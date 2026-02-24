import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey, isGeminiConfigured } from './gemini-config';
import { buildMatchExplanationPrompt, WEIGHTED_MATCH_EXPLANATION_SYSTEM } from './prompts/match-me';
import {
  generateUserProfileEmbedding,
  scoreListingsBySemanticSimilarity,
  hybridScore,
  saveUserProfileEmbedding,
} from './semantic-match';

const db = admin.firestore();

export interface MatchProfile {
  skills: string[];
  interests: string[];
  availability?: string;
  location?: string;
  causes?: string[];
}

export interface MatchResultItem {
  id: string;
  title: string;
  organizationName?: string;
  location?: string;
  matchScore: number;
  matchExplanation: string;
}

export interface RunMatchAssessmentOutput {
  profile: MatchProfile;
  topMatches: MatchResultItem[];
}

function normalizeAnswers(answers: Record<string, unknown>): MatchProfile {
  const skills = normalizeArray(answers.skills ?? answers.skill ?? answers.q1);
  const interests = normalizeArray(answers.interests ?? answers.interest ?? answers.q2);
  const availability = normalizeString(answers.availability ?? answers.when ?? answers.q3 ?? answers.q2);
  const location = normalizeString(answers.location ?? answers.where ?? answers.q4 ?? answers.q3);
  const causes = normalizeArray(answers.causes ?? answers.cause ?? answers.q5 ?? answers.q4);

  return {
    skills: skills.length ? skills : interests.length ? interests : [],
    interests: interests.length ? interests : skills.length ? skills : [],
    availability: availability || undefined,
    location: location || undefined,
    causes: causes.length ? causes : undefined,
  };
}

function normalizeArray(v: unknown): string[] {
  if (Array.isArray(v)) return v.map((x) => String(x).trim()).filter(Boolean);
  if (typeof v === 'string') return v.split(/[,;]/).map((s) => s.trim()).filter(Boolean);
  return [];
}

function normalizeString(v: unknown): string {
  if (typeof v === 'string') return v.trim();
  if (v != null) return String(v).trim();
  return '';
}

/**
 * Weighted scoring: skills 35%, causes 25%, location 20%, availability 15%, tags 5%.
 * Availability: user "Weekends" vs listing tags "Weekend Only" -> boost. Causes vs listing category/tags.
 */
export function calculateWeightedMatchScore(profile: MatchProfile, activity: admin.firestore.DocumentData): number {
  let score = 0;
  const userSkills = profile.skills || [];
  const userInterests = profile.interests || [];
  const requiredSkills = activity.skillsRequired || [];
  const tags: string[] = activity.tags || [];
  const titleDesc = `${(activity.title || '')} ${(activity.description || '')}`.toLowerCase();

  // 1. Skills match (35%)
  if (requiredSkills.length > 0) {
    const matched = userSkills.filter((s) => requiredSkills.some((r: string) => r.toLowerCase().includes(s.toLowerCase()) || s.toLowerCase().includes(r.toLowerCase()))).length;
    score += (matched / requiredSkills.length) * 35;
  } else {
    const skillTagMatch = userSkills.some((s) => tags.some((t: string) => t.toLowerCase().includes(s.toLowerCase())));
    score += skillTagMatch ? 25 : 15;
  }

  // 2. Causes match (25%) - user causes vs listing category/title/tags
  const userCauses = profile.causes || [];
  const causeMatch = userCauses.some((c) => titleDesc.includes(c.toLowerCase()) || tags.some((t: string) => t.toLowerCase().includes(c.toLowerCase())))
    || userInterests.some((i) => titleDesc.includes(i.toLowerCase()));
  if (causeMatch) score += 25;

  // 3. Location (20%)
  if (profile.location && activity.location) {
    const u = profile.location.toLowerCase();
    const a = String(activity.location).toLowerCase();
    score += u.includes(a) || a.includes(u) ? 20 : 10;
  } else if (!profile.location || !activity.location) score += 10;

  // 4. Availability (15%) - user availability vs listing tags (Weekend Only, Weekday, etc.)
  const userAvail = (profile.availability || '').toLowerCase();
  const availMatch = tags.some((t: string) => {
    const tLower = t.toLowerCase();
    if (userAvail.includes('weekend') && (tLower.includes('weekend') || tLower.includes('saturday') || tLower.includes('sunday'))) return true;
    if (userAvail.includes('weekday') && (tLower.includes('weekday') || tLower.includes('mon') || tLower.includes('fri'))) return true;
    if (userAvail.includes('evening') && tLower.includes('evening')) return true;
    return false;
  });
  if (userAvail && availMatch) score += 15;
  else if (userAvail || tags.some((t: string) => /weekend|weekday|evening/i.test(t))) score += 7;

  // 5. Tags overlap (5%)
  const tagOverlap = tags.some((t: string) => [...userSkills, ...userInterests, ...(userCauses || [])].some((u) => t.toLowerCase().includes(u.toLowerCase())));
  if (tagOverlap) score += 5;

  return Math.round(Math.min(score, 100));
}

async function explainMatch(profile: MatchProfile, activity: admin.firestore.DocumentData, score: number): Promise<string> {
  if (!isGeminiConfigured()) return `Good match based on your profile (${score}% fit).`;
  const gemini = new GoogleGenerativeAI(getGeminiApiKey());
  const model = gemini.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: { temperature: 0.5, maxOutputTokens: 256 },
  });
  const prompt = buildMatchExplanationPrompt(
    {
      skills: profile.skills,
      interests: profile.interests,
      availability: profile.availability,
      location: profile.location,
      causes: profile.causes,
    },
    {
      title: activity.title ?? '',
      description: activity.description,
      skillsRequired: activity.skillsRequired,
      location: activity.location,
      tags: activity.tags,
    },
    score
  );
  try {
    const result = await model.generateContent(`${WEIGHTED_MATCH_EXPLANATION_SYSTEM}\n\n${prompt}`);
    return result.response.text()?.trim() || `Good match based on your profile (${score}% fit).`;
  } catch {
    return `Good match based on your profile (${score}% fit).`;
  }
}

/**
 * Core assessment logic: compute profile from answers and return top matches. Shared by callable and match-me-mini tool.
 */
export async function runMatchAssessmentCore(
  userId: string | null,
  answers: Record<string, unknown>
): Promise<RunMatchAssessmentOutput> {
  const profile = normalizeAnswers(answers);

  const now = admin.firestore.Timestamp.now();
  let snap = await db.collection('volunteer_listings').where('startTime', '>', now).limit(80).get();
  if (snap.empty) snap = await db.collection('volunteer_listings').limit(80).get();

  const ruleScores = new Map<string, number>();
  const docsById = new Map<string, admin.firestore.DocumentData>();
  for (const doc of snap.docs) {
    const activity = doc.data();
    const score = calculateWeightedMatchScore(profile, activity);
    if (score >= 40) {
      ruleScores.set(doc.id, score);
      docsById.set(doc.id, activity);
    }
  }

  let scored: { id: string; data: admin.firestore.DocumentData; score: number }[] = [];
  const userEmbedding = await generateUserProfileEmbedding(profile);
  if (userId && userEmbedding) await saveUserProfileEmbedding(userId, profile);
  if (userEmbedding && docsById.size > 0) {
    const listingsWithEmbeddings = snap.docs
      .filter((d) => docsById.has(d.id))
      .map((d) => ({ id: d.id, embedding: d.data().embedding }));
    const semanticScores = await scoreListingsBySemanticSimilarity(userEmbedding, listingsWithEmbeddings);
    const semanticMap = new Map(semanticScores.map((s) => [s.id, s.semanticScore]));
    scored = Array.from(ruleScores.entries()).map(([id, ruleScore]) => {
      const sem = semanticMap.get(id) ?? 0;
      const finalScore = hybridScore(ruleScore, sem);
      return { id, data: docsById.get(id)!, score: finalScore };
    });
  } else {
    scored = Array.from(ruleScores.entries()).map(([id, score]) => ({ id, data: docsById.get(id)!, score }));
  }
  scored.sort((a, b) => b.score - a.score);
  const top = scored.slice(0, 10);

  const topMatches: MatchResultItem[] = [];
  for (const { id, data, score } of top) {
    const matchExplanation = await explainMatch(profile, data, score);
    topMatches.push({
      id,
      title: data.title ?? '',
      organizationName: data.organizationName,
      location: data.location,
      matchScore: score,
      matchExplanation,
    });
  }

  if (userId && (profile.skills.length > 0 || profile.interests.length > 0 || profile.availability || profile.location || (profile.causes?.length ?? 0) > 0)) {
    const userRef = db.collection('users').doc(userId);
    await userRef.set(
      {
        skills: profile.skills.length ? profile.skills : admin.firestore.FieldValue.delete(),
        interests: profile.interests.length ? profile.interests : admin.firestore.FieldValue.delete(),
        availability: profile.availability || admin.firestore.FieldValue.delete(),
        location: profile.location || admin.firestore.FieldValue.delete(),
        causes: (profile.causes?.length ?? 0) > 0 ? profile.causes : admin.firestore.FieldValue.delete(),
      },
      { merge: true }
    );
  }

  return { profile, topMatches };
}

/**
 * Callable: run match assessment from questionnaire answers.
 * Input: { answers: Record<string, unknown>, userId?: string }
 * Output: { profile, topMatches }
 */
export const runMatchAssessment = functions.https.onCall(async (data, context): Promise<RunMatchAssessmentOutput> => {
  const userId = (data.userId as string) || (context.auth?.uid as string) || null;
  const answers = (data.answers as Record<string, unknown>) || {};
  return runMatchAssessmentCore(userId, answers);
});

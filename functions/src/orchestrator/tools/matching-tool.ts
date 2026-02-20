import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import * as functions from 'firebase-functions';
import type { UserContext } from '../context-builder';

const db = admin.firestore();
const gemini = new GoogleGenerativeAI(functions.config().gemini?.api_key || '');
const model = gemini.getGenerativeModel({ model: 'gemini-2.0-flash' });

export interface MatchItem {
  id: string;
  title: string;
  organizationName?: string;
  location?: string;
  matchScore: number;
  matchExplanation: string;
}

export interface MatchingToolOutput {
  topMatches: MatchItem[];
}

function calculateMatchScore(user: any, activity: any): number {
  let score = 0;
  const userSkills = user.skills || [];
  const requiredSkills = activity.skillsRequired || [];
  if (requiredSkills.length > 0) {
    const matched = userSkills.filter((s: string) => requiredSkills.includes(s)).length;
    score += (matched / requiredSkills.length) * 40;
  } else score += 20;

  const userInterests = user.interests || [];
  const category = (activity.category || activity.title || '').toLowerCase();
  if (userInterests.some((i: string) => category.includes(i.toLowerCase()))) score += 25;

  if (user.location && activity.location) {
    const u = user.location.toLowerCase();
    const a = activity.location.toLowerCase();
    score += u.includes(a) || a.includes(u) ? 20 : 10;
  }

  const slotsLeft = (activity.slotsTotal || 0) - (activity.slotsFilled || 0);
  score += slotsLeft > 5 ? 15 : slotsLeft > 0 ? 8 : 0;
  return Math.round(Math.min(score, 100));
}

async function explainMatch(user: any, activity: any, score: number): Promise<string> {
  const prompt = `In 1-2 sentences, explain why this volunteer opportunity matches this user (score ${score}/100). User skills: ${(user.skills || []).join(', ')}. Interests: ${(user.interests || []).join(', ')}. Activity: ${activity.title}. Required: ${(activity.skillsRequired || []).join(', ')}. Location: ${activity.location || 'N/A'}.`;
  try {
    const result = await model.generateContent(prompt);
    return result.response.text()?.trim() || `Good match (${score}% fit).`;
  } catch {
    return `Good match based on your profile (${score}%).`;
  }
}

/**
 * Matching tool: score activities for user and return top matches with explanations.
 */
export async function runMatchingTool(userId: string, context: UserContext): Promise<MatchingToolOutput> {
  const userDoc = await db.collection('users').doc(userId).get();
  const user = userDoc.data();
  if (!user) return { topMatches: [] };

  const now = admin.firestore.Timestamp.now();
  let activitiesSnap = await db.collection('volunteer_listings').where('startTime', '>', now).get();
  if (activitiesSnap.empty) {
    activitiesSnap = await db.collection('volunteer_listings').limit(50).get();
  }

  const matches: MatchItem[] = [];
  for (const doc of activitiesSnap.docs) {
    const activity = doc.data();
    const score = calculateMatchScore(user, activity);
    if (score < 50) continue;
    const matchExplanation = await explainMatch(user, activity, score);
    matches.push({
      id: doc.id,
      title: activity.title ?? '',
      organizationName: activity.organizationName,
      location: activity.location,
      matchScore: score,
      matchExplanation,
    });
  }
  matches.sort((a, b) => b.matchScore - a.matchScore);
  const topMatches = matches.slice(0, 10);
  return { topMatches };
}

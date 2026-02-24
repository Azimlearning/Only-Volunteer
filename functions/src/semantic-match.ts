import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { getGeminiApiKey, isGeminiConfigured } from './gemini-config';
import type { MatchProfile } from './assessment';

const db = admin.firestore();
const EMBEDDING_MODEL = 'text-embedding-004';

function getEmbeddingModel() {
  if (!isGeminiConfigured()) return null;
  const gemini = new GoogleGenerativeAI(getGeminiApiKey());
  return gemini.getGenerativeModel({ model: EMBEDDING_MODEL });
}

export function buildProfileText(profile: MatchProfile): string {
  const parts: string[] = [];
  if (profile.skills?.length) parts.push(`Skills: ${profile.skills.join(', ')}`);
  if (profile.interests?.length) parts.push(`Interests: ${profile.interests.join(', ')}`);
  if (profile.availability) parts.push(`Availability: ${profile.availability}`);
  if (profile.location) parts.push(`Location: ${profile.location}`);
  if (profile.causes?.length) parts.push(`Causes: ${profile.causes.join(', ')}`);
  return parts.join('. ') || 'Volunteer looking for opportunities';
}

export async function generateUserProfileEmbedding(profile: MatchProfile): Promise<number[] | null> {
  const model = getEmbeddingModel();
  if (!model) return null;
  const text = buildProfileText(profile);
  try {
    const result = await model.embedContent({
      content: { parts: [{ text }], role: 'user' },
    });
    return result.embedding.values;
  } catch (e) {
    console.error('semantic-match: generateUserProfileEmbedding error', e);
    return null;
  }
}

export async function saveUserProfileEmbedding(userId: string, profile: MatchProfile): Promise<void> {
  const embedding = await generateUserProfileEmbedding(profile);
  if (!embedding) return;
  await db.collection('users').doc(userId).set({ matchProfileEmbedding: embedding }, { merge: true });
}

function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length) return 0;
  const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magnitudeA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magnitudeB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  if (magnitudeA === 0 || magnitudeB === 0) return 0;
  return dotProduct / (magnitudeA * magnitudeB);
}

export interface SemanticScoreItem {
  id: string;
  semanticScore: number;
}

/**
 * Score volunteer_listings by cosine similarity between user embedding and listing embedding.
 * Returns ranked listing IDs with semantic score (0-1 range).
 */
export async function scoreListingsBySemanticSimilarity(
  userEmbedding: number[],
  listings: { id: string; embedding?: number[] }[]
): Promise<SemanticScoreItem[]> {
  const withEmbedding = listings.filter((l) => l.embedding && Array.isArray(l.embedding) && l.embedding.length === userEmbedding.length);
  return withEmbedding
    .map((doc) => ({
      id: doc.id,
      semanticScore: cosineSimilarity(userEmbedding, doc.embedding!),
    }))
    .sort((a, b) => b.semanticScore - a.semanticScore);
}

const RULE_WEIGHT = 0.6;
const SEMANTIC_WEIGHT = 0.4;

/**
 * Combine rule-based score (0-100) and semantic score (0-1) into a single 0-100 hybrid score.
 */
export function hybridScore(ruleScore: number, semanticScore: number): number {
  return Math.round(ruleScore * RULE_WEIGHT + semanticScore * 100 * SEMANTIC_WEIGHT);
}

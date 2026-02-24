import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey, isGeminiConfigured } from './gemini-config';
import { TAG_GENERATION_SYSTEM, buildTagGenerationUserPrompt } from './prompts/match-me';

const db = admin.firestore();

function getTagModel() {
  if (!isGeminiConfigured()) return null;
  const gemini = new GoogleGenerativeAI(getGeminiApiKey());
  return gemini.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: { temperature: 0.3, maxOutputTokens: 512 },
  });
}

async function generateTagsForListing(listing: admin.firestore.DocumentData, id: string): Promise<string[]> {
  const model = getTagModel();
  if (!model) return [];

  const userPrompt = buildTagGenerationUserPrompt({
    title: (listing.title as string) ?? '',
    description: listing.description,
    skillsRequired: listing.skillsRequired,
    location: listing.location,
    startTime: listing.startTime,
    endTime: listing.endTime,
  });

  try {
    const fullPrompt = `${TAG_GENERATION_SYSTEM}\n\n---\n\n${userPrompt}`;
    const result = await model.generateContent(fullPrompt);
    const text = result.response.text()?.trim() ?? '';
    const cleaned = text.replace(/^[^[]*/, '').replace(/[^\]]*$/, '').trim();
    const parsed = JSON.parse(cleaned) as unknown;
    if (Array.isArray(parsed)) {
      return parsed.filter((t): t is string => typeof t === 'string').slice(0, 10);
    }
  } catch (e) {
    console.error(`opportunity-catalog: failed to generate tags for ${id}:`, e);
  }
  return [];
}

function contentChanged(before: admin.firestore.DocumentData | undefined, after: admin.firestore.DocumentData): boolean {
  if (!before) return true;
  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  for (const k of keys) {
    if (k === 'tags' || k === 'updatedAt') continue;
    if (JSON.stringify(before[k]) !== JSON.stringify(after[k])) return true;
  }
  return false;
}

/**
 * On create or update of a volunteer_listing, generate tags and write to the document.
 * Skips when the only change is to `tags` (avoids re-trigger loop).
 */
export const onVolunteerListingWrite = functions.firestore
  .document('volunteer_listings/{listingId}')
  .onWrite(async (change, context) => {
    const listingId = context.params.listingId;
    const before = change.before.exists ? change.before.data() : undefined;
    const after = change.after.exists ? change.after.data() ?? undefined : undefined;
    if (!after) return;
    if (before && !contentChanged(before, after) && Array.isArray(after.tags) && after.tags.length > 0) return;

    const tags = await generateTagsForListing(after, listingId);
    if (tags.length > 0) {
      await db.collection('volunteer_listings').doc(listingId).update({ tags });
    }
  });

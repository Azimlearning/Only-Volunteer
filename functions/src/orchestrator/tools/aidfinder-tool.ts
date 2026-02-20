import * as admin from 'firebase-admin';
import type { UserContext } from '../context-builder';

const db = admin.firestore();

export interface NearbyAidItem {
  id: string;
  title: string;
  category?: string;
  location?: string;
  urgency?: string;
  description?: string;
  distance?: number;
  matchScore?: number;
}

export interface AidFinderToolOutput {
  nearbyAid: NearbyAidItem[];
  summary: { totalNearby: number };
}

/**
 * Aid Finder tool: fetch aid resources, optionally filter by category/urgency.
 * Distance is placeholder (no geo in MVP); matchScore can be based on user interests/category.
 */
export async function runAidFinderTool(
  _userId: string,
  context: UserContext,
  options?: { category?: string; urgency?: string }
): Promise<AidFinderToolOutput> {
  const snapshot = await db
    .collection('aid_resources')
    .orderBy('createdAt', 'desc')
    .limit(20)
    .get();
  let items: NearbyAidItem[] = snapshot.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      title: d.title ?? '',
      category: d.category,
      location: d.location,
      urgency: d.urgency,
      description: d.description,
      matchScore: 0.8,
    };
  });

  if (options?.category) {
    const cat = options.category.toLowerCase();
    items = items.filter((i) => i.category?.toLowerCase().includes(cat));
  }
  if (options?.urgency) {
    const u = options.urgency.toLowerCase();
    items = items.filter((i) => i.urgency?.toLowerCase().includes(u));
  }

  // Simple relevance: boost if category matches user interests
  const interests = (context.interests || []).map((x) => x.toLowerCase());
  items = items.map((i) => {
    const categoryMatch = interests.some((int) => (i.category || '').toLowerCase().includes(int));
    return { ...i, matchScore: categoryMatch ? 0.95 : (i.matchScore ?? 0.8) };
  });
  items.sort((a, b) => (b.matchScore ?? 0) - (a.matchScore ?? 0));

  return {
    nearbyAid: items.slice(0, 10),
    summary: { totalNearby: items.length },
  };
}

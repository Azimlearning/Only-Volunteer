import * as admin from 'firebase-admin';
import type { UserContext } from '../context-builder';

const db = admin.firestore();

export interface DonationDriveItem {
  id: string;
  title: string;
  description?: string;
  location?: string;
  itemsNeeded?: string[];
  endDate?: string;
  matchScore?: number;
}

export interface DonationDrivesToolOutput {
  drives: DonationDriveItem[];
  summary: { total: number };
}

/**
 * Donation drives tool: fetch ongoing donation drives from Firestore.
 * Uses user location from context for relevance ordering when available (no asking for location).
 */
export async function runDonationDrivesTool(
  _userId: string,
  context: UserContext
): Promise<DonationDrivesToolOutput> {
  const snapshot = await db
    .collection('donation_drives')
    .orderBy('createdAt', 'desc')
    .limit(25)
    .get();

  let drives: DonationDriveItem[] = snapshot.docs.map((doc) => {
    const d = doc.data();
    const endDate = d.endDate?.toDate?.() ?? d.endDate;
    return {
      id: doc.id,
      title: d.title ?? '',
      description: d.description,
      location: d.location,
      itemsNeeded: Array.isArray(d.itemsNeeded) ? d.itemsNeeded : undefined,
      endDate: typeof endDate === 'string' ? endDate : endDate?.toISOString?.(),
      matchScore: 0.8,
    };
  });

  const userLocation = (context.location || '').toLowerCase();
  if (userLocation) {
    drives = drives.map((d) => {
      const loc = (d.location || '').toLowerCase();
      const matches = loc && userLocation && (loc.includes(userLocation) || userLocation.includes(loc));
      return { ...d, matchScore: matches ? 0.95 : (d.matchScore ?? 0.8) };
    });
    drives.sort((a, b) => (b.matchScore ?? 0) - (a.matchScore ?? 0));
  }

  return {
    drives: drives.slice(0, 10),
    summary: { total: drives.length },
  };
}

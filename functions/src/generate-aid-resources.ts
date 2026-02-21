import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey } from './gemini-config';

const gemini = new GoogleGenerativeAI(getGeminiApiKey());
const model = gemini.getGenerativeModel({ model: GEMINI_MODEL });

export interface AidResourceData {
  title: string;
  description: string;
  category: string;
  location: string;
  urgency: 'low' | 'medium' | 'high' | 'critical';
  lat: number;
  lng: number;
  operatingHours: string;
  eligibility: string;
  phone?: string;
}

export async function runAidResourceGeneration(
  userLat?: number,
  userLng?: number,
  userLocation?: string
): Promise<{ ok: boolean; message: string; resourcesCreated: number }> {
  try {
    const locationContext = (userLat && userLng)
      ? `The user is at coordinates ${userLat.toFixed(4)}, ${userLng.toFixed(4)} (${userLocation || 'Malaysia'}). Focus on aid organizations within 50km of this location.`
      : userLocation
        ? `The user is in ${userLocation}, Malaysia. Focus on aid organizations in and around this area.`
        : 'Cover major Malaysian cities: Kuala Lumpur, Petaling Jaya, Shah Alam, Johor Bahru, Penang, Ipoh, Kota Bharu, Kuantan, Kuching, Kota Kinabalu.';

    const today = new Date().toLocaleDateString('en-MY', { dateStyle: 'long' });

    const prompt = `You are a comprehensive Malaysian aid directory researcher with deep knowledge of real social service organizations across Malaysia.

Today is ${today}. ${locationContext}

Generate a list of exactly 15 real Malaysian aid organizations and community resources. These must be REAL, EXISTING organizations that actually operate in Malaysia.

Include a diverse mix of:
- Food banks and soup kitchens (e.g. Kechara Soup Kitchen, Food Aid Foundation, Pertiwi Soup Kitchen)
- Free medical clinics (e.g. MERCY Malaysia, Klinik Komuniti, free government clinics)
- Homeless shelters and temporary housing
- Women and children shelters (e.g. WAO, Refuge for the Refugees)
- Clothing banks and material aid centers
- Educational support centers for underprivileged
- Disaster relief centers (if currently active)
- Community centers providing multiple services
- NGO offices providing aid coordination
- Government welfare offices (JKM, LPPKN)

For each organization provide:
- Real name as it is officially known
- Accurate address and Malaysian state
- Correct GPS coordinates (must be precise real-world coordinates in Malaysia, NOT approximate)
- Operating hours (research what you know; use "Call to confirm" only if genuinely unknown)
- Phone number if publicly known
- Who is eligible (be specific: B40 families, all communities, women only, etc.)
- Urgency level based on current need: critical (disaster zone), high (acute shortage), medium (ongoing need), low (stable service)
- Category: choose the MOST fitting from Food, Shelter, Medical, Clothing, Education, Hygiene, Transport, or create a new relevant category

COORDINATE RULES:
- All lat must be between 1.0 and 7.5 (Malaysia range)
- All lng must be between 99.5 and 119.5 (Malaysia range)
- Must be precise street-level coordinates, not city centers

Respond ONLY with a valid JSON array, no markdown, no explanation:
[
  {
    "title": "Organization name",
    "description": "2-3 sentence description of services provided and who they help",
    "category": "Category name",
    "location": "Full address, City, State",
    "urgency": "low" or "medium" or "high" or "critical",
    "lat": 3.1234,
    "lng": 101.5678,
    "operatingHours": "Mon-Fri 9AM-5PM, Sat 9AM-1PM",
    "eligibility": "Who can access this service",
    "phone": "+603-XXXX-XXXX or null"
  }
]`;

    const result = await model.generateContent(prompt);
    const text = result.response.text();
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      console.error('No JSON array in Gemini response:', text.substring(0, 500));
      return { ok: false, message: 'No JSON in Gemini response', resourcesCreated: 0 };
    }

    const resources: AidResourceData[] = JSON.parse(jsonMatch[0]);
    console.log(`Gemini generated ${resources.length} aid resources`);

    // Delete old AI-generated resources
    const oldDocs = await admin.firestore()
      .collection('aid_resources')
      .where('source', '==', 'ai')
      .get();
    const deleteOps = oldDocs.docs.map(d => d.ref.delete());
    await Promise.all(deleteOps);
    console.log(`Deleted ${oldDocs.size} old AI aid resources`);

    // Write new resources — format matches AidResource.fromFirestore
    let created = 0;
    const now = admin.firestore.FieldValue.serverTimestamp();
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 7 * 24 * 3600000) // 7 days
    );

    for (const r of resources.slice(0, 15)) {
      if (r.lat < 1.0 || r.lat > 7.5 || r.lng < 99.5 || r.lng > 119.5) {
        console.warn(`Skipping resource with invalid coords: ${r.title} (${r.lat}, ${r.lng})`);
        continue;
      }
      try {
        await admin.firestore().collection('aid_resources').add({
          title: r.title,
          description: `${r.description}\n\nOperating Hours: ${r.operatingHours}\nEligibility: ${r.eligibility}${r.phone ? '\nContact: ' + r.phone : ''}`,
          category: r.category,
          location: r.location,
          urgency: r.urgency,
          lat: r.lat,
          lng: r.lng,
          source: 'ai',
          imageUrl: null,
          createdAt: now,
          updatedAt: now,
          expiresAt: expiresAt,
        });
        created++;
      } catch (e) {
        console.error('Error writing aid resource:', e);
      }
    }

    console.log(`Created ${created} new AI aid resources`);
    return { ok: true, message: `Generated ${created} aid resources`, resourcesCreated: created };
  } catch (error: any) {
    console.error('runAidResourceGeneration error:', error);
    return { ok: false, message: String(error), resourcesCreated: 0 };
  }
}

export const generateAidResources = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'OPTIONS, GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  try {
    const userLat = req.query.lat ? parseFloat(req.query.lat as string) : req.body?.lat;
    const userLng = req.query.lng ? parseFloat(req.query.lng as string) : req.body?.lng;
    const userLocation = (req.query.location as string | undefined) || req.body?.location;
    const result = await runAidResourceGeneration(userLat, userLng, userLocation);
    res.status(200).json(result);
  } catch (e: any) {
    res.status(500).json({ ok: false, message: e?.message ?? String(e), resourcesCreated: 0 });
  }
});

export const scheduledAidResourceRefresh = functions.pubsub
  .schedule('every 168 hours') // 7 days
  .timeZone('Asia/Kuala_Lumpur')
  .onRun(async () => {
    const result = await runAidResourceGeneration();
    console.log('scheduledAidResourceRefresh result:', result);
    return null;
  });

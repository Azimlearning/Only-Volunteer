import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey } from './gemini-config';
import { getAidGeneratorPrompt } from './prompts/aid-generator-prompts';

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
    const prompt = getAidGeneratorPrompt(locationContext, today);

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
          description: r.description,
          operatingHours: r.operatingHours,
          eligibility: r.eligibility,
          phone: r.phone ?? null,
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

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';
import * as xml2js from 'xml2js';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey } from './gemini-config';

const gemini = new GoogleGenerativeAI(getGeminiApiKey());
const model = gemini.getGenerativeModel({ model: GEMINI_MODEL });

export interface NewsArticle {
  title: string;
  description?: string;
  link?: string;
  publishedAt?: string;
}

export interface GeneratedAlert {
  title: string;
  body: string;
  type: 'flood' | 'sos' | 'general';
  region: string;
  severity: 'high' | 'medium' | 'low';
}

async function fetchMalaysiaNewsRSS(): Promise<NewsArticle[]> {
  const feeds = [
    'https://www.thestar.com.my/rss/news/nation',
    'https://www.malaymail.com/feed',
    'https://www.bernama.com/en/rss/news.php',
  ];
  const articles: NewsArticle[] = [];
  for (const url of feeds) {
    try {
      const response = await axios.get(url, {
        timeout: 8000,
        headers: { 'User-Agent': 'Mozilla/5.0 (compatible; OnlyVolunteer/1.0)' },
      });
      const parsed = await xml2js.parseStringPromise(response.data, { explicitArray: true });
      const items: any[] = parsed?.rss?.channel?.[0]?.item || [];
      for (const item of items.slice(0, 5)) {
        const title = Array.isArray(item.title) ? item.title[0] : item.title || '';
        const desc = Array.isArray(item.description) ? item.description[0] : item.description || '';
        const link = Array.isArray(item.link) ? item.link[0] : item.link || '';
        const pubDate = Array.isArray(item.pubDate) ? item.pubDate[0] : item.pubDate || '';
        const cleanDesc = String(desc).replace(/<[^>]*>/g, '').trim();
        articles.push({
          title: String(title).trim(),
          description: cleanDesc,
          link: String(link).trim(),
          publishedAt: String(pubDate).trim(),
        });
      }
      console.log(`Fetched ${Math.min(items.length, 5)} articles from ${url}`);
    } catch (e: any) {
      console.error(`RSS fetch error for ${url}:`, e?.message ?? e);
    }
  }
  console.log(`Total RSS articles fetched: ${articles.length}`);
  return articles;
}

export async function runNewsAlertGeneration(userLocation?: string): Promise<{
  ok: boolean;
  message: string;
  articlesProcessed: number;
  alertsCreated: number;
}> {
  try {
    const articles = await fetchMalaysiaNewsRSS();
    const locationContext = userLocation
      ? `The user is located in ${userLocation}, Malaysia. Prioritize alerts for this state first, then nearby states.`
      : 'Cover Malaysia in general. Focus on: Kuala Lumpur, Selangor, Johor, Pahang, Kelantan, Perak, Sabah, Sarawak.';

    const articleSummaries = articles.length > 0
      ? articles.map((a, i) => `${i + 1}. Title: ${a.title}\n   Summary: ${a.description || 'N/A'}`).join('\n\n')
      : 'No news articles available today.';

    const today = new Date().toLocaleDateString('en-MY', { dateStyle: 'long' });

    const prompt = `You are an emergency alert system for OnlyVolunteer, a Malaysian volunteer and aid platform.
Today is ${today}. ${locationContext}

Based on the following real Malaysian news articles (and your knowledge of current conditions in Malaysia), generate between 5 and 10 emergency or community alerts. You MUST generate at least 5 alerts.

REAL NEWS ARTICLES:
${articleSummaries}

ALERT CRITERIA (from most to least urgent):
- HIGH severity: Active floods, fires, accidents, SOS rescue needed, disease outbreaks
- MEDIUM severity: Weather warnings, road closures, missing persons, supply shortages
- LOW severity: Community health campaigns, food distribution events, volunteer drives, general safety advisories

RULES:
- Always generate at least 5 alerts total
- If real news only covers 1-2 urgent topics, pad the rest with relevant low-severity community alerts based on current Malaysian seasonal context (monsoon season, haze, community events)
- Each alert must be specific to a real Malaysian location (state, city, or district)
- Never duplicate the same region + type combination
- Keep titles under 10 words
- Keep body to 1-2 factual sentences

Respond ONLY with a valid JSON array, no markdown, no explanation:
[
  {
    "title": "short alert title",
    "body": "1-2 sentence description",
    "type": "flood" or "sos" or "general",
    "region": "Malaysian state or city",
    "severity": "high" or "medium" or "low"
  }
]`;

    const result = await model.generateContent(prompt);
    const text = result.response.text();
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      console.error('No JSON array in Gemini response:', text);
      return { ok: false, message: 'No JSON in Gemini response', articlesProcessed: articles.length, alertsCreated: 0 };
    }

    const generatedAlerts: GeneratedAlert[] = JSON.parse(jsonMatch[0]);
    console.log(`Gemini generated ${generatedAlerts.length} alerts`);

    // Delete old AI-generated alerts (keep hardcoded ones which have no source field)
    const oldAlerts = await admin.firestore()
      .collection('alerts')
      .where('source', '==', 'ai')
      .get();
    const deletePromises = oldAlerts.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
    console.log(`Deleted ${oldAlerts.size} old AI alerts`);

    // Write new alerts
    let created = 0;
    for (const alert of generatedAlerts.slice(0, 10)) {
      try {
        await admin.firestore().collection('alerts').add({
          title: alert.title,
          body: alert.body,
          type: alert.type,
          region: alert.region,
          severity: alert.severity,
          source: 'ai',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 12 * 3600000)),
        });
        created++;
      } catch (e) {
        console.error('Error writing alert:', e);
      }
    }

    console.log(`Created ${created} new AI alerts`);
    return {
      ok: true,
      message: `Processed ${articles.length} articles, created ${created} alerts`,
      articlesProcessed: articles.length,
      alertsCreated: created,
    };
  } catch (error: any) {
    console.error('runNewsAlertGeneration error:', error);
    return { ok: false, message: String(error), articlesProcessed: 0, alertsCreated: 0 };
  }
}

export const monitorNewsForAlerts = functions.pubsub
  .schedule('every 15 minutes')
  .timeZone('Asia/Kuala_Lumpur')
  .onRun(async () => {
    const result = await runNewsAlertGeneration();
    console.log('monitorNewsForAlerts result:', result);
    return null;
  });

export const triggerNewsAlerts = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'OPTIONS, GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  try {
    const userLocation = (req.query.location as string | undefined) || (req.body?.location as string | undefined);
    const result = await runNewsAlertGeneration(userLocation);
    res.status(200).json(result);
  } catch (e: any) {
    res.status(500).json({ ok: false, message: e?.message ?? String(e), articlesProcessed: 0, alertsCreated: 0 });
  }
});

export const testNewsAlerts = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  try {
    const articles = await fetchMalaysiaNewsRSS();
    res.json({ articleCount: articles.length, titles: articles.map((a) => a.title) });
  } catch (e: any) {
    res.status(500).json({ error: e?.message || String(e) });
  }
});

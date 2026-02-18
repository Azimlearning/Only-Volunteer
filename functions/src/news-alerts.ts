import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import axios from 'axios';

const gemini = new GoogleGenerativeAI(functions.config().gemini?.api_key || '');
const model = gemini.getGenerativeModel({ model: 'gemini-1.5-flash' });

// Scheduled function: runs every 15 minutes
export const monitorNewsForAlerts = functions.pubsub
  .schedule('every 15 minutes')
  .timeZone('Asia/Kuala_Lumpur')
  .onRun(async (context) => {
    const newsApiKey = functions.config().news?.api_key;
    if (!newsApiKey) {
      console.log('NewsAPI key not configured');
      return null;
    }

    try {
      // Fetch Malaysian news (last 1 hour)
      const response = await axios.get('https://newsapi.org/v2/everything', {
        params: {
          q: 'Malaysia flood OR disaster OR emergency OR SOS',
          language: 'en',
          sortBy: 'publishedAt',
          from: new Date(Date.now() - 3600000).toISOString(),
          apiKey: newsApiKey,
        },
      });

      const articles = response.data.articles || [];
      if (articles.length === 0) {
        console.log('No articles found');
        return null;
      }

      // Analyze each article with Gemini
      for (const article of articles.slice(0, 10)) {
        try {
          const analysis = await analyzeArticle(article);
          if (analysis.shouldCreateAlert) {
            await createAlert(analysis);
          }
        } catch (error) {
          console.error('Error processing article:', error);
        }
      }

      return null;
    } catch (error) {
      console.error('Error fetching news:', error);
      return null;
    }
  });

async function analyzeArticle(article: any): Promise<any> {
  const prompt = `Analyze this news article and determine if it requires an emergency alert for volunteers.

Article Title: ${article.title}
Article Description: ${article.description || 'N/A'}

Determine:
1. Is this about floods, disasters, or urgent SOS situations in Malaysia?
2. What region/location is affected?
3. What type of alert: flood, sos, or general?
4. What is the severity: high, medium, or low?

Respond in JSON format:
{
  "shouldCreateAlert": true/false,
  "type": "flood" | "sos" | "general",
  "region": "location name",
  "severity": "high" | "medium" | "low",
  "title": "short alert title",
  "body": "1-2 sentence summary"
}`;

  try {
    const result = await model.generateContent(prompt);
    const text = result.response.text();
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return parsed;
    }
  } catch (error) {
    console.error('Gemini analysis error:', error);
  }
  return { shouldCreateAlert: false };
}

async function createAlert(analysis: any): Promise<void> {
  try {
    // Check if similar alert exists (prevent duplicates)
    const oneHourAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3600000));
    const existing = await admin.firestore()
      .collection('alerts')
      .where('region', '==', analysis.region)
      .where('type', '==', analysis.type)
      .where('createdAt', '>', oneHourAgo)
      .get();

    if (!existing.empty) {
      console.log('Duplicate alert exists, skipping');
      return; // Duplicate exists
    }

    await admin.firestore().collection('alerts').add({
      title: analysis.title,
      body: analysis.body,
      type: analysis.type,
      region: analysis.region,
      severity: analysis.severity,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 3600000)), // 7 days
    });

    console.log('Alert created:', analysis.title);
  } catch (error) {
    console.error('Error creating alert:', error);
  }
}

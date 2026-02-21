import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GEMINI_MODEL, getGeminiApiKey } from './gemini-config';

const apiKey = getGeminiApiKey();
const gemini = new GoogleGenerativeAI(apiKey);
const geminiModel = gemini.getGenerativeModel({ model: GEMINI_MODEL });
const embeddingModel = gemini.getGenerativeModel({ model: 'text-embedding-004' });

// Main chat endpoint
export const chatWithRAG = functions.https.onCall(async (data, context) => {
  const { message, userId } = data;
  if (!message || !userId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing message or userId');
  }

  try {
    // 1. Generate query embedding
    const queryEmbedding = await generateEmbedding(message);

    // 2. Semantic search in Firestore
    const relevantDocs = await semanticSearch(queryEmbedding, 3);

    // 3. Build context from retrieved docs
    const context = buildContext(relevantDocs);

    // 4. Generate response with Gemini
    const response = await generateResponse(message, context, userId);

    return { response, sources: relevantDocs.map((d: any) => ({ id: d.id, type: d.type })) };
  } catch (error) {
    console.error('RAG chat error:', error);
    // Fallback to simple chat
    return await chatWithoutRAG(message, userId);
  }
});

async function generateEmbedding(text: string): Promise<number[]> {
  const result = await embeddingModel.embedContent({
    content: { parts: [{ text }], role: 'user' },
  });
  return result.embedding.values;
}

async function semanticSearch(queryEmbedding: number[], limit: number): Promise<any[]> {
  // Get all documents with embeddings
  const [activitiesSnapshot, drivesSnapshot, resourcesSnapshot] = await Promise.all([
    admin.firestore().collection('volunteer_listings').get(),
    admin.firestore().collection('donation_drives').get(),
    admin.firestore().collection('aid_resources').get(),
  ]);

  const allDocs: any[] = [
    ...activitiesSnapshot.docs.map(d => ({ ...d.data(), id: d.id, type: 'activity' })),
    ...drivesSnapshot.docs.map(d => ({ ...d.data(), id: d.id, type: 'drive' })),
    ...resourcesSnapshot.docs.map(d => ({ ...d.data(), id: d.id, type: 'resource' })),
  ];

  // Calculate cosine similarity
  const scored = allDocs
    .filter(d => d.embedding && Array.isArray(d.embedding) && d.embedding.length === queryEmbedding.length)
    .map(doc => ({
      ...doc,
      score: cosineSimilarity(queryEmbedding, doc.embedding),
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);

  return scored;
}

function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length) return 0;
  const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magnitudeA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magnitudeB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  if (magnitudeA === 0 || magnitudeB === 0) return 0;
  return dotProduct / (magnitudeA * magnitudeB);
}

function buildContext(docs: any[]): string {
  return docs.map(d => {
    if (d.type === 'activity') {
      return `Activity: ${d.title}. ${d.description || ''} Location: ${d.location || 'N/A'}. Skills: ${d.skillsRequired?.join(', ') || 'N/A'}`;
    } else if (d.type === 'drive') {
      return `Donation Drive: ${d.title}. ${d.description || ''} Location: ${d.location || 'N/A'}. Items needed: ${d.items?.join(', ') || 'N/A'}`;
    } else {
      return `Aid Resource: ${d.title}. ${d.description || ''} Location: ${d.location || 'N/A'}. Category: ${d.category || 'N/A'}`;
    }
  }).join('\n\n');
}

async function generateResponse(query: string, context: string, userId: string): Promise<string> {
  // Get user profile for personalization
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  const user = userDoc.data();

  const prompt = `You are the OnlyVolunteer AI assistant. Help users find volunteer opportunities, donation drives, and aid resources.

User Profile:
- Name: ${user?.displayName || 'User'}
- Skills: ${user?.skills?.join(', ') || 'None'}
- Interests: ${user?.interests?.join(', ') || 'None'}

Relevant Context from Database:
${context}

User Question: ${query}

Provide a helpful, concise answer (2-4 sentences). If relevant opportunities exist, mention them. Be friendly and actionable.`;

  const result = await geminiModel.generateContent(prompt);
  return result.response.text() || 'I apologize, but I could not generate a response. Please try again.';
}

async function chatWithoutRAG(message: string, userId: string): Promise<any> {
  // Fallback: simple Gemini chat without RAG
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  const user = userDoc.data();

  const prompt = `You are the OnlyVolunteer AI assistant. Help users find volunteer opportunities, donation drives, and aid resources.

User Profile:
- Name: ${user?.displayName || 'User'}
- Skills: ${user?.skills?.join(', ') || 'None'}
- Interests: ${user?.interests?.join(', ') || 'None'}

User Question: ${message}

Provide a helpful, concise answer (2-4 sentences). Be friendly and actionable.`;

  const result = await geminiModel.generateContent(prompt);
  return {
    response: result.response.text() || 'I apologize, but I could not generate a response. Please try again.',
    sources: [],
  };
}

// Function to embed all existing documents (run once)
export const embedAllActivities = functions.https.onCall(async (data, context) => {
  // Allow admin users or skip auth check in emulator
  if (!context.auth && process.env.FUNCTIONS_EMULATOR !== 'true') {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  try {
    const activities = await admin.firestore().collection('volunteer_listings').get();
    let count = 0;

    for (const doc of activities.docs) {
      const data = doc.data();
      const text = `${data.title} ${data.description || ''} ${data.location || ''}`;
      const embedding = await generateEmbedding(text);
      await doc.ref.update({ embedding });
      count++;
    }

    return { success: true, count };
  } catch (error) {
    console.error('Error embedding activities:', error);
    throw new functions.https.HttpsError('internal', 'Failed to embed activities');
  }
});

// Function to embed all donation drives
export const embedAllDrives = functions.https.onCall(async (data, context) => {
  // Allow admin users or skip auth check in emulator
  if (!context.auth && process.env.FUNCTIONS_EMULATOR !== 'true') {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  try {
    const drives = await admin.firestore().collection('donation_drives').get();
    let count = 0;

    for (const doc of drives.docs) {
      const data = doc.data();
      const text = `${data.title} ${data.description || ''} ${data.location || ''} ${data.items?.join(' ') || ''}`;
      const embedding = await generateEmbedding(text);
      await doc.ref.update({ embedding });
      count++;
    }

    return { success: true, count };
  } catch (error) {
    console.error('Error embedding drives:', error);
    throw new functions.https.HttpsError('internal', 'Failed to embed drives');
  }
});

// Function to embed all aid resources
export const embedAllResources = functions.https.onCall(async (data, context) => {
  // Allow admin users or skip auth check in emulator
  if (!context.auth && process.env.FUNCTIONS_EMULATOR !== 'true') {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  try {
    const resources = await admin.firestore().collection('aid_resources').get();
    let count = 0;

    for (const doc of resources.docs) {
      const data = doc.data();
      const text = `${data.title} ${data.description || ''} ${data.location || ''} ${data.category || ''}`;
      const embedding = await generateEmbedding(text);
      await doc.ref.update({ embedding });
      count++;
    }

    return { success: true, count };
  } catch (error) {
    console.error('Error embedding resources:', error);
    throw new functions.https.HttpsError('internal', 'Failed to embed resources');
  }
});

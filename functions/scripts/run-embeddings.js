// Script to run initial embeddings
// Run with: node scripts/run-embeddings.js

const admin = require('firebase-admin');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { VertexAI } = require('@google-cloud/vertexai');

// Initialize Firebase Admin with explicit project
admin.initializeApp({
  projectId: projectId,
  // Use Application Default Credentials or service account
});

// Get config from environment or Firebase config
const geminiApiKey = process.env.GEMINI_API_KEY || 'AIzaSyD9I8ZLMRmtaRwyq0EylLIq8rNDgt58_uQ';
const projectId = process.env.GCLOUD_PROJECT || 'onlyvolunteer-e3066';

const gemini = new GoogleGenerativeAI(geminiApiKey);
const geminiModel = gemini.getGenerativeModel({ model: 'gemini-1.5-flash' });

// Initialize Vertex AI
let vertexAI;
let embeddingModel;

try {
  vertexAI = new VertexAI({
    project: projectId,
    location: 'us-central1',
  });
  embeddingModel = vertexAI.preview.getGenerativeModel({
    model: 'textembedding-gecko@003',
  });
  console.log('✓ Vertex AI initialized');
} catch (error) {
  console.error('✗ Vertex AI initialization failed:', error.message);
  console.log('Make sure Vertex AI API is enabled in Google Cloud Console');
  process.exit(1);
}

async function generateEmbedding(text) {
  const result = await embeddingModel.embedContent({
    content: { parts: [{ text }] },
  });
  return result.embedding.values;
}

async function embedActivities() {
  console.log('\n📦 Embedding activities...');
  const activities = await admin.firestore().collection('volunteer_listings').get();
  let count = 0;
  
  for (const doc of activities.docs) {
    const data = doc.data();
    const text = `${data.title} ${data.description || ''} ${data.location || ''}`;
    try {
      const embedding = await generateEmbedding(text);
      await doc.ref.update({ embedding });
      count++;
      if (count % 5 === 0) {
        console.log(`  Processed ${count}/${activities.size} activities...`);
      }
    } catch (error) {
      console.error(`  Error embedding activity ${doc.id}:`, error.message);
    }
  }
  
  console.log(`✓ Embedded ${count} activities`);
  return count;
}

async function embedDrives() {
  console.log('\n📦 Embedding donation drives...');
  const drives = await admin.firestore().collection('donation_drives').get();
  let count = 0;
  
  for (const doc of drives.docs) {
    const data = doc.data();
    const text = `${data.title} ${data.description || ''} ${data.location || ''} ${data.items?.join(' ') || ''}`;
    try {
      const embedding = await generateEmbedding(text);
      await doc.ref.update({ embedding });
      count++;
      if (count % 5 === 0) {
        console.log(`  Processed ${count}/${drives.size} drives...`);
      }
    } catch (error) {
      console.error(`  Error embedding drive ${doc.id}:`, error.message);
    }
  }
  
  console.log(`✓ Embedded ${count} drives`);
  return count;
}

async function embedResources() {
  console.log('\n📦 Embedding aid resources...');
  const resources = await admin.firestore().collection('aid_resources').get();
  let count = 0;
  
  for (const doc of resources.docs) {
    const data = doc.data();
    const text = `${data.title} ${data.description || ''} ${data.location || ''} ${data.category || ''}`;
    try {
      const embedding = await generateEmbedding(text);
      await doc.ref.update({ embedding });
      count++;
      if (count % 5 === 0) {
        console.log(`  Processed ${count}/${resources.size} resources...`);
      }
    } catch (error) {
      console.error(`  Error embedding resource ${doc.id}:`, error.message);
    }
  }
  
  console.log(`✓ Embedded ${count} resources`);
  return count;
}

async function main() {
  console.log('🚀 Starting embedding process...');
  console.log(`Project: ${projectId}`);
  
  try {
    const [activitiesCount, drivesCount, resourcesCount] = await Promise.all([
      embedActivities(),
      embedDrives(),
      embedResources(),
    ]);
    
    console.log('\n✅ Embedding complete!');
    console.log(`   Activities: ${activitiesCount}`);
    console.log(`   Drives: ${drivesCount}`);
    console.log(`   Resources: ${resourcesCount}`);
    console.log(`   Total: ${activitiesCount + drivesCount + resourcesCount}`);
  } catch (error) {
    console.error('\n✗ Error:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

main();

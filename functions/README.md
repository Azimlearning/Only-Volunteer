# Firebase Cloud Functions - OnlyVolunteer AI Features

This directory contains Firebase Cloud Functions implementing AI features using Google technologies.

## Features

1. **AI News Alert System** (`news-alerts.ts`)
   - Monitors Malaysian news every 15 minutes
   - Analyzes articles with Gemini AI
   - Auto-creates flood/SOS alerts in Firestore

2. **RAG Chatbot** (`chatbot-rag.ts`)
   - Semantic search using Vertex AI embeddings
   - Context-aware responses with Gemini
   - Embedding functions for activities, drives, and resources

3. **AI Analytics** (`analytics.ts`)
   - Descriptive insights (what happened)
   - Prescriptive recommendations (what to do next)
   - Powered by Gemini AI

4. **Enhanced Skill Matching** (`skill-matching.ts`)
   - Multi-factor scoring (skills, interests, location, availability)
   - AI-generated explanations for matches
   - Returns top 10 matches with scores

## Setup

1. Install dependencies:
```bash
cd functions
npm install
```

2. Set environment variables:
```bash
firebase functions:config:set gemini.api_key="YOUR_GEMINI_KEY"
firebase functions:config:set news.api_key="YOUR_NEWS_KEY"
firebase functions:config:set gcp.project_id="YOUR_PROJECT_ID"
```

3. Build TypeScript:
```bash
npm run build
```

4. Deploy:
```bash
firebase deploy --only functions
```

## Initial Setup (Run Once)

After deploying, embed existing data:

```bash
firebase functions:shell
> embedAllActivities()
> embedAllDrives()
> embedAllResources()
```

## Testing Locally

```bash
firebase emulators:start --only functions
```

## Cost Estimates

- Gemini API: ~$5-10/month
- Vertex AI Embeddings: ~$2-5/month
- Cloud Functions: Free tier covers development
- NewsAPI: Free tier (100 requests/day)

**Total: < $20/month** for moderate usage

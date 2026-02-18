# AI Features Deployment Guide - OnlyVolunteer

## Quick Start

### 1. Install Functions Dependencies

```bash
cd functions
npm install
```

### 2. Set Environment Variables

```bash
# Get your Gemini API key from https://aistudio.google.com/apikey
firebase functions:config:set gemini.api_key="YOUR_GEMINI_KEY"

# Get NewsAPI key from https://newsapi.org (optional, for news alerts)
firebase functions:config:set news.api_key="YOUR_NEWS_KEY"

# Your Firebase project ID (usually auto-detected)
firebase functions:config:set gcp.project_id="YOUR_PROJECT_ID"
```

### 3. Enable Vertex AI

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your Firebase project
3. Enable **Vertex AI API**
4. Create a service account with **Vertex AI User** role (if needed)

### 4. Build and Deploy

```bash
# Build TypeScript
npm run build

# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:chatWithRAG
```

### 5. Initial Data Embedding (Run Once)

After deployment, embed existing data for RAG:

```bash
firebase functions:shell
> embedAllActivities()
> embedAllDrives()
> embedAllResources()
```

Or call via HTTP:
```bash
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/embedAllActivities \
  -H "Authorization: Bearer YOUR_ID_TOKEN"
```

## Testing Locally

```bash
# Start emulators
firebase emulators:start --only functions

# In another terminal, test functions
firebase functions:shell
> chatWithRAG({message: "find volunteer work", userId: "test-uid"})
> generateAIInsights()
> matchVolunteerToActivities({userId: "test-uid"})
```

## Flutter Integration

The Flutter app is already integrated! Just ensure:

1. **cloud_functions** package is installed (already added to `pubspec.yaml`)
2. **Firebase is initialized** in your app
3. **User is authenticated** when calling functions

### Testing in Flutter

1. Run the app: `flutter run -d chrome --dart-define=GEMINI_API_KEY=YOUR_KEY`
2. Navigate to:
   - **AI Chatbot** - Test RAG chat
   - **Analytics** - Click AI icon to generate insights
   - **Match Me** - Get AI-powered matches with explanations

## Function Endpoints

### chatWithRAG
- **Type**: Callable
- **Input**: `{message: string, userId: string}`
- **Output**: `{response: string, sources: Array}`

### generateAIInsights
- **Type**: Callable
- **Input**: `{}`
- **Output**: `{metrics: object, descriptive: string, prescriptive: string}`

### matchVolunteerToActivities
- **Type**: Callable
- **Input**: `{userId: string}`
- **Output**: `Array<{id, title, matchScore, matchExplanation, ...}>`

### monitorNewsForAlerts
- **Type**: Scheduled (every 15 minutes)
- **Auto-runs**: Yes
- **Manual trigger**: `firebase functions:shell > monitorNewsForAlerts()`

## Troubleshooting

### "Vertex AI not configured"
- Ensure Vertex AI API is enabled
- Check `gcp.project_id` is set correctly
- Verify service account permissions

### "Gemini API error"
- Check API key is valid
- Verify quota limits
- Check function logs: `firebase functions:log`

### "Embedding dimension mismatch"
- Re-run embedding functions after updating data
- Ensure all documents have embeddings before using RAG

### Functions timeout
- Increase timeout in `firebase.json`:
```json
{
  "functions": {
    "timeout": "60s"
  }
}
```

## Cost Monitoring

Monitor costs in Google Cloud Console:
- **Gemini API**: Cloud Console → APIs & Services → Dashboard
- **Vertex AI**: Cloud Console → Vertex AI → Usage
- **Cloud Functions**: Cloud Console → Cloud Functions → Metrics

## Next Steps

1. ✅ Deploy functions
2. ✅ Run initial embeddings
3. ✅ Test in Flutter app
4. ✅ Monitor Cloud Scheduler for news alerts
5. ✅ Review AI insights in Analytics screen

## Support

For issues:
1. Check function logs: `firebase functions:log`
2. Check Cloud Console for errors
3. Verify API keys and permissions
4. Test locally with emulators first

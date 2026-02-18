# Test Cloud Functions - Button Guide

This document explains what each button in the Test Functions screen does and its effects.

## Location
Navigate to: **Developer Menu → Test Cloud Functions** (`/test-functions`)

---

## Embedding Functions Section

These functions generate vector embeddings for your data, which are required for the AI Chatbot's RAG (Retrieval-Augmented Generation) feature to work properly.

### 1. `embedAllActivities` Button

**What it does:**
- Triggers the `embedAllActivities` Firebase Cloud Function
- Processes all volunteer activity listings in your Firestore `volunteer_listings` collection
- For each activity, it:
  1. Extracts text content (title, description, location)
  2. Generates a vector embedding using Vertex AI `textembedding-gecko@003` model
  3. Stores the embedding back into the activity document in Firestore

**Effects:**
- ✅ **Success**: All activities now have an `embedding` field containing a 768-dimensional vector
- ✅ Enables semantic search for activities in the AI Chatbot
- ✅ Improves matching accuracy in the Skill Matching feature
- ❌ **Error**: If Vertex AI is not configured or there's a network issue, you'll see "Failed to embed activities"

**When to use:**
- **First time setup**: Run once after deploying functions to populate embeddings
- **After adding new activities**: Run again to embed newly added activities
- **If chatbot isn't finding relevant results**: Re-run to refresh embeddings

**Expected result:**
```
✅ embedAllActivities: Success!
{success: true, count: X}
```
Where X is the number of activities processed.

---

### 2. `embedAllDrives` Button

**What it does:**
- Triggers the `embedAllDrives` Firebase Cloud Function
- Processes all donation drives in your Firestore `donation_drives` collection
- For each drive, it:
  1. Extracts text content (title, description, location, items needed)
  2. Generates a vector embedding using Vertex AI
  3. Stores the embedding back into the drive document

**Effects:**
- ✅ **Success**: All donation drives now have an `embedding` field
- ✅ Enables semantic search for drives in the AI Chatbot
- ✅ Users can find relevant drives using natural language queries
- ❌ **Error**: If Vertex AI is not configured, you'll see "Failed to embed drives"

**When to use:**
- **First time setup**: Run once after deploying functions
- **After adding new drives**: Run again to embed new drives
- **If chatbot can't find relevant drives**: Re-run to refresh embeddings

**Expected result:**
```
✅ embedAllDrives: Success!
{success: true, count: X}
```

---

### 3. `embedAllResources` Button

**What it does:**
- Triggers the `embedAllResources` Firebase Cloud Function
- Processes all aid resources in your Firestore `aid_resources` collection
- For each resource, it:
  1. Extracts text content (title, description, location, category)
  2. Generates a vector embedding using Vertex AI
  3. Stores the embedding back into the resource document

**Effects:**
- ✅ **Success**: All aid resources now have an `embedding` field
- ✅ Enables semantic search for resources in the AI Chatbot
- ✅ Users can find resources using natural language (e.g., "wheelchair", "medical supplies")
- ❌ **Error**: If Vertex AI is not configured, you'll see "Failed to embed resources"

**When to use:**
- **First time setup**: Run once after deploying functions
- **After adding new resources**: Run again to embed new resources
- **If chatbot can't find relevant resources**: Re-run to refresh embeddings

**Expected result:**
```
✅ embedAllResources: Success!
{success: true, count: X}
```

---

## Other Functions Section

### 4. `generateAIInsights` Button

**What it does:**
- Triggers the `generateAIInsights` Firebase Cloud Function
- Collects metrics from Firestore:
  - Total users
  - Total activities
  - Total donation drives
  - Total attendances
  - Total donations (sum of amounts)
- Sends metrics to Google Gemini AI to generate:
  - **Descriptive insights**: "What happened" - analysis of trends and patterns
  - **Prescriptive insights**: "What to do next" - actionable recommendations

**Effects:**
- ✅ **Success**: Returns metrics and AI-generated insights
- ✅ Insights appear in the Analytics screen (click the ✨ icon)
- ✅ Helps NGOs/admins understand platform performance
- ❌ **Partial success**: Metrics collected but AI insights failed (check Gemini API key)
- ❌ **Error**: If Firestore query fails or Gemini API is unavailable

**When to use:**
- **Viewing analytics**: Click the ✨ icon in Analytics screen (automatic)
- **Manual refresh**: Use this button to regenerate insights with latest data
- **After significant data changes**: Re-run to get updated insights

**Expected result:**
```
✅ generateAIInsights: Success!
{
  metrics: {
    totalUsers: X,
    totalActivities: Y,
    totalDrives: Z,
    totalAttendances: A,
    totalDonations: B
  },
  descriptive: "AI-generated descriptive text...",
  prescriptive: "AI-generated recommendations...",
  generatedAt: "2026-02-18T..."
}
```

**Common issues:**
- If `descriptive` or `prescriptive` show "Unable to generate...", check:
  - Gemini API key is configured correctly
  - API has sufficient quota
  - Network connectivity

---

## Functions NOT in Test Screen

These functions require a `userId` parameter and should be tested from their respective screens:

### `chatWithRAG`
- **Test location**: AI Chatbot screen (`/chatbot`)
- **What it does**: Processes user messages with semantic search
- **Requires**: User authentication + embedded data

### `matchVolunteerToActivities`
- **Test location**: Match Me screen (`/match`)
- **What it does**: Matches volunteers to activities based on skills/interests
- **Requires**: User authentication + user profile data

---

## Troubleshooting

### All embedding functions failing
1. **Check Vertex AI setup:**
   - Go to Google Cloud Console
   - Enable Vertex AI API
   - Verify GCP project ID is configured: `firebase functions:config:get`

2. **Check authentication:**
   - Functions require authentication in production
   - In emulator, auth check is bypassed

3. **Check Firestore data:**
   - Ensure you have activities/drives/resources in Firestore
   - Empty collections will return `count: 0` but won't error

### `generateAIInsights` not generating text
1. **Check Gemini API key:**
   ```bash
   firebase functions:config:get
   ```
   Should show `gemini.api_key`

2. **Check API quota:**
   - Visit Google AI Studio
   - Verify API key is active and has quota

3. **Check metrics:**
   - If all metrics are 0, insights may be empty
   - Add some test data first

---

## Best Practices

1. **Run embedding functions in order:**
   - First: `embedAllActivities`
   - Second: `embedAllDrives`
   - Third: `embedAllResources`

2. **Run after data changes:**
   - After bulk imports
   - After adding significant new content
   - If RAG results seem outdated

3. **Monitor function logs:**
   - Firebase Console → Functions → Logs
   - Check for errors or warnings

4. **Test in production:**
   - Embedding functions can take time (depends on data size)
   - Be patient, especially with large datasets
   - Check status message for progress

---

## Status Messages Explained

- **✅ Success**: Function completed successfully
- **❌ Error**: Function failed (check error message)
- **Testing...**: Function is currently running (wait for completion)
- **Ready to test**: No function has been run yet

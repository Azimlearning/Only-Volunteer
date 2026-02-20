# Deploy AI Orchestrator - Quick Fix

## Issue
Chatbot returns "I couldn't process that..." because `handleAIRequest` function is not deployed yet.

## Solution

### Step 1: Build Functions
```bash
cd functions
npm run build
```

### Step 2: Deploy Functions
```bash
firebase deploy --only functions:handleAIRequest
```

Or deploy all functions:
```bash
firebase deploy --only functions
```

### Step 3: Verify Deployment
```bash
firebase functions:list
```

Should show `handleAIRequest` in the list.

### Step 4: Test in App
1. Open chatbot screen
2. Ask: "What are current alerts?"
3. Should route to alerts tool and return formatted response

## Troubleshooting

### If function still not found:
1. Check Firebase Console → Functions → Should see `handleAIRequest`
2. Check logs: `firebase functions:log --only handleAIRequest`
3. Verify exports in `functions/src/index.ts` includes `export * from './orchestrator';`

### If function deployed but still errors:
1. Check function logs in Firebase Console
2. Verify Gemini API key: `firebase functions:config:get gemini.api_key`
3. Check rate limits aren't blocking (emulator bypasses this)

### Temporary Workaround
Until deployed, chatbot falls back to `chatWithRAG` (existing RAG function), which should still work.

## Quick Deploy Command
```bash
cd functions && npm run build && firebase deploy --only functions:handleAIRequest
```

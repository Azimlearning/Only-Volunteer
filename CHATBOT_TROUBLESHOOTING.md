# Chatbot Not Working - Troubleshooting Guide

## Problem
Chatbot returns: *"I couldn't process that. Try asking about volunteer opportunities, donation drives, or how to earn e-certificates."*

This happens because the **`handleAIRequest`** Cloud Function is not deployed yet.

---

## Quick Fix: Deploy the Function

### Step 1: Build Functions
```bash
cd functions
npm run build
```

### Step 2: Deploy
```bash
firebase deploy --only functions:handleAIRequest
```

Or deploy all functions:
```bash
firebase deploy --only functions
```

### Step 3: Verify
```bash
firebase functions:list
```

Look for `handleAIRequest` in the output.

---

## What Changed

**Before (old behavior):**
- Chatbot used `chatWithRAG` directly
- No tool routing

**After (new behavior):**
- Chatbot uses **`handleAIRequest`** orchestrator
- Routes to tools: alerts, analytics, matching, aidfinder
- Falls back to `chatWithRAG` if orchestrator fails

---

## Testing After Deployment

1. **Open chatbot** (`/chatbot`)
2. **Sign in** (required for orchestrator)
3. **Test queries**:
   - "What are current alerts?" → Should route to alerts tool
   - "How are we doing?" → Should route to analytics tool
   - "Match me" → Should route to matching tool
   - "Find nearby aid" → Should route to aidfinder tool
   - "Hello" → Should use pure Gemini chat

---

## If Still Not Working

### Check 1: Function Deployed?
```bash
firebase functions:list | Select-String "handleAIRequest"
```

If not listed → Deploy it.

### Check 2: Function Logs
```bash
firebase functions:log --only handleAIRequest
```

Look for errors:
- "Gemini API key not configured" → Set: `firebase functions:config:set gemini.api_key="YOUR_KEY"`
- "User not found" → User must exist in Firestore `users` collection
- Rate limit errors → Wait 1 minute and try again

### Check 3: Browser Console
Open browser DevTools (F12) → Console tab
Look for:
- `Orchestrator chat error: ...` → Shows actual error
- `Falling back to RAG chat...` → Orchestrator failed, using RAG

### Check 4: Authentication
- User must be **signed in** for orchestrator to work
- If not signed in, chatbot uses regular `chat()` method

### Check 5: Gemini API Key
```bash
firebase functions:config:get gemini.api_key
```

Should return your API key. If empty:
```bash
firebase functions:config:set gemini.api_key="YOUR_KEY"
firebase deploy --only functions:handleAIRequest
```

---

## Fallback Chain

The chatbot tries in this order:
1. **`chatWithOrchestrator`** → `handleAIRequest` function
2. **`chatWithRAG`** → `chatWithRAG` function (if orchestrator fails)
3. **`chat`** → Direct Gemini API (if RAG fails or not signed in)

If all fail → Shows fallback message.

---

## Expected Behavior After Deployment

**Query: "What are current alerts?"**
- Routes to **alerts tool**
- Fetches alerts from Firestore
- Formats with Gemini: *"There are currently 3 active alerts. Here's what's happening..."*

**Query: "Hello"**
- No tool matched
- Uses pure Gemini chat with context
- Response: *"Hi! I'm OnlyVolunteer AI. How can I help you today?"*

---

## Debug Mode

To see detailed errors, check:
1. **Browser Console** (F12) → Console tab
2. **Firebase Console** → Functions → Logs → `handleAIRequest`

---

## Quick Deploy Script

Save as `deploy-orchestrator.ps1`:
```powershell
cd functions
npm run build
if ($LASTEXITCODE -eq 0) {
    firebase deploy --only functions:handleAIRequest
} else {
    Write-Host "Build failed!" -ForegroundColor Red
}
```

Run: `.\deploy-orchestrator.ps1`

---

## Summary

**Root Cause**: `handleAIRequest` function not deployed  
**Solution**: Deploy with `firebase deploy --only functions:handleAIRequest`  
**After Deploy**: Chatbot will route queries to appropriate tools and return formatted responses

# Fix Chatbot CORS Error

## Problem
Console shows: **CORS error** - "No 'Access-Control-Allow-Origin' header" when calling `handleAIRequest` from the web app (localhost).

## Root Cause
Firebase callable functions can fail CORS in browsers when the preflight or response doesn’t include CORS headers (e.g. on errors). To avoid that, the web app now uses an **HTTP endpoint with explicit CORS** instead of the callable when running on web.

## Solutions Applied

### 1. HTTP endpoint with CORS (for web)
- **handleAIRequestHttp**: new `functions.https.onRequest` that sets CORS headers (`Access-Control-Allow-Origin: *`, etc.), handles OPTIONS, and runs the same logic as the callable.
- **Flutter web**: when `kIsWeb` is true, the app calls this HTTP URL with `Authorization: Bearer <idToken>` and JSON body instead of the callable, so the browser allows the request.

### 2. Shared handler
- Core logic moved to `runHandleAIRequest(data, userId)` so both the callable and the HTTP function use the same code.

### 3. Error handling and attendances
- Try-catch and attendances query fallback remain as before.

### 4. Deploy both functions

**Deploy:**
```bash
cd functions
npm run build
firebase deploy --only functions:handleAIRequest,functions:handleAIRequestHttp
```

Or deploy all functions:
```bash
firebase deploy --only functions
```

**Check function logs after calling:**
```bash
firebase functions:log --only handleAIRequest --limit 10
```

Look for:
- ✅ "handleAIRequest called" - Function is being reached
- ❌ Any error messages - Shows what's failing

**Test in browser console:**
After deploying, open browser DevTools (F12) → Console
Try calling the chatbot again and check for:
- `Orchestrator chat error: ...` - Shows actual error
- Network tab → Check the `handleAIRequest` request → Response tab

## Simple conversational replies show "Something went wrong"

If the backend is reached (no CORS errors, you see "Calling handleAIRequestHttp (web) with userId: ...") but the bot replies with "Something went wrong. Please try again.", the **Gemini API call inside the Cloud Function is failing**.

### 1. Check function logs for the real error
```bash
cd functions
firebase functions:log --only handleAIRequestHttp
```
Send a message in the chatbot, then check the logs. Look for:
- `Gemini chat error: ...` – the next line usually shows the cause (e.g. API key invalid, 400/403, quota).
- `Gemini API key not configured` – config not set or not available.

### 2. Ensure Gemini API key is set
The key must be set in **Firebase** (for the Cloud Function), not only in Flutter:
```bash
firebase functions:config:set gemini.api_key="YOUR_GEMINI_API_KEY"
```
Get the key from [Google AI Studio](https://aistudio.google.com/app/apikey) (create or copy). Then **redeploy** so the function picks up config:
```bash
npm run build
firebase deploy --only functions:handleAIRequestHttp
```

### 3. Key format and restrictions
- Key should start with `AIza` and be a long string.
- If the key has HTTP referrer or IP restrictions in AI Studio, allow your Cloud Function (or test with a key with no restrictions).

### 4. Code changes made
- **Lazy API key**: The function now reads `gemini.api_key` when handling a request (and trims quotes/whitespace), so misconfig is easier to spot.
- **Clearer logging**: The exact Gemini error is logged (e.g. `Gemini chat error: ...`). Use the steps above to see it.

---

## 403 Forbidden from Gemini (0% success in AI Studio)

If **Google AI Studio → Usage** shows **403 Forbidden** errors and **0% success rate** while your functions are being called, the API key is being **rejected** by Gemini (not missing). Common cause: **API key application restrictions**.

### Fix: Allow server-side use of the key

1. **Open [Google AI Studio](https://aistudio.google.com) → API keys** (or your project’s key settings).
2. **Edit the key** you use for `gemini.api_key` in Firebase.
3. **Application restrictions**
   - If the key is restricted to **HTTP referrers** (e.g. `localhost`, your website), **server-side** calls from Cloud Functions do **not** send a referrer, so Gemini returns **403**.
   - **Fix:** Set restrictions to **None** (for development), or use a **separate key** with no referrer restrictions for the Cloud Function.
4. **Save**, then in Firebase:
   ```bash
   firebase functions:config:set gemini.api_key="YOUR_KEY"
   firebase deploy --only functions:handleAIRequestHttp
   ```
5. **Optional:** Create a **new** API key in AI Studio with **no application restrictions**, set that in Firebase config, and redeploy. Often resolves 403 immediately.

### 404 NotFound from Gemini

If AI Studio shows **404 NotFound** instead of 403, the model ID may be wrong or deprecated. The functions now use `gemini-2.0-flash`. If 404 persists, try `gemini-1.5-flash` in `functions/src/orchestrator/gemini-formatter.ts` (constant `MODEL`).

### Other 403 causes
- **Billing:** In some regions, free tier may require billing to be enabled (or a different project).
- **Wrong project:** The key must be from the same AI Studio / Google Cloud context you expect; usage in AI Studio will show under the project that owns the key.

---

## If Still Not Working (CORS / callable)

### Check 1: Function Region
Ensure Flutter uses correct region (default is `us-central1`):
```dart
FirebaseFunctions.instanceFor(region: 'us-central1')
```

### Check 2: Authentication
- User must be signed in
- Check: `FirebaseAuth.instance.currentUser?.uid` is not null

### Check 3: Function Logs
```bash
firebase functions:log --only handleAIRequest
```

Look for execution errors (not just deployment logs).

### Check 4: Test Directly
Use Firebase Console → Functions → `handleAIRequest` → Test tab
Enter:
```json
{
  "userId": "YOUR_USER_ID",
  "message": "What are current alerts?",
  "pageContext": "chat"
}
```

If this works but Flutter doesn't → CORS/network issue
If this also fails → Function code issue

## Quick Test Script

Add to `lib/services/gemini_service.dart` temporarily:
```dart
Future<String> testOrchestrator(String userId) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('handleAIRequest');
    print('Calling handleAIRequest with userId: $userId');
    final result = await callable.call({
      'userId': userId,
      'message': 'test',
      'pageContext': 'chat',
    });
    print('Result: ${result.data}');
    return (result.data as Map)['text'] ?? 'No text';
  } catch (e, stack) {
    print('Error: $e');
    print('Stack: $stack');
    rethrow;
  }
}
```

Call from chatbot to see detailed error.

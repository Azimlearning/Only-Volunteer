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

### 2. Ensure Gemini API key is available to the function
The code reads **`GEMINI_API_KEY`** from the environment (no longer uses deprecated `functions.config()`).

- **Local / emulator:** Create `functions/.env` with:
  ```
  GEMINI_API_KEY=your_key_here
  ```
  and run with `dotenv` loaded (the functions entry point loads `dotenv/config`).
- **Production:** Because `functions/.env` is in `.gitignore`, it is not deployed. Set the variable in **Google Cloud Console**: Cloud Functions → select the function (e.g. `handleAIRequestHttp`) → Edit → Environment variables → Add `GEMINI_API_KEY` with your key. Alternatively, use [Secret Manager](https://firebase.google.com/docs/functions/config-env#secret-manager) and reference it in the function.

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

If AI Studio shows **404 NotFound** or "model is no longer available to new users", the model ID may be wrong or deprecated. The functions use **`gemini-2.5-flash`** (set in `functions/src/gemini-config.ts`). If that model is unavailable in your project, change `GEMINI_MODEL` there and rebuild.

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

---

## Chat fallback chain (so the bot always responds)

The chatbot now uses a **3-level fallback** so users get a reply even when the backend fails:

1. **Orchestrator** (signed-in): `handleAIRequestHttp` with tools (alerts, matching, analytics, aid finder).
2. **RAG** (signed-in): `chatWithRAG` (Firebase callable) if orchestrator fails.
3. **Client Gemini**: direct `chat()` using `GEMINI_API_KEY` from `--dart-define` (or a friendly “add API key” message if unset).

So for simple prompts like “hello”, the app will still respond via client-side Gemini if the Cloud Function is down or returns an error. Run the app with:

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key
```

so the client fallback has a key.

---

## Optional: Flutter AI Toolkit (Firebase AI Logic)

The [Flutter AI Toolkit](https://docs.flutter.dev/ai/ai-toolkit) provides `LlmChatView` and `FirebaseProvider` for a first-party chat UI with streaming, voice, and attachments. It uses **Firebase AI Logic** (no CORS, no manual API key in app code).

To use it you must:

1. **Upgrade Firebase** to a version that supports `firebase_ai` (e.g. `firebase_core: ^4.4.0` and related FlutterFire packages), because `firebase_ai` currently requires `firebase_core ^4.3.0`.
2. **Enable Firebase AI Logic** in your Firebase project ([Get started](https://firebase.google.com/docs/ai-logic/get-started)).
3. Add dependencies: `flutter_ai_toolkit: ^1.0.0`, `firebase_ai: ^3.8.0`.
4. Use `LlmChatView(provider: FirebaseProvider(model: FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash')))` as the chat body.

Until you upgrade Firebase, the existing chatbot (orchestrator → RAG → client Gemini fallback) remains the supported path.

---

## Deploy verification (run from `functions/`)

Commands must be run from the **`functions/`** folder, not the project root.

### 1. Where is `.env`?

- **Correct:** `functions/.env` (inside the functions folder).
- **Wrong:** project root `.env` — that is not loaded by the Functions build/runtime.
- `functions/.env` is in `functions/.gitignore` and is **not deployed**. Use it only for local emulator. For production, set **GEMINI_API_KEY** in Cloud Console (see below).

### 2. Check `.env` (from project root or from `functions/`)

```powershell
cd functions
Get-Content .env
```

You should see a line like `GEMINI_API_KEY=...`. If the file is missing, create `functions/.env` with that line.

### 3. Build and check compiled output

From **`functions/`**:

```powershell
cd functions
npm run build
Select-String -Path "lib\gemini-config.js" -Pattern "GEMINI_MODEL|GEMINI_API_KEY"
Select-String -Path "lib\orchestrator\gemini-formatter.js" -Pattern "GEMINI_MODEL|getGeminiApiKey"
```

- **Expected:** `lib/gemini-config.js` contains `GEMINI_MODEL = 'gemini-2.5-flash'` and `process.env.GEMINI_API_KEY`.
- **Expected:** No `functions.config().gemini` in any `lib/**/*.js` (all Gemini usage now goes through `gemini-config` and `process.env.GEMINI_API_KEY`).

### 4. Deploy and set env in production

**Deploy code (from project root):**
```powershell
cd functions
npm run build
firebase deploy --only functions
```

**Set `GEMINI_API_KEY` for production:**  
The Console **Edit** button is not available for **1st Gen** Cloud Functions. Do it from the CLI. **Important:** run from the **OnlyVolunteer project folder** and use `--source=functions` so gcloud uploads only the functions folder (otherwise it may use the current directory and exceed the 512 MB limit):

```powershell
# 1) Go to project root (not the Google Cloud SDK folder)
cd c:\Users\User\Documents\Coding\Hackathon\OnlyVolunteer

# 2) Set env var on each function (replace YOUR_GEMINI_API_KEY with your key)
gcloud functions deploy handleAIRequestHttp --update-env-vars GEMINI_API_KEY=YOUR_GEMINI_API_KEY --region us-central1 --source=functions

gcloud functions deploy chatWithRAG --update-env-vars GEMINI_API_KEY=YOUR_GEMINI_API_KEY --region us-central1 --source=functions
```

Optional: `gcloud config set project onlyvolunteer-e3066` first if needed. The repo has a `functions/.gcloudignore` so `node_modules` is not uploaded (Cloud Build runs `npm install` on deploy). Other Gemini-using functions can be updated the same way if they need the key.

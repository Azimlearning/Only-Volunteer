# Testing Firebase Functions - Alternative Methods

Since the Firebase Console doesn't show a "Test" button, here are working alternatives:

## Method 1: Test from Flutter App (Easiest)

Your functions are already integrated! Just use the app:

### Test RAG Chatbot:
1. Run your Flutter app: `flutter run -d chrome --dart-define=GEMINI_API_KEY=AIzaSyD9I8ZLMRmtaRwyq0EylLIq8rNDgt58_uQ`
2. Log in
3. Go to **AI Chatbot** screen
4. Ask: "Find volunteer opportunities for teaching"
5. Should use semantic search

### Test AI Analytics:
1. Log in as NGO/Admin user
2. Go to **Analytics** screen
3. Click the **AI icon** (auto_awesome button)
4. Should show descriptive and prescriptive insights

### Test Skill Matching:
1. Log in
2. Go to **Match Me** screen
3. Add skills/interests
4. Click **"Save & find matches"**
5. Should show matches with AI explanations

## Method 2: Google Cloud Console (Has Test Feature)

1. Go to: https://console.cloud.google.com/functions/list?project=onlyvolunteer-e3066
2. Click on a function (e.g., `embedAllActivities`)
3. Click **"TEST"** tab at the top
4. Enter: `{}`
5. Click **"TEST THE FUNCTION"**

This has the test feature Firebase Console is missing!

## Method 3: Direct HTTP Call (Requires Auth Token)

Since these are callable functions, you need an auth token. Get one from your Flutter app:

```powershell
# In Flutter app, after login, get the ID token
# Then use it in HTTP request:

$token = "YOUR_ID_TOKEN_HERE"
$url = "https://us-central1-onlyvolunteer-e3066.cloudfunctions.net/embedAllActivities"

Invoke-RestMethod -Uri $url `
  -Method Post `
  -Headers @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
  } `
  -Body '{"data":{}}'
```

## Method 4: Create a Test Screen in Flutter

Add a temporary admin screen to test functions:

```dart
// In your Flutter app, create a test screen
Future<void> testEmbeddings() async {
  final callable = FirebaseFunctions.instance.httpsCallable('embedAllActivities');
  final result = await callable.call();
  print('Result: ${result.data}');
}
```

## Method 5: Use Firebase CLI with Auth

```powershell
# Get your auth token first
firebase login:list

# Then call via HTTP with token
# (See Method 3 for HTTP call format)
```

## Recommended: Use Google Cloud Console

**Go here:** https://console.cloud.google.com/functions/list?project=onlyvolunteer-e3066

This has the **"TEST"** tab that Firebase Console is missing!

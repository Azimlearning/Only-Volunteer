# Running Initial Embeddings

The embedding functions require authentication. Here are **3 ways** to run them:

## Option 1: Use Firebase Console (Easiest)

1. Go to: https://console.firebase.google.com/project/onlyvolunteer-e3066/functions
2. Click on each function: `embedAllActivities`, `embedAllDrives`, `embedAllResources`
3. Click "Test" tab
4. Enter empty JSON: `{}`
5. Click "Test function"
6. Repeat for all three functions

## Option 2: Call from Flutter App (After Login)

1. Log in to your Flutter app as an admin user
2. Navigate to a screen that can call Cloud Functions
3. Or add a temporary admin button to call these functions

## Option 3: Use Firebase CLI Shell

```powershell
# Start the shell
firebase functions:shell

# Then run these commands one by one:
embedAllActivities({})
embedAllDrives({})
embedAllResources({})
```

**Note:** The shell requires you to be authenticated. Make sure you're logged in:
```powershell
firebase login
```

## Option 4: Use HTTP Requests (Advanced)

If you have an ID token, you can call them via HTTP:

```powershell
# Get your ID token first (from Firebase Auth)
$token = "YOUR_ID_TOKEN"

# Call embedAllActivities
Invoke-RestMethod -Uri "https://us-central1-onlyvolunteer-e3066.cloudfunctions.net/embedAllActivities" `
  -Method Post `
  -Headers @{"Authorization"="Bearer $token"} `
  -ContentType "application/json" `
  -Body '{}'
```

## Quick Test

After running embeddings, test the RAG chatbot:
1. Go to AI Chatbot screen in your Flutter app
2. Ask: "Find volunteer opportunities for teaching"
3. The chatbot should use semantic search to find relevant activities

## Verify Embeddings

Check Firestore to see if documents have an `embedding` field:
- Go to Firestore Console
- Check a document in `volunteer_listings`, `donation_drives`, or `aid_resources`
- Look for an `embedding` field (array of numbers)

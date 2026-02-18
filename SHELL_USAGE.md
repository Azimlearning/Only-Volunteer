# Using Firebase Functions Shell

## Current Issue

The shell is running but functions need:
1. ✅ Config values (`.runtimeconfig.json` created)
2. ✅ Auth bypass for emulator (code updated)
3. ⚠️  Vertex AI initialization

## Solution: Use Deployed Functions Instead

Since your functions are **already deployed** and working, the easiest way is to call them via **Firebase Console**:

### Step 1: Go to Firebase Console
https://console.firebase.google.com/project/onlyvolunteer-e3066/functions

### Step 2: Test Each Function
1. Click on `embedAllActivities`
2. Click **"Test"** tab
3. Enter: `{}`
4. Click **"Test function"**
5. Wait for completion
6. Repeat for `embedAllDrives` and `embedAllResources`

## Why This Works Better

- ✅ Functions have access to config
- ✅ Vertex AI is properly initialized
- ✅ No authentication issues
- ✅ Uses production Firestore (where your data is)

## Alternative: Fix Shell Setup

If you want to use the shell, you need to:

1. **Restart the shell** (it should pick up `.runtimeconfig.json`)
2. **Make sure Vertex AI API is enabled**
3. **Call functions with proper syntax**

But Console method is **much easier** and **more reliable**!

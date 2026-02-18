# Quick Guide: Run Embeddings

## ✅ Easiest Method: Firebase Console

1. **Go to Firebase Console:**
   https://console.firebase.google.com/project/onlyvolunteer-e3066/functions

2. **For each function, click "Test" and run:**
   - `embedAllActivities` → Test with `{}`
   - `embedAllDrives` → Test with `{}`
   - `embedAllResources` → Test with `{}`

## 🔧 Alternative: Firebase Shell

Open PowerShell and run:

```powershell
firebase functions:shell
```

**Important:** You need to be authenticated first:
```powershell
firebase login
```

Then in the shell, type each command:
```
embedAllActivities({})
embedAllDrives({})
embedAllResources({})
```

Type `.exit` to quit the shell.

## ⚠️ Note

These functions require authentication. If you get permission errors:
1. Make sure you're logged in: `firebase login`
2. Make sure your user has admin/developer role in Firestore
3. Or use Firebase Console method instead

## ✅ Verify It Worked

After running, check Firestore:
- Documents should have an `embedding` field (array of ~768 numbers)
- Test the chatbot - it should use semantic search now!

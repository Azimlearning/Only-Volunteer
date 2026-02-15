# Firebase setup (before first run)

Project ID: **onlyvolunteer-e3066**

## 1. Firebase Console (do these once)

Open [Firebase Console](https://console.firebase.google.com) and select project **onlyvolunteer-e3066** (or create it and add a Web app to get `firebase_options.dart`).

### Authentication
1. Go to **Build → Authentication**.
2. Click **Get started** if needed.
3. Open the **Sign-in method** tab.
4. Enable **Email/Password** (turn on, save).
5. Enable **Google** (turn on, choose support email, save).

### Firestore
1. Go to **Build → Firestore Database**.
2. Click **Create database** if you don’t have one yet.
3. Choose **Start in test mode** for development, then pick a location (e.g. `us-central1`) and enable.
4. After the database exists, deploy rules from your machine (see step 2 below). Rules have already been deployed once; re-run deploy if you change `firestore.rules`.
5. Indexes: deploy with `firebase deploy --only firestore:indexes` (may only work after the database exists). If that fails, run the app and use the index-creation link Firebase shows in the console when a query needs an index.

### Storage (optional, for images)
1. Go to **Build → Storage**.
2. Click **Get started**.
3. Use the default rules for now (or deploy custom rules later for production).

---

## 2. Deploy rules and indexes (from project root)

Install Firebase CLI if needed:

```bash
npm install -g firebase-tools
```

Log in and select the project:

```bash
firebase login
firebase use onlyvolunteer-e3066
```

Deploy Firestore rules and indexes:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

Or both in one go:

```bash
firebase deploy --only firestore
```

After this, your local `firestore.rules` and `firestore.indexes.json` are active for **onlyvolunteer-e3066**.

---

## 3. Quick check

- **Auth:** Try signing up / signing in (email or Google) in the app.
- **Firestore:** Create a drive or a post; it should read/write without permission errors.
- If you see “missing index” in the app, open the link in the error message to create the index in the Console, or re-run `firebase deploy --only firestore:indexes` after adding the index to `firestore.indexes.json`.

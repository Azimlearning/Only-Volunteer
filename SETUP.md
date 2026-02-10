# OnlyVolunteer – Setup Steps 1–4 and Test Run

Follow these in order. Commands are for PowerShell on Windows.

**Quick start (if Flutter is already at C:\flutter):**  
Open PowerShell in the project folder and run:

```powershell
.\run_setup.ps1
```

Then run the app (replace with your Gemini key):

```powershell
.\run_test.ps1 -GeminiKey "YOUR_GEMINI_API_KEY"
```

---

## Step 1: Flutter on PATH

Flutter has been cloned to `C:\flutter` for you. Add it to your PATH so it works in any terminal.

### Option A – Add C:\flutter\bin to PATH (do this now)

1. Add Flutter to your user PATH:
   - Press Win + R, type `sysdm.cpl`, Enter → Advanced → Environment Variables.
   - Under "User variables", select **Path** → Edit → New → add: `C:\flutter\bin`
   - OK out. **Close and reopen** PowerShell/terminal (and Cursor if you use its terminal).

2. In a **new** PowerShell, verify:

   ```powershell
   flutter --version
   flutter doctor
   ```

   The first run may download the Dart SDK (a few minutes).

### Option B – Install from zip (if you don’t have C:\flutter)

1. Download: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip  
2. Extract to `C:\flutter` (so you have `C:\flutter\bin\flutter.bat`).
3. Add `C:\flutter\bin` to your user PATH (same as in Option A step 2).
4. In a **new** PowerShell: `flutter doctor`

---

## Step 2: Firebase

1. **Create a Firebase project**
   - Go to https://console.firebase.google.com
   - Add project (e.g. "OnlyVolunteer") and follow the wizard.

2. **Enable services**
   - **Authentication** → Get started → enable **Email/Password** and **Google**.
   - For **Google** sign-in: under "Support email for project" choose your email from the dropdown (required to save). Optionally set a "Public-facing name" if you like.
   - **Firestore Database** → Create database → Start in test mode (or set rules as in `firestore.rules`).
   - **Storage** → Get started → use default.

3. **Register a Web app**
   - Project Overview → Add app → Web (</>).
   - Register app (e.g. "OnlyVolunteer Web"), then copy the `firebaseConfig` snippet (you can ignore it for now if using FlutterFire CLI).

4. **Configure Flutter (FlutterFire CLI)**
   In the project folder:

   ```powershell
   cd "c:\Users\User\Documents\Coding\Hackathon\OnlyVolunteer"
   dart pub global activate flutterfire_cli
   flutter pub get
   flutterfire configure
   ```

   - Sign in with Google if asked.
   - Select your Firebase project and (when asked) the platforms (at least **web**).
   - This overwrites `lib/firebase_options.dart` with real values.

---

## Step 3: Gemini API key

1. Get a key: https://aistudio.google.com/apikey  
2. Create an API key and copy it.

3. **Run the app with the key** (no need to put it in the repo):

   ```powershell
   flutter run -d chrome --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
   ```
   Or use the helper script: `.\run_test.ps1 -GeminiKey "YOUR_KEY_HERE"`

---

## Step 4: Google Maps (optional)

Use the **same Google Cloud project** as your Firebase app (e.g. the one for OnlyVolunteer, not "new project 2").

1. **Select the right project**
   - Go to [Google Cloud Console](https://console.cloud.google.com).
   - Click the project dropdown at the top and choose the project linked to your Firebase app (e.g. **onlyvolunteer-e3066** or the name that matches your Firebase project). Do **not** use "new project 2" unless that is your Firebase project.

2. **Enable Maps JavaScript API**
   - In the left sidebar go to **Google Maps Platform** → **APIs & Services** (or open [APIs & Services](https://console.cloud.google.com/apis/library) and ensure the correct project is selected).
   - Under "Find the right map products", find **Maps JavaScript API** ("Maps for your website").
   - Click **Enable** for that API.

3. **Create or use an API key**
   - Go to **APIs & Services** → **Credentials**.
   - Click **Create credentials** → **API key**. Copy the key (you can restrict it later to HTTP referrers and Maps JavaScript API).

4. **Add the key to the app**
   - Open `web/index.html` and find the line with `YOUR_MAPS_KEY`.
   - Replace `YOUR_MAPS_KEY` with your Maps API key so it looks like:  
     `...maps/api/js?key=YOUR_ACTUAL_KEY`

---

## Run for testing

From the project root in a **new** PowerShell (so PATH and env are correct):

```powershell
cd "c:\Users\User\Documents\Coding\Hackathon\OnlyVolunteer"
flutter pub get
flutter run -d chrome --dart-define=GEMINI_API_KEY=YOUR_GEMINI_KEY
```

Use your real Gemini key. Chrome should open with the app.  
If you see Firebase errors, run `flutterfire configure` again and ensure Auth, Firestore, and Storage are enabled.

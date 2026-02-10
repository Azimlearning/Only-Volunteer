# Only-Volunteer

Comprehensive Volunteer &amp; Aid Management Platform with AI-powered features - Flutter Web + Firebase + Google Gemini.

## Tech Stack

- **Frontend**: Flutter Web
- **Backend**: Firebase (Auth, Firestore, Storage)
- **AI**: Google Gemini API
- **Maps**: Google Maps
- **Analytics**: Firestore → BigQuery / Looker (optional)

## Setup

1. Install [Flutter](https://flutter.dev/docs/get-started/install) and ensure it's on your PATH.
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Create a project at [Firebase Console](https://console.firebase.google.com).
   - Enable Auth (Email/Password + Google), Firestore, Storage.
   - Run `dart pub global activate flutterfire_cli` then `flutterfire configure` to generate `lib/firebase_options.dart`.
4. Add Gemini API key:
   - Use `GEMINI_API_KEY` via `--dart-define` as described in `lib/core/config.dart`.
   - Example: `flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key`
5. Google Maps: add your Maps key in `web/index.html` script tag.
6. Run web:
   ```bash
   flutter run -d chrome
   ```

## Project Structure

- `lib/main.dart` - Entry point
- `lib/app/` - App shell, routing, theme
- `lib/features/` - Feature modules (aid, volunteer, social, gamification, analytics, ai)
- `lib/core/` - Shared models, services, config
- `lib/models/` - Firestore/data models

## Analytics (BigQuery / Looker)

In-app analytics use Firestore counts (see Analytics screen). To push events to BigQuery:

1. Enable the [Firebase BigQuery export](https://firebase.google.com/docs/analytics/bigquery-export) for your project, or
2. Use Cloud Functions to write key events (e.g. sign-ups, volunteer hours, donations) to BigQuery.
3. Connect Looker to that BigQuery dataset for dashboards.

## License

Proprietary - KitaHack 2026.

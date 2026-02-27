# Only-Volunteer

Comprehensive Volunteer &amp; Aid Management Platform with AI-powered features - Flutter Web + Firebase + Google Gemini.

## Tech Stack

- **Frontend**: Flutter Web
- **Backend**: Firebase (Auth, Firestore, Storage)
- **AI**: Google Gemini API
- **Maps**: Google Maps
- **Analytics**: Firestore → BigQuery / Looker (optional)

## Core AI Features ✨
Our platform heavily utilizes AI to provide the best experience. These are our 5 main AI-powered features:
1. **Aid Finder using AI**: Intelligently helps users locate and request necessary resources and aid.
2. **AI Matching System**: Evaluates volunteer profiles against opportunities to provide the best matches with detailed explanations.
3. **AI Analytics**: Generates descriptive and prescriptive insights from volunteer and donation data.
4. **AI News Alerts**: Monitors emergencies via news APIs and triggers alerts for immediate volunteer responses.
5. **AI Chatbot with Tool Calling**: A conversational AI focused on the platform that can intelligently route and call the other 4 AI features to assist users seamlessly.

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

## Project Structure & Documentation

- `lib/main.dart` - Entry point
- `lib/app/` - App shell, routing, theme
- `lib/features/` - Feature modules (aid, volunteer, social, gamification, analytics, ai)
- `lib/core/` - Shared models, services, config
- `lib/models/` - Firestore/data models

**Detailed Documentation:**
- [Project Documentation](docs/project_documentation.md) - Deep dive into architecture, specific AI features, modules, and components.
- [Tech Stack](docs/techstack.md) - Information regarding frameworks, libraries, and external integrations.

## Analytics (BigQuery / Looker)

In-app analytics use Firestore counts (see Analytics screen). To push events to BigQuery:

1. Enable the [Firebase BigQuery export](https://firebase.google.com/docs/analytics/bigquery-export) for your project, or
2. Use Cloud Functions to write key events (e.g. sign-ups, volunteer hours, donations) to BigQuery.
3. Connect Looker to that BigQuery dataset for dashboards.

## License

Proprietary - KitaHack 2026.

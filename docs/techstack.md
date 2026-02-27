# OnlyVolunteer - Technology Stack

## 1. Frontend Development
- **Framework**: Flutter (Dart) 
- **Platforms**: Web (Primary target for the hackathon)
- **State Management**: Provider (`package:provider`)
- **Routing**: Go Router (`package:go_router`)
- **UI & Design**: Material Design (`uses-material-design: true`), Custom Theming
- **Graphics & Visualization**: FL Chart (`package:fl_chart`)
- **PDF Generation**: `package:pdf`
- **Markdown Rendering**: `package:flutter_markdown` (for AI Chatbot responses)

## 2. Backend Services (Firebase)
- **Authentication**: Firebase Auth (Email/Password, Google Sign-In)
- **Database**: Cloud Firestore (NoSQL Document Database)
- **Storage**: Cloud Storage for Firebase
- **Compute**: Cloud Functions for Firebase (Node.js, TypeScript)
- **Hosting**: Firebase Hosting (Optional, for deploying the web app)

## 3. Artificial Intelligence & Machine Learning
- **Google Gemini API**: Used via `package:google_generative_ai` in Flutter.
- **Vertex AI**: Used via Cloud Functions to power Retrieval-Augmented Generation (RAG) capabilities.
- **AI Features (The Core 5)**:
  - **Aid Finder using AI**: Assesses and categorizes user requests to help find nearby resources dynamically.
  - **AI Matchmaking System**: Evaluates and matches volunteers with relevant activities, providing a "match score" and an explanation for why they are a good fit.
  - **AI Analytics**: Generates both descriptive and prescriptive analytics from platform data.
  - **AI News Alerts**: Utilizes external news APIs to formulate real-time emergency alerts using Gemini.
  - **AI Chatbot with Tool Calling**: A comprehensive conversational AI assistant that can answer platform-specific questions and inherently trigger/call the other 4 AI features depending on user needs.

## 4. Location & Maps
- **Google Maps**: Google Maps JavaScript API.
- **Flutter Integration**: `package:google_maps_flutter`

## 5. Third-Party APIs
- **GNews API**: For automated news alerts gathering (running via Cloud Functions scheduled jobs).
- **News API**: Alternative API for external news data (can be used in conjunction with or as a fallback for GNews).

## 6. Utilities & Tooling
- **Linting**: `flutter_lints`
- **Testing**: `flutter_test`, `test_api`
- **Other Utils**: `shared_preferences` (local caching/persistence), `uuid` (unique identifiers), `intl` (localization and formatting), `http` (network requests), `url_launcher` (external links).

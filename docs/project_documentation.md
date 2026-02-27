# OnlyVolunteer - Project Documentation

## 1. Overview
**OnlyVolunteer** is a comprehensive Volunteer & Aid Management Platform engineered for the KitaHack 2026 hackathon. The platform aims to bridge the gap between volunteers, people in need, and organizing communities. It leverages Flutter Web as the frontend, Firebase for the backend infrastructure, and integrates cutting-edge Google Gemini & Vertex AI capabilities to perform matchmaking, analytics, and intelligent conversational features.

## 2. Core Modules & Features

### 2.1 Home & Navigation
- A central dashboard that redirects users based on their intents.
- Provides a responsive shell (`AppShell`) powered by `GoRouter` to easily traverse between tabs.

### 2.2 Aid Management
- **Aid Finder**: Allows users to find nearby resources or request aid.
- **Donation Drives**: Lists ongoing and past donation campaigns.
- **Creation Tools**: Users can initiate new aid requests or create new donation drives.

### 2.3 Volunteer Opportunities
- **Listings**: Volunteers can browse opportunities that match their skills.
- **Opportunity Creation**: Organizers can post volunteer roles.
- **Requests & Support**: Users can track their support requests or offer help via `MyRequestsScreen` and `RequestSupportScreen`.

### 2.4 Social & Community
- A collaborative space for volunteers to discuss, share experiences, and make posts.
- Helps build a strong volunteer community around the platform.

### 2.5 Gamification
- Tracks volunteer hours, missions completed, and assigns points and badges.
- Keeps users motivated and engaged in the ecosystem.

### 2.6 Analytics & Reporting
- Gives organizers insights into volunteer impact, donation metrics, and drive outcomes.
- Includes AI-generated insights (descriptive and prescriptive) using Gemini, breaking down statistics and proposing optimizations.

### 2.7 AI Integration (Gemini & Vertex AI) - The Core 5 Features
Our platform is built around 5 major AI pillars that provide an advanced, user-centric experience:

1. **Aid Finder using AI (`AidFinderScreen`)**: 
   - **How it Works**: When a user inputs a natural language description of what they need (e.g., "I need blankets for a flood victim"), the AI processes the request using Gemini. It extracts keywords, determines urgency, and maps the request to pre-defined resource categories in the Firestore database.
   - **Benefit**: Users don't need to manually filter through complex forms; they can simply type what they need in conversational language, and the AI will dynamically surface the most relevant local aid pools, shelters, or supply drops from the platform.

2. **AI Matching System (`MatchScreen`)**: 
   - **How it Works**: This system utilizes Gemini/Vertex AI via a Cloud Function (`matchVolunteerToActivities`) to analyze a volunteer's entire profile—including their listed skills, past volunteer history, current physical location, and personal preferences. It then cross-references this profile against all open donation drives and volunteer opportunities in Firestore.
   - **Output**: The system returns a curated list of opportunities, calculating a percentage-based **"Match Score"** and generating a distinct, natural language **"Match Explanation"** (e.g., "This event is an 85% match because it requires your medical background, and it's located 2 miles from you.").

3. **AI Analytics (`AnalyticsScreen`)**: 
   - **How it Works**: Instead of static dashboards, organizers can click an "AI Insights" button which passes aggregated backend data (number of volunteers, hours logged, aid distributed) through a dedicated Cloud Function (`generateAIInsights`) into the Gemini API. 
   - **Output**: The AI returns **Descriptive Analytics** (summarizing the data narratively to explain *what* happened) and **Prescriptive Analytics** (providing actionable advice on *what to do next*, such as "Increase outreach for medical volunteers next week based on current aid request trends").

4. **AI News Alerts (`AlertsScreen`)**: 
   - **How it Works**: A scheduled Cloud Function (`monitorNewsForAlerts`) runs periodically (e.g., every 15 minutes) and uses the GNews or NewsAPI to fetch real-time news headlines related to regional emergencies or disasters (e.g., floods, fires). 
   - **Processing**: The raw news data is fed into Gemini to determine relevance and extract actionable intelligence.
   - **Action**: If a critical event is detected, the AI formulates an emergency alert and publishes it directly to the platform, instantly notifying relevant volunteers to mobilize or prepare.

5. **AI Chatbot with Tool Calling (`ChatbotScreen`)**: 
   - **How it Works**: The chatbot is powered by Vertex AI and utilizes a Retrieval-Augmented Generation (RAG) architecture. Regular Cloud Functions (`embedAllActivities`, `embedAllDrives`) convert Firestore data into vector embeddings. When a user asks a question, the chatbot performs a semantic search over these embeddings to provide accurate, context-aware answers based solely on the current platform state.
   - **Tool Calling Integration**: Beyond answering queries, the AI Chatbot possesses **Agentic Tool Calling capabilities**. It acts as a central router; if a user says "Find me activities that match my skills," the Chatbot natively executes the `matchVolunteerToActivities` tool in the backend and returns the formatted response within the chat window, effectively bridging all 5 AI features into one accessible interface.

### 2.8 Administrative Controls
- **Developer Screen** & **Test Functions Screen**: Allows administrators to check APIs, manually trigger Cloud Functions, and handle metadata resets.

## 3. Architecture Design

The app follows a feature-first architectural approach:
- **`lib/app/`**: Contains the App Shell, routing management (`GoRouter`), and global theme setup.
- **`lib/core/`**: Hosts shared configurations, routing maps, constants, and utilities.
- **`lib/features/`**: Code is modularized by feature (e.g., `ai`, `aid`, `analytics`, `auth`, `common`, `gamification`, `home`, `opportunities`, `social`, `volunteer`). Each folder encapsulates its own UI screens, logic, and state if necessary.
- **`lib/models/`**: Shared data models mapped to Firestore documents.
- **`lib/providers/`**: Global state management objects (e.g., `AuthNotifier`).
- **`lib/services/`**: Abstracts out network, Firebase, or external API calls (e.g., `AuthService`, `FirestoreService`).
- **`functions/`**: The backend logic implemented using Firebase Cloud Functions (Node.js/TypeScript). Functions generate embeddings, trigger alerts, and provide server-side AI solutions.

## 4. Data Flow
1. **Frontend to Backend**: The Flutter application predominantly talks to Cloud Firestore via the official FlutterFire SDKs.
2. **AI & Cloud Functions**: For computationally intensive tasks (e.g., matching volunteer profiles, calling Google AI/Vertex APIs), Flutter makes a callable request to Cloud Functions.
3. **Data Embedding**: Firestore data (activities, resources) is periodically embedded into vector representations to power the AI Chatbot's RAG system.

## 5. Deployment Information
Refer to `DEPLOYMENT_GUIDE.md` for information on setting up Vertex AI, GNews variables, and deploying Cloud Functions. Refer to `SETUP.md` for local testing instructions.

# OnlyVolunteer - Project Documentation & Hackathon Submission

## 1. Overview
**OnlyVolunteer** is a comprehensive Volunteer & Aid Management Platform engineered for the KitaHack 2026 hackathon. The platform aims to bridge the gap between volunteers, people in need, and organizing communities. It leverages Flutter Web as the frontend, Firebase for the backend infrastructure, and integrates cutting-edge Google Gemini & Vertex AI capabilities to perform matchmaking, analytics, and intelligent conversational features.

### Problem Statement & SDG Alignment
During crises and everyday community support, there is a massive disconnect between people who want to help (volunteers, donors) and those in need (organizations, victims). People willing to volunteer often don't know where their skills are most needed, and organizations struggle to efficiently match tasks with the right people. This matters because inefficient aid distribution and volunteer mobilization lead to delayed relief, wasted resources, and burnout among community organizers.

**Sustainable Development Goals:**
- **Goal 11: Sustainable Cities and Communities.** (Target 11.B: Increase resilience to disasters)
- **Goal 10: Reduced Inequalities.** (Target 10.2: Empower and promote the social, economic and political inclusion of all)

OnlyVolunteer directly supports **Goal 11** by providing an intelligent platform that mobilizes volunteers and distributes aid rapidly during emergencies. Our AI News Alerts feature preemptively notifies communities to prepare and respond to crises. It supports **Goal 10** by ensuring that aid requests are visible and accessible, giving marginalized or deeply affected communities a voice to request specific help efficiently using our AI Aid Finder.

---

## 2. Core Modules & AI Features

### The Core 5 AI Features ✨
Our platform heavily utilizes AI to provide the best experience, effectively treating AI as the core routing engine for the entire platform. Without AI, the platform loses its core value proposition.

1. **Aid Finder using AI (`AidFinderScreen`)**: 
   - **How it Works**: When a user inputs a natural language description (e.g., "I need blankets for a flood victim"), the AI processes the request using Gemini. It extracts keywords, determines urgency, and maps the request to pre-defined resource categories in the Firestore database.
2. **AI Matching System (`MatchScreen`)**: 
   - **How it Works**: Utilizes Gemini/Vertex AI via a Cloud Function to analyze a volunteer's entire profile (skills, history, location, preferences) against open donation drives and volunteer opportunities.
   - **Output**: Returns a curated list with a percentage-based **"Match Score"** and generating a distinct, natural language **"Match Explanation"**.
3. **AI Analytics (`AnalyticsScreen`)**: 
   - **How it Works**: Organizers click "AI Insights" to pass aggregated backend data through Gemini.
   - **Output**: The AI returns **Descriptive Analytics** (summarizing what happened) and **Prescriptive Analytics** (actionable advice on what to do next).
4. **AI News Alerts (`AlertsScreen`)**: 
   - **How it Works**: A scheduled Cloud Function monitors GNews/NewsAPI for real-time news related to regional emergencies. Gemini extracts actionable intelligence.
   - **Action**: If a critical event is detected, the AI publishes an emergency alert directly to the platform.
5. **AI Chatbot with Tool Calling (`ChatbotScreen`)**: 
   - **How it Works**: Powered by Vertex AI using a Retrieval-Augmented Generation (RAG) architecture. It possesses **Agentic Tool Calling capabilities**. It can natively execute backend Cloud Functions (like `matchVolunteerToActivities`) natively in the chat workflow to intelligently route and assist users seamlessly.

### Technology Innovation
Unlike existing platforms, OnlyVolunteer uniquely leverages an **Agentic AI architecture**. Our Chatbot doesn't just answer FAQs; it can execute backend Cloud Functions natively in the chat workflow. We treat AI not as an add-on feature, but as the core routing engine for the entire platform.

---

## 3. Prototype Documentation

### Technical Architecture
Our architecture is feature-first. The **Flutter Web UI** handles presentation and local state management using Provider. It executes CRUD operations directly against **Cloud Firestore** for standard data. For complex tasks (AI matching, embeddings, news alerts), Flutter calls secure **Firebase Cloud Functions**. These Node.js functions act as middleware, communicating with the **Gemini API** and **Vertex AI**. This structure ensures the frontend remains lightweight while computationally heavy AI tasks are securely handled off-device.

- **Frontend**: Flutter Web (Chosen for its fast development cycle, expressive UI, and future mobile deployment potential).
- **Backend / Database**: Firebase Auth, Firestore, Storage (Chosen for real-time data syncing, seamless Flutter integration, and out-of-the-box scalability).
- **Middleware / AI Logic**: Firebase Cloud Functions (Node.js/TypeScript) encapsulating secure operations calling Gemini via `google_generative_ai` and Vertex AI.
- **Maps Integration**: Google Maps API (Crucial for location-based aid requests and volunteer event mapping).

### Implementation Details
We traded the deep performance of native app development for the rapid prototyping speed of **Flutter Web**, delivering a fully functional cross-platform MVP within the hackathon timeframe. We also traded a rigid relational database setup (SQL) for **Firestore's NoSQL** flexibility, allowing us to rapidly iterate on data models.

### Challenges Faced
**Challenge:** Implementing Agentic Tool Calling within the Chatbot to work seamlessly with our existing Cloud Functions. We needed the Gemini model to know when to answer a question normally vs. when to execute a function like matching a user.

**Debugging & Solution:** Initially, we tried parsing the model's text output to trigger functions, which was extremely flaky. We debugged by reviewing Gemini's latest documentation on *Function Calling*. We refactored our backend to explicitly declare tools (JSON schemas defining our functions) to the Gemini model. Now, when asked, Gemini returns a structured tool call request, our Cloud Function executes the local logic, and returns the result to Gemini to formulate the final answer.

### Future Roadmap
In 2-3 years, OnlyVolunteer could integrate with local government civic response systems and major NGOs to become the central dispatcher during national emergencies. We plan to:
1. **Mobile Deployment:** Compile the existing Flutter codebase into native iOS and Android apps.
2. **Multi-Language Support:** Integrate Google Translate API.
3. **Organization Portals:** Build dedicated administrative panels with deeper Looker integrations for enterprise NGOs.
4. **Predictive Logistics:** Use AI to forecast aid shortages *before* they happen based on weather patterns and geographic data.

Our reliance on **Firebase** naturally supports scaling to millions of real-time users. As usage scales, we plan to stream Firestore data to **BigQuery** using Firebase Extensions to build comprehensive dashboards in Looker, and utilize more sophisticated **Vertex AI Vector Search** infrastructure.

---

## 4. User Feedback & Success Metrics

### User Validation & Feedback
We conducted beta testing with local community leaders, regular volunteers, and university students using contextual scenarios.
- **Surprise:** Users strongly preferred interacting with the AI Chatbot to navigate the app rather than clicking through menus.
- **Struggle:** Initially, organizers found the analytics dashboard overwhelming. We integrated Gemini to provide AI insights (Descriptive and Prescriptive analytics), resulting in plain-text summaries of trends and actionable advice.
- **Value:** Volunteers found the "Match Explanation" in the AI Matching System incredibly valuable as it validated *why* they were chosen.
- **Improvement:** The initial Aid Finder keyword search was hard to use. We upgraded it to use natural language processing (Gemini), allowing users to type "I need baby wipes" to immediately find relevant donation drives.

### Success Metrics
1. **Time Saved in Matchmaking:** Reduction in time to successfully fill a volunteer role.
2. **Aid Response Rate:** The speed at which an aid request goes from "posted" to "fulfilled."
3. **Volunteer Engagement Retention:** Percentage of volunteers applying for subsequent opportunities.
We utilize **Firebase Analytics** to track user journeys and interaction events to prove these metrics.

---

## 5. Setup & Development Guide 

**Prerequisites:**
1. Install [Flutter](https://flutter.dev/docs/get-started/install) and ensure it's on your PATH.
2. Create a project at [Firebase Console](https://console.firebase.google.com), enable Auth (Email/Password + Google), Firestore, and Storage.

**Installation:**
```bash
# Get Flutter dependencies
flutter pub get

# Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure
```

**API Keys Required:**
- **Gemini API Key**: Passed via `--dart-define`
- **Google Maps API Key**: Placed in `web/index.html` script tag

**Run Web App Locally:**
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_gemini_api_key_here
```

**Project Structure Overview:**
- `lib/main.dart` - Entry point
- `lib/app/` - App shell, routing, theme
- `lib/features/` - Feature modules (aid, volunteer, social, gamification, analytics, ai)
- `functions/` - Cloud Functions (Node.js/TypeScript) for embeddings, alerts, and server-side AI.

---
*Proprietary - KitaHack 2026 Submission.*

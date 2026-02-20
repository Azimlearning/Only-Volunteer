# OnlyVolunteer AI – Full Development Execution Plan
## KitaHack 2026 | Google Technologies

**Figma design**: [KitaHack 2026](https://www.figma.com/design/rGsC96kPkyiU7kBHq76Gva/KitaHack-2026?node-id=0-1&p=f)  
**Repos**: [Only-Volunteer](https://github.com/Azimlearning/Only-Volunteer) | [VERA-AI](https://github.com/Azimlearning/VERA-AI) (reference) | [system-prompts-and-models-of-ai-tools](https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools)

---

## Execution status (implemented)

- **Orchestrator**: `handleAIRequest` Cloud Function with context builder, deterministic router, rate limiter, Gemini formatter.
- **Tools**: `analytics`, `alerts`, `matching`, `aidfinder` (pure functions in `functions/src/orchestrator/tools/`).
- **Flutter**: `AIOrchestratorService`, `GeminiService.chatWithOrchestrator()`; **chatbot** uses orchestrator first (then fallback to RAG/chat).
- **Pages**: Analytics / Alerts / Match / Aid Finder continue to call their existing Cloud Functions or Firestore; chatbot can trigger the same tools via the orchestrator when the user asks (e.g. “what are current alerts?”, “how are we doing?”, “match me”, “nearby aid”).

**Deploy**: `cd functions && npm run build && firebase deploy --only functions`

---

## 1. Executive Summary

### Architecture
- **One main AI chatbot** – core logic/backend; answers all questions.
- **Other AI features as tools** – Alerts, Analytics, Match Making, Aid Finder are tools the chatbot can call when the user asks.
- **Dual invocation**:
  - **From chatbot**: user asks → router picks tool → tool runs → Gemini formats reply.
  - **From pages**: e.g. Analytics page loads → analytics tool runs automatically and shows insights.

### Additions to Plan
- **Aid Finder AI** – AI to find nearby aid (new tool).
- **Context engineering** – System prompts, user/context injection.
- **Rate limiting** – Per user and per tool.
- **Semantic chunking** – For RAG/semantic search (where used).

### Stack
- **Frontend**: Flutter Web (UI aligned to Figma).
- **Backend**: Firebase (Cloud Functions, Firestore, Auth).
- **AI**: Google Gemini Flash 1.5, Vertex AI Embeddings.
- **Timeline**: Suited to hackathon (phased MVP → polish).

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter Web (Frontend)                         │
│  Home │ Aid Finder │ Alerts │ Analytics │ Match Me │ AI Chatbot  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              AI Orchestrator (Cloud Function)                    │
│  • Context builder (user, page, history)                         │
│  • Deterministic router (intent → tool)                          │
│  • Tool executor (alerts, analytics, matching, aidfinder, search) │
│  • Gemini formatter (tool output → natural language)            │
│  • Rate limiter + optional semantic chunking for RAG             │
└─────────────────────────────┬───────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Alerts Tool    │  │ Analytics Tool   │  │ Matching Tool    │
│  (current news  │  │ (metrics +       │  │ (skills,         │
│   + AI alerts)  │  │  insights)       │  │  interests)      │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Aid Finder Tool │  │ Semantic Search │  │ Gemini Flash     │
│ (nearby aid,    │  │ (embeddings +   │  │ (format + chat)  │
│  geo + AI)      │  │  chunking)      │  │                  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Firestore +      │
                    │ Vertex AI        │
                    └─────────────────┘
```

---

## 3. Core Logic: One Chatbot, Many Tools

### 3.1 Main AI Chatbot (Core)
- **Role**: Single entry point for all user questions.
- **Backend**: One Cloud Function (or a small set) that:
  - Receives: `userId`, `message`, `pageContext`, optional `autoExecute`.
  - Builds context (user profile, location, recent activity).
  - Uses **deterministic router** (keywords + page) to choose a tool.
  - Runs the chosen tool (or no tool for general chat).
  - Sends tool output + context to **Gemini** for one consistent reply.
- **Behaviour**:
  - Can answer general questions without calling tools.
  - When user asks “what are current issues?” / “any alerts?” → **Alerts tool**.
  - When user asks “how are we doing?” / “insights?” → **Analytics tool**.
  - When user asks “match me” / “what’s best for me?” → **Matching tool**.
  - When user asks “nearby aid” / “find aid” → **Aid Finder tool**.
  - For complex or vague queries → **Semantic search tool** (optional) + Gemini.

### 3.2 Tools (Add-ons to the Chatbot)

| Tool            | Trigger (examples)              | Page auto-execute   | Output used by                    |
|-----------------|----------------------------------|--------------------|-----------------------------------|
| **Alerts**      | “current issues”, “alerts”, “SOS”| Alerts page load   | Chatbot reply + Alerts page UI   |
| **Analytics**   | “insights”, “stats”, “how are we”| Analytics page load | Chatbot reply + Analytics UI     |
| **Matching**    | “match me”, “recommend”, “for me”| Match Me page load | Chatbot reply + Match Me UI       |
| **Aid Finder**  | “nearby aid”, “find aid”, “food bank” | Aid Finder page  | Chatbot reply + Aid Finder UI    |
| **Semantic**    | Complex / open-ended search      | —                  | Chatbot reply + suggested items  |

- Each tool is a **pure function** (input → structured output).
- Orchestrator calls the tool; **Gemini formatter** turns that into one coherent voice for the chatbot and, where relevant, for the page.

### 3.3 Page Behaviour
- **Analytics page**: On load (or on “Generate insights”), call **Analytics tool** and show result on the same page.
- **Alerts page**: On load, call **Alerts tool** (or stream from Firestore) and show list; chatbot can also call the same tool when user asks about alerts.
- **Match Me page**: On load (or “Find matches”), call **Matching tool** and show results.
- **Aid Finder page**: On load or when user searches, call **Aid Finder tool** and show nearby aid; chatbot can call it when user asks for nearby aid.

So: **same tools**, invoked either **from the chatbot** (user question) or **from the page** (auto or button).

---

## 4. New and Enhanced Components

### 4.1 Aid Finder Tool (New)
- **Input**: `userId`, `context`, optional `location`, `category`, `urgency`.
- **Logic**:
  - Resolve user location (from context or param).
  - Query Firestore `aid_resources` (and related) with geo/distance (e.g. Haversine or GeoFlutterFire).
  - Filter by category/urgency if provided.
  - Rank by distance + urgency + match to user preferences.
- **Output**: List of nearby aid items (id, title, category, distance, address, contact, urgency, matchScore).
- **AI**: Orchestrator sends this list to Gemini so the **main chatbot** explains “here’s nearby aid…” in one voice.

### 4.2 Context Engineering
- **System prompts**: Single source of personality and instructions (see [system-prompts-and-models-of-ai-tools](https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools)).
- **Context injected per request**:
  - User: name, role, skills, interests, location.
  - Page: `home | analytics | aidfinder | alerts | match | chat`.
  - Recent activity / volunteer history (optional).
- **Formatter**: One Gemini prompt that takes (context + tool result) and outputs natural language so the chatbot and pages feel consistent.

### 4.3 Rate Limiting
- **Chat**: e.g. 10 req/min, 60 req/hour per user (configurable).
- **Tool calls (auto-execute)**: e.g. 20/min, 100/hour per user.
- **Implementation**: Firestore counters or Cloud Functions middleware; return clear error when exceeded.
- **Admin/developer bypass**: Optional for demo/testing.

### 4.4 Semantic Chunking
- **Where**: Used for RAG / semantic search (e.g. activities, drives, aid descriptions).
- **How**: Chunk long text (by paragraph or fixed token size), embed chunks with Vertex AI, store in Firestore (or same vector store).
- **Use**: When the user query is complex or open-ended, semantic search tool returns top chunks; orchestrator passes them to Gemini for the main chatbot reply.
- **Reference**: VERA-AI chunking and embedding patterns.

---

## 5. Deterministic Router (Summary)

- **Priority 1 – Page auto-execute**:  
  `analytics` → analytics_tool; `aidfinder` → aidfinder_tool; `alerts` → alerts_tool; `match` → matching_tool.
- **Priority 2 – Intent keywords** (from message):
  - “alert”, “SOS”, “crisis”, “current issues” → alerts_tool.
  - “insight”, “stats”, “analytics”, “performance” → analytics_tool.
  - “match”, “recommend”, “suitable”, “for me” → matching_tool.
  - “nearby”, “aid”, “food bank”, “find aid” → aidfinder_tool.
- **Priority 3 – Page fallback**: If on a specific page and no tool chosen yet, use that page’s tool.
- **Default**: No tool; pure Gemini chat (with context).

---

## 6. Implementation Phases (Hackathon-Friendly)

### Phase 1 – Orchestrator + one tool (Week 1)
- [x] Cloud Function: `handleAIRequest` (context + router + formatter).
- [x] Context builder (user + page).
- [x] Deterministic router.
- [x] Analytics tool; connect to chatbot via orchestrator.
- [x] Flutter: call orchestrator from chatbot.
- **Deliverable**: One main chatbot that can answer “how are we doing?” and Analytics page that auto-shows insights.

### Phase 2 – All tools + pages (Week 2)
- [x] Alerts tool (fetch from Firestore).
- [x] Matching tool (scoring + Gemini explanations).
- [x] Aid Finder tool (aid_resources + category/urgency).
- [x] Chatbot routes to all tools by intent; pages use existing endpoints.
- **Deliverable**: Chatbot can answer alerts, matching, and nearby aid; each page shows its own tool result.

### Phase 3 – Polish (Week 3)
- [ ] Rate limiting (Firestore + middleware).
- [ ] Semantic chunking + optional semantic search tool.
- [ ] Context engineering: finalise system prompts and formatter.
- [ ] UI: Alerts, Analytics, Chatbot pages aligned to Figma (KitaHack 2026).
- **Deliverable**: Demo-ready app with one chatbot, all tools, and consistent UI.

---

## 7. UI Alignment (Figma – KitaHack 2026)

- **Design file**: [KitaHack 2026 – Figma](https://www.figma.com/design/rGsC96kPkyiU7kBHq76Gva/KitaHack-2026?node-id=0-1&p=f).
- **Apply to**:
  - **Alerts page**: Header (title + subtitle), list/cards for each alert (type, severity, region, time), empty state.
  - **Analytics page**: Header, stat cards, chart, AI insights block (descriptive + prescriptive).
  - **AI Chatbot page**: Header, message list, suggestion chips, input + send; recommendation cards when tool returns results.
- **Theme**: Use existing `figmaOrange`, `figmaPurple`, `figmaBlack`; consistent spacing (16/24), card radius 12, same header style across the three pages.

---

## 8. References

- **Only-Volunteer**: [github.com/Azimlearning/Only-Volunteer](https://github.com/Azimlearning/Only-Volunteer)
- **VERA-AI**: [github.com/Azimlearning/VERA-AI](https://github.com/Azimlearning/VERA-AI) – RAG, chunking, tools
- **System prompts**: [github.com/x1xhlol/system-prompts-and-models-of-ai-tools](https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools)
- **Figma**: [KitaHack 2026](https://www.figma.com/design/rGsC96kPkyiU7kBHq76Gva/KitaHack-2026?node-id=0-1&p=f)

---

**Document version**: 1.0  
**Last updated**: February 2026  
**Project**: OnlyVolunteer | **Hackathon**: KitaHack 2026

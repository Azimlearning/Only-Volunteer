# OnlyVolunteer - File Structure Explanation

This document explains the organization of the OnlyVolunteer Flutter application codebase.

## 📁 Root Directory Structure

```
OnlyVolunteer/
├── lib/                    # Main application code (Dart/Flutter)
├── web/                    # Web-specific files (HTML, assets)
├── assets/                 # Images, fonts, and other static assets
├── pubspec.yaml            # Dependencies and project configuration
└── README.md               # Project documentation
```

---

## 📂 `lib/` Directory - Main Application Code

The `lib/` folder contains all Dart code organized using a **feature-first architecture**:

### 🎯 Core (`lib/core/`)
**Purpose:** Shared, reusable components used across the entire app.

- **`theme.dart`** - App-wide styling, colors (`figmaOrange`, `figmaPurple`, `figmaBlack`), and Material Design theme
- **`app_router.dart`** - Navigation configuration using `go_router`, defines all routes
- **`config.dart`** - App-wide constants and configuration values

**Why separate?** These are used everywhere and don't belong to a specific feature.

---

### 🏠 Features (`lib/features/`)
**Purpose:** Each folder represents a major feature/page of the app. This keeps code organized and maintainable.

#### **`auth/`** - Authentication
- **`login_screen.dart`** - Login and registration UI
- Handles user sign-in/sign-up with Firebase Auth

#### **`home/`** - Landing Page
- **`home_screen.dart`** - Main landing page with hero section, feature cards, and services
- First page users see after login

#### **`aid/`** - Aid Finder Feature
- **`aid_finder_screen.dart`** - Main Aid Finder page (static aid resources directory)
- **`donation_drives_screen.dart`** - Donation Drives page (official campaigns)
- **`create_drive_screen.dart`** - Form to create new donation drives
- Related to finding and providing aid resources

#### **`opportunities/`** - Opportunities Feature
- **`opportunities_screen.dart`** - Main Opportunities page (volunteering + micro-donations)
- **`my_requests_screen.dart`** - User's donation requests tracking
- Handles both volunteering opportunities and small donation requests

#### **`volunteer/`** - Volunteer Management
- **`volunteer_listings_screen.dart`** - List of volunteer opportunities
- **`create_opportunity_screen.dart`** - Form to create volunteer opportunities
- **`my_activities_screen.dart`** - User's attendance, certificates, donations
- **`opportunities_map_screen.dart`** - Map view of volunteer opportunities

#### **`admin/`** - Admin Functions
- **`developer_screen.dart`** - Developer tools (seed data, clear data)
- Only accessible to admins/NGOs

#### **`ai/`** - AI Features
- **`chatbot_screen.dart`** - Gemini-powered chatbot
- **`alerts_screen.dart`** - Alert notifications (currently work in progress)
- **`match_screen.dart`** - Skill matching feature

#### **`social/`** - Social Features
- **`feed_screen.dart`** - Social feed (currently work in progress)

#### **`gamification/`** - Gamification
- **`leaderboard_screen.dart`** - User leaderboard (currently work in progress)

#### **`analytics/`** - Analytics
- **`analytics_screen.dart`** - Analytics dashboard (currently work in progress)

#### **`support/`** - Support
- **`request_support_screen.dart`** - Contact/support request form

#### **`common/`** - Shared Components
- **`work_in_progress_screen.dart`** - Reusable "work in progress" placeholder

**Why feature-first?** 
- Easy to find code related to a specific feature
- Each feature can be developed independently
- Easier to test and maintain
- Clear separation of concerns

---

### 📊 Models (`lib/models/`)
**Purpose:** Data structures (classes) that represent entities in your app.

- **`app_user.dart`** - User profile structure (name, email, role, points)
- **`donation_drive.dart`** - Official campaign structure (title, goal, raised, campaign category)
- **`aid_resource.dart`** - Static aid center structure (location, category, urgency)
- **`volunteer_listing.dart`** - Volunteer opportunity structure (title, skills, slots, times)
- **`micro_donation_request.dart`** - Small donation request structure (item needed, category)
- **`attendance.dart`** - Volunteer attendance tracking
- **`e_certificate.dart`** - Electronic certificate structure
- **`donation.dart`** - Individual donation record
- **`alert.dart`** - Alert/notification structure
- **`feed_post.dart`** - Social feed post structure
- **`feed_comment.dart`** - Comment on feed posts

**Why separate?** Models are used across multiple features and services. Centralizing them ensures consistency.

---

### 🔧 Services (`lib/services/`)
**Purpose:** Business logic, API calls, and external integrations.

- **`firestore_service.dart`** - All Firestore database operations (CRUD for all collections)
- **`auth_service.dart`** - Firebase Authentication operations
- **`seed_data_service.dart`** - Populates database with test data (developer tool)
- **`gemini_service.dart`** - Google Gemini AI integration

**Why separate?** Keeps business logic separate from UI, making it reusable and testable.

---

### 🎛️ Providers (`lib/providers/`)
**Purpose:** State management using Provider pattern.

- **`auth_provider.dart`** - Manages authentication state (logged in user, app user data)
- Provides reactive state that UI can listen to

**Why separate?** State management is separate from UI and services, following separation of concerns.

---

### 🏗️ App (`lib/app/`)
**Purpose:** App-level structure and shell.

- **`app_shell.dart`** - Main shell wrapper that provides:
  - Static header (logo, navigation) for all pages
  - Footer for all pages
  - Drawer menu
  - Dropdown navigation menu
  - Wraps all authenticated pages

**Why separate?** This is the structural foundation that wraps all pages, not a specific feature.

---

### 📄 Root Files (`lib/`)

- **`main.dart`** - Application entry point
  - Initializes Firebase
  - Sets up providers
  - Configures routing
  - Runs the app

---

## 🔄 How It All Works Together

### Example: User clicks "Aid Finder"

1. **`main.dart`** → App starts, sets up routing
2. **`app_router.dart`** → Defines `/finder` route → points to `AidFinderScreen`
3. **`app_shell.dart`** → Wraps the screen with header/footer
4. **`aid_finder_screen.dart`** → UI renders
5. **`firestore_service.dart`** → Fetches aid resources from Firestore
6. **`aid_resource.dart`** → Data structure for each resource
7. **`theme.dart`** → Provides colors and styling

### Example: Developer seeds data

1. **`developer_screen.dart`** → User clicks "Populate database"
2. **`seed_data_service.dart`** → Creates test data
3. Uses **`donation_drive.dart`**, **`volunteer_listing.dart`**, **`aid_resource.dart`** models
4. Calls **`firestore_service.dart`** → Saves to Firestore
5. Data appears in respective screens

---

## 📋 Key Principles

1. **Feature-First:** Code is organized by feature, not by type (UI vs logic)
2. **Separation of Concerns:** Models, Services, Providers, UI are separate
3. **Reusability:** Core components (`theme`, `router`) are shared
4. **Scalability:** Easy to add new features without touching existing code
5. **Maintainability:** Easy to find and fix bugs in specific features

---

## 🎨 Color Scheme (from `core/theme.dart`)

- **`figmaOrange`** (`#FF691C`) - Primary action color
- **`figmaPurple`** (`#8100DE`) - Secondary action color  
- **`figmaBlack`** (`#333333`) - Text color

---

## 🗺️ Navigation Flow

All routes are defined in **`core/app_router.dart`**:
- `/home` → Landing page
- `/finder` → Aid Finder
- `/drives` → Donation Drives
- `/opportunities` → Opportunities
- `/my-activities` → My Activities
- `/my-requests` → My Requests
- `/developer` → Developer tools (admin only)
- And more...

---

## 💡 Tips for Working with This Structure

1. **Adding a new feature?** Create a new folder in `features/`
2. **Need a new data type?** Add a model in `models/`
3. **Adding a new route?** Update `app_router.dart`
4. **Shared styling?** Add to `core/theme.dart`
5. **Database operations?** Add methods to `firestore_service.dart`

---

This structure makes the codebase organized, maintainable, and scalable! 🚀

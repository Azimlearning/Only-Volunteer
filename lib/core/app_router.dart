import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/aid/aid_finder_screen.dart';
import '../features/aid/donation_drives_screen.dart';
import '../features/aid/create_drive_screen.dart';
import '../features/volunteer/volunteer_listings_screen.dart';
import '../features/opportunities/opportunities_screen.dart';
import '../features/opportunities/my_requests_screen.dart';
import '../features/opportunities/request_support_screen.dart';
import '../features/volunteer/create_opportunity_screen.dart';
import '../features/volunteer/my_activities_screen.dart';
import '../features/volunteer/opportunities_map_screen.dart';
import '../features/social/feed_screen.dart';
import '../features/gamification/leaderboard_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/ai/chatbot_screen.dart';
import '../features/ai/alerts_screen.dart';
import '../features/common/work_in_progress_screen.dart';
import '../features/common/about_us_screen.dart';
import '../features/common/profile_screen.dart';
import '../features/ai/match_screen.dart';
import '../features/admin/developer_screen.dart';
import '../app/app_shell.dart';
import '../providers/auth_provider.dart';

GoRouter createAppRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      // Wait for auth to restore from persistence before redirecting
      if (!authNotifier.authInitialized) return '/splash';
      final isLoggedIn = authNotifier.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';
      if (isSplash) return isLoggedIn ? '/home' : '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      if (!isLoggedIn && !isLoginRoute && !isSplash) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) => '/splash',
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/finder', builder: (_, __) => const AidFinderScreen()),
          GoRoute(path: '/drives', builder: (_, __) => const DonationDrivesScreen()),
          GoRoute(path: '/create-drive', builder: (_, __) => const CreateDriveScreen()),
          GoRoute(path: '/opportunities', builder: (_, __) => const OpportunitiesScreen()),
          GoRoute(path: '/my-requests', builder: (_, __) => const MyRequestsScreen()),
          GoRoute(path: '/create-opportunity', builder: (_, __) => const CreateOpportunityScreen()),
          GoRoute(path: '/request-support', builder: (_, __) => const RequestSupportScreen()),
          GoRoute(path: '/map', builder: (_, __) => const OpportunitiesMapScreen()),
          GoRoute(path: '/my-activities', builder: (_, __) => const MyActivitiesScreen()),
          GoRoute(
            path: '/feed',
            builder: (_, __) => const WorkInProgressScreen(
              title: 'Feed',
              description: 'The Feed feature is currently under development. Check back soon!',
            ),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (_, __) => const WorkInProgressScreen(
              title: 'Leaderboard',
              description: 'The Leaderboard feature is currently under development. Check back soon!',
            ),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, __) => const WorkInProgressScreen(
              title: 'Analytics',
              description: 'The Analytics feature is currently under development. Check back soon!',
            ),
          ),
          GoRoute(path: '/chatbot', builder: (_, __) => const ChatbotScreen()),
          GoRoute(
            path: '/alerts',
            builder: (_, __) => const WorkInProgressScreen(
              title: 'Alerts',
              description: 'The Alerts feature is currently under development. Check back soon!',
            ),
          ),
          GoRoute(path: '/match', builder: (_, __) => const MatchScreen()),
          GoRoute(path: '/about-us', builder: (_, __) => const AboutUsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/developer', builder: (_, __) => const DeveloperScreen()),
        ],
      ),
    ],
  );
}

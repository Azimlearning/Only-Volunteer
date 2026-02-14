import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/aid/aid_finder_screen.dart';
import '../features/aid/donation_drives_screen.dart';
import '../features/aid/create_drive_screen.dart';
import '../features/volunteer/volunteer_listings_screen.dart';
import '../features/volunteer/my_activities_screen.dart';
import '../features/volunteer/opportunities_map_screen.dart';
import '../features/social/feed_screen.dart';
import '../features/gamification/leaderboard_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/ai/chatbot_screen.dart';
import '../features/ai/alerts_screen.dart';
import '../features/ai/match_screen.dart';
import '../app/app_shell.dart';
import '../providers/auth_provider.dart';

GoRouter createAppRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authNotifier.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/finder', builder: (_, __) => const AidFinderScreen()),
          GoRoute(path: '/drives', builder: (_, __) => const DonationDrivesScreen()),
          GoRoute(path: '/create-drive', builder: (_, __) => const CreateDriveScreen()),
          GoRoute(path: '/opportunities', builder: (_, __) => const VolunteerListingsScreen()),
          GoRoute(path: '/map', builder: (_, __) => const OpportunitiesMapScreen()),
          GoRoute(path: '/my-activities', builder: (_, __) => const MyActivitiesScreen()),
          GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/chatbot', builder: (_, __) => const ChatbotScreen()),
          GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
          GoRoute(path: '/match', builder: (_, __) => const MatchScreen()),
        ],
      ),
    ],
  );
}

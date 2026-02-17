import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final canManage = auth.appUser?.role == UserRole.ngo || auth.appUser?.role == UserRole.admin;
    
    // Unified static header for ALL pages
    return Scaffold(
      body: Column(
        children: [
          // Static dark header - same for all pages
          Container(
            color: const Color(0xFF2C2C2C),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Logo - clickable to go home
                  InkWell(
                    onTap: () => context.go('/home'),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/onlyvolunteer_logo.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: figmaOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.volunteer_activism, size: 20, color: figmaOrange),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'OnlyVolunteer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Navigation links - Core pages visible
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Home', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/about-us'),
                    child: const Text('About Us', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/finder'),
                    child: const Text('Aid Finder', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/drives'),
                    child: const Text('Donation Drives', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/opportunities'),
                    child: const Text('Opportunities', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/match'),
                    child: const Text('Match Me', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/my-activities'),
                    child: const Text('My Activities', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/my-requests'),
                    child: const Text('My Requests', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/chatbot'),
                    child: const Text('AI Chatbot', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  // Dropdown menu for other features
                  _FeaturesDropdown(canManage: canManage),
                  const SizedBox(width: 12),
                  // Profile icon with notification badge - clickable
                  InkWell(
                    onTap: () => context.go('/profile'),
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[700],
                          child: Icon(Icons.person, color: Colors.grey[300], size: 20),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Page content - NO FOOTER
          Expanded(child: child),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [figmaOrange, figmaPurple],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/onlyvolunteer_logo.png',
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.volunteer_activism, size: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'OnlyVolunteer',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => context.go('/home')),
            ListTile(leading: const Icon(Icons.search), title: const Text('Aid Finder'), onTap: () => context.go('/finder')),
            ListTile(leading: const Icon(Icons.volunteer_activism), title: const Text('Donation Drives'), onTap: () => context.go('/drives')),
            if (canManage)
              ListTile(leading: const Icon(Icons.add_circle_outline), title: const Text('Create Drive'), onTap: () => context.go('/create-drive')),
            ListTile(leading: const Icon(Icons.work), title: const Text('Opportunities'), onTap: () => context.go('/opportunities')),
            ListTile(leading: const Icon(Icons.map), title: const Text('Map View'), onTap: () => context.go('/map')),
            ListTile(leading: const Icon(Icons.event), title: const Text('My Activities'), onTap: () => context.go('/my-activities')),
            ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Match Me'), onTap: () => context.go('/match')),
            ListTile(leading: const Icon(Icons.people), title: const Text('Feed'), onTap: () => context.go('/feed')),
            ListTile(leading: const Icon(Icons.emoji_events), title: const Text('Leaderboard'), onTap: () => context.go('/leaderboard')),
            if (canManage)
              ListTile(leading: const Icon(Icons.bar_chart), title: const Text('Analytics'), onTap: () => context.go('/analytics')),
            if (canManage) ...[
              const Divider(),
              ListTile(leading: const Icon(Icons.science), title: const Text('Developer'), onTap: () => context.go('/developer')),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturesDropdown extends StatelessWidget {
  const _FeaturesDropdown({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: Colors.white),
      color: Colors.white,
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        // Other Features Section (core pages are now visible buttons)
        const PopupMenuItem(
          value: '/leaderboard',
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: figmaOrange, size: 20),
              SizedBox(width: 12),
              Text('Leaderboard'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: '/analytics',
          child: Row(
            children: [
              Icon(Icons.bar_chart, color: figmaPurple, size: 20),
              SizedBox(width: 12),
              Text('Analytics'),
            ],
          ),
        ),
        // Other Features Section
        const PopupMenuItem(
          value: '/feed',
          child: Row(
            children: [
              Icon(Icons.people, color: figmaOrange, size: 20),
              SizedBox(width: 12),
              Text('Feed'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: '/alerts',
          child: Row(
            children: [
              Icon(Icons.notifications_active, color: figmaPurple, size: 20),
              SizedBox(width: 12),
              Text('Alerts'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: '/map',
          child: Row(
            children: [
              Icon(Icons.map, color: figmaOrange, size: 20),
              SizedBox(width: 12),
              Text('Map View'),
            ],
          ),
        ),
        if (canManage) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: '/create-drive',
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: figmaPurple, size: 20),
                SizedBox(width: 12),
                Text('Create Drive'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: '/create-opportunity',
            child: Row(
              children: [
                Icon(Icons.work_outline, color: figmaOrange, size: 20),
                SizedBox(width: 12),
                Text('Create Opportunity'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: '/developer',
            child: Row(
              children: [
                Icon(Icons.science, color: figmaPurple, size: 20),
                SizedBox(width: 12),
                Text('Developer'),
              ],
            ),
          ),
        ],
      ],
      onSelected: (value) => context.go(value),
    );
  }
}

class _AppFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C2C2C),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Home', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => context.go('/finder'),
                  child: const Text('Aid Finder', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => context.go('/drives'),
                  child: const Text('Donation Drives', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => context.go('/opportunities'),
                  child: const Text('Opportunities', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '© 2026 OnlyVolunteer. All rights reserved.',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Policy coming soon')),
                    );
                  },
                  child: Text('Privacy Policy', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of Service coming soon')),
                    );
                  },
                  child: Text('Terms of Service', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact feature coming soon')),
                    );
                  },
                  child: Text('Contact Us', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

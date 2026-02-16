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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Logo
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
                color: figmaBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Orange button from Figma design (functionality to be determined)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: () {
                // TODO: Determine function - could be profile, menu, or notifications
                // For now, opening drawer as placeholder
                Scaffold.of(context).openDrawer();
              },
              style: FilledButton.styleFrom(
                backgroundColor: figmaOrange,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Icon(Icons.menu, color: Colors.white),
            ),
          ),
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
      body: child,
    );
  }
}

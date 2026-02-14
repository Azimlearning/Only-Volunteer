import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OnlyVolunteer'),
        actions: [
          IconButton(icon: const Icon(Icons.chat), onPressed: () => context.go('/chatbot')),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () => context.go('/alerts')),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0D47A1)),
              child: Text('OnlyVolunteer', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => context.go('/home')),
            ListTile(leading: const Icon(Icons.search), title: const Text('Aid Finder'), onTap: () => context.go('/finder')),
            ListTile(leading: const Icon(Icons.volunteer_activism), title: const Text('Donation Drives'), onTap: () => context.go('/drives')),
            ListTile(leading: const Icon(Icons.work), title: const Text('Opportunities'), onTap: () => context.go('/opportunities')),
            ListTile(leading: const Icon(Icons.map), title: const Text('Map View'), onTap: () => context.go('/map')),
            ListTile(leading: const Icon(Icons.event), title: const Text('My Activities'), onTap: () => context.go('/my-activities')),
            ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Match Me'), onTap: () => context.go('/match')),
            ListTile(leading: const Icon(Icons.people), title: const Text('Feed'), onTap: () => context.go('/feed')),
            ListTile(leading: const Icon(Icons.emoji_events), title: const Text('Leaderboard'), onTap: () => context.go('/leaderboard')),
            ListTile(leading: const Icon(Icons.bar_chart), title: const Text('Analytics'), onTap: () => context.go('/analytics')),
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

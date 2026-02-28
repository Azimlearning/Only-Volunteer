import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                  // Brand - clickable to go home (logo + text)
                  InkWell(
                    onTap: () => context.go('/home'),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/onlyvolunteer_logo.png',
                          width: 96,
                          height: 96,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: figmaOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.volunteer_activism, size: 24, color: figmaOrange),
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
                    onPressed: () => context.go('/chatbot'),
                    child: const Text('AI Chatbot', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/alerts'),
                    child: const Text('Alerts', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  // Profile icon - clickable
                  InkWell(
                    onTap: () => context.go('/profile'),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[700],
                      child: Icon(Icons.person, color: Colors.grey[300], size: 20),
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
            ListTile(leading: const Icon(Icons.work), title: const Text('Opportunities'), onTap: () => context.go('/opportunities')),
            ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Match Me'), onTap: () => context.go('/match')),
            ListTile(leading: const Icon(Icons.notifications_active), title: const Text('Alerts'), onTap: () => context.go('/alerts')),
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

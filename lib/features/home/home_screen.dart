import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final name = auth.appUser?.displayName ?? auth.appUser?.email.split('@').first ?? 'there';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Logo + wording (Aid Finder style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  figmaOrange.withOpacity(0.1),
                  figmaPurple.withOpacity(0.1),
                ],
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/onlyvolunteer_logo.png',
                  width: 48,
                  height: 48,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: figmaOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.volunteer_activism, size: 28, color: figmaOrange),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OnlyVolunteer',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: figmaBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Welcome, $name. Find opportunities, donate, and track your impact.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 2. Rotating banner placeholder
          Container(
            height: 140,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[350]!),
            ),
            child: Center(
              child: Text(
                'Banner',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // 3. Clean navbar – all page buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _NavButton(
                  icon: Icons.search_rounded,
                  label: 'Aid Finder',
                  onTap: () => context.go('/finder'),
                ),
                _NavButton(
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Donation Drives',
                  onTap: () => context.go('/drives'),
                ),
                _NavButton(
                  icon: Icons.work_rounded,
                  label: 'Opportunities',
                  onTap: () => context.go('/opportunities'),
                ),
                _NavButton(
                  icon: Icons.person_rounded,
                  label: 'My Activities',
                  onTap: () => context.go('/my-activities'),
                ),
                _NavButton(
                  icon: Icons.list_alt_rounded,
                  label: 'My Requests',
                  onTap: () => context.go('/my-requests'),
                ),
                _NavButton(
                  icon: Icons.notifications_active_rounded,
                  label: 'Alerts',
                  onTap: () => context.go('/alerts'),
                ),
                _NavButton(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Create Drive',
                  onTap: () => context.go('/create-drive'),
                ),
                _NavButton(
                  icon: Icons.emoji_events_rounded,
                  label: 'Leaderboard',
                  onTap: () => context.go('/leaderboard'),
                ),
                _NavButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Match Me',
                  onTap: () => context.go('/match'),
                ),
                _NavButton(
                  icon: Icons.people_rounded,
                  label: 'Feed',
                  onTap: () => context.go('/feed'),
                ),
                _NavButton(
                  icon: Icons.chat_rounded,
                  label: 'Chatbot',
                  onTap: () => context.go('/chatbot'),
                ),
                if (auth.appUser?.role?.name == 'ngo' || auth.appUser?.role?.name == 'admin')
                  _NavButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics',
                    onTap: () => context.go('/analytics'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: figmaOrange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: figmaOrange.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: figmaOrange),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: figmaBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

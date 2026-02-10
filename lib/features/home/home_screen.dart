import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome to OnlyVolunteer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Find opportunities, donate, and track your impact.', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _QuickCard(icon: Icons.search, title: 'Aid Finder', onTap: () => context.go('/finder')),
              _QuickCard(icon: Icons.volunteer_activism, title: 'Donation Drives', onTap: () => context.go('/drives')),
              _QuickCard(icon: Icons.work, title: 'Opportunities', onTap: () => context.go('/opportunities')),
              _QuickCard(icon: Icons.auto_awesome, title: 'Match Me', onTap: () => context.go('/match')),
              _QuickCard(icon: Icons.people, title: 'Community Feed', onTap: () => context.go('/feed')),
              _QuickCard(icon: Icons.emoji_events, title: 'Leaderboard', onTap: () => context.go('/leaderboard')),
              _QuickCard(icon: Icons.bar_chart, title: 'Analytics', onTap: () => context.go('/analytics')),
              _QuickCard(icon: Icons.chat, title: 'Ask Concierge', onTap: () => context.go('/chatbot')),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

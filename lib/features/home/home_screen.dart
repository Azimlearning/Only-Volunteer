import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/donation_drive.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final name = auth.appUser?.displayName ?? auth.appUser?.email.split('@').first ?? 'there';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, $name', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Find opportunities, donate, and track your impact.', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _QuickCard(icon: Icons.search, title: 'Find Aid', onTap: () => context.go('/finder')),
              _QuickCard(icon: Icons.volunteer_activism, title: 'Join Drive', onTap: () => context.go('/drives')),
              _QuickCard(icon: Icons.add_circle_outline, title: 'Create Drive', onTap: () => context.go('/create-drive')),
              _QuickCard(icon: Icons.notifications_active, title: 'Alerts', onTap: () => context.go('/alerts')),
            ],
          ),
          const SizedBox(height: 24),
          Text('More', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _QuickCard(icon: Icons.work, title: 'Opportunities', onTap: () => context.go('/opportunities')),
              _QuickCard(icon: Icons.auto_awesome, title: 'Match Me', onTap: () => context.go('/match')),
              _QuickCard(icon: Icons.people, title: 'Feed', onTap: () => context.go('/feed')),
              _QuickCard(icon: Icons.emoji_events, title: 'Leaderboard', onTap: () => context.go('/leaderboard')),
              _QuickCard(icon: Icons.bar_chart, title: 'Analytics', onTap: () => context.go('/analytics')),
              _QuickCard(icon: Icons.chat, title: 'Chatbot', onTap: () => context.go('/chatbot')),
            ],
          ),
          const SizedBox(height: 24),
          const _SuggestedDrivesSection(),
        ],
      ),
    );
  }
}

class _SuggestedDrivesSection extends StatelessWidget {
  const _SuggestedDrivesSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DonationDrive>>(
      future: FirestoreService().getDonationDrives(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final drives = snapshot.data!.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suggested for you', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...drives.map((d) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.volunteer_activism, color: Color(0xFF0D47A1)),
                title: Text(d.title),
                subtitle: d.location != null ? Text(d.location!) : null,
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.go('/drives'),
              ),
            )),
          ],
        );
      },
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

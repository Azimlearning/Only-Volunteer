import 'dart:ui';
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
      child: Column(
        children: [
          _HeroSection(name: name),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Quick actions'),
                const SizedBox(height: 12),
                _QuickActionsGrid(),
                const SizedBox(height: 28),
                _SectionTitle(title: 'Suggested for you'),
                const SizedBox(height: 12),
                const _SuggestedDrivesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D47A1),
            const Color(0xFF1565C0),
            const Color(0xFF1976D2).withOpacity(0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Find opportunities, donate, and track your impact.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ) ??
          const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
          ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        _QuickCard(
          icon: Icons.search_rounded,
          title: 'Find Aid',
          subtitle: 'Resources & requests',
          gradient: [primary, primary.withOpacity(0.8)],
          onTap: () => context.go('/finder'),
        ),
        _QuickCard(
          icon: Icons.volunteer_activism_rounded,
          title: 'Join Drive',
          subtitle: 'Donation drives',
          gradient: [const Color(0xFF2E7D32), const Color(0xFF43A047)],
          onTap: () => context.go('/drives'),
        ),
        _QuickCard(
          icon: Icons.add_circle_outline_rounded,
          title: 'Create Drive',
          subtitle: 'Start a campaign',
          gradient: [const Color(0xFFE65100), const Color(0xFFFF9800)],
          onTap: () => context.go('/create-drive'),
        ),
        _QuickCard(
          icon: Icons.notifications_active_rounded,
          title: 'Alerts',
          subtitle: 'SOS & flood alerts',
          gradient: [const Color(0xFFC62828), const Color(0xFFE53935)],
          onTap: () => context.go('/alerts'),
        ),
        _QuickCard(
          icon: Icons.work_rounded,
          title: 'Opportunities',
          subtitle: 'Volunteer listings',
          gradient: [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
          onTap: () => context.go('/opportunities'),
        ),
        _QuickCard(
          icon: Icons.auto_awesome_rounded,
          title: 'Match Me',
          subtitle: 'AI recommendations',
          gradient: [const Color(0xFF00838F), const Color(0xFF26C6DA)],
          onTap: () => context.go('/match'),
        ),
        _QuickCard(
          icon: Icons.people_rounded,
          title: 'Feed',
          subtitle: 'Community posts',
          gradient: [const Color(0xFF37474F), const Color(0xFF546E7A)],
          onTap: () => context.go('/feed'),
        ),
        _QuickCard(
          icon: Icons.emoji_events_rounded,
          title: 'Leaderboard',
          subtitle: 'Top volunteers',
          gradient: [const Color(0xFFF9A825), const Color(0xFFFFD54F)],
          onTap: () => context.go('/leaderboard'),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradient[0].withOpacity(0.12), gradient[1].withOpacity(0.06)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gradient[0].withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: gradient[0].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 26, color: gradient[0]),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.volunteer_activism, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No drives yet. Browse or create one!',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.go('/drives'),
                  icon: const Icon(Icons.explore, size: 18),
                  label: const Text('Browse drives'),
                ),
              ],
            ),
          );
        }
        final drives = snapshot.data!.take(5).toList();
        return Column(
          children: drives.map((d) => _DriveCard(drive: d)).toList(),
        );
      },
    );
  }
}

class _DriveCard extends StatelessWidget {
  const _DriveCard({required this.drive});

  final DonationDrive drive;

  @override
  Widget build(BuildContext context) {
    final progress = (drive.goalAmount != null && drive.goalAmount! > 0)
        ? (drive.raisedAmount / drive.goalAmount!).clamp(0.0, 1.0)
        : 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => context.go('/drives'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.volunteer_activism, color: Color(0xFF0D47A1), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drive.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (drive.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(drive.location!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF0D47A1)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Raised: ${drive.raisedAmount.toStringAsFixed(0)} / ${drive.goalAmount?.toStringAsFixed(0) ?? "—"}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

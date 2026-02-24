import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/seed_data_service.dart';
import '../../core/theme.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  final SeedDataService _seed = SeedDataService();
  bool _loading = false;
  String? _message;
  bool _success = false;

  Future<void> _populate() async {
    setState(() { _loading = true; _message = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final count = await _seed.seedAll(systemUserId: uid);
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'Successfully added $count test entries.';
          _success = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message!),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'Error: $e';
          _success = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _seedSection(String label, Future<int> Function() seedFn) async {
    setState(() { _loading = true; _message = null; });
    try {
      final count = await seedFn();
      if (mounted) {
        setState(() { _loading = false; _message = 'Added $count entries for $label.'; _success = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_message!), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _message = 'Error: $e'; _success = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Seed Data?'),
        content: const Text('This will delete all donation drives, volunteer opportunities, aid resources, alerts, and feed posts. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    
    setState(() { _loading = true; _message = null; });
    try {
      await _seed.clearAllSeedData();
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'All seed data cleared successfully.';
          _success = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message!),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'Error: $e';
          _success = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Developer Menu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                ),
                const SizedBox(height: 4),
                Text(
                  'Populate the database with test data for all core pages',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Seed Data for Core Pages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _SeedableRow(
                          icon: Icons.search,
                          title: 'Aid Finder',
                          description: '10 aid resources with locations, categories, and operating hours',
                          color: figmaOrange,
                          loading: _loading,
                          onSeed: () => _seedSection('Aid Finder', () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            return await _seed.seedAidResources(uid);
                          }),
                        ),
                        const SizedBox(height: 12),
                        _SeedableRow(
                          icon: Icons.volunteer_activism,
                          title: 'Donation Drives',
                          description: '7 donation drives with progress tracking',
                          color: figmaPurple,
                          loading: _loading,
                          onSeed: () => _seedSection('Donation Drives', () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            return await _seed.seedDonationDrives(uid);
                          }),
                        ),
                        const SizedBox(height: 12),
                        _SeedableRow(
                          icon: Icons.work,
                          title: 'Opportunity (volunteering/donation)',
                          description: '7 volunteer opportunities + 5 micro-donation requests',
                          color: figmaOrange,
                          loading: _loading,
                          onSeed: () => _seedSection('Opportunity', () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            final a = await _seed.seedVolunteerOpportunities(uid);
                            final b = await _seed.seedMicroDonations(uid);
                            return a + b;
                          }),
                        ),
                        const SizedBox(height: 12),
                        const _CorePageInfo(
                          icon: Icons.auto_awesome,
                          title: 'Match Me',
                          description: 'Uses opportunities and drives data for matching',
                          color: figmaPurple,
                        ),
                        const SizedBox(height: 12),
                        _SeedableRow(
                          icon: Icons.event,
                          title: 'My Activities (participation/ongoing)',
                          description: 'Event participation: donation drives, volunteering and donation opportunities joined',
                          color: figmaOrange,
                          loading: _loading,
                          onSeed: () => _seedSection('My Activities', () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            final a = await _seed.seedAttendances(uid);
                            final b = await _seed.seedDonations(uid);
                            return a + b;
                          }),
                        ),
                        const SizedBox(height: 12),
                        _SeedableRow(
                          icon: Icons.list_alt,
                          title: 'My Request',
                          description: 'Micro-donation requests (volunteering/donation opportunity style)',
                          color: figmaPurple,
                          loading: _loading,
                          onSeed: () => _seedSection('My Request', () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            return await _seed.seedMicroDonations(uid);
                          }),
                        ),
                        const SizedBox(height: 12),
                        _SeedableRow(
                          icon: Icons.bar_chart,
                          title: 'Analytics (all 3)',
                          description: 'User, org, and admin analytics data',
                          color: figmaOrange,
                          loading: _loading,
                          onSeed: () => _seedSection('Analytics', () => _seed.seedAnalyticsForAllSides(FirebaseAuth.instance.currentUser?.uid)),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _loading ? null : _populate,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.add_circle_outline),
                                label: Text(_loading ? 'Populating...' : 'Populate All Data'),
                                style: FilledButton.styleFrom(backgroundColor: figmaOrange),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _clearData,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Clear All Data'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _success ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _success ? Colors.green.shade800 : Colors.red.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedableRow extends StatelessWidget {
  const _SeedableRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.loading,
    required this.onSeed,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool loading;
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: loading ? null : onSeed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Seed'),
        ),
      ],
    );
  }
}

class _CorePageInfo extends StatelessWidget {
  const _CorePageInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
                        const _CorePageInfo(
                          icon: Icons.search,
                          title: 'Aid Finder',
                          description: '10 aid resources with images, locations, and categories',
                          color: figmaOrange,
                        ),
                        const SizedBox(height: 12),
                        const _CorePageInfo(
                          icon: Icons.volunteer_activism,
                          title: 'Donation Drives',
                          description: '7 donation drives with progress tracking and images',
                          color: figmaPurple,
                        ),
                        const SizedBox(height: 12),
                        const _CorePageInfo(
                          icon: Icons.work,
                          title: 'Opportunities',
                          description: '7 volunteer opportunities + 5 micro-donation requests',
                          color: figmaOrange,
                        ),
                        const SizedBox(height: 12),
                        const _CorePageInfo(
                          icon: Icons.auto_awesome,
                          title: 'Match Me',
                          description: 'Uses opportunities and drives data for matching',
                          color: figmaPurple,
                        ),
                        const SizedBox(height: 12),
                        const _CorePageInfo(
                          icon: Icons.event,
                          title: 'My Activities',
                          description: '3 attendances, 2 e-certificates, 3 donations',
                          color: figmaOrange,
                        ),
                        const SizedBox(height: 12),
                        const _CorePageInfo(
                          icon: Icons.list_alt,
                          title: 'My Requests',
                          description: '5 micro-donation requests (some fulfilled)',
                          color: figmaPurple,
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

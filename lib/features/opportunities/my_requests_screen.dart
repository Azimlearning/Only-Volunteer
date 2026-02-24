import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../models/micro_donation_request.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final FirestoreService _firestore = FirestoreService();
  List<MicroDonationRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final list = await _firestore.getMicroDonations(requesterId: uid);
    if (mounted) setState(() { _requests = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/request-support'),
        backgroundColor: figmaOrange,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Request support',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Aid Finder style)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  figmaOrange.withOpacity(0.1),
                  figmaPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(kCardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Requests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your donation requests',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Expanded(
            child: uid == null
                ? const Center(child: Text('Sign in to see your requests'))
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No requests yet',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create an opportunity to request support',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => context.go('/request-support'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Opportunity'),
                                  style: FilledButton.styleFrom(backgroundColor: figmaOrange),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _requests.length,
                            itemBuilder: (_, i) {
                              final r = _requests[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.title,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
                                            ),
                                          ),
                                          _StatusChip(status: r.status),
                                        ],
                                      ),
                                      if (r.itemNeeded != null) ...[
                                        const SizedBox(height: 4),
                                        Text('Needs: ${r.itemNeeded}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                      ],
                                      if (r.location != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(r.location!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        r.categoryName,
                                        style: TextStyle(fontSize: 12, color: figmaPurple, fontWeight: FontWeight.w500),
                                      ),
                                      if (r.createdAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Posted ${_formatDate(r.createdAt!)}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MicroDonationStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case MicroDonationStatus.open:
        color = Colors.orange;
        label = 'Open';
        break;
      case MicroDonationStatus.fulfilled:
        color = Colors.green;
        label = 'Fulfilled';
        break;
      case MicroDonationStatus.cancelled:
        color = Colors.grey;
        label = 'Cancelled';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

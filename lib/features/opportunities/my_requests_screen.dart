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
        tooltip: 'Create request',
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
                                  'Create a request to get support',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => context.go('/request-support'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create request'),
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
                                child: InkWell(
                                  onTap: () => _showRequestDetail(context, r),
                                  borderRadius: BorderRadius.circular(12),
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

  void _showRequestDetail(BuildContext context, MicroDonationRequest r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(r.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack)),
              const SizedBox(height: 8),
              _StatusChip(status: r.status),
              if (r.description != null && r.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text(r.description!, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
              ],
              if (r.itemNeeded != null) ...[
                const SizedBox(height: 12),
                Text('Needs: ${r.itemNeeded}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
              if (r.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(r.location!, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text('Category: ${r.categoryName}', style: TextStyle(fontSize: 14, color: figmaPurple, fontWeight: FontWeight.w500)),
              Text('Urgency: ${r.urgency}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              if (r.createdAt != null) Text('Posted ${_formatDate(r.createdAt!)}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditRequest(context, r);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(foregroundColor: figmaOrange, side: BorderSide(color: figmaOrange)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (c) => AlertDialog(
                            title: const Text('Delete request?'),
                            content: const Text('This request will be permanently deleted.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && ctx.mounted) {
                          Navigator.pop(ctx);
                          await _firestore.deleteMicroDonationRequest(r.id);
                          if (mounted) _load();
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditRequest(BuildContext context, MicroDonationRequest r) {
    final titleController = TextEditingController(text: r.title);
    final descriptionController = TextEditingController(text: r.description ?? '');
    final locationController = TextEditingController(text: r.location ?? '');
    MicroDonationCategory category = r.category;
    String urgency = r.urgency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          title: const Text('Edit request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MicroDonationCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: MicroDonationCategory.values.map((c) {
                    String label;
                    switch (c) {
                      case MicroDonationCategory.specific_food: label = 'Specific Food'; break;
                      case MicroDonationCategory.furniture: label = 'Furniture'; break;
                      case MicroDonationCategory.appliances: label = 'Appliances'; break;
                      case MicroDonationCategory.medical: label = 'Medical'; break;
                      case MicroDonationCategory.education: label = 'Education'; break;
                      case MicroDonationCategory.other: label = 'Other'; break;
                    }
                    return DropdownMenuItem(value: c, child: Text(label));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: urgency,
                  decoration: const InputDecoration(labelText: 'Urgency'),
                  items: ['low', 'medium', 'high', 'critical'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setDialogState(() => urgency = v ?? urgency),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final updated = MicroDonationRequest(
                  id: r.id,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  category: category,
                  requesterId: r.requesterId,
                  requesterName: r.requesterName,
                  requesterType: r.requesterType,
                  itemNeeded: r.itemNeeded,
                  quantity: r.quantity,
                  urgency: urgency,
                  location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                  lat: r.lat,
                  lng: r.lng,
                  status: r.status,
                  fulfilledBy: r.fulfilledBy,
                  createdAt: r.createdAt,
                  updatedAt: DateTime.now(),
                  qrCodeUrl: r.qrCodeUrl,
                  bank: r.bank,
                  accountName: r.accountName,
                  accountNumber: r.accountNumber,
                );
                await _firestore.updateMicroDonationRequest(updated);
                if (ctx2.mounted) Navigator.pop(ctx2);
                if (mounted) _load();
              },
              style: FilledButton.styleFrom(backgroundColor: figmaOrange),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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

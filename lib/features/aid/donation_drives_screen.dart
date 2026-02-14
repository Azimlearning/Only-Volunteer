import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/donation_drive.dart';
import '../../services/firestore_service.dart';

class DonationDrivesScreen extends StatefulWidget {
  const DonationDrivesScreen({super.key});

  @override
  State<DonationDrivesScreen> createState() => _DonationDrivesScreenState();
}

class _DonationDrivesScreenState extends State<DonationDrivesScreen> {
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-drive'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _categoryFilter == null,
                  onSelected: (_) => setState(() => _categoryFilter = null),
                ),
                FilterChip(
                  label: const Text('Disaster relief'),
                  selected: _categoryFilter == 'disaster_relief',
                  onSelected: (_) => setState(() => _categoryFilter = _categoryFilter == 'disaster_relief' ? null : 'disaster_relief'),
                ),
                FilterChip(
                  label: const Text('Community support'),
                  selected: _categoryFilter == 'community_support',
                  onSelected: (_) => setState(() => _categoryFilter = _categoryFilter == 'community_support' ? null : 'community_support'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService().donationDrivesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var drives = snapshot.data!.docs.map((d) => DonationDrive.fromFirestore(d)).toList();
                if (_categoryFilter != null) {
                  drives = drives.where((d) => d.category == _categoryFilter).toList();
                }
                if (drives.isEmpty) return const Center(child: Text('No donation drives yet. Tap + to create one.'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: drives.length,
                  itemBuilder: (_, i) {
                    final d = drives[i];
                    final progress = (d.goalAmount != null && d.goalAmount! > 0)
                        ? (d.raisedAmount / d.goalAmount!).clamp(0.0, 1.0)
                        : 0.0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (d.bannerUrl != null && d.bannerUrl!.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: d.bannerUrl!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                              errorWidget: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (d.category != null) ...[
                                  Text(d.category!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  const SizedBox(height: 4),
                                ],
                                Text(d.title, style: Theme.of(context).textTheme.titleMedium),
                                if (d.description != null) Text(d.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (d.ngoName != null) Text('By ${d.ngoName}', style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(value: progress),
                                const SizedBox(height: 4),
                                Text('Raised: ${d.raisedAmount.toStringAsFixed(0)} / ${d.goalAmount?.toStringAsFixed(0) ?? "—"}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/donation_drive.dart';
import '../../services/firestore_service.dart';

class DonationDrivesScreen extends StatefulWidget {
  const DonationDrivesScreen({super.key});

  @override
  State<DonationDrivesScreen> createState() => _DonationDrivesScreenState();
}

class _DonationDrivesScreenState extends State<DonationDrivesScreen> {
  String? _categoryFilter;

  void _showDriveDetail(DonationDrive d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (d.bannerUrl != null && d.bannerUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: d.bannerUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                d.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (d.category != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    d.category!.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              if (d.ngoName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('By ${d.ngoName}', style: TextStyle(color: Colors.grey[600])),
                ),
              if (d.description != null && d.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(d.description!, style: const TextStyle(height: 1.5)),
              ],
              if (d.location != null || d.address != null) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (d.location != null) Text(d.location!, style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (d.address != null) Text(d.address!, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (d.goalAmount != null && d.goalAmount! > 0)
                          ? (d.raisedAmount / d.goalAmount!).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Raised RM ${d.raisedAmount.toStringAsFixed(0)} / RM ${d.goalAmount?.toStringAsFixed(0) ?? "—"}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (d.contactEmail != null || d.contactPhone != null || d.whatsappNumber != null) ...[
                const SizedBox(height: 20),
                const Text('Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (d.contactEmail != null)
                      ActionChip(
                        avatar: const Icon(Icons.email, size: 18, color: Colors.white),
                        label: const Text('Email'),
                        onPressed: () => _launchUrl('mailto:${d.contactEmail}'),
                      ),
                    if (d.contactPhone != null)
                      ActionChip(
                        avatar: const Icon(Icons.phone, size: 18, color: Colors.white),
                        label: const Text('Call'),
                        onPressed: () => _launchUrl('tel:${d.contactPhone}'),
                      ),
                    if (d.whatsappNumber != null)
                      ActionChip(
                        avatar: const Icon(Icons.chat, size: 18, color: Colors.white),
                        label: const Text('WhatsApp'),
                        onPressed: () => _launchUrl('https://wa.me/${d.whatsappNumber!.replaceAll(RegExp(r'[^0-9]'), '')}'),
                      ),
                    if (d.lat != null && d.lng != null)
                      ActionChip(
                        avatar: const Icon(Icons.directions, size: 18, color: Colors.white),
                        label: const Text('Open in Maps'),
                        onPressed: () => _launchUrl('https://www.google.com/maps/dir/?api=1&destination=${d.lat},${d.lng}'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
                      child: InkWell(
                        onTap: () => _showDriveDetail(d),
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
                                    Text(d.category!.replaceAll('_', ' '), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(d.title, style: Theme.of(context).textTheme.titleMedium),
                                  if (d.description != null) Text(d.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  if (d.location != null)
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            d.location!,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (d.ngoName != null) Text('By ${d.ngoName}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(value: progress),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Raised: RM ${d.raisedAmount.toStringAsFixed(0)} / RM ${d.goalAmount?.toStringAsFixed(0) ?? "—"}'),
                                      Text('Tap for details', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

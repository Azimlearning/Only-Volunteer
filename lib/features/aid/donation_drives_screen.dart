import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/donation_drive.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class DonationDrivesScreen extends StatefulWidget {
  const DonationDrivesScreen({super.key});

  @override
  State<DonationDrivesScreen> createState() => _DonationDrivesScreenState();
}

class _DonationDrivesScreenState extends State<DonationDrivesScreen> {
  String? _categoryFilter;
  String? _campaignFilter; // disasterRelief, medicalHealth, communityInfrastructure, sustainedSupport
  int _currentPage = 0;
  static const int _itemsPerPage = 6;

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
              if (d.campaignCategory != null || d.category != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    d.campaignCategory != null
                        ? _campaignCategoryLabel(d.campaignCategory!)
                        : (d.category ?? '').replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              if (d.beneficiaryGroup != null && d.beneficiaryGroup!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Beneficiaries: ${d.beneficiaryGroup}',
                    style: TextStyle(color: figmaOrange, fontSize: 13, fontWeight: FontWeight.w500),
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
                style: FilledButton.styleFrom(backgroundColor: figmaOrange),
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

  String _campaignCategoryLabel(CampaignCategory c) {
    switch (c) {
      case CampaignCategory.disasterRelief:
        return 'Disaster Relief';
      case CampaignCategory.medicalHealth:
        return 'Medical & Health';
      case CampaignCategory.communityInfrastructure:
        return 'Community Infrastructure';
      case CampaignCategory.sustainedSupport:
        return 'Sustained Support';
    }
  }

  List<DonationDrive> _getPaginatedDrives(List<DonationDrive> drives) {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, drives.length);
    return drives.sublist(start.clamp(0, drives.length), end);
  }

  int _getTotalPages(int total) => (total / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // About Donation Drive section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/onlyvolunteer_logo.png',
                  width: 48,
                  height: 48,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: figmaOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.volunteer_activism, size: 24, color: figmaOrange),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Donation Drive',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Join or create donation drives to help those in need',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/create-drive'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create New Drive'),
                  style: FilledButton.styleFrom(
                    backgroundColor: figmaOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.grey[50],
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _categoryFilter == null && _campaignFilter == null,
                  selectedColor: figmaOrange.withOpacity(0.2),
                  checkmarkColor: figmaOrange,
                  onSelected: (_) => setState(() { _categoryFilter = null; _campaignFilter = null; }),
                ),
                FilterChip(
                  label: const Text('Disaster Relief'),
                  selected: _campaignFilter == 'disasterRelief',
                  selectedColor: figmaOrange.withOpacity(0.2),
                  checkmarkColor: figmaOrange,
                  onSelected: (_) => setState(() => _campaignFilter = _campaignFilter == 'disasterRelief' ? null : 'disasterRelief'),
                ),
                FilterChip(
                  label: const Text('Medical & Health'),
                  selected: _campaignFilter == 'medicalHealth',
                  selectedColor: figmaOrange.withOpacity(0.2),
                  checkmarkColor: figmaOrange,
                  onSelected: (_) => setState(() => _campaignFilter = _campaignFilter == 'medicalHealth' ? null : 'medicalHealth'),
                ),
                FilterChip(
                  label: const Text('Community Infrastructure'),
                  selected: _campaignFilter == 'communityInfrastructure',
                  selectedColor: figmaOrange.withOpacity(0.2),
                  checkmarkColor: figmaOrange,
                  onSelected: (_) => setState(() => _campaignFilter = _campaignFilter == 'communityInfrastructure' ? null : 'communityInfrastructure'),
                ),
                FilterChip(
                  label: const Text('Sustained Support'),
                  selected: _campaignFilter == 'sustainedSupport',
                  selectedColor: figmaOrange.withOpacity(0.2),
                  checkmarkColor: figmaOrange,
                  onSelected: (_) => setState(() => _campaignFilter = _campaignFilter == 'sustainedSupport' ? null : 'sustainedSupport'),
                ),
                FilterChip(
                  label: const Text('Disaster relief'),
                  selected: _categoryFilter == 'disaster_relief',
                  selectedColor: figmaOrange.withOpacity(0.2),
                  checkmarkColor: figmaOrange,
                  onSelected: (_) => setState(() => _categoryFilter = _categoryFilter == 'disaster_relief' ? null : 'disaster_relief'),
                ),
                FilterChip(
                  label: const Text('Community support'),
                  selected: _categoryFilter == 'community_support',
                  selectedColor: figmaOrange.withOpacity(0.2),
                  checkmarkColor: figmaOrange,
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
                if (_campaignFilter != null) {
                  drives = drives.where((d) => d.campaignCategory?.name == _campaignFilter).toList();
                }
                // Reset to first page when filter changes
                if (_currentPage >= _getTotalPages(drives.length)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _currentPage = 0);
                  });
                }
                if (drives.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.volunteer_activism, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No donation drives yet.', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () => context.go('/create-drive'),
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Drive'),
                            style: FilledButton.styleFrom(backgroundColor: figmaOrange),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final paginatedDrives = _getPaginatedDrives(drives);
                final totalPages = _getTotalPages(drives.length);
                return Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: paginatedDrives.length,
                        itemBuilder: (_, i) {
                          final d = paginatedDrives[i];
                          return Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => _showDriveDetail(d),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            Expanded(
                              flex: 3,
                              child: d.bannerUrl != null && d.bannerUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: d.bannerUrl!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: Colors.grey[200],
                                        child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
                                    ),
                            ),
                            // Content
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: figmaBlack,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: () => _showDriveDetail(d),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: figmaOrange,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        child: const Text(
                                          'View Details',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                          },
                        ),
                      ),
                    // Pagination controls
                    if (totalPages > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(top: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(totalPages, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () => setState(() => _currentPage = index),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _currentPage == index ? figmaOrange : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _currentPage == index ? figmaOrange : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: _currentPage == index ? Colors.white : figmaBlack,
                                        fontWeight: _currentPage == index ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

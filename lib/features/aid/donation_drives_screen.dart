import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const int _itemsPerPage = 8; // 4 per row x 2 rows

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
              // Title
              Text(
                d.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: figmaBlack),
              ),
              // Support type/Category
              if (d.campaignCategory != null || d.category != null) ...[
                const SizedBox(height: 4),
                Text(
                  d.campaignCategory != null
                      ? _campaignCategoryLabel(d.campaignCategory!)
                      : (d.category ?? '').replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
              // Beneficiaries (highlighted in orange)
              if (d.beneficiaryGroup != null && d.beneficiaryGroup!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Beneficiaries: ${d.beneficiaryGroup}',
                  style: TextStyle(color: figmaOrange, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
              // Organization name
              if (d.ngoName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'By ${d.ngoName}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
              // Description
              if (d.description != null && d.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  d.description!,
                  style: const TextStyle(height: 1.5, fontSize: 14),
                ),
              ],
              // Location
              if (d.location != null || d.address != null) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 20, color: figmaOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (d.location != null)
                            Text(
                              d.location!,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          if (d.address != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              d.address!,
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              // Progress bar
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: (d.goalAmount != null && d.goalAmount! > 0)
                          ? (d.raisedAmount / d.goalAmount!).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(figmaOrange),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Raised RM ${d.raisedAmount.toStringAsFixed(0)} / RM ${d.goalAmount?.toStringAsFixed(0) ?? "—"}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: figmaBlack),
                    ),
                  ],
                ),
              ),
              // Contact section
              if (d.contactEmail != null || d.contactPhone != null || d.whatsappNumber != null || (d.lat != null && d.lng != null)) ...[
                const SizedBox(height: 24),
                const Text(
                  'Contact',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (d.contactEmail != null) ...[
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.email,
                          label: 'Email',
                          onPressed: () => _launchUrl('mailto:${d.contactEmail}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (d.contactPhone != null) ...[
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.phone,
                          label: 'Call',
                          onPressed: () => _launchUrl('tel:${d.contactPhone}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (d.whatsappNumber != null) ...[
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          onPressed: () => _launchUrl('https://wa.me/${d.whatsappNumber!.replaceAll(RegExp(r'[^0-9]'), '')}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (d.lat != null && d.lng != null)
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.directions,
                          label: 'Open in Maps',
                          onPressed: () => _launchUrl('https://www.google.com/maps/dir/?api=1&destination=${d.lat},${d.lng}'),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              // Payment method
              const Text(
                'Payment method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
              ),
              const SizedBox(height: 12),
              if (d.qrCodeUrl != null && d.qrCodeUrl!.isNotEmpty) ...[
                const Text(
                  'Scan QR Code to Donate',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: d.qrCodeUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(child: CircularProgressIndicator(color: figmaOrange)),
                        ),
                        errorWidget: (_, __, ___) => Icon(Icons.qr_code, size: 64, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (d.bank != null || d.accountName != null || d.accountNumber != null) ...[
                const Text(
                  'Bank Transfer Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (d.bank != null) ...[
                        _BankDetailRow(label: 'Bank', value: _formatBankName(d.bank!)),
                        const SizedBox(height: 12),
                      ],
                      if (d.accountName != null) ...[
                        _BankDetailRow(label: 'Account Name', value: d.accountName!),
                        const SizedBox(height: 12),
                      ],
                      if (d.accountNumber != null) ...[
                        _BankDetailRow(label: 'Account Number', value: d.accountNumber!),
                      ],
                    ],
                  ),
                ),
                if (d.accountNumber != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: d.accountNumber!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Account number copied: ${d.accountNumber}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Account Number'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: figmaOrange,
                      side: BorderSide(color: figmaOrange),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
              if ((d.qrCodeUrl == null || d.qrCodeUrl!.isEmpty) &&
                  (d.bank == null && d.accountName == null && d.accountNumber == null)) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment details not available. Please contact the organization directly.',
                          style: TextStyle(color: Colors.amber[900], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Donate button
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showDonateDialog(d);
                },
                icon: const Icon(Icons.favorite),
                label: const Text('Donate'),
                style: FilledButton.styleFrom(
                  backgroundColor: figmaOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              // Close button
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: figmaBlack,
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
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

  void _showDonateDialog(DonationDrive d) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: figmaOrange),
            const SizedBox(width: 8),
            const Text('Donate Now'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                d.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // QR Code
              if (d.qrCodeUrl != null && d.qrCodeUrl!.isNotEmpty) ...[
                const Text(
                  'Scan QR Code to Donate',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: d.qrCodeUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(color: figmaOrange),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[200],
                          child: Icon(Icons.qr_code, size: 64, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Bank Details
              if (d.bank != null || d.accountName != null || d.accountNumber != null) ...[
                const Text(
                  'Bank Transfer Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (d.bank != null) ...[
                        _BankDetailRow(label: 'Bank', value: _formatBankName(d.bank!)),
                        const SizedBox(height: 12),
                      ],
                      if (d.accountName != null) ...[
                        _BankDetailRow(label: 'Account Name', value: d.accountName!),
                        const SizedBox(height: 12),
                      ],
                      if (d.accountNumber != null) ...[
                        _BankDetailRow(label: 'Account Number', value: d.accountNumber!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Copy button for account number
                if (d.accountNumber != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: d.accountNumber!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Account number copied: ${d.accountNumber}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Account Number'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: figmaPurple,
                      side: BorderSide(color: figmaPurple),
                    ),
                  ),
              ],
              // If no payment method available
              if ((d.qrCodeUrl == null || d.qrCodeUrl!.isEmpty) &&
                  (d.bank == null && d.accountName == null && d.accountNumber == null)) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment details not available. Please contact the organization directly.',
                          style: TextStyle(color: Colors.amber[900], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatBankName(String bank) {
    switch (bank.toLowerCase()) {
      case 'maybank':
        return 'Maybank';
      case 'cimb':
        return 'CIMB Bank';
      case 'public':
        return 'Public Bank';
      case 'hongleong':
        return 'Hong Leong Bank';
      case 'rhb':
        return 'RHB Bank';
      case 'ambank':
        return 'AmBank';
      default:
        return bank;
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

  String _driveCategoryLabel(DonationDrive d) {
    if (d.campaignCategory != null) return _campaignCategoryLabel(d.campaignCategory!);
    return (d.category ?? '').replaceAll('_', ' ').toUpperCase();
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
                FilledButton(
                  onPressed: () => context.go('/create-drive'),
                  style: FilledButton.styleFrom(
                    backgroundColor: figmaOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Create New Drive'),
                ),
              ],
            ),
          ),
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.grey[50],
            child: DropdownButtonFormField<String?>(
              value: _campaignFilter ?? _categoryFilter ?? 'all',
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'disasterRelief', child: Text('Disaster Relief')),
                DropdownMenuItem(value: 'medicalHealth', child: Text('Medical & Health')),
                DropdownMenuItem(value: 'communityInfrastructure', child: Text('Community Infrastructure')),
                DropdownMenuItem(value: 'sustainedSupport', child: Text('Sustained Support')),
                DropdownMenuItem(value: 'disaster_relief', child: Text('Disaster relief')),
                DropdownMenuItem(value: 'community_support', child: Text('Community support')),
              ],
              onChanged: (v) {
                setState(() {
                  if (v == null || v == 'all') {
                    _campaignFilter = null;
                    _categoryFilter = null;
                  } else if (v == 'disaster_relief' || v == 'community_support') {
                    _categoryFilter = v;
                    _campaignFilter = null;
                  } else {
                    _campaignFilter = v;
                    _categoryFilter = null;
                  }
                });
              },
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
                final rowCount = (paginatedDrives.length / 2).ceil();
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rowCount,
                        itemBuilder: (_, rowIndex) {
                          final leftIndex = rowIndex * 2;
                          final rightIndex = leftIndex + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _DriveCard(
                                    drive: paginatedDrives[leftIndex],
                                    categoryLabel: _driveCategoryLabel(paginatedDrives[leftIndex]),
                                    onTap: () => _showDriveDetail(paginatedDrives[leftIndex]),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: rightIndex < paginatedDrives.length
                                      ? _DriveCard(
                                          drive: paginatedDrives[rightIndex],
                                          categoryLabel: _driveCategoryLabel(paginatedDrives[rightIndex]),
                                          onTap: () => _showDriveDetail(paginatedDrives[rightIndex]),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
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

// Card layout per card_ui_recommendations.md: accent bar, no image, meta rows, badge, divider, CTA.
class _DriveCard extends StatelessWidget {
  const _DriveCard({
    required this.drive,
    required this.categoryLabel,
    required this.onTap,
  });

  final DonationDrive drive;
  final String categoryLabel;
  final VoidCallback onTap;

  static const _space8 = 8.0;
  static const _space12 = 12.0;
  static const _radiusMd = 12.0;
  static const _radiusLg = 16.0;

  @override
  Widget build(BuildContext context) {
    final raisedText = 'Raised RM ${drive.raisedAmount.toStringAsFixed(0)} / RM ${drive.goalAmount?.toStringAsFixed(0) ?? "—"}';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusLg),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, color: figmaOrange),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    drive.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: figmaBlack,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: _space12),
                  if (drive.location != null)
                    _DriveMetaRow(icon: Icons.location_on_outlined, text: drive.location!),
                  if (drive.location != null) const SizedBox(height: _space8),
                  if (drive.ngoName != null)
                    _DriveMetaRow(icon: Icons.business_outlined, text: 'By ${drive.ngoName}'),
                  if (drive.ngoName != null) const SizedBox(height: _space8),
                  _DriveMetaRow(icon: Icons.volunteer_activism, text: raisedText),
                  if (categoryLabel.isNotEmpty) ...[
                    const SizedBox(height: _space12),
                    Wrap(
                      spacing: _space8,
                      runSpacing: _space8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: _space8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            categoryLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: figmaOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radiusMd),
                    ),
                  ),
                  child: const Text('Donate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriveMetaRow extends StatelessWidget {
  const _DriveMetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: figmaBlack,
        side: BorderSide(color: Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  const _BankDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: figmaBlack,
            ),
          ),
        ),
      ],
    );
  }
}

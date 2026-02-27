import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/volunteer_listing.dart';
import '../../models/micro_donation_request.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

enum _FilterMode { all, volunteering, donations }

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final FirestoreService _firestore = FirestoreService();
  List<VolunteerListing> _listings = [];
  List<MicroDonationRequest> _microDonations = [];
  bool _loading = true;
  _FilterMode _filter = _FilterMode.all;
  MicroDonationCategory? _donationCategoryFilter;
  int _currentPage = 0;
  static const int _itemsPerPage = 8; // 4 per row x 2 rows

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _currentPage = 0; // Reset to first page when reloading
    });
    // Check if user is NGO or Admin to show private opportunities
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    final canSeePrivate = auth.appUser?.role == UserRole.ngo || auth.appUser?.role == UserRole.admin;
    final listings = await _firestore.getVolunteerListings(showPrivate: canSeePrivate);
    final micro = await _firestore.getMicroDonations(status: 'open');
    if (mounted) {
      setState(() {
        _listings = listings;
        _microDonations = micro;
        _loading = false;
      });
    }
  }


  void _openMicroDonationSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddMicroDonationSheet(onSubmitted: () {
        Navigator.pop(context);
        _load();
      }),
    );
  }

  void _showOpportunityDetail(VolunteerListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                listing.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: figmaBlack),
              ),
              // Organization name
              if (listing.organizationName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'By ${listing.organizationName}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
              // Description
              if (listing.description != null && listing.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  listing.description!,
                  style: const TextStyle(height: 1.5, fontSize: 14),
                ),
              ],
              // Location
              if (listing.location != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: figmaOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        listing.location!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
              // Category/Skills
              if (listing.skillsRequired.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: listing.skillsRequired.map((skill) {
                    return Chip(
                      label: Text(skill),
                      backgroundColor: figmaPurple.withOpacity(0.1),
                      labelStyle: TextStyle(color: figmaPurple, fontSize: 12, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ],
              // Date/Time range
              if (listing.startTime != null || listing.endTime != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: figmaOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        listing.startTime != null && listing.endTime != null
                            ? '${_formatDate(listing.startTime!)} - ${_formatDate(listing.endTime!)}'
                            : listing.startTime != null
                                ? 'Starting: ${_formatDate(listing.startTime!)}'
                                : 'Ending: ${_formatDate(listing.endTime!)}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
              // Slots info
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 18, color: figmaOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${listing.slotsTotal - listing.slotsFilled} of ${listing.slotsTotal} slots available',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              // Monetary donation section
              if (listing.acceptsMonetaryDonation == true) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: figmaPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: figmaPurple.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 18, color: figmaPurple),
                          const SizedBox(width: 8),
                          Text(
                            'Monetary Donations Accepted',
                            style: TextStyle(
                              color: figmaPurple,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (listing.monetaryGoal != null) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: listing.monetaryRaised != null && listing.monetaryGoal! > 0
                              ? (listing.monetaryRaised! / listing.monetaryGoal!).clamp(0.0, 1.0)
                              : 0.0,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          backgroundColor: figmaPurple.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(figmaPurple),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Raised RM ${listing.monetaryRaised?.toStringAsFixed(0) ?? "0"} / RM ${listing.monetaryGoal!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              // Visibility/Status indicators
              if (listing.visibility == RequestVisibility.private) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 18, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Private Request - Only visible to verified NGOs',
                          style: TextStyle(color: Colors.amber[900], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (listing.isRegisteredWithJKM == true || listing.isB40Household == true) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (listing.isRegisteredWithJKM == true)
                      Chip(
                        avatar: Icon(Icons.verified, size: 16, color: figmaOrange),
                        label: const Text('JKM Registered', style: TextStyle(fontSize: 11)),
                        backgroundColor: figmaOrange.withOpacity(0.1),
                      ),
                    if (listing.isB40Household == true)
                      Chip(
                        avatar: Icon(Icons.home, size: 16, color: figmaPurple),
                        label: const Text('B40 Household', style: TextStyle(fontSize: 11)),
                        backgroundColor: figmaPurple.withOpacity(0.1),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Implement message functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Message functionality coming soon')),
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: figmaPurple,
                        side: BorderSide(color: figmaPurple),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (listing.lat != null && listing.lng != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _openMaps(listing);
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Maps'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: figmaOrange,
                          side: BorderSide(color: figmaOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _ApplyButtonWithState(
                listing: listing,
                onApply: _applyListing,
                onDone: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _openMaps(VolunteerListing listing) async {
    if (listing.lat == null || listing.lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${listing.lat},${listing.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _applyListing(VolunteerListing listing) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to apply')));
      return;
    }
    try {
      await _firestore.applyToListing(listing.id, uid);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _fulfillRequest(MicroDonationRequest req) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to fulfill')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fulfill request?'),
        content: Text('Mark "${req.title}" as fulfilled? Arrange delivery offline.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: figmaOrange),
            child: const Text('Fulfill'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _firestore.fulfillMicroDonation(req.id, uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as fulfilled')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
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
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Opportunities',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Volunteer your time or fulfill donation requests',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => context.go('/my-requests'),
                  style: FilledButton.styleFrom(
                    backgroundColor: figmaOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('My Requests'),
                ),
              ],
            ),
          ),
          // Filter toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.grey[50],
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == _FilterMode.all,
                  onTap: () => setState(() => _filter = _FilterMode.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Volunteering',
                  selected: _filter == _FilterMode.volunteering,
                  onTap: () => setState(() => _filter = _FilterMode.volunteering),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Donations',
                  selected: _filter == _FilterMode.donations,
                  onTap: () => setState(() => _filter = _FilterMode.donations),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<MicroDonationCategory?>(
                    value: _donationCategoryFilter,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<MicroDonationCategory?>(value: null, child: Text('All')),
                      ...MicroDonationCategory.values.map((c) => DropdownMenuItem<MicroDonationCategory?>(
                            value: c,
                            child: Text(_donationCategoryLabel(c)),
                          )),
                    ],
                    onChanged: (v) => setState(() => _donationCategoryFilter = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
        ),
      ],
    );
  }

  List<VolunteerListing> _getPaginatedListings() {
    final start = _currentPage * _itemsPerPage;
    final end = start + _itemsPerPage;
    return _listings.sublist(start.clamp(0, _listings.length), end.clamp(0, _listings.length));
  }

  List<MicroDonationRequest> _getPaginatedDonations() {
    final start = _currentPage * _itemsPerPage;
    final end = start + _itemsPerPage;
    return _microDonations.sublist(start.clamp(0, _microDonations.length), end.clamp(0, _microDonations.length));
  }

  int _getTotalPages(int itemCount) {
    return (itemCount / _itemsPerPage).ceil();
  }

  Widget _buildContent() {
    final showVolunteering = _filter == _FilterMode.all || _filter == _FilterMode.volunteering;
    final showDonations = _filter == _FilterMode.all || _filter == _FilterMode.donations;

    if (_filter == _FilterMode.all && _listings.isEmpty && _microDonations.isEmpty) {
      return const Center(child: Text('No opportunities yet. Tap + to post one.'));
    }
    if (_filter == _FilterMode.volunteering && _listings.isEmpty) {
      return const Center(child: Text('No volunteer opportunities yet.'));
    }
    if (_filter == _FilterMode.donations && _microDonations.isEmpty) {
      return const Center(child: Text('No donation requests yet.'));
    }

    final filteredDonations = _donationCategoryFilter == null
        ? _microDonations
        : _microDonations.where((r) => r.category == _donationCategoryFilter).toList();

    // Determine which items to show based on filter
    List<dynamic> itemsToShow;
    if (_filter == _FilterMode.volunteering) {
      itemsToShow = _listings;
    } else if (_filter == _FilterMode.donations) {
      itemsToShow = filteredDonations;
    } else {
      // All mode - show volunteering first, then donations
      itemsToShow = [..._listings, ...filteredDonations];
    }

    final totalPages = _getTotalPages(itemsToShow.length);
    
    // Reset to first page if current page is out of bounds
    if (_currentPage >= totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = 0);
      });
    }

    // Get paginated items
    final start = _currentPage * _itemsPerPage;
    final end = start + _itemsPerPage;
    final paginatedItems = itemsToShow.sublist(start.clamp(0, itemsToShow.length), end.clamp(0, itemsToShow.length));

    final rowCount = (paginatedItems.length / 2).ceil();
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rowCount,
            itemBuilder: (context, rowIndex) {
              final leftIndex = rowIndex * 2;
              final rightIndex = leftIndex + 1;
              final leftItem = paginatedItems[leftIndex];
              final rightItem = rightIndex < paginatedItems.length ? paginatedItems[rightIndex] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildOpportunityCard(leftItem, () {
                        if (leftItem is VolunteerListing) _showOpportunityDetail(leftItem);
                        else if (leftItem is MicroDonationRequest) _showMicroDonationDetail(leftItem);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: rightItem != null
                          ? _buildOpportunityCard(rightItem, () {
                              if (rightItem is VolunteerListing) _showOpportunityDetail(rightItem);
                              else if (rightItem is MicroDonationRequest) _showMicroDonationDetail(rightItem);
                            })
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
  }

  String _donationCategoryLabel(MicroDonationCategory c) {
    switch (c) {
      case MicroDonationCategory.specific_food:
        return 'Specific Food';
      case MicroDonationCategory.furniture:
        return 'Furniture';
      case MicroDonationCategory.appliances:
        return 'Appliances';
      case MicroDonationCategory.medical:
        return 'Medical';
      case MicroDonationCategory.education:
        return 'Education';
      case MicroDonationCategory.other:
        return 'Other';
    }
  }

  Widget _buildOpportunityCard(dynamic item, VoidCallback onTap) {
    if (item is VolunteerListing) {
      return _VolunteerCard(listing: item, onTap: onTap);
    }
    if (item is MicroDonationRequest) {
      return _MicroDonationCard(request: item, onTap: onTap);
    }
    return const SizedBox.shrink();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
      ),
    );
  }

  void _showMicroDonationDetail(MicroDonationRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                request.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: figmaBlack),
              ),
              // Requester name
              if (request.requesterName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'By ${request.requesterName}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
              // Description
              if (request.description != null && request.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  request.description!,
                  style: const TextStyle(height: 1.5, fontSize: 14),
                ),
              ],
              // Category
              const SizedBox(height: 16),
              Chip(
                label: Text(request.categoryName),
                backgroundColor: figmaPurple.withOpacity(0.1),
                labelStyle: TextStyle(color: figmaPurple, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              // Item needed
              if (request.itemNeeded != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag, size: 18, color: figmaPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Needs: ${request.itemNeeded}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            if (request.quantity > 1)
                              Text(
                                'Quantity: ${request.quantity}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Location
              if (request.location != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: figmaOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.location!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
              // Urgency
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getUrgencyColor(request.urgency).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getUrgencyColor(request.urgency).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.priority_high, size: 18, color: _getUrgencyColor(request.urgency)),
                    const SizedBox(width: 8),
                    Text(
                      'Urgency: ${request.urgency.toUpperCase()}',
                      style: TextStyle(
                        color: _getUrgencyColor(request.urgency),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Implement message functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Message functionality coming soon')),
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: figmaPurple,
                        side: BorderSide(color: figmaPurple),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (request.lat != null && request.lng != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _openMapsForRequest(request);
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Maps'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: figmaOrange,
                          side: BorderSide(color: figmaOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showDonateDialogForRequest(request);
                },
                icon: const Icon(Icons.favorite),
                label: const Text('Donate'),
                style: FilledButton.styleFrom(
                  backgroundColor: figmaPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openMapsForRequest(MicroDonationRequest request) async {
    if (request.lat == null || request.lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${request.lat},${request.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDonateDialogForRequest(MicroDonationRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: figmaPurple),
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
                request.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // QR Code
              if (request.qrCodeUrl != null && request.qrCodeUrl!.isNotEmpty) ...[
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
                        imageUrl: request.qrCodeUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(color: figmaPurple),
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
              if (request.bank != null || request.accountName != null || request.accountNumber != null) ...[
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
                      if (request.bank != null) ...[
                        _BankDetailRow(label: 'Bank', value: _formatBankName(request.bank!)),
                        const SizedBox(height: 12),
                      ],
                      if (request.accountName != null) ...[
                        _BankDetailRow(label: 'Account Name', value: request.accountName!),
                        const SizedBox(height: 12),
                      ],
                      if (request.accountNumber != null) ...[
                        _BankDetailRow(label: 'Account Number', value: request.accountNumber!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Copy button for account number
                if (request.accountNumber != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: request.accountNumber!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Account number copied: ${request.accountNumber}'),
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
              if ((request.qrCodeUrl == null || request.qrCodeUrl!.isEmpty) &&
                  (request.bank == null && request.accountName == null && request.accountNumber == null)) ...[
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
                          'Payment details not available. Please contact the requester directly.',
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
}

class _ApplyButtonWithState extends StatefulWidget {
  const _ApplyButtonWithState({
    required this.listing,
    required this.onApply,
    required this.onDone,
  });
  final VolunteerListing listing;
  final Future<void> Function(VolunteerListing) onApply;
  final VoidCallback onDone;

  @override
  State<_ApplyButtonWithState> createState() => _ApplyButtonWithStateState();
}

class _ApplyButtonWithStateState extends State<_ApplyButtonWithState> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _applying
          ? null
          : () async {
              setState(() => _applying = true);
              await widget.onApply(widget.listing);
              if (mounted) {
                setState(() => _applying = false);
                widget.onDone();
              }
            },
      icon: _applying
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.check_circle),
      label: Text(_applying ? 'Applying...' : 'Apply'),
      style: FilledButton.styleFrom(
        backgroundColor: figmaOrange,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: figmaOrange.withOpacity(0.2),
      checkmarkColor: figmaOrange,
      onSelected: (_) => onTap(),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, this.iconSize = 14});

  final IconData icon;
  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: iconSize, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({required this.listing, required this.onTap});

  final VolunteerListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slotsLeft = listing.slotsTotal - listing.slotsFilled;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, width: double.infinity, color: figmaOrange),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  listing.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                if (listing.location != null)
                  _MetaRow(icon: Icons.location_on, label: listing.location!, iconSize: 14),
                if (listing.location != null && (listing.organizationName != null || listing.skillsRequired.isNotEmpty)) const SizedBox(height: 8),
                if (listing.organizationName != null)
                  _MetaRow(icon: Icons.business, label: listing.organizationName!, iconSize: 14),
                if (listing.organizationName != null) const SizedBox(height: 8),
                _MetaRow(icon: Icons.people, label: '${slotsLeft > 0 ? slotsLeft : 0} slots left', iconSize: 14),
                const SizedBox(height: 12),
                if (listing.skillsRequired.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: listing.skillsRequired.take(3).map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: figmaOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: figmaOrange)),
                    )).toList(),
                  ),
                if (listing.skillsRequired.isEmpty && listing.acceptsMonetaryDonation == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: figmaPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Accepts RM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: figmaPurple)),
                  ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: slotsLeft > 0 ? onTap : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: figmaOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(slotsLeft > 0 ? 'View Details' : 'Full', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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

class _MicroDonationCard extends StatelessWidget {
  const _MicroDonationCard({required this.request, required this.onTap});

  final MicroDonationRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, width: double.infinity, color: figmaPurple),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                if (request.itemNeeded != null)
                  _MetaRow(icon: Icons.shopping_bag, label: request.itemNeeded!, iconSize: 14),
                if (request.itemNeeded != null && request.location != null) const SizedBox(height: 8),
                if (request.location != null)
                  _MetaRow(icon: Icons.location_on, label: request.location!, iconSize: 14),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: figmaPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(request.categoryName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: figmaPurple)),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: figmaPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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

class _AddMicroDonationSheet extends StatefulWidget {
  const _AddMicroDonationSheet({required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  State<_AddMicroDonationSheet> createState() => _AddMicroDonationSheetState();
}

class _AddMicroDonationSheetState extends State<_AddMicroDonationSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _itemController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _qrCodeUrlController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  MicroDonationCategory _category = MicroDonationCategory.other;
  bool _saving = false;
  bool _acceptMonetary = false;
  String? _bank;

  static const List<Map<String, String>> _bankOptions = [
    {'value': 'maybank', 'label': 'Maybank'},
    {'value': 'cimb', 'label': 'CIMB Bank'},
    {'value': 'public', 'label': 'Public Bank'},
    {'value': 'hongleong', 'label': 'Hong Leong Bank'},
    {'value': 'rhb', 'label': 'RHB Bank'},
    {'value': 'ambank', 'label': 'AmBank'},
    {'value': 'uob', 'label': 'UOB'},
    {'value': 'ocbc', 'label': 'OCBC'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _itemController.dispose();
    _locationController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _qrCodeUrlController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title')));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to post')));
      return;
    }
    setState(() => _saving = true);
    try {
      final ref = FirebaseFirestore.instance.collection('micro_donations').doc();
      final contactEmail = _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim();
      final contactPhone = _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim();
      final qrCodeUrl = _acceptMonetary ? (_qrCodeUrlController.text.trim().isEmpty ? null : _qrCodeUrlController.text.trim()) : null;
      final bank = _acceptMonetary ? _bank : null;
      final accountName = _acceptMonetary ? (_accountNameController.text.trim().isEmpty ? null : _accountNameController.text.trim()) : null;
      final accountNumber = _acceptMonetary ? (_accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim()) : null;
      final request = MicroDonationRequest(
        id: ref.id,
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        category: _category,
        requesterId: uid,
        requesterName: FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email,
        itemNeeded: _itemController.text.trim().isEmpty ? null : _itemController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        qrCodeUrl: qrCodeUrl,
        bank: bank,
        accountName: accountName,
        accountNumber: accountNumber,
        status: MicroDonationStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await FirestoreService().addMicroDonationRequest(request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request posted')));
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Post donation request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MicroDonationCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: MicroDonationCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? MicroDonationCategory.other),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Item needed (e.g. mattress, laptop)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _contactEmailController,
              decoration: const InputDecoration(labelText: 'Contact email (optional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(labelText: 'Contact phone (optional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _acceptMonetary,
              onChanged: (v) => setState(() => _acceptMonetary = v ?? false),
              title: const Text('Accept monetary donations?'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_acceptMonetary) ...[
              const SizedBox(height: 12),
              const Text('Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _qrCodeUrlController,
                decoration: const InputDecoration(labelText: 'QR Code URL (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _bank,
                decoration: const InputDecoration(labelText: 'Bank', hintText: 'Select Bank', border: OutlineInputBorder()),
                items: _bankOptions
                    .map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!)))
                    .toList(),
                onChanged: (v) => setState(() => _bank = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _accountNameController,
                decoration: const InputDecoration(labelText: 'Account name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _accountNumberController,
                decoration: const InputDecoration(labelText: 'Account number', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: figmaOrange),
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post request'),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(MicroDonationCategory c) {
    switch (c) {
      case MicroDonationCategory.specific_food:
        return 'Specific Food';
      case MicroDonationCategory.furniture:
        return 'Furniture';
      case MicroDonationCategory.appliances:
        return 'Appliances';
      case MicroDonationCategory.medical:
        return 'Medical';
      case MicroDonationCategory.education:
        return 'Education';
      case MicroDonationCategory.other:
        return 'Other';
    }
  }
}

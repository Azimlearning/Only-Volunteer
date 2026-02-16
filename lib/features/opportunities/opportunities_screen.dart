import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/volunteer_listing.dart';
import '../../models/micro_donation_request.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final listings = await _firestore.getVolunteerListings();
    final micro = await _firestore.getMicroDonations(status: 'open');
    if (mounted) {
      setState(() {
        _listings = listings;
        _microDonations = micro;
        _loading = false;
      });
    }
  }

  void _openPostDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post opportunity'),
        content: const Text('What would you like to post?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/create-opportunity');
            },
            child: const Text('Volunteering opportunity'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openMicroDonationSheet();
            },
            style: FilledButton.styleFrom(backgroundColor: figmaOrange),
            child: const Text('Donation request'),
          ),
        ],
      ),
    );
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
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openPostDialog,
        backgroundColor: figmaOrange,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Post opportunity',
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
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/onlyvolunteer_logo.png',
                  width: 48,
                  height: 48,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: figmaOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work, size: 24, color: figmaOrange),
                  ),
                ),
                const SizedBox(width: 16),
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
                TextButton.icon(
                  onPressed: () => context.go('/my-requests'),
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('My Requests'),
                  style: TextButton.styleFrom(foregroundColor: figmaPurple),
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
    );
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showVolunteering && _listings.isNotEmpty) ...[
          if (_filter == _FilterMode.all) _sectionTitle('Volunteering'),
          ...(_filter == _FilterMode.all ? _listings.take(5) : _listings).map((l) => _VolunteerCard(
                listing: l,
                onApply: () => _applyListing(l),
              )),
          if (_filter == _FilterMode.all && _listings.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () => setState(() => _filter = _FilterMode.volunteering),
                child: const Text('View all volunteering'),
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (showDonations && _microDonations.isNotEmpty) ...[
          if (_filter == _FilterMode.all) _sectionTitle('Donation requests'),
          ...(_filter == _FilterMode.all ? _microDonations.take(5) : _microDonations).map((r) => _MicroDonationCard(
                request: r,
                onFulfill: () => _fulfillRequest(r),
              )),
          if (_filter == _FilterMode.all && _microDonations.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () => setState(() => _filter = _FilterMode.donations),
                child: const Text('View all donation requests'),
              ),
            ),
        ],
      ],
    );
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

class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({required this.listing, required this.onApply});

  final VolunteerListing listing;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final slotsLeft = listing.slotsTotal - listing.slotsFilled;
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
                Icon(Icons.volunteer_activism, color: figmaOrange, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    listing.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
                  ),
                ),
              ],
            ),
            if (listing.description != null) ...[
              const SizedBox(height: 4),
              Text(listing.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
            if (listing.location != null) ...[
              const SizedBox(height: 6),
              Text(listing.location!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: slotsLeft > 0 ? onApply : null,
              style: FilledButton.styleFrom(backgroundColor: figmaOrange),
              child: Text(slotsLeft > 0 ? 'Apply' : 'Full'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicroDonationCard extends StatelessWidget {
  const _MicroDonationCard({required this.request, required this.onFulfill});

  final MicroDonationRequest request;
  final VoidCallback onFulfill;

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.card_giftcard, color: figmaPurple, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
                  ),
                ),
                Chip(
                  label: Text(request.categoryName, style: const TextStyle(fontSize: 11)),
                  backgroundColor: figmaPurple.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (request.itemNeeded != null) ...[
              const SizedBox(height: 4),
              Text('Needs: ${request.itemNeeded}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
            if (request.location != null) ...[
              const SizedBox(height: 4),
              Text(request.location!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onFulfill,
              style: FilledButton.styleFrom(backgroundColor: figmaPurple),
              child: const Text('Fulfill request'),
            ),
          ],
        ),
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
  MicroDonationCategory _category = MicroDonationCategory.other;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _itemController.dispose();
    _locationController.dispose();
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
      final request = MicroDonationRequest(
        id: ref.id,
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        category: _category,
        requesterId: uid,
        requesterName: FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email,
        itemNeeded: _itemController.text.trim().isEmpty ? null : _itemController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
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

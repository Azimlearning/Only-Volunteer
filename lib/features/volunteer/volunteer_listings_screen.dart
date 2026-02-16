import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../models/volunteer_listing.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class VolunteerListingsScreen extends StatefulWidget {
  const VolunteerListingsScreen({super.key});

  @override
  State<VolunteerListingsScreen> createState() => _VolunteerListingsScreenState();
}

class _VolunteerListingsScreenState extends State<VolunteerListingsScreen> {
  final FirestoreService _firestore = FirestoreService();
  List<VolunteerListing> _listings = [];
  Set<String> _savedIds = {};
  DocumentSnapshot? _lastDoc;
  bool _loading = true;
  bool _loadingMore = false;
  String? _skillFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int _currentPage = 0;
  static const int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _lastDoc = null; });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final result = await _firestore.getVolunteerListingsPaginated(limit: 20);
    var list = result.list;
    if (_skillFilter != null) list = list.where((l) => l.skillsRequired.contains(_skillFilter)).toList();
    if (_dateFrom != null) list = list.where((l) => l.startTime != null && !l.startTime!.isBefore(_dateFrom!)).toList();
    if (_dateTo != null) list = list.where((l) => l.startTime != null && !l.startTime!.isAfter(_dateTo!)).toList();
    if (uid != null) {
      final saved = await _firestore.getSavedListingIds(uid);
      if (mounted) {
        setState(() {
          _listings = list;
          _lastDoc = result.lastDoc;
          _savedIds = saved.toSet();
          _loading = false;
          _currentPage = 0; // Reset to first page when filters change
        });
      }
    } else if (mounted) {
      setState(() {
        _listings = list;
        _lastDoc = result.lastDoc;
        _loading = false;
        _currentPage = 0; // Reset to first page when filters change
      });
    }
  }

  Future<void> _loadMore() async {
    if (_lastDoc == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    final result = await _firestore.getVolunteerListingsPaginated(limit: 20, startAfter: _lastDoc);
    var list = [..._listings, ...result.list];
    if (_skillFilter != null) list = list.where((l) => l.skillsRequired.contains(_skillFilter)).toList();
    if (_dateFrom != null) list = list.where((l) => l.startTime != null && !l.startTime!.isBefore(_dateFrom!)).toList();
    if (_dateTo != null) list = list.where((l) => l.startTime != null && !l.startTime!.isAfter(_dateTo!)).toList();
    if (mounted) setState(() { _listings = list; _lastDoc = result.lastDoc; _loadingMore = false; });
  }

  Future<void> _toggleSaved(VolunteerListing listing) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to save')));
      return;
    }
    final isSaved = _savedIds.contains(listing.id);
    try {
      if (isSaved) {
        await _firestore.removeSavedListing(uid, listing.id);
        setState(() => _savedIds.remove(listing.id));
      } else {
        await _firestore.addSavedListing(uid, listing.id);
        setState(() => _savedIds.add(listing.id));
      }
    } catch (_) {}
  }

  Future<void> _apply(BuildContext context, String listingId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to apply')));
      return;
    }
    try {
      await _firestore.applyToListing(listingId, uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickDateFrom() async {
    final d = await showDatePicker(context: context, initialDate: _dateFrom ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null) setState(() { _dateFrom = d; _load(); });
  }

  Future<void> _pickDateTo() async {
    final d = await showDatePicker(context: context, initialDate: _dateTo ?? DateTime.now(), firstDate: _dateFrom ?? DateTime(2020), lastDate: DateTime(2030));
    if (d != null) setState(() { _dateTo = d; _load(); });
  }

  List<VolunteerListing> get _paginatedListings {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _listings.length);
    return _listings.sublist(start.clamp(0, _listings.length), end);
  }

  int get _totalPages => (_listings.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final allSkills = _listings.expand((l) => l.skillsRequired).toSet().toList()..sort();
    if (allSkills.length > 8) allSkills.removeRange(8, allSkills.length);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // About Opportunities section
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
                        'Find volunteer opportunities that match your skills',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/create-opportunity'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Opportunities'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Text('Skill:', style: TextStyle(fontWeight: FontWeight.w500)),
                    FilterChip(
                      label: const Text('All'),
                      selected: _skillFilter == null,
                      selectedColor: figmaOrange.withOpacity(0.2),
                      checkmarkColor: figmaOrange,
                      onSelected: (_) => setState(() { _skillFilter = null; _load(); }),
                    ),
                    ...allSkills.map((s) => FilterChip(
                      label: Text(s),
                      selected: _skillFilter == s,
                      selectedColor: figmaOrange.withOpacity(0.2),
                      checkmarkColor: figmaOrange,
                      onSelected: (_) => setState(() { _skillFilter = _skillFilter == s ? null : s; _load(); }),
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDateFrom,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_dateFrom != null ? 'From: ${_dateFrom!.day}/${_dateFrom!.month}' : 'From'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDateTo,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_dateTo != null ? 'To: ${_dateTo!.day}/${_dateTo!.month}' : 'To'),
                    ),
                    if (_dateFrom != null || _dateTo != null)
                      TextButton(onPressed: () => setState(() { _dateFrom = null; _dateTo = null; _load(); }), child: const Text('Clear')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _listings.isEmpty
                    ? const Center(child: Text('No opportunities yet.'))
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _paginatedListings.length,
                              itemBuilder: (_, i) {
                                final l = _paginatedListings[i];
                                final slotsLeft = l.slotsTotal - l.slotsFilled;
                                final isSaved = _savedIds.contains(l.id);
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: figmaBlack,
                                              ),
                                            ),
                                            if (l.description != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                l.description!,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                              ),
                                            ],
                                            if (l.organizationName != null || l.location != null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                '${l.organizationName ?? ""}${l.organizationName != null && l.location != null ? " · " : ""}${l.location ?? ""}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                                        color: isSaved ? figmaOrange : Colors.grey,
                                        onPressed: () => _toggleSaved(l),
                                      ),
                                    ],
                                  ),
                                  if (l.skillsRequired.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: l.skillsRequired.take(3).map((skill) => Chip(
                                        label: Text(skill, style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: figmaOrange.withOpacity(0.1),
                                      )).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Slots: $slotsLeft / ${l.slotsTotal}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      if (slotsLeft > 0)
                                        FilledButton(
                                          onPressed: () => _apply(context, l.id),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: figmaOrange,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          ),
                                          child: const Text('Apply Now'),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text('Full', style: TextStyle(color: Colors.grey)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                                },
                              ),
                            ),
                          // Pagination controls
                          if (_totalPages > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_totalPages, (index) {
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
                      ),
          ),
        ],
      ),
    );
  }
}

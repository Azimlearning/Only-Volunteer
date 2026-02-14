import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/volunteer_listing.dart';
import '../../services/firestore_service.dart';

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
      if (mounted) setState(() { _listings = list; _lastDoc = result.lastDoc; _savedIds = saved.toSet(); _loading = false; });
    } else if (mounted) {
      setState(() { _listings = list; _lastDoc = result.lastDoc; _loading = false; });
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

  @override
  Widget build(BuildContext context) {
    final allSkills = _listings.expand((l) => l.skillsRequired).toSet().toList()..sort();
    if (allSkills.length > 8) allSkills.removeRange(8, allSkills.length);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Text('Skill:', style: TextStyle(fontWeight: FontWeight.w500)),
                    FilterChip(label: const Text('All'), selected: _skillFilter == null, onSelected: (_) => setState(() { _skillFilter = null; _load(); })),
                    ...allSkills.map((s) => FilterChip(
                      label: Text(s),
                      selected: _skillFilter == s,
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
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _listings.length + (_lastDoc != null ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _listings.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: _loadingMore ? const CircularProgressIndicator() : TextButton(onPressed: _loadMore, child: const Text('Load more')),
                              ),
                            );
                          }
                          final l = _listings[i];
                          final slotsLeft = l.slotsTotal - l.slotsFilled;
                          final isSaved = _savedIds.contains(l.id);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(l.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (l.description != null) Text(l.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  if (l.organizationName != null) Text('${l.organizationName} · ${l.location ?? ""}'),
                                  if (l.skillsRequired.isNotEmpty) Text('Skills: ${l.skillsRequired.join(", ")}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  Text('Slots: $slotsLeft / ${l.slotsTotal}'),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                                    onPressed: () => _toggleSaved(l),
                                  ),
                                  if (slotsLeft > 0)
                                    FilledButton(onPressed: () => _apply(context, l.id), child: const Text('Apply'))
                                  else
                                    const Text('Full'),
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
}

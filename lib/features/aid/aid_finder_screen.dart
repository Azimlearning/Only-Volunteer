import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/aid_resource.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../core/config.dart';

// Default reference: Kuala Lumpur
const _defaultLat = 3.1390;
const _defaultLng = 101.6869;

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0; // Earth radius in km
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

class AidFinderScreen extends StatefulWidget {
  const AidFinderScreen({super.key});

  @override
  State<AidFinderScreen> createState() => _AidFinderScreenState();
}

class _AidFinderScreenState extends State<AidFinderScreen> {
  final FirestoreService _firestore = FirestoreService();
  final GeminiService _gemini = GeminiService();
  final _searchController = TextEditingController();
  final _locationFilterController = TextEditingController();
  List<AidResource> _list = [];
  List<AidResource> _filtered = [];
  String? _category;
  String? _urgencyFilter;
  double? _maxDistanceKm;
  bool _loading = true;
  String? _contextualHint;

  static const _categories = ['Food', 'Clothing', 'Shelter', 'Medical', 'Education', 'Hygiene', 'Transport', 'All'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _firestore.getAidResources(category: _category, urgency: _urgencyFilter);
    if (mounted) {
      setState(() { _list = list; _loading = false; });
      _applyFilters();
    }
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    final loc = _locationFilterController.text.trim().toLowerCase();
    final maxKm = _maxDistanceKm;
    setState(() {
      var result = _list.where((r) {
        final matchText = q.isEmpty ||
            (r.title.toLowerCase().contains(q)) ||
            (r.description?.toLowerCase().contains(q) ?? false) ||
            (r.category?.toLowerCase().contains(q) ?? false);
        if (!matchText) return false;
        if (loc.isNotEmpty && (r.location?.toLowerCase().contains(loc) ?? false) == false) return false;
        if (maxKm != null && maxKm > 0 && (r.lat != null && r.lng != null)) {
          final km = _haversineKm(_defaultLat, _defaultLng, r.lat!, r.lng!);
          if (km > maxKm) return false;
        }
        return true;
      }).toList();
      // Sort by distance when distance filter is on
      if (maxKm != null && maxKm > 0) {
        result.sort((a, b) {
          final aKm = (a.lat != null && a.lng != null) ? _haversineKm(_defaultLat, _defaultLng, a.lat!, a.lng!) : double.infinity;
          final bKm = (b.lat != null && b.lng != null) ? _haversineKm(_defaultLat, _defaultLng, b.lat!, b.lng!) : double.infinity;
          return aKm.compareTo(bKm);
        });
      }
      _filtered = result;
    });
  }

  void _filter(String _) => _applyFilters();

  Future<void> _contextualSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _contextualHint = null);
    final hint = await _gemini.contextualSearch(query, 'volunteer');
    if (mounted) setState(() => _contextualHint = hint);
  }

  void _openSubmitAidRequest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SubmitAidRequestSheet(
        onSubmitted: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  Future<void> _openMaps(AidResource r) async {
    if (r.lat == null || r.lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${r.lat},${r.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openSubmitAidRequest,
        child: const Icon(Icons.add),
        tooltip: 'Submit aid request',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(hintText: 'Search resources...'),
                        onChanged: _filter,
                        onSubmitted: (_) => _contextualSearch(),
                      ),
                    ),
                    if (Config.geminiApiKey.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.auto_awesome),
                        onPressed: _contextualSearch,
                        tooltip: 'AI search tips',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationFilterController,
                  decoration: const InputDecoration(hintText: 'Filter by location', prefixIcon: Icon(Icons.location_on, size: 20)),
                  onChanged: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Max distance (km):', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    ChoiceChip(
                      label: const Text('Any'),
                      selected: _maxDistanceKm == null,
                      onSelected: (_) {
                        setState(() { _maxDistanceKm = null; _applyFilters(); });
                      },
                    ),
                    ...([10, 25, 50, 100, 200].map((km) => ChoiceChip(
                      label: Text('$km km'),
                      selected: _maxDistanceKm == km.toDouble(),
                      onSelected: (_) {
                        setState(() { _maxDistanceKm = km.toDouble(); _applyFilters(); });
                      },
                    ))),
                  ],
                ),
              ],
            ),
          ),
          if (_contextualHint != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_contextualHint!, style: TextStyle(color: Colors.grey[700]))),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.w500)),
                ..._categories.map((c) {
                  final isSelected = _category == (c == 'All' ? null : c);
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: FilterChip(
                      label: Text(c),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _category = c == 'All' ? null : c);
                        _load();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text('Urgency:', style: TextStyle(fontWeight: FontWeight.w500)),
                ...['low', 'medium', 'high', 'critical'].map((u) {
                  final isSelected = _urgencyFilter == u;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: FilterChip(
                      label: Text(u),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _urgencyFilter = isSelected ? null : u);
                        _load();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No resources found. Try adjusting filters.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final r = _filtered[i];
                          final distanceKm = (r.lat != null && r.lng != null)
                              ? _haversineKm(_defaultLat, _defaultLng, r.lat!, r.lng!)
                              : null;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(r.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (r.description != null) Text(r.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (r.category != null) _chip(r.category!),
                                      if (r.location != null) _chip(r.location!),
                                      if (distanceKm != null) _chip('${distanceKm.toStringAsFixed(1)} km'),
                                    ],
                                  ),
                                  Text('Urgency: ${r.urgency.name}', style: TextStyle(color: _urgencyColor(r.urgency), fontSize: 12)),
                                ],
                              ),
                              trailing: r.lat != null && r.lng != null
                                  ? IconButton(
                                      icon: const Icon(Icons.directions),
                                      onPressed: () => _openMaps(r),
                                      tooltip: 'Open in Maps',
                                    )
                                  : (r.quantity != null ? Text('${r.quantity} ${r.unit ?? ''}') : null),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(label: Text(label, style: const TextStyle(fontSize: 11)), padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
      );

  Color _urgencyColor(AidUrgency u) {
    switch (u) {
      case AidUrgency.critical:
        return Colors.red;
      case AidUrgency.high:
        return Colors.orange;
      case AidUrgency.medium:
        return Colors.blue;
      case AidUrgency.low:
        return Colors.grey;
    }
  }
}

class _SubmitAidRequestSheet extends StatefulWidget {
  const _SubmitAidRequestSheet({required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  State<_SubmitAidRequestSheet> createState() => _SubmitAidRequestSheetState();
}

class _SubmitAidRequestSheetState extends State<_SubmitAidRequestSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  String? _category;
  AidUrgency _urgency = AidUrgency.medium;
  bool _saving = false;

  static const _submitCategories = ['Food', 'Clothing', 'Shelter', 'Medical', 'Education', 'Hygiene', 'Transport'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title')));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() => _saving = true);
    try {
      final ref = FirebaseFirestore.instance.collection('aid_resources').doc();
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());
      final resource = AidResource(
        id: ref.id,
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        category: _category,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        urgency: _urgency,
        ownerId: uid,
        lat: lat,
        lng: lng,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await FirestoreService().addAidResource(resource);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aid request submitted')));
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
            const Text('Submit aid request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title *')),
            const SizedBox(height: 12),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _submitCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _latController, decoration: const InputDecoration(labelText: 'Latitude (optional)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _lngController, decoration: const InputDecoration(labelText: 'Longitude (optional)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AidUrgency>(
              value: _urgency,
              decoration: const InputDecoration(labelText: 'Urgency'),
              items: AidUrgency.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
              onChanged: (v) => setState(() => _urgency = v ?? AidUrgency.medium),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

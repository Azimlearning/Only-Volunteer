import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/aid_resource.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../core/config.dart';
import '../../core/theme.dart';

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
  Set<Marker> _mapMarkers = {};
  int _currentPage = 0;
  static const int _itemsPerPage = 6;
  static const _defaultCenter = LatLng(3.1390, 101.6869); // Kuala Lumpur

  static const _categories = ['All', 'Food', 'Clothes', 'Medical', 'Clothing', 'Shelter', 'Education', 'Hygiene', 'Transport'];

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
      _updateMapMarkers();
    }
  }

  void _updateMapMarkers() {
    // Note: google.maps.Marker is deprecated as of Feb 2024 in favor of AdvancedMarkerElement
    // The Flutter google_maps_flutter plugin will handle migration when ready
    // Current implementation will continue working for at least 12 months
    final markers = <Marker>{};
    for (final r in _filtered) {
      if (r.lat != null && r.lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId(r.id),
            position: LatLng(r.lat!, r.lng!),
            infoWindow: InfoWindow(
              title: r.title,
              snippet: r.location ?? r.category ?? '',
            ),
            onTap: () => _showAidDetails(r),
          ),
        );
      }
    }
    setState(() => _mapMarkers = markers);
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
      _currentPage = 0; // Reset to first page when filters change
      _updateMapMarkers();
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


  Future<void> _openMaps(AidResource r) async {
    if (r.lat == null || r.lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${r.lat},${r.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAidDetails(AidResource r) {
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
              Text(
                r.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: figmaBlack),
              ),
              if (r.description != null) ...[
                const SizedBox(height: 12),
                Text(r.description!, style: const TextStyle(height: 1.5)),
              ],
              if (r.location != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: figmaOrange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.location!, style: const TextStyle(fontWeight: FontWeight.w500))),
                  ],
                ),
              ],
              if (r.category != null) ...[
                const SizedBox(height: 12),
                Chip(label: Text(r.category!), backgroundColor: figmaOrange.withOpacity(0.1)),
              ],
              const SizedBox(height: 12),
              Text('Urgency: ${r.urgency.name}', style: TextStyle(color: _urgencyColor(r.urgency), fontSize: 14)),
              const SizedBox(height: 24),
              if (r.lat != null && r.lng != null)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openMaps(r);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Open in Maps'),
                  style: FilledButton.styleFrom(backgroundColor: figmaOrange),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationFilterController.dispose();
    super.dispose();
  }

  List<AidResource> get _paginatedItems {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filtered.length);
    return _filtered.sublist(start.clamp(0, _filtered.length), end);
  }

  int get _totalPages => (_filtered.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // About Aid Finder section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aid Finder',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find and request aid resources in your area',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          // Search and filters - compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.grey[50],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search resources...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: _filter,
                        onSubmitted: (_) => _contextualSearch(),
                      ),
                    ),
                    if (Config.geminiApiKey.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome),
                        onPressed: _contextualSearch,
                        tooltip: 'AI search tips',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _category == null,
                      selectedColor: figmaOrange.withOpacity(0.2),
                      checkmarkColor: figmaOrange,
                      onSelected: (_) {
                        setState(() => _category = null);
                        _load();
                      },
                    ),
                    ..._categories.where((c) => c != 'All').map((c) {
                      final isSelected = _category == c;
                      return FilterChip(
                        label: Text(c),
                        selected: isSelected,
                        selectedColor: figmaOrange.withOpacity(0.2),
                        checkmarkColor: figmaOrange,
                        onSelected: (_) {
                          setState(() => _category = isSelected ? null : c);
                          _load();
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          // Split view: Left list, Right map
          Expanded(
            child: Row(
              children: [
                // Left side - Paginated list (max 6 items)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(right: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No resources found',
                                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try adjusting filters',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: GridView.builder(
                                      padding: const EdgeInsets.all(20),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 20,
                                        mainAxisSpacing: 20,
                                        childAspectRatio: 0.82,
                                      ),
                                      itemCount: _paginatedItems.length,
                                      itemBuilder: (_, i) {
                                        final r = _paginatedItems[i];
                                        return _AidCard(resource: r, onTap: () => _showAidDetails(r));
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
                ),
                // Right side - Full map with padding
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 16,
                      right: 16,
                      bottom: 60, // Padding to align with pagination controls
                    ),
                    child: _mapMarkers.isEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No locations available',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add resources with location to see them on map',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: _defaultCenter,
                                zoom: 10,
                              ),
                              markers: _mapMarkers,
                              onMapCreated: (GoogleMapController controller) {},
                            ),
                          ),
                  ),
                ),
              ],
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

class _AidCard extends StatelessWidget {
  const _AidCard({required this.resource, required this.onTap});

  final AidResource resource;
  final VoidCallback onTap;

  String _getDistance() {
    if (resource.lat == null || resource.lng == null) return '';
    final distanceKm = _haversineKm(_defaultLat, _defaultLng, resource.lat!, resource.lng!);
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // Earth radius in km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  @override
  Widget build(BuildContext context) {
    final distance = _getDistance();
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              Expanded(
                flex: 5,
                child: resource.imageUrl != null && resource.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: resource.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: figmaOrange,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: 20, color: Colors.grey[400]),
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.image, size: 20, color: Colors.grey[400]),
                      ),
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                resource.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: figmaBlack,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Location with distance
              if (resource.location != null)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 11, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        distance.isNotEmpty
                            ? '$distance • ${resource.location!}'
                            : resource.location!,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 3),
              // Type (Category)
              if (resource.category != null)
                Text(
                  'Item Type: ${resource.category}',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              const SizedBox(height: 1),
              // Operating Hours
              Text(
                'Operating Hours: 10am - 10pm',
                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              ),
              const SizedBox(height: 1),
              // Eligibility
              Text(
                'Walk In',
                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              ),
              const Spacer(),
              // Action buttons row
              Row(
                children: [
                  // Message button
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message feature coming soon')),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: figmaOrange.withOpacity(0.3)),
                      ),
                      child: Icon(Icons.chat_bubble_outline, size: 14, color: figmaOrange),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Map/Location button
                  if (resource.lat != null && resource.lng != null)
                    IconButton(
                      onPressed: () async {
                        final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${resource.lat},${resource.lng}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: figmaOrange.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.map_outlined, size: 14, color: figmaOrange),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (resource.lat != null && resource.lng != null) const SizedBox(width: 4),
                  // Check Eligibility button
                  Expanded(
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: figmaOrange,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Check Eligibility',
                        style: TextStyle(fontSize: 10),
                      ),
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
}


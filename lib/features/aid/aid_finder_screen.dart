import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/aid_resource.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../services/aid_generation_service.dart';
import '../../services/location_service.dart';
import '../../core/config.dart';
import '../../core/theme.dart';

const String _keyLastAidGeneratedAt = 'lastAidGeneratedAt';

// Default reference: Kuala Lumpur
const _defaultLat = 3.1390;
const _defaultLng = 101.6869;

/// Approximate state/region centers for map when device GPS is unavailable.
LatLng _approxLatLngForLocation(String? location) {
  if (location == null || location.isEmpty) return const LatLng(_defaultLat, _defaultLng);
  final loc = location.toLowerCase();
  if (loc.contains('kuala lumpur')) return const LatLng(3.1390, 101.6869);
  if (loc.contains('selangor')) return const LatLng(3.0733, 101.5185);
  if (loc.contains('johor')) return const LatLng(1.4927, 103.7414);
  if (loc.contains('penang')) return const LatLng(5.4164, 100.3327);
  if (loc.contains('perak')) return const LatLng(4.5921, 101.0901);
  if (loc.contains('kelantan')) return const LatLng(6.1253, 102.2381);
  if (loc.contains('pahang')) return const LatLng(3.8126, 103.3256);
  if (loc.contains('sabah')) return const LatLng(5.9804, 116.0735);
  if (loc.contains('sarawak')) return const LatLng(1.5535, 110.3593);
  if (loc.contains('negeri sembilan')) return const LatLng(2.7258, 101.9424);
  if (loc.contains('malacca') || loc.contains('melaka')) return const LatLng(2.1896, 102.2501);
  if (loc.contains('kedah')) return const LatLng(6.1184, 100.3685);
  if (loc.contains('terengganu')) return const LatLng(5.3117, 103.1324);
  if (loc.contains('perlis')) return const LatLng(6.4443, 100.1984);
  return const LatLng(_defaultLat, _defaultLng);
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

  double? _userLat;
  double? _userLng;
  String? _userLocation;

  double get _effectiveLat => _userLat ?? _defaultLat;
  double get _effectiveLng => _userLng ?? _defaultLng;
  LatLng get _mapCenter => LatLng(_effectiveLat, _effectiveLng);

  static const _categories = ['All', 'Food', 'Clothing', 'Medical', 'Shelter', 'Education', 'Hygiene', 'Transport'];

  Timer? _refreshTimer;
  bool _generating = false;
  static const _genCooldown = Duration(days: 7);

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveUserLocation();
      _autoGenerate();
    });
    _refreshTimer = Timer.periodic(const Duration(days: 7), (_) {
      if (mounted) _autoGenerate();
    });
  }

  Future<void> _resolveUserLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _userLat = loc.lat;
        _userLng = loc.lng;
        _userLocation = loc.resolvedLocation;
      });
      _applyFilters();
      _updateMapMarkers();
      return;
    }
    final profileLoc = context.read<AuthNotifier>().appUser?.location;
    if (profileLoc != null && profileLoc.isNotEmpty && profileLoc != 'Not set' && mounted) {
      final approx = _approxLatLngForLocation(profileLoc);
      setState(() {
        _userLocation = profileLoc;
        _userLat = approx.latitude;
        _userLng = approx.longitude;
      });
      _applyFilters();
      _updateMapMarkers();
    }
  }

  /// Auto-generate only on first load or after 7 days (persisted across page refresh).
  Future<void> _autoGenerate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_keyLastAidGeneratedAt);
    if (lastMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (DateTime.now().difference(last) < _genCooldown) return;
    }
    await _generateAid(silent: true);
  }

  Future<void> _generateAid({bool silent = false}) async {
    if (_generating || !mounted) return;
    setState(() => _generating = true);
    try {
      final result = await AidGenerationService.generate(
        lat: _userLat,
        lng: _userLng,
        location: _userLocation,
      );
      if (result.ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyLastAidGeneratedAt, DateTime.now().millisecondsSinceEpoch);
      }
      if (mounted) {
        await _load();
        if (!silent && result.ok) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Found ${result.resourcesCreated} aid resources near you.'),
            backgroundColor: Colors.green,
          ));
        } else if (!silent && !result.ok) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: ${result.message}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // When "Clothing" is selected, fetch all and filter in _applyFilters (to include "Clothes")
    final categoryParam = (_category == null || _category == 'Clothing') ? null : _category;
    final list = await _firestore.getAidResources(category: categoryParam, urgency: _urgencyFilter);
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
        if (_category != null && _category != 'All') {
          if (_category == 'Clothing') {
            if (r.category != 'Clothing' && r.category != 'Clothes') return false;
          } else if (r.category != _category) {
            return false;
          }
        }
        if (loc.isNotEmpty && (r.location?.toLowerCase().contains(loc) ?? false) == false) return false;
        if (maxKm != null && maxKm > 0 && (r.lat != null && r.lng != null)) {
          final km = _haversineKm(_effectiveLat, _effectiveLng, r.lat!, r.lng!);
          if (km > maxKm) return false;
        }
        return true;
      }).toList();
      // Sort by distance when distance filter is on (or by default for "near you")
      result.sort((a, b) {
        final aKm = (a.lat != null && a.lng != null) ? _haversineKm(_effectiveLat, _effectiveLng, a.lat!, a.lng!) : double.infinity;
        final bKm = (b.lat != null && b.lng != null) ? _haversineKm(_effectiveLat, _effectiveLng, b.lat!, b.lng!) : double.infinity;
        return aKm.compareTo(bKm);
      });
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
              const SizedBox(height: 16),
              Text(
                r.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: figmaBlack),
              ),
              if (r.description != null) ...[
                const SizedBox(height: 12),
                Text(r.description!, style: const TextStyle(height: 1.5, fontSize: 14)),
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
                Chip(
                  label: Text(r.category!),
                  backgroundColor: figmaOrange.withOpacity(0.1),
                  labelStyle: TextStyle(color: figmaOrange, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Urgency: ',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  Text(
                    r.urgency.name.toUpperCase(),
                    style: TextStyle(
                      color: _urgencyColor(r.urgency),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Single source: Operating Hours (from resource)
              const SizedBox(height: 16),
              const Text(
                'Operating Hours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: figmaOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.operatingHoursDisplay,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              // Single source: Eligibility (from resource)
              const SizedBox(height: 16),
              const Text(
                'Eligibility',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user, size: 18, color: figmaPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.eligibilityDisplay,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              if (r.phone != null && r.phone!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Contact',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  r.phone!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
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
                  if (r.lat != null && r.lng != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openMaps(r);
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Open in Maps'),
                        style: FilledButton.styleFrom(
                          backgroundColor: figmaOrange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aid Finder',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find aid resources near you — powered by AI',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                if (context.watch<AuthNotifier>().appUser?.role == UserRole.ngo ||
                    context.watch<AuthNotifier>().appUser?.role == UserRole.admin) ...[
                  FilledButton(
                    onPressed: () => context.go('/create-aid'),
                    style: FilledButton.styleFrom(
                      backgroundColor: figmaOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                  const SizedBox(width: 8),
                ],
                FilledButton(
                  onPressed: _generating ? null : () => _generateAid(silent: false),
                  style: FilledButton.styleFrom(
                    backgroundColor: figmaOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_generating ? 'Refreshing…' : 'Refresh'),
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
                                    child: _TwoColumnAidList(
                                      items: _paginatedItems,
                                      refLat: _effectiveLat,
                                      refLng: _effectiveLng,
                                      onTap: _showAidDetails,
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
                              initialCameraPosition: CameraPosition(
                                target: _mapCenter,
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

// Card spacing tokens (align with card_ui_recommendations.md)
const _kSpace4 = 4.0;
const _kSpace8 = 8.0;
const _kSpace12 = 12.0;
const _kRadiusSm = 8.0;
const _kRadiusMd = 12.0;
const _kRadiusLg = 16.0;

class _AidCard extends StatelessWidget {
  const _AidCard({
    required this.resource,
    required this.refLat,
    required this.refLng,
    required this.onTap,
  });

  final AidResource resource;
  final double refLat;
  final double refLng;
  final VoidCallback onTap;

  String _getDistance() {
    if (resource.lat == null || resource.lng == null) return '';
    final distanceKm = _haversineKm(refLat, refLng, resource.lat!, resource.lng!);
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
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
    final hasMap = resource.lat != null && resource.lng != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadiusLg),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kRadiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, color: figmaOrange),
            Padding(
              padding: const EdgeInsets.fromLTRB(_kSpace12, _kSpace12, _kSpace12, _kSpace8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          resource.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: figmaBlack,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distance.isNotEmpty) ...[
                        const SizedBox(width: _kSpace4),
                        _PillBadge(
                          label: distance,
                          icon: Icons.near_me_rounded,
                          bg: const Color(0xFFF5F5F5),
                          fg: Colors.grey[700]!,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: _kSpace8),
                  if (resource.location != null)
                    _MetaRow(icon: Icons.location_on_outlined, text: resource.location!),
                  const SizedBox(height: _kSpace4),
                  _MetaRow(icon: Icons.access_time_rounded, text: resource.operatingHoursDisplay),
                  const SizedBox(height: _kSpace8),
                  Wrap(
                    spacing: _kSpace4,
                    runSpacing: _kSpace4,
                    children: [
                      if (resource.category != null)
                        _PillBadge(
                          label: resource.category!,
                          icon: Icons.category_outlined,
                          bg: const Color(0xFFE3F2FD),
                          fg: const Color(0xFF1565C0),
                        ),
                      _PillBadge(
                        label: 'Walk In',
                        icon: Icons.how_to_reg_outlined,
                        bg: const Color(0xFFE8F5E9),
                        fg: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _kSpace12, vertical: _kSpace8),
              child: Row(
                children: [
                  _GhostIconBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message feature coming soon')),
                    ),
                  ),
                  const SizedBox(width: _kSpace8),
                  if (hasMap)
                    _GhostIconBtn(
                      icon: Icons.map_outlined,
                      onTap: () async {
                        final uri = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=${resource.lat},${resource.lng}',
                        );
                        if (await canLaunchUrl(uri)) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  if (hasMap) const SizedBox(width: _kSpace8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: figmaOrange,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_kRadiusMd),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Check Eligibility',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _kSpace8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: _kSpace4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _GhostIconBtn extends StatelessWidget {
  const _GhostIconBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_kRadiusSm),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(_kRadiusSm),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, size: 16, color: figmaOrange),
      ),
    );
  }
}

class _TwoColumnAidList extends StatelessWidget {
  const _TwoColumnAidList({
    required this.items,
    required this.refLat,
    required this.refLng,
    required this.onTap,
  });
  final List<AidResource> items;
  final double refLat;
  final double refLng;
  final void Function(AidResource) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: (items.length / 2).ceil(),
      itemBuilder: (_, rowIndex) {
        final leftIndex = rowIndex * 2;
        final rightIndex = leftIndex + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: _kSpace12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AidCard(
                  resource: items[leftIndex],
                  refLat: refLat,
                  refLng: refLng,
                  onTap: () => onTap(items[leftIndex]),
                ),
              ),
              const SizedBox(width: _kSpace12),
              Expanded(
                child: rightIndex < items.length
                    ? _AidCard(
                        resource: items[rightIndex],
                        refLat: refLat,
                        refLng: refLng,
                        onTap: () => onTap(items[rightIndex]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}


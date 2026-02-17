import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/volunteer_listing.dart';
import '../../services/firestore_service.dart';

class OpportunitiesMapScreen extends StatefulWidget {
  const OpportunitiesMapScreen({super.key});

  @override
  State<OpportunitiesMapScreen> createState() => _OpportunitiesMapScreenState();
}

class _OpportunitiesMapScreenState extends State<OpportunitiesMapScreen> {
  final FirestoreService _firestore = FirestoreService();
  Set<Marker> _markers = {};
  static const _defaultCenter = LatLng(4.2105, 101.9758);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Note: google.maps.Marker is deprecated as of Feb 2024 in favor of AdvancedMarkerElement
    // The Flutter google_maps_flutter plugin will handle migration when ready
    // Current implementation will continue working for at least 12 months
    final list = await _firestore.getVolunteerListings();
    final markers = <Marker>{};
    for (final l in list) {
      if (l.lat != null && l.lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId(l.id),
            position: LatLng(l.lat!, l.lng!),
            infoWindow: InfoWindow(title: l.title, snippet: l.location),
            onTap: () => _showListingSheet(l),
          ),
        );
      }
    }
    if (mounted) setState(() { _markers = markers; });
  }

  void _showListingSheet(VolunteerListing listing) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
            if (listing.organizationName != null) Text('${listing.organizationName}', style: TextStyle(color: Colors.grey[600])),
            if (listing.location != null) Text(listing.location!, style: TextStyle(color: Colors.grey[700])),
            if (listing.startTime != null) Text('Start: ${listing.startTime}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    if (listing.lat != null && listing.lng != null) {
                      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${listing.lat},${listing.lng}');
                      if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Open in Maps'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Volunteer opportunities on map. Tap a pin for details.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: _markers.isEmpty
              ? const Center(
                  child: Text(
                    'No locations available. Add volunteer listings with lat/lng to see them on the map.',
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: const CameraPosition(target: _defaultCenter, zoom: 6),
                  markers: _markers,
                ),
        ),
      ],
    );
  }
}

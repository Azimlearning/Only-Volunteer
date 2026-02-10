import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/volunteer_listing.dart';
import '../../services/firestore_service.dart';

class OpportunitiesMapScreen extends StatefulWidget {
  const OpportunitiesMapScreen({super.key});

  @override
  State<OpportunitiesMapScreen> createState() => _OpportunitiesMapScreenState();
}

class _OpportunitiesMapScreenState extends State<OpportunitiesMapScreen> {
  final FirestoreService _firestore = FirestoreService();
  List<VolunteerListing> _listings = [];
  Set<Marker> _markers = {};
  static const _defaultCenter = LatLng(4.2105, 101.9758); // Malaysia

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _firestore.getVolunteerListings();
    final markers = <Marker>{};
    for (final l in list) {
      if (l.lat != null && l.lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId(l.id),
            position: LatLng(l.lat!, l.lng!),
            infoWindow: InfoWindow(title: l.title, snippet: l.location),
          ),
        );
      }
    }
    if (mounted) setState(() { _listings = list; _markers = markers; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Volunteer opportunities on map',
            style: Theme.of(context).textTheme.titleLarge,
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

import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerListing {
  VolunteerListing({
    required this.id,
    required this.title,
    this.description,
    this.organizationId,
    this.organizationName,
    this.skillsRequired = const [],
    this.location,
    this.lat,
    this.lng,
    this.startTime,
    this.endTime,
    this.slotsTotal = 0,
    this.slotsFilled = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? organizationId;
  final String? organizationName;
  final List<String> skillsRequired;
  final String? location;
  final double? lat;
  final double? lng;
  final DateTime? startTime;
  final DateTime? endTime;
  final int slotsTotal;
  final int slotsFilled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VolunteerListing.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return VolunteerListing(
      id: doc.id,
      title: m['title'] as String? ?? '',
      description: m['description'] as String?,
      organizationId: m['organizationId'] as String?,
      organizationName: m['organizationName'] as String?,
      skillsRequired: List<String>.from(m['skillsRequired'] ?? []),
      location: m['location'] as String?,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      startTime: (m['startTime'] as Timestamp?)?.toDate(),
      endTime: (m['endTime'] as Timestamp?)?.toDate(),
      slotsTotal: (m['slotsTotal'] as num?)?.toInt() ?? 0,
      slotsFilled: (m['slotsFilled'] as num?)?.toInt() ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'skillsRequired': skillsRequired,
      'location': location,
      'lat': lat,
      'lng': lng,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'slotsTotal': slotsTotal,
      'slotsFilled': slotsFilled,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

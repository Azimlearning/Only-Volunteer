import 'package:cloud_firestore/cloud_firestore.dart';

/// Urgency level for aid requests.
enum AidUrgency { low, medium, high, critical }

class AidResource {
  AidResource({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.location,
    this.urgency = AidUrgency.medium,
    this.quantity,
    this.unit,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
    this.lat,
    this.lng,
  });

  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? location;
  final AidUrgency urgency;
  final double? lat;
  final double? lng;
  final int? quantity;
  final String? unit;
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AidResource.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return AidResource(
      id: doc.id,
      title: m['title'] as String? ?? '',
      description: m['description'] as String?,
      category: m['category'] as String?,
      location: m['location'] as String?,
      urgency: _urgencyFrom(m['urgency']),
      quantity: (m['quantity'] as num?)?.toInt(),
      unit: m['unit'] as String?,
      ownerId: m['ownerId'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
    );
  }

  static AidUrgency _urgencyFrom(dynamic v) {
    if (v == 'critical') return AidUrgency.critical;
    if (v == 'high') return AidUrgency.high;
    if (v == 'low') return AidUrgency.low;
    return AidUrgency.medium;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'urgency': urgency.name,
      'quantity': quantity,
      'unit': unit,
      'ownerId': ownerId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lat': lat,
      'lng': lng,
    };
  }
}

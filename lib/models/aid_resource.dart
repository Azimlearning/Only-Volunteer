import 'package:cloud_firestore/cloud_firestore.dart';

class AidResource {
  AidResource({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.location,
    this.quantity,
    this.unit,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? location;
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
      quantity: (m['quantity'] as num?)?.toInt(),
      unit: m['unit'] as String?,
      ownerId: m['ownerId'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'quantity': quantity,
      'unit': unit,
      'ownerId': ownerId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

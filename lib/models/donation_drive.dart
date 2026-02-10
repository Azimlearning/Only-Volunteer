import 'package:cloud_firestore/cloud_firestore.dart';

class DonationDrive {
  DonationDrive({
    required this.id,
    required this.title,
    this.description,
    this.ngoId,
    this.ngoName,
    this.startDate,
    this.endDate,
    this.goalAmount,
    this.raisedAmount = 0,
    this.items = const [],
    this.location,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? ngoId;
  final String? ngoName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? goalAmount;
  final double raisedAmount;
  final List<String> items;
  final String? location;
  final DateTime? createdAt;

  factory DonationDrive.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return DonationDrive(
      id: doc.id,
      title: m['title'] as String? ?? '',
      description: m['description'] as String?,
      ngoId: m['ngoId'] as String?,
      ngoName: m['ngoName'] as String?,
      startDate: (m['startDate'] as Timestamp?)?.toDate(),
      endDate: (m['endDate'] as Timestamp?)?.toDate(),
      goalAmount: (m['goalAmount'] as num?)?.toDouble(),
      raisedAmount: (m['raisedAmount'] as num?)?.toDouble() ?? 0,
      items: List<String>.from(m['items'] ?? []),
      location: m['location'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'goalAmount': goalAmount,
      'raisedAmount': raisedAmount,
      'items': items,
      'location': location,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

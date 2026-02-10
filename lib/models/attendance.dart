import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  Attendance({
    required this.id,
    required this.listingId,
    required this.userId,
    this.checkInAt,
    this.checkOutAt,
    this.hours,
    this.verified = false,
    this.createdAt,
  });

  final String id;
  final String listingId;
  final String userId;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final double? hours;
  final bool verified;
  final DateTime? createdAt;

  factory Attendance.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return Attendance(
      id: doc.id,
      listingId: m['listingId'] as String? ?? '',
      userId: m['userId'] as String? ?? '',
      checkInAt: (m['checkInAt'] as Timestamp?)?.toDate(),
      checkOutAt: (m['checkOutAt'] as Timestamp?)?.toDate(),
      hours: (m['hours'] as num?)?.toDouble(),
      verified: m['verified'] as bool? ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'userId': userId,
      'checkInAt': checkInAt != null ? Timestamp.fromDate(checkInAt!) : null,
      'checkOutAt': checkOutAt != null ? Timestamp.fromDate(checkOutAt!) : null,
      'hours': hours,
      'verified': verified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

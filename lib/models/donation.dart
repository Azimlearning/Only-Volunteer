import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  Donation({
    required this.id,
    required this.driveId,
    required this.userId,
    required this.amount,
    this.driveTitle,
    this.paymentIntentId,
    this.createdAt,
  });

  final String id;
  final String driveId;
  final String userId;
  final double amount;
  final String? driveTitle;
  final String? paymentIntentId;
  final DateTime? createdAt;

  factory Donation.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return Donation(
      id: doc.id,
      driveId: m['driveId'] as String? ?? '',
      userId: m['userId'] as String? ?? '',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      driveTitle: m['driveTitle'] as String?,
      paymentIntentId: m['paymentIntentId'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driveId': driveId,
      'userId': userId,
      'amount': amount,
      'driveTitle': driveTitle,
      'paymentIntentId': paymentIntentId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

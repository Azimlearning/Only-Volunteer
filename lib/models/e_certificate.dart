import 'package:cloud_firestore/cloud_firestore.dart';

class ECertificate {
  ECertificate({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.listingTitle,
    this.organizationName,
    this.hours,
    this.issuedAt,
    this.verificationCode,
    this.downloadUrl,
  });

  final String id;
  final String userId;
  final String listingId;
  final String listingTitle;
  final String? organizationName;
  final double? hours;
  final DateTime? issuedAt;
  final String? verificationCode;
  final String? downloadUrl;

  factory ECertificate.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return ECertificate(
      id: doc.id,
      userId: m['userId'] as String? ?? '',
      listingId: m['listingId'] as String? ?? '',
      listingTitle: m['listingTitle'] as String? ?? '',
      organizationName: m['organizationName'] as String?,
      hours: (m['hours'] as num?)?.toDouble(),
      issuedAt: (m['issuedAt'] as Timestamp?)?.toDate(),
      verificationCode: m['verificationCode'] as String?,
      downloadUrl: m['downloadUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'organizationName': organizationName,
      'hours': hours,
      'issuedAt': issuedAt != null ? Timestamp.fromDate(issuedAt!) : FieldValue.serverTimestamp(),
      'verificationCode': verificationCode,
      'downloadUrl': downloadUrl,
    };
  }
}

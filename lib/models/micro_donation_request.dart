import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a micro-donation request (e.g. "I need a mattress").
enum MicroDonationStatus { open, fulfilled, cancelled }

/// Requester type: individual or organization.
enum MicroDonationRequesterType { individual, ngo }

/// Category for micro-donation (specific need).
enum MicroDonationCategory {
  specific_food,
  furniture,
  appliances,
  medical,
  education,
  other,
}

class MicroDonationRequest {
  MicroDonationRequest({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.requesterId,
    this.requesterName,
    this.requesterType = MicroDonationRequesterType.individual,
    this.itemNeeded,
    this.quantity = 1,
    this.urgency = 'medium',
    this.location,
    this.lat,
    this.lng,
    this.status = MicroDonationStatus.open,
    this.fulfilledBy,
    this.createdAt,
    this.updatedAt,
    this.qrCodeUrl,
    this.bank,
    this.accountName,
    this.accountNumber,
  });

  final String id;
  final String title;
  final String? description;
  final MicroDonationCategory category;
  final String requesterId;
  final String? requesterName;
  final MicroDonationRequesterType requesterType;
  final String? itemNeeded;
  final int quantity;
  final String urgency; // low, medium, high, critical
  final String? location;
  final double? lat;
  final double? lng;
  final MicroDonationStatus status;
  final String? fulfilledBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? qrCodeUrl;
  final String? bank;
  final String? accountName;
  final String? accountNumber;

  factory MicroDonationRequest.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return MicroDonationRequest(
      id: doc.id,
      title: m['title'] as String? ?? '',
      description: m['description'] as String?,
      category: _categoryFrom(m['category']),
      requesterId: m['requesterId'] as String? ?? '',
      requesterName: m['requesterName'] as String?,
      requesterType: m['requesterType'] == 'ngo'
          ? MicroDonationRequesterType.ngo
          : MicroDonationRequesterType.individual,
      itemNeeded: m['itemNeeded'] as String?,
      quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      urgency: m['urgency'] as String? ?? 'medium',
      location: m['location'] as String?,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      status: _statusFrom(m['status']),
      fulfilledBy: m['fulfilledBy'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      qrCodeUrl: m['qrCodeUrl'] as String?,
      bank: m['bank'] as String?,
      accountName: m['accountName'] as String?,
      accountNumber: m['accountNumber'] as String?,
    );
  }

  static MicroDonationCategory _categoryFrom(dynamic v) {
    if (v == null) return MicroDonationCategory.other;
    final s = v.toString();
    if (s == 'specific_food') return MicroDonationCategory.specific_food;
    if (s == 'furniture') return MicroDonationCategory.furniture;
    if (s == 'appliances') return MicroDonationCategory.appliances;
    if (s == 'medical') return MicroDonationCategory.medical;
    if (s == 'education') return MicroDonationCategory.education;
    return MicroDonationCategory.other;
  }

  static MicroDonationStatus _statusFrom(dynamic v) {
    if (v == 'fulfilled') return MicroDonationStatus.fulfilled;
    if (v == 'cancelled') return MicroDonationStatus.cancelled;
    return MicroDonationStatus.open;
  }

  String get categoryName {
    switch (category) {
      case MicroDonationCategory.specific_food:
        return 'Specific Food';
      case MicroDonationCategory.furniture:
        return 'Furniture';
      case MicroDonationCategory.appliances:
        return 'Appliances';
      case MicroDonationCategory.medical:
        return 'Medical';
      case MicroDonationCategory.education:
        return 'Education';
      case MicroDonationCategory.other:
        return 'Other';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterType': requesterType.name,
      'itemNeeded': itemNeeded,
      'quantity': quantity,
      'urgency': urgency,
      'location': location,
      'lat': lat,
      'lng': lng,
      'status': status.name,
      'fulfilledBy': fulfilledBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'qrCodeUrl': qrCodeUrl,
      'bank': bank,
      'accountName': accountName,
      'accountNumber': accountNumber,
    };
  }
}

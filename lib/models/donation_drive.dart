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
    this.category,
    this.bannerUrl,
    this.createdAt,
    this.contactEmail,
    this.contactPhone,
    this.whatsappNumber,
    this.address,
    this.lat,
    this.lng,
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
  final String? category;
  final String? bannerUrl;
  final DateTime? createdAt;
  final String? contactEmail;
  final String? contactPhone;
  final String? whatsappNumber;
  final String? address;
  final double? lat;
  final double? lng;

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
      category: m['category'] as String?,
      bannerUrl: m['bannerUrl'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      contactEmail: m['contactEmail'] as String?,
      contactPhone: m['contactPhone'] as String?,
      whatsappNumber: m['whatsappNumber'] as String?,
      address: m['address'] as String?,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
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
      'category': category,
      'bannerUrl': bannerUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'whatsappNumber': whatsappNumber,
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}

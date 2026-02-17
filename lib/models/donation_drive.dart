import 'package:cloud_firestore/cloud_firestore.dart';

/// Official campaign category for donation drives (NGO-only).
enum CampaignCategory {
  disasterRelief,
  medicalHealth,
  communityInfrastructure,
  sustainedSupport,
}

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
    this.campaignCategory,
    this.beneficiaryGroup,
    this.bannerUrl,
    this.createdAt,
    this.contactEmail,
    this.contactPhone,
    this.whatsappNumber,
    this.address,
    this.lat,
    this.lng,
    this.qrCodeUrl,
    this.bank,
    this.accountName,
    this.accountNumber,
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
  final CampaignCategory? campaignCategory;
  final String? beneficiaryGroup;
  final String? bannerUrl;
  final DateTime? createdAt;
  final String? contactEmail;
  final String? contactPhone;
  final String? whatsappNumber;
  final String? address;
  final double? lat;
  final double? lng;
  final String? qrCodeUrl;
  final String? bank;
  final String? accountName;
  final String? accountNumber;

  static CampaignCategory? _campaignCategoryFrom(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s == 'disasterRelief') return CampaignCategory.disasterRelief;
    if (s == 'medicalHealth') return CampaignCategory.medicalHealth;
    if (s == 'communityInfrastructure') return CampaignCategory.communityInfrastructure;
    if (s == 'sustainedSupport') return CampaignCategory.sustainedSupport;
    return null;
  }

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
      campaignCategory: _campaignCategoryFrom(m['campaignCategory']),
      beneficiaryGroup: m['beneficiaryGroup'] as String?,
      bannerUrl: m['bannerUrl'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      contactEmail: m['contactEmail'] as String?,
      contactPhone: m['contactPhone'] as String?,
      whatsappNumber: m['whatsappNumber'] as String?,
      address: m['address'] as String?,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      qrCodeUrl: m['qrCodeUrl'] as String?,
      bank: m['bank'] as String?,
      accountName: m['accountName'] as String?,
      accountNumber: m['accountNumber'] as String?,
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
      'campaignCategory': campaignCategory?.name,
      'beneficiaryGroup': beneficiaryGroup,
      'bannerUrl': bannerUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'whatsappNumber': whatsappNumber,
      'address': address,
      'lat': lat,
      'lng': lng,
      'qrCodeUrl': qrCodeUrl,
      'bank': bank,
      'accountName': accountName,
      'accountNumber': accountNumber,
    };
  }
}

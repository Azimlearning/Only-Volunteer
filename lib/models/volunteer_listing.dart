import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestVisibility { public, private }

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
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.visibility = RequestVisibility.public,
    this.isRegisteredWithJKM,
    this.isB40Household,
    this.acceptsMonetaryDonation = false,
    this.monetaryGoal,
    this.monetaryRaised = 0,
    this.tags = const [],
    this.contactEmail,
    this.contactPhone,
    this.qrCodeUrl,
    this.bank,
    this.accountName,
    this.accountNumber,
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
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RequestVisibility visibility;
  final bool? isRegisteredWithJKM;
  final bool? isB40Household;
  final bool? acceptsMonetaryDonation;
  final double? monetaryGoal;
  final double? monetaryRaised;
  /// AI-generated tags for matching (e.g. "Requires Car", "Weekend Only", "Graphic Design").
  final List<String> tags;
  final String? contactEmail;
  final String? contactPhone;
  final String? qrCodeUrl;
  final String? bank;
  final String? accountName;
  final String? accountNumber;

  factory VolunteerListing.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    final visibilityStr = m['visibility'] as String? ?? 'public';
    final visibility = visibilityStr == 'private' ? RequestVisibility.private : RequestVisibility.public;
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
      imageUrl: m['imageUrl'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      visibility: visibility,
      isRegisteredWithJKM: m['isRegisteredWithJKM'] as bool?,
      isB40Household: m['isB40Household'] as bool?,
      acceptsMonetaryDonation: m['acceptsMonetaryDonation'] as bool? ?? false,
      monetaryGoal: (m['monetaryGoal'] as num?)?.toDouble(),
      monetaryRaised: (m['monetaryRaised'] as num?)?.toDouble() ?? 0,
      tags: List<String>.from(m['tags'] ?? []),
      contactEmail: m['contactEmail'] as String?,
      contactPhone: m['contactPhone'] as String?,
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
      'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'visibility': visibility.name,
      'isRegisteredWithJKM': isRegisteredWithJKM,
      'isB40Household': isB40Household,
      'acceptsMonetaryDonation': acceptsMonetaryDonation,
      'monetaryGoal': monetaryGoal,
      'monetaryRaised': monetaryRaised ?? 0,
      'tags': tags,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'qrCodeUrl': qrCodeUrl,
      'bank': bank,
      'accountName': accountName,
      'accountNumber': accountNumber,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aid_resource.dart';
import '../models/alert.dart';
import '../models/donation_drive.dart';
import '../models/feed_post.dart';
import '../models/volunteer_listing.dart';
import '../models/micro_donation_request.dart';
import '../models/attendance.dart';
import '../models/e_certificate.dart';
import '../models/donation.dart';
import 'firestore_service.dart';

/// Seeds the database with test data for development/demo.
class SeedDataService {
  SeedDataService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final FirestoreService _firestore = FirestoreService();

  Future<int> seedAll({String? systemUserId}) async {
    // Ensure user has developer role for seed operations
    if (systemUserId != null) {
      try {
        final userDoc = await _db.collection('users').doc(systemUserId).get();
        if (!userDoc.exists || userDoc.data()?['role'] == null) {
          await _db.collection('users').doc(systemUserId).set({
            'role': 'developer',
          }, SetOptions(merge: true));
        } else {
          final currentRole = userDoc.data()?['role'] as String?;
          if (currentRole != 'admin' && currentRole != 'developer') {
            await _db.collection('users').doc(systemUserId).update({
              'role': 'developer',
            });
          }
        }
      } catch (e) {
        // If setting role fails, continue anyway - rules might allow it
        print('Warning: Could not set developer role: $e');
      }
    }
    
    var count = 0;
    count += await seedDonationDrives(systemUserId);
    count += await seedVolunteerOpportunities(systemUserId);
    count += await seedAidResources(systemUserId);
    count += await seedMicroDonations(systemUserId);
    count += await seedAttendances(systemUserId);
    count += await seedECertificates(systemUserId);
    count += await seedDonations(systemUserId);
    count += await seedAlerts(systemUserId);
    count += await seedFeedPosts(systemUserId);
    return count;
  }

  Future<void> clearAllSeedData() async {
    // Clear all collections that are seeded for core pages
    final collections = [
      'donation_drives',
      'volunteer_listings',
      'aid_resources',
      'micro_donations',
      'attendances',
      'e_certificates',
      'donations',
      'alerts',
      'feed_posts',
    ];
    for (final collectionName in collections) {
      final snapshot = await _db.collection(collectionName).get();
      if (snapshot.docs.isEmpty) continue;
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<int> seedDonationDrives(String? ngoId) async {
    // Official Campaigns - 5 drives across 4 campaign categories with images
    final drives = [
      // Disaster Relief
      {
        'title': 'Flood Relief Fund - Pahang 2026',
        'description': 'Heavy flooding has displaced thousands of families in Pahang. Your donation will provide emergency shelter, food supplies, clean water, and medical assistance to affected communities.',
        'goalAmount': 50000.0,
        'raisedAmount': 32750.0,
        'ngoName': 'Malaysian Red Crescent',
        'campaignCategory': CampaignCategory.disasterRelief,
        'beneficiaryGroup': '500 Flood Victims in Pahang',
        'location': 'Kuantan, Pahang',
        'contactEmail': 'relief@redcrescent.my',
        'contactPhone': '+60123456789',
        'whatsappNumber': '60123456789',
        'address': 'Jalan Hospital, 25100 Kuantan, Pahang',
        'lat': 3.8245,
        'lng': 103.3232,
        'bannerUrl': 'https://images.unsplash.com/photo-1593113598332-cd288d3dbeb2?w=800&h=400&fit=crop',
        'startDate': DateTime.now().subtract(const Duration(days: 10)),
        'endDate': DateTime.now().add(const Duration(days: 20)),
      },
      {
        'title': 'Fire Victims Support - Selangor',
        'description': 'Emergency relief for families affected by recent fires. Funds will provide temporary housing, essential supplies, and rebuilding support.',
        'goalAmount': 35000.0,
        'raisedAmount': 18900.0,
        'ngoName': 'Malaysian Red Crescent',
        'campaignCategory': CampaignCategory.disasterRelief,
        'beneficiaryGroup': '200 Fire Victims in Selangor',
        'location': 'Shah Alam, Selangor',
        'contactEmail': 'relief@redcrescent.my',
        'contactPhone': '+60123456790',
        'whatsappNumber': '60123456790',
        'address': 'Dewan Seri Selangor, Shah Alam',
        'lat': 3.0733,
        'lng': 101.5185,
        'bannerUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&h=400&fit=crop',
        'startDate': DateTime.now().subtract(const Duration(days: 5)),
        'endDate': DateTime.now().add(const Duration(days: 25)),
      },
      // Medical & Health
      {
        'title': 'Medical Supplies for Rural Clinics',
        'description': 'Provide essential medical supplies to rural clinics in Sarawak. Your donation saves lives.',
        'goalAmount': 40000.0,
        'raisedAmount': 28000.0,
        'ngoName': 'Malaysian Medical Relief Society',
        'campaignCategory': CampaignCategory.medicalHealth,
        'beneficiaryGroup': '15 Rural Clinics in Sarawak',
        'location': 'Kuching, Sarawak',
        'contactEmail': 'donate@mercy.org.my',
        'contactPhone': '+6082423111',
        'whatsappNumber': '6082423111',
        'address': 'Jalan Tabuan, 93150 Kuching, Sarawak',
        'lat': 1.5535,
        'lng': 110.3593,
        'bannerUrl': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=800&h=400&fit=crop',
        'startDate': DateTime.now().subtract(const Duration(days: 15)),
        'endDate': DateTime.now().add(const Duration(days: 45)),
      },
      {
        'title': 'Blood Donation Campaign - Nationwide',
        'description': 'Join our nationwide blood donation drive. Every donation can save up to 3 lives. Multiple locations available.',
        'goalAmount': 0.0, // No monetary goal, just participation
        'raisedAmount': 0.0,
        'ngoName': 'National Blood Centre',
        'campaignCategory': CampaignCategory.medicalHealth,
        'beneficiaryGroup': 'Patients Nationwide',
        'location': 'Multiple Locations',
        'contactEmail': 'blood@nbc.gov.my',
        'contactPhone': '+60326933333',
        'whatsappNumber': '60326933333',
        'address': 'Jalan Tun Razak, 50400 Kuala Lumpur',
        'lat': 3.1390,
        'lng': 101.6869,
        'bannerUrl': 'https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=800&h=400&fit=crop',
        'startDate': DateTime.now(),
        'endDate': DateTime.now().add(const Duration(days: 30)),
      },
      // Community Infrastructure
      {
        'title': 'Mosque Renovation Project - Kelantan',
        'description': 'Help renovate the community mosque that serves 500 families. Funds will go toward repairs, new facilities, and accessibility improvements.',
        'goalAmount': 60000.0,
        'raisedAmount': 35000.0,
        'ngoName': 'Yayasan Dakwah Islamiah Malaysia',
        'campaignCategory': CampaignCategory.communityInfrastructure,
        'beneficiaryGroup': '500 Families in Kelantan',
        'location': 'Kota Bharu, Kelantan',
        'contactEmail': 'info@ydim.org.my',
        'contactPhone': '+6097441234',
        'whatsappNumber': '6097441234',
        'address': 'Jalan Sultan Ibrahim, 15000 Kota Bharu',
        'lat': 6.1252,
        'lng': 102.2381,
        'bannerUrl': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&h=400&fit=crop',
        'startDate': DateTime.now().subtract(const Duration(days: 20)),
        'endDate': DateTime.now().add(const Duration(days: 60)),
      },
      // Sustained Support
      {
        'title': 'Education Sponsorship Fund - Orang Asli Children',
        'description': 'Support indigenous children\'s education by providing school supplies, uniforms, textbooks, and scholarships for sustained learning.',
        'goalAmount': 25000.0,
        'raisedAmount': 18900.0,
        'ngoName': 'UNICEF Malaysia',
        'campaignCategory': CampaignCategory.sustainedSupport,
        'beneficiaryGroup': '100 Orang Asli Children',
        'location': 'Gua Musang, Kelantan',
        'contactEmail': 'education@unicef.my',
        'contactPhone': '+60198765432',
        'whatsappNumber': '60198765432',
        'address': 'Kampung Pulai, Gua Musang, Kelantan',
        'lat': 4.8845,
        'lng': 101.9683,
        'bannerUrl': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=400&fit=crop',
        'startDate': DateTime.now().subtract(const Duration(days: 30)),
        'endDate': DateTime.now().add(const Duration(days: 90)),
      },
      {
        'title': 'Orphanage Operational Support - Selangor',
        'description': 'Monthly operational support for orphanage housing 50 children. Covers food, education, healthcare, and daily necessities.',
        'goalAmount': 15000.0,
        'raisedAmount': 8500.0,
        'ngoName': 'Pertubuhan Kebajikan Anak Yatim Malaysia',
        'campaignCategory': CampaignCategory.sustainedSupport,
        'beneficiaryGroup': '50 Orphaned Children',
        'location': 'Petaling Jaya, Selangor',
        'contactEmail': 'support@pkaym.org.my',
        'contactPhone': '+60379541234',
        'whatsappNumber': '60379541234',
        'address': 'Jalan SS2/24, 47300 Petaling Jaya',
        'lat': 3.1068,
        'lng': 101.6057,
        'bannerUrl': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=800&h=400&fit=crop',
        'startDate': DateTime.now().subtract(const Duration(days: 7)),
        'endDate': DateTime.now().add(const Duration(days: 23)),
      },
    ];

    for (final d in drives) {
      final ref = _db.collection('donation_drives').doc();
      final drive = DonationDrive(
        id: ref.id,
        title: d['title'] as String,
        description: d['description'] as String,
        ngoId: ngoId,
        ngoName: d['ngoName'] as String,
        goalAmount: d['goalAmount'] as double,
        raisedAmount: d['raisedAmount'] as double,
        campaignCategory: d['campaignCategory'] as CampaignCategory,
        beneficiaryGroup: d['beneficiaryGroup'] as String,
        location: d['location'] as String,
        contactEmail: d['contactEmail'] as String,
        contactPhone: d['contactPhone'] as String,
        whatsappNumber: d['whatsappNumber'] as String,
        address: d['address'] as String,
        lat: d['lat'] as double,
        lng: d['lng'] as double,
        bannerUrl: d['bannerUrl'] as String,
        startDate: d['startDate'] as DateTime,
        endDate: d['endDate'] as DateTime,
        createdAt: DateTime.now(),
      );
      await _firestore.addDonationDrive(drive);
    }
    return drives.length;
  }

  Future<int> seedVolunteerOpportunities(String? orgId) async {
    final now = DateTime.now();
    // Community Opportunities - Mix of Volunteering Opportunities (Give Time) and Volunteering Donations (Give Items)
    final opportunities = [
      // Physical Labor - Disaster
      {
        'title': 'Flood Cleanup - Pahang',
        'description': 'Help clean up mud and debris from flood-affected homes. Physical labor required. Safety equipment provided.',
        'organizationName': 'Malaysian Red Crescent',
        'location': 'Kuantan, Pahang',
        'lat': 3.8245,
        'lng': 103.3232,
        'skillsRequired': ['Cleaning', 'Construction'],
        'slotsTotal': 30,
        'slotsFilled': 15,
        'startTime': now.add(const Duration(days: 2)),
        'endTime': now.add(const Duration(days: 2, hours: 6)),
        'imageUrl': 'https://images.unsplash.com/photo-1593113598332-cd288d3dbeb2?w=800&h=400&fit=crop',
        'visibility': RequestVisibility.public,
      },
      {
        'title': 'Packing Aid Boxes - Disaster Relief',
        'description': 'Help pack emergency aid boxes with food, water, and essentials for flood victims. Warehouse work.',
        'organizationName': 'Malaysian Red Crescent',
        'location': 'Shah Alam, Selangor',
        'lat': 3.0733,
        'lng': 101.5185,
        'skillsRequired': ['Manual Labor'],
        'slotsTotal': 25,
        'slotsFilled': 12,
        'startTime': now.add(const Duration(days: 1)),
        'endTime': now.add(const Duration(days: 1, hours: 4)),
        'imageUrl': 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=800&h=400&fit=crop',
        'visibility': RequestVisibility.public,
      },
      // Physical Labor - Community
      {
        'title': 'Beach Cleanup Drive - Port Dickson',
        'description': 'Join us for a morning of environmental action! We\'ll clean the beach and raise awareness about ocean conservation.',
        'organizationName': 'EcoKnights',
        'location': 'Port Dickson Beach, Negeri Sembilan',
        'lat': 2.5227,
        'lng': 101.7967,
        'skillsRequired': ['Cleaning'],
        'slotsTotal': 50,
        'slotsFilled': 23,
        'startTime': now.add(const Duration(days: 7)),
        'endTime': now.add(const Duration(days: 7, hours: 4)),
        'imageUrl': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800&h=400&fit=crop',
        'visibility': RequestVisibility.public,
      },
      {
        'title': 'Tree Planting - Sungai Buloh',
        'description': 'Join our reforestation project. We\'re planting 500 trees to restore the local ecosystem.',
        'organizationName': 'Global Environment Centre',
        'location': 'Sungai Buloh Forest Reserve',
        'lat': 3.2167,
        'lng': 101.5833,
        'skillsRequired': ['Construction'],
        'slotsTotal': 40,
        'slotsFilled': 28,
        'startTime': now.add(const Duration(days: 14)),
        'endTime': now.add(const Duration(days: 14, hours: 5)),
        'imageUrl': 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=800&h=400&fit=crop',
        'visibility': RequestVisibility.public,
      },
      // Social & Care - Welfare
      {
        'title': 'Elderly Care Visit - Ampang',
        'description': 'Spend time with elderly residents at a care home. Activities include reading, gardening, and conversation.',
        'organizationName': 'Pure Life Society',
        'location': 'Ampang, Kuala Lumpur',
        'lat': 3.1589,
        'lng': 101.7626,
        'skillsRequired': ['Counseling'],
        'slotsTotal': 15,
        'slotsFilled': 8,
        'startTime': now.add(const Duration(days: 5)),
        'endTime': now.add(const Duration(days: 5, hours: 3)),
        'imageUrl': 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=800&h=400&fit=crop',
        'visibility': RequestVisibility.public,
      },
      // Skill-Based - Education
      {
        'title': 'Teach English at Community Center',
        'description': 'Volunteer to teach basic English to underprivileged children. No experience required, just patience and enthusiasm!',
        'organizationName': 'Teach For Malaysia',
        'location': 'Petaling Jaya, Selangor',
        'lat': 3.1068,
        'lng': 101.6057,
        'skillsRequired': ['Teaching'],
        'slotsTotal': 10,
        'slotsFilled': 6,
        'startTime': now.add(const Duration(days: 3)),
        'endTime': now.add(const Duration(days: 3, hours: 2)),
        'imageUrl': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=400&fit=crop',
        'visibility': RequestVisibility.public,
      },
      // Skill-Based - Professional
      {
        'title': 'Graphic Design for NGO Website',
        'description': 'Help design graphics and banners for a local NGO\'s website. Remote work possible.',
        'organizationName': 'Tech Volunteers Malaysia',
        'location': 'Remote / Kuala Lumpur',
        'lat': 3.1390,
        'lng': 101.6869,
        'skillsRequired': ['IT Support'],
        'slotsTotal': 5,
        'slotsFilled': 2,
        'startTime': now.add(const Duration(days: 10)),
        'endTime': now.add(const Duration(days: 10, hours: 4)),
        'imageUrl': 'https://images.unsplash.com/photo-1467232004584-a241de8bcf5d?w=800&h=400&fit=crop',
        'visibility': RequestVisibility.public,
      },
      // Add some private requests for testing
      {
        'title': 'Private Medical Support Request',
        'description': 'Need medical supplies for family member. Requesting privately.',
        'organizationName': 'Anonymous Requester',
        'location': 'Kuala Lumpur',
        'lat': 3.1390,
        'lng': 101.6869,
        'skillsRequired': ['Medical'],
        'slotsTotal': 1,
        'slotsFilled': 0,
        'startTime': now.add(const Duration(days: 1)),
        'endTime': now.add(const Duration(days: 1, hours: 2)),
        'visibility': RequestVisibility.private,
        'isRegisteredWithJKM': true,
        'isB40Household': true,
      },
    ];

    for (final o in opportunities) {
      final ref = _db.collection('volunteer_listings').doc();
      final listing = VolunteerListing(
        id: ref.id,
        title: o['title'] as String,
        description: o['description'] as String,
        organizationId: orgId,
        organizationName: o['organizationName'] as String,
        location: o['location'] as String,
        lat: o['lat'] as double,
        lng: o['lng'] as double,
        skillsRequired: List<String>.from(o['skillsRequired'] as List),
        slotsTotal: o['slotsTotal'] as int,
        slotsFilled: o['slotsFilled'] as int,
        startTime: o['startTime'] as DateTime,
        endTime: o['endTime'] as DateTime,
        imageUrl: o['imageUrl'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visibility: o['visibility'] as RequestVisibility? ?? RequestVisibility.public,
        isRegisteredWithJKM: o['isRegisteredWithJKM'] as bool?,
        isB40Household: o['isB40Household'] as bool?,
      );
      await _firestore.addVolunteerListing(listing);
    }
    return opportunities.length;
  }

  Future<int> seedAidResources(String? ownerId) async {
    // Static Aid Resources - Directory of existing resources (Aid Centers)
    final resources = [
      // Food Sources
      {
        'title': 'Community Food Bank - Chow Kit',
        'description': 'Free food distribution center. Open to all. Stock levels: Rice (High), Cooking Oil (Medium), Canned Food (High)',
        'category': 'Food',
        'location': 'Chow Kit, Kuala Lumpur',
        'urgency': 'low',
        'lat': 3.1725,
        'lng': 101.7020,
        'imageUrl': 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=800&h=400&fit=crop',
        'eligibility': 'Open to all',
      },
      {
        'title': 'Soup Kitchen - Petaling Jaya',
        'description': 'Free meal distribution daily 11am-2pm. Serving hot meals for families in need.',
        'category': 'Food',
        'location': 'Petaling Jaya, Selangor',
        'urgency': 'low',
        'lat': 3.1068,
        'lng': 101.6057,
        'imageUrl': 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=800&h=400&fit=crop',
        'eligibility': 'Open to all',
      },
      {
        'title': 'Community Pantry - Ampang',
        'description': 'Take what you need, leave what you can. 24/7 accessible pantry with basic food items.',
        'category': 'Food',
        'location': 'Ampang, Kuala Lumpur',
        'urgency': 'low',
        'lat': 3.1589,
        'lng': 101.7626,
        'imageUrl': 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=800&h=400&fit=crop',
        'eligibility': 'Open to all',
      },
      // Shelter & Safety
      {
        'title': 'Temporary Disaster Shelter - Pahang',
        'description': 'Emergency shelter for flood victims. Capacity: 200 people. Open 24/7 during emergencies.',
        'category': 'Shelter',
        'location': 'Kuantan, Pahang',
        'urgency': 'medium',
        'lat': 3.8245,
        'lng': 103.3232,
        'imageUrl': 'https://images.unsplash.com/photo-1593113598332-cd288d3dbeb2?w=800&h=400&fit=crop',
        'eligibility': 'Disaster victims',
      },
      {
        'title': 'Homeless Support Center - KL',
        'description': 'Day center providing shelter, meals, and basic services for homeless individuals.',
        'category': 'Shelter',
        'location': 'Kuala Lumpur',
        'urgency': 'low',
        'lat': 3.1390,
        'lng': 101.6869,
        'imageUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&h=400&fit=crop',
        'eligibility': 'Open to all',
      },
      {
        'title': 'Women\'s Shelter - Selangor',
        'description': 'Safe haven for women and children in crisis. 24/7 helpline available.',
        'category': 'Shelter',
        'location': 'Shah Alam, Selangor',
        'urgency': 'high',
        'lat': 3.0733,
        'lng': 101.5185,
        'imageUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&h=400&fit=crop',
        'eligibility': 'Women and children in need',
      },
      // Health
      {
        'title': 'Free Clinic - Community Health Center',
        'description': 'Free basic medical consultations. Open Mon-Fri 9am-5pm. Walk-ins welcome.',
        'category': 'Medical',
        'location': 'Petaling Jaya, Selangor',
        'urgency': 'low',
        'lat': 3.1068,
        'lng': 101.6057,
        'imageUrl': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=800&h=400&fit=crop',
        'eligibility': 'Registered poor only',
      },
      {
        'title': 'Health Aid Center - Ampang',
        'description': 'Free health screenings and basic medication assistance. First aid available.',
        'category': 'Medical',
        'location': 'Ampang, Kuala Lumpur',
        'urgency': 'low',
        'lat': 3.1589,
        'lng': 101.7626,
        'imageUrl': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=800&h=400&fit=crop',
        'eligibility': 'Open to all',
      },
      // Material Goods
      {
        'title': 'Cloth Bank - Free Clothing Center',
        'description': 'Free clothing for families in need. Men\'s, women\'s, and children\'s clothing available. Stock: High',
        'category': 'Clothing',
        'location': 'Kuala Lumpur',
        'urgency': 'low',
        'lat': 3.1390,
        'lng': 101.6869,
        'imageUrl': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&h=400&fit=crop',
        'eligibility': 'Registered poor only',
      },
      {
        'title': 'School Uniform Bank - Selangor',
        'description': 'Free school uniforms and supplies for students. Available sizes: All. Stock: Medium',
        'category': 'Education',
        'location': 'Shah Alam, Selangor',
        'urgency': 'low',
        'lat': 3.0733,
        'lng': 101.5185,
        'imageUrl': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=400&fit=crop',
        'eligibility': 'Students from low-income families',
      },
    ];

    for (final r in resources) {
      final ref = _db.collection('aid_resources').doc();
      final urgency = AidUrgency.values.firstWhere(
        (u) => u.name == r['urgency'],
        orElse: () => AidUrgency.medium,
      );
      final resource = AidResource(
        id: ref.id,
        title: r['title'] as String,
        description: r['description'] as String?,
        category: r['category'] as String,
        location: r['location'] as String,
        urgency: urgency,
        ownerId: ownerId,
        lat: (r['lat'] as num).toDouble(),
        lng: (r['lng'] as num).toDouble(),
        imageUrl: r['imageUrl'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.addAidResource(resource);
    }
    return resources.length;
  }

  Future<int> seedAlerts(String? _) async {
    final alerts = [
      {'title': 'Flood alert: Pahang river levels rising', 'body': 'Residents in low-lying areas of Kuantan and Pekan are advised to evacuate. Relief centers open at Dewan Seri Pahang.', 'type': 'flood', 'region': 'Pahang'},
      {'title': 'SOS: Family trapped in flood - need rescue', 'body': 'Kampung Sungai Lembing. Contact: 012-XXX XXXX. Urgent assistance required.', 'type': 'sos', 'region': 'Pahang'},
      {'title': 'Heavy rain warning: Selangor', 'body': 'MetMalaysia issues yellow alert for Klang Valley. Avoid low-lying areas.', 'type': 'flood', 'region': 'Selangor'},
      {'title': 'Community food bank open', 'body': 'Kechara Soup Kitchen distributing meals at Chow Kit. 11am-2pm daily.', 'type': 'general', 'region': 'Kuala Lumpur'},
    ];

    for (final a in alerts) {
      final ref = _db.collection('alerts').doc();
      final type = a['type'] == 'flood' ? AlertType.flood : (a['type'] == 'sos' ? AlertType.sos : AlertType.general);
      final alert = Alert(
        id: ref.id,
        title: a['title'] as String,
        body: a['body'] as String,
        type: type,
        region: a['region'] as String,
        createdAt: DateTime.now(),
      );
      await _firestore.addAlert(alert);
    }
    return alerts.length;
  }

  Future<int> seedFeedPosts(String? authorId) async {
    final authorIdToUse = authorId ?? 'seed_user_1';
    final posts = [
      'Just completed my first volunteer shift at the soup kitchen. Highly recommend!',
      'Flood relief donations are still needed in Pahang. Every contribution counts.',
      'Our beach cleanup collected 200kg of waste. Thank you to all volunteers!',
      'The Match Me feature found the perfect opportunity for my skills. Love this app!',
      'E-certificate received! 10 hours of volunteering at the community center.',
    ];

    for (final text in posts) {
      final ref = _db.collection('feed_posts').doc();
      final post = FeedPost(
        id: ref.id,
        authorId: authorIdToUse,
        authorName: 'Demo User',
        text: text,
        likes: (posts.indexOf(text) * 3) % 15,
        commentCount: posts.indexOf(text) % 5,
        createdAt: DateTime.now().subtract(Duration(days: posts.indexOf(text))),
      );
      await _firestore.addFeedPost(post);
    }
    return posts.length;
  }

  Future<int> seedMicroDonations(String? userId) async {
    final requesterId = userId ?? 'seed_user_1';
    final now = DateTime.now();
    final requests = [
      {
        'title': 'Need school supplies for 3 children',
        'description': 'Looking for notebooks, pencils, and backpacks for my children starting school next month.',
        'category': MicroDonationCategory.education,
        'itemNeeded': 'School supplies (notebooks, pencils, backpacks)',
        'quantity': 3,
        'urgency': 'medium',
        'location': 'Kuala Lumpur',
        'lat': 3.1390,
        'lng': 101.6869,
        'status': MicroDonationStatus.open,
      },
      {
        'title': 'Urgent: Need baby formula',
        'description': 'Running low on baby formula. Any brand would help.',
        'category': MicroDonationCategory.specific_food,
        'itemNeeded': 'Baby formula',
        'quantity': 2,
        'urgency': 'high',
        'location': 'Petaling Jaya, Selangor',
        'lat': 3.1068,
        'lng': 101.6057,
        'status': MicroDonationStatus.open,
      },
      {
        'title': 'Looking for a small refrigerator',
        'description': 'Our old fridge broke down. Need a small one for a family of 4.',
        'category': MicroDonationCategory.appliances,
        'itemNeeded': 'Small refrigerator',
        'quantity': 1,
        'urgency': 'medium',
        'location': 'Shah Alam, Selangor',
        'lat': 3.0733,
        'lng': 101.5185,
        'status': MicroDonationStatus.open,
      },
      {
        'title': 'Need a study desk',
        'description': 'My daughter needs a desk for online classes.',
        'category': MicroDonationCategory.furniture,
        'itemNeeded': 'Study desk',
        'quantity': 1,
        'urgency': 'low',
        'location': 'Ampang, Kuala Lumpur',
        'lat': 3.1589,
        'lng': 101.7626,
        'status': MicroDonationStatus.open,
      },
      {
        'title': 'Medical supplies needed',
        'description': 'Need basic medical supplies: bandages, antiseptic, pain relievers.',
        'category': MicroDonationCategory.medical,
        'itemNeeded': 'Medical supplies',
        'quantity': 1,
        'urgency': 'medium',
        'location': 'Klang, Selangor',
        'lat': 3.0449,
        'lng': 101.4456,
        'status': MicroDonationStatus.fulfilled,
        'fulfilledBy': 'seed_donor_1',
      },
    ];

    for (final r in requests) {
      final ref = _db.collection('micro_donations').doc();
      final request = MicroDonationRequest(
        id: ref.id,
        title: r['title'] as String,
        description: r['description'] as String?,
        category: r['category'] as MicroDonationCategory,
        requesterId: requesterId,
        requesterName: 'Demo User',
        itemNeeded: r['itemNeeded'] as String?,
        quantity: r['quantity'] as int,
        urgency: r['urgency'] as String,
        location: r['location'] as String?,
        lat: (r['lat'] as num?)?.toDouble(),
        lng: (r['lng'] as num?)?.toDouble(),
        status: r['status'] as MicroDonationStatus,
        fulfilledBy: r['fulfilledBy'] as String?,
        createdAt: now.subtract(Duration(days: requests.indexOf(r))),
        updatedAt: now.subtract(Duration(days: requests.indexOf(r))),
      );
      await _firestore.addMicroDonationRequest(request);
    }
    return requests.length;
  }

  Future<int> seedAttendances(String? userId) async {
    final userIdToUse = userId ?? 'seed_user_1';
    final now = DateTime.now();
    
    // Get some volunteer listings to reference
    final listings = await _firestore.getVolunteerListings();
    if (listings.isEmpty) return 0; // Can't create attendances without listings
    
    final attendances = [
      {
        'listingId': listings[0].id,
        'checkInAt': now.subtract(const Duration(days: 5, hours: 10)),
        'checkOutAt': now.subtract(const Duration(days: 5, hours: 6)),
        'hours': 4.0,
        'verified': true,
      },
      {
        'listingId': listings.length > 1 ? listings[1].id : listings[0].id,
        'checkInAt': now.subtract(const Duration(days: 3, hours: 9)),
        'checkOutAt': now.subtract(const Duration(days: 3, hours: 5)),
        'hours': 4.0,
        'verified': true,
      },
      {
        'listingId': listings.length > 2 ? listings[2].id : listings[0].id,
        'checkInAt': now.subtract(const Duration(days: 1, hours: 14)),
        'checkOutAt': now.subtract(const Duration(days: 1, hours: 10)),
        'hours': 4.0,
        'verified': true,
      },
    ];

    for (final a in attendances) {
      final ref = _db.collection('attendances').doc();
      final attendance = Attendance(
        id: ref.id,
        listingId: a['listingId'] as String,
        userId: userIdToUse,
        checkInAt: a['checkInAt'] as DateTime?,
        checkOutAt: a['checkOutAt'] as DateTime?,
        hours: a['hours'] as double?,
        verified: a['verified'] as bool,
        createdAt: (a['checkInAt'] as DateTime?) ?? now,
      );
      await _firestore.addAttendance(attendance);
    }
    return attendances.length;
  }

  Future<int> seedECertificates(String? userId) async {
    final userIdToUse = userId ?? 'seed_user_1';
    final now = DateTime.now();
    
    // Get some volunteer listings and attendances to reference
    final listings = await _firestore.getVolunteerListings();
    final attendances = await _firestore.getAttendancesForUser(userIdToUse);
    
    if (listings.isEmpty || attendances.isEmpty) return 0;
    
    final certificates = [
      {
        'listingId': attendances[0].listingId,
        'listingTitle': listings.firstWhere((l) => l.id == attendances[0].listingId, orElse: () => listings[0]).title,
        'organizationName': listings.firstWhere((l) => l.id == attendances[0].listingId, orElse: () => listings[0]).organizationName,
        'hours': attendances[0].hours ?? 4.0,
        'issuedAt': now.subtract(const Duration(days: 4)),
        'verificationCode': 'CERT-${DateTime.now().millisecondsSinceEpoch}',
      },
      if (attendances.length > 1)
        {
          'listingId': attendances[1].listingId,
          'listingTitle': listings.firstWhere((l) => l.id == attendances[1].listingId, orElse: () => listings[0]).title,
          'organizationName': listings.firstWhere((l) => l.id == attendances[1].listingId, orElse: () => listings[0]).organizationName,
          'hours': attendances[1].hours ?? 4.0,
          'issuedAt': now.subtract(const Duration(days: 2)),
          'verificationCode': 'CERT-${DateTime.now().millisecondsSinceEpoch + 1}',
        },
    ];

    for (final c in certificates) {
      final ref = _db.collection('e_certificates').doc();
      final cert = ECertificate(
        id: ref.id,
        userId: userIdToUse,
        listingId: c['listingId'] as String,
        listingTitle: c['listingTitle'] as String,
        organizationName: c['organizationName'] as String?,
        hours: c['hours'] as double?,
        issuedAt: c['issuedAt'] as DateTime?,
        verificationCode: c['verificationCode'] as String?,
      );
      await _firestore.addECertificate(cert);
    }
    return certificates.length;
  }

  Future<int> seedDonations(String? userId) async {
    final userIdToUse = userId ?? 'seed_user_1';
    final now = DateTime.now();
    
    // Get some donation drives to reference
    final drives = await _firestore.getDonationDrives();
    if (drives.isEmpty) return 0; // Can't create donations without drives
    
    final donations = [
      {
        'driveId': drives[0].id,
        'driveTitle': drives[0].title,
        'amount': 50.0,
        'createdAt': now.subtract(const Duration(days: 7)),
      },
      {
        'driveId': drives.length > 1 ? drives[1].id : drives[0].id,
        'driveTitle': drives.length > 1 ? drives[1].title : drives[0].title,
        'amount': 100.0,
        'createdAt': now.subtract(const Duration(days: 4)),
      },
      {
        'driveId': drives.length > 2 ? drives[2].id : drives[0].id,
        'driveTitle': drives.length > 2 ? drives[2].title : drives[0].title,
        'amount': 25.0,
        'createdAt': now.subtract(const Duration(days: 1)),
      },
    ];

    for (final d in donations) {
      final ref = _db.collection('donations').doc();
      final donation = Donation(
        id: ref.id,
        driveId: d['driveId'] as String,
        userId: userIdToUse,
        amount: d['amount'] as double,
        driveTitle: d['driveTitle'] as String?,
        createdAt: d['createdAt'] as DateTime?,
      );
      await _firestore.addDonation(donation);
    }
    return donations.length;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aid_resource.dart';
import '../models/alert.dart';
import '../models/donation_drive.dart';
import '../models/feed_post.dart';
import '../models/volunteer_listing.dart';
import 'firestore_service.dart';

/// Seeds the database with test data for development/demo.
class SeedDataService {
  SeedDataService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final FirestoreService _firestore = FirestoreService();

  Future<int> seedAll({String? systemUserId}) async {
    var count = 0;
    count += await seedDonationDrives(systemUserId);
    count += await seedVolunteerOpportunities(systemUserId);
    count += await seedAidResources(systemUserId);
    count += await seedAlerts(systemUserId);
    count += await seedFeedPosts(systemUserId);
    return count;
  }

  Future<int> seedDonationDrives(String? ngoId) async {
    final drives = [
      {
        'title': 'Flood Relief Fund - Pahang 2026',
        'description': 'Heavy flooding has displaced thousands of families in Pahang. Your donation will provide emergency shelter, food supplies, clean water, and medical assistance to affected communities.',
        'goalAmount': 50000.0,
        'raisedAmount': 32750.0,
        'ngoName': 'Malaysian Red Crescent',
        'category': 'disaster_relief',
        'location': 'Kuantan, Pahang',
        'contactEmail': 'relief@redcrescent.my',
        'contactPhone': '+60123456789',
        'whatsappNumber': '60123456789',
        'address': 'Jalan Hospital, 25100 Kuantan, Pahang',
        'lat': 3.8245,
        'lng': 103.3232,
        'bannerUrl': 'https://picsum.photos/seed/flood1/800/400',
      },
      {
        'title': 'Education Fund for Orang Asli Children',
        'description': 'Support indigenous children\'s education by providing school supplies, uniforms, textbooks, and scholarships.',
        'goalAmount': 25000.0,
        'raisedAmount': 18900.0,
        'ngoName': 'UNICEF Malaysia',
        'category': 'community_support',
        'location': 'Gua Musang, Kelantan',
        'contactEmail': 'education@unicef.my',
        'contactPhone': '+60198765432',
        'whatsappNumber': '60198765432',
        'address': 'Kampung Pulai, Gua Musang, Kelantan',
        'lat': 4.8845,
        'lng': 101.9683,
        'bannerUrl': 'https://picsum.photos/seed/education1/800/400',
      },
      {
        'title': 'Emergency Food Bank - Kuala Lumpur',
        'description': 'Help us stock the community food bank to support families in need. Every RM10 feeds a family for a day.',
        'goalAmount': 30000.0,
        'raisedAmount': 15200.0,
        'ngoName': 'Kechara Soup Kitchen',
        'category': 'community_support',
        'location': 'Kuala Lumpur',
        'contactEmail': 'info@kechara.com',
        'contactPhone': '+60390575555',
        'whatsappNumber': '60390575555',
        'address': 'No 7, Jalan Utara, 46200 Petaling Jaya',
        'lat': 3.1390,
        'lng': 101.6869,
        'bannerUrl': 'https://picsum.photos/seed/food1/800/400',
      },
      {
        'title': 'Typhoon Relief - Sabah',
        'description': 'Communities in Sabah need urgent support after the recent typhoon. Donations will go toward rebuilding homes and restoring livelihoods.',
        'goalAmount': 75000.0,
        'raisedAmount': 42000.0,
        'ngoName': 'Yayasan Sabah',
        'category': 'disaster_relief',
        'location': 'Kota Kinabalu, Sabah',
        'contactEmail': 'relief@yayasansabah.org.my',
        'contactPhone': '+6088242111',
        'whatsappNumber': '6088242111',
        'address': 'Wisma Tun Fuad, Kota Kinabalu, Sabah',
        'lat': 5.9804,
        'lng': 116.0735,
        'bannerUrl': 'https://picsum.photos/seed/typhoon1/800/400',
      },
      {
        'title': 'Medical Supplies for Rural Clinics',
        'description': 'Provide essential medical supplies to rural clinics in Sarawak. Your donation saves lives.',
        'goalAmount': 40000.0,
        'raisedAmount': 28000.0,
        'ngoName': 'Malaysian Medical Relief Society',
        'category': 'community_support',
        'location': 'Kuching, Sarawak',
        'contactEmail': 'donate@mercy.org.my',
        'contactPhone': '+6082423111',
        'whatsappNumber': '6082423111',
        'address': 'Jalan Tabuan, 93150 Kuching, Sarawak',
        'lat': 1.5535,
        'lng': 110.3593,
        'bannerUrl': 'https://picsum.photos/seed/medical1/800/400',
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
        category: d['category'] as String,
        location: d['location'] as String,
        contactEmail: d['contactEmail'] as String,
        contactPhone: d['contactPhone'] as String,
        whatsappNumber: d['whatsappNumber'] as String,
        address: d['address'] as String,
        lat: d['lat'] as double,
        lng: d['lng'] as double,
        bannerUrl: d['bannerUrl'] as String,
        createdAt: DateTime.now(),
      );
      await _firestore.addDonationDrive(drive);
    }
    return drives.length;
  }

  Future<int> seedVolunteerOpportunities(String? orgId) async {
    final now = DateTime.now();
    final opportunities = [
      {
        'title': 'Beach Cleanup Drive - Port Dickson',
        'description': 'Join us for a morning of environmental action! We\'ll clean the beach and raise awareness about ocean conservation.',
        'organizationName': 'EcoKnights',
        'location': 'Port Dickson Beach, Negeri Sembilan',
        'lat': 2.5227,
        'lng': 101.7967,
        'skillsRequired': ['manual_labor', 'teamwork'],
        'slotsTotal': 50,
        'slotsFilled': 23,
        'startTime': now.add(const Duration(days: 7)),
      },
      {
        'title': 'Teach English at Community Center',
        'description': 'Volunteer to teach basic English to underprivileged children. No experience required, just patience and enthusiasm!',
        'organizationName': 'Teach For Malaysia',
        'location': 'Petaling Jaya, Selangor',
        'lat': 3.1068,
        'lng': 101.6057,
        'skillsRequired': ['teaching', 'communication'],
        'slotsTotal': 10,
        'slotsFilled': 6,
        'startTime': now.add(const Duration(days: 3)),
      },
      {
        'title': 'Food Distribution - Chow Kit',
        'description': 'Help distribute meals to homeless and needy families. Shifts available morning and evening.',
        'organizationName': 'Kechara Soup Kitchen',
        'location': 'Chow Kit, Kuala Lumpur',
        'lat': 3.1725,
        'lng': 101.7020,
        'skillsRequired': ['manual_labor', 'teamwork'],
        'slotsTotal': 20,
        'slotsFilled': 12,
        'startTime': now.add(const Duration(days: 1)),
      },
      {
        'title': 'Tree Planting - Sungai Buloh',
        'description': 'Join our reforestation project. We\'re planting 500 trees to restore the local ecosystem.',
        'organizationName': 'Global Environment Centre',
        'location': 'Sungai Buloh Forest Reserve',
        'lat': 3.2167,
        'lng': 101.5833,
        'skillsRequired': ['manual_labor', 'outdoor'],
        'slotsTotal': 40,
        'slotsFilled': 28,
        'startTime': now.add(const Duration(days: 14)),
      },
      {
        'title': 'Elderly Care Visit - Ampang',
        'description': 'Spend time with elderly residents at a care home. Activities include reading, gardening, and conversation.',
        'organizationName': 'Pure Life Society',
        'location': 'Ampang, Kuala Lumpur',
        'lat': 3.1589,
        'lng': 101.7626,
        'skillsRequired': ['communication', 'empathy'],
        'slotsTotal': 15,
        'slotsFilled': 8,
        'startTime': now.add(const Duration(days: 5)),
      },
      {
        'title': 'Disaster Response Training',
        'description': 'Learn first aid and basic disaster response. Certification provided. Essential for future volunteer deployments.',
        'organizationName': 'Malaysian Red Crescent',
        'location': 'Shah Alam, Selangor',
        'lat': 3.0733,
        'lng': 101.5185,
        'skillsRequired': ['willingness_to_learn'],
        'slotsTotal': 30,
        'slotsFilled': 18,
        'startTime': now.add(const Duration(days: 21)),
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.addVolunteerListing(listing);
    }
    return opportunities.length;
  }

  Future<int> seedAidResources(String? ownerId) async {
    final resources = [
      {'title': 'Urgent: Baby formula needed', 'category': 'Food', 'location': 'Kuantan', 'urgency': 'high', 'lat': 3.8245, 'lng': 103.3232},
      {'title': 'Blankets and clothing for flood victims', 'category': 'Clothing', 'location': 'Pekan, Pahang', 'urgency': 'critical', 'lat': 3.4897, 'lng': 103.3896},
      {'title': 'Temporary shelter materials', 'category': 'Shelter', 'location': 'Bentong', 'urgency': 'high', 'lat': 3.5228, 'lng': 101.9083},
      {'title': 'First aid kits - community center', 'category': 'Medical', 'location': 'Shah Alam', 'urgency': 'medium', 'lat': 3.0733, 'lng': 101.5185},
      {'title': 'Canned food drive', 'category': 'Food', 'location': 'Kuala Lumpur', 'urgency': 'medium', 'lat': 3.1390, 'lng': 101.6869},
      {'title': 'Wheelchair needed for elderly', 'category': 'Medical', 'location': 'Petaling Jaya', 'urgency': 'medium', 'lat': 3.1068, 'lng': 101.6057},
      {'title': 'School uniforms - 20 children', 'category': 'Clothing', 'location': 'Gua Musang', 'urgency': 'low', 'lat': 4.8845, 'lng': 101.9683},
      {'title': 'Clean water tanks', 'category': 'Shelter', 'location': 'Kota Bharu', 'urgency': 'high', 'lat': 6.1252, 'lng': 102.2381},
      {'title': 'Diabetes medication supplies', 'category': 'Medical', 'location': 'Ipoh', 'urgency': 'high', 'lat': 4.5975, 'lng': 101.0901},
      {'title': 'Rice and cooking oil - family of 6', 'category': 'Food', 'location': 'Johor Bahru', 'urgency': 'medium', 'lat': 1.4927, 'lng': 103.7414},
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
        category: r['category'] as String,
        location: r['location'] as String,
        urgency: urgency,
        ownerId: ownerId,
        lat: (r['lat'] as num).toDouble(),
        lng: (r['lng'] as num).toDouble(),
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
}

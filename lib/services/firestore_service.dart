import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/aid_resource.dart';
import '../models/donation_drive.dart';
import '../models/volunteer_listing.dart';
import '../models/attendance.dart';
import '../models/e_certificate.dart';
import '../models/alert.dart';
import '../models/feed_post.dart';
import '../models/donation.dart';
import '../models/feed_comment.dart';
import '../core/config.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _users = 'users';
  static const _aidResources = 'aid_resources';
  static const _donationDrives = 'donation_drives';
  static const _volunteerListings = 'volunteer_listings';
  static const _attendances = 'attendances';
  static const _eCertificates = 'e_certificates';
  static const _alerts = 'alerts';
  static const _feedPosts = 'feed_posts';
  static const _applications = 'applications';
  static const _donations = 'donations';
  static const _feedComments = 'feed_comments';
  static const _reports = 'reports';

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection(_users).doc(uid).get();
    if (doc.exists && doc.data() != null) return AppUser.fromFirestore(doc);
    return null;
  }

  Future<void> setUser(AppUser user) async {
    await _db.collection(_users).doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserPoints(String uid, int delta) async {
    await _db.collection(_users).doc(uid).update({'points': FieldValue.increment(delta)});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> aidResourcesStream() {
    return _db.collection(_aidResources).orderBy('createdAt', descending: true).snapshots();
  }

  Future<List<AidResource>> getAidResources({String? category, String? urgency}) async {
    final snap = await _db.collection(_aidResources).orderBy('createdAt', descending: true).limit(100).get();
    var list = snap.docs.map((d) => AidResource.fromFirestore(d)).toList();
    if (category != null && category.isNotEmpty) {
      list = list.where((r) => r.category == category).toList();
    }
    if (urgency != null && urgency.isNotEmpty) {
      list = list.where((r) => r.urgency.name == urgency).toList();
    }
    return list;
  }

  Future<void> addAidResource(AidResource resource) async {
    await _db.collection(_aidResources).doc(resource.id).set(resource.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> donationDrivesStream() {
    return _db.collection(_donationDrives).orderBy('createdAt', descending: true).snapshots();
  }

  Future<List<DonationDrive>> getDonationDrives({String? category}) async {
    var query = _db.collection(_donationDrives).orderBy('createdAt', descending: true).limit(50);
    final snap = await query.get();
    var list = snap.docs.map((d) => DonationDrive.fromFirestore(d)).toList();
    if (category != null && category.isNotEmpty) {
      list = list.where((d) => d.category == category).toList();
    }
    return list;
  }

  Future<void> addDonationDrive(DonationDrive drive) async {
    await _db.collection(_donationDrives).doc(drive.id).set(drive.toMap());
  }

  Future<void> updateDriveRaised(String driveId, double amount) async {
    await _db.collection(_donationDrives).doc(driveId).update({'raisedAmount': FieldValue.increment(amount)});
  }

  Future<void> addDonation(Donation donation) async {
    await _db.collection(_donations).doc(donation.id).set(donation.toMap());
    await updateUserPoints(donation.userId, Config.pointsPerDonationBonus);
  }

  Future<List<Donation>> getDonationsByUser(String userId) async {
    final snap = await _db.collection(_donations).where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Donation.fromFirestore(d)).toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> volunteerListingsStream() {
    return _db.collection(_volunteerListings).orderBy('createdAt', descending: true).snapshots();
  }

  Future<List<VolunteerListing>> getVolunteerListings() async {
    final snap = await _db.collection(_volunteerListings).orderBy('createdAt', descending: true).limit(50).get();
    return snap.docs.map((d) => VolunteerListing.fromFirestore(d)).toList();
  }

  /// Paginated volunteer listings. Returns list and last document for next page.
  Future<({List<VolunteerListing> list, DocumentSnapshot? lastDoc})> getVolunteerListingsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _db.collection(_volunteerListings).orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    final list = snap.docs.map((d) => VolunteerListing.fromFirestore(d)).toList();
    final lastDoc = snap.docs.isEmpty ? null : snap.docs.last;
    return (list: list, lastDoc: lastDoc);
  }

  static const _savedListings = 'saved_listings';

  Future<List<String>> getSavedListingIds(String userId) async {
    final snap = await _db.collection(_users).doc(userId).collection(_savedListings).get();
    return snap.docs.map((d) => d.id).toList();
  }

  Future<void> addSavedListing(String userId, String listingId) async {
    await _db.collection(_users).doc(userId).collection(_savedListings).doc(listingId).set({'savedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeSavedListing(String userId, String listingId) async {
    await _db.collection(_users).doc(userId).collection(_savedListings).doc(listingId).delete();
  }

  Future<void> addVolunteerListing(VolunteerListing listing) async {
    await _db.collection(_volunteerListings).doc(listing.id).set(listing.toMap());
  }

  Future<void> applyToListing(String listingId, String userId) async {
    await _db.collection(_applications).add({
      'listingId': listingId,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    await _db.collection(_volunteerListings).doc(listingId).update({'slotsFilled': FieldValue.increment(1)});
  }

  Future<List<Attendance>> getAttendancesForUser(String userId) async {
    final snap = await _db.collection(_attendances).where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Attendance.fromFirestore(d)).toList();
  }

  Future<void> addAttendance(Attendance attendance) async {
    await _db.collection(_attendances).doc(attendance.id).set(attendance.toMap());
    if (attendance.verified && attendance.hours != null && attendance.hours! > 0) {
      final points = (attendance.hours! * Config.pointsPerVolunteerHour).round();
      await updateUserPoints(attendance.userId, points);
    }
  }

  Future<void> addECertificate(ECertificate cert) async {
    await _db.collection(_eCertificates).doc(cert.id).set(cert.toMap());
  }

  Future<ECertificate?> getCertificateByCode(String code) async {
    final snap = await _db.collection(_eCertificates).where('verificationCode', isEqualTo: code).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return ECertificate.fromFirestore(snap.docs.first);
  }

  Future<List<ECertificate>> getCertificatesForUser(String userId) async {
    final snap = await _db.collection(_eCertificates).where('userId', isEqualTo: userId).get();
    final list = snap.docs.map((d) => ECertificate.fromFirestore(d)).toList();
    list.sort((a, b) => (b.issuedAt ?? DateTime(0)).compareTo(a.issuedAt ?? DateTime(0)));
    return list;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> alertsStream() {
    return _db.collection(_alerts).orderBy('createdAt', descending: true).limit(20).snapshots();
  }

  Future<void> addAlert(Alert alert) async {
    await _db.collection(_alerts).doc(alert.id).set(alert.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> feedPostsStream() {
    return _db.collection(_feedPosts).orderBy('createdAt', descending: true).limit(50).snapshots();
  }

  Future<void> addFeedPost(FeedPost post) async {
    await _db.collection(_feedPosts).doc(post.id).set(post.toMap());
  }

  Future<void> incrementLikes(String postId) async {
    await _db.collection(_feedPosts).doc(postId).update({'likes': FieldValue.increment(1)});
  }

  Future<List<FeedComment>> getCommentsForPost(String postId) async {
    final snap = await _db.collection(_feedComments).where('postId', isEqualTo: postId).orderBy('createdAt', descending: false).get();
    return snap.docs.map((d) => FeedComment.fromFirestore(d)).toList();
  }

  Future<void> addFeedComment(FeedComment comment) async {
    await _db.collection(_feedComments).doc(comment.id).set(comment.toMap());
    await _db.collection(_feedPosts).doc(comment.postId).update({'commentCount': FieldValue.increment(1)});
  }

  Future<void> reportPost(String postId, String userId, String reason) async {
    await _db.collection(_reports).add({
      'postId': postId,
      'userId': userId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AppUser>> getLeaderboard({int limit = 20}) async {
    final snap = await _db.collection(_users).orderBy('points', descending: true).limit(limit).get();
    return snap.docs.map((d) => AppUser.fromFirestore(d)).toList();
  }

  Future<Map<String, int>> getAnalyticsCounts() async {
    final usersSnap = await _db.collection(_users).get();
    final listingsSnap = await _db.collection(_volunteerListings).get();
    final drivesSnap = await _db.collection(_donationDrives).get();
    final certsSnap = await _db.collection(_eCertificates).get();
    final attendancesSnap = await _db.collection(_attendances).get();
    return {
      'users': usersSnap.docs.length,
      'listings': listingsSnap.docs.length,
      'drives': drivesSnap.docs.length,
      'certificates': certsSnap.docs.length,
      'attendances': attendancesSnap.docs.length,
    };
  }

  Future<double> getTotalDonations() async {
    final snap = await _db.collection(_donations).get();
    double total = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      total += (data['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }
}

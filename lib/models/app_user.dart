import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { volunteer, ngo, admin }

class AppUser {
  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.volunteer,
    this.skills = const [],
    this.interests = const [],
    this.points = 0,
    this.badges = const [],
    this.createdAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final List<String> skills;
  final List<String> interests;
  final int points;
  final List<String> badges;
  final DateTime? createdAt;

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: doc.id,
      email: m['email'] as String? ?? '',
      displayName: m['displayName'] as String?,
      photoUrl: m['photoUrl'] as String?,
      role: _roleFrom(m['role']),
      skills: List<String>.from(m['skills'] ?? []),
      interests: List<String>.from(m['interests'] ?? []),
      points: (m['points'] as num?)?.toInt() ?? 0,
      badges: List<String>.from(m['badges'] ?? []),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static UserRole _roleFrom(dynamic v) {
    if (v == null) return UserRole.volunteer;
    if (v == 'ngo') return UserRole.ngo;
    if (v == 'admin') return UserRole.admin;
    return UserRole.volunteer;
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'skills': skills,
      'interests': interests,
      'points': points,
      'badges': badges,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

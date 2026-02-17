import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.appUser;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (user == null || uid == null) {
      return const Center(child: Text('Please sign in to view your profile'));
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadUserStats(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        final totalHours = stats['totalHours'] as int;
        final totalDonations = stats['totalDonations'] as double;
        final eCertificates = stats['eCertificates'] as int;
        final activitiesAttended = stats['activitiesAttended'] as int;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: figmaOrange,
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.displayName?.substring(0, 1).toUpperCase() ?? user.email.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName ?? user.email,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: figmaBlack),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: figmaOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppUser.roleDisplayName(user.role),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: figmaOrange),
                      ),
                    ),
                  ],
                ),
              ),
              // Points and Badges Section
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(
                      icon: Icons.stars,
                      label: 'Points',
                      value: '${user.points}',
                      color: figmaOrange,
                    ),
                    _StatCard(
                      icon: Icons.emoji_events,
                      label: 'Badges',
                      value: '${user.badges.length}',
                      color: figmaPurple,
                    ),
                  ],
                ),
              ),
              // Stats Grid
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Impact',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _ImpactCard(
                          icon: Icons.access_time,
                          label: 'Volunteer Hours',
                          value: '$totalHours',
                          color: figmaOrange,
                        ),
                        _ImpactCard(
                          icon: Icons.volunteer_activism,
                          label: 'Total Donations',
                          value: 'RM ${totalDonations.toStringAsFixed(2)}',
                          color: figmaPurple,
                        ),
                        _ImpactCard(
                          icon: Icons.card_membership,
                          label: 'E-Certificates',
                          value: '$eCertificates',
                          color: figmaOrange,
                        ),
                        _ImpactCard(
                          icon: Icons.event,
                          label: 'Activities Attended',
                          value: '$activitiesAttended',
                          color: figmaPurple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Skills Section
              if (user.skills.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skills',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.skills.map((skill) => Chip(
                          label: Text(skill),
                          backgroundColor: figmaOrange.withOpacity(0.1),
                          side: BorderSide(color: figmaOrange.withOpacity(0.3)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              // Interests Section
              if (user.interests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.grey[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Interests',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.interests.map((interest) => Chip(
                          label: Text(interest),
                          backgroundColor: figmaPurple.withOpacity(0.1),
                          side: BorderSide(color: figmaPurple.withOpacity(0.3)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              // Badges Section
              if (user.badges.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Badges Earned',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: user.badges.map((badge) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: figmaOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: figmaOrange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events, color: figmaOrange, size: 20),
                              const SizedBox(width: 8),
                              Text(badge, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadUserStats(String uid) async {
    final firestore = FirestoreService();
    final attendances = await firestore.getAttendancesForUser(uid);
    final donations = await firestore.getDonationsByUser(uid);

    final totalHours = attendances.fold<double>(0.0, (sum, a) => sum + (a.hours ?? 0.0)).toInt();
    final totalDonations = donations.fold<double>(0, (sum, d) => sum + d.amount);
    final eCertificatesList = await firestore.getCertificatesForUser(uid);

    return {
      'totalHours': totalHours,
      'totalDonations': totalDonations,
      'eCertificates': eCertificatesList.length,
      'activitiesAttended': attendances.length,
    };
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

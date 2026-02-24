import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/attendance.dart';
import '../../models/donation.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';
import '../analytics/analytics_screen.dart';
import '../opportunities/my_requests_screen.dart';

class MyActivitiesScreen extends StatelessWidget {
  const MyActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in to see your activities'));
    }
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Activities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                ),
                const SizedBox(height: 4),
                Text(
                  'Events: donation drives, volunteering and donation opportunities',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Event participation'),
              Tab(text: 'Event ongoing'),
              Tab(text: 'My Request History'),
              Tab(text: 'Analytics'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                EventParticipationTab(uid: uid),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No ongoing events at the moment. Your active donation drives, volunteering and donation opportunities will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
                const MyRequestsScreen(),
                const AnalyticsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable event participation list (attendances + donations). Used in profile My Activity.
class EventParticipationTab extends StatelessWidget {
  const EventParticipationTab({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return FutureBuilder<dynamic>(
      future: Future.wait([
        firestore.getAttendancesForUser(uid),
        firestore.getDonationsByUser(uid),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final results = snap.data! as List;
        final attendances = results[0] as List<Attendance>;
        final donations = results[1] as List<Donation>;
        if (attendances.isEmpty && donations.isEmpty) {
          return const Center(
            child: Text(
              'No event participation yet. Join donation drives or volunteering opportunities to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (attendances.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Volunteer attendance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
              ),
              ...attendances.map((a) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Listing: ${a.listingId}'),
                  subtitle: Text('Hours: ${a.hours ?? "—"} · ${a.verified ? "Verified" : "Pending"}'),
                ),
              )),
              const SizedBox(height: 16),
            ],
            if (donations.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Donations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
              ),
              ...donations.map((d) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(d.driveTitle ?? 'Drive ${d.driveId}'),
                  subtitle: Text('${d.amount.toStringAsFixed(2)} · ${d.createdAt != null ? _formatDateStatic(d.createdAt!) : "—"}'),
                  leading: const Icon(Icons.volunteer_activism),
                ),
              )),
            ],
          ],
        );
      },
    );
  }

  static String _formatDateStatic(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

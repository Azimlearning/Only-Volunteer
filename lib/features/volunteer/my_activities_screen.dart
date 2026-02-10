import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/attendance.dart';
import '../../models/e_certificate.dart';
import '../../services/firestore_service.dart';

class MyActivitiesScreen extends StatelessWidget {
  const MyActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in to see your activities'));
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Attendance'), Tab(text: 'E-Certificates')]),
          Expanded(
            child: TabBarView(
              children: [
                FutureBuilder<List<Attendance>>(
                  future: FirestoreService().getAttendancesForUser(uid),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final list = snap.data!;
                    if (list.isEmpty) return const Center(child: Text('No attendance records yet'));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final a = list[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text('Listing: ${a.listingId}'),
                            subtitle: Text('Hours: ${a.hours ?? "—"} · ${a.verified ? "Verified" : "Pending"}'),
                          ),
                        );
                      },
                    );
                  },
                ),
                FutureBuilder<List<ECertificate>>(
                  future: FirestoreService().getCertificatesForUser(uid),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final list = snap.data!;
                    if (list.isEmpty) return const Center(child: Text('No e-certificates yet'));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final c = list[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(c.listingTitle),
                            subtitle: Text('${c.organizationName ?? ""} · ${c.hours ?? 0} hrs · Code: ${c.verificationCode ?? "—"}'),
                            trailing: const Icon(Icons.download),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

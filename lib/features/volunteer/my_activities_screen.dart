import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/attendance.dart';
import '../../models/e_certificate.dart';
import '../../models/donation.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class MyActivitiesScreen extends StatelessWidget {
  const MyActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in to see your activities'));
    }
    return DefaultTabController(
      length: 3,
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
                  'Track your volunteer hours, certificates, and donations',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Attendance'),
              Tab(text: 'E-Certificates'),
              Tab(text: 'Donations'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _downloadReport(context, uid),
                icon: const Icon(Icons.download),
                label: const Text('Download report'),
              ),
            ),
          ),
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
                            trailing: const Icon(Icons.card_membership),
                          ),
                        );
                      },
                    );
                  },
                ),
                FutureBuilder<List<Donation>>(
                  future: FirestoreService().getDonationsByUser(uid),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final list = snap.data!;
                    if (list.isEmpty) return const Center(child: Text('No donations yet'));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final d = list[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(d.driveTitle ?? 'Drive ${d.driveId}'),
                            subtitle: Text('${d.amount.toStringAsFixed(2)} · ${d.createdAt != null ? _formatDate(d.createdAt!) : "—"}'),
                            leading: const Icon(Icons.volunteer_activism),
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

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _downloadReport(BuildContext context, String uid) async {
    final auth = context.read<AuthNotifier>();
    final userName = auth.appUser?.displayName ?? auth.appUser?.email ?? 'User';
    final firestore = FirestoreService();
    final attendances = await firestore.getAttendancesForUser(uid);
    final certificates = await firestore.getCertificatesForUser(uid);
    final donations = await firestore.getDonationsByUser(uid);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('OnlyVolunteer Activity Report', style: pw.TextStyle(fontSize: 22))),
          pw.Paragraph(text: 'User: $userName'),
          pw.Paragraph(text: 'Generated: ${DateTime.now()}'),
          pw.Header(level: 1, child: pw.Text('Attendance')),
          pw.Table(
    border: pw.TableBorder.all(),
    children: [
      pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Listing ID')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Hours')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Status')),
        ],
      ),
      ...attendances.map((a) => pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(a.listingId)),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${a.hours ?? "—"}')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(a.verified ? 'Verified' : 'Pending')),
        ],
      )),
    ],
          ),
          pw.Header(level: 1, child: pw.Text('E-Certificates')),
          pw.Table(
    border: pw.TableBorder.all(),
    children: [
      pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Title')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Hours')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Code')),
        ],
      ),
      ...certificates.map((c) => pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(c.listingTitle)),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${c.hours ?? "—"}')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(c.verificationCode ?? "—")),
        ],
      )),
    ],
          ),
          pw.Header(level: 1, child: pw.Text('Donations')),
          pw.Table(
    border: pw.TableBorder.all(),
    children: [
      pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Drive')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Amount')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date')),
        ],
      ),
      ...donations.map((d) => pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(d.driveTitle ?? d.driveId)),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(d.amount.toStringAsFixed(2))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(d.createdAt != null ? '${d.createdAt!.toIso8601String().substring(0, 10)}' : "—")),
        ],
      )),
    ],
          ),
        ],
      ),
    );
    final bytes = await pdf.save();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report generated (${bytes.length} bytes). Use a file-save flow in browser to save.')),
      );
    }
  }
}

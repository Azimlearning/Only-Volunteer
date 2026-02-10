import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/donation_drive.dart';
import '../../services/firestore_service.dart';

class DonationDrivesScreen extends StatelessWidget {
  const DonationDrivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-drive'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().donationDrivesStream(),
        builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final drives = docs.map((d) => DonationDrive.fromFirestore(d)).toList();
        if (drives.isEmpty) return const Center(child: Text('No donation drives yet. Tap + to create one.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drives.length,
          itemBuilder: (_, i) {
            final d = drives[i];
            final progress = (d.goalAmount != null && d.goalAmount! > 0)
                ? (d.raisedAmount / d.goalAmount!).clamp(0.0, 1.0)
                : 0.0;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title, style: Theme.of(context).textTheme.titleMedium),
                    if (d.description != null) Text(d.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (d.ngoName != null) Text('By ${d.ngoName}', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 4),
                    Text('Raised: ${d.raisedAmount.toStringAsFixed(0)} / ${d.goalAmount?.toStringAsFixed(0) ?? "—"}'),
                  ],
                ),
              ),
            );
          },
        );
        },
      ),
    );
  }
}

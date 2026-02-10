import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/volunteer_listing.dart';
import '../../services/firestore_service.dart';

class VolunteerListingsScreen extends StatelessWidget {
  const VolunteerListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().volunteerListingsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final listings = docs.map((d) => VolunteerListing.fromFirestore(d)).toList();
        if (listings.isEmpty) return const Center(child: Text('No opportunities yet.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (_, i) {
            final l = listings[i];
            final slotsLeft = l.slotsTotal - l.slotsFilled;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(l.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (l.description != null) Text(l.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (l.organizationName != null) Text('${l.organizationName} · ${l.location ?? ""}'),
                    Text('Slots: $slotsLeft / ${l.slotsTotal}'),
                  ],
                ),
                isThreeLine: true,
                trailing: slotsLeft > 0
                    ? FilledButton(
                        onPressed: () => _apply(context, l.id),
                        child: const Text('Apply'),
                      )
                    : const Text('Full'),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _apply(BuildContext context, String listingId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to apply')));
      return;
    }
    try {
      await FirestoreService().applyToListing(listingId, uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

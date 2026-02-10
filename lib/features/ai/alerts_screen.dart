import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/alert.dart';
import '../../services/firestore_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().alertsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final alerts = docs.map((d) => Alert.fromFirestore(d)).toList();
        if (alerts.isEmpty) {
          return const Center(
            child: Text('No SOS or flood alerts at the moment. Check back for updates.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (_, i) {
            final a = alerts[i];
            final isFlood = a.type == AlertType.flood;
            final isSos = a.type == AlertType.sos;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isFlood ? Colors.blue[50] : (isSos ? Colors.red[50] : null),
              child: ListTile(
                leading: Icon(
                  isFlood ? Icons.water_drop : (isSos ? Icons.warning : Icons.info),
                  color: isFlood ? Colors.blue : (isSos ? Colors.red : null),
                ),
                title: Text(a.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (a.body != null) Text(a.body!),
                    if (a.region != null) Text('Region: ${a.region}', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

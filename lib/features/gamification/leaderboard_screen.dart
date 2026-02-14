import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppUser>>(
      future: FirestoreService().getLeaderboard(limit: 20),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('No leaderboard data yet.'));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('1 hr volunteering = 10 pts · Donation = bonus pts', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final u = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(u.displayName ?? u.email),
                      subtitle: Row(
                        children: [
                          if (u.badges.isNotEmpty) ...[
                            ...u.badges.take(3).map((b) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Chip(label: Text(b, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            )),
                          ] else
                            const Text('No badges yet'),
                        ],
                      ),
                      trailing: Text('${u.points} pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

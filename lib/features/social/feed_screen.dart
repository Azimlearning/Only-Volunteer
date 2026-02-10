import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/feed_post.dart';
import '../../services/firestore_service.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().feedPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final posts = docs.map((d) => FeedPost.fromFirestore(d)).toList();
        if (posts.isEmpty) return const Center(child: Text('No posts yet. Be the first to share!'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final p = posts[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(child: Text((p.authorName ?? p.authorId).substring(0, 1).toUpperCase())),
                        const SizedBox(width: 8),
                        Text(p.authorName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (p.text != null && p.text!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(p.text!),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () => FirestoreService().incrementLikes(p.id),
                        ),
                        Text('${p.likes}'),
                        const SizedBox(width: 16),
                        Text('${p.commentCount} comments'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

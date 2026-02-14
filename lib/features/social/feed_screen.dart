import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/feed_post.dart';
import '../../models/feed_comment.dart';
import '../../services/firestore_service.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreatePost(context),
        child: const Icon(Icons.add),
        tooltip: 'Create post',
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
              return _FeedPostCard(post: p);
            },
          );
        },
      ),
    );
  }

  void _openCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreatePostSheet(),
    );
  }
}

class _FeedPostCard extends StatefulWidget {
  const _FeedPostCard({required this.post});

  final FeedPost post;

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  bool _showComments = false;
  List<FeedComment>? _comments;

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
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
                Expanded(child: Text(p.authorName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600))),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'report') _reportPost(context, p.id);
                  },
                  itemBuilder: (_) => [const PopupMenuItem(value: 'report', child: Text('Report'))],
                ),
              ],
            ),
            if (p.text != null && p.text!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(p.text!),
            ],
            if (p.imageUrl != null && p.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              CachedNetworkImage(
                imageUrl: p.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
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
                InkWell(
                  onTap: () async {
                    setState(() => _showComments = !_showComments);
                    if (_showComments && _comments == null) {
                      final list = await FirestoreService().getCommentsForPost(p.id);
                      if (mounted) setState(() => _comments = list);
                    }
                  },
                  child: Text('${p.commentCount} comments'),
                ),
              ],
            ),
            if (_showComments && _comments != null) ...[
              const Divider(),
              ..._comments!.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 14, child: Text((c.userName ?? c.userId).substring(0, 1).toUpperCase())),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.userName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), if (c.text != null) Text(c.text!, style: const TextStyle(fontSize: 14))])),
                  ],
                ),
              )),
              _AddCommentRow(postId: p.id, onAdded: () async {
                final list = await FirestoreService().getCommentsForPost(p.id);
                if (mounted) setState(() => _comments = list);
              }),
            ],
          ],
        ),
      ),
    );
  }

  void _reportPost(BuildContext context, String postId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report post'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Reason (optional)'), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await FirestoreService().reportPost(postId, uid, controller.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _AddCommentRow extends StatefulWidget {
  const _AddCommentRow({required this.postId, required this.onAdded});

  final String postId;
  final VoidCallback onAdded;

  @override
  State<_AddCommentRow> createState() => _AddCommentRowState();
}

class _AddCommentRowState extends State<_AddCommentRow> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Write a comment...', isDense: true),
            onSubmitted: (_) => _send(),
          ),
        ),
        IconButton(
          onPressed: _sending ? null : _send,
          icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to comment')));
      return;
    }
    setState(() => _sending = true);
    try {
      final ref = FirebaseFirestore.instance.collection('feed_comments').doc();
      final comment = FeedComment(
        id: ref.id,
        postId: widget.postId,
        userId: uid,
        userName: FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email,
        text: text,
        createdAt: DateTime.now(),
      );
      await FirestoreService().addFeedComment(comment);
      _controller.clear();
      widget.onAdded();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }
}

class _CreatePostSheet extends StatefulWidget {
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _textController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter some text')));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to post')));
      return;
    }
    setState(() => _saving = true);
    try {
      final ref = FirebaseFirestore.instance.collection('feed_posts').doc();
      final post = FeedPost(
        id: ref.id,
        authorId: uid,
        authorName: FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email,
        text: text,
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        likes: 0,
        commentCount: 0,
        createdAt: DateTime.now(),
      );
      await FirestoreService().addFeedPost(post);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Create post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _textController, decoration: const InputDecoration(hintText: 'What\'s on your mind?'), maxLines: 4),
            const SizedBox(height: 12),
            TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL (optional)')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}

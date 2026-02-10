import 'package:cloud_firestore/cloud_firestore.dart';

class FeedPost {
  FeedPost({
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorPhotoUrl,
    this.text,
    this.imageUrl,
    this.listingId,
    this.driveId,
    this.likes = 0,
    this.commentCount = 0,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? text;
  final String? imageUrl;
  final String? listingId;
  final String? driveId;
  final int likes;
  final int commentCount;
  final DateTime? createdAt;

  factory FeedPost.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return FeedPost(
      id: doc.id,
      authorId: m['authorId'] as String? ?? '',
      authorName: m['authorName'] as String?,
      authorPhotoUrl: m['authorPhotoUrl'] as String?,
      text: m['text'] as String?,
      imageUrl: m['imageUrl'] as String?,
      listingId: m['listingId'] as String?,
      driveId: m['driveId'] as String?,
      likes: (m['likes'] as num?)?.toInt() ?? 0,
      commentCount: (m['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'imageUrl': imageUrl,
      'listingId': listingId,
      'driveId': driveId,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

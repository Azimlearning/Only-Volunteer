import 'package:cloud_firestore/cloud_firestore.dart';

class FeedComment {
  FeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.userName,
    this.text,
    this.createdAt,
  });

  final String id;
  final String postId;
  final String userId;
  final String? userName;
  final String? text;
  final DateTime? createdAt;

  factory FeedComment.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return FeedComment(
      id: doc.id,
      postId: m['postId'] as String? ?? '',
      userId: m['userId'] as String? ?? '',
      userName: m['userName'] as String?,
      text: m['text'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

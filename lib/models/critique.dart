import 'package:cloud_firestore/cloud_firestore.dart';

class Critique {
  final String critiqueId;
  final String postId;
  final String critiquerUid;
  final String critiquerName;
  final String critiquerProfileImage;
  final String comment;
  final double rating; // 1-5 stars
  final int likes;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Critique({
    required this.critiqueId,
    required this.postId,
    required this.critiquerUid,
    required this.critiquerName,
    required this.critiquerProfileImage,
    required this.comment,
    required this.rating,
    required this.likes,
    required this.likedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Critique.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Critique(
      critiqueId: doc.id,
      postId: data['postId'] ?? '',
      critiquerUid: data['critiquerUid'] ?? '',
      critiquerName: data['critiquerName'] ?? 'Anonymous',
      critiquerProfileImage: data['critiquerProfileImage'] ?? '',
      comment: data['comment'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'critiquerUid': critiquerUid,
      'critiquerName': critiquerName,
      'critiquerProfileImage': critiquerProfileImage,
      'comment': comment,
      'rating': rating,
      'likes': likes,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

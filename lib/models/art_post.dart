import 'package:cloud_firestore/cloud_firestore.dart';

class ArtPost {
  final String postId;
  final String artistUid;
  final String artistName;
  final String artistProfileImage;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> tags;
  final String medium; // Oil, Digital, Watercolor, etc.
  final String style; // Abstract, Realistic, etc.
  final double askingPrice;
  final int viewCount;
  final int likeCount;
  final int critiqueCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> imageUrls; // Multiple images

  ArtPost({
    required this.postId,
    required this.artistUid,
    required this.artistName,
    required this.artistProfileImage,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.tags,
    required this.medium,
    required this.style,
    required this.askingPrice,
    required this.viewCount,
    required this.likeCount,
    required this.critiqueCount,
    required this.likedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrls,
  });

  factory ArtPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtPost(
      postId: doc.id,
      artistUid: data['artistUid'] ?? '',
      artistName: data['artistName'] ?? 'Anonymous',
      artistProfileImage: data['artistProfileImage'] ?? '',
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      medium: data['medium'] ?? 'Mixed',
      style: data['style'] ?? 'Abstract',
      askingPrice: (data['askingPrice'] ?? 0.0).toDouble(),
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      critiqueCount: data['critiqueCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? [data['imageUrl'] ?? '']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'artistUid': artistUid,
      'artistName': artistName,
      'artistProfileImage': artistProfileImage,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'tags': tags,
      'medium': medium,
      'style': style,
      'askingPrice': askingPrice,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'critiqueCount': critiqueCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrls': imageUrls,
    };
  }
}

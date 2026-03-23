import 'package:cloud_firestore/cloud_firestore.dart';

class ArtistUser {
  final String uid;
  final String email;
  final String displayName;
  final String profileImageUrl;
  final String bio;
  final List<String> specialties; // painting, digital, sculpture, etc.
  final double averageRating;
  final int totalCritiques;
  final DateTime createdAt;

  ArtistUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.profileImageUrl,
    required this.bio,
    required this.specialties,
    required this.averageRating,
    required this.totalCritiques,
    required this.createdAt,
  });

  factory ArtistUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtistUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Anonymous',
      profileImageUrl: data['profileImageUrl'] ?? '',
      bio: data['bio'] ?? '',
      specialties: List<String>.from(data['specialties'] ?? []),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalCritiques: data['totalCritiques'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'specialties': specialties,
      'averageRating': averageRating,
      'totalCritiques': totalCritiques,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

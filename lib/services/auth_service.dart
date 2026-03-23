import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artist_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUp(
      String email, String password, String displayName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await result.user?.updateDisplayName(displayName);

      // Create user profile in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'profileImageUrl': '',
        'bio': '',
        'specialties': [],
        'averageRating': 0.0,
        'totalCritiques': 0,
        'createdAt': Timestamp.now(),
      });

      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<ArtistUser?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return ArtistUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ArtistUser>> getRecentArtists({
    String? excludeUserId,
    int limit = 6,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit + 6)
          .get();

      return snapshot.docs
          .map((doc) => ArtistUser.fromFirestore(doc))
          .where((artist) =>
              _isDiscoverableArtist(artist, excludeUserId: excludeUserId))
          .take(limit)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ArtistUser>> getPotentialMentors({
    String? excludeUserId,
    int limit = 3,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalCritiques', descending: true)
          .limit(limit + 8)
          .get();

      final mentors = snapshot.docs
          .map((doc) => ArtistUser.fromFirestore(doc))
          .where((artist) =>
              _isDiscoverableArtist(artist, excludeUserId: excludeUserId))
          .where(
              (artist) => artist.totalCritiques > 0 || artist.averageRating > 0)
          .take(limit)
          .toList();

      if (mentors.isNotEmpty) {
        return mentors;
      }

      return getRecentArtists(excludeUserId: excludeUserId, limit: limit);
    } catch (e) {
      return getRecentArtists(excludeUserId: excludeUserId, limit: limit);
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool _isDiscoverableArtist(ArtistUser artist, {String? excludeUserId}) {
    if (excludeUserId != null && artist.uid == excludeUserId) {
      return false;
    }

    return artist.displayName.trim().isNotEmpty;
  }
}

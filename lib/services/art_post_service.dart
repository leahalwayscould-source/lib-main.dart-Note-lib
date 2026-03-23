import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/art_post.dart';

class ArtPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createPost(ArtPost post) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('artPosts').add(post.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('artPosts').doc(postId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('artPosts').doc(postId).delete();
      // Also delete all critiques for this post
      QuerySnapshot critiquesSnapshot = await _firestore
          .collection('critiques')
          .where('postId', isEqualTo: postId)
          .get();
      for (DocumentSnapshot doc in critiquesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ArtPost?> getPost(String postId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('artPosts').doc(postId).get();
      if (doc.exists) {
        return ArtPost.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ArtPost>> getAllPosts() {
    return _firestore
        .collection('artPosts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList());
  }

  Stream<List<ArtPost>> getUserPosts(String artistUid) {
    return _firestore
        .collection('artPosts')
        .where('artistUid', isEqualTo: artistUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList());
  }

  Stream<List<ArtPost>> getPostsByTag(String tag) {
    return _firestore
        .collection('artPosts')
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList());
  }

  Future<List<ArtPost>> getRecentPosts({int limit = 12}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('artPosts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> incrementViewCount(String postId) async {
    try {
      await _firestore.collection('artPosts').doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore.collection('artPosts').doc(postId).update({
        'likeCount': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection('artPosts').doc(postId).update({
        'likeCount': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }
}

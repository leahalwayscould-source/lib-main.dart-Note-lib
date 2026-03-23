import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/critique.dart';

class CritiqueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createCritique(Critique critique) async {
    try {
      DocumentReference docRef = await _firestore.collection('critiques').add(critique.toMap());

      // Update the post's critique count
      await _firestore.collection('artPosts').doc(critique.postId).update({
        'critiqueCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCritique(String critiqueId, String postId) async {
    try {
      await _firestore.collection('critiques').doc(critiqueId).delete();

      // Update the post's critique count
      await _firestore.collection('artPosts').doc(postId).update({
        'critiqueCount': FieldValue.increment(-1),
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Critique>> getPostCritiques(String postId) {
    return _firestore
        .collection('critiques')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Critique.fromFirestore(doc)).toList());
  }

  Stream<List<Critique>> getUserCritiques(String critiquerUid) {
    return _firestore
        .collection('critiques')
        .where('critiquerUid', isEqualTo: critiquerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Critique.fromFirestore(doc)).toList());
  }

  Future<void> likeCritique(String critiqueId, String userId) async {
    try {
      await _firestore.collection('critiques').doc(critiqueId).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlikeCritique(String critiqueId, String userId) async {
    try {
      await _firestore.collection('critiques').doc(critiqueId).update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }
}

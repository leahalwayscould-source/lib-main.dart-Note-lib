import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/art_post.dart';
import '../models/artwork_order.dart';

class ArtworkOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ArtworkOrder>> getBuyerOrders(String userId) {
    return _firestore
        .collection('artworkOrders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ArtworkOrder.fromFirestore).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Future<ArtworkOrder> createSandboxOrder({
    required String userId,
    required String artistName,
    required String buyerEmail,
    required ArtPost post,
    required String checkoutReferenceId,
  }) async {
    final now = DateTime.now();
    final orderRef =
        _firestore.collection('artworkOrders').doc(checkoutReferenceId);

    final order = ArtworkOrder(
      orderId: orderRef.id,
      userId: userId,
      artistName: artistName,
      artworkId: post.postId,
      artworkTitle: post.title,
      amount: post.askingPrice,
      currency: 'usd',
      checkoutType: 'artwork_sandbox',
      status: 'sandbox_ready',
      createdAt: now,
      updatedAt: now,
      stripeSessionId: checkoutReferenceId,
      stripeCustomerId: buyerEmail,
      note:
          'Sandbox checkout prepared. Replace Stripe keys and deploy functions to collect real payment.',
    );

    await orderRef.set(order.toMap(), SetOptions(merge: true));
    return order;
  }

  Future<ArtworkOrder> createHostedCheckoutOrder({
    required String userId,
    required String artistName,
    required String buyerEmail,
    required ArtPost post,
    required String checkoutReferenceId,
    required String checkoutUrl,
  }) async {
    final now = DateTime.now();
    final orderRef =
        _firestore.collection('artworkOrders').doc(checkoutReferenceId);

    final order = ArtworkOrder(
      orderId: orderRef.id,
      userId: userId,
      artistName: artistName,
      artworkId: post.postId,
      artworkTitle: post.title,
      amount: post.askingPrice,
      currency: 'usd',
      checkoutType: 'artwork',
      status: 'checkout_created',
      createdAt: now,
      updatedAt: now,
      stripeSessionId: checkoutReferenceId,
      stripeCustomerId: buyerEmail,
      checkoutUrl: checkoutUrl,
      note:
          'Hosted checkout created. Complete payment in Stripe and this order will update after webhook confirmation.',
    );

    await orderRef.set(order.toMap(), SetOptions(merge: true));
    return order;
  }
}

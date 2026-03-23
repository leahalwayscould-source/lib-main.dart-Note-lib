import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deactivateActiveSubscriptions(String userId) async {
    final activeSubscriptions = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    if (activeSubscriptions.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in activeSubscriptions.docs) {
      batch.update(doc.reference, {
        'isActive': false,
        'endDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }

  Future<void> _syncUserSubscriptionSummary({
    required String userId,
    required String tier,
    required bool isActive,
    required String billingPeriod,
    required DateTime renewalDate,
    required String stripeCustomerId,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'subscriptionTier': tier,
      'subscriptionActive': isActive,
      'subscriptionBillingPeriod': billingPeriod,
      'subscriptionRenewalDate': Timestamp.fromDate(renewalDate),
      'stripeCustomerId': stripeCustomerId,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Get user's active subscription
  Future<Subscription?> getUserSubscription(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Subscription.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Check subscription status
  Future<bool> isSubscriptionActive(String userId) async {
    try {
      final subscription = await getUserSubscription(userId);
      if (subscription == null) return false;

      if (subscription.tier == 'elite') {
        return true; // Elite is lifetime
      }

      // Check if subscription hasn't expired
      return subscription.isActive &&
          subscription.renewalDate.isAfter(DateTime.now());
    } catch (e) {
      rethrow;
    }
  }

  // Create subscription in Firestore (called after Stripe payment)
  Future<String> createSubscription({
    required String userId,
    required String tier,
    required String billingPeriod,
    required String stripeSubscriptionId,
    required String stripeCustomerId,
    required double price,
  }) async {
    try {
      await _deactivateActiveSubscriptions(userId);

      DateTime renewalDate;
      DateTime? endDate;

      if (tier == 'elite') {
        renewalDate = DateTime(2099, 12, 31); // Lifetime
      } else if (tier == 'trial' || billingPeriod == 'trial') {
        renewalDate = DateTime.now().add(const Duration(days: 7));
        endDate = renewalDate;
      } else if (billingPeriod == 'monthly') {
        renewalDate = DateTime.now().add(const Duration(days: 30));
        endDate = renewalDate;
      } else {
        renewalDate = DateTime.now().add(const Duration(days: 365));
        endDate = renewalDate;
      }

      final subscription = Subscription(
        subscriptionId: '',
        userId: userId,
        tier: tier,
        price: price,
        billingPeriod: billingPeriod,
        isActive: true,
        startDate: DateTime.now(),
        endDate: endDate,
        stripeSubscriptionId: stripeSubscriptionId,
        stripeCustomerId: stripeCustomerId,
        renewalDate: renewalDate,
        postsUploaded: 0,
        isMentor: false,
        createdAt: DateTime.now(),
      );

      DocumentReference docRef = await _firestore
          .collection('subscriptions')
          .add(subscription.toMap());

      await _syncUserSubscriptionSummary(
        userId: userId,
        tier: tier,
        isActive: true,
        billingPeriod: billingPeriod,
        renewalDate: renewalDate,
        stripeCustomerId: stripeCustomerId,
      );

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> startFreeTrial(String userId) async {
    try {
      final existingTrial = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('tier', isEqualTo: 'trial')
          .limit(1)
          .get();

      if (existingTrial.docs.isNotEmpty) {
        throw Exception('Trial already used for this account.');
      }

      return createSubscription(
        userId: userId,
        tier: 'trial',
        billingPeriod: 'trial',
        stripeSubscriptionId: 'trial_${DateTime.now().millisecondsSinceEpoch}',
        stripeCustomerId: '',
        price: 0,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'isActive': false,
        'endDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Upgrade subscription
  Future<void> upgradeSubscription({
    required String userId,
    required String newTier,
    required String newStripeSubscriptionId,
  }) async {
    try {
      // Create new subscription
      final plan = subscriptionPlans[newTier];
      await createSubscription(
        userId: userId,
        tier: newTier,
        billingPeriod: 'monthly',
        stripeSubscriptionId: newStripeSubscriptionId,
        stripeCustomerId: '', // Get from old subscription
        price: plan?.monthlyPrice ?? 0,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Check upload limit
  Future<bool> canUploadArt(String userId) async {
    try {
      final subscription = await getUserSubscription(userId);

      if (subscription == null) {
        // Free tier - limit 5 uploads per month
        return await _checkFreeUserUploadLimit(userId);
      }

      if (subscription.canUnlimitedUpload) {
        return true; // Premium and Elite have unlimited
      }

      if (subscription.isTrial) {
        return true; // Trial gets full upload access during trial window
      }

      // Basic tier - limit
      return await _checkBasicUserUploadLimit(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> _checkFreeUserUploadLimit(String userId) async {
    try {
      DateTime monthAgo = DateTime.now().subtract(Duration(days: 30));
      QuerySnapshot result = await _firestore
          .collection('artPosts')
          .where('artistUid', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(monthAgo))
          .get();

      return result.docs.length < 5; // Free: 5 uploads per month
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> _checkBasicUserUploadLimit(String userId) async {
    try {
      DateTime monthAgo = DateTime.now().subtract(Duration(days: 30));
      QuerySnapshot result = await _firestore
          .collection('artPosts')
          .where('artistUid', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(monthAgo))
          .get();

      return result.docs.length < 20; // Basic: 20 uploads per month
    } catch (e) {
      rethrow;
    }
  }

  // Get subscription history
  Stream<List<Subscription>> getUserSubscriptionHistory(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subscription.fromFirestore(doc))
            .toList());
  }

  // Update mentor status (for Elite members)
  Future<void> setMentorStatus(String userId, bool isMentor) async {
    try {
      QuerySnapshot subscriptions = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in subscriptions.docs) {
        await doc.reference.update({'isMentor': isMentor});
      }
    } catch (e) {
      rethrow;
    }
  }
}

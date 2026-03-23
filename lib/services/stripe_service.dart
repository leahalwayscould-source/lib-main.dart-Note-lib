import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StripeCheckoutResult {
  const StripeCheckoutResult({
    required this.checkoutReferenceId,
    required this.customerId,
    required this.providerReferenceId,
    required this.checkoutUrl,
    required this.isSandbox,
    required this.message,
  });

  final String checkoutReferenceId;
  final String customerId;
  final String providerReferenceId;
  final String? checkoutUrl;
  final bool isSandbox;
  final String message;
}

class StripeService {
  static const String stripePublishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const Map<String, Map<String, String>> stripePriceIds = {
    'basic_monthly': {
      'priceId': 'price_basic_monthly',
      'lookup': 'basic_monthly'
    },
    'basic_yearly': {'priceId': 'price_basic_yearly', 'lookup': 'basic_yearly'},
    'premium_monthly': {
      'priceId': 'price_premium_monthly',
      'lookup': 'premium_monthly'
    },
    'premium_yearly': {
      'priceId': 'price_premium_yearly',
      'lookup': 'premium_yearly'
    },
    'elite_lifetime': {
      'priceId': 'price_elite_lifetime',
      'lookup': 'elite_lifetime'
    },
  };

  // Get price ID for checkout session
  static String getPriceId(String tier, String billingPeriod) {
    final key = '${tier}_$billingPeriod';
    return stripePriceIds[key]?['priceId'] ?? '';
  }

  static String getLookupKey(String tier, String billingPeriod) {
    final key = '${tier}_$billingPeriod';
    return stripePriceIds[key]?['lookup'] ?? key;
  }

  static bool get _hasRealPublishableKey {
    return stripePublishableKey.startsWith('pk_') &&
        !stripePublishableKey.contains('YOUR_PUBLISHABLE_KEY');
  }

  static bool get _hasRealPriceIds {
    final livePriceIdPattern = RegExp('^price_[A-Za-z0-9]+\$');
    return stripePriceIds.values.every((config) {
      final priceId = config['priceId'] ?? '';
      return livePriceIdPattern.hasMatch(priceId);
    });
  }

  static bool get isConfigured {
    return _hasRealPublishableKey && _hasRealPriceIds;
  }

  static String buildMockCustomerId(String userId) {
    return 'mock_cus_${userId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<StripeCheckoutResult> createSubscriptionCheckout({
    required String userId,
    required String tier,
    required String billingPeriod,
    required String email,
    required double amount,
    String? name,
  }) async {
    if (isConfigured) {
      try {
        final callable = _functions.httpsCallable('createCheckoutSession');
        final response = await callable.call(<String, dynamic>{
          'priceId': getPriceId(tier, billingPeriod),
          'lookupKey': getLookupKey(tier, billingPeriod),
          'tier': tier,
          'billingPeriod': billingPeriod,
          'email': email,
          'name': name ?? '',
        });

        final data = Map<String, dynamic>.from(response.data as Map);
        final customerId = (data['customerId'] as String?) ?? '';

        if (customerId.isNotEmpty) {
          await saveCustomerId(userId: userId, customerId: customerId);
        }

        return StripeCheckoutResult(
          checkoutReferenceId: (data['sessionId'] as String?) ?? '',
          customerId: customerId,
          providerReferenceId: (data['sessionId'] as String?) ?? '',
          checkoutUrl: data['checkoutUrl'] as String?,
          isSandbox: false,
          message: (data['message'] as String?) ??
              'Stripe Checkout session created. Complete payment before the subscription becomes active.',
        );
      } on FirebaseFunctionsException catch (error) {
        throw Exception(
          error.message ?? 'Failed to create Stripe Checkout session.',
        );
      }
    }

    final customerId = buildMockCustomerId(userId);
    final providerReferenceId = tier == 'elite'
        ? 'pi_${DateTime.now().millisecondsSinceEpoch}'
        : 'sub_${DateTime.now().millisecondsSinceEpoch}';

    await saveCustomerId(userId: userId, customerId: customerId);

    return StripeCheckoutResult(
      checkoutReferenceId: 'sandbox_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      providerReferenceId: providerReferenceId,
      checkoutUrl: null,
      isSandbox: true,
      message:
          'Stripe is running in sandbox mode because publishable keys or price IDs are still placeholders.',
    );
  }

  static Future<StripeCheckoutResult> createArtworkCheckout({
    required String userId,
    required String email,
    required double amount,
    required String artworkId,
    required String artworkTitle,
    required String artistName,
    String? name,
    String currency = 'usd',
  }) async {
    if (isConfigured) {
      try {
        final callable =
            _functions.httpsCallable('createArtworkCheckoutSession');
        final response = await callable.call(<String, dynamic>{
          'email': email,
          'amount': amount,
          'currency': currency,
          'artworkId': artworkId,
          'artworkTitle': artworkTitle,
          'artistName': artistName,
          'name': name ?? '',
        });

        final data = Map<String, dynamic>.from(response.data as Map);
        final customerId = (data['customerId'] as String?) ?? '';

        if (customerId.isNotEmpty) {
          await saveCustomerId(userId: userId, customerId: customerId);
        }

        return StripeCheckoutResult(
          checkoutReferenceId: (data['sessionId'] as String?) ?? '',
          customerId: customerId,
          providerReferenceId: (data['sessionId'] as String?) ?? '',
          checkoutUrl: data['checkoutUrl'] as String?,
          isSandbox: false,
          message: (data['message'] as String?) ??
              'Artwork checkout session created. Complete payment in Stripe.',
        );
      } on FirebaseFunctionsException catch (error) {
        throw Exception(
          error.message ?? 'Failed to create artwork checkout session.',
        );
      }
    }

    final customerId = buildMockCustomerId(userId);
    await saveCustomerId(userId: userId, customerId: customerId);

    return StripeCheckoutResult(
      checkoutReferenceId:
          'sandbox_artwork_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      providerReferenceId:
          'artwork_pi_${DateTime.now().millisecondsSinceEpoch}',
      checkoutUrl: null,
      isSandbox: true,
      message:
          'Stripe is running in sandbox mode, so artwork payment checkout cannot open yet. You can still send a purchase inquiry.',
    );
  }

  // Create checkout session (call backend Cloud Function)
  static Future<String> createCheckoutSession({
    required String userId,
    required String tier,
    required String billingPeriod,
    required String email,
  }) async {
    final result = await createSubscriptionCheckout(
      userId: userId,
      tier: tier,
      billingPeriod: billingPeriod,
      email: email,
      amount: 0,
    );

    if (result.checkoutUrl == null || result.checkoutUrl!.isEmpty) {
      throw Exception(
        'Stripe checkout URL is not available until live Stripe configuration is completed.',
      );
    }

    return result.checkoutUrl!;
  }

  // Save Stripe customer ID
  static Future<void> saveCustomerId({
    required String userId,
    required String customerId,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'stripeCustomerId': customerId,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Create payment intent for one-time payment (Elite lifetime)
  static Future<String> createPaymentIntent({
    required String userId,
    required double amount, // in cents: 50000 = $500
    required String currency, // 'usd'
  }) async {
    try {
      // In production, call a Firebase Cloud Function
      // POST /createPaymentIntent
      // with { userId, amount, currency }

      return 'pi_mock_payment_intent_id';
    } catch (e) {
      rethrow;
    }
  }

  // Confirm payment
  static Future<bool> confirmPayment({
    required String paymentIntentId,
    required String clientSecret,
  }) async {
    try {
      // Use flutter_stripe to confirm the payment on client
      // Implementation requires flutter_stripe package
      return true;
    } catch (e) {
      rethrow;
    }
  }
}

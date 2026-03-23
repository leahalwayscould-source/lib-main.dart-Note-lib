# Phase 1: Real Image Upload & Stripe Integration

## ✅ Part 1: Real Image Upload (COMPLETE)

Your upload flow now supports **real image uploads to Firebase Storage** with:
- ✅ Image picker from gallery
- ✅ Firebase Storage upload with progress tracking
- ✅ Upload progress bar (0-100%)
- ✅ Image preview with remove button
- ✅ Size limit enforcement (50 MB max)
- ✅ Automatic compression (85% quality)

### Files Modified
- `lib/screens/home/upload_art_screen.dart` - Full image upload implementation

### Files Created
- `storage.rules` - Firebase Storage security rules

---

## 🚀 Deploy Firebase Storage Rules

To enable real image uploads, deploy the storage rules:

```bash
firebase deploy --only storage
```

Or in Firebase Console:
1. Go to **Storage** → **Rules** tab
2. Copy content from [storage.rules](storage.rules)
3. Click "Publish"

---

## 🧪 Test Real Image Upload

1. **Run app** on iOS/Android/web
2. Go to **Gallery** tab
3. Click **"Upload"** button
4. Fill in art details (title, description, etc.)
5. Click **"Pick Image from Gallery"**
6. Select an image from your device
7. You'll see image preview with thumbnail
8. Click **"Upload Art"** button
9. Watch progress bar (0-100%)
10. On success → Image stored in Firebase Storage + metadata in Firestore

**Expected result:**
- Image appears in gallery within 2-3 seconds
- Real image shows instead of placeholder
- Upload progress visible in real-time

---

## 🔗 Part 2: Real Stripe Integration (NEXT)

### What's Happening Next

**Current State:**
- ✅ Checkout screen with form validation
- ✅ Test card support (4242 4242 4242 4242)
- ✅ Mock payment processing (simulated 2-second wait)

**What We'll Add:**
- ✅ Flutter Stripe package
- ✅ Firebase Cloud Function for checkout sessions
- ✅ Real Stripe API integration
- ✅ Webhook handlers for payment confirmations
- ✅ Subscription creation on successful payment

### Implementation Steps

#### Step 1: Add Flutter Stripe Package (5 min)

```bash
flutter pub add flutter_stripe
flutter pub get
```

Update `pubspec.yaml` - it should look like:
```yaml
dependencies:
  flutter_stripe: ^10.0.0
  # ... other dependencies
```

#### Step 2: Get Stripe API Keys (5 min)

1. Go to [dashboard.stripe.com](https://dashboard.stripe.com)
2. Sign up or login
3. Switch to **test mode** (top toggle)
4. Go to **Developers** → **API keys**
5. Copy:
   - **Publishable Key** (pk_test_...)
   - **Secret Key** (sk_test_...) - keep this private!

#### Step 3: Initialize Stripe in Main App (10 min)

Update `lib/main.dart` to initialize Stripe:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Stripe
  Stripe.publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';
  await Stripe.instance.applySettings();
  
  runApp(const MyApp());
}
```

#### Step 4: Create Firebase Cloud Function (30 min)

Create `functions/src/createCheckoutSession.js`:

```javascript
const functions = require('firebase-functions');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const admin = require('firebase-admin');

exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price: data.priceId,
        quantity: 1,
      }],
      mode: data.mode || 'subscription',
      customer_email: data.email,
      client_reference_id: context.auth.uid,
      success_url: `${process.env.APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.APP_URL}/cancel`,
    });

    // Save Stripe customer ID
    const userRef = admin.firestore().collection('users').doc(context.auth.uid);
    await userRef.update({
      stripeCustomerId: session.customer,
      lastSubscriptionUpdate: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { sessionId: session.id };
  } catch (error) {
    console.error('Error creating checkout session:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create checkout session');
  }
});
```

#### Step 5: Update StripeService (20 min)

Update `lib/services/stripe_service.dart` to use real Stripe:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StripeService {
  static final _firebaseFunctions = FirebaseFunctions.instance;

  static Future<String> createCheckoutSession(
    String userId,
    String priceId,
    String email,
  ) async {
    try {
      final callable = _firebaseFunctions.httpsCallable('createCheckoutSession');
      final result = await callable.call({
        'priceId': priceId,
        'email': email,
      });
      return result.data['sessionId']!;
    } catch (e) {
      throw Exception('Failed to create checkout session: $e');
    }
  }

  static Future<void> redirectToCheckout(String sessionId) async {
    try {
      await Stripe.instance.redirectToCheckout(
        sessionId: sessionId,
      );
    } catch (e) {
      throw Exception('Error redirecting to checkout: $e');
    }
  }
}
```

#### Step 6: Update Checkout Screen (15 min)

Update `lib/screens/home/checkout_screen.dart` to use real Stripe:

```dart
Future<void> _processPayment() async {
  // ... validation code ...

  try {
    final sessionId = await StripeService.createCheckoutSession(
      userId,
      priceId,
      _emailController.text,
    );

    // Redirect to Stripe checkout
    await StripeService.redirectToCheckout(sessionId);

    // On success, create subscription record
    await _subscriptionService.createSubscription(
      userId,
      selectedPlan,
      billingPeriod,
      price,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription created successfully!')),
    );
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: $e')),
    );
  }
}
```

#### Step 7: Deploy Cloud Function

```bash
cd functions
npm install stripe firebase-admin firebase-functions
firebase deploy --only functions:createCheckoutSession
```

#### Step 8: Add Stripe Test Cards

For testing, use these Stripe test cards:

| Card | Number | Expiry | CVC |
|------|--------|--------|-----|
| Success | 4242 4242 4242 4242 | 12/25 | 123 |
| Decline | 4000 0000 0000 0002 | 12/25 | 123 |
| Expired | 4000 0000 0000 0069 | 01/20 | 123 |

---

## 📋 Checklist for Phase 1

### Real Image Upload
- [ ] Deploy `storage.rules` to Firebase
- [ ] Test image picker from gallery
- [ ] Upload progress bar shows during upload
- [ ] Image appears in gallery after upload
- [ ] Upload limit enforced (free user max 5/month)

### Real Stripe Integration
- [ ] Add `flutter_stripe` package
- [ ] Get Stripe test API keys
- [ ] Initialize Stripe in main.dart
- [ ] Create Cloud Function for checkout
- [ ] Update StripeService with real calls
- [ ] Deploy Cloud Function
- [ ] Test payment with test card (4242...)
- [ ] Subscription created in Firestore on success

---

## 🎯 Success Criteria: Phase 1 Complete

✅ **Users can:**
- Upload real images from device gallery
- See upload progress in real-time
- Have image stored in Firebase Storage
- See their uploaded image in gallery
- Have upload limits enforced per subscription tier

✅ **Payment flow:**
- Navigate to checkout
- Enter card details (or use test card)
- Click "Pay"
- Redirected to real Stripe checkout (if integrated)
- Subscription created after payment
- Return to app with success message

✅ **No errors:**
- Image upload successful without crashes
- Payment processing completes smoothly
- Firestore records created correctly
- Security rules allowing proper access

---

## 🐛 Troubleshooting Phase 1

### Image Upload Issues

**Problem:** "Failed to pick image"
- Check iOS/Android permissions for gallery access
- Ensure image file exists and is not corrupted

**Problem:** Upload stuck at 0%
- Check Firebase Storage rules are deployed
- Verify user is authenticated
- Check Firebase console for errors

**Problem:** Image doesn't appear in gallery
- Check Firestore `artPosts` collection for new record
- Verify image URL in document exists
- Check Firebase Storage bucket

### Stripe Integration Issues

**Problem:** "Cloud Function not found"
- Ensure function is deployed: `firebase deploy --only functions`
- Check Firebase console Functions tab for errors
- Wait 1-2 minutes after deployment

**Problem:** Payment redirect fails
- Verify Stripe publishable key is set correctly
- Check test card number is valid
- Ensure session ID is valid string

**Problem:** Subscription not created
- Check Firestore `subscriptions` collection
- Verify webhook headers match
- Check Cloud Function logs

---

## 🔐 Security Notes

1. **Storage:** Only authenticated users can upload, files size-limited to 50 MB
2. **Payment:** Never handle card data directly - use Stripe (PCI compliant)
3. **API Keys:** Keep secret key private, only use publishable key in Flutter
4. **Webhooks:** Verify Stripe signatures before processing

---

## 📚 Next Steps After Phase 1

Once Phase 1 is complete:
- Real images upload and store in Firebase Storage ✅
- Real payments process through Stripe ✅
- Subscriptions activate on checkout success ✅

Then move to **Phase 2: Rich Features** (email notifications, reviews, follow artists, etc.)

---

## 🆘 Need Help?

- **Flutter Stripe Docs:** https://pub.dev/packages/flutter_stripe
- **Stripe API:** https://stripe.com/docs/api
- **Firebase Cloud Functions:** https://firebase.google.com/docs/functions
- **Storage Rules:** https://firebase.google.com/docs/storage/security

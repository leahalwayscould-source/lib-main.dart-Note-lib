# Subscription System Integration Guide

## Quick Start

This guide walks you through integrating the subscription system into your existing ArtConnect app.

## Step 1: Add Subscription Service Dependency

The subscription system requires the following packages (most already in pubspec.yaml):
- `firebase_core`
- `cloud_firestore`
- `firebase_auth`

For full Stripe integration, add to `pubspec.yaml`:
```yaml
flutter_stripe: ^10.0.0  # For real payment processing
```

Run:
```bash
flutter pub get
```

## Step 2: Update Home Screen Navigation

### Option A: Add Subscriptions Tab

In `lib/screens/home/home_screen.dart`, modify the `_tabNameList` and tab switching logic:

```dart
static const _tabNameList = [
  'Gallery',
  'Pricing',
  'Mockup',
  'Profile',
  'Subscriptions',  // Add this line
];

// In the build method, update the tab view:
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('ArtConnect'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.grey[900],
    ),
    body: _getTabBody(_currentTabIndex),
    bottomNavigationBar: GoogleNavBar(
      // ... existing config ...
      tabs: [
        GButton(icon: Icons.image_outlined, text: 'Gallery'),
        GButton(icon: Icons.calculate, text: 'Pricing'),
        GButton(icon: Icons.wallpaper, text: 'Mockup'),
        GButton(icon: Icons.person, text: 'Profile'),
        GButton(icon: Icons.card_membership, text: 'Premium'),  // Add this
      ],
    ),
  );
}

// Add a new case in _getTabBody method:
Widget _getTabBody(int tabIndex) {
  switch (tabIndex) {
    case 0:
      return const GalleryTab();
    case 1:
      return const PricingTab();
    case 2:
      return const MockupTab();
    case 3:
      return const ProfileTab();
    case 4:
      return const SubscriptionManagementScreen();  // Add this
    default:
      return const GalleryTab();
  }
}
```

### Option B: Add Subscriptions to Settings/Menu

Alternatively, add a "Get Premium" quick action button in the AppBar:

```dart
AppBar(
  title: const Text('ArtConnect'),
  actions: [
    IconButton(
      icon: const Icon(Icons.card_membership),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscriptionManagementScreen(),
          ),
        );
      },
    ),
  ],
)
```

## Step 3: Update Upload Art Screen

In `lib/screens/home/upload_art_screen.dart`, add upload limit checking:

**Before uploading, add this check in your upload function:**

```dart
import '../../services/subscription_service.dart';

Future<void> _uploadArt() async {
  final subscriptionService = SubscriptionService();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  
  // Check if user can upload based on their tier
  final canUpload = await subscriptionService.canUploadArt(userId);
  
  if (!canUpload) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload Limit Reached'),
          content: const Text('You\'ve reached your monthly upload limit. Upgrade to a higher tier for more uploads!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              child: const Text('Upgrade Now'),
            ),
          ],
        ),
      );
    }
    return;
  }
  
  // Proceed with upload as normal...
  // Your existing upload code here
}
```

## Step 4: Add Imports to Your Screens

Add these imports to `home_screen.dart`:

```dart
import 'subscription_management_screen.dart';
import 'subscription_plans_screen.dart';
```

## Step 5: Test Subscription Features

### Test Free User Flow
1. Create new account
2. Try to upload 6 artworks (should fail on 6th)
3. Navigate to subscriptions tab
4. Browse plans and features

### Test Upgrade Flow
1. Click "Subscribe" on a plan
2. Fill in checkout form with test data:
   - Email: test@example.com
   - Name: Test User
   - Card: 4242 4242 4242 4242
   - Expiry: 12/25
   - CVC: 123
3. Click "Pay"
4. Verify subscription created in Firestore
5. Try uploading again (should succeed up to tier limit)

### Test Managed Subscription
1. Access Subscriptions tab after subscribing
2. Verify current plan, renewal date, and features display
3. Try upgrading to higher tier
4. Test cancel subscription functionality

## Step 6: Setup Firestore Security Rules

**Update your Firebase Firestore rules** to enable subscription functionality:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow users to read their own subscriptions
    match /subscriptions/{document=**} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid != null;
      allow update, delete: if false;  // Only Cloud Functions can modify
    }
    
    // Allow users to read/write their own docs
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }
    
    // Allow users to read upload history
    match /uploadHistory/{document=**} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid != null;
    }
    
    // Allow public read of art posts
    match /artPosts/{document=**} {
      allow read: if true;
      allow create: if request.auth.uid == resource.data.userId;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
  }
}
```

## Step 7: (Optional) Setup Stripe Integration

For real payment processing, follow these additional steps:

### A. Create Stripe Account & Get API Keys

1. Go to [stripe.com](https://stripe.com)
2. Create account (use test mode initially)
3. Get **Publishable Key** and **Secret Key** from dashboard
4. Configure your Stripe products and pricing:
   - Basic Monthly: $9.99
   - Basic Yearly: $99.00
   - Premium Monthly: $29.99
   - Premium Yearly: $299.00
   - Elite (Lifetime): $500.00

### B. Create Firebase Cloud Function

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
      billing_address_collection: 'auto',
      customer_email: data.email,
      client_reference_id: context.auth.uid,
      success_url: `${process.env.APP_URL}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.APP_URL}/subscription/cancel`,
    });

    // Save customer ID if new
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

### C. Deploy Cloud Function

```bash
cd functions
firebase deploy --only functions:createCheckoutSession
```

### D. Update StripeService

In `lib/services/stripe_service.dart`, replace the mock implementation with real Stripe calls:

```dart
Future<String> createCheckoutSession(
  String userId,
  String priceId,
  String email,
) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('createCheckoutSession');
    final result = await callable.call({
      'priceId': priceId,
      'email': email,
    });
    return result.data['sessionId']!;
  } catch (e) {
    throw Exception('Failed to create checkout session: $e');
  }
}
```

## Step 8: Add Environment Variables (if using Stripe)

Create `.env` file in functions directory:
```
STRIPE_SECRET_KEY=sk_test_xxxxx
APP_URL=https://your-app.com
```

## Testing Checklist

- [ ] Free tier user cannot exceed 5 uploads/month
- [ ] Basic tier user cannot exceed 20 uploads/month
- [ ] Premium tier user has unlimited uploads
- [ ] Elite tier user shows lifetime access
- [ ] Upgrade button navigates to checkout
- [ ] Checkout form validates all fields
- [ ] Cancel subscription removes active status
- [ ] Subscription management screen shows current plan
- [ ] Test card charges succeed in dev mode
- [ ] Billing history displays correctly
- [ ] FAQ section expands/collapses

## Troubleshooting

### Issue: Subscription service not found
**Solution:** Ensure all files are in correct directories:
- Models: `lib/models/subscription.dart`
- Services: `lib/services/subscription_service.dart`, `lib/services/stripe_service.dart`
- Screens: `lib/screens/home/subscription_*.dart`

### Issue: Upload limit not working
**Solution:** 
1. Verify `canUploadArt()` is called before upload
2. Check Cloud Firestore `uploadHistory` collection has entries
3. Verify subscription tier is correctly saved in Firestore

### Issue: Stripe integration not working
**Solution:**
1. Verify Stripe API keys are correct
2. Check Cloud Function logs: `firebase functions:log`
3. Ensure flutter_stripe package is installed
4. Test with Stripe test cards (4242...)

### Issue: Firestore permission errors
**Solution:** 
1. Update Firestore rules as shown in Step 6
2. Ensure user is authenticated
3. Check collection names match exactly

## Next Steps

1. **Production Stripe Keys** - Replace test keys with live keys when ready
2. **Email Notifications** - Send confirmation emails on subscription changes
3. **Usage Analytics** - Track subscription metrics (MRR, churn, LTV)
4. **Customer Portal** - Link to Stripe customer portal for billing management
5. **Coupon System** - Add promotional codes and discounts

## Support

For issues with:
- **Flutter/Dart:** Check Flutter documentation
- **Firebase:** See Firebase console
- **Stripe:** Check Stripe dashboard and webhook logs
- **This system:** Review SUBSCRIPTION_SYSTEM.md documentation

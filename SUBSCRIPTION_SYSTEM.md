# Subscription System Documentation

## Overview

The subscription system provides a three-tier monetization model for the ArtConnect application. Users can upgrade from a free account to Basic, Premium, or Elite subscription tiers, each offering progressively more features and capabilities.

## Subscription Tiers

### Free Plan
- **Price:** Free
- **Upload Limit:** 5 artworks per month
- **Features:**
  - Basic gallery access
  - Like and view artworks
  - Leave critiques
  - Limited profile features
- **Renewal:** N/A

### Basic Plan
- **Price:** $9.99/month or $99/year (20% discount)
- **Upload Limit:** 20 artworks per month
- **Features:**
  - Unlimited critique creation
  - Enhanced profile visibility
  - Monthly email newsletter
  - Priority support (email within 24 hours)
  - Ad-free experience
- **Renewal:** Monthly or Yearly

### Premium Plan
- **Price:** $29.99/month or $299/year (20% discount)
- **Upload Limit:** Unlimited
- **Features:**
  - All Basic features
  - Unlimited artwork uploads
  - Featured artist badge
  - Advanced analytics dashboard
  - Portfolio website link
  - Direct messaging with other artists
  - Monthly art challenges with prizes
  - 1-on-1 mentorship availability
- **Renewal:** Monthly or Yearly

### Elite Plan (Lifetime)
- **Price:** $500 (one-time payment)
- **Upload Limit:** Unlimited lifetime
- **Features:**
  - All Premium features
  - Lifetime access (no renewal)
  - Mentor status badge
  - Can mentor up to 10 free users
  - Lifetime portfolio hosting
  - Custom artist website
  - Exclusive Elite community access
  - Annual Elite conference access
  - Merchandise collaboration opportunities
- **Renewal:** Never (lifetime access)

## File Structure

### Models (`lib/models/subscription.dart`)

**Subscription Class**
```dart
class Subscription {
  final String subscriptionId;
  final String userId;
  final String tier;           // 'basic', 'premium', 'elite'
  final DateTime startDate;
  final DateTime renewalDate;
  final double price;
  final String billingPeriod;  // 'monthly' or 'yearly'
  final bool isActive;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
}
```

**Key Computed Properties:**
- `isLifetime` - True for Elite plan
- `canUnlimitedUpload` - True for Premium and Elite
- `hasPrioritySupport` - True for Basic and above
- `isMentor` - True for Elite members

**SubscriptionPlan Class**
```dart
class SubscriptionPlan {
  final String id;           // 'basic', 'premium', 'elite'
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final int uploadLimitPerMonth;
}
```

### Services

#### SubscriptionService (`lib/services/subscription_service.dart`)

**Core Methods:**

1. **getUserSubscription(userId)**
   - Fetches active subscription from Firestore
   - Returns `Subscription?` (null if no active subscription)

2. **isSubscriptionActive(userId)**
   - Checks if subscription is valid and not expired
   - Handles both monthly and lifetime subscriptions

3. **createSubscription(userId, planId, billingPeriod, price)**
   - Creates new subscription record in Firestore
   - Called after successful Stripe payment
   - Sets renewal date based on billing period

4. **cancelSubscription(subscriptionId)**
   - Sets `isActive` to false
   - Keeps historical record in Firestore
   - Called when user cancels mid-cycle

5. **upgradeSubscription(subscriptionId, newPlanId)**
   - Updates existing subscription to new tier
   - Adjusts renewal date for proration
   - Calculates price difference for upgrade credit

6. **canUploadArt(userId)**
   - Returns `Future<bool>` indicating if user can upload
   - Checks upload limit against monthly count
   - Free users: 5/month, Basic: 20/month, Premium/Elite: unlimited

7. **getUserSubscriptionHistory(userId)**
   - Returns `Stream<List<Subscription>>`
   - All past and current subscriptions (useful for analytics)

8. **setMentorStatus(userId, isMentor)**
   - Updates Elite member mentor flag
   - Allows Elite members to mentor free users

#### StripeService (`lib/services/stripe_service.dart`)

**Configuration:**
```dart
final stripePriceIds = {
  'basic_monthly': 'price_basic_monthly',
  'basic_yearly': 'price_basic_yearly',
  'premium_monthly': 'price_premium_monthly',
  'premium_yearly': 'price_premium_yearly',
  'elite': 'price_elite',
};
```

**Core Methods:**

1. **getPriceId(planId, billingPeriod)**
   - Maps plan and billing period to Stripe price ID
   - Used during checkout initialization

2. **createCheckoutSession(userId, planId, billingPeriod)**
   - Creates Stripe checkout session
   - **Current Status:** Scaffold only - requires:
     - Firebase Cloud Function implementation
     - Stripe API integration
   - Returns checkout URL for redirect

3. **createPaymentIntent(userId, amount)**
   - For one-time Elite payment ($500)
   - Initialize Stripe payment intent

4. **confirmPayment(intentId)**
   - Complete payment processing
   - Called from checkout screen after form submission

5. **saveCustomerId(userId, customerId)**
   - Store Stripe customer ID in Firestore
   - Link user account to Stripe customer for future charges

### UI Screens

#### SubscriptionPlansScreen (`lib/screens/home/subscription_plans_screen.dart`)

**Purpose:** Display all available plans and allow user selection

**Key Features:**
- Billing period toggle (Monthly/Yearly) with 20% savings display
- Plan cards showing:
  - Plan name and description
  - Price (updates with toggle)
  - Feature list with ✓/✗ indicators
  - Current plan badge (if subscribed to this tier)
  - Action button (Upgrade/Subscribe/Current Plan)
- Current subscription info display
- FAQ section with 5 common questions

**Workflow:**
1. User lands on screen and sees 3-4 plan options
2. Toggles between monthly/yearly billing
3. Reviews features and pricing
4. Clicks "Subscribe" or "Upgrade"
5. Navigates to CheckoutScreen

#### CheckoutScreen (`lib/screens/home/checkout_screen.dart`)

**Purpose:** Complete subscription purchase

**Key Sections:**
1. **Order Summary**
   - Plan name and billing period
   - Base price
   - Savings amount (for yearly)
   - Total amount

2. **Billing Form**
   - Email address
   - Full name
   - Email validation

3. **Payment Form**
   - Card number
   - Expiration date
   - CVC code
   - Form validation

4. **Extra Elements**
   - Terms & conditions checkbox
   - Security notice
   - Error message display

**Workflow:**
1. Form pre-filled with user email (if authenticated)
2. User enters billing and payment details
3. Form validates all required fields
4. User checks terms agreement
5. Click "Pay" button triggers:
   - Client-side validation
   - Stripe payment processing (currently mocked)
   - Firestore subscription record creation on success
   - Navigation back with success message

#### SubscriptionManagementScreen (`lib/screens/home/subscription_management_screen.dart`)

**Purpose:** View and manage active subscription

**Key Features:**
- Current subscription card showing:
  - Plan name and description
  - Active status badge
  - Pricing details
  - Renewal information
  - Days remaining
- Features included checklist
- Billing history with past and upcoming payments
- Manage subscription actions:
  - Upgrade/Change plan button
  - Cancel subscription button
- Help/Support section
- Handles "no subscription" state with upgrade prompt

## Database Schema

### Firestore Collection: `subscriptions`

```dart
{
  subscriptionId: string,
  userId: string,
  tier: string,                    // 'basic', 'premium', 'elite'
  startDate: timestamp,
  renewalDate: timestamp,
  price: number,
  billingPeriod: string,           // 'monthly', 'yearly', 'lifetime'
  isActive: boolean,
  stripeCustomerId: string,
  stripeSubscriptionId: string,
  createdAt: timestamp,
  updatedAt: timestamp,
}
```

### Upload Limits Tracking

Separate collection: `uploadHistory`
```dart
{
  userId: string,
  uploadDate: timestamp,
  month: string,                   // 'YYYY-MM' format
  count: number,
}
```

## Integration Guide

### 1. Add to Home Screen Navigation

```dart
// In home_screen.dart, add to bottomNavigationBar or menu
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionManagementScreen(),
      ),
    );
  },
  child: const Text('Subscriptions'),
),
```

### 2. Enforce Upload Limits

In `upload_art_screen.dart`:
```dart
Future<void> _uploadArt() async {
  final canUpload = await _subscriptionService
      .canUploadArt(FirebaseAuth.instance.currentUser!.uid);
  
  if (!canUpload) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload limit reached. Upgrade your plan!')),
    );
    return;
  }
  
  // Proceed with upload...
}
```

### 3. Setup Stripe Integration

**Requirements:**
1. Add to `pubspec.yaml`:
```yaml
flutter_stripe: ^10.0.0
```

2. Create Firebase Cloud Function for checkout:
```javascript
exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
  const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
  const session = await stripe.checkout.sessions.create({
    customer_email: data.email,
    payment_method_types: ['card'],
    line_items: [{
      price: data.priceId,
      quantity: 1,
    }],
    mode: 'subscription',
    success_url: `${process.env.APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.APP_URL}/cancel`,
  });
  return { sessionId: session.id };
});
```

3. Update `stripe_service.dart` with real Stripe calls
4. Add Stripe webhook handler for subscription events
5. Update Firebase initialization with Stripe keys

### 4. Test Stripe Integration

Use Stripe test cards:
- Valid card: `4242 4242 4242 4242`
- Expired: `4000 0000 0000 0002`

## Usage Examples

### Check if User Can Upload

```dart
final subscriptionService = SubscriptionService();
final userId = FirebaseAuth.instance.currentUser!.uid;

if (await subscriptionService.canUploadArt(userId)) {
  // Proceed with upload
} else {
  // Show upgrade prompt
}
```

### Get User's Current Subscription

```dart
final subscription = 
    await subscriptionService.getUserSubscription(userId);

if (subscription != null) {
  print('${subscription.tier} - expires ${subscription.renewalDate}');
} else {
  print('User has no active subscription');
}
```

### Upgrade Subscription

```dart
await subscriptionService.upgradeSubscription(
  currentSubscriptionId,
  'premium',
);
```

## Security Considerations

1. **Always validate server-side** - Never trust client-side tier checks
2. **Use Firestore Rules** to restrict access:
   ```
   match /subscriptions/{document=**} {
     allow read: if request.auth.uid == resource.data.userId;
     allow write: if false;  // Only Cloud Functions can write
   }
   ```
3. **Webhook verification** - Always verify Stripe webhook signatures
4. **PCI Compliance** - Use Stripe's hosted checkout (never handle card data directly)

## Future Enhancements

1. **Coupon system** - Promotional codes and discounts
2. **Free trial** - 7-day trial for first subscription
3. **Plan switching** - Downgrade with prorated refunds
4. **Family plans** - Share subscription among multiple accounts
5. **Referral rewards** - Commission for referring new paid users
6. **Analytics dashboard** - MRR, churn rate, LTV tracking
7. **Dunning management** - Retry logic for failed payments

## Troubleshooting

### Subscription shows as inactive but should be active
- Check `renewalDate` vs current time
- Verify Stripe webhook was processed
- Check Firestore `isActive` flag

### Upload limit not enforcing
- Call `canUploadArt()` before allowing upload
- Verify `uploadHistory` collection is being updated
- Check upload limit for tier in subscription model

### Stripe payment fails
- Verify Stripe API keys in environment
- Check Cloud Function logs for errors
- Ensure price IDs match Stripe dashboard
- Test with Stripe test cards

### User can't access subscription management
- Ensure screen is properly integrated in navigation
- Check Firebase auth is initialized
- Verify Firestore rules allow user to read their subscription

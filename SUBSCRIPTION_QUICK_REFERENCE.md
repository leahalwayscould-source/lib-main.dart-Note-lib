# Subscription System - Quick Reference

## File Locations

```
lib/
├── models/
│   └── subscription.dart              # Data models
├── services/
│   ├── subscription_service.dart      # Business logic
│   └── stripe_service.dart            # Payment integration
└── screens/home/
    ├── subscription_plans_screen.dart      # Browse & subscribe
    ├── checkout_screen.dart                # Payment form
    └── subscription_management_screen.dart # Manage subscription
```

## Subscription Tiers at a Glance

| Feature | Free | Basic | Premium | Elite |
|---------|------|-------|---------|-------|
| Price | Free | $9.99/mo | $29.99/mo | $500 |
| Upload Limit | 5/mo | 20/mo | ∞ | ∞ |
| Priority Support | ✗ | ✓ | ✓ | ✓ |
| Can Mentor | ✗ | ✗ | ✗ | ✓ |
| Renewal | - | Monthly | Monthly | Lifetime |
| Yearly Price | - | $99/year | $299/year | - |

## Common Tasks

### Check User's Subscription
```dart
final subscription = await SubscriptionService().getUserSubscription(userId);
if (subscription != null) {
  print('Tier: ${subscription.tier}');
  print('Renews: ${subscription.renewalDate}');
}
```

### Prevent Upload if Limit Exceeded
```dart
if (!await SubscriptionService().canUploadArt(userId)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Upload limit reached. Upgrade your plan!'))
  );
  return;
}
```

### Navigate to Subscription Plans
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SubscriptionPlansScreen()),
);
```

### Navigate to Subscription Management
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SubscriptionManagementScreen()),
);
```

## Firestore Collections

### subscriptions
```
userId: string
tier: 'basic' | 'premium' | 'elite'
startDate: timestamp
renewalDate: timestamp
price: number
billingPeriod: 'monthly' | 'yearly' | 'lifetime'
isActive: boolean
stripeCustomerId: string
stripeSubscriptionId: string
```

### uploadHistory
```
userId: string
uploadDate: timestamp
month: 'YYYY-MM'
count: number
```

## SubscriptionService Methods

| Method | Returns | Purpose |
|--------|---------|---------|
| `getUserSubscription(userId)` | `Future<Subscription?>` | Get active subscription |
| `isSubscriptionActive(userId)` | `Future<bool>` | Check if subscription valid |
| `createSubscription(...)` | `Future<void>` | Create after payment |
| `cancelSubscription(id)` | `Future<void>` | Deactivate subscription |
| `upgradeSubscription(id, tier)` | `Future<void>` | Change tier |
| `canUploadArt(userId)` | `Future<bool>` | Check upload limit |
| `getUserSubscriptionHistory(userId)` | `Stream<List<Subscription>>` | All subscriptions |
| `setMentorStatus(userId, isMentor)` | `Future<void>` | Toggle mentor badge |

## StripeService Methods

| Method | Parameters | Returns | Status |
|--------|-----------|---------|--------|
| `getPriceId()` | planId, billingPeriod | String | Ready |
| `createCheckoutSession()` | userId, priceId, email | String (sessionId) | Needs Cloud Function |
| `createPaymentIntent()` | userId, amount | String (clientSecret) | Scaffold |
| `confirmPayment()` | intentId | bool | Scaffold |
| `saveCustomerId()` | userId, customerId | Future<void> | Ready |

## Stripe Test Cards

```
Valid:     4242 4242 4242 4242
Declined:  4000 0000 0000 0002
Expired:   4000 0000 0000 0069
CVC:       Any 3 digits (e.g., 123)
Date:      Any future date (e.g., 12/25)
```

## Key Constants

```dart
// Upload limits per tier
const uploadLimits = {
  'free': 5,      // per month
  'basic': 20,    // per month
  'premium': -1,  // unlimited (-1 = unlimited)
  'elite': -1,    // unlimited
};

// Pricing (monthly)
const pricing = {
  'basic': 9.99,
  'premium': 29.99,
};

// Pricing (yearly)
const pricingYearly = {
  'basic': 99.00,
  'premium': 299.00,
};

// Elite pricing
const elitePrice = 500.00;
```

## Computed Properties

```dart
subscription.isLifetime              // true for Elite
subscription.canUnlimitedUpload      // true for Premium/Elite
subscription.hasPrioritySupport      // true for Basic+
```

## State Management

**Current Pattern:** Service + Firestore Streams

```dart
final _subscriptionService = SubscriptionService();
final _currentUser = FirebaseAuth.instance.currentUser!;

// Real-time stream
Stream<List<Subscription>> getHistory() {
  return _subscriptionService
      .getUserSubscriptionHistory(_currentUser.uid);
}

// One-time future
Future<Subscription?> getCurrent() {
  return _subscriptionService
      .getUserSubscription(_currentUser.uid);
}
```

## Integration Checklist

- [ ] Add SubscriptionService to your dependency injection
- [ ] Add five subscription screens to your navigation
- [ ] Wrap upload with `canUploadArt()` check
- [ ] Add Firestore security rules for subscriptions collection
- [ ] Test with Free → Basic → Premium upgrade flow
- [ ] Test Elite $500 lifetime purchase
- [ ] Test annual billing shows 20% savings
- [ ] Verify renewal dates calculated correctly
- [ ] Test cancel subscription workflow
- [ ] Configure Stripe keys (test mode first)
- [ ] Deploy Cloud Functions for Stripe
- [ ] Test real payment flow end-to-end

## Error Handling

```dart
try {
  await subscriptionService.createSubscription(...);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Subscription created!'))
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'))
  );
}
```

## Imports Required

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import '../../services/stripe_service.dart';
import 'subscription_plans_screen.dart';
import 'checkout_screen.dart';
import 'subscription_management_screen.dart';
```

## Links

- [SUBSCRIPTION_SYSTEM.md](./SUBSCRIPTION_SYSTEM.md) - Detailed documentation
- [SUBSCRIPTION_INTEGRATION_GUIDE.md](./SUBSCRIPTION_INTEGRATION_GUIDE.md) - Setup & integration
- [Stripe Docs](https://stripe.com/docs) - Payment processor
- [Firebase Auth](https://firebase.google.com/docs/auth) - User authentication
- [Firestore](https://firebase.google.com/docs/firestore) - Database

## Support Resources

| Issue | Resource |
|-------|----------|
| Upload limits not enforcing | Check `canUploadArt()` is called |
| Stripe payment fails | Check API keys & test cards |
| Subscription not saving | Verify Firestore rules & connection |
| Screen not navigating | Ensure screen is imported & routed |
| Performance slow | Add indexes to Firestore |

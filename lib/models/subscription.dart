import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final String subscriptionId;
  final String userId;
  final String tier; // 'trial', 'basic', 'premium', 'elite'
  final double price;
  final String billingPeriod; // 'monthly', 'yearly', 'lifetime'
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate; // null for lifetime/active subscriptions
  final String stripeSubscriptionId;
  final String stripeCustomerId;
  final DateTime renewalDate;
  final int postsUploaded; // track usage
  final bool isMentor; // for elite members
  final DateTime createdAt;

  Subscription({
    required this.subscriptionId,
    required this.userId,
    required this.tier,
    required this.price,
    required this.billingPeriod,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.stripeSubscriptionId,
    required this.stripeCustomerId,
    required this.renewalDate,
    required this.postsUploaded,
    required this.isMentor,
    required this.createdAt,
  });

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      subscriptionId: doc.id,
      userId: data['userId'] ?? '',
      tier: data['tier'] ?? 'free',
      price: (data['price'] ?? 0.0).toDouble(),
      billingPeriod: data['billingPeriod'] ?? 'monthly',
      isActive: data['isActive'] ?? false,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      stripeSubscriptionId: data['stripeSubscriptionId'] ?? '',
      stripeCustomerId: data['stripeCustomerId'] ?? '',
      renewalDate: (data['renewalDate'] as Timestamp).toDate(),
      postsUploaded: data['postsUploaded'] ?? 0,
      isMentor: data['isMentor'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tier': tier,
      'price': price,
      'billingPeriod': billingPeriod,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'stripeSubscriptionId': stripeSubscriptionId,
      'stripeCustomerId': stripeCustomerId,
      'renewalDate': Timestamp.fromDate(renewalDate),
      'postsUploaded': postsUploaded,
      'isMentor': isMentor,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get canUnlimitedUpload => tier == 'premium' || tier == 'elite';
  bool get hasPrioritySupport => tier == 'premium' || tier == 'elite';
  bool get isElite => tier == 'elite';
  bool get isTrial => tier == 'trial';
  bool get isLifetime => billingPeriod == 'lifetime' || tier == 'elite';
}

// Subscription plans data
class SubscriptionPlan {
  final String tier;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final double lifetime; // for elite
  final List<String> features;
  final String color;

  SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.lifetime,
    required this.features,
    required this.color,
  });
}

// Predefined subscription plans
final subscriptionPlans = {
  'trial': SubscriptionPlan(
    tier: 'trial',
    name: '7-Day Trial',
    description: 'Try premium tools free, then subscribe anytime',
    monthlyPrice: 0,
    yearlyPrice: 0,
    lifetime: 0,
    features: [
      '✓ 7-day full feature access',
      '✓ Unlimited uploads during trial',
      '✓ Mockup + pricing + collector workflows',
      '✓ Cancel or upgrade anytime',
    ],
    color: '#22c55e',
  ),
  'basic': SubscriptionPlan(
    tier: 'basic',
    name: 'Basic',
    description: 'Perfect for getting started',
    monthlyPrice: 9.99,
    yearlyPrice: 99.00,
    lifetime: 0,
    features: [
      '✓ Basic artwork uploads',
      '✓ Community feedback',
      '✓ View pricing calculator',
      '✓ Access to mockup viewer',
      '✓ Artist profile',
      '✗ Unlimited uploads',
      '✗ Priority support',
    ],
    color: '#6366f1', // Indigo
  ),
  'premium': SubscriptionPlan(
    tier: 'premium',
    name: 'Premium',
    description: 'For serious artists',
    monthlyPrice: 29.99,
    yearlyPrice: 299.00,
    lifetime: 0,
    features: [
      '✓ Unlimited artwork uploads',
      '✓ Community feedback',
      '✓ Advanced pricing tools',
      '✓ Enhanced mockup viewer',
      '✓ Priority support (24/7)',
      '✓ Analytics dashboard',
      '✓ Featured artist badge',
    ],
    color: '#8b5cf6', // Purple
  ),
  'elite': SubscriptionPlan(
    tier: 'elite',
    name: 'Elite',
    description: 'Lifetime premium access + mentor',
    monthlyPrice: 0,
    yearlyPrice: 0,
    lifetime: 500.00,
    features: [
      '✓ Lifetime unlimited uploads',
      '✓ Priority support (24/7)',
      '✓ Become a mentor',
      '✓ Exclusive masterclasses',
      '✓ Advanced analytics',
      '✓ Custom portfolio website',
      '✓ Revenue sharing opportunities',
      '✓ Featured in elite gallery',
    ],
    color: '#ec4899', // Pink
  ),
};

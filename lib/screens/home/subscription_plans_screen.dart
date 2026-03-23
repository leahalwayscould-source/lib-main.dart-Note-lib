import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import 'checkout_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  String _billingPeriod = 'monthly'; // 'monthly' or 'yearly'
  Subscription? _userSubscription;
  bool _isLoading = true;
  bool _isStartingTrial = false;

  @override
  void initState() {
    super.initState();
    _loadUserSubscription();
  }

  Future<void> _loadUserSubscription() async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      setState(() {
        _userSubscription = null;
        _isLoading = false;
      });
      return;
    }

    try {
      final subscription =
          await _subscriptionService.getUserSubscription(currentUser.uid);
      setState(() {
        _userSubscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToCheckout(String tier, double price) {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to subscribe, or continue in demo mode.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          tier: tier,
          billingPeriod: _billingPeriod,
          price: price,
          onSuccess: () {
            _loadUserSubscription();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription activated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _startFreeTrial() async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to start your 7-day trial.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isStartingTrial = true;
    });

    try {
      await _subscriptionService.startFreeTrial(currentUser.uid);
      await _loadUserSubscription();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your 7-day trial is active. Subscribe anytime.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start trial: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isStartingTrial = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Subscription Plans'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userSubscription == null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start with a 7-day free trial',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get full access now, then choose Basic, Premium, or Elite any time during the trial.',
                      style: TextStyle(
                        color: Colors.grey[300],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isStartingTrial ? null : _startFreeTrial,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: _isStartingTrial
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.rocket_launch_outlined),
                        label: Text(
                          _isStartingTrial
                              ? 'Starting trial...'
                              : 'Start 7-Day Trial',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Billing Period Toggle
            if (_userSubscription == null || _userSubscription!.tier != 'elite')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BillingPeriodButton(
                      label: 'Monthly',
                      isSelected: _billingPeriod == 'monthly',
                      onTap: () {
                        setState(() => _billingPeriod = 'monthly');
                      },
                    ),
                    const SizedBox(width: 12),
                    _BillingPeriodButton(
                      label: 'Yearly',
                      isSelected: _billingPeriod == 'yearly',
                      onTap: () {
                        setState(() => _billingPeriod = 'yearly');
                      },
                      badge: 'Save 20%',
                    ),
                  ],
                ),
              ),
            if (_userSubscription == null || _userSubscription!.tier != 'elite')
              const SizedBox(height: 24),

            // Current Subscription Info
            if (_userSubscription != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Plan',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Chip(
                          label: Text(
                            _userSubscription!.tier == 'trial'
                                ? 'TRIAL'
                                : _userSubscription!.tier.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userSubscription!.tier == 'trial'
                          ? 'Trial ends on ${_userSubscription!.renewalDate.toString().split(' ')[0]} • Subscribe anytime'
                          : _userSubscription!.isLifetime
                              ? 'Lifetime Access'
                              : 'Renews on ${_userSubscription!.renewalDate.toString().split(' ')[0]}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            if (_userSubscription != null) const SizedBox(height: 24),

            // Plans Grid
            Column(
              children: subscriptionPlans.entries
                  .where((entry) => entry.key != 'trial')
                  .map((entry) {
                final plan = entry.value;
                final isCurrentPlan = _userSubscription?.tier == plan.tier;

                return _SubscriptionCard(
                  plan: plan,
                  billingPeriod: _billingPeriod,
                  isCurrentPlan: isCurrentPlan,
                  onTap: () {
                    if (isCurrentPlan) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('You already have this plan')),
                      );
                      return;
                    }

                    final price = plan.tier == 'elite'
                        ? plan.lifetime
                        : _billingPeriod == 'monthly'
                            ? plan.monthlyPrice
                            : plan.yearlyPrice;

                    _navigateToCheckout(plan.tier, price);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // FAQ Section
            _FaqSection(),
          ],
        ),
      ),
    );
  }
}

class _BillingPeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _BillingPeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.grey,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 4),
                Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.yellow : Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String billingPeriod;
  final bool isCurrentPlan;
  final VoidCallback onTap;

  const _SubscriptionCard({
    required this.plan,
    required this.billingPeriod,
    required this.isCurrentPlan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = plan.tier == 'elite'
        ? plan.lifetime
        : billingPeriod == 'monthly'
            ? plan.monthlyPrice
            : plan.yearlyPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlan ? Colors.deepPurple : Colors.grey[700]!,
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    if (isCurrentPlan)
                      Chip(
                        label: const Text('Current'),
                        backgroundColor: Colors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      TextSpan(
                        text: plan.tier == 'elite'
                            ? ' one-time'
                            : ' / ${billingPeriod == 'monthly' ? 'month' : 'year'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Features List
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          feature.startsWith('✓') ? '✓' : '✗',
                          style: TextStyle(
                            color: feature.startsWith('✓')
                                ? Colors.green
                                : Colors.red.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature.substring(2),
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Subscribe Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isCurrentPlan ? Colors.grey[700] : Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isCurrentPlan ? 'Current Plan' : 'Subscribe Now',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (plan.tier == 'elite')
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _FaqItem(
          question: 'Can I cancel anytime?',
          answer:
              'Yes! Monthly and yearly plans can be cancelled anytime. Elite lifetime purchases are non-refundable.',
        ),
        _FaqItem(
          question: 'What happens when my subscription renews?',
          answer:
              'Your subscription will automatically renew on the renewal date. We\'ll send you a reminder email before charging.',
        ),
        _FaqItem(
          question: 'Can I upgrade or downgrade?',
          answer:
              'Yes! You can upgrade or downgrade anytime. Pricing will be prorated based on your remaining time.',
        ),
        _FaqItem(
          question: 'What payment methods do you accept?',
          answer:
              'We accept all major credit/debit cards through Stripe. Your payment information is encrypted and secure.',
        ),
        _FaqItem(
          question: 'Do I get a refund if I cancel?',
          answer:
              'For monthly plans, refunds are provided prorated for the remaining days. Yearly plans and Elite lifetime are non-refundable.',
        ),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.answer,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import 'subscription_plans_screen.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  Subscription? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final subscription =
          await _subscriptionService.getUserSubscription(_currentUser!.uid);
      setState(() {
        _subscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Are you sure you want to cancel? You\'ll lose access to premium features at the end of this billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _subscriptionService
            .cancelSubscription(_subscription!.subscriptionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadSubscription();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_subscription == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_membership, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text('No active subscription'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text('Browse Plans'),
            ),
          ],
        ),
      );
    }

    final plan = subscriptionPlans[_subscription!.tier];
    final daysRemaining =
        _subscription!.renewalDate.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Subscription Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
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
                          plan!.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Details Grid
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  children: [
                    _DetailBox(
                      label: 'Price',
                      value:
                          '\$${_subscription!.price.toStringAsFixed(2)}/${_subscription!.billingPeriod}',
                    ),
                    _DetailBox(
                      label: 'Status',
                      value: _subscription!.isActive ? 'Active' : 'Inactive',
                    ),
                    _DetailBox(
                      label: 'Started',
                      value:
                          '${_subscription!.startDate.month}/${_subscription!.startDate.day}/${_subscription!.startDate.year}',
                    ),
                    _DetailBox(
                      label: 'Renews In',
                      value: '$daysRemaining days',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Features Included
          Text(
            'Features Included',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    feature.startsWith('✓') ? Icons.check_circle : Icons.cancel,
                    color: feature.startsWith('✓') ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature.substring(2),
                      style: TextStyle(
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Billing History
          Text(
            'Billing History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _BillingHistoryItem(
                  date: _subscription!.startDate,
                  description:
                      '${plan.name} - ${_subscription!.billingPeriod.toUpperCase()}',
                  amount: '\$${_subscription!.price.toStringAsFixed(2)}',
                  status: 'Paid',
                ),
                if (_subscription!.renewalDate.isAfter(DateTime.now()))
                  Column(
                    children: [
                      const Divider(color: Colors.grey),
                      _BillingHistoryItem(
                        date: _subscription!.renewalDate,
                        description: 'Upcoming renewal',
                        amount: '\$${_subscription!.price.toStringAsFixed(2)}',
                        status: 'Scheduled',
                        statusColor: Colors.blue,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          if (!_subscription!.isLifetime)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Subscription',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionPlansScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: const Text('Upgrade/Change Plan'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cancelSubscription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    child: const Text('Cancel Subscription'),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Support
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help, color: Colors.blue.shade300),
                    const SizedBox(width: 8),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact our support team at support@artconnect.app for subscription changes or billing questions.',
                  style: TextStyle(
                    color: Colors.blue.shade200,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  final String label;
  final String value;

  const _DetailBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingHistoryItem extends StatelessWidget {
  final DateTime date;
  final String description;
  final String amount;
  final String status;
  final Color? statusColor;

  const _BillingHistoryItem({
    required this.date,
    required this.description,
    required this.amount,
    required this.status,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.month}/${date.day}/${date.year}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (statusColor ?? Colors.green).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (statusColor ?? Colors.green).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor ?? Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

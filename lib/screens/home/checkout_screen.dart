import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import '../../services/stripe_service.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String tier;
  final String billingPeriod;
  final double price;
  final VoidCallback onSuccess;

  const CheckoutScreen({
    super.key,
    required this.tier,
    required this.billingPeriod,
    required this.price,
    required this.onSuccess,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isProcessing = false;
  bool _agreeToTerms = false;
  String _errorMessage = '';
  String _checkoutStatusMessage = '';
  String? _hostedCheckoutUrl;
  bool _hostedCheckoutAutoOpened = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = _currentUser?.email ?? '';
    _nameController.text = _currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _openHostedCheckout(String checkoutUrl) async {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) {
      return false;
    }

    return launchUrl(uri, webOnlyWindowName: '_blank');
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      setState(() => _errorMessage = 'Please agree to terms and conditions');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
      _checkoutStatusMessage = '';
      _hostedCheckoutUrl = null;
      _hostedCheckoutAutoOpened = false;
    });

    try {
      final currentUser = _currentUser;
      if (currentUser == null) {
        throw Exception('You must be signed in before starting checkout.');
      }

      final checkoutResult = await StripeService.createSubscriptionCheckout(
        userId: currentUser.uid,
        tier: widget.tier,
        billingPeriod: widget.billingPeriod,
        email: _emailController.text.trim(),
        amount: widget.price,
        name: _nameController.text.trim(),
      );

      if (checkoutResult.isSandbox) {
        await _subscriptionService.createSubscription(
          userId: currentUser.uid,
          tier: widget.tier,
          billingPeriod: widget.billingPeriod,
          stripeSubscriptionId: checkoutResult.providerReferenceId,
          stripeCustomerId: checkoutResult.customerId,
          price: widget.price,
        );
      }

      setState(() {
        _hostedCheckoutUrl = checkoutResult.checkoutUrl;
        _checkoutStatusMessage = checkoutResult.checkoutUrl == null
            ? checkoutResult.message
            : '${checkoutResult.message}\n\nHosted checkout URL:\n${checkoutResult.checkoutUrl}';
      });

      if (!checkoutResult.isSandbox &&
          checkoutResult.checkoutUrl != null &&
          checkoutResult.checkoutUrl!.isNotEmpty) {
        final opened = await _openHostedCheckout(checkoutResult.checkoutUrl!);
        if (mounted) {
          setState(() {
            _hostedCheckoutAutoOpened = opened;
          });
        }
        if (mounted && !opened) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open hosted checkout automatically.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkoutResult.isSandbox
                  ? 'Sandbox checkout completed. Subscription activated for testing.'
                  : 'Checkout session created. Complete payment in hosted Stripe Checkout before the subscription is activated.',
            ),
            backgroundColor:
                checkoutResult.isSandbox ? Colors.green : Colors.orange,
          ),
        );
        if (checkoutResult.isSandbox) {
          widget.onSuccess();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final plan = subscriptionPlans[widget.tier];
    final isStripeConfigured = StripeService.isConfigured;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Complete Your Purchase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: plan!.name,
                    value: widget.tier == 'elite'
                        ? plan.lifetime.toStringAsFixed(2)
                        : (widget.billingPeriod == 'monthly'
                            ? plan.monthlyPrice.toStringAsFixed(2)
                            : plan.yearlyPrice.toStringAsFixed(2)),
                  ),
                  if (widget.tier != 'elite')
                    _SummaryRow(
                      label: widget.billingPeriod == 'monthly'
                          ? 'Monthly subscription'
                          : 'Annual subscription',
                      value: '',
                    ),
                  if (widget.billingPeriod == 'yearly')
                    _SummaryRow(
                      label: 'Savings vs monthly',
                      value:
                          '-\$${(plan.monthlyPrice * 12 - plan.yearlyPrice).toStringAsFixed(2)}',
                      valueColor: Colors.green,
                    ),
                  const Divider(color: Colors.grey),
                  _SummaryRow(
                    label: 'Total',
                    value: '\$${widget.price.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Billing Information Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billing Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Email is required';
                      if (!value!.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Checkout Information
                  Text(
                    'Secure Checkout',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isStripeConfigured
                            ? Colors.green.withValues(alpha: 0.35)
                            : Colors.orange.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isStripeConfigured
                                  ? Icons.verified_outlined
                                  : Icons.science_outlined,
                              color: isStripeConfigured
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isStripeConfigured
                                    ? 'Stripe checkout is configured. The next production step is redirect + webhook confirmation.'
                                    : 'Stripe is still using placeholder credentials, so this checkout runs in sandbox mode for now.',
                                style: TextStyle(
                                  color: Colors.grey[200],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Payments should be collected in hosted Stripe Checkout or a PaymentSheet flow rather than directly in this form.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Terms & Conditions
                  CheckboxListTile(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() => _agreeToTerms = value ?? false);
                    },
                    title: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey[300]),
                        children: [
                          const TextSpan(text: 'I agree to '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Refund Policy',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),

                  // Error Message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_checkoutStatusMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _checkoutStatusMessage,
                        style: TextStyle(color: Colors.green[200]),
                      ),
                    ),
                    if (_hostedCheckoutUrl != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hostedCheckoutAutoOpened
                                  ? 'Stripe opened in a new tab.'
                                  : 'Open Stripe checkout to continue.',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '1. Complete payment in Stripe.\n2. Return here after payment.\n3. Use Premium to review your subscription status.',
                              style: TextStyle(height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openHostedCheckout(_hostedCheckoutUrl!),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open Hosted Checkout'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const HomeScreen(initialIndex: 6),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.workspace_premium),
                          label: const Text('Return to Premium'),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),

                  // Security Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your payment is secure. We use industry-standard encryption.',
                            style: TextStyle(
                              color: Colors.blue.shade300,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              isStripeConfigured
                                  ? 'Create Stripe Checkout - \$${widget.price.toStringAsFixed(2)}'
                                  : 'Activate Sandbox Subscription - \$${widget.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed:
                          _isProcessing ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (value.isNotEmpty)
            Text(
              '\$$value',
              style: TextStyle(
                color: valueColor ?? (isBold ? Colors.white : Colors.grey[300]),
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}

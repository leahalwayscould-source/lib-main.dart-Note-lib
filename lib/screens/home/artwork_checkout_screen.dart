import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/art_post.dart';
import '../../models/collector_conversation.dart';
import '../../models/artwork_order.dart';
import '../../services/artwork_inquiry_service.dart';
import '../../services/artwork_order_service.dart';
import '../../services/stripe_service.dart';
import 'artwork_order_status_screen.dart';
import 'collector_conversation_screen.dart';
import 'home_screen.dart';

class ArtworkCheckoutScreen extends StatefulWidget {
  const ArtworkCheckoutScreen({
    super.key,
    required this.post,
    this.initialIntent = 'Purchase original',
  });

  final ArtPost post;
  final String initialIntent;

  @override
  State<ArtworkCheckoutScreen> createState() => _ArtworkCheckoutScreenState();
}

class _ArtworkCheckoutScreenState extends State<ArtworkCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentUser = FirebaseAuth.instance.currentUser;
  final _artworkInquiryService = ArtworkInquiryService();
  final _artworkOrderService = ArtworkOrderService();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  late String _selectedIntent;
  bool _isSubmitting = false;
  String _statusMessage = '';
  String? _hostedCheckoutUrl;
  ArtworkOrder? _createdOrder;
  CollectorConversation? _createdConversation;

  @override
  void initState() {
    super.initState();
    _selectedIntent = widget.initialIntent;
    _emailController.text = _currentUser?.email ?? '';
    _nameController.text = _currentUser?.displayName ?? '';
    _messageController.text = _defaultMessageForIntent(widget.initialIntent);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = '';
      _hostedCheckoutUrl = null;
      _createdOrder = null;
      _createdConversation = null;
    });

    final buyerUid = _currentUser?.uid;
    if (buyerUid == null) {
      setState(() {
        _isSubmitting = false;
        _statusMessage = 'Sign in to send a live collector inquiry.';
      });
      return;
    }

    final buyerName = _nameController.text.trim();
    final buyerEmail = _emailController.text.trim();
    final message = _messageController.text.trim();

    try {
      final submission = await _artworkInquiryService.submitInquiry(
        post: widget.post,
        buyerUid: buyerUid,
        buyerName: buyerName,
        buyerEmail: buyerEmail,
        intent: _selectedIntent,
        message: message,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _createdConversation = submission.conversation;
        _statusMessage = _selectedIntent == 'Purchase original'
            ? 'Purchase inquiry sent to ${widget.post.artistName}. The thread now lives in Collector so you can track availability, shipping, and payment follow-up.'
            : _selectedIntent == 'Commission something similar'
                ? 'Commission request sent to ${widget.post.artistName}. Collector now has the live thread for scope, timing, and pricing.'
                : 'Question sent to ${widget.post.artistName}. Collector now tracks the thread until they reply.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artwork inquiry sent.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _statusMessage =
            'The inquiry could not be saved right now. Try again in a moment.';
      });
    }
  }

  Future<bool> _openHostedCheckout(String checkoutUrl) async {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) {
      return false;
    }

    return launchUrl(uri, webOnlyWindowName: '_blank');
  }

  Future<void> _processArtworkPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = '';
      _hostedCheckoutUrl = null;
      _createdOrder = null;
      _createdConversation = null;
    });

    final buyerUid = _currentUser?.uid;
    if (buyerUid == null) {
      setState(() {
        _isSubmitting = false;
        _statusMessage = 'Sign in to purchase this artwork.';
      });
      return;
    }

    final buyerName = _nameController.text.trim();
    final buyerEmail = _emailController.text.trim();

    try {
      final checkoutResult = await StripeService.createArtworkCheckout(
        userId: buyerUid,
        email: buyerEmail,
        amount: widget.post.askingPrice,
        artworkId: widget.post.postId,
        artworkTitle: widget.post.title,
        artistName: widget.post.artistName,
        name: buyerName,
      );

      final order = checkoutResult.isSandbox
          ? await _artworkOrderService.createSandboxOrder(
              userId: buyerUid,
              artistName: widget.post.artistName,
              buyerEmail: buyerEmail,
              post: widget.post,
              checkoutReferenceId: checkoutResult.checkoutReferenceId,
            )
          : await _artworkOrderService.createHostedCheckoutOrder(
              userId: buyerUid,
              artistName: widget.post.artistName,
              buyerEmail: buyerEmail,
              post: widget.post,
              checkoutReferenceId: checkoutResult.checkoutReferenceId,
              checkoutUrl: checkoutResult.checkoutUrl ?? '',
            );

      if (!mounted) {
        return;
      }

      bool opened = false;
      if (!checkoutResult.isSandbox &&
          checkoutResult.checkoutUrl != null &&
          checkoutResult.checkoutUrl!.isNotEmpty) {
        opened = await _openHostedCheckout(checkoutResult.checkoutUrl!);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _hostedCheckoutUrl = checkoutResult.checkoutUrl;
        _createdOrder = order;
        _statusMessage = checkoutResult.isSandbox
            ? 'Sandbox mode: direct payment is not configured yet. You can continue with a purchase inquiry instead.'
            : opened
                ? 'Stripe checkout opened in a new tab. Complete payment and then return to your collector inbox for updates.'
                : 'Stripe checkout is ready. Tap Open Hosted Checkout to complete payment.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            checkoutResult.isSandbox
                ? 'Sandbox artwork checkout prepared.'
                : 'Artwork checkout session created.',
          ),
          backgroundColor:
              checkoutResult.isSandbox ? Colors.orange : Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _statusMessage =
            'Could not start artwork checkout right now. Try again in a moment.';
      });
    }
  }

  void _returnToGallery() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 0)),
      (route) => false,
    );
  }

  void _openCollector() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 1)),
      (route) => false,
    );
  }

  void _openOrderStatus() {
    final order = _createdOrder;
    if (order == null) {
      _returnToGallery();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtworkOrderStatusScreen(order: order),
      ),
    );
  }

  void _openConversation() {
    final conversation = _createdConversation;
    if (conversation == null) {
      _openCollector();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectorConversationScreen(conversation: conversation),
      ),
    );
  }

  String _defaultMessageForIntent(String intent) {
    switch (intent) {
      case 'Purchase original':
        return 'Hi ${widget.post.artistName}, I\'m interested in purchasing ${widget.post.title}. Is it currently available?';
      case 'Commission something similar':
        return 'Hi ${widget.post.artistName}, I\'d love to commission something inspired by ${widget.post.title}. Are you open for commissions?';
      default:
        return 'Hi ${widget.post.artistName}, I have a question about ${widget.post.title}.';
    }
  }

  void _selectIntent(String intent) {
    setState(() {
      _selectedIntent = intent;
      _messageController.text = _defaultMessageForIntent(intent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _selectedIntent == 'Purchase original'
              ? 'Buy Artwork'
              : _selectedIntent == 'Commission something similar'
                  ? 'Commission Artist'
                  : 'Ask About Artwork',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: widget.post.imageUrl.isNotEmpty
                            ? Image.network(widget.post.imageUrl,
                                fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.image, size: 36),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.post.artistName,
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 10),
                          Chip(
                            backgroundColor: Colors.deepPurple,
                            label: Text(
                              '\$${widget.post.askingPrice.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Buyer Intent',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _IntentChip(
                    label: 'Buy Original',
                    selected: _selectedIntent == 'Purchase original',
                    onTap: () => _selectIntent('Purchase original'),
                  ),
                  _IntentChip(
                    label: 'Commission',
                    selected: _selectedIntent == 'Commission something similar',
                    onTap: () => _selectIntent('Commission something similar'),
                  ),
                  _IntentChip(
                    label: 'Ask First',
                    selected: _selectedIntent == 'Ask a question first',
                    onTap: () => _selectIntent('Ask a question first'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message to Artist',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _selectedIntent == 'Purchase original'
                      ? 'Buying an original now uses hosted Stripe checkout. Commission and question intents continue through collector inquiry threads.'
                      : 'Commission and question intents are sent as collector inquiries so the artist can follow up with details.',
                  style: TextStyle(color: Colors.blue.shade200, height: 1.4),
                ),
              ),
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
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
                    _statusMessage,
                    style: TextStyle(color: Colors.green[200]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _hostedCheckoutUrl != null
                            ? () => _openHostedCheckout(_hostedCheckoutUrl!)
                            : _createdOrder != null
                                ? _openOrderStatus
                                : _createdConversation == null
                                    ? _returnToGallery
                                    : _openCollector,
                        icon: Icon(
                          _hostedCheckoutUrl != null
                              ? Icons.open_in_new
                              : _createdOrder != null
                                  ? Icons.receipt_long_outlined
                                  : _createdConversation == null
                                      ? Icons.collections_outlined
                                      : Icons.inbox_outlined,
                        ),
                        label: Text(
                          _hostedCheckoutUrl != null
                              ? 'Open Hosted Checkout'
                              : _createdOrder != null
                                  ? 'View Order Status'
                                  : _createdConversation == null
                                      ? 'Back to Gallery'
                                      : 'Open Collector',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: _hostedCheckoutUrl != null
                            ? _openOrderStatus
                            : _createdOrder != null
                                ? _returnToGallery
                                : _createdConversation == null
                                    ? () => Navigator.of(context).maybePop()
                                    : _openConversation,
                        child: Text(
                          _hostedCheckoutUrl != null
                              ? 'View Order Status'
                              : _createdOrder != null
                                  ? 'Back to Gallery'
                                  : _createdConversation == null
                                      ? 'Stay Here'
                                      : 'Open Thread',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : _selectedIntent == 'Purchase original'
                          ? _processArtworkPayment
                          : _submitInquiry,
                  icon: Icon(
                    _selectedIntent == 'Purchase original'
                        ? Icons.shopping_cart_checkout
                        : Icons.shopping_bag_outlined,
                  ),
                  label: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _selectedIntent == 'Purchase original'
                              ? 'Pay now with card'
                              : 'Continue with ${_selectedIntent.toLowerCase()}',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntentChip extends StatelessWidget {
  const _IntentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey[800],
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey[300],
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

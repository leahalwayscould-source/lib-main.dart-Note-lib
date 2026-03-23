import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/gallery_cart_item.dart';
import '../../models/print_order.dart';
import '../../services/artwork_inquiry_service.dart';
import '../../services/gallery_cart_service.dart';
import '../../services/print_order_service.dart';

class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalController = TextEditingController();
  final _noteController = TextEditingController();

  final _currentUser = FirebaseAuth.instance.currentUser;
  final _inquiryService = ArtworkInquiryService();
  final _printOrderService = PrintOrderService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _currentUser?.displayName ?? '';
    _emailController.text = _currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _postalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitCheckout(List<GalleryCartItem> items) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to complete checkout.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final buyerName = _nameController.text.trim();
    final buyerEmail = _emailController.text.trim();
    final note = _noteController.text.trim();

    var originalSuccessCount = 0;
    var merchSuccessCount = 0;
    var failureCount = 0;

    for (final item in items) {
      try {
        if (item.kind == GalleryCartItemKind.original) {
          await _inquiryService.submitInquiry(
            post: item.post,
            buyerUid: _currentUser!.uid,
            buyerName: buyerName,
            buyerEmail: buyerEmail,
            intent: 'Purchase original',
            message: note.isEmpty
                ? 'Cart checkout request: I am ready to purchase the original artwork.'
                : 'Cart checkout request: I am ready to purchase the original artwork.\\n\\nBuyer note: $note',
          );
          originalSuccessCount += 1;
          continue;
        }

        final quantity = item.quantity;
        final printType = item.merchType ?? 'poster';
        final size = item.size ?? 'medium';
        final unitPrice = PrintOrderService.getPrice(printType, size);
        final order = PrintOrder(
          orderId: '',
          userId: _currentUser!.uid,
          artistUid: item.post.artistUid,
          artworkId: item.post.postId,
          artworkTitle: item.post.title,
          artworkImageUrl: item.post.imageUrl,
          printType: printType,
          productColor: item.color,
          size: size,
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: unitPrice * quantity,
          status: 'pending',
          provider: 'manual',
          providerStatus: 'queued',
          shippingName: buyerName,
          shippingAddress: _addressController.text.trim(),
          shippingCity: _cityController.text.trim(),
          shippingCountry: _countryController.text.trim(),
          shippingPostalCode: _postalController.text.trim(),
          createdAt: DateTime.now(),
        );
        await _printOrderService.createPrintOrder(order);
        merchSuccessCount += 1;
      } catch (_) {
        failureCount += 1;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (failureCount == 0) {
      GalleryCartService.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checkout submitted: $originalSuccessCount original request(s), $merchSuccessCount merch order(s).',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).maybePop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Some items failed to submit. Success: ${originalSuccessCount + merchSuccessCount}, Failed: $failureCount.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cart Checkout'),
      ),
      body: ValueListenableBuilder<List<GalleryCartItem>>(
        valueListenable: GalleryCartService.itemsNotifier,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Your cart is empty. Add artwork or merch from Gallery.',
                style: TextStyle(color: Colors.grey[400]),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CartItemCard(item: item),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Subtotal',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '\$${GalleryCartService.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full name *'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Email *'),
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
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration('Shipping address *'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Address is required'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _cityController,
                      decoration: _inputDecoration('City *'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'City is required'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _countryController,
                      decoration: _inputDecoration('Country *'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Country is required'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _postalController,
                      decoration: _inputDecoration('Postal code *'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Postal code is required'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: _inputDecoration('Order note (optional)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      _isSubmitting ? null : () => _submitCheckout(items),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Checkout Now'),
                ),
              ),
              const SizedBox(height: 28),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final GalleryCartItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: item.post.imageUrl.isNotEmpty
                  ? Image.network(item.post.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_outlined),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty ${item.quantity} • \$${item.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (item.kind == GalleryCartItemKind.merch)
                IconButton(
                  tooltip: 'Increase quantity',
                  onPressed: () => GalleryCartService.updateQuantity(
                    item.key,
                    item.quantity + 1,
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () => GalleryCartService.remove(item.key),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

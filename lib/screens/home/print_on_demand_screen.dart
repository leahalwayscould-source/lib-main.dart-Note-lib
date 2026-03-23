import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/art_post.dart';
import '../../models/print_order.dart';
import '../../models/subscription.dart';
import '../../services/art_post_service.dart';
import '../../services/print_order_service.dart';
import '../../services/subscription_service.dart';
import 'subscription_plans_screen.dart';

class PrintOnDemandScreen extends StatefulWidget {
  const PrintOnDemandScreen({super.key});

  @override
  State<PrintOnDemandScreen> createState() => _PrintOnDemandScreenState();
}

class _PrintOnDemandScreenState extends State<PrintOnDemandScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _currentUser = FirebaseAuth.instance.currentUser;
  final _artPostService = ArtPostService();
  final _printOrderService = PrintOrderService();
  final _subscriptionService = SubscriptionService();

  // Configurator state
  ArtPost? _selectedArtwork;
  String _selectedPrintType = 'poster';
  String _selectedHoodieColor = 'black';
  String _selectedSize = 'medium';
  int _quantity = 1;

  // Shipping form
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalController = TextEditingController();

  bool _isPlacingOrder = false;
  Subscription? _subscription;
  bool _subscriptionLoading = true;

  static const _printTypes = [
    {'key': 'poster', 'label': 'Art Poster', 'icon': Icons.image_outlined},
    {
      'key': 'canvas',
      'label': 'Canvas Print',
      'icon': Icons.crop_original_outlined
    },
    {
      'key': 'framed',
      'label': 'Framed Print',
      'icon': Icons.photo_size_select_large_outlined
    },
    {
      'key': 'tote_bag',
      'label': 'Tote Bag',
      'icon': Icons.shopping_bag_outlined
    },
    {
      'key': 'phone_case',
      'label': 'Phone Case',
      'icon': Icons.smartphone_outlined
    },
    {
      'key': 'adult_hoodie_pullover',
      'label': 'Adult Hoodie Pullover',
      'icon': Icons.checkroom_outlined
    },
  ];

  static const _sizes = ['small', 'medium', 'large', 'xlarge'];
  static const _hoodieColors = [
    'black',
    'white',
    'navy',
    'charcoal',
    'heather_gray',
    'maroon',
    'forest_green',
  ];

  bool get _isHoodieSelected => _selectedPrintType == 'adult_hoodie_pullover';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscription() async {
    if (_currentUser == null) return;
    final sub =
        await _subscriptionService.getUserSubscription(_currentUser!.uid);
    if (mounted) {
      setState(() {
        _subscription = sub;
        _subscriptionLoading = false;
      });
    }
  }

  double get _unitPrice =>
      PrintOrderService.getPrice(_selectedPrintType, _selectedSize);

  double get _totalPrice => _unitPrice * _quantity;

  bool get _canOrder => _subscription != null && _subscription!.tier != 'trial';

  void _showUpsellDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Unlock Print on Demand',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Print on Demand is available on Basic, Premium, and Elite plans.\n\n'
          'Start selling physical prints of your artwork today!',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SubscriptionPlansScreen()));
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_currentUser == null) return;
    if (!_canOrder) {
      _showUpsellDialog();
      return;
    }
    if (_selectedArtwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an artwork first')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPlacingOrder = true);
    try {
      final order = PrintOrder(
        orderId: '',
        userId: _currentUser!.uid,
        artistUid: _selectedArtwork!.artistUid,
        artworkId: _selectedArtwork!.postId,
        artworkTitle: _selectedArtwork!.title,
        artworkImageUrl: _selectedArtwork!.imageUrl,
        printType: _selectedPrintType,
        productColor: _isHoodieSelected ? _selectedHoodieColor : null,
        size: _selectedSize,
        quantity: _quantity,
        unitPrice: _unitPrice,
        totalPrice: _totalPrice,
        status: 'pending',
        provider: 'manual',
        providerStatus: 'queued',
        shippingName: _nameController.text.trim(),
        shippingAddress: _addressController.text.trim(),
        shippingCity: _cityController.text.trim(),
        shippingCountry: _countryController.text.trim(),
        shippingPostalCode: _postalController.text.trim(),
        createdAt: DateTime.now(),
      );
      await _printOrderService.createPrintOrder(order);

      if (mounted) {
        _clearForm();
        _tabController.animateTo(1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _clearForm() {
    setState(() {
      _selectedArtwork = null;
      _selectedPrintType = 'poster';
      _selectedHoodieColor = 'black';
      _selectedSize = 'medium';
      _quantity = 1;
    });
    _nameController.clear();
    _addressController.clear();
    _cityController.clear();
    _countryController.clear();
    _postalController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.deepPurple,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.add_shopping_cart), text: 'New Order'),
              Tab(icon: Icon(Icons.receipt_long), text: 'My Orders'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderConfigurator(),
                _buildOrderHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              const Icon(Icons.local_print_shop,
                  color: Colors.deepPurple, size: 28),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Print on Demand',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('Turn your art into physical products',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              if (!_subscriptionLoading && !_canOrder)
                GestureDetector(
                  onTap: _showUpsellDialog,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text('TRIAL',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderConfigurator() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_subscriptionLoading && !_canOrder) _buildTrialBanner(),
        _buildSectionTitle('1. Select Your Artwork'),
        _buildArtworkSelector(),
        const SizedBox(height: 20),
        _buildSectionTitle('2. Choose Print Type'),
        _buildPrintTypeSelector(),
        if (_isHoodieSelected) ...[
          const SizedBox(height: 20),
          _buildSectionTitle('3. Hoodie Color'),
          _buildHoodieColorSelector(),
        ],
        const SizedBox(height: 20),
        _buildSectionTitle(
            _isHoodieSelected ? '4. Size & Quantity' : '3. Size & Quantity'),
        _buildSizeSelector(),
        const SizedBox(height: 12),
        _buildQuantitySelector(),
        const SizedBox(height: 20),
        _buildPriceSummary(),
        const SizedBox(height: 20),
        _buildSectionTitle(
            _isHoodieSelected ? '5. Shipping Details' : '4. Shipping Details'),
        _buildShippingForm(),
        const SizedBox(height: 24),
        _buildPlaceOrderButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTrialBanner() {
    return GestureDetector(
      onTap: _showUpsellDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.deepOrange.withValues(alpha: 0.1)
          ]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Upgrade to Basic or higher to place print orders.',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),
            const Text('Upgrade →',
                style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildArtworkSelector() {
    if (_currentUser == null) {
      return const Text('Not signed in', style: TextStyle(color: Colors.grey));
    }
    return SizedBox(
      height: 130,
      child: StreamBuilder<List<ArtPost>>(
        stream: _artPostService.getUserPosts(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined,
                        color: Colors.grey, size: 32),
                    SizedBox(height: 6),
                    Text('Upload artwork first to print it',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final post = posts[i];
              final isSelected = _selectedArtwork?.postId == post.postId;
              return GestureDetector(
                onTap: () => setState(() => _selectedArtwork = post),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected ? Colors.deepPurple : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: post.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            color: Colors.deepPurple.withValues(alpha: 0.35),
                            child: const Icon(Icons.check_circle,
                                color: Colors.white, size: 28),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPrintTypeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _printTypes.map((type) {
        final isSelected = _selectedPrintType == type['key'];
        return GestureDetector(
          onTap: () => setState(() {
            _selectedPrintType = type['key'] as String;
            if (!_isHoodieSelected) {
              _selectedHoodieColor = 'black';
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepPurple : Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.deepPurple : Colors.grey[700]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type['icon'] as IconData,
                    size: 18, color: isSelected ? Colors.white : Colors.grey),
                const SizedBox(width: 6),
                Text(type['label'] as String,
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHoodieColorSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _hoodieColors.map((colorKey) {
        final isSelected = _selectedHoodieColor == colorKey;
        final label = colorKey
            .split('_')
            .map((part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedHoodieColor = colorKey),
          selectedColor: Colors.deepPurple,
          backgroundColor: Colors.grey[850],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
          ),
          side: BorderSide(
            color: isSelected ? Colors.deepPurple : Colors.grey[700]!,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeSelector() {
    return Wrap(
      spacing: 8,
      children: _sizes.map((size) {
        final isSelected = _selectedSize == size;
        final label = PrintOrderService.sizeLabels[size] ?? size;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedSize = size),
          selectedColor: Colors.deepPurple,
          backgroundColor: Colors.grey[850],
          labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey, fontSize: 12),
          side: BorderSide(
              color: isSelected ? Colors.deepPurple : Colors.grey[700]!),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text('Quantity:', style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 16),
        IconButton(
          icon:
              const Icon(Icons.remove_circle_outline, color: Colors.deepPurple),
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
        ),
        Text('$_quantity',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
          onPressed: _quantity < 20 ? () => setState(() => _quantity++) : null,
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _priceRow(
              PrintOrderService.printTypeLabels[_selectedPrintType] ??
                  _selectedPrintType,
              '\$${_unitPrice.toStringAsFixed(2)} × $_quantity'),
          const Divider(color: Colors.grey),
          _priceRow('Total', '\$${_totalPrice.toStringAsFixed(2)}',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isTotal ? Colors.white : Colors.grey,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14)),
        Text(value,
            style: TextStyle(
                color: isTotal ? Colors.deepPurpleAccent : Colors.grey,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14)),
      ],
    );
  }

  Widget _buildShippingForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextInput(_nameController, 'Full Name', Icons.person_outline),
          const SizedBox(height: 10),
          _buildTextInput(
              _addressController, 'Street Address', Icons.home_outlined),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _buildTextInput(
                      _cityController, 'City', Icons.location_city_outlined)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildTextInput(
                      _postalController, 'Postal Code', Icons.numbers)),
            ],
          ),
          const SizedBox(height: 10),
          _buildTextInput(_countryController, 'Country Code (e.g. US)',
              Icons.flag_outlined),
        ],
      ),
    );
  }

  Widget _buildTextInput(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isPlacingOrder ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canOrder ? Colors.deepPurple : Colors.grey[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: _isPlacingOrder
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.local_print_shop, color: Colors.white),
        label: Text(
          _isPlacingOrder
              ? 'Placing Order...'
              : _canOrder
                  ? 'Place Order — \$${_totalPrice.toStringAsFixed(2)}'
                  : 'Upgrade to Order',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Order History Tab ───────────────────────────────────────────────────────

  Widget _buildOrderHistory() {
    if (_currentUser == null) {
      return const Center(
          child: Text('Not signed in', style: TextStyle(color: Colors.grey)));
    }
    return StreamBuilder<List<PrintOrder>>(
      stream: _printOrderService.getUserPrintOrders(_currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple));
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text('No orders yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                const SizedBox(height: 6),
                Text('Your print orders will appear here',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildOrderCard(orders[i]),
        );
      },
    );
  }

  Widget _buildOrderCard(PrintOrder order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: order.artworkImageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey[800],
                  child: const Icon(Icons.image, color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.artworkTitle,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${PrintOrderService.printTypeLabels[order.printType] ?? order.printType}  •  '
                  '${order.productColor != null ? '${order.productColor!.replaceAll('_', ' ')}  •  ' : ''}'
                  '${PrintOrderService.sizeLabels[order.size] ?? order.size}  •  '
                  'Qty ${order.quantity}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: order.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: order.statusColor.withValues(alpha: 0.6)),
                      ),
                      child: Text(order.statusLabel,
                          style: TextStyle(
                              color: order.statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text('\$${order.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

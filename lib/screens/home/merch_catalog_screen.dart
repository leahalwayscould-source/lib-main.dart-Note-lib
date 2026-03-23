import 'package:flutter/material.dart';

import '../../models/art_post.dart';
import '../../services/gallery_cart_service.dart';
import '../../services/print_order_service.dart';

class MerchCatalogScreen extends StatefulWidget {
  const MerchCatalogScreen({
    super.key,
    required this.post,
  });

  final ArtPost post;

  @override
  State<MerchCatalogScreen> createState() => _MerchCatalogScreenState();
}

class _MerchCatalogScreenState extends State<MerchCatalogScreen> {
  static const List<String> _productOrder = [
    'poster',
    'canvas',
    'framed',
    'tote_bag',
    'phone_case',
    'adult_hoodie_pullover',
  ];

  static const List<String> _hoodieColors = [
    'black',
    'white',
    'navy',
    'charcoal',
    'heather_gray',
    'maroon',
    'forest_green',
  ];

  static const Map<String, Color> _frameColors = {
    'black': Color(0xFF1F1F1F),
    'white': Color(0xFFF2F2F2),
    'oak': Color(0xFFAA7A45),
    'walnut': Color(0xFF5B3A29),
    'gold': Color(0xFFC9A227),
  };

  String _selectedProduct = 'poster';
  String _selectedSize = 'medium';
  String _selectedHoodieColor = 'black';
  String _selectedFrameColor = 'walnut';
  int _quantity = 1;

  bool get _isHoodie => _selectedProduct == 'adult_hoodie_pullover';
  bool get _isFramed => _selectedProduct == 'framed';

  double get _unitPrice =>
      PrintOrderService.getPrice(_selectedProduct, _selectedSize);
  double get _totalPrice => _unitPrice * _quantity;

  String? get _selectedColor {
    if (_isHoodie) {
      return _selectedHoodieColor;
    }
    if (_isFramed) {
      return _selectedFrameColor;
    }
    return null;
  }

  void _addToCart() {
    GalleryCartService.addMerch(
      post: widget.post,
      merchType: _selectedProduct,
      size: _selectedSize,
      color: _selectedColor,
      quantity: _quantity,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added item to cart.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Prints And Merch'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ArtworkHeader(post: widget.post),
          const SizedBox(height: 16),
          Text(
            'Choose an item to preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _productOrder.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final type = _productOrder[index];
              final label = PrintOrderService.printTypeLabels[type] ?? type;
              final selected = type == _selectedProduct;

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _selectedProduct = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.deepPurple.withValues(alpha: 0.2)
                        : Colors.grey[850],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          selected ? Colors.deepPurple : Colors.grey.shade700,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: _ProductPreview(
                            imageUrl: widget.post.imageUrl,
                            productType: type,
                            frameColor: _frameColors[_selectedFrameColor]!,
                            hoodieColorName: _selectedHoodieColor,
                            width: 100,
                            height: 90,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Live Preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Center(
              child: _ProductPreview(
                imageUrl: widget.post.imageUrl,
                productType: _selectedProduct,
                frameColor: _frameColors[_selectedFrameColor]!,
                hoodieColorName: _selectedHoodieColor,
                width: 220,
                height: 180,
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedSize,
            decoration: const InputDecoration(labelText: 'Size'),
            items: PrintOrderService.sizeLabels.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedSize = value;
              });
            },
          ),
          if (_isFramed) ...[
            const SizedBox(height: 12),
            Text(
              'Frame Color',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _frameColors.entries.map((entry) {
                final selected = _selectedFrameColor == entry.key;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFrameColor = entry.key;
                    });
                  },
                  label: Text(entry.key),
                  avatar: CircleAvatar(backgroundColor: entry.value),
                );
              }).toList(),
            ),
          ],
          if (_isHoodie) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedHoodieColor,
              decoration: const InputDecoration(labelText: 'Hoodie Color'),
              items: _hoodieColors
                  .map(
                    (color) => DropdownMenuItem<String>(
                      value: color,
                      child: Text(color),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedHoodieColor = value;
                });
              },
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Quantity'),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _quantity <= 1
                    ? null
                    : () => setState(() => _quantity -= 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_quantity'),
              IconButton(
                onPressed: () => setState(() => _quantity += 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
              const Spacer(),
              Text(
                '\$${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add To Cart'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ArtworkHeader extends StatelessWidget {
  const _ArtworkHeader({required this.post});

  final ArtPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 84,
              height: 84,
              child: post.imageUrl.isNotEmpty
                  ? Image.network(post.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_outlined),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.artistName,
                  style: TextStyle(color: Colors.grey[300]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Artist offers original, prints, and merch from this artwork.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview({
    required this.imageUrl,
    required this.productType,
    required this.frameColor,
    required this.hoodieColorName,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final String productType;
  final Color frameColor;
  final String hoodieColorName;
  final double width;
  final double height;

  Color _hoodieColor(String name) {
    switch (name) {
      case 'white':
        return const Color(0xFFECECEC);
      case 'navy':
        return const Color(0xFF1C2B5A);
      case 'charcoal':
        return const Color(0xFF3E3E42);
      case 'heather_gray':
        return const Color(0xFF9EA3A8);
      case 'maroon':
        return const Color(0xFF672E3B);
      case 'forest_green':
        return const Color(0xFF2A4B3C);
      case 'black':
      default:
        return const Color(0xFF1E1E1E);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (productType == 'tote_bag') {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFD9C9AE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _ArtworkFill(imageUrl: imageUrl),
        ),
      );
    }

    if (productType == 'phone_case') {
      return Container(
        width: width * 0.6,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _ArtworkFill(imageUrl: imageUrl),
          ),
        ),
      );
    }

    if (productType == 'adult_hoodie_pullover') {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _hoodieColor(hoodieColorName),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _ArtworkFill(imageUrl: imageUrl),
          ),
        ),
      );
    }

    if (productType == 'framed') {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _ArtworkFill(imageUrl: imageUrl),
            ),
          ),
        ),
      );
    }

    if (productType == 'canvas') {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFECDCC4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC5B497), width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: _ArtworkFill(imageUrl: imageUrl),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: _ArtworkFill(imageUrl: imageUrl),
      ),
    );
  }
}

class _ArtworkFill extends StatelessWidget {
  const _ArtworkFill({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[700],
              child: const Icon(Icons.image_outlined),
            ),
          )
        : Container(
            color: Colors.grey[700],
            child: const Icon(Icons.image_outlined),
          );
  }
}

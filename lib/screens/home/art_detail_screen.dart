import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/art_post.dart';
import '../../models/critique.dart';
import '../../services/art_post_service.dart';
import '../../services/critique_service.dart';
import '../../services/gallery_cart_service.dart';
import '../../services/print_order_service.dart';
import 'artwork_checkout_screen.dart';
import 'cart_checkout_screen.dart';
import 'merch_catalog_screen.dart';

class ArtDetailScreen extends StatefulWidget {
  final ArtPost post;

  const ArtDetailScreen({super.key, required this.post});

  @override
  State<ArtDetailScreen> createState() => _ArtDetailScreenState();
}

class _ArtDetailScreenState extends State<ArtDetailScreen> {
  final _critiqueController = TextEditingController();
  double _selectedRating = 3.0;
  final CritiqueService _critiqueService = CritiqueService();
  final ArtPostService _artPostService = ArtPostService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isSubmittingCritique = false;
  static final double _startingPrintPrice = PrintOrderService.pricing.values
      .expand((sizeMap) => sizeMap.values)
      .reduce((a, b) => a < b ? a : b);

  @override
  void initState() {
    super.initState();
    _artPostService.incrementViewCount(widget.post.postId);
  }

  @override
  void dispose() {
    _critiqueController.dispose();
    super.dispose();
  }

  Future<void> _submitCritique() async {
    if (_critiqueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a critique')),
      );
      return;
    }

    setState(() => _isSubmittingCritique = true);

    try {
      final critique = Critique(
        critiqueId: '',
        postId: widget.post.postId,
        critiquerUid: _currentUser!.uid,
        critiquerName: _currentUser!.displayName ?? 'Anonymous',
        critiquerProfileImage: _currentUser!.photoURL ?? '',
        comment: _critiqueController.text,
        rating: _selectedRating,
        likes: 0,
        likedBy: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _critiqueService.createCritique(critique);
      _critiqueController.clear();
      _selectedRating = 3.0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Critique posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting critique: $e')),
        );
      }
    }

    setState(() => _isSubmittingCritique = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Art Details'),
        actions: [
          ValueListenableBuilder<List<dynamic>>(
            valueListenable: GalleryCartService.itemsNotifier,
            builder: (context, _, __) {
              final cartCount = GalleryCartService.itemCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Open Cart Checkout',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartCheckoutScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Art Image
          SliverAppBar(
            expandedHeight: 400,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.grey[800],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.post.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.post.imageUrl,
                      fit: BoxFit.cover,
                      memCacheHeight: 1000,
                      memCacheWidth: 1000,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (context, _) =>
                          Container(color: Colors.grey[800]),
                      errorWidget: (context, _, __) => Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                          size: 64,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.image,
                        color: Colors.grey[600],
                        size: 64,
                      ),
                    ),
            ),
          ),
          // Art Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.post.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Chip(
                        label: Text(
                            '\$${widget.post.askingPrice.toStringAsFixed(0)}'),
                        backgroundColor: Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _AvailabilityPill(
                        icon: Icons.verified,
                        label: 'Original for sale',
                        color: Colors.green,
                      ),
                      _AvailabilityPill(
                        icon: Icons.local_print_shop,
                        label:
                            'Prints and merch from \$${_startingPrintPrice.toStringAsFixed(2)}',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'You can buy the original here, then open a dedicated Prints And Merch screen with live product previews and frame color options.',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Artist Info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            widget.post.artistProfileImage.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    widget.post.artistProfileImage,
                                  )
                                : null,
                        child: widget.post.artistProfileImage.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.artistName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${widget.post.medium} • ${widget.post.style}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatBox(
                        label: 'Views',
                        value: widget.post.viewCount.toString(),
                      ),
                      _StatBox(
                        label: 'Likes',
                        value: widget.post.likeCount.toString(),
                      ),
                      _StatBox(
                        label: 'Critiques',
                        value: widget.post.critiqueCount.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          GalleryCartService.addOriginal(widget.post);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Original added to cart.'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add Original'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MerchCatalogScreen(
                                post: widget.post,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_mall_outlined),
                        label: const Text('Shop Prints And Merch'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArtworkCheckoutScreen(
                                post: widget.post,
                                initialIntent: 'Commission something similar',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.draw_outlined),
                        label: const Text('Commission'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add items while browsing, then use the cart icon to checkout once when you are finished shopping.',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.post.description,
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  if (widget.post.tags.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tags',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: widget.post.tags
                              .map(
                                (tag) => Chip(
                                  label: Text('#$tag'),
                                  backgroundColor:
                                      Colors.deepPurple.withValues(alpha: 0.3),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // Critique Section
                  Text(
                    'Critiques',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Submit Critique Form
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Your Critique',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),

                        // Rating Slider
                        Row(
                          children: [
                            const Text('Rating: '),
                            Expanded(
                              child: Slider(
                                value: _selectedRating,
                                min: 1,
                                max: 5,
                                divisions: 4,
                                onChanged: (value) {
                                  setState(() => _selectedRating = value);
                                },
                              ),
                            ),
                            Text('${_selectedRating.toStringAsFixed(1)} ⭐'),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Critique Text
                        TextField(
                          controller: _critiqueController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts about this art...',
                            filled: true,
                            fillColor: Colors.grey[700],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isSubmittingCritique ? null : _submitCritique,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmittingCritique
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Post Critique'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Critiques List
                  StreamBuilder<List<Critique>>(
                    stream:
                        _critiqueService.getPostCritiques(widget.post.postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text(
                          'No critiques yet. Be the first!',
                          style: TextStyle(color: Colors.grey[400]),
                        );
                      }

                      final critiques = snapshot.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: critiques.length,
                        itemBuilder: (context, index) {
                          final critique = critiques[index];
                          return _CritiqueCard(critique: critique);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CritiqueCard extends StatelessWidget {
  final Critique critique;

  const _CritiqueCard({required this.critique});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: critique.critiquerProfileImage.isNotEmpty
                    ? NetworkImage(critique.critiquerProfileImage)
                    : null,
                child: critique.critiquerProfileImage.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      critique.critiquerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '⭐ ${critique.rating.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            critique.comment,
            style: TextStyle(color: Colors.grey[200]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.thumb_up, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                critique.likes.toString(),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

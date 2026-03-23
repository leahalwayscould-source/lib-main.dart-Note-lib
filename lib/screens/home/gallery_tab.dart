import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/art_post.dart';
import '../../services/art_post_service.dart';
import '../../services/gallery_cart_service.dart';
import '../../services/print_order_service.dart';
import 'art_detail_screen.dart';
import 'artwork_checkout_screen.dart';
import 'cart_checkout_screen.dart';
import 'merch_catalog_screen.dart';
import 'subscription_plans_screen.dart';
import 'upload_art_screen.dart';

class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab>
    with AutomaticKeepAliveClientMixin<GalleryTab> {
  @override
  bool get wantKeepAlive => true;

  final ArtPostService _artPostService = ArtPostService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  static final double _startingPrintPrice = PrintOrderService.pricing.values
      .expand((sizeMap) => sizeMap.values)
      .reduce((a, b) => a < b ? a : b);

  void _addOriginalToCart(ArtPost post) {
    GalleryCartService.addOriginal(post);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added original to cart: ${post.title}')),
    );
  }

  void _openMerchCatalog(ArtPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchCatalogScreen(post: post),
      ),
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartCheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Art Gallery'),
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
                    onPressed: _openCart,
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
          IconButton(
            tooltip: 'Subscription Plans',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPlansScreen(),
                ),
              );
            },
            icon: const Icon(Icons.workspace_premium),
          ),
          IconButton(
            tooltip: 'Upload Art',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadArtScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: StreamBuilder<List<ArtPost>>(
        stream: _artPostService.getAllPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No art posts yet',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isLiked = post.likedBy.contains(_currentUser?.uid);

              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Artist Info
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: post.artistProfileImage.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    post.artistProfileImage,
                                  )
                                : null,
                            child: post.artistProfileImage.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.artistName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  post.title,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                                '\$${post.askingPrice.toStringAsFixed(0)}'),
                            backgroundColor: Colors.deepPurple,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SalePill(
                            icon: Icons.verified,
                            label: 'Original for sale',
                            color: Colors.green,
                          ),
                          _SalePill(
                            icon: Icons.local_print_shop,
                            label:
                                'Prints and merch from \$${_startingPrintPrice.toStringAsFixed(2)}',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Art Image
                    if (post.imageUrl.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 250,
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl,
                          fit: BoxFit.cover,
                          memCacheHeight: 600,
                          memCacheWidth: 800,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (context, _) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, _, __) => Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Description
                    if (post.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          post.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ),
                    if (post.description.toLowerCase().contains('print'))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: () => _openMerchCatalog(post),
                            icon: const Icon(Icons.local_mall_outlined),
                            label: const Text('Shop Prints'),
                          ),
                        ),
                      ),
                    // Tags
                    if (post.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 4,
                          children: post.tags
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    '#$tag',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor:
                                      Colors.deepPurple.withValues(alpha: 0.3),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    // Interactions
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InteractionButton(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: post.likeCount.toString(),
                            color: isLiked ? Colors.red : Colors.grey,
                            onTap: () async {
                              if (isLiked) {
                                await _artPostService.unlikePost(
                                  post.postId,
                                  _currentUser!.uid,
                                );
                              } else {
                                await _artPostService.likePost(
                                  post.postId,
                                  _currentUser!.uid,
                                );
                              }
                            },
                          ),
                          _InteractionButton(
                            icon: Icons.comment,
                            label: post.critiqueCount.toString(),
                            color: Colors.grey,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ArtDetailScreen(post: post),
                                ),
                              );
                            },
                          ),
                          _InteractionButton(
                            icon: Icons.visibility,
                            label: post.viewCount.toString(),
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _addOriginalToCart(post),
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Add Original'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openMerchCatalog(post),
                            icon: const Icon(Icons.local_mall_outlined),
                            label: const Text('Add Merch'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArtDetailScreen(
                                    post: post,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('View Details'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArtworkCheckoutScreen(
                                    post: post,
                                    initialIntent:
                                        'Commission something similar',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.draw_outlined),
                            label: const Text('Commission'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Use Add Original or Add Merch while browsing, then open the cart icon in the header to checkout when finished shopping.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openMerchCatalog(post),
                            child: const Text('Shop prints now'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SalePill extends StatelessWidget {
  const _SalePill({
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

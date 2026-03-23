import '../services/print_order_service.dart';
import 'art_post.dart';

enum GalleryCartItemKind { original, merch }

class GalleryCartItem {
  const GalleryCartItem({
    required this.kind,
    required this.post,
    required this.quantity,
    this.merchType,
    this.size,
    this.color,
  });

  final GalleryCartItemKind kind;
  final ArtPost post;
  final int quantity;
  final String? merchType;
  final String? size;
  final String? color;

  String get key {
    if (kind == GalleryCartItemKind.original) {
      return '${post.postId}:original';
    }
    return '${post.postId}:${merchType ?? 'poster'}:${size ?? 'medium'}:${color ?? ''}';
  }

  double get unitPrice {
    if (kind == GalleryCartItemKind.original) {
      return post.askingPrice;
    }
    return PrintOrderService.getPrice(merchType ?? 'poster', size ?? 'medium');
  }

  double get totalPrice => unitPrice * quantity;

  String get displayTitle {
    if (kind == GalleryCartItemKind.original) {
      return '${post.title} (Original)';
    }

    final merchLabel =
        PrintOrderService.printTypeLabels[merchType ?? 'poster'] ??
            'Print Product';
    final sizeLabel = PrintOrderService.sizeLabels[size ?? 'medium'] ??
        (size ?? 'medium').toUpperCase();
    if (color == null || color!.isEmpty) {
      return '${post.title} ($merchLabel • $sizeLabel)';
    }
    return '${post.title} ($merchLabel • $sizeLabel • ${color!})';
  }

  GalleryCartItem copyWith({
    int? quantity,
  }) {
    return GalleryCartItem(
      kind: kind,
      post: post,
      quantity: quantity ?? this.quantity,
      merchType: merchType,
      size: size,
      color: color,
    );
  }
}

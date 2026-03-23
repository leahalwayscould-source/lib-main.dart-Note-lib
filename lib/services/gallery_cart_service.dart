import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../models/gallery_cart_item.dart';

class GalleryCartService {
  static final ValueNotifier<List<GalleryCartItem>> itemsNotifier =
      ValueNotifier<List<GalleryCartItem>>(<GalleryCartItem>[]);

  static List<GalleryCartItem> get items => itemsNotifier.value;

  static int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  static double get subtotal =>
      items.fold(0, (sum, item) => sum + item.totalPrice);

  static void addOriginal(ArtPost post) {
    final current = List<GalleryCartItem>.from(itemsNotifier.value);
    final originalKey = '${post.postId}:original';
    final existingIndex = current.indexWhere((item) => item.key == originalKey);
    if (existingIndex >= 0) {
      return;
    }

    current.add(
      GalleryCartItem(
        kind: GalleryCartItemKind.original,
        post: post,
        quantity: 1,
      ),
    );
    itemsNotifier.value = current;
  }

  static void addMerch({
    required ArtPost post,
    required String merchType,
    required String size,
    String? color,
    int quantity = 1,
  }) {
    final current = List<GalleryCartItem>.from(itemsNotifier.value);
    final incoming = GalleryCartItem(
      kind: GalleryCartItemKind.merch,
      post: post,
      quantity: quantity,
      merchType: merchType,
      size: size,
      color: color,
    );

    final existingIndex =
        current.indexWhere((item) => item.key == incoming.key);
    if (existingIndex >= 0) {
      final existing = current[existingIndex];
      current[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      current.add(incoming);
    }

    itemsNotifier.value = current;
  }

  static void updateQuantity(String key, int quantity) {
    final current = List<GalleryCartItem>.from(itemsNotifier.value);
    final index = current.indexWhere((item) => item.key == key);
    if (index < 0) {
      return;
    }

    if (quantity <= 0) {
      current.removeAt(index);
    } else {
      current[index] = current[index].copyWith(quantity: quantity);
    }
    itemsNotifier.value = current;
  }

  static void remove(String key) {
    final current = List<GalleryCartItem>.from(itemsNotifier.value)
      ..removeWhere((item) => item.key == key);
    itemsNotifier.value = current;
  }

  static void clear() {
    itemsNotifier.value = <GalleryCartItem>[];
  }
}

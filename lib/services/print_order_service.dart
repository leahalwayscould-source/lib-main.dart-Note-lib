import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/print_order.dart';

class PrintOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Pricing matrix: printType → size → price (USD)
  static const Map<String, Map<String, double>> pricing = {
    'poster': {
      'small': 12.99,
      'medium': 19.99,
      'large': 29.99,
      'xlarge': 44.99,
    },
    'canvas': {
      'small': 29.99,
      'medium': 49.99,
      'large': 79.99,
      'xlarge': 119.99,
    },
    'framed': {
      'small': 39.99,
      'medium': 64.99,
      'large': 99.99,
      'xlarge': 149.99,
    },
    'tote_bag': {
      'small': 18.99,
      'medium': 22.99,
      'large': 22.99,
      'xlarge': 22.99,
    },
    'phone_case': {
      'small': 16.99,
      'medium': 16.99,
      'large': 16.99,
      'xlarge': 16.99,
    },
    'adult_hoodie_pullover': {
      'small': 39.99,
      'medium': 42.99,
      'large': 44.99,
      'xlarge': 47.99,
    },
  };

  static const Map<String, String> printTypeLabels = {
    'poster': 'Art Poster',
    'canvas': 'Canvas Print',
    'framed': 'Framed Print',
    'tote_bag': 'Tote Bag',
    'phone_case': 'Phone Case',
    'adult_hoodie_pullover': 'Adult Hoodie Pullover',
  };

  static const Map<String, String> sizeLabels = {
    'small': 'Small (8×10 in)',
    'medium': 'Medium (11×14 in)',
    'large': 'Large (16×20 in)',
    'xlarge': 'XL (24×36 in)',
  };

  static double getPrice(String printType, String size) {
    return pricing[printType]?[size] ?? 19.99;
  }

  Future<String> createPrintOrder(PrintOrder order) async {
    final callable = _functions.httpsCallable('createPrintOrder');
    final result = await callable.call({
      'artistUid': order.artistUid,
      'artworkId': order.artworkId,
      'artworkTitle': order.artworkTitle,
      'artworkImageUrl': order.artworkImageUrl,
      'printType': order.printType,
      'productColor': order.productColor,
      'size': order.size,
      'quantity': order.quantity,
      'shippingName': order.shippingName,
      'shippingAddress': order.shippingAddress,
      'shippingCity': order.shippingCity,
      'shippingCountry': order.shippingCountry,
      'shippingPostalCode': order.shippingPostalCode,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final orderId = data['orderId'] as String?;
    if (orderId == null || orderId.isEmpty) {
      throw Exception('Failed to create print order. Missing orderId.');
    }
    return orderId;
  }

  Stream<List<PrintOrder>> getUserPrintOrders(String userId) {
    return _firestore
        .collection('printOrders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PrintOrder.fromFirestore(doc)).toList());
  }

  Future<void> cancelPrintOrder(String orderId) async {
    final callable = _functions.httpsCallable('cancelPrintOrder');
    await callable.call({'orderId': orderId});
  }
}

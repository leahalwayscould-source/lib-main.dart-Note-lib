import 'package:cloud_firestore/cloud_firestore.dart';

class ArtworkOrder {
  ArtworkOrder({
    required this.orderId,
    required this.userId,
    required this.artistName,
    required this.artworkId,
    required this.artworkTitle,
    required this.amount,
    required this.currency,
    required this.checkoutType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.stripeSessionId = '',
    this.stripePaymentIntentId = '',
    this.stripeCustomerId = '',
    this.checkoutUrl,
    this.note = '',
  });

  final String orderId;
  final String userId;
  final String artistName;
  final String artworkId;
  final String artworkTitle;
  final double amount;
  final String currency;
  final String checkoutType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String stripeSessionId;
  final String stripePaymentIntentId;
  final String stripeCustomerId;
  final String? checkoutUrl;
  final String note;

  factory ArtworkOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ArtworkOrder(
      orderId: doc.id,
      userId: data['userId'] ?? '',
      artistName: data['artistName'] ?? '',
      artworkId: data['artworkId'] ?? '',
      artworkTitle: data['artworkTitle'] ?? 'Untitled artwork',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'usd',
      checkoutType: data['checkoutType'] ?? 'artwork',
      status: data['status'] ?? 'pending',
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
      stripeSessionId: data['stripeSessionId'] ?? '',
      stripePaymentIntentId: data['stripePaymentIntentId'] ?? '',
      stripeCustomerId: data['stripeCustomerId'] ?? '',
      checkoutUrl: data['checkoutUrl'] as String?,
      note: data['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'artistName': artistName,
      'artworkId': artworkId,
      'artworkTitle': artworkTitle,
      'amount': amount,
      'currency': currency,
      'checkoutType': checkoutType,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'stripeSessionId': stripeSessionId,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeCustomerId': stripeCustomerId,
      'checkoutUrl': checkoutUrl,
      'note': note,
    };
  }

  bool get isSandboxOrder => checkoutType == 'artwork_sandbox';

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.now();
  }
}

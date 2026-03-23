import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PrintOrder {
  final String orderId;
  final String userId;
  final String artistUid;
  final String artworkId;
  final String artworkTitle;
  final String artworkImageUrl;
  final String
      printType; // poster, canvas, framed, tote_bag, phone_case, adult_hoodie_pullover
  final String? productColor;
  final String size; // small, medium, large, xlarge
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String status; // pending, processing, shipped, delivered, cancelled
  final String provider; // manual, printful, printify, etc.
  final String providerStatus;
  final String? providerOrderId;
  final String? trackingNumber;
  final String? trackingUrl;
  final String shippingName;
  final String shippingAddress;
  final String shippingCity;
  final String shippingCountry;
  final String shippingPostalCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PrintOrder({
    required this.orderId,
    required this.userId,
    required this.artistUid,
    required this.artworkId,
    required this.artworkTitle,
    required this.artworkImageUrl,
    required this.printType,
    this.productColor,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
    required this.provider,
    required this.providerStatus,
    this.providerOrderId,
    this.trackingNumber,
    this.trackingUrl,
    required this.shippingName,
    required this.shippingAddress,
    required this.shippingCity,
    required this.shippingCountry,
    required this.shippingPostalCode,
    required this.createdAt,
    this.updatedAt,
  });

  factory PrintOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrintOrder(
      orderId: doc.id,
      userId: data['userId'] ?? '',
      artistUid: data['artistUid'] ?? '',
      artworkId: data['artworkId'] ?? '',
      artworkTitle: data['artworkTitle'] ?? '',
      artworkImageUrl: data['artworkImageUrl'] ?? '',
      printType: data['printType'] ?? 'poster',
      productColor: data['productColor'],
      size: data['size'] ?? 'medium',
      quantity: (data['quantity'] ?? 1) as int,
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      provider: data['provider'] ?? 'manual',
      providerStatus: data['providerStatus'] ?? 'queued',
      providerOrderId: data['providerOrderId'],
      trackingNumber: data['trackingNumber'],
      trackingUrl: data['trackingUrl'],
      shippingName: data['shippingName'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      shippingCity: data['shippingCity'] ?? '',
      shippingCountry: data['shippingCountry'] ?? '',
      shippingPostalCode: data['shippingPostalCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'artistUid': artistUid,
      'artworkId': artworkId,
      'artworkTitle': artworkTitle,
      'artworkImageUrl': artworkImageUrl,
      'printType': printType,
      'productColor': productColor,
      'size': size,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'status': status,
      'provider': provider,
      'providerStatus': providerStatus,
      'providerOrderId': providerOrderId,
      'trackingNumber': trackingNumber,
      'trackingUrl': trackingUrl,
      'shippingName': shippingName,
      'shippingAddress': shippingAddress,
      'shippingCity': shippingCity,
      'shippingCountry': shippingCountry,
      'shippingPostalCode': shippingPostalCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'processing':
        return const Color(0xFF2196F3);
      case 'shipped':
        return const Color(0xFF9C27B0);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFFF9800);
    }
  }
}

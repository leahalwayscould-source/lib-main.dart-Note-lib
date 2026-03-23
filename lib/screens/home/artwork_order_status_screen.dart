import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/artwork_order.dart';

class ArtworkOrderStatusScreen extends StatelessWidget {
  const ArtworkOrderStatusScreen({
    super.key,
    required this.order,
  });

  final ArtworkOrder order;

  Future<void> _openHostedCheckout(BuildContext context) async {
    final checkoutUrl = order.checkoutUrl;
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) {
      return;
    }

    final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!context.mounted || opened) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open checkout link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.simpleCurrency(name: order.currency.toUpperCase());

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Artwork Order'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.artworkTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'by ${order.artistName}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _OrderPill(label: order.status.replaceAll('_', ' ')),
                    _OrderPill(label: money.format(order.amount)),
                    _OrderPill(
                        label: DateFormat.yMMMd().format(order.createdAt)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Status',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  order.isSandboxOrder
                      ? 'This is a sandbox order record created so you can preview the collector order flow before live Stripe is deployed.'
                      : order.status == 'paid'
                          ? 'Payment completed successfully. The artist can now coordinate fulfillment.'
                          : 'This checkout has been created and is waiting for payment completion.',
                  style: TextStyle(color: Colors.grey[300], height: 1.5),
                ),
                if (order.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    order.note,
                    style: TextStyle(color: Colors.blue[200], height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          if (order.checkoutUrl != null && order.checkoutUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openHostedCheckout(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Hosted Checkout'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderPill extends StatelessWidget {
  const _OrderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.deepPurple[100],
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/market_order.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/marketplace/market_status_badge.dart';
// PATCH 01 (Critical Gap #1): DeliveryPaymentScreen was only reachable from
// DeliveryBoyScreen (itself unreachable), so the BUYER-side half of the flow
// — payment method selection (FR-PAY-001/002), delivery OTP generation
// (FR-DELIV-003) and receipt retrieval (FR-DELIV-004) — had no entry point at
// all. Those three backend endpoints are gated to FARMER/FPO/CONSUMER/
// BULK_BUYER, so the order detail screen is the correct entry point.
import 'delivery_payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  MarketOrder? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await context.read<OrderService>().getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Could not reach the server. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: _buildBody(),
    );
  }

  String _caseStatusLabel(dynamic status) {
    if (status == null) return '';
    final String statusStr = status is Enum ? status.name : status.toString();
    final words = statusStr.split('_');
    return words.map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}').join(' ');
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 40, color: AppTheme.danger.withOpacity(0.7)),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(child: Semantics(identifier: 'hf.mkt.order_detail.retry_button', child: OutlinedButton(key: const Key('hf.mkt.order_detail.retry_button'), onPressed: _load, child: const Text('Retry')))),
        ],
      );
    }

    final order = _order!;
    final userId = context.read<AuthService>().userId;
    final isSeller = order.sellerId == userId;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(order.cropName, style: Theme.of(context).textTheme.headlineSmall)),
            MarketStatusBadge.order(order.status),
          ],
        ),
        const SizedBox(height: 16),
        const SectionHeader('Parties'),
        LabeledValue(label: 'Seller', value: order.sellerName),
        LabeledValue(label: 'Buyer', value: order.buyerName),
        LabeledValue(label: 'Your Role', value: isSeller ? 'Seller' : 'Buyer'),
        const SizedBox(height: 16),
        const SectionHeader('Order'),
        LabeledValue(label: 'Quantity', value: order.quantity.toStringAsFixed(0)),
        LabeledValue(label: 'Agreed Price / Unit', value: '₹${order.agreedPricePerUnit.toStringAsFixed(2)}'),
        LabeledValue(label: 'Total Amount', value: '₹${order.totalAmount.toStringAsFixed(2)}', emphasize: true),
        LabeledValue(label: 'Created', value: dateFmt.format(order.createdAt)),
        if (order.expectedHarvestDate != null)
          LabeledValue(
            label: 'Expected Harvest Date',
            value: DateFormat('dd MMM yyyy').format(order.expectedHarvestDate!),
          ),
        if (order.deliveredAt != null)
          LabeledValue(label: 'Delivered', value: dateFmt.format(order.deliveredAt!)),
        // PATCH 01 (Critical Gap #1): buyer/seller entry point into the
        // payment + delivery flow. Reloads the order on return so the payment
        // status and delivered-at values shown here stay consistent with any
        // action taken on the pushed screen (no stale state, no duplicate
        // submission — the pushed screen owns its own busy-guard).
        const SizedBox(height: 20),
        Semantics(
          identifier: 'hf.mkt.order_detail.payment_delivery_button',
          child: ElevatedButton.icon(
            key: const Key('hf.mkt.order_detail.payment_delivery_button'),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Payment & Delivery'),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (_) => DeliveryPaymentScreen(orderId: widget.orderId),
                ))
                .then((_) {
                  if (mounted) _load();
                }),
          ),
        ),
        if (order.operationalStatus != null) ...[
          const SizedBox(height: 16),
          const SectionHeader('Internal Operations Status'),
          LabeledValue(label: 'Current Stage', value: _caseStatusLabel(order.operationalStatus)),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'The internal HarvestFlow team is handling plot, harvesting, packing, '
              'logistics and delivery. Payment is released automatically (simulated) '
              'once the internal workflow completes.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

}

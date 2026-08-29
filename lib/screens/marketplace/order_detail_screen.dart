import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/market_order.dart';
import '../../models/order_status.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/marketplace/market_status_badge.dart';

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
          Center(child: OutlinedButton(onPressed: _load, child: const Text('Retry'))),
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
        if (order.status == MarketOrderStatus.confirmed) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _completingDelivery ? null : _completeDelivery,
            icon: _completingDelivery
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.local_shipping_outlined),
            label: const Text('Confirm Delivery & Release Payment'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Payment is simulated — no real gateway is connected in this deployment.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  bool _completingDelivery = false;

  Future<void> _completeDelivery() async {
    setState(() => _completingDelivery = true);
    try {
      final updated = await context.read<OrderService>().completeDelivery(widget.orderId);
      if (!mounted) return;
      setState(() => _order = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery confirmed. Simulated payment released.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _completingDelivery = false);
    }
  }
}

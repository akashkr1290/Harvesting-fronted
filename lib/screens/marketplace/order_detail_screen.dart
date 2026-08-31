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
        if (order.expectedHarvestDate != null)
          LabeledValue(
            label: 'Expected Harvest Date',
            value: DateFormat('dd MMM yyyy').format(order.expectedHarvestDate!),
          ),
        if (order.deliveredAt != null)
          LabeledValue(label: 'Delivered', value: dateFmt.format(order.deliveredAt!)),
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

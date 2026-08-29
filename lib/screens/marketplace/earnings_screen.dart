import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/market_order.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/marketplace/order_card.dart';
import 'order_detail_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
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
      await context.read<OrderService>().fetchEarnings();
      if (mounted) setState(() => _loading = false);
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
    final earnings = context.watch<OrderService>().earnings;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(earnings)),
    );
  }

  Widget _buildBody(EarningsSummary? earnings) {
    if (_loading && earnings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && earnings == null) {
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
    if (earnings == null) {
      return const Center(child: Text('No data available.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppTheme.primary.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Earnings', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '₹${earnings.totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(label: 'Confirmed', value: '${earnings.confirmedOrders}'),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Completed', value: '${earnings.completedOrders}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (earnings.recentOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No orders yet.', style: TextStyle(color: Colors.grey))),
          )
        else
          for (final order in earnings.recentOrders)
            OrderCard(
              order: order,
              viewerId: order.sellerId,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
              ),
            ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

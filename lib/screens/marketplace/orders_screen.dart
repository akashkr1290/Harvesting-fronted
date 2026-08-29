import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/marketplace/order_card.dart';
import 'order_detail_screen.dart';

/// Same screen for both sides of a trade — GET /api/marketplace/orders
/// already returns only orders this user is a party to, whichever side.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.read<OrderService>().fetchOrders();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the server. Check your connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<OrderService>();
    final userId = context.watch<AuthService>().userId ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(service, userId)),
    );
  }

  Widget _buildBody(OrderService service, String userId) {
    if (service.isLoading && service.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && service.orders.isEmpty) {
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
    if (service.orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No orders yet.', style: TextStyle(color: Colors.grey))),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: service.orders.length,
      itemBuilder: (context, index) {
        final order = service.orders[index];
        return OrderCard(
          order: order,
          viewerId: userId,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
          ),
        );
      },
    );
  }
}

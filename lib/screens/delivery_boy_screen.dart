import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/delivery_service.dart';
import '../services/api_client.dart';
import '../services/localization_service.dart';
import 'marketplace/delivery_payment_screen.dart';

class DeliveryBoyScreen extends StatefulWidget {
  const DeliveryBoyScreen({super.key});

  @override
  State<DeliveryBoyScreen> createState() => _DeliveryBoyScreenState();
}

class _DeliveryBoyScreenState extends State<DeliveryBoyScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final x = await context.read<DeliveryService>().assigned();
      if (mounted) setState(() => _items = x);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not reach the server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Assignments')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Assignments')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: _items.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (ctx, i) {
            final x = _items[i];
            return Card(
              child: ListTile(
                title: Text("${x['cropName']} \u2022 \u20b9${x['amount']}"),
                subtitle: Text(
                  "${x['farmerName']} \u2192 ${x['buyerName']}\n"
                  "${x['status']} \u2022 Payment: ${x['paymentStatus'] ?? 'PENDING'}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.local_shipping),
                  tooltip: loc.t('completeDelivery'),
                  onPressed: () => Navigator.of(ctx)
                      .push(MaterialPageRoute(
                        builder: (_) => DeliveryPaymentScreen(
                          orderId: x['orderId'] as String,
                        ),
                      ))
                      .then((_) => _load()),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

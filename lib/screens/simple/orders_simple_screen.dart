import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/market_order.dart';
import '../../models/order_status.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';
import '../../services/order_service.dart';
import '../../widgets/simple/crop_art.dart';
import '../../widgets/simple/simple_ui.dart';

/// Each order as a picture timeline: Sold → Buyer paid → Delivered → Money in bank.
class OrdersSimpleScreen extends StatefulWidget {
  const OrdersSimpleScreen({super.key});

  @override
  State<OrdersSimpleScreen> createState() => _OrdersSimpleScreenState();
}

class _OrdersSimpleScreenState extends State<OrdersSimpleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderService>().fetchOrders().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final service = context.watch<OrderService>();
    final me = context.watch<AuthService>().userId;
    final orders = service.orders;

    String speech() => orders.isEmpty
        ? loc.t('no_orders')
        : orders.take(5).map((o) => '${localCropName(loc, o.cropName)} ${o.quantity.toStringAsFixed(0)} ${loc.t('kg')}, '
            '${rupees(o.totalAmount)}, ${_stepLabel(loc, _currentStep(o))}').join('. ');

    return SimplePage(
      header: SimpleHeader(title: loc.t('orders'), speakText: speech),
      children: [
        if (service.isLoading && orders.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
        if (!service.isLoading && orders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(loc.t('no_orders'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 19)),
          ),
        for (final o in orders) ...[
          _OrderCard(order: o, iAmSeller: o.sellerId == me),
          const SizedBox(height: 14),
        ],
      ],
      bottom: const [HelpCallButton()],
    );
  }
}

/// 0 sold, 1 paid, 2 delivered, 3 money with farmer.
int _currentStep(MarketOrder o) {
  if (o.status == MarketOrderStatus.completed) return 3;
  if (o.isPaid) return 1;
  return 0;
}

String _stepLabel(LocalizationService loc, int step) =>
    [loc.t('step_sold'), loc.t('step_paid'), loc.t('step_delivered'), loc.t('step_money')][step];

class _OrderCard extends StatelessWidget {
  final MarketOrder order;
  final bool iAmSeller;
  const _OrderCard({required this.order, required this.iAmSeller});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final cancelled = order.status == MarketOrderStatus.cancelled;
    final step = _currentStep(order);
    final labels = [
      (loc.t('step_sold'), Icons.handshake_rounded),
      (loc.t('step_paid'), Icons.payments_rounded),
      (loc.t('step_delivered'), Icons.local_shipping_rounded),
      (loc.t('step_money'), Icons.account_balance_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SimpleColors.line, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CropPicture(cropName: order.cropName, size: 48),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${localCropName(loc, order.cropName)} · ${order.quantity.toStringAsFixed(0)} ${loc.t('kg')}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(iAmSeller ? order.buyerName : order.sellerName,
                  style: const TextStyle(fontSize: 15, color: SimpleColors.quiet)),
            ]),
          ),
          Text(rupees(order.totalAmount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        if (cancelled)
          StatusPill(kind: PillKind.bad, text: order.status.label)
        else
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= step ? SimpleColors.green : (i == step + 1 ? SimpleColors.orange : Colors.white),
                    border: Border.all(color: i <= step + 1 ? Colors.transparent : SimpleColors.line, width: 2),
                  ),
                  child: Icon(i <= step ? Icons.check_rounded : labels[i].$2,
                      color: i <= step + 1 ? Colors.white : SimpleColors.quiet, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(labels[i].$1,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: i == step + 1 ? FontWeight.w800 : FontWeight.w600,
                        color: i <= step + 1 ? SimpleColors.ink : SimpleColors.quiet,
                      )),
                ),
              ]),
            ),
        if (!cancelled && iAmSeller && step < 2) ...[
          const SizedBox(height: 6),
          Text(loc.t('keep_ready'), style: const TextStyle(fontSize: 16, color: SimpleColors.orange, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }
}

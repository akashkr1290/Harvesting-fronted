import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/localization_service.dart';
import '../../services/order_service.dart';
import '../../widgets/simple/crop_art.dart';
import '../../widgets/simple/simple_ui.dart';

/// Money received (delivered orders) and money still coming, in big numbers.
class MoneySimpleScreen extends StatefulWidget {
  const MoneySimpleScreen({super.key});

  @override
  State<MoneySimpleScreen> createState() => _MoneySimpleScreenState();
}

class _MoneySimpleScreenState extends State<MoneySimpleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderService>().fetchEarnings().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final e = context.watch<OrderService>().earnings;

    String speech() => e == null
        ? loc.t('loading')
        : '${loc.t('money_received')}: ${rupees(e.receivedAmount)}. ${loc.t('money_coming')}: ${rupees(e.expectedAmount)}';

    Widget box(String label, double amount, Color color, IconData icon) => Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 3),
          ),
          child: Row(children: [
            Icon(icon, size: 44, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 18, color: SimpleColors.quiet, fontWeight: FontWeight.w600)),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(rupees(amount), style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: color)),
                ),
              ]),
            ),
          ]),
        );

    return SimplePage(
      header: SimpleHeader(title: loc.t('my_money'), speakText: speech),
      children: [
        if (e == null)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
        else ...[
          box(loc.t('money_received'), e.receivedAmount, SimpleColors.green, Icons.account_balance_wallet_rounded),
          const SizedBox(height: 12),
          box(loc.t('money_coming'), e.expectedAmount, SimpleColors.orange, Icons.schedule_rounded),
          const SizedBox(height: 20),
          for (final o in e.recentOrders)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: CropPicture(cropName: o.cropName, size: 40),
              title: Text('${localCropName(loc, o.cropName)} · ${o.quantity.toStringAsFixed(0)} ${loc.t('kg')}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              subtitle: Text(o.buyerName, style: const TextStyle(fontSize: 15)),
              trailing: Text(rupees(o.totalAmount), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            ),
        ],
      ],
      bottom: const [HelpCallButton()],
    );
  }
}

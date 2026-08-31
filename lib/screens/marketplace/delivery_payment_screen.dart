import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_role.dart';
import '../../services/api_client.dart';
import '../../services/delivery_service.dart';
import '../../services/market_payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';

class DeliveryPaymentScreen extends StatefulWidget {
  final String orderId;
  const DeliveryPaymentScreen({super.key, required this.orderId});

  @override
  State<DeliveryPaymentScreen> createState() => _DeliveryPaymentScreenState();
}

class _DeliveryPaymentScreenState extends State<DeliveryPaymentScreen> {
  String? _qr, _otp, _error;
  bool _busy = false;
  Map<String, dynamic>? _receipt;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final loc = c.watch<LocalizationService>();
    final role = c.watch<AuthService>().role;
    final isDelivery = role == UserRole.pickupPerson;

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('payment'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),

          // --- Buyer side: payment selection + OTP generation ---
          if (!isDelivery) ...[
            _qr == null
                ? Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                  final r = await context
                                      .read<MarketPaymentService>()
                                      .digital(widget.orderId);
                                  setState(() =>
                                      _qr = r['paymentUrl'] as String?);
                                }),
                        child: Text(loc.t('digital')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                  await context
                                      .read<MarketPaymentService>()
                                      .selectCash(widget.orderId);
                                }),
                        child: Text(loc.t('cash')),
                      ),
                    ),
                  ])
                : Column(children: [
                    QrImageView(data: _qr!, size: 220),
                    Text(_qr!, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text(
                        'Gateway confirmation is server-side; this QR does not itself mark payment as paid.'),
                  ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        final otp = await context
                            .read<DeliveryService>()
                            .generateOtp(widget.orderId);
                        setState(() => _otp = otp);
                      }),
              child: Text(loc.t('generateOtp')),
            ),
            // OTP display is OUTSIDE the button, in the list
            if (_otp != null)
              SelectableText('${loc.t('deliveryOtp')}: $_otp'),
          ],

          // --- Delivery-person side: pickup milestones + OTP confirm ---
          if (isDelivery) ...[
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await context
                            .read<DeliveryService>()
                            .pickup(widget.orderId);
                      }),
              child: Text(loc.t('confirmPickup')),
            ),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await context
                            .read<DeliveryService>()
                            .reachBuyer(widget.orderId);
                      }),
              child: Text(loc.t('reachBuyer')),
            ),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await context
                            .read<MarketPaymentService>()
                            .cash(widget.orderId);
                      }),
              child: Text(loc.t('cash')),
            ),
            TextField(
              decoration:
                  InputDecoration(labelText: loc.t('deliveryOtp')),
              onChanged: (v) => _otp = v,
            ),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await context
                            .read<DeliveryService>()
                            .complete(widget.orderId, _otp ?? '');
                        final r = await context
                            .read<DeliveryService>()
                            .receipt(widget.orderId);
                        setState(() => _receipt = r);
                      }),
              child: Text(loc.t('completeDelivery')),
            ),
          ],

          if (_receipt != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_receipt.toString()),
              ),
            ),
        ],
      ),
    );
  }
}

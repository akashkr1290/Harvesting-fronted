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
  // PATCH 01: local confirmation flag for the delivery-person side, replacing
  // the removed (unauthorized) automatic receipt fetch.
  bool _deliveryCompleted = false;

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

  // PATCH 01: tiny presentation helper for the receipt card. Null/blank values
  // are hidden rather than printed as "null".
  Widget _receiptRow(String label, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text('$label:', style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: SelectableText(value.toString())),
        ],
      ),
    );
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
                      child: Semantics(identifier: 'hf.mkt.delivery_payment.select_digital_button', child: ElevatedButton(
                        key: const Key('hf.mkt.delivery_payment.select_digital_button'),
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
                      )),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(identifier: 'hf.mkt.delivery_payment.select_cash_button', child: OutlinedButton(
                        key: const Key('hf.mkt.delivery_payment.select_cash_button'),
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                  await context
                                      .read<MarketPaymentService>()
                                      .selectCash(widget.orderId);
                                }),
                        child: Text(loc.t('cash')),
                      )),
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
            Semantics(identifier: 'hf.mkt.delivery_payment.generate_otp_button', child: ElevatedButton(
              key: const Key('hf.mkt.delivery_payment.generate_otp_button'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        final otp = await context
                            .read<DeliveryService>()
                            .generateOtp(widget.orderId);
                        setState(() => _otp = otp);
                      }),
              child: Text(loc.t('generateOtp')),
            )),
            // OTP display is OUTSIDE the button, in the list
            if (_otp != null)
              SelectableText('${loc.t('deliveryOtp')}: $_otp'),
            const SizedBox(height: 12),
            // PATCH 01 (FR-DELIV-004): receipt retrieval belongs on the buyer/
            // seller side — this is the role the backend authorizes. The
            // backend returns it only once the order reaches COMPLETED
            // ("Receipt is available after delivery completion."), so this is
            // an explicit user action rather than an automatic fetch.
            Semantics(identifier: 'hf.mkt.delivery_payment.view_receipt_button', child: OutlinedButton(
              key: const Key('hf.mkt.delivery_payment.view_receipt_button'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        final r = await context
                            .read<DeliveryService>()
                            .receipt(widget.orderId);
                        if (mounted) setState(() => _receipt = r);
                      }),
              child: const Text('View Receipt'),
            )),
          ],

          // --- Delivery-person side: pickup milestones + OTP confirm ---
          if (isDelivery) ...[
            Semantics(identifier: 'hf.mkt.delivery_payment.confirm_pickup_button', child: ElevatedButton(
              key: const Key('hf.mkt.delivery_payment.confirm_pickup_button'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await context
                            .read<DeliveryService>()
                            .pickup(widget.orderId);
                      }),
              child: Text(loc.t('confirmPickup')),
            )),
            Semantics(identifier: 'hf.mkt.delivery_payment.reach_buyer_button', child: ElevatedButton(
              key: const Key('hf.mkt.delivery_payment.reach_buyer_button'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await context
                            .read<DeliveryService>()
                            .reachBuyer(widget.orderId);
                      }),
              child: Text(loc.t('reachBuyer')),
            )),
            Semantics(identifier: 'hf.mkt.delivery_payment.confirm_cash_button', child: ElevatedButton(
              key: const Key('hf.mkt.delivery_payment.confirm_cash_button'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await context
                            .read<MarketPaymentService>()
                            .cash(widget.orderId);
                      }),
              child: Text(loc.t('cash')),
            )),
            Semantics(identifier: 'hf.mkt.delivery_payment.otp_input_field', child: TextField(
              key: const Key('hf.mkt.delivery_payment.otp_input_field'),
              decoration:
                  InputDecoration(labelText: loc.t('deliveryOtp')),
              onChanged: (v) => _otp = v,
            )),
            Semantics(identifier: 'hf.mkt.delivery_payment.complete_delivery_button', child: ElevatedButton(
              key: const Key('hf.mkt.delivery_payment.complete_delivery_button'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await context
                            .read<DeliveryService>()
                            .complete(widget.orderId, _otp ?? '');
                        // PATCH 01: the receipt fetch that used to sit here was
                        // removed. GET /api/deliveries/{id}/receipt is
                        // @PreAuthorize("hasAnyRole('FARMER','FPO','CONSUMER',
                        // 'BULK_BUYER')") AND DeliveryService.receipt() further
                        // rejects any actor who is neither the order's buyer nor
                        // its seller — so for a PICKUP_PERSON this call could
                        // only ever throw, surfacing "Receipt access denied."
                        // immediately after a SUCCESSFUL delivery completion.
                        // The receipt is now retrieved on the buyer side, where
                        // the caller is actually authorized.
                        if (mounted) {
                          setState(() => _deliveryCompleted = true);
                        }
                      }),
              child: Text(loc.t('completeDelivery')),
            )),
            if (_deliveryCompleted)
              Semantics(
                identifier: 'hf.mkt.delivery_payment.delivery_completed_text',
                child: const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Delivery completed. The buyer and seller can now view the receipt '
                    'from their order details.',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
          ],

          // PATCH 01 (instruction 7): this card previously rendered the raw
          // Dart map via _receipt.toString(). Same data, same card, now shown
          // as labeled rows using the existing ReceiptResponse fields
          // (orderId, farmer, buyer, produce, quantity, finalAmount,
          // deliveryDateTime, paymentStatus, paymentMethod,
          // transactionReference). No redesign, no new model, no new API.
          if (_receipt != null)
            Semantics(
              identifier: 'hf.mkt.delivery_payment.receipt_card',
              child: Card(
                key: const Key('hf.mkt.delivery_payment.receipt_card'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt', style: Theme.of(c).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _receiptRow('Order', _receipt!['orderId']),
                      _receiptRow('Seller', _receipt!['farmer']),
                      _receiptRow('Buyer', _receipt!['buyer']),
                      _receiptRow('Produce', _receipt!['produce']),
                      _receiptRow('Quantity', _receipt!['quantity']),
                      _receiptRow('Final Amount', _receipt!['finalAmount']),
                      _receiptRow('Delivered At', _receipt!['deliveryDateTime']),
                      _receiptRow('Payment Status', _receipt!['paymentStatus']),
                      _receiptRow('Payment Method', _receipt!['paymentMethod']),
                      _receiptRow('Transaction Ref', _receipt!['transactionReference']),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

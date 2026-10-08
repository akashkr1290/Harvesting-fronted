import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/offer.dart';
import '../../models/offer_status.dart';
import '../../services/api_client.dart';
import '../../services/localization_service.dart';
import '../../services/market_price_service.dart';
import '../../services/offer_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/simple/crop_art.dart';
import '../../widgets/simple/simple_ui.dart';

/// Buyer offers as big cards: price per kg, mandi comparison, total, and two
/// buttons (Yes, sell / No). Accepting asks once more in plain words.
class OffersSimpleScreen extends StatefulWidget {
  const OffersSimpleScreen({super.key});

  @override
  State<OffersSimpleScreen> createState() => _OffersSimpleScreenState();
}

class _OffersSimpleScreenState extends State<OffersSimpleScreen> {
  final Map<String, double?> _mandi = {};
  String? _busyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final offers = context.read<OfferService>();
    final prices = context.read<MarketPriceService>();
    try {
      await offers.fetchReceived();
    } catch (_) {}
    for (final crop in offers.received.map((o) => o.cropName).toSet()) {
      final p = await prices.latest(crop);
      if (mounted) setState(() => _mandi[crop] = p?.modalPerKg);
    }
  }

  Future<void> _accept(Offer o) async {
    final loc = context.read<LocalizationService>();
    final total = rupees(o.totalAmount);
    final question = loc.tf('confirm_sell', {'qty': o.quantity.toStringAsFixed(0), 'total': total});
    context.read<VoiceService>().speak(question, language: loc.ttsLanguage);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          CropPicture(cropName: o.cropName, size: 64),
          const SizedBox(height: 10),
          Text(question, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          BigButton(label: loc.t('yes_sell'), icon: Icons.check_rounded, onPressed: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: 8),
          BigButton(
              label: loc.t('no'), outlined: true, color: SimpleColors.red, onPressed: () => Navigator.of(ctx).pop(false)),
        ]),
      ),
    );
    if (ok != true || !mounted) return;
    await _act(o.id, () => context.read<OfferService>().accept(o.id), loc.t('sold'));
  }

  Future<void> _reject(Offer o) async {
    final loc = context.read<LocalizationService>();
    await _act(o.id, () => context.read<OfferService>().reject(o.id), loc.t('offer_rejected_msg'));
  }

  Future<void> _act(String id, Future<Object?> Function() call, String doneMessage) async {
    final loc = context.read<LocalizationService>();
    final voice = context.read<VoiceService>();
    setState(() => _busyId = id);
    try {
      await call();
      voice.speak(doneMessage, language: loc.ttsLanguage);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(doneMessage, style: const TextStyle(fontSize: 18))));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.t('no_internet'))));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final service = context.watch<OfferService>();
    final pending = service.received.where((o) => o.status == OfferStatus.pending && !o.isExpired).toList()
      ..sort((a, b) => b.pricePerUnit.compareTo(a.pricePerUnit));
    final bestPerListing = <String, String>{};
    for (final o in pending) {
      bestPerListing.putIfAbsent(o.listingId, () => o.id);
    }

    String speech() => pending.isEmpty
        ? loc.t('no_offers')
        : pending
            .map((o) =>
                '${localCropName(loc, o.cropName)} ${o.quantity.toStringAsFixed(0)} ${loc.t('kg')}, ₹${o.pricePerUnit.toStringAsFixed(0)} ${loc.t('per_kg')}')
            .join('. ');

    return SimplePage(
      header: SimpleHeader(title: loc.t('offers'), speakText: speech),
      children: [
        if (service.isLoading && pending.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
        if (!service.isLoading && pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(children: [
              const Icon(Icons.inbox_rounded, size: 72, color: SimpleColors.quiet),
              const SizedBox(height: 12),
              Text(loc.t('no_offers'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 19)),
            ]),
          ),
        for (final o in pending) ...[
          _OfferCard(
            offer: o,
            mandi: _mandi[o.cropName],
            best: bestPerListing[o.listingId] == o.id && pending.where((x) => x.listingId == o.listingId).length > 1,
            busy: _busyId == o.id,
            onAccept: () => _accept(o),
            onReject: () => _reject(o),
          ),
          const SizedBox(height: 14),
        ],
      ],
      bottom: const [HelpCallButton()],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final double? mandi;
  final bool best;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OfferCard({
    required this.offer,
    required this.mandi,
    required this.best,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final left = offer.listingAvailableQuantity;
    final remains = left != null && left - offer.quantity > 0.5 ? left - offer.quantity : null;
    final hours = offer.expiresAt?.difference(DateTime.now()).inHours;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: best ? SimpleColors.green : SimpleColors.line, width: best ? 3 : 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (best) StatusPill(kind: PillKind.good, text: loc.t('best_offer')),
          if (best) const SizedBox(height: 8),
          Row(children: [
            CropPicture(cropName: offer.cropName, size: 48),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: '₹${offer.pricePerUnit.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: SimpleColors.ink)),
                TextSpan(text: ' / ${loc.t('kg')}', style: const TextStyle(fontSize: 18, color: SimpleColors.quiet)),
              ])),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(rupees(offer.totalAmount),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SimpleColors.ink)),
              Text('${offer.quantity.toStringAsFixed(0)} ${loc.t('kg')}',
                  style: const TextStyle(fontSize: 16, color: SimpleColors.quiet)),
            ]),
          ]),
          const SizedBox(height: 6),
          if (mandi != null) MandiCompare(mandiPerKg: mandi, pricePerKg: offer.pricePerUnit),
          const SizedBox(height: 4),
          Text(offer.buyerName, style: const TextStyle(fontSize: 16, color: SimpleColors.quiet)),
          if (remains != null)
            Text(loc.tf('remains_for_sale', {'qty': remains.toStringAsFixed(0)}),
                style: const TextStyle(fontSize: 15, color: SimpleColors.quiet)),
          if (hours != null && hours >= 0 && hours < 48)
            Text(loc.tf('expires_in_h', {'h': hours}), style: const TextStyle(fontSize: 15, color: SimpleColors.orange)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              flex: 2,
              child: BigButton(label: loc.t('yes_sell'), icon: Icons.check_rounded, onPressed: onAccept, busy: busy),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigButton(
                  label: loc.t('no'),
                  icon: Icons.close_rounded,
                  outlined: true,
                  color: SimpleColors.red,
                  onPressed: busy ? null : onReject),
            ),
          ]),
        ],
      ),
    );
  }
}

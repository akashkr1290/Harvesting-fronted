import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/listing_status.dart';
import '../../models/produce_listing.dart';
import '../../services/api_client.dart';
import '../../services/localization_service.dart';
import '../../services/marketplace_service.dart';
import '../../widgets/simple/crop_art.dart';
import '../../widgets/simple/simple_ui.dart';
import '../produce_image_screen.dart';
import 'sell_wizard_screen.dart';

/// The farmer's listings with a plain status: for sale, not yet for sale, photo being checked, sold.
class MyCropsSimpleScreen extends StatefulWidget {
  const MyCropsSimpleScreen({super.key});

  @override
  State<MyCropsSimpleScreen> createState() => _MyCropsSimpleScreenState();
}

class _MyCropsSimpleScreenState extends State<MyCropsSimpleScreen> {
  String? _busyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<MarketplaceService>().fetchMyListings().catchError((_) {}));
  }

  Future<void> _publish(ProduceListingSummary l) async {
    final loc = context.read<LocalizationService>();
    setState(() => _busyId = l.id);
    try {
      await context.read<MarketplaceService>().publish(l.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.t('listed_success'), style: const TextStyle(fontSize: 18))));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.t('no_internet'))));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  (PillKind, String) _status(LocalizationService loc, ProduceListingSummary l) {
    switch (l.status) {
      case ListingStatus.published:
        return (PillKind.good, loc.t('status_live'));
      case ListingStatus.closed:
        return (PillKind.neutral, loc.t('status_closed'));
      case ListingStatus.draft:
        if (l.verificationStatus == 'MANUAL_REVIEW' || l.verificationStatus == 'PENDING') {
          return (PillKind.waiting, loc.t('status_review'));
        }
        if (l.verificationStatus == 'REJECTED') return (PillKind.bad, loc.t('photo_rejected'));
        return (PillKind.waiting, loc.t('status_draft'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final service = context.watch<MarketplaceService>();
    final listings = service.myListings;

    String speech() => listings.isEmpty
        ? loc.t('no_crops')
        : listings
            .map((l) => '${localCropName(loc, l.cropName)}, ${l.availableQuantity.toStringAsFixed(0)} ${loc.t('kg')}, '
                '${_status(loc, l).$2}')
            .join('. ');

    return SimplePage(
      header: SimpleHeader(title: loc.t('my_crops'), speakText: speech),
      children: [
        if (service.isLoading && listings.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
        if (!service.isLoading && listings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(loc.t('no_crops'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 19)),
          ),
        for (final l in listings) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SimpleColors.line, width: 2),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CropPicture(cropName: l.cropName, size: 52),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(localCropName(loc, l.cropName),
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    Text(
                        '${loc.tf('left_for_sale', {'qty': l.availableQuantity.toStringAsFixed(0)})} · '
                        '₹${l.expectedPricePerUnit.toStringAsFixed(0)}/${loc.t('kg')}',
                        style: const TextStyle(fontSize: 16, color: SimpleColors.quiet)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              StatusPill(kind: _status(loc, l).$1, text: _status(loc, l).$2),
              if (l.status == ListingStatus.draft) ...[
                const SizedBox(height: 12),
                if (l.verificationStatus == 'REJECTED' || l.verificationStatus == 'NOT_SUBMITTED')
                  BigButton(
                    label: loc.t('take_photo'),
                    icon: Icons.photo_camera_rounded,
                    outlined: true,
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => ProduceImageScreen(listingId: l.id)))
                        .then((_) => context.read<MarketplaceService>().fetchMyListings()),
                  )
                else
                  BigButton(
                    label: loc.t('put_for_sale_now'),
                    icon: Icons.sell_rounded,
                    busy: _busyId == l.id,
                    onPressed: () => _publish(l),
                  ),
              ],
            ]),
          ),
          const SizedBox(height: 14),
        ],
      ],
      bottom: [
        BigButton(
          label: loc.t('sell_crop'),
          icon: Icons.add_rounded,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SellWizardScreen())),
        ),
      ],
    );
  }
}

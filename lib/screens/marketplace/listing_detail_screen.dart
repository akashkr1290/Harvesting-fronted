import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/listing_status.dart';
import '../../models/offer.dart';
import '../../models/produce_image.dart';
import '../../models/produce_listing.dart';
import '../../services/api_client.dart';
import '../../services/marketplace_service.dart';
import '../../services/offer_service.dart';
import '../../services/produce_image_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/marketplace/market_status_badge.dart';
import '../../widgets/marketplace/offer_card.dart';
import '../../widgets/marketplace/produce_photo.dart';
import '../../widgets/verification_badge.dart';
import '../produce_image_screen.dart';
import 'create_edit_listing_screen.dart';
import 'submit_offer_screen.dart';

/// Shared listing-detail screen for both sides of the marketplace.
/// [isOwner] controls whether the farmer/FPO management actions (edit,
/// publish, close, view offers) show, or the buyer's "Submit Offer"
/// button does — the backend's own role/ownership checks are still the
/// real enforcement; this just avoids showing an action that would 403.
class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  final bool isOwner;

  const ListingDetailScreen({super.key, required this.listingId, this.isOwner = false});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  ProduceListingDetail? _listing;
  List<Offer> _offers = const [];
  List<ProduceImage> _verifiedImages = const [];
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
      final listing = await context.read<MarketplaceService>().getListing(widget.listingId);
      List<Offer> offers = const [];
      if (widget.isOwner) {
        offers = await context.read<OfferService>().forListing(widget.listingId);
      }
      // Phase 5: real, AI-verified crop photos (Phase 4), separate from the
      // legacy imageUrls string list on the listing itself. Best-effort —
      // an older listing may have none, which is not an error state.
      List<ProduceImage> verifiedImages = const [];
      try {
        final imageService = context.read<ProduceImageService>();
        await imageService.fetchForListing(widget.listingId);
        verifiedImages = imageService.images;
      } catch (_) {
        // No verified photos yet, or the endpoint isn't reachable — fall
        // back to the legacy imageUrls rendering below.
      }
      if (!mounted) return;
      setState(() {
        _listing = listing;
        _offers = offers;
        _verifiedImages = verifiedImages;
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

  Future<void> _publish() async {
    try {
      await context.read<MarketplaceService>().publish(widget.listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing published.')));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _close() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close this listing?'),
        content: const Text('Buyers will no longer be able to see it or make offers.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Close Listing')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<MarketplaceService>().close(widget.listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing closed.')));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing')),
      body: _buildBody(),
    );
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

    final listing = _listing!;
    final dateFmt = DateFormat('dd MMM yyyy');
    final isDraft = listing.status == ListingStatus.draft;
    final isPublished = listing.status == ListingStatus.published;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_verifiedImages.isNotEmpty)
            _VerifiedPrimaryPhoto(image: _verifiedImages.firstWhere(
              (i) => i.isPrimary,
              orElse: () => _verifiedImages.first,
            ))
          else if (listing.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ProducePhoto(url: listing.primaryImageUrl!, height: 200, width: double.infinity),
            )
          else
            const ProducePhotoPlaceholder(height: 160),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(listing.cropName, style: Theme.of(context).textTheme.headlineSmall),
              ),
              MarketStatusBadge.listing(listing.status),
            ],
          ),
          const SizedBox(height: 4),
          Text('${listing.sellerName} · ${listing.location}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          LabeledValue(label: 'Quantity', value: '${listing.quantity.toStringAsFixed(0)} ${listing.unit}'),
          LabeledValue(label: 'Quality', value: listing.quality?.isNotEmpty == true ? listing.quality! : '—'),
          LabeledValue(label: 'Harvest Date', value: dateFmt.format(listing.harvestDate)),
          LabeledValue(
            label: 'Expected Price',
            value: '₹${listing.expectedPricePerUnit.toStringAsFixed(2)} / ${listing.unit}',
            emphasize: true,
          ),
          if (listing.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const SectionHeader('Description'),
            Text(listing.description!),
          ],

          const SizedBox(height: 24),
          if (widget.isOwner) ..._ownerActions(listing, isDraft, isPublished) else ..._buyerActions(listing, isPublished),
        ],
      ),
    );
  }

  List<Widget> _ownerActions(ProduceListingDetail listing, bool isDraft, bool isPublished) {
    return [
      Row(
        children: [
          if (isDraft) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => CreateEditListingScreen(existingListing: listing)),
                  );
                  if (saved == true) _load();
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _publish,
                icon: const Icon(Icons.publish_outlined),
                label: const Text('Publish'),
              ),
            ),
          ],
          if (isPublished)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _close,
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Close Listing'),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProduceImageScreen(listingId: widget.listingId)),
          );
          _load();
        },
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(_verifiedImages.isEmpty ? 'Add Crop Photos' : 'Manage Crop Photos (${_verifiedImages.length})'),
      ),
      const SizedBox(height: 24),
      const SectionHeader('Offers'),
      if (_offers.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No offers yet.', style: TextStyle(color: Colors.grey)),
        )
      else
        for (final offer in _offers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OfferCard(offer: offer, showBuyer: true),
          ),
    ];
  }

  List<Widget> _buyerActions(ProduceListingDetail listing, bool isPublished) {
    if (!isPublished) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('This listing is not currently accepting offers.', style: TextStyle(color: Colors.grey)),
        ),
      ];
    }
    return [
      ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SubmitOfferScreen(listing: listing)),
        ),
        icon: const Icon(Icons.local_offer_outlined),
        label: const Text('Submit Offer'),
      ),
    ];
  }
}

/// Phase 5: the listing's real (Phase 4) primary produce photo, shown with
/// its risk-based verification badge — the "buyer sees relevant
/// verification status" requirement (master spec, marketplace flow). A
/// listing can only reach PUBLISHED with no REJECT-decision photo (see
/// MarketplaceService.publish's Phase 5 gate), but MANUAL_REVIEW/SUSPICIOUS
/// results can still be published, so the badge is always shown here
/// rather than hidden once "safe".
class _VerifiedPrimaryPhoto extends StatelessWidget {
  final ProduceImage image;
  const _VerifiedPrimaryPhoto({required this.image});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              apiClient.resolveUrl(image.url),
              headers: apiClient.authHeaders,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.black38),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: VerificationBadge(status: image.verificationStatus),
          ),
        ],
      ),
    );
  }
}

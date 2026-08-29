import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/produce_listing.dart';
import 'market_status_badge.dart';
import 'produce_photo.dart';

/// Mirrors CaseCard's shape (leading visual, title row with a status
/// badge, a couple of meta rows below) so the marketplace doesn't look
/// like a bolted-on second app.
class ListingCard extends StatelessWidget {
  final ProduceListingSummary listing;
  final VoidCallback? onTap;

  const ListingCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final photo = listing.primaryImageUrl;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photo != null
                    ? ProducePhoto(url: photo, width: 64, height: 64)
                    : const ProducePhotoPlaceholder(width: 64, height: 64),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            listing.cropName,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        MarketStatusBadge.listing(listing.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${listing.sellerName}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(listing.location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(dateFmt.format(listing.harvestDate), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${listing.quantity.toStringAsFixed(0)} ${listing.unit} · ₹${listing.expectedPricePerUnit.toStringAsFixed(2)}/${listing.unit}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

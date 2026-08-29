import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/offer.dart';
import 'market_status_badge.dart';

/// Used both on the buyer's "My Offers" list and the farmer's "Offers
/// received" list. `showBuyer` controls whether the buyer's name is shown
/// (farmer view) or the crop name takes its place (buyer already knows
/// who they are — they want to know which listing this was on).
class OfferCard extends StatelessWidget {
  final Offer offer;
  final bool showBuyer;
  final VoidCallback? onTap;
  final Widget? trailingAction;

  const OfferCard({
    super.key,
    required this.offer,
    this.showBuyer = false,
    this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      showBuyer ? '${offer.buyerName}  ·  ${offer.cropName}' : offer.cropName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  MarketStatusBadge.offer(offer.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${offer.quantity.toStringAsFixed(0)} @ ₹${offer.pricePerUnit.toStringAsFixed(2)}  ·  Total ₹${offer.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (offer.message != null && offer.message!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('"${offer.message}"', style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 6),
              Text(dateFmt.format(offer.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (trailingAction != null) ...[
                const SizedBox(height: 10),
                trailingAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

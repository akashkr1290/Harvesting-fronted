import 'package:flutter/material.dart';
import '../../models/listing_status.dart';
import '../../models/offer_status.dart';
import '../../models/order_status.dart';

/// Same pill shape as CaseCard's StatusBadge (which is tied to CaseStatus)
/// but with one constructor per marketplace enum, so ListingStatus,
/// OfferStatus, and MarketOrderStatus don't each need a bespoke widget.
class MarketStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const MarketStatusBadge._(this.label, this.color);

  factory MarketStatusBadge.listing(ListingStatus status) {
    final Color color;
    switch (status) {
      case ListingStatus.draft:
        color = Colors.blueGrey;
        break;
      case ListingStatus.published:
        color = const Color(0xFF2E7D32);
        break;
      case ListingStatus.closed:
        color = const Color(0xFFC62828);
        break;
    }
    return MarketStatusBadge._(status.label, color);
  }

  factory MarketStatusBadge.offer(OfferStatus status) {
    final Color color;
    switch (status) {
      case OfferStatus.pending:
        color = const Color(0xFFF9A825);
        break;
      case OfferStatus.accepted:
        color = const Color(0xFF2E7D32);
        break;
      case OfferStatus.rejected:
      case OfferStatus.withdrawn:
        color = const Color(0xFFC62828);
        break;
    }
    return MarketStatusBadge._(status.label, color);
  }

  factory MarketStatusBadge.order(MarketOrderStatus status) {
    final Color color;
    switch (status) {
      case MarketOrderStatus.confirmed:
        color = const Color(0xFFF9A825);
        break;
      case MarketOrderStatus.completed:
        color = const Color(0xFF2E7D32);
        break;
      case MarketOrderStatus.cancelled:
        color = const Color(0xFFC62828);
        break;
    }
    return MarketStatusBadge._(status.label, color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

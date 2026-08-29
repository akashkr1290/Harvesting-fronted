import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/market_order.dart';
import 'market_status_badge.dart';

/// One row for a MarketOrder — shown identically on both the seller's and
/// buyer's order list. `viewerId` picks which counterparty name to show
/// (the one that isn't the logged-in user).
class OrderCard extends StatelessWidget {
  final MarketOrder order;
  final String viewerId;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, required this.viewerId, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final isSeller = order.sellerId == viewerId;
    final counterpartyLabel = isSeller ? 'Buyer: ${order.buyerName}' : 'Seller: ${order.sellerName}';

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
                    child: Text(order.cropName,
                        style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                  ),
                  MarketStatusBadge.order(order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(counterpartyLabel, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                '${order.quantity.toStringAsFixed(0)} @ ₹${order.agreedPricePerUnit.toStringAsFixed(2)}  ·  Total ₹${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(dateFmt.format(order.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

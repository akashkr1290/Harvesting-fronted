import 'order_status.dart';
import '../utils/api_dates.dart';

/// Matches OrderResponse — created the moment a farmer/FPO accepts an
/// offer. Shows up identically in both the seller's and buyer's order
/// list; which side the logged-in user was on is inferred by the screen
/// comparing sellerId/buyerId against the logged-in user's id.
class MarketOrder {
  final String id;
  final String listingId;
  final String offerId;
  final String cropName;
  final String sellerId;
  final String sellerName;
  final String buyerId;
  final String buyerName;
  final double quantity;
  final double agreedPricePerUnit;
  final double totalAmount;
  final MarketOrderStatus status;
  final DateTime createdAt;

  MarketOrder({
    required this.id,
    required this.listingId,
    required this.offerId,
    required this.cropName,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    required this.quantity,
    required this.agreedPricePerUnit,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory MarketOrder.fromJson(Map<String, dynamic> json) {
    return MarketOrder(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      offerId: json['offerId'] as String,
      cropName: json['cropName'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      buyerId: json['buyerId'] as String,
      buyerName: json['buyerName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      agreedPricePerUnit: (json['agreedPricePerUnit'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: marketOrderStatusFromApi(json['status'] as String),
      createdAt: parseApiInstant(json['createdAt'] as String),
    );
  }
}

/// Matches EarningsSummaryResponse.
class EarningsSummary {
  final double totalEarnings;
  final int completedOrders;
  final int confirmedOrders;
  final List<MarketOrder> recentOrders;

  EarningsSummary({
    required this.totalEarnings,
    required this.completedOrders,
    required this.confirmedOrders,
    required this.recentOrders,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      completedOrders: (json['completedOrders'] as num).toInt(),
      confirmedOrders: (json['confirmedOrders'] as num).toInt(),
      recentOrders: (json['recentOrders'] as List)
          .map((e) => MarketOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

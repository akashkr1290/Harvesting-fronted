import 'offer_status.dart';
import 'user_role.dart';
import '../utils/api_dates.dart';

/// Matches OfferResponse — used both on the buyer's "My Offers" screen and
/// the farmer's "Offers received" / listing-detail offer list.
class Offer {
  final String id;
  final String listingId;
  final String cropName;
  final String buyerId;
  final String buyerName;
  final UserRole buyerRole;
  final double quantity;
  final double pricePerUnit;
  final String? message;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final DateTime? expiresAt;
  /// How much of the listing is still unsold (helps the farmer judge partial offers).
  final double? listingAvailableQuantity;

  Offer({
    required this.id,
    required this.listingId,
    required this.cropName,
    required this.buyerId,
    required this.buyerName,
    required this.buyerRole,
    required this.quantity,
    required this.pricePerUnit,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.decidedAt,
    this.expiresAt,
    this.listingAvailableQuantity,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  double get totalAmount => quantity * pricePerUnit;

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      cropName: json['cropName'] as String,
      buyerId: json['buyerId'] as String,
      buyerName: json['buyerName'] as String,
      buyerRole: userRoleFromApi(json['buyerRole'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      message: json['message'] as String?,
      status: offerStatusFromApi(json['status'] as String),
      createdAt: parseApiInstant(json['createdAt'] as String),
      decidedAt: parseApiInstantOrNull(json['decidedAt'] as String?),
      expiresAt: parseApiInstantOrNull(json['expiresAt'] as String?),
      listingAvailableQuantity: (json['listingAvailableQuantity'] as num?)?.toDouble(),
    );
  }
}

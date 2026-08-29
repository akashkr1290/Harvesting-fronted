import 'listing_status.dart';
import 'user_role.dart';
import '../utils/api_dates.dart';

/// Lightweight shape for marketplace browsing and "my listings" — matches
/// ListingSummaryResponse. Cards never need the full description/image
/// list just to render, mirroring CaseSummaryResponse's role in the
/// harvest-case screens.
class ProduceListingSummary {
  final String id;
  final String cropName;
  final double quantity;
  final String unit;
  final String? quality;
  final DateTime harvestDate;
  final String location;
  final double expectedPricePerUnit;
  final ListingStatus status;
  final String sellerName;
  final String? primaryImageUrl;
  final String verificationStatus;

  ProduceListingSummary({
    required this.id,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.quality,
    required this.harvestDate,
    required this.location,
    required this.expectedPricePerUnit,
    required this.status,
    required this.sellerName,
    required this.primaryImageUrl,
    required this.verificationStatus,
  });

  factory ProduceListingSummary.fromJson(Map<String, dynamic> json) {
    return ProduceListingSummary(
      id: json['id'] as String,
      cropName: json['cropName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      quality: json['quality'] as String?,
      harvestDate: parseApiDate(json['harvestDate'] as String),
      location: json['location'] as String,
      expectedPricePerUnit: (json['expectedPricePerUnit'] as num).toDouble(),
      status: listingStatusFromApi(json['status'] as String),
      sellerName: json['sellerName'] as String,
      primaryImageUrl: json['primaryImageUrl'] as String?,
      verificationStatus: json['verificationStatus'] as String? ?? 'NOT_SUBMITTED',
    );
  }
}

/// Full detail shape — matches ListingDetailResponse. Used on the listing
/// detail screen and by the farmer's create/edit form.
class ProduceListingDetail {
  final String id;
  final String sellerId;
  final String sellerName;
  final UserRole sellerRole;
  final String cropName;
  final double quantity;
  final String unit;
  final String? quality;
  final DateTime harvestDate;
  final String location;
  final double expectedPricePerUnit;
  final String? description;
  final ListingStatus status;
  final List<String> imageUrls;
  final int? primaryImageIndex;
  final String verificationStatus;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? closedAt;

  ProduceListingDetail({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRole,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.quality,
    required this.harvestDate,
    required this.location,
    required this.expectedPricePerUnit,
    required this.description,
    required this.status,
    required this.imageUrls,
    required this.primaryImageIndex,
    required this.verificationStatus,
    required this.createdAt,
    required this.publishedAt,
    required this.closedAt,
  });

  String? get primaryImageUrl {
    if (primaryImageIndex != null && primaryImageIndex! >= 0 && primaryImageIndex! < imageUrls.length) {
      return imageUrls[primaryImageIndex!];
    }
    return imageUrls.isNotEmpty ? imageUrls.first : null;
  }

  factory ProduceListingDetail.fromJson(Map<String, dynamic> json) {
    return ProduceListingDetail(
      id: json['id'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      sellerRole: userRoleFromApi(json['sellerRole'] as String),
      cropName: json['cropName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      quality: json['quality'] as String?,
      harvestDate: parseApiDate(json['harvestDate'] as String),
      location: json['location'] as String,
      expectedPricePerUnit: (json['expectedPricePerUnit'] as num).toDouble(),
      description: json['description'] as String?,
      status: listingStatusFromApi(json['status'] as String),
      imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? const [],
      primaryImageIndex: (json['primaryImageIndex'] as num?)?.toInt(),
      verificationStatus: json['verificationStatus'] as String? ?? 'NOT_SUBMITTED',
      createdAt: parseApiInstant(json['createdAt'] as String),
      publishedAt: parseApiInstantOrNull(json['publishedAt'] as String?),
      closedAt: parseApiInstantOrNull(json['closedAt'] as String?),
    );
  }
}

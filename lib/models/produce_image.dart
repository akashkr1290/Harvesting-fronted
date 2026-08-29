/// Mirrors com.harvestflow.api.domain.enums.ImageVerificationStatus.
/// Deliberately risk-based labels — never rendered to the user as
/// "verified real" or "confirmed fake", see [ImageVerificationStatusX.label].
enum ImageVerificationStatus {
  pending,
  authenticityLikely,
  suspicious,
  highManipulationRisk,
  highAiGenerationRisk,
  verificationFailed,
}

extension ImageVerificationStatusX on ImageVerificationStatus {
  String get apiValue {
    switch (this) {
      case ImageVerificationStatus.pending:
        return 'PENDING';
      case ImageVerificationStatus.authenticityLikely:
        return 'AUTHENTICITY_LIKELY';
      case ImageVerificationStatus.suspicious:
        return 'SUSPICIOUS';
      case ImageVerificationStatus.highManipulationRisk:
        return 'HIGH_MANIPULATION_RISK';
      case ImageVerificationStatus.highAiGenerationRisk:
        return 'HIGH_AI_GENERATION_RISK';
      case ImageVerificationStatus.verificationFailed:
        return 'VERIFICATION_FAILED';
    }
  }

  /// Risk-based phrasing only — this label is the one place a mislabel
  /// could turn into a false "guaranteed real" claim to a farmer/buyer,
  /// so every case reads as a likelihood or a flag, never a certainty.
  String get label {
    switch (this) {
      case ImageVerificationStatus.pending:
        return 'Checking image…';
      case ImageVerificationStatus.authenticityLikely:
        return 'No issues found';
      case ImageVerificationStatus.suspicious:
        return 'Flagged for review';
      case ImageVerificationStatus.highManipulationRisk:
        return 'Likely edited/manipulated';
      case ImageVerificationStatus.highAiGenerationRisk:
        return 'Likely AI-generated';
      case ImageVerificationStatus.verificationFailed:
        return 'Could not verify this image';
    }
  }
}

ImageVerificationStatus imageVerificationStatusFromApi(String value) {
  return ImageVerificationStatus.values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => throw ArgumentError('Unknown verification status from API: $value'),
  );
}

/// Mirrors com.harvestflow.api.domain.enums.ImageDecision — the three-way
/// switch screens actually branch their UI on.
enum ImageDecision { accept, manualReview, reject }

extension ImageDecisionX on ImageDecision {
  String get apiValue {
    switch (this) {
      case ImageDecision.accept:
        return 'ACCEPT';
      case ImageDecision.manualReview:
        return 'MANUAL_REVIEW';
      case ImageDecision.reject:
        return 'REJECT';
    }
  }
}

ImageDecision imageDecisionFromApi(String value) {
  return ImageDecision.values.firstWhere(
    (d) => d.apiValue == value,
    orElse: () => throw ArgumentError('Unknown decision from API: $value'),
  );
}

/// Mirrors com.harvestflow.api.dto.image.ProduceImageResponse.
class ProduceImage {
  final String id;
  final String? caseId;
  final String? listingId;
  final String url;
  final String? originalFilename;
  final String contentType;
  final int sizeBytes;
  final bool isPrimary;
  final DateTime uploadedAt;
  final ImageVerificationStatus verificationStatus;
  final ImageDecision decision;
  final double? confidenceScore;
  final List<String> verificationReasons;
  final String? verifierId;
  final DateTime? verifiedAt;

  ProduceImage({
    required this.id,
    required this.caseId,
    required this.listingId,
    required this.url,
    required this.originalFilename,
    required this.contentType,
    required this.sizeBytes,
    required this.isPrimary,
    required this.uploadedAt,
    required this.verificationStatus,
    required this.decision,
    required this.confidenceScore,
    required this.verificationReasons,
    required this.verifierId,
    required this.verifiedAt,
  });

  factory ProduceImage.fromApi(Map<String, dynamic> json) {
    return ProduceImage(
      id: json['id'] as String,
      caseId: json['caseId'] as String?,
      listingId: json['listingId'] as String?,
      url: json['url'] as String,
      originalFilename: json['originalFilename'] as String?,
      contentType: json['contentType'] as String,
      sizeBytes: json['sizeBytes'] as int,
      isPrimary: json['isPrimary'] as bool,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      verificationStatus: imageVerificationStatusFromApi(json['verificationStatus'] as String),
      decision: imageDecisionFromApi(json['decision'] as String),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      verificationReasons: (json['verificationReasons'] as List<dynamic>? ?? [])
          .map((r) => r as String)
          .toList(),
      verifierId: json['verifierId'] as String?,
      verifiedAt: json['verifiedAt'] == null ? null : DateTime.parse(json['verifiedAt'] as String),
    );
  }
}

/// Mirrors the backend's DemandLevel enum (Phase 3).
enum DemandLevel { low, medium, high }

DemandLevel demandLevelFromApi(String value) {
  switch (value) {
    case 'LOW':
      return DemandLevel.low;
    case 'HIGH':
      return DemandLevel.high;
    default:
      return DemandLevel.medium;
  }
}

extension DemandLevelX on DemandLevel {
  String get label {
    switch (this) {
      case DemandLevel.low:
        return 'LOW';
      case DemandLevel.medium:
        return 'MEDIUM';
      case DemandLevel.high:
        return 'HIGH';
    }
  }
}

/// Mirrors the backend's TrendDirection enum (Phase 3).
enum TrendDirection { increasing, stable, decreasing }

TrendDirection trendFromApi(String value) {
  switch (value) {
    case 'INCREASING':
      return TrendDirection.increasing;
    case 'DECREASING':
      return TrendDirection.decreasing;
    default:
      return TrendDirection.stable;
  }
}

extension TrendDirectionX on TrendDirection {
  String get label {
    switch (this) {
      case TrendDirection.increasing:
        return 'Increasing';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.decreasing:
        return 'Decreasing';
    }
  }
}

/// Mirrors the backend's DemandPredictionResponse (Phase 3). Always an
/// estimate — see [estimate] and the "Estimate" label shown wherever this
/// is displayed. Never presented to the user as a guaranteed figure.
class DemandPrediction {
  final String id;
  final String cropType;
  final String location;
  final DateTime predictionDate;
  final double predictedQuantity;
  final double? historicalAverage;
  final DemandLevel demandLevel;
  final TrendDirection trend;
  final double? confidenceScore;
  final int dataPointsUsed;
  final String generatedByUsername;
  final DateTime generatedAt;
  final String? notes;
  final bool estimate;

  DemandPrediction({
    required this.id,
    required this.cropType,
    required this.location,
    required this.predictionDate,
    required this.predictedQuantity,
    required this.historicalAverage,
    required this.demandLevel,
    required this.trend,
    required this.confidenceScore,
    required this.dataPointsUsed,
    required this.generatedByUsername,
    required this.generatedAt,
    required this.notes,
    required this.estimate,
  });

  factory DemandPrediction.fromJson(Map<String, dynamic> json) {
    return DemandPrediction(
      id: json['id'] as String,
      cropType: json['cropType'] as String,
      location: json['location'] as String,
      predictionDate: DateTime.parse(json['predictionDate'] as String),
      predictedQuantity: (json['predictedQuantity'] as num).toDouble(),
      historicalAverage: (json['historicalAverage'] as num?)?.toDouble(),
      demandLevel: demandLevelFromApi(json['demandLevel'] as String),
      trend: trendFromApi(json['trend'] as String),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      dataPointsUsed: json['dataPointsUsed'] as int,
      generatedByUsername: json['generatedByUsername'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      notes: json['notes'] as String?,
      estimate: json['estimate'] as bool? ?? true,
    );
  }
}

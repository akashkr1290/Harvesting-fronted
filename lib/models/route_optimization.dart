/// Mirrors the backend's RouteStatus enum (Phase 3).
enum RouteStatus { optimized, assigned, inTransit, delivered, cancelled }

RouteStatus routeStatusFromApi(String value) {
  switch (value) {
    case 'ASSIGNED':
      return RouteStatus.assigned;
    case 'IN_TRANSIT':
      return RouteStatus.inTransit;
    case 'DELIVERED':
      return RouteStatus.delivered;
    case 'CANCELLED':
      return RouteStatus.cancelled;
    default:
      return RouteStatus.optimized;
  }
}

extension RouteStatusX on RouteStatus {
  String get label {
    switch (this) {
      case RouteStatus.optimized:
        return 'Optimized';
      case RouteStatus.assigned:
        return 'Assigned';
      case RouteStatus.inTransit:
        return 'In Transit';
      case RouteStatus.delivered:
        return 'Delivered';
      case RouteStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Mirrors the backend's StopType enum (Phase 3).
enum StopType { pickup, delivery }

StopType stopTypeFromApi(String value) => value == 'PICKUP' ? StopType.pickup : StopType.delivery;

/// A stop to send in an optimize request. If [latitude]/[longitude] are
/// left null, the backend tries to resolve them from Master Data
/// (Locations/Companies) by matching [name].
class RouteStopInput {
  final String name;
  final double? latitude;
  final double? longitude;

  RouteStopInput({required this.name, this.latitude, this.longitude});

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      };
}

/// One stop in an optimized route's returned sequence.
class RouteStop {
  final int sequenceIndex;
  final String name;
  final double latitude;
  final double longitude;
  final StopType stopType;

  RouteStop({
    required this.sequenceIndex,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.stopType,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      sequenceIndex: json['sequenceIndex'] as int,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      stopType: stopTypeFromApi(json['stopType'] as String),
    );
  }
}

/// Mirrors the backend's RouteOptimizeResponse (Phase 3).
class RouteOptimizationResult {
  final String id;
  final String? caseId;
  final String? vehicleId;
  final String? vehicleRegistrationNumber;
  final RouteStatus status;
  final double? totalQuantityKg;
  final double originalDistanceKm;
  final double optimizedDistanceKm;
  final double distanceSavedKm;
  final double estimatedDurationMinutes;
  final double estimatedCost;
  final String requestedByUsername;
  final DateTime createdAt;
  final List<RouteStop> stops;

  RouteOptimizationResult({
    required this.id,
    required this.caseId,
    required this.vehicleId,
    required this.vehicleRegistrationNumber,
    required this.status,
    required this.totalQuantityKg,
    required this.originalDistanceKm,
    required this.optimizedDistanceKm,
    required this.distanceSavedKm,
    required this.estimatedDurationMinutes,
    required this.estimatedCost,
    required this.requestedByUsername,
    required this.createdAt,
    required this.stops,
  });

  factory RouteOptimizationResult.fromJson(Map<String, dynamic> json) {
    return RouteOptimizationResult(
      id: json['id'] as String,
      caseId: json['caseId'] as String?,
      vehicleId: json['vehicleId'] as String?,
      vehicleRegistrationNumber: json['vehicleRegistrationNumber'] as String?,
      status: routeStatusFromApi(json['status'] as String),
      totalQuantityKg: (json['totalQuantityKg'] as num?)?.toDouble(),
      originalDistanceKm: (json['originalDistanceKm'] as num).toDouble(),
      optimizedDistanceKm: (json['optimizedDistanceKm'] as num).toDouble(),
      distanceSavedKm: (json['distanceSavedKm'] as num).toDouble(),
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num).toDouble(),
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      requestedByUsername: json['requestedByUsername'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      stops: (json['stops'] as List<dynamic>)
          .map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A vehicle available for route assignment (Phase 3 fleet registry).
class DeliveryVehicle {
  final String id;
  final String registrationNumber;
  final String vehicleType;
  final double capacityKg;
  final bool active;

  DeliveryVehicle({
    required this.id,
    required this.registrationNumber,
    required this.vehicleType,
    required this.capacityKg,
    required this.active,
  });

  factory DeliveryVehicle.fromJson(Map<String, dynamic> json) {
    return DeliveryVehicle(
      id: json['id'] as String,
      registrationNumber: json['registrationNumber'] as String,
      vehicleType: json['vehicleType'] as String,
      capacityKg: (json['capacityKg'] as num).toDouble(),
      active: json['active'] as bool,
    );
  }
}

import '../utils/api_dates.dart';

/// Fields captured by the Planning Team (SOW 5.4 B).
class PlanningDetails {
  final DateTime plannedDate;
  final String timeWindow;
  final String supervisorName;
  final String pickupPersonName;
  final String vehiclePlan;
  final double expectedQuantity;
  final String notesForGodown;
  final String notesForSupervisor;

  PlanningDetails({
    required this.plannedDate,
    required this.timeWindow,
    required this.supervisorName,
    required this.pickupPersonName,
    this.vehiclePlan = '',
    required this.expectedQuantity,
    this.notesForGodown = '',
    this.notesForSupervisor = '',
  });

  /// Body for POST /api/cases/{id}/planning (PlanningRequest on the backend).
  Map<String, dynamic> toJson() => {
        'plannedDate': formatApiDate(plannedDate),
        'timeWindow': timeWindow,
        'supervisorName': supervisorName,
        'pickupPersonName': pickupPersonName,
        'vehiclePlan': vehiclePlan,
        'expectedQuantity': expectedQuantity,
        'notesForGodown': notesForGodown,
        'notesForSupervisor': notesForSupervisor,
      };

  factory PlanningDetails.fromJson(Map<String, dynamic> json) {
    return PlanningDetails(
      plannedDate: parseApiDate(json['plannedDate'] as String),
      timeWindow: json['timeWindow'] as String? ?? '',
      supervisorName: json['supervisorName'] as String,
      pickupPersonName: json['pickupPersonName'] as String,
      vehiclePlan: json['vehiclePlan'] as String? ?? '',
      expectedQuantity: (json['expectedQuantity'] as num?)?.toDouble() ?? 0,
      notesForGodown: json['notesForGodown'] as String? ?? '',
      notesForSupervisor: json['notesForSupervisor'] as String? ?? '',
    );
  }
}

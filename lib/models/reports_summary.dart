import 'case_status.dart';

/// Mirrors ReportsSummaryResponse from the backend — computed server-side
/// over every case in the database, not just whatever happens to be in
/// this device's local CaseService cache. This is the one place in the
/// app where "reports" means the authoritative number, not a client-side
/// approximation.
class ReportsSummary {
  final int totalCases;
  final int selectionsToday;
  final int plannedCount;
  final int completedCount;
  final Map<CaseStatus, int> stageWisePending;
  final Map<String, double> purchaseSummaryByFarmer;
  final Map<String, double> salesSummaryByCompany;
  final double averageRecovery;
  final double averagePulp;

  ReportsSummary({
    required this.totalCases,
    required this.selectionsToday,
    required this.plannedCount,
    required this.completedCount,
    required this.stageWisePending,
    required this.purchaseSummaryByFarmer,
    required this.salesSummaryByCompany,
    required this.averageRecovery,
    required this.averagePulp,
  });

  factory ReportsSummary.fromJson(Map<String, dynamic> json) {
    final stageWiseJson = (json['stageWisePending'] as Map<String, dynamic>? ?? {});
    final purchaseJson = (json['purchaseSummaryByFarmer'] as Map<String, dynamic>? ?? {});
    final salesJson = (json['salesSummaryByCompany'] as Map<String, dynamic>? ?? {});

    return ReportsSummary(
      totalCases: json['totalCases'] as int? ?? 0,
      selectionsToday: json['selectionsToday'] as int? ?? 0,
      plannedCount: json['plannedCount'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
      stageWisePending: stageWiseJson.map(
        (key, value) => MapEntry(caseStatusFromApi(key), (value as num).toInt()),
      ),
      purchaseSummaryByFarmer: purchaseJson.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      salesSummaryByCompany: salesJson.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      averageRecovery: (json['averageRecovery'] as num?)?.toDouble() ?? 0,
      averagePulp: (json['averagePulp'] as num?)?.toDouble() ?? 0,
    );
  }
}

import 'case_status.dart';
import 'plot_selection.dart';
import 'planning_details.dart';
import 'packing_material.dart';
import 'harvest_completion.dart';
import 'logistics_entry.dart';
import 'purchase_invoice.dart';
import 'sales_invoice.dart';
import '../utils/api_dates.dart';

class TimelineEntry {
  final DateTime timestamp;
  final String actor;
  final String action;

  TimelineEntry({
    required this.timestamp,
    required this.actor,
    required this.action,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      timestamp: parseApiInstant(json['timestamp'] as String),
      actor: json['actor'] as String,
      action: json['action'] as String,
    );
  }
}

class HarvestCase {
  final String id;
  final PlotSelection selection;
  CaseStatus status;
  final List<TimelineEntry> timeline;

  // Populated progressively as the case moves through stages — each is
  // null until that stage's screen saves it, which is also how "has this
  // stage happened yet" is checked elsewhere (e.g. Purchase Invoice
  // auto-pulling completion + logistics data).
  PlanningDetails? planning;
  double? ratePerUnit;
  PackingMaterialRecord? packingIssue;
  HarvestCompletion? completion;
  LogisticsEntry? pickup;
  LogisticsEntry? transport;
  LogisticsEntry? labor;
  LogisticsEntry? localLabor;
  PackingMaterialRecord? packingReturn;
  PurchaseInvoiceData? purchaseInvoice;
  SalesInvoiceData? salesInvoice;

  HarvestCase({
    required this.id,
    required this.selection,
    this.status = CaseStatus.submittedForPlanning,
    List<TimelineEntry>? timeline,
  }) : timeline = timeline ?? [];

  /// Builds a full HarvestCase from a CaseDetailResponse — the single
  /// canonical shape used everywhere in the app (list cards, stage forms,
  /// timeline view). CaseService fetches this per case rather than working
  /// off the lighter CaseSummaryResponse, so every screen downstream keeps
  /// working exactly as it did against the old in-memory mock data.
  factory HarvestCase.fromApi(Map<String, dynamic> json) {
    final harvestCase = HarvestCase(
      id: json['id'] as String,
      selection: PlotSelection.fromCaseJson(json),
      status: caseStatusFromApi(json['status'] as String),
      timeline: (json['timeline'] as List<dynamic>? ?? [])
          .map((t) => TimelineEntry.fromJson(t as Map<String, dynamic>))
          .toList(),
    );

    harvestCase.ratePerUnit = (json['ratePerUnit'] as num?)?.toDouble();

    if (json['planning'] != null) {
      harvestCase.planning = PlanningDetails.fromJson(json['planning'] as Map<String, dynamic>);
    }
    if (json['packingIssue'] != null) {
      harvestCase.packingIssue =
          PackingMaterialRecord.fromJson(json['packingIssue'] as Map<String, dynamic>);
    }
    if (json['packingReturn'] != null) {
      harvestCase.packingReturn =
          PackingMaterialRecord.fromJson(json['packingReturn'] as Map<String, dynamic>);
    }
    if (json['completion'] != null) {
      harvestCase.completion = HarvestCompletion.fromJson(json['completion'] as Map<String, dynamic>);
    }
    if (json['pickup'] != null) {
      harvestCase.pickup = LogisticsEntry.fromJson(json['pickup'] as Map<String, dynamic>);
    }
    if (json['transport'] != null) {
      harvestCase.transport = LogisticsEntry.fromJson(json['transport'] as Map<String, dynamic>);
    }
    if (json['labor'] != null) {
      harvestCase.labor = LogisticsEntry.fromJson(json['labor'] as Map<String, dynamic>);
    }
    if (json['localLabor'] != null) {
      harvestCase.localLabor = LogisticsEntry.fromJson(json['localLabor'] as Map<String, dynamic>);
    }
    if (json['purchaseInvoice'] != null) {
      harvestCase.purchaseInvoice =
          PurchaseInvoiceData.fromJson(json['purchaseInvoice'] as Map<String, dynamic>);
    }
    if (json['salesInvoice'] != null) {
      harvestCase.salesInvoice = SalesInvoiceData.fromJson(json['salesInvoice'] as Map<String, dynamic>);
    }

    return harvestCase;
  }

  void advanceTo(CaseStatus newStatus, {required String actor, required String action}) {
    status = newStatus;
    timeline.add(TimelineEntry(timestamp: DateTime.now(), actor: actor, action: action));
  }

  /// Total logistics cost so far — feeds the Purchase Invoice cost calc.
  double get logisticsCostTotal {
    double total = 0;
    for (final entry in [pickup, transport, labor, localLabor]) {
      if (entry != null) total += entry.amount;
    }
    return total;
  }
}

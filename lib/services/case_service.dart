import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/case_status.dart';
import '../models/harvest_case.dart';
import '../models/plot_selection.dart';
import '../models/planning_details.dart';
import '../models/packing_material.dart';
import '../models/harvest_completion.dart';
import '../models/logistics_entry.dart';
import '../models/purchase_invoice.dart';
import '../models/sales_invoice.dart';
import '../models/user_role.dart';

/// Real API-backed case service. Every mutation hits its matching
/// /api/cases/{id}/... endpoint, gets back a full CaseDetailResponse, and
/// replaces that case in the local cache — the same single canonical
/// HarvestCase shape every screen already reads from, now sourced over the
/// network instead of synthesized in memory. `allCases` and `pendingFor`
/// stay synchronous getters over that cache, so dashboard/list/report
/// screens that just watch this service don't need to change at all.
class CaseService extends ChangeNotifier {
  final ApiClient _api;
  final List<HarvestCase> _cases = [];
  bool _loading = false;

  CaseService(this._api);

  bool get isLoading => _loading;
  List<HarvestCase> get allCases => List.unmodifiable(_cases);

  /// Cases sitting in a given status — i.e. the "pending queue" for whichever
  /// role owns that status's next action.
  List<HarvestCase> pendingFor(UserRole role) {
    return _cases
        .where((c) => c.status != CaseStatus.salesCompleted && c.status.nextActorRole == role)
        .toList()
      ..sort((a, b) => a.selection.harvestingDate.compareTo(b.selection.harvestingDate));
  }

  int countPendingFor(UserRole role) => pendingFor(role).length;

  void _upsert(HarvestCase updated) {
    final index = _cases.indexWhere((c) => c.id == updated.id);
    if (index == -1) {
      _cases.add(updated);
    } else {
      _cases[index] = updated;
    }
  }

  // ---------------------------------------------------------------------
  // Bootstrap / refresh — GET /api/cases returns lightweight summaries
  // (just enough to list ids), then each is hydrated via GET
  // /api/cases/{id} for the full nested detail every stage screen needs.
  // ---------------------------------------------------------------------
  Future<void> fetchAll({String? query, CaseStatus? status}) async {
    _loading = true;
    notifyListeners();
    try {
      final summaries = await _api.get('/api/cases', query: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (status != null) 'status': status.apiValue,
      }) as List<dynamic>;

      final ids = summaries.map((s) => (s as Map<String, dynamic>)['id'] as String).toList();
      final hydrated = <HarvestCase>[];
      for (final id in ids) {
        final detail = await _api.get('/api/cases/$id') as Map<String, dynamic>;
        hydrated.add(HarvestCase.fromApi(detail));
      }
      _cases
        ..clear()
        ..addAll(hydrated);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<HarvestCase> refreshOne(String id) async {
    final detail = await _api.get('/api/cases/$id') as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(detail);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stage 1 — Plot Selection
  // ---------------------------------------------------------------------
  Future<HarvestCase> createPlotSelection(PlotSelection selection, {required String actor}) async {
    final res = await _api.post('/api/cases', body: selection.toJson()) as Map<String, dynamic>;
    final created = HarvestCase.fromApi(res);
    _upsert(created);
    notifyListeners();
    return created;
  }

  /// Editable only while the case is still at the very first status —
  /// the backend enforces this server-side (403 otherwise); this call
  /// isn't wired to a screen yet, but is here ready for the edit screen.
  Future<HarvestCase> updatePlotSelection(
    HarvestCase harvestCase,
    PlotSelection selection, {
    required String actor,
  }) async {
    final res = await _api.put('/api/cases/${harvestCase.id}/plot-selection', body: selection.toJson())
        as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stage 2 — Planning
  // ---------------------------------------------------------------------
  Future<HarvestCase> savePlanning(
    HarvestCase harvestCase,
    PlanningDetails details, {
    required String actor,
  }) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/planning', body: details.toJson())
        as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stage 3 — Purchase rate update
  // ---------------------------------------------------------------------
  Future<HarvestCase> updatePurchaseRate(
    HarvestCase harvestCase,
    double rate, {
    required String actor,
  }) async {
    final res = await _api.post(
      '/api/cases/${harvestCase.id}/purchase-rate',
      body: {'ratePerUnit': rate},
    ) as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stage 4 — Packing material issue
  // ---------------------------------------------------------------------
  Future<HarvestCase> issuePackingMaterial(
    HarvestCase harvestCase,
    PackingMaterialRecord record, {
    required String actor,
  }) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/packing-issue', body: {
      'issuedTo': record.handledBy,
      'remarks': record.remarks,
      'lines': record.lines.map((l) => l.toJson()).toList(),
    }) as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stage 5 — Harvest completion / weight slip
  // ---------------------------------------------------------------------
  Future<HarvestCase> completeHarvest(
    HarvestCase harvestCase,
    HarvestCompletion completion, {
    required String actor,
  }) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/harvest-completion', body: completion.toJson())
        as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stage 6 — Pickup
  // ---------------------------------------------------------------------
  Future<HarvestCase> addPickup(HarvestCase harvestCase, LogisticsEntry entry, {required String actor}) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/pickup', body: entry.toJson())
        as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stage 7 — Transport
  // ---------------------------------------------------------------------
  Future<HarvestCase> addTransport(HarvestCase harvestCase, LogisticsEntry entry, {required String actor}) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/transport', body: entry.toJson())
        as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stages 8–9 — Labor + optional Local Labor, submitted together since one
  // role owns both and a case can only sit in one pending queue at a time.
  // ---------------------------------------------------------------------
  Future<HarvestCase> addLaborEntries(
    HarvestCase harvestCase, {
    required LogisticsEntry labor,
    LogisticsEntry? localLabor,
    required String actor,
  }) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/labor', body: {
      'labor': labor.toJson(),
      if (localLabor != null) 'localLabor': localLabor.toJson(),
    }) as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stage 10 — Packing material return / reconciliation
  // ---------------------------------------------------------------------
  Future<HarvestCase> returnPackingMaterial(
    HarvestCase harvestCase,
    PackingMaterialRecord record, {
    required String actor,
  }) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/packing-return', body: {
      'remarks': record.remarks,
      'lines': record.lines.map((l) => l.toJson()).toList(),
    }) as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  // ---------------------------------------------------------------------
  // Stage 11 — Purchase invoice
  // ---------------------------------------------------------------------
  Future<PurchaseInvoiceData> createPurchaseInvoice(
    HarvestCase harvestCase, {
    required double rate,
    required double weight,
    required bool includeCommission,
    required double commissionAmount,
    required bool includePacking,
    required double packingCost,
    required bool includeTransport,
    required double transportCost,
    required double otherCharges,
    required double deductions,
    required double additions,
    required String actor,
  }) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/purchase-invoice', body: {
      'rate': rate,
      'weight': weight,
      'includeCommission': includeCommission,
      'commissionAmount': commissionAmount,
      'includePackingCost': includePacking,
      'packingCost': packingCost,
      'includeTransportCost': includeTransport,
      'transportCost': transportCost,
      'otherCharges': otherCharges,
      'deductions': deductions,
      'additions': additions,
    }) as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated.purchaseInvoice!;
  }

  // ---------------------------------------------------------------------
  // Stage 12 — Sales invoice
  // ---------------------------------------------------------------------
  Future<SalesInvoiceData> createSalesInvoice(
    HarvestCase harvestCase, {
    required String buyerCompany,
    required double salesRate,
    required double weight,
    required double taxPercent,
    required String actor,
  }) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/sales-invoice', body: {
      'buyerCompany': buyerCompany,
      'salesRate': salesRate,
      'weight': weight,
      'taxPercent': taxPercent,
    }) as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated.salesInvoice!;
  }

  /// Eicher Truck Driver milestones (loading/transit/delivery) are logged
  /// for visibility but don't gate the status state machine — no role in
  /// the SOW's status table owns a "driver confirmation" stage, so this
  /// stays informational rather than blocking the pipeline.
  Future<HarvestCase> logDriverMilestone(
    HarvestCase harvestCase,
    String milestone, {
    required String actor,
  }) async {
    final res = await _api.post('/api/cases/${harvestCase.id}/milestone', body: {'milestone': milestone})
        as Map<String, dynamic>;
    final updated = HarvestCase.fromApi(res);
    _upsert(updated);
    notifyListeners();
    return updated;
  }

  /// Feeds the Eicher Truck Driver's screen — cases currently in transit.
  Future<void> fetchActiveTrips() async {
    final res = await _api.get('/api/cases/active-trips') as List<dynamic>;
    for (final s in res) {
      final id = (s as Map<String, dynamic>)['id'] as String;
      await refreshOne(id);
    }
  }
}

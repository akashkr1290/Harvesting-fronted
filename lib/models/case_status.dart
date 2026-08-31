import 'user_role.dart';

/// The canonical stage sequence (see Working Approach doc, section 1).
/// Order matters — index in this list determines allowed forward transitions.
enum CaseStatus {
  awaitingPlotSelection,
  submittedForPlanning,
  planned,
  rateUpdated,
  packingMaterialIssued,
  harvestingCompleted,
  pickupAssigned,
  transportAssigned,
  costEntriesDone,
  materialReconciled,
  purchaseCompleted,
  salesCompleted,
}

extension CaseStatusX on CaseStatus {
  /// Matches the Java enum constant name exactly (e.g. RATE_UPDATED).
  String get apiValue {
    switch (this) {
      case CaseStatus.awaitingPlotSelection:
        return 'AWAITING_PLOT_SELECTION';
      case CaseStatus.submittedForPlanning:
        return 'SUBMITTED_FOR_PLANNING';
      case CaseStatus.planned:
        return 'PLANNED';
      case CaseStatus.rateUpdated:
        return 'RATE_UPDATED';
      case CaseStatus.packingMaterialIssued:
        return 'PACKING_MATERIAL_ISSUED';
      case CaseStatus.harvestingCompleted:
        return 'HARVESTING_COMPLETED';
      case CaseStatus.pickupAssigned:
        return 'PICKUP_ASSIGNED';
      case CaseStatus.transportAssigned:
        return 'TRANSPORT_ASSIGNED';
      case CaseStatus.costEntriesDone:
        return 'COST_ENTRIES_DONE';
      case CaseStatus.materialReconciled:
        return 'MATERIAL_RECONCILED';
      case CaseStatus.purchaseCompleted:
        return 'PURCHASE_COMPLETED';
      case CaseStatus.salesCompleted:
        return 'SALES_COMPLETED';
    }
  }

  String get label {
    switch (this) {
      case CaseStatus.awaitingPlotSelection:
        return 'Awaiting Plot Selection';
      case CaseStatus.submittedForPlanning:
        return 'Submitted for Planning';
      case CaseStatus.planned:
        return 'Planned';
      case CaseStatus.rateUpdated:
        return 'Rate Updated';
      case CaseStatus.packingMaterialIssued:
        return 'Packing Material Issued';
      case CaseStatus.harvestingCompleted:
        return 'Harvesting Completed';
      case CaseStatus.pickupAssigned:
        return 'Pickup Assigned';
      case CaseStatus.transportAssigned:
        return 'Transport Assigned';
      case CaseStatus.costEntriesDone:
        return 'Cost Entries Done';
      case CaseStatus.materialReconciled:
        return 'Material Reconciled';
      case CaseStatus.purchaseCompleted:
        return 'Purchase Completed';
      case CaseStatus.salesCompleted:
        return 'Sales Completed';
    }
  }

  /// Which role owns the NEXT action once a case is in this status.
  UserRole get nextActorRole {
    switch (this) {
      case CaseStatus.awaitingPlotSelection:
        return UserRole.plotSelection;
      case CaseStatus.submittedForPlanning:
        return UserRole.planning;
      case CaseStatus.planned:
        return UserRole.godown;
      case CaseStatus.rateUpdated:
        return UserRole.godown;
      case CaseStatus.packingMaterialIssued:
        return UserRole.supervisor;
      case CaseStatus.harvestingCompleted:
        return UserRole.pickupPerson;
      case CaseStatus.pickupAssigned:
        return UserRole.transportPerson;
      case CaseStatus.transportAssigned:
        return UserRole.laborCoordinator;
      case CaseStatus.costEntriesDone:
        return UserRole.godown;
      case CaseStatus.materialReconciled:
        return UserRole.purchaseAccount;
      case CaseStatus.purchaseCompleted:
        return UserRole.admin; // Accounts/Sales — modeled under admin for now
      case CaseStatus.salesCompleted:
        return UserRole.admin;
    }
  }
}

CaseStatus caseStatusFromApi(String value) {
  return CaseStatus.values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => throw ArgumentError('Unknown case status from API: $value'),
  );
}

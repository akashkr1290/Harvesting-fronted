import 'package:flutter/material.dart';
import '../models/case_status.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final CaseStatus status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case CaseStatus.submittedForPlanning:
      case CaseStatus.planned:
        return Colors.blueGrey;
      case CaseStatus.rateUpdated:
      case CaseStatus.packingMaterialIssued:
        return AppTheme.accent;
      case CaseStatus.harvestingCompleted:
        return AppTheme.primary;
      case CaseStatus.pickupAssigned:
      case CaseStatus.transportAssigned:
      case CaseStatus.costEntriesDone:
      case CaseStatus.materialReconciled:
        return Colors.deepPurple;
      case CaseStatus.purchaseCompleted:
      case CaseStatus.salesCompleted:
        return AppTheme.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

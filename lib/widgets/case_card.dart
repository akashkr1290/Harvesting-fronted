import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/harvest_case.dart';
import 'status_badge.dart';

class CaseCard extends StatelessWidget {
  final HarvestCase harvestCase;
  final VoidCallback? onTap;

  /// Optional extra control shown next to the status badge — used for the
  /// Plot Selection edit button, but kept generic in case another screen
  /// needs a similar per-card action later. Every existing call site is
  /// unaffected since this defaults to null.
  final Widget? trailingAction;

  const CaseCard({super.key, required this.harvestCase, this.onTap, this.trailingAction});

  @override
  Widget build(BuildContext context) {
    final s = harvestCase.selection;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${s.farmerName}  ·  ${s.village}',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: harvestCase.status),
                  if (trailingAction != null) ...[
                    const SizedBox(width: 6),
                    trailingAction!,
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(s.location, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 14),
                  const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dateFmt.format(s.harvestingDate),
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                harvestCase.marketOrderId == null
                    ? 'Case #${harvestCase.id}  ·  ${s.selectedCompany}'
                    : 'Marketplace Order #${harvestCase.marketOrderId}  ·  Internal Case #${harvestCase.id}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

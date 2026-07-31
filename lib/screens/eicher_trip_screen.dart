import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_status.dart';
import '../models/harvest_case.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../widgets/case_card.dart';
import '../widgets/form_helpers.dart';

/// The SOW describes this role as confirming loading/transit/delivery
/// milestones, but doesn't give it a dedicated status in the workflow —
/// so this screen shows in-transit cases and logs milestones to the
/// timeline without blocking the pipeline (see Working Approach doc).
class EicherTripScreen extends StatefulWidget {
  const EicherTripScreen({super.key});

  @override
  State<EicherTripScreen> createState() => _EicherTripScreenState();
}

/// Stateful (rather than the original Stateless) purely so milestone
/// logging can go through the same submitAction error handling as every
/// other stage screen — a silently-swallowed 403/409 here would otherwise
/// look identical to a successful log.
class _EicherTripScreenState extends State<EicherTripScreen> with SubmitStateMixin<EicherTripScreen> {
  void _logMilestone(HarvestCase harvestCase, String milestone) {
    final actor = context.read<AuthService>().username ?? 'Eicher Truck Driver';
    // popOnSuccess: false — this is a list screen, not a single-record form;
    // the bottom sheet already closed itself before this fires.
    submitAction(
      () => context.read<CaseService>().logDriverMilestone(harvestCase, milestone, actor: actor),
      successMessage: '$milestone logged.',
      popOnSuccess: false,
    );
  }

  void _openMilestoneSheet(BuildContext context, HarvestCase harvestCase) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Case #${harvestCase.id} — ${harvestCase.selection.farmerName}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _logMilestone(harvestCase, 'Confirmed loading');
              },
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Confirm Loading'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _logMilestone(harvestCase, 'Confirmed in transit');
              },
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Confirm Transit'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _logMilestone(harvestCase, 'Confirmed delivery');
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm Delivery'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseService = context.watch<CaseService>();
    final activeTrips = caseService.allCases
        .where((c) => c.status == CaseStatus.pickupAssigned || c.status == CaseStatus.transportAssigned)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trips'),
        bottom: submitting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: activeTrips.isEmpty
          ? const Center(child: Text('No trips in progress.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeTrips.length,
              itemBuilder: (context, i) {
                final c = activeTrips[i];
                return CaseCard(harvestCase: c, onTap: () => _openMilestoneSheet(context, c));
              },
            ),
    );
  }
}

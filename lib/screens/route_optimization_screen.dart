import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/master_item.dart';
import '../models/route_optimization.dart';
import '../services/master_data_service.dart';
import '../services/route_optimization_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_helpers.dart';

/// Part B (route optimization) + Part C (marketplace-to-logistics
/// integration — [caseId], see RouteOptimizationService on the backend).
/// Pickup and delivery stops are picked from Master Data (Locations /
/// Companies) by name; the backend resolves coordinates from there if
/// they've been geocoded, so this form never has to collect lat/lng by
/// hand for the common case.
class RouteOptimizationScreen extends StatefulWidget {
  /// When opened from a case's detail/timeline, pass its id so the
  /// resulting route gets linked to it (Part C).
  final String? caseId;

  const RouteOptimizationScreen({super.key, this.caseId});

  @override
  State<RouteOptimizationScreen> createState() => _RouteOptimizationScreenState();
}

class _RouteOptimizationScreenState extends State<RouteOptimizationScreen>
    with SubmitStateMixin<RouteOptimizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _costPerKmController = TextEditingController();

  String? _pickupName;
  final List<String?> _deliveryNames = [null];
  String? _vehicleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteOptimizationService>().fetchVehicles().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costPerKmController.dispose();
    super.dispose();
  }

  List<MasterItem> _stopOptions(MasterDataService masterData) => [
        ...masterData.activeItemsFor(MasterCategory.locations),
        ...masterData.activeItemsFor(MasterCategory.companies),
      ];

  Future<void> _optimize() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupName == null || _deliveryNames.any((d) => d == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a pickup and every delivery stop.')),
      );
      return;
    }

    final service = context.read<RouteOptimizationService>();
    await submitAction(
      () => service.optimize(
        caseId: widget.caseId,
        vehicleId: _vehicleId,
        pickup: RouteStopInput(name: _pickupName!),
        deliveries: _deliveryNames.map((d) => RouteStopInput(name: d!)).toList(),
        totalQuantityKg: double.parse(_quantityController.text.trim()),
        costPerKm: _costPerKmController.text.trim().isEmpty
            ? null
            : double.parse(_costPerKmController.text.trim()),
      ),
      successMessage: 'Route optimized.',
      popOnSuccess: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterData = context.watch<MasterDataService>();
    final routeService = context.watch<RouteOptimizationService>();
    final stopOptions = _stopOptions(masterData);

    return Scaffold(
      appBar: AppBar(title: const Text('Route Optimization')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.caseId != null)
              Card(
                color: AppTheme.primary.withOpacity(0.08),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'This route will be linked to the harvest case and logged on its timeline.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const SectionHeader('Pickup'),
            DropdownButtonFormField<String>(
              value: _pickupName,
              decoration: const InputDecoration(labelText: 'Pickup Location *'),
              items: stopOptions.map((m) => DropdownMenuItem(value: m.name, child: Text(m.name))).toList(),
              onChanged: (v) => setState(() => _pickupName = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader('Delivery Stops'),
                TextButton.icon(
                  onPressed: () => setState(() => _deliveryNames.add(null)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Stop'),
                ),
              ],
            ),
            for (int i = 0; i < _deliveryNames.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _deliveryNames[i],
                        decoration: InputDecoration(labelText: 'Stop ${i + 1} *'),
                        items: stopOptions
                            .map((m) => DropdownMenuItem(value: m.name, child: Text(m.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _deliveryNames[i] = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    if (_deliveryNames.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _deliveryNames.removeAt(i)),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const SectionHeader('Load & Vehicle'),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Total Quantity (KG) *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: numericValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _vehicleId,
              decoration: const InputDecoration(labelText: 'Vehicle (optional)'),
              items: routeService.vehicles
                  .map((v) => DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.registrationNumber} (${v.capacityKg.toStringAsFixed(0)} kg)'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _vehicleId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costPerKmController,
              decoration: const InputDecoration(labelText: 'Cost per KM (optional, default ₹20)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: submitting ? null : _optimize,
              icon: submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.route_outlined),
              label: const Text('Optimize Route'),
            ),
            const SizedBox(height: 24),
            if (routeService.lastResult != null) _RouteResultCard(result: routeService.lastResult!),
          ],
        ),
      ),
    );
  }
}

class _RouteResultCard extends StatelessWidget {
  final RouteOptimizationResult result;
  const _RouteResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Optimized Route', style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(result.status.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            LabeledValue(label: 'Original', value: '${result.originalDistanceKm.toStringAsFixed(1)} KM'),
            LabeledValue(label: 'Optimized', value: '${result.optimizedDistanceKm.toStringAsFixed(1)} KM', emphasize: true),
            if (result.distanceSavedKm > 0)
              LabeledValue(
                label: 'Potential Saving',
                value: '${result.distanceSavedKm.toStringAsFixed(1)} KM',
              ),
            LabeledValue(label: 'Estimated Duration', value: '${result.estimatedDurationMinutes.toStringAsFixed(0)} min'),
            LabeledValue(label: 'Estimated Cost', value: '₹${result.estimatedCost.toStringAsFixed(0)}'),
            if (result.vehicleRegistrationNumber != null)
              LabeledValue(label: 'Vehicle', value: result.vehicleRegistrationNumber!),
            const SizedBox(height: 12),
            const Text('Stop Sequence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...result.stops.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: s.stopType == StopType.pickup ? AppTheme.accent : AppTheme.primary,
                        child: Text('${s.sequenceIndex + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.name)),
                      Text(s.stopType == StopType.pickup ? 'Pickup' : 'Delivery',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

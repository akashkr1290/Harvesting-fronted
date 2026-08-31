import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/demand_prediction.dart';
import '../models/master_item.dart';
import '../services/api_client.dart';
import '../services/demand_forecast_service.dart';
import '../services/master_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_helpers.dart';

/// Part A — AI demand forecasting screen. Lets a user pick a crop +
/// location (from Master Data, same dropdowns used elsewhere in the app)
/// and either generate a fresh forecast or view the latest one. Every
/// figure shown is explicitly labelled an estimate — see the banner and
/// the "Estimate" chip — per the Phase 3 requirement that predictions
/// never be presented as guaranteed facts.
class DemandForecastScreen extends StatefulWidget {
  const DemandForecastScreen({super.key});

  @override
  State<DemandForecastScreen> createState() => _DemandForecastScreenState();
}

class _DemandForecastScreenState extends State<DemandForecastScreen>
    with SubmitStateMixin<DemandForecastScreen> {
  String? _cropType;
  String? _location;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DemandForecastService>().fetchOverview().catchError((_) {});
    });
  }

  Future<void> _generate() async {
    if (_cropType == null || _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a crop and a location first.')),
      );
      return;
    }
    final service = context.read<DemandForecastService>();
    await submitAction(
      () async {
        await service.generate(_cropType!, _location!);
        await service.fetchOverview();
      },
      successMessage: 'Forecast generated.',
      popOnSuccess: false,
    );
  }

  Future<void> _viewLatest() async {
    if (_cropType == null || _location == null) return;
    final service = context.read<DemandForecastService>();
    try {
      await service.fetchLatest(_cropType!, _location!);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterData = context.watch<MasterDataService>();
    final demandService = context.watch<DemandForecastService>();
    final crops = masterData.activeItemsFor(MasterCategory.cropTypes);
    final locations = masterData.activeItemsFor(MasterCategory.locations);

    return Scaffold(
      appBar: AppBar(title: const Text('Demand Forecast')),
      body: RefreshIndicator(
        onRefresh: () => demandService.fetchOverview(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppTheme.accent.withOpacity(0.12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI-generated forecasts are estimates based on historical harvest data — not guaranteed figures.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader('Generate / View Forecast'),
            DropdownButtonFormField<String>(
              value: _cropType,
              decoration: const InputDecoration(labelText: 'Crop / Product'),
              items: crops.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _cropType = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _location,
              decoration: const InputDecoration(labelText: 'Location'),
              items: locations.map((l) => DropdownMenuItem(value: l.name, child: Text(l.name))).toList(),
              onChanged: (v) => setState(() => _location = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _viewLatest,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View Latest'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: submitting ? null : _generate,
                    icon: submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_graph),
                    label: const Text('Generate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (demandService.selected != null) ...[
              const SectionHeader('Result'),
              _ForecastCard(prediction: demandService.selected!),
              const SizedBox(height: 20),
            ],
            const SectionHeader('All Forecasts'),
            if (demandService.isLoading && demandService.overview.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (demandService.overview.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No forecasts generated yet.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...demandService.overview.map((p) => _ForecastListTile(prediction: p)),
          ],
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final DemandPrediction prediction;
  const _ForecastCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(prediction.cropType,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                _DemandLevelChip(level: prediction.demandLevel),
              ],
            ),
            Text(prediction.location, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 24),
            LabeledValue(
              label: 'Predicted Demand (${dateFmt.format(prediction.predictionDate)})',
              value: '${prediction.predictedQuantity.toStringAsFixed(0)} KG',
              emphasize: true,
            ),
            if (prediction.historicalAverage != null)
              LabeledValue(
                label: 'Historical Average',
                value: '${prediction.historicalAverage!.toStringAsFixed(0)} KG',
              ),
            LabeledValue(label: 'Trend', value: prediction.trend.label),
            if (prediction.confidenceScore != null)
              LabeledValue(
                label: 'Confidence',
                value: '${(prediction.confidenceScore! * 100).toStringAsFixed(0)}%',
              ),
            LabeledValue(label: 'Based On', value: '${prediction.dataPointsUsed} month(s) of history'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science_outlined, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('Estimate — not a guaranteed figure', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastListTile extends StatelessWidget {
  final DemandPrediction prediction;
  const _ForecastListTile({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _DemandLevelChip(level: prediction.demandLevel),
        title: Text('${prediction.cropType} — ${prediction.location}'),
        subtitle: Text(
            '${prediction.predictedQuantity.toStringAsFixed(0)} KG · ${prediction.trend.label}'),
        trailing: Text(DateFormat('dd MMM').format(prediction.generatedAt),
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}

class _DemandLevelChip extends StatelessWidget {
  final DemandLevel level;
  const _DemandLevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level) {
      case DemandLevel.high:
        color = Colors.green.shade700;
        break;
      case DemandLevel.medium:
        color = AppTheme.accent;
        break;
      case DemandLevel.low:
        color = Colors.grey.shade600;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Text(level.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

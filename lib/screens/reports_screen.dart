import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/case_status.dart';
import '../models/reports_summary.dart';
import '../services/api_client.dart';
import '../services/reports_service.dart';
import '../widgets/form_helpers.dart';

/// Pulls from GET /api/reports/summary — computed server-side over every
/// case in the database, not just this device's local CaseService cache.
/// (Admin's stage-wise Overview screen still filters by location client
/// side, since the backend endpoint doesn't take a location parameter;
/// this screen is the one place that's purely server-computed.)
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _error;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.read<ReportsService>().fetchSummary();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not reach the server. Check your connection and try again.');
      }
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final bytes = await context.read<ApiClient>().getBytes('/api/reports/summary/export');
      if (!mounted) return;
      final file = XFile.fromData(
        Uint8List.fromList(bytes),
        name: 'harvestflow-reports.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      await Share.shareXFiles([file], text: 'HarvestFlow Reports');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Check your connection and try again.')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsService = context.watch<ReportsService>();
    final summary = reportsService.summary;
    final dateFmt = DateFormat('dd MMM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Dashboards'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: reportsService.isLoading ? null : _load,
          ),
          IconButton(
            tooltip: 'Export to Excel',
            icon: _exporting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            onPressed: _exporting ? null : _exportExcel,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(summary, reportsService.isLoading, dateFmt),
      ),
    );
  }

  Widget _buildBody(ReportsSummary? summary, bool isLoading, DateFormat dateFmt) {
    if (summary == null && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (summary == null && _error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 60),
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Center(child: ElevatedButton(onPressed: _load, child: const Text('Retry'))),
        ],
      );
    }

    if (summary == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader('Daily Snapshot'),
        Row(
          children: [
            Expanded(child: LabeledValue(label: 'Selections Today', value: '${summary.selectionsToday}')),
            Expanded(child: LabeledValue(label: 'Planned', value: '${summary.plannedCount}')),
            Expanded(child: LabeledValue(label: 'Completed', value: '${summary.completedCount}')),
          ],
        ),
        const Divider(height: 32),

        const SectionHeader('Stage-Wise Pending Report'),
        ...CaseStatus.values.map(
          (status) => LabeledValue(label: status.label, value: '${summary.stageWisePending[status] ?? 0}'),
        ),
        const Divider(height: 32),

        const SectionHeader('Purchase Summary by Farmer'),
        if (summary.purchaseSummaryByFarmer.isEmpty)
          const Text('No purchase invoices generated yet.', style: TextStyle(color: Colors.grey))
        else
          ...summary.purchaseSummaryByFarmer.entries.map(
            (e) => LabeledValue(label: e.key, value: '₹${e.value.toStringAsFixed(2)}'),
          ),
        const Divider(height: 32),

        const SectionHeader('Sales Summary by Company'),
        if (summary.salesSummaryByCompany.isEmpty)
          const Text('No sales invoices generated yet.', style: TextStyle(color: Colors.grey))
        else
          ...summary.salesSummaryByCompany.entries.map(
            (e) => LabeledValue(label: e.key, value: '₹${e.value.toStringAsFixed(2)}'),
          ),
        const Divider(height: 32),

        const SectionHeader('Recovery & Pulp Analytics'),
        LabeledValue(
            label: 'Average Recovery', value: summary.averageRecovery.toStringAsFixed(2), emphasize: true),
        LabeledValue(label: 'Average Pulp', value: summary.averagePulp.toStringAsFixed(2), emphasize: true),
        const SizedBox(height: 8),
        Text(
          'Based on ${summary.totalCases} case(s) as of ${dateFmt.format(DateTime.now())}. Pull down to refresh.',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

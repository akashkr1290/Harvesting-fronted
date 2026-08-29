import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/case_status.dart';
import '../../services/api_client.dart';
import '../../services/case_service.dart';
import '../../theme/app_theme.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  String _locationFilter = 'All';
  bool _exporting = false;

  Future<void> _refresh(CaseService caseService) async {
    try {
      await caseService.fetchAll();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not refresh. Check your connection and try again.')),
      );
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final path = _locationFilter == 'All'
          ? '/api/cases/export'
          : '/api/cases/export?location=${Uri.encodeQueryComponent(_locationFilter)}';
      final bytes = await context.read<ApiClient>().getBytes(path);
      if (!mounted) return;
      final file = XFile.fromData(
        Uint8List.fromList(bytes),
        name: 'harvestflow-cases.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      await Share.shareXFiles([file], text: 'HarvestFlow Cases');
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
    final caseService = context.watch<CaseService>();
    final cases = caseService.allCases;
    final locations = ['All', ...{for (final c in cases) c.selection.location}];

    final filtered = _locationFilter == 'All'
        ? cases
        : cases.where((c) => c.selection.location == _locationFilter).toList();

    final counts = {for (final s in CaseStatus.values) s: filtered.where((c) => c.status == s).length};

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Overview')),
      body: RefreshIndicator(
        onRefresh: () => _refresh(caseService),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('Filter by location:'),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _locationFilter,
                    isExpanded: true,
                    items: locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() => _locationFilter = v ?? 'All'),
                  ),
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
            const SizedBox(height: 8),
            Text('Total cases: ${filtered.length}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: CaseStatus.values
                  .map((s) => _StageCountCard(label: s.label, count: counts[s] ?? 0))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageCountCard extends StatelessWidget {
  final String label;
  final int count;
  const _StageCountCard({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 2),
          ],
        ),
      ),
    );
  }
}

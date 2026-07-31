import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/case_status.dart';
import '../../services/case_service.dart';
import '../../theme/app_theme.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  String _locationFilter = 'All';

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
        onRefresh: () => caseService.fetchAll(),
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
                  icon: const Icon(Icons.download_outlined),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Excel export runs against the real backend dataset once connected.')),
                  ),
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

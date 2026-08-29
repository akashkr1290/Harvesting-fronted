import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

/// Backs onto GET /api/analytics/{verification,operational,sih-impact}.
/// Every figure shown here is labeled AVAILABLE / DEMO_DATA / NOT_AVAILABLE
/// by the backend — this screen renders those labels as-is rather than
/// hiding them, per the SOW's "for demo data, label it clearly" rule.
class SihImpactScreen extends StatefulWidget {
  const SihImpactScreen({super.key});

  @override
  State<SihImpactScreen> createState() => _SihImpactScreenState();
}

class _SihImpactScreenState extends State<SihImpactScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _verification;
  Map<String, dynamic>? _operational;
  List<dynamic> _impactMetrics = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final results = await Future.wait([
        api.get('/api/analytics/verification'),
        api.get('/api/analytics/operational'),
        api.get('/api/analytics/sih-impact'),
      ]);
      if (!mounted) return;
      setState(() {
        _verification = results[0] as Map<String, dynamic>;
        _operational = results[1] as Map<String, dynamic>;
        _impactMetrics = (results[2] as Map<String, dynamic>)['metrics'] as List<dynamic>;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load analytics. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppTheme.primary;
      case 'DEMO_DATA':
        return AppTheme.accent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & SIH Impact')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger))),
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Produce Image Verification', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _verificationCard(),
                      const SizedBox(height: 24),
                      Text('Operations', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _operationalCard(),
                      const SizedBox(height: 24),
                      Text('SIH Impact', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Each line below is labeled by how real it is: AVAILABLE (from this '
                        'deployment\'s own data), DEMO_DATA (from Phase 4\'s mock payment '
                        'subsystem), or NOT_AVAILABLE (needs the marketplace/forecasting phases).',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      ..._impactMetrics.map((m) => _impactCard(m as Map<String, dynamic>)),
                    ],
                  ),
      ),
    );
  }

  Widget _verificationCard() {
    final v = _verification!;
    final total = v['totalImages'] as int;
    final pending = v['pendingReviewCount'] as int;
    final rate = v['acceptanceRate'] as num?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _stat('Total Photos', '$total'),
            _stat('Pending Review', '$pending'),
            _stat('Acceptance', rate == null ? '—' : '${(rate * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }

  Widget _operationalCard() {
    final o = _operational!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _stat('Total Cases', '${o['totalCases']}'),
            _stat('Farmers', '${o['distinctFarmers']}'),
            _stat('Sales Completed', '${o['salesCompletedCount']}'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _impactCard(Map<String, dynamic> metric) {
    final status = metric['status'] as String;
    final color = _statusColor(status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(metric['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (metric['value'] != null) ...[
              const SizedBox(height: 6),
              Text(metric['value'] as String, style: const TextStyle(fontSize: 14)),
            ],
            if (metric['note'] != null) ...[
              const SizedBox(height: 4),
              Text(metric['note'] as String, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}

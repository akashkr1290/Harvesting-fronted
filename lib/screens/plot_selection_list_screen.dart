import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/case_status.dart';
import '../models/harvest_case.dart';
import '../models/user_role.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../widgets/case_card.dart';
import '../widgets/document_actions.dart';
import 'plot_selection_form_screen.dart';

class PlotSelectionListScreen extends StatefulWidget {
  const PlotSelectionListScreen({super.key});

  @override
  State<PlotSelectionListScreen> createState() => _PlotSelectionListScreenState();
}

class _PlotSelectionListScreenState extends State<PlotSelectionListScreen> {
  final _searchController = TextEditingController();
  CaseStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HarvestCase> _filtered(List<HarvestCase> all) {
    final query = _searchController.text.trim().toLowerCase();
    return all.where((c) {
      final s = c.selection;
      final matchesQuery = query.isEmpty ||
          s.farmerName.toLowerCase().contains(query) ||
          s.village.toLowerCase().contains(query) ||
          s.commissionAgentName.toLowerCase().contains(query) ||
          s.selectedCompany.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == null || c.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList()
      ..sort((a, b) => b.selection.visitDate.compareTo(a.selection.visitDate));
  }

  /// Same rule the backend enforces (SOW 5.3 C): editable only while still
  /// SUBMITTED_FOR_PLANNING. This client-side check only decides whether to
  /// show the edit button — the backend re-checks this itself on the
  /// actual PUT call regardless of what this screen shows.
  bool _isEditable(HarvestCase harvestCase) {
    final role = context.read<AuthService>().role;
    return role == UserRole.plotSelection && harvestCase.status == CaseStatus.submittedForPlanning;
  }

  bool _isAwaitingAcceptance(HarvestCase harvestCase) {
    final role = context.read<AuthService>().role;
    return role == UserRole.plotSelection && harvestCase.status == CaseStatus.awaitingPlotSelection;
  }

  Future<void> _accept(HarvestCase harvestCase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept Plot Selection?'),
        content: const Text(
          'Accept this marketplace case and send it to the Planning Team? This action cannot be undone from Plot Selection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<CaseService>().acceptPlotSelection(harvestCase);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accepted. Case moved to Planning.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not accept the case. Check your connection and try again.')),
      );
    }
  }

  void _openEdit(HarvestCase harvestCase) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlotSelectionFormScreen(existingCase: harvestCase)),
    );
  }

  Future<void> _refresh() async {
    try {
      await context.read<CaseService>().fetchAll();
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

  void _showTimeline(HarvestCase harvestCase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final fmt = DateFormat('dd MMM yyyy, hh:mm a');
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
          child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Timeline · Case #${harvestCase.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (_isEditable(harvestCase))
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openEdit(harvestCase);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...harvestCase.timeline.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.action, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${entry.actor} · ${fmt.format(entry.timestamp)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 28),
              const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Every case has plot selection data from creation, so
                  // this one's always available.
                  DocumentDownloadButton(
                    apiClient: context.read<ApiClient>(),
                    documentPath: '/api/cases/${harvestCase.id}/documents/selection-report',
                    fileName: 'selection-report-${harvestCase.id}.pdf',
                    label: 'Selection Report',
                    icon: Icons.description_outlined,
                  ),
                  if (harvestCase.packingIssue != null)
                    DocumentDownloadButton(
                      apiClient: context.read<ApiClient>(),
                      documentPath: '/api/cases/${harvestCase.id}/documents/packing-issue-slip',
                      fileName: 'packing-issue-slip-${harvestCase.id}.pdf',
                      label: 'Issue Slip',
                      icon: Icons.inventory_2_outlined,
                    ),
                  if (harvestCase.purchaseInvoice != null)
                    DocumentDownloadButton(
                      apiClient: context.read<ApiClient>(),
                      documentPath: '/api/cases/${harvestCase.id}/documents/purchase-invoice',
                      fileName: 'purchase-invoice-${harvestCase.id}.pdf',
                      label: 'Purchase Invoice',
                      icon: Icons.receipt_long_outlined,
                    ),
                  if (harvestCase.salesInvoice != null)
                    DocumentDownloadButton(
                      apiClient: context.read<ApiClient>(),
                      documentPath: '/api/cases/${harvestCase.id}/documents/sales-invoice',
                      fileName: 'sales-invoice-${harvestCase.id}.pdf',
                      label: 'Sales Invoice',
                      icon: Icons.receipt_outlined,
                    ),
                ],
              ),
            ],
          ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseService = context.watch<CaseService>();
    final results = _filtered(caseService.allCases);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Cases')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by farmer, village, agent, or company',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _statusFilter == null,
                  onSelected: () => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                ...CaseStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: status.label,
                      selected: _statusFilter == status,
                      onSelected: () => setState(() => _statusFilter = status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: results.isEmpty
                ? ListView(
                    // Wrapped in a scrollable even when empty so pull-to-refresh
                    // still works with nothing to show.
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text('No matching records.', style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final c = results[index];
                        return CaseCard(
                          harvestCase: c,
                          onTap: () => _showTimeline(c),
                          trailingAction: _isAwaitingAcceptance(c)
                              ? FilledButton.icon(
                                  onPressed: () => _accept(c),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Accept'),
                                )
                              : (_isEditable(c)
                                  ? IconButton(
                                      tooltip: 'Edit',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                                      onPressed: () => _openEdit(c),
                                    )
                                  : null),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

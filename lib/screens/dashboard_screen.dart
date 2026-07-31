import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_status.dart';
import '../models/harvest_case.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../widgets/case_card.dart';
import 'plot_selection_form_screen.dart';
import 'plot_selection_list_screen.dart';
import 'planning_form_screen.dart';
import 'purchase_rate_screen.dart';
import 'godown_issue_screen.dart';
import 'godown_return_screen.dart';
import 'supervisor_completion_screen.dart';
import 'logistics_entry_screen.dart';
import 'labor_entry_screen.dart';
import 'purchase_invoice_screen.dart';
import 'sales_invoice_screen.dart';
import 'eicher_trip_screen.dart';
import 'reports_screen.dart';
import 'admin/admin_overview_screen.dart';
import 'admin/user_management_screen.dart';
import 'admin/master_data_screen.dart';
import 'login_screen.dart';
import '../models/logistics_entry.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Routes a tapped pending case to the correct stage screen. Some roles
  /// own two different stages (Purchase Account: rate update vs invoice;
  /// Godown: issue vs return) so status disambiguates which screen opens.
  void _openCaseAction(BuildContext context, UserRole role, HarvestCase harvestCase) {
    Widget? screen;

    switch (role) {
      case UserRole.planning:
        screen = PlanningFormScreen(harvestCase: harvestCase);
        break;
      case UserRole.purchaseAccount:
        screen = harvestCase.status == CaseStatus.planned
            ? PurchaseRateScreen(harvestCase: harvestCase)
            : PurchaseInvoiceScreen(harvestCase: harvestCase);
        break;
      case UserRole.godown:
        screen = harvestCase.status == CaseStatus.rateUpdated
            ? GodownIssueScreen(harvestCase: harvestCase)
            : GodownReturnScreen(harvestCase: harvestCase);
        break;
      case UserRole.supervisor:
        screen = SupervisorCompletionScreen(harvestCase: harvestCase);
        break;
      case UserRole.pickupPerson:
        screen = LogisticsEntryScreen(harvestCase: harvestCase, kind: LogisticsKind.pickup);
        break;
      case UserRole.transportPerson:
        screen = LogisticsEntryScreen(harvestCase: harvestCase, kind: LogisticsKind.transport);
        break;
      case UserRole.laborCoordinator:
        screen = LaborEntryScreen(harvestCase: harvestCase);
        break;
      case UserRole.admin:
        screen = SalesInvoiceScreen(harvestCase: harvestCase);
        break;
      case UserRole.plotSelection:
      case UserRole.eicherDriver:
        screen = null;
        break;
    }

    if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final caseService = context.watch<CaseService>();
    final role = auth.role ?? UserRole.admin;

    if (role == UserRole.eicherDriver) {
      return const EicherTripScreen();
    }

    final pending = caseService.pendingFor(role);

    return Scaffold(
      appBar: AppBar(
        title: Text(role.label),
        actions: [
          if (role == UserRole.admin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Admin Tools',
              onSelected: (value) {
                Widget target;
                switch (value) {
                  case 'overview':
                    target = const AdminOverviewScreen();
                    break;
                  case 'users':
                    target = const UserManagementScreen();
                    break;
                  case 'masters':
                    target = const MasterDataScreen();
                    break;
                  default:
                    target = const ReportsScreen();
                }
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'overview', child: Text('Overview & Filters')),
                PopupMenuItem(value: 'users', child: Text('User Management')),
                PopupMenuItem(value: 'masters', child: Text('Master Data')),
                PopupMenuItem(value: 'reports', child: Text('Reports')),
              ],
            ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: role == UserRole.plotSelection
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlotSelectionFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Selection'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => caseService.fetchAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome, ${auth.username}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(role.description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total Cases',
                    value: '${caseService.allCases.length}',
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Pending on You',
                    value: '${pending.length}',
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pending on you (${pending.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PlotSelectionListScreen()),
                  ),
                  child: const Text('Browse All Cases'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (pending.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Nothing pending right now.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...pending.map(
                (c) => CaseCard(
                  harvestCase: c,
                  onTap: () => _openCaseAction(context, role, c),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

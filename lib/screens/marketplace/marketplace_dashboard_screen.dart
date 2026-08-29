import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import 'marketplace_browse_screen.dart';
import 'my_listings_screen.dart';
import 'offers_received_screen.dart';
import 'my_offers_screen.dart';
import 'orders_screen.dart';
import 'earnings_screen.dart';

/// Home screen for the four marketplace roles (Farmer, FPO, Consumer,
/// Bulk Buyer) — the marketplace equivalent of DashboardScreen, kept as a
/// separate widget rather than a branch inside DashboardScreen so the
/// internal harvest-ops dashboard's logic is never touched.
class MarketplaceDashboardScreen extends StatelessWidget {
  const MarketplaceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final role = auth.role ?? UserRole.consumer;
    final isSeller = role.isMarketplaceSeller;

    final tiles = isSeller
        ? [
            _Tile(
              icon: Icons.storefront_outlined,
              title: 'My Listings',
              subtitle: 'Create, edit, publish, and close your produce listings',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyListingsScreen())),
            ),
            _Tile(
              icon: Icons.local_offer_outlined,
              title: 'Offers Received',
              subtitle: 'Compare and act on buyer offers',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OffersReceivedScreen())),
            ),
            _Tile(
              icon: Icons.receipt_long_outlined,
              title: 'Orders',
              subtitle: 'Orders created from your accepted offers',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
            ),
            _Tile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Earnings',
              subtitle: 'Your marketplace earnings summary',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EarningsScreen())),
            ),
          ]
        : [
            _Tile(
              icon: Icons.storefront_outlined,
              title: 'Marketplace',
              subtitle: 'Browse, search, and filter produce listings',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketplaceBrowseScreen())),
            ),
            _Tile(
              icon: Icons.local_offer_outlined,
              title: 'My Offers',
              subtitle: 'Offers you have submitted',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOffersScreen())),
            ),
            _Tile(
              icon: Icons.receipt_long_outlined,
              title: 'Orders',
              subtitle: 'Orders from your accepted offers',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(role.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome, ${auth.name ?? ''}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'HarvestFlow Marketplace',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...tiles,
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/listing_status.dart';
import '../../models/offer_status.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';
import '../../services/marketplace_service.dart';
import '../../services/offer_service.dart';
import '../../services/order_service.dart';
import '../../widgets/language_selector_widget.dart';
import '../../widgets/simple/crop_art.dart';
import '../../widgets/simple/simple_ui.dart';
import '../login_screen.dart';
import 'money_simple_screen.dart';
import 'my_crops_simple_screen.dart';
import 'offers_simple_screen.dart';
import 'orders_simple_screen.dart';
import 'sell_wizard_screen.dart';

/// Farmer / FPO home in Simple mode: five big picture buttons, voice, help.
class FarmerHomeSimple extends StatefulWidget {
  const FarmerHomeSimple({super.key});

  @override
  State<FarmerHomeSimple> createState() => _FarmerHomeSimpleState();
}

class _FarmerHomeSimpleState extends State<FarmerHomeSimple> {
  String? _demandTip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final offers = context.read<OfferService>();
    final orders = context.read<OrderService>();
    final listings = context.read<MarketplaceService>();
    await Future.wait([
      offers.fetchReceived().catchError((_) {}),
      orders.fetchEarnings().catchError((_) {}),
      listings.fetchMyListings().catchError((_) {}),
    ]);
    await _loadDemandTip();
  }

  /// Shows a forecast hint for the farmer's latest crop when staff have generated one.
  Future<void> _loadDemandTip() async {
    final mine = context.read<MarketplaceService>().myListings;
    if (mine.isEmpty || !mounted) return;
    final latest = mine.first;
    final loc = context.read<LocalizationService>();
    try {
      final res = await context.read<ApiClient>().get('/api/demand/latest',
          query: {'cropType': latest.cropName, 'location': latest.location}) as Map<String, dynamic>;
      final trend = res['trend'] as String?;
      final name = localCropName(loc, latest.cropName);
      if (!mounted) return;
      setState(() {
        _demandTip = trend == 'INCREASING'
            ? loc.tf('demand_up', {'crop': name})
            : trend == 'DECREASING'
                ? loc.tf('demand_down', {'crop': name})
                : null;
      });
    } catch (_) {
      // No forecast for this crop yet: nothing to show.
    }
  }

  Future<void> _logout() async {
    context.read<AuthService>().logout();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) => _refresh());

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthService>();
    final pendingOffers = context.watch<OfferService>().received.where((o) => o.status == OfferStatus.pending).length;
    final earnings = context.watch<OrderService>().earnings;
    final liveCrops =
        context.watch<MarketplaceService>().myListings.where((l) => l.status == ListingStatus.published).length;
    final name = (auth.name ?? '').split(' ').first;

    String speech() => [
          loc.tf('hello_name', {'name': name}),
          loc.t('sell_crop'),
          '${loc.t('offers')}: $pendingOffers',
          loc.t('orders'),
          loc.t('my_crops'),
          if (earnings != null) '${loc.t('my_money')}: ${rupees(earnings.receivedAmount)} ${loc.t('received')}',
          if (_demandTip != null) _demandTip!,
        ].join('. ');

    return SimplePage(
      header: SimpleHeader(
        title: loc.tf('hello_name', {'name': name}),
        showBack: false,
        speakText: speech,
        trailing: IconButton(
          tooltip: loc.t('logout'),
          iconSize: 30,
          icon: const Icon(Icons.logout_rounded, color: SimpleColors.quiet),
          onPressed: _logout,
        ),
      ),
      children: [
        const Row(children: [ModeToggle(), Spacer(), LanguageSelectorWidget()]),
        const SizedBox(height: 14),
        BigActionTile(
          primary: true,
          height: 150,
          icon: const Icon(Icons.storefront_rounded, size: 56, color: Colors.white),
          title: loc.t('sell_crop'),
          onTap: () => _open(const SellWizardScreen()),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: BigActionTile(
              icon: const Icon(Icons.local_offer_rounded, size: 48, color: SimpleColors.green),
              title: loc.t('offers'),
              badge: pendingOffers,
              onTap: () => _open(const OffersSimpleScreen()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BigActionTile(
              icon: const Icon(Icons.local_shipping_rounded, size: 48, color: SimpleColors.green),
              title: loc.t('orders'),
              onTap: () => _open(const OrdersSimpleScreen()),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: BigActionTile(
              icon: const Icon(Icons.grass_rounded, size: 48, color: SimpleColors.green),
              title: loc.t('my_crops'),
              subtitle: liveCrops > 0 ? '$liveCrops ${loc.t('status_live').toLowerCase()}' : null,
              onTap: () => _open(const MyCropsSimpleScreen()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BigActionTile(
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 48, color: SimpleColors.green),
              title: loc.t('my_money'),
              trailing: earnings == null
                  ? null
                  : Text('${rupees(earnings.receivedAmount)} ${loc.t('received')}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SimpleColors.green)),
              onTap: () => _open(const MoneySimpleScreen()),
            ),
          ),
        ]),
        if (_demandTip != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SimpleColors.marigoldSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SimpleColors.marigold, width: 2),
            ),
            child: Row(children: [
              const Icon(Icons.trending_up_rounded, size: 36, color: Color(0xFF8A5A00)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${_demandTip!} (${loc.t('estimate_note')})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SimpleColors.ink)),
              ),
            ]),
          ),
        ],
      ],
      bottom: const [HelpCallButton()],
    );
  }
}

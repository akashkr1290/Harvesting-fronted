import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/language_selector_widget.dart';
import '../../widgets/simple/simple_ui.dart';
import '../login_screen.dart';
import '../marketplace/marketplace_browse_screen.dart';
import '../marketplace/my_offers_screen.dart';
import 'orders_simple_screen.dart';

/// Home for consumers in Simple mode: buy, my offers, orders, help.
class BuyerHomeSimple extends StatelessWidget {
  const BuyerHomeSimple({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthService>();
    final name = (auth.name ?? '').split(' ').first;
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return SimplePage(
      header: SimpleHeader(
        title: loc.tf('hello_name', {'name': name}),
        showBack: false,
        speakText: () => [loc.tf('hello_name', {'name': name}), loc.t('buy_crops'), loc.t('my_offers'), loc.t('orders')].join('. '),
        trailing: IconButton(
          tooltip: loc.t('logout'),
          iconSize: 30,
          icon: const Icon(Icons.logout_rounded, color: SimpleColors.quiet),
          onPressed: () {
            context.read<AuthService>().logout();
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
          },
        ),
      ),
      children: [
        const Row(children: [ModeToggle(), Spacer(), LanguageSelectorWidget()]),
        const SizedBox(height: 14),
        BigActionTile(
          primary: true,
          height: 150,
          icon: const Icon(Icons.shopping_basket_rounded, size: 56, color: Colors.white),
          title: loc.t('buy_crops'),
          onTap: () => open(const MarketplaceBrowseScreen()),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: BigActionTile(
              icon: const Icon(Icons.local_offer_rounded, size: 48, color: SimpleColors.green),
              title: loc.t('my_offers'),
              onTap: () => open(const MyOffersScreen()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BigActionTile(
              icon: const Icon(Icons.local_shipping_rounded, size: 48, color: SimpleColors.green),
              title: loc.t('orders'),
              onTap: () => open(const OrdersSimpleScreen()),
            ),
          ),
        ]),
      ],
      bottom: const [HelpCallButton()],
    );
  }
}

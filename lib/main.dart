import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/case_service.dart';
import 'services/user_service.dart';
import 'services/master_data_service.dart';
import 'services/reports_service.dart';
import 'services/marketplace_service.dart';
import 'services/offer_service.dart';
import 'services/order_service.dart';
import 'services/demand_forecast_service.dart';
import 'services/route_optimization_service.dart';
import 'services/produce_image_service.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HarvestFlowApp());
}

/// Lets the 401-handling code below navigate to the login screen without
/// needing a BuildContext of its own — ApiClient.onUnauthorized fires from
/// deep inside a network call, well outside any widget's build method.
final navigatorKey = GlobalKey<NavigatorState>();

class HarvestFlowApp extends StatefulWidget {
  const HarvestFlowApp({super.key});

  @override
  State<HarvestFlowApp> createState() => _HarvestFlowAppState();
}

class _HarvestFlowAppState extends State<HarvestFlowApp> {
  // Created once in initState (not in build) so a stray rebuild of the
  // root widget can never silently replace this with a fresh, token-less
  // instance — that used to be a latent risk when this was built inline
  // in a StatelessWidget's build().
  late final ApiClient _apiClient;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authService = AuthService(_apiClient);

    // Any request coming back 401 (expired/invalid token) forces a clean
    // logout + redirect, instead of the previous behavior of surfacing a
    // generic error on whatever screen happened to be open.
    _apiClient.onUnauthorized = () {
      if (!_authService.isLoggedIn) return; // already logged out, avoid double-pop
      _authService.logout();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      final ctx = navigatorKey.currentState?.overlay?.context;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Your session has expired. Please log in again.')),
        );
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _apiClient),
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        ChangeNotifierProvider(create: (_) => CaseService(_apiClient)),
        ChangeNotifierProvider(create: (_) => UserService(_apiClient)),
        ChangeNotifierProvider(create: (_) => MasterDataService(_apiClient)),
        ChangeNotifierProvider(create: (_) => ReportsService(_apiClient)),
        ChangeNotifierProvider(create: (_) => MarketplaceService(_apiClient)),
        ChangeNotifierProvider(create: (_) => OfferService(_apiClient)),
        ChangeNotifierProvider(create: (_) => OrderService(_apiClient)),
        ChangeNotifierProvider(create: (_) => DemandForecastService(_apiClient)),
        ChangeNotifierProvider(create: (_) => RouteOptimizationService(_apiClient)),
        ChangeNotifierProvider(create: (_) => ProduceImageService(_apiClient)),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'HarvestFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const LoginScreen(),
      ),
    );
  }
}

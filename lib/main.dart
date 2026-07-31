import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/case_service.dart';
import 'services/user_service.dart';
import 'services/master_data_service.dart';
import 'services/reports_service.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HarvestFlowApp());
}

class HarvestFlowApp extends StatelessWidget {
  const HarvestFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // One shared ApiClient instance carries the JWT (set by AuthService on
    // login) to every other service automatically — see api_client.dart.
    final apiClient = ApiClient();

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => AuthService(apiClient)),
        ChangeNotifierProvider(create: (_) => CaseService(apiClient)),
        ChangeNotifierProvider(create: (_) => UserService(apiClient)),
        ChangeNotifierProvider(create: (_) => MasterDataService(apiClient)),
        ChangeNotifierProvider(create: (_) => ReportsService(apiClient)),
      ],
      child: MaterialApp(
        title: 'HarvestFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const LoginScreen(),
      ),
    );
  }
}


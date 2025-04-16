import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/routes.dart';
import 'provider/dark_mode_provider.dart';
import 'controller/airtime_controller.dart';
import 'controller/data_bundle_controller.dart';
import 'controller/cable_tv_controller.dart';
import 'controller/electricity_controller.dart';
import 'controller/WalletTransactionController.dart';
import 'controller/wallet_to_bank_controller.dart';
import 'controller/wallet_transfer_controller.dart';
import 'controller/registration_controller.dart';
import 'controller/organization_controller.dart';
import 'controller/cards_controller.dart';
import 'utils/navigator_key.dart';
import 'themes/color_schemes.dart';
import 'themes/input_decoration_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DarkModeProvider()..getDarkMode()),
        ChangeNotifierProvider(create: (_) => AirtimeController()), // Added
        ChangeNotifierProvider(create: (_) => DataBundleController()), // Added
        ChangeNotifierProvider(create: (_) => CableTVController()),
        ChangeNotifierProvider(create: (context) => ElectricityController()),
        ChangeNotifierProvider(create: (context) => WalletTransactionController()),
        ChangeNotifierProvider(create: (context) => WalletToBankTransferController()),
        ChangeNotifierProvider(create: (context) => WalletTransferController()),
        ChangeNotifierProvider(create: (context) => NinVerificationController()),
        ChangeNotifierProvider(create: (_) => OrganizationController()),
        ChangeNotifierProvider(create: (context) => VirtualCardController()),
      ],
      child: Consumer<DarkModeProvider>(
        builder: (context, darkMode, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SDDTIF',
            navigatorKey: navigatorKey,
            themeMode: darkMode.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: lightColorScheme,
              inputDecorationTheme: CustomInputDecorationTheme.inputDecorationTheme,
            ),
            darkTheme: ThemeData(
              colorScheme: darkColorScheme,
              inputDecorationTheme: CustomInputDecorationTheme.inputDecorationTheme,
            ),
            initialRoute: Routes.initial,
            routes: Routes.routes, // Use named routes
          );
        },
      ),
    );
  }
}

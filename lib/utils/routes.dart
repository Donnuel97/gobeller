import 'package:flutter/material.dart';
import 'package:gobeller/pages/login/login_page.dart';
import 'package:gobeller/pages/registration/registration.dart';
import 'package:gobeller/pages/success/dashboard_page.dart';
import 'package:gobeller/pages/welcome/welcome_page.dart';
import 'package:gobeller/pages/profile/profile_page.dart';
import 'package:gobeller/pages/wallet/wallet_page.dart';
import 'package:gobeller/pages/cards/virtual_card_page.dart';
import 'package:gobeller/pages/quick_action/airtime.dart';
import 'package:gobeller/pages/quick_action/data_purchase_page.dart';
import 'package:gobeller/pages/quick_action/cable_tv_page.dart';
import 'package:gobeller/pages/quick_action/electric_meter_page.dart';
import 'package:gobeller/pages/quick_action/wallet_to_wallet.dart';
import 'package:gobeller/pages/quick_action/wallet_to_bank.dart';

class Routes {

  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String virtualCard = '/virtualCard';
  static const String dashboard = '/dashboard';
  static const String airtime = '/airtime';
  static const String data_purchase = '/data_purchase';
  static const String cable_tv = '/cable-tv';
  static const String electric = '/electric';
  static const String transfer = '/transfer';
  static const String bank_transfer = '/bank_transfer';


  static Map<String, Widget Function(BuildContext)> routes = {
    initial: (context) => const WelcomePage(),
    login: (context) => const LoginPage(),
    register: (context) => RegistrationPage(),
    dashboard: (context) => const DashboardPage(),
    profile: (context) => const ProfilePage(),
    wallet: (context) => const WalletPage(),
    virtualCard: (context) => const VirtualCardPage(),
    airtime: (context) => const BuyAirtimePage(),
    data_purchase: (context) => const DataPurchasePage(),
    cable_tv: (context) => const CableTVPage(),
    electric: (context) => const ElectricityPaymentPage(),
    transfer: (context) => const WalletToWalletTransferPage(),
    bank_transfer: (context) => const WalletToBankTransferPage(),
  };
}


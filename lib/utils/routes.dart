import 'package:flutter/material.dart';
import 'package:gobeller/pages/login/login_page.dart';
import 'package:gobeller/pages/registration/registration.dart';
import 'package:gobeller/pages/success/dashboard_page.dart';
import 'package:gobeller/pages/success/transaction_history.dart';
import 'package:gobeller/pages/welcome/welcome_page.dart';
import 'package:gobeller/pages/profile/profile_page.dart';
import 'package:gobeller/pages/wallet/wallet_page.dart';
import 'package:gobeller/pages/cards/virtual_card_page.dart';
import 'package:gobeller/pages/cards/card_details_page.dart';
import 'package:gobeller/pages/quick_action/airtime.dart';
import 'package:gobeller/pages/quick_action/data_purchase_page.dart';
import 'package:gobeller/pages/quick_action/cable_tv_page.dart';
import 'package:gobeller/pages/quick_action/electric_meter_page.dart';
import 'package:gobeller/pages/quick_action/wallet_to_wallet.dart';
import 'package:gobeller/pages/quick_action/wallet_to_bank.dart';

import 'package:gobeller/pages/success_screens/registration_success_screen/regSuccess.dart';
import 'package:gobeller/pages/success_screens/quick_menu/airtime_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/data_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/electricity_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/wallet_to_bank_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/wallet_to_wallet_success.dart';
import 'package:gobeller/pages/success_screens/quick_menu/cable_result.dart';




class Routes {

  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String virtualCard = '/virtualCard';
  static const String dashboard = '/dashboard';
  static const String history = '/history';
  static const String airtime = '/airtime';
  static const String data_purchase = '/data_purchase';
  static const String cable_tv = '/cable-tv';
  static const String electric = '/electric';
  static const String transfer = '/transfer';
  static const String bank_transfer = '/bank_transfer';
  static const String transfer_result = '/transfer_result';
  static const String reg_success = '/reg_success';
  static const String airtime_result = '/airtime-result';
  static const String data_result = '/data_result';
  static const String electricity_result = '/electricity_result';
  static const String bank_result = '/bank_result';
  static const String cable_result = '/cable_result';
  static const String card_details = '/card_details';




  static Map<String, Widget Function(BuildContext)> routes = {
    initial: (context) => const WelcomePage(),
    login: (context) => const LoginPage(),
    register: (context) => RegistrationPage(),
    dashboard: (context) => const DashboardPage(),
    history: (context) => const TransactionHistoryPage(),
    profile: (context) => const ProfilePage(),
    wallet: (context) => const WalletPage(),
    virtualCard: (context) => const VirtualCardPage(),
    airtime: (context) => const BuyAirtimePage(),
    data_purchase: (context) => const DataPurchasePage(),
    cable_tv: (context) => const CableTVPage(),
    electric: (context) => const ElectricityPaymentPage(),
    transfer: (context) => const WalletToWalletTransferPage(),
    bank_transfer: (context) => const WalletToBankTransferPage(),
    transfer_result: (context) => const TransferResultPage(),
    reg_success: (context) => const RegistrationSuccessPage(),
    airtime_result: (context) => const AirtimeResultPage(),
    data_result: (context) => const DataResultPage(),
    electricity_result: (context) => const ElectricityResultPage(),
    bank_result: (context) => const WalletTransferResultPage(),
    cable_result: (context) => const CableTVResultPage(),
    card_details: (context) { final card = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;return CardDetailsPage(card: card);},
  };
}


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';

class QuickActionsGrid extends StatefulWidget {
  const QuickActionsGrid({super.key});

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid> {
  Color? _primaryColor;
  Color? _secondaryColor;
  Map<String, dynamic> _menuItems = {};
  List<Widget> _menuCards = [];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndMenus();
  }

  Future<void> _loadSettingsAndMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    final orgJson = prefs.getString('organizationData');

    if (settingsJson != null) {
      final settings = json.decode(settingsJson)['data'];
      final primaryColorHex = settings['customized-app-primary-color'] ?? '#171E3B';
      final secondaryColorHex = settings['customized-app-secondary-color'] ?? '#EB6D00';

      _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
      _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
    }

    if (orgJson != null) {
      final orgData = json.decode(orgJson);

      _menuItems = {
        ...?orgData['data']?['customized_app_displayable_menu_items'],
        "display-corporate-account-menu": true,
        "display-loan-menu": true,
        "display-fx-menu": true,
      };
    }

    _menuCards = _buildVisibleMenuCards();

    setState(() {});
  }

  List<Widget> _buildVisibleMenuCards() {
    final List<Widget> cards = [];

    if (_menuItems['display-wallet-transfer-menu'] == true || _menuItems['display-bank-transfer-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.payments, label: "Transfer", route: Routes.bank_transfer));
    }
    if (_menuItems['display-airtime-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.phone_android, label: "Airtime", route: Routes.airtime));
    }
    if (_menuItems['display-data-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.wifi, label: "Data", route: Routes.data_purchase));
    }
    if (_menuItems['display-cable-tv-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.tv, label: "Cable", route: Routes.cable_tv));
    }
    if (_menuItems['display-electricity-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.lightbulb, label: "Electric", route: Routes.electric));
    }


    // New upcoming features
    if (_menuItems['display-corporate-account-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.business_center, label: "Corporate Account", route: Routes.coming_soon));
    }
    if (_menuItems['display-loan-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.monetization_on_outlined, label: "Loan", route: Routes.loan_soon));
    }
    if (_menuItems['display-fx-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.currency_exchange, label: "Fix Deposit", route: Routes.fx_soon));
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    if (_menuCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Menu not available, contact support for assistance",
            style: TextStyle(
              color: _primaryColor ?? Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust this threshold as needed
        double screenWidth = constraints.maxWidth;
        int crossAxisCount;

        if (screenWidth >= 900) {
          crossAxisCount = 6; // large screens like tablets
        } else if (screenWidth >= 600) {
          crossAxisCount = 5; // medium devices
        } else {
          crossAxisCount = 4; // default for phones
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8, // Helps prevent overflow
          children: _menuCards,
        );
      },
    );

  }

  Widget _buildMenuCard(BuildContext context, {required IconData icon, required String label, String? route}) {
    return GestureDetector(
      onTap: () {
        if (label == "Transfer") {
          _showTransferOptions(context);
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Coming next on our upgrade...\nStart building your credit score to be the first to benefit from the service by transacting more",
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _primaryColor?.withOpacity(0.1),
            child: Icon(icon, size: 28, color: _primaryColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showTransferOptions(BuildContext context) {
    final showWallet = _menuItems['display-wallet-transfer-menu'] == true;
    final showBank = _menuItems['display-bank-transfer-menu'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose Transfer Option", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (showWallet)
                ListTile(
                  leading: Icon(Icons.account_balance_wallet, color: _secondaryColor),
                  title: const Text("Wallet to Wallet"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.transfer);
                  },
                ),
              if (showBank)
                ListTile(
                  leading: Icon(Icons.account_balance, color: _secondaryColor),
                  title: const Text("Wallet to Bank"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.bank_transfer);
                  },
                ),
              if (!showWallet && !showBank)
                const Text("No transfer options available."),
            ],
          ),
        );
      },
    );
  }
}

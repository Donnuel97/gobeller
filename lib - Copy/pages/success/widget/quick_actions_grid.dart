import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:gobeller/controller/CacVerificationController.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionsGrid extends StatefulWidget {
  const QuickActionsGrid({super.key});

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid> {
  final CacVerificationController _CacVerificationController = CacVerificationController();
  Color _primaryColor = const Color(0xFF2BBBA4);
  Color _secondaryColor = const Color(0xFFFF9800);
  Map<String, dynamic> _menuItems = {};
  List<Widget> _menuCards = [];
  bool _showAllCards = false;

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
      final primaryColorHex = settings['customized-app-primary-color'] ?? '#2BBBA4';
      final secondaryColorHex = settings['customized-app-secondary-color'] ?? '#FF9800';

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }

    if (orgJson != null) {
      final orgData = json.decode(orgJson);
      setState(() {
        _menuItems = {
          ...?orgData['data']?['customized_app_displayable_menu_items'],
          "display-corporate-account-menu": true,
          "display-loan-request-menu": true,
          "display-fix-deposit-menu": false,
          "display-bnpl-menu": true,
        };
      });
    }

    _menuCards = _buildVisibleMenuCards();
    setState(() {});
  }

  Future<void> _handleCorporateNavigation(BuildContext context) async {
    try {
      await _CacVerificationController.fetchWallets();

      final wallets = _CacVerificationController.wallets ?? [];

      final hasCorporate = wallets.any((wallet) =>
      wallet['ownership_type'] == 'corporate-wallet'
      );

      if (hasCorporate) {
        Navigator.pushNamed(context, Routes.dashboard);
      } else {
        Navigator.pushNamed(context, Routes.corporate);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching wallets: $e")),
      );
    }
  }

  List<Widget> _buildVisibleMenuCards() {
    final List<Widget> cards = [];
    int index = 0;

    if (_menuItems['display-wallet-transfer-menu'] == true || _menuItems['display-bank-transfer-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.sync, label: "Transfer", route: Routes.bank_transfer, index: index++));
    }
    if (_menuItems['display-airtime-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.phone_android, label: "Airtime", route: Routes.airtime, index: index++));
    }
    if (_menuItems['display-data-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.wifi, label: "Data", route: Routes.data_purchase, index: index++));
    }
    if (_menuItems['display-cable-tv-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.tv, label: "Cable", route: Routes.cable_tv, index: index++));
    }
    if (_menuItems['display-electricity-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.lightbulb, label: "Electric", route: Routes.electric, index: index++));
    }
    if (_menuItems['display-loan-request-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.money, label: "Loan", route: Routes.loan, index: index++));
    }
    if (_menuItems['display-fix-deposit-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.candlestick_chart, label: "Fix Deposit", route: Routes.fixed, index: index++));
    }
    if (_menuItems['display-bnpl-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.real_estate_agent, label: "BNPL", route: Routes.borrow, index: index++));
    }

    // If we have 7 or more cards, replace the last visible one with "See More"
    if (cards.length >= 7) {
      cards.removeAt(6); // Remove the 7th item
      cards.add(_buildMenuCard(
        context,
        icon: Icons.apps_rounded,
        label: "See More",
        route: Routes.more_menu,
        index: index,
      ));
    }

    return cards;
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? route,
    required int index,
    }) {
    final color = index % 2 == 0 ? _primaryColor : _secondaryColor;
    
    return GestureDetector(
      onTap: () async {
        if (label == "Transfer") {
          _showTransferOptions(context);
        } else if (label == "Corporate Account") {
          try {
            await _CacVerificationController.fetchWallets();
            final wallets = _CacVerificationController.wallets ?? [];

            final hasCorporate = wallets.any((wallet) =>
              wallet['ownership_type'] == 'corporate-wallet'
            );

            if (hasCorporate) {
              Navigator.pushNamed(context, Routes.corporate_account);
            } else {
              Navigator.pushNamed(context, Routes.corporate);
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error fetching wallets: $e")),
            );
          }
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Choose Transfer Type",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (showWallet)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.transfer);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Wallet Transfer",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            if (showWallet && showBank) const SizedBox(height: 10),
            if (showBank)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.bank_transfer);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Bank Transfer",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_menuCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Menu not available, contact support for assistance",
            style: GoogleFonts.poppins(
              color: _primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.8,
      children: _menuCards,
    );
  }
}

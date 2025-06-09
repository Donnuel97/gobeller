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
        };
      });
    }

    final cards = await _buildVisibleMenuCards();
    setState(() {
      _menuCards = cards;
    });
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

  Future<List<Widget>> _buildVisibleMenuCards() async {
    final List<Widget> cards = [];
    int index = 0;

    // Get organization features
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');
    bool isVtuEnabled = false;
    bool isFixedDepositEnabled = false;
    bool isLoanEnabled = false;
    bool isInvestmentEnabled = false;
    bool isBNPLEnabled = false;
    bool isCustomerMgtEnabled = false;

    if (orgJson != null) {
      final orgData = json.decode(orgJson);
      isVtuEnabled = orgData['data']?['organization_subscribed_features']?['vtu-mgt'] ?? false;
      isFixedDepositEnabled = orgData['data']?['organization_subscribed_features']?['fixed-deposit-mgt'] ?? false;
      isLoanEnabled = orgData['data']?['organization_subscribed_features']?['loan-mgt'] ?? false;
      isInvestmentEnabled = orgData['data']?['organization_subscribed_features']?['investment-mgt'] ?? false;
      isBNPLEnabled = orgData['data']?['organization_subscribed_features']?['properties-mgt'] ?? false;
      isCustomerMgtEnabled = orgData['data']?['organization_subscribed_features']?['customers-mgt'] ?? false;
    }
    // Add individual wallet transfer icon


    if (isCustomerMgtEnabled) {
      if (_menuItems['display-wallet-transfer-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.account_balance_wallet_outlined, label: "Wallet transfer", route: Routes.transfer, index: index++));
      }

      // Add individual bank transfer icon
      if (_menuItems['display-bank-transfer-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.swap_horiz, label: "Other bank ", route: Routes.bank_transfer, index: index++));
      }

      if (_menuItems['display-corporate-account-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.business, label: "Corporate", route: Routes.corporate, index: index++));
      }
    }
    // Only show VTU-related menus if vtu-mgt is enabled
    if (isVtuEnabled) {
      if (_menuItems['display-electricity-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.electric_bolt, label: "Electricity", route: Routes.electric, index: index++));
      }
      if (_menuItems['display-airtime-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.phone_android_outlined, label: "Airtime", route: Routes.airtime, index: index++));
      }
      if (_menuItems['display-data-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.wifi, label: "Data", route: Routes.data_purchase, index: index++));
      }
      if (_menuItems['display-cable-tv-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.tv_outlined, label: "Cable Tv", route: Routes.cable_tv, index: index++));
      }
    }

    // Only show loan if enabled
    if (isLoanEnabled) {
      if (_menuItems['display-loan-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.monetization_on_outlined, label: "Loans", route: Routes.loan, index: index++));
      }
    }

    // Only show Investment if enabled
    if (isInvestmentEnabled) {
      if (_menuItems['display-investment-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.account_balance_outlined, label: "Investment", route: Routes.investment, index: index++));
      }
    }

    // Only show BNLP if enabled
    if (isBNPLEnabled) {
      if (_menuItems['display-buy-now-pay-later-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.card_giftcard_outlined, label: "BNPL", route: Routes.borrow, index: index++));
      }
    }


    // Only show fixed deposit menu if fixed-deposit-mgt is enabled
    if (isFixedDepositEnabled) {
      if (_menuItems['display-fixed-deposit-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.account_balance_outlined, label: "fixed deposit", route: Routes.fixed, index: index++));
      }
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
    // Remove the alternating color logic and use only _primaryColor
    return GestureDetector(
      onTap: () async {
        if (label == "Corporate Account") {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
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
              color: _primaryColor, // Changed to always use _primaryColor
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12), // Reduced from 16 to 12
      crossAxisSpacing: 12, // Reduced from 16 to 12
      mainAxisSpacing: 12, // Reduced from 16 to 12
      childAspectRatio: 0.8,
      children: _menuCards,
    );
  }
}
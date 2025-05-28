import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:gobeller/controller/CacVerificationController.dart';

class QuickActionsGrid extends StatefulWidget {
  const QuickActionsGrid({super.key});

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid> {
  final CacVerificationController _CacVerificationController = CacVerificationController();
  Color? _primaryColor;
  Color? _secondaryColor;
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
        "display-loan-request-menu": true,
        "display-fix-deposit-menu": false,
        "display-bnpl-menu": true,
      };
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
    // if (_menuItems['display-corporate-account-menu'] == true) {
    //   cards.add(_buildMenuCard(context, icon: Icons.business_center, label: "Corporate Account", route: Routes.corporate));
    // }
    if (_menuItems['display-loan-request-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.money, label: "Loan", route: Routes.loan));
    }
    if (_menuItems['display-fix-deposit-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.candlestick_chart, label: "Fix Deposit", route: Routes.fixed));
    }
    if (_menuItems['display-bnpl-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.real_estate_agent, label: "BNPL", route: Routes.borrow));
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
        double screenWidth = constraints.maxWidth;
        int crossAxisCount;

        // Determine grid columns based on screen width
        if (screenWidth >= 900) {
          crossAxisCount = 6; // large screens like tablets
        } else if (screenWidth >= 600) {
          crossAxisCount = 5; // medium devices
        } else {
          crossAxisCount = 4; // default for phones
        }

        // Calculate how many items fit in two rows
        final int itemsInTwoRows = crossAxisCount * 2;
        
        // Determine if we need a "Show More" button
        final bool hasMoreItems = _menuCards.length > itemsInTwoRows;
        
        // Get visible cards based on show more state
        final visibleCards = hasMoreItems && !_showAllCards 
          ? _menuCards.sublist(0, itemsInTwoRows)
          : _menuCards;

        return Column(
          children: [
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
              children: visibleCards,
            ),
            if (hasMoreItems) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllCards = !_showAllCards;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _primaryColor ?? Colors.blue),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_showAllCards ? "Show Less" : "Show More"),
                        const SizedBox(width: 4),
                        Icon(
                          _showAllCards ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? route,
  }) {
    return GestureDetector(
      onTap: () async {
        final cacVerificationController = Provider.of<CacVerificationController>(context, listen: false);

        if (label == "Transfer") {
          _showTransferOptions(context);
        } else if (label == "Corporate Account") {
          try {
            await cacVerificationController.fetchWallets();
            final wallets = cacVerificationController.wallets ?? [];

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Choose Transfer Type",
              style: TextStyle(
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
}

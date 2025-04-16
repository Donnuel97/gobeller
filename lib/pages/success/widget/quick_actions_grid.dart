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

  @override
  void initState() {
    super.initState();
    _loadSecondaryColor();
  }

  // Fetch colors from SharedPreferences
  Future<void> _loadSecondaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');  // Using the correct key name for settings

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'] ?? '#171E3B'; // Default fallback color
      final secondaryColorHex = data['customized-app-secondary-color'] ?? '#EB6D00'; // Default fallback color

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: constraints.maxWidth > 400 ? 4 : 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildMenuCard(context, icon: Icons.payments, label: "Transfer", route: Routes.bank_transfer),
            _buildMenuCard(context, icon: Icons.phone_android, label: "Airtime", route: Routes.airtime),
            _buildMenuCard(context, icon: Icons.wifi, label: "Data", route: Routes.data_purchase),
            _buildMenuCard(context, icon: Icons.tv, label: "Cable", route: Routes.cable_tv),
            _buildMenuCard(context, icon: Icons.lightbulb, label: "Electric", route: Routes.electric),
            _buildMenuCard(context, icon: Icons.monetization_on, label: "MoMo", route: Routes.reg_success),
          ],
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
            SnackBar(content: Text("$label feature coming soon!")),
          );
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _primaryColor?.withOpacity(0.1),
            child: Icon(icon, size: 28, color: _primaryColor),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showTransferOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Transfer Option",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: _secondaryColor),
                title: const Text("Wallet to Wallet"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.transfer);
                },
              ),
              ListTile(
                leading: Icon(Icons.account_balance, color: _secondaryColor),
                title: const Text("Wallet to Bank"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.bank_transfer);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

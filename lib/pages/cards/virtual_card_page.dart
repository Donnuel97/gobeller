import 'package:flutter/material.dart';
import 'package:gobeller/pages/success/widget/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:gobeller/controller/cards_controller.dart';
import 'package:gobeller/utils/routes.dart';
import 'widgets/card_info.dart';
import 'widgets/create_card_modal.dart';
import 'widgets/add_money_modal.dart';
import 'widgets/transaction_history.dart';

class VirtualCardPage extends StatefulWidget {
  const VirtualCardPage({super.key});

  @override
  State<VirtualCardPage> createState() => _VirtualCardPageState();
}

class _VirtualCardPageState extends State<VirtualCardPage> {
  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VirtualCardController>(context, listen: false).fetchVirtualCards();
    });
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      setState(() {
        _primaryColor = _hexToColor(data['customized-app-primary-color']);
        _secondaryColor = _hexToColor(data['customized-app-secondary-color']);
      });
    }
  }

  Color _hexToColor(String hex) => Color(int.parse(hex.replaceAll('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<VirtualCardController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Virtual Card")),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.virtualCards.isEmpty
          ? Center(
        child: ElevatedButton.icon(
          onPressed: () => showCreateCardModal(context, controller, _secondaryColor),
          icon: const Icon(Icons.add),
          label: const Text("Create Virtual Card"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _secondaryColor ?? Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80), // leave space for bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CardView(
                card: controller.virtualCards.first,
                primaryColor: _primaryColor,
                secondaryColor: _secondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Center the "Transaction History" text
            Center(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Transaction History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16), // Add space between the title and the history section
            TransactionHistory(cardId: controller.virtualCards.first["id"]),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) Navigator.pushReplacementNamed(context, _getRouteForIndex(index));
        },
      ),
    );
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0: return "/";
      case 1: return "/wallet";
      case 2: return "/virtualCard";
      case 3: return "/profile";
      default: return "/";
    }
  }
}

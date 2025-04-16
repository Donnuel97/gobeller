import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gobeller/controller/profileControllers.dart';
import 'package:gobeller/pages/success/widget/user_info_card.dart';
import 'package:gobeller/pages/success/widget/quick_actions_grid.dart';
import 'package:gobeller/pages/success/widget/transaction_list.dart';
import 'package:gobeller/pages/success/widget/bottom_nav_bar.dart';
import 'package:gobeller/pages/login/login_page.dart'; // Import login page for redirection
import 'package:gobeller/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>?> _userProfileFuture;
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;
  String _welcomeTitle = "Dashboard";
  String _welcomeDescription = "We are here to help you achieve your goals.";

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
    _userProfileFuture = ProfileController.fetchUserProfile();
  }


  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    final orgJson = prefs.getString('organizationData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];
      final logoUrl = data['customized-app-logo-url'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
        _logoUrl = logoUrl;
      });
    }

    if (orgJson != null) {
      final Map<String, dynamic> orgData = json.decode(orgJson);
      final data = orgData['data'] ?? {};

      setState(() {
        _welcomeTitle = "Welcome to ${data['short_name']} ";
        _welcomeDescription = data['description'] ?? _welcomeDescription;
      });
    }
  }
  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Stay on page
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Confirm logout
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: Text(_welcomeTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.headset_mic),
              onPressed: () {
                Navigator.pushNamed(context, Routes.profile);
              },
            ),
          ],
        ),

        body: FutureBuilder<Map<String, dynamic>?>(
          future: _userProfileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || snapshot.data == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              });
              return const Center(child: Text("Redirecting to login..."));
            }

            var userProfile = snapshot.data!;
            String fullName = userProfile["first_name"] ?? "User";
            String accountNumber = userProfile["wallet_number"] ?? "";
            String balance = userProfile["wallet_balance"]?.toString() ?? "0";

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UserInfoCard(
                      username: fullName,
                      accountNumber: accountNumber,
                      balance: balance,
                      bankName: userProfile["bank_name"],
                    ),
                    const SizedBox(height: 15),
                    const QuickActionsGrid(),
                    const SizedBox(height: 20),
                    const TransactionList(),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:gobeller/controller/profileControllers.dart';
import 'package:gobeller/pages/success/widget/user_info_card.dart';
import 'package:gobeller/pages/success/widget/quick_actions_grid.dart';
import 'package:gobeller/pages/success/widget/transaction_list.dart';
import 'package:gobeller/pages/success/widget/bottom_nav_bar.dart';
import 'package:gobeller/pages/login/login_page.dart'; // Import login page for redirection

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>?> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = ProfileController.fetchUserProfile();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text("Dashboard")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            // Redirect to login page if no authentication token is found
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
                children: [
                  UserInfoCard(
                    username: fullName,
                    accountNumber: accountNumber,
                    balance: balance,
                    bankName: userProfile["bank_name"], // Pass bank name here
                  ),

                  const SizedBox(height: 20),
                  const QuickActionsGrid(),
                  const SizedBox(height: 30),

                  // ✅ Fixed: Removed `transactions: []`
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
    );
  }
}

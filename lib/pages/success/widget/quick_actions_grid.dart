import 'package:flutter/material.dart';
import 'package:gobeller/utils/routes.dart'; // Import Routes

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

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
            _buildMenuCard(context, icon: Icons.monetization_on, label: "MoMo"),
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
            backgroundColor: const Color(0xFFEB6D00).withOpacity(0.1), // Light orange background
            child: Icon(icon, size: 28, color: const Color(0xFFEB6D00)), // Icon color set to #eb6d00
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Function to show modal bottom sheet for Transfer options
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
                leading: const Icon(Icons.account_balance_wallet, color: Color(0xFFEB6D00)), // Icon color updated
                title: const Text("Wallet to Wallet"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.transfer);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Color(0xFFEB6D00)), // Icon color updated
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

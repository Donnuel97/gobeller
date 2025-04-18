import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/routes.dart';

class UserInfoCard extends StatefulWidget {
  final String username;
  final String accountNumber;
  final String balance;
  final String bankName;

  const UserInfoCard({
    super.key,
    required this.username,
    required this.accountNumber,
    required this.balance,
    required this.bankName,
  });

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  bool _isBalanceHidden = true;
  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');  // Using the correct key name for settings

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'] ; // Default fallback color
      final secondaryColorHex = data['customized-app-secondary-color'] ; // Default fallback color

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if wallet details are missing or invalid
    bool isWalletMissing = widget.balance.isEmpty ||
        widget.balance == "0.00" ||
        widget.accountNumber.isEmpty ||
        widget.accountNumber == "N/A" ||
        widget.bankName.isEmpty ||
        widget.bankName == "N/A";

    String formattedBalance = NumberFormat("#,##0.00")
        .format(double.tryParse(widget.balance) ?? 0.00);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, ${widget.username} 👋",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),

          // Wallet Info or Create Wallet
          if (isWalletMissing)
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text("Create Wallet"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryColor ?? Colors.deepPurple,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.wallet);
                },
              ),
            )

          else ...[
            Row(
              children: [
                Text(
                  "Acct: ${widget.accountNumber}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.accountNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Account number copied!")),
                    );
                  },
                  child: const Icon(Icons.copy, color: Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              widget.bankName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBalanceHidden ? "****" : "₦$formattedBalance",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: Icon(
                    _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isBalanceHidden = !_isBalanceHidden;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}

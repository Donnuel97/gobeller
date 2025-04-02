import 'package:flutter/material.dart';
import 'widget/wallet_list.dart';

class CryptoWalletPage extends StatelessWidget {
  const CryptoWalletPage({super.key});

  final List<Map<String, dynamic>> wallets = const [
    {"name": "Bitcoin Wallet", "balance": 0.025, "currency": "BTC"},
    {"name": "Ethereum Wallet", "balance": 1.2, "currency": "ETH"},
    {"name": "USDT Wallet", "balance": 500.00, "currency": "USDT"},
  ];

  void _createNewWallet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Crypto Wallet creation feature coming soon!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crypto Wallets")),
      body: Column(
        children: [
          Expanded(child: WalletList(wallets: wallets)), // List of wallets
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, // Full width
              height: 50, // Consistent height
              child: ElevatedButton(
                onPressed: () => _createNewWallet(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Pill shape
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Create New Crypto Wallet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

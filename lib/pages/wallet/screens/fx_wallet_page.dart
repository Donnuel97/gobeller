import 'package:flutter/material.dart';
import 'package:gobeller/controller/WalletController.dart';
import 'widget/wallet_list.dart';

class FXWalletPage extends StatefulWidget {
  const FXWalletPage({super.key});

  @override
  _FXWalletPageState createState() => _FXWalletPageState();
}

class _FXWalletPageState extends State<FXWalletPage> {
  List<Map<String, dynamic>> wallets = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final walletData = await WalletController.fetchWallets();

      if (walletData.isNotEmpty) {
        setState(() {
          wallets = [
            {
              "name": "Main Wallet",
              "wallet_number": walletData["wallet_number"],
              "balance": double.tryParse(walletData["balance"]!) ?? 0.0,
              "currency": "₦", // Assuming Naira from response
            }
          ];
        });
      } else {
        setState(() => hasError = true);
      }
    } catch (e) {
      setState(() => hasError = true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _createNewWallet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("FX Wallet creation feature coming soon!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FX Wallets")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Loading indicator
          : hasError
          ? const Center(child: Text("Failed to load wallets. Try again."))
          : Column(
        children: [
          Expanded(child: WalletList(wallets: wallets)), // Render dynamic data
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _createNewWallet(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Create New FX Wallet",
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

import 'package:flutter/material.dart';
import 'screens/fx_wallet_page.dart';
import 'screens/crypto_wallet_page.dart';
import 'package:gobeller/pages/success/widget/bottom_nav_bar.dart';
import 'package:gobeller/utils/routes.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallets"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "FX Wallets"), Tab(text: "Crypto Wallets")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [FXWalletPage(), CryptoWalletPage()],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, Routes.initial);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/cards');
          }
        },
      ),

    );
  }
}

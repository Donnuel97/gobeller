import 'package:flutter/material.dart';
import 'package:gobeller/pages/success/dashboard_page.dart';
import 'package:gobeller/pages/wallet/wallet_page.dart';
import 'package:gobeller/pages/borrowers/borrowers.dart';
import 'package:gobeller/pages/cards/virtual_card_page.dart';
import 'package:gobeller/pages/profile/profile_page.dart';
import 'bottom_nav.dart';

class BaseLayout extends StatefulWidget {
  final int initialIndex;

  const BaseLayout({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  late int _currentIndex;
  final List<Widget> _pages = [
    const DashboardPage(),
    const WalletPage(),
    const PropertyListPage(),
    const VirtualCardPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),
        bottomNavigationBar: BottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
} 
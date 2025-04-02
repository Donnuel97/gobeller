import 'package:flutter/material.dart';
import 'package:gobeller/utils/routes.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  void _handleNavigation(int index) {
    if (index == 1) { // Wallet Tab Clicked
      Navigator.pushNamed(context, Routes.wallet);
    } else if (index == 0) { // Profile Tab Clicked
      Navigator.pushNamed(context, Routes.dashboard);
    } else if (index == 3) { // dashboard Tab Clicked
      Navigator.pushNamed(context, Routes.profile);
    } else if (index == 2) { // Cards Tab Clicked
      Navigator.pushNamed(context, Routes.virtualCard);
    } else {
      widget.onTabSelected(index); // Update state for Home & Cards tab
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: widget.currentIndex,
      onDestinationSelected: _handleNavigation,
      destinations: const [
        NavigationDestination(
          selectedIcon: Icon(Icons.home_rounded),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'Wallets',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.credit_card),
          icon: Icon(Icons.credit_card_outlined),
          label: 'Cards',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.account_circle_rounded),
          icon: Icon(Icons.account_circle_outlined),
          label: 'Profile',
        ),
      ],
    );
  }
}

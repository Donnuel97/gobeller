import 'package:flutter/material.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Color _primaryColor = Colors.blue; // Default fallback color

  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final hexColor = prefs.getString('customized-app-primary-color');
    if (hexColor != null && hexColor.startsWith('#')) {
      setState(() {
        _primaryColor = Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
      });
    }
  }

  void _handleNavigation(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, Routes.wallet);
    } else if (index == 0) {
      Navigator.pushNamed(context, Routes.dashboard);
    } else if (index == 3) {
      Navigator.pushNamed(context, Routes.profile);
    } else if (index == 2) {
      Navigator.pushNamed(context, Routes.virtualCard);
    } else {
      widget.onTabSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: widget.currentIndex,
      onDestinationSelected: _handleNavigation,
      destinations: [
        NavigationDestination(
          selectedIcon: Icon(Icons.home_rounded, color: _primaryColor),
          icon: const Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: _primaryColor),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: 'Wallets',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.credit_card, color: _primaryColor),
          icon: const Icon(Icons.credit_card_outlined),
          label: 'Cards',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.account_circle_rounded, color: _primaryColor),
          icon: const Icon(Icons.account_circle_outlined),
          label: 'Profile',
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../controller/user_controller.dart';
import '../../../utils/routes.dart';
// import '../../../layouts/base_layout.dart';

class UserInfoCard extends StatefulWidget {
  final String username;
  final String accountNumber;
  final String balance;
  final String bankName;
  final bool hasWallet;

  const UserInfoCard({
    super.key,
    required this.username,
    required this.accountNumber,
    required this.balance,
    required this.bankName,
    required this.hasWallet,
  });

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> with SingleTickerProviderStateMixin {
  bool _isBalanceHidden = true;
  Color? _primaryColor;
  Color? _secondaryColor;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _mounted = true;

  final _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadThemeColors();
  }

  void _initializeAnimations() {
    if (!mounted) return;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    if (mounted) {
      _animationController.forward();
    }
  }

  Future<void> _loadThemeColors() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('appSettingsData');

      if (!mounted) return;

      if (settingsJson != null) {
        final Map<String, dynamic> settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        final primaryColorHex = data['customized-app-primary-color'];
        final secondaryColorHex = data['customized-app-secondary-color'];

        if (mounted) {
          setState(() {
            _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
            _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading theme colors: $e');
    }
  }

  Future<bool> _isTokenValid() async {
    if (!mounted) return false;
    
    try {
      String? token = await UserController.getToken();
      if (!mounted) return false;
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking token validity: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _mounted = false;
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _mounted = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    String formattedBalance = NumberFormat("#,##0.00")
        .format(double.tryParse(widget.balance) ?? 0.00);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _secondaryColor ?? Colors.blue,
                (_secondaryColor ?? Colors.blue).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (_secondaryColor ?? Colors.blue).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome back,",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (!widget.hasWallet)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                              label: const Text("Create Wallet"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _primaryColor ?? Colors.blue,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                bool isValid = await _isTokenValid();
                                if (isValid) {
                                  Navigator.pushNamed(context, Routes.wallet);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Session expired. Please log in again."),
                                    ),
                                  );
                                  Navigator.pushReplacementNamed(context, Routes.dashboard);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (widget.hasWallet) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Available Balance",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _isBalanceHidden ? "****" : "₦$formattedBalance",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.white70,
                                        size: 20,
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.accountNumber,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: widget.accountNumber));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Account number copied!"),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: const Icon(
                                          Icons.copy,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.bankName,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

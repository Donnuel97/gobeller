import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/const/const_ui.dart';
import 'package:gobeller/controller/login_controller.dart'; // ✅ Imported
import 'package:gobeller/pages/success/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/biometric_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../controller/create_wallet_controller.dart';
import '../../controller/kyc_controller.dart';
import '../../pages/navigation/base_layout.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController _loginController = LoginController(); // ✅ Added
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isLoading = false;
  bool _hideUsernameField = false;
  bool _isBiometricLoading = false;

  String? _storedUsername;
  String? _displayName;
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    _checkStoredUsername();
    _autoBiometricLogin(); // <- Call here
  }
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _autoBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final hasUsername = prefs.getString('saved_username') != null;
    final hasPassword = prefs.getString('saved_password') != null;

    if (hasUsername && hasPassword) {
      setState(() => _isBiometricLoading = true);
      _showLoadingDialog();

      final didAuth = await BiometricHelper.authenticate();

      if (didAuth && mounted) {
        final result = await _loginController.loginUser(useStoredCredentials: true);

        _hideLoadingDialog();

        if (!mounted) return;

        if (result['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BaseLayout(initialIndex: 0)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Biometric login failed')),
          );
        }
      } else {
        _hideLoadingDialog();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication failed')),
          );
        }
      }

      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }





  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        setState(() {
          final primaryColorHex = data['customized-app-primary-color'];
          final secondaryColorHex = data['customized-app-secondary-color'];

          _primaryColor = primaryColorHex != null
              ? Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blue;

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blueAccent;

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {}
    }
  }

  Future<void> _checkStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final test = prefs.getString('first_name');
    final userData = prefs.getString('user');

    if (savedUsername != null && savedUsername.isNotEmpty) {
      String? firstName;

      if (userData != null) {
        final Map<String, dynamic> userMap = json.decode(userData);
        firstName = userMap['first_name'];
      }

      setState(() {
        _storedUsername = savedUsername;
        _displayName = test ;
        _usernameController.text = savedUsername;
        _hideUsernameField = true;
      });
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final username = _storedUsername ?? _usernameController.text.trim();
    final password = _passwordController.text;

    final result = await _loginController.loginUser(
      username: username,
      password: password,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', username);

      // ✅ Fetch and cache KYC
      final kycData = await KycVerificationController.fetchKycVerifications();
      if (kycData != null) {
        debugPrint("✅ KYC data successfully fetched and cached.");
      }

      // ✅ Fetch and cache currencies
      await CurrencyController.fetchCurrencies();

      // ✅ Fetch and cache banks
      final banks = await CurrencyController.fetchBanks();
      await prefs.setString('cached_banks', json.encode(banks));
      debugPrint("✅ Banks saved to SharedPreferences.");

      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BaseLayout(initialIndex: 0)),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login failed')),
      );
    }

    setState(() => _isLoading = false);
  }




  Future<void> _switchAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('first_name');

    setState(() {
      _storedUsername = null;
      _displayName = null;
      _usernameController.clear();
      _hideUsernameField = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: ConstUI.kMainPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_logoUrl != null)
                  CachedNetworkImage(
                    imageUrl: _logoUrl!,
                    width: 128,
                    height: 128,
                    fit: BoxFit.contain,
                    httpHeaders: const {
                      'User-Agent': 'Flutter App',
                      'Accept': 'image/png, image/jpeg, image/jpg, image/gif, image/webp, image/*',
                    },
                    placeholder: (context, url) => SizedBox(
                      width: 128,
                      height: 128,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: null,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print('Failed to load image: $url');
                      print('Error: $error');
                      return const Center(
                        child: Text(
                          'Getting Data...',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),

                Text(
                  _hideUsernameField
                      ? "Welcome back, ${_displayName ?? ''}"
                      : "Log in to your account",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (!_hideUsernameField)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                if (!_hideUsernameField) const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _isPasswordObscured = !_isPasswordObscured);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login"),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Biometric login button (conditionally shown)
                    if (_storedUsername != null)
                      Center(
                        child: IconButton(
                          icon: const Icon(Icons.fingerprint, size: 40, color: Colors.blueGrey),
                          onPressed: _isBiometricLoading
                              ? null
                              : () async {
                            setState(() => _isBiometricLoading = true);
                            _showLoadingDialog();

                            final didAuth = await BiometricHelper.authenticate();

                            if (didAuth) {
                              final result = await _loginController.loginUser(useStoredCredentials: true);

                              if (!mounted) return;

                              if (result['success'] == true) {
                                // ✅ Fetch and save KYC verifications
                                final kycData = await KycVerificationController.fetchKycVerifications();
                                if (kycData != null) {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('cached_kyc_data', json.encode(kycData));
                                  debugPrint("✅ Biometric: KYC data cached successfully.");
                                } else {
                                  debugPrint("⚠️ Biometric: Failed to fetch or cache KYC data.");
                                }

                                _hideLoadingDialog();

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BaseLayout(initialIndex: 0)),
                                );
                              } else {
                                _hideLoadingDialog();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message'] ?? 'Biometric login failed')),
                                );
                              }
                            } else {
                              _hideLoadingDialog();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fingerprint authentication failed')),
                              );
                            }

                            if (mounted) setState(() => _isBiometricLoading = false);
                          },
                        ),
                      ),


                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: const Text("Don't have an account? Register"),
                    ),
                  ],
                ),


                if (_hideUsernameField)
                  TextButton(
                    onPressed: _switchAccount,
                    child: const Text(
                      "Switch Account",
                      style: TextStyle(color: Colors.black),
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

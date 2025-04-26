import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/const/const_ui.dart';
import 'package:gobeller/controller/login_controller.dart'; // ✅ Imported
import 'package:gobeller/pages/success/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
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
                _logoUrl != null
                    ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      _logoUrl!,
                      width: 128,
                      height: 128,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported,
                            size: 128, color: Colors.grey);
                      },
                    ),
                  ],
                )
                    : const Icon(Icons.image, size: 128, color: Colors.grey),
                const SizedBox(height: 16),

                Text(
                  _hideUsernameField
                      ? "Welcome back, ${ _displayName}"
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
                        setState(() =>
                        _isPasswordObscured = !_isPasswordObscured);
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

                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: const Text("Don’t have an account? Register"),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/const/const_ui.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:gobeller/controller/organization_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _hasFetched = false;
  bool _hasRetried = false;

  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  // Dynamic content from organization data
  String _welcomeTitle = "Welcome";
  String _welcomeDescription = "We are here to help you achieve your goals.";

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    final orgJson = prefs.getString('organizationData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];
      final logoUrl = data['customized-app-logo-url'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
        _logoUrl = logoUrl;
      });
    }

    if (orgJson != null) {
      final Map<String, dynamic> orgData = json.decode(orgJson);
      final data = orgData['data'] ?? {};

      setState(() {
        _welcomeTitle = "Welcome to ${data['short_name']} App";
        _welcomeDescription = data['description'] ?? _welcomeDescription;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasFetched) {
      final orgController = Provider.of<OrganizationController>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await orgController.fetchOrganizationData();

        if ((orgController.organizationData == null || orgController.appSettingsData == null) && !_hasRetried) {
          _hasRetried = true;
          Future.delayed(const Duration(seconds: 3), () async {
            debugPrint("🔁 Retrying organization data fetch...");
            await orgController.fetchOrganizationData();
          });
        }
      });

      _hasFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationController>(
      builder: (context, orgController, child) {
        final isLoading = orgController.isLoading;
        final hasError = orgController.organizationData == null || orgController.appSettingsData == null;

        return Scaffold(
          body: SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? _buildErrorState(context)
                : _buildMainContent(context),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: ConstUI.kMainPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _logoUrl != null
                    ? Image.network(
                  _logoUrl!,
                  width: 188,
                  height: 188,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 188,
                      width: 188,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                  },
                )
                    : const Icon(Icons.image, size: 100, color: Colors.grey),
                const SizedBox(height: 32),
                Text(
                  _welcomeTitle,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _welcomeDescription,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: ConstUI.kMainPadding,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: const Text("Login"),
                  onPressed: () => Navigator.pushNamed(context, Routes.login),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(_primaryColor),
                  ),
                  child: const Text("Register"),
                  onPressed: () => Navigator.pushNamed(context, Routes.register),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final orgController = Provider.of<OrganizationController>(context, listen: false);

    return Padding(
      padding: ConstUI.kMainPadding,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Unable to load app settings.\nPlease check your internet and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              onPressed: () async {
                await orgController.fetchOrganizationData();
              },
            ),
          ],
        ),
      ),
    );
  }
}

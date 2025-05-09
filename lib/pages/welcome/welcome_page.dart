import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset("assets/videos/welcome_bg.mp4")
      ..initialize().then((_) {
        setState(() {});
        _videoController!.setLooping(true);
        _videoController!.setVolume(0);
        _videoController!.play();
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasFetched) {
      final orgController = Provider.of<OrganizationController>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await orgController.loadCachedData();
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

        final settings = orgController.appSettingsData?['data'] ?? {};
        final orgData = orgController.organizationData?['data'] ?? {};

        final primaryColorHex = settings['customized-app-primary-color'] ?? '#6200EE';
        final tertiaryColorHex = settings['customized-app-tertiary-color'] ?? '#000000';
        final logoUrl = settings['customized-app-logo-url'];
        final welcomeTitle = "Welcome to ${orgData['short_name'] ?? 'Our'} ";
        final welcomeDescription = orgData['description'] ?? "We are here to help you achieve your goals.";

        final primaryColor = parseColor(primaryColorHex, fallbackHex: '#6200EE');
        final tertiaryColor = parseColor(tertiaryColorHex, fallbackHex: '#000000');

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background Video
              if (_videoController != null && _videoController!.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              else
                Container(color: Colors.black),

              // Dark overlay with tertiary color and fade animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                color: tertiaryColor.withOpacity(0.8),
              ),

              // Content
              SafeArea(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : hasError
                    ? _buildErrorState(context)
                    : _buildMainContent(context, logoUrl, welcomeTitle, welcomeDescription, primaryColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, String? logoUrl, String welcomeTitle, String welcomeDescription, Color primaryColor) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: ConstUI.kMainPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (logoUrl != null)
                  Image.network(
                    logoUrl,
                    width: 128,
                    height: 128,
                    fit: BoxFit.contain,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return SizedBox(
                          width: 128,
                          height: 128,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          ),
                        );
                      }
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Getting Data...',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 32),
                Text(
                  welcomeTitle,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  welcomeDescription,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.black,
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,

                    side: const BorderSide(color: Colors.black),
                  ),
                  child: const Text("Login"),
                  onPressed: () => Navigator.pushNamed(context, Routes.login),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(primaryColor),
                  ),
                  child: const Text("Register"),
                  onPressed: () => Navigator.pushNamed(context, Routes.register),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
              style: TextStyle(fontSize: 16, color: Colors.white),
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

  // Helper to parse color safely
  Color parseColor(String hexColor, {String fallbackHex = '#000000'}) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (_) {
      return Color(int.parse(fallbackHex.replaceAll('#', '0xFF')));
    }
  }
}

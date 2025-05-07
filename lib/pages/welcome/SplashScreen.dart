import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/organization_controller.dart';
import 'welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final List<String> _images = [
    'assets/Lumi/bg1.png',
    'assets/Lumi/bg2.png',
    'assets/Lumi/bg3.png',
  ];

  int _currentIndex = 0;
  bool _hasRetried = false;
  late Timer _carouselTimer;

  late AnimationController _logoController;
  late Animation<double> _logoFadeIn;

  late AnimationController _textController;
  late Animation<Offset> _textSlideIn;

  @override
  void initState() {
    super.initState();
    _startCarousel();

    // Logo fade-in animation
    _logoController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _logoFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    ));

    // Text slide-in animation
    _textController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _textSlideIn = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logoController.forward();
      Future.delayed(const Duration(milliseconds: 1000), () {
        _textController.forward();
      });
      _loadAppData();
    });
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _images.length;
      });
    });
  }

  Future<void> _loadAppData() async {
    final orgController = Provider.of<OrganizationController>(context, listen: false);
    await orgController.loadCachedData();
    await orgController.fetchOrganizationData();

    if ((orgController.organizationData == null || orgController.appSettingsData == null) && !_hasRetried) {
      _hasRetried = true;
      await Future.delayed(const Duration(seconds: 2));
      await orgController.fetchOrganizationData();
    }

    await Future.delayed(const Duration(seconds: 45));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    }
  }

  Widget _floatingCoverImage(String imagePath) {
    final random = Random();
    final dx = (random.nextDouble() * 40) - 20;
    final dy = (random.nextDouble() * 40) - 20;

    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: Offset.zero, end: Offset(dx, dy)),
      duration: const Duration(seconds: 6),
      curve: Curves.easeInOut,
      builder: (context, Offset offset, child) {
        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
      child: SizedBox.expand(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.orange,
        child: Stack(
          children: [
            ..._images.asMap().entries.map((entry) {
              int index = entry.key;
              String imagePath = entry.value;

              return AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: _currentIndex == index ? 1.0 : 0.0,
                curve: Curves.easeInOut,
                child: _floatingCoverImage(imagePath),
              );
            }),

            // Dark overlay
            Container(
              color: Colors.black.withOpacity(0.8),
            ),

            // Logo and subheading
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFadeIn,
                    child: Image.asset(
                      'assets/Lumi/logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _textSlideIn,
                    child: const Text(
                      "We are here to help you achieve your goals",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

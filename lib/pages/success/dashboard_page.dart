import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gobeller/controller/profileControllers.dart';
import 'package:gobeller/pages/success/widget/user_info_card.dart';
import 'package:gobeller/pages/success/widget/quick_actions_grid.dart';
import 'package:gobeller/pages/success/widget/transaction_list.dart';
import 'package:gobeller/pages/success/widget/bottom_nav_bar.dart';
import 'package:gobeller/pages/login/login_page.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>?> _userProfileFuture;

  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;

  String? _logoUrl;
  String _welcomeTitle = "Dashboard";
  String _welcomeDescription = "We are here to help you achieve your goals.";

  List<Map<String, dynamic>> _ads = [];

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
    _userProfileFuture = ProfileController.fetchUserProfile().then((profile) {
      _loadAdsFromPrefs();
      return profile;
    });
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
      final tertiaryColorHex = data['customized-app-tertiary-color'];
      final logoUrl = data['customized-app-logo-url'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
        _tertiaryColor = tertiaryColorHex != null
            ? Color(int.parse(tertiaryColorHex.replaceAll('#', '0xFF')))
            : Colors.grey[200];
        _logoUrl = logoUrl;
      });
    }

    if (orgJson != null) {
      final Map<String, dynamic> orgData = json.decode(orgJson);
      final data = orgData['data'] ?? {};

      setState(() {
        _welcomeTitle = "Welcome to ${data['short_name']} ";
        _welcomeDescription = data['description'] ?? _welcomeDescription;
      });
    }
  }

  Future<void> _loadAdsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString('userProfileRaw');

    if (rawJson != null) {
      final profileData = json.decode(rawJson);
      final adsMap = profileData['ads'] as Map<String, dynamic>?;

      if (adsMap != null) {
        final adsList = adsMap.entries.map((entry) {
          final ad = entry.value;
          final bannerUrl = ad['banner_url'];

          // Debug the banner_url
          debugPrint("🖼️ Loaded ad banner_url: $bannerUrl");

          return {
            'subject': ad['subject'],
            'content': ad['content'],
            'banner_url': bannerUrl,
            'content_redirect_url': ad['content_redirect_url'],
          };
        }).toList();

        setState(() {
          _ads = adsList;
        });
      } else {
        debugPrint("📭 No ads found in profile data.");
      }
    } else {
      debugPrint("⚠️ userProfileRaw not found in SharedPreferences.");
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    // Logic to log out the user (e.g., clear user session, navigate to login)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _tertiaryColor ?? Colors.grey[200],
      appBar: AppBar(
        title: Text(_welcomeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic),
            onPressed: () {
              Navigator.pushNamed(context, Routes.profile);
            },
          ),
          const SizedBox(width: 16), // Adds space between the icons
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
          const SizedBox(width: 8), // Optional: padding at the end of actions
        ],

      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            });
            return const Center(child: Text("Redirecting to login..."));
          }

          var userProfile = snapshot.data!;
          String fullName = userProfile["first_name"] ?? "User";
          String accountNumber = userProfile["wallet_number"] ?? "";
          String balance = userProfile["wallet_balance"]?.toString() ?? "0";
          String bankName = userProfile["bank_name"] ?? "N/A";

          bool hasWallet = balance.isNotEmpty &&
              balance != "0.00" &&
              accountNumber.isNotEmpty &&
              accountNumber != "N/A" &&
              bankName.isNotEmpty &&
              bankName != "N/A";

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UserInfoCard(
                    username: fullName,
                    accountNumber: accountNumber,
                    balance: balance,
                    bankName: bankName,
                    hasWallet: hasWallet,
                  ),
                  const SizedBox(height: 15),
                  const QuickActionsGrid(),
                  const SizedBox(height: 20),
                  AdCarousel(ads: _ads),
                  const SizedBox(height: 20),
                  const TransactionList(),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class AdCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> ads;

  const AdCarousel({super.key, required this.ads});

  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<AdCarousel> {
  final PageController _controller = PageController(viewportFraction: 1.0);  // Full-width PageView
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_controller.hasClients && widget.ads.isNotEmpty) {
        int nextPage = (_currentIndex + 1) % widget.ads.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentIndex = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 250,  // Increased height for full-width display
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.ads.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final ad = widget.ads[index];
              return GestureDetector(
                onTap: () {
                  final url = ad['content_redirect_url'];
                  debugPrint("🔗 Redirect to: $url");
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ad['banner_url'],
                          width: MediaQuery.of(context).size.width,  // Full width image
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ad['subject'] ?? 'Ad Title',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ad['content'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.ads.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentIndex == index ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentIndex == index ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

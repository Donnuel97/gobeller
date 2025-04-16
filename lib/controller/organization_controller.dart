import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class OrganizationController extends ChangeNotifier {
  Map<String, dynamic>? organizationData;
  Map<String, dynamic>? appSettingsData;
  bool isLoading = false;

  String? appId;

  OrganizationController();

  /// Fetch Organization Data and save to SharedPreferences
  Future<void> fetchOrganizationData() async {
    isLoading = true;
    notifyListeners();

    const String url = 'https://app.gobeller.com/api/v1/organizations/sddtif';
// beller, wba, sddtif
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        organizationData = jsonDecode(response.body);
        debugPrint("✅ Organization Data: ${jsonEncode(organizationData)}");

        appId = organizationData?['data']['id'];

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('organizationData', jsonEncode(organizationData));

        if (appId != null) {
          prefs.setString('appId', appId!);
        }

        // Fetch App Settings
        await fetchAppSettings();
      } else {
        debugPrint("❌ Failed to load organization. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching organization: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// Fetch App Settings and save to SharedPreferences
  Future<void> fetchAppSettings() async {
    if (appId == null) {
      debugPrint("❌ AppID is null. Cannot fetch settings.");
      return;
    }

    isLoading = true;
    notifyListeners();

    const String url = 'https://app.gobeller.com/api/v1/customized-app-api/public-app/settings';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'AppID': appId!,
        },
      );

      if (response.statusCode == 200) {
        appSettingsData = jsonDecode(response.body);
        debugPrint("✅ App Settings Data: ${jsonEncode(appSettingsData)}");

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('appSettingsData', jsonEncode(appSettingsData));

        // Extract the icon URL from app settings
        String? iconUrl = appSettingsData?['data']['iconUrl'];

        if (iconUrl != null) {
          await downloadAndSaveIcon(iconUrl);
        }
      } else {
        debugPrint("❌ Failed to load settings. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching app settings: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// Download and save the icon locally
  Future<void> downloadAndSaveIcon(String iconUrl) async {
    try {
      final response = await http.get(Uri.parse(iconUrl));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/app_icon.png';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        debugPrint("✅ Icon saved to: $filePath");

        // Save the icon path to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('appIconPath', filePath);

        // Notify UI to update icon
        setAppIcon(filePath);
      } else {
        debugPrint("❌ Failed to download icon. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error downloading icon: $e");
    }
  }

  /// Set the app icon path to be used in the UI
  Future<void> setAppIcon(String filePath) async {
    // You can now use this file path to show the icon in the app UI
    // Update your UI logic accordingly to display the downloaded icon
    notifyListeners();
  }

  /// Load cached data from SharedPreferences (optional)
  Future<void> loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');
    final settingsJson = prefs.getString('appSettingsData');
    final iconPath = prefs.getString('appIconPath');

    if (orgJson != null) organizationData = jsonDecode(orgJson);
    if (settingsJson != null) appSettingsData = jsonDecode(settingsJson);
    if (iconPath != null) {
      setAppIcon(iconPath);
    }

    notifyListeners();
  }
}

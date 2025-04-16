import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/api_service.dart';

class VirtualCardController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _virtualCards = [];
  List<Map<String, dynamic>> get virtualCards => _virtualCards;

  /// Fetches all virtual cards
  Future<void> fetchVirtualCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No auth token found.");
        _virtualCards = [];
        return;
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      const String endpoint = "/card-mgt/cards/virtual/list?page=1&items_per_page=20";
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);

      debugPrint("🔹 Virtual Cards API Response: $response");

      if (response["status"] == true &&
          response["data"] != null &&
          response["data"]["data"] != null) {
        _virtualCards = List<Map<String, dynamic>>.from(response["data"]["data"]);
      } else {
        debugPrint("⚠️ Failed to fetch virtual cards: ${response["message"]}");
        _virtualCards = [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching virtual cards: $e");
      _virtualCards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new virtual card
  Future<String> createVirtualCard({required String cardPin}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return "Authentication token missing.";
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      const String endpoint = "/card-mgt/cards/virtual/create";
      final Map<String, dynamic> body = {
        "card_pin": cardPin,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("🆕 Create Card Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards(); // Refresh the list after creation
        return "Virtual card created successfully.";
      } else {
        return response["message"] ?? "Failed to create card.";
      }
    } catch (e) {
      debugPrint("❌ Error creating virtual card: $e");
      return "An error occurred while creating the card.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

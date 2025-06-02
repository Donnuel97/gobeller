import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletController {
  static Future<Map<String, dynamic>> fetchWallets({int retryCount = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return {};
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
        'Content-Type': 'application/json',
      };

      final response = await ApiService.getRequest(
        "/customers/wallets",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Raw Wallets API Response: $response");

      if (response["status"] == true) {
        dynamic data = response["data"];

        // Handle if it's a JSON-encoded string
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            debugPrint("❌ Failed to decode wallet data: $e");
            return {};
          }
        }

        // Pass the full list of wallets directly, no reformatting
        if (data is List) {
          return {'data': data};
        }

        // Handle nested "data" key (optional, if API wraps again)
        if (data is Map && data.containsKey("data") && data["data"] is List) {
          return {'data': data["data"]};
        }

        debugPrint("❌ Unexpected data format: $data");
        return {};
      } else {
        debugPrint("❌ API Error: ${response["message"]}");

        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("🔁 401 Unauthorized - Retrying (${retryCount + 1}/3)...");
          return fetchWallets(retryCount: retryCount + 1);
        }

        return {};
      }
    } catch (e) {
      debugPrint("❌ Wallets API Exception: $e");

      if (e.toString().contains('401') && retryCount < 3) {
        debugPrint("🔁 401 Unauthorized in exception - Retrying (${retryCount + 1}/3)...");
        return fetchWallets(retryCount: retryCount + 1);
      }

      return {};
    }
  }
}


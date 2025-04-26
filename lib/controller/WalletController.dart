import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletController {
  // Fetch wallets from the API
  static Future<Map<String, dynamic>> fetchWallets({int retryCount = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return {};
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
      };

      final response = await ApiService.getRequest(
        "/customers/wallets",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Wallets API Response: $response");

      if (response["status"] == true) {
        // Access the 'data' -> 'data' structure to get the wallet list
        List<dynamic> walletList = response["data"]["data"];

        if (walletList.isNotEmpty) {
          return {
            'data': walletList,  // Return the entire wallet list here
          };
        } else {
          debugPrint("ℹ️ No wallets found.");
          return {};
        }
      } else {
        debugPrint("Error: ${response["message"]}");

        // If a 401 Unauthorized error is encountered, retry the request (limit retries)
        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("401 Unauthorized - Retrying...");
          return fetchWallets(retryCount: retryCount + 1);  // Retry up to 3 times
        }
        return {};
      }
    } catch (e) {
      debugPrint("❌ Wallets API Error: $e");

      // If 401 is encountered in the exception, retry
      if (e.toString().contains('401') && retryCount < 3) {
        debugPrint("401 Unauthorized error in exception - Retrying...");
        return fetchWallets(retryCount: retryCount + 1);  // Retry up to 3 times
      }

      return {};
    }
  }
}

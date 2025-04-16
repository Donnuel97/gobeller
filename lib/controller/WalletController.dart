import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletController {
  // Fetch wallets from the API
  static Future<Map<String, String>> fetchWallets() async {
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
        List<dynamic> walletList = response["data"]["data"];

        if (walletList.isNotEmpty) {
          var walletData = walletList[0];  // Safe access now
          String walletNumber = walletData["wallet_number"];
          String balance = walletData["balance"];

          return {
            'wallet_number': walletNumber,
            'balance': balance,
          };
        } else {
          debugPrint("ℹ️ No wallets found.");
          return {};
        }
      } else {
        debugPrint("Error: ${response["message"]}");
        return {};
      }
    } catch (e) {
      debugPrint("❌ Wallets API Error: $e");
      return {};
    }
  }

}

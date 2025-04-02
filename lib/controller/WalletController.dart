import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletController {
  // Fetch wallets from the API
  static Future<Map<String, String>> fetchWallets() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token'); // Get the stored token

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return {};  // If no token is found, return an empty map
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',  // Include the token in the Authorization header
      };

      final response = await ApiService.getRequest(
        "/customers/wallets?page=1&items_per_page=15",
        extraHeaders: extraHeaders, // Corrected the parameter name to 'extraHeaders'
      );

      debugPrint("🔹 Wallets API Response: $response");

      // Assuming the API returns a response in this structure:
      if (response["status"] == true) {
        // Extract wallet data and return wallet number and balance
        var walletData = response["data"]["data"][0];  // Assuming first wallet in the response
        String walletNumber = walletData["wallet_number"];
        String balance = walletData["balance"];

        return {
          'wallet_number': walletNumber,
          'balance': balance,
        };
      } else {
        debugPrint("Error: ${response["message"]}");
        return {}; // Return an empty map in case of an error
      }
    } catch (e) {
      debugPrint("❌ Wallets API Error: $e");
      return {};  // Return an empty map in case of an error
    }
  }
}

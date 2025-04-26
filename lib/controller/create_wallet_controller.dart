import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CurrencyController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _balance = 0.0;
  double get balance => _balance;

  // Fetch available currencies from the API
  static Future<List<Map<String, dynamic>>> fetchCurrencies({int retryCount = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      final headers = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return [];
      }

      final response = await ApiService.getRequest(
        "/customers/currencies?page=1&items_per_page=15&category=fiat",
        extraHeaders: headers,
      );

      if (response["status"] == false) {
        debugPrint("Error: ${response["message"]}");
        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("401 Unauthorized - Retrying...");
          return fetchCurrencies(retryCount: retryCount + 1);  // Retry up to 3 times
        }
        return [];
      }

      var currencies = response["data"]["data"];
      return List<Map<String, dynamic>>.from(currencies);
    } catch (e) {
      debugPrint("❌ Currencies API Error: $e");
      return [];
    }
  }



  // Fetch available wallet types from the API
  static Future<List<Map<String, dynamic>>> fetchWalletTypes() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token'); // Get the stored token

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return [];  // Return an empty list if no token is found
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',  // Include the token in the Authorization header
      };

      final response = await ApiService.getRequest(
        "/wallet-types?items_per_page=15",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Wallet Types API Response: $response");

      if (response["status"] == true) {
        var walletTypes = response["data"]["data"];
        debugPrint("Available wallet types: $walletTypes");

        return List<Map<String, dynamic>>.from(walletTypes);
      } else {
        debugPrint("Error: ${response["message"]}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Wallet Types API Error: $e");
      return [];
    }
  }

  // Fetch available banks from the API
  static Future<List<Map<String, dynamic>>> fetchBanks() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token'); // Get the stored token

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return [];  // Return an empty list if no token is found
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',  // Include the token in the Authorization header
      };

      // Make API request to the new endpoint /virtual-wallet-banks
      final response = await ApiService.getRequest(
        "/virtual-wallet-banks?items_per_page=15",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Virtual Wallet Banks API Response: $response");

      // Check if the response status is true
      if (response["status"] == true) {
        // Extract the banks data from the nested response
        var banks = response["data"]["data"];

        debugPrint("Available virtual wallet banks: $banks");

        // Return the banks as a list of maps
        return List<Map<String, dynamic>>.from(banks);
      } else {
        // Log and return an empty list if there's an error in the response
        debugPrint("Error: ${response["message"]}");
        return [];
      }
    } catch (e) {
      // Catch and log any errors during the API call
      debugPrint("❌ Virtual Wallet Banks API Error: $e");
      return [];
    }
  }


  static Future<dynamic> createWallet(Map<String, dynamic> body) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No auth token found.");
        throw Exception("Unauthorized: Please login again.");
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'AppID': appId,
      };

      debugPrint("📤 Submitting wallet creation with body: $body");

      final response = await ApiService.postRequest(
        "/customers/wallets",
        body,
        extraHeaders: headers,
      );

      debugPrint("✅ Wallet creation response: $response");

      // Check if status is error and throw with custom message
      if (response is Map<String, dynamic> && response["status"] == "error") {
        throw Exception(response["message"] ?? "An unknown error occurred");
      }

      return response;
    } catch (e) {
      debugPrint("❌ Error creating wallet: $e");

      // Pass back the error to the UI in a way that can be shown nicely
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }


// Create a new wallet
  // Future<void> createNewWallet({
  //   required String accountType,
  //   required String bankId,
  //   required String walletTypeId,
  //   required String currencyId,
  //   required BuildContext context,
  //   }) async {
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final String? token = prefs.getString('auth_token');
  //
  //     if (token == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("❌ Authentication required. Please log in again.")),
  //       );
  //       _isLoading = false;
  //       notifyListeners();
  //       return;
  //     }
  //
  //     final Map<String, dynamic> body = {
  //       "account_type": accountType,
  //       "bank_id": bankId,
  //       "wallet_type_id": walletTypeId,
  //       "currency_id": currencyId,
  //     };
  //
  //     final Map<String, dynamic> requestBodyWithHeaders = {
  //       'data': body,
  //       'headers': {'Authorization': 'Bearer $token'},
  //     };
  //
  //     final response = await ApiService.postRequest(
  //       "/customers/wallets", requestBodyWithHeaders,
  //     );
  //
  //     debugPrint("🔹 Create Wallet API Response: $response");
  //
  //     if (response != null && response["status"] == true) {
  //       _balance = response["data"]["balance"].toDouble();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("✅ Wallet created successfully! New Balance: $_balance")),
  //       );
  //     } else {
  //       debugPrint("⚠️ Error in wallet creation: ${response?["message"]}");
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("⚠️ ${response["message"] ?? "Failed to create wallet"}"), backgroundColor: Colors.red),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Failed to create wallet: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("❌ Failed to create wallet: $e"), backgroundColor: Colors.red),
  //     );
  //   }
  //
  //   _isLoading = false;
  //   notifyListeners();
  // }



}

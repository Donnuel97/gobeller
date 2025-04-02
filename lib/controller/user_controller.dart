import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/api_service.dart';

class UserController {
  // Handle user login
  static Future<String> attemptAuthentication(String username, String password) async {
    try {
      final response = await ApiService.postRequest("/login", {
        "username": username,
        "password": password,
      });

      debugPrint("🔹 Login API Response: $response");

      if (response["status"] == true) {
        // Save the token to SharedPreferences
        final String token = response["data"]["token"];
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);  // Store the token

        // Optionally, you can store other user data as well
        final String userData = json.encode(response["data"]["profile"]);
        await prefs.setString('user', userData);

        return "Successfully logged in";
      } else {
        return response["message"] ?? "Login failed";
      }
    } catch (e) {
      debugPrint("❌ Login API Error: $e");
      return "An error occurred";
    }
  }

  // Logout user
  static Future<bool> logoutAuthenticatedUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // Clear all stored data including the token
    return true;
  }

  // Get user data from local storage
  static Future<Map<String, dynamic>> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user');
    return userData != null ? json.decode(userData) : {};
  }

  // Get user's full name
  static Future<String> getFullName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('first_name') ?? "User";
  }

  // Get token from local storage
  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');  // Retrieve the token from SharedPreferences
  }
}
// class WalletController {
//   // Fetch wallets from the API and print the response to the debugger
//   static Future<void> fetchWallets() async {
//     try {
//       // Make the GET request to the wallets endpoint
//       final response = await ApiService.getRequest(
//         "/customers/wallets?page=1&items_per_page=15",
//       );
//
//       // Print the full response to the debugger
//       debugPrint("🔹 Wallets API Response: $response");
//
//       // Optional: Print just the wallet data if the request was successful
//       if (response["status"] == true) {
//         debugPrint("Wallet data: ${json.encode(response["data"])}");
//       } else {
//         debugPrint("Error: ${response["message"]}");
//       }
//     } catch (e) {
//       debugPrint("❌ Wallets API Error: $e");
//     }
//   }
// }
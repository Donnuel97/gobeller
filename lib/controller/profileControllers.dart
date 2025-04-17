import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController {
  // Fetch user profile from the API
  // static Future<Map<String, dynamic>?> fetchUserProfile() async {
  //   try {
  //     final SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final String? token = prefs.getString('auth_token');
  //
  //     if (token == null) {
  //       debugPrint("❌ No authentication token found. Please login again.");
  //       return null;
  //     }
  //
  //     // Print token to console
  //     debugPrint("🔑 Token for profile fetch: $token");
  //
  //     final extraHeaders = {
  //       'Authorization': 'Bearer $token',
  //     };
  //
  //     final response = await ApiService.getRequest("/profile", extraHeaders: extraHeaders);
  //
  //     debugPrint("🔹 User Profile API Response: $response");
  //
  //     if (response["status"] == true) {
  //       final profileData = response["data"];
  //
  //       Map<String, dynamic> userProfile = {
  //         'id': profileData["id"] ?? '',
  //         'full_name': profileData["full_name"] ?? '',
  //         'first_name': profileData["first_name"] ?? '',
  //         'email': profileData["email"] ?? '',
  //         'username': profileData["username"] ?? '',
  //         'telephone': profileData["telephone"] ?? '',
  //         'gender': profileData["gender"] ?? '',
  //         'date_of_birth': profileData["date_of_birth"] ?? '',
  //         'physical_address': profileData["physical_address"] ?? '',
  //         'should_send_sms': profileData["should_send_sms"] ?? false,
  //         'job_title': profileData["job_title"] ?? '',
  //         'profile_image_url': profileData["profile_image_url"],
  //         'status': profileData["status"]?["label"] ?? 'Unknown',
  //         'organization': profileData["organization"]?["full_name"] ?? 'Unknown Org',
  //         // Null-safe wallet data
  //         'wallet_balance': profileData["get_primary_wallet"]?["balance"] ?? "0.00",
  //         'wallet_number': profileData["get_primary_wallet"]?["wallet_number"] ?? "N/A",
  //         'wallet_currency': profileData["get_primary_wallet"]?["currency"]?["code"] ?? "N/A",
  //         'bank_name': profileData["get_primary_wallet"]?["bank"]?["name"] ?? "N/A",
  //       };
  //
  //       debugPrint("✅ Parsed User Profile: $userProfile");
  //       return userProfile;
  //     } else {
  //       debugPrint("⚠️ Error fetching profile: ${response["message"]}");
  //       return null;
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Profile API Error: $e");
  //     return null;
  //   }
  // }
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return null;
      }

      debugPrint("🔑 Token for profile fetch: $token");

      final extraHeaders = {
        'Authorization': 'Bearer $token',
      };

      final response = await ApiService.getRequest("/profile", extraHeaders: extraHeaders);

      debugPrint("🔹 User Profile API Response: $response");

      if (response["status"] == true) {
        final profileData = response["data"];
        final walletData = profileData["get_primary_wallet"];

        final walletBalance = walletData?["balance"];
        final walletNumber = walletData?["wallet_number"];
        final walletCurrency = walletData?["currency"]?["code"];
        final bankName = walletData?["bank"]?["name"];

        final bool hasWallet = walletData != null &&
            walletBalance != null &&
            walletNumber != null &&
            walletCurrency != null &&
            bankName != null;

        Map<String, dynamic> userProfile = {
          'id': profileData["id"] ?? '',
          'full_name': profileData["full_name"] ?? '',
          'first_name': profileData["first_name"] ?? '',
          'email': profileData["email"] ?? '',
          'username': profileData["username"] ?? '',
          'telephone': profileData["telephone"] ?? '',
          'gender': profileData["gender"] ?? '',
          'date_of_birth': profileData["date_of_birth"] ?? '',
          'physical_address': profileData["physical_address"] ?? '',
          'should_send_sms': profileData["should_send_sms"] ?? false,
          'job_title': profileData["job_title"] ?? '',
          'profile_image_url': profileData["profile_image_url"],
          'status': profileData["status"]?["label"] ?? 'Unknown',
          'organization': profileData["organization"]?["full_name"] ?? 'Unknown Org',
          'wallet_balance': walletBalance ?? "0.00",
          'wallet_number': walletNumber ?? "N/A",
          'wallet_currency': walletCurrency ?? "N/A",
          'bank_name': bankName ?? "N/A",
          'has_wallet': hasWallet,
        };

        // 🔐 Save raw profile response to local storage
        await prefs.setString('userProfileRaw', json.encode(profileData));

        debugPrint("✅ Saved raw profile to SharedPreferences.");
        debugPrint("✅ Parsed User Profile: $userProfile");

        return userProfile;
      } else {
        debugPrint("⚠️ Error fetching profile: ${response["message"]}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Profile API Error: $e");
      return null;
    }
  }


  // Change Password
  static Future<String> changePassword(
      String currentPassword, String newPassword, String newPasswordConfirmation) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token'); // Retrieve the authentication token

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return "Authentication required. Please log in again.";
      }

      // Print token to console
      debugPrint("🔑 Token for password change: $token");

      final extraHeaders = {
        'Authorization': 'Bearer $token', // Include the token in the Authorization header
      };

      // Prepare request body
      final Map<String, dynamic> body = {
        "current_password": currentPassword,
        "new_password": newPassword,
        "new_password_confirmation": newPasswordConfirmation,
      };

      // Make the POST request to change the password
      final response = await ApiService.postRequest(
        "/change-password", // Change password API endpoint
        body,
        extraHeaders: extraHeaders, // Include authorization headers
      );

      debugPrint("🔹 Change Password API Response: $response");

      if (response["status"] == true) {
        return "Password changed successfully."; // Return success message
      } else {
        return response["message"] ?? "Failed to change password."; // Return error message
      }
    } catch (e) {
      debugPrint("❌ Change Password API Error: $e");
      return "An error occurred while changing the password.";
    }
  }

  // Fetch Customer Support Details
  static Future<Map<String, dynamic>?> fetchCustomerSupportDetails() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? appId = prefs.getString('appId');

      if (appId == null || appId.isEmpty) {
        debugPrint("❌ AppID not found in SharedPreferences.");
        return null;
      }

      final response = await ApiService.getRequest(
        "/organizations/customer-support-details/$appId",
      );

      debugPrint("📞 Support API Response: $response");

      if (response["status"] == true) {
        return response["data"];
      } else {
        debugPrint("⚠️ Failed to load support details: ${response["message"]}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Support API Error: $e");
      return null;
    }
  }

  // Change Transaction PIN
  static Future<String> changeTransactionPin(String currentPin, String newPin) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token'); // Retrieve the authentication token

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return "Authentication required. Please log in again.";
      }

      // Print token to console
      debugPrint("🔑 Token for transaction PIN change: $token");

      final extraHeaders = {
        'Authorization': 'Bearer $token', // Include the token in the Authorization header
      };

      // Prepare request body
      final Map<String, dynamic> body = {
        "current_pin": currentPin,
        "new_pin": newPin,
      };

      // Make the POST request to change the transaction PIN
      final response = await ApiService.postRequest(
        "/change-transaction-pin", // Change transaction pin API endpoint
        body,
        extraHeaders: extraHeaders, // Include authorization headers
      );

      debugPrint("🔹 Change Transaction PIN API Response: $response");

      if (response["status"] == true) {
        return "Transaction PIN changed successfully."; // Return success message
      } else {
        return response["message"] ?? "Failed to change transaction PIN."; // Return error message
      }
    } catch (e) {
      debugPrint("❌ Change Transaction PIN API Error: $e");
      return "An error occurred while changing the transaction PIN.";
    }
  }
}

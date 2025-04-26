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
        final walletData = profileData["getPrimaryWallet"];
        final rawKyc = profileData["first_kyc_verification"];

        // 🔍 Normalize KYC: Accept map, or first item in a list if applicable
        Map<String, dynamic>? firstKycVerification;
        if (rawKyc is Map) {
          firstKycVerification = Map<String, dynamic>.from(rawKyc);
        } else if (rawKyc is List && rawKyc.isNotEmpty && rawKyc[0] is Map) {
          firstKycVerification = Map<String, dynamic>.from(rawKyc[0]);
        } else {
          firstKycVerification = null;
        }


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
          'first_kyc_verification': firstKycVerification ?? {},
          'kyc_image_encoding': firstKycVerification?["imageEncoding"] ?? '',
        };

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


  // Fetch All KYC Verifications
  static Future<List<Map<String, dynamic>>?> getKycVerifications() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return null;
      }

      debugPrint("🔑 Token for KYC fetch: $token");

      final extraHeaders = {
        'Authorization': 'Bearer $token',
      };

      final response = await ApiService.getRequest(
        "/customers/kyc-verifications",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 KYC Verifications API Response: $response");

      if (response["status"] == true) {
        final kycData = response["data"]["data"] as List<dynamic>;

        // Cast each KYC entry to a Map<String, dynamic> safely
        final List<Map<String, dynamic>> verifications = kycData
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        debugPrint("✅ Parsed KYC Verifications: $verifications");

        return verifications;
      } else {
        debugPrint("⚠️ Error fetching KYC verifications: ${response["message"]}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ KYC Verifications API Error: $e");
      return null;
    }
  }

  // Link KYC Verification
  static Future<String> linkKycVerification({
    required String idType,
    required String idValue,
    required String walletIdentifier,
    required String transactionPin,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return "Authentication required. Please log in again.";
      }

      debugPrint("🔑 Token for link KYC: $token");

      final extraHeaders = {
        'Authorization': 'Bearer $token',
      };

      final Map<String, dynamic> body = {
        "id_type": idType,
        "id_value": idValue,
        "customer_wallet_number_or_uuid": walletIdentifier,
        "transaction_pin": transactionPin,
      };

      final response = await ApiService.postRequest(
        "/customers/kyc-verifications/link/verified",
        body,
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Link KYC API Response: $response");

      if (response["status"] == true) {
        return "KYC linked successfully.";
      } else {
        return response["message"] ?? "Failed to link KYC.";
      }
    } catch (e) {
      debugPrint("❌ Link KYC API Error: $e");
      return "An error occurred while linking KYC.";
    }
  }

  // Fetch Wallets
  static Future<Map<String, dynamic>> fetchWallets() async {
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

      debugPrint("🔹 Wallets Profile API Response: $response");

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
        return {};
      }
    } catch (e) {
      debugPrint("❌ Wallets API Error: $e");
      return {};
    }
  }



}

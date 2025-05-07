import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController {

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
        await prefs.setString('userProfileRaw', json.encode(profileData)); // Save raw

        final walletData = profileData["getPrimaryWallet"];
        final rawKyc = profileData["first_kyc_verification"];

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
  // static Future<Map<String, dynamic>?> fetchCustomerSupportDetails() async {
  //   try {
  //     final SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final String? appId = prefs.getString('appId');
  //
  //     if (appId == null || appId.isEmpty) {
  //       debugPrint("❌ AppID not found in SharedPreferences.");
  //       return null;
  //     }
  //
  //     final response = await ApiService.getRequest(
  //       "/organizations/customer-support-details/$appId",
  //     );
  //
  //     debugPrint("📞 Support API Response: $response");
  //
  //     if (response["status"] == true) {
  //       final supportData = response["data"];
  //       await prefs.setString('customerSupportDetails', json.encode(supportData)); // Save raw
  //       return supportData;
  //     } else {
  //       debugPrint("⚠️ Failed to load support details: ${response["message"]}");
  //       return null;
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Support API Error: $e");
  //     return null;
  //   }
  // }

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
        final supportData = response["data"];

        // Store raw support data
        await prefs.setString('customerSupportRaw', json.encode(supportData));

        final address = supportData["address"] ?? {};
        final socialMedia = supportData["social_media"] ?? {};

        Map<String, dynamic> parsedSupportDetails = {
          'organization_full_name': supportData["organization_full_name"] ?? '',
          'organization_short_name': supportData["organization_short_name"] ?? '',
          'organization_description': supportData["organization_description"] ?? '',
          'public_existing_website': supportData["public_existing_website"] ?? '',
          'official_email': supportData["official_email"] ?? '',
          'official_telephone': supportData["official_telephone"] ?? '',
          'support_hours': supportData["support_hours"] ?? '',
          'live_chat_url': supportData["live_chat_url"] ?? '',
          'faq_url': supportData["faq_url"] ?? '',
          'address': {
            'physical_address': address["physical_address"] ?? '',
            'country': address["country"] ?? '',
          },
          'social_media': {
            'twitter': socialMedia["twitter"] ?? '',
            'facebook': socialMedia["facebook"] ?? '',
            'instagram': socialMedia["instagram"] ?? '',
          },
        };

        // Store parsed data
        await prefs.setString('customerSupportDetails', json.encode(supportData));


        debugPrint("✅ Saved parsed support details to SharedPreferences.");
        return parsedSupportDetails;
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

  static Future<Map<String, dynamic>> linkKycVerification({
    required String idType,
    required String idValue,
    required String walletIdentifier,
    required String transactionPin,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String? appId = prefs.getString('appId');

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': '🔒 Authentication required. Please log in again.'
        };
      }

      if (appId == null || appId.isEmpty) {
        return {
          'success': false,
          'message': '⚙️ App configuration missing. Please restart the app.'
        };
      }

      debugPrint("🔑 Token for link KYC: $token");
      debugPrint("🆔 AppID for link KYC: $appId");

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'AppID': appId,
      };

      final Map<String, dynamic> body = {
        "id_type": idType,
        "id_value": idValue,
        "customer_wallet_number_or_uuid": walletIdentifier,
        "transaction_pin": transactionPin,
      };

      debugPrint("📤 Submitting KYC Link Payload:");
      body.forEach((key, value) => debugPrint("   $key: $value"));

      final response = await ApiService.postRequest(
        "/customers/kyc-verifications/link/verified",
        body,
        extraHeaders: headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint("🔹 Link KYC API Response: $response");

      final bool status = response['status'] == true;
      final String message = (response['message'] ?? '').toString().trim();

      if (status) {
        return {
          'success': true,
          'message': "✅ KYC linked successfully."
        };
      } else {
        String friendlyMessage = '⚠️ Failed to link KYC.';

        if (message.isNotEmpty) {
          friendlyMessage = message;
        } else if (response.containsKey('errors')) {
          final errors = response['errors'] as Map<String, dynamic>;
          final errorMessages = errors.entries
              .map((entry) => entry.value is List
              ? (entry.value as List).join(', ')
              : entry.value.toString())
              .join('\n');

          friendlyMessage = errorMessages.isNotEmpty
              ? "⚠️ $errorMessages"
              : '⚠️ Failed to link KYC.';
        }

        return {'success': false, 'message': friendlyMessage};
      }

    } on SocketException {
      return {
        'success': false,
        'message': '📶 No internet connection. Please check your network and try again.'
      };
    } on ClientException {
      return {
        'success': false,
        'message': '🌐 Unable to connect to the server. Please try again later.'
      };
    } catch (e) {
      final error = e.toString().toLowerCase();
      if (error.contains("socketexception") || error.contains("failed host lookup")) {
        return {
          'success': false,
          'message': '📡 Network error. Please check your internet connection.'
        };
      }

      debugPrint("❌ Link KYC API Error: $e");
      return {
        'success': false,
        'message': '❌ Something went wrong. Please try again shortly.'
      };
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
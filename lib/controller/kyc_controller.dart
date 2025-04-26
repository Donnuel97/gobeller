import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KycVerificationController {
  // Fetch All KYC Verifications
  static Future<List<Map<String, dynamic>>?> fetchKycVerifications() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token'); // Retrieve the authentication token

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return null;
      }

      debugPrint("🔑 Token for KYC fetch: $token");

      final extraHeaders = {
        'Authorization': 'Bearer $token', // Include the token in the Authorization header
      };

      // Make the GET request to fetch KYC verifications
      final response = await ApiService.getRequest(
        "/customers/kyc-verifications", // KYC verifications endpoint
        extraHeaders: extraHeaders, // Include authorization headers
      );

      debugPrint("🔹 KYC Verifications API Response: $response");

      // Check if the response status is true and contains data
      if (response["status"] == true && response["data"] != null) {
        final kycData = response["data"] as List<dynamic>;

        final List<Map<String, dynamic>> verifications = kycData
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        for (var verification in verifications) {
          debugPrint("🔍 KYC Verification: $verification");
        }

        return verifications;
      }else {
        debugPrint("⚠️ Error fetching KYC verifications: ${response["message"]}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ KYC Verifications API Error: $e");
      return null;
    }
  }
}

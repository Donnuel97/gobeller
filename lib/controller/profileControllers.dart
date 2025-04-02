import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController {
  // Fetch user profile from the API
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token'); // Retrieve the authentication token

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return null; // If no token is found, return null
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token', // Include the token in the Authorization header
      };

      // Make the GET request to fetch user profile
      final response = await ApiService.getRequest(
        "/profile", // Profile API endpoint
        extraHeaders: extraHeaders, // Include authorization headers
      );

      debugPrint("🔹 User Profile API Response: $response");

      if (response["status"] == true) {
        // Extract user profile data
        var profileData = response["data"];

        // Extract relevant profile fields
        Map<String, dynamic> userProfile = {
          'id': profileData["id"],
          'full_name': profileData["full_name"],
          'first_name': profileData["first_name"],
          'email': profileData["email"],
          'username': profileData["username"],
          'telephone': profileData["telephone"],
          'gender': profileData["gender"],
          'job_title': profileData["job_title"],
          'profile_image_url': profileData["profile_image_url"],
          'status': profileData["status"]["label"],
          'organization': profileData["organization"]["full_name"],
          'wallet_balance': profileData["get_primary_wallet"]["balance"],
          'wallet_number': profileData["get_primary_wallet"]["wallet_number"],
          'wallet_currency': profileData["get_primary_wallet"]["currency"]["code"],
          'bank_name': profileData["get_primary_wallet"]["bank"]?["name"] ?? "N/A", // Retrieve bank name safely
        };

        debugPrint("✅ Parsed User Profile: $userProfile");

        return userProfile; // Return user profile details
      } else {
        debugPrint("⚠️ Error fetching profile: ${response["message"]}");
        return null; // Return null in case of an error
      }
    } catch (e) {
      debugPrint("❌ Profile API Error: $e");
      return null; // Return null in case of an error
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ensure this is the correct location of your API service

class NinVerificationController with ChangeNotifier {
  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  bool _isSubmitting = false; // To track submission state
  bool get isSubmitting => _isSubmitting;

  Map<String, dynamic>? _ninData;
  Map<String, dynamic>? get ninData => _ninData;

  String _verificationMessage = "";
  String get verificationMessage => _verificationMessage;

  String _submissionMessage = "";
  String get submissionMessage => _submissionMessage;

  /// **Verifies NIN, BVN or Passport and fetches user details**
  Future<void> verifyId(String idNumber, String idType) async {
    _isVerifying = true;
    _ninData = null;
    _verificationMessage = '';
    notifyListeners();

    try {
      String endpoint = '';

      // Determine the correct endpoint based on the ID type
      if (idType == 'nin') {
        endpoint = "/verify/nin/$idNumber";  // NIN verification endpoint
      } else if (idType == 'bvn') {
        endpoint = "/verify/bvn/$idNumber";  // BVN verification endpoint
      } else if (idType == 'passport-number') {
        endpoint = "/verify/passport-number/$idNumber";  // Passport verification endpoint
      } else {
        _verificationMessage = "⚠️ Invalid ID type selected.";
        _isVerifying = false;
        notifyListeners();
        return;
      }

      // Make the API call
      final response = await ApiService.getRequest(endpoint);

      debugPrint("🔹 ID Verification API Response: $response");

      if (response["status"] == true && response["data"] != null) {
        _ninData = response["data"];
        _verificationMessage = "$idType Verified Successfully!";
      } else {
        _verificationMessage = response["message"] ?? "⚠️ Verification failed.";
      }
    } catch (e) {
      _verificationMessage = "❌ Error verifying ID. Please try again.";
      debugPrint("❌ ID Verification API Error: $e");
    }

    _isVerifying = false;
    notifyListeners();
  }

  /// **Submits the registration data with KYC**
  /// **Submits the registration data with KYC**
  Future<void> submitRegistration({
    required String idType,
    required String idNumber,
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String username,
    required String telephone,
    required String gender,
    required String password,
    required int transactionPin,
  }) async {
    _isSubmitting = true;
    _submissionMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> body = {
        "id_type": idType,
        "id_value": idNumber.toString(),
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "email": email,
        "username": username,
        "telephone": telephone.toString(),
        "gender": gender,
        "password": password,
        "transaction_pin": transactionPin.toString(),
      };

      debugPrint("📤 Submitting Registration Payload:");
      body.forEach((key, value) => debugPrint("   $key: $value"));

      final response = await ApiService.postRequest(
        '/customers-api/registrations/with-kyc',
        body,
      );

      debugPrint("🔹 Registration API Response: $response");

      if (response["status"] == true) {
        _submissionMessage = "✅ Registration successful! Please check your email to verify your account.";

        // 👉 Save response data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // Save user data if available
        if (response.containsKey('data')) {
          final userData = response['data'];
          await prefs.setString('userData', json.encode(userData));
          await prefs.setBool('isLoggedIn', false); // User needs to login after registration
        }

        // Save token if available
        if (response.containsKey('token')) {
          await prefs.setString('authToken', response['token']);
        }

        // Save app settings if provided
        if (response.containsKey('app_settings')) {
          await prefs.setString('appSettingsData', json.encode(response['app_settings']));
        }

        // Save organization data if provided
        if (response.containsKey('organization')) {
          await prefs.setString('organizationData', json.encode(response['organization']));
        }

        // Optional: Notify other parts of the app to reload settings or refresh UI
      } else {
        // Handle registration error response
        if (response.containsKey('errors')) {
          final errors = response['errors'] as Map<String, dynamic>;
          final errorMessages = errors.entries
              .map((entry) => entry.value is List
              ? (entry.value as List).join(', ')
              : entry.value.toString())
              .join('\n');

          _submissionMessage = errorMessages.isNotEmpty
              ? "⚠️ $errorMessages"
              : (response["message"] ?? "⚠️ Registration failed.");
        } else {
          _submissionMessage = response["message"] ?? "⚠️ Registration failed.";
        }
      }
    } catch (e) {
      _submissionMessage = "❌ Error submitting registration. Please try again.";
      debugPrint("❌ Registration API Error: $e");
    }

    _isSubmitting = false;
    notifyListeners();
  }




  /// **Clears verification data**
  void clearVerification() {
    _ninData = null;
    _verificationMessage = "";
    notifyListeners();
  }
}

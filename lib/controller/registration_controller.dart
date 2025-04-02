import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart'; // Ensure this is the correct location of your API service

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
      if (idType == 'NIN') {
        endpoint = "/verify/nin/$idNumber";  // NIN verification endpoint
      } else if (idType == 'BVN') {
        endpoint = "/verify/bvn/$idNumber";  // BVN verification endpoint
      } else if (idType == 'Passport Number') {
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
  Future<void> submitRegistration({
    required String idType,
    required String idValue,
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
    _submissionMessage = ''; // Clear any previous messages
    notifyListeners();

    try {
      // Prepare the registration body
      final Map<String, dynamic> body = {
        "id_type": idType, // passport-number, nin, bvn
        "id_value": idValue,
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "email": email,
        "username": username,
        "telephone": telephone,
        "gender": gender,
        "password": password,
        "transaction_pin": transactionPin,
      };

      // Convert body to JSON
      final String jsonBody = json.encode(body);

      // Make the POST request
      final response = await ApiService.postRequest(
        '/customers-api/registrations/with-kyc',  // endpoint
        body,  // formData (this is the second required argument)
      );

      debugPrint("🔹 Registration API Response: $response");

      if (response["status"] == true) {
        _submissionMessage = "Registration successful!";
      } else {
        _submissionMessage = response["message"] ?? "⚠️ Registration failed.";
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

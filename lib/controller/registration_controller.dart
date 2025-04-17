import 'dart:convert';
import 'dart:io'; // 👈 Needed for catching SocketException
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NinVerificationController with ChangeNotifier {
  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Map<String, dynamic>? _ninData;
  Map<String, dynamic>? get ninData => _ninData;

  String _verificationMessage = "";
  String get verificationMessage => _verificationMessage;

  String _submissionMessage = "";
  String get submissionMessage => _submissionMessage;

  /// Verifies NIN, BVN or Passport and fetches user details
  Future<void> verifyId(String idNumber, String idType) async {
    _isVerifying = true;
    _ninData = null;
    _verificationMessage = '';
    notifyListeners();

    try {
      String endpoint = '';

      if (idType == 'nin') {
        endpoint = "/verify/nin/$idNumber";
      } else if (idType == 'bvn') {
        endpoint = "/verify/bvn/$idNumber";
      } else if (idType == 'passport-number') {
        endpoint = "/verify/passport-number/$idNumber";
      } else {
        _verificationMessage = "⚠️ Invalid ID type selected.";
        _isVerifying = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(endpoint);
      debugPrint("🔹 ID Verification API Response: $response");

      if (response["status"] == true && response["data"] != null) {
        _ninData = response["data"];
        _verificationMessage = "$idType Verified Successfully!";
      } else {
        _verificationMessage = response["message"] ?? "⚠️ Verification failed.";
      }
    } on SocketException catch (_) {
      _verificationMessage = "🚫 Unable to connect. Please check your internet connection and try again.";
    } catch (e) {
      _verificationMessage = "❌ Error verifying ID. Please try again.";
      debugPrint("❌ ID Verification API Error: $e");
    }

    _isVerifying = false;
    notifyListeners();
  }

  /// Submits the registration data with KYC
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
    required String dateOfBirth,
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
        "telephone": telephone,
        "gender": gender,
        "password": password,
        "transaction_pin": transactionPin.toString(),
        "date_of_birth": dateOfBirth,
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

        final prefs = await SharedPreferences.getInstance();

        if (response.containsKey('data')) {
          final userData = response['data'];
          await prefs.setString('userData', json.encode(userData));
          await prefs.setBool('isLoggedIn', false);
        }

        if (response.containsKey('token')) {
          await prefs.setString('authToken', response['token']);
        }

        if (response.containsKey('app_settings')) {
          await prefs.setString('appSettingsData', json.encode(response['app_settings']));
        }

        if (response.containsKey('organization')) {
          await prefs.setString('organizationData', json.encode(response['organization']));
        }
      } else {
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
    } on SocketException catch (_) {
      _submissionMessage = "🚫 Unable to connect. Please check your internet connection and try again.";
    } catch (e) {
      _submissionMessage = "❌ Error submitting registration. Please try again.";
      debugPrint("❌ Registration API Error: $e");
    }

    _isSubmitting = false;
    notifyListeners();
  }

  /// Clears verification data
  void clearVerification() {
    _ninData = null;
    _verificationMessage = "";
    notifyListeners();
  }
}

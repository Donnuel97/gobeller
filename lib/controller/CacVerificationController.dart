import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacVerificationController with ChangeNotifier {
  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  Map<String, dynamic>? _companyDetails;
  Map<String, dynamic>? get companyDetails => _companyDetails;

  /// Verify CAC Number
  Future<void> verifyCacNumber({
    required String corporateIdType,
    required String corporateIdNumber,
    required BuildContext context,
  }) async {
    _isVerifying = true;
    _companyDetails = null;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Authentication required. Please log in again.")),
        );
        _isVerifying = false;
        notifyListeners();
        return;
      }

      final String endpoint = "/verify/cac-number";
      final Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

      final Map<String, dynamic> body = {
        "corporate-id-type": corporateIdType,
        "corporate-id-number": corporateIdNumber,
      };

      debugPrint("📤 Sending CAC Verification Request: ${jsonEncode(body)}");

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
      debugPrint("🔹 CAC Verification API Response: $response");

      if (response["status"] == true) {
        _companyDetails = response["data"];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ CAC Verified: ${_companyDetails?['company_name'] ?? 'Company'}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ ${response['message']}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Verification failed: $e"), backgroundColor: Colors.red),
      );
    }

    _isVerifying = false;
    notifyListeners();
  }
}

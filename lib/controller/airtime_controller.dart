import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AirtimeController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> buyAirtime({
    required String networkProvider,
    required String phoneNumber,
    required String amount,
    required String pin,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Retrieve Auth Token from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Authentication required. Please log in again.")),
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      const String url = "https://app.gobeller.com/api/v1/transactions/buy-airtime";
      final Map<String, String> headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Use the saved token
      };

      final Map<String, dynamic> body = {
        "network_provider": networkProvider.toLowerCase(),
        "final_amount": amount,
        "phone_number": phoneNumber,
        "transaction_pin": pin,
      };

      final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
      final data = jsonDecode(response.body);

      if (data["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${data["message"]}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Error: ${data["message"]}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Request failed: $e"), backgroundColor: Colors.red),
      );
    }

    _isLoading = false;
    notifyListeners();
  }
}

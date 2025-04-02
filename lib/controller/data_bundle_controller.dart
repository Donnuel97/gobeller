import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataBundleController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  static Future<List<Map<String, dynamic>>?> fetchDataBundles(String network) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        debugPrint("❌ No authentication token found.");
        return null;
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
      };

      String endpoint = "get-data-bundles/${network.toLowerCase()}-data";

      final response = await ApiService.getRequest(
        "/transactions/$endpoint",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Data Bundles API Response for $network: $response");

      if (response["status"] == true) {
        return List<Map<String, dynamic>>.from(response["data"]);
      } else {
        debugPrint("⚠️ Error fetching data bundles: ${response["message"]}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Data Bundle API Error: $e");
      return null;
    }
  }

  Future<void> buyDataBundle({
    required String networkProvider,
    required String dataPlan,
    required String phoneNumber,
    required String pin,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
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

      final String endpoint = "/transactions/buy-data-bundle";
      final Map<String, String> headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final Map<String, dynamic> body = {
        "network_provider": networkProvider.toLowerCase() + "-data",
        "data_plan": dataPlan,
        "phone_number": phoneNumber,
        "transaction_pin": pin,
      };

      debugPrint("📤 Sending Data Purchase Request: ${jsonEncode(body)}");

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
      debugPrint("🔹 Data Purchase API Response: $response");

      if (response["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${response["message"]}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Error: ${response["message"]}"), backgroundColor: Colors.red),
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

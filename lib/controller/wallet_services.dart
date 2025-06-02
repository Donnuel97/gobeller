import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gobeller/utils/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  static const String _baseUrl = "https://app.gobeller.com/api/v1/customers/wallets?page=1&items_per_page=15";

  Future<Map<String, dynamic>?> fetchWalletData() async {
    try {
      String? token = await AuthService.getAuthToken();
      final prefs = await SharedPreferences.getInstance();
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        throw Exception("No authentication token found.");
      }

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "AppID": appId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse["status"] == true && jsonResponse["data"]["data"].isNotEmpty) {
          final wallet = jsonResponse["data"]["data"][0];
          return {
            "wallet_number": wallet["wallet_number"],
            "balance": wallet["balance"],
            "currency_symbol": wallet["currency"]["symbol"],
          };
        }
      }

      return null;
    } catch (e) {
      print("Error fetching wallet data: $e");
      return null;
    }
  }
}

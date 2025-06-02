import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletTransactionController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> get transactions => _transactions;

  /// Fetch Wallet Transactions
  Future<void> fetchWalletTransactions() async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No authentication token found.");
        _isLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return;
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'AppID': appId,
      };

      final response = await ApiService.getRequest(
        "/customers/wallet-transactions",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Wallet Transactions API Response: $response");

      if (response["status"] == true) {
        _transactions = List<Map<String, dynamic>>.from(
          response["data"]["transactions"]["data"] ?? [],
        );
        debugPrint("✅ Transactions Loaded: ${_transactions.length}");
      } else {
        debugPrint("⚠️ Error fetching transactions: ${response["message"]}");
      }
    } catch (e) {
      debugPrint("❌ Wallet Transactions API Error: $e");
    }

    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

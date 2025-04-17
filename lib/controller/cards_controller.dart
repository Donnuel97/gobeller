import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/api_service.dart';

class VirtualCardController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _virtualCards = [];
  List<Map<String, dynamic>> get virtualCards => _virtualCards;

  List<Map<String, dynamic>> _sourceWallets = [];
  List<Map<String, dynamic>> get sourceWallets => _sourceWallets;

  String _transactionMessage = "";
  String get transactionMessage => _transactionMessage;




  /// **Fetch authentication token**
  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Fetches all virtual cards
  Future<void> fetchVirtualCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No auth token found.");
        _virtualCards = [];
        return;
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      const String endpoint = "/card-mgt/cards/virtual/list?page=1&items_per_page=20";
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);

      debugPrint("🔹 Virtual Cards API Response: $response");

      if (response["status"] == true &&
          response["data"] != null &&
          response["data"]["data"] != null) {
        _virtualCards = List<Map<String, dynamic>>.from(response["data"]["data"]);
      } else {
        debugPrint("⚠️ Failed to fetch virtual cards: ${response["message"]}");
        _virtualCards = [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching virtual cards: $e");
      _virtualCards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWallets() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No auth token found.");
        return;
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      const String endpoint = "/customers/wallets";
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);

      debugPrint("🔹 Wallets API Response: $response");

      // Check if response is a Map and contains 'data' and 'data' field (which holds the wallets)
      if (response["status"] == true && response["data"] != null && response["data"]["data"] != null) {
        // Access the wallets list
        _sourceWallets = List<Map<String, dynamic>>.from(response["data"]["data"]);
        debugPrint("✅ Wallets fetched successfully.");
      } else {
        debugPrint("⚠️ Failed to fetch wallets: ${response["message"]}");
        _sourceWallets = [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching wallets: $e");
      _sourceWallets = [];
    } finally {
      notifyListeners();
    }
  }



  // /// **Fetches user wallets**
  // Future<void> fetchWallets() async {
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final String? token = await _getAuthToken();
  //     if (token == null) {
  //       _transactionMessage = "❌ Authentication required.";
  //       _isLoading = false;
  //       notifyListeners();
  //       return;
  //     }
  //
  //     final response = await ApiService.getRequest(
  //       "customers/wallets",
  //       extraHeaders: {'Authorization': 'Bearer $token'},
  //     );
  //
  //     if (response["status"] == true && response["data"]?["data"] != null) {
  //       final List wallets = response["data"]["data"];
  //
  //       _sourceWallets = wallets.map((wallet) {
  //         return {
  //           "account_number": wallet["wallet_number"] ?? "",
  //           "available_balance": wallet["balance"] ?? "0.00",
  //           "currency_symbol": wallet["currency"]?["symbol"] ?? "₦",
  //           "wallet_type": wallet["wallet_type"]?["name"] ?? "Default Wallet"
  //         };
  //       }).toList();
  //     } else {
  //       _transactionMessage = "⚠️ Unable to fetch wallets.";
  //       _sourceWallets = [];
  //     }
  //   } catch (e) {
  //     print("Error: $e");
  //     _transactionMessage = "❌ Error fetching wallets. Please try again.";
  //     _sourceWallets = [];
  //   }
  //
  //   _isLoading = false;
  //   notifyListeners();
  // }

  /// Creates a new virtual card
  Future<String> createVirtualCard({required String cardPin}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return "Authentication token missing.";
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      const String endpoint = "/card-mgt/cards/virtual/create";
      final Map<String, dynamic> body = {
        "card_pin": cardPin,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("🆕 Create Card Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards(); // Refresh the list after creation
        return "Virtual card created successfully.";
      } else {
        return response["message"] ?? "Failed to create card.";
      }
    } catch (e) {
      debugPrint("❌ Error creating virtual card: $e");
      return "An error occurred while creating the card.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles virtual card lock status (block/unblock)
  Future<String> toggleCardLockStatus(String cardId, bool isCurrentlyLocked) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return "Authentication token missing.";
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
        "Content-Type": "application/json",
      };

      final String endpoint = isCurrentlyLocked
          ? "/card-mgt/cards/$cardId/unblock"
          : "/card-mgt/cards/$cardId/block";

      final response = await ApiService.patchRequest(endpoint, {}, extraHeaders: headers);

      debugPrint("🔄 Toggle Lock Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards(); // Refresh after toggle
        return isCurrentlyLocked ? "Card has been unfrozen." : "Card has been frozen.";
      } else {
        return response["message"] ?? "Failed to update card status.";
      }
    } catch (e) {
      debugPrint("❌ Error toggling lock status: $e");
      return "An error occurred while updating card status.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  /// Adds funds to a virtual card using a source wallet and payment channel
  Future<String> addFundsToCard({
    required String cardId,
    required double amount,
    required String walletId, // wallet_number
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return "Authentication token missing.";
      }

      // Safely fetch wallet by wallet_number
      Map<String, dynamic> wallet;
      try {
        wallet = _sourceWallets.firstWhere(
              (wallet) => wallet["wallet_number"] == walletId,
        );
      } catch (e) {
        debugPrint("❌ Wallet not found: $e");
        return "Selected wallet not found.";
      }

      final String paymentChannel = wallet["payment_method"] ?? "stripe";
      final String currency = wallet["currency"]?["code"] ?? "NGN";

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
        "Content-Type": "application/json",
      };

      final String endpoint = "/card-mgt/cards/virtual/$cardId/funding";
      final Map<String, dynamic> body = {
        "amount": amount.toString(),
        "currency": currency,
        "payment_channel": paymentChannel,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("💰 Fund Card Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards();
        return "Funds added successfully.";
      } else {
        return response["message"] ?? "Failed to add funds.";
      }
    } catch (e) {
      debugPrint("❌ Error adding funds: $e");
      return "An error occurred while funding the card.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


}

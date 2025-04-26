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

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // New: Store card details by card ID
  Map<String, Map<String, dynamic>> _cardDetails = {};
  Map<String, Map<String, dynamic>> get cardDetails => _cardDetails;
// inside VirtualCardController

  Map<String, dynamic>? getCardById(String cardId) {
    return _cardDetails[cardId];
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

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

      final headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      const endpoint = "/card-mgt/cards/virtual/list?page=1&items_per_page=20";
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);

      debugPrint("🔹 Virtual Cards API Response: $response");

      if (response["status"] == true &&
          response["data"] != null &&
          response["data"]["data"] != null) {
        _virtualCards = List<Map<String, dynamic>>.from(response["data"]["data"]);

        // Fetch balance for the first card automatically
        if (_virtualCards.isNotEmpty) {
          fetchCardBalanceDetails(_virtualCards.first['id']);
        }
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

  Future<void> fetchCardBalanceDetails(String cardId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No auth token found.");
        return;
      }

      final headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      final endpoint = "/card-mgt/cards/virtual/$cardId/balance";
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);

      debugPrint("💳 Card Balance Response for $cardId: $response");

      if (response["status"] == true && response["data"] != null) {
        _cardDetails[cardId] = {
          "id": response["data"]["id"],
          "name": response["data"]["name"],
          "card_number": response["data"]["card_number"],
          "masked_pan": response["data"]["masked_pan"],
          "expiry": response["data"]["expiry"],
          "cvv": response["data"]["cvv"],
          "status": response["data"]["status"],
          "type": response["data"]["type"],
          "issuer": response["data"]["issuer"],
          "currency": response["data"]["currency"],
          "balance": response["data"]["balance"],
          "balance_updated_at": response["data"]["balance_updated_at"],
          "auto_approve": response["data"]["auto_approve"],
          "address": response["data"]["address"],
          "created_at": response["data"]["created_at"],
          "updated_at": response["data"]["updated_at"],
          "is_amount_locked": response["data"]["is_amount_locked"],
        };
      } else {
        debugPrint("⚠️ Failed to fetch card details: ${response["message"]}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching card details: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<String> createVirtualCard({required String cardPin, required BuildContext context}) async {
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
        "transaction_pin": cardPin,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("🆕 Create Card Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards(); // Refresh the list after creation
        return "Virtual card created successfully.";
      } else {
        // Handle specific error message for insufficient funds
        if (response["statusCode"] == 403) {
          return "Insufficient funds to create a virtual card.";
        } else {
          return response["message"] ?? "Failed to create card.";
        }
      }
    } catch (e) {
      debugPrint("❌ Error creating virtual card: $e");
      return "An error occurred while creating the card.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  /// Fetch wallets associated with the user
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

      if (response["status"] == true && response["data"] != null && response["data"]["data"] != null) {
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

  /// Creates a new virtual card



  // Method to create the virtual card
  // Future<String> createVirtualCard({required String cardPin}) async {
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final String? token = prefs.getString('auth_token');
  //     final String appId = prefs.getString('appId') ?? '';
  //
  //     if (token == null) {
  //       return "Authentication token missing."; // Error message
  //     }
  //
  //     final Map<String, String> headers = {
  //       "Accept": "application/json",
  //       "Authorization": "Bearer $token",
  //       "AppID": appId,
  //     };
  //
  //     const String endpoint = "/card-mgt/cards/virtual/create";
  //     final Map<String, dynamic> body = {
  //       "transaction_pin": cardPin,
  //     };
  //
  //     final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
  //
  //     debugPrint("🆕 Create Card Response: $response");
  //
  //     if (response["status"] == true) {
  //       await fetchVirtualCards(); // Refresh the list after creation
  //       return "Virtual card created successfully."; // Success message
  //     } else {
  //       return response["message"] ?? "Failed to create card."; // Error message
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Error creating virtual card: $e");
  //     return "An error occurred while creating the card."; // Error message
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }


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

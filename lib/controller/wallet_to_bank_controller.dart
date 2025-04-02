import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletToBankTransferController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // Add this method
  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  bool _isVerifyingWallet = false;
  bool get isVerifyingWallet => _isVerifyingWallet;

  String _beneficiaryName = "";
  String get beneficiaryName => _beneficiaryName;



  // Setter method to update beneficiary name
  void setBeneficiaryName(String name) {
    _beneficiaryName = name;
    notifyListeners(); // Notify listeners when the beneficiary name changes
  }

  // Method to clear the beneficiary name
  void clearBeneficiaryName() {
    _beneficiaryName = "";  // Clear the beneficiary name
    notifyListeners(); // Notify listeners to refresh UI
  }
  List<Map<String, dynamic>> _sourceWallets = [];
  List<Map<String, dynamic>> get sourceWallets => _sourceWallets;

  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> get banks => _banks;

  String _transactionMessage = "";
  String get transactionMessage => _transactionMessage;

  /// **Fetch authentication token**
  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// **Fetches list of banks**
  Future<void> fetchBanks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(
        "/banks",
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true) {
        _banks = (response["data"] as List).map((bank) => {
          "id": bank["id"] ?? "Unknown",
          "bank_code": bank["code"],
          "bank_name": bank["name"]
        }).toList();
      } else {
        _transactionMessage = "⚠️ We couldn't retrieve the list of banks. Please try again later.";
        _banks = [];
      }
    } catch (e) {
      _transactionMessage = "❌ We encountered an error while fetching banks. Please check your internet connection and try again.";
      _banks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// **Fetches source wallets**
  Future<void> fetchSourceWallets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ Authentication required.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(
        "/customers/wallets",
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true) {
        _sourceWallets = (response["data"]["data"] as List).map((wallet) {
          return {
            "account_number": wallet["wallet_number"],
            "available_balance": wallet["balance"],
            "currency_symbol": wallet["currency"]["symbol"],
            "wallet_type": wallet["wallet_type"]["name"],
          };
        }).toList();
      } else {
        _transactionMessage = "⚠️ Unable to fetch wallets.";
        _sourceWallets = [];
      }
    } catch (e) {
      _transactionMessage = "❌ Error fetching wallets. Please try again.";
      _sourceWallets = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// **Verifies a bank account before processing transfer**
  Future<void> verifyBankAccount({
    required String accountNumber,
    required String bankId,
  }) async {
    _isVerifyingWallet = true;
    _beneficiaryName = "";
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _beneficiaryName = "❌ You are not logged in. Please log in to continue.";
        _isVerifyingWallet = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(
        "/verify/bank-account/$accountNumber/$bankId",
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true && response["data"] != null) {
        _beneficiaryName = response["data"]["account_name"] ?? "Unknown Account";
      } else {
        _beneficiaryName = "❌ Unable to verify the account. Please check the account number and try again.";
      }
    } catch (e) {
      _beneficiaryName = "❌ We encountered an error while verifying the account. Please try again later.";
    }

    _isVerifyingWallet = false;
    notifyListeners();
  }

  /// **Initiate Wallet to Bank Transfer**
  Future<void> initializeBankTransfer({
    required String sourceWallet,
    required String bankCode,
    required String accountNumber,
    required double amount,
    required String narration,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ Authentication failed. Please log in.";
        _isProcessing = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.postRequest(
        "/customers/wallet-to-bank-transaction/initiate",
        {
          "source_wallet_number": sourceWallet,
          "bank_code": bankCode,
          "account_number": accountNumber,
          "amount": amount,
          "narration": narration.isNotEmpty ? narration : "Wallet to Bank Transfer",
        },
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true) {
        _transactionMessage = response["message"] ?? "✅ Transfer initialized successfully!";
      } else {
        _transactionMessage = response["message"] ?? "❌ Transaction failed.";
      }
    } catch (e) {
      _transactionMessage = "❌ Error initializing transfer. Please try again.";
      debugPrint("❌ Error: $e");
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// **Complete the Transfer**
  /// **Fetch authentication token**

  /// **Complete the Wallet to Bank Transfer**
  Future<void> completeBankTransfer({
    required String sourceWallet,
    required String destinationAccountNumber,
    required String bankId,
    required double amount,
    required String description,
    required String transactionPin,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
        _isProcessing = false;
        notifyListeners();
        return;
      }

      final requestBody = {
        "source_wallet_number": sourceWallet,
        "destination_account_number": destinationAccountNumber,
        "bank_id": bankId,
        "amount": amount,
        "description": description.isNotEmpty ? description : "Wallet to Bank Transfer",
        "transaction_pin": transactionPin
      };

      final response = await ApiService.postRequest(
        "/customers/wallet-to-bank-transaction/process",
        requestBody,
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true) {
        _transactionMessage = "✅ Your transfer was successful! Funds have been sent to the bank.";
      } else {
        _transactionMessage = "❌ Transfer failed. Please check your details and try again.";
      }
    } catch (e) {
      _transactionMessage = "❌ We encountered an error while processing the transfer. Please try again.";
    }

    _isProcessing = false;
    notifyListeners();
  }


}

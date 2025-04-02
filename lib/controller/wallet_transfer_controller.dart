import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletTransferController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _isVerifyingWallet = false;
  bool get isVerifyingWallet => _isVerifyingWallet;

  List<Map<String, dynamic>> _sourceWallets = [];
  List<Map<String, dynamic>> get sourceWallets => _sourceWallets;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String _transactionMessage = "";
  String get transactionMessage => _transactionMessage;

  String _beneficiaryName = "";
  String get beneficiaryName => _beneficiaryName;

  double _amountProcessable = 0.0;
  double get amountProcessable => _amountProcessable;

  double _expectedBalanceAfter = 0.0;
  double get expectedBalanceAfter => _expectedBalanceAfter;

  String _transactionCurrency = "NGN";
  String get transactionCurrency => _transactionCurrency;

  String _transactionCurrencySymbol = "₦";
  String get transactionCurrencySymbol => _transactionCurrencySymbol;

  String _actualBalanceBefore = "0.00";
  String get actualBalanceBefore => _actualBalanceBefore;

  String _platformChargeFee = "0.00";
  String get platformChargeFee => _platformChargeFee;

  String _totalAmountProcessable = "0.00";
  String get totalAmountProcessable => _totalAmountProcessable;

  String _transactionReference = "";
  String get transactionReference => _transactionReference;

  String _transactionStatus = "";
  String get transactionStatus => _transactionStatus;

  void clearBeneficiaryName() {
    _beneficiaryName = "";
    notifyListeners();
  }
  /// **Fetch authentication token**
  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// **Fetches source wallets from API**
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
        _sourceWallets = (response["data"]["data"] as List)
            .map((wallet) => {
          "account_number": wallet["wallet_number"],
          "available_balance": wallet["balance"],
          "currency_symbol": wallet["currency"]["symbol"],
          "wallet_type": wallet["wallet_type"]["name"]
        })
            .toList();
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

  /// **Verifies recipient wallet number**
  Future<void> verifyWalletNumber(String walletNumber) async {
    if (walletNumber.length != 10) return;

    _isVerifyingWallet = true;
    _beneficiaryName = "";
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _beneficiaryName = "Verification failed: No authentication token";
        _isVerifyingWallet = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(
        "/verify/wallet-number/$walletNumber",
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true && response["data"] != null) {
        _beneficiaryName = response["data"]["wallet_name"] ?? "Unknown Wallet";
      } else {
        _beneficiaryName = response["message"] ?? "Wallet not found";
      }
    } catch (e) {
      _beneficiaryName = "Verification failed. Please try again.";
    }

    _isVerifyingWallet = false;
    notifyListeners();
  }

  /// **Initializes transfer process**
  Future<void> initializeTransfer({
    required String sourceWallet,
    required String destinationWallet,
    required double amount,
    required String description,
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
        "/customers/wallet-to-wallet-transaction/initiate",
        {
          "source_wallet_number": sourceWallet,
          "destination_wallet_number": destinationWallet,
          "amount": amount,
          "description": description
        },
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true) {
        final data = response["data"];
        _transactionCurrency = data["currency_code"] ?? "NGN";
        _transactionCurrencySymbol = data["currency_symbol"] ?? "₦";
        _actualBalanceBefore = data["actual_balance_before"] ?? "0.00";
        _amountProcessable = double.tryParse(data["amount_processable"]?.toString() ?? '0.0') ?? 0.0;
        _platformChargeFee = data["platform_charge_fee"] ?? "0.00";
        _expectedBalanceAfter = double.tryParse(data["expected_balance_after"]?.replaceAll(',', '') ?? '0.0') ?? 0.0;
        _totalAmountProcessable = data["total_amount_processable"] ?? "0.00";

        _isInitialized = true;
        _transactionMessage = response["message"] ?? "✅ Transfer initialized successfully!";
      } else {
        _isInitialized = false;
        _transactionMessage = response["message"] ?? "❌ Transaction failed.";
      }
    } catch (e) {
      _isInitialized = false;
      _transactionMessage = "❌ Error initializing transfer. Please try again.";
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// **Completes the transfer using API**
  Future<void> completeTransfer({
    required String sourceWallet,
    required String destinationWallet,
    required double amount,
    required String description,
    required String transactionPin,
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

      final requestBody = {
        "source_wallet_number": sourceWallet,
        "destination_wallet_number": destinationWallet,
        "amount": amount,
        "description": description.isNotEmpty ? description : "Gobeller",
        "transaction_pin": transactionPin
      };


      print("🔹 Sending Request: $requestBody"); // Debugging

      final response = await ApiService.postRequest(
        "/customers/wallet-to-wallet-transaction/process",
        requestBody,
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      print("🔹 API Response: $response"); // Debugging

      if (response["status"] == true) {
        _transactionMessage = response["message"] ?? "✅ Transfer successfully processed!";
      } else {
        _transactionMessage = response["message"] ?? "❌ Transfer failed.";
      }
    } catch (e) {
      print("❌ Error: $e"); // Debugging
      _transactionMessage = "❌ Error processing transfer. Please try again.";
    }

    _isProcessing = false;
    notifyListeners();
  }

}

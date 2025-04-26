// Unchanged imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gobeller/utils/currency_input_formatter.dart';
import 'package:gobeller/controller/wallet_transfer_controller.dart';

import '../../utils/routes.dart';

class WalletToWalletTransferPage extends StatefulWidget {
  const WalletToWalletTransferPage({super.key});

  @override
  State<WalletToWalletTransferPage> createState() => _WalletToWalletTransferPageState();
}

class _WalletToWalletTransferPageState extends State<WalletToWalletTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _destWalletController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String? selectedSourceWallet;
  bool _isPinHidden = true;
  bool _isCompletingTransfer = false;

  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _fetchThemeColors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<WalletTransferController>(context, listen: false);
      controller.fetchSourceWallets();
      controller.clearBeneficiaryName();
    });
  }

  Future<void> _fetchThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};
      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }

  Future<Color> _getColorFromPrefs(String key, Color fallback) async {
    final prefs = await SharedPreferences.getInstance();
    final colorInt = prefs.getInt(key);
    return colorInt != null ? Color(colorInt) : fallback;
  }

  void _resetForm(WalletTransferController controller) {
    _formKey.currentState?.reset();
    _destWalletController.clear();
    _amountController.clear();
    _narrationController.clear();
    _pinController.clear();
    setState(() {
      selectedSourceWallet = null;
    });
    controller.clearBeneficiaryName();
  }

  void _showTransferResult(WalletTransferController controller) {
    if (controller.transactionMessage.contains("successfully")) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("✅ Transfer Successful"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Transaction Reference: ${controller.transactionReference}"),
              Text("New Balance: ${controller.transactionCurrencySymbol}${controller.expectedBalanceAfter}"),
              Text("Status: ${controller.transactionStatus}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm(controller);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.transactionMessage)),
      );
    }
  }

  void _navigateToTransferResult(bool success, String message) {
    final controller = Provider.of<WalletTransferController>(context, listen: false);

    if (success) {
      _resetForm(controller); // Clear the form first
    }

    Navigator.pushNamed(
      context,
      Routes.transfer_result,
      arguments: {
        'success': success,
        'message': message,
      },
    );
  }


  void showTransactionSummaryModal(WalletTransferController controller) async {
    final primaryColor = await _getColorFromPrefs('customized-app-primary-color', const Color(0xFF171E3B));
    final secondaryColor = await _getColorFromPrefs('customized-app-secondary-color', const Color(0xFFEB6D00));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          const Text("Transaction Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ListTile(title: const Text("Transaction Type"), subtitle: const Text("Wallet to Wallet Transfer")),
                          ListTile(title: const Text("Currency"), subtitle: Text(controller.transactionCurrency)),
                          ListTile(
                            title: const Text("Actual Balance Before"),
                            subtitle: Text("${controller.transactionCurrencySymbol} ${controller.actualBalanceBefore}"),
                          ),
                          ListTile(
                            title: const Text("Amount to Transfer"),
                            subtitle: Text("${controller.transactionCurrencySymbol} ${controller.amountProcessable}"),
                          ),
                          ListTile(
                            title: const Text("Platform Charge Fee"),
                            subtitle: Text("${controller.transactionCurrencySymbol} ${controller.platformChargeFee}"),
                          ),
                          ListTile(
                            title: const Text("Expected Balance After"),
                            subtitle: Text("${controller.transactionCurrencySymbol} ${controller.expectedBalanceAfter}"),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _pinController,
                            obscureText: _isPinHidden,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Transaction PIN",
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_isPinHidden ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _isPinHidden = !_isPinHidden),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (value) => value!.length != 4 ? "Enter a valid 4-digit PIN" : null,
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _secondaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text("Cancel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isCompletingTransfer
                                      ? null
                                      : () async {
                                    if (selectedSourceWallet == null) return;

                                    setModalState(() => _isCompletingTransfer = true);

                                    final result = await controller.completeTransfer(
                                      sourceWallet: selectedSourceWallet!,
                                      destinationWallet: _destWalletController.text.trim(),
                                      amount: controller.amountProcessable,
                                      description: _narrationController.text.trim(),
                                      transactionPin: _pinController.text.trim(),
                                    );

                                    if (mounted) {
                                      setModalState(() => _isCompletingTransfer = false);
                                      _navigateToTransferResult(result['success'], result['message']);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _secondaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text(
                                    "Proceed",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),

                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isCompletingTransfer)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              );
            },
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transferController = Provider.of<WalletTransferController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Wallet to Wallet Transfer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Source Wallet"),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedSourceWallet,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: transferController.sourceWallets.map((wallet) {
                  return DropdownMenuItem<String>(
                    value: wallet['account_number'],
                    child: Text(
                      "${wallet['account_number']} - (${wallet['available_balance']} NGN)",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedSourceWallet = value),
                validator: (value) => value == null ? "Please select a source wallet" : null,
              ),
              const SizedBox(height: 16),

              const Text("Destination wallet number"),
              TextFormField(
                controller: _destWalletController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (value) {
                  if (value.length == 10) {
                    transferController.verifyWalletNumber(value);
                  }
                },
                validator: (value) => value!.isEmpty ? "Wallet number is required" : null,
              ),
              const SizedBox(height: 8),

              Consumer<WalletTransferController>(builder: (context, controller, _) {
                if (controller.isVerifyingWallet) {
                  return const Center(child: CircularProgressIndicator());
                } else if (controller.beneficiaryName.isNotEmpty) {
                  return Text("Beneficiary: ${controller.beneficiaryName}",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
                } else {
                  return const Text("Enter destination wallet number", style: TextStyle(color: Colors.red));
                }
              }),
              const SizedBox(height: 16),

              const Text("Amount"),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                inputFormatters: [CurrencyInputFormatter()],
                validator: (value) => value!.isEmpty ? "Enter a valid amount" : null,
              ),
              const SizedBox(height: 16),

              const Text("Narration (Optional)"),
              TextFormField(
                controller: _narrationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Narration (Optional)",
                ),
              ),
              const SizedBox(height: 16),

              transferController.isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: transferController.isProcessing
                      ? null
                      : () {
                    if (_formKey.currentState!.validate()) {
                      if (selectedSourceWallet == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a source wallet")),
                        );
                        return;
                      }

                      transferController
                          .initializeTransfer(
                        sourceWallet: selectedSourceWallet!,
                        destinationWallet: _destWalletController.text.trim(),
                        amount: double.parse(_amountController.text.replaceAll(',', '').trim()),
                        description: _narrationController.text.trim(),
                      )
                          .then((_) => showTransactionSummaryModal(transferController));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Initialize Transfer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destWalletController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}

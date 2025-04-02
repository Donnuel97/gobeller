import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/utils/currency_input_formatter.dart';
import 'package:gobeller/controller/wallet_transfer_controller.dart';
import 'package:provider/provider.dart';

class WalletToWalletTransferPage extends StatefulWidget {
  const WalletToWalletTransferPage({super.key});

  @override
  State<WalletToWalletTransferPage> createState() =>
      _WalletToWalletTransferPageState();
}

class _WalletToWalletTransferPageState extends State<WalletToWalletTransferPage> {
  /// **Resets the form fields and clears beneficiary name**
  void _resetForm(WalletTransferController controller) {
    _formKey.currentState?.reset(); // Reset form validation state
    _destWalletController.clear();
    _amountController.clear();
    _narrationController.clear();
    _pinController.clear();
    setState(() {
      selectedSourceWallet = null; // Reset dropdown selection
    });

    // Clear the beneficiary name in the controller
    controller.clearBeneficiaryName();
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _destWalletController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String? selectedSourceWallet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transferController =
      Provider.of<WalletTransferController>(context, listen: false);
      transferController.fetchSourceWallets();
      transferController.clearBeneficiaryName(); // Clear name on load
    });
  }

  @override
  void dispose() {
    _destWalletController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  /// **Displays Transaction Summary & Confirmation**
  void showTransactionSummaryModal(WalletTransferController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows the modal to resize when the keyboard appears
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Transaction Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text("Transaction Type"),
                  subtitle: const Text("Wallet to Wallet Transfer"),
                ),
                ListTile(
                  title: const Text("Currency"),
                  subtitle: Text(controller.transactionCurrency),
                ),
                ListTile(
                  title: const Text("Actual Balance Before"),
                  subtitle: Text(
                      "${controller.transactionCurrencySymbol} ${controller.actualBalanceBefore}"),
                ),
                ListTile(
                  title: const Text("Amount to Transfer"),
                  subtitle: Text(
                      "${controller.transactionCurrencySymbol} ${controller.amountProcessable}"),
                ),
                ListTile(
                  title: const Text("Platform Charge Fee"),
                  subtitle: Text(
                      "${controller.transactionCurrencySymbol} ${controller.platformChargeFee}"),
                ),
                ListTile(
                  title: const Text("Expected Balance After"),
                  subtitle: Text(
                      "${controller.transactionCurrencySymbol} ${controller.expectedBalanceAfter}"),
                ),
                const SizedBox(height: 16),

                /// **Transaction PIN Input**
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Transaction PIN",
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) =>
                  value!.length != 4 ? "Enter a valid 4-digit PIN" : null,
                ),
                const SizedBox(height: 20),

                /// **Buttons: Cancel & Proceed**
                /// **Buttons: Cancel & Proceed**
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4, // 40% of screen width
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF171E3B), // Set button color
                          foregroundColor: Colors.white, // White text color
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Rounded corners
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4, // 40% of screen width
                      child: ElevatedButton(
                        onPressed: () {
                          controller.completeTransfer(
                            sourceWallet: selectedSourceWallet!,
                            destinationWallet: _destWalletController.text,
                            amount: controller.amountProcessable,
                            description: _narrationController.text,
                            transactionPin: _pinController.text,
                          ).then((_) {
                            Navigator.pop(context);
                            _showTransferResult(controller);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF171E3B), // Set button color
                          foregroundColor: Colors.white, // White text color
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Rounded corners
                          ),
                        ),
                        child: const Text(
                          "Proceed",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  /// **Shows Transfer Result Dialog**
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
              Text(
                  "New Balance: ${controller.transactionCurrencySymbol}${controller.expectedBalanceAfter}"),
              Text("Status: ${controller.transactionStatus}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm(controller); // Clear form after success
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

  @override
  Widget build(BuildContext context) {
    final transferController = Provider.of<WalletTransferController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Wallet to Wallet Transfer")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                  onChanged: (value) {
                    setState(() {
                      selectedSourceWallet = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? "Please select a source wallet" : null,
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
                  validator: (value) =>
                  value!.isEmpty ? "Wallet number is required" : null,
                ),
                const SizedBox(height: 8),

                Consumer<WalletTransferController>(
                  builder: (context, controller, _) {
                    if (controller.isVerifyingWallet) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (controller.beneficiaryName.isNotEmpty) {
                      return Text(
                        "Beneficiary: ${controller.beneficiaryName}",
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      );
                    } else {
                      return const Text(
                        "Enter destination wallet number",
                        style: TextStyle(color: Colors.red),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                const Text("Amount"),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (value) =>
                  value!.isEmpty ? "Enter a valid amount" : null,
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
                  width: double.infinity, // Makes the button full-width
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        transferController.initializeTransfer(
                          sourceWallet: selectedSourceWallet!,
                          destinationWallet: _destWalletController.text,
                          amount: double.parse(_amountController.text.replaceAll(',', '')),
                          description: _narrationController.text,
                        ).then((_) {
                          showTransactionSummaryModal(transferController);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEB6D00), // Set button color
                      foregroundColor: Colors.white, // White text color
                      padding: const EdgeInsets.symmetric(vertical: 16), // Better UX padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      "Initialize Transfer",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

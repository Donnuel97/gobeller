import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/utils/currency_input_formatter.dart';
import 'package:gobeller/controller/wallet_to_bank_controller.dart';
import 'package:provider/provider.dart';

class WalletToBankTransferPage extends StatefulWidget {
  const WalletToBankTransferPage({super.key});

  @override
  State<WalletToBankTransferPage> createState() => _WalletToBankTransferPageState();
}

class _WalletToBankTransferPageState extends State<WalletToBankTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String? selectedSourceWallet;
  String? selectedBank;
  String? selectedBankId;

  bool isLoading = false;
  bool _isPinHidden = true; // Add this as a class-level variable if not already declared

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
      controller.fetchBanks();
      controller.fetchSourceWallets();
      _resetForm();
    });
  }


  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    _pinController.dispose();
    super.dispose();
  }



  void _showTransactionSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Key line to adjust padding when keyboard is visible
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Transaction Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ListTile(title: const Text("Bank"), subtitle: Text(selectedBank ?? "Not Selected")),
                  ListTile(title: const Text("Account Number"), subtitle: Text(_accountNumberController.text)),
                  ListTile(title: const Text("Beneficiary"), subtitle: Text(context.read<WalletToBankTransferController>().beneficiaryName)),
                  ListTile(title: const Text("Amount"), subtitle: Text("₦ ${_amountController.text}")),
                  ListTile(title: const Text("Narration"), subtitle: Text(_narrationController.text.isNotEmpty ? _narrationController.text : "Wallet to Bank Transfer")),

                  const SizedBox(height: 16),

                  // PIN Input Field
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: _isPinHidden, // Toggle PIN visibility
                    decoration: InputDecoration(
                      labelText: "Transaction PIN",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPinHidden ? Icons.visibility_off : Icons.visibility, // Toggle icon for visibility
                        ),
                        onPressed: () => setState(() {
                          _isPinHidden = !_isPinHidden; // Toggle visibility on press
                        }),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Only digits allowed
                      LengthLimitingTextInputFormatter(4), // Max 4 digits
                    ],
                    validator: (value) => value!.length != 4 ? "Enter a valid 4-digit PIN" : null,
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons (Cancel and Proceed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Close the modal
                        child: const Text("Cancel"),
                      ),
                      Consumer<WalletToBankTransferController>(
                        builder: (context, controller, child) {
                          return ElevatedButton(
                            onPressed: controller.isProcessing || isLoading ? null : _confirmTransfer,
                            child: controller.isProcessing || isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Text("Proceed"),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }




  void _confirmTransfer() async {
    final controller = Provider.of<WalletToBankTransferController>(context, listen: false);

    setState(() {
      isLoading = true;
    });

    Navigator.pop(context); // Close the PIN modal

    final result = await controller.completeBankTransfer(
      sourceWallet: selectedSourceWallet!,
      destinationAccountNumber: _accountNumberController.text,
      bankId: selectedBankId!,
      amount: double.parse(_amountController.text.replaceAll(",", "")),
      description: _narrationController.text,
      transactionPin: _pinController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (!mounted) return;

    if (result['success']) {
      // 🔥 CLEAR the form if successful
      _resetForm();
    }

    Navigator.pushNamed(
      context,
      '/bank_result',
      arguments: {
        'success': result['success'],
        'message': result['message'],
        'data': result['data'],
      },
    );
  }


  void _showResultDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: message.contains("✅")
            ? const Text("✅ Transfer Successful")
            : const Text("❌ Transfer Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog

              if (message.contains("✅")) {
                // If successful, reload the page (reset everything)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
                  controller.fetchBanks();
                  controller.fetchSourceWallets();
                  controller.clearBeneficiaryName();
                });
                _resetForm();
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }


  void _resetForm() {
    _formKey.currentState?.reset();
    _accountNumberController.clear();
    _amountController.clear();
    _narrationController.clear();
    _pinController.clear();
    setState(() {
      selectedSourceWallet = null;
      selectedBank = null;
      selectedBankId = null;
    });

    final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
    controller.clearBeneficiaryName();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<WalletToBankTransferController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Wallet to Bank Transfer")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Source Wallet"),
                    DropdownButtonFormField<String>(
                      value: selectedSourceWallet,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: controller.sourceWallets.map((wallet) {
                        return DropdownMenuItem<String>(
                          value: wallet['account_number'],
                          child: Text("${wallet['account_number']} - (₦${wallet['available_balance']})"),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedSourceWallet = value),
                      validator: (value) => value == null ? "Please select a source wallet" : null,
                    ),
                    const SizedBox(height: 16),

                    const Text("Select Bank"),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedBank,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: controller.banks.map((bank) {
                        return DropdownMenuItem<String>(
                          value: bank['bank_code'],
                          child: Text(
                            bank['bank_name']!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBank = value;
                          selectedBankId = controller.banks.firstWhere(
                                (bank) => bank['bank_code'] == value,
                            orElse: () => {'id': 'Unknown'},
                          )['id'];
                        });
                      },
                      validator: (value) => value == null ? "Please select a bank" : null,
                    ),

                    const SizedBox(height: 16),

                    const Text("Account Number"),
                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Account Number",
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      onChanged: (value) {
                        if (value.length == 10 && selectedBankId != null) {
                          controller.verifyBankAccount(accountNumber: value, bankId: selectedBankId!);
                        }
                      },
                    ),

                    const SizedBox(height: 8),

                    controller.isVerifyingWallet
                        ? const CircularProgressIndicator()
                        : Text(
                      controller.beneficiaryName.isNotEmpty
                          ? "Beneficiary: ${controller.beneficiaryName}"
                          : "Enter account number to verify",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),


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

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _showTransactionSummary();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEB6D00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

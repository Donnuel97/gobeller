import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/utils/currency_input_formatter.dart';
import 'package:gobeller/controller/wallet_to_bank_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool saveBeneficiary = false;

  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  List<Map<String, dynamic>> filteredSuggestions = [];
  bool showSuggestions = false;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrimaryColorAndLogo();
      final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
      controller.fetchBanks();
      controller.fetchSourceWallets();
      controller.fetchSavedBeneficiaries(); // 👈 Add this
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


  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        setState(() {
          final primaryColorHex = data['customized-app-primary-color'];
          final secondaryColorHex = data['customized-app-secondary-color'];

          _primaryColor = primaryColorHex != null
              ? Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blue;

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blueAccent;

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {}
    }
  }
  void _showTransactionSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // keep this, but fix inside
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white, // 🧱 Add a white background
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // 🧈 Rounded top corners
            ),
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Transaction Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ListTile(title: const Text("Bank"), subtitle: Text(selectedBank ?? "Not Selected")),
                  ListTile(title: const Text("Account Number"), subtitle: Text(_accountNumberController.text)),
                  ListTile(title: const Text("Beneficiary"), subtitle: Text(context.read<WalletToBankTransferController>().beneficiaryName)),
                  ListTile(title: const Text("Amount"), subtitle: Text("₦ ${_amountController.text}")),
                  ListTile(title: const Text("Narration"), subtitle: Text(_narrationController.text.isNotEmpty ? _narrationController.text : "Wallet to Bank Transfer")),
                  ListTile(
                    title: const Text("Save as Beneficiary"),
                    subtitle: Text(saveBeneficiary ? "Yes" : "No"),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: _isPinHidden,
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
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.red, // White text color for Cancel
                        ),
                        child: const Text("Cancel"),
                      ),
                      Consumer<WalletToBankTransferController>(
                        builder: (context, controller, child) {
                          return ElevatedButton(
                            onPressed: controller.isProcessing || isLoading ? null : _confirmTransfer,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.green, // White text color for Proceed
                            ),
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
      saveBeneficiary: saveBeneficiary,
    );

    if (!mounted) return;

    // 🧠 Attempt to save beneficiary only if transfer succeeded
    if (saveBeneficiary && result["success"]) {
      final saveResult = await controller.saveBeneficiary(
        beneficiaryName: controller.beneficiaryName,
        accountNumber: _accountNumberController.text,
        bankId: selectedBankId!,
        transactionPin: _pinController.text,
        nickname: null,
      );

      // 🔁 Refresh saved beneficiaries list regardless of outcome
      await controller.fetchSavedBeneficiaries(); // ⬅️ Refetch and overwrite

      if (!saveResult["success"] &&
          !saveResult["message"]
              .toString()
              .contains("Beneficiary Identifier has already been taken")) {
        _showResultDialog("⚠️ Transfer succeeded, but saving beneficiary failed: ${saveResult["message"]}");
      }
    }

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      _resetForm(); // Reset form on success

      // ✅ Refetch and store beneficiaries
      await controller.fetchSavedBeneficiaries(); // This refetches and sets _savedBeneficiaries in controller

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_beneficiaries', jsonEncode(controller.savedBeneficiaries));
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

  void _showSavedBeneficiaries(BuildContext context) {
    final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
    final beneficiaries = controller.savedBeneficiaries;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Saved Beneficiaries", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: beneficiaries.isEmpty
                  ? const Center(child: Text("You have no beneficiaries saved.")) // Updated text here
                  : ListView.separated(
                itemCount: beneficiaries.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) {
                  final b = beneficiaries[index];
                  return ListTile(
                    title: Text(b['beneficiary_name'] ?? b['account_number']),
                    subtitle: Text("${b['bank_name']} - ${b['account_number']}"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      setState(() {
                        _accountNumberController.text = b["account_number"];
                        selectedBankId = b["bank_id"];
                        final bank = controller.banks.firstWhere(
                              (bk) => bk['id'].toString() == b['bank_id'],
                          orElse: () => {'bank_code': '', 'bank_name': ''},
                        );
                        selectedBank = bank['bank_code'];
                      });
                      controller.verifyBankAccount(
                        accountNumber: b["account_number"],
                        bankId: b["bank_id"],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
      appBar: AppBar(
        title: const Text("Wallet to Bank Transfer"),
        // actions: [
        //   TextButton.icon(
        //     icon: const Icon(Icons.people_alt_outlined, color: Colors.black),
        //     label: const Text(
        //       "Saved Beneficiary",
        //       style: TextStyle(color: Colors.black),
        //     ),
        //     onPressed: () {
        //       _showSavedBeneficiaries(context);
        //     },
        //   ),
        // ],
      ),



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
                    const SizedBox(height: 10),



                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showSavedBeneficiaries(context),
                          icon: const Icon(Icons.people_alt_outlined, size: 18),
                          label: const Text("Saved Beneficiary"),
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFFEB6D00), // 👈 Orange text
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),


                    const Text("Account Number"),
                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        // labelText: "Account Number",
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],

                      onChanged: (value) {
                        final controller = Provider.of<WalletToBankTransferController>(context, listen: false);

                        if (value.length >= 3) {
                          final suggestions = controller.savedBeneficiaries.where((b) {
                            return b['account_number'] != null &&
                                b['account_number'].toString().contains(value);
                          }).toList();

                          setState(() {
                            filteredSuggestions = suggestions;
                            showSuggestions = suggestions.isNotEmpty;
                          });
                        } else {
                          setState(() {
                            showSuggestions = false;
                          });
                        }

                        if (value.length == 10 && selectedBankId != null && selectedBankId != 'Unknown') {
                          controller.verifyBankAccount(
                            accountNumber: value,
                            bankId: selectedBankId!,
                          );
                        }
                      },


                    ),
                    const SizedBox(height: 16),
                    const Text("Select Bank"),
                    DropdownSearch<Map<String, String>>(
                      items: controller.banks.map<Map<String, String>>((bank) => {
                        "bank_code": bank["bank_code"].toString(),
                        "bank_name": bank["bank_name"].toString(),
                      }).toList(),
                      itemAsString: (bank) => bank["bank_name"]!,
                      selectedItem: controller.banks
                          .map<Map<String, String>>((bank) => {
                        "bank_code": bank["bank_code"].toString(),
                        "bank_name": bank["bank_name"].toString(),
                      })
                          .firstWhere(
                            (bank) => bank["bank_code"] == selectedBank,
                        orElse: () => {"bank_code": "", "bank_name": "Select Bank"},
                      ),
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          border: OutlineInputBorder(),
                          // labelText: "Select Bank",
                        ),
                      ),

                      onChanged: (value) {
                        setState(() {
                          selectedBank = value?["bank_code"];
                          selectedBankId = controller.banks.firstWhere(
                                (bank) => bank['bank_code'].toString() == selectedBank,
                            orElse: () => {'id': null},
                          )['id']?.toString();
                        });

                        // ✅ Trigger verification if account number is already 10 digits
                        final accountNumber = _accountNumberController.text;
                        if (accountNumber.length == 10 && selectedBankId != null && selectedBankId != 'Unknown') {
                          controller.verifyBankAccount(
                            accountNumber: accountNumber,
                            bankId: selectedBankId!,
                          );
                        }
                      },



                      validator: (value) => value == null ? "Please select a bank" : null,
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(labelText: "Search Bank"),
                        ),
                      ),
                    ),



                    if (showSuggestions)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredSuggestions.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            final suggestion = filteredSuggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                suggestion['beneficiary_name'] ?? suggestion['account_number'],
                                style: TextStyle(color: Color(0xFFEB6D00)),
                              ),
                              subtitle: Text(
                                "${suggestion['bank_name']} - ${suggestion['account_number']}",
                                style: TextStyle(color: Color(0xFFEB6D00)),
                              ),

                              onTap: () {
                                setState(() {
                                  _accountNumberController.text = suggestion['account_number'];
                                  selectedBankId = suggestion['bank_id'];
                                  showSuggestions = false;

                                  final bank = controller.banks.firstWhere(
                                        (bk) => bk['id'].toString() == suggestion['bank_id'],
                                    orElse: () => {'bank_code': '', 'bank_name': ''},
                                  );
                                  selectedBank = bank['bank_code'];
                                });

                                controller.verifyBankAccount(
                                  accountNumber: suggestion['account_number'],
                                  bankId: suggestion['bank_id'],
                                );
                              },
                            );
                          },
                        ),
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
                        // labelText: "Narration (Optional)",
                      ),
                    ),

                    CheckboxListTile(
                      title: const Text("Save as Beneficiary"),
                      value: saveBeneficiary,
                      onChanged: (value) {
                        setState(() {
                          saveBeneficiary = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
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
                          backgroundColor: _primaryColor,
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

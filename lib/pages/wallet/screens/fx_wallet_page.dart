import 'package:flutter/material.dart';
import 'package:gobeller/controller/WalletController.dart';
import 'package:gobeller/controller/create_wallet_controller.dart';
import 'widget/wallet_list.dart';

class FXWalletPage extends StatefulWidget {
  const FXWalletPage({super.key});

  @override
  _FXWalletPageState createState() => _FXWalletPageState();
}

class _FXWalletPageState extends State<FXWalletPage> {
  List<Map<String, dynamic>> wallets = [];
  bool isLoading = true;
  bool hasError = false;

  List<dynamic> currencies = [];
  bool isCurrencyLoading = true;
  String selectedCurrencyId = '';

  List<Map<String, dynamic>> walletTypes = [];
  bool isWalletTypeLoading = true;
  String selectedWalletTypeId = '';

  List<Map<String, dynamic>> banks = [];
  bool isBanksLoading = true;
  String selectedBankId = '';

  String selectedAccountType = 'internal-account';

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadCurrencies();
    _loadWalletTypes();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    try {
      if (!mounted) return;
      setState(() => isBanksLoading = true);

      final response = await CurrencyController.fetchBanks();
      if (!mounted) return;

      if (response != null && response.isNotEmpty) {
        setState(() {
          banks = response;
          isBanksLoading = false;
        });
      } else {
        setState(() => isBanksLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isBanksLoading = false);
    }
  }

  Future<void> _loadWallets() async {
    try {
      final walletData = await WalletController.fetchWallets();
      if (!mounted) return;

      if (walletData.isNotEmpty) {
        setState(() {
          wallets = [
            {
              "name": "Main Wallet",
              "wallet_number": walletData["wallet_number"],
              "balance": double.tryParse(walletData["balance"]!) ?? 0.0,
              "currency": "₦",
            }
          ];
          hasError = false;
        });
      } else {
        setState(() {
          wallets = [];
          hasError = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => hasError = true);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCurrencies() async {
    try {
      if (!mounted) return;
      setState(() => isCurrencyLoading = true);

      final response = await CurrencyController.fetchCurrencies();
      if (!mounted) return;

      if (response != null && response.isNotEmpty) {
        setState(() {
          currencies = response;
          isCurrencyLoading = false;
        });
      } else {
        setState(() => isCurrencyLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isCurrencyLoading = false);
    }
  }

  Future<void> _loadWalletTypes() async {
    try {
      if (!mounted) return;
      setState(() => isWalletTypeLoading = true);

      final response = await CurrencyController.fetchWalletTypes();
      if (!mounted) return;

      if (response != null && response.isNotEmpty) {
        setState(() {
          walletTypes = response;
          isWalletTypeLoading = false;
        });
      } else {
        setState(() => isWalletTypeLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isWalletTypeLoading = false);
    }
  }

  void _createNewWallet(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Create New FX Wallet"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Account Type"),
                      items: const [
                        DropdownMenuItem(
                          value: "internal-account",
                          child: Text("Internal Account"),
                        ),

                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedAccountType = value!;
                          selectedBankId = '';
                        });
                      },
                      value: selectedAccountType,
                    ),

                    const SizedBox(height: 20),

                    isCurrencyLoading
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Currency"),
                      items: currencies.map<DropdownMenuItem<String>>((currency) {
                        return DropdownMenuItem<String>(
                          value: currency["id"],
                          child: Text(currency["name"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedCurrencyId = value!;
                        });
                      },
                      value: selectedCurrencyId.isNotEmpty ? selectedCurrencyId : null,
                    ),

                    const SizedBox(height: 20),

                    isWalletTypeLoading
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Wallet Type"),
                      items: walletTypes.map<DropdownMenuItem<String>>((walletType) {
                        return DropdownMenuItem<String>(
                          value: walletType["id"],
                          child: Text(walletType["name"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedWalletTypeId = value!;
                        });
                      },
                      value: selectedWalletTypeId.isNotEmpty ? selectedWalletTypeId : null,
                    ),

                    const SizedBox(height: 20),

                    if (selectedAccountType == 'virtual-account')
                      isBanksLoading
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Bank"),
                        items: banks.map<DropdownMenuItem<String>>((bank) {
                          return DropdownMenuItem<String>(
                            value: bank["id"],
                            child: Text(bank["name"]),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedBankId = value!;
                          });
                        },
                        value: selectedBankId.isNotEmpty ? selectedBankId : null,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedAccountType == 'virtual-account' && selectedBankId.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a bank for virtual accounts.")),
                        );
                      }
                      return;
                    }

                    final requestBody = {
                      "account_type": selectedAccountType,
                      if (selectedAccountType == 'virtual-account') "bank_id": selectedBankId,
                      "wallet_type_id": selectedWalletTypeId,
                      "currency_id": selectedCurrencyId,
                    };

                    debugPrint("📤 Creating Wallet with body: $requestBody");

                    try {
                      final result = await CurrencyController.createWallet(requestBody);
                      debugPrint("✅ Wallet creation response: $result");

                      if (result["status"] == "error" || result["status"] == false) {
                        final errorMsg = result["message"] ?? "Something went wrong while creating wallet.";
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg)),
                          );
                        }
                      } else {
                        await _loadWallets();
                        if (!mounted) return;

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Wallet created successfully")),
                          );
                          setState(() {
                            selectedCurrencyId = '';
                            selectedWalletTypeId = '';
                            selectedBankId = '';
                            selectedAccountType = 'internal-account';
                          });
                          Navigator.of(context).pop();
                        }
                      }
                    } catch (e) {
                      final cleanedMessage = e.toString().replaceFirst('Exception: ', '');
                      debugPrint("❌ Wallet creation failed: $cleanedMessage");

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(cleanedMessage)),
                        );
                      }
                    }
                  },
                  child: const Text("Create Wallet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FX Wallets")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? const Center(child: Text("Failed to load wallets. Try again."))
          : wallets.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                "No available wallet.",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _createNewWallet(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Create Wallet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [
          Expanded(child: WalletList(wallets: wallets)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _createNewWallet(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Create New FX Wallet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gobeller/controller/WalletController.dart';
import 'package:gobeller/controller/create_wallet_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String selectedAccountType = 'virtual-account';

  bool isCreatingWallet = false;
  bool isWalletsLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _loadWallets(),
        _loadCurrencies(),
        _loadWalletTypes(),
        _loadBanks(),
      ]);
      hasError = false;
    } catch (e) {
      hasError = true;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadWallets() async {
    try {
      if (!mounted) return;
      setState(() => isWalletsLoading = true);

      final walletData = await WalletController.fetchWallets();
      if (!mounted) return;

      if (walletData.isNotEmpty) {
        final data = walletData['data'];
        if (data is List) {
          setState(() {
            wallets = List<Map<String, dynamic>>.from(data.map((wallet) {
              return {
                "type": wallet["ownership_type"] ?? "Normal wallet",
                "name": wallet["bank"]?["name"] ?? "Unknown Bank",
                "wallet_number": wallet["wallet_number"] ?? "N/A",
                "balance": double.tryParse(wallet["balance"]?.toString() ?? "0.0") ?? 0.0,
                "currency": wallet["currency"]?["symbol"] ?? "₦",
                "bank_code": wallet["bank"]?["code"] ?? "N/A",
              };
            }));
            hasError = false;
          });
        } else {
          setState(() {
            wallets = [];
            hasError = true;
          });
        }
      } else {
        setState(() {
          wallets = [];
          hasError = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => hasError = true);

      if (e.toString().contains('401')) {
        debugPrint("❌ 401 Unauthorized error detected. Reloading wallets...");
        await _loadWallets();  // Retry fetching wallets
      }
    } finally {
      if (!mounted) return;
      setState(() => isWalletsLoading = false);
    }
  }

  Future<void> _loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (!mounted) return;
      setState(() => isCurrencyLoading = true);

      final cachedCurrencies = prefs.getString('cachedCurrencies');
      if (cachedCurrencies != null) {
        final decoded = jsonDecode(cachedCurrencies);
        if (decoded is List) {
          setState(() => currencies = decoded);
        }
      }

      final response = await CurrencyController.fetchCurrencies();
      if (response != null) {
        setState(() => currencies = response);
        prefs.setString('cachedCurrencies', jsonEncode(response));
      }
    } catch (e) {
      debugPrint("Failed to load currencies: $e");
    } finally {
      if (!mounted) return;
      setState(() => isCurrencyLoading = false);
    }
  }

  Future<void> _loadBanks() async {
    try {
      if (!mounted) return;
      setState(() => isBanksLoading = true);

      final response = await CurrencyController.fetchBanks();
      if (!mounted) return;

      setState(() {
        banks = response ?? [];
        isBanksLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isBanksLoading = false);
    }
  }

  Future<void> _loadWalletTypes() async {
    try {
      if (!mounted) return;
      setState(() => isWalletTypeLoading = true);

      final response = await CurrencyController.fetchWalletTypes();
      if (!mounted) return;

      setState(() {
        walletTypes = response ?? [];
        isWalletTypeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isWalletTypeLoading = false);
    }
  }

  // Future<void> _loadBanks() async {
  //   try {
  //     if (!mounted) return;
  //     setState(() => isBanksLoading = true);
  //
  //     final response = await CurrencyController.fetchBanks();
  //     if (!mounted) return;
  //
  //     setState(() {
  //       banks = response ?? [];
  //       isBanksLoading = false;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() => isBanksLoading = false);
  //   }
  // }

  void _createNewWallet(BuildContext context) {
    if (isCurrencyLoading || isWalletTypeLoading || isBanksLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait, loading options...")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !isCreatingWallet,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Stack(
              children: [
                AlertDialog(
                  title: const Text("Create New FX Wallet"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Account Type"),
                          items: const [
                            DropdownMenuItem(
                              value: "virtual-account",
                              child: Text("Virtual Account"),
                            ),
                          ],
                          onChanged: null,
                          value: "virtual-account",
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
                          isExpanded: true,
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
                            items: banks.isNotEmpty
                                ? banks.map<DropdownMenuItem<String>>((bank) {
                              return DropdownMenuItem<String>(
                                value: bank["id"],
                                child: Text(bank["name"]),
                              );
                            }).toList()
                                : [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text("No banks available"),
                              ),
                            ],
                            onChanged: banks.isNotEmpty
                                ? (value) {
                              setStateDialog(() {
                                selectedBankId = value!;
                              });
                            }
                                : null,
                            value: banks.isNotEmpty
                                ? (selectedBankId.isNotEmpty ? selectedBankId : null)
                                : '',
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
                      onPressed: isCreatingWallet
                          ? null
                          : () async {
                        if (selectedCurrencyId.isEmpty || selectedWalletTypeId.isEmpty || (selectedAccountType == 'virtual-account' && selectedBankId.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields.")));
                          return;
                        }

                        final requestBody = {
                          "account_type": selectedAccountType,
                          if (selectedAccountType == 'virtual-account') "bank_id": selectedBankId,
                          "wallet_type_id": selectedWalletTypeId,
                          "currency_id": selectedCurrencyId,
                        };

                        setStateDialog(() => isCreatingWallet = true);

                        try {
                          final result = await CurrencyController.createWallet(requestBody);

                          if (result["status"] == "success" || result["status"] == true) {
                            await _loadWallets();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wallet created successfully.")));

                            setState(() {
                              selectedCurrencyId = '';
                              selectedWalletTypeId = '';
                              selectedBankId = '';
                              selectedAccountType = 'internal-account';
                            });

                            Navigator.of(context).pop();
                          } else {
                            final errorMsg = result["message"] ?? "Something went wrong.";
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
                          }
                        } catch (e) {
                          final errorMsg = e.toString().replaceFirst("Exception: ", "");
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
                        } finally {
                          setStateDialog(() => isCreatingWallet = false);
                        }
                      },
                      child: const Text("Create Wallet"),
                    ),
                  ],
                ),
                if (isCreatingWallet)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
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
      appBar: AppBar(title: const Text("FX Wallets")),
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
              const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("No available wallet.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _createNewWallet(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Create Wallet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: WalletList(
              wallets: wallets,
              isLoading: isWalletsLoading,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _createNewWallet(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

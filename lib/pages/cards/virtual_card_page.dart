import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/pages/success/widget/bottom_nav_bar.dart';
import 'package:gobeller/controller/cards_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/kyc_controller.dart';
import '../../utils/routes.dart';

class VirtualCardPage extends StatefulWidget {
  const VirtualCardPage({super.key});

  @override
  _VirtualCardPageState createState() => _VirtualCardPageState();
}

class _VirtualCardPageState extends State<VirtualCardPage> {
  bool _shouldShowKycButton = false;
  bool _kycLoading = true;

  Color? _primaryColor;
  Color? _secondaryColor;
  bool _isLoading = false; // Add this at the top of your StatefulWidget class
  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
    _checkKycStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VirtualCardController>(context, listen: false).fetchVirtualCards();
    });
  }


  void _checkKycStatus() async {
    final kycVerifications = await KycVerificationController.fetchKycVerifications();

    if (kycVerifications != null && kycVerifications.isNotEmpty) {
      final usedTypes = kycVerifications
          .map((e) => (e['documentType'] as String).toUpperCase())
          .toList();

      if (!(usedTypes.contains('NIN') && usedTypes.contains('BVN'))) {
        setState(() {
          _shouldShowKycButton = true;
        });
      }
    } else {
      setState(() {
        _shouldShowKycButton = true; // Show button if there's no verification
      });
    }

    setState(() {
      _kycLoading = false;
    });
  }


  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'] ?? "#2196F3";
      final secondaryColorHex = data['customized-app-secondary-color'] ?? "#1976D2";

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDisabled = false, // <-- Now it supports disabling
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            backgroundColor: _primaryColor?.withOpacity(0.15) ?? Colors.grey.withOpacity(0.15),
            foregroundColor: _primaryColor ?? Colors.blue,
            radius: 28,
            child: Icon(icon, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<VirtualCardController>(context);

    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: KycVerificationController.fetchKycVerifications(),
      builder: (context, snapshot) {
        final kycData = snapshot.data ?? [];
        final usedTypes = kycData
            .map((item) => (item['documentType'] as String?)?.toUpperCase())
            .whereType<String>()
            .toList();

        final bool hasBvn = usedTypes.contains('BVN');
        final bool hasNin = usedTypes.contains('NIN');
        final bool isKycComplete = hasBvn && hasNin;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Virtual Card"),
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: controller.virtualCards.isEmpty
                    ? Center(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
                      : isKycComplete
                      ? ElevatedButton.icon(
                    onPressed: () => _showCreateCardModal(context, controller),
                    icon: const Icon(Icons.add),
                    label: const Text("Create Virtual Card"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor ?? Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  )
                      : ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    icon: const Icon(Icons.warning),
                    label: const Text("Complete KYC"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                )
                    : _buildCardContent(controller.virtualCards.first),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 2,
            onTabSelected: (index) {
              if (index != 2) {
                Navigator.pushReplacementNamed(context, _getRouteForIndex(index));
              }
            },
          ),
        );
      },
    );
  }




  Widget _buildCardContent(Map<String, dynamic> card) {
    final metadataRaw = card["card_response_metadata"];
    final decodedMeta = metadataRaw != null ? jsonDecode(metadataRaw) : {};
    final String cardNumber = card["masked_card_number"] ?? "**** **** **** ****";
    final String expiryDate = card["expiration_date"] ?? "--/--";
    final String cvv = decodedMeta["cvv"] ?? "***";
    final String name = decodedMeta["name"] ?? "Card Holder";
    final String currency = card["currency"] ?? "NGN";
    final dynamic balanceRaw = card["balance"];
    final String balance = balanceRaw != null ? balanceRaw.toString() : "--";

    // Whether the card is currently merchant-locked (frozen)
    final bool isLocked = card["is_amount_locked"] == true;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Information Section
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _secondaryColor,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Virtual Card",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  cardNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Exp: $expiryDate",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      "CVV: $cvv",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons (Details, Add Money, Freeze/Unfreeze)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.info_outline,
                label: 'Details',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.card_details,
                    arguments: card,
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Add Money',
                onTap: isLocked
                    ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Your card is frozen. Please unfreeze it to add money.",
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                    : () => _showAddMoneyModal(context, card),
                isDisabled: isLocked, // <-- Disable Add Money if locked
              ),
              _buildActionButton(
                icon: isLocked ? Icons.lock_open : Icons.lock_outline,
                label: isLocked ? 'Unfreeze' : 'Freeze',
                onTap: () async {
                  final rootCtx = context;
                  final scaffold = ScaffoldMessenger.of(rootCtx);
                  final controller = Provider.of<VirtualCardController>(rootCtx, listen: false);

                  final dialogCtx = await _showLoadingDialog(rootCtx);

                  try {
                    final result = await controller.toggleCardLockStatus(
                      card["id"],
                      isLocked,
                    );

                    if (Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx);

                    scaffold.showSnackBar(
                      SnackBar(
                        content: Text(result),
                        backgroundColor: result.toLowerCase().contains("success")
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                  } catch (e) {
                    if (Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx);
                    scaffold.showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString()}")),
                    );
                  }
                },
              ),
            ],
          ),

          // Extra info if card is locked
          if (isLocked) ...[
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: Colors.redAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Your card is frozen. Unfreeze to perform transactions.",
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          const Text(
            "Manage your virtual card securely.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }






  void _showAddMoneyModal(BuildContext context, Map<String, dynamic> card) {
    final BuildContext rootContext = context; // Save the parent context
    final TextEditingController amountController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(rootContext);
    final controller = Provider.of<VirtualCardController>(rootContext, listen: false);

    String? selectedWallet;

    controller.fetchWallets();

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Consumer<VirtualCardController>(
            builder: (context, controller, child) {
              final wallets = controller.sourceWallets;
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Add Money to Card", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    wallets.isEmpty
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                      value: selectedWallet,
                      items: wallets.map((wallet) {
                        final walletName = wallet["wallet_name"] ?? "Wallet";
                        final walletNumber = wallet["wallet_number"] ?? "";
                        final uuid = wallet["id"] ?? "";

                        return DropdownMenuItem<String>(
                          value: walletNumber.isNotEmpty ? walletNumber : uuid,
                          child: Text("$walletName - $walletNumber"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedWallet = value;
                      },
                      decoration: const InputDecoration(
                        labelText: "Select Source Wallet",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Enter Amount",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () async {
                        final amountText = amountController.text.trim();
                        if (selectedWallet == null || amountText.isEmpty || double.tryParse(amountText) == null) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text("Please select a wallet and enter valid amount")),
                          );
                          return;
                        }

                        Navigator.pop(context); // Close bottom sheet

                        final dialogContext = await _showLoadingDialog(rootContext);

                        try {
                          final virtualCardId = card["id"] ?? "";

                          final initResponse = await controller.initiateCardFunding(
                            sourceWalletNumberOrUuid: selectedWallet!,
                            fundingAmount: double.parse(amountText),
                            virtualCardId: virtualCardId,
                          );

                          if (Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext);
                          }

                          if (initResponse["status"] == true) {
                            final proceed = await _showFundingDetailsDialog(rootContext, initResponse["data"]);

                            if (proceed == true) {
                              // 🔥 ASK for PIN before processing funding
                              final transactionPin = await _showPinInputDialog(rootContext);

                              if (transactionPin != null) {
                                final processDialogContext = await _showLoadingDialog(rootContext);

                                final processResult = await controller.processCardFunding(
                                  sourceWalletNumberOrUuid: selectedWallet!,
                                  fundingAmount: double.parse(amountText),
                                  virtualCardId: virtualCardId,
                                  transactionPin: transactionPin, // Pass PIN here
                                );

                                if (Navigator.canPop(processDialogContext)) {
                                  Navigator.pop(processDialogContext);
                                }

                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(processResult),
                                    backgroundColor: processResult.contains("success") ? Colors.green : Colors.red,
                                  ),
                                );

                                if (processResult.contains("success")) {
                                  await Future.delayed(const Duration(milliseconds: 500));
                                  controller.fetchVirtualCards();
                                }
                              }
                            }
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text(initResponse["message"])),
                            );
                          }
                        } catch (e, stack) {
                          if (Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext);
                          }
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text("Failed to fund card: ${e.toString()}")),
                          );
                          debugPrint("❌ Error funding card: $e");
                          debugPrintStack(stackTrace: stack);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _secondaryColor ?? Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Add Money"),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  // FUND CARD DETAILS
  Future<bool?> _showFundingDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    final sourceAmount = data["source_wallet_debit_amount"];
    final sourceCurrency = data["source_wallet_currency_symbol"];
    final destAmount = data["destination_card_final_amount"];
    final destCurrency = data["destination_card_currency_symbol"];
    final exchangeRate = data["exchange_rate"];

    final BuildContext rootContext = context; // Save the parent context
    final scaffoldMessenger = ScaffoldMessenger.of(rootContext);

    return showModalBottomSheet<bool>(
      context: rootContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Confirm Funding Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Display funding details in text format
                _buildDetailRow("Source Amount:", "$sourceCurrency$sourceAmount"),
                const SizedBox(height: 12),
                _buildDetailRow("Destination Amount:", "$destCurrency$destAmount"),
                const SizedBox(height: 12),
                _buildDetailRow("Exchange Rate:", "$exchangeRate"),
                const SizedBox(height: 24),

                // Proceed & Cancel buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _secondaryColor ?? Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Proceed"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper method to build a detail row with title and value
  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "$title ",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }


  // FUND CARD PIN MODAL
  Future<String?> _showPinInputDialog(BuildContext context) async {
    final TextEditingController pinController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners for dialog
          ),
          title: const Text(
            "Enter Transaction PIN",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: "Enter 4-digit PIN",
                counterText: "",  // Hides the character counter
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                "Cancel",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            // Confirm button
            ElevatedButton(
              onPressed: () {
                final enteredPin = pinController.text.trim();
                if (enteredPin.length == 4) {
                  Navigator.pop(context, enteredPin);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("PIN must be 4 digits")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondaryColor ?? Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "Confirm",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }


  // CREATE CARD MODAL
  void _showCreateCardModal(BuildContext context, VirtualCardController controller) {
    final TextEditingController pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Create Virtual Card", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: "Enter 4-digit PIN",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    if (pin.length != 4) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text("PIN must be exactly 4 digits")),
                      );
                      return;
                    }

                    Navigator.pop(context); // Close bottom sheet first

                    // Now show loading dialog
                    final dialogContext = await _showLoadingDialog(context);

                    try {
                      final result = await controller.createVirtualCard(
                        context: dialogContext,
                        cardPin: pin,
                      );

                      if (Navigator.canPop(dialogContext)) {
                        Navigator.pop(dialogContext); // close the loading
                      }

                      // Now show success/failure message
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(result),
                          backgroundColor: result.contains("successfully") ? Colors.green : Colors.red,
                        ),
                      );

                      if (result.contains("successfully")) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        controller.fetchVirtualCards();
                      }

                    } catch (e, stack) {
                      if (Navigator.canPop(dialogContext)) {
                        Navigator.pop(dialogContext); // close loading
                      }

                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text("Failed to create card: ${e.toString()}")),
                      );

                      debugPrint("❌ Error creating card: $e");
                      debugPrintStack(stackTrace: stack);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondaryColor ?? Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Create Card"),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper function to show loading dialog properly
  Future<BuildContext> _showLoadingDialog(BuildContext context) async {
    final completer = Completer<BuildContext>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        completer.complete(ctx);
        return Dialog(
          backgroundColor: Colors.transparent, // Transparent background
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
        );
      },
    );

    return completer.future;
  }






  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return "/";
      case 1:
        return "/wallet";
      case 2:
        return "/virtualCard";
      case 3:
        return "/profile";
      default:
        return "/";
    }
  }
}

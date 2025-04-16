import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/pages/success/widget/bottom_nav_bar.dart';
import 'package:gobeller/controller/cards_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/routes.dart';

class VirtualCardPage extends StatefulWidget {
  const VirtualCardPage({super.key});

  @override
  _VirtualCardPageState createState() => _VirtualCardPageState();
}

class _VirtualCardPageState extends State<VirtualCardPage> {
  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VirtualCardController>(context, listen: false).fetchVirtualCards();
    });
  }
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
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

  Future<void> _loadPrimaryColor() async {
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

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<VirtualCardController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Virtual Card"),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.virtualCards.isEmpty
          ? Center(
        child: ElevatedButton.icon(
          onPressed: () {
            _showCreateCardModal(context, controller);
          },
          icon: const Icon(Icons.add),
          label: const Text("Create Virtual Card"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _secondaryColor ?? Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      )
          : _buildCardContent(controller.virtualCards.first),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) {
            Navigator.pushReplacementNamed(context, _getRouteForIndex(index));
          }
        },
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> card) {
    final String cardNumber = card["masked_card_number"] ?? "**** **** **** ****";
    final String expiryDate = card["expiration_date"] ?? "--/--";
    final String cvv = jsonDecode(card["card_response_metadata"] ?? '{}')["cvv"] ?? "***";
    final String name = jsonDecode(card["card_response_metadata"] ?? '{}')["name"] ?? "Card Holder";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                onTap: () {
                  // TODO: Trigger add money flow
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add money to card")));
                },
              ),
              _buildActionButton(
                icon: Icons.lock_outline,
                label: 'Freeze',
                onTap: () {
                  // TODO: Trigger freeze/unfreeze logic
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Card frozen")));
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Manage your virtual card securely.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }


  void _showCreateCardModal(BuildContext context, VirtualCardController controller) {
    final TextEditingController pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
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
                "Create Virtual Card",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("PIN must be exactly 4 digits")),
                    );
                    return;
                  }

                  Navigator.pop(context); // Close modal
                  final result = await controller.createVirtualCard(cardPin: pin);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result)),
                    );
                  }

                  await controller.fetchVirtualCards(); // Refresh after creation
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
        );
      },
    );
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

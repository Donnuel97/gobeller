import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/cards_controller.dart';

class CardDetailsPage extends StatelessWidget {
  final Map<String, dynamic> card;

  const CardDetailsPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final String cardId = card["id"] ?? "";
    final String cardNumber = card["card_number"] ?? "**** **** **** ****";
    final String expiryDate = card["expiration_date"] ?? "--/--";
    final String cvv = jsonDecode(card["card_response_metadata"] ?? '{}')["cvv"] ?? "***";
    final String name = jsonDecode(card["card_response_metadata"] ?? '{}')["name"] ?? "Card Holder";

    final controller = Provider.of<VirtualCardController>(context, listen: false);

    controller.fetchCardBalanceDetails(cardId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Card Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Card Holder", style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),
                const Text("Card Number", style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cardNumber,
                        style: const TextStyle(fontSize: 18, letterSpacing: 2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: cardNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Card number copied to clipboard")),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Expiry", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(expiryDate, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("CVV", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(cvv, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Text(
                  "The Card Address is the same as your residential address for online transaction or purchase",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                // Displaying Balance and Address
                FutureBuilder<void>(
                  future: controller.fetchCardBalanceDetails(cardId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text("Error fetching card balance: ${snapshot.error}");
                    } else {
                      final cardInfo = controller.cardDetails[cardId];
                      final balance = cardInfo?["balance"];
                      final address = cardInfo?["address"];
                      final street = address?["street"] ?? "N/A";
                      final city = address?["city"] ?? "N/A";
                      final state = address?["state"] ?? "N/A";
                      final postalCode = address?["postal_code"] ?? "N/A";
                      final country = address?["country"] ?? "N/A";

                      String balanceText;
                      if (balance == null || (balance is num && balance == 0)) {
                        balanceText = "No Balance Available";
                      } else {
                        balanceText = "\$${balance.toString()}";
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Balance", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            balanceText,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: balanceText == "No Balance Available" ? Colors.red : Colors.black,
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Text("Address", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            "$street, $city, $state, $postalCode, $country",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 30),
                const Text(
                  "This is your virtual card detail. Keep your card data secure and do not share sensitive information.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

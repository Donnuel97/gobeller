import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CardDetailsPage extends StatelessWidget {
  final Map<String, dynamic> card;

  const CardDetailsPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final String cardNumber = card["card_number"] ?? "**** **** **** ****";
    final String expiryDate = card["expiration_date"] ?? "--/--";
    final String cvv = jsonDecode(card["card_response_metadata"] ?? '{}')["cvv"] ?? "***";
    final String name = jsonDecode(card["card_response_metadata"] ?? '{}')["name"] ?? "Card Holder";

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
                // Text(cardNumber, style: const TextStyle(fontSize: 18, letterSpacing: 2)),
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

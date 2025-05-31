import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final String type;
  final String amount;
  final String date;
  final String currencySymbol; // Added this

  const TransactionTile({
    Key? key,
    required this.type,
    required this.amount,
    required this.date,
    required this.currencySymbol, // Ensure it's required
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        type.toUpperCase(), // Show "CREDIT" or "DEBIT"
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(date), // Display date
      trailing: Text(
        "$currencySymbol$amount", // Use currency symbol from response
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: type.toLowerCase() == "credit" ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}

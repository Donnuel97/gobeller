import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Import intl package for formatting

class UserInfoCard extends StatefulWidget {
  final String username;
  final String accountNumber;
  final String balance;
  final String bankName; // Added bank name field

  const UserInfoCard({
    super.key,
    required this.username,
    required this.accountNumber,
    required this.balance,
    required this.bankName, // Added bank name parameter
  });

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  bool _isBalanceHidden = true;

  @override
  Widget build(BuildContext context) {
    // Format balance with comma separators and two decimal places
    String formattedBalance = NumberFormat("#,##0.00").format(double.parse(widget.balance));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161D3A), // Updated background color to HEX #161D3A
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Greeting
          Text(
            "Hello, ${widget.username} 👋",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),

          // Account Number + Copy Button
          Row(
            children: [
              Text(
                "Acct: ${widget.accountNumber}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Account number copied!")),
                  );
                },
                child: const Icon(Icons.copy, color: Colors.white, size: 18),
              ),
            ],
          ),

          // Bank Name (Now Bigger)
          const SizedBox(height: 5),
          Text(
            widget.bankName, // Display the bank name
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70), // Slightly bigger
          ),

          const SizedBox(height: 10),

          // Wallet Balance & Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBalanceHidden ? "****" : "₦$formattedBalance",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: Icon(_isBalanceHidden ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isBalanceHidden = !_isBalanceHidden;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

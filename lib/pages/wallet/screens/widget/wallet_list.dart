import 'package:flutter/material.dart';

class WalletList extends StatelessWidget {
  final List<Map<String, dynamic>> wallets;
  final bool isLoading; // <-- new field to know if loading

  const WalletList({
    super.key,
    required this.wallets,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (wallets.isEmpty) {
      return const Center(
        child: Text(
          "No wallets found.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        var wallet = wallets[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: const Text('W', style: TextStyle(color: Colors.white)),
            ),
            title: Text(
              wallet["name"] ?? "Unknown Bank",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Balance: ${wallet["balance"] ?? "N/A"}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

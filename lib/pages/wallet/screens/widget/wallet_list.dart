import 'package:flutter/material.dart';

class WalletList extends StatelessWidget {
  final List<Map<String, dynamic>> wallets;

  const WalletList({super.key, required this.wallets});

  @override
  Widget build(BuildContext context) {
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
              child: Text(wallet["currency"], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(wallet["name"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text("${wallet["currency"]} ${wallet["balance"].toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

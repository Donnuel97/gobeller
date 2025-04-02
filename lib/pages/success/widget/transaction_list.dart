import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/WalletTransactionController.dart';
import 'transaction_tile.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  bool _showFullTransactions = false;
  late WalletTransactionController _walletTransactionController;

  @override
  void initState() {
    super.initState();
    _walletTransactionController = Provider.of<WalletTransactionController>(context, listen: false);
    _walletTransactionController.fetchWalletTransactions();
  }

  /// **Opens modal to show full transaction details**
  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true, // Enables smooth scrolling
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Transaction Details",
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      title: const Text("Transaction Type"),
                      subtitle: Text(transaction["transaction_type"] ?? "Unknown"),
                    ),
                    ListTile(
                      title: const Text("Amount"),
                      subtitle: Text("${transaction["user_wallet"]["currency"]["symbol"]}${transaction["user_amount"] ?? "0.00"}"),
                    ),
                    ListTile(
                      title: const Text("Date"),
                      subtitle: Text(transaction["created_at"] ?? "Unknown"),
                    ),
                    ListTile(
                      title: const Text("Description"),
                      subtitle: Text(transaction["description"] ?? "No Description"),
                    ),
                    ListTile(
                      title: const Text("Transaction Reference"),
                      subtitle: Text(transaction["reference_number"] ?? "N/A"),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionController = Provider.of<WalletTransactionController>(context);
    final transactions = transactionController.transactions;
    final isLoading = transactionController.isLoading;

    bool hasTransactions = transactions.isNotEmpty;
    int displayedTransactions = hasTransactions
        ? (_showFullTransactions ? transactions.length : (transactions.length < 3 ? transactions.length : 3))
        : 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Column(
            children: [
              /// **Header with "See More" Button**
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (hasTransactions)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showFullTransactions = !_showFullTransactions;
                        });
                      },
                      child: Text(_showFullTransactions ? "See Less" : "See More"),
                    ),
                ],
              ),
              const Divider(),

              /// **Loading State**
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                )

              /// **No Transactions Message**
              else if (!hasTransactions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text(
                        "No transactions available",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )

              /// **Transaction List with Limited Fields**
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedTransactions,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return GestureDetector(
                      onTap: () => _showTransactionDetails(transaction), // Show modal on click
                      child: TransactionTile(
                        type: transaction["transaction_type"] ?? "Unknown", // Use "debit" or "credit"
                        amount: transaction["user_amount"] ?? "0.00", // Show amount
                        date: transaction["created_at"] ?? "Unknown", // Show date
                        currencySymbol: transaction["user_wallet"]["currency"]["symbol"] ?? "₦", // Use correct currency symbol
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

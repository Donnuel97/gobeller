import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/loan_controller.dart';

class LoanHistoryPage extends StatefulWidget {
  const LoanHistoryPage({super.key});

  @override
  State<LoanHistoryPage> createState() => _LoanHistoryPageState();
}

class _LoanHistoryPageState extends State<LoanHistoryPage> {
  List<Map<String, dynamic>> loanBalanceList = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchLoanBalance());
  }

  Future<void> fetchLoanBalance() async {
    final loanController = Provider.of<LoanController>(context, listen: false);
    final result = await loanController.getLoanBalanceInfo();

    if (mounted) {
      setState(() {
        if (result['success']) {
          final loans = result['data'] as List<dynamic>;
          loanBalanceList = loans.cast<Map<String, dynamic>>();
          errorMessage = loanBalanceList.isEmpty ? "No loan history available." : null;
        } else {
          loanBalanceList = [];
          errorMessage = result['message'];
        }
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    final num value = num.tryParse(amount.toString()) ?? 0;
    return "₦${NumberFormat('#,##0').format(value)}";
  }

  @override
  Widget build(BuildContext context) {
    final loanController = Provider.of<LoanController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Loan History")),
      body: loanController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: loanBalanceList.isNotEmpty
            ? ListView.separated(
          itemCount: loanBalanceList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final loan = loanBalanceList[index];

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Loan ID: ${loan['application_number'] ?? 'N/A'}",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(loan['loan_status']),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow("Amount Disbursed", _formatCurrency(loan['loan_amount'])),
                    _buildInfoRow("Outstanding Balance", _formatCurrency(loan['repayment_amount_per_cycle'])),
                    _buildInfoRow("Next Repayment Date", loan['next_repayment_date'] ?? "N/A"),
                  ],
                ),
              ),
            );
          },
        )
            : Center(
          child: Text(
            errorMessage ?? "No loan history found.",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(dynamic status) {
    final label = status?['label'] ?? 'N/A';
    final color = _statusColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'overdue':
        return Colors.redAccent;
      case 'completed':
      case 'closed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

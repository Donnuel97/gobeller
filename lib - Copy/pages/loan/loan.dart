import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/loan_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loan_balance.dart';
import 'loan_calculator_screen.dart'; // adjust import

// Ensure this exists

class LoanPage extends StatefulWidget {
  const LoanPage({super.key});

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  String? selectedLoanProduct;
  double? selectedLoanAmount;
  final TextEditingController _amountController = TextEditingController();

  bool showLoanForm = false;
  bool showSummary = false;
  double _minAmount = 0.0;
  double _maxAmount = 0.0;
  double _selectedLoanAmount = 0.0;
  List<Map<String, dynamic>> loanBalanceList = [];
  String? errorMessage;
  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;
  String? _logoUrl;



  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        setState(() {
          final primaryColorHex = data['customized-app-primary-color'];
          final secondaryColorHex = data['customized-app-secondary-color'];
          final tertiaryColorHex = data['customized-app-tertiary-color'];

          _primaryColor = primaryColorHex != null
              ? Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blue;

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blueAccent;
          _tertiaryColor = tertiaryColorHex != null
              ? Color(int.parse(tertiaryColorHex.replaceAll('#', '0xFF')))
              : Colors.grey[200];

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {}
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrimaryColorAndLogo();
      fetchLoanBalance();
      Provider.of<LoanController>(context, listen: false).getEligibleLoanProducts();
    });
  }

  Future<void> fetchLoanBalance() async {
    final loanController = Provider.of<LoanController>(context, listen: false);
    final result = await loanController.getLoanBalanceInfo();

    if (mounted) {
      setState(() {
        if (result['success']) {
          final loans = result['data'] as List<dynamic>;
          if (loans.isNotEmpty) {
            loanBalanceList = loans.cast<Map<String, dynamic>>();
            errorMessage = null;
          } else {
            loanBalanceList = [];
            errorMessage = "No loan balance available.";
          }
        } else {
          loanBalanceList = [];
          errorMessage = result['message'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LoanController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Go to Dashboard',
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard'); // or replaceNamed if needed
            },
          ),
        ],
      ),

      body: SafeArea(
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height, // Ensure full height
          color: _tertiaryColor ?? Theme.of(context).primaryColor,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _loanBalanceCard(),
                    const SizedBox(height: 16),
                    const SizedBox(height: 24),
                    _buildLoanProducts(controller.loanProducts),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _loanBalanceCard() {
    final totalOutstanding = loanBalanceList.fold<num>(
      0,
          (sum, loan) => sum + (num.tryParse(loan['repayment_amount_per_cycle'].toString()) ?? 0),
    );

    final totalDisbursed = loanBalanceList.fold<num>(
      0,
          (sum, loan) => sum + (num.tryParse(loan['loan_amount'].toString()) ?? 0),
    );

    // Get status from the first loan, fallback to "N/A"
    final String loanStatus = loanBalanceList.isNotEmpty
        ? (loanBalanceList.first['loan_status']?['label'] ?? 'N/A')
        : 'N/A';

    String formatCurrency(num amount) {
      return "₦${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Status: $loanStatus",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(totalDisbursed),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Outstanding Balance: ${formatCurrency(totalOutstanding)}",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoanHistoryPage()),
              );
            },
            icon: const Icon(Icons.history, color: Colors.blue),
            label: const Text(
              "My Loan",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            flex: 4,
            child: Text(value != null ? value.toString() : "N/A"),
          ),
        ],
      ),
    );
  }

  // Existing buildLoanProducts code stays the same (pasted below again for completeness)
  Widget _buildLoanProducts(List<Map<String, dynamic>> products) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Get Eligible Loan Products", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Text("No loan products available at the moment.", style: TextStyle(color: Colors.grey))
          else
            Column(
              children: products.map((product) {
                final isSelected = selectedLoanProduct == product['id'];

                String formatAmount(dynamic amount) {
                  if (amount == null) return "0";
                  final numValue = num.tryParse(amount.toString()) ?? 0;
                  return numValue.toStringAsFixed(0).replaceAllMapped(
                      RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedLoanProduct = product['id']?.toString();

                      _minAmount = double.tryParse(product['min_amount'].toString()) ?? 0.0;
                      _maxAmount = double.tryParse(product['max_amount'].toString()) ?? 0.0;
                      _selectedLoanAmount = _minAmount;
                      _amountController.text = _minAmount.toStringAsFixed(0);

                      showSummary = false;
                      showLoanForm = false;
                    });

                    if (selectedLoanProduct != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoanCalculatorPage(
                            productId: selectedLoanProduct!,
                            minAmount: _minAmount,
                            maxAmount: _maxAmount,
                            productName: product['product_name'] ?? 'Unknown Product',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a valid loan product")),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product['product_name'] ?? '',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
                          ],
                        ),
                        if (product['description'] != null) ...[
                          const SizedBox(height: 4),
                          Text(product['description'], style: const TextStyle(fontSize: 14)),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _infoRow(Icons.attach_money, Colors.green,
                                "₦${formatAmount(product['min_amount'])} - ₦${formatAmount(product['max_amount'])}"),
                            _infoRow(Icons.percent, Colors.deepPurple,
                                "Rate: ${product['interest_rate_pct']}%"),
                            _infoRow(
                              Icons.sync,
                              Colors.orange,
                              product['is_interest_rate_reoccuring'] == true
                                  ? "Recurring Interest"
                                  : "One-time Interest",
                            ),
                            _infoRow(
                              Icons.repeat,
                              Colors.blueGrey,
                              "Rollover: " +
                                  (product['allow_internal_loan_rollover'] == true ? "Internal" : "No") +
                                  (product['allow_external_loan_rollover'] == true ? " & External" : ""),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

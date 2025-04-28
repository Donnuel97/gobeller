import 'dart:convert'; // Import for jsonDecode
import 'dart:typed_data'; // For working with byte data
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/WalletTransactionController.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'widget/transaction_tile.dart';
import 'package:flutter/services.dart' show rootBundle;

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Fetch wallet transactions on initialization
    Provider.of<WalletTransactionController>(context, listen: false).fetchWalletTransactions();
  }

  void _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 5);
    final DateTime lastDate = DateTime(now.year + 1);

    // Show date range picker
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
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
                    Center(
                      child: Text(
                        "Transaction Details",
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Centralized Amount with Transaction Type in Brackets
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text:
                              "${transaction["user_wallet"]["currency"]["symbol"]}${(double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 24, // Larger font size for the amount
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const TextSpan(text: " "),
                            TextSpan(
                              text: "(${transaction["transaction_type"] ?? "Unknown"})",
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Table for the details in a tabular form
                    Table(
                      columnWidths: {
                        0: FixedColumnWidth(150), // Width for labels
                        1: FlexColumnWidth(), // Width for values
                      },
                      children: [
                        TableRow(
                          children: [
                            _buildTableCell("Transaction Type"),
                            _buildTableCell(transaction["transaction_type"] ?? "Unknown"),
                          ],
                        ),
                        TableRow(
                          children: [
                            _buildTableCell("Date"),
                            _buildTableCell(transaction["created_at"] ?? "Unknown"),
                          ],
                        ),
                        TableRow(
                          children: [
                            _buildTableCell("Description"),
                            _buildTableCell(transaction["description"] ?? "No Description"),
                          ],
                        ),
                        TableRow(
                          children: [
                            _buildTableCell("Transaction Reference"),
                            _buildTableCell(transaction["reference_number"] ?? "N/A"),
                          ],
                        ),
                        TableRow(
                          children: [
                            _buildTableCell("Session ID"),
                            _buildTableCell(transaction["instrument_code"] ?? "N/A"),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Row for Close and Download buttons positioned left and right
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close Receipt"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _downloadTransactionAsPDF(transaction),
                            child: const Text("Download"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _shareTransactionAsPDF(transaction),
                            child: const Text("Share"),
                          ),
                        ),
                      ],
                    ),


                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Helper function to build Table cells
  Widget _buildTableCell(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  // PDF share
  Future<void> _shareTransactionAsPDF(Map<String, dynamic> transaction) async {
    final pdf = pw.Document();

    final prefs = await SharedPreferences.getInstance();
    final logoUrl = prefs.getString('customized-app-logo-url'); // Load logo URL from SharedPreferences
    final customerSupportData = prefs.getString('customerSupportData');

    final customerSupport = customerSupportData != null
        ? jsonDecode(customerSupportData)['data']
        : null;

    Uint8List? logoImageBytes;
    if (logoUrl != null) {
      try {
        final response = await http.get(Uri.parse(logoUrl)); // Get the logo image from the URL
        if (response.statusCode == 200) {
          logoImageBytes = response.bodyBytes;
        }
      } catch (e) {
        print("Error loading logo image: $e");
      }
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo at top center
              pw.Center(
                child: logoImageBytes != null
                    ? pw.Image(pw.MemoryImage(logoImageBytes), width: 100, height: 100, fit: pw.BoxFit.contain)
                    : pw.SizedBox(width: 100, height: 100),
              ),
              pw.SizedBox(height: 20),

              // Title: Transaction Receipt
              pw.Center(
                child: pw.Text(
                  'Transaction Receipt',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Status Label
              pw.Center(
                child: pw.Text(
                  transaction["status"]["label"],
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: _getPdfStatusColor(transaction["status"]["label"]),
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Table for transaction details
              pw.Table(
                children: [
                  _buildPdfTableRow("Amount", "${transaction["user_wallet"]["currency"]["symbol"]}${(double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}"),
                  _buildPdfTableRow("Transaction Type", transaction["transaction_type"] ?? "Unknown"),
                  _buildPdfTableRow("Date", transaction["created_at"] ?? "Unknown"),
                  _buildPdfTableRow("Description", transaction["description"] ?? "No Description"),
                  _buildPdfTableRow("Transaction Reference", transaction["reference_number"] ?? "N/A"),
                  if (transaction["instrument_code"] != null)
                    _buildPdfTableRow("Session ID", transaction["instrument_code"]),
                ],
              ),

              pw.SizedBox(height: 20),

              // Customer Support Details
              if (customerSupport != null) ...[
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Customer Support:',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Email: ${customerSupport['official_email']}'),
                pw.Text('Phone: ${customerSupport['official_telephone']}'),
                pw.Text('Website: ${customerSupport['public_existing_website']}'),
                if (customerSupport['address'] != null && customerSupport['address']['country'] != null)
                  pw.Text('Country: ${customerSupport['address']['country']}'),
              ],
              pw.SizedBox(height: 20),

              // Footer (Generated Date)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated on ${DateFormat.yMMMd().format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'transaction_receipt.pdf',
    );
  }

// Helper to build a clean table row
  pw.TableRow _buildPdfTableRow(String title, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

// Helper to determine PDF status label color
  PdfColor _getPdfStatusColor(String statusLabel) {
    if (statusLabel == "Pending") {
      return PdfColors.orange; // Pending
    } else if (statusLabel == "Successful") {
      return PdfColors.green; // Successful
    } else {
      return PdfColors.red; // Any other status
    }
  }




  // Function to generate PDF and download it
  Future<void> _downloadTransactionAsPDF(Map<String, dynamic> transaction) async {
    final pdf = pw.Document();

    // Fetch customer support details from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final customerSupportData = prefs.getString('customerSupportData');
    final customerSupport = customerSupportData != null
        ? jsonDecode(customerSupportData)['data']
        : null;

    // Load the logo from the assets folder
    Uint8List? logoImageBytes;
    try {
      logoImageBytes = await rootBundle.load('assets/logo.png').then((value) => value.buffer.asUint8List());
      print("Logo image loaded from assets successfully");
    } catch (e) {
      print("Error loading logo image from assets: $e");
    }

    // Add a page with the transaction details
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section: Logo centralized in the page
              pw.Center(
                child: logoImageBytes != null
                    ? pw.Image(pw.MemoryImage(logoImageBytes), width: 100, height: 100, fit: pw.BoxFit.contain)
                    : pw.SizedBox(width: 100),
              ),
              pw.SizedBox(height: 20), // Space after logo

              // Title: Transaction Receipt
              pw.Center(
                child: pw.Text(
                  'Transaction Receipt',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 30), // Space after the title
              pw.Center(
                child: pw.Text(
                  transaction["status"]["label"],
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              // Transaction Details Section (with no borders in the table)
              pw.Table(
                children: [
                  _buildTableRow("Amount", "${transaction["user_wallet"]["currency"]["code"]}${(double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}"),
                  _buildTableRow("Date", transaction["created_at"] ?? "Unknown"),
                  _buildTableRow("Description", transaction["description"] ?? "No Description"),
                  _buildTableRow("Transaction Reference", transaction["reference_number"] ?? "N/A"),
                ],
              ),
              pw.SizedBox(height: 20), // Space after the transaction table

              // Customer Support Section (below transaction details)
              if (customerSupport != null) ...[
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Customer Support:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text('Email: ${customerSupport['official_email']}'),
                pw.Text('Phone: ${customerSupport['official_telephone']}'),
                pw.Text('Website: ${customerSupport['public_existing_website']}'),
                if (customerSupport['address'] != null && customerSupport['address']['country'] != null)
                  pw.Text('Country: ${customerSupport['address']['country']}'),
                pw.SizedBox(height: 20),
              ],

              // Footer Section: Date and time the PDF was generated
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated on ${DateFormat.yMMMd().format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF and print it or show a preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  pw.TableRow _buildTableRow(String title, String value) {
    return pw.TableRow(
      children: [
        // Title aligned to the left with padding and wrapping enabled
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            softWrap: true, // Allow text to wrap
            maxLines: 2, // Limit the lines to 2 (you can adjust based on your needs)
          ),
        ),
        // Value aligned to the right with padding and wrapping enabled
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,  // Align the value to the right
            style: pw.TextStyle(
              color: PdfColors.black,
            ),
            softWrap: true,  // Allow text to wrap
            maxLines: 2,  // Limit the lines to 2 (you can adjust based on your needs)
          ),
        ),
      ],
    );
  }




  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<WalletTransactionController>(context);
    final transactions = controller.transactions;

    // Sort transactions by date in descending order and get the 10 most recent ones
    final recentTransactions = transactions
        .where((tx) => DateTime.tryParse(tx['created_at'] ?? '') != null) // Filter valid dates
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA); // Sort descending
      });

    // Get the top 10 most recent transactions
    final top10Transactions = recentTransactions.take(10).toList();

    // If no date range is selected, keep the filtered list empty initially.
    final filteredTransactions = (_startDate != null && _endDate != null)
        ? top10Transactions.where((tx) {
      final date = DateTime.tryParse(tx['created_at'] ?? '');
      return date != null &&
          date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          date.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList()
        : top10Transactions;

    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Filter UI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _startDate != null && _endDate != null
                      ? "${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}"
                      : "All Dates",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text("Filter"),
                ),
              ],
            ),
            const Divider(),

            // Transaction List
            controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                ? const Center(child: Text("No transactions found. Apply a filter to view transactions."))
                : Expanded(
              child: ListView.builder(
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  final tx = filteredTransactions[index];
                  // Format the amount to 2 decimal places
                  String formattedAmount = (double.tryParse(tx["user_amount"] ?? "0.00") ?? 0.00)
                      .toStringAsFixed(2);

                  return GestureDetector(
                    onTap: () => _showTransactionDetails(tx), // Show modal on click
                    child: TransactionTile(
                      type: tx["transaction_type"] ?? "Unknown",
                      amount: formattedAmount,
                      date: tx["created_at"] ?? "Unknown",
                      currencySymbol: tx["user_wallet"]["currency"]["symbol"] ?? "₦",
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

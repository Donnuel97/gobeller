import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/property_controller.dart';

class SubscriptionHistoryPage extends StatefulWidget {
  final String propertyId;

  const SubscriptionHistoryPage({super.key, required this.propertyId});

  @override
  State<SubscriptionHistoryPage> createState() => _SubscriptionHistoryPageState();
}

class _SubscriptionHistoryPageState extends State<SubscriptionHistoryPage> {
  List<dynamic>? subscriptions;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionHistory();
  }

  Future<void> _loadSubscriptionHistory() async {
    final controller = Provider.of<PropertyController>(context, listen: false);
    final result = await controller.fetchPropertySubscriptionHistory(widget.propertyId);

    if (result == null || result['status'] != true) {
      setState(() {
        errorMessage = "Failed to load subscription history.";
        isLoading = false;
      });
      return;
    }

    setState(() {
      subscriptions = result['data']?['subscriptions'] ?? [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription History')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : (subscriptions == null || subscriptions!.isEmpty)
          ? const Center(child: Text('No subscription history found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subscriptions!.length,
        itemBuilder: (context, index) {
          final sub = subscriptions![index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription ID: ${sub['id'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Quantity: ${sub['quantity'] ?? 'N/A'}'),
                  Text('Start Date: ${sub['start_date'] ?? 'N/A'}'),
                  Text('Duration: ${sub['duration_interval'] ?? 'N/A'}'),
                  Text('Payment Option: ${sub['payment_option'] ?? 'N/A'}'),
                  Text('Status: ${sub['status'] ?? 'N/A'}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


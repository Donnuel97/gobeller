import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/airtime_controller.dart';

class BuyAirtimePage extends StatefulWidget {
  const BuyAirtimePage({super.key});

  @override
  State<BuyAirtimePage> createState() => _BuyAirtimePageState();
}

class _BuyAirtimePageState extends State<BuyAirtimePage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  String? selectedNetwork;
  bool isProcessing = false;

  final List<Map<String, String>> networks = [
    {"value": "MTN", "image": "assets/airtime_data/mtn-logo.svg"},
    {"value": "Airtel", "image": "assets/airtime_data/airtel-logo.svg"},
    {"value": "Glo", "image": "assets/airtime_data/glo-logo.svg"},
    {"value": "9mobile", "image": "assets/airtime_data/9mobile-logo.svg"},
  ];

  @override
  void dispose() {
    phoneController.dispose();
    amountController.dispose();
    pinController.dispose();
    super.dispose();
  }

  void _buyAirtime() async {
    if (selectedNetwork == null ||
        phoneController.text.isEmpty ||
        amountController.text.isEmpty ||
        pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      await Provider.of<AirtimeController>(context, listen: false).buyAirtime(
        networkProvider: selectedNetwork!,
        phoneNumber: phoneController.text,
        amount: amountController.text,
        pin: pinController.text,
        context: context,
      );

      // 🎉 Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Airtime Purchase Successful!")),
      );

      // 🔄 Clear the form after success
      setState(() {
        phoneController.clear();
        amountController.clear();
        pinController.clear();
        selectedNetwork = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Purchase Failed: $e")),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buy Airtime")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // **Network Selection**
            const Text(
              "Select Network:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: networks.map((provider) {
                final isSelected = selectedNetwork == provider['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedNetwork = provider['value']);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            provider['image']!,
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 4),
                          Text(provider['value']!,
                              style: TextStyle(
                                  color: isSelected ? Colors.blue : Colors.black)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // **Phone Number Input**
            const Text("Phone Number:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Enter phone number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),

            const SizedBox(height: 24),

            // **Amount Input**
            const Text("Amount (₦):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter amount",
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // **Transaction PIN Input**
            const Text("Transaction PIN:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter your PIN",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // **Buy Airtime Button**
            ElevatedButton(
              onPressed: isProcessing ? null : _buyAirtime,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: const Color(0xFFEB6D00), // HEX color for background
                foregroundColor: Colors.white, // Text color set to white
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Buy Airtime", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),


          ],
        ),
      ),
    );
  }
}

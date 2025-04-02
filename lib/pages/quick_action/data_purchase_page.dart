import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/data_bundle_controller.dart';

class DataPurchasePage extends StatefulWidget {
  const DataPurchasePage({super.key});

  @override
  _DataPurchasePageState createState() => _DataPurchasePageState();
}

class _DataPurchasePageState extends State<DataPurchasePage> {
  String? selectedNetwork;
  String? selectedPlan;
  List<Map<String, dynamic>> dataPlans = [];
  bool isLoadingPlans = false;
  bool isProcessingPurchase = false;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  final List<Map<String, String>> networks = [
    {"value": "MTN", "image": "assets/airtime_data/mtn-logo.svg"},
    {"value": "Airtel", "image": "assets/airtime_data/airtel-logo.svg"},
    {"value": "Glo", "image": "assets/airtime_data/glo-logo.svg"},
    {"value": "9Mobile", "image": "assets/airtime_data/9mobile-logo.svg"},
  ];

  @override
  void dispose() {
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataPlans(String network) async {
    setState(() {
      isLoadingPlans = true;
      dataPlans = [];
      selectedPlan = null;
    });

    try {
      List<Map<String, dynamic>>? fetchedPlans =
      await DataBundleController.fetchDataBundles(network);

      setState(() {
        isLoadingPlans = false;
        dataPlans = fetchedPlans ?? [];
      });
    } catch (e) {
      setState(() => isLoadingPlans = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Failed to fetch data plans.")),
      );
    }
  }

  void _purchaseData() async {
    if (selectedNetwork == null ||
        selectedPlan == null ||
        phoneController.text.isEmpty ||
        pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      return;
    }

    setState(() => isProcessingPurchase = true);

    try {
      await Provider.of<DataBundleController>(context, listen: false).buyDataBundle(
        networkProvider: selectedNetwork!,
        dataPlan: selectedPlan!,
        phoneNumber: phoneController.text,
        pin: pinController.text,
        context: context,
      );

      // 🎉 Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Data Purchase Successful!")),
      );

      // 🔄 Clear the form after success
      setState(() {
        phoneController.clear();
        pinController.clear();
        selectedNetwork = null;
        selectedPlan = null;
        dataPlans = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Purchase Failed: $e")),
      );
    } finally {
      setState(() => isProcessingPurchase = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buy Data")),
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
                      setState(() {
                        selectedNetwork = provider['value'];
                        _fetchDataPlans(provider['value']!);
                      });
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

            // **Data Plan Selection**
            const Text("Select Data Plan:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedPlan,
              items: dataPlans.map((plan) {
                return DropdownMenuItem<String>(
                  value: plan["variation_code"].toString(),
                  child: Text(
                    "${plan["name"]} - ₦${plan["variation_amount"]}",
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedPlan = value),
              decoration: const InputDecoration(
                labelText: "Select Data Plan",
                border: OutlineInputBorder(),
              ),
              isExpanded: true, // ✅ Fixes overflow issue
            ),

            const SizedBox(height: 24),

            // **Phone Number Input**
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                hintText: "Enter phone number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),

            const SizedBox(height: 24),

            // **Transaction PIN Input**
            TextFormField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Transaction PIN",
                hintText: "Enter your PIN",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // **Purchase Button**
            ElevatedButton(
              onPressed: isProcessingPurchase ? null : _purchaseData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB6D00), // HEX color for background
                foregroundColor: Colors.white, // Text color set to white
                padding: const EdgeInsets.all(15), // Optional: Adds better spacing
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Optional: Rounded corners
              ),
              child: isProcessingPurchase
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Purchase Data", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

          ],
        ),
      ),
    );
  }
}

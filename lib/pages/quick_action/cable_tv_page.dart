import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/cable_tv_controller.dart';

class CableTVPage extends StatefulWidget {
  const CableTVPage({super.key});

  @override
  State<CableTVPage> createState() => _CableTVPageState();
}

class _CableTVPageState extends State<CableTVPage> {
  final TextEditingController smartCardController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? selectedProvider;
  String? selectedPlan;
  String? selectedApiKey;

  final List<Map<String, dynamic>> cableProviders = [
    {"name": "DStv", "image": "assets/cable_tv/dstv-logo.svg", "apiKey": "dstv"},
    {"name": "GOtv", "image": "assets/cable_tv/gotv-logo.svg", "apiKey": "gotv"},
    {"name": "StarTimes", "image": "assets/cable_tv/startimes-logo.svg", "apiKey": "startimes"},
    {"name": "Showmax", "image": "assets/cable_tv/showmax-logo.svg", "apiKey": "showmax"},
  ];

  @override
  void dispose() {
    smartCardController.dispose();
    pinController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void clearForm() {
    setState(() {
      smartCardController.clear();
      pinController.clear();
      phoneController.clear();
      selectedProvider = null;
      selectedPlan = null;
      selectedApiKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cableTVController = Provider.of<CableTVController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Cable TV Subscription")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Select Provider:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: cableProviders.map((provider) {
                final isSelected = selectedProvider == provider['name'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedProvider = provider['name'];
                        selectedApiKey = provider['apiKey'];
                        selectedPlan = null;
                      });

                      cableTVController.fetchSubscriptionPlans(selectedApiKey!);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!, width: 2),
                      ),
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          SvgPicture.asset(provider['image']!, width: 50, height: 50),
                          const SizedBox(height: 4),
                          Text(provider['name']!, style: TextStyle(color: isSelected ? Colors.blue : Colors.black)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: smartCardController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter Smart Card/IUC Number",
                prefixIcon: const Icon(Icons.credit_card),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: selectedApiKey == null
                      ? null
                      : () {
                    cableTVController.verifySmartCard(
                      selectedApiKey!,
                      smartCardController.text.trim(),
                      context,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
            Consumer<CableTVController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (selectedProvider == null || controller.subscriptionPlans.isEmpty) {
                  return const Text("No plans available. Select a provider first.");
                }
                return DropdownButtonFormField<String>(
                  value: selectedPlan,
                  hint: const Text("Choose a plan"),
                  isExpanded: true,  // ✅ FIXES OVERFLOW ISSUE
                  items: controller.subscriptionPlans.map((plan) {
                    return DropdownMenuItem<String>(
                      value: plan["variation_code"],
                      child: Text("${plan["name"]} - ₦${plan["variation_amount"]}"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedPlan = value),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                );
              },
            ),

            const SizedBox(height: 24),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Enter Phone Number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            TextFormField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Transaction PIN",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: cableTVController.isLoading
                  ? null
                  : () async {
                if (selectedApiKey != null &&
                    smartCardController.text.isNotEmpty &&
                    selectedPlan != null &&
                    phoneController.text.isNotEmpty &&
                    pinController.text.isNotEmpty) {

                  await cableTVController.subscribeToCableTV(
                    cableTvType: selectedApiKey!,
                    smartCardNumber: smartCardController.text.trim(),
                    subscriptionPlan: selectedPlan!,
                    phoneNumber: phoneController.text.trim(),
                    transactionPin: pinController.text.trim(),
                    context: context,
                  );

                  // Clear form after a short delay (UI update safety)
                  Future.delayed(const Duration(milliseconds: 500), () {
                    clearForm();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Subscription Successful!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("⚠️ Please fill all fields correctly!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB6D00), // HEX color for background
                foregroundColor: Colors.white, // Text color set to white
                padding: const EdgeInsets.all(15), // Better spacing
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
              ),
              child: cableTVController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "Subscribe",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/electricity_controller.dart';

class ElectricityPaymentPage extends StatefulWidget {
  const ElectricityPaymentPage({super.key});

  @override
  State<ElectricityPaymentPage> createState() => _ElectricityPaymentPageState();
}

class _ElectricityPaymentPageState extends State<ElectricityPaymentPage> {
  String? selectedDisco;
  String? selectedMeterType;

  final TextEditingController meterNumberController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ElectricityController>(context, listen: false).fetchMeterServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final electricityController = Provider.of<ElectricityController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Electricity Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// **Electricity Disco Dropdown**
              const Text("Select Electricity Disco:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              electricityController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : electricityController.electricityDiscos.isEmpty
                  ? const Text("No Electricity Discos available")
                  : DropdownButtonFormField<String>(
                value: selectedDisco,
                hint: const Text("Choose a provider"),
                items: electricityController.electricityDiscos.map((disco) {
                  return DropdownMenuItem<String>(
                    value: disco["id"],
                    child: Text(disco["name"]!),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedDisco = value),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 24),

              /// **Meter Type Dropdown**
              const Text("Select Meter Type:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              electricityController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : electricityController.meterTypes.isEmpty
                  ? const Text("No Meter Types available")
                  : DropdownButtonFormField<String>(
                value: selectedMeterType,
                hint: const Text("Choose a meter type"),
                items: electricityController.meterTypes.map((meter) {
                  return DropdownMenuItem<String>(
                    value: meter["id"],
                    child: Text(meter["name"]!),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedMeterType = value),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 24),

              /// **Meter Number Input**
              const Text("Enter Meter Number:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: meterNumberController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter meter number",
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              /// **Verify Meter Button**
              ElevatedButton(
                onPressed: electricityController.isVerifying
                    ? null
                    : () {
                  if (selectedDisco != null &&
                      selectedMeterType != null &&
                      meterNumberController.text.isNotEmpty) {
                    electricityController.verifyMeterNumber(
                      electricityDisco: selectedDisco!,
                      meterType: selectedMeterType!,
                      meterNumber: meterNumberController.text,
                      context: context,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("⚠️ Please fill all fields!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB6D00), // HEX color for background
                  foregroundColor: Colors.white, // Text color set to white
                  padding: const EdgeInsets.all(15), // Better spacing
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
                ),
                child: electricityController.isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Verify Meter Number",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 24),

              /// **Display Meter Owner Name after Verification**
              if (electricityController.meterOwnerName != null) ...[
                const SizedBox(height: 16),
                Text(
                  "✅ Meter Owner: ${electricityController.meterOwnerName}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],

              const SizedBox(height: 24),

              /// **Amount Input**
              const Text("Enter Amount:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter amount",
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              /// **Phone Number Input**
              const Text("Enter Phone Number:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneNumberController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter phone number",
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              /// **Transaction PIN Input**
              const Text("Enter Transaction PIN:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: pinController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter PIN",
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              /// **Purchase Electricity Button**
              /// **Purchase Electricity Button**
              SizedBox(
                width: double.infinity, // Makes button full width
                child: ElevatedButton(
                  onPressed: electricityController.isPurchasing
                      ? null
                      : () {
                    if (selectedDisco != null &&
                        selectedMeterType != null &&
                        meterNumberController.text.isNotEmpty &&
                        amountController.text.isNotEmpty &&
                        phoneNumberController.text.isNotEmpty &&
                        pinController.text.isNotEmpty) {
                      electricityController.purchaseElectricity(
                        meterNumber: meterNumberController.text,
                        electricityDisco: selectedDisco!,
                        meterType: selectedMeterType!,
                        amount: amountController.text,
                        phoneNumber: phoneNumberController.text,
                        pin: pinController.text,
                        context: context,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("⚠️ Please fill all fields!")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEB6D00), // HEX color for background
                    foregroundColor: Colors.white, // Text color set to white
                    padding: const EdgeInsets.all(15), // Better spacing
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
                  ),
                  child: electricityController.isPurchasing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Purchase Electricity",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

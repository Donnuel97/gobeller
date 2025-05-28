import 'package:flutter/material.dart';

class FixedDepositPage extends StatelessWidget {
  const FixedDepositPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fixed"),
        leading: const BackButton(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(child: Text("More", style: TextStyle(color: Colors.black))),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5C27C0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Fixed",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Deposit & earn massive returns.",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Powered by BlueRidge Microfinance Bank",
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.lock, size: 48, color: Colors.orange),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details List
            _buildFeatureTile("Interest Yield",
                "Earn up to 18% p.a. on balance of ₦300,000 and below. For balance over ₦300,000, you will earn up to 18% p.a. on the first ₦300,000 and up to 9% p.a. on the remaining balance."),
            _buildFeatureTile("Savings Duration", "7-1000 days"),
            _buildFeatureTile("Savings Top-up", "One-time initial deposit"),
            _buildFeatureTile("Withdrawal",
                "You can withdraw anytime, but doing so before maturity means losing accrued interest and being charged a fee."),
            _buildFeatureTile("Halal Compliant",
                "You have the option to choose not to receive interests on your savings."),

            const SizedBox(height: 24),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/fixed_form');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C27C0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Create Fixed",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // NDIC footer
            const Text(
              "Insured by",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Image.asset(
              "assets/ndic.png", // Ensure this is added in pubspec.yaml
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF5C27C0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

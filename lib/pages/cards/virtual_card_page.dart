import 'package:flutter/material.dart';
import 'package:gobeller/pages/success/widget/bottom_nav_bar.dart';

class VirtualCardPage extends StatefulWidget {
  const VirtualCardPage({super.key});

  @override
  _VirtualCardPageState createState() => _VirtualCardPageState();
}

class _VirtualCardPageState extends State<VirtualCardPage> {
  // Sample virtual card details (can be dynamically generated)
  String cardNumber = "**** **** **** 1234";
  String expiryDate = "12/26";
  String cvv = "***";

  void _generateNewCard() {
    setState(() {
      // Simulate generating a new virtual card
      cardNumber = "**** **** **** ${1000 + (DateTime.now().millisecond % 9000)}";
      expiryDate = "01/28";
      cvv = "${100 + (DateTime.now().second % 900)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Virtual Card"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Move Card to Top
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.blueAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Virtual Card",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    cardNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Exp: $expiryDate",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        "CVV: $cvv",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20), // Add space after card

            // Add more content here if needed
            const Text(
              "Manage your virtual card securely.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateNewCard,
        label: const Text("New Card"),
        icon: const Icon(Icons.refresh),
        backgroundColor: Colors.blueAccent,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // "Cards" tab
        onTabSelected: (index) {
          if (index != 2) {
            Navigator.pushReplacementNamed(context, _getRouteForIndex(index));
          }
        },
      ),
    );
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return "/";
      case 1:
        return "/wallet";
      case 2:
        return "/virtualCard";
      case 3:
        return "/profile";
      default:
        return "/";
    }
  }
}

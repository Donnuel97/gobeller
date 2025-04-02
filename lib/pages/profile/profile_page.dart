import 'package:flutter/material.dart';
import 'package:gobeller/controller/profileControllers.dart'; // Import the ProfileController
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileController.fetchUserProfile();
    setState(() {
      userProfile = profile;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader while fetching data
          : userProfile == null
          ? const Center(child: Text('Failed to load profile')) // Handle API error
          : SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image & Name
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: userProfile!['profile_image_url'] != null &&
                              userProfile!['profile_image_url'].isNotEmpty
                              ? NetworkImage(userProfile!['profile_image_url'])
                              : const AssetImage('assets/default_profile.png') as ImageProvider,
                          backgroundColor: Colors.grey[300], // Optional background color
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userProfile!['full_name'],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          userProfile!['email'],
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🟢 Personal Information Section
                  _buildProfileSection("Personal Information", [
                    _buildProfileItem(Icons.person, "Username", userProfile!['username']),
                    _buildProfileItem(Icons.male, "Gender", userProfile!['gender'] ?? "N/A"),
                  ]),

                  const SizedBox(height: 10),

                  // 📞 Contact Information Section
                  _buildProfileSection("Contact Information", [
                    _buildProfileItem(Icons.email, "Email", userProfile!['email']),
                    _buildProfileItem(Icons.phone, "Phone", userProfile!['telephone']),
                    _buildProfileItem(Icons.business, "Organization", userProfile!['organization']),
                  ]),

                  const SizedBox(height: 10),

                  // 💰 Wallet Information Section
                  _buildProfileSection("Wallet Information", [
                    _buildProfileItem(Icons.wallet, "Wallet Number", userProfile!['wallet_number']),
                    _buildProfileItem(
                      Icons.attach_money,
                      "Wallet Balance",
                      "${userProfile!['wallet_currency']} ${double.parse(userProfile!['wallet_balance'].toString()).toStringAsFixed(2)}",
                    ),
                    _buildProfileItem(Icons.verified, "Account Status", userProfile!['status']),
                  ]),

                  const SizedBox(height: 30),

                  // Logout Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onPressed: () async {
                      final SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.remove('auth_token'); // Clear stored auth token

                      // Navigate back to the login screen and remove previous routes
                      if (!mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🏷️ Profile Section Widget (for grouping)
  Widget _buildProfileSection(String title, List<Widget> items) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Column(children: items), // Ensure children fit properly
          ],
        ),
      ),
    );
  }

  // 📌 Individual Profile Item Widget
  Widget _buildProfileItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }
}

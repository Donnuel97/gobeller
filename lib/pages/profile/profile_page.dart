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
  Map<String, dynamic>? supportDetails;

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
    final support = await ProfileController.fetchCustomerSupportDetails();
    setState(() {
      userProfile = profile;
      supportDetails = support;
      isLoading = false;
    });

  }

  ImageProvider _getGenderBasedImage(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return const AssetImage('assets/male.png');
      case 'female':
        return const AssetImage('assets/female.png');
      default:
        return const AssetImage('assets/default_profile.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader while fetching data
          : userProfile == null
          ? const Center(child: Text('Failed to load profile')) // Handle API error
          : SingleChildScrollView( // Wrapping the entire content in SingleChildScrollView
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image & Name
                  // Profile Image & Name
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: userProfile!['profile_image_url'] != null &&
                              userProfile!['profile_image_url'].isNotEmpty
                              ? NetworkImage(userProfile!['profile_image_url'])
                              : _getGenderBasedImage(userProfile!['gender']),
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),

                        // Name
                        Text(
                          userProfile!['full_name'] ?? "N/A",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Email
                        Text(
                          userProfile!['email'] ?? "N/A",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),



                  // 🟢 Personal Information Section
                  _buildProfileSection("Personal Information", [
                    _buildProfileItem(Icons.person, "Username", userProfile!['username']?.toString() ?? "N/A"),
                    _buildProfileItem(Icons.male, "Gender", userProfile!['gender']?.toString() ?? "N/A"),
                    _buildProfileItem(Icons.calendar_month, "Date of Birth", userProfile!['date_of_birth']?.toString() ?? "N/A"),
                    _buildProfileItem(Icons.home, "Address", userProfile!['physical_address']?.toString() ?? "N/A"),
                    _buildProfileItem(
                      Icons.chat_bubble,
                      "SMS enabled",
                      userProfile!['should_send_sms'] == true
                          ? "Enabled"
                          : userProfile!['should_send_sms'] == false
                          ? "Disabled"
                          : "N/A",
                      valueColor: userProfile!['should_send_sms'] == true
                          ? Colors.green
                          : userProfile!['should_send_sms'] == false
                          ? Colors.red
                          : Colors.grey,
                    ),
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


                  // 🛠️ Change Settings Section (Change Password & Change PIN)
                  _buildSettingsSection(),

                  const SizedBox(height: 10),

                  if (supportDetails != null)
                    _buildProfileSection("Customer Support Details", [
                      _buildProfileItem(Icons.business, "Organization", supportDetails!['organization_full_name']),
                      _buildProfileItem(Icons.language, "Website", supportDetails!['public_existing_website'] ?? "N/A"),
                      _buildProfileItem(Icons.email, "Email", supportDetails!['official_email'] ?? "N/A"),
                      _buildProfileItem(Icons.phone, "Telephone", supportDetails!['official_telephone'] ?? "N/A"),
                      _buildProfileItem(Icons.location_on, "Address", supportDetails!['address']?['physical_address'] ?? "N/A"),
                      _buildProfileItem(Icons.public, "Country", supportDetails!['address']?['country'] ?? "N/A"),
                    ]),

                  // // 📞 Contact Information Section
                  // _buildProfileSection("Contact Information", [
                  //   _buildProfileItem(Icons.email, "Email", userProfile!['email']),
                  //   _buildProfileItem(Icons.phone, "Phone", userProfile!['telephone']),
                  //   _buildProfileItem(Icons.business, "Organization", userProfile!['organization']),
                  // ]),
                  //
                  // const SizedBox(height: 10),
                  // Logout Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 3,
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
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            Column(children: items), // Ensure children fit properly
          ],
        ),
      ),
    );
  }

  // 📌 Individual Profile Item Widget
  Widget _buildProfileItem(
      IconData icon,
      String label,
      String value, {
        Color valueColor = Colors.black87, // default color
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 14, color: valueColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }


  // 🛠️ Settings Section: Change Password and Change PIN
  Widget _buildSettingsSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Divider(),

            // Change Password Item
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.blue),
              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangePasswordDialog,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),

            // Change PIN Item
            ListTile(
              leading: const Icon(Icons.pin, color: Colors.blue),
              title: const Text('Change PIN', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangePinDialog,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ],
        ),
      ),
    );
  }


  // Show Change Password Dialog
  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController newPasswordConfirmationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Title
                  Center(
                    child: Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current Password
                  _buildPasswordField(
                    label: 'Current Password',
                    controller: currentPasswordController,
                    obscureText: true,
                  ),

                  // New Password
                  _buildPasswordField(
                    label: 'New Password',
                    controller: newPasswordController,
                    obscureText: true,
                  ),

                  // Confirm New Password
                  _buildPasswordField(
                    label: 'Confirm New Password',
                    controller: newPasswordConfirmationController,
                    obscureText: true,
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel Button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Change Button
                      ElevatedButton(
                        onPressed: () async {
                          String currentPassword = currentPasswordController.text;
                          String newPassword = newPasswordController.text;
                          String newPasswordConfirmation = newPasswordConfirmationController.text;

                          if (currentPassword.isEmpty || newPassword.isEmpty || newPasswordConfirmation.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields")),
                            );
                            return;
                          }

                          if (newPassword != newPasswordConfirmation) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Passwords do not match")),
                            );
                            return;
                          }

                          String result = await ProfileController.changePassword(
                            currentPassword,
                            newPassword,
                            newPasswordConfirmation,
                          );

                          if (result == "Password changed successfully") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Password changed successfully")),
                            );

                            // Redirect after successful change
                            Future.delayed(const Duration(seconds: 2), () {
                              // Clear session
                              SharedPreferences.getInstance().then((prefs) {
                                prefs.remove('auth_token');
                              });

                              // Redirect to login page
                              if (!mounted) return;
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                          }

                          Navigator.of(context).pop(); // Close the dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,  // Set the text color to white
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for Password Fields
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  // Show Change PIN Dialog
  void _showChangePinDialog() {
    final TextEditingController currentPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "Change Transaction PIN",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current PIN
                  _buildPasswordField(
                    label: 'Current PIN',
                    controller: currentPinController,
                    obscureText: true,
                  ),

                  // New PIN
                  _buildPasswordField(
                    label: 'New PIN',
                    controller: newPinController,
                    obscureText: true,
                  ),

                  // Confirm New PIN
                  _buildPasswordField(
                    label: 'Confirm New PIN',
                    controller: confirmPinController,
                    obscureText: true,
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel Button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Change Button
                      ElevatedButton(
                        onPressed: () async {
                          String currentPin = currentPinController.text;
                          String newPin = newPinController.text;
                          String confirmPin = confirmPinController.text;

                          if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields")),
                            );
                            return;
                          }

                          if (newPin != confirmPin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("PINs do not match")),
                            );
                            return;
                          }

                          String result = await ProfileController.changeTransactionPin(
                            currentPin,
                            newPin,
                          );

                          if (result == "Transaction PIN changed successfully") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Transaction PIN changed successfully")),
                            );

                            // Optionally clear session or navigate based on requirements
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                          }

                          Navigator.of(context).pop(); // Close the dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

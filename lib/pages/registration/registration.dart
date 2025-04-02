import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/const/const_ui.dart';
import 'package:gobeller/controller/registration_controller.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _transactionPinController = TextEditingController();

  String? _selectedIdType;
  bool _showIdInput = false;
  bool _showFullForm = false;

  @override
  Widget build(BuildContext context) {
    final ninController = Provider.of<NinVerificationController>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: ConstUI.kMainPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset("assets/logo.png", width: 128, height: 128),
                  const SizedBox(height: 16),
                  Text(
                    "Create Your Account",
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  /// **Step 1: ID Type Dropdown**
                  DropdownButtonFormField<String>(
                    value: _selectedIdType,
                    decoration: const InputDecoration(labelText: "Select ID Type"),
                    items: ["NIN", "BVN", "Passport Number"]
                        .map((idType) => DropdownMenuItem(
                      value: idType,
                      child: Text(idType),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedIdType = value;
                        _showIdInput = true;
                        _showFullForm = false;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  /// **Step 2: ID Number Input**
                  if (_showIdInput) ...[
                    TextFormField(
                      controller: _idNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Enter $_selectedIdType Number",
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// **Verification Button**
                    ElevatedButton(
                      onPressed: () {
                        if (_idNumberController.text.isNotEmpty) {
                          ninController.verifyId(_idNumberController.text, _selectedIdType!);
                        }
                      },
                      child: ninController.isVerifying
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify'),
                    ),
                    const SizedBox(height: 10),

                    /// **Verification Result**
                    if (ninController.verificationMessage.isNotEmpty)
                      Text(
                        ninController.verificationMessage,
                        style: TextStyle(
                          color: ninController.verificationMessage.startsWith('✅')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  /// **Step 3: Full Registration Form**
                  if (_showFullForm || (ninController.ninData != null)) ...[
                    _buildFullForm(ninController),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullForm(NinVerificationController ninController) {
    final data = ninController.ninData;

    _firstNameController.text = data?['first_name'] ?? '';
    _middleNameController.text = data?['middle_name'] ?? '';
    _lastNameController.text = data?['last_name'] ?? '';
    _usernameController.text = data?['username'] ?? '';
    _emailController.text = data?['email'] ?? '';
    _telephoneController.text = data?['telephone'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(labelText: "First Name"),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _middleNameController,
          decoration: const InputDecoration(labelText: "Middle Name (Optional)"),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: "Last Name"),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(labelText: "Username"),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _telephoneController,
          decoration: const InputDecoration(labelText: "Telephone"),
        ),
        const SizedBox(height: 10),

        /// **Password Field**
        TextFormField(
          controller: _passwordController,
          obscureText: _isPasswordObscured,
          decoration: InputDecoration(
            labelText: "Password",
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordObscured = !_isPasswordObscured;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        /// **Confirm Password Field**
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _isConfirmPasswordObscured,
          decoration: InputDecoration(
            labelText: "Confirm Password",
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        /// **Transaction Pin**
        TextFormField(
          controller: _transactionPinController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Transaction Pin"),
        ),
        const SizedBox(height: 20),

        /// **Register Button**
        SizedBox(
          width: double.infinity, // Makes the button full width
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB6D00), // Orange color
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Registration Successful!")),
                );

                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.pushReplacementNamed(context, '/login'); // Redirect to login
                });
              }
            },
            child: const Text(
              'Register',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

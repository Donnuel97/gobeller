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
  bool _isTermsAccepted = false;

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
  bool _hasPopulatedFields = false;

  void _populateFieldsFromVerificationData(Map<String, dynamic> data) {
    _firstNameController.text = data['first_name'] ?? '';
    _middleNameController.text = data['middle_name'] ?? '';
    _lastNameController.text = data['last_name'] ?? '';
    _usernameController.text = data['username'] ?? '';
    _emailController.text = data['email'] ?? '';
    _telephoneController.text = data['phone_number1'] ?? data['telephone'] ?? '';
  }

  void _resetFormState() {
    _formKey.currentState?.reset();
    _idNumberController.clear();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _usernameController.clear();
    _emailController.clear();
    _telephoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _transactionPinController.clear();

    setState(() {
      _selectedIdType = null;
      _showIdInput = false;
      _showFullForm = false;
      _hasPopulatedFields = false;
      _isTermsAccepted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ninController = Provider.of<NinVerificationController>(context);

    if (ninController.ninData != null && !_hasPopulatedFields) {
      _populateFieldsFromVerificationData(ninController.ninData!);
      _hasPopulatedFields = true;
      _showFullForm = true;
    }

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

                  DropdownButtonFormField<String>(
                    value: _selectedIdType,
                    decoration: const InputDecoration(labelText: "Select ID Type"),
                    items: ["nin", "bvn", "passport-number"]
                        .map((idType) => DropdownMenuItem(value: idType, child: Text(idType)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedIdType = value;
                        _showIdInput = true;
                        _showFullForm = false;
                        _hasPopulatedFields = false;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  if (_showIdInput) ...[
                    TextFormField(
                      controller: _idNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Enter $_selectedIdType Number"),
                      validator: (value) =>
                      value == null || value.isEmpty ? "ID number is required" : null,
                    ),
                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () {
                        if (_idNumberController.text.isNotEmpty) {
                          ninController.verifyId(_idNumberController.text.trim(), _selectedIdType!);
                        }
                      },
                      child: ninController.isVerifying
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify'),
                    ),
                    const SizedBox(height: 10),

                    if (ninController.verificationMessage.isNotEmpty)
                      Text(
                        ninController.verificationMessage,
                        style: TextStyle(
                          color: ninController.verificationMessage.contains('Success')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  if (_showFullForm) _buildFullForm(ninController),
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
    String gender = (data?['gender'] ?? 'unspecified').toString().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: "First Name")),
        const SizedBox(height: 10),
        TextFormField(controller: _middleNameController, decoration: const InputDecoration(labelText: "Middle Name (Optional)")),
        const SizedBox(height: 10),
        TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: "Last Name")),
        const SizedBox(height: 10),
        TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: "Username")),
        const SizedBox(height: 10),
        TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
        const SizedBox(height: 10),
        TextFormField(controller: _telephoneController, decoration: const InputDecoration(labelText: "Telephone")),
        const SizedBox(height: 10),

        TextFormField(
          controller: _passwordController,
          obscureText: _isPasswordObscured,
          decoration: InputDecoration(
            labelText: "Password",
            suffixIcon: IconButton(
              icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
            ),
          ),
          validator: (value) => value != null && value.length < 6 ? "Min 6 characters" : null,
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _isConfirmPasswordObscured,
          decoration: InputDecoration(
            labelText: "Confirm Password",
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
            ),
          ),
          validator: (value) => value != _passwordController.text ? "Passwords don't match" : null,
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _transactionPinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(labelText: "Transaction Pin"),
          validator: (value) {
            if (value == null || value.length != 4) return "Enter a 4-digit PIN";
            if (int.tryParse(value) == null) return "Only digits allowed";
            return null;
          },
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Checkbox(
              value: _isTermsAccepted,
              onChanged: (value) {
                setState(() {
                  _isTermsAccepted = value ?? false;
                });
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isTermsAccepted = !_isTermsAccepted;
                  });
                },
                child: const Text(
                  'I accept the terms and privacy policy',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB6D00),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isTermsAccepted
                ? () async {
              if (_formKey.currentState?.validate() ?? false) {
                final controller = Provider.of<NinVerificationController>(context, listen: false);

                await controller.submitRegistration(
                  idType: _selectedIdType!,
                  idNumber: _idNumberController.text.trim(),
                  firstName: _firstNameController.text.trim(),
                  middleName: _middleNameController.text.trim(),
                  lastName: _lastNameController.text.trim(),
                  email: _emailController.text.trim(),
                  username: _usernameController.text.trim(),
                  telephone: _telephoneController.text.trim(),
                  gender: gender,
                  password: _passwordController.text.trim(),
                  transactionPin: int.parse(_transactionPinController.text.trim()),
                );

                if (controller.submissionMessage.contains("successful")) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Awaiting email verification")),
                  );
                  await Future.delayed(const Duration(seconds: 2));
                  _resetFormState();
                  Navigator.pushReplacementNamed(context, '/reg_success');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(controller.submissionMessage)),
                  );
                }
              }
            }
                : null,
            child: ninController.isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              'Register',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

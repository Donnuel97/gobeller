import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart'; // 👈 Add this
import 'package:gobeller/const/const_ui.dart';
import 'package:gobeller/controller/registration_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';



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
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _transactionPinController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String? _selectedIdType;
  bool _showIdInput = false;
  bool _showFullForm = false;
  bool _hasPopulatedFields = false;



  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;
  String? _logoUrl;  // Variable to store the logo URL


  // Fetch the primary color and logo URL from SharedPreferences
  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');  // Using the correct key name for settings

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];
      final tertiaryColorHex = data['customized-app-tertiary-color'] ?? '#ffffff';
      final logoUrl = data['customized-app-logo-url'];  // Fetch logo URL

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
        _tertiaryColor = Color(int.parse(tertiaryColorHex.replaceAll('#', '0xFF')));

        _logoUrl = logoUrl;  // Save the logo URL
      });
    }
  }

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset("")
      ..initialize().then((_) {
        setState(() {});
        _videoController!
          ..setLooping(true)
          ..setVolume(0)
          ..play();
      });
    _loadPrimaryColorAndLogo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _populateFieldsFromVerificationData(Map<String, dynamic> data) {
    _firstNameController.text = data['first_name'] ?? '';
    _middleNameController.text = data['middle_name'] ?? '';
    _lastNameController.text = data['last_name'] ?? '';
    _usernameController.text = data['username'] ?? '';
    _emailController.text = data['email'] ?? '';
    _telephoneController.text = data['phone_number1'] ?? data['telephone'] ?? '';
    _addressController.text = data['physical_address'] ?? '';
    _dobController.text = data['date_of_birth'] ?? '';
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
    _addressController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _transactionPinController.clear();
    _dobController.clear();

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoController != null && _videoController!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            // Container(color: Colors.black),
            Container(color: _tertiaryColor?.withOpacity(1),),

          Container(
            // color: const Color(0xCC051330),
            // color: _tertiaryColor,
          ),


          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: ConstUI.kMainPadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_logoUrl != null)
                        Image.network(
                          _logoUrl!,
                          width: 128,
                          height: 128,
                          fit: BoxFit.contain,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            } else {
                              return SizedBox(
                                width: 128,
                                height: 128,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ?? 1)
                                        : null,
                                  ),
                                ),
                              );
                            }
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'Getting Data...',
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                            ); // Show "Getting Data..." if image fails to load
                          },
                        ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Create Your Account",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            child: const Text(
                              "Already have an account? Login",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      DropdownButtonFormField<String>(
                        value: _selectedIdType,
                        decoration: InputDecoration(
                          labelText: "Select ID Type",
                          labelStyle: const TextStyle(color: Colors.black),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black),
                        items: const [
                          {"label": "Register with NIN", "value": "nin"},
                          {"label": "Register with BVN", "value": "bvn"},
                          {"label": "Register with Passport", "value": "passport-number"},
                        ].map((item) {
                          return DropdownMenuItem<String>(
                            value: item["value"]!,
                            child: Text(item["label"]!, style: const TextStyle(color: Colors.black)),
                          );
                        }).toList(),
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
                          decoration: const InputDecoration(labelText: "Enter ID Number"),
                          style: const TextStyle(color: Colors.black),
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
                              ? const CircularProgressIndicator(color: Colors.black)
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
        ],
      ),
    );
  }

  Widget _buildFullForm(NinVerificationController ninController) {
    final data = ninController.ninData;
    String gender = (data?['gender'] ?? 'unspecified').toString().toLowerCase();

    const labelStyle = TextStyle(color: Colors.black);
    const inputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.black),
    );

    InputDecoration inputDecoration(String label, {Widget? suffixIcon}) {
      return InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
        border: inputBorder,
        suffixIcon: suffixIcon,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _firstNameController,
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration("First Name"),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _middleNameController,
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration("Middle Name (Optional)"),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _lastNameController,
          style: const TextStyle(color:Colors.black),
          decoration: inputDecoration("Last Name"),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _usernameController,
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration("Username"),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _emailController,
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration("Email"),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _telephoneController,
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration("Telephone"),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressController,
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration("Address"),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _dobController,
          readOnly: true,
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration(
            "Date of Birth",
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.black),
          ),
          onTap: () async {
            DateTime initialDate;
            try {
              initialDate = DateTime.parse(_dobController.text);
            } catch (_) {
              initialDate = DateTime(2000);
            }

            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.orange,
                      onPrimary: Colors.black,
                      surface: Colors.grey,
                      onSurface: Colors.black,
                    ),
                    dialogBackgroundColor: Colors.black,
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              _dobController.text = picked.toIso8601String().split('T').first;
            }
          },
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _passwordController,
          obscureText: _isPasswordObscured,
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration(
            "Password",
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.black,
              ),
              onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
            ),
          ),
          validator: (value) => value != null && value.length < 6 ? "Min 6 characters" : null,
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _isConfirmPasswordObscured,
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration(
            "Confirm Password",
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.black,
              ),
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
          style: const TextStyle(color: Colors.black),
          decoration: inputDecoration("Transaction Pin"),
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
              checkColor: Colors.black,
              activeColor: Colors.black,
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
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                  ),
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
                  address: _addressController.text.trim(),
                  gender: gender,
                  password: _passwordController.text.trim(),
                  transactionPin: int.parse(_transactionPinController.text.trim()),
                  dateOfBirth: _dobController.text.trim(),
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
                ? const CircularProgressIndicator(color: Colors.black)
                : Text(
              'Register',
              style: TextStyle(color: _primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

}

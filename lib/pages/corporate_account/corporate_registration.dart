import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CorporateAccountRegistrationPage extends StatefulWidget {
  const CorporateAccountRegistrationPage({Key? key}) : super(key: key);

  @override
  _CorporateAccountRegistrationPageState createState() =>
      _CorporateAccountRegistrationPageState();
}

class _CorporateAccountRegistrationPageState
    extends State<CorporateAccountRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rcNoController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _cacStatusReportController =
  TextEditingController();
  XFile? _cacCertificateFile;
  XFile? _cacMoaFile;
  XFile? _recentPassportFile;
  XFile? _file; // For other file uploads

  bool isLoading = false;

  final _picker = ImagePicker();

  Future<void> _pickFile(String type) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case 'cacCertificate':
            _cacCertificateFile = pickedFile;
            break;
          case 'cacMoa':
            _cacMoaFile = pickedFile;
            break;
          case 'passport':
            _recentPassportFile = pickedFile;
            break;
          case 'file':
            _file = pickedFile;
            break;
          default:
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      // Here, submit the form data to your backend/API
      // You can also include the files that have been picked (_cacCertificateFile, _cacMoaFile, etc.)

      // Example: simulate a delay (like an API call)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corporate Account Registration Successful!')),
      );

      // Reset the form
      _formKey.currentState?.reset();
    }
  }

  @override
  void dispose() {
    _rcNoController.dispose();
    _businessNameController.dispose();
    _phoneNumberController.dispose();
    _tinController.dispose();
    _bvnController.dispose();
    _ninController.dispose();
    _cacStatusReportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corporate Account Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RC No'),
                TextFormField(
                  controller: _rcNoController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter RC No',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the RC No.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('Business Name'),
                TextFormField(
                  controller: _businessNameController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Business Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the Business Name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('Phone Number'),
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Phone Number',
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length != 10) {
                      return 'Please enter a valid phone number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('TIN'),
                TextFormField(
                  controller: _tinController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter TIN',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the TIN.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('BVN'),
                TextFormField(
                  controller: _bvnController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter BVN',
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length != 11) {
                      return 'Please enter a valid BVN.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('NIN'),
                TextFormField(
                  controller: _ninController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter NIN',
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length != 11) {
                      return 'Please enter a valid NIN.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('CAC Certificate'),
                ElevatedButton(
                  onPressed: () => _pickFile('cacCertificate'),
                  child: Text(_cacCertificateFile == null
                      ? 'Upload CAC Certificate'
                      : 'File Selected'),
                ),
                const SizedBox(height: 16),

                const Text('CAC MOA Document'),
                ElevatedButton(
                  onPressed: () => _pickFile('cacMoa'),
                  child: Text(_cacMoaFile == null
                      ? 'Upload CAC MOA Document'
                      : 'File Selected'),
                ),
                const SizedBox(height: 16),

                const Text('CAC Status Report (Optional)'),
                ElevatedButton(
                  onPressed: () => _pickFile('cacStatusReport'),
                  child: Text(_cacStatusReportController.text.isEmpty
                      ? 'Upload CAC Status Report'
                      : 'File Selected'),
                ),
                const SizedBox(height: 16),

                const Text('Recent Passport'),
                ElevatedButton(
                  onPressed: () => _pickFile('passport'),
                  child: Text(_recentPassportFile == null
                      ? 'Upload Recent Passport'
                      : 'File Selected'),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEB6D00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                      "Register Corporate Account",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

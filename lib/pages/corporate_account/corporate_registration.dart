import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controller/CacVerificationController.dart';


class CorporateAccountRegistrationPage extends StatefulWidget {
  const CorporateAccountRegistrationPage({Key? key}) : super(key: key);

  @override
  _CorporateAccountRegistrationPageState createState() =>
      _CorporateAccountRegistrationPageState();
}

class _CorporateAccountRegistrationPageState
    extends State<CorporateAccountRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _corporateIdNumberController =
  TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  String? selectedCorporateIdType;

  XFile? _cacCertificateFile;
  XFile? _cacMoaFile;
  XFile? _recentPassportFile;

  final _picker = ImagePicker();
  bool isLoading = false;

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
        }
      });
    }
  }

  void _verifyCorporateId(BuildContext context) {
    final controller =
    Provider.of<CacVerificationController>(context, listen: false);
    controller.verifyCacNumber(
      corporateIdType: selectedCorporateIdType!,
      corporateIdNumber: _corporateIdNumberController.text.trim(),
      context: context,
    );
  }

  void _submitForm(BuildContext context) async {
    final cacController = Provider.of<CacVerificationController>(context, listen: false);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (cacController.companyDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please verify CAC before submitting.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulate API

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Corporate Account Registration Successful!')),
    );

    _formKey.currentState?.reset();
  }

  @override
  void dispose() {
    _corporateIdNumberController.dispose();
    _phoneNumberController.dispose();
    _tinController.dispose();
    _bvnController.dispose();
    _ninController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CacVerificationController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Corporate Account Registration')),
        body: Consumer<CacVerificationController>(
          builder: (context, cacController, _) {
            final isVerified = cacController.companyDetails != null;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Corporate ID Type'),
                      DropdownButtonFormField<String>(
                        value: selectedCorporateIdType,
                        items: const [
                          DropdownMenuItem(
                            value: 'cac-bn-number',
                            child: Text('CAC BN Number'),
                          ),
                          DropdownMenuItem(
                            value: 'cac-rc-number',
                            child: Text('CAC RC Number'),
                          ),
                          DropdownMenuItem(
                            value: 'cac-it-number',
                            child: Text('CAC IT Number'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCorporateIdType = value;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Select Corporate ID Type',
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Corporate ID Number'),
                      TextFormField(
                        controller: _corporateIdNumberController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter Corporate ID Number',
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedCorporateIdType == null ||
                              cacController.isVerifying
                              ? null
                              : () => _verifyCorporateId(context),
                          child: cacController.isVerifying
                              ? const CircularProgressIndicator()
                              : const Text('Verify CAC'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (isVerified) ...[
                        Text(
                          "✅ Verified: ${cacController.companyDetails?['company_name'] ?? ''}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
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
                            if (value == null || value.length != 10) {
                              return 'Enter valid phone number.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text('TIN'),
                        TextFormField(
                          controller: _tinController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Enter TIN',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter TIN.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text('BVN'),
                        TextFormField(
                          controller: _bvnController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Enter BVN',
                          ),
                          validator: (value) {
                            if (value == null || value.length != 11) {
                              return 'Enter valid BVN.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text('NIN'),
                        TextFormField(
                          controller: _ninController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Enter NIN',
                          ),
                          validator: (value) {
                            if (value == null || value.length != 11) {
                              return 'Enter valid NIN.';
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

                        const Text('Recent Passport'),
                        ElevatedButton(
                          onPressed: () => _pickFile('passport'),
                          child: Text(_recentPassportFile == null
                              ? 'Upload Passport'
                              : 'File Selected'),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _submitForm(context),
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
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

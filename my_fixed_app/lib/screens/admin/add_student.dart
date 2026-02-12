// lib/screens/admin/add_student.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  File? _profileImageFile;
  Uint8List? _profileImageBytes;
  XFile? _pickedXFile;

  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _departmentController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollNumberController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // API endpoint - update with your server URL
  final String _apiUrl = 'http://127.0.0.1:5000/api/students/add'; // Change this to your server IP

  // Glassmorphism Colors
  final Color _primaryRed = const Color(0xFFDC2626);
  final Color _darkRed = const Color(0xFF991B1B);
  final Color _glassWhite = Colors.white.withOpacity(0.1);
  final Color _glassBorder = Colors.white.withOpacity(0.2);

  // Pick Image
  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _profileImageBytes = bytes;
          _profileImageFile = null;
          _pickedXFile = picked;
        });
      } else {
        final file = File(picked.path);
        final compressed = await _compressImage(file);
        setState(() {
          _profileImageFile = compressed;
          _profileImageBytes = null;
          _pickedXFile = picked;
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        _showErrorDialog('Image Pick Error', 'Failed to pick image: $e');
      }
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final outPath = file.path.replaceAll(RegExp(r'\.[^\.]+$'), '_comp.jpg');
      final dynamic result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        outPath,
        quality: 80,
      );
      if (result == null) return file;
      if (result is File) return result;
      if (result is XFile) return File(result.path);
      return file;
    } catch (e) {
      debugPrint('Compression error: $e');
      return file;
    }
  }

  // Convert image to base64 for sending to server
  Future<String?> _imageToBase64() async {
    try {
      if (kIsWeb) {
        if (_profileImageBytes != null) {
          return base64Encode(_profileImageBytes!);
        }
      } else {
        if (_profileImageFile != null) {
          final bytes = await _profileImageFile!.readAsBytes();
          return base64Encode(bytes);
        }
      }
    } catch (e) {
      debugPrint('Image to base64 error: $e');
    }
    return null;
  }

  // Beautiful Error Dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: _primaryRed,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [_primaryRed, _darkRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Success Dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'Success!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Student account created successfully',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [_primaryRed, _darkRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Submit Form to MySQL via API
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final department = _departmentController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final gender = _selectedGender ?? '';
    final guardianName = _guardianNameController.text.trim();
    final guardianPhone = _guardianPhoneController.text.trim();
    final password = _passwordController.text;
    final rollNumber = _rollNumberController.text.trim();

    // Validate Date of Birth
    final dobText = _dobController.text.trim();
    String formattedDob = '';

    if (dobText.isNotEmpty) {
      try {
        final dobDate = DateTime.parse(dobText);
        formattedDob = DateFormat('yyyy-MM-dd').format(dobDate);
      } catch (e) {
        _showErrorDialog('Invalid Date',
            'Please select a valid date of birth in YYYY-MM-DD format.');
        return;
      }
    } else {
      _showErrorDialog('Missing Date', 'Date of birth is required.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert image to base64 if exists
      String? base64Image = await _imageToBase64();

      // Prepare data for API
      final studentData = {
        'name': name,
        'rollNumber': rollNumber,
        'dob': formattedDob,
        'department': department,
        'address': address,
        'phone': phone,
        'gender': gender,
        'guardian_name': guardianName,
        'guardian_phone': guardianPhone,
        'password': password,
        'profile_image': base64Image, // Optional
      };

      // Send POST request to backend
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(studentData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add student');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Creation Failed', 'Failed to create student account: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _dobController.clear();
    _departmentController.clear();
    _addressController.clear();
    _phoneController.clear();
    _selectedGender = null;
    _guardianNameController.clear();
    _guardianPhoneController.clear();
    _passwordController.clear();
    _rollNumberController.clear();
    setState(() {
      _profileImageFile = null;
      _profileImageBytes = null;
      _pickedXFile = null;
    });
  }

  // Build Input Field
  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false,
      TextInputType? keyboardType,
      String? Function(String?)? validator,
      Widget? suffixIcon,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _glassBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: _primaryRed.withOpacity(0.8), width: 2),
            ),
            filled: true,
            fillColor: _glassWhite,
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          validator: validator ??
              (value) {
                if (value == null || value.trim().isEmpty) {
                  return "$label is required.";
                }
                return null;
              },
        ),
      ),
    );
  }

  // Image Preview
  Widget _imagePreview(double radius) {
    Widget imageWidget;

    if (kIsWeb) {
      if (_profileImageBytes != null) {
        imageWidget = CircleAvatar(
            radius: radius, backgroundImage: MemoryImage(_profileImageBytes!));
      } else {
        imageWidget = CircleAvatar(
          radius: radius,
          backgroundColor: _glassWhite,
          child: Icon(Icons.camera_alt, color: Colors.white70, size: 30),
        );
      }
    } else {
      if (_profileImageFile != null) {
        imageWidget = CircleAvatar(
            radius: radius, backgroundImage: FileImage(_profileImageFile!));
      } else {
        imageWidget = CircleAvatar(
          radius: radius,
          backgroundColor: _glassWhite,
          child: Icon(Icons.camera_alt, color: Colors.white70, size: 30),
        );
      }
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _glassBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2D1B1B),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _glassWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _glassBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Add Student',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create student account',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Profile Image
                      Center(child: _imagePreview(50)),
                      const SizedBox(height: 24),

                      _buildTextField(_nameController, 'Name'),

                      // DOB Date Picker
                      _buildTextField(
                        _dobController,
                        'Date of Birth',
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Date of birth is required.";
                          }
                          try {
                            DateTime.parse(value);
                            return null;
                          } catch (_) {
                            return "Please enter a valid date (YYYY-MM-DD).";
                          }
                        },
                        onTap: () async {
                          final DateTime initialDate = DateTime.now().subtract(
                              const Duration(days: 365 * 18));
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFFDC2626),
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF2A1A1A),
                                    onSurface: Colors.white,
                                  ),
                                  dialogBackgroundColor:
                                      const Color(0xFF2A1A1A),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (picked != null) {
                            setState(() {
                              _dobController.text =
                                  DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                      ),

                      _buildTextField(
                        _rollNumberController,
                        'Roll Number',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Roll number is required.";
                          }
                          if (value.contains(' ')) {
                            return "Roll number cannot contain spaces.";
                          }
                          if (RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                              .hasMatch(value)) {
                            return "Roll number cannot contain special characters.";
                          }
                          return null;
                        },
                      ),

                      // Department Dropdown
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _departmentController.text.isEmpty
                                ? null
                                : _departmentController.text,
                            dropdownColor: const Color(0xFF2A1A1A),
                            style: const TextStyle(color: Colors.white),
                            items: [
                              'IT',
                              'CSE',
                              'ECE',
                              'EEE',
                              'Civil',
                              'MBA',
                              'MCA',
                              'Mech'
                            ].map<DropdownMenuItem<String>>(
                                (String department) {
                              return DropdownMenuItem<String>(
                                value: department,
                                child: Text(
                                  department,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _departmentController.text = newValue ?? '';
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Department',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: _glassBorder, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: _primaryRed.withOpacity(0.8),
                                    width: 2),
                              ),
                              filled: true,
                              fillColor: _glassWhite,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Department is required.";
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      _buildTextField(_addressController, 'Address'),

                      _buildTextField(
                        _phoneController,
                        'Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Phone number is required.";
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return "Enter a valid 10-digit phone number.";
                          }
                          return null;
                        },
                      ),

                      // Gender Dropdown
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            dropdownColor: const Color(0xFF2A1A1A),
                            style: const TextStyle(color: Colors.white),
                            items: ['Male', 'Female', 'Other']
                                .map<DropdownMenuItem<String>>(
                                    (g) => DropdownMenuItem<String>(
                                          value: g,
                                          child: Text(g),
                                        ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedGender = val),
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: _glassBorder, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: _primaryRed.withOpacity(0.8),
                                    width: 2),
                              ),
                              filled: true,
                              fillColor: _glassWhite,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            validator: (value) =>
                                value == null ? 'Please select a gender' : null,
                          ),
                        ),
                      ),

                      _buildTextField(
                          _guardianNameController, "Guardian's Name"),
                      _buildTextField(
                        _guardianPhoneController,
                        "Guardian's Phone",
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Guardian's phone is required.";
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return "Enter a valid 10-digit phone number.";
                          }
                          return null;
                        },
                      ),

                      _buildTextField(
                        _passwordController,
                        'Password',
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required.";
                          }
                          if (value.length < 6) {
                            return "Password must be at least 6 characters.";
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(
                                () => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                      ),

                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [_primaryRed, _darkRed],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryRed.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create Student Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _passwordController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }
}
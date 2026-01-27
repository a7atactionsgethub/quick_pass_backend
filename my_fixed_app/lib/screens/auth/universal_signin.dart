// universal_signin.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class UniversalSignIn extends StatefulWidget {
  const UniversalSignIn({super.key});

  @override
  State<UniversalSignIn> createState() => _UniversalSignInState();
}

class _UniversalSignInState extends State<UniversalSignIn> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Student';
  String _errorMessage = '';
  int _failedAttempts = 0;
  DateTime? _blockTime;
  Timer? _timer;

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const String _studentEmailDomain = 'students.mygate';

  // Glassmorphism Colors (same as AddStudentPage)
  final Color _primaryRed = const Color(0xFFDC2626);
  final Color _darkRed = const Color(0xFF991B1B);
  final Color _glassWhite = Colors.white.withOpacity(0.1);
  final Color _glassBorder = Colors.white.withOpacity(0.2);

  // Backend URL
  static const String backendUrl = 'http://localhost:5000/api/auth/login';

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_blockTime != null && DateTime.now().isAfter(_blockTime!)) {
        setState(() {
          _errorMessage = '';
          _failedAttempts = 0;
          _blockTime = null;
        });
        timer.cancel();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    String identifier = _usernameController.text.trim();
    final password = _passwordController.text;

    if (_blockTime != null && DateTime.now().isBefore(_blockTime!)) {
      final remaining = _blockTime!.difference(DateTime.now()).inSeconds;
      _setError('Blocked. Try again in ${remaining}s');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
          'role': _selectedRole.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        switch (data['role']) {
          case 'admin':
            context.go('/admin');
            break;
          case 'security':
            context.go('/qr-scanner');
            break;
          case 'student':
            context.go('/student-home', extra: {
              'studentName': data['name'],
              'profileImageUrl': data['profileImageUrl'] ?? '',
              'studentDocId': data['identifier'], // using identifier from backend
              'token': data['token'], // optional
            });
            break;
          default:
            _handleFailure('Unrecognized role from server');
        }
      } else if (response.statusCode == 401) {
        _handleFailure('Invalid credentials');
      } else {
        _handleFailure('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Unexpected error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _handleFailure(String message) {
    setState(() {
      _failedAttempts++;
      _errorMessage = message;
      if (_failedAttempts >= 5) {
        _blockTime = DateTime.now().add(const Duration(minutes: 5));
        _startTimer();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Custom text field builder matching AddStudentPage style
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    Widget? prefixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
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
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: prefixIcon,
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

  @override
  Widget build(BuildContext context) {
    final remainingTime = _blockTime != null
        ? _blockTime!.difference(DateTime.now()).inSeconds
        : 0;

    final isStudent = _selectedRole.toLowerCase() == 'student';

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
                constraints: const BoxConstraints(maxWidth: 500),
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
                        'Welcome Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Role Dropdown
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
                            value: _selectedRole,
                            dropdownColor: const Color(0xFF2A1A1A),
                            style: const TextStyle(color: Colors.white),
                            items: ['Student', 'Admin', 'Security']
                                .map<DropdownMenuItem<String>>(
                                  (String role) => DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(
                                      role,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedRole = newValue!;
                                _errorMessage = '';
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Select Role',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.person_outline,
                                  color: Colors.white70),
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
                                return "Role is required.";
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      // Username/Roll Number Field
                      _buildTextField(
                        _usernameController,
                        isStudent ? 'Roll Number' : 'Email',
                        keyboardType:
                            isStudent ? TextInputType.text : TextInputType.emailAddress,
                        prefixIcon: Icon(
                          isStudent ? Icons.badge_outlined : Icons.email_outlined,
                          color: Colors.white70,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isStudent
                                ? 'Roll number is required'
                                : 'Email is required';
                          }
                          if (!isStudent && !value.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      // Password Field
                      _buildTextField(
                        _passwordController,
                        'Password',
                        obscureText: _obscurePassword,
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required.";
                          }
                          if (value.length < 6) {
                            return "Password must be at least 6 characters.";
                          }
                          return null;
                        },
                      ),

                      if (_blockTime != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_clock, color: _primaryRed, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Blocked for ${remainingTime}s',
                                style: TextStyle(
                                  color: _primaryRed,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Login Button
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
                          onPressed: _isLoading ? null : () => _handleLogin(context),
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
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      // Error Message
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: _primaryRed, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: _primaryRed,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Home Button
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          onPressed: () => context.go('/'),
                          backgroundColor: _glassWhite,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.home_outlined),
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
}

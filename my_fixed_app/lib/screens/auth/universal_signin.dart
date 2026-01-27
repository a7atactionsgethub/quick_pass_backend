// universal_signin.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UniversalSignIn extends StatefulWidget {
  const UniversalSignIn({super.key});

  @override
  State<UniversalSignIn> createState() => _UniversalSignInState();
}

class _UniversalSignInState extends State<UniversalSignIn> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    String input = _usernameController.text.trim();
    final password = _passwordController.text;

    if (_blockTime != null && DateTime.now().isBefore(_blockTime!)) {
      final remaining = _blockTime!.difference(DateTime.now()).inSeconds;
      _setError('Blocked. Try again in ${remaining}s');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String authEmailToUse;

      if (_selectedRole.toLowerCase() == 'student') {
        if (input.isEmpty) {
          _handleFailure('Enter roll number');
          return;
        }
        authEmailToUse = '${input.toLowerCase()}@$_studentEmailDomain';
      } else {
        authEmailToUse = input;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: authEmailToUse,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        _handleFailure('Authentication failed');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || !doc.data()!.containsKey('role')) {
        _handleFailure('User role not found');
        return;
      }

      final role = (doc.data()!['role'] ?? '').toString().trim().toLowerCase();
      final selectedRole = _selectedRole.trim().toLowerCase();

      if (role != selectedRole) {
        _handleFailure('Incorrect role selected for this account');
        return;
      }

      switch (role) {
        case 'admin':
          context.go('/admin');
          break;
        case 'security':
          context.go('/qr-scanner');
          break;
        case 'student':
          DocumentSnapshot<Map<String, dynamic>>? studentDoc;

          final studentByUidQuery = await FirebaseFirestore.instance
              .collection('students')
              .where('uid', isEqualTo: user.uid)
              .limit(1)
              .get();

          if (studentByUidQuery.docs.isNotEmpty) {
            studentDoc = studentByUidQuery.docs.first;
          } else {
            final byUsername = await FirebaseFirestore.instance
                .collection('students')
                .where('username', isEqualTo: _usernameController.text.trim())
                .limit(1)
                .get();

            if (byUsername.docs.isNotEmpty) {
              studentDoc = byUsername.docs.first;
            } else {
              final authEmail = '${_usernameController.text.trim().toLowerCase()}@$_studentEmailDomain';
              final byAuthEmail = await FirebaseFirestore.instance
                  .collection('students')
                  .where('authEmail', isEqualTo: authEmail)
                  .limit(1)
                  .get();
              if (byAuthEmail.docs.isNotEmpty) {
                studentDoc = byAuthEmail.docs.first;
              }
            }
          }

          if (studentDoc == null) {
            _handleFailure('Student record not found. Contact admin.');
            return;
          }

          final sdata = studentDoc.data()!;
          final studentName = (sdata['name'] ?? '').toString();
          final profileImageUrl = (sdata['profileImageUrl'] ?? '').toString();

          context.go('/student-home', extra: {
            'studentName': studentName,
            'profileImageUrl': profileImageUrl,
            'studentDocId': studentDoc.id,
            'uid': user.uid,
          });
          break;
        default:
          _handleFailure('Unrecognized role');
      }
    } on FirebaseAuthException catch (e) {
      _handleFailure(_getErrorMessage(e.code));
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

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'Account disabled';
      case 'user-not-found':
        return 'No account found';
      case 'wrong-password':
        return 'Wrong password';
      default:
        return 'Login failed: $code';
    }
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
              borderSide: BorderSide(color: _primaryRed.withOpacity(0.8), width: 2),
            ),
            filled: true,
            fillColor: _glassWhite,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

                      // Role Dropdown (consistent with AddStudentPage)
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
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.person_outline, color: Colors.white70),
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
                                borderSide: BorderSide(color: _primaryRed.withOpacity(0.8), width: 2),
                              ),
                              filled: true,
                              fillColor: _glassWhite,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        keyboardType: isStudent ? TextInputType.text : TextInputType.emailAddress,
                        prefixIcon: Icon(
                          isStudent ? Icons.badge_outlined : Icons.email_outlined,
                          color: Colors.white70,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isStudent ? 'Roll number is required' : 'Email is required';
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
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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

                      // Login Button (matching AddStudentPage style)
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
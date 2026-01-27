import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GatePassRequest extends StatefulWidget {
  const GatePassRequest({super.key});

  @override
  _GatePassRequestState createState() => _GatePassRequestState();
}

class _GatePassRequestState extends State<GatePassRequest> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final rollController = TextEditingController();
  final deptController = TextEditingController();
  final reasonController = TextEditingController();

  DateTime? _departureDateTime;
  DateTime? _returnDateTime;

  bool _isSubmitting = false;
  bool _isLoadingStudent = true;

  // 🎯 Color Palette
  final Color _primaryRed = const Color(0xFFDC2626);
  final Color _darkRed = const Color(0xFF991B1B);
  final Color _glassWhite = Colors.white.withOpacity(0.1);
  final Color _glassBorder = Colors.white.withOpacity(0.2);
  final Color _textWhite = Colors.white;
  final Color _textWhite70 = Colors.white.withOpacity(0.7);
  final Color _textWhite54 = Colors.white.withOpacity(0.54);

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoadingStudent = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoadingStudent = false);
        return;
      }

      final studentsCol = FirebaseFirestore.instance.collection('students');
      DocumentSnapshot<Map<String, dynamic>>? studentDoc;

      final byUid = await studentsCol.where('uid', isEqualTo: user.uid).limit(1).get();
      if (byUid.docs.isNotEmpty) {
        studentDoc = byUid.docs.first;
      } else {
        final byUsername = await studentsCol.where('username', isEqualTo: user.email).limit(1).get();
        if (byUsername.docs.isNotEmpty) {
          studentDoc = byUsername.docs.first;
        } else {
          final byAuthEmail = await studentsCol.where('authEmail', isEqualTo: user.email).limit(1).get();
          if (byAuthEmail.docs.isNotEmpty) studentDoc = byAuthEmail.docs.first;
        }
      }

      if (studentDoc != null) {
        final data = studentDoc.data()!;
        nameController.text = (data['name'] ?? '').toString();
        rollController.text = (data['rollNumber'] ?? data['username'] ?? '').toString();
        deptController.text = (data['department'] ?? data['dept'] ?? '').toString();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load student data: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingStudent = false);
    }
  }

  Future<void> submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_departureDateTime == null || _returnDateTime == null) {
      _showSnackBar('Please select both Departure and Return Date & Time');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final email = user?.email;

    setState(() => _isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('gatepass_requests').doc();

      final data = {
        'uid': uid ?? '',
        'email': email ?? '',
        'studentName': nameController.text.trim(),
        'rollNumber': rollController.text.trim(),
        'department': deptController.text.trim(),
        'reason': reasonController.text.trim(),
        'departureTime': _departureDateTime!.toIso8601String(),
        'returnTime': _returnDateTime!.toIso8601String(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);

      if (!mounted) return;
      _showSnackBar('Request submitted successfully');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to submit request: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    rollController.dispose();
    deptController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  // ✨ Glassmorphism Form Field
  Widget _buildFormField(
    String label,
    IconData icon,
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        style: TextStyle(color: _textWhite, fontSize: 16),
        cursorColor: _primaryRed,
        validator: readOnly ? null : (v) => v == null || v.trim().isEmpty ? '$label is required' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textWhite70),
          prefixIcon: Icon(icon, color: _textWhite70),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: TextStyle(color: Colors.red.shade200),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ✨ Glassmorphism DateTime Field
  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final formatted = value != null ? _formatDateTime(value) : 'Select $label';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.access_time_outlined, color: _textWhite70),
        title: Text(
          label,
          style: TextStyle(
            color: _textWhite,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          formatted,
          style: TextStyle(
            color: value != null ? _textWhite70 : _textWhite54,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.arrow_drop_down, color: _textWhite70),
        onTap: _isSubmitting ? null : onTap,
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _primaryRed,
              onPrimary: Colors.white,
              surface: const Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF2D1B1B)),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _primaryRed,
              onPrimary: Colors.white,
              surface: const Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF2D1B1B)),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} at ${_formatTime(dt)}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStudent) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
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
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: _glassWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _glassBorder),
              ),
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_textWhite),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _glassWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: _textWhite70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Request Gate Pass',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _textWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildFormField('Full Name', Icons.person_outline, nameController, readOnly: true),
                          _buildFormField('Roll Number', Icons.numbers_outlined, rollController, readOnly: true),
                          _buildFormField('Department', Icons.school_outlined, deptController, readOnly: true),
                          _buildFormField('Reason for Leave', Icons.note_outlined, reasonController, maxLines: 4),
                          _buildDateTimeField(
                            label: 'Departure Date & Time',
                            value: _departureDateTime,
                            onTap: () async {
                              final picked = await _pickDateTime(context);
                              if (picked != null) setState(() => _departureDateTime = picked);
                            },
                          ),
                          _buildDateTimeField(
                            label: 'Return Date & Time',
                            value: _returnDateTime,
                            onTap: () async {
                              final picked = await _pickDateTime(context);
                              if (picked != null) setState(() => _returnDateTime = picked);
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFDC2626),
                        Color(0xFF991B1B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(_textWhite),
                            ),
                          )
                        : Text(
                            'Submit Request',
                            style: TextStyle(
                              color: _textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
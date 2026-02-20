// gatepass_request.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GatePassRequest extends StatefulWidget {
  const GatePassRequest({super.key});

  @override
  State<GatePassRequest> createState() => _GatePassRequestState();
}

class _GatePassRequestState extends State<GatePassRequest> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController rollController = TextEditingController();
  final TextEditingController deptController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  DateTime? _departureDateTime;
  DateTime? _returnDateTime;

  bool _isSubmitting = false;
  bool _isLoadingStudent = true;

  String? _currentRollNumber;
  String? _currentStudentName;

  final String _baseUrl = 'http://127.0.0.1:5000/api';

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoadingStudent = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      _currentRollNumber = prefs.getString('rollNumber');
      _currentStudentName = prefs.getString('studentName');

      if (_currentRollNumber == null || _currentRollNumber!.isEmpty) {
        print("❌ Roll number missing in SharedPreferences");
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/students/${_currentRollNumber!}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        nameController.text =
            data['name'] ?? _currentStudentName ?? '';
        rollController.text = _currentRollNumber!;
        deptController.text = data['department'] ?? '';
      } else {
        nameController.text = _currentStudentName ?? '';
        rollController.text = _currentRollNumber!;
      }
    } catch (e) {
      print("❌ Error loading student: $e");
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

    if (_currentRollNumber == null) {
      _showSnackBar('Student information missing');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final requestData = {
        'rollNumber': _currentRollNumber,
        'studentName': nameController.text.trim(),
        'department': deptController.text.trim(),
        'reason': reasonController.text.trim(),
        'departureTime': _departureDateTime!.toIso8601String(),
        'returnTime': _returnDateTime!.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/gatepass/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _showSnackBar('Request submitted successfully');
        Navigator.pop(context);
      } else {
        throw Exception('Failed to submit request');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to submit request');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStudent) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Request Gate Pass')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextFormField(
                controller: rollController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Roll Number'),
              ),
              TextFormField(
                controller: deptController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Reason required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final picked = await _pickDateTime(context);
                  if (picked != null) {
                    setState(() => _departureDateTime = picked);
                  }
                },
                child: const Text('Select Departure Time'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final picked = await _pickDateTime(context);
                  if (picked != null) {
                    setState(() => _returnDateTime = picked);
                  }
                },
                child: const Text('Select Return Time'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : submitRequest,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
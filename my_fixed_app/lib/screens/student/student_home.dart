// student_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'gatepass_request.dart';
import 'view_requests.dart';
import '../settings/settings_screen.dart';
import 'dart:convert';
class StudentHomeScreen extends StatefulWidget {
  final String studentName;
  final String profileImageUrl;
  final String rollNumber;
  final String token;

  const StudentHomeScreen({
    super.key,
    required this.studentName,
    required this.profileImageUrl,
    required this.rollNumber,
    required this.token,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late String _studentName;
  late String _profileImageUrl;
  late String _rollNumber;
  late String _token;
  bool _loading = false;

  // Backend URL
  final String _baseUrl = 'http://127.0.0.1:5000/api';

  // Glassmorphism Colors
  final Color _primaryRed = const Color(0xFFDC2626);
  final Color _darkRed = const Color(0xFF991B1B);
  final Color _glassWhite = Colors.white.withOpacity(0.1);
  final Color _glassBorder = Colors.white.withOpacity(0.2);

  // Stats
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _studentName = widget.studentName;
    _profileImageUrl = widget.profileImageUrl;
    _rollNumber = widget.rollNumber;
    _token = widget.token;
    
    _loadStudentStats();
    _saveAuthData();
  }

  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rollNumber', _rollNumber);
      await prefs.setString('token', _token);
      await prefs.setString('studentName', _studentName);
      await prefs.setString('profileImageUrl', _profileImageUrl);
    } catch (e) {
      debugPrint('Error saving auth data: $e');
    }
  }

  Future<void> _loadStudentStats() async {
    setState(() => _loading = true);
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/students/$_rollNumber/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingCount = data['pending'] ?? 0;
          _approvedCount = data['approved'] ?? 0;
          _rejectedCount = data['rejected'] ?? 0;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        context.go('/signin');
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (mounted) {
        context.go('/signin');
      }
    }
  }

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final doLogout = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
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
                Icons.logout_rounded,
                color: _primaryRed,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _glassBorder),
                        color: _glassWhite,
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
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
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (doLogout == true) {
      showDialog(
        context: context, 
        barrierDismissible: false, 
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
      await _logout();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

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
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeaderSection(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildMainActionsSection(),
                          const SizedBox(height: 24),
                          _buildQuickStatsSection(),
                          const SizedBox(height: 32),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
  return Container(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _glassBorder, width: 2),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFDC2626),
                Color(0xFF991B1B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _profileImageUrl.isNotEmpty 
              ? _profileImageUrl.startsWith('http')
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(_profileImageUrl),
                    ) // URL image
                  : CircleAvatar(
                      backgroundImage: MemoryImage(
                        base64Decode(_profileImageUrl),
                      ),
                    ) // Base64 image
              : Icon(
                  Icons.person,
                  color: Colors.white.withOpacity(0.8),
                  size: 24,
                ),
        ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _studentName.isNotEmpty ? _studentName : 'Student',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Roll No: $_rollNumber',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _glassWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _glassBorder),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined, 
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Gate Pass Management",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Manage your hostel gate passes",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureCard(
            "Request Gate Pass",
            Icons.note_add_outlined,
            "Create a new gate pass request",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GatePassRequest(
                    rollNumber: _rollNumber,
                    studentName: _studentName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            "View My Requests",
            Icons.list_alt_outlined,
            "Check your gate pass status",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyGatePass(
                    rollNumber: _rollNumber,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            "View History",
            Icons.history_outlined,
            "See your past gate passes",
            () {
              context.push('/view-history', extra: {
                'rollNumber': _rollNumber,
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Stats",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Pending", _pendingCount.toString(), Icons.pending_actions_outlined),
              _buildStatItem("Approved", _approvedCount.toString(), Icons.check_circle_outline),
              _buildStatItem("Rejected", _rejectedCount.toString(), Icons.cancel_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glassBorder),
        color: _glassWhite,
      ),
      child: TextButton.icon(
        onPressed: () => _confirmAndSignOut(context),
        icon: Icon(
          Icons.logout_rounded,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glassBorder),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryRed.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _glassWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded, 
            color: Colors.white.withOpacity(0.7), 
            size: 16
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryRed.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
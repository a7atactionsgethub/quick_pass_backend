import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int totalStudents = 0;
  int outStudents = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> outStudentDetails = [];
  List<Map<String, dynamic>> inStudentDetails = [];

  // Glassmorphism Colors
  final Color _primaryRed = const Color(0xFFDC2626);
  final Color _darkRed = const Color(0xFF991B1B);
  final Color _primaryBlue = const Color(0xFF2563EB);
  final Color _darkBlue = const Color(0xFF1D4ED8);
  final Color _primaryGreen = const Color(0xFF059669);
  final Color _darkGreen = const Color(0xFF047857);
  final Color _glassWhite = Colors.white.withOpacity(0.1);
  final Color _glassBorder = Colors.white.withOpacity(0.2);

  @override
  void initState() {
    super.initState();
    _loadStatsAndDetails();
  }

  /// 🔹 TEMP DATA (replace with backend API later)
  Future<void> _loadStatsAndDetails() async {
    setState(() => isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    totalStudents = 120;
    outStudents = 18;

    outStudentDetails = [
      {'name': 'Arun', 'roll': '21CS001', 'department': 'CSE'},
      {'name': 'Kumar', 'roll': '21EC012', 'department': 'ECE'},
    ];

    inStudentDetails = [
      {'name': 'Ravi', 'roll': '21ME004', 'department': 'MECH'},
      {'name': 'Suresh', 'roll': '21CS010', 'department': 'CSE'},
    ];

    setState(() => isLoading = false);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStrength = totalStudents - outStudents;

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
                  /// HEADER
                  Row(
                    children: [
                      _glassIcon(
                        Icons.arrow_back,
                        () => context.pop(),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Admin Dashboard",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Manage hostel activities",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _glassIcon(
                        Icons.settings_outlined,
                        () => context.go('/settings'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _statsSection(currentStrength),
                                const SizedBox(height: 24),
                                _quickActions(),
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

  /// ================= UI COMPONENTS =================

  Widget _glassIcon(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: _glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glassBorder),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70),
        onPressed: onTap,
      ),
    );
  }

  Widget _statsSection(int currentStrength) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glassBorder),
      ),
      child: Column(
        children: [
          const Text(
            "Hostel Statistics",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statBox("Total Students", totalStudents, Icons.group_outlined,
                  [_primaryBlue, _darkBlue]),
              _statBox("Out Students", outStudents, Icons.exit_to_app_outlined,
                  [_primaryRed, _darkRed]),
              _statBox("Current Strength", currentStrength,
                  Icons.home_outlined, [_primaryGreen, _darkGreen]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(
      String label, int value, IconData icon, List<Color> colors) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _menuItem("Add Student", Icons.person_add_outlined,
              () => context.push('/add-student')),
          _menuItem("Student List", Icons.list_alt_outlined,
              () => context.go('/student-list')),
          _menuItem("Gate Pass Requests", Icons.assignment_outlined,
              () => context.push('/requested-gate-pass')),
        ],
      ),
    );
  }

  Widget _menuItem(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glassBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
      ),
    );
  }
}

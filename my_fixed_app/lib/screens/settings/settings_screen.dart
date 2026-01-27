import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
// Remove the problematic import for now

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _emailNotifications = true;

  // 🎯 Color Palettes - Dynamic based on theme
  Color get _primaryColor => _isDarkMode ? const Color(0xFFDC2626) : const Color(0xFF0AD5FF);
  Color get _secondaryColor => _isDarkMode ? const Color(0xFF991B1B) : const Color(0xFF0099CC);
  Color get _glassColor => _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
  Color get _glassBorder => _isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1);
  Color get _textPrimary => _isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  Color get _textSecondary => _isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6);
  Color get _textTertiary => _isDarkMode ? Colors.white.withOpacity(0.54) : Colors.black.withOpacity(0.4);
  Color get _dividerColor => _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
  
  // 🎯 Background Gradients
  List<Color> get _backgroundGradient => _isDarkMode 
      ? const [Color(0xFF1A1A1A), Color(0xFF2D1B1B), Color(0xFF1A1A1A)]
      : const [Color(0xFFF8F9FA), Color(0xFFE3F2FD), Color(0xFFF8F9FA)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _glassColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: _textSecondary),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Settings Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Appearance Section
                        _buildSectionHeader('Appearance'),
                        _buildGlassCard(
                          children: [
                            _buildSettingSwitch(
                              icon: Icons.dark_mode_outlined,
                              title: 'Dark Mode',
                              value: _isDarkMode,
                              onChanged: (value) {
                                setState(() {
                                  _isDarkMode = value;
                                });
                              },
                            ),
                            _buildDivider(),
                            _buildSettingOption(
                              icon: Icons.color_lens_outlined,
                              title: 'Theme Color',
                              subtitle: _isDarkMode ? 'Red Theme' : 'Blue Theme',
                              onTap: () {
                                // Theme color selection
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Notifications Section
                        _buildSectionHeader('Notifications'),
                        _buildGlassCard(
                          children: [
                            _buildSettingSwitch(
                              icon: Icons.notifications_outlined,
                              title: 'Push Notifications',
                              value: _notificationsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                });
                              },
                            ),
                            _buildDivider(),
                            _buildSettingSwitch(
                              icon: Icons.email_outlined,
                              title: 'Email Notifications',
                              value: _emailNotifications,
                              onChanged: (value) {
                                setState(() {
                                  _emailNotifications = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Security Section
                        _buildSectionHeader('Security'),
                        _buildGlassCard(
                          children: [
                            _buildSettingSwitch(
                              icon: Icons.fingerprint_outlined,
                              title: 'Biometric Login',
                              value: _biometricEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _biometricEnabled = value;
                                });
                              },
                            ),
                            _buildDivider(),
                            _buildSettingOption(
                              icon: Icons.lock_outlined,
                              title: 'Change Password',
                              onTap: () {
                                // Change password
                              },
                            ),
                            _buildDivider(),
                            _buildSettingOption(
                              icon: Icons.security_outlined,
                              title: 'Privacy & Security',
                              onTap: () {
                                // Privacy settings
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // About Section
                        _buildSectionHeader('About'),
                        _buildGlassCard(
                          children: [
                            _buildSettingOption(
                              icon: Icons.info_outlined,
                              title: 'App Information',
                              onTap: () {
                                _showAppInfoDialog();
                              },
                            ),
                            _buildDivider(),
                            _buildSettingOption(
                              icon: Icons.school_outlined,
                              title: 'App Tutorial',
                              onTap: () {
                                // Tutorial
                              },
                            ),
                            _buildDivider(),
                            _buildSettingOption(
                              icon: Icons.shield_outlined,
                              title: 'Privacy Policy',
                              onTap: () {
                                // Privacy policy
                              },
                            ),
                            _buildDivider(),
                            _buildSettingOption(
                              icon: Icons.description_outlined,
                              title: 'Terms of Service',
                              onTap: () {
                                // Terms of service
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Support Section
                        _buildSectionHeader('Support'),
                        _buildGlassCard(
                          children: [
                            _buildSettingOption(
                              icon: Icons.help_outlined,
                              title: 'Help & Support',
                              onTap: () {
                                // Help & support
                              },
                            ),
                            _buildDivider(),
                            _buildSettingOption(
                              icon: Icons.bug_report_outlined,
                              title: 'Report a Bug',
                              onTap: () {
                                // Bug report
                              },
                            ),
                            _buildDivider(),
                            _buildSettingOption(
                              icon: Icons.star_outlined,
                              title: 'Rate the App',
                              onTap: () {
                                // Rate app
                              },
                            ),
                            _buildDivider(),
                            _buildSettingOption(
                              icon: Icons.feedback_outlined,
                              title: 'Send Feedback',
                              onTap: () {
                                // Feedback
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Logout Button
                        _buildLogoutButton(),
                        const SizedBox(height: 16),
                        
                        // App Version
                        Text(
                          'Version 1.0.0 • SXCCE Gate Pass',
                          style: TextStyle(
                            color: _textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _glassColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: _textTertiary,
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: _textSecondary,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSettingSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
      ),
      trailing: _buildCustomSwitch(value, onChanged),
    );
  }

  Widget _buildCustomSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value 
              ? LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    _textTertiary.withOpacity(0.3),
                    _textTertiary.withOpacity(0.1)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: value ? _primaryColor.withOpacity(0.4) : Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : Colors.white.withOpacity(0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(value ? 0.3 : 0.2),
                  blurRadius: value ? 8 : 6,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: value ? _primaryColor.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: value 
                    ? [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.85),
                      ],
              ),
            ),
            child: value
                ? Icon(
                    Icons.check,
                    color: _primaryColor,
                    size: 12,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: _dividerColor,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          _showLogoutDialog();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outlined,
                    color: _primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow('App Name', 'SXCCE Gate Pass'),
              _buildInfoRow('Version', '1.0.0'),
              _buildInfoRow('Build Number', '1'),
              _buildInfoRow('Developer', 'SXCCE Institution'),
              _buildInfoRow('Flutter Version', '3.19.0'),
              _buildInfoRow('Last Updated', 'December 2024'),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout_rounded,
                color: _primaryColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout from your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _glassColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _glassBorder),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performLogout();
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
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
  }

  void _performLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        context.go('/signin');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
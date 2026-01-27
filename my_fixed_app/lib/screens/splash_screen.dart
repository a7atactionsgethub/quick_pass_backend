import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'view_history_page.dart';
import '../themes/app_theme.dart'; // Add this import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    AppTheme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    // Clean up listener
    AppTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    // Rebuild when AppTheme changes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations.backgroundDecoration(), // ✅ Use AppTheme background
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Theme Test Button (Temporary - remove after testing)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Text(
                    'Theme Test - Current: ${AppTheme.isDarkMode ? "DARK" : "LIGHT"}',
                    style: TextStyle(
                      color: AppTheme.textPrimary, // ✅ Use AppTheme color
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          print('🎯 Forcing DARK mode');
                          AppTheme.isDarkMode = true;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        child: const Text('Force Dark', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          print('🎯 Forcing LIGHT mode');
                          AppTheme.isDarkMode = false;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        child: const Text('Force Light', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // App Bar with Three dots button
            Padding(
              padding: const EdgeInsets.only(top: 40, right: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: AppDecorations.glassContainer( // ✅ Use AppTheme glass
                    borderRadius: 30,
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.textSecondary, // ✅ Use AppTheme color
                    ),
                    onSelected: (String value) {
                      if (value == 'View History') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ViewHistoryScreen()),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'View History',
                        child: Text(
                          'View History',
                          style: TextStyle(
                            color: AppTheme.textPrimary, // ✅ Use AppTheme color
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                    color: AppTheme.isDarkMode ? const Color(0xFF2A1A1A) : Colors.white,
                  ),
                ),
              ),
            ),

            // Centered Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title Section with Premium Font Style
                  Column(
                    children: [
                      Text(
                        'ROCKBOYS',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppTheme.textPrimary, // ✅ Use AppTheme color
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          shadows: AppTheme.isDarkMode ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(2, 2),
                            ),
                          ] : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'HOSTEL MANAGEMENT',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppTheme.textSecondary, // ✅ Use AppTheme color
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Glass Login Button
                      Container(
                        width: 220,
                        height: 56,
                        decoration: AppDecorations.buttonDecoration( // ✅ Use AppTheme button
                          borderRadius: 30,
                        ),
                        child: ElevatedButton(
                          onPressed: () => context.go('/signin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          ),
                          child: Text(
                            'GET STARTED',
                            style: AppTextStyles.buttonText.copyWith( // ✅ Use AppTheme text style
                              fontFamily: 'Poppins',
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Secure • Fast • Reliable',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppTheme.textTertiary, // ✅ Use AppTheme color
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Clean Bottom Section
            Container(
              margin: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  Text(
                    'Gate Pass Management System',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.textTertiary, // ✅ Use AppTheme color
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
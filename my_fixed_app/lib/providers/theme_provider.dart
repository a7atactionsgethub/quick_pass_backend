import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;
  
  set isDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners(); // This updates the whole app
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Colors that actually work with your UI
  Color get primaryColor => _isDarkMode ? const Color(0xFFDC2626) : const Color(0xFF0AD5FF);
  Color get secondaryColor => _isDarkMode ? const Color(0xFF991B1B) : const Color(0xFF0099CC);
  Color get glassColor => _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
  Color get glassBorder => _isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1);
  Color get textPrimary => _isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  Color get textSecondary => _isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6);
  Color get textTertiary => _isDarkMode ? Colors.white.withOpacity(0.54) : Colors.black.withOpacity(0.4);
  Color get dividerColor => _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
  
  // Background Gradients that match your MyGatePass
  List<Color> get backgroundGradient => _isDarkMode 
      ? const [Color(0xFF1A1A1A), Color(0xFF2D1B1B), Color(0xFF1A1A1A)]
      : const [Color(0xFFF8F9FA), Color(0xFFE3F2FD), Color(0xFFF8F9FA)];

  // Glass morphism decoration
  BoxDecoration get glassDecoration => BoxDecoration(
    color: glassColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: glassBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
      ),
    ],
  );
}
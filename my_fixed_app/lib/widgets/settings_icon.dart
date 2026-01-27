import 'package:flutter/material.dart';

class SettingsIcon extends StatelessWidget {
  final VoidCallback onPressed;
  
  const SettingsIcon({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.settings_outlined,
          color: Colors.white.withOpacity(0.7),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
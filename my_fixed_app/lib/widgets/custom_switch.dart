import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textTertiary;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
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
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    textTertiary.withOpacity(0.3),
                    textTertiary.withOpacity(0.1)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            // Outer shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
            // Inner shadow for track depth
            BoxShadow(
              color: value ? primaryColor.withOpacity(0.4) : Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: -2,
            ),
            // Track border/edge depth
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
                // Thumb outer shadow
                BoxShadow(
                  color: Colors.black.withOpacity(value ? 0.3 : 0.2),
                  blurRadius: value ? 8 : 6,
                  offset: const Offset(0, 2),
                ),
                // Thumb inner shadow for depth
                BoxShadow(
                  color: value ? primaryColor.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                  spreadRadius: -1,
                ),
                // Thumb highlight
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
                    color: primaryColor,
                    size: 12,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class ChordsmithMainButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ChordsmithMainButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonHeight = 64.0;
    final Color buttonColor = Theme.of(context).colorScheme.primary.withAlpha(12);
    final Color iconColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: Material(
        color: buttonColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../generated/l10n.dart';

class ChordsmithAppBar extends StatelessWidget {
  final void Function()? onSettingsPressed;
  const ChordsmithAppBar({super.key, this.onSettingsPressed});

  static const double buttonSize = 48.0;
  static const double horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey.shade300 : Colors.black87;
    final textColor = isDark ? Colors.grey.shade300 : Colors.black87;

    return SafeArea(
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: IconButton(
                icon: Icon(Icons.account_circle, size: 32, color: iconColor),
                onPressed: () {
                  // TODO: Implement login/account logic
                },
                tooltip: S.of(context).account,
                padding: EdgeInsets.zero,
              ),
            ),
            const Spacer(),
            Text(
              'Chordsmith',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: textColor,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: IconButton(
                icon: Icon(Icons.settings, size: 28, color: iconColor),
                onPressed: onSettingsPressed,
                tooltip: S.of(context).settings,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

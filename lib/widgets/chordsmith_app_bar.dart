import 'package:flutter/material.dart';

class ChordsmithAppBar extends StatelessWidget {
  final void Function()? onSettingsPressed;

  const ChordsmithAppBar({super.key, this.onSettingsPressed});

  static const double buttonSize = 48.0;

  static const double horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.account_circle, size: 32),
                onPressed: () {
                  // TODO: Implement login/account logic
                },
                tooltip: 'Account',
                padding: EdgeInsets.zero,
              ),
            ),
            const Spacer(),
            const Text(
              'Chordsmith',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: IconButton(
                icon: const Icon(Icons.settings, size: 28),
                onPressed: onSettingsPressed,
                tooltip: 'Settings',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

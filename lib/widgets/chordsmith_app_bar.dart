import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import '../storage/admin_storage.dart';
import '../storage/user_storage.dart';
import '../screens/login_popup.dart';

class ChordsmithAppBar extends StatelessWidget {
  final void Function()? onSettingsPressed;

  const ChordsmithAppBar({super.key, this.onSettingsPressed});

  static const double buttonSize = 48.0;

  static const double horizontalPadding = 16.0;

  void _handleAccountPressed(BuildContext context) async {
    final userStorage = UserStorage();
    await userStorage.init();
    final adminStorage = AdminStorage();
    await adminStorage.init();

    showDialog(
      context: context,
      builder: (_) => LoginPopup(
        authorizeAdmin: adminStorage.authorizeAdmin,
        onLoginSuccess: (username) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome, $username')),
          );
        },
        createAccount: (username, password, adminPassword) =>
            userStorage.createAccount(username, password, adminPassword, adminStorage.authorizeAdmin),
        loginUser: (username, password) => userStorage.login(username, password),
      ),
    );
  }

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
                onPressed: () => _handleAccountPressed(context),
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

import 'package:flutter/material.dart';

import '../generated/l10n.dart';
import '../storage/admin_storage.dart';
import '../storage/user_storage.dart';
import '../screens/login_popup.dart';
import '../screens/account_screen.dart';

class ChordsmithAppBar extends StatelessWidget {
  final void Function()? onSettingsPressed;
  final void Function(String username)? onLoginSuccess;
  final VoidCallback? onLogout;
  final String? loggedUsername;
  final bool isLoggedIn;

  const ChordsmithAppBar({
    super.key,
    this.onSettingsPressed,
    this.onLoginSuccess,
    this.onLogout,
    this.loggedUsername,
    this.isLoggedIn = false,
  });

  Future<void> _handleAccountPressed(BuildContext context) async {
    if (isLoggedIn && loggedUsername != null) {
      // If logged in, show account screen
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AccountScreen(
          username: loggedUsername!,
          onLogout: onLogout,
        ),
      ));
      return;
    }

    // Not logged in: show login popup
    final userStorage = UserStorage();
    await userStorage.init();
    final adminStorage = AdminStorage();
    await adminStorage.init();

    // Use local context saved here to avoid BuildContext across async gaps
    final localContext = context;

    showDialog(
      context: localContext,
      builder: (_) => LoginPopup(
        // Correct named parameter
        authorizeAdmin: adminStorage.authorizeAdmin,
        onLoginSuccess: (username) {
          Navigator.of(localContext).pop();
          if (onLoginSuccess != null) {
            onLoginSuccess!(username);
          }
          ScaffoldMessenger.of(localContext).showSnackBar(
            SnackBar(content: Text('${S.of(localContext).account}: $username')),
          );
        },
        createAccount: (username, password, adminPass) =>
            userStorage.createAccount(username, password, adminPass, adminStorage.authorizeAdmin),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
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
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  loggedUsername ?? '',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                ),
              ),
            SizedBox(
              width: 48,
              height: 48,
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

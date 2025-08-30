import 'package:flutter/material.dart';

import '../storage/user_storage.dart';
import '../storage/admin_storage.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _usernameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isLoggedIn = false;
  String? _currentUsername;

  bool _isLoading = false;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _oldPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Please fill username and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userStorage = UserStorage();
    await userStorage.init();

    final loggedIn = await userStorage.login(username, password);

    setState(() {
      _isLoading = false;
      _isLoggedIn = loggedIn;
      if (loggedIn) _currentUsername = username;
    });

    if (!loggedIn) {
      _showMessage('Invalid username or password');
    } else {
      _showMessage('Logged in successfully');
    }
  }

  Future<void> _changePassword() async {
    if (!_isLoggedIn) {
      _showMessage('Login required to change password');
      return;
    }

    final oldPwd = _oldPasswordController.text;
    final newPwd = _newPasswordController.text;
    final confirmNewPwd = _confirmNewPasswordController.text;

    if (newPwd.isEmpty) {
      _showMessage('New password is required');
      return;
    }
    if (newPwd != confirmNewPwd) {
      _showMessage('New passwords do not match');
      return;
    }

    // Validate old password again before changing
    setState(() {
      _isLoading = true;
    });

    final userStorage = UserStorage();
    await userStorage.init();

    final oldPwdValid = await userStorage.login(_currentUsername!, oldPwd);
    if (!oldPwdValid) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Old password is incorrect');
      return;
    }

    // Implement updateUser method in UserStorage to update password hash and encrypted password
    final updated = await userStorage.updateUser('username', 'newPwd', adminPassword: 'adminPwd');



    setState(() {
      _isLoading = false;
    });

    if (updated) {
      _showMessage('Password changed successfully');
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
      _oldPasswordController.clear();
    } else {
      _showMessage('Failed to change password');
    }
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _currentUsername = null;
      _usernameController.clear();
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    });
    _showMessage('Logged out');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!_isLoggedIn) ...[
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _oldPasswordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ] else ...[
                Text('Logged in as $_currentUsername'),
                const SizedBox(height: 24),
                TextField(
                  controller: _oldPasswordController,
                  decoration: const InputDecoration(labelText: 'Current Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmNewPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm New Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _changePassword,
                  child: const Text('Change Password'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

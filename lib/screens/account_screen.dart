import 'package:flutter/material.dart';

import '../storage/user_storage.dart';
import '../storage/admin_storage.dart';

class AccountScreen extends StatefulWidget {
  final String username;
  final VoidCallback? onLogout;

  const AccountScreen({Key? key, required this.username, this.onLogout})
      : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoggedIn = false;
  String? _currentUsername;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _currentUsername = widget.username;
    _isLoggedIn = true;
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _oldPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Please fill username and password');
      return;
    }

    setState(() => _isLoading = true);

    final userStorage = UserStorage();
    await userStorage.init();
    final success = await userStorage.login(username, password);

    setState(() {
      _isLoading = false;
      _isLoggedIn = success;
      if(success) _currentUsername = username;
    });

    if (!success) {
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
    final confirmPwd = _confirmPasswordController.text;

    if (newPwd.isEmpty) {
      _showMessage('New password is required');
      return;
    }

    if (newPwd != confirmPwd) {
      _showMessage('New passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final userStorage = UserStorage();
    await userStorage.init();

    final validOldPwd = await userStorage.login(_currentUsername!, oldPwd);

    if (!validOldPwd) {
      setState(() => _isLoading = false);
      _showMessage('Old password is incorrect');
      return;
    }

    final updated = await userStorage.updateUser(
      _currentUsername!,
      newPwd,
      // You must provide the current admin password to encrypt password.
      // For demonstration: assuming admin password 'admin', should be asked securely
      adminPassword: 'admin',
    );

    setState(() => _isLoading = false);

    if (updated) {
      _showMessage('Password changed successfully');
      _newPasswordController.clear();
      _confirmPasswordController.clear();
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
      _confirmPasswordController.clear();
    });

    if (widget.onLogout != null) widget.onLogout!();

    _showMessage('Logged out');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loggedUser = _currentUsername ?? widget.username;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
                Text('Logged in as $loggedUser'),
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
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _changePassword,
                  child: const Text('Change Password'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../storage/user_storage.dart';
import '../storage/admin_storage.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  @override
  State createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<bool> _isUsernameAvailable(String username) async {
    final userStorage = UserStorage();
    await userStorage.init();
    final users = await userStorage.getAllUsers();
    return !users.any((u) => u['username'] == username);
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPwd = _confirmPasswordController.text;
    final adminPwd = _adminPasswordController.text;

    if (username.isEmpty || password.isEmpty || adminPwd.isEmpty) {
      _showMessage('Please fill all required fields');
      return;
    }
    if (password != confirmPwd) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final adminStorage = AdminStorage();
    await adminStorage.init();

    final isAdminValid = await adminStorage.authorizeAdmin(adminPwd);

    if (!isAdminValid) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Invalid admin password');
      return;
    }

    final userStorage = UserStorage();
    await userStorage.init();

    bool usernameAvailable = true;
    if (!usernameAvailable) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Username already exists');
      return;
    }

    final success = await userStorage.createAccount(username, password, adminPwd, adminStorage.authorizeAdmin);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showMessage('Account created successfully');
      Navigator.pop(context);
    } else {
      _showMessage('Account creation failed');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _adminPasswordController,
                  decoration: const InputDecoration(labelText: 'Admin Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _createAccount,
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

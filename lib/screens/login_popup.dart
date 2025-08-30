import 'package:flutter/material.dart';

typedef Future<bool> AuthorizeAdminCallback(String pwd);
typedef Future<bool> LoginUserCallback(String username, String password);
typedef Future<bool> CreateAccountCallback(String username, String password, String adminPassword);

class LoginPopup extends StatefulWidget {
  final AuthorizeAdminCallback authorizeAdmin;
  final LoginUserCallback loginUser;
  final CreateAccountCallback createAccount;
  final void Function(String username)? onLoginSuccess;

  const LoginPopup({
    Key? key,
    required this.authorizeAdmin,
    required this.loginUser,
    required this.createAccount,
    this.onLoginSuccess,
  }) : super(key: key);

  @override
  _LoginPopupState createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup> {
  bool _isCreateMode = false;
  bool _loading = false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
    });
    final success =
    await widget.loginUser(_usernameController.text.trim(), _passwordController.text.trim());
    setState(() {
      _loading = false;
    });

    if (success) {
      widget.onLoginSuccess?.call(_usernameController.text.trim());
      Navigator.of(context).pop();
    } else {
      _showMessage('Invalid username or password');
    }
  }

  Future<void> _handleCreateAccount() async {
    setState(() {
      _loading = true;
    });
    final success = await widget.createAccount(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      _adminPasswordController.text.trim(),
    );
    setState(() {
      _loading = false;
    });

    if (success) {
      _showMessage('Account created successfully. Please login.');
      setState(() {
        _isCreateMode = false;
        _usernameController.clear();
        _passwordController.clear();
        _adminPasswordController.clear();
      });
    } else {
      _showMessage('Account creation failed: check admin password or username already exists');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isCreateMode ? 'Create Account' : 'Login'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_isCreateMode) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _adminPasswordController,
                decoration: const InputDecoration(labelText: 'Admin Password'),
                obscureText: true,
              ),
            ],
            if (_loading) const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_isCreateMode) {
              setState(() {
                _isCreateMode = false;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Text(_isCreateMode ? 'Back to Login' : 'Cancel'),
        ),
        TextButton(
          onPressed: _isCreateMode ? _handleCreateAccount : _handleLogin,
          child: Text(_isCreateMode ? 'Create' : 'Login'),
        ),
        if (!_isCreateMode)
          TextButton(
            onPressed: () {
              setState(() {
                _isCreateMode = true;
              });
            },
            child: const Text('Create Account'),
          ),
      ],
    );
  }
}

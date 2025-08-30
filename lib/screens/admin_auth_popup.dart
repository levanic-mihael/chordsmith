import 'package:flutter/material.dart';

import '../storage/admin_storage.dart';

class AdminAuthPopup extends StatefulWidget {
  final Function(bool authorized) onAdminVerified;

  const AdminAuthPopup({Key? key, required this.onAdminVerified}) : super(key: key);

  @override
  State createState() => _AdminAuthPopupState();
}

class _AdminAuthPopupState extends State<AdminAuthPopup> {
  final _adminPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _verifyAdmin() async {
    final adminPwd = _adminPasswordController.text;
    if (adminPwd.isEmpty) {
      setState(() {
        _errorText = 'Admin password is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final adminStorage = AdminStorage();
    await adminStorage.init();

    final authorized = await adminStorage.authorizeAdmin(adminPwd);

    setState(() {
      _isLoading = false;
      if (!authorized) {
        _errorText = 'Invalid admin password';
      }
    });

    if (authorized) {
      widget.onAdminVerified(true);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Admin Authentication'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _adminPasswordController,
            decoration: InputDecoration(
              labelText: 'Admin Password',
              errorText: _errorText,
            ),
            obscureText: true,
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.only(top: 12),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyAdmin,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

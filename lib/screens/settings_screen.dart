import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import '../settings/ini_settings_manager.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(Locale locale, bool darkMode) onSettingsChanged;

  const SettingsScreen({Key? key, required this.onSettingsChanged}) : super(key: key);

  @override
  State createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final IniSettingsManager _settingsManager = IniSettingsManager();

  Locale _selectedLocale = const Locale('en');
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsManager.loadSettings();
    setState(() {
      _selectedLocale = Locale(settings['language'] ?? 'en');
      _darkModeEnabled = settings['darkMode'] ?? false;
    });
  }

  Future<void> _saveSettings() async {
    await _settingsManager.saveSettings(
      languageCode: _selectedLocale.languageCode,
      darkMode: _darkModeEnabled,
    );
    widget.onSettingsChanged(_selectedLocale, _darkModeEnabled);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).settingsSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButton<Locale>(
              value: _selectedLocale,
              items: const [
                DropdownMenuItem(
                  child: Text('English'),
                  value: Locale('en'),
                ),
                DropdownMenuItem(
                  child: Text('Hrvatski'),
                  value: Locale('hr'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLocale = value);
                }
              },
            ),
            SwitchListTile(
              title: Text(strings.darkMode),
              value: _darkModeEnabled,
              onChanged: (val) {
                setState(() {
                  _darkModeEnabled = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              child: Text(strings.saveSettings),
            ),
          ],
        ),
      ),
    );
  }
}

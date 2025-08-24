import 'dart:io';

import 'package:ini/ini.dart';
import 'package:path_provider/path_provider.dart';

class IniSettingsManager {
  static const String _fileName = 'chordsmith_settings.ini';

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<Config> _loadIni() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        final config = Config();
        await file.writeAsString(config.toString());
        return config;
      }
      final content = await file.readAsString();
      return Config.fromString(content);
    } catch (_) {
      return Config();
    }
  }

  Future<void> saveSettings({required String languageCode, required bool darkMode}) async {
    final config = await _loadIni();

    if (!config.sections().contains('General')) {
      config.addSection('General');
    }

    config.set('General', 'language', languageCode);
    config.set('General', 'dark_mode', darkMode ? 'true' : 'false');

    final file = await _localFile;
    await file.writeAsString(config.toString());
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final config = await _loadIni();
    final language = config.get('General', 'language') ?? 'en';
    final darkModeStr = config.get('General', 'dark_mode') ?? 'false';
    final darkMode = darkModeStr.toLowerCase() == 'true';

    return {
      'language': language,
      'darkMode': darkMode,
    };
  }
}

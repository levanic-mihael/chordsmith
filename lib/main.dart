import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/chordsmith_home.dart';

import 'database/chord_database.dart';

import 'settings/ini_settings_manager.dart';

import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
  }

  await ChordDatabase.instance.database;

  final settingsManager = IniSettingsManager();
  final settings = await settingsManager.loadSettings();

  runApp(ChordsmithApp(
    locale: Locale(settings['language']),
    darkModeEnabled: settings['darkMode'],
  ));
}

class ChordsmithApp extends StatefulWidget {
  final Locale locale;
  final bool darkModeEnabled;
  const ChordsmithApp({super.key, required this.locale, required this.darkModeEnabled});

  @override
  State createState() => _ChordsmithAppState();
}

class _ChordsmithAppState extends State<ChordsmithApp> {
  late Locale _locale;
  late bool _darkModeEnabled;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
    _darkModeEnabled = widget.darkModeEnabled;
  }

  void updateSettings(Locale locale, bool darkMode) {
    setState(() {
      _locale = locale;
      _darkModeEnabled = darkMode;
    });
  }

  final ThemeData _customDarkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: Colors.blue.shade700,
    iconTheme: IconThemeData(color: Colors.grey.shade300),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1F1F1F),
      foregroundColor: Colors.grey.shade300,
      iconTheme: IconThemeData(color: Colors.grey.shade300),
      titleTextStyle: TextStyle(color: Colors.grey.shade300, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.grey.shade300),
      bodyMedium: TextStyle(color: Colors.grey.shade300),
      titleLarge: TextStyle(color: Colors.grey.shade300),
      labelLarge: TextStyle(color: Colors.grey.shade300),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.grey.shade300,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue.shade700,
      onPrimary: Colors.grey.shade300,
      secondary: Colors.red.shade700,
      onSecondary: Colors.grey.shade300,
      surface: const Color(0xFF1F1F1F),
      onSurface: Colors.grey.shade300,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chordsmith',
      theme: ThemeData.light(),
      darkTheme: _customDarkTheme,
      themeMode: _darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      locale: _locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: ChordsmithHome(onSettingsChanged: updateSettings),
      debugShowCheckedModeBanner: false,
    );
  }
}

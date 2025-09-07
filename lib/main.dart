import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/chordsmith_home.dart';
import 'screens/settings_screen.dart';
import 'screens/account_screen.dart';
import 'database/chord_database.dart';
import 'widgets/chordsmith_app_bar.dart';
import 'settings/ini_settings_manager.dart';
import 'storage/admin_storage.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final futures = [
    ChordDatabase.instance.database,
    IniSettingsManager().loadSettings(),
    AdminStorage().init(),
  ];
  final results = await Future.wait(futures);
  final settings = results[1] as Map<String, dynamic>;

  runApp(ChordsmithApp(
    locale: Locale(settings['language']),
    darkModeEnabled: settings['darkMode'],
  ));
}

class ChordsmithApp extends StatefulWidget {
  final Locale locale;
  final bool darkModeEnabled;

  const ChordsmithApp({
    super.key,
    required this.locale,
    required this.darkModeEnabled,
  });

  @override
  State<ChordsmithApp> createState() => _ChordsmithAppState();
}

class _ChordsmithAppState extends State<ChordsmithApp> {
  late Locale _locale;
  late bool _darkModeEnabled;

  bool _isLoggedIn = false;
  String? _loggedUsername;

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

  void handleLoginSuccess(String username, BuildContext context) {
    setState(() {
      _isLoggedIn = true;
      _loggedUsername = username;
    });
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AccountScreen(
        username: username,
        onLogout: handleLogout,
      ),
    ));
  }

  void handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _loggedUsername = null;
    });
  }

  final ThemeData _customDarkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: Colors.blue.shade700,
    iconTheme: const IconThemeData(color: Color(0xFFD6D6D6)),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1F1F1F),
      foregroundColor: Colors.grey.shade300,
      iconTheme: const IconThemeData(color: Color(0xFFD6D6D6)),
      titleTextStyle: const TextStyle(
        color: Color(0xFFD6D6D6),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
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
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Builder(
            builder: (context) => ChordsmithAppBar(
              onSettingsPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingsScreen(
                  onSettingsChanged: updateSettings,
                )));
              },
              onLoginSuccess: (username) => handleLoginSuccess(username, context),
              onLogout: handleLogout,
              loggedUsername: _loggedUsername,
              isLoggedIn: _isLoggedIn,
            ),
          ),
        ),
        body: ChordsmithHome(
          onSettingsChanged: updateSettings,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

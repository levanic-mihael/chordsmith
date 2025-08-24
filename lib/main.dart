import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/chordsmith_home.dart';
import 'database/chord_database.dart';
import 'settings/ini_settings_manager.dart';
import 'generated/l10n.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chordsmith',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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

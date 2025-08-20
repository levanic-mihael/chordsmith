import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/chordsmith_home.dart';
import 'database/chord_database.dart';

void main() async {
  // Initialize sqflite ffi for desktop or non-mobile environments
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database before running the app
  await ChordDatabase.instance.database;

  runApp(const ChordsmithApp());
}

class ChordsmithApp extends StatelessWidget {
  const ChordsmithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chordsmith',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ChordsmithHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

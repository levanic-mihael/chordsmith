import 'package:flutter/material.dart';
import 'screens/chordsmith_home.dart';

void main() {
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
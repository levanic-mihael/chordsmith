import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChordDatabase {
  static final ChordDatabase instance = ChordDatabase._init();

  static Database? _database;

  ChordDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chordsmith.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Tonality (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Mode (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE ChordType (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Chord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tonality_id INTEGER NOT NULL,
        mode_id INTEGER NOT NULL,
        type_id INTEGER NOT NULL,
        tabs_frets TEXT NOT NULL,
        custom INTEGER DEFAULT 0,
        display_name TEXT,
        FOREIGN KEY (tonality_id) REFERENCES Tonality(id),
        FOREIGN KEY (mode_id) REFERENCES Mode(id),
        FOREIGN KEY (type_id) REFERENCES ChordType(id)
      );
    ''');

    await _insertInitialData(db);
  }

  Future _insertInitialData(Database db) async {
    // TONALITIES: A-G
    const tonalities = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    for (int i = 0; i < tonalities.length; i++) {
      await db.insert('Tonality', {'id': i + 1, 'name': tonalities[i]});
    }

    // MODES: major, minor
    const modes = ['major', 'minor'];
    for (int i = 0; i < modes.length; i++) {
      await db.insert('Mode', {'id': i + 1, 'name': modes[i]});
    }

    // CHORD TYPES: only 'triad' for now
    await db.insert('ChordType', {'id': 1, 'name': 'triad'});

    // Standard Major and Minor Chords with tabs (EADGBE format, spaces for muted strings)
    final chordTabs = {
      'A-major': 'X 0 2 2 2 0',
      'B-major': 'X 2 4 4 4 2',
      'C-major': 'X 3 2 0 1 0',
      'D-major': 'X X 0 2 3 2',
      'E-major': '0 2 2 1 0 0',
      'F-major': '1 3 3 2 1 1',
      'G-major': '3 2 0 0 0 3',
      'A-minor': 'X 0 2 2 1 0',
      'B-minor': 'X 2 4 4 3 2',
      'C-minor': 'X 3 5 5 4 3',
      'D-minor': 'X X 0 2 3 1',
      'E-minor': '0 2 2 0 0 0',
      'F-minor': '1 3 3 1 1 1',
      'G-minor': '3 5 5 3 3 3',
    };

    final tonalityMap = {'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7};
    final modeMap = {'major': 1, 'minor': 2};

    int chordId = 1;
    for (var entry in chordTabs.entries) {
      final parts = entry.key.split('-');
      final tonality = parts[0];
      final mode = parts[1];
      await db.insert('Chord', {
        'id': chordId++,
        'tonality_id': tonalityMap[tonality]!,
        'mode_id': modeMap[mode]!,
        'type_id': 1, // triad
        'tabs_frets': entry.value,
        'custom': 0,
        'display_name': '${tonality.toUpperCase()} ${mode.toUpperCase()}${mode.substring(1)}',
      });
    }
  }

// Additional CRUD methods can be implemented here, e.g., to fetch chords by filters.
}

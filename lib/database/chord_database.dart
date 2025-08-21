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
      version: 2, // bump version!!
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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

    // New tables:
    await db.execute('''
      CREATE TABLE AlternativeChord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        base_chord_id INTEGER NOT NULL, -- reference standard chord id
        tabs_frets TEXT NOT NULL,
        FOREIGN KEY (base_chord_id) REFERENCES Chord(id)
      );
    ''');
    await db.execute('''
      CREATE TABLE CustomChord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        tabs_frets TEXT NOT NULL
      );
    ''');

    await _insertInitialData(db);
  }

  // For migrating old DB
  FutureOr<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // v2: add AlternativeChord, CustomChord
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE AlternativeChord (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          base_chord_id INTEGER NOT NULL,
          tabs_frets TEXT NOT NULL,
          FOREIGN KEY (base_chord_id) REFERENCES Chord(id)
        );
      ''');
      await db.execute('''
        CREATE TABLE CustomChord (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          tabs_frets TEXT NOT NULL
        );
      ''');
    }
  }

  Future _insertInitialData(Database db) async {
    // All your logic for Tonalities, Modes, ChordTypes, Chords...
    // [Code from your existing _insertInitialData here]
  }

  // --- CHORD/ALT/CUSTOM PUBLIC API ---

  // For search
  Future<Map<String, dynamic>?> getStandardChord(int tonalityId, int modeId, int typeId) async {
    final db = await instance.database;
    final rows = await db.query(
      'Chord',
      where: 'tonality_id = ? AND mode_id = ? AND type_id = ?',
      whereArgs: [tonalityId, modeId, typeId],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  // For alternative search: get alternatives for a standard chord (by id)
  Future<List<Map<String, dynamic>>> getAlternativeChords(int baseChordId) async {
    final db = await instance.database;
    return await db.query(
      'AlternativeChord',
      where: 'base_chord_id = ?',
      whereArgs: [baseChordId],
    );
  }

  // For custom search (list + retrieve by id)
  Future<List<Map<String, dynamic>>> getAllCustomChords() async {
    final db = await instance.database;
    return await db.query('CustomChord');
  }

  Future<Map<String, dynamic>?> getCustomChordById(int id) async {
    final db = await instance.database;
    final rows = await db.query('CustomChord', where: 'id=?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  // --- CREATE ---

  Future<int> insertAlternativeChord(int baseChordId, String tabs) async {
    final db = await instance.database;
    return await db.insert('AlternativeChord', {'base_chord_id': baseChordId, 'tabs_frets': tabs});
  }

  Future<int> insertCustomChord(String name, String tabs) async {
    final db = await instance.database;
    return await db.insert('CustomChord', {'name': name, 'tabs_frets': tabs});
  }
}

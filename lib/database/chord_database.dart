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
      version: 4, // incremented version for migration
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
      favorite INTEGER DEFAULT 0,
      FOREIGN KEY (tonality_id) REFERENCES Tonality(id),
      FOREIGN KEY (mode_id) REFERENCES Mode(id),
      FOREIGN KEY (type_id) REFERENCES ChordType(id)
    );
    ''');

    await db.execute('''
    CREATE TABLE AlternativeChord (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      base_chord_id INTEGER NOT NULL,
      tabs_frets TEXT NOT NULL,
      favorite INTEGER DEFAULT 0,
      FOREIGN KEY (base_chord_id) REFERENCES Chord(id)
    );
    ''');

    await db.execute('''
    CREATE TABLE CustomChord (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      tabs_frets TEXT NOT NULL,
      favorite INTEGER DEFAULT 0
    );
    ''');

    await _insertInitialData(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE AlternativeChord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        base_chord_id INTEGER NOT NULL,
        tabs_frets TEXT NOT NULL,
        favorite INTEGER DEFAULT 0,
        FOREIGN KEY (base_chord_id) REFERENCES Chord(id)
      );
      ''');

      await db.execute('''
      CREATE TABLE CustomChord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        tabs_frets TEXT NOT NULL,
        favorite INTEGER DEFAULT 0
      );
      ''');
    }

    if (oldVersion < 4) {
      // Add favorite columns if they don't exist
      await db.execute('ALTER TABLE Chord ADD COLUMN favorite INTEGER DEFAULT 0;');
      await db.execute('ALTER TABLE AlternativeChord ADD COLUMN favorite INTEGER DEFAULT 0;');
      await db.execute('ALTER TABLE CustomChord ADD COLUMN favorite INTEGER DEFAULT 0;');
    }
  }

  Future _insertInitialData(Database db) async {
    // Tonalities including sharps and flats
    final List<String> tonalities = [
      'C', 'C#', 'Db', 'D', 'D#', 'Eb',
      'E', 'F', 'F#', 'Gb', 'G', 'G#',
      'Ab', 'A', 'A#', 'Bb', 'B'
    ];
    for (int i = 0; i < tonalities.length; i++) {
      await db.insert('Tonality', {'id': i + 1, 'name': tonalities[i]});
    }

    // Modes
    final List<String> modes = [
      'major', 'minor', 'dominant', 'augmented', 'diminished', 'suspended'
    ];
    for (int i = 0; i < modes.length; i++) {
      await db.insert('Mode', {'id': i + 1, 'name': modes[i]});
    }

    // Chord Types
    final List<String> chordTypes = [
      'triad', '2', '4', '5', '6', '7'
    ];
    for (int i = 0; i < chordTypes.length; i++) {
      await db.insert('ChordType', {'id': i + 1, 'name': chordTypes[i]});
    }

    final tonalityMap = {for (var t in tonalities) t: tonalities.indexOf(t) + 1};
    final modeMap = {for (var m in modes) m: modes.indexOf(m) + 1};
    final chordTypeMap = {for (var c in chordTypes) c: chordTypes.indexOf(c) + 1};

    final List<Map<String, String>> chordsData = [
      {'tone': 'C', 'mode': 'major', 'type': 'triad', 'tabs': 'X 3 2 0 1 0', 'name': 'C Major'},
      {'tone': 'C', 'mode': 'minor', 'type': 'triad', 'tabs': 'X 3 5 5 4 3', 'name': 'C Minor'},
      {'tone': 'C', 'mode': 'dominant', 'type': '7', 'tabs': 'X 3 2 3 1 0', 'name': 'C7'},
      {'tone': 'C', 'mode': 'augmented', 'type': 'triad', 'tabs': 'X 3 2 1 1 0', 'name': 'C Augmented'},
      {'tone': 'C', 'mode': 'diminished', 'type': 'triad', 'tabs': 'X 3 4 5 4 X', 'name': 'C Diminished'},
      {'tone': 'C', 'mode': 'suspended', 'type': '4', 'tabs': 'X 3 3 0 1 1', 'name': 'C Suspended'},
      {'tone': 'C', 'mode': 'major', 'type': '2', 'tabs': 'X 3 0 0 1 0', 'name': 'C2'},

      {'tone': 'G', 'mode': 'major', 'type': 'triad', 'tabs': '3 2 0 0 0 3', 'name': 'G Major'},
      {'tone': 'G', 'mode': 'minor', 'type': 'triad', 'tabs': '3 5 5 3 3 3', 'name': 'G Minor'},
      {'tone': 'G', 'mode': 'dominant', 'type': '7', 'tabs': '3 2 0 0 0 1', 'name': 'G7'},
      {'tone': 'G', 'mode': 'augmented', 'type': 'triad', 'tabs': '3 2 1 0 0 0', 'name': 'G Augmented'},
      {'tone': 'G', 'mode': 'diminished', 'type': 'triad', 'tabs': '3 2 1 0 1 X', 'name': 'G Diminished'},
      {'tone': 'G', 'mode': 'suspended', 'type': '4', 'tabs': '3 3 0 0 1 1', 'name': 'G Suspended'},
      {'tone': 'G', 'mode': 'major', 'type': '5', 'tabs': '3 5 5 0 0 3', 'name': 'G5'},

      {'tone': 'C#', 'mode': 'major', 'type': 'triad', 'tabs': 'X 4 3 1 2 1', 'name': 'C# Major'},
      {'tone': 'C#', 'mode': 'minor', 'type': 'triad', 'tabs': 'X 4 6 6 5 4', 'name': 'C# Minor'},

      {'tone': 'Db', 'mode': 'major', 'type': 'triad', 'tabs': 'X 4 3 1 2 1', 'name': 'Db Major'},
      {'tone': 'Db', 'mode': 'minor', 'type': 'triad', 'tabs': 'X 4 6 6 5 4', 'name': 'Db Minor'},

      {'tone': 'D', 'mode': 'major', 'type': 'triad', 'tabs': 'X X 0 2 3 2', 'name': 'D Major'},
      {'tone': 'D', 'mode': 'minor', 'type': 'triad', 'tabs': 'X X 0 2 3 1', 'name': 'D Minor'},

      {'tone': 'D#', 'mode': 'major', 'type': 'triad', 'tabs': 'X X 1 3 4 3', 'name': 'D# Major'},
      {'tone': 'D#', 'mode': 'minor', 'type': 'triad', 'tabs': 'X X 1 3 4 2', 'name': 'D# Minor'},

      {'tone': 'Eb', 'mode': 'major', 'type': 'triad', 'tabs': 'X X 1 3 4 3', 'name': 'Eb Major'},
      {'tone': 'Eb', 'mode': 'minor', 'type': 'triad', 'tabs': 'X X 1 3 4 2', 'name': 'Eb Minor'},

      {'tone': 'E', 'mode': 'major', 'type': 'triad', 'tabs': '0 2 2 1 0 0', 'name': 'E Major'},
      {'tone': 'E', 'mode': 'minor', 'type': 'triad', 'tabs': '0 2 2 0 0 0', 'name': 'E Minor'},

      {'tone': 'F', 'mode': 'major', 'type': 'triad', 'tabs': '1 3 3 2 1 1', 'name': 'F Major'},
      {'tone': 'F', 'mode': 'minor', 'type': 'triad', 'tabs': '1 3 3 1 1 1', 'name': 'F Minor'},

      {'tone': 'F#', 'mode': 'major', 'type': 'triad', 'tabs': '2 4 4 3 2 2', 'name': 'F# Major'},
      {'tone': 'F#', 'mode': 'minor', 'type': 'triad', 'tabs': '2 4 4 2 2 2', 'name': 'F# Minor'},

      {'tone': 'Gb', 'mode': 'major', 'type': 'triad', 'tabs': '2 4 4 3 2 2', 'name': 'Gb Major'},
      {'tone': 'Gb', 'mode': 'minor', 'type': 'triad', 'tabs': '2 4 4 2 2 2', 'name': 'Gb Minor'},

      {'tone': 'G#', 'mode': 'major', 'type': 'triad', 'tabs': '4 6 6 5 4 4', 'name': 'G# Major'},
      {'tone': 'G#', 'mode': 'minor', 'type': 'triad', 'tabs': '4 6 6 4 4 4', 'name': 'G# Minor'},

      {'tone': 'Ab', 'mode': 'major', 'type': 'triad', 'tabs': '4 6 6 5 4 4', 'name': 'Ab Major'},
      {'tone': 'Ab', 'mode': 'minor', 'type': 'triad', 'tabs': '4 6 6 4 4 4', 'name': 'Ab Minor'},

      {'tone': 'A', 'mode': 'major', 'type': 'triad', 'tabs': 'X 0 2 2 2 0', 'name': 'A Major'},
      {'tone': 'A', 'mode': 'minor', 'type': 'triad', 'tabs': 'X 0 2 2 1 0', 'name': 'A Minor'},

      {'tone': 'A#', 'mode': 'major', 'type': 'triad', 'tabs': 'X 1 3 3 3 1', 'name': 'A# Major'},
      {'tone': 'A#', 'mode': 'minor', 'type': 'triad', 'tabs': 'X 1 3 3 2 1', 'name': 'A# Minor'},

      {'tone': 'Bb', 'mode': 'major', 'type': 'triad', 'tabs': 'X 1 3 3 3 1', 'name': 'Bb Major'},
      {'tone': 'Bb', 'mode': 'minor', 'type': 'triad', 'tabs': 'X 1 3 3 2 1', 'name': 'Bb Minor'},

      {'tone': 'B', 'mode': 'major', 'type': 'triad', 'tabs': 'X 2 4 4 4 2', 'name': 'B Major'},
      {'tone': 'B', 'mode': 'minor', 'type': 'triad', 'tabs': 'X 2 4 4 3 2', 'name': 'B Minor'},
    ];

    int chordId = 1;
    for (final chord in chordsData) {
      await db.insert('Chord', {
        'id': chordId++,
        'tonality_id': tonalityMap[chord['tone']!]!,
        'mode_id': modeMap[chord['mode']!]!,
        'type_id': chordTypeMap[chord['type']!]!,
        'tabs_frets': chord['tabs']!,
        'custom': 0,
        'display_name': chord['name']!,
      });
    }
  }

  Future<Map<String, dynamic>?> getStandardChord(int tonalityId, int modeId, int typeId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Chord',
      where: 'tonality_id = ? AND mode_id = ? AND type_id = ?',
      whereArgs: [tonalityId, modeId, typeId],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getAlternativeChords(int baseChordId) async {
    final db = await database;
    return await db.query('AlternativeChord', where: 'base_chord_id = ?', whereArgs: [baseChordId]);
  }

  Future<List<Map<String, dynamic>>> getAllCustomChords() async {
    final db = await database;
    return await db.query('CustomChord', orderBy: 'name COLLATE NOCASE ASC');
  }

  Future<Map<String, dynamic>?> getCustomChordById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('CustomChord', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> insertAlternativeChord(int baseChordId, String tabs) async {
    final db = await database;
    return await db.insert('AlternativeChord', {'base_chord_id': baseChordId, 'tabs_frets': tabs});
  }

  Future<int> insertCustomChord(String name, String tabs) async {
    final db = await database;
    return await db.insert('CustomChord', {'name': name, 'tabs_frets': tabs});
  }

  // New methods for favorites update

  Future<int> updateStandardChordFavorite(int chordId, int favorite) async {
    final db = await database;
    return await db.update('Chord', {'favorite': favorite}, where: 'id = ?', whereArgs: [chordId]);
  }

  Future<int> updateAlternativeChordFavorite(int chordId, int favorite) async {
    final db = await database;
    return await db.update('AlternativeChord', {'favorite': favorite}, where: 'id = ?', whereArgs: [chordId]);
  }

  Future<int> updateCustomChordFavorite(int chordId, int favorite) async {
    final db = await database;
    return await db.update('CustomChord', {'favorite': favorite}, where: 'id = ?', whereArgs: [chordId]);
  }

  // New methods for deleting chords

  Future<int> deleteAlternativeChord(int id) async {
    final db = await database;
    return await db.delete('AlternativeChord', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomChord(int id) async {
    final db = await database;
    return await db.delete('CustomChord', where: 'id = ?', whereArgs: [id]);
  }

  // Also add update methods to update tabs_frets on alternative and custom chords for editing

  Future<int> updateAlternativeChordTabs(int id, String tabs) async {
    final db = await database;
    return await db.update('AlternativeChord', {'tabs_frets': tabs}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCustomChordTabs(int id, String tabs) async {
    final db = await database;
    return await db.update('CustomChord', {'tabs_frets': tabs}, where: 'id = ?', whereArgs: [id]);
  }
}

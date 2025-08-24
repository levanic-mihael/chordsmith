import 'package:flutter/material.dart';
import '../database/chord_database.dart';
import '../widgets/guitar_fretboard.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favoriteStandardChords = [];
  List<Map<String, dynamic>> favoriteAlternativeChords = [];
  List<Map<String, dynamic>> favoriteCustomChords = [];

  Map<String, dynamic>? selectedChord;
  String? displayTabs;
  String selectedCategory = '';

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteChords();
  }

  Future<void> _loadFavoriteChords() async {
    setState(() => loading = true);
    final db = await ChordDatabase.instance.database;

    final stdChords = await db.query(
      'Chord',
      where: 'favorite = 1',
      orderBy: 'display_name COLLATE NOCASE ASC',
    );

    final altChords = await db.rawQuery('''
      SELECT alt.id, alt.base_chord_id, alt.tabs_frets, alt.favorite, c.display_name
      FROM AlternativeChord alt
      JOIN Chord c ON alt.base_chord_id = c.id
      WHERE alt.favorite = 1
      ORDER BY c.display_name COLLATE NOCASE ASC
    ''');

    final custChords = await db.query(
      'CustomChord',
      where: 'favorite = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    setState(() {
      favoriteStandardChords = stdChords;
      favoriteAlternativeChords = altChords;
      favoriteCustomChords = custChords;
      loading = false;
      selectedChord = null;
      displayTabs = null;
      selectedCategory = '';
    });
  }

  Future<void> _toggleFavoriteStandard(int chordId, bool current) async {
    await ChordDatabase.instance.updateStandardChordFavorite(chordId, current ? 0 : 1);
    await _loadFavoriteChords();
  }

  Future<void> _toggleFavoriteAlternative(int chordId, bool current) async {
    await ChordDatabase.instance.updateAlternativeChordFavorite(chordId, current ? 0 : 1);
    await _loadFavoriteChords();
  }

  Future<void> _toggleFavoriteCustom(int chordId, bool current) async {
    await ChordDatabase.instance.updateCustomChordFavorite(chordId, current ? 0 : 1);
    await _loadFavoriteChords();
  }

  void _selectChord(String category, Map<String, dynamic> chord) {
    setState(() {
      selectedCategory = category;
      selectedChord = chord;
      displayTabs = chord['tabs_frets'] as String?;
    });
  }

  void _goBackToList() {
    setState(() {
      selectedChord = null;
      displayTabs = null;
      selectedCategory = '';
    });
  }

  List<List<int>> _parseTabsToNeckMarks(String tabs) {
    const int noMark = -1;
    const int openMark = 0;
    const int muteMark = -2;

    List<String> parts = tabs.split(' ');
    if (parts.length != 6) return List.generate(6, (_) => List.filled(7, noMark));

    List<List<int>> neckMarks = List.generate(6, (_) => List.filled(7, noMark));
    for (int stringIdx = 0; stringIdx < 6; stringIdx++) {
      final tabVal = parts[5 - stringIdx];
      if (tabVal == 'X')
        neckMarks[stringIdx][0] = muteMark;
      else if (tabVal == '0')
        neckMarks[stringIdx][0] = openMark;
      else {
        final fretNum = int.tryParse(tabVal);
        if (fretNum != null && fretNum < 7) {
          neckMarks[stringIdx][fretNum] = fretNum;
        }
      }
    }
    return neckMarks;
  }

  Widget _buildChordTile({
    required String name,
    required bool favorite,
    required VoidCallback onToggleFavorite,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(name),
      trailing: IconButton(
        icon: Icon(favorite ? Icons.star : Icons.star_border, color: favorite ? Colors.amber : null),
        onPressed: onToggleFavorite,
        tooltip: favorite ? 'Unmark Favorite' : 'Mark as Favorite',
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (selectedChord != null && displayTabs != null) {
      // Display only fretboard and back button
      return Scaffold(
        appBar: AppBar(
          title: Text(selectedCategory == 'custom'
              ? selectedChord!['name'] ?? 'Custom Chord'
              : selectedChord!['display_name'] ?? 'Chord'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackToList,
          ),
        ),
        body: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: GuitarFretboard(
              neckMarks: _parseTabsToNeckMarks(displayTabs!),
              fretCount: 7,
              fretboardOffset: 0,
            ),
          ),
        ),
      );
    }

    // Otherwise show the list
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favoriteStandardChords.isNotEmpty) ...[
              const Text('Standard Chords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              ...favoriteStandardChords.map((chord) {
                final favorite = (chord['favorite'] ?? 0) == 1;
                return _buildChordTile(
                  name: chord['display_name'] ?? 'Unknown',
                  favorite: favorite,
                  onToggleFavorite: () => _toggleFavoriteStandard(chord['id'], favorite),
                  onTap: () => _selectChord('standard', chord),
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
            if (favoriteAlternativeChords.isNotEmpty) ...[
              const Text('Alternative Chords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              ...favoriteAlternativeChords.map((chord) {
                final favorite = (chord['favorite'] ?? 0) == 1;
                return _buildChordTile(
                  name: chord['display_name'] ?? 'Unknown',
                  favorite: favorite,
                  onToggleFavorite: () => _toggleFavoriteAlternative(chord['id'], favorite),
                  onTap: () => _selectChord('alternative', chord),
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
            if (favoriteCustomChords.isNotEmpty) ...[
              const Text('Custom Chords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              ...favoriteCustomChords.map((chord) {
                final favorite = (chord['favorite'] ?? 0) == 1;
                return _buildChordTile(
                  name: chord['name'] ?? 'Unknown',
                  favorite: favorite,
                  onToggleFavorite: () => _toggleFavoriteCustom(chord['id'], favorite),
                  onTap: () => _selectChord('custom', chord),
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
            if (favoriteStandardChords.isEmpty &&
                favoriteAlternativeChords.isEmpty &&
                favoriteCustomChords.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No favorites yet.', style: TextStyle(fontSize: 20)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

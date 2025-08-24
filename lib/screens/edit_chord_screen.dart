import 'package:flutter/material.dart';
import '../database/chord_database.dart';
import '../widgets/guitar_fretboard_editor.dart';

class EditChordScreen extends StatefulWidget {
  const EditChordScreen({Key? key}) : super(key: key);

  @override
  State<EditChordScreen> createState() => _EditChordScreenState();
}

class _EditChordScreenState extends State<EditChordScreen> {
  List<Map<String, dynamic>> alternativeChords = [];
  List<Map<String, dynamic>> customChords = [];
  List<Map<String, dynamic>> standardChords = [];

  Map<String, dynamic>? editingChord;
  bool isAlternativeEditing = false;
  List<String>? fretboardTabs;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadChords();
  }

  Future<void> _loadChords() async {
    setState(() {
      loading = true;
    });
    final db = await ChordDatabase.instance.database;

    final altChords = await db.rawQuery('''
      SELECT alt.id, alt.base_chord_id, alt.tabs_frets, alt.favorite, c.display_name
      FROM AlternativeChord alt
      JOIN Chord c ON alt.base_chord_id = c.id
      ORDER BY c.display_name COLLATE NOCASE ASC
    ''');

    final custChords = await db.query('CustomChord', orderBy: 'name COLLATE NOCASE ASC');

    final stdChords = await db.query('Chord', orderBy: 'display_name COLLATE NOCASE ASC');

    setState(() {
      alternativeChords = altChords;
      customChords = custChords;
      standardChords = stdChords;
      loading = false;
      editingChord = null;
      fretboardTabs = null;
      isAlternativeEditing = false;
    });
  }

  Future<void> _toggleFavoriteStandardChord(int chordId, bool current) async {
    await ChordDatabase.instance.updateStandardChordFavorite(chordId, current ? 0 : 1);
    await _loadChords();
  }

  Future<void> _toggleFavoriteAlternativeChord(int chordId, bool current) async {
    await ChordDatabase.instance.updateAlternativeChordFavorite(chordId, current ? 0 : 1);
    await _loadChords();
  }

  Future<void> _toggleFavoriteCustomChord(int chordId, bool current) async {
    await ChordDatabase.instance.updateCustomChordFavorite(chordId, current ? 0 : 1);
    await _loadChords();
  }

  Future<void> _deleteAlternativeChord(int chordId) async {
    await ChordDatabase.instance.deleteAlternativeChord(chordId);
    await _loadChords();
  }

  Future<void> _deleteCustomChord(int chordId) async {
    await ChordDatabase.instance.deleteCustomChord(chordId);
    await _loadChords();
  }

  Future<void> _startEditingAlternativeChord(Map<String, dynamic> chord) {
    setState(() {
      editingChord = chord;
      fretboardTabs = chord['tabs_frets'].toString().split(' ');
      isAlternativeEditing = true;
    });
    return Future.value();
  }

  Future<void> _startEditingCustomChord(Map<String, dynamic> chord) {
    setState(() {
      editingChord = chord;
      fretboardTabs = chord['tabs_frets'].toString().split(' ');
      isAlternativeEditing = false;
    });
    return Future.value();
  }

  Future<bool?> _showConfirmDeleteDialog(BuildContext context, String chordName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chord'),
        content: Text('Are you sure you want to delete "$chordName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEditedChord() async {
    if (editingChord == null) return;
    if (fretboardTabs == null || fretboardTabs!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set chord fingers on fretboard')),
      );
      return;
    }

    final tabsString = fretboardTabs!.join(' ');
    if (isAlternativeEditing) {
      await ChordDatabase.instance.updateAlternativeChordTabs(editingChord!['id'], tabsString);
    } else {
      await ChordDatabase.instance.updateCustomChordTabs(editingChord!['id'], tabsString);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chord saved.')),
    );
    await _loadChords();
  }

  List<List<int>> _tabsStringToNeckMarks(String tabsString, int fretCount) {
    const int noMark = -1;
    const int openMark = 0;
    const int muteMark = -2;

    List<String> tabs = tabsString.split(' ');
    List<List<int>> neckMarks = List.generate(6, (_) => List.filled(fretCount, noMark));
    for (int stringIdx = 0; stringIdx < 6; stringIdx++) {
      if (stringIdx >= tabs.length) continue;
      String val = tabs[5 - stringIdx];
      if (val == 'X') {
        neckMarks[stringIdx][0] = muteMark;
      } else if (val == '0') {
        neckMarks[stringIdx][0] = openMark;
      } else {
        int? fret = int.tryParse(val);
        if (fret != null && fret < fretCount) {
          neckMarks[stringIdx][fret] = fret;
        }
      }
    }
    return neckMarks;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (editingChord != null) {
      final fretCount = 7;
      final neckMarks = _tabsStringToNeckMarks(editingChord!['tabs_frets'] as String, fretCount);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            isAlternativeEditing
                ? (editingChord!['display_name'] ?? 'Edit Alternative Chord')
                : (editingChord!['name'] ?? 'Edit Custom Chord'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                editingChord = null;
                fretboardTabs = null;
              });
            },
          ),
        ),
        body: SafeArea(
          child: SizedBox.expand(
            child: Column(
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: GuitarFretboardEditor(
                      fretCount: fretCount,
                      initialOffset: 0,
                      initialNeckMarks: neckMarks,
                      onChanged: (tabs) {
                        setState(() {
                          fretboardTabs = tabs;
                        });
                      },
                      key: ValueKey(neckMarks.map((e) => e.join(',')).join(';')),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: _saveEditedChord,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Save Chord', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            editingChord = null;
                            fretboardTabs = null;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Chords'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Standard Chords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ...standardChords.map((chord) {
              final favorite = (chord['favorite'] ?? 0) == 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(chord['display_name'] ?? 'Unknown', style: const TextStyle(fontSize: 18))),
                  IconButton(
                    icon: Icon(favorite ? Icons.star : Icons.star_border, color: favorite ? Colors.amber : null),
                    onPressed: () => _toggleFavoriteStandardChord(chord['id'], favorite),
                    tooltip: favorite ? 'Unmark Favorite' : 'Mark as Favorite',
                  ),
                  const SizedBox(width: 48),
                  const SizedBox(width: 48),
                ],
              );
            }).toList(),
            const SizedBox(height: 24),
            const Text('Alternative Chords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ...alternativeChords.map((chord) {
              final favorite = (chord['favorite'] ?? 0) == 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(chord['display_name'] ?? 'Unknown', style: const TextStyle(fontSize: 18))),
                  IconButton(
                    icon: Icon(favorite ? Icons.star : Icons.star_border, color: favorite ? Colors.amber : null),
                    onPressed: () => _toggleFavoriteAlternativeChord(chord['id'], favorite),
                    tooltip: favorite ? 'Unmark Favorite' : 'Mark as Favorite',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _startEditingAlternativeChord(chord),
                    tooltip: 'Edit Chord',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await _showConfirmDeleteDialog(context, chord['display_name'] ?? 'this chord');
                      if (confirm == true) {
                        await _deleteAlternativeChord(chord['id']);
                      }
                    },
                    tooltip: 'Delete Chord',
                  ),
                ],
              );
            }).toList(),
            const SizedBox(height: 24),
            const Text('Custom Chords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ...customChords.map((chord) {
              final favorite = (chord['favorite'] ?? 0) == 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(chord['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18))),
                  IconButton(
                    icon: Icon(favorite ? Icons.star : Icons.star_border, color: favorite ? Colors.amber : null),
                    onPressed: () => _toggleFavoriteCustomChord(chord['id'], favorite),
                    tooltip: favorite ? 'Unmark Favorite' : 'Mark as Favorite',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _startEditingCustomChord(chord),
                    tooltip: 'Edit Chord',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await _showConfirmDeleteDialog(context, chord['name'] ?? 'this chord');
                      if (confirm == true) {
                        await _deleteCustomChord(chord['id']);
                      }
                    },
                    tooltip: 'Delete Chord',
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

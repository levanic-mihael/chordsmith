import 'package:flutter/material.dart';
import '../database/chord_database.dart';
import '../widgets/guitar_fretboard_editor.dart';
import '../generated/l10n.dart';

class EditChordScreen extends StatefulWidget {
  const EditChordScreen({super.key});

  @override
  State createState() => _EditChordScreenState();
}

class _EditChordScreenState extends State<EditChordScreen> {
  List<Map> alternativeChords = [];
  List<Map> customChords = [];
  List<Map> standardChords = [];
  Map? editingChord;
  bool isAlternativeEditing = false;
  List<String>? fretboardTabs;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadChords();
  }

  Future _loadChords() async {
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

  Future _toggleFavoriteStandardChord(int chordId, bool current) async {
    await ChordDatabase.instance.updateStandardChordFavorite(chordId, current ? 0 : 1);
    await _loadChords();
  }

  Future _toggleFavoriteAlternativeChord(int chordId, bool current) async {
    await ChordDatabase.instance.updateAlternativeChordFavorite(chordId, current ? 0 : 1);
    await _loadChords();
  }

  Future _toggleFavoriteCustomChord(int chordId, bool current) async {
    await ChordDatabase.instance.updateCustomChordFavorite(chordId, current ? 0 : 1);
    await _loadChords();
  }

  Future _deleteAlternativeChord(int chordId) async {
    await ChordDatabase.instance.deleteAlternativeChord(chordId);
    await _loadChords();
  }

  Future _deleteCustomChord(int chordId) async {
    await ChordDatabase.instance.deleteCustomChord(chordId);
    await _loadChords();
  }

  Future _startEditingAlternativeChord(Map chord) {
    setState(() {
      editingChord = chord;
      fretboardTabs = chord['tabs_frets'].toString().split(' ');
      isAlternativeEditing = true;
    });
    return Future.value();
  }

  Future _startEditingCustomChord(Map chord) {
    setState(() {
      editingChord = chord;
      fretboardTabs = chord['tabs_frets'].toString().split(' ');
      isAlternativeEditing = false;
    });
    return Future.value();
  }

  Future<bool?> _showConfirmDeleteDialog(BuildContext context, String chordName) {
    final strings = S.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteChord),
        content: Text(strings.confirmDeleteChord(chordName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.yes),
          ),
        ],
      ),
    );
  }

  Future _saveEditedChord() async {
    final strings = S.of(context);
    if (editingChord == null) return;
    if (fretboardTabs == null || fretboardTabs!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.pleaseSetChordFingers)),
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
      SnackBar(content: Text(strings.chordSaved)),
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
    final strings = S.of(context);

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
                ? (editingChord!['display_name'] ?? strings.editAlternativeChord)
                : (editingChord!['name'] ?? strings.editCustomChord),
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(strings.saveChord, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            editingChord = null;
                            fretboardTabs = null;
                          });
                        },
                        child: Text(strings.cancel),
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
      appBar: AppBar(title: Text(strings.editChords), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.standardChords, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ...standardChords.map((chord) {
              final favorite = (chord['favorite'] ?? 0) == 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(chord['display_name'] ?? strings.unknown, style: const TextStyle(fontSize: 18))),
                  IconButton(
                    icon: Icon(favorite ? Icons.star : Icons.star_border, color: favorite ? Colors.amber : null),
                    onPressed: () => _toggleFavoriteStandardChord(chord['id'], favorite),
                    tooltip: favorite ? strings.unmarkFavorite : strings.markFavorite,
                  ),
                  const SizedBox(width: 48),
                  const SizedBox(width: 48),
                ],
              );
            }).toList(),
            const SizedBox(height: 24),
            Text(strings.alternativeChords, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ...alternativeChords.map((chord) {
              final favorite = (chord['favorite'] ?? 0) == 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(chord['display_name'] ?? strings.unknown, style: const TextStyle(fontSize: 18))),
                  IconButton(
                    icon: Icon(favorite ? Icons.star : Icons.star_border, color: favorite ? Colors.amber : null),
                    onPressed: () => _toggleFavoriteAlternativeChord(chord['id'], favorite),
                    tooltip: favorite ? strings.unmarkFavorite : strings.markFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _startEditingAlternativeChord(chord),
                    tooltip: strings.editChord,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await _showConfirmDeleteDialog(context, chord['display_name'] ?? strings.thisChord);
                      if (confirm == true) {
                        await _deleteAlternativeChord(chord['id']);
                      }
                    },
                    tooltip: strings.deleteChord,
                  ),
                ],
              );
            }).toList(),
            const SizedBox(height: 24),
            Text(strings.customChords, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ...customChords.map((chord) {
              final favorite = (chord['favorite'] ?? 0) == 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(chord['name'] ?? strings.unknown, style: const TextStyle(fontSize: 18))),
                  IconButton(
                    icon: Icon(favorite ? Icons.star : Icons.star_border, color: favorite ? Colors.amber : null),
                    onPressed: () => _toggleFavoriteCustomChord(chord['id'], favorite),
                    tooltip: favorite ? strings.unmarkFavorite : strings.markFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _startEditingCustomChord(chord),
                    tooltip: strings.editChord,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await _showConfirmDeleteDialog(context, chord['name'] ?? strings.thisChord);
                      if (confirm == true) {
                        await _deleteCustomChord(chord['id']);
                      }
                    },
                    tooltip: strings.deleteChord,
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

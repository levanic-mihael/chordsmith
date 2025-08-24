import 'package:flutter/material.dart';

import '../database/chord_database.dart';
import '../models/chord_models.dart';
import '../widgets/guitar_fretboard.dart';

enum SearchMode { standard, custom }

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Tonality> tonalities = [];
  List<Mode> modes = [];
  List<ChordType> chordTypes = [];

  int? selectedTonalityId;
  int? selectedModeId;
  int? selectedChordTypeId;

  Set<int> enabledModeIds = {};
  Set<int> enabledChordTypeIds = {};

  SearchMode searchMode = SearchMode.standard;

  Map<String, dynamic>? standardChord;
  List<Map<String, dynamic>> alternatives = [];
  int selectedAlternativeIdx = 0;

  List<Map<String, dynamic>> customChords = [];
  Map<String, dynamic>? selectedCustomChord;

  String? displayTabs;
  String feedbackMessage = '';

  bool loading = true;
  static const int fretCount = 7;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future _loadMeta() async {
    final db = await ChordDatabase.instance.database;

    final tonalRes = await db.query('Tonality');
    final modeRes = await db.query('Mode');
    final chordTypeRes = await db.query('ChordType');

    setState(() {
      tonalities = tonalRes.map((e) => Tonality(id: e['id'] as int, name: e['name'] as String)).toList();
      modes = modeRes.map((e) => Mode(id: e['id'] as int, name: e['name'] as String)).toList();
      chordTypes = chordTypeRes.map((e) => ChordType(id: e['id'] as int, name: e['name'] as String)).toList();
      loading = false;
    });

    await _updateEnabledOptions();
  }

  Future _updateEnabledOptions() async {
    if (selectedTonalityId == null) {
      setState(() {
        enabledModeIds.clear();
        enabledChordTypeIds.clear();
      });
      return;
    }

    final db = await ChordDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT DISTINCT Mode.id AS mode_id, ChordType.id AS chord_type_id
      FROM Chord
      JOIN Mode ON Chord.mode_id = Mode.id
      JOIN ChordType ON Chord.type_id = ChordType.id
      WHERE Chord.tonality_id = ?
    ''', [selectedTonalityId]);

    final modeSet = <int>{};
    final chordSet = <int>{};

    for (final row in rows) {
      final m = row['mode_id'];
      final c = row['chord_type_id'];
      if (m is int) modeSet.add(m);
      if (c is int) chordSet.add(c);
    }

    setState(() {
      enabledModeIds = modeSet;
      enabledChordTypeIds = chordSet;

      if (selectedModeId != null && !enabledModeIds.contains(selectedModeId!)) {
        selectedModeId = null;
      }
      if (selectedChordTypeId != null && !enabledChordTypeIds.contains(selectedChordTypeId!)) {
        selectedChordTypeId = null;
      }
      standardChord = null;
      alternatives = [];
      selectedAlternativeIdx = 0;
      displayTabs = null;
      feedbackMessage = '';
    });
  }

  Future _loadStandardChordAndAlternatives() async {
    if (selectedTonalityId == null || selectedModeId == null || selectedChordTypeId == null) {
      return;
    }

    final base = await ChordDatabase.instance.getStandardChord(selectedTonalityId!, selectedModeId!, selectedChordTypeId!);

    List<Map<String, dynamic>> alts = [];
    String? tabs;

    if (base != null) {
      alts = await ChordDatabase.instance.getAlternativeChords(base['id'] as int);
      tabs = base['tabs_frets'] as String?;
    }

    setState(() {
      standardChord = base;
      alternatives = alts;
      selectedAlternativeIdx = 0;
      displayTabs = tabs;
      feedbackMessage = base == null ? 'No such chord found' : '';
    });

    await _loadFavoriteStatus();
  }

  Future _enterCustomMode() async {
    final list = await ChordDatabase.instance.getAllCustomChords();
    setState(() {
      searchMode = SearchMode.custom;
      customChords = list;
      selectedCustomChord = null;
      displayTabs = null;
      feedbackMessage = '';
      _isFavorite = false;
    });
  }

  Future _enterStandardMode() async {
    setState(() {
      searchMode = SearchMode.standard;
      selectedCustomChord = null;
      customChords = [];
      displayTabs = null;
      feedbackMessage = '';
      _isFavorite = false;
    });
    await _updateEnabledOptions();
  }

  void _selectTone(int id) {
    setState(() {
      selectedTonalityId = id;
      selectedModeId = null;
      selectedChordTypeId = null;
      standardChord = null;
      alternatives = [];
      selectedAlternativeIdx = 0;
      displayTabs = null;
      feedbackMessage = '';
      _isFavorite = false;
    });
    _updateEnabledOptions();
  }

  void _selectMode(int id) {
    if (searchMode == SearchMode.standard && !enabledModeIds.contains(id)) return;
    setState(() {
      selectedModeId = id;
      selectedChordTypeId = null;
      standardChord = null;
      alternatives = [];
      selectedAlternativeIdx = 0;
      displayTabs = null;
      feedbackMessage = '';
      _isFavorite = false;
    });
  }

  void _selectChordType(int id) {
    if (searchMode == SearchMode.standard && !enabledChordTypeIds.contains(id)) return;
    setState(() {
      selectedChordTypeId = id;
      standardChord = null;
      alternatives = [];
      selectedAlternativeIdx = 0;
      displayTabs = null;
      feedbackMessage = '';
      _isFavorite = false;
    });
  }

  void _selectAlternative(int idx) {
    setState(() {
      selectedAlternativeIdx = idx;
      if (idx == 0) {
        displayTabs = standardChord?['tabs_frets'] as String?;
      } else {
        displayTabs = alternatives[idx - 1]['tabs_frets'] as String?;
      }
    });
  }

  Future<void> _selectCustomChord(Map<String, dynamic> chord) async {
    setState(() {
      selectedCustomChord = chord;
      displayTabs = chord['tabs_frets'] as String;
      feedbackMessage = '';
    });
    await _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    if (searchMode == SearchMode.standard && standardChord != null) {
      setState(() {
        _isFavorite = (standardChord!['favorite'] ?? 0) == 1;
      });
    } else if (searchMode == SearchMode.custom && selectedCustomChord != null) {
      setState(() {
        _isFavorite = (selectedCustomChord!['favorite'] ?? 0) == 1;
      });
    } else {
      setState(() {
        _isFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (searchMode == SearchMode.standard && standardChord != null) {
      final current = (standardChord!['favorite'] ?? 0) == 1;
      await ChordDatabase.instance.updateStandardChordFavorite(standardChord!['id'], current ? 0 : 1);
      standardChord!['favorite'] = current ? 0 : 1;
    } else if (searchMode == SearchMode.custom && selectedCustomChord != null) {
      final current = (selectedCustomChord!['favorite'] ?? 0) == 1;
      await ChordDatabase.instance.updateCustomChordFavorite(selectedCustomChord!['id'], current ? 0 : 1);
      selectedCustomChord!['favorite'] = current ? 0 : 1;
    }
    await _loadFavoriteStatus();
  }

  List<List<int>> _parseTabsToNeckMarks(String tabs) {
    const int noMark = -1;
    const int openMark = 0;
    const int muteMark = -2;

    List<String> parts = tabs.split(' ');
    if (parts.length != 6) return List.generate(6, (_) => List.filled(fretCount, noMark));

    List<List<int>> neckMarks = List.generate(6, (_) => List.filled(fretCount, noMark));
    for (int stringIdx = 0; stringIdx < 6; stringIdx++) {
      final tabVal = parts[5 - stringIdx]; // reverse order for display
      if (tabVal == 'X')
        neckMarks[stringIdx][0] = muteMark;
      else if (tabVal == '0')
        neckMarks[stringIdx][0] = openMark;
      else {
        final fretNum = int.tryParse(tabVal);
        if (fretNum != null && fretNum < fretCount) {
          neckMarks[stringIdx][fretNum] = fretNum;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Chordsmith Search'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSearchModeToggle(),
            const SizedBox(height: 16),
            if (searchMode == SearchMode.standard) _buildStandardSelectors(),
            if (searchMode == SearchMode.custom) _buildCustomList(),
            if (feedbackMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(feedbackMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
              ),
            if (displayTabs != null) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_isFavorite ? Icons.star : Icons.star_border,
                        color: _isFavorite ? Colors.amber : Colors.grey, size: 32),
                    tooltip: _isFavorite ? 'Unmark Favorite' : 'Mark as Favorite',
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: GuitarFretboard(
                  neckMarks: _parseTabsToNeckMarks(displayTabs!),
                  fretCount: fretCount,
                  fretboardOffset: 0,
                ),
              ),
              if (searchMode == SearchMode.standard && alternatives.isNotEmpty) _buildAlternativeTabsToggle(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
            onPressed: () => _enterStandardMode(),
            style: ElevatedButton.styleFrom(
                backgroundColor: searchMode == SearchMode.standard ? Colors.blue : Colors.grey),
            child: const Text('Standard')),
        const SizedBox(width: 12),
        ElevatedButton(
            onPressed: () => _enterCustomMode(),
            style: ElevatedButton.styleFrom(
                backgroundColor: searchMode == SearchMode.custom ? Colors.blue : Colors.grey),
            child: const Text('Custom')),
      ],
    );
  }

  Widget _buildButtonsRow<T>({
    required List<T> items,
    required int? selectedId,
    required String Function(T) getLabel,
    required int Function(T) getId,
    required void Function(int) onTap,
    bool Function(int)? isEnabled,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        final id = getId(item);
        final enabled = isEnabled == null ? true : isEnabled(id);
        final selected = selectedId == id;
        return GestureDetector(
          onTap: enabled ? () => onTap(id) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? (selected ? Colors.blue.shade700 : Colors.white) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled ? (selected ? Colors.blue.shade700 : Colors.grey.shade400) : Colors.grey.shade400,
              ),
            ),
            child: Text(
              getLabel(item),
              style: TextStyle(
                color: enabled ? (selected ? Colors.white : Colors.black87) : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStandardSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Select Tone:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 10),
        _buildButtonsRow<Tonality>(
          items: tonalities,
          selectedId: selectedTonalityId,
          getLabel: (t) => t.name,
          getId: (t) => t.id,
          onTap: _selectTone,
        ),
        const SizedBox(height: 24),
        const Text('Select Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 10),
        _buildButtonsRow<Mode>(
          items: modes,
          selectedId: selectedModeId,
          getLabel: (m) => m.name,
          getId: (m) => m.id,
          onTap: _selectMode,
          isEnabled: (id) => enabledModeIds.contains(id),
        ),
        const SizedBox(height: 24),
        const Text('Select Chord Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 10),
        _buildButtonsRow<ChordType>(
          items: chordTypes,
          selectedId: selectedChordTypeId,
          getLabel: (c) => c.name,
          getId: (c) => c.id,
          onTap: _selectChordType,
          isEnabled: (id) => enabledChordTypeIds.contains(id),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: searchMode == SearchMode.standard ? _loadStandardChordAndAlternatives : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12),
            child: Text('Show Chord', style: TextStyle(fontSize: 20)),
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeTabsToggle() {
    if (searchMode != SearchMode.standard || standardChord == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: () => _selectAlternative(0),
              child: Text(
                'Standard',
                style: TextStyle(
                  fontWeight: selectedAlternativeIdx == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            ...List.generate(alternatives.length, (i) {
              final idx = i + 1;
              return TextButton(
                onPressed: () => _selectAlternative(idx),
                child: Text(
                  'Alt $idx',
                  style: TextStyle(
                    fontWeight: selectedAlternativeIdx == idx ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomList() {
    if (searchMode != SearchMode.custom) return const SizedBox.shrink();
    if (customChords.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 18),
        child: Center(
          child: Text('No custom chords yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Custom Chords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          ...customChords.map((row) {
            final selected = selectedCustomChord != null && selectedCustomChord!['id'] == row['id'];
            return ListTile(
              title: Text(row['name'] as String),
              selected: selected,
              onTap: () async {
                setState(() {
                  selectedCustomChord = row;
                  displayTabs = row['tabs_frets'] as String;
                  feedbackMessage = '';
                });
                await _loadFavoriteStatus();
              },
            );
          }),
        ],
      ),
    );
  }
}

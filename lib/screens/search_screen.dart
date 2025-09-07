import 'package:flutter/material.dart';
import '../database/chord_database.dart';
import '../models/chord_models.dart';
import '../widgets/guitar_fretboard.dart';
import '../generated/l10n.dart';

enum SearchMode { standard, custom }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Tonality> tonalities = [];
  List<Mode> modes = [];
  List<ChordType> chordTypes = [];

  int? selectedTonalityId;
  int? selectedModeId;
  int? selectedChordTypeId;

  Set<int> enabledModeIds = {};
  Set<int> enabledChordIds = {};

  SearchMode searchMode = SearchMode.standard;

  Map<String, Object?>? standardChord;
  List<Map<String, Object?>> alternatives = [];
  int selectedAlternativeIdx = 0;

  List<Map<String, Object?>> customChords = [];
  Map<String, Object?>? selectedCustomChord;

  String? displayTabs;
  String feedbackMessage = '';

  bool loading = true;
  bool _isFavorite = false;

  static const int fretCount = 7;

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
        enabledChordIds.clear();
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

    final Set<int> modeSet = {};
    final Set<int> chordSet = {};

    for (final row in rows) {
      final m = row['mode_id'];
      final c = row['chord_type_id'];
      if (m is int) modeSet.add(m);
      if (c is int) chordSet.add(c);
    }

    setState(() {
      enabledModeIds = modeSet;
      enabledChordIds = chordSet;

      if (selectedModeId != null && !enabledModeIds.contains(selectedModeId!)) {
        selectedModeId = null;
      }
      if (selectedChordTypeId != null && !enabledChordIds.contains(selectedChordTypeId!)) {
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

    final dbChord = await ChordDatabase.instance.getStandardChord(selectedTonalityId!, selectedModeId!, selectedChordTypeId!);
    List<Map<String, Object?>> alts = [];
    String? tabs;

    if (dbChord != null) {
      alts = await ChordDatabase.instance.getAlternativeChords(dbChord['id'] as int);
      tabs = dbChord['tabs_frets'] as String?;
    }

    setState(() {
      standardChord = dbChord;
      alternatives = alts;
      selectedAlternativeIdx = 0;
      displayTabs = tabs;
      feedbackMessage = dbChord == null ? S.of(context).noSuchChordFound : '';
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
    if (searchMode == SearchMode.standard && !enabledChordIds.contains(id)) return;

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

  Future _loadFavoriteStatus() async {
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

  Future _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      if (searchMode == SearchMode.standard && standardChord != null) {
        await ChordDatabase.instance.updateStandardChordFavorite(
          standardChord!['id'] as int,
          _isFavorite ? 1 : 0,
        );
      } else if (searchMode == SearchMode.custom && selectedCustomChord != null) {
        await ChordDatabase.instance.updateCustomChordFavorite(
          selectedCustomChord!['id'] as int,
          _isFavorite ? 1 : 0,
        );
      }
    } catch (e) {}
  }



  List<List<int>> _parseTabsToNeckMarks(String tabs) {
    const int noMark = -1;
    const int openMark = 0;
    const int muteMark = -2;
    List<String> parts = tabs.split(' ');
    if (parts.length != 6) return List.generate(fretCount, (_) => List.filled(fretCount, noMark));
    List<List<int>> neckMarks = List.generate(6, (_) => List.filled(fretCount, noMark));
    for (int stringIdx = 0; stringIdx < 6; stringIdx++) {
      final tabVal = parts[5 - stringIdx];
      if (tabVal == 'X') {
        neckMarks[stringIdx][0] = muteMark;
      } else if (tabVal == '0') {
        neckMarks[stringIdx][0] = openMark;
      } else {
        final fretNum = int.tryParse(tabVal);
        if (fretNum != null && fretNum < fretCount) {
          neckMarks[stringIdx][fretNum] = fretNum;
        }
      }
    }
    return neckMarks;
  }

  Widget _buildButtonsToggle(
      List items,
      int? selectedId,
      String Function(dynamic) getLabel,
      void Function(int) onTap, {
        Set? enabledIds,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        final id = (item as dynamic).id as int;
        final label = getLabel(item);
        final enabled = enabledIds == null || enabledIds.contains(id);
        final selected = selectedId == id;

        Color backgroundColor;
        Color borderColor;
        Color textColor;

        if (!enabled) {
          backgroundColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
          borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
          textColor = isDark ? Colors.grey.shade600 : Colors.grey.shade600;
        } else {
          if (selected) {
            backgroundColor = Colors.blue.shade700;
            borderColor = Colors.blue.shade700;
            textColor = Colors.white;
          } else {
            backgroundColor = isDark ? Colors.grey.shade900 : Colors.white;
            borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
            textColor = isDark ? Colors.grey.shade300 : Colors.black87;
          }
        }

        return GestureDetector(
          onTap: enabled ? () => onTap(id) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildSearchModeToggle() {
    final strings = S.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _enterStandardMode,
          style: ElevatedButton.styleFrom(
            backgroundColor: searchMode == SearchMode.standard ? Colors.blue : Colors.grey,
          ),
          child: Text(strings.standard),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _enterCustomMode,
          style: ElevatedButton.styleFrom(
            backgroundColor: searchMode == SearchMode.custom ? Colors.blue : Colors.grey,
          ),
          child: Text(strings.custom),
        ),
      ],
    );
  }

  Widget _buildStandardSelectors() {
    final strings = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(strings.selectTone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 10),
        _buildButtonsToggle(
          tonalities,
          selectedTonalityId,
              (item) => (item as Tonality).name,
          _selectTone,
        ),
        const SizedBox(height: 24),
        Text(strings.selectMode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 10),
        _buildButtonsToggle(modes, selectedModeId, (item) => (item as Mode).name, _selectMode, enabledIds: enabledModeIds),
        const SizedBox(height: 24),
        Text(strings.selectChordType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 10),
        _buildButtonsToggle(chordTypes, selectedChordTypeId, (item) => (item as ChordType).name, _selectChordType, enabledIds: enabledChordIds),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: (selectedTonalityId != null && selectedModeId != null && selectedChordTypeId != null) ? _loadStandardChordAndAlternatives : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
            child: Text(S.of(context).showChord, style: const TextStyle(fontSize: 20)),
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
                S.of(context).standard,
                style: TextStyle(fontWeight: selectedAlternativeIdx == 0 ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            ...List.generate(alternatives.length, (i) {
              final idx = i + 1;
              return TextButton(
                onPressed: () => _selectAlternative(idx),
                child: Text(
                  '${S.of(context).alt} $idx',
                  style: TextStyle(fontWeight: selectedAlternativeIdx == idx ? FontWeight.bold : FontWeight.normal),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomList() {
    final strings = S.of(context);

    if (searchMode != SearchMode.custom) return const SizedBox.shrink();

    if (customChords.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Center(child: Text(strings.noCustomChordsYet, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(strings.customChords, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          ...customChords.map((row) {
            final selected = selectedCustomChord != null && selectedCustomChord!['id'] == row['id'];
            return ListTile(
              title: Text(row['name'] as String),
              selected: selected,
              onTap: () {
                setState(() {
                  selectedCustomChord = row;
                  displayTabs = row['tabs_frets'] as String;
                  feedbackMessage = '';
                });
                _loadFavoriteStatus();
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.search), centerTitle: true),
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
                    icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: _isFavorite ? Colors.amber : Colors.grey, size: 32),
                    tooltip: _isFavorite ? strings.unmarkFavorite : strings.markFavorite,
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
              if (alternatives.isNotEmpty) _buildAlternativeTabsToggle(),
            ],
          ],
        ),
      ),
    );
  }
}

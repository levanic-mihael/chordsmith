import 'package:flutter/material.dart';
import '../database/chord_database.dart';
import '../models/chord_models.dart'; // Tonality, Mode, ChordType


// Toggle between standard (built-in + alternatives) vs custom chords
enum SearchMode { standard, custom }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Metadata
  List<Tonality> tonalities = [];
  List<Mode> modes = [];
  List<ChordType> chordTypes = [];

  // Selection states
  int? selectedTonalityId;
  int? selectedModeId;
  int? selectedChordTypeId;

  // Enabled (auto-filtered) for standard search
  Set<int> enabledModeIds = {};
  Set<int> enabledChordTypeIds = {};

  // Search mode
  SearchMode searchMode = SearchMode.standard;

  // Standard chord and alternatives
  Map<String, dynamic>? standardChord; // row from Chord table
  List<Map<String, dynamic>> alternatives = []; // rows from AlternativeChord
  int selectedAlternativeIdx = 0; // 0 = standard, 1.. = Alt N

  // Custom chords list & selection
  List<Map<String, dynamic>> customChords = [];
  Map<String, dynamic>? selectedCustomChord;

  // Current display tabs (the one shown in the graphic)
  String? displayTabs; // "EADGBE", e.g. "X 2 2 1 0 0"

  // UI state
  String feedbackMessage = '';
  bool loading = true;

  // Visual constants
  static const int fretCount = 7; // 0..6 columns
  static const double firstColWidth = 25;
  static const double otherColWidth = 50;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    // Load metadata lists
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
  }

  // When tone changes, recompute what modes/types exist for Standard mode
  Future<void> _updateEnabledOptions() async {
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

      // Reset current display when options change
      standardChord = null;
      alternatives = [];
      selectedAlternativeIdx = 0;
      displayTabs = null;
      feedbackMessage = '';
    });
  }

  // Load base standard chord + alternatives for current selection
  Future<void> _loadStandardChordAndAlternatives() async {
    if (selectedTonalityId == null || selectedModeId == null || selectedChordTypeId == null) return;

    final base = await ChordDatabase.instance.getStandardChord(
      selectedTonalityId!, selectedModeId!, selectedChordTypeId!,
    );

    List<Map<String, dynamic>> alts = [];
    String? tabs;

    if (base != null) {
      alts = await ChordDatabase.instance.getAlternativeChords(base['id'] as int);
      tabs = base['tabs_frets'] as String;
    }

    setState(() {
      standardChord = base;
      alternatives = alts;
      selectedAlternativeIdx = 0; // default to standard
      displayTabs = tabs;
      feedbackMessage = base == null ? 'No such chord found' : '';
    });
  }

  // Switch display to selected alternative index (0 = standard)
  void _selectAlternative(int idx) {
    setState(() {
      selectedAlternativeIdx = idx;
      if (idx == 0) {
        displayTabs = standardChord?['tabs_frets'] as String?;
      } else {
        final alt = alternatives[idx - 1];
        displayTabs = alt['tabs_frets'] as String;
      }
    });
  }

  // Standard "Show Chord" action: fetch base + alts, show base by default
  Future<void> _showStandardChord() async {
    if (selectedTonalityId == null || selectedModeId == null || selectedChordTypeId == null) {
      setState(() {
        feedbackMessage = 'Please select tone, mode, and chord type.';
        displayTabs = null;
      });
      return;
    }
    await _loadStandardChordAndAlternatives();
  }

  // Custom mode: load list, and allow picking one to display
  Future<void> _enterCustomMode() async {
    final list = await ChordDatabase.instance.getAllCustomChords();
    setState(() {
      searchMode = SearchMode.custom;
      customChords = list;
      selectedCustomChord = null;
      displayTabs = null;
      feedbackMessage = '';
    });
  }

  Future<void> _enterStandardMode() async {
    setState(() {
      searchMode = SearchMode.standard;
      selectedCustomChord = null;
      customChords = [];
      displayTabs = null;
      feedbackMessage = '';
    });
    // Keep current selections; re-evaluate enabled options if tone was selected
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
    });
  }

  // ---------- UI BUILDERS ----------

  Widget _buildSearchModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _enterStandardMode(),
          style: ElevatedButton.styleFrom(
            backgroundColor: searchMode == SearchMode.standard ? Colors.blue : Colors.grey,
          ),
          child: const Text('Standard'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _enterCustomMode(),
          style: ElevatedButton.styleFrom(
            backgroundColor: searchMode == SearchMode.custom ? Colors.blue : Colors.grey,
          ),
          child: const Text('Custom'),
        ),
      ],
    );
  }

  Widget _buildButtonsRow<T>({
    required List<T> items,
    required int? selectedId,
    required String Function(T) getLabel,
    required int Function(T) getId,
    required void Function(int) onTap,
    bool Function(int id)? isEnabled,
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
                color: enabled
                    ? (selected ? Colors.blue.shade700 : Colors.grey.shade400)
                    : Colors.grey.shade400,
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
          isEnabled: searchMode == SearchMode.standard ? (id) => enabledModeIds.contains(id) : null,
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
          isEnabled: searchMode == SearchMode.standard ? (id) => enabledChordTypeIds.contains(id) : null,
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: searchMode == SearchMode.standard ? _showStandardChord : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12),
            child: Text('Show Chord', style: TextStyle(fontSize: 20)),
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeTabsToggle() {
    if (searchMode != SearchMode.standard || standardChord == null) return const SizedBox.shrink();

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 18),
        const Text('Custom Chords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 8),
        if (customChords.isEmpty)
          const Text('No custom chords yet.')
        else
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
              },
            );
          }),
      ],
    );
  }

  // 6 (rows x strings) x 7 (cols x frets) display
  Widget _buildGuitarNeck() {
    if (displayTabs == null) return const SizedBox.shrink();

    // Convert to highE..lowE for UI top..bottom
    final parts = displayTabs!.split(' '); // lowE..highE coming from DB standard format
    if (parts.length != 6) return const SizedBox.shrink();

    // Invert to high E (top) -> low E (bottom)
    final byStringTopToBottom = List<String>.generate(6, (i) => parts[5 - i]);

    final circleColor = Colors.blue.shade700;
    final textStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14);

    final stringNames = ['E', 'A', 'D', 'G', 'B', 'E'];
    const double firstColWidth = 25;
    const double otherColWidth = 50;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), // Match surrounding frame margin
      child: Center(
        child: AspectRatio(
          // 7 columns wide vs 6 rows tall; adjust vertical ratio for less height
          aspectRatio: 7 / (6 * 0.35),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: string names vertically aligned
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (row) {
                    return Container(
                      height: 28, // reduce height for compactness
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        stringNames[row],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                ),

                // Fretboard grid expanding horizontally
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (row) {
                      final fretVal = byStringTopToBottom[row];
                      return SizedBox(
                        height: 28, // reduced height per row
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(fretCount, (col) {
                            bool isCircle = false;
                            String? circleText;
                            bool isMuted = false;

                            if (col == 0) {
                              if (fretVal == 'X') {
                                isCircle = true;
                                circleText = 'X';
                                isMuted = true;
                              } else if (fretVal == '0') {
                                isCircle = true;
                                circleText = '0';
                              }
                            } else {
                              final n = int.tryParse(fretVal);
                              if (n != null && n == col) {
                                isCircle = true;
                                circleText = '$col';
                              }
                            }

                            return Container(
                              width: col == 0 ? firstColWidth : otherColWidth,
                              height: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade600),
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.white,
                              ),
                              alignment: Alignment.center,
                              child: isCircle
                                  ? Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isMuted ? Colors.red.shade700 : circleColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isMuted ? Colors.red : circleColor).withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                child: Center(child: Text(circleText!, style: textStyle)),
                              )
                                  : Text(
                                col == 0 ? '' : '$col',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chordsmith Search'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSearchModeToggle(),
              const SizedBox(height: 16),

              // Standard selection or Custom list
              if (searchMode == SearchMode.standard) _buildStandardSelectors(),
              if (searchMode == SearchMode.custom) _buildCustomList(),

              // Feedback
              if (feedbackMessage.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(feedbackMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
              ],

              // Chord display
              if (displayTabs != null) ...[
                const SizedBox(height: 18),
                SizedBox(width: MediaQuery.of(context).size.width * 0.9, child: _buildGuitarNeck()),
                // Alternatives toggle only for Standard mode
                _buildAlternativeTabsToggle(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


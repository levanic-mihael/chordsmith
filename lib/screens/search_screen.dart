import 'package:flutter/material.dart';
import '../database/chord_database.dart';
import '../models/chord_models.dart'; // Your Tonality, Mode, ChordType models

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Tonality> tonalities = [];
  List<Mode> modes = [];
  List<ChordType> chordTypes = [];

  int? selectedTonalityId;
  int? selectedAccidentalIndex; // Optional: 1 = sharp, 2 = flat
  int? selectedModeId;
  int? selectedChordTypeId;

  Set<int> enabledModeIds = {};
  Set<int> enabledChordTypeIds = {};

  Map<int, String>? chordTabs; // Map: String index (0=high E) -> fret or 'X' or '0'
  String feedbackMessage = '';
  bool loading = true;

  static const accidentalLabels = ['♯', '♭'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
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
      SELECT DISTINCT Mode.id as mode_id, ChordType.id as chord_type_id
      FROM Chord
      JOIN Mode ON Chord.mode_id = Mode.id
      JOIN ChordType ON Chord.type_id = ChordType.id
      WHERE Chord.tonality_id = ?
    ''', [selectedTonalityId]);

    final modeSet = <int>{};
    final chordTypeSet = <int>{};
    for (final row in rows) {
      if (row['mode_id'] is int) modeSet.add(row['mode_id'] as int);
      if (row['chord_type_id'] is int) chordTypeSet.add(row['chord_type_id'] as int);
    }
    setState(() {
      enabledModeIds = modeSet;
      enabledChordTypeIds = chordTypeSet;
      if (selectedModeId != null && !enabledModeIds.contains(selectedModeId!)) {
        selectedModeId = null;
      }
      if (selectedChordTypeId != null && !enabledChordTypeIds.contains(selectedChordTypeId!)) {
        selectedChordTypeId = null;
      }
    });
  }

  void _selectTone(int id) {
    setState(() {
      selectedTonalityId = id;
      selectedModeId = null;
      selectedChordTypeId = null;
      chordTabs = null;
      feedbackMessage = '';
      selectedAccidentalIndex = null;
    });
    _updateEnabledOptions();
  }

  void _selectAccidental(int idx) {
    setState(() {
      if (selectedAccidentalIndex == idx) selectedAccidentalIndex = null;
      else selectedAccidentalIndex = idx;
    });
  }

  void _selectMode(int id) {
    if (!enabledModeIds.contains(id)) return;
    setState(() {
      selectedModeId = id;
      selectedChordTypeId = null;
      chordTabs = null;
      feedbackMessage = '';
    });
  }

  void _selectChordType(int id) {
    if (!enabledChordTypeIds.contains(id)) return;
    setState(() {
      selectedChordTypeId = id;
      chordTabs = null;
      feedbackMessage = '';
    });
  }

  Future<void> _showChord() async {
    if (selectedTonalityId == null || selectedModeId == null || selectedChordTypeId == null) {
      setState(() {
        feedbackMessage = 'Please select tone, mode, and chord type.';
        chordTabs = null;
      });
      return;
    }
    final db = await ChordDatabase.instance.database;
    final chords = await db.query(
      'Chord',
      where: 'tonality_id = ? AND mode_id = ? AND type_id = ?',
      whereArgs: [selectedTonalityId, selectedModeId, selectedChordTypeId],
    );
    if (chords.isEmpty) {
      setState(() {
        feedbackMessage = 'No such chord found';
        chordTabs = null;
      });
      return;
    }
    final tabStr = chords.first['tabs_frets'] as String;
    final tabList = tabStr.split(' ');
    Map<int, String> tabs = {};
    for (int i = 0; i < 6; i++) {
      tabs[i] = tabList[5 - i]; // reverse order to match high E top in UI
    }
    setState(() {
      chordTabs = tabs;
      feedbackMessage = '';
    });
  }

  Widget _button(String label, bool selected, bool enabled, VoidCallback? onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? (selected ? Colors.blue.shade700 : Colors.white) : Colors.grey.shade300,
          border: Border.all(color: enabled ? (selected ? Colors.blue.shade700 : Colors.grey) : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? (selected ? Colors.white : Colors.black) : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildTonalities() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: tonalities.map((e) {
      return _button(
        e.name,
        selectedTonalityId == e.id,
        true,
            () => _selectTone(e.id),
      );
    }).toList(),
  );

  Widget _buildAccidentals() => Wrap(
    spacing: 8,
    children: List.generate(accidentalLabels.length, (i) {
      return _button(
        accidentalLabels[i],
        selectedAccidentalIndex == i + 1,
        true, // always enabled, adapt if needed
            () => _selectAccidental(i + 1),
      );
    }),
  );

  Widget _buildModes() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: modes.map((e) {
      return _button(
        e.name,
        selectedModeId == e.id,
        enabledModeIds.contains(e.id),
            () => _selectMode(e.id),
      );
    }).toList(),
  );

  Widget _buildChordTypes() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: chordTypes.map((e) {
      return _button(
        e.name,
        selectedChordTypeId == e.id,
        enabledChordTypeIds.contains(e.id),
            () => _selectChordType(e.id),
      );
    }).toList(),
  );

  Widget _buildGuitarNeck() {
    if (chordTabs == null) return const SizedBox.shrink();
    final circleColor = Colors.blue.shade700;

    // 6 strings, 7 frets (0 to 6)
    return Center(
      child: AspectRatio(
        aspectRatio: 7 / (6 * 0.5), // width:height approx 2:1 (7 wide, 6 tall, with vertical spacing)
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (stringIdx) {
              final fret = chordTabs![stringIdx]!;
              return Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(7, (fretIdx) {
                    bool showCircle = false;
                    bool showX = false;

                    if (fretIdx == 0) {
                      if (fret == 'X') {
                        showX = true;
                      } else if (fret == '0') {
                        showCircle = true;
                      }
                    } else {
                      showCircle = (int.tryParse(fret) == fretIdx);
                    }
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade600),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: showCircle
                            ? Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: circleColor.withAlpha(50),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        )
                            : showX
                            ? Text(
                          'X',
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        )
                            : Text(
                          fretIdx == 0 ? '' : fretIdx.toString(),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Chord'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Select Tone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              _buildTonalities(),
              const SizedBox(height: 20),
              const Text('Select Accidental', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              _buildAccidentals(),
              const SizedBox(height: 20),
              const Text('Select Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              _buildModes(),
              const SizedBox(height: 20),
              const Text('Select Chord Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              _buildChordTypes(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _showChord,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  child: Text('Show Chord', style: TextStyle(fontSize: 20)),
                ),
              ),
              if (feedbackMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(feedbackMessage, style: const TextStyle(color: Colors.red, fontSize: 18)),
              ],
              if (chordTabs != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: _buildGuitarNeck(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

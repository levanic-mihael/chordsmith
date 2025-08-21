import 'package:flutter/material.dart';
import '../database/chord_database.dart';
import '../models/chord_models.dart'; // Tonality, Mode, ChordType

enum ChordCreateType { custom, alternative }

class CreateChordScreen extends StatefulWidget {
  const CreateChordScreen({super.key});
  @override
  State<CreateChordScreen> createState() => _CreateChordScreenState();
}

class _CreateChordScreenState extends State<CreateChordScreen> {
  ChordCreateType? createType;

  final TextEditingController _nameController = TextEditingController();

  List<Tonality> tonalities = [];
  List<Mode> modes = [];
  List<ChordType> chordTypes = [];
  int? toneId;
  int? modeId;
  int? typeId;

  final int fretCount = 7;
  late List<List<int>> neckMarks; // Using int marks instead of string

  int fretboardOffset = 0;

  static const int noMark = -1;
  static const int openMark = 0;
  static const int muteMark = -2;

  @override
  void initState() {
    super.initState();
    _resetFretboard();
    _loadMeta();
  }

  void _resetFretboard() {
    neckMarks = List.generate(6, (_) => List.filled(fretCount, noMark));
  }

  void _loadMeta() async {
    final db = await ChordDatabase.instance.database;
    final tonalRes = await db.query('Tonality');
    final modeRes = await db.query('Mode');
    final chordTypeRes = await db.query('ChordType');
    if (!mounted) return;
    setState(() {
      tonalities = tonalRes.map((e) => Tonality(id: e['id'] as int, name: e['name'] as String)).toList();
      modes = modeRes.map((e) => Mode(id: e['id'] as int, name: e['name'] as String)).toList();
      chordTypes = chordTypeRes.map((e) => ChordType(id: e['id'] as int, name: e['name'] as String)).toList();
    });
  }

  void _setCreateType(ChordCreateType? type) {
    setState(() {
      createType = type;
      _resetFretboard();
      _nameController.clear();
      toneId = null;
      modeId = null;
      typeId = null;
      fretboardOffset = 0;
    });
  }

  void _onFretTap(int stringIdx, int fretIdx) {
    setState(() {
      int val = neckMarks[stringIdx][fretIdx];
      if (fretIdx == 0) {
        if (val == noMark) {
          neckMarks[stringIdx][0] = openMark;  // Open string
        } else if (val == openMark) {
          neckMarks[stringIdx][fretIdx] = muteMark; // Muted string
        } else {
          neckMarks[stringIdx][fretIdx] = noMark;   // Remove mark
        }
        for (int f = 1; f < fretCount; f++) {
          neckMarks[stringIdx][f] = noMark;
        }
      } else {
        if (val == noMark) {
          for (int f = 0; f < fretCount; f++) {
            neckMarks[stringIdx][f] = noMark;
          }
          neckMarks[stringIdx][fretIdx] = fretIdx + fretboardOffset;
        } else {
          neckMarks[stringIdx][fretIdx] = noMark;
        }
      }
    });
  }

  void _scrollLeft() {
    setState(() {
      if (fretboardOffset > 0) fretboardOffset--;
    });
  }

  void _scrollRight() {
    setState(() {
      fretboardOffset++;
    });
  }

  String _fretDisplay(int fretIdx) {
    if (fretIdx == 0) return "0";
    return "${fretIdx + fretboardOffset}";
  }

  List<String> _generateTabsFrets() {
    List<String> result = [];
    for (int stringIdx = 5; stringIdx >= 0; stringIdx--) {
      int val = neckMarks[stringIdx][0];
      if (val == muteMark) {
        result.add("X");
      } else if (val == openMark) {
        result.add("0");
      } else {
        // Find first fret marked
        int fretMark = noMark;
        for (int f = 1; f < fretCount; f++) {
          int mark = neckMarks[stringIdx][f];
          if (mark != noMark) {
            fretMark = mark;
            break;
          }
        }
        if (fretMark == noMark) {
          result.add("X");
        } else {
          result.add("$fretMark");
        }
      }
    }
    return result;
  }

  Future<void> _saveChord() async {
    final tabs = _generateTabsFrets().join(' ');
    if (createType == ChordCreateType.custom) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter custom chord name")));
        return;
      }
      await ChordDatabase.instance.insertCustomChord(name, tabs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Custom chord saved.")));
      setState(_resetFretboard);
    } else if (createType == ChordCreateType.alternative) {
      if (toneId == null || modeId == null || typeId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select tone, mode, type.")));
        return;
      }
      final baseChord = await ChordDatabase.instance.getStandardChord(toneId!, modeId!, typeId!);
      if (!mounted) return;
      if (baseChord == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Standard chord not found.")));
        return;
      }
      await ChordDatabase.instance.insertAlternativeChord(baseChord['id'] as int, tabs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alternative chord saved.")));
      setState(_resetFretboard);
    }
  }

  Widget _buildFretboard() {
    final stringNames = ['E', 'A', 'D', 'G', 'B', 'E'];
    final circleColor = Colors.blue.shade700;
    final textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), // match frame horizontal margin
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // String names column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(6, (i) {
              return Container(
                height: 32, // reduced vertical height per string
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  stringNames[i],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              );
            }),
          ),

          // Fretboard expanded horizontally
          Expanded(
            child: Column(
              children: List.generate(6, (stringIdx) {
                return SizedBox(
                  height: 32, // reduced height to make it less tall
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(fretCount, (fretIdx) {
                      int val = neckMarks[stringIdx][fretIdx];
                      bool isCircle = false;
                      String? circleText;
                      bool isMuted = false;

                      if (fretIdx == 0) {
                        if (val == openMark) {
                          isCircle = true;
                          circleText = "0";
                        } else if (val == muteMark) {
                          isCircle = true;
                          circleText = "X";
                          isMuted = true;
                        }
                      } else if (val != noMark) {
                        isCircle = true;
                        circleText = "${val}";
                      }

                      final isFirstColumn = fretIdx == 0;
                      return GestureDetector(
                        onTap: () => _onFretTap(stringIdx, fretIdx),
                        child: Container(
                          width: isFirstColumn ? 25 : 50,
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
                                  color:
                                  (isMuted ? Colors.red : circleColor).withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(1, 1),
                                )
                              ],
                            ),
                            child: Center(child: Text(circleText!, style: textStyle)),
                          )
                              : Text(
                            isFirstColumn ? "" : _fretDisplay(fretIdx),
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
        ],
      ),
    );
  }


  Widget _buildMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: createType == ChordCreateType.custom ? Colors.blue : Colors.grey),
          onPressed: () => _setCreateType(ChordCreateType.custom),
          child: const Text('New Chord'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: createType == ChordCreateType.alternative ? Colors.blue : Colors.grey),
          onPressed: () => _setCreateType(ChordCreateType.alternative),
          child: const Text('Alternative'),
        ),
      ],
    );
  }

  Widget _buildAltSpecifier() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: tonalities
              .map((t) => ChoiceChip(
            label: Text(t.name),
            selected: toneId == t.id,
            onSelected: (_) => setState(() => toneId = t.id),
          ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: modes
              .map((m) => ChoiceChip(
            label: Text(m.name),
            selected: modeId == m.id,
            onSelected: (_) => setState(() => modeId = m.id),
          ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: chordTypes
              .map((ct) => ChoiceChip(
            label: Text(ct.name),
            selected: typeId == ct.id,
            onSelected: (_) => setState(() => typeId = ct.id),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildScroller() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: fretboardOffset > 0 ? _scrollLeft : null,
          icon: const Icon(Icons.arrow_left),
        ),
        Text(
          "Frets: 0, ${1 + fretboardOffset} ... ${fretCount - 1 + fretboardOffset}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: _scrollRight,
          icon: const Icon(Icons.arrow_right),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Chord")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenu(),
              const SizedBox(height: 18),
              if (createType == ChordCreateType.custom)
                Column(
                  children: [
                    const Text("Enter name for new chord:"),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              if (createType == ChordCreateType.alternative) ...[
                const Text("Select chord to create alternative for:"),
                _buildAltSpecifier(),
              ],
              const SizedBox(height: 14),
              _buildScroller(),
              const SizedBox(height: 3),
              _buildFretboard(),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _saveChord,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  child: Text("Save Chord", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

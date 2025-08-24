import 'package:flutter/material.dart';

import '../database/chord_database.dart';
import '../models/chord_models.dart';
import '../widgets/guitar_fretboard_editor.dart';

enum ChordCreateType { custom, alternative }

class CreateChordScreen extends StatefulWidget {
  const CreateChordScreen({Key? key}) : super(key: key);

  @override
  _CreateChordScreenState createState() => _CreateChordScreenState();
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

  List<String>? fretboardTabs;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final db = await ChordDatabase.instance.database;
    final tonalRes = await db.query('Tonality');
    final modeRes = await db.query('Mode');
    final chordTypeRes = await db.query('ChordType');

    if (!mounted) return;

    setState(() {
      tonalities = tonalRes
          .map((e) => Tonality(id: e['id'] as int, name: e['name'] as String))
          .toList();
      modes = modeRes
          .map((e) => Mode(id: e['id'] as int, name: e['name'] as String))
          .toList();
      chordTypes = chordTypeRes
          .map((e) => ChordType(id: e['id'] as int, name: e['name'] as String))
          .toList();
    });
  }

  void _setCreateType(ChordCreateType? type) {
    setState(() {
      createType = type;
      _nameController.clear();
      fretboardTabs = null;
      toneId = null;
      modeId = null;
      typeId = null;
    });
  }

  Future<void> _saveChord() async {
    final tabs = fretboardTabs;
    if (tabs == null || tabs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please set chord fingers on fretboard")));
      return;
    }

    if (createType == ChordCreateType.custom) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Enter custom chord name")));
        return;
      }
      await ChordDatabase.instance.insertCustomChord(name, tabs.join(' '));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Custom chord saved.")));
      setState(() {
        _nameController.clear();
        fretboardTabs = null;
      });
    } else if (createType == ChordCreateType.alternative) {
      if (toneId == null || modeId == null || typeId == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Select tone, mode, and type.")));
        return;
      }
      final baseChord =
      await ChordDatabase.instance.getStandardChord(toneId!, modeId!, typeId!);
      if (!mounted) return;
      if (baseChord == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Standard chord not found.")));
        return;
      }
      await ChordDatabase.instance
          .insertAlternativeChord(baseChord['id'] as int, tabs.join(' '));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Alternative chord saved.")));
      setState(() {
        fretboardTabs = null;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Chord")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Menu with buttons for create type
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    createType == ChordCreateType.custom ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _setCreateType(ChordCreateType.custom),
                  child: const Text('New Chord'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    createType == ChordCreateType.alternative ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _setCreateType(ChordCreateType.alternative),
                  child: const Text('Alternative'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (createType == ChordCreateType.custom)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Text("Enter name for new chord:"),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            if (createType == ChordCreateType.alternative)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Text("Select chord to create alternative for:"),
                    const SizedBox(height: 10),
                    _buildAltSpecifier(),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            GuitarFretboardEditor(
              fretCount: 7,
              onChanged: (tabs) {
                setState(() {
                  fretboardTabs = tabs;
                });
              },
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _saveChord,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  child: Text("Save Chord", style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

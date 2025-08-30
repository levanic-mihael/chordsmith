import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;

import '../database/chord_database.dart';
import '../generated/l10n.dart';
import 'report_view_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<FileSystemEntity> _reports = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<Directory> _getReportsDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${baseDir.path}/Chordsmith');
    final reportsDir = Directory('${docDir.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    return reportsDir;
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    final dir = await _getReportsDirectory();
    final files = dir.listSync().where((e) => e.path.endsWith('.xml')).toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    setState(() {
      _reports = files;
      _loading = false;
    });
  }

  Future<void> _createNewReport() async {
    setState(() => _loading = true);
    final db = await ChordDatabase.instance.database;

    final alternativeChords = await db.query('AlternativeChord');
    final customChords = await db.query('CustomChord');
    final favoriteStandard = await db.query('Chord', where: 'favorite = 1');
    final favoriteAlt = await db.query('AlternativeChord', where: 'favorite = 1');
    final favoriteCustom = await db.query('CustomChord', where: 'favorite = 1');

    final favorites = [...favoriteStandard, ...favoriteAlt, ...favoriteCustom];

    final builder = xml.XmlBuilder();
    final now = DateTime.now().toIso8601String();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('ChordsmithReport', nest: () {
      builder.element('ReportDateTime', nest: now);

      builder.element('AlternativeChords', nest: () {
        for (var chord in alternativeChords) {
          builder.element('Chord', attributes: {'id': '${chord['id']}'}, nest: chord['tabs_frets'] ?? '');
        }
      });
      builder.element('CustomChords', nest: () {
        for (var chord in customChords) {
          builder.element('Chord', attributes: {'id': '${chord['id']}'}, nest: chord['tabs_frets'] ?? '');
        }
      });
      builder.element('Favorites', nest: () {
        for (var chord in favorites) {
          builder.element('Chord', attributes: {'id': '${chord['id']}'}, nest: chord['tabs_frets'] ?? '');
        }
      });
    });

    final xmlDocument = builder.buildDocument();
    final xmlString = xmlDocument.toXmlString(pretty: true);

    final dir = await _getReportsDirectory();
    final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.xml';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(xmlString);

    await _loadReports();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.reports)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(strings.createNewReport ?? 'Create new report'),
              onPressed: _createNewReport,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _reports.isEmpty
                  ? Center(child: Text(strings.noReportsYet ?? 'No reports yet.'))
                  : ListView.builder(
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final reportFile = _reports[index];
                  final modified = reportFile.statSync().modified;
                  final name = reportFile.uri.pathSegments.last;
                  return ListTile(
                    title: Text(name),
                    subtitle: Text(modified.toLocal().toString()),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportViewScreen(reportFile: File(reportFile.path)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

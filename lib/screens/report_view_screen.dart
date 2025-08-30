import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;

import '../generated/l10n.dart';

class ReportViewScreen extends StatefulWidget {
  final File reportFile;

  const ReportViewScreen({super.key, required this.reportFile});

  @override
  State createState() => _ReportViewScreenState();
}

class _ReportViewScreenState extends State<ReportViewScreen> {
  xml.XmlDocument? document;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadXml();
  }

  Future<void> _loadXml() async {
    final content = await widget.reportFile.readAsString();
    final doc = xml.XmlDocument.parse(content);
    setState(() {
      document = doc;
      loading = false;
    });
  }

  String _extractText(String xpath) {
    if (document == null) return '';
    try {
      final elements = document!.findAllElements(xpath);
      return elements.isNotEmpty ? elements.first.innerText : '';
    } catch (_) {
      return '';
    }
  }

  List<xml.XmlElement> _getChordElements(String parentTag) {
    if (document == null) return [];
    try {
      return document!.findAllElements(parentTag).expand((e) => e.findElements('Chord')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _generatePdf() async {
    if (document == null) return;

    final pdf = pw.Document();

    final dateTimeText = _extractText('ReportDateTime');
    final altChords = _getChordElements('AlternativeChords');
    final customChords = _getChordElements('CustomChords');
    final favorites = _getChordElements('Favorites');

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Chordsmith Report')),
          pw.Text('Generated on: $dateTimeText'),
          pw.SizedBox(height: 12),
          pw.Text('Alternative Chords:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...altChords.map((chord) => pw.Text('ID: ${chord.getAttribute('id')}, Tabs: ${chord.innerText}')),
          pw.SizedBox(height: 12),
          pw.Text('Custom Chords:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...customChords.map((chord) => pw.Text('ID: ${chord.getAttribute('id')}, Tabs: ${chord.innerText}')),
          pw.SizedBox(height: 12),
          pw.Text('Favorites:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...favorites.map((chord) => pw.Text('ID: ${chord.getAttribute('id')}, Tabs: ${chord.innerText}')),
        ],
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final pdfFilePath = '${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfFile = File(pdfFilePath);
    await pdfFile.writeAsBytes(await pdf.save());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to $pdfFilePath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.reports)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.generatedOn, style: Theme.of(context).textTheme.titleMedium),
            Text(_extractText('ReportDateTime'), style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            Text(strings.alternativeChords, style: Theme.of(context).textTheme.titleMedium),
            ..._getChordElements('AlternativeChords').map((c) => Text('ID: ${c.getAttribute('id')}, Tabs: ${c.innerText}')),
            const SizedBox(height: 12),
            Text(strings.customChords, style: Theme.of(context).textTheme.titleMedium),
            ..._getChordElements('CustomChords').map((c) => Text('ID: ${c.getAttribute('id')}, Tabs: ${c.innerText}')),
            const SizedBox(height: 12),
            Text(strings.favorites, style: Theme.of(context).textTheme.titleMedium),
            ..._getChordElements('Favorites').map((c) => Text('ID: ${c.getAttribute('id')}, Tabs: ${c.innerText}')),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(strings.generate),
                onPressed: _generatePdf,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

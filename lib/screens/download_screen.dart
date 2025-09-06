import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../database/chord_database.dart';
import '../generated/l10n.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  static const String Url =
      'https://raw.githubusercontent.com/levanic-mihael/chordsmith/refs/heads/master/custom_chords.json';

  final List<_SpeedOption> speedOptions = [
    _SpeedOption('No Limit', 0),
    _SpeedOption('10 B/s', 10),
    _SpeedOption('100 B/s', 100),
    _SpeedOption('50 KB/s', 50 * 1024),
    _SpeedOption('100 KB/s', 100 * 1024),
    _SpeedOption('200 KB/s', 200 * 1024),
  ];

  _SpeedOption? selectedSpeed;
  double progress = 0;
  String statusMessage = '';
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    selectedSpeed = speedOptions[0];
  }

  Future<void> _startDownload() async {
    setState(() {
      progress = 0;
      statusMessage = 'Starting download...';
      isDownloading = true;
    });

    try {
      final uri = Uri.parse(Url);
      final client = http.Client();

      final request = http.Request('GET', uri);
      final streamedResponse = await client.send(request);
      final contentLength = streamedResponse.contentLength ?? 0;

      List<int> bytes = [];
      int received = 0;
      final speedLimit = selectedSpeed!.bytesPerSecond;

      final stopwatch = Stopwatch()..start();

      StreamSubscription? subscription;
      subscription = streamedResponse.stream.listen(
            (chunk) async {
          bytes.addAll(chunk);
          received += chunk.length;

          // Update progress
          setState(() {
            progress = contentLength > 0 ? received / contentLength : 0;
            statusMessage = 'Downloading: ${(progress * 100).toStringAsFixed(1)}%';
          });

          // Speed limiting logic
          if (speedLimit > 0) {
            final elapsed = stopwatch.elapsedMilliseconds;
            final expectedElapsed = (received / speedLimit) * 1000;
            final delay = expectedElapsed - elapsed;
            if (delay > 0) {
              await Future.delayed(Duration(milliseconds: delay.floor()));
            }
          }
        },
        onDone: () async {
          stopwatch.stop();
          setState(() {
            progress = 1.0;
            statusMessage = 'Download completed. Processing data...';
          });
          await _processDownloadedData(Uint8List.fromList(bytes));
          client.close();
        },
        onError: (e) {
          stopwatch.stop();
          setState(() {
            statusMessage = 'Download error: $e';
            isDownloading = false;
          });
          client.close();
        },
        cancelOnError: true,
      );

    } catch (e) {
      setState(() {
        statusMessage = 'Failed to start download: $e';
        isDownloading = false;
      });
    }
  }


  Future<void> _processDownloadedData(Uint8List data) async {
    try {
      final jsonString = utf8.decode(data);
      final Map<String, dynamic> dataMap = jsonDecode(jsonString);
      final List<dynamic> chordList = dataMap['customChords'] ?? [];

      final db = await ChordDatabase.instance.database;

      for (final chord in chordList) {
        if (chord is Map<String, dynamic>) {
          final name = chord['name']?.toString() ?? '';
          final tabs = chord['tabs_frets']?.toString() ?? '';
          if (name.isNotEmpty && tabs.isNotEmpty) {
            await db.insert('CustomChord', {
              'name': chord['name'],
              'tabs_frets': chord['tabs_frets'],
              'favorite': chord['favorite'] ?? 0,
            });
          }
        }
      }

      setState(() {
        statusMessage = 'Data processed and added to database.';
        isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download and import successful.')),
      );
    } catch (e) {
      setState(() {
        statusMessage = 'Error processing data: $e';
        isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process downloaded data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.downloadChords)),
        body: Center(
            child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(strings.selectSpeed, style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: speedOptions.map((opt) {
                            final selected = selectedSpeed == opt;
                            return ChoiceChip(
                              label: Text(opt.label),
                              selected: selected,
                              onSelected: (val) {
                                if (!isDownloading) {
                                  setState(() {
                                    selectedSpeed = opt;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: isDownloading ? null : _startDownload,
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
                        const SizedBox(height: 24),
                        if (isDownloading || progress > 0)
                          Column(
                            children: [
                              LinearProgressIndicator(value: progress),
                              const SizedBox(height: 12),
                              Text(statusMessage),
                            ],
                          )
                        else
                          Text(statusMessage),
                      ],
                    ),
                  ),
                ),
            ),
        ),
    );
  }
}

class _SpeedOption {
  final String label;
  final int bytesPerSecond;
  const _SpeedOption(this.label, this.bytesPerSecond);
}

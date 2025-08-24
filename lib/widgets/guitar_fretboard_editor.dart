import 'package:flutter/material.dart';
import 'guitar_fretboard.dart';

class GuitarFretboardEditor extends StatefulWidget {
  final List<List<int>>? initialNeckMarks; // Added to accept initial fret marks
  final int fretCount;
  final int initialOffset;
  final void Function(List<String> tabs)? onChanged;

  const GuitarFretboardEditor({
    Key? key,
    this.fretCount = 7,
    this.initialOffset = 0,
    this.initialNeckMarks, // new parameter
    this.onChanged,
  }) : super(key: key);

  @override
  _GuitarFretboardEditorState createState() => _GuitarFretboardEditorState();
}

class _GuitarFretboardEditorState extends State<GuitarFretboardEditor> {
  static const int noMark = -1;
  static const int openMark = 0;
  static const int muteMark = -2;

  late List<List<int>> neckMarks;
  late int fretboardOffset;

  @override
  void initState() {
    super.initState();
    fretboardOffset = widget.initialOffset;
    neckMarks = widget.initialNeckMarks != null
        ? List<List<int>>.generate(
      6,
          (i) => List.from(widget.initialNeckMarks![i]),
    )
        : List<List<int>>.generate(
      6,
          (_) => List.filled(widget.fretCount, noMark),
    );
  }

  void _onFretTap(int stringIdx, int fretIdx) {
    setState(() {
      int val = neckMarks[stringIdx][fretIdx];
      if (fretIdx == 0) {
        if (val == noMark) {
          neckMarks[stringIdx][0] = openMark;
        } else if (val == openMark) {
          neckMarks[stringIdx][0] = muteMark;
        } else {
          neckMarks[stringIdx][0] = noMark;
          for (int f = 1; f < widget.fretCount; f++) {
            neckMarks[stringIdx][f] = noMark;
          }
        }
      } else {
        if (val == noMark) {
          for (int f = 0; f < widget.fretCount; f++) {
            neckMarks[stringIdx][f] = noMark;
          }
          neckMarks[stringIdx][fretIdx] = fretIdx;
        } else {
          neckMarks[stringIdx][fretIdx] = noMark;
        }
      }
      if (widget.onChanged != null) {
        widget.onChanged!(_generateTabs());
      }
    });
  }

  List<String> _generateTabs() {
    List<String> tabs = [];
    for (int i = 0; i < 6; i++) {
      if (neckMarks[i][0] == muteMark) {
        tabs.add('X');
      } else if (neckMarks[i][0] == openMark) {
        tabs.add('0');
      } else {
        int val = noMark;
        for (int f = 1; f < widget.fretCount; f++) {
          if (neckMarks[i][f] != noMark) {
            val = neckMarks[i][f];
            break;
          }
        }
        if (val == noMark) {
          tabs.add('X');
        } else {
          tabs.add(val.toString());
        }
      }
    }
    return tabs;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _scrollLeft,
              icon: const Icon(Icons.arrow_left),
            ),
            Text(
              "Frets: $fretboardOffset - ${widget.fretCount - 1 + fretboardOffset}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _scrollRight,
              icon: const Icon(Icons.arrow_right),
            ),
          ],
        ),
        GuitarFretboard(
          neckMarks: neckMarks,
          fretCount: widget.fretCount,
          fretboardOffset: fretboardOffset,
          onFretTap: _onFretTap,
        ),
      ],
    );
  }
}

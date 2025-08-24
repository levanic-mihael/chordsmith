import 'package:flutter/material.dart';

import 'guitar_fretboard.dart';

class GuitarFretboardEditor extends StatefulWidget {
  final int fretCount;
  final int initialOffset;
  final void Function(List<String> tabsFrets)? onChanged;

  const GuitarFretboardEditor({
    Key? key,
    this.fretCount = 7,
    this.initialOffset = 0,
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
    neckMarks = List.generate(6, (_) => List.filled(widget.fretCount, noMark));
  }

  void _onFretTap(int stringIdx, int fretIdx) {
    setState(() {
      int val = neckMarks[stringIdx][fretIdx];
      if (fretIdx == 0) {
        if (val == noMark) {
          neckMarks[stringIdx][0] = openMark;
        } else if (val == openMark) {
          neckMarks[stringIdx][fretIdx] = muteMark;
        } else {
          neckMarks[stringIdx][fretIdx] = noMark;
        }
        for (int f = 1; f < widget.fretCount; f++) {
          neckMarks[stringIdx][f] = noMark;
        }
      } else {
        if (val == noMark) {
          for (int f = 0; f < widget.fretCount; f++) {
            neckMarks[stringIdx][f] = noMark;
          }
          neckMarks[stringIdx][fretIdx] = fretIdx + fretboardOffset;
        } else {
          neckMarks[stringIdx][fretIdx] = noMark;
        }
      }
      if (widget.onChanged != null) {
        widget.onChanged!(_generateTabsFrets());
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

  List<String> _generateTabsFrets() {
    List<String> result = [];
    for (int stringIdx = 5; stringIdx >= 0; stringIdx--) {
      int val = neckMarks[stringIdx][0];
      if (val == muteMark) {
        result.add("X");
      } else if (val == openMark) {
        result.add("0");
      } else {
        int fretMark = noMark;
        for (int f = 1; f < widget.fretCount; f++) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scroll controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _scrollLeft,
              icon: const Icon(Icons.arrow_left),
            ),
            Text(
              "Frets: 0, ${1 + fretboardOffset} ... ${widget.fretCount - 1 + fretboardOffset}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _scrollRight,
              icon: const Icon(Icons.arrow_right),
            ),
          ],
        ),
        // Fretboard editor display
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

import 'package:flutter/material.dart';

class GuitarFretboard extends StatelessWidget {
  final List<List<int>> neckMarks; // 6 strings x fretCount frets
  final int fretCount;
  final int fretboardOffset;
  final void Function(int stringIdx, int fretIdx)? onFretTap;

  static const int noMark = -1;
  static const int openMark = 0;
  static const int muteMark = -2;

  const GuitarFretboard({
    Key? key,
    required this.neckMarks,
    this.fretCount = 7,
    this.fretboardOffset = 0,
    this.onFretTap,
  }) : super(key: key);

  String fretDisplay(int fretIdx) {
    return fretIdx == 0 ? "0" : "${fretIdx + fretboardOffset}";
  }

  @override
  Widget build(BuildContext context) {
    const stringNames = ['E', 'A', 'D', 'G', 'B', 'E'];
    final circleColor = Colors.blue.shade700;
    final textStyle =
    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14);

    final availableWidth = MediaQuery.of(context).size.width * 0.8;
    final usableWidth = availableWidth * 0.8;

    final firstColWidth = usableWidth * 0.12;
    final otherColWidth = (usableWidth - firstColWidth) / (fretCount - 1);

    final firstColHeight = otherColWidth / 2; // Use same height as other frets for alignment
    final otherColHeight = otherColWidth / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column with string names, matching rows height exactly with fret rows
          IntrinsicHeight(
            child: SizedBox(
              width: firstColWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(6, (i) {
                  return Container(
                    height: firstColHeight,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(stringNames[i],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  );
                }),
              ),
            ),
          ),

          // Right: fretboard rows
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(6, (stringIdx) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(fretCount, (fretIdx) {
                    final int val = neckMarks[stringIdx][fretIdx];
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
                    } else if (val > 0 && val == fretIdx + fretboardOffset) {
                      isCircle = true;
                      circleText = "$val";
                    }

                    final bool isZeroFret = fretIdx == 0;
                    // 0 fret: square (width = height = otherColHeight)
                    // others: width twice height
                    final cellHeight = otherColHeight;
                    final cellWidth = isZeroFret ? cellHeight : otherColWidth;

                    return GestureDetector(
                      onTap: onFretTap != null ? () => onFretTap!(stringIdx, fretIdx) : null,
                      child: Container(
                        width: cellWidth,
                        height: cellHeight,
                        margin: const EdgeInsets.symmetric(horizontal: 2), // only horizontal margins
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade600),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: isCircle
                            ? Container(
                          width: cellHeight * (24 / 28),
                          height: cellHeight * (24 / 28),
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
                          fretIdx == 0 ? "" : fretDisplay(fretIdx),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

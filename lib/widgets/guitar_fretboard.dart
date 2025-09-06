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
    super.key,
    required this.neckMarks,
    this.fretCount = 7,
    this.fretboardOffset = 0,
    this.onFretTap,
  });

  String fretDisplay(int fretIdx) {
    return fretIdx == 0 ? "0" : "${fretIdx + fretboardOffset}";
  }

  @override
  Widget build(BuildContext context) {
    const stringNames = ['E', 'A', 'D', 'G', 'B', 'E'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final circleColor = Colors.blue.shade700;
    final textStyle = TextStyle(
      color: isDark ? Colors.grey.shade300 : Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    final fretboardBgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade600;
    final fretNumberColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    final availableWidth = MediaQuery.of(context).size.width * 0.8;
    final usableWidth = availableWidth * 0.8;
    final firstColWidth = usableWidth * 0.12;
    final otherColWidth = (usableWidth - firstColWidth) / (fretCount - 1);
    final firstColHeight = otherColWidth / 2;
    final otherColHeight = otherColWidth / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    child: Text(
                      stringNames[i],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.black,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
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
                    final cellHeight = otherColHeight;
                    final cellWidth = isZeroFret ? cellHeight : otherColWidth;

                    return GestureDetector(
                      onTap: onFretTap != null ? () => onFretTap!(stringIdx, fretIdx) : null,
                      child: Container(
                        width: cellWidth,
                        height: cellHeight,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(6),
                          color: fretboardBgColor,
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
                                color: (isMuted ? Colors.red : circleColor).withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                          child: Center(child: Text(circleText!, style: textStyle)),
                        )
                            : Text(
                          fretIdx == 0 ? "" : fretDisplay(fretIdx),
                          style: TextStyle(color: fretNumberColor, fontSize: 12),
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

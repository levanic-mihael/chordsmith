import 'dart:math' as math;
import 'package:flutter/material.dart';

class GuitarFretboard extends StatelessWidget {
  final List<List<int>> neckMarks; // 6 strings × fretCount frets
  final int fretCount;
  final int fretboardOffset;
  final void Function(int stringIdx, int fretIdx)? onFretTap;

  static const int noMark = -1;
  static const int openMark = 0;
  static const int muteMark = -2;

  // String names in standard order: index 0 = low E, index 5 = high E
  static const List<String> _names = ['E', 'A', 'D', 'G', 'B', 'E'];

  const GuitarFretboard({
    super.key,
    required this.neckMarks,
    this.fretCount = 7,
    this.fretboardOffset = 0,
    this.onFretTap,
  });

  String _fretLabel(int fretIdx) =>
      fretIdx == 0 ? '0' : '${fretIdx + fretboardOffset}';

  // ---------------------------------------------------------------------------
  // Shared cell builder
  // ---------------------------------------------------------------------------
  Widget _cell({
    required int stringIdx,
    required int fretIdx,
    required double w,
    required double h,
    required Color circleColor,
    required Color bgColor,
    required Color borderColor,
    required Color fretNumColor,
    required TextStyle circleStyle,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(horizontal: 2),
    bool showFretNumWhenEmpty = false,
  }) {
    final val = neckMarks[stringIdx][fretIdx];
    bool isCircle = false;
    String? circleText;
    bool isMuted = false;

    if (fretIdx == 0) {
      if (val == openMark) {
        isCircle = true;
        circleText = '0';
      } else if (val == muteMark) {
        isCircle = true;
        circleText = 'X';
        isMuted = true;
      }
    } else if (val > 0 && val == fretIdx + fretboardOffset) {
      isCircle = true;
      circleText = '$val';
    }

    final circleSize = h * 0.85;

    return GestureDetector(
      onTap: onFretTap != null ? () => onFretTap!(stringIdx, fretIdx) : null,
      child: Container(
        width: w,
        height: h,
        margin: margin,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
          color: bgColor,
        ),
        alignment: Alignment.center,
        child: isCircle
            ? Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: isMuted ? Colors.red.shade700 : circleColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isMuted ? Colors.red : circleColor)
                          .withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Center(child: Text(circleText!, style: circleStyle)),
              )
            : Text(
                (showFretNumWhenEmpty && fretIdx > 0)
                    ? _fretLabel(fretIdx)
                    : '',
                style: TextStyle(color: fretNumColor, fontSize: 12),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LANDSCAPE layout
  // Strings run as rows. Low E (string 0) at the bottom, high E (string 5) at
  // the top — so reading upward you see E A D G B E.
  // ---------------------------------------------------------------------------
  Widget _buildLandscape(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final circleColor = Colors.blue.shade700;
    final circleStyle = TextStyle(
      color: isDark ? Colors.grey.shade300 : Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor = Colors.grey.shade600;
    final fretNumColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final labelColor = isDark ? Colors.grey.shade300 : Colors.black;

    final avail = MediaQuery.of(context).size.width * 0.8;
    final usable = avail * 0.8;
    final labelW = usable * 0.12;
    final cellW = (usable - labelW) / (fretCount - 1);
    final cellH = cellW / 2;

    // Display order: row 0 = string 5 (high E), row 5 = string 0 (low E)
    const displayToString = [5, 4, 3, 2, 1, 0];
    // String label order from top to bottom: high→low
    const displayNames = ['E', 'B', 'G', 'D', 'A', 'E'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // String name labels
          IntrinsicHeight(
            child: SizedBox(
              width: labelW,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(6, (i) => Container(
                  height: cellH,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    displayNames[i],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                )),
              ),
            ),
          ),
          // Fretboard grid
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(6, (displayRow) {
                final stringIdx = displayToString[displayRow];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(fretCount, (fretIdx) {
                    final isZeroFret = fretIdx == 0;
                    final w = isZeroFret ? cellH : cellW;
                    return _cell(
                      stringIdx: stringIdx,
                      fretIdx: fretIdx,
                      w: w,
                      h: cellH,
                      circleColor: circleColor,
                      bgColor: bgColor,
                      borderColor: borderColor,
                      fretNumColor: fretNumColor,
                      circleStyle: circleStyle,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      showFretNumWhenEmpty: true,
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

  // ---------------------------------------------------------------------------
  // PORTRAIT layout
  // Transposed: strings become columns (E A D G B E left→right), frets become
  // rows (fret 0 at top, increasing downward). Each cell is square, making the
  // diagram much larger on a phone.
  // ---------------------------------------------------------------------------
  Widget _buildPortrait(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final circleColor = Colors.blue.shade700;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor = Colors.grey.shade600;
    final fretNumColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final labelColor = isDark ? Colors.grey.shade300 : Colors.black;
    final circleTextColor = isDark ? Colors.grey.shade300 : Colors.white;

    const fretLabelW = 28.0;
    const cellMargin = 2.0;
    const headerH = 28.0;
    const fret0Ratio = 0.4;

    return LayoutBuilder(
      builder: (_, constraints) {
        // Width: divide available space evenly across 6 string columns
        final slotW = (constraints.maxWidth - fretLabelW) / 6;
        final cellW = slotW - cellMargin * 2;

        // Height: when the parent gives a finite height (e.g. via Expanded),
        // derive fretH so the whole diagram fills that space exactly.
        // Total height = headerH
        //              + (fret0Ratio * fretH + 2*cellMargin)   ← fret-0 row
        //              + (fretCount-1) * (fretH + 2*cellMargin) ← remaining rows
        //              = headerH + fretH*(fret0Ratio + fretCount - 1)
        //                        + 2*cellMargin*fretCount
        // Solving for fretH:
        final double fretH;
        if (constraints.maxHeight.isFinite) {
          final effectiveRows = fret0Ratio + (fretCount - 1);
          fretH = ((constraints.maxHeight - headerH - 2 * cellMargin * fretCount)
                  / effectiveRows)
              .clamp(12.0, 200.0);
        } else {
          // Fallback when height is unconstrained: use square cells
          fretH = cellW;
        }
        final fret0H = fretH * fret0Ratio;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row: string labels ────────────────────────────────────
            Row(
              children: [
                const SizedBox(width: fretLabelW, height: headerH),
                ...List.generate(6, (j) => SizedBox(
                      width: slotW,
                      height: headerH,
                      child: Center(
                        child: Text(
                          _names[j],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
            // ── Fret rows ────────────────────────────────────────────────────
            ...List.generate(fretCount, (fretIdx) {
              final thisH = fretIdx == 0 ? fret0H : fretH;
              // Scale circle font to fit the (potentially short) fret-0 row
              final fontSize =
                  (math.min(cellW, thisH) * 0.45).clamp(7.0, 14.0);
              final circleStyle = TextStyle(
                color: circleTextColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              );
              return Row(
                children: [
                  SizedBox(
                    width: fretLabelW,
                    height: thisH + cellMargin * 2,
                    child: Center(
                      child: Text(
                        _fretLabel(fretIdx),
                        style: TextStyle(
                          color: fretNumColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(6, (stringIdx) => _cell(
                        stringIdx: stringIdx,
                        fretIdx: fretIdx,
                        w: cellW,
                        h: thisH,
                        circleColor: circleColor,
                        bgColor: bgColor,
                        borderColor: borderColor,
                        fretNumColor: fretNumColor,
                        circleStyle: circleStyle,
                        margin: const EdgeInsets.all(cellMargin),
                        showFretNumWhenEmpty: false,
                      )),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait
        ? _buildPortrait(context)
        : _buildLandscape(context);
  }
}

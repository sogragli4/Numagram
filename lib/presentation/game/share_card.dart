import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/domain/entities/puzzle_grid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The shareable completion card: a compact render of the solved grid plus
/// date/time, captured via [shareCompletionCard] and handed to the OS share
/// sheet. Kept as a real (if small) on-screen widget in the completion
/// sheet — rendering off-screen and never laying it out would leave
/// [RenderRepaintBoundary.toImage] with nothing to capture.
class ShareCard extends StatelessWidget {
  const ShareCard({
    required this.solution,
    required this.elapsedLabel,
    required this.dateLabel,
    super.key,
  });

  final PuzzleGrid solution;
  final String elapsedLabel;
  final String dateLabel;

  static const _cardSize = 360.0;
  static const _cellGap = 2.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: _cardSize,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.shareCardAppName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: solution.width / solution.height,
            child: CustomPaint(
              painter: _ShareGridPainter(
                solution: solution,
                filledColor: colorScheme.primary,
                emptyColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(dateLabel, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            l10n.shareCardTimeLabel(elapsedLabel),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ShareGridPainter extends CustomPainter {
  const _ShareGridPainter({
    required this.solution,
    required this.filledColor,
    required this.emptyColor,
  });

  final PuzzleGrid solution;
  final Color filledColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth =
        (size.width - (solution.width - 1) * ShareCard._cellGap) /
        solution.width;
    final cellHeight =
        (size.height - (solution.height - 1) * ShareCard._cellGap) /
        solution.height;
    final paint = Paint();

    for (var row = 0; row < solution.height; row++) {
      for (var col = 0; col < solution.width; col++) {
        paint.color = solution.cellAt(row, col) ? filledColor : emptyColor;
        final left = col * (cellWidth + ShareCard._cellGap);
        final top = row * (cellHeight + ShareCard._cellGap);
        canvas.drawRect(Rect.fromLTWH(left, top, cellWidth, cellHeight), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ShareGridPainter oldDelegate) =>
      oldDelegate.solution != solution ||
      oldDelegate.filledColor != filledColor ||
      oldDelegate.emptyColor != emptyColor;
}

/// Formats the puzzle date for display on the card, in the app's current
/// locale.
String formatShareCardDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);

/// Captures [boundaryKey]'s current render as a PNG and opens the OS share
/// sheet for it. [boundaryKey] must be attached to a [RepaintBoundary] that
/// has already been laid out (e.g. the [ShareCard] shown in the completion
/// sheet) — an unmounted or not-yet-painted boundary has nothing to
/// capture.
Future<void> shareCompletionCard({
  required GlobalKey boundaryKey,
  required String shareText,
}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;

  final image = await boundary.toImage(pixelRatio: 3);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return;

  final bytes = byteData.buffer.asUint8List();
  final file = await _writeTempPng(bytes);
  await SharePlus.instance.share(
    ShareParams(text: shareText, files: [XFile(file.path)]),
  );
}

Future<File> _writeTempPng(Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/nonogram_share_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  return file.writeAsBytes(bytes);
}

import 'package:flutter/material.dart';

/// Truncated desktop table text with optional hover tooltip.
class AppDesktopTableCell extends StatelessWidget {
  const AppDesktopTableCell(
    this.text, {
    super.key,
    this.maxLines = 1,
    this.style,
  });

  final String text;
  final int maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    if (text.trim().isEmpty || text == '—') {
      return label;
    }

    return Tooltip(
      message: text,
      waitDuration: const Duration(milliseconds: 400),
      child: label,
    );
  }
}

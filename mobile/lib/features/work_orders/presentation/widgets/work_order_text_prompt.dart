import 'package:flutter/material.dart';

/// Dialog prompt that owns its [TextEditingController] for the full route life.
///
/// Disposing the controller only after the route is fully dismissed avoids
/// Flutter's `_dependents.isEmpty` assertion when a [TextField] is still
/// attached during the pop animation.
Future<String?> promptWorkOrderText(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  required String cancelLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _WorkOrderTextPromptDialog(
      title: title,
      hint: hint,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
}

class _WorkOrderTextPromptDialog extends StatefulWidget {
  const _WorkOrderTextPromptDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String cancelLabel;

  @override
  State<_WorkOrderTextPromptDialog> createState() =>
      _WorkOrderTextPromptDialogState();
}

class _WorkOrderTextPromptDialogState extends State<_WorkOrderTextPromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: widget.hint),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

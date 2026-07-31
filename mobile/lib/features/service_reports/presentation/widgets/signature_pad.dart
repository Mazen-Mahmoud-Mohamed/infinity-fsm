import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.controller,
    this.height = 220,
  });

  final SignaturePadController controller;
  final double height;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class SignaturePadController {
  _SignaturePadState? _state;

  bool get hasStroke => _state?._strokes.isNotEmpty == true;

  void clear() => _state?.clear();

  Future<Uint8List?> toPngBytes() =>
      _state?.exportPng() ?? Future<Uint8List?>.value(null);

  void _attach(_SignaturePadState state) => _state = state;
  void _detach(_SignaturePadState state) {
    if (_state == state) _state = null;
  }
}

class _SignaturePadState extends State<SignaturePad> {
  final _boundaryKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset>? _current;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void didUpdateWidget(covariant SignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    super.dispose();
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _current = null;
    });
  }

  Future<Uint8List?> exportPng() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: widget.height,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: ColoredBox(
                  color: Colors.white,
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _current = [details.localPosition];
                        _strokes.add(_current!);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _current?.add(details.localPosition);
                      });
                    },
                    onPanEnd: (_) => _current = null,
                    child: CustomPaint(
                      painter: _SignaturePainter(
                        strokes: _strokes,
                        strokeColor: Colors.black,
                      ),
                      child: Center(
                        child: _strokes.isEmpty
                            ? Text(
                                l10n.reportsSignHere,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: clear,
            icon: const Icon(Icons.clear),
            label: Text(l10n.reportsClearSignature),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes, required this.strokeColor});

  final List<List<Offset>> strokes;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 1.5, paint..style = PaintingStyle.fill);
          paint.style = PaintingStyle.stroke;
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

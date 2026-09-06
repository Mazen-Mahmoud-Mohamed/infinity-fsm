import 'package:flutter/material.dart';

class WorkingTimer extends StatelessWidget {
  const WorkingTimer({super.key, required this.seconds});

  final int seconds;

  String get _formatted {
    final duration = Duration(seconds: seconds < 0 ? 0 : seconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatted,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
    );
  }
}

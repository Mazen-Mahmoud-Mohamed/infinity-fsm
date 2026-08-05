import 'package:equatable/equatable.dart';

/// In-memory voice capture for the next overtime checkpoint submission.
class OvertimeVoiceDraft extends Equatable {
  const OvertimeVoiceDraft({
    required this.filePath,
    required this.bytes,
    required this.durationSeconds,
  });

  final String filePath;
  final List<int> bytes;
  final double durationSeconds;

  @override
  List<Object?> get props => [filePath, bytes, durationSeconds];
}

import 'package:equatable/equatable.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';

/// Excel export depth — summary statistics only vs full session dataset.
enum OvertimeExportMode {
  summary,
  detailed;

  String get apiValue => name;
}

/// Report language for generated Excel human-readable content.
enum OvertimeExportLanguage {
  english,
  arabic;

  String get apiValue => this == OvertimeExportLanguage.arabic ? 'ar' : 'en';

  /// Defaults from the app locale (`ar` → Arabic, otherwise English).
  static OvertimeExportLanguage fromLocaleCode(String? localeCode) {
    if (localeCode?.toLowerCase().startsWith('ar') ?? false) {
      return OvertimeExportLanguage.arabic;
    }
    return OvertimeExportLanguage.english;
  }
}

/// Filter set for administrator/supervisor overtime Excel export.
class OvertimeExportFilters extends Equatable {
  const OvertimeExportFilters({
    this.startDate,
    this.endDate,
    this.status,
    this.type,
    this.userId,
    this.search,
    this.mode = OvertimeExportMode.detailed,
    this.language = OvertimeExportLanguage.english,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final OvertimeStatus? status;
  final OvertimeType? type;
  final String? userId;
  final String? search;
  final OvertimeExportMode mode;
  final OvertimeExportLanguage language;

  Map<String, dynamic> toQueryParameters() {
    String? dateOnly(DateTime? d) {
      if (d == null) return null;
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    return {
      if (startDate != null) 'startDate': dateOnly(startDate),
      if (endDate != null) 'endDate': dateOnly(endDate),
      if (status != null) 'status': status!.apiValue,
      if (type != null) 'type': type!.apiValue,
      if (userId != null && userId!.isNotEmpty) 'userId': userId,
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      'mode': mode.apiValue,
      'language': language.apiValue,
    };
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        status,
        type,
        userId,
        search,
        mode,
        language,
      ];
}

class OvertimeExcelExportResult extends Equatable {
  const OvertimeExcelExportResult({
    required this.bytes,
    required this.fileName,
    this.rowCount,
  });

  final List<int> bytes;
  final String fileName;
  final int? rowCount;

  @override
  List<Object?> get props => [bytes, fileName, rowCount];
}

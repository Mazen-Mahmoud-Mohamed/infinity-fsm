enum OvertimeType {
  normal,
  travel;

  static OvertimeType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'TRAVEL':
        return OvertimeType.travel;
      default:
        return OvertimeType.normal;
    }
  }

  String get apiValue {
    switch (this) {
      case OvertimeType.normal:
        return 'NORMAL';
      case OvertimeType.travel:
        return 'TRAVEL';
    }
  }

  String get label {
    switch (this) {
      case OvertimeType.normal:
        return 'Normal Overtime';
      case OvertimeType.travel:
        return 'Travel Overtime';
    }
  }
}

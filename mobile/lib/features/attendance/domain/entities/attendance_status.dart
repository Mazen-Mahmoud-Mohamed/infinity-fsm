enum AttendanceStatus {
  notStarted,
  clockedIn,
  onBreak,
  clockedOut;

  static AttendanceStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'CLOCKED_IN':
        return AttendanceStatus.clockedIn;
      case 'ON_BREAK':
        return AttendanceStatus.onBreak;
      case 'CLOCKED_OUT':
        return AttendanceStatus.clockedOut;
      default:
        return AttendanceStatus.notStarted;
    }
  }

  String get apiValue {
    switch (this) {
      case AttendanceStatus.clockedIn:
        return 'CLOCKED_IN';
      case AttendanceStatus.onBreak:
        return 'ON_BREAK';
      case AttendanceStatus.clockedOut:
        return 'CLOCKED_OUT';
      case AttendanceStatus.notStarted:
        return 'NOT_STARTED';
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.notStarted:
        return 'Not started';
      case AttendanceStatus.clockedIn:
        return 'Working';
      case AttendanceStatus.onBreak:
        return 'On break';
      case AttendanceStatus.clockedOut:
        return 'Clocked out';
    }
  }
}

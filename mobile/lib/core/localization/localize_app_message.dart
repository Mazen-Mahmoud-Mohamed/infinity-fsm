import 'package:mobile/core/localization/l10n/app_localizations.dart';

/// Maps cubit/repository message keys, API error codes, and known English
/// fallbacks to AppLocalizations. Never returns raw backend English text.
String localizeAppMessage(
  AppLocalizations l10n,
  String? message, {
  String? code,
}) {
  final key = (code != null && code.isNotEmpty) ? code : message;
  if (key == null || key.isEmpty) {
    return l10n.errorGeneric;
  }

  if (key.startsWith('attendanceGpsAccuracyExceeded:')) {
    final parts = key.split(':');
    if (parts.length >= 3) {
      return l10n.attendanceGpsAccuracyExceeded(parts[1], parts[2]);
    }
    return l10n.gpsAccuracyTooLow;
  }

  switch (key) {
    case 'livePhotoRequired':
    case 'LIVE_PHOTO_REQUIRED':
    case 'SELFIE_REQUIRED':
    case 'PHOTO_REQUIRED':
      return l10n.errorLivePhotoRequired;
    case 'deviceTimeIncorrect':
    case 'CLOCK_SKEW':
      return l10n.errorClockSkew;
    case 'gpsAccuracyTooLow':
    case 'GPS_ACCURACY_TOO_LOW':
      return l10n.errorGpsAccuracyTooLow;
    case 'GPS_REQUIRED':
      return l10n.errorGpsRequired;
    case 'INVALID_EMAIL':
    case 'errorInvalidCredentials':
      return l10n.errorInvalidEmail;
    case 'INVALID_PASSWORD':
      return l10n.errorInvalidPassword;
    case 'USER_DISABLED':
      return l10n.errorUserDisabled;
    case 'WORK_ORDER_NOT_FOUND':
      return l10n.errorWorkOrderNotFound;
    case 'NOT_FOUND':
      return l10n.errorNotFound;
    case 'FORBIDDEN':
    case 'errorForbidden':
      return l10n.errorForbidden;
    case 'UNAUTHORIZED':
      return l10n.errorUnauthorized;
    case 'VALIDATION_ERROR':
      return l10n.errorValidation;
    case 'DEVICE_REQUIRED':
      return l10n.errorDeviceRequired;
    case 'CLIENT_REQUEST_REQUIRED':
      return l10n.errorClientRequestRequired;
    case 'INVALID_TIMESTAMP':
      return l10n.errorInvalidTimestamp;
    case 'CONFLICT':
      return l10n.errorConflict;
    case 'USER_NOT_FOUND':
      return l10n.errorUserNotFound;
    case 'OVERTIME_NOT_FOUND':
      return l10n.errorOvertimeNotFound;
    case 'TITLE_REQUIRED':
      return l10n.errorTitleRequired;
    case 'INVALID_PRIORITY':
      return l10n.errorInvalidPriority;
    case 'INVALID_DATE':
      return l10n.errorInvalidDate;
    case 'INVALID_STATUS':
      return l10n.errorInvalidStatus;
    case 'AVATAR_REQUIRED':
      return l10n.errorAvatarRequired;
    case 'UPLOAD_FAILED':
      return l10n.errorUploadFailed;
    case 'attendanceUpdated':
      return l10n.attendanceUpdated;
    case 'overtimeEnded':
      return l10n.overtimeEnded;
    case 'normalOvertimeStarted':
      return l10n.normalOvertimeStarted;
    case 'travelOvertimeStarted':
      return l10n.travelOvertimeStarted;
    case 'overtimeArrivedAtWorkSiteRecorded':
      return l10n.overtimeArrivedAtWorkSiteRecorded;
    case 'overtimeFinishedWorkRecorded':
      return l10n.overtimeFinishedWorkRecorded;
    case 'overtimeCompletePriorCheckpoints':
      return l10n.overtimeCompletePriorCheckpoints;
    case 'overtimeLoadFailed':
      return l10n.overtimeLoadFailed;
    case 'errorGeneric':
      return l10n.errorGeneric;
    case 'sessionExpired':
      return l10n.sessionExpired;
    case 'emailRequired':
      return l10n.emailRequired;
    case 'emailInvalid':
      return l10n.emailInvalid;
    case 'passwordRequired':
      return l10n.passwordRequired;
    case 'passwordMinLength':
      return l10n.passwordMinLength;
    case 'deviceRegistrationFailed':
      return l10n.deviceRegistrationFailed;
    case 'firstSignInRequiresInternet':
      return l10n.firstSignInRequiresInternet;
    case 'rolesNotLoaded':
      return l10n.rolesNotLoaded;
    case 'rolesSelectAtLeastOneUser':
      return l10n.rolesSelectAtLeastOneUser;
    case 'overtimeApprovedMessage':
      return l10n.overtimeApprovedMessage;
    case 'overtimeRejectedMessage':
      return l10n.overtimeRejectedMessage;
    case 'overtimeDetailsLoadFailed':
      return l10n.overtimeDetailsLoadFailed;
    case 'overtimeHistoryLoadFailed':
      return l10n.overtimeHistoryLoadFailed;
    case 'workOrderJobTitleRequired':
      return l10n.workOrderJobTitleRequired;
    case 'workOrderJobTitleMaxLength':
      return l10n.workOrderJobTitleMaxLength;
    case 'workOrderLocationUrlInvalid':
      return l10n.workOrderLocationUrlInvalid;
    case 'workOrderCustomerPhoneInvalid':
      return l10n.workOrderCustomerPhoneInvalid;
    case 'workOrderMaxCustomerPhonesReached':
      return l10n.workOrderMaxCustomerPhonesReached;
    case 'workOrderMaxAttachmentsReached':
      return l10n.workOrderMaxAttachmentsReached;
    case 'workOrderUpdated':
      return l10n.workOrderUpdated;
    case 'workOrderCreated':
      return l10n.workOrderCreated;
    case 'workOrderSaved':
      return l10n.workOrderSaved;
    case 'workOrderAfterPhotoRequiredSnackbar':
      return l10n.workOrderAfterPhotoRequiredSnackbar;
    case 'workOrderAccepted':
      return l10n.workOrderAccepted;
    case 'workOrderRejected':
      return l10n.workOrderRejected;
    case 'workOrderStarted':
      return l10n.workOrderStarted;
    case 'workOrderCompletedMessage':
      return l10n.workOrderCompletedMessage;
    case 'workOrderCancelledMessage':
      return l10n.workOrderCancelledMessage;
    case 'workOrderTechnicianAssigned':
      return l10n.workOrderTechnicianAssigned;
    case 'workOrderDeleted':
      return l10n.workOrderDeleted;
    case 'workOrderBeforeWorkSaved':
      return l10n.workOrderBeforeWorkSaved;
    case 'workOrderProgressNoteAdded':
      return l10n.workOrderProgressNoteAdded;
    case 'workOrderProgressPhotoUploaded':
      return l10n.workOrderProgressPhotoUploaded;
    case 'workOrderAfterPhotoUploaded':
      return l10n.workOrderAfterPhotoUploaded;
    case 'workOrderPhotoRemoved':
      return l10n.workOrderPhotoRemoved;
    case 'errorServer':
      return l10n.errorServer;
    case 'errorRequestTimeout':
      return l10n.errorRequestTimeout;
    case 'errorUnableToReachServer':
      return l10n.errorUnableToReachServer;
    case 'errorNoInternet':
      return l10n.errorNoInternet;
    case 'errorSecureConnectionFailed':
      return l10n.errorSecureConnectionFailed;
    case 'errorRequestFailed':
      return l10n.errorRequestFailed;
    case 'errorUnexpectedNetworkError':
      return l10n.errorUnexpectedNetworkError;
    case 'attendanceAlreadyClockedIn':
      return l10n.attendanceAlreadyClockedIn;
    case 'attendanceMustClockInBeforeOut':
      return l10n.attendanceMustClockInBeforeOut;
    case 'attendanceEndBreakBeforeOut':
      return l10n.attendanceEndBreakBeforeOut;
    case 'attendanceAlreadyClockedOut':
      return l10n.attendanceAlreadyClockedOut;
    case 'attendanceMustClockInBeforeBreak':
      return l10n.attendanceMustClockInBeforeBreak;
    case 'attendanceBreakAlreadyInProgress':
      return l10n.attendanceBreakAlreadyInProgress;
    case 'attendanceNoActiveBreak':
      return l10n.attendanceNoActiveBreak;
    case 'attendanceWebOfflinePhotoRequired':
      return l10n.attendanceWebOfflinePhotoRequired;
    case 'locationServicesDisabled':
      return l10n.locationServicesDisabled;
    case 'locationPermissionRequired':
      return l10n.locationPermissionRequired;
    case 'locationPermissionDeniedForever':
      return l10n.locationPermissionDeniedForever;
    case 'locationTimeout':
      return l10n.locationTimeout;
    case 'cameraUnavailable':
      return l10n.cameraUnavailable;
    case 'authNoActiveSession':
      return l10n.authNoActiveSession;
    case 'authOfflineRestoreProfile':
      return l10n.authOfflineRestoreProfile;
    case 'overtimeNoRunningSession':
      return l10n.overtimeNoRunningSession;
    case 'overtimeContinueExistingSession':
      return l10n.overtimeContinueExistingSession;
    case 'overtimeActiveSessionReminder':
      return l10n.overtimeActiveSessionReminder;
    case 'assetsQrScannerNotReady':
      return l10n.assetsQrScannerNotReady;
    case 'A live photo is required.':
      return l10n.errorLivePhotoRequired;
    case 'Device time appears to be incorrect.':
      return l10n.errorClockSkew;
    case 'Email is required.':
      return l10n.emailRequired;
    case 'Enter a valid email address.':
      return l10n.emailInvalid;
    case 'Password is required.':
      return l10n.passwordRequired;
    case 'Password must be at least 8 characters.':
      return l10n.passwordMinLength;
    case 'Device registration failed. Restart the app.':
      return l10n.deviceRegistrationFailed;
    case 'Internet is required for the first sign-in.':
      return l10n.firstSignInRequiresInternet;
    case 'Your session has expired. Please sign in again.':
      return l10n.sessionExpired;
    case 'Session expired.':
      return l10n.sessionExpired;
    case 'Role not loaded':
      return l10n.rolesNotLoaded;
    case 'Select at least one user':
      return l10n.rolesSelectAtLeastOneUser;
    case 'Overtime approved.':
      return l10n.overtimeApprovedMessage;
    case 'Overtime rejected.':
      return l10n.overtimeRejectedMessage;
    case 'Job title is required':
      return l10n.workOrderJobTitleRequired;
    case 'Job title must be at most 200 characters':
      return l10n.workOrderJobTitleMaxLength;
    case 'Work order updated':
      return l10n.workOrderUpdated;
    case 'Work order created':
      return l10n.workOrderCreated;
    case 'Saved':
      return l10n.workOrderSaved;
    case 'Add at least one after photo before completing':
      return l10n.workOrderAfterPhotoRequiredSnackbar;
    case 'Work order accepted':
      return l10n.workOrderAccepted;
    case 'Work order rejected':
      return l10n.workOrderRejected;
    case 'Work started':
      return l10n.workOrderStarted;
    case 'Work order completed':
      return l10n.workOrderCompletedMessage;
    case 'Work order cancelled':
      return l10n.workOrderCancelledMessage;
    case 'Technician assigned':
      return l10n.workOrderTechnicianAssigned;
    case 'Work order deleted':
      return l10n.workOrderDeleted;
    case 'Before-work details saved':
      return l10n.workOrderBeforeWorkSaved;
    case 'Progress note added':
      return l10n.workOrderProgressNoteAdded;
    case 'Progress photo uploaded':
      return l10n.workOrderProgressPhotoUploaded;
    case 'After photo uploaded':
      return l10n.workOrderAfterPhotoUploaded;
    case 'Photo removed':
      return l10n.workOrderPhotoRemoved;
    case 'Invalid email or password.':
      return l10n.errorInvalidEmail;
    case 'You do not have permission to perform this action.':
      return l10n.errorForbidden;
    case 'Server error. Please try again later.':
      return l10n.errorServer;
    case 'Request timed out. Please try again.':
      return l10n.errorRequestTimeout;
    case 'Unable to reach the server.':
      return l10n.errorUnableToReachServer;
    case 'Something went wrong. Please try again.':
      return l10n.errorGeneric;
    case 'No internet connection. Please check your network.':
      return l10n.errorNoInternet;
    case 'Request failed':
      return l10n.errorRequestFailed;
    case 'You have already clocked in today.':
      return l10n.attendanceAlreadyClockedIn;
    case 'You must clock in before clocking out.':
      return l10n.attendanceMustClockInBeforeOut;
    case 'End your current break before clocking out.':
      return l10n.attendanceEndBreakBeforeOut;
    case 'You have already clocked out today.':
      return l10n.attendanceAlreadyClockedOut;
    case 'You must clock in before starting a break.':
      return l10n.attendanceMustClockInBeforeBreak;
    case 'A break is already in progress.':
      return l10n.attendanceBreakAlreadyInProgress;
    case 'There is no active break to end.':
      return l10n.attendanceNoActiveBreak;
    case 'Photo attendance requires an internet connection on web. Please reconnect and try again.':
      return l10n.attendanceWebOfflinePhotoRequired;
    case 'Location services are disabled. Enable GPS to continue.':
      return l10n.locationServicesDisabled;
    case 'Location permission is required to clock in or out.':
      return l10n.locationPermissionRequired;
    case 'Location permission is permanently denied. Enable it from device settings.':
      return l10n.locationPermissionDeniedForever;
    case 'Could not determine your location in time. Try again.':
      return l10n.locationTimeout;
    case 'Camera is unavailable. A live photo is required.':
      return l10n.cameraUnavailable;
    case 'No active session.':
      return l10n.authNoActiveSession;
    case 'Offline Mode. Connect once to restore your profile.':
      return l10n.authOfflineRestoreProfile;
    case 'No running overtime session found to end.':
      return l10n.overtimeNoRunningSession;
    case 'QR scanning will be available in a future release.':
      return l10n.assetsQrScannerNotReady;
    case 'serverMgmtInvalidUrl':
      return l10n.serverMgmtInvalidUrl;
    case 'serverMgmtTestSuccess':
      return l10n.serverMgmtTestSuccess;
    case 'serverMgmtTestFailed':
      return l10n.serverMgmtTestFailed;
    case 'serverMgmtPingSuccess':
      return l10n.serverMgmtPingSuccess;
    case 'serverMgmtPingFailed':
      return l10n.serverMgmtPingFailed;
    case 'serverMgmtSaveSuccess':
      return l10n.serverMgmtSaveSuccess;
    case 'serverMgmtSaveFailed':
      return l10n.serverMgmtSaveFailed;
    case 'serverMgmtRestoreSuccess':
      return l10n.serverMgmtRestoreSuccess;
    case 'serverMgmtTimeout':
      return l10n.serverMgmtTimeout;
    case 'serverMgmtExportSuccess':
      return l10n.serverMgmtExportSuccess;
    case 'serverMgmtExportFailed':
      return l10n.serverMgmtExportFailed;
    case 'serverMgmtCopySuccess':
      return l10n.serverMgmtCopySuccess;
    default:
      if (_looksLikeRawEnglishSentence(key)) {
        return l10n.errorGeneric;
      }
      if (RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(key)) {
        return l10n.errorGeneric;
      }
      return key;
  }
}

bool _looksLikeRawEnglishSentence(String value) {
  if (value.contains(' ') && RegExp(r'[A-Za-z]{3,}').hasMatch(value)) {
    final lower = value.toLowerCase();
    return lower.contains(' must ') ||
        lower.contains(' required') ||
        lower.contains(' invalid') ||
        lower.contains(' failed') ||
        lower.contains(' please ') ||
        lower.contains(' not found') ||
        lower.endsWith('.');
  }
  return false;
}

/// Maps validation error keys from cubits to localized field errors.
String? localizeFieldError(AppLocalizations l10n, String? message) {
  if (message == null || message.isEmpty) {
    return null;
  }
  return localizeAppMessage(l10n, message);
}

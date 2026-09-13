/// Stable Windows toast identity for [flutter_local_notifications].
///
/// Must stay identical to:
/// - `mobile/windows/runner/windows_toast_registration.cpp`
/// - `installer.iss` shortcut `AppUserModelID`
/// - Inno `AppId` GUID (without braces) used as toast activator CLSID
///
/// Format requirements (flutter_local_notifications 22.x / windows 3.1.x):
/// - [appUserModelId]: Company.Product style, no spaces, ≤129 chars
/// - [guid]: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Display name shown on Windows toast notifications.
const String kWindowsNotificationAppName = 'INFINITY';

/// Production Application User Model ID for unpackaged Win32 toasts.
///
/// Used by Release/Profile builds and the Inno installer Start Menu shortcut.
const String kWindowsNotificationAumid = 'Com.TotalCom.Infinity';

/// Debug-only AUMID so development builds never collide with the installed app
/// Taskbar/Start Menu identity.
const String kWindowsNotificationAumidDevelopment =
    'Com.TotalCom.Infinity.Development';

/// Toast activator CLSID (matches installer `AppId` without braces).
const String kWindowsNotificationGuid = '04a35421-e8d4-4192-9ad2-abc142836211';

/// AUMID for the current Windows process (Debug → Development, else Production).
String windowsNotificationAumidForCurrentBuild() {
  if (!kIsWeb && Platform.isWindows && kDebugMode) {
    return kWindowsNotificationAumidDevelopment;
  }
  return kWindowsNotificationAumid;
}

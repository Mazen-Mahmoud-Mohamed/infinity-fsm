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

/// Display name shown on Windows toast notifications.
const String kWindowsNotificationAppName = 'INFINITY';

/// Application User Model ID for unpackaged Win32 toasts.
const String kWindowsNotificationAumid = 'Com.TotalCom.Infinity';

/// Toast activator CLSID (matches installer `AppId` without braces).
const String kWindowsNotificationGuid = '04a35421-e8d4-4192-9ad2-abc142836211';

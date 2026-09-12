#ifndef RUNNER_WINDOWS_TOAST_REGISTRATION_H_
#define RUNNER_WINDOWS_TOAST_REGISTRATION_H_

// Registers unpackaged-desktop toast identity required by
// flutter_local_notifications_windows (AUMID + Start Menu shortcut).
// Values must match mobile/lib/core/push/windows_notification_identity.dart
// and installer.iss.
void EnsureWindowsToastIdentity();

#endif  // RUNNER_WINDOWS_TOAST_REGISTRATION_H_

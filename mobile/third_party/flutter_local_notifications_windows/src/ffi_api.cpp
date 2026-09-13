#include <windows.h>  // <-- This must be the first Windows header
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Data.Xml.Dom.h>

#include <cstdio>
#include <exception>
#include <optional>
#include <string>

#include "ffi_api.h"
#include "plugin.hpp"
#include "utils.hpp"

using winrt::Windows::Data::Xml::Dom::XmlDocument;

namespace {

void LogFailure(const char* where, const winrt::hresult_error& error) {
  char buffer[256];
  std::snprintf(
    buffer, sizeof(buffer),
    "[flutter_local_notifications_windows] %s failed hr=0x%08X\n", where,
    static_cast<uint32_t>(static_cast<int32_t>(error.code()))
  );
  OutputDebugStringA(buffer);
}

void LogFailure(const char* where, const std::exception& error) {
  char buffer[512];
  std::snprintf(
    buffer, sizeof(buffer),
    "[flutter_local_notifications_windows] %s failed: %s\n", where, error.what()
  );
  OutputDebugStringA(buffer);
}

void LogFailure(const char* where) {
  char buffer[256];
  std::snprintf(
    buffer, sizeof(buffer),
    "[flutter_local_notifications_windows] %s failed: unknown exception\n",
    where
  );
  OutputDebugStringA(buffer);
}

void ResetPlugin(NativePlugin* plugin) {
  if (plugin == nullptr) return;
  plugin->isReady = false;
  plugin->notifier = std::nullopt;
  plugin->history = std::nullopt;
}

}  // namespace

bool hasPackageIdentity() {
  if (!IsWindows8OrGreater()) return false;
  uint32_t length = 0;
  int error = GetCurrentPackageFullName(&length, nullptr);
  return error != APPMODEL_ERROR_NO_PACKAGE;
}

NativePlugin* createPlugin() { return new NativePlugin(); }

void disposePlugin(NativePlugin* plugin) { delete plugin; }

bool init(
  NativePlugin* plugin, char* appName, char* aumId, char* guid, char* iconPath,
  NativeNotificationCallback callback
) {
  // WinRT / COM failures must not escape the FFI boundary. Uncaught C++
  // exceptions terminate the process (CRT abort). Return false so Dart can
  // continue without local toasts.
  // See: https://github.com/MaikuB/flutter_local_notifications/issues/2813
  if (plugin == nullptr || appName == nullptr || aumId == nullptr || guid == nullptr) {
    OutputDebugStringA(
      "[flutter_local_notifications_windows] init failed: null argument\n"
    );
    return false;
  }

  try {
    // Only treat a non-empty path as an icon. An empty string must not become
    // optional("") — that writes a blank IconUri and blanks the Taskbar icon.
    std::optional<string> icon;
    if (iconPath != nullptr && iconPath[0] != '\0') {
      icon = string(iconPath);
    }
    const auto didRegister = plugin->registerApp(aumId, appName, guid, icon, callback);
    if (!didRegister) {
      OutputDebugStringA(
        "[flutter_local_notifications_windows] init failed: registerApp returned false\n"
      );
      ResetPlugin(plugin);
      return false;
    }
    plugin->hasIdentity = hasPackageIdentity();
    plugin->aumid = winrt::to_hstring(aumId);
    plugin->notifier = plugin->hasIdentity
      ? ToastNotificationManager::CreateToastNotifier()
      : ToastNotificationManager::CreateToastNotifier(plugin->aumid);
    plugin->history = ToastNotificationManager::History();
    plugin->isReady = true;
    OutputDebugStringA(
      "[flutter_local_notifications_windows] init succeeded\n"
    );
    return true;
  } catch (winrt::hresult_error const& error) {
    LogFailure("init", error);
    ResetPlugin(plugin);
    return false;
  } catch (std::exception const& error) {
    LogFailure("init", error);
    ResetPlugin(plugin);
    return false;
  } catch (...) {
    LogFailure("init");
    ResetPlugin(plugin);
    return false;
  }
}

bool isValidXml(char* xml) {
  if (xml == nullptr) return false;
  XmlDocument doc = XmlDocument();
  try {
    doc.LoadXml(winrt::to_hstring(xml));
    return true;
  } catch (winrt::hresult_error const&) {
    return false;
  } catch (...) {
    return false;
  }
}

bool showNotification(NativePlugin* plugin, int id, char* xml, NativeStringMap bindings) {
  if (plugin == nullptr || !plugin->isReady || !plugin->notifier.has_value() || xml == nullptr) {
    return false;
  }
  try {
    XmlDocument doc;
    doc.LoadXml(winrt::to_hstring(xml));
    ToastNotification notification(doc);
    const auto data = dataFromMap(bindings);
    notification.Tag(winrt::to_hstring(id));
    notification.Data(data);
    plugin->notifier.value().Show(notification);
    return true;
  } catch (winrt::hresult_error const& error) {
    LogFailure("showNotification", error);
    return false;
  } catch (std::exception const& error) {
    LogFailure("showNotification", error);
    return false;
  } catch (...) {
    LogFailure("showNotification");
    return false;
  }
}

bool scheduleNotification(NativePlugin* plugin, int id, char* xml, int time) {
  if (plugin == nullptr || !plugin->isReady || !plugin->notifier.has_value() || xml == nullptr) {
    return false;
  }
  try {
    XmlDocument doc;
    doc.LoadXml(winrt::to_hstring(xml));
    ScheduledToastNotification notification(doc, winrt::clock::from_time_t(time));
    notification.Tag(winrt::to_hstring(id));
    plugin->notifier.value().AddToSchedule(notification);
    return true;
  } catch (winrt::hresult_error const& error) {
    LogFailure("scheduleNotification", error);
    return false;
  } catch (std::exception const& error) {
    LogFailure("scheduleNotification", error);
    return false;
  } catch (...) {
    LogFailure("scheduleNotification");
    return false;
  }
}

NativeUpdateResult updateNotification(NativePlugin* plugin, int id, NativeStringMap bindings) {
  if (plugin == nullptr || !plugin->isReady || !plugin->notifier.has_value()) {
    return NativeUpdateResult::failed;
  }
  try {
    const auto tag = winrt::to_hstring(id);
    const auto data = dataFromMap(bindings);
    const auto result = plugin->notifier.value().Update(data, tag);
    return (NativeUpdateResult) result;
  } catch (winrt::hresult_error const& error) {
    LogFailure("updateNotification", error);
    return NativeUpdateResult::failed;
  } catch (std::exception const& error) {
    LogFailure("updateNotification", error);
    return NativeUpdateResult::failed;
  } catch (...) {
    LogFailure("updateNotification");
    return NativeUpdateResult::failed;
  }
}

void cancelAll(NativePlugin* plugin) {
  if (plugin == nullptr || !plugin->isReady || !plugin->notifier.has_value()) return;
  try {
    if (plugin->history.has_value()) {
      if (plugin->hasIdentity) {
        plugin->history.value().Clear();
      } else {
        plugin->history.value().Clear(plugin->aumid);
      }
    }
    for (const auto notification : plugin->notifier.value().GetScheduledToastNotifications()) {
      plugin->notifier.value().RemoveFromSchedule(notification);
    }
  } catch (winrt::hresult_error const& error) {
    LogFailure("cancelAll", error);
  } catch (std::exception const& error) {
    LogFailure("cancelAll", error);
  } catch (...) {
    LogFailure("cancelAll");
  }
}

void cancelNotification(NativePlugin* plugin, int id) {
  if (plugin == nullptr || !plugin->isReady || !plugin->notifier.has_value()) return;
  try {
    const auto tag = winrt::to_hstring(id);
    if (plugin->hasIdentity && plugin->history.has_value()) {
      plugin->history.value().Remove(tag);
    }
    for (const auto notification : plugin->notifier.value().GetScheduledToastNotifications()) {
      if (notification.Tag() == tag) {
        plugin->notifier.value().RemoveFromSchedule(notification);
        return;
      }
    }
  } catch (winrt::hresult_error const& error) {
    LogFailure("cancelNotification", error);
  } catch (std::exception const& error) {
    LogFailure("cancelNotification", error);
  } catch (...) {
    LogFailure("cancelNotification");
  }
}

NativeNotificationDetails* getActiveNotifications(NativePlugin* plugin, int* size) {
  if (size == nullptr) return nullptr;
  *size = 0;
  if (plugin == nullptr || !plugin->isReady || !plugin->hasIdentity || !plugin->history.has_value()) {
    return nullptr;
  }
  try {
    const auto active = plugin->history.value().GetHistory();
    *size = static_cast<int>(active.Size());
    if (*size <= 0) return nullptr;
    const auto result = new NativeNotificationDetails[*size];
    int index = 0;
    for (const auto notification : active) {
      const auto tag = notification.Tag();
      const auto tagStr = winrt::to_string(tag);
      try {
        result[index++].id = std::stoi(tagStr);
      } catch (...) {
        result[index++].id = 0;
      }
    }
    return result;
  } catch (winrt::hresult_error const& error) {
    LogFailure("getActiveNotifications", error);
    *size = 0;
    return nullptr;
  } catch (std::exception const& error) {
    LogFailure("getActiveNotifications", error);
    *size = 0;
    return nullptr;
  } catch (...) {
    LogFailure("getActiveNotifications");
    *size = 0;
    return nullptr;
  }
}

NativeNotificationDetails* getPendingNotifications(NativePlugin* plugin, int* size) {
  if (size == nullptr) return nullptr;
  *size = 0;
  if (plugin == nullptr || !plugin->isReady || !plugin->notifier.has_value()) {
    return nullptr;
  }
  try {
    const auto pending = plugin->notifier.value().GetScheduledToastNotifications();
    *size = static_cast<int>(pending.Size());
    if (*size <= 0) return nullptr;
    const auto result = new NativeNotificationDetails[*size];
    int index = 0;
    for (const auto notification : pending) {
      const auto tag = notification.Tag();
      const auto tagStr = winrt::to_string(tag);
      try {
        result[index++].id = std::stoi(tagStr);
      } catch (...) {
        result[index++].id = 0;
      }
    }
    return result;
  } catch (winrt::hresult_error const& error) {
    LogFailure("getPendingNotifications", error);
    *size = 0;
    return nullptr;
  } catch (std::exception const& error) {
    LogFailure("getPendingNotifications", error);
    *size = 0;
    return nullptr;
  } catch (...) {
    LogFailure("getPendingNotifications");
    *size = 0;
    return nullptr;
  }
}

void freeDetailsArray(NativeNotificationDetails* ptr) { delete[] ptr; }

void freeLaunchDetails(NativeLaunchDetails details) {
  if (details.payload != nullptr) delete[] details.payload;
  for (int index = 0; index < details.data.size; index++) {
    const auto pair = details.data.entries[index];
    delete pair.key;
    delete pair.value;
  }
  if (details.data.entries != nullptr) delete[] details.data.entries;
}

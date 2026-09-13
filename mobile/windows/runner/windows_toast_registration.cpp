#include "windows_toast_registration.h"

#include <windows.h>

#include <propkey.h>
#include <propvarutil.h>
#include <shlobj.h>
#include <shobjidl.h>

#include <string>

namespace {

// Keep in sync with:
// - mobile/lib/core/push/windows_notification_identity.dart
// - installer.iss (AppUserModelID / toast activator GUID)
constexpr wchar_t kProductionAumid[] = L"Com.TotalCom.Infinity";
constexpr wchar_t kDevelopmentAumid[] = L"Com.TotalCom.Infinity.Development";
constexpr wchar_t kAppDisplayName[] = L"INFINITY";
constexpr wchar_t kActivatorClsid[] = L"{04a35421-e8d4-4192-9ad2-abc142836211}";
constexpr wchar_t kProductionShortcutName[] = L"INFINITY.lnk";
constexpr wchar_t kStaleDevelopmentShortcutName[] = L"INFINITY (Development).lnk";

bool GetExecutablePath(std::wstring* exe_path) {
  wchar_t buffer[MAX_PATH];
  const DWORD length =
      GetModuleFileNameW(nullptr, buffer, static_cast<DWORD>(MAX_PATH));
  if (length == 0 || length >= MAX_PATH) {
    return false;
  }
  *exe_path = buffer;
  return true;
}

bool GetStartMenuProgramsPath(std::wstring* programs_path) {
  PWSTR path = nullptr;
  const HRESULT hr = SHGetKnownFolderPath(FOLDERID_Programs, 0, nullptr, &path);
  if (FAILED(hr) || path == nullptr) {
    return false;
  }
  *programs_path = path;
  CoTaskMemFree(path);
  return true;
}

bool IsDebugBuildPath(const std::wstring& exe_path) {
  return exe_path.find(L"\\runner\\Debug\\") != std::wstring::npos;
}

bool FileExists(const std::wstring& path) {
  const DWORD attrs = GetFileAttributesW(path.c_str());
  return attrs != INVALID_FILE_ATTRIBUTES &&
         (attrs & FILE_ATTRIBUTE_DIRECTORY) == 0;
}

bool SetRegistryString(HKEY root,
                       const std::wstring& subkey,
                       const wchar_t* value_name,
                       const std::wstring& value) {
  const LSTATUS status = RegSetKeyValueW(
      root, subkey.c_str(), value_name, REG_SZ, value.c_str(),
      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  return status == ERROR_SUCCESS;
}

void DeleteEmptyIconUri(const std::wstring& aumid) {
  const std::wstring aumid_key =
      std::wstring(L"Software\\Classes\\AppUserModelId\\") + aumid;
  HKEY key = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, aumid_key.c_str(), 0,
                    KEY_QUERY_VALUE | KEY_SET_VALUE, &key) != ERROR_SUCCESS) {
    return;
  }
  DWORD type = 0;
  DWORD size = 0;
  const LSTATUS status =
      RegQueryValueExW(key, L"IconUri", nullptr, &type, nullptr, &size);
  if (status == ERROR_SUCCESS && type == REG_SZ) {
    // Empty REG_SZ is typically 2 bytes (single NUL) or a zero-length string.
    if (size <= sizeof(wchar_t)) {
      RegDeleteValueW(key, L"IconUri");
    } else {
      std::wstring value(size / sizeof(wchar_t), L'\0');
      DWORD read_size = size;
      if (RegQueryValueExW(key, L"IconUri", nullptr, &type,
                           reinterpret_cast<LPBYTE>(value.data()),
                           &read_size) == ERROR_SUCCESS) {
        // Trim embedded NULs from REG_SZ.
        const size_t end = value.find(L'\0');
        if (end != std::wstring::npos) {
          value.resize(end);
        }
        if (value.empty()) {
          RegDeleteValueW(key, L"IconUri");
        }
      }
    }
  }
  RegCloseKey(key);
}

void CleanupStaleDevelopmentShortcut() {
  std::wstring programs_path;
  if (!GetStartMenuProgramsPath(&programs_path)) {
    return;
  }
  const std::wstring stale =
      programs_path + L"\\" + kStaleDevelopmentShortcutName;
  if (FileExists(stale)) {
    DeleteFileW(stale.c_str());
  }
}

// Production identity only — never call from Debug builds (would rewrite
// LocalServer32 to a Debug path).
bool RegisterProductionToastIdentity(const std::wstring& exe_path) {
  const std::wstring clsid_key =
      std::wstring(L"Software\\Classes\\CLSID\\") + kActivatorClsid;
  const std::wstring local_server_key = clsid_key + L"\\LocalServer32";
  const std::wstring aumid_key =
      std::wstring(L"Software\\Classes\\AppUserModelId\\") + kProductionAumid;
  const std::wstring quoted_exe = L"\"" + exe_path + L"\"";

  if (!SetRegistryString(HKEY_CURRENT_USER, clsid_key, nullptr,
                         kAppDisplayName)) {
    return false;
  }
  if (!SetRegistryString(HKEY_CURRENT_USER, local_server_key, nullptr,
                         quoted_exe)) {
    return false;
  }
  if (!SetRegistryString(HKEY_CURRENT_USER, aumid_key, L"DisplayName",
                         kAppDisplayName)) {
    return false;
  }
  if (!SetRegistryString(HKEY_CURRENT_USER, aumid_key, L"CustomActivator",
                         kActivatorClsid)) {
    return false;
  }
  // Icon comes from the Start Menu shortcut / PE resource — never write empty
  // IconUri (blank Taskbar icon).
  DeleteEmptyIconUri(kProductionAumid);
  return true;
}

bool RegisterDevelopmentToastIdentity() {
  const std::wstring aumid_key =
      std::wstring(L"Software\\Classes\\AppUserModelId\\") + kDevelopmentAumid;
  if (!SetRegistryString(HKEY_CURRENT_USER, aumid_key, L"DisplayName",
                         kAppDisplayName)) {
    return false;
  }
  if (!SetRegistryString(HKEY_CURRENT_USER, aumid_key, L"CustomActivator",
                         kActivatorClsid)) {
    return false;
  }
  DeleteEmptyIconUri(kDevelopmentAumid);
  return true;
}

bool InstallProductionStartMenuShortcut(const std::wstring& exe_path) {
  if (!FileExists(exe_path)) {
    return false;
  }

  std::wstring programs_path;
  if (!GetStartMenuProgramsPath(&programs_path)) {
    return false;
  }

  const std::wstring shortcut_path =
      programs_path + L"\\" + kProductionShortcutName;

  IShellLinkW* shell_link = nullptr;
  HRESULT hr =
      CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                       IID_PPV_ARGS(&shell_link));
  if (FAILED(hr) || shell_link == nullptr) {
    return false;
  }

  hr = shell_link->SetPath(exe_path.c_str());
  if (SUCCEEDED(hr)) {
    hr = shell_link->SetArguments(L"");
  }
  if (SUCCEEDED(hr)) {
    const size_t slash = exe_path.find_last_of(L"\\/");
    if (slash != std::wstring::npos) {
      hr = shell_link->SetWorkingDirectory(exe_path.substr(0, slash).c_str());
    }
  }
  if (SUCCEEDED(hr)) {
    hr = shell_link->SetDescription(kAppDisplayName);
  }
  if (SUCCEEDED(hr)) {
    // Explicit icon from the executable (index 0) — required for reliable
    // Taskbar/Start Menu icons when AUMID is set.
    hr = shell_link->SetIconLocation(exe_path.c_str(), 0);
  }

  if (SUCCEEDED(hr)) {
    IPropertyStore* property_store = nullptr;
    hr = shell_link->QueryInterface(IID_PPV_ARGS(&property_store));
    if (SUCCEEDED(hr) && property_store != nullptr) {
      PROPVARIANT app_id_prop;
      PropVariantInit(&app_id_prop);
      hr = InitPropVariantFromString(kProductionAumid, &app_id_prop);
      if (SUCCEEDED(hr)) {
        hr = property_store->SetValue(PKEY_AppUserModel_ID, app_id_prop);
        if (SUCCEEDED(hr)) {
          hr = property_store->Commit();
        }
        PropVariantClear(&app_id_prop);
      }
      property_store->Release();
    }
  }

  if (SUCCEEDED(hr)) {
    IPersistFile* persist_file = nullptr;
    hr = shell_link->QueryInterface(IID_PPV_ARGS(&persist_file));
    if (SUCCEEDED(hr) && persist_file != nullptr) {
      hr = persist_file->Save(shortcut_path.c_str(), TRUE);
      persist_file->Release();
    }
  }

  shell_link->Release();
  return SUCCEEDED(hr);
}

void LogToastRegistration(const char* message) {
  OutputDebugStringA("[WindowsToastIdentity] ");
  OutputDebugStringA(message);
  OutputDebugStringA("\n");
}

}  // namespace

void EnsureWindowsToastIdentity() {
  // Best-effort only. Failures must never prevent app startup.
  std::wstring exe_path;
  if (!GetExecutablePath(&exe_path)) {
    LogToastRegistration("GetModuleFileNameW failed");
    return;
  }

  // Always remove the v1.2.3 stale Development shortcut that shared production
  // AUMID and could point at a missing Debug exe.
  CleanupStaleDevelopmentShortcut();
  DeleteEmptyIconUri(kProductionAumid);
  DeleteEmptyIconUri(kDevelopmentAumid);

  if (IsDebugBuildPath(exe_path)) {
    // Debug must never own production AUMID / LocalServer32 / INFINITY.lnk.
    const HRESULT aumid_hr =
        SetCurrentProcessExplicitAppUserModelID(kDevelopmentAumid);
    if (FAILED(aumid_hr)) {
      LogToastRegistration("SetCurrentProcessExplicitAppUserModelID (dev) failed");
    }
    if (!RegisterDevelopmentToastIdentity()) {
      LogToastRegistration("Development AppUserModelId registration failed");
    }
    // No Development Start Menu shortcut — avoids broken targets and AUMID
    // collisions with the installed production shortcut.
    return;
  }

  const HRESULT aumid_hr =
      SetCurrentProcessExplicitAppUserModelID(kProductionAumid);
  if (FAILED(aumid_hr)) {
    LogToastRegistration("SetCurrentProcessExplicitAppUserModelID failed");
  }

  if (!RegisterProductionToastIdentity(exe_path)) {
    LogToastRegistration("COM / AppUserModelId registry registration failed");
  }
  if (!InstallProductionStartMenuShortcut(exe_path)) {
    LogToastRegistration("Start Menu shortcut registration failed");
  }
}

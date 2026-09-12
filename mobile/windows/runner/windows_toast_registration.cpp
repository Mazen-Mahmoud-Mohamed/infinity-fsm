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
constexpr wchar_t kAumid[] = L"Com.TotalCom.Infinity";
constexpr wchar_t kAppDisplayName[] = L"INFINITY";
constexpr wchar_t kActivatorClsid[] = L"{04a35421-e8d4-4192-9ad2-abc142836211}";

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
  // Avoid overwriting the installed Start Menu shortcut when running
  // `flutter run` Debug builds from the source tree.
  const wchar_t* needle = L"\\runner\\Debug\\";
  return exe_path.find(needle) != std::wstring::npos;
}

std::wstring ShortcutFileName(const std::wstring& exe_path) {
  return IsDebugBuildPath(exe_path) ? L"INFINITY (Development).lnk"
                                      : L"INFINITY.lnk";
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

bool RegisterToastComIdentity(const std::wstring& exe_path) {
  const std::wstring clsid_key =
      std::wstring(L"Software\\Classes\\CLSID\\") + kActivatorClsid;
  const std::wstring local_server_key = clsid_key + L"\\LocalServer32";
  const std::wstring aumid_key =
      std::wstring(L"Software\\Classes\\AppUserModelId\\") + kAumid;

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
  return true;
}

bool InstallStartMenuShortcut(const std::wstring& exe_path) {
  std::wstring programs_path;
  if (!GetStartMenuProgramsPath(&programs_path)) {
    return false;
  }

  const std::wstring shortcut_path =
      programs_path + L"\\" + ShortcutFileName(exe_path);

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
    IPropertyStore* property_store = nullptr;
    hr = shell_link->QueryInterface(IID_PPV_ARGS(&property_store));
    if (SUCCEEDED(hr) && property_store != nullptr) {
      PROPVARIANT app_id_prop;
      PropVariantInit(&app_id_prop);
      hr = InitPropVariantFromString(kAumid, &app_id_prop);
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
  const HRESULT aumid_hr = SetCurrentProcessExplicitAppUserModelID(kAumid);
  if (FAILED(aumid_hr)) {
    LogToastRegistration("SetCurrentProcessExplicitAppUserModelID failed");
  }

  std::wstring exe_path;
  if (!GetExecutablePath(&exe_path)) {
    LogToastRegistration("GetModuleFileNameW failed");
    return;
  }

  if (!RegisterToastComIdentity(exe_path)) {
    LogToastRegistration("COM / AppUserModelId registry registration failed");
  }
  if (!InstallStartMenuShortcut(exe_path)) {
    LogToastRegistration("Start Menu shortcut registration failed");
  }
}

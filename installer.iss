; INFINITY FSM Windows installer (Inno Setup)
; Local builds: compile from repo root with defaults below.
; CI builds: pass /DMyAppVersion=1.0.2 /DOutputBaseFilename=INFINITY-Setup-1.0.2 /DRepoRoot=.

#ifndef RepoRoot
#define RepoRoot "."
#endif

#ifndef MyAppVersion
#define MyAppVersion "1.0.0"
#endif

#ifndef OutputBaseFilename
#define OutputBaseFilename "INFINITY-Setup-1.0.0"
#endif

#ifndef OutputDir
#define OutputDir "dist\releases"
#endif

#ifndef WindowsReleaseDir
#define WindowsReleaseDir RepoRoot + "\mobile\build\windows\x64\runner\Release"
#endif

#ifndef SetupIconFile
#define SetupIconFile RepoRoot + "\assets\INFINITY_icon.ico"
#endif

#define MyAppName "INFINITY"
#define MyAppPublisher "Mazen Mahmoud"
#define MyAppURL "https://github.com/Mazen-Mahmoud-Mohamed/infinity-fsm"
#define MyAppExeName "mobile.exe"

[Setup]
AppId={{04A35421-E8D4-4192-9AD2-ABC142836211}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\INFINITY FSM
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseFilename}
SetupIconFile={#SetupIconFile}
SolidCompression=yes
WizardStyle=modern dynamic

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#WindowsReleaseDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WindowsReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

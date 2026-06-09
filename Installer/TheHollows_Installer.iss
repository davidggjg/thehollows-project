; ═══════════════════════════════════════════════════════════════════════
;  TheHollows_Installer.iss  —  Inno Setup 6.x
;  1. Extract your build ZIP into SourceDir
;  2. Open in Inno Setup Compiler → Ctrl+F9 to compile
; ═══════════════════════════════════════════════════════════════════════

#define AppName      "The Hollows"
#define AppVersion   "1.0.0"
#define AppPublisher "YourStudioName"
#define AppURL       "https://yourstudio.itch.io/the-hollows"
#define AppExeName   "TheHollows.exe"
#define SourceDir    "C:\Build\TheHollows-StandaloneWindows64"
#define OutputDir    "C:\Installer\Output"

[Setup]
AppId={{A3F2C8D1-9B4E-4F7A-B2D6-5E8C1F3A0D94}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=TheHollows_v{#AppVersion}_Setup
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern
Uninstallable=yes
UninstallDisplayIcon={app}\{#AppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon";   Description: "Create a Desktop shortcut";    GroupDescription: "Shortcuts:"; Flags: checked
Name: "startmenuicon"; Description: "Create a Start Menu shortcut"; GroupDescription: "Shortcuts:"; Flags: checked

[Files]
Source: "{#SourceDir}\{#AppExeName}";           DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\TheHollows_Data\*";       DestDir: "{app}\TheHollows_Data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#SourceDir}\UnityPlayer.dll";         DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\GameAssembly.dll";        DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\UnityCrashHandler64.exe"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{autodesktop}\{#AppName}";                           Filename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{autostartmenu}\{#AppName}\{#AppName}";              Filename: "{app}\{#AppExeName}"; Tasks: startmenuicon
Name: "{autostartmenu}\{#AppName}\Uninstall {#AppName}";    Filename: "{uninstallexe}";      Tasks: startmenuicon

[Registry]
Root: HKCU; Subkey: "Software\{#AppPublisher}\{#AppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName} now"; Flags: nowait postinstall skipifsilent

[Messages]
WelcomeLabel2=This will install [name/ver] on your computer.%n%nNo internet connection required. All progress saves locally.%n%nClick Next to continue.
FinishedHeadingLabel=Installation complete.
FinishedLabel=The Hollows has been installed. The darkness awaits.

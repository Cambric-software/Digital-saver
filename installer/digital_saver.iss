; Digital Saver - Windows installer.
;
; Installs a versioned layout so the app can update itself later without ever
; overwriting files Windows has open:
;
;   %LOCALAPPDATA%\Programs\DigitalSaver\
;     current.txt                    the active version
;     versions\0.1.1\digital_saver.exe, flutter_windows.dll, data\
;
; The shortcut points at the version this installer shipped, not at "whatever
; is newest". When an update lands, that older copy starts first, notices
; current.txt names a newer version, hands over and exits. That is the
; mechanism that stops a stale shortcut trapping someone on an old build.
;
; Per-user install (PrivilegesRequired=lowest), so applying an update never
; needs administrator rights.

#ifndef AppVersion
  #define AppVersion "0.1.1"
#endif
#ifndef AppExeName
  #define AppExeName "digital_saver.exe"
#endif

#define AppPublisher "Cambric Software"
#define AppName "Digital Saver"
; A plain AppId is enough for upgrade detection and avoids escaped-brace GUID
; syntax, which is easy to get subtly wrong.
#define AppId "CambricDigitalSaver"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
; Must be strictly numeric. The release workflow normalises the tag before
; passing it in, because Inno rejects a pre-release suffix here.
VersionInfoVersion={#AppVersion}.0
DefaultDirName={localappdata}\Programs\DigitalSaver
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=..\release-out
OutputBaseFilename=DigitalSaver-Setup-{#AppVersion}
UninstallDisplayName={#AppName} {#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
; The Start Menu entry is created unconditionally; the desktop shortcut is
; optional, because plenty of users do not want one.
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
; The payload is staged by CI as ..\staging, already shaped as the version dir.
Source: "..\staging\*"; DestDir: "{app}\versions\{#AppVersion}"; Flags: ignoreversion recursesubdirs createallsubdirs
; The pointer that decides which version runs.
Source: "..\staging-current.txt"; DestDir: "{app}"; Flags: ignoreversion

[Dirs]
Name: "{app}\versions"

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\versions\{#AppVersion}\{#AppExeName}"; WorkingDir: "{app}\versions\{#AppVersion}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\versions\{#AppVersion}\{#AppExeName}"; WorkingDir: "{app}\versions\{#AppVersion}"; Tasks: desktopicon

[Run]
Filename: "{app}\versions\{#AppVersion}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[Code]
// Remove version folders left behind by updates.
//
// The folder this installer created is already tracked and removed by Inno's
// own file handling. Anything else under versions/ is a leftover from an
// update. Uninstalling means removing the whole application, so there is no
// reason to preserve the active version - keeping it would leave a broken copy
// that nothing can launch.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  VersionsDir: String;
  Found: TFindRec;
  EntryName: String;
begin
  if CurUninstallStep = usUninstall then
  begin
    VersionsDir := ExpandConstant('{app}\versions');
    if DirExists(VersionsDir) then
    begin
      if FindFirst(VersionsDir + '\*', Found) then
      try
        repeat
          EntryName := Found.Name;
          if (Found.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
          begin
            if (CompareText(EntryName, '..') <> 0) and (EntryName <> '.') and
               (CompareText(EntryName, '{#AppVersion}') <> 0) then
              DelTree(VersionsDir + '\' + EntryName, True, True, True);
          end;
        until not FindNext(Found);
      finally
        FindClose(Found);
      end;
    end;
  end;
end;
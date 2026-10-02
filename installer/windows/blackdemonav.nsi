; BlackDemon AV - premium Windows installer (NSIS / Modern UI 2).
; Build:  makensis BlackDemon AV.nsi   ->  BlackDemonAV-Setup.exe
; Stage the real Windows binaries into payload/ (blackdemon.exe, blackdemon-desktop.exe)
; and the engine data into payload/assets/ before building a release.

Unicode true
SetCompressor /SOLID lzma

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

!define APPNAME      "BlackDemon AV"
!define COMPANY      "BlackDemon AV"
!ifndef VERSION
  !define VERSION    "2026.1.0"   ; overridden by build.ps1 via /DVERSION=<tag>
!endif
!define DESKBIN      "blackdemon-desktop.exe"
!define CLIBIN       "blackdemon.exe"
; The desktop GUI is bundled only when build.ps1 passes /DWITH_GUI (i.e. the
; Tauri app compiled). Otherwise this is a CLI-only install and app shortcuts
; point at the scanner. Either way the engine + real-time protection install.
!ifdef WITH_GUI
  !define APPTARGET  "${DESKBIN}"
!else
  !define APPTARGET  "${CLIBIN}"
!endif
!define RTTASK       "BlackDemon AV Real-Time Protection"
!define UNINSTKEY    "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"

; Absolute source dir (installer/windows), passed by build.ps1 as /DSRCDIR so
; File/bitmap paths resolve regardless of makensis' working directory (Windows
; NSIS resolves them against the CWD, which differs from Linux). Defaults to "."
; so a manual `makensis` run from this folder still works.
!ifndef SRCDIR
  !define SRCDIR "."
!endif

Name "${APPNAME} ${VERSION}"
OutFile "${SRCDIR}\BlackDemonAV-Setup.exe"
InstallDir "$PROGRAMFILES64\${APPNAME}"
InstallDirRegKey HKLM "Software\${APPNAME}" "InstallDir"
RequestExecutionLevel admin

; ---- Branding ----
!define MUI_ICON   "${SRCDIR}\assets\BlackDemonAV.ico"
!define MUI_UNICON "${SRCDIR}\assets\BlackDemonAV.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${SRCDIR}\assets\header.bmp"
!define MUI_HEADERIMAGE_RIGHT
!define MUI_WELCOMEFINISHPAGE_BITMAP "${SRCDIR}\assets\welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${SRCDIR}\assets\welcome.bmp"
!define MUI_ABORTWARNING

; ---- Welcome text ----
!define MUI_WELCOMEPAGE_TITLE "Welcome to the ${APPNAME} Setup"
!define MUI_WELCOMEPAGE_TEXT "This wizard will install ${APPNAME} ${VERSION} - the open-source antivirus with on-device AI, behavioral defense, a threat-intelligence firewall and tamper-proof updates.$\r$\n$\r$\nClose other applications before continuing, then click Next."

; ---- Finish page: offer to launch (GUI only) ----
!ifdef WITH_GUI
  !define MUI_FINISHPAGE_RUN "$INSTDIR\${DESKBIN}"
  !define MUI_FINISHPAGE_RUN_TEXT "Launch ${APPNAME} now"
!endif
!define MUI_FINISHPAGE_LINK "Visit the BlackDemon AV project"
!define MUI_FINISHPAGE_LINK_LOCATION "https://github.com/Blackdemon200/BlackDemon-Anti-Virus"

; ---- Pages ----
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${SRCDIR}\..\LICENSE_EULA.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

; =====================================================================
; Sections (components)
; =====================================================================

Section "BlackDemon AV core engine + app" SEC_CORE
  SectionIn RO
  SetOutPath "$INSTDIR"
!ifdef WITH_GUI
  File "${SRCDIR}\payload\${DESKBIN}"
!endif
  File "${SRCDIR}\payload\${CLIBIN}"
  File "${SRCDIR}\assets\BlackDemonAV.ico"
  ; Bundle runtime DLLs (VCRUNTIME140.dll, MSVCP140.dll, etc.)
  File /nonfatal "${SRCDIR}\payload\*.dll"
  SetOutPath "$INSTDIR\assets"
  File /r "${SRCDIR}\payload\assets\*.*"

  ; Registry: install info + Add/Remove Programs entry.
  WriteRegStr HKLM "Software\${APPNAME}" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "Software\${APPNAME}" "Version" "${VERSION}"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayName"     "${APPNAME}"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayVersion"  "${VERSION}"
  WriteRegStr HKLM "${UNINSTKEY}" "Publisher"       "${COMPANY}"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayIcon"     "$INSTDIR\BlackDemonAV.ico"
  WriteRegStr HKLM "${UNINSTKEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "${UNINSTKEY}" "InstallLocation" "$INSTDIR"
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoRepair" 1
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Command-line scanner (add to PATH)" SEC_CLI
  ; blackdemon.exe is already installed by core; add the folder to the system PATH.
  Push "$INSTDIR"
  Call AddToPath
SectionEnd

Section "Real-Time Protection (background)" SEC_RT
  ; Auto-start the on-access watcher at logon (scans + quarantines new/changed
  ; files in high-risk folders). Highest privileges so it can quarantine.
  nsExec::ExecToLog 'schtasks /create /tn "${RTTASK}" /tr "\"$INSTDIR\${CLIBIN}\" watch \"%USERPROFILE%\Downloads\" --quarantine \"%LOCALAPPDATA%\BlackDemonAV\quarantine\"" /sc onlogon /rl highest /f'
  ; Best-effort: stop Microsoft Defender from double-scanning our quarantine.
  nsExec::ExecToLog 'powershell -NoProfile -Command "Add-MpPreference -ExclusionPath $\'$INSTDIR$\' -ErrorAction SilentlyContinue"'
SectionEnd

Section "Start Menu shortcuts" SEC_SM
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortCut  "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\${APPTARGET}" "" "$INSTDIR\BlackDemonAV.ico"
  CreateShortCut  "$SMPROGRAMS\${APPNAME}\Uninstall ${APPNAME}.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Desktop shortcut" SEC_DESK
  CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${APPTARGET}" "" "$INSTDIR\BlackDemonAV.ico"
SectionEnd

Section "Explorer right-click: Scan with BlackDemon AV" SEC_CTX
  WriteRegStr HKCR "*\shell\BlackDemonAV" "" "Scan with BlackDemon AV"
  WriteRegStr HKCR "*\shell\BlackDemonAV" "Icon" "$INSTDIR\BlackDemonAV.ico"
  WriteRegStr HKCR "*\shell\BlackDemonAV\command" "" '"$INSTDIR\${CLIBIN}" scan "%1"'
SectionEnd

; ---- Component descriptions ----
LangString DESC_CORE ${LANG_ENGLISH} "The BlackDemon AV detection engine, on-device AI model and desktop app. Required."
LangString DESC_CLI  ${LANG_ENGLISH} "Add the 'blackdemon' command-line scanner to your system PATH."
LangString DESC_RT   ${LANG_ENGLISH} "Real-time, on-access protection running in the background from logon (recommended)."
LangString DESC_SM   ${LANG_ENGLISH} "Create Start Menu shortcuts."
LangString DESC_DESK ${LANG_ENGLISH} "Create a desktop shortcut."
LangString DESC_CTX  ${LANG_ENGLISH} "Add a 'Scan with BlackDemon AV' entry to the file right-click menu."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CORE} $(DESC_CORE)
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CLI}  $(DESC_CLI)
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_RT}   $(DESC_RT)
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_SM}   $(DESC_SM)
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_DESK} $(DESC_DESK)
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CTX}  $(DESC_CTX)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; =====================================================================
; Uninstaller
; =====================================================================
Section "Uninstall"
  nsExec::ExecToLog 'schtasks /delete /tn "${RTTASK}" /f'
  Push "$INSTDIR"
  Call un.RemoveFromPath

  Delete "$DESKTOP\${APPNAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APPNAME}"
  DeleteRegKey HKCR "*\shell\BlackDemonAV"

  RMDir /r "$INSTDIR\assets"
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\${DESKBIN}"
  Delete "$INSTDIR\${CLIBIN}"
  Delete "$INSTDIR\BlackDemonAV.ico"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"

  DeleteRegKey HKLM "${UNINSTKEY}"
  DeleteRegKey HKLM "Software\${APPNAME}"
SectionEnd

; =====================================================================
; PATH helpers (system PATH via registry + broadcast change)
; =====================================================================
!define ENV_HKLM 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'

Function AddToPath
  Exch $0          ; dir to add
  Push $1
  ReadRegStr $1 ${ENV_HKLM} "Path"
  ; Only append if not already present.
  Push $1
  Push "$0"
  Call StrContains
  Pop $2
  ${If} $2 == ""
    ${If} $1 == ""
      WriteRegExpandStr ${ENV_HKLM} "Path" "$0"
    ${Else}
      WriteRegExpandStr ${ENV_HKLM} "Path" "$1;$0"
    ${EndIf}
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=3000
  ${EndIf}
  Pop $1
  Pop $0
FunctionEnd

Function un.RemoveFromPath
  Exch $0
  Push $1
  ReadRegStr $1 ${ENV_HKLM} "Path"
  Push $1
  Push ";$0"
  Call un.StrReplace
  Pop $1
  WriteRegExpandStr ${ENV_HKLM} "Path" "$1"
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=3000
  Pop $1
  Pop $0
FunctionEnd

; Returns the needle in $R0 (or "" if not found) - simple substring check.
Function StrContains
  Exch $R1 ; needle
  Exch
  Exch $R2 ; haystack
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  StrCpy $R0 ""
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 "" done
    StrCmp $R5 $R1 found
    IntOp $R4 $R4 + 1
    Goto loop
  found:
    StrCpy $R0 $R1
  done:
    Pop $R5
    Pop $R4
    Pop $R3
    Pop $R2
    Pop $R1
    Exch $R0
FunctionEnd

; Minimal string replace used to strip our dir from PATH on uninstall.
Function un.StrReplace
  Exch $R1 ; substring to remove
  Exch
  Exch $R2 ; string
  Push $R3
  Push $R4
  Push $R5
  Push $R6
  StrLen $R3 $R1
  StrCpy $R4 0
  StrCpy $R6 ""
  rloop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 "" rdone
    StrCmp $R5 $R1 rskip
    StrCpy $R5 $R2 1 $R4
    StrCpy $R6 "$R6$R5"
    IntOp $R4 $R4 + 1
    Goto rloop
  rskip:
    IntOp $R4 $R4 + $R3
    Goto rloop
  rdone:
    StrCpy $R0 $R6
    Pop $R6
    Pop $R5
    Pop $R4
    Pop $R3
    Pop $R2
    Pop $R1
    Exch $R0
FunctionEnd



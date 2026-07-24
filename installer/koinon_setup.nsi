; ==============================================================================
; Koinon Standalone LLM Omni-Server - Modern NSIS Windows Installer Script
; Produces standard Windows GUI setup executable: Koinon_OmniServer_Setup_v0.1.0.exe
; ==============================================================================

!define PRODUCT_NAME "Koinon Omni-Server"
!define PRODUCT_VERSION "0.1.0"
!define PRODUCT_PUBLISHER "Koinon Project Team"
!define PRODUCT_WEB_SITE "http://localhost:8080/"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\koinon-server.bat"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

SetCompressor /SOLID lzma

; Modern UI
!include "MUI2.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Welcome page
!insertmacro MUI_PAGE_WELCOME
; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!define MUI_FINISHPAGE_RUN "$INSTDIR\koinon-server.bat"
!define MUI_FINISHPAGE_RUN_TEXT "Launch Koinon Omni-Server Now"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "../dist/Koinon_OmniServer_Setup_v0.1.0.exe"
InstallDir "$LOCALAPPDATA\Koinon"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer

  ; Include all package files
  File /r "..\dist\koinon-windows-v0.1.0\*"

  ; Create Desktop & Start Menu Shortcuts
  CreateDirectory "$SMPROGRAMS\Koinon Omni-Server"
  CreateShortCut "$SMPROGRAMS\Koinon Omni-Server\Koinon Omni-Server.lnk" "$INSTDIR\koinon-server.bat" "" "" 0
  CreateShortCut "$SMPROGRAMS\Koinon Omni-Server\Uninstall.lnk" "$INSTDIR\uninst.exe" "" "" 0
  CreateShortCut "$DESKTOP\Koinon Omni-Server.lnk" "$INSTDIR\koinon-server.bat" "" "" 0
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\koinon-server.bat"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_OK|MB_ICONINFORMATION "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  Delete "$DESKTOP\Koinon Omni-Server.lnk"
  Delete "$SMPROGRAMS\Koinon Omni-Server\*.lnk"
  RMDir "$SMPROGRAMS\Koinon Omni-Server"

  RMDir /r "$INSTDIR\web"
  RMDir /r "$INSTDIR\models"
  RMDir /r "$INSTDIR\doc"
  Delete "$INSTDIR\*"

  RMDir "$INSTDIR"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd

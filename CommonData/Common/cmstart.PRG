LPARAMETER cOption, uParam
*++
* CodeMine Developer Menu support code.
*
* This program displays and executes the CodeMine Developer Menu items.
* It is implemented as a traditional prodecure file rather than as a class
* library so that it will not be affected by CLEAR ALL commands.
*
* Copyright 1996-2003 Soft Classics, Ltd. All Rights Reserved Worldwide.
*--
#include 'codemine.h'

  * If called with no parameter, add the CodeMine menu pad to the main menu.
  m.cOption = IIF(EMPTY(m.cOption), 'Startup', m.cOption)

  * Store talk setting in screen comment property temporarily, since all memvars 
  * may be lost during possible CLEAR ALL
  _SCREEN.AddProperty('cSavedTalkSetting', SET('TALK'))
  SET TALK OFF

  * Dispatch to the function passed in as our parameter.
  IF PCOUNT() >= 2
    DO &cOption WITH m.uParam
  ELSE
    DO &cOption
  ENDIF

  IF _SCREEN.cSavedTalkSetting == 'ON'
    SET TALK ON
  ENDIF
  RETURN .T.


FUNCTION About
*++
* Display the Codemine About dialog box.
*--
LOCAL oDialog
  * Load the API library so the About dialog can access registration information
  IF LoadAPILibrary()
    m.oDialog = CREATEOBJECT('frmAboutCodemine')
    IF VARTYPE(m.oDialog) = 'O'
      m.oDialog.Show()
    ENDIF
  ENDIF
ENDFUNC


FUNCTION ShowHelp
*++
* Display the Codemine HTML Help file.
*--
LOCAL cHelpFile, nHWND

  DECLARE Integer FindWindow in Win32Api String, String

  m.nHWND = FindWindow(0, 'CodeMine Application Framework 7.1')
  IF m.nHWND > 0
    DECLARE Integer IsIconic in Win32APi Integer
    DECLARE BringWindowToTop in Win32APi Integer
    DECLARE ShowWindow in Win32Api Integer, Integer

    BringWindowToTop(m.nHWND)
    IF NOT EMPTY(IsIconic(m.nHWND))
      ShowWindow(m.nHWND, 1)
    ENDIF
  ELSE
    DECLARE INTEGER ShellExecute IN Shell32.DLL ;
  	      INTEGER nWinHandle, STRING cOperation, STRING cFileName, STRING cParameters,;
  	      STRING cDirectory, INTEGER nShowWindow
    m.cHelpFile = _SCREEN.cCodeMineRootPath + 'CodeMine71.chm'
    IF FILE(m.cHelpFile)
      ShellExecute(_vfp.hWnd, 'Open', m.cHelpFile, '', '', 1)
    ELSE
      MESSAGEBOX('Help file ' + m.cHelpFile + ' was not found', 64, 'CodeMine')
    ENDIF
  ENDIF
  RETURN .T.
ENDFUNC


FUNCTION Shutdown
*++
* Called as the shutdown handler while the development environment is active.
*--
  IF TYPE('_SCREEN.Activeform.Baseclass') = 'C' AND _SCREEN.Activeform.WindowType != 0
    WAIT WINDOW NOWAIT 'Please close the "' + _SCREEN.Activeform.Caption + '" dialog before quitting VFP'
    RETURN .F.
  ENDIF
  ClearEnvironment()
  QUIT
ENDFUNC


FUNCTION StartBuilder
*++
* Start the control builder for the currently selected control(s)
*--
LOCAL aSelected[1]
  IF ASELOBJ(aSelected) > 0 OR ASELOBJ(aSelected, 1) > 0
    DO (_BUILDER) WITH aSelected[1], 'RTMOUSE'
  ENDIF
ENDFUNC


FUNCTION SuperclassParameters
*++
* Insert parameters statement into current editing window
*--
  IF NOT PEMSTATUS(_SCREEN, 'cmDevSuperclassCode', 5)
    _SCREEN.NewObject('cmDevSuperclassCode', 'cmDevSuperclassCode', _SCREEN.cCodemineCommonPath + 'cmDevEnv.vcx')
  ENDIF
  _SCREEN.cmDevSuperclassCode.InsertParameters()
ENDFUNC

FUNCTION SuperclassDoDefault(lReturn)
*++
* Insert parameters statement into current editing window
*--
  IF NOT PEMSTATUS(_SCREEN, 'cmDevSuperclassCode', 5)
    _SCREEN.NewObject('cmDevSuperclassCode', 'cmDevSuperclassCode', _SCREEN.cCodemineCommonPath + 'cmDevEnv.vcx')
  ENDIF
  _SCREEN.cmDevSuperclassCode.InsertDoDefault(m.lReturn)
ENDFUNC

FUNCTION ViewSuperclass()
*++
* View parent class (superclass) code for the method currently being edited.
*--
  LoadAPILibrary()   && Load API library for window size save/restor from sys registry
  IF NOT PEMSTATUS(_SCREEN, 'cmDevSuperclassCode', 5)
    _SCREEN.NewObject('cmDevSuperclassCode', 'cmDevSuperclassCode', _SCREEN.cCodemineCommonPath + 'cmDevEnv.vcx')
  ENDIF
  _SCREEN.cmDevSuperclassCode.ViewSuperclass()
ENDFUNC

FUNCTION SuperclassSavePos()
*++
* Save superclass window size & position
*--
  IF PEMSTATUS(_SCREEN, 'cmDevSuperclassCode', 5)
    LoadAPILibrary()   && Load API library for window size save/restor from sys registry
    _SCREEN.cmDevSuperclassCode.SavePosition()
  ENDIF
ENDFUNC


FUNCTION DumpDataEnvironment
*++
* Dump data environmnet from a form to a PRG file.
*--
LOCAL oDialog

  IF LoadAPILibrary()
    m.oDialog = CreateLocalized('frmExtractDataEnvironment')
    IF VARTYPE(m.oDialog) = 'O'
      m.oDialog.Show()
    ENDIF
  ENDIF
ENDFUNC


FUNCTION CopyClass
*++
* Copy a class definition
*--
LOCAL oDialog

  IF LoadAPILibrary()
    m.oDialog = CreateLocalized('frmCopyClass')
    IF VARTYPE(m.oDialog) = 'O'
      m.oDialog.Show()
    ENDIF
  ENDIF
ENDFUNC


FUNCTION NewForm
*++
* Create a new form (.scx) from the specified base class
*--
LOCAL oDialog

  IF LoadAPILibrary()
    m.oDialog = CreateLocalized('frmNewForm')
    IF VARTYPE(m.oDialog) = 'O'
      m.oDialog.Show()
    ENDIF
  ENDIF
ENDFUNC


FUNCTION NewCDE
*++
* Create a new CDE class.
*--
LOCAL cFolder
  m.cFolder = FULLPATH('') + 'Source\'
  IF NOT DIRECTORY(m.cFolder)
    m.cFolder = ''
  ENDIF
  CREATE CLASS ? OF (m.cFolder + 'appData.vcx') ;
                 AS cmDataEnvironmentCustom FROM (_SCREEN.cCodemineRootPath + '\Custom\cData.vcx') NOWAIT
ENDFUNC


FUNCTION Setup
*++
* View/Modify development environment.
*--
LOCAL oDialog

  IF LoadAPILibrary()
    m.oDialog = CREATEOBJECT('frmSetupEnvironment')
    IF VARTYPE(m.oDialog) = 'O'
      m.oDialog.Show()
    ENDIF
  ENDIF
ENDFUNC


FUNCTION NewApplication
*++
* Create a new application folder.
*--
LOCAL oDialog

  ClearEnvironment(.T.)
  CLOSE ALL
  IF LoadAPILibrary()
    m.oDialog = CREATEOBJECT('frmCreateApplication')
    IF VARTYPE(m.oDialog) = 'O'
      m.oDialog.Show()
      IF VARTYPE(m.oDialog) = 'O' AND m.oDialog.ReturnValue()
        PrepareForBuild()
      ENDIF
    ENDIF
  ENDIF
ENDFUNC


FUNCTION ModifyApplication
*++
* Add/Remove optional components in the current application
*--
LOCAL oDialog, lEnvLoaded

  * Make sure an application is open, or at least an app folder is selected.
  SET DATASESSION TO  1
  m.lEnvLoaded = EnvironmentOK()
  IF NOT m.lEnvLoaded AND (NOT LoadAPILibrary() OR NOT InitEnvironment(.T.))
    RETURN .F.
  ENDIF

  m.oDialog = CREATEOBJECT('frmModifyApplication', _SCREEN.cCodemineRootPath)
  IF VARTYPE(m.oDialog) = 'O'
    m.oDialog.Show()
    IF VARTYPE(m.oDialog) = 'O'
      m.lStatus = m.oDialog.ReturnValue()
      IF ISNULL(m.lStatus)   && If user cancelled
        * If env wasnt running when started, clear it on cancel
        IF NOT m.lEnvLoaded
          ClearEnvironment(.T.)
        ENDIF
      ELSE
        IF m.lStatus
          ResetEnvironment()
        ELSE
          ClearEnvironment(.T.)  && Make sure everything is cleared, for a clean rebuild.
        ENDIF
      ENDIF
    ENDIF
  ENDIF
ENDFUNC


FUNCTION Zipcodes
*++
* Display the zipcode and areacode lookup utility
*--
  * Load the API library so the About dialog can access registration information
  IF LoadAPILibrary() AND FILE(_SCREEN.cCodemineCommonPath + 'ziptool.scx')
    PUBLIC goZipCodeUtilityForm
    IF TYPE('m.goZipCodeUtilityForm') == 'O' AND NOT ISNULL(m.goZipCodeUtilityForm)
      m.goZipCodeUtilityForm.Show()
    ELSE
      DO FORM (_SCREEN.cCodemineCommonPath + 'ziptool.scx') NAME goZipCodeUtilityForm
    ENDIF
  ENDIF
ENDFUNC


FUNCTION RegistryTools
*++
* Pack/Update registry tables for the application in the default directory.
*--
LOCAL oDialog

  * Make sure an application is open, or at least an app folder is selected.
  IF NOT EnvironmentOK() ;
  AND (NOT LoadAPILibrary() OR NOT InitEnvironment())
    RETURN .F.
  ENDIF

  m.oDialog = CREATEOBJECT('frmRegistryTools')
  IF VARTYPE(m.oDialog) = 'O'
    m.oDialog.Show()
    RETURN .T.
  ENDIF
  RETURN .F.
ENDFUNC


FUNCTION SqlScript
*++
* Generate INSERT commands script for SQL Server table data.
*--
  LOCAL oDialog
  IF NOT EnvironmentOK() AND NOT ResetEnvironment()
    RETURN .F.
  ENDIF

  m.oDialog = CREATEOBJECT('frmsqlscriptdata')
  IF VARTYPE(m.oDialog) = 'O'
    m.oDialog.Show()
    RETURN .T.
  ENDIF
  RETURN .F.
ENDFUNC


FUNCTION UpsizeRegistry
*++
* Create necessary server tables, SP, and remote views for remote appreg01 table.
*--
  IF EnvironmentOK() OR LoadAPILibrary()
    LOCAL oDialog
    m.oDialog = CREATEOBJECT('frmUpsizeRegistry')
    IF VARTYPE(m.oDialog) = 'O'
      m.oDialog.Show()
      RETURN .T.
    ENDIF
  ENDIF
  RETURN .F.
ENDFUNC


FUNCTION ConvertPrgToVcx
*++
* Convert a PRG class definition to VCX format
*--
  DO ClearAll
  IF LoadAPILibrary()
    LOCAL oDialog
    m.oDialog = CreateLocalized('frmconvertprgtovcx')
    IF VARTYPE(m.oDialog) = 'O'
      m.oDialog.Show()
    ENDIF
  ENDIF
ENDFUNC


FUNCTION OpenApplication(lNoPrompt)
*++
* Set default to existing application folder, and open the project file.
*
* Use the lNoPrompt parameter to use the curent default folder, without prompting user to select one.
*--
  LOCAL cProject

  * Make sure the current default directory contains registry tables,
  * and is in the correct relative position to the common codemine files.
  IF NOT m.lNoPrompt AND NOT SelectAppDirectory()
    RETURN .F.
  ENDIF

  ClearEnvironment(.T.)    && Clear quietly
  IF LoadAPILibrary() AND InitEnvironment()
    IF PEMSTATUS(m.goApp, 'appSettings', 5)
      m.cProject = LOWER(JUSTSTEM(m.goApp.appSettings.cProject))
      IF EMPTY(m.cProject)
        MESSAGEBOX('The cProject property of appApplicationSettings in appMain.vcx is empty, so no project file will be opened.', 48, 'CodeMine')
      ELSE
        TRY 
          MODIFY PROJECT (m.cProject) NOWAIT
        CATCH TO oError
          MESSAGEBOX('The cProject file "' + m.cProject + '" could not be opened - ' + m.oError.Message, 48, 'CodeMine')
        ENDTRY
      ENDIF

      * Release appSettings object so it can be modified in class designer while DevEnv is running.
      m.goApp.RemoveObject('appSettings')
    ENDIF
  ENDIF
ENDFUNC

FUNCTION ResetEnvironment()
*++
* Clear any existing objects and re-initialize the development environment.
*--
set
SET STEP on
  ClearEnvironment(.T.)    && Clear quietly
  IF LoadAPILibrary() AND InitEnvironment()
    * Release appSettings object so it can be modified in class designer while DevEnv is running.
    m.goApp.RemoveObject('appSettings')
    RETURN .T.
  ENDIF
  RETURN .F.
ENDFUNC

FUNCTION PrepareForBuild()
*++
* Clean up environment so project will build cleanly, and update 
*--
  ClearEnvironment(.T.)

  * Do a partial reinitialization to ensure that the appApplicationSettings class is up-to-date.
  IF LoadAPILibrary()
    InitEnvironment(.T.)
  ENDIF
  ClearEnvironment(.t.)    && Clear everything for a clean project build
  WAIT WINDOW NOWAIT 'Project Scan Complete. Ready to build application.'
ENDFUNC

FUNCTION ClearEnvironment(lClearAll)
LOCAL ix, oTemp, aCont[1]

  SET DATASESSION TO  1
  FOR ix = _SCREEN.FormCount TO 1 STEP -1
    IF TYPE('_SCREEN.Forms[m.ix].Baseclass') = 'C'
      * Dont release forms in a formset - which includes all form designer and class designer windows.
      m.oTemp = _SCREEN.Forms[m.ix]
      IF TYPE('m.oTemp.Parent.Name') = 'U'
        IF PEMSTATUS(m.oTemp, 'Release', 5)
          m.oTemp.Release()
        ENDIF
      ENDIF
    ENDIF
  ENDFOR

  IF 'CODEMINE.' $ SET('PROCEDURE')
    ReleaseGlobalObject()  && Clean shutdown of all global objects
  ENDIF

  * Look for any "Stuck" objects, usually CDE or cursors that have outstanding cross-links.
  IF AINSTANCE(aCont, 'Container') > 0
    ACTIVATE SCREEN
    ?'Could not release these objects:'
    FOR ix = 1 TO ALEN(aCont)
      ?' ', aCont[ix].name
    ENDFOR
    m.lClearAll = .F.
  ENDIF

  IF m.lClearAll
    ON ERROR DO ClearError
    CLEAR ALL
    ON ERROR
  ENDIF

  SET LIBRARY TO
  SET CLASSLIB TO
  SET PROCEDURE TO
  CLOSE DATA ALL

  CLEAR PROG
  POP KEY ALL
  SET SYSMENU TO DEFAULT
  SET SYSMENU AUTO
  ON SHUTDOWN

  * Display the standard VFP toolbar, if it exists.
  IF WEXIST('Standard')
    SHOW WINDOW Standard
  ENDIF
ENDFUNC


FUNCTION ClearAll
  ClearEnvironment(.T.)
  WAIT WINDOW NOWAIT 'Environment Cleared'
ENDFUNC


FUNCTION ClearError
*++
* Handle errors from CLEAR ALL command.
* Usually means a method in an object has been SUSPENDed
*--
  ON ERROR
  MESSAGEBOX('Unable to CLEAR ALL objects - Try "Clear Everything" again', 16, 'CodeMine Development Environment')
  CANCEL
ENDFUNC

FUNCTION LoadAPILibrary
*++
* Load Codemine API library and development environment and support class libraries.
*--
  * Declare necessary Windows API functions.
  DECLARE INTEGER GetSysColor IN user32.dll INTEGER nColorValue

  IF NOT 'CODEMINE.FLL' $ SET('LIBRARY') ;
  OR NOT 'CODEMINE.' $ SET('PROCEDURE') ;
  OR NOT 'CMDEVENV.VCX' $ SET('CLASSLIB')
    LOCAL cPath

    * Find and load the Codemine API library file
    SET PATH TO
    SET LIBRARY TO (_SCREEN.cCodemineCommonPath + 'Codemine.fll') ADDITIVE

    * Load and store the optional developer-supplied path folders to add to our default search path.
    cmRegGetValue(HKEY_LOCAL_MACHINE, SYSREG_CODEMINE_ROOT + '\Custom Paths', @m.cPath)
    _SCREEN.cCodemineDeveloperPath = IIF(EMPTY(m.cPath), '', m.cPath)

    * Set preliminary path to include Codemine library and graphics directories.
    m.cPath = _SCREEN.cCodemineCommonPath + ',' ;
            + _SCREEN.cCodemineRootPath + 'Custom\' + ',' ;
            + _SCREEN.cCodemineRootPath + 'Graphics\'
    IF NOT EMPTY(_SCREEN.cCodemineDeveloperPath)
      m.cPath = m.cPath + ',' + _SCREEN.cCodemineDeveloperPath
    ENDIF
    SET PATH TO &cPath

    * Make sure we are running with the correct versions of VFP and API library.
    IF NOT CheckVersion()
      RETURN .F.
    ENDIF

    * Load development env and core codemine class libraries
    SET PROCEDURE TO (_SCREEN.cCodemineCommonPath + 'codemine') ADDITIVE   && Utilities, and global object manager

    SET CLASSLIB TO (_SCREEN.cCodemineCommonPath + 'cmForms') ADDITIVE     && Needed for CtxMenu manager
    SET CLASSLIB TO (_SCREEN.cCodemineCommonPath + 'cmData') ADDITIVE      && Control Data Binding 
    SET CLASSLIB TO (_SCREEN.cCodemineCommonPath + 'cmDevenv') ADDITIVE    && Dev Env classes
    SET CLASSLIB TO (_SCREEN.cCodemineCommonPath + 'cmInspect') ADDITIVE   && Object Inspector
  ENDIF
  RETURN .T.
ENDFUNC


FUNCTION SelectAppDirectory(cPath)
*++
* Make sure the current default directory is in the correct relative position 
* to the application registry files.
*--
  SET COMPATIBLE OFF   && Make sure no DB4 settings alter default behavoir

  IF EMPTY(m.cPath)
    WAIT WINDOW NOWAIT NOCLEAR 'Select existing application folder'
  ENDIF

  DO WHILE EMPTY(m.cPath) ;
  OR (NOT FILE('datafiles\appreg02.dbf') AND NOT FILE('data\appreg02.dbf')) OR NOT FILE('source\appdefs.h') 
    IF NOT EMPTY(m.cPath)
      WAIT WINDOW NOWAIT NOCLEAR '"' + m.cPath + '" is not a CodeMine application development folder'
    ENDIF

    m.cPath = GETDIR('', 'Select Application Folder', 'Open CodeMine Application')
    WAIT CLEAR
    IF EMPTY(m.cPath)
      RETURN .F.
    ENDIF
    CD (m.cPath)
  ENDDO
  RETURN .T.
ENDFUNC


FUNCTION InitEnvironment(lRegistryOnly)
*++
* Initialize the full development environment. Before calling, the API library must be loaded
* and the current default directory should be set to the application development directory.
*
* The lRegistryOnly parameter is used to stop dev env startup after creating the app registry obejct.
* This is done for some developer utilities, such as the add/remove app components dialog.
*--
  LOCAL cPath, cProject, oRegistry, oAppSettings, lScanStatus, nValue
  PUBLIC goApp   && Public reference to app object for menus, etc...

  IF NOT SelectAppDirectory(FULLPATH(''))
    RETURN .F.
  ENDIF

  * Default to Asserts ON for development environment.
  SET ASSERT ON

  * Release any pre-existing global objects, and app level classlibs which may be open from another app folder.
  ReleaseGlobalObject()
  IF 'ALIAS APPMAIN ' $ SET('CLASSLIB') + ' '
    RELEASE CLASSLIB AppMain
  ENDIF
  IF 'ALIAS APPFORMS ' $ SET('CLASSLIB') + ' '
    RELEASE CLASSLIB AppForms
  ENDIF

  IF NOT m.lRegistryOnly
    WAIT WINDOW NOWAIT NOCLEAR 'Codemine Development Environment Initializing in ' + LOWER(FULLPATH('')) + ' ...'
  ENDIF

  * Save the app root path so it can be restored next time VFP starts if user enables this option.
  cmRegSetString(HKEY_LOCAL_MACHINE, SYSREG_CODEMINE_ROOT + '\Last App', LOWER(FULLPATH('')))

  * Load app registry editor library for development environment, even if not in project
  * Note that cmDevEnv.vcx will already be in the list before we get called.
  * AppMain needs to be loaded in order to create application object.
  SET CLASSLIB TO source\AppMain, cmRegEdt ADDITIVE

  * At this point, default directory is the app folder, and path includes Codemine common and data folders.
  * We are now ready to create the application object, which is responsible for most of the remaining setup.
  m.goApp = CreateGlobalObject('appApplication')
  IF VARTYPE(m.goApp) != 'O'
    RETURN .F.
  ENDIF

  WITH m.goApp
    * Set development environment search path for this app.
    .SetDevSearchPath()

    * These class libraries must always be part of all client applications.
    .LoadCoreLibraries()

    * Create the application and registry manager service object and load all the class
    * and procedure libraries that are part of the current project. Need to do this early
    * to pick out class library lists from 6.1 apps, and copy them to appSettings object.
    m.oRegistry = CreateGlobalObject('cmRegistry',, .cMainDBC, .cLocalRegistry, .cSharedRegistry)

    * Rebuild library lists and other project settings as appropriate, and store in appApplicationSettings class.
    * An instance of this class will be added to application object when LoadLibraries() is called.
    m.oAppSettings = NEWOBJECT('cmApplicationSettingsManager', 'cmDevEnv.vcx')
    m.lScanStatus = m.oAppSettings.ScanProject()
    m.oAppSettings.Release()

    IF NOT m.lRegistryOnly
      * Load the necessary application-specific class and procedure libraries. 
      IF NOT .LoadLibraries()
        RETURN .F.   && Should never happen
      ENDIF

      * Create core and optional global service objects, and any custom states & actions.
      IF NOT .CreateGlobalObjects()
        MESSAGEBOX("One or more of the Application's Global Service Objects failed to start.", 48, 'CodeMine Development Environment')

        * We can try to continue as long as these minimal service object were successful.
        IF ISNULL(FindGlobalObject('cmRegistry')) ;
        OR ISNULL(FindGlobalObject('cmStateManager'))
          RETURN .F.
        ENDIF
      ENDIF

      * Create custom application states & actions
      .CreateStates()

      * If security is loaded, enable developer mode by default.
      IF NOT ISNULL(.oSecurity)
        .oSecurity.EnableDeveloperMode()
      ENDIF

      * Put up the application toolbars.
      .lToolbarMemory = .F.   && Dont remember toolbar state in dev env
      .CloseFoxToolbars()

      * Strip out tbrLaunchPad from toolbar list if requested in CodeMine Setup dialog option.
      IF cmRegGetValue(HKEY_LOCAL_MACHINE, SYSREG_CODEMINE_ROOT + '\Show Toolbars', @m.nValue) ;
      AND m.nValue = 0
        .cToolbars = STRTRAN(LOWER(.cToolbars) + ',', 'tbrlaunchpad,', ',')
      ENDIF
      .OpenAppToolbars()

      * Put up the developer toolbars, using the custom subclass specified in the appSettings object.
      SET CLASSLIB TO (_SCREEN.cCodemineRootPath + 'custom\cDevEnv') ADDITIVE
      IF NOT EMPTY(.appSettings.cDeveloperToolbarClass)
        .oStateManager.OpenToolbar(.appSettings.cDeveloperToolbarClass)
      ENDIF

      m.cProject = TRIM(.appSettings.cProject)
      WAIT WINDOW NOWAIT 'Codemine Development Environment Initialized in "' + LOWER(SET('DEFAULT') + CURDIR()) + '"' ;
                     + CR_LF + 'Project file: ' + IIF(EMPTY(m.cProject), '<none>', PROPER(m.cProject)) ;
                     + IIF(m.lScanStatus, '', CR_LF + 'Unable to update appApplicationSettings because appMain.vcx is Read-Only')
    ENDIF
  
    * Establish dev env shutdown handler
    m.cPath = ["] + Thispath() + ["] 
    ON SHUTDOWN DO &cPath WITH 'Shutdown'

    * Run global and application-specific development environment setup program
    m.cPath = _SCREEN.cCodemineRootPath + 'custom\devSetup.prg'
    IF FILE(m.cPath)
      DO (m.cPath)
    ENDIF
    m.cPath = SYS(5) + CURDIR() + 'devSetup.prg'
    IF FILE(m.cPath)
      DO (m.cPath)
    ENDIF
  ENDWITH
  RETURN .T.
ENDFUNC


FUNCTION EnvironmentOK
*++
* Determine if the full development environment is setup, and reasonably intact.
*--
  IF PEMSTATUS(_SCREEN, 'cmGlobalObjectManager', 5)
    RETURN TYPE('m.goStateManager.Name') = 'C' ;
           AND 'CODEMINE.' $ SET('PROCEDURE') ;
           AND NOT ISNULL(FindGlobalObject('cmRegistry')) ;
           AND NOT ISNULL(FindGlobalObject('appApplication'))
  ENDIF
  RETURN .F.
ENDFUNC


FUNCTION RegistryEditor
* Open registry editor
  IF NOT EnvironmentOK() AND NOT ResetEnvironment()
    RETURN .F.
  ENDIF
  IF NOT ISNULL(FindGlobalObject('cmRegistry'))
    m.goStateManager.OpenForm('frmRegistryEditor')
  ENDIF
ENDFUNC


FUNCTION UserEditor
* Open user account editor form.
  IF NOT EnvironmentOK() AND NOT ResetEnvironment()
    RETURN .F.
  ENDIF
  IF 'CMSECURE.VCX' $ SET('CLASSLIB')
    m.goStateManager.OpenForm('frmAccountEditor')
  ELSE
    MESSAGEBOX('Security System Component is not included in this application', 'CodeMine')
  ENDIF
ENDFUNC


FUNCTION ViewEvents
* Display event log viewer form.
  IF NOT EnvironmentOK() AND NOT ResetEnvironment()
    RETURN .F.
  ENDIF
  IF 'CMSECURE.VCX' $ SET('CLASSLIB')
    m.goStateManager.OpenForm('frmEventViewer')
  ELSE
    MESSAGEBOX('Security System Component is not included in this application', 'CodeMine')
  ENDIF
ENDFUNC


FUNCTION Inspector
*++
* Open object inspector
*--
  IF NOT LoadAPILibrary()
    RETURN .F.
  ENDIF

  * If Codemine Dev Env is not running, we create a standalone copy of the state manager 
  * service object, which is necessary to trap mouse clicks. This allows use of the Inspector
  * in non-CodeMine apps, as long as CodeMine is installed.
  IF ISNULL(FindGlobalObject('cmStateManager'))
    * String tools library is used by InspectorDetails() method of state manager.
    SET CLASSLIB TO (_SCREEN.cCodemineCommonPath + 'cmState') ADDITIVE
    SET CLASSLIB TO (_SCREEN.cCodemineCommonPath + 'cmRegKey') ADDITIVE
    CreateGlobalObject('cmStateManager')
  ENDIF
  m.goStateManager.OpenForm('cmInspect.frmObjectInspector')
ENDFUNC


FUNCTION ShowAppToolbar
*++
* Open and display the application toolbars, when the dev env is running.
*--
  IF TYPE('m.goApp.Name') = 'C'
    m.goApp.lToolbarMemory = .F.   && Dont remember toolbar state in dev env
    m.goApp.CloseAppToolbars()
    m.goApp.OpenAppToolbars()
  ENDIF
ENDFUNC


FUNCTION LoadCodemineMenu
*++
* Put up the Codemine menu. Called on VFP startup.
*--
PRIVATE ALL LIKE c*
LOCAL cThisPath, cLanguage, cDefault

  m.cDefault = FULLPATH('')
  CD (_SCREEN.cCodemineRootPath)

  * Set menu language to one of "English", "French", or "German".
  * This only affects the developer menu pad options.
  IF NOT cmRegGetValue(HKEY_LOCAL_MACHINE, SYSREG_CODEMINE_ROOT + '\Default Language', @m.cLanguage)
    m.cLanguage = ''
  ENDIF

  * Define English developer menu item text strings. Any left unchanged 
  * by language-specific code will remain in English.
  m.cCodemineMessage = "Control the CodeMine Development System"
  m.cABOUTPROMPT = "About CodeMine..."
  m.cABOUTMESSAGE = 'Displays version and copyright information about CodeMine'
  m.cHelpPrompt = "CodeMine Help..."
  m.cHelpMessage = "Open the CodeMine HTML Help file"
  m.cNEWAPPPROMPT = "Create \<New Application..."
  m.cNEWAPPMESSAGE = 'Creates a new CodeMine application and project file in a new folder'
  m.cOPENAPPPROMPT = "\<Open Existing Application..."
  m.cOPENAPPMESSAGE = 'Open an existing CodeMine application and its project'
  m.cModifyAppPrompt = "\<Add/Remove Application Components..."
  m.cModifyAppMessage = 'Add or Remove optional components in the current application'
  m.cPrepProjectPrompt = '\<Prepare Project for Rebuild'
  m.cPrepProjectMessage = 'Scan project file to rebuild appApplicationSettings class, and clear environemnt so all files in project can be recompiled'
  m.cNEWFORMPROMPT = "Create New \<Form..."
  m.cNEWFORMMESSAGE = 'Create a new form based on any available form class'
  m.cNewCdePrompt = "Create New CDE..."
  m.cNewCdeMessage = 'Create a new CDE based business object.'
  m.cREGEDITPROMPT = "Application \<Registry Editor..."
  m.cREGEDITMESSAGE = 'Edit Security, Message, and configuration data stored in the application registry'
  m.cUSEREDITPROMPT = "\<User Accounts Editor..."
  m.cUSEREDITMESSAGE = 'Edit user account definitions'
  m.cEVENTLOGPROMPT = "\<View Event Log..."
  m.cEVENTLOGMESSAGE = 'Views the CodeMine Security System event log'
  m.cINITPROMPT = "Initialize Development \<Environment"
  m.cINITMESSAGE = 'Initializes a development environment for testing and debugging your forms'
  m.cCLEARPROMPT = "\<Clear Everything"
  m.cCLEARMESSAGE = 'Release all objects, close all libraries and data files, and reset VFP to its original state'
  m.cTOOLSPROMPT = "CodeMine \<Developer Tools"
  m.cTOOLSMESSAGE = 'CodeMine Object Inspector and other developer tools'
  m.cINSPECTORPROMPT = " Object \<Inspector..."
  m.cINSPECTORMESSAGE = 'Run the CodeMine Object Inspector for viewing and editing object properties'
  m.cPARENTCODEPROMPT = " View Parent Class Code"
  m.cPARENTCODEMESSAGE = 'View the parent class (superclass) method code of the method currently being edited.'
  m.cPARAMSPROMPT = " Insert Method Parameters"
  m.cPARAMSMESSAGE = 'Insert required LPARAMETER statement for a custom method from the parent class.'
  m.cPACKPROMPT = " Application Registry Utilities..."
  m.cPACKMESSAGE = 'Pack or Update the application registry tables for the current application.'
  m.cUpsizePrompt = " Upsize Application Registry to Remote Server..."
  m.cUpsizeMessage = 'Create a remote data server copy of the AppReg01 table, and the remote view to access it.'
  m.cSqlScriptPrompt = " Script SQL Server Data..."
  m.cSqlScriptMessage = 'Generate INSERT commands script for SQL Server table data.'
  m.cEXTRACTPROMPT = " Export Form Data Environment..."
  m.cEXTRACTMESSAGE = 'Export DataEnvironment definition from an SCX based form and save it as a class definition'
  m.cPRGTOVCXPROMPT = " Convert PRG based class to VCX..."
  m.cPRGTOVCXMESSAGE = "Convert class definitions from PRG format to a VCX file format using Tom Retig's PrgToVcx utility"
  m.cZIPPROMPT = " Zip/Area Code Lookup..."
  m.cZIPMESSAGE = 'Open the optional USA Zip Code and Area Code lookup utility.'
  m.cSetupPrompt = ' CodeMine Setup...'
  m.cSetupMessage = 'CodeMine setup and configuration options.'
  m.cCopyClassPrompt = ' Copy Class Definition...'
  m.cCopyClassMessage = 'Copy a class definition from an existing class to a new class.'
  m.cBuilderPrompt = ' Class Builder...'
  m.cBuilderMessage = 'Opens the buidler for the currently selected object in a form or class designer window.'
  m.cSuperPrompt = 'Superclass Utility'
  m.cSuperMessage = 'View method code from parent classes, when a Form or Class Designer method editing window is active.'
  m.cDoDefaultPrompt = ' Insert DODEFAULT() statement'
  m.cDodefaultMessage = 'Inserts a DODEFAULT() statement using the parameter list defined in the parent class'
  m.cRetDoDefaultPrompt = ' Insert RETURN DODEFAULT()'
  m.cRetDodefaultMessage = 'Inserts a RETURN DODEFAULT() statement using the parameter list defined in the parent class'
  m.cSaveSuperPrompt = ' Save Superclass Window Position'
  m.cSaveSuperMessage = 'Saves the current size and position of the superclass code viewing window'

  DO CASE
    CASE m.cLanguage == 'Francais'
      m.cCODEMINEMESSAGE = "Contrôle Système de développement CodeMine"
      m.cABOUTPROMPT = "\<A propos de CodeMine..."
      m.cABOUTMESSAGE = "Affiche la version et les informations de droits d'auteurs de CodeMine"
      m.cNEWAPPPROMPT = "Créer une nouvelle \<Application..."
      m.cNEWAPPMESSAGE = 'Creates a new CodeMine application and project file in a new folder'
      m.cOPENAPPPROMPT = "\<Ouvrir une Application..."
      m.cOPENAPPMESSAGE = "Ouvrir une application CodeMine et son projet"
      m.cModifyAppPrompt = "Ajout/Suppression de Composants..."
      m.cModifyAppMessage = "Ajout ou Suppression de composants optionnels de l'application en cours"
      m.cNEWFORMPROMPT = "Créer une \<Fenêtre..."
      m.cNEWFORMMESSAGE = "Crée une nouvelle fenêtre basée sur une n'importe quelle classe de fenêtres disponible"
      m.cREGEDITPROMPT = "Editeur de \<Registre d'Application"
      m.cREGEDITMESSAGE = "Maintenance : Sécurité, Messages, configuration des données stockées dans le Registre de l'application" 
      m.cUSEREDITPROMPT = "Editeur de comptes \<Utilisateur..."
      m.cUSEREDITMESSAGE = "Maintenance des définitions de comptes utilisateurs"
      m.cEVENTLOGPROMPT = "\<Afficher le Mouchard..."
      m.cEVENTLOGMESSAGE = "Affiche le journal des évènements de CodeMine"
      m.cINITPROMPT = "Initialiser l'environnement de Développement"
      m.cINITMESSAGE = "Initialise un environnement de développement pour  tester et débogger des fenêtres"
      m.cCLEARPROMPT = "Faire le ménage"
      m.cCLEARMESSAGE = "Supprimer tous les objets, fermer les fichiers et ramener VFP à son état normal"
      m.cTOOLSPROMPT = "\<Outils du Développeur CodeMine"
      m.cTOOLSMESSAGE = "Inspecteur d'objets et autres outils de développement CodeMine"
      m.cINSPECTORPROMPT = " \<Inspecteur d'Objets..."
      m.cINSPECTORMESSAGE = "Lancer l'inspecteur d'objets  CodeMine à fin de d'afficher et permettre l' édition  des propriétés des objets"
      m.cPARENTCODEPROMPT = " Visualiser le Code de la Classe Parente"
      m.cPARENTCODEMESSAGE = "Affiche la méthode de la classe parente de même nom que celle en cours"
      m.cPARAMSPROMPT = " Insérer Paramètres de la Méthode"
      m.cPARAMSMESSAGE = "Insérer les instructions LPARAMETER à partir de la même méthode de  la classe parente"
      m.cPACKPROMPT = " Utilitaires du registre d'application..."
      m.cPACKMESSAGE = "Comprimer les tables du  registre de l'application en cours"
      m.cEXTRACTPROMPT = " Extraire l'Environnement de données de la Fenêtre..."
      m.cEXTRACTMESSAGE = "Extraire les définitions de l'environnement de donnée dune fenêtre au format SCX et la sauvegarder au format VCX"
      m.cPRGTOVCXPROMPT = " Convertir une Classe PRG en VCX..."
      m.cPRGTOVCXMESSAGE = "Convertir une définition de classe du format PRG au format VCX à l'aide de l'utilitaire PrgToVcx de Tom Retig"
      m.cSetupPrompt = ' CodeMine Setup...'
      m.cSetupMessage = ''
      m.cZIPPROMPT = ''
      m.cZIPMESSAGE = ''
      m.cBuilderPrompt = ' Class Builder...'
      m.cBuilderMessage = 'Opens the buidler for the currently selected object in a form or class designer window.'

    CASE m.cLanguage == 'Deutsch'
      * German developer menu item text strings.
      m.cCODEMINEMESSAGE = 'Steuert das CodeMine Entwicklungssystem.'
      m.cABOUTPROMPT = "\<Über CodeMine"
      m.cABOUTMESSAGE = 'Zeigt Version und Copyright Information von CodeMine.'
      m.cNEWAPPPROMPT = "\<Neue Anwendung erstellen..."
      m.cNEWAPPMESSAGE = 'Creates a new CodeMine application and project file in a new folder'
      m.cOPENAPPPROMPT = "\<Öffne bestehende Anwendung..."
      m.cOPENAPPMESSAGE = 'Öffnen einer bestehenden CodeMine Anwendung und ihres Projekts.'
      m.cModifyAppPrompt = "\<Hinzufuegen/Entfernen von Anwendungskomponenten..."
      m.cModifyAppMessage = 'Fuegt optionale Komponenten der Anwendung hinzu oder entferntdiese'
      m.cNEWFORMPROMPT = "Erzeuge neues \<Formular..."
      m.cNEWFORMMESSAGE = 'Erzeugt ein neues Formular auf der Basis einer beliebigen verfügbaren Formularklasse.'
      m.cREGEDITPROMPT = "Anwendungs-\<Registry-Editor..."
      m.cREGEDITMESSAGE = 'Bearbeiten der in der Anwendungsregistry hinterlegten Sicherheits-, Meldungs- und Konfigurationsdaten.'
      m.cUSEREDITPROMPT = "\<Benutzer Editor..."
      m.cUSEREDITMESSAGE = 'Bearbeiten der User Account Definitionen.'
      m.cEVENTLOGPROMPT = "Betrachte Ereignis-Log..."
      m.cEVENTLOGMESSAGE = 'Betrachtet das CodeMine Sicherheitssystem Event Log.'
      m.cINITPROMPT = "\<Initialisiere Entwicklungsumgebung"
      m.cINITMESSAGE = 'Initialisiert eine Entwicklungsumgebung für den Formulartest und -Debug.'
      m.cCLEARPROMPT = "\<Alles freigeben"
      m.cCLEARMESSAGE = 'Entfernt alle Objekte, schließt alle Dateien und setzt VFP in den Originalzustand zurück.'
      m.cTOOLSPROMPT = "CodeMine Entwickler-\<Tools"
      m.cTOOLSMESSAGE = 'CodeMine Objektinspektor und andere Entwicklertools'
      m.cINSPECTORPROMPT = " Objekt-Inspektor..."
      m.cINSPECTORMESSAGE = 'Betrachten und bearbeiten Sie Objekteigenschaften mit dem CodeMine Objektinspektor.'
      m.cPARENTCODEPROMPT = " Zeige Elternklassen-Code"
      m.cPARENTCODEMESSAGE = 'Betrachten Sie den Elternklassen- (Superklassen-) Methodencode der momentan bearbeiteten Methode.'
      m.cPARAMSPROMPT = " Methodenparameter einfügen"
      m.cPARAMSMESSAGE = 'Fügen Sie das erforderliche LPARAMETER Statement aus der Elternklasse für eine Custom Methode ein.'
      m.cPACKPROMPT = " Anwendungs-Registry packen..."
      m.cPACKMESSAGE = 'Packen Sie die Tabellen des Anwendungsregisters für die laufende Anwendung.'
      m.cEXTRACTPROMPT = " Formulardaten-Umgebung extrahieren..."
      m.cEXTRACTMESSAGE = 'Extrahieren Sie die DataEnvironment Definition aus einem SCX-Formular und speichern Sie diese als Klassendefinition.'
      m.cPRGTOVCXPROMPT = " PRG-basierende Klassen in VCX umwandeln..."
      m.cPRGTOVCXMESSAGE = "Konvertiert Klassendefinitionen vom PRG-Format in das VCX-Dateiformat mittels des Tools PrgToVcx  von Tom Rettig."
      m.cSetupPrompt = ' CodeMine Setup...'
      m.cSetupMessage = ''
      m.cZIPPROMPT = ""
      m.cZIPMESSAGE = ""
      m.cBuilderPrompt = ' Class Builder...'
      m.cBuilderMessage = 'Opens the buidler for the currently selected object in a form or class designer window.'

    CASE m.cLanguage == 'Espanol'
      * Spanish developer menu item text strings.
      m.cCodemineMessage = 'Controla el sistema de desarrollo CodeMine'
      m.cABOUTPROMPT = "\<Acerca de CodeMine..."
      m.cABOUTMESSAGE = 'Muestra información de versión y copyright acerca de CodeMine'
      m.cNEWAPPPROMPT = "Crear \<nueva aplicación..."
      m.cNEWAPPMESSAGE = 'Crea una nueva aplicación CodeMine y su archivo de proyecto en una nueva carpeta'
      m.cOPENAPPPROMPT = "A\<brir aplicación existente..."
      m.cOPENAPPMESSAGE = 'Abre una aplicación CodeMine existente y su archivo de proyecto'
      m.cModifyAppPrompt = "A\<gregar/Remover componentes de la aplicación..."
      m.cModifyAppMessage = 'Agrega o remueve componentes opcionales en la aplicación actual'
      m.cNEWFORMPROMPT = "Crear nuevo \<formulario..."
      m.cNEWFORMMESSAGE = 'Crea un nuevo formulario basado en cualquier clase de formulario disponible'
      m.cREGEDITPROMPT = "Editor del \<registro de la aplicación..."
      m.cREGEDITMESSAGE = 'Edita datos de seguridad, mensajes y configuración guardados en el registro de la aplicación'
      m.cUSEREDITPROMPT = "Editor de cuentas de \<usuario..."
      m.cUSEREDITMESSAGE = 'Edita las definiciones de cuentas de usuario'
      m.cEVENTLOGPROMPT = "\<Ver Bitácora de eventos..."
      m.cEVENTLOGMESSAGE = 'Abre el visor de la Bitácora de eventos del sistema de seguridad de CodeMine'
      m.cINITPROMPT = "Iniciar el entorno de d\<esarrollo"
      m.cINITMESSAGE = 'Inicia un entorno de desarrollo para prueba y depuración de sus formularios'
      m.cCLEARPROMPT = "\<Limpiar todo"
      m.cCLEARMESSAGE = 'Remueve todos los objetos, cierra todos los archivos, y restaura VFP a su estado original'
      m.cTOOLSPROMPT = "\<Herramientas de desarrollo CodeMine"
      m.cTOOLSMESSAGE = 'CodeMine Object Inspector y otras herramientas de desarrollo'
      m.cINSPECTORPROMPT = " Object \<Inspector..."
      m.cINSPECTORMESSAGE = 'Ejecuta el inspector de objetos de CodeMine para ver y editar propiedades de objetos'
      m.cPARENTCODEPROMPT = " \<Ver código de clase padre"
      m.cPARENTCODEMESSAGE = 'Muestra el código de método de la clase padre (superclass) del método actualmente en edición'
      m.cPARAMSPROMPT = " Insertar \<parámetros del método"
      m.cPARAMSMESSAGE = 'Inserta las declaraciones LPARAMETER necesarias para un método personalizado a partir de la clase padre'
      m.cPACKPROMPT = " Utilidades del \<registro de la aplicación..."
      m.cPACKMESSAGE = 'Empaqueta o actualiza las tablas del registro de la aplicación para la aplicación actual'
      m.cEXTRACTPROMPT = " Extraer entorno de \<datos del formulario..."
      m.cEXTRACTMESSAGE = 'Extrae la definición del objeto DataEnvironment de un formulario SCX y lo guarda como una definición de clase'
      m.cPRGTOVCXPROMPT = " \<Convertir clase basada en PRG a VCX..."
      m.cPRGTOVCXMESSAGE = 'Convierte una definición de clase guardada en un PRG a un archivo VCX usando la utilidad PrgToVcx de Tom Retig'
      m.cZIPPROMPT = " \<Búsqueda de Código Postal y Área..."
      m.cZIPMESSAGE = 'Abre la utilidad opcional de búsqueda de Código Postales y códigos de Area de EE.UU.'
      m.cSetupPrompt = " Configuración de CodeMine..."
      m.cSetupMessage = 'Permite cambiar la configuración del entorno de dasorrollo CodeMine'
      m.cBuilderPrompt = ' Class Builder...'
      m.cBuilderMessage = 'Opens the buidler for the currently selected object in a form or class designer window.'

    CASE m.cLanguage == 'Portugues'
      * Spanish developer menu item text strings.
      m.cCodemineMessage = "Controla o Sistema de Desenvolvimento CodeMine"
      m.cABOUTPROMPT = "Sobre CodeMine..."
      m.cABOUTMESSAGE = 'Mostra informação de versão e copyright sobre CodeMine'
      m.cNEWAPPPROMPT = "Criar uma \<Nova Aplicação..."
      m.cNEWAPPMESSAGE = 'Cria uma nova aplicação CodeMine e um arquivo de projeto numa nova pasta'
      m.cOPENAPPPROMPT = "A\<brir uma Aplicação Existente..."
      m.cOPENAPPMESSAGE = 'Abre uma aplicação CodeMine existente e seu projeto'
      m.cModifyAppPrompt = "\<Adicionar/Remover Componentes da Aplicação ..."
      m.cModifyAppMessage = 'Adiciona ou Remove componentes opcionais da aplicação corrente'
      m.cPrepProjectPrompt = '\<Preparar Projeto para Reconstrução'
      m.cPrepProjectMessage = 'Pesquisa o arquivo do projeto reconstruir a classe appApplicationSettings, e limpa "environemnt" para que todos os arquivos no projeto possam ser recompilados'
      m.cNEWFORMPROMPT = "Criar Novo \<Formulário..."
      m.cNEWFORMMESSAGE = 'Cria um novo formulário baseado em qualquer classe disponível'
      m.cNewCdePrompt = "Criar Novo CDE..."
      m.cNewCdeMessage = 'Cria um novo CDE baseado em objeto de negócios.'
      m.cREGEDITPROMPT = "Editor do \<Registro da Aplicação..."
      m.cREGEDITMESSAGE = 'Edita dados de Securança, Mensagens, e dados de configuração armazenados no Registro da aplicação'
      m.cUSEREDITPROMPT = "Editor de Contas de \<Usuário..."
      m.cUSEREDITMESSAGE = 'Edita definições de conta de Usuário'
      m.cEVENTLOGPROMPT = "\<Ver Registro de Eventos..."
      m.cEVENTLOGMESSAGE = 'Vê o registro de eventos do Sistema de Segurança CodeMine'
      m.cINITPROMPT = "Inicializar o Ambiente de D\<esenvolvimento"
      m.cINITMESSAGE = 'Inicializa o ambiente de desenvolvimento para testar e depurar seus formulários'
      m.cCLEARPROMPT = "\<Limpar Tudo"
      m.cCLEARMESSAGE = 'Libera todos os objetos, fecha todas a bibliotecas e arquivos de dados, e reinicializa VFP ao seus estado original'
      m.cTOOLSPROMPT = "Ferramentas de \<Desenvoledor CodeMine"
      m.cTOOLSMESSAGE = 'Inspetor de Objetos CodeMine e outras ferramentas de desenvolvedor'
      m.cINSPECTORPROMPT = " \<Inspector de Objetos..."
      m.cINSPECTORMESSAGE = 'Executa o Inspetor de Objetos CodeMine para ver e editar propriedades de objetos'
      m.cPARENTCODEPROMPT = ' Ver Código de "Parent Class Code"'
      m.cPARENTCODEMESSAGE = 'Vê os códigos de métodos da "parent class (superclass)" do método editado correntemente.'
      m.cPARAMSPROMPT = " Inserir Parâmetros de Método"
      m.cPARAMSMESSAGE = 'Insere palavra requerida LPARAMETER para um método customizado da "parent class".'
      m.cPACKPROMPT = " Utilitários do Registro da Aplicação..."
      m.cPACKMESSAGE = '"Pack" ou Atualiza as tabelas do registro da aplicação para a aplicação corrente.'
      m.cUpsizePrompt = ' "Upsize" o Registro da Aplicação para um Servidor Remoto...'
      m.cUpsizeMessage = 'Cria uma cópia de dados no servidor remoto da tabela AppReg01, e uma "view" remota para acessá-la.'
      m.cEXTRACTPROMPT = " Exportar Amiente de Dados do Formulário..."
      m.cEXTRACTMESSAGE = 'Exporta definições do "DataEnvironment" de um formulário baseado em SCX e salva como uma definição de classe'
      m.cPRGTOVCXPROMPT = " Converter classe baseada em PRG para VCX..."
      m.cPRGTOVCXMESSAGE = "Converte definições de classe de um formato PRG para arquivo do formato VCX usando o utilitário PrgToVcx de Tom Retig"
      m.cZIPPROMPT = " Procura de Código de Zip/Area..."
      m.cZIPMESSAGE = 'Abre o utilitário opcional "USA Zip Code and Area Code lookup".'
      m.cSetupPrompt = ' Configuração do CodeMine...'
      m.cSetupMessage = 'Opções de configuração do CodeMine.'
      m.cCopyClassPrompt = ' Copiar Definição de Classe...'
      m.cCopyClassMessage = 'Copia a definição de classe de uma classe existente para uma nova classe.'
      m.cBuilderPrompt = ' Construtor de Classe...'
      m.cBuilderMessage = 'Abre o contrutor para o objeto selecionado correntemente numa janela de desenho de formulário ou classe.'
      m.cSuperPrompt = 'Utilitário "Superclass"'
      m.cSuperMessage = 'Vê código de método de "parent classes", quando uma janela de edição de método de "Designer" de Formulário ou Classe está ativa.'
      m.cDoDefaultPrompt = ' Inserir palavra DODEFAULT()'
      m.cDodefaultMessage = 'Insere uma palavra DODEFAULT() usando a lista de parâmetros definida na "parent class"'
      m.cRetDoDefaultPrompt = ' Inserir RETURN DODEFAULT()'
      m.cRetDodefaultMessage = 'Insere uma palavra RETURN DODEFAULT() usando a lista de parâmetros definida na "parent class"'
      m.cSaveSuperPrompt = ' Salvar Posição de Janela de "Superclass"'
      m.cSaveSuperMessage = 'Salva o tamanho e posição corrente da janela de visualização de código da "superclass"'
  ENDCASE

  m.cThisPath = ["] + ThisPath() + ["]  && Enclose in quotes to allow paths that contain spaces

  * VFP Versions prior to 7.0 do not allow the PICTURE clause in menu definitions.
  m.cPicture = IIF(VERSION(5) >= 700, 'PICTURE ', '&' + '& ')

  * Define customizable Menu Hotkeys
  PRIVATE ALL LIKE pcKey*
  m.pcKeyBuilder = [KEY F2, "F2"]
  m.pcKeyHelp = [KEY F12, "F12"]
  m.pcKeyObjectInspector = [KEY F8, "F8"]
  m.pcKeySuperclassView = [KEY F9, "F9"]
  m.pcKeySuperclassParams = [KEY CTRL+F9, "Ctrl+F9"]
  m.pcKeySuperclassDodefault = [KEY SHIFT+F9, "Shift+F9"]
  m.pcKeySuperclassReturnDodefault = [KEY ALT+F9, "Alt+F9"]
  IF FILE('Custom\DevHotKeys.prg')
    DO Custom\DevHotKeys  && Let user redefine hotkey vars if desired.
  ENDIF

  SET SYSMENU TO DEFAULT
  DEFINE PAD _Codemine OF _MSYSMENU PROMPT "CodeMine" ;
     BEFORE "_MWINDOW" KEY ALT+C ;
     MESSAGE m.cCODEMINEMESSAGE
  ON PAD _Codemine OF _MSYSMENU ACTIVATE POPUP _Codemine

  DEFINE POPUP _Codemine MARGIN RELATIVE COLOR SCHEME 4
    DEFINE BAR 1 OF _Codemine PROMPT m.cABOUTPROMPT MESSAGE m.cABOUTMESSAGE &cPicture 'graphics\About.bmp'
     ON SELECTION BAR 1 OF _Codemine DO &cThisPath WITH 'About'
    DEFINE BAR 2 OF _Codemine PROMPT m.cHelpPrompt MESSAGE m.cHelpMessage &cPicture 'graphics\Help.bmp' ;
     &pcKeyHelp
     ON SELECTION BAR 2 OF _Codemine DO &cThisPath WITH 'ShowHelp'

    DEFINE BAR 4 OF _Codemine PROMPT "\-"
    DEFINE BAR 5 OF _Codemine PROMPT m.cNEWAPPPROMPT MESSAGE m.cNEWAPPMESSAGE &cPicture 'graphics\newrec.bmp'
     ON SELECTION BAR 5 OF _Codemine DO &cThisPath WITH 'NewApplication'
    DEFINE BAR 7 OF _Codemine PROMPT m.cOPENAPPPROMPT MESSAGE m.cOPENAPPMESSAGE &cPicture 'graphics\openApp.bmp'
     ON SELECTION BAR 7 OF _Codemine DO &cThisPath WITH 'OpenApplication'
    DEFINE BAR 8 OF _Codemine PROMPT m.cModifyAppPrompt MESSAGE m.cModifyAppMessage &cPicture 'graphics\modApp.bmp'
     ON SELECTION BAR 8 OF _Codemine DO &cThisPath WITH 'ModifyApplication'

    DEFINE BAR 10 OF _Codemine PROMPT "\-"
    DEFINE BAR 12 OF _Codemine PROMPT m.cNEWFORMPROMPT MESSAGE m.cNEWFORMMESSAGE &cPicture 'graphics\newForm.bmp'
     ON SELECTION BAR 12 OF _Codemine DO &cThisPath WITH 'NewForm'
    DEFINE BAR 13 OF _Codemine PROMPT m.cNewCdePrompt MESSAGE m.cNewCdeMessage
     ON SELECTION BAR 13 OF _Codemine DO &cThisPath WITH 'NewCDE'
    DEFINE BAR 15 OF _Codemine PROMPT "\-"
    DEFINE BAR 16 OF _Codemine PROMPT m.cREGEDITPROMPT MESSAGE m.cREGEDITMESSAGE &cPicture 'graphics\appReg1.bmp'
     ON SELECTION BAR 16 OF _Codemine DO &cThisPath WITH 'RegistryEditor'
    DEFINE BAR 17 OF _Codemine PROMPT m.cUSEREDITPROMPT MESSAGE m.cUSEREDITMESSAGE &cPicture 'graphics\Users2.bmp' ;
      SKIP FOR TYPE('m.goApp.oSecurity.Name') != 'C'
     ON SELECTION BAR 17 OF _Codemine DO &cThisPath WITH 'UserEditor'
    DEFINE BAR 18 OF _Codemine PROMPT m.cEVENTLOGPROMPT MESSAGE m.cEVENTLOGMESSAGE ;
      SKIP FOR TYPE('m.goApp.oSecurity.Name') != 'C'
     ON SELECTION BAR 18 OF _Codemine DO &cThisPath WITH 'ViewEvents'

    DEFINE BAR 20 OF _Codemine PROMPT "\-"
    DEFINE BAR 22 OF _Codemine PROMPT m.cINITPROMPT MESSAGE m.cINITMESSAGE &cPicture 'graphics\devInit.bmp'
     ON SELECTION BAR 22 OF _Codemine DO &cThisPath WITH 'ResetEnvironment'
    DEFINE BAR 9 OF _Codemine PROMPT m.cPrepProjectPrompt MESSAGE m.cPrepProjectMessage &cPicture 'graphics\Check.bmp'
     ON SELECTION BAR 9 OF _Codemine DO &cThisPath WITH 'PrepareForBuild'
    DEFINE BAR 25 OF _Codemine PROMPT m.cCLEARPROMPT MESSAGE m.cCLEARMESSAGE &cPicture 'graphics\ClearAll.bmp'
     ON SELECTION BAR 25 OF _Codemine DO &cThisPath WITH 'ClearAll'

    DEFINE BAR 30 OF _Codemine PROMPT "\-"
    DEFINE BAR 31 OF _Codemine PROMPT m.cTOOLSPROMPT MESSAGE m.cTOOLSMESSAGE &cPicture 'graphics\devTools.bmp'
     ON BAR 31 OF _Codemine ACTIVATE POPUP _CodemineTools

    DEFINE BAR 32 OF _Codemine PROMPT "\-"
    DEFINE BAR 33 OF _Codemine PROMPT m.cSuperPrompt MESSAGE m.cSuperMessage &cPicture 'graphics\_Super.bmp'
     ON BAR 33 OF _Codemine ACTIVATE POPUP _CodemineSuperclass

  * CodeMine Tools Menu Definition
  DEFINE POPUP _CodemineTools RELATIVE SHADOW COLOR SCHEME 4
    DEFINE BAR 10 OF _CodemineTools PROMPT m.cINSPECTORPROMPT MESSAGE m.cINSPECTORMESSAGE ;
      &pcKeyObjectInspector
      ON SELECTION BAR 10 OF _CodemineTools DO &cThisPath WITH 'Inspector'

    DEFINE BAR 12 OF _CodemineTools PROMPT "\-"
    DEFINE BAR 15 OF _CodemineTools PROMPT m.cBuilderPrompt MESSAGE m.cBuilderMessage ;
      &pcKeyBuilder ;
      SKIP FOR EMPTY(WONTOP()) OR NOT ('-' $ WONTOP() AND ('.SCX' $ WONTOP() OR '.VCX' $ WONTOP()))
      ON SELECTION BAR 15 OF _CodemineTools DO &cThisPath WITH 'StartBuilder'

    DEFINE BAR 20 OF _CodemineTools PROMPT "\-"
    DEFINE BAR 22 OF _CodemineTools PROMPT m.cEXTRACTPROMPT MESSAGE m.cEXTRACTMESSAGE ;
      SKIP FOR NOT '.scx' $ LOWER(WTITLE(WONTOP()))
      ON SELECTION BAR 22 OF _CodemineTools DO &cThisPath WITH 'DumpDataEnvironment'
    DEFINE BAR 30 OF _CodemineTools PROMPT m.cCopyClassPrompt MESSAGE m.cCopyClassMessage
      ON SELECTION BAR 30 OF _CodemineTools DO &cThisPath WITH 'CopyClass'
    DEFINE BAR 35 OF _CodemineTools PROMPT m.cPRGTOVCXPROMPT MESSAGE m.cPRGTOVCXMESSAGE
      ON SELECTION BAR 35 OF _CodemineTools DO &cThisPath WITH 'ConvertPrgToVcx'

    DEFINE BAR 40 OF _CodemineTools PROMPT "\-"
    DEFINE BAR 41 OF _CodemineTools PROMPT m.cPACKPROMPT MESSAGE m.cPACKMESSAGE ;
      SKIP FOR TYPE('m.goApp.Name') != 'C'
      ON SELECTION BAR 41 OF _CodemineTools DO &cThisPath WITH 'RegistryTools'

    DEFINE BAR 42 OF _CodemineTools PROMPT "\-"
    DEFINE BAR 43 OF _CodemineTools PROMPT m.cSqlScriptPrompt MESSAGE m.cSqlScriptMessage ;
      SKIP FOR TYPE('m.goApp.Name') != 'C'
      ON SELECTION BAR 43 OF _CodemineTools DO &cThisPath WITH 'SqlScript'
    DEFINE BAR 44 OF _CodemineTools PROMPT m.cUpsizePrompt MESSAGE m.cUpsizeMessage
      ON SELECTION BAR 44 OF _CodemineTools DO &cThisPath WITH 'UpsizeRegistry'

    DEFINE BAR 45 OF _CodemineTools PROMPT "\-"
    DEFINE BAR 46 OF _CodemineTools PROMPT m.cSetupPrompt MESSAGE m.cSetupMessage
    ON SELECTION BAR 46 OF _CodemineTools DO &cThisPath WITH 'Setup'

    IF NOT EMPTY(m.cZipPrompt) AND FILE(_SCREEN.cCodemineRootPath + '\data\cmzipdat.dbf')
      DEFINE BAR 50 OF _CodemineTools PROMPT "\-"
      DEFINE BAR 55 OF _CodemineTools PROMPT m.cZipPrompt MESSAGE m.cZipMessage
      ON SELECTION BAR 55 OF _CodemineTools DO &cThisPath WITH 'Zipcodes'
    ENDIF

  * Menu for "View Parent Class". We cant rely on any environment for the SKIP FOR expression
  * So we just use a simple one that will work in most cases, although the command window can confuse it.
  * When the option executes, the real code will correctly determine the focus window.
  DEFINE POPUP _CodemineSuperclass RELATIVE SHADOW COLOR SCHEME 4
    DEFINE BAR 15 OF _CodemineSuperclass PROMPT m.cPARENTCODEPROMPT MESSAGE m.cPARENTCODEMESSAGE ;
      &pcKeySuperclassView ;
      SKIP FOR EMPTY(WONTOP()) OR TYPE('_SCREEN.Activeform.Name') = 'C' ;
               OR '-' $ WONTOP() OR '[' $ WONTOP() OR OCCURS('.', WONTOP()) != 1 OR CNTBAR('_MPROG') != 6
      ON SELECTION BAR 15 OF _CodemineSuperclass DO &cThisPath WITH 'ViewSuperclass'

    DEFINE BAR 16 OF _CodemineSuperclass PROMPT m.cPARAMSPROMPT MESSAGE m.cPARAMSMESSAGE ;
        &pcKeySuperclassParams ;
        SKIP FOR EMPTY(WONTOP()) OR TYPE('_SCREEN.Activeform.Name') = 'C' ;
               OR '-' $ WONTOP() OR '[' $ WONTOP() OR OCCURS('.', WONTOP()) != 1 OR CNTBAR('_MPROG') != 6
      ON SELECTION BAR 16 OF _CodemineSuperclass DO &cThisPath WITH 'SuperclassParameters'
    DEFINE BAR 17 OF _CodemineSuperclass PROMPT m.cDoDefaultPrompt MESSAGE m.cDodefaultMessage ;
        &pcKeySuperclassDodefault ;
        SKIP FOR EMPTY(WONTOP()) OR TYPE('_SCREEN.Activeform.Name') = 'C' ;
               OR '-' $ WONTOP() OR '[' $ WONTOP() OR OCCURS('.', WONTOP()) != 1 OR CNTBAR('_MPROG') != 6
      ON SELECTION BAR 17 OF _CodemineSuperclass DO &cThisPath WITH 'SuperclassDodefault'
    DEFINE BAR 18 OF _CodemineSuperclass PROMPT m.cRetDoDefaultPrompt MESSAGE m.cRetDodefaultMessage ;
        &pcKeySuperclassReturnDodefault ;
        SKIP FOR EMPTY(WONTOP()) OR TYPE('_SCREEN.Activeform.Name') = 'C' ;
               OR '-' $ WONTOP() OR '[' $ WONTOP() OR OCCURS('.', WONTOP()) != 1 OR CNTBAR('_MPROG') != 6
      ON SELECTION BAR 18 OF _CodemineSuperclass DO &cThisPath WITH 'SuperclassDodefault', .T.
    DEFINE BAR 19 OF _CodemineSuperclass PROMPT "\-"
    DEFINE BAR 20 OF _CodemineSuperclass PROMPT m.cSaveSuperPrompt MESSAGE m.cSaveSuperMessage ;
        SKIP FOR EMPTY(WONTOP()) OR TYPE('_SCREEN.Activeform.Name') = 'C' ;
               OR '-' $ WONTOP() OR NOT '[' $ WONTOP() OR OCCURS('.', WONTOP()) != 1 OR CNTBAR('_MPROG') != 6
      ON SELECTION BAR 20 OF _CodemineSuperclass DO &cThisPath WITH 'SuperclassSavePos'

  SET SYSMENU SAVE
  CD (m.cDefault)
ENDFUNC


FUNCTION Startup()
*++
* Make sure the Codemine development environment is properly installed.
*--
  * Add other screen properties to store path to common Codemine class folders
  _SCREEN.AddProperty('cCodemineRootPath', RootPath() + '\')
  _SCREEN.AddProperty('cCodemineCommonPath', JUSTPATH(ThisPath()) + '\')
  _SCREEN.AddProperty('cCodemineDeveloperPath', '')

  IF LoadAPILibrary() AND Install()  && May do a CLEAR ALL
    LOCAL oForm, nValue, cPath, lInitEnvironment
    LOCAL cCodemineVersion, cKey, cPoint, lStatus

    * Preserve default builder path, and Install Codemine builder dispatcher as the primary builder.
    IF NOT PEMSTATUS(_SCREEN, 'cVFPbuilder', 5)
      _SCREEN.AddProperty('cVFPBuilder', '')
    ENDIF
    IF (NOT '\cmbuilder.prg' $ LOWER(_BUILDER))
      _SCREEN.cVFPBuilder = _BUILDER
    ENDIF
    _BUILDER = _SCREEN.cCodemineCommonPath + 'cmBuilder.prg'

    * Add the CodeMine menu pad to the system menu bar
    DO LoadCodemineMenu

    * Set the initial default directory, based on the startup folder option selected.
    m.nValue = 1
    cmRegGetValue(HKEY_LOCAL_MACHINE, SYSREG_CODEMINE_ROOT + '\Startup Folder', @m.nValue)
    DO CASE
      CASE m.nValue = 1
        * Do nothing - use whatever the VFP default folder is
      CASE m.nValue = 2
        CD (_SCREEN.cCodemineRootPath)
      CASE m.nValue = 3
        m.cPath = ''
        cmRegGetValue(HKEY_LOCAL_MACHINE, SYSREG_CODEMINE_ROOT + '\Last App', @m.cPath)
        IF NOT EMPTY(m.cPath) AND DIRECTORY(m.cPath)
          CD (m.cPath)
          m.nValue = 0
          cmRegGetValue(HKEY_LOCAL_MACHINE, SYSREG_CODEMINE_ROOT + '\Init On Startup', @m.nValue)
          m.lInitEnvironment = NOT EMPTY(m.nValue)
        ELSE
          * If no stored app folder, set default to the codemine root
          CD (_SCREEN.cCodemineRootPath)
        ENDIF
    ENDCASE

    * Init env if that option was selected. Otherwise, start out with a clean slate
    IF m.lInitEnvironment 
      InitEnvironment()
    ELSE
      ClearEnvironment(.T.)
    ENDIF

    * Run developer's custom VFP startup/setup program if found.
    m.cPath = _SCREEN.cCodemineRootPath + 'custom\devStartup.prg'
    IF FILE(m.cPath)
      DO (m.cPath)
    ENDIF
    RETURN .T.
  ENDIF
  RETURN .F.
ENDFUNC

FUNCTION ReInstall()
*++
* Un-install and then re-run the installation and registration dialog.
*--
  IF UnInstall(.T.)
    DO Startup
  ENDIF
ENDFUNC


FUNCTION Install()
*++
* Make sure the Codemine development environment is properly installed.
*--
LOCAL oForm, cCodemineVersion, cKey, cPoint, lStatus

  m.cPoint = SET('POINT')
  SET POINT TO '.'

  * Call install/registration dialog if the first time, or if Codemine or VFP version has changed.
  m.cKey = SYSREG_CODEMINE_ROOT  + '\Version\VFP' + LEFT(VERSION(4), 5)
  m.lStatus = NOT cmRegGetValue(HKEY_LOCAL_MACHINE, m.cKey, @m.cCodemineVersion) ;
                   OR VAL(m.cCodemineVersion) < VAL(CODEMINE_FOUNDATION_VERSION) ;
                   OR NOT FILE(_SCREEN.cCodemineRootPath + 'custom\cData.vcx') ;
                   OR NOT FILE(_SCREEN.cCodemineRootPath + 'custom\DevHotKeys.prg')
  SET POINT TO (m.cPoint)

  IF m.lStatus
    m.oForm = CREATEOBJECT('frmRegisterCodemine')
    IF VARTYPE(m.oForm) != 'O'
      RETURN .F.
    ENDIF
    m.oForm.Show(1)
    m.lStatus = m.oForm.ReturnValue()
    IF m.lStatus
      * Recompile all class libraries on competion of installation dialog.
      ClearEnvironment(.T.)   && Clear everything before recompiling.

      LOCAL cPath
      m.cPath = FULLPATH('')
      CD (_SCREEN.cCodemineCommonPath)
      WAIT WINDOW NOWAIT NOCLEAR 'Please wait while all CodeMine Class Libraries are Recompiled for this version of VFP'
      COMPILE CLASS *
      COMPILE Codemine.prg
      WAIT CLEAR
      CD (m.cPath)
      RETURN Setup()
    ENDIF
    RETURN .F.
  ENDIF
  RETURN .T.
ENDFUNC


FUNCTION UnInstall(lForce)
*++
* Remove ourself from the system registry.
*--
LOCAL nVersion, cRoot, cClassLib
  IF LoadAPILibrary()
    IF NOT m.lForce AND MESSAGEBOX("Uninstalling CodeMine will remove all CodeMine-specific entries from the Windows Registry, but will not delete any files. Do you wish to Uninstall?", ;
             52, "Unistall CodeMine") != 6
      RETURN .F.
    ENDIF

    SET SYSMENU TO DEFAULT
    RELEASE PAD _Codemine OF _MSYSMENU
    RELEASE POPUP _Codemine
    SET SYSMENU SAVE

    m.nVersion = VERSION(5)/100
    DO CASE
      CASE m.nVersion >=6 AND m.nVersion < 7
        m.cRoot = "Software\Microsoft\VisualFoxPro\6.0\Options\"
      CASE m.nVersion >=7 AND m.nVersion < 8
        m.cRoot = "Software\Microsoft\VisualFoxPro\7.0\Options\"
      CASE m.nVersion >=8 AND m.nVersion < 9
        m.cRoot = "Software\Microsoft\VisualFoxPro\8.0\Options\"
      CASE m.nVersion >=9 AND m.nVersion < 10
        m.cRoot = "Software\Microsoft\VisualFoxPro\9.0\Options\"
      OTHERWISE
        RETURN .F.
    ENDCASE

    * Delete CodeMine registration keys from Windows Registry, along with all values.
    cmRegDeleteKey(HKEY_LOCAL_MACHINE, SYSREG_CODEMINE_ROOT + '\Version')
    cmRegDeleteKey(HKEY_LOCAL_MACHINE, SYSREG_CODEMINE_ROOT)
    cmRegDeleteKey(HKEY_CURRENT_USER, SYSREG_CODEMINE_ROOT)

    * Remove Codemine class references from VFP intellidrop registry keys.
    UninstallFieldMapping(m.cRoot, 'Character')
    UninstallFieldMapping(m.cRoot, 'Character (binary)')
    UninstallFieldMapping(m.cRoot, 'Currency')
    UninstallFieldMapping(m.cRoot, 'Date')
    UninstallFieldMapping(m.cRoot, 'DateTime')
    UninstallFieldMapping(m.cRoot, 'Double')
    UninstallFieldMapping(m.cRoot, 'Float')
    UninstallFieldMapping(m.cRoot, 'Integer')
    UninstallFieldMapping(m.cRoot, 'Logical')
    UninstallFieldMapping(m.cRoot, 'Memo')
    UninstallFieldMapping(m.cRoot, 'Memo (binary)')
    UninstallFieldMapping(m.cRoot, 'Numeric')
    UninstallFieldMapping(m.cRoot, 'Multiple')
    UninstallFieldMapping(m.cRoot, 'Label')

    IF cmRegGetValue(HKEY_CURRENT_USER, m.cRoot + "FormsLib", @m.cClassLib) ;
    AND ('cmforms.vcx' $ LOWER(m.cClassLib) OR 'cforms.vcx' $ LOWER(m.cClassLib))
      cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "FormsClass")
      cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "FormsLib")
    ENDIF

    cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "VCXList\cControl")
    cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "VCXList\cButton")
    cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "VCXList\Cmactivx")
    cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "VCXList\Cmcredit")
    cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "VCXList\Cmgadget")
    cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "VCXList\Cmname")
    cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "VCXList\Cmtools")
    cmRegDeleteValue(HKEY_CURRENT_USER, m.cRoot + "VCXList\Cmdata")

    IF m.nVersion >=6
      SYS(3056)
    ENDIF
    ClearEnvironment(.T.)    && Clear quietly
  ENDIF
ENDFUNC


FUNCTION UninstallFieldMapping(cRoot, cType)
LOCAL cClassLib
  * During uninstall, Delete a VFP Intellidrop field mapping if it references a codemine VCX library.
  IF cmRegGetValue(HKEY_CURRENT_USER, m.cRoot + "IntelliDrop\FieldTypes\" + m.cType + "\ClassLocation", @m.cClassLib)
    m.cClassLib = LOWER(m.cClassLib)
    IF 'ccontrol.vcx' $ m.cClassLib OR 'codemine.vcx' $ m.cClassLib OR 'cmgadget.vcx' $ m.cClassLib
      cmRegDeleteKey(HKEY_CURRENT_USER, m.cRoot + "IntelliDrop\FieldTypes\" + m.cType)
    ENDIF
  ENDIF
ENDFUNC


FUNCTION CheckVersion
*++
* Verify that the app is running with the correct version of VFP and Codemine.fll
*--
LOCAL nVersion
  m.nVersion = VERSION(5)/100
  IF NOT BETWEEN(m.nVersion, 6.0, 9.9)
    =MESSAGEBOX('This version of VFP is not supported. Please contact Soft Classics for an upgrade.', 16, 'Obsolete version of CodeMine')
    RETURN m.nVersion > 6  && Let them try to run if newer than 6.0 - maybe it will work ok in later versions of VFP.
  ENDIF

  * Make sure the correct FLL file is loaded.
  IF cmGetFLLVersion() < MIN_FLL_VERSION
    =MESSAGEBOX('CodeMine.fll is outdated. Copy current version to your Application or Windows System folder')
    SET LIBRARY TO
    CANCEL
  ENDIF
  RETURN .T.
ENDFUNC


FUNCTION RootPath
LOCAL cPath
  m.cPath = ThisPath()
  RETURN LEFT(m.cPath, RAT('\', m.cPath, 2) - 1)    && Strip off program name and common folder name
ENDFUNC

FUNCTION ThisPath
* Return the path that this program file was run from.
LOCAL ix
  m.ix = 1
  DO WHILE NOT EMPTY(SYS(16, m.ix))
    IF '\CMSTART.' $ SYS(16, m.ix)
      RETURN SYS(16, m.ix)
    ENDIF
    m.ix = m.ix + 1
  ENDDO
ENDFUNC

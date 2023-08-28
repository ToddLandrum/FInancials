LPARAMETERS tcPath
LOCAL llPathPassed
DIMENSION aVersion[4]
llPathPassed = .F.
* Check to see if a company name was passed
IF VARTYPE(tcPath) = 'C'
   llPathPassed = .T.
ENDIF
* CodeMine application Main Program
*--
#include appdefs.h

IF llPathPassed
   MESSAGEBOX('Path: ' + tcPath,0,'Path')
   TRY 
   CD (tcPath)
   CATCH
   ENDTRY 
ENDIF 
*CLEAR ALL
*CLEAR
LOCAL cFllPath, cRootKey, llDevEnv, lcVersion, jcVersion
PUBLIC goApp         && Keep available for access by menu and ON SHUTDOWN handler.
PUBLIC oMenu
PUBLIC glSQLServer AS Boolean
PUBLIC oFoxAudit_APPDATA    && Fox Audit object
PUBLIC glDebug
PRIV lcValue

lcValue    = ' '
glDebug    = .F.
llDMPRO    = .F.
llLandPro  = .F.
llBrinePro = .F.
glSQLServer = .F.

SET PROCEDURE TO custom\swutils.prg additive
DO SetVFPMemory

SET ENGINEBEHAVIOR 70

*
*  TEMPORARY PUBLIC VARIABLE
*
PUBLIC m.cProducer
m.cProducer = 'SherWare Inc.'

SET TALK OFF
SET ESCAPE OFF       && No interuptions for finished application
SET COMPATIBLE OFF   && Make sure no DB4 settings alter default behavoir
SET EXCLUSIVE OFF
SET MULTILOCKS ON

* Clear any pre-existing libraries and handlers that are not part of our app.
SET LIBRARY TO
SET CLASSLIB TO
SET PROCEDURE TO
ON SHUTDOWN

ON KEY LABEL CTRL+F12 DO ctrlf12
ON KEY LABEL CTRL+F7 m.goStateManager.OpenForm('appversion.scx')
ON KEY LABEL CTRL+F8 m.goStateManager.OpenForm('companystats.scx')

llDMPRO = .F.

lcHelpLoc = specialfolders('CommonDocuments')
* Set the help file
IF FILE(lcHelpLoc + 'ampro.chm')
   SET HELP TO (lcHelpLoc + 'AMPRO.chm')
ELSE
*  If it doesn't exist in the public documents, try the individual user's documents folder instead
   lcHelpLoc = specialfolders('Personal')
   IF FILE(lcHelpLoc + 'ampro.chm')
      SET HELP TO (lcHelpLoc + 'AMPRO.chm')
   ELSE
*  Last ditch effort - try the current folder
      IF FILE('ampro.chm')
         SET HELP TO ampro.chm
      ENDIF
   ENDIF
ENDIF
_SCREEN.CAPTION = 'AM'

* Copy the VFP runtimes from program files
TRY
   IF NOT FILE('vfp9r.dll')
      COPY FILE ('c:\program files\common files\microsoft shared\vfp\vfp9r.dll') TO vfp9r.dll
   ENDIF
   IF NOT FILE('vfp9renu.dll')
      COPY FILE ('c:\program files\common files\microsoft shared\vfp\vfp9renu.dll') TO vfp9renu.dll
   ENDIF
CATCH
ENDTRY

TRY
   IF NOT FILE('vfp9r.dll')
      COPY FILE ('c:\program files (x86)\common files\microsoft shared\vfp\vfp9r.dll') TO vfp9r.dll
   ENDIF
   IF NOT FILE('vfp9renu.dll')
      COPY FILE ('c:\program files (x86)\common files\microsoft shared\vfp\vfp9renu.dll') TO vfp9renu.dll
   ENDIF
CATCH
ENDTRY

lcFile = UPPER(SYS(16))
IF 'SHERWARE' $ lcFile
   llAMPro = .T.
ENDIF
IF 'BMPRO' $ lcFile
   llBrinePro = .T.
ENDIF 
lnx    = AGETFILEVERSION(afile, lcFile)
IF lnx = 15
   lcVersion = afile[4]
ELSE
   lcVersion = '00'
ENDIF

jcVersion = STRTRAN(lcVersion, '.', '')

llDevEnv = .F.

**
** Update swlaunch if the included version is greater
** than the version on disk - pws - 3/31/09
**
TRY
    IF NOT USED('swlaunch')
        USE swlaunch IN 0
    ENDIF
    aVersion[4] = '1'
    SELECT swlaunch
    lcExeVersion = cversion
    lcExe        = mExe
    USE IN swlaunch
    * Get the current version of swlaunch
    lnFiles = AGETFILEVERSION(aVersion, 'swlaunch.exe')
    IF ALLTRIM(lcExeVersion) > ALLTRIM(aVersion[4]) OR lnFiles = 0
        lcSafety = SET('safety')
        SET SAFETY OFF
        STRTOFILE(lcExe, 'swlaunch.exe')
        SET SAFETY &lcSafety
    ENDIF
CATCH TO loError
    *    MESSAGEBOX(loError.Message)
ENDTRY

* Get the path this program was run from.
m.cFllPath = IIF('...' $ SYS(16, 1), SYS(16, 2), SYS(16, 1))
IF '.FXP' $ m.cFllPath
* If run as a standalone PRG file, presumably from a development folder,
* then set search path to locate the rest of the CodeMine development environment.
* This assumes default directory is set to the application root folder.
   SET PATH TO 'data\,source\,..\Common\,..\Graphics,..\Data'
   llDevEnv = .T.
ENDIF

IF '.APP' $ m.cFllPath
   llDevEnv = .T.
ENDIF

m.cFllPath = LEFT(m.cFllPath, RAT('\', m.cFllPath)) + 'codemine.fll'
IF NOT FILE(m.cFllPath)
* Get Windows system path for API library.
   DECLARE INTEGER GetSystemDirectory IN Kernel32.DLL STRING cBuffer, INTEGER nLength
   m.cSysDir = SPACE(128)
   = GetSystemDirectory(@m.cSysDir, LEN(m.cSysDir))
   m.cSysDir  = LEFT(m.cSysDir, AT(CHR(0), m.cSysDir) - 1)
   m.cFllPath = m.cSysDir + '\codemine.fll'
* As last resort, look for it in development source folder
   IF NOT FILE(m.cFllPath)
      m.cFllPath = '..\Common\Codemine.fll'
   ENDIF
ENDIF

ON ERROR m.cFllPath = ''
SET LIBRARY TO (m.cFllPath) ADDITIVE
ON ERROR
IF EMPTY(m.cFllPath)
   MESSAGEBOX('The files "codemine.fll" and "msvcrt.dll" must be placed in the application directory, or in your Windows System directory', 16, 'Error loading FLL file')
   RETURN .F.
ENDIF

* Load core CodeMine support classes, and main application library
SET PROCEDURE TO Codemine, swutils, cappmain, capp
SET CLASSLIB TO AppForms, cmapp, custom\foxaudit.vcx ADDITIVE

*
*  Check on the existence of the compmast table
*
IF NOT FILE('datafiles\compmast.dbf')
   IF FILE('compmast.dbf')
      COPY FILE compmast.* TO datafiles\compmast.*
   ELSE
      MESSAGEBOX('The company master file does not exist. Cannot continue.')
      RETURN .F.
   ENDIF
ENDIF

* Build root system registry key for this application
m.cRootKey = VERSION_LOC
IF OCCURS('.', m.cRootKey) > 1
   m.cRootKey = LEFT(m.cRootKey, AT('.', m.cRootKey, 2) - 1)
ENDIF
m.cRootKey = 'Software\' + COMPANYNAME_LOC + '\' + APPNAME_LOC + '\' + m.cRootKey

PRIVATE oMeta       && Stonefield Database Toolkit Object

oMeta = NEWOBJECT('DBCXMgr', 'DBCXMGR.VCX', '', .F.)
IF TYPE('oMeta') <> 'O' OR ISNULL(oMeta)
* Display error message and exit, because DBCX cannot be used.
   MESSAGEBOX('The DBCX is not available', 16, 'Error Loading DBCX')
   RETURN .F.
ENDIF

*  Make sure compmast is updated
oMeta.lSuppressErrors = .T.
oMeta.oSDTMgr.UPDATE('Compmast')

IF NOT USED('compmast')
   USE ('datafiles\compmast') IN 0
ENDIF

*IF FILE('datafiles\removecomps.txt')
   SELECT compmast
   SCAN 
      IF NOT DIRECTORY(compmast.cdatapath)
         DELETE NEXT 1
      ENDIF
   ENDSCAN 
*ENDIF 

SET SAFETY OFF
SET STRICTDATE TO 0
ON ERROR

IF NOT USED('compmast')
   USE datafiles\compmast IN 0 ORDER cidcomp
ENDIF

IF FILE('datafiles\update.dat')
   SELECT compmast
   SCAN FOR NOT DELETED()
      REPL cversion WITH '100'
   ENDSCAN
   ERASE ('datafiles\UPDATE.dat')
ENDIF

USE IN compmast

WAIT CLEAR

* Create the main application object and start it running.
m.goApp = CreateGlobalObject('appApplication', , m.cRootKey)

IF NOT ISNULL(m.goApp)
   ON SHUTDOWN m.goApp.SHUTDOWN()
   m.goApp.cdatafilepath = ''
   DO CASE
      CASE llBrinePro
         m.goApp.lAMVersion   = .T.   && Brine Hauler
         m.goApp.BrinePro     = .T.
         m.goApp.cSplash      = 'frmAppSplashScreenb'
         m.goApp.cFileVersion = lcVersion
         m.goApp.cProductName = 'BM'

      OTHERWISE
         m.goApp.lAMVersion   = .T.   && Accounting Manager
         m.goApp.cSplash      = 'frmAppSplashScreen'
         m.goApp.cFileVersion = lcVersion
   ENDCASE
   m.goApp.oMeta       = .NULL.
   m.goApp.lQBVersion  = .F.
   m.goApp.cExecutable = lcFile
   m.goApp.START()
ENDIF

* Return to the previous help file
*SET HELP TO

* Release all remaining shared global objects.
ReleaseGlobalObject()

SET ESCAPE ON

CLEAR ALL
SET LIBRARY TO
SET CLASSLIB TO
SET PROCEDURE TO
RETURN .T.




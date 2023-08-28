LPARAMETERS tlIgnoreSupport, tlForce
LOCAL lcDescription, lcLibrary, lcSourceFile, lcTargetFile, lcYear, llReturn, llSupport, loUpdate

#DEFINE CRLF CHR(13) + CHR(10)

lcLibrary = SET('library')

IF FILE(m.goapp.cCommonFolder+'ignoresupport.txt')
   tlIgnoreSupport = .T.
ENDIF 

TRY
   * Copy the old 1099 files to the new location
   IF NOT DIRECTORY(m.goapp.cCommonFolder+'Payroll')
      MKDIR (m.goapp.cCommonFolder+'Payroll')
   ENDIF
CATCH
ENDTRY

IF NOT tlIgnoreSupport
   llSupport = checksupportexp(.T.)
ELSE
   llSupport = .T.
ENDIF

IF NOT llSupport
   RETURN .F.
ENDIF

lcFile = 'prmoddate.txt'
lcWebDate = GetPRModDate(lcFile)

IF FILE('modules\Payroll\' + lcFile)
   lcMyRptsDate = FILETOSTR('modules\Payroll\' + lcFile)
ELSE
   lcMyRptsDate = '01/01/2004'
ENDIF

IF CTOD(lcWebDate) > CTOD(lcMyRptsDate) OR tlForce
   llGetFormats = .T.
   SET SAFETY OFF
ELSE
   llGetFormats = .F.
ENDIF

IF llGetFormats
   WAIT WINDOW NOWAIT 'Downloading the latest Payroll Module....please wait.'
   lcSourceFile  = 'prmod.zip'
   lcTargetFile  = m.goapp.cCommonFolder + 'prmod.zip'
   lcDescription = "Payroll Module Files"

   loUpdate              = m.goapp.oUpdate
   loUpdate.cSourceFile  = lcSourceFile
   loUpdate.cTargetFile  = lcTargetFile
   loUpdate.cDescription = lcDescription
   loUpdate.cUnzipTo     = 'modules\Payroll'
   llReturn              = loUpdate.GetUpdate()
   WAIT CLEAR
   IF NOT EMPTY(loUpdate.cErrorMessage)
      IF 'not found' $ LOWER(loUpdate.cErrorMessage)
         MESSAGEBOX('The Payroll Module Files are not available yet. Please check back later.',16,'1099 Payroll Module Not Available')
      ELSE
         MESSAGEBOX(loUpdate.cErrorMessage, 0, 'Download Payroll Module')
         STRTOFILE(lcWebDate,'modules\Payroll\' + lcFile)
      ENDIF
   ELSE
      STRTOFILE(lcWebDate,'modules\Payroll\' + lcFile)
   ENDIF
ENDIF

RETURN llReturn

********************************************************************************
FUNCTION GetPRModDate
********************************************************************************
* Looks for a file at http://support.sherware.com/StateReports/prmoddate.txt that
* contains the date of the latest state reports.
LPARAMETERS tcFile
LOCAL lcReportsDate, lcReportsURL, lcStateDate

lcDate = '01/01/2005'

DECLARE INTEGER URLDownloadToFile IN urlmon.DLL;
   INTEGER pCaller, ;
   STRING  szURL, ;
   STRING  szFileName, ;
   INTEGER dwReserved, ;
   INTEGER lpfnCB



lcReportsURL  = "http://support.sherware.com/StateReports/prmoddate.txt"


lcReportsDate = ADDBS(SYS(2023))+tcFile && temporary file created locally so expiration date can be saved

* Get the support expiration for the given client
URLDownloadToFile(0, lcReportsURL + '?fakevariable=' + SYS(2015), lcReportsDate, 0, 0)

IF FILE(lcReportsDate)
   lcDate = TRANSFORM(FILETOSTR(lcReportsDate)) && Latest date for state reports
ENDIF

RETURN lcDate

ENDFUNC

LPARAMETERS tlIgnoreSupport, tlForce
LOCAL lcDescription, lcLibrary, lcSourceFile, lcTargetFile, lcYear, llReturn, llSupport, loUpdate

#DEFINE CRLF CHR(13) + CHR(10)

lcLibrary = SET('library')

TRY
   * Copy the old 1099 files to the new location
   IF NOT DIRECTORY(m.goapp.cRptsFolder+'1099s')
      MKDIR (m.goapp.cRptsFolder+'1099s')
      ERASE (m.goapp.cRptsFolder+'ten99*.*') recycle
      ERASE (m.goapp.cRptsFolder+'f1099*.*') recycle
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

lcFile = 'ten99sdate.txt'
lcWebDate = Get1099sDate(lcFile)

IF FILE(m.goapp.cRptsFolder+'1099s\' + lcFile)
   lcMyRptsDate = FILETOSTR(m.goapp.cRptsFolder+'1099s\' + lcFile)
ELSE
   lcMyRptsDate = '01/01/2004'
ENDIF

IF CTOD(lcWebDate) > CTOD(lcMyRptsDate) OR tlForce
   llGetFormats = .T.
   SET SAFETY OFF
   STRTOFILE(lcWebDate,m.goapp.cRptsFolder+'1099s\' + lcFile)
ELSE
   llGetFormats = .F.
ENDIF

IF llGetFormats
   WAIT WINDOW NOWAIT 'Downloading the latest 1099 formats....please wait.'
   lcSourceFile  = 'form1099.zip'
   lcTargetFile  = m.goapp.cCommonFolder + 'form1099.zip'
   lcDescription = "1099 report formats"

   loUpdate              = m.goapp.oUpdate
   loUpdate.cSourceFile  = lcSourceFile
   loUpdate.cTargetFile  = lcTargetFile
   loUpdate.cDescription = lcDescription
   loUpdate.cUnzipTo     = m.goapp.cRptsFolder+'1099s'
   llReturn              = loUpdate.GetUpdate()
   WAIT CLEAR
   IF NOT EMPTY(loUpdate.cErrorMessage)
      IF 'not found' $ LOWER(loUpdate.cErrorMessage)
         MESSAGEBOX('The 1099 formats are not available yet. Please check back later.',16,'1099 Formats Not Available')
      ELSE
         MESSAGEBOX(loUpdate.cErrorMessage, 0, 'Update Files')
      ENDIF
   ENDIF
ENDIF

RETURN llReturn

********************************************************************************
FUNCTION Get1099sDate
********************************************************************************
* Looks for a file at http://support.sherware.com/StateReports/ten99s.txt that
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



lcReportsURL  = "http://support.sherware.com/StateReports/Ten99s.txt"


lcReportsDate = ADDBS(SYS(2023))+tcFile && temporary file created locally so expiration date can be saved

* Get the support expiration for the given client
URLDownloadToFile(0, lcReportsURL + '?fakevariable=' + SYS(2015), lcReportsDate, 0, 0)

IF FILE(lcReportsDate)
   lcDate = TRANSFORM(FILETOSTR(lcReportsDate)) && Latest date for state reports
ENDIF

RETURN lcDate

ENDFUNC

LPARAMETERS tlIgnoreSupport, tlForce
LOCAL lcDescription, lcLibrary, lcSourceFile, lcTargetFile, lcYear, llReturn, llSupport, loUpdate

#DEFINE CRLF CHR(13) + CHR(10)

lcLibrary = SET('library')

IF NOT tlIgnoreSupport
   llSupport = checksupportexp(.T.)
ELSE
   llSupport = .T.
ENDIF

IF NOT llSupport
   RETURN .F.
ENDIF


lcFile = 'brinemoddate.txt'
lcWebDate = GetBrineModDate(lcFile)

IF FILE('Modules\Brine\' + lcFile)
   lcMyRptsDate = FILETOSTR('Modules\Brine\' + lcFile)
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
   WAIT WINDOW NOWAIT 'Downloading the latest Brine Module....please wait.'
   lcSourceFile  = 'brinemod.zip'
   lcTargetFile  = m.goapp.cCommonFolder + 'brinemod.zip'
   lcDescription = "Brine Module Files"

   loUpdate              = m.goapp.oUpdate
   loUpdate.cSourceFile  = lcSourceFile
   loUpdate.cTargetFile  = lcTargetFile
   loUpdate.cDescription = lcDescription
   loUpdate.cUnzipTo     = 'Modules\Brine'
   llReturn              = loUpdate.GetUpdate()
   WAIT CLEAR
   IF NOT EMPTY(loUpdate.cErrorMessage)
      IF 'not found' $ LOWER(loUpdate.cErrorMessage)
         MESSAGEBOX('The Brine Module Files are not available yet. Please check back later.',16,'1099 Brine Module Not Available')
      ELSE
         MESSAGEBOX(loUpdate.cErrorMessage, 0, 'Download Brine Module')
         STRTOFILE(lcWebDate,'Modules\Brine\' + lcFile)
      ENDIF
   ELSE
      STRTOFILE(lcWebDate,'Modules\Brine\' + lcFile)
   ENDIF
ENDIF

RETURN llReturn

********************************************************************************
FUNCTION GetBrineModDate
********************************************************************************
* Looks for a file at http://support.sherware.com/StateReports/brinemoddate.txt that
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



lcReportsURL  = "http://support.sherware.com/StateReports/brinemoddate.txt"


lcReportsDate = ADDBS(SYS(2023))+tcFile && temporary file created locally so expiration date can be saved

* Get the support expiration for the given client
URLDownloadToFile(0, lcReportsURL + '?fakevariable=' + SYS(2015), lcReportsDate, 0, 0)

IF FILE(lcReportsDate)
   lcDate = TRANSFORM(FILETOSTR(lcReportsDate)) && Latest date for state reports
ENDIF

RETURN lcDate

ENDFUNC

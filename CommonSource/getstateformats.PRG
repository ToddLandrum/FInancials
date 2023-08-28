LPARAMETERS tcState, tlQuiet, tlForce
LOCAL loIP AS 'wwftp'
LOCAL lcDescription, lcLibrary, lcMyRptsDate, lcSourceFile, lcTargetFile, lcWebDate, llGetFormats
LOCAL llReturn, llSupport, lnResult, loUpdate, loerror

llReturn = .T.
llUnable = .F.

IF VARTYPE(tcState) # 'C'
   tcState = "ALL"
ENDIF 

TRY
   lcLibrary = SET('library')
   WAIT WINDOW NOWAIT 'Checking for the most current version of the state compliance reports...Please wait.'
   llSupport = checksupportexp()

   IF NOT llSupport AND NOT tlForce
      llReturn = .F.
      EXIT
   ENDIF

   DO CASE
      CASE tcState = 'CO'
         lcFile	   = "COReports.txt"
         lcSourceFile = 'CO_statereports.zip'

      CASE tcState = 'KS'
         lcFile	   = "KSReports.txt"
         lcSourceFile = 'KS_statereports.zip'

      CASE tcState = 'OH'
         lcFile	   = "OHReports.txt"
         lcSourceFile = 'OH_statereports.zip'

      CASE tcState = 'PA'
         lcFile	   = "PAReports.txt"
         lcSourceFile = 'PA_statereports.zip'

      CASE tcState = 'NY'
         lcFile	   = "NYReports.txt"
         lcSourceFile = 'NY_statereports.zip'

      CASE tcState = 'OK'
         lcFile	   = "OKReports.txt"
         lcSourceFile = 'OK_statereports.zip'

      CASE tcState = 'LA'
         lcFile	   = "LAReports.txt"
         lcSourceFile = 'LA_statereports.zip'

      CASE tcState = 'TX'
         lcFile	   = "TXReports.txt"
         lcSourceFile = 'TX_statereports.zip'

      CASE tcState = 'WV'
         lcFile	   = "WVReports.txt"
         lcSourceFile = 'WV_statereports.zip'

      CASE tcState = 'WY'
         lcFile	   = "WYReports.txt"
         lcSourceFile = 'WY_statereports.zip'

      OTHERWISE
         lcFile	   = "StateReports.txt"
         lcSourceFile = '_statereports.zip'
         tcState	   = ''
   ENDCASE

   lcWebDate = GetStateReportsDate(tcState,lcFile)

   IF FILE(m.goapp.cRptsFolder+'StateReports\' + tcState + '\' + lcFile)
      lcMyRptsDate = FILETOSTR(m.goapp.cRptsFolder+'StateReports\' + tcState + '\' + lcFile)
   ELSE
      lcMyRptsDate = '01/01/2004'
   ENDIF

   IF CTOD(lcWebDate) > CTOD(lcMyRptsDate) OR tlForce
      llGetFormats = .T.
   ELSE
      llGetFormats = .F.
   ENDIF

   IF llGetFormats

      lcTargetFile  = m.goapp.cCommonFolder + 'strpts.zip'
      lcDescription = tcState + ' State report formats'

      loUpdate			  = m.goapp.oUpdate
      loUpdate.cSourceFile  = lcSourceFile
      loUpdate.cTargetFile  = lcTargetFile
      loUpdate.cDescription = lcDescription
      loUpdate.cUnzipTo	  = m.goapp.cRptsFolder+'StateReports\' + tcState
      llReturn			  = loUpdate.GetUpdate()
      IF NOT llReturn
         MESSAGEBOX('Unable to update the state formats for ' + tcState + CHR(13) + loupdate.cerrormessage,64,'Update State Formats')
         llUnable = .t.
      ENDIF 
   ENDIF
   
   IF llGetFormats
      IF NOT llUnable
         SET SAFETY OFF 
         STRTOFILE(lcWebDate,m.goapp.crptsfolder+'StateReports\' + tcState + '\' + lcFile)
      ENDIF 
   ENDIF    

CATCH TO loerror
   llReturn = .F.
   DO errorlog WITH 'GetStateFormats', loerror.LINENO, 'GetStateFormats', loerror.ERRORNO, loerror.MESSAGE
   *!*       MESSAGEBOX('Unable to get the new state formats at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
   *!*             'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

WAIT CLEAR
RETURN llReturn

********************************************************************************
FUNCTION GetStateReportsDate
   ********************************************************************************
   * Looks for a file at http://support.sherware.com/StateReports/statereports.txt that
   * or https://support.sherware.com/StateReports/STreports.txt where ST is the 2
   * characters state code.
   * contains the date of the latest state reports.
   LPARAMETERS tcState, tcFile
   LOCAL lcReportsDate, lcReportsURL, lcStateDate

   lcDate = '01/01/2005'

   DECLARE INTEGER URLDownloadToFile IN urlmon.DLL;
      INTEGER pCaller, ;
      STRING  szURL, ;
      STRING  szFileName, ;
      INTEGER dwReserved, ;
      INTEGER lpfnCB

   DO CASE
      CASE tcState = 'CO'
         lcReportsURL  = "http://support.sherware.com/StateReports/COReports.txt"

      CASE tcState = 'KS'
         lcReportsURL  = "http://support.sherware.com/StateReports/KSReports.txt"

      CASE tcState = 'OH'
         lcReportsURL  = "http://support.sherware.com/StateReports/OHReports.txt"

      CASE tcState = 'PA'
         lcReportsURL  = "http://support.sherware.com/StateReports/PAReports.txt"

      CASE tcState = 'NY'
         lcReportsURL  = "http://support.sherware.com/StateReports/NYReports.txt"

      CASE tcState = 'OK'
         lcReportsURL  = "http://support.sherware.com/StateReports/OKReports.txt"

      CASE tcState = 'LA'
         lcReportsURL  = "http://support.sherware.com/StateReports/LAReports.txt"

      CASE tcState = 'TX'
         lcReportsURL  = "http://support.sherware.com/StateReports/TXReports.txt"

      CASE tcState = 'WV'
         lcReportsURL  = "http://support.sherware.com/StateReports/WVReports.txt"

      CASE tcState = 'WY'
         lcReportsURL  = "http://support.sherware.com/StateReports/WYReports.txt"
         
      CASE tcState = '99'  && 1099s
         lcReportsURL  = "http://support.sherware.com/StateReports/Ten99.txt"

      OTHERWISE
         lcReportsURL  = "http://support.sherware.com/StateReports/StateReports.txt"
   ENDCASE


   lcReportsDate = ADDBS(SYS(2023))+tcFile && temporary file created locally so expiration date can be saved

   * Get the support expiration for the given client
   URLDownloadToFile(0, lcReportsURL + '?fakevariable=' + SYS(2015), lcReportsDate, 0, 0)

   IF FILE(lcReportsDate)
      lcDate = TRANSFORM(FILETOSTR(lcReportsDate)) && Latest date for state reports
   ENDIF

   RETURN lcDate

ENDFUNC




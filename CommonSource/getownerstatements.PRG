LOCAL loIP AS 'wwftp'
LOCAL lcDescription, lcLibrary, lcMyRptsDate, lcSourceFile, lcTargetFile, lcWebDate, llGetFormats
LOCAL llReturn, llSupport, lnResult, loUpdate, loerror

llReturn = .T.

TRY
   lcLibrary = SET('library')
   WAIT WINDOW NOWAIT 'Checking for the most current version of the owner statement reports...Please wait.'
   llSupport = checksupportexp()

   IF NOT llSupport
      llReturn = .F.
      EXIT
   ENDIF
   
   lcFile	    = "OwnerDistStmts.txt"
   lcSourceFile = 'OwnerDistStmts.zip'

   lcWebDate = GetOstmtsDate(lcFile)

   IF FILE(m.goapp.cRptsFolder + lcFile)
      lcMyRptsDate = FILETOSTR(m.goapp.cRptsFolder + lcFile)
   ELSE
      lcMyRptsDate = '01/01/2004'
   ENDIF

   IF CTOD(lcWebDate) > CTOD(lcMyRptsDate)
      llGetFormats = .T.
      SET SAFETY OFF 
      STRTOFILE(lcWebDate,m.goapp.crptsfolder + lcFile)
   ELSE
      llGetFormats = .F.
   ENDIF

   IF llGetFormats

      lcTargetFile  = m.goapp.cCommonFolder + 'ownerdiststmts.zip'
      lcDescription = 'Owner Statement formats'

      loUpdate			  = m.goapp.oUpdate
      loUpdate.cSourceFile  = lcSourceFile
      loUpdate.cTargetFile  = lcTargetFile
      loUpdate.cDescription = lcDescription
      loUpdate.cUnzipTo	  = m.goapp.cRptsFolder
      llReturn			  = loUpdate.GetUpdate()
   ENDIF

CATCH TO loerror
   llReturn = .F.
   DO errorlog WITH 'GetOwnerStatements', loerror.LINENO, 'GetOwnerStatements', loerror.ERRORNO, loerror.MESSAGE
   *!*       MESSAGEBOX('Unable to get the new state formats at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
   *!*             'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

WAIT CLEAR
RETURN llReturn

********************************************************************************
FUNCTION GetOstmtsDate
   ********************************************************************************
   * Looks for a file at http://support.sherware.com/Reports/ownerdiststmts.txt that
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

  
   lcReportsURL  = "https://support.sherware.com/Reports/ownerdiststmts.txt"
 
   lcReportsDate = ADDBS(SYS(2023))+tcFile && temporary file created locally so expiration date can be saved

   * Get the support expiration for the given client
   URLDownloadToFile(0, lcReportsURL + '?fakevariable=' + SYS(2015), lcReportsDate, 0, 0)

   IF FILE(lcReportsDate)
      lcDate = TRANSFORM(FILETOSTR(lcReportsDate)) && Latest date for state reports
   ENDIF

   RETURN lcDate

ENDFUNC




PARA tcCheck
LOCAL lcData, llFound, llError

* Check to see if the check file names are specified by account in glopt
swselect('glopt')
GO TOP
llCheckNames = lCheckNames

IF llCheckNames
   MESSAGEBOX('The check formats are specified by account in the Chart of Accounts. ' + ;
        'This is set in the General Ledger Preferences.' + CHR(10)+CHR(10) + ;
        'Go to Maintain Chart of Accounts and bring up the cash account for the check you want to modify ' + ;
        'and click on the Modify Check button for the type of check to modify.', 64, 'Modify Check')
   RETURN
ENDIF

llFound  = .F.  &&  Variable for telling whether the requested file exists - BH 8/30/06
llError  = .F.  &&  Set to .T. in the catch if an error is enountered trying to modi a file
oMessage = findglobalobject('cmMessage')

PUSH MENU _MSYSMENU
SET SYSMENU TO _MFILE, _MEDIT

lcData = ALLTRIM(m.goApp.cDataFilePath)

m.goStateManager.CloseToolbar('tbrMainToolBar')
tcReport = ''

* Setup up try/catch to catch error 1 - file does not exist
TRY

   * Get the type of check to modify based on the parameter passed
   DO CASE
      CASE tcCheck = 'AP'
         swselect('apopt')
         lcCheckType = cCheckType
         tcReport    = 'apchk' + lcCheckType
      CASE tcCheck = 'DM'
         swselect('options')
         lcCheckType = cCheckType
         IF options.lTwoLines
            tcReport = 'dmchklve'
         ELSE
            tcReport = 'dmchk' + lcCheckType
         ENDIF
      CASE tcCheck = 'PR'
         swselect('propt')
         lcCheckType = cCheckType
         tcReport    = 'prchk' + lcCheckType
      CASE tcCheck = 'LM'
         swselect('landopt')
         lcCheckType = cCheckType
         tcReport    = 'lmchk' + lcCheckType
      CASE tcCheck = 'PD'
         swselect('progopt')
         lcCheckType = cCheckType
         tcReport    = 'pdchk' + lcCheckType
   ENDCASE

   IF EMPTY(lcCheckType)
      MESSAGEBOX('The type of check has not been specified. Please specify the check type and try again.', 64, 'Modify Check Format')
      llReturn = .F.
      llFound  = .T.
      EXIT
   ENDIF
   tcReport = UPPER(tcReport)
   DO CASE
      CASE tcReport == 'PRCHKLV'
         IF FILE(m.goApp.cChecksFolder + 'prcheklv.frx')
            AddProtection(m.goApp.cChecksFolder + 'prcheklv.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'prcheklv') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PRCHKLM'
         IF FILE(lcData + 'prcheklm.frx')
            AddProtection(lcData + 'prcheklm.frx')
            MODIFY REPORT (lcData + 'prcheklm') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PRCHKDA'
         IF FILE(m.goApp.cChecksFolder + 'prchekda.frx')
            AddProtection(m.goApp.cChecksFolder + 'prchekda.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'prchekda') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PRCHKDB'
         IF FILE(m.goApp.cChecksFolder + 'prchekdb.frx')
            AddProtection(m.goApp.cChecksFolder + 'prchekdb.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'prchekdb') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLV'
         IF FILE(m.goApp.cChecksFolder + 'apcheklv.frx')
            AddProtection(m.goApp.cChecksFolder + 'apcheklv.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'apcheklv') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLM'
         IF FILE(lcData + 'apcheklm.frx')
            AddProtection(lcData + 'apcheklm.frx')
            MODIFY REPORT (lcData + 'apcheklm') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLN'
         IF FILE(m.goApp.cChecksFolder + 'apchekln.frx')
            AddProtection(m.goApp.cChecksFolder + 'apchekln.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'apchekln') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLE'
         IF FILE(lcData + 'apchekle.frx')
            AddProtection(lcData + 'apchekle.frx')
            MODIFY REPORT (lcData + 'apchekle') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKDB'
         IF FILE(m.goApp.cChecksFolder + 'apchekdb.frx')
            AddProtection(m.goApp.cChecksFolder + 'apchekdb.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'apchekdb') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKDA'
         IF FILE(m.goApp.cChecksFolder + 'apchekda.frx')
            AddProtection(m.goApp.cChecksFolder + 'apchekda.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'apchekda') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKDN'
         IF FILE(m.goApp.cChecksFolder + 'apchekdn.frx')
            AddProtection(m.goApp.cChecksFolder + 'apchekdn.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'apchekdn') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLA'
         IF FILE(m.goApp.cChecksFolder + 'apchekla.frx')
            AddProtection(m.goApp.cChecksFolder + 'apchekla.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'apchekla') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLC'
         IF FILE(m.goApp.cChecksFolder + 'apcheklc.frx')
            AddProtection(m.goApp.cChecksFolder + 'apcheklc.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'apcheklc') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKCF'
         IF NOT FILE(lcData + 'apchekcf.frx')
            USE customchk IN 0
            SELECT customchk
            COPY TO (lcData + 'apchekcf.frx') FOR checkname = 'APCHEKCF'
            USE IN customchk
         ENDIF
         TRY
            MODIFY REPORT (lcData + 'apchekcf') PROTECTED NOENVIRONMENT
            llFound = .T.
         CATCH
            llFound = .F.
         ENDTRY
      CASE tcReport == 'DMCHKLVE'
         IF FILE(m.goApp.cChecksFolder + 'dmcheklve.frx')
            AddProtection(m.goApp.cChecksFolder + 'dmcheklve.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'dmcheklve') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKLV'
         IF FILE(m.goApp.cChecksFolder + 'dmcheklv.frx')
            AddProtection(m.goApp.cChecksFolder + 'dmcheklv.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'dmcheklv') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKLM'
         IF FILE(lcData + 'dmcheklm.frx')
            AddProtection(lcData + 'dmcheklm.frx')
            MODIFY REPORT (lcData + 'dmcheklm') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKLE'
         IF FILE(lcData + 'dmchekle.frx')
            AddProtection(lcData + 'dmchekle.frx')
            MODIFY REPORT (lcData + 'dmchekle') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKLA'
         IF FILE(m.goApp.cChecksFolder + 'dmchekla.frx')
            AddProtection(m.goApp.cChecksFolder + 'dmchekla.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'dmchekla') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKLC'
         IF FILE(m.goApp.cChecksFolder + 'dmcheklc.frx')
            AddProtection(m.goApp.cChecksFolder + 'dmcheklc.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'dmcheklc') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKDB'
         IF FILE(m.goApp.cChecksFolder + 'dmchekdb.frx')
            AddProtection(m.goApp.cChecksFolder + 'dmchekdb.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'dmchekdb') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKDA'
         IF FILE(m.goApp.cChecksFolder + 'dmchekda.frx')
            AddProtection(m.goApp.cChecksFolder + 'dmchekda.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'dmchekda') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKDN'
         IF FILE(m.goApp.cChecksFolder + 'dmchekdn.frx')
            AddProtection(m.goApp.cChecksFolder + 'dmchekdn.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'dmchekdn') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKLN'
         IF FILE(m.goApp.cChecksFolder + 'dmchekln.frx')
            AddProtection(m.goApp.cChecksFolder + 'dmchekln.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'dmchekln') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKCF'
         IF NOT FILE(lcData + 'dmchekcf.frx')
            USE customchk IN 0
            SELECT customchk
            COPY TO (lcData + 'dmchekcf.frx') FOR checkname = 'DMCHEKCF'
            USE IN customchk
         ENDIF
         AddProtection(lcData + 'dmchekcf.frx')
         TRY
            MODIFY REPORT (lcData + 'dmchekcf') PROTECTED NOENVIRONMENT
            llFound = .T.
         CATCH
         ENDTRY
      CASE tcReport == 'LMCHKDB'
         IF FILE(m.goApp.cChecksFolder + 'lmchekdb.frx')
            AddProtection(m.goApp.cChecksFolder + 'lmchekdb.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'lmchekdb') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'LMCHKDA'
         IF FILE(m.goApp.cChecksFolder + 'lmchekda.frx')
            AddProtection(m.goApp.cChecksFolder + 'lmchekda.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'lmchekda') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'LMCHKDN'
         IF FILE(m.goApp.cChecksFolder + 'lmchekdn.frx')
            AddProtection(m.goApp.cChecksFolder + 'lmchekdn.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'lmchekdn') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'LMCHKLV'
         IF FILE(m.goApp.cChecksFolder + 'lmcheklv.frx')
            AddProtection(m.goApp.cChecksFolder + 'lmcheklv.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'lmcheklv') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'LMCHKLA'
         IF FILE(m.goApp.cChecksFolder + 'lmchekla.frx')
            AddProtection(m.goApp.cChecksFolder + 'lmchekla.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'lmchekla') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'LMCHKLC'
         IF FILE(m.goApp.cChecksFolder + 'lmcheklc.frx')
            AddProtection(m.goApp.cChecksFolder + 'lmcheklc.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'lmcheklc') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'LMCHKLE'
         IF FILE(lcData + 'lmchekle.frx')
            AddProtection(lcData + 'lmchekle.frx')
            MODIFY REPORT (lcData + 'lmchekle') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF   
      CASE tcReport == 'LMCHKLN'
         IF FILE(m.goApp.cChecksFolder + 'lmchekln.frx')
            AddProtection(m.goApp.cChecksFolder + 'lmchekln.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'lmchekln') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'LMCHKCF'
         IF NOT FILE(lcData + 'lmchekcf.frx')
            USE customchk IN 0
            SELECT customchk
            COPY TO (lcData + 'lmchekcf.frx') FOR checkname = 'LMCHEKCF'
            USE IN customchk
         ENDIF
         AddProtection(lcData + 'lmchekcf.frx')
         TRY
            MODIFY REPORT (lcData + 'lmchekcf') PROTECTED NOENVIRONMENT
            llFound = .T.
         CATCH
         ENDTRY
      CASE tcReport == 'PDCHKLV'
         IF FILE(m.goApp.cChecksFolder + 'pdcheklv.frx')
            AddProtection(m.goApp.cChecksFolder + 'pdcheklv.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'pdcheklv') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PDCHKLA'
         IF FILE(m.goApp.cChecksFolder + 'pdchekla.frx')
            AddProtection(m.goApp.cChecksFolder + 'pdchekla.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'pdchekla') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PDCHKLB'
         IF FILE(m.goApp.cChecksFolder + 'pdcheklb.frx')
            AddProtection(m.goApp.cChecksFolder + 'pdcheklb.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'pdcheklb') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PDCHKDA'
         IF FILE(m.goApp.cChecksFolder + 'pdchekda.frx')
            AddProtection(m.goApp.cChecksFolder + 'pdchekda.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'pdchekda') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PDCHKDB'
         IF FILE(m.goApp.cChecksFolder + 'pdchekdb.frx')
            AddProtection(m.goApp.cChecksFolder + 'pdchekdb.frx')
            MODIFY REPORT (m.goApp.cChecksFolder + 'pdchekdb') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == '1099MISCW'
         IF FILE(m.goApp.cRptsFolder + 'ten99miscw.frx')
            AddProtection(m.goApp.cRptsFolder + 'ten99miscw.frx')
            MODIFY REPORT (m.goApp.cRptsFolder + 'ten99miscw') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
   ENDCASE

CATCH TO loError
   llError = .T.
ENDTRY

* Tell the user there was a problem if llError is .T.
IF llError
   IF loError.ERRORNO = 1
      oMessage.Warning('The requested check format does not exist, so it cannot be modified.')
   ELSE
      MESSAGEBOX('The chosen check format cannot be modified. The error encountered: ' + CHR(10) + CHR(10) + loError.MESSAGE, 48, 'Modify Check Format Problem')
   ENDIF
ELSE
   IF NOT llFound  &&  Requested format didn't exist, so give a warning, instead of doing nothing
      oMessage.Warning('The requested check format does not exist, so it cannot be modified.')
   ENDIF
ENDIF

POP MENU _MSYSMENU

m.goStateManager.OpenToolbar('tbrMainToolBar')

*!*    IF lcCURR_MENU = 'OFF'
*!*       SET SYSMENU OFF
*!*    ENDIF lcCURR_MENU = 'OFF'



PROCEDURE AddProtection

   PARAMETERS tcReportFormat

   **  Try and get a lock on the file, so we know whether we'll be able to open the .frx file to check the protection stuff.
   **  If it can't open the .frx file, just open it like normal.  This should be rare.  Should only happen if they're trying
   **  to modify the report format while someone else is printing using that format, or is modifying it, too.  What are the chances...

   fh = FOPEN(tcReportFormat)

   IF fh > 0
      FCLOSE(fh)
      USE "&tcReportFormat" IN 0 ALIAS chkfmt
      SELECT chkfmt
      GO TOP
      IF NOT '€€' $ ORDER
         * Wrap this in a TRY/CATCH to catch any errors
         * caused by the file being read only.
         TRY
            REPLACE ORDER WITH '€€'
         CATCH
         ENDTRY
      ENDIF
      USE IN chkfmt
   ENDIF


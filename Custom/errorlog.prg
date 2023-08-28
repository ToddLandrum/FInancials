LPARA tcMethod, tnLine, tcCaller, tnError, tcMessage, tcExtra, toException, tlProgramData, tlNoSendError
LOCAL oMessage, laErrors[1], llExcl, laStackInfo[1], llQBSDKLog, lcLogLocation

*
*  Creates a log entry for any errors
*
TRY
   SET SAFETY OFF

   m.cCaller = tcCaller

   llQBSDKLog    = .F.
   lcLogLocation = ''

   IF TYPE('tnLine') # 'N'
      llReturn = .F.
      EXIT
   ENDIF

   IF TYPE('tcCaller') # 'C'
      llReturn = .F.
      EXIT
   ENDIF

   IF VARTYPE(tcExtra) # 'C'
      tcExtra = ' '
   ENDIF

   AERROR(laErrors)
   lnStackInfo = ASTACKINFO(laStackInfo)

   IF VARTYPE(m.goapp) # 'O'
      llReturn = .F.
      EXIT
   ENDIF

   swclose('errorlog')

* Initalize variables
   STORE '' TO m.cETime, m.cMethod, m.cExtra, m.cMessage, ;
      M.cCaller, m.cuser, m.cVersion, m.cSDKVer, m.cQBFCVer, ;
      M.DETAILS, m.cDetails

   IF NOT FILE(m.goapp.cCommonFolder + 'errorlog.dbf')
      CREATE TABLE (m.goapp.cCommonFolder + 'errorlog') FREE ;
         ( dEDate    D, ;
           cETime    C(8), ;
           cMethod   C(20), ;
           cExtra    C(20), ;
           nLineNo   N(5), ;
           nENumber  N(5), ;
           cMessage  C(254), ;
           cCaller   C(20), ;
           cuser     C(20), ;
           cVersion  C(10), ;
           cSDKVer   C(5), ;
           cQBFCVer  C(5), ;
           DETAILS   M)
   ENDIF

   llExcl = .T.
   TRY
      IF NOT USED('errorlog')
         USE (m.goapp.cCommonFolder + 'errorlog') EXCL IN 0
      ENDIF
      IF TYPE('errorlog.cversion') # 'C'
         ALTER TABLE errorlog ADD COLUMN cVersion C(10)
      ENDIF
      IF TYPE('errorlog.csdkver') # 'C'
         ALTER TABLE errorlog ADD COLUMN cSDKVer C(5)
      ENDIF
      IF TYPE('errorlog.cqbfcver') # 'C'
         ALTER TABLE errorlog ADD COLUMN cQBFCVer C(5)
      ENDIF
      IF TYPE('errorlog.details') # 'M'
         ALTER TABLE errorlog ADD COLUMN DETAILS M
      ENDIF
   CATCH
      llExcl = .F.
   ENDTRY

   IF NOT llExcl
      IF NOT USED('errorlog')
         USE (m.goapp.cCommonFolder + 'errorlog') IN 0
      ENDIF
   ENDIF

   m.dEDate   = DATE()
   m.cETime   = TIME()
   m.cMethod  = tcMethod
   m.nLineNo  = tnLine
   m.cCaller  = tcCaller
   m.cCompany = m.goapp.cCompanyName

   IF VARTYPE(tnError) # 'N'
      m.nENumber = laErrors[1]
      m.cMessage = laErrors[2]

      IF NOT ISNULL(laErrors[3])
         m.cExtra = laErrors[3]
      ELSE
         m.cExtra = ''
      ENDIF
   ELSE
      m.nENumber = tnError
      m.cMessage = tcMessage
      m.cExtra   = tcExtra
   ENDIF

   m.cuser    = m.goapp.cuser
   m.cVersion = m.goapp.cfileversion
   m.cSDKVer  = ''
   m.cQBFCVer = ''

   IF VARTYPE(toException) = 'O'
* We have an error object. Get the info from it
      m.nENumber = toException.ERRORNO
      m.cMethod  = toException.PROCEDURE
      m.nLineNo  = toException.LINENO
      m.cCode    = toException.LINECONTENTS
      m.cMessage = toException.MESSAGE
      m.cDetails = toException.DETAILS
   ELSE
      m.cCode = MESSAGE(1)
   ENDIF

   IF m.goapp.lQBVersion
      TRY
         IF VARTYPE(m.goapp.oqb.sdkversion) = 'C'
            m.cSDKVer  = m.goapp.oqb.sdkversion
            m.cQBFCVer = m.goapp.oqb.QBFCVersion
         ELSE
            m.cSDKVer  = ''
            m.cQBFCVer = ''
         ENDIF
      CATCH
      ENDTRY
      IF tlProgramData
         TRY
            IF NOT FILE('c:\programdata\intuit\quickbooks\qbsdklog.txt')
               IF NOT FILE('C:\Documents and Settings\All Users\Application Data\Intuit\QuickBooks\qbsdklog.txt')
                  tlProgramData = .F.
               ELSE
                  llQBSDKLog    = .T.
                  lcTemp        = SYS(2023)
                  lcFile        = SYS(2015) + '.txt'
                  lcLogLocation = ADDBS(lcTemp) + lcFile
                  lcString      = FILETOSTR('C:\Documents and Settings\All Users\Application Data\Intuit\QuickBooks\qbsdklog.txt')
                  STRTOFILE(lcString, lcLogLocation)
               ENDIF
            ELSE
               llQBSDKLog    = .T.
               lcTemp        = SYS(2023)
               lcFile        = SYS(2015) + '.txt'
               lcLogLocation = ADDBS(lcTemp) + lcFile
               lcString      = FILETOSTR('C:\Documents and Settings\All Users\Application Data\Intuit\QuickBooks\qbsdklog.txt')
               STRTOFILE(lcString, lcLogLocation)
            ENDIF
         CATCH
         ENDTRY
      ENDIF
   ENDIF

   lcDate = DTOC(FDATE(ALLTRIM(m.goapp.cexecutable)))
   lcTime = FTIME(ALLTRIM(m.goapp.cexecutable))

   m.DETAILS = 'APPLICATION: ' + ALLTRIM(m.goapp.cexecutable) + ;
      'VERSION:     ' + m.cVersion + '   DATE: ' + lcDate + '   TIME: ' + lcTime + CHR(10)

   m.DETAILS = m.DETAILS + CHR(10) + ;
      'COMPANY OPEN ' + m.cCompany + CHR(10) + ;
      'ERROR NO:    ' + TRANSFORM(m.nENumber) + CHR(10) + ;
      'ERROR MSG:   ' + m.cMessage + CHR(10) + ;
      'MODULE:      ' + tcCaller +  CHR(10) + ;
      'METHOD:      ' + m.cMethod + CHR(10) + ;
      'LINE NO      ' + TRANSFORM(m.nLineNo) + '   CODE:      ' + m.cCode + CHR(10) + ;
      IIF(NOT EMPTY(m.cDetails), 'DETAILS:     ' + m.cDetails + CHR(10), '') + ;
      'USER:        ' + m.cuser + CHR(10) + ;
      IIF(NOT EMPTY(m.cExtra), m.cExtra, '') + CHR(10)

   IF NOT EMPTY(m.cSDKVer)
      m.DETAILS = m.DETAILS + 'QB SDK: ' + m.cSDKVer + '  QBFC VERSION: ' + m.cQBFCVer + CHR(10) + CHR(10)
   ELSE
      m.DETAILS = m.DETAILS + CHR(10)
   ENDIF

   m.DETAILS   = m.DETAILS + 'Call Stack: ' + CHR(10)
   lcStackInfo = ''
   FOR x = lnStackInfo TO 1 STEP - 1
      IF NOT 'errorlog' $ laStackInfo[x, 2] AND NOT 'do errorlog' $ LOWER(laStackInfo[x, 6])
         lcStackInfo = lcStackInfo + 'LEVEL: ' + TRANSFORM(laStackInfo[x, 1]) + CHR(10) + ;
            '     PROGRAM: ' + ALLTRIM(laStackInfo[x, 2]) + CHR(10) + ;
            '     MODULE:  ' + ALLTRIM(laStackInfo[x, 3]) + CHR(10) + ;
            '     FILE:    ' + ALLTRIM(laStackInfo[x, 4]) + CHR(10) + ;
            '     LINE:    ' + TRANSFORM(laStackInfo[x, 5]) + '   SOURCE:  ' + laStackInfo[x, 6] + CHR(10)
      ENDIF
   ENDFOR
   m.DETAILS = m.DETAILS + lcStackInfo

* Don't send these errors to support
   IF INLIST(m.nENumber, 5, 13, 43, 108, 111, 1103, 1104, 1190, 1585, 1298, 1958)
      tlNoSendError = .T.
   ENDIF

* If the error message contains these phrases don't send them to support.
   IF 'Invalid Date Value' $ m.cMessage OR ;
         'QuickBooks did not finish' $ m.cMessage OR ;
         'An internal QuickBooks error occurred' $ m.cMessage OR ;
         'Error parsing.' $ m.cMessage OR ;
         'logins.dbf' $ m.cMessage OR ;
         'OLOGGER' $ m.cMessage OR ;
         'Automated Error Recovery Error' $ m.cMessage
      tlNoSendError = .T.
   ENDIF


   SELECT errorlog
   COUNT FOR dEDate = m.dEDate AND cMethod = ALLTRIM(m.cMethod) AND nLineNo = m.nLineNo AND nENumber = m.nENumber TO lnErrors
   IF lnErrors < 1
      INSERT INTO errorlog FROM MEMVAR
      IF NOT tlNoSendError
         DO senderror WITH m.cMethod, m.nLineNo, tcCaller, m.nENumber, m.cMessage, m.DETAILS, llQBSDKLog, lcLogLocation
      ENDIF
   ENDIF
   USE IN errorlog
CATCH TO loError
*!*      MESSAGEBOX('Error in Errorlog' + CHR(10) + ;
*!*           'Error No: ' + TRANSFORM(loError1.ERRORNO) + CHR(10) + ;
*!*           'Line No:  ' + TRANSFORM(loError1.LINENO) + CHR(10) + ;
*!*           'Code:     ' + MESSAGE(1), 16, 'Error')
ENDTRY

RETURN










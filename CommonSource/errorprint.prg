LOCAL lnCount, llCleared
LOCAL lcLF, lcRegCode, loerror, lnCount
LOCAL llReturn, llUseError

llReturn = .T.

TRY

*  Prints the error log listing

   IF NOT FILE(m.goapp.cCommonFolder + 'errorlog.dbf')
* If errorlog.dbf doesn't exist, there have been no errors.
      MESSAGEBOX('There are no errors in the error log to be listed.', 64, 'View System Log')
      llReturn = .F.
      EXIT
   ENDIF

   IF TYPE('m.goApp') <> 'O'
      m.cProducer = 'Development Company'
   ELSE
      m.cProducer = m.goapp.cCompanyName
   ENDIF

   lcTitle1 = ''
   lcTitle2 = ''
   SET DELETED ON
   IF NOT USED('errorlog')
      IF FILE(m.goapp.cCommonFolder + 'errorlog.dbf')
         TRY
            USE (m.goapp.cCommonFolder + 'errorlog') IN 0
         CATCH
            llUseError = .T.
         ENDTRY
      ELSE
         MESSAGEBOX('There are no entries in the system log to be listed', 64, 'View System Log')
         llReturn = .T.
         EXIT
      ENDIF
   ENDIF

   SELECT errorlog
   COUNT FOR NOT DELETED() TO lnCount

   IF lnCount > 0
	  SELECT  * ;
		  FROM errorlog ;
		  INTO CURSOR errorprint ;
		  ORDER BY dedate DESCENDING, cetime DESCENDING
      REPORT FORM errorlog TO PRINTER PROMPT PREVIEW

      IF MESSAGEBOX('Would you like to email this error log to SherWare Support now?', 36, 'View System Log') = 6
         LOCAL llResult, oSendMail, lcTime, lcVersion, lcDate, lcSubject, lcBody, lcCompany, lcClient
         TRY
            swselect('options')

            oSendMail = CREATEOBJECT('swSendMail')

            lcClient  = m.goapp.cClient
            lcCompany = m.goapp.cRegCompany
            lcRegCode = m.goapp.cCode
            lcVersion = m.goapp.cFileVersion
            lcDate    = DTOC(FDATE(ALLTRIM(m.goapp.cexecutable)))
            lcTime    = FTIME(ALLTRIM(m.goapp.cexecutable))

            lcBody = 'Company: ' + lcCompany + CHR(10) ;
               + 'Registration Code: ' + lcRegCode + CHR(10) ;
               + 'Software: ' + CHR(10) ;
               + ALLTRIM(m.goapp.cexecutable) + ' Version: ' + lcVersion + '  ' + ;
               + lcDate    + '  ' + ;
               + lcTime    + CHR(10) + CHR(10)

            lnCount = 0
            SELECT errorprint
            SCAN
               SCATTER MEMVAR

               lcBody = lcBody + 'Date: ' + DTOC(dedate) + '  ' + cetime + CHR(10) + ;
                  'Program: ' + ALLTRIM(ccaller) + CHR(10) + ;
                  'Method: ' + ALLTRIM(cmethod) + CHR(10) + ;
                  'Line: ' + TRANSFORM(nlineno) + CHR(10) + ;
                  'Error #: ' + TRANSFORM(nenumber) + CHR(10) + ;
                  'Error Msg: ' + ALLTRIM(cmessage) +  CHR(10) + ;
                  'User: ' + cuser + CHR(10) + ;
                  '**************************************' + CHR(10)
               lnCount = lnCount + 1
               IF lnCount > 20
                  EXIT
               ENDIF
            ENDSCAN

* If using outlook options send line feeds as html <br>
* Otherwise insert a real linefeed.
            IF options.lUseOutlook
               lcLF = "<br>"
            ELSE
               lcLF = CHR(10)
            ENDIF

            lcSubject = ALLTRIM(lcCompany) + ' Error Log'

            oSendMail.cBody         = lcBody
            oSendMail.cTo           = 'support@sherware.com'
            oSendMail.cSubject      = lcSubject
            oSendMail.cEmailServer  = options.cEmailServer
            oSendMail.cEmailAddress = options.cEmailAddress
            oSendMail.cReplyTo      = 'support@sherware.com'
            oSendMail.cEmailUser    = options.cEmailUser
            oSendMail.cEmailPass    = options.cEmailPass
            oSendMail.lOutlook      = options.lUseOutlook
            oSendMail.lUseSSL       = options.lUseSSL
            oSendMail.nSMTPPort     = options.nSMTPPort
            oSendMail.cSender       = lcCompany
            WAIT WINDOW NOWAIT 'Submitting case to support...Please wait'
            llResult = oSendMail.SendMail()
            WAIT CLEAR
            IF !llResult
               MESSAGEBOX('Unable to Send Email. Try Again Later.' + CHR(10) + ;
                    oSendMail.cErrorMsg, 16, 'View System Log')
            ELSE
               MESSAGEBOX('System Log Submitted.', 64, 'View System Log')
            ENDIF
         CATCH TO loerror
            MESSAGEBOX('Unable to submit your system log by email. Message = ' + loerror.MESSAGE, 48, 'View System Log')
         ENDTRY
      ENDIF

      llCleared = .T.

      IF NOT llUseError
         IF MESSAGEBOX('Do you wish to clear the error log at this time?', 36, 'View System Log') = 6
            TRY
               SET SAFETY OFF
               USE IN errorlog
               USE (m.goapp.cCommonFolder + 'errorlog') IN 0 EXCL
               SELECT errorlog
               ZAP
               USE IN errorlog
            CATCH
               llCleared = .F.
            ENDTRY
            IF NOT llCleared
               IF NOT USED('errorlog')
                  USE (m.goapp.cCommonFolder + 'errorlog') IN 0
                  SELECT errorlog
                  DELETE ALL
                  llCleared = .T.
               ENDIF
            ENDIF 
         ENDIF
      ENDIF
   ELSE
      MESSAGEBOX('There are no entries in the system log to be listed', 64, 'View System Log')
   ENDIF

   swclose('errorlog')

CATCH TO loerror
   llReturn = .F.
*   DO errorlog WITH 'ErrorPrint', loerror.LINENO, 'View System Log', loerror.ERRORNO, loerror.MESSAGE
*   MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   IF llCleared
      MESSAGEBOX('Unable to view the system log at this time.', 64, 'View System Log')
   ELSE
      MESSAGEBOX('Unable to clear the system log at this time',64,'Clear System Log')
   ENDIF    
ENDTRY

RETURN llReturn



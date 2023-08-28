LPARAMETERS tcMethod, tnLine, tcCaller, tnError, tcMessage, tcDetails, tlQBSDKLog, tcLogLocation, tlDupes, tlNoProblems
LOCAL llResult, oSendMail, lcTime, lcVersion, lcDate, lcSubject, lcBody, lcCompany, lcClient, llReturn
#DEFINE cr_lf CHR(13)+CHR(10)

TRY

   * Don't send the email if the nosend.txt file exists
   IF NOT tlDupes AND FILE('datafiles\nosend.txt')
      llReturn = .F.
      EXIT
   ENDIF

   swselect('options')

   oSendMail = CREATEOBJECT('swSendMail')

   lcClient  = m.goApp.cClient
   lcCompany = m.goApp.cRegCompany
   lcRegCode = m.goApp.cCode
   lcVersion = m.goApp.cFileVersion
   lcDate    = DTOC(FDATE(ALLTRIM(m.goApp.cexecutable)))
   lcTime    = FTIME(ALLTRIM(m.goApp.cexecutable))
   lnx       = ASTACKINFO(laStack)

   * If using outlook options send line feeds as html <br>
   * Otherwise insert a real linefeed.
   IF options.lUseOutlook
      lcLF = "<br>"
   ELSE
      lcLF = CHR(10)
   ENDIF

   lcBody = 'Company: ' + lcCompany + cr_lf ;
      + 'Client ID: ' + lcClient + cr_lf ;
      + 'Registration Code: ' + lcRegCode + cr_lf ;
      + 'Software: ' + cr_lf ;
      + ALLTRIM(m.goApp.cexecutable) + ' Version: ' + lcVersion + '  ' + ;
      + lcDate    + '  ' + ;
      + lcTime    + cr_lf + cr_lf ;
      + IIF(m.goApp.lQBVersion,'QBFC Version: ' + m.goApp.oqb.qbfcversion + cr_lf + 'SDK Version: ' + m.goApp.oqb.sdkversion + cr_lf,'') + ;
      + IIF(tlQBSDKLog,'QBSDKLOG ATTACHED BELOW...','') + cr_lf + cr_lf ;
      + tcDetails

   IF NOT tlDupes
      lcSubject               = 'Auto Submit - Error: ' + TRANSFORM(tnError) + ' in ' + ALLTRIM(tcMethod) + ' of ' + ALLTRIM(tcCaller)
   ELSE
      IF NOT tlNoProblems
         lcSubject               = 'Duplicate Utility Ran for Company: ' + ALLTRIM(m.goApp.cCompanyName)
      ELSE
         lcSubject               = 'No Duplicate Suspense Found for Company: ' + ALLTRIM(m.goApp.cCompanyName)
      ENDIF    
   ENDIF

   oSendMail.cBody         = lcBody
   oSendMail.cTo           = 'phil@sherware.com'
   oSendMail.cSubject      = lcSubject

   IF tlDupes
      oSendMail.cEmailServer  = 'smtp.gmail.com'
      oSendMail.cEmailAddress = 'support@sherware.com'
      oSendMail.cEmailPass    = '$herW@re1994'
      oSendMail.cReplyTo      = 'no-reply@sherware.com'
   ELSE
      oSendMail.cEmailServer  = options.cEmailServer
      oSendMail.cEmailAddress = options.cEmailAddress
      oSendMail.cReplyTo      = options.cEmailAddress
      oSendMail.cEmailUser    = options.cEmailUser
      oSendMail.cEmailPass    = options.cEmailPass
      oSendMail.lOutlook      = options.lUseOutlook
      oSendMail.lUseSSL       = options.lUseSSL
      oSendMail.nSMTPPort     = options.nSMTPPort

      IF EMPTY(oSendMail.cReplyTo)
         IF NOT USED('compmast')
            USE (m.goApp.cCommonFolder+'compmast') IN 0
         ENDIF
         SELECT compmast
         LOCATE FOR cidcomp = m.goApp.cidcomp
         IF FOUND() AND NOT EMPTY(compmast.cemail)
            oSendMail.cReplyTo = compmast.cemail
         ELSE
            oSendMail.cReplyTo = 'info@sherware.com'
         ENDIF
      ENDIF
   ENDIF

   oSendMail.cSender       = ALLTRIM(lcCompany)

   * Attach the qbsdklog file if it's a QB error
   IF tlQBSDKLog
      oSendMail.cAttachment = tcLogLocation
   ENDIF

   WAIT WINDOW NOWAIT 'Submitting support case to SherWare support...Please wait'
   llResult = oSendMail.SendMail(.T.,.T.)
   WAIT CLEAR
CATCH TO loError
   llReturn = .F.
   *DO errorlog WITH 'SendError', loError.LINENO, tcMethod, loError.ERRORNO, loError.MESSAGE, '', loError
ENDTRY

RETURN



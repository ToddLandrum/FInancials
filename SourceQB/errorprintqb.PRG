*
*  Prints the error log listing
*


LOCAL lcLF, lcRegCode, lcTitle1, lcTitle2, lnCount, loerror
*:Global cProducer, oMessage

#define cr_lf CHR(13)+CHR(10)

oMessage = findglobalobject('cmMessage')

IF TYPE('m.goApp') <> 'O'
   m.cProducer = 'Development Company'
ELSE
   m.cProducer = m.goApp.cCompanyName
ENDIF

lcTitle1 = ''
lcTitle2 = ''
SET DELETED ON
IF NOT USED('errorlog')
   IF FILE(m.goapp.cCommonFolder+'errorlog.dbf')
      USE (m.goapp.cCommonFolder+'errorlog') IN 0 EXCL
   ELSE
      oMessage.DISPLAY('There are no errors in the error log to be listed')
      return
   ENDIF          
ENDIF

SELECT errorlog

IF TYPE('errorlog.cversion') <> 'C'
   ALTER TABLE errorlog ADD COLUMN cVersion C(10)
ENDIF   
IF TYPE('errorlog.csdkver') <> 'C'
   ALTER TABLE errorlog ADD COLUMN csdkVer C(5)
ENDIF   
IF TYPE('errorlog.cqbfcver') <> 'C'
   ALTER TABLE errorlog ADD COLUMN cqbfcVer C(5)
ENDIF   

COUNT FOR NOT DELETED() TO lnCount

IF lnCount > 0
   SELECT * FROM errorlog INTO CURSOR errorprint ;
     ORDER BY dedate descending, cetime descending 

   REPORT FORM errorlogqb TO PRINTER PROMPT PREVIEW

   IF oMessage.CONFIRM('Would you like to email this error log to SherWare Support now?')
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

         lcBody = 'Company: ' + lcCompany + CR_LF ;
            + 'Registration Code: ' + lcRegCode + CR_LF ;
            + 'Software: ' + CR_LF ;
            + ALLTRIM(m.goapp.cexecutable) + ' Version: ' + lcVersion + '  ' + ;
            + lcDate    + '  ' + ;
            + lcTime    + CR_LF + CR_LF
 
         lnCount = 0
         SELECT errorprint
         SCAN
            SCATTER MEMVAR

            lcBody = lcBody + 'Date: ' +DTOC(dedate) + '  ' + cetime + cr_lf + ;
              'Program: ' + ALLTRIM(ccaller) + cr_lf + ;
              'Method: ' + ALLTRIM(cmethod) + cr_lf + ;
              'Line: ' + TRANSFORM(nlineno) + cr_lf + ;
              'Error #: ' + TRANSFORM(nenumber) + cr_lf +;
              'Error Msg: ' + ALLTRIM(cmessage) +  cr_lf + ;
              'User: ' + cuser + cr_lf+ ;
              '**************************************' + cr_LF
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
            oMessage.warning('Unable to Send Email. Try Again Later.' + CHR(10) + ;
               oSendMail.cErrorMsg)
         ELSE
            MESSAGEBOX('Error Log Submitted.',64, 'Error Log Submission')
         ENDIF
      CATCH TO loerror
         MESSAGEBOX('Unable to submit your error log by email. Error = ' + loerror.MESSAGE,48,'Email Submit Error')
      ENDTRY
   ENDIF
   
   IF oMessage.CONFIRM('Do you wish to clear the error log at this time?')
      SET SAFETY OFF
      SELECT errorlog
      ZAP
      USE IN errorlog
   ENDIF
ELSE
   oMessage.DISPLAY('There are no errors in the error log to be listed')
ENDIF

IF USED('errorlog')
   USE IN errorlog
ENDIF
 
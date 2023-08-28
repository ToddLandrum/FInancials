LPARAMETERS tcAuthName, tcTitle
LOCAL lcLibrary, lcYear, lnTotalRecs
LOCAL loIP AS 'wwftp'
LOCAL lcFile99, lcFileName, lcFileVer, lcSourceFile, lcState99, lcTargetFile, lcTemp, llReturn
LOCAL lnResult, loError
*:Global tcYear
#DEFINE CRLF CHR(13) + CHR(10)

llReturn = .T.

TRY
   lcLibrary = SET('library')

   lcTemp = SYS(2023)

   swselect('tax1099')
   SET ORDER TO cYear DESC
   GO TOP
   tcYear = cYear

   IF MESSAGEBOX('This utility will upload your 1099 data for ' + tcyear + ' to SherWare in order for it to be electronically transmitted to the IRS. ' + ;
           'This service is provided by SherWare for a fee of $125 per company and $25 per State.' + CRLF  + CRLF + ;
           'Do you want to continue?', 36, '1099 Upload') = 7
      llReturn = .F.
      EXIT
   ENDIF

SET SAFETY OFF 
   swselect('tax1099')
   COPY TO (lcTemp + '\ten99file.dbf') FOR cYear = tcYear
   COUNT FOR cYear = tcYear TO lnTotalRecs
   swselect('version')
   COPY TO (lcTemp + '\ver99file.dbf')
   swselect('tax1099st')
   COPY TO (lcTemp + '\ten99state.dbf') FOR cYear = tcYear

   CREATE TABLE (lcTemp+'\ten99comp.dbf') FREE  ;
      (cCompany        c(60), ;
       caddress1       c(60), ;
       caddress2       c(60), ;
       caddress3       c(60), ;
       ccity           c(40), ;
       cstate          c(2), ;
       czip            c(10), ;
       ctaxid          c(20), ;
       cphone          c(15), ;
       ccontact        c(40), ;
       cAuthName       c(60), ;
       cTitle          c(25), ;
       dAuthDate       D)
    
   m.ccompany = m.goapp.ccompanyname
   m.caddress1 = m.goapp.caddress1
   m.caddress2 = m.goapp.caddress2
   m.caddress3 = m.goapp.caddress3
   m.ccity = m.goapp.ccity
   m.cstate = m.goapp.cstate
   m.czip = m.goapp.czip
   m.ccontact = m.goapp.ccontact
   m.ctaxid = m.goapp.ctaxid
   m.cAuthName = tcAuthName
   m.dAuthDate = DATE()
   m.cTitle    = tcTitle
   IF VARTYPE(m.caddress1) # 'C'
      m.caddress1 = ''
   ENDIF 
   IF VARTYPE(m.caddress2) # 'C'
      m.caddress2 = ''
   ENDIF 
   IF VARTYPE(m.caddress3) # 'C'
      m.caddress3 = ''
   ENDIF 
   IF VARTYPE(m.ccity) # 'C'
      m.ccity = ''
   ENDIF 
   IF VARTYPE(m.cstate) # 'C'
      m.cstate = ''
   ENDIF 
   IF VARTYPE(m.czip) # 'C'
      m.czip = ''
   ENDIF 
   IF VARTYPE(m.ccontact) # 'C'
      m.ccontact = ''
   ENDIF 
   IF VARTYPE(m.cauthname) # 'C'
      m.cauthname = ''
   ENDIF 
   IF VARTYPE(m.ctitle) # 'C'
      m.ctitle = ''
   ENDIF 
   INSERT INTO ten99comp FROM memvar
   USE IN ten99comp
       
   IF FILE(lcTemp + '\ten99file.dbf')

      lcFileName = ALLT(STRTRAN(LOWER(m.goApp.ccompanyname), ' ', ''))
      lcFileName = STRTRAN(lcFileName, ',', '')
      lcFileName = STRTRAN(lcFileName, '.', '')
      lcFileName = STRTRAN(lcFileName, '-', '')
      lcFileName = STRTRAN(lcFileName, '#', '')
      lcFileName = STRTRAN(lcFileName, '&', '')
      lcFileName = STRTRAN(lcFileName, '\', '')
      lcFileName = STRTRAN(lcFileName, '/', '')
      lcFileName = STRTRAN(lcFileName, '?', '')
      lcFileName = STRTRAN(lcFileName, "'", '')
      lcFileName = STRTRAN(lcFileName, ' ', '')
      lcFile99   = lcFileName + '_' + tcYear + '.dbf'
      lcFileVer  = lcFileName + '_VER_' + tcYear + '.dbf'
      lcState99  = lcFileName + '_State_' + tcYear + '.dbf'
      lcComp99   = lcFileName + '_CompInfo.dbf'

      loIP             = CREATEOBJECT('swftp')
      loIP.lPassiveFTP = .T.
      loIP.cServer     = 'backups.sherware.com'
      loIP.cUser       = 'backups'
      loIP.cPwd        = '2AQqJ92'
      loIP.CONNECT()
      lcSourceFile     = lcTemp + '\ten99file.dbf'
      lcTargetFile     = '1099files\' + lcFile99
      loIP.cSourceFile = lcSourceFile
      loIP.cTargetFile = lcTargetFile
      llReturn         = loIP.SendFile()

*!*	      IF llReturn
*!*	         loIP             = CREATEOBJECT('swftp')
*!*	         loIP.lPassiveFTP = .T.
*!*	         loIP.cServer     = 'backups.sherware.com'
*!*	         loIP.cUser       = 'backups'
*!*	         loIP.cPwd        = '2AQqJ92'
*!*	         loIP.CONNECT()
*!*	         lcSourceFile     = lcTemp + '\ver99file.dbf'
*!*	         lcTargetFile     = '1099files\' + lcFileVer
*!*	         loIP.cSourceFile = lcSourceFile
*!*	         loIP.cTargetFile = lcTargetFile
*!*	         llReturn         = loIP.SendFile()
*!*	      ENDIF

      IF llReturn
         loIP             = CREATEOBJECT('swftp')
         loIP.lPassiveFTP = .T.
         loIP.cServer     = 'backups.sherware.com'
         loIP.cUser       = 'backups'
         loIP.cPwd        = '2AQqJ92'
         loIP.CONNECT()
         lcSourceFile     = lcTemp + '\ten99state.dbf'
         lcTargetFile     = '1099files\' + lcState99
         loIP.cSourceFile = lcSourceFile
         loIP.cTargetFile = lcTargetFile
         llReturn         = loIP.SendFile()
      ENDIF
      
      IF llReturn
         loIP             = CREATEOBJECT('swftp')
         loIP.lPassiveFTP = .T.
         loIP.cServer     = 'backups.sherware.com'
         loIP.cUser       = 'backups'
         loIP.cPwd        = '2AQqJ92'
         loIP.CONNECT()
         lcSourceFile     = lcTemp + '\ten99comp.dbf'
         lcTargetFile     = '1099files\' + lcComp99
         loIP.cSourceFile = lcSourceFile
         loIP.cTargetFile = lcTargetFile
         llReturn         = loIP.SendFile()
      ENDIF


      IF NOT llReturn
         MESSAGEBOX("Unable to upload your 1099 data at this time. Please try again. If the problem persists, " + ;
              "please contact SherWare Support with the following information:" + CHR(10) + loIP.cerrormsg, 16, 'Upload 1099 Problem')
      ELSE
         MESSAGEBOX('Transmit of ' + tcYear + ' 1099 data to SherWare was successful!' + CRLF + ;
              'Uploaded ' + TRANSFORM(lnTotalRecs) + ' 1099 records.', 48, 'Transmit 1099s')
      ENDIF
   ENDIF
   WAIT CLEAR

   SET LIBRARY TO &lcLibrary
CATCH TO loError
   llReturn = .F.
   DO errorlog WITH 'Ten99Upload', loError.LINENO, 'Upload 1099s', loError.ERRORNO, loError.MESSAGE, '', loError
   MESSAGEBOX('Unable to process the 1099 upload at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
        'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn






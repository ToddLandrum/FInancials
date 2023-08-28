********************************************************************************
DEFINE CLASS swregcode AS CUSTOM
********************************************************************************
   lfileopen   = .F.
   cclient     = ''
   ccode       = ''
   cregcompany = ''
   cregpath    = ''
   cstates     = ''

********************************************************************************
   PROTECTED PROCEDURE INIT
********************************************************************************
      LPARAMETERS tcPath

      IF VARTYPE(tcPath) # 'C'
         THIS.cregpath = SYS(5) + CURDIR() + 'datafiles\'
      ELSE
         THIS.cregpath = ADDBS(tcPath)
      ENDIF

   ENDPROC

********************************************************************************
   FUNCTION GetOpt
********************************************************************************
      LPARAMETERS noption, tlNoisy
      LOCAL lnclient, lncode

      IF m.noption > 32
         MESSAGEBOX('GetOpt: Invalid option passed. Must be less than 32.')
         RETURN
      ENDIF
      lnclient = THIS.getcode(1)
      IF lnclient = 9191
         MESSAGEBOX('Unable to read registration code file.')
         RETURN
      ENDIF
      lccode = THIS.getcode(2)
      IF lccode = '9191'
         MESSAGEBOX('Unable to read registration code file.')
         RETURN
      ENDIF
      IF THIS.checksum(lnclient, lccode)
         lncode   = THIS.checksum(lnclient, lccode, .T.)
         lncode   = INT((lncode - lnclient) / lnclient)
         llreturn = BITTEST(lncode, m.noption)
         RETURN (llreturn)
      ELSE
         IF tlNoisy
            MESSAGEBOX('This is an invalid registration code.', 0, 'Bad Registration Code')
         ENDIF
         RETURN .F.
      ENDIF
   ENDFUNC

********************************************************************************
   FUNCTION getcode
********************************************************************************
      LPARAMETERS ntype
      LOCAL lnfile, lcclient, lccode, lnclient, lncode, lcStates

* Parameter nType
*  1 = Client Code
*  2 = Reg Code
*  3 = Company Name
*  4 = State Codes

      lcStates = ''

      IF THIS.lfileopen = .F.
         lnfile = FOPEN(THIS.cregpath + 'swconfig.cfg')
         IF lnfile > 0
            THIS.lfileopen = .T.
            lcclient       = FREAD(lnfile, 4)
            lnloc          = FSEEK(lnfile, 4)
            lccompany      = FREAD(lnfile, 40)
            lnloc          = FSEEK(lnfile, 44)
            lccode         = FREAD(lnfile, 4096)

            IF '*' $ lccode
               lcStates = SUBSTR(lccode, AT('*', lccode) + 1)
               lccode   = SUBSTR(lccode, 1, AT('*', lccode) - 1)
            ELSE
               lcStates = ''
            ENDIF

            THIS.cclient     = lcclient
            THIS.ccode       = lccode
            THIS.cregcompany = lccompany
            THIS.cstates     = lcStates
         ELSE
            = FCLOSE(lnfile)
            THIS.cclient = '9191'
            THIS.ccode   = '9191'
         ENDIF
      ENDIF
      lnclient = INT(VAL(THIS.cclient))
      lccode   = ALLTRIM(THIS.ccode)
      = FCLOSE(lnfile)
      DO CASE
         CASE ntype = 1
            RETURN (lnclient)
         CASE ntype = 2
            RETURN (lccode)
         CASE ntype = 3
            RETURN (THIS.cregcompany)
         CASE ntype = 4
            RETURN THIS.cstates
      ENDCASE
      RETURN 0
   ENDFUNC

********************************************************************************
   FUNCTION WriteCode
********************************************************************************
      LPARAMETERS nclient, ccode, ccompany
      LOCAL lnfile, lcclient, lccode, lnclient, lncode, lnbytes, llsuccess, lccompany
      lccode    = m.ccode
      lcclient  = TRANSFORM(m.nclient)
      lccompany = PADR(ALLTRIM(m.ccompany), 40, ' ')

      IF  .NOT. FILE(THIS.cregpath + 'swconfig.cfg')
         m.lnewfile = .T.
      ELSE
         m.lnewfile = .T.
         ERASE (THIS.cregpath + 'swconfig.cfg')
      ENDIF
      IF m.lnewfile
         lnfile    = FCREATE(THIS.cregpath + 'swconfig.cfg')
         llsuccess = lnfile > 0
      ELSE
         lnfile    = FOPEN(THIS.cregpath + 'swconfig.cfg', 12)
         llsuccess = lnfile > 0
      ENDIF
      IF llsuccess
         lnbytes = FWRITE(lnfile, lcclient + lccompany + lccode)
         lnerror = FERROR()
         IF lnerror # 0
            DO CASE
               CASE lnerror = 2
                  MESSAGEBOX('The registration code file was not found. Please contact SherWare support.', 0, 'Registration Code Problem')
               CASE lnerror = 5
                  MESSAGEBOX('Unable to open the registration code file. Please contact SherWare support.', 0, 'Registration Code Problem')
               CASE lnerror = 8
                  MESSAGEBOX('Memory problem while writing to the registration code file. Please contact SherWare support.', 0, 'Registration Code Problem')
               CASE lnerror = 29
                  MESSAGEBOX('Disk Full error while writing to the registration code file. Please contact SherWare support.', 0, 'Registration Code Problem')
               OTHERWISE
                  MESSAGEBOX('Undetermined error while writing to the registration code file. Please contact SherWare support.', 0, 'Registration Code Problem')
            ENDCASE
         ENDIF
      ENDIF
      = FCLOSE(lnfile)
      RETURN (llsuccess)
   ENDFUNC

********************************************************************************
   FUNCTION GetOptFromCode
********************************************************************************
      LPARAMETERS noption, nclient, ccode, tlNoisy
      LOCAL lnclient, lncode
      IF m.noption > 32
         MESSAGEBOX('GetOpt: Invalid option passed. Must be less than 32.')
         RETURN
      ENDIF
      lnclient = m.nclient
      IF THIS.checksum(m.nclient, m.ccode)
         lncode = THIS.checksum(m.nclient, m.ccode, .T.)
      ELSE
         IF tlNoisy
            MESSAGEBOX('GetOptFromCode: This is an invalid registration code.', 0, 'Bad Registration Code')
         ENDIF
         RETURN .F.
      ENDIF
      lncode   = INT((lncode - lnclient) / lnclient)
      llreturn = BITTEST(lncode, m.noption)
      RETURN (llreturn)
   ENDFUNC

********************************************************************************
   FUNCTION checksum
********************************************************************************
      LPARAMETERS nclient, ccode, lreturncode, lreturndate
      LOCAL lccode, lnlength, lnchksum, lnchksum1, lcchksum
      lccode    = STRTRAN(m.ccode, '-', '')
      lnchksum1 = 0
      lnlength  = LEN(lccode)
      lcchksum  = SUBSTR(lccode, lnlength - 1, 2) + SUBSTR(lccode, 1, 1)
      lnchksum  = INT(VAL(lcchksum))
      DO CASE
         CASE m.lreturncode
            lccode = SUBSTR(lccode, 2, lnlength - 3)
            lccode = SUBSTR(lccode, 3, 4) + SUBSTR(lccode, 9, 4) + SUBSTR(lccode, 15)
            RETURN (INT(VAL(lccode)))
         CASE m.lreturndate
            lccode = SUBSTR(lccode, 2, lnlength - 3)
            lddate = CTOD(SUBSTR(lccode, 13, 2) + '/' + SUBSTR(lccode, 1, 2) + '/20' + SUBSTR(lccode, 7, 2))
            RETURN (lddate)
         OTHERWISE
            FOR lnx = 2 TO lnlength - 2
               lnchksum1 = lnchksum1 + INT(VAL(SUBSTR(lccode, lnx, 1)))
            ENDFOR
            IF lnchksum1 # lnchksum
               RETURN .F.
            ELSE
               RETURN .T.
            ENDIF
      ENDCASE
   ENDFUNC

********************************************************************************
   FUNCTION ServerIsAvailable(tcUrlToCheck)
********************************************************************************
      LOCAL llreturn
      m.llreturn = .T.
      IF NOT DIRECTORY(tcUrlToCheck) && First check if it is a directory path, if not then assume it is an URL
         DECLARE INTEGER InternetCheckConnection IN wininet;
            STRING lpszUrl, ;
            INTEGER dwFlags, ;
            INTEGER dwReserved
         IF InternetCheckConnection(m.tcUrlToCheck, 1, 0) # 1
            m.llreturn = .F.
         ENDIF
      ENDIF
      RETURN m.llreturn
   ENDFUNC

********************************************************************************
   FUNCTION GetSupportStatus(tcClientid)
********************************************************************************
* Looks for a file at http://support.sherware.com/monthly/support-xxxx.txt that
* contains the xxxx client id's monthly support expiration date. If the file
* doesn't exist an expiration date of 12/31 of the current year is assumed.
      LOCAL lcDate, lcSupportStatus, lcSupportURL, lcYear

      lcYear = TRANSFORM(YEAR(DATE()))
      lcDate = '12/31/' + lcYear

      DECLARE INTEGER URLDownloadToFile IN urlmon.DLL;
         INTEGER pCaller, ;
         STRING  szURL, ;
         STRING  szFileName, ;
         INTEGER dwReserved, ;
         INTEGER lpfnCB

      lcSupportURL    = 'http://support.sherware.com/monthly/support-' + ALLTRIM(tcClientid) + '.txt'
      lcSupportStatus = ADDBS(SYS(2023)) + SYS(2015) + '.txt' && temporary file created locally so expiration date can be saved

* Get the support expiration for the given client
      URLDownloadToFile(0, lcSupportURL + '?fakevariable=' + SYS(2015), lcSupportStatus, 0, 0)

      IF FILE(lcSupportStatus)
         lcDate = TRANSFORM(FILETOSTR(lcSupportStatus)) && Expiration date for support
      ENDIF

      RETURN lcDate

   ENDFUNC
********************************************************************************
   FUNCTION GetLicenseStatus(tcClientid)
********************************************************************************
* Looks for a file at http://support.sherware.com/licenses/xxxx.txt that
* contains the xxxx client id's monthly license expiration date. If the file
* doesn't exist an expiration date of 12/31 of the current year is assumed.
      LOCAL lcDate, lcLicenseStatus, lcLicenseURL, lcYear

      lcYear = TRANSFORM(YEAR(DATE()))
      lcDate = '12/31/' + lcYear

      DECLARE INTEGER URLDownloadToFile IN urlmon.DLL;
         INTEGER pCaller, ;
         STRING  szURL, ;
         STRING  szFileName, ;
         INTEGER dwReserved, ;
         INTEGER lpfnCB

      lcLicenseURL    = 'http://support.sherware.com/licenses/' + ALLTRIM(tcClientid) + '.txt'
      lcLicenseStatus = ADDBS(SYS(2023)) + SYS(2015) + '.txt' && temporary file created locally so expiration date can be saved

* Get the support expiration for the given client
      URLDownloadToFile(0, lcLicenseURL + '?fakevariable=' + SYS(2015), lcLicenseStatus, 0, 0)

      IF FILE(lcLicenseStatus)
         lcDate = TRANSFORM(FILETOSTR(lcLicenseStatus)) && Expriation Date of the license
      ENDIF

      RETURN lcDate

   ENDFUNC

***************************************************
   PROCEDURE RenewCode
***************************************************
      LPARAMETERS tlMenu
      LOCAL lccode, lnclient, lnMultiple, x
      DIMENSION optionarray[32, 2]

* Get the current code
      lccode   = THIS.getcode(2)
      lcStates = THIS.getcode(4)
      lnlength = LEN(ALLTRIM(lccode))

      IF lccode # '9191'
         lnclient = THIS.getcode(1)
* Get the support expiration date
         ldExpDate = THIS.checksum(lnclient, lccode, .F., .T.)
         lcExpires = DTOC(ldExpDate)
         lcExpires = STRTRAN(RIGHT(lcExpires, 4) + LEFT(lcExpires, 5), '/', '')
         lcclient  = TRANSFORM(lnclient)
         lcDate    = THIS.GetNewExpireDate(lcclient, lcExpires)
         lcNewDate = STRTRAN(RIGHT(lcDate, 4) + LEFT(lcDate, 5), '/', '')

* Only update the regcode if the expiration date on the web is greater than the current expiration date
         IF lcNewDate > lcExpires
* Parse the code to get the real code. The code format has the expiration date and client id embedded.
            lccode     = SUBSTR(lccode, 2, lnlength - 3)
            lcOldCode1 = SUBSTR(lccode, 3, 4)
            lcOldCode2 = SUBSTR(lccode, 9, 4)
            lcOldCode3 = SUBSTR(lccode, 15)

            lcDay   = SUBSTR(lcDate, 4, 2)
            lcMonth = SUBSTR(lcDate, 1, 2)
            lcYear  = SUBSTR(lcDate, 9, 2)

            lccode = lcDay + lcOldCode1 + lcYear + lcOldCode2 + lcMonth + lcOldCode3

* Add all the digits together to get a checksum
            lnchksum = 0
            lnlength = LEN(lccode)
            FOR lnx = 1 TO lnlength
               lnchksum = lnchksum + INT(VAL(SUBSTR(lccode, lnx, 1)))
            ENDFOR

* Pad the checksum to 3 digits with leading zeros
            lcchksum = PADL(TRANSFORM(lnchksum), 3, '0')

* Prepend the first digit of the checksum to the code
* Append the last two digits of the checksum to the code
            lccode = SUBSTR(lcchksum, 3, 1) + lccode + SUBSTR(lcchksum, 1, 2)
            lccode = ALLTRIM(lccode) + '*' + lcStates

            IF THIS.WriteCode(lnclient, lccode, THIS.cregcompany)
               MESSAGEBOX('Your Registration Code has been updated with a new expiration date of: ' + CHR(13) + CHR(13) + ;
                    lcDate + '!', 48, 'Update Registration Code')
               THIS.UpdateRegCode(lcclient, lccode)
            ENDIF
         ELSE
            IF tlMenu
               MESSAGEBOX('Your Registration Code is the most current one for your subscription.', 64, 'Update Registration Code')
            ENDIF
         ENDIF
      ENDIF

*********************************************
   FUNCTION GetNewExpireDate(tcclient, tcExpDate)
*********************************************

      DECLARE INTEGER URLDownloadToFile IN urlmon.DLL;
         INTEGER pCaller, ;
         STRING  szURL, ;
         STRING  szFileName, ;
         INTEGER dwReserved, ;
         INTEGER lpfnCB

      llreturn   = .T.
      lcNewsFile = ADDBS(SYS(2023)) + SYS(2015) + '.txt' && temporary file created locally so server version can be read
      lcNewsURL  = 'http://support.sherware.com/expiredate.sw?cid=' + ALLTRIM(tcclient) + '&fakevariable=' + SYS(2015)

      URLDownloadToFile(0, lcNewsURL, lcNewsFile, 0, 0)
      IF FILE(lcNewsFile)
         lcDate = FILETOSTR(lcNewsFile)
      ELSE
         lcDate = tcExpireDate
      ENDIF

      RETURN lcDate

*********************************************
   FUNCTION UpdateRegCode(lcclient, lccode)
*********************************************

      DECLARE INTEGER URLDownloadToFile IN urlmon.DLL;
         INTEGER pCaller, ;
         STRING  szURL, ;
         STRING  szFileName, ;
         INTEGER dwReserved, ;
         INTEGER lpfnCB

      llreturn   = .T.
      lcNewsFile = ADDBS(SYS(2023)) + SYS(2015) + '.txt' && temporary file created locally so server version can be read
      lcNewsURL  = 'http://support.sherware.com/saveregcode.sw?cid=' + ALLTRIM(lcclient) + '&regcode=' + lccode

      URLDownloadToFile(0, lcNewsURL, lcNewsFile, 0, 0)


********************************************************************************
   FUNCTION GetSFOpt
********************************************************************************
      LPARAMETERS noption, tlNoisy
      LOCAL lnclient, lncode

      IF m.noption > 32
         MESSAGEBOX('GetOpt: Invalid option passed. Must be less than 32.')
         RETURN
      ENDIF
      lnclient = THIS.GetSFCode(1)
      IF lnclient = 9191
         MESSAGEBOX('Unable to read registration code file.')
         RETURN
      ENDIF
      lccode = THIS.GetSFCode(2)
      IF lccode = '9191'
         MESSAGEBOX('Unable to read registration code file.')
         RETURN
      ENDIF
      IF THIS.sfchecksum(lnclient, lccode)
         lncode   = THIS.sfchecksum(lnclient, lccode, .T.)
         lncode   = INT((lncode - lnclient) / lnclient)
         llreturn = BITTEST(lncode, m.noption)
         RETURN (llreturn)
      ELSE
         IF tlNoisy
            MESSAGEBOX('This is an invalid registration code.', 0, 'Bad Registration Code')
         ENDIF
         RETURN .F.
      ENDIF
   ENDFUNC

********************************************************************************
   FUNCTION GetSFCode
********************************************************************************
      LPARAMETERS tntype, tcCode
      LOCAL lnfile, lcclient, lccode, lnclient, lncode, lcStates
      LOCAL lnWells, lnUsers, lnTrans

      STORE 0 TO lnWells, lnUsers, lnTrans, lnCompanies

* Parameter nType
*  1 = Client Code
*  2 = Reg Code
*  3 = Company Name
*  4 = # of Wells
*  5 = # of Users
*  6 = # of Trans
*  7 = # of Companies

      lcStates = ''
      IF VARTYPE(tcCode) = 'C'
         lcclient         = SUBSTR(tcCode, 1, 4)
         lccompany        = SUBSTR(tcCode, 5, 40)
         lccode           = SUBSTR(tcCode, 45)
         THIS.cclient     = lcclient
         THIS.ccode       = lccode
         THIS.cregcompany = lccompany

* Remove Checksum
         lnlength = LEN(lccode)
         lccode   = SUBSTR(lccode, 2, lnlength - 3)

* Get Wells, Users and Trans
         lnWells     = INT(VAL(SUBSTR(lccode,  1, 4)))  - 555
         lnUsers     = INT(VAL(SUBSTR(lccode,  9, 4)))  - 209
         lnTrans     = INT(VAL(SUBSTR(lccode, 17, 4)))  - 1502
         lnCompanies = INT(VAL(SUBSTR(lccode, 25, 4)))  - 1234

         IF lnTrans = 8497
            lnTrans = 9999
         ENDIF

      ELSE
         IF THIS.lfileopen = .F.
            lnfile = FOPEN(THIS.cregpath + 'swconfig.cfg')
            IF lnfile > 0
               lcclient         = FREAD(lnfile, 4)
               lnloc            = FSEEK(lnfile, 4)
               lccompany        = FREAD(lnfile, 40)
               lnloc            = FSEEK(lnfile, 44)
               lccode           = FREAD(lnfile, 4096)
               lccode           = STRTRAN(lccode, '-', '')
               THIS.cclient     = lcclient
               THIS.ccode       = lccode
               THIS.cregcompany = lccompany

* Remove Checksum
               lnlength = LEN(lccode)
               lccode   = SUBSTR(lccode, 2, lnlength - 3)

* Get Wells, Users and Trans
               lnWells     = INT(VAL(SUBSTR(lccode,  1, 4)))  - 555
               lnUsers     = INT(VAL(SUBSTR(lccode,  9, 4)))  - 209
               lnTrans     = INT(VAL(SUBSTR(lccode, 17, 4)))  - 1502
               lnCompanies = INT(VAL(SUBSTR(lccode, 25, 4)))  - 1234

               IF lnTrans = 8497
                  lnTrans = 9999
               ENDIF

            ELSE
               = FCLOSE(lnfile)
               THIS.cclient = '9191'
               THIS.ccode   = '9191'
            ENDIF
         ENDIF
         = FCLOSE(lnfile)
      ENDIF

      lnclient = INT(VAL(THIS.cclient))
      lccode   = ALLTRIM(THIS.ccode)

      DO CASE
         CASE tntype = 1
            RETURN (lnclient)
         CASE tntype = 2
            RETURN (lccode)
         CASE tntype = 3
            RETURN (THIS.cregcompany)
         CASE tntype = 4
            RETURN lnWells
         CASE tntype = 5
            RETURN lnUsers
         CASE tntype = 6
            RETURN lnTrans
         CASE tntype = 7
            RETURN lnCompanies

      ENDCASE
      RETURN 0
   ENDFUNC


********************************************************************************
   FUNCTION sfchecksum
********************************************************************************
      LPARAMETERS tnclient, tcCode, tlreturncode, tlreturndate
      LOCAL lccode, lnlength, lnchksum, lnchksum1, lcchksum
      lccode    = STRTRAN(tcCode, '-', '')
      lnchksum1 = 0

      lnlength = LEN(lccode)
      lcchksum = SUBSTR(lccode, lnlength - 1, 2) + SUBSTR(lccode, 1, 1)
      lnchksum = INT(VAL(lcchksum))
      DO CASE
         CASE tlreturncode
            lccode = SUBSTR(lccode, 2, lnlength - 3)
* Remove Wells, Users and Trans
            lccode = SUBSTR(lccode, 5, 4) + SUBSTR(lccode, 13, 4) + SUBSTR(lccode, 21, 4) + SUBSTR(lccode, 29)
* Remove the expiration date
            lccode = SUBSTR(lccode, 3, 4) + SUBSTR(lccode, 9, 4) + SUBSTR(lccode, 15)
            RETURN (INT(VAL(lccode)))
         CASE tlreturndate
            lccode = SUBSTR(lccode, 2, lnlength - 3)
* Remove Wells, Users and Trans
            lccode = SUBSTR(lccode, 5, 4) + SUBSTR(lccode, 13, 4) + SUBSTR(lccode, 21, 4) + SUBSTR(lccode, 29)
            lddate = CTOD(SUBSTR(lccode, 13, 2) + '/' + SUBSTR(lccode, 1, 2) + '/20' + SUBSTR(lccode, 7, 2))
            RETURN (lddate)
         OTHERWISE
            FOR lnx = 2 TO lnlength - 2
               lnchksum1 = lnchksum1 + INT(VAL(SUBSTR(lccode, lnx, 1)))
            ENDFOR
            IF lnchksum1 # lnchksum
               RETURN .F.
            ELSE
               RETURN .T.
            ENDIF
      ENDCASE
   ENDFUNC


********************************************************************************
   FUNCTION GetSFOptFromCode
********************************************************************************
      LPARAMETERS noption, nclient, ccode, tlNoisy
      LOCAL lnclient, lncode
      IF m.noption > 32
         MESSAGEBOX('GetOpt: Invalid option passed. Must be less than 32.')
         RETURN
      ENDIF
      lnclient = m.nclient
      IF THIS.sfchecksum(m.nclient, m.ccode)
         lncode = THIS.sfchecksum(m.nclient, m.ccode, .T.)
      ELSE
         IF tlNoisy
            MESSAGEBOX('GetSFOptFromCode: This is an invalid registration code.', 0, 'Bad Registration Code')
         ENDIF
         RETURN .F.
      ENDIF
      lncode   = INT((lncode - lnclient) / lnclient)
      llreturn = BITTEST(lncode, m.noption)
      RETURN (llreturn)
   ENDFUNC

ENDDEFINE




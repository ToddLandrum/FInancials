**************************************************
*-- Class Library:  c:\develop\codeminenew\dmie_rv\custom\swqb.vcx
**************************************************


**************************************************
*-- Class:        qbutils
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   09/16/08 09:46:02 PM
*
#INCLUDE SOURCE\appdefs.h
#DEFINE QBFCVER ' 4.0'
***********************************
DEFINE CLASS qbutils AS CUSTOM
   ***********************************

   HEIGHT				 = 26
   WIDTH				 = 105
   oqbsm				 = .F.
   orequest				 = .F.
   omessage				 = .F.
   oregistry			 = .F.
   oqbrequest			 = .F.
   lqberror				 = .F.
   companypost			 = .F.
   dpostdate			 = .F.
   dacctdate			 = .F.
   cperiod				 = .F.
   cyear				 = .F.
   cgroup				 = .F.
   nrunno				 = .F.
   lerrorflag			 = .F.
   csysctlkey			 = .F.
   cdmbatch				 = ""
   ccountry				 = "Version supported"
   sdkversion			 = "1.1"
   qbfcversion			 = " 5.0"
   lqbactive			 = .F.
   crunyear				 = ""
   nprogress			 = .F.
   oprogress			 = .F.
   lquiet				 = .F.
   lHouseGas			 = .F.
   ndatasession			 = .F.
   lerror_recovery_error = .F.
   dexpdate				 = .F.
   cErrorMsg             = ""
   cCheckMemo            = ""
   NAME					 = "qbutils"

   ***************************
   PROCEDURE INIT
   ***************************
   *
   * Get references to the global objects
   *
   IF VARTYPE(m.goapp) = 'O'
      THIS.oregistry	= m.goapp.oregistry
      THIS.omessage	= m.goapp.omessage
   ENDIF

   *
   *  Create the qbxml file if it doesn't exist
   *
   TRY
      IF NOT FILE(m.goapp.cCommonFolder + 'qbxml.dbf')
         CREATE TABLE (m.goapp.cCommonFolder + 'qbxml') FREE ;
            (cid       c(10), ;
            DATETIME T, ;
            XML      m)
      ENDIF
   CATCH TO loError
   ENDTRY
   ENDPROC

   ***************************
   PROCEDURE qbsynccheck
   ***************************
   *
   *  Check to see if any of the data files need to be synchronized with QuickBooks
   *  and perform the synchronization if desired.
   *
   LOCAL llSyncWells, llSyncOwners, llSyncTerms, llSyncCats, llSyncVendors, llSyncPurchasers, llSyncIt, llQuit

   STORE .F. TO llSyncWells, llSyncOwners, llSyncTerms, llSyncCats, llSyncVendors, llSyncPurchasers, llSyncIt, llContinue
   STORE .T. TO llContinue

   SWSELECT('wells')
   LOCATE FOR EMPTY(cListID) AND NOT EMPTY(cWellID) AND NOT EMPTY(cwellname) AND NOT INLIST(cwellstat, 'I', 'S', 'P')
   llSyncWells = FOUND()

   SWSELECT('investor')
   LOCATE FOR EMPTY(cListID) AND NOT EMPTY(cOwnerID) AND NOT EMPTY(cownname)
   llSyncOwners = FOUND()

   SWSELECT('vendor')
   LOCATE FOR EMPTY(cListID) AND NOT EMPTY(cVendorID)
   llSyncVendors = FOUND()

   SWSELECT('expcat')
   LOCATE FOR EMPTY(cListID) AND NOT EMPTY(cCatCode)
   llSyncCats = FOUND()

   SWSELECT('terms')
   LOCATE FOR EMPTY(cListID)
   llSyncTerms = FOUND()

   SWSELECT('revsrc')
   LOCATE FOR EMPTY(cListID) AND NOT EMPTY(cRevKey)
   llSyncPurchasers = FOUND()

   IF llSyncWells OR llSyncOwners OR llSyncTerms OR llSyncCats OR llSyncVendors OR llSyncPurchasers
      IF THIS.omessage.CONFIRM('The data files need to be synchronized with QuickBooks.  Perform the synchronization and continue?')
         llSyncIt = .T.
      ELSE
         llContinue = .F.
      ENDIF
   ENDIF

   IF llSyncIt
      IF llSyncWells
         THIS.sync_wells()
      ENDIF
      IF llSyncOwners
         THIS.sync_owners()
      ENDIF
      IF llSyncVendors
         THIS.sync_Vendors()
      ENDIF
      IF llSyncTerms
         THIS.sync_expcat()
      ENDIF
      IF llSyncCats
         THIS.sync_expcat()
      ENDIF
      IF llSyncPurchasers
         THIS.sync_purchaser()
      ENDIF
   ENDIF

   RETURN (llContinue)

   ENDPROC

   ***************************
   PROCEDURE QBConnection
   ***************************
   LOCAL lnResult, lcGUID, oprogress
   DIMENSION laVersions[1]

   #DEFINE    qbFileOpenSingleUser    0
   #DEFINE    qbFileOpenMultiUser        1
   #DEFINE    qbFileOpenDoNotCare     2

   #DEFINE    qbStopOnError            0
   #DEFINE    qbContinueOnError        1

   lnResult = 0

   * Call the win32 api seterrormode to turn off the "no disk" error message
   THIS.SetErrorMode()

   * Check to make sure the company file specified is a valid file
   DO CASE
      CASE EMPTY(m.goapp.cQBCompany)
         RETURN .F.

      CASE NOT FILE(ALLTRIM(m.goapp.cQBCompany))
         MESSAGEBOX("The QuickBooks Company File Specified: " + CHR(10) + CHR(10) + ;
            UPPER(ALLT(m.goapp.cQBCompany)) + CHR(10) + CHR(10) + ;
            "was not found. "  + ;
            "DMIE can't connect to QuickBooks until a valid filename is specified on the " +  ;
            "Maintain >> Company Information form.", 0, "QuickBooks Filename Problem")
         RETURN .F.
   ENDCASE

   * Kill any qbw32.exe processes that don't have a visible window. This keeps them
   * from locking you out of starting QB manually.

   THIS.QBOrphanProcess()

   * Check to see if QB is running, if not, tell them they have to start it up first.
*!*      IF NOT THIS.IsQBRunning()
*!*         DO FORM 'messages.scx' WITH "Problem Found", ;
*!*            "QuickBooks must be running before DMIE can connect to it.", ;
*!*            "Please start QuickBooks and open company: " + CHR(10) + CHR(10) + ;
*!*            UPPER(ALLTRIM(m.goapp.cQBCompany)) + CHR(10) + CHR(10) + ;
*!*            "Then try connecting again by going to File, Connect to QuickBooks."
*!*         RETURN .F.
*!*      ENDIF

   * If we're in demo status, make sure we're using the correct sample QB company
   IF m.goapp.lDemo
      THIS.QBVersionChk()
   ENDIF

   * IF QuickBooks isn't installed, let the user know.
   IF NOT THIS.QBInstalled()
      IF MESSAGEBOX("QuickBooks does not appear to be installed on this workstation!" + CHR(10) + CHR(10) + ;
            "This could be because you're using a newer version of QuickBooks than we support at this time. " + ;
            "Do you want to continue?", 48, 'QuickBooks Integration Problem') = 7
         RETURN .F.
      ENDIF
   ENDIF

   IF NOT 'QBW' $ UPPER(m.goapp.cQBCompany)
      MESSAGEBOX("The QuickBooks company file specified in Company Information isn't a QuickBooks file! " + ;
         "Please specify a valid QuickBooks company file name on the Maintain >> Company Information form.", 48, 'QuickBooks Integration')
      RETURN .F.
   ENDIF

   THIS.lqberror = .F.

   * Get the location of program files
   TRY
      lcProgramFiles = specialfolders('PROGRAMFILES')
   CATCH
      lcProgramFiles = 'C:\Program Files\'
   ENDTRY

   lcProgramFiles = lcProgramFiles + 'common files\intuit\QuickBooks\'

   * Check to see if what latest QBFC is installed
   llQBFCError = .F.

   TRY
      DO CASE
      CASE FILE(lcProgramFiles + "qbfc15.dll")
         THIS.qbfcversion   = '15.0'
         THIS.oqbsm      = CREATEOBJECT('QBFC15.QBSessionManager')
      CASE FILE(lcProgramFiles + "qbfc14.dll")
         THIS.qbfcversion   = '14.0'
         THIS.oqbsm      = CREATEOBJECT('QBFC14.QBSessionManager')
         CASE FILE(lcProgramFiles + "qbfc13.dll")
            THIS.qbfcversion	= '13.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC13.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc12.dll")
            THIS.qbfcversion	= '12.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC12.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc11.dll")
            THIS.qbfcversion	= '11.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC11.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc10.dll")
            THIS.qbfcversion	= '10.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC10.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc8.dll")
            THIS.qbfcversion	= ' 8.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC8.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc7.dll")
            THIS.qbfcversion	= ' 7.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC7.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc6.dll")
            THIS.qbfcversion	= ' 6.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC6.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc5.dll")
            THIS.qbfcversion	= ' 5.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC5.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc7.dll")
            THIS.qbfcversion	= ' 7.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC7.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc6.dll")
            THIS.qbfcversion	= ' 6.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC6.QBSessionManager')

         CASE FILE(lcProgramFiles + "qbfc5.dll")
            THIS.qbfcversion	= ' 5.0'
            THIS.oqbsm		= CREATEOBJECT('QBFC5.QBSessionManager')

         OTHERWISE
            THIS.qbfcversion	= ' 1.1'
            THIS.oqbsm		= CREATEOBJECT('QBFC1.QBSessionManager')
      ENDCASE
   CATCH TO loError
      llQBFCError = .T.
      IF FILE('datafiles\qbfcdebug.txt')
         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(10) + ;
            'Line:  ' + TRANSFORM(loError.LINENO), 16, 'QBFC Error')
      ENDIF
   ENDTRY

   IF llQBFCError
      MESSAGEBOX("There is a problem with the interface with QuickBooks. It appears the interface hasn't been installed. Contact SherWare support.", 16, 'QB Interface Problem')
      RETURN .F.
   ENDIF


   * open connection with QuickBooks
   THIS.oqbsm.OpenConnection2('Disbursement and JIB Manager Integrated Edition', 'Disbursement and JIB Manager Integrated Edition', 1)

   IF NOT THIS.lqberror
      * open a session with QuickBooks using the specified company file
      TRY
         THIS.oqbsm.BeginSession(m.goapp.cQBCompany, qbFileOpenDoNotCare)
      CATCH TO loError
         WAIT CLEAR
         AERROR(laError)
IF FILE('datafiles\debugqbfc.txt')
   MESSAGEBOX('Error: ' + TRANSFORM(loerror.errorno) + CHR(10) + ;
              'Message: ' + loerror.message + CHR(10) + ;
              'Details: ' + loerror.details + CHR(10) + ;
              'Aerror:  ' + laerror[3],16,'QB Connection')
ENDIF 
         IF loError.ERRORNO = 1440
            DO FORM 'messages.scx' WITH "QuickBooks Connection Problem", ;
               'This application did not connect with QuickBooks. ', ;
               'If you have multiple versions of QuickBooks on your system make sure you have:' + CHR(10) + CHR(10) + ;
               UPPER(ALLTRIM(m.goapp.cQBCompany))                                               + CHR(10) + CHR(10) + ;
               'open in the correct version of QuickBooks before trying to integrate with it.'   + CHR(10) + CHR(10) + ;
               'Also, verify that the QuickBooks company was opened with the exact same path'    + CHR(10) + ;
               'as listed above.  You can verify this under the File menu in QuickBooks by'      + CHR(10) + ;
               'choosing "Open a previous company".  The top path listed there is the currently' + CHR(10) + ;
               'open company and should be the EXACT same path as the path above.'
            DO errorlog WITH 'QBConnection', loError.LINENO, 'oQB', loError.ERRORNO, loError.MESSAGE, '', loError, .T., IIF(m.goapp.cClient = '9999', .T., .F.)

         ELSE
            DO CASE
               CASE 'data file is already' $ loError.MESSAGE
                  DO FORM 'messages.scx' WITH "QuickBooks Connection Problem", ;
                     "QuickBooks has a different company open.", + ;
                     "The company you're trying to integrate with is: " + CHR(10) + CHR(10) + ;
                     UPPER(ALLTRIM(m.goapp.cQBCompany)) + CHR(10) + CHR(10) + ;
                     "Please switch to QuickBooks and choose File, Open Previous Company to see the path and " + ;
                     "name of the company that QuickBooks has open. If the company name is the same but the " + ;
                     "path is different, either change how QuickBooks opens the company or change the path in " + ;
                     "maintain company information to the same path that QuickBooks uses."
                  *                     DO errorlog WITH 'QBConnection', loError.LINENO, 'oQB', loError.ERRORNO, loError.MESSAGE, '', loError, .T.

               CASE 'Could not start QuickBooks...' $ loError.MESSAGE
                  DO FORM 'messages.scx' WITH "QuickBooks Connection Problem", ;
                     "QuickBooks has a different company open.", + ;
                     "The company you're trying to integrate with is: " + CHR(10) + CHR(10) + ;
                     UPPER(ALLTRIM(m.goapp.cQBCompany)) + CHR(10) + CHR(10) + ;
                     "Please switch to QuickBooks and choose File, Open Previous Company to see the path and " + ;
                     "name of the company that QuickBooks has open. If the company name is the same but the " + ;
                     "path is different, either change how QuickBooks opens the company or change the path in " + ;
                     "maintain company information to the same path that QuickBooks uses."

               CASE 'automatic login' $ loError.MESSAGE
                  DO FORM 'messages.scx' WITH "Problem Found", ;
                     "QuickBooks must be running before DMIE can connect to it.", ;
                     "Please start QuickBooks and open company: " + CHR(10) + CHR(10) + ;
                     UPPER(ALLTRIM(m.goapp.cQBCompany)) + CHR(10) + CHR(10) + ;
                     "Then try connecting again by going to File, Connect to QuickBooks."

               CASE 'modal dialog' $ loError.MESSAGE
                  DO FORM 'messages.scx' WITH "Problem Found", ;
                     "There's a modal dialog open in QuickBooks.", ;
                     "Please close the dialog in QuickBooks and "  + ;
                     "then try connecting again by going to File, Connect to QuickBooks."

               CASE 'already logged in' $ loError.MESSAGE
                  DO FORM 'messages.scx' WITH "Problem Found", ;
                     "User already logged in.", ;
                     "The user you are trying to log in with is already logged in from another machine."

               CASE 'Recent changes' $ loError.MESSAGE
                  DO FORM 'messages.scx' WITH "Problem Found", ;
                     "Reauthorization with QB Required", ;
                     "Recent changes to your configuration require you (the QuickBooks Administrator) to go into the Integrated " + ;
                     "Applications preferences and re-authorize your integrated application to log in automatically."

               CASE 'multiple instances of QuickBooks are running' $ loError.MESSAGE
                  DO FORM 'messages.scx' WITH "Problem Found", ;
                     "More than one copy of QB is running...", ;
                     "There must be only one copy of QuickBooks running when attempting to connect to the SherWare application. "

               CASE 'The QuickBooks administrator must grant an application' $ loError.MESSAGE
                  DO FORM 'messages.scx' WITH "Problem Found", ;
                     "The QB Administrator must grant permission to connect!", ;
                     "The QuickBooks administrator must grant an application permission " + ;
                     "to access a QuickBooks company data file for the first time." + CHR(10) + CHR(10) + ;
                     "Switch to QuickBooks and login with the Administrator account " + ;
                     "and then open this company again so that when it attempts to " + ;
                     "connect, you can grant the permission needed."

               OTHERWISE
                  DO FORM 'messages.scx' WITH "QuickBooks Connection Problem", ;
                     'An error was received from QuickBooks when the session was attempted.', ;
                     'The error code is: ' + TRANSFORM(loError.ERRORNO) + CHR(10) + ;
                     'The error text is: ' + CHR(10) + ;
                     loError.MESSAGE + CHR(10) + CHR(10) + ;
                     "Please switch over to QuickBooks to make sure a company is open and all dialogue messages are dismissed."
                  DO errorlog WITH 'QBConnection', loError.LINENO, 'oQB', loError.ERRORNO, loError.MESSAGE, '', loError, .T., IIF(m.goapp.cClient = '9999', .T., .F.)
            ENDCASE
         ENDIF
         THIS.lqberror = .T.
      FINALLY
         WAIT CLEAR
      ENDTRY

      IF NOT THIS.lqberror

         * Set the automated error recovery
         THIS.oqbsm.EnableErrorRecovery		= .F.
         THIS.oqbsm.SaveAllMsgSetRequestInfo	= .F.
         lcGUID								= "{B2921009-AB95-475d-A94A-15180BB8C67A}"
         THIS.oqbsm.errorrecoveryid.setvalue(lcGUID)

         * Check and clear the error recovery status
         THIS.check_error_recovery()

         * Find out what versions are supported
         laVersions = THIS.oqbsm.qbxmlversionsforsession()
         lnVersions = ALEN(laVersions)
         llCanada   = .F.
         FOR lnx = 1 TO lnVersions
            IF 'CA' $ laVersions[lnx]
               llCanada = .T.
            ENDIF
         ENDFOR

         THIS.qbfcversion = PADL(laVersions[lnVersions], 4, ' ')

         IF llCanada
            THIS.ccountry = 'CA'
         ELSE
            THIS.ccountry = 'US'
         ENDIF

         * get a message set request object (version 1.1 xml)
         IF THIS.ccountry = 'CA'
            THIS.oqbrequest = THIS.oqbsm.CreateMsgSetRequest(THIS.ccountry, 3, 0)
         ELSE
            THIS.oqbrequest = THIS.oqbsm.CreateMsgSetRequest(THIS.ccountry, 1, 1)
         ENDIF

         * set the on error attribute for the request
         THIS.oqbrequest.ATTRIBUTES.OnError = qbContinueOnError

         THIS.sdkversion = THIS.qbfcversion

         lnMajorVersion = INT(VAL(SUBSTR(THIS.sdkversion, 1, ATC('.', THIS.sdkversion) - 1)))
         lnMinorVersion = INT(VAL(RIGHT(THIS.sdkversion, 1)))

         IF lnMajorVersion = 4
            lnMinorVersion = 0
         ENDIF
         * Setup the new connection with the highest version supported.
         IF VAL(THIS.qbfcversion) > 2
            THIS.oqbrequest = THIS.oqbsm.CreateMsgSetRequest(THIS.ccountry, lnMajorVersion, lnMinorVersion)
         ELSE
            lnMajorVersion  = 1
            lnMinorVersion  = 1
            THIS.oqbrequest = THIS.oqbsm.CreateMsgSetRequest(lnMajorVersion, lnMinorVersion)
         ENDIF

         THIS.oqbrequest.ATTRIBUTES.OnError = qbContinueOnError
         *      WAIT WINDOW 'SDK Version: ' + THIS.sdkversion + ' QBFC Version: ' + THIS.qbfcversion

         THIS.lqbactive = .T.
      ELSE
         THIS.lqbactive = .F.
      ENDIF
   ELSE
      THIS.lqbactive = .F.
   ENDIF

   WAIT CLEAR

   IF m.goapp.lDemo
      *    In Demo mode
      lcDemo = 'DEMO of '
   ELSE
      lcDemo = ''
   ENDIF


   IF THIS.lqbactive
      _SCREEN.CAPTION = lcDemo + m.goapp.cproductname + ' V' + m.goapp.cFullVersion + ' - ' + TRIM(m.goapp.cCompanyName) + ' QB: ' + UPPER(ALLT(JUSTSTEM(m.goapp.cQBCompany)))
   ELSE
      _SCREEN.CAPTION = lcDemo + m.goapp.cproductname + ' V' + m.goapp.cFullVersion + ' - ' + TRIM(m.goapp.cCompanyName) + ' QB: Not Connected To QuickBooks'
   ENDIF
   m.goapp.lqbactive = THIS.lqbactive

   RETURN NOT THIS.lqberror
   ENDPROC

   ***************************
   PROCEDURE qbclose
   ***************************
   LOCAL lcVersion

   WAIT WIND NOWAIT 'Closing QuickBooks interface....Please Wait'

   lcVersion = m.goapp.cfileversion

   * end the session - we have our response message object
   IF THIS.lqbactive
      THIS.oqbsm.EndSession()

      * close the connection
      THIS.oqbsm.CloseConnection()

      _SCREEN.CAPTION = m.goapp.cproductname + ' ' + ALLT(m.goapp.capplevel) + ' V' + lcVersion + ' - ' + TRIM(cproducer)

      m.goapp.lqbactive = .F.
      THIS.lqbactive	   = .F.
   ENDIF

   WAIT CLEAR
   ENDPROC

   ***************************
   PROCEDURE qbpostvendcks
   ***************************
   LOCAL lnCheck, lcRevClear, lcExpClear, llQBPost, lcSuspense
   *  Get the account fixed expenses and well expenses by well expenses are to be posted to.
   SELE apopt
   lcAPAcct = cAPAcct

   IF NOT USED('glopt')
      USE glopt IN 0
   ENDIF
   SELE glopt
   lcRevClear = crevclear
   lcExpClear = cexpclear
   llQBPost	 = NOT ldmnopost
   lcSuspense = csuspense

   IF THIS.qbfcversion > QBFCVER
      lnCheck = 6
   ELSE
      lnCheck = 11
   ENDIF

   * set the on error attribute for the request
   THIS.oqbrequest.ATTRIBUTES.OnError = 1

   * Clear any previous requests
   THIS.oqbrequest.ClearRequests()

   ****************************************************************
   *   Get Disbursement Checking Acct Number
   ****************************************************************
   SWSELECT('options')
   GO TOP
   m.cdisbacct = cdisbacct
   IF EMPTY(ALLT(m.cdisbacct))
      m.cdisbacct = lcSuspense
   ENDIF
   m.cvendcomp = cvendcomp
   IF EMPTY(ALLT(m.cvendcomp))
      m.cvendcomp = lcSuspense
   ENDIF
   m.cgathacct = cgathacct
   IF EMPTY(ALLT(m.cgathacct))
      m.cgathacct = lcSuspense
   ENDIF
   m.cbackwith = cbackacct
   IF EMPTY(ALLT(m.cbackwith))
      m.cbackwith = lcSuspense
   ENDIF
   m.ctaxacct1  = ctaxacct1
   IF EMPTY(ALLT(m.ctaxacct1))
      m.ctaxacct1 = lcSuspense
   ENDIF
   m.ctaxacct2  = ctaxacct2
   IF EMPTY(ALLT(m.ctaxacct2))
      m.ctaxacct2 = lcSuspense
   ENDIF
   m.ctaxacct3  = ctaxacct3
   IF EMPTY(ALLT(m.ctaxacct3))
      m.ctaxacct3 = lcSuspense
   ENDIF
   m.ctaxacct4 = ctaxacct4
   IF EMPTY(ALLT(m.ctaxacct4))
      m.ctaxacct4 = lcSuspense
   ENDIF
   m.cdefacct  = cdefacct
   IF EMPTY(ALLT(m.cdefacct))
      m.cdefacct = lcSuspense
   ENDIF
   m.cminacct  = cminacct
   IF EMPTY((m.cminacct))
      m.cminacct = lcSuspense
   ENDIF

   *  Get the account fixed expenses and well expenses by well expenses are to be posted to.
   lcdmexp = cfixedacct
   IF EMPTY(lcdmexp)
      lcdmexp = lcAPAcct
   ENDIF

   IF EMPTY(lcdmexp)
      MESSAGEBOX('The fixed expense clearing account needs to be specified in Disbursement and JIB Options.' + ;
         'please specify the account and then close the revenue period again.', 0, 'Setup Problem')
      RETURN .F.
   ENDIF

   llsepclose  = lsepclose

   * Post vendor checks
   SWSELECT('checks')
   SCAN FOR cbatch = THIS.cdmbatch AND cidtype = 'V'
      SCATTER MEMVAR

      SWSELECT('vendor')
      LOCATE FOR cVendorID = m.cid
      IF FOUND()
         lcvendlistid = cListID
         IF EMPTY(cListID)
            MESSAGEBOX('The vendor file needs to be synchronized with QuickBooks. ' + ;
               'please synchronize and then close the revenue period again.', 0, 'Synchronization Problem')
            RETURN .F.
         ENDIF
      ELSE
         LOOP
      ENDIF

      *  Setup the check add request
      locheckadd = THIS.oqbrequest.appendcheckaddrq()
      locheckadd.txndate.setvalue(tdPostdate)
      locheckadd.MEMO.setvalue('')

      locheckadd.payeeentityref.listid.setvalue(lcvendlistid)
      locheckadd.accountref.listid.setvalue(m.cdisbacct)
      locheckadd.istobeprinted.setvalue(0)
      locheckadd.refnumber.setvalue(m.ccheckno)

      loexpenseline = locheckadd.expenselineaddlist.APPEND
      loexpenseline.MEMO.setvalue('Vendor Ck: ' + m.cid)
      loexpenseline.amount.setvalue(ABS(ROUND(m.namount, 2)))
      IF m.cmemo = 'Compression/Gathering'
         loexpenseline.accountref.listid.setvalue(m.cgathacct)
      ELSE
         loexpenseline.accountref.listid.setvalue(lcdmexp)
      ENDIF

      lcxml		= THIS.oqbrequest.toxmlstring()
      this.SaveXML(m.cID, lcXML)
      loresponse	= THIS.oqbsm.dorequests(THIS.oqbrequest)
      loaddresp	= loresponse.responselist.getat(0)

      IF loaddresp.statuscode # 0
         MESSAGEBOX('Vendor Check: ' + m.cid + CHR(13) + loaddresp.statusmessage, 48, 'Error Posting to QB')
         *!*               MESSAGEBOX(lcxml, 0, 'Vendor Post Error')
         THIS.ClearErrorRecovery()
         RETURN .F.
      ELSE
         lonewchk = loaddresp.DETAIL
         m.ctxnid = lonewchk.txnid.getvalue()
         SWSELECT('qbpost')
         LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnCheck
         IF NOT FOUND()
            m.ntype	 = lnCheck
            m.mtxnids = m.ctxnid
            INSERT INTO qbpost FROM MEMVAR
         ELSE
            IF NOT EMPTY(ALLT(mtxnids))
               REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
            ELSE
               REPL mtxnids WITH m.ctxnid
            ENDIF
         ENDIF
         SWSELECT('checks')
         IF FOUND()
            REPL ctxnid WITH m.ctxnid
         ENDIF
         THIS.ClearErrorRecovery()
         THIS.oqbrequest.ClearRequests()
      ENDIF
   ENDSCAN
   ENDPROC

   ***************************
   PROCEDURE qbpostjib
   ***************************
   LOCAL lcbatch, lcaracct, lctaxacct, lccogsacct, llreturn, lcselect, lnrecno, lcdmexp
   LOCAL lnlastcost, llinvitem, llnopostdm, llSummarize, lnJournal, lnCheck, lnInvoice, lnCreditMemo

   IF THIS.lerrorflag
      RETURN .F.
   ENDIF

   lnDatasession = THIS.ndatasession
   TRY
      SET DATASESSION TO (lnDatasession)
   CATCH TO loError
   ENDTRY

   * Check to see if the data files need to be synchronized with QuickBooks
   IF NOT THIS.qbsynccheck()
      RETURN .F.
   ENDIF

   * Choose the correct txndeltype depending on the SDK.
   IF THIS.qbfcversion > QBFCVER
      lnJournal	  = 15
      lnCheck	  = 6
      lnInvoice	  = 13
      lnCreditMemo = 9
   ELSE
      lnJournal	  = 14
      lnCheck	  = 11
      lnInvoice	  = 0
      lnCreditMemo = 3
   ENDIF

   * Check and clear error recovery status
   THIS.check_error_recovery()

   * set the on error attribute for the request
   THIS.oqbrequest.ATTRIBUTES.OnError = 1

   * Set the automated error recovery
   THIS.oqbsm.EnableErrorRecovery	  = .T.
   THIS.oqbsm.SaveAllMsgSetRequestInfo = .T.
   lcGUID							  = "{B2921009-AB95-475d-A94A-15180BB8C67A}"
   THIS.oqbsm.errorrecoveryid.setvalue(lcGUID)

   * Clear any requests prior to posting
   THIS.oqbrequest.ClearRequests()

   tcperiod = THIS.cperiod
   tcyear   = THIS.cyear
   tcgroup  = THIS.cgroup
   tnrunno  = THIS.nrunno

   lcselect = SELECT()

   * Look to see if only the company's share is to be posted with the post date
   IF THIS.companypost = .T.
      tdPostdate	   = THIS.dacctdate
      tdCompanyPost = THIS.dpostdate
   ELSE
      tdPostdate	   = THIS.dpostdate
      tdCompanyPost = THIS.dpostdate
   ENDIF

   *
   * Get the default A/R account
   *
   SWSELECT('options')
   GO TOP
   lcaracct	 = cjibacct
   llsepclose = .T.
   lcdmexp	 = cfixedacct

   SWSELECT('apopt')
   lcAPAcct   = cAPAcct

   IF EMPTY(lcdmexp)
      lcdmexp = lcAPAcct
   ENDIF

   SWSELECT('glopt')
   lcExpClear  = cexpclear
   llQBPost	  = NOT ldmnopost
   lcSuspense  = csuspense
   llSummarize = lBunch

   m.cownacctlistid = ''

   IF EMPTY(lcSuspense)
      MESSAGEBOX('The "Catch-All" account has not been specified in the Account Defaults.  Please specify a catch-all account before continuing.', 0, 'Account Problem')
      RETURN .F.
   ENDIF

   *  Open the QB Transaction Table
   SWSELECT('qbpost')

   SWSELECT('wells')
   SET ORDER TO cWellID
   lnExpTot = 0
   lnowner  = 0

   *  Get the owners to be posted.
   SELECT cOwnerID, cownname, cListID FROM investor WHERE linteggl = .T. INTO ARRAY laowns ORDER BY cOwnerID
   lnowns	= _TALLY
   lcownerid	= ''
   IF lnowns > 0
      WAIT WIND NOWAIT 'Creating Cash Journal Entries For Owner Expenses....'
      lnamount = 0
      SWSELECT('suspense')
      lnx = AFIELDS(latemp)
      FOR x = 1 TO lnx
         latemp[X, 7]  = ''
         latemp[X, 8]  = ''
         latemp[X, 9]  = ''
         latemp[X, 10] = ''
         latemp[X, 11] = ''
         latemp[X, 12] = ''
         latemp[X, 13] = ''
         latemp[X, 14] = ''
         latemp[X, 15] = ''
         latemp[X, 16] = ''
      ENDFOR
      CREATE CURSOR tempowner FROM ARRAY latemp

      FOR lnx = 1 TO lnowns
         lcownerid  = laowns[lnX, 1]
         CREATE CURSOR tempowner FROM ARRAY latemp
         m.cbatch = THIS.oregistry.incrementcounter('%Shared.Counters.Batch')
         STORE 0 TO lnoilrev, lngasrev, lntrprev, lnmi1rev, lnmi2rev, lndebits, lncredits, ;
            lnmin, lndeficit, lnoiltax, lngastax

         SELE disbhist
         SCAN FOR cOwnerID == lcownerid ;
               AND crunyear = tcyear ;
               AND nrunno   = tnrunno ;
               AND cgroup = tcgroup ;
               AND crectype = 'J'
            SCATTER MEMVAR
            SWSELECT('ownpcts')
            LOCATE FOR ciddisb == m.ciddisb
            IF FOUND()
               SCATTER MEMVAR
            ENDIF
            INSERT INTO tempowner FROM MEMVAR
         ENDSCAN

         SELE cOwnerID, cWellID, SUM(nexpense) AS nexp, SUM(nincome) AS ninc, SUM(nsevtaxes) AS nsev, SUM(nnetcheck) AS nnet ;
            FROM tempowner INTO CURSOR tempownwell ORDER BY cOwnerID, cWellID GROUP BY cOwnerID, cWellID

         SELE tempowner
         lnmax	= RECC()
         lncount	= 1
         IF lnmax > 0
            IF NOT THIS.lquiet
               THIS.oprogress = THIS.omessage.progressbarex('Posting owner totals to expense accounts...', laowns[lnX, 2])
               THIS.oprogress.setprogressrange(0, lnmax)
            ENDIF

            SELE roundtmp
            REPL lused WITH .F. FOR cOwnerID == lcownerid AND cdmbatch == THIS.cdmbatch

            SELE tempownwell
            SCAN
               SCATTER MEMVAR
               IF m.nexp = 0 AND m.ninc = 0 AND m.nsev = 0 AND m.nnet = 0
                  SWSELECT('expense')
                  LOCATE FOR cWellID == m.cWellID AND nrunnojib == THIS.nrunno AND crunyearjib == THIS.crunyear
                  IF NOT FOUND()
                     LOOP
                  ENDIF
               ENDIF

               *  Setup the journal add request
               loentryadd = THIS.oqbrequest.appendjournalentryaddrq()
               loentryadd.txndate.setvalue(tdCompanyPost)
               loentryadd.refnumber.setvalue('DM-' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear)
               *            loentryadd.MEMO.setvalue('** CREATED BY DMPRO2004 **')

               * Add an entry for rounding
               SELE roundtmp
               LOCATE FOR cOwnerID = m.cOwnerID AND cWellID = m.cWellID AND lused = .F. AND cdmbatch == THIS.cdmbatch
               IF FOUND()
                  m.nexptotal = nexpense + ntotale1 + ntotale2 + ntotale3 + ntotale4 + ntotale5 + ntotalea + ntotaleb
                  m.nexptotal = ROUND(m.nexptotal, 2)
                  REPL lused WITH .T.

                  IF m.nexptotal # 0
                     IF m.nexptotal > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF

                     lcname		= laowns[lnX, 2]
                     lcownlistid	= laowns[lnX, 3]

                     SWSELECT('wells')
                     IF SEEK(m.cWellID)
                        SCATTER FIELDS LIKE lsev* MEMVAR
                        lcwelllistid = cListID
                     ELSE
                        LOOP
                     ENDIF

                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK('ROUN')
                        m.cownacctlistid = cownacctlistid
                     ENDIF

                     IF EMPTY(m.cownacctlistid)
                        m.cownacctlistid = lcSuspense
                     ENDIF

                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cownacctlistid)
                     loentry.amount.setvalue(ABS(m.nexptotal))
                     loentry.MEMO.setvalue(ALLT('Rounding'))
                  ENDIF

                  *
                  *  Post expense clearing entry
                  *
                  IF m.nexptotal # 0
                     IF m.nexptotal < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(swround(m.nexptotal, 2)))
                     loentry.MEMO.setvalue('Rounding')
                  ENDIF


               ENDIF

               SELECT tempowner
               SCAN FOR THIS.lerrorflag = .F. AND cWellID == m.cWellID
                  SCATTER MEMVAR

                  lljib = ljib

                  IF NOT THIS.lquiet
                     THIS.oprogress.updateprogress(lncount)
                  ENDIF

                  lncount = lncount + 1

                  lcname		 = laowns[lnX, 2]
                  lcownlistid = laowns[lnX, 3]

                  SWSELECT('wells')
                  IF SEEK(m.cWellID)
                     SCATTER FIELDS LIKE lsev* MEMVAR
                     lcwelllistid = cListID
                  ELSE
                     LOOP
                  ENDIF

                  *
                  *  Process default class expenses
                  *
                  llroundit = .F.

                  IF NOT llsepclose AND lljib
                     *  Do Nothing
                  ELSE
                     *                       IF m.nexpense <> 0
                     lntotal = 0
                     SWSELECT('expense')
                     SCAN FOR nrunnojib    = tnrunno ;
                           AND crunyearjib  = tcyear ;
                           AND cWellID      = m.cWellID   ;
                           AND cexpclass    = '0' ;
                           AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND cCatCode # 'MKTG' ;
                           AND dexpdate    <= THIS.dexpdate

                        m.ccateg	   = cCatCode + '-' + ALLTRIM(ccateg)
                        m.namount   = namount
                        lcownerid   = cOwnerID
                        m.cexpclass = cexpclass
                        m.cCatCode  = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cownacctlistid = cownacctlistid
                           m.lJIBOnly	   = lJIBOnly
                        ELSE
                           LOOP
                        ENDIF

                        * If this owner is not a jib owner and the expense
                        * isn't a JIB only expense, loop out.
                        IF NOT m.ljib AND NOT m.lJIBOnly
                           LOOP
                        ENDIF

                        IF EMPTY(m.cownacctlistid)
                           m.cownacctlistid = lcSuspense
                        ENDIF

                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cOwnerID
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nworkint / 100), 2)
                        ENDIF

                        *!*                            IF llround AND NOT llroundit
                        *!*                               m.namount = swround(m.namount + roundtmp.nexpense,2)
                        *!*                               llroundit = .T.
                        *!*                            ENDIF

                        IF m.namount # 0
                           IF m.namount > 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                           ENDIF
                           loentry.classref.listid.setvalue(lcwelllistid)
                           loentry.entityref.listid.setvalue(lcownlistid)
                           loentry.accountref.listid.setvalue(m.cownacctlistid)
                           loentry.amount.setvalue(ABS(m.namount))
                           loentry.MEMO.setvalue(ALLT(m.ccateg))
                        ENDIF

                        lnExpTot = lnExpTot + m.namount

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     *                           IF m.nexpense <> 0
                     IF m.nexpense < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(swround(lnExpTot, 2)))
                     loentry.MEMO.setvalue('Well Expenses')
                     *                           ENDIF
                     *                        ENDIF

                     *
                     *  Process class 1 expenses
                     *
                     llroundit = .F.
                     lnExpTot  = 0
                     *                        IF m.ntotale1 <> 0
                     lntotal = 0
                     SWSELECT('expense')
                     SCAN FOR nrunnojib    = tnrunno ;
                           AND crunyearjib = tcyear ;
                           AND cWellID     = m.cWellID   ;
                           AND cexpclass   = '1' ;
                           AND cCatCode # 'MKTG' ;
                           AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND dexpdate    <= THIS.dexpdate

                        m.ccateg	  = cCatCode + '-' + ALLTRIM(ccateg)
                        m.namount  = namount
                        lcownerid  = cOwnerID
                        m.cCatCode = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cownacctlistid = cownacctlistid
                           m.lJIBOnly	   = lJIBOnly
                        ELSE
                           LOOP
                        ENDIF

                        * If this owner is not a jib owner and the expense
                        * isn't a JIB only expense, loop out.
                        IF NOT m.ljib AND NOT m.lJIBOnly
                           LOOP
                        ENDIF

                        IF EMPTY(m.cownacctlistid)
                           m.cownacctlistid = lcSuspense
                        ENDIF

                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cOwnerID
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nintclass1 / 100), 2)
                        ENDIF

                        *!*                            IF llround AND NOT llroundit
                        *!*                               m.namount = swround(m.namount + roundtmp.ntotale1,2)
                        *!*                               llroundit = .T.
                        *!*                            ENDIF

                        IF m.namount # 0
                           IF m.namount > 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                           ENDIF
                           loentry.classref.listid.setvalue(lcwelllistid)
                           loentry.entityref.listid.setvalue(lcownlistid)
                           loentry.accountref.listid.setvalue(m.cownacctlistid)
                           loentry.amount.setvalue(ABS(m.namount))
                           loentry.MEMO.setvalue(ALLT(m.ccateg))
                        ENDIF

                        lnExpTot = lnExpTot + m.namount

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     *                         IF m.ntotale1 <> 0
                     IF m.ntotale1 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(swround(lnExpTot, 2)))
                     loentry.MEMO.setvalue('Class 1 Expenses')
                     *                          ENDIF
                     *                       ENDIF
                     *
                     *  Process class 2 expenses
                     *
                     llroundit = .F.
                     lnExpTot  = 0
                     *                        IF m.ntotale2 <> 0
                     lntotal = 0
                     SWSELECT('expense')
                     SCAN FOR nrunnojib    = tnrunno ;
                           AND crunyearjib = tcyear ;
                           AND cWellID     = m.cWellID   ;
                           AND cexpclass   = '2' ;
                           AND cCatCode # 'MKTG' ;
                           AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND dexpdate   <= THIS.dexpdate

                        m.ccateg	 = cCatCode + '-' + ALLTRIM(ccateg)
                        m.namount = namount
                        lcownerid = cOwnerID

                        m.cCatCode  = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cownacctlistid = cownacctlistid
                           m.lJIBOnly	   = lJIBOnly
                        ELSE
                           LOOP
                        ENDIF

                        * If this owner is not a jib owner and the expense
                        * isn't a JIB only expense, loop out.
                        IF NOT m.ljib AND NOT m.lJIBOnly
                           LOOP
                        ENDIF

                        IF EMPTY(m.cownacctlistid)
                           m.cownacctlistid = lcSuspense
                        ENDIF

                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cOwnerID
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nintclass2 / 100), 2)
                        ENDIF

                        *!*                            IF llround AND NOT llroundit
                        *!*                               m.namount = swround(m.namount + roundtmp.ntotale2,2)
                        *!*                               llroundit = .T.
                        *!*                            ENDIF

                        IF m.namount # 0
                           IF m.namount > 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                           ENDIF
                           loentry.classref.listid.setvalue(lcwelllistid)
                           loentry.entityref.listid.setvalue(lcownlistid)
                           loentry.accountref.listid.setvalue(m.cownacctlistid)
                           loentry.amount.setvalue(ABS(m.namount))
                           loentry.MEMO.setvalue(ALLT(m.ccateg))
                        ENDIF

                        lnExpTot = lnExpTot + m.namount

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     *                          IF m.ntotale2 <> 0
                     IF m.ntotale2 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(swround(lnExpTot, 2)))
                     loentry.MEMO.setvalue('Class 2 Expenses')
                     *                          ENDIF
                     *                       ENDIF
                     *
                     *  Process class 3 expenses
                     *
                     llroundit = .F.
                     lnExpTot  = 0
                     *                        IF m.ntotale3 <> 0
                     lntotal = 0
                     SWSELECT('expense')
                     SCAN FOR nrunnojib    = tnrunno ;
                           AND crunyearjib = tcyear ;
                           AND cWellID     = m.cWellID   ;
                           AND cexpclass   = '3' ;
                           AND cCatCode # 'MKTG' ;
                           AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND dexpdate   <= THIS.dexpdate

                        m.ccateg	 = cCatCode + '-' + ALLTRIM(ccateg)
                        m.namount = namount
                        lcownerid = cOwnerID

                        m.cCatCode  = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cownacctlistid = cownacctlistid
                           m.lJIBOnly	   = lJIBOnly
                        ELSE
                           LOOP
                        ENDIF

                        * If this owner is not a jib owner and the expense
                        * isn't a JIB only expense, loop out.
                        IF NOT m.ljib AND NOT m.lJIBOnly
                           LOOP
                        ENDIF

                        IF EMPTY(m.cownacctlistid)
                           m.cownacctlistid = lcSuspense
                        ENDIF

                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cOwnerID
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nintclass3 / 100), 2)
                        ENDIF

                        *!*                            IF llround AND NOT llroundit
                        *!*                               m.namount = swround(m.namount + roundtmp.ntotale3,2)
                        *!*                               llroundit = .T.
                        *!*                            ENDIF

                        IF m.namount # 0
                           IF m.namount > 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                           ENDIF
                           loentry.classref.listid.setvalue(lcwelllistid)
                           loentry.entityref.listid.setvalue(lcownlistid)
                           loentry.accountref.listid.setvalue(m.cownacctlistid)
                           loentry.amount.setvalue(ABS(m.namount))
                           loentry.MEMO.setvalue(ALLT(m.ccateg))
                        ENDIF

                        lnExpTot = lnExpTot + m.namount

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     *                          IF m.ntotale3 <> 0
                     IF m.ntotale3 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(swround(lnExpTot, 2)))
                     loentry.MEMO.setvalue('Class 3 Expenses')
                     *                         ENDIF
                     *                      ENDIF
                     *
                     *  Process class 4 expenses
                     *
                     llroundit = .F.
                     lnExpTot  = 0
                     *                      IF m.ntotale4 <> 0
                     lntotal = 0
                     SWSELECT('expense')
                     SCAN FOR nrunnojib    = tnrunno ;
                           AND crunyearjib = tcyear ;
                           AND cWellID     = m.cWellID   ;
                           AND cexpclass   = '4' ;
                           AND cCatCode # 'MKTG' ;
                           AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND dexpdate   <= THIS.dexpdate

                        m.ccateg	 = cCatCode + '-' + ALLTRIM(ccateg)
                        m.namount = namount
                        lcownerid = cOwnerID

                        m.cCatCode  = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cownacctlistid = cownacctlistid
                           m.lJIBOnly	   = lJIBOnly
                        ELSE
                           LOOP
                        ENDIF

                        * If this owner is not a jib owner and the expense
                        * isn't a JIB only expense, loop out.
                        IF NOT m.ljib AND NOT m.lJIBOnly
                           LOOP
                        ENDIF

                        IF EMPTY(m.cownacctlistid)
                           m.cownacctlistid = lcSuspense
                        ENDIF

                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cOwnerID
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nintclass4 / 100), 2)
                        ENDIF

                        *!*                            IF llround AND NOT llroundit
                        *!*                               m.namount = swround(m.namount + roundtmp.ntotale4,2)
                        *!*                               llroundit = .T.
                        *!*                            ENDIF

                        IF m.namount # 0
                           IF m.namount > 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                           ENDIF
                           loentry.classref.listid.setvalue(lcwelllistid)
                           loentry.entityref.listid.setvalue(lcownlistid)
                           loentry.accountref.listid.setvalue(m.cownacctlistid)
                           loentry.amount.setvalue(ABS(m.namount))
                           loentry.MEMO.setvalue(ALLT(m.ccateg))
                        ENDIF

                        lnExpTot = lnExpTot + m.namount

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     *                           IF m.ntotale4 <> 0
                     IF m.ntotale4 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(swround(lnExpTot, 2)))
                     loentry.MEMO.setvalue('Class 4 Expenses')
                     *                           ENDIF
                     *                        ENDIF

                     *
                     *  Process class 5 expenses
                     *
                     llroundit = .F.
                     lnExpTot  = 0
                     *                        IF m.ntotale5 <> 0
                     lntotal = 0
                     SWSELECT('expense')
                     SCAN FOR nrunnojib    = tnrunno ;
                           AND crunyearjib = tcyear ;
                           AND cWellID     = m.cWellID   ;
                           AND cexpclass   = '5' ;
                           AND cCatCode # 'MKTG' ;
                           AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND dexpdate   <= THIS.dexpdate

                        m.ccateg	  = cCatCode + '-' + ALLTRIM(ccateg)
                        m.namount  = namount
                        lcownerid  = cOwnerID
                        m.cCatCode = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cownacctlistid = cownacctlistid
                           m.lJIBOnly	   = lJIBOnly
                        ELSE
                           LOOP
                        ENDIF

                        * If this owner is not a jib owner and the expense
                        * isn't a JIB only expense, loop out.
                        IF NOT m.ljib AND NOT m.lJIBOnly
                           LOOP
                        ENDIF

                        IF EMPTY(m.cownacctlistid)
                           m.cownacctlistid = lcSuspense
                        ENDIF

                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cOwnerID
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nintclass5 / 100), 2)
                        ENDIF

                        *!*                            IF llround AND NOT llroundit
                        *!*                               m.namount = swround(m.namount + roundtmp.ntotale5,2)
                        *!*                               llroundit = .T.
                        *!*                            ENDIF

                        IF m.namount # 0
                           IF m.namount > 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                           ENDIF
                           loentry.classref.listid.setvalue(lcwelllistid)
                           loentry.entityref.listid.setvalue(lcownlistid)
                           loentry.accountref.listid.setvalue(m.cownacctlistid)
                           loentry.amount.setvalue(ABS(m.namount))
                           loentry.MEMO.setvalue(ALLT(m.ccateg))
                        ENDIF

                        lnExpTot = lnExpTot + m.namount

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     *                          IF m.ntotale5 <> 0
                     IF m.ntotale5 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(swround(lnExpTot, 2)))
                     loentry.MEMO.setvalue('Class 5 Expenses')
                     *                          ENDIF
                     *                       ENDIF

                     *
                     *  Process ACP expenses
                     *
                     llroundit = .F.
                     lnExpTot  = 0
                     *                        IF m.ntotalea <> 0

                     lntotal = 0
                     SWSELECT('expense')
                     SCAN FOR nrunnojib    = tnrunno ;
                           AND crunyearjib = tcyear ;
                           AND cWellID     = m.cWellID   ;
                           AND cexpclass   = 'A' ;
                           AND cCatCode # 'MKTG' ;
                           AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND dexpdate   <= THIS.dexpdate

                        m.ccateg	 = cCatCode + '-' + ALLTRIM(ccateg)
                        m.namount = namount
                        lcownerid = cOwnerID

                        m.cCatCode  = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cownacctlistid = cownacctlistid
                           m.lJIBOnly	   = lJIBOnly
                        ELSE
                           LOOP
                        ENDIF

                        * If this owner is not a jib owner and the expense
                        * isn't a JIB only expense, loop out.
                        IF NOT m.ljib AND NOT m.lJIBOnly
                           LOOP
                        ENDIF

                        IF EMPTY(m.cownacctlistid)
                           m.cownacctlistid = lcSuspense
                        ENDIF

                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cOwnerID
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nacpint / 100), 2)
                        ENDIF

                        *!*                            IF llround AND NOT llroundit
                        *!*                               m.namount = swround(m.namount + roundtmp.ntotalea,2)
                        *!*                               llroundit = .T.
                        *!*                            ENDIF

                        IF m.namount # 0
                           IF m.namount > 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                           ENDIF
                           loentry.classref.listid.setvalue(lcwelllistid)
                           loentry.entityref.listid.setvalue(lcownlistid)
                           loentry.accountref.listid.setvalue(m.cownacctlistid)
                           loentry.amount.setvalue(ABS(m.namount))
                           loentry.MEMO.setvalue(ALLT(m.ccateg))
                        ENDIF

                        lnExpTot = lnExpTot + m.namount

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     *                          IF m.ntotalea <> 0
                     IF m.ntotalea < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(swround(lnExpTot, 2)))
                     loentry.MEMO.setvalue('After Casing Expenses')
                     *                          ENDIF
                     *                       ENDIF

                     *
                     *  Process BCP expenses
                     *
                     llroundit = .F.
                     lnExpTot  = 0
                     *                      IF m.ntotaleb <> 0
                     lntotal = 0
                     SWSELECT('expense')
                     SCAN FOR nrunnojib    = tnrunno ;
                           AND crunyearjib = tcyear ;
                           AND cWellID     = m.cWellID   ;
                           AND cexpclass   = 'B' ;
                           AND cCatCode # 'MKTG' ;
                           AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND dexpdate   <= THIS.dexpdate

                        m.ccateg	  = cCatCode + '-' + ALLTRIM(ccateg)
                        m.namount  = namount
                        lcownerid  = cOwnerID
                        m.cCatCode = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cownacctlistid = cownacctlistid
                           m.lJIBOnly	   = lJIBOnly
                        ELSE
                           LOOP
                        ENDIF

                        * If this owner is not a jib owner and the expense
                        * isn't a JIB only expense, loop out.
                        IF NOT m.ljib AND NOT m.lJIBOnly
                           LOOP
                        ENDIF

                        IF EMPTY(m.cownacctlistid)
                           m.cownacctlistid = lcSuspense
                        ENDIF

                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cOwnerID
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nbcpint / 100), 2)
                        ENDIF

                        *!*                            IF llround AND NOT llroundit
                        *!*                               m.namount = swround(m.namount + roundtmp.ntotaleb,2)
                        *!*                               llroundit = .T.
                        *!*                            ENDIF

                        IF m.namount # 0
                           IF m.namount > 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                           ENDIF
                           loentry.classref.listid.setvalue(lcwelllistid)
                           loentry.entityref.listid.setvalue(lcownlistid)
                           loentry.accountref.listid.setvalue(m.cownacctlistid)
                           loentry.amount.setvalue(ABS(m.namount))
                           loentry.MEMO.setvalue(ALLT(m.ccateg))
                        ENDIF
                        lnExpTot = lnExpTot + m.namount

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     *                           IF m.ntotaleb <> 0
                     IF m.ntotaleb < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(swround(lnExpTot, 2)))
                     loentry.MEMO.setvalue('Before Casing Expenses')
                     *                          ENDIF
                     *                       ENDIF
                  ENDIF
                  lnExpTot  = 0
               ENDSCAN

               lcxml		 = THIS.oqbrequest.toxmlstring()
               THIS.SaveXML(lcOwnerID, lcXML)
               loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
               loaddresp	 = loresponse.responselist.getat(0)

               IF loaddresp.statuscode # 0

                  IF 'object' $ LOWER(loaddresp.statusmessage)
                     lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
                     llResult = m.goapp.oQB.QBListID(lcListID)
                     IF llResult
                        SELECT QBListID
                        IF QBListID.ctype = 'Account'
                           lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                              'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                              'and try to close the JIB run again.'
                        ELSE
                           IF 'Acct' $ QBListID.cdescription
                              lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                                 'Please choose a new account in ' + ALLTRIM(QBListID.ctype) + ' and try to close the JIB run again.'
                           ELSE
                              lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                                 'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to close the JIB run again.'
                           ENDIF
                        ENDIF
                        THIS.omessage.severe(lcMessage)
                     ELSE
                        THIS.omessage.severe(loaddresp.statusmessage)
                     ENDIF
                  ELSE
                     THIS.omessage.severe(loaddresp.statusmessage)
                  ENDIF
                  IF VARTYPE(THIS.oprogress) = 'O'
                     THIS.oprogress.closeprogress()
                  ENDIF
                  THIS.ClearErrorRecovery()
                  * Unpost what has been posted so far this run.
                  THIS.qbunpostjib()
                  RETURN .F.
               ELSE
                  lonewbill = loaddresp.DETAIL
                  m.ctxnid  = lonewbill.txnid.getvalue()
                  SWSELECT('qbpost')
                  LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnJournal
                  IF NOT FOUND()
                     m.ntype	  = lnJournal
                     m.mtxnids = m.ctxnid
                     INSERT INTO qbpost FROM MEMVAR
                  ELSE
                     IF NOT EMPTY(ALLT(mtxnids))
                        REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
                     ELSE
                        REPL mtxnids WITH m.ctxnid
                     ENDIF
                  ENDIF
               ENDIF

               THIS.ClearErrorRecovery()
               THIS.oqbrequest.ClearRequests()

            ENDSCAN

            IF VARTYPE(THIS.oprogress) = 'O'
               THIS.oprogress.closeprogress()
            ENDIF

            DOEVENTS
            THIS.oprogress = .NULL.
         ENDIF && lnMax > 0
      ENDFOR
   ENDIF

   ***********************************************************************
   *   Post the Vendor amounts that are designated to be posted.
   ***********************************************************************
   lnvendor = 0
   *
   *  Get the vendors to be posted.
   *

   * Clear out any previous requests
   THIS.oqbrequest.ClearRequests()

   SELECT cVendorID, cvendname, cListID FROM vendor WHERE linteggl = .T. INTO ARRAY lavends

   IF _TALLY > 0
      lnvends = ALEN(lavends, 1)
      IF lnvends > 0
         FOR lnx = 1 TO lnvends
            lnamount	 = 0
            lnPostAmt = 0
            THIS.oprogress = THIS.omessage.progressbarex('Posting vendor totals to income accounts...', ;
               lavends[lnX, 2])
            m.cVendorID	= lavends[lnX, 1]
            m.cvendname	= lavends[lnX, 2]
            lcvendlistid	= lavends[lnX, 3]
            SWSELECT('expense')
            COUNT FOR cVendorID = m.cVendorID AND nrunnojib = tnrunno ;
               AND crunyearjib = tcyear AND namount # 0 ;
               AND dexpdate <= THIS.dexpdate ;
               AND NOT lAPTran TO lnmax
            THIS.oprogress.setprogressrange(0, lnmax)
            lncount = 1
            IF lnmax > 0
               *  Setup the journal add request
               loentryadd = THIS.oqbrequest.appendjournalentryaddrq()
               loentryadd.txndate.setvalue(tdCompanyPost)
               loentryadd.refnumber.setvalue('DM-' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear)
               * Post Non lAPTran entries
               lnamount = 0
               SWSELECT('expense')
               SCAN FOR cVendorID = m.cVendorID ;
                     AND nrunnojib = tnrunno ;
                     AND crunyearjib = tcyear ;
                     AND namount # 0 ;
                     AND dexpdate <= THIS.dexpdate ;
                     AND THIS.lerrorflag = .F. ;
                     AND NOT lAPTran
                  m.cWellID	 = cWellID
                  m.ccateg	 = cCatCode + '-' + ALLTRIM(ccateg)
                  m.cexpclass = cexpclass
                  m.namount	 = namount
                  m.cunitno	 = cWellID
                  m.cid		 = cVendorID
                  m.cvendname = lavends[lnX, 2]
                  m.lAPTran	 = lAPTran
                  m.cCatCode	 = cCatCode
                  m.cOwnerID	 = cOwnerID

                  *
                  *  Check to make sure the well is in the right group
                  *
                  SWSELECT('wells')
                  SET ORDER TO cWellID
                  IF SEEK(m.cWellID)
                     IF wells.cgroup # tcgroup
                        LOOP
                     ENDIF
                     lcwelllistid = cListID
                  ENDIF

                  *
                  *  Get the account numbers to be posted for this expense category
                  *
                  SWSELECT('expcat')
                  SET ORDER TO cCatCode
                  IF SEEK(m.cCatCode)
                     m.cvendacctlistid = cvendacctlistid
                     IF NOT '-' $ m.cvendacctlistid
                        m.cvendacctlistid = lcSuspense
                     ENDIF
                  ELSE
                     m.cvendacctlistid = lcSuspense
                  ENDIF

                  *
                  *  Net down the amount for dummy and net owners.  The vendor shouldn't
                  *  be paid by the dummy owners, so they shouldn't receive the amount
                  *  the dummy owner would have had to pay
                  *
                  jnamount = m.namount

                  m.namount = SWNETEXP(jnamount, m.cWellID, .T., m.cexpclass, 'J', .F., m.cOwnerID, m.cCatCode, m.cDeck)
                  lnvendor  = lnvendor + m.namount

                  *  If the amount is zero, the expense has not been assigned to
                  *  any JIB owners
                  IF m.namount = 0
                     LOOP
                  ENDIF

                  *
                  * Update the progress counter
                  *
                  THIS.oprogress.updateprogress(lncount)
                  lncount = lncount + 1

                  *
                  *  Add amount of this invoice to the total the vendor is to be paid
                  *
                  lnamount = lnamount + swround(m.namount, 2)

                  IF m.namount # 0
                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     loentry.classref.listid.setvalue(lcwelllistid)
                     loentry.entityref.listid.setvalue(lcvendlistid)
                     loentry.accountref.listid.setvalue(m.cvendacctlistid)
                     loentry.amount.setvalue(ABS(swround(m.namount, 2)))
                     loentry.MEMO.setvalue(ALLT(m.ccateg))
                  ENDIF
               ENDSCAN

               lnamount = swround(lnamount, 2)

               IF lnamount # 0
                  IF lnamount > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  loentry.classref.listid.setvalue(lcwelllistid)
                  loentry.entityref.listid.setvalue(lcvendlistid)
                  loentry.accountref.listid.setvalue(lcdmexp)

                  loentry.amount.setvalue(ABS(lnamount))
                  loentry.MEMO.setvalue('Vendor Posting')
               ENDIF

               IF lnvendor # 0
                  lcxml = THIS.oqbrequest.toxmlstring()
                  THIS.SaveXML(m.cVendorID, lcXML)
                  loresponse	= THIS.oqbsm.dorequests(THIS.oqbrequest)
                  loaddresp	= loresponse.responselist.getat(0)

                  IF loaddresp.statuscode # 0
                     IF 'object' $ LOWER(loaddresp.statusmessage)
                        lcListID	= SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
                        llResult	= m.goapp.oQB.QBListID(lcListID)
                        IF llResult
                           SELECT QBListID
                           IF QBListID.ctype = 'Account'
                              lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                                 'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                                 'and try to close the JIB run again.'
                           ELSE
                              IF 'Acct' $ QBListID.cdescription
                                 lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                                    'Please choose a new account in ' + ALLTRIM(QBListID.ctype) + ' and try to close the JIB run again.'
                              ELSE
                                 lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                                    'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to close the JIB run again.'
                              ENDIF
                           ENDIF
                           THIS.omessage.severe(lcMessage)
                        ELSE
                           THIS.omessage.severe(loaddresp.statusmessage)
                        ENDIF
                     ELSE
                        THIS.omessage.severe(loaddresp.statusmessage)
                     ENDIF
                     IF VARTYPE(THIS.oprogress) = 'O'
                        THIS.oprogress.closeprogress()
                     ENDIF
                     THIS.ClearErrorRecovery()
                     * Unpost what has been posted so far this run.
                     THIS.qbunpostjib()
                     RETURN .F.
                  ELSE
                     lonewbill = loaddresp.DETAIL
                     m.ctxnid  = lonewbill.txnid.getvalue()
                     SWSELECT('qbpost')
                     LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnJournal
                     IF NOT FOUND()
                        m.ntype	 = lnJournal
                        m.mtxnids = m.ctxnid
                        INSERT INTO qbpost FROM MEMVAR
                     ELSE
                        IF NOT EMPTY(ALLT(mtxnids))
                           REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
                        ELSE
                           REPL mtxnids WITH m.ctxnid
                        ENDIF
                     ENDIF
                     THIS.ClearErrorRecovery()
                  ENDIF
               ELSE
                  lnvendor = 0
               ENDIF

               THIS.oqbrequest.ClearRequests()
               IF VARTYPE(THIS.oprogress) = 'O'
                  THIS.oprogress.closeprogress()
               ENDIF

               DOEVENTS
            ENDIF
         ENDFOR &&* lnX = 1 TO lnVends
      ENDIF

   ENDIF

   ********************************************************************************
   *   Post the A/R Invoices created
   ********************************************************************************

   * Check to make sure we have a "Rounding" item in the QB item file.
   THIS.oqbrequest.ClearRequests()

   * Turn off error recovery for the item query
   THIS.oqbsm.EnableErrorRecovery      = .F.

   loitemservicequery = THIS.oqbrequest.appenditemservicequeryrq()

   * add a filter look for the Rounding Item
   *!*         IF THIS.qbfcversion > ' 7.0'
   loitemservicequery.ORListQueryWithOwnerIDAndClass.ListWithClassFilter.ActiveStatus.SetAsString('ActiveOnly')
   loitemservicequery.ORListQueryWithOwnerIDAndClass.ListWithClassFilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
   loitemservicequery.ORListQueryWithOwnerIDAndClass.ListWithClassFilter.ornamefilter.namefilter.NAME.setvalue(PADR('Rounding', 31, ' '))
   *!*         ELSE
   *!*            loitemservicequery.orlistquery.listfilter.ActiveStatus.SetAsString('ActiveOnly')
   *!*            loitemservicequery.orlistquery.listfilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
   *!*            loitemservicequery.orlistquery.listfilter.ornamefilter.namefilter.NAME.setvalue(PADR('Rounding', 31, ' '))
   *!*         ENDIF
   * add a filter to the item query for the Rounding item

   * process the request object returning a response message object
   loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
   loitemresp = loresponse.responselist.getat(0)

   m.clistidrnd = ''

   IF loitemresp.statuscode # 0
      * Clear inquiry request
      THIS.oqbrequest.ClearRequests()
      loitemadd = THIS.oqbrequest.appenditemserviceaddrq()
      loitemadd.NAME.setvalue(PADR('Rounding', 31, ' '))
      loitemadd.orsalespurchase.salesorpurchase.accountref.listid.setvalue(lcExpClear)
      loitemadd.orsalespurchase.salesorpurchase.DESC.setvalue('Rounding')
      loresponse	  = THIS.oqbsm.dorequests(THIS.oqbrequest)
      loitemresp	  = loresponse.responselist.getat(0)
      loitemrec	  = loitemresp.DETAIL
      m.clistidrnd = loitemrec.listid.getvalue()
   ELSE
      loitem		  = loitemresp.DETAIL
      loitemrec	  = loitem.getat(0)
      m.clistidrnd = loitemrec.listid.getvalue()
   ENDIF

   * add a filter look for the Prepay Item
   IF THIS.qbfcversion > ' 7.0'
      loitemservicequery.ORListQueryWithOwnerIDAndClass.ListWithClassFilter.ActiveStatus.SetAsString('ActiveOnly')
      loitemservicequery.ORListQueryWithOwnerIDAndClass.ListWithClassFilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
      loitemservicequery.ORListQueryWithOwnerIDAndClass.ListWithClassFilter.ornamefilter.namefilter.NAME.setvalue(PADR('PrePay', 31, ' '))
   ELSE
      loitemservicequery.orlistquery.listfilter.ActiveStatus.SetAsString('ActiveOnly')
      loitemservicequery.orlistquery.listfilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
      loitemservicequery.orlistquery.listfilter.ornamefilter.namefilter.NAME.setvalue(PADR('PrePay', 31, ' '))
   ENDIF
   * add a filter to the item query for the Rounding item

   * process the request object returning a response message object
   loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
   loitemresp = loresponse.responselist.getat(0)

   m.clistidpre = ''

   IF loitemresp.statuscode # 0
      * Clear inquiry request
      THIS.oqbrequest.ClearRequests()
      loitemadd = THIS.oqbrequest.appenditemserviceaddrq()
      loitemadd.NAME.setvalue(PADR('PrePay', 31, ' '))
      loitemadd.orsalespurchase.salesorpurchase.accountref.listid.setvalue(lcExpClear)
      loitemadd.orsalespurchase.salesorpurchase.DESC.setvalue('PrePay')
      loresponse	  = THIS.oqbsm.dorequests(THIS.oqbrequest)
      loitemresp	  = loresponse.responselist.getat(0)
      loitemrec	  = loitemresp.DETAIL
      m.clistidpre = loitemrec.listid.getvalue()
   ELSE
      loitem		  = loitemresp.DETAIL
      loitemrec	  = loitem.getat(0)
      m.clistidpre = loitemrec.listid.getvalue()
   ENDIF

   * Check to make sure we have a "Summary" item in the QB item file.
   THIS.oqbrequest.ClearRequests()
   loitemservicequery = THIS.oqbrequest.appenditemservicequeryrq()

   * add a filter to the item query for the Summary item
   IF THIS.qbfcversion > ' 7.0'
      loitemservicequery.ORListQueryWithOwnerIDAndClass.ListWithClassFilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
      loitemservicequery.ORListQueryWithOwnerIDAndClass.ListWithClassFilter.ornamefilter.namefilter.NAME.setvalue(PADR('Summary', 31, ' '))
   ELSE
      loitemservicequery.orlistquery.listfilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
      loitemservicequery.orlistquery.listfilter.ornamefilter.namefilter.NAME.setvalue(PADR('Summary', 31, ' '))
   ENDIF

   * process the request object returning a response message object
   loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
   loitemresp = loresponse.responselist.getat(0)

   IF loitemresp.statuscode # 0
      * Clear inquiry request
      THIS.oqbrequest.ClearRequests()
      loitemadd = THIS.oqbrequest.appenditemserviceaddrq()
      loitemadd.NAME.setvalue(PADR('Summary', 31, ' '))
      loitemadd.orsalespurchase.salesorpurchase.accountref.listid.setvalue(lcExpClear)
      loitemadd.orsalespurchase.salesorpurchase.DESC.setvalue('Summary of JIB Detail')
      loresponse	= THIS.oqbsm.dorequests(THIS.oqbrequest)
      loitemresp	= loresponse.responselist.getat(0)
   ELSE
      THIS.ClearErrorRecovery()
   ENDIF

   * Turn error recovery back on
   THIS.oqbsm.EnableErrorRecovery	  = .T.
   THIS.oqbsm.SaveAllMsgSetRequestInfo = .T.
   lcGUID							  = "{B2921009-AB95-475d-A94A-15180BB8C67A}"
   THIS.oqbsm.errorrecoveryid.setvalue(lcGUID)

   * Summarize JIBs before posting to QB
   IF llSummarize
      SELECT  cbatch, ;
         cunitno, ;
         SUM(nextension) AS nextension, ;
         wells.cListID ;
         FROM jibtempd, wells ;
         INTO CURSOR jibsummd ;
         WHERE jibtempd.cunitno == wells.cWellID ;
         AND jibtempd.ctaxcode # '{P' ;
         ORDER BY cbatch, cunitno ;
         GROUP BY cbatch, cunitno
   ENDIF

   IF USED('jibtemph')
      SELECT jibtemph
      SCAN FOR ninvtot >= 0 AND THIS.lerrorflag = .F.
         SCATTER MEMVAR
         lcbatch = jibtemph.cbatch

         SWSELECT('jibtempd')
         LOCATE FOR cbatch == lcbatch
         IF NOT FOUND()
            LOOP
         ENDIF

         lnamount = jibtemph.ninvtot

         SWSELECT('investor')
         SET ORDER TO cOwnerID
         IF SEEK(jibtemph.ccustid)
            *  Setup the invoice add request
            THIS.oqbrequest.ClearRequests()
            loinvoiceadd = THIS.oqbrequest.appendinvoiceaddrq()

            lcownname   = cownname
            lcownlistid = cListID
            lcidterms   = cidterm
            IF lchktosec
               IF lcheckonly
                  m.caddress1 = caddress1a
                  m.caddress2 = caddress1b
                  m.ccity	 = ccity1
                  m.czip		 = czip1
               ELSE
                  m.caddress1 = caddress2a
                  m.caddress2 = caddress2b
                  m.ccity	 = ccity2
                  m.czip		 = czip2
               ENDIF
            ELSE
               m.caddress1 = caddress1a
               m.caddress2 = caddress1b
               m.ccity	  = ccity1
               m.czip	  = czip1
            ENDIF

            IF linteggl = .T.
               THIS.oqbrequest.ClearRequests()
               LOOP
            ENDIF

            loinvoiceadd.customerref.listid.setvalue(lcownlistid)
            loinvoiceadd.araccountref.listid.setvalue(lcaracct)
            loinvoiceadd.istobeprinted.setvalue('False')

            *  Get the terms listid
            SELE terms
            LOCATE FOR cidterm = lcidterms
            IF FOUND()
               loinvoiceadd.termsref.listid.setvalue(terms.cListID)
            ENDIF

            loinvoiceadd.txndate.setvalue(tdPostdate)
            loinvoiceadd.duedate.setvalue(jibtemph.dduedate)
            loinvoiceadd.refnumber.setvalue(jibtemph.cinvnum)
            loinvoiceadd.MEMO.setvalue('JIB STMT ')

            loinvoicelist = loinvoiceadd.orinvoicelineaddlist

            IF NOT llSummarize
               SELE roundtmp
               REPL lused WITH .F. FOR cdmbatch = THIS.cdmbatch

               SELE jibtempd
               SCAN FOR cbatch = lcbatch
                  SCATTER MEMVAR
                  m.cPayee	 = STRTRAN(m.cPayee, 'é', 'e')
                  m.cPayee	 = STRTRAN(m.cPayee, ':', '-')
                  m.cPayee	 = STRTRAN(m.cPayee, '&', '-')
                  m.cItemDesc = STRTRAN(m.cItemDesc, 'é', 'e')
                  m.cItemDesc = STRTRAN(m.cItemDesc, ':', '-')
                  m.cItemDesc = STRTRAN(m.cItemDesc, '&', '-')
                  m.cItemDesc = STRTRAN(cItemDesc, '', '')

                  lccatcode = LEFT(m.citemid, 4)

                  DO CASE
                     CASE lccatcode = '{PAY'
                        lcItemListID = m.clistidpre
                     CASE lccatcode = 'ROUN'
                        lcItemListID = m.clistidrnd
                     OTHERWISE
                        SELE expcat
                        LOCATE FOR cCatCode = lccatcode
                        IF FOUND()
                           lcItemListID = cListID
                        ELSE
                           LOOP
                        ENDIF
                  ENDCASE

                  loinvoiceline = loinvoicelist.APPEND

                  IF EMPTY(ALLT(lcItemListID))
                     lcItemListID = lcSuspense
                  ENDIF

                  loinvoiceline.invoicelineadd.itemref.listid.setvalue(lcItemListID)
                  IF lccatcode = '{PAY'
                     loinvoiceline.invoicelineadd.overrideitemaccountref.listid.setvalue(m.cacctno)
                     loinvoiceline.invoicelineadd.DESC.setvalue(m.cItemDesc)
                  ELSE
                     loinvoiceline.invoicelineadd.DESC.setvalue(PADR(ALLT(m.cItemDesc), 25, ' ') + PADR(ALLT(m.cPayee), 25, ' ') + PADL(STR(m.nprice, 9, 2), 11, ' ') + ' X ' + PADL(STR(m.nInterest, 11, 7), 12, ' ') + '%')
                  ENDIF

                  loinvoiceline.invoicelineadd.quantity.setvalue(1)
                  loinvoiceline.invoicelineadd.amount.setvalue(swround(m.nextension, 2))

                  IF NOT EMPTY(m.cunitno)
                     SELE wells
                     LOCATE FOR cWellID = ALLT(m.cunitno)
                     IF FOUND()
                        loinvoiceline.invoicelineadd.classref.listid.setvalue(wells.cListID)
                     ENDIF
                  ENDIF
               ENDSCAN
            ELSE
               SELE jibsummd
               SCAN FOR cbatch == lcbatch
                  SCATTER MEMVAR

                  loinvoiceline = loinvoicelist.APPEND
                  loinvoiceline.invoicelineadd.itemref.FULLNAME.setvalue('Summary')
                  loinvoiceline.invoicelineadd.DESC.setvalue('Summary of JIB Detail')
                  loinvoiceline.invoicelineadd.quantity.setvalue(1)
                  loinvoiceline.invoicelineadd.amount.setvalue(swround(m.nextension, 2))
                  loinvoiceline.invoicelineadd.classref.listid.setvalue(m.cListID)

                  SELECT jibtempd
                  SCAN FOR cunitno == m.cunitno AND ctaxcode = '{P' AND cbatch == lcbatch
                     SCATTER MEMVAR
                     loinvoiceline = loinvoicelist.APPEND
                     loinvoiceline.invoicelineadd.itemref.FULLNAME.setvalue('Summary')
                     loinvoiceline.invoicelineadd.quantity.setvalue(1)
                     loinvoiceline.invoicelineadd.amount.setvalue(swround(m.nextension, 2))
                     loinvoiceline.invoicelineadd.classref.listid.setvalue(m.cListID)
                     loinvoiceline.invoicelineadd.overrideitemaccountref.listid.setvalue(m.cacctno)
                     loinvoiceline.invoicelineadd.DESC.setvalue(m.cItemDesc)
                  ENDSCAN

               ENDSCAN

            ENDIF

            lcxml = THIS.oqbrequest.toxmlstring()
           THIS.SaveXML(m.cCustID, lcXML)

            loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
            loaddresp  = loresponse.responselist.getat(0)

            IF loaddresp.statuscode # 0
               IF 'object' $ LOWER(loaddresp.statusmessage)
                  lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
                  llResult = m.goapp.oQB.QBListID(lcListID)
                  IF llResult

                     SELECT QBListID
                     IF QBListID.ctype = 'Account'
                        lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                           'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                           'and try to close the JIB run again.'
                     ELSE
                        IF 'Acct' $ QBListID.cdescription
                           lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                              'Please choose a new account in ' + ALLTRIM(QBListID.ctype) + ' and try to close the JIB run again.'
                        ELSE
                           lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                              'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to close the JIB run again.'
                        ENDIF
                     ENDIF
                     THIS.omessage.severe(lcMessage)
                  ELSE
                     THIS.omessage.severe(loaddresp.statusmessage)
                  ENDIF
               ELSE
                  THIS.omessage.severe(loaddresp.statusmessage)
               ENDIF
               IF VARTYPE(THIS.oprogress) = 'O'
                  THIS.oprogress.closeprogress()
               ENDIF
               THIS.ClearErrorRecovery()
               * Unpost what has been posted so far this run.
               THIS.qbunpostjib()
               RETURN .F.
            ELSE
               lonewinv = loaddresp.DETAIL
               m.ctxnid = lonewinv.txnid.getvalue()
               SWSELECT('qbpost')
               LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnInvoice
               IF NOT FOUND()
                  m.ntype   = lnInvoice
                  m.mtxnids = m.ctxnid
                  INSERT INTO qbpost FROM MEMVAR
               ELSE
                  IF NOT EMPTY(ALLT(mtxnids))
                     REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
                  ELSE
                     REPL mtxnids WITH m.ctxnid
                  ENDIF
               ENDIF
               SELE jibtemph
               REPL ctxnid WITH m.ctxnid
               THIS.ClearErrorRecovery()
            ENDIF

            THIS.oqbrequest.ClearRequests()
         ENDIF
      ENDSCAN

      *
      *  Post credit invoices
      *

      SELECT jibtemph
      SCAN FOR ninvtot < 0
         SCATTER MEMVAR
         IF jibtemph.ninvtot = 0
            LOOP
         ENDIF

         lnamount = jibtemph.ninvtot
         lcbatch	 = jibtemph.cbatch

         SWSELECT('investor')
         SET ORDER TO cOwnerID
         IF SEEK(jibtemph.ccustid)
            *  Setup the invoice add request
            THIS.oqbrequest.ClearRequests()
            loinvoiceadd = THIS.oqbrequest.appendcreditmemoaddrq()

            lcownname   = cownname
            lcownlistid = cListID
            lcidterms   = cidterm
            IF lchktosec
               IF lcheckonly
                  m.caddress1 = caddress1a
                  m.caddress2 = caddress1b
                  m.ccity	 = ccity1
                  m.czip		 = czip1
               ELSE
                  m.caddress1 = caddress2a
                  m.caddress2 = caddress2b
                  m.ccity	 = ccity2
                  m.czip		 = czip2
               ENDIF
            ELSE
               m.caddress1 = caddress1a
               m.caddress2 = caddress1b
               m.ccity	  = ccity1
               m.czip	  = czip1
            ENDIF

            IF linteggl = .T.
               LOOP
            ENDIF

            loinvoiceadd.customerref.listid.setvalue(lcownlistid)
            loinvoiceadd.araccountref.listid.setvalue(lcaracct)
            loinvoiceadd.istobeprinted.setvalue('False')

            *  Get the terms listid
            SELE terms
            LOCATE FOR cidterm = lcidterms
            IF FOUND()
               loinvoiceadd.termsref.listid.setvalue(terms.cListID)
            ENDIF

            loinvoiceadd.txndate.setvalue(tdPostdate)
            loinvoiceadd.duedate.setvalue(jibtemph.dduedate)
            loinvoiceadd.refnumber.setvalue(jibtemph.cinvnum)
            loinvoiceadd.MEMO.setvalue('** Created by DMIE **')

            loinvoicelist = loinvoiceadd.orcreditmemolineaddlist

            IF NOT llSummarize
               SELE roundtmp
               REPL lused WITH .F. FOR cdmbatch = THIS.cdmbatch

               SELE jibtempd
               SCAN FOR cbatch = lcbatch
                  SCATTER MEMVAR
                  m.nextension = m.nextension * -1
                  lccatcode	  = LEFT(m.citemid, 4)

                  DO CASE
                     CASE lccatcode = '{PAY'
                        lcItemListID = m.clistidpre
                     CASE lccatcode = 'ROUN'
                        lcItemListID = m.clistidrnd
                     OTHERWISE lccatcode # 'ROUN'
                        SELE expcat
                        LOCATE FOR cCatCode = lccatcode
                        IF FOUND()
                           lcItemListID = cListID
                        ELSE
                           LOOP
                        ENDIF
                  ENDCASE

                  loinvoiceline = loinvoicelist.APPEND

                  IF EMPTY(ALLT(lcItemListID))
                     lcItemListID = lcSuspense
                  ENDIF

                  loinvoiceline.creditmemolineadd.itemref.listid.setvalue(lcItemListID)
                  IF lccatcode = '{PAY'
                     loinvoiceline.creditmemolineadd.overrideitemaccountref.listid.setvalue(m.cacctno)
                     loinvoiceline.creditmemolineadd.DESC.setvalue(m.cItemDesc)
                  ELSE
                     loinvoiceline.creditmemolineadd.DESC.setvalue(PADR(ALLT(m.cItemDesc), 25, ' ') + PADR(ALLT(m.cPayee), 25, ' ') + PADL(STR(m.nprice, 9, 2), 11, ' ') + ' X ' + PADL(STR(m.nInterest, 11, 7), 12, ' ') + '%')
                  ENDIF

                  loinvoiceline.creditmemolineadd.quantity.setvalue(1)
                  loinvoiceline.creditmemolineadd.amount.setvalue(swround(m.nextension, 2))

                  IF NOT EMPTY(m.cunitno)
                     SELE wells
                     LOCATE FOR cWellID = ALLT(m.cunitno)
                     IF FOUND()
                        loinvoiceline.creditmemolineadd.classref.listid.setvalue(wells.cListID)
                     ENDIF
                  ENDIF
               ENDSCAN
            ELSE
               SELE jibsummd
               SCAN FOR cbatch == lcbatch
                  SCATTER MEMVAR
                  m.nextension  = m.nextension * -1
                  loinvoiceline = loinvoicelist.APPEND
                  loinvoiceline.creditmemolineadd.itemref.FULLNAME.setvalue('Summary')
                  loinvoiceline.creditmemolineadd.DESC.setvalue('Summary of JIB Detail')
                  loinvoiceline.creditmemolineadd.quantity.setvalue(1)
                  loinvoiceline.creditmemolineadd.amount.setvalue(swround(m.nextension, 2))
                  loinvoiceline.creditmemolineadd.classref.listid.setvalue(m.cListID)
               ENDSCAN
            ENDIF


            lcxml = THIS.oqbrequest.toxmlstring()
            THIS.SaveXML(m.cCustID, lcXML)
            loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
            loaddresp  = loresponse.responselist.getat(0)

            IF loaddresp.statuscode # 0
               IF 'object' $ LOWER(loaddresp.statusmessage)
                  lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
                  llResult = m.goapp.oQB.QBListID(lcListID)
                  IF llResult
                     SELECT QBListID
                     IF QBListID.ctype = 'Account'
                        lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                           'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                           'and try to close the JIB run again.'
                     ELSE
                        IF 'Acct' $ QBListID.cdescription
                           lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                              'Please choose a new account in ' + ALLTRIM(QBListID.ctype) + ' and try to close the JIB run again.'
                        ELSE
                           lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                              'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to close the JIB run again.'
                        ENDIF
                     ENDIF
                     THIS.omessage.severe(lcMessage)
                  ELSE
                     THIS.omessage.severe(loaddresp.statusmessage)
                  ENDIF
               ELSE
                  THIS.omessage.severe(loaddresp.statusmessage)
               ENDIF
               IF VARTYPE(THIS.oprogress) = 'O'
                  THIS.oprogress.closeprogress()
               ENDIF
               THIS.ClearErrorRecovery()
               * Unpost what has been posted so far this run.
               THIS.qbunpostjib()
               RETURN .F.
            ELSE
               lonewinv = loaddresp.DETAIL
               m.ctxnid = lonewinv.txnid.getvalue()
               SWSELECT('qbpost')
               LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnCreditMemo
               IF NOT FOUND()
                  m.ntype   = lnCreditMemo
                  m.mtxnids = m.ctxnid
                  INSERT INTO qbpost FROM MEMVAR
               ELSE
                  IF NOT EMPTY(ALLT(mtxnids))
                     REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
                  ELSE
                     REPL mtxnids WITH m.ctxnid
                  ENDIF
               ENDIF

               SELE jibtemph
               REPL ctxnid WITH m.ctxnid

               THIS.ClearErrorRecovery()
            ENDIF

            THIS.oqbrequest.ClearRequests()
         ENDIF
      ENDSCAN

      SELECT (lcselect)

      THIS.qbpostvendcks()

      * Turn off automated error recovery
      THIS.oqbsm.EnableErrorRecovery		 = .F.
      THIS.oqbsm.SaveAllMsgSetRequestInfo = .F.

      RETURN .T.
   ENDIF
   ENDPROC

   ***************************
   PROCEDURE qbpostrev
   ***************************
   LPARA tcdmbatch
   LOCAL tcyear, tcperiod, tdcheckdate, tcgroup, tdPostdate
   LOCAL lnmax, lncount, lntotal, lcname, lnjibinv, m.ccustname, lcdmbatch, llsepclose
   LOCAL lcRevClear, lcSuspense, m.cdisbacct, m.cvendcomp, m.cgathacct, m.cbackwith
   LOCAL llintegcomp, llsepclose, lcAPAcct, lcacctyear, lcacctmonth, lcidchec
   LOCAL loresponse, lnJournal, lnCheck, lcOwner1, lcOwner2, llJVPosting

   IF THIS.lerrorflag
      RETURN .F.
   ENDIF

   * Fix bad data from a prior update that put the current run in nrunno_in
   SWSELECT('disbhist')
   LOCATE FOR nrunno = THIS.nrunno AND crunyear = THIS.crunyear AND EMPTY(csusptype) AND nrunno_in = nrunno
   IF FOUND()
      SELECT disbhist
      SCAN FOR nrunno = THIS.nrunno AND crunyear = THIS.crunyear AND EMPTY(csusptype) AND nrunno_in = nrunno
         REPLACE nrunno_in WITH 0, ;
            crunyear_in WITH ''
      ENDSCAN
   ENDIF

   THIS.cdmbatch = tcdmbatch
   * Choose the correct txndeltype depending on the SDK.
   IF THIS.qbfcversion > QBFCVER
      lnJournal = 15
      lnCheck   = 6
   ELSE
      lnJournal = 14
      lnCheck   = 11
   ENDIF

   THIS.lquiet	 = .T.
   THIS.nprogress = 1
   THIS.oprogress = THIS.omessage.progressbarex('Processing Revenue Closing for Run: ' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear, ' ')
   THIS.oprogress.setprogressrange(0, 6)

   SWSELECT('sysctl')
   LOCATE FOR cdmbatch = tcdmbatch
   IF FOUND()
      THIS.csysctlkey  = cidsysctl
      m.cidsysctl	  = cidsysctl
      THIS.cgroup	  = cgroup
      THIS.companypost = lCompanyPost
   ELSE
      THIS.omessage.severe('The closing control information cannot be found...')
      RETURN
   ENDIF

   * Get the range of owners for processing
   SWSELECT('investor')
   SET ORDER TO cOwnerID
   GO TOP
   lcOwner1 = cOwnerID
   GO BOTT
   lcOwner2 = cOwnerID

   * Check and clear error recovery status
   THIS.check_error_recovery()

   * set the on error attribute for the request
   THIS.oqbrequest.ATTRIBUTES.OnError = 1

   * Set the automated error recovery
   THIS.oqbsm.EnableErrorRecovery	  = .T.
   THIS.oqbsm.SaveAllMsgSetRequestInfo = .T.
   lcGUID							  = "{B2921009-AB95-475d-A94A-15180BB8C67A}"
   THIS.oqbsm.errorrecoveryid.setvalue(lcGUID)

   * Clear any previous requests
   THIS.oqbrequest.ClearRequests()

   * get a message set request object (version 3.0 xml)
   lorequest = THIS.oqbrequest
   * set the on error attribute for the request
   lorequest.ATTRIBUTES.OnError = 1

   lnmax		  = 0
   lncount	  = 0
   lntotal	  = 0
   lcname	  = 'Owner'
   m.ccustname = ' '
   lcidchec	  = ''

   lcacctyear  = STR(YEAR(THIS.dpostdate), 4)
   lcacctmonth = PADL(ALLTRIM(STR(MONTH(THIS.dpostdate), 2)), 2, '0')

   IF THIS.companypost = .T.
      tdCompanyPost = THIS.dpostdate
      tdPostdate	   = THIS.dacctdate
   ELSE
      tdCompanyPost = THIS.dpostdate
      tdPostdate	   = THIS.dpostdate
   ENDIF

   *
   *  Get the suspense account from glopt
   *
   SWSELECT('glopt')
   lcRevClear = crevclear
   lcExpClear = cexpclear
   llQBPost	 = .T.
   lcSuspense = csuspense

   IF EMPTY(lcRevClear)
      MESSAGEBOX('The revenue clearing account needs to be specified in Account Settings ' + ;
         'please specify the account and then close the revenue period again.', 0, 'Setup Problem')
      RETURN .F.
   ENDIF
   IF EMPTY(lcExpClear)
      MESSAGEBOX('The expense clearing account needs to be specified in Account Settings ' + ;
         'please specify the account and then close the revenue period again.', 0, 'Setup Problem')
      RETURN .F.
   ENDIF

   *
   *  Get the A/P account
   *
   SWSELECT('apopt')
   lcAPAcct = cAPAcct

   *
   *  Set up the parameters used by processing in this method
   *
   tcyear   = THIS.crunyear
   tcperiod = THIS.cperiod
   tcgroup  = THIS.cgroup

   *  Get the current last suspense types.  The posting should be based on the current suspense
   *  type, and not by the suspense type on each individual entry.  If a deficit switches to a minimum,
   *  for example, it clears the deficit balance and posts it to the minimum account at the
   *  time it occurs.  That means that all of the entries being processed should be getting posted
   *  the same way, regardless of their original suspense types.
   IF VARTYPE(oSuspense) # 'O'
      oSuspense = CREATEOBJECT('suspense')
   ENDIF
   oSuspense.crunyear = THIS.crunyear
   oSuspense.nrunno	 = THIS.nrunno
   oSuspense.cgroup	 = THIS.cgroup

   oSuspense.GetLastType(.F., .T., tcgroup, .T.)

   IF EMPTY(lcSuspense)
      MESSAGEBOX('The "Catch-All" account has not been specified in the Account Defaults.  Please specify a catch-all account before continuing.', 0, 'Account Problem')
      RETURN .F.
   ENDIF

   *  Open the QB Transaction Table
   SWSELECT('qbpost')

   ****************************************************************
   *   Get Disbursement Checking Acct Number
   ****************************************************************
   SWSELECT('options')
   GO TOP
   m.cdisbacct = cdisbacct
   IF EMPTY(ALLT(m.cdisbacct))
      m.cdisbacct = lcSuspense
   ENDIF
   m.cvendcomp = cvendcomp
   IF EMPTY(ALLT(m.cvendcomp))
      m.cvendcomp = lcSuspense
   ENDIF
   m.cgathacct = cgathacct
   IF EMPTY(ALLT(m.cgathacct))
      m.cgathacct = lcSuspense
   ENDIF
   m.cbackwith = cbackacct
   IF EMPTY(ALLT(m.cbackwith))
      m.cbackwith = lcSuspense
   ENDIF
   m.ctaxwith = ctaxacct
   IF EMPTY(ALLT(m.ctaxwith))
      m.ctaxwith = lcSuspense
   ENDIF
   m.ctaxacct1  = ctaxacct1
   IF EMPTY(ALLT(m.ctaxacct1))
      m.ctaxacct1 = lcSuspense
   ENDIF
   m.ctaxacct2  = ctaxacct2
   IF EMPTY(ALLT(m.ctaxacct2))
      m.ctaxacct2 = lcSuspense
   ENDIF
   m.ctaxacct3  = ctaxacct3
   IF EMPTY(ALLT(m.ctaxacct3))
      m.ctaxacct3 = lcSuspense
   ENDIF
   m.ctaxacct4 = ctaxacct4
   IF EMPTY(ALLT(m.ctaxacct4))
      m.ctaxacct4 = lcSuspense
   ENDIF
   m.cdefacct  = cdefacct
   IF EMPTY(ALLT(m.cdefacct))
      m.cdefacct = lcSuspense
   ENDIF
   m.cminacct  = cminacct
   IF EMPTY((m.cminacct))
      m.cminacct = lcSuspense
   ENDIF

   *  Get the account fixed expenses and well expenses by well expenses are to be posted to.
   lcdmexp = cfixedacct
   IF EMPTY(lcdmexp)
      lcdmexp = lcAPAcct
   ENDIF

   IF EMPTY(lcdmexp)
      MESSAGEBOX('The fixed expense clearing account needs to be specified in Disbursement and JIB Options.' + ;
         'please specify the account and then close the revenue period again.', 0, 'Setup Problem')
      RETURN .F.
   ENDIF

   llsepclose  = options.lsepclose

   * Check to see if the deficit account is a receivable acct
   * The posting will have to be changed to group deficits by
   * owner if the account is a receivable acct.
   llReceivable = .F.
   m.goapp.oQB.QBAccounts('', .F., .T., .F.)
   SELECT accounts
   LOCATE FOR cListID = m.cdefacct
   IF FOUND()
      IF 'receivable' $ LOWER(cAcctType)
         llReceivable = .T.
      ELSE
         llReceivable = .F.
      ENDIF
   ENDIF

   IF m.goapp.lPartnershipMod
      SWSELECT('progopt')
      GO TOP
      llJVPosting = lJVPosting
      lcCapitalAcct = cCapAcct
   ELSE
      llJVPosting = .F.
      lcCapitalAcct = lcSuspense
   ENDIF

   ******************************************************************
   *   Check to see if vendor compression & gathering is to be posted
   ******************************************************************
   llintegcomp = .F.

   IF NOT EMPTY(m.cvendcomp)
      SWSELECT('vendor')
      SET ORDER TO cVendorID
      IF SEEK(m.cvendcomp)
         IF linteggl
            llintegcomp = .T.
         ENDIF
      ENDIF
   ENDIF

   IF NOT THIS.lquiet
      THIS.oprogress.SetProgressMessage('Removing Zero Amount Records From Temp Owner Activity...')
      THIS.oprogress.updateprogress(THIS.nprogress)
      THIS.nprogress = THIS.nprogress + 1
   ENDIF

   *
   *  Remove zero records from invtmp and change the csusptype to correct type
   *

   WAIT WIND NOWAIT 'Removing records with no activity...'
   SELE invtmp
   SET ORDER TO 0
   SCAN
      SCATTER MEMVAR
      IF m.nincome = 0 AND m.nexpense = 0 AND m.nsevtaxes = 0 AND m.nnetcheck = 0 AND m.nmktgexp = 0
         SWSELECT('income')
         LOCATE FOR cWellID = m.cWellID AND nrunno = m.nrunno AND crunyear = m.crunyear
         IF NOT FOUND()
            SWSELECT('expense')
            LOCATE FOR cWellID = m.cWellID AND nrunnorev = m.nrunno AND crunyearrev = m.crunyear
            IF NOT FOUND()
               SWSELECT('invtmp')
               DELE NEXT 1
            ENDIF
         ENDIF
      ELSE
         IF NOT EMPTY(m.csusptype)
            SELECT curLastSuspType
            LOCATE FOR cOwnerID == m.cOwnerID AND cWellID == m.cWellID AND NOT EMPTY(csusptype)
            IF FOUND()
               SELECT invtmp
               REPLACE csusptype WITH curLastSuspType.csusptype
            ENDIF
         ENDIF
      ENDIF
   ENDSCAN
   WAIT CLEAR

   *********************************************************************
   *   Post owner checks to register
   *********************************************************************
   SWSELECT('wells')
   SET ORDER TO cWellID

   IF THIS.lqbactive AND llQBPost
      IF THIS.lquiet
         THIS.oprogress.SetProgressMessage('Posting Owner Checks to QuickBooks...')
         THIS.oprogress.updateprogress(THIS.nprogress)
         THIS.nprogress = THIS.nprogress + 1
      ENDIF
      CREATE CURSOR tmpowners ;
         (cOwnerID   c(10), ;
         cidchec   c(8), ;
         hyear     c(4), ;
         hperiod   c(2), ;
         ntotal     N(12, 2),  ;
         ntotinc    N(12, 2),  ;
         ntotexp    N(12, 2),  ;
         ntottax    N(12, 2))

      INDEX ON cOwnerID TAG owner


      * Check to see if prior suspense is in invtmp and it includes payments that zero it out
      * If any are found, remove them because we don't want to post them here..they've already been posted when the payment was entered.
      llSuspenseZero = .F.
      SELECT  * ;
         FROM invtmp ;
         WHERE BETWEEN(cOwnerID, lcOwner1, lcOwner2)   ;
         AND crectype # 'P' ;
         AND NOT EMPTY(crunyear_in);
         AND (crunyear + PADL(TRANSFORM(nrunno), 3, '0') # crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0')) ;
         INTO CURSOR tempinvtmp READWRITE NOFILTER
      SELECT  * ;
         FROM disbhist ;
         WHERE BETWEEN(cOwnerID, lcOwner1, lcOwner2) ;
         AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') = THIS.crunyear + PADL(TRANSFORM(THIS.nrunno), 3, '0') ;
         OR  crunyear + PADL(TRANSFORM(nrunno), 3, '0') = THIS.crunyear + PADL(TRANSFORM(THIS.nrunno), 3, '0')) ;
         AND crectype = 'P' ;
         INTO CURSOR tmptmp NOFILTER

      SELECT tempinvtmp
      APPEND FROM DBF('tmptmp')
      USE IN tmptmp
      SELECT tempinvtmp
      IF RECCOUNT() > 0
         SELECT cOwnerID, SUM(nnetcheck) AS nnetcheck FROM tempinvtmp WHERE nrunno_in # 0 INTO CURSOR temp ORDER BY cOwnerID GROUP BY cOwnerID
         SCAN FOR nnetcheck = 0
            m.cOwnerID = cOwnerID
            * Set the flag that tells later processing that suspense was zeroed out
            * so it doesn't try to post a suspense balance
            llSuspenseZero = .T.
            SELECT invtmp
            DELETE FOR cOwnerID == m.cOwnerID AND nrunno_in # 0 AND crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < THIS.crunyear + PADL(TRANSFORM(THIS.nrunno), 3, '0')
         ENDSCAN
      ENDIF

      * Make sure cidchec is correct in invtmp
      * Only mark the records making up this check.
      SELE invtmp
      SCAN FOR EMPTY(nrunno_in) OR (PADL(TRANSFORM(nrunno_in), 3, '0') + crunyear_in # PADL(TRANSFORM(nrunno), 3, '0') + crunyear)
         lcidchec   = cidchec
         m.cOwnerID = cOwnerID
         SWSELECT('checks')
         LOCATE FOR cbatch = tcdmbatch AND cid = m.cOwnerID
         IF FOUND()
            IF cidchec # lcidchec
               SELE invtmp
               REPL cidchec WITH checks.cidchec
            ENDIF
         ELSE
            SELE invtmp
            REPL cidchec WITH ''
         ENDIF
      ENDSCAN


      * Get a cursor of owners to be posted from invtmp
      SELECT  cOwnerID, ;
         cidchec, ;
         hyear, ;
         hperiod, ;
         SUM(nnetcheck) AS ntotal, ;
         SUM(nincome) AS ntotinc, ;
         SUM(nexpense + ntotale1 + ntotale2 + ntotale3 + ntotale4 + ntotale5 + ntotalea + ntotaleb) AS ntotexp, ;
         SUM(nsevtaxes) AS ntottax  ;
         FROM invtmp ;
         WHERE NOT EMPTY(cidchec) ;
         AND (nnetcheck # 0 OR (nincome # 0 OR nexpense # 0 OR nsevtaxes # 0)) ;
         AND (EMPTY(nrunno_in) OR (PADL(TRANSFORM(nrunno_in), 3, '0') + crunyear_in # PADL(TRANSFORM(nrunno), 3, '0') + crunyear)) ;
         ORDER BY cOwnerID ;
         GROUP BY cOwnerID  ;
         INTO CURSOR tmp
      lnmax = _TALLY
      IF lnmax > 0
         SELE tmpowners
         APPEND FROM DBF('tmp')
      ENDIF

      lncount = 1

      IF NOT THIS.lquiet
         THIS.oprogress = THIS.omessage.progressbarex('Posting owner checks to QuickBooks...', ' ')
         THIS.oprogress.setprogressrange(0, lnmax)
      ENDIF
      SELECT tmpowners
      SCAN FOR ntotal > 0

         m.cOwnerID = cOwnerID
         m.ntotal   = ntotal
         lcidchec   = cidchec

         IF ntotinc = 0 AND ntotexp = 0 AND ntottax = 0 AND ntotal = 0
            LOOP
         ENDIF
         m.lExempt = .F.
         SWSELECT('investor')
         SET ORDER TO cOwnerID
         IF SEEK(m.cOwnerID)
            m.cownname	 = cownname
            lcownerlistid = cListID
            m.lExempt	 = lExempt
            IF NOT EMPTY(investor.cchkmemo1)
               m.cmemo = ALLTRIM(investor.cchkmemo1)
            ELSE
               m.cmemo = ''
            ENDIF
            IF EMPTY(cListID)
               MESSAGEBOX('The owner file needs to be synchronized with QuickBooks. ' + ;
                  'please synchronize and then close the revenue period again.', 0, 'Synchronization Problem')
               RETURN .F.
            ENDIF
            * Don't post owners that are transfered to G/L here.
            IF linteggl
               LOOP
            ENDIF
            IF NOT THIS.lquiet
               THIS.oprogress.SetProgressMessage(ALLT(m.cOwnerID) + ' - ' + ALLT(m.cownname))
               THIS.oprogress.updateprogress(lncount)
               lncount = lncount + 1
            ENDIF
            * Don't post "Dummy" owner amounts
            IF lDummy
               LOOP
            ENDIF
         ELSE
            LOOP
         ENDIF

         SWSELECT('checks')
         LOCATE FOR cidchec = lcidchec
         IF FOUND()
            lcCheckNo = ccheckno
         ELSE
            LOOP
         ENDIF

         *  Set the post flag
         llpostqb = .F.

         * get a message set request object (version 3.0 xml)
         lorequest = THIS.oqbrequest
         * set the on error attribute for the request
         lorequest.ATTRIBUTES.OnError = 1
         lorequest.ClearRequests()

         *  Setup the check add request
         locheckadd = lorequest.appendcheckaddrq()
         locheckadd.txndate.setvalue(tdPostdate)
         locheckadd.payeeentityref.listid.setvalue(lcownerlistid)
         locheckadd.accountref.listid.setvalue(m.cdisbacct)
         locheckadd.istobeprinted.setvalue(0)
         locheckadd.refnumber.setvalue(lcCheckNo)

         IF llJVPosting

            SELECT invtmp
            LOCATE FOR cOwnerID = m.cOwnerID
            IF FOUND()
               m.hperiod = hperiod
               m.hyear   = hyear
            ENDIF
            IF NOT EMPTY(THIS.cCheckMemo)
               locheckadd.MEMO.setvalue(THIS.cCheckMemo)
            ELSE
               locheckadd.MEMO.setvalue(getmonth(m.hperiod) + ' ' + m.hyear + ' ' + STRTRAN(ALLTRIM(m.goapp.cCompanyName),'GCW ','') + ' Distribution')
            ENDIF
            loexpenseline = locheckadd.expenselineaddlist.APPEND
            loexpenseline.amount.setvalue(ROUND(tmpowners.ntotal, 2))
            loexpenseline.accountref.listid.setvalue(lcCapitalAcct)
            llpostqb = .T.
            IF NOT EMPTY(THIS.cCheckMemo)
               loexpenseline.MEMO.setvalue(THIS.cCheckMemo)
            ELSE
               loexpenseline.MEMO.setvalue(getmonth(m.hperiod) + ' ' + m.hyear + ' ' + STRTRAN(ALLTRIM(m.goapp.cCompanyName),'GCW ','') + ' Distribution')
            ENDIF
            lcxml = THIS.oqbrequest.toxmlstring()
            THIS.SaveXML(m.cOwnerID, lcXML)
            loresponse = THIS.oqbsm.dorequests(lorequest)
            loaddresp  = loresponse.responselist.getat(0)

            IF loaddresp.statuscode = 0
               lonewbill = loaddresp.DETAIL
               m.ctxnid	 = lonewbill.txnid.getvalue()
               SWSELECT('qbpost')
               LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnCheck
               IF NOT FOUND()
                  m.ntype	= lnCheck
                  m.mtxnids	= m.ctxnid
                  INSERT INTO qbpost FROM MEMVAR
               ELSE
                  IF NOT EMPTY(ALLT(mtxnids))
                     REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
                  ELSE
                     REPL mtxnids WITH m.ctxnid
                  ENDIF
               ENDIF

               SWSELECT('checks')
               LOCATE FOR cbatch = THIS.cdmbatch AND cid = m.cOwnerID
               IF FOUND()
                  REPL ctxnid WITH m.ctxnid
               ENDIF

               THIS.ClearErrorRecovery()
            ELSE
               THIS.omessage.severe('Posting owner: ' + ALLTRIM(m.cOwnerID) + ' - ' + loaddresp.statusmessage)
               RETURN .F.
            ENDIF
            LOOP
         ELSE
            locheckadd.MEMO.setvalue(m.cmemo)
         ENDIF

         m.cidchec = ' '

         lccheckkey = lcidchec

         * Scan invtmp for records that made up this check. Make sure that no records going to
         * suspense this run are included. They shouldn't be showing in invtmp but sometimes
         * they are.
         SELECT invtmp
         SCAN FOR cOwnerID = m.cOwnerID AND (nnetcheck # 0 OR (nincome # 0 OR nexpense # 0 OR nsevtaxes # 0)) ;
               AND (EMPTY(nrunno_in) OR (PADL(TRANSFORM(nrunno_in), 3, '0') + crunyear_in # PADL(TRANSFORM(nrunno), 3, '0') + crunyear))
            SCATTER MEMVAR

            SWSELECT('wells')
            IF SEEK(m.cWellID)
               SCATTER FIELDS LIKE lsev* MEMVAR

               m.ldiroilpurch = wells.ldiroilpurch
               m.ldirgaspurch = wells.ldirgaspurch
               lcwelllistid	 = wells.cListID
               IF EMPTY(wells.cListID)
                  IF wells.cwellstat = 'I'
                     REPLACE cListID WITH ALLTRIM(wells.cWellID) + '-' + ALLTRIM(wells.cwellname)
                     LOOP
                  ELSE
                     MESSAGEBOX('The wells file needs to be synchronized with QuickBooks. ' + ;
                        'Please synchronize and then close the revenue run again.', 0, 'Synchronization Problem')
                     RETURN .F.
                  ENDIF
               ENDIF
               llvalidwell = .T.
            ELSE
               m.ldiroilpurch = .F.
               m.ldirgaspurch = .F.
               STORE .F. TO m.lsev1o, m.lsev2o, m.lsev3o, m.lsev4o
               STORE .F. TO m.lsev1g, m.lsev2g, m.lsev3g, m.lsev4g
               STORE .F. TO m.lsev1p, m.lsev2p, m.lsev3p, m.lsev4p
               lcwelllistid = ''
               llvalidwell  = .F.
            ENDIF

            * Don't post prior suspense in this section
            IF NOT INLIST(m.csusptype, 'D', 'M', 'I', 'H', 'Q', 'S', 'A', 'P')
               lnincome   = m.nincome
               *  Remove direct paid amounts
               DO CASE
                  CASE m.cdirect = 'O'
                     lnincome = lnincome - m.noilrev
                  CASE m.cdirect = 'G'
                     lnincome = lnincome - m.ngasrev
                  CASE m.cdirect = 'B'
                     lnincome = lnincome - m.noilrev - m.ngasrev
               ENDCASE
               lnincome = ROUND(lnincome, 2)
               * Post the Revenue
               IF NOT m.lflat
                  IF lnincome # 0
                     loexpenseline = locheckadd.expenselineaddlist.APPEND
                     loexpenseline.amount.setvalue(ROUND(lnincome, 2))
                     loexpenseline.accountref.listid.setvalue(lcRevClear)
                     llpostqb = .T.
                     IF llvalidwell
                        loexpenseline.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loexpenseline.MEMO.setvalue('Revenue ' + m.hyear + '/' + m.hperiod)
                  ENDIF
               ELSE
                  IF m.nflatrate # 0
                     loexpenseline = locheckadd.expenselineaddlist.APPEND
                     loexpenseline.amount.setvalue(ROUND(m.nflatrate, 2))
                     loexpenseline.accountref.listid.setvalue(lcRevClear)
                     llpostqb = .T.
                     IF llvalidwell
                        loexpenseline.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loexpenseline.MEMO.setvalue('Flat-Rate Royalty ' + m.hyear + '/' + m.hperiod)
                  ENDIF
               ENDIF

               * If the owner is exempt, make sure no taxes post
               IF m.lExempt
                  STORE 0 TO m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4
                  STORE 0 TO m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4
                  STORE 0 TO m.nothtax1, m.nothtax2, m.nothtax3, m.nothtax4
               ENDIF

               * Post the sev taxes
               IF m.noiltax1 # 0
                  IF NOT m.lsev1o
                     IF INLIST(m.cdirect, 'B', 'O')
                        IF NOT m.ldiroilpurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.noiltax1, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(m.ctaxacct1)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ELSE
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.noiltax1, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(m.ctaxacct1)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'O')
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.noiltax1, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(lcRevClear)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                     ELSE
                        IF NOT m.ldiroilpurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.noiltax1, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(lcRevClear)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.ngastax1 # 0
                  IF NOT m.lsev1g
                     IF INLIST(m.cdirect, 'B', 'G')
                        IF NOT m.ldirgaspurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.ngastax1, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(m.ctaxacct1)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ELSE
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.ngastax1, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(m.ctaxacct1)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'G')
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.ngastax1, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(lcRevClear)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                     ELSE
                        IF NOT m.ldirgaspurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.ngastax1, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(lcRevClear)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.nothtax1 # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nothtax1, 2) * -1)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Other Tax 1 ' + m.hyear + '/' + m.hperiod)
                  IF NOT m.lsev1p
                     loexpenseline.accountref.listid.setvalue(m.ctaxacct1)
                  ELSE
                     loexpenseline.accountref.listid.setvalue(lcRevClear)
                  ENDIF
               ENDIF

               IF m.noiltax2 # 0
                  IF NOT m.lsev2o
                     IF INLIST(m.cdirect, 'B', 'O')
                        IF NOT m.ldiroilpurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.noiltax2, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(m.ctaxacct2)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ELSE
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.noiltax2, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(m.ctaxacct2)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'O')
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.noiltax2, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(lcRevClear)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                     ELSE
                        IF NOT m.ldiroilpurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.noiltax2, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(lcRevClear)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.ngastax2 # 0
                  IF NOT m.lsev2g
                     IF INLIST(m.cdirect, 'B', 'G')
                        IF NOT m.ldirgaspurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.ngastax2, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(m.ctaxacct2)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ELSE
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.ngastax2, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(m.ctaxacct2)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'G')
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.ngastax2, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(lcRevClear)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                     ELSE
                        IF NOT m.ldirgaspurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.ngastax2, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(lcRevClear)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.nothtax2 # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nothtax2, 2) * -1)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Other Tax 2 ' + m.hyear + '/' + m.hperiod)
                  IF NOT m.lsev1p
                     loexpenseline.accountref.listid.setvalue(m.ctaxacct2)
                  ELSE
                     loexpenseline.accountref.listid.setvalue(lcRevClear)
                  ENDIF
               ENDIF

               * Post the sev taxes
               IF m.noiltax3 # 0
                  IF NOT m.lsev3o
                     IF INLIST(m.cdirect, 'B', 'O')
                        IF NOT m.ldiroilpurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.noiltax3, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(m.ctaxacct3)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ELSE
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.noiltax3, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(m.ctaxacct3)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'O')
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.noiltax3, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(lcRevClear)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                     ELSE
                        IF NOT m.ldiroilpurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.noiltax3, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(lcRevClear)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.ngastax3 # 0
                  IF NOT m.lsev3g
                     IF INLIST(m.cdirect, 'B', 'G')
                        IF NOT m.ldirgaspurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.ngastax3, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(m.ctaxacct3)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ELSE
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.ngastax3, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(m.ctaxacct3)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'G')
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.ngastax3, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(lcRevClear)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                     ELSE
                        IF NOT m.ldirgaspurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.ngastax3, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(lcRevClear)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.nothtax3 # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nothtax3, 2) * -1)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Other Tax 3 ' + m.hyear + '/' + m.hperiod)
                  IF NOT m.lsev1p
                     loexpenseline.accountref.listid.setvalue(m.ctaxacct3)
                  ELSE
                     loexpenseline.accountref.listid.setvalue(lcRevClear)
                  ENDIF
               ENDIF

               * Post the sev taxes
               IF m.noiltax4 # 0
                  IF NOT m.lsev4o
                     IF INLIST(m.cdirect, 'B', 'O')
                        IF NOT m.ldiroilpurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.noiltax4, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(m.ctaxacct4)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ELSE
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.noiltax4, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(m.ctaxacct4)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'O')
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.noiltax4, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(lcRevClear)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                     ELSE
                        IF NOT m.ldiroilpurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.noiltax4, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(lcRevClear)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.ngastax4 # 0
                  IF NOT m.lsev4g
                     IF INLIST(m.cdirect, 'B', 'G')
                        IF NOT m.ldirgaspurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.ngastax4, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(lcRevClear)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ELSE
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.ngastax4, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(m.ctaxacct4)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'G')
                        loexpenseline = locheckadd.expenselineaddlist.APPEND
                        loexpenseline.amount.setvalue(ROUND(m.ngastax4, 2) * -1)
                        loexpenseline.accountref.listid.setvalue(lcRevClear)
                        llpostqb = .T.
                        IF llvalidwell
                           loexpenseline.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loexpenseline.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                     ELSE
                        IF NOT m.ldirgaspurch
                           loexpenseline = locheckadd.expenselineaddlist.APPEND
                           loexpenseline.amount.setvalue(ROUND(m.ngastax4, 2) * -1)
                           loexpenseline.accountref.listid.setvalue(lcRevClear)
                           llpostqb = .T.
                           IF llvalidwell
                              loexpenseline.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loexpenseline.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.nothtax4 # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nothtax4, 2) * -1)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Other Tax 4 ' + m.hyear + '/' + m.hperiod)
                  IF NOT m.lsev1p
                     loexpenseline.accountref.listid.setvalue(m.ctaxacct4)
                  ELSE
                     loexpenseline.accountref.listid.setvalue(lcRevClear)
                  ENDIF
               ENDIF

               *
               *  Post compression and gathering
               *
               IF m.ncompress # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.ncompress, 2) * -1)
                  loexpenseline.accountref.listid.setvalue(lcRevClear)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Compression Charge ' + m.hyear + '/' + m.hperiod)
               ENDIF

               IF m.ngather # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.ngather, 2) * -1)
                  loexpenseline.accountref.listid.setvalue(lcRevClear)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Gathering Charge ' + m.hyear + '/' + m.hperiod)
               ENDIF

               *
               *  Post marketing expenses
               *
               IF m.nmktgexp # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nmktgexp, 2) * -1)
                  loexpenseline.accountref.listid.setvalue(lcExpClear)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Marketing Expense ' + m.hyear + '/' + m.hperiod)
               ENDIF

               *  Post the Expenses
               lnexpense = m.nexpense + ;
                  m.ntotale1 + ;
                  m.ntotale2 + ;
                  m.ntotale3 + ;
                  m.ntotale4 + ;
                  m.ntotale5 + ;
                  m.ntotalea + ;
                  m.ntotaleb + ;
                  m.nPlugExp

               IF lnexpense # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(lnexpense, 2) * -1)
                  loexpenseline.accountref.listid.setvalue(lcExpClear)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Well Expenses: ' + m.hyear + '/' + m.hperiod)
               ENDIF

               *  Post Backup Withholding
               IF m.nbackwith # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nbackwith, 2) * -1)
                  loexpenseline.accountref.listid.setvalue(m.cbackwith)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Backup Withholding')
               ENDIF

               *  Post Tax Withholding
               IF m.ntaxwith # 0
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.ntaxwith, 2) * -1)
                  loexpenseline.accountref.listid.setvalue(m.ctaxwith)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Income Tax W/H')
               ENDIF
            ENDIF

         ENDSCAN

         * Post prior suspense
         IF NOT llReceivable
            * Deficit account is not a receivable account so deficits don't have to be grouped by owner
            SELECT invtmp
            SCAN FOR cOwnerID = m.cOwnerID AND (nincome # 0 OR nexpense # 0 OR nsevtaxes # 0 OR nnetcheck # 0) ;
                  AND (PADL(TRANSFORM(nrunno_in), 3, '0') + crunyear_in # PADL(TRANSFORM(nrunno), 3, '0') + crunyear)
               SCATTER MEMVAR

               *  Match this owner/well to their current suspense type, so it posts using
               *  that instead of whatever suspense type was originally on the entry.
               *  Non-suspense entries won't have a csusptype filled in, so only do thi
               *  if the csusptype isn't empty.
               IF USED('CurLastSuspType') AND NOT EMPTY(m.csusptype)
                  SELECT curLastSuspType
                  LOCATE FOR cOwnerID == m.cOwnerID AND cWellID == m.cWellID
                  IF FOUND()
                     m.csusptype = curLastSuspType.csusptype
                  ENDIF
               ENDIF

               *  Make sure the correct well's clistid is chosen
               SWSELECT('wells')
               IF SEEK(m.cWellID)
                  lcwelllistid = wells.cListID
                  llvalidwell  = .T.
               ELSE
                  lcwelllistid = ''
                  llvalidwell  = .F.
               ENDIF

               *  Post Prior Period Deficits
               IF m.csusptype = 'D'
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nnetcheck, 2))
                  loexpenseline.accountref.listid.setvalue(m.cdefacct)
                  loexpenseline.customerref.listid.setvalue(lcownerlistid)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Prior Deficits')
               ENDIF

               *  Post Prior Period Minimums
               IF m.csusptype = 'M'
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nnetcheck, 2))
                  loexpenseline.accountref.listid.setvalue(m.cminacct)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Prior Minimums')
               ENDIF

               *  Post Interest on Hold being released
               IF m.csusptype = 'I'
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nnetcheck, 2))
                  loexpenseline.accountref.listid.setvalue(m.cminacct)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Interest On Hold Released')
               ENDIF

               *  Post Owner on Hold being released
               IF m.csusptype = 'H'
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nnetcheck, 2))
                  loexpenseline.accountref.listid.setvalue(m.cminacct)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loexpenseline.MEMO.setvalue('Owner On Hold Released')
               ENDIF

               *  Post Owner frequency suspense being released
               IF INLIST(m.csusptype, 'A', 'Q', 'S')
                  loexpenseline = locheckadd.expenselineaddlist.APPEND
                  loexpenseline.amount.setvalue(ROUND(m.nnetcheck, 2))
                  loexpenseline.accountref.listid.setvalue(m.cminacct)
                  llpostqb = .T.
                  IF llvalidwell
                     loexpenseline.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  DO CASE
                     CASE m.csusptype = 'A'
                        loexpenseline.MEMO.setvalue('Annual Pay Released')
                     CASE m.csusptype = 'Q'
                        loexpenseline.MEMO.setvalue('Quarterly Pay Released')
                     CASE m.csusptype = 'S'
                        loexpenseline.MEMO.setvalue('Semi-Annual Pay Released')
                  ENDCASE
               ENDIF
            ENDSCAN
         ELSE
            * The deficit account is a receivable account so deficits have to be grouped
            * by owner since we can only post to one receivable account in a journal entry.
            STORE 0 TO lnDefSave, lnLegalSave
            SELECT invtmp
            SCAN FOR cOwnerID = m.cOwnerID AND (nincome # 0 OR nexpense # 0 OR nsevtaxes # 0 OR nnetcheck # 0) ;
                  AND (NOT EMPTY(nrunno_in) AND (PADL(TRANSFORM(nrunno_in), 3, '0') + crunyear_in # PADL(TRANSFORM(nrunno), 3, '0') + crunyear))
               SCATTER MEMVAR
               IF m.csusptype = 'D'
                  lnDefSave = lnDefSave + ROUND(m.nnetcheck, 2)
               ELSE
                  lnLegalSave = lnLegalSave + ROUND(m.nnetcheck, 2)
               ENDIF
            ENDSCAN
            *  Post Prior Period Deficits
            IF lnDefSave # 0
               loexpenseline = locheckadd.expenselineaddlist.APPEND
               loexpenseline.amount.setvalue(ROUND(lnDefSave, 2))
               loexpenseline.accountref.listid.setvalue(m.cdefacct)
               loexpenseline.customerref.listid.setvalue(lcownerlistid)
               llpostqb = .T.
               loexpenseline.MEMO.setvalue('Prior Deficits')
            ENDIF

            *  Post Prior Period Minimums
            IF lnLegalSave # 0
               loexpenseline = locheckadd.expenselineaddlist.APPEND
               loexpenseline.amount.setvalue(ROUND(lnLegalSave, 2))
               loexpenseline.accountref.listid.setvalue(m.cminacct)
               llpostqb = .T.
               loexpenseline.MEMO.setvalue('Legal Suspense')
            ENDIF

         ENDIF && llReceivable

         lcxml = THIS.oqbrequest.toxmlstring()
            THIS.SaveXML(m.cOwnerID, lcXML)
         loresponse = THIS.oqbsm.dorequests(lorequest)
         loaddresp  = loresponse.responselist.getat(0)

         IF loaddresp.statuscode # 0
            IF 'object' $ LOWER(loaddresp.statusmessage)
               lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
               llResult = m.goapp.oQB.QBListID(lcListID)
               IF llResult
                  SELECT QBListID
                  IF QBListID.ctype = 'Account'
                     lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                        'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                        'and try to post again.'
                  ELSE
                     IF 'Acct' $ QBListID.cdescription
                        lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                           'Please choose a new account in ' + ALLTRIM(QBListID.ctype) + ' and try to post again.'
                     ELSE
                        lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                           'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to post again.'
                     ENDIF
                  ENDIF
                  THIS.omessage.severe(lcMessage)
               ELSE
                  THIS.omessage.severe('Posting owner: ' + ALLTRIM(m.cOwnerID) + ' - ' + loaddresp.statusmessage)
               ENDIF
            ELSE
               THIS.omessage.severe(loaddresp.statusmessage)
            ENDIF
            IF VARTYPE(THIS.oprogress) = 'O'
               THIS.oprogress.closeprogress()
            ENDIF
            THIS.ClearErrorRecovery()
            RETURN .F.
         ELSE
            lonewbill = loaddresp.DETAIL
            m.ctxnid	 = lonewbill.txnid.getvalue()
            SWSELECT('qbpost')
            LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnCheck
            IF NOT FOUND()
               m.ntype	= lnCheck
               m.mtxnids	= m.ctxnid
               INSERT INTO qbpost FROM MEMVAR
            ELSE
               IF NOT EMPTY(ALLT(mtxnids))
                  REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
               ELSE
                  REPL mtxnids WITH m.ctxnid
               ENDIF
            ENDIF

            SWSELECT('checks')
            LOCATE FOR cbatch = THIS.cdmbatch AND cid = m.cOwnerID
            IF FOUND()
               REPL ctxnid WITH m.ctxnid
            ENDIF

            THIS.ClearErrorRecovery()
         ENDIF
         THIS.oqbrequest.ClearRequests()

      ENDSCAN

      IF NOT THIS.lquiet
         IF VARTYPE(THIS.oprogress) = 'O'
            THIS.oprogress.closeprogress()
         ENDIF

         DOEVENTS
         THIS.oprogress = .NULL.
      ENDIF
   ENDIF

   * Clear any previous requests
   THIS.oqbrequest.ClearRequests()

   ************************************************************
   *   Process compression & gathering charges
   ************************************************************
   SELECT  SUM(ncompress + ngather) AS ntot ;
      FROM wellhist ;
      WHERE nrunno = THIS.nrunno ;
      AND crunyear = THIS.crunyear ;
      AND cgroup   = THIS.cgroup ;
      INTO CURSOR temp

   IF THIS.lquiet
      THIS.oprogress.SetProgressMessage('Posting Compression/Gathering to QuickBooks...')
      THIS.oprogress.updateprogress(THIS.nprogress)
      THIS.nprogress = THIS.nprogress + 1
   ENDIF
   SELE temp
   GO TOP
   lnactivity = ntot
   IF lnactivity # 0
      *  Setup the journal add request
      loentryadd = THIS.oqbrequest.appendjournalentryaddrq()
      loentryadd.txndate.setvalue(tdPostdate)
      loentryadd.refnumber.setvalue('DM-' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear)
      *   loentryadd.MEMO.setvalue('** DO NOT CHANGE OR DELETE THIS ENTRY IN QuickBooks **')


      IF NOT THIS.lquiet
         THIS.oprogress.SetProgressMessage('Posting Compression/Gathering to QuickBooks...')
         THIS.oprogress.updateprogress(THIS.nprogress)
         THIS.nprogress = THIS.nprogress + 1
      ENDIF

      lncompgath = 0
      SWSELECT('wellhist')
      SCAN FOR nrunno = THIS.nrunno ;
            AND crunyear = THIS.crunyear ;
            AND cgroup = tcgroup
         lncompgath = ROUND(ncompress + ngather, 2)

         SWSELECT('wells')
         LOCATE FOR cWellID = wellhist.cWellID
         IF FOUND()
            lcwelllistid = cListID
            IF EMPTY(wells.cListID)
               MESSAGEBOX('The wells file needs to be synchronized with QuickBooks. ' + ;
                  'please synchronize the file and then close the revenue period again.', 0, 'Synchronization Problem')
               RETURN .F.
            ENDIF
         ELSE
            LOOP
         ENDIF
         IF lncompgath # 0
            IF lncompgath > 0
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
               ELSE
                  loentry = loentryadd.journaldebitlinelist.APPEND
               ENDIF
            ELSE
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
               ELSE
                  loentry = loentryadd.journalcreditlinelist.APPEND
               ENDIF
            ENDIF
            loentry.classref.listid.setvalue(lcwelllistid)
            loentry.accountref.listid.setvalue(lcRevClear)
            loentry.amount.setvalue(ABS(lncompgath))
            loentry.MEMO.setvalue('Compression & Gathering')

            IF lncompgath < 0
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
               ELSE
                  loentry = loentryadd.journaldebitlinelist.APPEND
               ENDIF
            ELSE
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
               ELSE
                  loentry = loentryadd.journalcreditlinelist.APPEND
               ENDIF
            ENDIF
            loentry.classref.listid.setvalue(lcwelllistid)
            loentry.accountref.listid.setvalue(m.cgathacct)
            loentry.amount.setvalue(ABS(lncompgath))
            loentry.MEMO.setvalue('Compression & Gathering')
         ENDIF
      ENDSCAN

      lcxml		= THIS.oqbrequest.toxmlstring()
      THIS.SaveXML(m.cWellID, lcXML)
      loresponse	= THIS.oqbsm.dorequests(THIS.oqbrequest)
      loaddresp	= loresponse.responselist.getat(0)

      IF loaddresp.statuscode # 0
         IF NOT USED('qbxml')
            USE (m.goapp.cCommonFolder + 'qbxml') IN 0
         ENDIF
         INSERT INTO qbxml VALUES(m.cWellID, DATETIME(), lcxml)
         IF 'object' $ LOWER(loaddresp.statusmessage)
            lcListID	= SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
            llResult	= m.goapp.oQB.QBListID(lcListID)
            IF llResult
               SELECT QBListID
               IF QBListID.ctype = 'Account'
                  lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                     'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                     'and try to post again.'
               ELSE
                  IF 'Acct' $ QBListID.cdescription
                     lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                        'Please choose a new account in ' + ALLTRIM(QBListID.ctype) + ' and try to post again.'
                  ELSE
                     lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                        'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to post again.'
                  ENDIF
               ENDIF
               THIS.omessage.severe(lcMessage)
            ELSE
               THIS.omessage.severe(loaddresp.statusmessage)
            ENDIF
         ELSE
            THIS.omessage.severe(loaddresp.statusmessage)
         ENDIF
         THIS.ClearErrorRecovery()
         IF VARTYPE(THIS.oprogress) = 'O'
            THIS.oprogress.closeprogress()
         ENDIF
         RETURN .F.
      ELSE
         lonewbill = loaddresp.DETAIL
         m.ctxnid  = lonewbill.txnid.getvalue()
         SWSELECT('qbpost')
         LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnJournal
         IF NOT FOUND()
            m.ntype	 = lnJournal
            m.mtxnids = m.ctxnid
            INSERT INTO qbpost FROM MEMVAR
         ELSE
            IF NOT EMPTY(ALLT(mtxnids))
               REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
            ELSE
               REPL mtxnids WITH m.ctxnid
            ENDIF
         ENDIF

         THIS.ClearErrorRecovery()
      ENDIF

      THIS.oqbrequest.ClearRequests()
   ENDIF

   ***********************************************************************
   *   Post the Vendor amounts that are designated to be posted.
   ***********************************************************************
   IF THIS.lquiet
      THIS.oprogress.SetProgressMessage('Posting Vendor Amounts to QuickBooks...')
      THIS.oprogress.updateprogress(THIS.nprogress)
      THIS.nprogress = THIS.nprogress + 1
   ENDIF

   THIS.qbpostvendop()

   ***********************************************************************
   *  Post the operator/owner checks to qb
   ***********************************************************************
   IF THIS.lquiet
      THIS.oprogress.SetProgressMessage('Posting Operator Amounts to QuickBooks...')
      THIS.oprogress.updateprogress(THIS.nprogress)
      THIS.nprogress = THIS.nprogress + 1
   ENDIF

   IF NOT THIS.qbpostoperator()
      RETURN .F.
   ENDIF

   ***********************************************************************
   *  Post the vendor checks to QB
   ***********************************************************************
   IF THIS.lquiet
      THIS.oprogress.SetProgressMessage('Posting Vendor Checks to QuickBooks...')
      THIS.oprogress.updateprogress(THIS.nprogress)
      THIS.nprogress = THIS.nprogress + 1
   ENDIF

   IF NOT THIS.qbpostvendcks()
      RETURN .F.
   ENDIF

   ***********************************************************************
   *   Post the journal entries for owners not getting checks
   ***********************************************************************
   IF THIS.lquiet
      THIS.oprogress.SetProgressMessage('Posting owner suspense to QuickBooks...')
      THIS.oprogress.updateprogress(THIS.nprogress)
      THIS.nprogress = THIS.nprogress + 1
   ENDIF

   llreturn = THIS.qbpostsuspense(tcdmbatch)
   IF NOT llreturn
      RETURN .F.
   ENDIF

   * Post owners who have owner history but they zeroed out instead of going into suspense
   llreturn = THIS.qbpostownhist(tcdmbatch)
   IF NOT llreturn
      RETURN .F.
   ENDIF

   * Turn off error recovery
   THIS.oqbsm.EnableErrorRecovery	  = .F.
   THIS.oqbsm.SaveAllMsgSetRequestInfo = .F.

   * Close the progress bar
   IF THIS.lquiet
      IF VARTYPE(THIS.oprogress) = 'O'
         THIS.oprogress.closeprogress()
      ENDIF

   ENDIF

   IF NOT THIS.lerrorflag
      SWSELECT('sysctl')
      LOCATE FOR cdmbatch = THIS.cdmbatch
      IF FOUND()
         REPL lposted WITH .T.
      ENDIF
      TABLEUPDATE(.T., .T., 'sysctl')
   ELSE
      RETURN .F.
   ENDIF
   ENDPROC

   ***************************
   PROCEDURE qbpmts
   ***************************
   LPARA tdtodate, tdfromdate,  tcbegown, tcendown, tcListID, tnDataSession
   LOCAL llAcct

   llAcct = VARTYPE(tcListID) = 'C' AND NOT EMPTY(tcListID)

   CREATE CURSOR jibpmts (cownerlistid  c(36), cownname c(41), drecdate d, crefid c(25), npmtamt N(12, 2))

   IF VARTYPE(tnDataSession) = 'N'
      SET DATASESSION TO tnDataSession
   ENDIF

   IF NOT THIS.lqbactive
      RETURN
   ENDIF

   THIS.oqbsm.EnableErrorRecovery = .F.
   SELE cOwnerID, csortfield AS cownname, cownname AS cOwnName1, cListID AS cownerlistid FROM investor WHERE BETWEEN(cOwnerID, tcbegown, tcendown) AND NOT linteggl INTO CURSOR temp

   IF _TALLY > 0
      * get a message set request object (version 3.0 xml)
      lorequest = THIS.oqbrequest
      * set the on error attribute for the request
      lorequest.ATTRIBUTES.OnError = 1

      SELE temp
      SCAN
         SCATTER MEMVAR

         *  Do a receive payment query
         lorequest.ClearRequests()
         loreceivepaymentquery = lorequest.appendreceivepaymentqueryrq()
         loreceivepaymentquery.ortxnquery.txnfilter.entityfilter.orentityfilter.fullnamelist.ADD(LEFT(m.cownname, 41))
         loreceivepaymentquery.ortxnquery.txnfilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.fromtxndate.setvalue(tdfromdate)
         loreceivepaymentquery.ortxnquery.txnfilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.totxndate.setvalue(tdtodate)


         * Add Get the response from the receivepayment query
         loresponse = THIS.oqbsm.dorequests(lorequest)
         lopayments = loresponse.responselist.getat(0)

         IF lopayments.statuscode = 0
            FOR lni = 0 TO lopayments.DETAIL.COUNT - 1

               * get reference to single vendor
               lopayment = lopayments.DETAIL.getat(lni)

               m.cownerlistid = lopayment.customerref.listid.getvalue()
               m.cownname	 = lopayment.customerref.FULLNAME.getvalue()
               IF VARTYPE(lopayment.refnumber) = 'O'
                  m.crefid       = lopayment.refnumber.getvalue()
               ELSE
                  m.crefid = ''
               ENDIF
               IF VARTYPE(lopayment.txndate) = 'O'
                  m.drecdate     = lopayment.txndate.getvalue()
               ENDIF
               IF VARTYPE(lopayment.totalamount) = 'O'
                  m.npmtamt      = lopayment.totalamount.getvalue()
               ENDIF

               IF llAcct
                  lcAcctListid = lopayment.araccountref.listid.getvalue()
                  IF ALLTRIM(lcAcctListid) # ALLTRIM(tcListID)
                     LOOP
                  ENDIF
               ENDIF
               INSERT INTO jibpmts FROM MEMVAR
            ENDFOR
         ELSE
            *  We didn't get a match on cSortField, so use the owner name and query again to check for a balance

            *  Do a receive payment query
            lorequest.ClearRequests()
            loreceivepaymentquery = lorequest.appendreceivepaymentqueryrq()
            loreceivepaymentquery.ortxnquery.txnfilter.entityfilter.orentityfilter.fullnamelist.ADD(LEFT(m.cOwnName1, 41))
            loreceivepaymentquery.ortxnquery.txnfilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.fromtxndate.setvalue(tdfromdate)
            loreceivepaymentquery.ortxnquery.txnfilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.totxndate.setvalue(tdtodate)


            * Add Get the response from the receivepayment query
            loresponse = THIS.oqbsm.dorequests(lorequest)
            lopayments = loresponse.responselist.getat(0)

            IF lopayments.statuscode = 0
               FOR lni = 0 TO lopayments.DETAIL.COUNT - 1

                  * get reference to single vendor
                  lopayment = lopayments.DETAIL.getat(lni)

                  m.cownerlistid	= lopayment.customerref.listid.getvalue()
                  m.cownname		= lopayment.customerref.FULLNAME.getvalue()
                  IF VARTYPE(lopayment.refnumber) = 'O'
                     m.crefid       = lopayment.refnumber.getvalue()
                  ELSE
                     m.crefid = ''
                  ENDIF
                  IF VARTYPE(lopayment.txndate) = 'O'
                     m.drecdate     = lopayment.txndate.getvalue()
                  ENDIF
                  IF VARTYPE(lopayment.totalamount) = 'O'
                     m.npmtamt      = lopayment.totalamount.getvalue()
                  ENDIF

                  IF llAcct
                     lcAcctListid = lopayment.araccountref.listid.getvalue()
                     IF ALLTRIM(lcAcctListid) # ALLTRIM(tcListID)
                        LOOP
                     ENDIF
                  ENDIF
                  INSERT INTO jibpmts FROM MEMVAR
               ENDFOR
            ENDIF
         ENDIF
      ENDSCAN
   ENDIF

   THIS.oqbsm.EnableErrorRecovery = .F.

   ENDPROC

   ***************************
   PROCEDURE qberror
   ***************************
   LPARAMETERS nError, cMethod, nLine, lSuppressMsg

   = AERROR[aerrinfo]

   IF NOT lSuppressMsg
      IF NOT 'list is empty' $ LOWER(aerrinfo[3])
         MESSAGEBOX(aerrinfo[3] + CHR(10) + CHR(10) + ;
            'Method: ' + cMethod + CHR(10) + ;
            'Line:   ' + TRANSFORM(nLine), 0, 'QuickBooks Error')
      ENDIF
   ENDIF
   RETURN

   IF USED('sysctl')
      tcdmbatch = THIS.cdmbatch

      IF NOT EMPTY(tcdmbatch)
         SWSELECT('sysctl')
         LOCATE FOR cdmbatch = tcdmbatch
         IF FOUND()
            REPL lposted WITH .F.
         ENDIF

         *
         *  Remove the QuickBooks Transactions
         *

         * add a request to delete the receipt
         lcxml = THIS.oqbrequest.toxmlstring()
         THIS.SaveXML('QBError', lcXML)

         * set the on error attribute for the request
         THIS.oqbrequest.ATTRIBUTES.OnError = 1

         WAIT WIND NOWAIT 'Cleaning Up QuickBooks Journal Entries...'
         SWSELECT('sysctl')
         LOCATE FOR cdmbatch = THIS.cdmbatch
         IF FOUND()
            m.cidsysctl = cidsysctl
            SWSELECT('qbpost')
            LOCATE FOR cidsysctl = m.cidsysctl
            IF FOUND()
               lcTxnIDs = mtxnids
               m.ntype  = ntype
               lncount  = ALINES(laTxnid, lcTxnIDs)
               IF lncount > 0
                  FOR lnx = 1 TO lncount
                     lcTxnID		 = PADR(ALLT(laTxnid[lnX]), 36, ' ')
                     loJournalDel = THIS.oqbrequest.AppendTxnDelRq()
                     loJournalDel.TxnDelType.setvalue(m.ntype)
                     loJournalDel.txnid.setvalue(lcTxnID)

                     loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
                     loDelResp  = loresponse.responselist.getat(0)
                     IF loDelResp.statuscode # 0
                        WAIT WIND NOWAIT loDelResp.statusmessage
                     ENDIF
                     THIS.ClearErrorRecovery()
                     THIS.oqbrequest.ClearRequests()
                  ENDFOR
                  SWSELECT('qbpost')
                  DELE NEXT 1
               ENDIF
            ENDIF
            WAIT CLEAR
         ENDIF
      ENDIF
   ENDIF

   THIS.lqberror = .T.
   ENDPROC

   ***************************
   PROCEDURE qbbal
   ***************************
   LPARA tddate, tcgroup, tcrunyear, tnrunno, tcbegown, tcendown, tcAcctName
   LOCAL jndays30, jndays60, jndays90

   #DEFINE qbStopOnError            0
   #DEFINE qbContinueOnError        1

   lnDatasession = THIS.ndatasession
   TRY
      SET DATASESSION TO (lnDatasession)
   CATCH TO loError
   ENDTRY

   IF VARTYPE(tcAcctName) # 'C'
      tlAcctFilter = .F.
   ELSE
      tlAcctFilter = .T.
   ENDIF

   jndays30 = GOMONTH(tddate, -1)
   jndays60 = GOMONTH(tddate, -2)
   jndays90 = GOMONTH(tddate, -3)

   jndays30x	= GOMONTH(THIS.dacctdate, -1)
   jndays60x	= GOMONTH(THIS.dacctdate, -2)
   jndays90x	= GOMONTH(THIS.dacctdate, -3)

   IF TYPE('tcGroup') # 'L'
      llgroup = .T.
   ELSE
      llgroup = .F.
   ENDIF

   * Get JIB Receivable Account List ID
   SWSELECT('options')
   lcJIBRcvAcct = cjibacct


   CREATE CURSOR jibbal ;
      (cownerlistid c(36), ;
      cOwnerID     c(10), ;
      cownname     c(60), ;
      ncurrent     N(12, 2), ;
      ndays30      N(12, 2), ;
      ndays60      N(12, 2), ;
      ndays90      N(12, 2))

   CREATE CURSOR jibbal1 ;
      (cownerlistid c(36), ;
      cOwnerID     c(10), ;
      cownname     c(60), ;
      cinvnum      c(11), ;
      dinvdate     d, ;
      ncurrent     N(12, 2), ;
      nbalance     N(12, 2))

   CREATE CURSOR jibbal2 ;
      (cownerlistid c(36), ;
      cOwnerID     c(10), ;
      cownname     c(40), ;
      cinvnum      c(11), ;
      dinvdate     d, ;
      ncurrent     N(12, 2), ;
      nbalance     N(12, 2))

   CREATE CURSOR jibbal3 ;
      (cownerlistid c(36), ;
      cOwnerID     c(10), ;
      cownname     c(40), ;
      cinvnum      c(11), ;
      dinvdate     d, ;
      ncurrent     N(12, 2), ;
      nbalance     N(12, 2))

   IF NOT THIS.lHouseGas      &&  Not asking for house gas previous balances
      *  Build the temp cursor
      SELE investor.cListID AS cownerlistid, ;
         jibinv.ccustid AS cOwnerID, ;
         investor.cownname, ;
         00000000.00 AS ncurrent, ;
         00000000.00 AS ndays30, ;
         00000000.00 AS ndays60, ;
         00000000.00 AS ndays90 ;
         FROM investor, jibinv ;
         WHERE BETWEEN(jibinv.ccustid, tcbegown, tcendown) ;
         AND investor.cOwnerID = jibinv.ccustid ;
         INTO CURSOR temp ;
         ORDER BY jibinv.ccustid ;
         GROUP BY jibinv.ccustid
   ELSE
      SELE investor.cListID AS cownerlistid, ;
         gasown.cOwnerID AS cOwnerID, ;
         investor.cownname, ;
         00000000.00 AS ncurrent, ;
         00000000.00 AS ndays30, ;
         00000000.00 AS ndays60, ;
         00000000.00 AS ndays90 ;
         FROM investor, gasown ;
         WHERE BETWEEN(gasown.cOwnerID, tcbegown, tcendown) ;
         AND gasown.cOwnerID = investor.cOwnerID ;
         INTO CURSOR temp ;
         ORDER BY gasown.cOwnerID ;
         GROUP BY gasown.cOwnerID

   ENDIF
   IF _TALLY > 0
      SELE jibbal
      APPEND FROM DBF('temp')
   ELSE
      RETURN .F.
   ENDIF

   IF NOT THIS.lqbactive
      RETURN
   ENDIF

   * Turn off error recovery for queries
   THIS.oqbsm.EnableErrorRecovery = .F.

   * get a message set request object (version 3.0 xml)
   lorequest = THIS.oqbrequest

   * set the on error attribute for the request
   lorequest.ATTRIBUTES.OnError = 1

   *  Tell QB what owners to look for
   SELE jibbal
   SCAN

      m.cOwnerID = cOwnerID
      * Don't get the prior balance for owner's transfering via G/L entry.
      SWSELECT('investor')
      SET ORDER TO cOwnerID
      IF SEEK(m.cOwnerID) AND linteggl
         LOOP
      ENDIF

      ********************
      *  Invoices
      ********************
      loinvoicequery	= lorequest.appendinvoicequeryrq()
      m.cownname		= csortfield
      m.cownerlistid	= cListID

      loinvoicequery.orinvoicequery.invoicefilter.entityfilter.orentityfilter.fullnamewithchildren.setvalue(m.cownname)
      loinvoicequery.orinvoicequery.invoicefilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.totxndate.setvalue(tddate - 1)

      * Add Get the response from the receivepayment query
      loresponse	= THIS.oqbsm.dorequests(lorequest)
      loinvoices	= loresponse.responselist.getat(0)

      IF loinvoices.statuscode = 0
         FOR lni = 0 TO loinvoices.DETAIL.COUNT - 1

            * get reference to single invoice
            loinvoice = loinvoices.DETAIL.getat(lni)

            m.cownerlistid = loinvoice.customerref.listid.getvalue()

            m.dinvdate     = loinvoice.txndate.getvalue()
            IF m.dinvdate > tddate
               LOOP
            ENDIF

            IF TYPE('loinvoice.refnumber') = 'O'
               m.cinvnum      = loinvoice.refnumber.getvalue()
            ELSE
               m.cinvnum = ''
            ENDIF
            m.nbalance = loinvoice.balanceremaining.getvalue()
            m.napplied = loinvoice.appliedamount.getvalue()

            * Add applied amount back to balance to get original invoice total
            m.nbalance = m.nbalance - m.napplied

            INSERT INTO jibbal1 FROM MEMVAR
         ENDFOR

         SELE jibbal1
         SCAN FOR cOwnerID == m.cOwnerID
            SCATTER MEMVAR
            SELE jibbal
            DO CASE
               CASE BETWEEN(m.dinvdate, jndays30 + 1, tddate)
                  m.ncurrent = ncurrent + m.nbalance
                  REPLACE ncurrent WITH m.ncurrent
               CASE BETWEEN(m.dinvdate, jndays60 + 1, jndays30)
                  m.ndays30 = ndays30 + m.nbalance
                  REPLACE ndays30 WITH m.ndays30
               CASE BETWEEN(m.dinvdate, jndays90 + 1, jndays60)
                  m.ndays60 = ndays60 + m.nbalance
                  REPLACE ndays60 WITH m.ndays60
               CASE m.dinvdate <= jndays90
                  m.ndays90 = ndays90 + m.nbalance
                  REPLACE ndays90 WITH m.ndays90
            ENDCASE
            SELE jibbal1
         ENDSCAN
      ELSE
         *  No response from doing it by sortfield, so do it again by owner name
         loinvoicequery = lorequest.appendinvoicequeryrq()
         m.cownname	   = investor.cownname
         m.cownerlistid = investor.cListID

         loinvoicequery.orinvoicequery.invoicefilter.entityfilter.orentityfilter.fullnamewithchildren.setvalue(m.cownname)
         loinvoicequery.orinvoicequery.invoicefilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.totxndate.setvalue(tddate - 1)

         * Add Get the response from the receivepayment query
         loresponse = THIS.oqbsm.dorequests(lorequest)
         loinvoices = loresponse.responselist.getat(0)

         IF loinvoices.statuscode = 0
            FOR lni = 0 TO loinvoices.DETAIL.COUNT - 1

               * get reference to single invoice
               loinvoice = loinvoices.DETAIL.getat(lni)

               m.cownerlistid = loinvoice.customerref.listid.getvalue()

               m.dinvdate     = loinvoice.txndate.getvalue()
               IF m.dinvdate > tddate
                  LOOP
               ENDIF

               IF TYPE('loinvoice.refnumber') = 'O'
                  m.cinvnum      = loinvoice.refnumber.getvalue()
               ELSE
                  m.cinvnum = ''
               ENDIF
               m.nbalance = loinvoice.balanceremaining.getvalue()
               m.napplied = loinvoice.appliedamount.getvalue()

               * Add applied amount back to balance to get original invoice total
               m.nbalance = m.nbalance - m.napplied

               INSERT INTO jibbal1 FROM MEMVAR
            ENDFOR

            SELE jibbal1
            SCAN FOR cOwnerID == m.cOwnerID
               SCATTER MEMVAR
               SELE jibbal
               DO CASE
                  CASE BETWEEN(m.dinvdate, jndays30 + 1, tddate)
                     m.ncurrent = ncurrent + m.nbalance
                     REPLACE ncurrent WITH m.ncurrent
                  CASE BETWEEN(m.dinvdate, jndays60 + 1, jndays30)
                     m.ndays30 = ndays30 + m.nbalance
                     REPLACE ndays30 WITH m.ndays30
                  CASE BETWEEN(m.dinvdate, jndays90 + 1, jndays60)
                     m.ndays60 = ndays60 + m.nbalance
                     REPLACE ndays60 WITH m.ndays60
                  CASE m.dinvdate <= jndays90
                     m.ndays90 = ndays90 + m.nbalance
                     REPLACE ndays90 WITH m.ndays90
               ENDCASE
               SELE jibbal1
            ENDSCAN
         ENDIF
      ENDIF


      lorequest.ClearRequests()

      *********************
      * Get credit memos
      *********************

      loinvoicequery = lorequest.appendcreditmemoqueryrq()
      WAIT WIND NOWAIT 'Retrieving prior balance from QuickBooks for: ' + ALLT(m.cownname)
      loinvoicequery.ortxnquery.txnfilter.entityfilter.orentityfilter.fullnamewithchildren.setvalue(m.cownname)
      loinvoicequery.ortxnquery.txnfilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.totxndate.setvalue(tddate)

      * Add Get the response from the receivepayment query
      loresponse	= THIS.oqbsm.dorequests(lorequest)
      loinvoices	= loresponse.responselist.getat(0)

      IF loinvoices.statuscode = 0
         FOR lni = 0 TO loinvoices.DETAIL.COUNT - 1

            * get reference to single invoice
            loinvoice = loinvoices.DETAIL.getat(lni)

            m.cownerlistid = loinvoice.customerref.listid.getvalue()

            m.dinvdate     = loinvoice.txndate.getvalue()
            IF m.dinvdate >= tddate
               LOOP
            ENDIF

            IF VARTYPE(loinvoice.refnumber) = 'O'
               m.cinvnum = loinvoice.refnumber.getvalue()
            ELSE
               m.cinvnum = ''
            ENDIF

            m.nbalance     = loinvoice.totalamount.getvalue()

            INSERT INTO jibbal2 FROM MEMVAR
         ENDFOR

         SELE jibbal2
         SCAN FOR cOwnerID == m.cOwnerID
            SCATTER MEMVAR
            SELE jibbal
            DO CASE
               CASE BETWEEN(m.dinvdate, jndays30 + 1, tddate)
                  m.ncurrent = ncurrent - m.nbalance
                  REPLACE ncurrent WITH m.ncurrent
               CASE BETWEEN(m.dinvdate, jndays60 + 1, jndays30)
                  m.ndays30 = ndays30 - m.nbalance
                  REPLACE ndays30 WITH m.ndays30
               CASE BETWEEN(m.dinvdate, jndays90 + 1, jndays60)
                  m.ndays60 = ndays60 - m.nbalance
                  REPLACE ndays60 WITH m.ndays60
               CASE m.dinvdate <= jndays90
                  m.ndays90 = ndays90 - m.nbalance
                  REPLACE ndays90 WITH m.ndays90
            ENDCASE
            SELE jibbal1
         ENDSCAN
      ENDIF
      lorequest.ClearRequests()

      *********************
      * Get checks issued
      *********************
      locheckquery = lorequest.appendcheckqueryrq()
      WAIT WIND NOWAIT 'Retrieving prior balance from QuickBooks for: ' + ALLT(m.cownname)
      locheckquery.ortxnquery.txnfilter.entityfilter.orentityfilter.fullnamewithchildren.setvalue(m.cownname)
      locheckquery.ortxnquery.txnfilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.totxndate.setvalue(THIS.dacctdate)
      locheckquery.includelineitems.setvalue(1)

      * Add Get the response from the check query
      loresponse	= THIS.oqbsm.dorequests(lorequest)
      lochecks	= loresponse.responselist.getat(0)

      IF lochecks.statuscode = 0
         FOR lni = 0 TO lochecks.DETAIL.COUNT - 1

            * get reference to single check
            locheck = lochecks.DETAIL.getat(lni)

            m.cownerlistid = locheck.payeeentityref.listid.getvalue()
            m.dinvdate	  = locheck.txndate.getvalue()
            IF VARTYPE(locheck.refnumber) = 'O'
               m.cinvnum      = locheck.refnumber.getvalue()
            ELSE
               m.cinvnum = ''
            ENDIF

            FOR lnx = 0 TO locheck.ExpenseLineRetList.COUNT - 1

               loCheckDetail = locheck.ExpenseLineRetList.getat(lnx)

               lcJIBAcct     = loCheckDetail.accountref.listid.getvalue()

               IF lcJIBAcct  = ALLT(lcJIBRcvAcct)
                  m.nbalance = loCheckDetail.amount.getvalue()
                  INSERT INTO jibbal3 FROM MEMVAR
               ELSE
                  m.nbalance = 0
               ENDIF
            ENDFOR
         ENDFOR

         SELE jibbal3
         SCAN FOR cOwnerID = m.cOwnerID
            SCATTER MEMVAR
            SELE jibbal
            DO CASE
               CASE BETWEEN(m.dinvdate, jndays30x + 1, THIS.dacctdate)
                  m.ncurrent = ncurrent + m.nbalance
                  REPL ncurrent WITH m.ncurrent
               CASE BETWEEN(m.dinvdate, jndays60x + 1, jndays30x)
                  m.ndays30 = ndays30 + m.nbalance
                  REPL ndays30 WITH m.ndays30
               CASE BETWEEN(m.dinvdate, jndays90x + 1, jndays60x)
                  m.ndays60 = ndays60 + m.nbalance
                  REPL ndays60 WITH m.ndays60
               CASE m.dinvdate <= jndays90x
                  m.ndays90 = ndays90 + m.nbalance
                  REPL ndays90 WITH m.ndays90
            ENDCASE
         ENDSCAN
      ENDIF
      lorequest.ClearRequests()

      ***************************
      * General Journal Entries
      ***************************

      loJournalQuery = lorequest.appendjournalentryqueryrq()
      loJournalQuery.ortxnquery.txnfilter.entityfilter.orentityfilter.fullnamewithchildren.setvalue(m.cownname)
      IF tlAcctFilter
         loJournalQuery.ortxnquery.txnfilter.AccountFilter.ORAccountFilter.fullnamelist.ADD(ALLT(tcAcctName))
      ENDIF
      loJournalQuery.ortxnquery.txnfilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.totxndate.setvalue(tddate)
      loJournalQuery.includelineitems.setvalue(1)


      * Add Get the response from the check query
      loresponse	= THIS.oqbsm.dorequests(lorequest)
      loEntries	= loresponse.responselist.getat(0)
      m.namount	= 0

      IF loEntries.statuscode = 0
         FOR lni = 0 TO loEntries.DETAIL.COUNT - 1

            * get reference to single entry
            loentry	   = loEntries.DETAIL.getat(lni)
            m.dTranDate = loentry.txndate.getvalue()

            IF THIS.qbfcversion > QBFCVER
               FOR lnx = 0 TO loentry.ORJournalLineList.COUNT - 1
                  loDetail = loentry.ORJournalLineList.getat(lnx)
                  loDebit  = loDetail.journaldebitline
                  loCredit = loDetail.journalcreditline

                  IF VARTYPE(loDebit) = 'O'
                     IF VARTYPE(loDebit.accountref) = 'O'
                        lcAcct  = loDebit.accountref.listid.getvalue()
                        IF lcAcct = ALLT(lcJIBRcvAcct)
                           m.namount = loDebit.amount.getvalue()
                           EXIT
                        ENDIF
                     ENDIF
                  ENDIF

                  IF VARTYPE(loCredit) = 'O'
                     IF VARTYPE(loCredit.accountref) = 'O'
                        lcAcct  = loCredit.accountref.listid.getvalue()
                        IF lcAcct = ALLT(lcJIBRcvAcct)
                           m.namount = (loCredit.amount.getvalue() * -1)
                           EXIT
                        ENDIF
                     ENDIF
                  ENDIF
               ENDFOR
            ELSE
               FOR lnx = 0 TO loentry.journaldebitlinelist.COUNT - 1
                  loDebit = loentry.journaldebitlinelist.getat(lnx)
                  lcAcct	 = loDebit.accountref.listid.getvalue()
                  IF lcAcct = ALLT(lcJIBRcvAcct)
                     m.namount = loDebit.amount.getvalue()
                     EXIT
                  ENDIF
               ENDFOR

               FOR lnx = 0 TO loentry.journalcreditlinelist.COUNT - 1
                  loCredit = loentry.journalcreditlinelist.getat(lnx)
                  lcAcct	  = loCredit.accountref.listid.getvalue()
                  IF lcAcct = ALLT(lcJIBRcvAcct)
                     m.namount = (loCredit.amount.getvalue() * -1)
                     EXIT
                  ENDIF
               ENDFOR
            ENDIF

            SELE jibbal
            SCATTER MEMVAR
            DO CASE
               CASE BETWEEN(m.dTranDate, jndays30 + 1, tddate)
                  m.ncurrent = m.ncurrent + m.namount
               CASE BETWEEN(m.dTranDate, jndays60 + 1, jndays30)
                  m.ndays30 = m.ndays30 + m.namount
               CASE BETWEEN(m.dTranDate, jndays90 + 1, jndays60)
                  m.ndays60 = m.ndays60 + m.namount
               CASE m.dTranDate <= jndays90
                  m.ndays90 = m.ndays90 + m.namount
            ENDCASE
            REPLACE ncurrent WITH m.ncurrent, ;
               ndays30  WITH m.ndays30, ;
               ndays60  WITH m.ndays60, ;
               ndays90  WITH m.ndays90

            m.namount = 0
         ENDFOR
      ENDIF

      lorequest.ClearRequests()
      ***************************
      * Get payments received
      ***************************
      THIS.qbpmts(tddate, {01/01/1980}, jibbal.cOwnerID, jibbal.cOwnerID)

      SELE jibpmts
      SCAN FOR cOwnerID = m.cOwnerID
         SCATTER MEMVAR
         SELE jibbal
         DO CASE
            CASE BETWEEN(m.drecdate, jndays30 + 1, tddate)
               m.ncurrent = ncurrent - m.npmtamt
               REPL ncurrent WITH m.ncurrent
            CASE BETWEEN(m.drecdate, jndays60 + 1, jndays30)
               m.ndays30 = ndays30 - m.npmtamt
               REPL ndays30 WITH m.ndays30
            CASE BETWEEN(m.drecdate, jndays90 + 1, jndays60)
               m.ndays60 = ndays60 - m.npmtamt
               REPL ndays60 WITH m.ndays60
            CASE m.drecdate <= jndays90
               m.ndays90 = ndays90 - m.npmtamt
               REPL ndays90 WITH m.ndays90
         ENDCASE
      ENDSCAN

      lorequest.ClearRequests()

      *!*       ********************
      *!*       *  Statement Charges
      *!*       ********************
      *!*       loChargeQuery = lorequest.appendchargequeryrq()
      *!*       m.cownname = cownname
      *!*       m.cownerlistid = cownerlistid
      *!*       WAIT WIND NOWAIT 'Retrieving prior balance from QuickBooks for: ' + ALLT(m.cownname)
      *!*       loChargeQuery.ortxnquery.txnfilter.entityfilter.orentityfilter.fullnamewithchildren.setvalue(m.cownname)
      *!*       loChargeQuery.ortxnquery.txnfilter.ordaterangefilter.txndaterangefilter.ortxndaterangefilter.txndatefilter.totxndate.setvalue(tddate-1)
      *!*       loChargeQuery.IncludeLineItems.setvalue(1)

      *!*       * Add Get the response from the statement charge query
      *!*       loresponse = THIS.oQBSM.dorequests(lorequest)
      *!*       loCharges = loresponse.responselist.getat(0)

      *!*       IF loCharges.statuscode = 0
      *!*          FOR lni = 0 TO loCharges.detail.COUNT - 1

      *!*             * get reference to single charge
      *!*             loCharge = loCharges.detail.getat(lni)

      *!*             m.cownerlistid = loCharge.customerref.listid.getvalue()
      *!*             m.cownname     = loCharge.customerref.FULLNAME.getvalue()

      *!*             m.dinvdate     = loCharge.txndate.getvalue()
      *!*             IF m.dinvdate > tddate
      *!*                LOOP
      *!*             ENDIF

      *!*             m.cinvnum      = loCharge.chargenumber.getvalue()
      *!*
      *!*             for lnx = 1 to loCharge.
      *!*             m.nbalance     = loCharge.balanceremaining.getvalue()
      *!*             m.napplied     = loCharge.appliedamount.getvalue()

      *!*             * Add applied amount back to balance to get original invoice total
      *!*             m.nbalance = m.nbalance - m.napplied

      *!*             INSERT INTO jibbal1 FROM MEMVAR
      *!*          ENDFOR

      *!*          SELE jibbal1
      *!*          SCAN FOR cownerlistid = m.cownerlistid
      *!*             SCATTER MEMVAR
      *!*             SELE jibbal
      *!*             SCATTER MEMVAR
      *!*             DO CASE
      *!*                CASE BETWEEN(m.dinvdate,jndays30+1,tddate)
      *!*                   m.ncurrent = m.ncurrent + m.nbalance
      *!*                CASE BETWEEN(m.dinvdate,jndays60+1,jndays30)
      *!*                   m.ndays30 = m.ndays30 + m.nbalance
      *!*                CASE BETWEEN(m.dinvdate,jndays90+1,jndays60)
      *!*                   m.ndays60 = m.ndays60 + m.nbalance
      *!*                CASE m.dinvdate <= jndays90
      *!*                   m.ndays90 = m.ndays90 + m.nbalance
      *!*             ENDCASE
      *!*             REPLACE ncurrent WITH m.ncurrent, ;
      *!*                ndays30  WITH m.ndays30, ;
      *!*                ndays60  WITH m.ndays60, ;
      *!*                ndays90  WITH m.ndays90
      *!*          ENDSCAN
      *!*       ENDIF
      *!*       lorequest.clearrequests()

   ENDSCAN
   WAIT CLEAR

   * Turn error recovery back on
   THIS.oqbsm.EnableErrorRecovery = .T.

   SELECT jibbal
   ENDPROC

   ***************************
   PROCEDURE qbacctcheck
   ***************************
   LPARAMETERS tlparm1, tlParm2
   *
   *  Checks to make sure all QB accounts specified in Expense Categories,
   *  Revenue Categories, Account Settings and Disbursement and JIB Options
   *  still exist in QuickBooks

   *  Check to see if QuickBooks link is active
   IF NOT THIS.lqbactive
      RETURN .F.
   ENDIF

   *  Build cursor for holding all account listid's specified
   lcReturn = THIS.QBAccounts('*', .F., .T., 1)
   IF '*' $ lcReturn
      MESSAGEBOX('Could not retrieve list of accounts from QuickBooks. Unable to continue...', 0, 'QuickBooks Problem')
   ENDIF

   *  Scan through expense categories checking listid's
   IF NOT USED('expcat')
      USE expcat IN 0
   ENDIF
   SWSELECT('expcat')
   SCAN
      IF '-' $ expcat.cvendacctlistid           && If there's an * in the listid, it could be a valid QB listid
         SELE accounts
         LOCATE FOR accounts.cListID = expcat.cvendacctlistid
         IF NOT FOUND()
            MESSAGEBOX('The vendor income account specified for expense category: ' + ALLT(expcat.ccateg) + ;
               ' no longer exists in QuickBooks.  Please specify a valid account.', 0, 'QuickBooks Account Problem')
            RETURN
         ENDIF
      ELSE
         IF ALLT(expcat.cvendacctlistid) # ''    && The listid is not blank, so blank it out.
            REPL expcat.cvendacctlistid WITH ''
         ENDIF
      ENDIF

      *  Check the owner debit account listid
      IF '-' $ expcat.cownacctlistid           && If there's an * in the listid, it could be a valid QB listid
         SELE accounts
         LOCATE FOR accounts.cListID = expcat.cownacctlistid
         IF NOT FOUND()
            MESSAGEBOX('The owner expense account specified for expense category: ' + ALLT(expcat.ccateg) + ;
               ' no longer exists in QuickBooks.  Please specify a valid account.', 0, 'QuickBooks Account Problem')
            RETURN
         ENDIF
      ELSE
         IF ALLT(expcat.cownacctlistid) # ''    && The listid is not blank, so blank it out.
            REPL expcat.cownacctlistid WITH ''
         ENDIF
      ENDIF
   ENDSCAN

   *  Check to see if all revenue category accounts are valid
   IF NOT USED('revcat')
      USE revcat IN 0
   ENDIF
   SWSELECT('revcat')
   SCAN
      * Check working interest owner revenue
      IF '-' $ revcat.ccracctnow              && If there's an * in the listid, it could be a valid QB listid
         SELE accounts
         LOCATE FOR accounts.cListID = revcat.ccracctnow
         IF NOT FOUND()
            MESSAGEBOX('The income account specified for working interest owners in revenue category: ' + ALLT(revcat.crevtype) + ;
               ' no longer exists in QuickBooks.  Please specify a valid account.', 0, 'QuickBooks Account Problem')
            RETURN
         ENDIF
      ELSE
         IF ALLT(revcat.ccracctnow) # ''     && Listid is not blank, so blank it out
            REPL revcat.ccracctnow WITH ''
         ENDIF
      ENDIF

      * Check royalty interest owner revenue
      IF '-' $ revcat.ccracctnow              && If there's an * in the listid, it could be a valid QB listid
         SELE accounts
         LOCATE FOR accounts.cListID = revcat.ccracctnol
         IF NOT FOUND()
            MESSAGEBOX('The income account specified for royalty interest owners in revenue category: ' + ALLT(revcat.crevtype) + ;
               ' no longer exists in QuickBooks.  Please specify a valid account.', 0, 'QuickBooks Account Problem')
            RETURN
         ENDIF
      ELSE
         IF ALLT(revcat.ccracctnol) # ''     && Listid is not blank, so blank it out
            REPL revcat.ccracctnol WITH ''
         ENDIF
      ENDIF

      * Check royalty interest owner revenue
      IF '-' $ revcat.ccracctnoo              && If there's an * in the listid, it could be a valid QB listid
         SELE accounts
         LOCATE FOR accounts.cListID = revcat.ccracctnoo
         IF NOT FOUND()
            MESSAGEBOX('The income account specified for overriding royalty interest owners in revenue category: ' + ALLT(revcat.crevtype) + ;
               ' no longer exists in QuickBooks.  Please specify a valid account.', 0, 'QuickBooks Account Problem')
            RETURN
         ENDIF
      ELSE
         IF ALLT(revcat.ccracctnoo) # ''     && Listid is not blank, so blank it out
            REPL revcat.ccracctnoo WITH ''
         ENDIF
      ENDIF
   ENDSCAN

   *  Check to see if accounts specified in account settings are valid
   IF NOT USED('glopt')
      USE glopt IN 0
   ENDIF
   SWSELECT('glopt')
   GO TOP

   * Check revenue clearing account
   SELE accounts
   LOCATE FOR accounts.cListID = glopt.crevclear
   IF NOT FOUND()
      SWSELECT('glopt')
      REPL crevclear WITH ''
      MESSAGEBOX('The revenue clearing account specified in QB posting preferences is invalid. Please correct.', 0, 'Account Settings Problem')
      RETURN .F.
   ENDIF

   * Check expense clearing account
   SELE accounts
   LOCATE FOR accounts.cListID = glopt.cexpclear
   IF NOT FOUND()
      SWSELECT('glopt')
      REPL cexpclear WITH ''
      MESSAGEBOX('The expense clearing account specified in QB posting preferences is invalid. Please correct.', 0, 'Account Settings Problem')
      RETURN .F.
   ENDIF

   * Check catch-all account
   SELE accounts
   LOCATE FOR accounts.cListID = glopt.csuspense
   IF NOT FOUND()
      SWSELECT('glopt')
      REPL csuspense WITH ''
      MESSAGEBOX('The catch-all account specified in QB posting preferences is invalid. Please correct.', 0, 'Account Settings Problem')
      RETURN .F.
   ENDIF

   *  Check accounts specified in Disbursement and JIB Options
   SWSELECT('options')
   GO TOP

   * Check bank account
   SELE accounts
   LOCATE FOR accounts.cListID = options.cdisbacct
   IF NOT FOUND()
      SWSELECT('options')
      REPL cdisbacct WITH ''
      MESSAGEBOX('The account specified as the cash account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
      RETURN .F.
   ENDIF

   * Check deficit account
   IF ALLT(options.cdefacct) # ''
      IF '-' $ options.cdefacct
         SELE accounts
         LOCATE FOR accounts.cListID = options.cdefacct
         IF NOT FOUND()
            SWSELECT('options')
            REPL cdefacct WITH ''
            MESSAGEBOX('The account specified as the owner deficit account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL cdefacct WITH ''
      ENDIF
   ENDIF

   * Check minimum account
   IF ALLT(options.cminacct) # ''
      IF '-' $ options.cminacct
         SELE accounts
         LOCATE FOR accounts.cListID = options.cminacct
         IF NOT FOUND()
            SWSELECT('options')
            REPL cminacct WITH ''
            MESSAGEBOX('The account specified as the owner minimum account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL cminacct WITH ''
      ENDIF
   ENDIF

   * Check JIB account
   IF ALLT(options.cjibacct) # ''
      IF '-' $ options.cjibacct
         SELE accounts
         LOCATE FOR accounts.cListID = options.cjibacct
         IF NOT FOUND()
            SWSELECT('options')
            REPL cjibacct WITH ''
            MESSAGEBOX('The account specified as the owner JIB receivable account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SELE options
         REPL cjibacct WITH ''
      ENDIF
   ENDIF

   * Check tax withholding account
   IF ALLT(options.ctaxacct) # ''
      SELE accounts
      LOCATE FOR accounts.cListID = options.ctaxacct
      IF NOT FOUND()
         SWSELECT('options')
         REPL ctaxacct WITH ''
         MESSAGEBOX('The account specified as the tax withholding account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
         RETURN .F.
      ENDIF
   ENDIF

   * Check backup withholding account
   IF ALLT(options.cbackacct) # ''
      IF '-' $ options.cbackacct
         SELE accounts
         LOCATE FOR accounts.cListID = options.cbackacct
         IF NOT FOUND()
            SWSELECT('options')
            REPL cbackacct WITH ''
            MESSAGEBOX('The account specified as the backup withholding account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL cbackacct WITH ''
      ENDIF
   ENDIF

   * Check tax withholding account
   IF ALLT(options.ctaxacct) # ''
      IF '-' $ options.ctaxacct
         SELE accounts
         LOCATE FOR accounts.cListID = options.ctaxacct
         IF NOT FOUND()
            SWSELECT('options')
            REPL ctaxacct WITH ''
            MESSAGEBOX('The account specified as the backup withholding account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL ctaxacct WITH ''
      ENDIF
   ENDIF

   * Check compression/gathering account
   IF ALLT(options.cgathacct) # ''
      IF '-' $ options.cgathacct
         SELE accounts
         LOCATE FOR accounts.cListID = options.cgathacct
         IF NOT FOUND()
            SWSELECT('options')
            REPL cgathacct WITH ''
            MESSAGEBOX('The account specified as the compression/gathering account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL cgathacct WITH ''
      ENDIF
   ENDIF

   * Check tax payable 1 withholding account
   IF ALLT(options.ctaxacct1) # ''
      IF '-' $ options.ctaxacct1
         SELE accounts
         LOCATE FOR accounts.cListID = options.ctaxacct1
         IF NOT FOUND()
            SWSELECT('options')
            REPL ctaxacct1 WITH ''
            MESSAGEBOX('The account specified as the tax payable 1 account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL ctaxacct1 WITH ''
      ENDIF
   ENDIF

   * Check taxes payable 2 account
   IF ALLT(options.ctaxacct2) # ''
      IF '-' $ options.ctaxacct2
         SELE accounts
         LOCATE FOR accounts.cListID = options.ctaxacct2
         IF NOT FOUND()
            SWSELECT('options')
            REPL ctaxacct2 WITH ''
            MESSAGEBOX('The account specified as the tax payable 2 account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL ctaxacct2 WITH ''
      ENDIF
   ENDIF

   * Check taxes payable 3 account
   IF ALLT(options.ctaxacct3) # ''
      IF '-' $ options.ctaxacct3
         SELE accounts
         LOCATE FOR accounts.cListID = options.ctaxacct3
         IF NOT FOUND()
            SWSELECT('options')
            REPL ctaxacct3 WITH ''
            MESSAGEBOX('The account specified as the tax payable 3 account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL ctaxacct3 WITH ''
      ENDIF
   ENDIF

   * Check taxes payable 4 account
   IF ALLT(options.ctaxacct4) # ''
      IF '-' $ options.ctaxacct4
         SELE accounts
         LOCATE FOR accounts.cListID = options.ctaxacct4
         IF NOT FOUND()
            SWSELECT('options')
            REPL ctaxacct4 WITH ''
            MESSAGEBOX('The account specified as the tax payable 4 account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL ctaxacct4 WITH ''
      ENDIF
   ENDIF

   * Check fixed expense clearing account
   IF ALLT(options.cfixedacct) # ''
      IF '-' $ options.cfixedacct
         SELE accounts
         LOCATE FOR accounts.cListID = options.cfixedacct
         IF NOT FOUND()
            SWSELECT('options')
            REPL cfixedacct WITH ''
            MESSAGEBOX('The account specified as the fixed expense clearing account in QuickBooks Posting - Preferences is invalid. Please correct.', 0, 'Disb & JIB Options Problem')
            RETURN .F.
         ENDIF
      ELSE
         SWSELECT('options')
         REPL cfixedacct WITH ''
      ENDIF
   ENDIF

   IF NOT tlparm1
      MESSAGEBOX('Finished Validating Account Links.', 0, 'Validation Complete')
   ENDIF
   ENDPROC

   ***************************
   PROCEDURE qbpostoperator
   ***************************
   LOCAL lcTaxDesc, lcAPAcct, lcRevClear, lcExpClear, llQBPost, lcSuspense, lnJournal
   LOCAL lndebits, lncredits, lcRun

   SWSELECT('glopt')
   lcRevClear = crevclear
   lcExpClear = cexpclear
   llQBPost	 = NOT ldmnopost
   lcSuspense = csuspense

   STORE 0 TO lndebits, lncredits

   SWSELECT('apopt')
   lcAPAcct = cAPAcct

   SWSELECT('wells')
   SET ORDER TO cWellID

   * Get the group and date to process expenses through for this run
   SWSELECT('sysctl')
   LOCATE FOR cdmbatch = tcdmbatch
   IF FOUND()
      THIS.cgroup   = cgroup
      THIS.dexpdate = dexpdate
   ENDIF

   * Get the correct txndeltype
   IF THIS.qbfcversion > QBFCVER
      lnJournal = 15
   ELSE
      lnJournal = 14
   ENDIF

   ****************************************************************
   *   Get Disbursement Checking Acct Number
   ****************************************************************
   SWSELECT('options')
   GO TOP
   m.cdisbacct = cdisbacct
   IF EMPTY(ALLT(m.cdisbacct))
      m.cdisbacct = lcSuspense
   ENDIF
   m.cvendcomp = cvendcomp
   IF EMPTY(ALLT(m.cvendcomp))
      m.cvendcomp = lcSuspense
   ENDIF
   m.cgathacct = cgathacct
   IF EMPTY(ALLT(m.cgathacct))
      m.cgathacct = lcSuspense
   ENDIF
   m.cbackwith = cbackacct
   IF EMPTY(ALLT(m.cbackwith))
      m.cbackwith = lcSuspense
   ENDIF
   m.ctaxacct1  = ctaxacct1
   IF EMPTY(ALLT(m.ctaxacct1))
      m.ctaxacct1 = lcSuspense
   ENDIF
   m.ctaxacct2  = ctaxacct2
   IF EMPTY(ALLT(m.ctaxacct2))
      m.ctaxacct2 = lcSuspense
   ENDIF
   m.ctaxacct3  = ctaxacct3
   IF EMPTY(ALLT(m.ctaxacct3))
      m.ctaxacct3 = lcSuspense
   ENDIF
   m.ctaxacct4 = ctaxacct4
   IF EMPTY(ALLT(m.ctaxacct4))
      m.ctaxacct4 = lcSuspense
   ENDIF
   m.cdefacct  = cdefacct
   IF EMPTY(ALLT(m.cdefacct))
      m.cdefacct = lcSuspense
   ENDIF
   m.cminacct  = cminacct
   IF EMPTY((m.cminacct))
      m.cminacct = lcSuspense
   ENDIF

   *  Get the account fixed expenses and well expenses by well expenses are to be posted to.
   lcdmexp = cfixedacct
   IF EMPTY(lcdmexp)
      lcdmexp = lcAPAcct
   ENDIF

   IF EMPTY(lcdmexp)
      MESSAGEBOX('The fixed expense clearing account needs to be specified in Disbursement and JIB Options.' + ;
         'please specify the account and then close the revenue period again.', 0, 'Setup Problem')
      RETURN .F.
   ENDIF

   llsepclose  = lsepclose

   * set the on error attribute for the request
   THIS.oqbrequest.ATTRIBUTES.OnError = 1

   * Clear any previous requests
   THIS.oqbrequest.ClearRequests()
   THIS.ClearErrorRecovery()

   * Build the text lcRun from the Runno and Run Year
   lcRun	  = THIS.crunyear + '/' + PADL(TRANSFORM(THIS.nrunno), 3, '0')
   lnowner = 0

   *
   *  Get the owners to be posted.
   *
   SELECT cOwnerID, cownname, cListID FROM investor WHERE linteggl = .T. INTO ARRAY laowns
   lnowns  = _TALLY

   IF THIS.lqbactive AND llQBPost AND lnowns > 0
      lnamount = 0
      FOR lnx = 1 TO lnowns
         SELE SUM(nincome + nsevtaxes) AS ninc, SUM(nexpense + ntotale1 + ntotale2 + ntotale3 + ntotale4 + ntotale5 + ntotalea + ntotaleb + nmktgexp) AS nexp ;
            FROM invtmp WHERE cOwnerID == laowns[lnX, 1] AND nrunno = THIS.nrunno AND crunyear = THIS.crunyear AND cgroup = tcgroup INTO CURSOR tempown
         SELE tempown

         STORE 0 TO lnoilrev, lngasrev, lntrprev, lnmi1rev, lnmi2rev, lndebits, lncredits, ;
            lnmin, lndeficit, lnoiltax, lngastax, lndebits, lncredits
         SELECT invtmp
         COUNT FOR cOwnerID == laowns[lnX, 1] AND nrunno = THIS.nrunno AND crunyear = THIS.crunyear AND cgroup = tcgroup TO lnmax
         lncount = 1
         IF NOT THIS.lquiet
            THIS.oprogress = THIS.omessage.progressbarex('Posting owner totals to income and expense accounts...', ;
               laowns[lnX, 2])
            THIS.oprogress.setprogressrange(0, lnmax)
         ENDIF
         SELECT invtmp
         SCAN FOR cOwnerID == laowns[lnX, 1] AND nrunno = THIS.nrunno AND crunyear = THIS.crunyear AND cgroup = tcgroup AND crectype = 'R'
            SCATTER MEMVAR
            * If this is a zero amount record, skip it
            IF m.nincome = 0 AND m.nsevtaxes = 0 AND m.nexpense = 0 AND ;
                  m.ntotale1 = 0 AND m.ntotale2 = 0  AND m.ntotale3 = 0 AND ;
                  m.ntotale4 = 0 AND m.ntotale5 = 0  AND m.ntotalea = 0 AND ;
                  m.ntotaleb = 0 AND m.nmktgexp = 0
                     LOOP
            ENDIF

            *  Setup the journal add request
            loentryadd = THIS.oqbrequest.appendjournalentryaddrq()
            loentryadd.txndate.setvalue(m.hDate)
            loentryadd.refnumber.setvalue('DM-' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear)

            lcownlistid = laowns[lnX, 3]

            SWSELECT('roundtmp')
            LOCATE FOR cOwnerID == m.cOwnerID AND cWellID = m.cWellID AND NOT lused AND cdmbatch = tcdmbatch
            IF FOUND()
               llround = .T.
            ELSE
               llround = .F.
            ENDIF

            lljib = ljib
            IF NOT THIS.lquiet
               THIS.oprogress.updateprogress(lncount)
               lncount = lncount + 1
            ENDIF
            lcname    = laowns[lnX, 2]

            SWSELECT('wells')
            IF SEEK(m.cWellID)
               SCATTER FIELDS LIKE lsev* MEMVAR
               m.nprocess	 = nprocess
               lcwelllistid	 = cListID
               m.ldiroilpurch = ldiroilpurch
               m.ldirgaspurch = ldirgaspurch
               IF EMPTY(wells.cListID)
                  MESSAGEBOX('The wells file needs to be synchronized with QuickBooks. ' + ;
                     'please synchronize and then close the revenue period again.', 0, 'Synchronization Problem')
                  RETURN .F.
               ENDIF
            ELSE
               LOOP
               lcwelllistid = ''
            ENDIF

            *  Post Interest on Hold being released
            IF m.csusptype = 'I' AND m.nnetcheck # 0
               IF m.nnetcheck > 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF

                  m.nnetcheck = ROUND(ABS(m.nnetcheck), 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  * Validate the account
                  IF THIS.qbacct_validate(m.cminacct)
                     loentry.accountref.listid.setvalue(m.cminacct)
                  ELSE
                     MESSAGEBOX('The QB account given for legal suspense is invalid. Please choose another.', 16, 'QB Account Problem')
                     THIS.oqbrequest.ClearRequests()
                     RETURN .F.
                  ENDIF
                  loentry.amount.setvalue(ABS(m.nnetcheck))
                  loentry.MEMO.setvalue('Interest On Hold Released - ' + m.hyear + '/' + m.hperiod)

                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF

                  m.nnetcheck = ROUND(ABS(m.nnetcheck), 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nnetcheck))
                  loentry.MEMO.setvalue('Interest On Hold Released - ' + m.hyear + '/' + m.hperiod)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF

                  m.nnetcheck = ROUND(m.nnetcheck, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(m.cminacct)
                  loentry.amount.setvalue(ABS(m.nnetcheck))
                  loentry.MEMO.setvalue('Interest On Hold Released - ' + m.hyear + '/' + m.hperiod)

                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF

                  m.nnetcheck = ROUND(ABS(m.nnetcheck), 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nnetcheck))
                  loentry.MEMO.setvalue('Interest On Hold Released - ' + m.hyear + '/' + m.hperiod)
               ENDIF

            ENDIF

            *
            *  Post Oil Income
            *
            llroundit = .F.
            IF m.noilrev # 0
               IF INLIST(m.cdirect, 'O', 'B')
                  m.nincome = m.nincome - m.noilrev
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('BBL')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcacctc = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcacctc = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcacctc = ccracctnow
                     ENDCASE

                     IF EMPTY(lcacctc)
                        lcacctc = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noilrev = m.noilrev + roundtmp.noilrev
                        llroundit = .T.
                     ENDIF

                     IF m.noilrev < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.noilrev = ROUND(m.noilrev, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcacctc)
                     loentry.amount.setvalue(ABS(m.noilrev))
                     loentry.MEMO.setvalue('Oil Revenue ' + m.hyear + '/' + m.hperiod)

                     IF m.noilrev > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcRevClear)
                     loentry.amount.setvalue(ABS(m.noilrev))
                     loentry.MEMO.setvalue('Oil Revenue ' + m.hyear + '/' + m.hperiod)
                  ELSE

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noilrev = m.noilrev + roundtmp.noilrev
                        llroundit = .T.
                     ENDIF

                     IF m.noilrev < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.noilrev = ROUND(m.noilrev, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.noilrev))
                     loentry.MEMO.setvalue('Oil Revenue ' + m.hyear + '/' + m.hperiod)

                     IF m.noilrev > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcRevClear)
                     loentry.amount.setvalue(ABS(m.noilrev))
                     loentry.MEMO.setvalue('Oil Revenue ' + m.hyear + '/' + m.hperiod)
                  ENDIF
               ENDIF
            ENDIF
            *
            *  Post Gas Income
            *
            llroundit = .F.
            IF m.ngasrev # 0 OR m.nflatrate # 0
               IF INLIST(m.cdirect, 'G', 'B')
                  m.nincome = m.nincome - m.ngasrev
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('MCF')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcacctc = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcacctc = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcacctc = ccracctnow
                     ENDCASE

                     IF EMPTY(lcacctc)
                        lcacctc = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngasrev = m.ngasrev + roundtmp.ngasrev
                        llroundit = .T.
                     ENDIF

                     IF m.ngasrev + m.nflatrate < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngasrev = ROUND(m.ngasrev, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcacctc)
                     loentry.amount.setvalue(ABS(m.ngasrev+m.nflatrate))
                     loentry.MEMO.setvalue('Gas Revenue ' + m.hyear + '/' + m.hperiod)

                     IF m.ngasrev+m.nflatrate > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcRevClear)
                     loentry.amount.setvalue(ABS(m.ngasrev+m.nflatrate))
                     loentry.MEMO.setvalue('Gas Revenue ' + m.hyear + '/' + m.hperiod)
                  ELSE

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngasrev = m.ngasrev + roundtmp.ngasrev
                        llroundit = .T.
                     ENDIF

                     IF m.ngasrev+m.nflatrate < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngasrev = ROUND(m.ngasrev, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.ngasrev+m.nflatrate))
                     loentry.MEMO.setvalue('Gas Revenue ' + m.hyear + '/' + m.hperiod)

                     IF m.ngasrev+m.nflatrate > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcRevClear)
                     loentry.amount.setvalue(ABS(m.ngasrev+m.nflatrate))
                     loentry.MEMO.setvalue('Gas Revenue ' + m.hyear + '/' + m.hperiod)
                  ENDIF
               ENDIF
            ENDIF
            *
            *  Post Other Income
            *
            llroundit = .F.
            IF m.nothrev # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('OTH')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcacctc = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcacctc = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcacctc = ccracctnow
                  ENDCASE

                  IF EMPTY(lcacctc)
                     lcacctc = lcSuspense
                  ENDIF

                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothrev = m.nothrev + roundtmp.nothrev
                     llroundit = .T.
                  ENDIF

                  IF m.nothrev < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothrev = ROUND(m.nothrev, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcacctc)
                  loentry.amount.setvalue(ABS(m.nothrev))
                  loentry.MEMO.setvalue('Other Product Revenue ' + m.hyear + '/' + m.hperiod)

                  IF m.nothrev > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.nothrev))
                  loentry.MEMO.setvalue('Other Product Revenue ' + m.hyear + '/' + m.hperiod)
               ELSE
                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothrev = m.nothrev + roundtmp.nothrev
                     llroundit = .T.
                  ENDIF

                  IF m.nothrev < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothrev = ROUND(m.nothrev, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nothrev))
                  loentry.MEMO.setvalue('Other Product Revenue ' + m.hyear + '/' + m.hperiod)

                  IF m.nothrev > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.nothrev))
                  loentry.MEMO.setvalue('Other Product Revenue ' + m.hyear + '/' + m.hperiod)
               ENDIF
            ENDIF
            *
            *  Post Trp Income
            *
            llroundit = .F.
            IF m.ntrprev # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('TRANS')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcacctc = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcacctc = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcacctc = ccracctnow
                  ENDCASE

                  IF EMPTY(lcacctc)
                     lcacctc = lcSuspense
                  ENDIF

                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.ntrprev = m.ntrprev + roundtmp.ntrprev
                     llroundit = .T.
                  ENDIF

                  IF m.ntrprev < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.ntrprev = ROUND(m.ntrprev, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcacctc)
                  loentry.amount.setvalue(ABS(m.ntrprev))
                  loentry.MEMO.setvalue('Transportation Revenue ' + m.hyear + '/' + m.hperiod)

                  IF m.ntrprev > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.ntrprev))
                  loentry.MEMO.setvalue('Transportation Revenue ' + m.hyear + '/' + m.hperiod)
               ELSE
                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.ntrprev = m.ntrprev + roundtmp.ntrprev
                     llroundit = .T.
                  ENDIF

                  IF m.ntrprev < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.ntrprev = ROUND(m.ntrprev, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.ntrprev))
                  loentry.MEMO.setvalue('Transportation Revenue ' + m.hyear + '/' + m.hperiod)

                  IF m.ntrprev > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
               ENDIF
               loentry.entityref.listid.setvalue(lcownlistid)
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.ntrprev))
               loentry.MEMO.setvalue('Transportation Revenue ' + m.hyear + '/' + m.hperiod)
            ENDIF
            *
            *  Post Misc 1 Income
            *
            llroundit = .F.
            IF m.nmiscrev1 # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('MISC1')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcacctc = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcacctc = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcacctc = ccracctnow
                  ENDCASE

                  IF EMPTY(lcacctc)
                     lcacctc = lcSuspense
                  ENDIF

                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nmiscrev1	= m.nmiscrev1 + roundtmp.nmiscrev1
                     llroundit	= .T.
                  ENDIF

                  IF m.nmiscrev1 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nmiscrev1 = ROUND(m.nmiscrev1, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcacctc)
                  loentry.amount.setvalue(ABS(m.nmiscrev1))
                  loentry.MEMO.setvalue('Misc Revenue 1 ' + m.hyear + '/' + m.hperiod)

                  IF m.nmiscrev1 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.nmiscrev1))
                  loentry.MEMO.setvalue('Misc Revenue 1 ' + m.hyear + '/' + m.hperiod)
               ELSE
                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nmiscrev1	= m.nmiscrev1 + roundtmp.nmiscrev1
                     llroundit	= .T.
                  ENDIF

                  IF m.nmiscrev1 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nmiscrev1 = ROUND(m.nmiscrev1, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nmiscrev1))
                  loentry.MEMO.setvalue('Misc Revenue 1 ' + m.hyear + '/' + m.hperiod)

                  IF m.nmiscrev1 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.nmiscrev1))
                  loentry.MEMO.setvalue('Misc Revenue 1 ' + m.hyear + '/' + m.hperiod)
               ENDIF
            ENDIF
            *
            *  Post Misc 2 Income
            *
            llroundit = .F.
            IF m.nmiscrev2 # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('MISC2')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcacctc = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcacctc = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcacctc = ccracctnow
                  ENDCASE

                  IF EMPTY(lcacctc)
                     lcacctc = lcSuspense
                  ENDIF

                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nmiscrev2	= m.nmiscrev2 + roundtmp.nmiscrev2
                     llroundit	= .T.
                  ENDIF

                  IF m.nmiscrev2 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nmiscrev2 = ROUND(m.nmiscrev2, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcacctc)
                  loentry.amount.setvalue(ABS(m.nmiscrev2))
                  loentry.MEMO.setvalue('Misc Revenue 2 ' + m.hyear + '/' + m.hperiod)

                  IF m.nmiscrev2 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.nmiscrev2))
                  loentry.MEMO.setvalue('Misc Revenue 2 ' + m.hyear + '/' + m.hperiod)
               ELSE
                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nmiscrev2	= m.nmiscrev2 + roundtmp.nmiscrev2
                     llroundit	= .T.
                  ENDIF

                  IF m.nmiscrev2 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nmiscrev2 = ROUND(m.nmiscrev2, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nmiscrev2))
                  loentry.MEMO.setvalue('Misc Revenue 2 ' + m.hyear + '/' + m.hperiod)

                  IF m.nmiscrev2 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.nmiscrev2))
                  loentry.MEMO.setvalue('Misc Revenue 2 ' + m.hyear + '/' + m.hperiod)

               ENDIF

            ENDIF

            *
            *  Post Gathering
            *
            llroundit = .F.
            IF m.ngather # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('GATH')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcacctc = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcacctc = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcacctc = ccracctnow
                  ENDCASE
               ELSE
                  SWSELECT('expcat')
                  SET ORDER TO cCatCode
                  IF SEEK('GATH')
                     lcacctc = cownacctlistid
                  ELSE
                     lcacctc = lcSuspense
                  ENDIF
               ENDIF

               IF llround AND NOT llroundit
                  SELE roundtmp
                  REPL lused WITH .T.
                  m.ngather = m.ngather + roundtmp.ngather
                  llroundit = .T.
               ENDIF

               IF m.ngather > 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
               ENDIF
               IF NOT EMPTY(lcwelllistid)
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               m.ngather = ROUND(m.ngather, 2)
               loentry.entityref.listid.setvalue(lcownlistid)
               loentry.accountref.listid.setvalue(lcacctc)
               loentry.amount.setvalue(ABS(m.ngather))
               loentry.MEMO.setvalue('Gathering Expense ' + m.hyear + '/' + m.hperiod)

               IF m.ngather < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
               ENDIF
               IF NOT EMPTY(lcwelllistid)
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownlistid)
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.ngather))
               loentry.MEMO.setvalue('Gathering Expense ' + m.hyear + '/' + m.hperiod)
            ENDIF

            *
            *  Post Compression
            *
            llroundit = .F.
            IF m.ncompress # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('COMP')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcacctc = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcacctc = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcacctc = ccracctnow
                  ENDCASE
               ELSE
                  SWSELECT('expcat')
                  SET ORDER TO cCatCode   && CCATCODE
                  IF SEEK('COMP')
                     lcacctc = cownacctlistid
                  ELSE
                     lcacctc = lcSuspense
                  ENDIF
               ENDIF


               IF llround AND NOT llroundit
                  SELE roundtmp
                  REPL lused WITH .T.
                  m.ncompress = m.ncompress + roundtmp.ncompress
                  llroundit	 = .T.
               ENDIF

               IF m.ncompress > 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
               ENDIF
               IF NOT EMPTY(lcwelllistid)
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               m.ncompress = ROUND(m.ncompress, 2)
               loentry.entityref.listid.setvalue(lcownlistid)
               loentry.accountref.listid.setvalue(lcacctc)
               loentry.amount.setvalue(ABS(m.ncompress))
               loentry.MEMO.setvalue('Compression Expense ' + m.hyear + '/' + m.hperiod)

               IF m.ncompress < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
               ENDIF
               IF NOT EMPTY(lcwelllistid)
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownlistid)
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.ncompress))
               loentry.MEMO.setvalue('Compression Expense ' + m.hyear + '/' + m.hperiod)

            ENDIF

            *
            *  Post Marketing Expenses
            *
            llroundit = .F.
            IF m.nmktgexp # 0
               SWSELECT('expcat')
               SET ORDER TO cCatCode
               IF SEEK('MKTG')
                  lcacctc = cownacctlistid

                  IF EMPTY(lcacctc)
                     lcacctc = lcSuspense
                  ENDIF

                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nmktgexp = m.nmktgexp + roundtmp.nmktgexp
                     llroundit  = .T.
                  ENDIF

                  IF m.nmktgexp > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nmktgexp = ROUND(m.nmktgexp, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcacctc)
                  loentry.amount.setvalue(ABS(m.nmktgexp))
                  loentry.MEMO.setvalue('Marketing Expenses ' + m.hyear + '/' + m.hperiod)

                  IF m.nmktgexp < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcExpClear)
                  loentry.amount.setvalue(ABS(m.nmktgexp))
                  loentry.MEMO.setvalue('Marketing Expense ' + m.hyear + '/' + m.hperiod)
               ELSE
                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nmktgexp = m.nmktgexp + roundtmp.nmktgexp
                     llroundit  = .T.
                  ENDIF

                  IF m.nmktgexp > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nmktgexp = ROUND(m.nmktgexp, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nmktgexp))
                  loentry.MEMO.setvalue('Marketing Expense ' + m.hyear + '/' + m.hperiod)

                  IF m.nmktgexp > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcExpClear)
                  loentry.amount.setvalue(ABS(m.nmktgexp))
                  loentry.MEMO.setvalue('Marketing Expense ' + m.hyear + '/' + m.hperiod)

               ENDIF

            ENDIF
            *
            *  Post Oil Taxes
            *
            llroundit = .F.
            IF m.noiltax1 # 0
               IF INLIST(m.cdirect, 'O', 'B') AND m.ldiroilpurch
                  *
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('OTAX1')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcoilacctd = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcoilacctd = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcoilacctd = ccracctnow
                     ENDCASE
                     lcTaxDesc = ALLTRIM(crevdesc) + ' ' + m.hyear + '/' + m.hperiod

                     IF EMPTY(lcoilacctd)
                        lcoilacctd = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noiltax1 = m.noiltax1 + roundtmp.noiltax1
                        llroundit  = .T.
                     ENDIF

                     IF m.noiltax1 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF

                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.noiltax1 = ROUND(m.noiltax1, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcoilacctd)
                     loentry.amount.setvalue(ABS(m.noiltax1))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.noiltax1 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev1o
                        loentry.accountref.listid.setvalue(m.ctaxacct1)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.noiltax1))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ELSE
                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noiltax1 = m.noiltax1 + roundtmp.noiltax1
                        llroundit  = .T.
                     ENDIF

                     lcTaxDesc = 'Oil Taxes'

                     IF m.noiltax1 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.noiltax1 = ROUND(m.noiltax1, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.noiltax1))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.noiltax1 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev1o
                        loentry.accountref.listid.setvalue(m.ctaxacct1)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.noiltax1))
                     loentry.MEMO.setvalue(lcTaxDesc)

                  ENDIF
               ENDIF
            ENDIF

            llroundit = .F.
            IF m.noiltax2 # 0
               IF INLIST(m.cdirect, 'O', 'B') AND m.ldiroilpurch
                  *
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('OTAX2')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcoilacctd = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcoilacctd = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcoilacctd = ccracctnow
                     ENDCASE
                     lcTaxDesc = crevdesc

                     IF EMPTY(lcoilacctd)
                        lcoilacctd = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noiltax2 = m.noiltax2 + roundtmp.noiltax2
                        llroundit  = .T.
                     ENDIF

                     IF m.noiltax2 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.noiltax2 = ROUND(m.noiltax2, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcoilacctd)
                     loentry.amount.setvalue(ABS(m.noiltax2))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.noiltax2 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev2o
                        loentry.accountref.listid.setvalue(m.ctaxacct2)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.noiltax2))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ELSE
                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noiltax2 = m.noiltax2 + roundtmp.noiltax2
                        llroundit  = .T.
                     ENDIF

                     lcTaxDesc = 'Oil Taxes'

                     IF m.noiltax2 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.noiltax2 = ROUND(m.noiltax2, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.noiltax2))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.noiltax2 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev2o
                        loentry.accountref.listid.setvalue(m.ctaxacct2)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.noiltax2))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ENDIF
               ENDIF
            ENDIF

            llroundit = .F.
            IF m.noiltax3 # 0
               IF INLIST(m.cdirect, 'O', 'B') AND m.ldiroilpurch
                  *
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('OTAX3')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcoilacctd = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcoilacctd = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcoilacctd = ccracctnow
                     ENDCASE
                     lcTaxDesc = crevdesc

                     IF EMPTY(lcoilacctd)
                        lcoilacctd = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noiltax3 = m.noiltax3 + roundtmp.noiltax3
                        llroundit  = .T.
                     ENDIF

                     IF m.noiltax3 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.noiltax3 = ROUND(m.noiltax3, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcoilacctd)
                     loentry.amount.setvalue(ABS(m.noiltax3))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.noiltax3 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev3o
                        loentry.accountref.listid.setvalue(m.ctaxacct3)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.noiltax3))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ELSE
                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noiltax3 = m.noiltax3 + roundtmp.noiltax3
                        llroundit  = .T.
                     ENDIF

                     lcTaxDesc = 'Oil Taxes'

                     IF m.noiltax3 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.noiltax3 = ROUND(m.noiltax3, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.noiltax3))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.noiltax3 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev3o
                        loentry.accountref.listid.setvalue(m.ctaxacct3)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.noiltax3))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ENDIF
               ENDIF
            ENDIF

            llroundit = .F.
            IF m.noiltax4 # 0
               IF INLIST(m.cdirect, 'O', 'B') AND m.ldiroilpurch
                  *
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('OTAX4')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcoilacctd = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcoilacctd = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcoilacctd = ccracctnow
                     ENDCASE
                     lcTaxDesc = crevdesc

                     IF EMPTY(lcoilacctd)
                        lcoilacctd = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noiltax4 = m.noiltax4 + roundtmp.noiltax4
                        llroundit  = .T.
                     ENDIF

                     IF m.noiltax4 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.noiltax4 = ROUND(m.noiltax4, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcoilacctd)
                     loentry.amount.setvalue(ABS(m.noiltax4))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.noiltax4 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev4o
                        loentry.accountref.listid.setvalue(m.ctaxacct4)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.noiltax4))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ELSE
                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.noiltax4 = m.noiltax4 + roundtmp.noiltax4
                        llroundit  = .T.
                     ENDIF

                     lcTaxDesc = 'Oil Taxes'

                     IF m.noiltax4 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.noiltax4 = ROUND(m.noiltax4, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.noiltax4))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.noiltax4 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev4o
                        loentry.accountref.listid.setvalue(m.ctaxacct4)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.noiltax4))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ENDIF
               ENDIF
            ENDIF

            *
            *  Post Gas Taxes
            *
            llroundit = .F.
            IF m.ngastax1 # 0
               IF INLIST(m.cdirect, 'G', 'B') AND m.ldirgaspurch
                  *
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('GTAX1')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcgasacctd = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcgasacctd = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcgasacctd = ccracctnow
                     ENDCASE
                     lcTaxDesc = crevdesc

                     IF EMPTY(lcgasacctd)
                        lcgasacctd = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngastax1 = m.ngastax1 + roundtmp.ngastax1
                        llroundit  = .T.
                     ENDIF

                     IF m.ngastax1 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngastax1 = ROUND(m.ngastax1, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcgasacctd)
                     loentry.amount.setvalue(ABS(m.ngastax1))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.ngastax1 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev1g
                        loentry.accountref.listid.setvalue(m.ctaxacct1)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.ngastax1))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ELSE
                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngastax1 = m.ngastax1 + roundtmp.ngastax1
                        llroundit  = .T.
                     ENDIF

                     lcTaxDesc = 'Gas Taxes'

                     IF m.ngastax1 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngastax1 = ROUND(m.ngastax1, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.ngastax1))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.ngastax1 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev1g
                        loentry.accountref.listid.setvalue(m.ctaxacct1)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.ngastax1))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ENDIF
               ENDIF
            ENDIF

            llroundit = .F.
            IF m.ngastax2 # 0
               IF INLIST(m.cdirect, 'G', 'B') AND m.ldirgaspurch
                  *
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('GTAX2')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcgasacctd = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcgasacctd = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcgasacctd = ccracctnow
                     ENDCASE
                     lcTaxDesc = crevdesc

                     IF EMPTY(lcgasacctd)
                        lcgasacctd = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngastax2 = m.ngastax2 + roundtmp.ngastax2
                        llroundit  = .T.
                     ENDIF

                     IF m.ngastax2 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngastax2 = ROUND(m.ngastax2, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcgasacctd)
                     loentry.amount.setvalue(ABS(m.ngastax2))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.ngastax2 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev2g
                        loentry.accountref.listid.setvalue(m.ctaxacct2)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.ngastax2))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ELSE
                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngastax2 = m.ngastax2 + roundtmp.ngastax2
                        llroundit  = .T.
                     ENDIF

                     lcTaxDesc = 'Gas Taxes'

                     IF m.ngastax2 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngastax2 = ROUND(m.ngastax2, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.ngastax2))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.ngastax2 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev2g
                        loentry.accountref.listid.setvalue(m.ctaxacct2)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.ngastax2))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ENDIF
               ENDIF
            ENDIF

            llroundit = .F.
            IF m.ngastax3 # 0
               IF INLIST(m.cdirect, 'G', 'B') AND m.ldirgaspurch
                  *
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('GTAX3')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcgasacctd = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcgasacctd = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcgasacctd = ccracctnow
                     ENDCASE
                     lcTaxDesc = crevdesc

                     IF EMPTY(lcgasacctd)
                        lcgasacctd = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngastax3 = m.ngastax3 + roundtmp.ngastax3
                        llroundit  = .T.
                     ENDIF

                     IF m.ngastax3 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngastax3 = ROUND(m.ngastax3, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcgasacctd)
                     loentry.amount.setvalue(ABS(m.ngastax3))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.ngastax3 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev3g
                        loentry.accountref.listid.setvalue(m.ctaxacct3)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.ngastax3))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ELSE
                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngastax3 = m.ngastax3 + roundtmp.ngastax3
                        llroundit  = .T.
                     ENDIF

                     lcTaxDesc = 'Gas Taxes'

                     IF m.ngastax3 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngastax3 = ROUND(m.ngastax3, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.ngastax3))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.ngastax3 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev3g
                        loentry.accountref.listid.setvalue(m.ctaxacct3)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.ngastax3))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ENDIF
               ENDIF
            ENDIF

            llroundit = .F.
            IF m.ngastax4 # 0
               IF INLIST(m.cdirect, 'G', 'B') AND m.ldirgaspurch
                  *
               ELSE
                  SWSELECT('revcat')
                  SET ORDER TO crevtype
                  IF SEEK('GTAX4')
                     DO CASE
                        CASE m.ctypeinv = 'L'
                           lcgasacctd = ccracctnol
                        CASE m.ctypeinv = 'O'
                           lcgasacctd = ccracctnoo
                        CASE m.ctypeinv = 'W'
                           lcgasacctd = ccracctnow
                     ENDCASE
                     lcTaxDesc = crevdesc

                     IF EMPTY(lcgasacctd)
                        lcgasacctd = lcSuspense
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngastax4 = m.ngastax4 + roundtmp.ngastax4
                        llroundit  = .T.
                     ENDIF

                     IF m.ngastax4 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngastax4 = ROUND(m.ngastax4, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcgasacctd)
                     loentry.amount.setvalue(ABS(m.ngastax4))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.ngastax4 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev4g
                        loentry.accountref.listid.setvalue(m.ctaxacct4)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.ngastax4))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ELSE
                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.ngastax4 = m.ngastax4 + roundtmp.ngastax4
                        llroundit  = .T.
                     ENDIF

                     lcTaxDesc = 'Gas Taxes'

                     IF m.ngastax4 > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.ngastax4 = ROUND(m.ngastax4, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcSuspense)
                     loentry.amount.setvalue(ABS(m.ngastax4))
                     loentry.MEMO.setvalue(lcTaxDesc)

                     IF m.ngastax4 < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownlistid)
                     IF NOT m.lsev4g
                        loentry.accountref.listid.setvalue(m.ctaxacct4)
                     ELSE
                        loentry.accountref.listid.setvalue(lcRevClear)
                     ENDIF
                     loentry.amount.setvalue(ABS(m.ngastax4))
                     loentry.MEMO.setvalue(lcTaxDesc)
                  ENDIF
               ENDIF
            ENDIF
            *
            *  Post Other Product Taxes
            *
            llroundit = .F.
            IF m.nothtax1 # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('PTAX1')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcgasacctd = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcgasacctd = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcgasacctd = ccracctnow
                  ENDCASE
                  lcTaxDesc = crevdesc

                  IF EMPTY(lcgasacctd)
                     lcgasacctd = lcSuspense
                  ENDIF

                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothtax1 = m.nothtax1 + roundtmp.nothtax1
                     llroundit  = .T.
                  ENDIF

                  IF m.nothtax1 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothtax1 = ROUND(m.nothtax1, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcgasacctd)
                  loentry.amount.setvalue(ABS(m.nothtax1))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.nothtax1 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev1p
                     loentry.accountref.listid.setvalue(m.ctaxacct1)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.nothtax1))
                  loentry.MEMO.setvalue(lcTaxDesc)
               ELSE
                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothtax1 = m.nothtax1 + roundtmp.nothtax1
                     llroundit  = .T.
                  ENDIF

                  lcTaxDesc = 'Other Taxes'

                  IF m.nothtax1 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothtax1 = ROUND(m.nothtax1, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nothtax1))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.nothtax1 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev1p
                     loentry.accountref.listid.setvalue(m.ctaxacct1)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.nothtax1))
                  loentry.MEMO.setvalue(lcTaxDesc)

               ENDIF
            ENDIF

            llroundit = .F.
            IF m.nothtax2 # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('PTAX2')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcgasacctd = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcgasacctd = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcgasacctd = ccracctnow
                  ENDCASE
                  lcTaxDesc = crevdesc

                  IF EMPTY(lcgasacctd)
                     lcgasacctd = lcSuspense
                  ENDIF

                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothtax2 = m.nothtax2 + roundtmp.nothtax2
                     llroundit  = .T.
                  ENDIF

                  IF m.nothtax2 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothtax2 = ROUND(m.nothtax2, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcgasacctd)
                  loentry.amount.setvalue(ABS(m.nothtax2))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.nothtax2 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev2p
                     loentry.accountref.listid.setvalue(m.ctaxacct2)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.nothtax2))
                  loentry.MEMO.setvalue(lcTaxDesc)
               ELSE
                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothtax2 = m.nothtax2 + roundtmp.nothtax2
                     llroundit  = .T.
                  ENDIF

                  lcTaxDesc = 'Other Taxes'

                  IF m.nothtax2 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothtax2 = ROUND(m.nothtax2, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nothtax2))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.nothtax2 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev2p
                     loentry.accountref.listid.setvalue(m.ctaxacct2)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.nothtax2))
                  loentry.MEMO.setvalue(lcTaxDesc)
               ENDIF
            ENDIF

            llroundit = .F.
            IF m.nothtax3 # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('PTAX3')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcgasacctd = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcgasacctd = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcgasacctd = ccracctnow
                  ENDCASE
                  lcTaxDesc = crevdesc

                  IF EMPTY(lcgasacctd)
                     lcgasacctd = lcSuspense
                  ENDIF

                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothtax3 = m.nothtax3 + roundtmp.nothtax3
                     llroundit  = .T.
                  ENDIF

                  IF m.nothtax3 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothtax3 = ROUND(m.nothtax3, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcgasacctd)
                  loentry.amount.setvalue(ABS(m.nothtax3))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.nothtax3 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev3p
                     loentry.accountref.listid.setvalue(m.ctaxacct3)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.nothtax3))
                  loentry.MEMO.setvalue(lcTaxDesc)
               ELSE
                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothtax3 = m.nothtax3 + roundtmp.nothtax3
                     llroundit  = .T.
                  ENDIF

                  lcTaxDesc = 'Other Taxes'

                  IF m.nothtax3 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothtax3 = ROUND(m.nothtax3, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nothtax3))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.nothtax3 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev3p
                     loentry.accountref.listid.setvalue(m.ctaxacct3)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.nothtax3))
                  loentry.MEMO.setvalue(lcTaxDesc)
               ENDIF
            ENDIF

            llroundit = .F.
            IF m.nothtax4 # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('PTAX4')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcgasacctd = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcgasacctd = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcgasacctd = ccracctnow
                  ENDCASE
                  lcTaxDesc = crevdesc

                  IF EMPTY(lcgasacctd)
                     lcgasacctd = lcSuspense
                  ENDIF

                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothtax4 = m.nothtax4 + roundtmp.nothtax4
                     llroundit  = .T.
                  ENDIF

                  IF m.nothtax4 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothtax4 = ROUND(m.nothtax4, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcgasacctd)
                  loentry.amount.setvalue(ABS(m.nothtax4))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.nothtax4 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev4p
                     loentry.accountref.listid.setvalue(m.ctaxacct4)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.nothtax4))
                  loentry.MEMO.setvalue(lcTaxDesc)
               ELSE
                  IF llround AND NOT llroundit
                     SELE roundtmp
                     REPL lused WITH .T.
                     m.nothtax4 = m.nothtax4 + roundtmp.nothtax4
                     llroundit  = .T.
                  ENDIF

                  lcTaxDesc = 'Other Taxes'

                  IF m.nothtax4 > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.nothtax4 = ROUND(m.nothtax4, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.nothtax4))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.nothtax4 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev4p
                     loentry.accountref.listid.setvalue(m.ctaxacct4)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.nothtax4))
                  loentry.MEMO.setvalue(lcTaxDesc)
               ENDIF
            ENDIF
            *
            *  Process default class expenses
            *
            llroundit = .F.
            lnexpense = 0
            IF llsepclose AND lljib
               *  Do Nothing
            ELSE
               llExpense = .F.
               IF (m.nexpense # 0 OR THIS.Well_Activity(.F., m.cWellID)) AND NOT m.ljib AND m.nworkint # 0
                  lntotal = 0
                  SWSELECT('expense')
                  SCAN FOR cyear + cperiod = m.hyear + m.hperiod ;
                        AND IIF(EMPTY(m.csusptype), nrunnorev = THIS.nrunno, nrunnorev = m.nrunno_in) ;
                        AND IIF(EMPTY(m.csusptype), crunyearrev = THIS.crunyear, crunyearrev = m.crunyear_in) ;
                        AND dexpdate    <= THIS.dexpdate ;
                        AND cWellID      = m.cWellID   ;
                        AND cexpclass    = '0'  ;
                        AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
                     llExpense	= .T.
                     m.ccateg	= cCatCode + '-' + ALLTRIM(ccateg) + ' ' + m.hyear + '/' + m.hperiod
                     m.cCatCode	= cCatCode
                     m.namount	= namount
                     lcownerid	= cOwnerID
                     m.cexpclass	= cexpclass

                     *
                     *  Get the account numbers to post this expense to
                     *
                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdracct   = cownacctlistid
                     ELSE
                        m.cdracct   = lcSuspense
                     ENDIF

                     *  If the expcat field is blank, use the suspense account from glopt
                     IF EMPTY(ALLT(m.cdracct))
                        m.cdracct = lcSuspense
                     ENDIF

                     *
                     *  Post Expenses
                     *
                     IF NOT EMPTY(lcownerid)           && Check for one-man items
                        IF lcownerid # m.cOwnerID
                           LOOP
                        ENDIF
                     ELSE
                        m.namount = ROUND(m.namount * (m.nworkint / 100), 2)
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.namount = m.namount + roundtmp.nexpense
                        llroundit = .T.
                     ENDIF

                     lnexpense = lnexpense + m.namount

                     IF m.namount > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     m.namount = ROUND(m.namount, 2)
                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cdracct)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue(m.ccateg)


                     *  Post expense clearing entry

                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     lnexpense = ROUND(lnexpense, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue('Well Expenses ' + m.hyear + '/' + m.hperiod)
                  ENDSCAN
               ENDIF

               *
               *  Process class 1 expenses
               *
               llroundit	 = .F.
               lnexpense1 = 0
               llExpense	 = .F.
               IF (m.ntotale1 # 0 OR THIS.Well_Activity(.F., m.cWellID)) AND NOT m.ljib AND m.nintclass1 # 0
                  lntotal = 0
                  SWSELECT('expense')
                  SCAN FOR cyear + cperiod = m.hyear + m.hperiod ;
                        AND IIF(EMPTY(m.csusptype), nrunnorev = THIS.nrunno, nrunnorev = m.nrunno_in) ;
                        AND IIF(EMPTY(m.csusptype), crunyearrev = THIS.crunyear, crunyearrev = m.crunyear_in) ;
                        AND dexpdate    <= THIS.dexpdate ;
                        AND cWellID      = m.cWellID   ;
                        AND cexpclass    = '1'  ;
                        AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
                     llExpense	= .T.
                     m.ccateg	= cCatCode + '-' + ALLTRIM(ccateg)
                     m.cCatCode	= cCatCode
                     m.namount	= namount
                     lcownerid	= cOwnerID
                     m.cexpclass	= cexpclass

                     *
                     *  Get the account numbers to post this expense to
                     *
                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdracct   = cownacctlistid
                     ELSE
                        m.cdracct   = lcSuspense
                     ENDIF

                     *  If the expcat field is blank, use the suspense account from glopt
                     IF EMPTY(ALLT(m.cdracct))
                        m.cdracct = lcSuspense
                     ENDIF

                     *
                     *  Post Expenses
                     *
                     IF NOT EMPTY(lcownerid)           && Check for one-man items
                        IF lcownerid # m.cOwnerID
                           LOOP
                        ENDIF
                     ELSE
                        m.namount = ROUND(m.namount * (m.nintclass1 / 100), 2)
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.namount = m.namount + roundtmp.ntotale1
                        llroundit = .T.
                     ENDIF

                     lnexpense1 = lnexpense1 + m.namount

                     IF m.namount > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.namount = ROUND(m.namount, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cdracct)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue(m.ccateg)


                     *  Post expense clearing entry

                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     lnexpense1 = ROUND(lnexpense1, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue('Class 1 Expenses ' + m.hyear + '/' + m.hperiod)
                  ENDSCAN
               ENDIF
               *
               *  Process class 2 expenses
               *
               llroundit	 = .F.
               lnexpense2 = 0
               llExpense	 = .F.
               IF (m.ntotale2 # 0 OR THIS.Well_Activity(.F., m.cWellID)) AND NOT m.ljib  AND m.nintclass2 # 0
                  lntotal = 0
                  SWSELECT('expense')
                  SCAN FOR cyear + cperiod = m.hyear + m.hperiod ;
                        AND IIF(EMPTY(m.csusptype), nrunnorev = THIS.nrunno, nrunnorev = m.nrunno_in) ;
                        AND IIF(EMPTY(m.csusptype), crunyearrev = THIS.crunyear, crunyearrev = m.crunyear_in) ;
                        AND dexpdate    <= THIS.dexpdate ;
                        AND cWellID      = m.cWellID   ;
                        AND cexpclass    = '2'  ;
                        AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
                     llExpense	= .T.
                     m.ccateg	= cCatCode + '-' + ALLTRIM(ccateg)
                     m.cCatCode	= cCatCode
                     m.namount	= namount
                     lcownerid	= cOwnerID
                     m.cexpclass	= cexpclass

                     *
                     *  Get the account numbers to post this expense to
                     *
                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdracct   = cownacctlistid
                     ELSE
                        m.cdracct   = lcSuspense
                     ENDIF

                     *  If the expcat field is blank, use the suspense account from glopt
                     IF EMPTY(ALLT(m.cdracct))
                        m.cdracct = lcSuspense
                     ENDIF

                     *
                     *  Post Expenses
                     *
                     IF NOT EMPTY(lcownerid)           && Check for one-man items
                        IF lcownerid # m.cOwnerID
                           LOOP
                        ENDIF
                     ELSE
                        m.namount = ROUND(m.namount * (m.nintclass2 / 100), 2)
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.namount = m.namount + roundtmp.ntotale2
                        llroundit = .T.
                     ENDIF

                     lnexpense2 = lnexpense2 + m.namount

                     IF m.namount > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.namount = ROUND(m.namount, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cdracct)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue(m.ccateg)

                     *  Post expense clearing entry

                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     lnexpense2 = ROUND(lnexpense2, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue('Class 2 Expenses ' + m.hyear + '/' + m.hperiod)
                  ENDSCAN
               ENDIF
               *
               *  Process class 3 expenses
               *
               llroundit	 = .F.
               lnexpense3 = 0
               llExpense	 = .F.
               IF (m.ntotale3 # 0 OR THIS.Well_Activity(.F., m.cWellID)) AND NOT m.ljib  AND m.nintclass3 # 0
                  lntotal = 0
                  SWSELECT('expense')
                  SCAN FOR cyear + cperiod = m.hyear + m.hperiod ;
                        AND IIF(EMPTY(m.csusptype), nrunnorev = THIS.nrunno, nrunnorev = m.nrunno_in) ;
                        AND IIF(EMPTY(m.csusptype), crunyearrev = THIS.crunyear, crunyearrev = m.crunyear_in) ;
                        AND dexpdate    <= THIS.dexpdate ;
                        AND cWellID      = m.cWellID   ;
                        AND cexpclass    = '3'  ;
                        AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
                     llExpense	= .T.
                     m.ccateg	= cCatCode + '-' + ALLTRIM(ccateg)
                     m.cCatCode	= cCatCode
                     m.namount	= namount
                     lcownerid	= cOwnerID
                     m.cexpclass	= cexpclass

                     *
                     *  Get the account numbers to post this expense to
                     *
                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdracct   = cownacctlistid
                     ELSE
                        m.cdracct   = lcSuspense
                     ENDIF

                     *  If the expcat field is blank, use the suspense account from glopt
                     IF EMPTY(ALLT(m.cdracct))
                        m.cdracct = lcSuspense
                     ENDIF

                     *
                     *  Post Expenses
                     *
                     IF NOT EMPTY(lcownerid)           && Check for one-man items
                        IF lcownerid # m.cOwnerID
                           LOOP
                        ENDIF
                     ELSE
                        m.namount = ROUND(m.namount * (m.nintclass3 / 100), 2)
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.namount = m.namount + roundtmp.ntotale3
                        llroundit = .T.
                     ENDIF

                     lnexpense3 = lnexpense3 + m.namount

                     IF m.namount > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.namount = ROUND(m.namount, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cdracct)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue(m.ccateg)

                     *  Post expense clearing entry

                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     lnexpense3 = ROUND(lnexpense3, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue('Class 3 Expenses ' + m.hyear + '/' + m.hperiod)
                  ENDSCAN
               ENDIF

               *
               *  Process class 4 expenses
               *
               llroundit	 = .F.
               lnexpense4 = 0
               llExpense	 = .F.
               IF (m.ntotale4 # 0 OR THIS.Well_Activity(.F., m.cWellID)) AND NOT m.ljib  AND m.nintclass4 # 0
                  lntotal = 0
                  SWSELECT('expense')
                  SCAN FOR cyear + cperiod = m.hyear + m.hperiod ;
                        AND IIF(EMPTY(m.csusptype), nrunnorev = THIS.nrunno, nrunnorev = m.nrunno_in) ;
                        AND IIF(EMPTY(m.csusptype), crunyearrev = THIS.crunyear, crunyearrev = m.crunyear_in) ;
                        AND dexpdate    <= THIS.dexpdate ;
                        AND cWellID      = m.cWellID   ;
                        AND cexpclass    = '4'  ;
                        AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
                     llExpense	= .T.
                     m.ccateg	= cCatCode + '-' + ALLTRIM(ccateg)
                     m.cCatCode	= cCatCode
                     m.namount	= namount
                     lcownerid	= cOwnerID
                     m.cexpclass	= cexpclass

                     *
                     *  Get the account numbers to post this expense to
                     *
                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdracct   = cownacctlistid
                     ELSE
                        m.cdracct   = lcSuspense
                     ENDIF

                     *  If the expcat field is blank, use the suspense account from glopt
                     IF EMPTY(ALLT(m.cdracct))
                        m.cdracct = lcSuspense
                     ENDIF

                     *
                     *  Post Expenses
                     *
                     IF NOT EMPTY(lcownerid)           && Check for one-man items
                        IF lcownerid # m.cOwnerID
                           LOOP
                        ENDIF
                     ELSE
                        m.namount = ROUND(m.namount * (m.nintclass4 / 100), 2)
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.namount = m.namount + roundtmp.ntotale4
                        llroundit = .T.
                     ENDIF

                     lnexpense4 = lnexpense4 + m.namount

                     IF m.namount > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.namount = ROUND(m.namount, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cdracct)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue(m.ccateg)

                     *  Post expense clearing entry

                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     lnexpense4 = ROUND(lnexpense4, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue('Class 4 Expenses ' + m.hyear + '/' + m.hperiod)
                  ENDSCAN
               ENDIF

               *
               *  Process class 5 expenses
               *
               llroundit	 = .F.
               lnexpense5 = 0
               llExpense	 = .F.
               IF (m.ntotale5 # 0 OR THIS.Well_Activity(.F., m.cWellID)) AND NOT m.ljib  AND m.nintclass5 # 0
                  lntotal = 0
                  SWSELECT('expense')
                  SCAN FOR cyear + cperiod = m.hyear + m.hperiod ;
                        AND IIF(EMPTY(m.csusptype), nrunnorev = THIS.nrunno, nrunnorev = m.nrunno_in) ;
                        AND IIF(EMPTY(m.csusptype), crunyearrev = THIS.crunyear, crunyearrev = m.crunyear_in) ;
                        AND dexpdate    <= THIS.dexpdate ;
                        AND cWellID      = m.cWellID   ;
                        AND cexpclass    = '5'  ;
                        AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
                     llExpense	= .T.
                     m.ccateg	= cCatCode + '-' + ALLTRIM(ccateg)
                     m.cCatCode	= cCatCode
                     m.namount	= namount
                     lcownerid	= cOwnerID
                     m.cexpclass	= cexpclass

                     *
                     *  Get the account numbers to post this expense to
                     *
                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdracct   = cownacctlistid
                     ELSE
                        m.cdracct   = lcSuspense
                     ENDIF

                     *  If the expcat field is blank, use the suspense account from glopt
                     IF EMPTY(ALLT(m.cdracct))
                        m.cdracct = lcSuspense
                     ENDIF

                     *
                     *  Post Expenses
                     *
                     IF NOT EMPTY(lcownerid)           && Check for one-man items
                        IF lcownerid # m.cOwnerID
                           LOOP
                        ENDIF
                     ELSE
                        m.namount = ROUND(m.namount * (m.nintclass5 / 100), 2)
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.namount = m.namount + roundtmp.ntotale5
                        llroundit = .T.
                     ENDIF

                     lnexpense5 = lnexpense5 + m.namount

                     IF m.namount > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.namount = ROUND(m.namount, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cdracct)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue(m.ccateg)

                     *  Post expense clearing entry

                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue('Class 5 Expenses ' + m.hyear + '/' + m.hperiod)
                  ENDSCAN
               ENDIF

               *
               *  Process ACP expenses
               *
               llroundit	 = .F.
               lnexpensea = 0
               llExpense	 = .F.
               IF (m.ntotalea # 0 OR THIS.Well_Activity(.F., m.cWellID)) AND NOT m.ljib  AND m.nacpint # 0
                  lntotal = 0
                  SWSELECT('expense')
                  SCAN FOR cyear + cperiod = m.hyear + m.hperiod ;
                        AND IIF(EMPTY(m.csusptype), nrunnorev = THIS.nrunno, nrunnorev = m.nrunno_in) ;
                        AND IIF(EMPTY(m.csusptype), crunyearrev = THIS.crunyear, crunyearrev = m.crunyear_in) ;
                        AND dexpdate    <= THIS.dexpdate ;
                        AND cWellID      = m.cWellID   ;
                        AND cexpclass    = 'A'  ;
                        AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
                     llExpense	= .T.
                     m.ccateg	= cCatCode + '-' + ALLTRIM(ccateg)
                     m.cCatCode	= cCatCode
                     m.namount	= namount
                     lcownerid	= cOwnerID
                     m.cexpclass	= cexpclass

                     *
                     *  Get the account numbers to post this expense to
                     *
                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdracct   = cownacctlistid
                     ELSE
                        m.cdracct   = lcSuspense
                     ENDIF

                     *  If the expcat field is blank, use the suspense account from glopt
                     IF EMPTY(ALLT(m.cdracct))
                        m.cdracct = lcSuspense
                     ENDIF

                     *
                     *  Post Expenses
                     *
                     IF NOT EMPTY(lcownerid)           && Check for one-man items
                        IF lcownerid # m.cOwnerID
                           LOOP
                        ENDIF
                     ELSE
                        m.namount = ROUND(m.namount * (m.nacpint / 100), 2)
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.namount = m.namount + roundtmp.ntotalea
                        llroundit = .T.
                     ENDIF

                     lnexpensea = lnexpensea + m.namount

                     IF m.namount > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.namount = ROUND(m.namount, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cdracct)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue(m.ccateg)


                     *  Post expense clearing entry

                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue('After Casing Point Expenses ' + m.hyear + '/' + m.hperiod)
                  ENDSCAN
               ENDIF

               *
               *  Process BCP expenses
               *
               llroundit	 = .F.
               lnexpenseb = 0
               IF (m.ntotaleb # 0 OR THIS.Well_Activity(.F., m.cWellID)) AND NOT m.ljib  AND m.nbcpint # 0
                  lntotal = 0
                  SWSELECT('expense')
                  SCAN FOR cyear + cperiod = m.hyear + m.hperiod ;
                        AND IIF(EMPTY(m.csusptype), nrunnorev = THIS.nrunno, nrunnorev = m.nrunno_in) ;
                        AND IIF(EMPTY(m.csusptype), crunyearrev = THIS.crunyear, crunyearrev = m.crunyear_in) ;
                        AND dexpdate    <= THIS.dexpdate ;
                        AND cWellID      = m.cWellID   ;
                        AND cexpclass    = 'B'  ;
                        AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')

                     m.ccateg	= cCatCode + '-' + ALLTRIM(ccateg)
                     m.cCatCode	= cCatCode
                     m.namount	= namount
                     lcownerid	= cOwnerID
                     m.cexpclass	= cexpclass

                     *
                     *  Get the account numbers to post this expense to
                     *
                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdracct   = cownacctlistid
                     ELSE
                        m.cdracct   = lcSuspense
                     ENDIF

                     *  If the expcat field is blank, use the suspense account from glopt
                     IF EMPTY(ALLT(m.cdracct))
                        m.cdracct = lcSuspense
                     ENDIF

                     *  Post Expenses
                     IF NOT EMPTY(lcownerid)           && Check for one-man items
                        IF lcownerid # m.cOwnerID
                           LOOP
                        ENDIF
                     ELSE
                        m.namount = ROUND(m.namount * (m.nbcpint / 100), 2)
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.namount = m.namount + roundtmp.ntotaleb
                        llroundit = .T.
                     ENDIF

                     lnexpenseb = lnexpenseb + m.namount

                     IF m.namount > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.namount = ROUND(m.namount, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cdracct)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue(m.ccateg)

                     *  Post expense clearing entry
                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue('Before Casing Expenses ' + m.hyear + '/' + m.hperiod)
                  ENDSCAN
               ENDIF

               *
               *  Process Plugging expenses
               *
               llroundit		= .F.
               lnExpensePlug	= 0
               IF (m.nPlugExp # 0 AND THIS.Well_Activity(.F., m.cWellID)) AND NOT m.ljib  AND m.nPlugPct # 0
                  lntotal = 0
                  SWSELECT('expense')
                  SCAN FOR cyear + cperiod = m.hyear + m.hperiod ;
                        AND IIF(EMPTY(m.csusptype), nrunnorev = THIS.nrunno, nrunnorev = m.nrunno_in) ;
                        AND IIF(EMPTY(m.csusptype), crunyearrev = THIS.crunyear, crunyearrev = m.crunyear_in) ;
                        AND dexpdate    <= THIS.dexpdate ;
                        AND cWellID      = m.cWellID   ;
                        AND cexpclass    = 'P'  ;
                        AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')

                     m.ccateg	= cCatCode + '-' + ALLTRIM(ccateg)
                     m.cCatCode	= cCatCode
                     m.namount	= namount
                     lcownerid	= cOwnerID
                     m.cexpclass	= cexpclass

                     *  Get the account numbers to post this expense to

                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdracct   = cownacctlistid
                     ELSE
                        m.cdracct   = lcSuspense
                     ENDIF

                     *  If the expcat field is blank, use the suspense account from glopt
                     IF EMPTY(ALLT(m.cdracct))
                        m.cdracct = lcSuspense
                     ENDIF

                     IF NOT EMPTY(lcownerid)           && Check for one-man items
                        IF lcownerid # m.cOwnerID
                           LOOP
                        ENDIF
                     ELSE
                        m.namount = ROUND(m.namount * (m.nPlugPct / 100), 2)
                     ENDIF

                     IF llround AND NOT llroundit
                        SELE roundtmp
                        REPL lused WITH .T.
                        m.namount = m.namount + roundtmp.nPlugExp
                        llroundit = .T.
                     ENDIF

                     lnExpensePlug = lnExpensePlug + m.namount

                     IF m.namount > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     m.namount = ROUND(m.namount, 2)

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(m.cdracct)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue(m.ccateg)


                     *  Post expense clearing entry
                     IF m.namount < 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                     ENDIF
                     IF NOT EMPTY(lcwelllistid)
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF

                     loentry.entityref.listid.setvalue(lcownlistid)
                     loentry.accountref.listid.setvalue(lcExpClear)
                     loentry.amount.setvalue(ABS(m.namount))
                     loentry.MEMO.setvalue('Plugging Expenses ' + m.hyear + '/' + m.hperiod)
                  ENDSCAN
               ENDIF
            ENDIF

            *
            *  Post Withholding Taxes
            *
            llroundit = .F.
            IF m.ntaxwith # 0
               SWSELECT('revcat')
               SET ORDER TO crevtype
               IF SEEK('STAX')
                  DO CASE
                     CASE m.ctypeinv = 'L'
                        lcoilacctd = ccracctnol
                     CASE m.ctypeinv = 'O'
                        lcoilacctd = ccracctnoo
                     CASE m.ctypeinv = 'W'
                        lcoilacctd = ccracctnow
                  ENDCASE
                  lcTaxDesc = ALLTRIM(crevdesc) + ' ' + m.hyear + '/' + m.hperiod

                  IF EMPTY(lcoilacctd)
                     lcoilacctd = lcSuspense
                  ENDIF

                  IF m.ntaxwith > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF

                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF

                  m.ntaxwith = ROUND(m.ntaxwith, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcoilacctd)
                  loentry.amount.setvalue(ABS(m.ntaxwith))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.ntaxwith < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev1o
                     loentry.accountref.listid.setvalue(m.ctaxacct1)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.ntaxwith))
                  loentry.MEMO.setvalue(lcTaxDesc)
               ELSE

                  lcTaxDesc = 'Withholding Taxes'

                  IF m.ntaxwith > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  m.ntaxwith = ROUND(m.ntaxwith, 2)
                  loentry.entityref.listid.setvalue(lcownlistid)
                  loentry.accountref.listid.setvalue(lcSuspense)
                  loentry.amount.setvalue(ABS(m.ntaxwith))
                  loentry.MEMO.setvalue(lcTaxDesc)

                  IF m.ntaxwith < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  IF NOT EMPTY(lcwelllistid)
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownlistid)
                  IF NOT m.lsev1o
                     loentry.accountref.listid.setvalue(m.ctaxacct1)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  loentry.amount.setvalue(ABS(m.ntaxwith))
                  loentry.MEMO.setvalue(lcTaxDesc)

               ENDIF
            ENDIF

            IF m.nincome = 0 AND m.nsevtaxes = 0
               IF (m.nexpense # 0 OR ;
                     m.ntotale1 # 0 OR ;
                     m.ntotale2 # 0 OR ;
                     m.ntotale3 # 0 OR ;
                     m.ntotale4 # 0 OR ;
                     m.ntotale5 # 0 OR ;
                     m.ntotalea # 0 OR ;
                     m.ntotaleb # 0 OR ;
                     m.nmktgexp # 0) AND m.ljib AND NOT THIS.Well_Activity(.F., m.cWellID)
                  THIS.oqbrequest.ClearRequests()
                  LOOP
               ELSE
                  IF m.nexpense = 0 AND ;
                        m.ntotale1 = 0 AND ;
                        m.ntotale2 = 0 AND ;
                        m.ntotale3 = 0 AND ;
                        m.ntotale4 = 0 AND ;
                        m.ntotale5 = 0 AND ;
                        m.ntotalea = 0 AND ;
                        m.ntotaleb = 0 AND ;
                        m.nmktgexp = 0 AND NOT THIS.Well_Activity(.F., m.cWellID)
                     THIS.oqbrequest.ClearRequests()
                     LOOP
                  ENDIF
               ENDIF
            ENDIF
            lcxml = THIS.oqbrequest.toxmlstring()
            THIS.SaveXML(m.cOwnerID, lcXML)


            loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
            IF VARTYPE(loresponse) = 'O'
               loaddresp  = loresponse.responselist.getat(0)


               IF loaddresp.statuscode # 0
                  IF 'object' $ LOWER(loaddresp.statusmessage)
                     lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
                     llResult = m.goapp.oQB.QBListID(lcListID)
                     IF llResult
                        SELECT QBListID
                        IF QBListID.ctype = 'Account'
                           lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                              'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                              'and try to post again.'
                        ELSE
                           IF 'Acct' $ QBListID.cdescription
                              lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                                 'Please choose a new account in ' + ALLTRIM(QBListID.ctype) + ' and try to post again.'
                           ELSE
                              lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                                 'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to post again.'
                           ENDIF
                        ENDIF
                        THIS.omessage.severe(lcMessage)
                     ELSE
                        THIS.omessage.severe(loaddresp.statusmessage)
                     ENDIF
                  ELSE
                     THIS.omessage.severe(loaddresp.statusmessage)
                  ENDIF
                     m.goapp.oQB.oqbsm.ClearErrorRecovery()
                  IF VARTYPE(THIS.oprogress) = 'O'
                     THIS.oprogress.closeprogress()
                  ENDIF
                  RETURN .F.
               ELSE
                  lonewbill = loaddresp.DETAIL
                  m.ctxnid  = lonewbill.txnid.getvalue()
                  SWSELECT('qbpost')
                  LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnJournal
                  IF NOT FOUND()
                     m.ntype	  = lnJournal
                     m.mtxnids = m.ctxnid
                     INSERT INTO qbpost FROM MEMVAR
                  ELSE
                     IF NOT EMPTY(ALLT(mtxnids))
                        REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
                     ELSE
                        REPL mtxnids WITH m.ctxnid
                     ENDIF
                  ENDIF
                  THIS.ClearErrorRecovery()
                  THIS.oqbrequest.ClearRequests()

               ENDIF
            ELSE
               THIS.ClearErrorRecovery()
               THIS.oqbrequest.ClearRequests()
            ENDIF
         ENDSCAN

         IF NOT THIS.lquiet
            IF VARTYPE(THIS.oprogress) = 'O'
               THIS.oprogress.closeprogress()
            ENDIF

            DOEVENTS
            THIS.oprogress = .NULL.
         ENDIF
      ENDFOR
   ENDIF
   ENDPROC


   ***************************
   PROCEDURE qbpostvendop
   ***************************
   LOCAL lnvendor, lnJournal

   lnvendor = 0

   * Set the correct txndeltype based on the sdk in use
   IF THIS.qbfcversion > QBFCVER
      lnJournal = 15
   ELSE
      lnJournal = 14
   ENDIF

   IF NOT USED('glopt')
      USE glopt IN 0
   ENDIF
   SELECT glopt
   lcRevClear = crevclear
   lcExpClear = cexpclear
   llQBPost	 = NOT ldmnopost
   lcSuspense = csuspense

   SWSELECT('options')
   GO TOP
   lcaracct	 = cjibacct
   llsepclose = .T.
   lcdmexp	 = cfixedacct

   SWSELECT('apopt')
   lcAPAcct   = cAPAcct

   IF EMPTY(lcdmexp)
      lcdmexp = lcAPAcct
   ENDIF

   * set the on error attribute for the request
   THIS.oqbrequest.ATTRIBUTES.OnError = 1

   * Clear any previous requests
   THIS.oqbrequest.ClearRequests()

   *
   *  Get the vendors to be posted.
   *
   SELECT cVendorID, cvendname, cListID FROM vendor WHERE linteggl = .T. INTO ARRAY lavends

   IF m.goapp.oQB.lqbactive AND llQBPost AND _TALLY > 0
      lnvends = ALEN(lavends, 1)
      IF lnvends > 0

         FOR lnx = 1 TO lnvends

            IF NOT THIS.lquiet
               THIS.oprogress = THIS.omessage.progressbarex('Posting vendor totals to income accounts...', lavends[lnX, 2])
            ENDIF
            m.cVendorID = lavends[lnX, 1]
            SELE expense
            COUNT FOR cVendorID = m.cVendorID AND nrunnorev = THIS.nrunno AND expense.crunyearrev = THIS.crunyear AND namount # 0 AND NOT expense.lAPTran TO lnexp
            IF lnexp > 0
               *  Setup the journal add request
               loentryadd = THIS.oqbrequest.appendjournalentryaddrq()
               loentryadd.txndate.setvalue(tdCompanyPost)
               loentryadd.refnumber.setvalue('DM-' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear)
            ENDIF

            lcvendorlistid = lavends[lnX, 3]
            lnamount		  = 0
            SWSELECT('expense')
            lncount = 1

            * Summarize by ccateg to cut down on journal entries
            SELECT  expense.cWellID, ;
               ccateg, ;
               cexpclass, ;
               cDeck, ;
               SUM(namount) AS namount, ;
               cVendorID, ;
               cCatCode, ;
               expense.cOwnerID, ;
               expense.cyear, ;
               expense.cperiod ;
               FROM expense, wells ;
               WHERE cVendorID = m.cVendorID ;
               AND nrunnorev = THIS.nrunno ;
               AND expense.crunyearrev = THIS.crunyear ;
               AND namount # 0 ;
               AND NOT expense.lAPTran ;
               AND expense.cWellID = wells.cWellID ;
               AND expense.cWellID IN (SELECT  cWellID ;
               FROM wellwork) ;
               INTO CURSOR tempexp ;
               ORDER BY cVendorID, expense.cWellID, ccateg, cexpclass, cDeck, expense.cOwnerID, expense.cyear, expense.cperiod ;
               GROUP BY cVendorID, expense.cWellID, ccateg, cexpclass, cDeck, expense.cOwnerID, expense.cyear, expense.cperiod
            SELECT tempexp
            COUNT FOR cVendorID = m.cVendorID TO lnmax
            IF NOT THIS.lquiet
               THIS.oprogress.setprogressrange(0, lnmax)
            ENDIF
            SELECT tempexp
            SCAN
               m.cWellID	  = tempexp.cWellID
               m.ccateg	  = tempexp.cCatCode + '-' + ALLTRIM(tempexp.ccateg) + ' ' + tempexp.cyear + '/' + tempexp.cperiod
               m.cexpclass = tempexp.cexpclass
               m.cOwnerID  = tempexp.cOwnerID
               m.namount	  = tempexp.namount
               m.cunitno	  = tempexp.cWellID
               m.cid		  = tempexp.cVendorID
               m.cvendname = lavends[lnX, 2]
               m.cCatCode  = tempexp.cCatCode
               m.cDeck     = tempexp.cDeck

               *
               * Update the progress counter
               *
               IF NOT THIS.lquiet
                  THIS.oprogress.updateprogress(lncount)
                  lncount = lncount + 1
               ENDIF

               *
               *  Check to make sure the well is in the right group
               *
               SWSELECT('wells')
               SET ORDER TO cWellID
               IF SEEK(m.cWellID)
                  IF wells.cgroup # tcgroup
                     LOOP
                  ENDIF
                  lcwelllistid = cListID
                  IF EMPTY(wells.cListID)
                     MESSAGEBOX('The wells file needs to be synchronized with QuickBooks. ' + ;
                        'please synchronize and then close the revenue period again.', 0, 'Synchronization Problem')
                     RETURN .F.
                  ENDIF
                  llvalidwell = .T.
               ELSE
                  llvalidwell = .F.
               ENDIF

               *
               *  Get the account numbers to be posted for this expense category
               *
               SWSELECT('expcat')
               SET ORDER TO cCatCode
               IF SEEK(m.cCatCode)
                  m.cvendacctlistid = cvendacctlistid
               ELSE
                  LOOP
               ENDIF

               IF NOT '-' $ m.cvendacctlistid
                  m.cvendacctlistid = lcSuspense
               ENDIF

               *
               *  Net out any JIB and "Dummy" interest shares from the expense
               *
               m.namount   = SWNETEXP(m.namount, m.cWellID, .T., m.cexpclass, 'N', .F., m.cOwnerID, '', m.cDeck)

               *
               *  Add amount of this invoice to the total the vendor is to be paid
               *
               lnamount = ROUND(lnamount + m.namount, 2)

               IF m.namount # 0
                  IF m.namount < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  m.namount = ROUND(m.namount, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcvendorlistid)
                  loentry.accountref.listid.setvalue(m.cvendacctlistid)
                  loentry.amount.setvalue(ABS(m.namount))
                  loentry.MEMO.setvalue(m.ccateg)
               ENDIF
            ENDSCAN

            IF lnamount = 0
               THIS.oqbrequest.ClearRequests()
            ENDIF
            IF lnexp > 0
               IF lnamount # 0
                  IF lnamount > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                  ENDIF
                  loentry.entityref.listid.setvalue(lcvendorlistid)
                  loentry.accountref.listid.setvalue(lcdmexp)
                  loentry.amount.setvalue(ABS(lnamount))
                  loentry.MEMO.setvalue('Vendor Posting')


                  lcxml		= THIS.oqbrequest.toxmlstring()
                  THIS.SaveXML(m.cOwnerID, lcXML)
                  loresponse	= THIS.oqbsm.dorequests(THIS.oqbrequest)
                  loaddresp	= loresponse.responselist.getat(0)

                  IF loaddresp.statuscode # 0
                     IF 'object' $ LOWER(loaddresp.statusmessage)
                        lcListID	= SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
                        llResult	= m.goapp.oQB.QBListID(lcListID)
                        IF llResult
                           SELECT QBListID
                           IF QBListID.ctype = 'Account'
                              lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                                 'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                                 'and try to post again.'
                           ELSE
                              IF 'Acct' $ QBListID.cdescription
                                 lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                                    'Please choose a new account in ' + ALLTRIM(QBListID.ctype) + ' and try to post again.'
                              ELSE
                                 lcMessage = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                                    'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to post again.'
                              ENDIF
                           ENDIF
                           THIS.omessage.severe(lcMessage)
                        ELSE
                           THIS.omessage.severe(loaddresp.statusmessage)
                        ENDIF
                     ELSE
                        THIS.omessage.severe(loaddresp.statusmessage)
                     ENDIF

                     m.goapp.oQB.oqbsm.ClearErrorRecovery()
                     IF VARTYPE(THIS.oprogress) = 'O'
                        THIS.oprogress.closeprogress()
                     ENDIF
                     RETURN .F.
                  ELSE
                     lonewbill = loaddresp.DETAIL
                     m.ctxnid  = lonewbill.txnid.getvalue()
                     SWSELECT('qbpost')
                     LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnJournal
                     IF NOT FOUND()
                        m.ntype	 = lnJournal
                        m.mtxnids = m.ctxnid
                        INSERT INTO qbpost FROM MEMVAR
                     ELSE
                        IF NOT EMPTY(ALLT(mtxnids))
                           REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
                        ELSE
                           REPL mtxnids WITH m.ctxnid
                        ENDIF
                     ENDIF
                     THIS.oqbrequest.ClearRequests()

                     THIS.ClearErrorRecovery()
                  ENDIF
               ENDIF  && lnAmount <> 0

            ENDIF  && lnExp > 0

            IF NOT THIS.lquiet
               IF VARTYPE(THIS.oprogress) = 'O'
                  THIS.oprogress.closeprogress()
               ENDIF

               DOEVENTS
               THIS.oprogress = .NULL.
            ENDIF
         ENDFOR
      ENDIF
   ENDIF
   ENDPROC

   ***************************
   PROCEDURE qbunpostrev
   ***************************
   LPARAMETERS tlError
   LOCAL lnJournal, lnCheck, lnInvoice

   * tlError = .t. - called from error_recovery method

   IF NOT THIS.lqbactive
      RETURN
   ENDIF

   * Check to see if we're in error recovery status and clear
   THIS.check_error_recovery()

   m.cidsysctl = THIS.csysctlkey
   * set the on error attribute for the request
   THIS.oqbrequest.ATTRIBUTES.OnError = 1

   * Clear any previous requests
   THIS.oqbrequest.ClearRequests()

   * Choose the correct txndeltype depending on the SDK.
   * Why they changed these constants is beyond me.
   IF THIS.qbfcversion > QBFCVER
      lnJournal = 15
      lnCheck   = 6
      lnInvoice = 13
   ELSE
      lnJournal = 14
      lnCheck   = 11
      lnInvoice = 0
   ENDIF

   IF tlError
      WAIT WIND NOWAIT 'Removing partial revenue posting records...Please wait'
   ELSE
      WAIT WIND NOWAIT 'Deleting QuickBooks Journal Entries For Revenue Closing...'
   ENDIF
   SWSELECT('qbpost')
   SCAN FOR cidsysctl = m.cidsysctl AND ntype = lnJournal
      lcTxnIDs = mtxnids
      lncount  = ALINES(laTxnid, lcTxnIDs)
      IF lncount > 0
         FOR lnx = 1 TO lncount
            lcTxnID		= PADR(ALLT(laTxnid[lnX]), 36, ' ')
            loJournalDel	= THIS.oqbrequest.AppendTxnDelRq()
            loJournalDel.TxnDelType.setvalue(lnJournal)
            loJournalDel.txnid.setvalue(lcTxnID)

            loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
            loDelResp  = loresponse.responselist.getat(0)
            THIS.ClearErrorRecovery()
            THIS.oqbrequest.ClearRequests()
         ENDFOR
      ENDIF
      SELECT qbpost
      DELETE NEXT 1
   ENDSCAN
   IF NOT tlError
      WAIT WIND NOWAIT 'Deleting QuickBooks Checks For Revenue Closing...'
   ENDIF
   SWSELECT('qbpost')
   SCAN FOR cidsysctl = m.cidsysctl AND ntype = lnCheck
      lcTxnIDs = mtxnids
      lncount  = ALINES(laTxnid, lcTxnIDs)
      IF lncount > 0
         FOR lnx = 1 TO lncount
            lcTxnID		= PADR(ALLT(laTxnid[lnX]), 36, ' ')
            loJournalDel	= THIS.oqbrequest.AppendTxnDelRq()
            loJournalDel.TxnDelType.setvalue(lnCheck)
            loJournalDel.txnid.setvalue(lcTxnID)

            loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
            loDelResp  = loresponse.responselist.getat(0)
            THIS.ClearErrorRecovery()
            THIS.oqbrequest.ClearRequests()
         ENDFOR
      ENDIF
      SELECT qbpost
      DELETE NEXT 1
   ENDSCAN
   IF NOT tlError
      WAIT WIND NOWAIT 'Deleting QuickBooks Invoices For Revenue Closing...'
   ENDIF
   SWSELECT('qbpost')
   SCAN FOR cidsysctl = m.cidsysctl AND ntype = lnInvoice
      lcTxnIDs = mtxnids
      lncount  = ALINES(laTxnid, lcTxnIDs)
      IF lncount > 0
         FOR lnx = 1 TO lncount
            lcTxnID		= PADR(ALLT(laTxnid[lnX]), 36, ' ')
            loJournalDel	= THIS.oqbrequest.AppendTxnDelRq()
            loJournalDel.TxnDelType.setvalue(lnInvoice)
            loJournalDel.txnid.setvalue(lcTxnID)

            loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
            loDelResp  = loresponse.responselist.getat(0)
            THIS.ClearErrorRecovery()
            THIS.oqbrequest.ClearRequests()
         ENDFOR
      ENDIF
      SELECT qbpost
      DELETE NEXT 1
   ENDSCAN
   WAIT CLEAR
   ENDPROC


   ***************************
   PROCEDURE qbunpostjib
   ***************************
   LPARAMETERS tlError
   LOCAL lnJournal, lnCheck, lnInvoice, lnCreditMemo
   *
   * tlError = .T. - the routine has been called by
   *                 the initial connection to QB
   *                 to unpost any partial jib postings
   *
   IF NOT THIS.lqbactive
      RETURN
   ENDIF

   * Choose the correct txndeltype depending on the SDK.
   IF THIS.qbfcversion > QBFCVER
      lnJournal	  = 15
      lnCheck	  = 6
      lnInvoice	  = 13
      lnCreditMemo = 9
   ELSE
      lnJournal	  = 14
      lnCheck	  = 11
      lnInvoice	  = 0
      lnCreditMemo = 3
   ENDIF


   SWSELECT('qbpost')
   m.cidsysctl = THIS.csysctlkey
   *  Get a message set request object (version 3.0 xml)
   lorequest = THIS.oqbrequest

   * set the on error attribute for the request
   lorequest.ATTRIBUTES.OnError = 1

   IF tlError
      WAIT WIND NOWAIT 'Removing partial JIB posting records...Please wait'
   ELSE
      WAIT WIND NOWAIT 'Deleting QuickBooks Journal Entries For JIB Closing...'
   ENDIF
   SWSELECT('qbpost')
   SCAN FOR cidsysctl = m.cidsysctl AND ntype = lnJournal
      lcTxnIDs = mtxnids
      lncount  = ALINES(laTxnid, lcTxnIDs)
      IF lncount > 0
         FOR lnx = 1 TO lncount
            lcTxnID		= PADR(ALLT(laTxnid[lnX]), 36, ' ')
            loJournalDel	= lorequest.AppendTxnDelRq()
            loJournalDel.TxnDelType.setvalue(lnJournal)
            loJournalDel.txnid.setvalue(lcTxnID)

            loresponse = THIS.oqbsm.dorequests(lorequest)
            loDelResp  = loresponse.responselist.getat(0)
            THIS.ClearErrorRecovery()
            lorequest.ClearRequests()
         ENDFOR
      ENDIF
      SELECT qbpost
      DELETE NEXT 1
   ENDSCAN
   IF NOT tlError
      WAIT WIND NOWAIT 'Deleting QuickBooks JIB Invoices...'
   ENDIF
   SWSELECT('qbpost')
   SCAN FOR cidsysctl = m.cidsysctl AND ntype = lnInvoice
      lcTxnIDs = mtxnids
      lncount  = ALINES(laTxnid, lcTxnIDs)
      IF lncount > 0
         FOR lnx = 1 TO lncount
            lcTxnID		= PADR(ALLT(laTxnid[lnX]), 36, ' ')
            loJournalDel	= lorequest.AppendTxnDelRq()
            loJournalDel.TxnDelType.setvalue(lnInvoice)
            loJournalDel.txnid.setvalue(lcTxnID)

            loresponse = THIS.oqbsm.dorequests(lorequest)
            loDelResp  = loresponse.responselist.getat(0)
            THIS.ClearErrorRecovery()
            lorequest.ClearRequests()
         ENDFOR
      ENDIF
      SELECT qbpost
      DELETE NEXT 1
   ENDSCAN
   IF NOT tlError
      WAIT WIND NOWAIT 'Deleting QuickBooks Checks FOR JIB Closing...'
   ENDIF
   SWSELECT('qbpost')
   SCAN FOR cidsysctl = m.cidsysctl AND ntype = lnCheck
      lcTxnIDs = mtxnids
      lncount  = ALINES(laTxnid, lcTxnIDs)
      IF lncount > 0
         FOR lnx = 1 TO lncount
            lcTxnID		= PADR(ALLT(laTxnid[lnX]), 36, ' ')
            loJournalDel	= lorequest.AppendTxnDelRq()
            loJournalDel.TxnDelType.setvalue(lnCheck)
            loJournalDel.txnid.setvalue(lcTxnID)

            loresponse = THIS.oqbsm.dorequests(lorequest)
            loDelResp  = loresponse.responselist.getat(0)
            THIS.ClearErrorRecovery()
            lorequest.ClearRequests()
         ENDFOR
      ENDIF
      SELECT qbpost
      DELETE NEXT 1
   ENDSCAN

   WAIT CLEAR
   ENDPROC

   ***************************
   PROCEDURE QBVersionChk
   ***************************

   loReg = NEWOBJECT('Registry', HOME() + 'FFC\Registry.VCX')

   lcKey10 = "SOFTWARE\Intuit\QuickBooks\10.0"
   lcKey12 = "SOFTWARE\Intuit\QuickBooks\12.0"
   lcKey13 = "SOFTWARE\Intuit\QuickBooks\13.0"
   lcKey15 = "SOFTWARE\Intuit\QuickBooks\15.0"
   lcKey16 = "SOFTWARE\Intuit\QuickBooks\16.0"
   lcKey17 = "SOFTWARE\Intuit\QuickBooks\17.0"
   lcKey18 = "SOFTWARE\Intuit\QuickBooks\18.0"
   lcKey19 = "SOFTWARE\Intuit\QuickBooks\19.0"
   lcKey20 = "SOFTWARE\Intuit\QuickBooks\20.0"
   lcKey21 = "SOFTWARE\Intuit\QuickBooks\21.0"
   lcKey22 = "SOFTWARE\Intuit\QuickBooks\22.0"
   lcKey23 = "SOFTWARE\Intuit\QuickBooks\23.0"
   lcKey24 = "SOFTWARE\Intuit\QuickBooks\24.0"

   lcPath = ADDBS(specialfolders("CommonDocuments")) + 'Intuit\QuickBooks\Company Files'

   * Changed to only have one QB sample file built for QB 2011 - pws 11/21/13

   m.goapp.cQBCompany = lcPath + '\SherWare Sample Company.qbw'

   *!*         DO CASE
   *!*            CASE loReg.iskey(lcKey23,HKEY_LOCAL_MACHINE)
   *!*               m.goapp.cQBCompany = lcPath + '\datafiles\2013 Sample Company.qbw'
   *!*
   *!*            CASE loReg.iskey(lcKey22,HKEY_LOCAL_MACHINE)
   *!*               m.goapp.cQBCompany = lcPath + '\datafiles\2012 Sample Company.qbw'
   *!*
   *!*            CASE loReg.iskey(lcKey21,HKEY_LOCAL_MACHINE)
   *!*               m.goapp.cQBCompany = lcPath + '\datafiles\2011 Sample Company.qbw'
   *!*
   *!*            CASE loReg.iskey(lcKey20,HKEY_LOCAL_MACHINE)
   *!*               m.goapp.cQBCompany = lcPath + '\datafiles\2010 Sample Company.qbw'
   *!*
   *!*            CASE loReg.iskey(lcKey19,HKEY_LOCAL_MACHINE)
   *!*               m.goapp.cQBCompany = lcPath + '\datafiles\2009 Sample Company.qbw'

   *!*            CASE loReg.iskey(lcKey18,HKEY_LOCAL_MACHINE)
   *!*               m.goapp.cQBCompany = lcPath + '\datafiles\2008 Sample Company.qbw'

   *!*            CASE loReg.iskey(lcKey17,HKEY_LOCAL_MACHINE)
   *!*               m.goapp.cQBCompany = lcPath + '\datafiles\2007 Sample Company.qbw'

   *!*            CASE loReg.iskey(lcKey16,HKEY_LOCAL_MACHINE)
   *!*               m.goapp.cQBCompany = lcPath + '\datafiles\2006 Sample Company.qbw'

   *!*            OTHERWISE
   *!*               m.goapp.cQBCompany = lcPath + '\datafiles\2009 Sample Company.qbw'

   *!*         ENDCASE
   ENDPROC

   ***************************
   PROCEDURE qbacct_validate
   ***************************
   LPARAMETERS tcListID

   *
   * Validates the list id passed by looking it up
   * in the accounts table to see if it is a valid account
   * listid.
   *
   lnDatasession = SET('datasession')

   IF VARTYPE(tcListID) # 'C'
      RETURN .F.
   ENDIF

   IF NOT USED('accounts')
      THIS.QBAccounts('*', .F., .T., lnDatasession)
   ENDIF

   SELECT accounts
   SET ORDER TO cListID
   IF SEEK(tcListID)
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF

   ***************************
   PROCEDURE QBAccounts
   ***************************
   LPARA tcAccount, tlDescOnly, tlCursorOnly, tnDataSession
   LOCAL loAcctQuery, loresponse, loAcctResp, loAcct, llAccounts

   lnDatasession = SET('datasession')

   IF tlCursorOnly
      IF TYPE('tnDataSession') = 'N'
         TRY
            SET DATASESSION TO (tnDataSession)
         CATCH TO loError
         ENDTRY
      ENDIF
   ENDIF

   * create output cursors
   CREATE CURSOR accounts (cAcctDesc c(60), cListID c(36), cAcctType c(25), cacctno c(7), nListOrder I)
   INDEX ON nListOrder TAG nListOrder
   INDEX ON cListID    TAG cListID
   INDEX ON cAcctDesc TAG cAcctDesc
   INDEX ON cAcctType TAG cAcctType

   *  If QuickBooks interface is not active return asterisks
   IF NOT m.goapp.oQB.lqbactive
      RETURN '******'
   ENDIF

   THIS.ClearErrorRecovery()
   THIS.oqbsm.EnableErrorRecovery = .F.

   THIS.oqbrequest.ClearRequests()

   * Get the account number preference from QB to see if we need to include the account numbers
   THIS.oqbrequest.ATTRIBUTES.OnError = 1

   llAccounts = .F.
   TRY
   lopref = THIS.oqbrequest.AppendPreferencesQueryrq()

   loresponslist	= THIS.oqbsm.dorequests(THIS.oqbrequest)
   loresponse	= loresponslist.responselist.getat(0)

   lopreferences	= loresponse.DETAIL
   llAccounts	= lopreferences.accountingpreferences.isusingaccountnumbers.getvalue()
   CATCH TO loerr
   ENDTRY

   THIS.oqbrequest.ClearRequests()

   * add a customer query request to request message set
   loAcctQuery = THIS.oqbrequest.AppendAccountQueryRq()

   * add a filter to the customer request to only pick up active customers
   loAcctQuery.ORAccountListQuery.AccountListFilter.ActiveStatus.SetAsString('ActiveOnly')
   loAcctQuery.IncludeRetElementList.ADD('ListID')
   loAcctQuery.IncludeRetElementList.ADD('Name')
   loAcctQuery.IncludeRetElementList.ADD('AccountType')
   loAcctQuery.IncludeRetElementList.ADD('AccountNumber')

   * process the request object returning a response message object
   loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)

   * get reference to all responses in response message object,
   * these will each be collections of customer/employee/vendor ret objects
   loAcctResp = loresponse.responselist.getat(0)

   * display status code and message on screen
   *!*    ? "Account Query Response Status: "
   *!*    ? loAcctResp.StatusCode
   *!*    ? loAcctResp.StatusMessage

   * loop through the collection of account ret objects
   * 0 based array
   IF loAcctResp.statuscode = 0
      FOR lni = 0 TO loAcctResp.DETAIL.COUNT - 1

         * get reference to single Acctomer
         loAcct = loAcctResp.DETAIL.getat(lni)

         * get reference to listid
         m.cListID = loAcct.listid.getvalue()

         * get the value of the fullname tag
         TRY
            lcFullName = loAcct.NAME.getvalue()
         CATCH
            lcFullName = 'Unknown'
         ENDTRY

         * get the account type
         lnType = loAcct.AccountType.getvalue()

         * get the account number
         IF llAccounts
            IF VARTYPE(loAcct.accountnumber) = 'O'
               lcAcctNo = loAcct.accountnumber.getvalue()
            ELSE
               lcAcctNo = ' '
            ENDIF
         ELSE
            lcAcctNo = ' '
         ENDIF

         IF THIS.qbfcversion > QBFCVER
            DO CASE
               CASE lnType = 0
                  lcType		  = 'Accounts Payable'
                  m.nListOrder = 4
               CASE lnType = 1
                  lcType		  = 'Accounts Receivable'
                  m.nListOrder = 1
               CASE lnType = 2
                  lcType		  = 'Bank'
                  m.nListOrder = 1
               CASE lnType = 3
                  lcType		  = 'Cost of Goods Sold'
                  m.nListOrder = 9
               CASE lnType = 4
                  lcType		  = 'Credit Card'
                  m.nListOrder = 6
               CASE lnType = 5
                  lcType		  = 'Equity'
                  m.nListOrder = 7
               CASE lnType = 6
                  lcType		  = 'Expense'
                  m.nListOrder = 10
               CASE lnType = 7
                  lcType		  = 'Fixed Asset'
                  m.nListOrder = 3
               CASE lnType = 8
                  lcType		  = 'Income'
                  m.nListOrder = 8
               CASE lnType = 9
                  lcType		  = 'Long Term Liability'
                  m.nListOrder = 5
               CASE lnType = 11
                  lcType		  = 'Other Asset'
                  m.nListOrder = 2
               CASE lnType = 12
                  lcType		  = 'Other Current Asset'
                  m.nListOrder = 2
               CASE lnType = 13
                  lcType		  = 'Other Current Liability'
                  m.nListOrder = 6
               CASE lnType = 14
                  lcType		  = 'Other Expense'
                  m.nListOrder = 14
               CASE lnType = 15
                  lcType		  = 'Other Income'
                  m.nListOrder = 13
               CASE lnType = 10
                  lcType		  = 'Non-Posting'
                  m.nListOrder = 15
            ENDCASE
         ELSE
            DO CASE
               CASE lnType = 0
                  lcType		  = 'Accounts Payable'
                  m.nListOrder = 4
               CASE lnType = 1
                  lcType		  = 'Accounts Receivable'
                  m.nListOrder = 1
               CASE lnType = 2
                  lcType		  = 'Bank'
                  m.nListOrder = 1
               CASE lnType = 3
                  lcType		  = 'Cost of Goods Sold'
                  m.nListOrder = 9
               CASE lnType = 4
                  lcType		  = 'Credit Card'
                  m.nListOrder = 6
               CASE lnType = 5
                  lcType		  = 'Equity'
                  m.nListOrder = 7
               CASE lnType = 6
                  lcType		  = 'Expense'
                  m.nListOrder = 10
               CASE lnType = 7
                  lcType		  = 'Fixed Asset'
                  m.nListOrder = 3
               CASE lnType = 8
                  lcType		  = 'Income'
                  m.nListOrder = 8
               CASE lnType = 9
                  lcType		  = 'Long Term Liability'
                  m.nListOrder = 5
               CASE lnType = 10
                  lcType		  = 'Other Asset'
                  m.nListOrder = 2
               CASE lnType = 11
                  lcType		  = 'Other Current Asset'
                  m.nListOrder = 2
               CASE lnType = 12
                  lcType		  = 'Other Current Liability'
                  m.nListOrder = 6
               CASE lnType = 13
                  lcType		  = 'Other Expense'
                  m.nListOrder = 14
               CASE lnType = 14
                  lcType		  = 'Other Income'
                  m.nListOrder = 13
               CASE lnType = 15
                  lcType		  = 'Non-Posting'
                  m.nListOrder = 15
            ENDCASE
         ENDIF

         * insert into cursor
         INSERT INTO accounts VALUES (lcFullName, m.cListID, lcType, lcAcctNo, m.nListOrder)

      ENDFOR
   ENDIF

   THIS.oqbsm.EnableErrorRecovery = .T.

   * Clear this request
   THIS.oqbrequest.ClearRequests()

   IF NOT tlDescOnly AND NOT tlCursorOnly
      * Bring up the picklist
      SELECT accounts
      IF RECCOUNT() # 0
         PRIVATE llok
         LOCAL lclist

         llok = .F.

         lclist = 'cacctdesc\Account Description,cAcctType\Account Type'

         DO FORM picklist WITH 'Accounts', lclist, tcAccount, 2, .T., .T.

         lcListID = accounts.cListID

         TRY
            SET DATASESSION TO (lnDatasession)
         CATCH TO loError
         ENDTRY

         IF llok
            RETURN lcListID
         ELSE
            RETURN tcAccount
         ENDIF
      ENDIF
   ELSE
      IF tlDescOnly
         SELE accounts
         LOCATE FOR cacctno = tcAccount
         IF FOUND()
            lcListID = accounts.cAcctDesc
            TRY
               SET DATASESSION TO (lnDatasession)
            CATCH TO loError
            ENDTRY
            RETURN lcListID
         ELSE
            TRY
               SET DATASESSION TO (lnDatasession)
            CATCH TO loError
            ENDTRY
            RETURN 'Not Found'
         ENDIF
      ELSE
         RETURN ''
      ENDIF
   ENDIF
   ENDPROC


   ***************************
   PROCEDURE qbitems
   ***************************
   LPARA tnDataSession
   LOCAL loitemquery, loresponse, loitemresp, loitem, lnDatasession

   lnDatasession = SET('Datasession')

   IF TYPE('tnDataSession') = 'N'
      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH TO loError
      ENDTRY
   ELSE
      THIS.omessage.severe('Bad datasession passed to qbitems.')
      RETURN
   ENDIF

   * create output cursors
   CREATE CURSOR qbitems (citemid c(31), cListID c(36))
   INDEX ON citemid TAG citemid

   *  If QuickBooks interface is not active return asterisks
   IF NOT THIS.lqbactive
      RETURN '******'
   ENDIF

   THIS.ClearErrorRecovery()
   THIS.oqbrequest.ClearRequests()
   THIS.oqbsm.EnableErrorRecovery = .F.

   TRY
      * add a non inventory query request to request message set
      loitemquery = THIS.oqbrequest.appenditemnoninventoryqueryrq()

      * add a filter to the item request to only pick up active items
      IF THIS.qbfcversion > ' 7.0'
         loitemquery.ORListQueryWithOwnerIDAndClass.ListWithClassFilter.ActiveStatus.SetAsString('ActiveOnly')
      ELSE
         loitemquery.orlistquery.listfilter.ActiveStatus.SetAsString('ActiveOnly')
      ENDIF

      * process the request object returning a response message object
      loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)

      * get reference to all responses in response message object,
      * these will each be collections of customer/employee/vendor ret objects
      loitemresp = loresponse.responselist.getat(0)

      * loop through the collection of item ret objects
      * 0 based array
      IF loitemresp.statuscode = 0
         FOR lni = 0 TO loitemresp.DETAIL.COUNT - 1

            * get reference to single Acctomer
            loitem = loitemresp.DETAIL.getat(lni)

            * get reference to listid
            m.cListID = loitem.listid.getvalue()

            * get the value of the name tag
            lcitemid = loitem.NAME.getvalue()

            * insert into cursor
            INSERT INTO qbitems VALUES (lcitemid, m.cListID)

         ENDFOR
      ENDIF
   CATCH
   ENDTRY
   THIS.oqbsm.EnableErrorRecovery = .T.
   ENDPROC

   ***************************
   FUNCTION create_qbbadnames
   ***************************
   LPARAMETERS tnDataSession

   IF VARTYPE(tnDataSession) = 'N'
      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH
      ENDTRY
   ENDIF

   CREATE CURSOR qbbadnames ;
      (cid    c(10), ;
      cname  c(40), ;
      ctype  c(15), ;
      cmessage m, ;
      nqberror I)

   ***************************
   PROCEDURE sync_expcat
   ***************************
   LPARAMETERS tnDataSession, tlNewOnly
   LOCAL lnDatasession, llError, llSyncError

   * Initialize the error flags
   STORE .F. TO llError, llSyncError

   TRY
      IF VARTYPE(tnDataSession) # 'N'
         tnDataSession = 1
      ENDIF

      lnDatasession = SET('DataSession')

      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH TO loError
      ENDTRY


      IF NOT USED('qbbadnames')
         THIS.create_qbbadnames()
      ENDIF

      #DEFINE qbFileOpenSingleUser  0
      #DEFINE qbFileOpenMultiUser   1
      #DEFINE qbFileOpenDoNotCare   2
      #DEFINE qbStopOnError         0
      #DEFINE qbContinueOnError     1

      IF NOT THIS.lqbactive
         llreturn = .F.
         EXIT
      ENDIF

      THIS.oqbsm.EnableErrorRecovery = .F.

      LOCAL loitemadd AS 'QBFC7.iitemserviceadd'
      LOCAL loitemlist AS 'qbfc7.iitemserviceretlist'
      LOCAL loitem AS 'qbfc7.iitemserviceret'
      LOCAL loresponsemsg AS 'qbfc7.imsgsetresponse'
      LOCAL loresponselist AS 'qbfc7.iresponselist'
      LOCAL loresponse AS 'qbfc7.iresponse'
      LOCAL loitemmod AS 'qbfc7.iitemservicemod'


      * get a message set request object (version 1.1 xml)
      lorequest = THIS.oqbrequest

      * set the on error attribute for the request
      lorequest.ATTRIBUTES.OnError = 1

      lorequest.ClearRequests()

      SWSELECT('glopt')
      GO TOP
      lcExpClear = cexpclear

      IF EMPTY(lcExpClear)
         MESSAGEBOX('The expense clearing account has not been specified in the Account Settings.  Synchronization may not be successful.', 0, 'Setup Error')
      ENDIF

      SWSELECT('expcat')

      CREATE CURSOR qbitems (ccateg  c(31), cListID c(36), ceditseq c(16), lused L)
      CREATE CURSOR badstatus (cCatCode  c(4), nstatus I)

      WAIT WIND NOWAIT 'Synchronizing expense categories with QuickBooks item file ...Please Wait'

      *
      * Get the full list of items to compare expense categories against
      *

      * add an item query request to request message set
      loitemservicequery = lorequest.appenditemservicequeryrq()

      * process the request object returning a response message object
      loresponsemsg = THIS.oqbsm.dorequests(lorequest)
      loresponse	   = loresponsemsg.responselist.getat(0)

      IF loresponse.statuscode = 0
         * Scan through the list to build the cursor
         loitemlist = loresponse.DETAIL
         FOR lnx = 0 TO loitemlist.COUNT - 1
            loitem	  = loitemlist.getat(lnx)
            m.cListID  = loitem.listid.getvalue()
            m.ceditseq = loitem.editsequence.getvalue()
            m.ccateg	  = loitem.NAME.getvalue()
            INSERT INTO qbitems FROM MEMVAR
         ENDFOR
      ENDIF
      lorequest.ClearRequests()
      lorequest.ATTRIBUTES.OnError = 1

      SWSELECT('expcat')
      SET ORDER TO cCatCode
      SCAN FOR NOT DELETED() AND IIF(tlNewOnly, EMPTY(cListID), .T.)
         SCATTER MEMVAR
         * Fix invalid category names
         IF '&' $ m.ccateg
            m.ccateg = STRTRAN(m.ccateg, '&', 'and')
            REPL ccateg WITH m.ccateg
         ENDIF
         IF ':' $ m.ccateg
            m.ccateg = STRTRAN(m.ccateg, ':', '-')
            REPL ccateg WITH m.ccateg
         ENDIF

         * Insert the cat code into the category name to make it unique
         m.ccateg = m.cCatCode + '-' + ALLTRIM(m.ccateg)

         * Empty listid so it must be a new listid
         IF EMPTY(m.cListID)
            * Clear inquiry request
            SELECT qbitems
            LOCATE FOR ccateg = m.ccateg AND lused = .F.
            IF FOUND()
               REPLACE lused WITH .T.
               SWSELECT('expcat')
               REPLACE cListID WITH qbitems.cListID
            ELSE
               lorequest.ClearRequests()
               loitemadd = lorequest.appenditemserviceaddrq()
               loitemadd.NAME.setvalue(PADR(ALLTRIM(m.ccateg), 31, ' '))
               loitemadd.orsalespurchase.salesorpurchase.accountref.listid.setvalue(lcExpClear)
               loitemadd.orsalespurchase.salesorpurchase.DESC.setvalue(m.cdescrip)
               loresponse = THIS.oqbsm.dorequests(lorequest)
               loitemresp = loresponse.responselist.getat(0)

               IF loitemresp.statuscode = 0
                  WAIT WIND NOWAIT 'Item: ' + ALLT(m.ccateg) + ' was added to QuickBooks successfully as an Item.'
                  lonewitem = loitemresp.DETAIL
                  m.cListID = lonewitem.listid.getvalue()
                  SELECT expcat
                  REPLACE cListID WITH m.cListID
               ELSE
                  WAIT WIND NOWAIT 'Item: ' + ALLT(m.ccateg) + ' was NOT added successfully. Code: ' + STR(loitemresp.statuscode)
                  m.cid		= m.cCatCode
                  m.cname	= m.ccateg
                  m.ctype	= 'Exp Cat'
                  m.cmessage	= loitemresp.statusmessage
                  m.nqberror	= loitemresp.statuscode
                  INSERT INTO qbbadnames FROM MEMVAR
               ENDIF
            ENDIF
         ELSE
            SELECT qbitems
            LOCATE FOR cListID == m.cListID
            IF FOUND()
               REPLACE lused WITH .T.
               lorequest.ClearRequests()
               loitemmod = lorequest.appenditemservicemodrq()
               loitemmod.editsequence.setvalue(qbitems.ceditseq)
               loitemmod.NAME.setvalue(PADR(ALLTRIM(m.ccateg), 31, ' '))
               loitemmod.listid.setvalue(m.cListID)
               loitemmod.ORSalesPurchaseMod.SalesOrPurchaseMod.DESC.setvalue(m.cdescrip)
               IF THIS.qbfcversion > ' 6.0'
                  loitemmod.ORSalesPurchaseMod.SalesOrPurchaseMod.accountref.listid.setvalue(lcExpClear)
               ENDIF
               loresponse = THIS.oqbsm.dorequests(lorequest)
               loitemresp = loresponse.responselist.getat(0)
               IF loitemresp.statuscode = 0
                  WAIT WINDOW NOWAIT 'Item: ' + ALLTRIM(m.ccateg) + ' was successfully modified in QuickBooks'
               ELSE
                  WAIT WINDOW NOWAIT 'Item: ' + ALLTRIM(m.ccateg) + ' was NOT successfully modified in QuickBooks. Code: ' + STR(loitemresp.statuscode)
                  SWSELECT('expcat')
                  REPLACE cListID WITH ''
                  m.cid		= m.cCatCode
                  m.cname	= m.ccateg
                  m.ctype	= 'Exp Cat'
                  m.cmessage	= loitemresp.statusmessage
                  m.nqberror	= loitemresp.statuscode
                  INSERT INTO qbbadnames FROM MEMVAR
               ENDIF
            ELSE
               SELECT qbitems
               LOCATE FOR ccateg = m.ccateg
               IF FOUND()
                  SWSELECT('expcat')
                  REPLACE cListID WITH qbitems.cListID
               ELSE
                  lorequest.ClearRequests()
                  loitemadd = lorequest.appenditemserviceaddrq()
                  loitemadd.NAME.setvalue(PADR(ALLTRIM(m.ccateg), 31, ' '))
                  loitemadd.orsalespurchase.salesorpurchase.accountref.listid.setvalue(lcExpClear)
                  loitemadd.orsalespurchase.salesorpurchase.DESC.setvalue(m.cdescrip)
                  loresponse	= THIS.oqbsm.dorequests(lorequest)
                  loitemresp	= loresponse.responselist.getat(0)

                  IF loitemresp.statuscode = 0
                     WAIT WIND NOWAIT 'Item: ' + ALLT(m.ccateg) + ' was added to QuickBooks successfully as an Item.'
                     lonewitem = loitemresp.DETAIL
                     m.cListID = lonewitem.listid.getvalue()
                     SELECT expcat
                     REPLACE cListID WITH m.cListID
                  ELSE
                     WAIT WIND NOWAIT 'Item: ' + ALLT(m.ccateg) + ' was NOT added successfully. Code: ' + STR(loitemresp.statuscode)
                     m.cid	   = m.cCatCode
                     m.cname	   = m.ccateg
                     m.ctype	   = 'Exp Cat'
                     m.cmessage = loitemresp.statusmessage
                     m.nqberror = loitemresp.statuscode
                     INSERT INTO qbbadnames FROM MEMVAR
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
      ENDSCAN

      TRY
         SET DATASESSION TO (lnDatasession)
      CATCH TO loError
      ENDTRY
      THIS.oqbsm.EnableErrorRecovery = .T.
      WAIT CLEAR
   CATCH TO loError
      llError = .T.
   ENDTRY

   IF llError
      MESSAGEBOX('Unable to synchronize expense codes. Reason Given:' + CHR(13) + ;
         'Code: ' + TRANSFORM(loError.ERRORNO) + CHR(13) + loError.MESSAGE + CHR(13) + ;
         'Contact SherWare Support for assistance.', 48, 'Synchronize Expense Codes')
   ENDIF

   RETURN (NOT llError AND NOT llSyncError)

   ENDPROC


   ***************************
   PROCEDURE sync_wells
   ***************************
   LPARAMETERS tnDataSession, tlNewOnly
   LOCAL lnDatasession, llError, llSyncError

   * Initialize the error flags
   STORE .F. TO llError, llSyncError

   TRY
      IF VARTYPE(tnDataSession) # 'N'
         tnDataSession = 1
      ENDIF

      lnDatasession = SET('datasession')

      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH TO loError
      ENDTRY

      IF NOT THIS.lqbactive
         llreturn = .F.
         EXIT
      ENDIF

      IF NOT USED('qbbadnames')
         THIS.create_qbbadnames()
      ENDIF

      THIS.oqbsm.EnableErrorRecovery = .F.
      * get a message set request object (version 1.1 xml)
      lorequest = THIS.oqbrequest

      * set the on error attribute for the request
      lorequest.ATTRIBUTES.OnError = 1

      lorequest.ClearRequests()

      IF NOT USED('wells')
         USE wells IN 0
      ENDIF
      IF NOT USED('land')
         USE land IN 0
      ENDIF

      CREATE CURSOR badstatus (cWellID  c(10), ctype c(1))

      WAIT WIND NOWAIT 'Synchronizing wells file with QuickBooks ...Please Wait'
      SWSELECT('land')
      SCAN FOR  IIF(tlNewOnly, EMPTY(cListID), .T.)
         SCATTER MEMVAR

         IF EMPTY(m.cleasename) OR EMPTY(m.cleaseid)
            LOOP
         ENDIF

         * Can't have a colon (:) in the lease name
         IF ':' $ m.cleasename
            m.cleasename = STRTRAN(m.cleasename, ':', '-')
            REPLACE cleasename WITH m.cleasename
         ENDIF

         * add a class query request to request message set
         loClassQuery = lorequest.AppendClassQueryRq()

         * add a filter to the class request to look for the given well
         loClassQuery.orlistquery.listfilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
         loClassQuery.orlistquery.listfilter.ornamefilter.namefilter.NAME.setvalue(LEFT(m.cleasename, 31))

         * process the request object returning a response message object
         loresponse	= THIS.oqbsm.dorequests(lorequest)
         loClassResp	= loresponse.responselist.getat(0)

         IF loClassResp.statuscode # 0
            * Clear inquiry request
            lorequest.ClearRequests()
            lorequest.ATTRIBUTES.OnError	= 1
            loClassAdd					= lorequest.AppendClassAddRq()
            loClassAdd.NAME.setvalue(LEFT(ALLTRIM(m.cleasename), 31))
            loresponse  = THIS.oqbsm.dorequests(lorequest)
            loClassResp = loresponse.responselist.getat(0)

            IF loClassResp.statuscode = 0
               WAIT WIND NOWAIT 'Lease: ' + ALLT(m.cleasename) + ' was added to QuickBooks successfully as a class.' + CHR(13) + loClassResp.statusmessage
               loNewWell	= loClassResp.DETAIL
               m.cListID	= loNewWell.listid.getvalue()
               SELECT land
               REPLACE cListID WITH m.cListID
               THIS.ClearErrorRecovery()
            ELSE
               WAIT WINDOW NOWAIT 'Lease: ' + ALLT(m.cleasename) + ' was NOT added successfully. Code: ' + STR(loClassResp.statuscode) + CHR(13) + loClassResp.statusmessage
               m.cid		 = m.cleaseid
               m.cname	 = m.cleasename
               m.ctype	 = 'Lease'
               m.cmessage = loClassResp.statusmessage
               m.nqberror = loClassResp.statuscode
               INSERT INTO qbbadnames FROM MEMVAR
            ENDIF
         ELSE
            loWellList = loClassResp.DETAIL
            loWellRec  = loWellList.getat(0)
            m.cListID  = loWellRec.listid.getvalue()
            SWSELECT('land')
            REPL cListID WITH m.cListID
         ENDIF
         lorequest.ClearRequests()
         lorequest.ATTRIBUTES.OnError = 1
      ENDSCAN

      SWSELECT('wells')
      SCAN FOR NOT DELETED() AND NOT INLIST(cwellstat, 'I', 'P', 'S')  AND IIF(tlNewOnly, EMPTY(cListID), .T.)
         SCATTER MEMVAR
         IF EMPTY(m.cWellID) OR EMPTY(m.cwellname)
            LOOP
         ENDIF

         * Can't have a colon (:) in the well name
         IF ':' $ m.cwellname
            m.cwellname = STRTRAN(m.cwellname, ':', '-')
            REPLACE cwellname WITH m.cwellname
         ENDIF

         * add a class query request to request message set
         loClassQuery = lorequest.AppendClassQueryRq()

         * add a filter to the class request to look for the given well
         loClassQuery.orlistquery.listfilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
         loClassQuery.orlistquery.listfilter.ornamefilter.namefilter.NAME.setvalue(LEFT(m.cwellname, 31))

         * process the request object returning a response message object
         loresponse	= THIS.oqbsm.dorequests(lorequest)
         loClassResp	= loresponse.responselist.getat(0)

         IF loClassResp.statuscode # 0
            * Clear inquiry request
            lorequest.ClearRequests()
            lorequest.ATTRIBUTES.OnError	= 1
            loClassAdd					= lorequest.AppendClassAddRq()
            loClassAdd.NAME.setvalue(LEFT(m.cwellname, 31))
            loresponse  = THIS.oqbsm.dorequests(lorequest)
            loClassResp = loresponse.responselist.getat(0)

            IF loClassResp.statuscode = 0
               WAIT WIND NOWAIT 'Well: ' + ALLT(m.cwellname) + ' was added to QuickBooks successfully as a class.' + CHR(13) + loClassResp.statusmessage
               loNewWell	= loClassResp.DETAIL
               m.cListID	= loNewWell.listid.getvalue()
               SELECT wells
               REPLACE cListID WITH m.cListID
               THIS.ClearErrorRecovery()
            ELSE
               WAIT WINDOW NOWAIT 'Well: ' + ALLT(m.cwellname) + ' was NOT added successfully. Code: ' + STR(loClassResp.statuscode) + CHR(13) + loClassResp.statusmessage
               m.cid		 = m.cWellID
               m.cname	 = m.cwellname
               m.ctype	 = 'Well'
               m.cmessage = loClassResp.statusmessage
               m.nqberror = loClassResp.statuscode
               INSERT INTO qbbadnames FROM MEMVAR
            ENDIF
         ELSE
            loWellList = loClassResp.DETAIL
            loWellRec  = loWellList.getat(0)
            m.cListID  = loWellRec.listid.getvalue()
            SWSELECT('wells')
            REPL cListID WITH m.cListID
         ENDIF
         lorequest.ClearRequests()
         lorequest.ATTRIBUTES.OnError = 1
      ENDSCAN


      WAIT CLEAR

      THIS.oqbsm.EnableErrorRecovery = .T.

      TRY
         SET DATASESSION TO (lnDatasession)
      CATCH TO loError
      ENDTRY
   CATCH TO loError
      llError = .T.
   ENDTRY

   IF llError
      MESSAGEBOX('Unable to synchronize wells. Reason Given:' + CHR(13) + ;
         'Code: ' + TRANSFORM(loError.ERRORNO) + CHR(13) + loError.MESSAGE + CHR(13) + ;
         'Contact SherWare Support for assistance.', 48, 'Synchronize Wells')
   ENDIF

   RETURN (NOT llError AND NOT llSyncError)

   ENDPROC


   ***************************
   PROCEDURE sync_Vendors
   ***************************
   LPARAMETERS tnDataSession, tlNewOnly
   LOCAL lnDatasession, llError, llSyncError, lnvendor

   * Initialize the error flags
   STORE .F. TO llError, llSyncError

   LOCAL lovendorquery AS "qbfc7.ivendorquery"

   TRY
      IF VARTYPE(tnDataSession) # 'N'
         tnDataSession = 1
      ENDIF

      lnDatasession = SET('datasession')

      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH TO loError
      ENDTRY

      IF NOT THIS.lqbactive
         llreturn = .F.
         EXIT
      ENDIF

      IF NOT USED('qbbadnames')
         THIS.create_qbbadnames()
      ENDIF

      THIS.oqbsm.EnableErrorRecovery = .F.

      * get a message set request object (version 1.1 xml)
      lorequest = THIS.oqbrequest

      IF NOT THIS.lqberror
         * set the on error attribute for the request
         lorequest.ATTRIBUTES.OnError = 1
      ENDIF

      lorequest.ClearRequests()

      SWSELECT('vendor')

      llvendadd = .T.

      *!*            CREATE CURSOR vendtemp ;
      *!*               (cVendorID c(10), ;
      *!*                 cListID   c(36), ;
      *!*                 lActive   L)

      make_copy('vendor', 'vendtemp')

      WAIT WIND NOWAIT 'Synchronizing QuickBooks Vendor File with SherWare....Please Wait'

      * add a vendor query request to request message set
      IF NOT THIS.lqberror
         lovendorquery = lorequest.appendvendorqueryrq()
      ELSE
         llreturn = .F.
         EXIT
      ENDIF

      lovendorquery.ORVendorListQuery.VendorListFilter.ActiveStatus.setvalue(2)

      * Only ask for the items we need for our vendor file
      IF NOT m.goapp.lqberror AND THIS.sdkversion >= QBFCVER
         lovendorquery.IncludeRetElementList.ADD("ListID")
         lovendorquery.IncludeRetElementList.ADD("Name")
         lovendorquery.IncludeRetElementList.ADD("Contact")
         lovendorquery.IncludeRetElementList.ADD("Phone")
         lovendorquery.IncludeRetElementList.ADD("Fax")
         lovendorquery.IncludeRetElementList.ADD("VendorTaxIdent")
         lovendorquery.IncludeRetElementList.ADD("TermsRef")
         lovendorquery.IncludeRetElementList.ADD("IsVendorEligibleFor1099")
         lovendorquery.IncludeRetElementList.ADD("VendorAddress")
         lovendorquery.IncludeRetElementList.ADD("Email")
         lovendorquery.IncludeRetElementList.ADD("IsActive")
      ENDIF

      * Add vendors from QuickBooks to vendor table if they don't already exist
      IF NOT THIS.lqberror
         loresponse = THIS.oqbsm.dorequests(lorequest)
      ENDIF
      IF NOT THIS.lqberror
         lovendresp = loresponse.responselist.getat(0)
      ENDIF
      IF NOT THIS.lqberror
         IF lovendresp.statuscode = 0
            lnvendor = 0
            FOR lni = 0 TO lovendresp.DETAIL.COUNT - 1

               * get reference to single vendor
               lovend = lovendresp.DETAIL.getat(lni)

               * get the value of each of the fields
               lnvendor	  = lnvendor + 1
               m.cVendorID = 'V' + PADL(TRANSFORM(lnvendor), 5, '0')
               IF VARTYPE(lovend.isactive) = 'O'
                  m.lActive = lovend.isactive.getvalue()
               ELSE
                  m.lActive = .T.
               ENDIF
               IF VARTYPE(lovend.NAME) = 'O'
                  m.cvendname  = lovend.NAME.getvalue()
                  m.csortfield = m.cvendname
               ELSE
                  m.cvendname  = 'Unknown'
                  m.csortfield = 'Unknown'
               ENDIF
               IF VARTYPE(lovend.contact) = 'O'
                  m.cbcontact = lovend.contact.getvalue()
                  m.ccontact	 = m.cbcontact
               ELSE
                  m.cbcontact = ''
                  m.ccontact	 = ''
               ENDIF
               IF VARTYPE(lovend.phone) = 'O'
                  m.cbphone = lovend.phone.getvalue()
                  m.cphone  = m.cbphone
               ELSE
                  m.cbphone = ''
                  m.cphone  = ''
               ENDIF
               IF VARTYPE(lovend.fax) = 'O'
                  m.cbfaxphone = lovend.fax.getvalue()
                  m.cfaxphone  = m.cbfaxphone
               ELSE
                  m.cbfaxphone = ''
                  m.cfaxphone  = ''
               ENDIF
               IF VARTYPE(lovend.email) = 'O'
                  m.cemail = lovend.email.getvalue()
               ELSE
                  m.cemail = ''
               ENDIF
               IF VARTYPE(lovend.termsref) = 'O'
                  IF VARTYPE(lovend.termsref.listid) = 'O'
                     m.cidterm = lovend.termsref.listid.getvalue()
                  ELSE
                     m.cidterm = ''
                  ENDIF
               ELSE
                  m.cidterm = ''
               ENDIF
               IF VARTYPE(lovend.vendortaxident) = 'O'
                  m.ctaxid = cmEncrypt(lovend.vendortaxident.getvalue(), m.goapp.cEncryptionKey)
               ELSE
                  m.ctaxid = ''
               ENDIF
               IF VARTYPE(lovend.isvendoreligiblefor1099) = 'O'
                  m.lsend1099 = lovend.isvendoreligiblefor1099.getvalue()
               ELSE
                  m.lsend1099 = .F.
               ENDIF
               IF VARTYPE(lovend.vendoraddress) = 'O'
                  IF VARTYPE(lovend.vendoraddress.addr1) = 'O'
                     m.cbaddr1 = lovend.vendoraddress.addr1.getvalue()
                  ELSE
                     m.cbaddr1 = ''
                  ENDIF
                  IF VARTYPE(lovend.vendoraddress.addr2) = 'O'
                     m.cbaddr2 = lovend.vendoraddress.addr2.getvalue()
                  ELSE
                     m.cbaddr2 = ''
                  ENDIF
                  IF VARTYPE(lovend.vendoraddress.city) = 'O'
                     m.cbcity = lovend.vendoraddress.city.getvalue()
                  ELSE
                     m.cbcity = ''
                  ENDIF
                  IF VARTYPE(lovend.vendoraddress.state) = 'O'
                     m.cbstate = lovend.vendoraddress.state.getvalue()
                  ELSE
                     m.cbstate = ''
                  ENDIF
                  IF VARTYPE(lovend.vendoraddress.postalcode) = 'O'
                     m.cbzip = lovend.vendoraddress.postalcode.getvalue()
                  ELSE
                     m.cbzip = ''
                  ENDIF
               ELSE
                  STORE '' TO m.cbaddr1, m.cbaddr2, m.cbcity, m.cbstate, m.cbzip
               ENDIF

               m.cListID = lovend.listid.getvalue()
               INSERT INTO vendtemp FROM MEMVAR
               SET DELE OFF
               SELECT vendor
               LOCATE FOR cListID = m.cListID
               IF NOT FOUND()
                  LOCATE FOR cvendname = ALLTRIM(m.cvendname)
                  IF FOUND()
                     IF DELETED()
                        RECALL
                     ENDIF
                     REPL cvendname WITH m.cvendname, ;
                        cbaddr1   WITH m.cbaddr1, ;
                        cbaddr2   WITH m.cbaddr2, ;
                        cbcity    WITH m.cbcity, ;
                        cbstate   WITH m.cbstate, ;
                        cbzip     WITH m.cbzip, ;
                        cemail    WITH m.cemail, ;
                        cListID   WITH m.cListID
                  ELSE
                     * Make sure the vendor id is unique
                     SELECT vendor
                     SET ORDER TO cVendorID   && CVENDORID
                     DO WHILE SEEK(m.cVendorID)
                        lnvendor	   = lnvendor + 1
                        m.cVendorID = 'V' + PADL(TRANSFORM(lnvendor), 5, '0')
                     ENDDO
                     INSERT INTO vendor FROM MEMVAR
                  ENDIF
               ELSE
                  IF DELETED()
                     RECALL
                  ENDIF
                  REPLACE cvendname WITH m.cvendname
                  REPLACE csortfield WITH m.csortfield
                  REPLACE cListID WITH m.cListID
                  REPLACE cidterm WITH m.cidterm
                  REPLACE lsend1099 WITH m.lsend1099
                  REPLACE ctaxid   WITH m.ctaxid
                  REPL cbaddr1   WITH m.cbaddr1, ;
                     cbaddr2   WITH m.cbaddr2, ;
                     cbcity    WITH m.cbcity, ;
                     cbstate   WITH m.cbstate, ;
                     cbzip     WITH m.cbzip, ;
                     cemail    WITH m.cemail, ;
                     cListID   WITH m.cListID
               ENDIF
               SET DELE ON
            ENDFOR
         ENDIF
      ENDIF

      * Add vendor to QuickBooks if it doesn't already exist.
      *  This should only happen if the vendsync file doesn't exist - i.e. the first time a non-DMIE
      *  company is synced with QB
      IF NOT FILE(ALLT(m.goapp.cdatafilepath) + 'vendsync.dat')
         WAIT WIND NOWAIT 'Synchronizing SherWare Vendor File with QuickBooks....Please Wait'
         SWSELECT('vendor')
         SCAN FOR  IIF(tlNewOnly, EMPTY(cListID), .T.)
            SCATTER MEMVAR
            m.cvendname	= STRTRAN(m.cvendname, ':', '')
            m.csortfield	= STRTRAN(m.csortfield, ':', '')
            SELECT vendtemp
            LOCATE FOR cListID == m.cListID
            IF FOUND()
               LOOP
            ENDIF

            IF NOT THIS.lqberror
               lorequest.ClearRequests()
            ENDIF
            * add a vendor query request to request message set
            IF NOT THIS.lqberror
               lovendorquery = lorequest.appendvendorqueryrq()
            ENDIF

            IF NOT m.goapp.lqberror AND THIS.sdkversion >= QBFCVER
               lovendorquery.IncludeRetElementList.ADD("ListID")
               lovendorquery.IncludeRetElementList.ADD("Name")
               lovendorquery.IncludeRetElementList.ADD("Contact")
               lovendorquery.IncludeRetElementList.ADD("Phone")
               lovendorquery.IncludeRetElementList.ADD("Fax")
               lovendorquery.IncludeRetElementList.ADD("VendorTaxIdent")
               lovendorquery.IncludeRetElementList.ADD("TermsRef")
               lovendorquery.IncludeRetElementList.ADD("Email")
               lovendorquery.IncludeRetElementList.ADD("IsVendorEligibleFor1099")
               lovendorquery.IncludeRetElementList.ADD("VendorAddress")
            ENDIF

            * add a filter to the customer request to only pick up active customers
            IF NOT THIS.lqberror
               lovendorquery.ORVendorListQuery.VendorListFilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
            ENDIF
            IF NOT THIS.lqberror
               lovendorquery.ORVendorListQuery.VendorListFilter.ornamefilter.namefilter.NAME.setvalue(m.cvendname)
            ENDIF

            * process the request object returning a response message object
            IF NOT THIS.lqberror
               loresponse = THIS.oqbsm.dorequests(lorequest)
            ENDIF
            IF NOT THIS.lqberror
               lovendresp = loresponse.responselist.getat(0)
            ENDIF
            IF NOT THIS.lqberror
               IF lovendresp.statuscode # 0
                  IF llvendadd
                     * Clear inquiry request1
                     lorequest.ClearRequests()
                     lovendadd = lorequest.appendvendoraddrq()
                     lovendadd.CompanyName.setvalue(PADR(ALLTRIM(m.cvendname), 41, ' '))
                     lovendadd.NAME.setvalue(PADR(ALLTRIM(m.cvendname), 41, ' '))
                     lovendadd.vendoraddress.addr1.setvalue(PADR(ALLTRIM(m.cbaddr1), 41, ' '))
                     lovendadd.vendoraddress.addr2.setvalue(PADR(ALLTRIM(m.cbaddr2), 41, ' '))
                     lovendadd.vendoraddress.city.setvalue(ALLTRIM(m.cbcity))
                     lovendadd.vendoraddress.state.setvalue(ALLTRIM(m.cbstate))
                     lovendadd.vendoraddress.postalcode.setvalue(ALLTRIM(m.cbzip))
                     lovendadd.accountnumber.setvalue(ALLTRIM(m.cVendorID))
                     lovendadd.email.setvalue(ALLTRIM(m.cemail))
                     loresponse = THIS.oqbsm.dorequests(lorequest)
                     lovendresp = loresponse.responselist.getat(0)

                     IF lovendresp.statuscode = 0
                        WAIT WIND NOWAIT 'Vendor: ' + ALLT(m.cvendname) + ' was added to QuickBooks successfully.' + CHR(13) + lovendresp.statusmessage
                        lonevendor = lovendresp.DETAIL
                        m.cListID  = lonevendor.listid.getvalue()
                        SELECT vendor
                        REPLACE cListID WITH m.cListID
                     ELSE
                        *!*	                           WAIT WIND NOWAIT 'Vendor: ' + ALLT(m.cvendname) + ' was NOT added successfully. Code: ' + ;
                        *!*	                               transform(lovendresp.statuscode)
                        m.cid	  = m.cVendorID
                        m.cname	  = m.cvendname
                        m.ctype	  = 'Vendor'
                        m.cmessage = lovendresp.statusmessage
                        m.nqberror = lovendresp.statuscode
                        INSERT INTO qbbadnames FROM MEMVAR
                     ENDIF
                  ELSE
                     SELECT vendor
                     DELE NEXT 1
                  ENDIF
               ELSE
                  lovendorlist = lovendresp.DETAIL
                  lovendorrec  = lovendorlist.getat(0)
                  m.cListID	  = lovendorrec.listid.getvalue()
                  m.csortfield = lovendorrec.NAME.getvalue()
                  SWSELECT('vendor')
                  REPL cListID WITH m.cListID
                  IF EMPTY(csortfield)
                     REPL csortfield WITH m.csortfield
                  ENDIF
                  THIS.ClearErrorRecovery()
               ENDIF
            ENDIF
         ENDSCAN
      ENDIF

      * Delete bad vendor records in our vendor file that don't exist in QB anymore
      SELECT vendor
      SCAN
         m.cListID = cListID
         SELECT vendtemp
         LOCATE FOR cListID == m.cListID
         IF NOT FOUND()
            SELECT vendor
            DELETE NEXT 1
         ENDIF
      ENDSCAN

      *  Mark all vendors with a terms code of POST as being integrated with the G/L
      lorequest.ClearRequests()
      loterms = lorequest.appendtermsqueryrq()
      loterms.orlistquery.listfilter.ornamefilter.namefilter.NAME.setvalue('POST')
      loterms.orlistquery.listfilter.ornamefilter.namefilter.matchcriterion.setvalue(1)

      loresponse	 = THIS.oqbsm.dorequests(lorequest)
      lotermslist = loresponse.responselist.getat(0)

      IF lotermslist.statuscode = 0
         lotermsret = lotermslist.DETAIL.getat(0)
         lctermsid  = lotermsret.standardtermsret.listid.getvalue()
         lctermdesc = lotermsret.standardtermsret.NAME.getvalue()
         SELECT vendor
         SCAN
            IF cidterm = lctermsid
               REPLACE linteggl WITH .T.
            ELSE
               REPLACE linteggl WITH .F.
            ENDIF
         ENDSCAN
      ENDIF

      fh = FCREATE(ALLT(m.goapp.cdatafilepath) + 'vendsync.dat')
      = FCLOSE(fh)

      WAIT CLEAR
      TRY
         SET DATASESSION TO (lnDatasession)
      CATCH TO loError
      ENDTRY
   CATCH TO loError
      llError = .T.
   ENDTRY

   IF llError
      MESSAGEBOX('Unable to synchronize vendors. Reason Given:' + CHR(13) + ;
         'Code: ' + TRANSFORM(loError.ERRORNO) + CHR(13) + loError.MESSAGE + CHR(13) + ;
         'Contact SherWare Support for assistance.', 48, 'Synchronize Vendors')
   ENDIF

   THIS.oqbsm.EnableErrorRecovery = .T.
   RETURN (NOT llError AND NOT llSyncError)

   ENDPROC

   ***************************
   PROCEDURE sync_Owners_as_Vendors
   ***************************
   LPARAMETERS tnDataSession, tlNewOnly
   LOCAL lnDatasession, llError, llSyncError, lnvendor

   * Initialize the error flags
   STORE .F. TO llError, llSyncError

   LOCAL lovendorquery AS "qbfc7.ivendorquery"

   TRY
      IF VARTYPE(tnDataSession) # 'N'
         tnDataSession = 1
      ENDIF

      lnDatasession = SET('datasession')

      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH TO loError
      ENDTRY

      IF NOT THIS.lqbactive
         llreturn = .F.
         EXIT
      ENDIF

      IF NOT USED('qbbadnames')
         THIS.create_qbbadnames()
      ENDIF

      THIS.oqbsm.EnableErrorRecovery = .F.

      * get a message set request object (version 1.1 xml)
      lorequest = THIS.oqbrequest

      IF NOT THIS.lqberror
         * set the on error attribute for the request
         lorequest.ATTRIBUTES.OnError = 1
      ENDIF

      lorequest.ClearRequests()

      SWSELECT('investor')

      llvendadd = .T.

      make_copy('investor', 'vendtemp')

      WAIT WIND NOWAIT 'Synchronizing Owner file to QB as Vendors....Please Wait'

      * Add vendor to QuickBooks if it doesn't already exist.
      WAIT WIND NOWAIT 'Synchronizing SherWare Owner File with QuickBooks....Please Wait'
      SWSELECT('investor')
      SCAN FOR  IIF(tlNewOnly, EMPTY(cListID), .T.)
         SCATTER MEMVAR
         m.cvendname	= STRTRAN(m.cownname, ':', '')
         m.csortfield	= STRTRAN(m.csortfield, ':', '')

         IF NOT THIS.lqberror
            lorequest.ClearRequests()
         ENDIF
         * add a vendor query request to request message set
         IF NOT THIS.lqberror
            lovendorquery = lorequest.appendvendorqueryrq()
         ENDIF

         IF NOT m.goapp.lqberror AND THIS.sdkversion >= QBFCVER
            lovendorquery.IncludeRetElementList.ADD("ListID")
            lovendorquery.IncludeRetElementList.ADD("Name")
            lovendorquery.IncludeRetElementList.ADD("Contact")
            lovendorquery.IncludeRetElementList.ADD("Phone")
            lovendorquery.IncludeRetElementList.ADD("Fax")
            lovendorquery.IncludeRetElementList.ADD("VendorTaxIdent")
            lovendorquery.IncludeRetElementList.ADD("TermsRef")
            lovendorquery.IncludeRetElementList.ADD("Email")
            lovendorquery.IncludeRetElementList.ADD("IsVendorEligibleFor1099")
            lovendorquery.IncludeRetElementList.ADD("VendorAddress")
         ENDIF

         * add a filter to the customer request to only pick up active customers
         IF NOT THIS.lqberror
            lovendorquery.ORVendorListQuery.VendorListFilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
         ENDIF
         IF NOT THIS.lqberror
            lovendorquery.ORVendorListQuery.VendorListFilter.ornamefilter.namefilter.NAME.setvalue(m.csortfield)
         ENDIF

         * process the request object returning a response message object
         IF NOT THIS.lqberror
            loresponse = THIS.oqbsm.dorequests(lorequest)
         ENDIF
         IF NOT THIS.lqberror
            lovendresp = loresponse.responselist.getat(0)
         ENDIF
         IF NOT THIS.lqberror
            IF lovendresp.statuscode # 0
               * Clear inquiry request1
               lorequest.ClearRequests()
               lovendadd = lorequest.appendvendoraddrq()
               lovendadd.CompanyName.setvalue(PADR(ALLTRIM(m.csortfield), 41, ' '))
               lovendadd.NAME.setvalue(PADR(ALLTRIM(m.csortfield), 41, ' '))
               lovendadd.vendoraddress.addr1.setvalue(PADR(ALLTRIM(m.caddress1a), 41, ' '))
               lovendadd.vendoraddress.addr2.setvalue(PADR(ALLTRIM(m.caddress1b), 41, ' '))
               lovendadd.vendoraddress.city.setvalue(ALLTRIM(m.ccity1))
               lovendadd.vendoraddress.state.setvalue(ALLTRIM(m.cstate1))
               lovendadd.vendoraddress.postalcode.setvalue(ALLTRIM(m.czip1))
               lovendadd.accountnumber.setvalue(ALLTRIM(m.cOwnerID))
               lovendadd.email.setvalue(ALLTRIM(m.cemail))
               loresponse = THIS.oqbsm.dorequests(lorequest)
               lovendresp = loresponse.responselist.getat(0)

               IF lovendresp.statuscode = 0
                  WAIT WIND NOWAIT 'Owner: ' + ALLT(m.csortfield) + ' was added to QuickBooks successfully.' + CHR(13) + lovendresp.statusmessage
                  lonevendor = lovendresp.DETAIL
                  m.cListID  = lonevendor.listid.getvalue()
                  SELECT investor
                  REPLACE cListID WITH m.cListID
               ELSE
                  m.cid	  = m.cOwnerID
                  m.cname	  = m.cvendname
                  m.ctype	  = 'Owner'
                  m.cmessage = lovendresp.statusmessage
                  m.nqberror = lovendresp.statuscode
                  INSERT INTO qbbadnames FROM MEMVAR
               ENDIF
            ELSE
               lovendorlist = lovendresp.DETAIL
               lovendorrec  = lovendorlist.getat(0)
               m.cListID	  = lovendorrec.listid.getvalue()
               m.csortfield = lovendorrec.NAME.getvalue()
               SWSELECT('investor')
               REPL cListID WITH m.cListID
               IF EMPTY(csortfield)
                  REPL csortfield WITH m.csortfield
               ENDIF
               THIS.ClearErrorRecovery()
            ENDIF
         ENDIF
      ENDSCAN

      WAIT CLEAR
      TRY
         SET DATASESSION TO (lnDatasession)
      CATCH TO loError
      ENDTRY
   CATCH TO loError
      llError = .T.
   ENDTRY

   IF llError
      MESSAGEBOX('Unable to synchronize owners. Reason Given:' + CHR(13) + ;
         'Code: ' + TRANSFORM(loError.ERRORNO) + CHR(13) + loError.MESSAGE + CHR(13) + ;
         'Contact SherWare Support for assistance.', 48, 'Synchronize Vendors')
   ENDIF

   THIS.oqbsm.EnableErrorRecovery = .T.
   RETURN (NOT llError AND NOT llSyncError)

   ENDPROC

   ***************************
   PROCEDURE sync_owners
   ***************************
   LPARAMETERS tnDataSession, tlNewOnly
   LOCAL lnDatasession, llError, llSyncError

   * Initialize the error flags
   STORE .F. TO llError, llSyncError

   TRY
      IF VARTYPE(tnDataSession) # 'N'
         tnDataSession = 1
      ENDIF

      lnDatasession = SET('datasession')

      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH TO loError
      ENDTRY

      SET DELE ON

      IF NOT THIS.lqbactive
         llreturn = .F.
         EXIT
      ENDIF

      IF NOT USED('qbbadnames')
         THIS.create_qbbadnames()
      ENDIF

      THIS.oqbsm.EnableErrorRecovery = .F.

      LOCAL loCustQuery AS 'qbfc12.icustomerquery'
      LOCAL loCustMod   AS 'qbfc12.icustomermod'
      LOCAL loCustAdd   AS 'qbfc12.icustomeradd'


      * get a message set request object (version 1.1 xml)
      lorequest = THIS.oqbrequest

      * set the on error attribute for the request
      lorequest.ATTRIBUTES.OnError = 1

      lorequest.ClearRequests()

      CREATE CURSOR badstatus (cOwnerID c(10))

      WAIT WIND NOWAIT 'Synchronizing owner file with QuickBooks customer file ...Please Wait'
      SWSELECT('investor')
      SCAN FOR NOT DELETED()  AND IIF(tlNewOnly, EMPTY(cListID), .T.)
         SCATTER MEMVAR

         *  Why would someone have a blank sortfield?  Mystery of life, but someone had a few of them, and it messed up reporting. - BH 05/11/12
         IF EMPTY(m.csortfield)
            REPLACE csortfield WITH m.cownname
            m.csortfield = m.cownname
         ENDIF

         IF EMPTY(m.cOwnerID) OR EMPTY(m.cownname)
            LOOP
         ENDIF

         IF 'é' $ m.cownname
            m.cownname   = STRTRAN(m.cownname, 'é', 'e')
            REPLACE cownname WITH m.cownname
         ENDIF
         IF 'é' $ m.csortfield
            m.csortfield = STRTRAN(m.csortfield, 'é', 'e')
            REPLACE csortfield WITH m.csortfield
         ENDIF
         IF ':' $ m.cownname
            m.cownname   = STRTRAN(m.cownname, ':', '-')
            REPLACE cownname WITH m.cownname
         ENDIF
         IF ':' $ m.csortfield
            m.csortfield = STRTRAN(m.csortfield, ':', '-')
            REPLACE csortfield WITH m.csortfield
         ENDIF

         * add a customer query request to request message set
         loCustQuery = lorequest.appendcustomerqueryrq()

         * Look for the owner by list id or owner name
         IF NOT EMPTY(m.cListID)
            * add a filter to look for the customer by listid
            loCustQuery.ORCustomerListQuery.ListIDList.ADD(m.cListID)
         ELSE
            * add a filter to the class request to look for the given customer
            loCustQuery.ORCustomerListQuery.customerlistfilter.ornamefilter.namefilter.matchcriterion.setvalue(0)
            loCustQuery.ORCustomerListQuery.customerlistfilter.ornamefilter.namefilter.NAME.setvalue(LEFT(m.cownname, 41))
         ENDIF

         * Get the response from the query by list id or owner name
         loresponse = THIS.oqbsm.dorequests(lorequest)
         locustresp = loresponse.responselist.getat(0)


         * If the owner wasn't found in QB, do a query on sort field
         IF locustresp.statuscode # 0
            * Clear inquiry request
            lorequest.ClearRequests()
            lorequest.ATTRIBUTES.OnError = 1

            loCustQuery = lorequest.appendcustomerqueryrq()
            loCustQuery.ORCustomerListQuery.customerlistfilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
            loCustQuery.ORCustomerListQuery.customerlistfilter.ornamefilter.namefilter.NAME.setvalue(LEFT(m.csortfield, 41))
            loCustQuery.ORCustomerListQuery.customerlistfilter.ActiveStatus.setvalue(2)

            * process the request object returning a response message object
            loresponse = THIS.oqbsm.dorequests(lorequest)
            locustresp = loresponse.responselist.getat(0)


            * Add the owner as a customer since they weren't found
            IF locustresp.statuscode # 0
               * Clear inquiry request
               TRY
                  lorequest.ClearRequests()
                  lorequest.ATTRIBUTES.OnError = 1

                  loCustAdd = lorequest.appendcustomeraddrq()
                  loCustAdd.NAME.setvalue(PADR(ALLTRIM(m.csortfield), 41, ' '))
                  loCustAdd.billaddress.addr1.setvalue(LEFT(m.cownname, 41))
                  loCustAdd.billaddress.addr2.setvalue(PADR(ALLTRIM(m.caddress1a), 41, ' '))
                  loCustAdd.billaddress.addr3.setvalue(PADR(ALLTRIM(m.caddress1b), 41, ' '))
                  loCustAdd.billaddress.city.setvalue(LEFT(ALLTRIM(m.ccity1), 31))
                  loCustAdd.phone.setvalue(m.cphoneh)
                  loCustAdd.fax.setvalue(m.cphonew)
                  loCustAdd.email.setvalue(m.cemail)
                  IF NOT EMPTY(m.cidterm)
                     SWSELECT('terms')
                     LOCATE FOR ALLTRIM(cidterm) == ALLTRIM(m.cidterm)
                     IF FOUND()
                        loCustAdd.termsref.listid.setvalue(terms.cListID)
                     ENDIF
                  ENDIF
                  IF THIS.ccountry = 'US'
                     loCustAdd.billaddress.state.setvalue(ALLTRIM(m.cstate1))
                  ENDIF
                  loCustAdd.billaddress.postalcode.setvalue(ALLTRIM(m.czip1))
                  IF NOT EMPTY(m.caddress2a)
                     loCustAdd.shipaddress.addr1.setvalue(LEFT(m.cownname, 41))
                     loCustAdd.shipaddress.addr2.setvalue(PADR(ALLTRIM(m.caddress2a), 41, ' '))
                     loCustAdd.shipaddress.addr3.setvalue(PADR(ALLTRIM(m.caddress2b), 41, ' '))
                     loCustAdd.shipaddress.city.setvalue(LEFT(ALLTRIM(m.ccity2), 31))
                     IF THIS.ccountry = 'US'
                        loCustAdd.shipaddress.state.setvalue(ALLTRIM(m.cstate2))
                     ENDIF
                     loCustAdd.shipaddress.postalcode.setvalue(ALLTRIM(m.czip2))
                  ENDIF

                  loCustAdd.accountnumber.setvalue(ALLTRIM(m.cOwnerID))
                  loCustAdd.resalenumber.setvalue(cmEncrypt(ALLTRIM(m.ctaxid), m.goapp.cEncryptionKey))
                  loresponse	= THIS.oqbsm.dorequests(lorequest)
                  locustresp	= loresponse.responselist.getat(0)

                  IF locustresp.statuscode = 0
                     WAIT WIND NOWAIT 'Owner: ' + ALLT(m.cownname) + ' was added to QuickBooks successfully as a customer.' + CHR(13) + locustresp.statusmessage
                     lonewowner = locustresp.DETAIL
                     m.cListID  = lonewowner.listid.getvalue()
                     SELECT investor
                     REPLACE cListID WITH m.cListID
                     THIS.ClearErrorRecovery()
                  ELSE
                     WAIT WIND NOWAIT 'Owner: ' + ALLT(m.cownname) + ' was NOT added successfully. Code: ' + STR(locustresp.statuscode) + CHR(13) + locustresp.statusmessage
                     m.cid	   = m.cOwnerID
                     m.cname	   = m.cownname
                     m.ctype	   = 'Owner'
                     m.cmessage = locustresp.statusmessage
                     m.nqberror = locustresp.statuscode
                     INSERT INTO qbbadnames FROM MEMVAR
                  ENDIF
               CATCH

               ENDTRY
            ELSE
               TRY
                  * Owner was found so just modify the customer to match current info
                  loowner	= locustresp.DETAIL
                  loownerrec	= loowner.getat(0)
                  m.cListID	= loownerrec.listid.getvalue()
                  m.ceditseq	= loownerrec.editsequence.getvalue()

                  lorequest.ClearRequests()

                  loCustMod = lorequest.AppendCustomerModRq
                  loCustMod.listid.setvalue(m.cListID)
                  loCustMod.editsequence.setvalue(m.ceditseq)
                  loCustMod.billaddress.addr1.setvalue(LEFT(m.cownname, 41))
                  loCustMod.billaddress.addr2.setvalue(LEFT(m.caddress1a, 41))
                  loCustMod.billaddress.addr3.setvalue(LEFT(m.caddress1b, 41))
                  loCustMod.billaddress.city.setvalue(LEFT(m.ccity1, 31))
                  loCustMod.billaddress.state.setvalue(m.cstate1)
                  loCustMod.billaddress.postalcode.setvalue(m.czip1)
                  loCustMod.CompanyName.setvalue(LEFT(m.csortfield, 41))
                  loCustMod.email.setvalue(m.cemail)
                  loCustMod.phone.setvalue(m.cphoneh)
                  loCustMod.fax.setvalue(m.cphonew)

                  loCustMod.accountnumber.setvalue(ALLTRIM(m.cOwnerID))
                  loCustMod.resalenumber.setvalue(cmEncrypt(ALLTRIM(m.ctaxid), m.goapp.cEncryptionKey))
                  IF NOT EMPTY(m.caddress2a)
                     loCustMod.shipaddress.addr1.setvalue(LEFT(m.cownname, 41))
                     loCustMod.shipaddress.addr2.setvalue(PADR(ALLTRIM(m.caddress2a), 41, ' '))
                     loCustMod.shipaddress.addr3.setvalue(PADR(ALLTRIM(m.caddress2b), 41, ' '))
                     loCustMod.shipaddress.city.setvalue(ALLTRIM(m.ccity2))
                     IF THIS.ccountry = 'US'
                        loCustMod.shipaddress.state.setvalue(ALLTRIM(m.cstate2))
                     ENDIF
                     loCustMod.shipaddress.postalcode.setvalue(ALLTRIM(m.czip2))
                  ENDIF
                  IF NOT EMPTY(m.cidterm)
                     SWSELECT('terms')
                     LOCATE FOR ALLTRIM(cidterm) == ALLTRIM(m.cidterm)
                     IF FOUND()
                        loCustMod.termsref.listid.setvalue(terms.cListID)
                     ENDIF
                  ENDIF
                  loresponse	= THIS.oqbsm.dorequests(lorequest)
                  locustresp	= loresponse.responselist.getat(0)

                  IF locustresp.statuscode = 0
                     SWSELECT('investor')
                     REPLACE cListID WITH m.cListID

                     lorequest.ClearRequests()
                     lorequest.ATTRIBUTES.OnError = 1

                     loCustQuery = lorequest.appendcustomerqueryrq()
                     loCustQuery.ORCustomerListQuery.customerlistfilter.ornamefilter.namefilter.matchcriterion.setvalue(1)
                     loCustQuery.ORCustomerListQuery.customerlistfilter.ornamefilter.namefilter.NAME.setvalue(LEFT(m.csortfield, 41))
                     loCustQuery.ORCustomerListQuery.customerlistfilter.ActiveStatus.setvalue(2)
                     loresponse = THIS.oqbsm.dorequests(lorequest)
                     locustresp = loresponse.responselist.getat(0)

                     IF locustresp.statuscode = 0
                        loowner	  = locustresp.DETAIL
                        loownerrec = loowner.getat(0)
                        m.cListID  = loownerrec.listid.getvalue()
                        m.ceditseq = loownerrec.editsequence.getvalue()

                        * Try to change the name now by itself.
                        lorequest.ClearRequests()
                        loCustMod = lorequest.AppendCustomerModRq
                        loCustMod.listid.setvalue(m.cListID)
                        loCustMod.editsequence.setvalue(m.ceditseq)
                        loCustMod.NAME.setvalue(LEFT(m.csortfield, 41))

                        loCustMod.accountnumber.setvalue(ALLTRIM(m.cOwnerID))
                        loresponse = THIS.oqbsm.dorequests(lorequest)
                        locustresp = loresponse.responselist.getat(0)
                     ENDIF
                  ELSE
                     WAIT WIND NOWAIT 'Owner: ' + ALLT(m.cownname) + ' was NOT changed successfully. Code: ' + STR(locustresp.statuscode) + CHR(13) + locustresp.statusmessage
                     m.cid	   = m.cOwnerID
                     m.cname	   = m.cownname
                     m.ctype	   = 'Owner'
                     m.cmessage = locustresp.statusmessage
                     m.nqberror = locustresp.statuscode
                     INSERT INTO qbbadnames FROM MEMVAR
                  ENDIF
               CATCH

               ENDTRY
            ENDIF
         ELSE
            locustresp = loresponse.responselist.getat(0)
            loowner	  = locustresp.DETAIL
            loownerrec = loowner.getat(0)
            m.cListID  = loownerrec.listid.getvalue()
            m.ceditseq = loownerrec.editsequence.getvalue()

            lorequest.ClearRequests()

            loCustMod = lorequest.AppendCustomerModRq
            loCustMod.listid.setvalue(m.cListID)
            loCustMod.editsequence.setvalue(m.ceditseq)

            loCustMod.billaddress.addr1.setvalue(LEFT(m.cownname, 41))
            loCustMod.billaddress.addr2.setvalue(LEFT(m.caddress1a, 41))
            loCustMod.billaddress.addr3.setvalue(LEFT(m.caddress1b, 41))
            loCustMod.billaddress.city.setvalue(LEFT(m.ccity1, 31))
            loCustMod.billaddress.state.setvalue(m.cstate1)
            loCustMod.billaddress.postalcode.setvalue(m.czip1)
            loCustMod.CompanyName.setvalue(LEFT(m.csortfield, 41))
            loCustMod.email.setvalue(m.cemail)
            loCustMod.phone.setvalue(m.cphoneh)
            loCustMod.fax.setvalue(m.cphonew)

            loCustMod.accountnumber.setvalue(ALLTRIM(m.cOwnerID))
            loCustMod.resalenumber.setvalue(cmEncrypt(ALLTRIM(m.ctaxid), m.goapp.cEncryptionKey))
            IF NOT EMPTY(m.caddress2a)
               loCustMod.shipaddress.addr1.setvalue(LEFT(m.cownname, 41))
               loCustMod.shipaddress.addr2.setvalue(PADR(ALLTRIM(m.caddress2a), 41, ' '))
               loCustMod.shipaddress.addr3.setvalue(PADR(ALLTRIM(m.caddress2b), 41, ' '))
               loCustMod.shipaddress.city.setvalue(ALLTRIM(m.ccity2))
               IF THIS.ccountry = 'US'
                  loCustMod.shipaddress.state.setvalue(ALLTRIM(m.cstate2))
               ENDIF
               loCustMod.shipaddress.postalcode.setvalue(ALLTRIM(m.czip2))
            ENDIF
            IF NOT EMPTY(m.cidterm)
               SWSELECT('terms')
               LOCATE FOR ALLTRIM(cidterm) == ALLTRIM(m.cidterm)
               IF FOUND()
                  loCustMod.termsref.listid.setvalue(terms.cListID)
               ENDIF
            ENDIF
            loresponse = THIS.oqbsm.dorequests(lorequest)
            locustresp = loresponse.responselist.getat(0)

            IF locustresp.statuscode = 0
               SWSELECT('investor')
               REPLACE cListID WITH m.cListID

               lorequest.ClearRequests()
               lorequest.ATTRIBUTES.OnError = 1

               loCustQuery = lorequest.appendcustomerqueryrq()
               loCustQuery.ORCustomerListQuery.ListIDList.ADD(m.cListID)
               loresponse = THIS.oqbsm.dorequests(lorequest)
               locustresp = loresponse.responselist.getat(0)

               IF locustresp.statuscode = 0
                  loowner	= locustresp.DETAIL
                  loownerrec	= loowner.getat(0)
                  m.cListID	= loownerrec.listid.getvalue()
                  m.ceditseq	= loownerrec.editsequence.getvalue()

                  * Try to change the name now by itself.
                  lorequest.ClearRequests()
                  loCustMod = lorequest.AppendCustomerModRq
                  loCustMod.listid.setvalue(m.cListID)
                  loCustMod.editsequence.setvalue(m.ceditseq)
                  loCustMod.NAME.setvalue(LEFT(m.csortfield, 41))

                  loCustMod.accountnumber.setvalue(ALLTRIM(m.cOwnerID))
                  loresponse	= THIS.oqbsm.dorequests(lorequest)
                  locustresp	= loresponse.responselist.getat(0)
               ENDIF
            ELSE
               WAIT WIND NOWAIT 'Owner: ' + ALLT(m.cownname) + ' was NOT changed successfully. Code: ' + STR(locustresp.statuscode) + CHR(13) + locustresp.statusmessage
               m.cid		 = m.cOwnerID
               m.cname	 = m.cownname
               m.ctype	 = 'Owner'
               m.cmessage = locustresp.statusmessage
               m.nqberror = locustresp.statuscode
               INSERT INTO qbbadnames FROM MEMVAR
            ENDIF
         ENDIF
         lorequest.ClearRequests()
      ENDSCAN

      WAIT CLEAR
      TRY
         SET DATASESSION TO (lnDatasession)
      CATCH TO loError
      ENDTRY
   CATCH TO loError
      llError = .T.
   ENDTRY

   IF llError
      MESSAGEBOX('Unable to synchronize owners. Reason Given:' + CHR(13) + ;
         'Code: ' + TRANSFORM(loError.ERRORNO) + CHR(13) + loError.MESSAGE + CHR(13) + ;
         'Contact SherWare Support for assistance.', 48, 'Synchronize Owners')
   ENDIF

   THIS.oqbsm.EnableErrorRecovery = .F.
   RETURN (NOT llError AND NOT llSyncError)

   ENDPROC


   ***************************
   PROCEDURE sync_terms
   ***************************
   LPARAMETERS tnDataSession
   LOCAL lnDatasession, llError, llSyncError

   * Initialize the error flags
   STORE .F. TO llError, llSyncError
   * Capture any errors that happen in this method and give a message.
   TRY
      IF VARTYPE(tnDataSession) # 'N'
         tnDataSession = 1
      ENDIF

      lnDatasession = SET('datasession')

      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH TO loError
      ENDTRY

      IF NOT THIS.lqbactive
         llreturn = .F.
         EXIT
      ENDIF

      THIS.oqbsm.EnableErrorRecovery = .F.

      * get a message set request object (version 1.1 xml)
      lorequest = THIS.oqbrequest

      * set the on error attribute for the request
      lorequest.ATTRIBUTES.OnError = 1

      lorequest.ClearRequests()

      IF NOT USED('terms')
         USE terms IN 0
      ENDIF

      SWSELECT('terms')
      DELE ALL

      * add a terms query request to request message set
      lovendorquery = lorequest.AppendStandardTermsQueryRq()

      * Add terms from QuickBooks to terms table if they don't already exist
      loresponse	 = THIS.oqbsm.dorequests(lorequest)
      loTermsResp = loresponse.responselist.getat(0)

      IF loTermsResp.statuscode = 0
         FOR lni = 0 TO loTermsResp.DETAIL.COUNT - 1

            * get reference to single Terms
            loterms = loTermsResp.DETAIL.getat(lni)

            * get the value of each of the fields
            m.cidterm = loterms.listid.getvalue()
            m.cListID = loterms.listid.getvalue()
            IF VARTYPE(loterms.NAME) = 'O'
               m.cTermDesc  = PADR(ALLT(LEFT(loterms.NAME.getvalue(), 20)), 20, ' ')
            ELSE
               m.cTermDesc  = 'Unknown'
            ENDIF
            IF VARTYPE(loterms.StdDueDays) = 'O'
               m.nNetDueIn  = loterms.StdDueDays.getvalue()
            ELSE
               m.nNetDueIn  = 30
            ENDIF
            IF VARTYPE(loterms.StdDiscountDays) = 'O'
               m.nDiscIn    = loterms.StdDiscountDays.getvalue()
            ELSE
               m.nDiscIn    = 0
            ENDIF
            IF VARTYPE(loterms.DiscountPct) = 'O'
               m.nDiscPct = loterms.DiscountPct.getvalue()
            ELSE
               m.nDiscPct   = 0
            ENDIF
            m.nTermType = 3
            SET DELE OFF
            IF ALLTRIM(UPPER(m.cTermDesc)) = 'POST'  &&  Don't bring over POST terms - BH 11/12/2008
               LOOP
            ENDIF
            SELECT terms
            LOCATE FOR UPPER(cTermDesc) = UPPER(m.cTermDesc)
            IF NOT FOUND()
               INSERT INTO terms FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
               GATHER MEMVAR
            ENDIF
            SET DELE ON
         ENDFOR
      ENDIF
      TRY
         SET DATASESSION TO (lnDatasession)
      CATCH TO loError
      ENDTRY
   CATCH TO loError
      llError = .T.
   ENDTRY

   IF llError
      MESSAGEBOX('Unable to synchronize terms. Reason Given:' + CHR(13) + ;
         'Code: ' + TRANSFORM(loError.ERRORNO) + CHR(13) + loError.MESSAGE + CHR(13) + ;
         'Contact SherWare Support for assistance.', 48, 'Synchronize Terms')
   ENDIF

   THIS.oqbsm.EnableErrorRecovery = .F.

   RETURN (NOT llError AND NOT llSyncError)
   ENDPROC


   ***************************
   PROCEDURE sync_purchaser
   ***************************
   LPARAMETERS tnDataSession, tlNewOnly
   LOCAL lnDatasession, llError, llSyncError

   * Initialize the error flags
   STORE .F. TO llError, llSyncError

   LOCAL loCustMod   AS 'qbfc12.icustomermod'

   * Capture any errors in this method
   TRY
      IF VARTYPE(tnDataSession) # 'N'
         tnDataSession = 1
      ENDIF

      lnDatasession = SET('datasession')

      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH TO loError
      ENDTRY

      IF NOT THIS.lqbactive
         llreturn = .F.
         EXIT
      ENDIF

      IF NOT USED('qbbadnames')
         THIS.create_qbbadnames()
      ENDIF

      THIS.oqbsm.EnableErrorRecovery = .F.

      SET DELE ON

      * get a message set request object (version 1.1 xml)
      lorequest = THIS.oqbrequest

      * set the on error attribute for the request
      lorequest.ATTRIBUTES.OnError = 1

      lorequest.ClearRequests()

      SWSELECT('revsrc')


      CREATE CURSOR badstatus (cRevKey c(10))
      WAIT WIND NOWAIT 'Synchronizing purchaser file with QuickBooks customer file ...Please Wait'
      SWSELECT('revsrc')
      SCAN FOR NOT DELETED()  AND IIF(tlNewOnly, EMPTY(cListID), .T.)
         SCATTER MEMVAR
         IF EMPTY(m.cRevKey) OR EMPTY(m.cRevName)
            LOOP
         ENDIF

         IF ':' $ m.cRevName
            m.cRevName = STRTRAN(m.cRevName, ':', '-')
            REPLACE cRevName WITH m.cRevName
         ENDIF
         IF 'é' $ m.cRevName
            m.cRevName = STRTRAN(m.cRevName, 'é', 'e')
            REPLACE cRevName WITH m.cRevName
         ENDIF

         * add a class query request to request message set
         loCustQuery = lorequest.appendcustomerqueryrq()

         IF NOT EMPTY(m.cListID)
            * add a filter to look for the customer by listid
            loCustQuery.ORCustomerListQuery.ListIDList.ADD(m.cListID)
         ELSE
            * add a filter to the class request to look for the given well
            loCustQuery.ORCustomerListQuery.customerlistfilter.ornamefilter.namefilter.matchcriterion.setvalue(0)
            m.cRevName = STRTRAN(m.cRevName, 'é', 'e')
            loCustQuery.ORCustomerListQuery.customerlistfilter.ornamefilter.namefilter.NAME.setvalue(LEFT(m.cRevName, 41))
         ENDIF

         * process the request object returning a response message object
         loresponse = THIS.oqbsm.dorequests(lorequest)
         locustresp = loresponse.responselist.getat(0)

         IF locustresp.statuscode # 0
            * Clear inquiry request
            lorequest.ClearRequests()
            lorequest.ATTRIBUTES.OnError	= 1
            loCustAdd					= lorequest.appendcustomeraddrq()
            loCustAdd.NAME.setvalue(PADR(ALLTRIM(m.cRevName), 41, ' '))
            loCustAdd.CompanyName.setvalue(LEFT(m.cRevName, 41))
            loCustAdd.billaddress.addr1.setvalue(LEFT(m.cRevName, 41))
            loCustAdd.billaddress.addr2.setvalue(PADR(ALLTRIM(m.caddress1), 41, ' '))
            loCustAdd.billaddress.addr3.setvalue(PADR(ALLTRIM(m.caddress2), 41, ' '))
            loCustAdd.billaddress.addr4.setvalue(PADR(ALLTRIM(m.caddress3), 41, ' '))
            loCustAdd.billaddress.addr5.setvalue('')
            loCustAdd.billaddress.city.setvalue('')
            loCustAdd.billaddress.state.setvalue('')
            loCustAdd.billaddress.postalcode.setvalue('')
            loCustAdd.phone.setvalue(m.cphone)
            loCustAdd.fax.setvalue(m.cfaxphone)
            loCustAdd.accountnumber.setvalue(ALLTRIM(m.cRevKey))
            loresponse = THIS.oqbsm.dorequests(lorequest)
            locustresp = loresponse.responselist.getat(0)

            IF locustresp.statuscode = 0
               WAIT WIND NOWAIT 'Purchaser: ' + ALLT(m.cRevName) + ' was added to QuickBooks successfully as a customer.' + CHR(13) + locustresp.statusmessage
               lonewowner = locustresp.DETAIL
               m.cListID	 = lonewowner.listid.getvalue()
               SELECT revsrc
               REPLACE cListID WITH m.cListID
               THIS.ClearErrorRecovery()
            ELSE
               WAIT WIND NOWAIT 'Purchaser: ' + ALLT(m.cRevName) + ' was NOT added successfully. Code: ' + STR(locustresp.statuscode) + CHR(13) + locustresp.statusmessage
               m.cid		 = m.cRevKey
               m.cname	 = m.cRevName
               m.ctype	 = 'Purchaser'
               m.cmessage = locustresp.statusmessage
               m.nqberror = locustresp.statuscode
               INSERT INTO qbbadnames FROM MEMVAR
               llSyncError = .T.
            ENDIF
         ELSE
            locustresp = loresponse.responselist.getat(0)
            loowner	  = locustresp.DETAIL
            loownerrec = loowner.getat(0)
            m.cListID  = loownerrec.listid.getvalue()
            m.ceditseq = loownerrec.editsequence.getvalue()

            lorequest.ClearRequests()

            loCustMod = lorequest.AppendCustomerModRq
            loCustMod.listid.setvalue(m.cListID)
            loCustMod.editsequence.setvalue(m.ceditseq)
            loCustMod.NAME.setvalue(LEFT(m.cRevName, 41))
            loCustMod.billaddress.addr1.setvalue(LEFT(m.cRevName, 41))
            loCustMod.billaddress.addr2.setvalue(LEFT(m.caddress1, 41))
            loCustMod.billaddress.addr3.setvalue(LEFT(m.caddress2, 41))
            loCustMod.billaddress.addr4.setvalue(LEFT(m.caddress3, 41))
            loCustMod.billaddress.addr5.setvalue('')
            loCustMod.billaddress.city.setvalue('')
            loCustMod.billaddress.state.setvalue('')
            loCustMod.billaddress.postalcode.setvalue('')
            loCustMod.accountnumber.setvalue(ALLTRIM(m.cRevKey))
            loCustMod.CompanyName.setvalue(LEFT(m.cRevName, 41))
            loCustMod.phone.setvalue(m.cphone)
            loCustMod.fax.setvalue(m.cfaxphone)
            loresponse = THIS.oqbsm.dorequests(lorequest)

            SWSELECT('revsrc')
            REPLACE cListID WITH m.cListID
         ENDIF
         lorequest.ClearRequests()
      ENDSCAN

      WAIT CLEAR
      TRY
         SET DATASESSION TO (lnDatasession)
      CATCH TO loError
      ENDTRY
   CATCH TO loError
      llError = .T.
   ENDTRY

   IF llError
      MESSAGEBOX('Unable to synchronize purchasers. Reason Given:' + CHR(13) + ;
         'Code: ' + TRANSFORM(loError.ERRORNO) + CHR(13) + loError.MESSAGE + CHR(13) + ;
         'Contact SherWare Support for assistance.', 48, 'Synchronize Purchasers')
   ENDIF
   THIS.oqbsm.EnableErrorRecovery = .F.

   RETURN (NOT llError AND NOT llSyncError)

   ENDPROC


   *-- Checks to see if the revenue or jib runs posted successfully.
   ***************************
   PROCEDURE error_recovery
   ***************************
   LOCAL llError, llContinue

   llError	 = .F.
   llContinue = .T.
   *
   *  Checks qbpost for posted entries and matches the sysctl
   *  record for the closing to see if the posted flag has been
   *  set to true. If it hasn't, attempt to unpost from QB.
   *
   SET DELETED ON

   * Sometimes the sysctl file will be in use in another datasession
   * which causes the not used to return .t. Then the USE will error
   * because the file is already in use. Put in this error checking
   * to avoid that.
   TRY
      * Changed to use swselect so that the full path get's used
      SWSELECT('sysctl')
   CATCH
      llError = .T.
   ENDTRY

   IF llError
      RETURN
   ENDIF

   SWSELECT('qbpost')

   * Check sysctl for unposted runs
   SELECT sysctl
   SCAN FOR lposted = .F. AND INLIST(cTypeClose, 'R', 'J') AND NOT EMPTY(cVersion)
      m.cidsysctl  = cidsysctl
      m.cTypeClose = cTypeClose
      m.nrunno	  = nrunno
      m.crunyear	  = crunyear
      m.dacctdate  = dacctdate
      SELECT qbpost
      LOCATE FOR cidsysctl == m.cidsysctl
      IF FOUND()
         IF FILE('datafiles\partialqb.cfg')
            IF MESSAGEBOX('There are partial run closings that need to be cleaned up in QuickBooks. Do you want let ths processing continue?', 36, 'Remove Partial Runs') = 7
               llContinue = .F.
            ENDIF
         ENDIF
         IF llContinue
            * Let the user know we found posting problems
            IF m.cTypeClose = 'R'
               MESSAGEBOX('A problem was found with a revenue run posting to QuickBooks.' + CHR(13) + ;
                  'Run: ' + TRANSFORM(m.nrunno) + '/' + m.crunyear + ' Dated: ' + DTOC(m.dacctdate) + CHR(13) + ;
                  'was partially posted. The error recovery system will attempt to remove' + CHR(13) + ;
                  'the partial posting from QuickBooks.', 48, 'QuickBooks Posting Error Recovery')
            ELSE
               MESSAGEBOX('A problem was found with a JIB run posting to QuickBooks.' + CHR(13) + ;
                  'Run: ' + TRANSFORM(m.nrunno) + '/' + m.crunyear + ' Dated: ' + DTOC(m.dacctdate) + CHR(13) + ;
                  'was partially posted. The error recovery system will attempt to remove' + CHR(13) + ;
                  'the partial posting from QuickBooks.', 48, 'QuickBooks Posting Error Recovery')
            ENDIF
            * Check for records in qbpost
            SELECT qbpost
            SCAN FOR cidsysctl == m.cidsysctl
               THIS.csysctlkey = m.cidsysctl
               IF m.cTypeClose = 'J'
                  THIS.qbunpostjib()
               ELSE
                  THIS.qbunpostrev()
               ENDIF
            ENDSCAN
            * Delete the qbpost entry
            SELECT qbpost
            DELETE FOR cidsysctl == m.cidsysctl
         ENDIF
      ENDIF
   ENDSCAN

   * Check qbpost for entries not associated with a valid run closing
   *
   * Ignore qbpost records where cidsysctl starts with an 'E' or 'I'. These came from
   * Well Expenses by Well or Well Revenue by Well instead of a Revenue Run posting.
   SELECT  cidsysctl ;
      FROM qbpost ;
      WHERE lposted = .F. ;
      AND cidsysctl NOT IN (SELECT  cidsysctl ;
      FROM sysctl) ;
      AND LEFT(cidsysctl, 1) # 'E' ;
      AND LEFT(cidsysctl, 1) # 'I' ;
      INTO CURSOR temp ;
      ORDER BY cidsysctl ;
      GROUP BY cidsysctl
   IF _TALLY > 0
      llContinue = .T.
      IF FILE('datafiles\partialqb.cfg')
         IF MESSAGEBOX('There are partial run closings that need to be cleaned up in QuickBooks. Do you want let ths processing continue?', 36, 'Remove Partial Runs') = 7
            llContinue = .F.
         ENDIF
      ENDIF
      IF llContinue
         WAIT WINDOW NOWAIT 'Cleaning up partial/invalid run closings from QuickBooks...'
         SELECT temp
         SCAN
            THIS.csysctlkey = cidsysctl
            THIS.qbunpostrev(.T.)
         ENDSCAN
         SELECT temp
         SCAN
            THIS.csysctlkey = cidsysctl
            THIS.qbunpostjib(.T.)
         ENDSCAN
         SELECT temp
         SCAN
            * Remove the entries from qbpost
            SELECT qbpost
            DELETE FOR cidsysctl = temp.cidsysctl
         ENDSCAN
      ENDIF
   ENDIF
   ENDPROC

   ***************************
   PROCEDURE omessage_access
   ***************************
   *To do: Modify this routine for the Access method

   IF TYPE('this.omessage') # 'O'
      THIS.omessage = findglobalobject('cmmessage')
   ENDIF
   RETURN THIS.omessage
   ENDPROC


   ***************************
   PROCEDURE oregistry_access
   ***************************
   *To do: Modify this routine for the Access method
   IF TYPE('this.oregistry') # 'O'
      THIS.oregistry = findglobalobject('cmregistry')
   ENDIF
   RETURN THIS.oregistry
   ENDPROC

   ***************************
   PROCEDURE open_files
   ***************************
   *
   * Opens all the files needed, if not open already
   *
   ENDPROC


   ***************************
   PROCEDURE ndatasession_assign
   ***************************
   LPARAMETERS vNewVal
   *To do: Modify this routine for the Assign method
   THIS.ndatasession = m.vNewVal
   SET DATASESSION TO m.vNewVal
   ENDPROC

   ***************************
   PROCEDURE QBInstalled
   ***************************
   *
   * Checks to see if a registry key exists that shows
   * QuickBooks as being installed.
   *
   m.goapp.lQBInstalled = .F.

   IF FILE(m.goapp.cCommonFolder + 'ignoreqbver.txt')
      m.goapp.lQBInstalled = .T.
   ENDIF

   loReg = NEWOBJECT('Registry', HOME() + 'FFC\Registry.VCX')

   lcKey10 = "SOFTWARE\Intuit\QuickBooks\10.0"
   lcKey12 = "SOFTWARE\Intuit\QuickBooks\12.0"
   lcKey13 = "SOFTWARE\Intuit\QuickBooks\13.0"
   lcKey15 = "SOFTWARE\Intuit\QuickBooks\15.0"
   lcKey16 = "SOFTWARE\Intuit\QuickBooks\16.0"
   lcKey17 = "SOFTWARE\Intuit\QuickBooks\17.0"
   lcKey18 = "SOFTWARE\Intuit\QuickBooks\18.0"
   lcKey19 = "SOFTWARE\Intuit\QuickBooks\19.0"
   lcKey20 = "SOFTWARE\Intuit\QuickBooks\20.0"
   lcKey21 = "SOFTWARE\Intuit\QuickBooks\21.0"
   lcKey22 = "SOFTWARE\Intuit\QuickBooks\22.0"
   lcKey23 = "SOFTWARE\Intuit\QuickBooks\23.0"
   lcKey24 = "SOFTWARE\Intuit\QuickBooks\24.0"
   lcKey25 = "SOFTWARE\Intuit\QuickBooks\25.0"
   lcKey26 = "SOFTWARE\Intuit\QuickBooks\26.0"
   lcKey27 = "SOFTWARE\Intuit\QuickBooks\27.0"
   lcKey28 = "SOFTWARE\Intuit\QuickBooks\28.0"
   lcKey29 = "SOFTWARE\Intuit\QuickBooks\29.0"
   lcKey30 = "SOFTWARE\Intuit\QuickBooks\30.0"
   lcKey31 = "SOFTWARE\Intuit\QuickBooks\31.0"
   lcKey32 = "SOFTWARE\Intuit\QuickBooks\32.0"
   lcKey33 = "SOFTWARE\Intuit\QuickBooks\33.0"
   lcKey34 = "SOFTWARE\Intuit\QuickBooks\34.0"
   lcKey35 = "SOFTWARE\Intuit\QuickBooks\35.0"

   DO CASE
      CASE loReg.iskey(lcKey35, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey34, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey33, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey32, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey31, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey30, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey29, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey28, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey27, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey26, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey25, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey24, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey23, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey22, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey21, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey20, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey19, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey18, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey17, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey16, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey15, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey13, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey12, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

      CASE loReg.iskey(lcKey10, HKEY_CURRENT_USER)
         m.goapp.lQBInstalled = .T.

   ENDCASE

   IF NOT m.goapp.lQBInstalled
      IF DIRECTORY("\Program Files\Common Files\Intuit\QuickBooks")
         m.goapp.lQBInstalled = .T.
      ELSE
         IF DIRECTORY("\Program Files (x86)\Common Files\Intuit\QuickBooks")
            m.goapp.lQBInstalled = .T.
         ENDIF
      ENDIF
   ENDIF

   RETURN (m.goapp.lQBInstalled)
   ENDPROC


   *-- Check to see if we're in error recovery status. If so, get the status code from the last request and if it finished ok, delete it.
   ***************************
   PROCEDURE check_error_recovery
   ***************************
   *
   * Check to see if there's unprocessed responses and clear
   *
   TRY
      IF THIS.oqbsm.IsErrorRecoveryInfo()
         IF NOT THIS.lerror_recovery_error
            * Get the last response we missed
            loresp = THIS.oqbsm.geterrorrecoverystatus()
            IF VARTYPE(loresp.responselist) = 'O'
               loresponse = loresp.responselist.getat(0)
               * If the previous request was successful, let's do it again to get the real response
               IF loresponse.statuscode = 0
                  lorequest = THIS.oqbsm.getsavedmsgsetrequest()
                  THIS.oqbsm.ClearErrorRecovery()
                  loresponse = THIS.oqbsm.dorequests(lorequest)
                  IF VARTYPE(loresponse.responselist)  = 'O'
                     loresp = loresponse.responselist.getat(0)
                     * If our 2nd request was successful, we can get the original response
                     IF loresp.statuscode = 0
                        loTrans	= loresp.DETAIL
                        loTranso	= loTrans.getat(0)
                        * Get the transaction id so we can delete it
                        IF VARTYPE(loTranso) = 'O'
                           IF VARTYPE(loTranso.txnid) = 'O'
                              lcTxnID  = loTranso.txnid.getvalue()
                              lorequest.ClearRequests()
                              * Since we're not sure what version we're at, let's try deleting
                              * journal entries and checks from pre QBFC4 and after.
                              lnJournal1	= 15
                              lnCheck1	= 6
                              lnJournal2	= 14
                              lnCheck2	= 11
                              loTransDel	= lorequest.AppendTxnDelRq()
                              loTransDel.TxnDelType.setvalue(lnJournal1)
                              loTransDel.txnid.setvalue(lcTxnID)
                              loTransDel = lorequest.AppendTxnDelRq()
                              loTransDel.TxnDelType.setvalue(lnCheck1)
                              loTransDel.txnid.setvalue(lcTxnID)
                              loTransDel = lorequest.AppendTxnDelRq()
                              loTransDel.TxnDelType.setvalue(lnJournal2)
                              loTransDel.txnid.setvalue(lcTxnID)
                              loTransDel = lorequest.AppendTxnDelRq()
                              loTransDel.TxnDelType.setvalue(lnCheck2)
                              loTransDel.txnid.setvalue(lcTxnID)
                              loresponse	= THIS.oqbsm.dorequests(lorequest)
                              loDelResp	= loresponse.responselist.getat(0)
                           ENDIF
                        ENDIF
                        lorequest.ClearRequests()
                     ENDIF
                  ENDIF
               ELSE
                  * The previous request didn't succeed, so don't worry about it.
                  * Clear out the error recovery info so we can continue.
                  THIS.oqbsm.ClearErrorRecovery()
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   CATCH TO loError
   ENDTRY

   ENDPROC

   ***************************
   PROCEDURE qbpostsuspense
   ***************************
   LPARA tcdmbatch
   LOCAL tcyear, tcperiod, tdcheckdate, tcgroup, tdPostdate
   LOCAL lnmax, lncount, lntotal, lcname, lnjibinv, m.ccustname, lcdmbatch, llsepclose
   LOCAL lcRevClear, lcSuspense, m.cdisbacct, m.cvendcomp, m.cgathacct, m.cbackwith
   LOCAL llintegcomp, llsepclose, lcAPAcct, lcacctyear, lcacctmonth, lcidchec
   LOCAL loresponse, lnJournal, lnCheck

   IF THIS.lerrorflag
      RETURN .F.
   ENDIF

   THIS.cdmbatch = tcdmbatch

   * Choose the correct txndeltype depending on the SDK.
   IF THIS.qbfcversion > QBFCVER
      lnJournal = 15
      lnCheck   = 6
   ELSE
      lnJournal = 14
      lnCheck   = 11
   ENDIF

   SWSELECT('sysctl')
   LOCATE FOR cdmbatch = tcdmbatch
   IF FOUND()
      THIS.csysctlkey = cidsysctl
      m.cidsysctl	 = cidsysctl
   ELSE
      THIS.omessage.severe('The closing control information cannot be found...')
      RETURN
   ENDIF

   IF m.goapp.lPartnershipMod
      SWSELECT('progopt')
      GO TOP
      llJVPosting = lJVPosting
      lcCapitalAcct = cCapAcct
   ELSE
      llJVPosting = .F.
      lcCapitalAcct = lcSuspense
   ENDIF

   * set the on error attribute for the request
   THIS.oqbrequest.ATTRIBUTES.OnError = 1

   * Clear any previous requests
   THIS.oqbrequest.ClearRequests()

   lnmax		  = 0
   lncount	  = 0
   lntotal	  = 0
   lcname	  = 'Owner'
   m.ccustname = ' '
   lcidchec	  = ''

   lcacctyear  = STR(YEAR(THIS.dpostdate), 4)
   lcacctmonth = PADL(ALLTRIM(STR(MONTH(THIS.dpostdate), 2)), 2, '0')

   tdCompanyPost	= THIS.dpostdate
   tdPostdate	= THIS.dpostdate

   *
   *  Get the suspense account from glopt
   *
   SWSELECT('glopt')
   IF NOT llJVPosting
      lcRevClear = crevclear
      lcExpClear = cexpclear
   ELSE
      STORE lcCapitalAcct TO lcRevClear, lcExpClear
   ENDIF

   llQBPost	 = NOT ldmnopost
   lcSuspense = csuspense

   IF EMPTY(lcRevClear)
      MESSAGEBOX('The revenue clearing account needs to be specified in Account Settings ' + ;
         'please specify the account and then close the revenue period again.', 0, 'Setup Problem')
      RETURN .F.
   ENDIF
   IF EMPTY(lcExpClear)
      MESSAGEBOX('The expense clearing account needs to be specified in Account Settings ' + ;
         'please specify the account and then close the revenue period again.', 0, 'Setup Problem')
      RETURN .F.
   ENDIF

   *
   *  Get the A/P account
   *
   SWSELECT('apopt')
   lcAPAcct = cAPAcct

   *
   *  Set up the parameters used by processing in this method
   *
   tcyear   = THIS.crunyear
   tcperiod = THIS.cperiod
   tcgroup  = THIS.cgroup

   IF EMPTY(lcSuspense)
      MESSAGEBOX('The "Catch-All" account has not been specified in the Account Defaults.  Please specify a catch-all account before continuing.', 0, 'Account Problem')
      RETURN .F.
   ENDIF

   *  Open the QB Transaction Table
   SWSELECT('qbpost')

   ****************************************************************
   *   Get Disbursement Checking Acct Number
   ****************************************************************
   SWSELECT('options')
   GO TOP
   m.cdisbacct = cdisbacct
   IF EMPTY(ALLT(m.cdisbacct))
      m.cdisbacct = lcSuspense
   ENDIF
   m.cvendcomp = cvendcomp
   IF EMPTY(ALLT(m.cvendcomp))
      m.cvendcomp = lcSuspense
   ENDIF
   m.cgathacct = cgathacct
   IF EMPTY(ALLT(m.cgathacct))
      m.cgathacct = lcSuspense
   ENDIF
   m.cbackwith = cbackacct
   IF EMPTY(ALLT(m.cbackwith))
      m.cbackwith = lcSuspense
   ENDIF
   m.ctaxwith = ctaxacct
   IF EMPTY(ALLT(m.ctaxwith))
      m.ctaxwith = lcSuspense
   ENDIF
   m.ctaxacct1  = ctaxacct1
   IF EMPTY(ALLT(m.ctaxacct1))
      m.ctaxacct1 = lcSuspense
   ENDIF
   m.ctaxacct2  = ctaxacct2
   IF EMPTY(ALLT(m.ctaxacct2))
      m.ctaxacct2 = lcSuspense
   ENDIF
   m.ctaxacct3  = ctaxacct3
   IF EMPTY(ALLT(m.ctaxacct3))
      m.ctaxacct3 = lcSuspense
   ENDIF
   m.ctaxacct4 = ctaxacct4
   IF EMPTY(ALLT(m.ctaxacct4))
      m.ctaxacct4 = lcSuspense
   ENDIF
   m.cdefacct  = cdefacct
   IF EMPTY(ALLT(m.cdefacct))
      m.cdefacct = lcSuspense
   ENDIF
   m.cminacct  = cminacct
   IF EMPTY((m.cminacct))
      m.cminacct = lcSuspense
   ENDIF

   *  Get the account fixed expenses and well expenses by well expenses are to be posted to.
   lcdmexp = cfixedacct
   IF EMPTY(lcdmexp)
      lcdmexp = lcAPAcct
   ENDIF

   llsepclose  = .T.

   ******************************************************************
   *   Check to see if vendor compression & gathering is to be posted
   ******************************************************************
   llintegcomp = .F.

   IF NOT EMPTY(m.cvendcomp)
      SWSELECT('vendor')
      SET ORDER TO cVendorID
      IF SEEK(m.cvendcomp)
         IF linteggl
            llintegcomp = .T.
         ENDIF
      ENDIF
   ENDIF

   * Plug 'DM' into the reference for journal entries

   lcref = 'DM-' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear

   *********************************************************************
   *   Post owner amounts to G/L
   *********************************************************************
   SWSELECT('wells')
   SET ORDER TO cWellID

   IF m.goapp.oQB.lqbactive AND llQBPost

      IF NOT llJVPosting
         CREATE CURSOR tmpowners ;
            (cOwnerID   c(10), ;
            cWellID    c(10), ;
            ctypeinv   c(1), ;
            ntotal     N(12, 2),  ;
            ntotinc    N(12, 2),  ;
            noilrev    N(12, 2), ;
            ngasrev    N(12, 2), ;
            ntotexp    N(12, 2),  ;
            ntottax    N(12, 2))

         * Get a cursor of owners to be posted from suspense
         * Compare nrunno_in and crunyear_in to the current runnno because they contain the original runno for when the
         * item went into suspense
         * Don't include any payment record types
         SELECT  cOwnerID, ;
            cWellID, ;
            ctypeinv, ;
            cdirect, ;
            SUM(noilrev) AS noilrev, ;
            SUM(ngasrev) AS ngasrev, ;
            SUM(nnetcheck) AS ntotal, ;
            SUM(nincome) AS ntotinc, ;
            SUM(nexpense) AS ntotexp, ;
            SUM(nsevtaxes) AS ntottax  ;
            FROM suspense WITH (BUFFERING = .T.) ;
            WHERE crectype # 'P' ;
            AND nrunno_in = THIS.nrunno ;
            AND crunyear_in = THIS.crunyear ;
            AND lManual = .F. ;
            ORDER BY cOwnerID, cWellID, ctypeinv ;
            GROUP BY cOwnerID, cWellID, ctypeinv ;
            INTO CURSOR tmp1

         lnmax = _TALLY

         SELECT  cOwnerID, ;
            cWellID, ;
            ctypeinv, ;
            cdirect, ;
            SUM(noilrev) AS noilrev, ;
            SUM(ngasrev) AS ngasrev, ;
            SUM(nnetcheck) AS ntotal, ;
            SUM(nincome) AS ntotinc, ;
            SUM(nexpense) AS ntotexp, ;
            SUM(nsevtaxes) AS ntottax  ;
            FROM disbhist WITH (BUFFERING = .T.) ;
            WHERE nrunno_in = THIS.nrunno ;
            AND crunyear_in = THIS.crunyear ;
            AND crectype # 'P';
            AND lManual = .F. ;
            ORDER BY cOwnerID, cWellID, ctypeinv ;
            GROUP BY cOwnerID, cWellID, ctypeinv ;
            INTO CURSOR tmp2

         lnmax = lnmax + _TALLY

         IF lnmax > 0
            SELE tmpowners
            APPEND FROM DBF('tmp1')
            APPEND FROM DBF('tmp2')
         ENDIF

      ELSE
         CREATE CURSOR tmpowners ;
            (cOwnerID   c(10), ;
            nnetcheck  N(12,2))

         * Get a cursor of owners to be posted from suspense
         * Compare nrunno_in and crunyear_in to the current runnno because they contain the original runno for when the
         * item went into suspense
         * Don't include any payment record types
         SELECT  cOwnerID, ;
            SUM(nnetcheck) AS nnetcheck ;
            FROM suspense WITH (BUFFERING = .T.) ;
            WHERE crectype # 'P' ;
            AND nrunno_in = THIS.nrunno ;
            AND crunyear_in = THIS.crunyear ;
            AND lManual = .F. ;
            ORDER BY cOwnerID;
            GROUP BY cOwnerID;
            INTO CURSOR tmp1

         lnmax = _TALLY

         SELECT  cOwnerID, ;
            SUM(nnetcheck) AS nnetcheck ;
            FROM disbhist WITH (BUFFERING = .T.) ;
            WHERE nrunno_in = THIS.nrunno ;
            AND crunyear_in = THIS.crunyear ;
            AND crectype # 'P';
            AND lManual = .F. ;
            ORDER BY cOwnerID ;
            GROUP BY cOwnerID ;
            INTO CURSOR tmp2

         lnmax = lnmax + _TALLY

         IF lnmax > 0
            SELE tmpowners
            APPEND FROM DBF('tmp1')
            APPEND FROM DBF('tmp2')
         ENDIF
      ENDIF

      INDEX ON cOwnerID TAG owner


      lncount = 1

      IF NOT THIS.lquiet
         THIS.oprogress = THIS.omessage.progressbarex('Posting owner amounts to QuickBooks...', ' ')
         THIS.oprogress.setprogressrange(0, lnmax)
      ENDIF

      * Scan through the owners in suspense for this run
      SELECT tmpowners
      SCAN
         SCATTER MEMVAR

         IF NOT llJVPosting
            IF m.cdirect = 'O'
               m.ntotinc = m.ntotinc - m.noilrev
            ENDIF
            IF m.cdirect = 'G'
               m.ntotinc = m.ntotinc - m.ngasrev
            ENDIF
            IF m.cdirect = 'B'
               m.ntotinc = m.ntotinc - m.ngasrev - m.noilrev
            ENDIF

            IF m.ntotinc = 0 AND m.ntotal = 0 AND m.ntotexp = 0 AND m.ntottax = 0
               LOOP
            ENDIF
         ELSE
            IF m.nnetcheck = 0
               LOOP
            ENDIF
            STORE '' TO m.cWellID, m.ctypeinv
         ENDIF

         THIS.oqbrequest.ClearRequests()
         * set the on error attribute for the request
         THIS.oqbrequest.ATTRIBUTES.OnError = 1

         * Setup the counters for debits and credits so we can post any difference
         * To the catch-all account so we don't try to post out of balance entries - pws 3/9/2007
         STORE 0 TO lndebits, lncredits

         lnBalance = 0

         m.lExempt	 = .F.
         m.lDirectDep = .F.

         * Check the owner to make sure they've been synch'd with QB and that
         * they're not a posting or dummy owner.
         SWSELECT('investor')
         SET ORDER TO cOwnerID
         IF SEEK(m.cOwnerID)
            m.cownname	 = cownname
            lcownerlistid = cListID
            m.lExempt	 = lExempt
            m.lDirectDep	 = lDirectDep
            IF NOT THIS.lquiet
               THIS.oprogress.SetProgressMessage(ALLT(m.cOwnerID) + ' - ' + ALLT(m.cownname))
               THIS.oprogress.updateprogress(lncount)
               lncount = lncount + 1
            ENDIF
            IF EMPTY(cListID)
               MESSAGEBOX('The owner file needs to be synchronized with QuickBooks. ' + ;
                  'please synchronize and then close the revenue period again.', 0, 'Synchronization Problem')
               RETURN .F.
            ENDIF
            * Don't post "Dummy" owner amounts
            IF lDummy
               LOOP
            ENDIF
            * Don't post owners that are transfered to G/L here.
            IF linteggl
               LOOP
            ENDIF
         ELSE
            LOOP
         ENDIF

         *  Set the post flag
         llpostqb = .F.

         *  Setup the journal add request
         loentryadd = THIS.oqbrequest.appendjournalentryaddrq()
         loentryadd.txndate.setvalue(tdPostdate)
         loentryadd.refnumber.setvalue(lcref)

         m.cidchec	 = ' '
         llPostInvTmp = .F.
         STORE 0 TO lnolddef

         * Scan through the suspense table posting each record put into suspense during this run.
         SWSELECT('suspense')

         llreturn = THIS.qbpostsusp(m.cOwnerID, m.cWellID, m.ctypeinv)
         IF NOT llreturn
            RETURN .F.
         ENDIF

         * Get a list of the suspense from this run that already been released to disbhist
         IF NOT llJVPosting
            SELECT  * ;
               FROM disbhist WITH (BUFFERING = .T.) ;
               WHERE crectype # 'P' ;
               AND nrunno_in = THIS.nrunno ;
               AND crunyear_in = THIS.crunyear ;
               AND cOwnerID = m.cOwnerID ;
               AND cWellID = m.cWellID ;
               AND ctypeinv = m.ctypeinv ;
               AND lManual = .F. ;
               INTO CURSOR relsusp
            llreturn = THIS.qbpostsusp(m.cOwnerID, m.cWellID, m.ctypeinv)
         ELSE
            SELECT  cOwnerID, hyear, hperiod, csusptype, SUM(nnetcheck) AS nnetcheck ;
               FROM disbhist WITH (BUFFERING = .T.) ;
               WHERE crectype # 'P' ;
               AND nrunno_in = THIS.nrunno ;
               AND crunyear_in = THIS.crunyear ;
               AND cOwnerID = m.cOwnerID ;
               AND cWellID = m.cWellID ;
               AND ctypeinv = m.ctypeinv ;
               AND lManual = .F. ;
               INTO CURSOR relsusp ;
               GROUP BY cOwnerID, csusptype

            IF relsusp.nnetcheck # 0
               llreturn = THIS.qbpostsusp(m.cOwnerID, m.cWellID, m.ctypeinv)
            ENDIF
         ENDIF


         IF NOT llreturn
            RETURN .F.
         ENDIF

         IF llpostqb
            * llPostQB is set when there was any activity found in the
            * processing above. This tells us we have info to post to QB.
            * It keeps us from posting empty journal entries.
            lcxml = THIS.oqbrequest.toxmlstring()
            This.savexml(m.cownerid, lcXML)

            loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
            loaddresp  = loresponse.responselist.getat(0)

            IF loaddresp.statuscode # 0
               lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
               llResult = m.goapp.oQB.QBListID(lcListID)
               IF llResult
                  MESSAGEBOX('The QuickBooks unique ID attached to ' + ALLTRIM(QBListID.cdescription) + ;
                     ' does not exist in QuickBooks. Please fix and try again.',0,'QuickBooks Posting Error')
               ELSE
                  MESSAGEBOX(loaddresp.statusmessage, 0, 'QuickBooks Posting Error')
               ENDIF
               TRY
                  IF VARTYPE(THIS.oprogress) = 'O'
                     THIS.oprogress.closeprogress()
                  ENDIF
               CATCH
               ENDTRY
               THIS.ClearErrorRecovery()
               RETURN .F.
            ELSE
               TRY
                  lonewbill = loaddresp.DETAIL
                  m.ctxnid  = lonewbill.txnid.getvalue()
                  THIS.ClearErrorRecovery()
                  SWSELECT('qbpost')
                  LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnJournal
                  IF NOT FOUND()
                     m.ntype	  = lnJournal
                     m.mtxnids = m.ctxnid
                     INSERT INTO qbpost FROM MEMVAR
                  ELSE
                     IF NOT EMPTY(ALLT(mtxnids))
                        REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
                     ELSE
                        REPL mtxnids WITH m.ctxnid
                     ENDIF
                  ENDIF
               CATCH
               ENDTRY
            ENDIF
         ENDIF
         THIS.oqbrequest.ClearRequests()
      ENDSCAN

      *******************************************************
      * Post suspense amounts that are moving between deficit
      * and minimum suspense.
      *******************************************************
      llpostqb = .F.
      THIS.oqbrequest.ClearRequests()
      * set the on error attribute for the request
      THIS.oqbrequest.ATTRIBUTES.OnError = 1
      IF NOT USED('baltransfer')
         IF VARTYPE(oSuspense) # 'O'
            oSuspense = CREATEOBJECT('suspense')
         ENDIF
         oSuspense.crunyear = THIS.crunyear
         oSuspense.nrunno   = THIS.nrunno
         oSuspense.cgroup   = THIS.cgroup
         * Post amounts transfering between deficit and minimum
         * Get the amount of deficits that transferred
         lnDefSwitch = oSuspense.GetBalTransfer('D', .T.)
         * Get the amount of minimums that transferred
         lnMinSwitch = oSuspense.GetBalTransfer('M', .T.) * -1


         IF USED('baltransfer')
            SELECT baltransfer
            SCAN FOR ctype = 'D'
               SCATTER MEMVAR
               SWSELECT('investor')
               SET ORDER TO cOwnerID
               IF SEEK(m.cOwnerID)
                  lcownerlistid = cListID
               ELSE
                  lcownerlistid = ''
               ENDIF
               SWSELECT('wells')
               SET ORDER TO cWellID
               IF SEEK(m.cWellID)
                  lcwelllistid = cListID
               ELSE
                  lcwelllistid = ''
               ENDIF
               loentryadd = THIS.oqbrequest.appendjournalentryaddrq()
               loentryadd.txndate.setvalue(tdPostdate)
               loentryadd.refnumber.setvalue('DM-' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear)

               lnamount = m.namount * -1
               IF lnamount < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(lnamount)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(lnamount)
               ENDIF
               llpostqb = .T.
               IF NOT EMPTY(lcwelllistid)
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               IF NOT EMPTY(lcownerlistid)
                  loentry.entityref.listid.setvalue(lcownerlistid)
               ENDIF
               loentry.accountref.listid.setvalue(m.cminacct)
               loentry.amount.setvalue(ABS(m.namount))
               loentry.MEMO.setvalue('Deficit to Minimum')

               IF m.namount < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.namount)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.namount)
               ENDIF
               llpostqb = .T.
               IF NOT EMPTY(lcwelllistid)
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               IF NOT EMPTY(lcownerlistid)
                  loentry.entityref.listid.setvalue(lcownerlistid)
               ENDIF
               loentry.accountref.listid.setvalue(m.cdefacct)
               loentry.amount.setvalue(ABS(m.namount))
               loentry.MEMO.setvalue('Deficit to Minimum')
               llpostqb = .T.
            ENDSCAN


            SELECT baltransfer
            SCAN FOR ctype = 'M'
               SCATTER MEMVAR
               SWSELECT('investor')
               SET ORDER TO cOwnerID
               IF SEEK(m.cOwnerID)
                  lcownerlistid = cListID
               ELSE
                  lcownerlistid = ''
               ENDIF
               SWSELECT('wells')
               SET ORDER TO cWellID
               IF SEEK(m.cWellID)
                  lcwelllistid = cListID
               ELSE
                  lcwelllistid = ''
               ENDIF

               loentryadd = THIS.oqbrequest.appendjournalentryaddrq()
               loentryadd.txndate.setvalue(tdPostdate)
               loentryadd.refnumber.setvalue('DM-' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear)

               IF m.namount > 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.namount)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.namount)
               ENDIF
               llpostqb = .T.
               IF NOT EMPTY(lcwelllistid)
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               IF NOT EMPTY(lcownerlistid)
                  loentry.entityref.listid.setvalue(lcownerlistid)
               ENDIF
               loentry.accountref.listid.setvalue(m.cminacct)
               loentry.amount.setvalue(ABS(m.namount))
               loentry.MEMO.setvalue('Minimum to Deficit')

               lnamount = m.namount * -1
               IF lnamount > 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(lnamount)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(lnamount)
               ENDIF
               llpostqb = .T.
               IF NOT EMPTY(lcwelllistid)
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               IF NOT EMPTY(lcownerlistid)
                  loentry.entityref.listid.setvalue(lcownerlistid)
               ENDIF
               loentry.accountref.listid.setvalue(m.cdefacct)
               loentry.amount.setvalue(ABS(lnamount))
               loentry.MEMO.setvalue('Minimum to Deficit')
               llpostqb = .T.
            ENDSCAN
         ENDIF
      ENDIF

      IF llpostqb
         * llPostQB is set when there was any activity found in the
         * processing above. This tells us we have info to post to QB.
         * It keeps us from posting empty journal entries.
         lcxml = THIS.oqbrequest.toxmlstring()
         THIS.SaveXML(m.cownerid, lcXML)

         loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
         loaddresp  = loresponse.responselist.getat(0)

         IF loaddresp.statuscode # 0
            lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
            llResult = m.goapp.oQB.QBListID(lcListID)
            IF llResult
               MESSAGEBOX('The QuickBooks unique ID attached to ' + ALLTRIM(QBListID.cdescription) + ;
                  ' does not exist in QuickBooks. Please fix and try again.',0,'QuickBooks Posting Error')
            ELSE
               MESSAGEBOX(loaddresp.statusmessage, 0, 'QuickBooks Posting Error')
            ENDIF
            TRY
               IF VARTYPE(THIS.oprogress) = 'O'
                  THIS.oprogress.closeprogress()
               ENDIF
            CATCH
            ENDTRY
            THIS.ClearErrorRecovery()
            RETURN .F.
         ELSE
            loNewEntry = loaddresp.DETAIL
            m.ctxnid	  = loNewEntry.txnid.getvalue()
            THIS.ClearErrorRecovery()
            SWSELECT('qbpost')
            LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnJournal
            IF NOT FOUND()
               m.ntype	= lnJournal
               m.mtxnids	= m.ctxnid
               INSERT INTO qbpost FROM MEMVAR
            ELSE
               IF NOT EMPTY(ALLT(mtxnids))
                  REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
               ELSE
                  REPL mtxnids WITH m.ctxnid
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      THIS.oqbrequest.ClearRequests()

      IF NOT THIS.lquiet
         IF VARTYPE(THIS.oprogress) = 'O'
            THIS.oprogress.closeprogress()
         ENDIF

         DOEVENTS
         THIS.oprogress = .NULL.
      ENDIF

      THIS.oqbrequest.ClearRequests()
   ENDIF
   ENDPROC

   ***************************
   PROCEDURE qbpostsusp
   ***************************
   LPARAMETERS tcownerid, tcwellid, tctypeinv
   LOCAL lndebits, lncredits

   STORE 0 TO lndebits, lncredits
   m.csusptype = ' '
   lcalias	  = ALIAS()

   SWSELECT('investor')
   SET ORDER TO cOwnerID
   IF SEEK(tcownerid)
      lcownerlistid = cListID
   ELSE
      MESSAGEBOX('Invalid Owner ID passed to suspense posting.',16,'Post Revenue Run to QB')
      RETURN .F.
   ENDIF

   *
   *  Get the suspense account from glopt
   *
   SWSELECT('glopt')
   IF NOT llJVPosting
      lcRevClear = crevclear
      lcExpClear = cexpclear
   ELSE
      STORE lcCapitalAcct TO lcRevClear, lcExpClear
   ENDIF
   llQBPost	 = NOT ldmnopost
   lcSuspense = glopt.csuspense

   *  Make sure tax backup withholding accounts are selected.
   SWSELECT('options')
   GO TOP
   m.cbackwith = cbackacct
   IF EMPTY(ALLT(m.cbackwith))
      m.cbackwith = lcSuspense
   ENDIF
   m.cdefacct = cdefacct
   IF EMPTY(m.cdefacct)
      m.cdefacct = lcSuspense
   ENDIF
   m.cminacct = cminacct
   IF EMPTY(m.cminacct)
      m.cminacct = lcSuspense
   ENDIF
   m.ctaxwith = ctaxacct
   IF EMPTY(ALLT(m.ctaxwith))
      m.ctaxwith = lcSuspense
   ENDIF

   IF m.goapp.lPartnershipMod
      SWSELECT('progopt')
      GO TOP
      llJVPosting = lJVPosting
      lcCapitalAcct = cCapAcct
   ELSE
      llJVPosting = .F.
      lcCapitalAcct = lcSuspense
   ENDIF

   m.cOwnerID = tcownerid
   m.cWellID	 = tcwellid
   m.ctypeinv = tctypeinv

   IF llJVPosting

      SELECT cOwnerID, hyear, hperiod, csusptype, SUM(nnetcheck) AS nnetcheck ;
         FROM (lcalias) ;
         WHERE nrunno_in = THIS.nrunno AND crunyear_in = THIS.crunyear ;
         AND cOwnerID = m.cOwnerID ;
         INTO CURSOR jvposting ;
         GROUP BY cOwnerID, csusptype ;
         ORDER BY cOwnerID, csusptype

      IF jvposting.nnetcheck # 0
         IF jvposting.csusptype = 'D'
            lcPostingAcct = m.cdefacct
         ELSE
            lcPostingAcct = m.cminacct
         ENDIF
         IF jvposting.nnetcheck < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
         ENDIF
         llpostqb = .T.
         IF NOT EMPTY(THIS.cCheckMemo)
            loentry.MEMO.setvalue(THIS.cCheckMemo)
         ELSE
            loentry.MEMO.setvalue(getmonth(m.hperiod) + ' ' + m.hyear + ' ' + STRTRAN(m.goapp.cCompanyName,'GCW ','') + ' Distribution')
         ENDIF
         loentry.amount.setvalue(ABS(jvposting.nnetcheck))
         loentry.entityref.listid.setvalue(lcownerlistid)
         loentry.accountref.listid.setvalue(lcPostingAcct)

         IF jvposting.nnetcheck < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
         ENDIF

         llpostqb = .T.
         loentry.MEMO.setvalue(getmonth(jvposting.hperiod) + ' ' + jvposting.hyear + ' ' + STRTRAN(m.goapp.cCompanyName,'GCW ','') + ' Distribution')
         loentry.amount.setvalue(ABS(jvposting.nnetcheck))
         loentry.entityref.listid.setvalue(lcownerlistid)
         loentry.accountref.listid.setvalue(lcCapitalAcct)
      ENDIF

      RETURN .T.
   ENDIF

   SELECT (lcalias)
   SCAN FOR cOwnerID == m.cOwnerID AND cWellID == m.cWellID AND ctypeinv == m.ctypeinv ;
         AND (nincome # 0 OR nexpense # 0 OR nsevtaxes # 0 OR nnetcheck # 0) ;
         AND nrunno_in   = THIS.nrunno ;
         AND crunyear_in = THIS.crunyear ;
         AND crectype # 'P' ;
         AND lManual = .F.
      SCATTER MEMVAR
      llFoundInvTmp = .T.
      SWSELECT('wells')
      IF SEEK(m.cWellID)
         SCATTER FIELDS LIKE lsev* MEMVAR
         m.ldiroilpurch = ldiroilpurch
         m.ldirgaspurch = ldirgaspurch
         lcwelllistid   = wells.cListID
         IF EMPTY(wells.cListID)
            MESSAGEBOX('The wells file needs to be synchronized with QuickBooks. ' + ;
               'please synchronize and then close the revenue period again.', 0, 'Synchronization Problem')
            RETURN .F.
         ENDIF
         llvalidwell = .T.
      ELSE
         m.ldiroilpurch = .F.
         m.ldirgaspurch = .F.
         STORE .F. TO m.lsev1o, m.lsev2o, m.lsev3o, m.lsev4o
         STORE .F. TO m.lsev1g, m.lsev2g, m.lsev3g, m.lsev4g
         STORE .F. TO m.lsev1p, m.lsev2p, m.lsev3p, m.lsev4p
         lcwelllistid = ''
         llvalidwell	 = .F.
      ENDIF

      IF m.nincome # 0
         lnincome   = m.nincome
         *  Remove direct paid amounts
         DO CASE
            CASE m.cdirect = 'O'
               lnincome = lnincome - m.noilrev
            CASE m.cdirect = 'G'
               lnincome = lnincome - m.ngasrev
            CASE m.cdirect = 'B'
               lnincome = lnincome - m.noilrev - m.ngasrev
         ENDCASE
         lnincome = ROUND(lnincome, 2)
      ELSE
         lnincome = 0
      ENDIF

      * Post the Revenue
      IF NOT m.lflat
         IF lnincome # 0
            IF lnincome > 0
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
               ELSE
                  loentry = loentryadd.journaldebitlinelist.APPEND
               ENDIF
               lndebits = lndebits + ABS(lnincome)
            ELSE
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
               ELSE
                  loentry = loentryadd.journalcreditlinelist.APPEND
               ENDIF
               lncredits = lncredits + ABS(lnincome)
            ENDIF
            llpostqb = .T.
            loentry.MEMO.setvalue('Revenue ' + m.hyear + '/' + m.hperiod)
            loentry.amount.setvalue(ABS(lnincome))
            IF llvalidwell
               loentry.classref.listid.setvalue(lcwelllistid)
            ENDIF
            loentry.entityref.listid.setvalue(lcownerlistid)
            IF THIS.BillableAcct(lcRevClear)
               loentry.billablestatus.setvalue(1) && Not Billable
            ENDIF
            loentry.accountref.listid.setvalue(lcRevClear)
            lnBalance = lnBalance + lnincome
         ENDIF
      ELSE
         IF m.nflatrate # 0
            IF m.nflatrate > 0
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
               ELSE
                  loentry = loentryadd.journaldebitlinelist.APPEND
               ENDIF
               lndebits = lndebits + ABS(m.nflatrate)
            ELSE
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
               ELSE
                  loentry = loentryadd.journalcreditlinelist.APPEND
               ENDIF
               lncredits = lncredits + ABS(m.nflatrate)
            ENDIF
            llpostqb	   = .T.
            m.nflatrate = ROUND(m.nflatrate, 2)
            IF llvalidwell
               loentry.classref.listid.setvalue(lcwelllistid)
            ENDIF
            loentry.entityref.listid.setvalue(lcownerlistid)
            IF THIS.BillableAcct(lcRevClear)
               loentry.billablestatus.setvalue(1) && Not Billable
            ENDIF
            loentry.accountref.listid.setvalue(lcRevClear)
            loentry.amount.setvalue(ABS(m.nflatrate))
            loentry.MEMO.setvalue('Flat-Rate Royalty ' + m.hyear + '/' + m.hperiod)
            lnBalance = lnBalance + m.nflatrate
         ENDIF
      ENDIF

      * If the owner is exempt, make sure no taxes post
      IF m.lExempt
         STORE 0 TO m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4
         STORE 0 TO m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4
         STORE 0 TO m.nothtax1, m.nothtax2, m.nothtax3, m.nothtax4
      ENDIF

      * Post the sev taxes
      IF m.noiltax1 # 0
         IF NOT m.lsev1o
            IF INLIST(m.cdirect, 'B', 'O')
               IF NOT m.ldiroilpurch
                  IF m.noiltax1 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.noiltax1)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.noiltax1)
                  ENDIF
                  llpostqb	= .T.
                  m.noiltax1	= ROUND(m.noiltax1, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.ctaxacct1)
                  loentry.amount.setvalue(ABS(m.noiltax1))
                  loentry.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.noiltax1
               ENDIF
            ELSE
               IF m.noiltax1 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.noiltax1)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.noiltax1)
               ENDIF
               llpostqb	 = .T.
               m.noiltax1 = ROUND(m.noiltax1, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               loentry.accountref.listid.setvalue(m.ctaxacct1)
               loentry.amount.setvalue(ABS(m.noiltax1))
               loentry.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.noiltax1
            ENDIF
         ELSE
            IF NOT INLIST(m.cdirect, 'B', 'O')
               IF m.noiltax1 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.noiltax1)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.noiltax1)
               ENDIF
               llpostqb	 = .T.
               m.noiltax1 = ROUND(m.noiltax1, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               IF THIS.BillableAcct(lcRevClear)
                  loentry.billablestatus.setvalue(1) && Not Billable
               ENDIF
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.noiltax1))
               loentry.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.noiltax1
            ELSE
               IF NOT m.ldiroilpurch
                  IF m.noiltax1 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.noiltax1)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.noiltax1)
                  ENDIF
                  llpostqb	= .T.
                  m.noiltax1	= ROUND(m.noiltax1, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.noiltax1))
                  loentry.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.noiltax1
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      IF m.ngastax1 # 0
         IF NOT m.lsev1g
            IF INLIST(m.cdirect, 'B', 'G')
               IF NOT m.ldirgaspurch
                  IF m.ngastax1 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ngastax1)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ngastax1)
                  ENDIF

                  llpostqb	= .T.
                  m.ngastax1	= ROUND(m.ngastax1, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.ctaxacct1)
                  loentry.amount.setvalue(ABS(m.ngastax1))
                  loentry.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ngastax1
               ENDIF
            ELSE
               IF m.ngastax1 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.ngastax1)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.ngastax1)
               ENDIF
               llpostqb	 = .T.
               m.ngastax1 = ROUND(m.ngastax1, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               loentry.accountref.listid.setvalue(m.ctaxacct1)
               loentry.amount.setvalue(ABS(m.ngastax1))
               loentry.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.ngastax1
            ENDIF
         ELSE
            IF NOT INLIST(m.cdirect, 'B', 'G')
               IF m.ngastax1 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.ngastax1)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.ngastax1)
               ENDIF
               llpostqb	 = .T.
               m.ngastax1 = ROUND(m.ngastax1, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               IF THIS.BillableAcct(lcRevClear)
                  loentry.billablestatus.setvalue(1) && Not Billable
               ENDIF
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.ngastax1))
               loentry.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.ngastax1
            ELSE
               IF NOT m.ldirgaspurch
                  IF m.ngastax1 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ngastax1)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ngastax1)
                  ENDIF
                  llpostqb	= .T.
                  m.ngastax1	= ROUND(m.ngastax1, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.ngastax1))
                  loentry.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ngastax1
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      IF m.nothtax1 # 0
         IF m.nothtax1 < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(m.nothtax1)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(m.nothtax1)
         ENDIF
         llpostqb = .T.
         IF NOT m.lsev1p
            loentry.accountref.listid.setvalue(m.ctaxacct1)
         ELSE
            IF THIS.BillableAcct(lcRevClear)
               loentry.billablestatus.setvalue(1) && Not Billable
            ENDIF
            loentry.accountref.listid.setvalue(lcRevClear)
         ENDIF
         m.nothtax1 = ROUND(m.nothtax1, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         loentry.amount.setvalue(ABS(m.nothtax1))
         loentry.MEMO.setvalue('Other Tax 1 ' + m.hyear + '/' + m.hperiod)
         lnBalance = lnBalance - m.nothtax1
      ENDIF

      IF m.noiltax2 # 0
         IF NOT m.lsev2o
            IF INLIST(m.cdirect, 'B', 'O')
               IF NOT m.ldiroilpurch
                  IF m.noiltax2 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.noiltax2)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.noiltax2)
                  ENDIF
                  llpostqb	= .T.
                  m.noiltax2	= ROUND(m.noiltax2, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.ctaxacct2)
                  loentry.amount.setvalue(ABS(m.noiltax2))
                  loentry.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.noiltax2
               ENDIF
            ELSE
               IF m.noiltax2 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.noiltax2)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.noiltax2)
               ENDIF
               llpostqb	 = .T.
               m.noiltax2 = ROUND(m.noiltax2, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               loentry.accountref.listid.setvalue(m.ctaxacct2)
               loentry.amount.setvalue(ABS(m.noiltax2))
               loentry.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.noiltax2
            ENDIF
         ELSE
            IF NOT INLIST(m.cdirect, 'B', 'O')
               IF m.noiltax2 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.noiltax2)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.noiltax2)
               ENDIF
               llpostqb	 = .T.
               m.noiltax2 = ROUND(m.noiltax2, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               IF THIS.BillableAcct(lcRevClear)
                  loentry.billablestatus.setvalue(1) && Not Billable
               ENDIF
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.noiltax2))
               loentry.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.noiltax2
            ELSE
               IF NOT m.ldiroilpurch
                  IF m.noiltax2 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.noiltax2)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.noiltax2)
                  ENDIF
                  llpostqb	= .T.
                  m.noiltax2	= ROUND(m.noiltax2, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.noiltax2))
                  loentry.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.noiltax2
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      IF m.ngastax2 # 0
         IF NOT m.lsev2g
            IF INLIST(m.cdirect, 'B', 'G')
               IF NOT m.ldirgaspurch
                  IF m.ngastax2 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ngastax2)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ngastax2)
                  ENDIF
                  llpostqb	= .T.
                  m.ngastax2	= ROUND(m.ngastax2, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.ctaxacct2)
                  loentry.amount.setvalue(ABS(m.ngastax2))
                  loentry.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ngastax2
               ENDIF
            ELSE
               IF m.ngastax2 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.ngastax2)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.ngastax2)
               ENDIF
               llpostqb	 = .T.
               m.ngastax2 = ROUND(m.ngastax2, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               loentry.accountref.listid.setvalue(m.ctaxacct2)
               loentry.amount.setvalue(ABS(m.ngastax2))
               loentry.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.ngastax2
            ENDIF
         ELSE
            IF NOT INLIST(m.cdirect, 'B', 'G')
               IF m.ngastax2 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.ngastax2)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.ngastax2)
               ENDIF
               llpostqb	 = .T.
               m.ngastax2 = ROUND(m.ngastax2, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               IF THIS.BillableAcct(lcRevClear)
                  loentry.billablestatus.setvalue(1) && Not Billable
               ENDIF
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.ngastax2))
               loentry.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.ngastax2
            ELSE
               IF NOT m.ldirgaspurch
                  IF m.ngastax2 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ngastax2)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ngastax2)
                  ENDIF
                  llpostqb	= .T.
                  m.ngastax2	= ROUND(m.ngastax2, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.ngastax2))
                  loentry.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ngastax2
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      IF m.nothtax2 # 0
         IF m.nothtax2 < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(m.nothtax2)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(m.nothtax2)
         ENDIF
         IF NOT m.lsev2p
            loentry.accountref.listid.setvalue(m.ctaxacct2)
         ELSE
            IF THIS.BillableAcct(lcRevClear)
               loentry.billablestatus.setvalue(1) && Not Billable
            ENDIF
            loentry.accountref.listid.setvalue(lcRevClear)
         ENDIF
         llpostqb   = .T.
         m.nothtax2 = ROUND(m.nothtax2, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         loentry.amount.setvalue(ABS(m.nothtax2))
         loentry.MEMO.setvalue('Other Tax 2 ' + m.hyear + '/' + m.hperiod)
         lnBalance = lnBalance - m.nothtax2
      ENDIF

      IF m.noiltax3 # 0
         IF NOT m.lsev3o
            IF INLIST(m.cdirect, 'B', 'O')
               IF NOT m.ldiroilpurch
                  IF m.noiltax3 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.noiltax3)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.noiltax3)
                  ENDIF
                  llpostqb	= .T.
                  m.noiltax3	= ROUND(m.noiltax3, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.ctaxacct3)
                  loentry.amount.setvalue(ABS(m.noiltax3))
                  loentry.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.noiltax3
               ENDIF
            ELSE
               IF m.noiltax3 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.noiltax3)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.noiltax3)
               ENDIF
               llpostqb	 = .T.
               m.noiltax3 = ROUND(m.noiltax3, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               loentry.accountref.listid.setvalue(m.ctaxacct3)
               loentry.amount.setvalue(ABS(m.noiltax3))
               loentry.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.noiltax3
            ENDIF
         ELSE
            IF NOT INLIST(m.cdirect, 'B', 'O')
               IF m.noiltax3 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.noiltax3)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.noiltax3)
               ENDIF
               llpostqb	 = .T.
               m.noiltax3 = ROUND(m.noiltax3, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               IF THIS.BillableAcct(lcRevClear)
                  loentry.billablestatus.setvalue(1) && Not Billable
               ENDIF
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.noiltax3))
               loentry.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.noiltax3
            ELSE
               IF NOT m.ldiroilpurch
                  IF m.noiltax3 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.noiltax3)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.noiltax3)
                  ENDIF
                  llpostqb	= .T.
                  m.noiltax3	= ROUND(m.noiltax3, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.noiltax3))
                  loentry.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.noiltax3
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      IF m.ngastax3 # 0
         IF NOT m.lsev3g
            IF INLIST(m.cdirect, 'B', 'G')
               IF NOT m.ldirgaspurch
                  IF m.ngastax3 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ngastax3)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ngastax3)
                  ENDIF
                  llpostqb	= .T.
                  m.ngastax3	= ROUND(m.ngastax3, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.ctaxacct3)
                  loentry.amount.setvalue(ABS(m.ngastax3))
                  loentry.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ngastax3
               ENDIF
            ELSE
               IF m.ngastax3 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.ngastax3)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.ngastax3)
               ENDIF
               llpostqb	 = .T.
               m.ngastax3 = ROUND(m.ngastax3, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               loentry.accountref.listid.setvalue(m.ctaxacct3)
               loentry.amount.setvalue(ABS(m.ngastax3))
               loentry.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.ngastax3
            ENDIF
         ELSE
            IF NOT INLIST(m.cdirect, 'B', 'G')
               IF m.ngastax3 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.ngastax3)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.ngastax3)
               ENDIF
               llpostqb	 = .T.
               m.ngastax3 = ROUND(m.ngastax3, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               IF THIS.BillableAcct(lcRevClear)
                  loentry.billablestatus.setvalue(1) && Not Billable
               ENDIF
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.ngastax3))
               loentry.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.ngastax3
            ELSE
               IF NOT m.ldirgaspurch
                  IF m.ngastax3 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ngastax3)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ngastax3)
                  ENDIF
                  llpostqb	= .T.
                  m.ngastax3	= ROUND(m.ngastax3, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.ngastax3))
                  loentry.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ngastax3
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      IF m.nothtax3 # 0
         IF m.nothtax3 < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(m.nothtax3)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(m.nothtax3)
         ENDIF
         IF NOT m.lsev3p
            loentry.accountref.listid.setvalue(m.ctaxacct3)
         ELSE
            IF THIS.BillableAcct(lcRevClear)
               loentry.billablestatus.setvalue(1) && Not Billable
            ENDIF
            loentry.accountref.listid.setvalue(lcRevClear)
         ENDIF
         llpostqb   = .T.
         m.nothtax3 = ROUND(m.nothtax3, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         loentry.amount.setvalue(ABS(m.nothtax3))
         loentry.MEMO.setvalue('Other Tax 3 ' + m.hyear + '/' + m.hperiod)
         lnBalance = lnBalance - m.nothtax3
      ENDIF

      IF m.noiltax4 # 0
         IF NOT m.lsev4o
            IF INLIST(m.cdirect, 'B', 'O')
               IF NOT m.ldiroilpurch
                  IF m.noiltax4 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.noiltax4)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.noiltax4)
                  ENDIF
                  llpostqb	= .T.
                  m.noiltax4	= ROUND(m.noiltax4, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.ctaxacct4)
                  loentry.amount.setvalue(ABS(m.noiltax4))
                  loentry.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.noiltax4
               ENDIF
            ELSE
               IF m.noiltax4 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.noiltax4)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.noiltax4)
               ENDIF
               llpostqb	 = .T.
               m.noiltax4 = ROUND(m.noiltax4, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               loentry.accountref.listid.setvalue(m.ctaxacct4)
               loentry.amount.setvalue(ABS(m.noiltax4))
               loentry.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.noiltax4
            ENDIF
         ELSE
            IF NOT INLIST(m.cdirect, 'B', 'O')
               IF m.noiltax4 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.noiltax4)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.noiltax4)
               ENDIF
               llpostqb	 = .T.
               m.noiltax4 = ROUND(m.noiltax4, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               IF THIS.BillableAcct(lcRevClear)
                  loentry.billablestatus.setvalue(1) && Not Billable
               ENDIF
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.noiltax4))
               loentry.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.noiltax4
            ELSE
               IF NOT m.ldiroilpurch
                  IF m.noiltax4 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.noiltax4)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.noiltax4)
                  ENDIF
                  llpostqb	= .T.
                  m.noiltax4	= ROUND(m.noiltax4, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.noiltax4))
                  loentry.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.noiltax4
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      IF m.ngastax4 # 0
         IF NOT m.lsev4g
            IF INLIST(m.cdirect, 'B', 'G')
               IF NOT m.ldirgaspurch
                  IF m.ngastax4 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ngastax4)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ngastax4)
                  ENDIF
                  llpostqb	= .T.
                  m.ngastax4	= ROUND(m.ngastax4, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.ctaxacct4)
                  loentry.amount.setvalue(ABS(m.ngastax4))
                  loentry.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ngastax4
               ENDIF
            ELSE
               IF m.ngastax4 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.ngastax4)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.ngastax4)
               ENDIF
               llpostqb	 = .T.
               m.ngastax4 = ROUND(m.ngastax4, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               loentry.accountref.listid.setvalue(m.ctaxacct4)
               loentry.amount.setvalue(ABS(m.ngastax4))
               loentry.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.ngastax4
            ENDIF
         ELSE
            IF NOT INLIST(m.cdirect, 'B', 'G')
               IF m.ngastax4 < 0
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                  ELSE
                     loentry = loentryadd.journaldebitlinelist.APPEND
                  ENDIF
                  lndebits = lndebits + ABS(m.ngastax4)
               ELSE
                  IF THIS.qbfcversion > QBFCVER
                     loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                  ELSE
                     loentry = loentryadd.journalcreditlinelist.APPEND
                  ENDIF
                  lncredits = lncredits + ABS(m.ngastax4)
               ENDIF
               llpostqb	 = .T.
               m.ngastax4 = ROUND(m.ngastax4, 2)
               IF llvalidwell
                  loentry.classref.listid.setvalue(lcwelllistid)
               ENDIF
               loentry.entityref.listid.setvalue(lcownerlistid)
               IF THIS.BillableAcct(lcRevClear)
                  loentry.billablestatus.setvalue(1) && Not Billable
               ENDIF
               loentry.accountref.listid.setvalue(lcRevClear)
               loentry.amount.setvalue(ABS(m.ngastax4))
               loentry.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
               lnBalance = lnBalance - m.ngastax4
            ELSE
               IF NOT m.ldirgaspurch
                  IF m.ngastax4 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ngastax4)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ngastax4)
                  ENDIF
                  llpostqb	= .T.
                  m.ngastax4	= ROUND(m.ngastax4, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.ngastax4))
                  loentry.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ngastax4
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      IF m.nothtax4 # 0
         IF m.nothtax4 < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(m.nothtax4)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(m.nothtax4)
         ENDIF
         IF NOT m.lsev4p
            loentry.accountref.listid.setvalue(m.ctaxacct4)
         ELSE
            IF THIS.BillableAcct(lcRevClear)
               loentry.billablestatus.setvalue(1) && Not Billable
            ENDIF
            loentry.accountref.listid.setvalue(lcRevClear)
         ENDIF
         llpostqb   = .T.
         m.nothtax4 = ROUND(m.nothtax4, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         loentry.amount.setvalue(ABS(m.nothtax4))
         loentry.MEMO.setvalue('Other Tax 4 ' + m.hyear + '/' + m.hperiod)
         lnBalance = lnBalance - m.nothtax4
      ENDIF

      *
      *  Post Marketing Expenses
      *
      IF m.nmktgexp # 0
         IF m.nmktgexp < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(m.nmktgexp)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(m.nmktgexp)
         ENDIF
         llpostqb   = .T.
         m.nmktgexp = ROUND(m.nmktgexp, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         IF THIS.BillableAcct(lcExpClear)
            loentry.billablestatus.setvalue(1) && Not Billable
         ENDIF
         loentry.accountref.listid.setvalue(lcExpClear)
         loentry.amount.setvalue(ABS(m.nmktgexp))
         loentry.MEMO.setvalue('Marketing Expense ' + m.hyear + '/' + m.hperiod)
         lnBalance = lnBalance - m.nmktgexp
      ENDIF


      *
      *  Post compression and gathering
      *
      IF m.ncompress # 0
         IF m.ncompress < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(m.ncompress)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(m.ncompress)
         ENDIF
         llpostqb	= .T.
         m.ncompress	= ROUND(m.ncompress, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         IF THIS.BillableAcct(lcRevClear)
            loentry.billablestatus.setvalue(1) && Not Billable
         ENDIF
         loentry.accountref.listid.setvalue(lcRevClear)
         loentry.amount.setvalue(ABS(m.ncompress))
         loentry.MEMO.setvalue('Compression Charge ' + m.hyear + '/' + m.hperiod)
         lnBalance = lnBalance - m.ncompress
      ENDIF

      IF m.ngather # 0
         IF m.ngather < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(m.ngather)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(m.ngather)
         ENDIF
         llpostqb  = .T.
         m.ngather = ROUND(m.ngather, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         IF THIS.BillableAcct(lcRevClear)
            loentry.billablestatus.setvalue(1) && Not Billable
         ENDIF
         loentry.accountref.listid.setvalue(lcRevClear)
         loentry.amount.setvalue(ABS(m.ngather))
         loentry.MEMO.setvalue('Gathering Charge ' + m.hyear + '/' + m.hperiod)
         lnBalance = lnBalance - m.ngather
      ENDIF

      *  Post the Expenses
      lnexpense = m.nexpense + ;
         m.ntotale1 + ;
         m.ntotale2 + ;
         m.ntotale3 + ;
         m.ntotale4 + ;
         m.ntotale5 + ;
         m.ntotalea + ;
         m.ntotaleb + ;
         m.nPlugExp

      IF lnexpense # 0
         IF lnexpense < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(lnexpense)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(lnexpense)
         ENDIF
         llpostqb  = .T.
         lnexpense = ROUND(lnexpense, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         IF THIS.BillableAcct(lcExpClear)
            loentry.billablestatus.setvalue(1) && Not Billable
         ENDIF
         loentry.accountref.listid.setvalue(lcExpClear)
         loentry.amount.setvalue(ABS(lnexpense))
         loentry.MEMO.setvalue('Well Expenses: ' + m.hyear + '/' + m.hperiod )
         lnBalance = lnBalance - lnexpense
      ENDIF

      *  Post Backup Withholding
      IF m.nbackwith # 0
         IF m.nbackwith < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(m.nbackwith)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(m.nbackwith)
         ENDIF
         llpostqb	= .T.
         m.nbackwith	= ROUND(m.nbackwith, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         IF THIS.BillableAcct(m.cbackwith)
            loentry.billablestatus.setvalue(1) && Not Billable
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         loentry.accountref.listid.setvalue(m.cbackwith)
         loentry.amount.setvalue(ABS(m.nbackwith))
         loentry.MEMO.setvalue('Backup W/H ' + m.hyear + '/' + m.hperiod)
      ENDIF

      *  Post Tax Withholding
      IF m.ntaxwith # 0
         IF m.ntaxwith < 0
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
            ELSE
               loentry = loentryadd.journaldebitlinelist.APPEND
            ENDIF
            lndebits = lndebits + ABS(m.ntaxwith)
         ELSE
            IF THIS.qbfcversion > QBFCVER
               loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
            ELSE
               loentry = loentryadd.journalcreditlinelist.APPEND
            ENDIF
            lncredits = lncredits + ABS(m.ntaxwith)
         ENDIF
         llpostqb   = .T.
         m.ntaxwith = ROUND(m.ntaxwith, 2)
         IF llvalidwell
            loentry.classref.listid.setvalue(lcwelllistid)
         ENDIF
         IF THIS.BillableAcct(m.ctaxwith)
            loentry.billablestatus.setvalue(1) && Not Billable
         ENDIF
         loentry.entityref.listid.setvalue(lcownerlistid)
         loentry.accountref.listid.setvalue(m.ctaxwith)
         loentry.amount.setvalue(ABS(m.ntaxwith))
         loentry.MEMO.setvalue('Income Tax W/H ' + m.hyear + '/' + m.hperiod)
      ENDIF
   ENDSCAN

   * Post current deficits
   IF m.csusptype = 'D'  AND m.ntotal # 0
      IF m.ntotal < 0
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
         ELSE
            loentry = loentryadd.journaldebitlinelist.APPEND
         ENDIF
         lndebits = lndebits + ABS(m.ntotal)
      ELSE
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
         ELSE
            loentry = loentryadd.journalcreditlinelist.APPEND
         ENDIF
         lncredits = lncredits + ABS(m.ntotal)
      ENDIF
      llpostqb = .T.
      IF llvalidwell
         loentry.classref.listid.setvalue(lcwelllistid)
      ENDIF
      IF THIS.BillableAcct(m.cdefacct)
         loentry.billablestatus.setvalue(1) && Not Billable
      ENDIF
      loentry.entityref.listid.setvalue(lcownerlistid)
      loentry.accountref.listid.setvalue(m.cdefacct)
      loentry.amount.setvalue(ABS(m.ntotal))
      loentry.MEMO.setvalue('Current Deficit ' + m.hyear + '/' + m.hperiod)
      lnolddef = 0
   ENDIF

   * Post current minimums
   IF m.csusptype = 'M'  AND m.ntotal # 0
      IF m.ntotal < 0
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
         ELSE
            loentry = loentryadd.journaldebitlinelist.APPEND
         ENDIF
         lndebits = lndebits + ABS(m.ntotal)
      ELSE
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
         ELSE
            loentry = loentryadd.journalcreditlinelist.APPEND
         ENDIF
         lncredits = lncredits + ABS(m.ntotal)
      ENDIF
      llpostqb = .T.
      IF llvalidwell
         loentry.classref.listid.setvalue(lcwelllistid)
      ENDIF
      IF THIS.BillableAcct(m.cminacct)
         loentry.billablestatus.setvalue(1) && Not Billable
      ENDIF
      loentry.entityref.listid.setvalue(lcownerlistid)
      loentry.accountref.listid.setvalue(m.cminacct)
      loentry.amount.setvalue(ABS(m.ntotal))
      loentry.MEMO.setvalue('Current Minimum ' + m.hyear + '/' + m.hperiod)
      lnolddef = 0
   ENDIF

   * Post owners going on hold
   IF m.csusptype = 'H'  AND m.ntotal # 0
      IF m.ntotal < 0
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
         ELSE
            loentry = loentryadd.journaldebitlinelist.APPEND
         ENDIF
         lndebits = lndebits + ABS(m.ntotal)
      ELSE
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
         ELSE
            loentry = loentryadd.journalcreditlinelist.APPEND
         ENDIF
         lncredits = lncredits + ABS(m.ntotal)
      ENDIF
      llpostqb = .T.
      IF llvalidwell
         loentry.classref.listid.setvalue(lcwelllistid)
      ENDIF
      IF THIS.BillableAcct(m.cminacct)
         loentry.billablestatus.setvalue(1) && Not Billable
      ENDIF
      loentry.entityref.listid.setvalue(lcownerlistid)
      loentry.accountref.listid.setvalue(m.cminacct)
      loentry.amount.setvalue(ABS(m.ntotal))
      loentry.MEMO.setvalue('Owner on Hold ' + m.hyear + '/' + m.hperiod)
      lnolddef = 0
   ENDIF

   * Post interests going on hold
   IF m.csusptype = 'I' AND m.ntotal # 0
      IF m.ntotal < 0
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
         ELSE
            loentry = loentryadd.journaldebitlinelist.APPEND
         ENDIF
         lndebits = lndebits + ABS(m.ntotal)
      ELSE
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
         ELSE
            loentry = loentryadd.journalcreditlinelist.APPEND
         ENDIF
         lncredits = lncredits + ABS(m.ntotal)
      ENDIF
      llpostqb = .T.
      IF llvalidwell
         loentry.classref.listid.setvalue(lcwelllistid)
      ENDIF
      IF THIS.BillableAcct(m.cminacct)
         loentry.billablestatus.setvalue(1) && Not Billable
      ENDIF
      loentry.entityref.listid.setvalue(lcownerlistid)
      loentry.accountref.listid.setvalue(m.cminacct)
      loentry.amount.setvalue(ABS(m.ntotal))
      loentry.MEMO.setvalue('Interest on Hold ' + m.hyear + '/' + m.hperiod)
      lnolddef = 0
   ENDIF

   * Post Quarterly pays going on hold
   IF m.csusptype = 'Q' AND m.ntotal # 0
      IF m.ntotal < 0
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
         ELSE
            loentry = loentryadd.journaldebitlinelist.APPEND
         ENDIF
         lndebits = lndebits + ABS(m.ntotal)
      ELSE
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
         ELSE
            loentry = loentryadd.journalcreditlinelist.APPEND
         ENDIF
         lncredits = lncredits + ABS(m.ntotal)
      ENDIF
      llpostqb = .T.
      IF llvalidwell
         loentry.classref.listid.setvalue(lcwelllistid)
      ENDIF
      IF THIS.BillableAcct(m.cminacct)
         loentry.billablestatus.setvalue(1) && Not Billable
      ENDIF
      loentry.entityref.listid.setvalue(lcownerlistid)
      loentry.accountref.listid.setvalue(m.cminacct)
      loentry.amount.setvalue(ABS(m.ntotal))
      loentry.MEMO.setvalue('Quarterly Interest Held ' + m.hyear + '/' + m.hperiod)
      lnolddef = 0
   ENDIF

   * Post Semi-Annual pays going on hold
   IF m.csusptype = 'S'  AND m.ntotal # 0
      IF m.ntotal < 0
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
         ELSE
            loentry = loentryadd.journaldebitlinelist.APPEND
         ENDIF
         lndebits = lndebits + ABS(m.ntotal)
      ELSE
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
         ELSE
            loentry = loentryadd.journalcreditlinelist.APPEND
         ENDIF
         lncredits = lncredits + ABS(m.ntotal)
      ENDIF
      llpostqb = .T.
      IF llvalidwell
         loentry.classref.listid.setvalue(lcwelllistid)
      ENDIF
      IF THIS.BillableAcct(m.cminacct)
         loentry.billablestatus.setvalue(1) && Not Billable
      ENDIF
      loentry.entityref.listid.setvalue(lcownerlistid)
      loentry.accountref.listid.setvalue(m.cminacct)
      loentry.amount.setvalue(ABS(m.ntotal))
      loentry.MEMO.setvalue('Semi-Annual Interest Held ' + m.hyear + '/' + m.hperiod)
      lnolddef = 0
   ENDIF

   * Post Annual pays going on hold
   IF m.csusptype = 'A' AND m.ntotal # 0
      IF m.ntotal < 0
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
         ELSE
            loentry = loentryadd.journaldebitlinelist.APPEND
         ENDIF
         lndebits = lndebits + ABS(m.ntotal)
      ELSE
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
         ELSE
            loentry = loentryadd.journalcreditlinelist.APPEND
         ENDIF
         lncredits = lncredits + ABS(m.ntotal)
      ENDIF
      llpostqb = .T.
      IF llvalidwell
         loentry.classref.listid.setvalue(lcwelllistid)
      ENDIF
      IF THIS.BillableAcct(m.cminacct)
         loentry.billablestatus.setvalue(1) && Not Billable
      ENDIF
      loentry.entityref.listid.setvalue(lcownerlistid)
      loentry.accountref.listid.setvalue(m.cminacct)
      loentry.amount.setvalue(ABS(m.ntotal))
      loentry.MEMO.setvalue('Annual Interest Held ' + m.hyear + '/' + m.hperiod)
      lnolddef = 0
   ENDIF

   lcidchec = ''

   IF lndebits # lncredits
      lnBal = ROUND(lndebits - lncredits, 2)
      IF lnBal < 0
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
         ELSE
            loentry = loentryadd.journaldebitlinelist.APPEND
         ENDIF
      ELSE
         IF THIS.qbfcversion > QBFCVER
            loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
         ELSE
            loentry = loentryadd.journalcreditlinelist.APPEND
         ENDIF
      ENDIF
      loentry.entityref.listid.setvalue(lcownerlistid)
      IF m.lManual
         loentry.accountref.listid.setvalue(lcRevClear)
         loentry.MEMO.setvalue('Purchaser Withheld Tax')
      ELSE
         loentry.accountref.listid.setvalue(lcSuspense)
         loentry.MEMO.setvalue('Out of Balance Entry')
      ENDIF
      loentry.amount.setvalue(ABS(lnBal))

   ENDIF

   ***************************
   PROCEDURE qbpostownhist
   ***************************
   LPARA tcdmbatch
   LOCAL tcyear, tcperiod, tdcheckdate, tcgroup, tdPostdate
   LOCAL lnmax, lncount, lntotal, lcname, lnjibinv, m.ccustname, lcdmbatch, llsepclose
   LOCAL lcRevClear, lcSuspense, m.cdisbacct, m.cvendcomp, m.cgathacct, m.cbackwith
   LOCAL llintegcomp, llsepclose, lcAPAcct, lcacctyear, lcacctmonth, lcidchec
   LOCAL loresponse, lnJournal, lnCheck

   IF THIS.lerrorflag
      RETURN .F.
   ENDIF

   THIS.cdmbatch = tcdmbatch

   * Choose the correct txndeltype depending on the SDK.
   IF THIS.qbfcversion > QBFCVER
      lnJournal = 15
      lnCheck   = 6
   ELSE
      lnJournal = 14
      lnCheck   = 11
   ENDIF

   SWSELECT('sysctl')
   LOCATE FOR cdmbatch = tcdmbatch
   IF FOUND()
      THIS.csysctlkey = cidsysctl
      m.cidsysctl	 = cidsysctl
   ELSE
      THIS.omessage.severe('The closing control information cannot be found...')
      RETURN
   ENDIF

   * set the on error attribute for the request
   THIS.oqbrequest.ATTRIBUTES.OnError = 1

   * Clear any previous requests
   THIS.oqbrequest.ClearRequests()

   lnmax		  = 0
   lncount	  = 0
   lntotal	  = 0
   lcname	  = 'Owner'
   m.ccustname = ' '
   lcidchec	  = ''

   lcacctyear  = STR(YEAR(THIS.dpostdate), 4)
   lcacctmonth = PADL(ALLTRIM(STR(MONTH(THIS.dpostdate), 2)), 2, '0')

   tdCompanyPost	= THIS.dpostdate
   tdPostdate	= THIS.dpostdate

   IF m.goapp.lPartnershipMod
      SWSELECT('progopt')
      GO TOP
      llJVPosting = lJVPosting
      lcCapitalAcct = cCapAcct
   ELSE
      llJVPosting = .F.
      lcCapitalAcct = lcSuspense
   ENDIF

   *
   *  Get the suspense account from glopt
   *
   SWSELECT('glopt')
   IF NOT llJVPosting
      lcRevClear = crevclear
      lcExpClear = cexpclear
   ELSE
      STORE lcCapitalAcct TO lcRevClear, lcExpClear
   ENDIF

   llQBPost	 = NOT ldmnopost
   lcSuspense = csuspense

   IF EMPTY(lcRevClear)
      MESSAGEBOX('The revenue clearing account needs to be specified in Account Settings ' + ;
         'please specify the account and then close the revenue period again.', 0, 'Setup Problem')
      RETURN .F.
   ENDIF
   IF EMPTY(lcExpClear)
      MESSAGEBOX('The expense clearing account needs to be specified in Account Settings ' + ;
         'please specify the account and then close the revenue period again.', 0, 'Setup Problem')
      RETURN .F.
   ENDIF

   *
   *  Get the A/P account
   *
   SWSELECT('apopt')
   lcAPAcct = cAPAcct

   *
   *  Set up the parameters used by processing in this method
   *
   tcyear   = THIS.crunyear
   tcperiod = THIS.cperiod
   tcgroup  = THIS.cgroup

   IF EMPTY(lcSuspense)
      MESSAGEBOX('The "Catch-All" account has not been specified in the Account Defaults.  Please specify a catch-all account before continuing.', 0, 'Account Problem')
      RETURN .F.
   ENDIF

   *  Open the QB Transaction Table
   SWSELECT('qbpost')

   ****************************************************************
   *   Get Disbursement Checking Acct Number
   ****************************************************************
   SWSELECT('options')
   GO TOP
   m.cdisbacct = cdisbacct
   IF EMPTY(ALLT(m.cdisbacct))
      m.cdisbacct = lcSuspense
   ENDIF
   m.cvendcomp = cvendcomp
   IF EMPTY(ALLT(m.cvendcomp))
      m.cvendcomp = lcSuspense
   ENDIF
   m.cgathacct = cgathacct
   IF EMPTY(ALLT(m.cgathacct))
      m.cgathacct = lcSuspense
   ENDIF
   m.cbackwith = cbackacct
   IF EMPTY(ALLT(m.cbackwith))
      m.cbackwith = lcSuspense
   ENDIF
   m.ctaxwith = ctaxacct
   IF EMPTY(ALLT(m.ctaxwith))
      m.ctaxwith = lcSuspense
   ENDIF
   m.ctaxacct1  = ctaxacct1
   IF EMPTY(ALLT(m.ctaxacct1))
      m.ctaxacct1 = lcSuspense
   ENDIF
   m.ctaxacct2  = ctaxacct2
   IF EMPTY(ALLT(m.ctaxacct2))
      m.ctaxacct2 = lcSuspense
   ENDIF
   m.ctaxacct3  = ctaxacct3
   IF EMPTY(ALLT(m.ctaxacct3))
      m.ctaxacct3 = lcSuspense
   ENDIF
   m.ctaxacct4 = ctaxacct4
   IF EMPTY(ALLT(m.ctaxacct4))
      m.ctaxacct4 = lcSuspense
   ENDIF
   m.cdefacct  = cdefacct
   IF EMPTY(ALLT(m.cdefacct))
      m.cdefacct = lcSuspense
   ENDIF
   m.cminacct  = cminacct
   IF EMPTY((m.cminacct))
      m.cminacct = lcSuspense
   ENDIF

   lcSaveExpClr = lcExpClear
   lcSaveRevClr = lcRevClear
   *  Get the account fixed expenses and well expenses by well expenses are to be posted to.
   lcdmexp = cfixedacct
   IF EMPTY(lcdmexp)
      lcdmexp = lcAPAcct
   ENDIF

   llsepclose  = .T.

   ******************************************************************
   *   Check to see if vendor compression & gathering is to be posted
   ******************************************************************
   llintegcomp = .F.

   IF NOT EMPTY(m.cvendcomp)
      SWSELECT('vendor')
      SET ORDER TO cVendorID
      IF SEEK(m.cvendcomp)
         IF linteggl
            llintegcomp = .T.
         ENDIF
      ENDIF
   ENDIF

   lcref = 'DM-' + PADL(TRANSFORM(THIS.nrunno), 3, '0') + '/' + THIS.crunyear

   *********************************************************************
   *   Post owner amounts to G/L that zeroed out during the run
   *********************************************************************
   SWSELECT('wells')
   SET ORDER TO cWellID

   IF m.goapp.oQB.lqbactive AND llQBPost

      CREATE CURSOR tmpowners ;
         (cOwnerID   c(10), ;
         cWellID    c(10), ;
         ctypeinv   c(1), ;
         csusptype  c(1), ;
         ntotal     N(12, 2),  ;
         ntotinc    N(12, 2),  ;
         ntotexp    N(12, 2),  ;
         ntottax    N(12, 2))

      INDEX ON cOwnerID TAG owner

      lcRunYear = THIS.crunyear + PADL(TRANSFORM(THIS.nrunno), 3, '0')

      * Get a cursor of owners to be posted from invtmp
      SELECT  cOwnerID, ;
         cWellID, ;
         ctypeinv, ;
         SUM(nnetcheck) AS ntotal, ;
         SUM(ICASE(cdirect = 'O', nincome - noilrev, cdirect = 'G', nincome - ngasrev, cdirect = 'B', nincome - noilrev - ngasrev, nincome)) AS ntotinc, ;
         SUM(nexpense) AS ntotexp, ;
         SUM(nsevtaxes) AS ntottax, ;
         csusptype  ;
         FROM invtmp WITH (BUFFERING = .T.) ;
         WHERE EMPTY(cidchec) ;
         AND (nrunno = THIS.nrunno ;
         AND crunyear = THIS.crunyear ;
         AND crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') # lcRunYear);
         AND cOwnerID NOT IN (SELECT  cOwnerID ;
         FROM investor ;
         WHERE linteggl) ;
         ORDER BY cOwnerID, cWellID, ctypeinv, csusptype ;
         GROUP BY cOwnerID, cWellID, ctypeinv, csusptype ;
         INTO CURSOR tmp
      lnmax = _TALLY
      IF lnmax > 0
         SELE tmpowners
         APPEND FROM DBF('tmp')
      ENDIF

      * Get the owners to post
      SELECT  cOwnerID, ;
         SUM(ntotal) AS ntotal, ;
         SUM(ntotinc) AS ntotinc, ;
         SUM(ntotexp) AS ntotexp, ;
         SUM(ntottax) AS ntottax;
         FROM tmpowners ;
         INTO CURSOR ownerpost ;
         ORDER BY cOwnerID ;
         GROUP BY cOwnerID
      lncount = 1

      IF NOT THIS.lquiet
         THIS.oprogress = THIS.omessage.progressbarex('Posting owner amounts to QuickBooks...', ' ')
         THIS.oprogress.setprogressrange(0, lnmax)
      ENDIF

      SELECT ownerpost
      SCAN
         SCATTER MEMVAR
         * Scan through the owners in invtmp for this run

         THIS.oqbrequest.ClearRequests()
         * set the on error attribute for the request
         THIS.oqbrequest.ATTRIBUTES.OnError = 1

         * Setup the counters for debits and credits so we can post any difference
         * To the catch-all account so we don't try to post out of balance entries - pws 3/9/2007
         STORE 0 TO lndebits, lncredits

         m.ntotal  = ntotal
         lnBalance = 0
         IF m.ntotinc = 0 AND m.ntotexp = 0 AND m.ntottax = 0 AND m.ntotal = 0
            LOOP
         ENDIF

         m.lExempt	 = .F.
         m.lDirectDep = .F.

         * Check the owner to make sure they've been synch'd with QB and that
         * they're not a posting or dummy owner.
         SWSELECT('investor')
         SET ORDER TO cOwnerID
         IF SEEK(m.cOwnerID)
            m.cownname	 = cownname
            lcownerlistid = cListID
            m.lExempt	 = lExempt
            m.lDirectDep	 = lDirectDep
            IF EMPTY(cListID)
               MESSAGEBOX('The owner file needs to be synchronized with QuickBooks. ' + ;
                  'please synchronize and then close the revenue period again.', 0, 'Synchronization Problem')
               RETURN .F.
            ENDIF
            IF NOT THIS.lquiet
               THIS.oprogress.SetProgressMessage(ALLT(m.cOwnerID) + ' - ' + ALLT(m.cownname))
               THIS.oprogress.updateprogress(lncount)
               lncount = lncount + 1
            ENDIF
            * Don't post "Dummy" owner amounts
            IF lDummy
               LOOP
            ENDIF
            * Don't post owners that are transfered to G/L here.
            IF linteggl OR lDummy
               LOOP
            ENDIF
         ELSE
            LOOP
         ENDIF

         *  Set the post flag
         llpostqb = .F.

         *  Setup the journal add request
         loentryadd = THIS.oqbrequest.appendjournalentryaddrq()
         loentryadd.txndate.setvalue(tdPostdate)
         loentryadd.refnumber.setvalue(lcref)
         SELECT tmpowners
         SCAN FOR cOwnerID == m.cOwnerID
            m.cOwnerID  = cOwnerID
            m.cWellID   = cWellID
            m.ctypeinv  = ctypeinv
            m.csusptype = csusptype



            m.cidchec	= ' '
            llPostInvTmp	= .F.
            STORE 0 TO lnolddef

            * Scan through the invtmp table posting each record zeroed during this run.
            SWSELECT('invtmp')
            SCAN FOR EMPTY(cidchec) AND cOwnerID == m.cOwnerID AND cWellID == m.cWellID AND ctypeinv == m.ctypeinv ;
                  AND (nincome # 0 OR nexpense # 0 OR nsevtaxes # 0 OR nnetcheck # 0) ;
                  AND nrunno   = THIS.nrunno ;
                  AND crunyear = THIS.crunyear ;
                  AND csusptype = m.csusptype
               SCATTER MEMVAR


               * Change clearing accounts to post deficits or minimums to deficit or minimum account
               * Since the suspense was cleared out of the clearing accounts when it went into suspense
               DO CASE
                  CASE m.csusptype = 'D'
                     lcRevClear = m.cdefacct
                     lcExpClear = m.cdefacct
                  CASE EMPTY(m.csusptype)
                     lcRevClear = lcSaveRevClr
                     lcExpClear = lcSaveExpClr
                  OTHERWISE
                     lcRevClear = m.cminacct
                     lcExpClear = m.cminacct
               ENDCASE

               llFoundInvTmp = .T.
               SWSELECT('wells')
               IF SEEK(m.cWellID)
                  SCATTER FIELDS LIKE lsev* MEMVAR
                  m.ldiroilpurch	= ldiroilpurch
                  m.ldirgaspurch	= ldirgaspurch
                  lcwelllistid	= wells.cListID
                  IF EMPTY(wells.cListID)
                     MESSAGEBOX('The wells file needs to be synchronized with QuickBooks. ' + ;
                        'please synchronize and then close the revenue period again.', 0, 'Synchronization Problem')
                     RETURN .F.
                  ENDIF
                  llvalidwell = .T.
               ELSE
                  m.ldiroilpurch	= .F.
                  m.ldirgaspurch	= .F.
                  STORE .F. TO m.lsev1o, m.lsev2o, m.lsev3o, m.lsev4o
                  STORE .F. TO m.lsev1g, m.lsev2g, m.lsev3g, m.lsev4g
                  STORE .F. TO m.lsev1p, m.lsev2p, m.lsev3p, m.lsev4p
                  lcwelllistid = ''
                  llvalidwell  = .F.
               ENDIF

               IF m.nincome # 0
                  lnincome   = m.nincome
                  *  Remove direct paid amounts
                  DO CASE
                     CASE m.cdirect = 'O'
                        lnincome = lnincome - m.noilrev
                     CASE m.cdirect = 'G'
                        lnincome = lnincome - m.ngasrev
                     CASE m.cdirect = 'B'
                        lnincome = lnincome - m.noilrev - m.ngasrev
                  ENDCASE
                  lnincome = ROUND(lnincome, 2)
               ELSE
                  lnincome = 0
               ENDIF

               * Post the Revenue
               IF NOT m.lflat
                  IF lnincome # 0
                     IF lnincome > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                        lndebits = lndebits + ABS(lnincome)
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                        lncredits = lncredits + ABS(lnincome)
                     ENDIF
                     llpostqb = .T.
                     loentry.MEMO.setvalue('Revenue ' + m.hyear + '/' + m.hperiod)
                     loentry.amount.setvalue(ABS(lnincome))
                     IF llvalidwell
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownerlistid)
                     IF THIS.BillableAcct(lcRevClear)
                        loentry.billablestatus.setvalue(1) && Not Billable
                     ENDIF
                     loentry.accountref.listid.setvalue(lcRevClear)
                     lnBalance = lnBalance + lnincome
                  ENDIF
               ELSE
                  IF m.nflatrate # 0
                     IF m.nflatrate > 0
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                        ELSE
                           loentry = loentryadd.journaldebitlinelist.APPEND
                        ENDIF
                        lndebits = lndebits + ABS(m.nflatrate)
                     ELSE
                        IF THIS.qbfcversion > QBFCVER
                           loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                        ELSE
                           loentry = loentryadd.journalcreditlinelist.APPEND
                        ENDIF
                        lncredits = lncredits + ABS(m.nflatrate)
                     ENDIF
                     llpostqb	= .T.
                     m.nflatrate	= ROUND(m.nflatrate, 2)
                     IF llvalidwell
                        loentry.classref.listid.setvalue(lcwelllistid)
                     ENDIF
                     loentry.entityref.listid.setvalue(lcownerlistid)
                     IF THIS.BillableAcct(lcRevClear)
                        loentry.billablestatus.setvalue(1) && Not Billable
                     ENDIF
                     loentry.accountref.listid.setvalue(lcRevClear)
                     loentry.amount.setvalue(ABS(m.nflatrate))
                     loentry.MEMO.setvalue('Flat-Rate Royalty ' + m.hyear + '/' + m.hperiod)
                     lnBalance = lnBalance + m.nflatrate
                  ENDIF
               ENDIF

               * If the owner is exempt, make sure no taxes post
               IF m.lExempt
                  STORE 0 TO m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4
                  STORE 0 TO m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4
                  STORE 0 TO m.nothtax1, m.nothtax2, m.nothtax3, m.nothtax4
               ENDIF

               * Post the sev taxes
               IF m.noiltax1 # 0
                  IF NOT m.lsev1o
                     IF INLIST(m.cdirect, 'B', 'O')
                        IF NOT m.ldiroilpurch
                           IF m.noiltax1 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.noiltax1)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.noiltax1)
                           ENDIF
                           llpostqb	 = .T.
                           m.noiltax1 = ROUND(m.noiltax1, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           loentry.accountref.listid.setvalue(m.ctaxacct1)
                           loentry.amount.setvalue(ABS(m.noiltax1))
                           loentry.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.noiltax1
                        ENDIF
                     ELSE
                        IF m.noiltax1 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.noiltax1)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.noiltax1)
                        ENDIF
                        llpostqb	  = .T.
                        m.noiltax1 = ROUND(m.noiltax1, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        loentry.accountref.listid.setvalue(m.ctaxacct1)
                        loentry.amount.setvalue(ABS(m.noiltax1))
                        loentry.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.noiltax1
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'O')
                        IF m.noiltax1 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.noiltax1)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.noiltax1)
                        ENDIF
                        llpostqb	  = .T.
                        m.noiltax1 = ROUND(m.noiltax1, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        IF THIS.BillableAcct(lcRevClear)
                           loentry.billablestatus.setvalue(1) && Not Billable
                        ENDIF
                        loentry.accountref.listid.setvalue(lcRevClear)
                        loentry.amount.setvalue(ABS(m.noiltax1))
                        loentry.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.noiltax1
                     ELSE
                        IF NOT m.ldiroilpurch
                           IF m.noiltax1 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.noiltax1)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.noiltax1)
                           ENDIF
                           llpostqb	 = .T.
                           m.noiltax1 = ROUND(m.noiltax1, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           IF THIS.BillableAcct(lcRevClear)
                              loentry.billablestatus.setvalue(1) && Not Billable
                           ENDIF
                           loentry.accountref.listid.setvalue(lcRevClear)
                           loentry.amount.setvalue(ABS(m.noiltax1))
                           loentry.MEMO.setvalue('Oil Tax 1 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.noiltax1
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
               IF m.ngastax1 # 0
                  IF NOT m.lsev1g
                     IF INLIST(m.cdirect, 'B', 'G')
                        IF NOT m.ldirgaspurch
                           IF m.ngastax1 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.ngastax1)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.ngastax1)
                           ENDIF

                           llpostqb	 = .T.
                           m.ngastax1 = ROUND(m.ngastax1, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           loentry.accountref.listid.setvalue(m.ctaxacct1)
                           loentry.amount.setvalue(ABS(m.ngastax1))
                           loentry.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.ngastax1
                        ENDIF
                     ELSE
                        IF m.ngastax1 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.ngastax1)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.ngastax1)
                        ENDIF
                        llpostqb	  = .T.
                        m.ngastax1 = ROUND(m.ngastax1, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        loentry.accountref.listid.setvalue(m.ctaxacct1)
                        loentry.amount.setvalue(ABS(m.ngastax1))
                        loentry.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.ngastax1
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'G')
                        IF m.ngastax1 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.ngastax1)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.ngastax1)
                        ENDIF
                        llpostqb	  = .T.
                        m.ngastax1 = ROUND(m.ngastax1, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        IF THIS.BillableAcct(lcRevClear)
                           loentry.billablestatus.setvalue(1) && Not Billable
                        ENDIF
                        loentry.accountref.listid.setvalue(lcRevClear)
                        loentry.amount.setvalue(ABS(m.ngastax1))
                        loentry.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.ngastax1
                     ELSE
                        IF NOT m.ldirgaspurch
                           IF m.ngastax1 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.ngastax1)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.ngastax1)
                           ENDIF
                           llpostqb	 = .T.
                           m.ngastax1 = ROUND(m.ngastax1, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           IF THIS.BillableAcct(lcRevClear)
                              loentry.billablestatus.setvalue(1) && Not Billable
                           ENDIF
                           loentry.accountref.listid.setvalue(lcRevClear)
                           loentry.amount.setvalue(ABS(m.ngastax1))
                           loentry.MEMO.setvalue('Gas Tax 1 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.ngastax1
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.nothtax1 # 0
                  IF m.nothtax1 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.nothtax1)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.nothtax1)
                  ENDIF
                  llpostqb = .T.
                  IF NOT m.lsev1p
                     loentry.accountref.listid.setvalue(m.ctaxacct1)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  m.nothtax1 = ROUND(m.nothtax1, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.amount.setvalue(ABS(m.nothtax1))
                  loentry.MEMO.setvalue('Other Tax 1 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.nothtax1
               ENDIF

               IF m.noiltax2 # 0
                  IF NOT m.lsev2o
                     IF INLIST(m.cdirect, 'B', 'O')
                        IF NOT m.ldiroilpurch
                           IF m.noiltax2 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.noiltax2)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.noiltax2)
                           ENDIF
                           llpostqb	 = .T.
                           m.noiltax2 = ROUND(m.noiltax2, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           loentry.accountref.listid.setvalue(m.ctaxacct2)
                           loentry.amount.setvalue(ABS(m.noiltax2))
                           loentry.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.noiltax2
                        ENDIF
                     ELSE
                        IF m.noiltax2 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.noiltax2)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.noiltax2)
                        ENDIF
                        llpostqb	  = .T.
                        m.noiltax2 = ROUND(m.noiltax2, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        loentry.accountref.listid.setvalue(m.ctaxacct1)
                        loentry.amount.setvalue(ABS(m.noiltax2))
                        loentry.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.noiltax2
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'O')
                        IF m.noiltax2 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.noiltax2)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.noiltax2)
                        ENDIF
                        llpostqb	  = .T.
                        m.noiltax2 = ROUND(m.noiltax2, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        IF THIS.BillableAcct(lcRevClear)
                           loentry.billablestatus.setvalue(1) && Not Billable
                        ENDIF
                        loentry.accountref.listid.setvalue(lcRevClear)
                        loentry.amount.setvalue(ABS(m.noiltax2))
                        loentry.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.noiltax2
                     ELSE
                        IF NOT m.ldiroilpurch
                           IF m.noiltax2 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.noiltax2)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.noiltax2)
                           ENDIF
                           llpostqb	 = .T.
                           m.noiltax2 = ROUND(m.noiltax2, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           IF THIS.BillableAcct(lcRevClear)
                              loentry.billablestatus.setvalue(1) && Not Billable
                           ENDIF
                           loentry.accountref.listid.setvalue(lcRevClear)
                           loentry.amount.setvalue(ABS(m.noiltax2))
                           loentry.MEMO.setvalue('Oil Tax 2 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.noiltax2
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.ngastax2 # 0
                  IF NOT m.lsev2g
                     IF INLIST(m.cdirect, 'B', 'G')
                        IF NOT m.ldirgaspurch
                           IF m.ngastax2 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.ngastax2)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.ngastax2)
                           ENDIF
                           llpostqb	 = .T.
                           m.ngastax2 = ROUND(m.ngastax2, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           loentry.accountref.listid.setvalue(m.ctaxacct2)
                           loentry.amount.setvalue(ABS(m.ngastax2))
                           loentry.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.ngastax2
                        ENDIF
                     ELSE
                        IF m.ngastax2 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.ngastax2)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.ngastax2)
                        ENDIF
                        llpostqb	  = .T.
                        m.ngastax2 = ROUND(m.ngastax2, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        loentry.accountref.listid.setvalue(m.ctaxacct2)
                        loentry.amount.setvalue(ABS(m.ngastax2))
                        loentry.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.ngastax2
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'G')
                        IF m.ngastax2 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.ngastax2)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.ngastax2)
                        ENDIF
                        llpostqb	  = .T.
                        m.ngastax2 = ROUND(m.ngastax2, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        IF THIS.BillableAcct(lcRevClear)
                           loentry.billablestatus.setvalue(1) && Not Billable
                        ENDIF
                        loentry.accountref.listid.setvalue(lcRevClear)
                        loentry.amount.setvalue(ABS(m.ngastax2))
                        loentry.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.ngastax2
                     ELSE
                        IF NOT m.ldirgaspurch
                           IF m.ngastax2 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.ngastax2)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.ngastax2)
                           ENDIF
                           llpostqb	 = .T.
                           m.ngastax2 = ROUND(m.ngastax2, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           IF THIS.BillableAcct(lcRevClear)
                              loentry.billablestatus.setvalue(1) && Not Billable
                           ENDIF
                           loentry.accountref.listid.setvalue(lcRevClear)
                           loentry.amount.setvalue(ABS(m.ngastax2))
                           loentry.MEMO.setvalue('Gas Tax 2 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.ngastax2
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.nothtax2 # 0
                  IF m.nothtax2 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.nothtax2)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.nothtax2)
                  ENDIF
                  IF NOT m.lsev2p
                     loentry.accountref.listid.setvalue(m.ctaxacct2)
                  ELSE
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  llpostqb	= .T.
                  m.nothtax2	= ROUND(m.nothtax2, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.amount.setvalue(ABS(m.nothtax2))
                  loentry.MEMO.setvalue('Other Tax 2 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.nothtax2
               ENDIF

               IF m.noiltax3 # 0
                  IF NOT m.lsev3o
                     IF INLIST(m.cdirect, 'B', 'O')
                        IF NOT m.ldiroilpurch
                           IF m.noiltax3 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.noiltax3)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.noiltax3)
                           ENDIF
                           llpostqb	 = .T.
                           m.noiltax3 = ROUND(m.noiltax3, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           loentry.accountref.listid.setvalue(m.ctaxacct3)
                           loentry.amount.setvalue(ABS(m.noiltax3))
                           loentry.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.noiltax3
                        ENDIF
                     ELSE
                        IF m.noiltax3 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.noiltax3)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.noiltax3)
                        ENDIF
                        llpostqb	  = .T.
                        m.noiltax3 = ROUND(m.noiltax3, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        loentry.accountref.listid.setvalue(m.ctaxacct3)
                        loentry.amount.setvalue(ABS(m.noiltax3))
                        loentry.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.noiltax3
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'O')
                        IF m.noiltax3 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.noiltax3)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.noiltax3)
                        ENDIF
                        llpostqb	  = .T.
                        m.noiltax3 = ROUND(m.noiltax3, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        IF THIS.BillableAcct(lcRevClear)
                           loentry.billablestatus.setvalue(1) && Not Billable
                        ENDIF
                        loentry.accountref.listid.setvalue(lcRevClear)
                        loentry.amount.setvalue(ABS(m.noiltax3))
                        loentry.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.noiltax3
                     ELSE
                        IF NOT m.ldiroilpurch
                           IF m.noiltax3 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.noiltax3)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.noiltax3)
                           ENDIF
                           llpostqb	 = .T.
                           m.noiltax3 = ROUND(m.noiltax3, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           IF THIS.BillableAcct(lcRevClear)
                              loentry.billablestatus.setvalue(1) && Not Billable
                           ENDIF
                           loentry.accountref.listid.setvalue(lcRevClear)
                           loentry.amount.setvalue(ABS(m.noiltax3))
                           loentry.MEMO.setvalue('Oil Tax 3 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.noiltax3
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.ngastax3 # 0
                  IF NOT m.lsev3g
                     IF INLIST(m.cdirect, 'B', 'G')
                        IF NOT m.ldirgaspurch
                           IF m.ngastax3 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.ngastax3)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.ngastax3)
                           ENDIF
                           llpostqb	 = .T.
                           m.ngastax3 = ROUND(m.ngastax3, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           loentry.accountref.listid.setvalue(m.ctaxacct3)
                           loentry.amount.setvalue(ABS(m.ngastax3))
                           loentry.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.ngastax3
                        ENDIF
                     ELSE
                        IF m.ngastax3 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.ngastax3)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.ngastax3)
                        ENDIF
                        llpostqb	  = .T.
                        m.ngastax3 = ROUND(m.ngastax3, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        loentry.accountref.listid.setvalue(m.ctaxacct3)
                        loentry.amount.setvalue(ABS(m.ngastax3))
                        loentry.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.ngastax3
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'G')
                        IF m.ngastax3 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.ngastax3)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.ngastax3)
                        ENDIF
                        llpostqb	  = .T.
                        m.ngastax3 = ROUND(m.ngastax3, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        IF THIS.BillableAcct(lcRevClear)
                           loentry.billablestatus.setvalue(1) && Not Billable
                        ENDIF
                        loentry.accountref.listid.setvalue(lcRevClear)
                        loentry.amount.setvalue(ABS(m.ngastax3))
                        loentry.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.ngastax3
                     ELSE
                        IF NOT m.ldirgaspurch
                           IF m.ngastax3 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.ngastax3)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.ngastax3)
                           ENDIF
                           llpostqb	 = .T.
                           m.ngastax3 = ROUND(m.ngastax3, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           IF THIS.BillableAcct(lcRevClear)
                              loentry.billablestatus.setvalue(1) && Not Billable
                           ENDIF
                           loentry.accountref.listid.setvalue(lcRevClear)
                           loentry.amount.setvalue(ABS(m.ngastax3))
                           loentry.MEMO.setvalue('Gas Tax 3 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.ngastax3
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.nothtax3 # 0
                  IF m.nothtax3 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.nothtax3)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.nothtax3)
                  ENDIF
                  IF NOT m.lsev3p
                     loentry.accountref.listid.setvalue(m.ctaxacct3)
                  ELSE
                     IF THIS.BillableAcct(lcRevClear)
                        loentry.billablestatus.setvalue(1) && Not Billable
                     ENDIF
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  llpostqb	= .T.
                  m.nothtax3	= ROUND(m.nothtax3, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.amount.setvalue(ABS(m.nothtax3))
                  loentry.MEMO.setvalue('Other Tax 3 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.nothtax3
               ENDIF

               IF m.noiltax4 # 0
                  IF NOT m.lsev4o
                     IF INLIST(m.cdirect, 'B', 'O')
                        IF NOT m.ldiroilpurch
                           IF m.noiltax4 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.noiltax4)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.noiltax4)
                           ENDIF
                           llpostqb	 = .T.
                           m.noiltax4 = ROUND(m.noiltax4, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           loentry.accountref.listid.setvalue(m.ctaxacct4)
                           loentry.amount.setvalue(ABS(m.noiltax4))
                           loentry.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.noiltax4
                        ENDIF
                     ELSE
                        IF m.noiltax4 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.noiltax4)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.noiltax4)
                        ENDIF
                        llpostqb	  = .T.
                        m.noiltax4 = ROUND(m.noiltax4, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        loentry.accountref.listid.setvalue(m.ctaxacct4)
                        loentry.amount.setvalue(ABS(m.noiltax4))
                        loentry.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.noiltax4
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'O')
                        IF m.noiltax4 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.noiltax4)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.noiltax4)
                        ENDIF
                        llpostqb	  = .T.
                        m.noiltax4 = ROUND(m.noiltax4, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        IF THIS.BillableAcct(lcRevClear)
                           loentry.billablestatus.setvalue(1) && Not Billable
                        ENDIF
                        loentry.accountref.listid.setvalue(lcRevClear)
                        loentry.amount.setvalue(ABS(m.noiltax4))
                        loentry.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.noiltax4
                     ELSE
                        IF NOT m.ldiroilpurch
                           IF m.noiltax4 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.noiltax4)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.noiltax4)
                           ENDIF
                           llpostqb	 = .T.
                           m.noiltax4 = ROUND(m.noiltax4, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           IF THIS.BillableAcct(lcRevClear)
                              loentry.billablestatus.setvalue(1) && Not Billable
                           ENDIF
                           loentry.accountref.listid.setvalue(lcRevClear)
                           loentry.amount.setvalue(ABS(m.noiltax4))
                           loentry.MEMO.setvalue('Oil Tax 4 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.noiltax4
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.ngastax4 # 0
                  IF NOT m.lsev4g
                     IF INLIST(m.cdirect, 'B', 'G')
                        IF NOT m.ldirgaspurch
                           IF m.ngastax4 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.ngastax4)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.ngastax4)
                           ENDIF
                           llpostqb	 = .T.
                           m.ngastax4 = ROUND(m.ngastax4, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           loentry.accountref.listid.setvalue(m.ctaxacct4)
                           loentry.amount.setvalue(ABS(m.ngastax4))
                           loentry.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.ngastax4
                        ENDIF
                     ELSE
                        IF m.ngastax4 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.ngastax4)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.ngastax4)
                        ENDIF
                        llpostqb	  = .T.
                        m.ngastax4 = ROUND(m.ngastax4, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        loentry.accountref.listid.setvalue(m.ctaxacct4)
                        loentry.amount.setvalue(ABS(m.ngastax4))
                        loentry.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.ngastax4
                     ENDIF
                  ELSE
                     IF NOT INLIST(m.cdirect, 'B', 'G')
                        IF m.ngastax4 < 0
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                           ELSE
                              loentry = loentryadd.journaldebitlinelist.APPEND
                           ENDIF
                           lndebits = lndebits + ABS(m.ngastax4)
                        ELSE
                           IF THIS.qbfcversion > QBFCVER
                              loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                           ELSE
                              loentry = loentryadd.journalcreditlinelist.APPEND
                           ENDIF
                           lncredits = lncredits + ABS(m.ngastax4)
                        ENDIF
                        llpostqb	  = .T.
                        m.ngastax4 = ROUND(m.ngastax4, 2)
                        IF llvalidwell
                           loentry.classref.listid.setvalue(lcwelllistid)
                        ENDIF
                        loentry.entityref.listid.setvalue(lcownerlistid)
                        IF THIS.BillableAcct(lcRevClear)
                           loentry.billablestatus.setvalue(1) && Not Billable
                        ENDIF
                        loentry.accountref.listid.setvalue(lcRevClear)
                        loentry.amount.setvalue(ABS(m.ngastax4))
                        loentry.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                        lnBalance = lnBalance - m.ngastax4
                     ELSE
                        IF NOT m.ldirgaspurch
                           IF m.ngastax4 < 0
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                              ELSE
                                 loentry = loentryadd.journaldebitlinelist.APPEND
                              ENDIF
                              lndebits = lndebits + ABS(m.ngastax4)
                           ELSE
                              IF THIS.qbfcversion > QBFCVER
                                 loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                              ELSE
                                 loentry = loentryadd.journalcreditlinelist.APPEND
                              ENDIF
                              lncredits = lncredits + ABS(m.ngastax4)
                           ENDIF
                           llpostqb	 = .T.
                           m.ngastax4 = ROUND(m.ngastax4, 2)
                           IF llvalidwell
                              loentry.classref.listid.setvalue(lcwelllistid)
                           ENDIF
                           loentry.entityref.listid.setvalue(lcownerlistid)
                           IF THIS.BillableAcct(lcRevClear)
                              loentry.billablestatus.setvalue(1) && Not Billable
                           ENDIF
                           loentry.accountref.listid.setvalue(lcRevClear)
                           loentry.amount.setvalue(ABS(m.ngastax4))
                           loentry.MEMO.setvalue('Gas Tax 4 ' + m.hyear + '/' + m.hperiod)
                           lnBalance = lnBalance - m.ngastax4
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF

               IF m.nothtax4 # 0
                  IF m.nothtax4 < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.nothtax4)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.nothtax4)
                  ENDIF
                  IF NOT m.lsev4p
                     loentry.accountref.listid.setvalue(m.ctaxacct4)
                  ELSE
                     IF THIS.BillableAcct(lcRevClear)
                        loentry.billablestatus.setvalue(1) && Not Billable
                     ENDIF
                     loentry.accountref.listid.setvalue(lcRevClear)
                  ENDIF
                  llpostqb	= .T.
                  m.nothtax4	= ROUND(m.nothtax4, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.amount.setvalue(ABS(m.nothtax4))
                  loentry.MEMO.setvalue('Other Tax 4 ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.nothtax4
               ENDIF

               *
               *  Post Marketing Expenses
               *
               IF m.nmktgexp # 0
                  IF m.nmktgexp < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.nmktgexp)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.nmktgexp)
                  ENDIF
                  llpostqb	= .T.
                  m.nmktgexp	= ROUND(m.nmktgexp, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcExpClear)
                  loentry.amount.setvalue(ABS(m.nmktgexp))
                  loentry.MEMO.setvalue('Marketing Expense ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.nmktgexp
               ENDIF


               *
               *  Post compression and gathering
               *
               IF m.ncompress # 0
                  IF m.ncompress < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ncompress)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ncompress)
                  ENDIF
                  llpostqb	 = .T.
                  m.ncompress = ROUND(m.ncompress, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.ncompress))
                  loentry.MEMO.setvalue('Compression Charge ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ncompress
               ENDIF

               IF m.ngather # 0
                  IF m.ngather < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ngather)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ngather)
                  ENDIF
                  llpostqb  = .T.
                  m.ngather = ROUND(m.ngather, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcRevClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcRevClear)
                  loentry.amount.setvalue(ABS(m.ngather))
                  loentry.MEMO.setvalue('Gathering Charge ' + m.hyear + '/' + m.hperiod)
                  lnBalance = lnBalance - m.ngather
               ENDIF

               *  Post the Expenses
               lnexpense = m.nexpense + ;
                  m.ntotale1 + ;
                  m.ntotale2 + ;
                  m.ntotale3 + ;
                  m.ntotale4 + ;
                  m.ntotale5 + ;
                  m.ntotalea + ;
                  m.ntotaleb + ;
                  m.nPlugExp

               IF lnexpense # 0
                  IF lnexpense < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(lnexpense)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(lnexpense)
                  ENDIF
                  llpostqb  = .T.
                  lnexpense = ROUND(lnexpense, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(lcExpClear)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(lcExpClear)
                  loentry.amount.setvalue(ABS(lnexpense))
                  loentry.MEMO.setvalue('Well Expenses: ' + m.hyear + '/' + m.hperiod )
                  lnBalance = lnBalance - lnexpense
               ENDIF

               *  Post Backup Withholding
               IF m.nbackwith # 0
                  IF m.nbackwith < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.nbackwith)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.nbackwith)
                  ENDIF
                  llpostqb	 = .T.
                  m.nbackwith = ROUND(m.nbackwith, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  IF THIS.BillableAcct(m.cbackwith)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.cbackwith)
                  loentry.amount.setvalue(ABS(m.nbackwith))
                  loentry.MEMO.setvalue('Backup W/H ' + m.hyear + '/' + m.hperiod)
               ENDIF

               *  Post Tax Withholding
               IF m.ntaxwith # 0
                  IF m.ntaxwith < 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.ntaxwith)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.ntaxwith)
                  ENDIF
                  llpostqb	= .T.
                  m.ntaxwith	= ROUND(m.ntaxwith, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  IF THIS.BillableAcct(m.ctaxwith)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  loentry.accountref.listid.setvalue(m.ctaxwith)
                  loentry.amount.setvalue(ABS(m.ntaxwith))
                  loentry.MEMO.setvalue('Income Tax W/H ' + m.hyear + '/' + m.hperiod)
               ENDIF

               *  Post Payment
               IF m.crectype = 'P'
                  IF m.nnetcheck > 0
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loentryadd.journaldebitlinelist.APPEND
                     ENDIF
                     lndebits = lndebits + ABS(m.nnetcheck)
                  ELSE
                     IF THIS.qbfcversion > QBFCVER
                        loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loentryadd.journalcreditlinelist.APPEND
                     ENDIF
                     lncredits = lncredits + ABS(m.nnetcheck)
                  ENDIF
                  llpostqb	 = .T.
                  m.nnetcheck = ROUND(m.nnetcheck, 2)
                  IF llvalidwell
                     loentry.classref.listid.setvalue(lcwelllistid)
                  ENDIF
                  loentry.entityref.listid.setvalue(lcownerlistid)
                  IF THIS.BillableAcct(m.cdefacct)
                     loentry.billablestatus.setvalue(1) && Not Billable
                  ENDIF
                  loentry.accountref.listid.setvalue(m.cdefacct)
                  loentry.amount.setvalue(ABS(m.nnetcheck))
                  loentry.MEMO.setvalue('Payment')
               ENDIF
            ENDSCAN
         ENDSCAN

         lcidchec = ''

         IF lndebits # lncredits
            lnBal = ROUND(lndebits - lncredits, 2)
            IF lnBal < 0
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journaldebitline
               ELSE
                  loentry = loentryadd.journaldebitlinelist.APPEND
               ENDIF
            ELSE
               IF THIS.qbfcversion > QBFCVER
                  loentry = loentryadd.ORJournalLineList.APPEND.journalcreditline
               ELSE
                  loentry = loentryadd.journalcreditlinelist.APPEND
               ENDIF
            ENDIF
            loentry.entityref.listid.setvalue(lcownerlistid)
            IF THIS.BillableAcct(lcSuspense)
               loentry.billablestatus.setvalue(1) && Not Billable
            ENDIF
            loentry.accountref.listid.setvalue(lcSuspense)
            loentry.amount.setvalue(ABS(lnBal))
            loentry.MEMO.setvalue('Out of Balance Entry')
         ENDIF

         IF llpostqb
            * llPostQB is set when there was any activity found in the
            * processing above. This tells us we have info to post to QB.
            * It keeps us from posting empty journal entries.
            lcxml = THIS.oqbrequest.toxmlstring()
            THIS.SaveXML(m.cOwnerID, lcXML)

            loresponse = THIS.oqbsm.dorequests(THIS.oqbrequest)
            loaddresp  = loresponse.responselist.getat(0)

            IF loaddresp.statuscode # 0
               lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
               llResult = m.goapp.oQB.QBListID(lcListID)
               IF llResult
                  MESSAGEBOX('The QuickBooks unique ID attached to ' + ALLTRIM(QBListID.cdescription) + ;
                     ' does not exist in QuickBooks. Please fix and try again.',0,'QuickBooks Posting Error')
               ELSE
                  MESSAGEBOX(loaddresp.statusmessage, 0, 'QuickBooks Posting Error')
               ENDIF
               TRY
                  IF VARTYPE(THIS.oprogress) = 'O'
                     THIS.oprogress.closeprogress()
                  ENDIF
               CATCH
               ENDTRY
               THIS.ClearErrorRecovery()
               RETURN .F.
            ELSE
               lonewbill	= loaddresp.DETAIL
               m.ctxnid	= lonewbill.txnid.getvalue()
               THIS.ClearErrorRecovery()
               SWSELECT('qbpost')
               LOCATE FOR cidsysctl = THIS.csysctlkey AND ntype = lnJournal
               IF NOT FOUND()
                  m.ntype   = lnJournal
                  m.mtxnids = m.ctxnid
                  INSERT INTO qbpost FROM MEMVAR
               ELSE
                  IF NOT EMPTY(ALLT(mtxnids))
                     REPL mtxnids WITH ALLT(mtxnids) + CHR(13) + m.ctxnid
                  ELSE
                     REPL mtxnids WITH m.ctxnid
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
         THIS.oqbrequest.ClearRequests()
      ENDSCAN

      THIS.oqbrequest.ClearRequests()

      IF NOT THIS.lquiet
         IF VARTYPE(THIS.oprogress) = 'O'
            THIS.oprogress.closeprogress()
         ENDIF

         DOEVENTS
         THIS.oprogress = .NULL.
      ENDIF

   ENDIF
   ENDPROC

   ***************************
   PROCEDURE ERROR
   ***************************
   LPARAMETERS nError, cMethod, nLine

   IF nError = 1429 OR nError = 1426
      AERROR(myerrors)
      THIS.lerror_recovery_error	= .T.
      THIS.lqberror				= .T.
      THIS.qberror(nError, cMethod, nLine)
   ELSE
      IF VARTYPE(m.goapp) = 'O'
         m.goapp.ERROR(nError, cMethod, nLine)
      ELSE
         MESSAGEBOX('Error: ' + TRANSFORM(nError) + CHR(13) + ;
            'Method: ' + cMethod + CHR(13) + ;
            'Line:   ' + TRANSFORM(nLine), 0, 'Error')
      ENDIF
   ENDIF
   ENDPROC

   ***************************
   PROCEDURE qbownerbal
   ***************************
   LPARAMETERS tcownerid, tddate, tcAcctListID

   LOCAL lcOwnerName, lcownerlistid, llAcctPassed
   LOCAL loReportQuery, loresponselist, loresponse
   LOCAL lorequest, loReport, lnRows, lnCols
   LOCAL loReportData, loColdata, lcname, lnamount

   * Initialize return variable
   lnamount = 0

   * Check to see if the QB link is active.
   * If not, just return 0
   IF THIS.lqbactive
      * Check the validity of the passed owner ID
      IF EMPTY(tcownerid)
         MESSAGEBOX('QBOwnerBal: A valid owner ID must be passed to qbOwnerBal',16,'QB Processing')
         RETURN 0
      ENDIF

      * Check on the account name parameter
      IF EMPTY(tcAcctListID) OR tcAcctListID = '**'
         llAcctPassed = .F.
      ELSE
         llAcctPassed = .T.
      ENDIF

      * Check the validity of the date parameter
      IF EMPTY(tddate)
         tddate = {01/01/1980}
      ELSE
         IF VARTYPE(tddate) # 'D'
            MESSAGEBOX('QBOwnerBal: The date parameter is invalid',16,'QB Processing')
            RETURN 0
         ENDIF
      ENDIF

      * Make sure the owner table is open
      SWSELECT('investor')

      * Get the owner name
      SELECT investor
      SET ORDER TO cOwnerID
      IF NOT SEEK(tcownerid)
         MESSAGEBOX('QBOwnerBal: Owner: ' + tcownerid + ' is not a valid owner.',16,'QB Processing')
         RETURN 0
      ELSE
         lcownerlistid = cListID
      ENDIF

      THIS.oqbsm.EnableErrorRecovery = .F.

      * get a message set request object (version 1.1 xml)
      lorequest = THIS.oqbrequest

      * set the on error attribute for the request
      lorequest.ATTRIBUTES.OnError = 1

      lorequest.ClearRequests()

      loReportQuery = lorequest.AppendGeneralSummaryReportQueryRq()

      loReportQuery.GeneralSummaryReportType.setvalue(4)
      loReportQuery.ReportEntityFilter.ORReportEntityFilter.ListIDList.ADD(lcownerlistid)
      loReportQuery.ORReportPeriod.ReportPeriod.ToReportDate.setvalue(tddate)
      * Set the account filter if passed
      IF llAcctPassed
         loReportQuery.ReportAccountFilter.ORReportAccountFilter.ListIDList.ADD(tcAcctListID)
      ENDIF
      loresponslist = THIS.oqbsm.dorequests(lorequest)
      loresponse	   = loresponslist.responselist.getat(0)

      lnamount = 0

      IF loresponse.statuscode = 0
         loReport = loresponse.DETAIL

         lnRows = loReport.NumRows.getvalue()
         lnCols = loReport.NumColumns.getvalue()

         IF VARTYPE(loReport.ReportData) = 'O'
            FOR lni = 0 TO loReport.ReportData.ORReportDataList.COUNT - 1
               loReportData = loReport.ReportData.ORReportDataList.getat(lni)

               IF VARTYPE(loReportData.DataRow) = 'O'
                  loColdata = loReportData.DataRow.ColDataList.getat(0)
                  lcname	   = loColdata.VALUE.getvalue()
                  loColdata = loReportData.DataRow.ColDataList.getat(1)
                  lnamount  = VAL(loColdata.VALUE.getvalue())
                  lorequest.ClearRequests()
               ENDIF
            ENDFOR
         ENDIF
      ENDIF

      THIS.oqbsm.EnableErrorRecovery = .T.
   ELSE
      lnamount = 0
   ENDIF

   RETURN (lnamount)
   ENDPROC

   *******************************************
   PROCEDURE QBListID
   *******************************************
   LPARAMETERS tcListID, tnDataSession, tlMenu

   *
   *  Does a lookup of the given list id in all SherWare
   *  tables to find out where it came from. This is used
   *  when QuickBooks returns an error of
   *  "Object xxxxxxx listid not found". We'll call this
   *  routine so we can give the user good feedback on
   *  what entity is not synchronized with QB.
   *

   IF VARTYPE(tnDataSession) = 'N'
      TRY
         SET DATASESSION TO (tnDataSession)
      CATCH TO loError
      ENDTRY
   ENDIF

   IF EMPTY(tcListID)
      tcListID = "     "
   ENDIF

   llreturn = .F.

   tcListID = PADR(ALLTRIM(tcListID), 36, ' ')

   * Create the temp cursor that contains the info
   IF USED('qblistid')
      USE IN QBListID
   ENDIF

   CREATE CURSOR QBListID ;
      (cListID      c(36), ;
      ctype        c(15), ;
      cdescription c(60))

   * Check for a valid listID being passed
   IF VARTYPE(tcListID) # 'C'
      m.cListID		= 'None Passed'
      m.ctype		= 'Bad ListID'
      m.cdescription	= 'Bad ListID Parameter Passed to QBListID'
      INSERT INTO QBListID FROM MEMVAR
      RETURN .F.
   ENDIF

   m.cListID = tcListID

   TRY
      * Look in Wells
      SWSELECT('wells')
      LOCATE FOR cListID == tcListID
      IF FOUND()
         m.ctype		= 'Well'
         m.cdescription	= 'Well: ' + ALLTRIM(cWellID) + ' - ' + cwellname
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look in investor
      SWSELECT('investor')
      LOCATE FOR cListID == tcListID
      IF FOUND()
         m.ctype		= 'Owner'
         m.cdescription	= 'Owner: ' + ALLTRIM(cOwnerID) + ' - ' + csortfield
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look in Vendor
      SWSELECT('vendor')
      LOCATE FOR cListID == tcListID
      IF FOUND()
         m.ctype		= 'Vendor'
         m.cdescription	= 'Vendor: ' + cvendname
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look in Expcat
      SWSELECT('expcat')
      LOCATE FOR cListID == tcListID
      IF FOUND()
         m.ctype		= 'Exp Code'
         m.cdescription	= 'Exp Code: ' + cCatCode + ' - ' + ccateg
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      SWSELECT('vendor')
      LOCATE FOR linteggl = .T.
      IF FOUND()
         * Look at vendor posting accts in expcat
         SELECT expcat
         LOCATE FOR cvendacctlistid == tcListID
         IF FOUND()
            m.ctype		   = 'Exp Codes'
            m.cdescription = 'Vendor Posting Acct in Exp Code: ' + cCatCode
            INSERT INTO QBListID FROM MEMVAR
            IF NOT EMPTY(tcListID)
               llreturn = .T.
               EXIT
            ENDIF
         ENDIF
      ENDIF

      SWSELECT('investor')
      LOCATE FOR linteggl = .T.
      IF FOUND()

         * Look at owner posting accounts in expcat
         SELECT expcat
         LOCATE FOR cownacctlistid == tcListID
         IF FOUND()
            m.ctype		   = 'Exp Codes'
            m.cdescription = 'Owner Posting Acct in Exp Code: ' + cCatCode
            INSERT INTO QBListID FROM MEMVAR
            IF NOT EMPTY(tcListID)
               llreturn = .T.
               EXIT
            ENDIF
         ENDIF

         * Look in Revcat
         SWSELECT('revcat')
         LOCATE FOR ccracctnow == tcListID
         IF FOUND()
            m.ctype		   = 'Rev Categories'
            m.cdescription = 'Working Int Posting Acct for ' + crevtype + 'Revenue'
            INSERT INTO QBListID FROM MEMVAR
            IF NOT EMPTY(tcListID)
               llreturn = .T.
               EXIT
            ENDIF
         ENDIF
         LOCATE FOR ccracctnol == tcListID
         IF FOUND()
            m.ctype		   = 'Rev Categories'
            m.cdescription = 'Royalty Int Posting Acct for ' + crevtype + 'Revenue'
            INSERT INTO QBListID FROM MEMVAR
            IF NOT EMPTY(tcListID)
               llreturn = .T.
               EXIT
            ENDIF
         ENDIF
         LOCATE FOR ccracctnoo == tcListID
         IF FOUND()
            m.ctype		   = 'Rev Categories'
            m.cdescription = 'Override Int Posting Acct for ' + crevtype + 'Revenue'
            INSERT INTO QBListID FROM MEMVAR
            IF NOT EMPTY(tcListID)
               llreturn = .T.
               EXIT
            ENDIF
         ENDIF
      ENDIF

      * Look in Purchasers
      SWSELECT('revsrc')
      LOCATE FOR cListID == tcListID
      IF FOUND()
         m.ctype		= 'Purchaser'
         m.cdescription	= 'Purchaser: ' + cRevName
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in glopt
      SWSELECT('glopt')
      LOCATE FOR crevclear == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Revenue Clearing Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in glopt
      SWSELECT('glopt')
      LOCATE FOR cexpclear == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Expense Clearing Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in glopt
      SWSELECT('glopt')
      LOCATE FOR csuspense == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Catch-All Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR cdisbacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Disbursement Cash Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR cdefacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Owner Deficit Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR cminacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Owner Minimum Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR cjibacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'JIB Receivable Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR ctaxacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Tax Withholding Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR cbackacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Backup Withholding Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR cgathacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Compression/Gathering Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR ctaxacct1 == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Severance Tax Account 1'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR ctaxacct2 == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Severance Tax Account 2'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR ctaxacct3 == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Severance Tax Account 3'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR ctaxacct4 == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Severance Tax Account 4'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in options
      SWSELECT('options')
      LOCATE FOR cfixedacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Fixed Expense Clearing Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at accounts in apopt
      SWSELECT('apopt')
      LOCATE FOR cAPAcct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Accounts Payable Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at Terms codes
      SWSELECT('terms')
      LOCATE FOR cListID == tcListID
      IF FOUND()
         m.ctype		= 'Terms'
         m.cdescription	= 'Terms Code: ' + ALLTRIM(terms.cTermDesc)
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

      * Look at Land Options
      SWSELECT('landopt')
      LOCATE FOR ccashacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Cash Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF
      LOCATE FOR crentacct == tcListID
      IF FOUND()
         m.ctype		= 'Account'
         m.cdescription	= 'Rent Account'
         INSERT INTO QBListID FROM MEMVAR
         IF NOT EMPTY(tcListID)
            llreturn = .T.
            EXIT
         ENDIF
      ENDIF

   CATCH TO loErr

   ENDTRY

   RETURN llreturn

   ENDPROC

   ***********************************
   PROCEDURE BillableAcct
   ***********************************
   LPARAMETERS tcAcctListID
   * Returns .T. if the account represented by the passed list id
   * is an Other Current Asset, Expense or Other Current Expense type
   * account.  Those account types are the only ones that can set
   * the billable status.
   LOCAL llreturn
   llreturn = .F.

   *  Return .f. for now until we figure out how this is supposed to work - pws 9/23/10
   RETURN llreturn

   IF NOT USED('accounts')
      THIS.QBAccounts(, , .T.)
   ENDIF

   SELECT accounts
   LOCATE FOR cListID == tcAcctListID
   IF FOUND()
      IF cAcctType = 'Other Current Asset'
         llreturn = .T.
      ENDIF
      IF cAcctType = 'Expense'
         llreturn = .T.
      ENDIF
      IF cAcctType = 'Other Expense'
         llreturn = .T.
      ENDIF
   ENDIF

   RETURN llreturn

   **********************
   PROCEDURE RemoveRevRun
   **********************
   LPARAMETERS tcyear, tnrunno, tcgroup, tcSysCtl, tlVoidCheck
   LOCAL loError, llreturn, lncount, lcTxnIDs, m.cidsysctl
   LOCAL lnCheck, lnJournal

   llreturn = .T.

   m.cidsysctl = tcSysCtl
   SWSELECT('sysctl')

   TRY
      IF m.goapp.oQB.lqbactive

         IF m.goapp.oQB.qbfcversion > ' 4.0'
            lnCheck	 = 6
            lnVoid	 = 5
            lnJournal = 15
         ELSE
            lnCheck	 = 11
            lnJournal = 14
         ENDIF


         THIS.ClearErrorRecovery()

         *  Get a message set request object (version 1.1 xml)
         lorequest = m.goapp.oQB.oqbrequest

         * set the on error attribute for the request
         lorequest.ClearRequests()
         lorequest.ATTRIBUTES.OnError = 1
         SWSELECT('qbpost')
         SCAN FOR cidsysctl = m.cidsysctl AND ntype = lnJournal
            lcTxnIDs	 = mtxnids
            lncount	 = ALINES(laTxnid, lcTxnIDs)
            oprogress = m.goapp.omessage.progressbar('Removing Revenue Run From QuickBooks....')
            oprogress.setprogressrange(0, lncount)
            IF lncount > 0
               FOR lnx = 1 TO lncount
                  oprogress.updateprogress(lnx)
                  lcTxnID = PADR(ALLT(laTxnid[lnX]), 36, ' ')

                  loJournalDel = lorequest.AppendTxnDelRq()
                  loJournalDel.TxnDelType.setvalue(qbpost.ntype)
                  loJournalDel.txnid.setvalue(lcTxnID)
                  loresponse	= m.goapp.oQB.oqbsm.dorequests(lorequest)
                  loDelResp	= loresponse.responselist.getat(0)
                  m.goapp.oQB.oqbsm.ClearErrorRecovery()
                  lorequest.ClearRequests()
                  lorequest.ATTRIBUTES.OnError = 1
               ENDFOR
            ENDIF
            oprogress.closeprogress()
            SELE qbpost
            DELE NEXT 1
         ENDSCAN
         WAIT CLEAR

         IF tlVoidCheck
            WAIT WIND NOWAIT 'Voiding QuickBooks Checks..'
            m.goapp.oQB.oqbsm.ClearErrorRecovery()
            SELE qbpost
            SCAN FOR cidsysctl = m.cidsysctl AND ntype = lnCheck
               m.ntype  = ntype
               lcTxnIDs = mtxnids
               lncount  = ALINES(laTxnid, lcTxnIDs)
               IF lncount > 0
                  FOR lnx = 1 TO lncount
                     lcTxnID	  = PADR(ALLT(laTxnid[lnX]), 36, ' ')
                     loTxnVoid = m.goapp.oQB.oqbrequest.AppendTxnVoidRq()
                     loTxnVoid.TxnVoidType.setvalue(lnVoid)
                     loTxnVoid.txnid.setvalue(lcTxnID)

                     loresponse = m.goapp.oQB.oqbsm.dorequests(m.goapp.oQB.oqbrequest)
                     loDelResp  = loresponse.responselist.getat(0)
                     m.goapp.oQB.oqbrequest.ClearRequests()
                     m.goapp.oQB.oqbsm.ClearErrorRecovery()
                  ENDFOR
               ENDIF
               * Delete the qbpost record
               SELECT qbpost
               DELETE NEXT 1
            ENDSCAN
         ENDIF
      ENDIF
   CATCH TO loError
      llreturn = .F.
      DO errorlog WITH 'RemoveRevRun', loError.LINENO, 'oQB', loError.ERRORNO, loError.MESSAGE, '', loError
      MESSAGEBOX('Unable to remove the revenue run from QuickBooks at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY

   RETURN llreturn

   ****************************
   PROCEDURE Well_Activity
   ****************************
   LPARAMETERS tlCreate, tcwellid
   LOCAL m.cWellID
   * Check to see if the well had any income or expense activity

   IF tlCreate
      SELECT  cWellID ;
         FROM income ;
         WHERE nrunno == THIS.nrunno ;
         AND crunyear == THIS.crunyear ;
         INTO CURSOR wellactivity READWRITE ;
         ORDER BY cWellID ;
         GROUP BY cWellID

      SELECT  cWellID ;
         FROM expense ;
         WHERE nrunnorev == THIS.nrunno ;
         AND crunyearrev == THIS.crunyear ;
         INTO CURSOR temp ;
         ORDER BY cWellID ;
         GROUP BY cWellID

      SELECT temp
      SCAN
         SCATTER MEMVAR
         SELECT wellactivity
         LOCATE FOR cWellID == m.cWellID
         IF NOT FOUND()
            INSERT INTO wellactivity FROM MEMVAR
         ENDIF
      ENDSCAN
   ELSE
      IF NOT USED('wellactivity')
         THIS.Well_Activity(.T.)
      ENDIF

      SELECT wellactivity
      LOCATE FOR cWellID == tcwellid
      IF FOUND()
         llreturn = .T.
      ELSE
         llreturn = .F.
      ENDIF

      RETURN llreturn
   ENDIF

   ****************************
   PROCEDURE SetErrorMode
   ****************************
   LOCAL nOldMode

   * Turn off critical windows error messages for this process

   DECLARE INTEGER SetErrorMode IN kernel32;
      INTEGER uMode

   nOldMode = SetErrorMode(1)

   RETURN

   ************************************************************
   FUNCTION IsQBRunning()
   ************************************************************
   * Looks to see if QBW32.EXE is running and has a
   * visible window.
   * Returns the .T. if QB is running
   *
   LOCAL cPath, lnProcess
   LOCAL llreturn, loError, llError
   #DEFINE VFP2C_INIT_ALL		0xFFFFFFFF
   llreturn = .F.
   DIMENSION laProcess[1, 5]
   DIMENSION laWindow[1]

   lnProcess = 0

   TRY
      llError = .F.

      SET LIBRARY TO datafiles\bin\vfp2c32.fll ADDITIVE
      INITVFP2C32(VFP2C_INIT_ALL)

      * Contains the process ids of all qbw32.exe processes
      CREATE CURSOR temprows ;
         (nRow     I, ;
         nprocess I)

      * Get the list of processes and look for qbw32.exe
      lnProcesses = AProcesses('laProcess')
      lnWindows	 = AWindowsEx('laWindow', 'TWOV', 1)
      m.nRow		 = ASCAN(laProcess, 'qbw32.exe', 1, -1, 1, 13)
      DO WHILE m.nRow > 0
         m.nprocess = laProcess[m.nRow, 2]
         INSERT INTO temprows FROM MEMVAR
         IF m.nRow + 1 <= lnProcesses
            m.nRow = ASCAN(laProcess, 'qbw32.exe', m.nRow + 1, -1, 1, 13)
         ELSE
            m.nRow = 0
         ENDIF
      ENDDO

      m.nRow		 = ASCAN(laProcess, 'qbw.exe', 1, -1, 1, 13)
      DO WHILE m.nRow > 0
         m.nprocess = laProcess[m.nRow, 2]
         INSERT INTO temprows FROM MEMVAR
         IF m.nRow + 1 <= lnProcesses
            m.nRow = ASCAN(laProcess, 'qbw.exe', m.nRow + 1, -1, 1, 13)
         ELSE
            m.nRow = 0
         ENDIF
      ENDDO

      * Look through all qb processes to see if any don't have
      * a visible window. If the process doesn't that means that it
      * is an orphan and will keep us from integrating with it.
      SELECT temprows
      SCAN
         SCATTER MEMVAR

         lnRow = ASCAN(laWindow, m.nprocess, 1, -1, 3, 8)
         DO WHILE lnRow > 0 AND NOT llreturn
            lcWindow = laWindow[lnRow, 1]
            lcWindow = STRTRAN(lcWindow,':','')
            IF 'quickbooks desktop' $ LOWER(lcWindow) OR ;
                  'quickbooks pro' $ LOWER(lcWindow) OR ;
                  'quickbooks enterprise' $ LOWER(lcWindow) OR  ;
                  'quickbooks premier' $ LOWER(lcWindow) OR ;
                  'quickbooks accountant' $ LOWER(lcWindow)
               IF laWindow[lnRow, 4] = .T.
                  llreturn = .T.
               ENDIF
            ENDIF
            IF lnRow + 1 <= lnWindows
               lnRow = ASCAN(laWindow, m.nprocess, lnRow + 1, -1, 3, 8)
            ELSE
               lnRow = 0
            ENDIF
         ENDDO
      ENDSCAN

   CATCH TO loError
      llError = .T.
   ENDTRY

   RETURN llreturn


   ************************************************************
   PROCEDURE QBOrphanProcess
   ************************************************************
   * Looks to see if QBW32.EXE is running without having a
   * visible window.
   * Returns the process id if an orphan is found
   *
   LOCAL cPath, lnProcess
   LOCAL llreturn, loError, llError
   #DEFINE VFP2C_INIT_ALL		0xFFFFFFFF
   llreturn = .T.
   DIMENSION laProcess[1, 5]
   DIMENSION laWindow[1]

   lnProcess = 0

   TRY
      llError = .F.

      SET LIBRARY TO datafiles\bin\vfp2c32.fll ADDITIVE
      INITVFP2C32(VFP2C_INIT_ALL)

      * Contains the process ids of all qbw32.exe processes
      CREATE CURSOR temprows ;
         (nRow     I, ;
         nprocess I)

      * Get the list of processes and look for qbw32.exe
      lnProcesses = AProcesses('laProcess')
      lnWindows	 = AWindowsEx('laWindow', 'TWOV', 1)
      m.nRow		 = ASCAN(laProcess, 'qbw32.exe', 1, -1, 1, 13)
      DO WHILE m.nRow > 0
         m.nprocess = laProcess[m.nRow, 2]
         INSERT INTO temprows FROM MEMVAR
         IF m.nRow + 1 <= lnProcesses
            m.nRow = ASCAN(laProcess, 'qbw32.exe', m.nRow + 1, -1, 1, 13)
         ELSE
            m.nRow = 0
         ENDIF
      ENDDO

      * Look through all qbw32.exe processes to see if any don't have
      * a visible window. If the process doesn't that means that it
      * is an orphan and will keep us from integrating with it.
      SELECT temprows
      SCAN
         SCATTER MEMVAR

         lnRow = ASCAN(laWindow, m.nprocess, 1, -1, 3, 8)
         DO WHILE lnRow > 0
            IF 'quickbooks' $ LOWER(laWindow[lnRow, 1])
               IF laWindow[lnRow, 4] = .T.
                  llreturn = .F.
               ENDIF
            ENDIF
            IF lnRow + 1 <= lnWindows
               lnRow = ASCAN(laWindow, m.nprocess, lnRow + 1, -1, 3, 8)
            ELSE
               lnRow = 0
            ENDIF
         ENDDO

         IF llreturn
            * We found a process that doesn't have a visible window
            lnProcess = m.nprocess
            EXIT
         ENDIF
      ENDSCAN

   CATCH TO loError
      llError = .T.
   ENDTRY

   IF lnProcess > 0
      lnRow = ASCAN(laWindow, lnProcess, 1, -1, 3, 8)
      IF lnRow > 0
         lnhWnd = laWindow[lnRow, 2]
      ELSE
         lnhWnd = 0
      ENDIF
      llreturn = KillProcess(lnProcess, lnhWnd)
   ENDIF

   RETURN llreturn

   ************************
   PROCEDURE PostReceipt
   ************************
   LPARAMETERS tcBatch
   LOCAL lcbatch, lcAPAcct,  llreturn, lcselect, lnrecno, lcFilter, lcidchec, llInvestment
   LOCAL oGLMaint

   llreturn	 = .T.
   llInvestment = .F.

   TRY

      oGLMaint = m.goapp.oGLMaint

      m.cbatch = tcBatch

      SWSELECT('csrcthdr')
      LOCATE FOR cbatch == m.cbatch
      IF FOUND()

         IF csrcthdr.nCashAmt <= 0
            THIS.cErrorMsg = 'A negative or zero balance receipt cannot be saved.  Please correct.'
            llreturn = .F.
            EXIT
         ENDIF

         IF m.goapp.oQB.lqbactive = .T.
            IF EMPTY(csrcthdr.ccashacct)
               THIS.cErrorMsg = 'A cash account must be specified.  Please choose the cash account.'
               llreturn = .F.
               EXIT
            ENDIF

            THIS.ClearErrorRecovery()
         ENDIF

         IF EMPTY(csrcthdr.dpostdate)
            REPLACE csrcthdr.dpostdate WITH csrcthdr.ddate
         ENDIF

         IF EMPTY(csrcthdr.ddate)
            THIS.cErrorMsg = 'A accounting date must be specified.  Please enter an accounting date.'
            llreturn = .F.
            EXIT
         ENDIF

         IF NOT EMPTY(csrcthdr.ctxnid)
            llDelete = .T.
            IF csrcthdr.lnoqbpost
               * Ask if the receipt should be deleted from QB since it obviously was posted to QB earlier and
               * not they're telling it not to post.
               IF MESSAGEBOX('This receipt has previously been saved to QuickBooks. ' + ;
                     'Do you want to delete the original entry from QuickBooks?',36,'Remove From QuickBooks') = 7
                  llDelete = .F.
               ENDIF
            ENDIF
            IF llDelete
               IF m.goapp.oQB.lqbactive = .T.
                  * get a message set request object (version 1.1 xml)
                  lorequest = m.goapp.oQB.oqbrequest

                  * set the on error attribute for the request
                  lorequest.ATTRIBUTES.OnError = 1
                  lorequest.ClearRequests()
                  * add a request to delete the receipt
                  loRcptDel = lorequest.AppendTxnDelRq()
                  IF m.goapp.oQB.qbfcversion > ' 4.0'
                     loRcptDel.TxnDelType.setvalue(15)
                  ELSE
                     loRcptDel.TxnDelType.setvalue(14)
                  ENDIF
                  loRcptDel.txnid.setvalue(csrcthdr.ctxnid)

                  loresponse = m.goapp.oQB.oqbsm.dorequests(lorequest)
                  loDelResp  = loresponse.responselist.getat(0)

                  IF loDelResp.statuscode = 0
                     SELECT csrcthdr
                     REPLACE ctxnid WITH ''
                  ELSE
                     IF loDelResp.statuscode = 3160 AND 'deposit' $ LOWER(loDelResp.statusmessage)
                        MESSAGEBOX('This receipt cannot be changed. It has been deposited in QuickBooks using Make Deposits.',16,'Post Receipt to QB')
                        THIS.ClearErrorRecovery()
                        llreturn = .F.
                        EXIT
                     ENDIF
                     IF 'not be locked' $ loDelResp.statusmessage
                        MESSAGEBOX('This receipt cannot be modified. QuickBooks currently has it locked.',16,'Post Receipt to QB')
                        THIS.ClearErrorRecovery()
                        llreturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
                  THIS.ClearErrorRecovery()
               ELSE
                  MESSAGEBOX('This receipt cannot be modified. The QuickBooks connection is not active.',16,'Post Receipt to QB')
                  THIS.ClearErrorRecovery()
                  llreturn = .F.
                  EXIT
               ENDIF
            ENDIF
         ENDIF

         * If the ref file exists, plug 'DM' into the reference for journal entries
         IF FILE('dmref.cfg')
            lcref = 'DM'
         ELSE
            lcref = ''
         ENDIF



         *  Look to see if this receipt has been deposited
         lcidchec = csrcthdr.cidchec

         lcselect = SELECT()
         lcbatch	 = csrcthdr.cbatch
         lcidchec = csrcthdr.cidchec

         WAIT WINDOW NOWAIT 'Saving Changes, Please Wait.....'

         *  Create the G/L journal entries for this receipt
         oGLMaint.cSource	= 'CS'
         oGLMaint.cbatch		= lcbatch
         oGLMaint.dGLDate	= csrcthdr.dpostdate
         oGLMaint.cReference	= 'Cash: ' + ALLTRIM(csrcthdr.cinvnum)
         oGLMaint.cDesc		= csrcthdr.cname
         oGLMaint.cacctno	= csrcthdr.ccashacct
         oGLMaint.cid		= csrcthdr.cid
         oGLMaint.namount	= csrcthdr.nCashAmt
         oGLMaint.cBunch		= ''
         oGLMaint.dCheckDate	= csrcthdr.dpostdate
         oGLMaint.dpostdate	= csrcthdr.dpostdate
         oGLMaint.cPayee		= csrcthdr.cname
         oGLMaint.cidchec	= ''
         oGLMaint.centrytype	= 'D'
         oGLMaint.cidtype	= 'D'
         oGLMaint.cyear		= ' '
         oGLMaint.cperiod	= ' '
         oGLMaint.lcleared	= .F.
         oGLMaint.ccheckno	= csrcthdr.ccheckno
         oGLMaint.cunitno	= ''
         oGLMaint.lPrinted	= .T.

         * Only add a register entry if the receipt is positive
         IF csrcthdr.nCashAmt > 0
            oGLMaint.addcheck()
            lcidchec = oGLMaint.GETKEY()
            SWSELECT('csrcthdr')
            REPL cidchec WITH lcidchec
            oGLMaint.cidchec    = lcidchec
         ENDIF

         * Get revenue clearing account
         SWSELECT('glopt')
         GO TOP
         lcClearAcct	= crevclear
         lcExpClear	= cexpclear

         IF EMPTY(lcClearAcct)
            lcAcct = 'Uncategorized Expenses'
            SELECT accounts
            LOCATE FOR lcAcct $ cAcctDesc
            IF FOUND()
               lcAcctListid = cListID
            ELSE
               * IF the account is invalid, post to last account
               GO BOTT
               lcAcctListid = cListID
            ENDIF
         ELSE
            lcAcctListid = lcClearAcct
         ENDIF

         *  Create the G/L journal entries for this invoice
         IF m.goapp.oQB.lqbactive

            THIS.ClearErrorRecovery()

            * get a message set request object (version 1.1 xml)
            lorequest = m.goapp.oQB.oqbrequest

            * set the on error attribute for the request
            lorequest.ATTRIBUTES.OnError = 1
            lorequest.ClearRequests()


            IF csrcthdr.lnoqbpost = .F.
               lorequest.ClearRequests()

               *  Setup the receipt add request
               loRcptAdd = lorequest.appendjournalentryaddrq()

               loRcptAdd.refnumber.setvalue(csrcthdr.ccheckno)
               loRcptAdd.txndate.setvalue(csrcthdr.dpostdate)
               *      loRcptAdd.MEMO.SetValue('** DO NOT CHANGE OR DELETE THIS ENTRY IN QUICKBOOKS **')


               *  Add the deposit to the check register
               IF m.goapp.oQB.qbfcversion > ' 4.0'
                  loDebit = loRcptAdd.ORJournalLineList.APPEND.journaldebitline
               ELSE
                  loDebit = loRcptAdd.journaldebitlinelist.APPEND
               ENDIF

               SWSELECT('revsrc')
               SET ORDER TO cRevKey
               IF SEEK(csrcthdr.cid)
                  IF EMPTY(revsrc.cListID)
                     THIS.cErrorMsg = 'The receipt cannot be saved.  The purchaser file needs to be synchronized with QuickBooks.'
                     lorequest.ClearRequests()
                     llreturn = .F.
                     EXIT
                  ENDIF
                  loDebit.entityref.listid.setvalue(revsrc.cListID)
               ELSE
                  SWSELECT('vendor')
                  SET ORDER TO cVendorID
                  IF SEEK(csrcthdr.cid)
                     loDebit.entityref.listid.setvalue(vendor.cListID)
                  ELSE
                     THIS.cErrorMsg = 'Purchaser/Vendor: ' + csrcthdr.cid + ' not found.'
                     llreturn = .F.
                     EXIT
                  ENDIF
               ENDIF

               loDebit.accountref.listid.setvalue(csrcthdr.ccashacct)
               loDebit.amount.setvalue(ROUND(csrcthdr.nCashAmt, 2))

               *  Add detail lines to check
               SWSELECT('csrctdet',.T.)
               SCAN FOR cbatch == lcbatch
                  SCATTER MEMVAR

                  IF m.namount > 0
                     IF m.goapp.oQB.qbfcversion > ' 4.0'
                        loentry = loRcptAdd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loRcptAdd.journalcreditlinelist.APPEND
                     ENDIF
                  ELSE
                     IF m.goapp.oQB.qbfcversion > ' 4.0'
                        loentry = loRcptAdd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loRcptAdd.journaldebitlinelist.APPEND
                     ENDIF
                     m.namount = ABS(m.namount)
                  ENDIF

                  IF NOT EMPTY(csrctdet.cWellID)
                     SWSELECT('wells')
                     LOCATE FOR cWellID = csrctdet.cWellID
                     IF FOUND()
                        IF EMPTY(ALLT(wells.cListID))
                           THIS.cErrorMsg = 'The receipt cannot be saved.  The wells file needs to be synchronized with QuickBooks.'
                           lorequest.ClearRequests()
                           llreturn = .F.
                           EXIT
                        ENDIF
                        loentry.classref.listid.setvalue(wells.cListID)
                        IF wells.cwellstat = "V"
                           llInvestment = .T.
                        ELSE
                           llInvestment = .F.
                        ENDIF
                     ENDIF
                  ENDIF

                  IF llInvestment
                     SWSELECT('revcat')
                     LOCATE FOR crevtype == m.ctype
                     IF FOUND()
                        IF EMPTY(ALLT(ccracctnow))
                           THIS.cErrorMsg = 'The receipt cannot be saved.  The Revenue Category needs to have a valid QuickBooks account specified.'
                           lorequest.ClearRequests()
                           llreturn = .F.
                           EXIT
                        ENDIF
                        m.cAcctListID = ccracctnow
                     ELSE
                        SWSELECT('expcat')
                        LOCATE FOR cCatCode == m.ctype
                        IF FOUND()
                           m.cAcctListID = cownacctlistid
                        ELSE
                           m.cAcctListID = ''
                        ENDIF
                     ENDIF
                  ELSE
                     SWSELECT('revcat')
                     SET ORDER TO crevtype
                     IF SEEK(m.ctype)
                        m.cAcctListID = lcClearAcct
                     ELSE
                        m.cAcctListID = lcExpClear
                     ENDIF
                  ENDIF

                  loentry.accountref.listid.setvalue(m.cAcctListID)
                  loentry.amount.setvalue(ROUND(m.namount, 2))

                  IF NOT EMPTY(csrctdet.cprodperiod)
                     lcMemoExtra =  "' Period: '+ csrctdet.cprodperiod+'/'+csrctdet.cprodyear"
                     DO CASE
                        CASE INLIST(m.ctype, 'BBL', 'MCF', 'OTH')
                           loentry.MEMO.setvalue(ALLT(STR(csrctdet.nunits, 5, 2)) + ' ' + csrctdet.ctype + ;
                              ' @ ' + ALLT(STR(csrctdet.nprice, 5, 2)) + &lcMemoExtra)
                        CASE m.ctype = 'GTAX1'
                           loentry.MEMO.setvalue('Gas Tax 1' + &lcMemoExtra)
                        CASE m.ctype = 'GTAX2'
                           loentry.MEMO.setvalue('Gas Tax 2' + &lcMemoExtra)
                        CASE m.ctype = 'GTAX3'
                           loentry.MEMO.setvalue('Gas Tax 3' + &lcMemoExtra)
                        CASE m.ctype = 'GTAX4'
                           loentry.MEMO.setvalue('Gas Tax 4' + &lcMemoExtra)
                        CASE m.ctype = 'OTAX1'
                           loentry.MEMO.setvalue('Oil Tax 1' + &lcMemoExtra)
                        CASE m.ctype = 'OTAX2'
                           loentry.MEMO.setvalue('Oil Tax 2' + &lcMemoExtra)
                        CASE m.ctype = 'OTAX3'
                           loentry.MEMO.setvalue('Oil Tax 3' + &lcMemoExtra)
                        CASE m.ctype = 'OTAX4'
                           loentry.MEMO.setvalue('Oil Tax 4' + &lcMemoExtra)
                        CASE m.ctype = 'PTAX1'
                           loentry.MEMO.setvalue('OTH Tax 1' + &lcMemoExtra)
                        CASE m.ctype = 'PTAX2'
                           loentry.MEMO.setvalue('OTH Tax 2' + &lcMemoExtra)
                        CASE m.ctype = 'PTAX3'
                           loentry.MEMO.setvalue('OTH Tax 3' + &lcMemoExtra)
                        CASE m.ctype = 'PTAX4'
                           loentry.MEMO.setvalue('OTH Tax 4' + &lcMemoExtra)
                        CASE m.ctype = 'TRANS'
                           loentry.MEMO.setvalue('Transportation' + &lcMemoExtra)
                        CASE m.ctype = 'MISC1'
                           loentry.MEMO.setvalue('Miscellaneous Revenue 1' + &lcMemoExtra)
                        CASE m.ctype = 'MISC2'
                           loentry.MEMO.setvalue('Miscellaneous Revenue 2' + &lcMemoExtra)
                        OTHERWISE  &&  Expenses - all other types should be covered above
                        SWSELECT('expcat')
                           LOCATE FOR ALLTRIM(cCatCode) = ALLTRIM(csrctdet.ctype)
                           IF FOUND()
                              loentry.MEMO.setvalue(ALLT(expcat.ccateg) + &lcMemoExtra)
                           ELSE
                              loentry.MEMO.setvalue('')
                           ENDIF
                     ENDCASE
                  ENDIF
               ENDSCAN

               IF llreturn
                  loresponse = m.goapp.oQB.oqbsm.dorequests(lorequest)
                  loaddresp  = loresponse.responselist.getat(0)

                  IF loaddresp.statuscode = 0
                     WAIT WIND NOWAIT 'Receipt successfully added in QuickBooks'
                     loNewCheck = loaddresp.DETAIL
                     m.ctxnid   = loNewCheck.txnid.getvalue()
                     THIS.ClearErrorRecovery()

                     SELE csrcthdr
                     REPL ctxnid WITH m.ctxnid

                  ELSE
                     SWSELECT('csrcthdr')
                     REPL ctxnid WITH ''

                     IF 'object' $ LOWER(loaddresp.statusmessage)
                        lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
                        llResult = m.goapp.oQB.QBListID(lcListID)
                        IF llResult
                           SELECT QBListID
                           IF QBListID.ctype = 'Account'
                              THIS.cErrorMsg = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                                 'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                                 'and try to save the receipt again.'
                           ELSE
                              THIS.cErrorMsg = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                                 'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to save the receipt again.'
                           ENDIF
                        ELSE
                           THIS.cErrorMsg = loaddresp.statusmessage
                        ENDIF
                     ELSE
                        THIS.cErrorMsg = loaddresp.statusmessage
                     ENDIF
                     THIS.ClearErrorRecovery()
                     llreturn = .F.
                     EXIT
                  ENDIF && loresp.statuscode = 0
               ENDIF && llReturn
            ENDIF && csrcthdr.lnoqbpost = .F.
         ENDIF && m.goapp.oQB.lqbactive
      ENDIF  && csrcthdr.cbatch found
   CATCH TO loError
      llreturn = .F.
      DO errorlog WITH 'PostRcptQB', loError.LINENO, 'ImportRev', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.cErrorMsg = loError.MESSAGE
   ENDTRY

   oGLMaint = .NULL.

   RETURN llreturn

   **************************
   PROCEDURE PostReceiptJV
   **************************
   * Posts a receipt to a JV - pws - 10/17/20
   * The receipt is posted to the income and expense accounts rather
   * than the revenue and expense clearing accounts
   LPARAMETERS tcBatch
   LOCAL lcbatch, lcAPAcct,  llreturn, lcselect, lnrecno, lcFilter, lcidchec, llInvestment
   LOCAL oGLMaint

   llreturn	 = .T.
   llInvestment = .F.

   TRY

      oGLMaint = m.goapp.oGLMaint

      * Get the catch-all account
      SWSELECT('glopt')
      GO TOP
      lcCatchAll = csuspense

      * Get the detail posting preference
      SWSELECT('progopt')
      GO TOP
      llDetailPosting = lDetailPost
      llJVPosting     = lJVPosting

      SWSELECT('options')
      GO TOP
      lcDeficitAcct = cdefacct

      m.cbatch = tcBatch

      SWSELECT('csrcthdr')
      LOCATE FOR cbatch == m.cbatch
      IF FOUND()

         IF csrcthdr.nCashAmt <= 0
            REPLACE csrcthdr.ccashacct WITH lcDeficitAcct
         ENDIF

         IF m.goapp.oQB.lqbactive = .T.
            IF EMPTY(csrcthdr.ccashacct)
               IF csrcthdr.nCashAmt > 0
                  THIS.cErrorMsg = 'A cash account must be specified.  Please choose the cash account.'
               ELSE
                  THIS.cErrorMsg = 'An owner deficit account must be specified.  Please specify the deficit account.'
               ENDIF
               llreturn = .F.
               EXIT
            ENDIF

            THIS.ClearErrorRecovery()
         ENDIF && m.goapp.oqb.lqbactive = .t.

         IF EMPTY(csrcthdr.dpostdate)
            THIS.cErrorMsg = 'A posting date must be specified.  Please enter a posting date.'
            llreturn = .F.
            EXIT
         ENDIF

         IF EMPTY(csrcthdr.ddate)
            THIS.cErrorMsg = 'A accounting date must be specified.  Please enter an accounting date.'
            llreturn = .F.
            EXIT
         ENDIF

         IF NOT EMPTY(csrcthdr.ctxnid)
            llDelete = .T.
            IF csrcthdr.lnoqbpost
               * Ask if the receipt should be deleted from QB since it obviously was posted to QB earlier and
               * not they're telling it not to post.
               IF MESSAGEBOX('This receipt has previously been saved to QuickBooks. ' + ;
                     'Do you want to delete the original entry from QuickBooks?',36,'Remove From QuickBooks') = 7
                  llDelete = .F.
               ENDIF
            ENDIF
            IF llDelete
               IF m.goapp.oQB.lqbactive = .T.
                  * get a message set request object (version 1.1 xml)
                  lorequest = m.goapp.oQB.oqbrequest

                  * set the on error attribute for the request
                  lorequest.ATTRIBUTES.OnError = 1
                  lorequest.ClearRequests()
                  * add a request to delete the receipt
                  loRcptDel = lorequest.AppendTxnDelRq()
                  IF m.goapp.oQB.qbfcversion > ' 4.0'
                     loRcptDel.TxnDelType.setvalue(15)
                  ELSE
                     loRcptDel.TxnDelType.setvalue(14)
                  ENDIF
                  loRcptDel.txnid.setvalue(csrcthdr.ctxnid)

                  loresponse = m.goapp.oQB.oqbsm.dorequests(lorequest)
                  loDelResp  = loresponse.responselist.getat(0)

                  IF loDelResp.statuscode = 0
                     SELECT csrcthdr
                     REPLACE ctxnid WITH ''
                  ELSE
                     IF loDelResp.statuscode = 3160 AND 'deposit' $ LOWER(loDelResp.statusmessage)
                        MESSAGEBOX('This receipt cannot be changed. It has been deposited in QuickBooks using Make Deposits.',16,'Post Receipt to QB')
                        THIS.ClearErrorRecovery()
                        llreturn = .F.
                        EXIT
                     ENDIF
                     IF 'not be locked' $ loDelResp.statusmessage
                        MESSAGEBOX('This receipt cannot be modified. QuickBooks currently has it locked.',16,'Post Receipt to QB')
                        THIS.ClearErrorRecovery()
                        llreturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
                  THIS.ClearErrorRecovery()
               ELSE
                  MESSAGEBOX('This receipt cannot be modified. The QuickBooks connection is not currently active.',16,'Post Receipt to QB')
                  THIS.ClearErrorRecovery()
                  llreturn = .F.
                  EXIT
               ENDIF
            ENDIF
         ENDIF

         * If the ref file exists, plug 'DM' into the reference for journal entries
         IF FILE('dmref.cfg')
            lcref = 'DM'
         ELSE
            lcref = ''
         ENDIF

         lcidchec = csrcthdr.cidchec

         lcselect = SELECT()
         lcbatch	 = csrcthdr.cbatch
         lcidchec = csrcthdr.cidchec

         IF NOT EMPTY(lcidchec)
            oGLMaint.delcheck(lcbatch, .T.)
         ENDIF

         WAIT WINDOW NOWAIT 'Saving Changes, Please Wait.....'

         *  Create the G/L journal entries for this receipt
         oGLMaint.cSource	= 'CS'
         oGLMaint.cbatch		= lcbatch
         oGLMaint.dGLDate	= csrcthdr.dpostdate
         oGLMaint.cReference	= 'Cash: ' + ALLTRIM(csrcthdr.cinvnum)
         oGLMaint.cDesc		= csrcthdr.cname
         oGLMaint.cacctno	= csrcthdr.ccashacct
         oGLMaint.cid		= csrcthdr.cid
         oGLMaint.namount	= csrcthdr.nCashAmt
         oGLMaint.cBunch		= ''
         oGLMaint.dCheckDate	= csrcthdr.dpostdate
         oGLMaint.dpostdate	= csrcthdr.dpostdate
         oGLMaint.cPayee		= csrcthdr.cname
         oGLMaint.cmemo      = csrcthdr.cinvnum
         oGLMaint.cidchec	= ''
         oGLMaint.centrytype	= 'D'
         oGLMaint.cidtype	= 'D'
         oGLMaint.cyear		= ' '
         oGLMaint.cperiod	= ' '
         oGLMaint.lcleared	= .F.
         oGLMaint.ccheckno	= csrcthdr.ccheckno
         oGLMaint.cunitno	= ''
         oGLMaint.lPrinted	= .T.

         * Only add a register entry if the receipt is positive
         IF csrcthdr.nCashAmt > 0
            oGLMaint.addcheck()
            lcidchec = oGLMaint.GETKEY()
            SWSELECT('csrcthdr')
            REPL cidchec WITH lcidchec
            oGLMaint.cidchec    = lcidchec
         ENDIF


         *  Create the G/L journal entries for this invoice
         IF m.goapp.oQB.lqbactive

            THIS.ClearErrorRecovery()

            * get a message set request object (version 1.1 xml)
            lorequest = m.goapp.oQB.oqbrequest

            * set the on error attribute for the request
            lorequest.ATTRIBUTES.OnError = 1
            lorequest.ClearRequests()

            SWSELECT('expcat')
            LOCATE FOR cCatCode = 'PDEF'
            IF NOT FOUND()
               m.cCatCode = 'PDEF'
               m.ccateg   = 'Balance Fwd'
               m.cdescrip = 'Balance Forward'
               m.cexpclass = '0'
               m.cidexpc  = m.goapp.oregistry.incrementcounter('%Shared.Counters.Expense Category')
               INSERT INTO expcat FROM MEMVAR
            ENDIF

            IF llDetailPosting
               SELECT csrctdet.* FROM csrctdet WITH (BUFFERING=.T.) INTO CURSOR tempdetail WHERE cbatch = lcbatch
            ELSE
               SELECT csrctdet.* FROM csrctdet WITH (BUFFERING=.T.) INTO CURSOR tempdetail1 READWRITE WHERE cbatch = lcbatch
               lcType = ''

               SELECT cDesc, ;
                  SUM(namount) AS namount, ;
                  cdeptno, ;
                  cbatch, ;
                  cWellID, ;
                  ctype, ;
                  SUM(nunits) AS nunits, ;
                  AVG(nprice) AS nprice, ;
                  cnotes, ;
                  cprodyear, ;
                  cprodperiod, ;
                  SUM(ngrossunits) AS ngrossunits, ;
                  SUM(ngrossval) AS ngrossval, ;
                  crefid, ;
                  cPayee, ;
                  SUM(nsaltbbl) AS nsaltbbl, ;
                  cAcctListID, ;
                  nInterest ;
                  FROM tempdetail1 ;
                  INTO CURSOR tempdetail ;
                  WHERE cbatch = lcbatch ;
                  ORDER BY cWellID, ctype ;
                  GROUP BY cWellID, ctype
            ENDIF


            IF csrcthdr.lnoqbpost = .F.
               lorequest.ClearRequests()

               *  Setup the receipt add request
               loRcptAdd = lorequest.appendjournalentryaddrq()

               loRcptAdd.refnumber.setvalue(csrcthdr.ccheckno)
               loRcptAdd.txndate.setvalue(csrcthdr.dpostdate)
               *      loRcptAdd.MEMO.SetValue('** DO NOT CHANGE OR DELETE THIS ENTRY IN QUICKBOOKS **')


               *  Add the deposit to the check register
               IF m.goapp.oQB.qbfcversion > ' 4.0'
                  loDebit = loRcptAdd.ORJournalLineList.APPEND.journaldebitline
               ELSE
                  loDebit = loRcptAdd.journaldebitlinelist.APPEND
               ENDIF

               SWSELECT('revsrc')
               SET ORDER TO cRevKey
               IF SEEK(csrcthdr.cid)
                  IF EMPTY(revsrc.cListID)
                     THIS.cErrorMsg = 'The receipt cannot be saved.  The purchaser file needs to be synchronized with QuickBooks.'
                     lorequest.ClearRequests()
                     llreturn = .F.
                     EXIT
                  ENDIF
                  loDebit.entityref.listid.setvalue(revsrc.cListID)
               ELSE
                  SWSELECT('vendor')
                  SET ORDER TO cVendorID
                  IF SEEK(csrcthdr.cid)
                     loDebit.entityref.listid.setvalue(vendor.cListID)
                  ELSE
                     SWSELECT('investor')
                     SET ORDER TO cOwnerID
                     IF SEEK(csrcthdr.cid)
                        loDebit.entityref.listid.setvalue(investor.cListID)
                     ELSE
                        THIS.cErrorMsg = 'Purchaser/Vendor: ' + csrcthdr.cid + ' not found.'
                        llreturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF

               loDebit.accountref.listid.setvalue(csrcthdr.ccashacct)
               loDebit.amount.setvalue(ROUND(csrcthdr.nCashAmt, 2))

               IF llJVPosting
                  loDebit.MEMO.setvalue(csrcthdr.cinvnum)
               ENDIF

               *  Add detail lines to check
               SELECT tempdetail
               SCAN FOR cbatch == lcbatch
                  SCATTER MEMVAR

                  IF m.namount > 0
                     IF m.goapp.oQB.qbfcversion > ' 4.0'
                        loentry = loRcptAdd.ORJournalLineList.APPEND.journalcreditline
                     ELSE
                        loentry = loRcptAdd.journalcreditlinelist.APPEND
                     ENDIF
                  ELSE
                     IF m.goapp.oQB.qbfcversion > ' 4.0'
                        loentry = loRcptAdd.ORJournalLineList.APPEND.journaldebitline
                     ELSE
                        loentry = loRcptAdd.journaldebitlinelist.APPEND
                     ENDIF
                     m.namount = ABS(m.namount)
                  ENDIF

                  IF NOT EMPTY(tempdetail.cWellID)
                     SELE wells
                     LOCATE FOR cWellID = tempdetail.cWellID
                     IF FOUND()
                        IF EMPTY(ALLT(wells.cListID))
                           THIS.cErrorMsg = 'The receipt cannot be saved.  The wells file needs to be synchronized with QuickBooks.'
                           lorequest.ClearRequests()
                           llreturn = .F.
                           EXIT
                        ENDIF
                        loentry.classref.listid.setvalue(wells.cListID)
                     ENDIF
                  ENDIF

                  SWSELECT('revcat')
                  LOCATE FOR crevtype = m.ctype
                  IF FOUND()
                     IF EMPTY(ALLT(ccracctnow))
                        m.cAcctListID = lcCatchAll
                     ELSE
                        m.cAcctListID = ccracctnow
                     ENDIF
                  ELSE
                     IF NOT EMPTY(m.ctype)
                        SWSELECT('expcat')
                        LOCATE FOR cCatCode = ALLTRIM(m.ctype)
                        IF FOUND()
                           IF EMPTY(ALLT(cownacctlistid))
                              m.cAcctListID = lcCatchAll
                           ELSE
                              m.cAcctListID = cownacctlistid
                           ENDIF
                        ELSE
                           m.cAcctListID = lcCatchAll
                        ENDIF
                     ELSE
                        m.cAcctListID = tempdetail.cAcctListID
                     ENDIF
                  ENDIF

                  loentry.accountref.listid.setvalue(m.cAcctListID)
                  loentry.amount.setvalue(ROUND(m.namount, 2))

                  IF NOT EMPTY(tempdetail.cprodperiod)
                     lcMemoExtra =  "' Period: '+ tempdetail.cprodperiod+'/'+tempdetail.cprodyear"
                     DO CASE
                        CASE INLIST(m.ctype, 'BBL', 'MCF', 'OTH')
                           loentry.MEMO.setvalue(ALLT(STR(tempdetail.nunits, 5, 2)) + ' ' + tempdetail.ctype + ;
                              ' @ ' + ALLT(STR(tempdetail.nprice, 5, 2)) + &lcMemoExtra)
                        CASE m.ctype = 'GTAX1'
                           loentry.MEMO.setvalue('Gas Tax 1' + &lcMemoExtra)
                        CASE m.ctype = 'GTAX2'
                           loentry.MEMO.setvalue('Gas Tax 2' + &lcMemoExtra)
                        CASE m.ctype = 'GTAX3'
                           loentry.MEMO.setvalue('Gas Tax 3' + &lcMemoExtra)
                        CASE m.ctype = 'GTAX4'
                           loentry.MEMO.setvalue('Gas Tax 4' + &lcMemoExtra)
                        CASE m.ctype = 'OTAX1'
                           loentry.MEMO.setvalue('Oil Tax 1' + &lcMemoExtra)
                        CASE m.ctype = 'OTAX2'
                           loentry.MEMO.setvalue('Oil Tax 2' + &lcMemoExtra)
                        CASE m.ctype = 'OTAX3'
                           loentry.MEMO.setvalue('Oil Tax 3' + &lcMemoExtra)
                        CASE m.ctype = 'OTAX4'
                           loentry.MEMO.setvalue('Oil Tax 4' + &lcMemoExtra)
                        CASE m.ctype = 'PTAX1'
                           loentry.MEMO.setvalue('OTH Tax 1' + &lcMemoExtra)
                        CASE m.ctype = 'PTAX2'
                           loentry.MEMO.setvalue('OTH Tax 2' + &lcMemoExtra)
                        CASE m.ctype = 'PTAX3'
                           loentry.MEMO.setvalue('OTH Tax 3' + &lcMemoExtra)
                        CASE m.ctype = 'PTAX4'
                           loentry.MEMO.setvalue('OTH Tax 4' + &lcMemoExtra)
                        CASE m.ctype = 'TRANS'
                           loentry.MEMO.setvalue('Transportation' + &lcMemoExtra)
                        CASE m.ctype = 'MISC1'
                           loentry.MEMO.setvalue('Miscellaneous Revenue 1' + &lcMemoExtra)
                        CASE m.ctype = 'MISC2'
                           loentry.MEMO.setvalue('Miscellaneous Revenue 2' + &lcMemoExtra)
                        CASE m.ctype = 'NET' OR m.ctype = 'PDEF'
                           loentry.MEMO.setvalue('Net JIB' + &lcMemoExtra)
                        OTHERWISE  &&  Expenses - all other types should be covered above
                           SELECT expcat
                           LOCATE FOR ALLTRIM(cCatCode) = ALLTRIM(tempdetail.ctype)
                           IF FOUND()
                              loentry.MEMO.setvalue(ALLT(expcat.ccateg) + &lcMemoExtra)
                           ELSE
                              loentry.MEMO.setvalue(csrcthdr.cinvnum)
                           ENDIF
                     ENDCASE
                  ELSE
                     IF llJVPosting
                        loentry.MEMO.setvalue(csrcthdr.cinvnum)
                     ENDIF
                  ENDIF
               ENDSCAN

               IF llreturn
                  loresponse = m.goapp.oQB.oqbsm.dorequests(lorequest)
                  loaddresp  = loresponse.responselist.getat(0)

                  IF loaddresp.statuscode = 0
                     WAIT WIND NOWAIT 'Receipt successfully added in QuickBooks'
                     loNewCheck = loaddresp.DETAIL
                     m.ctxnid   = loNewCheck.txnid.getvalue()
                     THIS.ClearErrorRecovery()

                     SELE csrcthdr
                     REPL ctxnid WITH m.ctxnid

                  ELSE
                     SWSELECT('csrcthdr')
                     REPL ctxnid WITH ''

                     THIS.FillErrorMsg(loAddResp.StatusMessage)
                     llreturn = .F.
                     EXIT
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   CATCH TO loError
      llreturn = .F.
      DO errorlog WITH 'PostRcptQB', loError.LINENO, 'ImportRev', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.cErrorMsg = loError.MESSAGE
   ENDTRY

   oGLMaint = .NULL.

   RETURN llreturn


   ************************
   PROCEDURE PostBill
   ************************
   LPARAMETERS tcBatch
   LOCAL llreturn, llJVPosting

   llreturn = .T.

   WAIT WINDOW NOWAIT 'Saving Changes, Please Wait.....'
   TRY
      lcbatch = tcBatch

      *  Get the catch-all account
      SWSELECT('glopt')
      lcCatchAll = csuspense
      lcExpClear = cexpclear

      SWSELECT('apopt')
      lcAPListID = cAPAcct

      SWSELECT('afeopt')
      llAFEExp = lAllocExp

      IF m.goapp.lPartnershipMod
         SWSELECT('progopt')
         GO TOP
         llJVPosting = lJVPosting
      ELSE
         llJVPosting = .F.
      ENDIF

      SWSELECT('appurchh')
      LOCATE FOR cbatch = lcbatch
      IF FOUND()

         lcAPListID = appurchh.cAPAcct
         IF EMPTY(lcAPListID)
            lcAPListID = apopt.cAPAcct
         ENDIF

         IF m.goapp.oQB.lqbactive
            THIS.ClearErrorRecovery()

            * get a message set request object (version 1.1 xml)
            lorequest = m.goapp.oQB.oqbrequest

            * set the on error attribute for the request
            lorequest.ATTRIBUTES.OnError = 1
            lorequest.ClearRequests()

            IF NOT EMPTY(appurchh.ctxnid)
               llDelete = .T.

               IF llDelete
                  * add a request to delete the bill
                  lobilldel = lorequest.AppendTxnDelRq()
                  *  Delete previous bill
                  IF m.goapp.oQB.qbfcversion > ' 4.0'
                     lobilldel.TxnDelType.setvalue(1)
                  ELSE
                     lobilldel.TxnDelType.setvalue(8)
                  ENDIF
                  lobilldel.txnid.setvalue(appurchh.ctxnid)

                  loresponse = m.goapp.oQB.oqbsm.dorequests(lorequest)
                  loDelResp  = loresponse.responselist.getat(0)

                  IF loDelResp.statuscode <> 0
                     IF 'not be locked' $ loDelResp.statusmessage
                        THIS.cErrorMsg = 'This invoice cannot be modified. QuickBooks currently has it locked.'
                        m.goapp.oQB.oqbsm.ClearErrorRecovery()
                        llreturn = .F.
                        EXIT
                     ELSE
                        IF 'insufficient permission' $ LOWER(loDelResp.statusmessage)
                           THIS.cErrorMsg = 'Cannot update this bill. The user being used to access QuickBooks '+ ;
                              'does not have a permission level that allows the update. Please make sure ' + ;
                              'the user in QB has permission to delete and update bills.'
                           llreturn = .F.
                           EXIT
                        ENDIF
                     ENDIF
                  ENDIF

                  lorequest.ClearRequests()
                  m.goapp.oQB.oqbsm.ClearErrorRecovery()

                  *  Delete previous credit
                  IF llreturn
                     lobilldel = lorequest.AppendTxnDelRq()

                     IF m.goapp.oQB.qbfcversion > ' 4.0'
                        lobilldel.TxnDelType.setvalue(23)
                     ELSE
                        lobilldel.TxnDelType.setvalue(9)
                     ENDIF
                     lobilldel.txnid.setvalue(appurchh.ctxnid)

                     loresponse = m.goapp.oQB.oqbsm.dorequests(lorequest)
                     loDelResp  = loresponse.responselist.getat(0)
                     IF loDelResp.statuscode <> 0
                        IF 'insufficient permission' $ LOWER(loDelResp.statusmessage)
                           THIS.cErrorMsg = 'Cannot update this bill. The user being used to access QuickBooks '+ ;
                              'does not have a permission level that allows the update. Please make sure ' + ;
                              'the user in QB has permission to delete and update bills.'
                           llreturn = .F.
                           EXIT
                        ENDIF
                     ENDIF
                     m.goapp.oQB.oqbsm.ClearErrorRecovery()
                  ENDIF
               ENDIF
            ENDIF

            lorequest.ClearRequests()

            IF appurchh.ninvtot > 0
               *  Setup the bill add request
               lobilladd = lorequest.appendbilladdrq()

               *  Get the vendor listid
               SWSELECT('vendor')
               LOCATE FOR cVendorID = appurchh.cVendorID
               IF NOT FOUND()
                  THIS.cErrorMsg = 'An invalid vendor has been imported.'
                  lorequest.ClearRequests()
                  llreturn = .F.
                  EXIT
               ENDIF

               lobilladd.vendorref.listid.setvalue(vendor.cListID)

               lobilladd.txndate.setvalue(appurchh.dinvdate)
               lobilladd.duedate.setvalue(appurchh.dduedate)
               lobilladd.refnumber.setvalue(appurchh.cinvnum)
               lobilladd.MEMO.setvalue(appurchh.cReference)

               * Set the default A/P Account
               IF NOT EMPTY(lcAPListID)
                  lobilladd.APAccountRef.listid.setvalue(lcAPListID)
               ENDIF

               * Get terms
               lcidterm = appurchh.cidterm
               SWSELECT('terms')
               LOCATE FOR ALLTRIM(cListID) == ALLTRIM(lcidterm)
               IF FOUND()
                  lcidterm = terms.cListID
                  lobilladd.termsref.listid.setvalue(lcidterm)
               ENDIF

               lobilllist = lobilladd.expenselineaddlist

               *  Add detail lines to bill
               SWSELECT('appurchd')
               SCAN FOR cbatch == lcbatch
                  SCATTER MEMVAR
                  lobillline = lobilllist.APPEND

                  lobillline.amount.setvalue(appurchd.nextension)

                  IF NOT EMPTY(appurchd.cunitno)
                     SWSELECT('wells')
                     LOCATE FOR cWellID = appurchd.cunitno
                     IF FOUND()
                        lobillline.classref.listid.setvalue(wells.cListID)
                     ENDIF
                  ENDIF

                  IF NOT EMPTY(appurchd.cCatCode)
                     SWSELECT('expcat')
                     LOCATE FOR cCatCode = appurchd.cCatCode
                     IF FOUND()
                        lobillline.MEMO.setvalue(ALLT(expcat.ccateg) + ' ' + appurchd.cprodyear + '/' + appurchd.cprodperiod)
                        IF llJVPosting OR (lafetype AND NOT llAFEExp)
                           IF llJVPosting
                              lcExpClear = cownacctlistid
                           ELSE
                              IF EMPTY(m.cAcctListID)
                                 lcExpClear = cownacctlistid
                              ELSE
                                 lcExpClear = m.cAcctListID
                              ENDIF
                           ENDIF
                           IF EMPTY(lcExpClear)
                              lcExpClear = lcCatchAll
                              THIS.cErrorMsg = 'The posting account must be specified for the expense codes being used. Expense code ' + expcat.cCatCode + ;
                                 ' does not have a QB posting account specified. Go to Maintain Expense Codes and choose the ' + ;
                                 'posting accounts the bills should use when posting to QuickBooks.'
                              llreturn = .F.
                           ENDIF
                        ENDIF
                     ENDIF
                  ELSE
                     lcExpClear = appurchd.cAcctListID
                  ENDIF

                  IF EMPTY(lcExpClear)
                     lcExpClear = lcCatchAll
                  ENDIF

                  lobillline.accountref.listid.setvalue(lcExpClear)
               ENDSCAN

               lcxml      = lorequest.toxmlstring()
               THIS.SaveXML(appurchh.cVendorID, lcXML)
               loresponse = m.goapp.oQB.oqbsm.dorequests(lorequest)
               loaddresp  = loresponse.responselist.getat(0)
               IF loaddresp.statuscode = 0
                  lonewbill = loaddresp.DETAIL
                  m.ctxnid  = lonewbill.txnid.getvalue()
                  m.goapp.oQB.oqbsm.ClearErrorRecovery()
                  SWSELECT('appurchh')
                  REPL ctxnid WITH m.ctxnid
                  *                  = TABLEUPDATE(.T.)
               ELSE
                  IF 'object' $ LOWER(loaddresp.statusmessage)
                     lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
                     llResult = m.goapp.oQB.QBListID(lcListID)
                     IF llResult
                        SELECT QBListID
                        IF QBListID.ctype = 'Account'
                           THIS.cErrorMsg = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                              'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                              'and try to save the bill again.'
                           llreturn = .F.
                           EXIT
                        ELSE
                           THIS.cErrorMsg = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                              'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to save the bill again.'
                           llreturn = .F.
                           EXIT
                        ENDIF
                     ELSE
                        THIS.cErrorMsg = 'Unable to Post the Bill to QuickBooks: ' + CHR(13) + ;
                           loaddresp.statusmessage
                        llreturn = .F.
                        EXIT
                     ENDIF
                  ELSE
                     THIS.cErrorMsg = 'Unable to Post the Bill to QuickBooks: ' + CHR(13) + ;
                        loaddresp.statusmessage
                     llreturn = .F.
                     EXIT
                  ENDIF
                  m.goapp.oQB.oqbsm.ClearErrorRecovery()
                  llreturn = .F.
                  EXIT
               ENDIF
            ELSE
               *  Setup the credit add request
               lovendorcreditadd = lorequest.appendvendorcreditaddrq()

               *  Get the vendor listid
               SWSELECT('vendor')
               LOCATE FOR cVendorID = appurchh.cVendorID
               IF FOUND()
                  lovendorcreditadd.vendorref.listid.setvalue(vendor.cListID)
               ELSE
                  THIS.cErrorMsg = 'Vendor: ' + appurchh.cVendorID + ' not found in vendor file.'
                  llreturn = .F.
                  EXIT
               ENDIF

               lovendorcreditadd.txndate.setvalue(appurchh.dinvdate)
               lovendorcreditadd.refnumber.setvalue(appurchh.cinvnum)
               lovendorcreditadd.MEMO.setvalue(appurchh.cReference)
               locreditlist = lovendorcreditadd.expenselineaddlist

               *  Add detail lines to bill
               SWSELECT('appurchd')
               SCAN FOR cbatch == lcbatch
                  SCATTER MEMVAR
                  locreditline = locreditlist.APPEND
                  IF NOT EMPTY(appurchd.cAcctListID)
                     locreditline.accountref.listid.setvalue(appurchd.cAcctListID)
                  ELSE
                     locreditline.accountref.listid.setvalue(lcCatchAll)
                  ENDIF
                  locreditline.amount.setvalue(appurchd.nextension * -1)

                  IF NOT EMPTY(appurchd.cunitno)
                     SWSELECT('wells')
                     LOCATE FOR cWellID = appurchd.cunitno
                     IF FOUND()
                        locreditline.classref.listid.setvalue(wells.cListID)
                     ENDIF
                  ENDIF

                  IF NOT EMPTY(appurchd.cCatCode)
                     SWSELECT('expcat')
                     LOCATE FOR cCatCode = appurchd.cCatCode
                     IF FOUND()
                        locreditline.MEMO.setvalue(ALLT(expcat.ccateg) + ' ' + appurchd.cprodyear + '/' + appurchd.cprodperiod)
                     ENDIF
                  ENDIF
               ENDSCAN

               loresponse = m.goapp.oQB.oqbsm.dorequests(lorequest)
               loaddresp  = loresponse.responselist.getat(0)

               IF loaddresp.statuscode = 0
                  WAIT WIND NOWAIT 'Vendor Credit successfully added in QuickBooks'

                  lonewcredit = loaddresp.DETAIL
                  m.ctxnid    = lonewcredit.txnid.getvalue()
                  m.goapp.oQB.oqbsm.ClearErrorRecovery()
                  SWSELECT('appurchh')
                  REPL ctxnid WITH m.ctxnid
               ELSE
                  IF 'object' $ LOWER(loaddresp.statusmessage)
                     lcListID = SUBSTR(loaddresp.statusmessage, AT('"', loaddresp.statusmessage) + 1, AT('"', loaddresp.statusmessage, 2) - (AT('"', loaddresp.statusmessage) + 1))
                     llResult = m.goapp.oQB.QBListID(lcListID)
                     IF llResult
                        SELECT QBListID
                        IF QBListID.ctype = 'Account'
                           THIS.cErrorMsg = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
                              'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
                              'and try to save the credit again.'
                           llreturn = .F.
                           EXIT
                        ELSE
                           THIS.cErrorMsg = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
                              'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to save the credit again.'
                           llreturn = .F.
                           EXIT
                        ENDIF
                     ELSE
                        THIS.cErrorMsg = 'The files need to be synchronized with QuickBooks.  Could not save this credit.'
                        llreturn = .F.
                        EXIT
                     ENDIF
                  ELSE
                     THIS.cErrorMsg = 'Unable to Post the Bill to QuickBooks: ' + CHR(13) + ;
                        loaddresp.statusmessage
                     llreturn = .F.
                     EXIT
                  ENDIF
                  m.goapp.oQB.oqbsm.ClearErrorRecovery()
                  llreturn = .F.
                  EXIT
               ENDIF
            ENDIF
         ENDIF
      ELSE
         THIS.cErrorMsg = 'The given bill was not found. Unable to post to QuickBooks.'
         llreturn = .F.
         EXIT
      ENDIF
   CATCH TO loError
      DO errorlog WITH 'PostBill', loError.LINENO, 'QBUtils', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.cErrorMsg = 'Unable to save the bill at this time. Check the System Log found under Other Reports for more information.'
      llreturn = .F.
   ENDTRY

   RETURN llreturn
   ***************************************************
   FUNCTION IsCheckCleared(tddate, tnAmount, tcCheckNo, tcListID, tcCashAcct)
   ***************************************************
   LOCAL loReportQuery   AS 'qbfc12.igeneraldetailreportquery'
   LOCAL loReportDet   AS 'qbfc12.ireportret'
   LOCAL loReportDetail   AS 'qbfc12.ireportdata'
   LOCAL loReportData   AS 'qbfc12.iorreportdatalist'
   LOCAL llCleared, lnRows, lnCols

   llCleared = .F.
   STORE 0 TO lnRows, lnCols

   IF m.goapp.oQB.lqbactive = .F. OR NOT BETWEEN(tddate,{1/1/2010},{12/31/2030})
      RETURN .F.
   ENDIF

   TRY

      * Create the cursor to hold the report data coming from QB
      CREATE CURSOR ReportData ( ;
         col1      c(40), ;
         col2      c(40), ;
         col3      c(40), ;
         col4      c(40), ;
         col5      c(40), ;
         col6      c(40), ;
         col7      c(40), ;
         col8      c(40), ;
         col9      c(40), ;
         col10     c(40), ;
         col11     c(40))

      * get a message set request object (version 1.1 xml)
      lorequest = m.goapp.oQB.oqbrequest

      * set the on error attribute for the request
      lorequest.ATTRIBUTES.OnError = 1
      lorequest.ClearRequests()

      THIS.ClearErrorRecovery()

      * Set up the filter criteria for the report query request
      loReportQuery = lorequest.AppendGeneralDetailReportQueryRq()
      loReportQuery.GeneralDetailReportType.setvalue(29)  && Transaction Detail Report
      loReportQuery.ReportEntityFilter.ORReportEntityFilter.ListIDList.ADD(tcListID)
      loReportQuery.ORReportPeriod.ReportPeriod.FromReportDate.setvalue(tddate)
      loReportQuery.ORReportPeriod.ReportPeriod.ToReportDate.setvalue(tddate)
      loReportQuery.ReportAccountFilter.ORReportAccountFilter.ListIDList.ADD(tcCashAcct)

      loresponslist = THIS.oqbsm.dorequests(lorequest)
      loresponse	   = loresponslist.responselist.getat(0)

      * Report request was successful. Build the reportdata cursor
      IF loresponse.statuscode = 0
         loReportDet = loresponse.DETAIL

         lnRows = loReportDet.NumRows.getvalue()
         lnCols = loReportDet.NumColumns.getvalue()

         loReportDetail = loReportDet.ReportData

         IF VARTYPE(loReportDetail) = 'O'
            FOR lni = 0 TO loReportDetail.ORReportDataList.COUNT - 1
               loReportData = loReportDetail.ORReportDataList.getat(lni)
               IF VARTYPE(loReportData.DataRow) = 'O'
                  FOR lnx = 0 TO lnCols - 1
                     TRY
                        loColdata = loReportData.DataRow.ColDataList.getat(lnx)
                        lcCol = 'm.Col' + TRANSFORM(lnx+1)
                        &lcCol	   = loColdata.VALUE.getvalue()
                     CATCH
                     ENDTRY
                  ENDFOR
                  INSERT INTO ReportData FROM MEMVAR
               ENDIF
            ENDFOR
         ENDIF

         SELECT ReportData
         SCAN
            SCATTER MEMVAR
            IF VARTYPE(m.col4) = 'C'
               ldDate = CTOD(SUBSTR(m.col2,6,2)+'/'+SUBSTR(m.col2,9,2)+'/'+SUBSTR(m.col2,1,4))
               IF tddate = ldDate AND VAL(m.col8) = tnAmount AND LOWER(ALLTRIM(tcCheckNo)) $ LOWER(m.col3)
                  IF m.col6 = 'Cleared'
                     llCleared = .T.
                     EXIT
                  ENDIF
               ENDIF
            ENDIF
         ENDSCAN
      ENDIF

      swclose('reportdata')

      THIS.ClearErrorRecovery()
   CATCH TO loError
      DO errorlog WITH 'IsCheckCleared', loError.LINENO, 'QBUtils', loError.ERRORNO, loError.MESSAGE, '', loError
   ENDTRY

   RETURN llCleared

   **********************
   PROCEDURE DeleteTxnID
   **********************
   LPARAMETERS tcQBTxnID, tnTxnType
   LOCAL llreturn
   llreturn = .T.

   TRY
      DO CASE
         CASE tnTxnType = 0
            lcType = 'Credit Card Refund'
         CASE tnTxnType = 1
            lcType = 'Bill'
         CASE tnTxnType = 2
            lcType = 'Bill Payment Check'
         CASE tnTxnType = 3
            lcType = 'Bill Payment Credit Card'
         CASE tnTxnType = 4
            lcType = 'Build Assembly'
         CASE tnTxnType = 5
            lcType = 'Charge'
         CASE tnTxnType = 6
            lcType = 'Check'
         CASE tnTxnType = 7
            lcType = 'Credit Card Charge'
         CASE tnTxnType = 8
            lcType = 'Credit Card Credit'
         CASE tnTxnType = 9
            lcType = 'Credit Memo'
         CASE tnTxnType = 10
            lcType = 'Deposit'
         CASE tnTxnType = 11
            lcType = 'Estimate'
         CASE tnTxnType = 12
            lcType = 'Inventory Adjustment'
         CASE tnTxnType = 13
            lcType = 'Invoice'
         CASE tnTxnType = 14
            lcType = 'Item Receipt'
         CASE tnTxnType = 15
            lcType = 'Journal Entry'
         CASE tnTxnType = 16
            lcType = 'Purchase Order'
         CASE tnTxnType = 17
            lcType = 'Receive Payment'
         CASE tnTxnType = 18
            lcType = 'Sales Order'
         CASE tnTxnType = 19
            lcType = 'Sales Receipt'
         CASE tnTxnType = 20
            lcType = 'Sales Tax Payment'
         CASE tnTxnType = 21
            lcType = 'Time Tracking'
         CASE tnTxnType = 22
            lcType = 'Transfer Inventory'
         CASE tnTxnType = 23
            lcType = 'Vehicle Mileage'
         CASE tnTxnType = 24
            lcType = 'Vendor Credit'
         OTHERWISE
            llreturn = .F.
            DO errorlog WITH 'DelTxnID', 999, 'QBUtils', 9999, 'Invalid Txn Id passed to DeleteTxnID'
            EXIT
      ENDCASE

      THIS.ClearErrorRecovery()

      * get a message set request object (version 1.1 xml)
      lorequest = THIS.oqbrequest

      * set the on error attribute for the request
      lorequest.ATTRIBUTES.OnError = 1
      lorequest.ClearRequests()

      *  Remove the receipt from quickbooks
      IF NOT EMPTY(tcQBTxnID)
         * add a request to delete the receipt
         loRcptDel = lorequest.AppendTxnDelRq()
         loRcptDel.TxnDelType.setvalue(tnTxnType)
         loRcptDel.txnid.setvalue(tcQBTxnID)

         loresponse = m.goapp.oQB.oqbsm.dorequests(lorequest)
         loDelResp  = loresponse.responselist.getat(0)

         IF loDelResp.statuscode # 0
            DO CASE
               CASE loDelResp.statuscode = 3160 AND 'deposit' $ LOWER(loDelResp.statusmessage)
                  MESSAGEBOX('This ' + lcType + ' cannot be changed. It has been deposited in QuickBooks using Make Deposits.',16,'Delete ' + lcType)
                  THIS.oqbsm.ClearErrorRecovery()
                  llreturn = .F.

               CASE 'not be locked' $ loDelResp.statusmessage
                  MESSAGEBOX('This ' + lcType + ' cannot be modified. QuickBooks currently has it locked.',16,'Delete ' + lcType)
                  THIS.oqbsm.ClearErrorRecovery()
                  llreturn = .F.

               CASE 'insufficient permission' $ LOWER(loDelResp.statusmessage)
                  MESSAGEBOX('Cannot update this ' + lcType +'. The user being used to access QuickBooks '+ ;
                     'does not have a permission level that allows the update. Please make sure ' + ;
                     'the user in QB has permission to delete and update ' + lcType + 's.',16,'Update Permission Problem')
                  THIS.ClearErrorRecovery()
                  llreturn = .F.
            ENDCASE
         ELSE
            THIS.ClearErrorRecovery()
         ENDIF
      ENDIF

   CATCH TO loError
      DO errorlog WITH 'DelTxnID', loError.LINENO, 'QBUtils', loError.ERRORNO, loError.MESSAGE
      llreturn = .F.
   ENDTRY

   RETURN llreturn

   ************************
   PROCEDURE ClearErrorInfo
   ************************
   LOCAL llreturn

   llreturn = .T.
   TRY
      IF THIS.oqbsm.IsErrorRecoveryInfo()
         loresp     = THIS.oqbsm.geterrorrecoverystatus()
         lcxml      = loresp.toxmlstring()
         loresponse = loresp.responselist.getat(0)
         lcreq  = THIS.oqbsm.getsavedmsgsetrequest()
         THIS.oqbsm.ClearErrorRecovery()
         DO errorlog WITH 'ClearErrorInfo', 99, 'QBUtils', 999, lcxml, .F.,.F.,.F.,.T.
      ENDIF
   CATCH TO loError
      DO errorlog WITH 'ClearErrorInfo', loError.LINENO, 'QBUtils', loError.ERRORNO, loError.MESSAGE + CHR(13) + lcxml
      llreturn = .F.
   ENDTRY

   RETURN llreturn

   *******************************************
   FUNCTION ClearErrorRecovery(tlNoMessage)
   *******************************************
   LOCAL llError
   llError = .f.

   TRY
      IF m.goapp.oQB.oqbsm.IsErrorRecoveryInfo()
         loresp     = m.goapp.oQB.oqbsm.geterrorrecoverystatus()
         IF VARTYPE(loresp) = 'O'
            lcxml      = loresp.toxmlstring()
            THIS.SaveXML('Error', lcXML)
            IF NOT ISNULL(loresp.responselist)
               loresponse = loresp.responselist.getat(0)
               IF loresponse.statuscode = 0
                  lcreq  = m.goapp.oQB.oqbsm.getsavedmsgsetrequest()
                  m.goapp.oQB.oqbsm.ClearErrorRecovery()
               ELSE
                  IF NOT tlNoMessage
                     THIS.cErrorMsg = 'QB Error Recovery Info: ' + CHR(13) + lcxml
                  ENDIF
                  m.goapp.oQB.oqbsm.ClearErrorRecovery()
                  llreturn = .F.
                  EXIT
               ENDIF
            ELSE
               m.goapp.oQB.oqbsm.ClearErrorRecovery()
            ENDIF
         ELSE
            m.goapp.oQB.oqbsm.ClearErrorRecovery()
         ENDIF
      ENDIF
   CATCH TO loError
      DO errorlog WITH 'ClearErrorRecovery', loError.LINENO, 'QBUtils', loError.ERRORNO, loError.MESSAGE, '', loError
      llError = .T.
   ENDTRY
   TRY 
      IF llError
         m.goapp.oQB.oqbsm.ClearErrorRecovery()
      ENDIF 
   CATCH
   ENDTRY 

   ENDFUNC

   ******************************
   FUNCTION FillErrorMsg(tcStatusMessage)
   ******************************

   IF 'object' $ LOWER(tcstatusmessage)
      lcListID = SUBSTR(tcstatusmessage, AT('"', tcstatusmessage) + 1, AT('"', tcstatusmessage, 2) - (AT('"', tcstatusmessage) + 1))
      llResult = m.goapp.oQB.QBListID(lcListID)
      IF llResult
         SELECT QBListID
         IF QBListID.ctype = 'Account'
            THIS.cErrorMsg = 'The ' + ALLTRIM(QBListID.cdescription) + ' specified in the ' + ;
               'QB Posting Preferences was not found in QuickBooks. Please select a new account ' + ;
               'and try to save the receipt again.'
         ELSE
            THIS.cErrorMsg = 'The ' + ALLTRIM(QBListID.cdescription) + ' was not found in QuickBooks. ' + ;
               'Please synchronize the ' + ALLTRIM(QBListID.ctype) + ' file and try to save the receipt again.'
         ENDIF
      ELSE
         THIS.cErrorMsg = loaddresp.statusmessage
      ENDIF
   ELSE
      THIS.cErrorMsg = loaddresp.statusmessage
   ENDIF
   THIS.ClearErrorRecovery(.T.)
   
   ENDPROC
   
   ********************************
FUNCTION SaveXML(tcID, tcXML)
********************************
LOCAL lcXML, m.XML, m.DateTime, m.cID

TRY
   m.cID = tcID
   *
   *  Create the qbxml file if it doesn't exist
   *
   IF NOT FILE(m.goapp.cDataFilePath + 'qbxml.dbf')
      CREATE TABLE (m.goapp.cDataFilePath + 'qbxml') FREE ;
         (cid       c(10), ;
         DATETIME T, ;
         XML      m)
   ENDIF
   m.xml       = tcXML
   m.datetime = DATETIME()
   swSelect('qbxml')
   INSERT INTO qbxml FROM MEMVAR
   USE IN QBXML
CATCH TO loErr
ENDTRY
ENDDEFINE
*
*-- EndDefine: qbutils
**************************************************









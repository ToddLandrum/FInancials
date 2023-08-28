**************************************************
*-- Class Library:  c:\develop\codeminenew\custom\swjib.vcx
**************************************************


**************************************************
*-- Class:        jibproc (c:\develop\codeminenew\custom\swjib.vcx)
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   08/19/08 11:28:12 AM
*

DEFINE CLASS jibproc AS CUSTOM


   HEIGHT      = 40
   WIDTH         = 159
   cbegownerid   = .F.
   cbegwellid   = .F.
   cendownerid   = .F.
   cendwellid   = .F.
   cgroup      = .F.
   cperiod      = .F.
   cprocess      = .F.
   cyear         = .F.
   dacctdate   = .F.
   lquiet      = .F.
   omessage      = .NULL.
   oregistry   = .NULL.
   oqb         = .F.
   NAME         = "jibproc"

   *-- This closing process's batch number.
   cdmbatch     = .F.
   lerrorflag = .F.

   *-- The expense clearing account.
   cexpclear = .F.

   *-- GLMaint object
   ogl       = .F.
   nrunno    = .F.
   lrelqtr    = .F.
   crunyear    = .F.
   lclose    = .F.
   cacctyear = .F.
   cacctprd    = .F.

   *-- .T. = QuickBooks Version
   lqbversion = .F.

   *-- QuickBooks Request Object
   orequest = .F.

   *-- Sysctl primary key
   csysctlkey = .F.

   *-- Date to use in processing expenses.
   dexpdate    = .F.
   lnoreport = .F.
   dpostdate = .F.

   *-- .T. = only post companies share with posting date.
   companypost   = .F.
   lhousegas   = .F.
   lCanceled   = .F.
   oProgress   = .NULL.
   oWellInv    = .NULL.

   **********************************************************
   PROCEDURE addhist
   **********************************************************
   LOCAL lnMax, lnCount, lnX, llReturn, loError

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      STORE 0 TO lnMax, lnCount

      SELECT jibowner
      COUNT FOR NOT DELETED() AND ctypeinv # 'S' AND cWellID # 'ALL ' TO lnX
      lnMax = lnMax + lnX
      SELECT jibwell
      COUNT FOR NOT DELETED() TO lnX
      lnMax = lnMax + lnX

      IF NOT THIS.lquiet
         THIS.oProgress = THIS.omessage.ProgressBar('Adding the current period data to the history files...')
         THIS.oProgress.SetProgressRange(0, lnMax)
      ENDIF
      SELECT jibowner
      SET ORDER TO 0
      SCAN FOR ctypeinv # 'S' AND cWellID # 'ALL '
         lnCount = lnCount + 1
         IF NOT THIS.lquiet
            THIS.oProgress.UpdateProgress(lnCount)
         ENDIF
         SCATTER MEMVAR
         m.ciddisb = THIS.oregistry.IncrementCounter('%Shared.Counters.Owner History')
         SET DELETED OFF
         SWSELECT('disbhist', .T.)
         SET ORDER TO ciddisb
         DO WHILE SEEK(m.ciddisb)
            m.ciddisb = THIS.oregistry.IncrementCounter('%Shared.Counters.Owner History')
         ENDDO
         INSERT INTO disbhist FROM MEMVAR
         INSERT INTO ownpcts  FROM MEMVAR
         SET DELETED ON
      ENDSCAN
      SELECT jibwell
      SET ORDER TO 0
      SCAN
         lnCount = lnCount + 1
         IF NOT THIS.lquiet
            THIS.oProgress.UpdateProgress(lnCount)
         ENDIF
         SCATTER MEMVAR
         m.cidwhst = THIS.oregistry.IncrementCounter('%Shared.Counters.Well History')
         SET DELETED OFF
         SWSELECT('wellhist', .T.)
         SET ORDER TO cidwhst
         DO WHILE SEEK(m.cidwhst)
            m.cidwhst = THIS.oregistry.IncrementCounter('%Shared.Counters.Well History')
         ENDDO
         INSERT INTO wellhist FROM MEMVAR
         SET DELETED ON
      ENDSCAN
      IF NOT THIS.lquiet
         THIS.oProgress.CLOSEProgress()
         THIS.oProgress = .NULL.
      ENDIF

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'AddHist', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('AddHist', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn

   ENDPROC

   **********************************************************
   PROCEDURE checkhist
   **********************************************************
   LOCAL llHist, lcDeleted, lnSelect, llReturn, loError

   llReturn = .T.

   TRY
      lnSelect = SELECT()

      lcDeleted = SET('DELETED')
      SET DELETED ON

      llHist = .F.

      SWSELECT('sysctl', .T.)
      LOCATE FOR nrunno == THIS.nrunno AND cyear == THIS.cyear AND cTypeClose = 'J'
      IF FOUND()
         llHist        = .T.
         THIS.cdmbatch = cdmbatch
      ENDIF

      SET DELETED &lcDeleted

      SELECT (lnSelect)

      llReturn = llHist
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'CheckHist', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('CheckHist', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE GetHist
   **********************************************************
   LOCAL lnCount, lnMax, lnX, llReturn, loError

   llReturn = .T.

   TRY
      STORE 0 TO lnCount, lnMax, lnX

      *   Create Temp Investor Disbursement File
      SWSELECT('disbhist', .T.)
      lnX = AFIELDS(latempx)
      SWSELECT('ownpcts', .T.)
      lny = AFIELDS(latempy)
      DIMENSION laTemp[lnx + lny - 1, 18]
      FOR x = 1 TO lnX
         FOR Y = 1 TO 18
            laTemp[x, y] = latempx[x, y]
         ENDFOR
      ENDFOR
      FOR x = 1 TO lny - 1
         FOR Y = 1 TO 18
            laTemp[x + lnx, y] = latempy[x + 1, y]
         ENDFOR
      ENDFOR
      FOR x = 1 TO lnX + lny - 1
         laTemp[X, 7]  = ''
         laTemp[X, 8]  = ''
         laTemp[X, 9]  = ''
         laTemp[X, 10] = ''
         laTemp[X, 11] = ''
         laTemp[X, 12] = ''
         laTemp[X, 13] = ''
         laTemp[X, 14] = ''
         laTemp[X, 15] = ''
         laTemp[X, 18] = ''
      ENDFOR
      CREATE CURSOR invtmp FROM ARRAY laTemp
      CREATE CURSOR jibowner FROM ARRAY laTemp

      IF NOT THIS.lquiet
         IF THIS.cgroup = '**'
            SWSELECT('disbhist', .T.)
            SELECT cownerid FROM disbhist ;
               WHERE nrunno = THIS.nrunno ;
               AND crunyear  = THIS.cyear     ;
               AND cRecType  = 'J' ;
               AND cownerid IN (SELECT cID FROM SELECTED) INTO CURSOR temp
            lnMax = lnMax + _TALLY
            SELECT cWellID FROM wellhist ;
               WHERE nrunno = THIS.nrunno ;
               AND crunyear  = THIS.cyear  ;
               AND cRecType  = 'J' ;
               AND BETWEEN(cWellID, THIS.cbegwellid, THIS.cendwellid) INTO CURSOR temp
            lnMax = lnMax + _TALLY
         ELSE
            SELECT cWellID FROM disbhist ;
               WHERE nrunno = THIS.nrunno ;
               AND crunyear  = THIS.cyear     ;
               AND cRecType  = 'J' ;
               AND cownerid IN (SELECT cID FROM SELECTED) ;
               AND cgroup = THIS.cgroup INTO CURSOR temp
            lnMax = lnMax + _TALLY
            SELECT cWellID FROM wellhist ;
               WHERE nrunno = THIS.nrunno ;
               AND crunyear  = THIS.cyear  ;
               AND cRecType  = 'J' ;
               AND BETWEEN(cWellID, THIS.cbegwellid, THIS.cendwellid) ;
               AND cgroup = THIS.cgroup INTO CURSOR temp
            lnMax = lnMax + _TALLY
         ENDIF
         IF NOT THIS.lquiet
            THIS.oProgress = THIS.omessage.ProgressBar('Retrieving history records...')
            THIS.oProgress.SetProgressRange(0, lnMax)
         ENDIF
      ENDIF

      SWSELECT('disbhist', .T.)
      IF THIS.cgroup = '**'          && All Groups
         SELECT  disbhist.*, ownpcts.* ;
            FROM disbhist, ownpcts ;
            WHERE disbhist.nrunno = THIS.nrunno ;
            AND disbhist.crunyear = THIS.cyear     ;
            AND disbhist.cRecType = 'J' ;
            AND disbhist.cownerid IN (SELECT  cownerid ;
            FROM jibowntmp) ;
            AND disbhist.ciddisb == ownpcts.ciddisb ;
            INTO CURSOR temp
         IF _TALLY > 0
            SELECT temp
            SCAN
               SCATTER MEMVAR
               IF NOT THIS.lquiet
                  THIS.oProgress.UpdateProgress(lnCount)
                  lnCount = lnCount + 1
               ENDIF
               INSERT INTO jibowner FROM MEMVAR
            ENDSCAN
         ENDIF
      ELSE
         SELECT  disbhist.*, ownpcts.* ;
            FROM disbhist, ownpcts ;
            WHERE disbhist.nrunno = THIS.nrunno ;
            AND disbhist.crunyear = THIS.cyear     ;
            AND disbhist.cRecType = 'J' ;
            AND disbhist.cownerid IN (SELECT  cownerid ;
            FROM jibowntmp) ;
            AND disbhist.cgroup = THIS.cgroup ;
            AND disbhist.ciddisb == ownpcts.ciddisb ;
            INTO CURSOR temp
         IF _TALLY > 0
            SELECT temp
            SCAN
               SCATTER MEMVAR
               IF NOT THIS.lquiet
                  THIS.oProgress.UpdateProgress(lnCount)
                  lnCount = lnCount + 1
               ENDIF
               INSERT INTO jibowner FROM MEMVAR
            ENDSCAN
         ENDIF
      ENDIF

      SELECT jibowner
      INDEX ON cWellID + cownerid TAG wellinv
      INDEX ON cownerid + cWellID TAG invwell
      INDEX ON cownerid + cWellID + ctypeinv + cprogcode TAG invtype
      INDEX ON cWellID TAG cWellID
      INDEX ON cownerid + cprogcode + cWellID TAG invprog
      INDEX ON DELETED() TAG _deleted

      *   Create Temp Well Production History File
      SWSELECT('wellhist', .T.)
      Make_Copy('wellhist', 'jibwell')

      SWSELECT('wellhist', .T.)
      IF THIS.cgroup = '**'      && All Groups
         SELECT  * ;
            FROM wellhist ;
            WHERE nrunno = THIS.nrunno ;
            AND crunyear = THIS.cyear  ;
            AND cRecType = 'J' ;
            AND wellhist.cWellID IN (SELECT  cWellID ;
            FROM jibwelltmp) ;
            INTO CURSOR temp
         IF _TALLY > 0
            SELECT temp
            SCAN
               SCATTER MEMVAR
               IF NOT THIS.lquiet
                  THIS.oProgress.UpdateProgress(lnCount)
                  lnCount = lnCount + 1
               ENDIF
               INSERT INTO jibwell FROM MEMVAR
            ENDSCAN
         ENDIF
      ELSE
         SELECT  * ;
            FROM wellhist ;
            WHERE nrunno = THIS.nrunno ;
            AND crunyear = THIS.cyear  ;
            AND cRecType = 'J' ;
            AND wellhist.cWellID IN (SELECT  cWellID ;
            FROM jibwelltmp) ;
            AND cgroup = THIS.cgroup ;
            INTO CURSOR temp
         IF _TALLY > 0
            SELECT temp
            SCAN
               SCATTER MEMVAR
               IF NOT THIS.lquiet
                  THIS.oProgress.UpdateProgress(lnCount)
                  lnCount = lnCount + 1
               ENDIF
               INSERT INTO jibwell FROM MEMVAR
            ENDSCAN
         ENDIF
      ENDIF
      SELECT jibwell
      INDEX ON cWellID TAG cWellID

      IF NOT THIS.lquiet
         THIS.oProgress.CLOSEProgress()
         THIS.oProgress = .NULL.
      ENDIF

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'GetHist', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('GetHist', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE MAIN
   **********************************************************
   LPARA tlClose, tlRpt
   LOCAL llNetDef, llReturn, loError

   llReturn = .T.

   SET ESCAPE ON
   ON ESCAPE m.goApp.lCanceled = .T.

   TRY
      IF m.goApp.lqbversion
         IF m.goApp.capplevel # 'Unlimited'
            lnwells = 0
            IF NOT USED('wells')
               USE wells IN 0
            ENDIF
            SWSELECT('wells')
            COUNT FOR NOT DELETED() AND cwellstat # 'U' TO lnwells
            IF m.goApp.capplevel = 'Starter' AND lnwells > 10
               MESSAGEBOX('More than 10 wells were found in the well master file. ' + CHR(10) + ;
                  'This is a starter system. 10 wells is the maximum. ' + CHR(10) + ;
                  'You will not be able to process revenue or JIBs until you upgrade to the next level.', 0, 'Compliance Problem')
               llReturn = .F.
               EXIT
            ENDIF
            IF m.goApp.capplevel = 'Basic' AND lnwells > 20
               MESSAGEBOX('More than 20 wells were found in the well master file. ' + CHR(10) + ;
                  'This is a basic system. 20 wells is the maximum. ' + CHR(10) + ;
                  'You will not be able to process revenue or JIBs until you upgrade to the next level.', 0, 'Compliance Problem')
               llReturn = .F.
               EXIT
            ENDIF
         ENDIF
      ENDIF

      IF m.goApp.lCanceled
         llReturn = .F.
         IF NOT m.goApp.CancelMsg()
            THIS.lCanceled = .T.
            EXIT
         ENDIF
      ENDIF

      * Create the business object for wellinv
      THIS.oWellInv = CREATEOBJECT('swbizobj_wellinv')

      IF tlClose
         THIS.cdmbatch = THIS.oregistry.IncrementCounter('%Shared.Counters.Batch')
      ELSE
         THIS.cdmbatch = ''
      ENDIF

      THIS.lclose = tlClose

      m.cdmbatch = THIS.cdmbatch

      *  Check for Any Activity During Period Range
      lnCount = 0

      SELECT jibwelltmp
      SCAN
         m.cWellID = cWellID
         SWSELECT('wells')
         SET ORDER TO cWellID
         IF SEEK(m.cWellID)
            SWSELECT('expense', .T.)
            COUNT ALL FOR ((nRunNoJIB = THIS.nrunno AND cRunYearJIB = THIS.crunyear) OR nRunNoJIB = 0 AND cWellID == m.cWellID AND dexpdate <= THIS.dexpdate) AND cyear # 'FIXD' TO lnX
            lnCount = lnCount + lnX
            IF lnCount > 0
               llReturn = .T.
            ENDIF
         ENDIF
      ENDSCAN

      IF lnCount = 0
         IF NOT THIS.lquiet
            THIS.omessage.DISPLAY('%msgNoActivity')
         ENDIF
         llReturn = .F.
         EXIT
      ELSE
         ****************************************************************************
         *  Check to see if the period has already been posted
         *  If the period has been posted, retrieve the information from the history
         *  files.
         ****************************************************************************

         IF THIS.checkhist()
            SWSELECT('groups')
            SET ORDER TO cgroup
            IF SEEK(THIS.cgroup)
               llNetDef = lNetDef
            ELSE
               llNetDef = .T.
            ENDIF
            THIS.GetHist()
            THIS.getinvoice()
         ELSE
            SWSELECT('groups')
            SET ORDER TO cgroup
            IF SEEK(THIS.cgroup)
               llNetDef = lNetDef
            ELSE
               llNetDef = .T.
            ENDIF

            *
            *  Create the work cursors (jibwell) and (jibowner)
            *
            llReturn = THIS.SETUP()
            IF NOT llReturn
               EXIT
            ENDIF

            *
            *  Process the wells
            *
            llReturn = THIS.wellproc()
            IF NOT llReturn
               EXIT
            ENDIF

            *
            *  Process the owners
            *
            llReturn = THIS.ownerproc()
            IF NOT llReturn
               EXIT
            ENDIF

            *
            *  Calculate the rounding
            *
            llReturn = THIS.calcround(tlClose OR tlRpt)
            IF NOT llReturn
               EXIT
            ENDIF

            *
            *  Create the JIB invoices
            *
            llReturn = THIS.jibinv(tlClose)
            IF NOT llReturn
               EXIT
            ENDIF


            *
            *  If the JIB period is being closed, add to the history files
            *
            IF tlClose
               *
               *  Create the Vendor Checks
               *
               llReturn = THIS.vendorchks()
               IF NOT llReturn
                  EXIT
               ENDIF
               llReturn = THIS.closeproc()
               IF llReturn AND NOT THIS.lerrorflag
                  THIS.calcsummary()
                  THIS.omessage.DISPLAY('The JIB run processed successfully.')
               ELSE
                  MESSAGEBOX('The JIB processing did not complete successfully. All files have been reset.' + CHR(13) + ;
                     'Check the system log for more information.', 16, 'JIB Processing Failed')
               ENDIF
            ENDIF

         ENDIF
      ENDIF
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'Main', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('Main', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   ON ESCAPE

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE OwnerProc
   **********************************************************
   LOCAL lnflatoilamt, lnflatgasamt, lcsaveprd1, lcsaveprd2, lnrunno
   LOCAL llReturn, loError

   llReturn = .T.

   TRY
      llround = .F.

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      IF m.goApp.lCanceled
         lnReturn = 0
         IF NOT m.goApp.CancelMsg()
            THIS.lCanceled = .T.
            EXIT
         ENDIF
      ENDIF

      lnrunno    = THIS.nrunno

      SWSELECT('options')
      GO TOP
      llexpsum  = lexpsum

      ****************************************************************************
      *  Calculate share of expenses by owner
      ****************************************************************************
      IF NOT THIS.lquiet
         THIS.oProgress = THIS.omessage.ProgressBar('Allocating JIB expenses to the owners...')
      ENDIF

      lnCount = 0
      SWSELECT('wells')
      SET ORDER TO cWellID
      *
      *  Reset the one-man-item flag in the expense files.
      *
      SWSELECT('expense', .T.)
      REPLACE loneman WITH .F. FOR (nRunNoJIB = lnrunno OR nRunNoJIB = 0)

      *
      *  Prepare the work expense cursor with just the expenses we need to process this run
      *
      Make_Copy('expense', 'workexp')
      Make_Copy('expense', 'workexp1')
      SELE expense
      SCAN FOR (nRunNoJIB = 0 OR (nRunNoJIB = THIS.nrunno AND cRunYearJIB = THIS.crunyear)) AND dexpdate <= THIS.dexpdate AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
         SCATTER MEMVAR
         INSERT INTO workexp1 FROM MEMVAR
      ENDSCAN

      IF llexpsum
         SELECT  cWellID, ccateg, cyear, cperiod, crefid, dexpdate, SUM(namount) AS namount, ;
            cpayee, cmemo, cvendorid, cpaidbyck, cexpclass, nsaltwater, cprdpaid, ;
            lfixed, laptran, cbatch, cownerid, loneman, cCatCode, cdeck ;
            FROM workexp1 ;
            INTO CURSOR exptemp1 ;
            ORDER BY cWellID, cdeck, cCatCode, cyear, cperiod, cownerid, cexpclass ;
            GROUP BY cWellID, cdeck, cCatCode, cyear, cperiod, cownerid, cexpclass
         SELE workexp
         APPEND FROM DBF('exptemp1')
      ELSE
         SELE workexp
         APPEND FROM DBF('workexp1')
      ENDIF

      SELE workexp
      INDEX ON cWellID TAG cWellID
      INDEX ON cyear + cperiod TAG yearprd

      *
      *  Start the scan through the jibowner file to process each interest.
      *
      SELECT jibowner
      SET ORDER TO ownperiod
      COUNT FOR NOT DELETED() TO lnMax
      IF NOT THIS.lquiet
         THIS.oProgress.SetProgressRange(0, lnMax)
      ENDIF

      SELE jibowner
      SCAN
         SCATTER MEMVAR
         SWSELECT('investor')
         SET ORDER TO cownerid
         IF SEEK(m.cownerid)
            m.lexempt = lexempt
         ELSE
            m.lexempt = .F.
         ENDIF

         IF m.goApp.lCanceled
            llReturn = .F.
            IF NOT m.goApp.CancelMsg()
               THIS.lCanceled = .T.
               EXIT
            ENDIF
         ENDIF

         STORE 0 TO lnWellTot, lnTotInc, lnTotExp, m.ninvamt, jinvcnt, lnoilinc, ;
            lngasinc, lntrpinc, lnsevtaxes, jnflatcount, lnmi1inc, lnmi2inc, ;
            lncompress, lngather, lngastax, lnoiltax, lnoiltax1, lngastax1, ;
            lnoilexp, lngasexp

         IF NOT THIS.lquiet
            THIS.oProgress.UpdateProgress(lnCount)
            lnCount = lnCount + 1
         ENDIF

         SELECT jibwell
         SET ORDER TO wellprd
         IF SEEK (m.cWellID + m.hyear + m.hperiod)
            m.nprodwell    = ngasinc + noilinc + ntrpinc
            m.ntotbbltx2 = ntotbbltx2
            m.ntotmcftx2 = ntotmcftx2
            m.ntotbbltx1 = ntotbbltx1
            m.ntotmcftx1 = ntotmcftx1
            m.ntotbbltx3 = ntotbbltx3
            m.ntotmcftx3 = ntotmcftx3
            m.ntotbbltx4 = ntotbbltx4
            m.ntotmcftx4 = ntotmcftx4
            m.ntotothtx1 = ntotothtx1
            m.ntotothtx2 = ntotothtx2
            m.ntotothtx3 = ntotothtx3
            m.ntotothtx4 = ntotothtx4
            m.ntotbbltxr = ntotbbltxr
            m.ntotmcftxr = ntotmcftxr
            m.ntotbbltxw = ntotbbltxw
            m.ntotmcftxw = ntotmcftxw
            lngasrevenue = ngrossgas
            lnoilrevenue = ngrossoil
            m.nroyalty    = nroyint
            m.nprocess    = nprocess
            jncompress    = ncompress
            jngather       = ngather
            m.nexpcl1    = nexpcl1
            m.nexpcl2    = nexpcl2
            m.nexpcl3    = nexpcl3
            m.nexpcl4    = nexpcl4
            m.nexpcl5    = nexpcl5
            m.nexpcla    = nexpcla
            m.nexpclb    = nexpclb
            m.nplugamt    = nplugamt
         ELSE
            LOOP
         ENDIF

         **********************************************************
         *  Process expenses
         **********************************************************
         STORE 0 TO m.ntotale1, m.ntotale2, m.ntotale3, m.ntotale4, m.ntotale5, m.nplugexp
         jccownerid = m.cownerid
         STORE .F. TO llRnd0, llRnd1, llRnd2, llRnd3, llRnd4, llRnd5, llRndA, llRndB
         SELECT workexp
         SET ORDER TO 0
         SCAN FOR cWellID = m.cWellID AND cyear + cperiod = m.hyear + m.hperiod
            SCATTER MEMVAR

            m.category = m.ccateg

            * Check for net owners and only apply JIB Only expenses to them
            IF NOT jibowner.lJIB
               SWSELECT('expcat')
               SET ORDER TO cCatCode
               IF SEEK(m.cCatCode)
                  IF NOT ljibonly
                     LOOP
                  ENDIF
               ENDIF
            ENDIF

            SELE workexp
            *  Store original interests so we can change for one-man-items.  pws 3/11/97
            jnworkint = m.nworkint
            jnclass1    = m.nintclass1
            jnclass2    = m.nintclass2
            jnclass3    = m.nintclass3
            jnclass4    = m.nintclass4
            jnclass5    = m.nintclass5
            jnclassa    = m.nacpint
            jnclassb    = m.nbcpint
            jnPlugPct = m.nPlugpct

            * Check to see if this owner type is not a working interest owner
            * if the owner has a working interest in the well. One man items
            * should always be allocated to the working interest if there is one.
            llSkipOneMan = .F.

            IF NOT EMPTY(m.cownerid) AND m.ctypeinv # 'W'
               SELECT  cownerid, ctypeinv ;
                  FROM jibowner ;
                  WHERE cownerid == jccownerid ;
                  AND cWellID == m.cWellID ;
                  AND ctypeinv = 'W' ;
                  INTO CURSOR temp ;
                  ORDER BY cownerid, ctypeinv ;
                  GROUP BY cownerid, ctypeinv
               IF _TALLY > 0
                  llSkipOneMan = .T.
               ENDIF
            ENDIF

            DO CASE
               CASE m.cownerid = jccownerid AND NOT m.loneman AND NOT llSkipOneMan
                  SELECT workexp
                  REPLACE loneman WITH .T.
                  DO CASE
                     CASE m.cexpclass = '0'
                        m.nworkint = 100
                     CASE m.cexpclass = '1'
                        m.nintclass1 = 100
                     CASE m.cexpclass = '2'
                        m.nintclass2 = 100
                     CASE m.cexpclass = '3'
                        m.nintclass3 = 100
                     CASE m.cexpclass = '4'
                        m.nintclass4 = 100
                     CASE m.cexpclass = '5'
                        m.nintclass5 = 100
                     CASE m.cexpclass = 'A'
                        m.nacpint = 100
                     CASE m.cexpclass = 'B'
                        m.nbcpint = 100
                     CASE m.cexpclass = 'P'
                        m.nPlugpct = 100
                  ENDCASE
               CASE m.cownerid = ' '
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # jccownerid
                  LOOP
               CASE m.cownerid = jccownerid AND loneman
                  LOOP
            ENDCASE

            m.cownerid = jccownerid
            DO CASE
               CASE m.cexpclass = '0'
                  m.ninvamt = swround(m.namount * (m.nworkint / 100), 2)
                  lnTotExp    = lnTotExp + m.ninvamt
                  lnWellTot = lnWellTot - m.ninvamt
                  STORE 0 TO m.ninvamt

               CASE m.cexpclass = '1' && AND m.nexpcl1 <> 0  &&  Changed to not check m.nexpcl1-5, since it wasn't getting filled in in JIBWELL - BH 10/11/05
                  m.ninvamt   = swround((m.namount * (m.nintclass1 / 100)), 2)
                  IF llround AND NOT llRnd1
                     m.ninvamt = m.ninvamt + roundtemp.ntotale1
                     llRnd1    = .T.
                  ENDIF
                  m.ntotale1 = m.ntotale1 + m.ninvamt
                  lnWellTot  = lnWellTot - m.ninvamt
                  STORE 0 TO m.ninvamt

               CASE m.cexpclass = '2' && AND m.nexpcl2 <> 0
                  m.ninvamt   = swround((m.namount * (m.nintclass2 / 100)), 2)
                  IF llround AND NOT llRnd2
                     m.ninvamt = m.ninvamt + roundtemp.ntotale2
                     llRnd2    = .T.
                  ENDIF
                  m.ntotale2 = m.ntotale2 + m.ninvamt
                  lnWellTot  = lnWellTot - m.ninvamt
                  STORE 0 TO m.ninvamt

               CASE m.cexpclass = '3' && AND m.nexpcl3 <> 0
                  m.ninvamt   = swround((m.namount * (m.nintclass3 / 100)), 2)
                  IF llround AND NOT llRnd3
                     m.ninvamt = m.ninvamt + roundtemp.ntotale3
                     llRnd3    = .T.
                  ENDIF
                  m.ntotale3 = m.ntotale3 + m.ninvamt
                  lnWellTot  = lnWellTot - m.ninvamt
                  STORE 0 TO m.ninvamt

               CASE m.cexpclass = '4' && AND m.nexpcl4 <> 0
                  m.ninvamt   = swround((m.namount * (m.nintclass4 / 100)), 2)
                  IF llround AND NOT llRnd4
                     m.ninvamt = m.ninvamt + roundtemp.ntotale4
                     llRnd4    = .T.
                  ENDIF
                  m.ntotale4 = m.ntotale4 + m.ninvamt
                  lnWellTot  = lnWellTot - m.ninvamt
                  STORE 0 TO m.ninvamt

               CASE m.cexpclass = '5' && AND m.nexpcl5 <> 0
                  m.ninvamt   = swround((m.namount * (m.nintclass5 / 100)), 2)
                  IF llround AND NOT llRnd5
                     m.ninvamt = m.ninvamt + roundtemp.ntotale5
                     llRnd5    = .T.
                  ENDIF
                  m.ntotale5 = m.ntotale5 + m.ninvamt
                  lnWellTot  = lnWellTot - m.ninvamt
                  STORE 0 TO m.ninvamt

               CASE m.cexpclass = 'B' &&  AND m.nexpclb <> 0
                  m.ninvamt   = swround((m.namount * (m.nbcpint / 100)), 2)
                  IF llround AND NOT llRndB
                     m.ninvamt = m.ninvamt + roundtemp.ntotaleB
                     llRndB    = .T.
                  ENDIF
                  m.ntotaleB = m.ntotaleB + m.ninvamt
                  lnWellTot  = lnWellTot - m.ninvamt
                  STORE 0 TO m.ninvamt

               CASE m.cexpclass = 'A' && AND m.nexpcla <> 0
                  m.ninvamt   = swround((m.namount * (m.nacpint / 100)), 2)
                  IF llround AND NOT llRndA
                     m.ninvamt = m.ninvamt + roundtemp.ntotaleA
                     llRndA    = .T.
                  ENDIF
                  m.ntotaleA = m.ntotaleA + m.ninvamt
                  lnWellTot  = lnWellTot - m.ninvamt
                  STORE 0 TO m.ninvamt

               CASE m.cexpclass = 'P'
                  IF m.goApp.lPluggingModule
                     m.ninvamt   = swround((m.namount * (m.nPlugpct / 100)), 2)
                     IF llround AND NOT llRndP
                        m.ninvamt = m.ninvamt + roundtemp.nplugexp
                        llRndP    = .T.
                     ENDIF
                     m.nplugexp = m.nplugexp + m.ninvamt
                     lnWellTot  = lnWellTot - m.ninvamt
                     STORE 0 TO m.ninvamt
                  ENDIF
            ENDCASE
            *  Restore original interests in case one-man-item logic changed them. pws 3/11/97
            m.nworkint    =   jnworkint
            m.nintclass5 = jnclass5
            m.nintclass4 = jnclass4
            m.nintclass3 = jnclass3
            m.nintclass2 = jnclass2
            m.nintclass1 = jnclass1
            m.nbcpint    = jnclassb
            m.nacpint    = jnclassa
         ENDSCAN  && Workexp

         WAIT CLEAR
         *************************************************************
         *  Process well net total
         *************************************************************
         SELECT jibowner
         REPLACE hperiod   WITH m.hperiod, ;
            hyear      WITH m.hyear, ;
            hdate      WITH THIS.dacctdate, ;
            nrunno     WITH lnrunno, ;
            noilrev    WITH 0, ;
            ngasrev    WITH 0, ;
            ntrprev    WITH 0, ;
            nmiscrev1  WITH 0, ;
            nmiscrev2  WITH 0, ;
            nincome    WITH 0, ;
            nexpense   WITH lnTotExp, ;
            ntotale1   WITH m.ntotale1, ;
            ntotale2   WITH m.ntotale2, ;
            ntotale3   WITH m.ntotale3, ;
            ntotale4   WITH m.ntotale4, ;
            ntotale5   WITH m.ntotale5, ;
            ntotaleA   WITH m.ntotaleA, ;
            ntotaleB   WITH m.ntotaleB, ;
            nplugexp   WITH m.nplugexp, ;
            nnetcheck  WITH lnWellTot, ;
            nsevtaxes  WITH 0, ;
            noiltax1    WITH 0, ;
            ngastax1    WITH 0, ;
            noiltax2   WITH 0, ;
            ngastax2   WITH 0, ;
            ngather    WITH 0, ;
            ncompress  WITH 0

         STORE 0 TO m.ntotale1, m.ntotale2, m.ntotale3, m.ntotale4, m.ntotale5, lnoiltax, lngastax, ;
            lnmi1inc, lnmi2inc, lnoilinc, lngasinc, lntrpinc, lnTotInc, lnTotExp, ;
            lnoilexp, lngasexp, m.ntotaleA, m.ntotaleB, m.nplugexp
      ENDSCAN


      IF VARTYPE(THIS.oProgress) = 'O'
         THIS.oProgress.CLOSEProgress()
         THIS.oProgress = .NULL.
      ENDIF

      *
      *  Get rid of zero records
      *
      SELECT jibowner
      SCAN FOR hperiod = '13'
         DELE NEXT 1
      ENDSCAN

      INDEX ON cWellID + cownerid TAG wellinv
      INDEX ON cownerid + cWellID TAG invwell
      INDEX ON cWellID TAG cWellID
      INDEX ON cownerid + cWellID + ctypeinv + cprogcode TAG invtype
      INDEX ON DELETED() TAG _deleted

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'OwnerProc', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('OwnerProc', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE Setup
   **********************************************************
   LOCAL llReturn, loError

   llReturn = .T.

   TRY
      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      IF TYPE('This.dExpDate') # 'D'
         THIS.dexpdate = THIS.dacctdate
      ENDIF

      *
      *  Check to see if the quarterly wells should be released
      *
      IF THIS.checkquarterly()
         THIS.lrelqtr = THIS.omessage.CONFIRM('Should the quarterly wells be released during this run?')
      ENDIF

      SET DELETED ON
      WAIT WIND NOWAIT 'Preparing work files....'
      *
      ****************************************************************************
      * Prepare the jibwell cursor
      ****************************************************************************
      *
      IF THIS.lrelqtr
         SELE wellinv.cWellID, expense.cyear, expense.cperiod, expense.cdeck,;
            wells.cgroup, ;
            THIS.nrunno, ;
            THIS.crunyear AS crunyear, ;
            expense.cyear AS hyear, ;
            expense.cperiod AS hperiod, ;
            wells.lRoySevTx  AS lRoySevTx, ;
            wells.nprocess   AS nprocess  ;
            FROM wellinv, expense, wells ;
            WHERE (expense.nRunNoJIB = 0 OR (expense.nRunNoJIB = THIS.nrunno AND expense.cRunYearJIB = THIS.crunyear)) ;
            AND expense.dexpdate <= THIS.dexpdate ;
            AND expense.cyear # 'FIXD' ;
            AND wellinv.cWellID = expense.cWellID ;
            AND expense.cWellID = wells.cWellID ;
            AND wells.cgroup = THIS.cgroup ;
            AND NOT INLIST(wells.cwellstat, 'I', 'V', 'S', 'P') ;
            INTO CURSOR tempexp ;
            ORDER BY expense.cWellID, expense.cdeck, cyear, cperiod ;
            GROUP BY expense.cWellID, expense.cdeck, cyear, cperiod
      ELSE
         SELE wellinv.cWellID, expense.cyear, expense.cperiod, expense.cdeck, ;
            wells.cgroup, ;
            THIS.nrunno, ;
            THIS.crunyear AS crunyear, ;
            expense.cyear AS hyear, ;
            expense.cperiod AS hperiod, ;
            wells.lRoySevTx  AS lRoySevTx, ;
            wells.nprocess   AS nprocess  ;
            FROM wellinv, expense, wells ;
            WHERE (expense.nRunNoJIB = 0 OR (expense.nRunNoJIB = THIS.nrunno AND expense.cRunYearJIB = THIS.crunyear)) ;
            AND expense.dexpdate <= THIS.dexpdate ;
            AND expense.cyear # 'FIXD' ;
            AND wellinv.cWellID = expense.cWellID ;
            AND expense.cWellID = wells.cWellID ;
            AND wells.cgroup = THIS.cgroup ;
            AND wells.nprocess # 2 ;
            AND NOT INLIST(wells.cwellstat, 'I', 'V', 'S', 'P') ;
            INTO CURSOR tempexp ;
            ORDER BY expense.cWellID, expense.cdeck, cyear, cperiod ;
            GROUP BY expense.cWellID, expense.cdeck, cyear, cperiod
      ENDIF

      *
      ****************************************************************
      *   Create Temp Well Production History File
      ****************************************************************
      Make_Copy('wellhist', 'jibwell')

      SELECT tempexp
      SCAN
         SCATTER MEMVAR
         m.nrunno     = THIS.nrunno
         m.cRecType = 'J'
         IF EMPTY(m.cdeck)
            m.cdeck = THIS.oWellInv.DOIDeckNameLookup(m.hyear,m.hperiod,m.cWellID)
         ENDIF
         SELE jibwell
         LOCATE FOR cWellID + hyear + hperiod = m.cWellID + m.hyear + m.hperiod
         IF NOT FOUND()
            INSERT INTO jibwell FROM MEMVAR
         ENDIF
      ENDSCAN

      SET SAFETY OFF
      SELECT jibwell
      INDEX ON cWellID TAG cWellID
      INDEX ON cWellID + hyear + hperiod TAG wellprd
      INDEX ON hyear + hperiod TAG yearprd
      *
      ****************************************************************************
      *  Build jibowner table
      ****************************************************************************

      SELECT  cWellID ;
         FROM expense ;
         WHERE (expense.nRunNoJIB = 0 ;
         OR (expense.nRunNoJIB = THIS.nrunno ;
         AND expense.cRunYearJIB = THIS.crunyear)) ;
         AND expense.dexpdate <= THIS.dexpdate ;
         AND expense.cyear # 'FIXD' ;
         AND expense.cCatCode IN (SELECT  cCatCode ;
         FROM expcat ;
         WHERE ljibonly) ;
         INTO CURSOR jibonly ;
         ORDER BY cWellID ;
         GROUP BY cWellID

      SELECT  THIS.nrunno   AS nrunno, ;
         {^1980-01-01} AS hdate, ;
         wellinv.cownerid, ;
         wellinv.cWellID, ;
         wellinv.cdeck, ;
         THIS.cgroup AS cgroup, ;
         wellinv.nworkint, ;
         wellinv.cidwinv, ;
         wellinv.nintclass1, ;
         wellinv.nintclass2, ;
         wellinv.nintclass3, ;
         wellinv.nintclass4, ;
         wellinv.nintclass5, ;
         wellinv.nacpint, ;
         wellinv.nbcpint, ;
         wellinv.nRevOil, ;
         wellinv.nRevGas, ;
         wellinv.nRevTrp, ;
         wellinv.nRevOth, ;
         wellinv.nRevTax1, ;
         wellinv.nRevTax2, ;
         wellinv.nRevTax3, ;
         wellinv.nRevTax4, ;
         wellinv.nRevTax5, ;
         wellinv.nRevTax6, ;
         wellinv.nRevTax7, ;
         wellinv.nRevTax8, ;
         wellinv.nRevTax9, ;
         wellinv.nRevTax10, ;
         wellinv.nRevTax11, ;
         wellinv.nRevTax12, ;
         wellinv.nPlugpct, ;
         wellinv.ctypeinv, ;
         wellinv.cTypeInt, ;
         wellinv.cDirect, ;
         wellinv.lFlat, ;
         wellinv.nflatrate, ;
         wellinv.cFlatStart, ;
         wellinv.nFlatFreq, ;
         wellinv.cprogcode, ;
         wellinv.nrevmisc1, ;
         wellinv.nrevmisc2, ;
         wellinv.lJIB, ;
         wellinv.lOnHold, ;
         wellinv.cidwinv AS ciddisb, ;
         'J'  AS cRecType, ;
         .F.  AS lUSED, ;
         .F.  AS lProgNet, ;
         000000.00 AS nbbltot, ;
         000000.00 AS nmcftot, ;
         000000.00 AS nothtot, ;
         000000.00 AS nincome, ;
         000000.00 AS ngasrev, ;
         000000.00 AS noilrev, ;
         000000.00 AS ntrprev, ;
         000000.00 AS nmiscrev1, ;
         000000.00 AS nmiscrev2, ;
         000000.00 AS nexpense, ;
         000000.00 AS ntotale1, ;
         000000.00 AS ntotale2, ;
         000000.00 AS ntotale3, ;
         000000.00 AS ntotale4, ;
         000000.00 AS ntotale5, ;
         000000.00 AS ntotaleA, ;
         000000.00 AS ntotaleB, ;
         000000.00 AS nnetcheck, ;
         000000.00 AS nsevtaxes, ;
         wellinv.lprogram ;
         FROM wellinv, wells ;
         WHERE wellinv.cownerid IN (SELECT  cownerid ;
         FROM jibowntmp) ;
         AND wellinv.cWellID IN (SELECT  cWellID ;
         FROM jibwelltmp) ;
         AND wellinv.cWellID = wells.cWellID ;
         AND (wellinv.lJIB ;
         OR wellinv.cWellID IN (SELECT  cWellID ;
         FROM jibonly)) ;
         AND IIF(THIS.cgroup # '**', wells.cgroup = THIS.cgroup, .T.) ;
         AND NOT INLIST(wells.cwellstat, 'I', 'V', 'S', 'P') ;
         INTO CURSOR jibtmpx ;
         ORDER BY wellinv.cownerid, wellinv.cWellID, wellinv.cdeck

      ****************************************************************
      *   Create Temp Investor Disbursement File
      ****************************************************************
      SWSELECT('disbhist', .T.)
      lnX = AFIELDS(latempx)
      SWSELECT('ownpcts', .T.)
      lny = AFIELDS(latempy)
      DIMENSION laTemp[lnx + lny - 1, 18]
      FOR x = 1 TO lnX
         FOR Y = 1 TO 18
            laTemp[x, y] = latempx[x, y]
         ENDFOR
      ENDFOR
      FOR x = 1 TO lny - 1
         FOR Y = 1 TO 18
            laTemp[x + lnx, y] = latempy[x + 1, y]
         ENDFOR
      ENDFOR
      FOR x = 1 TO lnX + lny - 1
         laTemp[X, 7]  = ''
         laTemp[X, 8]  = ''
         laTemp[X, 9]  = ''
         laTemp[X, 10] = ''
         laTemp[X, 11] = ''
         laTemp[X, 12] = ''
         laTemp[X, 13] = ''
         laTemp[X, 14] = ''
         laTemp[X, 15] = ''
         laTemp[X, 18] = ''
      ENDFOR
      CREATE CURSOR invtmp FROM ARRAY laTemp

      SET SAFETY OFF
      CREATE CURSOR jibowner FROM ARRAY laTemp
      SELECT jibowner
      INDEX ON cownerid TAG cownerid
      INDEX ON cownerid + cprogcode + cWellID TAG invprog
      INDEX ON cprogcode TAG cprogcode
      INDEX ON hyear + hperiod TAG yearprd
      INDEX ON cownerid + cprogcode + cWellID + hyear + hperiod TAG ownperiod

      **-
      **- Append records to the owner work cursor
      **-
      SELE jibwell
      SCAN
         m.cWellID = cWellID
         m.hyear   = hyear
         m.hperiod = hperiod
         m.cDeck   = cDeck
         IF EMPTY(m.cdeck)
            m.cDeck = THIS.oWellInv.DOIDeckNameLookup(m.hyear,m.hperiod,m.cWellID)
         ENDIF    
         SELECT wellinv
         LOCATE FOR cWellID = m.cWellID AND cDeck = m.cDeck
         IF FOUND()
            SCAN FOR cWellID = m.cWellID AND cDeck = m.cDeck
               SCATTER MEMVAR

               SELECT jibowntmp
               LOCATE FOR cownerid = m.cownerid
               IF NOT FOUND()
                  LOOP
               ENDIF
               SELECT investor
               IF SEEK(m.cownerid)
                  m.lhold      = lhold
                  m.ldirectdep = ldirectdep
                  m.ndisbfreq  = ndisbfreq
                  m.nrunno     = THIS.nrunno
                  m.crunyear   = THIS.crunyear
                  INSERT INTO jibowner FROM MEMVAR
               ENDIF
            ENDSCAN
         ENDIF
      ENDSCAN

      **-
      **-  Flag the programs as being netted outside the program or not
      **-
      SELECT jibowner
      SCAN FOR NOT EMPTY(cprogcode)
         m.cprogcode = cprogcode
         SWSELECT('programs')
         SET ORDER TO cprogcode
         IF SEEK(m.cprogcode)
            m.lProgNet = lProgNet
         ELSE
            m.lProgNet = .F.
         ENDIF
         SELECT jibowner
         REPLACE lProgNet WITH m.lProgNet
      ENDSCAN

      WAIT CLEAR

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'Setup', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('Setup', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE wellproc
   **********************************************************
   LOCAL lnCount, lcsaveprd1, lcsaveprd2, lcYear, lnrunno
   LOCAL llReturn, loError

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      IF m.goApp.lCanceled
         llReturn = .F.
         IF NOT m.goApp.CancelMsg()
            THIS.lCanceled = .T.
            EXIT
         ENDIF
      ENDIF

      lnCount     = 0
      lcsaveprd1 = THIS.cperiod
      lcsaveprd2 = lcsaveprd1
      lcYear     = THIS.cyear
      lnrunno     = THIS.nrunno
      ldAcctDate = THIS.dacctdate

      SELECT jibwell
      COUNT FOR NOT DELETED() TO lnMax

      IF NOT THIS.lquiet
         THIS.oProgress = THIS.omessage.ProgressBar('Allocating expenses to the wells....')
         THIS.oProgress.SetProgressRange(0, lnMax)
      ENDIF

      SELECT jibwell
      SCAN
         m.cWellID    = cWellID
         m.nprocess    = nprocess
         m.ngasint    = ngasint
         m.noilint    = noilint
         lcProdPeriod = hperiod
         lcProdYear    = hyear

         IF m.goApp.lCanceled
            llReturn = .F.
            IF NOT m.goApp.CancelMsg()
               THIS.lCanceled = .T.
               EXIT
            ENDIF
         ENDIF

         SELE wellinv
         LOCATE FOR cWellID = m.cWellID AND lJIB
         IF FOUND()
            llJIBWell = .T.
         ELSE
            SELECT jibonly
            LOCATE FOR cWellID = m.cWellID
            IF FOUND()
               llJIBWell = .T.
            ELSE
               llJIBWell = .F.
            ENDIF
         ENDIF

         IF NOT THIS.lquiet
            THIS.oProgress.UpdateProgress(lnCount)
            lnCount = lnCount + 1
         ENDIF

         STORE 0 TO m.nTotale, m.ngasinc, m.noilinc, m.ntrpinc, m.nBBLTax, m.nMCFTax, m.nBBLTax1, m.nMCFTax1, ;
            M.nTotBBL, m.nTotMCF, m.bbltot, m.mcftot, m.nMiscinc1, m.nMiscinc2, ;
            M.ngather, m.ncompress, m.nMCFTaxr, m.nMCFTaxw, m.nBBLTaxr, m.nBBLTaxw, ;
            M.nExpgas, m.nExpoil, m.nexpcl1, m.nexpcl2, m.nexpcl3, m.nexpcl4, m.nexpcl4, m.nexpcl5, ;
            M.nexpcla, m.nexpclb, m.nTotSalt, m.nnetexp, m.nexpcl1, m.nexpcl2, m.nexpcl3, m.nexpcl4, ;
            M.nexpcl5, m.nexpcla, m.nexpclb, m.nclass0, m.nclass1, m.nclass2, m.nclass3, m.nclass4, ;
            M.nclass5, m.nclassa, m.nclassb, m.nclassp, m.nplugamt

         SWSELECT('wells')
         SET ORDER TO cWellID
         IF SEEK (m.cWellID)
            m.ctable        = ctable
            m.cwellname     = cwellname
            m.lthird_prty = lthird_prty
         ELSE
            LOOP
         ENDIF

         **-
         **-  Process well expenses
         **-

         SWSELECT('expense', .T.)
         SCAN FOR cWellID = m.cWellID AND ;
               nRunNoJIB = 0 AND ;
               (cyear + cperiod = lcProdYear + lcProdPeriod) AND ;
               dexpdate <= THIS.dexpdate AND ;
               NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
            SCATTER MEMVAR

            STORE 0 TO m.nclass0, m.nclass1, m.nclass2, m.nclass3, m.nclass4, M.nclass5, m.nclassa, m.nclassb

            IF THIS.lclose AND llJIBWell
               REPL nRunNoJIB  WITH lnrunno, ;
                  lClosed      WITH .T., ;
                  cRunYearJIB  WITH THIS.crunyear, ;
                  cacctyear    WITH THIS.cacctyear, ;
                  cacctprd     WITH THIS.cacctprd
            ENDIF

            IF EMPTY(m.cDeck)
               m.cDeck = THIS.oWellInv.DOIDeckNameLookup(m.cyear, m.cperiod, m.cWellID)
               SELECT expense
               REPLACE cDeck WITH m.cDeck
            ENDIF

            SWSELECT('expcat')
            SET ORDER TO cCatCode
            IF SEEK(m.cCatCode)
               IF EMPTY(m.cexpclass)
                  m.cexpclass = cexpclass
               ENDIF
            ELSE
               LOOP
            ENDIF

            SWSELECT('expense', .T.)
            IF EMPTY(cexpclass)
               REPL cexpclass WITH m.cexpclass
            ENDIF

            DO CASE
               CASE m.cexpclass = '0'
                  m.nclass0 = swnetexp(m.namount, m.cWellID, .T., '0', 'DN', .F., m.cownerid, m.cCatCode, m.cDeck)
               CASE m.cexpclass = '1'
                  m.nclass1 = swnetexp(m.namount, m.cWellID, .T., '1', 'DN', .F., m.cownerid, m.cCatCode, m.cDeck)
               CASE m.cexpclass = '2'
                  m.nclass2 = swnetexp(m.namount, m.cWellID, .T., '2', 'DN', .F., m.cownerid, m.cCatCode, m.cDeck)
               CASE m.cexpclass = '3'
                  m.nclass3 = swnetexp(m.namount, m.cWellID, .T., '3', 'DN', .F., m.cownerid, m.cCatCode, m.cDeck)
               CASE m.cexpclass = '4'
                  m.nclass4 = swnetexp(m.namount, m.cWellID, .T., '4', 'DN', .F., m.cownerid, m.cCatCode, m.cDeck)
               CASE m.cexpclass = '5'
                  m.nclass5 = swnetexp(m.namount, m.cWellID, .T., '5', 'DN', .F., m.cownerid, m.cCatCode, m.cDeck)
               CASE m.cexpclass = 'A'
                  m.nclassa = swnetexp(m.namount, m.cWellID, .T., 'A', 'DN', .F., m.cownerid, m.cCatCode, m.cDeck)
               CASE m.cexpclass = 'B'
                  m.nclassb = swnetexp(m.namount, m.cWellID, .T., 'B', 'DN', .F., m.cownerid, m.cCatCode, m.cDeck)
               CASE m.cexpclass = 'P'
                  IF m.goApp.lPluggingModule
                     m.nclassp = swnetexp(m.namount, m.cWellID, .T., 'P', 'DN', .F., m.cownerid, m.cCatCode, m.cDeck)
                  ENDIF
            ENDCASE
            m.nTotSalt = m.nTotSalt + swnetexp(m.nsaltwater, m.cWellID, .T., m.cexpclass, 'DN', '', ,'',m.cDeck)  &&  Net down the salt BBL's, since the Rev run closing will be doing the same thing - BH 07/16/2008
            **-
            **-  Get the net amounts of expenses based upon "dummy" owners in the well
            **-
            m.nnetexp = m.nnetexp + ;
               M.nclass0 + ;
               M.nclass1 + ;
               M.nclass2 + ;
               M.nclass3 + ;
               M.nclass4 + ;
               M.nclass5 + ;
               M.nclassa + ;
               M.nclassb + ;
               M.nclassp
            m.nTotale  = m.nTotale + m.nclass0
            m.nexpcl1  = m.nexpcl1 + m.nclass1
            m.nexpcl2  = m.nexpcl2 + m.nclass2
            m.nexpcl3  = m.nexpcl3 + m.nclass3
            m.nexpcl4  = m.nexpcl4 + m.nclass4
            m.nexpcl5  = m.nexpcl5 + m.nclass5
            m.nexpcla  = m.nexpcla + m.nclassa
            m.nexpclb  = m.nexpclb + m.nclassb
            m.nplugamt = m.nplugamt + m.nclassp

         ENDSCAN

         IF TYPE('ldAcctDate') # 'D'
            ldAcctDate = DATE()
         ENDIF
         IF TYPE('ldPostDate') # 'D'
            ldPostDate = DATE()
         ENDIF
         SELECT jibwell
         REPLACE ngasinc WITH  0, ;
            ngrossgas  WITH  0, ;
            noilinc    WITH  0, ;
            ngrossoil  WITH  0, ;
            ntrpinc    WITH  0, ;
            nMiscinc1  WITH  0, ;
            nMiscinc2  WITH  0, ;
            nrunno     WITH  THIS.nrunno, ;
            crunyear   WITH  THIS.crunyear, ;
            nnetexp    WITH  m.nnetexp, ;
            nTotale    WITH  m.nTotale, ;
            nexpcl1    WITH  m.nexpcl1, ;
            nexpcl2    WITH  m.nexpcl2, ;
            nexpcl3    WITH  m.nexpcl3, ;
            nexpcl4    WITH  m.nexpcl4, ;
            nexpcl5    WITH  m.nexpcl5, ;
            nexpcla    WITH  m.nexpcla, ;
            nexpclb    WITH  m.nexpclb, ;
            nplugamt   WITH  m.nplugamt, ;
            ntotbbltx1 WITH  0, ;
            ntotmcftx1 WITH  0, ;
            ntotothtx1 WITH  0, ;
            ntotbbltx2 WITH  0, ;
            ntotmcftx2 WITH  0, ;
            ntotothtx2 WITH  0, ;
            ntotbbltx3 WITH  0, ;
            ntotmcftx3 WITH  0, ;
            ntotothtx3 WITH  0, ;
            ntotbbltx4 WITH  0, ;
            ntotmcftx4 WITH  0, ;
            ntotothtx4 WITH  0, ;
            ntotbbltxr WITH  0, ;
            ntotmcftxr WITH  0, ;
            ntotbbltxw WITH  0, ;
            ntotmcftxw WITH  0, ;
            ngather    WITH  0, ;
            ncompress  WITH  0, ;
            nTotBBL    WITH  0, ;
            nTotMCF    WITH  0, ;
            noilint    WITH  0, ;
            ngasint    WITH  0, ;
            ndayson    WITH  0, ;
            nTotSalt   WITH  m.nTotSalt, ;
            nFlatGas   WITH  0, ;
            nFlatOil   WITH  0, ;
            ngbbltax1  WITH  0, ;
            ngmcftax1  WITH  0, ;
            ngbbltax2  WITH  0, ;
            ngmcftax2  WITH  0, ;
            hdate      WITH  ldAcctDate
         lcPeriod1 = lcsaveprd1
         lcPeriod2 = lcsaveprd2
      ENDSCAN

      IF NOT THIS.lquiet
         THIS.oProgress.CLOSEProgress()
         THIS.oProgress = .NULL.
      ENDIF

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'WellProc', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('WellProc', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC


   *-- Creates temporary work files
   **********************************************************
   PROCEDURE createtemp
   **********************************************************
   *===============================================================================
   *   DESCRIPTION: Creates the work cursors for printing JIB statements
   *===============================================================================

   LOCAL llReturn, loError

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      CREATE CURSOR jibtemph ;
         (cbatch     C(8), ;
         cInvNum    C(15), ;
         cCustId    C(10), ;
         dInvDate   D, ;
         nrunno     I, ;
         crunyear   C(4), ;
         nSalesTax  N(12, 2), ;
         nDiscTot   N(12, 2), ;
         nSubTotal  N(12, 2), ;
         nPayments  N(12, 2), ;
         nInvTot    N(13, 2), ;
         nInvBal    N(13, 2), ;
         mShipRem   M, ;
         dDueDate   D, ;
         dDiscDate  D, ;
         cReference C(15), ;
         lPrinted   L, ;
         cidTerm    C(8), ;
         cTaxCode   C(6), ;
         cInvType   C(2), ;
         lPosted    L, ;
         lDeleted   L, ;
         lAging     L, ;
         dpostdate  D, ;
         cdmbatch   C(8), ;
         cgroup     C(2), ;
         cTxnID     C(36))

      IF m.goApp.lqbversion
         CREATE CURSOR jibtempd ;
            (cidInvD    C(8), ;
            cProdPrd   C(2), ;
            cProdYear  C(4), ;
            cItemId    C(10), ;
            cItemDesc  C(40), ;
            cExtDesc   C(40), ;
            nPrice     N(12, 4), ;
            nDiscPct   N(5, 2), ;
            nDiscount  N(12, 2), ;
            nQuantity  N(12, 4), ;
            nExtension N(12, 2), ;
            nItemTax   N(12, 2), ;
            cAcctNo    C(36), ;
            cUnitNo    C(10), ;
            cDeck      C(10), ;
            cPriceCode C(1), ;
            cMeasure   C(10), ;
            cbatch     C(8), ;
            lDeleted   L, ;
            nInterest  N(11, 7), ;
            cpayee     C(30), ;
            dexpdate   D, ;
            cTaxable   C(1), ;
            cCatCode   C(4), ;
            cNotes     C(40), ;
            cworkorder C(10), ;
            cTaxCode   C(2))
      ELSE
         CREATE CURSOR jibtempd ;
            (cidInvD    C(8), ;
            cProdPrd   C(2), ;
            cProdYear  C(4), ;
            cItemId    C(10), ;
            cItemDesc  C(40), ;
            cExtDesc   C(40), ;
            nPrice     N(12, 4), ;
            nDiscPct   N(5, 2), ;
            nDiscount  N(12, 2), ;
            nQuantity  N(12, 4), ;
            nExtension N(12, 2), ;
            nItemTax   N(12, 2), ;
            cAcctNo    C(6), ;
            cUnitNo    C(10), ;
            cDeck      C(10), ;
            cPriceCode C(1), ;
            cMeasure   C(10), ;
            cbatch     C(8), ;
            lDeleted   L, ;
            nInterest  N(11, 7), ;
            cpayee     C(30), ;
            dexpdate   D, ;
            cTaxable   C(1), ;
            cCatCode   C(4), ;
            cNotes     C(40), ;
            cworkorder C(10), ;
            cTaxCode   C(2))
      ENDIF

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'CreateTemp', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('CreateTemp', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC


   *-- Calculates the current owner jib balances
   **********************************************************
   PROCEDURE jibbal
   **********************************************************
   LPARA tdDate, tcGroup, tcRunYear, tnRunNo, tcOwnerID1, tcOwnerID2, tlJunk, tlSelected
   LOCAL jnDays30, jnDays60, jnDays90, llReturn, loError

   llReturn = .T.

   TRY

      jnDays30   = GOMONTH(tdDate, -1)
      jnDays60   = GOMONTH(tdDate, -2)
      jnDays90   = GOMONTH(tdDate, -3)

      IF NOT tlSelected
         SELECT cownerid AS cID FROM investor WHERE BETWEEN(cownerid,tcOwnerID1,tcOwnerID2) INTO CURSOR SELECTED ORDER BY cID
      ENDIF

      IF VARTYPE(tcOwnerID1) # 'C' OR VARTYPE(tcOwnerID2) # 'C'
         SWSELECT('investor')
         SET ORDER TO cownerid
         GO TOP
         tcOwnerID1 = cownerid
         GO BOTT
         tcOwnerID2 = cownerid
      ENDIF

      IF TYPE('tcGroup') # 'L'
         llGroup = .T.
      ELSE
         llGroup = .F.
      ENDIF

      IF m.goApp.lCanceled
         llReturn = .F.
         IF NOT m.goApp.CancelMsg()
            THIS.lCanceled = .T.
            EXIT
         ENDIF
      ENDIF

      CREATE CURSOR jibbal ;
         (cCustId    C(10), ;
         cCustName  C(40), ;
         nCurrent   N(12, 2), ;
         nDays30    N(12, 2), ;
         nDays60    N(12, 2), ;
         nDays90    N(12, 2))

      SELECT  invhdr.cCustId, 00000.00 AS nCurrent, ;
         00000.00 AS nDays30, 00000.00 AS nDays60, ;
         00000.00 AS nDays90,  ;
         investor.cownname AS cCustName ;
         FROM invhdr, investor ;
         WHERE invhdr.cCustId  = investor.cownerid ;
         AND cCustId IN (SELECT cID FROM SELECTED)  ;
         AND invhdr.dInvDate <= tdDate ;
         AND investor.lIntegGL = .F. ;
         INTO CURSOR jibbalx ;
         ORDER BY invhdr.cCustId ;
         GROUP BY invhdr.cCustId

      SELECT jibbal
      APPEND FROM DBF('jibbalx')
      USE IN jibbalx
      SCAN
         m.cCustId  = cCustId
         m.nCurrent = 0
         m.nBal30     = 0
         m.nBal60     = 0
         m.nBal90     = 0
         SWSELECT('invhdr', .T.)
         SCAN FOR cCustId = m.cCustId AND nInvTot # 0 AND cInvType = 'J' AND dInvDate <= tdDate
            m.cbatch     = cbatch
            m.dInvDate = dInvDate
            m.nBal     = nInvTot
            IF llGroup
               * If we're only looking for a certain well group
               IF cgroup # tcGroup AND NOT EMPTY(cgroup)
                  LOOP
               ENDIF
            ENDIF
            * Look for pmts that paid the invoice
            SWSELECT('arpmtdet')
            SCAN FOR cinvtoken = m.cbatch
               lcBatch = cbatch
               SWSELECT('arpmthdr')
               SET ORDER TO cbatch
               IF SEEK(lcBatch)
                  IF dRecDate > tdDate + 1
                     LOOP
                  ENDIF
               ENDIF
               SWSELECT('arpmtdet')
               m.nBal = m.nBal - nAmtApp
            ENDSCAN
            DO CASE
               CASE BETWEEN(m.dInvDate, jnDays30 + 1, tdDate)
                  m.nCurrent = m.nCurrent + m.nBal
               CASE BETWEEN(m.dInvDate, jnDays60 + 1, jnDays30)
                  m.nBal30 = m.nBal30 + m.nBal
               CASE BETWEEN(m.dInvDate, jnDays90 + 1, jnDays60)
                  m.nBal60 = m.nBal60 + m.nBal
               CASE m.dInvDate <= jnDays90
                  m.nBal90 = m.nBal90 + m.nBal
            ENDCASE
            m.nBal = 0
         ENDSCAN
         SELECT jibbal
         REPLACE nCurrent WITH m.nCurrent, ;
            nDays30  WITH m.nBal30, ;
            nDays60  WITH m.nBal60, ;
            nDays90  WITH m.nBal90
         STORE 0 TO m.nCurrent, m.nBal30, m.nBal60, m.nBal90

      ENDSCAN
      SELECT jibbal
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'JIBBal', loError.LINENO, 'JIBproc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('JIBBal', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC


   *-- Creates JIB invoice files
   **********************************************************
   PROCEDURE jibinv
   **********************************************************
   LPARA tlClose
   LOCAL tcyear, tcperiod, tcGroup, tcdmbatch, tdpostdate, tlcloseprd, llcatdesc
   LOCAL llexpsum, jcOwnerID, llReturn, loError

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      tcyear     = THIS.cyear
      tcperiod     = THIS.cperiod
      tcGroup     = THIS.cgroup
      tnRunNo     = THIS.nrunno
      tcdmbatch  = ''
      tdpostdate = THIS.dacctdate
      tlcloseprd = .F.

      m.nInvTot = 0

      ****************************************************************
      *  Get the beginning JIB invoice number
      ****************************************************************
      SWSELECT('aropt', .T.)
      GO TOP
      lnjibinv = njibinv

      ****************************************************************
      *  Get the expense clearing account
      ****************************************************************
      SWSELECT('glopt')
      GO TOP
      lcexpclear = cexpclear

      ****************************************************************
      *  Get the category desc option
      ****************************************************************
      SWSELECT('options')
      GO TOP
      llcatdesc    = lacctdesc
      llexpsum       = lexpsum
      lljibnotes    = ljibnotes
      llShowVendor = lShowVendor

      IF NOT USED('jibowner')
         llReturn = .F.
         EXIT
      ENDIF

      IF USED('exptemp')
         USE IN exptemp
      ENDIF

      SWSELECT('expense', .T.)
      REPL loneman WITH .F. FOR (nRunNoJIB = THIS.nrunno OR nRunNoJIB = 0) AND loneman = .T.

      SELECT jibowner
      lnMax = RECC()

      IF lnMax > 0
         SELECT  jibowner.cownerid, jibowner.cWellID,  ;
            jibowner.ctypeinv, investor.cownname, investor.cidTerm, ;
            SUM(nnetcheck * -1) AS nInvTot ;
            FROM jibowner, investor ;
            WHERE ctypeinv = 'W' ;
            AND jibowner.cownerid = investor.cownerid ;
            INTO CURSOR invjtot ;
            ORDER BY jibowner.cownerid ;
            GROUP BY jibowner.cownerid

         lnMax     = _TALLY
         lnCount = 1

         Make_Copy('expense', 'tempexp')

         IF llexpsum         && Summarize expenses
            SWSELECT('expense', .T.)
            SCAN FOR ((nRunNoJIB = THIS.nrunno AND cRunYearJIB = THIS.crunyear) OR nRunNoJIB = 0) AND ;
                  dexpdate <= THIS.dexpdate AND ;
                  cyear # 'FIXD' AND ;
                  NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
               SCATTER MEMVAR
               INSERT INTO tempexp FROM MEMVAR
            ENDSCAN
            SELECT  cWellID, ccateg, cyear, cperiod, crefid, dexpdate, SUM(namount) AS namount, ;
               cpayee, cmemo, cvendorid, cpaidbyck, cexpclass, nsaltwater, cprdpaid, ;
               lfixed, laptran, cbatch, cownerid, loneman, cCatCode ;
               FROM tempexp ;
               INTO CURSOR exptemp READWRITE ;
               ORDER BY cWellID, cCatCode, cyear, cperiod, cownerid, cexpclass ;
               GROUP BY cWellID, cCatCode, cyear, cperiod, cownerid, cexpclass

         ELSE
            SWSELECT('expense', .T.)
            SCAN FOR ((nRunNoJIB = THIS.nrunno AND cRunYearJIB = THIS.crunyear) OR nRunNoJIB = 0) AND ;
                  dexpdate <= THIS.dexpdate AND ;
                  cyear # 'FIXD' AND ;
                  NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
               SCATTER MEMVAR
               INSERT INTO tempexp FROM MEMVAR
            ENDSCAN
            SELE tempexp
            INDEX ON cWellID TAG cWellID
            INDEX ON cyear + cperiod TAG yearprd
         ENDIF

         *  Make sure we have a good key for the invoice detail table
         m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
         SET DELETED OFF
         SWSELECT('invdet', .T.)
         SET ORDER TO cidInvD
         DO WHILE SEEK(m.cidInvD)
            m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
         ENDDO

         THIS.oProgress = THIS.omessage.ProgressBar('Building the JIB invoices...')
         THIS.oProgress.SetProgressRange(0, lnMax)

         * Reset used flag in roundtmp
         SELE roundtmp
         REPL lUSED WITH .F. FOR cdmbatch == THIS.cdmbatch

         SELECT invjtot
         SCAN
            SCATTER MEMVAR

            IF m.goApp.lCanceled
               llReturn = .F.
               IF NOT m.goApp.CancelMsg()
                  THIS.lCanceled = .T.
                  EXIT
               ENDIF
            ENDIF

            THIS.oProgress.UpdateProgress(lnCount)
            lnCount = lnCount + 1
            IF m.ctypeinv # 'W'
               LOOP
            ENDIF
            IF m.nInvTot = 0
               SELECT jibowner
               LOCATE FOR cownerid == m.cownerid AND nnetcheck # 0
               IF NOT FOUND()
                  * LOOP
               ENDIF
            ENDIF

            *  Don't create JIBs for Dummy owners
            SWSELECT('investor')
            SET ORDER TO cownerid
            IF SEEK(m.cownerid) AND investor.ldummy
               LOOP
            ENDIF

            m.cbatch = THIS.oregistry.IncrementCounter('%Shared.Counters.Batch')
            SET DELETED OFF
            SWSELECT('invhdr', .T.)
            SET ORDER TO cbatch
            DO WHILE SEEK(m.cbatch)
               m.cbatch = THIS.oregistry.IncrementCounter('%Shared.Counters.Batch')
            ENDDO
            SET DELETED ON

            * Save the batch for this invoice
            lcBatch = m.cbatch

            m.cInvNum = 'JIB' + PADL(TRANSFORM(lnjibinv), 8, '0')
            lnjibinv    = lnjibinv + 1

            m.cCustId   = m.cownerid
            m.cCustName   = m.cownname
            m.dInvDate   = tdpostdate
            m.dpostdate   = tdpostdate
            m.nSalesTax   = 0
            m.nSubTotal   = m.nInvTot
            m.nPayments   = 0
            m.nInvTot   = m.nInvTot
            m.nInvBal   = m.nInvTot
            m.mShipRem   = ' '
            m.nnetduein   = 0
            m.ndiscin   = 0
            m.nDiscPct   = 0

            IF EMPTY(m.cidTerm)
               SWSELECT('terms')
               SCAN FOR ldefterm
                  m.cidTerm   = cidTerm
                  m.nnetduein   = nnetduein
                  m.ndiscin   = ndiscin
                  m.nDiscPct   = nDiscPct
                  EXIT
               ENDSCAN
            ELSE
               SWSELECT('terms')
               LOCATE FOR ALLTRIM(cidTerm) = ALLTRIM(m.cidTerm)
               IF FOUND()
                  m.nnetduein   = nnetduein
                  m.ndiscin   = ndiscin
                  m.nDiscPct   = nDiscPct
                  m.nDiscTot   = m.nInvTot * (m.nDiscPct / 100)
               ELSE
                  m.nDiscTot   = 0
                  m.nnetduein   = 30
                  m.ndiscin   = 0
                  m.nDiscPct   = 0
               ENDIF
            ENDIF

            m.dDueDate   = m.dInvDate + m.nnetduein
            m.dDiscDate   = m.dInvDate + m.ndiscin

            m.cReference = 'JIB: ' + tcyear + '/' + tcperiod
            m.lPrinted    = .F.
            m.cTaxCode    = ' '
            m.cInvType    = 'J'
            m.lDeleted    = .F.
            m.lAging       = .F.
            m.cgroup       = tcGroup
            m.crunyear    = tcyear
            m.nrunno       = tnRunNo

            INSERT INTO jibtemph FROM MEMVAR
            jcOwnerID = m.cownerid

            * Scan through each well the owner is in so we can apply one prepayment per well
            SELECT cWellID FROM jibowner ;
               WHERE cownerid == jcOwnerID ;
               INTO CURSOR ownwell ;
               GROUP BY cWellID ORDER BY cWellID
            SELECT ownwell
            SCAN
               m.cWellID   = cWellID
               lnWellTotal   = 0

               * Scan through all the expenses for this owner
               SELECT jibowner
               SCAN FOR cownerid == jcOwnerID AND cWellID == m.cWellID
                  SCATTER MEMVAR
                  m.cProdYear   = m.hyear
                  m.cProdPrd   = m.hperiod

                  *****************************************************************
                  *   Build the invoice detail lines
                  *****************************************************************
                  STORE 0 TO jnworkint, jnclass1, jnclass2, jnclass3, jnclass4, jnclass5
                  IF llexpsum         && Summarize expenses
                     SELECT exptemp
                  ELSE
                     SELECT tempexp
                  ENDIF

                  SCAN FOR cWellID = m.cWellID AND cyear + cperiod = m.hyear + m.hperiod
                     SCATTER MEMVAR
                     m.ccategory = ccateg

                     *  Look for expclass.  If not found just use what's on the expense record
                     SELE expcat
                     SET ORDER TO cCatCode
                     IF SEEK(m.cCatCode)
                        m.cdescrip = cdescrip
                        m.cTaxCode = cTaxCode
                        * Check for net owners and only apply JIB Only expenses to them
                        IF NOT (jibowner.lJIB OR expcat.ljibonly)
                           LOOP
                        ENDIF

                     ELSE
                        LOCATE FOR UPPER(ccateg) = UPPER(m.ccateg)
                        IF FOUND()
                           m.cdescrip = cdescrip
                           m.cTaxCode = cTaxCode
                           m.cCatCode = cCatCode
                        ENDIF
                     ENDIF

                     IF m.cexpclass = '0' AND m.ctypeinv = 'W'
                        IF llexpsum
                           SELECT exptemp
                        ELSE
                           SELECT tempexp
                        ENDIF

                        m.cbatch = lcBatch

                        *  Store original interests so we can change for one-man-items.  pws 3/11/97
                        jnworkint = m.nworkint
                        DO CASE
                           CASE m.cownerid = ' '
                              * Don't do anything if the cOwnerID is blank
                           CASE m.cownerid = jcOwnerID AND NOT m.loneman
                              REPLACE loneman WITH .T.
                              m.nworkint = 100
                           CASE m.cownerid # jcOwnerID
                              m.cownerid = jcOwnerID
                              LOOP
                           CASE m.cownerid = jcOwnerID AND loneman
                              LOOP
                        ENDCASE

                        m.cownerid   = jcOwnerID
                        m.crptgroup   = 'D'
                        m.cmiscmemo   = m.cmemo
                        m.cperiod   = tcperiod
                        m.cyear      = tcyear
                        m.ninvamt   = swround(m.namount * (m.nworkint / 100), 2)
                        lnWellTotal   = lnWellTotal + m.ninvamt
                        m.cNotes      = m.cmemo

                        *  Make sure we have a good key for the invoice detail table
                        m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        SET DELETED OFF
                        SWSELECT('invdet', .T.)
                        SET ORDER TO cidInvD
                        IF SEEK(m.cidInvD)
                           GO BOTT
                           ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                           m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                           IF invdet.cidInvD >= m.ccountervalue
                              THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                              THIS.oregistry.updatecounter(ocounter)
                           ENDIF
                           THIS.oregistry.unlockcounter(ocounter)
                           m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        ENDIF
                        SET DELETED ON

                        m.cItemId    = m.cCatCode
                        IF NOT lljibnotes
                           IF llcatdesc AND NOT EMPTY(m.cdescrip)
                              m.cItemDesc = m.cdescrip
                           ELSE
                              m.cItemDesc  = m.ccategory
                           ENDIF
                        ELSE
                           IF NOT EMPTY(m.cmemo)
                              m.cItemDesc = m.cmemo
                           ELSE
                              m.cItemDesc = m.ccategory
                           ENDIF
                        ENDIF
                        IF FILE('datafiles\jibref.cfg')
                           m.cworkorder = m.crefid
                        ELSE
                           m.cworkorder = ''
                        ENDIF
                        m.nPrice       = m.namount
                        m.nInterest    = m.nworkint
                        m.nQuantity    = 1
                        m.nExtension = m.ninvamt
                        m.nDiscPct    = 0
                        m.nDiscount    = 0
                        m.cUnitNo    = m.cWellID
                        m.cdeptno    = ' '
                        m.cTaxable    = 'E'
                        m.cPriceCode = '1'
                        m.cMeasure    = ' '
                        m.lDeleted    = .F.
                        m.cAcctNo    = lcexpclear
                        SWSELECT('vendor')
                        LOCATE FOR cvendorid = m.cvendorid
                        IF FOUND()
                           m.cpayee = cvendname
                        ENDIF
                        IF m.nExtension # 0
                           INSERT INTO jibtempd FROM MEMVAR
                        ENDIF
                        STORE 0 TO m.ninvamt, m.namount, m.ntotal
                        STORE ' ' TO m.cpayee, m.ccategory, m.cdescript, m.cmiscmemo
                        *  Restore original interests in case one-man-item logic changed them. pws 3/11/97
                        m.nworkint   = jnworkint
                     ENDIF

                     IF m.ntotale1 # 0 AND m.cexpclass = '1'
                        IF llexpsum
                           SELECT exptemp
                        ELSE
                           SELECT tempexp
                        ENDIF
                        m.cbatch = lcBatch

                        *  Store original interests so we can change for one-man-items.  pws 3/11/97
                        jnclass1  = m.nintclass1
                        DO CASE
                           CASE m.cownerid = jcOwnerID AND NOT m.loneman
                              REPLACE loneman WITH .T.
                              m.nintclass1 = 100
                           CASE m.cownerid = ' '
                              * Don't do anything if the cOwnerID is blank
                           CASE m.cownerid # jcOwnerID
                              m.cownerid = jcOwnerID
                              LOOP
                           CASE m.cownerid = jcOwnerID AND loneman
                              LOOP
                        ENDCASE
                        m.cownerid = jcOwnerID
                        jnworkint  = m.nworkint

                        IF llcatdesc AND NOT EMPTY(m.cdescrip)
                           *
                           * Report category descript instead of name
                           *
                           m.ccategory = m.cdescrip
                        ENDIF

                        m.cpayee      = cpayee
                        m.namount   = namount
                        m.cvendorid   = cvendorid
                        m.nworkint   = m.nintclass1
                        m.ninvamt   = swround((m.namount * (m.nintclass1 / 100)), 2)
                        lnWellTotal   = lnWellTotal + m.ninvamt
                        m.cperiod   = tcperiod
                        m.cyear      = tcyear

                        *
                        *  Check for counter being out-of-sync
                        *
                        *  Make sure we have a good key for the invoice detail table
                        m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        SET DELETED OFF
                        SWSELECT('invdet', .T.)
                        SET ORDER TO cidInvD
                        IF SEEK(m.cidInvD)
                           GO BOTT
                           ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                           m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                           IF invdet.cidInvD >= m.ccountervalue
                              THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                              THIS.oregistry.updatecounter(ocounter)
                           ENDIF
                           THIS.oregistry.unlockcounter(ocounter)
                           m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        ENDIF
                        SET DELETED ON
                        m.cItemId    = m.cCatCode

                        IF NOT lljibnotes
                           IF llcatdesc
                              m.cItemDesc = m.cdescrip
                           ELSE
                              m.cItemDesc  = m.ccategory
                           ENDIF
                        ELSE
                           IF NOT EMPTY(m.cmemo)
                              m.cItemDesc = m.cmemo
                           ELSE
                              m.cItemDesc = m.ccategory
                           ENDIF
                        ENDIF
                        IF FILE('datafiles\jibref.cfg')
                           m.cworkorder = m.crefid
                        ELSE
                           m.cworkorder = ''
                        ENDIF
                        m.nPrice       = m.namount
                        m.nInterest    = m.nintclass1
                        m.nQuantity    = 1
                        m.nExtension = m.ninvamt
                        m.nDiscPct    = 0
                        m.nDiscount    = 0
                        m.cUnitNo    = m.cWellID
                        m.cdeptno    = ' '
                        m.cTaxable    = 'E'
                        m.cPriceCode = '1'
                        m.cMeasure    = ' '
                        m.lDeleted    = .F.
                        m.cAcctNo    = lcexpclear
                        SWSELECT('vendor')
                        LOCATE FOR cvendorid = m.cvendorid
                        IF FOUND()
                           m.cpayee = cvendname
                        ENDIF
                        IF m.nExtension # 0
                           INSERT INTO jibtempd FROM MEMVAR
                        ENDIF
                        STORE 0 TO m.ninvamt, m.namount, m.ntotal
                        STORE ' ' TO m.cpayee, m.ccategory, m.cdescript, m.cmiscmemo
                        SELECT tempexp
                        m.nintclass1 = jnclass1
                        m.nworkint    = jnworkint
                     ENDIF

                     IF m.ntotale2 # 0 AND m.cexpclass = '2'
                        IF llexpsum
                           SELECT exptemp
                        ELSE
                           SELECT tempexp
                        ENDIF
                        m.cbatch = lcBatch

                        *  Store original interests so we can change for one-man-items.  pws 3/11/97
                        jnclass2  = m.nintclass2
                        DO CASE
                           CASE m.cownerid = jcOwnerID AND NOT m.loneman
                              REPLACE loneman WITH .T.
                              m.nintclass2 = 100
                           CASE m.cownerid = ' '
                              * Don't do anything if the cOwnerID is blank
                           CASE m.cownerid # jcOwnerID
                              m.cownerid = jcOwnerID
                              LOOP
                           CASE m.cownerid = jcOwnerID AND loneman
                              LOOP
                        ENDCASE
                        m.cownerid = jcOwnerID
                        jnworkint  = m.nworkint

                        IF llcatdesc AND NOT EMPTY(m.cdescrip)
                           *
                           * Report category descript instead of name
                           *
                           m.ccategory = m.cdescrip
                        ENDIF
                        IF lljibnotes
                           m.cdescrip = m.cmemo
                        ENDIF

                        m.cpayee      = cpayee
                        m.namount   = namount
                        m.cvendorid   = cvendorid
                        m.nworkint   = m.nintclass2
                        m.ninvamt   = swround((m.namount * (m.nintclass2 / 100)), 2)
                        lnWellTotal   = lnWellTotal + m.ninvamt
                        m.cperiod   = tcperiod
                        m.cyear      = tcyear

                        *
                        *  Check for counter being out-of-sync
                        *
                        *  Make sure we have a good key for the invoice detail table
                        m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        SET DELETED OFF
                        SWSELECT('invdet', .T.)
                        SET ORDER TO cidInvD
                        IF SEEK(m.cidInvD)
                           GO BOTT
                           ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                           m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                           IF invdet.cidInvD >= m.ccountervalue
                              THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                              THIS.oregistry.updatecounter(ocounter)
                           ENDIF
                           THIS.oregistry.unlockcounter(ocounter)
                           m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        ENDIF
                        SET DELETED ON

                        m.cItemId    = m.cCatCode

                        IF NOT lljibnotes
                           IF llcatdesc
                              m.cItemDesc = m.cdescrip
                           ELSE
                              m.cItemDesc  = m.ccategory
                           ENDIF
                        ELSE
                           IF NOT EMPTY(m.cmemo)
                              m.cItemDesc = m.cmemo
                           ELSE
                              m.cItemDesc = m.ccategory
                           ENDIF
                        ENDIF
                        IF FILE('datafiles\jibref.cfg')
                           m.cworkorder = m.crefid
                        ELSE
                           m.cworkorder = ''
                        ENDIF
                        m.nPrice       = m.namount
                        m.nInterest    = m.nintclass2
                        m.nQuantity    = 1
                        m.nExtension = m.ninvamt
                        m.nDiscPct    = 0
                        m.nDiscount    = 0
                        m.cUnitNo    = m.cWellID
                        m.cdeptno    = ' '
                        m.cTaxable    = 'E'
                        m.cPriceCode = '1'
                        m.cMeasure    = ' '
                        m.lDeleted    = .F.
                        m.cAcctNo    = lcexpclear
                        SWSELECT('vendor')
                        LOCATE FOR cvendorid = m.cvendorid
                        IF FOUND()
                           m.cpayee = cvendname
                        ENDIF
                        IF m.nExtension # 0
                           INSERT INTO jibtempd FROM MEMVAR
                        ENDIF
                        STORE 0 TO m.ninvamt, m.namount, m.ntotal
                        STORE ' ' TO m.cpayee, m.ccategory, m.cdescript, m.cmiscmemo
                        SELECT tempexp
                        m.nintclass2 = jnclass2
                        m.nworkint    = jnworkint
                     ENDIF

                     IF m.ntotale3 # 0 AND m.cexpclass = '3'
                        IF llexpsum
                           SELECT exptemp
                        ELSE
                           SELECT tempexp
                        ENDIF
                        m.cbatch = lcBatch

                        *  Store original interests so we can change for one-man-items.  pws 3/11/97
                        jnclass3  = m.nintclass3
                        DO CASE
                           CASE m.cownerid = jcOwnerID AND NOT m.loneman
                              REPLACE loneman WITH .T.
                              m.nintclass3 = 100
                           CASE m.cownerid = ' '
                              * Don't do anything if the cOwnerID is blank
                           CASE m.cownerid # jcOwnerID
                              m.cownerid = jcOwnerID
                              LOOP
                           CASE m.cownerid = jcOwnerID AND loneman
                              LOOP
                        ENDCASE
                        m.cownerid = jcOwnerID
                        jnworkint  = m.nworkint

                        IF llcatdesc AND NOT EMPTY(m.cdescrip)
                           *
                           * Report category descript instead of name
                           *
                           m.ccategory = m.cdescrip
                        ENDIF
                        IF FILE('datafiles\jibref.cfg')
                           m.cworkorder = m.crefid
                        ELSE
                           m.cworkorder = ''
                        ENDIF
                        m.cpayee      = cpayee
                        m.namount   = namount
                        m.cvendorid   = cvendorid
                        m.nworkint   = m.nintclass3
                        m.ninvamt   = swround((m.namount * (m.nintclass3 / 100)), 2)
                        lnWellTotal   = lnWellTotal + m.ninvamt
                        m.cperiod   = tcperiod
                        m.cyear      = tcyear


                        *  Make sure we have a good key for the invoice detail table
                        m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        SET DELETED OFF
                        SWSELECT('invdet', .T.)
                        SET ORDER TO cidInvD
                        IF SEEK(m.cidInvD)
                           GO BOTT
                           ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                           m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                           IF invdet.cidInvD >= m.ccountervalue
                              THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                              THIS.oregistry.updatecounter(ocounter)
                           ENDIF
                           THIS.oregistry.unlockcounter(ocounter)
                           m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        ENDIF
                        SET DELETED ON
                        m.cItemId    = m.cCatCode
                        IF NOT lljibnotes
                           IF llcatdesc
                              m.cItemDesc = m.cdescrip
                           ELSE
                              m.cItemDesc  = m.ccategory
                           ENDIF
                        ELSE
                           IF NOT EMPTY(m.cmemo)
                              m.cItemDesc = m.cmemo
                           ELSE
                              m.cItemDesc = m.ccategory
                           ENDIF
                        ENDIF
                        m.nPrice       = m.namount
                        m.nInterest    = m.nintclass3
                        m.nQuantity    = 1
                        m.nExtension = m.ninvamt
                        m.nDiscPct    = 0
                        m.nDiscount    = 0
                        m.cUnitNo    = m.cWellID
                        m.cdeptno    = ' '
                        m.cTaxable    = 'E'
                        m.cPriceCode = '1'
                        m.cMeasure    = ' '
                        m.lDeleted    = .F.
                        m.cAcctNo    = lcexpclear
                        SWSELECT('vendor')
                        LOCATE FOR cvendorid = m.cvendorid
                        IF FOUND()
                           m.cpayee = cvendname
                        ENDIF
                        IF m.nExtension # 0
                           INSERT INTO jibtempd FROM MEMVAR
                        ENDIF
                        STORE 0 TO m.ninvamt, m.namount
                        STORE ' ' TO m.cpayee, m.ccategory, m.cdescript, m.cmiscmemo
                        SELECT tempexp
                        m.nintclass3 = jnclass3
                        m.nworkint    = jnworkint
                     ENDIF

                     IF m.ntotale4 # 0 AND m.cexpclass = '4'
                        IF llexpsum
                           SELECT exptemp
                        ELSE
                           SELECT tempexp
                        ENDIF
                        m.cbatch = lcBatch

                        *  Store original interests so we can change for one-man-items.  pws 3/11/97
                        jnclass4  = m.nintclass4
                        DO CASE
                           CASE m.cownerid = jcOwnerID AND NOT m.loneman
                              REPLACE loneman WITH .T.
                              m.nintclass4 = 100
                           CASE m.cownerid = ' '
                              * Don't do anything if the cOwnerID is blank
                           CASE m.cownerid # jcOwnerID
                              m.cownerid = jcOwnerID
                              LOOP
                           CASE m.cownerid = jcOwnerID AND loneman
                              LOOP
                        ENDCASE
                        m.cownerid = jcOwnerID
                        jnworkint  = m.nworkint

                        IF llcatdesc AND NOT EMPTY(m.cdescrip)
                           *
                           * Report category descript instead of name
                           *
                           m.ccategory = m.cdescrip
                        ENDIF

                        m.cpayee      = cpayee
                        m.namount   = namount
                        m.cvendorid   = cvendorid
                        m.nworkint   = m.nintclass4
                        m.ninvamt   = swround((m.namount * (m.nintclass4 / 100)), 2)
                        lnWellTotal   = lnWellTotal + m.ninvamt
                        m.cperiod   = tcperiod
                        m.cyear      = tcyear

                        *  Make sure we have a good key for the invoice detail table
                        m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        SET DELETED OFF
                        SWSELECT('invdet', .T.)
                        SET ORDER TO cidInvD
                        IF SEEK(m.cidInvD)
                           GO BOTT
                           ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                           m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                           IF invdet.cidInvD >= m.ccountervalue
                              THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                              THIS.oregistry.updatecounter(ocounter)
                           ENDIF
                           THIS.oregistry.unlockcounter(ocounter)
                           m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        ENDIF
                        SET DELETED ON

                        m.cItemId    = m.cCatCode
                        IF NOT lljibnotes
                           IF llcatdesc
                              m.cItemDesc = m.cdescrip
                           ELSE
                              m.cItemDesc  = m.ccategory
                           ENDIF
                        ELSE
                           IF NOT EMPTY(m.cmemo)
                              m.cItemDesc = m.cmemo
                           ELSE
                              m.cItemDesc = m.ccategory
                           ENDIF
                        ENDIF
                        IF FILE('datafiles\jibref.cfg')
                           m.cworkorder = m.crefid
                        ELSE
                           m.cworkorder = ''
                        ENDIF
                        m.nPrice       = m.namount
                        m.nInterest    = m.nintclass4
                        m.nQuantity    = 1
                        m.nExtension = m.ninvamt
                        m.nDiscPct    = 0
                        m.nDiscount    = 0
                        m.cUnitNo    = m.cWellID
                        m.cdeptno    = ' '
                        m.cTaxable    = 'E'
                        m.cPriceCode = '1'
                        m.cMeasure    = ' '
                        m.lDeleted    = .F.
                        m.cAcctNo    = lcexpclear
                        SWSELECT('vendor')
                        LOCATE FOR cvendorid = m.cvendorid
                        IF FOUND()
                           m.cpayee = cvendname
                        ENDIF
                        IF m.nExtension # 0
                           INSERT INTO jibtempd FROM MEMVAR
                        ENDIF
                        STORE 0 TO m.ninvamt, m.namount
                        STORE ' ' TO m.cpayee, m.ccategory, m.cdescript, m.cmiscmemo
                        SELECT tempexp
                        m.nintclass4 = jnclass4
                        m.nworkint    = jnworkint
                     ENDIF

                     IF m.ntotale5 # 0 AND m.cexpclass = '5'
                        IF llexpsum
                           SELECT exptemp
                        ELSE
                           SELECT tempexp
                        ENDIF
                        m.cbatch = lcBatch

                        *  Store original interests so we can change for one-man-items.  pws 3/11/97
                        jnclass5  = m.nintclass5
                        DO CASE
                           CASE m.cownerid = jcOwnerID AND NOT m.loneman
                              REPLACE loneman WITH .T.
                              m.nintclass5 = 100
                           CASE m.cownerid = ' '
                              * Don't do anything if the cOwnerID is blank
                           CASE m.cownerid # jcOwnerID
                              m.cownerid = jcOwnerID
                              LOOP
                           CASE m.cownerid = jcOwnerID AND loneman
                              LOOP
                        ENDCASE
                        m.cownerid = jcOwnerID
                        jnworkint  = m.nworkint

                        IF llcatdesc AND NOT EMPTY(m.cdescrip)
                           *
                           * Report category descript instead of name
                           *
                           m.ccategory = m.cdescrip
                        ENDIF
                        m.cpayee      = cpayee
                        m.namount   = namount
                        m.cvendorid   = cvendorid
                        m.nworkint   = m.nintclass5
                        m.ninvamt   = swround((m.namount * (m.nintclass5 / 100)), 2)
                        lnWellTotal   = lnWellTotal + m.ninvamt
                        m.cperiod   = tcperiod
                        m.cyear      = tcyear

                        *  Make sure we have a good key for the invoice detail table
                        m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        SET DELETED OFF
                        SWSELECT('invdet', .T.)
                        SET ORDER TO cidInvD
                        IF SEEK(m.cidInvD)
                           GO BOTT
                           ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                           m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                           IF invdet.cidInvD >= m.ccountervalue
                              THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                              THIS.oregistry.updatecounter(ocounter)
                           ENDIF
                           THIS.oregistry.unlockcounter(ocounter)
                           m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        ENDIF
                        SET DELETED ON

                        m.cItemId    = m.cCatCode
                        IF NOT lljibnotes
                           IF llcatdesc
                              m.cItemDesc = m.cdescrip
                           ELSE
                              m.cItemDesc  = m.ccategory
                           ENDIF
                        ELSE
                           IF NOT EMPTY(m.cmemo)
                              m.cItemDesc = m.cmemo
                           ELSE
                              m.cItemDesc = m.ccategory
                           ENDIF
                        ENDIF
                        IF FILE('datafiles\jibref.cfg')
                           m.cworkorder = m.crefid
                        ELSE
                           m.cworkorder = ''
                        ENDIF
                        m.nPrice       = m.namount
                        m.nInterest    = m.nworkint
                        m.nQuantity    = 1
                        m.nExtension = m.ninvamt
                        m.nDiscPct    = 0
                        m.nDiscount    = 0
                        m.cUnitNo    = m.cWellID
                        m.cdeptno    = ' '
                        m.cTaxable    = 'E'
                        m.cPriceCode = '1'
                        m.cMeasure    = ' '
                        m.lDeleted    = .F.
                        m.cAcctNo    = lcexpclear
                        SWSELECT('vendor')
                        LOCATE FOR cvendorid = m.cvendorid
                        IF FOUND()
                           m.cpayee = cvendname
                        ENDIF
                        IF m.nExtension # 0
                           INSERT INTO jibtempd FROM MEMVAR
                        ENDIF
                        STORE 0 TO m.ninvamt, m.namount
                        STORE ' ' TO m.cpayee, m.ccategory, m.cdescript, m.cmiscmemo
                        SELECT tempexp
                        m.nintclass5 = jnclass5
                        m.nworkint    = jnworkint
                     ENDIF

                     IF m.ntotaleA # 0 AND m.cexpclass = 'A'
                        IF llexpsum
                           SELECT exptemp
                        ELSE
                           SELECT tempexp
                        ENDIF
                        m.cbatch = lcBatch

                        *  Store original interests so we can change for one-man-items.  pws 3/11/97
                        jnclassa  = m.nacpint
                        DO CASE
                           CASE m.cownerid = jcOwnerID AND NOT m.loneman
                              REPLACE loneman WITH .T.
                              m.nacpint = 100
                           CASE m.cownerid = ' '
                              * Don't do anything if the cOwnerID is blank
                           CASE m.cownerid # jcOwnerID
                              m.cownerid = jcOwnerID
                              LOOP
                           CASE m.cownerid = jcOwnerID AND loneman
                              LOOP
                        ENDCASE
                        m.cownerid = jcOwnerID
                        jnworkint  = m.nworkint
                        IF llcatdesc AND NOT EMPTY(m.cdescrip)
                           *
                           * Report category descript instead of name
                           *
                           m.ccategory = m.cdescrip
                        ENDIF

                        m.cpayee      = cpayee
                        m.namount   = namount
                        m.cvendorid   = cvendorid
                        m.nworkint   = m.nacpint
                        m.ninvamt   = swround((m.namount * (m.nacpint / 100)), 2)
                        lnWellTotal   = lnWellTotal + m.ninvamt
                        m.cperiod   = tcperiod
                        m.cyear      = tcyear

                        *  Make sure we have a good key for the invoice detail table
                        m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        SET DELETED OFF
                        SWSELECT('invdet', .T.)
                        SET ORDER TO cidInvD
                        IF SEEK(m.cidInvD)
                           GO BOTT
                           ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                           m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                           IF invdet.cidInvD >= m.ccountervalue
                              THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                              THIS.oregistry.updatecounter(ocounter)
                           ENDIF
                           THIS.oregistry.unlockcounter(ocounter)
                           m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        ENDIF
                        SET DELETED ON
                        m.cItemId    = m.cCatCode
                        IF NOT lljibnotes
                           IF llcatdesc
                              m.cItemDesc = m.cdescrip
                           ELSE
                              m.cItemDesc  = m.ccategory
                           ENDIF
                        ELSE
                           IF NOT EMPTY(m.cmemo)
                              m.cItemDesc = m.cmemo
                           ELSE
                              m.cItemDesc = m.ccategory
                           ENDIF
                        ENDIF
                        IF FILE('datafiles\jibref.cfg')
                           m.cworkorder = m.crefid
                        ELSE
                           m.cworkorder = ''
                        ENDIF
                        m.nPrice       = m.namount
                        m.nInterest    = m.nworkint
                        m.nQuantity    = 1
                        m.nExtension = m.ninvamt
                        m.nDiscPct    = 0
                        m.nDiscount    = 0
                        m.cUnitNo    = m.cWellID
                        m.cdeptno    = ' '
                        m.cTaxable    = 'E'
                        m.cPriceCode = '1'
                        m.cMeasure    = ' '
                        m.lDeleted    = .F.
                        m.cAcctNo    = lcexpclear
                        SWSELECT('vendor')
                        LOCATE FOR cvendorid = m.cvendorid
                        IF FOUND()
                           m.cpayee = cvendname
                        ENDIF
                        IF m.nExtension # 0
                           INSERT INTO jibtempd FROM MEMVAR
                        ENDIF
                        STORE 0 TO m.ninvamt, m.namount
                        STORE ' ' TO m.cpayee, m.ccategory, m.cdescript, m.cmiscmemo
                        SELECT tempexp
                        m.nacpint  = jnclassa
                        m.nworkint = jnworkint
                     ENDIF

                     IF m.ntotaleB # 0 AND m.cexpclass = 'B'
                        IF llexpsum
                           SELECT exptemp
                        ELSE
                           SELECT tempexp
                        ENDIF
                        m.cbatch = lcBatch

                        *  Store original interests so we can change for one-man-items.  pws 3/11/97
                        jnclassb  = m.nbcpint
                        DO CASE
                           CASE m.cownerid = jcOwnerID AND NOT m.loneman
                              REPLACE loneman WITH .T.
                              m.nintclassb = 100
                           CASE m.cownerid = ' '
                              * Don't do anything if the cOwnerID is blank
                           CASE m.cownerid # jcOwnerID
                              m.cownerid = jcOwnerID
                              LOOP
                           CASE m.cownerid = jcOwnerID AND loneman
                              LOOP
                        ENDCASE
                        m.cownerid = jcOwnerID
                        jnworkint  = m.nworkint

                        IF llcatdesc AND NOT EMPTY(m.cdescrip)
                           *
                           * Report category descript instead of name
                           *
                           m.ccategory = m.cdescrip
                        ENDIF

                        m.cpayee      = cpayee
                        m.namount   = namount
                        m.cvendorid   = cvendorid
                        m.nworkint   = m.nbcpint
                        m.ninvamt   = swround((m.namount * (m.nbcpint / 100)), 2)
                        lnWellTotal   = lnWellTotal + m.ninvamt
                        m.cperiod   = tcperiod
                        m.cyear      = tcyear

                        *  Make sure we have a good key for the invoice detail table
                        m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        SET DELETED OFF
                        SWSELECT('invdet', .T.)
                        SET ORDER TO cidInvD
                        IF SEEK(m.cidInvD)
                           GO BOTT
                           ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                           m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                           IF invdet.cidInvD >= m.ccountervalue
                              THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                              THIS.oregistry.updatecounter(ocounter)
                           ENDIF
                           THIS.oregistry.unlockcounter(ocounter)
                           m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        ENDIF
                        SET DELETED ON

                        m.cItemId    = m.cCatCode
                        IF NOT lljibnotes
                           IF llcatdesc
                              m.cItemDesc = m.cdescrip
                           ELSE
                              m.cItemDesc  = m.ccategory
                           ENDIF
                        ELSE
                           IF NOT EMPTY(m.cmemo)
                              m.cItemDesc = m.cmemo
                           ELSE
                              m.cItemDesc = m.ccategory
                           ENDIF
                        ENDIF
                        IF FILE('datafiles\jibref.cfg')
                           m.cworkorder = m.crefid
                        ELSE
                           m.cworkorder = ''
                        ENDIF
                        m.nPrice       = m.namount
                        m.nInterest    = m.nworkint
                        m.nQuantity    = 1
                        m.nExtension = m.ninvamt
                        m.nDiscPct    = 0
                        m.nDiscount    = 0
                        m.cUnitNo    = m.cWellID
                        m.cdeptno    = ' '
                        m.cTaxable    = 'E'
                        m.cPriceCode = '1'
                        m.cMeasure    = ' '
                        m.lDeleted    = .F.
                        m.cAcctNo    = lcexpclear
                        SWSELECT('vendor')
                        LOCATE FOR cvendorid = m.cvendorid
                        IF FOUND()
                           m.cpayee = cvendname
                        ENDIF
                        IF m.nExtension # 0
                           INSERT INTO jibtempd FROM MEMVAR
                        ENDIF
                        STORE 0 TO m.ninvamt, m.namount
                        STORE ' ' TO m.cpayee, m.ccategory, m.cdescript, m.cmiscmemo
                        SELECT tempexp
                        m.nbcpint  = jnclassb
                        m.nworkint = jnworkint
                     ENDIF

                     IF m.nplugexp # 0 AND m.cexpclass = 'P' AND m.goApp.lPluggingModule
                        IF llexpsum
                           SELECT exptemp
                        ELSE
                           SELECT tempexp
                        ENDIF
                        m.cbatch = lcBatch

                        *  Store original interests so we can change for one-man-items.
                        jnPlugPct = m.nPlugpct
                        DO CASE
                           CASE m.cownerid = jcOwnerID AND NOT m.loneman
                              REPLACE loneman WITH .T.
                              m.nPlugpct = 100
                           CASE m.cownerid = ' '
                              * Don't do anything if the cOwnerID is blank
                           CASE m.cownerid # jcOwnerID
                              m.cownerid = jcOwnerID
                              LOOP
                           CASE m.cownerid = jcOwnerID AND loneman
                              LOOP
                        ENDCASE
                        m.cownerid = jcOwnerID
                        jnworkint  = m.nworkint

                        IF llcatdesc AND NOT EMPTY(m.cdescrip)
                           *
                           * Report category descript instead of name
                           *
                           m.ccategory = m.cdescrip
                        ENDIF

                        m.cpayee      = cpayee
                        m.namount   = namount
                        m.cvendorid   = cvendorid
                        m.nworkint   = m.nbcpint
                        m.ninvamt   = swround((m.namount * (m.nPlugpct / 100)), 2)
                        lnWellTotal   = lnWellTotal + m.ninvamt
                        m.cperiod   = tcperiod
                        m.cyear      = tcyear

                        *  Make sure we have a good key for the invoice detail table
                        m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        SET DELETED OFF
                        SWSELECT('invdet', .T.)
                        SET ORDER TO cidInvD
                        IF SEEK(m.cidInvD)
                           GO BOTT
                           ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                           m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                           IF invdet.cidInvD >= m.ccountervalue
                              THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                              THIS.oregistry.updatecounter(ocounter)
                           ENDIF
                           THIS.oregistry.unlockcounter(ocounter)
                           m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                        ENDIF
                        SET DELETED ON

                        m.cItemId    = m.cCatCode
                        IF NOT lljibnotes
                           IF llcatdesc
                              m.cItemDesc = m.cdescrip
                           ELSE
                              m.cItemDesc  = m.ccategory
                           ENDIF
                        ELSE
                           IF NOT EMPTY(m.cmemo)
                              m.cItemDesc = m.cmemo
                           ELSE
                              m.cItemDesc = m.ccategory
                           ENDIF
                        ENDIF
                        IF FILE('datafiles\jibref.cfg')
                           m.cworkorder = m.crefid
                        ELSE
                           m.cworkorder = ''
                        ENDIF
                        m.nPrice       = m.namount
                        m.nInterest    = m.nworkint
                        m.nQuantity    = 1
                        m.nExtension = m.ninvamt
                        m.nDiscPct    = 0
                        m.nDiscount    = 0
                        m.cUnitNo    = m.cWellID
                        m.cdeptno    = ' '
                        m.cTaxable    = 'E'
                        m.cPriceCode = '1'
                        m.cMeasure    = ' '
                        m.lDeleted    = .F.
                        m.cAcctNo    = lcexpclear
                        SWSELECT('vendor')
                        LOCATE FOR cvendorid = m.cvendorid
                        IF FOUND()
                           m.cpayee = cvendname
                        ENDIF
                        IF m.nExtension # 0
                           INSERT INTO jibtempd FROM MEMVAR
                        ENDIF
                        STORE 0 TO m.ninvamt, m.namount
                        STORE ' ' TO m.cpayee, m.ccategory, m.cdescript, m.cmiscmemo
                        SELECT tempexp
                        m.nPlugpct = jnPlugPct
                        m.nworkint = jnworkint
                     ENDIF
                  ENDSCAN && tempexp
               ENDSCAN && jibowner

               *  Adjust for rounding if needed
               SELE roundtmp
               SCAN FOR cdmbatch == THIS.cdmbatch AND cownerid == jcOwnerID AND cWellID == m.cWellID AND NOT lUSED
                  m.cWellID   = roundtmp.cWellID
                  m.cexpclass   = '0'
                  m.cdescrip   = 'Rounding'
                  m.cTaxCode   = 'OE'
                  m.cownerid   = jcOwnerID
                  m.crptgroup   = 'D'
                  m.cmiscmemo   = ''
                  m.dexpdate   = THIS.dacctdate

                  *  Locate an existing entry in jibtempd for this owner, and get a valid year/period off of that
                  SELECT jibtempd
                  LOCATE FOR cbatch = lcBatch AND NOT 'ROUND' $ UPPER(cItemDesc)
                  IF FOUND()
                     m.cProdPrd   = cProdPrd
                     m.cProdYear   = cProdYear
                  ELSE
                     m.cProdPrd   = tcperiod
                     m.cProdYear   = tcyear
                  ENDIF

                  m.cbatch    = lcBatch
                  m.ninvamt = swround((roundtmp.nexpense + roundtmp.ntotale1 + roundtmp.ntotale2 + roundtmp.ntotale3 + roundtmp.ntotale4 + roundtmp.ntotale5 + roundtmp.ntotaleA + roundtmp.ntotaleB), 2)

                  *  Make sure we have a good key for the invoice detail table
                  m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                  SET DELETED OFF
                  SWSELECT('invdet', .T.)
                  SET ORDER TO cidInvD
                  IF SEEK(m.cidInvD)
                     GO BOTT
                     ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
                     m.ccountervalue = THIS.oregistry.getcounter(ocounter)
                     IF invdet.cidInvD >= m.ccountervalue
                        THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
                        THIS.oregistry.updatecounter(ocounter)
                     ENDIF
                     THIS.oregistry.unlockcounter(ocounter)
                     m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
                  ENDIF
                  SET DELETED ON

                  m.cItemId    = 'ROUND'
                  m.cItemDesc    = 'Rounding'
                  m.nPrice       = m.ninvamt
                  m.nInterest    = 100
                  m.nQuantity    = 1
                  m.nExtension = m.ninvamt
                  m.nDiscPct    = 0
                  m.nDiscount    = 0
                  m.cUnitNo    = m.cWellID
                  m.cdeptno    = ' '
                  m.cTaxable    = 'E'
                  m.cPriceCode = '1'
                  m.cMeasure    = ' '
                  m.lDeleted    = .F.
                  m.cAcctNo    = lcexpclear
                  m.cpayee       = ''
                  INSERT INTO jibtempd FROM MEMVAR
                  lnWellTotal = lnWellTotal + m.ninvamt
               ENDSCAN && roundtmp

               SELECT jibtempd
               LOCATE FOR cbatch == lcBatch
               IF FOUND()
                  THIS.prepay_process(jcOwnerID, m.cWellID, lnWellTotal, lcBatch)
               ENDIF

            ENDSCAN && ownwell


         ENDSCAN && invjtot

         THIS.oProgress.CLOSEProgress()
         THIS.oProgress = .NULL.

      ENDIF


      **************************************************************
      *  Update the jib invoice number
      **************************************************************
      IF tlClose
         SWSELECT('aropt', .T.)
         GO TOP
         REPLACE njibinv WITH lnjibinv
         TABLEUPDATE(.T.)
      ENDIF

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'JIBInv', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('JIBInv', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn

   ENDPROC


   *-- Processes the closing.
   **********************************************************
   PROCEDURE closeproc
   **********************************************************
   LOCAL oqb, llReturn, loError

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      IF m.goApp.lCanceled
         llReturn = .F.
         IF NOT m.goApp.CancelMsg()
            THIS.lCanceled = .T.
            EXIT
         ENDIF
      ENDIF

      *  Mark the JIB period as being closed
      m.cidsysctl   = THIS.oregistry.IncrementCounter('%Shared.Counters.Sysctl')
      m.cdmbatch   = THIS.cdmbatch
      SWSELECT('sysctl', .T.)
      SET ORDER TO cidsysctl
      DO WHILE SEEK(m.cidsysctl)
         m.cidsysctl   = THIS.oregistry.IncrementCounter('%Shared.Counters.Sysctl')
      ENDDO
      m.cperiod      = THIS.cperiod
      m.cyear         = THIS.cyear
      m.crunyear      = THIS.crunyear
      m.dacctdate      = THIS.dacctdate
      m.dpostdate      = THIS.dpostdate
      m.dexpdate      = THIS.dexpdate
      m.cgroup         = THIS.cgroup
      m.dDateClose   = DATE()
      m.cTimeClose   = TIME()
      m.cTypeClose   = 'J'
      m.lRelMin      = .F.
      m.lCloseYear   = .F.
      m.lDisbMan      = .T.
      m.lPosted      = .T.
      m.nrunno         = THIS.nrunno
      m.lCompanyPost   = THIS.companypost
      m.cversion      = STRTRAN(m.goApp.cfileversion, '.', '')
      INSERT INTO sysctl FROM MEMVAR

      THIS.csysctlkey = m.cidsysctl

      *
      *  Check for non-net wells and post runno into revenue runno
      *
      llReturn = THIS.nonnetcheck()
      IF NOT llReturn
         EXIT
      ENDIF

      *
      *  Add the owner history and well history records.
      *
      llReturn = THIS.addhist()
      IF NOT llReturn
         EXIT
      ENDIF

      *
      *  Create the journal entries
      *
      * Check to see if this is the QB version
      IF m.goApp.lqbversion
         m.goApp.oqb.dacctdate   = THIS.dacctdate
         m.goApp.oqb.dpostdate   = THIS.dpostdate
         m.goApp.oqb.dexpdate      = THIS.dexpdate
         m.goApp.oqb.companypost   = THIS.companypost
         m.goApp.oqb.crunyear      = THIS.crunyear
         m.goApp.oqb.nrunno      = THIS.nrunno
         m.goApp.oqb.cdmbatch      = THIS.cdmbatch
         m.goApp.oqb.csysctlkey   = THIS.csysctlkey
         m.goApp.oqb.cyear         = THIS.cyear
         m.goApp.oqb.cperiod      = THIS.cperiod
         m.goApp.oqb.cgroup      = THIS.cgroup
         llReturn                  = m.goApp.oqb.QBPostJIB()
         IF NOT llReturn
            EXIT
         ENDIF

         SWSELECT('sysctl', .T.)
         LOCATE FOR cidsysctl == THIS.csysctlkey
         IF FOUND()
            REPLACE lPosted WITH .T.
         ENDIF
         *  Add the invoices to the invhdr and invdet files
         llReturn = THIS.addinvoice()
         IF NOT llReturn
            EXIT
         ENDIF
      ELSE
         llReturn = THIS.postjourn()
         IF NOT llReturn
            EXIT
         ENDIF
      ENDIF

      llReturn = THIS.PluggingFund()

      IF NOT llReturn
         EXIT
      ENDIF

      WAIT WIND NOWAIT 'Saving Closing Entries.....'
      llOK = .T.
      BEGIN TRANSACTION
      SELE disbhist
      llOK = TABLEUPDATE(.T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Disbhist'
         llReturn = .F.
         EXIT
      ENDIF
      SELE ownpcts
      llOK = TABLEUPDATE(.T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Ownpcts'
         llReturn = .F.
         EXIT
      ENDIF
      IF m.goApp.lAMVersion
         SELE glmaster
         llOK = TABLEUPDATE(.T.)
         IF NOT llOK
            AERROR(laError)
            ROLLBACK
            DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Glmaster'
            llReturn = .F.
            EXIT
         ENDIF
      ENDIF
      SELE wellhist
      llOK = TABLEUPDATE(.T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Wellhist'
         llReturn = .F.
         EXIT
      ENDIF
      SELE sysctl
      llOK = TABLEUPDATE(.T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Sysctl'
         llReturn = .F.
         EXIT
      ENDIF
      SELE expense
      llOK = TABLEUPDATE(.T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Expense'
         llReturn = .F.
         EXIT
      ENDIF
      SELE invhdr
      llOK = TABLEUPDATE(.T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Invhdr'
         llReturn = .F.
         EXIT
      ENDIF
      SELE invdet
      llOK = TABLEUPDATE(.T., .T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Invdet'
         llReturn = .F.
         EXIT
      ENDIF
      IF USED('checks')
         SELE checks
         llOK = TABLEUPDATE(.T.)
         IF NOT llOK
            AERROR(laError)
            ROLLBACK
            DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Checks'
            llReturn = .F.
            EXIT
         ENDIF
      ENDIF
      SELE roundtmp
      llOK = TABLEUPDATE(.T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Roundtmp'
         llReturn = .F.
         EXIT
      ENDIF
      SELE prepayd
      llOK = TABLEUPDATE(.T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Prepayd'
         llReturn = .F.
         EXIT
      ENDIF
      SELE plugwellbal
      llOK = TABLEUPDATE(.T.)
      IF NOT llOK
         AERROR(laError)
         ROLLBACK
         DO errorlog WITH 'Closeproc', 999, 'JIBPROC', 999, 'TableUpdate Failed: Plugwellbal'
         llReturn = .F.
         EXIT
      ENDIF
      END TRANSACTION
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'CloseProc', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('CloseProc', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC


   *-- Adds the invoices to the invhdr and invdet files.
   **********************************************************
   PROCEDURE addinvoice
   **********************************************************
   LOCAL m.cdmbatch, lcDMBatch, llReturn, loError
   **************************************************************
   *  Add to the invhdr and invdet files if the period is being closed.
   **************************************************************

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      lcDMBatch = THIS.cdmbatch

      IF m.goApp.lCanceled
         llReturn = .F.
         IF NOT m.goApp.CancelMsg()
            THIS.lCanceled = .T.
            EXIT
         ENDIF
      ENDIF

      *  Add the invoice headers
      SELECT jibtemph
      SCAN
         SCATTER MEMVAR
         m.cdmbatch = lcDMBatch
         m.lPrinted = .T.   && Mark JIB invoices as printed since the normail invoice print doesn't print them.
         INSERT INTO invhdr FROM MEMVAR
      ENDSCAN

      * Add the invoice detail
      SELECT jibtempd
      SCAN
         SCATTER MEMVAR
         INSERT INTO invdet FROM MEMVAR
      ENDSCAN

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'AddInvoice', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('AddInvoice', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC


   *-- Creates the journal entries for the invoices.
   **********************************************************
   PROCEDURE postjourn
   **********************************************************
   LOCAL lcBatch, lcaracct, lctaxacct, lccogsacct, llReturn, lcselect, lnrecno
   LOCAL lnlastcost, llinvitem, llnopostdm, llRoundClr, llRoundIt, llround
   LOCAL llReturn, loError, lcDMExp, lcAPAcct

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      IF m.goApp.lCanceled
         llReturn = .F.
         IF NOT m.goApp.CancelMsg()
            THIS.lCanceled = .T.
            EXIT
         ENDIF
      ENDIF

      tcperiod   = THIS.cperiod
      tcyear   = THIS.cyear
      tcGroup   = THIS.cgroup
      tnRunNo   = THIS.nrunno

      lcselect = SELECT()

      STORE .F. TO llround, llRoundIt, llRoundClr
      lcDMExp = ''

      *
      *  Plug the DM batch number into glmaint so that each
      *  batch created can be traced to this closing
      *
      THIS.ogl.dmbatch = THIS.cdmbatch
      THIS.ogl.csource = 'DM'

      * Look to see if only the company's share is to be posted with the post date.
      IF THIS.companypost = .T.
         THIS.ogl.dgldate  = THIS.dacctdate
      ELSE
         THIS.ogl.dgldate  = THIS.dpostdate
      ENDIF
      
      SWSELECT('options')
      llexpsum   = lexpsum
      lcdeptno   = cdeptno

      IF m.goApp.lqbversion
         lcDMExp   = cQBFixedAcct
         SWSELECT('glopt')
         THIS.cexpclear   = cQBexpclear
         llnopostdm      = ldmnopost
         lcSuspense      = cQBSuspense
         SWSELECT('apopt')
         lcapacct   = cQBapacct
      ELSE
         lcDMExp   = cFixedAcct
         SWSELECT('glopt')
         THIS.cexpclear   = cexpclear
         llnopostdm      = ldmnopost
         lcSuspense      = cSuspense
         SWSELECT('apopt')
         lcapacct   = capacct
      ENDIF

      IF EMPTY(lcDMExp)
         lcDMExp = lcapacct
      ENDIF

      SWSELECT('wells')
      SET ORDER TO cWellID
      lnowner = 0
      *
      *  Get the owners to be posted.
      *
      SELECT cownerid, cownname FROM investor WHERE lIntegGL = .T. INTO ARRAY laowns ORDER BY cownerid
      lnowns    = _TALLY
      lcownerid = ''

      IF NOT llnopostdm AND lnowns > 0
         WAIT WIND NOWAIT 'Creating Cash Journal Entries For Owner Expenses....'
         lnamount = 0
         SWSELECT('disbhist', .T.)
         lnX = AFIELDS(latempx)
         SWSELECT('ownpcts', .T.)
         lny = AFIELDS(latempy)
         DIMENSION laTemp[lnx + lny - 1, 18]
         FOR x = 1 TO lnX
            FOR Y = 1 TO 18
               laTemp[x, y] = latempx[x, y]
            ENDFOR
         ENDFOR
         FOR x = 1 TO lny - 1
            FOR Y = 1 TO 18
               laTemp[x + lnx, y] = latempy[x + 1, y]
            ENDFOR
         ENDFOR
         FOR x = 1 TO lnX + lny - 1
            laTemp[X, 7]  = ''
            laTemp[X, 8]  = ''
            laTemp[X, 9]  = ''
            laTemp[X, 10] = ''
            laTemp[X, 11] = ''
            laTemp[X, 12] = ''
            laTemp[X, 13] = ''
            laTemp[X, 14] = ''
            laTemp[X, 15] = ''
            laTemp[X, 18] = ''
         ENDFOR
         CREATE CURSOR tempowner FROM ARRAY laTemp

         *
         *  Prepare the work expense cursor with just the expenses we need to process this run
         *
         Make_Copy('expense', 'workexp')
         Make_Copy('expense', 'workexp1')
         SELE expense
         SCAN FOR (nRunNoJIB = THIS.nrunno AND cRunYearJIB = THIS.crunyear) AND NOT INLIST(cCatCode, 'MKTG', 'COMP', 'GATH')
            SCATTER MEMVAR
            SELE expcat
            LOCATE FOR cCatCode == m.cCatCode
            INSERT INTO workexp1 FROM MEMVAR
         ENDSCAN

         IF llexpsum
            SELECT  cWellID, ccateg, cyear, cperiod, crefid, dexpdate, SUM(namount) AS namount, ;
               cpayee, cmemo, cvendorid, cpaidbyck, cexpclass, nsaltwater, cprdpaid, ;
               lfixed, laptran, cbatch, cownerid, loneman, cCatCode, nRunNoJIB, cRunYearJIB ;
               FROM workexp1 ;
               INTO CURSOR exptemp1 ;
               ORDER BY cWellID, cCatCode, cyear, cperiod, cownerid, cexpclass ;
               GROUP BY cWellID, cCatCode, cyear, cperiod, cownerid, cexpclass
            SELE workexp
            APPEND FROM DBF('exptemp1')
         ELSE
            SELE workexp
            APPEND FROM DBF('workexp1')
         ENDIF

         SELE workexp
         INDEX ON cyear + cperiod TAG yearprd
         INDEX ON cWellID TAG cWellID

         * Reset used flag in roundtmp
         SELE roundtmp
         REPL lUSED WITH .F. FOR cdmbatch == THIS.cdmbatch

         FOR lnX = 1 TO lnowns
            m.cownerid       = laowns[lnX, 1]
            THIS.ogl.cbatch = THIS.oregistry.IncrementCounter('%Shared.Counters.Batch')
            STORE 0 TO lnoilrev, lngasrev, lntrprev, lnmi1rev, lnmi2rev, lndebits, lncredits, ;
               lnmin, lndeficit, lnoiltax, lngastax
            SELE disbhist
            SCAN FOR cownerid = m.cownerid ;
                  AND crunyear = tcyear ;
                  AND nrunno   = tnRunNo ;
                  AND cgroup = tcGroup ;
                  AND cRecType = 'J'
               SCATTER MEMVAR
               SWSELECT('ownpcts', .T.)
               SET ORDER TO ciddisb
               IF SEEK(m.ciddisb)
                  SCATTER MEMVAR
               ENDIF
               INSERT INTO tempowner FROM MEMVAR
            ENDSCAN

            IF m.goApp.lCanceled
               llReturn = .F.
               IF NOT m.goApp.CancelMsg()
                  THIS.lCanceled = .T.
                  EXIT
               ENDIF
            ENDIF

            SELE tempowner
            lnMax     = RECC()
            lnCount = 1
            IF lnMax > 0
               IF NOT THIS.lquiet
                  THIS.oProgress = THIS.omessage.progressbarex('Posting owner totals to expense accounts...', ;
                     laowns[lnX, 2])
                  THIS.oProgress.SetProgressRange(0, lnMax)
               ENDIF
               llround = .F.
               STORE .F. TO llRoundIt0, llRoundIt1, llRoundIt2, llRoundIt3, llRoundIt4, llRoundIt5, llRoundItA, llRoundItB
               SELECT tempowner
               SCAN FOR cownerid = m.cownerid
                  SCATTER MEMVAR

                  SWSELECT('roundtmp', .T.)
                  LOCATE FOR cownerid = m.cownerid AND cWellID = m.cWellID AND cdmbatch == THIS.cdmbatch AND NOT lUSED
                  IF FOUND()
                     REPL lUSED WITH .T.
                     m.nexptotal = nexpense + ntotale1 + ntotale2 + ntotale3 + ntotale4 + ntotale5 + ntotaleA + ntotaleB

                     SWSELECT('expcat')
                     SET ORDER TO cCatCode
                     IF SEEK('ROUN')
                        m.cdracct = cdraccto
                     ELSE
                        m.cdracct = lcSuspense
                     ENDIF

                     THIS.ogl.namount = m.nexptotal
                     THIS.ogl.cdesc     = 'Rounding Amount'
                     THIS.ogl.cAcctNo = m.cdracct
                     THIS.ogl.cUnitNo = m.cWellID
                     THIS.ogl.cID     = laowns[lnX, 1]
                     THIS.ogl.cdeptno = lcdeptno
                     THIS.ogl.updatebatch()
                  ENDIF


                  THIS.ogl.cReference = 'Post: ' + m.hyear + '/' + m.hperiod
                  lljib                 = lJIB
                  IF NOT THIS.lquiet
                     THIS.oProgress.UpdateProgress(lnCount)
                     lnCount = lnCount + 1
                  ENDIF
                  lcname    = laowns[lnX, 2]

                  SWSELECT('wells')
                  IF SEEK(m.cWellID)
                     SCATTER FIELDS LIKE lsev* MEMVAR
                  ENDIF

                  *
                  *  Process default class expenses
                  *
                  IF m.nexpense + m.ntotale1 + m.ntotale2 + m.ntotale3 + m.ntotale4 + m.ntotale5 + m.ntotaleB + m.ntotaleA # 0
                     lntotal = 0
                     SELECT workexp
                     SCAN FOR nRunNoJIB    = tnRunNo ;
                           AND cRunYearJIB  = tcyear ;
                           AND cWellID      = m.cWellID   ;
                           AND cexpclass    = '0' ;
                           AND cyear + cperiod = m.hyear + m.hperiod

                        m.ccateg      = ccateg
                        m.namount   = namount
                        lcownerid   = cownerid
                        m.cexpclass   = cexpclass
                        m.cCatCode   = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cdracct = cdraccto
                        ELSE
                           m.cdracct = lcSuspense
                        ENDIF

                        *
                        *  If either of the account numbers are blank, replace them
                        *  with a valid account number
                        *
                        IF EMPTY(m.cdracct)
                           m.cdracct = lcSuspense
                        ENDIF

                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cownerid
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nworkint / 100), 2)
                        ENDIF

                        *!*                         IF llround AND NOT llroundit0
                        *!*                            m.namount = m.namount + roundtmp.nexpense
                        *!*                            llRoundIt0 = .T.
                        *!*                         ENDIF

                        THIS.ogl.namount = m.namount
                        THIS.ogl.cdesc     = m.ccateg
                        THIS.ogl.cAcctNo = m.cdracct
                        THIS.ogl.cUnitNo = m.cWellID
                        THIS.ogl.cID     = laowns[lnX, 1]
                        THIS.ogl.cdeptno = lcdeptno
                        THIS.ogl.updatebatch()

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     THIS.ogl.namount = m.nexpense * -1
                     THIS.ogl.cdesc     = 'Operating Expenses'
                     THIS.ogl.cAcctNo = THIS.cexpclear
                     THIS.ogl.cUnitNo = m.cWellID
                     THIS.ogl.cID     = laowns[lnX, 1]
                     THIS.ogl.cdeptno = lcdeptno
                     THIS.ogl.updatebatch()


                     *
                     *  Process class 1 expenses
                     *
                     IF m.ntotale1 # 0
                        lntotal = 0
                        SELECT workexp
                        SCAN FOR nRunNoJIB    = tnRunNo ;
                              AND cRunYearJIB  = tcyear ;
                              AND cWellID      = m.cWellID   ;
                              AND cexpclass    = '1' ;
                              AND cyear + cperiod = m.hyear + m.hperiod

                           m.ccateg     = ccateg
                           m.namount  = namount
                           lcownerid  = cownerid
                           m.cCatCode = cCatCode

                           *
                           *  Get the account numbers to post this expense to
                           *
                           SWSELECT('expcat')
                           SET ORDER TO cCatCode
                           IF SEEK(m.cCatCode)
                              m.cdracct = cdraccto
                           ELSE
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  If either of the account numbers are blank, replace them
                           *  with a valid account number
                           *
                           IF EMPTY(m.cdracct)
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  Post Expenses
                           *
                           IF NOT EMPTY(lcownerid)           && Check for one-man items
                              IF lcownerid # m.cownerid
                                 LOOP
                              ENDIF
                           ELSE
                              m.namount = swround(m.namount * (m.nintclass1 / 100), 2)
                           ENDIF

                           *!*                         IF llround AND NOT llroundit1
                           *!*                            m.namount = m.namount + roundtmp.ntotale1
                           *!*                            llroundit1 = .T.
                           *!*                         ENDIF

                           THIS.ogl.namount = m.namount
                           THIS.ogl.cdesc     = m.ccateg
                           THIS.ogl.cAcctNo = m.cdracct
                           THIS.ogl.cUnitNo = m.cWellID
                           THIS.ogl.cID     = laowns[lnX, 1]
                           THIS.ogl.cdeptno = lcdeptno
                           THIS.ogl.updatebatch()

                        ENDSCAN

                        *
                        *  Post expense clearing entry
                        *
                        THIS.ogl.namount = m.ntotale1 * -1
                        THIS.ogl.cdesc     = 'Class 1 Expenses'
                        THIS.ogl.cAcctNo = THIS.cexpclear
                        THIS.ogl.cUnitNo = m.cWellID
                        THIS.ogl.cID     = laowns[lnX, 1]
                        THIS.ogl.cdeptno = lcdeptno
                        THIS.ogl.updatebatch()

                     ENDIF
                     *
                     *  Process class 2 expenses
                     *
                     IF m.ntotale2 # 0
                        lntotal = 0
                        SELECT workexp
                        SCAN FOR nRunNoJIB    = tnRunNo ;
                              AND cRunYearJIB  = tcyear ;
                              AND cWellID      = m.cWellID   ;
                              AND cexpclass    = '2' ;
                              AND cyear + cperiod = m.hyear + m.hperiod

                           m.ccateg     = ccateg
                           m.namount  = namount
                           lcownerid  = cownerid
                           m.cCatCode = cCatCode

                           *
                           *  Get the account numbers to post this expense to
                           *
                           SWSELECT('expcat')
                           SET ORDER TO cCatCode
                           IF SEEK(m.cCatCode)
                              m.cdracct = cdraccto
                           ELSE
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  If either of the account numbers are blank, replace them
                           *  with a valid account number
                           *
                           IF EMPTY(m.cdracct)
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  Post Expenses
                           *
                           IF NOT EMPTY(lcownerid)           && Check for one-man items
                              IF lcownerid # m.cownerid
                                 LOOP
                              ENDIF
                           ELSE
                              m.namount = swround(m.namount * (m.nintclass2 / 100), 2)
                           ENDIF

                           *!*                         IF llround AND NOT llroundit2
                           *!*                            m.namount = m.namount + roundtmp.ntotale2
                           *!*                            llroundit2 = .T.
                           *!*                         ENDIF

                           THIS.ogl.namount = m.namount
                           THIS.ogl.cdesc     = m.ccateg
                           THIS.ogl.cAcctNo = m.cdracct
                           THIS.ogl.cUnitNo = m.cWellID
                           THIS.ogl.cID     = laowns[lnX, 1]
                           THIS.ogl.cdeptno = lcdeptno
                           THIS.ogl.updatebatch()

                        ENDSCAN

                        *
                        *  Post expense clearing entry
                        *
                        THIS.ogl.namount = m.ntotale2 * -1
                        THIS.ogl.cdesc     = 'Class 2 Expenses'
                        THIS.ogl.cAcctNo = THIS.cexpclear
                        THIS.ogl.cUnitNo = m.cWellID
                        THIS.ogl.cID     = laowns[lnX, 1]
                        THIS.ogl.cdeptno = lcdeptno
                        THIS.ogl.updatebatch()

                     ENDIF
                     *
                     *  Process class 3 expenses
                     *
                     IF m.ntotale3 # 0
                        lntotal = 0
                        SELECT workexp
                        SCAN FOR nRunNoJIB    = tnRunNo ;
                              AND cRunYearJIB  = tcyear ;
                              AND cWellID      = m.cWellID   ;
                              AND cexpclass    = '3' ;
                              AND cyear + cperiod = m.hyear + m.hperiod

                           m.ccateg     = ccateg
                           m.namount  = namount
                           lcownerid  = cownerid
                           m.cCatCode = cCatCode

                           *
                           *  Get the account numbers to post this expense to
                           *
                           SWSELECT('expcat')
                           SET ORDER TO cCatCode
                           IF SEEK(m.cCatCode)
                              m.cdracct = cdraccto
                           ELSE
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  If either of the account numbers are blank, replace them
                           *  with a valid account number
                           *
                           IF EMPTY(m.cdracct)
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  Post Expenses
                           *
                           IF NOT EMPTY(lcownerid)           && Check for one-man items
                              IF lcownerid # m.cownerid
                                 LOOP
                              ENDIF
                           ELSE
                              m.namount = swround(m.namount * (m.nintclass3 / 100), 2)
                           ENDIF

                           *!*                         IF llround AND NOT llroundit3
                           *!*                            m.namount = m.namount + roundtmp.ntotale3
                           *!*                            llroundit3 = .T.
                           *!*                         ENDIF

                           THIS.ogl.namount = m.namount
                           THIS.ogl.cdesc     = m.ccateg
                           THIS.ogl.cAcctNo = m.cdracct
                           THIS.ogl.cUnitNo = m.cWellID
                           THIS.ogl.cID     = laowns[lnX, 1]
                           THIS.ogl.cdeptno = lcdeptno
                           THIS.ogl.updatebatch()

                        ENDSCAN

                        *
                        *  Post expense clearing entry
                        *
                        THIS.ogl.namount = m.ntotale3 * -1
                        THIS.ogl.cdesc     = 'Class 3 Expenses'
                        THIS.ogl.cAcctNo = THIS.cexpclear
                        THIS.ogl.cUnitNo = m.cWellID
                        THIS.ogl.cID     = laowns[lnX, 1]
                        THIS.ogl.cdeptno = lcdeptno
                        THIS.ogl.updatebatch()

                     ENDIF
                     *
                     *  Process class 4 expenses
                     *
                     IF m.ntotale4 # 0
                        lntotal = 0
                        SELECT workexp
                        SCAN FOR nRunNoJIB    = tnRunNo ;
                              AND cRunYearJIB  = tcyear ;
                              AND cWellID      = m.cWellID   ;
                              AND cexpclass    = '4' ;
                              AND cyear + cperiod = m.hyear + m.hperiod

                           m.ccateg     = ccateg
                           m.namount  = namount
                           lcownerid  = cownerid
                           m.cCatCode = cCatCode

                           *
                           *  Get the account numbers to post this expense to
                           *
                           SWSELECT('expcat')
                           SET ORDER TO cCatCode
                           IF SEEK(m.cCatCode)
                              m.cdracct = cdraccto
                           ELSE
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  If either of the account numbers are blank, replace them
                           *  with a valid account number
                           *
                           IF EMPTY(m.cdracct)
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  Post Expenses
                           *
                           IF NOT EMPTY(lcownerid)           && Check for one-man items
                              IF lcownerid # m.cownerid
                                 LOOP
                              ENDIF
                           ELSE
                              m.namount = swround(m.namount * (m.nintclass4 / 100), 2)
                           ENDIF

                           *!*                         IF llround AND NOT llroundit4
                           *!*                            m.namount = m.namount + roundtmp.ntotale4
                           *!*                            llroundit4 = .T.
                           *!*                         ENDIF

                           THIS.ogl.namount = m.namount
                           THIS.ogl.cdesc     = m.ccateg
                           THIS.ogl.cAcctNo = m.cdracct
                           THIS.ogl.cUnitNo = m.cWellID
                           THIS.ogl.cID     = laowns[lnX, 1]
                           THIS.ogl.cdeptno = lcdeptno
                           THIS.ogl.updatebatch()

                        ENDSCAN

                        *
                        *  Post expense clearing entry
                        *
                        THIS.ogl.namount = m.ntotale4 * -1
                        THIS.ogl.cdesc     = 'Class 4 Expenses'
                        THIS.ogl.cAcctNo = THIS.cexpclear
                        THIS.ogl.cUnitNo = m.cWellID
                        THIS.ogl.cID     = laowns[lnX, 1]
                        THIS.ogl.cdeptno = lcdeptno
                        THIS.ogl.updatebatch()

                     ENDIF

                     *
                     *  Process class 5 expenses
                     *
                     IF m.ntotale5 # 0
                        lntotal = 0
                        SELECT workexp
                        SCAN FOR nRunNoJIB    = tnRunNo ;
                              AND cRunYearJIB  = tcyear ;
                              AND cWellID      = m.cWellID   ;
                              AND cexpclass    = '5' ;
                              AND cyear + cperiod = m.hyear + m.hperiod

                           m.ccateg     = ccateg
                           m.namount  = namount
                           lcownerid  = cownerid
                           m.cCatCode = cCatCode

                           *
                           *  Get the account numbers to post this expense to
                           *
                           SWSELECT('expcat')
                           SET ORDER TO cCatCode
                           IF SEEK(m.cCatCode)
                              m.cdracct = cdraccto
                           ELSE
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  If either of the account numbers are blank, replace them
                           *  with a valid account number
                           *
                           IF EMPTY(m.cdracct)
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  Post Expenses
                           *
                           IF NOT EMPTY(lcownerid)           && Check for one-man items
                              IF lcownerid # m.cownerid
                                 LOOP
                              ENDIF
                           ELSE
                              m.namount = swround(m.namount * (m.nintclass5 / 100), 2)
                           ENDIF

                           *!*                         IF llround AND NOT llroundit5
                           *!*                            m.namount = m.namount + roundtmp.ntotale5
                           *!*                            llroundit5 = .T.
                           *!*                         ENDIF

                           THIS.ogl.namount = m.namount
                           THIS.ogl.cdesc     = m.ccateg
                           THIS.ogl.cAcctNo = m.cdracct
                           THIS.ogl.cUnitNo = m.cWellID
                           THIS.ogl.cID     = laowns[lnX, 1]
                           THIS.ogl.cdeptno = lcdeptno
                           THIS.ogl.updatebatch()

                        ENDSCAN

                        *
                        *  Post expense clearing entry
                        *
                        THIS.ogl.namount = m.ntotale5 * -1
                        THIS.ogl.cdesc     = 'Class 5 Expenses'
                        THIS.ogl.cAcctNo = THIS.cexpclear
                        THIS.ogl.cUnitNo = m.cWellID
                        THIS.ogl.cID     = laowns[lnX, 1]
                        THIS.ogl.cdeptno = lcdeptno
                        THIS.ogl.updatebatch()

                     ENDIF

                     *
                     *  Process ACP expenses
                     *
                     IF m.ntotaleA # 0
                        lntotal = 0
                        SELECT workexp
                        SCAN FOR nRunNoJIB    = tnRunNo ;
                              AND cRunYearJIB  = tcyear ;
                              AND cWellID      = m.cWellID   ;
                              AND cexpclass    = 'A' ;
                              AND cyear + cperiod = m.hyear + m.hperiod

                           m.ccateg     = ccateg
                           m.namount  = namount
                           lcownerid  = cownerid
                           m.cCatCode = cCatCode

                           *
                           *  Get the account numbers to post this expense to
                           *
                           SWSELECT('expcat')
                           SET ORDER TO cCatCode
                           IF SEEK(m.cCatCode)
                              m.cdracct = cdraccto
                           ELSE
                              m.cdracct = lcSuspense
                           ENDIF


                           *
                           *  If either of the account numbers are blank, replace them
                           *  with a valid account number
                           *
                           IF EMPTY(m.cdracct)
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  Post Expenses
                           *
                           IF NOT EMPTY(lcownerid)           && Check for one-man items
                              IF lcownerid # m.cownerid
                                 LOOP
                              ENDIF
                           ELSE
                              m.namount = swround(m.namount * (m.nacpint / 100), 2)
                           ENDIF

                           *!*                         IF llround AND NOT llrounditA
                           *!*                            m.namount = m.namount + roundtmp.ntotalea
                           *!*                            llrounditA = .T.
                           *!*                         ENDIF

                           THIS.ogl.namount = m.namount
                           THIS.ogl.cdesc     = m.ccateg
                           THIS.ogl.cAcctNo = m.cdracct
                           THIS.ogl.cUnitNo = m.cWellID
                           THIS.ogl.cID     = laowns[lnX, 1]
                           THIS.ogl.cdeptno = lcdeptno
                           THIS.ogl.updatebatch()

                        ENDSCAN

                        *
                        *  Post expense clearing entry
                        *
                        THIS.ogl.namount = m.ntotaleA * -1
                        THIS.ogl.cdesc     = 'After Casing Expenses'
                        THIS.ogl.cAcctNo = THIS.cexpclear
                        THIS.ogl.cUnitNo = m.cWellID
                        THIS.ogl.cID     = laowns[lnX, 1]
                        THIS.ogl.cdeptno = lcdeptno
                        THIS.ogl.updatebatch()

                     ENDIF

                     *
                     *  Process BCP expenses
                     *
                     IF m.ntotaleB # 0
                        lntotal = 0
                        SELECT workexp
                        SCAN FOR nRunNoJIB    = tnRunNo ;
                              AND cRunYearJIB  = tcyear ;
                              AND cWellID      = m.cWellID   ;
                              AND cexpclass    = 'B' ;
                              AND cyear + cperiod = m.hyear + m.hperiod

                           m.ccateg     = ccateg
                           m.namount  = namount
                           lcownerid  = cownerid
                           m.cCatCode = cCatCode

                           *
                           *  Get the account numbers to post this expense to
                           *
                           SWSELECT('expcat')
                           SET ORDER TO cCatCode
                           IF SEEK(m.cCatCode)
                              m.cdracct = cdraccto
                           ELSE
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  If either of the account numbers are blank, replace them
                           *  with a valid account number
                           *
                           IF EMPTY(m.cdracct)
                              m.cdracct = lcSuspense
                           ENDIF

                           *
                           *  Post Expenses
                           *
                           IF NOT EMPTY(lcownerid)           && Check for one-man items
                              IF lcownerid # m.cownerid
                                 LOOP
                              ENDIF
                           ELSE
                              m.namount = swround(m.namount * (m.nbcpint / 100), 2)
                           ENDIF

                           *!*                         IF llround AND NOT llrounditB
                           *!*                            m.namount = m.namount + roundtmp.ntotaleb
                           *!*                            llrounditB = .T.
                           *!*                         ENDIF

                           THIS.ogl.namount = m.namount
                           THIS.ogl.cdesc     = m.ccateg
                           THIS.ogl.cAcctNo = m.cdracct
                           THIS.ogl.cUnitNo = m.cWellID
                           THIS.ogl.cID     = laowns[lnX, 1]
                           THIS.ogl.cdeptno = lcdeptno
                           THIS.ogl.updatebatch()

                        ENDSCAN

                        *
                        *  Post expense clearing entry
                        *
                        THIS.ogl.namount = m.ntotaleB * -1
                        THIS.ogl.cdesc     = 'Before Casing Expenses'
                        THIS.ogl.cAcctNo = THIS.cexpclear
                        THIS.ogl.cUnitNo = m.cWellID
                        THIS.ogl.cID     = laowns[lnX, 1]
                        THIS.ogl.cdeptno = lcdeptno
                        THIS.ogl.updatebatch()

                     ENDIF

                  ENDIF

                  *
                  *  Process Plugging expenses
                  *
                  IF m.nplugexp # 0 AND m.goApp.lPluggingModule
                     lntotal = 0
                     SELECT workexp
                     SCAN FOR nRunNoJIB    = tnRunNo ;
                           AND cRunYearJIB  = tcyear ;
                           AND cWellID      = m.cWellID   ;
                           AND cexpclass    = 'P' ;
                           AND cyear + cperiod = m.hyear + m.hperiod

                        m.ccateg     = ccateg
                        m.namount  = namount
                        lcownerid  = cownerid
                        m.cCatCode = cCatCode

                        *
                        *  Get the account numbers to post this expense to
                        *
                        SWSELECT('expcat')
                        SET ORDER TO cCatCode
                        IF SEEK(m.cCatCode)
                           m.cdracct = cdraccto
                        ELSE
                           m.cdracct = lcSuspense
                        ENDIF

                        *
                        *  If either of the account numbers are blank, replace them
                        *  with a valid account number
                        *
                        IF EMPTY(m.cdracct)
                           m.cdracct = lcSuspense
                        ENDIF
                        *
                        *  Post Expenses
                        *
                        IF NOT EMPTY(lcownerid)           && Check for one-man items
                           IF lcownerid # m.cownerid
                              LOOP
                           ENDIF
                        ELSE
                           m.namount = swround(m.namount * (m.nbcpint / 100), 2)
                        ENDIF

                        THIS.ogl.namount = m.namount
                        THIS.ogl.cdesc     = m.ccateg
                        THIS.ogl.cAcctNo = m.cdracct
                        THIS.ogl.cUnitNo = m.cWellID
                        THIS.ogl.cID     = laowns[lnX, 1]
                        THIS.ogl.cdeptno = lcdeptno
                        THIS.ogl.updatebatch()

                     ENDSCAN

                     *
                     *  Post expense clearing entry
                     *
                     THIS.ogl.namount = m.ntotaleB * -1
                     THIS.ogl.cdesc     = 'Plugging Expenses'
                     THIS.ogl.cAcctNo = THIS.cexpclear
                     THIS.ogl.cUnitNo = m.cWellID
                     THIS.ogl.cID     = laowns[lnX, 1]
                     THIS.ogl.cdeptno = lcdeptno
                     THIS.ogl.updatebatch()

                  ENDIF
               ENDSCAN

               llReturn = THIS.ogl.chkbalance()

               IF NOT llReturn
                  WAIT WIND NOWAIT 'The owner/operator amounts for well: ' + ALLT(m.cWellID) + ' do not balance... '
               ENDIF

               IF NOT THIS.lquiet
                  THIS.oProgress.CLOSEProgress()
                  DOEVENTS
                  THIS.oProgress = .NULL.
               ENDIF
            ENDIF
         ENDFOR
         WAIT CLEAR
      ENDIF

      ***********************************************************************
      *   Post the Vendor amounts that are designated to be posted.
      ***********************************************************************
      lnvendor = 0
      *
      *  Get the vendors to be posted.
      *

      SELECT cvendorid, cvendname FROM vendor WHERE lIntegGL = .T. INTO ARRAY lavends

      IF NOT llnopostdm AND _TALLY > 0

         lnvends = ALEN(lavends, 1)
         IF lnvends > 0
            THIS.ogl.dmbatch = THIS.cdmbatch
            THIS.ogl.cbatch  = THIS.oregistry.IncrementCounter('%Shared.Counters.Batch')
            FOR lnX = 1 TO lnvends
               lnamount = 0
               THIS.oProgress = THIS.omessage.progressbarex('Posting vendor totals to income accounts...', ;
                  lavends[lnX, 2])
               THIS.ogl.cID = lavends[lnX, 1]
               SWSELECT('expense', .T.)
               COUNT FOR cvendorid = lavends[lnX, 1] AND ;
                  nRunNoJIB = tnRunNo AND ;
                  cRunYearJIB = tcyear AND ;
                  namount # 0 AND NOT laptran TO lnMax
               THIS.oProgress.SetProgressRange(0, lnMax)
               lnCount = 1
               SWSELECT('expense', .T.)
               SCAN FOR cvendorid = lavends[lnX, 1] AND ;
                     nRunNoJIB = tnRunNo AND ;
                     cRunYearJIB = tcyear AND ;
                     namount # 0 AND NOT laptran
                  m.cWellID   = cWellID
                  m.ccateg      = ccateg
                  m.cexpclass   = cexpclass
                  m.namount   = namount
                  m.cUnitNo   = cWellID
                  m.cID         = cvendorid
                  m.cvendname   = lavends[lnX, 2]
                  m.cCatCode   = cCatCode
                  m.cownerid   = cownerid

                  *
                  *  Check to make sure the well is in the right group
                  *
                  SWSELECT('wells')
                  SET ORDER TO cWellID
                  IF SEEK(m.cWellID)
                     IF wells.cgroup # tcGroup
                        LOOP
                     ENDIF
                  ENDIF

                  *
                  *  Get the account numbers to be posted for this expense category
                  *
                  SWSELECT('expcat')
                  SET ORDER TO cCatCode
                  IF SEEK(m.cCatCode)
                     SCATTER MEMVAR
                     m.cdeptno = m.cCatCode
                     IF EMPTY(m.ccracctv)
                        m.ccracctv = lcSuspense
                     ENDIF
                  ENDIF


                  IF m.cCatCode = 'PLUG' AND m.goApp.lPluggingModule
                     *  Get the account numbers to be posted for this expense category
                     SWSELECT('plugwell')
                     LOCATE FOR cWellID == m.cWellID
                     IF FOUND()
                        m.ccracctv = cAcctNo
                     ELSE
                        m.ccracctv = lcSuspense
                     ENDIF
                  ENDIF
                  *
                  *  Net down the amount for dummy and net owners.  The vendor shouldn't
                  *  be paid by the dummy owners, so they shouldn't receive the amount
                  *  the dummy owner would have had to pay
                  *
                  jnamount = m.namount

                  m.namount = swnetexp(jnamount, m.cWellID, .T., m.cexpclass, 'J', .F., m.cownerid, m.cCatCode, m.cDeck)

                  *  If the amount is zero, the expense has not been assigned to
                  *  any JIB owners
                  IF m.namount = 0
                     LOOP
                  ENDIF

                  *
                  * Update the progress counter
                  *
                  THIS.oProgress.UpdateProgress(lnCount)
                  lnCount = lnCount + 1
                  *
                  *  Add amount of this invoice to the total the vendor is to be paid
                  *
                  lnamount = lnamount + m.namount

                  THIS.ogl.cUnitNo = m.cUnitNo
                  THIS.ogl.cdesc     = m.ccateg
                  THIS.ogl.cdeptno = lcdeptno
                  THIS.ogl.cAcctNo = m.ccracctv
                  THIS.ogl.namount = m.namount * -1
                  THIS.ogl.updatebatch()
               ENDSCAN

               IF lnamount # 0
                  THIS.ogl.cAcctNo = lcDMExp
                  THIS.ogl.namount = lnamount
                  THIS.ogl.cdesc     = m.cvendname
                  THIS.ogl.updatebatch()
               ENDIF

               THIS.oProgress.CLOSEProgress()
               DOEVENTS
               THIS.oProgress = .NULL.
            ENDFOR &&* lnX = 1 TO lnVends
         ENDIF

      ENDIF


      ********************************************************************************
      *   Post the A/R Invoices created
      ********************************************************************************
      IF NOT llnopostdm
         IF THIS.companypost = .T.
            THIS.ogl.dpostdate = THIS.dacctdate
         ELSE
            THIS.ogl.dpostdate = THIS.dpostdate
         ENDIF
         SELECT  jibtemph.cCustId, jibtempd.cUnitNo, jibtempd.cAcctNo, SUM(jibtempd.nExtension) AS namount ;
            FROM jibtempd, jibtemph ;
            WHERE jibtempd.cbatch == jibtemph.cbatch ;
            INTO CURSOR tempjib ;
            ORDER BY jibtemph.cCustId, jibtempd.cUnitNo, jibtempd.cAcctNo ;
            GROUP BY jibtemph.cCustId, jibtempd.cUnitNo, jibtempd.cAcctNo

         SELECT jibtemph
         SCAN
            SCATTER MEMVAR
            IF jibtemph.nInvTot = 0
               LOOP
            ENDIF

            lcBatch = jibtemph.cbatch

            *
            *  Delete the G/L journal entries for this invoice
            *
            THIS.ogl.delbatch(lcBatch)

            *
            *  Set the source for this entry
            *
            THIS.ogl.csource = 'DM'
            THIS.ogl.dmbatch = THIS.cdmbatch

            *
            * Get the default A/R account
            *
            IF m.goApp.lqbversion
               SWSELECT('options')
               GO TOP
               lcaracct   = cQBjibacct

               SWSELECT('glopt')
               lcexpclear = cQBexpclear
            ELSE
               SWSELECT('options')
               GO TOP
               lcaracct   = cjibacct

               SWSELECT('glopt')
               lcexpclear = cexpclear
            ENDIF
            *
            *  Create the G/L journal entries for this invoice
            *

            SWSELECT('investor')
            SET ORDER TO cownerid
            IF SEEK(jibtemph.cCustId)
               lcownname = cownname
               IF lIntegGL = .T.
                  LOOP
               ENDIF
            ELSE
               lcownname = 'Unknown'
            ENDIF

            *  A/R entry
            THIS.ogl.cbatch     = lcBatch
            THIS.ogl.cReference = 'Inv: ' + ALLTRIM(jibtemph.cInvNum)
            THIS.ogl.cdesc        = lcownname
            THIS.ogl.cAcctNo     = lcaracct
            THIS.ogl.cID        = jibtemph.cCustId
            THIS.ogl.namount     = jibtemph.nInvTot
            THIS.ogl.mnotes     = ''
            THIS.ogl.cidchec     = ''

            THIS.ogl.updatebatch()

            SELECT tempjib
            SCAN FOR cCustId == m.cCustId
               *  Expense Clearing Entry
               THIS.ogl.cAcctNo = cAcctNo
               THIS.ogl.cUnitNo = cUnitNo
               THIS.ogl.namount = namount * -1     && Assume to be credit
               THIS.ogl.updatebatch()
            ENDSCAN
            *
            *  Check to make sure the batch balances
            *
            llReturn = THIS.ogl.chkbalance()

            IF NOT llReturn
               DO errorlog WITH 'PostJourn', 999, 'JIBPROC', 999, 'Posting for owner: ' + ALLTRIM(m.cCustId) + ' is out of balance'
               EXIT
            ENDIF
         ENDSCAN
      ENDIF

      SELECT (lcselect)

      *
      *  Add the invoices to the invhdr and invdet files
      *
      llReturn = THIS.addinvoice()

      IF VARTYPE(THIS.oProgress) = 'O'
         THIS.oProgress.CLOSEProgress()
         THIS.oProgress = .NULL.
      ENDIF

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'PostJourn', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('PostJourn', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC


   *-- Retrieves the invoices from the invhdr and invdet files.
   **********************************************************
   PROCEDURE getinvoice
   **********************************************************
   LOCAL m.cdmbatch, llReturn, loError
   **************************************************************
   *  Add to the invhdr and invdet files if the period is being closed.
   **************************************************************

   llReturn = .T.


   TRY
      m.cdmbatch = THIS.cdmbatch

      THIS.createtemp()

      *  Add the invoice headers
      SWSELECT('invhdr', .T.)
      SCAN FOR cdmbatch = m.cdmbatch
         SCATTER MEMVAR

         IF m.goApp.lCanceled
            llReturn = .F.
            IF NOT m.goApp.CancelMsg()
               THIS.lCanceled = .T.
               EXIT
            ENDIF
         ENDIF

         m.nrunno     = THIS.nrunno
         m.crunyear = THIS.crunyear
         INSERT INTO jibtemph FROM MEMVAR

         SWSELECT('invdet', .T.)
         SCAN FOR cbatch == m.cbatch
            SCATTER MEMVAR
            INSERT INTO jibtempd FROM MEMVAR
         ENDSCAN
      ENDSCAN

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'GetInvoice', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('GetInvoice', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE vendorchks
   **********************************************************
   LOCAL tcyear, tcperiod, tdCheckDate, tcGroup, tcBatch, tdpostdate
   LOCAL jUnique, lcBatch, lcVendComp, llPostDM, lcDisbAcct, lnAPAmt, lnFixedAmt, lnCompAmt
   LOCAL llReturn, loError

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      STORE 0 TO lnAPAmt, lnFixedAmt, lnCompAmt, lnMax1, lnMax2

      tcyear      = THIS.cyear
      tcperiod      = THIS.cperiod
      tdCheckDate   = THIS.dacctdate
      tcBatch      = THIS.cdmbatch
      tdpostdate   = tdCheckDate
      tcGroup      = THIS.cgroup
      tnRunNo      = THIS.nrunno

      IF m.goApp.lqbversion
         * Get the A/P Account
         SWSELECT('apopt')
         lcapacct   = cQBapacct

         *  Get the Disbursements accounts
         SWSELECT('options')
         GO TOP

         lcDisbAcct   = cQBDisbAcct
         lcVendComp   = cVendComp
         lcFixedAcct   = cQBFixedAcct
      ELSE
         * Get the A/P Account
         SWSELECT('apopt')
         lcapacct   = capacct

         *  Get the Disbursements accounts
         SWSELECT('options')
         GO TOP

         lcDisbAcct   = cDisbAcct
         lcVendComp   = cVendComp
         lcFixedAcct   = cFixedAcct
      ENDIF

      IF TYPE('m.goApp') = 'O'
         * Post entries for the AM version
         llPostDM = m.goApp.lAMVersion
      ENDIF

      **************************************
      *  Net down expenses for dummy owners
      **************************************

      Make_Copy('expense', 'exptemp')
      SWSELECT('wells')
      SET ORDER TO cWellID
      SWSELECT('expense', .T.)
      SCAN FOR nRunNoJIB = tnRunNo AND (cRunYearJIB = tcyear OR cRunYearJIB = '1900') AND EMPTY(cpaidbyck) AND cCatCode # 'PLUG'
         SCATTER MEMVAR
         SELECT wells
         IF SEEK(m.cWellID) AND cgroup = THIS.cgroup
            m.namount = swnetexp(m.namount, m.cWellID, .T., expense.cexpclass, 'B', .F., .F., m.cCatCode, m.cDeck)
            INSERT INTO exptemp FROM MEMVAR
         ENDIF
      ENDSCAN

      SELECT  exptemp.cvendorid, cyear, cperiod, wells.nprocess, ;
         SUM(namount) AS namount, vendor.cvendname AS cpayee   ;
         FROM exptemp, vendor, wells ;
         WHERE exptemp.cvendorid = vendor.cvendorid           ;
         AND exptemp.cWellID = wells.cWellID                ;
         AND EMPTY(exptemp.cpaidbyck)                        ;
         AND exptemp.laptran # .T.                         ;
         AND wells.cwellstat # 'I'                         ;
         AND wells.cgroup = tcGroup                         ;
         AND wells.nprocess # 2                            ;
         AND exptemp.cWellID IN (SELECT  DISTINCT cWellID ;
         FROM wellinv) ;
         INTO CURSOR vendc1 ;
         GROUP BY exptemp.cvendorid ;
         ORDER BY exptemp.cvendorid

      lnMax     = _TALLY
      lnCount = 1

      SELECT  exptemp.cvendorid, cyear, cperiod, wells.nprocess, ;
         SUM(namount) AS namount, vendor.cvendname AS cpayee   ;
         FROM exptemp, vendor, wells ;
         WHERE exptemp.cvendorid = vendor.cvendorid           ;
         AND exptemp.cWellID = wells.cWellID                ;
         AND EMPTY(exptemp.cpaidbyck)                        ;
         AND exptemp.laptran # .T.                         ;
         AND wells.cwellstat # 'I'                         ;
         AND wells.cgroup = tcGroup                         ;
         AND wells.nprocess # 2                            ;
         AND exptemp.cWellID IN (SELECT  DISTINCT cWellID ;
         FROM wellinv) ;
         INTO CURSOR vendtype ;
         GROUP BY exptemp.cvendorid, exptemp.lfixed ;
         ORDER BY exptemp.cvendorid, exptemp.lfixed

      CREATE CURSOR vendchks ;
         (cvendorid    C(10), ;
         cpayee      C(40), ;
         cyear        C(4), ;
         cperiod      C(2), ;
         nprocess     N(1), ;
         namount      N(12, 2))

      SELECT  cvendorid, cpayee, cyear, cperiod, nprocess, ;
         SUM(namount) AS namount ;
         FROM vendc1 ;
         INTO CURSOR vendc2 ;
         GROUP BY cvendorid ;
         ORDER BY cvendorid

      SELECT vendchks
      APPEND FROM DBF('vendc2')

      lnMax     = lnMax * 2
      lntotal = 0

      THIS.oProgress = THIS.omessage.ProgressBar('Creating the vendor checks...')

      THIS.ogl.dmbatch    = THIS.cdmbatch

      lcBatch              = THIS.oregistry.IncrementCounter('%Shared.Counters.Batch')
      THIS.ogl.cReference = 'Run: J' + THIS.crunyear + '/' + ALLT(STR(THIS.nrunno)) + '/' + THIS.cgroup
      THIS.ogl.cyear        = tcyear
      THIS.ogl.cperiod     = tcperiod
      THIS.ogl.dcheckdate = tdCheckDate
      THIS.ogl.dpostdate  = tdpostdate
      THIS.ogl.dgldate     = tdpostdate
      THIS.ogl.dRecDate     = {}
      THIS.ogl.cCheckNo     = ''
      THIS.ogl.lCleared     = .F.
      THIS.ogl.lPrinted     = .F.
      THIS.ogl.cmemo        = ''
      THIS.ogl.cidtype     = 'V'
      THIS.ogl.csource     = 'DM'
      THIS.ogl.cAcctNo     = lcDisbAcct
      THIS.ogl.cgroup     = tcGroup
      THIS.ogl.cEntryType = 'C'

      *
      *  Create checks in check register
      *
      SELECT vendchks
      IF RECC() # 0

         SCAN FOR namount > 0
            SCATTER MEMVAR

            IF m.goApp.lCanceled
               llReturn = .F.
               IF NOT m.goApp.CancelMsg()
                  THIS.lCanceled = .T.
                  EXIT
               ENDIF
            ENDIF

            SWSELECT('vendor')
            SET ORDER TO cvendorid
            IF SEEK(m.cvendorid)
               lcVendName = cvendname
               IF lIntegGL
                  LOOP
               ENDIF
               IF NOT m.goApp.lAMVersion
                  IF lSkipCheck
                     LOOP
                  ENDIF
               ENDIF
            ELSE
               LOOP
            ENDIF
            *
            *  Create a check to pay the vendor's expenses
            *
            THIS.ogl.cbatch  = tcBatch
            THIS.ogl.cID     = m.cvendorid
            THIS.ogl.cpayee  = lcVendName
            THIS.ogl.namount = m.namount
            THIS.ogl.addcheck()
            lcidchec = THIS.ogl.GETKEY()
            *
            *   Update the expense records with the check they were paid with
            *
            THIS.expenseupd(m.cvendorid, lcidchec)

            *
            *  Build the G/L
            *
            IF llPostDM
               THIS.ogl.cbatch  = lcBatch
               THIS.ogl.cAcctNo = lcDisbAcct
               THIS.ogl.namount = m.namount * -1
               THIS.ogl.cdesc     = lcVendName
               THIS.ogl.cidchec = lcidchec
               THIS.ogl.updatebatch()
            ENDIF
            *
            *  Add the check to the total so we can post one
            *  entry to the expense clearing account
            *
            SELECT vendtype
            LOCATE FOR cvendorid == m.cvendorid AND NOT lfixed
            IF FOUND()
               lnAPAmt = lnAPAmt + m.namount
            ENDIF
            LOCATE FOR cvendorid == m.cvendorid AND lfixed
            IF FOUND()
               lnFixedAmt = lnFixedAmt + m.namount
            ENDIF

            SELECT vendchks
            THIS.oProgress.UpdateProgress(lnCount)
            lnCount = lnCount + 1
         ENDSCAN

      ENDIF

      *  Post the total of the vendor checks to the expense
      *  clearing account
      IF llPostDM
         IF lnCompAmt # 0
            THIS.ogl.cbatch  = lcBatch
            THIS.ogl.cAcctNo = THIS.cRevClear
            THIS.ogl.namount = lnCompAmt
            THIS.ogl.cdesc     = 'Compression/Gathering Checks'
            THIS.ogl.cidchec = ''
            THIS.ogl.updatebatch()
         ENDIF
         IF lnAPAmt # 0
            THIS.ogl.cbatch  = lcBatch
            THIS.ogl.cAcctNo = lcapacct
            THIS.ogl.namount = lnAPAmt
            THIS.ogl.cdesc     = 'Vendor A/P Checks'
            THIS.ogl.cidchec = ''
            THIS.ogl.updatebatch()
         ENDIF
         IF lnFixedAmt # 0
            THIS.ogl.cbatch  = lcBatch
            THIS.ogl.cAcctNo = lcFixedAcct
            THIS.ogl.namount = lnFixedAmt
            THIS.ogl.cdesc     = 'Fixed Expnese Checks'
            THIS.ogl.cidchec = ''
            THIS.ogl.updatebatch()
         ENDIF
      ENDIF

      THIS.oProgress.CLOSEProgress()
      DOEVENTS
      THIS.oProgress = .NULL.
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'VendorChks', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('VendorChks', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC


   *-- Calculates the closing summary report.
   **********************************************************
   PROCEDURE calcsummary
   **********************************************************
   LOCAL lcYear, lcPeriod, lcGroup, lnRevEnt, lnExpEnt
   LOCAL lnRevAll, lnExpAll, lcTitle1, lcDMBatch
   LOCAL lnJIBAll, lnjibinv, lnJibInvAmt, llReturn, loError

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      lcYear  = THIS.cyear
      lcGroup = THIS.cgroup
      lnrunno = THIS.nrunno

      SWSELECT('wells')
      SWSELECT('wellinv')

      SWSELECT('sysctl')
      LOCATE FOR cyear = lcYear AND nrunno = lnrunno AND cTypeClose = 'J'
      IF FOUND()
         lcDMBatch      = cdmbatch
         THIS.dexpdate   = dexpdate
         THIS.dpostdate   = dpostdate
      ELSE
         lcDMBatch      = ''
         THIS.dexpdate   = {}
         THIS.dpostdate   = {}
      ENDIF

      STORE 0 TO lnJIBAll, lnjibinv, lnJibInvAmt

      SWSELECT('options')
      GO TOP
      glGrpName  = lGrpName

      IF glGrpName
         SWSELECT('groups')
         SET ORDER TO cgroup
         IF SEEK(lcGroup)
            m.cGrpName = cdesc
         ELSE
            IF lcGroup = '**'
               m.cGrpName = 'All Companies'
            ELSE
               m.cGrpName = ''
            ENDIF
         ENDIF
      ELSE
         m.cGrpName = ''
      ENDIF

      lcTitle1   = 'Joint Interest Closing Summary'
      lcTitle2   = 'For Run ' + ALLT(STR(lnrunno)) + '/' + lcYear + ' Group ' + lcGroup

      IF TYPE('m.goApp') = 'O'
         m.cProducer = m.goApp.cCompanyName
      ELSE
         m.cProducer = 'Development Company'
      ENDIF

      m.cProcessor = ''

      *
      *  Builds the closing summary information
      *
      CREATE CURSOR closetemp ;
         (dexpense       D, ;
         dexpdate       D,  ;
         dpostdate      D, ;
         nExpEntered    N(12, 2), ;
         nJExpAllocated N(12, 2), ;
         nExpAllocated  N(12, 2), ;
         nJIBInvCount   N(4), ;
         nJIBInvAmount  N(12, 2), ;
         nVendChkCount  N(4), ;
         nVendChkAmt    N(12, 2), ;
         nPrePaid       N(12, 2), ;
         nPluggingFund  N(12, 2))

      SWSELECT('wells')
      SET ORDER TO cWellID
      *  Get the expenses entered
      lnExpEnt      = 0
      lnJIBExpEnt   = 0
      WAIT WIND NOWAIT 'Summing Expenses Entered...'
      SWSELECT('expense')
      SCAN FOR (nRunNoJIB = lnrunno AND cRunYearJIB = lcYear)
         SCATTER MEMVAR
         IF NOT m.goApp.lPluggingModule AND m.cexpclass = 'P'
            LOOP
         ENDIF
         SWSELECT('wells')
         IF SEEK(m.cWellID) AND cgroup = lcGroup
            lnExpEnt = lnExpEnt + swnetexp(m.namount, m.cWellID, .T., m.cexpclass, 'J', .F., m.cownerid, m.cCatCode, m.cDeck)
         ENDIF
      ENDSCAN

      *  Get the JIB expenses allocated
      WAIT WIND NOWAIT 'Summing Expenses Allocated to JIB Owners...'
      lnJIBExpAll = 0
      SWSELECT('disbhist', .T.)
      SCAN FOR nrunno = lnrunno AND crunyear = lcYear AND cRecType = 'J'
         SCATTER MEMVAR
         SWSELECT('investor')
         SET ORDER TO cownerid
         IF SEEK(m.cownerid) AND investor.ldummy
            LOOP
         ENDIF
         lnJIBExpAll = lnJIBExpAll + m.nexpense + m.ntotale1 + m.ntotale2 + m.ntotale3 + m.ntotale4 + m.ntotale5 + m.ntotaleA + m.ntotaleB + m.nplugexp
      ENDSCAN

      *  Get the net expenses allocated
      WAIT WIND NOWAIT 'Summing Expenses Allocated to Net Owners...'
      lnExpAll = 0
      SWSELECT('expense', .T.)
      SCAN FOR (nRunNoJIB = lnrunno AND cRunYearJIB = lcYear)
         SCATTER MEMVAR
         IF NOT EMPTY(m.cownerid)
            SWSELECT('expcat')
            SET ORDER TO cCatCode
            IF SEEK(m.cCatCode)
               m.ljibonly = ljibonly
               SELE wellinv
               LOCATE FOR cownerid = m.cownerid AND cWellID = m.cWellID AND ctypeinv = 'W'
               IF FOUND()
                  IF wellinv.lJIB = .F. AND m.ljibonly = .F.
                     lnExpAll = lnExpAll + m.namount
                  ENDIF
               ENDIF
            ENDIF
         ELSE
            lnExpAll = lnExpAll + swnetexp(m.namount, m.cWellID, .T., m.cexpclass, 'N', .F., .F., m.cCatCode, m.cDeck)
         ENDIF
      ENDSCAN

      * Get the count of JIB Invoices
      WAIT WIND NOWAIT 'Summing JIB Invoice Count...'
      lnjibinv = 0
      SWSELECT('invhdr', .T.)
      SCAN FOR cdmbatch = lcDMBatch
         m.cownerid = cCustId
         SWSELECT('investor')
         SET ORDER TO cownerid
         IF SEEK(m.cownerid) AND investor.ldummy
            LOOP
         ENDIF
         lnjibinv = lnjibinv + 1
      ENDSCAN

      * Get the amount of JIB Invoices
      WAIT WIND NOWAIT 'Summing JIB Invoices...'
      SELECT  SUM(nInvTot) AS nInvTot ;
         FROM invhdr WITH (BUFFERING = .T.) ;
         WHERE cdmbatch = lcDMBatch ;
         AND cCustId NOT IN (SELECT  cownerid ;
         FROM investor ;
         WHERE investor.ldummy) ;
         INTO ARRAY laTotal
      IF _TALLY > 0
         lnJibInvAmt = laTotal[1]
      ELSE
         lnJibInvAmt = 0
      ENDIF

      * Get the amount of prepays applied
      SELECT  SUM(nExtension) AS nPrePaid ;
         FROM invdet, invhdr WITH (BUFFERING = .T.);
         WHERE invhdr.cdmbatch = lcDMBatch ;
         AND invdet.cbatch == invhdr.cbatch ;
         AND invdet.cTaxCode == '{P' ;
         AND cCustId NOT IN (SELECT  cownerid ;
         FROM investor ;
         WHERE investor.ldummy) ;
         INTO ARRAY laTotal
      IF _TALLY > 0
         lnPrePaid = laTotal[1]
      ELSE
         lnPrePaid = 0
      ENDIF


      STORE 0 TO m.nVendChkCount
      STORE 0 TO m.nVendChkAmt

      *  Get the check counts and amounts
      WAIT WIND NOWAIT 'Summing Checks...'
      SWSELECT('sysctl', .T.)
      LOCATE FOR nrunno = lnrunno AND cyear = lcYear AND cTypeClose = 'J'
      IF FOUND()
         lcDMBatch   = cdmbatch
         m.dexpense   = sysctl.dexpdate
         m.dpostdate   = sysctl.dpostdate
         SELE checks
         SCAN FOR cbatch = lcDMBatch AND cidtype = 'V'
            m.nVendChkCount = m.nVendChkCount + 1
            m.nVendChkAmt    = m.nVendChkAmt + namount
         ENDSCAN
      ELSE
         m.dexpense   = {}
         m.dpostdate   = {}
      ENDIF

      *  Get the Plugging Fund Charges
      WAIT WIND NOWAIT 'Summing Plugging Fund Charges...'
      lnPlugging = 0
      SWSELECT('disbhist', .T.)
      SCAN FOR nrunno = lnrunno AND crunyear = lcYear AND cRecType = 'J'
         SCATTER MEMVAR
         SWSELECT('investor')
         SET ORDER TO cownerid
         IF SEEK(m.cownerid) AND investor.ldummy
            LOOP
         ENDIF
         lnPlugging = lnPlugging + m.nplugexp
      ENDSCAN

      m.dexpdate        = m.dexpense
      m.nExpEntered     = lnExpEnt
      m.nJExpAllocated = lnJIBExpAll
      m.nExpAllocated  = lnExpAll
      m.nJIBInvCount     = lnjibinv
      m.nJIBInvAmount  = lnJibInvAmt
      m.nPrePaid        = lnPrePaid
      m.nPluggingFund  = lnPlugging

      INSERT INTO closetemp FROM MEMVAR
      SELECT closetemp
      WAIT CLEAR

      REPORT FORM dmrclosej.frx PREVIEW
      IF THIS.omessage.CONFIRM('Should the report be sent to the printer now?')
         REPORT FORM dmrclosej TO PRINTER PROMPT NOCONSOLE NOEJECT RANGE 1, 1
      ENDIF
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'CalcSummary', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('CalcSummary', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE expenseupd
   **********************************************************
   LPARA tcVendor, tcidChec
   LOCAL tcyear, tcperiod, tcGroup, llReturn, loError

   llReturn = .T.

   TRY
      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      tcyear   = THIS.cyear
      tcperiod   = THIS.cperiod
      tcGroup   = THIS.cgroup
      tnRunNo   = THIS.nrunno

      SWSELECT('expense', .T.)  &&  Select statement below wasn't working b/c of buffering issues on the crunyearjib and nrunnojib fields in expense - BH 3/28/06
      SCAN FOR cvendorid = tcVendor AND nRunNoJIB = tnRunNo AND (cRunYearJIB = tcyear OR cRunYearJIB = '1900') AND EMPTY(cpaidbyck) AND NOT laptran
         REPLACE cpaidbyck WITH tcidChec
      ENDSCAN

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'ExpenseUpd', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('ExpenseUpd', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC


   *-- Calculates and adjusts rounding
   **********************************************************
   PROCEDURE calcround
   **********************************************************
   LPARA tlAll
   LOCAL llRoundHigh, lnMaxRound, lcownerid
   LOCAL llReturn, loError

   llReturn = .T.

   TRY
      * If we're not closing, jibowner won't have all owners in it so
      * there's no use in trying to calculate rounding amounts
      IF NOT tlAll
         llReturn = .T.
         EXIT
      ENDIF

      IF m.goApp.lCanceled
         llReturn = .F.
         IF NOT m.goApp.CancelMsg()
            THIS.lCanceled = .T.
            EXIT
         ENDIF
      ENDIF

      SWSELECT('roundtmp')

      llRoundHigh   = options.lRoundHigh
      lnMaxRound   = options.nMaxRound
      lcownerid   = ''

      IF lnMaxRound = 0
         lnMaxRound = .50
      ENDIF

      CREATE CURSOR roundtmpx  ;
         (cWellID     C(10),    ;
         cwellname   C(40),    ;
         cownerid    C(10),    ;
         cownname    C(40),    ;
         nexpense    N(12, 2),  ;
         ntotale1    N(12, 2),  ;
         ntotale2    N(12, 2),  ;
         ntotale3    N(12, 2),  ;
         ntotale4    N(12, 2),  ;
         ntotale5    N(12, 2),  ;
         ntotaleA    N(12, 2),  ;
         ntotaleB    N(12, 2),  ;
         nnetcheck   N(12, 2),  ;
         cdmbatch    C(8))

      SELECT jibwell
      COUNT FOR NOT DELETED() TO lnMax
      lnCount = 1

      IF NOT THIS.lquiet
         THIS.oProgress = THIS.omessage.progressbarex('Calculating Rounding Amounts...', 'Processing Well: ')
         THIS.oProgress.SetProgressRange(0, lnMax)
      ENDIF

      SELECT  cWellID, ;
         SUM(nTotale) AS nTotale, ;
         SUM(nexpcl1) AS nexpcl1, ;
         SUM(nexpcl2) AS nexpcl2, ;
         SUM(nexpcl3) AS nexpcl3, ;
         SUM(nexpcl4) AS nexpcl4, ;
         SUM(nexpcl5) AS nexpcl5, ;
         SUM(nexpcla) AS nexpcla, ;
         SUM(nexpclb) AS nexpclb ;
         FROM jibwell ;
         INTO CURSOR jibwellwrk ;
         ORDER BY cWellID ;
         GROUP BY cWellID

      SELECT jibwellwrk
      SCAN
         SCATTER MEMVAR
         IF NOT THIS.lquiet
            THIS.oProgress.UpdateProgress(lnCount)
            THIS.oProgress.SetProgressMessage('Processing Well: ' + m.cWellID)
            lnCount = lnCount + 1
         ENDIF

         SELECT  cWellID,  ;
            jibowner.cownerid, ;
            SUM(nnetcheck) AS nnetcheck, ;
            SUM(nexpense)  AS nexpense,  ;
            SUM(ntotale1)  AS ntotale1,  ;
            SUM(ntotale2)  AS ntotale2,  ;
            SUM(ntotale3)  AS ntotale3,  ;
            SUM(ntotale4)  AS ntotale4,  ;
            SUM(ntotale5)  AS ntotale5,  ;
            SUM(ntotaleA)  AS ntotaleA,  ;
            SUM(ntotaleB)  AS ntotaleB   ;
            FROM jibowner, investor  ;
            WHERE cWellID = m.cWellID  ;
            AND jibowner.cownerid = investor.cownerid ;
            AND NOT investor.ldummy ;
            INTO CURSOR difftmp ;
            ORDER BY cWellID ;
            GROUP BY cWellID

         IF _TALLY > 0
            SELECT difftmp
            SCAN
               m.nexpense = m.nTotale - nexpense
               m.ntotale1 = m.nexpcl1 - ntotale1
               m.ntotale2 = m.nexpcl2 - ntotale2
               m.ntotale3 = m.nexpcl3 - ntotale3
               m.ntotale4 = m.nexpcl4 - ntotale4
               m.ntotale5 = m.nexpcl5 - ntotale5
               m.ntotaleA = m.nexpcla - ntotaleA
               m.ntotaleB = m.nexpclb - ntotaleB
            ENDSCAN
            m.cdmbatch = THIS.cdmbatch
            INSERT INTO roundtmpx FROM MEMVAR
         ENDIF

      ENDSCAN

      SELECT  * ;
         FROM roundtmpx ;
         INTO CURSOR roundtmp1 ;
         WHERE (nexpense # 0)  ;
         OR (ntotale1 # 0);
         OR (ntotale2 # 0)  ;
         OR (ntotale3 # 0);
         OR (ntotale4 # 0)  ;
         OR (ntotale5 # 0);
         OR (ntotaleA # 0)  ;
         OR (ntotaleB # 0)

      SELECT  * ;
         FROM roundtmp1 ;
         INTO CURSOR roundtmp2 ;
         WHERE (ABS(nexpense) <= lnMaxRound) ;
         AND   (ABS(ntotale1) <= lnMaxRound);
         AND  (ABS(ntotale2) <= lnMaxRound)  ;
         AND   (ABS(ntotale3) <= lnMaxRound);
         AND  (ABS(ntotale4) <= lnMaxRound)  ;
         AND   (ABS(ntotale5) <= lnMaxRound);
         AND  (ABS(ntotaleA) <= lnMaxRound)  ;
         AND   (ABS(ntotaleB) <= lnMaxRound)

      IF _TALLY > 0
         SELECT roundtmp2
         USE DBF('roundtmp2') AGAIN IN 0 ALIAS roundtmp3
         SELECT roundtmp3
         SCAN
            SWSELECT('wells')
            LOCATE FOR cWellID = roundtmp3.cWellID
            IF FOUND('wells')
               IF EMPTY(wells.cownerid)  &&  No owner specified to adjust rounding to
                  IF llRoundHigh  &&  If rounding to highest owner
                     SWSELECT('wellinv')
                     SET ORDER TO cownerid DESC
                     LOCATE FOR cWellID = roundtmp3.cWellID AND ctypeinv = 'W' AND nworkint # 0 AND lJIB
                     IF FOUND('wellinv')
                        lcownerid = wellinv.cownerid
                     ENDIF
                  ELSE  &&  Rounding to lowest owner
                     SWSELECT('wellinv')
                     SET ORDER TO cownerid
                     LOCATE FOR cWellID = roundtmp3.cWellID AND ctypeinv = 'W' AND nworkint # 0 AND lJIB
                     IF FOUND('wellinv')
                        lcownerid = wellinv.cownerid
                     ENDIF
                  ENDIF
               ELSE  &&  An owner is specified
                  lcownerid = wells.cownerid
               ENDIF
               REPLACE roundtmp3.cownerid WITH lcownerid

               SELECT jibowner
               LOCATE FOR cownerid = lcownerid AND cWellID = roundtmp3.cWellID
               IF FOUND('jibowner')  &&  If it doesn't find this owner and this well, somethings's screwy, and this well will have rounding.
                  REPLACE jibowner.nexpense WITH jibowner.nexpense + roundtmp3.nexpense,  ;
                     jibowner.ntotale1 WITH jibowner.ntotale1 + roundtmp3.ntotale1,  ;
                     jibowner.ntotale2 WITH jibowner.ntotale2 + roundtmp3.ntotale2,  ;
                     jibowner.ntotale3 WITH jibowner.ntotale3 + roundtmp3.ntotale3,  ;
                     jibowner.ntotale4 WITH jibowner.ntotale4 + roundtmp3.ntotale4,  ;
                     jibowner.ntotale5 WITH jibowner.ntotale5 + roundtmp3.ntotale5,  ;
                     jibowner.ntotaleA WITH jibowner.ntotaleA + roundtmp3.ntotaleA,  ;
                     jibowner.ntotaleB WITH jibowner.ntotaleB + roundtmp3.ntotaleB,  ;
                     jibowner.nnetcheck WITH jibowner.nnetcheck - ;
                     (roundtmp3.nexpense + roundtmp3.ntotale1 + roundtmp3.ntotale2 + roundtmp3.ntotale3 + roundtmp3.ntotale4 + roundtmp3.ntotale5 + ;
                     roundtmp3.ntotaleA + roundtmp3.ntotaleB)
               ENDIF
            ENDIF
         ENDSCAN

         SELECT roundtmp3
         USE DBF('roundtmp3') AGAIN IN 0 ALIAS roundtmp4
         SELECT roundtmp4
         SCAN
            SWSELECT('wells')
            LOCATE FOR cWellID = roundtmp4.cWellID
            IF FOUND('wells')
               IF EMPTY(wells.cownerid)  &&  No owner specified to adjust rounding to
                  IF llRoundHigh  &&  If rounding to highest owner
                     SWSELECT('wellinv')
                     SET ORDER TO cownerid DESC
                     LOCATE FOR cWellID = roundtmp4.cWellID AND ctypeinv = 'W' AND nworkint # 0 AND lJIB
                     IF FOUND('wellinv')
                        lcownerid = wellinv.cownerid
                     ENDIF
                  ELSE  &&  Rounding to lowest owner
                     SWSELECT('wellinv')
                     SET ORDER TO cownerid
                     LOCATE FOR cWellID = roundtmp4.cWellID AND ctypeinv = 'W' AND nworkint # 0 AND lJIB
                     IF FOUND('wellinv')
                        lcownerid = wellinv.cownerid
                     ENDIF
                  ENDIF
               ELSE  &&  An owner is specified
                  lcownerid = wells.cownerid
               ENDIF
               REPLACE roundtmp4.cownerid WITH lcownerid
               REPLACE roundtmp4.cwellname WITH wells.cwellname

               SWSELECT('investor')
               LOCATE FOR cownerid = lcownerid
               IF FOUND('Investor')
                  REPLACE roundtmp4.cownname WITH investor.cownname, ;
                     roundtmp4.cownerid WITH investor.cownerid
               ENDIF
            ENDIF
         ENDSCAN

         SWSELECT('roundtmp', .T.)
         APPEND FROM DBF('roundtmp4')

      ENDIF

      IF NOT THIS.lquiet
         THIS.oProgress.CLOSEProgress()
         DOEVENTS
         THIS.oProgress = .NULL.
      ENDIF

      swclose('roundtmp1')
      swclose('roundtmp2')
      swclose('roundtmp3')
      swclose('roundtmp4')

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'CalcRound', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('CalcRound', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE calcsumbywell
   **********************************************************
   LPARA tlExceptions
   LOCAL lcYear, lcPeriod, lcGroup, lnRevEnt, lnExpEnt
   LOCAL lnRevAll, lnExpAll, lcTitle1, lcDMBatch
   LOCAL lnJIBAll, lnjibinv, lnJibInvAmt, llReturn, loError

   llReturn = .T.

   TRY

      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      lcYear   = THIS.cyear
      lcPeriod   = THIS.cperiod
      lcGroup   = THIS.cgroup
      lnrunno   = THIS.nrunno

      STORE 0 TO lnJIBAll, lnjibinv, lnJibInvAmt

      SELE sysctl
      LOCATE FOR cyear = lcYear AND nrunno = lnrunno AND cTypeClose = 'J'
      IF FOUND()
         lcDMBatch      = cdmbatch
         THIS.dexpdate   = sysctl.dexpdate
         THIS.dpostdate   = sysctl.dpostdate
      ELSE
         lcDMBatch = ''
      ENDIF

      SWSELECT('options')
      GO TOP
      glGrpName  = lGrpName


      IF glGrpName
         SWSELECT('groups')
         SET ORDER TO cgroup
         IF SEEK(lcGroup)
            m.cGrpName = cdesc
         ELSE
            IF lcGroup = '**'
               m.cGrpName = 'All Companies'
            ELSE
               m.cGrpName = ''
            ENDIF
         ENDIF
      ELSE
         m.cGrpName = ''
      ENDIF

      lcTitle1   = 'Joint Interest Closing Summary'
      lcTitle2   = 'For Run ' + ALLT(STR(lnrunno)) + '/' + lcYear + ' Group ' + lcGroup

      IF TYPE('m.goApp') = 'O'
         m.cProducer = m.goApp.cCompanyName
      ELSE
         m.cProducer = 'Development Company'
      ENDIF

      m.cProcessor = ''


      *
      *  Builds the closing summary information
      *
      CREATE CURSOR closetemp ;
         (cWellID        C(10), ;
         cwellname      C(30), ;
         nExpEntered    N(12, 2), ;
         nJExpAllocated N(12, 2), ;
         nExpAllocated  N(12, 2), ;
         nJIBInvCount   N(4), ;
         nJIBInvAmount  N(12, 2), ;
         nVendChkCount  N(4), ;
         nVendChkAmt    N(12, 2), ;
         dpostdate      D, ;
         dexpdate       D)

      CREATE CURSOR tempclose ;
         (cWellID        C(10), ;
         cwellname      C(30), ;
         nExpEntered    N(12, 2), ;
         nJExpAllocated N(12, 2), ;
         nExpAllocated  N(12, 2), ;
         nJIBInvCount   N(4), ;
         nJIBInvAmount  N(12, 2), ;
         nVendChkCount  N(4), ;
         nVendChkAmt    N(12, 2), ;
         dpostdate      D, ;
         dexpdate       D)

      SWSELECT('wells')
      SET ORDER TO cWellID


      *  Get the expenses entered
      m.nExpEntered = 0
      WAIT WIND NOWAIT 'Summing expenses entered....'
      SWSELECT('expense', .T.)
      SCAN FOR (nRunNoJIB = lnrunno AND cRunYearJIB = lcYear)
         SCATTER MEMVAR
         SWSELECT('wells')
         IF SEEK(m.cWellID) AND cgroup = lcGroup
            m.nExpEntered = swnetexp(m.namount, m.cWellID, .T., m.cexpclass, 'J', .F., m.cownerid, m.cCatCode, m.cDeck)
            m.cwellname     = wells.cwellname
            INSERT INTO closetemp FROM MEMVAR
         ENDIF
      ENDSCAN

      STORE 0 TO  m.nExpEntered, m.nJExpAllocated, m.nExpAllocated, m.nJIBInvCount, m.nJIBInvAmount, m.nVendChkCount, m.nVendChkAmt

      *  Get the JIB expenses allocated
      WAIT WIND NOWAIT 'Summing JIB expenses allocated to owners...'
      m.nJExpAllocated = 0
      SWSELECT('disbhist', .T.)
      SCAN FOR nrunno = lnrunno AND crunyear = lcYear AND cRecType = 'J'
         SCATTER MEMVAR
         SWSELECT('investor')
         SET ORDER TO cownerid
         IF SEEK(m.cownerid) AND investor.ldummy
            LOOP
         ENDIF
         SWSELECT('wells')
         IF SEEK(m.cWellID) AND cgroup = lcGroup
            m.cwellname = cwellname
         ENDIF
         m.nJExpAllocated = m.nexpense + m.ntotale1 + m.ntotale2 + m.ntotale3 + m.ntotale4 + m.ntotale5 + m.ntotaleA + m.ntotaleB
         INSERT INTO closetemp FROM MEMVAR
      ENDSCAN

      STORE 0 TO  m.nExpEntered, m.nJExpAllocated, m.nExpAllocated, m.nJIBInvCount, m.nJIBInvAmount, m.nVendChkCount, m.nVendChkAmt

      *  Get the net expenses allocated
      WAIT WIND NOWAIT 'Summing net expenses allocated to owners...'
      m.nExpAllocated = 0
      SWSELECT('expense', .T.)
      SCAN FOR nRunNoJIB = lnrunno AND cRunYearJIB = lcYear
         SCATTER MEMVAR
         IF NOT EMPTY(m.cownerid)
            SWSELECT('expcat')
            SET ORDER TO cCatCode
            IF SEEK(m.cCatCode)
               m.ljibonly = ljibonly
               SELE wellinv
               LOCATE FOR cWellID = m.cWellID AND cownerid = m.cownerid AND ctypeinv = 'W' AND nworkint # 0
               IF FOUND()
                  IF wellinv.lJIB = .F. AND m.ljibonly = .F.
                     m.nExpAllocated = m.namount
                  ELSE
                     m.nExpAllocated = 0
                  ENDIF
               ELSE
                  m.nExpAllocated = 0
               ENDIF
            ENDIF
         ELSE
            m.nExpAllocated = swnetexp(m.namount, m.cWellID, .T., m.cexpclass, 'N', .F., .F., m.cCatCode, m.cDeck)
         ENDIF
         SWSELECT('wells')
         IF SEEK(m.cWellID) AND cgroup = lcGroup
            m.cwellname = cwellname
         ENDIF
         INSERT INTO closetemp FROM MEMVAR
      ENDSCAN

      SELECT  cWellID, cwellname, ;
         SUM(nExpEntered) AS nExpEntered, ;
         SUM(nJExpAllocated) AS nJExpAllocated, ;
         SUM(nExpAllocated) AS nExpAllocated ;
         FROM closetemp ;
         INTO CURSOR temp ;
         ORDER BY cWellID ;
         GROUP BY cWellID

      m.dexpdate   = THIS.dexpdate
      m.dpostdate   = THIS.dpostdate

      IF tlExceptions
         WAIT WIND NOWAIT 'Determining exceptions...'
         SELECT temp
         SCAN
            SCATTER MEMVAR
            IF ABS(m.nExpEntered - m.nJExpAllocated) <= .50
               LOOP
            ENDIF
            INSERT INTO tempclose FROM MEMVAR
         ENDSCAN
      ELSE
         SELECT temp
         SCAN
            SCATTER MEMVAR
            IF m.nExpEntered # 0
               INSERT INTO tempclose FROM MEMVAR
            ENDIF
         ENDSCAN
      ENDIF
      WAIT CLEAR
      SELECT tempclose
      IF RECC() > 0
         REPORT FORM dmrclosejw.frx PREVIEW
         IF THIS.omessage.CONFIRM('Should the report be sent to the printer now?')
            REPORT FORM dmrclosejw TO PRINTER PROMPT NOCONSOLE NOEJECT
         ENDIF
      ELSE
         THIS.omessage.DISPLAY('There were no exceptions found on which to report.')
      ENDIF
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'CalcSumByWell', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('CalcSumByWell', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE checkquarterly
   **********************************************************
   *
   *  Checks for quarterly wells in the wells table
   *
   LOCAL llReturn, loError

   llReturn = .T.

   TRY

      IF THIS.CheckHistRun()
         llReturn = .F.
         EXIT
      ENDIF

      SELE wells
      LOCATE FOR nprocess = 2 AND cgroup == THIS.cgroup
      llReturn = FOUND()
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'CheckQuarterly', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('CheckQuarterly', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC

   **********************************************************
   PROCEDURE CheckHistRun
   **********************************************************
   LOCAL llHist, lcDeleted, llReturn, loError
   *
   *  Checks to see if the given period is closed
   *  Returns .T. if the period is closed
   *

   llReturn = .T.

   TRY
      IF THIS.lerrorflag
         llReturn = .F.
         EXIT
      ENDIF

      IF TYPE('xcDebug') = 'C' AND xcDebug = 'Y'
         WAIT WIND 'In Distproc Checkhist...'
      ENDIF

      lcDeleted = SET('DELETED')
      SET DELETED ON

      llHist = .F.

      IF THIS.cgroup = '**'
         SWSELECT('sysctl', .T.)
         LOCATE FOR cyear == THIS.crunyear AND nrunno = THIS.nrunno AND lDisbMan AND cTypeClose = 'J'
         IF FOUND()
            llHist       = .T.
            THIS.lRelMin = sysctl.lRelMin
            THIS.lrelqtr = sysctl.lrelqtr
         ENDIF
      ELSE
         SWSELECT('sysctl', .T.)
         LOCATE FOR cyear == THIS.crunyear AND nrunno = THIS.nrunno AND cgroup = THIS.cgroup AND cTypeClose = 'J'
         IF FOUND()
            llHist       = .T.
            THIS.lRelMin = sysctl.lRelMin
            THIS.lrelqtr = sysctl.lrelqtr
         ENDIF
      ENDIF

      SET DELETED &lcDeleted

      llReturn = llHist
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'CheckHistRun', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('CheckHistRun', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn
   ENDPROC


   *-- Checks for wells with no net owners and makes the revenue run no in expense be the same as jib runno
   **********************************************************
   PROCEDURE nonnetcheck
   **********************************************************
   *
   *  Check for net owners in the wells being processed.
   *  If there are not any net owners, the expense records
   *  are changed so that cRunYearRev equals '1901' and
   *  nRunNoRev is changed to match nRunNoJIB so the expenses
   *  don't show up in the New Run for Well Net Expenses by Well.
   *
   LOCAL llReturn, loError

   llReturn = .T.

   TRY
      SWSELECT('expense')
      SWSELECT('wellinv')
      SWSELECT('wells')
      SCAN FOR BETWEEN(cWellID, THIS.cbegwellid, THIS.cendwellid)
         m.cWellID = cWellID
         SELE expense
         SCAN FOR cWellID == m.cWellID AND ;
               nRunNoJIB == THIS.nrunno AND ;
               cRunYearJIB == THIS.crunyear AND ;
               nrunnorev = 0 AND ;
               EMPTY(cownerid)
            SWSELECT('wellinv')
            DO CASE
               CASE NOT EMPTY(expense.cownerid)
                  * Look for the owner to see if they're a net owner
                  LOCATE FOR cWellID == m.cWellID AND cownerid == expense.cownerid AND ctypeinv = 'W' AND NOT lJIB
               CASE expense.cexpclass = '0'
                  LOCATE FOR cWellID == m.cWellID AND NOT lJIB AND nworkint # 0
               CASE expense.cexpclass = '1'
                  LOCATE FOR cWellID == m.cWellID AND NOT lJIB AND nintclass1 # 0
               CASE expense.cexpclass = '2'
                  LOCATE FOR cWellID == m.cWellID AND NOT lJIB AND nintclass2 # 0
               CASE expense.cexpclass = '3'
                  LOCATE FOR cWellID == m.cWellID AND NOT lJIB AND nintclass3 # 0
               CASE expense.cexpclass = '4'
                  LOCATE FOR cWellID == m.cWellID AND NOT lJIB AND nintclass4 # 0
               CASE expense.cexpclass = '5'
                  LOCATE FOR cWellID == m.cWellID AND NOT lJIB AND nintclass5 # 0
               CASE expense.cexpclass = 'A'
                  LOCATE FOR cWellID == m.cWellID AND NOT lJIB AND nacpint # 0
               CASE expense.cexpclass = 'B'
                  LOCATE FOR cWellID == m.cWellID AND NOT lJIB AND nbcpint # 0
               CASE expense.cexpclass = 'P'
                  LOCATE FOR cWellID == m.cWellID AND NOT lJIB AND nPlugpct # 0
            ENDCASE

            IF NOT FOUND()
               SWSELECT('expense')
               REPL nrunnorev WITH THIS.nrunno, crunyearrev WITH '1901'
            ENDIF
         ENDSCAN
         * Next, scan for one-person expense items, and fill in the '1901' year on them, too.
         * Those will never be looked at for a revenue closing, so they may as well be marked here
         SELECT expense
         SCAN FOR cWellID == m.cWellID AND nRunNoJIB == THIS.nrunno AND cRunYearJIB == THIS.crunyear AND NOT EMPTY(cownerid)
            SELECT wellinv
            LOCATE FOR cWellID == m.cWellID AND cownerid == expense.cownerid
            IF FOUND()
               IF ctypeinv = 'W' AND lJIB
                  SWSELECT('expense')
                  REPL nrunnorev WITH THIS.nrunno, crunyearrev WITH '1901'
               ENDIF
            ENDIF
         ENDSCAN
      ENDSCAN

      *  Look for any "JIB Only" expense codes, and scan this run's expenses and plug in 1900 as the run year, because these will never be processed
      *  during a normal revenue run closing, and that will keep them from showing up in the New Run and causing questions.
      SWSELECT('expcat')
      SCAN FOR ljibonly
         m.cCatCode = expcat.cCatCode
         SELECT expense
         SCAN FOR cCatCode = m.cCatCode AND nRunNoJIB == THIS.nrunno AND cRunYearJIB == THIS.crunyear
            REPL nrunnorev WITH THIS.nrunno, crunyearrev WITH '1901'
         ENDSCAN
      ENDSCAN

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'NonNetCheck', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('NonNetCheck', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn

   ENDPROC

   **********************************************************
   PROCEDURE ERROR
   **********************************************************
   LPARAMETERS nError, cMethod, nLine
   LOCAL lnLevel, lnX

   THIS.lerrorflag = .T.

   = AERROR(gaerrors)

   DO errorlog WITH m.cMethod, m.nLine, 'JIBPROC'

   *
   *  Remove the QuickBooks Transactions
   *
   IF BETWEEN(m.nError, 1426, 1429)
      m.goApp.oqb.QBError()
   ELSE

      lnLevel = TXNLEVEL()

      IF lnLevel > 0
         FOR lnX = 1 TO lnLevel
            ROLLBACK
         ENDFOR
      ENDIF

      DODEFAULT(nError, cMethod, nLine)
   ENDIF
   ENDPROC

   **********************************************************
   PROCEDURE INIT
   **********************************************************
   LPARA tcbegid, tcendid, tcperiod, tcyear, tcGroup, tcprocess, tdacctdate, tlquiet, tnRunNo, tlSelected
   LOCAL odist

   IF NOT tlquiet
      WAIT WIND NOWAIT 'Initializing Processing Routines...Please Wait'
   ENDIF

   IF TYPE('tcBegID') # 'C'
      WAIT WIND 'An invalid beginning owner was passed to jibproc'
      RETURN .F.
   ENDIF
   IF TYPE('tcEndID') # 'C'
      WAIT WIND 'An invalid ending owner was passed to jibproc'
      RETURN .F.
   ENDIF
   IF TYPE('tcPeriod') # 'C'
      WAIT WIND 'An invalid production period was passed to jibproc'
      RETURN .F.
   ENDIF
   IF TYPE('tcYear') # 'C'
      WAIT WIND 'An invalid production year was passed to jibproc'
      RETURN .F.
   ENDIF
   IF TYPE('tcGroup') # 'C'
      WAIT WIND 'An invalid well group was passed to jibproc'
      RETURN .F.
   ENDIF
   IF TYPE('tcProcess') # 'C'
      WAIT WIND 'An invalid process type was passed to jibproc'
      RETURN .F.
   ENDIF
   IF TYPE('tdAcctDate') # 'D'
      WAIT WIND 'An invalid accounting date was passed to jibproc'
      RETURN .F.
   ENDIF
   IF TYPE('tnRunNo') # 'N'
      WAIT WIND 'An invalid run no was passed to jibproc.'
      RETURN .F.
   ENDIF

   IF NOT tlSelected
      IF tcprocess # 'W'
         SELECT cownerid AS cID FROM investor WHERE BETWEEN(cownerid,tcbegid,tcendid) INTO CURSOR SELECTED ORDER BY cID
      ELSE
         SELECT cWellID AS cID FROM wells WHERE BETWEEN(cWellID,tcbegid,tcendid) INTO CURSOR SELECTED ORDER BY cID
      ENDIF
   ENDIF

   THIS.lquiet = tlquiet
   *
   *  Setup the registry object
   *
   THIS.oregistry = IIF(ISNULL(THIS.oregistry), findglobalobject('cmRegistry'), .NULL.)

   *
   *  Instantiate the glmaint object
   *
   THIS.ogl = CREATEOBJECT('glmaint')

   *
   *  Setup the message object
   *
   THIS.omessage = IIF(ISNULL(THIS.omessage), findglobalobject('cmMessage'), .NULL.)

   IF NOT m.goApp.lAMVersion
      THIS.cacctyear   = STR(YEAR(tdacctdate), 4)
      THIS.cacctprd   = PADL(ALLT(STR(MONTH(tdacctdate), 2)), 2, '0')
   ELSE
      THIS.cacctyear   = THIS.ogl.getperiod(tdacctdate, .T.)
      THIS.cacctprd   = THIS.ogl.getperiod(tdacctdate, .F.)
   ENDIF

   *
   *  Setup the parameters as properties so all methods can use them
   *
   THIS.cperiod   = tcperiod
   THIS.cyear      = tcyear
   THIS.cprocess   = tcprocess
   THIS.cgroup      = tcGroup
   THIS.dacctdate   = tdacctdate
   THIS.dexpdate   = tdacctdate

   *  Initialize the post date
   THIS.dpostdate = THIS.dacctdate

   *  What run no is this processing associated with
   THIS.nrunno     = tnRunNo
   THIS.crunyear = tcyear

   *
   *  Open the tables needed
   *
   SWSELECT('wells')
   SET ORDER TO cWellID
   SWSELECT('investor')
   SET ORDER TO cownerid
   SWSELECT('options')
   SWSELECT('roundtmp', .T.)
   SWSELECT('wellhist', .T.)
   SET ORDER TO wellprd
   SWSELECT('disbhist', .T.)
   SET ORDER TO invwell
   SWSELECT('ownpcts', .T.)
   SWSELECT('sysctl', .T.)
   SET ORDER TO yrprdgrp
   SWSELECT('expense', .T.)
   SWSELECT('expcat')
   SET ORDER TO ccateg
   SWSELECT('groups')
   SET ORDER TO cgroup
   SWSELECT('programs')
   SET ORDER TO cprogcode
   SWSELECT('vendor')
   SET ORDER TO cvendorid
   SWSELECT('wellinv')
   SWSELECT('terms')
   SWSELECT('glopt')
   SWSELECT('invhdr', .T.)
   SWSELECT('invdet', .T.)
   SWSELECT('checks', .T.)
   SWSELECT('ARopt', .T.)

   IF m.goApp.lAMVersion
      SWSELECT('glmaster', .T.)
   ENDIF


   *  Get the expense clearing account
   SELECT glopt
   GO TOP
   THIS.cexpclear = cexpclear

   *
   *  Create the jibwelltmp cursor.  This cursor will contain
   *  the list of wells to process
   *
   CREATE CURSOR jibwelltmp ;
      (cWellID    C(10))

   CREATE CURSOR jibowntmp ;
      (cownerid  C(10))

   *
   *  Build the JIB temporary invoice files
   *
   THIS.createtemp()

   *
   *  Fill in the beginning and ending owner and well ids
   *
   DO CASE
      CASE tcprocess = 'O'
         THIS.cbegownerid = tcbegid
         THIS.cendownerid = tcendid

         *
         *  Get the list of wells that these owners are in
         *
         IF tcGroup = '**'
            SELECT  cWellID ;
               FROM wells ;
               INTO CURSOR temp ;
               ORDER BY cWellID ;
               GROUP BY cWellID
         ELSE
            SELECT  cWellID ;
               FROM wells ;
               WHERE cgroup = tcGroup ;
               INTO CURSOR temp ;
               ORDER BY cWellID ;
               GROUP BY cWellID
         ENDIF

         SELECT jibwelltmp
         APPEND FROM DBF('temp')
         USE IN temp

         SELE jibwelltmp
         GO TOP
         THIS.cbegwellid = cWellID
         GO BOTT
         THIS.cendwellid = cWellID

         *
         *  Put the list of owners in the owner temp cursor
         *
         SELECT  cownerid ;
            FROM investor ;
            WHERE cownerid IN (SELECT cID FROM SELECTED) ;
            INTO CURSOR temp ;
            ORDER BY cownerid ;
            GROUP BY cownerid

         SELECT jibowntmp
         APPEND FROM DBF('temp')
         USE IN temp

      CASE tcprocess = 'W'
         THIS.cbegwellid = tcbegid
         THIS.cendwellid = tcendid

         *
         *  Put the list of wells in the jibwelltmp cursor
         *
         IF tcGroup = '**'
            SELECT  cWellID ;
               FROM wells ;
               WHERE cWellID IN (SELECT cID FROM SELECTED) ;
               INTO CURSOR temp ;
               ORDER BY cWellID ;
               GROUP BY cWellID
         ELSE
            SELECT  cWellID ;
               FROM wells ;
               WHERE cWellID IN (SELECT cID FROM SELECTED) ;
               AND cgroup = tcGroup ;
               INTO CURSOR temp ;
               ORDER BY cWellID ;
               GROUP BY cWellID
         ENDIF

         SELECT jibwelltmp
         APPEND FROM DBF('temp')
         USE IN temp

         *  If a New Run, get the list of owners from wellinv; otherwise, from disbhist
         IF THIS.nrunno = 0
            SELECT  cownerid ;
               FROM wellinv ;
               WHERE cWellID IN (SELECT cID FROM SELECTED) ;
               INTO CURSOR temp ;
               ORDER BY cownerid ;
               GROUP BY cownerid
         ELSE
            SELECT  cownerid ;
               FROM disbhist  ;
               WHERE cWellID IN (SELECT cID FROM SELECTED) ;
               AND nrunno = THIS.nrunno  ;
               AND crunyear = THIS.crunyear  ;
               AND cRecType = 'J'  ;
               INTO CURSOR temp ;
               ORDER BY cownerid ;
               GROUP BY cownerid
         ENDIF

         GO TOP
         THIS.cbegownerid = cownerid
         GO BOTT
         THIS.cendownerid = cownerid

         SELECT jibowntmp
         APPEND FROM DBF('temp')
         USE IN temp
   ENDCASE

   IF m.goApp.lqbversion AND m.goApp.oqb.lqbactive
      * get a message set request object (version 3.0 xml)
      THIS.orequest = m.goApp.oqb.oQBRequest

      * set the on error attribute for the request
      THIS.orequest.ATTRIBUTES.onerror = 1

      * Clear any previous requests
      THIS.orequest.ClearRequests()
   ENDIF

   WAIT CLEAR

   RETURN (DODEFAULT())
   ENDPROC

   *-- Calculates the closing summary report.
   **********************************************************
   PROCEDURE BuildSummary
   **********************************************************
   LOCAL llReturn

   llReturn = .F.

   CREATE CURSOR summary_cat ;
      (cCustId       C(10), ;
      cTaxCode      C(2), ;
      ctaxdesc      C(30), ;
      cexpcode      C(4), ;
      cExpCateg     C(30), ;
      cWellID       C(10), ;
      cwellname     C(30), ;
      nInterest     N(11, 7), ;
      namount       N(12, 2), ;
      cInvNum       C(15), ;
      nrunno        I, ;
      crunyear      C(4), ;
      djibdate      D, ;
      dDueDate      D, ;
      njibtotal     N(12, 2), ;
      nprevbal      N(12, 2), ;
      nPayments     N(12, 2))
   INDEX ON cCustId + cTaxCode + cWellID TAG billsum

   CREATE CURSOR summary_well ;
      (cCustId      C(10), ;
      cCustName    C(60), ;
      ccustname2   C(60), ;
      caddr1       C(60), ;
      caddr2       C(60), ;
      caddr3       C(60), ;
      cWellID      C(10), ;
      cwellname    C(30), ;
      namount      N(12, 2), ;
      cInvNum      C(15), ;
      nrunno       I, ;
      crunyear     C(4), ;
      djibdate     D, ;
      dDueDate     D, ;
      njibtotal    N(12, 2), ;
      nprevbal     N(12, 2), ;
      nPayments    N(12, 2))
   INDEX ON cCustId + cWellID TAG wellsum

   SELECT  cCustId, cTaxCode, ctaxdesc, SPACE(4) AS cexpcode, cExpCateg, ;
      cWellID, cwellname, SUM(nexpamount) namount, nInterest ;
      FROM jibinv ;
      INTO CURSOR temp READWRITE ;
      ORDER BY cCustId, cTaxCode, cWellID ;
      GROUP BY cCustId, cTaxCode, cWellID

   SELECT temp
   SCAN
      m.cExpCateg = cExpCateg
      SELECT expcat
      LOCATE FOR ccateg = m.cExpCateg
      IF FOUND()
         SELECT temp
         REPLACE cexpcode WITH expcat.cCatCode
      ENDIF
   ENDSCAN

   SELECT summary_cat
   APPEND FROM DBF('temp')

   SELECT  cCustId, cCustName, ccustname2, caddr1, caddr2, caddr3, ;
      cWellID, cwellname, SUM(nexpamount) AS namount ;
      FROM jibinv ;
      INTO CURSOR temp ;
      ORDER BY cCustId, cWellID ;
      GROUP BY cCustId, cWellID

   SELECT summary_well
   APPEND FROM DBF('temp')

   llReturn = RECCOUNT() > 0

   THIS.CheckCancel()

   RETURN llReturn

   ENDPROC

   *-- Prepayment Processing
   **********************************************************
   PROCEDURE prepay_process
   **********************************************************
   LPARAMETERS tcOwnerID, tcWellID, tnAmount, tcBatch
   LOCAL lcLastRun, lcLastYear, lnLastRun, lnBalance, lnUsed
   LOCAL llReturn, loError

   * Finds out the balance of prepayments in the well and compares
   * it to the current well total and processes the amount that it
   * needs to cover the current expenses

   llReturn = .T.

   TRY

      llReturn = THIS.PrePayBalance(tcOwnerID, tcWellID)
      IF NOT llReturn
         EXIT
      ENDIF
      * Store original amount
      lnamount    = tnAmount
      lnBalance = 0

      * Get the overall balance for the owner
      SELECT SUM(namount) AS ntotalbal, cAcctNo FROM prepaybal INTO CURSOR tempbal

      IF THIS.lclose AND tempbal.ntotalbal # 0
         SELECT prepaybal
         SCAN FOR namount # 0
            SCATTER MEMVAR

            * Figure out how much we can cover
            IF m.namount > lnamount
               lnUsed   = lnamount
               lnamount   = 0
            ELSE
               lnUsed   = m.namount
               lnamount   = lnamount - lnUsed
            ENDIF

            * If the run is being closed, add the used record to prepayd

            llReturn = THIS.PrePayUse(tcOwnerID, tcWellID, lnUsed, m.cbatch)
            IF NOT llReturn
               EXIT
            ENDIF
         ENDSCAN
      ENDIF

      lnamount    = tnAmount
      lnBalance = 0
      SELECT tempbal
      SCAN FOR ntotalbal # 0
         SCATTER MEMVAR
         * Figure out how much we can cover
         IF m.ntotalbal > lnamount
            lnUsed   = lnamount
            lnamount   = 0
         ELSE
            lnUsed   = m.ntotalbal
            lnamount   = lnamount - lnUsed
         ENDIF
         * Insert a detail line in jibinvd for the prepayment used
         *  Make sure we have a good key for the invoice detail table
         m.cidInvD    = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
         SET DELETED OFF
         SWSELECT('invdet', .T.)
         SET ORDER TO cidInvD
         IF SEEK(m.cidInvD)
            GO BOTT
            ocounter          = THIS.oregistry.lockcounter('%Shared.Counters.Invoice Detail')
            m.ccountervalue = THIS.oregistry.getcounter(ocounter)
            IF invdet.cidInvD >= m.ccountervalue
               THIS.oregistry.setcounter(ocounter, invdet.cidInvD)
               THIS.oregistry.updatecounter(ocounter)
            ENDIF
            THIS.oregistry.unlockcounter(ocounter)
            m.cidInvD = THIS.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
         ENDIF
         SET DELETED ON
         m.cItemId = '{PAY'

         lnBalance = m.ntotalbal - lnUsed
         IF lnBalance > 0
            m.cItemDesc  = 'Balance remaining: ' + TRANSFORM(lnBalance, '$$$,$$$,$$$.99')
         ELSE
            m.cItemDesc  = 'Prepayment Applied - Bal: 0'
         ENDIF
         m.cTaxCode    = '{P'
         m.nPrice       = lnUsed * -1
         m.nInterest    = 100
         m.nQuantity    = 1
         m.nExtension = lnUsed * -1
         m.nDiscPct    = 0
         m.nDiscount    = 0
         m.cUnitNo    = tcWellID
         m.cdeptno    = ' '
         m.cTaxable    = 'E'
         m.cPriceCode = '1'
         m.cMeasure    = ' '
         m.lDeleted    = .F.
         m.cAcctNo    = m.cAcctNo
         m.cpayee       = " "
         m.cbatch       = tcBatch
         IF m.nExtension # 0
            INSERT INTO jibtempd FROM MEMVAR

            SWSELECT('jibtemph')
            LOCATE FOR cbatch == m.cbatch
            IF FOUND()
               REPLACE nInvTot WITH nInvTot + m.nExtension, ;
                  nInvBal WITH nInvBal + m.nExtension, ;
                  nSubTotal WITH nSubTotal + m.nExtension
            ENDIF
         ENDIF
      ENDSCAN

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'PrePay_Process', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('PrePay_Process', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn


   *-- Calculates the prepayment balance for a well
   **********************************************************
   PROCEDURE PrePayBalance
   **********************************************************
   LPARAMETERS tcOwnerID, tcWellID
   LOCAL lcRunNo, ldPostDate, lnamount, llReturn, loError

   llReturn = .T.

   TRY
      SWSELECT('prepayd')
      SWSELECT('prepayh')

      * Get the balance as of the given post date
      SELECT  prepayd.cbatch, prepayd.deffdate, prepayd.cWellID, prepayd.cAcctNo, ;
         SUM(IIF(prepayd.cRecType = 'P' OR prepayd.lmanual, prepayd.namount, prepayd.namount * -1)) AS namount ;
         FROM prepayd ;
         JOIN prepayh ;
         ON prepayd.cbatch = prepayh.cbatch ;
         WHERE prepayh.cownerid == tcOwnerID ;
         AND prepayd.cWellID == tcWellID ;
         AND prepayd.deffdate <= THIS.dacctdate ;
         INTO CURSOR prepaybal ;
         ORDER BY prepayh.cownerid, prepayd.cWellID, prepayd.cAcctNo;
         GROUP BY prepayh.cownerid, prepayd.cWellID, prepayd.cAcctNo

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'PrePayBalance', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('PrePayBalance', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn

   ENDPROC

   *-- Adds prepayment use records to mark used prepayments
   **********************************************************
   PROCEDURE PrePayUse
   **********************************************************
   LPARAMETERS tcOwnerID, tcWellID, tnAmount, tcBatch
   LOCAL m.namount, m.cownerid, m.cWellID, m.nrunno, m.crunyear, m.cRecType, m.deffdate
   LOCAL llReturn, loError, m.cbatch

   llReturn = .T.

   TRY

      IF tnAmount = 0
         llReturn = .T.
         EXIT
      ENDIF

      m.cbatch     = tcBatch
      m.cownerid = tcOwnerID
      m.cWellID  = cWellID
      m.nrunno     = THIS.nrunno
      m.crunyear = THIS.crunyear
      m.namount  = tnAmount
      m.cRecType = 'U'
      m.deffdate = THIS.dacctdate


      INSERT INTO prepayd FROM MEMVAR

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'PrePayUse', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE, '', loError
      THIS.ERRORMESSAGE('PrePayUse', loError.LINENO, 'JIBProc', loError.ERRORNO, loError.MESSAGE)
   ENDTRY

   THIS.CheckCancel()

   RETURN llReturn

   *********************************
   PROCEDURE PluggingFund
   *********************************

   IF NOT m.goApp.lPluggingModule
      RETURN
   ENDIF

   m.cdmbatch = THIS.cdmbatch
   m.nrunno     = THIS.nrunno
   m.crunyear = THIS.crunyear

   CREATE CURSOR PluggingFund ;
      (cWellID     C(10), ;
      cownerid    C(10), ;
      crunyear    C(4), ;
      nrunno      I, ;
      dacctdate   D, ;
      nplugging   N(12, 2), ;
      lmanual     L, ;
      cdmbatch    C(8))

   SELECT cownerid, ;
      cWellID,  ;
      hdate AS dacctdate, ;
      nplugexp AS nplugging, ;
      cRecType ;
      FROM disbhist WITH (BUFFERING = .T.) ;
      WHERE nrunno = m.nrunno AND ;
      crunyear = m.crunyear AND ;
      nplugexp # 0  AND ;
      cRecType = 'J' ;
      INTO CURSOR tempd

   SELECT tempd
   SCAN
      SCATTER MEMVAR
      INSERT INTO PluggingFund FROM MEMVAR
   ENDSCAN

   USE IN tempd

   TRY
      SET PROCEDURE TO CUSTOM\plugging.prg ADDITIVE
   CATCH
   ENDTRY

   oPlugging = CREATEOBJECT('plugging')

   IF VARTYPE(oPlugging) = 'O'
      llReturn = oPlugging.AddPluggingFundRecs('pluggingfund')
   ELSE
      llReturn = .F.
   ENDIF

   oPlugging = .NULL.

   RETURN llReturn


   ******************************
   FUNCTION CheckCancel
   ******************************

   IF THIS.lCanceled
      IF VARTYPE(THIS.oProgress) = 'O'
         THIS.oProgress.CLOSEProgress()
         THIS.oProgress = .NULL.
      ENDIF
      THIS.lCanceled = .F.
   ENDIF

   ENDPROC

   ***********************************
   PROCEDURE ERRORMESSAGE
   ***********************************
   LPARAMETERS tcMethod, tnLineNo, tcModule, tnErrorNo, tcMessage

   IF VERSION(2) = 2
      IF MESSAGEBOX('Error Encountered!' + CHR(10) + CHR(10) + ;
            'Error No: ' + TRANSFORM(tnErrorNo) + CHR(10) + ;
            'Method: ' + tcMethod + CHR(10) + ;
            'Line No: ' + TRANSFORM(tnLineNo) + CHR(10) + ;
            'Message: ' + tcMessage + CHR(10) + CHR(10) + ;
            'Enter Debug Mode?', 36, 'Debug Error') = 6
         SET STEP ON
      ENDIF
   ELSE
      DO errorlog WITH 'JIB Processing', tnLineNo, 'JIBProc', tnErrorNo, tcMessage, ''
      MESSAGEBOX('Unable to complete the processing at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDIF
   ENDPROC

********************************************
   PROCEDURE JIBStatements
********************************************
      LPARAMETERS tcyear, ;
         tnRunNo, ;
         tlSelected, ;
         tdacctdate, ;
         tcGroup, ;
         tcOwner1, ;
         tcOwner2, ;
         tcSortOrder, ;
         tlSummary, ;
         tlIncEmail, ;
         tlEmail, ;
         tnDataSessionID

      LOCAL tcperiod, lljibnotes
      LOCAL laRpts[1], lcCust1, lcCust2, lcYear, ldDate1, ldDate2, ldPmtRcv, llGetFormats, llNoJIBBal
      LOCAL llPrintDesc, llReturn, llSummaryRet, lnFiles, lnPmtAmt, lnrunno, lnX
      LOCAL llFormatError, loError, llSelected

      llReturn = .T.

      TRY

* Check to see if we need new report formats
         lnFiles = ADIR(laRpts, m.goApp.crptsfolder + '*.frx')

         llGetFormats = .F.

         IF lnFiles > 0
            FOR lnX = 1 TO lnFiles
               IF LOWER(laRpts[lnx, 1]) = 'dmrojibrun.frx'
                  IF laRpts[lnx, 3] < {1/5/2019}
                     llGetFormats = .T.
                     lnX          = lnFiles + 1
                  ENDIF
               ENDIF
            ENDFOR
         ENDIF

         IF NOT tlSelected
            SELECT cownerid AS cID FROM investor ;
               INTO CURSOR SELECTED ;
               WHERE BETWEEN(cownerid,tcOwner1,tcOwner2) ;
               ORDER BY cID
         ENDIF

         SWSELECT('options')
         llPrintDesc = lacctdesc
         lljibnotes  = ljibnotes
*  Check to see if the previous jib balances should be printed on the statement
         llNoJIBBal = lNoJIBBal

         IF THIS.MAIN()

            SWSELECT('invhdr')
            SCAN FOR cInvType <> 'J'
               m.cownerid = cCustId
               SWSELECT('investor')
               SET ORDER TO cownerid
               IF SEEK(m.cownerid)
                  SWSELECT('invhdr')
                  REPL cInvType WITH 'J'
               ENDIF
            ENDSCAN

**********************************************************
*  Create the jib invoice work file
**********************************************************
            CREATE CURSOR jibinv   ;
               (cCustId    C(10),   ;
               cpagebreak  C(10), ;
               cCustName  C(40),   ;
               ccustname2 C(40),   ;
               caddr1     C(40),   ;
               caddr2     C(40),   ;
               caddr3     C(40),   ;
               cidTerm    C(8),    ;
               nstmttype  I,       ;
               lWellPage  L,       ;
               djibdate   D,       ;
               dDueDate   D,       ;
               dDiscDate  D,       ;
               nDiscPct   N(5, 2),  ;
               cInvNum    C(15),   ;
               cWellID    C(10),   ;
               cwellname  C(30),   ;
               ccounty    C(30),   ;
               cState     C(2),    ;
               cpayee     C(30),   ;
               dexpdate   D,       ;
               cExpCateg  C(40),   ;
               cNotes     C(40),   ;
               cCatCode   C(4),    ;
               nexptotal  N(12, 2), ;
               nexpamount N(12, 2), ;
               njibtotal  N(12, 2), ;
               nprevbal   N(12, 2), ;
               nPayments  N(12, 2), ;
               dpmtrcv    D,       ;
               cProdYear  C(4),    ;
               cProdPrd   C(2),    ;
               nrunno     I,       ;
               crunyear   C(4),    ;
               nInterest  N(11, 7), ;
               cTaxCode   C(2),    ;
               crefid     C(10), ;
               ctaxdesc   C(30), ;
               cSection   C(1))

**********************************************************
*  Build the jib invoice data
**********************************************************

            SELECT  jibtemph.cCustId, ;
               investor.cownname AS cCustName, ;
               IIF(investor.lchktosec, investor.cOwnName2, investor.cOwnName1) AS ccustname2, ;
               IIF(investor.lchktosec, investor.cAddress2a, investor.caddress1a) AS caddr1, ;
               IIF(investor.lchktosec, investor.cAddress2b, investor.caddress1b) AS caddr2, ;
               IIF(investor.lchktosec, TRIM(investor.ccity2) + ' ' + investor.cstate2 + ' ' + investor.czip2, TRIM(investor.ccity1) + ' ' + investor.cstate1 + ' ' + investor.czip1) AS caddr3, ;
               investor.cidTerm, ;
               investor.nstmttype, ;
               investor.lWellPage, ;
               jibtemph.dInvDate AS djibdate, ;
               jibtemph.dDueDate, ;
               jibtemph.cInvNum,  ;
               jibtemph.nrunno, ;
               jibtemph.crunyear, ;
               jibtempd.cUnitNo AS cWellID, ;
               wells.cwellname, ;
               wells.ccounty, ;
               wells.cState, ;
               SPACE(30) AS cExpCateg, ;
               jibtempd.dexpdate, ;
               jibtempd.cItemId AS cCatCode, ;
               jibtempd.cItemDesc AS cNotes, ;
               jibtempd.nExtension AS nexpamount, ;
               jibtemph.nInvTot AS njibtotal, ;
               jibtempd.nPrice  AS nexptotal, ;
               jibtempd.cpayee, ;
               jibtempd.cProdYear, ;
               jibtempd.cProdPrd, ;
               jibtempd.nInterest, ;
               jibtempd.cworkorder AS crefid, ;
               jibtempd.cTaxCode ;
               FROM jibtemph, jibtempd, investor, wells ;
               WHERE jibtemph.crunyear = tcyear ;
               AND jibtemph.nrunno     = tnRunNo ;
               AND cCustId IN (SELECT cID FROM SELECTED) ;
               AND jibtemph.cCustId = investor.cownerid ;
               AND jibtemph.cbatch  = jibtempd.cbatch ;
               AND jibtempd.cUnitNo = wells.cWellID ;
               INTO CURSOR temp  ;
               ORDER BY jibtemph.cCustId, jibtempd.cUnitNo, jibtempd.cTaxCode, jibtempd.cProdYear, jibtempd.cProdPrd, jibtempd.cItemId

            IF _TALLY = 0
               llReturn = .F.
               EXIT
            ENDIF

            SELECT jibinv
            APPEND FROM DBF('temp')

            SWSELECT('taxcodes')
            SET ORDER TO cTaxCode

            SELECT jibinv
            SCAN
* If we're not emailing statments
* exclude the owners that are marked
* to only get emailed statements.
               IF NOT tlIncEmail AND ;
                     NOT tlEmail
                  IF jibinv.nstmttype = 3
                     DELETE NEXT 1
                  ENDIF
               ENDIF

               m.cTaxCode  = jibinv.cTaxCode
               m.cExpCateg = jibinv.cExpCateg
               m.cCatCode  = jibinv.cCatCode
               m.cidTerm   = jibinv.cidTerm
               m.dDiscDate = jibinv.dDueDate

               SWSELECT('expcat')
               SET ORDER TO cCatCode
               IF SEEK(m.cCatCode)
                  m.cTaxCode  = cTaxCode
                  m.cExpCateg = ccateg
                  IF llPrintDesc
                     m.cExpCateg = cdescrip
                  ENDIF
*  Printing description from bills takes precedence, but they shouldn't be able to have both marked anyway
                  IF lljibnotes
                     m.cExpCateg = jibinv.cNotes
                  ENDIF
               ELSE
*  If there's no match, it may be something like a pre-pay, which already has a description built in.  Use it instead.
                  m.cExpCateg = jibinv.cNotes
               ENDIF
               m.dexpdate = jibinv.dexpdate
               SWSELECT('taxcodes')
               DO CASE
                  CASE SEEK(m.cTaxCode)
                     m.ctaxdesc = cdesc
                     m.cSection = 'A'
                  CASE m.cTaxCode == '{P'
                     m.ctaxdesc = '** ' + ALLTRIM(jibinv.cWellID) + ' Prepayment Applied **'
                     m.cSection = 'B'
                     m.dexpdate = {}
                  OTHERWISE
                     m.ctaxdesc = 'Lease Operating Expense '
                     m.cSection = 'A'
               ENDCASE
               SELECT jibinv
               REPL cTaxCode WITH m.cTaxCode, ;
                  ctaxdesc WITH m.ctaxdesc, ;
                  cExpCateg WITH m.cExpCateg, ;
                  cSection  WITH m.cSection, ;
                  dexpdate  WITH m.dexpdate
            ENDSCAN


            SELECT jibinv
            GO TOP
            lcCust1     = cCustId
            GO BOTT
            lcCust2     = cCustId

            IF tcyear = ' '
               tcyear = ALLT(STR(YEAR(tdacctdate)))
            ENDIF

            DO CASE
               CASE tnRunNo = 1
* If this is the 1st run of the year,
* Find out what the last run of last year was.
                  lcYear  = STR(VAL(tcyear) - 1, 4)
                  lnrunno = getrunno(lcYear, .F., 'J') - 1
               CASE tnRunNo = 2
                  lcYear  = tcyear
                  lnrunno = tnRunNo - 1
               OTHERWISE
*  If this is a new run, get the last run
*  for this year.
                  IF tnRunNo = 0
                     lnrunno = getrunno(tcyear, .F., 'J') - 1
                  ELSE
                     lnrunno  = tnRunNo - 1
                  ENDIF
                  lcYear = tcyear
            ENDCASE

            ldDate1 = tdacctdate - 1

**  Changing it to get the balance as of tdAcctDate-1, then get the payments since the last closing and add them back to the balance.
**  This lets them do adjustments to balances between the date of the last closing and tdAcctDate, and have them included in the balance,
**  while still reporting payments.  If no previous closings, tdDate2 becomes 30 days ago.

            SWSELECT('sysctl')
            SET ORDER TO yearrun DESC
            LOCATE FOR cgroup = tcGroup AND cTypeClose = 'J' AND crunyear + PADL(ALLTRIM(STR(nrunno)), 3, '0') <> tcyear + PADL(ALLTRIM(STR(tnRunNo)), 3, '0')
            IF FOUND()
               ldDate2 = sysctl.dacctdate
            ELSE
               ldDate2 = tdacctdate - 30
            ENDIF

            IF EMPTY(ldDate1)
               ldDate1 = ldDate2 - 30
            ENDIF

            IF m.goApp.lqbversion
               m.goApp.oqb.dacctdate    = tdacctdate
               m.goApp.oqb.ndatasession = tnDataSessionID
               llReturn                 = m.goApp.oqb.qbbal(ldDate2, tcGroup, lcYear, lnrunno, tcOwner1, tcOwner2)
               llReturn                 = m.goApp.oqb.qbpmts(ldDate2, ldDate1 + 1, tcOwner1, tcOwner2, .F., THISFORM.DATASESSIONID)
            ELSE
               llReturn = THIS.jibbal(ldDate1, tcGroup, lcYear, lnrunno, tcOwner1, tcOwner2)
            ENDIF

            IF NOT llReturn
               EXIT
            ENDIF

            IF NOT llNoJIBBal
               SELECT jibinv
               SCAN
                  m.cCustId  = cCustId
                  m.nprevbal = 0
                  m.caddr3   = caddr3
                  IF EMPTY(caddr2)
                     REPLACE caddr2 WITH m.caddr3, ;
                        caddr3 WITH ' '
                  ENDIF
                  SELECT jibbal
                  LOCATE FOR cCustId = m.cCustId
                  IF FOUND()
                     m.nprevbal = nCurrent + nDays30 + nDays60 + nDays90
                  ENDIF
                  lnPmtAmt = 0
                  ldPmtRcv = {}

                  SWSELECT('arpmthdr')
                  SCAN FOR cCustId = m.cCustId AND BETWEEN(dRecDate, ldDate2, ldDate1 + 1)
                     SWSELECT('arpmtdet')
                     IF lnPmtAmt <> m.nprevbal
                        SCAN FOR cbatch = arpmthdr.cbatch   &&  Only pick up payments for this batch
                           lnPmtAmt = lnPmtAmt + nAmtApp

*  To avoid getting a bogus "Last Payment Date" from a manually entered invoice, we have to match back
*  to invhdr and make sure it's got a cdmbatch value on it, meaning it came from a JIB closing - BH 03/15/12
                           SWSELECT('invhdr')
                           SET ORDER TO cbatch
                           IF SEEK(arpmtdet.cinvtoken)
                              IF NOT EMPTY(cdmbatch)
                                 ldPmtRcv = arpmthdr.dRecDate
                              ENDIF
                           ENDIF
                        ENDSCAN
                     ENDIF
                  ENDSCAN
                  SELECT jibinv
                  REPLACE nprevbal  WITH m.nprevbal + lnPmtAmt, ;
                     nPayments WITH lnPmtAmt, ;
                     dpmtrcv   WITH ldPmtRcv
               ENDSCAN
            ENDIF

            llReturn = DecimalInts('jibinv')

            IF tcSortOrder = '2'
               SELECT jibinv
               INDEX ON cCustId + cWellID + cSection + cTaxCode + cExpCateg + cProdYear + cProdPrd + cpayee TAG jibkey
            ELSE
               SELECT jibinv
               INDEX ON cCustId + cWellID + cSection + cTaxCode + cProdYear + cProdPrd + cExpCateg + cpayee TAG jibkey
            ENDIF

* Call the Summary processing if requested
            IF tlSummary
               llSummaryRet = THIS.BuildSummary()
            ENDIF

         ELSE
            llReturn = .F.
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'JIBStatements', loError.LINENO, 'Owner JIB Stmts', loError.ERRORNO, loError.MESSAGE
         MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn



   ENDPROC
ENDDEFINE
*
*-- EndDefine: jibproc
**************************************************







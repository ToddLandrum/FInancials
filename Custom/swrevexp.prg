**********************************
FUNCTION  PostIncome(tcBatch)
   **********************************
   LOCAL lcBatch, m.cOwnerID
   LOCAL lAPTran, lAllocated, lCSTran, lFixed, lafields[1], lcFilter, llFound, llGrossUnits, llReturn
   LOCAL lnetrev, loError, oGLMaint
   LOCAL cBatch, cCheckNo, cMemo, cPeriod, cRunYearJIB, cRunYearRev, cYear, ccatcode, ccateg
   LOCAL cexpclass, cidexpe, cidexph, cidexps, cidinch, cidinco, cidincs, cpayee, crefid, crevkey
   LOCAL csource, cvendorid, dExpDate, dPostDate, dRevDate, nAmount, nRunNo, nRunNoJIB, nRunNoRev
   LOCAL ntotalinc, nunits, oWellInv
   *******************************************************************
   *  Adds the income entries to the disbursement manager INCSUSP or
   *  INCOME tables depending on whether the production year and
   *  period are specified.
   *******************************************************************
   llReturn = .T.

   TRY

      oGLMaint = CREATEOBJECT('swglmaint')
      oWellInv = CREATEOBJECT('swbizobj_wellinv')
      lcBatch    = tcBatch
      swselect('csrcthdr')
      LOCATE FOR cBatch = lcBatch
      IF NOT FOUND()
         llReturn = .F.
         EXIT
      ENDIF

      m.cCheckNo = csrcthdr.cCheckNo

      swselect('income',.T.)
      = AFIELDS(lafields)
      CREATE CURSOR tempinc FROM ARRAY lafields

      swselect('incsusp',.T.)
      SCAN FOR cBatch = lcBatch
         DELETE NEXT 1
      ENDSCAN

      swselect('expsusp',.T.)
      SCAN FOR cBatch = lcBatch
         DELETE NEXT 1
      ENDSCAN

      * Remove Income entries
      SELECT income
      SCAN FOR cBatch == lcBatch
         m.cidinch = cidinch
         DELE NEXT 1
         SELECT income1
         llFound = .F.
         SCAN FOR cidinch == m.cidinch
            llFound = .T.
            EXIT
         ENDSCAN
      ENDSCAN
      * Remove Expense entries
      SELECT expense
      SCAN FOR cBatch == lcBatch
         m.cidexph = cidexph
         DELE NEXT 1
         swselect('expense',.F.,'expense1')
         llFound = .F.
         SCAN FOR cidexph == m.cidexph
            llFound = .T.
            EXIT
         ENDSCAN
      ENDSCAN

      swselect('revcat')
      SET ORDER TO crevtype

      swselect('csrctdet')
      lcFilter = FILTER()
      SET FILTER TO
      SCAN FOR cBatch == lcBatch AND lWellRcpt = .T.

         * Variable for whether this item should be grossed thru NetRev up or not.
         * Should be reset for each line - BH 08/02/2007
         m.lnetrev  = .T.

         SCATTER MEMVAR
         llGrossUnits = m.lGrossUnits
         m.dRevDate   = csrcthdr.ddate
         
         IF EMPTY(m.cProdYear) OR EMPTY(m.cProdPeriod)
            m.cYear   = oGLMaint.getperiod(m.dRevDate, .T.)
            m.cPeriod = oGLMaint.getperiod(m.dRevDate, .F.)
         ELSE
            m.cYear   = m.cProdYear
            m.cPeriod = m.cProdPeriod
         ENDIF
         
         
         IF EMPTY(m.cDeck) AND NOT EMPTY(m.cProdYear) AND NOT EMPTY(m.cProdPeriod) AND NOT m.goApp.lSendToAllocate
            m.cDeck = oWellInv.DOIDeckNameLookup(m.cProdYear,m.cProdPeriod,m.cWellID)
         ENDIF    
         
         m.crevkey     = csrcthdr.cid

         *  If the well is not valid, don't try to create income records
         SELECT wells
         SET ORDER TO cwellid
         IF NOT SEEK(m.cwellid)
            LOOP
         ENDIF

         IF NOT EMPTY(m.cOwnerID)
            m.lnetrev = .F.
         ENDIF

         swselect('revcat')
         IF SEEK(m.ctype)
            DO CASE
               CASE m.ctype = 'BBL'
                  m.csource = 'BBL'
                  IF NOT llGrossUnits
                     m.nunits = swNetRevenue(m.cwellid, m.nunits, 'O', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
                  ENDIF
                  IF m.lnetrev
                     m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, 'O', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
                  ELSE
                     m.ntotalinc = m.nAmount
                  ENDIF

               CASE m.ctype = 'MCF'
                  m.csource = 'MCF'
                  IF NOT llGrossUnits
                     m.nunits = swNetRevenue(m.cwellid, m.nunits, 'G', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
                  ENDIF
                  IF m.lnetrev
                     m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, 'G', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
                  ELSE
                     m.ntotalinc = m.nAmount
                  ENDIF

               CASE m.ctype = 'OTH'
                  m.csource = 'OTH'
                  IF NOT llGrossUnits
                     m.nunits = swNetRevenue(m.cwellid, m.nunits, 'P', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
                  ENDIF
                  m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, 'P', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)

               CASE m.ctype = 'MISC1'
                  m.csource = 'MISC1'
                  IF m.lnetrev
                     m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, '1', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
                  ELSE
                     m.ntotalinc = m.nAmount
                  ENDIF

                  IF m.lnetrev AND NOT llGrossUnits
                     m.nunits = swNetRevenue(m.cwellid, m.nunits, '1', .T., .T.,.F.,.F.,.F.,.F.,.F.,m.cDeck)
                  ENDIF

               CASE m.ctype = 'MISC2'
                  m.csource = 'MISC2'
                  IF m.lnetrev
                     m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, '2', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
                  ELSE
                     m.ntotalinc = m.nAmount
                  ENDIF

                  IF m.lnetrev AND NOT llGrossUnits
                     m.nunits = swNetRevenue(m.cwellid, m.nunits, '2', .T., .T.,.F.,.F.,.F.,.F.,.F.,m.cDeck)
                  ENDIF

               CASE m.ctype = 'TRANS'
                  m.csource   = 'TRANS'
                  m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, 'T', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)

                  IF m.lnetrev AND NOT llGrossUnits
                     m.nunits = swNetRevenue(m.cwellid, m.nunits, 'T', .T., .T.,.F.,.F.,.F.,.F.,.F.,m.cDeck)
                  ENDIF

               CASE m.ctype = 'OTAX1' OR m.ctype = 'OTAX2' OR m.ctype = 'OTAX3' OR m.ctype = 'OTAX4'
                  m.csource = m.ctype
                  IF NOT llGrossUnits
                     m.nunits = swNetRevenue(m.cwellid, m.nunits, 'O' + RIGHT(ALLT(m.csource), 1), .T., .T., .F., m.cOwnerID, .T.,.F.,.F.,m.cDeck)
                  ENDIF
                  IF m.lnetrev
                     m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, 'O' + RIGHT(ALLT(m.csource), 1), .T., .T., .F., m.cOwnerID, .T.,.F.,.F.,m.cDeck)
                  ELSE
                     m.ntotalinc = m.nAmount
                  ENDIF

               CASE m.ctype = 'GTAX1' OR m.ctype = 'GTAX2' OR m.ctype = 'GTAX3' OR m.ctype = 'GTAX4'
                  m.csource = m.ctype
                  IF NOT llGrossUnits
                     m.nunits = swNetRevenue(m.cwellid, m.nunits, 'G' + RIGHT(ALLT(m.csource), 1), .T., .T., .F., m.cOwnerID, .T.,.F.,.F.,m.cDeck)
                  ENDIF
                  IF m.lnetrev
                     m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, 'G' + RIGHT(ALLT(m.csource), 1), .T., .T., .F., m.cOwnerID, .T.,.F.,.F.,m.cDeck)
                  ELSE
                     m.ntotalinc = m.nAmount
                  ENDIF

               CASE m.ctype = 'PTAX1' OR m.ctype = 'PTAX2' OR m.ctype = 'PTAX3' OR m.ctype = 'PTAX4'
                  m.csource = m.ctype
                  IF NOT llGrossUnits
                     m.nunits = swNetRevenue(m.cwellid, m.nunits, 'P', .T., .T., .F., m.cOwnerID, .T.,.F.,.F.,m.cDeck)
                  ENDIF
                  IF m.lnetrev
                     m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, 'P', .T., .T., .F., m.cOwnerID, .T.,.F.,.F.,m.cDeck)
                  ELSE
                     m.ntotalinc = m.nAmount
                  ENDIF

               CASE m.ctype = 'COMP'
                  m.csource = 'COMP'
                  IF m.lnetrev
                     m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, 'G', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
                  ELSE
                     m.ntotalinc = m.nAmount
                  ENDIF

               CASE m.ctype = 'GATH'
                  m.csource = 'GATH'
                  IF m.lnetrev
                     m.ntotalinc = swNetRevenue(m.cwellid, m.nAmount, 'G', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
                  ELSE
                     m.ntotalinc = m.nAmount
                  ENDIF
            ENDCASE
         ELSE
            * Don't post prior deficits to the expense file.  The suspense from a prior period
            * will be processed when the run is closed. The PDEF is just there to make the 
            * receipt balance.
            IF m.cType = 'PDEF'
               LOOP
            ENDIF 
            swselect('expcat')
            SET ORDER TO ccatcode
            IF SEEK(LEFT(m.ctype, 4))
               m.cexpclass = cexpclass
               m.ccateg    = ccateg
               m.ccatcode  = ccatcode
               IF EMPTY(m.crefid)
                  m.crefid    = m.cCheckNo
               ENDIF
               IF m.ctype = 'MKTG'
                  m.nAmount = swNetRevenue(m.cwellid, m.nAmount, 'G', .T., .T., .F., m.cOwnerID,.F.,.F.,.F.,m.cDeck)
               ELSE
                  m.nAmount   = swNetExp(m.nAmount, m.cwellid, .F., expcat.cexpclass, 'B', .F., m.cOwnerID,.F.,m.cDeck)
               ENDIF
               m.nAmount   = m.nAmount * -1
               IF EMPTY(m.cpayee)
                  m.cpayee    = csrcthdr.cname
               ENDIF
               m.cvendorid = csrcthdr.cid
               m.lAPTran   = .T.
               m.lFixed    = .F.
               m.cBatch    = lcBatch
               m.dPostDate = m.dRevDate
               m.dExpDate  = m.dRevDate
               m.cMemo     = ''
               IF NOT EMPTY(m.cProdYear) AND NOT EMPTY(m.cProdPeriod) AND NOT m.goApp.lSendToAllocate
                  m.cidexph = m.goApp.oRegistry.IncrementCounter('%Shared.Counters.Batch')
                  m.cidexpe = m.goApp.oRegistry.IncrementCounter('%Shared.Counters.Expense')
                  SET DELETED OFF
                  swselect('expense',.T.)
                  SET ORDER TO cidexpe
                  DO WHILE SEEK(m.cidexpe)
                     m.cidexpe = m.goApp.oRegistry.IncrementCounter('%Shared.Counters.Expense')
                  ENDDO
                  SET DELETED ON
                  SELECT expense
                  m.nRunNoRev   = 0
                  m.nRunNoJIB   = 0
                  m.cRunYearRev = ''
                  m.cRunYearJIB = ''
                  m.cYear       = m.cProdYear
                  m.cPeriod     = m.cProdPeriod
                  INSERT INTO expense FROM MEMVAR
               ELSE
                  m.cidexps    = m.goApp.oRegistry.IncrementCounter('%Shared.Counters.Expense')
                  SET DELETED OFF
                  swselect('expsusp',.T.)
                  SET ORDER TO cidexps
                  DO WHILE SEEK(m.cidexps)
                     m.cidexps    = m.goApp.oRegistry.IncrementCounter('%Shared.Counters.Expense')
                  ENDDO
                  SET DELETED ON
                  m.nRunNoRev   = 0
                  m.nRunNoJIB   = 0
                  m.cRunYearRev = ''
                  m.cRunYearJIB = ''
                  m.cYear       = m.cProdYear
                  m.cPeriod     = m.cProdPeriod
                  INSERT INTO expsusp FROM MEMVAR
               ENDIF
            ENDIF
            LOOP
         ENDIF

         m.crefid    = m.cCheckNo
         m.lCSTran   = .T.
         m.cBatch    = lcBatch
         m.dPostDate = m.dRevDate
         m.cMemo     = ''

         IF NOT EMPTY(m.cProdYear) AND NOT EMPTY(m.cProdPeriod) AND NOT m.goApp.lSendToAllocate
            m.cidinch = m.goApp.oRegistry.IncrementCounter('%Shared.Counters.Batch')
            m.cidinco = GetNextPK('Income')
            m.nRunNo  = 0
            m.cYear   = m.cProdYear
            m.cPeriod = m.cProdPeriod
            INSERT INTO income FROM MEMVAR
         ELSE
            m.cidincs = GetNextPK('Income')
            m.lAllocated = .F.
            m.nRunNo     = 0
            m.cYear      = m.cProdYear
            m.cPeriod    = m.cProdPeriod
            INSERT INTO incsusp FROM MEMVAR
         ENDIF
      ENDSCAN

      SELECT csrctdet
      SET FILTER TO &lcFilter
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'PostIncome', loError.LINENO, 'swWellRevExp', loError.ERRORNO, loError.MESSAGE, '', loError

   ENDTRY

   oGLMaint = .NULL.

   RETURN llReturn

ENDPROC

**************************************
FUNCTION DelReceipt(tcBatch, tlQBPost)
   **************************************
   *
   * Delete income, expense and also QB Posting
   * from a receipt with the given batch
   *
   LOCAL lcBatch, llReturn, oGLMaint

   #define tdtJournalEntry 15
   
   swselect('csrcthdr')
   swselect('csrctdet')
   swselect('income',.T.)
   swselect('incsusp',.T.)
   swselect('expense',.T.)
   swselect('expsusp',.T.)
   swselect('checks',.T.)

   SELECT csrcthdr
   LOCATE FOR cBatch = tcBatch
   IF NOT FOUND()
      RETURN .F.
   ENDIF

   llReturn = .T.

   TRY

      oGLMaint = CREATEOBJECT('swglmaint')

      lcBatch = tcBatch
      lcidchec = csrcthdr.cidchec
      TRY
         lcDMBatch = csrcthdr.cDMBatch
      CATCH
      ENDTRY

      IF NOT m.goApp.oQB.lQBActive AND NOT EMPTY(csrcthdr.ctxnid)
         MESSAGEBOX('The link to QuickBooks is not active. This receipt was originally posted to QuickBooks. ' + ;
            'It cannot be deleted while the link is not active.',16,'Delete Receipt')
         llReturn = .F.
         EXIT
      ENDIF

      *  Check to see if revenue entered for wells was allocated
      *  If so, and the period isn't closed, delete it.  Otherwise
      *  let the user know he can't delete this entry.
      SELECT income
      LOCATE FOR cBatch == lcBatch AND nRunNo <> 0
      IF FOUND()
         MESSAGEBOX('At least one revenue entry on this receipt has been allocated to a well and closed.  ' + ;
            'No changes are allowed.',16,'Delete Receipt')
         llReturn = .F.
         EXIT
      ENDIF

      * Remove Income entries
      SELECT income
      SCAN FOR cBatch == lcBatch
         m.cidinch = cidinch
         DELE NEXT 1
         SELECT income1
         llFound = .F.
         SCAN FOR cidinch == m.cidinch
            llFound = .T.
            EXIT
         ENDSCAN
      ENDSCAN

      * Remove unallocated income entries
      SELECT incsusp
      SCAN FOR cBatch = lcBatch
         DELETE NEXT 1
      ENDSCAN

      * Remove expenses netted out of this receipt
      SELECT expense
      SCAN FOR cBatch = lcBatch
         DELETE NEXT 1
      ENDSCAN

      * Remove expenses netted out of this receipt
      SELECT expsusp
      SCAN FOR cBatch = lcBatch
         DELETE NEXT 1
      ENDSCAN

      IF m.goApp.lPartnershipMod
         swselect('partnerpost')
         LOCATE FOR cDMBatch = lcDMBatch
         IF FOUND()
            SCAN FOR cDMBatch == lcDMBatch
               REPLACE lPosted WITH .F., tPosted WITH {}
            ENDSCAN
         ENDIF
      ENDIF

      *  Delete the deposit entry from the check register
      oGLMaint.delcheck(lcBatch,.T.)

      IF m.goApp.lQBVersion AND tlQBPost AND NOT EMPTY(csrcthdr.ctxnid)
         llReturn = m.goApp.oQB.DeleteTxnID(csrcthdr.ctxnid, tdtJournalEntry)
      ENDIF

      IF llReturn
         SELECT income
         llReturn =TABLEUPDATE(.T.,.T.)
         SELECT expense
         llReturn =TABLEUPDATE(.T.,.T.)
         SELECT expsusp
         llReturn =TABLEUPDATE(.T.,.T.)
         SELECT incsusp
         llReturn =TABLEUPDATE(.T.,.T.)
         SELECT csrctdet
         llReturn =TABLEUPDATE(.T.,.T.)
         SELECT csrcthdr
         llReturn =TABLEUPDATE(.T.,.T.)
         SELECT checks
         llReturn =TABLEUPDATE(.T.,.T.)

         TRY
            IF m.goApp.lPartnershipMod
               llReturn = TABLEUPDATE(.T.,.T.,'Partnerpost')
            ENDIF
         CATCH
         ENDTRY
      ENDIF

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'DelReceipt', loError.LINENO, 'swRevExp', loError.ERRORNO, loError.MESSAGE
      MESSAGEBOX('Unable to delete the receipt posting at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY

   WAIT CLEAR

   oGLMaint = .NULL.

   RETURN llReturn


ENDPROC

**********************
PROCEDURE swNetExp
   **********************
   LPARA tnGrossAmt, tcwellid, tlDown, tcClass, tcJIB, tlRange, tcOwnerid, tcCatCode, tcDeck
   *
   *  tcClass     = the expense class for the given expense category
   *  tcJIB    B  = Net out only "Dummy" owners
   *           J  = Net out "Dummy" and Net interests
   *           N  = Net out "Dummy" and JIB interests
   *           D  = Net out only JIB interests
   *           DN = Net out only Net interests
   *
   LOCAL lcCurrent, lnDummyInt, llEntNet, lnCount, m.lJIBOnly, m.cOwnerID, lcWhere
   LOCAL lJIBOnly, lcownerid, llNoDummy, llNoJIB, lnGross, lnReturn, loError

   TRY

      lcCurrent   = ALIAS()
      lnReturn   = tnGrossAmt

      IF NOT INLIST(tcJIB, 'B', 'J', 'N', 'D', 'DN')
         EXIT
      ENDIF

      IF VARTYPE(tcCatCode) # 'C'
         tcCatCode = '@@@@'
      ENDIF

      IF EMPTY(tcDeck)
         swselect('doidecks')
         LOCATE FOR cwellid = tcwellid AND lDefault
         IF FOUND()
            tcDeck = cDeck
         ELSE
            LOCATE FOR cwellid = tcwellid AND cDeck = 'ORIGINAL'
            IF FOUND()
               tcDeck = cDeck
            ELSE
               * Just return the amount passed. If we don't have a deck we can't net
               EXIT
            ENDIF
         ENDIF
      ENDIF

      * Check to see if the category code passed is a JIB only code
      swselect('expcat')
      SET ORDER TO ccatcode
      IF SEEK(tcCatCode)
         m.lJIBOnly = lJIBOnly
      ELSE
         m.lJIBOnly = .F.
      ENDIF

      IF NOT INLIST(tcClass, '0', '1', '2', '3', '4', '5', 'A', 'B', 'P','G','O')
         *   WAIT WIND NOWAIT 'An invalid expense class was passed to distproc.netexp....'
         tcClass = '0'
      ENDIF

      IF TYPE('tcOwnerID') # 'C'
         tcOwnerid = ''
      ENDIF

      IF TYPE('tnGrossAmt') # 'N'
         lnReturn = 0
         EXIT
      ENDIF

      IF TYPE('tcWellID') # 'C'
         lnReturn = 0
         EXIT
      ENDIF

      IF NOT EMPTY(tcOwnerid)
         DO CASE
            CASE tcJIB = 'J'
               swselect('wellinv')
               LOCATE FOR cOwnerID = tcOwnerid AND cwellid = tcwellid AND ctypeinv = 'W' AND cDeck == tcDeck
               IF FOUND() AND NOT ljib AND NOT m.lJIBOnly
                  lnReturn = 0
                  EXIT
               ELSE
                  lnReturn = tnGrossAmt
                  EXIT
               ENDIF
            CASE tcJIB = 'N'
               swselect('wellinv')
               LOCATE FOR cOwnerID = tcOwnerid AND cwellid = tcwellid AND ctypeinv = 'W' AND cDeck == tcDeck
               IF FOUND() AND ljib
                  lnReturn = 0
                  EXIT
               ELSE
                  lnReturn = tnGrossAmt
                  EXIT
               ENDIF
            OTHERWISE
               lnReturn = tnGrossAmt
               EXIT
         ENDCASE
      ELSE
         * If we're netting out jibs make sure there are jib ints in the well
         * before we do the whole process. If there aren't, just return the
         * gross amount.
         IF tcJIB = 'D'
            swselect('wellinv')
            LOCATE FOR cwellid = tcwellid AND ljib
            IF NOT FOUND()
               lnReturn = tnGrossAmt
               EXIT
            ENDIF
         ENDIF
         IF tcJIB = 'N'
            llNoDummy = .T.
            llNoJIB     = .F.
            swselect('wellinv')
            SELECT cOwnerID FROM wellinv WHERE cwellid == tcwellid AND cDeck == tcDeck INTO CURSOR wellowns
            SELECT wellowns
            SCAN
               lcownerid = cOwnerID
               swselect('investor')
               SET ORDER TO cOwnerID
               IF SEEK(lcownerid) AND lDummy
                  llNoDummy = .F.
                  SELECT wellowns
                  GO BOTTOM
               ENDIF
            ENDSCAN
            SELECT wellinv
            LOCATE FOR cwellid = tcwellid AND ljib AND cDeck == tcDeck
            IF NOT FOUND()
               llNoJIB = .T.
            ENDIF
            IF llNoDummy AND llNoJIB
               lnReturn = tnGrossAmt
               EXIT
            ENDIF
         ENDIF
      ENDIF

      IF TYPE('tcClass') # 'C'
         tcClass = '0'
      ENDIF
      IF TYPE('tcJIB') # 'C'
         tcJIB = 'B'
      ENDIF

      swselect('wells')
      SET ORDER TO cwellid
      IF SEEK(tcwellid)
         IF cWellStat = 'V'
            *  If the well is an investment well return the amount passed
            *  because we don't want to have to setup a doi for investment
            *  wells.  They will report on whatever was entered for them.
            lnReturn = tnGrossAmt
            EXIT
         ENDIF
      ELSE
         *  The well wasn't found so don't try to net the amount down or gross it up
         lnReturn = tnGrossAmt
         EXIT
      ENDIF

      ***************************************************************************
      *  Initalize the work variables
      ***************************************************************************
      STORE 0 TO lnCount, lnDummyInt

      IF NOT m.lJIBOnly
         lcWhere  = "wellinv.lJib = .t."
         lcWhereF = "wellinv.lJIB = .f."
      ELSE
         lcWhere  = ".T."
         lcWhereF = ".F."
      ENDIF
      ***************************************************************************
      *  Sum the working interests for owners that are marked as dummy
      ***************************************************************************
      CREATE CURSOR tempwork ;
         (nworkint   N(11, 7))

      DO CASE
         CASE tcJIB == 'B'
            DO CASE
               CASE tcClass = '0'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nworkint AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND wellinv.ctypeinv  = 'W' ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = '1'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass1 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid  AND cDeck == tcDeck;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = '2'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass2 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = '3'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass3 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = '4'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass4 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = '5'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass5 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = 'A'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nACPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = 'B'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nBCPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = 'P'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nPlugPct AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = 'G'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevgas AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               CASE tcClass = 'O'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevoil AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

               OTHERWISE
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass5 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND investor.lDummy ;
                     INTO CURSOR tempy

            ENDCASE

         CASE tcJIB == 'D'
            DO CASE
               CASE tcClass = '0'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nworkint AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND wellinv.ctypeinv  = 'W' ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = '1'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass1 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = '2'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass2 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = '3'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass3 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = '4'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass4 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = '5'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass5 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = 'A'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nACPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = 'B'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nBCPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = 'P'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nPlugPct AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid  AND cDeck == tcDeck;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = 'G'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevgas AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy

               CASE tcClass = 'O'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevoil AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy


               OTHERWISE
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass5 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .T. ;
                     OR &lcWhere) ;
                     INTO CURSOR tempy
            ENDCASE

         CASE tcJIB == 'DN'
            DO CASE
               CASE tcClass = '0'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nworkint AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND wellinv.cOwnerID = investor.cOwnerID ;
                     AND wellinv.ctypeinv  = 'W' ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = '1'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass1 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = '2'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass2 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = '3'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass3 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = '4'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass4 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = '5'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass5 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = 'A'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nACPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = 'B'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nBCPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = 'P'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nPlugPct AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = 'G'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevgas AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               CASE tcClass = 'O'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevoil AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy

               OTHERWISE
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass5 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (wellinv.ljib = .F. ;
                     OR &lcWhereF) ;
                     INTO CURSOR tempy
            ENDCASE

         CASE tcJIB == 'J'
            DO CASE
               CASE tcClass = '0'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nworkint AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND wellinv.ctypeinv  = 'W' ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhereF)) ;
                     INTO CURSOR tempy

               CASE tcClass = '1'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass1 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhereF)) ;
                     INTO CURSOR tempy

               CASE tcClass = '2'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass2 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhereF)) ;
                     INTO CURSOR tempy

               CASE tcClass = '3'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass3 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhereF)) ;
                     INTO CURSOR tempy

               CASE tcClass = '4'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass4 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhereF)) ;
                     INTO CURSOR tempy

               CASE tcClass = '5'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass5 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhereF)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'A'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nACPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'B'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nBCPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhereF)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'P'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nPlugPct AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhereF)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'G'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevgas AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhereF)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'O'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevoil AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhereF)) ;
                     INTO CURSOR tempy

               OTHERWISE
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass5 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID AND cDeck == tcDeck ;
                     WHERE wellinv.cwellid   = tcwellid ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .F. ;
                     AND &lcWhereF)) ;
                     INTO CURSOR tempy
            ENDCASE

         CASE tcJIB == 'N'
            DO CASE
               CASE tcClass = '0'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nworkint AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND wellinv.ctypeinv  = 'W' ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = '1'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass1 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = '2'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass2 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = '3'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass3 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = '4'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass4 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = '5'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nIntClass5 AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid  AND cDeck == tcDeck;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'A'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nACPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'B'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nBCPInt AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'P'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nPlugPct AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'G'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevgas AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               CASE tcClass = 'O'
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nrevoil AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy

               OTHERWISE
                  SELECT  wellinv.cOwnerID, ;
                     wellinv.nworkint AS nworkint ;
                     FROM wellinv ;
                     JOIN investor ;
                     ON wellinv.cOwnerID = investor.cOwnerID ;
                     WHERE wellinv.cwellid   = tcwellid AND cDeck == tcDeck ;
                     AND wellinv.ctypeinv  = 'W' ;
                     AND (investor.lDummy ;
                     OR (wellinv.ljib = .T. ;
                     OR &lcWhere)) ;
                     INTO CURSOR tempy
            ENDCASE
      ENDCASE

      IF _TALLY = 0
         SELECT (lcCurrent)
         swclose('tempy')
         swclose('tempwork')
         lnReturn = tnGrossAmt
         EXIT
      ENDIF

      SELECT tempy
      SCAN
         SCATTER MEMVAR
         INSERT INTO tempwork FROM MEMVAR
      ENDSCAN
      SELECT  SUM(nworkint) AS nworkint ;
         FROM tempwork ;
         INTO CURSOR tempw

      SELECT tempw
      GO TOP
      lnDummyInt = nworkint

      swclose('tempy')
      swclose('tempw')
      swclose('tempwork')

      ***************************************************************************
      *  Calculate the Gross amount from the net amount
      ***************************************************************************
      DO CASE
         CASE lnDummyInt < 100     && Dummy Interest Amount
            IF tlDown
               lnGross = ROUND((tnGrossAmt * ((100 - lnDummyInt) / 100)), 2)
            ELSE
               lnGross = ROUND((tnGrossAmt / ((100 - lnDummyInt) / 100)), 2)
            ENDIF

            lnReturn = lnGross
         CASE lnDummyInt >= 100    && Dummy Interest Amount
            lnReturn = 0
      ENDCASE
   CATCH TO loError
      lnReturn = 0
      DO errorlog WITH 'swNetExp', loError.LINENO, 'swUtils', loError.ERRORNO, loError.MESSAGE, '', loError
      MESSAGEBOX('Unable to complete the processing at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY

   SELECT (lcCurrent)

   RETURN lnReturn

ENDPROC

*********************************
PROCEDURE SWNetRevenue
   *********************************
   *
   *  Processes the revenue amount passed by either grossing it up or
   *  netting it down based on the value of parameter tlUp
   *
   *  Parameters:   tcWellID  = The well the revenue is for
   *                tnAmount  = The revenue amount
   *                tcType    = The type of revenue.  O = oil, G = gas, T = trans
   *                                                  1 = misc1, 2 = misc2, P = other
   *                                                  G1-G4 - Gas Taxes, O1-O4 - Oil Taxes
   *                tlUp      = .T. - gross the revenue up based on direct pays
   *                            .F. - net the revenue down
   *                tlDummy   = .T. - process the revenue based on "Dummy" owners as well as direct pays.
   *                tlDumOnly = .T. - process only the "Dummy" owners
   *                tcOwnerid = The owner id if a one-man item.
   *                tlTaxes   = .T. - the amount passed is a tax amount
   *                tlRange   = .T. - the amount is for a close run. Use history files.
   **********************************************************************************
   *-- Nets revenue or grosses revenue based upon directly paid owners.
      LPARA tcwellid, tnAmount, tcType, tlUp, tlDummy, tlDumOnly, tcOwnerid, tlTaxes, tlRange, tlExcludeExempt, tcDeck
      LOCAL lcCurrent, lnDirOilAmt, lnDirGasAmt, lnCount, lnTally, lnGross
      LOCAL llInvestment, lnDumMiscAmt, lcExact, llTax, lcDirectExpr, lcTaxExpr
      LOCAL lcExpr, llDirGasPurch, llDirOilPurch, llReturn, llroysevtx, lnDirGas, lnDirOil, lnPct
      LOCAL lnReturn, loError, lcAlias

      lnReturn = tnAmount
      lcAlias  = ALIAS()

      TRY
      
      * this is to keep netrev from being run when you know you'll never have dummy owners
      IF FILE('datafiles\dontnet.txt')
         llDontNet = .T.
      ELSE
         llDontNet = .F.
      ENDIF


         IF EMPTY(tcdeck)
            swselect('doidecks')
            LOCATE FOR cWellID = tcwellid AND lDefault
            IF FOUND()
               tcDeck = cdeck
            ELSE
               LOCATE FOR cWellID = tcwellid AND cdeck = 'ORIGINAL'
               IF FOUND()
                  tcDeck = cdeck
               ELSE
                  * Just return the amount passed. If we don't have a deck we can't net
                  EXIT
               ENDIF
            ENDIF
         ENDIF
         
         * If we're not supposed to net
         IF llDontNet OR EMPTY(tcDeck)
            lnReturn = tnAmount
            EXIT
         ENDIF
         
         lcCurrent = ALIAS()
         lnTally   = 0
         llTax     = .F.

         lcExact = SET('exact')
         SET EXACT OFF

         STORE 0 TO lnDirOilAmt, lnDirGasAmt, lnDumMiscAmt

         *
         * Check the tcOwnerID parm. If it was passed
         * return the original amount since it should
         * not be grossed up or netted down.
         *
         IF TYPE('tcOwnerID') # 'C'
            tcOwnerid = ''
         ELSE
            IF NOT EMPTY(tcOwnerid)
               lnReturn = tnAmount
               EXIT
            ENDIF
         ENDIF

         * Don't do any processing if the amount passed is zero.
         IF tnAmount = 0
            lnReturn = 0
            EXIT
         ENDIF

         STORE 0 TO lnCount, lnDirOil, lnDirGas, lnDumMiscAmt

         swselect('wells')
         SET ORDER TO cWellID
         IF SEEK(tcwellid)
            IF cwellstat = 'V'
               *  If the well is an investment well return the amount passed
               *  because we don't want to have to setup a doi for investment
               *  wells.  They will report on whatever was entered for them.
               lnReturn = tnAmount
               EXIT
            ELSE
               llInvestment = .F.
            ENDIF
         ELSE
            lnReturn = tnAmount
            EXIT
         ENDIF

         * Temporary fix to combat a "File tempa does not exist" error
         CREATE CURSOR tempa (junk c(1))

         *
         * Determine what fields to include in the select statement
         *
            TRY
               SWCLOSE('wellinv_tmp')
               USE wellinv AGAIN IN 0 ALIAS wellinv_tmp
            CATCH
            ENDTRY
            DO CASE
               CASE tcType == 'G'
                  lcExpr = 'wellinv_tmp.nrevgas'
               CASE tcType == 'G1'
                  lcExpr = 'wellinv_tmp.nrevtax2'
                  llTax  = .T.
               CASE tcType == 'G2'
                  lcExpr = 'wellinv_tmp.nrevtax5'
                  llTax  = .T.
               CASE tcType == 'G3'
                  lcExpr = 'wellinv_tmp.nrevtax8'
                  llTax  = .T.
               CASE tcType == 'G4'
                  lcExpr = 'wellinv_tmp.nrevtax11'
                  llTax  = .T.
               CASE tcType == 'O'
                  lcExpr = 'wellinv_tmp.nrevoil'
               CASE tcType == 'O1'
                  lcExpr = 'wellinv_tmp.nrevtax1'
                  llTax  = .T.
               CASE tcType == 'O2'
                  lcExpr = 'wellinv_tmp.nrevtax4'
                  llTax  = .T.
               CASE tcType == 'O3'
                  lcExpr = 'wellinv_tmp.nrevtax7'
                  llTax  = .T.
               CASE tcType == 'O4'
                  lcExpr = 'wellinv_tmp.nrevtax10'
                  llTax  = .T.
               CASE tcType == 'P'
                  lcExpr = 'wellinv_tmp.nrevoth'
               CASE tcType == 'P1'
                  lcExpr = 'wellinv_tmp.nrevtax3'
                  llTax  = .T.
               CASE tcType == 'P2'
                  lcExpr = 'wellinv_tmp.nrevtax6'
                  llTax  = .T.
               CASE tcType == 'P3'
                  lcExpr = 'wellinv_tmp.nrevtax9'
                  llTax  = .T.
               CASE tcType == 'P4'
                  lcExpr = 'wellinv_tmp.nrevtax12'
                  llTax  = .T.
               CASE tcType == 'T'
                  lcExpr = 'wellinv_tmp.nrevtrp'
               CASE tcType == '1'
                  lcExpr = 'wellinv_tmp.nrevmisc1'
               CASE tcType == '2'
                  lcExpr = 'wellinv_tmp.nrevmisc2'
            ENDCASE

         * Set the default expression for direct paid revenue
         DO CASE
            CASE tcType = 'O'
               lcDirectExpr = "INLIST(cdirect,'O','B')"
            CASE tcType = 'G'
               lcDirectExpr = "INLIST(cdirect,'G','B')"
            CASE tcType = 'P'
               lcDirectExpr = ".F."
            OTHERWISE
               lcDirectExpr = ".F."
         ENDCASE

         *
         * Setup the selection criteria for exempt owners
         *
         IF llTax

            * Get the purchaser withholding options for direct paid tax
            SELE wells
            LOCATE FOR cWellID == tcwellid
            IF FOUND()
               llDirOilPurch = lDirOilPurch
               llDirGasPurch = lDirGasPurch
               llroysevtx    = lroysevtx
            ELSE
               lnReturn = 0
               EXIT
            ENDIF

            IF NOT tlExcludeExempt
               IF llroysevtx
                  lcTaxExpr = 'investor.lexempt = .T.) and wellinv_tmp.cTypeinv = "W"'
               ELSE
                  lcTaxExpr = 'investor.lexempt = .T.)'
               ENDIF
            ELSE
               lcTaxExpr = '.F.)'
            ENDIF

            * Change the default direct expression if needed.
            IF NOT llDirOilPurch AND INLIST(tcType, 'O1', 'O2', 'O3', 'O4')
               lcDirectExpr = '.F.'
            ENDIF
            IF NOT llDirGasPurch AND INLIST(tcType, 'G1', 'G2', 'G3', 'G4')
               lcDirectExpr = '.F.'
            ENDIF
         ELSE
            lcTaxExpr = '.F.)'
         ENDIF

         * This is commenting out this processing since we're not getting the doi from disbhist or suspense
         tlRange = .F.
         *
         *  Get the pct to gross up or net down by using the parms passed.
         *
         DO CASE
            CASE tlRange
               * A date range was passed. Get the DOI that existed during that date range.
               DO CASE
                  CASE tlDumOnly
                     SELECT  SUM(&lcExpr) AS nPct, ;
                        DTOC(hdate) AS cdate ;
                        FROM wellinv_tmp, investor ;
                        WHERE wellinv_tmp.cWellID = tcwellid ;
                        AND cDeck == tcDeck ;
                        AND wellinv_tmp.cownerid = investor.cownerid ;
                        AND (investor.ldummy ;
                        OR &lcTaxExpr ;
                        INTO CURSOR tempx


                  CASE tlDummy
                     SELECT  SUM(&lcExpr) AS nPct, ;
                        DTOC(hdate) AS cdate ;
                        FROM wellinv_tmp, investor ;
                        WHERE wellinv_tmp.cWellID = tcwellid ;
                        AND cDeck == tcDeck ;
                        AND (&lcDirectExpr ;
                        OR (investor.ldummy);
                        OR &lcTaxExpr ;
                        AND wellinv_tmp.cownerid = investor.cownerid ;
                        INTO CURSOR tempx

                  OTHERWISE
                     SELECT  SUM(&lcExpr) AS nPct, ;
                        DTOC(hdate) AS cdate ;
                        FROM wellinv_tmp, investor ;
                        WHERE wellinv_tmp.cWellID = tcwellid ;
                        AND cDeck == tcDeck ;
                        AND (&lcDirectExpr ;
                        OR &lcTaxExpr;
                        AND NOT(investor.ldummy) ;
                        AND wellinv_tmp.cownerid = investor.cownerid ;
                        INTO CURSOR tempx

               ENDCASE

               SELE AVG(nPct) AS nPct ;
                  FROM tempx ;
                  INTO CURSOR tempa

               lnTally = _TALLY

               IF lnTally = 0
                  IF USED(lcCurrent)
                     SELECT (lcCurrent)
                  ENDIF
                  swclose('tempx')
                  swclose('tempa')
                  lnReturn = tnAmount
                  EXIT
               ENDIF


            OTHERWISE
               * Processing a new run

               DO CASE
                  CASE tlDumOnly
                     SELECT  SUM(&lcExpr) AS nPct ;
                        FROM wellinv_tmp, investor ;
                        WHERE wellinv_tmp.cWellID = tcwellid ;
                        AND cDeck == tcDeck ;
                        AND wellinv_tmp.cownerid = investor.cownerid ;
                        AND (investor.ldummy ;
                        OR &lcTaxExpr ;
                        INTO CURSOR tempa

                  CASE tlDummy
                     SELECT  SUM(&lcExpr) AS nPct ;
                        FROM wellinv_tmp, investor ;
                        WHERE wellinv_tmp.cWellID = tcwellid ;
                        AND cDeck == tcDeck ;
                        AND wellinv_tmp.cownerid = investor.cownerid ;
                        AND (&lcDirectExpr ;
                        OR (investor.ldummy);
                        OR &lcTaxExpr ;
                        INTO CURSOR tempa
                  OTHERWISE
                     SELECT  SUM(&lcExpr) AS nPct ;
                        FROM wellinv_tmp, investor ;
                        WHERE wellinv_tmp.cWellID = tcwellid ;
                        AND cDeck == tcDeck ;
                        AND (&lcDirectExpr ;
                        OR &lcTaxExpr;
                        AND NOT (investor.ldummy) ;
                        AND wellinv_tmp.cownerid = investor.cownerid ;
                        INTO CURSOR tempa
               ENDCASE

               lnTally = _TALLY

               IF lnTally = 0
                  IF USED(lcCurrent)
                     SELECT (lcCurrent)
                  ENDIF
                  swclose('tempx')
                  swclose('tempa')
                  lnReturn = tnAmount
                  EXIT
               ENDIF
         ENDCASE

         * Get the pct from our temp cursor
         SELE tempa
         lnPct   = nPct
         IF ISNULL(lnPct)
            lnPct = 0
         ENDIF

         lnGross = tnAmount

         *
         *  Calculate the Gross amount from the net amount
         *
         DO CASE
            CASE tlUp          && Gross The Amount Up
               DO CASE
                  CASE lnPct < 100
                     lnGross = swround(tnAmount / ((100 - lnPct) / 100), 2)
                     IF USED(lcCurrent)
                        SELECT (lcCurrent)
                     ENDIF
                     lnReturn = lnGross
                     EXIT
                  CASE lnPct >= 100
                     IF USED(lcCurrent)
                        SELECT (lcCurrent)
                     ENDIF
                     lnReturn = lnGross
                     EXIT
               ENDCASE
            CASE NOT tlUp      && Net The Amount Down
               DO CASE
                  CASE lnPct < 100
                     lnGross = swround((tnAmount * ((100 - lnPct) / 100)), 2)
                     IF USED(lcCurrent)
                        SELECT (lcCurrent)
                     ENDIF
                     lnReturn = lnGross
                     EXIT
                  CASE lnPct >= 100
                     IF USED(lcCurrent)
                        SELECT (lcCurrent)
                     ENDIF
                     lnReturn = 0
                     EXIT
               ENDCASE
         ENDCASE

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'NetRev', loError.LINENO, 'DistProc', loError.ERRORNO, loError.MESSAGE, ' ', loError
      ENDTRY

      swclose('wellinv_temp')

      IF USED(lcAlias)
         SELECT (lcAlias)
      ENDIF

      RETURN lnReturn
   ENDPROC

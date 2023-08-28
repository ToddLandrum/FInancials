PARA cBegID,cEndID,dThroughDate,lDetail,tnDate,lHouseGas, tcAcctNo, tlShowAll, tlJIBS, tlSelected
LOCAL llByAccount

llByAccount = .F.

IF TYPE('tcAcctNo') = 'C'
   IF tcAcctNo = '******'
      llByAccount = .F.
   ELSE
      llByAccount = .T.
   ENDIF
ENDIF

IF NOT USED('glmaster')
   USE glmaster IN 0
ENDIF

tcBegID = cBegID
tcEndID = cEndID
tdThroughDate = dThroughDate
tdScanDate = iif(tlShowAll,{12/31/2999},tdThroughDate)
tlDetail = lDetail
tlHouseGas = lHouseGas

IF NOT tlSelected
   SELECT ccustid as cid FROM custown ;
      INTO CURSOR selected ;
      WHERE BETWEEN(ccustid,tcBegID,tcEndID);
      ORDER BY cid
ENDIF 

jnDays30 = tdThroughDate - 30
jnDays60 = tdThroughDate - 60
jnDays90 = tdThroughDate - 90

DO CASE
   CASE NOT lDetail           && Summary Report Requested
      CREATE CURSOR custbal ;
         (cCustId    C(10), ;
         cCustName   C(40), ;
         nCurrent    N(12,2), ;
         nDays1      N(12,2), ;
         nDays30     N(12,2), ;
         nDays60     N(12,2), ;
         nDaysover90 N(12,2))
      SELECT custown.cCustId, 00000.00 AS nCurrent, ;
         00000.00 AS nDays30, 00000.00 AS nDays60, ;
         00000.00 AS nDaysOver90, 00000.00 as nDays1,  ;
         custown.cCustName ;
         FROM custown ;
         WHERE custown.ccustid in (SELECT cid FROM selected) ;
         INTO CURSOR custbalx ;
         ORDER BY cCustId ;
         GROUP BY cCustId
      SELECT custbal
      APPEND FROM DBF('custbalx')
      USE IN custbalx
      SCAN
         m.cCustId = cCustId
         m.nCurrent = 0
         m.nBal30   = 0
         m.nBal60   = 0
         m.nBal90   = 0
         *  Check for posting owner
         SELE investor
         LOCATE FOR cOwnerID = m.cCustId
         IF FOUND() AND lIntegGL = .T.
            LOOP
         ENDIF
         SELECT invhdr
         SCAN FOR cCustId = m.cCustId AND ICASE(tnDate=1,dInvDate,tnDate=2,dDueDate,tnDate=3,dPostDate) <= tdScanDate AND IIF(tlJIBs,cinvtype='J',cinvtype#'J')
            m.cBatch   = cBatch
            IF llByAccount
               SELE glmaster
               llFound = .F.
               SCAN FOR cBatch == m.cBatch
                  IF cacctno == tcAcctNo
                     llFound = .T.
                  ENDIF
               ENDSCAN
               IF NOT llFound
                  LOOP
               ENDIF
            ENDIF
            SELE invhdr
            m.dInvDate = dInvDate
            m.dDueDate = dDueDate
            m.nBal     = nInvTot
            m.cinvnum  = cinvnum
            m.cInvToken = cBatch
            ldCheckDate = ICASE(tnDate=1,dInvDate,tnDate=2,dDueDate,tnDate=3,dPostDate)
             DO CASE
               CASE tdThroughDate - m.dDueDate < 1
                  m.nCurrent = m.nCurrent + m.nBal
               CASE tdThroughDate - m.dDueDate < 31
                  m.nBal1 = m.nBal1 + m.nBal
               CASE tdThroughDate - m.dDueDate < 61
                  m.nBal60 = m.nBal60 + m.nBal
               CASE tdThroughDate - m.dDueDate > 90
                  m.nBal90 = m.nBal90 + m.nBal
               OTHERWISE
                  m.nCurrent = m.nCurrent + m.nBal
            ENDCASE
            m.nBal = 0
         ENDSCAN
         m.nBal = 0
         lnPaid = 0
         SELECT arpmthdr1
         SCAN FOR cCustId == m.cCustId AND drecdate <= tdThroughDate AND IIF(tlJIBs,cPmtType = 'J',cPmtType = 'A')
            lcBatch = cBatch
            IF llByAccount
               SELE glmaster
               llFound = .F.
               SCAN FOR cBatch == lcBatch
                  IF cacctno == tcAcctNo
                     llFound = .T.
                  ENDIF
               ENDSCAN
               IF NOT llFound
                  LOOP
               ENDIF
            ENDIF
            SELE arpmthdr1
            lnUnApp = 0
            m.dDueDate = drecdate
            SELECT arpmtdet1
            SCAN FOR cBatch == lcBatch
               lnPaid = lnPaid + namtapp + nDisTaken
            ENDSCAN
            m.nBal = (lnPaid + lnUnApp) * -1

             DO CASE
               CASE tdThroughDate - m.dDueDate < 1
                  m.nCurrent = m.nCurrent + m.nBal
               CASE tdThroughDate - m.dDueDate < 31
                  m.nBal1 = m.nBal1 + m.nBal
               CASE tdThroughDate - m.dDueDate < 61
                  m.nBal60 = m.nBal60 + m.nBal
               CASE tdThroughDate - m.dDueDate > 90
                  m.nBal90 = m.nBal90 + m.nBal
               OTHERWISE
                  m.nCurrent = m.nCurrent + m.nBal
            ENDCASE
            STORE 0 TO m.nBal, lnPaid, lnUnApp
         ENDSCAN
         SELECT custbal
         IF m.nCurrent + m.nBal1 + m.nBal30 + m.nBal60 + m.nBal90 = 0
            DELETE NEXT 1
         ELSE
            REPLACE nCurrent WITH m.nCurrent, ;
               nDays1   WITH m.nBal1, ;
               nDays30  WITH m.nBal30, ;
               nDays60  WITH m.nBal60, ;
               nDaysover90  WITH m.nBal90
         ENDIF
         STORE 0 TO m.nCurrent, m.nBal30, m.nBal60, m.nBal90
      ENDSCAN
      
      SELECT custbal
      DELETE FOR nCurrent = 0 AND nDays1 = 0 AND nDays30 = 0 AND nDays60 = 0 AND nDaysover90 = 0

      SELECT custbal.ccustid, ;
             custbal.ccustname, ;
             SUM(nCurrent) as nCurrent, ;
             SUM(nDays1) as nDays1, ;
             SUM(nDays30) as nDays30, ;
             SUM(nDays60) as nDays60, ;
             SUM(nDaysOver90) as nDaysOver90 ;
        FROM custbal ORDER BY cCustId GROUP BY cCustId INTO CURSOR custbal

   CASE tlDetail           && Detail Report Requested
      *!*	      THISFORM.cTitle1 = 'Aged Receivables - Detail'
      *!*	      THIS.cReportName = 'arage2.frx'

      CREATE CURSOR custbalx ;
         (cCustId     C(10), ;
         cBatch     C(8), ;
         cCustName   C(40), ;
         cbAddr1     C(40),  ;
         cbAddr2     C(40),  ;
         cbAddr3     C(40),  ;
         cbCity      C(40),  ;
         cbState     C(2),  ;
         cbZip       C(10), ;
         cinvnum     C(15), ;
         cDateCap    C(10), ;
         dInvDate    D, ;
         dSelDate    D, ;
         dStmtDate   D,  ;
         cReference  C(15),  ;
         ccontact    C(25), ;
         cphone      C(15), ;
         asterisk    C(1), ;
         cartype     C(1), ;
         nInvBal     N(12,2), ;
         nInvTot     N(12,2),  ;
         ninvage     N(4,0))
      INDEX ON cCustId TAG cCustId
      INDEX ON cCustId+DTOS(dInvDate)+cinvnum+cartype TAG custinv

      SELECT custown.* FROM custown INTO CURSOR custtemp ORDER BY ccustid GROUP BY ccustid
      SCAN 
         SELECT selected
         LOCATE FOR cid = custtemp.ccustid
         IF NOT FOUND()
            LOOP
         ENDIF 
         SELECT custtemp
         m.cCustId   = cCustId
         lcCustID    = cCustId
         m.cCustName = cCustName
         m.ccontact  = ccontact
         m.cphone    = cphone
         m.cbAddr1   = cAddress1
         m.cbAddr2   = cAddress2

         *  Check for posting owner
         SELE investor
         LOCATE FOR cOwnerID = m.cCustId
         IF FOUND() AND lIntegGL = .T.
            LOOP
         ENDIF

         SELE custtemp
         IF EMPTY(m.cbAddr2)
            m.cbAddr2 = ALLTRIM(ccity) + ', ' + ALLTRIM(cState) + '  ' + cZip
            m.cbAddr3 = ''
         ELSE
            m.cbAddr3 = ALLTRIM(ccity) + ', ' + ALLTRIM(cState) + '  ' + cZip
         ENDIF

         IF NOT tlHouseGas
            SELECT invhdr
            SCAN FOR cCustId = m.cCustId ;
                  AND ICASE(tnDate=1,dInvDate,tnDate=2,dDueDate,tnDate=3,dPostDate) <= tdScanDate AND IIF(tlJIBs,cinvtype='J',cinvtype#'J')
               m.ninvage   = dDueDate - tdThroughDate
               *!*  Not sure why this is here...commenting it out  11/10/04 pws
               *!*	               IF m.ninvage > 0 AND dInvDate > tdThroughDate
               *!*	                  LOOP
               *!*	               ENDIF

               m.cBatch    = cBatch

               IF llByAccount
                  SELE glmaster
                  llFound = .F.
                  SCAN FOR cBatch == m.cBatch
                     IF cacctno == tcAcctNo
                        llFound = .T.
                     ENDIF
                  ENDSCAN
                  IF NOT llFound
                     LOOP
                  ENDIF
               ENDIF
               SELE invhdr
               m.dInvDate  = dInvDate
               IF tnDate = 3
                  m.dSelDate  = dPostDate
                  m.cDateCap = 'Post Date'
               ELSE
                  m.dSelDate  = dDueDate
                  m.cDateCap  = 'Due Date'
               ENDIF    
               m.cinvnum   = cinvnum
               m.cartype   = cInvType
               m.nInvBal   = nInvTot
               m.cReference = cReference
               m.nInvTot   = nInvTot
               m.dStmtDate = tdThroughDate
               m.nAmtPaid  = 0
               m.nPaid     = 0
               SELECT arpmtdet1
               SCAN FOR cInvToken == m.cBatch AND namtapp <> 0
                  SELECT arpmthdr1
                  LOCATE FOR cBatch = arpmtdet1.cBatch
                  IF FOUND()
                     IF drecdate <= tdThroughDate
                        m.nPaid = arpmtdet1.namtapp + arpmtdet1.nDisTaken
                     ELSE
                        m.nPaid = 0
                     ENDIF
                  ENDIF
                  m.nInvBal = m.nInvBal - m.nPaid
               ENDSCAN
               SELECT invhdr
               REPLACE invhdr.nInvBal WITH m.nInvBal, invhdr.nPayments WITH invhdr.nInvTot-nInvBal
               m.nInvBal = m.nInvTot
               IF m.nInvTot <> 0
                  INSERT INTO custbalx FROM MEMVAR
               ENDIF
            ENDSCAN
            *  Get the payments during this date range for the given customers or (owners)
            lnPaid = 0
            SELECT arpmthdr1
            SCAN FOR cCustId == m.cCustId AND drecdate <= tdThroughDate AND IIF(tlJIBs,cPmtType = 'J',cPmtType = 'A')
               m.ninvage = drecdate - tdThroughDate
               lcBatch = cBatch
               IF llByAccount
                  SELE glmaster
                  llFound = .F.
                  SCAN FOR cBatch == lcBatch
                     IF cacctno == tcAcctNo
                        llFound = .T.
                     ENDIF
                  ENDSCAN
                  IF NOT llFound
                     LOOP
                  ENDIF
               ENDIF
               SELE arpmthdr1
               lnUnApp = 0
               SELECT arpmtdet1
               SCAN FOR cBatch == lcBatch
                  llFound = .T.
                  lnPaid = lnPaid + arpmtdet1.namtapp + arpmtdet1.nDisTaken
               ENDSCAN
               lnPaid = lnPaid + lnUnApp
               m.dInvDate  = arpmthdr1.drecdate
               m.dSelDate  = m.dInvDate
               IF tnDate = 3
                  m.cDateCap = 'Post Date'
               ELSE
                  m.cDateCap  = 'Due Date'
               ENDIF    
               m.cinvnum   = arpmthdr1.cReference
               m.cartype   = 'P'
               m.cBatch    = lcBatch
               m.nInvBal   = lnPaid * -1
               m.cReference = arpmthdr1.cReference
               m.nInvTot   = lnPaid * -1
               m.dStmtDate = tdThroughDate
               IF lnPaid <> 0
                  INSERT INTO custbalx FROM MEMVAR
                  lnPaid = 0
               ENDIF
            ENDSCAN
         ENDIF

         IF tlHouseGas AND m.goapp.lHouseGasOpt  &&  House Gas Invoices

            SELECT gasinv
            SCAN FOR cOwnerID = m.cCustId AND nTotal <> 0;
                  AND ICASE(tnDate=1,dInvDate,tnDate=2,dDueDate,tnDate=3,dInvDate) <= tdScanDate
               m.ninvage   = dDueDate - tdThroughDate
               IF m.ninvage > 0 AND dInvDate > tdThroughDate and not tlShowAll
                  LOOP
               ENDIF
               m.dInvDate  = dInvDate
               IF tnDate = 3
                  m.dSelDate  = dInvDate
                  m.cDateCap = 'Post Date'
               ELSE
                  m.dSelDate  = dDueDate
                  m.cDateCap  = 'Due Date'
               ENDIF    
               m.cinvnum   = cinvnum
               m.cartype   = 'G'
               m.cBatch    = cidgasinv
               m.nInvBal   = nTotal
               m.cReference = cMeterNo
               m.nInvTot   = nTotal
               m.dStmtDate = tdThroughDate
               m.nAmtPaid  = 0
               m.nPaid     = 0

               IF m.nInvBal <> 0
                  INSERT INTO custbalx FROM MEMVAR
               ENDIF
            ENDSCAN

            *  Get the payments during this date range for the given customers or (owners)
            lnPaid = 0
            SELECT arpmthdr1
            SCAN FOR cCustId == m.cCustId AND drecdate <= tdThroughDate AND cPmtType = 'H'
               m.ninvage = drecdate - tdThroughDate
               lcBatch = cBatch
               IF llByAccount
                  SELE glmaster
                  llFound = .F.
                  SCAN FOR cBatch == lcBatch
                     IF cacctno == tcAcctNo
                        llFound = .T.
                     ENDIF
                  ENDSCAN
                  IF NOT llFound
                     LOOP
                  ENDIF
               ENDIF
               SELE arpmthdr1
               lnUnApp = 0
               SELECT arpmtdet1
               SCAN FOR cBatch == lcBatch
                  llFound = .T.
                  lnPaid = lnPaid + arpmtdet1.namtapp + arpmtdet1.nDisTaken
               ENDSCAN
               lnPaid = lnPaid + lnUnApp
               m.dInvDate  = arpmthdr1.drecdate
               m.dSelDate  = m.dInvDate
               IF tnDate = 3
                  m.cDateCap = 'Post Date'
               ELSE
                  m.cDateCap  = 'Due Date'
               ENDIF    
               m.cinvnum   = arpmthdr1.cReference
               m.cartype   = 'P'
               m.cBatch    = lcBatch
               m.nInvBal   = lnPaid * -1
               m.cReference = arpmthdr1.cReference
               m.nInvTot   = lnPaid * -1
               m.dStmtDate = tdThroughDate
               IF lnPaid <> 0
                  INSERT INTO custbalx FROM MEMVAR
                  lnPaid = 0
               ENDIF
            ENDSCAN
         ENDIF

      ENDSCAN

      SELECT * FROM custbalx ;
         INTO CURSOR custbal ;
         ORDER BY cCustId ASC, dInvDate ASC, cinvnum ASC, cartype ASC
      USE IN custbalx
      SELECT custbal
ENDCASE

WAIT CLEAR

SELECT custbal
COUNT FOR NOT DELETED() TO lnCount
GO TOP
IF lnCount > 0
   RETURN .T.
ELSE
   RETURN .F.
ENDIF

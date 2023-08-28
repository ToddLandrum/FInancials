PARA cBegID,cEndID,dThroughDate,lDetail,nDate,lHouseGas, tcAcctNo, lIncludeAll, tlJIBs, tlSelected

llByAccount = .F.

IF TYPE('tcAcctNo') = 'C'
   IF tcAcctNo = '******'
      llByAccount = .F.
   ELSE
      llByAccount = .T.
   ENDIF
ENDIF

tcBegID = cBegID
tcEndID = cEndID
tdThroughDate = dThroughDate
tdScanDate = IIF(lIncludeAll,{12/31/2999},tdThroughDate)
tlDetail = lDetail
tnDate = nDate
tlHouseGas = lHouseGas

IF NOT tlSelected
   SELECT ccustid as cid FROM custown ;
      INTO CURSOR selected ;
      WHERE BETWEEN(ccustid,tcBegID,tcEndID);
      ORDER BY cid
ENDIF 

*  If it's a 4, it's a HG aging being run by reading date
*  We don't have the reading date in the gasinv file, so we
*  have to match the gasinv file back to the gasuse file to
*  determine whether it should be included in the aging.
*  Just an extra step.
DO CASE
   CASE tnDate = 2 OR tnDate = 4
      lcDate = 'dInvDate'
   CASE tnDate = 3
      lcDate = 'dpostdate'
   OTHERWISE
      lcDate = 'dDueDate'
ENDCASE

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
         WHERE custown.cCustId in (SELECT cid FROM selected) ;
         INTO CURSOR custbalx ;
         ORDER BY cCustId ;
         GROUP BY cCustId
      SELECT custbal
      APPEND FROM DBF('custbalx')
      USE IN custbalx
      SCAN
         m.cCustId = cCustId
         m.nCurrent = 0
         m.nBal1    = 0
         m.nBal30   = 0
         m.nBal60   = 0
         m.nBal90   = 0
         *  Check for posting owner
         SELE investor
         LOCATE FOR cOwnerID = m.cCustId
         IF FOUND() AND lIntegGL = .T. AND m.goapp.lAMVersion  &&  Don't loop out for the stand-alone version, b/c the option is not to create a check in the DM - BH 03/09/2007
            swselect('custs')
            LOCATE FOR ccustid == m.ccustid
            IF NOT FOUND()
               LOOP
            ENDIF 
         ENDIF
         SELECT invhdr
         SCAN FOR cCustId = m.cCustId AND &lcDate <= tdScanDate AND cinvtype <> 'A' AND IIF(tlJIBs,cinvtype='J',cinvtype#'J')
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
            m.nAmtPaid = 0
            SELECT arpmtdet1
            SCAN FOR cInvToken == m.cInvToken AND nAmtApp <> 0
               m.cBatch = cBatch
               SELECT arpmthdr1
               LOCATE FOR arpmthdr1.cBatch == m.cBatch AND arpmthdr1.drecdate <= tdThroughDate
               IF FOUND()
                  m.nAmtPaid = arpmtdet1.nAmtApp+arpmtdet1.nDisTaken  &&  Include discounts used - BH 9-14-05
               ELSE
                  m.nAmtPaid = 0
               ENDIF
               m.nBal = m.nBal - m.nAmtPaid
            ENDSCAN
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
         STORE 0 TO m.nCurrent, m.nDays1, m.nBal30, m.nBal60, m.nBal90
      ENDSCAN
      SELECT custbal
      DELETE FOR nCurrent = 0 AND nDays1 = 0 AND nDays30 = 0 AND nDays60 = 0 AND nDaysover90 = 0

      SELECT * FROM custbal ORDER BY cCustId GROUP BY cCustId INTO CURSOR custbal

   CASE tlDetail           && Detail Report Requested
      *!*          THISFORM.cTitle1 = 'Aged Receivables - Detail'
      *!*          THIS.cReportName = 'arage2.frx'
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
         dInvDate    D, ;
         dDueDate    D,  ;
         cDateCap    C(10), ;
         dSelDate    D, ;
         dStmtDate   D,  ;
         cReference  C(15),  ;
         ccontact    C(25), ;
         cphone      C(15), ;
         asterisk    C(1), ;
         cartype     C(1), ;
         nInvBal     N(12,2), ;
         nInvTot     N(12,2),  ;
         ninvage     N(6,0), ;
         cmeterno    C(15))
      INDEX ON cCustId TAG cCustId
      INDEX ON cCustId+cinvnum+cartype TAG custinv

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
         SET ORDER TO cOwnerID
         IF SEEK(m.cCustId) AND lIntegGL = .T.
            swselect('custs')
            LOCATE FOR ccustid == m.ccustid
            IF NOT FOUND()
               LOOP
            ENDIF 
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
                  AND &lcDate <= tdScanDate AND cinvtype <> 'A' AND IIF(tlJIBs,cinvtype='J',cinvtype#'J')

               m.cBatch = cBatch
               m.dDueDate = dDueDate
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
               m.ninvage   = dDueDate - tdThroughDate

               IF m.ninvage > 0 AND dInvDate > tdThroughDate AND NOT lIncludeAll
                  LOOP
               ENDIF

               IF lIncludeAll AND m.ninvage >= 0  &&  Including all entries, so any negatively aged invoices should show up - reset age to 1
                  m.ninvage = 1
               ENDIF

               m.dInvDate  = dInvDate
               IF tnDate = 3
                  m.cDateCap = 'Post Date'
                  * pws - 2011/05/26  Changed this to be dDueDate instead of dPostDate because the
                  *                   report: araged2.frx doesn't use the cDateCap field to show the
                  *                   column heading.  Case 27103
                  m.dSelDate = dDueDate
               ELSE
                  m.cDateCap = 'Due Date'
                  m.dSelDate = dDueDate
               ENDIF
               m.cinvnum   = cinvnum
               m.cartype   = cinvtype
               m.cBatch    = cBatch
               m.nInvBal   = nInvTot
               m.cReference = cReference
               m.nInvTot   = nInvTot
               m.dStmtDate = tdThroughDate
               m.nAmtPaid  = 0
               m.nPaid     = 0
               SELECT arpmthdr1
               SET ORDER TO cBatch
               SELECT arpmtdet1
               SCAN FOR cInvToken == m.cBatch AND nAmtApp <> 0
                  SELECT arpmthdr1
                  IF SEEK(arpmtdet1.cBatch)
                     IF drecdate <= tdThroughDate
                        m.nPaid = arpmtdet1.nAmtApp+arpmtdet1.nDisTaken  &&  Include discounts used - BH 9-14-05
                     ELSE
                        m.nPaid = 0
                     ENDIF
                  ENDIF
                  m.nInvBal = m.nInvBal - m.nPaid
               ENDSCAN
               SELECT invhdr
               REPLACE invhdr.nInvBal WITH m.nInvBal, invhdr.nPayments WITH invhdr.nInvTot-nInvBal
               IF m.nInvBal <> 0
                  INSERT INTO custbalx FROM MEMVAR
               ENDIF
            ENDSCAN
         ENDIF

         IF tlHouseGas AND m.goapp.lHouseGasOpt  &&  House Gas Invoices

            SELECT gasinv
            SCAN FOR cOwnerID = m.cCustId AND nTotal <> 0 AND dInvDate <= tdThroughDate

               ldInvDate  = gasinv.dInvDate
               m.cmeterno = gasinv.cmeterno

               *  If it's a 4, it's basing the aging on reading date, so we need to match
               *  back to gasuse to get that date, since it's not stored in gasinv
               *  We also have to base the age of the reading on the gasuse.dDate field
               *  instead of the invoice date
               IF tnDate = 4
                  SELECT gasuse
                  LOCATE FOR cInvToken = gasinv.cidgasinv
                  IF FOUND()
                     ldInvDate = gasuse.dDate
                     m.ninvage = gasuse.dDate - tdThroughDate
                  ELSE
                     * Must be a credit invoice. Just use the due date 
                     m.ninvage = gasinv.dDueDate - tdThroughDate
                  ENDIF
                  SELECT gasinv
               ELSE
                  m.ninvage   = gasinv.dDueDate - tdThroughDate
               ENDIF

               IF m.ninvage > 0 AND dInvDate > tdThroughDate AND NOT lIncludeAll
                  LOOP
               ENDIF

               IF lIncludeAll AND m.ninvage >= 0  &&  Including all entries, so any negatively aged invoices should show up - reset age to 1
                  m.ninvage = 1
               ENDIF

               m.dInvDate  = dInvDate
               IF tnDate = 3
                  m.cDateCap = 'Post Date'
                  m.dSelDate = dInvDate
               ELSE
                  m.cDateCap = 'Due Date'
                  m.dSelDate = dDueDate
               ENDIF
               m.dDueDate  = dDueDate
               m.cinvnum   = cinvnum
               m.cartype   = 'G'
               m.cBatch    = cidgasinv
               m.nInvBal   = nTotal
               m.cReference = cMeterNo
               m.nInvTot   = nTotal
               m.dStmtDate = tdThroughDate
               m.nAmtPaid  = 0
               m.nPaid     = 0
               SELECT arpmtdet1
               SCAN FOR cInvToken == m.cBatch AND nAmtApp <> 0
                  SELECT arpmthdr1
                  LOCATE FOR cBatch = arpmtdet1.cBatch
                  IF FOUND()
                     IF drecdate <= tdThroughDate
                        m.nPaid = arpmtdet1.nAmtApp+arpmtdet1.nDisTaken  &&  Include discounts used - BH 9-14-05
                     ELSE
                        m.nPaid = 0
                     ENDIF
                  ENDIF
                  m.nInvBal = m.nInvBal - m.nPaid
               ENDSCAN
               SELECT gasinv
               REPLACE gasinv.nBalance WITH m.nInvBal, gasinv.nPmts WITH gasinv.nTotal-nBalance
               IF m.nInvBal <> 0
                  INSERT INTO custbalx FROM MEMVAR
               ENDIF
            ENDSCAN
         ENDIF
      ENDSCAN

      SELECT * FROM custbalx ;
         INTO CURSOR custbal ;
         ORDER BY cCustId ASC, cinvnum ASC, cartype ASC
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

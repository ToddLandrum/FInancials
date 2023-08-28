LPARA tcWellID, tcBatch, tcAFENo
LOCAL lcWellID, lcBatch, lcAPAcct, lcFixedAcct

STORE '******' TO lcAPAcct, lcFixedAcct

lcWellID = tcWellID
lcBatch  = tcBatch

IF USED('tempafex')
   USE IN tempafex
ENDIF
IF USED('tempafe1')
   USE IN tempafe1
ENDIF
IF USED('tempafe2')
   USE IN tempafe2
ENDIF

*
*  Calculates the afe balance
*

* Make sure the tables are open
swselect('afedet')
swselect('expense')
swselect('appurchd')
swselect('expcat')
IF m.goApp.lAMVersion
   swselect('glmaster')

   * Get the AP Acct and Fixed Clearing Acct so we
   * don't include any transactions in those accounts.
   swselect('apopt')
   lcAPAcct = cAPAcct
   swselect('options')
   lcFixedAcct = cFixedAcct
ENDIF

* Get the date range for the AFE
swselect('afehdr')
LOCATE FOR cafeno == tcAFENo
IF FOUND() AND NOT lClosed
   * The AFE is not closed, get the range of dates
   ldStartDate = dAFEDate
   ldEndDate   = dCompDate

   * The start date is empty. Set to inclusive default
   IF EMPTY(ldStartDate)
      ldStartDate = {01/01/1900}
   ENDIF
   
   * The end date is empty. Set to inclusive default
   IF EMPTY(ldEndDate)
      ldEndDate = {12/31/9999}
   ENDIF

   *  Zero out actual totals
   SELE afedet
   SCAN FOR cidafeh = lcBatch
      REPL nactcost  WITH 0, ;
         nvariance WITH nEstCost
   ENDSCAN

* Added the check for file afeconvert.cfg when using the AM version so that if they converted from DMIE or DM the AFE reports would still be correct.
   IF m.goApp.lAMVersion AND NOT FILE('datafiles\afeconvert.cfg')
      SELECT cUnitNo, glmaster.ccatcode, SUM(nDebits) AS ndr, SUM(nCredits) AS ncr ;
         FROM glmaster, expcat ;
         WHERE cUnitNo == lcWellID ;
         AND glmaster.cAcctNo <> lcAPAcct ;
         AND glmaster.cAcctNo <> lcFixedAcct ;
         AND glmaster.cAFENo == tcAFENo ;
         AND glmaster.ccatcode == expcat.ccatcode ;
         AND BETWEEN(glmaster.ddate,ldStartDate,ldEndDate) ;
         INTO CURSOR tempafex1 ;
         ORDER BY glmaster.ccatcode ;
         GROUP BY glmaster.ccatcode
         
   ELSE
      SELECT Expense.cWellID AS cUnitNo, ;  &&  All non-AP expenses first, and then add up the recs from appurchd
      Expense.ccatcode, SUM(nAmount) AS ndr, 000000.00 AS ncr ;
         FROM Expense ;
         WHERE cAFENo == tcAFENo ;
         AND lAPTran = .F.  ;
         AND BETWEEN(Expense.dexpdate,ldStartDate,ldEndDate) ;
         INTO CURSOR tempafe1 ;
         ORDER BY Expense.ccatcode ;
         GROUP BY Expense.ccatcode

      SELECT appurchd.cUnitNo,  ;
         appurchd.ccatcode, SUM(nextension) AS ndr, 000000.00 AS ncr  ;
         FROM appurchd  ;
         WHERE appurchd.cbatch IN (SELECT cbatch FROM appurchh WHERE BETWEEN(dInvDate,ldStartDate,ldEndDate)) ;
         AND cAFENo  == tcAFENo ;
         INTO CURSOR tempafe2  ;
         ORDER BY appurchd.ccatcode  ;
         GROUP BY appurchd.ccatcode

      USE DBF('tempafe1') AGAIN IN 0 ALIAS tempafex
      SELECT tempafex
      APPEND FROM DBF('tempafe2')
      
      *  One more sum, so if there entries for the same code in multiple places, they're getting added together
      SELECT cUnitNo, cCatCode, SUM(nDr) as nDr, SUM(nCr) as nCr FROM tempafex  ;
      INTO CURSOR tempafex1  ;
      GROUP BY cCatCode
      

   ENDIF

   SELECT tempafex1
   IF RECC() > 0
      SCAN
         SCATTER MEMVAR
         SELECT afedet
         LOCATE FOR cidafeh == lcBatch AND ccatcode == m.ccatcode
         IF FOUND()
            REPL nactcost  WITH (m.ndr - m.ncr), ;
               nvariance WITH nEstCost - (m.ndr-m.ncr)
         ENDIF
      ENDSCAN
   ENDIF
   USE IN tempafex1

ENDIF




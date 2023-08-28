**  Scans and sums the current suspense balances for owners, and creates a beginning  **
**  balance entry for them in the new suspense table                                  **

set deleted on

IF NOT USED('investor')
   USE investor IN 0
ENDIF
IF NOT USED('susaudit')
   USE susaudit IN 0
ENDIF
IF NOT USED('suspense')
   USE suspense IN 0
ENDIF
IF NOT USED('disbhist')
   USE disbhist IN 0
ENDIF
IF USED('temp')
   USE IN temp
ENDIF

oRegistry = FindGlobalObject('cmRegistry')

WAIT WINDOW NOWAIT 'Performing First-Time Suspense Balance Calculations...'

SELECT MAX(cYear) AS cYear, 'I' AS cAction, SUM(IIF(cAction='I',nAmount,nAmount*-1)) AS nNetCheck,  ;
   SUM(IIF(cAction='I',nincome,nincome*-1)) AS nincome,  ;
   MAX(cRunYear+PADL(ALLT(STR(nRunno)),2,'0')) AS cYearRun,  ;
   SUM(IIF(cAction='I',nExpenses,nExpenses*-1)) AS nExpense,  ;
   SUM(IIF(cAction='I',nTaxes,nTaxes*-1)) AS nSevTaxes,cSuspType,MAX(cProgCode) as cProgCode, ;  && Max progcode, so if they have a mixture of entries that have a progcode and some that are blank, it will always fill in with a code
   susaudit.cownerid AS cownerid, susaudit.cwellid AS cwellid, ;
   cGroup, MAX(dSuspDate) AS hDate, ;
   investor.cownname AS cownname, cTypeInv ;
   FROM susaudit, investor ;
   WHERE susaudit.cownerid == investor.cownerid ;
   ORDER BY susaudit.cownerid, susaudit.cwellid ;
   GROUP BY susaudit.cownerid, susaudit.cwellid ;
   INTO CURSOR temp

SELECT temp
SCAN FOR nNetCheck <> 0
   SCATTER MEMVAR
   
   m.lBegBal = .T.  &&  Beginning balance flag
   IF m.nNetCheck < 0 AND cSuspType = 'M'  &&  Negative minimum, so make it a deficit
      m.cSuspType = 'D'
   ENDIF
   IF m.nNetCheck > 0 AND cSuspType = 'D'  &&  Positive deficit, so make it a minimum
      m.cSuspType = 'M'
   ENDIF
   m.cRunYear     = LEFT(m.cYearRun,4)
   m.nRunno       = VAL(SUBSTR(m.cYearRun,5))
   m.cRunYear_in  = m.cRunYear
   m.nRunno_in    = m.nRunno
   m.cRecType     = 'R'
   m.lManEntry    = .t.
   
   SELECT disbhist  &&  Locate an entry for them with gas revenue.  If found, make all the entries gas revenue; otherwise, all oil
   LOCATE FOR cownerid = m.cOwnerID AND cWellID == m.cWellID AND nGasRev <> 0
   IF FOUND()
      m.nGasRev = m.nIncome
      m.nOilRev = 0
   ELSE  &&  No gas revenue, so make it all oil
      m.nGasRev = 0
      m.nOilRev = m.nIncome
   endif

   SET DELETED OFF  &&  Loop to find unique primary key, so it won't run into problems getting inserted into disbhist later
   SELECT disbhist
   SET ORDER TO ciddisb
   m.ciddisb = oRegistry.IncrementCounter('%Shared.Counters.Owner History')
   DO WHILE SEEK(m.ciddisb)
      m.ciddisb = oRegistry.IncrementCounter('%Shared.Counters.Owner History')
   ENDDO
   SET DELETED ON

   INSERT INTO suspense FROM MEMVAR
ENDSCAN

WAIT CLEAR



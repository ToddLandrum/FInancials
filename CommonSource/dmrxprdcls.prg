LOCAL lnCount

*
*  Prints the closed period listing
*
SET SAFETY OFF

IF TYPE('m.goApp') <> 'O'
   m.cProducer = 'Development Company'
ELSE
   m.cProducer = m.goApp.cCompanyName
ENDIF

IF USED('tempsys')
   USE IN tempsys
ENDIF

lcTitle1 = ''
lcTitle2 = ''
SET DELETED ON
IF NOT USED('sysctl')
   USE sysctl IN 0
ENDIF
SELECT sysctl
SCAN FOR lYearClose AND EMPTY(cRunYear)  &&  Fill in the run year for fiscal year closings, so it reports properly - BH 02/09/2007
   REPLACE cRunYear WITH cYear
ENDSCAN

CREATE CURSOR tempsys  ;
   (cRunYear       c(4),  ;
   nRunno          I,  ;
   cYear           c(4),  ;
   cPeriod         c(2),  ;
   cRunYearNo      c(7),  ;
   cGroup          c(2),  ;
   ddateclose      d,  ;
   cTimeClose      c(8),  ;
   dAcctDate       d,  ;
   dPostDate       d,  ;
   dRevDate        d,  ;
   dExpDate        d,  ;
   lCompanyPost    L,  ;
   lRelMin         L,  ;
   cversion        c(5), ;
   cTypeClose      c(1),  ;
   lYearClose      L)
INDEX ON cTypeClose+cRunYearNo+DTOC(dDateClose) DESCENDING TAG cRunYearNo

SELECT tempsys
SET ORDER TO cRunYearNo
APPEND FROM DBF('sysctl') FOR NOT 'BEG' $ cversion AND NOT nrunno=9999

SELECT tempsys  &&  Fill in the runyear on the accounting and fiscal year close records - BH 10/09/2006
SCAN FOR EMPTY(cRunYear)
   REPLACE cRunYear WITH cYear, cGroup WITH ''
ENDSCAN

replace nRunNo WITH VAL(cPeriod) FOR nRunNo = 0 AND NOT EMPTY(cPeriod)
REPLACE cRunYearNo WITH cRunYear+PADL(ALLTRIM(STR(nRunno)),3,'0') ALL  &&  Fill in sortfield, formatted properly

IF _TALLY > 0
   REPORT FORM dmrxprdcls TO PRINTER PROMPT PREVIEW
ELSE
   oMessage = findglobalobject('cmMessage')
   oMessage.Display('No closings have been done, so no report can be generated.')
ENDIF

USE IN sysctl

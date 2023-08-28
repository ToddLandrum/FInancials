IF TYPE('m.goApp') = 'O'
   lcPath = ALLTRIM(m.goApp.cDataFilePath)
ELSE
   lcPath = 'Data\'
ENDIF

oMessage = FindGlobalObject('cmMessage')

IF swOpenForms()
   messagebox('All open forms must be closed checking the GL for problems. Close other forms and then re-try.',16,'Close All Forms')
   RETURN
ENDIF

IF USED('gltemp')
   USE IN gltemp
ENDIF

CREATE CURSOR gltemp  ;
   (cBatch      c(8),  ;
   ddate        d,  ;
   cYear        c(4),  ;
   cPeriod      c(2),  ;
   dr           N(12,2),  ;
   cr           N(12,2),  ;
   bal          N(12,2),  ;
   cacctno      c(6),  ;
   cType        c(1))

IF NOT USED('glmaster')
   USE (lcPath+'glmaster') IN 0
ENDIF
IF NOT USED('coa')
   USE (lcPath+'coa') IN 0
ENDIF

WAIT WINDOW NOWAIT 'Checking for out of balance batches...'

SELECT cBatch, ddate, cYear, cPeriod, SUM(ndebits) AS dr, SUM(ncredits) AS cr ;
   FROM glmaster ;
   INTO CURSOR temp1 ;
   WHERE NOT DELETED() ;
   ORDER BY cBatch ;
   GROUP BY cBatch

SELECT cBatch, ddate, cYear, cPeriod, dr, cr, SUM(dr-cr) AS bal ;
   FROM temp1 ;
   INTO CURSOR temp2 ;
   ORDER BY cBatch ;
   GROUP BY cBatch

SELECT cBatch, ddate, cYear, cPeriod, dr, cr, bal, 'O' AS cType ;
   FROM temp2 ;
   WHERE bal <> 0 ;
   INTO CURSOR outbal ;
   ORDER BY cBatch

WAIT WINDOW NOWAIT 'Checking for improper account usage...'

SELE cBatch, ddate, cYear, cPeriod, cacctno, ndebits as dr, ncredits cr, 'T' AS cType ;
   FROM glmaster ;
   WHERE glmaster.cacctno IN (SELECT cacctno FROM coa WHERE (ltitle OR ltotalacct)) ;
   INTO CURSOR badacct ;
   ORDER BY cBatch

WAIT WINDOW NOWAIT 'Checking for bad accounts in the G/L'

SELE cBatch, ddate, cYear, cPeriod, cacctno, ndebits as dr, ncredits as cr, 'B' AS cType ;
   FROM glmaster ;
   WHERE glmaster.cacctno NOT IN (SELECT cacctno FROM coa) ;
   INTO CURSOR oldacct ;
   ORDER BY cBatch

SELECT gltemp
APPEND FROM DBF('outbal')
APPEND FROM DBF('badacct')
APPEND FROM DBF('oldacct')

WAIT CLEAR

IF RECC('gltemp') <> 0  &&  Records, so bring up the report
   REPORT FORM chkbal.frx PREVIEW
   IF oMessage.CONFIRM('Should the report be sent to the printer now?')
      REPORT FORM chkbal.frx TO PRINTER PROMPT NOCONSOLE NOEJECT
   ENDIF
ELSE
   oMessage.DISPLAY('There were no general ledger problems found.')
ENDIF

IF USED('temp1')
   USE IN temp1
ENDIF
IF USED('temp2')
   USE IN temp2
ENDIF
IF USED('outbal')
   USE IN outbal
ENDIF
IF USED('badacct')
   USE IN badacct
ENDIF
IF USED('oldacct')
   USE IN oldacct
ENDIF
IF USED('coa')
   USE IN coa
ENDIF
IF USED('glmaster')
   USE IN glmaster
ENDIF
IF USED('gltemp')
   USE IN gltemp
ENDIF
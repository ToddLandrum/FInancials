LOCAL oRegistry
set dele on
oRegistry = findglobalobject('cmRegistry')

*
*  Clean up expense and income files
*
IF NOT USED('inchdr')
   USE inchdr IN 0
ENDIF
IF NOT USED('income')
   USE income IN 0
ENDIF
IF NOT USED('exphdr')
   USE exphdr IN 0
ENDIF
IF NOT USED('expense')
   USE expense IN 0
ENDIF

SET DELETED ON
WAIT WIND NOWAIT 'Cleaning up well expense file...Resetting Keys...'

SELE expense
SCAN
   REPL cidexph WITH 'xx'
ENDSCAN

WAIT WIND NOWAIT 'Cleaning up well expense file...Finding Hdrs...'

SELE cidexpe, cidexph, cRunyear AS cyear, cperiod, cwellid, nRunNo FROM expense WHERE cidexph NOT IN (SELECT cidexph FROM exphdr) INTO CURSOR tempexph
IF _TALLY > 0
   SELE tempexph
   SCAN
      SCATTER MEMVAR
      IF NOT USED('exphdr')
         USE exphdr IN 0
      ENDIF
      IF NOT USED('expense')
         USE expense IN 0
      ENDIF
      SELE exphdr
      LOCATE FOR cWellID = m.cwellid AND cYear = m.cyear AND nRunNo = m.nRunNo
      IF FOUND()
         m.cidexph = cidexph
         SELE expense
         LOCATE FOR cidexpe = m.cidexpe
         IF FOUND()
            REPL cidexph WITH m.cidexph
         ENDIF
      ELSE
         m.cidexph =  oRegistry.incrementcounter('%Shared.counters.batch')
         SET DELE OFF
         IF NOT USED('exphdr')
            USE exphdr IN 0
         ENDIF
         IF NOT USED('expense')
            USE expense IN 0
         ENDIF

         SELE exphdr
         SET ORDER TO cidexph
         DO WHILE SEEK(m.cidexph)
            m.cidexph =  oRegistry.incrementcounter('%Shared.counters.batch')
         ENDDO
         SET DELE ON
         INSERT INTO exphdr FROM MEMVAR
      ENDIF
   ENDSCAN
ENDIF

SELE cwellid, cyear, cperiod, cidexph, nRunNo ;
   FROM exphdr ;
   INTO CURSOR tempexph ;
   ORDER BY cwellid, cyear, nRunNo;
   GROUP BY cwellid, cyear, nRunNo

WAIT WIND NOWAIT 'Cleaning up well expense file...Updating Hdrs...'
IF _TALLY > 0
   IF NOT USED('exphdr')
      USE exphdr IN 0
   ENDIF
   IF NOT USED('expense')
      USE expense IN 0
   ENDIF
   SELE tempexph
   SCAN
      SCATTER MEMVAR
      SELE expense
      SCAN FOR cwellid+cyear = m.cwellid+m.cyear AND nRunNo = m.nRunNo AND cidexph <> m.cidexph
         REPL cidexph WITH m.cidexph
      ENDSCAN
   ENDSCAN
ENDIF

SELE cidexph FROM exphdr WHERE cidexph NOT IN (SELE cidexph FROM expense) INTO CURSOR tempexp

WAIT WIND NOWAIT 'Cleaning up well expense file...Removing Bad Hdrs...'
IF _TALLY > 0
   IF NOT USED('exphdr')
      USE exphdr IN 0
   ENDIF
   IF NOT USED('expense')
      USE expense IN 0
   ENDIF

   SELE exphdr
   SET ORDER TO cidexph
   SELE tempexp
   SCAN
      m.cidexph = cidexph
      SELE exphdr
      IF SEEK(m.cidexph)
         DELE NEXT 1
      ENDIF
   ENDSCAN
ENDIF

WAIT WIND NOWAIT 'Cleaning up well income file... Resetting Keys...'

IF NOT USED('inchdr')
   USE inchdr IN 0
ENDIF
IF NOT USED('income')
   USE income IN 0
ENDIF

SELE income
SCAN
   REPL cidinch WITH 'xx'
ENDSCAN

SELE cidinco, cidinch, cRunyear AS cYear, cperiod, cwellid, nRunNo FROM income WHERE cidinch NOT IN (SELECT cidinch FROM inchdr) ;
   INTO CURSOR tempinch

WAIT WIND NOWAIT 'Cleaning up well income file... Finding Hdrs...'
IF _TALLY > 0
   SELE tempinch
   SCAN
      SCATTER MEMVAR
      IF NOT USED('inchdr')
         USE inchdr IN 0
      ENDIF
      IF NOT USED('income')
         USE income IN 0
      ENDIF

      SELE inchdr
      LOCATE FOR cwellid+cyear = m.cwellid+m.cyear AND nRunNo = m.nRunNo
      IF FOUND()
         m.cidinch = cidinch
         SELE income
         LOCATE FOR cidinco = m.cidinco
         IF FOUND()
            REPL cidinch WITH m.cidinch
         ENDIF
      ELSE
         m.cidinch =  oRegistry.incrementcounter('%Shared.counters.batch')
         SET DELE OFF
         SELE inchdr
         SET ORDER TO cidinch
         DO WHILE SEEK(m.cidinch)
            m.cidinch =  oRegistry.incrementcounter('%Shared.counters.batch')
         ENDDO
         SET DELE ON
         INSERT INTO inchdr FROM MEMVAR
         SELE income
         LOCATE FOR cidinco = m.cidinco
         IF FOUND()
            REPL cidinch WITH m.cidinch
         ENDIF
      ENDIF
   ENDSCAN
ENDIF

SELE cwellid, cyear, cperiod, cidinch, nRunNo ;
   FROM inchdr ;
   INTO CURSOR tempinch ;
   ORDER BY cwellid, cyear, nRunNo ;
   GROUP BY cwellid, cyear, nRunNo

WAIT WIND NOWAIT 'Cleaning up well income file... Updating Hdrs...'
IF _TALLY > 0
   IF NOT USED('inchdr')
      USE inchdr IN 0
   ENDIF
   IF NOT USED('income')
      USE income IN 0
   ENDIF

   SELE tempinch
   SCAN
      SCATTER MEMVAR
      SELE income
      SCAN FOR cwellid+cyear = m.cwellid+m.cyear AND nRunNo = m.nRunNo AND cidinch <> m.cidinch
         REPL cidinch WITH m.cidinch
      ENDSCAN
   ENDSCAN
ENDIF

SELE cidinch FROM inchdr WHERE cidinch NOT IN (SELE cidinch FROM income) INTO CURSOR tempinc

WAIT WIND NOWAIT 'Cleaning up well income file... Removing Bad Hdrs...'
IF _TALLY > 0
   IF NOT USED('inchdr')
      USE inchdr IN 0
   ENDIF
   IF NOT USED('income')
      USE income IN 0
   ENDIF

   SELE inchdr
   SET ORDER TO cidinch
   SELE tempinc
   SCAN
      m.cidinch = cidinch
      SELE inchdr
      IF SEEK(m.cidinch)
         DELE NEXT 1
      ENDIF
   ENDSCAN
ENDIF

WAIT CLEAR

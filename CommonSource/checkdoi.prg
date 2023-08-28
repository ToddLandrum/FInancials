LPARAMETERS tlOnlyNRIandWI, tcGroup, tnDataSessionID
*
*  Check the doi for each well to make sure they total 100%
*  Called from the Check DOI menu under DOI Utilities
*

IF VARTYPE(tnDataSessionID) = 'N'
   SET DATASESSION TO tnDataSessionID
ENDIF 

WAIT WIND NOWAIT 'Checking DOI For Problems...'

oMessage = findglobalobject('cmMessage')

IF TYPE('m.goApp') = 'O'
   lcPath = ALLTRIM(m.goApp.cDataFilePath)
ELSE
   lcPath = 'Data\'
ENDIF

SET DELETED ON

swselect('wellinv')
swselect('wells')
swselect('investor')

IF USED('tempdoi')
   USE IN tempdoi
ENDIF

IF USED('tempdoi1')
   USE IN tempdoi1
ENDIF

IF USED('nodoi')
   USE IN nodoi
ENDIF

IF tcGroup = '**'
SELECT wellinv.cwellid, wells.cwellname, wells.cgroup, wellinv.cdeck, ;
   SUM(nworkint) AS nworkint,  ;
   SUM(nrevoil) AS ntotoil, ;
   SUM(nrevgas) AS ntotgas, ;
   SUM(nrevtrp) AS ntottrp, ;
   SUM(nrevoth) AS ntototh, ;
   SUM(nrevmisc1) AS ntotmisc1, ;
   SUM(nrevmisc2) AS ntotmisc2, ;
   SUM(nworkint) AS ntotwork, ;
   SUM(nrevtax1) AS nrevtax1, ;
   SUM(nrevtax2) AS nrevtax2, ;
   SUM(nrevtax3) AS nrevtax3, ;
   SUM(nrevtax4) AS nrevtax4, ;
   SUM(nrevtax5) AS nrevtax5, ;
   SUM(nrevtax6) AS nrevtax6, ;
   SUM(nrevtax7) AS nrevtax7, ;
   SUM(nrevtax8) AS nrevtax8, ;
   SUM(nrevtax9) AS nrevtax9, ;
   SUM(nrevtax10) AS nrevtax10, ;
   SUM(nrevtax11) AS nrevtax11, ;
   SUM(nrevtax12) AS nrevtax12, ;
   SUM(nintclass1) AS nintclass1,  ;
   SUM(nintclass2) AS nintclass2,  ;
   SUM(nintclass3) AS nintclass3,  ;
   SUM(nintclass4) AS nintclass4,  ;
   SUM(nintclass5) AS nintclass5,  ;
   SUM(nbcpint) AS nbcpint,  ;
   SUM(nacpint) AS nacpint,  ;
   SUM(napoint) AS napoint,  ;
   SUM(nplugpct) as nplugpct, ;
   .F. AS lDeleted,  ;
   'A' AS cSection ;
   FROM wellinv, wells ;
   WHERE wellinv.cwellid = wells.cwellid ;
   AND NOT DELETED()  ;
   AND wellinv.cOwnerID IN(SELECT cOwnerID FROM investor)  ;
   INTO CURSOR tempdoi READWRITE  ;
   ORDER BY wellinv.cwellid, cSection ;
   GROUP BY wellinv.cwellid, wellinv.cdeck
ELSE
SELECT wellinv.cwellid, wells.cwellname, wells.cgroup, wellinv.cdeck, ;
   SUM(nworkint) AS nworkint,  ;
   SUM(nrevoil) AS ntotoil, ;
   SUM(nrevgas) AS ntotgas, ;
   SUM(nrevtrp) AS ntottrp, ;
   SUM(nrevoth) AS ntototh, ;
   SUM(nrevmisc1) AS ntotmisc1, ;
   SUM(nrevmisc2) AS ntotmisc2, ;
   SUM(nworkint) AS ntotwork, ;
   SUM(nrevtax1) AS nrevtax1, ;
   SUM(nrevtax2) AS nrevtax2, ;
   SUM(nrevtax3) AS nrevtax3, ;
   SUM(nrevtax4) AS nrevtax4, ;
   SUM(nrevtax5) AS nrevtax5, ;
   SUM(nrevtax6) AS nrevtax6, ;
   SUM(nrevtax7) AS nrevtax7, ;
   SUM(nrevtax8) AS nrevtax8, ;
   SUM(nrevtax9) AS nrevtax9, ;
   SUM(nrevtax10) AS nrevtax10, ;
   SUM(nrevtax11) AS nrevtax11, ;
   SUM(nrevtax12) AS nrevtax12, ;
   SUM(nintclass1) AS nintclass1,  ;
   SUM(nintclass2) AS nintclass2,  ;
   SUM(nintclass3) AS nintclass3,  ;
   SUM(nintclass4) AS nintclass4,  ;
   SUM(nintclass5) AS nintclass5,  ;
   SUM(nbcpint) AS nbcpint,  ;
   SUM(nacpint) AS nacpint,  ;
   SUM(napoint) AS napoint,  ;
   SUM(nplugpct) as nplugpct, ;
   .F. AS lDeleted,  ;
   'A' AS cSection ;
   FROM wellinv, wells ;
   WHERE wellinv.cwellid = wells.cwellid ;
   AND wells.cgroup = tcGroup ;
   AND NOT DELETED()  ;
   AND wellinv.cOwnerID IN(SELECT cOwnerID FROM investor)  ;
   INTO CURSOR tempdoi READWRITE  ;
   ORDER BY wellinv.cwellid, cSection ;
   GROUP BY wellinv.cwellid, wellinv.cdeck
ENDIF 
llBadDOI = .F.


IF _TALLY > 0
   SELECT tempdoi
   SCAN
      SCATTER MEMVAR

      IF m.nworkint <> 100 AND m.nworkint <> 0
         llBadDOI = .T.
         LOOP
      ENDIF
      IF m.ntotoil <> 100 AND m.ntotoil <> 0
         llBadDOI = .T.
         LOOP
      ENDIF
      IF m.ntotgas <> 100 AND m.ntotgas <> 0
         llBadDOI = .T.
         LOOP
      ENDIF

      IF NOT tlOnlyNRIandWI
         IF m.ntottrp <> 100 AND m.ntottrp <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.ntotmisc1 <> 100 AND m.ntotmisc1 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.ntotmisc2 <> 100 AND m.ntotmisc2 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.ntototh <> 100 AND m.ntototh <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax1 <> 100 AND m.nrevtax1 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax2 <> 100 AND m.nrevtax2 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax3 <> 100 AND m.nrevtax3 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax4 <> 100 AND m.nrevtax4 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax5 <> 100 AND m.nrevtax5 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax6 <> 100 AND m.nrevtax6 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax7 <> 100 AND m.nrevtax7 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax8 <> 100 AND m.nrevtax8 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax9 <> 100 AND m.nrevtax9 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax10 <> 100 AND m.nrevtax10 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax11 <> 100 AND m.nrevtax11 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nrevtax12 <> 100 AND m.nrevtax12 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nintclass1 <> 100 AND m.nintclass1 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nintclass2 <> 100 AND m.nintclass2 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nintclass3 <> 100 AND m.nintclass3 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nintclass4 <> 100 AND m.nintclass4 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nintclass5 <> 100 AND m.nintclass5 <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nbcpint <> 100 AND m.nbcpint <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nacpint <> 100 AND m.nacpint <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.napoint <> 100 AND m.napoint <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
         IF m.nplugpct <> 100 AND m.nplugpct <> 0
            llBadDOI = .T.
            LOOP
         ENDIF
      ENDIF
      REPL lDeleted WITH .T.
   ENDSCAN
   SELECT tempdoi
   DELE FOR lDeleted
ENDIF

SELECT cwellid, cwellname, cdeck, 'B' AS cSection FROM wells WHERE cwellid NOT IN(SELECT cwellid FROM wellinv)  ;
   INTO CURSOR nodoi

IF _TALLY <> 0
   llBadDOI = .T.

   SELECT nodoi
   SCAN
      SCATTER MEMVAR
      INSERT INTO tempdoi FROM MEMVAR
   ENDSCAN
ENDIF

IF llBadDOI
    m.goapp.oReport.cAlias             = 'tempdoi'
    m.goapp.oReport.DATASESSIONID      = tnDataSessionID
    m.goapp.oReport.cTitle1            = 'Division of Interest Problems'
    m.goapp.oReport.cTitle2            = ''
    m.goapp.oReport.cProcessor         = ''
    m.goapp.oReport.cSortOrder         = ''
    m.goapp.oReport.cSelectionCriteria = ''
    m.goapp.oReport.cReportName        = 'dmbaddoi.frx'
    m.goapp.oReport.CSVFilename        = 'Division of Interest Problems Report'
    m.goapp.oReport.cFriendlyName      = 'Division of Interest Problems Report'
    llReturn                           = m.goapp.oReport.SendReport('S', .F., .F.)
ELSE
   oMessage.DISPLAY('There were no DOI problems found...')
ENDIF

IF USED('tempdoi')
   USE IN tempdoi
ENDIF
IF USED('tempdoi1')
   USE IN tempdoi1
ENDIF

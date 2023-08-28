LOCAL oDist

IF FILE('datafiles\forcenet.txt')
   llForce = .t.
ELSE
   llForce = .f.
ENDIF 

m.goapp.oLogger.StartProcess('Netting Data')

IF NOT USED('compmast')
   USE (m.goapp.cCommonFolder + 'compmast') IN 0
ENDIF
SELECT compmast
LOCATE FOR cidcomp == m.goapp.cidcomp
IF FOUND() AND LEFT(xflag, 2) # 'IR'
   swselect('investor')
   SET ORDER TO cownerid
   GO TOP
   tcBegID = cownerid
   GO BOTT
   tcEndID = cownerid

   oDist = CREATEOBJECT('distproc', tcBegID, tcEndID,  ;
        '01',  ;
        '2017',  ;
        '00', 'W', DATE(), .F., 1)


   WAIT WINDOW NOWAIT 'Netting Expenses...'
   swselect('expense', .T.)
   LOCATE FOR (nrunnorev = 0 OR nrunnojib = 0) AND (nnetamount = 0 or llForce)
   IF FOUND()
      SCAN FOR (nrunnorev = 0 OR nrunnojib = 0) AND (nnetamount = 0 or llForce)
         SCATTER MEMVAR
         m.nnetamount = swNetExp(m.namount, m.cwellid, NETDOWN, m.cexpclass, NETDUMMY)
         REPLACE nnetamount WITH m.nnetamount
      ENDSCAN
   ENDIF


   WAIT WINDOW NOWAIT 'Netting Expenses...'
   swselect('expsusp', .T.)
   LOCATE FOR (nrunnorev = 0 OR nrunnojib = 0) AND (nnetamount = 0 or llForce)
   IF FOUND()
      SCAN FOR (nrunnorev = 0 OR nrunnojib = 0) AND (nnetamount = 0 or llForce)
         SCATTER MEMVAR
         m.nnetamount = swNetExp(m.namount, m.cwellid, NETDOWN, m.cexpclass, NETDUMMY)
         REPLACE nnetamount WITH m.nnetamount
      ENDSCAN
   ENDIF

   WAIT WINDOW NOWAIT 'Netting Revenue...'
   swselect('income', .T.)
   LOCATE FOR nrunno= 0 AND (nnetamount = 0 or llForce)
   IF FOUND()
      SCAN FOR nrunno= 0 AND (nnetamount = 0 or llForce)
         SCATTER MEMVAR

         lnamount = m.ntotalinc
         lcwellid = m.cwellid
         lcrevkey = m.crevkey

         DO CASE
            CASE NOT EMPTY(m.cownerid)
               swselect('investor')
               IF SEEK(m.cownerid) AND lDummy
                  lnNet      = 0
                  lnNetUnits = 0
               ELSE
                  lnNet      = lnamount
                  lnNetUnits = m.nUnits
               ENDIF
            CASE INLIST(csource, 'BBL', 'OTAX1', 'OTAX2', 'OTAX3', 'OTAX4')
               IF csource = 'BBL'
                  lnNet      = oDist.netrev(lcwellid, lnamount, 'O', .F., .T., .F., .F., .F., .F.)
                  lnNetUnits = oDist.netrev(lcwellid, m.nUnits, 'O', .F., .T., .F., .F., .F., .F.)
               ELSE
                  lnNet      = oDist.netrev(lcwellid, lnamount, 'O' + RIGHT(TRIM(csource), 1), .F., .T., .F., .F., .F., .F.)
                  lnNetUnits = 0
               ENDIF
            CASE INLIST(csource, 'MCF', 'GTAX1', 'GTAX2', 'GTAX3', 'GTAX4')
               IF csource = 'MCF'
                  lnNet      = oDist.netrev(lcwellid, lnamount, 'G', .F., .T., .F., .F., .F., .F.)
                  lnNetUnits = oDist.netrev(lcwellid, m.nUnits, 'G', .F., .T., .F., .F., .F., .F.)
               ELSE
                  lnNet      = oDist.netrev(lcwellid, lnamount, 'G' + RIGHT(TRIM(csource), 1), .F., .T., .F., .F., .F., .F.)
                  lnNetUnits = 0
               ENDIF
            CASE INLIST(csource, 'OTH', 'PTAX1', 'PTAX2', 'PTAX3', 'PTAX4')
               lnNet      = oDist.netrev(lcwellid, lnamount, 'P', .F., .T., .F., .F., .F., .F.)
               lnNetUnits = oDist.netrev(lcwellid, m.nUnits, 'P', .F., .T., .F., .F., .F., .F.)
            CASE csource = 'TRANS'
               lnNet      = oDist.netrev(lcwellid, lnamount, 'T', .F., .T., .F., .F., .F., .F.)
               lnNetUnits = oDist.netrev(lcwellid, m.nUnits, 'T', .F., .T., .F., .F., .F., .F.)
            CASE csource = 'MISC1'
               lnNet      = oDist.netrev(lcwellid, lnamount, '1', .F., .T., .F., .F., .F., .F.)
               lnNetUnits = oDist.netrev(lcwellid, m.nUnits, '1', .F., .T., .F., .F., .F., .F.)
            CASE csource = 'MISC2'
               lnNet      = oDist.netrev(lcwellid, lnamount, '2', .F., .T., .F., .F., .F., .F.)
               lnNetUnits = oDist.netrev(lcwellid, m.nUnits, '2', .F., .T., .F., .F., .F., .F.)
            OTHERWISE
               lnNet      = lnamount
               lnNetUnits = m.nUnits
         ENDCASE

         SELECT income
         REPLACE nnetamount WITH lnNet, ;
            nNetUnits  WITH lnNetUnits
      ENDSCAN
   ENDIF

   swselect('incsusp', .T.)
   LOCATE FOR nrunno= 0 AND (nnetamount = 0 or llForce)
   IF FOUND()
      SCAN FOR nrunno= 0 AND (nnetamount = 0 or llForce)
         SCATTER MEMVAR

         lnamount = m.ntotalinc
         lcwellid = m.cwellid
         lcrevkey = m.crevkey

         DO CASE
            CASE NOT EMPTY(m.cownerid)
               swselect('investor')
               IF SEEK(m.cownerid) AND lDummy
                  lnNet      = 0
                  lnNetUnits = 0
               ELSE
                  lnNet      = lnamount
                  lnNetUnits = m.nUnits
               ENDIF
            CASE INLIST(csource, 'BBL', 'OTAX1', 'OTAX2', 'OTAX3', 'OTAX4')
               IF csource = 'BBL'
                  lnNet      = oDist.netrev(lcwellid, lnamount, 'O', .F., .T., .F., .F., .F., .F.)
                  lnNetUnits = oDist.netrev(lcwellid, m.nUnits, 'O', .F., .T., .F., .F., .F., .F.)
               ELSE
                  lnNet      = oDist.netrev(lcwellid, lnamount, 'O' + RIGHT(TRIM(csource), 1), .F., .T., .F., .F., .F., .F.)
                  lnNetUnits = 0
               ENDIF
            CASE INLIST(csource, 'MCF', 'GTAX1', 'GTAX2', 'GTAX3', 'GTAX4')
               IF csource = 'MCF'
                  lnNet      = oDist.netrev(lcwellid, lnamount, 'G', .F., .T., .F., .F., .F., .F.)
                  lnNetUnits = oDist.netrev(lcwellid, m.nUnits, 'G', .F., .T., .F., .F., .F., .F.)
               ELSE
                  lnNet      = oDist.netrev(lcwellid, lnamount, 'G' + RIGHT(TRIM(csource), 1), .F., .T., .F., .F., .F., .F.)
                  lnNetUnits = 0
               ENDIF
            CASE INLIST(csource, 'OTH', 'PTAX1', 'PTAX2', 'PTAX3', 'PTAX4')
               lnNet      = oDist.netrev(lcwellid, lnamount, 'P', .F., .T., .F., .F., .F., .F.)
               lnNetUnits = oDist.netrev(lcwellid, m.nUnits, 'P', .F., .T., .F., .F., .F., .F.)
            CASE csource = 'TRANS'
               lnNet      = oDist.netrev(lcwellid, lnamount, 'T', .F., .T., .F., .F., .F., .F.)
               lnNetUnits = oDist.netrev(lcwellid, m.nUnits, 'T', .F., .T., .F., .F., .F., .F.)
            CASE csource = 'MISC1'
               lnNet      = oDist.netrev(lcwellid, lnamount, '1', .F., .T., .F., .F., .F., .F.)
               lnNetUnits = oDist.netrev(lcwellid, m.nUnits, '1', .F., .T., .F., .F., .F., .F.)
            CASE csource = 'MISC2'
               lnNet      = oDist.netrev(lcwellid, lnamount, '2', .F., .T., .F., .F., .F., .F.)
               lnNetUnits = oDist.netrev(lcwellid, m.nUnits, '2', .F., .T., .F., .F., .F., .F.)
            OTHERWISE
               lnNet      = lnamount
               lnNetUnits = m.nUnits
         ENDCASE

         SELECT incsusp
         REPLACE nnetamount WITH lnNet, ;
            nNetUnits  WITH lnNetUnits
      ENDSCAN
   ENDIF

   WAIT WINDOW NOWAIT 'Saving Changes...'
   BEGIN TRANSACTION
   llReturn = TABLEUPDATE(.T., .F., 'Income')
   IF llReturn
      llReturn = TABLEUPDATE(.T., .F., 'Incsusp')
      IF llReturn
         llReturn = TABLEUPDATE(.T., .F., 'Expense')
         IF llReturn
            llReturn = TABLEUPDATE(.T., .F., 'Expsusp')
         ENDIF
      ENDIF
   ENDIF

   IF NOT llReturn
      ROLLBACK
   ELSE
      END TRANSACTION
   ENDIF

   lcDesc = 'Netdata ran on: ' + TTOC(DATETIME())
   STRTOFILE(lcDesc, m.goapp.cCommonFolder + 'NetData.txt')
   WAIT CLEAR

   SELECT compmast
   REPLACE xflag WITH 'IR' + TTOC(DATETIME())
ENDIF
WAIT CLEAR

oDist = .NULL.
RELEASE oDist

m.goapp.oLogger.EndProcess('Netting Data')
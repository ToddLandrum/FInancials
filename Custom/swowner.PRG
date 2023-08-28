**************************************************
*-- Class Library:  c:\develop\codeminenew\custom\swowner.vcx
**************************************************

**************************************************
*-- Class:        swowner (c:\develop\codeminenew\custom\swowner.vcx)
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   07/26/08 12:16:00 PM
*

DEFINE CLASS swowner AS CUSTOM


   HEIGHT = 32
   WIDTH  = 100
   PROTECTED omessage
   omessage  = .F.
   oregistry = .F.
   cperiod   = .F.
   cyear     = .F.
   NAME      = 'swowner'


   PROCEDURE ownerstub
      LPARA tlStubRpt, tcRunYear, tnRunNo, tcOwner1, tcOwner2, tlSelective, tlSelected
      *  tlStubRpt - .T. = called from owner stub report
      *  tcRunYear - the run year when called from stub report
      *  tnRunNo   - the run no when called from stub report
      *  tcOwner1  - the 1st owner to include in the report
      *  tcOwner2  - the last owner to include in the report
      *  tlSelective - only print for owners marked to get this stmt.
      *  tlSelected - only print for the owners selected
      LOCAL lnCount, lnMaxLines, lcidChec, lnMax, lnProcess, llDistProc, tcFirst, tcLast, lcOldWellName
      LOCAL ldAcctDate, m.cIntType, tcYear, tcPeriod, tcGroup, llEcho, lnLineCount

      WAIT WIND NOWAIT 'Starting stub processing....'

      STORE ' ' TO tcFirst, tcLast, m.cIntType
      STORE {}  TO ldAcctDate

      IF FILE('echo.cfg')
         llEcho = .T.
      ELSE
         llEcho = .F.
      ENDIF

      IF USED('invtmp')
         USE IN invtmp
      ENDIF
      IF USED('invtmp1')
         USE IN invtmp1
      ENDIF

      * Create the selected cursor if it hasn't been created already
      IF NOT USED('selected')
         SELECT cid FROM pickchks INTO CURSOR SELECTED ORDER BY cid
      ENDIF


      lnMaxLines = 12  &&  Just initialize it - if there's no owner stub info, this variable isn't getting set as anything.... - BH 02/26/08

      * Make sure the owner pcts table is open
      swSelect('ownpcts')

      *
      *  Setup Global Options
      *
      swSelect('options')
      GO TOP
      glVouchMsg  = lvouchmsg
      glSkipPerf  = lSkipPerf
      gnStubLine  = nStubLine
      llVoidNext  = lVoidNext
      llDupStub   = lDupStub
      llSplitWell = ltwolines          &&  Need to change this variable name in the future.
      llHideComp  = lHideComp
      llChgPrice  = lChgPrice
      lcCheckType = cCheckType

      CREATE CURSOR stub ;
         (cid           C(10), ;
           cidtype        C(1), ;
           cpayee         C(60), ;
           cprogcode      C(10), ;
           ccheckno       C(10), ;
           cidchec        C(8), ;
           crptgroup      C(2), ;
           ilineno        I, ;
           cwellid        C(11), ;
           cwellname      C(60), ;
           ccounty        C(25), ;
           cstate         C(2), ;
           nincome        N(9, 2), ;
           nbbl           N(12, 2), ;
           cIncType       C(1), ;
           cSuspType      C(1), ;
           nmcf           N(12, 2), ;
           nbblprice      N(12, 6), ;
           nmcfprice      N(12, 6), ;
           noilrev        N(12, 2), ;
           ngasrev        N(12, 2), ;
           cIntType       C(1), ;
           cDesc          C(60), ;
           cinvnum        C(20), ;
           dinvdate       D, ;
           dcheckdate     D, ;
           ninvtot        N(12, 2), ;
           namtpaid       N(12, 2), ;
           ndisctot       N(12, 2), ;
           nAmount        N(12, 2), ;
           dproddate      D, ;
           nexpense       N(9, 2), ;
           ntax           N(9, 2), ;
           ntaxes         N(9, 2), ;
           nnetcheck      N(9, 2), ;
           creference     C(20), ;
           nother         N(9, 2), ;
           cprodprd       C(5), ;
           crefid         C(20), ;
           cyear          C(4), ;
           cperiod        C(2), ;
           nunits         N(12, 2), ;
           nprice         N(12, 4), ;
           ntotalinc      N(12, 2), ;
           ntax1          N(12, 2), ;
           ntax2          N(12, 2), ;
           ntax3          N(12, 2), ;
           ntax4          N(12, 2), ;
           nexpcl0        N(12, 2), ;
           nexpcl1        N(12, 2), ;
           nexpcl2        N(12, 2), ;
           nexpcl3        N(12, 2), ;
           nexpcl4        N(12, 2), ;
           nexpcl5        N(12, 2), ;
           nowntax        N(12, 2), ;
           nnetval        N(12, 2), ;
           ninterest      N(11, 7), ;
           nowngross      N(12, 2), ;
           nWellGath      N(12, 2), ;
           nWellComp      N(12, 2), ;
           lskip          L, ;
           npageno        I, ;
           nRunNo_In      I, ;
           cRunYear_In    C(4), ;
           cGROUP         C(2), ;
           nbackwith      N(12, 2), ;
           ntaxwith       N(12, 2))


      * Set the defaults for <> of lines if it isn't specified.
      IF llDupStub
         IF gnStubLine = 0
            IF NOT llSplitWell
               gnStubLine = 12
            ELSE
               gnStubLine = 18
            ENDIF
         ENDIF
      ELSE
         * Set default lines to 12 when not specified.
         IF gnStubLine = 0
            gnStubLine = 12
         ENDIF
      ENDIF

      llDistProc = .F.

      * Make sure sysctl is open and the order is set
      swSelect('sysctl')
      SET ORDER TO cDMBatch

      swSelect('disbhist')
      lnX = AFIELDS(latempx)
      swSelect('ownpcts')
      lny = AFIELDS(latempy)
      DIMENSION latemp[lnx + lny - 1, 18]
      FOR x = 1 TO lnX
         FOR Y = 1 TO 18
            latemp[x, y] = latempx[x, y]
         ENDFOR
      ENDFOR
      FOR x = 1 TO lny - 1
         FOR Y = 1 TO 18
            latemp[x + lnx, y] = latempy[x + 1, y]
         ENDFOR
      ENDFOR
      FOR x = 1 TO lnX + lny - 1
         latemp[X, 7]  = ''
         latemp[X, 8]  = ''
         latemp[X, 9]  = ''
         latemp[X, 10] = ''
         latemp[X, 11] = ''
         latemp[X, 12] = ''
         latemp[X, 13] = ''
         latemp[X, 14] = ''
         latemp[X, 15] = ''
         latemp[X, 18] = ''
      ENDFOR
      CREATE CURSOR invtemp FROM ARRAY latemp

      CREATE CURSOR tempprds ;
         (cyear    C(4), ;
           nRunNo   I, ;
           cGROUP    C(2), ;
           cwellid   C(10), ;
           dAcctDate D, ;
           cDMBatch  C(8))

      lnProcess = 1

      IF NOT tlStubRpt
         SELECT pickchks
         lnMax = RECC()
         * If printing check stubs, we need to know what run the checks came from so
         * that they can be matched up with records from distproc
         SELECT  DISTINCT cbatch ;
             FROM pickchks ;
             INTO CURSOR laPeriod
         IF _TALLY = 1
            SELECT laPeriod
            lcDMBatch = cbatch
            swSelect('sysctl')
            SET ORDER TO cDMBatch
            IF SEEK(lcDMBatch)
               m.cDMBatch  = cDMBatch
               m.cyear     = crunyear
               m.nRunNo    = nRunNo
               m.cGROUP    = cGROUP
               m.dAcctDate = dAcctDate
               ldAcctDate  = dAcctDate
               lcRunYear   = m.cyear + PADL(TRANSFORM(m.nRunNo), 3, '0')
               SELECT  cwellid, ;
                       nRunNo, ;
                       crunyear AS cyear ;
                   FROM disbhist ;
                   WHERE crunyear + PADL(TRANSFORM(nRunNo), 3, '0') == lcRunYear ;
                       AND nRunNo_In = 0 ;
                       AND disbhist.crectype = 'R' ;
                       AND disbhist.cownerid IN (SELECT  cid ;
                                                     FROM pickchks) ;
                   INTO CURSOR temp ;
                   ORDER BY cwellid, crunyear, nRunNo ;
                   GROUP BY cwellid, crunyear, nRunNo
               SELECT temp
               SCAN
                  SCATTER MEMVAR
                  SELECT tempprds
                  LOCATE FOR cwellid = m.cwellid AND cyear = m.cyear AND nRunNo = m.nRunNo
                  IF NOT FOUND()
                     INSERT INTO tempprds FROM MEMVAR
                  ENDIF
               ENDSCAN

               SELECT  cwellid, ;
                       nRunNo_In AS nRunNo, ;
                       cRunYear_In AS cyear ;
                   FROM disbhist ;
                   WHERE crunyear + PADL(TRANSFORM(nRunNo), 3, '0') == lcRunYear ;
                       AND nRunNo_In # 0 ;
                       AND disbhist.crectype = 'R' ;
                       AND disbhist.cownerid IN (SELECT  cid ;
                                                     FROM pickchks) ;
                   INTO CURSOR temp ;
                   ORDER BY cwellid, cRunYear_In, nRunNo_In ;
                   GROUP BY cwellid, cRunYear_In, nRunNo_In

               SELECT temp
               SCAN
                  SCATTER MEMVAR
                  SELECT tempprds
                  LOCATE FOR cwellid = m.cwellid AND cyear = m.cyear AND nRunNo = m.nRunNo
                  IF NOT FOUND()
                     INSERT INTO tempprds FROM MEMVAR
                  ENDIF
               ENDSCAN
            ELSE
               SELECT pickchks
               m.cyear     = cyear
               m.cperiod   = cperiod
               m.cGROUP    = cGROUP
               m.cDMBatch  = ''
               m.dAcctDate = {}
               ldAcctDate  = {}
               lcRunYear   = '2999999'
               INSERT INTO tempprds FROM MEMVAR
            ENDIF

            SELECT pickchks
            GO TOP
            tcFirst  = cid
            GO BOTT
            tcLast   = cid

            *  We've got a single batch that we're referencing, so we can just tie directly back to that, and pull all the recs from
            *  disbhist for that run.
            SELECT  disbhist.*, ;
                    disbhist.ciddisb AS pkey, ;
                    ownpcts.* ;
                FROM disbhist, ownpcts ;
                WHERE cownerid IN (SELECT  cid ;
                                       FROM SELECTED) ;
                    AND disbhist.crectype = 'R' ;
                    AND crunyear + PADL(TRANSFORM(nRunNo), 3, '0') == lcRunYear ;
                    AND disbhist.ciddisb == ownpcts.ciddisb ;
                    AND INLIST(disbhist.crectype, 'R', 'P') ;
                INTO CURSOR invtmp1 ;
                ORDER BY cownerid, disbhist.cwellid

            IF _TALLY > 0
               SELECT invtemp
               APPEND FROM DBF('invtmp1')
            ENDIF

            IF USED('invtmp')
               USE IN invtmp
            ENDIF
            USE DBF('invtemp') AGAIN IN 0 ALIAS invtmp
         ELSE
            llDistProc = .F.
            SELECT laPeriod
            SCAN
               lcDMBatch = cbatch
               swSelect('sysctl')
               IF SEEK(lcDMBatch)
                  m.cDMBatch   = cDMBatch
                  m.cyear      = crunyear
                  m.nRunNo     = nRunNo
                  m.cGROUP     = cGROUP
                  m.dAcctDate  = dAcctDate
                  ldAcctDate   = dAcctDate
                  m.dcheckdate = dAcctDate
                  lcRunYear    = m.cyear + PADL(TRANSFORM(m.nRunNo), 3, '0')

                  SELECT  cwellid, ;
                          nRunNo AS nRunNo, ;
                          crunyear AS crunyear ;
                      FROM disbhist ;
                      WHERE crunyear + PADL(TRANSFORM(nRunNo), 3, '0') == lcRunYear ;
                          AND disbhist.crectype = 'R' ;
                          AND nRunNo_In = 0 ;
                      INTO CURSOR temp ;
                      ORDER BY cwellid, crunyear, nRunNo ;
                      GROUP BY cwellid, crunyear, nRunNo
                  SELECT temp
                  SCAN
                     SCATTER MEMVAR
                     SELECT tempprds
                     LOCATE FOR cwellid = m.cwellid AND cyear = m.crunyear AND nRunNo = m.nRunNo
                     IF NOT FOUND()
                        m.cyear = m.crunyear
                        INSERT INTO tempprds FROM MEMVAR
                     ENDIF
                  ENDSCAN

                  SELECT  * ;
                      FROM disbhist ;
                      WHERE crunyear + PADL(TRANSFORM(nRunNo), 3, '0') == lcRunYear ;
                          AND nRunNo_In # 0 ;
                          AND INLIST(disbhist.crectype, 'R', 'P') ;
                      INTO CURSOR temphist READWRITE

                  * Check to see if prior suspense is in invtmp and it includes payments that zero it out
                  * If any are found, remove them because we don't want to report on them here.
                  SELECT  *, ;
                          .F. AS junk ;
                      FROM temphist ;
                      WHERE temphist.cownerid IN (SELECT  cid ;
                                                      FROM pickchks) ;
                          AND crectype # 'P' AND (crunyear + PADL(TRANSFORM(nRunNo), 3, '0') # cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0')) ;
                      INTO CURSOR tempinvtmp READWRITE

                  SELECT  *, ;
                          .F. AS junk ;
                      FROM temphist ;
                      WHERE temphist.cownerid IN (SELECT  cid ;
                                                      FROM pickchks) ;
                          AND crectype = 'P' ;
                      INTO CURSOR tmptmp
                  SELECT tempinvtmp
                  APPEND FROM DBF('tmptmp')
                  USE IN tmptmp

                  SELECT cownerid, SUM(nnetcheck) AS nnetcheck FROM tempinvtmp WHERE nRunNo_In # 0 INTO CURSOR tempck ORDER BY cownerid GROUP BY cownerid
                  SCAN FOR tempck.nnetcheck = 0
                     * Delete the entries from invtmp if they have been zeroed out by a payment
                     SELECT temphist
                     DELETE FOR cownerid == tempck.cownerid AND nRunNo_In # 0 AND cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') < lcRunYear
                  ENDSCAN

                  SELECT  cwellid, ;
                          nRunNo_In AS nRunNo, ;
                          cRunYear_In AS crunyear ;
                      FROM temphist ;
                      WHERE crunyear + PADL(TRANSFORM(nRunNo), 3, '0') == lcRunYear ;
                          AND nRunNo_In # 0 ;
                      INTO CURSOR temp ;
                      ORDER BY cwellid, cRunYear_In, nRunNo_In ;
                      GROUP BY cwellid, cRunYear_In, nRunNo_In

                  SELECT temp
                  SCAN
                     SCATTER MEMVAR
                     SELECT tempprds
                     LOCATE FOR cwellid = m.cwellid AND cyear = m.crunyear AND nRunNo = m.nRunNo
                     IF NOT FOUND()
                        m.cyear = m.crunyear
                        INSERT INTO tempprds FROM MEMVAR
                     ENDIF
                  ENDSCAN
               ELSE
                  SELECT pickchks
                  m.cyear     = cyear
                  m.cperiod   = cperiod
                  m.cGROUP    = cGROUP
                  m.cDMBatch  = ''
                  m.dAcctDate = {}
                  ldAcctDate  = {}
                  lcRunYear   = '2999999'
                  INSERT INTO tempprds FROM MEMVAR
               ENDIF
            ENDSCAN

            SELECT pickchks
            GO TOP
            tcFirst  = cid
            GO BOTT
            tcLast   = cid

            *  Changed from doing a scan of tempprds to doing a scan of the laPeriod cursor.  This has the run number in it, so
            *  we can just pull the data from disbhist based on that.  No need to match by runno and well ID from the convoluted
            *  mess that was being created in tempprds, when we've got a good cursor with the data right in it, and we just pull
            *  everything for that run.
            SELECT laPeriod
            SCAN
               lcDMBatch = cbatch
               swSelect('sysctl')
               IF SEEK(lcDMBatch)
                  m.cDMBatch   = cDMBatch
                  m.cyear      = crunyear
                  m.nRunNo     = nRunNo
                  m.cGROUP     = cGROUP
                  m.dAcctDate  = dAcctDate
                  ldAcctDate   = dAcctDate
                  m.dcheckdate = dAcctDate
                  lcRunYear    = m.cyear + PADL(TRANSFORM(m.nRunNo), 3, '0')

                  SELECT  disbhist.*, ;
                          disbhist.ciddisb AS pkey, ;
                          ownpcts.* ;
                      FROM disbhist, ownpcts ;
                      WHERE cownerid IN (SELECT  cid ;
                                             FROM SELECTED) ;
                          AND crunyear + PADL(TRANSFORM(nRunNo), 3, '0') = lcRunYear ;
                          AND disbhist.ciddisb == ownpcts.ciddisb ;
                          AND INLIST(disbhist.crectype, 'R', 'P') ;
                      INTO CURSOR invtmp1 ;
                      ORDER BY cownerid, disbhist.cwellid

                  IF _TALLY > 0
                     SELECT invtemp
                     APPEND FROM DBF('invtmp1')
                  ENDIF
               ENDIF
            ENDSCAN

            IF USED('invtmp')
               USE IN invtmp
            ENDIF
            USE DBF('invtemp') AGAIN IN 0 ALIAS invtmp
         ENDIF
      ELSE
         * Stub Report
         SELE sysctl
         LOCATE FOR crunyear = tcRunYear AND nRunNo = tnRunNo AND ctypeclose = 'R'
         IF FOUND()
            m.cDMBatch   = cDMBatch
            m.cyear      = cyear
            m.nRunNo     = nRunNo
            m.cGROUP     = cGROUP
            m.dAcctDate  = dAcctDate
            ldAcctDate   = dAcctDate
            m.dcheckdate = dAcctDate
            lcRunYear    = m.cyear + PADL(TRANSFORM(m.nRunNo), 3, '0')

            SELECT  cwellid, ;
                    nRunNo AS nRunNo, ;
                    crunyear AS crunyear ;
                FROM disbhist ;
                WHERE crunyear + PADL(TRANSFORM(nRunNo), 3, '0') = lcRunYear ;
                    AND nRunNo_In = 0 ;
                    AND disbhist.crectype = 'R' ;
                INTO CURSOR temp ;
                ORDER BY cwellid, crunyear, nRunNo ;
                GROUP BY cwellid, crunyear, nRunNo
            SELECT temp
            SCAN
               SCATTER MEMVAR
               SELECT tempprds
               LOCATE FOR cwellid = m.cwellid AND cyear = m.crunyear AND nRunNo = m.nRunNo
               IF NOT FOUND()
                  m.cyear = m.crunyear
                  INSERT INTO tempprds FROM MEMVAR
               ENDIF
            ENDSCAN

            SELECT  cwellid, ;
                    nRunNo_In AS nRunNo, ;
                    cRunYear_In AS crunyear ;
                FROM disbhist ;
                WHERE crunyear + PADL(TRANSFORM(nRunNo), 3, '0') = lcRunYear ;
                    AND nRunNo_In # 0 ;
                    AND disbhist.crectype = 'R' ;
                INTO CURSOR temp ;
                ORDER BY cwellid, cRunYear_In, nRunNo_In ;
                GROUP BY cwellid, cRunYear_In, nRunNo_In
            SELECT temp
            SCAN
               SCATTER MEMVAR
               SELECT tempprds
               LOCATE FOR cwellid = m.cwellid AND cyear = m.crunyear AND nRunNo = m.nRunNo
               IF NOT FOUND()
                  m.cyear = m.crunyear
                  INSERT INTO tempprds FROM MEMVAR
               ENDIF
            ENDSCAN
         ELSE
            RETURN
         ENDIF
         tcFirst = tcOwner1
         tcLast  = tcOwner2

         WAIT WIND NOWAIT 'Building stub work files....'
         lcRunYear = tcRunYear + PADL(TRANSFORM(tnRunNo), 3, '0')
         SELECT  disbhist.*, ;
                 disbhist.ciddisb AS pkey, ;
                 ownpcts.* ;
             FROM disbhist, ownpcts ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND crunyear + PADL(TRANSFORM(nRunNo), 3, '0') = lcRunYear ;
                 AND disbhist.crectype = 'R' ;
                 AND disbhist.ciddisb == ownpcts.ciddisb ;
             INTO CURSOR invtmp1 ;
             ORDER BY cownerid, disbhist.cwellid

         IF _TALLY > 0
            SELECT invtemp
            APPEND FROM DBF('invtmp1')
         ENDIF
         llDistProc = .T.
         IF USED('invtmp')
            USE IN invtmp
         ENDIF
         USE DBF('invtemp') AGAIN IN 0 ALIAS invtmp

      ENDIF

      SELECT tempprds
      SCAN
         SCATTER MEMVAR
         swSelect('groups')
         LOCATE FOR cGROUP == m.cGROUP AND lNetDef = .T.  &&  Netting, so skip out of the processing to delete negative wells
         IF FOUND()
            LOOP
         ELSE  &&  Not netting, so delete the negative wells - sum the totals for each well first, and then delete the negs

            IF USED('temp')
               USE IN temp
            ENDIF

            SELE cownerid, cwellid, SUM(nnetcheck) AS nnetcheck FROM invtmp ;
               WHERE crunyear == m.cyear AND nRunNo == m.nRunNo AND cGROUP == m.cGROUP ;
               INTO CURSOR temp GROUP BY cownerid, cwellid

            SELECT temp
            SCAN FOR nnetcheck < 0
               SELECT invtmp
               SCAN FOR cownerid = temp.cownerid AND cwellid = temp.cwellid AND crunyear = m.cyear AND nRunNo = m.nRunNo
                  DELETE NEXT 1
               ENDSCAN
            ENDSCAN

         ENDIF
      ENDSCAN


      *
      *  Get the fiscal year and period
      *
      IF m.goApp.lAMVersion
         oGL      = CREATEOBJECT('glmaint')
         lcYear   = oGL.getperiod(ldAcctDate, .T.)
         lcPeriod = oGL.getperiod(ldAcctDate, .F.)
      ENDIF

      IF tlStubRpt
         CREATE CURSOR pickchks ;
            (cid     C(10), ;
              cichec  C(8), ;
              ccheckno C(10), ;
              lnostub L, ;
              cbatch  C(8))
         SELE cownerid AS cid, m.cDMBatch AS cbatch, SPACE(8) AS cidchec, lnostubdetail AS lnostub ;
            FROM investor ;
            WHERE cownerid IN (SELECT cid FROM SELECTED) ;
            INTO CURSOR tempown ORDER BY cownerid
         m.cbatch  = m.cDMBatch
         m.cidchec = ''
         SELE pickchks
         APPEND FROM DBF('tempown')
      ENDIF

      IF USED('invtmp')

         *  Get Income Info

         SELECT  cwellid, ;
                 cyear, ;
                 cperiod, ;
                 csource, ;
                 nRunNo, ;
                 crunyear, ;
                 dRevDate, ;
                 SUM(ntotalinc) AS ntotalinc, ;
                 SUM(nunits) AS nunits, ;
                 nprice AS nrate, ;
                 '     ' AS cprodprd, ;
                 crefid, ;
                 cownerid ;
             FROM income ;
             WHERE cwellid + crunyear + PADL(TRANSFORM(nRunNo), 3, '0') IN (SELECT  cwellid + cyear + PADL(TRANSFORM(nRunNo), 3, '0') ;
                                                                                FROM tempprds) ;
             INTO CURSOR tempinc READWRITE ;
             ORDER BY cwellid, cyear, cperiod, csource, nRunNo, crunyear, cownerid ;
             GROUP BY cwellid, cyear, cperiod, csource, nRunNo, crunyear, cownerid
         INDEX ON cwellid + cyear + cperiod + csource TAG wellprd

         *  Special option for Echo Drilling   1/3/2005 pws
         IF llEcho
            INDEX ON cwellid + cyear + cperiod + csource + crefid TAG wellprd
         ENDIF

         *  Plug in the fiscal period
         IF m.goApp.lAMVersion
            m.cprodprd = lcPeriod + '/' + RIGHT(lcYear, 2)
         ENDIF

         * Check to see if prior suspense is in invtmp and it includes payments that zero it out
         * If any are found, remove them because we don't want to report on them here.
         SELECT  *, ;
                 .F. AS junk ;
             FROM invtmp ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND crectype # 'P' ;
                 AND NOT EMPTY(cRunYear_In) ;
                 AND (crunyear + PADL(TRANSFORM(nRunNo), 3, '0') # cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0')) ;
             INTO CURSOR tempinvtmp READWRITE

         SELECT  *, ;
                 .F. AS junk ;
             FROM disbhist ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND crunyear + PADL(TRANSFORM(nRunNo), 3, '0') == lcRunYear ;
                 AND crectype = 'P' ;
             INTO CURSOR tmptmp
         SELECT tempinvtmp
         APPEND FROM DBF('tmptmp')
         USE IN tmptmp

         SELECT cownerid, SUM(nnetcheck) AS nnetcheck FROM tempinvtmp WHERE nRunNo_In # 0 INTO CURSOR temp ORDER BY cownerid GROUP BY cownerid
         SCAN FOR temp.nnetcheck = 0
            * Delete the entries from invtmp if they have been zeroed out by a payment
            SELECT invtmp
            DELETE FOR cownerid == temp.cownerid AND nRunNo_In # 0
         ENDSCAN
         *
         *  Get stub info from invtmp
         *

         SET TALK ON
         SELECT  invtmp.cownerid AS cid, ;
                 invtmp.crectype, ;
                 invtmp.cwellid, ;
                 SUM(invtmp.nincome) AS nincome, ;
                 SUM(invtmp.nexpense) AS ntotale, ;
                 SUM(invtmp.nsevtaxes) AS ntaxes, ;
                 SUM(invtmp.nnetcheck) AS nnetcheck, ;
                 SUM(invtmp.nmiscrev1 + invtmp.nmiscrev2) AS nmiscrev, ;
                 IIF(EMPTY(invtmp.cdirect), 'N', invtmp.cdirect) AS cdirect, ;
                 invtmp.cprogcode, ;
                 invtmp.cGROUP, ;
                 invtmp.hyear, ;
                 invtmp.hperiod, ;
                 invtmp.cTypeInv AS cIntType, ;
                 IIF(EMPTY(invtmp.ctypeint), 'B', invtmp.ctypeint) AS cProdType, ;
                 invtmp.ljib, ;
                 invtmp.nrevgas, ;
                 invtmp.nworkint, ;
                 invtmp.nrevoil, ;
                 invtmp.nrevtrp, ;
                 invtmp.nrevoth, ;
                 invtmp.nrevmisc1, ;
                 invtmp.nrevmisc2, ;
                 SUM(invtmp.ntaxwith) AS ntaxwith, ;
                 SUM(invtmp.nbackwith) AS nbackwith, ;
                 invtmp.crunyear, ;
                 invtmp.nRunNo, ;
                 invtmp.lpayout, ;
                 invtmp.cSuspType, ;
                 invtmp.lmanual, ;
                 0000.00 AS nmcf, ;
                 0000.00 AS nbbl, ;
                 000000.00 AS nexpcl0, ;
                 000000.00 AS nexpcl1, ;
                 000000.00 AS nexpcl2, ;
                 000000.00 AS nexpcl3, ;
                 000000.00 AS nexpcl4, ;
                 000000.00 AS nexpcl5, ;
                 SUM(invtmp.noilrev) AS noilrev, ;
                 SUM(invtmp.ngasrev) AS ngasrev, ;
                 SUM(invtmp.nothrev) AS nothrev, ;
                 SUM(invtmp.ntrprev) AS ntrprev, ;
                 SUM(invtmp.nsevtaxes) AS nsevtaxes, ;
                 SUM(invtmp.nmiscrev1) AS nmiscrev1, ;
                 SUM(invtmp.nmiscrev2) AS nmiscrev2, ;
                 SUM(invtmp.nmktgexp) AS nmktgexp, ;
                 SUM(invtmp.ntotale1) AS ntotale1, ;
                 SUM(invtmp.ntotale2) AS ntotale2, ;
                 SUM(invtmp.ntotale3) AS ntotale3, ;
                 SUM(invtmp.ntotale4) AS ntotale4, ;
                 SUM(invtmp.ntotale5) AS ntotale5, ;
                 SUM(invtmp.nTotaleA) AS nTotaleA, ;
                 SUM(invtmp.nTotaleB) AS nTotaleB, ;
                 invtmp.noiltax1 AS nWellotax1, ;
                 invtmp.ngastax1 AS nWellgtax1, ;
                 invtmp.nothtax1 AS nWellptax1, ;
                 invtmp.noiltax2 AS nWellotax2, ;
                 invtmp.ngastax2 AS nWellgtax2, ;
                 invtmp.nothtax2 AS nWellptax2, ;
                 invtmp.noiltax3 AS nWellotax3, ;
                 invtmp.ngastax3 AS nWellgtax3, ;
                 invtmp.nothtax3 AS nWellptax3, ;
                 invtmp.noiltax4 AS nWellotax4, ;
                 invtmp.ngastax4 AS nWellgtax4, ;
                 invtmp.nothtax4 AS nWellptax4, ;
                 SUM(invtmp.noiltax1) AS noiltax1, ;
                 SUM(invtmp.ngastax1) AS ngastax1, ;
                 SUM(invtmp.nothtax1) AS nothtax1, ;
                 SUM(invtmp.noiltax2) AS noiltax2, ;
                 SUM(invtmp.ngastax2) AS ngastax2, ;
                 SUM(invtmp.nothtax2) AS nothtax2, ;
                 SUM(invtmp.noiltax3) AS noiltax3, ;
                 SUM(invtmp.ngastax3) AS ngastax3, ;
                 SUM(invtmp.nothtax3) AS nothtax3, ;
                 SUM(invtmp.noiltax4) AS noiltax4, ;
                 SUM(invtmp.ngastax4) AS ngastax4, ;
                 SUM(invtmp.nothtax4) AS nothtax4, ;
                 SUM(invtmp.ngather) AS ngather, ;
                 SUM(invtmp.ncompress) AS ncompress, ;
                 000000.00 AS nWellComp, ;
                 000000.00 AS nWellGath, ;
                 000000.00 AS ntax1, ;
                 000000.00 AS ntax2, ;
                 000000.00 AS ntax3, ;
                 000000.00 AS ntax4, ;
                 000000.00 AS nflatamt, ;
                 00000000.00 AS ngrossoil, ;
                 00000000.00 AS ngrossgas, ;
                 invtmp.nrevtax1, ;
                 invtmp.nrevtax2, ;
                 invtmp.nrevtax3, ;
                 invtmp.nrevtax4, ;
                 invtmp.nrevtax5, ;
                 invtmp.nrevtax6, ;
                 invtmp.nrevtax7, ;
                 invtmp.nrevtax8, ;
                 invtmp.nrevtax9, ;
                 invtmp.nrevtax10, ;
                 invtmp.nrevtax11, ;
                 invtmp.nrevtax12, ;
                 invtmp.nRunNo_In, ;
                 invtmp.cRunYear_In, ;
                 SUM(invtmp.nflatrate) AS nflatrate, ;
                 wells.lgather, ;
                 wells.ngather AS ngathrate, ;
                 wells.lcompress, ;
                 wells.ncompress AS ncomprate, ;
                 'I' AS cidtype, ;
                 wells.cwellname ;
             FROM invtmp ;
             LEFT OUTER JOIN wells ;
                 ON invtmp.cwellid == wells.cwellid ;
             WHERE invtmp.crectype = 'R' ;
                 OR invtmp.crectype = 'P' ;
             INTO CURSOR disbchks READWRITE ;
             ORDER BY invtmp.cownerid, invtmp.cwellid, invtmp.cTypeInv, invtmp.crunyear, invtmp.nRunNo, invtmp.cRunYear_In, invtmp.nRunNo_In, invtmp.lmanual, ;
                 invtmp.hyear, invtmp.hperiod, invtmp.cGROUP, invtmp.ctypeint, invtmp.cprogcode, invtmp.cGROUP, invtmp.cSuspType ;
             GROUP BY invtmp.cownerid, invtmp.cwellid, invtmp.cTypeInv, invtmp.crunyear, invtmp.nRunNo, invtmp.cRunYear_In, invtmp.nRunNo_In, invtmp.lmanual, ;
                 invtmp.hyear, invtmp.hperiod, invtmp.cGROUP, invtmp.ctypeint, invtmp.cprogcode, invtmp.cGROUP, invtmp.cSuspType

         SELECT disbchks
         INDEX ON cid TAG cid
         INDEX ON crunyear TAG crunyear
         INDEX ON nRunNo TAG nRunNo
         SET TALK OFF
         WAIT CLEAR

         * Make sure the wells table is open and the order is set
         swSelect('wells')
         SET ORDER TO cwellid

         IF _TALLY # 0

            lcidChec = ' '  &&  Variable to tell us when the m.cidchec has changed

            * Get the total of checks being printed
            SELECT pickchks
            lnCheckCount = RECCOUNT()
            lnCurrent    = 1
            *
            *  Set up the progress bar
            *
            oProgress = THIS.omessage.ProgressBarEX('Building check stubs for the selected owners...')
            oProgress.SetProgressRange(0, lnCheckCount)

            * Scan through the checks being printed
            swSelect('investor')
            SET ORDER TO cownerid
            SELECT pickchks
            SCAN
               m.cidchec = cidchec
               lcOwner   = cid
               lcBatch   = cbatch
               llNoStub  = lnostub

               * Set the line count to 1
               lnLineCount = 1

               swSelect('investor')
               SET ORDER TO cownerid
               IF SEEK(lcOwner)
                  IF lDummy
                     LOOP
                  ENDIF
                  m.cpayee  = cownname
                  m.lExempt = lExempt
                  llDirDep  = lDirectDep
               ELSE
                  LOOP
               ENDIF

               oProgress.UpdateProgress(lnCurrent)
               oProgress.SetProgressMessage('Processing check: ' + TRANSFORM(lnCurrent) + ' of ' + TRANSFORM(lnCheckCount) + ' - ' + m.cpayee)
               lnCurrent = lnCurrent + 1

               * Get the run number associated with this check
               swSelect('sysctl')
               LOCATE FOR cDMBatch == lcBatch
               IF FOUND()
                  lcRunYear = cyear
                  lnRunNo   = nRunNo
               ELSE
                  lcRunYear = ''
                  lnRunNo   = 0
               ENDIF

               * Get the checkno and cidchec for this owner
               swSelect('checks')
               LOCATE FOR cid == lcOwner AND cbatch == lcBatch AND NOT lVoid
               IF FOUND()
                  m.cidchec  = cidchec
                  m.ccheckno = ccheckno
               ENDIF

               * Get the total of Backup Withholding
               *  Exclude lManual records, b/c the income/expenses/net on converted suspense aren't including nbackwith, so
               *  it makes stubs wrong when it prints a line for backup withholding - BH 02/17/11
               SELECT  SUM(nbackwith) AS nBack ;
                   FROM disbchks ;
                   WHERE nbackwith # 0 ;
                       AND cid = lcOwner ;
                       AND crunyear = lcRunYear ;
                       AND nRunNo = lnRunNo ;
                       AND NOT lmanual ;
                   INTO CURSOR tempback
               m.nBackwh = nBack
               USE IN tempback


               * Get the total of Tax Withholding
               *  Exclude lManual records, b/c the income/expenses/net on converted suspense aren't including ntaxwith, so
               *  it makes stubs wrong when it prints a line for tax withholding - BH 02/17/11
               SELECT  SUM(ntaxwith) AS ntaxes ;
                   FROM disbchks ;
                   WHERE ntaxwith # 0 ;
                       AND cid = lcOwner ;
                       AND crunyear = lcRunYear ;
                       AND nRunNo = lnRunNo ;
                       AND NOT lmanual ;
                   INTO CURSOR temptax
               m.nTaxwh = ntaxes
               USE IN temptax

               m.cid = ' '

               * Scan through the check detail for this owner
               SELECT disbchks
               SCAN FOR cid = lcOwner AND crunyear = lcRunYear AND nRunNo = lnRunNo AND crectype # 'P'
                  THIS.cyear   = disbchks.hyear
                  THIS.cperiod = disbchks.hperiod

                  * Get the gross well totals
                  swSelect('wellhist')
                  LOCATE FOR cwellid + hyear + hperiod = disbchks.cwellid + disbchks.hyear + disbchks.hperiod  AND crectype = 'R' AND ;
                     ((nRunNo = lnRunNo AND crunyear = lcRunYear) OR (nRunNo = disbchks.nRunNo_In AND crunyear = disbchks.cRunYear_In))
                  IF FOUND()
                     m.cwellid    = cwellid
                     m.nbbl       = ntotbbl * (disbchks.nrevoil / 100)
                     m.nmcf       = ntotmcf * (disbchks.nrevgas / 100)
                     m.ngrossoil  = ngrossoil
                     m.ngrossgas  = ngrossgas
                     m.nWellotax1 = ngbbltax1 + ntotbbltxw + ntotbbltxr
                     m.nWellgtax1 = ngmcftax1 + ntotmcftxw + ntotmcftxr
                     m.nWellptax1 = ngothtax1
                     m.nWellotax2 = ngbbltax2
                     m.nWellgtax2 = ngmcftax2
                     m.nWellptax2 = ngothtax2
                     m.nWellotax3 = ngbbltax3
                     m.nWellgtax3 = ngmcftax3
                     m.nWellptax3 = ngothtax3
                     m.nWellotax4 = ngbbltax4
                     m.nWellgtax4 = ngmcftax4
                     m.nWellptax4 = ngothtax4
                     m.ntax1      = ntotbbltx1 + ntotmcftx1 + ntotothtx1
                     m.ntax2      = ntotbbltx2 + ntotmcftx2 + ntotothtx2
                     m.ntax3      = ntotbbltx3 + ntotmcftx3 + ntotothtx3
                     m.ntax4      = ntotbbltx4 + ntotmcftx4 + ntotothtx4
                     m.nWellComp  = ncompress
                     m.nWellGath  = ngather
                     m.nflatamt   = nflatgas

                     * Store the well totals in the detail record
                     SELECT disbchks
                     REPLACE nbbl WITH m.nbbl, ;
                        nmcf     WITH m.nmcf, ;
                        ntax1    WITH m.ntax1, ;
                        ntax2    WITH m.ntax2, ;
                        ntax3    WITH m.ntax3, ;
                        ntax4    WITH m.ntax4, ;
                        ngrossoil WITH m.ngrossoil, ;
                        ngrossgas WITH m.ngrossgas, ;
                        nWellotax1 WITH m.nWellotax1, ;
                        nWellgtax1 WITH m.nWellgtax1, ;
                        nWellptax1 WITH m.nWellptax1, ;
                        nWellotax2 WITH m.nWellotax2, ;
                        nWellgtax2 WITH m.nWellgtax2, ;
                        nWellptax2 WITH m.nWellptax2, ;
                        nWellotax3 WITH m.nWellotax3, ;
                        nWellgtax3 WITH m.nWellgtax3, ;
                        nWellptax3 WITH m.nWellptax3, ;
                        nWellotax4 WITH m.nWellotax4, ;
                        nWellgtax4 WITH m.nWellgtax4, ;
                        nWellptax4 WITH m.nWellptax4, ;
                        nWellComp WITH m.nWellComp, ;
                        nWellGath WITH m.nWellGath, ;
                        nflatamt  WITH m.nflatamt
                  ENDIF

                  SELECT disbchks
                  m.cwellid  = ''
                  llOverflow = .F.
                  STORE ' ' TO jcWellID, jcIntType

                  *
                  *  Remove non producing wells
                  *
                  IF disbchks.nnetcheck = 0
                     LOOP
                  ENDIF

                  * If this is a stub report request check to see
                  * if this owner should get a stub report or detail
                  * report. If not a stub report loop out.
                  IF tlSelective
                     swSelect('investor')
                     SET ORDER TO cownerid
                     IF SEEK(lcOwner) AND nstmttype # 2
                        LOOP
                     ENDIF
                     SELECT disbchks
                  ENDIF

                  m.cyear   = disbchks.hyear
                  m.cperiod = disbchks.hperiod

                  * Get the well settings for taxes
                  SELE wells
                  IF SEEK(disbchks.cwellid)
                     llRoySevExempt = lroysevtx
                     SCATTER FIELDS LIKE lsev* MEMVAR
                     m.lDirGasPurch = lDirGasPurch
                     m.lDirOilPurch = lDirOilPurch
                     m.nroysevo     = nroysevo
                     m.nroysevg     = nroysevg
                     m.nwrksevo     = nwrksevo
                     m.nwrksevg     = nwrksevg
                     m.lusesev      = lusesev
                  ELSE
                     llRoySevExempt = .F.
                     STORE .F. TO m.lSev1O, m.lSev2O, m.lSev3O, m.lSev4O
                     STORE .F. TO m.lSev1G, m.lSev2G, m.lSev3G, m.lSev4G
                     STORE .F. TO m.lSev1P, m.lSev2P, m.lSev3P, m.lSev4P, m.lusesev
                     STORE 0 TO m.nroysevg, m.nroysevo, m.nwrksevg, m.nwrksevo
                  ENDIF

                  IF NOT m.goApp.lAMVersion
                     m.cprodprd = m.cperiod + '/' + RIGHT(m.cyear, 2)
                  ENDIF

                  *
                  *  If msg should be printed on wrk int stubs
                  *  remove detail and put msg in
                  *
                  SELE disbchks
                  IF NOT tlStubRpt
                     IF llNoStub
                        IF m.cid # disbchks.cid
                           m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                           m.cprodprd  = ' '
                           m.cIncType  = ' '
                           m.crptgroup = 'AA'
                           m.cid       = lcOwner
                           STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                           STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4
                           STORE 0 TO m.nnetval, m.nowngross, m.nexpense, m.ninterest, m.nowntax
                           SELECT stub
                           LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                           IF NOT FOUND()
                              INSERT INTO stub FROM MEMVAR
                           ENDIF
                           SELECT disbchks
                           GO BOTTOM
                           LOOP
                        ELSE
                           LOOP
                        ENDIF
                     ENDIF
                  ENDIF

                  * This is the next check. Need to finish processing
                  * for the previous check
                  IF m.cidchec # lcidChec
                     lcid = m.cid

                     * Report any backup withholding on this check
                     IF m.nBackwh # 0
                        m.cwellid   = '{'
                        m.cprogcode = ' '
                        m.crptgroup = 'AA'
                        m.cwellname = 'Backup Withholding Deducted'
                        m.nnetcheck = m.nBackwh * -1
                        m.cid       = lcOwner
                        STORE 0 TO m.nincome, m.nbbl, m.nmcf, m.nbblprice, m.nmcfprice, m.noilrev, m.ngasrev, ;
                           M.ninvtot, m.namtpaid, m.ndisctot, m.nAmount, m.nexpense, m.ntax, m.ntaxes, ;
                           M.ntotalinc, m.ninterest, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nowntax, ;
                           M.nowngross, m.nnetval, m.nunits, m.nprice
                        STORE ' ' TO m.ccounty, m.cstate
                        m.cIntType  = 'Z'
                        m.cIncType  = 'B'
                        m.cSuspType = 'L'
                        IF m.nnetcheck # 0
                           m.ilineno = 99
                           INSERT INTO stub FROM MEMVAR
                           IF llSplitWell
                              lnLineCount = lnLineCount + 2
                           ELSE
                              lnLineCount = lnLineCount + 1
                           ENDIF
                        ENDIF
                        STORE 0 TO m.nincome, m.nexpense, m.nother, m.ntaxes, m.nmcf, m.nbbl, m.ntax
                        STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval
                        STORE 0 TO m.nowngross, m.nexpense, m.ninterest, m.nowntax, m.nBack
                     ENDIF

                     llTaxWHProcessed = .F.
                     * Report any tax withholding on this check
                     IF m.nTaxwh # 0
                        m.cprogcode = ' '
                        m.cwellid   = '{'
                        m.crptgroup = 'AA'
                        m.cwellname = 'Tax Withholding Deducted'
                        m.nnetcheck = m.nTaxwh * -1
                        m.cid       = lcOwner
                        STORE 0 TO m.nincome, m.nbbl, m.nmcf, m.nbblprice, m.nmcfprice, m.noilrev, m.ngasrev, ;
                           M.ninvtot, m.namtpaid, m.ndisctot, m.nAmount, m.nexpense, m.ntax, m.ntaxes, ;
                           M.ntotalinc, m.ninterest, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nowntax, ;
                           M.nowngross, m.nnetval, m.nunits, m.nprice
                        STORE ' ' TO m.ccounty, m.cstate
                        m.cIncType  = 'T'
                        m.cIntType  = 'L'
                        m.cSuspType = 'Z'
                        IF m.nnetcheck # 0
                           m.ilineno = 99
                           INSERT INTO stub FROM MEMVAR
                           IF llSplitWell
                              lnLineCount = lnLineCount + 2
                           ELSE
                              IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                 lnLineCount = lnLineCount + 2
                              ELSE
                                 lnLineCount = lnLineCount + 1
                              ENDIF
                           ENDIF
                        ENDIF
                        STORE 0 TO m.nincome, m.nexpense, m.nother, m.ntaxes, m.nmcf, m.nbbl, m.ntax
                        STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval
                        STORE 0 TO m.nowngross, m.nexpense, m.ninterest, m.nowntax, m.ntaxes, m.nTaxwh
                        llTaxWHProcessed = .T.
                     ENDIF

                     llOverflow = .F.
                     m.cid      = lcid
                     m.cIntType = 'X'
                  ENDIF


                  * Look to see if the well or owner type changed
                  * If it did, and we're doing 2 lines per well,
                  * set the flag to tell the counter to add 2 each
                  * time.
                  IF llSplitWell AND (cwellid # m.cwellid OR (cIntType # m.cIntType))
                     llDupLine = .T.
                  ELSE
                     llDupLine = .F.
                  ENDIF

                  SELECT disbchks
                  SCATTER MEMVAR

                  * Swap the runno if this is from suspense so the original run is processed
                  * to get the detail
                  IF m.nRunNo_In # 0
                     m.nRunNo   = m.nRunNo_In
                     m.crunyear = m.cRunYear_In
                  ENDIF

                  IF ISNULL(m.cwellname)  &&  Reset to character if .NULL.
                     m.cwellname = ''
                  ENDIF

                  * Determine if this is a royalty interest being processed
                  IF m.cIntType # 'W'
                     llRoyaltyOwner = .T.
                  ELSE
                     llRoyaltyOwner = .F.
                  ENDIF

                  * Set the default number of lines on the stub if the count wasn't
                  * set in check preferences.
                  IF NOT tlStubRpt
                     IF NOT llVoidNext
                        IF gnStubLine = 0
                           lnMaxLines = 12
                        ELSE
                           lnMaxLines = gnStubLine
                        ENDIF
                     ELSE
                        lnMaxLines = 99999
                     ENDIF
                  ELSE
                     lnMaxLines = 999999999
                  ENDIF

                  *
                  *  Take away any direct paid income
                  *
                  DO CASE
                     CASE m.cdirect = 'O'
                        m.nincome = m.nincome - m.noilrev
                        IF m.lDirOilPurch
                           IF m.lSev1O
                              m.ntaxes = m.ntaxes - ABS(m.noiltax1)
                           ENDIF
                           IF m.lSev2O
                              m.ntaxes = m.ntaxes - ABS(m.noiltax2)
                           ENDIF
                           IF m.lSev3O
                              m.ntaxes = m.ntaxes - ABS(m.noiltax3)
                           ENDIF
                           IF m.lSev4O
                              m.ntaxes = m.ntaxes - ABS(m.noiltax4)
                           ENDIF
                        ENDIF
                     CASE m.cdirect = 'G'
                        m.nincome = m.nincome - m.ngasrev
                        IF m.lDirGasPurch
                           IF m.lSev1G
                              m.ntaxes = m.ntaxes - ABS(m.ngastax1)
                           ENDIF
                           IF m.lSev2G
                              m.ntaxes = m.ntaxes - ABS(m.ngastax2)
                           ENDIF
                           IF m.lSev3G
                              m.ntaxes = m.ntaxes - ABS(m.ngastax3)
                           ENDIF
                           IF m.lSev4G
                              m.ntaxes = m.ntaxes - ABS(m.ngastax4)
                           ENDIF
                        ENDIF
                     CASE m.cdirect = 'B'
                        m.nincome = m.nincome - m.ngasrev - m.noilrev
                        IF m.lDirOilPurch
                           IF m.lSev1O
                              m.ntaxes = m.ntaxes - ABS(m.noiltax1)
                           ENDIF
                           IF m.lSev2O
                              m.ntaxes = m.ntaxes - ABS(m.noiltax2)
                           ENDIF
                           IF m.lSev3O
                              m.ntaxes = m.ntaxes - ABS(m.noiltax3)
                           ENDIF
                           IF m.lSev4O
                              m.ntaxes = m.ntaxes - ABS(m.noiltax4)
                           ENDIF
                        ENDIF
                        IF m.lDirGasPurch
                           IF m.lSev1G
                              m.ntaxes = m.ntaxes - ABS(m.ngastax1)
                           ENDIF
                           IF m.lSev2G
                              m.ntaxes = m.ntaxes - ABS(m.ngastax2)
                           ENDIF
                           IF m.lSev3G
                              m.ntaxes = m.ntaxes - ABS(m.ngastax3)
                           ENDIF
                           IF m.lSev4G
                              m.ntaxes = m.ntaxes - ABS(m.ngastax4)
                           ENDIF
                        ENDIF
                  ENDCASE


                  * Determine if the compression/gathering should be added to the expenses
                  * depending on whether the preference to hide comp/gathering has been set.
                  IF llRoyaltyOwner
                     IF NOT llChgPrice
                        m.nexpense = m.ntotale1 + m.ntotale2 + m.ntotale3 + m.ntotale4 + m.ntotale5 + m.ntotale + m.nTotaleA + m.nTotaleB + m.ncompress + m.ngather
                     ELSE
                        m.nexpense = m.ntotale1 + m.ntotale2 + m.ntotale3 + m.ntotale4 + m.ntotale5 + m.ntotale + m.nTotaleA + m.nTotaleB
                     ENDIF
                  ELSE
                     IF NOT llHideComp
                        m.nexpense = m.ntotale1 + m.ntotale2 + m.ntotale3 + m.ntotale4 + m.ntotale5 + m.ntotale + m.nTotaleA + m.nTotaleB + m.ncompress + m.ngather
                     ELSE
                        m.nexpense = m.ntotale1 + m.ntotale2 + m.ntotale3 + m.ntotale4 + m.ntotale5 + m.ntotale + m.nTotaleA + m.nTotaleB
                     ENDIF
                  ENDIF


                  * Flag that tells if expenses still need to be processed
                  llExpProcessed   = .F.

                  * Initial report group. This will be duplicated as report group "BB" if the preference to
                  * print a duplicate stub is enabled.
                  m.crptgroup = 'AA'

                  * Flag to tell whether it finds any MCF entries, so it can adjust the GTax figure accordingly
                  llFound = .F.

                  *******************************************************
                  *  Start of actual stub detail processing
                  *******************************************************
                  **********************************************************************************
                  * Process Gas Revenue
                  **********************************************************************************
                  m.nRevGasSave = m.nrevgas
                  IF NOT INLIST(m.cdirect, 'G', 'B')
                     IF INLIST(m.cProdType, 'G', 'B') AND m.ngasrev # 0
                        SELECT tempinc
                        LOCATE FOR cwellid = m.cwellid ;
                           AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND csource = 'MCF' ;
                           AND nRunNo == m.nRunNo ;
                           AND crunyear == m.crunyear
                        IF FOUND()
                           SCAN FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod ;
                                 AND csource = 'MCF' AND nRunNo == m.nRunNo AND crunyear == m.crunyear

                              * Check to see if this is a one-man item income entry and if so,
                              * and this is not the owner, loop out so it's not processed.
                              IF NOT EMPTY(cownerid)
                                 IF tempinc.cownerid # m.cid
                                    LOOP
                                 ELSE
                                    m.nrevgas = 100
                                 ENDIF
                              ELSE
                                 m.nrevgas = m.nRevGasSave
                              ENDIF

                              * Set the flag to say expenses are being processed for this prod period
                              llExpProcessed   = .T.

                              llFound     = .T.
                              m.cIncType  = 'G'
                              m.ntotalinc = ntotalinc
                              m.crefid    = crefid

                              * Make sure lJIB = .F. if this is a royalty owner
                              IF llRoyaltyOwner
                                 m.ljib = .F.
                              ENDIF

                              * Process gathering
                              IF m.lgather AND m.nWellGath # 0
                                 IF llRoyaltyOwner
                                    * Deduct the gathering from the total gas income so
                                    * when the price is calculated it will hide gathering
                                    IF llChgPrice
                                       m.ntotalinc = m.ntotalinc - m.nWellGath
                                    ENDIF
                                 ELSE
                                    IF llHideComp
                                       m.ntotalinc = m.ntotalinc - m.nWellGath
                                       *                                    m.ngasrev   = m.ngasrev - m.ngather
                                    ENDIF
                                 ENDIF
                              ENDIF

                              * Process compression
                              IF m.lcompress AND m.nWellComp # 0
                                 IF llRoyaltyOwner
                                    * Deduct the compression from the total gas income so
                                    * when the price is calculated it will hide gathering
                                    IF llChgPrice
                                       m.ntotalinc = m.ntotalinc - m.nWellComp
                                    ENDIF
                                 ELSE
                                    IF llHideComp
                                       m.ntotalinc = m.ntotalinc - m.nWellComp
                                       *                                    m.ngasrev   = m.ngasrev - m.ncompress
                                    ENDIF
                                 ENDIF
                              ENDIF

                              * Get the original price per MCF
                              m.nmcfprice  = nrate

                              * Calculate the new price per MCF
                              *  For manual entries, we don't care about the well totals
                              IF NOT m.lmanual
                                 m.nunits     = nunits
                                 IF m.nunits # 0
                                    m.nprice     = (m.ntotalinc / m.nunits)
                                 ELSE
                                    m.nprice = 0
                                 ENDIF

                                 * Taxes were entered or calculated with tax table
                                 IF NOT m.lusesev
                                    m.ntax1  = m.nWellgtax1
                                    m.ntax2  = m.nWellgtax2
                                    m.ntax3  = m.nWellgtax3
                                    m.ntax4  = m.nWellgtax4
                                    m.ntaxes = 0
                                    IF m.ngastax1 # 0
                                       m.ntaxes = m.ntaxes + m.ntax1
                                    ENDIF
                                    IF m.ngastax2 # 0
                                       m.ntaxes = m.ntaxes + m.ntax2
                                    ENDIF
                                    IF m.ngastax3 # 0
                                       m.ntaxes = m.ntaxes + m.ntax3
                                    ENDIF
                                    IF m.ngastax4 # 0
                                       m.ntaxes = m.ntaxes + m.ntax4
                                    ENDIF
                                 ELSE
                                    * Taxes were calculated using rates on well record
                                    IF INLIST(m.cIntType, 'L', 'O', 'R')
                                       m.ntaxes = SWROUND(m.ngrossgas * (m.nroysevg / 100), 2)
                                    ELSE
                                       m.ntaxes = SWROUND(m.ngrossgas * (m.nwrksevg / 100), 2)
                                    ENDIF
                                    m.ntax1  = m.ntaxes
                                    m.ntax2  = m.nWellgtax2
                                    m.ntax3  = m.nWellgtax3
                                    m.ntax4  = m.nWellgtax4
                                    m.ntaxes = 0
                                    IF m.ngastax1 # 0
                                       m.ntaxes = m.ntaxes + m.ntax1
                                    ENDIF
                                    IF m.ngastax2 # 0
                                       m.ntaxes = m.ntaxes + m.ntax2
                                    ENDIF
                                    IF m.ngastax3 # 0
                                       m.ntaxes = m.ntaxes + m.ntax3
                                    ENDIF
                                    IF m.ngastax4 # 0
                                       m.ntaxes = m.ntaxes + m.ntax4
                                    ENDIF
                                 ENDIF


                                 m.ninterest = m.nrevgas
                              ELSE
                                 STORE 0 TO m.nunits, m.nprice, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                                 m.ninterest = 100
                                 m.ntotalinc = m.ngasrev
                                 m.crefid    = ''
                              ENDIF

                              IF llRoyaltyOwner AND llRoySevExempt
                                 STORE 0 TO m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4, m.ntaxes, m.ntax1, m.ntax2, m.ntax3, m.ntax4
                              ENDIF

                              IF NOT m.lExempt
                                 m.nnetval = m.ntotalinc - m.ntaxes
                                 m.nowntax = m.ngastax1 + m.ngastax2 + m.ngastax3 + m.ngastax4

                                 IF NOT llTaxWHProcessed
                                    llTaxWHProcessed = .T.
                                    m.nowntax        = m.nowntax + m.ntaxwith
                                 ENDIF
                              ELSE
                                 m.nnetval = m.ntotalinc
                                 m.nowntax = 0
                              ENDIF

                              IF llRoyaltyOwner
                                 IF llChgPrice
                                    m.nowngross = m.ngasrev - m.nowntax - m.ncompress - m.ngather
                                 ELSE
                                    m.nowngross = m.ngasrev - m.nowntax
                                 ENDIF
                              ELSE
                                 IF llHideComp
                                    m.nowngross = m.ngasrev - m.nowntax - m.ncompress - m.ngather
                                 ELSE
                                    m.nowngross = m.ngasrev - m.nowntax
                                 ENDIF
                              ENDIF

                              IF NOT m.ljib
                                 IF NOT m.lmanual  &&  Don't re-assign m.nnetcheck for manual entries - it's probably converted suspense, and the net is correct, and should be left alone
                                    m.nnetcheck  = m.nowngross - m.nexpense - m.nmktgexp
                                 ENDIF
                                 m.nexpense   = m.nexpense + m.nmktgexp
                              ELSE
                                 IF NOT m.lmanual  &&  Don't re-assign m.nnetcheck for manual entries - it's probably converted suspense, and the net is correct, and should be left alone
                                    m.nnetcheck  = m.nowngross - m.ncompress - m.ngather - m.nmktgexp
                                 ENDIF
                                 m.nexpense   = m.ncompress + m.ngather + m.nmktgexp
                              ENDIF

                              m.cprodprd  = cperiod + '/' + RIGHT(cyear, 2)
                              m.dproddate = tempinc.dRevDate

                              IF NOT tlStubRpt
                                 DO CASE
                                    CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                          glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)
                                       * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                       IF NOT llDupLine
                                          lnLineCount = lnLineCount + 1
                                       ELSE
                                          IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                             lnLineCount = lnLineCount + 2
                                          ELSE
                                             lnLineCount = lnLineCount + 1
                                          ENDIF
                                       ENDIF
                                       lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                       m.cwellname   = ' '
                                       STORE '' TO m.cprodprd, m.cIncType
                                       STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                       STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, m.nowngross, m.ninterest
                                       m.lskip = .T.
                                       IF NOT llDupStub
                                          m.cwellid = ALLT(m.cwellid) + '{'
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                       ENDIF
                                       m.lskip     = .F.
                                       lnLineCount = lnLineCount + 3
                                       m.cwellname = lcOldWellName
                                    CASE lnLineCount <= lnMaxLines
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                       IF NOT llDupLine
                                          lnLineCount = lnLineCount + 1
                                       ELSE
                                          IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                             lnLineCount = lnLineCount + 2
                                          ELSE
                                             lnLineCount = lnLineCount + 1
                                          ENDIF
                                       ENDIF
                                    CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                       m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                       m.cwellid   = '{'
                                       llOverflow  = .T.
                                       m.crptgroup = 'AA'
                                       STORE '' TO m.cprodprd, m.cIncType
                                       STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                       STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, m.nowngross, m.ninterest
                                       SELECT stub
                                       LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                       IF NOT FOUND()
                                          m.ilineno = lnLineCount
                                          INSERT INTO stub FROM MEMVAR
                                       ENDIF
                                       lnLineCount = lnLineCount + 1
                                    CASE lnLineCount > lnMaxLines
                                       lnLineCount = lnLineCount + 1
                                 ENDCASE
                              ELSE
                                 m.ilineno = lnLineCount
                                 IF m.nowngross # 0
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 * STORE 0 TO m.nnetcheck, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                              ENDIF
                           ENDSCAN
                        ELSE
                           **
                           **  Income entry not found in tempinc for gas rev this prod period
                           **
                           IF m.lmanual
                              *  This is a suspense entry from old version (prior conversion)
                              *  We can't fill in everything with this record so we'll fill in
                              *  what we can and plug the interest at 100%
                              m.cIncType  = 'G'

                              m.ntotalinc = ntotalinc
                              m.crefid    = ''
                              STORE 0 TO m.nmcfprice, m.nprice, m.nunits, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                              m.ninterest = 100

                              IF llRoyaltyOwner AND llRoySevExempt
                                 STORE 0 TO m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4, m.ntaxes, m.ntax1, m.ntax2, m.ntax3, m.ntax4
                              ENDIF

                              * Make sure lJIB = .F. if this is a royalty owner
                              IF llRoyaltyOwner
                                 m.ljib = .F.
                              ENDIF

                              IF NOT m.lExempt
                                 m.nnetval = m.ntotalinc - m.ntaxes - m.ncompress - m.ngather
                                 m.nowntax = m.nsevtaxes
                              ELSE
                                 m.nnetval = m.ntotalinc - m.ncompress - m.ngather
                                 m.nowntax = 0
                              ENDIF

                              m.nowngross = m.ngasrev - m.ngastax1 - m.ngastax2 - m.ngastax3 - m.ngastax4

                              IF NOT m.ljib
                                 IF NOT llExpProcessed
                                    llExpProcessed = .T.
                                    m.nnetcheck    = m.nowngross - m.nexpense - m.nmktgexp
                                    m.nexpense     = m.nexpense + m.nmktgexp
                                 ELSE
                                    m.nnetcheck = m.nowngross - m.nmktgexp
                                    m.nexpense  = m.nmktgexp
                                 ENDIF
                              ENDIF
                              IF EMPTY(m.hperiod)
                                 m.cprodprd  = PADL(m.nRunNo_In, 2, '0') + '/' + RIGHT(m.cRunYear_In, 2)
                              ELSE
                                 m.cprodprd  = m.hperiod + '/' + RIGHT(m.hyear, 2)
                              ENDIF
                              m.dproddate = DATE()

                              IF NOT tlStubRpt
                                 DO CASE
                                    CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                          glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                       * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                       IF NOT llDupLine
                                          lnLineCount = lnLineCount + 1
                                       ELSE
                                          IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                             lnLineCount = lnLineCount + 2
                                          ELSE
                                             lnLineCount = lnLineCount + 1
                                          ENDIF
                                       ENDIF
                                       lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                       m.cwellname   = ' '
                                       STORE '' TO m.cprodprd, m.cIncType
                                       STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                       STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                          M.nowngross, m.nexpense, m.ninterest
                                       m.lskip = .T.
                                       IF NOT llDupStub
                                          m.cwellid = ALLT(m.cwellid) + '{'
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                       ENDIF
                                       m.lskip     = .F.
                                       lnLineCount = lnLineCount + 3
                                       m.cwellname = lcOldWellName
                                    CASE lnLineCount <= lnMaxLines
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                       IF NOT llDupLine
                                          lnLineCount = lnLineCount + 1
                                       ELSE
                                          IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                             lnLineCount = lnLineCount + 2
                                          ELSE
                                             lnLineCount = lnLineCount + 1
                                          ENDIF
                                       ENDIF
                                    CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                       m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                       m.cwellid   = '{'
                                       llOverflow  = .T.
                                       m.crptgroup = 'AA'
                                       STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                       STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                          M.nowngross, m.nexpense, m.ninterest
                                       SELECT stub
                                       LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                       IF NOT FOUND()
                                          m.ilineno = lnLineCount
                                          INSERT INTO stub FROM MEMVAR
                                       ENDIF
                                       lnLineCount = lnLineCount + 1
                                    CASE lnLineCount > lnMaxLines
                                       lnLineCount = lnLineCount + 1
                                 ENDCASE
                              ELSE
                                 m.ilineno = lnLineCount
                                 IF m.nowngross # 0
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 * STORE 0 TO m.ngasrev, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                              ENDIF
                           ENDIF

                        ENDIF
                     ENDIF
                  ELSE
                     *
                     *  The owner is direct paid.  Report any taxes that haven't been withheld
                     *
                     m.cIncType = 'G'
                     llInsert   = .F.
                     STORE 0 TO m.nowntax

                     * Make sure lJIB = .F. if this is a royalty owner
                     IF llRoyaltyOwner
                        m.ljib = .F.
                     ENDIF

                     IF NOT m.lusesev
                        IF NOT m.lSev1G
                           m.ntax1   = m.nWellgtax1
                           m.nowntax = m.ngastax1
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        IF NOT m.lSev2G
                           m.ntax2   = m.nWellgtax2
                           m.nowntax = m.nowntax + m.ngastax2
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        IF NOT m.lSev3G
                           m.ntax3   = m.nWellgtax3
                           m.nowntax = m.nowntax + m.ngastax3
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        IF NOT m.lSev4G
                           m.ntax4   = m.nWellgtax4
                           m.nowntax = m.nowntax + m.ngastax4
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        m.ntaxes    = m.ntax1 + m.ntax2 + m.ntax3 + m.ntax4
                     ELSE
                        IF INLIST(m.cIntType, 'L', 'O', 'R')
                           m.ntaxes = SWROUND(m.ngrossgas * (m.nroysevg / 100), 2)
                        ELSE
                           m.ntaxes = SWROUND(m.ngrossgas * (m.nwrksevg / 100), 2)
                        ENDIF
                        m.ntax1   = m.ntaxes
                        m.nowntax = m.ngastax1 + m.ngastax2 + m.ngastax3 + m.ngastax4
                        STORE 0 TO m.ntax2, m.ntax3, m.ntax4
                     ENDIF
                     m.ninterest = m.nrevgas

                     IF llRoyaltyOwner AND llRoySevExempt
                        STORE 0 TO m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4, m.ntaxes, m.ntax1, m.ntax2, m.ntax3, m.ntax4
                     ENDIF

                     IF NOT m.lExempt
                        m.nnetval = 0 - m.ntaxes
                        m.nowntax = m.ngastax1 + m.ngastax2 + m.ngastax3 + m.ngastax4
                     ELSE
                        m.nnetval = 0
                        m.nowntax = 0
                     ENDIF
                     IF llRoyaltyOwner
                        IF llChgPrice
                           m.nowngross = 0 - m.nowntax - m.ncompress - m.ngather
                        ELSE
                           m.nowngross = 0 - m.nowntax
                        ENDIF
                     ELSE
                        IF llHideComp
                           m.nowngross = 0 - m.nowntax - m.ncompress - m.ngather
                        ELSE
                           m.nowngross = 0 - m.nowntax
                        ENDIF
                     ENDIF
                     IF NOT m.ljib
                        m.nnetcheck = m.nowngross - m.nexpense - m.nmktgexp
                        m.nexpense  = m.nexpense + m.nmktgexp
                     ELSE
                        IF NOT m.lmanual
                           m.nnetcheck = m.nowngross - m.ncompress - m.ngather - m.nmktgexp
                           m.nexpense  = m.ncompress + m.ngather + m.nmktgexp
                        ENDIF
                     ENDIF
                     m.cprodprd  = THIS.cperiod + '/' + RIGHT(THIS.cyear, 2)
                     m.dproddate = tempinc.dRevDate
                     STORE 0 TO m.nmcfprice, m.nrate, m.nprice, m.nunits

                     * Something has been found to process above
                     IF llInsert
                        IF NOT tlStubRpt
                           DO CASE
                              CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                    glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                                 lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                 m.cwellname   = ' '
                                 STORE '' TO m.cprodprd, m.cIncType
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest
                                 m.lskip = .T.
                                 IF NOT llDupStub
                                    m.cwellid = ALLT(m.cwellid) + '{'
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                 ENDIF
                                 m.lskip     = .F.
                                 lnLineCount = lnLineCount + 3
                                 m.cwellname = lcOldWellName
                              CASE lnLineCount <= lnMaxLines
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                              CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                 m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 m.cwellid   = '{'
                                 llOverflow  = .T.
                                 m.crptgroup = 'AA'
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest
                                 SELECT stub
                                 LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 IF NOT FOUND()
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 lnLineCount = lnLineCount + 1
                              CASE lnLineCount > lnMaxLines
                                 lnLineCount = lnLineCount + 1
                           ENDCASE
                        ELSE
                           m.ilineno = lnLineCount
                           IF m.nowngross # 0
                              INSERT INTO stub FROM MEMVAR
                           ENDIF
                           *                           STORE 0 TO m.ngasrev, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                        ENDIF
                     ENDIF
                  ENDIF

                  IF NOT llFound
                     m.nnetcheck = 0
                  ENDIF

                  * Process entered gas taxes or marketing charges where there is not gas revenue during the same production period
                  * This could be used for tax adjustments

                  IF m.ngasrev = 0 AND (NOT m.lDirGasPurch OR NOT INLIST(m.cdirect, 'G', 'B') AND INLIST(m.cProdType, 'G', 'B'))
                     SELECT tempinc
                     LOCATE FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND LEFT(csource, 4) = 'GTAX' ;
                        AND nRunNo == m.nRunNo AND crunyear == m.crunyear
                     IF m.nmktgexp # 0 OR FOUND()
                        IF llRoyaltyOwner AND llRoySevExempt
                           LOOP
                        ENDIF
                        IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                           LOOP
                        ENDIF

                        IF llExpProcessed
                           m.nexpense = 0
                        ELSE
                           llExpProcessed = .T.
                           *  If this is a one-person item, but it's not for this owner, don't reset the flag
                           IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                              llExpProcessed = .F.
                           ENDIF
                        ENDIF

                        IF llTaxWHProcessed
                           m.ntaxwith = 0
                        ELSE
                           llTaxWHProcessed = .T.
                        ENDIF

                        m.cIncType  = 'M'
                        m.nmcfprice = 0
                        m.nprice    = 0
                        m.nunits    = 0
                        m.ntotalinc = 0
                        m.ntax1     = ntotalinc * -1
                        m.ntax2     = 0
                        m.ntax3     = 0
                        m.ntax4     = 0
                        m.ntaxes    = m.ntax1

                        m.ninterest = m.nrevgas
                        m.cprodprd  = cperiod + '/' + RIGHT(cyear, 2)
                        m.dproddate = tempinc.dRevDate
                        IF NOT m.lExempt
                           m.nnetval   = m.ntaxes
                           m.nowntax   = m.ngastax1 + m.ngastax2 + m.ngastax3 + m.ngastax4
                           m.nowngross = m.nowntax * -1 + m.nmktgexp * -1 - m.nexpense
                           IF m.nnetcheck = 0
                              m.nnetcheck = m.nowngross - m.nexpense
                           ENDIF
                        ELSE
                           m.nnetval   = m.ntotalinc
                           m.nowngross = m.nmktgexp * -1
                           IF m.nnetcheck = 0
                              m.nnetcheck = m.nowngross - m.nexpense
                           ENDIF
                        ENDIF
                        IF NOT tlStubRpt
                           DO CASE
                              CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                    glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                                 lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                 m.cwellname   = ' '
                                 STORE '' TO m.cprodprd, m.cIncType
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 m.lskip = .T.
                                 IF NOT llDupStub
                                    m.cwellid = ALLT(m.cwellid) + '{'
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                 ENDIF
                                 m.lskip     = .F.
                                 lnLineCount = lnLineCount + 3
                                 m.cwellname = lcOldWellName
                              CASE lnLineCount <= lnMaxLines
                                 SELE stub
                                 LOCATE FOR cid = m.cid AND cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND cIncType = 'G'
                                 IF FOUND()
                                    IF NOT m.lExempt
                                       REPL ntaxes  WITH ntaxes + m.ntaxes, ;
                                          nnetval WITH nnetval + m.ntaxes, ;
                                          nnetcheck WITH nnetcheck + m.nnetcheck
                                    ENDIF
                                 ELSE
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                    FLUSH
                                    IF NOT llDupLine
                                       lnLineCount = lnLineCount + 1
                                    ELSE
                                       IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                          lnLineCount = lnLineCount + 2
                                       ELSE
                                          lnLineCount = lnLineCount + 1
                                       ENDIF
                                    ENDIF
                                 ENDIF
                              CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                 m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 m.cwellid   = '{'
                                 llOverflow  = .T.
                                 m.crptgroup = 'AA'
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 SELECT stub
                                 LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 IF NOT FOUND()
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 lnLineCount = lnLineCount + 1
                           ENDCASE
                        ELSE
                           m.ilineno = lnLineCount
                           IF m.nowngross # 0
                              INSERT INTO stub FROM MEMVAR
                           ENDIF
                           *                           STORE 0 TO m.ngasrev, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                        ENDIF
                     ENDIF
                  ENDIF

                  llFound = .F.  &&  Flag to tell whether it finds any BBL entries, so it can adjust the OTax figure accordingly

                  **********************************************************************************
                  * Process Oil Revenue
                  **********************************************************************************
                  m.nRevOilSave = m.nrevoil
                  IF NOT INLIST(m.cdirect, 'O', 'B')
                     IF INLIST(m.cProdType, 'O', 'B') AND m.noilrev # 0
                        SELECT tempinc
                        LOCATE FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod ;
                           AND csource = 'BBL' AND nRunNo == m.nRunNo AND crunyear == m.crunyear
                        IF FOUND()
                           SCAN FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND csource = 'BBL' AND nRunNo == m.nRunNo AND crunyear == m.crunyear

                              IF llExpProcessed
                                 m.nexpense = 0
                                 m.nmktgexp = 0
                              ELSE
                                 llExpProcessed = .T.
                                 *  If this is a one-person item, but it's not for this owner, don't reset the flag
                                 IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                                    llExpProcessed = .F.
                                 ENDIF
                              ENDIF

                              IF llTaxWHProcessed
                                 m.ntaxwith = 0
                              ELSE
                                 llTaxWHProcessed = .T.
                              ENDIF

                              IF NOT EMPTY(cownerid)
                                 IF tempinc.cownerid # m.cid
                                    m.nrevoil = m.nRevOilSave
                                    LOOP
                                 ELSE
                                    m.nrevoil = 100
                                 ENDIF
                              ELSE
                                 m.nrevoil = m.nRevOilSave
                              ENDIF
                              llFound     = .T.
                              m.cIncType  = 'O'
                              m.nbblprice = nrate
                              IF nunits # 0
                                 m.nprice     = (ntotalinc / nunits)
                              ELSE
                                 m.nprice = 0
                              ENDIF

                              * Make sure lJIB = .F. if this is a royalty owner
                              IF llRoyaltyOwner
                                 m.ljib = .F.
                              ENDIF

                              m.nunits    = nunits
                              m.ntotalinc = ntotalinc
                              IF NOT m.lusesev
                                 m.ntax1  = m.nWellotax1
                                 m.ntax2  = m.nWellotax2
                                 m.ntax3  = m.nWellotax3
                                 m.ntax4  = m.nWellotax4
                                 m.ntaxes = 0
                                 IF m.noiltax1 # 0
                                    m.ntaxes = m.ntaxes + m.ntax1
                                 ENDIF
                                 IF m.noiltax2 # 0
                                    m.ntaxes = m.ntaxes + m.ntax2
                                 ENDIF
                                 IF m.noiltax3 # 0
                                    m.ntaxes = m.ntaxes + m.ntax3
                                 ENDIF
                                 IF m.noiltax4 # 0
                                    m.ntaxes = m.ntaxes + m.ntax4
                                 ENDIF
                              ELSE
                                 IF INLIST(m.cIntType, 'L', 'O', 'R')
                                    m.ntaxes = SWROUND(m.ngrossoil * (m.nroysevo / 100), 2)
                                 ELSE
                                    m.ntaxes = SWROUND(m.ngrossoil * (m.nwrksevo / 100), 2)
                                 ENDIF
                                 m.ntax1  = m.ntaxes
                                 m.ntax2  = m.nWellotax2
                                 m.ntax3  = m.nWellotax3
                                 m.ntax4  = m.nWellotax4
                                 m.ntaxes = 0
                                 IF m.noiltax1 # 0
                                    m.ntaxes = m.ntaxes + m.ntax1
                                 ENDIF
                                 IF m.noiltax2 # 0
                                    m.ntaxes = m.ntaxes + m.ntax2
                                 ENDIF
                                 IF m.noiltax3 # 0
                                    m.ntaxes = m.ntaxes + m.ntax3
                                 ENDIF
                                 IF m.noiltax4 # 0
                                    m.ntaxes = m.ntaxes + m.ntax4
                                 ENDIF
                              ENDIF
                              m.ninterest = m.nrevoil
                              m.crefid    = crefid
                              STORE 0 TO m.nWellGath, m.nWellComp

                              IF llRoyaltyOwner AND llRoySevExempt
                                 STORE 0 TO m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4, m.ntaxes, m.ntax1, m.ntax2, m.ntax3, m.ntax4
                              ENDIF

                              IF NOT m.lExempt
                                 m.nnetval = m.ntotalinc - m.ntaxes
                                 m.nowntax = m.noiltax1 + m.noiltax2 + m.noiltax3 + m.noiltax4

                                 IF NOT llTaxWHProcessed
                                    llTaxWHProcessed = .T.
                                    m.nowntax        = m.nowntax + m.ntaxwith
                                 ENDIF

                                 m.nowngross = m.noilrev - m.nowntax
                              ELSE
                                 m.nnetval   = m.ntotalinc
                                 m.nowngross = m.noilrev
                              ENDIF
                              IF NOT m.ljib
                                 m.nnetcheck = m.nowngross - m.nexpense - m.nmktgexp
                                 m.nexpense  = m.nexpense + m.nmktgexp
                              ELSE
                                 IF NOT m.lmanual
                                    m.nnetcheck  = m.nowngross
                                 ENDIF
                              ENDIF
                              m.cprodprd  = cperiod + '/' + RIGHT(cyear, 2)
                              m.dproddate = tempinc.dRevDate
                              SELECT disbchks
                              IF NOT tlStubRpt
                                 DO CASE
                                    CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                          glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                       * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                       IF NOT llDupLine
                                          lnLineCount = lnLineCount + 1
                                       ELSE
                                          IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                             lnLineCount = lnLineCount + 2
                                          ELSE
                                             lnLineCount = lnLineCount + 1
                                          ENDIF
                                       ENDIF
                                       lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                       m.cwellname   = ' '
                                       STORE '' TO m.cprodprd, m.cIncType
                                       STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                       STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                          M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                       m.lskip = .T.
                                       IF NOT llDupStub
                                          m.cwellid = ALLT(m.cwellid) + '{'
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                       ENDIF
                                       m.lskip     = .F.
                                       lnLineCount = lnLineCount + 3
                                       m.cwellname = lcOldWellName
                                    CASE lnLineCount <= lnMaxLines
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                       IF NOT llDupLine
                                          lnLineCount = lnLineCount + 1
                                       ELSE
                                          IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                             lnLineCount = lnLineCount + 2
                                          ELSE
                                             lnLineCount = lnLineCount + 1
                                          ENDIF
                                       ENDIF
                                    CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                       m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                       m.cwellid   = '{'
                                       llOverflow  = .T.
                                       m.crptgroup = 'AA'
                                       STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                       STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                          M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                       SELECT stub
                                       LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                       IF NOT FOUND()
                                          m.ilineno = lnLineCount
                                          INSERT INTO stub FROM MEMVAR
                                       ENDIF
                                       lnLineCount = lnLineCount + 1
                                 ENDCASE
                              ELSE
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 *                                 STORE 0 TO m.noilrev, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                              ENDIF
                           ENDSCAN
                        ELSE
                           IF m.lmanual

                              *  This is a suspense entry from old version (prior conversion)
                              *  We can't fill in everything with this record so we'll fill in
                              *  what we can and plug the interest at 100%
                              m.cIncType  = 'O'
                              m.ntotalinc = ntotalinc
                              m.crefid    = ''
                              STORE 0 TO m.nmcfprice, m.nprice, m.nunits, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                              m.ninterest = 100

                              IF llRoyaltyOwner AND llRoySevExempt
                                 STORE 0 TO m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4, m.ntaxes, m.ntax1, m.ntax2, m.ntax3, m.ntax4
                              ENDIF


                              * Make sure lJIB = .F. if this is a royalty owner
                              IF llRoyaltyOwner
                                 m.ljib = .F.
                              ENDIF

                              IF NOT m.lExempt
                                 m.nnetval = m.ntotalinc - m.ntaxes - m.ncompress - m.ngather
                                 m.nowntax = m.nsevtaxes
                              ELSE
                                 m.nnetval = m.ntotalinc - m.ncompress - m.ngather
                                 m.nowntax = 0
                              ENDIF

                              m.nowngross = m.noilrev - m.noiltax1 - m.noiltax2 - m.noiltax3 - m.noiltax3

                              IF NOT m.ljib
                                 IF NOT llExpProcessed
                                    llExpProcessed = .T.
                                    m.nnetcheck    = m.nowngross - m.nexpense - m.nmktgexp
                                    m.nexpense     = m.nexpense + m.nmktgexp
                                 ELSE
                                    m.nnetcheck = m.nowngross - m.nmktgexp
                                    m.nexpense  = m.nmktgexp
                                 ENDIF
                              ENDIF
                              IF EMPTY(m.hperiod)
                                 m.cprodprd  = PADL(m.nRunNo_In, 2, '0') + '/' + RIGHT(m.cRunYear_In, 2)
                              ELSE
                                 m.cprodprd  = m.hperiod + '/' + RIGHT(m.hyear, 2)
                              ENDIF
                              m.dproddate = DATE()

                              IF NOT tlStubRpt
                                 DO CASE
                                    CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                          glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                       * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                       IF NOT llDupLine
                                          lnLineCount = lnLineCount + 1
                                       ELSE
                                          IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                             lnLineCount = lnLineCount + 2
                                          ELSE
                                             lnLineCount = lnLineCount + 1
                                          ENDIF
                                       ENDIF
                                       lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                       m.cwellname   = ' '
                                       STORE '' TO m.cprodprd, m.cIncType
                                       STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                       STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                          M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                       m.lskip = .T.
                                       IF NOT llDupStub
                                          m.cwellid = ALLT(m.cwellid) + '{'
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.ilineno = lnLineCount + 1
                                          INSERT INTO stub FROM MEMVAR
                                          m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                       ENDIF
                                       m.lskip     = .F.
                                       lnLineCount = lnLineCount + 3
                                       m.cwellname = lcOldWellName
                                    CASE lnLineCount <= lnMaxLines
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                       IF NOT llDupLine
                                          lnLineCount = lnLineCount + 1
                                       ELSE
                                          IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                             lnLineCount = lnLineCount + 2
                                          ELSE
                                             lnLineCount = lnLineCount + 1
                                          ENDIF
                                       ENDIF
                                    CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                       m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                       m.cwellid   = '{'
                                       llOverflow  = .T.
                                       m.crptgroup = 'AA'
                                       STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                       STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                          M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                       SELECT stub
                                       LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                       IF NOT FOUND()
                                          m.ilineno = lnLineCount
                                          INSERT INTO stub FROM MEMVAR
                                       ENDIF
                                       lnLineCount = lnLineCount + 1
                                    CASE lnLineCount > lnMaxLines
                                       lnLineCount = lnLineCount + 1
                                 ENDCASE
                              ELSE
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                              ENDIF
                           ENDIF
                        ENDIF
                     ENDIF
                  ELSE
                     *
                     * Report on any taxes that weren't direct paid
                     *

                     llInsert   = .F.
                     m.cIncType = 'O'
                     STORE 0 TO m.nowntax
                     IF NOT m.lusesev
                        IF NOT m.lSev1O AND m.noiltax1 # 0 AND m.lDirOilPurch
                           m.ntax1   = m.nWellotax1
                           m.nowntax = m.noiltax1
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        IF NOT m.lSev2O AND m.noiltax2 # 0 AND m.lDirOilPurch
                           m.ntax2   = m.nWellotax2
                           m.nowntax = m.nowntax + m.noiltax2
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        IF NOT m.lSev3O AND m.noiltax3 # 0 AND m.lDirOilPurch
                           m.ntax3   = m.nWellotax3
                           m.nowntax = m.nowntax + m.noiltax3
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        IF NOT m.lSev4O AND m.noiltax4 # 0 AND m.lDirOilPurch
                           m.ntax4   = m.nWellotax4
                           m.nowntax = m.nowntax + m.noiltax4
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        m.ntaxes = 0
                        IF m.noiltax1 # 0
                           m.ntaxes = m.ntaxes + m.ntax1
                        ENDIF
                        IF m.noiltax2 # 0
                           m.ntaxes = m.ntaxes + m.ntax2
                        ENDIF
                        IF m.noiltax3 # 0
                           m.ntaxes = m.ntaxes + m.ntax3
                        ENDIF
                        IF m.noiltax4 # 0
                           m.ntaxes = m.ntaxes + m.ntax4
                        ENDIF
                     ELSE
                        IF INLIST(m.cIntType, 'L', 'O', 'R')
                           m.ntaxes = SWROUND(m.ngrossoil * (m.nroysevo / 100), 2)
                        ELSE
                           m.ntaxes = SWROUND(m.ngrossoil * (m.nwrksevo / 100), 2)
                        ENDIF
                        m.ntax1 = m.ntaxes
                        IF NOT m.lSev2O AND m.noiltax2 # 0 AND m.lDirOilPurch
                           m.ntax2   = m.nWellotax2
                           m.nowntax = m.nowntax + m.noiltax2
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        IF NOT m.lSev3O AND m.noiltax3 # 0 AND m.lDirOilPurch
                           m.ntax3   = m.nWellotax3
                           m.nowntax = m.nowntax + m.noiltax3
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        IF NOT m.lSev4O AND m.noiltax4 # 0 AND m.lDirOilPurch
                           m.ntax4   = m.nWellotax4
                           m.nowntax = m.nowntax + m.noiltax4
                           IF m.nowntax # 0
                              llInsert     = .T.
                           ENDIF
                        ENDIF
                        m.ntaxes = 0
                        IF m.noiltax1 # 0
                           m.ntaxes = m.ntaxes + m.ntax1
                        ENDIF
                        IF m.noiltax2 # 0
                           m.ntaxes = m.ntaxes + m.ntax2
                        ENDIF
                        IF m.noiltax3 # 0
                           m.ntaxes = m.ntaxes + m.ntax3
                        ENDIF
                        IF m.noiltax4 # 0
                           m.ntaxes = m.ntaxes + m.ntax4
                        ENDIF
                     ENDIF
                     m.ninterest = m.nrevoil

                     IF llRoyaltyOwner AND llRoySevExempt
                        STORE 0 TO m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4, m.ntaxes, m.ntax1, m.ntax2, m.ntax3, m.ntax4
                     ENDIF

                     IF NOT m.lExempt
                        m.nnetval = 0 - m.ntaxes
                        m.nowntax = m.noiltax1 + m.noiltax2 + m.noiltax3 + m.noiltax4
                     ELSE
                        m.nnetval = 0
                        m.nowntax = 0
                     ENDIF
                     m.nowngross = 0 - m.nowntax
                     IF NOT m.ljib
                        m.nnetcheck = m.nowngross - m.nexpense + m.nmktgexp
                        m.nexpense  = m.nexpense + m.nmktgexp
                     ELSE
                        IF NOT m.lmanual
                           m.nnetcheck = m.nowngross
                           m.nexpense  = 0
                        ENDIF
                     ENDIF
                     m.cprodprd  = THIS.cperiod + '/' + RIGHT(THIS.cyear, 2)
                     m.dproddate = tempinc.dRevDate
                     STORE 0 TO m.nbblprice, m.nrate, m.nprice, m.nunits
                     IF llInsert
                        IF NOT tlStubRpt
                           DO CASE
                              CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                    glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                                 lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                 m.cwellname   = ' '
                                 STORE '' TO m.cprodprd, m.cIncType
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 m.lskip = .T.
                                 IF NOT llDupStub
                                    m.cwellid = ALLT(m.cwellid) + '{'
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                 ENDIF
                                 m.lskip     = .F.
                                 lnLineCount = lnLineCount + 3
                                 m.cwellname = lcOldWellName
                              CASE lnLineCount <= lnMaxLines
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                              CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                 m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 m.cwellid   = '{'
                                 llOverflow  = .T.
                                 m.crptgroup = 'AA'
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 SELECT stub
                                 LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 IF NOT FOUND()
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 lnLineCount = lnLineCount + 1
                           ENDCASE
                        ELSE
                           m.ilineno = lnLineCount
                           IF m.nowngross # 0
                              INSERT INTO stub FROM MEMVAR
                           ENDIF
                           *                           STORE 0 TO m.noilrev, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                        ENDIF
                     ENDIF
                  ENDIF

                  IF NOT llFound
                     m.nnetcheck = 0
                  ENDIF

                  * Process entered taxes when there's no oil revenue during the same production period
                  * This is most usually a tax adjustment.

                  IF m.noilrev = 0 AND (NOT m.lDirOilPurch OR (NOT INLIST(m.cdirect, 'O', 'B') AND INLIST(m.cProdType, 'O', 'B')))
                     SELECT tempinc
                     LOCATE FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND LEFT(csource, 4) = 'OTAX' AND nRunNo == m.nRunNo AND crunyear == m.crunyear
                     IF FOUND() OR ((m.noiltax1 + m.noiltax2 + m.noiltax3 + m.noiltax4) # 0 AND m.lmanual)
                        IF llRoyaltyOwner AND llRoySevExempt
                           LOOP
                        ENDIF
                        IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                           LOOP
                        ENDIF

                        IF llExpProcessed
                           m.nexpense = 0
                        ELSE
                           llExpProcessed = .T.
                           *  If this is a one-person item, but it's not for this owner, don't reset the flag
                           IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                              llExpProcessed = .F.
                           ENDIF
                        ENDIF

                        IF llTaxWHProcessed
                           m.ntaxwith = 0
                        ELSE
                           llTaxWHProcessed = .T.
                        ENDIF

                        m.cIncType  = 'O'
                        m.nmcfprice = 0
                        m.nprice    = 0
                        m.nunits    = 0
                        m.ntotalinc = 0
                        m.ntax1     = ntotalinc * -1
                        m.ntax2     = 0
                        m.ntax3     = 0
                        m.ntax4     = 0
                        m.ntaxes    = m.ntax1
                        m.ninterest = m.nrevoil
                        m.cprodprd  = cperiod + '/' + RIGHT(cyear, 2)
                        m.dproddate = tempinc.dRevDate
                        m.crefid    = crefid
                        IF NOT m.lExempt
                           m.nnetval   = ntotalinc * -1
                           m.nowntax   = m.noiltax1 + m.noiltax2 + m.noiltax3 + m.noiltax4
                           m.nowngross = m.nowntax * -1 + m.nmktgexp * -1
                           m.nowngross = m.nowngross - m.nexpense
                           IF m.nnetcheck = 0
                              m.nnetcheck = m.nowngross - m.nmktgexp
                           ENDIF
                        ELSE
                           m.nnetval   = m.ntotalinc
                           m.nowngross = m.noilrev
                        ENDIF
                        IF NOT tlStubRpt
                           DO CASE
                              CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                    glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                                 lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                 m.cwellname   = ' '
                                 STORE '' TO m.cprodprd, m.cIncType
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 m.lskip = .T.
                                 IF NOT llDupStub
                                    m.cwellid = ALLT(m.cwellid) + '{'
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                 ENDIF
                                 m.lskip     = .F.
                                 lnLineCount = lnLineCount + 3
                                 m.cwellname = lcOldWellName
                              CASE lnLineCount <= lnMaxLines
                                 SELE stub
                                 LOCATE FOR cid = m.cid AND cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND cIncType = 'O'
                                 IF FOUND()
                                    IF NOT m.lExempt
                                       REPL ntaxes WITH ntaxes + m.ntaxes, ;
                                          nnetval WITH nnetval + m.ntaxes, ;
                                          nnetcheck WITH nnetcheck + m.nnetcheck
                                    ENDIF
                                 ELSE
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                    FLUSH
                                    IF NOT llDupLine
                                       lnLineCount = lnLineCount + 1
                                    ELSE
                                       IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                          lnLineCount = lnLineCount + 2
                                       ELSE
                                          lnLineCount = lnLineCount + 1
                                       ENDIF
                                    ENDIF
                                 ENDIF
                              CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                 m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 m.cwellid   = '{'
                                 llOverflow  = .T.
                                 m.crptgroup = 'AA'
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 SELECT stub
                                 LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 IF NOT FOUND()
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 lnLineCount = lnLineCount + 1
                           ENDCASE
                        ELSE
                           m.ilineno = lnLineCount
                           IF m.nowngross # 0
                              INSERT INTO stub FROM MEMVAR
                           ENDIF
                           * STORE 0 TO m.noilrev, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                        ENDIF
                     ENDIF
                  ENDIF

                  llFound = .F.  &&  Flag to tell whether it finds any BBL entries, so it can adjust the OTax figure accordingly


                  **********************************************************************************
                  * Process Other Revenue
                  **********************************************************************************
                  m.nRevOthSave = m.nrevoth
                  IF m.nothrev # 0
                     SELECT tempinc
                     SCAN FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND csource = 'OTH' AND nRunNo == m.nRunNo AND crunyear == m.crunyear

                        IF llExpProcessed
                           m.nexpense = 0
                        ELSE
                           llExpProcessed = .T.
                           *  If this is a one-person item, but it's not for this owner, don't reset the flag
                           IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                              llExpProcessed = .F.
                           ENDIF
                        ENDIF

                        IF llTaxWHProcessed
                           m.ntaxwith = 0
                        ELSE
                           llTaxWHProcessed = .T.
                        ENDIF

                        IF NOT EMPTY(cownerid)
                           IF tempinc.cownerid # m.cid
                              m.nrevoth = m.nRevOthSave
                              LOOP
                           ELSE
                              m.nrevoth = 100
                           ENDIF
                        ELSE
                           m.nrevoth = m.nRevOthSave
                        ENDIF
                        llFound     = .T.
                        m.cIncType  = 'P'
                        m.nbblprice = nrate
                        IF nunits # 0
                           m.nprice     = (ntotalinc / nunits)
                        ELSE
                           m.nprice = 0
                        ENDIF
                        m.nunits    = nunits
                        m.ntotalinc = ntotalinc
                        m.ntax1     = m.nWellptax1
                        m.ntax2     = m.nWellptax2
                        m.ntax3     = m.nWellptax3
                        m.ntax4     = m.nWellptax4
                        m.ntaxes    = 0
                        IF m.nothtax1 # 0
                           m.ntaxes = m.ntaxes + m.ntax1
                        ENDIF
                        IF m.nothtax2 # 0
                           m.ntaxes = m.ntaxes + m.ntax2
                        ENDIF
                        IF m.nothtax3 # 0
                           m.ntaxes = m.ntaxes + m.ntax3
                        ENDIF
                        IF m.nothtax4 # 0
                           m.ntaxes = m.ntaxes + m.ntax4
                        ENDIF
                        m.ninterest = m.nrevoth
                        m.crefid    = crefid
                        STORE 0 TO m.nWellGath, m.nWellComp

                        * Make sure lJIB = .F. if this is a royalty owner
                        IF llRoyaltyOwner
                           m.ljib = .F.
                        ENDIF

                        IF llRoyaltyOwner AND llRoySevExempt
                           STORE 0 TO m.nothtax1, m.nothtax2, m.nothtax3, m.nothtax4, m.ntaxes, m.ntax1, m.ntax2, m.ntax3, m.ntax4
                        ENDIF

                        IF NOT m.lExempt
                           m.nnetval   = m.ntotalinc - m.ntaxes
                           m.nowntax   = m.nothtax1 + m.nothtax2 + m.nothtax3 + m.nothtax4
                           m.nowngross = m.nothrev - m.nowntax
                        ELSE
                           m.nnetval   = m.ntotalinc
                           m.nowngross = m.nothrev
                        ENDIF
                        IF NOT m.ljib
                           m.nnetcheck  = m.nowngross - m.nexpense
                        ELSE
                           IF NOT m.lmanual
                              m.nnetcheck  = m.nowngross
                           ENDIF
                        ENDIF
                        m.cprodprd  = cperiod + '/' + RIGHT(cyear, 2)
                        m.dproddate = tempinc.dRevDate
                        SELECT disbchks
                        IF NOT tlStubRpt
                           DO CASE
                              CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                    glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                                 lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                 m.cwellname   = ' '
                                 STORE '' TO m.cprodprd, m.cIncType
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 m.lskip = .T.
                                 IF NOT llDupStub
                                    m.cwellid = ALLT(m.cwellid) + '{'
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                 ENDIF
                                 m.lskip     = .F.
                                 lnLineCount = lnLineCount + 3
                                 m.cwellname = lcOldWellName
                              CASE lnLineCount <= lnMaxLines
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                              CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                 m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 m.cwellid   = '{'
                                 llOverflow  = .T.
                                 m.crptgroup = 'AA'
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 SELECT stub
                                 LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 IF NOT FOUND()
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 lnLineCount = lnLineCount + 1
                           ENDCASE
                        ELSE
                           m.ilineno = lnLineCount
                           IF m.nowngross # 0
                              INSERT INTO stub FROM MEMVAR
                           ENDIF
                           * STORE 0 TO m.nothrev, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                        ENDIF
                     ENDSCAN
                  ENDIF

                  IF NOT llFound
                     m.nnetcheck = 0
                  ENDIF
                  * Process other taxes when there is no other revenue during the same production period
                  * This is probably a tax adjustment
                  IF m.nothrev = 0
                     SELECT tempinc
                     SCAN FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND LEFT(csource, 4) = 'PTAX' ;
                           AND nRunNo == m.nRunNo AND crunyear == m.crunyear
                        IF llRoyaltyOwner AND llRoySevExempt
                           LOOP
                        ENDIF
                        IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                           LOOP
                        ENDIF

                        IF llExpProcessed
                           m.nexpense = 0
                        ELSE
                           llExpProcessed = .T.
                           *  If this is a one-person item, but it's not for this owner, don't reset the flag
                           IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                              llExpProcessed = .F.
                           ENDIF
                        ENDIF

                        IF llTaxWHProcessed
                           m.ntaxwith = 0
                        ELSE
                           llTaxWHProcessed = .T.
                        ENDIF

                        m.cIncType  = 'P'
                        m.nmcfprice = 0
                        m.nprice    = 0
                        m.nunits    = 0
                        m.ntotalinc = 0
                        m.ntax1     = ntotalinc * -1
                        m.ntax2     = 0
                        m.ntax3     = 0
                        m.ntax4     = 0
                        m.ntaxes    = m.ntax1
                        m.ninterest = m.nrevoth
                        m.cprodprd  = cperiod + '/' + RIGHT(cyear, 2)
                        m.dproddate = tempinc.dRevDate
                        m.crefid    = crefid
                        IF NOT m.lExempt
                           m.nnetval   = m.ntaxes
                           m.nowntax   = m.nothtax1 + m.nothtax2 + m.nothtax3 + m.nothtax4
                           m.nowngross = m.nowntax * -1
                           IF m.nnetcheck = 0
                              m.nnetcheck = m.nowngross
                           ENDIF
                        ELSE
                           m.nnetval   = m.ntotalinc
                           m.nowngross = m.nothrev
                        ENDIF
                        IF m.nowntax # 0
                           IF NOT tlStubRpt
                              DO CASE
                                 CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                       glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                    * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                    IF NOT llDupLine
                                       lnLineCount = lnLineCount + 1
                                    ELSE
                                       IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                          lnLineCount = lnLineCount + 2
                                       ELSE
                                          lnLineCount = lnLineCount + 1
                                       ENDIF
                                    ENDIF
                                    lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                    m.cwellname   = ' '
                                    STORE '' TO m.cprodprd, m.cIncType
                                    STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                    STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                       M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                    m.lskip = .T.
                                    IF NOT llDupStub
                                       m.cwellid = ALLT(m.cwellid) + '{'
                                       m.ilineno = lnLineCount + 1
                                       INSERT INTO stub FROM MEMVAR
                                       m.ilineno = lnLineCount + 1
                                       INSERT INTO stub FROM MEMVAR
                                       m.ilineno = lnLineCount + 1
                                       INSERT INTO stub FROM MEMVAR
                                       m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                    ENDIF
                                    m.lskip     = .F.
                                    lnLineCount = lnLineCount + 3
                                    m.cwellname = lcOldWellName
                                 CASE lnLineCount <= lnMaxLines
                                    SELE stub
                                    LOCATE FOR cid = m.cid AND cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND cIncType = 'P'
                                    IF FOUND()
                                       IF NOT m.lExempt
                                          REPL ntaxes  WITH ntaxes + m.ntaxes, ;
                                             nnetval WITH nnetval + m.ntaxes, ;
                                             nnetcheck WITH nnetcheck + m.nnetcheck
                                       ENDIF
                                    ELSE
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                       FLUSH
                                       IF NOT llDupLine
                                          lnLineCount = lnLineCount + 1
                                       ELSE
                                          IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                             lnLineCount = lnLineCount + 2
                                          ELSE
                                             lnLineCount = lnLineCount + 1
                                          ENDIF
                                       ENDIF
                                    ENDIF
                                 CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                    m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                    m.cwellid   = '{'
                                    llOverflow  = .T.
                                    m.crptgroup = 'AA'
                                    STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                    STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                       M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                    SELECT stub
                                    LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                    IF NOT FOUND()
                                       m.ilineno = lnLineCount
                                       INSERT INTO stub FROM MEMVAR
                                    ENDIF
                                    lnLineCount = lnLineCount + 1
                              ENDCASE
                           ELSE
                              m.ilineno = lnLineCount
                              IF m.nowngross # 0
                                 INSERT INTO stub FROM MEMVAR
                              ENDIF
                              * STORE 0 TO m.nothrev, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                           ENDIF
                        ENDIF
                     ENDSCAN
                  ENDIF


                  **********************************************************************************
                  * Process Transportation Revenue
                  **********************************************************************************
                  m.nRevTrpSave = m.nrevtrp
                  IF m.nrevtrp # 0
                     SELECT tempinc
                     SCAN FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND csource = 'TRANS' AND nRunNo == m.nRunNo AND crunyear == m.crunyear
                        IF NOT EMPTY(cownerid)
                           IF tempinc.cownerid # m.cid
                              m.nrevtrp = m.nRevTrpSave
                              LOOP
                           ELSE
                              m.nrevtrp = 100
                           ENDIF
                        ELSE
                           m.nrevtrp = m.nRevTrpSave
                        ENDIF
                        m.nexpense  = 0
                        m.cIncType  = 'T'
                        m.nbblprice = nrate
                        m.nprice    = nrate
                        m.nunits    = nunits
                        m.ntotalinc = ntotalinc
                        STORE 0 TO m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes, m.nowntax, m.ntaxwith
                        m.nnetval   = m.ntotalinc
                        m.ninterest = m.nrevtrp
                        m.nowngross = m.ntrprev
                        m.nnetcheck = m.nowngross
                        m.cprodprd  = cperiod + '/' + RIGHT(cyear, 2)
                        m.dproddate = tempinc.dRevDate
                        SELECT disbchks
                        IF NOT tlStubRpt
                           DO CASE
                              CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                    glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                                 lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                 m.cwellname   = ' '
                                 STORE '' TO m.cprodprd, m.cIncType
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 m.lskip = .T.
                                 IF NOT llDupStub
                                    m.cwellid = ALLT(m.cwellid) + '{'
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                 ENDIF
                                 m.lskip     = .F.
                                 lnLineCount = lnLineCount + 3
                                 m.cwellname = lcOldWellName
                              CASE lnLineCount <= lnMaxLines
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                              CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                 m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 m.cwellid   = '{'
                                 llOverflow  = .T.
                                 m.crptgroup = 'AA'
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf, m.ngasrev, m.noilrev
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith, m.nmiscrev1, m.nmiscrev2, m.nothrev
                                 SELECT stub
                                 LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 IF NOT FOUND()
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 lnLineCount = lnLineCount + 1
                           ENDCASE
                        ELSE
                           m.ilineno = lnLineCount
                           IF m.nowngross # 0
                              INSERT INTO stub FROM MEMVAR
                           ENDIF
                           * STORE 0 TO m.ntrprev, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                        ENDIF
                     ENDSCAN
                  ENDIF

                  **********************************************************************************
                  * Process Misc Revenue 1
                  **********************************************************************************
                  m.nRevMisc1Save = m.nrevmisc1
                  IF m.nmiscrev1 # 0
                     SELECT tempinc
                     SCAN FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND csource = 'MISC1' AND nRunNo == m.nRunNo AND crunyear == m.crunyear

                        IF llExpProcessed
                           m.nexpense = 0
                        ELSE
                           llExpProcessed = .T.
                           *  If this is a one-person item, but it's not for this owner, don't reset the flag
                           IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                              llExpProcessed = .F.
                           ENDIF
                        ENDIF

                        IF llTaxWHProcessed
                           m.ntaxwith = 0
                        ELSE
                           llTaxWHProcessed = .T.
                        ENDIF

                        IF NOT EMPTY(cownerid)
                           IF tempinc.cownerid # m.cid
                              m.nrevmisc1 = m.nRevMisc1Save
                              LOOP
                           ELSE
                              m.nrevmisc1 = 100
                           ENDIF
                        ELSE
                           m.nrevmisc1 = m.nRevMisc1Save
                        ENDIF
                        m.cIncType  = '1'
                        m.nbblprice = nrate
                        m.nprice    = nrate
                        m.nunits    = nunits
                        m.ntotalinc = ntotalinc
                        STORE 0 TO m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes, m.nowntax
                        m.nnetval   = m.ntotalinc
                        m.ninterest = m.nrevmisc1
                        m.nowngross = ROUND(m.ntotalinc * (m.ninterest / 100), 2)
                        m.nnetcheck = m.nowngross - m.nexpense
                        m.cprodprd  = cperiod + '/' + RIGHT(cyear, 2)
                        m.dproddate = tempinc.dRevDate
                        SELECT disbchks
                        IF NOT tlStubRpt
                           DO CASE
                              CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                    glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                                 lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                 m.cwellname   = ' '
                                 STORE '' TO m.cprodprd, m.cIncType
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 m.lskip = .T.
                                 IF NOT llDupStub
                                    m.cwellid = ALLT(m.cwellid) + '{'
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                 ENDIF
                                 m.lskip     = .F.
                                 lnLineCount = lnLineCount + 3
                                 m.cwellname = lcOldWellName
                              CASE lnLineCount <= lnMaxLines
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                              CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                 m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 m.cwellid   = '{'
                                 llOverflow  = .T.
                                 m.crptgroup = 'AA'
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 SELECT stub
                                 LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 IF NOT FOUND()
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 lnLineCount = lnLineCount + 1
                           ENDCASE
                        ELSE
                           m.ilineno = lnLineCount
                           IF m.nowngross # 0
                              INSERT INTO stub FROM MEMVAR
                           ENDIF
                           * STORE 0 TO m.nmiscrev1, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                        ENDIF
                     ENDSCAN
                  ENDIF

                  **********************************************************************************
                  * Process Misc Revenue 2
                  **********************************************************************************
                  m.nRevMisc2Save = m.nrevmisc2
                  IF m.nmiscrev2 # 0
                     SELECT tempinc
                     SCAN FOR cwellid = m.cwellid AND cyear + cperiod = m.hyear + m.hperiod AND csource = 'MISC2' AND nRunNo == m.nRunNo AND crunyear == m.crunyear

                        IF llExpProcessed
                           m.nexpense = 0
                        ELSE
                           llExpProcessed = .T.
                           *  If this is a one-person item, but it's not for this owner, don't reset the flag
                           IF NOT EMPTY(cownerid) AND tempinc.cownerid # m.cid
                              llExpProcessed = .F.
                           ENDIF
                        ENDIF

                        IF llTaxWHProcessed
                           m.ntaxwith = 0
                        ELSE
                           llTaxWHProcessed = .T.
                        ENDIF


                        IF NOT EMPTY(cownerid)
                           IF tempinc.cownerid # m.cid
                              m.nrevmisc2 = m.nRevMisc2Save
                              LOOP
                           ELSE
                              m.nrevmisc2 = 100
                           ENDIF
                        ELSE
                           m.nrevmisc2 = m.nRevMisc2Save
                        ENDIF
                        m.cIncType  = '2'
                        m.nbblprice = nrate
                        m.nprice    = nrate
                        m.nunits    = nunits
                        m.ntotalinc = ntotalinc
                        STORE 0 TO m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes, m.nowntax
                        m.nnetval   = m.ntotalinc
                        m.ninterest = m.nrevmisc2
                        m.nowngross = ROUND(m.ntotalinc * (m.ninterest / 100), 2)
                        m.nnetcheck = m.nowngross - m.nexpense
                        m.cprodprd  = cperiod + '/' + RIGHT(cyear, 2)
                        m.dproddate = tempinc.dRevDate
                        SELECT disbchks
                        IF NOT tlStubRpt
                           DO CASE
                              CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                    glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                                 lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                                 m.cwellname   = ' '
                                 STORE '' TO m.cprodprd, m.cIncType
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 m.lskip = .T.
                                 IF NOT llDupStub
                                    m.cwellid = ALLT(m.cwellid) + '{'
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.ilineno = lnLineCount + 1
                                    INSERT INTO stub FROM MEMVAR
                                    m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                                 ENDIF
                                 m.lskip     = .F.
                                 lnLineCount = lnLineCount + 3
                                 m.cwellname = lcOldWellName
                              CASE lnLineCount <= lnMaxLines
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                                 IF NOT llDupLine
                                    lnLineCount = lnLineCount + 1
                                 ELSE
                                    IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                       lnLineCount = lnLineCount + 2
                                    ELSE
                                       lnLineCount = lnLineCount + 1
                                    ENDIF
                                 ENDIF
                              CASE lnLineCount > lnMaxLines AND NOT llOverflow
                                 m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 m.cwellid   = '{'
                                 llOverflow  = .T.
                                 m.crptgroup = 'AA'
                                 STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                                 STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                    M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                                 SELECT stub
                                 LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                                 IF NOT FOUND()
                                    m.ilineno = lnLineCount
                                    INSERT INTO stub FROM MEMVAR
                                 ENDIF
                                 lnLineCount = lnLineCount + 1
                           ENDCASE
                        ELSE
                           m.ilineno = lnLineCount
                           IF m.nowngross # 0
                              INSERT INTO stub FROM MEMVAR
                           ENDIF
                           * STORE 0 TO m.nmiscrev2, m.nunits, m.nprice, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                        ENDIF
                     ENDSCAN
                  ENDIF

                  **********************************************************************************
                  * Process Expenses when there is no revenue during this production period
                  **********************************************************************************
                  IF m.ngasrev = 0 AND m.noilrev = 0 AND m.nothrev = 0 AND ;
                        M.nmiscrev1 = 0 AND m.nmiscrev2 = 0 AND ;
                        (m.ngastax1 + m.ngastax2 + m.ngastax3 + m.ngastax4 = 0) AND ;
                        (m.noiltax1 + m.noiltax2 + m.noiltax3 + m.noiltax4 = 0) AND ;
                        (m.nothtax1 + m.nothtax2 + m.nothtax3 + m.nothtax4 = 0) AND ;
                        (m.nexpense # 0 OR m.nmktgexp # 0) AND NOT llExpProcessed

                     m.cIncType  = 'E'
                     m.nexpense  = m.nexpense + m.nmktgexp
                     m.nnetcheck = (m.nexpense) * -1
                     m.nbblprice = 0
                     m.nprice    = 0
                     m.nunits    = 0
                     m.ntotalinc = 0
                     STORE 0 TO m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nowntax, m.ntaxes
                     m.nnetval   = 0
                     m.ninterest = IIF(m.nworkint # 0, m.nworkint, m.nrevgas)
                     m.nowngross = 0
                     m.cprodprd  = m.hperiod + '/' + RIGHT(m.hyear, 2)
                     m.dproddate = {}
                     SELECT disbchks
                     IF NOT tlStubRpt
                        DO CASE
                           CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                 glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)
                              * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                              m.ilineno = lnLineCount
                              INSERT INTO stub FROM MEMVAR
                              IF NOT llDupLine
                                 lnLineCount = lnLineCount + 1
                              ELSE
                                 IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                    lnLineCount = lnLineCount + 2
                                 ELSE
                                    lnLineCount = lnLineCount + 1
                                 ENDIF
                              ENDIF
                              lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                              m.cwellname   = ' '
                              STORE '' TO m.cprodprd, m.cIncType
                              STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                              STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                 M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                              m.lskip = .T.
                              IF NOT llDupStub
                                 m.cwellid = ALLT(m.cwellid) + '{'
                                 m.ilineno = lnLineCount + 1
                                 INSERT INTO stub FROM MEMVAR
                                 m.ilineno = lnLineCount + 1
                                 INSERT INTO stub FROM MEMVAR
                                 m.ilineno = lnLineCount + 1
                                 INSERT INTO stub FROM MEMVAR
                                 m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                              ENDIF
                              m.lskip     = .F.
                              lnLineCount = lnLineCount + 3
                              m.cwellname = lcOldWellName
                           CASE lnLineCount <= lnMaxLines
                              m.ilineno = lnLineCount
                              INSERT INTO stub FROM MEMVAR
                              IF NOT llDupLine
                                 lnLineCount = lnLineCount + 1
                              ELSE
                                 IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                    lnLineCount = lnLineCount + 2
                                 ELSE
                                    lnLineCount = lnLineCount + 1
                                 ENDIF
                              ENDIF
                           CASE lnLineCount > lnMaxLines AND NOT llOverflow
                              m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                              m.cwellid   = '{'
                              llOverflow  = .T.
                              m.crptgroup = 'AA'
                              STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                              STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.nnetval, ;
                                 M.nowngross, m.nexpense, m.ninterest, m.ntaxwith
                              SELECT stub
                              LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                              IF NOT FOUND()
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                              ENDIF
                              lnLineCount = lnLineCount + 1
                        ENDCASE
                     ELSE
                        m.ilineno = lnLineCount
                        INSERT INTO stub FROM MEMVAR
                     ENDIF
                  ENDIF

                  **********************************************************************************
                  * Process flat rates
                  **********************************************************************************
                  IF disbchks.nflatrate # 0
                     * Set the flag to say expenses are being processed for this prod period

                     llExpProcessed = .T.
                     llFound        = .T.

                     m.cprodprd  = disbchks.hperiod + '/' + RIGHT(disbchks.hyear, 2)
                     m.cIncType  = 'F'
                     m.ntotalinc = disbchks.nflatrate * -1
                     m.crefid    = ''
                     m.nexpense  = 0

                     * Get the original price per MCF
                     m.nmcfprice  = 1

                     * Calculate the new price per MCF
                     STORE 0 TO m.nunits, m.nprice, m.ntax1, m.ntax2, m.ntax3, m.ntax4, m.ntaxes
                     m.ninterest = 100
                     m.ntotalinc = disbchks.nflatrate
                     m.crefid    = ''


                     m.nnetval = disbchks.nflatrate
                     m.nowntax = 0

                     m.nowngross = disbchks.nflatrate

                     IF NOT m.ljib
                        IF NOT m.lmanual  &&  Don't re-assign m.nnetcheck for manual entries - it's probably converted suspense, and the net is correct, and should be left alone
                           m.nnetcheck  = m.nowngross - m.nexpense - m.nmktgexp
                        ENDIF
                        m.nexpense   = m.nexpense + m.nmktgexp
                     ELSE
                        IF NOT m.lmanual  &&  Don't re-assign m.nnetcheck for manual entries - it's probably converted suspense, and the net is correct, and should be left alone
                           m.nnetcheck  = m.nowngross - m.ncompress - m.ngather - m.nmktgexp
                        ENDIF
                        m.nexpense   = m.ncompress + m.ngather + m.nmktgexp
                     ENDIF

                     m.dproddate = tempinc.dRevDate

                     IF NOT tlStubRpt
                        DO CASE
                           CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                 glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                              * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                              m.ilineno = lnLineCount
                              INSERT INTO stub FROM MEMVAR
                              IF NOT llDupLine
                                 lnLineCount = lnLineCount + 1
                              ELSE
                                 IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                    lnLineCount = lnLineCount + 2
                                 ELSE
                                    lnLineCount = lnLineCount + 1
                                 ENDIF
                              ENDIF
                              lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                              m.cwellname   = ' '
                              STORE '' TO m.cprodprd, m.cIncType
                              STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                              STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, m.nowngross, m.ninterest, m.ntaxwith
                              m.lskip = .T.
                              IF NOT llDupStub
                                 m.cwellid = ALLT(m.cwellid) + '{'
                                 m.ilineno = lnLineCount + 1
                                 INSERT INTO stub FROM MEMVAR
                                 m.ilineno = lnLineCount + 1
                                 INSERT INTO stub FROM MEMVAR
                                 m.ilineno = lnLineCount + 1
                                 INSERT INTO stub FROM MEMVAR
                                 m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                              ENDIF
                              m.lskip     = .F.
                              lnLineCount = lnLineCount + 3
                              m.cwellname = lcOldWellName
                           CASE lnLineCount <= lnMaxLines
                              m.ilineno = lnLineCount
                              INSERT INTO stub FROM MEMVAR
                              IF NOT llDupLine
                                 lnLineCount = lnLineCount + 1
                              ELSE
                                 IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                    lnLineCount = lnLineCount + 2
                                 ELSE
                                    lnLineCount = lnLineCount + 1
                                 ENDIF
                              ENDIF
                           CASE lnLineCount > lnMaxLines AND NOT llOverflow
                              m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                              m.cwellid   = '{'
                              llOverflow  = .T.
                              m.crptgroup = 'AA'
                              STORE '' TO m.cprodprd, m.cIncType
                              STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nnetcheck, m.nbbl, m.nmcf
                              STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, m.nowngross, m.ninterest, m.ntaxwith
                              SELECT stub
                              LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                              IF NOT FOUND()
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                              ENDIF
                              lnLineCount = lnLineCount + 1
                           CASE lnLineCount > lnMaxLines
                              lnLineCount = lnLineCount + 1
                        ENDCASE
                     ELSE
                        m.ilineno = lnLineCount
                        INSERT INTO stub FROM MEMVAR
                     ENDIF
                  ENDIF

                  lcidChec  = m.cidchec
                  jcWellID  = m.cwellid
                  jcIntType = m.cIntType
               ENDSCAN && disbchks

               IF NOT FILE(m.goApp.cCommonFolder + 'nostubpmts.txt')
                  SCAN FOR crectype = 'P' AND cid == m.cid AND NOT llNoStub
                     SCATTER MEMVAR
                     IF NOT tlStubRpt
                        DO CASE
                           CASE (lnLineCount = 13 OR (MOD(lnLineCount - 13, gnStubLine) = 0) AND lnLineCount >= 13) AND ;
                                 glSkipPerf AND IIF(NOT llVoidNext, lnLineCount <= gnStubLine, .T.)  &&  Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                              * Do calc to determine where the perf skipping should occur on 2nd and subsequent pages
                              m.ilineno = lnLineCount
                              STORE '' TO m.cprodprd, m.cIncType
                              STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nbbl, m.nmcf
                              STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                 M.nowngross, m.nexpense, m.ninterest
                              m.cIncType = '$'
                              m.cprodprd = 'PMT'
                              INSERT INTO stub FROM MEMVAR
                              IF NOT llDupLine
                                 lnLineCount = lnLineCount + 1
                              ELSE
                                 IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                    lnLineCount = lnLineCount + 2
                                 ELSE
                                    lnLineCount = lnLineCount + 1
                                 ENDIF
                              ENDIF
                              lcOldWellName = m.cwellname  &&  Store the name, so we don't have to look it up later - BH 8/31/06
                              m.cwellname   = ' '
                              STORE '' TO m.cprodprd, m.cIncType
                              STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother,  m.nbbl, m.nmcf
                              STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, m.nowngross, m.ninterest, m.ntaxwith
                              m.lskip = .T.
                              IF NOT llDupStub
                                 m.cwellid = ALLT(m.cwellid) + '{'
                                 m.ilineno = lnLineCount + 1
                                 INSERT INTO stub FROM MEMVAR
                                 m.ilineno = lnLineCount + 1
                                 INSERT INTO stub FROM MEMVAR
                                 m.ilineno = lnLineCount + 1
                                 INSERT INTO stub FROM MEMVAR
                                 m.cwellid = SUBSTR(m.cwellid, 1, LEN(ALLT(m.cwellid)) - 1)
                              ENDIF
                              m.lskip     = .F.
                              lnLineCount = lnLineCount + 3
                              m.cwellname = lcOldWellName
                           CASE lnLineCount <= lnMaxLines
                              m.ilineno = lnLineCount
                              STORE '' TO m.cprodprd, m.cIncType
                              STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother,  m.nbbl, m.nmcf
                              STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                                 M.nowngross, m.nexpense, m.ninterest
                              m.cIncType = '$'
                              m.cprodprd = 'PMT'
                              m.ilineno  = 99
                              INSERT INTO stub FROM MEMVAR
                              IF NOT llDupLine
                                 lnLineCount = lnLineCount + 1
                              ELSE
                                 IF jcWellID # m.cwellid OR jcIntType # m.cIntType
                                    lnLineCount = lnLineCount + 2
                                 ELSE
                                    lnLineCount = lnLineCount + 1
                                 ENDIF
                              ENDIF
                           CASE lnLineCount > lnMaxLines AND NOT llOverflow
                              m.cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                              m.cwellid   = '{'
                              llOverflow  = .T.
                              m.crptgroup = 'AA'
                              STORE '' TO m.cprodprd, m.cIncType
                              STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nbbl, m.nmcf
                              STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, m.nowngross, m.ninterest, m.ntaxwith
                              SELECT stub
                              LOCATE FOR cid = m.cid AND cwellname = '** SEE DISTRIBUTION STATEMENT FOR MORE DETAIL**'
                              IF NOT FOUND()
                                 m.ilineno = lnLineCount
                                 INSERT INTO stub FROM MEMVAR
                              ENDIF
                              lnLineCount = lnLineCount + 1
                           CASE lnLineCount > lnMaxLines
                              lnLineCount = lnLineCount + 1
                        ENDCASE
                     ELSE
                        m.ilineno = lnLineCount
                        STORE '' TO m.cprodprd, m.cIncType
                        STORE 0 TO m.nincome, m.nexpense, m.ntaxes, m.nother, m.nbbl, m.nmcf
                        STORE 0 TO m.nprice, m.nunits, m.ntotalinc, m.ntax, m.ntax1, m.nnetval, ;
                           M.nowngross, m.nexpense, m.ninterest
                        m.cIncType = '$'
                        m.cprodprd = 'PMT'
                        m.ilineno  = 99
                        INSERT INTO stub FROM MEMVAR
                     ENDIF
                  ENDSCAN
               ENDIF
            ENDSCAN  && pickchks
            oProgress.CloseProgress()
         ENDIF
      ENDIF

      SELE stub
      SCAN FOR NOT INLIST(cIncType, 'B', 'T')
         m.cwellid = ALLT(cwellid)
         SELE wells
         SET ORDER TO cwellid
         IF SEEK(m.cwellid)
            m.ccounty = ccounty
            m.cstate  = cstate
            SELE stub
            REPL ccounty WITH m.ccounty, ;
               cstate  WITH m.cstate
         ENDIF
         SELECT stub
         IF EMPTY(cwellname) AND 'ALL ' $ m.cwellid  &&  Fill in well name, so the report doesn't skip it
            SELECT stub
            REPLACE cwellname WITH 'Previous Suspense'
         ENDIF
      ENDSCAN

      IF FILE('datafiles\gallegos.txt') AND NOT tlStubRpt
         SELECT  cid, ;
                 cGROUP, ;
                 lskip, ;
                 npageno, ;
                 dcheckdate, ;
                 cprodprd, ;
                 crptgroup, ;
                 cprogcode, ;
                 cpayee, ;
                 ccheckno, ;
                 'I' AS cidtype, ;
                 cidchec, ;
                 cwellid, ;
                 cwellname, ;
                 SUM(nowngross + nowntax) AS nowngross, ;
                 SUM(nowntax) AS nowntax, ;
                 SUM(nexpense) AS nexpense, ;
                 SUM(nbackwith) AS nbackwith, ;
                 SUM(ntaxwith) AS ntaxwith, ;
                 ntax, ;
                 ntaxes, ;
                 cSuspType, ;
                 cIntType, ;
                 SUM(nnetval) AS nnetval ;
             FROM stub ;
             WHERE NOT 'Withholding' $ cwellname ;
             INTO CURSOR stub READWRITE ;
             ORDER BY cpayee, crptgroup, cwellname, cidchec ;
             GROUP BY cpayee, crptgroup, cwellname, cidchec
         SET SAFETY OFF
         INDEX ON cidchec TAG cidchec
      ENDIF

      IF llDupStub AND NOT tlStubRpt
         CREATE CURSOR stubcnt ;
            (cidchec   C(8), ;
              cid        C(10), ;
              cIntType   C(1), ;
              ncount     I)
         STORE 0 TO m.ncount
         m.cidchec = '**'
         SELE cidchec, cid FROM stub INTO CURSOR temp ORDER BY cidchec, cid GROUP BY cidchec, cid
         SELE temp
         SCAN
            IF m.cidchec # '**' AND m.cidchec # cidchec
               INSERT INTO stubcnt FROM MEMVAR
               m.ncount = 0
            ENDIF
            m.cidchec = cidchec
            m.cid     = cid
            STORE ' ' TO m.cwellid, m.cIntType
            SELE stub
            SCAN FOR cidchec == m.cidchec
               IF ((cwellid # m.cwellid AND cwellid # '{ ') OR (cIntType # m.cIntType)) AND llSplitWell
                  m.ncount = m.ncount + 1
               ENDIF
               m.cwellid  = cwellid
               m.cIntType = cIntType
               m.ncount   = m.ncount + 1
            ENDSCAN
         ENDSCAN
         * Get last owner
         INSERT INTO stubcnt FROM MEMVAR
         *   SELE cidchec, cid, cwellid, COUNT(cidchec) AS ncount FROM stub INTO CURSOR stubcnt ORDER BY cidchec GROUP BY cidchec
         SELE stub
         SCATTER MEMVAR BLANK
         SELE stubcnt
         SCAN
            SCATTER MEMVAR
            IF NOT llVoidNext  &&  Don't add additional lines if voiding next check - will really screw things up - BH 04/27/2004
               FOR lnX = 1 TO (lnMaxLines + 1 - m.ncount)
                  m.lskip     = .T.
                  m.crptgroup = 'AA'
                  m.cprodprd  = '99/99'
                  m.cwellid   = '{'  &&  Use character at the end of the ASCII table, so it will always be last, after the regular well IDs - BH 11/12/2004
                  m.cSuspType = 'Z'
                  INSERT INTO stub FROM MEMVAR
               ENDFOR
            ENDIF
         ENDSCAN

         SELE * FROM stub INTO CURSOR temp
         SELE temp
         SCAN
            SCATTER MEMVAR
            m.crptgroup = 'BB'
            INSERT INTO stub FROM MEMVAR
         ENDSCAN

         SELE stub
         SET ORDER TO 0
         SCAN
            IF crptgroup # 'AA'
               REPL crptgroup WITH 'BB'
            ENDIF
            REPL ntax WITH ntaxes
         ENDSCAN
      ENDIF


      IF llVoidNext AND NOT tlStubRpt  &&  If voiding next check for overflow, pad the stub to the max lines setting before advancing to the next check

         WAIT WIND NOWAIT 'Processing Voided Checks...'


         IF gnStubLine = 0  &&  Initialize, if it's never been defined on the DMOption screen
            gnStubLine = 12
         ENDIF

         *!*            IF lcCheckType # 'LC'
         *!*               gnStubLine = 12
         *!*            ELSE
         *!*               gnStubLine = 12  &&  Center checks only have one stub to print on so default to 12
         *!*            ENDIF
         *!*
         *!*            IF llSplitWell
         *!*               gnStubLine = gnStubLine/2
         *!*            ENDIF

         CREATE CURSOR stub1 ;  &&  New dummy stub file to dump the data, plus appropriately spaced blank lines into
            (cid             C(10), ;
              ilineno        I, ;
              cidtype        C(1), ;
              cpayee         C(60), ;
              cprogcode      C(10), ;
              ccheckno       C(10), ;
              cidchec        C(8), ;
              npageno        I, ;
              crptgroup      C(2), ;
              cwellid        C(10), ;
              cwellname      C(60), ;
              ccounty        C(25), ;
              cstate         C(2), ;
              nincome        N(9, 2), ;
              nbbl           N(12, 2), ;
              cIncType       C(1), ;
              nmcf           N(12, 2), ;
              nbblprice      N(12, 6), ;
              nmcfprice      N(12, 6), ;
              noilrev        N(12, 2), ;
              ngasrev        N(12, 2), ;
              cIntType       C(1), ;
              cDesc          C(60), ;
              cinvnum        C(20), ;
              dinvdate       D, ;
              dcheckdate     D, ;
              ninvtot        N(12, 2), ;
              namtpaid       N(12, 2), ;
              ndisctot       N(12, 2), ;
              nAmount        N(12, 2), ;
              dproddate      D, ;
              nexpense       N(9, 2), ;
              ntax           N(9, 2), ;
              ntaxes         N(9, 2), ;
              nnetcheck      N(9, 2), ;
              creference     C(20), ;
              nother         N(9, 2), ;
              cprodprd       C(5), ;
              cyear          C(4), ;
              cperiod        C(2), ;
              nunits         N(12, 2), ;
              nprice         N(12, 4), ;
              ntotalinc      N(12, 2), ;
              ntax1          N(12, 2), ;
              ntax2          N(12, 2), ;
              ntax3          N(12, 2), ;
              ntax4          N(12, 2), ;
              nexpcl0        N(12, 2), ;
              nexpcl1        N(12, 2), ;
              nexpcl2        N(12, 2), ;
              nexpcl3        N(12, 2), ;
              nexpcl4        N(12, 2), ;
              nexpcl5        N(12, 2), ;
              nowntax        N(12, 2), ;
              nnetval        N(12, 2), ;
              ninterest      N(11, 7), ;
              nowngross      N(12, 2), ;
              nWellGath      N(12, 2), ;
              nWellComp      N(12, 2), ;
              lskip          L, ;
              cGROUP         C(2))

         SELECT checktmp
         SCAN
            SELECT  * ;
                FROM stub ;
                INTO CURSOR tmpa ;
                WHERE cidchec = checktmp.cidchec ;
                    AND (crptgroup = 'AA' ;
                      OR EMPTY(crptgroup)) ;  &&  Pull all A records first, or empty ones if we're not doing duplicate stubs

            IF llDupStub  &&  Only get the B recs if doing a duplicate stub, since there won't be any otherwise
               SELECT * FROM stub INTO CURSOR tmpb WHERE cidchec = checktmp.cidchec AND crptgroup = 'BB' ORDER BY cidchec, crptgroup, cwellid, cprodprd  &&  Pull all B records next
            ENDIF

            lnMaxPages   = CEILING(_TALLY / gnStubLine)       &&  Figure out how many pages will be needed
            lnTotalLines = gnStubLine - (MOD(_TALLY, gnStubLine))  &&  Figure out the max number of blank lines that will need to be added

            *  If the number of lines on a page equals the number it thinks should be added, reset lnTotalLines to 0 so it doesn't add anything
            IF lnTotalLines = gnStubLine
               lnTotalLines = 0
            ENDIF

            SELECT checktmp
            REPLACE ncount WITH lnMaxPages  &&  Plug in the number of extra checks, so we know how many to void later

            FOR lnX = 1 TO lnMaxPages
               SELECT tmpa
               SCAN FOR BETWEEN(RECNO(), ((lnX - 1) * gnStubLine) + 1, gnStubLine * lnX)  &&  Add the A records back into the stub1 cursor
                  SCATTER MEMVAR
                  m.ilineno = m.ilineno + 1
                  m.npageno = lnX
                  INSERT INTO stub1 FROM MEMVAR
               ENDSCAN
               SELE stub1
               SCATTER MEMVAR BLANK
               m.npageno   = lnX
               m.cidchec   = checktmp.cidchec
               m.cid       = checktmp.cid
               m.cwellid   = '{'
               m.crptgroup = IIF(llDupStub, 'AA', '')
               m.cprodprd  = '99/99'

               IF lnX = lnMaxPages   &&  Insert two blank lines if we're not on the last page, otherwise, fill the stub with blanks
                  FOR lnZ = 1 TO (lnTotalLines)
                     INSERT INTO stub1 FROM MEMVAR
                  ENDFOR
               ENDIF

               IF llDupStub  &&  Only append from the tmpb cursor if we're doing duplicate stubs, otherwise, it won't be created
                  SELECT tmpb
                  SCAN FOR BETWEEN(RECNO(), ((lnX - 1) * gnStubLine) + 1, gnStubLine * lnX)
                     SCATTER MEMVAR
                     m.npageno = lnX
                     m.ilineno = m.ilineno + 1
                     INSERT INTO stub1 FROM MEMVAR
                  ENDSCAN
                  SELECT stub1
                  SCATTER MEMVAR BLANK
                  m.npageno   = lnX
                  m.cidchec   = checktmp.cidchec
                  m.cid       = checktmp.cid
                  m.cwellid   = '{'
                  m.crptgroup = 'BB'
                  m.cprodprd  = '99/99'

                  IF lnX = lnMaxPages
                     FOR lnZ = 1 TO (lnTotalLines)
                        INSERT INTO stub1 FROM MEMVAR
                     ENDFOR
                  ENDIF

               ENDIF
            ENDFOR
         ENDSCAN


         SELECT checktmp  &&  Increment check numbers if any checks have gone to multiple pages - figure out a better way of doing this some time...
         LOCATE FOR ncount > 1  &&  See if there's any multiple page checks, so we know whether to create the chkvoid cursor
         IF FOUND()
            CREATE CURSOR chkvoid ;
               (cEntryType C(1), ;
                 cid        C(10), ;
                 cpayee     C(60), ;
                 csource    C(2), ;
                 cGROUP     C(2), ;
                 dcheckdate D, ;
                 cDesc      C(10), ;
                 ccheckno   C(10))
            SELECT checktmp
            GO TOP
            SCAN FOR ncount > 1
               FOR lnX = 1 TO (ncount - 1)
                  SCATTER MEMVAR
                  m.cDesc    = 'VOID'
                  m.cpayee   = ALLT(m.cpayee) + ' - Check Overflow'
                  m.ccheckno = PADL(ALLT(STR(VAL(ccheckno) + lnX)), 10, ' ')
                  INSERT INTO chkvoid FROM MEMVAR
               ENDFOR
               SELECT checktmp
               lnrecNo = RECNO()
               lnCount = ncount - 1
               SKIP 1  &&  Go to the next record and begin updating check numbers
               REPLACE ccheckno WITH PADL(ALLT(STR(VAL(ccheckno) + (lnCount))), 10, ' ') REST
               GOTO lnrecNo
            ENDSCAN
         ENDIF

         SELECT stub
         USE
         USE DBF('stub1') AGAIN IN 0 ALIAS stub
      ENDIF

      SELECT stub
      INDEX ON cidchec + crptgroup + cwellid TAG myorder
      lnLineNoSave = 0
      SCAN
         IF ilineno # 0
            lnLineNoSave = ilineno
         ELSE
            REPLACE ilineno WITH lnLineNoSave + 1
            lnLineNoSave = lnLineNoSave + 1
         ENDIF
      ENDSCAN

      IF USED('checktmp')
         SELECT checktmp  &&  Scan for checktmp entries with no stub entries, and create one to avoid printing problems - BH 09-26-06
         SCAN
            SELECT stub
            SCATTER MEMVAR BLANK
            LOCATE FOR cidchec == checktmp.cidchec
            IF NOT FOUND()  &&  No record in the stub cursor, so make one
               m.cidchec   = checktmp.cidchec
               m.cwellname = '**  No stub detail available  **'
               INSERT INTO stub FROM MEMVAR
            ENDIF
         ENDSCAN
      ENDIF

      * Plug in missing interests
      SELE stub
      SCAN FOR EMPTY(ninterest)
         m.cwellid  = ALLT(cwellid)
         m.cownerid = cid
         swSelect('wellinv')
         LOCATE FOR cownerid = m.cownerid AND cwellid = m.cwellid
         IF FOUND()
            IF NOT INLIST(stub.cIncType, 'B', 'T')
               m.ninterest = IIF(NOT EMPTY(nrevgas), nrevgas, nrevoil)
            ELSE
               IF stub.cIncType = 'T'
                  m.ninterest = ntaxpct
               ENDIF
            ENDIF
            SELE stub
            REPL ninterest WITH m.ninterest
         ENDIF
      ENDSCAN


      IF NOT tlStubRpt AND FILE('progstub.cfg')  &&  Summarize stubs by program code - BH 11/16/07

         SELECT  cid, ;
                 cidtype, ;
                 cpayee, ;
                 cprogcode, ;
                 ccheckno, ;
                 cidchec, ;
                 npageno, ;
                 crptgroup, ;
                 cwellid, ;
                 cwellname, ;
                 ccounty, ;
                 cstate, ;
                 SUM(nincome) AS nincome, ;
                 SUM(nbbl) AS nbbl, ;
                 cIncType, ;
                 SUM(nmcf) AS nmfc, ;
                 SUM(nbblprice) AS nbblprice, ;
                 SUM(nmcfprice) AS nmcfprice, ;
                 SUM(noilrev) AS noilrev, ;
                 SUM(ngasrev) AS ngasrev, ;
                 cIntType, ;
                 cDesc, ;
                 cinvnum, ;
                 dinvdate, ;
                 dcheckdate, ;
                 SUM(ninvtot) AS ninvtot, ;
                 SUM(namtpaid) AS namtpaid, ;
                 SUM(ndisctot) AS ndisctot, ;
                 SUM(nAmount) AS nAmount, ;
                 dproddate, ;
                 SUM(nexpense) AS nexpense, ;
                 SUM(ntax) AS ntax, ;
                 SUM(ntaxes) AS ntaxes, ;
                 SUM(nnetcheck) AS nnetcheck, ;
                 creference, ;
                 SUM(nother) AS nother, ;
                 cprodprd, ;
                 cyear, ;
                 cperiod, ;
                 SUM(nunits) AS nunits, ;
                 SUM(nprice) AS nprice, ;
                 SUM(ntotalinc) AS ntotalinc, ;
                 SUM(ntax1) AS ntax1, ;
                 SUM(ntax2) AS ntax2, ;
                 SUM(ntax3) AS ntax3, ;
                 SUM(ntax4) AS ntax4, ;
                 SUM(nexpcl0) AS nexpcl0, ;
                 SUM(nexpcl1) AS nexpcl1, ;
                 SUM(nexpcl2) AS nexpcl2, ;
                 SUM(nexpcl3) AS nexpcl3, ;
                 SUM(nexpcl4) AS nexpcl4, ;
                 SUM(nexpcl5) AS nexpcl5, ;
                 SUM(nowntax) AS nowntax, ;
                 SUM(nnetval) AS nnetval, ;
                 SUM(ninterest) AS ninterest, ;
                 SUM(nowngross) AS nowngross, ;
                 SUM(nWellGath) AS nWellGath, ;
                 SUM(nWellComp) AS nWellComp, ;
                 lskip, ;
                 cGROUP, ;
                 .F. AS junk ;
             FROM stub ;
             INTO CURSOR stubtmp ;
             GROUP BY cidchec, cprogcode

         USE IN stub  &&  Close the stub cursor, b/c we're going to re-use stubtmp as stub

         USE DBF('stubtmp') AGAIN IN 0 ALIAS stub

         SET SAFETY OFF
         SELECT stub
         INDEX ON cidchec + crptgroup TAG cidchec  &&  Set index to match original index

         SCAN  &&  Change the well name to be the program name
            SELECT programs
            LOCATE FOR cprogcode = stub.cprogcode
            IF FOUND()
               REPLACE stub.cwellname WITH cProgName
            ENDIF
         ENDSCAN
      ENDIF


      SELE stub
      SET ORDER TO 0
      SCAN FOR EMPTY(crptgroup)
         REPL crptgroup WITH 'AA'
      ENDSCAN

      * Show the interests as decimal ints if the preference is set
      llReturn = DecimalInts('stub')

      SELECT stub
      * Setup what index cidchec is going to look like
      DO CASE
         CASE NOT tlStubRpt
            DO CASE
               CASE FILE('progstub.cfg')
                  INDEX ON cidchec + crptgroup TAG cidchec  &&  Set index to match original index
               CASE llVoidNext
                  * Set order to the order added to the table, which keeps spacing and blank lines in correct place
                  INDEX ON cidchec + STR(npageno) + crptgroup + cwellid TAG cidchec
               OTHERWISE
                  INDEX ON cidchec + crptgroup + PADL(TRANSFORM(ilineno), 3, '0') + cwellid + cIntType + cSuspType + cprodprd TAG cidchec
            ENDCASE
         OTHERWISE
            INDEX ON cid + crptgroup + cwellname + cSuspType + cprodprd TAG cidchec
      ENDCASE

      INDEX ON cid + cGROUP + cprogcode TAG cid

      SELE stub
      SET ORDER TO cidchec
      WAIT CLEAR

      IF VARTYPE(oProgress) = 'O'
         oProgress.CloseProgress()
      ENDIF

      TRY
         USE IN SELECTED
      CATCH
      ENDTRY
   ENDPROC


   PROCEDURE INIT

      THIS.omessage  = findglobalobject('cmMessage')
      THIS.oregistry = findglobalobject('cmRegistry')
   ENDPROC


ENDDEFINE
*
*-- EndDefine: swowner
**************************************************


********************************************************************************************************************************************************************
*-- Class:        swownerstmt (c:\develop\codeminenew\custom\swowner.vcx)
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   08/20/08 04:36:13 PM
********************************************************************************************************************************************************************
DEFINE CLASS swownerstmt AS CUSTOM


   HEIGHT           = 38
   WIDTH            = 100
   lroyaltyowner    = .F.
   cDMBatch         = ''
   cyear            = ''
   cowner1          = ''
   cowner2          = ''
   cwell1           = ''
   cwell2           = ''
   cGROUP           = ''
   nRunNo           = 0
   dAcctDate        = {}
   dExpDate         = {}
   dRevDate         = {}
   lnetwells        = .F.
   lcloserun        = .F.
   lclosed          = .F.
   ooptions         = .F.
   oinvtmp          = .F.
   omessage         = .F.
   cownerid         = ''
   ownergroup       = .F.
   nownertotal      = .F.
   lownertaxexempt  = .F.
   lowneronhold     = .F.
   lallminsreleased = .F.
   cperiod          = ''
   lsplitperiods    = .F.
   ncompress        = .F.
   ngather          = .F.
   owellwork        = .F.
   odist            = .F.
   crunyear         = ''
   cownertype       = ''
   nwelltot         = 0
   ntotinc          = 0
   lexemptroyalty   = .F.
   nbackupwith      = 0
   ntaxwith         = 0
   cwellid          = ''
   noiltax1         = 0
   noiltax2         = 0
   noiltax3         = 0
   noiltax4         = 0
   ngastax1         = 0
   ngastax2         = 0
   ngastax3         = 0
   ngastax4         = 0
   nothtax1         = 0
   nothtax2         = 0
   nothtax3         = 0
   nothtax4         = 0
   ntotalbbl        = 0
   ntotalmcf        = 0
   noilamount       = 0
   ngasamount       = 0
   notheramount     = 0
   ncompamount      = 0
   ngathamount      = 0
   ntotalother      = 0
   cprogcode        = ''
   nbalance         = 0
   lbelowminimum    = .F.
   cSuspType        = ''
   lcanceled        = .F.
   lziporder        = .F.
   lprintdef        = .F.
   lprintmin        = .F.
   lnoprod          = .F.
   lIncludeChecks   = .F.
   lflatrate        = .F.
   lrounding        = .F.
   linterestheld    = .F.
   lfreqheld        = .F.
   lIncSummary      = .F.
   *-- Owner marked to get an owner stmt
   ldetail      = .F.
   nownermin    = 0
   lownerposted = .F.
   lchksubtot   = .F.
   *-- Don't calculate tax for this entry. It came from converted suspense.
   lnotax       = .F.
   NAME         = 'swownerstmt'
   lflatalloc   = .F.
   osuspense    = .NULL.
   nNewRunNo    = 0
   lSumExp      = .F.
   lSumRev      = .F.
   lNewRun      = .F.
   lEmailOnly   = .F.
   lDirDeposit  = .F.
   lNoSuspDet   = .F.
   lcanceled    = .F.
   lClosing     = .F.
   lPartnerPost = .F.
   oProgress    = .NULL.

   ***********************************************************************
   PROCEDURE MAIN
      ***********************************************************************
      LPARAMETERS tlSelected
      LOCAL lcoldprog, lnowncount, lnPriorRunNo, lcPriorRunYear, llIncludeDirDep
      LOCAL lcoldprogname, lcperiod1, lcperiod2, lnperiodbal, llDirDep
      LOCAL llexemptroyalty, m.ljib, tcWellID1, tcWellID2, lnRevExpRun
      LOCAL llReturn, loError


      llReturn = .T.

      TRY
         * Close the suspense files and open them again to reset them
         * They could have been changed in earlier processing and we 
         * need them back to original state
         swclose('tsuspense')
         swclose('suspense')
         swSelect('suspense')
         STORE .F. TO llDirDep, THIS.lcanceled
         IF tlSelected
            * Use the owners selected
            SELECT SELECTED
            GO TOP
            THIS.cowner1 = cid
            GO BOTT
            THIS.cowner2 = cid
         ELSE
            SELECT  cownerid AS cid ;
                FROM investor ;
                WHERE BETWEEN(cownerid, THIS.cowner1, THIS.cowner2) ;
                INTO CURSOR SELECTED ;
                ORDER BY cownerid ;
                GROUP BY cownerid
         ENDIF

         llIncludeDirDep = THIS.lDirDeposit

         tcRunYear   = THIS.crunyear
         tnRunNo     = THIS.nRunNo
         lnRevExpRun = THIS.nRunNo

         THIS.omessage = findglobalobject('cmmessage')

         swSelect('wells')
         SET ORDER TO cwellid
         GO TOP
         tcWellID1 = cwellid
         GO BOTT
         tcWellID2 = cwellid

         * Clean up expense codes by plugging in "OE" to the cTaxCode field if it's empty
         * Blank tax codes keep that expense code from showing up on the reports. "OE" is
         * the code for lease operating expenses
         swSelect('expcat')
         REPLACE ctaxcode WITH 'OE' FOR ctaxcode = '  '

         IF THIS.nRunNo = 0
            THIS.lNewRun   = .T.
            THIS.nNewRunNo = getrunno(tcRunYear, .T., 'R')
            THIS.nRunNo    = THIS.nNewRunNo
         ELSE
            THIS.nNewRunNo = THIS.nRunNo
         ENDIF
         m.nRunNo    = THIS.nRunNo

         * Create the suspense object
         THIS.osuspense          = CREATEOBJECT('suspense')
         THIS.osuspense.crunyear = THIS.crunyear
         THIS.osuspense.nRunNo   = THIS.nNewRunNo
         THIS.osuspense.lNewRun  = THIS.lNewRun

         * Create cursor to hold manually entered taxes
         * to keep them separate from calculated taxes.
         CREATE CURSOR manualTax ;
            (cwellid    C(10), ;
              cyear      C(4), ;
              cperiod    C(2), ;
              noiltax1   N(9, 2), ;
              noiltax2   N(9, 2), ;
              noiltax3   N(9, 2), ;
              noiltax4   N(9, 2), ;
              ngastax1   N(9, 2), ;
              ngastax2   N(9, 2), ;
              ngastax3   N(9, 2), ;
              ngastax4   N(9, 2), ;
              nprodtax1  N(9, 2), ;
              nprodtax2  N(9, 2), ;
              nprodtax3  N(9, 2), ;
              nprodtax4  N(9, 2))

         *  Call distproc to create the (invtmp) and (wellwork) cursors
         THIS.odist = CREATEOBJECT('distproc', THIS.cowner1, THIS.cowner2, ;
              '01', ;
              THIS.crunyear, ;
              THIS.cGROUP, 'O', THIS.dAcctDate, .F., THIS.nNewRunNo, .F., THIS.lNewRun)

         THIS.odist.lFlatRates = .T.

         IF NOT THIS.lClosing
            THIS.odist.MAIN(.F., .T.)
         ENDIF

         IF NOT USED('invtmp')
            llReturn = .F.
            EXIT
         ENDIF

         _VFP.AUTOYIELD = .T.
         SET ESCAPE ON

         * Setup the ability to cancel processing
         ON ESCAPE m.goApp.lcanceled = .T.

         THIS.osuspense.getlasttype(.T., .T., THIS.cGROUP, .T.)

         * Get a copy of invtmp before suspense is added in so
         * we can check for owners who got checks to report
         * the top of the statement properly.
         SELECT * FROM invtmp INTO CURSOR currentrun WHERE crectype # 'P' AND EMPTY(cSuspType)

         * Create invtmp and wellwork cursors with the given run's data
         SELECT invtmp
         SCAN FOR nRunNo_In # 0
            m.cwellid  = cwellid
            m.nRunNo   = nRunNo_In
            m.crunyear = cRunYear_In
            swSelect('wellhist')
            SCAN FOR cwellid == m.cwellid AND crunyear == m.crunyear AND nRunNo == m.nRunNo AND crectype = 'R'
               SCATTER MEMVAR
               SELECT wellwork
               LOCATE FOR crunyear == m.crunyear AND nRunNo == m.nRunNo AND cwellid == m.cwellid AND hyear = m.hyear AND hperiod = m.hperiod AND crectype = 'R'
               IF NOT FOUND()
                  INSERT INTO wellwork FROM MEMVAR
               ENDIF
            ENDSCAN
            *
            * Fill in any empty pcts that came from ownpcts
            * If nnetcheck is not zero there had to be pcts in place when the run was closed
            *
            IF invtmp.nnetcheck # 0 AND invtmp.nworkint = 0 AND invtmp.nrevgas = 0 AND invtmp.nrevoil = 0 AND invtmp.nintclass1 = 0 AND invtmp.nintclass2 = 0 AND invtmp.nintclass3 = 0 AND ;
                  invtmp.nintclass4 = 0 AND invtmp.nintclass5 = 0 AND invtmp.nbcpint = 0 AND invtmp.nacpint = 0 AND invtmp.nrevmisc1 = 0 AND invtmp.nrevmisc2 = 0
               swSelect('wellinv')
               LOCATE FOR cownerid == invtmp.cownerid AND cwellid == invtmp.cwellid AND cTypeInv == invtmp.cTypeInv
               IF FOUND()
                  SELECT invtmp
                  REPLACE nworkint   WITH wellinv.nworkint, ;
                     nintclass1 WITH wellinv.nintclass1, ;
                     nintclass2 WITH wellinv.nintclass2, ;
                     nintclass3 WITH wellinv.nintclass3, ;
                     nintclass4 WITH wellinv.nintclass4, ;
                     nintclass5 WITH wellinv.nintclass5, ;
                     nacpint    WITH wellinv.nacpint, ;
                     nbcpint    WITH wellinv.nbcpint, ;
                     nrevgas    WITH wellinv.nrevgas, ;
                     nrevoil    WITH wellinv.nrevoil, ;
                     nrevmisc1  WITH wellinv.nrevmisc1, ;
                     nrevmisc2  WITH wellinv.nrevmisc2, ;
                     nrevoth    WITH wellinv.nrevoth, ;
                     nrevtax1   WITH wellinv.nrevtax1, ;
                     nrevtax2   WITH wellinv.nrevtax2, ;
                     nrevtax3   WITH wellinv.nrevtax3, ;
                     nrevtax4   WITH wellinv.nrevtax4, ;
                     nrevtax5   WITH wellinv.nrevtax5, ;
                     nrevtax6   WITH wellinv.nrevtax6, ;
                     nrevtax7   WITH wellinv.nrevtax7, ;
                     nrevtax8   WITH wellinv.nrevtax8, ;
                     nrevtax9   WITH wellinv.nrevtax9, ;
                     nrevtax10  WITH wellinv.nrevtax10, ;
                     nrevtax11  WITH wellinv.nrevtax11, ;
                     nrevtax12  WITH wellinv.nrevtax12
               ELSE
                  LOCATE FOR cownerid == invtmp.cownerid AND cwellid == invtmp.cwellid
                  IF FOUND()
                     SELECT invtmp
                     REPLACE nworkint   WITH wellinv.nworkint, ;
                        nintclass1 WITH wellinv.nintclass1, ;
                        nintclass2 WITH wellinv.nintclass2, ;
                        nintclass3 WITH wellinv.nintclass3, ;
                        nintclass4 WITH wellinv.nintclass4, ;
                        nintclass5 WITH wellinv.nintclass5, ;
                        nacpint    WITH wellinv.nacpint, ;
                        nbcpint    WITH wellinv.nbcpint, ;
                        nrevgas    WITH wellinv.nrevgas, ;
                        nrevoil    WITH wellinv.nrevoil, ;
                        nrevmisc1  WITH wellinv.nrevmisc1, ;
                        nrevmisc2  WITH wellinv.nrevmisc2, ;
                        nrevoth    WITH wellinv.nrevoth, ;
                        nrevtax1   WITH wellinv.nrevtax1, ;
                        nrevtax2   WITH wellinv.nrevtax2, ;
                        nrevtax3   WITH wellinv.nrevtax3, ;
                        nrevtax4   WITH wellinv.nrevtax4, ;
                        nrevtax5   WITH wellinv.nrevtax5, ;
                        nrevtax6   WITH wellinv.nrevtax6, ;
                        nrevtax7   WITH wellinv.nrevtax7, ;
                        nrevtax8   WITH wellinv.nrevtax8, ;
                        nrevtax9   WITH wellinv.nrevtax9, ;
                        nrevtax10  WITH wellinv.nrevtax10, ;
                        nrevtax11  WITH wellinv.nrevtax11, ;
                        nrevtax12  WITH wellinv.nrevtax12
                  ENDIF
               ENDIF
            ENDIF
         ENDSCAN

         DELETE  ;
             FROM invtmp ;
             WHERE nworkint = 0 AND ;
                 nrevgas = 0  AND ;
                 nrevoil = 0  AND ;
                 nintclass1 = 0 AND ;
                 nintclass2 = 0 AND ;
                 nintclass3 = 0 AND ;
                 nintclass4 = 0 AND ;
                 nintclass5 = 0 AND ;
                 nbcpint = 0 AND ;
                 nacpint = 0 AND ;
                 ngather = 0 AND ;
                 ncompress = 0 AND ;
                 nnetcheck = 0

         * Add in any records being put into suspense this run
         * when we're reporting on a new run.
         IF tnRunNo = 0
            IF USED('tsuspense')
               SELECT tsuspense
               SCAN
                  SCATTER MEMVAR
                  IF m.nRunNo_In = THIS.nNewRunNo
                     m.nRunNo_In = THIS.nRunNo
                     m.cSuspType = ''
                     INSERT INTO invtmp FROM MEMVAR
                  ENDIF
               ENDSCAN
            ENDIF
         ENDIF

         * Custom mod to show ITD totals on the statement
         IF FILE('datafiles\totals.itd')
            DO calcytditd WITH THIS.dAcctDate, '**'
         ENDIF

         THIS.odist.lFlatRates = THIS.lflatrate

         WAIT WIND NOWAIT 'Building Report File....'
         LOCAL lnWellTot, lnInvTot, lnTotInc, jInvCnt, lnProgTot, lcoldprog, lcOldcProgName
         LOCAL lnTax, lnInvCnt
         LOCAL lcDirect, lnMinAmt
         LOCAL lcperiod1, lcperiod2, m.cGrpName, llRefId, llChgPrice
         LOCAL llHideComp, jGross

         STORE 0 TO lnWellTot, lnInvTot, lnTotInc, jInvCnt, lnProgTot, ;
            M.ntax, jGross, lnInvCnt
         STORE '   ' TO lcoldprog, lcOldcProgName, lcperiod1, lcperiod2, m.cperiod

         **-
         **-  Get the suspense flag from the group table
         **-
         swSelect('groups')
         SET ORDER TO cGROUP
         IF SEEK(THIS.cGROUP)
            THIS.lnetwells  = lNetDef
         ELSE
            THIS.lnetwells  = .T.
         ENDIF

         * Create "dummy" exptemp cursor
         CREATE CURSOR exptemp (lused L)

         * Create "dummy" inctemp cursor
         CREATE CURSOR inctemp (lused L)

         IF NOT EMPTY(THIS.cDMBatch)
            *  Reset used flag in roundtmp
            IF USED('roundtmp')
               swSelect('roundtmp')
               REPL lused WITH .F. FOR cDMBatch = THIS.cDMBatch
            ENDIF
         ENDIF

         * Set description for whether we're reporting on a well or program
         IF FILE(m.goApp.cCommonFolder + 'sumprogs.txt')
            lcWellProg = 'Program'
         ELSE
            lcWellProg = 'Well'
         ENDIF

         *
         *  Create work cursor for report data
         *
         CREATE CURSOR  statemnt ;
            (crptgroup   C(1), ;
              cpagebreak C(10), ;
              cProgNoNet  C(10), ;
              lclosed     L, ;
              cWellType   C(30), ;
              cownerid    C(10), ;
              cownname    C(60), ;
              cOwnname1   C(60), ;
              caddress1   C(60), ;
              caddress2   C(60), ;
              ccityState  C(30), ;
              caddr1      C(60), ;
              caddr2      C(60), ;
              caddr3      C(60), ;
              cphoneno    C(15), ;
              cfaxno      C(15), ;
              czipcode    C(10), ;
              dAcctDate   D, ;
              cyear       C(4), ;
              cperiod     C(2), ;
              ntotalcheck N(12, 2), ;
              nTotalBal   N(12, 2), ;
              cprogcode   C(10), ;
              cProgName   C(60), ;
              cDeck       C(10), ;
              cwellid     C(10), ;
              cwellname   C(50), ;
              ccounty     C(40), ;
              cstate      C(2), ;
              crange      C(11), ;
              ndayson     N(3), ;
              cTYPE       C(5), ;
              csource     C(60), ;
              nunits      N(12, 4), ;
              nprice      N(12, 6), ;
              nTOTAL      N(12, 2), ;
              ninvamt     N(12, 2), ;
              nRevInt     N(11, 7), ;
              nRoyInt     N(11, 7), ;
              nTotNet     N(12, 2), ;
              nWellNet    N(12, 2), ;
              nWorkTot    N(12, 2), ;
              dExpDate    D, ;
              ccatcode    C(4), ;
              cCategory   C(60), ;
              ctaxcode    C(2), ;
              ctaxdesc    C(50), ;
              cpayee      C(50), ;
              nAmount     N(12, 2), ;
              nworkint    N(11, 7), ;
              cTypeInv    C(1), ;
              ctypeint    C(1), ;
              cdirect     C(1), ;
              nflatrate   N(7, 2), ;
              lFlat       L, ;
              lused       L, ;
              lwellpage   L, ;
              lDirect     L, ;
              lusesev     L, ;
              cMethod     C(1), ;
              cTaxable    N(12, 2), ;
              lHold       L, ;
              lOnHold     L, ;
              lExpDate    L, ;
              ninvmin     N(12, 2), ;
              nintclass1  N(11, 7), ;
              nintclass2  N(11, 7), ;
              nintclass3  N(11, 7), ;
              nintclass4  N(11, 7), ;
              nintclass5  N(11, 7), ;
              cMiscMemo   C(60), ;
              ljib        L, ;
              glStminv    L, ;
              glExpDate   L, ;
              cprodprd    C(7), ;
              cDescript   M, ;
              crunyear    C(4), ;
              nRunNo      I, ;
              lcloserun   L, ;
              lSuspense   L, ;
              lpriorsusp  L, ;
              lSummary    L, ;
              nRunNo_In   I, ;
              cRunYear_In C(4), ;
              cSuspType   C (1), ;
              cbalancedesc C(60), ;
              pcbreak      C(25), ;
              lownerposted L, ;
              nOilSummary N(12, 2), ;
              nGasSummary N(12, 2), ;
              nOthSummary N(12, 2), ;
              nDedSummary N(12, 2), ;
              nTaxSummary N(12, 2), ;
              nExpSummary N(12, 2), ;
              nNetSummary N(12, 2))

         *
         *  Get the Accounting Month
         *
         lcAcctPrd = PADL(ALLTRIM(STR(MONTH(THIS.dAcctDate), 2)), 2, '0')

         IF tlSelected
            SET SAFETY OFF
            SELECT invtmp
            DELETE FROM invtmp WHERE cownerid NOT IN (SELECT cid FROM SELECTED)
         ELSE
            DELETE FROM invtmp WHERE NOT BETWEEN(cownerid, THIS.cowner1, THIS.cowner2)
         ENDIF

         IF USED('invtmpx')
            USE IN invtmpx
         ENDIF
         IF USED('owntmp')
            USE IN owntmp
         ENDIF
         IF USED('tmpsusp')
            USE IN tmpsusp
         ENDIF
         IF USED('invtotx')
            USE IN invtotX
         ENDIF
         *
         * Remove payments that have the same runno_in as runno
         *
         SELECT invtmp
         DELETE  FOR crectype = 'P' AND (invtmp.nRunNo_In = invtmp.nRunNo ;
                     AND invtmp.cRunYear_In = invtmp.crunyear) ;


         *  Total investor's wells to get check nAmounts
         *
         CREATE CURSOR invtotal ;
            (cownerid     C(10), ;
              hdate        D, ;
              lDirectDep   L, ;
              lSuspense    L, ;
              ntotalcheck  N(12, 2))
         INDEX ON cownerid TAG owner

         SELECT  cownerid, ;
                 hdate, ;
                 lDirectDep, ;
                 SUM(ROUND(nnetcheck, 2)) AS ntotalcheck ;
             FROM invtmp ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND nRunNo = THIS.nRunNo ;
                 AND crunyear = THIS.crunyear ;
                 AND cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') # crunyear + PADL(TRANSFORM(nRunNo), 3, '0') ;
                 AND INLIST(crectype, 'R', 'P') ;
             INTO CURSOR invtotX ;
             GROUP BY cownerid ;
             ORDER BY cownerid

         SELECT invtotal
         APPEND FROM DBF('invtotx')
         SELECT invtotX
         USE

         * Get the owners that went into suspense totally for this run.
         SELECT  cownerid, ;
                 hdate, ;
                 SUM(ROUND(nnetcheck, 2)) AS ntotalcheck, ;
                 .F. AS lDirectDep, ;
                 .F. AS lSuspense ;
             FROM suspense WITH (BUFFERING = .T.) ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND suspense.nRunNo_In == THIS.nRunNo ;
                 AND suspense.cRunYear_In == THIS.crunyear ;
                 AND cownerid NOT IN (SELECT  cownerid ;
                                          FROM invtotal ;
                                          WHERE ntotalcheck # 0) ;
                 AND crectype = 'R' ;
             INTO CURSOR invtotX ;
             GROUP BY cownerid ;
             ORDER BY cownerid

         IF _TALLY > 0
            SELECT cownerid FROM invtotal INTO CURSOR tempown ORDER BY cownerid GROUP BY cownerid

            SELECT invtotX
            SCAN
               SCATTER MEMVAR
               SELECT invtotal
               LOCATE FOR cownerid == m.cownerid
               IF FOUND()
                  IF ntotalcheck = 0
                     REPLACE ntotalcheck WITH m.ntotalcheck
                  ENDIF
               ELSE
                  INSERT INTO invtotal FROM MEMVAR
               ENDIF
            ENDSCAN
            SELECT invtotX
            USE
         ENDIF

         SELECT  suspense.*, ;
                 .F. AS lDirectDep, ;
                 .T. AS lSuspense ;
             FROM suspense ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND suspense.nRunNo_In == THIS.nRunNo ;
                 AND suspense.cRunYear_In == THIS.crunyear ;
                 AND suspense.crectype = 'R' ;
             INTO CURSOR invtmpx

         SELECT invtmpx
         SCAN
            SCATTER MEMVAR
            THIS.osuspense.GetWellHist(m.cwellid, m.hyear, m.hperiod)
            SELECT invtmp
            LOCATE FOR cwellid = m.cwellid AND cownerid == m.cownerid AND cTypeInv = m.cTypeInv AND hyear + hperiod = m.hyear + m.hperiod AND nnetcheck = m.nnetcheck
            IF NOT FOUND()
               INSERT INTO invtmp FROM MEMVAR
            ENDIF
         ENDSCAN
         USE IN invtmpx

         * Get the owners that went into suspense for this run.
         SELECT  cownerid, ;
                 hdate, ;
                 SUM(ROUND(nnetcheck, 2)) AS ntotalcheck, ;
                 .F. AS lDirectDep, ;
                 .T. AS lSuspense ;
             FROM disbhist ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND disbhist.nRunNo_In == THIS.nRunNo ;
                 AND disbhist.cRunYear_In == THIS.crunyear ;
                 AND INLIST(crectype, 'R', 'P') ;
             INTO CURSOR invtotX ;
             GROUP BY cownerid ;
             ORDER BY cownerid

         TRY
            IF _TALLY > 0
               SCAN
                  SCATTER MEMVAR
                  SELECT invtotal
                  LOCATE FOR cownerid == m.cownerid
                  IF NOT FOUND()
                     INSERT INTO invtotal FROM MEMVAR
                  ENDIF
               ENDSCAN
               SELECT invtotX
               USE

               * Get the owner history record to copy to invtmp
               SELECT  disbhist.*, ;
                       ownpcts.*, ;
                       .T. AS lSuspense ;
                   FROM disbhist, ownpcts ;
                   WHERE cownerid IN (SELECT  cid ;
                                          FROM SELECTED) ;
                       AND crectype # 'P' ;
                       AND disbhist.nRunNo_In == THIS.nRunNo ;
                       AND disbhist.cRunYear_In == THIS.crunyear ;
                       AND disbhist.ciddisb == ownpcts.ciddisb ;
                   INTO CURSOR invtmpx

               IF USED('invtmpx')
                  SELECT invtmpx
                  SCAN
                     SCATTER MEMVAR
                     SELECT invtmp
                     LOCATE FOR cwellid = m.cwellid ;
                        AND cownerid == m.cownerid ;
                        AND cTypeInv = m.cTypeInv ;
                        AND hyear + hperiod = m.hyear + m.hperiod ;
                        AND nnetcheck = m.nnetcheck
                     IF NOT FOUND()
                        INSERT INTO invtmp FROM MEMVAR
                     ENDIF
                  ENDSCAN
                  USE IN invtmpx
               ENDIF
            ENDIF
         CATCH
         ENDTRY

         * Make sure all pmt records are owner type "W"
         SELECT invtmp
         SCAN FOR crectype = 'P' AND EMPTY(cTypeInv)
            REPLACE cTypeInv WITH 'W'
         ENDSCAN

         * Check to see if prior suspense is in invtmp and it includes payments that zero it out
         * If any are found, remove them because we don't want to report on them here.
         llSuspenseZero = .F.
         SELECT  *, ;
                 .F. AS junk ;
             FROM invtmp ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND crectype # 'P' ;
                 AND NOT EMPTY(cRunYear_In) ;
                 AND (crunyear + PADL(TRANSFORM(nRunNo), 3, '0') # cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0')) ;
             INTO CURSOR tempinvtmp READWRITE
         SELECT  *, ;
                 .F. AS junk ;
             FROM IIF(THIS.lNewRun, 'invtmp', 'disbhist') ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND crunyear + PADL(TRANSFORM(nRunNo), 3, '0') = THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0') ;
                 AND crectype = 'P' ;
             INTO CURSOR tmptmp

         SELECT tempinvtmp
         APPEND FROM DBF('tmptmp')
         USE IN tmptmp
         SELECT tempinvtmp
         IF RECCOUNT() > 0
            SELECT cownerid, SUM(nnetcheck) AS nnetcheck FROM tempinvtmp WHERE nRunNo_In # 0 INTO CURSOR temp ORDER BY cownerid GROUP BY cownerid
            SCAN FOR nnetcheck = 0
               m.cownerid = cownerid
               * Set the flag that tells later processing that suspense was zeroed out
               * so it doesn't try to report a suspense balance.by cownerid
               llSuspenseZero = .T.
               SELECT invtmp
               DELETE FOR cownerid == m.cownerid AND nRunNo_In # 0 AND cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') < THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')
            ENDSCAN
         ENDIF

         * Delete payments where nrunno_in = 0
         SELECT invtmp
         DELETE FOR crectype = 'P' AND (nRunNo_In = 0 OR (crunyear = cRunYear_In AND nRunNo = nRunNo_In))

         *
         *  Build the statemnt file
         *
         SELECT invtmp
         COUNT FOR NOT DELETED() TO lnCount

         IF lnCount <= 0
            ON KEY LABEL esc
            llReturn = .F.
            EXIT
         ENDIF

         * Clear up temporary cursors from previous statements
         IF USED('name')
            USE IN NAME
         ENDIF

         * Check to see if we're processing a new or closed run

         THIS.lclosed = (NOT THIS.nRunNo = 0)

         *  Remove owner types not being reported
         THIS.pulltype()

         *  Build a cursor for storing owner statement notes
         CREATE CURSOR ownnotes ;
            (cownerid  C(10), ;
              cwellid   C(10), ;
              mNotes    M)

         *
         *  Initialize memory variables
         *
         STORE ' ' TO m.crptgoup, m.cownerid, m.cownname, m.caddr1, m.caddr2, m.ccitycstate, ;
            M.cyear, m.cperiod, m.coilprd1, m.coilprd2, m.cgasprd1, m.cgasprd2, m.cphoneno, ;
            M.cwellid, m.cwellname, m.csource, m.cCategory, m.cpayee, m.cTypeInv, m.cfaxno, ;
            M.ctypeint, m.cMiscMemo, m.cDescript, lcoldprog, lcoldprogname, lcperiod1, lcperiod2
         STORE 0   TO m.ntotalcheck, m.nunits, m.nprice, m.ninvamt, m.nRevInt, ;
            M.nWorkTot, m.nlandpct, m.noverpct, m.nAmount, m.nworkint, THIS.nownertotal, ;
            M.nintclass1, m.nintclass2, m.nintclass3, m.nintclass4, m.nintclass5
         STORE 0 TO lnowncount, THIS.nwelltot, THIS.ntotinc, lnperiodbal

         m.crunyear = THIS.crunyear

         STORE .F. TO THIS.lexemptroyalty, m.lDirOilPurch, m.lDirGasPurch, m.ljib

         * Create cursor to hold program totals
         CREATE CURSOR progtots ;
            (cownerid   C(10), ;
              cprogcode  C(10), ;
              nprogtot   N(12, 2))

         *
         *  Remove owners getting checks if not included
         *

         IF THIS.lIncludeChecks = .F.
            * Delete all owners getting a check
            SELECT  cid AS cownerid ;
                FROM checks ;
                WHERE cbatch = THIS.cDMBatch ;
                    AND cid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                INTO CURSOR tempchks ;
                ORDER BY cid
            SELE invtmp
            SCAN FOR NOT lDirectDep
               m.cownerid = cownerid
               SELE tempchks
               LOCATE FOR cownerid == m.cownerid
               IF FOUND()
                  SELE invtmp
                  DELE NEXT 1
               ENDIF
            ENDSCAN
            SELE invtotal
            SCAN FOR NOT lDirectDep
               m.cownerid = cownerid
               SELE tempchks
               LOCATE FOR cownerid == m.cownerid
               IF FOUND()
                  SELE invtotal
                  DELE NEXT 1
               ENDIF
            ENDSCAN
            USE IN tempchks
         ENDIF

         *
         *  Remove direct deposit owners if not included
         *
         IF THIS.lDirDeposit = .F.
            * Delete all direct deposit owners
            SELECT  cownerid ;
                FROM invtmp ;
                WHERE cownerid IN (SELECT  cid ;
                                       FROM SELECTED) ;
                    AND lDirectDep ;
                INTO CURSOR tempchks ;
                ORDER BY cownerid
            SELE tempchks
            SCAN
               m.cownerid = cownerid
               SELE invtmp
               SCAN FOR cownerid == m.cownerid
                  SELE invtmp
                  DELE NEXT 1
               ENDSCAN

               SELE invtotal
               SCAN FOR cownerid == m.cownerid
                  SELE invtotal
                  DELE NEXT 1
               ENDSCAN
            ENDSCAN
            USE IN tempchks
         ENDIF

         swSelect('options')
         GO TOP
         SCATTER NAME THIS.ooptions

         IF NOT FILE('datafiles\compress.txt')
            THIS.ooptions.lHideComp = .F.
            THIS.ooptions.lChgPrice = .F.
         ENDIF

         glStminv       = lstminv
         gnmincheck     = nmincheck
         glhidecomp     = lHideComp
         glshowroy      = lshowroy
         glacctdesc     = lacctdesc
         glrefid        = lrefid
         glexpsum       = lexpsum
         glRevSum       = lRevSum
         glchgprice     = lChgPrice
         gngather       = ngather
         gncompress     = ncompress
         gldirinv       = ldirinv
         llroycomp      = lroycomp
         llbilldesc     = lbilldesc
         llshowvendor   = lshowvendor
         m.lExpDate     = lExpDate
         m.glExpDate    = lExpDate
         m.lNoFirstName = lNoFirstName

         swSelect('sysctl')
         LOCATE FOR crunyear == THIS.crunyear AND nRunNo == THIS.nRunNo AND ctypeclose = 'R' AND ldisbman
         IF FOUND()
            THIS.lSumExp  = lSumExp
            THIS.lSumRev  = lSumRev
            THIS.dRevDate = dRevDate
            THIS.dExpDate = dExpDate
         ELSE
            THIS.lSumExp  = glexpsum
            THIS.lSumRev  = glRevSum
            THIS.dRevDate = THIS.dAcctDate
            THIS.dExpDate = THIS.dAcctDate
         ENDIF

         * Get the rounding amounts for the runs showing on this statement.  This includes suspense
         SELECT  sysctl.cDMBatch, ;
                 invtmp.cwellid, ;
                 invtmp.nRunNo_In, ;
                 invtmp.cRunYear_In ;
             FROM sysctl, invtmp ;
             WHERE (sysctl.nRunNo = invtmp.nRunNo_In ;
                   AND sysctl.crunyear = invtmp.cRunYear_In) ;
                 AND NOT EMPTY(invtmp.cSuspType) ;
             INTO CURSOR tempdmbatch READWRITE ;
             ORDER BY cDMBatch, cwellid ;
             GROUP BY cDMBatch, cwellid

         SELECT cwellid FROM invtmp INTO CURSOR tmpwells ORDER BY cwellid GROUP BY cwellid
         SELECT tmpwells
         SCAN
            SCATTER MEMVAR
            SELECT tempdmbatch
            LOCATE FOR cDMBatch = THIS.cDMBatch AND cwellid == m.cwellid
            IF NOT FOUND()
               m.cDMBatch = THIS.cDMBatch
               INSERT INTO tempdmbatch FROM MEMVAR
            ENDIF
         ENDSCAN

         * Combine rounding amounts to one record per owner/well combination
         * so we don't show multiple rounding entries when multiple production
         * periods are processed.

         swclose('roundsum')
         SELECT  cownerid, ;
                 cwellid, ;
                 cDMBatch, ;
                 SUM(roundtmp.ngasrev + roundtmp.noilrev + roundtmp.ntrprev + ;
                     roundtmp.nmiscrev1 + roundtmp.nmiscrev2 + roundtmp.nothrev) AS nrevenue, ;
                 SUM((roundtmp.nexpense + roundtmp.ntotale1 + roundtmp.ntotale2 + ;
                       roundtmp.ntotale3 + roundtmp.ntotale4 + roundtmp.ntotale5 + ;
                       roundtmp.nTotaleA + roundtmp.nTotaleB + roundtmp.nmktgexp) - ;
                     (roundtmp.nothtax1 + roundtmp.nothtax2 + roundtmp.nothtax3 + ;
                       roundtmp.nothtax4 + roundtmp.noiltax1 + roundtmp.noiltax2 + ;
                       roundtmp.noiltax3 + roundtmp.noiltax4 + roundtmp.ngastax1 + ;
                       roundtmp.ngastax2 + roundtmp.ngastax3 + roundtmp.ngastax4) - ;
                     (roundtmp.ncompress + roundtmp.ngather + roundtmp.nPlugExp)) AS nexpenses, ;
                 SUM((roundtmp.ngasrev + roundtmp.noilrev + roundtmp.ntrprev + ;
                       roundtmp.nmiscrev1 + roundtmp.nmiscrev2 + roundtmp.nothrev) - ;
                     (roundtmp.nexpense + roundtmp.ntotale1 + roundtmp.ntotale2 + ;
                       roundtmp.ntotale3 + roundtmp.ntotale4 + roundtmp.ntotale5 + ;
                       roundtmp.nTotaleA + roundtmp.nTotaleB + roundtmp.nmktgexp) - ;
                     (roundtmp.nothtax1 + roundtmp.nothtax2 + roundtmp.nothtax3 + ;
                       roundtmp.nothtax4 + roundtmp.noiltax1 + roundtmp.noiltax2 + ;
                       roundtmp.noiltax3 + roundtmp.noiltax4 + roundtmp.ngastax1 + ;
                       roundtmp.ngastax2 + roundtmp.ngastax3 + roundtmp.ngastax4) - ;
                     (roundtmp.ncompress + roundtmp.ngather + roundtmp.nPlugExp)) AS nWellNet, ;
                 .F. AS lused ;
             FROM roundtmp ;
             WHERE cDMBatch + cwellid IN (SELECT  cDMBatch + cwellid ;
                                              FROM tempdmbatch) ;
             INTO CURSOR roundsum READWRITE ;
             ORDER BY cownerid, cwellid ;
             GROUP BY cownerid, cwellid

         **-
         **-  Get producer's address information
         **-
         **- Check on the existence of the application object
         **- if it doesn't exist, we're running in development
         **- mode and need to initialize the company address info.
         IF TYPE('m.goApp') = 'O'
            m.caddr1   = m.goApp.caddress1
            m.caddr2   = m.goApp.caddress2
            m.caddr3   = m.goApp.caddress3
            m.ctax     = m.goApp.ctaxid
            m.cphoneno = m.goApp.cphoneno
            m.cfaxno   = m.goApp.cfaxno
            IF EMPTY(m.goApp.ccompanyname) OR ALLT(m.goApp.ccompanyname) = "''"
               m.goApp.ccompanyname = 'Sherwood Energy'

               IF EMPTY(m.caddr1) OR ALLT(m.caddr1) = "''"
                  m.caddr1 = 'PO Box 209'
               ENDIF
               IF EMPTY(m.caddr2) OR ALLT(m.caddr2) = "''"
                  m.caddr2 = 'Apple Creek, OH 44606'
               ENDIF
               IF EMPTY(m.caddr3) OR ALLT(m.caddr3) = "''"
                  m.caddr3 = ''
               ENDIF
            ENDIF
         ELSE
            m.caddr1 = 'PO Box 223'
            m.caddr2 = 'Wooster, OH  44691'
            m.caddr3 = ''
            m.ctax   = '99-9999999'
         ENDIF


         *  Get the total invtmp records we're going to process so the progress bar updates correctly.
         SELECT invtmp
         lnCount = 1
         IF NOT THIS.lNoSuspDet
            COUNT FOR BETWEEN(cownerid, THIS.cowner1, THIS.cowner2) TO lnMax
         ELSE
            COUNT FOR BETWEEN(cownerid, THIS.cowner1, THIS.cowner2) ;
               AND IIF(NOT EMPTY(cSuspType), ;
                 PADL(TRANSFORM(nRunNo_In), 3, '0') + cRunYear_In = PADL(TRANSFORM(THIS.nRunNo), 3, '0') + ;
                 THIS.crunyear, .T.) TO lnMax
         ENDIF
         IF lnMax = 0
            llReturn = .F.
            EXIT
         ENDIF
         GO TOP

         lnMax = lnMax + 60

         *  Add back exempt owners taxes
         THIS.odist.Taxexempt(.T.)

         IF NOT THIS.lPartnerPost
            THIS.oProgress = THIS.omessage.ProgressBarEX('Building Owner Statements')
         ELSE
            THIS.oProgress = THIS.omessage.ProgressBarEX('Building JV Posting Entries')
         ENDIF

         THIS.oProgress.SetProgressRange(0, lnMax)

         *
         *  Reset the one-man-item flag in the Income file.  (<><><><> Check this. It could potentially be really slow <><><> - pws 10/12/17)
         *
         swSelect('income')
         REPLACE loneman WITH .F. FOR loneman = .T.

         *  Remove owner history records with no production if we're not reporting non producing wells.
         IF THIS.lnoprod = .F.
            SELE invtmp
            SCAN
               IF invtmp.nincome = 0 AND ;
                     (invtmp.nexpense + invtmp.ntotale1 + invtmp.ntotale2 + ;
                       invtmp.ntotale3 + invtmp.ntotale4 + invtmp.ntotale5 + ;
                       invtmp.nTotaleA + invtmp.nTotaleB + invtmp.nPlugExp) = 0 ;
                     AND invtmp.nsevtaxes = 0 AND invtmp.nnetcheck = 0
                  SELE stmtnote
                  LOCATE FOR cwellid == invtmp.cwellid AND nRunNo == invtmp.nRunNo AND crunyear == invtmp.crunyear
                  IF FOUND()
                     DO CASE
                        CASE stmtnote.nnotetype = 1
                           IF invtmp.cTypeInv = 'L'
                              LOOP
                           ENDIF
                        CASE stmtnote.nnotetype = 2
                           IF invtmp.cTypeInv = 'O'
                              LOOP
                           ENDIF
                        CASE stmtnote.nnotetype = 3
                           IF invtmp.cTypeInv = 'O' OR invtmp.cTypeInv = 'L'
                              LOOP
                           ENDIF
                        CASE stmtnote.nnotetype = 4
                           IF invtmp.cTypeInv = 'W'
                              LOOP
                           ENDIF
                        CASE stmtnote.nnotetype = 5
                           LOOP
                     ENDCASE
                  ENDIF
                  IF NOT THIS.checkincexp(invtmp.cwellid, invtmp.hyear, invtmp.hperiod, invtmp.nRunNo, invtmp.crunyear)
                     SELECT invtmp
                     DELE NEXT 1
                  ENDIF
               ENDIF
            ENDSCAN
         ELSE
            SELECT  cownerid, ;
                    cwellid ;
                FROM invtmp ;
                INTO CURSOR temp1 ;
                ORDER BY cownerid, cwellid ;
                GROUP BY cownerid, cwellid

            swSelect('wellinv')
            SCAN
               SELECT SELECTED
               LOCATE FOR cid = wellinv.cownerid
               IF NOT FOUND()
                  LOOP
               ENDIF
               SELECT temp1
               LOCATE FOR cownerid == wellinv.cownerid AND cwellid == wellinv.cwellid
               IF NOT FOUND()
                  SELECT invtmp
                  SCATTER MEMVAR BLANK
                  swSelect('wells')
                  LOCATE FOR cwellid == wellinv.cwellid
                  IF FOUND() AND cGROUP = THIS.cGROUP
                     swSelect('wellinv')
                     SCATTER MEMVAR
                     m.nRunNo   = THIS.nRunNo
                     m.crunyear = THIS.crunyear
                     INSERT INTO invtmp FROM MEMVAR
                  ENDIF
               ENDIF
            ENDSCAN
         ENDIF

         * Get unique owner, well and owner types
         SELECT  cownerid, ;
                 cwellid, ;
                 cTypeInv, ;
                 .F. AS lwellpage ;
             FROM invtmp ;
             WHERE NOT EMPTY(cTypeInv) ;
             INTO CURSOR owntypes ;
             ORDER BY cownerid, cwellid, cTypeInv ;
             GROUP BY cownerid, cwellid, cTypeInv

         * Start building a statement for each owner
         SELECT invtotal
         SCAN
            IF m.goApp.lcanceled
               llReturn          = .F.
               IF NOT m.goApp.CancelMsg()
                  THIS.lcanceled = .T.
                  EXIT
               ENDIF
            ENDIF

            * Reset the rounding flag
            THIS.lrounding = .F.
            SCATTER MEMVAR

            * Get the direct deposit flag for the owner
            llDirDep = m.lDirectDep

            * Reset expense used flag if new owner
            IF USED('exptemp')
               SELECT exptemp
               REPLACE lused WITH .F. ALL
            ENDIF

            * Set a flag that we're working with a different owner than before
            llnewowner = .T.

            * Save the current owner since we have to check for one-man items
            THIS.cownerid = m.cownerid
            STORE ' ' TO THIS.ownergroup
            STORE 0 TO THIS.nownertotal

            jTotal         = m.ntotalcheck

            m.nTotalBal    = m.ntotalcheck
            THIS.cSuspType = ''

            SELECT invtotal
            m.dAcctDate = THIS.dAcctDate
            m.crptgroup = 'A'
            m.cyear     = THIS.crunyear
            m.cownerid  = THIS.cownerid
            swSelect('investor')
            SET ORDER TO cownerid
            IF SEEK(THIS.cownerid)
               *
               *  Check to see if this investors deficit cStatement should be printed
               *
               SCATTER MEMVAR

               * Get the owner's minimum check amount
               THIS.nownermin = ninvmin

               * This owner posts to G/L instead of getting a check
               THIS.lownerposted = lIntegGL
               m.lownerposted    = lIntegGL

               m.lwellpage = lwellpage

               * Skip out on processing direct deposits if the
               * option isn't chosen.
               IF NOT llIncludeDirDep AND investor.lDirectDep
                  LOOP
               ENDIF

               * Setup for page breaks
               IF m.lwellpage
                  m.pcbreak = 'cwellid'
               ELSE
                  m.pcbreak = '" " '
               ENDIF

               * Check to see if this owner should get a detail stmt
               IF THIS.ldetail
                  IF investor.nstmttype # 0 AND ;
                        investor.nstmttype # 1
                     LOOP
                  ENDIF
               ENDIF

               * Only process owners whose statements are to be emailed.
               IF THIS.lEmailOnly
                  IF investor.nstmttype # 3
                     LOOP
                  ENDIF
               ENDIF

               THIS.lownertaxexempt = lExempt
               m.lHold              = .T.
               m.lOnHold            = .T.

               m.ninvmin = 999999
               SELECT invtmp
               SCAN FOR cownerid == THIS.cownerid AND ;
                     ((nRunNo == THIS.nNewRunNo AND crunyear == THIS.crunyear) OR (nRunNo_In == THIS.nNewRunNo AND cRunYear_In == THIS.crunyear))

                  * pws - 2009/02/06  Added the check for nrunno_in to make sure if the owner is no longer
                  *                   held, the statement will still print.
                  IF invtmp.cSuspType = 'H' AND invtmp.nRunNo_In = THIS.nNewRunNo AND cRunYear_In == THIS.crunyear
                     REPLACE lHold WITH .T.
                  ELSE
                     REPLACE lHold WITH .F.
                     m.lHold = .F.
                  ENDIF

                  IF invtmp.cSuspType # 'M'
                     m.ninvmin = THIS.nownermin
                  ENDIF

                  IF invtmp.cSuspType = 'I'
                     REPLACE lOnHold WITH .T.
                  ENDIF

                  m.lOnHold = m.lOnHold AND lOnHold

               ENDSCAN

               * This owner is on hold
               IF m.lHold
                  THIS.cSuspType = 'H'
               ENDIF

               * All the owner's interests are on hold
               IF m.lOnHold
                  THIS.cSuspType = 'I'
               ENDIF

               THIS.lowneronhold    = m.lHold

               IF NOT THIS.lPartnerPost
                  THIS.oProgress.SetProgressMessage('Building Statement for ' + csortfield)
               ELSE
                  THIS.oProgress.SetProgressMessage('Building Posting for ' + csortfield)
               ENDIF
               IF investor.lprtdef = .F. AND m.ntotalcheck < 0
                  SELECT invtotal
                  LOOP
               ENDIF

               *
               *  Don't print dummy owner cStatements
               *
               IF investor.lDummy
                  LOOP
               ENDIF

               IF THIS.lclosed
                  IF THIS.odist.lRelmin
                     THIS.lallminsreleased = .T.
                     m.ninvmin             = 0
                  ELSE
                     IF m.ninvmin = 0
                        m.ninvmin = gnmincheck
                     ENDIF
                  ENDIF
               ELSE
                  IF m.ninvmin = 0
                     m.ninvmin = THIS.ooptions.nmincheck
                  ENDIF
               ENDIF

               STORE 0 TO THIS.nbackupwith, THIS.ntaxwith

               **-
               **-  Setup the minimum check nAmount so that the Statement can
               **-  notify the owner if the net Amount is below the minimum.
               **-
               DO CASE
                  CASE THIS.lowneronhold        && Owner on hold - set minimum to max so owner stays on hold
                     m.ninvmin = 99999999
                  CASE THIS.lallminsreleased    && Releasing minimums - set minimum amount to zero
                     m.ninvmin = 0
                  CASE m.ndisbfreq = 2          && Quarterly owner - set minimum to max if not at the end of qtr
                     IF NOT INLIST(lcAcctPrd, '03', '06', '09', '12')
                        m.ninvmin = 99999999
                     ENDIF
                  CASE m.ndisbfreq = 3          && SemiAnnually owner - set minimum to max if not at middle or end of year
                     IF NOT INLIST(lcAcctPrd, '06', '12')
                        m.ninvmin = 99999999
                     ENDIF
                  CASE m.ndisbfreq = 4          && Annual owner - set minimum to max if not at end of year
                     IF lcAcctPrd # '12'
                        m.ninvmin = 99999999
                     ENDIF
               ENDCASE

               THIS.nownermin = m.ninvmin

               IF m.ntotalcheck < m.ninvmin AND m.ntotalcheck >= 0
                  THIS.cSuspType = 'M'
               ENDIF

               **-
               **-  If the statment should be sent to the secondary address
               **-  pull in the secondary address, otherwise pull in the
               **-  primary address.
               **-
               IF m.lchktosec AND NOT m.lcheckonly
                  m.cownname  = m.cownname
                  m.cOwnname1 = m.cownname2
                  IF m.lNoFirstName &&  Don't use the primary  name with a secondary address
                     m.cownname  = m.cownname2
                     m.cOwnname1 = ''
                  ENDIF
                  m.caddress1 = m.caddress2a
                  IF NOT EMPTY(m.caddress2b)
                     m.caddress2  = m.caddress2b
                     m.ccityState = ALLTRIM(m.ccity2) + ' ' + m.cstate2 + '  ' + m.czip2
                     m.czipcode   = m.czip2
                  ELSE
                     m.caddress2  = ALLTRIM(m.ccity2) + ' ' + m.cstate2 + '  ' + m.czip2
                     m.ccityState = ' '
                     m.czipcode   = m.czip2
                  ENDIF
               ELSE
                  IF NOT EMPTY(m.caddress1a)
                     m.caddress1 = m.caddress1a
                     IF NOT EMPTY(m.caddress1b)
                        m.caddress2  = m.caddress1b
                        m.ccityState = ALLTRIM(m.ccity1) + ' ' + m.cstate1 + '  ' + m.czip1
                        m.czipcode   = m.czip1
                     ELSE
                        m.caddress2  = ALLTRIM(m.ccity1) + ' ' + m.cstate1 + '  ' + m.czip1
                        m.ccityState = ''
                        m.czipcode   = m.czip1
                     ENDIF
                  ELSE
                     IF NOT EMPTY(m.caddress1b)
                        m.caddress1  = m.caddress1b
                        m.caddress2  = ALLTRIM(m.ccity1) + ' ' + m.cstate1 + '  ' + m.czip1
                        m.ccityState = ''
                        m.czipcode   = m.czip1
                     ELSE  &&  Blank out address for people with no address, so it doesn't just carry forward the same address from the last owner who had an address filled in
                        m.caddress1  = ''
                        m.caddress2  = ''
                        m.ccityState = ''
                        m.czipcode   = m.czip1
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF

            llWellProd = .F.

            * Build a cursor of totals for the owner and well
            SELE SUM(ngrossgas + ngrossoil) AS nbal FROM wellwork ;
               INTO CURSOR tempgross ORDER BY cwellid GROUP BY cwellid

            *  Start scan of owner types.  We need to scan through wellwork for each owner type record so
            *  that if an owner has more than one interest in the well, we'll process for each interest.
            SELE owntypes
            SCAN FOR cownerid = THIS.cownerid

               lcTypeOwner  = owntypes.cTypeInv
               THIS.cwellid = owntypes.cwellid
               swSelect('wells')
               IF SEEK(THIS.cwellid)
                  SCATTER MEMVAR
               ENDIF

               IF m.lwellpage
                  m.cpagebreak = THIS.cwellid
               ELSE
                  m.cpagebreak = ''
               ENDIF

               THIS.lflatalloc = .F.
               tnRunNo         = THIS.nRunNo
               tcRunYear       = THIS.crunyear

               * Scan through the temp owner history for each record with the given ownerid,
               * well, owner type and production period
               SELECT invtmp
               SET ORDER TO ownertype
               SCAN FOR cownerid  == THIS.cownerid ;
                     AND cwellid   == THIS.cwellid ;
                     AND cTypeInv == lcTypeOwner

                  IF m.goApp.lcanceled
                     llReturn          = .F.
                     IF NOT m.goApp.CancelMsg()
                        THIS.lcanceled = .T.
                        EXIT
                     ENDIF
                  ENDIF

                  * Remove the suspense record if we're not showing suspense detail
                  IF THIS.lNoSuspDet ;
                        AND NOT EMPTY(invtmp.cSuspType) ;
                        AND (invtmp.cRunYear_In + PADL(TRANSFORM(invtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0'))
                     LOOP
                  ENDIF

                  *  Update the progress bar
                  THIS.oProgress.UpdateProgress(lnCount)
                  lnCount = lnCount + 1

                  STORE 0 TO m.nTotNet

                  SELECT wellwork
                  LOCATE FOR cwellid == THIS.cwellid AND hyear = invtmp.hyear AND hperiod = invtmp.hperiod AND crectype = 'R'
                  IF FOUND()
                     SCATTER NAME THIS.owellwork
                     m.nRoyalty = nRoyInt
                  ELSE
                     *  We only want to loop if it's a non-manual entry, since those probably won't find a match in wellwork anyway - BH 08/04/2009
                     IF NOT invtmp.lmanual
                        LOOP
                     ENDIF
                  ENDIF

                  SELECT invtmp
                  llnoprod      = .F.
                  m.nRunNo_In   = nRunNo_In
                  m.cRunYear_In = cRunYear_In
                  m.nflatrate   = nflatrate
                  m.lFlat       = lFlat

                  IF THIS.lnoprod = .T.
                     SELE tempgross
                     LOCATE FOR cwellid = THIS.cwellid
                     IF nbal # 0
                        llWellProd = .T.
                        IF THIS.ownergroup # ' '   && If this isn't the 1st time through for this owner
                           IF invtmp.nincome = 0 AND ;
                                 (invtmp.nexpense + invtmp.ntotale1 + invtmp.ntotale2 + ;
                                   invtmp.ntotale3 + invtmp.ntotale4 + invtmp.ntotale5 + ;
                                   invtmp.nTotaleA + invtmp.nTotaleB + invtmp.nPlugExp) = 0 ;
                                 AND invtmp.nsevtaxes = 0 AND invtmp.nnetcheck = 0 AND invtmp.nmktgexp = 0
                              *  Don't process invtmp records for periods with no activity if we have
                              *  invtmp records for the same well with activity.  This prevents multple
                              *  "A" rptgroup records in statemnt
                              LOOP     && Loop back to invtmp scan
                           ENDIF
                        ENDIF
                     ELSE
                        llWellProd = .F.
                     ENDIF
                  ENDIF

                  *  Set the flag that tells whether we have production this period or not.
                  IF invtmp.nincome = 0 AND ;
                        (invtmp.nexpense + invtmp.ntotale1 + invtmp.ntotale2 + ;
                          invtmp.ntotale3 + invtmp.ntotale4 + invtmp.ntotale5 + ;
                          invtmp.nTotaleA + invtmp.nTotaleB + invtmp.nPlugExp) = 0 ;
                        AND invtmp.nsevtaxes = 0 AND invtmp.nnetcheck = 0 AND invtmp.nmktgexp = 0
                     IF THIS.checkincexp(invtmp.cwellid, invtmp.hyear, invtmp.hperiod, THIS.nRunNo, THIS.crunyear)
                        llnoprod   = .F.
                        llWellProd = .T.
                     ELSE
                        llnoprod   = .T.
                        llWellProd = .F.
                     ENDIF
                  ELSE
                     llnoprod   = .F.
                     llWellProd = .T.
                  ENDIF

                  SELE invtmp
                  IF EMPTY(cTypeInv)
                     REPLACE cTypeInv WITH 'B'
                  ENDIF

                  *  Process net well totals when not splitting prod prds into their own section
                  THIS.NetWellTotalNoSplit()

                  *  Continue scan through invtmp
                  SELE invtmp
                  * Create the oInvTmp object so other methods have access to this record
                  SCATTER NAME THIS.oinvtmp
                  m.cSuspType = invtmp.cSuspType

                  THIS.cyear   = THIS.oinvtmp.hyear
                  THIS.cperiod = THIS.oinvtmp.hperiod

                  IF THIS.lsplitperiods
                     lnowncount = lnowncount + 1
                     m.cWellType = invtmp.cownerid + invtmp.cwellid + ;
                        invtmp.cTypeInv + STR(lnowncount, 1) + invtmp.hyear + invtmp.hperiod
                  ELSE
                     m.cWellType = invtmp.cownerid + invtmp.cwellid + ;
                        invtmp.cTypeInv + STR(lnowncount, 1)
                  ENDIF

                  *
                  *  Determine if investor is a Royalty owner
                  *
                  IF THIS.oinvtmp.cTypeInv = 'L' OR THIS.oinvtmp.cTypeInv = 'O'
                     THIS.lroyaltyowner = .T.
                  ELSE
                     THIS.lroyaltyowner = .F.
                  ENDIF

                  m.crptgroup = 'A'
                  m.cSuspType = ''

                  *  Get the current well's info into memory variables
                  swSelect('wells')
                  SET ORDER TO cwellid
                  SEEK THIS.cwellid
                  IF FOUND()
                     SCATTER MEMVAR
                     m.nRoyInt    = nlandpct + noverpct
                     IF m.ncompress # 0
                        THIS.ncompress = wells.ncompress
                     ELSE
                        THIS.ncompress = THIS.ooptions.ncompress
                     ENDIF
                     IF m.ngather # 0
                        THIS.ngather = wells.ngather
                     ELSE
                        THIS.ngather = THIS.ooptions.ngather
                     ENDIF
                     THIS.lexemptroyalty = lroysevtx
                  ELSE
                     * Not a valid well so loop out...Shouldn't ever get here.
                     LOOP    && Loop back to invtmp scan
                  ENDIF

                  m.cDescript = ' '
                  m.cownerid  = THIS.cownerid

                  ************************************************************************************
                  **** PROCESSING FOR COMBINING PRODUCTION PERIOD TOGETHER UNDER ONE WELL HEADER *****
                  ************************************************************************************
                  IF NOT THIS.lsplitperiods    && Keeping production periods together
                     * If we're including wells with no production and the current well has no production
                     * insert a header record into the statement file.
                     IF THIS.lnoprod = .T. AND NOT llWellProd
                        m.nRunNo    = THIS.nRunNo
                        m.crunyear  = THIS.crunyear
                        m.cprogcode = THIS.oinvtmp.cprogcode
                        swSelect('programs')
                        LOCATE FOR cprogcode = m.cprogcode
                        IF FOUND()
                           m.cProgName = cProgName
                        ELSE
                           m.cProgName = ''
                        ENDIF
                        m.crunyear = THIS.crunyear
                        *********************************************************************************************************
                        *  Insert into the statement file  - Report Group A
                        *********************************************************************************************************
                        INSERT INTO statemnt FROM MEMVAR
                        *********************************************************************************************************
                     ELSE
                        *  Only insert a header record if the well has production at this point or if there are statement notes.
                        IF llWellProd
                           IF THIS.oinvtmp.crectype # 'P'
                              SELE statemnt
                              LOCATE FOR cWellType = m.cWellType AND crptgroup = 'A'
                              IF NOT FOUND()
                                 m.nRunNo    = THIS.nRunNo
                                 m.cprogcode = THIS.oinvtmp.cprogcode
                                 m.crunyear  = THIS.crunyear
                                 *********************************************************************************************************
                                 *  Insert into the statement file  - Report Group A
                                 *********************************************************************************************************
                                 INSERT INTO statemnt FROM MEMVAR
                                 *********************************************************************************************************
                              ENDIF
                           ENDIF
                        ELSE
                           * Check to see if there are statement notes, and if so, insert an A record.
                           swSelect('stmtnote')
                           LOCATE FOR cwellid == THIS.oinvtmp.cwellid AND nRunNo == THIS.oinvtmp.nRunNo AND crunyear == THIS.oinvtmp.crunyear
                           IF FOUND()
                              DO CASE
                                 CASE stmtnote.nnotetype = 1
                                    IF THIS.oinvtmp.cTypeInv # 'L'
                                       LOOP
                                    ENDIF
                                 CASE stmtnote.nnotetype = 2
                                    IF THIS.oinvtmp.cTypeInv # 'O'
                                       LOOP
                                    ENDIF
                                 CASE stmtnote.nnotetype = 3
                                    IF (THIS.oinvtmp.cTypeInv # 'O' AND THIS.oinvtmp.cTypeInv # 'L')
                                       LOOP
                                    ENDIF
                                 CASE stmtnote.nnotetype = 4
                                    IF THIS.oinvtmp.cTypeInv # 'W'
                                       LOOP
                                    ENDIF
                              ENDCASE
                              swSelect('statemnt')
                              LOCATE FOR cWellType = m.cWellType AND crptgroup = 'A'
                              IF NOT FOUND()
                                 m.nRunNo    = THIS.nRunNo
                                 m.cprogcode = THIS.oinvtmp.cprogcode
                                 m.crunyear  = THIS.crunyear
                                 *********************************************************************************************************
                                 *  Insert into the statement file  - Report Group A
                                 *********************************************************************************************************
                                 INSERT INTO statemnt FROM MEMVAR
                                 *********************************************************************************************************
                              ENDIF
                           ENDIF
                        ENDIF
                     ENDIF
                     llwellstmt   = .T.
                  ELSE
                     m.nRunNo    = THIS.nRunNo
                     m.crunyear  = THIS.crunyear
                     m.cprogcode = THIS.oinvtmp.cprogcode
                     m.cWellType = m.cownerid + m.cwellid + m.cTypeInv + '0'
                     *********************************************************************************************************
                     *  Insert into the statement file  - Report Group A
                     *********************************************************************************************************
                     INSERT INTO statemnt FROM MEMVAR
                     *********************************************************************************************************
                     llwellstmt = .T.
                  ENDIF
                  ************************************************************************************
                  **** PROCESSING FOR COMBINING PRODUCTION PERIOD TOGETHER UNDER ONE WELL HEADER *****
                  ************************************************************************************

                  *  If this is a flat rate royalty owner, insert the flat rate into the income section
                  IF invtmp.lFlat AND invtmp.nflatrate # 0
                     m.crptgroup = 'B'
                     IF invtmp.nflatrate = 0
                        *  Flat rate owner but no flat rate amount - loop back to invtmp
                        LOOP
                     ENDIF

                     m.ninvamt        = invtmp.nflatrate
                     THIS.nownertotal = THIS.nownertotal + invtmp.nflatrate
                     m.cDescript      = ' '
                     m.cTYPE          = 'FLT'
                     m.lFlat          = .T.
                     m.csource        = 'Flat-Rate Royalty'
                     m.cyear          = invtmp.hyear
                     m.cperiod        = invtmp.hperiod
                     m.cownerid       = THIS.cownerid
                     m.nRunNo         = THIS.nRunNo
                     m.cprogcode      = THIS.oinvtmp.cprogcode
                     THIS.ntotinc     = THIS.ntotinc + m.ninvamt
                     THIS.nwelltot    = THIS.nwelltot + m.ninvamt
                     m.crunyear       = THIS.crunyear
                     *********************************************************************************************************
                     *  Insert into the statement file  - Report Group B
                     *********************************************************************************************************
                     INSERT INTO statemnt FROM MEMVAR
                     *********************************************************************************************************
                     *
                     *  Look for statement notes for flat rate owners
                     *
                     m.lFlat = .F.
                     THIS.stmtnotes(THIS.nNewRunNo, THIS.crunyear, THIS.cwellid, THIS.oinvtmp.cownerid)
                     LOOP
                  ENDIF

                  IF THIS.oinvtmp.nincome = 0 AND ;
                        (THIS.oinvtmp.nexpense + THIS.oinvtmp.ntotale1 + ;
                          THIS.oinvtmp.ntotale2 + THIS.oinvtmp.ntotale3 + ;
                          THIS.oinvtmp.ntotale4 + THIS.oinvtmp.ntotale5 + ;
                          THIS.oinvtmp.nTotaleA + THIS.oinvtmp.nTotaleB + ;
                          THIS.oinvtmp.nPlugExp) = 0 ;
                        AND THIS.oinvtmp.nsevtaxes = 0 AND THIS.oinvtmp.nnetcheck = 0 AND NOT llWellProd
                     *  Print any statement notes
                     IF NOT THIS.stmtnotes(THIS.nRunNo, THIS.crunyear, THIS.cwellid, THIS.oinvtmp.cownerid)
                        SELECT invtmp
                        lnrecNo = RECNO()
                        LOCATE FOR cownerid = THIS.cownerid AND ;
                           cwellid = THIS.cwellid AND ;
                           (nincome # 0 OR nexpense # 0 OR ;
                             ntotale1 # 0 OR ntotale2 # 0 OR ;
                             ntotale3 # 0 OR ntotale4 # 0 OR ;
                             ntotale5 # 0 OR nTotaleA # 0 OR ;
                             nTotaleB # 0 OR nsevtaxes # 0 OR ;
                             nPlugExp # 0 OR nnetcheck # 0)
                        IF NOT FOUND()
                           * If no notes, print message about no production
                           m.cDescript = 'No Production This Run'
                           m.cTYPE     = 'NOT'
                           m.cownerid  = THIS.cownerid
                           SELE statemnt
                           LOCATE FOR cwellid = THIS.cwellid AND (crptgroup = 'B' OR crptgroup = 'D')
                           IF NOT FOUND()
                              GO BOTT
                              IF crptgroup # 'F' AND cDescript # 'No Production This Run'
                                 m.nRunNo   = THIS.nRunNo
                                 m.crunyear = THIS.crunyear
                                 *********************************************************************************************************
                                 *  Insert into the statement file  - Report Group F
                                 *********************************************************************************************************
                                 INSERT INTO statemnt FROM MEMVAR
                                 *********************************************************************************************************
                              ENDIF
                           ENDIF
                        ENDIF

                     ENDIF
                     IF THIS.lnoprod = .F.
                        IF NOT THIS.checkincexp(invtmp.cwellid, invtmp.hyear, invtmp.hperiod, invtmp.nRunNo, invtmp.crunyear)
                           SELECT invtmp
                           DELETE NEXT 1
                           LOOP
                        ENDIF
                     ENDIF
                  ELSE
                     THIS.stmtnotes(THIS.nRunNo, tcRunYear, THIS.cwellid, THIS.oinvtmp.cownerid)
                     m.cDescript = ' '
                     m.cownerid  = THIS.cownerid
                  ENDIF

                  *  Initialize work properties that need to be passed between methods
                  STORE ' ' TO m.oprng1, m.oprng2, m.gprng1, m.gprng2
                  STORE 0 TO THIS.noiltax1, THIS.noiltax2, THIS.noiltax3, THIS.noiltax4
                  STORE 0 TO THIS.ngastax1, THIS.ngastax2, THIS.ngastax3, THIS.ngastax4
                  STORE 0 TO THIS.nothtax1, THIS.nothtax2, THIS.nothtax3, THIS.nothtax4
                  STORE 0 TO jflatcnt
                  STORE 'N' TO m.cdirect

                  * If this record wasn't created during this run
                  * get the real runno from runno_in so that the
                  * original income entries can be pulled.
                  IF THIS.oinvtmp.nRunNo_In # 0 AND (THIS.oinvtmp.cRunYear_In + PADL(THIS.oinvtmp.nRunNo_In, 3, '0') # THIS.crunyear + PADL(THIS.nRunNo, 3, '0'))
                     lnRevRun  = THIS.oinvtmp.nRunNo_In
                     tnRunNo   = THIS.oinvtmp.nRunNo_In
                     tcRunYear = THIS.oinvtmp.cRunYear_In
                  ELSE
                     * Use the runno we were called with in case it was 0
                     * Changed to use the next runno if runno is zero - pws 1/20/09
                     lnRevRun  = THIS.nNewRunNo
                     tcRunYear = THIS.crunyear
                  ENDIF
                  THIS.lnotax = .F.
                  *************************************************************
                  *  Process Flat-Rates to deduct them from working interests
                  *************************************************************
                  THIS.flatowner(THIS.oinvtmp.nRunNo_In # 0 AND THIS.oinvtmp.nRunNo_In # THIS.nRunNo, tcRunYear, lnRevRun)

                  STORE 0 TO jnflatoil, jnflatgas
                  STORE ' ' TO m.cTYPE

                  *************************************************************
                  *  Process Income
                  *************************************************************
                  IF THIS.oinvtmp.lmanual OR NOT THIS.calcincome(THIS.cwellid, lnRevRun, tcRunYear, THIS.oinvtmp.hyear, THIS.oinvtmp.hperiod, THIS.dRevDate, THIS.oinvtmp.cDeck)
                     IF NOT EMPTY(invtmp.cSuspType)
                        IF invtmp.nincome # 0
                           *  Get the total of the flat rates already processed for this owner, so it can be
                           *  subtracted off this entry.  If it leaves zero, don't add it to the statement.
                           lnFlatTotal = 0
                           SELECT statemnt
                           LOCATE FOR cownerid == m.cownerid AND ;
                              cwellid == m.cwellid   AND ;
                              cTYPE = 'FLT'          AND ;
                              ninvamt = invtmp.nincome AND ;
                              cyear   = invtmp.hyear AND ;
                              cperiod = invtmp.hperiod
                           IF NOT FOUND()

                              m.crptgroup   = 'B'
                              m.csource     = 'Prior Suspense'
                              m.nunits      = 0
                              m.nprice      = 0
                              m.cyear       = invtmp.hyear
                              m.cperiod     = invtmp.hperiod
                              m.nAmount     = invtmp.nincome - invtmp.nsevtaxes - lnFlatTotal - invtmp.ncompress - invtmp.ngather
                              m.ninvamt     = invtmp.nincome - invtmp.nsevtaxes - lnFlatTotal - invtmp.ncompress - invtmp.ngather
                              m.nTOTAL      = invtmp.nincome - invtmp.nsevtaxes - lnFlatTotal - invtmp.ncompress - invtmp.ngather
                              THIS.ntotinc  = THIS.ntotinc + m.ninvamt
                              THIS.nwelltot = THIS.nwelltot + m.ninvamt
                              m.nRevInt     = 100
                              m.cTYPE       = 'OTH'
                              m.cdirect     = 'N'
                              m.cTypeInv    = invtmp.cTypeInv
                              m.crunyear    = THIS.crunyear
                              IF m.ninvamt # 0
                                 INSERT INTO statemnt FROM MEMVAR
                              ENDIF
                           ENDIF
                           THIS.lnotax = .T.
                        ENDIF
                     ENDIF
                  ENDIF

                  STORE 0 TO m.ninvamt, m.nTOTAL, m.nprice, m.nunits, m.nRevInt
                  STORE ' ' TO m.cTYPE, m.csource, m.crange


                  *************************************************************
                  *  Process taxes
                  *************************************************************
                  IF NOT THIS.lnotax
                     THIS.calctaxes(THIS.cwellid, lnRevRun, tcRunYear, THIS.oinvtmp.hyear, THIS.oinvtmp.hperiod, THIS.dRevDate)
                  ENDIF

                  THIS.lnotax = .F.
                  STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
                  STORE ' ' TO m.csource, m.cTYPE, m.cMethod
                  *************************************************************
                  *  Process Gathering and Compression Charges
                  *************************************************************
                  *!*                        IF THIS.oinvtmp.nincome <> 0 AND NOT THIS.oinvtmp.lmanual
                  IF NOT THIS.oinvtmp.lmanual
                     THIS.CalcCompress()
                  ENDIF
                  STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
                  STORE ' ' TO m.csource, m.cTYPE, m.cDescript

                  *************************************************************
                  *  Process Marketing Charges
                  *************************************************************
                  IF THIS.oinvtmp.nmktgexp # 0 AND NOT THIS.oinvtmp.lmanual
                     THIS.CalcMktg()
                  ENDIF
                  STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
                  STORE ' ' TO m.csource, m.cTYPE, m.cDescript

                  *************************************************************
                  *  Process Entered Gathering Charges
                  *************************************************************
                  IF NOT THIS.oinvtmp.lmanual
                     *                        THIS.CalcGathering()
                  ENDIF
                  STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
                  STORE ' ' TO m.csource, m.cTYPE, m.cDescript

                  *************************************************************
                  *  Process Entered Compression Charges
                  *************************************************************
                  IF NOT THIS.oinvtmp.lmanual
                     *                       THIS.CalcCompression()
                  ENDIF
                  STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
                  STORE ' ' TO m.csource, m.cTYPE, m.cDescript

                  *************************************************************
                  *  Process expenses
                  *************************************************************
                  IF NOT THIS.CalcExpense(lnRevRun, tcRunYear, THIS.oinvtmp.hyear, THIS.oinvtmp.hperiod, THIS.dExpDate, THIS.oinvtmp.cDeck)
                     IF NOT EMPTY(invtmp.cSuspType) OR invtmp.lmanual
                        IF invtmp.nexpense # 0 OR ;
                              invtmp.ntotale1 # 0 OR ;
                              invtmp.ntotale2 # 0 OR ;
                              invtmp.ntotale3 # 0 OR ;
                              invtmp.ntotale4 # 0 OR ;
                              invtmp.ntotale5 # 0 OR ;
                              invtmp.nTotaleA # 0 OR ;
                              invtmp.nTotaleB # 0 OR ;
                              invtmp.nPlugExp # 0
                           m.crptgroup = 'D'
                           m.cownerid  = invtmp.cownerid
                           m.cCategory = 'Prior Suspense'
                           m.ninvamt = invtmp.nexpense + ;
                              invtmp.ntotale1 + ;
                              invtmp.ntotale2 + ;
                              invtmp.ntotale3 + ;
                              invtmp.ntotale4 + ;
                              invtmp.ntotale5 + ;
                              invtmp.nTotaleA + ;
                              invtmp.nTotaleB + ;
                              invtmp.nPlugExp
                           m.nAmount     = m.ninvamt
                           m.nTOTAL      = m.ninvamt
                           m.dExpDate    = invtmp.hdate
                           THIS.nwelltot = THIS.nwelltot - m.ninvamt
                           m.nRevInt     = 100
                           m.nworkint    = 100
                           m.cTYPE       = 'EXP'
                           m.cdirect     = 'N'
                           m.cTypeInv    = invtmp.cTypeInv
                           m.cyear       = invtmp.hyear
                           m.cperiod     = invtmp.hperiod
                           m.crunyear    = THIS.crunyear
                           INSERT INTO statemnt FROM MEMVAR
                        ENDIF
                     ENDIF
                  ENDIF

                  * Include payments in the expense section
                  IF NOT THIS.lNoSuspDet
                     SELECT invtmp
                     lnrecNo = RECNO()
                     SCAN FOR crectype = 'P'  AND NOT lused AND cownerid == m.cownerid AND cwellid == m.cwellid AND cTypeInv == lcTypeOwner
                        SCATTER MEMVAR
                        IF EMPTY(invtmp.cTypeInv)
                           REPLACE invtmp.cTypeInv WITH 'W', ;
                              invtmp.ctypeint WITH 'B'
                        ENDIF
                        swSelect('wellinv')
                        LOCATE FOR cownerid == m.cownerid AND cwellid == m.cwellid
                        IF FOUND()
                           m.ctypeint = ctypeint
                           IF NOT EMPTY(cprogcode)
                              m.cprogcode = cprogcode
                           ENDIF
                        ENDIF
                        SELECT invtmp
                        m.crptgroup = 'D'
                        m.cownerid  = invtmp.cownerid
                        m.cCategory = '**  Payment Received  **'
                        m.ninvamt   = invtmp.nnetcheck * -1
                        m.nAmount   = 0
                        m.nTOTAL    = invtmp.nnetcheck * -1
                        m.dExpDate  = invtmp.hdate
                        m.nRevInt   = 100
                        m.nworkint  = 100
                        m.cTYPE     = 'EXP'
                        m.cdirect   = 'N'
                        m.cTypeInv  = invtmp.cTypeInv

                        IF EMPTY(m.ctypeint)
                           m.ctypeint = 'B'
                        ENDIF

                        m.cyear   = invtmp.hyear
                        m.cperiod = invtmp.hperiod
                        m.cWellType = m.cownerid + m.cwellid + ;
                           M.cTypeInv + '0'
                        m.nTotNet        = m.nTotNet + invtmp.nnetcheck
                        THIS.nbalance    = THIS.nbalance + invtmp.nnetcheck
                        THIS.nownertotal = THIS.nownertotal + invtmp.nnetcheck
                        m.ntotalcheck    = m.ntotalcheck + invtmp.nnetcheck
                        THIS.nwelltot    = THIS.nwelltot + invtmp.nnetcheck
                        m.crunyear       = THIS.crunyear
                        INSERT INTO statemnt FROM MEMVAR
                        SELECT invtmp
                        REPLACE lused WITH .T.
                     ENDSCAN
                     SELECT invtmp
                     GOTO lnrecNo
                  ENDIF

                  *************************************************************
                  *  Process well net total when splitting prod prds
                  *************************************************************
                  THIS.NetWellTotalSplit()

                  *************************************************************
                  *  Process Well Statement notes
                  *************************************************************
                  THIS.stmtnotes(THIS.nRunNo, tcRunYear, THIS.cwellid, THIS.oinvtmp.cownerid)

                  STORE 0 TO m.nWellNet, m.nTotNet, m.nProgNet
                  SELECT invtmp
                  THIS.nbackupwith = THIS.nbackupwith + THIS.oinvtmp.nbackwith
                  THIS.ntaxwith    = THIS.ntaxwith  + THIS.oinvtmp.ntaxwith
                  THIS.ownergroup  = THIS.cownerid + THIS.cwellid + THIS.oinvtmp.cTypeInv
                  THIS.cprogcode   = invtmp.cprogcode

                  *************************************************************
                  *  Process the inception to date totals if needed
                  *  Added 4/15/2002 by pws
                  *************************************************************
                  IF FILE('datafiles\weinsz.itd') OR FILE('datafiles\totals.itd')
                     swSelect('owntots')
                     LOCATE FOR cownerid == THIS.oinvtmp.cownerid AND ;
                        cwellid  == THIS.oinvtmp.cwellid  AND ;
                        cTypeInv == THIS.oinvtmp.cTypeInv AND ;
                        ctypeint == THIS.oinvtmp.ctypeint
                     IF FOUND()
                        m.oitdtotal  = oitdtotal
                        m.gitdtotal  = gitdtotal
                        m.witdtotal  = witdtotal + c1itdtotal + c2itdtotal + c3itdtotal + c4itdtotal + c5itdtotal + caitdtotal + cbitdtotal
                        m.ytdincome  = oytdtotal + gytdtotal + tytdtotal + m1ytdtotal + m2ytdtotal
                        m.itdincome  = oitdtotal + gitdtotal + titdtotal
                        m.ytdexpense = wytdtotal + c1ytdtotal + c2ytdtotal + c3ytdtotal + c4ytdtotal + c5ytdtotal + gcytdtotal + ccytdtotal
                        m.itdexpense = witdtotal + c1itdtotal + c2itdtotal + c3itdtotal + c4itdtotal + c5itdtotal + gcitdtotal + ccitdtotal
                        m.nitdnet    = m.itdincome - m.itdexpense - txitdtotal
                        m.txitdtotal = txitdtotal
                        m.titdtotal  = titdtotal
                        m.oytdtotal  = oytdtotal
                        m.gytdtotal  = gytdtotal
                        m.wytdtotal  = wytdtotal + c1ytdtotal + c2ytdtotal + c3ytdtotal + c4ytdtotal + c5ytdtotal + caYTDtotal + cbYTDtotal
                        m.nYTDnet    = m.ytdincome - m.ytdexpense - txytdtotal
                        m.txytdtotal = txytdtotal
                        m.tytdtotal  = tytdtotal
                        m.crptgroup  = 'F'
                        m.cSuspType  = ''
                        m.cTYPE      = 'NET'
                        m.nWellNet   = 0
                        m.nTotNet    = 0
                        m.nProgNet   = 0
                        m.cyear      = THIS.crunyear
                        m.cperiod    = lcperiod2
                        m.dAcctDate  = THIS.dAcctDate
                        m.crunyear   = THIS.crunyear
                        m.cownerid   = THIS.oinvtmp.cownerid
                        m.cwellid    = THIS.oinvtmp.cwellid

                        SELE statemnt
                        LOCATE FOR crptgroup = 'F' AND ;
                           cownerid == THIS.oinvtmp.cownerid AND ;
                           cwellid  == THIS.oinvtmp.cwellid  AND ;
                           cTypeInv == THIS.oinvtmp.cTypeInv AND ;
                           'Inception' $ cDescript
                        IF NOT FOUND()
                           m.cDescript = 'Year To Date Totals: ' + CHR(10) + ;
                              IIF(m.oytdtotal # 0, 'Oil Rev = ' + ALLTRIM(TRANSFORM(m.oytdtotal, '$$$,$$$,$$$.99')) + SPACE(2), '') + ;
                              IIF(m.gytdtotal # 0, 'Gas Rev = ' + ALLTRIM(TRANSFORM(m.gytdtotal, '$$$,$$$,$$$.99')) + SPACE(2), '') + ;
                              IIF(m.tytdtotal # 0, 'Other Rev = ' + ALLTRIM(TRANSFORM(m.tytdtotal, '$$$,$$$,$$$.99')), '') + CHR(10) + ;
                              IIF(m.txytdtotal # 0, 'Taxes = ' + ALLTRIM(TRANSFORM(m.txytdtotal, '$$$,$$$,$$$.99')) + SPACE(2), '') + ;
                              IIF(m.wytdtotal # 0, 'Expenses = ' + ALLTRIM(TRANSFORM(m.wytdtotal, '$$$,$$$,$$$.99')), '') + CHR(10) + ;
                              'Net = ' + ALLTRIM(TRANSFORM(m.nYTDnet, '$$$,$$$,$$$.99'))
                           m.dAcctDate = THIS.dAcctDate
                           m.crunyear  = THIS.crunyear
                           INSERT INTO statemnt FROM MEMVAR
                           m.cDescript = 'Inception To Date Totals: ' + CHR(10) + ;
                              IIF(m.oitdtotal # 0, 'Oil Rev = ' + ALLTRIM(TRANSFORM(m.oitdtotal, '$$$,$$$,$$$.99')) + SPACE(2), '') + ;
                              IIF(m.gitdtotal # 0, 'Gas Rev = ' + ALLTRIM(TRANSFORM(m.gitdtotal, '$$$,$$$,$$$.99')) + SPACE(2), '') + ;
                              IIF(m.titdtotal # 0, 'Other Rev = ' + ALLTRIM(TRANSFORM(m.titdtotal, '$$$,$$$,$$$.99')), '') + CHR(10) + ;
                              IIF(m.txitdtotal # 0, 'Taxes = ' + ALLTRIM(TRANSFORM(m.txitdtotal, '$$$,$$$,$$$.99')) + SPACE(2), '') + ;
                              IIF(m.witdtotal # 0, 'Expenses = ' + ALLTRIM(TRANSFORM(m.witdtotal, '$$$,$$$,$$$.99')), '') + CHR(10) + ;
                              'Net = ' + ALLTRIM(TRANSFORM(m.nitdnet, '$$$,$$$,$$$.99'))
                           m.dAcctDate = THIS.dAcctDate
                           m.crunyear  = THIS.crunyear
                           INSERT INTO statemnt FROM MEMVAR
                        ENDIF
                     ENDIF
                  ENDIF

               ENDSCAN  && invtmp

               IF THIS.lcanceled
                  llReturn = .F.
                  EXIT
               ENDIF

            ENDSCAN  && Owntypes

            IF THIS.lcanceled
               llReturn = .F.
               EXIT
            ENDIF

            * Check for the existence of wells processed
            lcWellID = m.cwellid
            SELECT statemnt
            LOCATE FOR cwellid = lcWellID AND crptgroup = 'A'
            IF NOT FOUND()
               LOCATE FOR crptgroup = 'A'
               IF FOUND()
                  m.cwellid    = cwellid
                  THIS.cwellid = cwellid
               ENDIF
            ENDIF

            *
            *  Process the well net totals for the last well for the owner
            *
            THIS.NetWellTotalNoSplit()

            m.cDescript = ' '
            STORE 0 TO THIS.nwelltot, m.nWellNet, m.nTotNet, m.nProgNet

            *************************************************************
            *  Process Backup and Tax Withholding
            *************************************************************
            THIS.BackTaxWith()

            *************************************************************
            *  Process Total Distribution this Run.
            *************************************************************

            IF NOT THIS.lbelowminimum
               SELECT invtotal
               m.crptgroup   = 'K'
               m.cSuspType   = ''
               m.cTYPE       = 'TOT'
               m.cperiod     = ''
               m.cyear       = THIS.cyear
               m.cprogcode   = '{'
               m.cWellType   = '}ZZZZZZZZZZ'
               m.cownerid    = THIS.cownerid
               m.nTotNet     = m.nTotalBal
               THIS.nbalance = m.nTotalBal

               IF m.lSuspense
                  m.cSuspType = 'Z'
               ELSE
                  m.cSuspType    = ''
               ENDIF
               lldef = .F.

               m.cDescript = 'Total Well Activity This Run'

               *   m.cOwnerID = THIS.cOwnerID
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group K      (Total Distribution)
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
            ENDIF

            lcWellType = m.cWellType

            *************************************************************
            *  Process suspense balance
            *************************************************************
            SELECT statemnt
            STORE 0 TO lnBalanceBefore

            IF FILE(m.goApp.cCommonFolder + 'priorsusp.txt')
               m.nTotNet       = THIS.osuspense.Owner_Balances(THIS.cownerid, THIS.cGROUP, .F., .T., .T., .T., .F.)
               lnBalanceBefore = m.nTotNet
               m.crptgroup     = 'N'
               m.cSuspType     = ''
               m.cTYPE         = 'BAL'
               m.cperiod       = ''
               m.cyear         = THIS.cyear
               m.cprogcode     = '{'
               m.cWellType     = lcWellType
               m.cWellType     = '}ZZZZZZZZZZ'
               m.cDescript     = 'Suspense Balance (Before This Run)'
               IF m.nTotNet # 0
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group N     (Suspense Balance Before This Run)
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
               ENDIF
            ENDIF

            IF NOT llSuspenseZero AND FILE(m.goApp.cCommonFolder + 'ownpmts.txt')
               * Get payments if they didn't zero out the suspense
               *            m.nTotNet   = THIS.osuspense.Owner_Payments(THIS.cownerid,THIS.cGROUP)
               m.nTotNet = THIS.Owner_Payments(THIS.cownerid)

               IF m.nTotNet # 0
                  m.crptgroup = 'N'
                  m.cSuspType = ''
                  m.cTYPE     = 'BAL'
                  m.cperiod   = ''
                  m.cyear     = THIS.cyear
                  m.cprogcode = '{'
                  m.cWellType = lcWellType
                  m.cWellType = '}ZZZZZZZZZZ'
                  m.cDescript = 'Payments made since last run'
                  m.cownerid  = THIS.cownerid
                  m.nRunNo    = THIS.nRunNo

                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group N     (Suspense Balance Before This Run)
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
               ENDIF
            ENDIF

            m.nTotNet      = THIS.osuspense.Owner_Balances(THIS.cownerid, THIS.cGROUP, .T., .T., .T., .T., .T.)
            IF VARTYPE(m.nTotNet) # 'N'
               llReturn  = .F.
               m.nTotNet = 0
               EXIT
            ENDIF
            lnBalanceAfter = m.nTotNet

            m.crptgroup = 'N'
            m.cSuspType = ''
            m.cTYPE     = 'BAL'
            m.cperiod   = ''
            m.cyear     = THIS.cyear
            m.cWellType = lcWellType
            m.cprogcode = '{'
            m.cWellType = '}ZZZZZZZZZZ'
            m.cDescript = 'Suspense Balance (After This Run)'

            * Only show the balance after this run as zero if the before balance wasn't zero. (it was cleared this run)
            IF m.nTotNet # 0 OR lnBalanceBefore # 0
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group N     (Suspense Balance After This Run)
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
            ENDIF
            m.cDescript = ' '

            * Plug in the balance description at the top of the statement
            m.cDescript = 'Check Amount'
            IF THIS.lbelowminimum = .T.
               m.nTotNet   = THIS.nbalance
            ENDIF

            * Look for owners who got a check
            SELECT currentrun
            LOCATE FOR cownerid = THIS.cownerid AND nnetcheck # 0 AND nRunNo_In # THIS.nRunNo
            IF FOUND()
               llCheck = .T.
            ELSE
               llCheck = .F.
            ENDIF
            SELECT invtmp
            LOCATE FOR cownerid = THIS.cownerid AND nnetcheck # 0 AND nRunNo_In # THIS.nRunNo
            IF FOUND()
               llCheck = .T.
            ELSE
               llCheck = .F.
            ENDIF

            IF NOT llCheck
               IF THIS.lnetwells
                  * Group is netting deficits between wells
                  SELECT curlastsusptype
                  LOCATE FOR cownerid = THIS.cownerid AND NOT EMPTY(cSuspType)
                  IF FOUND()
                     lcCurStatus = cSuspType
                  ELSE
                     lcCurStatus = '*'
                  ENDIF
               ELSE
                  SELECT curlastsusptype
                  LOCATE FOR cownerid = THIS.cownerid AND cSuspType = 'D'
                  IF FOUND()
                     lcCurStatus = 'D'
                  ELSE
                     SELECT curlastsusptype
                     LOCATE FOR cownerid = THIS.cownerid AND NOT EMPTY(cSuspType)
                     IF FOUND()
                        lcCurStatus = cSuspType
                     ELSE
                        lcCurStatus = '*'
                     ENDIF
                  ENDIF
               ENDIF
            ELSE
               lcCurStatus = '*'
            ENDIF

            * Check for direct deposits since the ldirdep in disbhist isn't working right now  12/30/19 - pws
            swSelect('checks')
            LOCATE FOR cid = THIS.cownerid AND cbatch == THIS.cDMBatch
            IF FOUND()
               llCheck = .T.
               IF 'DIRDEP' $ ccheckno
                  llDirDep = .T.
               ELSE
                  llDirDep = .F.
               ENDIF
            ELSE
               llCheck = .F.
            ENDIF

            DO CASE
               CASE m.lownerposted
                  m.cDescript = 'Posted To G/L:'

               CASE llDirDep AND m.nTotalBal > 0
                  DO CASE
                     CASE lcCurStatus = 'M'
                        m.cDescript = 'Minimum Suspense Balance:'
                        m.nTotalBal = lnBalanceAfter
                        SELECT statemnt
                        SCAN FOR cownerid == THIS.cownerid
                           REPLACE nTotalBal WITH m.nTotalBal
                        ENDSCAN
                     CASE lcCurStatus = 'D'
                        IF glStminv
                           IF lnBalanceAfter = 0
                              m.cDescript = 'Current Balance:'
                           ELSE
                              IF lnBalanceAfter > 0
                                 m.cDescript = 'Current Balance:'
                              ELSE
                                 m.cDescript = 'Please Pay'
                              ENDIF
                           ENDIF
                        ELSE
                           IF lnBalanceAfter = 0
                              m.cDescript = 'Current Balance:'
                           ELSE
                              IF lnBalanceAfter > 0
                                 m.cDescript = 'Current Balance:'
                              ELSE
                                 m.cDescript = 'Deficit Suspense Balance:'
                              ENDIF
                           ENDIF
                        ENDIF
                        m.nTotalBal = lnBalanceAfter
                        SELECT statemnt
                        SCAN FOR cownerid == THIS.cownerid
                           REPLACE nTotalBal WITH m.nTotalBal
                        ENDSCAN
                     CASE lcCurStatus = 'H'
                        m.cDescript = 'Held Balance:'
                     OTHERWISE
                        m.cDescript = 'Direct Deposited:'
                  ENDCASE

               CASE llCheck
                  m.cDescript = 'Check Amount:'

               CASE lcCurStatus = 'M'
                  m.cDescript = 'Minimum Suspense Balance:'
                  m.nTotalBal = lnBalanceAfter
                  SELECT statemnt
                  SCAN FOR cownerid == THIS.cownerid
                     REPLACE nTotalBal WITH m.nTotalBal
                  ENDSCAN

               CASE lcCurStatus = 'H'
                  m.cDescript = 'Held Balance:'
                  IF lnBalanceAfter # 0
                     m.nTotalBal = lnBalanceAfter
                  ENDIF
                  SELECT statemnt
                  SCAN FOR cownerid == THIS.cownerid
                     REPLACE nTotalBal WITH m.nTotalBal
                  ENDSCAN

               CASE lcCurStatus = 'D'
                  IF glStminv
                     IF lnBalanceAfter = 0
                        m.cDescript = 'Current Balance:'
                     ELSE
                        IF lnBalanceAfter > 0
                           m.cDescript = 'Current Balance:'
                        ELSE
                           m.cDescript = 'Please Pay'
                        ENDIF
                     ENDIF
                  ELSE
                     IF lnBalanceAfter = 0
                        m.cDescript = 'Current Balance:'
                     ELSE
                        IF lnBalanceAfter > 0
                           m.cDescript = 'Current Balance:'
                        ELSE
                           m.cDescript = 'Deficit Suspense Balance:'
                        ENDIF
                     ENDIF
                  ENDIF
                  m.nTotalBal = lnBalanceAfter
                  SELECT statemnt
                  SCAN FOR cownerid == THIS.cownerid
                     REPLACE nTotalBal WITH m.nTotalBal
                  ENDSCAN

               CASE INLIST(lcCurStatus, 'Q', 'A', 'S', 'I')
                  m.cDescript = 'Placed In Suspense:'
                  IF lcCurStatus = 'I'
                     * Check to make sure all the wells have their interests on hold
                     SELECT cSuspType FROM curlastsusptype WHERE cownerid = m.cownerid AND cSuspType # 'I' INTO CURSOR tmpsusptype
                     IF _TALLY > 0
                        m.cDescript = 'Current Run Amount:'
                     ELSE
                        m.nTotalBal = lnBalanceAfter
                        SELECT statemnt
                        SCAN FOR cownerid == THIS.cownerid
                           REPLACE nTotalBal WITH m.nTotalBal
                        ENDSCAN
                     ENDIF
                     USE IN tmpsusptype
                  ENDIF
               OTHERWISE
                  m.cDescript = 'Current Run Amount:'
            ENDCASE

            m.cbalancedesc = m.cDescript
            SELECT statemnt
            SCAN FOR cownerid == THIS.cownerid
               REPLACE cbalancedesc WITH m.cbalancedesc
            ENDSCAN

            WAIT CLEAR

            *************************************************************
            *  Process suspense amount released this run
            *************************************************************
            IF THIS.lNoSuspDet
               THIS.susprelbal()
            ENDIF

            THIS.lbelowminimum = .F.
         ENDSCAN  && invtotal

         IF THIS.lcanceled
            llReturn = .F.
            EXIT
         ENDIF

         *
         *  Print Program totals and deficits covered
         *

         STORE .F. TO m.lHold, m.lOnHold

         SELE progtots
         SCAN
            SCATTER MEMVAR

            * Look to see if this program has any records
            * Don't print a total line for programs with no activity
            SELECT statemnt
            LOCATE FOR cprogcode == m.cprogcode
            IF NOT FOUND()
               LOOP
            ENDIF

            swSelect('investor')
            SET ORDER TO cownerid
            IF SEEK(progtots.cownerid)
               m.lwellpage = lwellpage
            ENDIF
            *
            * Print the program total
            *
            m.crptgroup = 'E'
            m.cSuspType = ''
            m.nWellNet  = nprogtot
            m.cTYPE     = 'PRG'
            m.cprogcode = m.cprogcode
            m.nTotNet   = 0
            *   m.cownerid = this.cownerid
            swSelect('programs')
            LOCATE FOR cprogcode = m.cprogcode
            IF FOUND()
               m.cProgName = cProgName
            ELSE
               m.cProgName = ''
            ENDIF
            m.cWellType = '{YZZZZZZ'
            STORE '' TO m.cDescript
            SELE statemnt
            LOCATE FOR cownerid = progtots.cownerid AND crptgroup = 'A'
            IF FOUND()
               m.nTotalBal  = nTotalBal
               m.caddress1  = statemnt.caddress1
               m.caddress2  = statemnt.caddress2
               m.ccityState = statemnt.ccityState
            ELSE
               m.nTotalBal = 0
            ENDIF
            m.crunyear = THIS.crunyear
            *********************************************************************************************************
            *  Insert into the statement file  - Report Group E     (Program Totals)
            *********************************************************************************************************
            SELECT statemnt
            LOCATE FOR cprogcode == m.cprogcode AND (crptgroup = 'B' OR crptgroup = 'D')
            IF FOUND()
               INSERT INTO statemnt FROM MEMVAR
            ENDIF

            m.nWellNet = 0
            lnprogamt  = 0
            m.nProgNet = 0
            *
            *  Look for any program deficits that are being covered.
            *
            llCheckAmt = .F.
            SELECT statemnt
            SCAN FOR cownerid == THIS.cownerid
               IF 'Check Amount' $ cbalancedesc
                  llCheckAmt = .T.
               ENDIF
            ENDSCAN
            IF llCheckAmt
               USE DBF('invtmp') AGAIN IN 0 ALIAS tmpsusp
               SELECT tmpsusp
               SET ORDER TO 0
               SCAN FOR cownerid = progtots.cownerid ;
                     AND nnetcheck # 0 ;
                     AND cSuspType = 'D' ;
                     AND cprogcode = m.cprogcode ;
                     AND cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') # crunyear + PADL(TRANSFORM(nRunNo), 3, '0')
                  lnprogamt  = lnprogamt + nnetcheck
               ENDSCAN     && tmpsusp
               IF lnprogamt # 0
                  m.crptgroup = 'E'
                  m.cSuspType = ''
                  m.cTYPE     = 'PRS'
                  m.nWellNet  = lnprogamt
                  m.cperiod   = ''
                  m.cyear     = THIS.cyear
                  m.cWellType = '}YZZZZZZ'
                  swSelect('programs')
                  LOCATE FOR cprogcode = m.cprogcode
                  IF FOUND()
                     lcprogname = cProgName
                  ELSE
                     lcprogname = ''
                  ENDIF
                  m.cDescript = 'Balance Brought Forward From Previous Periods For Program: ' + lcprogname
                  m.nRunNo    = THIS.nRunNo
                  m.crunyear  = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group E     (Program Deficits)
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWellNet  = 0
                  m.nProgNet  = 0
                  m.cDescript = ' '
               ENDIF
               SELECT tmpsusp
               USE
            ENDIF
            m.nWellNet = 0
            lnProgTot  = 0
            m.nProgNet = 0

         ENDSCAN

         SELECT statemnt
         INDEX ON cownerid TAG cownerid
         INDEX ON cwellid TAG cwellid
         INDEX ON crptgroup TAG crptgroup
         INDEX ON cWellType TAG cWellType

         * Get list of owners and wells from statemnt
         * Remove any well records there's no "A" records.
         THIS.oProgress.SetProgressMessage('Cleaning up Statement File...')
         SELECT cownerid FROM statemnt INTO CURSOR tempowners ORDER BY cownerid GROUP BY cownerid
         SELE cownerid, cwellid FROM statemnt ;
            INTO CURSOR temp ;
            ORDER BY cownerid, cwellid ;
            GROUP BY cownerid, cwellid
         SELE temp
         SCAN FOR NOT EMPTY(cownerid)
            SCATTER MEMVAR
            SELE statemnt
            LOCATE FOR cownerid = m.cownerid AND cwellid = m.cwellid AND crptgroup = 'A'
            IF NOT FOUND()
               * Don't delete {YZZZZZZ record, since that's the prog total - BH 06/15/06
               DELETE  ;
                   FROM statemnt ;
                   WHERE cownerid = m.cownerid ;
                       AND cwellid  = m.cwellid ;
                       AND NOT INLIST(crptgroup, 'K', 'N') ;
                       AND cWellType # '{YZZZZZZ'
            ENDIF
         ENDSCAN

         SELECT tempowners
         SCAN
            m.cownerid = cownerid
            SELECT statemnt
            LOCATE FOR cownerid == m.cownerid AND crptgroup = 'A'
            IF NOT FOUND()
               DELETE FOR cownerid == m.cownerid
            ENDIF
         ENDSCAN
         THIS.oProgress.UpdateProgress(lnCount)
         lnCount = lnCount + 10

         SELECT statemnt
         IF THIS.lziporder
            INDEX ON czipcode + cownerid + cprogcode + cWellType + crptgroup + ctaxcode + cyear + cperiod + cSuspType TAG invprog
         ELSE
            INDEX ON cownerid + cprogcode + cWellType + crptgroup + ctaxcode + cyear + cperiod + cSuspType TAG invprog
         ENDIF

         lnEnd = SECONDS()

         THIS.oProgress.SetProgressMessage('Checking Owner Addresses...')
         * Get list of owners in statemnt file.
         swSelect('investor')
         SET ORDER TO cownerid
         SELE cownerid FROM statemnt INTO CURSOR temp ORDER BY cownerid GROUP BY cownerid
         SELE temp
         SCAN
            m.cownerid = cownerid
            SELECT investor
            IF SEEK(m.cownerid)
               *
               *  Check to see if this investors deficit cStatement should be printed
               *
               SCATTER MEMVAR
               **-
               **-  If the statment should be sent to the secondary address
               **-  pull in the secondary address, otherwise pull in the
               **-  primary address.
               **-
               IF m.lchktosec AND NOT m.lcheckonly
                  m.cownname  = m.cownname
                  m.cOwnname1 = m.cownname2
                  IF m.lNoFirstName &&  Don't use the primary  name with a secondary address
                     m.cownname  = m.cownname2
                     m.cOwnname1 = ''
                  ENDIF
                  m.caddress1 = m.caddress2a
                  IF NOT EMPTY(m.caddress2b)
                     m.caddress2  = m.caddress2b
                     m.ccityState = ALLTRIM(m.ccity2) + ' ' + m.cstate2 + '  ' + m.czip2
                     m.czipcode   = m.czip2
                  ELSE
                     m.caddress2  = ALLTRIM(m.ccity2) + ' ' + m.cstate2 + '  ' + m.czip2
                     m.ccityState = ' '
                     m.czipcode   = m.czip2
                  ENDIF
               ELSE
                  IF NOT EMPTY(m.caddress1a)
                     m.caddress1 = m.caddress1a
                     IF NOT EMPTY(m.caddress1b)
                        m.caddress2  = m.caddress1b
                        m.ccityState = ALLTRIM(m.ccity1) + ' ' + m.cstate1 + '  ' + m.czip1
                        m.czipcode   = m.czip1
                     ELSE
                        m.caddress2  = ALLTRIM(m.ccity1) + ' ' + m.cstate1 + '  ' + m.czip1
                        m.ccityState = ''
                        m.czipcode   = m.czip1
                     ENDIF
                  ELSE
                     IF NOT EMPTY(m.caddress1b)
                        m.caddress1  = m.caddress1b
                        m.caddress2  = ALLTRIM(m.ccity1) + ' ' + m.cstate1 + '  ' + m.czip1
                        m.ccityState = ''
                        m.czipcode   = m.czip1
                     ELSE  &&  Blank out address for people with no address, so it doesn't just carry forward the same address from the last owner who had an address filled in
                        m.caddress1  = ''
                        m.caddress2  = ''
                        m.ccityState = ''
                        m.czipcode   = m.czip1
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF
            SELE statemnt
            UPDATE  statemnt SET cownname = m.cownname, ;
                    cOwnname1 = m.cOwnname1, ;
                    caddress1 = m.caddress1, ;
                    caddress2 = m.caddress2, ;
                    ccityState = m.ccityState, ;
                    czipcode  = m.czipcode ;
                WHERE cownerid = m.cownerid
         ENDSCAN
         THIS.oProgress.UpdateProgress(lnCount)
         lnCount = lnCount + 10

         * Check to see how many wells an owner is in. If they're only in one well and their
         * owner record is marked to put each well on a separate page, unmark that option in
         * the statemnt table so it doesn't goof up the statement and take it to multiple pages.
         THIS.oProgress.SetProgressMessage('Calculating Pagination...')
         SELECT  cownerid, ;
                 lwellpage, ;
                 COUNT(*) AS ncount ;
             FROM statemnt ;
             WHERE crptgroup = 'A' ;
             INTO CURSOR temp ;
             ORDER BY cownerid ;
             GROUP BY cownerid
         SELECT temp
         SCAN FOR ncount = 1 AND lwellpage
            SELECT statemnt
            SCAN FOR cownerid = temp.cownerid
               REPLACE lwellpage WITH .F.
            ENDSCAN
         ENDSCAN

         * Set all records as on hold if one of them are
         * already marked that way so the ** Owner on Hold **
         * displays correctly on the statement.
         SELECT cownerid, lHold FROM statemnt WHERE lHold = .T. ORDER BY cownerid GROUP BY cownerid INTO CURSOR tmphold
         SCAN
            UPDATE statemnt SET lHold = .T. WHERE cownerid = tmphold.cownerid
         ENDSCAN

         * Fill in the tax code descriptions
         SELE statemnt
         SCAN
            IF lwellpage
               IF 'ZZZ' $ cWellType
                  REPLACE cpagebreak WITH m.cwellid
               ELSE
                  REPLACE cpagebreak WITH cwellid
                  m.cwellid = cwellid
               ENDIF
            ENDIF

            IF lownerposted
               REPLACE glStminv WITH .F.
            ENDIF
            IF THIS.lNewRun
               REPLACE nRunNo WITH 0
            ENDIF

            * Mark the prior suspense entries
            SELECT statemnt
            IF cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nNewRunNo), 3, '0') ;
                  AND INLIST(crptgroup, 'B', 'D') AND nRunNo_In # 0
               REPLACE lpriorsusp WITH .T.
            ENDIF
         ENDSCAN
         THIS.oProgress.UpdateProgress(lnCount)
         lnCount = lnCount + 10

         THIS.oProgress.SetProgressMessage('Removing Unwanted Statements...')
         * Get the totals for the owner from statemnt
         * so we can use it to determine if the statement
         * should print or not.
         SELECT  cownerid, ;
                 nTotalBal, ;
                 ninvmin, ;
                 lHold, ;
                 cbalancedesc ;
             FROM statemnt ;
             WHERE cWellType # '{YZZZZZZ' ;
             INTO CURSOR owntot ;
             ORDER BY cownerid ;
             GROUP BY cownerid, cbalancedesc

         SELECT owntot
         SCAN
            SCATTER MEMVAR

            DO CASE
               CASE m.nTotalBal = 0
                  SELECT statemnt
                  LOCATE FOR cownerid == m.cownerid AND INLIST(crptgroup, 'B', 'D')
                  IF NOT FOUND()
                     DELETE FOR cownerid == m.cownerid
                  ENDIF

               CASE NOT THIS.lprintmin AND NOT THIS.lprintdef
                  SELECT statemnt
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Current Balance:'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Deficit Suspense Balance:'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Placed In Suspense:'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Minimum Suspense Balance:'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Please Pay'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Held Balance'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Current Run Amount'


               CASE NOT THIS.lprintmin
                  SELECT statemnt
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Placed In Suspense:'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Minimum Suspense Balance:'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Held Balance'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Current Run Amount'

               CASE THIS.lallminsreleased AND (m.nTotalBal < m.ninvmin AND m.nTotalBal >= 0)
                  * Do nothing
               CASE NOT THIS.lprintdef
                  SELECT statemnt
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Current Balance:'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Deficit Suspense Balance:'
                  DELETE FOR cownerid == m.cownerid AND cbalancedesc = 'Please Pay'

            ENDCASE
         ENDSCAN
         THIS.oProgress.UpdateProgress(lnCount)
         lnCount = lnCount + 10

         THIS.oProgress.SetProgressMessage('Cleaning up Statement File...')
         * Look for wells with only an A record. Remove them
         SELECT cWellType FROM statemnt WHERE crptgroup = 'A' INTO CURSOR temp
         SCAN
            SCATTER MEMVAR
            SELECT statemnt
            LOCATE FOR cWellType = m.cWellType AND crptgroup # 'A' AND crptgroup # 'F'
            IF NOT FOUND()
               DELETE FOR cWellType = m.cWellType
            ENDIF
         ENDSCAN
         THIS.oProgress.UpdateProgress(lnCount)
         lnCount = lnCount + 10

         THIS.oProgress.SetProgressMessage('Filling in Program Information...')
         SELECT statemnt
         GO TOP
         m.dAcctDate = THIS.dAcctDate
         REPL dAcctDate WITH m.dAcctDate ALL
         SCAN FOR NOT EMPTY(cprogcode) AND EMPTY(cProgName)
            swSelect('programs')
            LOCATE FOR cprogcode == statemnt.cprogcode
            IF FOUND()
               REPLACE statemnt.cProgName WITH programs.cProgName
            ENDIF
         ENDSCAN
         THIS.oProgress.UpdateProgress(lnCount)
         lnCount = lnCount + 10

         THIS.oProgress.SetProgressMessage('Removing Owners With No Activity...')
         * Delete any owners that don't have an "A" record
         SELECT cownerid FROM statemnt INTO CURSOR sowners ORDER BY cownerid GROUP BY cownerid
         SELECT sowners
         SCAN
            m.cownerid = cownerid
            SELECT statemnt
            LOCATE FOR cownerid == m.cownerid AND crptgroup = 'A'
            IF NOT FOUND()
               DELETE FOR cownerid == m.cownerid
            ENDIF
         ENDSCAN
         THIS.oProgress.UpdateProgress(lnCount)

         THIS.oProgress.CloseProgress()

         THIS.odist = .NULL.
         WAIT CLEAR

         IF USED('flatrates')
            USE IN flatrates
         ENDIF

         IF FILE(m.goApp.cCommonFolder + 'sumprogs.txt')

            SELECT statemnt
            SET ORDER TO 0
            SCAN
               IF NOT EMPTY(cprogcode)
                  lcWellID = cwellid
                  REPLACE cwellid WITH cprogcode, ;
                     cwellname WITH cProgName, ;
                     cWellType WITH STRTRAN(cWellType, lcWellID, cprogcode)
               ENDIF
            ENDSCAN

            SELECT  crptgroup, ;
                    cpagebreak, ;
                    cProgNoNet, ;
                    lclosed, ;
                    cWellType, ;
                    cownerid, ;
                    cownname, ;
                    cOwnname1, ;
                    caddress1, ;
                    caddress2, ;
                    ccityState, ;
                    caddr1, ;
                    caddr2, ;
                    caddr3, ;
                    cphoneno, ;
                    cfaxno, ;
                    czipcode, ;
                    dAcctDate, ;
                    cyear, ;
                    cperiod, ;
                    ntotalcheck, ;
                    nTotalBal, ;
                    cprogcode, ;
                    cProgName, ;
                    cwellid, ;
                    cwellname, ;
                    ccounty, ;
                    cstate, ;
                    crange, ;
                    ndayson, ;
                    cTYPE, ;
                    csource, ;
                    SUM(nunits) AS nunits, ;
                    nprice, ;
                    SUM(nTOTAL) AS nTOTAL, ;
                    SUM(ninvamt) AS ninvamt, ;
                    nRevInt, ;
                    nRoyInt, ;
                    SUM(nTotNet) AS nTotNet, ;
                    SUM(nWellNet) AS nWellNet, ;
                    SUM(nWorkTot) AS nWorkTot, ;
                    dExpDate, ;
                    ccatcode, ;
                    cCategory, ;
                    ctaxcode, ;
                    ctaxdesc, ;
                    cpayee, ;
                    SUM(nAmount) AS nAmount, ;
                    nworkint, ;
                    cTypeInv, ;
                    ctypeint, ;
                    cdirect, ;
                    nflatrate, ;
                    lFlat, ;
                    lused, ;
                    lwellpage, ;
                    lDirect, ;
                    lusesev, ;
                    cMethod, ;
                    cTaxable, ;
                    lHold, ;
                    lOnHold, ;
                    lExpDate, ;
                    ninvmin, ;
                    nintclass1, ;
                    nintclass2, ;
                    nintclass3, ;
                    nintclass4, ;
                    nintclass5, ;
                    cMiscMemo, ;
                    ljib, ;
                    glStminv, ;
                    glExpDate, ;
                    cprodprd, ;
                    cDescript, ;
                    crunyear, ;
                    nRunNo, ;
                    lcloserun, ;
                    lSuspense, ;
                    lpriorsusp, ;
                    nRunNo_In, ;
                    cRunYear_In, ;
                    cSuspType, ;
                    cbalancedesc, ;
                    pcbreak, ;
                    lownerposted, ;
                    nOilSummary, ;
                    nGasSummary, ;
                    nOthSummary, ;
                    nDedSummary, ;
                    nTaxSummary, ;
                    nExpSummary, ;
                    nNetSummary ;
                FROM statemnt ;
                INTO CURSOR statemnt READWRITE ;
                ORDER BY cownerid, cprogcode, cWellType, crptgroup, ctaxcode, cTYPE, csource, ccatcode, cyear, cperiod, cSuspType;
                GROUP BY cownerid, cprogcode, cWellType, crptgroup, ctaxcode, cTYPE, csource, ccatcode, cyear, cperiod, cSuspType
         ENDIF

         llReturn = DecimalInts('statemnt')

         SELECT statemnt
         IF THIS.lziporder
            INDEX ON czipcode + cownerid + cprogcode + cWellType + crptgroup + ctaxcode + cyear + cperiod + cSuspType TAG invprog
         ELSE
            IF FILE('datafiles\expsort.txt')
               INDEX ON cownerid + cprogcode + cWellType + crptgroup + ctaxcode + + ccatcode + cyear + cperiod + cSuspType TAG invprog
            ELSE
               INDEX ON cownerid + cprogcode + cWellType + crptgroup + ctaxcode + cyear + cperiod + cSuspType TAG invprog
            ENDIF
         ENDIF

         *  Send data through report

         SELECT statemnt
         SET ORDER TO invprog
         COUNT FOR NOT DELETED() TO lnCount
         GO TOP

         ON KEY LABEL esc

         IF lnCount = 0
            llReturn = .F.
         ELSE
            llReturn = .T.
         ENDIF

         IF THIS.lIncSummary
            THIS.CalcSummary()
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'Main', loError.LINENO, 'SWOwner', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      THIS.CheckCancel()

      RETURN llReturn
   ENDPROC

   *-- Calculates summary totals to show at the bottom of the statement
   ***********************************************************************
   PROCEDURE CalcSummary
      ***********************************************************************

      CREATE CURSOR summary_tots ;
         (cownerid  C(10), ;
           nOilSummary N(12, 2), ;
           nGasSummary N(12, 2), ;
           nOthSummary N(12, 2), ;
           nDedSummary N(12, 2), ;
           nTaxSummary N(12, 2), ;
           nExpSummary N(12, 2), ;
           nNetSummary N(12, 2))

      SELECT  cownerid ;
          FROM statemnt ;
          WHERE 'check' $ LOWER(cbalancedesc) ;
              OR 'posted' $ LOWER(cbalancedesc) ;
              AND crptgroup = 'A' ;
          INTO CURSOR checkowners ;
          ORDER BY cownerid ;
          GROUP BY cownerid

      SELECT  cownerid ;
          FROM statemnt ;
          WHERE NOT 'check' $ LOWER(cbalancedesc) ;
              AND NOT 'posted' $ LOWER(cbalancedesc) ;
              AND crptgroup = 'A' ;
          INTO CURSOR suspowners ;
          ORDER BY cownerid ;
          GROUP BY cownerid

      lcRunYear = THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      SELECT  cownerid, ;
              SUM(noilrev) AS nOilSummary, ;
              SUM(ngasrev) AS nGasSummary, ;
              SUM(nothrev + nmiscrev1 + nmiscrev2 + ntrprev) AS nOthSummary, ;
              SUM(nmktgexp + ncompress + ngather) AS nDedSummary, ;
              SUM(nsevtaxes) AS nTaxSummary, ;
              SUM(nexpense + ntotale1 + ntotale2 + ;
                  ntotale3 + ntotale4 + ntotale5 + ;
                  nTotaleA + nTotaleB + nPlugExp) AS nExpSummary, ;
              SUM(nnetcheck) AS nNetSummary ;
          FROM invtmp ;
          INTO CURSOR tempsummary1 ;
          WHERE cownerid IN (SELECT  cownerid ;
                                 FROM checkowners) ;
              AND (cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') # lcRunYear) ;
          ORDER BY cownerid ;
          GROUP BY cownerid

      SELECT  cownerid, ;
              SUM(noilrev) AS nOilSummary, ;
              SUM(ngasrev) AS nGasSummary, ;
              SUM(nothrev + nmiscrev1 + nmiscrev2 + ntrprev) AS nOthSummary, ;
              SUM(nmktgexp + ncompress + ngather) AS nDedSummary, ;
              SUM(nsevtaxes) AS nTaxSummary, ;
              SUM(nexpense + ntotale1 + ntotale2 + ;
                  ntotale3 + ntotale4 + ntotale5 + ;
                  nTotaleA + nTotaleB + nPlugExp) AS nExpSummary, ;
              SUM(nnetcheck) AS nNetSummary ;
          FROM invtmp ;
          INTO CURSOR tempsummary2 ;
          WHERE cownerid IN (SELECT  cownerid ;
                                 FROM suspowners) ;
              AND (cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') # lcRunYear) ;
          ORDER BY cownerid ;
          GROUP BY cownerid

      SELECT summary_tots
      APPEND FROM DBF('tempsummary1')
      APPEND FROM DBF('tempsummary2')

      SELECT summary_tots
      SCAN
         SCATTER MEMVAR
         UPDATE  statemnt SET nOilSummary = m.nOilSummary, ;
                 nGasSummary = m.nGasSummary, ;
                 nOthSummary = m.nOthSummary, ;
                 nDedSummary = m.nDedSummary, ;
                 nTaxSummary = m.nTaxSummary, ;
                 nExpSummary = m.nExpSummary, ;
                 nNetSummary = m.nNetSummary ;
             WHERE cownerid == m.cownerid

      ENDSCAN


      *-- Calculates compression/gathering charges (Calculated)
      ***********************************************************************
   PROCEDURE CalcCompress
      ***********************************************************************
      LOCAL m.nTOTAL, m.nprice

      swSelect('wells')
      LOCATE FOR cwellid = THIS.cwellid
      IF FOUND()
         THIS.ooptions.lroycomp = lexclroycomp
         llCalcComp             = lcompress
         llCalcGath             = lgather
      ELSE
         llCalcComp = .F.
         llCalcGath = .F.
      ENDIF

      * Gets the totals of entered gathering and compression as expenses
      THIS.CalcGathering()
      THIS.calcCompression()

      IF NOT llCalcComp AND NOT llCalcGath
         RETURN
      ENDIF

      SELECT wellwork
      LOCATE FOR cwellid == THIS.cwellid  AND crectype = 'R' ;
         AND hyear   == THIS.oinvtmp.hyear ;
         AND hperiod == THIS.oinvtmp.hperiod ;
         AND nRunNo  == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.nRunNo_In, THIS.oinvtmp.nRunNo) ;
         AND crunyear == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.cRunYear_In, THIS.oinvtmp.crunyear)
      IF NOT FOUND()
         RETURN .T.
      ENDIF
      SCATTER NAME THIS.owellwork

      make_copy('income', 'gathrev')
      make_copy('income', 'comprev')

      llFoundGATH = .F.

      * Get the total compression/gathering entered in revenue
      swSelect('income')
      SCAN FOR csource = 'GATH' ;
            AND income.cwellid = THIS.cwellid ;
            AND IIF(THIS.lNewRun, nRunNo = 0 AND dRevDate <= THIS.dRevDate, nRunNo = THIS.nRunNo AND crunyear = THIS.crunyear)
         SCATTER MEMVAR

         m.loneman = .F.
         SELE gathrev
         LOCATE FOR cwellid = m.cwellid AND cyear + cperiod = m.cyear + m.cperiod AND ;
            csource == m.csource AND cownerid = m.cownerid AND cperiod = m.cperiod AND cyear = m.cyear
         IF FOUND()
            REPL ntotalinc WITH ntotalinc + m.ntotalinc
         ELSE
            INSERT INTO gathrev FROM MEMVAR
         ENDIF
      ENDSCAN

      swSelect('income')
      SCAN FOR csource = 'COMP' ;
            AND income.cwellid = THIS.cwellid ;
            AND IIF(THIS.lNewRun, nRunNo = 0 AND dRevDate <= THIS.dRevDate, nRunNo = THIS.nRunNo AND crunyear = THIS.crunyear)
         SCATTER MEMVAR

         m.loneman = .F.
         SELE comprev
         LOCATE FOR cwellid = m.cwellid AND cyear + cperiod = m.cyear + m.cperiod AND ;
            csource == m.csource AND cownerid = m.cownerid AND cperiod = m.cperiod AND cyear = m.cyear
         IF FOUND()
            REPL ntotalinc WITH ntotalinc + m.ntotalinc
         ELSE
            INSERT INTO comprev FROM MEMVAR
         ENDIF
      ENDSCAN

      IF THIS.owellwork.ngather # 0 AND NOT THIS.ooptions.lHideComp
         IF THIS.lroyaltyowner AND THIS.ooptions.lChgPrice AND NOT llFoundGATH
            * Do Nothing
         ELSE
            IF THIS.lroyaltyowner AND THIS.ooptions.lroycomp AND NOT llFoundGATH
               * Do Nothing
            ELSE

               m.crptgroup = 'B'
               m.cTYPE     = 'MCF'
               m.cperiod   = ''
               m.cyear     = THIS.owellwork.hyear

               * Fill in the description for the gathering, based on the name in the revenue categories file
               swSelect('revcat')
               SET ORDER TO crevtype
               IF SEEK('GATH')
                  m.csource = revcat.cRevDesc
               ELSE
                  m.csource   = 'Gathering Charge'
               ENDIF

               m.nprice = THIS.ngather
               m.nTOTAL = THIS.owellwork.ngather * -1
               IF USED('gathtemp')  && Subtract gathering entered as an expense
                  SELECT gathtemp
                  SCAN FOR cwellid = THIS.owellwork.cwellid
                     m.nTOTAL = m.nTOTAL + gathtemp.nAmount
                  ENDSCAN
               ENDIF
               IF USED('gathrev') && Subtract out gathering entered as revenue
                  SELECT gathrev
                  SCAN FOR cwellid = THIS.owellwork.cwellid
                     m.nTOTAL = m.nTOTAL - gathrev.ntotalinc
                  ENDSCAN
               ENDIF

               *** Need to subtract any one-man items out of the units   ps - 1/14/19
               m.nunits    = THIS.owellwork.ntotmcf
               llFoundGATH = .F.
               IF NOT THIS.lroyaltyowner AND THIS.ooptions.lroycomp
                  lnInterest = 'm.nworkint'
               ELSE
                  lnInterest   = 'THIS.oinvtmp.nrevgas'
               ENDIF

               m.nRevInt = &lnInterest
               *               m.nRevInt   = ROUND(this.oInvtmp.nGather/this.owellwork.ngather,4) * 100
               m.ninvamt   = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
               *                m.ninvamt   = THIS.oinvtmp.ngather * -1
               m.cDescript = ' '
               m.cownerid  = THIS.oinvtmp.cownerid
               m.nRunNo    = THIS.nRunNo
               m.crunyear  = THIS.crunyear
               m.cperiod   = THIS.owellwork.hperiod
               m.cprogcode = THIS.oinvtmp.cprogcode

               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               IF &lnInterest # 0
                  INSERT INTO statemnt FROM MEMVAR
                  THIS.nwelltot = THIS.nwelltot + m.ninvamt
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      llFoundCOMP = .F.

      STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
      STORE ' ' TO m.csource, m.cTYPE, m.cDescript
      IF THIS.owellwork.ncompress # 0 AND NOT THIS.ooptions.lHideComp
         IF THIS.lroyaltyowner AND THIS.ooptions.lChgPrice AND NOT llFoundCOMP
            * Do Nothing
         ELSE
            IF THIS.lroyaltyowner AND THIS.ooptions.lroycomp AND NOT llFoundCOMP
               * Do Nothing
            ELSE
               m.crptgroup = 'B'
               m.cTYPE     = 'MCF'
               m.cperiod   = ''
               m.cyear     = THIS.owellwork.hyear

               * Fill in the description for the compression, based on the name in the revenue categories file
               swSelect('revcat')
               SET ORDER TO crevtype
               IF SEEK('COMP')
                  m.csource = revcat.cRevDesc
               ELSE
                  m.csource   = 'Compression Charge'
               ENDIF

               m.nprice = THIS.ncompress
               m.nTOTAL = THIS.owellwork.ncompress * -1
               IF USED('comptemp')
                  SELECT comptemp
                  SCAN FOR cwellid = THIS.owellwork.cwellid
                     m.nTOTAL = m.nTOTAL + comptemp.nAmount
                  ENDSCAN
               ENDIF
               IF USED('comprev')
                  SCAN FOR cwellid = THIS.owellwork.cwellid
                     m.nTOTAL = m.nTOTAL - comprev.ntotalinc
                  ENDSCAN
               ENDIF
               m.nunits    = THIS.owellwork.ntotmcf
               llFoundCOMP = .F.

               IF NOT THIS.lroyaltyowner AND THIS.ooptions.lroycomp
                  lnInterest = 'm.nworkint'
               ELSE
                  lnInterest   = 'THIS.oinvtmp.nrevgas'
               ENDIF

               m.nRevInt   = &lnInterest
               m.cperiod   = THIS.owellwork.hperiod
               m.ninvamt   = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
               m.cDescript = ' '
               m.cownerid  = THIS.oinvtmp.cownerid
               m.nRunNo    = THIS.nRunNo
               m.crunyear  = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               IF m.ninvamt # 0
                  INSERT INTO statemnt FROM MEMVAR
               ENDIF
               THIS.nwelltot = THIS.nwelltot + m.ninvamt
            ENDIF
         ENDIF
      ENDIF

      STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
      STORE ' ' TO m.csource, m.cTYPE, m.cDescript

      swclose('comprev')
      swclose('gathrev')
   ENDPROC

   *-- Calculates marketing charges
   ***********************************************************************
   PROCEDURE CalcMktg
      ***********************************************************************
      LOCAL llSuspense
      * Don't run this method if there's no marketing to report
      IF THIS.oinvtmp.nmktgexp = 0
         RETURN
      ENDIF

      *
      *  Prepare MKTG expense table
      *
      CREATE CURSOR mktgtemp ;
         (cwellid    C(10), ;
           ccatcode   C(4), ;
           ccateg     C(60), ;
           cyear      C(4), ;
           cperiod    C(2), ;
           crefid     C(20), ;
           dExpDate   D, ;
           nAmount    N(12, 2), ;
           cpayee     C(40), ;
           cmemo      C(60), ;
           cvendorid  C(10), ;
           cpaidbyck  C(8), ;
           cExpClass  C(1), ;
           nsaltwater I, ;
           cprdpaid   C(6), ;
           lfixed     L, ;
           laptran    L, ;
           cbatch     C(8), ;
           cownerid   C(10), ;
           loneman    L, ;
           cdescrip   C(30), ;
           lused      L)

      * This entry came from prior suspense
      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + ;
         PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      * Get the MKTG charges
      swSelect('expense')
      SCAN FOR cwellid == THIS.cwellid AND ;
            cyear # 'FIXD' AND ccatcode = 'MKTG' AND cyear == THIS.oinvtmp.hyear AND cperiod == THIS.oinvtmp.hperiod AND ;
            ICASE(NOT llSuspense AND NOT EMPTY(THIS.oinvtmp.cSuspType) AND NOT THIS.lNewRun, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              llSuspense, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              THIS.lNewRun, ;
              nrunnorev = 0 AND dExpDate <= THIS.dExpDate, ;
              nrunnorev = THIS.nRunNo AND crunyearrev = THIS.crunyear)

         SCATTER MEMVAR
         swSelect('expcat')
         SET ORDER TO ccatcode
         IF SEEK(m.ccatcode)
            m.cdescrip  = cdescrip
         ELSE
            LOOP
         ENDIF
         m.loneman = .F.
         SELE mktgtemp
         LOCATE FOR cwellid = m.cwellid AND ;
            ccatcode == m.ccatcode AND cownerid = m.cownerid AND cExpClass = m.cExpClass AND cyear + cperiod = m.cyear + m.cperiod
         IF FOUND()
            REPL nAmount WITH nAmount + m.nAmount
         ELSE
            INSERT INTO mktgtemp FROM MEMVAR
         ENDIF
      ENDSCAN

      swSelect('expcat')
      LOCATE FOR ccatcode = 'MKTG'
      IF FOUND()
         IF THIS.ooptions.lacctdesc = .T. AND NOT EMPTY(cdescrip)
            m.csource = cdescrip
         ELSE
            m.csource = ccateg
         ENDIF
      ELSE
         m.csource   = 'Marketing Charge'
      ENDIF
      SELE mktgtemp
      SCAN FOR cwellid == THIS.owellwork.cwellid
         m.cExpClass = cExpClass
         m.crptgroup = 'B'
         m.cTYPE     = 'OTH'
         m.cperiod   = ''
         m.cyear     = THIS.owellwork.hyear
         m.nprice    = 0
         m.nTOTAL    = mktgtemp.nAmount * -1
         m.nunits    = 0
         m.cwellid   = THIS.owellwork.cwellid

         DO CASE
            CASE m.cExpClass = '0'
               m.nRevInt = THIS.oinvtmp.nrevgas
            CASE m.cExpClass = '1'
               m.nRevInt = THIS.oinvtmp.nintclass1
            CASE m.cExpClass = '2'
               m.nRevInt = THIS.oinvtmp.nintclass2
            CASE m.cExpClass = '3'
               m.nRevInt = THIS.oinvtmp.nintclass3
            CASE m.cExpClass = '4'
               m.nRevInt = THIS.oinvtmp.nintclass4
            CASE m.cExpClass = '5'
               m.nRevInt = THIS.oinvtmp.nintclass5
            CASE m.cExpClass = 'A'
               m.nRevInt = THIS.oinvtmp.nacpint
            CASE m.cExpClass = 'B'
               m.nRevInt = THIS.oinvtmp.nbcpint
            OTHERWISE
               m.nRevInt = THIS.oinvtmp.nrevgas
         ENDCASE
         m.crptgroup = 'B'
         m.cTYPE     = 'OTH'
         m.cperiod   = ''
         m.cyear     = THIS.owellwork.hyear
         m.nprice    = 0
         m.nunits    = 0
         m.cperiod   = THIS.owellwork.hperiod
         m.ninvamt   = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
         m.cDescript = ' '
         m.cownerid  = THIS.oinvtmp.cownerid
         m.nRunNo    = THIS.nRunNo
         m.crunyear  = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group B
         *********************************************************************************************************
         IF m.ninvamt # 0
            INSERT INTO statemnt FROM MEMVAR
            THIS.nwelltot = THIS.nwelltot + m.ninvamt
         ENDIF
      ENDSCAN
   ENDPROC

   *-- Calculates gathering charges
   ***********************************************************************
   PROCEDURE CalcGathering
      ***********************************************************************
      LOCAL llSuspense

      *
      *  Prepare MKTG expense table
      *
      CREATE CURSOR gathtemp ;
         (cwellid    C(10), ;
           ccatcode   C(4), ;
           ccateg     C(60), ;
           cyear      C(4), ;
           cperiod    C(2), ;
           crefid     C(20), ;
           dExpDate   D, ;
           nAmount    N(12, 2), ;
           cpayee     C(40), ;
           cmemo      C(60), ;
           cvendorid  C(10), ;
           cpaidbyck  C(8), ;
           cExpClass  C(1), ;
           nsaltwater I, ;
           cprdpaid   C(6), ;
           lfixed     L, ;
           laptran    L, ;
           cbatch     C(8), ;
           cownerid   C(10), ;
           loneman    L, ;
           cdescrip   C(30), ;
           lused      L)

      * This entry came from prior suspense
      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + ;
         PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      * Get the GATH charges
      swSelect('expense')
      SCAN FOR cwellid == THIS.cwellid AND ;
            cyear # 'FIXD' AND ccatcode = 'GATH' AND cyear == THIS.oinvtmp.hyear AND cperiod == THIS.oinvtmp.hperiod AND ;
            ICASE(NOT llSuspense AND NOT EMPTY(THIS.oinvtmp.cSuspType) AND NOT THIS.lNewRun, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              llSuspense, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              THIS.lNewRun, ;
              nrunnorev = 0 AND dExpDate <= THIS.dExpDate, ;
              nrunnorev = THIS.nRunNo AND crunyearrev = THIS.crunyear)

         SCATTER MEMVAR
         swSelect('expcat')
         SET ORDER TO ccatcode
         IF SEEK(m.ccatcode)
            m.cdescrip  = cdescrip
         ELSE
            LOOP
         ENDIF
         m.loneman = .F.
         SELE gathtemp
         LOCATE FOR cwellid = m.cwellid AND ;
            ccatcode == m.ccatcode AND cownerid = m.cownerid AND cExpClass = m.cExpClass AND cyear + cperiod = m.cyear + m.cperiod
         IF FOUND()
            REPL nAmount WITH nAmount + m.nAmount
         ELSE
            INSERT INTO gathtemp FROM MEMVAR
         ENDIF
      ENDSCAN

      swSelect('expcat')
      LOCATE FOR ccatcode = 'GATH'
      IF FOUND()
         IF THIS.ooptions.lacctdesc = .T. AND NOT EMPTY(cdescrip)
            m.csource = cdescrip
         ELSE
            m.csource = ccateg
         ENDIF
      ELSE
         m.csource   = 'Gathering Charge'
      ENDIF

      SELE gathtemp
      SCAN FOR cwellid == THIS.owellwork.cwellid
         m.cExpClass = cExpClass
         m.crptgroup = 'B'
         m.cTYPE     = 'OTH'
         m.cperiod   = ''
         m.cyear     = THIS.owellwork.hyear
         m.nprice    = 0
         m.nTOTAL    = gathtemp.nAmount * -1
         m.nunits    = 0
         m.cwellid   = THIS.owellwork.cwellid

         IF NOT EMPTY(gathtemp.cownerid) AND gathtemp.cownerid # THIS.cownerid
            LOOP
         ENDIF

         DO CASE
            CASE NOT EMPTY(gathtemp.cownerid)
               m.nRevInt = 100
            CASE m.cExpClass = '0'
               m.nRevInt = THIS.oinvtmp.nworkint
            CASE m.cExpClass = '1'
               m.nRevInt = THIS.oinvtmp.nintclass1
            CASE m.cExpClass = '2'
               m.nRevInt = THIS.oinvtmp.nintclass2
            CASE m.cExpClass = '3'
               m.nRevInt = THIS.oinvtmp.nintclass3
            CASE m.cExpClass = '4'
               m.nRevInt = THIS.oinvtmp.nintclass4
            CASE m.cExpClass = '5'
               m.nRevInt = THIS.oinvtmp.nintclass5
            CASE m.cExpClass = 'A'
               m.nRevInt = THIS.oinvtmp.nacpint
            CASE m.cExpClass = 'B'
               m.nRevInt = THIS.oinvtmp.nbcpint
            OTHERWISE
               m.nRevInt = THIS.oinvtmp.nrevgas
         ENDCASE
         m.crptgroup = 'B'
         m.cTYPE     = 'OTH'
         m.cperiod   = ''
         m.cyear     = THIS.owellwork.hyear
         m.nprice    = 0
         m.nunits    = 0
         m.cperiod   = THIS.owellwork.hperiod
         m.ninvamt   = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
         m.cDescript = ' '
         m.cownerid  = THIS.oinvtmp.cownerid
         m.nRunNo    = THIS.nRunNo
         m.crunyear  = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group B
         *********************************************************************************************************
         IF m.ninvamt # 0
            INSERT INTO statemnt FROM MEMVAR
            THIS.nwelltot = THIS.nwelltot + m.ninvamt
         ENDIF
      ENDSCAN
   ENDPROC

   *-- Calculates gathering charges
   ***********************************************************************
   PROCEDURE calcCompression
      ***********************************************************************
      LOCAL llSuspense

      *
      *  Prepare COMPTEMP expense table
      *
      CREATE CURSOR comptemp ;
         (cwellid    C(10), ;
           ccatcode   C(4), ;
           ccateg     C(60), ;
           cyear      C(4), ;
           cperiod    C(2), ;
           crefid     C(20), ;
           dExpDate   D, ;
           nAmount    N(12, 2), ;
           cpayee     C(40), ;
           cmemo      C(60), ;
           cvendorid  C(10), ;
           cpaidbyck  C(8), ;
           cExpClass  C(1), ;
           nsaltwater I, ;
           cprdpaid   C(6), ;
           lfixed     L, ;
           laptran    L, ;
           cbatch     C(8), ;
           cownerid   C(10), ;
           loneman    L, ;
           cdescrip   C(30), ;
           lused      L)

      * This entry came from prior suspense
      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + ;
         PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      * Get the COMP charges
      swSelect('expense')
      SCAN FOR cwellid == THIS.cwellid AND ;
            cyear # 'FIXD' AND ccatcode = 'COMP' AND cyear == THIS.oinvtmp.hyear AND cperiod == THIS.oinvtmp.hperiod AND ;
            ICASE(NOT llSuspense AND NOT EMPTY(THIS.oinvtmp.cSuspType) AND NOT THIS.lNewRun, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              llSuspense, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              THIS.lNewRun, ;
              nrunnorev = 0 AND dExpDate <= THIS.dExpDate, ;
              nrunnorev = THIS.nRunNo AND crunyearrev = THIS.crunyear)

         SCATTER MEMVAR
         swSelect('expcat')
         SET ORDER TO ccatcode
         IF SEEK('COMP')
            m.cdescrip  = cdescrip
         ELSE
            LOOP
         ENDIF
         m.loneman = .F.
         SELE comptemp
         LOCATE FOR cwellid = m.cwellid AND ;
            ccatcode == m.ccatcode AND cownerid = m.cownerid AND cExpClass = m.cExpClass AND cyear + cperiod = m.cyear + m.cperiod
         IF FOUND()
            REPL nAmount WITH nAmount + m.nAmount
         ELSE
            INSERT INTO comptemp FROM MEMVAR
         ENDIF
      ENDSCAN

      swSelect('expcat')
      LOCATE FOR ccatcode = 'COMP'
      IF FOUND()
         IF THIS.ooptions.lacctdesc = .T. AND NOT EMPTY(cdescrip)
            m.csource = cdescrip
         ELSE
            m.csource = ccateg
         ENDIF
      ELSE
         m.csource   = 'Compression Charge'
      ENDIF

      SELE comptemp
      SCAN FOR cwellid == THIS.owellwork.cwellid
         m.cExpClass = cExpClass
         m.crptgroup = 'B'
         m.cTYPE     = 'OTH'
         m.cperiod   = ''
         m.cyear     = THIS.owellwork.hyear
         m.nprice    = 0
         m.nTOTAL    = comptemp.nAmount * -1
         m.nunits    = 0
         m.cwellid   = THIS.owellwork.cwellid

         DO CASE
            CASE m.cExpClass = '0'
               m.nRevInt = THIS.oinvtmp.nworkint
            CASE m.cExpClass = '1'
               m.nRevInt = THIS.oinvtmp.nintclass1
            CASE m.cExpClass = '2'
               m.nRevInt = THIS.oinvtmp.nintclass2
            CASE m.cExpClass = '3'
               m.nRevInt = THIS.oinvtmp.nintclass3
            CASE m.cExpClass = '4'
               m.nRevInt = THIS.oinvtmp.nintclass4
            CASE m.cExpClass = '5'
               m.nRevInt = THIS.oinvtmp.nintclass5
            CASE m.cExpClass = 'A'
               m.nRevInt = THIS.oinvtmp.nacpint
            CASE m.cExpClass = 'B'
               m.nRevInt = THIS.oinvtmp.nbcpint
            OTHERWISE
               m.nRevInt = THIS.oinvtmp.nrevgas
         ENDCASE
         m.crptgroup = 'B'
         m.cTYPE     = 'OTH'
         m.cperiod   = ''
         m.cyear     = THIS.owellwork.hyear
         m.nprice    = 0
         m.nunits    = 0
         m.cperiod   = THIS.owellwork.hperiod
         m.ninvamt   = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
         m.cDescript = ' '
         m.cownerid  = THIS.oinvtmp.cownerid
         m.nRunNo    = THIS.nRunNo
         m.crunyear  = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group B
         *********************************************************************************************************
         IF m.ninvamt # 0
            INSERT INTO statemnt FROM MEMVAR
            THIS.nwelltot = THIS.nwelltot + m.ninvamt
         ENDIF
      ENDSCAN
   ENDPROC

   *-- Calculates income section
   ***********************************************************************
   PROCEDURE calcincome
      ***********************************************************************
      LPARA m.cwellid, tnRunNo, tcRunYear, tcYear, tcPeriod, tdAcctDate, tcDeck
      LOCAL llUseDefaultPurch

      IF FILE('datafiles\purchdef.txt')
         llUseDefaultPurch = .T.
      ELSE
         llUseDefaultPurch = .F.
      ENDIF

      m.cdirect = THIS.oinvtmp.cdirect

      *  Manualtax never gets cleared out, so it was adding to entries from previous owners.
      *  Not a big deal until you have an exempt owner in the mix, and then it causes problems over a range of statements.
      SELECT manualTax
      DELETE ALL

      * Make sure expense tax code is not set for income
      STORE '' TO m.ctaxcode, m.ctaxdesc

      * If we're printing the report for a new run and the current
      * record didn't come from suspense then reset the runno parms
      IF EMPTY(THIS.oinvtmp.cSuspType) AND THIS.nRunNo = 0
         tnRunNo   = 0
         tcRunYear = '   '
      ENDIF

      * This entry came from prior suspense
      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + ;
         PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      SELE inctemp
      LOCATE FOR cwellid == m.cwellid AND cDeck == tcDeck AND ;
         IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0, nRunNo = tnRunNo AND crunyear = tcRunYear) AND ;
         cyear + cperiod = tcYear + tcPeriod
      IF NOT FOUND()

         *  Process revenue into temp cursor
         make_copy('Income', 'Inctemp')

         * If the revenue is being summarized by type and prod period create the summarized cursor
         IF THIS.lSumRev
            SELE * FROM income ;
               WHERE IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0 AND dRevDate <= tdAcctDate, nRunNo = tnRunNo AND crunyear = tcRunYear) ;
               AND cyear == tcYear AND cperiod == tcPeriod ;
               AND cwellid = m.cwellid ;
               AND cDeck == tcDeck ;
               INTO CURSOR inctmp READWRITE ;
               ORDER BY cwellid

            IF _TALLY > 0
               SELE inctmp
               SCAN
                  SCATTER MEMVAR
                  m.loneman = .F.
                  IF EMPTY(m.cownerid)
                     SELECT inctemp
                     IF NOT llUseDefaultPurch
                        LOCATE FOR cwellid == m.cwellid ;
                           AND csource == m.csource ;
                           AND cyear == m.cyear ;
                           AND cperiod == m.cperiod ;
                           AND cownerid == m.cownerid ;
                           AND crevkey == m.crevkey ;
                           AND cDeck == tcDeck
                     ELSE
                        LOCATE FOR cwellid == m.cwellid ;
                           AND csource == m.csource ;
                           AND cyear == m.cyear ;
                           AND cperiod == m.cperiod ;
                           AND cownerid == m.cownerid ;
                           AND cDeck == tcDeck
                     ENDIF
                     IF FOUND()
                        REPLACE nunits WITH nunits + m.nunits, ;
                           ntotalinc WITH ntotalinc + m.ntotalinc
                        * Calculate the price based on income/units
                        IF nunits # 0
                           REPLACE nprice WITH ROUND(ntotalinc / nunits, 4)
                        ENDIF
                     ELSE
                        INSERT INTO inctemp FROM MEMVAR
                     ENDIF
                  ELSE
                     INSERT INTO inctemp FROM MEMVAR
                  ENDIF
               ENDSCAN
               SELE inctemp
               INDEX ON cwellid TAG cwellid
               INDEX ON cyear + cperiod TAG yearprd
            ENDIF
         ELSE
            * Revenue is not being summarized. Get a cursor of valid data
            SELE * FROM income ;
               WHERE IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0 AND dRevDate <= tdAcctDate, nRunNo = tnRunNo AND crunyear = tcRunYear) ;
               AND cyear == tcYear AND cperiod == tcPeriod ;
               AND cwellid = m.cwellid ;
               AND cDeck == tcDeck ;
               INTO CURSOR inctemp READWRITE ;
               ORDER BY cwellid
            SELE inctemp
            REPLACE loneman WITH .F. ALL
            INDEX ON cwellid TAG cwellid
            INDEX ON cyear + cperiod TAG yearprd
         ENDIF
      ENDIF

      jflatcnt = 0
      STORE 0 TO THIS.ntotalbbl, THIS.ntotalmcf, jnrevoil, jnrevgas, jnworkint, ;
         THIS.noilamount, THIS.ngasamount, THIS.notheramount, THIS.ntotalother, THIS.ncompamount, THIS.ngathamount, ;
         jnrevoth, THIS.noiltax1, THIS.noiltax2, THIS.noiltax3, THIS.noiltax4, ;
         THIS.ngastax1, THIS.ngastax2, THIS.ngastax3, THIS.ngastax4, THIS.nothtax1, THIS.nothtax2, THIS.nothtax3, THIS.nothtax4
      STORE 0 TO m.noiltax1, m.ngastax1, m.nprodtax1, m.noiltax2, m.ngastax2, m.nprodtax2, ;
         M.noiltax3, m.ngastax3, m.nprodtax3, m.noiltax4, m.ngastax4, m.nprodtax4

      swSelect('income')
      IF EMPTY(THIS.oinvtmp.cSuspType)
         LOCATE FOR cwellid = m.cwellid AND cDeck == tcDeck  ;
            AND IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0 AND dRevDate <= tdAcctDate, nRunNo = tnRunNo AND crunyear = tcRunYear) ;
            AND cyear + cperiod = tcYear + tcPeriod
         IF NOT FOUND()
            RETURN .F.
         ENDIF
      ELSE
         LOCATE FOR cwellid == m.cwellid AND cDeck == tcDeck ;
            AND IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0 AND dRevDate <= tdAcctDate, ;
              nRunNo = THIS.oinvtmp.nRunNo_In AND crunyear = THIS.oinvtmp.cRunYear_In) ;
            AND cyear + cperiod = tcYear + tcPeriod
         IF THIS.oinvtmp.lmanual OR NOT FOUND()
            RETURN .F.
         ENDIF
      ENDIF

      m.cSuspType = THIS.oinvtmp.cSuspType

      swSelect('wells')
      LOCATE FOR cwellid = THIS.cwellid
      IF FOUND()
         THIS.ooptions.lroycomp = lexclroycomp
         llCalcComp             = lcompress
         llCalcGath             = lgather
      ELSE
         llCalcComp = .F.
         llCalcGath = .F.
      ENDIF

      SELECT inctemp
      SCAN
         m.crptgroup = 'B'
         m.cDescript = ' '
         m.nAmount   = 0
         IF NOT EMPTY(ndayson)
            m.ndayson   = ndayson
         ENDIF

         m.ntotalinc = inctemp.ntotalinc

         * This is for the Gathering Manager
         IF FILE('datafiles\bdoil.txt')
            m.dExpDate  = inctemp.dRevDate
            m.crefid    = inctemp.crefid
            m.cMiscMemo = ALLTRIM(m.crefid)
         ENDIF

         jnrevoil    = THIS.oinvtmp.nrevoil
         jnrevgas    = THIS.oinvtmp.nrevgas
         jnrevtax1   = THIS.oinvtmp.nrevtax1
         jnrevtax2   = THIS.oinvtmp.nrevtax2
         jnrevtax3   = THIS.oinvtmp.nrevtax3
         jnrevtax4   = THIS.oinvtmp.nrevtax4
         jnrevtax5   = THIS.oinvtmp.nrevtax5
         jnrevtax6   = THIS.oinvtmp.nrevtax6
         jnrevtax7   = THIS.oinvtmp.nrevtax7
         jnrevtax8   = THIS.oinvtmp.nrevtax8
         jnrevtax9   = THIS.oinvtmp.nrevtax9
         jnrevtax10  = THIS.oinvtmp.nrevtax10
         jnrevtax11  = THIS.oinvtmp.nrevtax11
         jnrevtax12  = THIS.oinvtmp.nrevtax12
         jnrevm1     = THIS.oinvtmp.nrevmisc1
         jnrevm2     = THIS.oinvtmp.nrevmisc2
         jnrevoth    = THIS.oinvtmp.nrevoth
         jnrevtrans  = THIS.oinvtmp.nrevtrp
         m.cprogcode = THIS.oinvtmp.cprogcode

         SELECT wells
         SET ORDER TO cwellid
         IF SEEK(THIS.oinvtmp.cwellid)
            llRoyExempt = lroysevtx
         ELSE
            llRoyExempt = .F.
         ENDIF
         IF 'TAX' $ inctemp.csource
            IF THIS.lownertaxexempt
               LOOP
            ENDIF
            IF llRoyExempt AND THIS.oinvtmp.cTypeInv # 'W'
               LOOP
            ENDIF
         ENDIF
         DO CASE
            CASE inctemp.cownerid = THIS.cownerid AND NOT inctemp.loneman

               * Check to see if the owner has multiple interests in the well
               * If so, allocate it to the working interest owner.
               IF m.cTypeInv # 'W'
                  swSelect('wellinv')
                  LOCATE FOR cownerid == THIS.cownerid AND cwellid == inctemp.cwellid AND cTypeInv = 'W'
                  IF FOUND()
                     LOOP
                  ENDIF
               ENDIF
               SELECT inctemp
               REPLACE loneman WITH .T.
               DO CASE
                  CASE inctemp.csource = 'BBL'
                     THIS.oinvtmp.nrevoil = 100
                  CASE inctemp.csource = 'EXO'
                     THIS.oinvtmp.nrevoil = 100
                  CASE inctemp.csource = 'MCF'
                     THIS.oinvtmp.nrevgas = 100
                  CASE inctemp.csource = 'OTH'
                     THIS.oinvtmp.nrevoth = 100
                  CASE inctemp.csource = 'TRANS'
                     THIS.oinvtmp.nrevtrp = 100
                  CASE inctemp.csource = 'EXG'
                     THIS.oinvtmp.nrevgas = 100
                  CASE inctemp.csource = 'OTAX1'
                     THIS.oinvtmp.nrevtax1 = 100
                  CASE inctemp.csource = 'GTAX1'
                     THIS.oinvtmp.nrevtax2 = 100
                  CASE inctemp.csource = 'PTAX1'
                     THIS.oinvtmp.nrevtax3 = 100
                  CASE inctemp.csource = 'OTAX2'
                     THIS.oinvtmp.nrevtax4 = 100
                  CASE inctemp.csource = 'GTAX2'
                     THIS.oinvtmp.nrevtax5 = 100
                  CASE inctemp.csource = 'PTAX2'
                     THIS.oinvtmp.nrevtax6 = 100
                  CASE inctemp.csource = 'OTAX3'
                     THIS.oinvtmp.nrevtax7 = 100
                  CASE inctemp.csource = 'GTAX3'
                     THIS.oinvtmp.nrevtax8 = 100
                  CASE inctemp.csource = 'PTAX3'
                     THIS.oinvtmp.nrevtax9 = 100
                  CASE inctemp.csource = 'OTAX4'
                     THIS.oinvtmp.nrevtax10 = 100
                  CASE inctemp.csource = 'GTAX4'
                     THIS.oinvtmp.nrevtax11 = 100
                  CASE inctemp.csource = 'PTAX4'
                     THIS.oinvtmp.nrevtax12 = 100
                  CASE INLIST(inctemp.csource, 'NOT', 'NTL', 'NTO', 'NTR', 'NTW')
                     THIS.oinvtmp.nRevInt = 100
                  CASE inctemp.csource = 'MISC1'
                     THIS.oinvtmp.nrevmisc1 = 100
                  CASE inctemp.csource = 'MISC2'
                     THIS.oinvtmp.nrevmisc2 = 100
                  CASE inctemp.csource = 'COMP'
                     THIS.oinvtmp.nrevmisc2 = 100
                  CASE inctemp.csource = 'GATH'
                     THIS.oinvtmp.nrevmisc2 = 100
               ENDCASE
            CASE EMPTY(inctemp.cownerid) OR cownerid = SPACE(10)

            CASE inctemp.cownerid = THIS.cownerid AND inctemp.loneman
               LOOP
         ENDCASE

         DO CASE
            CASE inctemp.csource = 'BBL'
               m.nRevInt       = THIS.oinvtmp.nrevoil
               THIS.ntotalbbl  = THIS.ntotalbbl + nunits
               THIS.noilamount = THIS.noilamount + m.ntotalinc
            CASE inctemp.csource = 'MCF'
               m.nRevInt       = THIS.oinvtmp.nrevgas
               THIS.ntotalmcf  = THIS.ntotalmcf + nunits
               THIS.ngasamount = THIS.ngasamount + m.ntotalinc
            CASE inctemp.csource = 'OTH'
               m.nRevInt         = THIS.oinvtmp.nrevoth
               THIS.ntotalother  = THIS.ntotalother + nunits
               THIS.notheramount = THIS.notheramount + m.ntotalinc
            CASE inctemp.csource = 'COMP'
               IF THIS.lroyaltyowner AND THIS.ooptions.lroycomp
                  m.nRevInt = 0
               ELSE
                  IF NOT THIS.lroyaltyowner AND THIS.ooptions.lroycomp
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt        = THIS.oinvtmp.nrevgas
                  ENDIF
               ENDIF
               THIS.ncompamount = THIS.ncompamount + m.ntotalinc
            CASE inctemp.csource = 'GATH'
               IF THIS.lroyaltyowner AND THIS.ooptions.lroycomp
                  m.nRevInt = 0
               ELSE
                  IF NOT THIS.lroyaltyowner AND THIS.ooptions.lroycomp
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt        = THIS.oinvtmp.nrevgas
                  ENDIF
               ENDIF
               THIS.ngathamount = THIS.ngathamount + m.ntotalinc
            CASE inctemp.csource = 'TRANS'
               m.nRevInt = THIS.oinvtmp.nrevtrp
            CASE inctemp.csource = 'NOT'
               m.nRevInt = 1
            CASE inctemp.csource = 'MISC1'
               m.nRevInt = THIS.oinvtmp.nrevmisc1
            CASE inctemp.csource = 'MISC2'
               m.nRevInt = THIS.oinvtmp.nrevmisc2
            CASE inctemp.csource = 'OTAX1'
               m.noiltax1 = m.noiltax1 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax1
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax1
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'GTAX1'
               m.ngastax1 = m.ngastax1 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax2
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax2
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'PTAX1'
               m.nprodtax1 = m.nprodtax1 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax3
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax3
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'OTAX2'
               m.noiltax2 = m.noiltax2 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax4
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax4
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'GTAX2'
               m.ngastax2 = m.ngastax2 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax5
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax5
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'PTAX2'
               m.nprodtax2 = m.nprodtax2 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax6
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax6
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'OTAX3'
               m.noiltax3 = m.noiltax3 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax7
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax7
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'GTAX3'
               m.ngastax3 = m.ngastax3 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax8
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax8
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'PTAX3'
               m.nprodtax3 = m.nprodtax3 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax9
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax9
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'OTAX4'
               m.noiltax4 = m.noiltax4 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax10
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax10
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'GTAX4'
               m.ngastax4 = m.ngastax4 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax11
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax11
                  ENDIF
               ENDIF
            CASE inctemp.csource = 'PTAX4'
               m.nprodtax4 = m.nprodtax4 + m.ntotalinc
               IF NOT THIS.lroyaltyowner
                  IF THIS.lexemptroyalty
                     m.nRevInt = THIS.oinvtmp.nworkint
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax12
                  ENDIF
               ELSE
                  IF THIS.lexemptroyalty
                     m.nRevInt = 0
                  ELSE
                     m.nRevInt = THIS.oinvtmp.nrevtax12
                  ENDIF
               ENDIF
         ENDCASE

         IF NOT EMPTY(inctemp.cownerid) AND inctemp.cownerid # THIS.cownerid
            LOOP
         ENDIF

         IF THIS.oinvtmp.ctypeint = 'O' AND INLIST(inctemp.csource, 'MCF', 'GTAX1', 'GTAX2', 'GTAX3', 'GTAX4', 'EXG')
            m.nRevInt            = 0
            THIS.oinvtmp.nrevgas = 0
         ENDIF
         IF THIS.oinvtmp.ctypeint = 'G' AND INLIST(inctemp.csource, 'BBL', 'OTAX1', 'OTAX2', 'OTAX3', 'OTAX4', 'EXO')
            m.nRevInt            = 0
            THIS.oinvtmp.nrevoil = 0
         ENDIF

         * Fill in the purchaser
         lcDefPurch = inctemp.crevkey
         IF llUseDefaultPurch
            swSelect('wells')
            SET ORDER TO cwellid
            IF SEEK(inctemp.cwellid)
               DO CASE
                  CASE inctemp.csource = 'MCF'
                     IF NOT EMPTY(wells.crevmcf)
                        lcDefPurch = wells.crevmcf
                     ENDIF
                  CASE inctemp.csource = 'BBL'
                     IF NOT EMPTY(wells.crevbbl)
                        lcDefPurch = wells.crevbbl
                     ENDIF
               ENDCASE
            ENDIF
         ENDIF
         swSelect('revsrc')
         SET ORDER TO crevkey
         IF SEEK(lcDefPurch)
            m.csource = revsrc.crevname
         ELSE
            swSelect('income')
            LOCATE FOR cwellid == inctemp.cwellid AND csource == inctemp.csource
            IF FOUND()
               m.crevkey = crevkey
               SELECT revsrc
               IF SEEK(m.crevkey)
                  m.csource = revsrc.crevname
               ELSE
                  m.csource = 'Unknown'
               ENDIF
            ENDIF
         ENDIF

         IF inctemp.csource = 'MCF'
            * Get the gathering and compression flags
            IF THIS.oinvtmp.ncompress # 0
               m.lcompress = .T.
            ELSE
               m.lcompress = .F.
            ENDIF
            IF THIS.oinvtmp.ngather # 0
               m.lgather = .T.
            ELSE
               m.lgather = .F.
            ENDIF

            * Calculate the compression and gathering per MCF for Suspense Entries
            IF m.lcompress AND THIS.oinvtmp.cSuspType # ' '
               IF inctemp.nunits # 0
                  SELECT wellwork
                  LOCATE FOR cwellid == THIS.cwellid AND crectype = 'R' ;
                     AND hyear   == THIS.oinvtmp.hyear ;
                     AND hperiod == THIS.oinvtmp.hperiod ;
                     AND cDeck   == THIS.oinvtmp.cDeck ;
                     AND nRunNo  == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.nRunNo_In, THIS.oinvtmp.nRunNo) ;
                     AND crunyear == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.cRunYear_In, THIS.oinvtmp.crunyear)
                  IF FOUND()
                     lnCompGross    = wellwork.ncompress
                     IF THIS.ncompress = 0
                        THIS.ncompress = lnCompGross / inctemp.nunits
                     ENDIF
                  ELSE
                     THIS.ncompress = 0
                  ENDIF
               ELSE
                  THIS.ncompress = 0
               ENDIF
            ENDIF

            IF m.lgather AND THIS.oinvtmp.cSuspType # ' '
               IF inctemp.nunits # 0
                  SELECT wellwork
                  LOCATE FOR cwellid == THIS.cwellid AND crectype = 'R' ;
                     AND hyear   == THIS.oinvtmp.hyear ;
                     AND hperiod == THIS.oinvtmp.hperiod ;
                     AND nRunNo  == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.nRunNo_In, THIS.oinvtmp.nRunNo) ;
                     AND crunyear == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.cRunYear_In, THIS.oinvtmp.crunyear)
                  IF FOUND()
                     lnGathGross  = wellwork.ngather
                     IF THIS.ngather = 0
                        THIS.ngather = lnGathGross / inctemp.nunits
                     ENDIF
                  ELSE
                     THIS.ngather = 0
                  ENDIF
               ELSE
                  THIS.ngather = 0
               ENDIF
            ENDIF
         ENDIF

         SELECT inctemp
         m.cTYPE   = inctemp.csource
         m.nunits  = inctemp.nunits
         m.nprice  = inctemp.nprice
         m.cperiod = inctemp.cperiod
         m.cyear   = inctemp.cyear
         m.crange  = ALLTRIM(inctemp.cbegrange) + '-' + ALLTRIM(inctemp.cendrange)
         IF inctemp.cbegrange = '  /  ' OR inctemp.cendrange = '  /  '
            m.crange = ''
         ENDIF

         IF (THIS.lroyaltyowner AND THIS.ooptions.lChgPrice) OR THIS.ooptions.lHideComp
            * If the price is zero then we can't adjust compression and gathering
            * through the price (if those options are enabled)
            IF m.nprice = 0
               IF m.nunits # 0 AND m.ntotalinc # 0
                  m.nprice = ROUND(m.ntotalinc / m.nunits, 4)
               ENDIF
            ENDIF

            jGross  = m.ntotalinc
            IF m.lcompress AND m.cTYPE = 'MCF'
               m.nprice = m.nprice - THIS.ncompress
               jGross   = jGross - ROUND(THIS.ncompress * nunits, 2)
            ENDIF
            IF m.lgather AND m.cTYPE = 'MCF'
               m.nprice = m.nprice - THIS.ngather
               jGross   = jGross - ROUND(THIS.ngather * nunits, 2)
            ENDIF
         ELSE
            jGross  = m.ntotalinc
         ENDIF
         *
         *  Check if this investor is a cDirect pay or a flat rate Royalty
         *

         DO CASE
            CASE INLIST(THIS.oinvtmp.cdirect, 'O', 'B') ;
                  AND INLIST(m.cTYPE, 'BBL', 'OTAX1', 'OTAX2', 'OTAX3', 'OTAX4', 'EXO') AND NOT THIS.oinvtmp.lFlat
               *
               *  Direct Paid Oil or Oil Taxes
               *
               m.ninvamt  = 0
               m.nTOTAL   = 0
               m.nWorkTot = 0
               DO CASE
                  CASE m.cTYPE = 'OTAX1'
                     IF m.lExempt
                        * Owner is exempt from tax. Zero out taxes
                        m.nWorkTot = 0
                        lnoiltax1  = 0
                     ELSE
                        IF NOT m.lSev1O
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold, so subtract it
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ELSE
                           * Purchaser pays revenue directly, so mark as directly paid
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold tax on directly paid owners
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ENDIF
                     ENDIF
                  CASE m.cTYPE = 'OTAX2'
                     IF m.lExempt
                        * Owner is exempt from tax. Zero out taxes
                        m.nWorkTot = 0
                        lnoiltax2  = 0
                     ELSE
                        IF NOT m.lSev2O
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold, so subtract it
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ELSE
                           * Purchaser pays directly, so mark as directly paid
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold tax on directly paid owners
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ENDIF
                     ENDIF
                  CASE m.cTYPE = 'OTAX3'
                     IF m.lExempt
                        * Owner is exempt from tax. Zero out taxes
                        m.nWorkTot = 0
                        lnoiltax3  = 0
                     ELSE
                        IF NOT m.lSev3O
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold, so subtract it
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ELSE
                           * Purchaser pay, so mark as directly paid
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold tax on directly paid owners
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ENDIF
                     ENDIF
                  CASE m.cTYPE = 'OTAX4'
                     IF m.lExempt
                        * Owner is exempt from tax. Zero out taxes
                        m.nWorkTot = 0
                        lnoiltax4  = 0
                     ELSE
                        IF NOT m.lSev4O
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold, so subtract it
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ELSE
                           * Purchaser pays directly, so mark as directly paid
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold tax on directly paid owners
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ENDIF
                     ENDIF
                  OTHERWISE
                     m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                     m.lDirect  = .T.
               ENDCASE
            CASE INLIST(THIS.oinvtmp.cdirect, 'G', 'B') AND INLIST(m.cTYPE, 'MCF', 'GTAX1', 'GTAX2', 'GTAX3', 'GTAX4', 'EXG') AND NOT THIS.oinvtmp.lFlat
               *
               *  Direct paid gas or gas taxes
               *
               m.ninvamt = 0
               m.nTOTAL  = 0
               DO CASE
                  CASE m.cTYPE = 'GTAX1'
                     IF m.lExempt
                        * Owner is exempt from tax. Zero out taxes
                        m.nWorkTot = 0
                        lngastax1  = 0
                     ELSE
                        IF NOT m.lSev1G
                           IF NOT m.lDirGasPurch
                              * Purchaser doesn't withhold, so subtract it
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ELSE
                           * Purchaser pays revenue directly, so mark as directly paid
                           IF NOT m.lDirGasPurch
                              * Purchaser doesn't withhold tax on directly paid owners
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ENDIF
                     ENDIF
                  CASE m.cTYPE = 'GTAX2'
                     IF m.lExempt
                        * Owner is exempt from tax. Zero out taxes
                        m.nWorkTot = 0
                        lngastax2  = 0
                     ELSE
                        IF NOT m.lSev2G
                           IF NOT m.lDirGasPurch
                              * Purchaser doesn't withhold, so subtract it
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ENDIF
                        ELSE
                           * Purchaser pays directly, so mark as directly paid
                           IF NOT m.lDirGasPurch
                              * Purchaser doesn't withhold tax on directly paid owners
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ENDIF
                     ENDIF
                  CASE m.cTYPE = 'GTAX3'
                     IF m.lExempt
                        * Owner is exempt from tax. Zero out taxes
                        m.nWorkTot = 0
                        lngastax3  = 0
                     ELSE
                        IF NOT m.lSev3G
                           IF NOT m.lDirGasPurch
                              * Purchaser doesn't withhold, so subtract it
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ELSE
                           * Purchaser pay, so mark as directly paid
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold tax on directly paid owners
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ENDIF
                     ENDIF
                  CASE m.cTYPE = 'GTAX4'
                     IF m.lExempt
                        * Owner is exempt from tax. Zero out taxes
                        m.nWorkTot = 0
                        lngastax4  = 0
                     ELSE
                        IF NOT m.lSev4G
                           IF NOT m.lDirGasPurch
                              * Purchaser doesn't withhold, so subtract it
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ELSE
                           * Purchaser pays directly, so mark as directly paid
                           IF NOT m.lDirOilPurch
                              * Purchaser doesn't withhold tax on directly paid owners
                              m.ninvamt  = SWROUND((jGross * (m.nRevInt / 100)), 2)
                           ELSE
                              * Purchaser withholds tax on direct paid revenue
                              m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                           ENDIF
                        ENDIF
                     ENDIF
                  OTHERWISE
                     m.nWorkTot = SWROUND(jGross * (m.nRevInt / 100), 2)
                     m.lDirect  = .T.
               ENDCASE
            CASE INLIST(THIS.oinvtmp.cdirect, 'G', 'B') AND m.cTYPE = 'MCF' AND THIS.oinvtmp.lFlat AND THIS.oinvtmp.ctypeint = 'G'
               IF jflatcnt = 0
                  m.ninvamt  = SWROUND(m.nflatrate * (THIS.oinvtmp.nworkint / 100), 2)
                  m.nTOTAL   = 0
                  m.nWorkTot = m.nflatrate
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot  = 0
                  m.cDescript = ' '
                  jflatcnt    = 1
               ELSE
                  m.ninvamt = 0
               ENDIF
            CASE INLIST(THIS.oinvtmp.cdirect, 'O', 'B') AND m.cTYPE = 'BBL' AND THIS.oinvtmp.lFlat AND THIS.oinvtmp.ctypeint = 'O'
               IF jflatcnt = 0
                  m.ninvamt  = SWROUND(m.nflatrate * (THIS.oinvtmp.nworkint / 100), 2)
                  m.nTOTAL   = 0
                  m.nWorkTot = m.nflatrate
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.cDescript = ' '
                  jflatcnt    = 1
               ELSE
                  m.ninvamt = 0
               ENDIF
            OTHERWISE
               m.lDirect = .F.
               IF NOT THIS.ooptions.lHideComp
                  IF THIS.lroyaltyowner AND THIS.ooptions.lChgPrice AND m.cTYPE = 'MCF'
                     *  If either one is zero, it's dumb to zero out the total
                     IF m.nunits # 0 AND m.nprice # 0
                        m.nTOTAL = m.nunits * m.nprice
                     ELSE
                        m.nTOTAL = jGross
                     ENDIF
                  ELSE
                     m.nTOTAL   = jGross             && Re-establish total
                  ENDIF
               ELSE
                  m.nTOTAL   = jGross             && Re-establish total
               ENDIF
               IF SUBST(m.cTYPE, 2, 3) = 'TAX'
                  IF NOT THIS.lownertaxexempt
                     m.ninvamt = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
                  ENDIF
               ELSE
                  m.ninvamt = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
               ENDIF

         ENDCASE
         IF NOT THIS.ooptions.lHideComp
            IF THIS.lroyaltyowner AND THIS.ooptions.lChgPrice
               *  If either one is zero, it's dumb to zero out the total
               IF m.nunits # 0 AND m.nprice # 0
                  m.nTOTAL = m.nunits * m.nprice
               ELSE
                  m.nTOTAL = jGross
               ENDIF
            ELSE
               m.nTOTAL   = jGross             && Re-establish total
            ENDIF
         ELSE
            m.nTOTAL   = jGross             && Re-establish total
         ENDIF

         THIS.ntotinc  = THIS.ntotinc + m.ninvamt
         THIS.nwelltot = THIS.nwelltot + m.ninvamt

         *
         *  Check to see if this investor gets gas or oil interest
         *  If not, don't show that nIncome on his cStatement
         *
         DO CASE
            CASE m.cTYPE = 'BBL' AND THIS.oinvtmp.nrevoil > 0
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.nWorkTot = 0
            CASE m.cTYPE = 'EXO' AND THIS.oinvtmp.nrevoil > 0
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.nWorkTot = 0
            CASE m.cTYPE = 'MCF' AND THIS.oinvtmp.nrevgas > 0
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.nWorkTot = 0
            CASE m.cTYPE = 'OTH' AND THIS.oinvtmp.nrevoth > 0
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.nWorkTot = 0
            CASE m.cTYPE = 'TRANS' AND THIS.oinvtmp.nrevtrp > 0
               m.cTYPE    = 'TRP'
               m.cdirect  = 'N'
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.nWorkTot = 0
               m.cTYPE    = 'TRANS'
            CASE m.cTYPE = 'MISC1' AND THIS.oinvtmp.nrevmisc1 > 0
               m.cTYPE    = 'MI1'
               m.cdirect  = 'N'
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.nWorkTot = 0
               m.cTYPE    = 'MISC1'
            CASE m.cTYPE = 'MISC2' AND THIS.oinvtmp.nrevmisc2 > 0
               m.cTYPE    = 'MI2'
               m.cdirect  = 'N'
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.nWorkTot = 0
               m.cTYPE    = 'MISC2'

            CASE m.cTYPE = 'COMP' AND m.ninvamt # 0
               m.cTYPE    = 'OTH'
               m.cdirect  = 'N'
               m.csource  = 'Compression Charge'
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.nWorkTot = 0

            CASE m.cTYPE = 'GATH' AND m.ninvamt # 0
               m.cTYPE    = 'OTH'
               m.cdirect  = 'N'
               m.csource  = 'Gathering Charge'
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.nWorkTot = 0

            CASE m.cTYPE = 'OTAX1' AND THIS.oinvtmp.nrevtax1 > 0
               THIS.noiltax1 = m.ninvamt
               THIS.noiltax1 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               IF m.cdirect = 'O' OR m.cdirect = 'B'
                  DO CASE
                     CASE THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cdirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                     CASE NOT THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cdirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                  ENDCASE
               ELSE
                  m.cdirect  = 'N'
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               m.cTYPE = 'OTAX1'
            CASE m.cTYPE = 'GTAX1' AND THIS.oinvtmp.nrevtax2 > 0

               THIS.ngastax1 = m.ninvamt
               THIS.ngastax1 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               IF m.cdirect = 'G' OR m.cdirect = 'B'
                  DO CASE
                     CASE THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                     CASE NOT THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                  ENDCASE
               ELSE
                  m.cdirect  = 'N'
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               m.cTYPE = 'GTAX1'
            CASE m.cTYPE = 'OTAX2' AND THIS.oinvtmp.nrevtax4 > 0
               THIS.noiltax2 = m.ninvamt
               THIS.noiltax2 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               IF m.cdirect = 'O' OR m.cdirect = 'B'
                  DO CASE
                     CASE THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                    m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                     CASE NOT THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                   m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                  ENDCASE
               ELSE
                  m.cdirect  = 'N'
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               m.cTYPE = 'OTAX2'
            CASE m.cTYPE = 'GTAX2' AND THIS.oinvtmp.nrevtax5 > 0
               THIS.ngastax2 = m.ninvamt
               THIS.ngastax2 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               IF m.cdirect = 'G' OR m.cdirect = 'B'
                  DO CASE
                     CASE THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                     CASE NOT THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                  ENDCASE
               ELSE
                  m.cdirect  = 'N'
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               m.cTYPE = 'GTAX2'
            CASE m.cTYPE = 'OTAX3' AND THIS.oinvtmp.nrevtax7 > 0
               THIS.noiltax3 = m.ninvamt
               THIS.noiltax3 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               *         m.ctype = 'TX7'
               IF m.cdirect = 'O' OR m.cdirect = 'B'
                  DO CASE
                     CASE THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                     CASE NOT THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                  ENDCASE
               ELSE
                  m.cdirect  = 'N'
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               m.cTYPE = 'OTAX3'
            CASE m.cTYPE = 'GTAX3' AND THIS.oinvtmp.nrevtax8 > 0
               THIS.ngastax3 = m.ninvamt
               THIS.ngastax3 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               *         m.ctype = 'TX8'
               IF m.cdirect = 'G' OR m.cdirect = 'B'
                  DO CASE
                     CASE THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                     CASE NOT THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                  ENDCASE
               ELSE
                  m.cdirect  = 'N'
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               m.cTYPE = 'GTAX3'
            CASE m.cTYPE = 'OTAX4' AND THIS.oinvtmp.nrevtax10 > 0
               THIS.noiltax4 = m.ninvamt
               THIS.noiltax4 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               *         m.ctype = 'TX10'
               IF m.cdirect = 'O' OR m.cdirect = 'B'
                  DO CASE
                     CASE THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                    m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                     CASE NOT THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                  ENDCASE
               ELSE
                  m.cdirect  = 'N'
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               m.cTYPE = 'OTAX4'
            CASE m.cTYPE = 'GTAX4' AND THIS.oinvtmp.nrevtax11 > 0
               THIS.ngastax4 = m.ninvamt
               THIS.ngastax4 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               *         m.ctype = 'TX11'
               IF m.cdirect = 'G' OR m.cdirect = 'B'
                  DO CASE
                     CASE THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                    m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                     CASE NOT THIS.lroyaltyowner
                        IF NOT THIS.lownertaxexempt
                           *                     m.cDirect = 'N'
                           m.cownerid = THIS.cownerid
                           m.nRunNo   = THIS.nRunNo
                           m.crunyear = THIS.crunyear
                           *********************************************************************************************************
                           *  Insert into the statement file  - Report Group B
                           *********************************************************************************************************
                           INSERT INTO statemnt FROM MEMVAR
                           m.nWorkTot = 0
                        ENDIF
                  ENDCASE
               ELSE
                  m.cdirect  = 'N'
                  m.cownerid = THIS.cownerid
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               m.cTYPE = 'GTAX4'
            CASE m.cTYPE = 'PTAX1' AND THIS.oinvtmp.nrevtax3 > 0
               THIS.nothtax1 = m.ninvamt
               THIS.nothtax1 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               *         m.ctype = 'TX3'
               m.cdirect  = 'N'
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.cTYPE = 'PTAX1'
            CASE m.cTYPE = 'PTAX2' AND THIS.oinvtmp.nrevtax6 > 0
               THIS.nothtax2 = m.ninvamt
               THIS.nothtax2 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               *         m.ctype = 'TX6'
               m.cdirect  = 'N'
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.cTYPE = 'PTAX2'
            CASE m.cTYPE = 'PTAX3' AND THIS.oinvtmp.nrevtax9 > 0
               THIS.nothtax3 = m.ninvamt
               THIS.nothtax3 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               *         m.ctype = 'TX9'
               m.cdirect  = 'N'
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.cTYPE = 'PTAX3'
            CASE m.cTYPE = 'PTAX4' AND THIS.oinvtmp.nrevtax12 > 0
               THIS.nothtax4 = m.ninvamt
               THIS.nothtax4 = m.nTOTAL

               swSelect('revcat')  &&  Plug in description from the revcat table, instead of using the purchaser name - BH 06/08/2004
               LOCATE FOR crevtype = m.cTYPE
               IF FOUND()
                  m.csource = revcat.cRevDesc
               ENDIF

               *         m.ctype = 'TX12'
               m.cdirect  = 'N'
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               m.cTYPE = 'PTAX4'
         ENDCASE

         * Restore original interests that may have been changed by one-man-item processing.
         THIS.oinvtmp.nrevoil   = jnrevoil
         THIS.oinvtmp.nrevgas   = jnrevgas
         THIS.oinvtmp.nrevoth   = jnrevoth
         THIS.oinvtmp.nrevtax1  = jnrevtax1
         THIS.oinvtmp.nrevtax2  = jnrevtax2
         THIS.oinvtmp.nrevtax3  = jnrevtax3
         THIS.oinvtmp.nrevtax4  = jnrevtax4
         THIS.oinvtmp.nrevtax5  = jnrevtax5
         THIS.oinvtmp.nrevtax6  = jnrevtax6
         THIS.oinvtmp.nrevtax7  = jnrevtax7
         THIS.oinvtmp.nrevtax8  = jnrevtax8
         THIS.oinvtmp.nrevtax9  = jnrevtax9
         THIS.oinvtmp.nrevtax10 = jnrevtax10
         THIS.oinvtmp.nrevtax11 = jnrevtax11
         THIS.oinvtmp.nrevtax12 = jnrevtax12
         THIS.oinvtmp.nrevmisc1 = jnrevm1
         THIS.oinvtmp.nrevmisc2 = jnrevm2
         THIS.oinvtmp.nrevtrp   = jnrevtrans
         m.cdirect              = THIS.oinvtmp.cdirect
      ENDSCAN && nIncome

      m.cyear   = tcYear
      m.cperiod = tcPeriod
      SELE manualTax
      LOCATE FOR cwellid == m.cwellid AND cyear == m.cyear AND cperiod == m.cperiod
      IF NOT FOUND()
         INSERT INTO manualTax FROM MEMVAR
      ELSE
         DO CASE
            CASE m.cTYPE = 'OTAX1'
               REPLACE noiltax1 WITH noiltax1 + m.noiltax1
            CASE m.cTYPE = 'OTAX2'
               REPLACE noiltax2 WITH noiltax2 + m.noiltax2
            CASE m.cTYPE = 'OTAX3'
               REPLACE noiltax3 WITH noiltax3 + m.noiltax3
            CASE m.cTYPE = 'OTAX4'
               REPLACE noiltax4 WITH noiltax4 + m.noiltax4
            CASE m.cTYPE = 'GTAX1'
               REPLACE ngastax1 WITH ngastax1 + m.ngastax1
            CASE m.cTYPE = 'GTAX2'
               REPLACE ngastax2 WITH ngastax2 + m.ngastax2
            CASE m.cTYPE = 'GTAX3'
               REPLACE ngastax3 WITH ngastax3 + m.ngastax3
            CASE m.cTYPE = 'GTAX4'
               REPLACE ngastax4 WITH ngastax4 + m.ngastax4
            CASE m.cTYPE = 'PTAX1'
               REPLACE nprodtax1 WITH nprodtax1 + m.nprodtax1
            CASE m.cTYPE = 'PTAX2'
               REPLACE nprodtax2 WITH nprodtax2 + m.nprodtax2
            CASE m.cTYPE = 'PTAX3'
               REPLACE nprodtax3 WITH nprodtax3 + m.nprodtax3
            CASE m.cTYPE = 'PTAX4'
               REPLACE nprodtax4 WITH nprodtax4 + m.nprodtax4
         ENDCASE
      ENDIF
   ENDPROC


   *-- Calculates tax section
   ***********************************************************************
   PROCEDURE calctaxes
      ***********************************************************************
      LPARA m.cwellid, tnRunNo, tcRunYear, tcYear, tcPeriod, tdAcctDate
      LOCAL m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4
      LOCAL m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4
      LOCAL m.nothtax1, m.nothtax2, m.nothtax3, m.nothtax4
      LOCAL m.nprodtax1, m.nprodtax2, m.nprodtax3, m.nprodtax4
      LOCAL m.noiltax1b, m.noiltax2b, m.noiltax3b, m.noiltax4b
      LOCAL m.ngastax1b, m.ngastax2b, m.ngastax3b, m.ngastax4b
      LOCAL m.nothtax1b, m.nothtax2b, m.nothtax3b, m.nothtax4b
      LOCAL m.nTaxBBL1, m.nTaxBBL2, m.nTaxBBL3, m.nTaxBBL4
      LOCAL m.nTaxMCF1, m.nTaxMCF2, m.nTaxMCF3, m.nTaxMCF4
      LOCAL m.cMethodBBL1, m.cMethodBBL2, m.cMethodBBL3, m.cMethodBBL4
      LOCAL m.cMethodMCF1, m.cMethodMCF2, m.cMethodMCF3, m.cMethodMCF4
      LOCAL m.cMethodOTH1, m.cMethodOTH2, m.cMethodOTH3, m.cMethodOTH4
      LOCAL m.cNameBBL1, m.cNameBBL2, m.cNameBBL3, m.cNameBBL4
      LOCAL m.cNameMCF1, m.cNameMCF2, m.cNameMCF3, m.cNameMCF4
      LOCAL m.cNameOTH1, m.cNameOTH2, m.cNameOTH3, m.cNameOTH4


      * Initialize Variables
      STORE 'Oil Taxes' TO m.cNameBBL1, m.cNameBBL2, m.cNameBBL3, m.cNameBBL4
      STORE 'Gas Taxes' TO m.cNameMCF1, m.cNameMCF2, m.cNameMCF3, m.cNameMCF4
      STORE 'Other Taxes' TO m.cNameOTH1, m.cNameOTH2, m.cNameOTH3, m.cNameOTH4
      STORE ' ' TO m.cMethodBBL1, m.cMethodBBL2, m.cMethodBBL3, m.cMethodBBL4
      STORE ' ' TO m.cMethodMCF1, m.cMethodMCF2, m.cMethodMCF3, m.cMethodMCF4
      STORE ' ' TO m.cMethodOTH1, m.cMethodOTH2, m.cMethodOTH3, m.cMethodOTH4
      STORE 0 TO m.nTaxBBL1, m.nTaxBBL2, m.nTaxBBL3, m.nTaxBBL4
      STORE 0 TO m.nTaxMCF1, m.nTaxMCF2, m.nTaxMCF3, m.nTaxMCF4

      SELECT invtmp
      SCATTER MEMVAR
      SELECT wellwork
      LOCATE FOR cwellid == THIS.cwellid AND crectype = 'R' ;
         AND hyear   == THIS.oinvtmp.hyear ;
         AND hperiod == THIS.oinvtmp.hperiod ;
         AND cDeck   == THIS.oinvtmp.cDeck ;
         AND nRunNo  == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.nRunNo_In, THIS.oinvtmp.nRunNo) ;
         AND crunyear == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.cRunYear_In, THIS.oinvtmp.crunyear)
      IF NOT FOUND()
         RETURN
      ENDIF
      SCATTER NAME THIS.owellwork

      * Make sure expense tax code is not set for taxes
      STORE '' TO m.ctaxcode, m.ctaxdesc

      * Look for the manually entered taxes for this well and period
      * Manually entered taxes have to be subtracted from the wellwork
      * total before the owner's share is calculated. The manually entered
      * taxes have already been added to the statemnt table in calcincome.
      SELE manualTax
      LOCATE FOR cwellid == THIS.cwellid AND cyear == THIS.cyear AND cperiod == THIS.cperiod
      IF FOUND()
         SCATTER MEMVAR
      ELSE
         STORE 0 TO m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4
         STORE 0 TO m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4
         STORE 0 TO m.nothtax1, m.nothtax2, m.nothtax3, m.nothtax4
         STORE 0 TO m.nprodtax1, m.nprodtax2, m.nprodtax3, m.nprodtax4
      ENDIF

      *  Check for one man item taxes for this well and owner
      SELECT one_man_tax
      LOCATE FOR cownerid == THIS.cownerid AND cwellid = THIS.cwellid ;
         AND hyear = THIS.cyear AND hperiod = THIS.cperiod ;
         AND crunyear = THIS.crunyear AND nRunNo = THIS.nRunNo
      IF FOUND()
         m.noiltax1b  = noiltax1b
         m.noiltax2b  = noiltax2b
         m.noiltax3b  = noiltax3b
         m.noiltax4b  = noiltax4b
         m.ngastax1b  = ngastax1b
         m.ngastax2b  = ngastax2b
         m.ngastax3b  = ngastax3b
         m.ngastax4b  = ngastax4b
         m.nprodtax1b = nprodtax1b
         m.nprodtax2b = nprodtax2b
         m.nprodtax3b = nprodtax3b
         m.nprodtax4b = nprodtax4b
      ELSE
         STORE 0 TO m.noiltax1b, m.noiltax2b, m.noiltax3b, m.noiltax4b
         STORE 0 TO m.ngastax1b, m.ngastax2b, m.ngastax3b, m.ngastax4b
         STORE 0 TO m.nprodtax1b, m.nprodtax2b, m.nprodtax3b, m.nprodtax4b
      ENDIF

      IF invtmp.nsevtaxes # 0
         STORE 0 TO lnoiltax1, lnoiltax2, lnoiltax3, lnoiltax4
         STORE 0 TO lngastax1, lngastax2, lngastax3, lngastax4
         STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4

         swSelect('wells')
         LOCATE FOR cwellid = THIS.cwellid
         SCATTER MEMVAR

         * Don't do anything with taxes here if the table
         * is empty on the well record.
         IF EMPTY(m.ctable) AND NOT m.lusesev
            RETURN
         ENDIF

         * Set the lusesev flag if the wellwork fields ntotmcftxr, ntotmcftxw, ntotbbltxr, ntotbbltxw have a value in them.
         * The flag could have been set in the well record when the run was closed but not set now when you're trying to
         * print a previous statement.
         IF THIS.owellwork.ntotmcftxr # 0 OR ;
               THIS.owellwork.ntotmcftxw # 0 OR ;
               THIS.owellwork.ntotbbltxr # 0 OR ;
               THIS.owellwork.ntotbbltxw # 0
            m.lusesev = .T.
         ENDIF

         lntaxes = 0
         swSelect('sevtax')
         SET ORDER TO ctable
         IF SEEK(m.ctable)
            SCATTER MEMVAR

            * Zero out rates if the purchaser is withholding
            * No calculations should be done in this case.
            IF m.lSev1O AND THIS.nRunNo = 0
               m.nTaxBBL1    = 0
               m.cMethodBBL1 = ' '
            ENDIF
            IF m.lSev2O AND THIS.nRunNo = 0
               m.nTaxBBL2    = 0
               m.cMethodBBL2 = ' '
            ENDIF
            IF m.lSev3O AND THIS.nRunNo = 0
               m.nTaxBBL3    = 0
               m.cMethodBBL3 = ' '
            ENDIF
            IF m.lSev4O AND THIS.nRunNo = 0
               m.nTaxBBL4    = 0
               m.cMethodBBL4 = ' '
            ENDIF
            IF m.lSev1G
               m.nTaxMCF1    = 0
               m.cMethodMCF1 = ' '
            ENDIF
            IF m.lSev2G
               m.nTaxMCF2    = 0
               m.cMethodMCF2 = ' '
            ENDIF
            IF m.lSev3G
               m.nTaxMCF3    = 0
               m.cMethodMCF3 = ' '
            ENDIF
            IF m.lSev4G
               m.nTaxMCF4    = 0
               m.cMethodMCF4 = ' '
            ENDIF
         ELSE
            IF NOT m.lusesev
               RETURN
            ELSE
               STORE 'Oil Taxes' TO m.cNameBBL1, m.cNameBBL2, m.cNameBBL3, m.cNameBBL4
               STORE 'Gas Taxes' TO m.cNameMCF1, m.cNameMCF2, m.cNameMCF3, m.cNameMCF4
               STORE 'Other Taxes' TO m.cNameOTH1, m.cNameOTH2, m.cNameOTH3, m.cNameOTH4
               STORE ' ' TO m.cMethodBBL1, m.cMethodBBL2, m.cMethodBBL3, m.cMethodBBL4
               STORE ' ' TO m.cMethodMCF1, m.cMethodMCF2, m.cMethodMCF3, m.cMethodMCF4
               STORE ' ' TO m.cMethodOTH1, m.cMethodOTH2, m.cMethodOTH3, m.cMethodOTH4
               STORE 0 TO m.nTaxBBL1, m.nTaxBBL2, m.nTaxBBL3, m.nTaxBBL4
               STORE 0 TO m.nTaxMCF1, m.nTaxMCF2, m.nTaxMCF3, m.nTaxMCF4
            ENDIF
         ENDIF

         IF m.lusesev
            STORE 0 TO m.nTaxBBL1, m.nTaxMCF1
            IF EMPTY(m.cNameMCF1)
               STORE 'Gas Taxes' TO m.cNameMCF1
            ENDIF
            IF EMPTY(m.cNameBBL1)
               STORE 'Oil Taxes' TO m.cNameBBL1
            ENDIF
            STORE ' ' TO m.cMethodBBL1
            STORE ' ' TO m.cMethodMCF1
            m.cMethod = 'W'
         ENDIF
         m.crptgroup = 'B'
         m.cyear     = m.hyear
         m.cperiod   = m.hperiod
         *!*       m.cyear     = THIS.cYear
         m.cprogcode = THIS.oinvtmp.cprogcode
         IF THIS.lownertaxexempt             && Owner is Tax Exempt
            m.ninvamt = 0
            STORE 0 TO lnoiltax1, lnoiltax2, lnoiltax3, lnoiltax4
            STORE 0 TO lngastax1, lngastax2, lngastax3, lngastax4
            STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
         ELSE
            *  If the owner has an oil interest, process oil taxes
            IF INLIST(THIS.oinvtmp.ctypeint, 'B', 'O')
               m.nbblinc = THIS.noilamount
               m.nunits  = THIS.ntotalbbl

               IF m.lusesev  && Override state severance tax table rates
                  IF THIS.noiltax1 = 0
                     IF THIS.lroyaltyowner
                        lnoiltax1  = SWROUND(((THIS.owellwork.ngrossoil * (m.nroysevo / 100)) * (m.nrevoil / 100)), 2)
                        STORE 0 TO lnoiltax2, lnoiltax3, lnoiltax4
                     ELSE
                        lnoiltax1  = SWROUND(((THIS.owellwork.ngrossoil * (m.nwrksevo / 100)) * (m.nrevoil / 100)), 2)
                        STORE 0 TO lnoiltax2, lnoiltax3, lnoiltax4
                     ENDIF
                  ENDIF
               ELSE
                  * If royalty owners are exempt, working interest owner takes full
                  * working interest share of severance tax.
                  IF THIS.lexemptroyalty
                     IF NOT THIS.lroyaltyowner
                        STORE m.nworkint TO m.nrevtax1, m.nrevtax4, m.nrevtax7, m.nrevtax10
                     ELSE
                        m.ninvamt = 0
                        STORE 0 TO lnoiltax1, lnoiltax2, lnoiltax3, lnoiltax4
                        STORE 0 TO lngastax1, lngastax2, lngastax3, lngastax4
                        STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
                     ENDIF
                  ENDIF
                  IF INLIST(m.cdirect, 'B', 'O')  && Direct Paid
                     lnPct = m.nrevtax1
                     IF NOT m.lSev1O OR NOT THIS.nRunNo = 0
                        IF NOT m.lDirOilPurch
                           * If this is a NM well and we're using the alternate calculation,
                           * gross up the tax pct to account for exempt owners. This is only
                           * valid for tax 1.
                           *!*                         IF m.cstate = 'NM' AND FILE(m.goapp.cCommonFolder+'nm.cfg')
                           *!*                            lnPct = THIS.odist.grossuptaxpct(m.cwellid,lnPct,'O')
                           *!*                         ENDIF
                           lnoiltax1  = (SWROUND((THIS.owellwork.ngbbltax1 + m.noiltax1 - m.noiltax1b) * (lnPct / 100), 2)) + m.noiltax1b
                           m.nrevtax1 = lnPct
                           lntaxes    = lntaxes + lnoiltax1
                        ELSE
                           m.nWorkTot = (SWROUND((THIS.owellwork.ngbbltax1 + m.noiltax1 - m.noiltax1b) * (lnPct / 100), 2)) + m.noiltax1b
                           lnoiltax1  = 0
                        ENDIF
                     ELSE
                        lnoiltax1 = 0
                     ENDIF
                  ELSE        && Not Direct Paid
                     IF THIS.oinvtmp.noiltax1 # 0
                        IF NOT m.lSev1O OR NOT THIS.nRunNo = 0
                           * Save the original tax pct
                           lnPct = m.nrevtax1
                           * If this is a NM well and we're using the alternate calculation,
                           * gross up the tax pct to account for exempt owners. This is only
                           * valid for tax 1.
                           *!*                   IF m.cstate = 'NM' AND FILE(m.goapp.cCommonFolder+'nm.cfg')
                           *!*                      lnPct = THIS.odist.grossuptaxpct(m.cwellid,lnPct,'O')
                           *!*                   ENDIF
                           lnoiltax1  = (SWROUND((THIS.owellwork.ngbbltax1 + m.noiltax1 - m.noiltax1b) * (lnPct / 100), 2)) + m.noiltax1b
                           m.nrevtax1 = lnPct
                           lntaxes    = lntaxes + lnoiltax1
                        ELSE
                           lnoiltax1  = 0
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'O')  && Direct Paid
               IF NOT m.lSev2O
                  IF NOT m.lDirOilPurch
                     lnoiltax2 = (SWROUND((THIS.owellwork.ngbbltax2 + m.noiltax2 - m.noiltax2b) * (m.nrevtax4 / 100), 2)) + m.noiltax2b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngbbltax2 + m.noiltax2 - m.noiltax2b) * (m.nrevtax4 / 100), 2)) + m.noiltax2b
                     lnoiltax2  = 0
                  ENDIF
               ELSE
                  lnoiltax2 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev2O
                  lnoiltax2 = 0
               ELSE
                  IF THIS.oinvtmp.noiltax2 # 0
                     lnoiltax2 = (SWROUND((THIS.owellwork.ngbbltax2 + m.noiltax2 - m.noiltax2b) * (m.nrevtax4 / 100), 2)) + m.noiltax2b
                     lntaxes   = lntaxes + lnoiltax2
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'O')  && Direct Paid
               IF NOT m.lSev3O
                  IF NOT m.lDirOilPurch
                     lnoiltax3 = (SWROUND((THIS.owellwork.ngbbltax3 + m.noiltax3 - m.noiltax3b) * (m.nrevtax7 / 100), 2)) + m.noiltax3b
                     lntaxes   = lntaxes + lnoiltax3
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngbbltax3 + m.noiltax3 - m.noiltax3b) * (m.nrevtax7 / 100), 2)) + m.noiltax3b
                     lnoiltax3  = 0
                  ENDIF
               ELSE
                  lnoiltax3 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev3O
                  lnoiltax3 = 0
               ELSE
                  IF THIS.oinvtmp.noiltax3 # 0
                     lnoiltax3 = (SWROUND((THIS.owellwork.ngbbltax3 + m.noiltax3 - m.noiltax3b) * (m.nrevtax7 / 100), 2)) + m.noiltax3b
                     lntaxes   = lntaxes + lnoiltax3
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'O')  && Direct Paid
               IF NOT m.lSev4O
                  IF NOT m.lDirOilPurch
                     lnoiltax4 = (SWROUND((THIS.owellwork.ngbbltax4 + m.noiltax4 - m.noiltax4b) * (m.nrevtax10 / 100), 2)) + m.noiltax4b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngbbltax4 + m.noiltax4 - m.noiltax4b) * (m.nrevtax10 / 100), 2)) + m.noiltax4b
                     lnoiltax4  = 0
                  ENDIF
               ELSE
                  lnoiltax4 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev4O
                  lnoiltax4 = 0
               ELSE
                  IF THIS.oinvtmp.noiltax4 # 0
                     lnoiltax4 = (SWROUND((THIS.owellwork.ngbbltax4 + m.noiltax4 - m.noiltax4b) * (m.nrevtax10 / 100), 2)) + m.noiltax4b
                     lntaxes   = lntaxes + lnoiltax4
                  ENDIF
               ENDIF
            ENDIF

            IF THIS.lroyaltyowner AND THIS.lexemptroyalty
               STORE 0 TO lnoiltax1, lnoiltax2, lnoiltax3, lnoiltax4
            ENDIF

            * Check for well being exempt from certain taxes and zero out
            * those taxes when appropriate
            IF m.lTaxExempt1
               lnoiltax1 = 0
            ENDIF
            IF m.lTaxExempt2
               lnoiltax2 = 0
            ENDIF
            IF m.lTaxExempt3
               lnoiltax3 = 0
            ENDIF
            IF m.lTaxExempt4
               lnoiltax4 = 0
            ENDIF

            IF lnoiltax1 + lnoiltax2 + lnoiltax3 + lnoiltax4 + m.nWorkTot # 0
               THIS.nwelltot = THIS.nwelltot - lnoiltax1 - lnoiltax2 - lnoiltax3 - lnoiltax4
               m.cownerid    = THIS.cownerid
               IF lnoiltax1 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'OTAX1'
                  m.csource = m.cNameBBL1
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  IF NOT m.lusesev
                     m.cMethod  = m.cMethodBBL1
                  ENDIF
                  * If the well is a NM well and we're using the alternate tax calculation,
                  * remove the tax exempt owner's portion of the revenue.
                  *!*                IF m.cstate = 'NM' AND FILE(m.goapp.cCommonFolder+'nm.cfg')
                  *!*                   m.ctaxable = THIS.odist.removetaxexempt(m.cwellid,'BBL',THIS.oWellWork.nGrossOil)
                  *!*                ELSE
                  m.cTaxable = THIS.owellwork.ngrossoil
                  *!*                ENDIF
                  m.ninvamt  = lnoiltax1 * -1
                  IF m.lusesev
                     IF THIS.lroyaltyowner
                        m.nprice = m.nroysevo / 100
                        m.nTOTAL = SWROUND((THIS.owellwork.ngrossoil * (m.nroysevo / 100)), 2) * -1
                     ELSE
                        m.nprice = m.nwrksevo / 100
                        m.nTOTAL = SWROUND((THIS.owellwork.ngrossoil * (m.nwrksevo / 100)), 2) * -1
                     ENDIF
                  ELSE
                     m.nprice   = m.nTaxBBL1
                     *  Remove any manually entered taxes from calculated total
                     m.nTOTAL   = (THIS.owellwork.ngbbltax1 + m.noiltax1) * -1
                  ENDIF
                  IF NOT m.lusesev
                     m.nRevInt  = m.nrevtax1
                  ELSE
                     m.nRevInt  = m.nrevoil
                  ENDIF
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  m.nunits   = THIS.owellwork.ntotbbl
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lnoiltax2 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'OTAX2'
                  m.csource = m.cNameBBL2
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod = m.cMethodBBL2
                  *                     m.ctaxable = THIS.oWellWork.ngbbltax2/m.nTaxBBL2
                  m.cTaxable = THIS.owellwork.ngrossoil
                  m.ninvamt  = lnoiltax2 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nTOTAL   = (THIS.owellwork.ngbbltax2 + m.noiltax2) * -1
                  m.nprice   = m.nTaxBBL2
                  m.nRevInt  = m.nrevtax4
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  m.nunits   = THIS.owellwork.ntotbbl
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lnoiltax3 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'OTAX3'
                  m.csource = m.cNameBBL3
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod = m.cMethodBBL3
                  *                     m.ctaxable = THIS.oWellWork.ngbbltax3/m.nTaxBBL3
                  m.cTaxable = THIS.owellwork.ngrossoil
                  m.ninvamt  = lnoiltax3 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nTOTAL   = (THIS.owellwork.ngbbltax3 + m.noiltax3) * -1
                  m.nprice   = m.nTaxBBL3
                  m.nRevInt  = m.nrevtax7
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  m.nunits   = THIS.owellwork.ntotbbl
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lnoiltax4 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'OTAX4'
                  m.csource = m.cNameBBL4
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod = m.cMethodBBL4
                  *                     m.ctaxable = THIS.oWellWork.ngbbltax4/m.nTaxBBL4
                  m.cTaxable = THIS.owellwork.ngrossoil
                  m.ninvamt  = lnoiltax4 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nTOTAL   = (THIS.owellwork.ngbbltax4 + m.noiltax4) * -1
                  m.nprice   = m.nTaxBBL4
                  m.nRevInt  = m.nrevtax10
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  m.nunits   = THIS.owellwork.ntotbbl
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
            ENDIF
         ENDIF


         IF INLIST(THIS.oinvtmp.ctypeint, 'B', 'G')
            IF m.lusesev  && Use state severance tax table rates
               m.cMethod = 'W'
               IF THIS.ngastax1 = 0
                  IF THIS.lroyaltyowner
                     lngastax1  = SWROUND(((THIS.owellwork.ngrossgas * (m.nroysevg / 100)) * (m.nrevgas / 100)), 2)
                     STORE 0 TO lngastax2, lngastax3, lngastax4
                  ELSE
                     lngastax1  = SWROUND(((THIS.owellwork.ngrossgas * (m.nwrksevg / 100)) * (m.nrevgas / 100)), 2)
                     STORE 0 TO lngastax2, lngastax3, lngastax4
                  ENDIF
               ENDIF
            ELSE
               * If royalty owners are exempt, working interest owner takes full
               * working interest share of severance tax.
               IF THIS.lexemptroyalty AND NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax2, m.nrevtax5, m.nrevtax8, m.nrevtax11
               ENDIF
               IF INLIST(m.cdirect, 'B', 'G')  && Direct Paid
                  lnPct = m.nrevtax2
                  IF NOT m.lSev1G
                     IF NOT m.lDirGasPurch
                        * If this is a NM well and we're using the alternate calculation,
                        * gross up the tax pct to account for exempt owners. This is only
                        * valid for tax 1.
                        *!*                      IF m.cstate = 'NM' AND FILE(m.goapp.cCommonFolder+'nm.cfg')
                        *!*                         lnPct = THIS.odist.grossuptaxpct(m.cwellid,lnPct,'O')
                        *!*                      ENDIF
                        lngastax1  = (SWROUND((THIS.owellwork.ngmcftax1 + m.ngastax1 - m.ngastax1b) * (lnPct / 100), 2)) + m.ngastax1b
                        m.nrevtax2 = lnPct
                        lntaxes    = lntaxes + lnoiltax1
                     ELSE
                        m.nWorkTot = (SWROUND((THIS.owellwork.ngmcftax1 + m.ngastax1 - m.ngastax1b) * (lnPct / 100), 2)) + m.ngastax1b
                        lngastax1  = 0
                     ENDIF
                  ELSE
                     lngastax1 = 0
                  ENDIF
               ELSE        && Not Direct Paid
                  IF THIS.oinvtmp.ngastax1 # 0
                     * Save the original tax pct
                     lnPct = m.nrevtax2
                     * If this is a NM well and we're using the alternate calculation,
                     * gross up the tax pct to account for exempt owners. This is only
                     * valid for tax 1.
                     *!*                IF m.cstate = 'NM' AND FILE(m.goapp.cCommonFolder+'nm.cfg')
                     *!*                   lnPct = THIS.odist.grossuptaxpct(m.cwellid,lnPct,'O')
                     *!*                ENDIF
                     lngastax1  = (SWROUND((THIS.owellwork.ngmcftax1 + m.ngastax1 - m.ngastax1b) * (lnPct / 100), 2)) + m.ngastax1b
                     m.nrevtax2 = lnPct
                     lntaxes    = lntaxes + lngastax1
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'G')  && Direct Paid
               IF NOT m.lSev2G
                  IF NOT m.lDirGasPurch
                     lngastax2 = (SWROUND((THIS.owellwork.ngmcftax2 + m.ngastax2 - m.ngastax2b) * (m.nrevtax5 / 100), 2)) + m.ngastax2b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngmcftax2 + m.ngastax2 - m.ngastax2b) * (m.nrevtax5 / 100), 2)) + m.ngastax2b
                     lngastax2  = 0
                  ENDIF
               ELSE
                  lngastax2 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev2G
                  lngastax2 = 0
               ELSE
                  IF THIS.oinvtmp.ngastax2 # 0
                     lngastax2 = (SWROUND((THIS.owellwork.ngmcftax2 + m.ngastax2 - m.ngastax2b) * (m.nrevtax5 / 100), 2)) + m.ngastax2b
                     lntaxes   = lntaxes + lngastax2
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'G')  && Direct Paid
               IF NOT m.lSev3G
                  IF NOT m.lDirGasPurch
                     lngastax3 = (SWROUND((THIS.owellwork.ngmcftax3 + m.ngastax3 - m.ngastax3b) * (m.nrevtax8 / 100), 2)) + m.ngastax3b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngmcftax3 + m.ngastax3 - m.ngastax3b) * (m.nrevtax8 / 100), 2)) + m.ngastax3b
                     lngastax3  = 0
                  ENDIF
               ELSE
                  lngastax3 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev3G
                  lngastax3 = 0
               ELSE
                  IF THIS.oinvtmp.ngastax3 # 0
                     lngastax3 = (SWROUND((THIS.owellwork.ngmcftax3 + m.ngastax3 - m.ngastax3b) * (m.nrevtax8 / 100), 2)) + m.ngastax3b
                     lntaxes   = lntaxes + lngastax3
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'G')  && Direct Paid
               IF NOT m.lSev4G
                  IF NOT m.lDirGasPurch
                     lngastax4 = (SWROUND((THIS.owellwork.ngmcftax4 + m.ngastax4 - m.ngastax4b) * (m.nrevtax11 / 100), 2)) + m.ngastax4b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngmcftax4 + m.ngastax4 - m.ngastax4b) * (m.nrevtax11 / 100), 2)) + m.ngastax4b
                     lngastax4  = 0
                  ENDIF
               ELSE
                  lngastax4 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev4G
                  lngastax4 = 0
               ELSE
                  IF THIS.oinvtmp.ngastax4 # 0
                     lngastax4 = (SWROUND((THIS.owellwork.ngmcftax4 + m.ngastax4 - m.ngastax4b) * (m.nrevtax11 / 100), 2)) + m.ngastax4b
                     lntaxes   = lntaxes + lngastax4
                  ENDIF
               ENDIF
            ENDIF

            *  If royalty owners are exempt from the severance tax, don't
            *  show a share for them.
            IF THIS.lexemptroyalty AND THIS.lroyaltyowner
               STORE 0 TO lngastax1, lngastax2, lngastax3, lngastax4
            ENDIF

            * Check for well being exempt from certain taxes and zero out
            * those taxes when appropriate
            IF m.lTaxExempt1
               lngastax1 = 0
            ENDIF
            IF m.lTaxExempt2
               lngastax2 = 0
            ENDIF
            IF m.lTaxExempt3
               lngastax3 = 0
            ENDIF
            IF m.lTaxExempt4
               lngastax4 = 0
            ENDIF

            IF lngastax1 + lngastax2 + lngastax3 + lngastax4 + m.nWorkTot # 0
               *!*                      IF (m.cDirect = 'G' OR m.cDirect = 'B')
               *!*                         THIS.nWellTot = THIS.nWellTot
               *!*                      ELSE
               THIS.nwelltot = THIS.nwelltot - lngastax1 - lngastax2 - lngastax3 - lngastax4
               *!*                      ENDIF
               m.cownerid = THIS.cownerid
               IF lngastax1 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'GTAX1'
                  m.csource = m.cNameMCF1
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  IF NOT m.lusesev
                     m.cMethod  = m.cMethodMCF1
                  ENDIF
                  * If this is a NM well and we're using the alternate tax calculation,
                  * remove the tax exempt owner's share of gas revenue.
                  *!*                IF m.cstate = 'NM' AND FILE(m.goapp.cCommonFolder+'nm.cfg')
                  *!*                   m.ctaxable = THIS.odist.removetaxexempt(m.cwellid,'MCF',THIS.oWellWork.nGrossGas)
                  *!*                ELSE
                  m.cTaxable = THIS.owellwork.ngrossgas
                  *!*                ENDIF

                  m.ninvamt  = lngastax1 * -1
                  IF m.lusesev
                     IF THIS.lroyaltyowner
                        m.nprice = m.nroysevg / 100
                        m.nTOTAL = SWROUND((THIS.owellwork.ngrossgas * (m.nroysevg / 100)), 2) * -1
                     ELSE
                        m.nprice = m.nwrksevg / 100
                        m.nTOTAL = SWROUND((THIS.owellwork.ngrossgas * (m.nwrksevg / 100)), 2) * -1
                     ENDIF
                  ELSE
                     *  Remove any manually entered taxes from calculated total
                     m.nTOTAL = (THIS.owellwork.ngmcftax1 + m.ngastax1) * -1
                     m.nprice = m.nTaxMCF1
                  ENDIF
                  IF NOT m.lusesev
                     m.nRevInt  = m.nrevtax2
                  ELSE
                     m.nRevInt  = m.nrevgas
                  ENDIF
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  m.nunits   = THIS.owellwork.ntotmcf
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lngastax2 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'GTAX2'
                  m.csource = m.cNameMCF2
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod = m.cMethodMCF2
                  *                     m.ctaxable = THIS.oWellWork.nTotMCFtx2/m.nTaxMCF2
                  m.cTaxable = THIS.owellwork.ngrossgas
                  m.ninvamt  = lngastax2 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nTOTAL   = (THIS.owellwork.ngmcftax2 + m.ngastax2) * -1
                  m.nprice   = m.nTaxMCF2
                  m.nRevInt  = m.nrevtax5
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  m.nunits   = THIS.owellwork.ntotmcf
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lngastax3 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'GTAX3'
                  m.csource = m.cNameMCF3
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod = m.cMethodMCF3
                  *                     m.ctaxable = THIS.oWellWork.nTotMCFtx3/m.nTaxMCF3
                  m.cTaxable = THIS.owellwork.ngrossgas
                  m.ninvamt  = lngastax3 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nTOTAL   = (THIS.owellwork.ngmcftax3 + m.ngastax3) * -1
                  m.nprice   = m.nTaxMCF3
                  m.nRevInt  = m.nrevtax8
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  m.nunits   = THIS.owellwork.ntotmcf
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lngastax4 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'GTAX4'
                  m.csource = m.cNameMCF4
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod = m.cMethodMCF4
                  *                     m.ctaxable = THIS.oWellWork.nTotMCFtx4/m.nTaxMCF4
                  m.cTaxable = THIS.owellwork.ngrossgas
                  m.ninvamt  = lngastax4 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nTOTAL   = (THIS.owellwork.ngmcftax4 + m.ngastax4) * -1
                  m.nprice   = m.nTaxMCF4
                  m.nRevInt  = m.nrevtax11
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  m.nunits   = THIS.owellwork.ntotmcf
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
            ENDIF
         ENDIF
         *
         *  Calculate other product taxes
         *

         *  The ngOthTax1-4 variables in wellhist don't contain any one-man OTH taxes, so this was changed to not subtract it from the
         *  (THIS.owellwork.ngothtax1+m.nothtax1) calculation like OTAX and GTAX. - BH 10/28/2009

         IF m.lSev1P
            lnothtax1 = 0
         ELSE
            * If royalty owners are exempt, working interest owner takes full
            * working interest share of severance tax.
            IF THIS.lexemptroyalty
               IF NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax3, m.nrevtax6, m.nrevtax9, m.nrevtax12
               ELSE
                  m.ninvamt = 0
                  STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
               ENDIF
            ENDIF
            lnothtax1 = (SWROUND((THIS.owellwork.ngothtax1 + m.nprodtax1 - m.nprodtax1b) * (m.nrevtax3 / 100), 2)) + m.nprodtax1b
            lntaxes   = lntaxes + lnothtax1
         ENDIF
         IF m.lSev2P
            lnothtax2 = 0
         ELSE
            * If royalty owners are exempt, working interest owner takes full
            * working interest share of severance tax.
            IF THIS.lexemptroyalty
               IF NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax3, m.nrevtax6, m.nrevtax9, m.nrevtax12
               ELSE
                  m.ninvamt = 0
                  STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
               ENDIF
            ENDIF

            lnothtax2 = (SWROUND((THIS.owellwork.ngothtax2 + m.nprodtax2 - m.nprodtax2b) * (m.nrevtax6 / 100), 2)) + m.nprodtax2b
            lntaxes   = lntaxes + lnothtax2
         ENDIF
         IF m.lSev3P
            lnothtax3 = 0
         ELSE
            * If royalty owners are exempt, working interest owner takes full
            * working interest share of severance tax.
            IF THIS.lexemptroyalty
               IF NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax3, m.nrevtax6, m.nrevtax9, m.nrevtax12
               ELSE
                  m.ninvamt = 0
                  STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
               ENDIF
            ENDIF

            lnothtax3 = (SWROUND((THIS.owellwork.ngothtax3 + m.nprodtax3 - m.nprodtax3b) * (m.nrevtax9 / 100), 2)) + m.nprodtax3b
            lntaxes   = lntaxes + lnothtax3
         ENDIF
         IF m.lSev4P
            lnothtax4 = 0
         ELSE
            * If royalty owners are exempt, working interest owner takes full
            * working interest share of severance tax.
            IF THIS.lexemptroyalty
               IF NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax3, m.nrevtax6, m.nrevtax9, m.nrevtax12
               ELSE
                  m.ninvamt = 0
                  STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
               ENDIF
            ENDIF

            lnothtax4 = (SWROUND((THIS.owellwork.ngothtax4 + m.nprodtax4 - m.nprodtax4b) * (m.nrevtax12 / 100), 2)) + m.nprodtax4b
            lntaxes   = lntaxes + lnothtax4
         ENDIF

         * Check for well being exempt from certain taxes and zero out
         * those taxes when appropriate
         IF m.lTaxExempt1
            lnothtax1 = 0
         ENDIF
         IF m.lTaxExempt2
            lnothtax2 = 0
         ENDIF
         IF m.lTaxExempt3
            lnothtax3 = 0
         ENDIF
         IF m.lTaxExempt4
            lnothtax4 = 0
         ENDIF

         IF lnothtax1 + lnothtax2 + lnothtax3 + lnothtax4 # 0
            THIS.nwelltot = THIS.nwelltot - lnothtax1 - lnothtax2 - lnothtax3 - lnothtax4
            m.cownerid    = THIS.cownerid
            IF lnothtax1 # 0
               m.cTYPE    = 'PTAX1'
               m.csource  = m.cNameOTH1
               m.crange   = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
               m.cMethod  = m.cMethodOTH1
               m.cTaxable = THIS.owellwork.nOthInc
               m.ninvamt  = lnothtax1 * -1
               *  Remove any manually entered taxes from calculated total
               m.nTOTAL   = (THIS.owellwork.ntotothtx1 + m.nprodtax1) * -1
               m.nprice   = m.ntaxoth1
               m.nRevInt  = m.nrevtax3
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               m.nunits   = THIS.owellwork.ntotprod
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
            ENDIF
            IF lnothtax2 # 0
               m.cTYPE    = 'PTAX2'
               m.csource  = m.cNameOTH2
               m.crange   = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
               m.cMethod  = m.cMethodOTH2
               m.cTaxable = THIS.owellwork.nOthInc
               m.ninvamt  = lnothtax2 * -1
               *  Remove any manually entered taxes from calculated total
               m.nTOTAL   = (THIS.owellwork.ntotothtx2 + m.nprodtax2) * -1
               m.nprice   = m.ntaxoth2
               m.nRevInt  = m.nrevtax6
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               m.nunits   = THIS.owellwork.ntotprod
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
            ENDIF
            IF lnothtax3 # 0
               m.cTYPE    = 'PTAX3'
               m.csource  = m.cNameOTH3
               m.crange   = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
               m.cMethod  = m.cMethodOTH3
               m.cTaxable = THIS.owellwork.nOthInc
               m.ninvamt  = lnothtax3 * -1
               *  Remove any manually entered taxes from calculated total
               m.nTOTAL   = (THIS.owellwork.ntotothtx3 + m.nprodtax3) * -1
               m.nprice   = m.ntaxoth3
               m.nRevInt  = m.nrevtax9
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               m.nunits   = THIS.owellwork.ntotprod
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
            ENDIF
            IF lnothtax4 # 0
               m.cTYPE    = 'PTAX4'
               m.csource  = m.cNameOTH4
               m.crange   = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
               m.cMethod  = m.cMethodOTH4
               m.cTaxable = THIS.owellwork.nOthInc
               m.ninvamt  = lnothtax4 * -1
               *  Remove any manually entered taxes from calculated total
               m.nTOTAL   = (THIS.owellwork.ntotothtx4 + m.nprodtax4) * -1
               m.nprice   = m.ntaxoth4
               m.nRevInt  = m.nrevtax12
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               m.nunits   = THIS.owellwork.ntotprod
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
            ENDIF
         ENDIF
      ENDIF
   ENDPROC


   *-- Calculates expense section
   ***********************************************************************
   PROCEDURE CalcExpense
      ***********************************************************************
      LPARA tnRunNo, tcYear, tcProdYear, tcProdPrd, tdAcctDate, tcDeck
      LOCAL lcScan, tcYear, tcRunYear, llReturn

      llReturn = .F.


      * If we're printing the report for a new run and the current
      * record didn't come from suspense then reset the runno parms
      IF EMPTY(THIS.oinvtmp.cSuspType) AND THIS.lNewRun
         tnRunNo   = 0
         tcRunYear = '   '
      ELSE
         tcRunYear = tcYear
      ENDIF

      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      SELE exptemp
      LOCATE FOR cwellid == THIS.oinvtmp.cwellid AND cDeck == tcDeck AND ;
         IIF(THIS.lNewRun AND NOT llSuspense, nrunnorev = 0, nrunnorev = tnRunNo AND crunyearrev = tcRunYear) ;
         AND cyear + cperiod = tcProdYear + tcProdPrd
      IF NOT FOUND()
         IF THIS.lSumExp         && Summarize expenses
            IF THIS.lchksubtot
               lcOrderBy = 'expense.cwellid, expense.cDeck, expcat.ctaxcode, expense.ccateg, expense.cexpclass, expense.cownerid'
            ELSE
               lcOrderBy = 'expense.cwellid, expense.cDeck, expense.ccateg, expense.cexpclass, expense.cownerid'
            ENDIF
            SELECT  expense.cwellid, ;
                    expense.cDeck, ;
                    expense.ccateg, ;
                    expcat.ctaxcode, ;
                    expcat.lRevenueDed, ;
                    taxcodes.cDesc AS ctaxdesc, ;
                    expense.cyear, ;
                    expense.cperiod, ;
                    expense.crefid, ;
                    expense.dExpDate, ;
                    SUM(expense.nAmount) AS nAmount, ;
                    expense.cpayee, ;
                    SPACE(60) AS cmemo, ;
                    expense.cvendorid, ;
                    expense.cpaidbyck, ;
                    expense.cExpClass, ;
                    nsaltwater, ;
                    cprdpaid, ;
                    expense.ccatcode, ;
                    lfixed, ;
                    laptran, ;
                    cbatch, ;
                    cownerid, ;
                    .F. AS loneman, ;
                    expcat.cdescrip, ;
                    nrunnorev, ;
                    crunyearrev ;
                FROM expense ;
                JOIN expcat ;
                    ON expense.ccatcode = expcat.ccatcode, taxcodes ;
                WHERE cwellid == THIS.oinvtmp.cwellid ;
                    AND cDeck == tcDeck ;
                    AND IIF(THIS.lNewRun ;
                      AND NOT llSuspense, nrunnorev = 0 ;
                      AND dExpDate <= THIS.dExpDate, nrunnorev = tnRunNo ;
                      AND crunyearrev = tcYear) ;
                    AND cyear + cperiod = tcProdYear + tcProdPrd ;
                    AND NOT INLIST(expense.ccatcode, 'MKTG', 'COMP', 'GATH') ;
                    AND expense.cyear # 'FIXD' ;
                    AND expcat.ctaxcode = taxcodes.ctaxcode ;
                    AND expense.ccatcode NOT IN(SELECT  ccatcode ;
                                                    FROM expcat ;
                                                    WHERE lJIBOnly) ;
                INTO CURSOR exptemp1 ;
                ORDER BY &lcOrderBy ;
                GROUP BY &lcOrderBy
            lcselect = 'exptemp'
         ELSE
            IF THIS.lchksubtot
               lcOrderBy = 'expense.cwellid, expense.cDeck, expcat.ctaxcode, expense.cYear, expense.cPeriod, expense.dexpdate'
            ELSE
               lcOrderBy = 'expense.cwellid, expense.cDeck, expense.cYear, expense.cPeriod, expense.dexpdate'
            ENDIF
            SELECT  expense.cwellid, ;
                    expense.cDeck, ;
                    expense.ccateg, ;
                    expcat.ctaxcode, ;
                    expcat.lRevenueDed, ;
                    taxcodes.cDesc AS ctaxdesc, ;
                    expense.cyear, ;
                    expense.cperiod, ;
                    expense.crefid, ;
                    expense.dExpDate, ;
                    expense.nAmount, ;
                    expense.ccatcode, ;
                    expense.cpayee, ;
                    expense.cmemo, ;
                    expense.cvendorid, ;
                    expense.cpaidbyck, ;
                    expense.cExpClass, ;
                    nsaltwater, ;
                    cprdpaid, ;
                    lfixed, ;
                    laptran, ;
                    cbatch, ;
                    cownerid, ;
                    .F. AS loneman, ;
                    expcat.cdescrip, ;
                    nrunnorev, ;
                    crunyearrev ;
                FROM expense ;
                JOIN expcat ;
                    ON expense.ccatcode = expcat.ccatcode, taxcodes ;
                WHERE cwellid == THIS.oinvtmp.cwellid ;
                    AND cDeck == tcDeck ;
                    AND IIF(THIS.lNewRun ;
                      AND NOT llSuspense, nrunnorev = 0 ;
                      AND dExpDate <= THIS.dExpDate, nrunnorev = tnRunNo ;
                      AND crunyearrev = tcYear) ;
                    AND cyear + cperiod = tcProdYear + tcProdPrd ;
                    AND NOT INLIST(expense.ccatcode, 'MKTG', 'COMP', 'GATH') ;
                    AND expense.cyear # 'FIXD' ;
                    AND expcat.ctaxcode = taxcodes.ctaxcode ;
                    AND expense.ccatcode NOT IN(SELECT  ccatcode ;
                                                    FROM expcat ;
                                                    WHERE lJIBOnly) ;
                INTO CURSOR exptemp1 ;
                ORDER BY &lcOrderBy
         ENDIF

         CREATE CURSOR exptemp ;
            (cwellid    C(10), ;
              cDeck       C(10), ;
              ccatcode   C(4), ;
              ccateg     C(60), ;
              ctaxcode   C(2), ;
              ctaxdesc  C(40), ;
              lRevenueDed L, ;
              cyear      C(4), ;
              cperiod    C(2), ;
              crefid     C(20), ;
              dExpDate   D, ;
              nAmount    N(12, 2), ;
              cpayee     C(60), ;
              cmemo      C(60), ;
              cvendorid  C(10), ;
              cpaidbyck  C(8), ;
              cExpClass  C(1), ;
              nsaltwater I, ;
              cprdpaid   C(6), ;
              lfixed     L, ;
              laptran    L, ;
              cbatch     C(8), ;
              cownerid   C(10), ;
              loneman    L, ;
              cdescrip   C(60), ;
              nrunnorev  I, ;
              crunyearrev C(4), ;
              lused      L)

         SELE exptemp
         APPEND FROM DBF('exptemp1')

         SELE exptemp
         REPL lused WITH .F. ALL
      ENDIF

      SELE exptemp
      IF EMPTY(THIS.oinvtmp.cSuspType)
         LOCATE FOR cwellid == m.cwellid AND ;
            cDeck == tcDeck AND ;
            IIF(THIS.lNewRun AND NOT llSuspense, nrunnorev = 0 AND dExpDate <= THIS.dExpDate, nrunnorev = tnRunNo AND crunyearrev = tcRunYear) AND cyear + cperiod = tcProdYear + tcProdPrd
         IF NOT FOUND()
            RETURN .F.
         ENDIF
      ELSE
         LOCATE FOR cwellid == m.cwellid AND ;
            cDeck == tcDeck AND ;
            IIF(THIS.lNewRun AND NOT llSuspense, nrunnorev = 0 AND dExpDate <= THIS.dExpDate, nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In) AND cyear + cperiod = tcProdYear + tcProdPrd
         IF THIS.oinvtmp.lmanual OR NOT FOUND()
            RETURN .F.
         ENDIF
      ENDIF



      ************************************************
      *  Process Class 0 Expenses
      ************************************************      
      IF THIS.oinvtmp.nexpense # 0
         llReturn = THIS.ProcessExp('0', THIS.oinvtmp.nworkint, THIS.oinvtmp.nexpense)
      ENDIF

      ************************************************
      *  Process Class 1 Expenses
      ************************************************      
      IF THIS.oinvtmp.ntotale1 # 0
         llReturn = THIS.ProcessExp('1', THIS.oinvtmp.nintclass1, THIS.oinvtmp.ntotale1)
      ENDIF

      ************************************************
      *  Process Class 2 Expenses
      ************************************************      
      IF THIS.oinvtmp.ntotale2 # 0
         llReturn = THIS.ProcessExp('2', THIS.oinvtmp.nintclass2, THIS.oinvtmp.ntotale2)
      ENDIF

      ************************************************
      *  Process Class 3 Expenses
      ************************************************      
      IF THIS.oinvtmp.ntotale3 # 0
         llReturn = THIS.ProcessExp('3', THIS.oinvtmp.nintclass3, THIS.oinvtmp.ntotale3)
      ENDIF

      ************************************************
      *  Process Class 4 Expenses
      ************************************************      
      IF THIS.oinvtmp.ntotale4 # 0
         llReturn = THIS.ProcessExp('4', THIS.oinvtmp.nintclass4, THIS.oinvtmp.ntotale4)
      ENDIF

      ************************************************
      *  Process Class 5 Expenses
      ************************************************      
      IF THIS.oinvtmp.ntotale5 # 0
         llReturn = THIS.ProcessExp('5', THIS.oinvtmp.nintclass5, THIS.oinvtmp.ntotale5)
      ENDIF

      ************************************************
      *  Process Class A Expenses
      ************************************************      
      IF THIS.oinvtmp.nTotaleA # 0
         llReturn = THIS.ProcessExp('A', THIS.oinvtmp.nacpint, THIS.oinvtmp.nTotaleA)
      ENDIF


      ************************************************
      *  Process Class B Expenses
      ************************************************      
      IF THIS.oinvtmp.nTotaleB # 0
         llReturn = THIS.ProcessExp('B', THIS.oinvtmp.nbcpint, THIS.oinvtmp.nTotaleB)
      ENDIF


      ************************************************
      *  Process Plugging Expenses
      ************************************************      
      IF THIS.oinvtmp.nPlugExp # 0
         llReturn = THIS.ProcessExp('B', THIS.oinvtmp.nPlugPct, THIS.oinvtmp.nPlugExp)
      ENDIF


      RETURN (llReturn)
   ENDPROC


   ***********************************************************************
   PROCEDURE ProcessExp
      ***********************************************************************
      LPARAMETERS tcClass, tnPct, tnAmount
      LOCAL llReturn, lnInterest

      llReturn = .T.

      IF THIS.lSumExp
         lcScan = 'cwellid == THIS.oInvTmp.cwellid AND cDeck == this.oInvTmp.cDeck AND NOT lUsed AND ' + ;
            "cexpclass = tcClass AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
      ELSE
         lcScan = 'cwellid == THIS.oInvTmp.cwellid AND ' + ;
            'cDeck == this.oInvTmp.cDeck AND ' + ;
            '(cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
            "cexpclass = tcClass AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') AND NOT lUsed"
      ENDIF

      LOCATE FOR &lcScan
      IF FOUND()
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            m.cCategory    = m.ccateg

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = tnPct
            lnInterest     = tnPct

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W' AND cDeck == tcDeck
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  lnInterest = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  IF tnPct = 0
                     LOOP
                  ENDIF
            ENDCASE

            llReturn = .T.
            SELE exptemp
            IF tnPct # 0
               REPL lused WITH .T.
            ENDIF


            IF exptemp.lRevenueDed
               m.crptgroup = 'B'
               m.cTYPE     = 'OTH'
               m.cdirect   = 'N'
               m.csource   = m.cCategory
               m.cownerid  = THIS.cownerid
               m.nRunNo    = THIS.nRunNo
               m.crunyear  = THIS.crunyear
               * Calculate the owner's share of the expense
               m.ninvamt   = SWROUND(m.nAmount * (lnInterest / 100), 2)
               * Calculate the running well total of income - expenses
               THIS.nwelltot = THIS.nwelltot - m.ninvamt
               m.nTOTAL      = tnAmount * -1
               m.ninvamt     = m.ninvamt * -1
            ELSE
               m.crptgroup = 'D'

               * Report Category Descript instead of category name
               IF THIS.ooptions.lacctdesc AND NOT EMPTY(m.cdescrip)
                  m.cCategory = m.cdescrip
               ENDIF

               *  Use the item description from the A/P bill for the category.
               IF THIS.ooptions.lbilldesc AND NOT EMPTY(m.cmemo)
                  m.cCategory = m.cmemo
                  m.cmemo     = ''
               ENDIF

               *  Include the reference id on the expense line
               IF THIS.ooptions.lrefid
                  IF NOT EMPTY(m.cmemo)
                     m.cMiscMemo = ALLTRIM(m.crefid) + ' - ' + ALLTRIM(m.cmemo)
                  ELSE
                     m.cMiscMemo = ALLTRIM(m.crefid)
                  ENDIF
               ENDIF

               *  Print the vendor's name on the expense line
               IF THIS.ooptions.lshowvendor
                  m.cMiscMemo = m.cpayee
               ENDIF

               * Calculate the owner's share of the expense
               m.ninvamt   = SWROUND(m.nAmount * (lnInterest / 100), 2)

               * Calculate the running well total of income - expenses
               THIS.nwelltot  = THIS.nwelltot - m.ninvamt

               m.cTYPE = 'EXP'

               * Reset the owner id before saving to the statemnt table
               m.cownerid  = THIS.cownerid
               m.nRunNo    = THIS.nRunNo
               m.crunyear  = THIS.crunyear
               m.cprogcode = THIS.oinvtmp.cprogcode
            ENDIF


            * Only insert a record if the expense line is non-zero
            IF m.ninvamt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group D
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
            ENDIF

            STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo

         ENDSCAN  && Exptemp
      ENDIF

      RETURN llReturn

      ***********************************************************************
   PROCEDURE flatowner
      ***********************************************************************
      LPARAMETERS tlSuspense, tcRunYear, tnRunNo
      *
      * Get the flat rates that should be charged agains the current owner
      *

      * If the invtmp record is from suspense we need to make sure that we
      * only get on flat rate per run in suspense.
      IF tlSuspense
         IF NOT USED('flatrates')
            * Create cursor to keep track of what we've processed
            CREATE CURSOR flatrates ;
               (crunyear   C(4), ;
                 nRunNo     I, ;
                 cwellid   C(10), ;
                 cownerid  C(10))
            m.crunyear = tcRunYear
            m.nRunNo   = tnRunNo
            m.cownerid = THIS.cownerid
            m.cwellid  = THIS.cwellid
            INSERT INTO flatrates FROM MEMVAR
         ELSE
            * Check to see if this run has been processed for a flat rate yet
            SELECT flatrates
            LOCATE FOR cownerid == THIS.cownerid AND crunyear == tcRunYear AND nRunNo == tnRunNo AND cwellid = THIS.cwellid
            IF FOUND()
               RETURN
            ELSE
               m.hyear    = THIS.oinvtmp.hyear
               m.hperiod  = THIS.oinvtmp.hperiod
               m.nRunNo   = tnRunNo
               m.crunyear = tcRunYear
               INSERT INTO flatrates FROM MEMVAR
            ENDIF
         ENDIF
      ENDIF

      * Only allocate flat rates once (This is non suspense processing)
      IF NOT tlSuspense AND THIS.lflatalloc = .T.
         RETURN
      ENDIF

      *
      *  Get flat-rate Royalty nAmounts for current well
      *
      STORE 0 TO jnflatgas, jnflatoil

      *  If the run is closed, get the flat rates from well history
      IF NOT THIS.lNewRun
         swSelect('wellhist')
         LOCATE FOR cwellid = THIS.cwellid AND nRunNo = tnRunNo AND crunyear = tcRunYear ;
            AND hyear + hperiod = THIS.oinvtmp.hyear + THIS.oinvtmp.hperiod
         IF FOUND()
            jnflatgas = nflatgas
            jnflatoil = nflatoil
         ENDIF
      ELSE
         * The run isn't closed so get the flat rates from wellinv
         jnflatgas = THIS.odist.getflatamt(THIS.cwellid, 'G')
         jnflatoil = THIS.odist.getflatamt(THIS.cwellid, 'O')
      ENDIF

      *************************************************************
      *  Process flat-rate royalties
      *************************************************************
      IF jnflatgas # 0 AND NOT THIS.lroyaltyowner
         m.cTYPE     = 'FLT'
         m.csource   = 'Gas Royalties'
         m.nTOTAL    = jnflatgas * -1
         m.nRevInt   = invtmp.nworkint
         jwrk        = jnflatgas * (invtmp.nworkint / 100)
         m.ninvamt   = jwrk * -1
         m.nincome   = m.ninvamt
         m.cyear     = THIS.oinvtmp.hyear
         m.cperiod   = THIS.oinvtmp.hperiod
         m.cdirect   = THIS.oinvtmp.cdirect
         m.crptgroup = 'B'
         m.cownerid  = THIS.oinvtmp.cownerid
         m.nRunNo    = THIS.nRunNo
         m.crunyear  = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group B
         *********************************************************************************************************
         IF m.ninvamt # 0
            INSERT INTO statemnt FROM MEMVAR
         ENDIF

         m.cDescript   = ' '
         THIS.ntotinc  = THIS.ntotinc + m.ninvamt
         THIS.nwelltot = THIS.nwelltot + m.ninvamt
      ENDIF

      IF jnflatoil # 0 AND NOT THIS.lroyaltyowner
         m.cTYPE     = 'FLT'
         m.csource   = 'Oil Royalties'
         m.nTOTAL    = jnflatoil * -1
         m.nRevInt   = invtmp.nworkint
         jwrk        = jnflatoil * (invtmp.nworkint / 100)
         m.ninvamt   = jwrk * -1
         m.cdirect   = THIS.oinvtmp.cdirect
         m.crptgroup = 'B'
         m.cownerid  = THIS.oinvtmp.cownerid
         m.nRunNo    = THIS.nRunNo
         m.crunyear  = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group B
         *********************************************************************************************************
         IF m.ninvamt # 0
            INSERT INTO statemnt FROM MEMVAR
         ENDIF
         m.cDescript   = ' '
         THIS.ntotinc  = THIS.ntotinc + m.ninvamt
         THIS.nwelltot = THIS.nwelltot + m.ninvamt
      ENDIF

      THIS.lflatalloc = .T.
   ENDPROC

   ***********************************************************************
   PROCEDURE getrange
      ***********************************************************************
      *========================================================================================
      *  Program....: GETRANGE.PRG
      *  Version....: 2.5
      *  Author.....: Phil W. Sherwood
      *  Date.......: February 13, 1994
      *  Notice.....: Copyright (c) 1996 SherWare, Inc., All Rights Reserved.
      *  Compiler...: FoxPro 2.6a
      *) Description: Retrieves well period range information from prdrange file.
      *  Parameters.:
      *  Changes....:
      *    03/31/96   pws - Changed to update the prdrange file instead of the well file.
      *    02/14/97   pws - Changed the way the range is calculated.  Calculate the range by
      *                     looking at last periods range and adding 1 to the end.
      *    12/08/98   pws - Changed for new wellrng file.
      *========================================================================================
      LPARA tcPeriod, tcYear, tcType, tcWellId
      LOCAL ldDate1, lcDate1, lcDate2, lcYear, lcRange1, lcRange2, llCalcRange
      LOCAL m.cRange1, m.cRange2

      ldDate1   = tcPeriod + '/01/' + tcYear
      m.cRange1 = LEFT(ldDate1, 5)
      ldDate1   = GOMONTH(CTOD(ldDate1), 1) - 1
      lcDate1   = DTOC(ldDate1)
      m.cRange2 = LEFT(lcDate1, 5)

      IF TYPE('tcYear') = 'C'
         lcYear = tcYear
      ELSE
         lcYear = STR(YEAR(DATE()), 4)
      ENDIF

      IF tcPeriod = '01'
         lcPrd = '12'
         lcYr  = STR(VAL(tcYear) - 1, 4)
      ELSE
         lcPrd = PADL(ALLTRIM(STR(VAL(tcPeriod) - 1, 2)), 2, '0')
         lcYr  = tcYear
      ENDIF

      swSelect('options')
      GO TOP
      llCalcRange = lCalcRange

      SELECT wellrng
      SET ORDER TO wellprd
      IF SEEK (tcWellId + tcYear + tcPeriod)
         DO CASE
            CASE tcType = 'O'
               m.cRange1 = oprng1
               m.cRange2 = oprng2
            CASE tcType = 'G'
               m.cRange1 = gprng1
               m.cRange2 = gprng2
         ENDCASE
      ELSE
         DO CASE
            CASE tcType = 'O'
               IF llCalcRange
                  IF SEEK(tcWellId + lcYr + lcPrd)
                     ldDate1   = CTOD(cRange2 + '/' + lcYr)
                     lcDate1   = DTOC(ldDate1 + 1)
                     lcDate2   = DTOC(ldDate1 + 31)
                     lcRange1  = LEFT(lcDate1, 5)
                     lcRange2  = LEFT(lcDate2, 5)
                     m.cRange1 = lcRange1
                     m.cRange2 = lcRange2
                  ENDIF
               ENDIF
            CASE tcType = 'G'
               IF llCalcRange
                  IF SEEK(tcWellId + lcYr + lcPrd)
                     ldDate1   = CTOD(cRange2 + '/' + lcYr)
                     lcDate1   = DTOC(ldDate1 + 1)
                     lcDate2   = DTOC(ldDate1 + 31)
                     lcRange1  = LEFT(lcDate1, 5)
                     lcRange2  = LEFT(lcDate2, 5)
                     m.cRange1 = lcRange1
                     m.cRange2 = lcRange2
                  ENDIF
               ENDIF
         ENDCASE
      ENDIF

      RETURN (m.cRange1 + m.cRange2)
   ENDPROC

   ***********************************************************************
   PROCEDURE susprelbal
      ***********************************************************************
      * Show released suspense balance

      m.nWellNet   = 0
      m.nProgNet   = 0
      lnSuspRelamt = 0
      *
      *  Look for any program deficits that are being covered.
      *
      llCheckAmt = .F.
      SELECT statemnt
      SCAN FOR cownerid == THIS.cownerid
         IF 'Check Amount' $ cbalancedesc
            llCheckAmt = .T.
         ENDIF
      ENDSCAN
      IF llCheckAmt
         USE DBF('invtmp') AGAIN IN 0 ALIAS tmpsusp
         SELECT tmpsusp
         SET ORDER TO 0
         SCAN FOR cownerid = THIS.cownerid ;
               AND nnetcheck # 0 ;
               AND NOT EMPTY(cSuspType)
            lnSuspRelamt  = lnSuspRelamt + nnetcheck
         ENDSCAN     && tmpsusp
         IF lnSuspRelamt # 0
            m.crptgroup = 'N'
            m.cSuspType = ''
            m.cTYPE     = 'BAL'
            m.nTotNet   = lnSuspRelamt
            m.cperiod   = ''
            m.cyear     = THIS.cyear
            m.cprogcode = 'ZZZZ'
            m.cWellType = '}ZZZZZZZZZZ'
            m.cDescript = 'Balance Brought Forward From Previous Periods That Was In Suspense'
            m.nRunNo    = THIS.nRunNo
            m.crunyear  = THIS.crunyear
            *********************************************************************************************************
            *  Insert into the statement file  - Report Group E     (Suspense Released)
            *********************************************************************************************************
            INSERT INTO statemnt FROM MEMVAR
            m.nWellNet  = 0
            m.nProgNet  = 0
            m.cDescript = ' '
         ENDIF
         SELECT tmpsusp
         USE
      ENDIF
   ENDPROC

   ***********************************************************************
   PROCEDURE NetWellTotalNoSplit
      ***********************************************************************
      ************************************************************************************
      **** PROCESSING FOR COMBINING PRODUCTION PERIOD TOGETHER UNDER ONE WELL HEADER *****
      ************************************************************************************
      IF TYPE('this.oinvtmp') # 'O'
         RETURN
      ENDIF

      m.nWellNet = 0
      m.nProgNet = 0

      IF NOT THIS.lsplitperiods
         IF THIS.ownergroup # invtmp.cownerid + invtmp.cwellid + invtmp.cTypeInv  AND THIS.ownergroup # ' '
            *  Report Rounding for this owner, if any
            *  Moved to always do rounding, even if the total for the well is zero. In instances
            *  where the well comes out to zero, but there was actually activity, it doesn't allow
            *  any rounding to be reported, which makes the statement not total the check amount.
            THIS.Rounding()
            * If the well total is zero, make sure the activity is zero so wells without production can be reported
            IF THIS.nwelltot = 0
               IF THIS.oinvtmp.nincome = 0 AND ;
                     (THIS.oinvtmp.nexpense + THIS.oinvtmp.ntotale1 + ;
                       THIS.oinvtmp.ntotale2 + THIS.oinvtmp.ntotale3 + ;
                       THIS.oinvtmp.ntotale4 + THIS.oinvtmp.ntotale5 + ;
                       THIS.oinvtmp.nTotaleA + THIS.oinvtmp.nTotaleB) = 0 AND ;
                     THIS.oinvtmp.nsevtaxes = 0 AND THIS.oinvtmp.nnetcheck = 0
                  SELECT invtmp
                  IF NOT BOF() AND NOT EOF()
                     lnrecNo = RECNO()
                     LOCATE FOR cownerid = THIS.oinvtmp.cownerid AND ;
                        cwellid = THIS.oinvtmp.cwellid AND ;
                        (nincome # 0 OR nexpense # 0 OR ;
                          ntotale1 # 0 OR ntotale2 # 0 OR ;
                          ntotale3 # 0 OR ntotale4 # 0 OR ;
                          ntotale5 # 0 OR nTotaleA # 0 OR ;
                          nTotaleB # 0 OR nPlugExp # 0 OR ;
                          nsevtaxes # 0 OR nnetcheck # 0)
                     IF NOT FOUND()
                        m.cDescript = 'No Production this Run'
                        STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL, lnwelldef
                        m.cownerid = THIS.cownerid
                        m.nWellNet = 0
                        m.nProgNet = 0
                        m.nRunNo   = THIS.nRunNo
                        IF NOT EMPTY(THIS.oinvtmp.cprogcode)
                           m.nprogtot  = 0
                           m.cprogcode = THIS.oinvtmp.cprogcode
                           m.cownerid  = THIS.oinvtmp.cownerid
                           SELECT progtots
                           LOCATE FOR cownerid == m.cownerid AND cprogcode == m.cprogcode
                           IF NOT FOUND()
                              INSERT INTO progtots FROM MEMVAR
                           ENDIF
                        ENDIF
                     ELSE
                        m.nWellNet  = THIS.nwelltot
                        IF (THIS.oinvtmp.lFlat AND m.nWellNet # 0) OR NOT THIS.oinvtmp.lFlat
                           DO CASE
                              CASE THIS.oinvtmp.cTypeInv = 'L'     && Royalty Owner
                                 m.cDescript = 'Your Royalty Interest This ' + lcWellProg
                                 STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                              CASE THIS.oinvtmp.cTypeInv = 'O'     && Overriding Royalty Owner
                                 m.cDescript = 'Your Overriding Royalty Interest This ' + lcWellProg
                                 STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                              CASE THIS.oinvtmp.cTypeInv = 'W'     && Working Interest
                                 m.cDescript = 'Your Working Interest This ' + lcWellProg
                                 STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                              OTHERWISE
                                 m.cDescript = ' '
                           ENDCASE
                        ELSE
                           SELECT invtmp
                           GOTO lnrecNo
                           RETURN
                        ENDIF
                     ENDIF
                     SELECT invtmp
                     GOTO lnrecNo
                  ELSE
                     SELECT curlastsusptype
                     LOCATE FOR cwellid = THIS.oinvtmp.cwellid AND cownerid = THIS.oinvtmp.cownerid AND cTypeInv = THIS.oinvtmp.cTypeInv
                     IF FOUND()
                        lcCurStatus = cSuspType
                        lnBalance   = THIS.osuspense.Owner_Balances(THIS.cownerid, THIS.cGROUP, .F., .T., .T., .T., .T.)
                        IF VARTYPE(lnBalance) # 'N'
                           llReturn  = .F.
                           lnBalance = 0
                           EXIT
                        ENDIF
                        IF lnBalance = 0
                           lcCurStatus = '*'
                        ENDIF
                     ELSE
                        lcCurStatus = '*'
                     ENDIF

                     * If this runno_in = runno this means that the amount was cleared from suspense
                     * It shouldn't show as not being in suspense for this run on the statement
                     IF THIS.oinvtmp.nRunNo_In = THIS.oinvtmp.nRunNo AND ;
                           THIS.oinvtmp.cRunYear_In = THIS.oinvtmp.crunyear
                        lcCurStatus = THIS.oinvtmp.cSuspType
                     ENDIF

                     m.nWellNet = THIS.nwelltot

                     DO CASE
                        CASE THIS.oinvtmp.cTypeInv = 'L'     && Royalty Owner
                           m.cDescript = 'Your Royalty Interest This ' + lcWellProg
                           STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                        CASE THIS.oinvtmp.cTypeInv = 'O'     && Overriding Royalty Owner
                           m.cDescript = 'Your Overriding Royalty Interest This ' + lcWellProg
                           STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                        CASE THIS.oinvtmp.cTypeInv = 'W'     && Working Interest
                           m.cDescript = 'Your Working Interest This ' + lcWellProg
                           STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                        OTHERWISE
                           m.cDescript = ' '
                     ENDCASE
                     DO CASE
                        CASE lcCurStatus = 'D'
                           IF THIS.ooptions.lstminv
                              m.cDescript = m.cDescript + '-(Amount Added To Previous Suspense Balance)'
                           ELSE
                              m.cDescript = m.cDescript + '-(Deficit Held In Suspense)'
                           ENDIF
                        CASE lcCurStatus = 'M'
                           m.cDescript = m.cDescript + '-(Minimum Held In Suspense)'
                        CASE lcCurStatus = 'H'
                           m.cDescript = m.cDescript + '-(Owner Held In Suspense)'
                        CASE lcCurStatus = 'I'
                           m.cDescript = m.cDescript + '-(Interest Held In Suspense)'
                        CASE lcCurStatus = 'Q'
                           m.cDescript = m.cDescript + '-(Quarterly Pay Held Until End Of Quarter)'
                        CASE lcCurStatus = 'S'
                           m.cDescript = m.cDescript + '-(Semi-Annual Pay Held)'
                        CASE lcCurStatus = 'A'
                           m.cDescript = m.cDescript + '-(Annual Pay Held Until End Of Year)'
                     ENDCASE

                  ENDIF
                  m.crptgroup = 'E'
                  m.cownerid  = THIS.cownerid
                  m.cwellid   = THIS.oinvtmp.cwellid
                  m.cSuspType = ''
                  m.crunyear  = THIS.crunyear
                  SELECT statemnt
                  LOCATE FOR cownerid = THIS.oinvtmp.cownerid AND cwellid = THIS.oinvtmp.cwellid AND cWellType = m.cWellType AND (crptgroup = 'B' OR crptgroup = 'D')
                  IF NOT FOUND()
                     RETURN
                  ENDIF
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group E
                  *********************************************************************************************************
                  INSERT INTO statemnt FROM MEMVAR
                  *********************************************************************************************************
               ENDIF
            ELSE
               m.crptgroup = 'E'
               m.cSuspType = ''
               m.nWellNet  = THIS.nwelltot

               *  This is a kludge.  If an owner has a piddly interest and a ton of amounts that round to zero, it can
               *  sometimes come out with a penny difference between the well total and the overall total (when they
               *  only have an interest in one well).  This makes it match.  No idea how they come out different, because
               *  anytime nWellNet is being set, there have been swrounds done on the numbers that make it up, so there
               *  should be no partial penny stuff going on to cause the difference.  If someone else feels like taking
               *  the time to step through a few hundred entries to find out where it's happening, feel free.
               *  But as for me and my house, we will kludge. - BH 07/20/12
               *!*               IF ABS(m.nWellNet-m.nTotalCheck) <= .03
               *!*                  m.nWellNet = m.nTotalCheck
               *!*               ENDIF

               lnwelldef  = m.nWellNet
               m.cTYPE    = 'NET'
               llnewowner = .F.
               m.cownerid = THIS.cownerid
               m.cwellid  = THIS.oinvtmp.cwellid

               * Determine what type of interest is being reported
               DO CASE
                  CASE THIS.oinvtmp.cTypeInv = 'L'     && Royalty Owner
                     m.cDescript = 'Your Royalty Interest This ' + lcWellProg
                     STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                  CASE THIS.oinvtmp.cTypeInv = 'O'     && Overriding Royalty Owner
                     m.cDescript = 'Your Overriding Royalty Interest This ' + lcWellProg
                     STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                  CASE THIS.oinvtmp.cTypeInv = 'W'     && Working Interest
                     m.cDescript = 'Your Working Interest This ' + lcWellProg
                     STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                  OTHERWISE
                     m.cDescript = ' '
               ENDCASE

               * Get the type of suspense for this well so it can be reported correctly
               SELECT curlastsusptype
               LOCATE FOR cwellid = THIS.oinvtmp.cwellid AND cownerid = THIS.oinvtmp.cownerid AND cTypeInv = THIS.oinvtmp.cTypeInv
               IF FOUND()
                  lcCurStatus = cSuspType
               ELSE
                  lcCurStatus = '*'
               ENDIF

               * If this runno_in = runno this means that the amount was cleared from suspense
               * It shouldn't show as not being in suspense for this run on the statement
               IF THIS.oinvtmp.nRunNo_In = THIS.oinvtmp.nRunNo AND ;
                     THIS.oinvtmp.cRunYear_In = THIS.oinvtmp.crunyear
                  lcCurStatus = THIS.oinvtmp.cSuspType
               ENDIF

               * Add the suspense description to the total line
               DO CASE
                  CASE lcCurStatus = 'D'
                     IF THIS.ooptions.lstminv
                        m.cDescript = m.cDescript + '-(Amount Added To Previous Suspense Balance)'
                     ELSE
                        m.cDescript = m.cDescript + '-(Deficit Held In Suspense)'
                     ENDIF
                  CASE lcCurStatus = 'M'
                     m.cDescript = m.cDescript + '-(Minimum Held In Suspense)'
                  CASE lcCurStatus = 'H'
                     m.cDescript = m.cDescript + '-(Owner Held In Suspense)'
                  CASE lcCurStatus = 'I'
                     m.cDescript = m.cDescript + '-(Interest Held In Suspense)'
                  CASE lcCurStatus = 'Q'
                     m.cDescript = m.cDescript + '-(Quarterly Pay Held Until End Of Quarter)'
                  CASE lcCurStatus = 'S'
                     m.cDescript = m.cDescript + '-(Semi-Annual Pay Held)'
                  CASE lcCurStatus = 'A'
                     m.cDescript = m.cDescript + '-(Annual Pay Held Until End Of Year)'
               ENDCASE

               STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL, lnwelldef
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               SELECT statemnt
               LOCATE FOR cownerid = THIS.oinvtmp.cownerid AND cwellid = THIS.oinvtmp.cwellid AND cWellType = m.cWellType AND (crptgroup = 'B' OR crptgroup = 'D')
               IF NOT FOUND()
                  RETURN
               ENDIF
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group E
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               *********************************************************************************************************

               *  At this point, m.cProgCode still has the last program code stored
               *  Add to that programs totals
               IF NOT EMPTY(ALLT(THIS.cprogcode)) AND THIS.oinvtmp.cSuspType # 'I'
                  SELE progtots
                  LOCATE FOR cownerid + cprogcode == THIS.oinvtmp.cownerid + THIS.oinvtmp.cprogcode
                  IF FOUND()
                     IF THIS.lnetwells
                        REPL nprogtot WITH nprogtot + m.nWellNet
                     ELSE
                        IF m.nWellNet > 0
                           REPL nprogtot WITH nprogtot + m.nWellNet
                        ENDIF
                     ENDIF
                  ELSE
                     m.nprogtot  = m.nWellNet
                     m.cprogcode = THIS.oinvtmp.cprogcode
                     m.cownerid  = THIS.oinvtmp.cownerid
                     IF THIS.lnetwells
                        INSERT INTO progtots FROM MEMVAR
                     ELSE
                        * Not netting wells so don't show a program total unless
                        * the total is positive
                        IF m.nWellNet > 0
                           INSERT INTO progtots FROM MEMVAR
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF
            m.cDescript = ' '
            *      IF m.nwellnet > 0 OR (m.nwellnet < 0 AND THIS.oInvTmp.lused) OR (m.ntotalcheck < 0)
            THIS.nownertotal = THIS.nownertotal + ROUND(m.nWellNet, 2)
            *      ENDIF
            STORE 0 TO THIS.nwelltot, THIS.ntotinc, m.nWellNet, m.nTOTAL
         ENDIF

      ENDIF
      ************************************************************************************
      **** PROCESSING FOR COMBINING PRODUCTION PERIOD TOGETHER UNDER ONE WELL HEADER *****
      ************************************************************************************
   ENDPROC

   ***********************************************************************
   PROCEDURE NetWellTotalSplit
      ***********************************************************************
      LOCAL llNetSusp

      swSelect('groups')
      LOCATE FOR cGROUP = THIS.cGROUP
      IF FOUND()
         llNetSusp = lNetDef
      ELSE
         llNetSusp = .T.
      ENDIF

      *
      * Determines which message to print for the net total
      *
      IF THIS.lsplitperiods
         m.nworkint  = THIS.oinvtmp.nworkint
         m.crptgroup = 'E'
         m.cSuspType = ''
         m.nWellNet  = THIS.nwelltot
         m.cTYPE     = 'NET'
         m.cownerid  = THIS.cownerid

         DO CASE
            CASE THIS.oinvtmp.cTypeInv = 'L'
               lcOwnType = 'Your Royalty'
            CASE THIS.oinvtmp.cTypeInv = 'O'
               lcOwnType = 'You Overriding Royalty'
            CASE THIS.oinvtmp.cTypeInv = 'W'
               lcOwnType = 'Your Working'
            OTHERWISE
               lcOwnType = 'Your Working'
         ENDCASE


         DO CASE
               * Royalty owner, postive net
            CASE THIS.oinvtmp.cTypeInv # 'W' AND m.nWellNet >= 0
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg
               ELSE
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg + ' (**ON HOLD**)'
               ENDIF
               * Royalty owner, negative net covered by other wells this period
            CASE THIS.oinvtmp.cTypeInv # 'W' AND m.nWellNet < 0 AND THIS.oinvtmp.lused
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg
               ELSE
                  m.cDescript = lcOwnType + ' Interest This '  + lcWellProg + ' (**ON HOLD**)'
               ENDIF
               * Royalty owner, deficit
            CASE THIS.oinvtmp.cTypeInv # 'W' AND m.nWellNet < 0 AND NOT THIS.oinvtmp.lused
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg + ' (Deficit Carried Forward)'
               ELSE
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg + ' (**ON HOLD**)'
               ENDIF
               * Working interest owner, positive net or deficit covered by other wells this period
            CASE THIS.oinvtmp.cTypeInv = 'W' AND ;
                  ((m.nWellNet > 0 OR (m.nWellNet < 0 AND THIS.oinvtmp.lused) OR ;
                      (m.nWellNet < 0 AND NOT THIS.oinvtmp.lused AND THIS.ooptions.lstminv AND llNetSusp)))
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = 'Your Working Interest This ' + lcWellProg
               ELSE
                  m.cDescript = 'Your Working Interest This ' + lcWellProg + '(**ON HOLD**)'
               ENDIF
               * Working interest owner, deficit
            CASE THIS.oinvtmp.cTypeInv = 'W' AND ;
                  (m.nWellNet < 0 AND NOT THIS.oinvtmp.lused AND (NOT THIS.ooptions.lstminv OR NOT THIS.lnetwells))
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = 'Your Working Interest This ' + lcWellProg + ' (Deficit Carried Forward)'
               ELSE
                  m.cDescript = 'Your Working Interest This ' + lcWellProg + ' (**ON HOLD**)'
               ENDIF
            CASE THIS.oinvtmp.cTypeInv = 'W' AND ;
                  (m.nWellNet < 0 AND NOT THIS.oinvtmp.lused AND THIS.ooptions.lstminv)
               m.cDescript = 'Your Working Interest This ' + lcWellProg + ' (Amount Added to Payment)'
               * Should never get here
            OTHERWISE
               m.cDescript = ' '
         ENDCASE
         STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL, lnwelldef
         m.cownerid = THIS.oinvtmp.cownerid
         m.nRunNo   = THIS.nRunNo
         m.crunyear = THIS.crunyear

         *********************************************************************************************************
         *  Insert into the statement file  - Report Group E
         *********************************************************************************************************
         INSERT INTO statemnt FROM MEMVAR

         IF NOT EMPTY(ALLT(THIS.oinvtmp.cprogcode)) AND THIS.oinvtmp.cSuspType # 'I'
            SELE progtots
            LOCATE FOR cownerid + cprogcode == THIS.oinvtmp.cownerid + THIS.oinvtmp.cprogcode
            IF FOUND()
               IF THIS.lnetwells
                  REPL nprogtot WITH nprogtot + m.nWellNet
               ELSE
                  IF m.nWellNet > 0
                     REPL nprogtot WITH nprogtot + m.nWellNet
                  ENDIF
               ENDIF
            ELSE
               m.nprogtot = m.nWellNet
               IF THIS.lnetwells
                  INSERT INTO progtots FROM MEMVAR
               ELSE
                  IF m.nWellNet > 0
                     INSERT INTO progtots FROM MEMVAR
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
         m.cDescript = ' '
         *   IF m.nwellnet > 0 OR (m.nwellnet < 0 AND THIS.oInvTmp.lUsed) OR (m.ntotalcheck < 0)
         THIS.nownertotal = THIS.nownertotal + ROUND(m.nWellNet, 2)
         *   ENDIF
         STORE 0 TO THIS.nwelltot, THIS.ntotinc

         **************************************************************
         *  Report Rounding for this owner
         **************************************************************
         THIS.Rounding()

      ENDIF
   ENDPROC

   ***********************************************************************
   PROCEDURE pulltype
      ***********************************************************************
      tcOwner1 = THIS.cowner1
      tcOwner2 = THIS.cowner2

      * Get list of owners, wells and types from doi
      SELE cownerid, cwellid, cTypeInv ;
         FROM invtmp ;
         WHERE cownerid IN (SELECT cid FROM SELECTED) ;
         INTO CURSOR owntypes ;
         GROUP BY cownerid, cwellid, cTypeInv ;
         ORDER BY cownerid, cwellid, cTypeInv

      DO CASE
         CASE 'Royalty' $ THIS.cownertype
            *  Scan for non royalty owner records to see if they should stay or go
            *  They stay if the owner has other royalty interests being reported
            SELE invtmp
            SET ORDER TO
            SCAN FOR NOT INLIST(cTypeInv, 'L', 'O')
               lnrecNo    = RECNO()
               m.cownerid = cownerid
               m.cwellid  = cwellid
               m.cTypeInv = cTypeInv
               SELE owntypes
               LOCATE FOR cownerid = m.cownerid AND cwellid = m.cwellid
               IF FOUND()
                  IF NOT INLIST(cTypeInv, 'L', 'O')
                     SELECT owntypes
                     LOCATE FOR cownerid = m.cownerid AND INLIST(cTypeInv, 'L', 'O')
                     IF NOT FOUND()
                        SELE invtmp
                        SCAN FOR cownerid == m.cownerid
                           DELE NEXT 1
                        ENDSCAN
                        GOTO lnrecNo
                     ENDIF
                  ENDIF
               ENDIF
            ENDSCAN
         CASE 'Working' $ THIS.cownertype
            * Scan for non working interests to see if they should stay or go
            * They stay if the owner has other working interests that are being reported
            SELE invtmp
            SET ORDER TO
            SCAN FOR cTypeInv # 'W'
               lnrecNo    = RECNO()
               m.cownerid = cownerid
               m.cwellid  = cwellid
               m.cTypeInv = cTypeInv
               SELE owntypes
               LOCATE FOR cownerid = m.cownerid AND cwellid = m.cwellid
               IF FOUND()
                  IF cTypeInv # 'W'
                     SELECT owntypes
                     LOCATE FOR cownerid = m.cownerid AND cTypeInv = 'W'
                     IF NOT FOUND()
                        SELE invtmp
                        SCAN FOR cownerid == m.cownerid
                           DELE NEXT 1
                        ENDSCAN
                        GOTO lnrecNo
                     ENDIF
                  ENDIF
               ENDIF
            ENDSCAN
      ENDCASE

      *  Remove owner total records if there are no detail records
      *  to report on.
      SELE invtotal
      SCAN
         m.cownerid = cownerid
         SELE invtmp
         LOCATE FOR cownerid = m.cownerid
         IF NOT FOUND()
            SELE invtotal
            DELE NEXT 1
         ENDIF
      ENDSCAN
   ENDPROC

   ***********************************************************************
   PROCEDURE Rounding
      ***********************************************************************
      * Make sure expense tax code is not set for rounding
      STORE '' TO m.ctaxcode, m.ctaxdesc

      * Don't attempt to adjust rounding when doing statements
      * for a new run
      IF THIS.lNewRun
         RETURN
      ENDIF

      IF USED('roundsum')
         SELECT roundsum
         LOCATE FOR cownerid == THIS.oinvtmp.cownerid AND cwellid == THIS.oinvtmp.cwellid AND cDMBatch == THIS.cDMBatch AND lused = .F.
         IF FOUND()
            m.nWellNet    = nWellNet
            m.nrevenue    = nrevenue
            m.nexpenses   = nexpenses
            THIS.nwelltot = THIS.nwelltot + m.nWellNet
            * Commented out 3/18/09 by pws because it was adding the rounding to the total on each page
            *      m.nTotalBal   = m.nTotalBal + m.nWellNet
            m.crptgroup = 'E'
            m.cSuspType = ''
            m.cTYPE     = 'RND'
            m.cperiod   = ''
            m.cyear     = THIS.oinvtmp.hyear
            m.cprogcode = 'ZZZZ'
            m.cwellid   = THIS.oinvtmp.cwellid
            m.cSuspType = THIS.oinvtmp.cSuspType
            m.cownerid  = THIS.cownerid

            REPL lused WITH .T.

            swSelect('wells')
            SET ORDER TO cwellid
            IF SEEK(THIS.oinvtmp.cwellid)
               m.cwellname = cwellname
            ELSE
               m.cwellname = 'Combined Wells'
            ENDIF
            IF THIS.lsplitperiods
               m.cWellType = THIS.oinvtmp.cownerid + THIS.oinvtmp.cwellid + ;
                  THIS.oinvtmp.cTypeInv + STR(0, 1) + THIS.oinvtmp.hyear + THIS.oinvtmp.hperiod
            ELSE
               m.cWellType = THIS.oinvtmp.cownerid + THIS.oinvtmp.cwellid + ;
                  THIS.oinvtmp.cTypeInv + STR(0, 1)
            ENDIF
            m.cprogcode = THIS.oinvtmp.cprogcode
            IF NOT FILE(m.goApp.cCommonFolder + 'sumprogs.txt')
               m.cDescript = 'Rounding Adjustment For Well: ' + ALLT(THIS.oinvtmp.cwellid) + ;
                  ' --- Revenue: ' + TRANSFORM(roundsum.nrevenue) + ' Expenses: ' + TRANSFORM(roundsum.nexpenses)
            ELSE
               m.cDescript = 'Rounding Adjustment For Program: ' + ALLT(THIS.oinvtmp.cwellid)
            ENDIF
            m.cownerid = THIS.oinvtmp.cownerid
            m.nRunNo   = THIS.nRunNo
            m.crunyear = THIS.crunyear
            *********************************************************************************************************
            *  Insert into the statement file  - Report Group H   (Rounding Amount)
            *********************************************************************************************************
            IF m.nWellNet # 0 OR m.nrevenue # 0 OR m.nexpenses # 0
               INSERT INTO statemnt FROM MEMVAR
               THIS.lrounding = .T.
            ENDIF
         ENDIF
      ENDIF
   ENDPROC

   ***********************************************************************
   PROCEDURE stmtnotes
      ***********************************************************************
      LPARA tnRunNo, tcRunYear, m.cwellid, m.cownerid

      * Make sure expense tax code is not set for statement notes
      STORE '' TO m.ctaxcode, m.ctaxdesc

      m.ninvamt  = 0
      llReturn   = .F.
      m.cTypeInv = THIS.oinvtmp.cTypeInv
      swSelect('stmtnote')
      IF THIS.lNewRun
         LOCATE FOR cwellid == m.cwellid AND nRunNo = 0        && Look for notes
      ELSE
         LOCATE FOR cwellid == m.cwellid AND crunyear == tcRunYear AND nRunNo == tnRunNo        && Look for notes
      ENDIF

      IF FOUND() AND NOT EMPTY(mNotes)
         SCATTER MEMVAR MEMO
         SELE ownnotes
         LOCATE FOR cownerid = m.cownerid AND cwellid = m.cwellid
         IF NOT FOUND()
            m.cownerid  = THIS.oinvtmp.cownerid
            swSelect('wellinv')
            LOCATE FOR cownerid == m.cownerid AND cwellid == m.cwellid AND cTypeInv == m.cTypeInv
            IF FOUND()
               m.cprogcode = wellinv.cprogcode
               m.ctypeint  = wellinv.ctypeint
            ENDIF
            m.nRunNo    = THIS.nRunNo
            m.crunyear  = THIS.crunyear
            m.crptgroup = 'F'
            m.cTYPE     = 'NOT'
            m.cSuspType = ''
            m.cownerid  = THIS.oinvtmp.cownerid
            m.cWellType = m.cownerid + m.cwellid + m.cTypeInv + '0'

            IF m.cTypeInv = 'L' AND INLIST(m.nnotetype, 1, 3, 5)
               m.cDescript = '**********************************************************************' + CHR(13) + ;
                  M.mNotes + CHR(13) + ;
                  '**********************************************************************'

               STORE 0 TO m.ninvamt, m.nWellNet, m.nunits, m.nprice, m.nTOTAL, m.nworkint, m.nTotNet, m.nWorkTot
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group F
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               *********************************************************************************************************
               llReturn = .T.
            ENDIF
            IF m.cTypeInv = 'O' AND INLIST(m.nnotetype, 2, 3, 5)
               m.cDescript = '**********************************************************************' + CHR(13) + ;
                  M.mNotes + CHR(13) + ;
                  '**********************************************************************'
               STORE 0 TO m.ninvamt, m.nWellNet, m.nunits, m.nprice, m.nTOTAL, m.nworkint, m.nTotNet, m.nWorkTot
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group F
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               *********************************************************************************************************
               llReturn = .T.
            ENDIF
            IF m.cTypeInv = 'W' AND INLIST(m.nnotetype, 4, 5)
               m.cDescript = '**********************************************************************' + CHR(13) + ;
                  M.mNotes + CHR(13) + ;
                  '**********************************************************************'
               STORE 0 TO m.ninvamt, m.nWellNet, m.nunits, m.nprice, m.nTOTAL, m.nworkint, m.nTotNet, m.nWorkTot
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group F
               *********************************************************************************************************
               INSERT INTO statemnt FROM MEMVAR
               llReturn = .T.
            ENDIF
            INSERT INTO ownnotes FROM MEMVAR
         ENDIF
      ENDIF
   ENDPROC

   ***********************************************************************
   PROCEDURE BackTaxWith
      ***********************************************************************
      *************************************************************
      *  Process Tax Withholding
      *************************************************************
      IF THIS.nbackupwith # 0
         THIS.nownertotal = THIS.nownertotal - THIS.nbackupwith
         m.crptgroup      = 'H'
         m.cSuspType      = ''
         m.cTYPE          = 'PPD'
         m.nWellNet       = THIS.nbackupwith
         m.cperiod        = ''
         m.cyear          = THIS.oinvtmp.hyear
         m.cprogcode      = 'ZZZZ'
         m.cWellType      = '}ZZZZZZZ'
         m.cDescript      = 'Backup Withholding Amount Deducted This Run'
         m.cownerid       = THIS.cownerid
         m.nRunNo         = THIS.nRunNo
         m.crunyear       = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group H     (Backup Withholding)
         *********************************************************************************************************
         INSERT INTO statemnt FROM MEMVAR
         m.cDescript = ' '
      ENDIF  && IF m.nBack

      *************************************************************
      *  Process Tax Withholding
      *************************************************************
      IF THIS.ntaxwith # 0
         THIS.nownertotal = THIS.nownertotal - THIS.ntaxwith
         m.crptgroup      = 'H'
         m.cSuspType      = ''
         m.cTYPE          = 'PPD'
         m.nWellNet       = THIS.ntaxwith
         m.cperiod        = ''
         m.cyear          = THIS.oinvtmp.hyear
         m.cprogcode      = 'ZZZZ'
         m.cWellType      = '}ZZZZZZZ'
         m.cDescript      = 'Tax Withholding Amount Deducted This Run'
         m.cownerid       = THIS.cownerid
         m.nRunNo         = THIS.nRunNo
         m.crunyear       = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group H     (Tax Withholding)
         *********************************************************************************************************
         INSERT INTO statemnt FROM MEMVAR
         m.cDescript = ' '
      ENDIF  && IF m.nTax
   ENDPROC

   ***********************************************************************
   PROCEDURE removetaxexempt
      ***********************************************************************
      LPARA tcWellId, tcType, tnAmount
      LOCAL lnShare

      *
      * Removes the tax exempt owners share from the gross amount before taxes
      * are calculated on the gross.  - For New Mexico Wells
      *

      lnShare = 0

      swSelect('wellinv')
      SCAN FOR cwellid = tcWellId
         SCATTER MEMVAR

         swSelect('investor')
         SET ORDER TO cownerid
         IF SEEK(m.cownerid) AND lExempt
            DO CASE
               CASE tcType = 'BBL'
                  lnShare = lnShare + SWROUND((tnAmount * m.nrevoil / 100), 2)
               CASE tcType = 'MCF'
                  lnShare = lnShare + SWROUND((tnAmount * m.nrevgas / 100), 2)
            ENDCASE
         ENDIF
      ENDSCAN

      lnAmount = tnAmount - lnShare

      RETURN (lnAmount)

   ENDPROC

   ***********************************************************************
   PROCEDURE Owner_Payments
      ********************************************************************
      LPARAMETERS tcownerid
      LOCAL lnPmtAmt

      lnPmtAmt = 0

      *!*         IF NOT THIS.lNewRun

      * Get the pmts that were released from suspense
      swSelect('disbhist')

      SELECT  SUM(nnetcheck) AS ntotpmts ;
          FROM disbhist ;
          WHERE crunyear = THIS.crunyear ;
              AND nRunNo = THIS.nRunNo ;
              AND cownerid = tcownerid ;
              AND crectype = 'P' ;
          INTO CURSOR pmtamt
      lnPmtAmt = ntotpmts

      lcRunYear = THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      * Get pmts still sitting in suspense since it affects the balance after the run
      swSelect('suspense')
      SELECT  SUM(nnetcheck) AS ntotpmts ;
          FROM suspense ;
          WHERE cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') < lcRunYear ;
              AND cownerid = tcownerid ;
              AND crectype = 'P' ;
          INTO CURSOR pmtamt
      lnPmtAmt = lnPmtAmt + ntotpmts
      *!*         ENDIF

      RETURN lnPmtAmt
   ENDPROC

   ***********************************************************************
   PROCEDURE osuspense_access
      ***********************************************************************
      *To do: Modify this routine for the Access method

      IF TYPE('this.osuspense') # 'O'
         THIS.osuspense = CREATEOBJECT('suspense')
      ENDIF

      RETURN THIS.osuspense
   ENDPROC

   ***********************************************************************
   PROCEDURE checkincexp
      ***********************************************************************
      LPARAMETERS tcWellId, tcYear, tcPeriod, tnRunNo, tcRunYear
      LOCAL llReturn
      * Looks for activity for the given year and period for the given run
      * If it finds any, we assume it zeros itself out and go ahead and report
      * it.
      llReturn = .F.

      lcForInc = IIF(THIS.lNewRun, ' nRunNo = 0 ', ' nRunNo = tnRunNo AND crunyear = tcRunYear ')
      lcForExp = IIF(THIS.lNewRun, ' nRunNo = 0 ', ' nRunNoRev = tnRunNo AND crunyearRev = tcRunYear ')

      swSelect('income')
      LOCATE FOR cwellid = tcWellId AND ;
         cyear   = tcYear   AND ;
         cperiod = tcPeriod AND ;
         &lcForInc
      IF FOUND()
         llReturn = .T.
      ENDIF

      IF NOT llReturn
         swSelect('expense')
         LOCATE FOR cwellid = tcWellId AND ;
            cyear   = tcYear   AND ;
            cperiod = tcPeriod AND ;
            &lcForExp
         IF FOUND()
            llReturn = .T.
         ENDIF
      ENDIF

      RETURN llReturn

      ******************************
   FUNCTION CheckCancel
      ******************************

      IF THIS.lcanceled
         IF VARTYPE(THIS.oProgress) = 'O'
            THIS.oProgress.CloseProgress()
            THIS.oProgress = .NULL.
         ENDIF
      ENDIF

   ENDPROC

ENDDEFINE
*
*-- EndDefine: swownerstmt
**************************************************

********************************************************************************************************************************************************************
*-- Class:        swSettlement (c:\develop\codeminenew\custom\swowner.vcx)
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   06/08/2020 11:00:00 AM
*-- Description:  Builds the settlement cursor for the partner-settlement1 and partner-settlment2 reports.
********************************************************************************************************************************************************************
DEFINE CLASS swSettlement AS CUSTOM


   HEIGHT           = 38
   WIDTH            = 100
   lroyaltyowner    = .F.
   cDMBatch         = ''
   cyear            = ''
   cowner1          = ''
   cowner2          = ''
   cwell1           = ''
   cwell2           = ''
   cGROUP           = ''
   nRunNo           = 0
   dAcctDate        = {}
   dExpDate         = {}
   dRevDate         = {}
   lnetwells        = .F.
   lcloserun        = .F.
   lclosed          = .F.
   ooptions         = .F.
   oinvtmp          = .F.
   omessage         = .F.
   cownerid         = ''
   ownergroup       = .F.
   nownertotal      = .F.
   lownertaxexempt  = .F.
   lowneronhold     = .F.
   lallminsreleased = .F.
   cperiod          = ''
   lsplitperiods    = .F.
   ncompress        = .F.
   ngather          = .F.
   owellwork        = .F.
   odist            = .F.
   crunyear         = ''
   cownertype       = ''
   nwelltot         = 0
   ntotinc          = 0
   lexemptroyalty   = .F.
   nbackupwith      = 0
   ntaxwith         = 0
   cwellid          = ''
   noiltax1         = 0
   noiltax2         = 0
   noiltax3         = 0
   noiltax4         = 0
   ngastax1         = 0
   ngastax2         = 0
   ngastax3         = 0
   ngastax4         = 0
   nothtax1         = 0
   nothtax2         = 0
   nothtax3         = 0
   nothtax4         = 0
   ntotalbbl        = 0
   ntotalmcf        = 0
   noilamount       = 0
   ngasamount       = 0
   notheramount     = 0
   ncompamount      = 0
   ngathamount      = 0
   ntotalother      = 0
   cprogcode        = ''
   nbalance         = 0
   lbelowminimum    = .F.
   cSuspType        = ''
   lcanceled        = .F.
   lziporder        = .F.
   lprintdef        = .F.
   lprintmin        = .F.
   lnoprod          = .F.
   lIncludeChecks   = .F.
   lflatrate        = .F.
   lrounding        = .F.
   linterestheld    = .F.
   lfreqheld        = .F.
   lIncSummary      = .F.
   *-- Owner marked to get an owner stmt
   ldetail      = .F.
   nownermin    = 0
   lownerposted = .F.
   lchksubtot   = .F.
   *-- Don't calculate tax for this entry. It came from converted suspense.
   lnotax      = .F.
   NAME        = 'swownerstmt'
   lflatalloc  = .F.
   osuspense   = .NULL.
   nNewRunNo   = 0
   lSumExp     = .F.
   lSumRev     = .F.
   lNewRun     = .F.
   lEmailOnly  = .F.
   lDirDeposit = .F.
   lNoSuspDet  = .F.
   lcanceled   = .F.
   lClosing    = .F.
   lNoEmail    = .F.
   oProgress   = .NULL.

   ***********************************************************************
   PROCEDURE MAIN
      ***********************************************************************
      LPARAMETERS tlSelected
      LOCAL lcoldprog, lnowncount, lnPriorRunNo, lcPriorRunYear, llIncludeDirDep
      LOCAL lcoldprogname, lcperiod1, lcperiod2, lnperiodbal, llDirDep
      LOCAL llexemptroyalty, m.ljib, tcWellID1, tcWellID2, lnRevExpRun
      LOCAL llReturn, loError

      llReturn = .T.

      * Force the processing to not include suspense detail
      THIS.lNoSuspDet = .T.

      TRY
         STORE .F. TO llDirDep, THIS.lcanceled

         m.goApp.oLogger.StartProcess('Settlement Statements: Main')

         IF tlSelected
            * Use the owners selected
            SELECT SELECTED
            GO TOP
            THIS.cowner1 = cid
            GO BOTT
            THIS.cowner2 = cid
         ELSE
            SELECT  cownerid AS cid ;
                FROM investor ;
                WHERE BETWEEN(cownerid, THIS.cowner1, THIS.cowner2) ;
                INTO CURSOR SELECTED ;
                ORDER BY cownerid ;
                GROUP BY cownerid
         ENDIF

         llIncludeDirDep = THIS.lDirDeposit

         tcRunYear   = THIS.crunyear
         tnRunNo     = THIS.nRunNo
         lnRevExpRun = THIS.nRunNo

         THIS.omessage = findglobalobject('cmmessage')

         swSelect('wells')
         SET ORDER TO cwellid
         GO TOP
         tcWellID1 = cwellid
         GO BOTT
         tcWellID2 = cwellid

         swSelect('taxcodes')

         IF THIS.nRunNo = 0
            THIS.lNewRun   = .T.
            THIS.nNewRunNo = getrunno(tcRunYear, .T., 'R')
            THIS.nRunNo    = THIS.nNewRunNo
         ELSE
            THIS.nNewRunNo = THIS.nRunNo
         ENDIF
         m.nRunNo    = THIS.nRunNo

         * Create the suspense object
         THIS.osuspense          = CREATEOBJECT('suspense')
         THIS.osuspense.crunyear = THIS.crunyear
         THIS.osuspense.nRunNo   = THIS.nNewRunNo
         THIS.osuspense.lNewRun  = THIS.lNewRun

         * Create cursor to hold manually entered taxes
         * to keep them separate from calculated taxes.
         CREATE CURSOR manualTax ;
            (cwellid    C(10), ;
              cyear      C(4), ;
              cperiod    C(2), ;
              noiltax1   N(9, 2), ;
              noiltax2   N(9, 2), ;
              noiltax3   N(9, 2), ;
              noiltax4   N(9, 2), ;
              ngastax1   N(9, 2), ;
              ngastax2   N(9, 2), ;
              ngastax3   N(9, 2), ;
              ngastax4   N(9, 2), ;
              nprodtax1  N(9, 2), ;
              nprodtax2  N(9, 2), ;
              nprodtax3  N(9, 2), ;
              nprodtax4  N(9, 2))

         * Make sure all the tax codes represented in Expcat are in Taxcodes
         SELECT  ctaxcode ;
             FROM expcat ;
             INTO CURSOR missingcodes ;
             WHERE ctaxcode NOT IN (SELECT  ctaxcode ;
                                        FROM taxcodes) ;
             ORDER BY ctaxcode ;
             GROUP BY ctaxcode

         TRY
            lcCode = ''
            SELECT missingcodes
            SCAN
               m.ctaxcode = ctaxcode
               m.cDesc    = ctaxcode
               INSERT INTO taxcodes FROM MEMVAR
               lcCode = m.ctaxcode + CHR(13)
            ENDSCAN

            SELECT missingcodes
            IF RECCOUNT() > 0
               MESSAGEBOX('The following Expense Section Codes were added. Go to ' + ;
                    'Maintain Expense Section Codes to update the description for the code ' + ;
                    'to be a better description than just the code itself.' + CHR(13) + CHR(13) + lcCode, 64, 'Missing Expense Section Codes')
            ENDIF
         CATCH
         ENDTRY


         *  Call distproc to create the (invtmp) and (wellwork) cursors
         THIS.odist = CREATEOBJECT('distproc', THIS.cowner1, THIS.cowner2, ;
              '01', ;
              THIS.crunyear, ;
              THIS.cGROUP, 'O', THIS.dAcctDate, .F., THIS.nNewRunNo, .F., THIS.lNewRun)

         THIS.odist.lFlatRates = .T.

         m.goApp.oLogger.LogMilestone('Settlement Statements: Calling oDist')
         IF NOT THIS.lClosing
            THIS.odist.MAIN()
         ENDIF

         IF NOT USED('invtmp')
            llReturn = .F.
            EXIT
         ENDIF

         _VFP.AUTOYIELD = .T.
         SET ESCAPE ON

         * Setup the ability to cancel processing
         ON ESCAPE m.goApp.lcanceled = .T.

         m.goApp.oLogger.LogMilestone('Settlement Statements: Calling GetLastType')
         THIS.osuspense.getlasttype(.T., .T., THIS.cGROUP, .T.)

         * Get a copy of invtmp before suspense is added in so
         * we can check for owners who got checks to report
         * the top of the statement properly.
         SELECT * FROM invtmp INTO CURSOR currentrun WHERE crectype # 'P' AND cSuspType = ' '

         m.goApp.oLogger.LogMilestone('Settlement Statements: Building Invtemp and Wellwork')
         * Create invtmp and wellwork cursors with the given run's data
         SELECT invtmp
         SCAN FOR nRunNo_In # 0
            m.cwellid  = cwellid
            m.nRunNo   = nRunNo_In
            m.crunyear = cRunYear_In
            swSelect('wellhist')
            SCAN FOR cwellid == m.cwellid AND crunyear == m.crunyear AND nRunNo == m.nRunNo AND crectype = 'R'
               SCATTER MEMVAR
               SELECT wellwork
               LOCATE FOR crunyear == m.crunyear AND nRunNo == m.nRunNo AND cwellid == m.cwellid AND hyear = m.hyear AND hperiod = m.hperiod AND crectype = 'R'
               IF NOT FOUND()
                  INSERT INTO wellwork FROM MEMVAR
               ENDIF
            ENDSCAN
            *
            * Fill in any empty pcts that came from ownpcts
            * If nnetcheck is not zero there had to be pcts in place when the run was closed
            *
            IF invtmp.nnetcheck # 0 AND ;
                  invtmp.nworkint = 0 AND ;
                  invtmp.nrevgas = 0 AND ;
                  invtmp.nrevoil = 0 AND ;
                  invtmp.nintclass1 = 0 AND ;
                  invtmp.nintclass2 = 0 AND ;
                  invtmp.nintclass3 = 0 AND ;
                  invtmp.nintclass4 = 0 AND ;
                  invtmp.nintclass5 = 0 AND ;
                  invtmp.nbcpint = 0 AND ;
                  invtmp.nacpint = 0 AND ;
                  invtmp.nrevmisc1 = 0 AND ;
                  invtmp.nrevmisc2 = 0
               swSelect('wellinv')
               LOCATE FOR cownerid == invtmp.cownerid AND cwellid == invtmp.cwellid AND cTypeInv == invtmp.cTypeInv
               IF FOUND()
                  SELECT invtmp
                  REPLACE nworkint   WITH wellinv.nworkint, ;
                     nintclass1 WITH wellinv.nintclass1, ;
                     nintclass2 WITH wellinv.nintclass2, ;
                     nintclass3 WITH wellinv.nintclass3, ;
                     nintclass4 WITH wellinv.nintclass4, ;
                     nintclass5 WITH wellinv.nintclass5, ;
                     nacpint    WITH wellinv.nacpint, ;
                     nbcpint    WITH wellinv.nbcpint, ;
                     nrevgas    WITH wellinv.nrevgas, ;
                     nrevoil    WITH wellinv.nrevoil, ;
                     nrevmisc1  WITH wellinv.nrevmisc1, ;
                     nrevmisc2  WITH wellinv.nrevmisc2, ;
                     nrevoth    WITH wellinv.nrevoth, ;
                     nrevtax1   WITH wellinv.nrevtax1, ;
                     nrevtax2   WITH wellinv.nrevtax2, ;
                     nrevtax3   WITH wellinv.nrevtax3, ;
                     nrevtax4   WITH wellinv.nrevtax4, ;
                     nrevtax5   WITH wellinv.nrevtax5, ;
                     nrevtax6   WITH wellinv.nrevtax6, ;
                     nrevtax7   WITH wellinv.nrevtax7, ;
                     nrevtax8   WITH wellinv.nrevtax8, ;
                     nrevtax9   WITH wellinv.nrevtax9, ;
                     nrevtax10  WITH wellinv.nrevtax10, ;
                     nrevtax11  WITH wellinv.nrevtax11, ;
                     nrevtax12  WITH wellinv.nrevtax12
               ELSE
                  LOCATE FOR cownerid == invtmp.cownerid AND cwellid == invtmp.cwellid
                  IF FOUND()
                     SELECT invtmp
                     REPLACE nworkint   WITH wellinv.nworkint, ;
                        nintclass1 WITH wellinv.nintclass1, ;
                        nintclass2 WITH wellinv.nintclass2, ;
                        nintclass3 WITH wellinv.nintclass3, ;
                        nintclass4 WITH wellinv.nintclass4, ;
                        nintclass5 WITH wellinv.nintclass5, ;
                        nacpint    WITH wellinv.nacpint, ;
                        nbcpint    WITH wellinv.nbcpint, ;
                        nrevgas    WITH wellinv.nrevgas, ;
                        nrevoil    WITH wellinv.nrevoil, ;
                        nrevmisc1  WITH wellinv.nrevmisc1, ;
                        nrevmisc2  WITH wellinv.nrevmisc2, ;
                        nrevoth    WITH wellinv.nrevoth, ;
                        nrevtax1   WITH wellinv.nrevtax1, ;
                        nrevtax2   WITH wellinv.nrevtax2, ;
                        nrevtax3   WITH wellinv.nrevtax3, ;
                        nrevtax4   WITH wellinv.nrevtax4, ;
                        nrevtax5   WITH wellinv.nrevtax5, ;
                        nrevtax6   WITH wellinv.nrevtax6, ;
                        nrevtax7   WITH wellinv.nrevtax7, ;
                        nrevtax8   WITH wellinv.nrevtax8, ;
                        nrevtax9   WITH wellinv.nrevtax9, ;
                        nrevtax10  WITH wellinv.nrevtax10, ;
                        nrevtax11  WITH wellinv.nrevtax11, ;
                        nrevtax12  WITH wellinv.nrevtax12
                  ENDIF
               ENDIF
            ENDIF
         ENDSCAN

         m.goApp.oLogger.LogMilestone('Settlement Statements: Removing Zero amount records from Invtmp')

         DELETE  ;
             FROM invtmp ;
             WHERE nworkint = 0 AND ;
                 nrevgas = 0  AND ;
                 nrevoil = 0  AND ;
                 nintclass1 = 0 AND ;
                 nintclass2 = 0 AND ;
                 nintclass3 = 0 AND ;
                 nintclass4 = 0 AND ;
                 nintclass5 = 0 AND ;
                 nbcpint = 0 AND ;
                 nacpint = 0 AND ;
                 ngather = 0 AND ;
                 ncompress = 0 AND ;
                 nnetcheck = 0

         * Add in any records being put into suspense this run
         * when we're reporting on a new run.
         IF THIS.nRunNo = 0
            IF USED('tsuspense')
               SELECT tsuspense
               SCAN
                  SCATTER MEMVAR
                  IF m.nRunNo_In = THIS.nNewRunNo
                     m.nRunNo_In = THIS.nRunNo
                     m.cSuspType = ''
                     INSERT INTO invtmp FROM MEMVAR
                  ENDIF
               ENDSCAN
            ENDIF
         ENDIF

         THIS.odist.lFlatRates = THIS.lflatrate

         WAIT WIND NOWAIT 'Building Report File....'
         LOCAL lnWellTot, lnInvTot, lnTotInc, jInvCnt, lnProgTot, lcoldprog, lcOldcProgName
         LOCAL lnTax, lnInvCnt
         LOCAL lcDirect, lnMinAmt
         LOCAL lcperiod1, lcperiod2, m.cGrpName, llRefId, llChgPrice
         LOCAL llHideComp, jGross

         STORE 0 TO lnWellTot, lnInvTot, lnTotInc, jInvCnt, lnProgTot, ;
            M.ntax, jGross, lnInvCnt
         STORE '   ' TO lcoldprog, lcOldcProgName, lcperiod1, lcperiod2, m.cperiod

         **-
         **-  Get the suspense flag from the group table
         **-
         swSelect('groups')
         SET ORDER TO cGROUP
         IF SEEK(THIS.cGROUP)
            THIS.lnetwells  = lNetDef
         ELSE
            THIS.lnetwells  = .T.
         ENDIF

         * Make sure the checks table is open         
         swSelect('checks')

         * Create "dummy" exptemp cursor
         CREATE CURSOR exptemp (lused L)

         * Create "dummy" inctemp cursor
         CREATE CURSOR inctemp (lused L)

         IF NOT EMPTY(THIS.cDMBatch)
            *  Reset used flag in roundtmp
            IF USED('roundtmp')
               swSelect('roundtmp')
               REPL lused WITH .F. FOR cDMBatch = THIS.cDMBatch
            ENDIF
         ENDIF

         * Set description for whether we're reporting on a well or program
         IF FILE(m.goApp.cCommonFolder + 'sumprogs.txt')
            lcWellProg = 'Program'
         ELSE
            lcWellProg = 'Well'
         ENDIF

         * Create a dummy statemnt cursor to avoid errors
         CREATE CURSOR statemnt (cJunk C(1))

         *  Create work cursor for report data
         CREATE CURSOR  settlement ;
            (cSection       C(1), ;
              cpagebreak     C(10), ;
              cownerid        C(10), ;
              cownname        C(60), ;
              cOwnname1       C(60), ;
              caddress1       C(60), ;
              caddress2       C(60), ;
              ccityState      C(30), ;
              cproducer       C(60), ;
              caddr1          C(60), ;
              caddr2          C(60), ;
              caddr3          C(60), ;
              cphoneno        C(15), ;
              cfaxno          C(15), ;
              czipcode        C(10), ;
              dAcctDate       D, ;
              cDeck           C(10), ;
              cwellid         C(10), ;
              cwellname       C(50), ;
              cstate          C(2), ;
              ccounty         C(25), ;
              cProdDate       C(8), ;
              cyear           C(4), ;
              cperiod         C(2), ;
              cTypeInv        C(1), ;
              cProdType       C(5), ;
              nprice          N(12, 2), ;
              nGrossVol       N(12, 2), ;
              nGrossAmt       N(12, 2), ;
              nPartnerShipVol N(12, 2), ;
              nPartnerShipAmt N(12, 2), ;
              nOwnerVol       N(12, 2), ;
              nOwnerAmt       N(12, 2), ;
              cTaxSection     C(60), ;
              cCategory       C(60), ;
              creference      C(20), ;
              cDescription    C(40), ;
              nPartnerShipPct N(11, 7), ;
              nOwnerPct       N(11, 7), ;
              ccheckno        C(10))

         INDEX ON cownerid + cwellid + cDeck + cSection + cyear + cperiod + cCategory TAG primkey
         *
         *  Get the Accounting Month
         *
         lcAcctPrd = PADL(ALLTRIM(STR(MONTH(THIS.dAcctDate), 2)), 2, '0')

         IF tlSelected
            DELETE FROM invtmp WHERE cownerid NOT IN (SELECT cid FROM SELECTED)
         ELSE
            DELETE FROM invtmp WHERE NOT BETWEEN(cownerid, THIS.cowner1, THIS.cowner2)
         ENDIF

         swclose('invtmpx')
         swclose('owntmp')
         swclose('tmpsusp')
         swclose('invtotx')

         * Remove payments that have the same runno_in as runno
         DELETE  ;
             FROM invtmp ;
             WHERE crectype = 'P' AND (invtmp.nRunNo_In = invtmp.nRunNo ;
                   AND invtmp.cRunYear_In = invtmp.crunyear) ;

         *  Total investor's wells to get check nAmounts
         CREATE CURSOR invtotal ;
            (cownerid     C(10), ;
              hdate        D, ;
              lDirectDep   L, ;
              lSuspense    L, ;
              ntotalcheck  N(12, 2))
         INDEX ON cownerid TAG owner

         m.goApp.oLogger.LogMilestone('Settlement Statements: Getting Owner Totals')
         SELECT  cownerid, ;
                 hdate, ;
                 lDirectDep, ;
                 SUM(ROUND(nnetcheck, 2)) AS ntotalcheck ;
             FROM invtmp ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND nRunNo = THIS.nRunNo ;
                 AND crunyear = THIS.crunyear ;
                 AND cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') # crunyear + PADL(TRANSFORM(nRunNo), 3, '0') ;
                 AND INLIST(crectype, 'R', 'P') ;
             INTO CURSOR invtotX ;
             GROUP BY cownerid ;
             ORDER BY cownerid

         SELECT invtotal
         APPEND FROM DBF('invtotx')
         SELECT invtotX
         USE

         m.goApp.oLogger.LogMilestone('Settlement Statements: Get Suspense Totals')
         * Get the owners that went into suspense totally for this run.
         SELECT  cownerid, ;
                 hdate, ;
                 SUM(ROUND(nnetcheck, 2)) AS ntotalcheck, ;
                 .F. AS lDirectDep, ;
                 .F. AS lSuspense ;
             FROM suspense ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND suspense.nRunNo_In == THIS.nRunNo ;
                 AND suspense.cRunYear_In == THIS.crunyear ;
                 AND cownerid NOT IN (SELECT  cownerid ;
                                          FROM invtotal ;
                                          WHERE ntotalcheck # 0) ;
                 AND crectype = 'R' ;
             INTO CURSOR invtotX ;
             GROUP BY cownerid ;
             ORDER BY cownerid

         IF _TALLY > 0
            SELECT cownerid FROM invtotal INTO CURSOR tempown ORDER BY cownerid GROUP BY cownerid

            SELECT invtotX
            SCAN
               SCATTER MEMVAR
               SELECT invtotal
               LOCATE FOR cownerid == m.cownerid
               IF FOUND()
                  IF ntotalcheck = 0
                     REPLACE ntotalcheck WITH m.ntotalcheck
                  ENDIF
               ELSE
                  INSERT INTO invtotal FROM MEMVAR
               ENDIF
            ENDSCAN
            swclose('invtotX')
         ENDIF

         SELECT  suspense.*, ;
                 .F. AS lDirectDep, ;
                 .T. AS lSuspense ;
             FROM suspense ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND suspense.nRunNo_In == THIS.nRunNo ;
                 AND suspense.cRunYear_In == THIS.crunyear ;
                 AND suspense.crectype = 'R' ;
             INTO CURSOR invtmpx

         SELECT invtmpx
         SCAN
            SCATTER MEMVAR
            THIS.osuspense.GetWellHist(m.cwellid, m.hyear, m.hperiod)
            SELECT invtmp
            LOCATE FOR cwellid = m.cwellid ;
               AND cownerid == m.cownerid ;
               AND cTypeInv = m.cTypeInv ;
               AND hyear + hperiod = m.hyear + m.hperiod ;
               AND nnetcheck = m.nnetcheck
            IF NOT FOUND()
               INSERT INTO invtmp FROM MEMVAR
            ENDIF
         ENDSCAN
         USE IN invtmpx

         * Get the owners that went into suspense for this run.
         SELECT  cownerid, ;
                 hdate, ;
                 SUM(ROUND(nnetcheck, 2)) AS ntotalcheck, ;
                 .F. AS lDirectDep, ;
                 .T. AS lSuspense ;
             FROM disbhist ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND disbhist.nRunNo_In   = THIS.nRunNo ;
                 AND disbhist.cRunYear_In = THIS.crunyear ;
                 AND INLIST(crectype, 'R', 'P') ;
             INTO CURSOR invtotX ;
             GROUP BY cownerid ;
             ORDER BY cownerid

         IF _TALLY > 0
            SELECT invtotX
            SCAN
               SCATTER MEMVAR
               SELECT invtotal
               LOCATE FOR cownerid == m.cownerid
               IF NOT FOUND()
                  INSERT INTO invtotal FROM MEMVAR
               ENDIF
            ENDSCAN
            swclose('invtotX')

            * Get the owner history record to copy to invtmp
            SELECT  disbhist.*, ;
                    ownpcts.*, ;
                    .T. AS lSuspense ;
                FROM disbhist, ownpcts ;
                WHERE cownerid IN (SELECT  cid ;
                                       FROM SELECTED) ;
                    AND crectype # 'P' ;
                    AND disbhist.nRunNo_In   = THIS.nRunNo ;
                    AND disbhist.cRunYear_In = THIS.crunyear ;
                    AND disbhist.ciddisb     = ownpcts.ciddisb ;
                INTO CURSOR invtmpx

            IF USED('invtmpx')
               SELECT invtmpx
               SCAN
                  SCATTER MEMVAR
                  SELECT invtmp
                  LOCATE FOR cwellid = m.cwellid AND cownerid == m.cownerid AND cTypeInv = m.cTypeInv AND hyear + hperiod = m.hyear + m.hperiod AND nnetcheck = m.nnetcheck
                  IF NOT FOUND()
                     INSERT INTO invtmp FROM MEMVAR
                  ENDIF
               ENDSCAN
               USE IN invtmpx
            ENDIF
         ENDIF

         * Make sure all pmt records are owner type "W"
         UPDATE  invtmp SET cTypeInv = 'W' ;
             WHERE crectype = 'P' ;
                 AND cTypeInv = ' '

         * Remove any owners that aren't being emailed         
         IF THIS.lNoEmail
            DELETE FROM invtmp WHERE cownerid IN (SELECT cownerid FROM investor WHERE NOT EMPTY(cemail))
         ENDIF

         * Check to see if prior suspense is in invtmp and it includes payments that zero it out
         * If any are found, remove them because we don't want to report on them here.
         m.goApp.oLogger.LogMilestone('Settlement Statements: Removing payments')
         llSuspenseZero = .F.
         SELECT  *, ;
                 .F. AS junk ;
             FROM invtmp ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND crectype # 'P' ;
                 AND NOT EMPTY(cRunYear_In) ;
                 AND (crunyear + PADL(TRANSFORM(nRunNo), 3, '0') # cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0')) ;
             INTO CURSOR tempinvtmp READWRITE
         SELECT  *, ;
                 .F. AS junk ;
             FROM IIF(THIS.lNewRun, 'invtmp', 'disbhist') ;
             WHERE cownerid IN (SELECT  cid ;
                                    FROM SELECTED) ;
                 AND crunyear + PADL(TRANSFORM(nRunNo), 3, '0') = THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0') ;
                 AND crectype = 'P' ;
             INTO CURSOR tmptmp

         SELECT tempinvtmp
         APPEND FROM DBF('tmptmp')
         USE IN tmptmp
         SELECT tempinvtmp
         IF RECCOUNT() > 0
            SELECT cownerid, SUM(nnetcheck) AS nnetcheck FROM tempinvtmp WHERE nRunNo_In # 0 INTO CURSOR temp ORDER BY cownerid GROUP BY cownerid
            SCAN FOR nnetcheck = 0
               m.cownerid = cownerid
               * Set the flag that tells later processing that suspense was zeroed out
               * so it doesn't try to report a suspense balance.by cownerid
               llSuspenseZero = .T.
               SELECT invtmp
               DELETE  ;
                   FROM invtmp ;
                   WHERE cownerid = m.cownerid AND ;
                       nRunNo_In # 0 ;
                       AND cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') < THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')
            ENDSCAN
         ENDIF

         * Delete payments where nrunno_in = 0
         SELECT invtmp
         DELETE FROM invtmp WHERE crectype = 'P' AND (nRunNo_In = 0 OR (crunyear = cRunYear_In AND nRunNo = nRunNo_In))

         * Build the statemnt file
         SELECT invtmp
         COUNT FOR NOT DELETED() TO lnCount

         IF lnCount <= 0
            ON KEY LABEL esc
            llReturn = .F.
            EXIT
         ENDIF

         * Clear up temporary cursors from previous statements
         swclose('name')

         * Check to see if we're processing a new or closed run
         THIS.lclosed = (NOT THIS.nRunNo = 0)

         *  Build a cursor for storing owner statement notes
         CREATE CURSOR ownnotes ;
            (cownerid  C(10), ;
              cwellid   C(10), ;
              mNotes    M)

         *
         *  Initialize memory variables
         *
         STORE ' ' TO m.crptgoup, m.cownerid, m.cownname, m.caddr1, m.caddr2, m.ccitycstate, ;
            M.cyear, m.cperiod, m.coilprd1, m.coilprd2, m.cgasprd1, m.cgasprd2, m.cphoneno, ;
            M.cwellid, m.cwellname, m.csource, m.cCategory, m.cpayee, m.cTypeInv, m.cfaxno, ;
            M.ctypeint, m.cMiscMemo, m.cDescript, lcoldprog, lcoldprogname, lcperiod1, lcperiod2
         STORE 0   TO m.ntotalcheck, m.nunits, m.nprice, m.ninvamt, m.nRevInt, ;
            M.nWorkTot, m.nlandpct, m.noverpct, m.nAmount, m.nworkint, THIS.nownertotal, ;
            M.nintclass1, m.nintclass2, m.nintclass3, m.nintclass4, m.nintclass5
         STORE 0 TO lnowncount, THIS.nwelltot, THIS.ntotinc, lnperiodbal

         m.crunyear = THIS.crunyear

         STORE .F. TO THIS.lexemptroyalty, m.lDirOilPurch, m.lDirGasPurch, m.ljib

         * Create cursor to hold program totals
         CREATE CURSOR progtots ;
            (cownerid   C(10), ;
              cprogcode  C(10), ;
              nprogtot   N(12, 2))

         swSelect('options')
         GO TOP
         SCATTER NAME THIS.ooptions

         glStminv       = lstminv
         gnmincheck     = nmincheck
         glhidecomp     = lHideComp
         glshowroy      = lshowroy
         glacctdesc     = lacctdesc
         glrefid        = lrefid
         glexpsum       = lexpsum
         glRevSum       = lRevSum
         glchgprice     = lChgPrice
         gngather       = ngather
         gncompress     = ncompress
         gldirinv       = ldirinv
         llroycomp      = lroycomp
         llbilldesc     = lbilldesc
         llshowvendor   = lshowvendor
         m.lExpDate     = lExpDate
         m.glExpDate    = lExpDate
         m.lNoFirstName = lNoFirstName

         swSelect('sysctl')
         LOCATE FOR crunyear == THIS.crunyear AND nRunNo == THIS.nRunNo AND ctypeclose = 'R' AND ldisbman
         IF FOUND()
            THIS.lSumExp  = lSumExp
            THIS.lSumRev  = lSumRev
            THIS.dRevDate = dRevDate
            THIS.dExpDate = dExpDate
         ELSE
            THIS.lSumExp  = glexpsum
            THIS.lSumRev  = glRevSum
            THIS.dRevDate = THIS.dAcctDate
            THIS.dExpDate = THIS.dAcctDate
         ENDIF

         m.goApp.oLogger.LogMilestone('Settlement Statements: Get Rounding Amounts')
         * Get the rounding amounts for the runs showing on this statement.  This includes suspense
         SELECT  sysctl.cDMBatch, ;
                 invtmp.cwellid, ;
                 invtmp.nRunNo_In, ;
                 invtmp.cRunYear_In ;
             FROM sysctl, invtmp ;
             WHERE (sysctl.nRunNo = invtmp.nRunNo_In ;
                   AND sysctl.crunyear = invtmp.cRunYear_In) ;
                 AND NOT EMPTY(invtmp.cSuspType) ;
             INTO CURSOR tempdmbatch READWRITE ;
             ORDER BY cDMBatch, cwellid ;
             GROUP BY cDMBatch, cwellid

         SELECT cwellid FROM invtmp INTO CURSOR tmpwells ORDER BY cwellid GROUP BY cwellid
         SELECT tmpwells
         SCAN
            SCATTER MEMVAR
            SELECT tempdmbatch
            LOCATE FOR cDMBatch = THIS.cDMBatch AND cwellid == m.cwellid
            IF NOT FOUND()
               m.cDMBatch = THIS.cDMBatch
               INSERT INTO tempdmbatch FROM MEMVAR
            ENDIF
         ENDSCAN

         * Get producer's address information
         * Check on the existence of the application object
         * if it doesn't exist, we're running in development
         * mode and need to initialize the company address info.
         IF TYPE('m.goApp') = 'O'
            m.caddr1    = m.goApp.caddress1
            m.caddr2    = m.goApp.caddress2
            m.caddr3    = m.goApp.caddress3
            m.ctax      = m.goApp.ctaxid
            m.cphoneno  = m.goApp.cphoneno
            m.cfaxno    = m.goApp.cfaxno
            m.cproducer = m.goApp.ccompanyname
            IF EMPTY(m.goApp.ccompanyname) OR ALLT(m.goApp.ccompanyname) = "''"
               m.goApp.ccompanyname = 'Sherwood Energy'

               IF EMPTY(m.caddr1) OR ALLT(m.caddr1) = "''"
                  m.caddr1 = 'PO Box 209'
               ENDIF
               IF EMPTY(m.caddr2) OR ALLT(m.caddr2) = "''"
                  m.caddr2 = 'Apple Creek, OH 44606'
               ENDIF
               IF EMPTY(m.caddr3) OR ALLT(m.caddr3) = "''"
                  m.caddr3 = ''
               ENDIF
            ENDIF
         ELSE
            m.caddr1 = 'PO Box 223'
            m.caddr2 = 'Wooster, OH  44691'
            m.caddr3 = ''
            m.ctax   = '99-9999999'
         ENDIF


         *  Get the total invtmp records we're going to process so the progress bar updates correctly.
         m.goApp.oLogger.LogMilestone('Settlement Statements: Set up progress bar')
         SELECT invtmp
         lnCount = 1
         IF NOT THIS.lNoSuspDet
            COUNT FOR BETWEEN(cownerid, THIS.cowner1, THIS.cowner2) TO lnMax
         ELSE
            COUNT FOR BETWEEN(cownerid, THIS.cowner1, THIS.cowner2) ;
               AND IIF(NOT EMPTY(cSuspType), ;
                 PADL(TRANSFORM(nRunNo_In), 3, '0') + cRunYear_In = PADL(TRANSFORM(THIS.nRunNo), 3, '0') + ;
                 THIS.crunyear, .T.) TO lnMax
         ENDIF
         IF lnMax = 0
            llReturn = .F.
            EXIT
         ENDIF
         GO TOP

         *  Add back exempt owners taxes
         THIS.odist.Taxexempt(.T.)

         THIS.oProgress = THIS.omessage.ProgressBarEX('Building Owner Statements....Press ESC To Cancel')
         THIS.oProgress.SetProgressRange(0, lnMax)

         *
         *  Reset the one-man-item flag in the Income file.  (<><><><> Check this. It could potentially be really slow <><><> - pws 10/12/17)
         *
         swSelect('income')
         REPLACE loneman WITH .F. FOR loneman = .T.

         *  Remove owner history records with no production if we're not reporting non producing wells.
         m.goApp.oLogger.LogMilestone('Settlement Statements: Removing wells with no production')
         IF THIS.lnoprod = .F.
            SELE invtmp
            SCAN
               IF invtmp.nincome = 0 AND ;
                     (invtmp.nexpense + invtmp.ntotale1 + invtmp.ntotale2 + ;
                       invtmp.ntotale3 + invtmp.ntotale4 + invtmp.ntotale5 + ;
                       invtmp.nTotaleA + invtmp.nTotaleB + invtmp.nPlugExp) = 0 ;
                     AND invtmp.nsevtaxes = 0 AND invtmp.nnetcheck = 0
                  SELE stmtnote
                  LOCATE FOR cwellid == invtmp.cwellid AND nRunNo == invtmp.nRunNo AND crunyear == invtmp.crunyear
                  IF FOUND()
                     DO CASE
                        CASE stmtnote.nnotetype = 1
                           IF invtmp.cTypeInv = 'L'
                              LOOP
                           ENDIF
                        CASE stmtnote.nnotetype = 2
                           IF invtmp.cTypeInv = 'O'
                              LOOP
                           ENDIF
                        CASE stmtnote.nnotetype = 3
                           IF invtmp.cTypeInv = 'O' OR invtmp.cTypeInv = 'L'
                              LOOP
                           ENDIF
                        CASE stmtnote.nnotetype = 4
                           IF invtmp.cTypeInv = 'W'
                              LOOP
                           ENDIF
                        CASE stmtnote.nnotetype = 5
                           LOOP
                     ENDCASE
                  ENDIF
                  IF NOT THIS.checkincexp(invtmp.cwellid, invtmp.hyear, invtmp.hperiod, invtmp.nRunNo, invtmp.crunyear)
                     SELECT invtmp
                     DELE NEXT 1
                  ENDIF
               ENDIF
            ENDSCAN
         ELSE
            SELECT  cownerid, ;
                    cwellid ;
                FROM invtmp ;
                INTO CURSOR temp1 ;
                ORDER BY cownerid, cwellid ;
                GROUP BY cownerid, cwellid

            swSelect('wellinv')
            SCAN
               SELECT SELECTED
               LOCATE FOR cid = wellinv.cownerid
               IF NOT FOUND()
                  LOOP
               ENDIF
               SELECT temp1
               LOCATE FOR cownerid == wellinv.cownerid AND cwellid == wellinv.cwellid
               IF NOT FOUND()
                  SELECT invtmp
                  SCATTER MEMVAR BLANK
                  swSelect('wells')
                  LOCATE FOR cwellid == wellinv.cwellid
                  IF FOUND() AND cGROUP = THIS.cGROUP
                     swSelect('wellinv')
                     SCATTER MEMVAR
                     m.nRunNo   = THIS.nRunNo
                     m.crunyear = THIS.crunyear
                     INSERT INTO invtmp FROM MEMVAR
                  ENDIF
               ENDIF
            ENDSCAN
         ENDIF

         * Get unique owner, well and owner types
         SELECT  cownerid, ;
                 cwellid, ;
                 cTypeInv, ;
                 .F. AS lwellpage ;
             FROM invtmp ;
             WHERE NOT EMPTY(cTypeInv) ;
             INTO CURSOR owntypes ;
             ORDER BY cownerid, cwellid, cTypeInv ;
             GROUP BY cownerid, cwellid, cTypeInv

         * Start building a statement for each owner
         SELECT invtotal
         SCAN
            IF m.goApp.lcanceled
               llReturn          = .F.
               IF NOT m.goApp.CancelMsg()
                  THIS.lcanceled = .T.
                  EXIT
               ENDIF
            ENDIF

            m.goApp.oLogger.LogMilestone('Settlement Statements: Building Statements - Owner: ' + invtotal.cownerid)

            * Reset the rounding flag
            THIS.lrounding = .F.
            SCATTER MEMVAR

            * Get the check number for this owner
            SELECT checks
            LOCATE FOR cbatch = THIS.cDMBatch ;
               AND cid = m.cownerid
            IF FOUND()
               m.ccheckno = ccheckno
            ELSE
               m.ccheckno = ''
            ENDIF

            * Get the direct deposit flag for the owner
            llDirDep = m.lDirectDep

            * Reset expense used flag if new owner
            IF USED('exptemp')
               SELECT exptemp
               REPLACE lused WITH .F. ALL
            ENDIF

            * Set a flag that we're working with a different owner than before
            llnewowner = .T.

            * Save the current owner since we have to check for one-man items
            THIS.cownerid = m.cownerid
            STORE ' ' TO THIS.ownergroup
            STORE 0 TO THIS.nownertotal

            jTotal         = m.ntotalcheck

            m.nTotalBal    = m.ntotalcheck
            THIS.cSuspType = ''

            SELECT invtotal
            m.dAcctDate = THIS.dAcctDate
            m.crptgroup = 'A'
            m.cyear     = THIS.crunyear
            m.cownerid  = THIS.cownerid
            swSelect('investor')
            SET ORDER TO cownerid
            IF SEEK(THIS.cownerid)
               *
               *  Check to see if this investors deficit cStatement should be printed
               *
               SCATTER MEMVAR

               * Get the owner's minimum check amount
               THIS.nownermin = ninvmin

               * This owner posts to G/L instead of getting a check
               THIS.lownerposted = lIntegGL
               m.lownerposted    = lIntegGL

               m.lwellpage = lwellpage

               * Skip out on processing direct deposits if the
               * option isn't chosen.
               IF NOT llIncludeDirDep AND investor.lDirectDep
                  LOOP
               ENDIF

               * Setup for page breaks
               IF m.lwellpage
                  m.pcbreak = 'cwellid'
               ELSE
                  m.pcbreak = '" " '
               ENDIF

               * Check to see if this owner should get a detail stmt
               IF THIS.ldetail
                  IF investor.nstmttype # 0 AND ;
                        investor.nstmttype # 1
                     LOOP
                  ENDIF
               ENDIF

               * Only process owners whose statements are to be emailed.
               IF THIS.lEmailOnly
                  IF investor.nstmttype # 3
                     LOOP
                  ENDIF
               ENDIF

               THIS.lownertaxexempt = lExempt
               m.lHold              = .T.
               m.lOnHold            = .T.

               m.ninvmin = 999999
               SELECT invtmp
               SCAN FOR cownerid = THIS.cownerid AND ;
                     ((nRunNo = THIS.nNewRunNo AND crunyear = THIS.crunyear) OR (nRunNo_In = THIS.nNewRunNo AND cRunYear_In = THIS.crunyear))

                  * pws - 2009/02/06  Added the check for nrunno_in to make sure if the owner is no longer
                  *                   held, the statement will still print.
                  IF invtmp.cSuspType = 'H' AND invtmp.nRunNo_In = THIS.nNewRunNo AND cRunYear_In == THIS.crunyear
                     REPLACE lHold WITH .T.
                  ELSE
                     REPLACE lHold WITH .F.
                     m.lHold = .F.
                  ENDIF

                  IF invtmp.cSuspType # 'M'
                     m.ninvmin = THIS.nownermin
                  ENDIF

                  IF invtmp.cSuspType = 'I'
                     REPLACE lOnHold WITH .T.
                  ENDIF

                  m.lOnHold = m.lOnHold AND lOnHold

               ENDSCAN

               * This owner is on hold
               IF m.lHold
                  THIS.cSuspType = 'H'
               ENDIF

               * All the owner's interests are on hold
               IF m.lOnHold
                  THIS.cSuspType = 'I'
               ENDIF

               THIS.lowneronhold    = m.lHold

               THIS.oProgress.SetProgressMessage('Building Statement for ' + csortfield)
               IF investor.lprtdef = .F. AND m.ntotalcheck < 0
                  SELECT invtotal
                  LOOP
               ENDIF

               *
               *  Don't print dummy owner cStatements
               *
               IF investor.lDummy
                  LOOP
               ENDIF

               IF THIS.lclosed
                  IF THIS.odist.lRelmin
                     THIS.lallminsreleased = .T.
                     m.ninvmin             = 0
                  ELSE
                     IF m.ninvmin = 0
                        m.ninvmin = gnmincheck
                     ENDIF
                  ENDIF
               ELSE
                  IF m.ninvmin = 0
                     m.ninvmin = THIS.ooptions.nmincheck
                  ENDIF
               ENDIF

               STORE 0 TO THIS.nbackupwith, THIS.ntaxwith

               **-
               **-  Setup the minimum check nAmount so that the Statement can
               **-  notify the owner if the net Amount is below the minimum.
               **-
               DO CASE
                  CASE THIS.lowneronhold        && Owner on hold - set minimum to max so owner stays on hold
                     m.ninvmin = 99999999
                  CASE THIS.lallminsreleased    && Releasing minimums - set minimum amount to zero
                     m.ninvmin = 0
                  CASE m.ndisbfreq = 2          && Quarterly owner - set minimum to max if not at the end of qtr
                     IF NOT INLIST(lcAcctPrd, '03', '06', '09', '12')
                        m.ninvmin = 99999999
                     ENDIF
                  CASE m.ndisbfreq = 3          && SemiAnnually owner - set minimum to max if not at middle or end of year
                     IF NOT INLIST(lcAcctPrd, '06', '12')
                        m.ninvmin = 99999999
                     ENDIF
                  CASE m.ndisbfreq = 4          && Annual owner - set minimum to max if not at end of year
                     IF lcAcctPrd # '12'
                        m.ninvmin = 99999999
                     ENDIF
               ENDCASE

               THIS.nownermin = m.ninvmin

               IF m.ntotalcheck < m.ninvmin AND m.ntotalcheck >= 0
                  THIS.cSuspType = 'M'
               ENDIF

               **-
               **-  If the statment should be sent to the secondary address
               **-  pull in the secondary address, otherwise pull in the
               **-  primary address.
               **-
               IF m.lchktosec AND NOT m.lcheckonly
                  m.cownname  = m.cownname
                  m.cOwnname1 = m.cownname2
                  IF m.lNoFirstName &&  Don't use the primary  name with a secondary address
                     m.cownname  = m.cownname2
                     m.cOwnname1 = ''
                  ENDIF
                  m.caddress1 = m.caddress2a
                  IF NOT EMPTY(m.caddress2b)
                     m.caddress2  = m.caddress2b
                     m.ccityState = ALLTRIM(m.ccity2) + ' ' + m.cstate2 + '  ' + m.czip2
                     m.czipcode   = m.czip2
                  ELSE
                     m.caddress2  = ALLTRIM(m.ccity2) + ' ' + m.cstate2 + '  ' + m.czip2
                     m.ccityState = ' '
                     m.czipcode   = m.czip2
                  ENDIF
               ELSE
                  IF NOT EMPTY(m.caddress1a)
                     m.caddress1 = m.caddress1a
                     IF NOT EMPTY(m.caddress1b)
                        m.caddress2  = m.caddress1b
                        m.ccityState = ALLTRIM(m.ccity1) + ' ' + m.cstate1 + '  ' + m.czip1
                        m.czipcode   = m.czip1
                     ELSE
                        m.caddress2  = ALLTRIM(m.ccity1) + ' ' + m.cstate1 + '  ' + m.czip1
                        m.ccityState = ''
                        m.czipcode   = m.czip1
                     ENDIF
                  ELSE
                     IF NOT EMPTY(m.caddress1b)
                        m.caddress1  = m.caddress1b
                        m.caddress2  = ALLTRIM(m.ccity1) + ' ' + m.cstate1 + '  ' + m.czip1
                        m.ccityState = ''
                        m.czipcode   = m.czip1
                     ELSE  &&  Blank out address for people with no address, so it doesn't just carry forward the same address from the last owner who had an address filled in
                        m.caddress1  = ''
                        m.caddress2  = ''
                        m.ccityState = ''
                        m.czipcode   = m.czip1
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF

            llWellProd = .F.

            * Build a cursor of totals for the owner and well
            SELE SUM(ngrossgas + ngrossoil) AS nbal FROM wellwork ;
               INTO CURSOR tempgross ORDER BY cwellid GROUP BY cwellid

            *  Start scan of owner types.  We need to scan through wellwork for each owner type record so
            *  that if an owner has more than one interest in the well, we'll process for each interest.
            SELE owntypes
            SCAN FOR cownerid = THIS.cownerid

               lcTypeOwner  = owntypes.cTypeInv
               THIS.cwellid = owntypes.cwellid

               IF m.lwellpage
                  m.cpagebreak = THIS.cwellid
               ELSE
                  m.cpagebreak = ''
               ENDIF

               THIS.lflatalloc = .F.
               tnRunNo         = THIS.nRunNo
               tcRunYear       = THIS.crunyear

               * Scan through the temp owner history for each record with the given ownerid,
               * well, owner type and production period
               SELECT invtmp
               SET ORDER TO ownertype
               SCAN FOR cownerid  = THIS.cownerid ;
                     AND cwellid  = THIS.cwellid ;
                     AND cTypeInv = lcTypeOwner

                  IF m.goApp.lcanceled
                     llReturn          = .F.
                     IF NOT m.goApp.CancelMsg()
                        THIS.lcanceled = .T.
                        EXIT
                     ENDIF
                  ENDIF

                  * Remove the suspense record if we're not showing suspense detail
                  IF THIS.lNoSuspDet ;
                        AND NOT EMPTY(invtmp.cSuspType) ;
                        AND (invtmp.cRunYear_In + PADL(TRANSFORM(invtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0'))
                     LOOP
                  ENDIF

                  *  Update the progress bar
                  THIS.oProgress.UpdateProgress(lnCount)
                  lnCount = lnCount + 1

                  STORE 0 TO m.nTotNet

                  SELECT wellwork
                  LOCATE FOR cwellid == THIS.cwellid AND hyear = invtmp.hyear AND hperiod = invtmp.hperiod AND crectype = 'R'
                  IF FOUND()
                     SCATTER NAME THIS.owellwork
                     m.nRoyalty = nRoyInt
                  ELSE
                     *  We only want to loop if it's a non-manual entry, since those probably won't find a match in wellwork anyway - BH 08/04/2009
                     IF NOT invtmp.lmanual
                        LOOP
                     ENDIF
                  ENDIF

                  SELECT invtmp
                  llnoprod      = .F.
                  m.nRunNo_In   = nRunNo_In
                  m.cRunYear_In = cRunYear_In
                  m.nflatrate   = nflatrate
                  m.lFlat       = lFlat

                  IF THIS.lnoprod = .T.
                     SELE tempgross
                     LOCATE FOR cwellid = THIS.cwellid
                     IF nbal # 0
                        llWellProd = .T.
                        IF THIS.ownergroup # ' '   && If this isn't the 1st time through for this owner
                           IF invtmp.nincome = 0 AND ;
                                 (invtmp.nexpense + invtmp.ntotale1 + invtmp.ntotale2 + ;
                                   invtmp.ntotale3 + invtmp.ntotale4 + invtmp.ntotale5 + ;
                                   invtmp.nTotaleA + invtmp.nTotaleB + invtmp.nPlugExp) = 0 ;
                                 AND invtmp.nsevtaxes = 0 AND invtmp.nnetcheck = 0 AND invtmp.nmktgexp = 0
                              *  Don't process invtmp records for periods with no activity if we have
                              *  invtmp records for the same well with activity.  This prevents multple
                              *  "A" rptgroup records in statemnt
                              LOOP     && Loop back to invtmp scan
                           ENDIF
                        ENDIF
                     ELSE
                        llWellProd = .F.
                     ENDIF
                  ENDIF

                  *  Set the flag that tells whether we have production this period or not.
                  IF invtmp.nincome = 0 AND ;
                        (invtmp.nexpense + invtmp.ntotale1 + invtmp.ntotale2 + ;
                          invtmp.ntotale3 + invtmp.ntotale4 + invtmp.ntotale5 + ;
                          invtmp.nTotaleA + invtmp.nTotaleB + invtmp.nPlugExp) = 0 ;
                        AND invtmp.nsevtaxes = 0 AND invtmp.nnetcheck = 0 AND invtmp.nmktgexp = 0
                     IF THIS.checkincexp(invtmp.cwellid, invtmp.hyear, invtmp.hperiod, THIS.nRunNo, THIS.crunyear)
                        llnoprod   = .F.
                        llWellProd = .T.
                     ELSE
                        llnoprod   = .T.
                        llWellProd = .F.
                     ENDIF
                  ELSE
                     llnoprod   = .F.
                     llWellProd = .T.
                  ENDIF

                  SELE invtmp
                  IF EMPTY(cTypeInv)
                     *                     REPLACE cTypeInv WITH 'B'
                  ENDIF

                  *  Process net well totals when not splitting prod prds into their own section
                  THIS.NetWellTotalNoSplit()

                  *  Continue scan through invtmp
                  SELE invtmp
                  * Create the oInvTmp object so other methods have access to this record
                  SCATTER NAME THIS.oinvtmp
                  m.cSuspType = invtmp.cSuspType

                  THIS.cyear   = THIS.oinvtmp.hyear
                  THIS.cperiod = THIS.oinvtmp.hperiod

                  IF THIS.lsplitperiods
                     lnowncount = lnowncount + 1
                     m.cWellType = invtmp.cownerid + invtmp.cwellid + ;
                        invtmp.cTypeInv + STR(lnowncount, 1) + invtmp.hyear + invtmp.hperiod
                  ELSE
                     m.cWellType = invtmp.cownerid + invtmp.cwellid + ;
                        invtmp.cTypeInv + STR(lnowncount, 1)
                  ENDIF

                  *
                  *  Determine if investor is a Royalty owner
                  *
                  IF THIS.oinvtmp.cTypeInv = 'L' OR THIS.oinvtmp.cTypeInv = 'O'
                     THIS.lroyaltyowner = .T.
                  ELSE
                     THIS.lroyaltyowner = .F.
                  ENDIF

                  m.crptgroup = 'A'
                  m.cSuspType = ''

                  *  Get the current well's info into memory variables
                  swSelect('wells')
                  SET ORDER TO cwellid
                  SEEK THIS.cwellid
                  IF FOUND()
                     SCATTER MEMVAR
                     m.nRoyInt    = nlandpct + noverpct
                     IF m.ncompress # 0
                        THIS.ncompress = wells.ncompress
                     ELSE
                        THIS.ncompress = THIS.ooptions.ncompress
                     ENDIF
                     IF m.ngather # 0
                        THIS.ngather = wells.ngather
                     ELSE
                        THIS.ngather = THIS.ooptions.ngather
                     ENDIF
                     THIS.lexemptroyalty = lroysevtx
                  ELSE
                     * Not a valid well so loop out...Shouldn't ever get here.
                     LOOP    && Loop back to invtmp scan
                  ENDIF

                  m.cDescript = ' '
                  m.cownerid  = THIS.cownerid

                  ************************************************************************************
                  **** PROCESSING FOR COMBINING PRODUCTION PERIOD TOGETHER UNDER ONE WELL HEADER *****
                  ************************************************************************************
                  IF NOT THIS.lsplitperiods    && Keeping production periods together
                     * If we're including wells with no production and the current well has no production
                     * insert a header record into the statement file.
                     IF THIS.lnoprod = .T. AND NOT llWellProd
                        m.nRunNo    = THIS.nRunNo
                        m.crunyear  = THIS.crunyear
                        m.cprogcode = THIS.oinvtmp.cprogcode
                        swSelect('programs')
                        LOCATE FOR cprogcode = m.cprogcode
                        IF FOUND()
                           m.cProgName = cProgName
                        ELSE
                           m.cProgName = ''
                        ENDIF
                        m.crunyear = THIS.crunyear
                     ELSE
                        *  Only insert a header record if the well has production at this point or if there are statement notes.
                        IF llWellProd
                           IF THIS.oinvtmp.crectype # 'P'
                              SELE statemnt
                              LOCATE FOR cWellType = m.cWellType AND crptgroup = 'A'
                              IF NOT FOUND()
                                 m.nRunNo    = THIS.nRunNo
                                 m.cprogcode = THIS.oinvtmp.cprogcode
                                 m.crunyear  = THIS.crunyear
                              ENDIF
                           ENDIF
                        ELSE
                           * Check to see if there are statement notes, and if so, insert an A record.
                           swSelect('stmtnote')
                           LOCATE FOR cwellid == THIS.oinvtmp.cwellid AND nRunNo == THIS.oinvtmp.nRunNo AND crunyear == THIS.oinvtmp.crunyear
                           IF FOUND()
                              DO CASE
                                 CASE stmtnote.nnotetype = 1
                                    IF THIS.oinvtmp.cTypeInv # 'L'
                                       LOOP
                                    ENDIF
                                 CASE stmtnote.nnotetype = 2
                                    IF THIS.oinvtmp.cTypeInv # 'O'
                                       LOOP
                                    ENDIF
                                 CASE stmtnote.nnotetype = 3
                                    IF (THIS.oinvtmp.cTypeInv # 'O' AND THIS.oinvtmp.cTypeInv # 'L')
                                       LOOP
                                    ENDIF
                                 CASE stmtnote.nnotetype = 4
                                    IF THIS.oinvtmp.cTypeInv # 'W'
                                       LOOP
                                    ENDIF
                              ENDCASE
                              swSelect('statemnt')
                              LOCATE FOR cWellType = m.cWellType AND crptgroup = 'A'
                              IF NOT FOUND()
                                 m.nRunNo    = THIS.nRunNo
                                 m.cprogcode = THIS.oinvtmp.cprogcode
                                 m.crunyear  = THIS.crunyear
                              ENDIF
                           ENDIF
                        ENDIF
                     ENDIF
                     llwellstmt   = .T.
                  ELSE
                     m.nRunNo    = THIS.nRunNo
                     m.crunyear  = THIS.crunyear
                     m.cprogcode = THIS.oinvtmp.cprogcode
                     m.cWellType = m.cownerid + m.cwellid + m.cTypeInv + '0'
                     llwellstmt  = .T.
                  ENDIF
                  ************************************************************************************
                  **** PROCESSING FOR COMBINING PRODUCTION PERIOD TOGETHER UNDER ONE WELL HEADER *****
                  ************************************************************************************

                  *  If this is a flat rate royalty owner, insert the flat rate into the income section
                  IF invtmp.lFlat AND invtmp.nflatrate # 0
                     m.crptgroup = 'B'
                     IF invtmp.nflatrate = 0
                        *  Flat rate owner but no flat rate amount - loop back to invtmp
                        LOOP
                     ENDIF

                     m.ninvamt        = invtmp.nflatrate
                     THIS.nownertotal = THIS.nownertotal + invtmp.nflatrate
                     m.cDescript      = ' '
                     m.cTYPE          = 'FLT'
                     m.lFlat          = .T.
                     m.csource        = 'Flat-Rate Royalty'
                     m.cProdDate      = THIS.GetProdDate(invtmp.hyear, invtmp.hperiod)
                     m.cyear          = invtmp.hyear
                     m.cperiod        = invtmp.hperiod
                     m.cownerid       = THIS.cownerid
                     m.nRunNo         = THIS.nRunNo
                     m.cprogcode      = THIS.oinvtmp.cprogcode
                     THIS.ntotinc     = THIS.ntotinc + m.ninvamt
                     THIS.nwelltot    = THIS.nwelltot + m.ninvamt
                     m.crunyear       = THIS.crunyear
                     *********************************************************************************************************
                     *  Insert into the settlement file  - section 1
                     *********************************************************************************************************
                     INSERT INTO settlement FROM MEMVAR
                     *********************************************************************************************************
                  ENDIF

                  *  Initialize work properties that need to be passed between methods
                  STORE ' ' TO m.oprng1, m.oprng2, m.gprng1, m.gprng2
                  STORE 0 TO THIS.noiltax1, THIS.noiltax2, THIS.noiltax3, THIS.noiltax4
                  STORE 0 TO THIS.ngastax1, THIS.ngastax2, THIS.ngastax3, THIS.ngastax4
                  STORE 0 TO THIS.nothtax1, THIS.nothtax2, THIS.nothtax3, THIS.nothtax4
                  STORE 0 TO jflatcnt
                  STORE 'N' TO m.cdirect

                  * If this record wasn't created during this run
                  * get the real runno from runno_in so that the
                  * original income entries can be pulled.
                  IF THIS.oinvtmp.nRunNo_In # 0 AND (THIS.oinvtmp.cRunYear_In + PADL(THIS.oinvtmp.nRunNo_In, 3, '0') # THIS.crunyear + PADL(THIS.nRunNo, 3, '0'))
                     lnRevRun  = THIS.oinvtmp.nRunNo_In
                     tnRunNo   = THIS.oinvtmp.nRunNo_In
                     tcRunYear = THIS.oinvtmp.cRunYear_In
                  ELSE
                     * Use the runno we were called with in case it was 0
                     * Changed to use the next runno if runno is zero - pws 1/20/09
                     lnRevRun  = THIS.nNewRunNo
                     tcRunYear = THIS.crunyear
                  ENDIF
                  THIS.lnotax = .F.
                  *************************************************************
                  *  Process Flat-Rates to deduct them from working interests
                  *************************************************************
                  THIS.flatowner(THIS.oinvtmp.nRunNo_In # 0 AND THIS.oinvtmp.nRunNo_In # THIS.nRunNo, tcRunYear, lnRevRun)

                  STORE 0 TO jnflatoil, jnflatgas
                  STORE ' ' TO m.cTYPE

                  *************************************************************
                  *  Process Income
                  *************************************************************

                  IF THIS.oinvtmp.lmanual OR ;
                        NOT THIS.calcincome(THIS.cwellid, lnRevRun, tcRunYear, THIS.oinvtmp.hyear, THIS.oinvtmp.hperiod, THIS.dRevDate)
                     IF NOT EMPTY(invtmp.cSuspType)
                        IF invtmp.nincome # 0
                           *  Get the total of the flat rates already processed for this owner, so it can be
                           *  subtracted off this entry.  If it leaves zero, don't add it to the statement.
                           lnFlatTotal = 0
                           SELECT statemnt
                           LOCATE FOR cownerid == m.cownerid AND ;
                              cwellid == m.cwellid   AND ;
                              cTYPE = 'FLT'          AND ;
                              ninvamt = invtmp.nincome AND ;
                              cyear   = invtmp.hyear AND ;
                              cperiod = invtmp.hperiod
                           IF NOT FOUND()

                              m.cSection    = '1'
                              m.cProdType   = 'SUSP'
                              m.nunits      = 0
                              m.nprice      = 0
                              m.cyear       = invtmp.hyear
                              m.cperiod     = invtmp.hperiod
                              m.nAmount     = invtmp.nincome - invtmp.nsevtaxes - lnFlatTotal - invtmp.ncompress - invtmp.ngather
                              m.ninvamt     = invtmp.nincome - invtmp.nsevtaxes - lnFlatTotal - invtmp.ncompress - invtmp.ngather
                              m.nTOTAL      = invtmp.nincome - invtmp.nsevtaxes - lnFlatTotal - invtmp.ncompress - invtmp.ngather
                              THIS.ntotinc  = THIS.ntotinc + m.ninvamt
                              THIS.nwelltot = THIS.nwelltot + m.ninvamt
                              m.nRevInt     = 100
                              m.cTYPE       = 'OTH'
                              m.cdirect     = 'N'
                              m.cTypeInv    = invtmp.cTypeInv
                              m.crunyear    = THIS.crunyear
                              IF m.ninvamt # 0
                                 INSERT INTO statemnt FROM MEMVAR
                              ENDIF
                           ENDIF
                           THIS.lnotax = .T.
                        ENDIF
                     ENDIF
                  ENDIF

                  STORE 0 TO m.ninvamt, m.nTOTAL, m.nprice, m.nunits, m.nRevInt
                  STORE ' ' TO m.cTYPE, m.csource, m.crange


                  *************************************************************
                  *  Process taxes
                  *************************************************************
                  IF NOT THIS.lnotax
                     THIS.calctaxes(THIS.cwellid, lnRevRun, tcRunYear, THIS.oinvtmp.hyear, THIS.oinvtmp.hperiod, THIS.dRevDate, THIS.oinvtmp.cSuspType)
                  ENDIF

                  THIS.lnotax = .F.
                  STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
                  STORE ' ' TO m.csource, m.cTYPE, m.cMethod
                  *************************************************************
                  *  Process Gathering and Compression Charges
                  *************************************************************
                  IF NOT THIS.oinvtmp.lmanual
                     THIS.CalcCompress()
                  ENDIF
                  STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
                  STORE ' ' TO m.csource, m.cTYPE, m.cDescript

                  *************************************************************
                  *  Process Marketing Charges
                  *************************************************************
                  IF THIS.oinvtmp.nmktgexp # 0 AND NOT THIS.oinvtmp.lmanual
                     THIS.CalcMktg()
                  ENDIF
                  STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
                  STORE ' ' TO m.csource, m.cTYPE, m.cDescript

                  *************************************************************
                  *  Process expenses
                  *************************************************************
                  IF NOT THIS.CalcExpense(lnRevRun, tcRunYear, THIS.oinvtmp.hyear, THIS.oinvtmp.hperiod, THIS.dExpDate)
                     IF NOT EMPTY(invtmp.cSuspType) OR invtmp.lmanual
                        IF invtmp.nexpense # 0 OR ;
                              invtmp.ntotale1 # 0 OR ;
                              invtmp.ntotale2 # 0 OR ;
                              invtmp.ntotale3 # 0 OR ;
                              invtmp.ntotale4 # 0 OR ;
                              invtmp.ntotale5 # 0 OR ;
                              invtmp.nTotaleA # 0 OR ;
                              invtmp.nTotaleB # 0 OR ;
                              invtmp.nPlugExp # 0
                           m.cSection     = '2'
                           m.cownerid     = invtmp.cownerid
                           m.ctax         = 0
                           m.cCategory    = 'Prior A/R Balance'
                           m.cDescription = ''
                           m.ninvamt = invtmp.nexpense + ;
                              invtmp.ntotale1 + ;
                              invtmp.ntotale2 + ;
                              invtmp.ntotale3 + ;
                              invtmp.ntotale4 + ;
                              invtmp.ntotale5 + ;
                              invtmp.nTotaleA + ;
                              invtmp.nTotaleB + ;
                              invtmp.nPlugExp
                           m.nOwnerAmt       = m.ninvamt
                           m.nPartnerShipAmt = 0
                           m.nPartnerShipPct = 0
                           m.dExpDate        = invtmp.hdate
                           THIS.nwelltot     = THIS.nwelltot - m.ninvamt
                           m.nRevInt         = 100
                           m.nworkint        = 100
                           m.cTYPE           = 'EXP'
                           m.cdirect         = 'N'
                           m.cTypeInv        = invtmp.cTypeInv
                           m.cProdDate       = THIS.GetProdDate(invtmp.hyear, invtmp.hperiod)
                           m.cyear           = invtmp.hyear
                           m.cperiod         = invtmp.hperiod
                           m.crunyear        = THIS.crunyear

                           SELECT settlement
                           LOCATE FOR cwellid = invtmp.cwellid ;
                              AND cownerid = invtmp.cownerid ;
                              AND cSection = '2' ;
                              AND nPartnerShipPct # 0
                           IF FOUND()
                              m.nPartnerShipPct = nPartnerShipPct
                              m.nOwnerPct       = nOwnerPct
                           ENDIF

                           SELECT taxcodes
                           LOCATE FOR ctaxcode = 'OE'
                           IF FOUND()
                              m.cTaxSection = cDesc
                           ELSE
                              m.cTaxSection = 'Lease Operating Expenses'
                           ENDIF
                           INSERT INTO settlement FROM MEMVAR
                        ENDIF
                     ENDIF
                  ENDIF

                  STORE 0 TO m.nWellNet, m.nTotNet
                  SELECT invtmp
                  THIS.nbackupwith = THIS.nbackupwith + THIS.oinvtmp.nbackwith
                  THIS.ntaxwith    = THIS.ntaxwith  + THIS.oinvtmp.ntaxwith
                  THIS.ownergroup  = THIS.cownerid + THIS.cwellid + THIS.oinvtmp.cTypeInv
                  THIS.cprogcode   = invtmp.cprogcode

               ENDSCAN  && invtmp

               IF THIS.lcanceled
                  llReturn = .F.
                  EXIT
               ENDIF

            ENDSCAN  && Owntypes

            IF THIS.lcanceled
               llReturn = .F.
               EXIT
            ENDIF


            m.cDescript = ' '
            STORE 0 TO THIS.nwelltot, m.nWellNet, m.nTotNet
            STORE 0 TO THIS.nwelltot, m.nWellNet, m.nTotNet


            *************************************************************
            *  Process Backup and Tax Withholding
            *************************************************************
            THIS.BackTaxWith()

            *************************************************************
            *  Process Total Distribution this Run.
            *************************************************************
            IF NOT THIS.lbelowminimum
               SELECT invtotal
               m.crptgroup   = 'K'
               m.cSuspType   = ''
               m.cTYPE       = 'TOT'
               m.cperiod     = ''
               m.cyear       = THIS.cyear
               m.cprogcode   = '{'
               m.cWellType   = '}ZZZZZZZZZZ'
               m.cownerid    = THIS.cownerid
               m.nTotNet     = m.nTotalBal
               THIS.nbalance = m.nTotalBal

               IF m.lSuspense
                  m.cSuspType = 'Z'
               ELSE
                  m.cSuspType    = ''
               ENDIF
               lldef = .F.

               m.cDescript = 'Total Well Activity This Run'

               *   m.cOwnerID = THIS.cOwnerID
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
            ENDIF

            lcWellType = m.cWellType


            WAIT CLEAR

            *************************************************************
            *  Process suspense amount released this run
            *************************************************************
            IF THIS.lNoSuspDet
               *            THIS.susprelbal()
            ENDIF

            THIS.lbelowminimum = .F.
         ENDSCAN  && invtotal

         IF THIS.lcanceled
            llReturn = .F.
            EXIT
         ENDIF

         THIS.oProgress.CloseProgress()

         THIS.odist = .NULL.
         WAIT CLEAR

         IF USED('flatrates')
            USE IN flatrates
         ENDIF

         ON KEY LABEL esc

         IF lnCount = 0
            llReturn = .F.
         ELSE
            llReturn = .T.
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'Main', loError.LINENO, 'SWOwner', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      THIS.CheckCancel()

      RETURN llReturn
   ENDPROC

   *-- Calculates summary totals to show at the bottom of the statement
   ***********************************************************************
   PROCEDURE CalcSummary
      ***********************************************************************

      CREATE CURSOR summary_tots ;
         (cownerid  C(10), ;
           nOilSummary N(12, 2), ;
           nGasSummary N(12, 2), ;
           nOthSummary N(12, 2), ;
           nDedSummary N(12, 2), ;
           nTaxSummary N(12, 2), ;
           nExpSummary N(12, 2), ;
           nNetSummary N(12, 2))

      SELECT  cownerid ;
          FROM statemnt ;
          WHERE 'check' $ LOWER(cbalancedesc) ;
              OR 'posted' $ LOWER(cbalancedesc) ;
              AND crptgroup = 'A' ;
          INTO CURSOR checkowners ;
          ORDER BY cownerid ;
          GROUP BY cownerid

      SELECT  cownerid ;
          FROM statemnt ;
          WHERE NOT 'check' $ LOWER(cbalancedesc) ;
              AND NOT 'posted' $ LOWER(cbalancedesc) ;
              AND crptgroup = 'A' ;
          INTO CURSOR suspowners ;
          ORDER BY cownerid ;
          GROUP BY cownerid

      lcRunYear = THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      SELECT  cownerid, ;
              SUM(noilrev) AS nOilSummary, ;
              SUM(ngasrev) AS nGasSummary, ;
              SUM(nothrev + nmiscrev1 + nmiscrev2 + ntrprev) AS nOthSummary, ;
              SUM(nmktgexp + ncompress + ngather) AS nDedSummary, ;
              SUM(nsevtaxes) AS nTaxSummary, ;
              SUM(nexpense + ntotale1 + ntotale2 + ;
                  ntotale3 + ntotale4 + ntotale5 + ;
                  nTotaleA + nTotaleB + nPlugExp) AS nExpSummary, ;
              SUM(nnetcheck) AS nNetSummary ;
          FROM invtmp ;
          INTO CURSOR tempsummary1 ;
          WHERE cownerid IN (SELECT  cownerid ;
                                 FROM checkowners) ;
              AND (cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') # lcRunYear) ;
          ORDER BY cownerid ;
          GROUP BY cownerid

      SELECT  cownerid, ;
              SUM(noilrev) AS nOilSummary, ;
              SUM(ngasrev) AS nGasSummary, ;
              SUM(nothrev + nmiscrev1 + nmiscrev2 + ntrprev) AS nOthSummary, ;
              SUM(nmktgexp + ncompress + ngather) AS nDedSummary, ;
              SUM(nsevtaxes) AS nTaxSummary, ;
              SUM(nexpense + ntotale1 + ntotale2 + ;
                  ntotale3 + ntotale4 + ntotale5 + ;
                  nTotaleA + nTotaleB + nPlugExp) AS nExpSummary, ;
              SUM(nnetcheck) AS nNetSummary ;
          FROM invtmp ;
          INTO CURSOR tempsummary2 ;
          WHERE cownerid IN (SELECT  cownerid ;
                                 FROM suspowners) ;
              AND (cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') # lcRunYear) ;
          ORDER BY cownerid ;
          GROUP BY cownerid

      SELECT summary_tots
      APPEND FROM DBF('tempsummary1')
      APPEND FROM DBF('tempsummary2')

      SELECT summary_tots
      SCAN
         SCATTER MEMVAR
         UPDATE  statemnt SET nOilSummary = m.nOilSummary, ;
                 nGasSummary = m.nGasSummary, ;
                 nOthSummary = m.nOthSummary, ;
                 nDedSummary = m.nDedSummary, ;
                 nTaxSummary = m.nTaxSummary, ;
                 nExpSummary = m.nExpSummary, ;
                 nNetSummary = m.nNetSummary ;
             WHERE cownerid == m.cownerid

      ENDSCAN


      *-- Calculates compression/gathering charges (Calculated)
      ***********************************************************************
   PROCEDURE CalcCompress
      ***********************************************************************
      LOCAL m.nTOTAL, m.nprice

      swSelect('wells')
      LOCATE FOR cwellid = THIS.cwellid
      IF FOUND()
         THIS.ooptions.lroycomp = lexclroycomp
         llCalcComp             = lcompress
         llCalcGath             = lgather
      ELSE
         llCalcComp = .F.
         llCalcGath = .F.
      ENDIF

      * Gets the totals of entered gathering and compression as expenses
      THIS.CalcGathering()
      THIS.calcCompression()

      IF NOT llCalcComp AND NOT llCalcGath
         RETURN
      ENDIF

      SELECT wellwork
      LOCATE FOR cwellid == THIS.cwellid  AND crectype = 'R' ;
         AND hyear   == THIS.oinvtmp.hyear ;
         AND hperiod == THIS.oinvtmp.hperiod ;
         AND nRunNo  == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.nRunNo_In, THIS.oinvtmp.nRunNo) ;
         AND crunyear == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.cRunYear_In, THIS.oinvtmp.crunyear)
      IF NOT FOUND()
         RETURN .T.
      ENDIF
      SCATTER NAME THIS.owellwork

      make_copy('income', 'gathrev')
      make_copy('income', 'comprev')

      llFoundGATH = .F.

      * Get the total compression/gathering entered in revenue
      swSelect('income')
      SCAN FOR csource = 'GATH' ;
            AND income.cwellid = THIS.cwellid ;
            AND IIF(THIS.lNewRun, nRunNo = 0 AND dRevDate <= THIS.dRevDate, nRunNo = THIS.nRunNo AND crunyear = THIS.crunyear)
         SCATTER MEMVAR

         m.loneman = .F.
         SELE gathrev
         LOCATE FOR cwellid = m.cwellid AND cyear + cperiod = m.cyear + m.cperiod AND ;
            csource == m.csource AND cownerid = m.cownerid AND cperiod = m.cperiod AND cyear = m.cyear
         IF FOUND()
            REPL ntotalinc WITH ntotalinc + m.ntotalinc
         ELSE
            INSERT INTO gathrev FROM MEMVAR
         ENDIF
      ENDSCAN

      swSelect('income')
      SCAN FOR csource = 'COMP' ;
            AND income.cwellid = THIS.cwellid ;
            AND IIF(THIS.lNewRun, nRunNo = 0 AND dRevDate <= THIS.dRevDate, nRunNo = THIS.nRunNo AND crunyear = THIS.crunyear)
         SCATTER MEMVAR

         m.loneman = .F.
         SELE comprev
         LOCATE FOR cwellid = m.cwellid AND cyear + cperiod = m.cyear + m.cperiod AND ;
            csource == m.csource AND cownerid = m.cownerid AND cperiod = m.cperiod AND cyear = m.cyear
         IF FOUND()
            REPL ntotalinc WITH ntotalinc + m.ntotalinc
         ELSE
            INSERT INTO comprev FROM MEMVAR
         ENDIF
      ENDSCAN

      IF THIS.owellwork.ngather # 0 AND NOT THIS.ooptions.lHideComp
         IF THIS.lroyaltyowner AND THIS.ooptions.lChgPrice AND NOT llFoundGATH
            * Do Nothing
         ELSE
            IF THIS.lroyaltyowner AND THIS.ooptions.lroycomp AND NOT llFoundGATH
               * Do Nothing
            ELSE

               m.crptgroup = 'B'
               m.cTYPE     = 'MCF'
               m.cperiod   = ''
               m.cyear     = THIS.owellwork.hyear

               * Fill in the description for the gathering, based on the name in the revenue categories file
               swSelect('revcat')
               SET ORDER TO crevtype
               IF SEEK('GATH')
                  m.csource = revcat.cRevDesc
               ELSE
                  m.csource   = 'Gathering Charge'
               ENDIF

               m.nprice = THIS.ngather
               m.nTOTAL = THIS.owellwork.ngather * -1
               IF USED('gathtemp')  && Subtract gathering entered as an expense
                  SELECT gathtemp
                  SCAN FOR cwellid = THIS.owellwork.cwellid
                     m.nTOTAL = m.nTOTAL + gathtemp.nAmount
                  ENDSCAN
               ENDIF
               IF USED('gathrev') && Subtract out gathering entered as revenue
                  SELECT gathrev
                  SCAN FOR cwellid = THIS.owellwork.cwellid
                     m.nTOTAL = m.nTOTAL - gathrev.ntotalinc
                  ENDSCAN
               ENDIF

               *** Need to subtract any one-man items out of the units   ps - 1/14/19
               m.nunits    = THIS.owellwork.ntotmcf
               llFoundGATH = .F.
               IF NOT THIS.lroyaltyowner AND THIS.ooptions.lroycomp
                  lnInterest = 'm.nworkint'
               ELSE
                  lnInterest   = 'THIS.oinvtmp.nrevgas'
               ENDIF

               m.nRevInt = &lnInterest
               *               m.nRevInt   = ROUND(this.oInvtmp.nGather/this.owellwork.ngather,4) * 100
               m.ninvamt   = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
               *                m.ninvamt   = THIS.oinvtmp.ngather * -1
               m.cDescript = ' '
               m.cownerid  = THIS.oinvtmp.cownerid
               m.nRunNo    = THIS.nRunNo
               m.crunyear  = THIS.crunyear
               m.cperiod   = THIS.owellwork.hperiod
               m.cprogcode = THIS.oinvtmp.cprogcode

            ENDIF
         ENDIF
      ENDIF

      llFoundCOMP = .F.

      STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
      STORE ' ' TO m.csource, m.cTYPE, m.cDescript
      IF THIS.owellwork.ncompress # 0 AND NOT THIS.ooptions.lHideComp
         IF THIS.lroyaltyowner AND THIS.ooptions.lChgPrice AND NOT llFoundCOMP
            * Do Nothing
         ELSE
            IF THIS.lroyaltyowner AND THIS.ooptions.lroycomp AND NOT llFoundCOMP
               * Do Nothing
            ELSE
               m.crptgroup = 'B'
               m.cTYPE     = 'MCF'
               m.cperiod   = ''
               m.cyear     = THIS.owellwork.hyear

               * Fill in the description for the compression, based on the name in the revenue categories file
               swSelect('revcat')
               SET ORDER TO crevtype
               IF SEEK('COMP')
                  m.csource = revcat.cRevDesc
               ELSE
                  m.csource   = 'Compression Charge'
               ENDIF

               m.nprice = THIS.ncompress
               m.nTOTAL = THIS.owellwork.ncompress * -1
               IF USED('comptemp')
                  SELECT comptemp
                  SCAN FOR cwellid = THIS.owellwork.cwellid
                     m.nTOTAL = m.nTOTAL + comptemp.nAmount
                  ENDSCAN
               ENDIF
               IF USED('comprev')
                  SCAN FOR cwellid = THIS.owellwork.cwellid
                     m.nTOTAL = m.nTOTAL - comprev.ntotalinc
                  ENDSCAN
               ENDIF
               m.nunits    = THIS.owellwork.ntotmcf
               llFoundCOMP = .F.

               IF NOT THIS.lroyaltyowner AND THIS.ooptions.lroycomp
                  lnInterest = 'm.nworkint'
               ELSE
                  lnInterest   = 'THIS.oinvtmp.nrevgas'
               ENDIF

               m.nRevInt         = &lnInterest
               m.cperiod         = THIS.owellwork.hperiod
               m.nOwnerAmt       = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
               m.nPartnerShipAmt = m.nTOTAL
               m.cDescript       = ' '
               m.cownerid        = THIS.oinvtmp.cownerid
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               IF m.ninvamt # 0
                  INSERT INTO settlement FROM MEMVAR
               ENDIF
               THIS.nwelltot = THIS.nwelltot + m.ninvamt
            ENDIF
         ENDIF
      ENDIF

      STORE 0 TO m.nTOTAL, m.ninvamt, m.nRevInt
      STORE ' ' TO m.csource, m.cTYPE, m.cDescript

      swclose('comprev')
      swclose('gathrev')
   ENDPROC

   *-- Calculates marketing charges
   ***********************************************************************
   PROCEDURE CalcMktg
      ***********************************************************************
      LOCAL llSuspense
      * Don't run this method if there's no marketing to report
      IF THIS.oinvtmp.nmktgexp = 0
         RETURN
      ENDIF

      *
      *  Prepare MKTG expense table
      *
      CREATE CURSOR mktgtemp ;
         (cwellid    C(10), ;
           ccatcode   C(4), ;
           ccateg     C(60), ;
           cyear      C(4), ;
           cperiod    C(2), ;
           crefid     C(20), ;
           dExpDate   D, ;
           nAmount    N(12, 2), ;
           cpayee     C(40), ;
           cmemo      C(60), ;
           cvendorid  C(10), ;
           cpaidbyck  C(8), ;
           cExpClass  C(1), ;
           nsaltwater I, ;
           cprdpaid   C(6), ;
           lfixed     L, ;
           laptran    L, ;
           cbatch     C(8), ;
           cownerid   C(10), ;
           loneman    L, ;
           cdescrip   C(30), ;
           lused      L)

      * This entry came from prior suspense
      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + ;
         PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      * Get the MKTG charges
      swSelect('expense')
      SCAN FOR cwellid == THIS.cwellid AND ;
            cyear # 'FIXD' AND ccatcode = 'MKTG' AND cyear == THIS.oinvtmp.hyear AND cperiod == THIS.oinvtmp.hperiod AND ;
            ICASE(NOT llSuspense AND NOT EMPTY(THIS.oinvtmp.cSuspType) AND NOT THIS.lNewRun, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              llSuspense, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              THIS.lNewRun, ;
              nrunnorev = 0 AND dExpDate <= THIS.dExpDate, ;
              nrunnorev = THIS.nRunNo AND crunyearrev = THIS.crunyear)

         SCATTER MEMVAR
         swSelect('expcat')
         SET ORDER TO ccatcode
         IF SEEK(m.ccatcode)
            m.cdescrip  = cdescrip
         ELSE
            LOOP
         ENDIF
         m.loneman = .F.
         SELE mktgtemp
         LOCATE FOR cwellid = m.cwellid AND ;
            ccatcode == m.ccatcode AND cownerid = m.cownerid AND cExpClass = m.cExpClass AND cyear + cperiod = m.cyear + m.cperiod
         IF FOUND()
            REPL nAmount WITH nAmount + m.nAmount
         ELSE
            INSERT INTO mktgtemp FROM MEMVAR
         ENDIF
      ENDSCAN

      swSelect('expcat')
      LOCATE FOR ccatcode = 'MKTG'
      IF FOUND()
         IF THIS.ooptions.lacctdesc = .T. AND NOT EMPTY(cdescrip)
            m.csource = cdescrip
         ELSE
            m.csource = ccateg
         ENDIF
      ELSE
         m.csource   = 'Marketing Charge'
      ENDIF
      SELE mktgtemp
      SCAN FOR cwellid == THIS.owellwork.cwellid
         m.cExpClass = cExpClass
         m.crptgroup = 'B'
         m.cTYPE     = 'OTH'
         m.cperiod   = ''
         m.cyear     = THIS.owellwork.hyear
         m.nprice    = 0
         m.nTOTAL    = mktgtemp.nAmount * -1
         m.nunits    = 0
         m.cwellid   = THIS.owellwork.cwellid

         DO CASE
            CASE m.cExpClass = '0'
               m.nRevInt = THIS.oinvtmp.nrevgas
            CASE m.cExpClass = '1'
               m.nRevInt = THIS.oinvtmp.nintclass1
            CASE m.cExpClass = '2'
               m.nRevInt = THIS.oinvtmp.nintclass2
            CASE m.cExpClass = '3'
               m.nRevInt = THIS.oinvtmp.nintclass3
            CASE m.cExpClass = '4'
               m.nRevInt = THIS.oinvtmp.nintclass4
            CASE m.cExpClass = '5'
               m.nRevInt = THIS.oinvtmp.nintclass5
            CASE m.cExpClass = 'A'
               m.nRevInt = THIS.oinvtmp.nacpint
            CASE m.cExpClass = 'B'
               m.nRevInt = THIS.oinvtmp.nbcpint
            OTHERWISE
               m.nRevInt = THIS.oinvtmp.nrevgas
         ENDCASE
         m.crptgroup       = 'B'
         m.cTYPE           = 'OTH'
         m.cperiod         = ''
         m.cyear           = THIS.owellwork.hyear
         m.nprice          = 0
         m.nunits          = 0
         m.cperiod         = THIS.owellwork.hperiod
         m.nOwnerAmt       = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
         m.nPartnerShipAmt = m.nTOTAL
         m.cDescript       = ' '
         m.cownerid        = THIS.oinvtmp.cownerid
         m.nRunNo          = THIS.nRunNo
         m.crunyear        = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group B
         *********************************************************************************************************
         IF m.nOwnerAmt # 0
            INSERT INTO settlement FROM MEMVAR
            THIS.nwelltot = THIS.nwelltot + m.ninvamt
         ENDIF
      ENDSCAN
   ENDPROC

   *-- Calculates gathering charges
   ***********************************************************************
   PROCEDURE CalcGathering
      ***********************************************************************
      LOCAL llSuspense

      *
      *  Prepare MKTG expense table
      *
      CREATE CURSOR gathtemp ;
         (cwellid    C(10), ;
           ccatcode   C(4), ;
           ccateg     C(60), ;
           cyear      C(4), ;
           cperiod    C(2), ;
           crefid     C(20), ;
           dExpDate   D, ;
           nAmount    N(12, 2), ;
           cpayee     C(40), ;
           cmemo      C(60), ;
           cvendorid  C(10), ;
           cpaidbyck  C(8), ;
           cExpClass  C(1), ;
           nsaltwater I, ;
           cprdpaid   C(6), ;
           lfixed     L, ;
           laptran    L, ;
           cbatch     C(8), ;
           cownerid   C(10), ;
           loneman    L, ;
           cdescrip   C(30), ;
           ngrossval  N(12, 2), ;
           ninterest  N(11, 7), ;
           lused      L)

      * This entry came from prior suspense
      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + ;
         PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      * Get the GATH charges
      swSelect('expense')
      SCAN FOR cwellid == THIS.cwellid AND ;
            cyear # 'FIXD' AND ccatcode = 'GATH' AND cyear == THIS.oinvtmp.hyear AND cperiod == THIS.oinvtmp.hperiod AND ;
            ICASE(NOT llSuspense AND NOT EMPTY(THIS.oinvtmp.cSuspType) AND NOT THIS.lNewRun, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              llSuspense, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              THIS.lNewRun, ;
              nrunnorev = 0 AND dExpDate <= THIS.dExpDate, ;
              nrunnorev = THIS.nRunNo AND crunyearrev = THIS.crunyear)

         SCATTER MEMVAR
         swSelect('expcat')
         SET ORDER TO ccatcode
         IF SEEK(m.ccatcode)
            m.cdescrip  = cdescrip
         ELSE
            LOOP
         ENDIF
         m.loneman = .F.
         SELE gathtemp
         LOCATE FOR cwellid = m.cwellid     AND ;
            ccatcode == m.ccatcode  AND ;
            cownerid = m.cownerid   AND ;
            cExpClass = m.cExpClass AND ;
            cyear + cperiod = m.cyear + m.cperiod
         IF FOUND()
            REPL nAmount WITH nAmount + m.nAmount, ;
               ngrossval WITH ngrossval + m.ngrossval
         ELSE
            INSERT INTO gathtemp FROM MEMVAR
         ENDIF
      ENDSCAN

      swSelect('expcat')
      LOCATE FOR ccatcode = 'GATH'
      IF FOUND()
         IF THIS.ooptions.lacctdesc = .T. AND NOT EMPTY(cdescrip)
            m.csource = cdescrip
         ELSE
            m.csource = ccateg
         ENDIF
      ELSE
         m.csource   = 'Gathering Charge'
      ENDIF

      SELE gathtemp
      SCAN FOR cwellid == THIS.owellwork.cwellid
         m.cExpClass = cExpClass
         m.crptgroup = 'B'
         m.cTYPE     = 'OTH'
         m.cperiod   = ''
         m.cyear     = THIS.owellwork.hyear
         m.nprice    = 0
         m.nTOTAL    = gathtemp.nAmount * -1
         m.nunits    = 0
         m.cwellid   = THIS.owellwork.cwellid

         IF NOT EMPTY(gathtemp.cownerid) AND gathtemp.cownerid # THIS.cownerid
            LOOP
         ENDIF

         DO CASE
            CASE NOT EMPTY(gathtemp.cownerid)
               m.nRevInt = 100
            CASE m.cExpClass = '0'
               m.nRevInt = THIS.oinvtmp.nworkint
            CASE m.cExpClass = '1'
               m.nRevInt = THIS.oinvtmp.nintclass1
            CASE m.cExpClass = '2'
               m.nRevInt = THIS.oinvtmp.nintclass2
            CASE m.cExpClass = '3'
               m.nRevInt = THIS.oinvtmp.nintclass3
            CASE m.cExpClass = '4'
               m.nRevInt = THIS.oinvtmp.nintclass4
            CASE m.cExpClass = '5'
               m.nRevInt = THIS.oinvtmp.nintclass5
            CASE m.cExpClass = 'A'
               m.nRevInt = THIS.oinvtmp.nacpint
            CASE m.cExpClass = 'B'
               m.nRevInt = THIS.oinvtmp.nbcpint
            OTHERWISE
               m.nRevInt = THIS.oinvtmp.nrevgas
         ENDCASE
         m.cSection        = '1'
         m.cProdType       = 'GATH'
         m.cperiod         = THIS.owellwork.hperiod
         m.cyear           = THIS.owellwork.hyear
         m.nprice          = 0
         m.nunits          = 0
         m.cperiod         = THIS.owellwork.hperiod
         m.cProdDate       = THIS.GetProdDate(m.cyear, m.cperiod)
         m.nOwnerAmt       = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
         m.nGrossAmt       = m.ngrossval
         m.nPartnerShipAmt = m.nTOTAL
         m.cDescript       = ' '
         m.nOwnerPct       = m.nRevInt
         m.cownerid        = THIS.oinvtmp.cownerid
         m.nRunNo          = THIS.nRunNo
         m.crunyear        = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the settlement file  - Report Group B
         *********************************************************************************************************
         IF m.nOwnerAmt # 0
            INSERT INTO settlement FROM MEMVAR
            THIS.nwelltot = THIS.nwelltot + m.nOwnerAmt
         ENDIF
      ENDSCAN
   ENDPROC

   *-- Calculates gathering charges
   ***********************************************************************
   PROCEDURE calcCompression
      ***********************************************************************
      LOCAL llSuspense

      *
      *  Prepare COMPTEMP expense table
      *
      CREATE CURSOR comptemp ;
         (cwellid    C(10), ;
           ccatcode   C(4), ;
           ccateg     C(60), ;
           cyear      C(4), ;
           cperiod    C(2), ;
           crefid     C(20), ;
           dExpDate   D, ;
           nAmount    N(12, 2), ;
           ngrossval  N(12, 2), ;
           ninterest  N(11, 7), ;
           cpayee     C(40), ;
           cmemo      C(60), ;
           cvendorid  C(10), ;
           cpaidbyck  C(8), ;
           cExpClass  C(1), ;
           nsaltwater I, ;
           cprdpaid   C(6), ;
           lfixed     L, ;
           laptran    L, ;
           cbatch     C(8), ;
           cownerid   C(10), ;
           loneman    L, ;
           cdescrip   C(30), ;
           lused      L)

      * This entry came from prior suspense
      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + ;
         PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      * Get the COMP charges
      swSelect('expense')
      SCAN FOR cwellid == THIS.cwellid AND ;
            cyear # 'FIXD' AND ccatcode = 'COMP' AND cyear == THIS.oinvtmp.hyear AND cperiod == THIS.oinvtmp.hperiod AND ;
            ICASE(NOT llSuspense AND NOT EMPTY(THIS.oinvtmp.cSuspType) AND NOT THIS.lNewRun, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              llSuspense, ;
              nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In, ;
              THIS.lNewRun, ;
              nrunnorev = 0 AND dExpDate <= THIS.dExpDate, ;
              nrunnorev = THIS.nRunNo AND crunyearrev = THIS.crunyear)

         SCATTER MEMVAR
         swSelect('expcat')
         SET ORDER TO ccatcode
         IF SEEK('COMP')
            m.cdescrip  = cdescrip
         ELSE
            LOOP
         ENDIF
         m.loneman = .F.
         SELE comptemp
         LOCATE FOR cwellid = m.cwellid AND ;
            ccatcode == m.ccatcode AND cownerid = m.cownerid AND cExpClass = m.cExpClass AND cyear + cperiod = m.cyear + m.cperiod
         IF FOUND()
            REPL nAmount WITH nAmount + m.nAmount, ;
               ngrossval WITH ngrossval + m.ngrossval
         ELSE
            INSERT INTO comptemp FROM MEMVAR
         ENDIF
      ENDSCAN

      swSelect('expcat')
      LOCATE FOR ccatcode = 'COMP'
      IF FOUND()
         IF THIS.ooptions.lacctdesc = .T. AND NOT EMPTY(cdescrip)
            m.csource = cdescrip
         ELSE
            m.csource = ccateg
         ENDIF
      ELSE
         m.csource   = 'Compression Charge'
      ENDIF

      SELE comptemp
      SCAN FOR cwellid == THIS.owellwork.cwellid
         m.cExpClass = cExpClass
         m.crptgroup = 'B'
         m.cTYPE     = 'OTH'
         m.cperiod   = ''
         m.cyear     = THIS.owellwork.hyear
         m.nprice    = 0
         m.nTOTAL    = comptemp.nAmount * -1
         m.nunits    = 0
         m.cwellid   = THIS.owellwork.cwellid

         DO CASE
            CASE m.cExpClass = '0'
               m.nRevInt = THIS.oinvtmp.nworkint
            CASE m.cExpClass = '1'
               m.nRevInt = THIS.oinvtmp.nintclass1
            CASE m.cExpClass = '2'
               m.nRevInt = THIS.oinvtmp.nintclass2
            CASE m.cExpClass = '3'
               m.nRevInt = THIS.oinvtmp.nintclass3
            CASE m.cExpClass = '4'
               m.nRevInt = THIS.oinvtmp.nintclass4
            CASE m.cExpClass = '5'
               m.nRevInt = THIS.oinvtmp.nintclass5
            CASE m.cExpClass = 'A'
               m.nRevInt = THIS.oinvtmp.nacpint
            CASE m.cExpClass = 'B'
               m.nRevInt = THIS.oinvtmp.nbcpint
            OTHERWISE
               m.nRevInt = THIS.oinvtmp.nrevgas
         ENDCASE
         m.cSection        = '1'
         m.cTYPE           = 'COMP'
         m.cperiod         = THIS.owellwork.hperiod
         m.cyear           = THIS.owellwork.hyear
         m.nprice          = 0
         m.nunits          = 0
         m.cperiod         = THIS.owellwork.hperiod
         m.cProdDate       = THIS.GetProdDate(m.cyear, m.cperiod)
         m.nOwnerAmt       = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
         m.nOwnerPct       = m.nRevInt
         m.nPartnerShipAmt = m.nTOTAL
         m.nGrossAmt       = m.ngrossval
         m.cDescript       = ' '
         m.cownerid        = THIS.oinvtmp.cownerid
         m.nRunNo          = THIS.nRunNo
         m.crunyear        = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the settlement file  - Section 1
         *********************************************************************************************************
         IF m.nownerval # 0
            INSERT INTO settlement FROM MEMVAR
            THIS.nwelltot = THIS.nwelltot + m.nownerval
         ENDIF
      ENDSCAN
   ENDPROC

   *-- Calculates income section
   ***********************************************************************
   PROCEDURE calcincome
      ***********************************************************************
      LPARA m.cwellid, tnRunNo, tcRunYear, tcYear, tcPeriod, tdAcctDate
      LOCAL llUseDefaultPurch

      IF FILE('datafiles\purchdef.txt')
         llUseDefaultPurch = .T.
      ELSE
         llUseDefaultPurch = .F.
      ENDIF

      m.cdirect = THIS.oinvtmp.cdirect

      *  Manualtax never gets cleared out, so it was adding to entries from previous owners.
      *  Not a big deal until you have an exempt owner in the mix, and then it causes problems over a range of statements.
      SELECT manualTax
      DELETE ALL

      * Make sure expense tax code is not set for income
      STORE '' TO m.ctaxcode, m.ctaxdesc

      * If we're printing the report for a new run and the current
      * record didn't come from suspense then reset the runno parms
      IF EMPTY(THIS.oinvtmp.cSuspType) AND THIS.nRunNo = 0
         tnRunNo   = 0
         tcRunYear = '   '
      ENDIF

      * This entry came from prior suspense
      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + ;
         PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      SELE inctemp
      LOCATE FOR cwellid == m.cwellid AND ;
         IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0, nRunNo = tnRunNo AND crunyear = tcRunYear) AND ;
         cyear + cperiod = tcYear + tcPeriod
      IF NOT FOUND()

         *  Process revenue into temp cursor
         make_copy('Income', 'Inctemp')

         * If the revenue is being summarized by type and prod period create the summarized cursor
         IF THIS.lSumRev
            SELE * FROM income ;
               WHERE IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0 AND dRevDate <= tdAcctDate, nRunNo = tnRunNo AND crunyear = tcRunYear) ;
               AND cyear == tcYear AND cperiod == tcPeriod ;
               AND cwellid = m.cwellid ;
               INTO CURSOR inctmp READWRITE ;
               ORDER BY cwellid

            IF _TALLY > 0
               SELE inctmp
               SCAN
                  SCATTER MEMVAR
                  m.loneman = .F.
                  IF EMPTY(m.cownerid)
                     SELECT inctemp
                     IF NOT llUseDefaultPurch
                        LOCATE FOR cwellid == m.cwellid ;
                           AND csource == m.csource ;
                           AND cyear == m.cyear ;
                           AND cperiod == m.cperiod ;
                           AND cownerid == m.cownerid ;
                           AND crevkey == m.crevkey
                     ELSE
                        LOCATE FOR cwellid == m.cwellid ;
                           AND csource == m.csource ;
                           AND cyear == m.cyear ;
                           AND cperiod == m.cperiod ;
                           AND cownerid == m.cownerid
                     ENDIF
                     IF FOUND()
                        REPLACE nunits WITH nunits + m.nunits, ;
                           ngrossunits WITH ngrossunits + m.ngrossunits, ;
                           ngrossval   WITH ngrossval + m.ngrossval, ;
                           ntotalinc WITH ntotalinc + m.ntotalinc
                        * Calculate the price based on income/units
                        IF nunits # 0
                           REPLACE nprice WITH ROUND(ntotalinc / nunits, 4)
                        ENDIF
                     ELSE
                        INSERT INTO inctemp FROM MEMVAR
                     ENDIF
                  ELSE
                     INSERT INTO inctemp FROM MEMVAR
                  ENDIF
               ENDSCAN
               SELE inctemp
               INDEX ON cwellid TAG cwellid
               INDEX ON cyear + cperiod TAG yearprd
            ENDIF
         ELSE
            * Revenue is not being summarized. Get a cursor of valid data
            SELE * FROM income ;
               WHERE IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0 AND dRevDate <= tdAcctDate, nRunNo = tnRunNo AND crunyear = tcRunYear) ;
               AND cyear == tcYear AND cperiod == tcPeriod ;
               AND cwellid = m.cwellid ;
               INTO CURSOR inctemp READWRITE ;
               ORDER BY cwellid
            SELE inctemp
            REPLACE loneman WITH .F. ALL
            INDEX ON cwellid TAG cwellid
            INDEX ON cyear + cperiod TAG yearprd
         ENDIF
      ENDIF

      jflatcnt = 0
      STORE 0 TO THIS.ntotalbbl, THIS.ntotalmcf, jnrevoil, jnrevgas, jnworkint, ;
         THIS.noilamount, THIS.ngasamount, THIS.notheramount, THIS.ntotalother, THIS.ncompamount, THIS.ngathamount, ;
         jnrevoth, THIS.noiltax1, THIS.noiltax2, THIS.noiltax3, THIS.noiltax4, ;
         THIS.ngastax1, THIS.ngastax2, THIS.ngastax3, THIS.ngastax4, THIS.nothtax1, THIS.nothtax2, THIS.nothtax3, THIS.nothtax4
      STORE 0 TO m.noiltax1, m.ngastax1, m.nprodtax1, m.noiltax2, m.ngastax2, m.nprodtax2, ;
         M.noiltax3, m.ngastax3, m.nprodtax3, m.noiltax4, m.ngastax4, m.nprodtax4
      m.cTaxSection  = ''
      m.cDescription = ''

      swSelect('income')
      IF EMPTY(THIS.oinvtmp.cSuspType)
         LOCATE FOR cwellid = m.cwellid ;
            AND IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0 AND dRevDate <= tdAcctDate, nRunNo = tnRunNo AND crunyear = tcRunYear) ;
            AND cyear + cperiod = tcYear + tcPeriod
         IF NOT FOUND()
            RETURN .F.
         ENDIF
      ELSE
         LOCATE FOR cwellid == m.cwellid ;
            AND IIF(THIS.lNewRun AND NOT llSuspense, nRunNo = 0 AND dRevDate <= tdAcctDate, ;
              nRunNo = THIS.oinvtmp.nRunNo_In AND crunyear = THIS.oinvtmp.cRunYear_In) ;
            AND cyear + cperiod = tcYear + tcPeriod
         IF THIS.oinvtmp.lmanual OR NOT FOUND()
            RETURN .F.
         ENDIF
      ENDIF

      m.cSuspType = THIS.oinvtmp.cSuspType

      swSelect('wells')
      LOCATE FOR cwellid = THIS.cwellid
      IF FOUND()
         THIS.ooptions.lroycomp = lexclroycomp
         llCalcComp             = lcompress
         llCalcGath             = lgather
      ELSE
         llCalcComp = .F.
         llCalcGath = .F.
      ENDIF

      SELECT inctemp
      LOCATE FOR inctemp.ninterest # 0
      m.nPartnerShipPct = inctemp.ninterest

      SELECT inctemp
      SCAN
         m.cSection = '1'
         m.nAmount  = 0
         SCATTER MEMVAR

         IF NOT EMPTY(ndayson)
            m.ndayson   = ndayson
         ENDIF

         m.nPartnerShipAmt = inctemp.ntotalinc

         jnrevoil    = THIS.oinvtmp.nrevoil
         jnrevgas    = THIS.oinvtmp.nrevgas
         jnrevtax1   = THIS.oinvtmp.nrevtax1
         jnrevtax2   = THIS.oinvtmp.nrevtax2
         jnrevtax3   = THIS.oinvtmp.nrevtax3
         jnrevtax4   = THIS.oinvtmp.nrevtax4
         jnrevtax5   = THIS.oinvtmp.nrevtax5
         jnrevtax6   = THIS.oinvtmp.nrevtax6
         jnrevtax7   = THIS.oinvtmp.nrevtax7
         jnrevtax8   = THIS.oinvtmp.nrevtax8
         jnrevtax9   = THIS.oinvtmp.nrevtax9
         jnrevtax10  = THIS.oinvtmp.nrevtax10
         jnrevtax11  = THIS.oinvtmp.nrevtax11
         jnrevtax12  = THIS.oinvtmp.nrevtax12
         jnrevm1     = THIS.oinvtmp.nrevmisc1
         jnrevm2     = THIS.oinvtmp.nrevmisc2
         jnrevoth    = THIS.oinvtmp.nrevoth
         jnrevtrans  = THIS.oinvtmp.nrevtrp
         m.cprogcode = THIS.oinvtmp.cprogcode

         SELECT wells
         SET ORDER TO cwellid
         IF SEEK(THIS.oinvtmp.cwellid)
            llRoyExempt = lroysevtx
         ELSE
            llRoyExempt = .F.
         ENDIF
         IF 'TAX' $ inctemp.csource
            IF THIS.lownertaxexempt
               LOOP
            ENDIF
            IF llRoyExempt AND THIS.oinvtmp.cTypeInv # 'W'
               LOOP
            ENDIF
         ENDIF
         DO CASE
            CASE inctemp.cownerid = THIS.cownerid AND NOT inctemp.loneman

               * Check to see if the owner has multiple interests in the well
               * If so, allocate it to the working interest owner.
               IF m.cTypeInv # 'W'
                  swSelect('wellinv')
                  LOCATE FOR cownerid == THIS.cownerid AND cwellid == inctemp.cwellid AND cTypeInv = 'W'
                  IF FOUND()
                     LOOP
                  ENDIF
               ENDIF
               SELECT inctemp
               REPLACE loneman WITH .T.
               DO CASE
                  CASE inctemp.csource = 'BBL'
                     THIS.oinvtmp.nrevoil = 100
                  CASE inctemp.csource = 'EXO'
                     THIS.oinvtmp.nrevoil = 100
                  CASE inctemp.csource = 'MCF'
                     THIS.oinvtmp.nrevgas = 100
                  CASE inctemp.csource = 'OTH'
                     THIS.oinvtmp.nrevoth = 100
                  CASE inctemp.csource = 'TRANS'
                     THIS.oinvtmp.nrevtrp = 100
                  CASE inctemp.csource = 'EXG'
                     THIS.oinvtmp.nrevgas = 100
                  CASE inctemp.csource = 'OTAX1'
                     THIS.oinvtmp.nrevtax1 = 100
                  CASE inctemp.csource = 'GTAX1'
                     THIS.oinvtmp.nrevtax2 = 100
                  CASE inctemp.csource = 'PTAX1'
                     THIS.oinvtmp.nrevtax3 = 100
                  CASE inctemp.csource = 'OTAX2'
                     THIS.oinvtmp.nrevtax4 = 100
                  CASE inctemp.csource = 'GTAX2'
                     THIS.oinvtmp.nrevtax5 = 100
                  CASE inctemp.csource = 'PTAX2'
                     THIS.oinvtmp.nrevtax6 = 100
                  CASE inctemp.csource = 'OTAX3'
                     THIS.oinvtmp.nrevtax7 = 100
                  CASE inctemp.csource = 'GTAX3'
                     THIS.oinvtmp.nrevtax8 = 100
                  CASE inctemp.csource = 'PTAX3'
                     THIS.oinvtmp.nrevtax9 = 100
                  CASE inctemp.csource = 'OTAX4'
                     THIS.oinvtmp.nrevtax10 = 100
                  CASE inctemp.csource = 'GTAX4'
                     THIS.oinvtmp.nrevtax11 = 100
                  CASE inctemp.csource = 'PTAX4'
                     THIS.oinvtmp.nrevtax12 = 100
                  CASE INLIST(inctemp.csource, 'NOT', 'NTL', 'NTO', 'NTR', 'NTW')
                     THIS.oinvtmp.nRevInt = 100
                  CASE inctemp.csource = 'MISC1'
                     THIS.oinvtmp.nrevmisc1 = 100
                  CASE inctemp.csource = 'MISC2'
                     THIS.oinvtmp.nrevmisc2 = 100
                  CASE inctemp.csource = 'COMP'
                     THIS.oinvtmp.nrevmisc2 = 100
                  CASE inctemp.csource = 'GATH'
                     THIS.oinvtmp.nrevmisc2 = 100
               ENDCASE
            CASE EMPTY(inctemp.cownerid) OR cownerid = SPACE(10)

            CASE inctemp.cownerid = THIS.cownerid AND inctemp.loneman
               LOOP
         ENDCASE

         m.cProdType       = inctemp.csource

         IF m.goApp.lParentCompany
            DO CASE
               CASE inctemp.csource = 'MCF'
                  lcType = 'G'
               CASE inctemp.csource = 'BBL'
                  lcType = 'O'
               CASE 'OTAX' $ inctemp.csource
                  lcType = 'O1'
               CASE 'GTAX' $ inctemp.csource
                  lcType = 'G1'
               CASE 'PTAX' $ inctemp.csource
                  lcType = 'P1'
               CASE inctemp.csource = 'MISC1'
                  lcType = '1'
               CASE inctemp.csource = 'MISC2'
                  lcType = '2'
               OTHERWISE
                  lcType = 'G'
            ENDCASE
            m.nGrossVol       = inctemp.nunits
            m.nGrossAmt       = inctemp.ntotalinc
            m.nPartnerShipPct = THIS.NonDummyPct(inctemp.cwellid, 'R')
            m.nPartnerShipAmt = swNetRevenue(inctemp.cwellid, inctemp.ntotalinc, lcType, .F., .T., .F., inctemp.cownerid, , , m.cDeck)
            m.nPartnerShipVol = swNetRevenue(inctemp.cwellid, inctemp.nunits, lcType, .F., .T., .F., inctemp.cownerid, , , m.cDeck)
         ELSE
            m.nGrossVol       = inctemp.ngrossunits
            m.nGrossAmt       = inctemp.ngrossval
            m.nPartnerShipAmt = inctemp.ntotalinc
            m.nPartnerShipVol = inctemp.nunits
         ENDIF



         m.nprice    = inctemp.nprice
         m.cProdDate = THIS.GetProdDate(inctemp.cyear, inctemp.cperiod)

         DO CASE
            CASE inctemp.csource = 'BBL'
               m.cProdType = 'BBL'
               m.nRevInt   = THIS.oinvtmp.nrevoil
            CASE inctemp.csource = 'MCF'
               m.nRevInt       = THIS.oinvtmp.nrevgas
               THIS.ntotalmcf  = THIS.ntotalmcf + nunits
               THIS.ngasamount = THIS.ngasamount + m.ntotalinc
            CASE inctemp.csource = 'OTH'
               m.nRevInt         = THIS.oinvtmp.nrevoth
               THIS.ntotalother  = THIS.ntotalother + nunits
               THIS.notheramount = THIS.notheramount + m.ntotalinc
            CASE inctemp.csource = 'COMP'
               THIS.ncompamount = THIS.ncompamount + m.ntotalinc
            CASE inctemp.csource = 'GATH'
               THIS.ngathamount = THIS.ngathamount + m.ntotalinc
            CASE inctemp.csource = 'TRANS'
               m.nRevInt = THIS.oinvtmp.nrevtrp
            CASE inctemp.csource = 'NOT'
               m.nRevInt = 1
            CASE inctemp.csource = 'MISC1'
               m.nRevInt = THIS.oinvtmp.nrevmisc1
            CASE inctemp.csource = 'MISC2'
               m.nRevInt = THIS.oinvtmp.nrevmisc2
            CASE inctemp.csource = 'OTAX1'
               m.nRevInt  = THIS.oinvtmp.nrevtax1
               m.noiltax1 = m.noiltax1 + m.ntotalinc
            CASE inctemp.csource = 'GTAX1'
               m.nRevInt  = THIS.oinvtmp.nrevtax2
               m.ngastax1 = m.ngastax1 + m.ntotalinc
            CASE inctemp.csource = 'PTAX1'
               m.nRevInt   = THIS.oinvtmp.nrevtax3
               m.nprodtax1 = m.nprodtax1 + m.ntotalinc
            CASE inctemp.csource = 'OTAX2'
               m.nRevInt  = THIS.oinvtmp.nrevtax4
               m.noiltax2 = m.noiltax2 + m.ntotalinc
            CASE inctemp.csource = 'GTAX2'
               m.nRevInt  = THIS.oinvtmp.nrevtax5
               m.ngastax2 = m.ngastax2 + m.ntotalinc
            CASE inctemp.csource = 'PTAX2'
               m.nRevInt   = THIS.oinvtmp.nrevtax6
               m.nprodtax2 = m.nprodtax2 + m.ntotalinc
            CASE inctemp.csource = 'OTAX3'
               m.nRevInt  = THIS.oinvtmp.nrevtax7
               m.noiltax3 = m.noiltax3 + m.ntotalinc
            CASE inctemp.csource = 'GTAX3'
               m.nRevInt  = THIS.oinvtmp.nrevtax8
               m.ngastax3 = m.ngastax3 + m.ntotalinc
            CASE inctemp.csource = 'PTAX3'
               m.nRevInt   = THIS.oinvtmp.nrevtax9
               m.nprodtax3 = m.nprodtax3 + m.ntotalinc
            CASE inctemp.csource = 'OTAX4'
               m.nRevInt  = THIS.oinvtmp.nrevtax10
               m.noiltax4 = m.noiltax4 + m.ntotalinc
            CASE inctemp.csource = 'GTAX4'
               m.nRevInt  = THIS.oinvtmp.nrevtax11
               m.ngastax4 = m.ngastax4 + m.ntotalinc
            CASE inctemp.csource = 'PTAX4'
               m.nRevInt   = THIS.oinvtmp.nrevtax12
               m.nprodtax4 = m.nprodtax4 + m.ntotalinc
         ENDCASE

         IF NOT EMPTY(inctemp.cownerid) AND inctemp.cownerid # THIS.cownerid
            LOOP
         ENDIF

         IF THIS.oinvtmp.ctypeint = 'O' AND INLIST(inctemp.csource, 'MCF', 'GTAX1', 'GTAX2', 'GTAX3', 'GTAX4', 'EXG')
            m.nRevInt            = 0
            THIS.oinvtmp.nrevgas = 0
         ENDIF
         IF THIS.oinvtmp.ctypeint = 'G' AND INLIST(inctemp.csource, 'BBL', 'OTAX1', 'OTAX2', 'OTAX3', 'OTAX4', 'EXO')
            m.nRevInt            = 0
            THIS.oinvtmp.nrevoil = 0
         ENDIF

         IF inctemp.csource = 'MCF'
            * Get the gathering and compression flags
            IF THIS.oinvtmp.ncompress # 0
               m.lcompress = .T.
            ELSE
               m.lcompress = .F.
            ENDIF
            IF THIS.oinvtmp.ngather # 0
               m.lgather = .T.
            ELSE
               m.lgather = .F.
            ENDIF

            * Calculate the compression and gathering per MCF for Suspense Entries
            IF m.lcompress AND THIS.oinvtmp.cSuspType # ' '
               IF inctemp.nunits # 0
                  SELECT wellwork
                  LOCATE FOR cwellid == THIS.cwellid AND crectype = 'R' ;
                     AND hyear   == THIS.oinvtmp.hyear ;
                     AND hperiod == THIS.oinvtmp.hperiod ;
                     AND nRunNo  == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.nRunNo_In, THIS.oinvtmp.nRunNo) ;
                     AND crunyear == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.cRunYear_In, THIS.oinvtmp.crunyear)
                  IF FOUND()
                     lnCompGross    = wellwork.ncompress
                     IF THIS.ncompress = 0
                        THIS.ncompress = lnCompGross / inctemp.nunits
                     ENDIF
                  ELSE
                     THIS.ncompress = 0
                  ENDIF
               ELSE
                  THIS.ncompress = 0
               ENDIF
            ENDIF

            IF m.lgather AND THIS.oinvtmp.cSuspType # ' '
               IF inctemp.nunits # 0
                  SELECT wellwork
                  LOCATE FOR cwellid == THIS.cwellid AND crectype = 'R' ;
                     AND hyear   == THIS.oinvtmp.hyear ;
                     AND hperiod == THIS.oinvtmp.hperiod ;
                     AND nRunNo  == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.nRunNo_In, THIS.oinvtmp.nRunNo) ;
                     AND crunyear == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.cRunYear_In, THIS.oinvtmp.crunyear)
                  IF FOUND()
                     lnGathGross  = wellwork.ngather
                     IF THIS.ngather = 0
                        THIS.ngather = lnGathGross / inctemp.nunits
                     ENDIF
                  ELSE
                     THIS.ngather = 0
                  ENDIF
               ELSE
                  THIS.ngather = 0
               ENDIF
            ENDIF
         ENDIF

         SELECT inctemp
         m.nprice  = inctemp.nprice

         IF inctemp.cbegrange = '  /  ' OR inctemp.cendrange = '  /  '
            m.crange = ''
         ENDIF

         jGross  = inctemp.ntotalinc

         *
         *  Check if this investor is a cDirect pay or a flat rate Royalty
         *
         m.lDirect = .F.
         IF NOT THIS.ooptions.lHideComp
            IF THIS.lroyaltyowner AND THIS.ooptions.lChgPrice AND m.cTYPE = 'MCF'
               *  If either one is zero, it's dumb to zero out the total
               IF m.nunits # 0 AND m.nprice # 0
                  m.nTOTAL = m.nunits * m.nprice
               ELSE
                  m.nTOTAL = jGross
               ENDIF
            ELSE
               m.nTOTAL   = jGross             && Re-establish total
            ENDIF
         ELSE
            m.nTOTAL   = jGross             && Re-establish total
         ENDIF
         IF SUBST(m.cTYPE, 2, 3) = 'TAX'
            IF NOT THIS.lownertaxexempt
               m.nOwnerAmt = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
               m.nOwnerVol = SWROUND(m.nunits * (m.nRevInt / 100), 2)
            ENDIF
         ELSE
            m.nOwnerAmt = SWROUND(m.nTOTAL * (m.nRevInt / 100), 2)
            m.nOwnerVol = SWROUND(m.nunits * (m.nRevInt / 100), 2)
         ENDIF

         m.nTOTAL    = jGross             && Re-establish total
         m.nOwnerPct = m.nRevInt
         m.cownerid  = THIS.cownerid
         m.nRunNo    = THIS.nRunNo
         m.crunyear  = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the settlement file  - Report Group 1
         *********************************************************************************************************
         INSERT INTO settlement FROM MEMVAR

         * Restore original interests that may have been changed by one-man-item processing.
         THIS.oinvtmp.nrevoil   = jnrevoil
         THIS.oinvtmp.nrevgas   = jnrevgas
         THIS.oinvtmp.nrevoth   = jnrevoth
         THIS.oinvtmp.nrevtax1  = jnrevtax1
         THIS.oinvtmp.nrevtax2  = jnrevtax2
         THIS.oinvtmp.nrevtax3  = jnrevtax3
         THIS.oinvtmp.nrevtax4  = jnrevtax4
         THIS.oinvtmp.nrevtax5  = jnrevtax5
         THIS.oinvtmp.nrevtax6  = jnrevtax6
         THIS.oinvtmp.nrevtax7  = jnrevtax7
         THIS.oinvtmp.nrevtax8  = jnrevtax8
         THIS.oinvtmp.nrevtax9  = jnrevtax9
         THIS.oinvtmp.nrevtax10 = jnrevtax10
         THIS.oinvtmp.nrevtax11 = jnrevtax11
         THIS.oinvtmp.nrevtax12 = jnrevtax12
         THIS.oinvtmp.nrevmisc1 = jnrevm1
         THIS.oinvtmp.nrevmisc2 = jnrevm2
         THIS.oinvtmp.nrevtrp   = jnrevtrans
         m.cdirect              = THIS.oinvtmp.cdirect
      ENDSCAN && nIncome

      m.cyear   = tcYear
      m.cperiod = tcPeriod
      SELE manualTax
      LOCATE FOR cwellid == m.cwellid AND cyear == m.cyear AND cperiod == m.cperiod
      IF NOT FOUND()
         INSERT INTO manualTax FROM MEMVAR
      ELSE
         DO CASE
            CASE m.cTYPE = 'OTAX1'
               REPLACE noiltax1 WITH noiltax1 + m.noiltax1
            CASE m.cTYPE = 'OTAX2'
               REPLACE noiltax2 WITH noiltax2 + m.noiltax2
            CASE m.cTYPE = 'OTAX3'
               REPLACE noiltax3 WITH noiltax3 + m.noiltax3
            CASE m.cTYPE = 'OTAX4'
               REPLACE noiltax4 WITH noiltax4 + m.noiltax4
            CASE m.cTYPE = 'GTAX1'
               REPLACE ngastax1 WITH ngastax1 + m.ngastax1
            CASE m.cTYPE = 'GTAX2'
               REPLACE ngastax2 WITH ngastax2 + m.ngastax2
            CASE m.cTYPE = 'GTAX3'
               REPLACE ngastax3 WITH ngastax3 + m.ngastax3
            CASE m.cTYPE = 'GTAX4'
               REPLACE ngastax4 WITH ngastax4 + m.ngastax4
            CASE m.cTYPE = 'PTAX1'
               REPLACE nprodtax1 WITH nprodtax1 + m.nprodtax1
            CASE m.cTYPE = 'PTAX2'
               REPLACE nprodtax2 WITH nprodtax2 + m.nprodtax2
            CASE m.cTYPE = 'PTAX3'
               REPLACE nprodtax3 WITH nprodtax3 + m.nprodtax3
            CASE m.cTYPE = 'PTAX4'
               REPLACE nprodtax4 WITH nprodtax4 + m.nprodtax4
         ENDCASE
      ENDIF
   ENDPROC


   *-- Calculates tax section
   ***********************************************************************
   PROCEDURE calctaxes
      ***********************************************************************
      LPARA m.cwellid, tnRunNo, tcRunYear, tcYear, tcPeriod, tdAcctDate, tcSuspType
      LOCAL m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4
      LOCAL m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4
      LOCAL m.nothtax1, m.nothtax2, m.nothtax3, m.nothtax4
      LOCAL m.nprodtax1, m.nprodtax2, m.nprodtax3, m.nprodtax4
      LOCAL m.noiltax1b, m.noiltax2b, m.noiltax3b, m.noiltax4b
      LOCAL m.ngastax1b, m.ngastax2b, m.ngastax3b, m.ngastax4b
      LOCAL m.nothtax1b, m.nothtax2b, m.nothtax3b, m.nothtax4b
      LOCAL m.nTaxBBL1, m.nTaxBBL2, m.nTaxBBL3, m.nTaxBBL4
      LOCAL m.nTaxMCF1, m.nTaxMCF2, m.nTaxMCF3, m.nTaxMCF4
      LOCAL m.cMethodBBL1, m.cMethodBBL2, m.cMethodBBL3, m.cMethodBBL4
      LOCAL m.cMethodMCF1, m.cMethodMCF2, m.cMethodMCF3, m.cMethodMCF4
      LOCAL m.cMethodOTH1, m.cMethodOTH2, m.cMethodOTH3, m.cMethodOTH4
      LOCAL m.cNameBBL1, m.cNameBBL2, m.cNameBBL3, m.cNameBBL4
      LOCAL m.cNameMCF1, m.cNameMCF2, m.cNameMCF3, m.cNameMCF4
      LOCAL m.cNameOTH1, m.cNameOTH2, m.cNameOTH3, m.cNameOTH4


      * Initialize Variables
      STORE 'Oil Taxes' TO m.cNameBBL1, m.cNameBBL2, m.cNameBBL3, m.cNameBBL4
      STORE 'Gas Taxes' TO m.cNameMCF1, m.cNameMCF2, m.cNameMCF3, m.cNameMCF4
      STORE 'Other Taxes' TO m.cNameOTH1, m.cNameOTH2, m.cNameOTH3, m.cNameOTH4
      STORE ' ' TO m.cMethodBBL1, m.cMethodBBL2, m.cMethodBBL3, m.cMethodBBL4
      STORE ' ' TO m.cMethodMCF1, m.cMethodMCF2, m.cMethodMCF3, m.cMethodMCF4
      STORE ' ' TO m.cMethodOTH1, m.cMethodOTH2, m.cMethodOTH3, m.cMethodOTH4
      STORE 0 TO m.nTaxBBL1, m.nTaxBBL2, m.nTaxBBL3, m.nTaxBBL4
      STORE 0 TO m.nTaxMCF1, m.nTaxMCF2, m.nTaxMCF3, m.nTaxMCF4

      SELECT invtmp
      SCATTER MEMVAR
      SELECT wellwork
      LOCATE FOR cwellid == THIS.cwellid AND crectype = 'R' ;
         AND hyear   == THIS.oinvtmp.hyear ;
         AND hperiod == THIS.oinvtmp.hperiod ;
         AND nRunNo  == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.nRunNo_In, THIS.oinvtmp.nRunNo) ;
         AND crunyear == IIF(THIS.oinvtmp.nRunNo_In # 0, THIS.oinvtmp.cRunYear_In, THIS.oinvtmp.crunyear)
      IF NOT FOUND()
         RETURN
      ENDIF
      SCATTER NAME THIS.owellwork

      * Make sure expense tax code is not set for taxes
      STORE '' TO m.ctaxcode, m.ctaxdesc

      * Look for the manually entered taxes for this well and period
      * Manually entered taxes have to be subtracted from the wellwork
      * total before the owner's share is calculated. The manually entered
      * taxes have already been added to the statemnt table in calcincome.
      SELE manualTax
      LOCATE FOR cwellid == THIS.cwellid AND cyear == THIS.cyear AND cperiod == THIS.cperiod
      IF FOUND()
         SCATTER MEMVAR
      ELSE
         STORE 0 TO m.noiltax1, m.noiltax2, m.noiltax3, m.noiltax4
         STORE 0 TO m.ngastax1, m.ngastax2, m.ngastax3, m.ngastax4
         STORE 0 TO m.nothtax1, m.nothtax2, m.nothtax3, m.nothtax4
         STORE 0 TO m.nprodtax1, m.nprodtax2, m.nprodtax3, m.nprodtax4
      ENDIF

      *  Check for one man item taxes for this well and owner
      SELECT one_man_tax
      LOCATE FOR cownerid == THIS.cownerid AND cwellid = THIS.cwellid ;
         AND hyear = THIS.cyear AND hperiod = THIS.cperiod ;
         AND crunyear = THIS.crunyear AND nRunNo = THIS.nRunNo
      IF FOUND()
         m.noiltax1b  = noiltax1b
         m.noiltax2b  = noiltax2b
         m.noiltax3b  = noiltax3b
         m.noiltax4b  = noiltax4b
         m.ngastax1b  = ngastax1b
         m.ngastax2b  = ngastax2b
         m.ngastax3b  = ngastax3b
         m.ngastax4b  = ngastax4b
         m.nprodtax1b = nprodtax1b
         m.nprodtax2b = nprodtax2b
         m.nprodtax3b = nprodtax3b
         m.nprodtax4b = nprodtax4b
      ELSE
         STORE 0 TO m.noiltax1b, m.noiltax2b, m.noiltax3b, m.noiltax4b
         STORE 0 TO m.ngastax1b, m.ngastax2b, m.ngastax3b, m.ngastax4b
         STORE 0 TO m.nprodtax1b, m.nprodtax2b, m.nprodtax3b, m.nprodtax4b
      ENDIF

      IF invtmp.nsevtaxes # 0
         STORE 0 TO lnoiltax1, lnoiltax2, lnoiltax3, lnoiltax4
         STORE 0 TO lngastax1, lngastax2, lngastax3, lngastax4
         STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4

         swSelect('wells')
         LOCATE FOR cwellid = THIS.cwellid
         SCATTER MEMVAR

         * Don't do anything with taxes here if the table
         * is empty on the well record.
         IF EMPTY(m.ctable) AND NOT m.lusesev
            RETURN
         ENDIF

         * Set the lusesev flag if the wellwork fields ntotmcftxr, ntotmcftxw, ntotbbltxr, ntotbbltxw have a value in them.
         * The flag could have been set in the well record when the run was closed but not set now when you're trying to
         * print a previous statement.
         IF THIS.owellwork.ntotmcftxr # 0 OR ;
               THIS.owellwork.ntotmcftxw # 0 OR ;
               THIS.owellwork.ntotbbltxr # 0 OR ;
               THIS.owellwork.ntotbbltxw # 0
            m.lusesev = .T.
         ENDIF

         lntaxes = 0
         swSelect('sevtax')
         SET ORDER TO ctable
         IF SEEK(m.ctable)
            SCATTER MEMVAR

            * Zero out rates if the purchaser is withholding
            * No calculations should be done in this case.
            IF m.lSev1O AND THIS.nRunNo = 0
               m.nTaxBBL1    = 0
               m.cMethodBBL1 = ' '
            ENDIF
            IF m.lSev2O AND THIS.nRunNo = 0
               m.nTaxBBL2    = 0
               m.cMethodBBL2 = ' '
            ENDIF
            IF m.lSev3O AND THIS.nRunNo = 0
               m.nTaxBBL3    = 0
               m.cMethodBBL3 = ' '
            ENDIF
            IF m.lSev4O AND THIS.nRunNo = 0
               m.nTaxBBL4    = 0
               m.cMethodBBL4 = ' '
            ENDIF
            IF m.lSev1G
               m.nTaxMCF1    = 0
               m.cMethodMCF1 = ' '
            ENDIF
            IF m.lSev2G
               m.nTaxMCF2    = 0
               m.cMethodMCF2 = ' '
            ENDIF
            IF m.lSev3G
               m.nTaxMCF3    = 0
               m.cMethodMCF3 = ' '
            ENDIF
            IF m.lSev4G
               m.nTaxMCF4    = 0
               m.cMethodMCF4 = ' '
            ENDIF
         ELSE
            IF NOT m.lusesev
               RETURN
            ELSE
               STORE 'Oil Taxes' TO m.cNameBBL1, m.cNameBBL2, m.cNameBBL3, m.cNameBBL4
               STORE 'Gas Taxes' TO m.cNameMCF1, m.cNameMCF2, m.cNameMCF3, m.cNameMCF4
               STORE 'Other Taxes' TO m.cNameOTH1, m.cNameOTH2, m.cNameOTH3, m.cNameOTH4
               STORE ' ' TO m.cMethodBBL1, m.cMethodBBL2, m.cMethodBBL3, m.cMethodBBL4
               STORE ' ' TO m.cMethodMCF1, m.cMethodMCF2, m.cMethodMCF3, m.cMethodMCF4
               STORE ' ' TO m.cMethodOTH1, m.cMethodOTH2, m.cMethodOTH3, m.cMethodOTH4
               STORE 0 TO m.nTaxBBL1, m.nTaxBBL2, m.nTaxBBL3, m.nTaxBBL4
               STORE 0 TO m.nTaxMCF1, m.nTaxMCF2, m.nTaxMCF3, m.nTaxMCF4
            ENDIF
         ENDIF

         IF m.lusesev
            STORE 0 TO m.nTaxBBL1, m.nTaxMCF1
            IF EMPTY(m.cNameMCF1)
               STORE 'Gas Taxes' TO m.cNameMCF1
            ENDIF
            IF EMPTY(m.cNameBBL1)
               STORE 'Oil Taxes' TO m.cNameBBL1
            ENDIF
            STORE ' ' TO m.cMethodBBL1
            STORE ' ' TO m.cMethodMCF1
            m.cMethod = 'W'
         ENDIF
         m.crptgroup = 'B'
         m.cyear     = m.hyear
         m.cperiod   = m.hperiod
         m.cprogcode = THIS.oinvtmp.cprogcode

         IF THIS.lownertaxexempt             && Owner is Tax Exempt
            m.ninvamt = 0
            STORE 0 TO lnoiltax1, lnoiltax2, lnoiltax3, lnoiltax4
            STORE 0 TO lngastax1, lngastax2, lngastax3, lngastax4
            STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
         ELSE
            *  If the owner has an oil interest, process oil taxes
            IF INLIST(THIS.oinvtmp.ctypeint, 'B', 'O')
               m.nbblinc = THIS.noilamount
               m.nunits  = THIS.ntotalbbl

               IF m.lusesev  && Override state severance tax table rates
                  IF THIS.noiltax1 = 0
                     IF THIS.lroyaltyowner
                        lnoiltax1  = SWROUND(((THIS.owellwork.ngrossoil * (m.nroysevo / 100)) * (m.nrevoil / 100)), 2)
                        STORE 0 TO lnoiltax2, lnoiltax3, lnoiltax4
                     ELSE
                        lnoiltax1  = SWROUND(((THIS.owellwork.ngrossoil * (m.nwrksevo / 100)) * (m.nrevoil / 100)), 2)
                        STORE 0 TO lnoiltax2, lnoiltax3, lnoiltax4
                     ENDIF
                  ENDIF
               ELSE
                  * If royalty owners are exempt, working interest owner takes full
                  * working interest share of severance tax.
                  IF THIS.lexemptroyalty
                     IF NOT THIS.lroyaltyowner
                        STORE m.nworkint TO m.nrevtax1, m.nrevtax4, m.nrevtax7, m.nrevtax10
                     ELSE
                        m.ninvamt = 0
                        STORE 0 TO lnoiltax1, lnoiltax2, lnoiltax3, lnoiltax4
                        STORE 0 TO lngastax1, lngastax2, lngastax3, lngastax4
                        STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
                     ENDIF
                  ENDIF
                  IF INLIST(m.cdirect, 'B', 'O')  && Direct Paid
                     lnPct = m.nrevtax1
                     IF NOT m.lSev1O OR NOT THIS.nRunNo = 0
                        IF NOT m.lDirOilPurch
                           lnoiltax1  = (SWROUND((THIS.owellwork.ngbbltax1 + m.noiltax1 - m.noiltax1b) * (lnPct / 100), 2)) + m.noiltax1b
                           m.nrevtax1 = lnPct
                           lntaxes    = lntaxes + lnoiltax1
                        ELSE
                           m.nWorkTot = (SWROUND((THIS.owellwork.ngbbltax1 + m.noiltax1 - m.noiltax1b) * (lnPct / 100), 2)) + m.noiltax1b
                           lnoiltax1  = 0
                        ENDIF
                     ELSE
                        lnoiltax1 = 0
                     ENDIF
                  ELSE        && Not Direct Paid
                     IF THIS.oinvtmp.noiltax1 # 0
                        IF NOT m.lSev1O OR NOT THIS.nRunNo = 0
                           * Save the original tax pct
                           lnPct      = m.nrevtax1
                           lnoiltax1  = (SWROUND((THIS.owellwork.ngbbltax1 + m.noiltax1 - m.noiltax1b) * (lnPct / 100), 2)) + m.noiltax1b
                           m.nrevtax1 = lnPct
                           lntaxes    = lntaxes + lnoiltax1
                        ELSE
                           lnoiltax1  = 0
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'O')  && Direct Paid
               IF NOT m.lSev2O
                  IF NOT m.lDirOilPurch
                     lnoiltax2 = (SWROUND((THIS.owellwork.ngbbltax2 + m.noiltax2 - m.noiltax2b) * (m.nrevtax4 / 100), 2)) + m.noiltax2b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngbbltax2 + m.noiltax2 - m.noiltax2b) * (m.nrevtax4 / 100), 2)) + m.noiltax2b
                     lnoiltax2  = 0
                  ENDIF
               ELSE
                  lnoiltax2 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev2O
                  lnoiltax2 = 0
               ELSE
                  IF THIS.oinvtmp.noiltax2 # 0
                     lnoiltax2 = (SWROUND((THIS.owellwork.ngbbltax2 + m.noiltax2 - m.noiltax2b) * (m.nrevtax4 / 100), 2)) + m.noiltax2b
                     lntaxes   = lntaxes + lnoiltax2
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'O')  && Direct Paid
               IF NOT m.lSev3O
                  IF NOT m.lDirOilPurch
                     lnoiltax3 = (SWROUND((THIS.owellwork.ngbbltax3 + m.noiltax3 - m.noiltax3b) * (m.nrevtax7 / 100), 2)) + m.noiltax3b
                     lntaxes   = lntaxes + lnoiltax3
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngbbltax3 + m.noiltax3 - m.noiltax3b) * (m.nrevtax7 / 100), 2)) + m.noiltax3b
                     lnoiltax3  = 0
                  ENDIF
               ELSE
                  lnoiltax3 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev3O
                  lnoiltax3 = 0
               ELSE
                  IF THIS.oinvtmp.noiltax3 # 0
                     lnoiltax3 = (SWROUND((THIS.owellwork.ngbbltax3 + m.noiltax3 - m.noiltax3b) * (m.nrevtax7 / 100), 2)) + m.noiltax3b
                     lntaxes   = lntaxes + lnoiltax3
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'O')  && Direct Paid
               IF NOT m.lSev4O
                  IF NOT m.lDirOilPurch
                     lnoiltax4 = (SWROUND((THIS.owellwork.ngbbltax4 + m.noiltax4 - m.noiltax4b) * (m.nrevtax10 / 100), 2)) + m.noiltax4b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngbbltax4 + m.noiltax4 - m.noiltax4b) * (m.nrevtax10 / 100), 2)) + m.noiltax4b
                     lnoiltax4  = 0
                  ENDIF
               ELSE
                  lnoiltax4 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev4O
                  lnoiltax4 = 0
               ELSE
                  IF THIS.oinvtmp.noiltax4 # 0
                     lnoiltax4 = (SWROUND((THIS.owellwork.ngbbltax4 + m.noiltax4 - m.noiltax4b) * (m.nrevtax10 / 100), 2)) + m.noiltax4b
                     lntaxes   = lntaxes + lnoiltax4
                  ENDIF
               ENDIF
            ENDIF

            IF THIS.lroyaltyowner AND THIS.lexemptroyalty
               STORE 0 TO lnoiltax1, lnoiltax2, lnoiltax3, lnoiltax4
            ENDIF

            * Check for well being exempt from certain taxes and zero out
            * those taxes when appropriate
            IF m.lTaxExempt1
               lnoiltax1 = 0
            ENDIF
            IF m.lTaxExempt2
               lnoiltax2 = 0
            ENDIF
            IF m.lTaxExempt3
               lnoiltax3 = 0
            ENDIF
            IF m.lTaxExempt4
               lnoiltax4 = 0
            ENDIF

            IF lnoiltax1 + lnoiltax2 + lnoiltax3 + lnoiltax4 + m.nWorkTot # 0
               THIS.nwelltot = THIS.nwelltot - lnoiltax1 - lnoiltax2 - lnoiltax3 - lnoiltax4
               m.cownerid    = THIS.cownerid
               IF lnoiltax1 # 0 OR m.nWorkTot # 0
                  m.cProdType   = 'OTAX1'
                  IF NOT m.lusesev
                     m.cMethod  = m.cMethodBBL1
                  ENDIF

                  m.nOwnerAmt  = lnoiltax1 * -1
                  IF m.lusesev
                     IF THIS.lroyaltyowner
                        m.nprice          = m.nroysevo / 100
                        m.nPartnerShipAmt = SWROUND((THIS.owellwork.ngrossoil * (m.nroysevo / 100)), 2) * -1
                     ELSE
                        m.nprice          = m.nwrksevo / 100
                        m.nPartnerShipAmt = SWROUND((THIS.owellwork.ngrossoil * (m.nwrksevo / 100)), 2) * -1
                     ENDIF
                  ELSE
                     m.nprice   = m.nTaxBBL1
                     *  Remove any manually entered taxes from calculated total
                     m.nPartnerShipAmt   = (THIS.owellwork.ngbbltax1 + m.noiltax1) * -1
                  ENDIF
                  m.nunits   = THIS.owellwork.ntotbbl
                  STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol
                  *********************************************************************************************************
                  *  Insert into the statement file  - Section 1
                  *********************************************************************************************************
                  m.cSection  = '1'
                  m.cOwnerPct = m.nRevInt
                  INSERT INTO settlement FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF

               IF lnoiltax2 # 0 OR m.nWorkTot # 0
                  m.cProdType = 'OTAX2'
                  m.cMethod   = m.cMethodBBL2
                  m.nOwnerAmt = lnoiltax2 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nPartnerShipAmt = (THIS.owellwork.ngbbltax2 + m.noiltax2) * -1
                  m.nunits          = THIS.owellwork.ntotbbl
                  STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  m.cSection  = '1'
                  m.nOwnerPct = m.nrevtax4
                  INSERT INTO settlement FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lnoiltax3 # 0 OR m.nWorkTot # 0
                  m.cProdType = 'OTAX3'
                  m.csource   = m.cNameBBL3
                  m.crange    = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod   = m.cMethodBBL3
                  *                     m.ctaxable = THIS.oWellWork.ngbbltax3/m.nTaxBBL3
                  m.cTaxable = THIS.owellwork.ngrossoil
                  m.ninvamt  = lnoiltax3 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nTOTAL   = (THIS.owellwork.ngbbltax3 + m.noiltax3) * -1
                  m.nprice   = m.nTaxBBL3
                  m.nRevInt  = m.nrevtax7
                  m.nRunNo   = THIS.nRunNo
                  m.crunyear = THIS.crunyear
                  m.nunits   = THIS.owellwork.ntotbbl
                  STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  m.cSection  = '1'
                  m.nOwnerPct = m.nRevInt
                  INSERT INTO settlement FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lnoiltax4 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'OTAX4'
                  m.csource = m.cNameBBL4
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod = m.cMethodBBL4
                  *                     m.ctaxable = THIS.oWellWork.ngbbltax4/m.nTaxBBL4
                  m.cTaxable  = THIS.owellwork.ngrossoil
                  m.nOwnerAmt = lnoiltax4 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nPartnerShipAmt = (THIS.owellwork.ngbbltax4 + m.noiltax4) * -1
                  m.nprice          = 0
                  STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  m.cSection  = '1'
                  m.nOwnerPct = m.nrevtax10
                  INSERT INTO settlement FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
            ENDIF
         ENDIF


         IF INLIST(THIS.oinvtmp.ctypeint, 'B', 'G')
            IF m.lusesev  && Use state severance tax table rates
               m.cMethod = 'W'
               IF THIS.ngastax1 = 0
                  IF THIS.lroyaltyowner
                     lngastax1  = SWROUND(((THIS.owellwork.ngrossgas * (m.nroysevg / 100)) * (m.nrevgas / 100)), 2)
                     STORE 0 TO lngastax2, lngastax3, lngastax4
                  ELSE
                     lngastax1  = SWROUND(((THIS.owellwork.ngrossgas * (m.nwrksevg / 100)) * (m.nrevgas / 100)), 2)
                     STORE 0 TO lngastax2, lngastax3, lngastax4
                  ENDIF
               ENDIF
            ELSE
               * If royalty owners are exempt, working interest owner takes full
               * working interest share of severance tax.
               IF THIS.lexemptroyalty AND NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax2, m.nrevtax5, m.nrevtax8, m.nrevtax11
               ENDIF
               IF INLIST(m.cdirect, 'B', 'G')  && Direct Paid
                  lnPct = m.nrevtax2
                  IF NOT m.lSev1G
                     IF NOT m.lDirGasPurch
                        lngastax1  = (SWROUND((THIS.owellwork.ngmcftax1 + m.ngastax1 - m.ngastax1b) * (lnPct / 100), 2)) + m.ngastax1b
                        m.nrevtax2 = lnPct
                        lntaxes    = lntaxes + lnoiltax1
                     ELSE
                        m.nWorkTot = (SWROUND((THIS.owellwork.ngmcftax1 + m.ngastax1 - m.ngastax1b) * (lnPct / 100), 2)) + m.ngastax1b
                        lngastax1  = 0
                     ENDIF
                  ELSE
                     lngastax1 = 0
                  ENDIF
               ELSE        && Not Direct Paid
                  IF THIS.oinvtmp.ngastax1 # 0
                     * Save the original tax pct
                     lnPct      = m.nrevtax2
                     lngastax1  = (SWROUND((THIS.owellwork.ngmcftax1 + m.ngastax1 - m.ngastax1b) * (lnPct / 100), 2)) + m.ngastax1b
                     m.nrevtax2 = lnPct
                     lntaxes    = lntaxes + lngastax1
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'G')  && Direct Paid
               IF NOT m.lSev2G
                  IF NOT m.lDirGasPurch
                     lngastax2 = (SWROUND((THIS.owellwork.ngmcftax2 + m.ngastax2 - m.ngastax2b) * (m.nrevtax5 / 100), 2)) + m.ngastax2b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngmcftax2 + m.ngastax2 - m.ngastax2b) * (m.nrevtax5 / 100), 2)) + m.ngastax2b
                     lngastax2  = 0
                  ENDIF
               ELSE
                  lngastax2 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev2G
                  lngastax2 = 0
               ELSE
                  IF THIS.oinvtmp.ngastax2 # 0
                     lngastax2 = (SWROUND((THIS.owellwork.ngmcftax2 + m.ngastax2 - m.ngastax2b) * (m.nrevtax5 / 100), 2)) + m.ngastax2b
                     lntaxes   = lntaxes + lngastax2
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'G')  && Direct Paid
               IF NOT m.lSev3G
                  IF NOT m.lDirGasPurch
                     lngastax3 = (SWROUND((THIS.owellwork.ngmcftax3 + m.ngastax3 - m.ngastax3b) * (m.nrevtax8 / 100), 2)) + m.ngastax3b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngmcftax3 + m.ngastax3 - m.ngastax3b) * (m.nrevtax8 / 100), 2)) + m.ngastax3b
                     lngastax3  = 0
                  ENDIF
               ELSE
                  lngastax3 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev3G
                  lngastax3 = 0
               ELSE
                  IF THIS.oinvtmp.ngastax3 # 0
                     lngastax3 = (SWROUND((THIS.owellwork.ngmcftax3 + m.ngastax3 - m.ngastax3b) * (m.nrevtax8 / 100), 2)) + m.ngastax3b
                     lntaxes   = lntaxes + lngastax3
                  ENDIF
               ENDIF
            ENDIF

            IF INLIST(m.cdirect, 'B', 'G')  && Direct Paid
               IF NOT m.lSev4G
                  IF NOT m.lDirGasPurch
                     lngastax4 = (SWROUND((THIS.owellwork.ngmcftax4 + m.ngastax4 - m.ngastax4b) * (m.nrevtax11 / 100), 2)) + m.ngastax4b
                     lntaxes   = lntaxes + lnoiltax2
                  ELSE
                     m.nWorkTot = (SWROUND((THIS.owellwork.ngmcftax4 + m.ngastax4 - m.ngastax4b) * (m.nrevtax11 / 100), 2)) + m.ngastax4b
                     lngastax4  = 0
                  ENDIF
               ELSE
                  lngastax4 = 0
               ENDIF
            ELSE   && Not Direct Paid
               IF m.lSev4G
                  lngastax4 = 0
               ELSE
                  IF THIS.oinvtmp.ngastax4 # 0
                     lngastax4 = (SWROUND((THIS.owellwork.ngmcftax4 + m.ngastax4 - m.ngastax4b) * (m.nrevtax11 / 100), 2)) + m.ngastax4b
                     lntaxes   = lntaxes + lngastax4
                  ENDIF
               ENDIF
            ENDIF

            *  If royalty owners are exempt from the severance tax, don't
            *  show a share for them.
            IF THIS.lexemptroyalty AND THIS.lroyaltyowner
               STORE 0 TO lngastax1, lngastax2, lngastax3, lngastax4
            ENDIF

            * Check for well being exempt from certain taxes and zero out
            * those taxes when appropriate
            IF m.lTaxExempt1
               lngastax1 = 0
            ENDIF
            IF m.lTaxExempt2
               lngastax2 = 0
            ENDIF
            IF m.lTaxExempt3
               lngastax3 = 0
            ENDIF
            IF m.lTaxExempt4
               lngastax4 = 0
            ENDIF

            IF lngastax1 + lngastax2 + lngastax3 + lngastax4 + m.nWorkTot # 0
               THIS.nwelltot = THIS.nwelltot - lngastax1 - lngastax2 - lngastax3 - lngastax4
               m.cownerid    = THIS.cownerid
               IF lngastax1 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'GTAX1'
                  m.csource = m.cNameMCF1
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  IF NOT m.lusesev
                     m.cMethod  = m.cMethodMCF1
                  ENDIF

                  m.nOwnerAmt  = lngastax1 * -1
                  IF m.lusesev
                     IF THIS.lroyaltyowner
                        m.nprice          = 0
                        m.nPartnerShipAmt = SWROUND((THIS.owellwork.ngrossgas * (m.nroysevg / 100)), 2) * -1
                     ELSE
                        m.nprice          = 0
                        m.nPartnerShipAmt = SWROUND((THIS.owellwork.ngrossgas * (m.nwrksevg / 100)), 2) * -1
                     ENDIF
                  ELSE
                     *  Remove any manually entered taxes from calculated total
                     m.nPartnerShipAmt = (THIS.owellwork.ngmcftax1 + m.ngastax1) * -1
                     m.nprice          = 0
                  ENDIF
                  STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol, m.nprice
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  m.cSection = '1'
                  INSERT INTO settlement FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lngastax2 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'GTAX2'
                  m.csource = m.cNameMCF2
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod = m.cMethodMCF2
                  *                     m.ctaxable = THIS.oWellWork.nTotMCFtx2/m.nTaxMCF2
                  m.nOwnerAmt  = lngastax2 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nPartnerShipAmt = (THIS.owellwork.ngmcftax2 + m.ngastax2) * -1
                  m.nprice          = 0
                  m.nRevInt         = m.nrevtax5
                  m.nRunNo          = THIS.nRunNo
                  m.crunyear        = THIS.crunyear
                  STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol, m.nprice
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************

                  m.cSection = '1'
                  INSERT INTO settlement FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lngastax3 # 0 OR m.nWorkTot # 0
                  m.cTYPE   = 'GTAX3'
                  m.csource = m.cNameMCF3
                  m.crange  = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod = m.cMethodMCF3
                  *                     m.ctaxable = THIS.oWellWork.nTotMCFtx3/m.nTaxMCF3
                  m.cTaxable  = THIS.owellwork.ngrossgas
                  m.nOwnerAmt = lngastax3 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nPartnerShipAmt = (THIS.owellwork.ngmcftax3 + m.ngastax3) * -1
                  m.nprice          = m.nTaxMCF3
                  m.nRevInt         = m.nrevtax8
                  STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol, m.nprice
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  m.cSection = '1'
                  INSERT INTO settlement FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
               IF lngastax4 # 0 OR m.nWorkTot # 0
                  m.cProdType = 'GTAX4'
                  m.csource   = m.cNameMCF4
                  m.crange    = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
                  m.cMethod   = m.cMethodMCF4
                  *                     m.ctaxable = THIS.oWellWork.nTotMCFtx4/m.nTaxMCF4
                  m.nOwnerAmt  = lngastax4 * -1
                  *  Remove any manually entered taxes from calculated total
                  m.nPartnerShipAmt = (THIS.owellwork.ngmcftax4 + m.ngastax4) * -1
                  m.nprice          = 0
                  STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol, m.nprice
                  *********************************************************************************************************
                  *  Insert into the statement file  - Report Group B
                  *********************************************************************************************************
                  m.cSection = '1'
                  INSERT INTO settlement FROM MEMVAR
                  m.nWorkTot = 0
               ENDIF
            ENDIF
         ENDIF
         *
         *  Calculate other product taxes
         *

         *  The ngOthTax1-4 variables in wellhist don't contain any one-man OTH taxes, so this was changed to not subtract it from the
         *  (THIS.owellwork.ngothtax1+m.nothtax1) calculation like OTAX and GTAX. - BH 10/28/2009

         IF m.lSev1P
            lnothtax1 = 0
         ELSE
            * If royalty owners are exempt, working interest owner takes full
            * working interest share of severance tax.
            IF THIS.lexemptroyalty
               IF NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax3, m.nrevtax6, m.nrevtax9, m.nrevtax12
               ELSE
                  m.ninvamt = 0
                  STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
               ENDIF
            ENDIF
            lnothtax1 = (SWROUND((THIS.owellwork.ngothtax1 + m.nprodtax1 - m.nprodtax1b) * (m.nrevtax3 / 100), 2)) + m.nprodtax1b
            lntaxes   = lntaxes + lnothtax1
         ENDIF
         IF m.lSev2P
            lnothtax2 = 0
         ELSE
            * If royalty owners are exempt, working interest owner takes full
            * working interest share of severance tax.
            IF THIS.lexemptroyalty
               IF NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax3, m.nrevtax6, m.nrevtax9, m.nrevtax12
               ELSE
                  m.ninvamt = 0
                  STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
               ENDIF
            ENDIF

            lnothtax2 = (SWROUND((THIS.owellwork.ngothtax2 + m.nprodtax2 - m.nprodtax2b) * (m.nrevtax6 / 100), 2)) + m.nprodtax2b
            lntaxes   = lntaxes + lnothtax2
         ENDIF
         IF m.lSev3P
            lnothtax3 = 0
         ELSE
            * If royalty owners are exempt, working interest owner takes full
            * working interest share of severance tax.
            IF THIS.lexemptroyalty
               IF NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax3, m.nrevtax6, m.nrevtax9, m.nrevtax12
               ELSE
                  m.ninvamt = 0
                  STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
               ENDIF
            ENDIF

            lnothtax3 = (SWROUND((THIS.owellwork.ngothtax3 + m.nprodtax3 - m.nprodtax3b) * (m.nrevtax9 / 100), 2)) + m.nprodtax3b
            lntaxes   = lntaxes + lnothtax3
         ENDIF
         IF m.lSev4P
            lnothtax4 = 0
         ELSE
            * If royalty owners are exempt, working interest owner takes full
            * working interest share of severance tax.
            IF THIS.lexemptroyalty
               IF NOT THIS.lroyaltyowner
                  STORE m.nworkint TO m.nrevtax3, m.nrevtax6, m.nrevtax9, m.nrevtax12
               ELSE
                  m.ninvamt = 0
                  STORE 0 TO lnothtax1, lnothtax2, lnothtax3, lnothtax4
               ENDIF
            ENDIF

            lnothtax4 = (SWROUND((THIS.owellwork.ngothtax4 + m.nprodtax4 - m.nprodtax4b) * (m.nrevtax12 / 100), 2)) + m.nprodtax4b
            lntaxes   = lntaxes + lnothtax4
         ENDIF

         * Check for well being exempt from certain taxes and zero out
         * those taxes when appropriate
         IF m.lTaxExempt1
            lnothtax1 = 0
         ENDIF
         IF m.lTaxExempt2
            lnothtax2 = 0
         ENDIF
         IF m.lTaxExempt3
            lnothtax3 = 0
         ENDIF
         IF m.lTaxExempt4
            lnothtax4 = 0
         ENDIF

         IF lnothtax1 + lnothtax2 + lnothtax3 + lnothtax4 # 0
            THIS.nwelltot = THIS.nwelltot - lnothtax1 - lnothtax2 - lnothtax3 - lnothtax4
            m.cownerid    = THIS.cownerid
            IF lnothtax1 # 0
               m.cProdType = 'PTAX1'
               m.crange    = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
               m.cMethod   = m.cMethodOTH1
               m.cTaxable  = THIS.owellwork.nOthInc
               m.nOwnerAmt = lnothtax1 * -1
               *  Remove any manually entered taxes from calculated total
               m.nPartnerShipAmt = (THIS.owellwork.ntotothtx1 + m.nprodtax1) * -1
               m.nRevInt         = m.nrevtax3
               STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol, m.nprice
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               m.cSection = '1'
               INSERT INTO settlement FROM MEMVAR
            ENDIF
            IF lnothtax2 # 0
               m.cProdType = 'PTAX2'
               m.csource   = m.cNameOTH2
               m.crange    = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
               m.cMethod   = m.cMethodOTH2
               m.nOwnerAmt = lnothtax2 * -1
               *  Remove any manually entered taxes from calculated total
               m.nPartnerShipAmt   = (THIS.owellwork.ntotothtx2 + m.nprodtax2) * -1
               STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol, m.nprice
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               m.cSection = '1'
               INSERT INTO settlement FROM MEMVAR
            ENDIF
            IF lnothtax3 # 0
               m.cTYPE     = 'PTAX3'
               m.csource   = m.cNameOTH3
               m.crange    = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
               m.cMethod   = m.cMethodOTH3
               m.cTaxable  = THIS.owellwork.nOthInc
               m.nOwnerAmt = lnothtax3 * -1
               *  Remove any manually entered taxes from calculated total
               m.nPartnerShipAmt   = (THIS.owellwork.ntotothtx3 + m.nprodtax3) * -1
               STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol, m.nprice
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               m.cSection = '1'
               INSERT INTO settlement FROM MEMVAR
            ENDIF
            IF lnothtax4 # 0
               m.cTYPE     = 'PTAX4'
               m.csource   = m.cNameOTH4
               m.crange    = ''  &&  Blank out the range, since it's still hanging onto a floating variable from the wells table
               m.cMethod   = m.cMethodOTH4
               m.cTaxable  = THIS.owellwork.nOthInc
               m.nOwnerAmt = lnothtax4 * -1
               *  Remove any manually entered taxes from calculated total
               m.nPartnerShipAmt   = (THIS.owellwork.ntotothtx4 + m.nprodtax4) * -1
               STORE 0 TO m.nGrossVol, m.nPartnerShipVol, m.nOwnerVol, m.nprice
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group B
               *********************************************************************************************************
               m.cSection = '1'
               INSERT INTO settlement FROM MEMVAR
            ENDIF
         ENDIF
      ENDIF
   ENDPROC


   *-- Calculates expense section
   ***********************************************************************
   PROCEDURE CalcExpense
      ***********************************************************************
      LPARA tnRunNo, tcYear, tcProdYear, tcProdPrd, tdAcctDate
      LOCAL lcScan, tcYear, tcRunYear, llReturn

      llReturn = .F.

      * If we're printing the report for a new run and the current
      * record didn't come from suspense then reset the runno parms
      IF EMPTY(THIS.oinvtmp.cSuspType) AND THIS.lNewRun
         tnRunNo   = 0
         tcRunYear = '   '
      ELSE
         tcRunYear = tcYear
      ENDIF

      swSelect('expcat')
      LOCATE FOR ccatcode = 'PDEF'
      IF FOUND()
         IF EMPTY(ctaxcode)
            REPLACE ctaxcode WITH 'OE'
         ENDIF
      ENDIF

      llSuspense = NOT EMPTY(THIS.oinvtmp.cSuspType) AND THIS.oinvtmp.cRunYear_In + PADL(TRANSFORM(THIS.oinvtmp.nRunNo_In), 3, '0') # THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      SELE exptemp
      LOCATE FOR cwellid == THIS.oinvtmp.cwellid AND ;
         IIF(THIS.lNewRun AND NOT llSuspense, nrunnorev = 0, nrunnorev = tnRunNo AND crunyearrev = tcRunYear) ;
         AND cyear + cperiod = tcProdYear + tcProdPrd
      IF NOT FOUND()
         IF THIS.lSumExp         && Summarize expenses
            IF THIS.lchksubtot
               lcOrderBy = 'expense.cwellid, expense.cDeck, expcat.ctaxcode, expense.ccateg, expense.cexpclass, expense.cownerid'
            ELSE
               lcOrderBy = 'expense.cwellid, expense.cDeck, expense.ccateg, expense.cexpclass, expense.cownerid'
            ENDIF
            SELECT  expense.cwellid, ;
                    expense.cDeck, ;
                    expense.ccateg, ;
                    expcat.ctaxcode, ;
                    expense.cyear, ;
                    expense.cperiod, ;
                    expense.crefid, ;
                    expense.dExpDate, ;
                    SUM(expense.nAmount) AS nAmount, ;
                    SUM(expense.ngrossval) AS ngrossval, ;
                    expense.cpayee, ;
                    SPACE(60) AS cmemo, ;
                    expense.cvendorid, ;
                    expense.cpaidbyck, ;
                    expense.cExpClass, ;
                    expense.ninterest, ;
                    expense.cpayee AS cDescription, ;
                    taxcodes.cDesc AS cTaxSection, ;
                    nsaltwater, ;
                    cprdpaid, ;
                    expense.ccatcode, ;
                    lfixed, ;
                    laptran, ;
                    cbatch, ;
                    cownerid, ;
                    .F. AS loneman, ;
                    expcat.cdescrip, ;
                    nrunnorev, ;
                    crunyearrev ;
                FROM expense, expcat, taxcodes  ;
                WHERE cwellid == THIS.oinvtmp.cwellid ;
                    AND taxcodes.ctaxcode = expcat.ctaxcode ;
                    AND IIF(THIS.lNewRun ;
                      AND NOT llSuspense, nrunnorev = 0 ;
                      AND dExpDate <= THIS.dExpDate, nrunnorev = tnRunNo ;
                      AND crunyearrev = tcYear) ;
                    AND cyear + cperiod = tcProdYear + tcProdPrd ;
                    AND NOT INLIST(expense.ccatcode, 'MKTG', 'COMP', 'GATH') ;
                    AND expense.cyear # 'FIXD' ;
                    AND expense.ccatcode = expcat.ccatcode ;
                    AND expense.ccatcode NOT IN(SELECT  ccatcode ;
                                                    FROM expcat ;
                                                    WHERE lJIBOnly) ;
                INTO CURSOR exptemp1 ;
                ORDER BY &lcOrderBy ;
                GROUP BY &lcOrderBy
            lcselect = 'exptemp'
         ELSE
            IF THIS.lchksubtot
               lcOrderBy = 'expense.cwellid, expense.cDeck, expcat.ctaxcode, expense.cYear, expense.cPeriod, expense.dexpdate'
            ELSE
               lcOrderBy = 'expense.cwellid, expense.cDeck, expense.cYear, expense.cPeriod, expense.dexpdate'
            ENDIF
            SELECT  expense.cwellid, ;
                    expense.cDeck, ;
                    expense.ccateg, ;
                    expcat.ctaxcode, ;
                    expense.cyear, ;
                    expense.cperiod, ;
                    expense.crefid, ;
                    expense.dExpDate, ;
                    expense.nAmount, ;
                    expense.ngrossval, ;
                    expense.ccatcode, ;
                    expense.cpayee, ;
                    expense.cmemo, ;
                    expense.cvendorid, ;
                    expense.cpaidbyck, ;
                    expense.cExpClass, ;
                    expense.ninterest, ;
                    expense.cpayee AS cDescription, ;
                    taxcodes.cDesc AS cTaxSection, ;
                    nsaltwater, ;
                    cprdpaid, ;
                    lfixed, ;
                    laptran, ;
                    cbatch, ;
                    cownerid, ;
                    .F. AS loneman, ;
                    expcat.cdescrip, ;
                    nrunnorev, ;
                    crunyearrev ;
                FROM expense, expcat, taxcodes ;
                WHERE cwellid == THIS.oinvtmp.cwellid ;
                    AND taxcodes.ctaxcode = expcat.ctaxcode ;
                    AND IIF(THIS.lNewRun ;
                      AND NOT llSuspense, nrunnorev = 0 ;
                      AND dExpDate <= THIS.dExpDate, nrunnorev = tnRunNo ;
                      AND crunyearrev = tcYear) ;
                    AND cyear + cperiod = tcProdYear + tcProdPrd ;
                    AND NOT INLIST(expense.ccatcode, 'MKTG', 'COMP', 'GATH') ;
                    AND expense.cyear # 'FIXD' ;
                    AND  expense.ccatcode = expcat.ccatcode ;
                    AND expense.ccatcode NOT IN(SELECT  ccatcode ;
                                                    FROM expcat ;
                                                    WHERE lJIBOnly) ;
                INTO CURSOR exptemp1 ;
                ORDER BY &lcOrderBy
         ENDIF

         CREATE CURSOR exptemp ;
            (cwellid    C(10), ;
              cDeck      C(10), ;
              ccatcode   C(4), ;
              ccateg     C(60), ;
              ctaxcode   C(2), ;
              cyear      C(4), ;
              cperiod    C(2), ;
              crefid     C(20), ;
              dExpDate   D, ;
              nAmount    N(12, 2), ;
              ngrossval  N(12, 2), ;
              cpayee     C(60), ;
              cmemo      C(60), ;
              cvendorid  C(10), ;
              cpaidbyck  C(8), ;
              cExpClass  C(1), ;
              cTaxSection C(60), ;
              cDescription C(40), ;
              nsaltwater I, ;
              cprdpaid   C(6), ;
              lfixed     L, ;
              laptran    L, ;
              cbatch     C(8), ;
              cownerid   C(10), ;
              loneman    L, ;
              cdescrip   C(60), ;
              nrunnorev  I, ;
              crunyearrev C(4), ;
              ninterest  N(11, 7), ;
              lused      L)

         SELE exptemp
         APPEND FROM DBF('exptemp1')

         SELE exptemp
         REPL lused WITH .F. ALL
      ENDIF

      SELE exptemp
      IF EMPTY(THIS.oinvtmp.cSuspType)
         LOCATE FOR cwellid = m.cwellid ;
            AND IIF(THIS.lNewRun AND NOT llSuspense, nrunnorev = 0 AND dExpDate <= ;
              THIS.dExpDate, nrunnorev = tnRunNo AND crunyearrev = tcRunYear) ;
            AND cyear + cperiod = tcProdYear + tcProdPrd
         IF NOT FOUND()
            RETURN .F.
         ENDIF
      ELSE
         LOCATE FOR cwellid == m.cwellid ;
            AND IIF(THIS.lNewRun AND NOT llSuspense, nrunnorev = 0 AND dExpDate <= ;
              THIS.dExpDate, nrunnorev = THIS.oinvtmp.nRunNo_In AND crunyearrev = THIS.oinvtmp.cRunYear_In) ;
            AND cyear + cperiod = tcProdYear + tcProdPrd
         IF THIS.oinvtmp.lmanual OR NOT FOUND()
            RETURN .F.
         ENDIF
      ENDIF
      IF THIS.lSumExp
         lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND NOT lUsed AND ' + ;
            "cexpclass = '0' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
      ELSE
         lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
            '(cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
            "cexpclass = '0' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') AND NOT lUsed"
      ENDIF

      SELECT exptemp
      LOCATE FOR ninterest # 0
      m.nPartnerShipPct = exptemp.ninterest

      LOCATE FOR &lcScan
      IF FOUND()
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            m.cCategory    = m.ccateg

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = THIS.oinvtmp.nworkint
            m.nworkint     = THIS.oinvtmp.nworkint

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W'
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  m.nworkint = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  m.nworkint = THIS.oinvtmp.nworkint
                  IF THIS.oinvtmp.nworkint = 0
                     LOOP
                  ENDIF
            ENDCASE

            llReturn = .T.
            SELE exptemp
            IF m.nworkint # 0
               REPL lused WITH .T.
            ENDIF

            m.creference = m.crefid

            * Calculate the owner's share of the expense
            m.nOwnerAmt       = SWROUND(m.nAmount * (m.nworkint / 100), 2)

            IF m.goApp.lParentCompany
               m.nPartnerShipPct = THIS.NonDummyPct(exptemp.cwellid, 'E')
               m.nPartnerShipAmt = swNetExp(m.nAmount, exptemp.cwellid, .T., exptemp.cExpClass, 'N', .F., exptemp.cownerid, exptemp.ccatcode)
               m.nGrossAmt       = exptemp.nAmount
            ELSE
               m.nPartnerShipAmt = m.nAmount
               m.nGrossAmt       = m.ngrossval
            ENDIF

            m.cownerid  = THIS.cownerid
            m.cprogcode = THIS.oinvtmp.cprogcode

            * Only insert a record if the expense line is non-zero
            IF m.nOwnerAmt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Section 2
               *********************************************************************************************************
               m.cSection  = '2'
               m.nOwnerPct = THIS.oinvtmp.nworkint
               INSERT INTO settlement FROM MEMVAR
            ENDIF

            * Restore the interest in case we changed it for one man item processing
            m.nworkint = lnSaveInterest

            STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo

         ENDSCAN  && Exptemp
      ENDIF

      IF THIS.oinvtmp.ntotale1 # 0

         SELECT exptemp
         IF THIS.lSumExp
            lcScan = 'cwellid = THIS.oInvTmp.cwellid AND ' + ;
               "cexpclass = '1' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ELSE
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               ' (cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
               " cexpclass = '1' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ENDIF
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            llReturn = .T.

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = THIS.oinvtmp.nintclass1
            m.nintclass1   = THIS.oinvtmp.nintclass1

            IF m.nintclass1 # 0
               REPL lused WITH .T.
            ENDIF

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W'
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  m.nintclass1 = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  m.nintclass1 = THIS.oinvtmp.nintclass1
                  IF THIS.oinvtmp.nintclass1 = 0
                     LOOP
                  ENDIF
            ENDCASE

            SELE exptemp
            REPL lused WITH .T.

            m.cSection   = '2'
            m.cCategory  = m.ccateg
            m.dExpDate   = m.dExpDate
            m.creference = m.crefid

            * Calculate the owner's share of the expense
            m.nOwnerAmt       = SWROUND(m.nAmount * (m.nintclass1 / 100), 2)

            IF m.goApp.lParentCompany
               m.nPartnerShipPct = THIS.NonDummyPct(exptemp.cwellid, 'E')
               m.nPartnerShipAmt = swNetExp(m.nAmount, exptemp.cwellid, .T., exptemp.cExpClass, 'N', .F., exptemp.cownerid, exptemp.ccatcode)
               m.nGrossAmt       = exptemp.nAmount
            ELSE
               m.nPartnerShipAmt = m.nAmount
               m.nGrossAmt       = m.ngrossval
            ENDIF

            * Calculate the owner's share of the expense
            m.ninvamt   = SWROUND((m.nAmount * (m.nintclass1 / 100)), 2)
            m.cownerid  = THIS.cownerid
            m.dAcctDate = THIS.dAcctDate
            m.cprogcode = THIS.oinvtmp.cprogcode


            IF m.nOwnerAmt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group D
               *********************************************************************************************************
               m.cSection  = '2'
               m.nOwnerPct = m.nintclass1
               INSERT INTO settlement FROM MEMVAR
            ENDIF

            * Restore the interest in case we changed it for one man item processing
            m.nintclass1 = lnSaveInterest

            STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo
         ENDSCAN  && Exptemp
      ENDIF

      IF THIS.oinvtmp.ntotale2 # 0
         SELECT exptemp
         IF THIS.lSumExp
            lcScan = 'cwellid = THIS.oInvTmp.cwellid AND ' + ;
               "cexpclass = '2' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ELSE
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               '(cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
               "cexpclass = '2' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ENDIF
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            llReturn = .T.
            REPL lused WITH .T.

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = THIS.oinvtmp.nintclass2
            m.nintclass2   = THIS.oinvtmp.nintclass2

            IF m.nintclass2 # 0
               REPL lused WITH .T.
            ENDIF

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W'
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  m.nintclass2 = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  m.nintclass2 = THIS.oinvtmp.nintclass2
                  IF THIS.oinvtmp.nintclass2 = 0
                     LOOP
                  ENDIF
            ENDCASE

            SELE exptemp
            REPL lused WITH .T.

            m.cCategory  = m.ccateg
            m.cSection   = '2'
            m.creference = m.crefid

            * Calculate the owner's share of the expense
            m.nOwnerAmt   = SWROUND((m.nAmount * (m.nintclass2 / 100)), 2)
            IF m.goApp.lParentCompany
               m.nPartnerShipPct = THIS.NonDummyPct(exptemp.cwellid, 'E')
               m.nPartnerShipAmt = swNetExp(m.nAmount, exptemp.cwellid, .T., exptemp.cExpClass, 'N', .F., exptemp.cownerid, exptemp.ccatcode)
               m.nGrossAmt       = exptemp.nAmount
            ELSE
               m.nPartnerShipAmt = m.nAmount
               m.nGrossAmt       = m.ngrossval
            ENDIF
            m.cownerid  = THIS.cownerid
            m.cprogcode = THIS.oinvtmp.cprogcode


            IF m.nOwnerAmt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group D
               *********************************************************************************************************
               m.cSection  = '2'
               m.nOwnerPct = m.nintclass2
               INSERT INTO settlement FROM MEMVAR
            ENDIF


            * Restore the interest in case we changed it for one man item processing
            m.nintclass2 = lnSaveInterest

            STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo
         ENDSCAN  && Exptemp
      ENDIF

      IF THIS.oinvtmp.ntotale3 # 0
         SELECT exptemp
         IF THIS.lSumExp
            lcScan = 'cwellid = THIS.oInvTmp.cwellid AND ' + ;
               "cexpclass = '3' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ELSE
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               '(cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
               "cexpclass = '3' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ENDIF
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            llReturn = .T.
            REPL lused WITH .T.

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = THIS.oinvtmp.nintclass3
            m.nintclass3   = THIS.oinvtmp.nintclass3

            IF m.nintclass3 # 0
               REPL lused WITH .T.
            ENDIF

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W'
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  m.nintclass3 = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  m.nintclass3 = THIS.oinvtmp.nintclass3
                  IF THIS.oinvtmp.nintclass3 = 0
                     LOOP
                  ENDIF
            ENDCASE

            SELE exptemp
            REPL lused WITH .T.

            m.cCategory  = m.ccateg
            m.creference = m.crefid

            * Calculate the owner's share of the expense
            m.nOwnerAmt   = SWROUND((m.nAmount * (m.nintclass3 / 100)), 2)
            IF m.goApp.lParentCompany
               m.nPartnerShipPct = THIS.NonDummyPct(exptemp.cwellid, 'E')
               m.nPartnerShipAmt = swNetExp(m.nAmount, exptemp.cwellid, .T., exptemp.cExpClass, 'N', .F., exptemp.cownerid, exptemp.ccatcode)
               m.nGrossAmt       = exptemp.nAmount
            ELSE
               m.nPartnerShipAmt = m.nAmount
               m.nGrossAmt       = m.ngrossval
            ENDIF
            m.cprogcode   = THIS.oinvtmp.cprogcode

            IF m.nOwnerAmt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Section 2
               *********************************************************************************************************
               m.cSection  = '2'
               m.nOwnerPct = m.nintclass3
               INSERT INTO settlement FROM MEMVAR
            ENDIF

            * Restore the interest in case we changed it for one man item processing
            m.nintclass3 = lnSaveInterest

            STORE 0 TO m.ninvamt, m.nAmount
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo
         ENDSCAN  && Exptemp
      ENDIF

      IF THIS.oinvtmp.ntotale4 # 0
         SELECT exptemp
         IF THIS.lSumExp
            lcScan = 'cwellid = THIS.oInvTmp.cwellid AND ' + ;
               "cexpclass = '4' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ELSE
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               '(cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
               "cexpclass = '4' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ENDIF
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            llReturn = .T.
            REPL lused WITH .T.

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = THIS.oinvtmp.nintclass4
            m.nintclass4   = THIS.oinvtmp.nintclass4

            IF m.nintclass4 # 0
               REPL lused WITH .T.
            ENDIF

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W'
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  m.nintclass4 = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  m.nintclass4 = THIS.oinvtmp.nintclass4
                  IF THIS.oinvtmp.nintclass4 = 0
                     LOOP
                  ENDIF
            ENDCASE

            SELE exptemp
            REPL lused WITH .T.

            m.cCategory  = m.ccateg
            m.creference = m.crefid

            * Calculate the owner's share of the expense
            m.nOwnerAmt       = SWROUND((m.nAmount * (m.nintclass4 / 100)), 2)
            IF m.goApp.lParentCompany
               m.nPartnerShipPct = THIS.NonDummyPct(exptemp.cwellid, 'E')
               m.nPartnerShipAmt = swNetExp(m.nAmount, exptemp.cwellid, .T., exptemp.cExpClass, 'N', .F., exptemp.cownerid, exptemp.ccatcode)
               m.nGrossAmt       = exptemp.nAmount
            ELSE
               m.nPartnerShipAmt = m.nAmount
               m.nGrossAmt       = m.ngrossval
            ENDIF
            m.cSection  = '2'
            m.cownerid  = THIS.cownerid
            m.cprogcode = THIS.oinvtmp.cprogcode

            IF m.nOwnerAmt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group D
               *********************************************************************************************************
               m.cSection  = '2'
               m.nOwnerPct = m.nintclass4
               INSERT INTO settlement FROM MEMVAR
            ENDIF

            * Restore the interest in case we changed it for one man item processing
            m.nintclass4 = lnSaveInterest

            STORE 0 TO m.ninvamt, m.nAmount
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo
         ENDSCAN  && Exptemp
      ENDIF

      IF THIS.oinvtmp.ntotale5 # 0
         SELECT exptemp
         IF THIS.lSumExp
            lcScan = 'cwellid = THIS.oInvTmp.cwellid   AND ' + ;
               "cexpclass = '5' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ELSE
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               '(cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
               "cexpclass = '5' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH')  "
         ENDIF
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            llReturn = .T.
            REPL lused WITH .T.

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = THIS.oinvtmp.nintclass5
            m.nintclass5   = THIS.oinvtmp.nintclass5

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W'
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  m.nintclass5 = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  m.nintclass5 = THIS.oinvtmp.nintclass5
                  IF THIS.oinvtmp.nintclass5 = 0
                     LOOP
                  ENDIF
            ENDCASE

            SELE exptemp
            REPL lused WITH .T.

            m.cCategory  = m.ccateg
            m.creference = m.crefid

            * Calculate the owner's share of the expense
            m.nOwnerAmt   = SWROUND((m.nAmount * (m.nintclass5 / 100)), 2)
            IF m.goApp.lParentCompany
               m.nPartnerShipPct = THIS.NonDummyPct(exptemp.cwellid, 'E')
               m.nPartnerShipAmt = swNetExp(m.nAmount, exptemp.cwellid, .T., exptemp.cExpClass, 'N', .F., exptemp.cownerid, exptemp.ccatcode)
               m.nGrossAmt       = exptemp.nAmount
            ELSE
               m.nPartnerShipAmt = m.nAmount
               m.nGrossAmt       = m.ngrossval
            ENDIF
            m.cownerid  = THIS.cownerid
            m.cprogcode = THIS.oinvtmp.cprogcode

            IF m.nOwnerAmt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group D
               *********************************************************************************************************
               m.cSection  = '2'
               m.nOwnerPct = m.nintclass5
               INSERT INTO settlement FROM MEMVAR
            ENDIF

            * Restore the interest in case we changed it for one man item processing
            m.nintclass5 = lnSaveInterest

            STORE 0 TO m.ninvamt, m.nAmount
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo
         ENDSCAN  && Exptemp
      ENDIF

      IF THIS.oinvtmp.nTotaleA # 0
         SELECT exptemp
         IF THIS.lSumExp
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               "cexpclass = 'A' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ELSE
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               '(cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
               "cexpclass = 'A' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ENDIF
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            llReturn = .T.
            REPL lused WITH .T.

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = THIS.oinvtmp.nacpint
            m.nacpint      = THIS.oinvtmp.nacpint

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W'
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  m.nacpint = 100
                  m.nacpint = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  m.nacpint = THIS.oinvtmp.nacpint
                  IF THIS.oinvtmp.nacpint = 0
                     LOOP
                  ENDIF
            ENDCASE

            SELE exptemp
            REPL lused WITH .T.

            m.cCategory  = m.ccateg
            m.creference = m.crefid

            * Calculate the owner's share of the expense
            m.nOwnerAmt   = SWROUND((m.nAmount * (m.nacpint / 100)), 2)
            IF m.goApp.lParentCompany
               m.nPartnerShipPct = THIS.NonDummyPct(exptemp.cwellid, 'E')
               m.nPartnerShipAmt = swNetExp(m.nAmount, exptemp.cwellid, .T., exptemp.cExpClass, 'N', .F., exptemp.cownerid, exptemp.ccatcode)
               m.nGrossAmt       = exptemp.nAmount
            ELSE
               m.nPartnerShipAmt = m.nAmount
               m.nGrossAmt       = m.ngrossval
            ENDIF
            m.cSection  = '2'
            m.cownerid  = THIS.cownerid
            m.cprogcode = THIS.oinvtmp.cprogcode

            IF m.nOwnerAmt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group D
               *********************************************************************************************************
               m.cSection  = '2'
               m.nOwnerPct = m.nacpint
               INSERT INTO settlement FROM MEMVAR
            ENDIF

            * Restore the interest in case we changed it for one man item processing
            m.nacpint = lnSaveInterest

            STORE 0 TO m.ninvamt, m.nAmount
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo
         ENDSCAN  && Exptemp
      ENDIF

      IF THIS.oinvtmp.nTotaleB # 0
         SELECT exptemp
         IF THIS.lSumExp
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               "cexpclass = 'B' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ELSE
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               '(cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
               "cexpclass = 'B' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ENDIF
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            llReturn = .T.
            REPL lused WITH .T.

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = THIS.oinvtmp.nbcpint
            m.nbcpint      = THIS.oinvtmp.nbcpint

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W'
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  m.nbcpint = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  m.nbcpint = THIS.oinvtmp.nbcpint
                  IF THIS.oinvtmp.nbcpint = 0
                     LOOP
                  ENDIF
            ENDCASE

            SELE exptemp
            REPL lused WITH .T.

            m.cCategory  = m.ccateg
            m.creference = m.crefid

            * Calculate the owner's share of the expense
            m.nOwnerAmt   = SWROUND((m.nAmount * (m.nbcpint / 100)), 2)
            IF m.goApp.lParentCompany
               m.nPartnerShipPct = THIS.NonDummyPct(exptemp.cwellid, 'E')
               m.nPartnerShipAmt = swNetExp(m.nAmount, exptemp.cwellid, .T., exptemp.cExpClass, 'N', .F., exptemp.cownerid, exptemp.ccatcode)
               m.nGrossAmt       = exptemp.nAmount
            ELSE
               m.nPartnerShipAmt = m.nAmount
               m.nGrossAmt       = m.ngrossval
            ENDIF
            m.cSection  = '2'
            m.cownerid  = THIS.cownerid
            m.cprogcode = THIS.oinvtmp.cprogcode

            IF m.nOwnerAmt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group D
               *********************************************************************************************************
               m.cSection  = '2'
               m.nOwnerPct = m.nbcpint
               INSERT INTO settlement FROM MEMVAR
            ENDIF

            * Restore the interest in case we changed it for one man item processing
            m.nbcpint = lnSaveInterest

            STORE 0 TO m.ninvamt, m.nAmount
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo
         ENDSCAN  && Exptemp
      ENDIF

      IF THIS.oinvtmp.nPlugExp # 0
         SELECT exptemp
         IF THIS.lSumExp
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               "cexpclass = 'P' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ELSE
            lcScan = 'cwellid = THIS.oInvTmp.cwellid  AND ' + ;
               '(cyear+cperiod = THIS.oInvTmp.hYear+THIS.oInvTmp.hperiod) AND ' + ;
               "cexpclass = 'P' AND NOT INLIST(expense.cCatCode,'MKTG','COMP','GATH') "
         ENDIF
         SCAN FOR &lcScan
            IF THIS.oinvtmp.ljib
               EXIT
            ENDIF

            SCATTER MEMVAR

            llReturn = .T.
            REPL lused WITH .T.

            * Save the interest in case we have to change it for a one man item
            lnSaveInterest = THIS.oinvtmp.nPlugPct
            m.nPlugPct     = THIS.oinvtmp.nPlugPct

            DO CASE
               CASE m.cownerid = THIS.cownerid AND NOT m.loneman
                  * Check to see if the owner has multiple interests in the well
                  * If so, allocate it to the working interest owner.
                  IF m.cTypeInv # 'W'
                     swSelect('wellinv')
                     LOCATE FOR cownerid == THIS.cownerid AND cwellid == m.cwellid AND cTypeInv = 'W'
                     IF FOUND()
                        LOOP
                     ENDIF
                  ENDIF
                  SELECT exptemp
                  REPLACE loneman WITH .T.
                  m.nbcpint = 100
               CASE EMPTY(m.cownerid) OR m.cownerid = SPACE(10)
                  * Don't do anything if the cOwnerID is blank
               CASE m.cownerid # THIS.cownerid
                  m.cownerid = THIS.cownerid
                  LOOP
               CASE m.cownerid = THIS.cownerid AND loneman
                  LOOP
               OTHERWISE
                  m.nbcpint = THIS.oinvtmp.nPlugPct
                  IF THIS.oinvtmp.nbcpint = 0
                     LOOP
                  ENDIF
            ENDCASE

            SELE exptemp
            REPL lused WITH .T.

            m.cCategory  = m.ccateg
            m.creference = m.crefid

            * Calculate the owner's share of the expense
            m.nOwnerAmt   = SWROUND((m.nAmount * (m.nPlugPct / 100)), 2)
            IF m.goApp.lParentCompany
               m.nPartnerShipPct = THIS.NonDummyPct(exptemp.cwellid, 'E')
               m.nPartnerShipAmt = swNetExp(m.nAmount, exptemp.cwellid, .T., exptemp.cExpClass, 'N', .F., exptemp.cownerid, exptemp.ccatcode)
               m.nGrossAmt       = exptemp.nAmount
            ELSE
               m.nPartnerShipAmt = m.nAmount
               m.nGrossAmt       = m.ngrossval
            ENDIF
            m.cSection  = '2'
            m.cownerid  = THIS.cownerid
            m.cprogcode = THIS.oinvtmp.cprogcode

            IF m.nOwnerAmt # 0
               *********************************************************************************************************
               *  Insert into the statement file  - Report Group D
               *********************************************************************************************************
               m.cSection  = '2'
               m.nOwnerPct = m.nPlugPct
               INSERT INTO settlement FROM MEMVAR
            ENDIF

            * Restore the interest in case we changed it for one man item processing
            m.nPlugPct = lnSaveInterest

            STORE 0 TO m.ninvamt, m.nAmount
            STORE ' ' TO m.cpayee, m.cCategory, m.cDescript, m.cMiscMemo
         ENDSCAN  && Exptemp
      ENDIF


      RETURN (llReturn)
   ENDPROC


   ***********************************************************************
   PROCEDURE flatowner
      ***********************************************************************
      LPARAMETERS tlSuspense, tcRunYear, tnRunNo
      *
      * Get the flat rates that should be charged agains the current owner
      *

      * If the invtmp record is from suspense we need to make sure that we
      * only get on flat rate per run in suspense.
      IF tlSuspense
         IF NOT USED('flatrates')
            * Create cursor to keep track of what we've processed
            CREATE CURSOR flatrates ;
               (crunyear   C(4), ;
                 nRunNo     I, ;
                 cwellid   C(10), ;
                 cownerid  C(10))
            m.crunyear = tcRunYear
            m.nRunNo   = tnRunNo
            m.cownerid = THIS.cownerid
            m.cwellid  = THIS.cwellid
            INSERT INTO flatrates FROM MEMVAR
         ELSE
            * Check to see if this run has been processed for a flat rate yet
            SELECT flatrates
            LOCATE FOR cownerid == THIS.cownerid AND crunyear == tcRunYear AND nRunNo == tnRunNo AND cwellid = THIS.cwellid
            IF FOUND()
               RETURN
            ELSE
               m.hyear    = THIS.oinvtmp.hyear
               m.hperiod  = THIS.oinvtmp.hperiod
               m.nRunNo   = tnRunNo
               m.crunyear = tcRunYear
               INSERT INTO flatrates FROM MEMVAR
            ENDIF
         ENDIF
      ENDIF

      * Only allocate flat rates once (This is non suspense processing)
      IF NOT tlSuspense AND THIS.lflatalloc = .T.
         RETURN
      ENDIF

      *
      *  Get flat-rate Royalty nAmounts for current well
      *
      STORE 0 TO jnflatgas, jnflatoil

      *  If the run is closed, get the flat rates from well history
      IF NOT THIS.lNewRun
         swSelect('wellhist')
         LOCATE FOR cwellid = THIS.cwellid AND nRunNo = tnRunNo AND crunyear = tcRunYear ;
            AND hyear + hperiod = THIS.oinvtmp.hyear + THIS.oinvtmp.hperiod
         IF FOUND()
            jnflatgas = nflatgas
            jnflatoil = nflatoil
         ENDIF
      ELSE
         * The run isn't closed so get the flat rates from wellinv
         jnflatgas = THIS.odist.getflatamt(THIS.cwellid, 'G')
         jnflatoil = THIS.odist.getflatamt(THIS.cwellid, 'O')
      ENDIF

      *************************************************************
      *  Process flat-rate royalties
      *************************************************************
      IF jnflatgas # 0 AND NOT THIS.lroyaltyowner
         m.cTYPE           = 'FLT'
         m.csource         = 'Gas Royalties'
         m.nPartnerShipAmt = jnflatgas * -1
         m.nRevInt         = invtmp.nworkint
         jwrk              = jnflatgas * (invtmp.nworkint / 100)
         m.nOwnerAmt       = jwrk * -1
         m.nincome         = m.ninvamt
         m.cyear           = THIS.oinvtmp.hyear
         m.cperiod         = THIS.oinvtmp.hperiod
         m.cdirect         = THIS.oinvtmp.cdirect
         m.crptgroup       = 'B'
         m.cownerid        = THIS.oinvtmp.cownerid
         m.nRunNo          = THIS.nRunNo
         m.crunyear        = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group B
         *********************************************************************************************************
         IF m.nOwnerAmt # 0
            INSERT INTO settlement FROM MEMVAR
         ENDIF

         m.cDescript   = ' '
         THIS.ntotinc  = THIS.ntotinc + m.ninvamt
         THIS.nwelltot = THIS.nwelltot + m.ninvamt
      ENDIF

      IF jnflatoil # 0 AND NOT THIS.lroyaltyowner
         m.cTYPE           = 'FLT'
         m.csource         = 'Oil Royalties'
         m.nPartnerShipAmt = jnflatoil * -1
         m.nRevInt         = invtmp.nworkint
         jwrk              = jnflatoil * (invtmp.nworkint / 100)
         m.nOwnerAmt       = jwrk * -1
         m.cdirect         = THIS.oinvtmp.cdirect
         m.crptgroup       = 'B'
         m.cownerid        = THIS.oinvtmp.cownerid
         m.nRunNo          = THIS.nRunNo
         m.crunyear        = THIS.crunyear
         *********************************************************************************************************
         *  Insert into the statement file  - Report Group B
         *********************************************************************************************************
         IF m.nOwnerAmt # 0
            INSERT INTO settlement FROM MEMVAR
         ENDIF
         m.cDescript   = ' '
         THIS.ntotinc  = THIS.ntotinc + m.ninvamt
         THIS.nwelltot = THIS.nwelltot + m.ninvamt
      ENDIF

      THIS.lflatalloc = .T.
   ENDPROC

   ***********************************************************************
   PROCEDURE getrange
      ***********************************************************************
      *========================================================================================
      *  Program....: GETRANGE.PRG
      *  Version....: 2.5
      *  Author.....: Phil W. Sherwood
      *  Date.......: February 13, 1994
      *  Notice.....: Copyright (c) 1996 SherWare, Inc., All Rights Reserved.
      *  Compiler...: FoxPro 2.6a
      *) Description: Retrieves well period range information from prdrange file.
      *  Parameters.:
      *  Changes....:
      *    03/31/96   pws - Changed to update the prdrange file instead of the well file.
      *    02/14/97   pws - Changed the way the range is calculated.  Calculate the range by
      *                     looking at last periods range and adding 1 to the end.
      *    12/08/98   pws - Changed for new wellrng file.
      *========================================================================================
      LPARA tcPeriod, tcYear, tcType, tcWellId
      LOCAL ldDate1, lcDate1, lcDate2, lcYear, lcRange1, lcRange2, llCalcRange
      LOCAL m.cRange1, m.cRange2

      ldDate1   = tcPeriod + '/01/' + tcYear
      m.cRange1 = LEFT(ldDate1, 5)
      ldDate1   = GOMONTH(CTOD(ldDate1), 1) - 1
      lcDate1   = DTOC(ldDate1)
      m.cRange2 = LEFT(lcDate1, 5)

      IF TYPE('tcYear') = 'C'
         lcYear = tcYear
      ELSE
         lcYear = STR(YEAR(DATE()), 4)
      ENDIF

      IF tcPeriod = '01'
         lcPrd = '12'
         lcYr  = STR(VAL(tcYear) - 1, 4)
      ELSE
         lcPrd = PADL(ALLTRIM(STR(VAL(tcPeriod) - 1, 2)), 2, '0')
         lcYr  = tcYear
      ENDIF

      swSelect('options')
      GO TOP
      llCalcRange = lCalcRange

      SELECT wellrng
      SET ORDER TO wellprd
      IF SEEK (tcWellId + tcYear + tcPeriod)
         DO CASE
            CASE tcType = 'O'
               m.cRange1 = oprng1
               m.cRange2 = oprng2
            CASE tcType = 'G'
               m.cRange1 = gprng1
               m.cRange2 = gprng2
         ENDCASE
      ELSE
         DO CASE
            CASE tcType = 'O'
               IF llCalcRange
                  IF SEEK(tcWellId + lcYr + lcPrd)
                     ldDate1   = CTOD(cRange2 + '/' + lcYr)
                     lcDate1   = DTOC(ldDate1 + 1)
                     lcDate2   = DTOC(ldDate1 + 31)
                     lcRange1  = LEFT(lcDate1, 5)
                     lcRange2  = LEFT(lcDate2, 5)
                     m.cRange1 = lcRange1
                     m.cRange2 = lcRange2
                  ENDIF
               ENDIF
            CASE tcType = 'G'
               IF llCalcRange
                  IF SEEK(tcWellId + lcYr + lcPrd)
                     ldDate1   = CTOD(cRange2 + '/' + lcYr)
                     lcDate1   = DTOC(ldDate1 + 1)
                     lcDate2   = DTOC(ldDate1 + 31)
                     lcRange1  = LEFT(lcDate1, 5)
                     lcRange2  = LEFT(lcDate2, 5)
                     m.cRange1 = lcRange1
                     m.cRange2 = lcRange2
                  ENDIF
               ENDIF
         ENDCASE
      ENDIF

      RETURN (m.cRange1 + m.cRange2)
   ENDPROC

   ***********************************************************************
   PROCEDURE susprelbal
      ***********************************************************************
      * Show released suspense balance

      RETURN .T.
      m.nWellNet   = 0
      lnSuspRelamt = 0
      *
      *  Look for any program deficits that are being covered.
      *
      llCheckAmt = .F.
      SELECT statemnt
      SCAN FOR cownerid == THIS.cownerid
         IF 'Check Amount' $ cbalancedesc
            llCheckAmt = .T.
         ENDIF
      ENDSCAN
      IF llCheckAmt
         USE DBF('invtmp') AGAIN IN 0 ALIAS tmpsusp
         SELECT tmpsusp
         SET ORDER TO 0
         SCAN FOR cownerid = THIS.cownerid ;
               AND nnetcheck # 0 ;
               AND NOT EMPTY(cSuspType)
            lnSuspRelamt  = lnSuspRelamt + nnetcheck
         ENDSCAN     && tmpsusp
         IF lnSuspRelamt # 0
            m.crptgroup = 'N'
            m.cSuspType = ''
            m.cTYPE     = 'BAL'
            m.nTotNet   = lnSuspRelamt
            m.cperiod   = ''
            m.cyear     = THIS.cyear
            m.cprogcode = 'ZZZZ'
            m.cWellType = '}ZZZZZZZZZZ'
            m.cDescript = 'Balance Brought Forward From Previous Periods That Was In Suspense'
            m.nRunNo    = THIS.nRunNo
            m.crunyear  = THIS.crunyear
            m.nWellNet  = 0
            m.cDescript = ' '
         ENDIF
         SELECT tmpsusp
         USE
      ENDIF
   ENDPROC

   ***********************************************************************
   PROCEDURE NetWellTotalNoSplit
      ***********************************************************************
      ************************************************************************************
      **** PROCESSING FOR COMBINING PRODUCTION PERIOD TOGETHER UNDER ONE WELL HEADER *****
      ************************************************************************************
      IF TYPE('this.oinvtmp') # 'O'
         RETURN
      ENDIF

      m.nWellNet = 0

      IF NOT THIS.lsplitperiods
         IF THIS.ownergroup # invtmp.cownerid + invtmp.cwellid + invtmp.cTypeInv  AND THIS.ownergroup # ' '
            *  Report Rounding for this owner, if any
            *  Moved to always do rounding, even if the total for the well is zero. In instances
            *  where the well comes out to zero, but there was actually activity, it doesn't allow
            *  any rounding to be reported, which makes the statement not total the check amount.
            THIS.Rounding()
            * If the well total is zero, make sure the activity is zero so wells without production can be reported
            IF THIS.nwelltot = 0
               IF THIS.oinvtmp.nincome = 0 AND ;
                     (THIS.oinvtmp.nexpense + THIS.oinvtmp.ntotale1 + ;
                       THIS.oinvtmp.ntotale2 + THIS.oinvtmp.ntotale3 + ;
                       THIS.oinvtmp.ntotale4 + THIS.oinvtmp.ntotale5 + ;
                       THIS.oinvtmp.nTotaleA + THIS.oinvtmp.nTotaleB) = 0 AND ;
                     THIS.oinvtmp.nsevtaxes = 0 AND THIS.oinvtmp.nnetcheck = 0
                  SELECT invtmp
                  IF NOT BOF() AND NOT EOF()
                     lnrecNo = RECNO()
                     LOCATE FOR cownerid = THIS.oinvtmp.cownerid ;
                        AND cwellid = THIS.oinvtmp.cwellid ;
                        AND ;
                        (nincome # 0 OR nexpense # 0 OR ;
                          ntotale1 # 0 OR ntotale2 # 0 OR ;
                          ntotale3 # 0 OR ntotale4 # 0 OR ;
                          ntotale5 # 0 OR nTotaleA # 0 OR ;
                          nTotaleB # 0 OR nPlugExp # 0 OR ;
                          nsevtaxes # 0 OR nnetcheck # 0)
                     IF NOT FOUND()
                        m.cDescript = 'No Production this Run'
                        STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL, lnwelldef
                        m.cownerid = THIS.cownerid
                        m.nWellNet = 0
                        m.nRunNo   = THIS.nRunNo
                        IF NOT EMPTY(THIS.oinvtmp.cprogcode)
                           m.nprogtot  = 0
                           m.cprogcode = THIS.oinvtmp.cprogcode
                           m.cownerid  = THIS.oinvtmp.cownerid
                           SELECT progtots
                           LOCATE FOR cownerid == m.cownerid AND cprogcode == m.cprogcode
                           IF NOT FOUND()
                              INSERT INTO progtots FROM MEMVAR
                           ENDIF
                        ENDIF
                     ELSE
                        m.nWellNet  = THIS.nwelltot
                        IF (THIS.oinvtmp.lFlat AND m.nWellNet # 0) OR NOT THIS.oinvtmp.lFlat
                           DO CASE
                              CASE THIS.oinvtmp.cTypeInv = 'L'     && Royalty Owner
                                 m.cDescript = 'Your Royalty Interest This ' + lcWellProg
                                 STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                              CASE THIS.oinvtmp.cTypeInv = 'O'     && Overriding Royalty Owner
                                 m.cDescript = 'Your Overriding Royalty Interest This ' + lcWellProg
                                 STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                              CASE THIS.oinvtmp.cTypeInv = 'W'     && Working Interest
                                 m.cDescript = 'Your Working Interest This ' + lcWellProg
                                 STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                              OTHERWISE
                                 m.cDescript = ' '
                           ENDCASE
                        ELSE
                           SELECT invtmp
                           GOTO lnrecNo
                           RETURN
                        ENDIF
                     ENDIF
                     SELECT invtmp
                     GOTO lnrecNo
                  ELSE
                     SELECT curlastsusptype
                     LOCATE FOR cwellid = THIS.oinvtmp.cwellid ;
                        AND cownerid = THIS.oinvtmp.cownerid ;
                        AND cTypeInv = THIS.oinvtmp.cTypeInv
                     IF FOUND()
                        lcCurStatus = cSuspType
                        lnBalance   = THIS.osuspense.Owner_Balances(THIS.cownerid, THIS.cGROUP, .F., .T., .T., .T., .T.)
                        IF VARTYPE(lnBalance) # 'N'
                           llReturn  = .F.
                           lnBalance = 0
                           EXIT
                        ENDIF
                        IF lnBalance = 0
                           lcCurStatus = '*'
                        ENDIF
                     ELSE
                        lcCurStatus = '*'
                     ENDIF

                     * If this runno_in = runno this means that the amount was cleared from suspense
                     * It shouldn't show as not being in suspense for this run on the statement
                     IF THIS.oinvtmp.nRunNo_In = THIS.oinvtmp.nRunNo AND ;
                           THIS.oinvtmp.cRunYear_In = THIS.oinvtmp.crunyear
                        lcCurStatus = THIS.oinvtmp.cSuspType
                     ENDIF

                     m.nWellNet = THIS.nwelltot

                     DO CASE
                        CASE THIS.oinvtmp.cTypeInv = 'L'     && Royalty Owner
                           m.cDescript = 'Your Royalty Interest This ' + lcWellProg
                           STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                        CASE THIS.oinvtmp.cTypeInv = 'O'     && Overriding Royalty Owner
                           m.cDescript = 'Your Overriding Royalty Interest This ' + lcWellProg
                           STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                        CASE THIS.oinvtmp.cTypeInv = 'W'     && Working Interest
                           m.cDescript = 'Your Working Interest This ' + lcWellProg
                           STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                        OTHERWISE
                           m.cDescript = ' '
                     ENDCASE
                     DO CASE
                        CASE lcCurStatus = 'D'
                           IF THIS.ooptions.lstminv
                              m.cDescript = m.cDescript + '-(Amount Added To Previous Suspense Balance)'
                           ELSE
                              m.cDescript = m.cDescript + '-(Deficit Held In Suspense)'
                           ENDIF
                        CASE lcCurStatus = 'M'
                           m.cDescript = m.cDescript + '-(Minimum Held In Suspense)'
                        CASE lcCurStatus = 'H'
                           m.cDescript = m.cDescript + '-(Owner Held In Suspense)'
                        CASE lcCurStatus = 'I'
                           m.cDescript = m.cDescript + '-(Interest Held In Suspense)'
                        CASE lcCurStatus = 'Q'
                           m.cDescript = m.cDescript + '-(Quarterly Pay Held Until End Of Quarter)'
                        CASE lcCurStatus = 'S'
                           m.cDescript = m.cDescript + '-(Semi-Annual Pay Held)'
                        CASE lcCurStatus = 'A'
                           m.cDescript = m.cDescript + '-(Annual Pay Held Until End Of Year)'
                     ENDCASE

                  ENDIF
                  m.crptgroup = 'E'
                  m.cownerid  = THIS.cownerid
                  m.cwellid   = THIS.oinvtmp.cwellid
                  m.cSuspType = ''
                  m.crunyear  = THIS.crunyear
                  SELECT statemnt
                  LOCATE FOR cownerid = THIS.oinvtmp.cownerid AND cwellid = THIS.oinvtmp.cwellid AND cWellType = m.cWellType AND (crptgroup = 'B' OR crptgroup = 'D')
                  IF NOT FOUND()
                     RETURN
                  ENDIF
               ENDIF
            ELSE
               m.crptgroup = 'E'
               m.cSuspType = ''
               m.nWellNet  = THIS.nwelltot

               *  This is a kludge.  If an owner has a piddly interest and a ton of amounts that round to zero, it can
               *  sometimes come out with a penny difference between the well total and the overall total (when they
               *  only have an interest in one well).  This makes it match.  No idea how they come out different, because
               *  anytime nWellNet is being set, there have been swrounds done on the numbers that make it up, so there
               *  should be no partial penny stuff going on to cause the difference.  If someone else feels like taking
               *  the time to step through a few hundred entries to find out where it's happening, feel free.
               *  But as for me and my house, we will kludge. - BH 07/20/12
               *!*               IF ABS(m.nWellNet-m.nTotalCheck) <= .03
               *!*                  m.nWellNet = m.nTotalCheck
               *!*               ENDIF

               lnwelldef  = m.nWellNet
               m.cTYPE    = 'NET'
               llnewowner = .F.
               m.cownerid = THIS.cownerid
               m.cwellid  = THIS.oinvtmp.cwellid

               * Determine what type of interest is being reported
               DO CASE
                  CASE THIS.oinvtmp.cTypeInv = 'L'     && Royalty Owner
                     m.cDescript = 'Your Royalty Interest This ' + lcWellProg
                     STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                  CASE THIS.oinvtmp.cTypeInv = 'O'     && Overriding Royalty Owner
                     m.cDescript = 'Your Overriding Royalty Interest This ' + lcWellProg
                     STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                  CASE THIS.oinvtmp.cTypeInv = 'W'     && Working Interest
                     m.cDescript = 'Your Working Interest This ' + lcWellProg
                     STORE .F. TO THIS.lbelowminimum, THIS.linterestheld, THIS.lfreqheld
                  OTHERWISE
                     m.cDescript = ' '
               ENDCASE

               * Get the type of suspense for this well so it can be reported correctly
               SELECT curlastsusptype
               LOCATE FOR cwellid = THIS.oinvtmp.cwellid AND cownerid = THIS.oinvtmp.cownerid AND cTypeInv = THIS.oinvtmp.cTypeInv
               IF FOUND()
                  lcCurStatus = cSuspType
               ELSE
                  lcCurStatus = '*'
               ENDIF

               * If this runno_in = runno this means that the amount was cleared from suspense
               * It shouldn't show as not being in suspense for this run on the statement
               IF THIS.oinvtmp.nRunNo_In = THIS.oinvtmp.nRunNo AND ;
                     THIS.oinvtmp.cRunYear_In = THIS.oinvtmp.crunyear
                  lcCurStatus = THIS.oinvtmp.cSuspType
               ENDIF

               * Add the suspense description to the total line
               DO CASE
                  CASE lcCurStatus = 'D'
                     IF THIS.ooptions.lstminv
                        m.cDescript = m.cDescript + '-(Amount Added To Previous Suspense Balance)'
                     ELSE
                        m.cDescript = m.cDescript + '-(Deficit Held In Suspense)'
                     ENDIF
                  CASE lcCurStatus = 'M'
                     m.cDescript = m.cDescript + '-(Minimum Held In Suspense)'
                  CASE lcCurStatus = 'H'
                     m.cDescript = m.cDescript + '-(Owner Held In Suspense)'
                  CASE lcCurStatus = 'I'
                     m.cDescript = m.cDescript + '-(Interest Held In Suspense)'
                  CASE lcCurStatus = 'Q'
                     m.cDescript = m.cDescript + '-(Quarterly Pay Held Until End Of Quarter)'
                  CASE lcCurStatus = 'S'
                     m.cDescript = m.cDescript + '-(Semi-Annual Pay Held)'
                  CASE lcCurStatus = 'A'
                     m.cDescript = m.cDescript + '-(Annual Pay Held Until End Of Year)'
               ENDCASE

               STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL, lnwelldef
               m.cownerid = THIS.cownerid
               m.nRunNo   = THIS.nRunNo
               m.crunyear = THIS.crunyear
               SELECT statemnt
               LOCATE FOR cownerid = THIS.oinvtmp.cownerid ;
                  AND cwellid = THIS.oinvtmp.cwellid ;
                  AND cWellType = m.cWellType ;
                  AND (crptgroup = 'B' OR crptgroup = 'D')
               IF NOT FOUND()
                  RETURN
               ENDIF

               *  At this point, m.cProgCode still has the last program code stored
               *  Add to that programs totals
               IF NOT EMPTY(ALLT(THIS.cprogcode)) AND THIS.oinvtmp.cSuspType # 'I'
                  SELE progtots
                  LOCATE FOR cownerid + cprogcode == THIS.oinvtmp.cownerid + THIS.oinvtmp.cprogcode
                  IF FOUND()
                     IF THIS.lnetwells
                        REPL nprogtot WITH nprogtot + m.nWellNet
                     ELSE
                        IF m.nWellNet > 0
                           REPL nprogtot WITH nprogtot + m.nWellNet
                        ENDIF
                     ENDIF
                  ELSE
                     m.nprogtot  = m.nWellNet
                     m.cprogcode = THIS.oinvtmp.cprogcode
                     m.cownerid  = THIS.oinvtmp.cownerid
                     IF THIS.lnetwells
                        INSERT INTO progtots FROM MEMVAR
                     ELSE
                        * Not netting wells so don't show a program total unless
                        * the total is positive
                        IF m.nWellNet > 0
                           INSERT INTO progtots FROM MEMVAR
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF
            m.cDescript = ' '
            *      IF m.nwellnet > 0 OR (m.nwellnet < 0 AND THIS.oInvTmp.lused) OR (m.ntotalcheck < 0)
            THIS.nownertotal = THIS.nownertotal + ROUND(m.nWellNet, 2)
            *      ENDIF
            STORE 0 TO THIS.nwelltot, THIS.ntotinc, m.nWellNet, m.nTOTAL
         ENDIF

      ENDIF
      ************************************************************************************
      **** PROCESSING FOR COMBINING PRODUCTION PERIOD TOGETHER UNDER ONE WELL HEADER *****
      ************************************************************************************
   ENDPROC

   ***********************************************************************
   PROCEDURE NetWellTotalSplit
      ***********************************************************************
      LOCAL llNetSusp

      swSelect('groups')
      LOCATE FOR cGROUP = THIS.cGROUP
      IF FOUND()
         llNetSusp = lNetDef
      ELSE
         llNetSusp = .T.
      ENDIF

      *
      * Determines which message to print for the net total
      *
      IF THIS.lsplitperiods
         m.nworkint  = THIS.oinvtmp.nworkint
         m.crptgroup = 'E'
         m.cSuspType = ''
         m.nWellNet  = THIS.nwelltot
         m.cTYPE     = 'NET'
         m.cownerid  = THIS.cownerid

         DO CASE
            CASE THIS.oinvtmp.cTypeInv = 'L'
               lcOwnType = 'Your Royalty'
            CASE THIS.oinvtmp.cTypeInv = 'O'
               lcOwnType = 'You Overriding Royalty'
            CASE THIS.oinvtmp.cTypeInv = 'W'
               lcOwnType = 'Your Working'
            OTHERWISE
               lcOwnType = 'Your Working'
         ENDCASE


         DO CASE
               * Royalty owner, postive net
            CASE THIS.oinvtmp.cTypeInv # 'W' AND m.nWellNet >= 0
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg
               ELSE
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg + ' (**ON HOLD**)'
               ENDIF
               * Royalty owner, negative net covered by other wells this period
            CASE THIS.oinvtmp.cTypeInv # 'W' AND m.nWellNet < 0 AND THIS.oinvtmp.lused
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg
               ELSE
                  m.cDescript = lcOwnType + ' Interest This '  + lcWellProg + ' (**ON HOLD**)'
               ENDIF
               * Royalty owner, deficit
            CASE THIS.oinvtmp.cTypeInv # 'W' AND m.nWellNet < 0 AND NOT THIS.oinvtmp.lused
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg + ' (Deficit Carried Forward)'
               ELSE
                  m.cDescript = lcOwnType + ' Interest This ' + lcWellProg + ' (**ON HOLD**)'
               ENDIF
               * Working interest owner, positive net or deficit covered by other wells this period
            CASE THIS.oinvtmp.cTypeInv = 'W' AND ;
                  ((m.nWellNet > 0 OR (m.nWellNet < 0 AND THIS.oinvtmp.lused) OR ;
                      (m.nWellNet < 0 AND NOT THIS.oinvtmp.lused AND THIS.ooptions.lstminv AND llNetSusp)))
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = 'Your Working Interest This ' + lcWellProg
               ELSE
                  m.cDescript = 'Your Working Interest This ' + lcWellProg + '(**ON HOLD**)'
               ENDIF
               * Working interest owner, deficit
            CASE THIS.oinvtmp.cTypeInv = 'W' AND ;
                  (m.nWellNet < 0 AND NOT THIS.oinvtmp.lused AND (NOT THIS.ooptions.lstminv OR NOT THIS.lnetwells))
               IF NOT THIS.oinvtmp.lOnHold
                  m.cDescript = 'Your Working Interest This ' + lcWellProg + ' (Deficit Carried Forward)'
               ELSE
                  m.cDescript = 'Your Working Interest This ' + lcWellProg + ' (**ON HOLD**)'
               ENDIF
            CASE THIS.oinvtmp.cTypeInv = 'W' AND ;
                  (m.nWellNet < 0 AND NOT THIS.oinvtmp.lused AND THIS.ooptions.lstminv)
               m.cDescript = 'Your Working Interest This ' + lcWellProg + ' (Amount Added to Payment)'
               * Should never get here
            OTHERWISE
               m.cDescript = ' '
         ENDCASE
         STORE 0 TO m.ninvamt, m.nAmount, m.nTOTAL, lnwelldef
         m.cownerid = THIS.oinvtmp.cownerid
         m.nRunNo   = THIS.nRunNo
         m.crunyear = THIS.crunyear


         IF NOT EMPTY(ALLT(THIS.oinvtmp.cprogcode)) AND THIS.oinvtmp.cSuspType # 'I'
            SELE progtots
            LOCATE FOR cownerid + cprogcode == THIS.oinvtmp.cownerid + THIS.oinvtmp.cprogcode
            IF FOUND()
               IF THIS.lnetwells
                  REPL nprogtot WITH nprogtot + m.nWellNet
               ELSE
                  IF m.nWellNet > 0
                     REPL nprogtot WITH nprogtot + m.nWellNet
                  ENDIF
               ENDIF
            ELSE
               m.nprogtot = m.nWellNet
               IF THIS.lnetwells
                  INSERT INTO progtots FROM MEMVAR
               ELSE
                  IF m.nWellNet > 0
                     INSERT INTO progtots FROM MEMVAR
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
         m.cDescript = ' '
         *   IF m.nwellnet > 0 OR (m.nwellnet < 0 AND THIS.oInvTmp.lUsed) OR (m.ntotalcheck < 0)
         THIS.nownertotal = THIS.nownertotal + ROUND(m.nWellNet, 2)
         *   ENDIF
         STORE 0 TO THIS.nwelltot, THIS.ntotinc

         **************************************************************
         *  Report Rounding for this owner
         **************************************************************
         THIS.Rounding()

      ENDIF
   ENDPROC

   ***********************************************************************
   PROCEDURE pulltype
      ***********************************************************************
      tcOwner1 = THIS.cowner1
      tcOwner2 = THIS.cowner2

      * Get list of owners, wells and types from doi
      SELE cownerid, cwellid, cTypeInv ;
         FROM invtmp ;
         WHERE cownerid IN (SELECT cid FROM SELECTED) ;
         INTO CURSOR owntypes ;
         GROUP BY cownerid, cwellid, cTypeInv ;
         ORDER BY cownerid, cwellid, cTypeInv

      DO CASE
         CASE 'Royalty' $ THIS.cownertype
            *  Scan for non royalty owner records to see if they should stay or go
            *  They stay if the owner has other royalty interests being reported
            SELE invtmp
            SET ORDER TO
            SCAN FOR NOT INLIST(cTypeInv, 'L', 'O')
               lnrecNo    = RECNO()
               m.cownerid = cownerid
               m.cwellid  = cwellid
               m.cTypeInv = cTypeInv
               SELE owntypes
               LOCATE FOR cownerid = m.cownerid AND cwellid = m.cwellid
               IF FOUND()
                  IF NOT INLIST(cTypeInv, 'L', 'O')
                     SELECT owntypes
                     LOCATE FOR cownerid = m.cownerid AND INLIST(cTypeInv, 'L', 'O')
                     IF NOT FOUND()
                        SELE invtmp
                        SCAN FOR cownerid == m.cownerid
                           DELE NEXT 1
                        ENDSCAN
                        GOTO lnrecNo
                     ENDIF
                  ENDIF
               ENDIF
            ENDSCAN
         CASE 'Working' $ THIS.cownertype
            * Scan for non working interests to see if they should stay or go
            * They stay if the owner has other working interests that are being reported
            SELE invtmp
            SET ORDER TO
            SCAN FOR cTypeInv # 'W'
               lnrecNo    = RECNO()
               m.cownerid = cownerid
               m.cwellid  = cwellid
               m.cTypeInv = cTypeInv
               SELE owntypes
               LOCATE FOR cownerid = m.cownerid AND cwellid = m.cwellid
               IF FOUND()
                  IF cTypeInv # 'W'
                     SELECT owntypes
                     LOCATE FOR cownerid = m.cownerid AND cTypeInv = 'W'
                     IF NOT FOUND()
                        SELE invtmp
                        SCAN FOR cownerid == m.cownerid
                           DELE NEXT 1
                        ENDSCAN
                        GOTO lnrecNo
                     ENDIF
                  ENDIF
               ENDIF
            ENDSCAN
      ENDCASE

      *  Remove owner total records if there are no detail records
      *  to report on.
      SELE invtotal
      SCAN
         m.cownerid = cownerid
         SELE invtmp
         LOCATE FOR cownerid = m.cownerid
         IF NOT FOUND()
            SELE invtotal
            DELE NEXT 1
         ENDIF
      ENDSCAN
   ENDPROC

   ***********************************************************************
   PROCEDURE Rounding
      ***********************************************************************
      * Make sure expense tax code is not set for rounding
      STORE '' TO m.ctaxcode, m.ctaxdesc

      * Don't attempt to adjust rounding when doing statements
      * for a new run
      IF THIS.lNewRun
         RETURN
      ENDIF

      IF USED('roundsum')
         SELECT roundsum
         LOCATE FOR cownerid == THIS.oinvtmp.cownerid AND cwellid == THIS.oinvtmp.cwellid AND cDMBatch == THIS.cDMBatch AND lused = .F.
         IF FOUND()
            m.nWellNet    = nWellNet
            m.nrevenue    = nrevenue
            m.nexpenses   = nexpenses
            THIS.nwelltot = THIS.nwelltot + m.nWellNet
            * Commented out 3/18/09 by pws because it was adding the rounding to the total on each page
            *      m.nTotalBal   = m.nTotalBal + m.nWellNet
            m.crptgroup = 'E'
            m.cSuspType = ''
            m.cTYPE     = 'RND'
            m.cperiod   = ''
            m.cyear     = THIS.oinvtmp.hyear
            m.cprogcode = 'ZZZZ'
            m.cwellid   = THIS.oinvtmp.cwellid
            m.cSuspType = THIS.oinvtmp.cSuspType
            m.cownerid  = THIS.cownerid

            REPL lused WITH .T.

            swSelect('wells')
            SET ORDER TO cwellid
            IF SEEK(THIS.oinvtmp.cwellid)
               m.cwellname = cwellname
            ELSE
               m.cwellname = 'Combined Wells'
            ENDIF
            IF THIS.lsplitperiods
               m.cWellType = THIS.oinvtmp.cownerid + THIS.oinvtmp.cwellid + ;
                  THIS.oinvtmp.cTypeInv + STR(0, 1) + THIS.oinvtmp.hyear + THIS.oinvtmp.hperiod
            ELSE
               m.cWellType = THIS.oinvtmp.cownerid + THIS.oinvtmp.cwellid + ;
                  THIS.oinvtmp.cTypeInv + STR(0, 1)
            ENDIF
            m.cprogcode = THIS.oinvtmp.cprogcode
            IF NOT FILE(m.goApp.cCommonFolder + 'sumprogs.txt')
               m.cDescript = 'Rounding Adjustment For Well: ' + ALLT(THIS.oinvtmp.cwellid) + ;
                  ' --- Revenue: ' + TRANSFORM(roundsum.nrevenue) + ' Expenses: ' + TRANSFORM(roundsum.nexpenses)
            ELSE
               m.cDescript = 'Rounding Adjustment For Program: ' + ALLT(THIS.oinvtmp.cwellid)
            ENDIF
            m.cownerid = THIS.oinvtmp.cownerid
            m.nRunNo   = THIS.nRunNo
            m.crunyear = THIS.crunyear
         ENDIF
      ENDIF
   ENDPROC

   ***********************************************************************
   PROCEDURE stmtnotes
      ***********************************************************************
      LPARA tnRunNo, tcRunYear, m.cwellid, m.cownerid

      * Make sure expense tax code is not set for statement notes
      STORE '' TO m.ctaxcode, m.ctaxdesc

      m.ninvamt  = 0
      llReturn   = .F.
      m.cTypeInv = THIS.oinvtmp.cTypeInv
      swSelect('stmtnote')
      IF THIS.lNewRun
         LOCATE FOR cwellid == m.cwellid AND nRunNo = 0        && Look for notes
      ELSE
         LOCATE FOR cwellid == m.cwellid AND crunyear == tcRunYear AND nRunNo == tnRunNo        && Look for notes
      ENDIF

      IF FOUND() AND NOT EMPTY(mNotes)
         SCATTER MEMVAR MEMO
         SELE ownnotes
         LOCATE FOR cownerid = m.cownerid AND cwellid = m.cwellid
         IF NOT FOUND()
            m.cownerid  = THIS.oinvtmp.cownerid
            swSelect('wellinv')
            LOCATE FOR cownerid == m.cownerid AND cwellid == m.cwellid AND cTypeInv == m.cTypeInv
            IF FOUND()
               m.cprogcode = wellinv.cprogcode
               m.ctypeint  = wellinv.ctypeint
            ENDIF
            m.nRunNo    = THIS.nRunNo
            m.crunyear  = THIS.crunyear
            m.crptgroup = 'F'
            m.cTYPE     = 'NOT'
            m.cSuspType = ''
            m.cownerid  = THIS.oinvtmp.cownerid
            m.cWellType = m.cownerid + m.cwellid + m.cTypeInv + '0'

            IF m.cTypeInv = 'L' AND INLIST(m.nnotetype, 1, 3, 5)
               m.cDescript = '**********************************************************************' + CHR(13) + ;
                  M.mNotes + CHR(13) + ;
                  '**********************************************************************'

               STORE 0 TO m.ninvamt, m.nWellNet, m.nunits, m.nprice, m.nTOTAL, m.nworkint, m.nTotNet, m.nWorkTot
               llReturn = .T.
            ENDIF
            IF m.cTypeInv = 'O' AND INLIST(m.nnotetype, 2, 3, 5)
               m.cDescript = '**********************************************************************' + CHR(13) + ;
                  M.mNotes + CHR(13) + ;
                  '**********************************************************************'
               STORE 0 TO m.ninvamt, m.nWellNet, m.nunits, m.nprice, m.nTOTAL, m.nworkint, m.nTotNet, m.nWorkTot
               llReturn = .T.
            ENDIF
            IF m.cTypeInv = 'W' AND INLIST(m.nnotetype, 4, 5)
               m.cDescript = '**********************************************************************' + CHR(13) + ;
                  M.mNotes + CHR(13) + ;
                  '**********************************************************************'
               STORE 0 TO m.ninvamt, m.nWellNet, m.nunits, m.nprice, m.nTOTAL, m.nworkint, m.nTotNet, m.nWorkTot
               INSERT INTO statemnt FROM MEMVAR
               llReturn = .T.
            ENDIF
            INSERT INTO ownnotes FROM MEMVAR
         ENDIF
      ENDIF
   ENDPROC

   ***********************************************************************
   PROCEDURE BackTaxWith
      ***********************************************************************
      *************************************************************
      *  Process Tax Withholding
      *************************************************************
      IF THIS.nbackupwith # 0
         THIS.nownertotal = THIS.nownertotal - THIS.nbackupwith
         m.crptgroup      = 'H'
         m.cSuspType      = ''
         m.cTYPE          = 'PPD'
         m.nWellNet       = THIS.nbackupwith
         m.cperiod        = ''
         m.cyear          = THIS.oinvtmp.hyear
         m.cprogcode      = 'ZZZZ'
         m.cWellType      = '}ZZZZZZZ'
         m.cDescript      = 'Backup Withholding Amount Deducted This Run'
         m.cownerid       = THIS.cownerid
         m.nRunNo         = THIS.nRunNo
         m.crunyear       = THIS.crunyear
         m.cDescript      = ' '
      ENDIF  && IF m.nBack

      *************************************************************
      *  Process Tax Withholding
      *************************************************************
      IF THIS.ntaxwith # 0
         THIS.nownertotal = THIS.nownertotal - THIS.ntaxwith
         m.crptgroup      = 'H'
         m.cSuspType      = ''
         m.cTYPE          = 'PPD'
         m.nWellNet       = THIS.ntaxwith
         m.cperiod        = ''
         m.cyear          = THIS.oinvtmp.hyear
         m.cprogcode      = 'ZZZZ'
         m.cWellType      = '}ZZZZZZZ'
         m.cDescript      = 'Tax Withholding Amount Deducted This Run'
         m.cownerid       = THIS.cownerid
         m.nRunNo         = THIS.nRunNo
         m.crunyear       = THIS.crunyear
         m.cDescript      = ' '
      ENDIF  && IF m.nTax
   ENDPROC

   ***********************************************************************
   PROCEDURE removetaxexempt
      ***********************************************************************
      LPARA tcWellId, tcType, tnAmount
      LOCAL lnShare

      *
      * Removes the tax exempt owners share from the gross amount before taxes
      * are calculated on the gross.  - For New Mexico Wells
      *

      lnShare = 0

      swSelect('wellinv')
      SCAN FOR cwellid = tcWellId
         SCATTER MEMVAR

         swSelect('investor')
         SET ORDER TO cownerid
         IF SEEK(m.cownerid) AND lExempt
            DO CASE
               CASE tcType = 'BBL'
                  lnShare = lnShare + SWROUND((tnAmount * m.nrevoil / 100), 2)
               CASE tcType = 'MCF'
                  lnShare = lnShare + SWROUND((tnAmount * m.nrevgas / 100), 2)
            ENDCASE
         ENDIF
      ENDSCAN

      lnAmount = tnAmount - lnShare

      RETURN (lnAmount)

   ENDPROC

   ***********************************************************************
   PROCEDURE Owner_Payments
      ********************************************************************
      LPARAMETERS tcownerid
      LOCAL lnPmtAmt

      lnPmtAmt = 0

      *!*         IF NOT THIS.lNewRun

      * Get the pmts that were released from suspense
      swSelect('disbhist')

      SELECT  SUM(nnetcheck) AS ntotpmts ;
          FROM disbhist ;
          WHERE crunyear = THIS.crunyear ;
              AND nRunNo = THIS.nRunNo ;
              AND cownerid = tcownerid ;
              AND crectype = 'P' ;
          INTO CURSOR pmtamt
      lnPmtAmt = ntotpmts

      lcRunYear = THIS.crunyear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

      * Get pmts still sitting in suspense since it affects the balance after the run
      swSelect('suspense')
      SELECT  SUM(nnetcheck) AS ntotpmts ;
          FROM suspense ;
          WHERE cRunYear_In + PADL(TRANSFORM(nRunNo_In), 3, '0') < lcRunYear ;
              AND cownerid = tcownerid ;
              AND crectype = 'P' ;
          INTO CURSOR pmtamt
      lnPmtAmt = lnPmtAmt + ntotpmts
      *!*         ENDIF

      RETURN lnPmtAmt
   ENDPROC

   ***********************************************************************
   PROCEDURE osuspense_access
      ***********************************************************************
      *To do: Modify this routine for the Access method

      IF TYPE('this.osuspense') # 'O'
         THIS.osuspense = CREATEOBJECT('suspense')
      ENDIF

      RETURN THIS.osuspense
   ENDPROC

   ***********************************************************************
   PROCEDURE checkincexp
      ***********************************************************************
      LPARAMETERS tcWellId, tcYear, tcPeriod, tnRunNo, tcRunYear
      LOCAL llReturn
      * Looks for activity for the given year and period for the given run
      * If it finds any, we assume it zeros itself out and go ahead and report
      * it.
      llReturn = .F.

      lcForInc = IIF(THIS.lNewRun, ' nRunNo = 0 ', ' nRunNo = tnRunNo AND crunyear = tcRunYear ')
      lcForExp = IIF(THIS.lNewRun, ' nRunNo = 0 ', ' nRunNoRev = tnRunNo AND crunyearRev = tcRunYear ')

      swSelect('income')
      LOCATE FOR cwellid = tcWellId AND ;
         cyear   = tcYear   AND ;
         cperiod = tcPeriod AND ;
         &lcForInc
      IF FOUND()
         llReturn = .T.
      ENDIF

      IF NOT llReturn
         swSelect('expense')
         LOCATE FOR cwellid = tcWellId AND ;
            cyear   = tcYear   AND ;
            cperiod = tcPeriod AND ;
            &lcForExp
         IF FOUND()
            llReturn = .T.
         ENDIF
      ENDIF

      RETURN llReturn

      ****************************************
   FUNCTION GetProdDate(tcYear, tcPeriod)
      ****************************************
      LOCAL lcReturn

      DO CASE
         CASE tcPeriod = '01'
            lcReturn = 'Jan-' + tcYear

         CASE tcPeriod = '02'
            lcReturn = 'Feb- ' + tcYear

         CASE tcPeriod = '03'
            lcReturn = 'Mar-' + tcYear

         CASE tcPeriod = '04'
            lcReturn = 'Apr-' + tcYear

         CASE tcPeriod = '05'
            lcReturn = 'May-' + tcYear

         CASE tcPeriod = '06'
            lcReturn = 'Jun-' + tcYear

         CASE tcPeriod = '07'
            lcReturn = 'Jul-' + tcYear

         CASE tcPeriod = '08'
            lcReturn = 'Aug-' + tcYear

         CASE tcPeriod = '09'
            lcReturn = 'Sep-' + tcYear

         CASE tcPeriod = '10'
            lcReturn = 'Oct-' + tcYear

         CASE tcPeriod = '11'
            lcReturn = 'Nov-' + tcYear

         CASE tcPeriod = '12'
            lcReturn = 'Dec-' + tcYear
      ENDCASE

      RETURN lcReturn

      ******************************
   FUNCTION CheckCancel
      ******************************

      IF THIS.lcanceled
         IF VARTYPE(THIS.oProgress) = 'O'
            THIS.oProgress.CloseProgress()
            THIS.oProgress = .NULL.
         ENDIF
      ENDIF

   ENDPROC

   ****************************
   PROCEDURE NonDummyPct
      ****************************
      LPARAMETERS tcWellId, tcType

      swSelect('wellinv')
      swSelect('investor')

      IF tcType = 'R'
         SELECT  SUM(nrevgas) AS npct ;
             FROM wellinv ;
             WHERE wellinv.cwellid = tcWellId AND ;
                 wellinv.cownerid NOT IN (SELECT  cownerid ;
                                              FROM investor ;
                                              WHERE lDummy) ;
             INTO CURSOR temp
      ELSE
         SELECT  SUM(nworkint) AS npct ;
             FROM wellinv ;
             WHERE wellinv.cwellid = tcWellId AND ;
                 wellinv.cownerid NOT IN (SELECT  cownerid ;
                                              FROM investor ;
                                              WHERE lDummy) ;
             INTO CURSOR temp
      ENDIF

      RETURN temp.npct

ENDDEFINE
*
*-- EndDefine: swownerstmt
**************************************************










DEFINE CLASS swOwnerReports AS CUSTOM

    cOwner1      = ""
    cOwner2      = ""
    cWell1       = ""
    cWell2       = ""
    cGroup       = ""
    cYear        = ""
    nRunNo       = 0
    dAcctDate    = {}
    cDMBatch     = ""
    lOwnPage     = .F.
    lPrograms    = .F.
    lIncDirect   = .F.
    lSummarize   = .F.
    lNoSuspense  = .F.
    lPostingOnly = .F.
    lChecksOnly  = .F.
    lOldVersion  = .F.

    ***********************
    PROCEDURE OwnerDisbStmt
    ***********************
    LOCAL oDist AS 'olddistproc'
    LOCAL lOrderGroup, lPriorSusp, llReturn, lnCount, lnMax, loError, lcVersion

    *:Global THIS.cGroupname, cprogcode, cprogname, cwellname, glNetSusp, ngrossbbl, ngrossmcf, nnetcheck
    *:Global npricebbl, npricemcf, nsevtaxes, THIS.cGroup, tcWellID1, tcWellID2, THIS.dAcctDate, THIS.nRunNo

    llReturn  = .F.
    lcVersion = ' '
    SET
    SET STEP ON

    TRY

        lcVersion     = ' '

        IF THIS.lPostingOnly
            swselect('investor')
            SET ORDER TO cownerid
            GO TOP
            THIS.cOwner1 = cownerid
            GO BOTT
            THIS.cOwner2 = cownerid
        ENDIF

        SELE groups
        LOCATE FOR THIS.cGroup = THIS.cGroup
        IF FOUND()
            m.cGroupname = cdesc
        ELSE
            m.cGroupname = 'All Groups'
        ENDIF

        IF NOT THIS.lSummarize
            lOrderGroup = 'invtmp.cOwnerID, invtmp.ctypeinv, invtmp.cwellid, invtmp.ctypeint, invtmp.cprogcode'
        ELSE
            lOrderGroup = 'invtmp.cOwnerID, invtmp.ctypeinv, invtmp.hyear, invtmp.hperiod, invtmp.csusptype, invtmp.ciddisb, invtmp.cwellid, invtmp.ctypeint, invtmp.cprogcode'
        ENDIF

        IF THIS.nRunNo # 0
            swselect('sysctl')
            LOCATE FOR nRunNo == tnRunNo AND cRunYear == tcYear AND ctypeclose = 'R'
            IF FOUND()
                lcVersion = cVersion
            ENDIF
        ENDIF

        *
        *  Call distproc to create the (invtmp) and (wellwork) cursors
        *
        * If the version is empty we assume it was
        * closed under the old version before we
        * started storing the version #. If so,
        * use the old ownerstmt class.

        IF EMPTY(lcVersion) AND THIS.nRunNo # 0
            oDist = CREATEOBJECT('olddistproc', THIS.cOwner1, THIS.cOwner2, ;
                  '01', ;
                  THIS.cYear, ;
                  THIS.cGroup, 'O', THIS.dAcctDate, .F., THIS.nRunNo)
        ELSE
            oDist = CREATEOBJECT('distproc', THIS.cOwner1, THIS.cOwner2, ;
                  '01', ;
                  THIS.cYear, ;
                  THIS.cGroup, 'O', THIS.dAcctDate, .F., THIS.nRunNo)
        ENDIF

        IF oDist.MAIN(.F., .T.)
            WAIT WIND NOWAIT 'Building Report File....'

            IF THIS.nRunNo = 0
                IF USED('tsuspense')
                    SELECT tsuspense
                    SCAN
                        SCATTER MEMVAR
                        INSERT INTO invtmp FROM MEMVAR
                    ENDSCAN
                ENDIF
            ENDIF


            SELECT  cownerid, ;
                    SUM(ROUND(nnetcheck, 2)) AS ntotalck  ;
                FROM invtmp ;
                INTO CURSOR invtotal READWRITE  ;
                GROUP BY cownerid ;
                ORDER BY cownerid

            swselect('groups')
            SET ORDER TO cGroup
            IF SEEK(THIS.cGroup)
                glNetSusp = lNetDef
            ELSE
                glNetSusp = .T.
            ENDIF

            SET SAFETY OFF

            IF THIS.lChecksOnly = .T. AND NOT THIS.lPostingOnly
                SELE cID AS cownerid, .T. AS junk FROM checks WHERE cBatch = THIS.cDMBatch INTO CURSOR tempchks ORDER BY cID
            ELSE
                SELE cownerid, .T. AS junk FROM investor INTO CURSOR tempchks ORDER BY cownerid
            ENDIF

            CREATE CURSOR disbchks ;
                (cRptGroup       C(1), ;
                  cownerid         C(10), ;
                  cOwnname         C(40), ;
                  cwellid          C(10), ;
                  nincome          N(12, 2), ;
                  noilrev          N(12, 2), ;
                  ngasrev          N(12, 2), ;
                  nothrev          N(12, 2), ;
                  ngrossbbl        N(12, 2), ;
                  ngrossmcf        N(12, 2), ;
                  ntotbbl          N(12, 2) NULL, ;
                  ntotmcf          N(12, 2) NULL, ;
                  ntotprod         N(12, 2) NULL, ;
                  ctypeinv         C(1), ;
                  ctypeint         C(1), ;
                  cdirect          C(1), ;
                  nexpense         N(12, 2), ;
                  nsevtaxes        N(12, 2), ;
                  ncompress        N(12, 2), ;
                  ngather          N(12, 2), ;
                  nnetcheck        N(12, 2), ;
                  npricebbl        N(12, 4), ;
                  npricemcf        N(12, 4), ;
                  nworkint         N(11, 7), ;
                  nintclass1       N(11, 7), ;
                  nintclass2       N(11, 7), ;
                  nintclass3       N(11, 7), ;
                  nintclass4       N(11, 7), ;
                  nintclass5       N(11, 7), ;
                  nrevoil          N(11, 7), ;
                  nrevgas          N(11, 7), ;
                  nrevoth          N(11, 7), ;
                  nOiltax1         N(9, 2), ;
                  nOiltax2         N(9, 2), ;
                  nOiltax3         N(9, 2), ;
                  nOiltax4         N(9, 2), ;
                  nGastax1         N(9, 2), ;
                  nGastax2         N(9, 2), ;
                  nGastax3         N(9, 2), ;
                  nGastax4         N(9, 2), ;
                  nMisc            N(12, 2), ;
                  nOper            N(12, 2), ;
                  nTrans           N(12, 2), ;
                  hyear            C(4), ;
                  hperiod          C(2), ;
                  cprogcode        C(10), ;
                  cprogname        C(40), ;
                  cwellname        C(30) NULL, ;
                  lPriorSusp       L, ;
                  cSuspType        C(1), ;
                  nrunno_in        I, ;
                  cRunYear_In      C(4), ;
                  ncheck_amt       N(12, 2))

            IF THIS.lOldVersion AND USED('invsusp')
                SELECT invsusp
                SCAN
                    SCATTER MEMVAR
                    IF NOT THIS.lNoSuspense
                        IF m.cprogcode # ' ' AND m.cprogcode # 'NONE'
                            IF m.lProgNet = .T.
                                SELECT invtmp
                                SET ORDER TO invtype
                                IF NOT SEEK(m.cownerid + m.cwellid + m.ctypeinv + m.ctypeint + m.cprogcode)
                                    INSERT INTO invtmp FROM MEMVAR
                                ELSE
                                    REPLACE nnetcheck WITH nnetcheck + m.nnetcheck, ;
                                        nincome   WITH nincome   + m.nincome, ;
                                        nexpense  WITH nexpense  + m.nexpense, ;
                                        nsevtaxes WITH nsevtaxes + m.nsevtaxes
                                ENDIF
                            ENDIF
                        ELSE
                            SELECT invtmp
                            SET ORDER TO invtype
                            IF NOT SEEK(m.cownerid + m.cwellid + m.ctypeinv + m.ctypeint + m.cprogcode)
                                INSERT INTO invtmp FROM MEMVAR
                            ELSE
                                REPLACE nnetcheck WITH nnetcheck + m.nnetcheck, ;
                                    nincome   WITH nincome   + m.nincome, ;
                                    nexpense  WITH nexpense  + m.nexpense, ;
                                    nsevtaxes WITH nsevtaxes + m.nsevtaxes
                            ENDIF
                        ENDIF
                    ENDIF
                    SELECT invsusp
                ENDSCAN
            ENDIF

            * Check to see if prior suspense is in invtmp and it includes payments that zero it out
            * If any are found, remove them because we don't want to report on them here.
            SELECT  *, ;
                    .F. AS junk ;
                FROM invtmp ;
                WHERE BETWEEN(cownerid, THIS.cOwner1, THIS.cOwner2)   ;
                    AND crectype # 'P' ;
                    AND NOT EMPTY(cRunYear_In);
                    AND (cRunYear + PADL(TRANSFORM(nRunNo), 3, '0') # cRunYear_In + PADL(TRANSFORM(nrunno_in), 3, '0')) ;
                INTO CURSOR tempinvtmp READWRITE

            SELECT  *, ;
                    .F. AS junk ;
                FROM IIF(THIS.nRunNo = 0, 'invtmp', 'disbhist') ;
                WHERE BETWEEN(cownerid, THIS.cOwner1, THIS.cOwner2) ;
                    AND cRunYear + PADL(TRANSFORM(nRunNo), 3, '0') = THIS.cYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0') ;
                    AND crectype = 'P' ;
                INTO CURSOR tmptmp
            SELECT tempinvtmp
            APPEND FROM DBF('tmptmp')
            USE IN tmptmp

            SELECT cownerid, SUM(nnetcheck) AS nnetcheck FROM tempinvtmp WHERE nrunno_in # 0 INTO CURSOR temp ORDER BY cownerid GROUP BY cownerid
            SCAN FOR temp.nnetcheck = 0
                * Delete the entries from invtmp if they have been zeroed out by a payment
                SELECT invtmp
                DELETE FOR cownerid == temp.cownerid AND nrunno_in # 0 AND cRunYear_In + PADL(TRANSFORM(nrunno_in), 3, '0') < THIS.cYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')
            ENDSCAN

            *
            * Remove any entries that went into suspense this run unless
            * we're including suspense.
            *
            IF THIS.lNoSuspense
                SELECT invtmp
                DELETE FOR nRunNo = nrunno_in AND cRunYear = cRunYear_In
            ENDIF

            *  This is hokey, but it works.  Wellwork comes back with J records, and trying to filter it out in the select
            *  statement doesn't work, since it's part of a union.  We don't want them in wellwork and the easy fix is
            *  to just delete them before it even gets to the select statement.  - BH 06/29/12
            SELECT wellwork
            SCAN FOR crectype = 'J'
                DELETE NEXT 1
            ENDSCAN

            SET TALK ON
            IF THIS.lIncDirect
                SELECT  invtmp.cownerid, ;
                        'A' AS cRptGroup, ;
                        investor.cSortField AS cOwnname, ;
                        invtmp.cwellid, ;
                        SUM(invtmp.nincome) AS nincome, ;
                        SUM(noilrev) AS noilrev, ;
                        SUM(ngasrev) AS ngasrev, ;
                        invtmp.nrevoil, ;
                        SUM(invtmp.nrevgas + invtmp.nflatrate) AS nrevgas, ;
                        invtmp.nrevoth, ;
                        SUM(invtmp.ntrprev + invtmp.nmiscrev1 + invtmp.nmiscrev2 + invtmp.nothrev) AS nothrev, ;
                        invtmp.ctypeinv, ;
                        invtmp.ctypeint, ;
                        invtmp.cdirect, ;
                        invtmp.cSuspType, ;
                        invtmp.nrunno_in, ;
                        invtmp.cRunYear_In, ;
                        SUM(wellwork.ntotbbl * (invtmp.nrevoil / 100)) AS ntotbbl, ;
                        SUM(wellwork.ntotmcf * (invtmp.nrevgas / 100)) AS ntotmcf, ;
                        SUM(wellwork.ntotprod * (invtmp.nrevoth / 100)) AS ntotprod, ;
                        SUM(invtmp.nexpense + ;
                            invtmp.ntotale1 + ;
                            invtmp.ntotale2 + ;
                            invtmp.ntotale3 + ;
                            invtmp.ntotale4 + ;
                            invtmp.ntotale5 + ;
                            invtmp.ntotaleA + ;
                            invtmp.ntotaleB + ;
                            invtmp.nmktgexp) AS nexpense,  ;
                        invtmp.nworkint, ;
                        invtmp.nintclass1, ;
                        invtmp.nintclass2, ;
                        invtmp.nintclass3, ;
                        invtmp.nintclass4, ;
                        invtmp.nintclass5, ;
                        invtmp.nbcpint, ;
                        invtmp.nacpint, ;
                        SUM(invtmp.nsevtaxes) AS nsevtaxes, ;
                        SUM(invtmp.ngather) AS ngather, ;
                        SUM(invtmp.ncompress) AS ncompress, ;
                        SUM(invtmp.nnetcheck) AS nnetcheck, ;
                        invtmp.hyear,    ;
                        invtmp.hperiod, ;
                        invtmp.cprogcode, ;
                        SUM(invtmp.nOiltax1) AS nOiltax1, ;
                        SUM(invtmp.nOiltax2) AS nOiltax2, ;
                        SUM(invtmp.nOiltax3) AS nOiltax3, ;
                        SUM(invtmp.nOiltax4) AS nOiltax4, ;
                        SUM(invtmp.nGastax1) AS nGastax1, ;
                        SUM(invtmp.nGastax2) AS nGastax2, ;
                        SUM(invtmp.nGastax3) AS nGastax3, ;
                        SUM(invtmp.nGastax4) AS nGastax4, ;
                        wells.cwellname, ;
                        0.00  AS ncheck_amt ;
                    FROM invtmp ;
                    LEFT JOIN wells ;
                        ON invtmp.cwellid = wells.cwellid ;
                    JOIN investor ;
                        ON invtmp.cownerid = investor.cownerid ;
                    LEFT OUTER JOIN wellwork ;
                        ON invtmp.cwellid = wellwork.cwellid ;
                        AND invtmp.hyear = wellwork.hyear ;
                        AND invtmp.hperiod = wellwork.hperiod ;
                        AND IIF(invtmp.nrunno_in = 0, invtmp.nRunNo = wellwork.nRunNo ;
                          AND invtmp.cRunYear == wellwork.cRunYear, invtmp.nrunno_in = wellwork.nRunNo ;
                          AND invtmp.cRunYear_In = wellwork.cRunYear);
                    WHERE BETWEEN(invtmp.cownerid, THIS.cOwner1, THIS.cOwner2)  ;
                        AND invtmp.cownerid IN (SELECT  cownerid ;
                                                    FROM tempchks) ;
                        AND IIF(THIS.lNoSuspense, EMPTY(invtmp.cSuspType), .T.) ;
                    INTO CURSOR disbchk ;
                    ORDER BY &lOrderGroup ;
                    GROUP BY &lOrderGroup
            ELSE
                SELECT  invtmp.cownerid, ;
                        investor.cSortField AS cOwnname, ;
                        'A' AS cRptGroup, ;
                        invtmp.cwellid, ;
                        SUM(invtmp.nincome) AS nincome, ;
                        IIF(INLIST(invtmp.cdirect, 'O', 'B'), 000000.00, SUM(invtmp.noilrev)) AS noilrev, ;
                        IIF(INLIST(invtmp.cdirect, 'G', 'B'), 000000.00, SUM(invtmp.ngasrev + invtmp.nflatrate)) AS ngasrev, ;
                        SUM(invtmp.ntrprev + invtmp.nmiscrev1 + invtmp.nmiscrev2 + invtmp.nothrev) AS nothrev, ;
                        SUM(wellwork.ntotbbl * (invtmp.nrevoil / 100)) AS ntotbbl, ;
                        SUM(wellwork.ntotmcf * (invtmp.nrevgas / 100)) AS ntotmcf, ;
                        SUM(wellwork.ntotprod * (invtmp.nrevoth / 100)) AS ntotprod, ;
                        invtmp.ctypeinv, ;
                        invtmp.ctypeint, ;
                        invtmp.cdirect, ;
                        invtmp.cSuspType, ;
                        invtmp.nrunno_in, ;
                        invtmp.cRunYear_In, ;
                        invtmp.nrevoil, ;
                        invtmp.nrevgas, ;
                        invtmp.nrevoth, ;
                        SUM(invtmp.nexpense + ;
                            invtmp.ntotale1 + ;
                            invtmp.ntotale2 + ;
                            invtmp.ntotale3 + ;
                            invtmp.ntotale4 + ;
                            invtmp.ntotale5 + ;
                            invtmp.ntotaleA + ;
                            invtmp.ntotaleB + ;
                            invtmp.nmktgexp) AS nexpense,  ;
                        invtmp.nworkint, ;
                        invtmp.nintclass1, ;
                        invtmp.nintclass2, ;
                        invtmp.nintclass3, ;
                        invtmp.nintclass4, ;
                        invtmp.nintclass5, ;
                        invtmp.nbcpint, ;
                        invtmp.nacpint, ;
                        SUM(invtmp.nOiltax1) AS nOiltax1, ;
                        SUM(invtmp.nOiltax2) AS nOiltax2, ;
                        SUM(invtmp.nOiltax3) AS nOiltax3, ;
                        SUM(invtmp.nOiltax4) AS nOiltax4, ;
                        SUM(invtmp.nGastax1) AS nGastax1, ;
                        SUM(invtmp.nGastax2) AS nGastax2, ;
                        SUM(invtmp.nGastax3) AS nGastax3, ;
                        SUM(invtmp.nGastax4) AS nGastax4, ;
                        SUM(invtmp.nsevtaxes) AS nsevtaxes, ;
                        SUM(invtmp.ngather)   AS ngather, ;
                        SUM(invtmp.ncompress) AS ncompress, ;
                        SUM(invtmp.nnetcheck) AS nnetcheck, ;
                        invtmp.hyear,    ;
                        invtmp.hperiod, ;
                        invtmp.cprogcode, ;
                        wells.cwellname, ;
                        0.00  AS ncheck_amt ;
                    FROM invtmp ;
                    LEFT JOIN wells ;
                        ON invtmp.cwellid = wells.cwellid ;
                    JOIN investor ;
                        ON invtmp.cownerid = investor.cownerid ;
                    LEFT OUTER JOIN wellwork ;
                        ON invtmp.cwellid = wellwork.cwellid ;
                        AND invtmp.hyear = wellwork.hyear ;
                        AND invtmp.hperiod = wellwork.hperiod ;
                        AND IIF(invtmp.nrunno_in = 0, invtmp.nRunNo = wellwork.nRunNo ;
                          AND invtmp.cRunYear == wellwork.cRunYear, invtmp.nrunno_in = wellwork.nRunNo ;
                          AND invtmp.cRunYear_In = wellwork.cRunYear);
                    WHERE BETWEEN(invtmp.cownerid, THIS.cOwner1, THIS.cOwner2)  ;
                        AND invtmp.cownerid IN (SELECT  cownerid ;
                                                    FROM tempchks) ;
                        AND IIF(THIS.lNoSuspense, EMPTY(invtmp.cSuspType);
                          OR (invtmp.nRunNo = invtmp.nrunno_in ;
                            AND invtmp.cRunYear = invtmp.cRunYear_In), .T.) ;
                    INTO CURSOR disbchk ;
                    ORDER BY &lOrderGroup ;
                    GROUP BY &lOrderGroup
            ENDIF
            SET TALK OFF
            SELECT disbchks
            APPEND FROM DBF('disbchk')

            IF USED('tempchks')
                USE IN tempchks
            ENDIF

            IF THIS.lPostingOnly
                SELECT cownerid FROM investor WHERE lIntegGL INTO CURSOR postingowners READWRITE
                INDEX ON cownerid TAG cownerid
            ENDIF

            lnMax   = RECC()
            lnCount = 1
            SELECT disbchks
            SET ORDER TO 0
            SCAN
                SCATTER MEMVAR
                lnCount = lnCount + 1

                IF THIS.lPostingOnly
                    SELECT postingowners
                    IF NOT SEEK(m.cownerid)
                        SELECT disbchks
                        DELETE NEXT 1
                        LOOP
                    ENDIF
                ENDIF

                SELECT disbchks

                IF ISNULL(m.ntotbbl)
                    REPLACE ntotbbl WITH 0
                ENDIF
                IF ISNULL(m.ntotmcf)
                    REPLACE ntotmcf WITH 0
                ENDIF
                IF ISNULL(m.ntotprod)
                    REPLACE ntotprod WITH 0
                ENDIF

                SELE wellwork
                LOCATE FOR cwellid = m.cwellid AND hyear + hperiod = m.hyear + m.hperiod
                IF FOUND()
                    m.ngrossbbl = wellwork.ntotbbl
                    m.ngrossmcf = wellwork.ntotmcf
                    IF wellwork.ntotbbl # 0
                        m.npricebbl = wellwork.ngrossoil / wellwork.ntotbbl
                    ELSE
                        m.npricebbl = 0
                    ENDIF
                    IF wellwork.ntotmcf # 0
                        m.npricemcf = wellwork.ngrossgas / wellwork.ntotmcf
                    ELSE
                        m.npricemcf = 0
                    ENDIF
                    SELE disbchks
                    REPL ngrossbbl WITH m.ngrossbbl, ;
                        ngrossmcf WITH m.ngrossmcf, ;
                        npricebbl WITH m.npricebbl, ;
                        npricemcf WITH m.npricemcf
                ENDIF

                IF m.cwellid = 'ALL'
                    m.cwellname = 'Prior Period Balance'
                ENDIF

                swselect('programs')
                SET ORDER TO cprogcode
                SEEK m.cprogcode
                IF FOUND()
                    m.cprogname = cprogname
                ELSE
                    m.cprogcode = 'None'
                    m.cprogname = 'Non Program Wells'
                ENDIF

                SELECT disbchks
                REPL cwellname WITH m.cwellname, ;
                    cprogname WITH m.cprogname

                IF THIS.lIncDirect
                    DO CASE
                        CASE m.cdirect = 'O'
                            m.nnetcheck = m.nnetcheck + m.noilrev
                        CASE m.cdirect = 'G'
                            m.nnetcheck = m.nnetcheck + m.ngasrev
                        CASE m.cdirect = 'B'
                            m.nnetcheck = m.nnetcheck + m.noilrev + m.ngasrev
                    ENDCASE
                    SELECT disbchks
                    REPL nnetcheck WITH m.nnetcheck
                ELSE
                    swselect('wells')
                    SET ORDER TO cwellid
                    IF SEEK(m.cwellid)
                        SCATTER FIELDS LIKE lSev* MEMVAR
                    ELSE
                        LOOP
                    ENDIF
                    DO CASE
                        CASE m.cdirect = 'O'
                            IF m.lSev1O
                                m.nsevtaxes = m.nsevtaxes - m.nOiltax1
                            ENDIF
                            IF m.lSev2O
                                m.nsevtaxes = m.nsevtaxes - m.nOiltax2
                            ENDIF
                            IF m.lSev3O
                                m.nsevtaxes = m.nsevtaxes - m.nOiltax3
                            ENDIF
                            IF m.lSev4O
                                m.nsevtaxes = m.nsevtaxes - m.nOiltax4
                            ENDIF
                        CASE m.cdirect = 'G'
                            IF m.lSev1G
                                m.nsevtaxes = m.nsevtaxes - m.nGastax1
                            ENDIF
                            IF m.lSev2G
                                m.nsevtaxes = m.nsevtaxes - m.nGastax2
                            ENDIF
                            IF m.lSev3G
                                m.nsevtaxes = m.nsevtaxes - m.nGastax3
                            ENDIF
                            IF m.lSev4G
                                m.nsevtaxes = m.nsevtaxes - m.nGastax4
                            ENDIF
                        CASE m.cdirect = 'B'
                            IF m.lSev1O
                                m.nsevtaxes = m.nsevtaxes - m.nOiltax1
                            ENDIF
                            IF m.lSev2O
                                m.nsevtaxes = m.nsevtaxes - m.nOiltax2
                            ENDIF
                            IF m.lSev3O
                                m.nsevtaxes = m.nsevtaxes - m.nOiltax3
                            ENDIF
                            IF m.lSev4O
                                m.nsevtaxes = m.nsevtaxes - m.nOiltax4
                            ENDIF
                            IF m.lSev1G
                                m.nsevtaxes = m.nsevtaxes - m.nGastax1
                            ENDIF
                            IF m.lSev2G
                                m.nsevtaxes = m.nsevtaxes - m.nGastax2
                            ENDIF
                            IF m.lSev3G
                                m.nsevtaxes = m.nsevtaxes - m.nGastax3
                            ENDIF
                            IF m.lSev4G
                                m.nsevtaxes = m.nsevtaxes - m.nGastax4
                            ENDIF
                    ENDCASE
                    SELECT disbchks
                    REPL nsevtaxes WITH m.nsevtaxes
                ENDIF

                IF INLIST(m.ctypeinv, 'X', 'M')
                    m.cwellname = 'Prior Bal: ' + m.cwellname
                    SELECT disbchks
                    REPL cwellname WITH m.cwellname, ;
                        ctypeinv  WITH 'Z', ;
                        noilrev   WITH 0, ;
                        ngasrev   WITH 0, ;
                        nothrev   WITH 0, ;
                        nexpense  WITH 0
                ELSE
                    IF NOT glNetSusp AND m.ctypeinv = 'X'
                        m.cwellname = 'Prior Period Deficit'
                        SELECT disbchks
                        REPL cwellname WITH m.cwellname, ;
                            ctypeinv  WITH 'Z', ;
                            noilrev   WITH 0, ;
                            ngasrev   WITH 0, ;
                            nothrev   WITH 0, ;
                            nexpense  WITH 0
                    ENDIF
                ENDIF

                IF NOT EMPTY(m.cSuspType)
                    m.lPriorSusp = .T.
                ELSE
                    m.lPriorSusp = .F.
                ENDIF
                SELECT disbchks
                REPLACE cprogname WITH m.cprogname, ;
                    cprogcode WITH m.cprogcode, ;
                    lPriorSusp WITH m.lPriorSusp

            ENDSCAN

            SELECT disbchks
            IF THIS.lPrograms = .T.
                INDEX ON cownerid + cRptGroup + cprogcode + cwellid + hyear + hperiod + cSuspType TAG cownerid
                SET ORDER TO cownerid
            ELSE
                INDEX ON cownerid + cRptGroup + ctypeinv + cwellid + hyear + hperiod + cSuspType TAG ownerkey
                SET ORDER TO ownerkey
            ENDIF

            SELECT disbchks
            SCAN
                IF nincome = 0 AND ;
                        nexpense = 0 AND ;
                        nnetcheck = 0
                    DELETE NEXT 1
                ENDIF
            ENDSCAN


            WAIT CLEAR

            * Remove any suspense from this run if we're only looking for checks this run
            IF THIS.lChecksOnly
                SELE disbchks
                DELETE FOR NOT EMPTY(cSuspType) AND nrunno_in = THIS.nRunNo AND cRunYear_In = THIS.cYear
            ENDIF

            *  If not summarizing by period, blank out year and period
            IF NOT THIS.lSummarize
                SCAN
                    REPL hyear WITH '', hperiod WITH ''
                ENDSCAN
            ENDIF
            IF RECC() > 0
                llReturn = .T.
            ELSE
                llReturn = .F.
            ENDIF
        ELSE
            llReturn = .F.
        ENDIF

    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'OwnerDisbStmt', loError.LINENO, 'OwnerReports', loError.ERRORNO, loError.MESSAGE
        MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    RETURN llReturn
ENDDEFINE


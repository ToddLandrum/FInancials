LPARA tnDecType, tcOwner1, tcOwner2, tcLease1, tcLease2, tnYears, tlNoEstimate, tlSelectedWells, tlSelectedOwners
LOCAL lnCurYear, lcLease, m.cYear, oMessage, oProgress
LOCAL m.nExp0, m.nExp1, m.nExp2, m.nExp3, m.nExp4, m.nExp5, m.nExp6, m.nExp7, m.nExp8, m.nExp9
LOCAL m.nExp10, m.nExp11, m.nExp12
LOCAL m.n1Time0, m.n1Time1, m.n1Time2, m.n1Time3, m.n1Time4, m.n1Time5, m.n1Time6, m.n1Time7, m.n1Time8, m.n1Time9
LOCAL m.n1Time10, m.n1Time11, m.n1Time12
LOCAL lEst0, lEst1, lEst10, lEst11, lEst12, lEst2, lEst3, lEst4, lEst5, lEst6, lEst7, lEst8, lEst9
LOCAL lcOwnType, lcYear, llReturn, lnCount, lnMax, loError
LOCAL cyear0, cyear1, cyear10, cyear11, cyear12, cyear2, cyear3, cyear4, cyear5, cyear6, cyear7
LOCAL cyear8, cyear9, n1Time0, n1Time1, n1Time10, n1Time11, n1Time12, n1Time2, n1Time3, n1Time4
LOCAL n1Time5, n1Time6, n1Time7, n1Time8, n1Time9, nExp0, nExp1, nExp10, nExp11, nExp12, nExp2
LOCAL nExp3, nExp4, nExp5, nExp6, nExp7, nExp8, nExp9, navgbblprc, navgmcfprc, nbbl0, nbbl1
LOCAL nbbl10, nbbl11, nbbl12, nbbl2, nbbl3, nbbl4, nbbl5, nbbl6, nbbl7, nbbl8, nbbl9, ncashflow
LOCAL ncashrcv0, ncashrcv1, ncashrcv10, ncashrcv11, ncashrcv12, ncashrcv2, ncashrcv3, ncashrcv4
LOCAL ncashrcv5, ncashrcv6, ncashrcv7, ncashrcv8, ncashrcv9, ncashtot0, ncashtot1, ncashtot10
LOCAL ncashtot11, ncashtot12, ncashtot2, ncashtot3, ncashtot4, ncashtot5, ncashtot6, ncashtot7
LOCAL ncashtot8, ncashtot9, ncurpay, nmcf0, nmcf1, nmcf10, nmcf11, nmcf12, nmcf2, nmcf3, nmcf4
LOCAL nmcf5, nmcf6, nmcf7, nmcf8, nmcf9, npct0, npct1, npct10, npct11, npct12, npct2, npct3
LOCAL npct4, npct5, npct6, npct7, npct8, npct9, ntotpay, nyear10pct, nyear11pct, nyear12pct
LOCAL nyear1pct, nyear2pct, nyear3pct, nyear4pct, nyear5pct, nyear6pct, nyear7pct, nyear8pct
LOCAL nyear9pct

STORE 0 TO m.nExp0, m.nExp1, m.nExp2, m.nExp3, m.nExp4, m.nExp5, m.nExp6, m.nExp7, m.nExp8, m.nExp9, ;
    m.nExp10, m.nExp11, m.nExp12
STORE 0 TO m.n1Time0, m.n1Time1, m.n1Time2, m.n1Time3, m.n1Time4, m.n1Time5, m.n1Time6, m.n1Time7, m.n1Time8, m.n1Time9, ;
    m.n1Time10, m.n1Time11, m.n1Time12

llReturn = .T.

TRY

    SWSELECT('wells')
    SET ORDER TO cwellid

    SWSELECT('ownpcts')
    oMessage = FindGlobalObject('cmMessage')

    SWSELECT('decline')
    DELE ALL

    IF NOT tlSelectedWells
       SELECT cwellid as cid FROM wells WHERE BETWEEN(cwellid,tcLease1,tcLease2) INTO CURSOR selectedwells
    ENDIF
    IF NOT tlSelectedOwners   
       SELECT cownerid as cid FROM investor WHERE BETWEEN(cownerid,tcOwner1,tcOwner2) INTO CURSOR selected
    ENDIF 
 
    lnCurYear = YEAR(DATE())

    CREATE CURSOR tempdecl ;
        (cleasename C(30), ;
          wellid     C(10), ;
          cownname   C(40), ;
          cstatus    C(1), ;
          dsold      D, ;
          nsellprice N(12, 2), ;
          cowntype   C(1), ;
          cYear      C(4), ;
          lest       L, ;
          nprodinc   N(12, 2), ;
          nonetime   N(12, 2), ;
          notherinc  N(12, 2), ;
          nexpense   N(12, 2), ;
          ncashflow  N(12, 2), ;
          nbblshare  N(12, 2), ;
          nmcfshare  N(12, 2), ;
          navgbblprc N(7, 4), ;
          navgmcfprc N(7, 4), ;
          nRevGas    N(11, 7), ;
          nRevOil    N(11, 7), ;
          cidlease   C(10), ;
          cidprod    C(5), ;
          cfieldname C(30), ;
          ninvamt    N(12, 2))

    CREATE CURSOR tempexp ;
        (cleasename C(30), ;
          cYear      C(4), ;
          nexpense   N(12, 2))
    INDEX ON TRIM(cleasename) + cYear TAG leaseyear

    oProgress = oMessage.ProgressBar('Calculating Report, Stage 1....')

	SELECT  disbhist.cwellid, ;
			disbhist.cownerid, ;
			investor.cownname AS cownname, ;
			wells.cfieldid, ;
			SPACE(30) AS cfieldname, ;
			wells.cwellname AS cleasename, ;
			wells.cwellstat AS cstatus, ;
			wells.dsold, ;
			wells.nsellprice, ;
			SUM(disbhist.noilrev + disbhist.ngasrev) AS nprodinc, ;
			SUM(disbhist.ntrprev) AS notherinc, ;
			SUM(disbhist.nexpense + disbhist.ntotale1 + disbhist.ntotale2 + disbhist.ntotale3 + ;
				disbhist.ntotale4 + disbhist.ntotale5 + disbhist.nsevtaxes + ;
				disbhist.ngather + disbhist.ncompress) AS nexpense, ;
			000000.00 AS nbblshare, ;
			000000.00 AS nmcfshare, ;
			SUM(disbhist.nnetcheck) AS ncashflow, ;
			00.0000 AS navgbblprc, ;
			00.0000 AS navgmcfprc, ;
			ownpcts.nRevGas  AS nRevGas, ;
			ownpcts.nRevOil  AS nRevOil, ;
			disbhist.ctypeinv AS cowntype, ;
			0 AS ninvamt, ;
			STR(YEAR(disbhist.hdate),4) AS cYear ;
		FROM disbhist, wells, investor, ownpcts ;
		WHERE disbhist.cownerid in (SELECT cid FROM selected) ;
			AND disbhist.cwellid in (SELECT cid FROM selectedwells) ;
			AND disbhist.ctypeinv = 'W' ;
			AND disbhist.cwellid = wells.cwellid ;
			AND disbhist.cownerid = investor.cownerid ;
			AND disbhist.ciddisb = ownpcts.ciddisb ;
		INTO CURSOR temp ;
		GROUP BY disbhist.cownerid, disbhist.cwellid, cYear ;
		ORDER BY disbhist.cownerid, disbhist.cwellid, cYear


    IF _TALLY = 0
        oProgress.CloseProgress()
        llReturn = .F.
        EXIT
    ENDIF

    swselect('fields')
    SET ORDER to cfieldid
    
    SELECT temp
    SCAN
       SCATTER MEMVAR 
       SELECT fields
       IF SEEK(m.cfieldid)
          m.cfieldname = cfieldname
       ELSE
          m.cfieldname = 'NONE'
       ENDIF
       INSERT INTO tempdecl FROM MEMVAR 
    ENDSCAN 
    USE IN temp
*
*  Fill in the total MCF and BBL
*
	SELECT  cwellid, YEAR(hdate) AS nYear, SUM(ntotmcf) AS ntotmcf, SUM(ntotbbl) AS ntotbbl ;
		FROM wellhist ;
		INTO CURSOR temp ;
		ORDER BY cwellid, nYear ;
		GROUP BY cwellid, nYear

    IF _TALLY > 0
        SELECT temp
        SCAN
            SCATTER MEMVAR
            SELECT tempdecl
            SCAN FOR cwellid = m.cwellid AND VAL(cYear) = m.nYear
                REPLACE nmcfshare WITH m.ntotmcf * (nRevGas / 100), ;
                    nbblshare WITH m.ntotbbl * (nRevOil / 100)
            ENDSCAN
        ENDSCAN
    ENDIF

    lcYear    = ' '
    lcLease   = ' '
    lcOwnType = ' '
    STORE 0 TO m.nyear1pct, m.nyear2pct, m.nyear3pct, m.nyear4pct, ;
        m.nyear5pct, m.nyear6pct, m.nyear7pct, m.nyear8pct, ;
        m.nyear9pct, m.nyear10pct, m.nyear11pct, m.nyear12pct, m.ncashrcv0
    STORE ' ' TO m.cyear0, m.cyear1, m.cyear2, m.cyear3, m.cyear4, ;
        m.cyear5, m.cyear6, m.cyear7, m.cyear8, m.cyear9, ;
        m.cyear10, m.cyear11, m.cyear12
    STORE .T. TO m.lEst0, m.lEst1, m.lEst2, m.lEst3, m.lEst4, m.lEst5, m.lEst6, ;
        m.lEst7, m.lEst8, m.lEst9, m.lEst10, m.lEst11, m.lEst12

    SELECT tempdecl

    lnMax   = RECC()
    lnCount = 1

    oProgress.SetProgressRange(0, lnMax)

    STORE 0 TO m.ncashrcv0, m.ncashrcv1, m.ncashrcv2, m.ncashrcv3, m.ncashrcv4, ;
        m.ncashrcv5, m.ncashrcv6, m.ncashrcv7, m.ncashrcv8, m.ncashrcv9, ;
        m.ncashrcv10, m.ncashrcv11, m.ncashrcv12
    STORE 0 TO m.ncashtot0, m.ncashtot1, m.ncashtot2, m.ncashtot3, m.ncashtot4, ;
        m.ncashtot5, m.ncashtot6, m.ncashtot7, m.ncashtot8, m.ncashtot9, ;
        m.ncashtot10, m.ncashtot11, m.ncashtot12
    STORE 0 TO m.nbbl0, m.nbbl1, m.nbbl2, m.nbbl3, m.nbbl4, m.nbbl5, m.nbbl6, ;
        m.nbbl7, m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
    STORE 0 TO m.nmcf0, m.nmcf1, m.nmcf2, m.nmcf3, m.nmcf4, m.nmcf5, m.nmcf6, ;
        m.nmcf7, m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
    STORE 0 TO m.nExp0, m.nExp1, m.nExp2, m.nExp3, m.nExp4, m.nExp5, m.nExp6, m.nExp7, m.nExp8, m.nExp9, ;
        m.nExp10, m.nExp11, m.nExp12
    STORE 0 TO m.n1Time0, m.n1Time1, m.n1Time2, m.n1Time3, m.n1Time4, m.n1Time5, m.n1Time6, m.n1Time7, m.n1Time8, m.n1Time9, ;
        m.n1Time10, m.n1Time11, m.n1Time12
    STORE 0 TO m.npct0, m.npct1, m.npct2, m.npct3, m.npct4, m.npct5, m.npct6, m.npct7, m.npct8, ;
               m.npct9, m.npct10, m.npct11, m.npct12
    SELECT decline
    SCATTER MEMVAR blank 
*
*  Insert one record for each well and owner into the decline table
*
    SELECT tempdecl
    GO TOP
    SCAN
        oProgress.UpdateProgress(lnCount)
        lnCount = lnCount + 1
        IF (lcLease <> cleasename + cownname OR lcOwnType <> cowntype) AND lcLease <> ' '
            INSERT INTO decline FROM MEMVAR
*  Insert expense record into cursor
            INSERT INTO tempexp FROM MEMVAR
            STORE 0 TO m.ncashrcv0, m.ncashrcv1, m.ncashrcv2, m.ncashrcv3, m.ncashrcv4, ;
                m.ncashrcv5, m.ncashrcv6, m.ncashrcv7, m.ncashrcv8, m.ncashrcv9, ;
                m.ncashrcv10, m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot0, m.ncashtot1, m.ncashtot2, m.ncashtot3, m.ncashtot4, ;
                m.ncashtot5, m.ncashtot6, m.ncashtot7, m.ncashtot8, m.ncashtot9, ;
                m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl0, m.nbbl1, m.nbbl2, m.nbbl3, m.nbbl4, m.nbbl5, m.nbbl6, ;
                m.nbbl7, m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf0, m.nmcf1, m.nmcf2, m.nmcf3, m.nmcf4, m.nmcf5, m.nmcf6, ;
                m.nmcf7, m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
            STORE .T. TO m.lEst0, m.lEst1, m.lEst2, m.lEst3, m.lEst4, m.lEst5, m.lEst6, ;
                m.lEst7, m.lEst8, m.lEst9, m.lEst10, m.lEst11, m.lEst12
            STORE 0 TO m.nExp0, m.nExp1, m.nExp2, m.nExp3, m.nExp4, m.nExp5, m.nExp6, m.nExp7, m.nExp8, m.nExp9, ;
                m.nExp10, m.nExp11, m.nExp12
            STORE 0 TO m.n1Time0, m.n1Time1, m.n1Time2, m.n1Time3, m.n1Time4, m.n1Time5, m.n1Time6, m.n1Time7, m.n1Time8, m.n1Time9, ;
                m.n1Time10, m.n1Time11, m.n1Time12
            lcLease   = cleasename + cownname
            lcOwnType = cowntype
            m.cyear0  = cYear
            m.cyear1  = STR(VAL(m.cyear0) + 1, 4)
            m.cyear2  = STR(VAL(m.cyear1) + 1, 4)
            m.cyear3  = STR(VAL(m.cyear2) + 1, 4)
            m.cyear4  = STR(VAL(m.cyear3) + 1, 4)
            m.cyear5  = STR(VAL(m.cyear4) + 1, 4)
            m.cyear6  = STR(VAL(m.cyear5) + 1, 4)
            m.cyear7  = STR(VAL(m.cyear6) + 1, 4)
            m.cyear8  = STR(VAL(m.cyear7) + 1, 4)
            m.cyear9  = STR(VAL(m.cyear8) + 1, 4)
            m.cyear10 = STR(VAL(m.cyear9) + 1, 4)
            m.cyear11 = STR(VAL(m.cyear10) + 1, 4)
            m.cyear12 = STR(VAL(m.cyear11) + 1, 4)
        ENDIF
        SCATTER MEMVAR
        IF lcLease = ' '
            m.cyear0  = m.cYear
            m.cyear1  = STR(VAL(m.cYear) + 1, 4)
            m.cyear2  = STR(VAL(m.cyear1) + 1, 4)
            m.cyear3  = STR(VAL(m.cyear2) + 1, 4)
            m.cyear4  = STR(VAL(m.cyear3) + 1, 4)
            m.cyear5  = STR(VAL(m.cyear4) + 1, 4)
            m.cyear6  = STR(VAL(m.cyear5) + 1, 4)
            m.cyear7  = STR(VAL(m.cyear6) + 1, 4)
            m.cyear8  = STR(VAL(m.cyear7) + 1, 4)
            m.cyear9  = STR(VAL(m.cyear8) + 1, 4)
            m.cyear10 = STR(VAL(m.cyear9) + 1, 4)
            m.cyear11 = STR(VAL(m.cyear10) + 1, 4)
            m.cyear12 = STR(VAL(m.cyear11) + 1, 4)
        ENDIF

*
*  Plug the cash received into the appropriate year
*
        m.ncashflow = m.nprodinc + m.notherinc
        DO CASE
            CASE m.cYear = m.cyear0
                m.ncashrcv0 = m.ncashflow
                m.ncashtot0 = m.ncashflow
                m.nbbl0     = m.nbblshare
                m.nmcf0     = m.nmcfshare
                m.lEst0     = .F.
                m.nExp0     = m.nexpense
                m.n1Time0   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear0)
                    m.ncashrcv0 = m.ncashrcv0 + m.nsellprice
                    m.ncashtot0 = m.ncashtot0 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear1
                m.ncashrcv1 = m.ncashflow
                m.ncashtot1 = m.ncashtot0 + m.ncashflow
                m.nbbl1     = m.nbblshare
                m.nmcf1     = m.nmcfshare
                m.lEst1     = .F.
                m.nExp1     = m.nexpense
                m.n1Time1   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear1)
                    m.ncashrcv1 = m.ncashrcv1 + m.nsellprice
                    m.ncashtot1 = m.ncashtot1 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear2
                m.ncashrcv2 = m.ncashflow
                m.ncashtot2 = m.ncashtot1 + m.ncashflow
                m.nbbl2     = m.nbblshare
                m.nmcf2     = m.nmcfshare
                m.lEst2     = .F.
                m.nExp2     = m.nexpense
                m.n1Time2   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear2)
                    m.ncashrcv2 = m.ncashrcv2 + m.nsellprice
                    m.ncashtot2 = m.ncashtot2 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear3
                m.ncashrcv3 = m.ncashflow
                m.ncashtot3 = m.ncashtot2 + m.ncashflow
                m.nbbl3     = m.nbblshare
                m.nmcf3     = m.nmcfshare
                m.lEst3     = .F.
                m.nExp3     = m.nexpense
                m.n1Time3   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear3)
                    m.ncashrcv3 = m.ncashrcv3 + m.nsellprice
                    m.ncashtot3 = m.ncashtot3 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear4
                m.ncashrcv4 = m.ncashflow
                m.ncashtot4 = m.ncashtot3 + m.ncashflow
                m.nbbl4     = m.nbblshare
                m.nmcf4     = m.nmcfshare
                m.lEst4     = .F.
                m.nExp4     = m.nexpense
                m.n1Time4   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear4)
                    m.ncashrcv4 = m.ncashrcv4 + m.nsellprice
                    m.ncashtot4 = m.ncashtot4 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear5
                m.ncashrcv5 = m.ncashflow
                m.ncashtot5 = m.ncashtot4 + m.ncashflow
                m.nbbl5     = m.nbblshare
                m.nmcf5     = m.nmcfshare
                m.lEst5     = .F.
                m.nExp5     = m.nexpense
                m.n1Time5   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear5)
                    m.ncashrcv5 = m.ncashrcv5 + m.nsellprice
                    m.ncashtot5 = m.ncashtot5 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear6
                m.ncashrcv6 = m.ncashflow
                m.ncashtot6 = m.ncashtot5 + m.ncashflow
                m.nbbl6     = m.nbblshare
                m.nmcf6     = m.nmcfshare
                m.lEst6     = .F.
                m.nExp6     = m.nexpense
                m.n1Time6   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear6)
                    m.ncashrcv6 = m.ncashrcv6 + m.nsellprice
                    m.ncashtot6 = m.ncashtot6 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear7
                m.ncashrcv7 = m.ncashflow
                m.ncashtot7 = m.ncashtot6 + m.ncashflow
                m.nbbl7     = m.nbblshare
                m.nmcf7     = m.nmcfshare
                m.lEst7     = .F.
                m.nExp7     = m.nexpense
                m.n1Time7   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear7)
                    m.ncashrcv7 = m.ncashrcv7 + m.nsellprice
                    m.ncashtot7 = m.ncashtot7 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear8
                m.ncashrcv8 = m.ncashflow
                m.ncashtot8 = m.ncashtot7 + m.ncashflow
                m.nbbl8     = m.nbblshare
                m.nmcf8     = m.nmcfshare
                m.lEst8     = .F.
                m.nExp8     = m.nexpense
                m.n1Time8   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear8)
                    m.ncashrcv8 = m.ncashrcv8 + m.nsellprice
                    m.ncashtot8 = m.ncashtot8 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear9
                m.ncashrcv9 = m.ncashflow
                m.ncashtot9 = m.ncashtot8 + m.ncashflow
                m.nbbl9     = m.nbblshare
                m.nmcf9     = m.nmcfshare
                m.lEst9     = .F.
                m.nExp9     = m.nexpense
                m.n1Time9   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear9)
                    m.ncashrcv9 = m.ncashrcv9 + m.nsellprice
                    m.ncashtot9 = m.ncashtot9 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear10
                m.ncashrcv10 = m.ncashflow
                m.ncashtot10 = m.ncashtot9 + m.ncashflow
                m.nbbl10     = m.nbblshare
                m.nmcf10     = m.nmcfshare
                m.lEst10     = .F.
                m.nExp10     = m.nexpense
                m.n1Time10   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear10)
                    m.ncashrcv10 = m.ncashrcv10 + m.nsellprice
                    m.ncashtot10 = m.ncashtot10 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear11
                m.ncashrcv11 = m.ncashflow
                m.ncashtot11 = m.ncashtot10 + m.ncashflow
                m.nbbl11     = m.nbblshare
                m.nmcf11     = m.nmcfshare
                m.lEst11     = .F.
                m.nExp11     = m.nexpense
                m.n1Time11   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear11)
                    m.ncashrcv11 = m.ncashrcv11 + m.nsellprice
                    m.ncashtot11 = m.ncashtot11 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
            CASE m.cYear = m.cyear12
                m.ncashrcv12 = m.ncashflow
                m.ncashtot12 = m.ncashtot11 + m.ncashflow
                m.nbbl12     = m.nbblshare
                m.nmcf12     = m.nmcfshare
                m.lEst12     = .F.
                m.nExp12     = m.nexpense
                m.n1Time12   = m.nonetime
                IF (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear12)
                    m.ncashrcv12 = m.ncashrcv12 + m.nsellprice
                    m.ncashtot12 = m.ncashtot12 + m.nsellprice
                ENDIF
                INSERT INTO tempexp FROM MEMVAR
        ENDCASE
        lcLease   = m.cleasename + m.cownname
        lcOwnType = m.cowntype
    ENDSCAN

    oProgress.CloseProgress()

*
*  Insert last record
*
    INSERT INTO decline FROM MEMVAR
    INSERT INTO tempexp FROM MEMVAR

    oProgress = oMessage.ProgressBar('Calculating Report, Stage 2....')

    SELECT tempexp
    SET ORDER TO leaseyear

    SELECT decline
    COUNT FOR NOT DELETED() TO lnMax
    lnCount = 1
    oProgress.SetProgressRange(0, lnMax)

    SELECT decline
    GO TOP
    SCAN
        SCATTER MEMVAR
        oProgress.UpdateProgress(lnCount)
        lnCount = lnCount + 1

        IF NOT tlNoEstimate
            SELECT FIELDS
            SET ORDER TO cfieldname
            IF SEEK (UPPER(m.cfieldname))
                SCATTER MEMVAR
            ELSE
* We're including estimates so if there's no field record we can't estimate
                LOOP
            ENDIF
            m.npct0  = 0
            m.npct1  = m.nyear1pct
            m.npct2  = m.nyear2pct
            m.npct3  = m.nyear3pct
            m.npct4  = m.nyear4pct
            m.npct5  = m.nyear5pct
            m.npct6  = m.nyear6pct
            m.npct7  = m.nyear7pct
            m.npct8  = m.nyear8pct
            m.npct9  = m.nyear9pct
            m.npct10 = m.nyear10pct
            m.npct11 = m.nyear11pct
            m.npct12 = m.nyear12pct

            SELECT decline
            REPLACE cfieldname WITH m.cfieldname
*
*  Start the estimating process for the decline curve.
*  If the year has no production entered, we estimate it based upon the declines
*  given for the field.  We have to assume that year0 has some actual
*  production.
*
            IF m.lEst1 = .T.
                m.nbbl1 = m.nbbl0 - (m.nbbl0 * (m.nyear1pct / 100))
                m.nmcf1 = m.nmcf0 - (m.nmcf0 * (m.nyear1pct / 100))
                IF tnDecType = 1
                    m.ncashrcv1 = ROUND(m.ncashrcv0 - (m.ncashrcv0 * (m.nyear1pct / 100)), 0)
                    m.ncashtot1 = m.ncashtot0 + m.ncashrcv1
                    m.nExp1     = m.nExp0
                ELSE
                    DO CASE
                        CASE m.nbblpct1 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct1) / 100))
                        CASE m.nbblpct1 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct1) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct1 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct1) / 100))
                        CASE m.nmcfpct1 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct1) / 100))
                    ENDCASE
                    m.ncashrcv1 = ROUND((m.nbbl1 * m.navgbblprc) + (m.nmcf1 * m.navgmcfprc), 0)
                    m.ncashtot1 = m.ncashtot0 + m.ncashrcv1
                    m.nExp1     = m.nExp0
                ENDIF
                REPLACE ncashrcv1 WITH m.ncashrcv1, ;
                    nExp1     WITH m.nExp1, ;
                    nbbl1     WITH m.nbbl1, ;
                    nmcf1     WITH m.nmcf1, ;
                    lEst1     WITH .T., ;
                    npct1     WITH m.npct1, ;
                    ntotpay   WITH m.ncashtot1
            ENDIF

            IF m.lEst2 = .T. AND tnYears >= 2
                m.nbbl2 = m.nbbl1 - (m.nbbl1 * (m.nyear2pct / 100))
                m.nmcf2 = m.nmcf1 - (m.nmcf1 * (m.nyear2pct / 100))
                IF tnDecType = 1
                    m.ncashrcv2 = ROUND(((m.ncashrcv0 + m.ncashrcv1) / 2) * ((100 - m.nyear2pct) / 100), 0)
                    m.ncashtot2 = m.ncashtot1 + m.ncashrcv2
                    m.nExp2     = (m.nExp0 + m.nExp1) / 2
                ELSE
                    DO CASE
                        CASE m.nbblpct2 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct2) / 100))
                        CASE m.nbblpct2 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct2) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct2 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct2) / 100))
                        CASE m.nmcfpct2 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct2) / 100))
                    ENDCASE
                    m.ncashrcv2 = ROUND((m.nbbl2 * m.navgbblprc) + (m.nmcf2 * m.navgmcfprc), 0)
                    m.ncashtot2 = m.ncashtot1 + m.ncashrcv2
                    m.nExp2     = (m.nExp0 + m.nExp1) / 2
                ENDIF
                REPLACE ncashrcv2 WITH m.ncashrcv2, ;
                    nExp2     WITH m.nExp2, ;
                    nbbl2     WITH m.nbbl2, ;
                    nmcf2     WITH m.nmcf2, ;
                    lEst2     WITH .T., ;
                    npct2     WITH m.npct2, ;
                    ntotpay   WITH m.ncashtot2
            ENDIF

            IF m.lEst3 = .T. AND tnYears >= 3
                m.nbbl3 = m.nbbl2 - (m.nbbl2 * (m.nyear3pct / 100))
                m.nmcf3 = m.nmcf2 - (m.nmcf2 * (m.nyear3pct / 100))
                IF tnDecType = 1
                    m.ncashrcv3 = ROUND(((m.ncashrcv0 + m.ncashrcv1 + m.ncashrcv2) / 3) * ((100 - m.nyear3pct) / 100), 0)
                    m.ncashtot3 = m.ncashtot2 + m.ncashrcv3
                    m.nExp3     = (m.nExp0 + m.nExp1 + m.nExp2) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct3 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct3) / 100))
                        CASE m.nbblpct3 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct3) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct3 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct3) / 100))
                        CASE m.nmcfpct3 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct3) / 100))
                    ENDCASE
                    m.ncashrcv3 = ROUND((m.nbbl3 * m.navgbblprc) + (m.nmcf3 * m.navgmcfprc), 0)
                    m.ncashtot3 = m.ncashtot2 + m.ncashrcv3
                    m.nExp3     = (m.nExp0 + m.nExp1 + m.nExp2) / 3
                ENDIF
                REPLACE ncashrcv3 WITH m.ncashrcv3, ;
                    nExp3     WITH m.nExp3, ;
                    nbbl3     WITH m.nbbl3, ;
                    nmcf3     WITH m.nmcf3, ;
                    lEst3     WITH .T., ;
                    npct3     WITH m.npct3, ;
                    ntotpay   WITH m.ncashtot3
            ENDIF

            IF m.lEst4 = .T. AND tnYears >= 4
                m.nbbl4 = m.nbbl3 - (m.nbbl3 * (m.nyear4pct / 100))
                m.nmcf4 = m.nmcf3 - (m.nmcf3 * (m.nyear4pct / 100))
                IF tnDecType = 1
                    m.ncashrcv4 = ROUND(((m.ncashrcv1 + m.ncashrcv2 + m.ncashrcv3) / 3) * ((100 - m.nyear4pct) / 100), 0)
                    m.ncashtot4 = m.ncashtot3 + m.ncashrcv4
                    m.nExp4     = (m.nExp1 + m.nExp2 + m.nExp3) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct4 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct4) / 100))
                        CASE m.nbblpct4 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct4) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct4 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct4) / 100))
                        CASE m.nmcfpct4 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct4) / 100))
                    ENDCASE
                    m.ncashrcv4 = ROUND((m.nbbl4 * m.navgbblprc) + (m.nmcf4 * m.navgmcfprc), 0)
                    m.ncashtot4 = m.ncashtot3 + m.ncashrcv4
                    m.nExp4     = (m.nExp1 + m.nExp2 + m.nExp3) / 3
                ENDIF
                REPLACE ncashrcv4 WITH m.ncashrcv4, ;
                    nExp4     WITH m.nExp4, ;
                    nbbl4     WITH m.nbbl4, ;
                    nmcf4     WITH m.nmcf4, ;
                    lEst4     WITH .T., ;
                    npct4     WITH m.npct4, ;
                    ntotpay   WITH m.ncashtot4
            ENDIF

            IF m.lEst5 = .T. AND tnYears >= 5
                m.nbbl5 = m.nbbl4 - (m.nbbl4 * (m.nyear5pct / 100))
                m.nmcf5 = m.nmcf4 - (m.nmcf4 * (m.nyear5pct / 100))
                IF tnDecType = 1
                    m.ncashrcv5 = ROUND(((m.ncashrcv2 + m.ncashrcv3 + m.ncashrcv4) / 3) * ((100 - m.nyear5pct) / 100), 0)
                    m.ncashtot5 = m.ncashtot4 + m.ncashrcv5
                    m.nExp5     = (m.nExp2 + m.nExp3 + m.nExp4) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct5 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct5) / 100))
                        CASE m.nbblpct5 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct5) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct5 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct5) / 100))
                        CASE m.nmcfpct5 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct5) / 100))
                    ENDCASE
                    m.ncashrcv5 = ROUND((m.nbbl5 * m.navgbblprc) + (m.nmcf5 * m.navgmcfprc), 0)
                    m.ncashtot5 = m.ncashtot4 + m.ncashrcv5
                    m.nExp5     = (m.nExp2 + m.nExp3 + m.nExp4) / 3
                ENDIF
                REPLACE ncashrcv5 WITH m.ncashrcv5, ;
                    nExp5     WITH m.nExp5, ;
                    nbbl5     WITH m.nbbl5, ;
                    nmcf5     WITH m.nmcf5, ;
                    lEst5     WITH .T., ;
                    npct5     WITH m.npct5, ;
                    ntotpay   WITH m.ncashtot5
            ENDIF

            IF m.lEst6 = .T. AND tnYears >= 6
                m.nbbl6 = m.nbbl5 - (m.nbbl5 * (m.nyear6pct / 100))
                m.nmcf6 = m.nmcf5 - (m.nmcf5 * (m.nyear6pct / 100))
                IF tnDecType = 1
                    m.ncashrcv6 = ROUND(((m.ncashrcv3 + m.ncashrcv4 + m.ncashrcv5) / 3) * ((100 - m.nyear6pct) / 100), 0)
                    m.ncashtot6 = m.ncashtot5 + m.ncashrcv6
                    m.nExp6     = (m.nExp3 + m.nExp4 + m.nExp5) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct6 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct6) / 100))
                        CASE m.nbblpct6 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct6) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct6 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct6) / 100))
                        CASE m.nmcfpct6 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct6) / 100))
                    ENDCASE
                    m.ncashrcv6 = ROUND((m.nbbl6 * m.navgbblprc) + (m.nmcf6 * m.navgmcfprc), 0)
                    m.ncashtot6 = m.ncashtot5 + m.ncashrcv6
                    m.nExp6     = (m.nExp3 + m.nExp4 + m.nExp5) / 3
                ENDIF
                REPLACE ncashrcv6 WITH m.ncashrcv6, ;
                    nExp6     WITH m.nExp6, ;
                    nbbl6     WITH m.nbbl6, ;
                    nmcf6     WITH m.nmcf6, ;
                    lEst6     WITH .T., ;
                    npct6     WITH m.npct6, ;
                    ntotpay   WITH m.ncashtot6
            ENDIF

            IF m.lEst7 = .T. AND tnYears >= 7
                m.nbbl7 = m.nbbl6 - (m.nbbl6 * (m.nyear7pct / 100))
                m.nmcf7 = m.nmcf6 - (m.nmcf6 * (m.nyear7pct / 100))
                IF tnDecType = 1
                    m.ncashrcv7 = ROUND(((m.ncashrcv4 + m.ncashrcv5 + m.ncashrcv6) / 3) * ((100 - m.nyear7pct) / 100), 0)
                    m.ncashtot7 = m.ncashtot6 + m.ncashrcv7
                    m.nExp7     = (m.nExp4 + m.nExp5 + m.nExp6) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct7 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct7) / 100))
                        CASE m.nbblpct7 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct7) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct7 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct7) / 100))
                        CASE m.nmcfpct7 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct7) / 100))
                    ENDCASE
                    m.ncashrcv7 = ROUND((m.nbbl7 * m.navgbblprc) + (m.nmcf7 * m.navgmcfprc), 0)
                    m.ncashtot7 = m.ncashtot6 + m.ncashrcv7
                    m.nExp7     = (m.nExp4 + m.nExp5 + m.nExp6) / 3
                ENDIF
                REPLACE ncashrcv7 WITH m.ncashrcv7, ;
                    nExp7     WITH m.nExp7, ;
                    nbbl7     WITH m.nbbl7, ;
                    nmcf7     WITH m.nmcf7, ;
                    lEst7     WITH .T., ;
                    npct7     WITH m.npct7, ;
                    ntotpay   WITH m.ncashtot7
            ENDIF

            IF m.lEst8 = .T. AND tnYears >= 8
                m.nbbl8 = m.nbbl7 - (m.nbbl7 * (m.nyear8pct / 100))
                m.nmcf8 = m.nmcf7 - (m.nmcf7 * (m.nyear8pct / 100))
                IF tnDecType = 1
                    m.ncashrcv8 = ROUND(((m.ncashrcv5 + m.ncashrcv6 + m.ncashrcv7) / 3) * ((100 - m.nyear8pct) / 100), 0)
                    m.ncashtot8 = m.ncashtot7 + m.ncashrcv8
                    m.nExp8     = (m.nExp5 + m.nExp6 + m.nExp7) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct8 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct8) / 100))
                        CASE m.nbblpct8 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct8) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct8 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct8) / 100))
                        CASE m.nmcfpct8 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct8) / 100))
                    ENDCASE
                    m.ncashrcv8 = ROUND((m.nbbl8 * m.navgbblprc) + (m.nmcf8 * m.navgmcfprc), 0)
                    m.ncashtot8 = m.ncashtot7 + m.ncashrcv8
                    m.nExp8     = (m.nExp5 + m.nExp6 + m.nExp7) / 3
                ENDIF
                REPLACE ncashrcv8 WITH m.ncashrcv8, ;
                    nExp8     WITH m.nExp8, ;
                    nbbl8     WITH m.nbbl8, ;
                    nmcf8     WITH m.nmcf8, ;
                    lEst8     WITH .T., ;
                    npct8     WITH m.npct8, ;
                    ntotpay   WITH m.ncashtot8
            ENDIF

            IF m.lEst9 = .T. AND tnYears >= 9
                m.nbbl9 = m.nbbl8 - (m.nbbl8 * (m.nyear9pct / 100))
                m.nmcf9 = m.nmcf8 - (m.nmcf8 * (m.nyear9pct / 100))
                IF tnDecType = 1
                    m.ncashrcv9 = ROUND(((m.ncashrcv8 + m.ncashrcv7 + m.ncashrcv6) / 3) * ((100 - m.nyear9pct) / 100), 0)
                    m.ncashtot9 = m.ncashtot8 + m.ncashrcv9
                    m.nExp9     = (m.nExp6 + m.nExp7 + m.nExp8) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct9 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct9) / 100))
                        CASE m.nbblpct9 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct9) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct9 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct9) / 100))
                        CASE m.nmcfpct9 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct9) / 100))
                    ENDCASE
                    m.ncashrcv9 = ROUND((m.nbbl9 * m.navgbblprc) + (m.nmcf9 * m.navgmcfprc), 0)
                    m.ncashtot9 = m.ncashtot8 + m.ncashrcv9
                    m.nExp9     = (m.nExp6 + m.nExp7 + m.nExp8) / 3
                ENDIF
                REPLACE ncashrcv9 WITH m.ncashrcv9, ;
                    nExp9     WITH m.nExp9, ;
                    nbbl9     WITH m.nbbl9, ;
                    nmcf9     WITH m.nmcf9, ;
                    lEst9     WITH .T., ;
                    npct9     WITH m.npct9, ;
                    ntotpay   WITH m.ncashtot9
            ENDIF

            IF m.lEst10 = .T. AND tnYears >= 10
                m.nbbl10 = m.nbbl9 - (m.nbbl9 * (m.nyear10pct / 100))
                m.nmcf10 = m.nmcf9 - (m.nmcf9 * (m.nyear10pct / 100))
                IF tnDecType = 1
                    m.ncashrcv10 = ROUND(((m.ncashrcv9 + m.ncashrcv8 + m.ncashrcv7) / 3) * ((100 - m.nyear10pct) / 100), 0)
                    m.ncashtot10 = m.ncashtot9 + m.ncashrcv10
                    m.nExp10     = (m.nExp7 + m.nExp8 + m.nExp9) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct10 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct10) / 100))
                        CASE m.nbblpct10 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct10) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct10 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct10) / 100))
                        CASE m.nmcfpct10 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct10) / 100))
                    ENDCASE
                    m.ncashrcv10 = ROUND((m.nbbl10 * m.navgbblprc) + (m.nmcf10 * m.navgmcfprc), 0)
                    m.ncashtot10 = m.ncashtot9 + m.ncashrcv10
                    m.nExp10     = (m.nExp7 + m.nExp8 + m.nExp9) / 3
                ENDIF
                REPLACE ncashrcv10 WITH m.ncashrcv10, ;
                    nExp10     WITH m.nExp10, ;
                    nbbl10     WITH m.nbbl10, ;
                    nmcf10     WITH m.nmcf10, ;
                    lEst10     WITH .T., ;
                    npct10     WITH m.npct10, ;
                    ntotpay    WITH m.ncashtot10
            ENDIF

            IF m.lEst11 = .T. AND tnYears >= 11
                m.nbbl11 = m.nbbl10 - (m.nbbl10 * (m.nyear11pct / 100))
                m.nmcf11 = m.nmcf10 - (m.nmcf10 * (m.nyear11pct / 100))
                IF tnDecType = 1
                    m.ncashrcv11 = ROUND(((m.ncashrcv10 + m.ncashrcv9 + m.ncashrcv8) / 3) * ((100 - m.nyear11pct) / 100), 0)
                    m.ncashtot11 = m.ncashtot10 + m.ncashrcv11
                    m.nExp11     = (m.nExp8 + m.nExp9 + m.nExp10) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct11 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct11) / 100))
                        CASE m.nbblpct11 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct11) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct11 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct11) / 100))
                        CASE m.nmcfpct11 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct11) / 100))
                    ENDCASE
                    m.ncashrcv11 = ROUND((m.nbbl11 * m.navgbblprc) + (m.nmcf11 * m.navgmcfprc), 0)
                    m.ncashtot11 = m.ncashtot10 + m.ncashrcv11
                    m.nExp11     = (m.nExp8 + m.nExp9 + m.nExp10) / 3
                ENDIF
                REPLACE ncashrcv11 WITH m.ncashrcv11, ;
                    nExp11     WITH m.nExp11, ;
                    nbbl11     WITH m.nbbl11, ;
                    nmcf11     WITH m.nmcf11, ;
                    lEst11     WITH .T., ;
                    npct11     WITH m.npct11, ;
                    ntotpay    WITH m.ncashtot11
            ENDIF

            IF m.lEst12 = .T. AND tnYears >= 12
                m.nbbl12 = m.nbbl11 - (m.nbbl11 * (m.nyear12pct / 100))
                m.nmcf12 = m.nmcf11 - (m.nmcf11 * (m.nyear12pct / 100))
                IF tnDecType = 1
                    m.ncashrcv12 = ROUND(((m.ncashrcv11 + m.ncashrcv10 + m.ncashrcv9) / 3) * ((100 - m.nyear12pct) / 100), 0)
                    m.ncashtot12 = m.ncashtot11 + m.ncashrcv12
                    m.nExp12     = (m.nExp9 + m.nExp10 + m.nExp11) / 3
                ELSE
                    DO CASE
                        CASE m.nbblpct12 < 0
                            m.navgbblprc = m.navgbblprc - (m.navgbblprc * (ABS(m.nbblpct12) / 100))
                        CASE m.nbblpct12 > 0
                            m.navgbblprc = m.navgbblprc + (m.navgbblprc * (ABS(m.nbblpct12) / 100))
                    ENDCASE
                    DO CASE
                        CASE m.nmcfpct12 < 0
                            m.navgmcfprc = m.navgmcfprc - (m.navgmcfprc * (ABS(m.nmcfpct12) / 100))
                        CASE m.nmcfpct12 > 0
                            m.navgmcfprc = m.navgmcfprc + (m.navgmcfprc * (ABS(m.nmcfpct12) / 100))
                    ENDCASE
                    m.ncashrcv12 = ROUND((m.nbbl12 * m.navgbblprc) + (m.nmcf12 * m.navgmcfprc), 0)
                    m.ncashtot12 = m.ncashtot11 + m.ncashrcv12
                    m.nExp12     = (m.nExp9 + m.nExp10 + m.nExp11) / 3
                ENDIF
                REPLACE ncashrcv12 WITH m.ncashrcv12, ;
                    nExp12     WITH m.nExp12, ;
                    nbbl12     WITH m.nbbl12, ;
                    nmcf12     WITH m.nmcf12, ;
                    lEst12     WITH .T., ;
                    npct12     WITH m.npct12, ;
                    ntotpay    WITH m.ncashtot12
            ENDIF

        ENDIF
*
*  Calculate the net cash received for year0
*
        SELECT decline
        m.ncashrcv0 = ROUND(m.ncashrcv0 - nExp0 - n1Time0, 0)
        m.ncashtot0 = m.ncashrcv0
        REPLACE ncashrcv0 WITH m.ncashrcv0, ;
            ncashtot0 WITH m.ncashtot0, ;
            ntotpay   WITH m.ncashtot0

*
*  Calculate the net cash received for year1
*
        SELECT decline
        m.ncashrcv1 = ROUND(m.ncashrcv1 - nExp1 - n1Time1, 0)
        m.ncashtot1 = m.ncashtot0 + m.ncashrcv1
        REPLACE ncashrcv1 WITH m.ncashrcv1, ;
            ncashtot1 WITH m.ncashtot1, ;
            ntotpay   WITH m.ncashtot1

*
*  Calculate the net cash received for year2
*
        SELECT decline
        m.ncashrcv2 = ROUND(m.ncashrcv2 - nExp2 - n1Time2, 0)
        m.ncashtot2 = m.ncashtot1 + m.ncashrcv2
        REPLACE ncashrcv2 WITH m.ncashrcv2, ;
            ncashtot2 WITH m.ncashtot2, ;
            ntotpay   WITH m.ncashtot2

*
*  Calculate the net cash received for year3
*
        SELECT decline
        m.ncashrcv3 = ROUND(m.ncashrcv3 - nExp3 - n1Time3, 0)
        m.ncashtot3 = m.ncashtot2 + m.ncashrcv3
        REPLACE ncashrcv3 WITH m.ncashrcv3, ;
            ncashtot3 WITH m.ncashtot3, ;
            ntotpay   WITH m.ncashtot3


*
*  Calculate the net cash received for year4
*
        SELECT decline
        m.ncashrcv4 = ROUND(m.ncashrcv4 - nExp4 - n1Time4, 0)
        m.ncashtot4 = m.ncashtot3 + m.ncashrcv4
        REPLACE ncashrcv4 WITH m.ncashrcv4, ;
            ncashtot4 WITH m.ncashtot4, ;
            ntotpay   WITH m.ncashtot4

*
*  Calculate the net cash received for year5
*
        SELECT decline
        m.ncashrcv5 = ROUND(m.ncashrcv5 - nExp5 - n1Time5, 0)
        m.ncashtot5 = m.ncashtot4 + m.ncashrcv5
        REPLACE ncashrcv5 WITH m.ncashrcv5, ;
            ncashtot5 WITH m.ncashtot5, ;
            ntotpay   WITH m.ncashtot5


*
*  Calculate the net cash received for year6
*
        SELECT decline
        m.ncashrcv6 = ROUND(m.ncashrcv6 - nExp6 - n1Time6, 0)
        m.ncashtot6 = m.ncashtot5 + m.ncashrcv6
        REPLACE ncashrcv6 WITH m.ncashrcv6, ;
            ncashtot6 WITH m.ncashtot6, ;
            ntotpay   WITH m.ncashtot6


*
*  Calculate the net cash received for year7
*
        SELECT decline
        m.ncashrcv7 = ROUND(m.ncashrcv7 - nExp7 - n1Time7, 0)
        m.ncashtot7 = m.ncashtot6 + m.ncashrcv7
        REPLACE ncashrcv7 WITH m.ncashrcv7, ;
            ncashtot7 WITH m.ncashtot7, ;
            ntotpay   WITH m.ncashtot7


*
*  Calculate the net cash received for year8
*
        SELECT decline
        m.ncashrcv8 = ROUND(m.ncashrcv8 - nExp8 - n1Time8, 0)
        m.ncashtot8 = m.ncashtot7 + m.ncashrcv8
        REPLACE ncashrcv8 WITH m.ncashrcv8, ;
            ncashtot8 WITH m.ncashtot8, ;
            ntotpay   WITH m.ncashtot8


*
*  Calculate the net cash received for year9
*
        SELECT decline
        m.ncashrcv9 = ROUND(m.ncashrcv9 - nExp9 - n1Time9, 0)
        m.ncashtot9 = m.ncashtot8 + m.ncashrcv9
        REPLACE ncashrcv9 WITH m.ncashrcv9, ;
            ncashtot9 WITH m.ncashtot9, ;
            ntotpay   WITH m.ncashtot9


*
*  Calculate the net cash received for year10
*
        SELECT decline
        m.ncashrcv10 = ROUND(m.ncashrcv10 - nExp10 - n1Time10, 0)
        m.ncashtot10 = m.ncashtot9 + m.ncashrcv10
        REPLACE ncashrcv10 WITH m.ncashrcv10, ;
            ncashtot10 WITH m.ncashtot10, ;
            ntotpay   WITH m.ncashtot10


*
*  Calculate the net cash received for year11
*
        SELECT decline
        m.ncashrcv11 = ROUND(m.ncashrcv11 - nExp11 - n1Time11, 0)
        m.ncashtot11 = m.ncashtot10 + m.ncashrcv11
        REPLACE ncashrcv11 WITH m.ncashrcv11, ;
            ncashtot11 WITH m.ncashtot11, ;
            ntotpay   WITH m.ncashtot11

*
*  Calculate the net cash received for year12
*
        SELECT decline
        m.ncashrcv12 = ROUND(m.ncashrcv12 - nExp12 - n1Time12, 0)
        m.ncashtot12 = m.ncashtot11 + m.ncashrcv12
        REPLACE ncashrcv12 WITH m.ncashrcv12, ;
            ncashtot12 WITH m.ncashtot12, ;
            ntotpay   WITH m.ncashtot12

    ENDSCAN

    oProgress.CloseProgress()
    oProgress = oMessage.ProgressBar('Calculating Report, Stage 3...')

    SELECT decline
    COUNT FOR NOT DELETED() TO lnMax
    lnCount = 1
    oProgress.SetProgressRange(0, lnMax)

*
*  Add up the total current cash received to display on the report.
*
    SELECT decline
    GO TOP
    SCAN
        SCATTER MEMVAR
        oProgress.UpdateProgress(lnCount)
        lnCount   = lnCount + 1
        m.ncurpay = m.ncashrcv0
        IF NOT lEst1
            m.ncurpay = m.ncurpay + m.ncashrcv1
        ENDIF
        IF NOT lEst2
            m.ncurpay = m.ncurpay + m.ncashrcv2
        ENDIF
        IF NOT lEst3
            m.ncurpay = m.ncurpay + m.ncashrcv3
        ENDIF
        IF NOT lEst4
            m.ncurpay = m.ncurpay + m.ncashrcv4
        ENDIF
        IF NOT lEst5
            m.ncurpay = m.ncurpay + m.ncashrcv5
        ENDIF
        IF NOT lEst6
            m.ncurpay = m.ncurpay + m.ncashrcv6
        ENDIF
        IF NOT lEst7
            m.ncurpay = m.ncurpay + m.ncashrcv7
        ENDIF
        IF NOT lEst8
            m.ncurpay = m.ncurpay + m.ncashrcv8
        ENDIF
        IF NOT lEst9
            m.ncurpay = m.ncurpay + m.ncashrcv9
        ENDIF
        IF NOT lEst10
            m.ncurpay = m.ncurpay + m.ncashrcv10
        ENDIF
        IF NOT lEst11
            m.ncurpay = m.ncurpay + m.ncashrcv11
        ENDIF
        IF NOT lEst12
            m.ncurpay = m.ncurpay + m.ncashrcv12
        ENDIF
        REPLACE ncurpay WITH m.ncurpay
*
*  Don't perpetuate negative income
*  Zero it out in years forecasted
*
        IF m.ncashrcv0 < 0 AND m.lEst1 OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear0)
            m.ntotpay = m.ncashtot0
            STORE 0 TO m.ncashrcv1, m.ncashrcv2, m.ncashrcv3, m.ncashrcv4, m.ncashrcv5, ;
                m.ncashrcv6, m.ncashrcv7, m.ncashrcv8, m.ncashrcv9, m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot1, m.ncashtot2, m.ncashtot3, m.ncashtot4, ;
                m.ncashtot5, m.ncashtot6, m.ncashtot7, m.ncashtot8, ;
                m.ncashtot9, m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl1, m.nbbl2, m.nbbl3, m.nbbl4, m.nbbl5, m.nbbl6, ;
                m.nbbl7, m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf1, m.nmcf2, m.nmcf3, m.nmcf4, m.nmcf5, m.nmcf6, ;
                m.nmcf7, m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv0 < 0 AND m.ncashrcv1 < 0) AND m.lEst2) ;
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear1)
            m.ntotpay = m.ncashtot1
            STORE 0 TO m.ncashrcv2, m.ncashrcv3, m.ncashrcv4, m.ncashrcv5, ;
                m.ncashrcv6, m.ncashrcv7, m.ncashrcv8, m.ncashrcv9, m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot2, m.ncashtot3, m.ncashtot4, ;
                m.ncashtot5, m.ncashtot6, m.ncashtot7, m.ncashtot8, ;
                m.ncashtot9, m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl2, m.nbbl3, m.nbbl4, m.nbbl5, m.nbbl6, ;
                m.nbbl7, m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf2, m.nmcf3, m.nmcf4, m.nmcf5, m.nmcf6, ;
                m.nmcf7, m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv1 < 0 AND m.ncashrcv2 < 0) AND m.lEst3) ;
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear2)
            m.ntotpay = m.ncashtot2
            STORE 0 TO m.ncashrcv3, m.ncashrcv4, m.ncashrcv5, ;
                m.ncashrcv6, m.ncashrcv7, m.ncashrcv8, m.ncashrcv9, m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot3, m.ncashtot4, ;
                m.ncashtot5, m.ncashtot6, m.ncashtot7, m.ncashtot8, ;
                m.ncashtot9, m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl3, m.nbbl4, m.nbbl5, m.nbbl6, ;
                m.nbbl7, m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf3, m.nmcf4, m.nmcf5, m.nmcf6, ;
                m.nmcf7, m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv2 < 0 AND m.ncashrcv3 < 0) AND m.lEst4) ;
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear3)
            m.ntotpay = m.ncashtot3
            STORE 0 TO m.ncashrcv4, m.ncashrcv5, ;
                m.ncashrcv6, m.ncashrcv7, m.ncashrcv8, m.ncashrcv9, m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot4, ;
                m.ncashtot5, m.ncashtot6, m.ncashtot7, m.ncashtot8, ;
                m.ncashtot9, m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl4, m.nbbl5, m.nbbl6, ;
                m.nbbl7, m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf4, m.nmcf5, m.nmcf6, ;
                m.nmcf7, m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv3 < 0 AND m.ncashrcv4 < 0) AND m.lEst5) ;
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear4)
            m.ntotpay = m.ncashtot4
            STORE 0 TO m.ncashrcv5, ;
                m.ncashrcv6, m.ncashrcv7, m.ncashrcv8, m.ncashrcv9, m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot5, m.ncashtot6, m.ncashtot7, m.ncashtot8, ;
                m.ncashtot9, m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl5, m.nbbl6, ;
                m.nbbl7, m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf5, m.nmcf6, ;
                m.nmcf7, m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv4 < 0 AND m.ncashrcv5 < 0) AND m.lEst6);
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear5)
            m.ntotpay = m.ncashtot5
            STORE 0 TO m.ncashrcv6, m.ncashrcv7, m.ncashrcv8, m.ncashrcv9, m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot6, m.ncashtot7, m.ncashtot8, ;
                m.ncashtot9, m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl6, ;
                m.nbbl7, m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf6, ;
                m.nmcf7, m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv5 < 0 AND m.ncashrcv6 < 0) AND m.lEst7) ;
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear6)
            m.ntotpay = m.ncashtot6
            STORE 0 TO m.ncashrcv7, m.ncashrcv8, m.ncashrcv9, m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot7, m.ncashtot8, ;
                m.ncashtot9, m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl7, m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf7, m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv6 < 0 AND m.ncashrcv7 < 0) AND m.lEst8) ;
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear7)
            m.ntotpay = m.ncashtot7
            STORE 0 TO m.ncashrcv8, m.ncashrcv9, m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot8, ;
                m.ncashtot9, m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl8, m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf8, m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv7 < 0 AND m.ncashrcv8 < 0) AND m.lEst9) ;
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear8)
            m.ntotpay = m.ncashtot8
            STORE 0 TO m.ncashrcv9, m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot9, m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl9, m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf9, m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv8 < 0 AND m.ncashrcv9 < 0) AND m.lEst10) ;
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear9)
            m.ntotpay = m.ncashtot9
            STORE 0 TO m.ncashrcv10, ;
                m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot10, m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl10, m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf10, m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv9 < 0 AND m.ncashrcv10 < 0) AND m.lEst11);
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear10)
            m.ntotpay = m.ncashtot10
            STORE 0 TO m.ncashrcv11, m.ncashrcv12
            STORE 0 TO m.ncashtot11, m.ncashtot12
            STORE 0 TO m.nbbl11, m.nbbl12
            STORE 0 TO m.nmcf11, m.nmcf12
        ENDIF
        IF ((m.ncashrcv10 < 0 AND m.ncashrcv11 < 0) AND m.lEst12) ;
                OR (INLIST(m.cstatus, 'S', 'P') AND STR(YEAR(m.dsold), 4) = m.cyear11)
            m.ntotpay = m.ncashtot11
            STORE 0 TO m.ncashrcv12
            STORE 0 TO m.ncashtot12
            STORE 0 TO m.nbbl12
            STORE 0 TO m.nmcf12
        ENDIF
        REPLACE  ncashrcv1  WITH m.ncashrcv1, ;
            ncashrcv2  WITH m.ncashrcv2, ;
            ncashrcv3  WITH m.ncashrcv3, ;
            ncashrcv4  WITH m.ncashrcv4, ;
            ncashrcv5  WITH m.ncashrcv5, ;
            ncashrcv6  WITH m.ncashrcv6, ;
            ncashrcv7  WITH m.ncashrcv7, ;
            ncashrcv8  WITH m.ncashrcv8, ;
            ncashrcv9  WITH m.ncashrcv9, ;
            ncashrcv10 WITH m.ncashrcv10, ;
            ncashrcv11 WITH m.ncashrcv11, ;
            ncashrcv12 WITH m.ncashrcv12, ;
            ncashtot1  WITH m.ncashtot1, ;
            ncashtot2  WITH m.ncashtot2, ;
            ncashtot3  WITH m.ncashtot3, ;
            ncashtot4  WITH m.ncashtot4, ;
            ncashtot5  WITH m.ncashtot5, ;
            ncashtot6  WITH m.ncashtot6, ;
            ncashtot7  WITH m.ncashtot7, ;
            ncashtot8  WITH m.ncashtot8, ;
            ncashtot9  WITH m.ncashtot9, ;
            ncashtot10 WITH m.ncashtot10, ;
            ncashtot11 WITH m.ncashtot11, ;
            ncashtot12 WITH m.ncashtot12, ;
            ntotpay    WITH m.ntotpay
        REPLACE  nbbl1  WITH m.nbbl1, ;
            nbbl2  WITH m.nbbl2, ;
            nbbl3  WITH m.nbbl3, ;
            nbbl4  WITH m.nbbl4, ;
            nbbl5  WITH m.nbbl5, ;
            nbbl6  WITH m.nbbl6, ;
            nbbl7  WITH m.nbbl7, ;
            nbbl8  WITH m.nbbl8, ;
            nbbl9  WITH m.nbbl9, ;
            nbbl10 WITH m.nbbl10, ;
            nbbl11 WITH m.nbbl11, ;
            nbbl12 WITH m.nbbl12, ;
            nmcf1  WITH m.nmcf1, ;
            nmcf2  WITH m.nmcf2, ;
            nmcf3  WITH m.nmcf3, ;
            nmcf4  WITH m.nmcf4, ;
            nmcf5  WITH m.nmcf5, ;
            nmcf6  WITH m.nmcf6, ;
            nmcf7  WITH m.nmcf7, ;
            nmcf8  WITH m.nmcf8, ;
            nmcf9  WITH m.nmcf9, ;
            nmcf10 WITH m.nmcf10, ;
            nmcf11 WITH m.nmcf11, ;
            nmcf12 WITH m.nmcf12
        IF ncashtot2 = 0
            m.cyear2 = ' '
        ENDIF
        IF ncashtot3 = 0
            m.cyear3 = ' '
        ENDIF
        IF ncashtot4 = 0
            m.cyear4 = ' '
        ENDIF
        IF ncashtot5 = 0
            m.cyear5 = ' '
        ENDIF
        IF ncashtot6 = 0
            m.cyear6 = ' '
        ENDIF
        IF ncashtot7 = 0
            m.cyear7 = ' '
        ENDIF
        IF ncashtot8 = 0
            m.cyear8 = ' '
        ENDIF
        IF ncashtot9 = 0
            m.cyear9 = ' '
        ENDIF
        IF ncashtot10 = 0
            m.cyear10 = ' '
        ENDIF
        IF ncashtot11 = 0
            m.cyear11 = ' '
        ENDIF
        IF ncashtot12 = 0
            m.cyear12 = ' '
        ENDIF
        REPLACE cyear2  WITH m.cyear2, ;
            cyear3  WITH m.cyear3, ;
            cyear4  WITH m.cyear4, ;
            cyear5  WITH m.cyear5, ;
            cyear6  WITH m.cyear6, ;
            cyear7  WITH m.cyear7, ;
            cyear8  WITH m.cyear8, ;
            cyear9  WITH m.cyear9, ;
            cyear10  WITH m.cyear10, ;
            cyear11  WITH m.cyear11, ;
            cyear12  WITH m.cyear12

        IF m.ncashrcv12 = 0 AND m.ncashrcv11 = 0 AND NOT m.lest12
           REPLACE ncashtot12 WITH 0
        ENDIF
        IF m.ncashrcv11 = 0 AND m.ncashrcv10 = 0 AND NOT m.lest11
           REPLACE ncashtot11 WITH 0
        ENDIF
        IF m.ncashrcv10 = 0 AND m.ncashrcv9 = 0 AND NOT m.lest10
           REPLACE ncashtot10 WITH 0
        ENDIF
        IF m.ncashrcv9 = 0 AND m.ncashrcv8 = 0 AND NOT m.lest9
           REPLACE ncashtot9 WITH 0
        ENDIF
        IF m.ncashrcv8 = 0 AND m.ncashrcv7 = 0 AND NOT m.lest8
           REPLACE ncashtot8 WITH 0
        ENDIF
        IF m.ncashrcv7 = 0 AND m.ncashrcv6 = 0 AND NOT m.lest7
           REPLACE ncashtot7 WITH 0
        ENDIF
        IF m.ncashrcv6 = 0 AND m.ncashrcv5 = 0 AND NOT m.lest6
           REPLACE ncashtot6 WITH 0
        ENDIF
        IF m.ncashrcv5 = 0 AND m.ncashrcv4 = 0 AND NOT m.lest5
           REPLACE ncashtot5 WITH 0
        ENDIF
        IF m.ncashrcv4 = 0 AND m.ncashrcv5 = 0 AND NOT m.lest4
           REPLACE ncashtot4 WITH 0
        ENDIF
        IF m.ncashrcv3 = 0 AND m.ncashrcv4 = 0 AND NOT m.lest3
           REPLACE ncashtot3 WITH 0
        ENDIF
        IF m.ncashrcv2 = 0 AND m.ncashrcv3 = 0 AND NOT m.lest2
           REPLACE ncashtot2 WITH 0
        ENDIF
        IF m.ncashrcv1 = 0 AND m.ncashrcv2 = 0 AND NOT m.lest1
           REPLACE ncashtot1 WITH 0
        ENDIF
        

    ENDSCAN

	SELECT  investor.cownname AS cownname, wells.cwellname AS cleasename, SUM(wellinv.ninvamount) AS ninvamt ;
		FROM wells, wellinv, investor ;
		WHERE wells.cwellid = wellinv.cwellid ;
			AND wellinv.cownerid = investor.cownerid ;
			AND wellinv.ctypeinv = 'W' ;
		INTO CURSOR temp ;
		ORDER BY wellinv.cownerid, cleasename ;
		GROUP BY wellinv.cownerid, cleasename


    SELECT temp
    SCAN
        SCATTER MEMVAR
        SELECT decline
        SCAN
            IF cleasename = m.cleasename AND cownname = LEFT(m.cownname, 40)
                REPLACE ninvamt  WITH m.ninvamt
            ENDIF
        ENDSCAN
    ENDSCAN

    oProgress.CloseProgress()

    SELECT decline
*-* DELETE FOR ninvamt = 0
CATCH TO loError
    llReturn = .F.
    DO errorlog WITH 'CalcDecl', loError.LINENO, 'CalcDecl', loError.ERRORNO, loError.MESSAGE, '', loError
    MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
          'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn

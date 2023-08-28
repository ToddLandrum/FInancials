*=================================================================================
*  Program....: CALCDEPL.PRG
*  Version....: 1.0
*  Author.....: Phil W. Sherwood
*  Date.......: June 19, 1996
*  Notice.....: Copyright (c) 1994-1996 SherWare, Inc., All Rights Reserved.
*  Compiler...: FoxPro 2.6a
*) Description: Calculates depletion for selected wells for a particular year.
*  Parameters.:
*               tcOwner1  -  The first owner in the range to process.
*               tcOwner2  -  The last owner in the range to process.
*               tcYear    -  The year to calculate depletion for.
*  Changes....:
*    2/9/99     pws - Added the ability to not limit depletion
*   10/17/99    pws - Changed for visual foxpro version
*=================================================================================
LPARAMETERS tcYear, tcOwner1, tcOwner2, tlIncludeSuspense, tcWellID, tcProgCode, tlProcessed
LOCAL lnYear, m.cYear, oMessage, oProgress, lcAlias, llByWell, lnDeplRecs, m.cProgCode, lcYear

llReturn = .T.


TRY
    IF VARTYPE(tcWellID) # 'C'
        llByWell    = .F.
        m.cProgCode = ''
    ELSE
        llByWell    = .T.
        m.cProgCode = tcProgCode
    ENDIF

    lcAlias    = ALIAS()
    lnDeplRecs = 0

*
*  Make the year parameter numeric for the SQL statement
*
    lnYear = VAL(tcYear)
    lcYear = tcYear

*  Get the message object
    oMessage = FindGlobalObject('cmMessage')

*  Build the progress bar object
    IF NOT llByWell
        oProgress = oMessage.ProgressBar('Building Depletion Data...')
        lcOWhere = ".T."
        lcSWhere = ".T."
        lcWWhere = ".T."
    ELSE
        lcOWhere = "disbhist.cwellid == tcWellID"
        lcSWhere = "suspense.cwellid == tcWellID"    
        lcWWhere = "wellhist.cwellid == tcWellID"
    ENDIF
    

*  Create work cursor for reporting
*
    CREATE CURSOR tempdepl ;
        (cleasename  C(30),   ;
          cidlease    C(10),   ;
          cownerid    C(10),   ;
          cownname    C(40),   ;
          cowntype    C(1),    ;
          cProgCode   C(10),   ;
          cYear       C(4),    ;
          cMarginal   C(1),    ;
          nMargPct    N(4, 2),  ;
          nNonPct     N(4, 2),  ;
          ninvamount  N(12, 2), ;
          dinvdate    D,       ;
          nintanpct   N(11, 7), ;
          nintanamt   N(12, 2), ;
          ntanpct     N(11, 7), ;
          ntanamt     N(12, 2), ;
          nTotMCF     N(12, 4), ;
          nTotBBL     N(12, 4), ;
          nBBLDay     N(12, 2), ;
          nGrossInc   N(12, 2), ;
          nIntDrill   N(12, 2), ;
          nIndExp     N(12, 2), ;
          nDirExp     N(12, 2), ;
          nIDCExp     N(12, 2), ;
          nDeprExp    N(12, 2), ;
          nNetInc     N(12, 2), ;
          nNetIncLim  N(12, 2), ;
          nDeplpct    N(4, 2), ;
          nDepl       N(12, 2), ;
          nTentDepl   N(12, 2), ;
          nTotDepl    N(12, 2), ;
          nCostDepl   N(12, 2), ;
          nPctOwned   N(11, 7), ;
          nMCFShare   N(12, 2), ;
          nMCFInt     N(11, 7), ;
          nWorkInt     N(11, 7), ;
          nMCFBBL     N(12, 2))
    INDEX ON cownerid + cowntype + cleasename TAG cownerid
    INDEX ON cowntype + cleasename TAG well
    INDEX ON cownname + cowntype  TAG PROD
    INDEX ON cownname + cowntype + cleasename TAG prodwell

   SELECT tempdepl
   SCATTER MEMVAR blank 

	SELECT  disbhist.cwellid  AS cidlease, ;
			disbhist.cownerid, ;
			investor.cownname AS cownname, ;
			disbhist.ctypeinv AS cowntype, ;
			wells.cwellname AS cleasename, ;
			tcProgCode      AS cProgCode, ;
			tcYear AS cYear, ;
			000000000.00 AS nGrossInc, ;
			000000.00    AS nTotMCF, ;
			000000.00    AS nTotBBL, ;
			000000000.00 AS nDirExp, ;
			MAX(ownpcts.nWorkInt) AS nPctOwned, ;
			MAX(ownpcts.nrevgas)  AS nMCFInt,   ;
			MAX(ownpcts.nWorkInt) AS nWorkInt,  ;
			000000.00 AS nMCFShare ;
		FROM disbhist, ownpcts, wells, investor ;
		WHERE (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nrunno), 3, '0')+disbhist.crectype IN   ;
                 (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0')+ctypeclose ;
                    FROM sysctl WHERE YEAR(dacctdate) = VAL(lcYear))) ;
			AND BETWEEN (disbhist.cownerid, tcOwner1, tcOwner2) ;
			AND disbhist.ciddisb == ownpcts.ciddisb ;
			AND &lcOWhere ;
			AND disbhist.cwellid = wells.cwellid ;
			AND disbhist.cownerid = investor.cownerid ;
		INTO CURSOR temp1 READWRITE ;
		ORDER BY disbhist.cownerid, disbhist.ctypeinv, disbhist.cwellid ;
		GROUP BY disbhist.cownerid, disbhist.ctypeinv, disbhist.cwellid

	SELECT  disbhist.cwellid  AS cidlease, ;
			disbhist.cownerid, ;
			investor.cownname AS cownname, ;
			disbhist.ctypeinv AS cowntype, ;
			wells.cwellname AS cleasename, ;
			tcProgCode      AS cProgCode, ;
			tcYear AS cYear, ;
			000000000.00 AS nGrossInc, ;
			000000.00    AS nTotMCF, ;
			000000.00    AS nTotBBL, ;
			000000000.00 AS nDirExp, ;
			MAX(ownpcts.nWorkInt) AS nPctOwned, ;
			MAX(ownpcts.nrevgas)  AS nMCFInt,   ;
			MAX(ownpcts.nWorkInt) AS nWorkInt,  ;
			000000.00 AS nMCFShare ;
		FROM disbhist, ownpcts, wells, investor ;
		WHERE NOT EMPTY(csusptype) ;
			AND disbhist.crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') + crectype IN ;
			(SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') + 'R' ;
				 FROM sysctl ;
				 WHERE YEAR(dacctdate) = lnYear) ;
			AND BETWEEN (disbhist.cownerid, tcOwner1, tcOwner2) ;
			AND disbhist.ciddisb == ownpcts.ciddisb ;
			AND &lcOWhere ;
			AND disbhist.cwellid = wells.cwellid ;
			AND disbhist.cownerid = investor.cownerid ;
		INTO CURSOR temp2 ;
		ORDER BY disbhist.cownerid, disbhist.ctypeinv, disbhist.cwellid ;
		GROUP BY disbhist.cownerid, disbhist.ctypeinv, disbhist.cwellid

	SELECT  suspense.cwellid  AS cidlease, ;
			suspense.cownerid, ;
			investor.cownname AS cownname, ;
			suspense.ctypeinv AS cowntype, ;
			wells.cwellname AS cleasename, ;
			tcProgCode      AS cProgCode, ;
			tcYear AS cYear, ;
			000000000.00 AS nGrossInc, ;
			000000.00    AS nTotMCF, ;
			000000.00    AS nTotBBL, ;
			000000000.00 AS nDirExp, ;
			MAX(suspense.nWorkInt) AS nPctOwned, ;
			MAX(suspense.nrevgas)  AS nMCFInt,   ;
			MAX(suspense.nWorkInt) AS nWorkInt,  ;
			000000.00 AS nMCFShare ;
		FROM suspense, wells, investor ;
		WHERE suspense.crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') + suspense.crectype IN ;
			(SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') + 'R' ;
				 FROM sysctl ;
				 WHERE YEAR(dacctdate) = lnYear) ;
			AND &lcSWhere ;
			AND suspense.cwellid = wells.cwellid ;
			AND suspense.cownerid = investor.cownerid ;
			AND BETWEEN(suspense.cownerid, tcOwner1, tcOwner2) ;
		INTO CURSOR temp3  ;
		ORDER BY suspense.cownerid, suspense.ctypeinv, suspense.cwellid ;
		GROUP BY suspense.cownerid, suspense.ctypeinv, suspense.cwellid

    SELECT temp1
    APPEND FROM DBF('temp2')
    APPEND FROM DBF('temp3')

	SELECT  cidlease, cownerid, cownname, cowntype, cleasename, cYear, cProgCode, ;
			MAX(nWorkInt) AS nWorkInt, ;
			MAX(nMCFInt) AS nMCFInt, ;
			MAX(nPctOwned) AS nPctOwned, ;
			nGrossInc, nTotMCF, nTotBBL, nDirExp, nMCFShare ;
		FROM temp1 ;
		INTO CURSOR tempx ;
		ORDER BY cownerid, cidlease, cowntype ;
		GROUP BY cownerid, cidlease, cowntype

    lnmax = _TALLY

*
*  Append records into tempdepl cursor
*
    SELECT tempdepl
    APPEND FROM DBF('tempx')
    IF USED('tempx')
        SELECT tempx
        USE
    ENDIF

    IF NOT tlProcessed
*  Fill in the owner history totals
		SELECT  cownerid, cwellid, ctypeinv, ;
				SUM(disbhist.noilrev + disbhist.ngasrev + disbhist.ntrprev + nothrev) AS nGrossInc, ;
				SUM(disbhist.nexpense + disbhist.ntotale1 + disbhist.ntotale2 + ;
					disbhist.ntotale3 + disbhist.ntotale4 + disbhist.ntotale5 + ;
					disbhist.nsevtaxes + disbhist.ngather + disbhist.ncompress) AS nDirExp ;
			FROM disbhist ;
			WHERE (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nrunno), 3, '0')+disbhist.crectype IN   ;
                 (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0')+ctypeclose ;
                    FROM sysctl WHERE YEAR(dacctdate) = VAL(lcYear))) ;
				AND BETWEEN(cownerid, tcOwner1, tcOwner2) ;
			INTO CURSOR temphist ;
			ORDER BY cownerid, ctypeinv, cwellid ;
			GROUP BY cownerid, ctypeinv, cwellid

        IF _TALLY > 0
            SELE temphist
            SCAN
                SCATTER MEMVAR
                SELE tempdepl
                LOCATE FOR cownerid = m.cownerid AND cowntype = m.ctypeinv AND cidlease = m.cwellid
                IF FOUND()
                    REPL nGrossInc WITH ROUND(m.nGrossInc, 0), ;
                        nDirExp   WITH ROUND(m.nDirExp, 0)

                ENDIF
            ENDSCAN
        ENDIF

*
*  Fill in the suspense history totals
*

        IF tlIncludeSuspense
			SELECT  cownerid, cwellid as cidlease, ctypeinv, ;
					SUM(suspense.noilrev + suspense.ngasrev + suspense.ntrprev + nothrev) AS nGrossInc, ;
					SUM(suspense.nexpense + suspense.ntotale1 + suspense.ntotale2 + ;
						suspense.ntotale3 + suspense.ntotale4 + suspense.ntotale5 + ;
						suspense.nsevtaxes + suspense.ngather + suspense.ncompress) AS nDirExp ;
				FROM suspense ;
				WHERE  crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') + crectype IN ;
				(SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') + ctypeclose ;
					 FROM sysctl ;
					 WHERE TRANSFORM(YEAR(dacctdate)) = lcYear);
					AND &lcSWhere ;
					AND BETWEEN(cownerid, tcOwner1, tcOwner2) ;
				INTO CURSOR temphists ;
				ORDER BY cownerid, ctypeinv, cwellid ;
				GROUP BY cownerid, ctypeinv, cwellid

            IF _TALLY > 0
                SELE temphists
                SCAN
                    SCATTER MEMVAR
                    SELE tempdepl
                    LOCATE FOR cownerid = m.cownerid AND cowntype = m.ctypeinv AND cidlease = m.cidlease
                    IF FOUND()
                        REPL nGrossInc WITH nGrossInc + ROUND(m.nGrossInc, 0), ;
                            nDirExp   WITH nDirExp + ROUND(m.nDirExp, 0)
                    ELSE 
                        INSERT INTO tempdepl FROM MEMVAR 
                    ENDIF
                ENDSCAN
            ENDIF
        ENDIF

*  Fill in the total MCF
		SELECT  cwellid, SUM(nTotMCF) AS nTotMCF, SUM(nTotBBL) AS nTotBBL ;
			FROM wellhist ;
			WHERE YEAR(wellhist.hdate) = lnYear ;
				AND &lcWWhere ;
			INTO CURSOR temp ;
			ORDER BY cwellid ;
			GROUP BY cwellid

        IF _TALLY > 0
            SELECT temp
            SCAN
                SCATTER MEMVAR
                SELECT tempdepl
                SCAN FOR cidlease = m.cwellid
                    REPLACE nTotMCF WITH m.nTotMCF, ;
                        nTotBBL WITH m.nTotBBL, ;
                        nMCFShare WITH m.nTotMCF * (nMCFInt / 100)
                ENDSCAN
            ENDSCAN
        ENDIF

    ELSE

*  Fill in the owner history totals
		SELECT  cownerid, cwellid, ctypeinv, ;
				SUM(disbhist.noilrev + disbhist.ngasrev + disbhist.ntrprev + nothrev) AS nGrossInc, ;
				SUM(disbhist.nexpense + disbhist.ntotale1 + disbhist.ntotale2 + ;
					disbhist.ntotale3 + disbhist.ntotale4 + disbhist.ntotale5 + ;
					disbhist.nsevtaxes + disbhist.ngather + disbhist.ncompress) AS nDirExp ;
			FROM disbhist ;
			WHERE EMPTY(csusptype) ;
				AND crunyear + PADL(TRANSFORM(nrunno), 3, '0') + crectype IN ;
				(SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') + ctypeclose ;
					 FROM sysctl ;
					 WHERE TRANSFORM(YEAR(dacctdate)) = lcYear);
				AND &lcOWhere ;
				AND BETWEEN(cownerid, tcOwner1, tcOwner2) ;
			INTO CURSOR temphist READWRITE  ;
			ORDER BY cownerid, ctypeinv, cwellid ;
			GROUP BY cownerid, ctypeinv, cwellid


* Get the entries that were processed but went into suspense during the year
		SELECT  cownerid, cwellid, ctypeinv, ;
				SUM(disbhist.noilrev + disbhist.ngasrev + disbhist.ntrprev + nothrev) AS nGrossInc, ;
				SUM(disbhist.nexpense + disbhist.ntotale1 + disbhist.ntotale2 + ;
					disbhist.ntotale3 + disbhist.ntotale4 + disbhist.ntotale5 + ;
					disbhist.nsevtaxes + disbhist.ngather + disbhist.ncompress) AS nDirExp ;
			FROM disbhist ;
			WHERE NOT EMPTY(csusptype) ;
				AND crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') + crectype IN ;
				(SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') + ctypeclose ;
					 FROM sysctl ;
					 WHERE TRANSFORM(YEAR(dacctdate)) = lcYear);
				AND &lcOWhere ;
				AND BETWEEN(cownerid, tcOwner1, tcOwner2) ;
			INTO CURSOR temphist1  ;
			ORDER BY cownerid, ctypeinv, cwellid ;
			GROUP BY cownerid, ctypeinv, cwellid

* Get the entries that were processed but went into suspense during the year and are still in suspense
		SELECT  cownerid, cwellid, ctypeinv, ;
				SUM(suspense.noilrev + suspense.ngasrev + suspense.ntrprev + nothrev) AS nGrossInc, ;
				SUM(suspense.nexpense + suspense.ntotale1 + suspense.ntotale2 + ;
					suspense.ntotale3 + suspense.ntotale4 + suspense.ntotale5 + ;
					suspense.nsevtaxes + suspense.ngather + suspense.ncompress) AS nDirExp ;
			FROM suspense ;
			WHERE crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') + crectype IN ;
				(SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') + ctypeclose ;
					 FROM sysctl ;
					 WHERE TRANSFORM(YEAR(dacctdate)) = lcYear);
				AND &lcSWhere ;
				AND BETWEEN(cownerid, tcOwner1, tcOwner2) ;
			INTO CURSOR temphist2  ;
			ORDER BY cownerid, ctypeinv, cwellid ;
			GROUP BY cownerid, ctypeinv, cwellid

        SELECT temphist
        APPEND FROM DBF('temphist1')
        APPEND FROM DBF('temphist2')

		SELECT  cownerid, cwellid, ctypeinv, ;
				SUM(nGrossInc) AS nGrossInc, ;
				SUM(nDirExp) AS nDirExp ;
			FROM temphist ;
			INTO CURSOR tmphist ;
			ORDER BY cownerid, ctypeinv, cwellid ;
			GROUP BY cownerid, ctypeinv, cwellid

        SELE tmphist
        SCAN
            SCATTER MEMVAR
            SELE tempdepl
            LOCATE FOR cownerid = m.cownerid AND cowntype = m.ctypeinv AND cidlease = m.cwellid
            IF FOUND()
                REPL nGrossInc WITH ROUND(m.nGrossInc, 0), ;
                    nDirExp   WITH ROUND(m.nDirExp, 0)

            ENDIF
        ENDSCAN


*  Fill in the total MCF
		SELECT  cwellid, SUM(nTotMCF) AS nTotMCF, SUM(nTotBBL) AS nTotBBL ;
			FROM wellhist ;
			WHERE YEAR(wellhist.hdate) = lnYear ;
				AND &lcWWhere ;
			INTO CURSOR temp ;
			ORDER BY cwellid ;
			GROUP BY cwellid

        IF _TALLY > 0
            SELECT temp
            SCAN
                SCATTER MEMVAR
                SELECT tempdepl
                SCAN FOR cidlease = m.cwellid
                    REPLACE nTotMCF WITH m.nTotMCF, ;
                        nTotBBL WITH m.nTotBBL, ;
                        nMCFShare WITH m.nTotMCF * (nMCFInt / 100)
                ENDSCAN
            ENDSCAN
        ENDIF
    ENDIF

    IF NOT llByWell
        oProgress.SetProgressRange(0, lnmax)
    ENDIF

    lnCount = 1
*
*  Calculate the bbl per day
*
    SELECT tempdepl
    SCAN
        SCATTER MEMVAR
        
        IF NOT llByWell
            oProgress.UpdateProgress(lnCount)
        ENDIF
        
        lnCount = lnCount + 1
*
* Divide the total BBL by 365 to get the BBL per day
*
        lnBBL_Day = m.nTotBBL / 365
*
* Convert the MCF to BBL and then divide by 365 to get BBL per day
*

        lnMCFBBL  = m.nTotMCF / 5.80
        lnMCF_Day = lnMCFBBL / 365
        lnBBL_Day = lnBBL_Day + lnMCF_Day
        SWSELECT('deplset')
        SET ORDER TO cYear
        IF SEEK (m.cYear)
            m.nMargPct = nMargPct / 100
            m.nNonPct  = nNonPct / 100
            m.nnetlim  = nNetIncLim
            m.lLimit   = lLimit
            IF m.nnetlim = 0
                m.nnetlim = 1
            ELSE
                m.nnetlim = m.nnetlim / 100
            ENDIF
        ELSE
            m.nMargPct = .15
            m.nNonPct  = .15
            m.nnetlim  = 1
            m.lLimit   = .F.
        ENDIF
        IF lnBBL_Day <= 15
            lnDeplPct = m.nMargPct
            lnDepl    = ROUND(m.nGrossInc * m.nMargPct, 0)
            lcMarg    = 'Y'
        ELSE
            lnDeplPct = m.nNonPct
            lnDepl    =  ROUND(m.nGrossInc * m.nNonPct, 0)
            lcMarg    = 'N'
        ENDIF
        SWSELECT('deplfile')
        SET ORDER TO yearkey
        IF SEEK (m.cYear + m.cidlease)
            lnIndExp  = nIndExp * (m.nWorkInt / 100)
            lnDeprExp = nDeprExp * (m.nWorkInt / 100)
            lnIDCExp  = nIDCExp * (m.nWorkInt / 100)
            lnCost    = nCostDepl * (m.nWorkInt / 100)
        ELSE
            STORE 0 TO lnIndExp, lnDeprExp, lnIDCExp, lnCost
        ENDIF
        lnNetInc = ROUND(m.nGrossInc - lnIDCExp - lnIndExp - m.nDirExp - lnDeprExp, 0)
        IF lnNetInc < 0 
            lnTentDepl  = 0
            lnNetIncLim = 0
        ELSE
            IF NOT m.lLimit
                lnNetIncLim = ROUND(lnNetInc * m.nnetlim, 0)
            ELSE
                lnNetIncLim = 0
            ENDIF
            IF lnDepl <> 0
                IF NOT m.lLimit
                    IF lnDepl > lnNetIncLim
                        lnTentDepl = lnNetIncLim
                    ELSE
                        lnTentDepl = lnDepl
                    ENDIF
                ELSE
                    lnTentDepl = lnDepl
                ENDIF
            ELSE
                lnTentDepl = 0
            ENDIF
        ENDIF
        IF lnCost > lnTentDepl
            lnTotDepl = lnCost
        ELSE
            lnTotDepl = lnTentDepl
        ENDIF
        lnDeplPct = lnDeplPct * 100

        SELECT tempdepl
        REPLACE nBBLDay   WITH lnBBL_Day, ;
            nMCFBBL   WITH lnMCFBBL,  ;
            cMarginal WITH lcMarg, ;
            nMargPct  WITH m.nMargPct, ;
            nNonPct   WITH m.nNonPct, ;
            nNetInc   WITH lnNetInc,  ;
            nDeplpct  WITH lnDeplPct,  ;
            nDepl     WITH lnDepl,  ;
            nTentDepl WITH lnTentDepl, ;
            nIDCExp   WITH lnIDCExp,   ;
            nIndExp   WITH lnIndExp,  ;
            nNetIncLim WITH lnNetIncLim, ;
            nCostDepl WITH lnCost, ;
            nTotDepl  WITH lnTotDepl, ;
            nDeprExp  WITH lnDeprExp
        STORE 0 TO lnTotDepl, lnTentDepl
    ENDSCAN

    lnDeplRecs = 0
    SELE tempdepl
    SCAN
*   IF nTotDepl = 0 AND nNetInc = 0 AND nTentDepl = 0 AND nGrossInc = 0 AND nDirExp = 0
*      DELETE NEXT 1
*   ELSE
        lnDeplRecs = lnDeplRecs + 1
*   ENDIF
    ENDSCAN

    IF NOT llByWell
        oProgress.CloseProgress()
    ENDIF

    SELECT (lcAlias)
CATCH TO loError
    llReturn = .F.
    DO errorlog WITH 'CalcDepl', loError.LINENO, 'CalcDepl', loError.ERRORNO, loError.MESSAGE, '', loError
    MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
          'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn






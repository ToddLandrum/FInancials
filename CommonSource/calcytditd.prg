*========================================================================================
*  Program....: CALCYTDITD.PRG
*  Version....: 2.5
*  Author.....: Phil W. Sherwood
*  Date.......: February 23, 1996
*  Notice.....: Copyright (c) 1996 SherWare, Inc., All Rights Reserved.
*  Compiler...: FoxPro 2.6a
*) Description: Calculates Year-to-date and Inception to date totals
*)              and updates the records in the owntots and welltots files.
*  Parameters.: tcYear - The year that the year-to-date totals should
*                        be calculated for.
*               tcGroup - The group of wells the total is to be calculated for.
*               tlClear - .T. = Delete the records and add all new instead of replacing.
*  Changes....:
*   04/01/96    pws - Added calculations for well totals.
*   04/17/96    pws - Added group to parms and calculation so only the totals for the
*                     passed group are calculated.
*   04/26/96    pws - Added average price calculations for bbl and mcf.
*   10/22/96    pws - Changed to get the dayson from the wellhist table instead of the
*                     welldays table.
*   08/02/97    pws - changed to use owntots table instead of wellinv table
*   11/17/97    pws - Added flat rate totals
*   01/15/98    pws - Added ldirtot option to exclude directly paid revenue from totals.
*
*========================================================================================
LPARA tdAcctDate, tcGroup, tlClear
LOCAL lcAlias, llDirTot, oMessage, oProgress
LOCAL llCanceled, llReturn, loError
LOCAL avgbbl, avgexp, avgmcf, avgrev, c1ytdtotal, c2ytdtotal, c3ytdtotal, c4ytdtotal, c5ytdtotal
LOCAL cAytdtotal, cBytdtotal, ccytdtotal, cidownt, cidwtot, flytdtotal, gcytdtotal, gytdtotal
LOCAL itdtotmon, itdtotyr, jCount, jMax, nytdnet, oRegistry, oytdtotal, totmonths, totyears
LOCAL txytdtotal, tytdtotal, wytdtotal, ytdGasInc, ytdbbl, ytdclass0, ytdclass1, ytdclass2
LOCAL ytdclass3, ytdclass4, ytdclass5, ytdclassa, ytdclassb, ytdcompres, ytdgather, ytdmcf
LOCAL ytdoilinc, ytdroyalty, ytdtrpinc, ytdworking

llReturn   = .T.
llCanceled = .F.

TRY
    swclose('welltots')
    swclose('owntots')
    swclose('itdytdsusp')

*
*  Open files if they're not open already
*
    swselect('options')
    swselect('owntots', .T.)
    swselect('welltots', .T.)
    swselect('wells')
    swselect('wellhist')
    swselect('disbhist')
    swselect('suspense')
    swselect('sysctl')
    swselect('suspense',.f.,'ytditdsusp')

    SELECT options
    GO TOP
    llDirTot = .T.

*
*  Delete all the current records if asked to
*
    IF tlClear
        WAIT WINDOW NOWAIT 'Clearing out the YTD/ITD tables...Please wait'
        SELECT owntots
        DELETE ALL
        = TABLEUPDATE(.T.)
        SELECT welltots
        DELETE ALL
        = TABLEUPDATE(.T.)
        WAIT CLEAR
    ENDIF

*
*  Setup the message object
*
    oMessage  = FindGlobalObject('cmMessage')
    oRegistry = FindGlobalObject('cmRegistry')

    oProgress = oMessage.ProgressBar('Updating the Year-to-date totals...')

    SELECT owntots
    SET ORDER TO ownerkey
*******************************************************************
*  Get the year-to-date totals.
*******************************************************************
    IF tcGroup = '**'      && All groups
        SET TALK ON
		SELECT  cOwnerID, ;
				cWellID, ;
				cTypeInv, ;
				cTypeInt, ;
				cDirect, ;
				lFlat, ;
				cProgCode, ;
				SUM(nExpense + nmktgexp)  AS wytdtotal, ;
				SUM(nOilRev)   AS oytdtotal, ;
				SUM(nGasRev+nflatrate)   AS gytdtotal, ;
				SUM(nTrpRev + nOthRev + nMiscRev1 + nMiscRev2)   AS tytdtotal, ;
				SUM(nTotale1)  AS c1ytdtotal, ;
				SUM(nTotale2)  AS c2ytdtotal, ;
				SUM(nTotale3)  AS c3ytdtotal, ;
				SUM(nTotale4)  AS c4ytdtotal, ;
				SUM(nTotale5)  AS c5ytdtotal, ;
				SUM(nTotaleA)  AS cAytdtotal, ;
				SUM(nTotaleB)  AS cBytdtotal, ;
				SUM(nSevTaxes+ntaxwith+nbackwith) AS txytdtotal, ;
				SUM(nFlatRate) AS flytdtotal, ;
				SUM(nGather)   AS gcytdtotal, ;
				SUM(nCompress) AS ccytdtotal, ;
				SUM(nNetCheck) AS nytdnet ;
			WHERE EMPTY(disbhist.csusptype) ;
				AND (crunyear + PADL(TRANSFORM(nrunno), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																	   FROM sysctl ;
																	   WHERE YEAR(dacctdate) = YEAR(tdAcctDate) ;
																		   AND dacctdate <= tdAcctDate) ;
					OR (disbhist.lmanual AND YEAR(hdate) = YEAR(tdAcctDate) AND hdate <= tdAcctDate)) ;													   
            AND cRecType <> 'P'  ;
            FROM disbhist ;
            INTO CURSOR ytdhist READWRITE;
            GROUP BY cOwnerID, cWellID, cTypeInv ;
            ORDER BY cOwnerID, cWellID, cTypeInv
        INDEX ON cOwnerID + cWellID + cTypeInv  TAG ytdhist

		SELECT  cOwnerID, ;
				cWellID, ;
				cTypeInv, ;
				cTypeInt, ;
				cDirect, ;
				lFlat, ;
				cProgCode, ;
				SUM(nExpense + nmktgexp)  AS wytdtotal, ;
				SUM(nOilRev)   AS oytdtotal, ;
				SUM(nGasRev+nflatrate)   AS gytdtotal, ;
				SUM(nTrpRev + nOthRev + nMiscRev1 + nMiscRev2)   AS tytdtotal, ;
				SUM(nTotale1)  AS c1ytdtotal, ;
				SUM(nTotale2)  AS c2ytdtotal, ;
				SUM(nTotale3)  AS c3ytdtotal, ;
				SUM(nTotale4)  AS c4ytdtotal, ;
				SUM(nTotale5)  AS c5ytdtotal, ;
				SUM(nTotaleA)  AS cAytdtotal, ;
				SUM(nTotaleB)  AS cBytdtotal, ;
				SUM(nSevTaxes+ntaxwith+nbackwith) AS txytdtotal, ;
				SUM(nFlatRate) AS flytdtotal, ;
				SUM(nGather)   AS gcytdtotal, ;
				SUM(nCompress) AS ccytdtotal, ;
				SUM(nNetCheck) AS nytdnet ;
			WHERE NOT EMPTY(disbhist.csusptype) ;
				AND (cRunYear_In + PADL(TRANSFORM(nRunNo_in), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																			 FROM sysctl ;
																			 WHERE YEAR(dacctdate) = YEAR(tdAcctDate) ;
																				 AND dacctdate <= tdAcctDate) ;
				OR (disbhist.lmanual AND YEAR(hdate) = YEAR(tdAcctDate) AND hdate <= tdAcctDate)) ;													   
				AND cRecType <> 'P'  ;
			FROM disbhist ;
			INTO CURSOR ytdhist1 READWRITE  ;
			GROUP BY cOwnerID, cWellID, cTypeInv ;
			ORDER BY cOwnerID, cWellID, cTypeInv

		SELECT  cOwnerID, ;
				cWellID, ;
				cTypeInv, ;
				cTypeInt, ;
				cDirect, ;
				lFlat, ;
				cProgCode, ;
				SUM(nExpense + nmktgexp)  AS wytdtotal, ;
				SUM(nOilRev)   AS oytdtotal, ;
				SUM(nGasRev+nflatrate)   AS gytdtotal, ;
				SUM(nTrpRev + nOthRev + nMiscRev1 + nMiscRev2)   AS tytdtotal, ;
				SUM(nTotale1)  AS c1ytdtotal, ;
				SUM(nTotale2)  AS c2ytdtotal, ;
				SUM(nTotale3)  AS c3ytdtotal, ;
				SUM(nTotale4)  AS c4ytdtotal, ;
				SUM(nTotale5)  AS c5ytdtotal, ;
				SUM(nTotaleA)  AS cAytdtotal, ;
				SUM(nTotaleB)  AS cBytdtotal, ;
				SUM(nSevTaxes+ntaxwith+nbackwith) AS txytdtotal, ;
				SUM(nFlatRate) AS flytdtotal, ;
				SUM(nGather)   AS gcytdtotal, ;
				SUM(nCompress) AS ccytdtotal, ;
				SUM(nNetCheck) AS nytdnet ;
			WHERE (cRunYear_In + PADL(TRANSFORM(nRunNo_in), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																		   FROM sysctl ;
																		   WHERE YEAR(dacctdate) = YEAR(tdAcctDate) ;
																			   AND dacctdate <= tdAcctDate) ;
				OR (ytditdsusp.lmanual AND YEAR(hdate) = YEAR(tdAcctDate) AND hdate <= tdAcctDate)) ;													   
				AND cRecType <> 'P'  ;
			FROM ytditdsusp ;
			INTO CURSOR ytdhist2 READWRITE  ;
			GROUP BY cOwnerID, cWellID, cTypeInv ;
			ORDER BY cOwnerID, cWellID, cTypeInv


        SET TALK OFF

        WAIT WINDOW NOWAIT 'Calculating YTD history...'
        SELECT ytdhist1
        SCAN
            SCATTER MEMVAR
            IF m.goApp.lCanceled
                llReturn          = .F.
                IF NOT m.goApp.CancelMsg()
                    llCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            WAIT WINDOW NOWAIT 'Calculating YTD history...' + m.cOwnerID
            SELECT ytdhist
            IF SEEK(m.cOwnerID + m.cWellID + m.cTypeInv)
                REPLACE wytdtotal WITH wytdtotal + m.wytdtotal, oytdtotal WITH oytdtotal + m.oytdtotal,  ;
                    tytdtotal WITH tytdtotal + m.tytdtotal, c1ytdtotal WITH c1ytdtotal + m.c1ytdtotal,  ;
                    c2ytdtotal WITH c2ytdtotal + m.c2ytdtotal, c3ytdtotal WITH c3ytdtotal + m.c3ytdtotal,  ;
                    c4ytdtotal WITH c4ytdtotal + m.c4ytdtotal, c5ytdtotal WITH c5ytdtotal + m.c5ytdtotal,  ;
                    cAytdtotal WITH cAytdtotal + m.cAytdtotal, cBytdtotal WITH cBytdtotal + m.cBytdtotal, ;
                    txytdtotal WITH txytdtotal + m.txytdtotal, flytdtotal WITH flytdtotal + m.flytdtotal,  ;
                    gcytdtotal WITH gcytdtotal + m.gcytdtotal, ccytdtotal WITH ccytdtotal + m.ccytdtotal,  ;
                    gytdtotal  WITH gytdtotal + m.gytdtotal, nytdnet WITH nytdnet + m.nytdnet
            ELSE
                INSERT INTO ytdhist FROM MEMVAR
            ENDIF
        ENDSCAN

        IF llCanceled
            EXIT
        ENDIF

        SELECT ytdhist2
        SCAN
            SCATTER MEMVAR
            IF m.goApp.lCanceled
                llReturn          = .F.
                IF NOT m.goApp.CancelMsg()
                    llCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            WAIT WINDOW NOWAIT 'Calculating YTD history...' + m.cOwnerID
            SELECT ytdhist
            IF SEEK(m.cOwnerID + m.cWellID + m.cTypeInv)
                REPLACE wytdtotal WITH wytdtotal + m.wytdtotal, oytdtotal WITH oytdtotal + m.oytdtotal,  ;
                    tytdtotal WITH tytdtotal + m.tytdtotal, c1ytdtotal WITH c1ytdtotal + m.c1ytdtotal,  ;
                    c2ytdtotal WITH c2ytdtotal + m.c2ytdtotal, c3ytdtotal WITH c3ytdtotal + m.c3ytdtotal,  ;
                    c4ytdtotal WITH c4ytdtotal + m.c4ytdtotal, c5ytdtotal WITH c5ytdtotal + m.c5ytdtotal,  ;
                    cAytdtotal WITH cAytdtotal + m.cAytdtotal, cBytdtotal WITH cBytdtotal + m.cBytdtotal, ;
                    txytdtotal WITH txytdtotal + m.txytdtotal, flytdtotal WITH flytdtotal + m.flytdtotal,  ;
                    gcytdtotal WITH gcytdtotal + m.gcytdtotal, ccytdtotal WITH ccytdtotal + m.ccytdtotal,  ;
                    gytdtotal  WITH gytdtotal + m.gytdtotal, nytdnet WITH nytdnet + m.nytdnet
            ELSE
                INSERT INTO ytdhist FROM MEMVAR
            ENDIF
        ENDSCAN
        IF llCanceled
            EXIT
        ENDIF
        WAIT CLEAR
    ELSE
        SET TALK ON
		SELECT  cOwnerID, ;
				cWellID, ;
				cTypeInv, ;
				cTypeInt, ;
				cDirect, ;
				lFlat, ;
				cProgCode, ;
				SUM(nExpense + nmktgexp) AS wytdtotal, ;
				SUM(nOilRev)  AS oytdtotal, ;
				SUM(nGasRev+nflatrate)  AS gytdtotal, ;
				SUM(nTrpRev + nOthRev + nMiscRev1 + nMiscRev2)  AS tytdtotal, ;
				SUM(nTotale1) AS c1ytdtotal, ;
				SUM(nTotale2) AS c2ytdtotal, ;
				SUM(nTotale3) AS c3ytdtotal, ;
				SUM(nTotale4) AS c4ytdtotal, ;
				SUM(nTotale5) AS c5ytdtotal, ;
				SUM(nTotaleA)  AS cAytdtotal, ;
				SUM(nTotaleB)  AS cBytdtotal, ;
				SUM(nSevTaxes+ntaxwith+nbackwith) AS txytdtotal, ;
				SUM(nFlatRate) AS flytdtotal, ;
				SUM(nGather)   AS gcytdtotal, ;
				SUM(nCompress) AS ccytdtotal, ;
				SUM(nNetCheck) AS nytdnet ;
			WHERE EMPTY(disbhist.csusptype) ;
				AND (crunyear + PADL(TRANSFORM(nrunno), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																	   FROM sysctl ;
																	   WHERE YEAR(dacctdate) = YEAR(tdAcctDate) ;
																		   AND dacctdate <= tdAcctDate) ;
				AND cGROUP = tcGroup ;
				OR (disbhist.lmanual AND YEAR(hdate) = YEAR(tdAcctDate) AND hdate <= tdAcctDate)) ;													   
				AND cRecType <> 'P'  ;
			FROM disbhist ;
			INTO CURSOR ytdhist READWRITE  ;
			GROUP BY cOwnerID, cWellID, cTypeInv  ;
			ORDER BY cOwnerID, cWellID, cTypeInv
        INDEX ON cowenrid + cWellID + cTypeInv  TAG ytdhist

		SELECT  cOwnerID, ;
				cWellID, ;
				cTypeInv, ;
				cTypeInt, ;
				cDirect, ;
				lFlat, ;
				cProgCode, ;
				SUM(nExpense + nmktgexp) AS wytdtotal, ;
				SUM(nOilRev)  AS oytdtotal, ;
				SUM(nGasRev+nflatrate)  AS gytdtotal, ;
				SUM(nTrpRev + nOthRev + nMiscRev1 + nMiscRev2)  AS tytdtotal, ;
				SUM(nTotale1) AS c1ytdtotal, ;
				SUM(nTotale2) AS c2ytdtotal, ;
				SUM(nTotale3) AS c3ytdtotal, ;
				SUM(nTotale4) AS c4ytdtotal, ;
				SUM(nTotale5) AS c5ytdtotal, ;
				SUM(nTotaleA)  AS cAytdtotal, ;
				SUM(nTotaleB)  AS cBytdtotal, ;
				SUM(nSevTaxes+ntaxwith+nbackwith) AS txytdtotal, ;
				SUM(nFlatRate) AS flytdtotal, ;
				SUM(nGather)   AS gcytdtotal, ;
				SUM(nCompress) AS ccytdtotal, ;
				SUM(nNetCheck) AS nytdnet ;
			WHERE NOT EMPTY(disbhist.csusptype) ;
				AND (cRunYear_In + PADL(TRANSFORM(nRunNo_in), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																			 FROM sysctl ;
																			 WHERE YEAR(dacctdate) = YEAR(tdAcctDate) ;
																				 AND dacctdate <= tdAcctDate) ;
				AND cGROUP = tcGroup ;
				OR (disbhist.lmanual AND YEAR(hdate) = YEAR(tdAcctDate) AND hdate <= tdAcctDate)) ;													   
				AND cRecType <> 'P'  ;
			FROM disbhist ;
			INTO CURSOR ytdhist1 READWRITE  ;
			GROUP BY cOwnerID, cWellID, cTypeInv   ;
			ORDER BY cOwnerID, cWellID, cTypeInv
        INDEX ON cowenrid + cWellID + cTypeInv TAG ytdhist

		SELECT  cOwnerID, ;
				cWellID, ;
				cTypeInv, ;
				cTypeInt, ;
				cDirect, ;
				lFlat, ;
				cProgCode, ;
				SUM(nExpense + nmktgexp)  AS wytdtotal, ;
				SUM(nOilRev)   AS oytdtotal, ;
				SUM(nGasRev+nflatrate)   AS gytdtotal, ;
				SUM(nTrpRev + nOthRev + nMiscRev1 + nMiscRev2)   AS tytdtotal, ;
				SUM(nTotale1)  AS c1ytdtotal, ;
				SUM(nTotale2)  AS c2ytdtotal, ;
				SUM(nTotale3)  AS c3ytdtotal, ;
				SUM(nTotale4)  AS c4ytdtotal, ;
				SUM(nTotale5)  AS c5ytdtotal, ;
				SUM(nTotaleA)  AS cAytdtotal, ;
				SUM(nTotaleB)  AS cBytdtotal, ;
				SUM(nSevTaxes+ntaxwith+nbackwith) AS txytdtotal, ;
				SUM(nFlatRate) AS flytdtotal, ;
				SUM(nGather)   AS gcytdtotal, ;
				SUM(nCompress) AS ccytdtotal, ;
				SUM(nNetCheck) AS nytdnet ;
			WHERE (cRunYear_In + PADL(TRANSFORM(nRunNo_in), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																		   FROM sysctl ;
																		   WHERE YEAR(dacctdate) = YEAR(tdAcctDate) ;
																			   AND dacctdate <= tdAcctDate) ;
				OR (disbhist.lmanual AND YEAR(hdate) = YEAR(tdAcctDate) AND hdate <= tdAcctDate)) ;													   
				AND cRecType <> 'P'  ;
			FROM ytditdsusp ;
			INTO CURSOR ytdhist2 READWRITE  ;
			GROUP BY cOwnerID, cWellID, cTypeInv  ;
			ORDER BY cOwnerID, cWellID, cTypeInv

        SET TALK OFF
 
        WAIT WINDOW NOWAIT 'Calculating YTD history...'
        SELECT ytdhist1
        SCAN
            SCATTER MEMVAR
            IF m.goApp.lCanceled
                llReturn          = .F.
                IF NOT m.goApp.CancelMsg()
                    llCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            WAIT WINDOW NOWAIT 'Calculating YTD history...' + m.cOwnerID
            SELECT ytdhist
            IF SEEK(m.cOwnerID + m.cWellID + m.cTypeInv)
                REPLACE wytdtotal WITH wytdtotal + m.wytdtotal, oytdtotal WITH oytdtotal + m.oytdtotal,  ;
                    tytdtotal WITH tytdtotal + m.tytdtotal, c1ytdtotal WITH c1ytdtotal + m.c1ytdtotal,  ;
                    c2ytdtotal WITH c2ytdtotal + m.c2ytdtotal, c3ytdtotal WITH c3ytdtotal + m.c3ytdtotal,  ;
                    c4ytdtotal WITH c4ytdtotal + m.c4ytdtotal, c5ytdtotal WITH c5ytdtotal + m.c5ytdtotal,  ;
                    cAytdtotal WITH cAytdtotal + m.cAytdtotal, cBytdtotal WITH cBytdtotal + m.cBytdtotal, ;
                    txytdtotal WITH txytdtotal + m.txytdtotal, flytdtotal WITH flytdtotal + m.flytdtotal,  ;
                    gcytdtotal WITH gcytdtotal + m.gcytdtotal, ccytdtotal WITH ccytdtotal + m.ccytdtotal,  ;
                    gytdtotal  WITH gytdtotal + m.gytdtotal, nytdnet WITH nytdnet + m.nytdnet
            ELSE
                INSERT INTO ytdhist FROM MEMVAR
            ENDIF
        ENDSCAN

        IF llCanceled
            EXIT
        ENDIF

        SELECT ytdhist2
        SCAN
            SCATTER MEMVAR
            IF m.goApp.lCanceled
                llReturn          = .F.
                IF NOT m.goApp.CancelMsg()
                    llCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            WAIT WINDOW NOWAIT 'Calculating YTD history...' + m.cOwnerID
            SELECT ytdhist
            IF SEEK(m.cOwnerID + m.cWellID + m.cTypeInv)
                REPLACE wytdtotal WITH wytdtotal + m.wytdtotal, oytdtotal WITH oytdtotal + m.oytdtotal,  ;
                    tytdtotal WITH tytdtotal + m.tytdtotal, c1ytdtotal WITH c1ytdtotal + m.c1ytdtotal,  ;
                    c2ytdtotal WITH c2ytdtotal + m.c2ytdtotal, c3ytdtotal WITH c3ytdtotal + m.c3ytdtotal,  ;
                    c4ytdtotal WITH c4ytdtotal + m.c4ytdtotal, c5ytdtotal WITH c5ytdtotal + m.c5ytdtotal,  ;
                    cAytdtotal WITH cAytdtotal + m.cAytdtotal, cBytdtotal WITH cBytdtotal + m.cBytdtotal, ;
                    txytdtotal WITH txytdtotal + m.txytdtotal, flytdtotal WITH flytdtotal + m.flytdtotal,  ;
                    gcytdtotal WITH gcytdtotal + m.gcytdtotal, ccytdtotal WITH ccytdtotal + m.ccytdtotal,  ;
                    gytdtotal  WITH gytdtotal + m.gytdtotal, nytdnet WITH nytdnet + m.nytdnet
            ELSE
                INSERT INTO ytdhist FROM MEMVAR
            ENDIF
        ENDSCAN

        IF llCanceled
            EXIT
        ENDIF

        WAIT CLEAR
    ENDIF
    SELECT ytdhist
    jMax = RECCOUNT()

    SET TALK ON
    IF tcGroup = '**'
		SELECT  cWellID, ;
				SUM(nGasInc)  AS ytdGasInc, ;
				SUM(nOilInc)  AS ytdoilinc, ;
				SUM(nTrpInc + nOthInc + nMiscInc1 + nMiscInc2)  AS ytdtrpinc, ;
				SUM(nTotale)  AS ytdclass0, ;
				SUM(nExpCl1)  AS ytdclass1, ;
				SUM(nExpCl2)  AS ytdclass2, ;
				SUM(nExpCl3)  AS ytdclass3, ;
				SUM(nExpCl4)  AS ytdclass4, ;
				SUM(nExpCl5)  AS ytdclass5, ;
				SUM(nExpClA)  AS ytdclassa, ;
				SUM(nExpClB)  AS ytdclassb, ;
				SUM(nTotMCF)  AS ytdmcftot, ;
				SUM(nTotBBL)  AS ytdbbltot, ;
				SUM(nRoyInt)  AS ytdroyalty, ;
				SUM(nGather) AS ytdgather, ;
				SUM(nCompress) AS ytdcompres, ;
				SUM(nWrkInt)  AS ytdworking ;
			WHERE crunyear + PADL(TRANSFORM(nrunno), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																	 FROM sysctl ;
																	 WHERE YEAR(dacctdate) = YEAR(tdAcctDate) ;
																		 AND dacctdate <= tdAcctDate) ;
			FROM wellhist ;
			INTO CURSOR ytdwhist READWRITE ;
			GROUP BY cWellID ;
			ORDER BY cWellID
    ELSE
		SELECT  cWellID, ;
				SUM(nGasInc)  AS ytdGasInc, ;
				SUM(nOilInc)  AS ytdoilinc, ;
				SUM(nTrpInc + nOthInc + nMiscInc1 + nMiscInc2)  AS ytdtrpinc, ;
				SUM(nTotale)  AS ytdclass0, ;
				SUM(nExpCl1)  AS ytdclass1, ;
				SUM(nExpCl2)  AS ytdclass2, ;
				SUM(nExpCl3)  AS ytdclass3, ;
				SUM(nExpCl4)  AS ytdclass4, ;
				SUM(nExpCl5)  AS ytdclass5, ;
				SUM(nExpClA)  AS ytdclassa, ;
				SUM(nExpClB)  AS ytdclassb, ;
				SUM(nTotMCF)  AS ytdmcf, ;
				SUM(nTotBBL)  AS ytdbbl, ;
				SUM(nRoyInt)  AS ytdroyalty, ;
				SUM(nGather) AS ytdgather, ;
				SUM(nCompress) AS ytdcompres, ;
				SUM(nWrkInt)  AS ytdworking, ;
				0000000.0000  AS avgbblprc, ;
				0000000.0000  AS avgmcfprc, ;
				0             AS totyears, ;
				0             AS totmonths, ;
				0             AS avgbbl, ;
				0             AS avgmcf, ;
				0             AS avgrev, ;
				0             AS avgexp, ;
				0             AS itdbbl, ;
				0             AS ytdbbl ;
			WHERE crunyear + PADL(TRANSFORM(nrunno), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																	 FROM sysctl ;
																	 WHERE YEAR(dacctdate) = YEAR(tdAcctDate) ;
																		 AND dacctdate <= tdAcctDate) ;
				AND cGROUP = tcGroup ;
			FROM wellhist ;
			INTO CURSOR ytdwhist READWRITE ;
			GROUP BY cWellID ;
			ORDER BY cWellID
    ENDIF
    SET TALK OFF
    jMax   = jMax + _TALLY
    jCount = 1
    oProgress.SetProgressRange(0, jMax)
*******************************************************************
*  Update the year-to-date totals
*******************************************************************
    IF jMax = 0
        SELECT owntots
        jMax = RECC()
        GO TOP
        SCAN
            oProgress.UpdateProgress(jCount)
            jCount = jCount + 1
            IF m.goApp.lCanceled
                llReturn          = .F.
                IF NOT m.goApp.CancelMsg()
                    llCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            REPLACE wytdtotal  WITH 0, ;
                oytdtotal  WITH 0, ;
                gytdtotal  WITH 0, ;
                tytdtotal  WITH 0, ;
                c1ytdtotal WITH 0, ;
                c2ytdtotal WITH 0, ;
                c3ytdtotal WITH 0, ;
                c4ytdtotal WITH 0, ;
                c5ytdtotal WITH 0, ;
                cAytdtotal WITH 0, ;
                cBytdtotal WITH 0, ;
                txytdtotal WITH 0, ;
                gcytdtotal WITH 0, ;
                ccytdtotal WITH 0, ;
                flytdtotal WITH 0
        ENDSCAN
        IF llCanceled
            EXIT
        ENDIF

        SELECT welltots
        jMax = RECC()
        GO TOP
        SCAN
            oProgress.UpdateProgress(jCount)
            jCount = jCount + 1
            IF m.goApp.lCanceled
                llReturn          = .F.
                IF NOT m.goApp.CancelMsg()
                    llCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            REPLACE ytdGasInc   WITH 0, ;
                ytdoilinc   WITH 0, ;
                ytdtrpinc   WITH 0, ;
                ytdclass0   WITH 0, ;
                ytdclass1   WITH 0, ;
                ytdclass2   WITH 0, ;
                ytdclass3   WITH 0, ;
                ytdclass4   WITH 0, ;
                ytdclass5   WITH 0, ;
                ytdclassa   WITH 0, ;
                ytdclassb   WITH 0, ;
                ytdmcf      WITH 0, ;
                ytdbbl      WITH 0, ;
                ytdroyalty  WITH 0, ;
                ytdgather   WITH 0, ;
                ytdcompres  WITH 0, ;
                ytdworking  WITH 0

        ENDSCAN
        IF llCanceled
            EXIT
        ENDIF

    ELSE
        SELECT owntots
        SCATTER MEMVAR BLANK
        SET ORDER TO ownerkey
        SELECT ytdhist
        GO TOP
        SCAN
            SCATTER MEMVAR
            oProgress.UpdateProgress(jCount)
            jCount = jCount + 1
            IF m.goApp.lCanceled
                llReturn          = .F.
                IF NOT m.goApp.CancelMsg()
                    llCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            SELECT owntots
            IF SEEK(m.cOwnerID + m.cWellID + m.cProgCode + m.cTypeInv + m.cTypeInt)
                REPLACE wytdtotal  WITH m.wytdtotal, ;
                    oytdtotal  WITH m.oytdtotal, ;
                    gytdtotal  WITH m.gytdtotal, ;
                    tytdtotal  WITH m.tytdtotal, ;
                    c1ytdtotal WITH m.c1ytdtotal, ;
                    c2ytdtotal WITH m.c2ytdtotal, ;
                    c3ytdtotal WITH m.c3ytdtotal, ;
                    c4ytdtotal WITH m.c4ytdtotal, ;
                    c5ytdtotal WITH m.c5ytdtotal, ;
                    cAytdtotal WITH m.cAytdtotal, ;
                    cBytdtotal WITH m.cBytdtotal, ;
                    txytdtotal WITH m.txytdtotal, ;
                    flytdtotal WITH m.flytdtotal, ;
                    gcytdtotal WITH m.gcytdtotal, ;
                    ccytdtotal WITH m.ccytdtotal, ;
                    cDirect    WITH m.cDirect, ;
                    lFlat      WITH m.lFlat, ;
                    nytdnet    WITH m.nytdnet
            ELSE
                SET DELE OFF
                m.cidownt = oRegistry.IncrementCounter('%Shared.Counters.Owner Totals')
                SELECT owntots
                SET ORDER TO cidownt
                DO WHILE SEEK(m.cidownt)
                    m.cidownt = oRegistry.IncrementCounter('%Shared.Counters.Owner Totals')
                ENDDO
                INSERT INTO owntots FROM MEMVAR
                SET DELE ON
            ENDIF
            SELECT ytdhist
        ENDSCAN
        IF llCanceled
            EXIT
        ENDIF
        SELECT welltots
        SCATTER MEMVAR BLANK

        SELECT ytdwhist
        GO TOP
        SCAN
            SCATTER MEMVAR
            oProgress.UpdateProgress(jCount)
            jCount = jCount + 1
            SELECT welltots
            SET ORDER TO cWellID
            IF NOT SEEK(m.cWellID)
                SET DELE OFF
                m.cidwtot = oRegistry.IncrementCounter('%Shared.Counters.Well Totals')
                SELECT welltots
                SET ORDER TO cidwtot
                DO WHILE SEEK(m.cidwtot)
                    m.cidwtot = oRegistry.IncrementCounter('%Shared.Counters.Well Totals')
                ENDDO
                INSERT INTO welltots FROM MEMVAR
                SET DELE ON
            ELSE
                REPLACE ytdGasInc   WITH m.ytdGasInc, ;
                    ytdoilinc   WITH m.ytdoilinc, ;
                    ytdtrpinc   WITH m.ytdtrpinc, ;
                    ytdclass0   WITH m.ytdclass0, ;
                    ytdclass1   WITH m.ytdclass1, ;
                    ytdclass2   WITH m.ytdclass2, ;
                    ytdclass3   WITH m.ytdclass3, ;
                    ytdclass4   WITH m.ytdclass4, ;
                    ytdclass5   WITH m.ytdclass5, ;
                    ytdclassa   WITH m.ytdclassa, ;
                    ytdclassb   WITH m.ytdclassb, ;
                    ytdmcf      WITH m.ytdmcftot, ;
                    ytdbbl      WITH m.ytdbbltot, ;
                    ytdcompres  WITH m.ytdcompres, ;
                    ytdgather   WITH m.ytdgather, ;
                    ytdroyalty  WITH m.ytdroyalty, ;
                    ytdworking  WITH m.ytdworking
            ENDIF
            SELECT ytdwhist
        ENDSCAN
        IF llCanceled
            EXIT
        ENDIF

    ENDIF

    oProgress.CloseProgress()

*******************************************************************
*  Get the inception to date totals.
*******************************************************************
    oProgress = oMessage.ProgressBar('Updating the Inception-to-date totals...')
    IF tcGroup =  '**'
        SET TALK ON

		SELECT  cOwnerID, ;
				cWellID, ;
				cTypeInv, ;
				cTypeInt, ;
				cDirect, ;
				lFlat, ;
				cProgCode, ;
				SUM(nExpense + nmktgexp) AS witdtotal, ;
				SUM(nOilRev)  AS oitdtotal, ;
				SUM(nGasRev+nflatrate)  AS gitdtotal, ;
				SUM(nTrpRev + nOthRev + nMiscRev1 + nMiscRev2)  AS titdtotal, ;
				SUM(nTotale1) AS c1itdtotal, ;
				SUM(nTotale2) AS c2itdtotal, ;
				SUM(nTotale3) AS c3itdtotal, ;
				SUM(nTotale4) AS c4itdtotal, ;
				SUM(nTotale5) AS c5itdtotal, ;
				SUM(nTotaleA) AS cAitdtotal, ;
				SUM(nTotaleB) AS cBitdtotal, ;
				SUM(nSevTaxes+ntaxwith+nbackwith) AS txitdtotal, ;
				SUM(nFlatRate) AS flitdtotal, ;
				SUM(nGather)   AS gcitdtotal, ;
				SUM(nCompress) AS ccitdtotal, ;
				.F. AS filler,  ;
				SUM(nNetCheck) AS nitdnet ;
			FROM disbhist ;
			WHERE EMPTY(disbhist.csusptype) ;
				AND (crunyear + PADL(TRANSFORM(nrunno), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																	   FROM sysctl ;
																	   WHERE YEAR(dacctdate) <= YEAR(tdAcctDate) ;
																		   AND dacctdate <= tdAcctDate) ;
				  OR (lManual AND YEAR(hdate) <= YEAR(tdAcctDate) ;
					AND hdate <= tdAcctDate))  ;
				AND cRecType <> 'P'  ;
			INTO CURSOR incphist READWRITE  ;
			GROUP BY cOwnerID, cWellID, cTypeInv;
			ORDER BY cOwnerID, cWellID, cTypeInv
        INDEX ON cOwnerID + cWellID + cTypeInv  TAG incphist

		SELECT  cOwnerID, ;
				cWellID, ;
				cTypeInv, ;
				cTypeInt, ;
				cDirect, ;
				lFlat, ;
				cProgCode, ;
				SUM(nExpense + nmktgexp) AS witdtotal, ;
				SUM(nOilRev)  AS oitdtotal, ;
				SUM(nGasRev+nflatrate)  AS gitdtotal, ;
				SUM(nTrpRev + nOthRev + nMiscRev1 + nMiscRev2)  AS titdtotal, ;
				SUM(nTotale1) AS c1itdtotal, ;
				SUM(nTotale2) AS c2itdtotal, ;
				SUM(nTotale3) AS c3itdtotal, ;
				SUM(nTotale4) AS c4itdtotal, ;
				SUM(nTotale5) AS c5itdtotal, ;
				SUM(nTotaleA) AS cAitdtotal, ;
				SUM(nTotaleB) AS cBitdtotal, ;
				SUM(nSevTaxes+ntaxwith+nbackwith) AS txitdtotal, ;
				SUM(nFlatRate) AS flitdtotal, ;
				SUM(nGather)   AS gcitdtotal, ;
				SUM(nCompress) AS ccitdtotal, ;
				.F. AS filler,  ;
				SUM(nNetCheck) AS nitdnet ;
			FROM disbhist ;
			WHERE NOT EMPTY(disbhist.csusptype) ;
				AND (cRunYear_In + PADL(TRANSFORM(nRunNo_in), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																			 FROM sysctl ;
																			 WHERE YEAR(dacctdate) <= YEAR(tdAcctDate) ;
																				 AND dacctdate <= tdAcctDate) ;
				  OR (lManual AND YEAR(hdate) <= YEAR(tdAcctDate) ;
					AND hdate <= tdAcctDate))  ;
				AND cRecType <> 'P'  ;
			INTO CURSOR incphist1 READWRITE  ;
			GROUP BY cOwnerID, cWellID, cTypeInv;
			ORDER BY cOwnerID, cWellID, cTypeInv

		SELECT  cOwnerID, ;
				cWellID, ;
				cTypeInv, ;
				cTypeInt, ;
				cDirect, ;
				lFlat, ;
				cProgCode, ;
				SUM(nExpense + nmktgexp) AS witdtotal, ;
				SUM(nOilRev)  AS oitdtotal, ;
				SUM(nGasRev+nflatrate)  AS gitdtotal, ;
				SUM(nTrpRev + nOthRev + nMiscRev1 + nMiscRev2)  AS titdtotal, ;
				SUM(nTotale1) AS c1itdtotal, ;
				SUM(nTotale2) AS c2itdtotal, ;
				SUM(nTotale3) AS c3itdtotal, ;
				SUM(nTotale4) AS c4itdtotal, ;
				SUM(nTotale5) AS c5itdtotal, ;
				SUM(nTotaleA) AS cAitdtotal, ;
				SUM(nTotaleB) AS cBitdtotal, ;
				SUM(nSevTaxes+ntaxwith+nbackwith) AS txitdtotal, ;
				SUM(nFlatRate) AS flitdtotal, ;
				SUM(nGather)   AS gcitdtotal, ;
				SUM(nCompress) AS ccitdtotal, ;
				.F. AS filler,  ;
				SUM(nNetCheck) AS nitdnet ;
			FROM ytditdsusp ;
			WHERE (cRunYear_In + PADL(TRANSFORM(nRunNo_in), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																		   FROM sysctl ;
																		   WHERE YEAR(dacctdate) <= YEAR(tdAcctDate) ;
																			   AND dacctdate <= tdAcctDate) ;
				  OR (lManual AND YEAR(hdate) <= YEAR(tdAcctDate) ;
					AND hdate <= tdAcctDate))  ;
				AND cRecType <> 'P'  ;
			INTO CURSOR incphist2 READWRITE ;
			GROUP BY cOwnerID, cWellID, cTypeInv  ;
			ORDER BY cOwnerID, cWellID, cTypeInv

        SET TALK OFF

        WAIT WINDOW NOWAIT 'Calculating ITD history...'
        SELECT incphist1
        SCAN
            SCATTER MEMVAR
            IF m.goApp.lCanceled
                llReturn          = .F.
                IF NOT m.goApp.CancelMsg()
                    llCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            WAIT WINDOW NOWAIT 'Calculating ITD history...' + m.cOwnerID
            SELECT incphist
            IF SEEK(m.cOwnerID + m.cWellID + m.cTypeInv)
                REPLACE witdtotal WITH witdtotal + m.witdtotal, oitdtotal WITH oitdtotal + m.oitdtotal,  ;
                    gitdtotal WITH gitdtotal + m.gitdtotal, titdtotal WITH titdtotal + m.titdtotal,  ;
                    c1itdtotal WITH c1itdtotal + m.c1itdtotal, c2itdtotal WITH c2itdtotal + m.c2itdtotal,  ;
                    c3itdtotal WITH c3itdtotal + m.c3itdtotal, c4itdtotal WITH c4itdtotal + m.c4itdtotal,  ;
                    c5itdtotal WITH c5itdtotal + m.c5itdtotal, txitdtotal WITH txitdtotal + m.txitdtotal,  ;
                    flitdtotal WITH flitdtotal + m.flitdtotal, gcitdtotal WITH gcitdtotal + m.gcitdtotal,  ;
                    ccitdtotal WITH ccitdtotal + m.ccitdtotal, nitdnet WITH nitdnet + m.nitdnet, ;
                    cAitdtotal WITH cAitdtotal + m.cAitdtotal, cBitdtotal WITH cBitdtotal + m.cBitdtotal
            ELSE
                INSERT INTO incphist FROM MEMVAR
            ENDIF
        ENDSCAN
        IF llCanceled
            EXIT
        ENDIF
        SELECT incphist2
        SCAN
            SCATTER MEMVAR
            IF m.goApp.lCanceled
                llReturn          = .F.
                IF NOT m.goApp.CancelMsg()
                    llCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            WAIT WINDOW NOWAIT 'Calculating ITD history...' + m.cOwnerID
            SELECT incphist
            IF SEEK(m.cOwnerID + m.cWellID + m.cTypeInv)
                REPLACE witdtotal WITH witdtotal + m.witdtotal, oitdtotal WITH oitdtotal + m.oitdtotal,  ;
                    gitdtotal WITH gitdtotal + m.gitdtotal, titdtotal WITH titdtotal + m.titdtotal,  ;
                    c1itdtotal WITH c1itdtotal + m.c1itdtotal, c2itdtotal WITH c2itdtotal + m.c2itdtotal,  ;
                    c3itdtotal WITH c3itdtotal + m.c3itdtotal, c4itdtotal WITH c4itdtotal + m.c4itdtotal,  ;
                    c5itdtotal WITH c5itdtotal + m.c5itdtotal, txitdtotal WITH txitdtotal + m.txitdtotal,  ;
                    flitdtotal WITH flitdtotal + m.flitdtotal, gcitdtotal WITH gcitdtotal + m.gcitdtotal,  ;
                    ccitdtotal WITH ccitdtotal + m.ccitdtotal, nitdnet WITH nitdnet + m.nitdnet, ;
                    cAitdtotal WITH cAitdtotal + m.cAitdtotal, cBitdtotal WITH cBitdtotal + m.cBitdtotal
            ELSE
                INSERT INTO incphist FROM MEMVAR
            ENDIF
        ENDSCAN
        IF llCanceled
            EXIT
        ENDIF
        WAIT CLEAR

    ENDIF

    SELECT incphist
    jMax   = RECCOUNT()
    jCount = 1
    oProgress.SetProgressRange(0, jMax)

    CREATE CURSOR itdwhist ;
        (cWellID      C(10),  ;
          itdGasInc   N(12, 2), ;
          itdOilInc   N(12, 2), ;
          itdTrpInc   N(12, 2), ;
          itdclass0   N(12, 2), ;
          itdclass1   N(12, 2), ;
          itdclass2   N(12, 2), ;
          itdclass3   N(12, 2), ;
          itdclass4   N(12, 2), ;
          itdclass5   N(12, 2), ;
          itdclassA   N(12, 2), ;
          itdclassB   N(12, 2), ;
          itdmcftot   N(12, 2), ;
          itdbbltot   N(12, 2), ;
          itdroyalty  N(12, 2), ;
          itdworking  N(12, 2), ;
          itdGather   N(12, 2), ;
          itdcompres  N(12, 2), ;
          avgrev      N(12, 2), ;
          avgexp      N(12, 2), ;
          avgmcf      I, ;
          avgbbl      I, ;
          avgbblprc   N(12, 4), ;
          avgmcfprc   N(12, 4), ;
          totdays     I,    ;
          itdtotmon   N(12, 2),    ;
          itdtotyr    N(12, 2))
    INDEX ON cWellID TAG cWellID

    IF tcGroup = '**'
		SELECT  cWellID, ;
				SUM(nGasInc)  AS itdGasInc, ;
				SUM(nOilInc)  AS itdOilInc, ;
				SUM(nTrpInc + nOthInc + nMiscInc1 + nMiscInc2)  AS itdTrpInc, ;
				SUM(nTotale)  AS itdclass0, ;
				SUM(nExpCl1)  AS itdclass1, ;
				SUM(nExpCl2)  AS itdclass2, ;
				SUM(nExpCl3)  AS itdclass3, ;
				SUM(nExpCl4)  AS itdclass4, ;
				SUM(nExpCl5)  AS itdclass5, ;
				SUM(nExpClA)  AS itdclassA, ;
				SUM(nExpClB)  AS itdclassB, ;
				SUM(nTotMCF)  AS itdmcftot, ;
				SUM(nTotBBL)  AS itdbbltot, ;
				SUM(nRoyInt)  AS itdroyalty, ;
				SUM(nWrkInt)  AS itdworking, ;
				SUM(nGather) AS itdGather, ;
				SUM(nCompress) AS itdcompres, ;
				SUM(nOilInc + nTrpInc + nGasInc) AS avgrev, ;
				SUM(nTotale + nExpCl1 + nExpCl2 + nExpCl3 + nExpCl4 + nExpCl5) AS avgexp ;
			FROM wellhist ;
			WHERE crunyear + PADL(TRANSFORM(nrunno), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																	 FROM sysctl ;
																	 WHERE YEAR(dacctdate) <= YEAR(tdAcctDate) ;
																		 AND dacctdate <= tdAcctDate) ;
			INTO CURSOR itdwells READWRITE ;
			GROUP BY cWellID ;
			ORDER BY cWellID
    ELSE
		SELECT  cWellID, ;
				SUM(nGasInc)  AS itdGasInc, ;
				SUM(nOilInc)  AS itdOilInc, ;
				SUM(nTrpInc + nOthInc + nMiscInc1 + nMiscInc2)  AS itdTrpInc, ;
				SUM(nTotale)  AS itdclass0, ;
				SUM(nExpCl1)  AS itdclass1, ;
				SUM(nExpCl2)  AS itdclass2, ;
				SUM(nExpCl3)  AS itdclass3, ;
				SUM(nExpCl4)  AS itdclass4, ;
				SUM(nExpCl5)  AS itdclass5, ;
				SUM(nExpClA)  AS itdclassA, ;
				SUM(nExpClB)  AS itdclassB, ;
				SUM(nTotMCF)  AS itdmcftot, ;
				SUM(nTotBBL)  AS itdbbltot, ;
				SUM(nRoyInt)  AS itdroyalty, ;
				SUM(nWrkInt)  AS itdworking, ;
				SUM(nGather) AS itdGather, ;
				SUM(nCompress) AS itdcompres, ;
				SUM(nOilInc + nTrpInc + nGasInc) AS avgrev, ;
				SUM(nTotale + nExpCl1 + nExpCl2 + nExpCl3 + nExpCl4 + nExpCl5) AS avgexp ;
			FROM wellhist ;
			WHERE cGROUP = tcGroup ;
				AND crunyear + PADL(TRANSFORM(nrunno), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																	   FROM sysctl ;
																	   WHERE YEAR(dacctdate) <= YEAR(tdAcctDate) ;
																		   AND dacctdate <= tdAcctDate) ;
			INTO CURSOR itdwells READWRITE ;
			GROUP BY cWellID ;
			ORDER BY cWellID
    ENDIF

    SELECT itdwells
    jMax   = jMax + RECCOUNT()
    jCount = 1

    SELECT itdwhist
    APPEND FROM DBF('itdwells')
*******************************************************************
*  Calculate the total dayson
*******************************************************************
    WAIT WINDOW NOWAIT 'Calculating Total Dayson...'
    IF tcGroup = '**'
		SELECT  wellhist.cWellID, ;
				SUM(wellhist.ndayson) AS totdays ;
			FROM wellhist ;
			INTO CURSOR itddays READWRITE ;
			GROUP BY cWellID ;
			ORDER BY cWellID
    ELSE
		SELECT  wellhist.cWellID, ;
				SUM(wellhist.ndayson) AS totdays ;
			FROM wellhist ;
			WHERE cWellID IN (SELECT  cWellID ;
								  FROM wells ;
								  WHERE cGROUP = tcGroup) ;
			INTO CURSOR itddays READWRITE ;
			GROUP BY cWellID ;
			ORDER BY cWellID
    ENDIF

    SELECT itddays
    SCAN
        SCATTER MEMVAR
        IF m.goApp.lCanceled
            llReturn          = .F.
            IF NOT m.goApp.CancelMsg()
                llCanceled = .T.
                EXIT
            ENDIF
        ENDIF
        IF m.totdays = 0
            m.itdtotyr  = 0
            m.itdtotmon = 0
        ELSE
            m.itdtotyr  = m.totdays / 365
            m.itdtotmon = m.totdays / 30
        ENDIF
        SELECT itdwhist
        SET ORDER TO cWellID
        SEEK m.cWellID
        IF FOUND()
            IF m.totdays = 0
                m.avgmcf = 0
                m.avgbbl = 0
                m.avgexp = 0
                m.avgrev = 0
            ELSE
                m.avgmcf = itdmcftot / m.totdays
                m.avgbbl = itdbbltot / m.totdays
                m.avgexp = avgexp / (m.totdays / 30)
                m.avgrev = avgrev / (m.totdays / 30)
            ENDIF
            REPLACE totdays   WITH m.totdays, ;
                itdtotyr  WITH m.itdtotyr, ;
                itdtotmon WITH m.itdtotmon, ;
                avgmcf    WITH m.avgmcf, ;
                avgbbl    WITH m.avgbbl, ;
                avgrev    WITH m.avgrev, ;
                avgexp    WITH m.avgexp
        ENDIF
        SELECT itddays
    ENDSCAN
    IF llCanceled
        EXIT
    ENDIF

    WAIT CLEAR

*******************************************************************
*  Calculate the average price per bbl and mcf
******************************************************************
    WAIT WINDOW NOWAIT 'Calculating Average Prices...'
	SELECT  cWellID, ;
			csource, ;
			AVG(nPrice) AS avgprice ;
		FROM income ;
		WHERE nPrice > 0 ;
			AND nunits  > 0 ;
			AND crunyear + PADL(TRANSFORM(nrunno), 3, '0') IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
																   FROM sysctl ;
																   WHERE YEAR(dacctdate) <= YEAR(tdAcctDate) ;
																	   AND dacctdate <= tdAcctDate) ;
		INTO CURSOR tmpavg READWRITE ;
		GROUP BY cWellID, csource ;
		ORDER BY cWellID, csource

    SELECT tmpavg
    GO TOP
    SCAN
        SCATTER MEMVAR
        IF m.goApp.lCanceled
            llReturn          = .F.
            IF NOT m.goApp.CancelMsg()
                llCanceled = .T.
                EXIT
            ENDIF
        ENDIF
        SELECT itdwhist
        SET ORDER TO cWellID
        SEEK m.cWellID
        IF FOUND()
            DO CASE
                CASE m.csource = 'BBL'
                    REPLACE avgbblprc WITH avgprice
                CASE m.csource = 'MCF'
                    REPLACE avgmcfprc WITH avgprice
            ENDCASE
        ENDIF
        SELECT tmpavg
    ENDSCAN
    IF llCanceled
        EXIT
    ENDIF


    IF USED('tmpavg')
        SELECT tmpavg
        USE
    ENDIF
    WAIT CLEAR
*******************************************************************
*  Update the inception-to-date totals
*******************************************************************
    SELECT incphist
    GO TOP
    SCAN
        SCATTER MEMVAR
        IF m.goApp.lCanceled
            llReturn          = .F.
            IF NOT m.goApp.CancelMsg()
                llCanceled = .T.
                EXIT
            ENDIF
        ENDIF
        oProgress.UpdateProgress(jCount)
        jCount = jCount + 1
        SELECT owntots
        SET ORDER TO ownerkey
        IF SEEK(m.cOwnerID + m.cWellID + m.cProgCode + m.cTypeInv)
            REPLACE witdtotal  WITH m.witdtotal, ;
                oitdtotal  WITH m.oitdtotal, ;
                gitdtotal  WITH m.gitdtotal, ;
                titdtotal  WITH m.titdtotal, ;
                c1itdtotal WITH m.c1itdtotal, ;
                c2itdtotal WITH m.c2itdtotal, ;
                c3itdtotal WITH m.c3itdtotal, ;
                c4itdtotal WITH m.c4itdtotal, ;
                c5itdtotal WITH m.c5itdtotal, ;
                cAitdtotal WITH m.cAitdtotal, ;
                cBitdtotal WITH m.cBitdtotal, ;
                txitdtotal WITH m.txitdtotal, ;
                flitdtotal WITH m.flitdtotal, ;
                gcitdtotal WITH m.gcitdtotal, ;
                ccitdtotal WITH m.ccitdtotal, ;
                nitdnet    WITH m.nitdnet
        ELSE
            SET DELE OFF
            m.cidownt = oRegistry.IncrementCounter('%Shared.Counters.Owner Totals')
            SELECT owntots
            SET ORDER TO cidownt
            DO WHILE SEEK(m.cidownt)
                m.cidownt = oRegistry.IncrementCounter('%Shared.Counters.Owner Totals')
            ENDDO
            STORE 0 TO m.oytdtotal, m.wytdtotal, m.gytdtotal, ;
                m.c1ytdtotal, m.c2ytdtotal, m.c3ytdtotal, ;
                m.c4ytdtotal, m.c5ytdtotal, m.txytdtotal, ;
                m.cAytdtotal, m.cBytdtotal, ;
                m.flytdtotal, m.gcytdtotal, m.ccytdtotal, ;
                m.nytdnet, m.tytdtotal
            INSERT INTO owntots FROM MEMVAR
            SET DELE ON
        ENDIF
        SELECT incphist
    ENDSCAN

    IF llCanceled
        EXIT
    ENDIF

    SELECT itdwhist
    GO TOP
    SCAN
        SCATTER MEMVAR
        IF m.goApp.lCanceled
            llReturn          = .F.
            IF NOT m.goApp.CancelMsg()
                llCanceled = .T.
                EXIT
            ENDIF
        ENDIF
        oProgress.UpdateProgress(jCount)
        jCount = jCount + 1
        SELECT welltots
        SET ORDER TO cWellID
        SEEK m.cWellID
        IF NOT FOUND()
            m.totmonths  = m.itdtotmon
            m.totyears   = m.itdtotyr
            m.cidwtot    = oRegistry.IncrementCounter('%Shared.Counters.Well Totals')
            m.ytdGasInc  =  0
            m.ytdoilinc  = 0
            m.ytdtrpinc  = 0
            m.ytdclass0  = 0
            m.ytdclass1  = 0
            m.ytdclass2  = 0
            m.ytdclass3  = 0
            m.ytdclass4  = 0
            m.ytdclass5  = 0
            m.ytdclassa  = 0
            m.ytdclassb  = 0
            m.ytdmcf     = 0
            m.ytdbbl     = 0
            m.ytdroyalty =  0
            m.ytdgather  = 0
            m.ytdcompres = 0
            m.ytdworking = 0
            SET DELE OFF
            SELECT welltots
            SET ORDER TO cidwtot
            DO WHILE SEEK(m.cidwtot)
                m.cidwtot = oRegistry.IncrementCounter('%Shared.Counters.Well Totals')
            ENDDO
            INSERT INTO welltots FROM MEMVAR
            SET DELE ON
        ELSE
            REPLACE itdGasInc   WITH m.itdGasInc, ;
                itdOilInc   WITH m.itdOilInc, ;
                itdTrpInc   WITH m.itdTrpInc, ;
                itdclass0   WITH m.itdclass0, ;
                itdclass1   WITH m.itdclass1, ;
                itdclass2   WITH m.itdclass2, ;
                itdclass3   WITH m.itdclass3, ;
                itdclass4   WITH m.itdclass4, ;
                itdclass5   WITH m.itdclass5, ;
                itdclassA   WITH m.itdclassA, ;
                itdclassB   WITH m.itdclassB, ;
                itdmcf      WITH m.itdmcftot, ;
                itdbbl      WITH m.itdbbltot, ;
                itdroyalty  WITH m.itdroyalty, ;
                itdworking  WITH m.itdworking, ;
                itdGather   WITH m.itdGather, ;
                itdcompres  WITH m.itdcompres, ;
                totdays     WITH m.totdays, ;
                avgmcf      WITH m.avgmcf,  ;
                avgbbl      WITH m.avgbbl, ;
                avgrev      WITH m.avgrev, ;
                avgexp      WITH m.avgexp, ;
                avgbblprc   WITH m.avgbblprc, ;
                avgmcfprc   WITH m.avgmcfprc, ;
                totmonths   WITH m.itdtotmon, ;
                totyears    WITH m.itdtotyr
        ENDIF
        SELECT itdwhist
    ENDSCAN

    oProgress.CloseProgress()

    WAIT WINDOW NOWAIT 'Saving Changes...'
    SELECT welltots
    = TABLEUPDATE(.T.)
    SELECT owntots
    = TABLEUPDATE(.T.)
    WAIT CLEAR


    RELE oProgress

    swclose('ytdhist')
    swclose('incphist')
    swclose('ytdwhist')
    swclose('itdwhist')

CATCH TO loError
    llReturn = .F.
    DO errorlog WITH 'CalcYTDITD', loError.LINENO, 'CalcYTDITD', loError.ERRORNO, loError.MESSAGE
    IF VARTYPE(oProgress) = 'O'
        oProgress.CloseProgress()
        oProgress = .NULL.
    ENDIF
    MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
          'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

IF llCanceled
    IF VARTYPE(oProgress) = 'O'
        oProgress.CloseProgress()
        oProgress = .NULL.
    ENDIF
ENDIF

RETURN llReturn

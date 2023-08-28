DEFINE CLASS swLeaseOperRpt AS CUSTOM

   cErrorMsg = ''

************************
   PROCEDURE BuildGross
************************   
      LPARAMETERS toProgress, ;
         tcOwner1, ;
         tcOwner2, ;
         tcWellID1, ;
         tcWellID2, ;
         tcYear, ;
         llTaxCode, ;
         llExpCat, ;
         llTotal, ;
         llSuspense, ;
         llProdYear, ;
         llAcctYear, ;
         llPageBreak, ;
         llAggregate, ;
         llTaxRevSect


      TRY

         m.lTotal = llTotal
         llReturn = .T.

         IF VARTYPE(toProgress) # 'O'
            llProgress = .F.
         ELSE
            llProgress = .T.
         ENDIF

         IF llProdYear
            lcWhere   = 'wellhist.hyear = tcyear'
            lcWhereD  = 'hyear = tcyear'
            lcGroupBy = 'wellhist.cwellid, wellhist.hperiod'
            lcPeriod  = 'hPeriod as cperiod'
         ELSE
            lcWhere   = "wellhist.crunyear+PADL(TRANSFORM(wellhist.nrunno),3,'0')+wellhist.crectype in (select crunyear+PADL(TRANSFORM(nrunno),3,'0')+ctypeclose from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcWhereD  = "crunyear+PADL(TRANSFORM(nrunno),3,'0')+crectype in (select crunyear+PADL(TRANSFORM(nrunno),3,'0')+ctypeclose from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcGroupBy = 'wellhist.cwellid, cperiod'
            lcPeriod  = "padl(TRANSFORM(MONTH(hdate)),2,'0') as cPeriod"
         ENDIF

         STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
            m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12


         SELECT  disbhist.cownerid, ;
                 disbhist.cWellid, ;
                 disbhist.ctypeinv, ;
                 MAX(ownpcts.nrevoil) AS nrevoil, ;
                 MAX(ownpcts.nRevGas) AS nRevGas, ;
                 MAX(ownpcts.nRevOth) AS nRevOth, ;
                 MAX(ownpcts.nWorkInt) AS nWorkInt ;
             FROM disbhist ;
             JOIN ownpcts ;
                 ON disbhist.ciddisb == ownpcts.ciddisb ;
             WHERE &lcWhereD ;
                 AND disbhist.cWellid IN (SELECT  cid ;
                                              FROM selectedwells) ;
                 AND disbhist.cownerid IN (SELECT  cid ;
                                               FROM SELECTED) ;
             INTO CURSOR wellinvtemp  READWRITE ;
             GROUP BY disbhist.cownerid, disbhist.cWellid, ctypeinv ;
             ORDER BY disbhist.cownerid, disbhist.cWellid, ctypeinv

         SELECT  suspense.cownerid, ;
                 suspense.cWellid, ;
                 suspense.ctypeinv, ;
                 MAX(suspense.nrevoil) AS nrevoil, ;
                 MAX(suspense.nRevGas) AS nRevGas, ;
                 MAX(suspense.nRevOth) AS nRevOth, ;
                 MAX(suspense.nWorkInt) AS nWorkInt ;
             FROM suspense ;
             WHERE &lcWhereD ;
                 AND suspense.cWellid IN (SELECT  cid ;
                                              FROM selectedwells) ;
                 AND suspense.cownerid IN (SELECT  cid ;
                                               FROM SELECTED) ;
             INTO CURSOR wellinvtemp1 ;
             GROUP BY suspense.cownerid, suspense.cWellid, ctypeinv ;
             ORDER BY suspense.cownerid, suspense.cWellid, ctypeinv

         SELECT wellinvtemp1
         SCAN
            SCATTER MEMVAR
            SELECT wellinvtemp
            LOCATE FOR cWellid == m.cWellid AND cownerid == m.cownerid AND ctypeinv = m.ctypeinv
            IF NOT FOUND()
               INSERT INTO wellinvtemp FROM MEMVAR
            ENDIF
         ENDSCAN

         lnMax              = RECCOUNT('wellinvtemp')

         IF llProgress
            toProgress.SetProgressRange(0, lnMax)
         ENDIF
         lnCount = 1

         SELECT wellinvtemp
         SCAN
            STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
               m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12, m.nPrdAmtN
            STORE '' TO m.cDesc

            m.cWellid  = cWellid
            m.nWrkPct  = nWorkInt
            m.ctypeinv = ctypeinv
            m.nRevPct  = ICASE(nrevoil # 0, nrevoil, nRevGas # 0, nRevGas, nRevOth)
            m.cownerid = cownerid
            lcOwnerID  = cownerid

            IF llProgress
               toProgress.SetProgressMessage('Well: ' + m.cWellid)
               toProgress.UpdateProgress(lnCount)
            ENDIF
            lnCount = lnCount + 1

            swselect('investor')
            SET ORDER TO cownerid
            IF SEEK(m.cownerid)
               m.cOwnName = cOwnName
            ENDIF

********************************************************************
*  Fill in the Gross Amounts for the Year
********************************************************************

            IF VARTYPE(m.goapp.oLogger) = 'O'
               m.goapp.oLogger.LogMilestone('DMROWNPL: BuildGross: Well: ' + m.cWellid + ' Building Gross Oil Revenue...')
            ENDIF

            IF llProgress
               toProgress.SetProgressMessage('Building Well Gross - Well: ' + m.cWellid)
               toProgress.UpdateProgress(lnCount)
            ENDIF

            llReturn = THIS.SelectGrossDataAmt(tcYear, ;
                 lcPeriod, ;
                 m.cownerid, ;
                 m.ctypeinv, ;
                 m.cWellid, ;
                 lcWhere, ;
                 lcGroupBy, ;
                 llTaxCode, ;
                 llExpCat, ;
                 llAggregate, ;
                 llTaxRevSect)
            DO CASE
               CASE llTaxCode  &&  Subtotaling by tax code

** pws 12/18/21 - In process of fixing the doubling of expenses because the revenue and jib runs have the same run number on them
                  IF VARTYPE(m.goapp.oLogger) = 'O'
                     m.goapp.oLogger.LogMilestone('DMROWNPL: BuildGross: Well: ' + m.cWellid + '  Subtotaling Expenses by Tax Code')
                  ENDIF
                  m.cGroup   = '1'
                  m.cSection = 'B'

                  IF llProdYear
                     SELECT  expcat.ctaxCode AS cSource,  ;
                             taxcodes.cDesc AS cDesc, ;
                             SUM(expense.nAmount) AS nAmount, ;
                             expense.ccatcode, ;
                             expense.cexpclass, ;
                             expense.cyear, ;
                             expense.cperiod, ;
                             expense.cownerid, ;
                             IIF(expense.crunyearrev > '1901', expense.crunyearrev, expense.crunyearjib) AS crunyearjib, ;
                             IIF(expense.nrunnorev # 0, expense.nrunnorev, expense.nrunnojib) AS nrunnojib ;
                         FROM taxcodes, expense ;
                         JOIN expcat ;
                             ON expcat.ccatcode = expense.ccatcode ;
                         WHERE cWellid == m.cWellid ;
                             AND cyear == tcYear ;
                             AND nrunnorev # 0 ;
                             AND nrunnojib # 0 ;
                             AND expcat.ctaxCode = taxcodes.ctaxCode ;
                         INTO CURSOR yearexpense READWRITE ;
                         ORDER BY expcat.ctaxCode, expense.cexpclass, cperiod, cownerid;
                         GROUP BY expcat.ctaxCode, expense.cexpclass, cperiod, cownerid
                  ELSE
                     SELECT  expense.ccatcode, ;
                             expense.cexpclass, ;
                             expcat.ctaxCode AS cSource, ;
                             taxcodes.cDesc, ;
                             SUM(expense.nAmount) AS nAmount, ;
                             expense.nrunnorev, ;
                             expense.crunyearrev, ;
                             expense.nrunnojib, ;
                             expense.crunyearjib, ;
                             expense.cownerid, ;
                             PADL(ALLTRIM(STR(MONTH(sysctl.dacctdate), 2)), 2, '0') AS cperiod, ;
                             tcYear AS cyear ;
                         FROM expense ;
                         JOIN expcat ;
                             ON expcat.ccatcode = expense.ccatcode, ;
                             sysctl, taxcodes ;
                         WHERE cWellid == m.cWellid ;
                             AND taxcodes.ctaxCode = expcat.ctaxCode  ;
                             AND crunyearrev + PADL(TRANSFORM(nrunnorev), 3, '0') + 'R' + tcYear = ;
                             sysctl.crunyear + PADL(TRANSFORM(sysctl.nrunno), 3, '0') + sysctl.ctypeclose + TRANSFORM(YEAR(sysctl.dacctdate)) ;
                             AND nrunnorev # 0 ;
                             AND nrunnojib # 0 ;
                         INTO CURSOR yearexpense READWRITE ;
                         ORDER BY expcat.ctaxCode, expense.cexpclass, 11, expense.cownerid ;
                         GROUP BY expcat.ctaxCode, expense.cexpclass, 11, expense.cownerid
                     IF _TALLY = 0
                        SELECT  expense.ccatcode, ;
                                expense.cexpclass, ;
                                expcat.ctaxCode AS cSource, ;
                                taxcodes.cDesc, ;
                                SUM(expense.nAmount) AS nAmount, ;
                                expense.nrunnorev, ;
                                expense.crunyearrev, ;
                                expense.nrunnojib, ;
                                expense.crunyearjib, ;
                                expense.cownerid, ;
                                PADL(ALLTRIM(STR(MONTH(sysctl.dacctdate), 2)), 2, '0') AS cperiod, ;
                                tcYear AS cyear ;
                            FROM expense ;
                            JOIN expcat ;
                                ON expcat.ccatcode = expense.ccatcode, ;
                                sysctl, taxcodes ;
                            WHERE cWellid == m.cWellid ;
                                AND expcat.ctaxCode = taxcodes.ctaxCode ;
                                AND crunyearjib + PADL(TRANSFORM(nrunnojib), 3, '0') + 'J' + tcYear = ;
                                sysctl.crunyear + PADL(TRANSFORM(sysctl.nrunno), 3, '0') + sysctl.ctypeclose + TRANSFORM(YEAR(sysctl.dacctdate)) ;
                                AND nrunnorev # 0 ;
                                AND nrunnojib # 0 ;
                            INTO CURSOR yearexpense ;
                            ORDER BY expcat.ctaxCode, expense.cexpclass, 11, expense.cownerid ;
                            GROUP BY expcat.ctaxCode, expense.cexpclass, 11, expense.cownerid
                     ENDIF
                  ENDIF

                  lcOwnerID = m.cownerid
                  SELECT yearexpense
                  SCAN
                     SCATTER MEMVAR
                     STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
                        m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12, ;
                        m.nWorkInt, m.nIntclass1, m.nIntClass2, m.nIntClass3, m.nIntClass4, m.nIntClass5
                     m.cperiod   = cperiod
                     m.nAmount   = nAmount
                     m.cexpclass = cexpclass
                     m.cGroup    = '1'

                     llOneMan = .F.
                     IF EMPTY(cexpclass)
                        REPLACE yearexpense.cexpclass WITH '0'
                     ENDIF
                     IF NOT EMPTY(cownerid)
                        IF cownerid = m.cownerid
                           llOneMan = .T.
                        ELSE
                           LOOP
                        ENDIF
                     ENDIF

                     THIS.LoadPrdAmt(m.cperiod, m.nAmount, m.cSource, m.cGroup, m.cSection, lcOwnerID, m.cWellid, m.ctypeinv, .F.)


&&  Owner's Share of the expense

                     m.cGroup = '2'
                     STORE 0 TO m.nWorkInt, m.nIntclass1, m.nIntClass2, m.nIntClass3, m.nIntClass4, m.nIntClass5, m.nBCPInt, m.nACPInt
                     swselect('disbhist')  &&  Match up the JIB run number to get their working interests in this well
                     LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND disbhist.cRectype = 'J' ;
                        AND disbhist.crunyear = yearexpense.crunyearjib AND disbhist.nrunno = yearexpense.nrunnojib  ;
                        AND ctypeinv = m.ctypeinv AND NOT lManual
                     IF FOUND()
                        swselect('ownpcts')
                        LOCATE FOR ciddisb == disbhist.ciddisb
                        IF FOUND()
                           m.nWorkInt   = nWorkInt
                           m.nIntclass1 = nIntclass1
                           m.nIntClass2 = nIntClass2
                           m.nIntClass3 = nIntClass3
                           m.nIntClass4 = nIntClass4
                           m.nIntClass5 = nIntClass5
                           m.nBCPInt    = nBCPInt
                           m.nACPInt    = nACPInt
                        ENDIF
                     ELSE
                        swselect('disbhist')  &&  Match up the revenue run number to get their working interests in this well
                        LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND disbhist.cRectype = 'R' ;
                           AND disbhist.crunyear = yearexpense.crunyearjib AND disbhist.nrunno = yearexpense.nrunnojib  AND ctypeinv = m.ctypeinv AND NOT lManual
                        IF FOUND()
                           swselect('ownpcts')
                           LOCATE FOR ciddisb == disbhist.ciddisb
                           IF FOUND()
                              m.nWorkInt   = nWorkInt
                              m.nIntclass1 = nIntclass1
                              m.nIntClass2 = nIntClass2
                              m.nIntClass3 = nIntClass3
                              m.nIntClass4 = nIntClass4
                              m.nIntClass5 = nIntClass5
                              m.nBCPInt    = nBCPInt
                              m.nACPInt    = nACPInt
                           ENDIF
                        ELSE
                           swselect('disbhist')  &&  If it can't find a WI, check to see if they're anywhere in this well with a royalty interest in this well
                           LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND disbhist.cRectype = 'R' ;
                              AND disbhist.crunyear = yearexpense.crunyearjib AND disbhist.nrunno = yearexpense.nrunnojib  AND ctypeinv = m.ctypeinv AND NOT lManual
                           IF FOUND()
                              swselect('ownpcts')
                              LOCATE FOR ciddisb == disbhist.ciddisb
                              IF FOUND()
                                 m.nWorkInt   = nWorkInt
                                 m.nIntclass1 = nIntclass1
                                 m.nIntClass2 = nIntClass2
                                 m.nIntClass3 = nIntClass3
                                 m.nIntClass4 = nIntClass4
                                 m.nIntClass5 = nIntClass5
                                 m.nBCPInt    = nBCPInt
                                 m.nACPInt    = nACPInt
                              ENDIF
                           ELSE
                              swselect('suspense')  &&  Look to see if this owner's data is still in suspense
                              LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND cRectype = 'R' ;
                                 AND crunyear = yearexpense.crunyearjib AND nrunno = yearexpense.nrunnojib  AND ctypeinv = m.ctypeinv
                              IF FOUND() AND llSuspense  &&  Only find it if they're including suspense activity
                                 m.nWorkInt   = nWorkInt
                                 m.nIntclass1 = nIntclass1
                                 m.nIntClass2 = nIntClass2
                                 m.nIntClass3 = nIntClass3
                                 m.nIntClass4 = nIntClass4
                                 m.nIntClass5 = nIntClass5
                                 m.nBCPInt    = nBCPInt
                                 m.nACPInt    = nACPInt
                              ELSE
                                 LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND cRectype = 'R' ;
                                    AND crunyear = yearexpense.crunyearrev AND nrunno = yearexpense.nrunnorev  AND ctypeinv = m.ctypeinv
                                 IF FOUND() AND llSuspense  &&  Only find it if they're including suspense activity
                                    m.nWorkInt   = nWorkInt
                                    m.nIntclass1 = nIntclass1
                                    m.nIntClass2 = nIntClass2
                                    m.nIntClass3 = nIntClass3
                                    m.nIntClass4 = nIntClass4
                                    m.nIntClass5 = nIntClass5
                                    m.nBCPInt    = nBCPInt
                                    m.nACPInt    = nACPInt
                                 ELSE
                                    swselect('wellinv')  &&  No history, so look it up in wellinv - should never get here, but just in case....
                                    LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID  AND ctypeinv = m.ctypeinv
                                    IF FOUND()
                                       m.nWorkInt   = nWorkInt
                                       m.nIntclass1 = nIntclass1
                                       m.nIntClass2 = nIntClass2
                                       m.nIntClass3 = nIntClass3
                                       m.nIntClass4 = nIntClass4
                                       m.nIntClass5 = nIntClass5
                                       m.nBCPInt    = nBCPInt
                                       m.nACPInt    = nACPInt
                                    ENDIF
                                 ENDIF
                              ENDIF
                           ENDIF
                        ENDIF
                     ENDIF

                     DO CASE
                        CASE m.cexpclass = '0'
                           lnInterest = m.nWorkInt
                        CASE m.cexpclass = '1'
                           lnInterest = m.nIntclass1
                        CASE m.cexpclass = '2'
                           lnInterest = m.nIntClass2
                        CASE m.cexpclass = '3'
                           lnInterest = m.nIntClass3
                        CASE m.cexpclass = '4'
                           lnInterest = m.nIntClass4
                        CASE m.cexpclass = '5'
                           lnInterest = m.nIntClass5
                        CASE m.cexpclass = 'A'
                           lnInterest = m.nACPInt
                        CASE m.cexpclass = 'B'
                           lnInterest = m.nBCPInt
                        OTHERWISE
                           lnInterest = 0
                     ENDCASE

                     DO CASE  &&  Multiply the owner share by their percentage for that run
                        CASE yearexpense.cperiod = '01'
                           m.nPrdAmt1  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '02'
                           m.nPrdAmt2  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '03'
                           m.nPrdAmt3  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '04'
                           m.nPrdAmt4  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '05'
                           m.nPrdAmt5  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '06'
                           m.nPrdAmt6  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '07'
                           m.nPrdAmt7  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '08'
                           m.nPrdAmt8  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '09'
                           m.nPrdAmt9  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '10'
                           m.nPrdAmt10 = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '11'
                           m.nPrdAmt11 = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '12'
                           m.nPrdAmt12 = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                     ENDCASE

                     SELECT temppl
                     SET ORDER TO wellsrc
                     IF SEEK(lcOwnerID + m.cWellid + m.ctypeinv + m.cGroup + m.cSection + m.cSource)
                        REPLACE nPrdAmt1  WITH nPrdAmt1 + m.nPrdAmt1, ;
                           nPrdAmt2  WITH nPrdAmt2 + m.nPrdAmt2, ;
                           nPrdAmt3  WITH nPrdAmt3 + m.nPrdAmt3, ;
                           nPrdAmt4  WITH nPrdAmt4 + m.nPrdAmt4, ;
                           nPrdAmt5  WITH nPrdAmt5 + m.nPrdAmt5, ;
                           nPrdAmt6  WITH nPrdAmt6 + m.nPrdAmt6, ;
                           nPrdAmt7  WITH nPrdAmt7 + m.nPrdAmt7, ;
                           nPrdAmt8  WITH nPrdAmt8 + m.nPrdAmt8, ;
                           nPrdAmt9  WITH nPrdAmt9 + m.nPrdAmt9, ;
                           nPrdAmt10 WITH nPrdAmt10 + m.nPrdAmt10, ;
                           nPrdAmt11 WITH nPrdAmt11 + m.nPrdAmt11, ;
                           nPrdAmt12 WITH nPrdAmt12 + m.nPrdAmt12
                     ELSE
                        m.cownerid = lcOwnerID
                        INSERT INTO temppl FROM MEMVAR
                     ENDIF
                     STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
                        m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12, ;
                        m.nWorkInt, m.nIntclass1, m.nIntClass2, m.nIntClass3, m.nIntClass4, m.nIntClass5

                  ENDSCAN && YearExpense

               CASE llExpCat  &&  Subtotaling by Expense Category
                  IF VARTYPE(m.goapp.oLogger) = 'O'
                     m.goapp.oLogger.LogMilestone('DMROWNPL: BuildGross: Well: ' + m.cWellid + '  Subtotaling by Expense Cat...')
                  ENDIF

                  m.cGroup   = '1'
                  m.cSection = 'B'

* Get the expenses for the production year or accounting year
                  IF llProdYear
                     SELECT  expense.ccatcode, ;
                             expense.cexpclass, ;
                             expense.ccateg, ;
                             SUM(expense.nAmount) AS nAmount, ;
                             expense.cyear, ;
                             expense.cperiod, ;
                             expense.cownerid, ;
                             IIF(expense.crunyearrev > '1901', expense.crunyearrev, expense.crunyearjib) AS crunyearjib, ;
                             IIF(expense.nrunnorev # 0, expense.nrunnorev, expense.nrunnojib) AS nrunnojib ;
                         FROM expense ;
                         WHERE cWellid == m.cWellid ;
                             AND cyear == tcYear ;
                             AND nrunnorev # 0 ;
                             AND nrunnojib # 0 ;
                         INTO CURSOR yearexpense READWRITE ;
                         ORDER BY ccatcode, cexpclass, cyear, cperiod, cownerid;
                         GROUP BY ccatcode, cexpclass, cyear, cperiod, cownerid
                  ELSE
                     SELECT  ccatcode, ;
                             cexpclass, ;
                             ccateg, ;
                             SUM(nAmount) AS nAmount, ;
                             nrunnorev, ;
                             crunyearrev, ;
                             IIF(expense.crunyearrev > '1901', expense.crunyearrev, expense.crunyearjib) AS crunyearjib, ;
                             IIF(expense.nrunnorev # 0, expense.nrunnorev, expense.nrunnojib) AS nrunnojib, ;
                             cownerid, ;
                             tcYear AS cyear, ;
                             PADL(ALLTRIM(STR(MONTH(sysctl.dacctdate), 2)), 2, '0') AS cperiod  ;
                         FROM expense, sysctl ;
                         WHERE cWellid == m.cWellid ;
                             AND (crunyearrev + PADL(TRANSFORM(nrunnorev), 3, '0') + 'R' == sysctl.crunyear + PADL(TRANSFORM(sysctl.nrunno), 3, '0') + sysctl.ctypeclose) ;
                             AND YEAR(sysctl.dacctdate) = VAL(tcYear) ;
                         INTO CURSOR yearexpense READWRITE ;
                         ORDER BY ccatcode, cexpclass, 11, cownerid ;
                         GROUP BY ccatcode, cexpclass, 11, cownerid

                     IF _TALLY = 0
                        SELECT  ccatcode, ;
                                cexpclass, ;
                                ccateg, ;
                                SUM(nAmount) AS nAmount, ;
                                nrunnorev, ;
                                crunyearrev, ;
                                IIF(expense.crunyearrev > '1901', expense.crunyearrev, expense.crunyearjib) AS crunyearjib, ;
                                IIF(expense.nrunnorev # 0, expense.nrunnorev, expense.nrunnojib) AS nrunnojib, ;
                                cownerid, ;
                                tcYear AS cyear, ;
                                PADL(ALLTRIM(STR(MONTH(sysctl.dacctdate), 2)), 2, '0') AS cperiod ;
                            FROM expense, sysctl ;
                            WHERE cWellid == m.cWellid ;
                                AND ccatcode == expcat.ccatcode ;
                                AND (crunyearjib + PADL(TRANSFORM(nrunnojib), 3, '0') + 'J' == sysctl.crunyear + PADL(TRANSFORM(sysctl.nrunno), 3, '0') + sysctl.ctypeclose) ;
                                AND YEAR(sysctl.dacctdate) = VAL(tcYear) ;
                            INTO CURSOR yearexpense READWRITE ;
                            ORDER BY ccatcode, cexpclass, 11, cownerid ;
                            GROUP BY ccatcode, cexpclass, 11, cownerid
                     ENDIF
                  ENDIF

                  SELECT yearexpense
                  SCAN
                     STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
                        m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12, ;
                        m.nWorkInt, m.nIntclass1, m.nIntClass2, m.nIntClass3, m.nIntClass4, m.nIntClass5
                     m.cperiod   = cperiod
                     m.nAmount   = nAmount
                     m.cDesc     = ccateg
                     m.cSource   = ccatcode
                     m.cexpclass = cexpclass
                     m.cGroup    = '1'

                     llOneMan = .F.
                     IF EMPTY(cexpclass)
                        REPLACE yearexpense.cexpclass WITH '0'
                     ENDIF
                     IF NOT EMPTY(cownerid)
                        IF cownerid = m.cownerid
                           llOneMan = .T.
                        ELSE
                           LOOP
                        ENDIF
                     ENDIF

                     THIS.LoadPrdAmt(m.cperiod, m.nAmount, m.cSource, m.cGroup, m.cSection, lcOwnerID, m.cWellid, m.ctypeinv, .F.)

*******************************
*  Owner's Share of the expense
*******************************

                     m.cGroup = '2'
                     STORE 0 TO m.nWorkInt, m.nIntclass1, m.nIntClass2, m.nIntClass3, m.nIntClass4, m.nIntClass5, m.nBCPInt, m.nACPInt
                     llFound = .F.

                     swselect('disbhist')  &&  Match up the JIB run number to get their working interests in this well
                     LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND disbhist.cRectype = 'J' AND ctypeinv = m.ctypeinv ;
                        AND disbhist.hyear = yearexpense.cyear AND disbhist.hperiod = yearexpense.cperiod ;
                        AND ((disbhist.crunyear = yearexpense.crunyearjib AND disbhist.nrunno = yearexpense.nrunnojib) OR ;
                          (disbhist.crunyear_in = yearexpense.crunyearjib AND disbhist.nrunno_in = yearexpense.nrunnojib)) ;
                        AND NOT lManual
                     IF FOUND()
                        IF llProdYear AND (disbhist.hyear + disbhist.hperiod # yearexpense.cyear + yearexpense.cperiod)
                           LOOP
                        ENDIF
                        llFound = .T.
                        swselect('ownpcts')
                        LOCATE FOR ciddisb == disbhist.ciddisb
                        IF FOUND()
                           m.nWorkInt   = m.nWorkInt + nWorkInt
                           m.nIntclass1 = m.nIntclass1 + nIntclass1
                           m.nIntClass2 = m.nIntClass2 + nIntClass2
                           m.nIntClass3 = m.nIntClass3 + nIntClass3
                           m.nIntClass4 = m.nIntClass4 + nIntClass4
                           m.nIntClass5 = m.nIntClass5 + nIntClass5
                           m.nBCPInt    = m.nBCPInt + nBCPInt
                           m.nACPInt    = m.nACPInt + nACPInt
                        ENDIF
                     ENDIF
                     IF NOT llFound
                        swselect('disbhist')  &&  Match up the revenue run number to get their working interests in this well
                        LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND disbhist.cRectype = 'R' AND ctypeinv = m.ctypeinv ;
                           AND disbhist.hyear = yearexpense.cyear AND disbhist.hperiod = yearexpense.cperiod ;
                           AND ((disbhist.crunyear = yearexpense.crunyearjib AND disbhist.nrunno = yearexpense.nrunnojib) OR ;
                             (disbhist.crunyear_in = yearexpense.crunyearjib AND disbhist.nrunno_in = yearexpense.nrunnojib)) ;
                           AND NOT lManual
                        IF FOUND()
                           IF llProdYear AND (disbhist.hyear + disbhist.hperiod # yearexpense.cyear + yearexpense.cperiod)
                              LOOP
                           ENDIF
                           llFound = .T.
                           swselect('ownpcts')
                           LOCATE FOR ciddisb == disbhist.ciddisb
                           IF FOUND()
                              m.nWorkInt   = m.nWorkInt + nWorkInt
                              m.nIntclass1 = m.nIntclass1 + nIntclass1
                              m.nIntClass2 = m.nIntClass2 + nIntClass2
                              m.nIntClass3 = m.nIntClass3 + nIntClass3
                              m.nIntClass4 = m.nIntClass4 + nIntClass4
                              m.nIntClass5 = m.nIntClass5 + nIntClass5
                              m.nBCPInt    = m.nBCPInt + nBCPInt
                              m.nACPInt    = m.nACPInt + nACPInt
                           ENDIF
                        ENDIF
                     ENDIF
                     IF NOT llFound
                        swselect('disbhist')  &&  If it can't find a WI, check to see if they're anywhere in this well with a royalty interest in this well
                        LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND disbhist.cRectype = 'R'  AND ctypeinv = m.ctypeinv ;
                           AND disbhist.hyear = yearexpense.cyear AND disbhist.hperiod = yearexpense.cperiod ;
                           AND ((disbhist.crunyear = yearexpense.crunyearjib AND disbhist.nrunno = yearexpense.nrunnojib) OR ;
                             (disbhist.crunyear_in = yearexpense.crunyearjib AND disbhist.nrunno_in = yearexpense.nrunnojib)) ;
                           AND NOT lManual
                        IF FOUND()
                           IF llProdYear AND (disbhist.hyear + disbhist.hperiod # yearexpense.cyear + yearexpense.cperiod)
                              LOOP
                           ENDIF
                           llFound = .T.
                           swselect('ownpcts')
                           LOCATE FOR ciddisb == disbhist.ciddisb
                           IF FOUND()
                              m.nWorkInt   = m.nWorkInt + nWorkInt
                              m.nIntclass1 = m.nIntclass1 + nIntclass1
                              m.nIntClass2 = m.nIntClass2 + nIntClass2
                              m.nIntClass3 = m.nIntClass3 + nIntClass3
                              m.nIntClass4 = m.nIntClass4 + nIntClass4
                              m.nIntClass5 = m.nIntClass5 + nIntClass5
                              m.nBCPInt    = m.nBCPInt + nBCPInt
                              m.nACPInt    = m.nACPInt + nACPInt
                           ENDIF
                        ENDIF
                     ENDIF
                     IF NOT llFound AND llSuspense
                        swselect('suspense')  &&  Look to see if this owner's data is still in suspense
                        LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND cRectype = 'R'  AND ctypeinv = m.ctypeinv ;
                           AND suspense.hyear = yearexpense.cyear AND suspense.hperiod = yearexpense.cperiod ;
                           AND ((suspense.crunyear = yearexpense.crunyearjib AND suspense.nrunno = yearexpense.nrunnojib) OR ;
                             (suspense.crunyear_in = yearexpense.crunyearjib AND suspense.nrunno_in = yearexpense.nrunnojib))
                        IF FOUND()
                           IF llProdYear AND (suspense.hyear + suspense.hperiod # yearexpense.cyear + yearexpense.cperiod)
                              LOOP
                           ENDIF
                           llFound      = .T.
                           m.nWorkInt   = m.nWorkInt + nWorkInt
                           m.nIntclass1 = m.nIntclass1 + nIntclass1
                           m.nIntClass2 = m.nIntClass2 + nIntClass2
                           m.nIntClass3 = m.nIntClass3 + nIntClass3
                           m.nIntClass4 = m.nIntClass4 + nIntClass4
                           m.nIntClass5 = m.nIntClass5 + nIntClass5
                           m.nBCPInt    = m.nBCPInt + nBCPInt
                           m.nACPInt    = m.nACPInt + nACPInt
                        ENDIF
                     ENDIF
                     IF NOT llFound AND llSuspense
                        LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND cRectype = 'R' ;
                           AND suspense.hyear = yearexpense.cyear AND suspense.hperiod = yearexpense.cperiod ;
                           AND ((suspense.crunyear = yearexpense.crunyearjib AND suspense.nrunno = yearexpense.nrunnojib) OR ;
                             (suspense.crunyear_in = yearexpense.crunyearjib AND suspense.nrunno_in = yearexpense.nrunnojib)) ;
                           AND ctypeinv = m.ctypeinv
                        IF FOUND()
                           IF llProdYear AND (suspense.hyear + suspense.hperiod # yearexpense.cyear + yearexpense.cperiod)
                              LOOP
                           ENDIF
                           llFound      = .T.
                           m.nWorkInt   = nWorkInt
                           m.nIntclass1 = nIntclass1
                           m.nIntClass2 = nIntClass2
                           m.nIntClass3 = nIntClass3
                           m.nIntClass4 = nIntClass4
                           m.nIntClass5 = nIntClass5
                           m.nBCPInt    = nBCPInt
                           m.nACPInt    = nACPInt
                        ENDIF
                     ENDIF
                     IF NOT llFound
                        swselect('wellinv') &&  No history, so look it up in wellinv - should never get here, but just in case....
                        LOCATE FOR cWellid = m.cWellid AND cownerid = lcOwnerID AND ctypeinv = m.ctypeinv
                        IF FOUND()
                           m.nWorkInt   = nWorkInt
                           m.nIntclass1 = nIntclass1
                           m.nIntClass2 = nIntClass2
                           m.nIntClass3 = nIntClass3
                           m.nIntClass4 = nIntClass4
                           m.nIntClass5 = nIntClass5
                           m.nBCPInt    = nBCPInt
                           m.nACPInt    = nACPInt
                        ENDIF
                     ENDIF

                     DO CASE
                        CASE m.cexpclass = '0'
                           lnInterest = m.nWorkInt
                        CASE m.cexpclass = '1'
                           lnInterest = m.nIntclass1
                        CASE m.cexpclass = '2'
                           lnInterest = m.nIntClass2
                        CASE m.cexpclass = '3'
                           lnInterest = m.nIntClass3
                        CASE m.cexpclass = '4'
                           lnInterest = m.nIntClass4
                        CASE m.cexpclass = '5'
                           lnInterest = m.nIntClass5
                        CASE m.cexpclass = 'A'
                           lnInterest = m.nACPInt
                        CASE m.cexpclass = 'B'
                           lnInterest = m.nBCPInt
                        OTHERWISE
                           lnInterest = 0
                     ENDCASE


                     DO CASE  &&  Multiply the owner share by their percentage for that run
                        CASE yearexpense.cperiod = '01'
                           m.nPrdAmt1  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '02'
                           m.nPrdAmt2  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '03'
                           m.nPrdAmt3  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '04'
                           m.nPrdAmt4  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '05'
                           m.nPrdAmt5  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '06'
                           m.nPrdAmt6  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '07'
                           m.nPrdAmt7  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '08'
                           m.nPrdAmt8  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '09'
                           m.nPrdAmt9  = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '10'
                           m.nPrdAmt10 = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '11'
                           m.nPrdAmt11 = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                        CASE yearexpense.cperiod = '12'
                           m.nPrdAmt12 = yearexpense.nAmount * IIF(llOneMan, 1, (lnInterest) / 100)
                     ENDCASE
                     SELECT temppl
                     SET ORDER TO wellsrc
                     IF SEEK(lcOwnerID + m.cWellid + m.ctypeinv + m.cGroup + m.cSection + m.cSource)
                        REPLACE nPrdAmt1  WITH nPrdAmt1 + m.nPrdAmt1, ;
                           nPrdAmt2  WITH nPrdAmt2 + m.nPrdAmt2, ;
                           nPrdAmt3  WITH nPrdAmt3 + m.nPrdAmt3, ;
                           nPrdAmt4  WITH nPrdAmt4 + m.nPrdAmt4, ;
                           nPrdAmt5  WITH nPrdAmt5 + m.nPrdAmt5, ;
                           nPrdAmt6  WITH nPrdAmt6 + m.nPrdAmt6, ;
                           nPrdAmt7  WITH nPrdAmt7 + m.nPrdAmt7, ;
                           nPrdAmt8  WITH nPrdAmt8 + m.nPrdAmt8, ;
                           nPrdAmt9  WITH nPrdAmt9 + m.nPrdAmt9, ;
                           nPrdAmt10 WITH nPrdAmt10 + m.nPrdAmt10, ;
                           nPrdAmt11 WITH nPrdAmt11 + m.nPrdAmt11, ;
                           nPrdAmt12 WITH nPrdAmt12 + m.nPrdAmt12
                     ELSE
                        m.cownerid = lcOwnerID
                        INSERT INTO temppl FROM MEMVAR
                     ENDIF
                     STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
                        m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12, ;
                        m.nWorkInt, m.nIntclass1, m.nIntClass2, m.nIntClass3, m.nIntClass4, m.nIntClass5

                  ENDSCAN && YearExpense
            ENDCASE
         ENDSCAN && Wellinvtmp

         IF VARTYPE(m.goapp.oLogger) = 'O'
            m.goapp.oLogger.EndProcess('DMROWNPL: BuildGross Finished...')
         ENDIF
         IF VARTYPE(toProgress) = 'O'
            toProgress.closeprogress()
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'buildgross', loError.LINENO, 'Lease Oper Stmt', loError.ERRORNO, loError.MESSAGE, '', loError
         IF VARTYPE(toProgress) = 'O'
            toProgress.closeprogress()
         ENDIF
         THIS.cErrorMsg = 'Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com'
      ENDTRY

      RETURN llReturn
   ENDPROC

****************************
   PROCEDURE BuildNet
****************************
      LPARAMETERS toProgress, ;
         tcOwner1, ;
         tcOwner2, ;
         tcWellID1, ;
         tcWellID2, ;
         tcYear, ;
         llTaxCode, ;
         llExpCat, ;
         llTotal, ;
         llSuspense, ;
         llProdYear, ;
         llAcctYear, ;
         llPageBreak, ;
         tlAggregate, ;
         llTaxRevSect

      TRY

         IF VARTYPE(toProgress) = 'O'
            llProgress = .T.
         ELSE
            llProgress = .F.
         ENDIF

         m.lTotal   = llTotal

         IF llProdYear
            lcWhere    = 'disbhist.hyear = tcyear'
            lcWhereS   = 'suspense.hyear = tcyear'
            lcWhereD   = 'disbhist.hyear = tcyear'
            lcGroupBy  = 'disbhist.cownerid, disbhist.cwellid, disbhist.ctypeinv, disbhist.hperiod'
            lcGroupByS = 'suspense.cownerid, suspense.cwellid, suspense.ctypeinv, suspense.hperiod'
            lcPeriod   = 'hperiod   AS cPeriod'
            lcWellName = 'wells.cwellname as cwellname'
         ELSE
            lcWhere    = "disbhist.crunyear+PADL(TRANSFORM(disbhist.nrunno),3,'0')+disbhist.crectype in (select crunyear+PADL(TRANSFORM(nrunno),3,'0')+ctypeclose from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcWhereS   = "suspense.crunyear_IN+PADL(TRANSFORM(suspense.nrunno_IN),3,'0')+'R' in (select crunyear+PADL(TRANSFORM(nrunno),3,'0')+ctypeclose from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcWhereD   = "disbhist.crunyear+PADL(TRANSFORM(disbhist.nrunno),3,'0')+disbhist.crectype in (select crunyear+PADL(TRANSFORM(nrunno),3,'0')+ctypeclose from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcGroupBy  = 'disbhist.cownerid, disbhist.cwellid, disbhist.ctypeinv, disbhist.hdate, disbhist.hyear, disbhist.hperiod'
            lcGroupByS = 'suspense.cownerid, suspense.cwellid, suspense.ctypeinv, suspense.hdate, suspense.hyear, suspense.hperiod'
            lcPeriod   = "padl(TRANSFORM(MONTH(hdate)),2,'0') as cperiod"
            lcWellName = 'wells.cwellname as cwellname'
         ENDIF

         lnMax    = RECCOUNT('wellinvtemp')

         toProgress = m.goapp.omessage.progressbarex('Building Lease Operating Statements...Owner Nets')
         toProgress.SetProgressRange(0, lnMax)
         lnCount = 1

         SELECT wellinvtemp
         SCAN
            STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
               m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12, m.nPrdAmtN
            STORE 0 TO m.nRevPct1, m.nRevPct2, m.nRevPct3, m.nRevPct4, m.nRevPct5, m.nRevpct6, ;
               m.nRevPct7, m.nRevpct8, m.nRevPct9, m.nRevPct10, m.nRevPct11, m.nRevPct12
            STORE '' TO m.cDesc, m.cSrcID, m.cSource, m.cOwnName, m.cownerid, m.cWellid, m.cWellname, m.cleaseid, ;
               m.cSection, m.cGroup

            m.cWellid  = cWellid
            toProgress.SetProgressMessage('Well: ' + m.cWellid)

            IF VARTYPE(m.goapp.oLogger) = 'O'
               m.goapp.oLogger.StartProcess('DMROWNPL: Buildnet - Well: ' + m.cWellid)
            ENDIF
            m.nWrkPct  = nWorkInt
            m.ctypeinv = ctypeinv
            m.nRevPct  = ICASE(nrevoil # 0, nrevoil, nRevGas # 0, nRevGas, nRevOth)
            m.cownerid = cownerid

            IF llProgress
               toProgress.UpdateProgress(lnCount)
            ENDIF
            lnCount = lnCount + 1

            swselect('investor')
            SET ORDER TO cownerid
            IF SEEK(m.cownerid)
               m.cOwnName = cOwnName
            ELSE
               m.cOwnName = 'Unknown'
            ENDIF

*
********************************************************************
*  Fill in the owner amounts for the year.
********************************************************************
*
            IF VARTYPE(m.goapp.oLogger) = 'O'
               m.goapp.oLogger.LogMilestone('DMROWNPL: Well: ' + m.cWellid + '  Owner: ' + m.cownerid + '  Owner Amounts')
            ENDIF

            llReturn = THIS.SelectNetDataAmt(tcYear, lcPeriod, ;
                 lcWhere, ;
                 lcWellName, ;
                 m.cWellid, ;
                 m.cownerid, ;
                 m.ctypeinv, ;
                 lcGroupBy, ;
                 llSuspense, ;
                 lcWhereS, ;
                 lcGroupByS, ;
                 tlAggregate, ;
                 llTaxCode, ;
                 llExpCat, ;
                 llTaxRevSect)

            IF NOT llReturn
               EXIT
            ENDIF


***************************
* Get the owner's share of each revenue and expense
***************************
            IF VARTYPE(m.goapp.oLogger) = 'O'
               m.goapp.oLogger.StartProcess('DMROWNPL: Well: ' + m.cWellid + '  Owner: ' + m.cownerid + '  Buildnet: Start Get owners share')
            ENDIF

            SELECT temppl
            lnMax     = RECCOUNT()
            lnCount   = 1
            oProgress = m.goapp.omessage.progressbarex("Building the owner's net share...")
            oProgress.SetProgressRange(0, lnMax)

            SCAN FOR cWellid == m.cWellid AND cownerid == m.cownerid AND ctypeinv == m.ctypeinv
               SCATTER MEMVAR
               oProgress.SetProgressMessage('Well: ' + m.cWellid + ' Owner: ' + m.cownerid)
               oProgress.UpdateProgress(lnCount)
               lnCount = lnCount + 1
               IF VARTYPE(m.goapp.oLogger) = 'O'
                  m.goapp.oLogger.StartProcess('DMROWNPL: Well: ' + m.cWellid + '  Owner: ' + m.cownerid + '  Buildnet: Get owners share: Source=' + m.cSource + 'Group=' + m.cGroup)
               ENDIF
               DO CASE
                  CASE m.cSource = 'MC1'
                     REPLACE cDesc WITH 'Gas Sales Volume'
                  CASE m.cSource = 'MC2'
                     REPLACE cDesc WITH 'Gas Sales'
                  CASE m.cSource = 'MC3'
                     REPLACE cDesc WITH 'MKTG Expense'
                  CASE m.cSource = 'BB1'
                     REPLACE cDesc WITH 'Oil Sales Volume'
                  CASE m.cSource = 'BB2'
                     REPLACE cDesc WITH 'Oil Sales'
                  CASE m.cSource = 'TRP'
                     REPLACE cDesc WITH 'Transportation Income'
                  CASE m.cSource = 'OT1'
                     REPLACE cDesc WITH 'Other Sales Volume'
                  CASE m.cSource = 'OTH'
                     REPLACE cDesc WITH 'Other Income'
                  CASE m.cSource = 'MI1'
                     REPLACE cDesc WITH 'Miscellaneous Income'
                  CASE m.cSource = 'TX1'
                     REPLACE cDesc WITH 'Oil Taxes'
                  CASE m.cSource = 'TX2'
                     REPLACE cDesc WITH 'Gas Taxes'
                  CASE m.cSource = 'TX3'
                     REPLACE cDesc WITH 'Other Taxes'
                  CASE m.cSource = 'EX0'
                     REPLACE cDesc WITH 'Operating Expenses'
                  CASE m.cSource = 'EX1'
                     REPLACE cDesc WITH 'Class 1 Expenses'
                  CASE m.cSource = 'EX2'
                     REPLACE cDesc WITH 'Class 2 Expenses'
                  CASE m.cSource = 'EX3'
                     REPLACE cDesc WITH 'Class 3 Expenses'
                  CASE m.cSource = 'EX4'
                     REPLACE cDesc WITH 'Class 4 Expenses'
                  CASE m.cSource = 'EX5'
                     REPLACE cDesc WITH 'Class 5 Expenses'
                  CASE m.cSource = 'EX6'
                     REPLACE cDesc WITH 'BCP Expenses'
                  CASE m.cSource = 'EX7'
                     REPLACE cDesc WITH 'ACP Expenses'
                  CASE m.cSource = 'MC4'
                     REPLACE cDesc WITH 'Compression/Gathering'
               ENDCASE

               IF m.cGroup = '2' AND INLIST(m.cSource, 'BB1', 'MC1', 'OT1')
                  m.nPrdAmt1  = m.nPrdAmt1 * (m.nRevPct / 100)
                  m.nPrdAmt2  = m.nPrdAmt2 * (m.nRevPct / 100)
                  m.nPrdAmt3  = m.nPrdAmt3 * (m.nRevPct / 100)
                  m.nPrdAmt4  = m.nPrdAmt4 * (m.nRevPct / 100)
                  m.nPrdAmt5  = m.nPrdAmt5 * (m.nRevPct / 100)
                  m.nPrdAmt6  = m.nPrdAmt6 * (m.nRevPct / 100)
                  m.nPrdAmt7  = m.nPrdAmt7 * (m.nRevPct / 100)
                  m.nPrdAmt8  = m.nPrdAmt8 * (m.nRevPct / 100)
                  m.nPrdAmt9  = m.nPrdAmt9 * (m.nRevPct / 100)
                  m.nPrdAmt10 = m.nPrdAmt10 * (m.nRevPct / 100)
                  m.nPrdAmt11 = m.nPrdAmt11 * (m.nRevPct / 100)
                  m.nPrdAmt12 = m.nPrdAmt12 * (m.nRevPct / 100)

                  REPLACE nPrdAmt1  WITH m.nPrdAmt1, ;
                     nPrdAmt2  WITH m.nPrdAmt2, ;
                     nPrdAmt3  WITH m.nPrdAmt3, ;
                     nPrdAmt4  WITH m.nPrdAmt4, ;
                     nPrdAmt5  WITH m.nPrdAmt5, ;
                     nPrdAmt6  WITH m.nPrdAmt6 ;
                     nPrdAmt7  WITH m.nPrdAmt7, ;
                     nPrdAmt8  WITH m.nPrdAmt8, ;
                     nPrdAmt9  WITH m.nPrdAmt9, ;
                     nPrdAmt10 WITH m.nPrdAmt10, ;
                     nPrdAmt11 WITH m.nPrdAmt11, ;
                     nPrdAmt12 WITH m.nPrdAmt12
               ENDIF

               SELECT temppl
               m.nPrdAmtN = (nPrdAmt1 + nPrdAmt2 + nPrdAmt3 + nPrdAmt4 + nPrdAmt5 + nPrdAmt6 + ;
                    nPrdAmt7 + nPrdAmt8 + nPrdAmt9 + nPrdAmt10 + nPrdAmt11 + nPrdAmt12) / 12
*
*  Remove expense classes 1-5 if they're zero
*
               IF INLIST(m.cSource, 'EX1', 'EX2', 'EX3', 'EX4', 'EX5', 'EX6', 'EX7', 'MC3')
                  IF m.nPrdAmtN = 0
                     DELETE
                     LOOP
                  ENDIF
               ENDIF
               m.cWellid = cWellid
               swselect('wells')
               SET ORDER TO cWellid
               IF SEEK(m.cWellid)
                  m.cWellname = cWellname
               ELSE
                  m.cWellname = ' '
               ENDIF
               SELECT temppl
               REPLACE cWellname WITH m.cWellname

            ENDSCAN
            IF VARTYPE(oProgress) = 'O'
               oProgress.closeprogress()
               RELEASE oProgress
            ENDIF
            IF VARTYPE(m.goapp.oLogger) = 'O'
               m.goapp.oLogger.EndProcess('DMROWNPL: Well: ' + m.cWellid + '  Owner: ' + m.cownerid + '  Buildnet: Get Owners share finished')
               m.goapp.oLogger.EndProcess('DMROWNPL: Well: ' + m.cWellid + '  Buildnet Finished')
            ENDIF
         ENDSCAN && WellInvTmp

         IF VARTYPE(toProgress) = 'O'
            toProgress.closeprogress()
         ENDIF
         IF VARTYPE(m.goapp.oLogger) = 'O'
            m.goapp.oLogger.EndProcess('DMROWNPL: BuildNet Finished')
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildNet', loError.LINENO, 'Lease Oper Stmt', loError.ERRORNO, loError.MESSAGE, '', loError
         IF VARTYPE(toProgress) = 'O'
            toProgress.closeprogress()
         ENDIF
      ENDTRY


   ENDPROC

****************************
   PROCEDURE BuildAggregate
****************************
      LPARAMETERS toProgress, ;
         tcOwner1, ;
         tcOwner2, ;
         tcWellID1, ;
         tcWellID2, ;
         tcYear, ;
         llTaxCode, ;
         llExpCat, ;
         llTotal, ;
         llSuspense, ;
         llProdYear, ;
         llAcctYear, ;
         llPageBreak, ;
         llTaxRevSect

      TRY

         IF VARTYPE(toProgress) = 'O'
            llProgress = .T.
         ELSE
            llProgress = .F.
         ENDIF

         llReturn = .T.

         IF llProdYear
            lcWhere   = 'wellhist.hyear = tcyear'
            lcWhereD  = 'hyear = tcyear'
            lcGroupBy = 'wellhist.cwellid, wellhist.hperiod'
            lcPeriod  = 'hPeriod as cperiod'
         ELSE
            lcWhere   = "wellhist.crunyear+PADL(TRANSFORM(wellhist.nrunno),3,'0') in (select crunyear+PADL(TRANSFORM(nrunno),3,'0') from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcWhereD  = "crunyear+PADL(TRANSFORM(nrunno),3,'0') in (select crunyear+PADL(TRANSFORM(nrunno),3,'0') from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcGroupBy = 'wellhist.cwellid, cperiod'
            lcPeriod  = "padl(TRANSFORM(MONTH(hdate)),2,'0') as cPeriod"
         ENDIF
         IF VARTYPE(m.goapp.oLogger) = 'O'
            m.goapp.oLogger.LogMilestone('DMROWNPL: Selecting owner history...')
         ENDIF
         SELECT  disbhist.cownerid, ;
                 disbhist.cWellid, ;
                 disbhist.ctypeinv, ;
                 MAX(ownpcts.nrevoil) AS nrevoil, ;
                 MAX(ownpcts.nRevGas) AS nRevGas, ;
                 MAX(ownpcts.nWorkInt) AS nWorkInt ;
             FROM disbhist ;
             JOIN ownpcts ;
                 ON disbhist.ciddisb == ownpcts.ciddisb ;
             WHERE &lcWhereD ;
                 AND disbhist.cownerid IN (SELECT  cid ;
                                               FROM SELECTED) ;
             INTO CURSOR wellinvtemp  READWRITE ;
             GROUP BY disbhist.cownerid ;
             ORDER BY disbhist.cownerid

         IF VARTYPE(m.goapp.oLogger) = 'O'
            m.goapp.oLogger.LogMilestone('DMROWNPL: Selecting suspense history...')
         ENDIF

         SELECT  suspense.cownerid, ;
                 suspense.cWellid, ;
                 suspense.ctypeinv, ;
                 MAX(suspense.nrevoil) AS nrevoil, ;
                 MAX(suspense.nRevGas) AS nRevGas, ;
                 MAX(suspense.nWorkInt) AS nWorkInt ;
             FROM suspense ;
             WHERE &lcWhereD ;
                 AND suspense.cownerid IN (SELECT  cid ;
                                               FROM SELECTED) ;
             INTO CURSOR wellinvtemp1 ;
             GROUP BY suspense.cownerid ;
             ORDER BY suspense.cownerid

         SELECT wellinvtemp1
         SCAN
            SCATTER MEMVAR
            SELECT wellinvtemp
            LOCATE FOR cownerid == m.cownerid
            IF NOT FOUND()
               INSERT INTO wellinvtemp FROM MEMVAR
            ENDIF
         ENDSCAN

         IF VARTYPE(m.goapp.oLogger) = 'O'
            m.goapp.oLogger.LogMilestone('DMROWNPL: Selecting owner history by well...')
         ENDIF

         SELECT  disbhist.cownerid, ;
                 disbhist.cWellid, ;
                 disbhist.ctypeinv, ;
                 MAX(ownpcts.nrevoil) AS nrevoil, ;
                 MAX(ownpcts.nRevGas) AS nRevGas, ;
                 MAX(ownpcts.nWorkInt) AS nWorkInt ;
             FROM disbhist ;
             JOIN ownpcts ;
                 ON disbhist.ciddisb == ownpcts.ciddisb ;
             WHERE &lcWhereD ;
                 AND disbhist.cownerid IN (SELECT  cid ;
                                               FROM SELECTED) ;
             INTO CURSOR wellown  READWRITE ;
             GROUP BY disbhist.cownerid, cWellid ;
             ORDER BY disbhist.cownerid, cWellid

         IF VARTYPE(m.goapp.oLogger) = 'O'
            m.goapp.oLogger.LogMilestone('DMROWNPL: Selecting suspense history by well...')
         ENDIF

         SELECT  suspense.cownerid, ;
                 suspense.cWellid, ;
                 suspense.ctypeinv, ;
                 MAX(suspense.nrevoil) AS nrevoil, ;
                 MAX(suspense.nRevGas) AS nRevGas, ;
                 MAX(suspense.nWorkInt) AS nWorkInt ;
             FROM suspense ;
             WHERE &lcWhereD ;
                 AND suspense.cownerid IN (SELECT  cid ;
                                               FROM SELECTED) ;
             INTO CURSOR wellown1 ;
             GROUP BY suspense.cownerid, cWellid ;
             ORDER BY suspense.cownerid, cWellid

         SELECT wellown1
         SCAN
            SCATTER MEMVAR
            SELECT wellinvtemp
            LOCATE FOR cownerid == m.cownerid AND cWellid == m.cWellid
            IF NOT FOUND()
               INSERT INTO wellown FROM MEMVAR
            ENDIF
         ENDSCAN

         CREATE CURSOR temppl ;
            (cGroup     C(1), ;
              cPageBreak C(22), ;
              cSection   C(1),  ;
              cownerid  C(10), ;
              cOwnName   C(30), ;
              ctypeinv   C(1), ;
              lTotal     L,  ;
              cSource    C(4),  ;
              cSrcID     C(25), ;
              cDesc      C(30), ;
              nRevPct    N(11, 7), ;
              nWrkPct    N(11, 7), ;
              nPrdAmt1   N(12, 2), ;
              nPrdAmt2   N(12, 2), ;
              nPrdAmt3   N(12, 2), ;
              nPrdAmt4   N(12, 2), ;
              nPrdAmt5   N(12, 2), ;
              nPrdAmt6   N(12, 2), ;
              nPrdAmt7   N(12, 2), ;
              nPrdAmt8   N(12, 2), ;
              nPrdAmt9   N(12, 2), ;
              nPrdAmt10  N(12, 2), ;
              nPrdAmt11  N(12, 2), ;
              nPrdAmt12  N(12, 2), ;
              nRevPct1   N(11, 7), ;
              nRevPct2   N(11, 7), ;
              nRevPct3   N(11, 7), ;
              nRevPct4   N(11, 7), ;
              nRevPct5   N(11, 7), ;
              nRevpct6   N(11, 7), ;
              nRevPct7   N(11, 7), ;
              nRevpct8   N(11, 7), ;
              nRevPct9   N(11, 7), ;
              nRevPct10  N(11, 7), ;
              nRevPct11  N(11, 7), ;
              nRevPct12  N(11, 7), ;
              nPrdAmtN   N(12, 2))
         INDEX ON cownerid + cGroup + cSection + cSource TAG wellsrc
         INDEX ON cSection TAG SECTION
         INDEX ON cSource  TAG SOURCE

         IF llProdYear
            lcWhere    = 'disbhist.hyear = tcyear'
            lcWhereS   = 'suspense.hyear = tcyear'
            lcWhereD   = 'disbhist.hyear = tcyear'
            lcGroupBy  = 'disbhist.cownerid, disbhist.hperiod'
            lcGroupByS = 'suspense.cownerid, suspense.hperiod'
            lcPeriod   = 'hperiod   AS cPeriod'
            lcWellName = 'cwellname'
         ELSE
            lcWhere    = "disbhist.crunyear+PADL(TRANSFORM(disbhist.nrunno),3,'0')+disbhist.crectype in (select crunyear+PADL(TRANSFORM(nrunno),3,'0')+ctypeclose from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcWhereS   = "suspense.crunyear_IN+PADL(TRANSFORM(suspense.nrunno_IN),3,'0')+'R' in (select crunyear+PADL(TRANSFORM(nrunno),3,'0')+ctypeclose from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcWhereD   = "disbhist.crunyear+PADL(TRANSFORM(disbhist.nrunno),3,'0')+disbhist.crectype in (select crunyear+PADL(TRANSFORM(nrunno),3,'0')+ctypeclose from sysctl where YEAR(dacctdate) = VAL(tcyear))"
            lcGroupBy  = 'disbhist.cownerid, disbhist.ctypeinv, 5'
            lcGroupByS = 'suspense.cownerid, suspense.ctypeinv, 5'
            lcPeriod   = "padl(TRANSFORM(MONTH(hdate)),2,'0') as cperiod"
            lcWellName = "'Aggregated Wells' AS cWellname"
         ENDIF

         lnMax              = 22
         IF llProgress
            toProgress.SetProgressRange(0, lnMax)
         ENDIF
         lnCount = 1

         SELECT wellinvtemp
         SCAN
            STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
               m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12, m.nPrdAmtN
            STORE 0 TO m.nRevPct1, m.nRevPct2, m.nRevPct3, m.nRevPct4, m.nRevPct5, m.nRevpct6, ;
               m.nRevPct7, m.nRevpct8, m.nRevPct9, m.nRevPct10, m.nRevPct11, m.nRevPct12
            STORE '' TO m.cDesc, m.cSrcID, m.cSource, m.cOwnName, m.cownerid, m.cWellid, m.cWellname, m.cleaseid, ;
               m.cSection, m.cGroup

            m.cWellid  = cWellid
            m.nWrkPct  = nWorkInt
            m.ctypeinv = ctypeinv
            m.nRevPct  = IIF(nrevoil # 0, nrevoil, nRevGas)
            m.cownerid = cownerid

            toProgress.UpdateProgress(lnCount)
            lnCount = lnCount + 1

            swselect('investor')
            SET ORDER TO cownerid
            IF SEEK(m.cownerid)
               m.cOwnName = cOwnName
            ELSE
               m.cOwnName = 'Unknown'
            ENDIF

********************************************************************
*  Fill in the owner amounts paid this year.
********************************************************************
*
            toProgress.SetProgressMessage('Calculating Oil Revenue...')
            toProgress.UpdateProgress(lnCount)
            lnCount = lnCount + 1

            llReturn = THIS.SelectAggregate(tcYear, lcPeriod, ;
                 lcWhere, ;
                 m.cWellid, ;
                 m.cownerid, ;
                 m.ctypeinv, ;
                 lcGroupBy, ;
                 llSuspense, ;
                 lcWhereS, ;
                 lcGroupByS, .T.)

            IF NOT llReturn
               EXIT
            ENDIF

            SELECT temppl
            SCAN FOR cownerid == m.cownerid
               SCATTER MEMVAR

               DO CASE
                  CASE m.cSource = 'MC1'
                     REPLACE cDesc WITH 'Gas Sales Volume'
                  CASE m.cSource = 'MC2'
                     REPLACE cDesc WITH 'Gas Sales'
                  CASE m.cSource = 'MC3'
                     REPLACE cDesc WITH 'MKTG Expense'
                  CASE m.cSource = 'BB1'
                     REPLACE cDesc WITH 'Oil Sales Volume'
                  CASE m.cSource = 'BB2'
                     REPLACE cDesc WITH 'Oil Sales'
                  CASE m.cSource = 'TRP'
                     REPLACE cDesc WITH 'Transportation Income'
                  CASE m.cSource = 'OTH'
                     REPLACE cDesc WITH 'Other Income'
                  CASE m.cSource = 'MI1'
                     REPLACE cDesc WITH 'Miscellaneous Income'
                  CASE m.cSource = 'TX1'
                     REPLACE cDesc WITH 'Oil Taxes'
                  CASE m.cSource = 'TX2'
                     REPLACE cDesc WITH 'Gas Taxes'
                  CASE m.cSource = 'TX3'
                     REPLACE cDesc WITH 'Other Taxes'
                  CASE m.cSource = 'EX0'
                     REPLACE cDesc WITH 'Operating Expenses'
                  CASE m.cSource = 'EX1'
                     REPLACE cDesc WITH 'Class 1 Expenses'
                  CASE m.cSource = 'EX2'
                     REPLACE cDesc WITH 'Class 2 Expenses'
                  CASE m.cSource = 'EX3'
                     REPLACE cDesc WITH 'Class 3 Expenses'
                  CASE m.cSource = 'EX4'
                     REPLACE cDesc WITH 'Class 4 Expenses'
                  CASE m.cSource = 'EX5'
                     REPLACE cDesc WITH 'Class 5 Expenses'
                  CASE m.cSource = 'EX6'
                     REPLACE cDesc WITH 'BCP Expenses'
                  CASE m.cSource = 'EX7'
                     REPLACE cDesc WITH 'ACP Expenses'
                  CASE m.cSource = 'MC4'
                     REPLACE cDesc WITH 'Compression/Gathering'
               ENDCASE
            ENDSCAN


            SELECT temppl
            SCAN FOR cownerid == m.cownerid
               SCATTER MEMVAR

               toProgress.SetProgressMessage('Calculating Oil & Gas Units...')
               toProgress.UpdateProgress(lnCount)
               lnCount = lnCount + 1
               IF .F.
                  SELECT wellown
                  SCAN FOR cownerid == m.cownerid
                     m.cWellid = cWellid
                     IF m.cGroup = '2' AND m.cSource = 'BB1'
                        IF llProdYear
                           swselect('wellhist')
                           SET ORDER TO wellprd
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '01'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit1 WITH nPrdUnit1 + (m.ntotbbl * (m.nRevPct1 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '02'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit2 WITH nPrdUnit2 + (m.ntotbbl * (m.nRevPct2 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '03'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit3 WITH nPrdUnit3 + (m.ntotbbl * (m.nRevPct3 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '04'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit4 WITH nPrdUnit4 + (m.ntotbbl * (m.nRevPct4 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '05'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit5 WITH nPrdUnit5 + (m.ntotbbl * (m.nRevPct5 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '06'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit6 WITH nPrdUnit6 + (m.ntotbbl * (m.nRevpct6 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '07'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit7 WITH nPrdUnit7 + (m.ntotbbl * (m.nRevPct7 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '08'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit8 WITH nPrdUnit8 + (m.ntotbbl * (m.nRevpct8 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '09'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit9 WITH nPrdUnit9 + (m.ntotbbl * (m.nRevPct9 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '10'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit10 WITH nPrdUnit10 + (m.ntotbbl * (m.nRevPct10 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '11'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit11 WITH nPrdUnit11 + (m.ntotbbl * (m.nRevPct11 / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '12'
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit12 WITH nPrdUnit12 + (m.ntotbbl * (m.nRevPct12 / 100))
                           ENDSCAN
                        ELSE
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 1
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit1 WITH nPrdUnit1 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 2
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit2 WITH nPrdUnit2 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 3
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit3 WITH nPrdUnit3 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 4
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit4 WITH nPrdUnit4 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 5
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit5 WITH nPrdUnit5 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 6
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit6 WITH nPrdUnit6 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 7
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit7 WITH nPrdUnit7 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 8
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit8 WITH nPrdUnit8 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 9
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit9 WITH nPrdUnit9 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 10
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit10 WITH nPrdUnit10 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 11
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit11 WITH nPrdUnit11 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 12
                              m.ntotbbl = ntotbbl
                              SELECT temppl
                              REPLACE nPrdUnit12 WITH nPrdUnit12 + (m.ntotbbl * (m.nRevPct / 100))
                           ENDSCAN
                        ENDIF
                     ENDIF

                     IF m.cGroup = '2' AND m.cSource = 'MC1'
                        IF llProdYear
                           swselect('wellhist')
                           SET ORDER TO wellprd
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '01'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit1 WITH nPrdUnit1 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '02'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit2 WITH nPrdUnit2 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '03'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit3 WITH nPrdUnit3 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '04'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit4 WITH nPrdUnit4 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '05'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit5 WITH nPrdUnit5 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '06'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit6 WITH nPrdUnit6 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '07'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit7 WITH nPrdUnit7 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '08'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit8 WITH nPrdUnit8 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '09'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit9 WITH nPrdUnit9 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '10'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit10 WITH nPrdUnit10 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '11'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit11 WITH nPrdUnit11 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid + hyear + hperiod = m.cWellid + tcYear + '12'
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit12 WITH nPrdUnit12 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                        ELSE
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 1
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit1 WITH nPrdUnit1 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 2
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit2 WITH nPrdUnit2 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 3
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit3 WITH nPrdUnit3 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 4
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit4 WITH nPrdUnit4 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 5
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit5 WITH nPrdUnit5 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 6
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit6 WITH nPrdUnit6 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 7
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit7 WITH nPrdUnit7 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 8
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit8 WITH nPrdUnit8 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 9
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit9 WITH nPrdUnit9 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 10
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit10 WITH nPrdUnit10 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 11
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit11 WITH nPrdUnit11 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                           swselect('wellhist')
                           SCAN FOR cWellid == m.cWellid AND YEAR(hdate) = VAL(tcYear) AND MONTH(hdate) = 12
                              m.ntotmcf = ntotmcf
                              SELECT temppl
                              REPLACE nPrdUnit12 WITH nPrdUnit12 + (m.ntotmcf * (m.nRevPct / 100))
                           ENDSCAN
                        ENDIF
                     ENDIF
                  ENDSCAN
               ENDIF

               SELECT temppl
               m.nPrdAmtN = (nPrdAmt1 + nPrdAmt2 + nPrdAmt3 + nPrdAmt4 + nPrdAmt5 + nPrdAmt6 + ;
                    nPrdAmt7 + nPrdAmt8 + nPrdAmt9 + nPrdAmt10 + nPrdAmt11 + nPrdAmt12) / 12
*
*  Remove expense classes 1-5 if they're zero
*
               toProgress.SetProgressMessage('Removing Zero Expenses...')
               toProgress.UpdateProgress(lnCount)
               IF INLIST(m.cSource, 'EX1', 'EX2', 'EX3', 'EX4', 'EX5', 'EX6', 'EX7', 'MC3')
                  IF m.nPrdAmtN = 0
                     DELETE
                     LOOP
                  ENDIF
               ENDIF
               SELECT temppl
               REPLACE nPrdAmtN  WITH m.nPrdAmtN

            ENDSCAN
         ENDSCAN

         IF VARTYPE(toProgress) = 'O'
            toProgress.closeprogress()
         ENDIF
         IF VARTYPE(m.goapp.oLogger) = 'O'
            m.goapp.oLogger.EndProcess('DMROWNPL: Building Aggregate Ending...')
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildAggregate', loError.LINENO, 'Lease Oper Stmt', loError.ERRORNO, loError.MESSAGE, '', loError
         IF VARTYPE(toProgress) = 'O'
            toProgress.closeprogress()
         ENDIF
      ENDTRY

      IF VARTYPE(toProgress) = 'O'
         toProgress.closeprogress()
      ENDIF
      RETURN llReturn
   ENDPROC

*************************
   PROCEDURE SelectGrossDataAmt
*************************
      LPARAMETERS tcYear, ;
         tcPeriod, ;
         tcOwnerID, ;
         tcTypeInv, ;
         tcWellID, ;
         tcWhere, ;
         tcGroupBy, ;
         tlTaxCode, ;
         tlExpCat, ;
         tlAggregate, ;
         tlTaxRevSect


      STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
         m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12
      STORE 0 TO m.nPrdUnit1, m.nPrdUnit2, m.nPrdUnit3, m.nPrdUnit4, m.nPrdUnit5, m.nPrdUnit6, ;
         m.nPrdUnit7, m.nPrdUnit8, m.nPrdUnit9, m.nPrdUnit10, m.nPrdUnit11, m.nPrdUnit12

      IF NOT tlAggregate
         SELECT  wellhist.cWellid AS cWellid, ;
                 wells.cWellname AS cWellname, ;
                 &tcPeriod, ;
                 wells.cleaseid AS cleaseid, ;
                 SUM(wellhist.ngrossoil) AS ngrossoil, ;
                 SUM(wellhist.ntotbbl) AS ntotbbl, ;
                 SUM(wellhist.ngrossgas) AS ngrossgas, ;
                 SUM(wellhist.ntotmcf) AS ntotmcf, ;
                 SUM(wellhist.ncompress + wellhist.ngather) AS ncompress, ;
                 SUM(wellhist.nTotMktg * -1) AS nTotMktg, ;
                 SUM(wellhist.nTRPInc) AS nTRPInc, ;
                 SUM(wellhist.nmiscinc1 + wellhist.nmiscinc2) AS nmiscinc, ;
                 SUM(wellhist.nothinc) AS nothinc, ;
                 SUM(wellhist.ntotprod) AS ntotprod, ;
                 SUM(wellhist.ngbbltax1 + ngbbltax2 + ngbbltax3 + ngbbltax4) AS noiltax, ;
                 SUM(wellhist.ngmcftax1 + ngmcftax2 + ngmcftax3 + ngmcftax4) AS ngastax, ;
                 SUM(wellhist.ntotothtx1 + ntotothtx2 + ntotothtx3 + ntotothtx4) AS nothtax, ;
                 SUM(wellhist.ntotale) AS ntotale, ;
                 SUM(wellhist.nexpcl1) AS nexpcl1, ;
                 SUM(wellhist.nexpcl2) AS nexpcl2, ;
                 SUM(wellhist.nexpcl3) AS nexpcl3, ;
                 SUM(wellhist.nexpcl4) AS nexpcl4, ;
                 SUM(wellhist.nexpcl5) AS nexpcl5, ;
                 SUM(wellhist.nexpclA) AS nexpclA, ;
                 SUM(wellhist.nexpclB) AS nexpclB ;
             FROM wellhist, wells ;
             WHERE wellhist.cWellid = tcWellID ;
                 AND wellhist.cWellid = wells.cWellid ;
                 AND &tcWhere ;
             ORDER BY &tcGroupBy ;
             GROUP BY &tcGroupBy ;
             INTO CURSOR temp
      ELSE
         SELECT  wellhist.cWellid AS cWellid, ;
                 wells.cWellname AS cWellname, ;
                 &tcPeriod, ;
                 wells.cleaseid AS cleaseid, ;
                 SUM(wellhist.ngrossoil) AS ngrossoil, ;
                 SUM(wellhist.ntotbbl) AS ntotbbl, ;
                 SUM(wellhist.ngrossgas) AS ngrossgas, ;
                 SUM(wellhist.ntotmcf) AS ntotmcf, ;
                 SUM(wellhist.ncompress + wellhist.ngather) AS ncompress, ;
                 SUM(wellhist.nTotMktg * -1) AS nTotMktg, ;
                 SUM(wellhist.nTRPInc) AS nTRPInc, ;
                 SUM(wellhist.nmiscinc1 + wellhist.nmiscinc2) AS nmiscinc, ;
                 SUM(wellhist.nothinc) AS nothinc, ;
                 SUM(wellhist.ntotprod) AS ntotprod, ;
                 SUM(wellhist.ngbbltax1 + ngbbltax2 + ngbbltax3 + ngbbltax4) AS noiltax, ;
                 SUM(wellhist.ngmcftax1 + ngmcftax2 + ngmcftax3 + ngmcftax4) AS ngastax, ;
                 SUM(wellhist.ntotothtx1 + ntotothtx2 + ntotothtx3 + ntotothtx4) AS nothtax, ;
                 SUM(wellhist.ntotale) AS ntotale, ;
                 SUM(wellhist.nexpcl1) AS nexpcl1, ;
                 SUM(wellhist.nexpcl2) AS nexpcl2, ;
                 SUM(wellhist.nexpcl3) AS nexpcl3, ;
                 SUM(wellhist.nexpcl4) AS nexpcl4, ;
                 SUM(wellhist.nexpcl5) AS nexpcl5, ;
                 SUM(wellhist.nexpclA) AS nexpclA, ;
                 SUM(wellhist.nexpclB) AS nexpclB ;
             FROM wellhist, wells ;
             WHERE wellhist.cWellid = wells.cWellid ;
                 AND &tcWhere ;
             ORDER BY &tcGroupBy ;
             GROUP BY &tcGroupBy ;
             INTO CURSOR temp
      ENDIF



      IF _TALLY > 0
         SELECT temp
         SCAN
            SCATTER MEMVAR
            THIS.LoadPrdAmt(  m.cperiod, m.ntotbbl,    'BB1', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.ntotbbl,    'BB1', '2', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.ngrossoil,  'BB2', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.ntotmcf,    'MC1', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.ntotmcf,    'MC1', '2', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.ntotprod,   'OT1', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.ntotprod,   'OT1', '2', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.ngrossgas,  'MC2', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.ncompress,  'MC4', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.nTotMktg,   'MC3', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.nTRPInc,    'TRP', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.nmiscinc,   'MI1', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            THIS.LoadPrdAmt(  m.cperiod, m.nothinc,    'OTH', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )

            IF tlTaxRevSect
               THIS.LoadPrdAmt(  m.cperiod, m.noiltax * -1,    'TX1', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.ngastax * -1,    'TX2', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.nothtax * -1,    'TX3', '1', 'A', tcOwnerID, tcWellID, tcTypeInv, )
            ELSE
               THIS.LoadPrdAmt(  m.cperiod, m.noiltax,    'TX1', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.ngastax,    'TX2', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.nothtax,    'TX3', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
            ENDIF

            IF NOT tlTaxCode AND NOT tlExpCat
               THIS.LoadPrdAmt(  m.cperiod, m.ntotale,    'EX0', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.nexpcl1,    'EX1', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.nexpcl2,    'EX2', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.nexpcl3,    'EX3', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.nexpcl4,    'EX4', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.nexpcl5,    'EX5', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.nexpclB,    'EX6', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
               THIS.LoadPrdAmt(  m.cperiod, m.nexpclA,    'EX7', '1', 'B', tcOwnerID, tcWellID, tcTypeInv, )
            ENDIF
         ENDSCAN
      ENDIF

      USE IN temp


**************************
   PROCEDURE SelectNetDataAmt
**************************
      LPARAMETERS tcYear, tcPeriod, ;
         tcWhere, ;
         tcWellName, ;
         tcWellID, ;
         tcOwnerID, ;
         tcTypeInv, ;
         tcGroupBy, ;
         tlSuspense, ;
         tcWhereS, ;
         tcGroupByS, ;
         tlAggregate, ;
         tlTaxCode, ;
         tlExpCat, ;
         tlTaxRevSect

      LOCAL lnRecords

      STORE 0 TO m.nPrdAmt1, m.nPrdAmt2, m.nPrdAmt3, m.nPrdAmt4, m.nPrdAmt5, m.nPrdAmt6, ;
         m.nPrdAmt7, m.nPrdAmt8, m.nPrdAmt9, m.nPrdAmt10, m.nPrdAmt11, m.nPrdAmt12, m.nPrdAmtN
      STORE 0 TO m.nRevPct1, m.nRevPct2, m.nRevPct3, m.nRevPct4, m.nRevPct5, m.nRevpct6, ;
         m.nRevPct7, m.nRevpct8, m.nRevPct9, m.nRevPct10, m.nRevPct11, m.nRevPct12, lnRecords
      STORE '' TO m.cDesc, m.cSrcID, m.cSource, m.cOwnName, m.cWellname, m.cleaseid, ;
         m.cSection, m.cGroup

      SELECT  disbhist.cWellid AS cWellid,  ;
              disbhist.cownerid AS cownerid, ;
              disbhist.ctypeinv AS ctypeinv, ;
              &tcWellName, ;
              &tcPeriod, ;
              investor.cOwnName AS cOwnName, ;
              SUM(noilrev) AS noilrev, ;
              SUM(ngasrev) AS ngasrev, ;
              SUM(nothrev) AS nothrev, ;
              SUM(ntrprev) AS ntrprev, ;
              000000000.00 AS ntotbbl, ;
              000000000.00 AS ntotmcf, ;
              000000000.00 AS ntotprod, ;
              SUM(nmiscrev1 + nmiscrev2) AS nMiscRev, ;
              SUM(nmktgexp * -1) AS nmktgexp, ;
              SUM(disbhist.ncompress + disbhist.ngather) AS ncompress, ;
              SUM(noiltax1 + noiltax2 + noiltax3 + noiltax4) AS noiltax, ;
              SUM(ngastax1 + ngastax2 + ngastax3 + ngastax4) AS ngastax, ;
              SUM(nothtax1 + nothtax2 + nothtax3 + nothtax4) AS nothtax, ;
              SUM(nexpense) AS nexpense, ;
              SUM(ntotale1) AS ntotale1, ;
              SUM(ntotale1) AS ntotale2, ;
              SUM(ntotale1) AS ntotale3, ;
              SUM(ntotale1) AS ntotale4, ;
              SUM(ntotale1) AS ntotale5, ;
              SUM(ntotale1) AS ntotalea, ;
              SUM(ntotale1) AS ntotaleb ;
          FROM disbhist, investor, wells  ;
          WHERE IIF(NOT tlAggregate, disbhist.cWellid   = tcWellID, .T.) ;
              AND disbhist.cownerid = tcOwnerID ;
              AND disbhist.cownerid = investor.cownerid ;
              AND disbhist.ctypeinv = tcTypeInv ;
              AND IIF(NOT tlAggregate, wells.cWellid = tcWellID, .T.) ;
              AND &tcWhere  ;
              AND (NOT lManual ;
                OR (lManual ;
                  AND (disbhist.nrunno_in = 0  ;
                    OR disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') ;
                    NOT IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
                                FROM sysctl ;
                                WHERE EMPTY(cversion) ;
                                    AND ctypeclose = 'R')))) ;
          ORDER BY &tcGroupBy ;
          GROUP BY &tcGroupBy ;
          INTO CURSOR temp READWRITE

      lnRecords = _TALLY

      IF tlSuspense  &&  If including money still in suspense
         SELECT  suspense.cWellid AS cWellid,  ;
                 suspense.cownerid AS cownerid, ;
                 IIF(NOT tlAggregate, wells.cWellname, 'Aggregated Wells') AS cWellname, ;
                 ctypeinv, ;
                 &tcPeriod, ;
                 investor.cOwnName AS cOwnName, ;
                 SUM(noilrev) AS noilrev, ;
                 SUM(ngasrev) AS ngasrev, ;
                 SUM(nothrev) AS nothrev, ;
                 SUM(ntrprev) AS ntrprev, ;
                 000000000.00 AS ntotbbl, ;
                 000000000.00 AS ntotmcf, ;
                 000000000.00 AS ntotprod, ;
                 SUM(nmiscrev1 + nmiscrev2) AS nMiscRev, ;
                 SUM(nmktgexp) * -1 AS nmktgexp, ;
                 SUM(suspense.ncompress + suspense.ngather) AS ncompress, ;
                 SUM(noiltax1 + noiltax2 + noiltax3 + noiltax4) AS noiltax, ;
                 SUM(ngastax1 + ngastax2 + ngastax3 + ngastax4) AS ngastax, ;
                 SUM(nothtax1 + nothtax2 + nothtax3 + nothtax4) AS nothtax, ;
                 SUM(nexpense) AS nexpense, ;
                 SUM(ntotale1) AS ntotale1, ;
                 SUM(ntotale1) AS ntotale2, ;
                 SUM(ntotale1) AS ntotale3, ;
                 SUM(ntotale1) AS ntotale4, ;
                 SUM(ntotale1) AS ntotale5, ;
                 SUM(ntotale1) AS ntotalea, ;
                 SUM(ntotale1) AS ntotaleb ;
             FROM suspense, investor, wells ;
             WHERE suspense.cownerid = tcOwnerID ;
                 AND suspense.ctypeinv = tcTypeInv ;
                 AND IIF(NOT tlAggregate, suspense.cWellid = tcWellID, .T.) ;
                 AND suspense.cownerid = investor.cownerid ;
                 AND IIF(NOT tlAggregate, wells.cWellid = tcWellID, .T.) ;
                 AND &tcWhereS  ;
                 AND (NOT lManual ;
                   OR (lManual ;
                     AND (suspense.nrunno_in = 0  ;
                       OR suspense.crunyear_in + PADL(TRANSFORM(suspense.nrunno_in), 3, '0') ;
                       NOT IN (SELECT  crunyear + PADL(TRANSFORM(nrunno), 3, '0') ;
                                   FROM sysctl ;
                                   WHERE EMPTY(cversion) ;
                                       AND ctypeclose = 'R')))) ;
             ORDER BY &tcGroupByS ;
             GROUP BY &tcGroupByS ;
             INTO CURSOR temp1

         IF _TALLY > 0
            SELECT temp
            APPEND FROM DBF('temp1')
            lnRecords = lnRecords + _TALLY
         ENDIF
      ENDIF

      IF lnRecords > 0
         SELECT temp
         SCAN
            SCATTER MEMVAR
            THIS.LoadPrdAmt(  m.cperiod, m.noilrev,   'BB2', '2', 'A', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            THIS.LoadPrdAmt(  m.cperiod, m.ngasrev,   'MC2', '2', 'A', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            THIS.LoadPrdAmt(  m.cperiod, m.ncompress, 'MC4', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            THIS.LoadPrdAmt(  m.cperiod, m.nothrev,   'OTH', '2', 'A', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            THIS.LoadPrdAmt(  m.cperiod, m.nMiscRev,  'MI1', '2', 'A', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            THIS.LoadPrdAmt(  m.cperiod, m.nmktgexp,  'MC3', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            THIS.LoadPrdAmt(  m.cperiod, m.ntrprev,   'TRP', '2', 'A', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            IF tlTaxRevSect
               THIS.LoadPrdAmt(  m.cperiod, m.noiltax * -1,   'TX1', '2', 'A', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.ngastax * -1,   'TX2', '2', 'A', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.nothtax * -1,   'TX3', '2', 'A', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            ELSE
               THIS.LoadPrdAmt(  m.cperiod, m.noiltax,   'TX1', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.ngastax,   'TX2', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.nothtax,   'TX3', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            ENDIF

            IF NOT tlTaxCode AND NOT tlExpCat
               THIS.LoadPrdAmt(  m.cperiod, m.nexpense,  'EX0', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.ntotale1,  'EX1', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.ntotale2,  'EX2', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.ntotale3,  'EX3', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.ntotale4,  'EX4', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.ntotale5,  'EX5', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.ntotalea,  'EX6', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
               THIS.LoadPrdAmt(  m.cperiod, m.ntotaleb,  'EX7', '2', 'B', m.cownerid, m.cWellid, m.ctypeinv, tlAggregate )
            ENDIF
         ENDSCAN
      ENDIF

      USE IN temp

   ENDPROC

**************************
   PROCEDURE SelectAggregate
**************************


      SELECT  cGroup, ;
              cPageBreak, ;
              cSection, ;
              'ALL' AS cWellid, ;
              cleaseid, ;
              'Aggregate of all wells' AS cWellname, ;
              cownerid, ;
              cownername, ;
              ctypeinv, ;
              lTotal, ;
              cSource, ;
              cSrcID, ;
              cDesc, ;
              nRevPct, ;
              nWrkPct, ;
              SUM(nPrdAmt1) AS nPrdAmt1, ;
              SUM(nPrdAmt2) AS nPrdAmt2, ;
              SUM(nPrdAmt3) AS nPrdAmt3, ;
              SUM(nPrdAmt4) AS nPrdAmt4, ;
              SUM(nPrdAmt5) AS nPrdAmt5, ;
              SUM(nPrdAmt6) AS nPrdAmt6, ;
              SUM(nPrdAmt7) AS nPrdAmt7, ;
              SUM(nPrdAmt8) AS nPrdAmt8, ;
              SUM(nPrdAmt9) AS nPrdAmt9, ;
              SUM(nPrdAmt10) AS nPrdAmt10, ;
              SUM(nPrdAmt11) AS nPrdAmt11, ;
              SUM(nPrdAmt12) AS nPrdAmt12, ;
              nRevPct1, ;
              nRevPct2, ;
              nRevPct3, ;
              nRevPct4, ;
              nRevPct5, ;
              nRevpct6, ;
              nRevPct7, ;
              nRevpct8, ;
              nRevPct9, ;
              nRevPct10, ;
              nRevPct11, ;
              nRevPct12, ;
              nrevpctn ;
          FROM temppl ;
          INTO CURSOR temppl ;
          ORDER BY cownerid, cGroup, cSection, cSource ;
          GROUP BY cownerid, cGroup, cSection, cSource

   ENDPROC


***********************************
   FUNCTION LoadPrdAmt(tcPeriod, tnAmount, tcSource, tcRptGroup, tcSection, tcOwnerID, tcWellID, tcTypeInv, tlAggregate)
***********************************

      m.cSource  = tcSource
      m.cGroup   = tcRptGroup
      m.cSection = tcSection
      m.cownerid = tcOwnerID
      m.cWellid  = tcWellID
      m.ctypeinv = tcTypeInv

      DO CASE
         CASE tcPeriod = '01'
            m.nPrdAmt1  = tnAmount
         CASE tcPeriod = '02'
            m.nPrdAmt2  = tnAmount
         CASE tcPeriod = '03'
            m.nPrdAmt3  = tnAmount
         CASE tcPeriod = '04'
            m.nPrdAmt4  = tnAmount
         CASE tcPeriod = '05'
            m.nPrdAmt5  = tnAmount
         CASE tcPeriod = '06'
            m.nPrdAmt6  = tnAmount
         CASE tcPeriod = '07'
            m.nPrdAmt7  = tnAmount
         CASE tcPeriod = '08'
            m.nPrdAmt8  = tnAmount
         CASE tcPeriod = '09'
            m.nPrdAmt9  = tnAmount
         CASE tcPeriod = '10'
            m.nPrdAmt10 = tnAmount
         CASE tcPeriod = '11'
            m.nPrdAmt11 = tnAmount
         CASE tcPeriod = '12'
            m.nPrdAmt12 = tnAmount
      ENDCASE

      SELECT temppl
      SET ORDER TO wellsrc

      IF tlAggregate
         lcKey = 'm.cownerid + m.cGroup + m.cSection + m.cSource'
      ELSE
         lcKey = 'm.cOwnerid + m.cWellid + m.ctypeinv + m.cGroup + m.cSection + m.cSource'
      ENDIF
      IF SEEK(&lcKey)
         DO CASE
            CASE tcPeriod = '01'
               REPLACE nPrdAmt1 WITH nPrdAmt1 + m.nPrdAmt1
            CASE tcPeriod = '02'
               REPLACE nPrdAmt2 WITH nPrdAmt2 + m.nPrdAmt2
            CASE tcPeriod = '03'
               REPLACE nPrdAmt3 WITH nPrdAmt3 + m.nPrdAmt3
            CASE tcPeriod = '04'
               REPLACE nPrdAmt4 WITH nPrdAmt4 + m.nPrdAmt4
            CASE tcPeriod = '05'
               REPLACE nPrdAmt5 WITH nPrdAmt5 + m.nPrdAmt5
            CASE tcPeriod = '06'
               REPLACE nPrdAmt6 WITH nPrdAmt6 + m.nPrdAmt6
            CASE tcPeriod = '07'
               REPLACE nPrdAmt7 WITH nPrdAmt7 + m.nPrdAmt7
            CASE tcPeriod = '08'
               REPLACE nPrdAmt8 WITH nPrdAmt8 + m.nPrdAmt8
            CASE tcPeriod = '09'
               REPLACE nPrdAmt9 WITH nPrdAmt9 + m.nPrdAmt9
            CASE tcPeriod = '10'
               REPLACE nPrdAmt10 WITH nPrdAmt10 + m.nPrdAmt10
            CASE tcPeriod = '11'
               REPLACE nPrdAmt11 WITH nPrdAmt11 + m.nPrdAmt11
            CASE tcPeriod = '12'
               REPLACE nPrdAmt12 WITH nPrdAmt12 + m.nPrdAmt12
         ENDCASE
      ELSE
         INSERT INTO temppl FROM MEMVAR
      ENDIF
   ENDFUNC

ENDDEFINE













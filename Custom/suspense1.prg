**************************************************
*-- Class:        suspense (c:\develop\codemine\custom\swsuspense.vcx)
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   11/15/05 05:41:03 PM
*
DEFINE CLASS suspense AS CUSTOM


    NAME = "suspense"

    dAcctDate         = {}
    lRelMin           = .F.
    nRunNo            = 0
    cRunYear          = " "
    cGroup            = ''
    oRegistry         = .NULL.
    oMessage          = .NULL.
    oProgress         = .NULL.
    nProgress         = 0
    lClosing          = .F.
    lDebug            = .F.
    cBegOwner         = ''
    cEndOwner         = ''
    cBegWell          = ''
    cEndWell          = ''
    lGetLastTypeAfter = .F.
    lGetLastTypeHold  = .F.
    lPerfLog          = .F.
    lNewRun           = .F.
    lNoPayFreqs       = .F. && No pay frequencies other than monthly
    lCheckedFreqs     = .F.
    lCanceled         = .F.
    lRelQtr           = .F.

    *************************
    PROCEDURE INIT
    *************************

    THIS.oRegistry = findglobalobject('cmRegistry')
    THIS.oMessage  = findglobalobject('cmMessage')

    * Setup for performance logging
    IF FILE('perflog.txt')
        THIS.lPerfLog = .T.
    ELSE
        THIS.lPerfLog = .F.
    ENDIF

    IF FILE('debug.dat')
        THIS.lDebug = .T.
    ENDIF

    ENDPROC

    *************************
    PROCEDURE DESTROY
    *************************

    swclose('curLastSuspType')
    swclose('temp1')
    swclose('temp2')
    swclose('temp0')

    *************************
    PROCEDURE perflog
    *************************
    LPARAMETERS tcDescription, tlEnd

    IF FILE('perflog.txt')
        IF NOT tlEnd
            m.goapp.oPerfLog.StartTask(tcDescription)
        ELSE
            m.goapp.oPerfLog.EndTask(tcDescription)
        ENDIF
    ENDIF

    *************************
    PROCEDURE open_files
    *************************
    LPARAMETERS tlNoInvTmp
    LOCAL llCallSWSelect

    llCallSWSelect = .F.

    * Try opening suspense. If we get an error
    * call swselect to open it so it can find it
    TRY
        IF NOT USED('suspense')
            USE suspense IN 0
        ENDIF
    CATCH
        llCallSWSelect = .T.
    ENDTRY

    IF llCallSWSelect
        swselect('suspense', .T.)
    ENDIF

    llCallSWSelect = .F.

    * Try opening suspense again as suspense1. If we get an error
    * call swselect to open it so it can find it.
    TRY
        IF NOT USED('suspense1')
            USE suspense IN 0 AGAIN ALIAS suspense1
        ENDIF
    CATCH
        llCallSWSelect = .T.
    ENDTRY

    IF llCallSWSelect
        swselect('suspense', .F., 'suspense1')
    ENDIF

    swselect('disbhist', .T.)

    swselect('disbhist', .F., 'disbhist1')

    swselect('investor')

    swselect('wells')

    IF NOT tlNoInvTmp
        IF NOT USED('invtmp')
            WAIT WINDOW 'The INVTMP file was not found....Bad problem!'
            RETURN
        ENDIF
    ENDIF

    swselect('options')

    SELE suspense
    SET ORDER TO ciddisb

    SELE disbhist
    SET ORDER TO ciddisb

    SELE investor
    SET ORDER TO cownerid

    SELE wells
    SET ORDER TO cwellid
    ENDPROC

    *******************************
    PROCEDURE Owner_suspense
    *******************************
    LPARAMETERS toProgress, tlTest

    LOCAL llReturn, loError
    *:Global cGroup
    llReturn = .T.

    TRY
        IF m.goapp.lCanceled
            llReturn          = .F.
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF
        
        m.goapp.oLogger.StartProcess('Suspense: Owner Suspense')

        * Use the closing process progress bar
        THIS.oProgress = toProgress

        THIS.open_files()

        THIS.perflog('Suspense: Owner Suspense')
        THIS.timekeeper('Starting owner_suspense')

        * Check for owner pay frequencies other than monthly
        llReturn = THIS.Owner_Pay_Freq()
        IF NOT llReturn
            EXIT
        ENDIF

        m.cGroup = THIS.cGroup
        * Put all "owner on holds" and "interest on holds" into suspense
        llReturn = THIS.owner_holds_in()
        IF NOT llReturn
            EXIT
        ENDIF

        * Bring out all minimum amounts into invtmp
        llReturn = THIS.process_minimums_out()
        IF NOT llReturn
            EXIT
        ENDIF

        * Remove owner frequencies that aren't due to pay
        llReturn = THIS.owner_freq_in()
        IF NOT llReturn
            EXIT
        ENDIF

        * Pull all owner freq payments out that are due to be paid
        llReturn = THIS.owner_freq_out()
        IF NOT llReturn
            EXIT
        ENDIF

        * Pull any "interests on hold" and "owner on hold" out of suspense
        llReturn = THIS.owner_holds_out()
        IF NOT llReturn
            EXIT
        ENDIF

        * Put any wells in deficit into suspense
        llReturn = THIS.owner_deficits_in()
        IF NOT llReturn
            EXIT
        ENDIF

        * Pull out of suspense any deficit wells that can be covered.
        llReturn = THIS.owner_deficits_out()
        IF NOT llReturn
            EXIT
        ENDIF

        * Process for programs
        THIS.program_suspense()

        * Check for being under minimum and put into suspense
        llReturn = THIS.process_minimums_in()
        IF NOT llReturn
            EXIT
        ENDIF

        * Check for payments zeroing out balances
        llReturn = THIS.check_for_payments()
        IF NOT llReturn
            EXIT
        ENDIF

        THIS.perflog('Suspense: Owner Suspense', .T.)
        THIS.timekeeper('Ending owner_suspense')
    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'Owner_Suspense', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()
    
    m.goapp.oLogger.EndProcess('Suspense: Owner Suspense')

    RETURN llReturn
    ENDPROC

    *******************************
    PROCEDURE well_suspense
    *******************************
    LPARAMETERS toProgress

    llReturn = .T.

    TRY
        * Use the closing process progress bar
        THIS.oProgress = toProgress

        THIS.perflog('Suspense: Well Suspense')
        THIS.timekeeper('Starting well_suspense')

        THIS.open_files()

        * Check for owner pay frequencies other than monthly
        llReturn = THIS.Owner_Pay_Freq()
        IF NOT llReturn
            EXIT
        ENDIF

        * Put all "owner on holds" and "interest on holds" into suspense
        llReturn = THIS.owner_holds_in()
        IF NOT llReturn
            EXIT
        ENDIF

        * Remove owner frequencies that aren't due to pay
        llReturn = THIS.owner_freq_in()
        IF NOT llReturn
            EXIT
        ENDIF

        * Bring out all minimum amounts into invtmp
        llReturn = THIS.process_minimums_out()
        IF NOT llReturn
            EXIT
        ENDIF

        * Pull any "interests on hold" and "owner on hold" out of suspense
        llReturn = THIS.owner_holds_out()
        IF NOT llReturn
            EXIT
        ENDIF

        * Pull all owner freq payments out that are due to be paid
        llReturn = THIS.owner_freq_out()
        IF NOT llReturn
            EXIT
        ENDIF

        * Put any wells in deficit into suspense
        llReturn = THIS.well_deficits_in()
        IF NOT llReturn
            EXIT
        ENDIF

        * Pull out of suspense any deficit wells that can be covered.
        llReturn = THIS.well_deficits_out()
        IF NOT llReturn
            EXIT
        ENDIF

        * Process for programs
        *   THIS.program_suspense()

        * Check for being under minimum and put into suspense
        llReturn = THIS.process_minimums_in()
        IF NOT llReturn
            EXIT
        ENDIF


        THIS.perflog('Suspense: Well Suspense', .T.)
        THIS.timekeeper('Ending well_suspense')
    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'Well_Suspense', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, '', loError
        MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    RETURN llReturn
    ENDPROC

    *******************************
    PROCEDURE program_suspense
    *******************************

    THIS.perflog('Suspense: Program Suspense')
    THIS.timekeeper('Starting program_suspense')

    THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Program Suspense')

    THIS.open_files()

    swselect('programs')
    LOCATE FOR lprognet = .F.
    IF FOUND()
        * Put any wells in deficit into suspense
        THIS.program_deficits_in()

        * Pull out of suspense any deficit wells that can be covered.
        THIS.program_deficits_out()
    ENDIF

    swclose('prog_susp_bal')
    swclose('prog_current_bal')

    THIS.perflog('Suspense: Program Suspense', .T.)
    THIS.timekeeper('Ending program_suspense')

    ENDPROC

    ********************************************
    PROTECTED PROCEDURE process_minimums_out
        ********************************************
        LOCAL lcSuspKey
        LOCAL llReturn, loError
        LOCAL cRunYear, cTypeInv, ciddisb, cownerid, crunyear_in, cwellid, hdate, nRunNo, nrunno_in

        llReturn = .T.
        m.goapp.Rushmore(.T., 'Process_Minimums_Out')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            
            m.goapp.oLogger.LogMileStone('Suspense: Process Minimums Out - Start')


            THIS.perflog('Suspense: Minimums Out')
            THIS.timekeeper('Starting Minimums Out')

            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Minimums Out')

            * Get the current suspense status for each owner and well.
            THIS.perflog('Minimums Out: GetLastType')
            THIS.getlasttype(.F., .F., THIS.cGroup, .T.)
            THIS.perflog('Minimums Out: GetLastType', .T.)

            swselect('suspense')
            SET ORDER TO ciddisb   && CIDDISB

            * Create a cursor to store the keys of deleted suspense records
            CREATE CURSOR delsusp (ciddisb c(8))

            * Process all suspense that is now minimum suspense
            * releasing it into invtmp
  * Commented out by pws 11/24/20 to try to optimize
            SELECT  * ;
                FROM CurLastSuspType ;
                INTO CURSOR tempcurlast ;
                WHERE cSuspType = 'M' ;
                    AND cownerid NOT IN (SELECT  cownerid ;
                                             FROM investor ;
                                             WHERE lhold) ;
                    AND cwellid + cownerid + cTypeInv NOT IN (SELECT  cwellid + cownerid + cTypeInv ;
                                                                  FROM wellinv ;
                                                                  WHERE lonhold) ;
                ORDER BY cownerid, cwellid, cTypeInv ;
                GROUP BY cownerid, cwellid, cTypeInv
*!*	                
*!*	                SELECT  * ;
*!*	                   FROM CurLastSuspType ;
*!*	                   INTO CURSOR tempcurlast ;
*!*	                   WHERE cSuspType = 'M' ;
*!*	                   ORDER BY cownerid, cwellid, cTypeInv ;
*!*	                   GROUP BY cownerid, cwellid, cTypeInv
                   
                                     
            * Get the records that match tempcurlast
            SELECT * FROM suspense ;
               WHERE cwellid+cownerid+ctypeinv IN ;
                 (SELECT cwellid+cownerid+ctypeinv FROM tempcurlast) ;
               INTO CURSOR tempsusp
            SELECT tempsusp
            SCAN
                SCATTER MEMVAR
                
*!*	                SELECT investor
*!*	                LOCATE FOR cownerid = m.cownerid ;
*!*	                       AND lhold = .t.
*!*	                IF FOUND()
*!*	                   LOOP
*!*	                ENDIF
                
*!*	                SELECT wellinv
*!*	                LOCATE FOR cownerid = m.cownerid ;
*!*	                       AND cwellid  = m.cwellid ;
*!*	                       AND ctypeinv = m.ctypeinv ;
*!*	                       AND lOnHold  = .T.
*!*	                IF FOUND()
*!*	                   LOOP
*!*	                ENDIF 

                THIS.perflog('Minimums Out - ' + m.cownerid)

                IF m.goapp.lCanceled
                    llReturn          = .F.
                    IF NOT m.goapp.CancelMsg()
                        THIS.lCanceled = .T.
                        EXIT
                    ENDIF
                ENDIF

                THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Minimums Out - ' + m.cownerid)

                    lcSuspKey = m.ciddisb
                    * Store the original run into run_in
                    IF m.nrunno_in = 0
                        m.nrunno_in   = m.nRunNo
                        m.crunyear_in = m.cRunYear
                    ENDIF
                    * Swap the original run with current run
                    m.nRunNo   = THIS.nRunNo
                    m.cRunYear = THIS.cRunYear
                    m.hdate    = THIS.dAcctDate
                    
* Not sure we need this next stmt since the closing creates new ciddisb fields when saving to disbhist - pws 11/24/20                    
                    m.ciddisb  = getnextpk('suspense')
                    IF EMPTY(m.cSuspType)
                        m.nrunno_in   = 0
                        m.crunyear_in = ''
                    ENDIF
                    INSERT INTO invtmp FROM MEMVAR
                    INSERT INTO delsusp VALUES(lcSuspKey)

                    * Get the well history record corresponding to the owner history
                    IF NOT this.lClosing  && Think we don't need wellwork recs when closing the run - pws 11/24/20
                       THIS.getwellhist(m.cwellid, m.hyear, m.hperiod)
                    ENDIF    
                THIS.perflog('Minimums Out - ' + m.cownerid, .T.)
            ENDSCAN.

            * Delete the suspense released
            IF RECCOUNT('delsusp') > 0
                THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Minimums Out - Remove Suspense')
                DELETE FROM suspense WHERE ciddisb IN (SELECT ciddisb FROM delsusp)
            ENDIF

            THIS.perflog('Suspense: Minimums Out', .T.)
            THIS.timekeeper('Ending Minimums Out')
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Process_Minimums_Out', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)
        m.goapp.oLogger.LogMileStone('Suspense: Process Minimums Out - End')

        RETURN llReturn
        ENDPROC

        *******************************************
    PROTECTED PROCEDURE process_minimums_in
        *******************************************
        LOCAL lnMinimum, lnGlobalMin
        LOCAL llReturn, lnbalance, loError
        *:Global cRunYear, ciddisb, cownerid, crunyear_in, csusptype, nRunNo, nrunno_in

        llReturn = .T.
        m.goapp.Rushmore(.T., 'Process_Minimums_In')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            
            m.goapp.oLogger.LogMileStone('Suspense: Process Minimums In - Start')


            THIS.perflog('Suspense: Minimums In')
            THIS.timekeeper('Starting minimum_suspense_in')

            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Minimums In')

            STORE 0 TO lnMinimum

            * Get the global minimum check amount
            swselect('options')
            GO TOP
            lnGlobalMin = nMinCheck

            SELECT invtmp
            SET ORDER TO cownerid

            * Get current run balances so we can check to see who's below the minimum
            THIS.owner_current_balance(, .T.)
            SELECT owncurbal
            SCAN FOR nBalance # 0
                m.cownerid = cownerid
                THIS.perflog('Minimums In - ' + m.cownerid)
                IF m.goapp.lCanceled
                    llReturn          = .F.
                    IF NOT m.goapp.CancelMsg()
                        THIS.lCanceled = .T.
                        EXIT
                    ENDIF
                ENDIF

                THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Minimums In - ' + m.cownerid)

                lnbalance = owncurbal.nBalance
                swselect('investor')
                IF SEEK(m.cownerid)
                    * Don't include owners marked to post
                    IF (lIntegGl AND (m.goapp.lAMVersion OR m.goapp.lQBVersion)) OR lDummy
                        LOOP
                    ENDIF
                    IF nInvMin # 0
                        lnMinimum = nInvMin
                    ELSE
                        lnMinimum = lnGlobalMin
                    ENDIF
                ENDIF

                * We're releasing all minimums on this closing
                IF THIS.lRelMin
                    lnMinimum = 0
                ENDIF

                IF lnbalance < lnMinimum
*!*	                    SELECT * FROM invtmp INTO CURSOR tempownhist WHERE cownerid = m.cownerid 
*!*	                    SELECT tempownhist
*!*	                    SCAN
                    SELECT invtmp

*                    SEEK(m.cownerid)   && COWNERID
                    SCAN FOR cownerid == m.cownerid
                        SCATTER MEMVAR

                        * Store the original run into run_in
                        IF m.nrunno_in = 0
                            m.nrunno_in   = THIS.nRunNo
                            m.crunyear_in = m.cRunYear
                            m.cSuspType   = 'M'
                        ENDIF
                        * Swap the original run with current run
                        m.nRunNo   = THIS.nRunNo
                        m.cRunYear = THIS.cRunYear
                        m.ciddisb  = GetNextPK('suspense')
                        IF m.nNetCheck # 0
                            INSERT INTO suspense FROM MEMVAR
                            IF m.nrunno_in = THIS.nRunNo AND m.crunyear_in = THIS.cRunYear
                                INSERT INTO tsuspense FROM MEMVAR
                            ENDIF
                            SELE invtmp
                            DELETE NEXT 1
                        ENDIF
                    ENDSCAN
                ENDIF
                THIS.perflog('Minimums In - ' + m.cownerid, .T.)
            ENDSCAN

            THIS.perflog('Suspense: Minimums In', .T.)
            THIS.timekeeper('Ending minimum_suspense_in')
            WAIT CLEAR
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Process_Minimums_In', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)
        m.goapp.oLogger.LogMileStone('Suspense: Process Minimums In - End')

        RETURN llReturn
        ENDPROC

        ***************************************
    PROTECTED PROCEDURE owner_holds_out
        ***************************************
        LOCAL lciddisb
        LOCAL lhold, lonhold, llReturn, loError
        *:Global cRunYear, cTypeInv, ciddisb, cownerid, crunyear_in, cwellid, hdate, nRunNo, nrunno_in

        llReturn = .T.
        m.goapp.Rushmore(.T., 'Owner_Holds_out')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            
            m.goapp.oLogger.LogMileStone('Suspense: Owner Holds Out - Start')


            THIS.perflog('Suspense: Holds Out')
            THIS.timekeeper('Starting Owner_holds_out')

            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Holds Out')

            * Get the current suspense status for each owner and well.
            THIS.perflog('Holds Out: GetLastType')
            THIS.getlasttype(.F., .T., THIS.cGroup)
            THIS.perflog('Holds Out: GetLastType', .T.)

            SELECT  cownerid, ;
                    cwellid, ;
                    cTypeInv, ;
                    cprogcode ;
                FROM CurLastSuspType ;
                WHERE cSuspType = 'I' ;
                    OR cSuspType = 'H' ;
                INTO CURSOR tempcurlast ;
                ORDER BY cownerid, cwellid, cTypeInv ;
                GROUP BY cownerid, cwellid, cTypeInv

            CREATE CURSOR delsusp (ciddisb c(8))

            SELECT tempcurlast
            SCAN
                m.cownerid = cownerid
                m.cwellid  = cwellid
                m.cTypeInv = cTypeInv

                IF m.goapp.lCanceled
                    llReturn          = .F.
                    IF NOT m.goapp.CancelMsg()
                        THIS.lCanceled = .T.
                        EXIT
                    ENDIF
                ENDIF

                IF NOT THIS.isonhold(m.cownerid) AND THIS.at_pay_freq(m.cownerid)
                    SELECT CurLastSuspType
                    SCAN FOR cownerid == m.cownerid AND cwellid  == m.cwellid AND cTypeInv == m.cTypeInv
                        m.cwellid   = cwellid
                        m.cownerid  = cownerid
                        m.cTypeInv  = cTypeInv
                        m.cprogcode = cprogcode
                        m.cGroup    = THIS.cGroup

                        THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Holds Out - ' + m.cownerid)

                        * Process only if the owner and interest is not held.
                        IF NOT THIS.isonhold(m.cownerid, .T., m.cwellid, m.cTypeInv)
                            SELECT  * ;
                                FROM suspense WITH (BUFFERING = .T.) ;
                                WHERE cwellid == m.cwellid ;
                                    AND cownerid == m.cownerid ;
                                    AND cTypeInv == m.cTypeInv ;
                                    AND cGroup == m.cGroup ;
                                INTO CURSOR temphold
                                lciddisb  = THIS.get_next_key('disbhist')
                            SELECT temphold
                            SCAN
                                SCATTER MEMVAR
                                m.ciddisb = lciddisb
                                lciddisb = PADL(TRANSFORM(VAL(lciddisb)+1),8,'0')
                                * Store the original run into run_in
                                IF m.nrunno_in = 0
                                    m.nrunno_in   = m.nRunNo
                                    m.crunyear_in = m.cRunYear
                                ENDIF
                                * Swap the original run with current run
                                m.nRunNo   = THIS.nRunNo
                                m.cRunYear = THIS.cRunYear
                                m.hdate    = THIS.dAcctDate
                                * Reset the on hold flag in the record
                                STORE .F. TO m.lonhold, m.lhold
                                
                                IF EMPTY(m.cSuspType)
                                    m.nrunno_in   = 0
                                    m.crunyear_in = ''
                                ENDIF
                                INSERT INTO invtmp FROM MEMVAR
                                INSERT INTO delsusp VALUES (temphold.ciddisb)
                                IF NOT this.lClosing
                                * Get the well history record corresponding to the owner history
                                   THIS.getwellhist(m.cwellid, m.hyear, m.hperiod)
                                ENDIF 
                            ENDSCAN && temphold
                        ENDIF && not isonhold
                    ENDSCAN && curlastsusptype
                ENDIF && isonhold
            ENDSCAN && tempcurlast

            IF RECCOUNT('delsusp') > 0
                DELETE FROM suspense WHERE ciddisb IN (SELECT ciddisb FROM delsusp)
            ENDIF

            WAIT CLEAR
            THIS.perflog('Suspense: Holds Out', .T.)
            THIS.timekeeper('Ending Owner_holds_out')
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Owner_Holds_Out', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)
 
        m.goapp.oLogger.LogMileStone('Suspense: Owner Holds Out - End')
        RETURN llReturn
        ENDPROC

        **************************************
    PROTECTED PROCEDURE owner_holds_in
        **************************************

        LOCAL llReturn, loError
        *:Global cRunYear, ciddisb, crunyear_in, csusptype, nRunNo, nrunno_in
        llReturn = .T.
        m.goapp.Rushmore(.T., 'Owner_Holds_In')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF
            
            m.goapp.oLogger.LogMileStone('Suspense: Owner Holds In - Start')

            THIS.perflog('Suspense: Holds In')
            THIS.timekeeper('Starting Owner_holds_in')
            m.goapp.oLogger.LogMileStone('Suspense: Owner Holds In - Start')

            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Holds In')

            *  Remove records from invtmp if the owner is on hold or the interest is on hold
            *  Place them in suspense
            SELECT invtmp
            SCAN FOR lonhold OR lhold AND BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner)
                SCATTER MEMVAR
                THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Holds In - ' + m.cownerid)

                IF m.goapp.lCanceled
                    llReturn          = .F.
                    IF NOT m.goapp.CancelMsg()
                        THIS.lCanceled = .T.
                        EXIT
                    ENDIF
                ENDIF

                * Plug the suspense record with the runno originally put into suspense
                IF m.nrunno_in = 0
                    m.nrunno_in   = THIS.nRunNo  &&  Bracketed b/c this.nrunno <> 0 for a new run (for some reason), which makes the recs from suspense not show on statements
                    m.crunyear_in = THIS.cRunYear
                    * Set the suspense type to be either Interest on Hold or Owner on Hold
                    DO CASE
                        CASE m.lonhold
                            m.cSuspType = 'I'
                        CASE m.lhold
                            m.cSuspType = 'H'
                    ENDCASE
                ELSE
                    m.nRunNo   = m.nrunno_in
                    m.cRunYear = m.crunyear_in
                ENDIF

                * Get the next primary key for suspense (matches owner history)
                m.ciddisb = THIS.get_next_key('disbhist')
                IF m.nNetCheck # 0
                    INSERT INTO suspense FROM MEMVAR
                    IF m.nrunno_in = THIS.nRunNo AND m.crunyear_in = THIS.cRunYear
                        INSERT INTO tsuspense FROM MEMVAR
                    ENDIF
                    SELE invtmp
                    DELETE NEXT 1
                ENDIF
            ENDSCAN && invtmp

            THIS.perflog('Suspense: Holds In', .T.)
            THIS.timekeeper('Ending Owner_holds_in')
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Owner_Holds_In', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)
        
        m.goapp.oLogger.LogMileStone('Suspense: Owner Holds In - End')

        RETURN llReturn

        ENDPROC

        *************************************
    PROTECTED PROCEDURE owner_freq_in
        *************************************
        *
        *  Remove records from invtmp if the owner isn't paid monthly and it's not time to pay them
        *  Place them in suspense
        *

        LOCAL llReturn, loError, llPayFreq1, llPayFreq2, llPayFreq3, llPayFreq4, llPay
        LOCAL ciddisb, crunyear_in, cSuspType, nrunno_in
        llReturn = .T.
        m.goapp.Rushmore(.T., 'Owner_Freq_In')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            * There are no owners set with a frequency other than monthly so bail
            IF THIS.lNoPayFreqs
                llReturn = .T.
                EXIT
            ENDIF

            THIS.perflog('Suspense: Freq In')
            THIS.timekeeper('Starting Owner_freq_in')
            m.goapp.oLogger.LogMileStone('Suspense: Owner Freq In - Start')

            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Frequency In')

            STORE .F. TO llPayFreq1, llPayFreq2, llPayFreq3, llPayFreq4, llPay
            llPayFreq1 = .T.
            IF INLIST(MONTH(THIS.dAcctDate), 3, 6, 9, 12)
                llPayFreq2 = .T.
            ENDIF
            IF INLIST(MONTH(THIS.dAcctDate), 6, 12)
                llPayFreq3 = .T.
            ENDIF
            IF INLIST(MONTH(THIS.dAcctDate), 12)
                llPayFreq4 = .T.
            ENDIF

            *  Set order for the seek in the scan loop below
            swselect('investor')
            SET ORDER TO cownerid

            * Check for owners that have a pay frequency other than monthly
            * so we can use them to scan through invtmp to check to see if
            * the invtmp should be put into suspense.
            IF m.goapp.lAMVersion OR m.goapp.lQBVersion
                SELECT  invtmp.cownerid, ;
                        investor.ndisbfreq ;
                    FROM invtmp, investor ;
                    WHERE NOT EMPTY(investor.ndisbfreq) ;
                        AND investor.ndisbfreq # 1 ;
                        AND invtmp.cownerid == investor.cownerid ;
                        AND (investor.lIntegGl = .F. ;
                          AND (m.goapp.lAMVersion ;
                            OR m.goapp.lQBVersion));
                        AND BETWEEN(invtmp.cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    INTO CURSOR tempfreqowner ;
                    ORDER BY invtmp.cownerid ;
                    GROUP BY invtmp.cownerid
            ELSE
                SELECT  invtmp.cownerid, ;
                        investor.ndisbfreq ;
                    FROM invtmp, investor ;
                    WHERE NOT EMPTY(investor.ndisbfreq) ;
                        AND investor.ndisbfreq # 1 ;
                        AND invtmp.cownerid == investor.cownerid ;
                        AND BETWEEN(invtmp.cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    INTO CURSOR tempfreqowner ;
                    ORDER BY invtmp.cownerid ;
                    GROUP BY invtmp.cownerid
            ENDIF

            SELECT tempfreqowner
            SCAN
                SCATTER MEMVAR

                * If we're at the the current pay frequency loop out
                * because we're not going to put this owner into freq suspense.
                DO CASE
                    CASE m.ndisbfreq = 2 AND llPayFreq2
                        LOOP
                    CASE m.ndisbfreq = 3 AND llPayFreq3
                        LOOP
                    CASE m.ndisbfreq = 4 AND llPayFreq4
                        LOOP
                ENDCASE

                SELECT invtmp
                SCAN FOR cownerid == m.cownerid
                    SCATTER MEMVAR

                    THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Frequency In - ' + m.cownerid)

                    IF m.goapp.lCanceled
                        llReturn          = .F.
                        IF NOT m.goapp.CancelMsg()
                            THIS.lCanceled = .T.
                            EXIT
                        ENDIF
                    ENDIF

                    * If the runno_in = 0 that means that this record was created from
                    * income and expenses this run.  We only set csusptype for new
                    * suspense. Suspense should keep its original csusptype intact.
                    IF m.nrunno_in = 0
                        DO CASE
                            CASE m.ndisbfreq = 2
                                m.cSuspType = 'Q'
                            CASE m.ndisbfreq = 3
                                m.cSuspType = 'S'
                            CASE m.ndisbfreq = 4
                                m.cSuspType = 'A'
                        ENDCASE

                        m.nrunno_in   = THIS.nRunNo  &&  Bracketed b/c this.nrunno <> 0 for a new run (for some reason), which makes the recs from suspense not show on statements
                        m.crunyear_in = THIS.cRunYear
                    ENDIF
                    m.ciddisb = THIS.get_next_key('disbhist')

                    * Only put the record in suspense if there was activity on the record
                    IF m.nNetCheck # 0 OR m.nincome # 0 OR m.nExpense # 0 OR m.nSevTaxes # 0
                        INSERT INTO suspense FROM MEMVAR
                        IF m.nrunno_in = THIS.nRunNo AND m.crunyear_in = THIS.cRunYear
                            INSERT INTO tsuspense FROM MEMVAR
                        ENDIF
                        SELE invtmp
                        DELETE NEXT 1
                    ENDIF
                ENDSCAN && invtmp
            ENDSCAN && tempfreqowner

            THIS.perflog('Suspense: Freq In', .T.)
            THIS.timekeeper('Ending Owner_freq_in')
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Owner_Freq_In', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)
        m.goapp.oLogger.LogMileStone('Suspense: Owner Freq In - End')

        RETURN llReturn

        ENDPROC

        **************************************
    PROTECTED PROCEDURE owner_freq_out
        **************************************
        LOCAL lcFreqType
        LOCAL llReturn, loError
        LOCAL cRunYear, ciddisb, crunyear_in, hdate, nRunNo, nrunno_in
        *
        *  Remove records from suspense if the owner isn't paid monthly and it is time to pay them
        *  Place them in invtmp
        *
        llReturn = .T.
        m.goapp.Rushmore(.T., 'Owner_Freq_Out')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            THIS.perflog('Suspense: Freq Out')
            THIS.timekeeper('Starting Owner_freq_out')
            m.goapp.oLogger.LogMileStone('Suspense: Owner Freq Out - Start')

            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Frequency Out')

            STORE .F. TO llPayFreq1, llPayFreq2, llPayFreq3, llPayFreq4, llPay
            llPayFreq1 = .T.
            IF INLIST(MONTH(THIS.dAcctDate), 3, 6, 9, 12)
                llPayFreq2 = .T.
            ENDIF
            IF INLIST(MONTH(THIS.dAcctDate), 6, 12)
                llPayFreq3 = .T.
            ENDIF
            IF INLIST(MONTH(THIS.dAcctDate), 12)
                llPayFreq4 = .T.
            ENDIF

            * Get the current suspense status for each owner and well.
            *  Added .t. as the Force parameter to prevent subsequent closings from using the same curLastType cursor, which can cause problems. BH 12/31/09
            THIS.perflog('Freq Out: GetLastType')
            THIS.getlasttype(.F., .F., THIS.cGroup, .T.)
            THIS.perflog('Freq Out: GetLastType', .T.)

            * Only process owners in invtmp.
            SELECT  cownerid, ;
                    ndisbfreq ;
                FROM invtmp ;
                WHERE BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND NOT lhold ;
                INTO CURSOR tempfreq READWRITE ;
                ORDER BY cownerid ;
                GROUP BY cownerid

            * Include owners who have non-monthly disbursement frequency suspense
            SELECT  suspense.* ;
                FROM suspense;
                WHERE BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND cownerid + cwellid IN (SELECT  cownerid + cwellid ;
                                                   FROM CurLastSuspType ;
                                                   WHERE INLIST(cSuspType, 'Q', 'S', 'A')) ;
                    AND cGroup == THIS.cGroup ;
                INTO CURSOR suspfreq ;
                ORDER BY suspense.cownerid

            CREATE CURSOR delsusp (ciddisb c(8))

            * Look for non-monthly owners who are not on hold
            * Changed to include monthly owners because we want to include owners who might have been a different disb freq
            *   in earlier runs and have suspense needing to be released now. - PWS 12/6/2011
            SELECT tempfreq
            SCAN
                SCATTER MEMVAR
                THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Frequency Out - ' + m.cownerid)

                IF m.goapp.lCanceled
                    llReturn          = .F.
                    IF NOT m.goapp.CancelMsg()
                        THIS.lCanceled = .T.
                        EXIT
                    ENDIF
                ENDIF

                DO CASE
                    CASE tempfreq.ndisbfreq = 1 OR tempfreq.ndisbfreq = 0
                        lcFreqType = 'M'
                        llPay      = .T.
                    CASE tempfreq.ndisbfreq = 2
                        lcFreqType = 'Q'
                        llPay      = llPayFreq2
                    CASE tempfreq.ndisbfreq = 3
                        lcFreqType = 'S'
                        llPay      = llPayFreq3
                    CASE tempfreq.ndisbfreq = 4
                        lcFreqType = 'A'
                        llPay      = llPayFreq4
                ENDCASE

                * Only release suspense for the owner's frequency. If the suspense type for the owner
                * is no longer the frequency type, ignore it.
                IF llPay
                    * Bring in all suspense entries for the given frequency type
                    SELECT suspfreq
                    SCAN FOR cownerid == m.cownerid
                        SCATTER MEMVAR

                        *  Check to make sure this interest isn't currently on hold - BH 01-25-12
                        IF THIS.isonhold(m.cownerid, .T., m.cwellid, m.cTypeInv)
                            LOOP
                        ENDIF

                        * Store the original run into run_in - only if the runno_in isn't set
                        IF m.nrunno_in = 0
                            m.nrunno_in   = m.nRunNo
                            m.crunyear_in = m.cRunYear
                        ENDIF
                        * Swap the original run with current run
                        m.nRunNo   = THIS.nRunNo
                        m.cRunYear = THIS.cRunYear
                        m.hdate    = THIS.dAcctDate
                        m.ciddisb  = THIS.get_next_key('disbhist')
                        IF EMPTY(m.cSuspType)
                            m.nrunno_in   = 0
                            m.crunyear_in = ''
                        ENDIF
                        INSERT INTO invtmp FROM MEMVAR
                        INSERT INTO delsusp VALUES (suspfreq.ciddisb)

                        * Get the well history record corresponding to the owner history
                        THIS.getwellhist(m.cwellid, m.hyear, m.hperiod)
                    ENDSCAN && suspfreq
                ENDIF && llPay
            ENDSCAN && tempfreq

            IF RECCOUNT('delsusp') > 0
                DELETE FROM suspense WHERE ciddisb IN (SELECT ciddisb FROM delsusp)
            ENDIF

            THIS.perflog('Suspense: Freq Out', .T.)
            THIS.timekeeper('Ending Owner_freq_out')
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Owner_Freq_Out', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to suspense the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)
        m.goapp.oLogger.LogMileStone('Suspense: Owner Freq Out - End')

        RETURN llReturn
        ENDPROC

        *****************************************
    PROTECTED PROCEDURE owner_deficits_in
        *****************************************
        LOCAL lnCurBalance, lnPriorBalance
        LOCAL llReturn, loError
        LOCAL cRunYear, ciddisb, crunyear_in, cSuspType, nRunNo, nrunno_in
        *
        *  Remove records from invtmp if they have a negative netcheck
        *  Place them in suspense

        llReturn       = .T.
        lnPriorBalance = 0
        m.goapp.Rushmore(.T., 'Owner_Deficits_In')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            THIS.perflog('Suspense: Deficits In')
            THIS.timekeeper('Starting Owner_deficits_in')
            
            m.goapp.oLogger.LogMileStone('Suspense: Owner Deficits In - Start')

            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Deficits In')

            * Get the owner's current run balance
            THIS.owner_current_balance()

            * Get the owner's total suspense balance before this run
            THIS.owner_suspense_balance(.T., .F., THIS.cGroup, .F., .F.)

            * Scan through the unique owner combinations so we can get the current balance for the given well
            SELE owncurbal
            SCAN FOR BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner)
                SCATTER MEMVAR
                THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Deficits In - ' + m.cownerid)

                IF m.goapp.lCanceled
                    llReturn          = .F.
                    IF NOT m.goapp.CancelMsg()
                        THIS.lCanceled = .T.
                        EXIT
                    ENDIF
                ENDIF

                swselect('investor')
                IF SEEK(m.cownerid)
                    * Don't include owners marked to post
                    IF (lIntegGl AND (m.goapp.lAMVersion OR m.goapp.lQBVersion)) OR lDummy
                        LOOP
                    ENDIF
                ENDIF

                *  Get what their current suspense balance is, and add it to the current balance.  If that total is negative, add it to suspense.
                SELECT ownsuspbal
                IF SEEK(m.cownerid)
                    lnPriorBalance = nBalance
                ELSE
                    lnPriorBalance = 0
                ENDIF

                IF m.nBalance + lnPriorBalance >= 0
                    LOOP
                ENDIF

                SELECT invtmp
                SCAN FOR cownerid = m.cownerid
                    IF NOT EMPTY(invtmp.cprogcode)
                        swselect('programs')
                        LOCATE FOR cprogcode = invtmp.cprogcode
                        IF NOT programs.lprognet
                            * Don't include non-netting programs here
                            LOOP
                        ENDIF
                    ENDIF
                    SELECT invtmp
                    SCATTER MEMVAR


                    IF invtmp.nrunno_in = 0
                        m.nrunno_in   = THIS.nRunNo  &&  Bracketed b/c this.nrunno <> 0 for a new run (for some reason), which makes the recs from suspense not show on statements
                        m.crunyear_in = THIS.cRunYear
                        * Only change suspense type on initial suspense entry
                        m.cSuspType = 'D'
                    ELSE
                        * Put the original run back in record
                        m.nRunNo   = m.nrunno_in
                        m.cRunYear = m.crunyear_in
                    ENDIF

                    IF m.nNetCheck # 0
                        m.ciddisb = getnextpk('suspense')
                        INSERT INTO suspense FROM MEMVAR
                        IF m.nrunno_in = THIS.nRunNo AND m.crunyear_in = THIS.cRunYear
                            INSERT INTO tsuspense FROM MEMVAR
                        ENDIF
                        SELE invtmp
                        DELETE NEXT 1
                    ELSE
                        *  In case there's any space-hogging all-zero records in invtmp - get rid of them!
                        IF m.nNetCheck = 0 AND m.nincome = 0 AND m.nExpense = 0 AND m.nSevTaxes = 0
                            SELECT invtmp
                            DELETE NEXT 1
                        ENDIF
                    ENDIF
                ENDSCAN && invtmp
            ENDSCAN && owncurbal

            WAIT CLEAR

            THIS.perflog('Suspense: Deficits In', .T.)
            THIS.timekeeper('Ending Owner_deficits_in')
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Owner_Deficits_In', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)
        m.goapp.oLogger.LogMileStone('Suspense: Owner Deficits In - End')

        RETURN llReturn
        ENDPROC

 ******************************************
   PROTECTED PROCEDURE owner_deficits_out
      ******************************************

      LOCAL lnCurBalance, lnSuspBalance, lcSuspKey
      LOCAL llReturn, lnbalance, loError, lprognet
      LOCAL cownerid, cRunYear, cTypeInv, cwellid, ciddisb, crunyear_in, cSuspType, hdate, nRunNo
      LOCAL nrunno_in, m.cGroup

      lcString = 'Owner Deficits Out' + CHR(13)
      STRTOFILE(lcString,'temp\rushmore.txt',1)
      STRTOFILE('Owner Deficits Out' + CHR(13),'temp\dispmemo.txt')
      DISPLAY MEMORY TO FILE temp\dispmemo.txt ADDITIVE NOCONSOLE
      STRTOFILE('Owner Deficits Out' + CHR(13)+CHR(13),'temp\dispstatus.txt')
      DISPLAY STATUS TO FILE temp\dispstatus.txt ADDITIVE NOCONSOLE
      STRTOFILE('Owner Deficits Out ' + CHR(13),'temp\dispseconds.txt',1)
      STRTOFILE('Starting Time: ' + TTOC(DATETIME()) + CHR(13),'temp\dispseconds.txt',1)
      lnStartProc = SECONDS()


      * Bring in suspense records if the current run can
      * cover them in total

      llReturn = .T.
      m.goapp.Rushmore(.T., 'Owner_Deficits_Out')

      TRY
         THIS.perflog('Suspense: Deficits Out')
         THIS.timekeeper('Starting Owner_deficits_out')

         THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Deficits Out')
         THIS.oProgress.UpdateProgress(THIS.nProgress)
         THIS.nProgress = THIS.nProgress + 1
         m.goapp.oLogger.LogMileStone('Suspense: Owner Deficits Out - Start')

         swselect('suspense',.T.)
         SET ORDER TO ciddisb   && CIDDISB
         * Get the unique owners from invtmp
         SELECT  cownerid, ;
            cGroup ;
            FROM invtmp ;
            WHERE BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
            AND invtmp.lhold = .F. ;
            AND invtmp.lonhold = .F. ;
            INTO CURSOR tempown ;
            ORDER BY cownerid ;
            GROUP BY cownerid

         * Get the owner's current balance for this run
         THIS.owner_current_balance()

         * Get the owner's suspense balance before this run by well
         THIS.owner_suspense_balance(.F., .F., THIS.cGroup)
         SELECT * FROM ownsuspbal INTO CURSOR ownwellsuspbal

         * Get suspense balances by owner before this run
         THIS.owner_suspense_balance(.T., .F., THIS.cGroup)

         * Get the current suspense status for each owner and well.
         * We're only going to release the csusptype = D records below
         THIS.perflog('Deficits Out: GetLastType')
         THIS.getlasttype(.F., .F., THIS.cGroup, .T., .F., .T.)
         THIS.perflog('Deficits Out: GetLastType', .T.)

         swselect('programs')
         SET ORDER TO cprogcode

         * Scan through the owner deficit balances
         SELECT  cownerid ;
            FROM CurLastSuspType ;
            WHERE cSuspType = 'D' ;
            AND cownerid NOT IN (SELECT  cownerid ;
            FROM investor ;
            WHERE lhold) ;
            AND cwellid + cownerid + cTypeInv NOT IN (SELECT  cwellid + cownerid + cTypeInv ;
            FROM wellinv ;
            WHERE lonhold) ;
            INTO CURSOR tempcurlast READWRITE ;
            ORDER BY cownerid ;
            GROUP BY cownerid
         INDEX ON cownerid TAG cownerid

         CREATE CURSOR delsusp (ciddisb c(8))

         * Get the suspense records for the owners that are in deficit into a cursor
         SELECT suspense.* FROM suspense WITH (Buffering=.t.) ;
            WHERE cownerid IN (SELECT cownerid FROM tempcurlast) ;
            INTO CURSOR curOwnerDeficits ;
            ORDER BY cownerid

         SELECT tempcurlast  && Deficit that were in deficit before this run
         SCAN
            SCATTER MEMVAR
            lnStart = SECONDS()

            IF m.goapp.lCanceled
               llReturn          = .F.
               IF NOT m.goapp.CancelMsg()
                  THIS.lCanceled = .T.
                  EXIT
               ENDIF
            ENDIF

            SELE ownsuspbal  && Owner total suspense balance
            SCAN FOR cownerid == m.cownerid
               SCATTER MEMVAR
               lnStart = SECONDS()
               lnSuspBalance = nBalance
               * Look for owners that have a positive balance this run
               SELECT owncurbal  && Owner current balance
               SCAN FOR cownerid == m.cownerid
                  lnbalance = nBalance
                  THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Deficits Out - ' + m.cownerid)

                  IF lnbalance + lnSuspBalance >= 0 AND (lnbalance # 0 AND lnSuspBalance # 0)
                     * Current revenue for owner exceeds the deficit for the owner
                     * so we can cover it. Bring it out of suspense back into
                     * invtmp.
                     SELECT curOwnerDeficits
                     SCAN FOR cownerid == m.cownerid
                        SCATTER MEMVAR

                        IF NOT EMPTY(m.cprogcode)
                           swselect('programs')
                           IF SEEK(m.cprogcode)
                              m.lprognet = lprognet
                           ENDIF
                        ENDIF
                        IF NOT EMPTY(m.cprogcode) AND NOT m.lprognet
                           LOOP  && Don't include programs that don't net
                        ENDIF

                        *  Should never be blank owner types, but if they are, they're probably old payments for WI owners, so fill that in.
                        IF EMPTY(m.cTypeInv)
                           m.cTypeInv = 'W'
                        ENDIF

                        *  If the owner or interest is on hold, or they're not due to be paid, loop out
                        IF THIS.isonhold(m.cownerid, .T., m.cwellid, m.cTypeInv)
                           LOOP
                        ENDIF

                        lcSuspKey = m.ciddisb
                        * Store the original run into run_in
                        IF m.nrunno_in = 0
                           m.nrunno_in   = m.nRunNo
                           m.crunyear_in = m.cRunYear
                        ENDIF
                        * Swap the original run with current run
                        m.nRunNo   = THIS.nRunNo
                        m.cRunYear = THIS.cRunYear
                        m.hdate    = THIS.dAcctDate
                        m.ciddisb  = THIS.get_next_key('disbhist')
                        IF EMPTY(m.cSuspType)
                           m.nrunno_in   = 0
                           m.crunyear_in = ''
                        ENDIF
                        INSERT INTO invtmp FROM MEMVAR
                        INSERT INTO delsusp VALUES (lcSuspKey)

                        * Get the well history record corresponding to the owner history
                        THIS.getwellhist(m.cwellid, m.hyear, m.hperiod)

                     ENDSCAN && curOwnerDeficits
                  ELSE
                     IF lnbalance < 0
                        * There wasn't enough revenue to cover deficits.
                        * Put the current run for this well into suspense.
                        SELE invtmp
                        SCAN FOR cownerid == m.cownerid
                           SCATTER MEMVAR
                           IF NOT EMPTY(m.cprogcode)
                              swselect('programs')
                              LOCATE FOR cprogcode == m.cprogcode
                              IF NOT programs.lprognet
                                 * Don't include non-netting programs here
                                 LOOP
                              ENDIF
                           ENDIF
                           SELECT invtmp
                           m.nRunNo   = THIS.nRunNo
                           m.cRunYear = THIS.cRunYear
                           * Plug the run no in for original entries only
                           IF m.nrunno_in = 0
                              m.nrunno_in   = THIS.nRunNo  &&  Bracketed b/c this.nrunno <> 0 for a new run (for some reason), which makes the recs from suspense not show on statements
                              m.crunyear_in = THIS.cRunYear
                              m.cSuspType   = 'D'
                           ENDIF
                           * Get the next valid primary key for suspense
                           m.ciddisb = THIS.get_next_key('disbhist')
                           IF m.nNetCheck # 0
                              INSERT INTO suspense FROM MEMVAR
                              IF !THIS.lNewRun AND m.nrunno_in = THIS.nRunNo AND m.crunyear_in = THIS.cRunYear
                                 INSERT INTO tsuspense FROM MEMVAR
                              ENDIF
                              SELE invtmp
                              DELETE NEXT 1
                           ENDIF  && m.nNetCheck <> 0
                        ENDSCAN
                     ENDIF
                  ENDIF && lnbalance + lnSuspBalance >= 0
               ENDSCAN && owncurbal
            ENDSCAN && ownsuspbal
            lnEnd = SECONDS()
            *            STRTOFILE('Owner/Well: ' + m.cownerid + m.cwellid + ' Seconds: ' + TRANSFORM(lnEnd-lnStart)+CHR(13),'temp\dispseconds.txt',1)
         ENDSCAN && tempcurlast

         IF RECCOUNT('delsusp') > 0
            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Deficits Out - Remove Suspense')
            DELETE FROM suspense WHERE ciddisb IN (SELECT ciddisb FROM delsusp)
         ENDIF

         THIS.perflog('Suspense: Deficits Out', .T.)
         THIS.timekeeper('Ending Owner_deficits_out')
         WAIT CLEAR
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'Owner_Deficits_Out', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
         MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      SYS(3092,'')
      lnEndProc = SECONDS()
      STRTOFILE('Ending Time: ' + TTOC(DATETIME()) + CHR(13),'temp\dispseconds.txt',1)
      STRTOFILE('Duration: ' + TRANSFORM(lnEndProc - lnStartProc) + CHR(13)+CHR(13),'temp\dispseconds.txt',1)

      THIS.CheckCancel()
      m.goapp.Rushmore(.F.)

      m.goapp.oLogger.LogMileStone('Suspense: Owner Deficits Out - End')
      RETURN llReturn

   ENDPROC
        *********************************
    PROTECTED PROCEDURE well_deficits_in
        *********************************
        LOCAL lnCurBalance, llReturn, loError

        llReturn = .T.
        m.goapp.Rushmore(.T., 'Well_Deficits_In')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            THIS.perflog('Suspense: Well Deficits In')
            THIS.timekeeper('Starting Well_deficits_in')

            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Well Deficits In')

            *
            *  Remove records from invtmp if they have a negative netcheck
            *  Place them in suspense
            *
            * Get the unique owner and well combinations from invtmp
            SELECT  cownerid, ;
                    cwellid ;
                FROM invtmp ;
                WHERE BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND cownerid NOT IN(SELECT  cownerid ;
                                            FROM investor ;
                                            WHERE IIF(NOT m.goapp.lAMVersion ;
                                                  AND NOT m.goapp.lQBVersion, .F., lIntegGl)) ;
                INTO CURSOR tempown ;
                ORDER BY cownerid, cwellid ;
                GROUP BY cownerid, cwellid

            * Scan through the unique owner and well combinations so we can get the current balance for the given well
            SELE tempown
            SCAN
                SCATTER MEMVAR

                IF m.goapp.lCanceled
                    llReturn          = .F.
                    IF NOT m.goapp.CancelMsg()
                        THIS.lCanceled = .T.
                        EXIT
                    ENDIF
                ENDIF

                lnCurBalance = THIS.well_current_balance(m.cownerid, m.cwellid)

                *  Get what their current suspense balance is, and add it to the current balance.  If that total is negative, add it to suspense.
                lnPriorBalance = THIS.Well_Suspense_Balance(m.cownerid, m.cwellid)

                * If the balance for the well is negative, put all records for the well for this owner in suspense
                IF lnCurBalance + lnPriorBalance < 0
                    SELECT invtmp
                    SCAN FOR cownerid == m.cownerid AND cwellid == m.cwellid
                        SCATTER MEMVAR
                        IF m.nincome # 0 OR m.nExpense # 0 OR m.nSevTaxes # 0 OR m.nNetCheck # 0 OR ;
                                m.ntotale1 # 0 OR m.ntotale2 # 0 OR m.ntotale3 # 0 OR m.ntotale4 # 0  OR ;
                                m.ntotale5 # 0 OR m.ntotalea # 0 OR m.ntotaleb # 0

                            IF m.nrunno_in = 0
                                m.nrunno_in   = THIS.nRunNo  &&  Bracketed b/c this.nrunno <> 0 for a new run (for some reason), which makes the recs from suspense not show on statements
                                m.crunyear_in = THIS.cRunYear
                                m.cSuspType   = 'D'
                            ENDIF
                            m.ciddisb = THIS.get_next_key('disbhist')
                            IF m.nNetCheck # 0
                                INSERT INTO suspense FROM MEMVAR
                                IF m.nrunno_in = THIS.nRunNo AND m.crunyear_in = THIS.cRunYear
                                    INSERT INTO tsuspense FROM MEMVAR
                                ENDIF
                                SELE invtmp
                                DELETE NEXT 1
                            ENDIF
                        ENDIF
                    ENDSCAN
                ENDIF
            ENDSCAN

            THIS.perflog('Suspense: Well Deficits In', .T.)
            THIS.timekeeper('Ending Well_deficits_in')
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Well_Deficits_In', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)

        RETURN llReturn
        ENDPROC

        **********************************
    PROTECTED PROCEDURE well_deficits_out
        **********************************

        LOCAL lnCurBalance, lnSuspBalance

        llReturn = .T.
        m.goapp.Rushmore(.T., 'Well_Deficits_Out')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Well Deficits Out')

            THIS.perflog('Suspense: Well Deficits Out')
            THIS.timekeeper('Starting Well_deficits_out')

            *
            * Bring in suspense records if the current run can
            * cover them in total
            *

            * Get the unique owner and well combinations from invtmp
            SELECT  cownerid, ;
                    cwellid ;
                FROM invtmp ;
                WHERE BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                INTO CURSOR tempown ;
                ORDER BY cownerid, cwellid ;
                GROUP BY cownerid, cwellid

            * Get the current suspense status for each owner and well.
            *  We're only going to release the csusptype = D records below
            THIS.perflog('Well Deficits Out: GetLastType')
            THIS.getlasttype(.F., .F., THIS.cGroup, .T., .F., .T.)
            THIS.perflog('Well Deficits Out: GetLastType', .T.)

            * Create a cursor to store the keys for suspense records released
            CREATE CURSOR delsusp (ciddisb c(8))

            SELECT  * ;
                FROM suspense WITH (BUFFERING = .T.) ;
                INTO CURSOR tempsusp ;
                WHERE cownerid + cwellid IN (SELECT  cownerid + cwellid ;
                                                 FROM CurLastSuspType ;
                                                 WHERE cSuspType = 'D')


            * Scan through the unique owner and well combinations so we can get the current balance for the given well
            SELE tempown
            SCAN
                SCATTER MEMVAR

                IF m.goapp.lCanceled
                    llReturn          = .F.
                    IF NOT m.goapp.CancelMsg()
                        THIS.lCanceled = .T.
                        EXIT
                    ENDIF
                ENDIF

                lnCurBalance  = THIS.well_current_balance(m.cownerid, m.cwellid)
                lnSuspBalance = THIS.Well_Suspense_Balance(m.cownerid, m.cwellid)

                *  Only release it if the sum of the current + old suspense are > 0
                IF lnCurBalance + lnSuspBalance > 0
                    * Current revenue for well exceeds the deficit for the well
                    * so we can cover it. Bring it out of suspense back into
                    * invtmp.
                    SELECT tempsusp
                    SCAN FOR cwellid == m.cwellid AND cownerid == m.cownerid AND cGroup == THIS.cGroup
                        SCATTER MEMVAR

                        *  If the owner or interest is on hold, or they're not due to be paid, loop out
                        IF THIS.isonhold(m.cownerid) OR THIS.isonhold(m.cownerid, .T., m.cwellid, m.cTypeInv) OR NOT THIS.at_pay_freq(m.cownerid)
                            LOOP
                        ENDIF

                        * Store the original run into run_in
                        IF m.nrunno_in = 0
                            m.nrunno_in   = m.nRunNo
                            m.crunyear_in = m.cRunYear
                        ENDIF
                        * Swap the original run with current run
                        m.nRunNo   = THIS.nRunNo
                        m.cRunYear = THIS.cRunYear
                        m.hdate    = THIS.dAcctDate
                        m.ciddisb  = THIS.get_next_key('disbhist')
                        IF EMPTY(m.cSuspType)
                            m.nrunno_in   = 0
                            m.crunyear_in = ''
                        ENDIF
                        INSERT INTO invtmp FROM MEMVAR
                        INSERT INTO delsusp VALUES (tempsusp.ciddisb)

                        * Get the well history record corresponding to the owner history
                        THIS.getwellhist(m.cwellid, m.hyear, m.hperiod)
                    ENDSCAN
                ELSE
                    * There wasn't enough revenue to cover deficits.
                    * Put the current run for this well into suspense.
                    SELE invtmp
                    SCAN FOR cownerid == m.cownerid AND cwellid == m.cwellid
                        SCATTER MEMVAR

                        swselect('investor')
                        LOCATE FOR cownerid == m.cownerid AND lIntegGl
                        IF FOUND() AND (m.goapp.lAMVersion OR m.goapp.lQBVersion)
                            LOOP  &&  Don't add back to suspense for posting owners
                        ENDIF

                        m.nRunNo   = THIS.nRunNo
                        m.cRunYear = THIS.cRunYear
                        m.hdate    = THIS.dAcctDate
                        * Store the original run into run_in
                        IF m.nrunno_in = 0
                            m.nrunno_in   = THIS.nRunNo  &&  Bracketed b/c this.nrunno <> 0 for a new run (for some reason), which makes the recs from suspense not show on statements
                            m.crunyear_in = m.cRunYear
                            m.cSuspType   = 'D'
                        ENDIF
                        * Get the next valid primary key for suspense
                        m.ciddisb = THIS.get_next_key('disbhist')
                        IF m.nNetCheck # 0
                            INSERT INTO suspense FROM MEMVAR
                            IF m.nrunno_in = THIS.nRunNo AND m.crunyear_in = THIS.cRunYear
                                INSERT INTO tsuspense FROM MEMVAR
                            ENDIF
                            SELE invtmp
                            DELETE NEXT 1
                        ENDIF
                    ENDSCAN
                ENDIF
            ENDSCAN

            * Delete the suspense records released
            IF RECCOUNT('delsusp') > 0
                DELETE FROM suspense WHERE ciddisb IN (SELECT ciddisb FROM delsusp)
                swclose('delsusp')
            ENDIF

            THIS.perflog('Suspense: Well Deficits Out', .T.)
            THIS.timekeeper('Ending Well_deficits_out')
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Well Deficits_Out', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)

        RETURN llReturn
        ENDPROC

        *************************************
    PROTECTED PROCEDURE well_current_balance
        *************************************
        LPARAMETERS tcOwnerid, tcWellID
        LOCAL lcAlias, lnbalance, lnReturn, loError

        lnReturn = 0
        m.goapp.Rushmore(.T., 'Well_Current_Balance')

        TRY

            IF m.goapp.lCanceled
                lnReturn = 0
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            lcAlias = ALIAS()

            SELECT  SUM(nNetCheck) AS nBalance ;
                FROM invtmp WITH (BUFFERING = .T.) ;
                WHERE cownerid == tcOwnerid ;
                    AND cwellid == tcWellID ;
                INTO CURSOR tempbalance

            SELECT (lcAlias)

            IF _TALLY > 0
                lnbalance = tempbalance.nBalance
            ELSE
                lnbalance = 0
            ENDIF
            swclose('tempbalance')

            lnReturn = lnbalance

        CATCH TO loError
            lnReturn = 0
            DO errorlog WITH 'Well_Current_Balance', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            *         MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)

        RETURN lnReturn

        ENDPROC

        **************************************
    PROTECTED PROCEDURE Well_Suspense_Balance
        **************************************
        LPARAMETERS tcOwnerid, tcWellID
        LOCAL lcAlias, lcRunYear, lnbalance
        LOCAL lnReturn, loError

        lnReturn = 0

        lcAlias = ALIAS()
        m.goapp.Rushmore(.T., 'Well_Suspense_Balance')

        TRY

            IF m.goapp.lCanceled
                lnReturn = 0
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            lcRunYear = THIS.cRunYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

            * Calculate the suspense balance
            SELECT  SUM(nNetCheck) AS nBalance ;
                FROM suspense WITH (BUFFERING = .T.) ;
                WHERE cownerid == tcOwnerid ;
                    AND cwellid == tcWellID ;
                    AND crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear ;
                    AND cGroup = THIS.cGroup ;
                INTO CURSOR tempbalance

            IF _TALLY > 0
                lnbalance = tempbalance.nBalance
                swclose('tempbalance')
            ELSE
                swclose('tempbalance')
                lnbalance = 0
            ENDIF

            lnReturn = lnbalance

        CATCH TO loError
            lnReturn = 0
            DO errorlog WITH 'Well_Suspense_Balance', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)

        SELECT(lcAlias)

        RETURN lnReturn
        ENDPROC

        *********************************
    PROTECTED PROCEDURE program_deficits_in
        *********************************
        LOCAL lnCurBalance, llReturn, loError

        llReturn = .T.
        m.goapp.Rushmore(.T., 'Program_Deficits_In')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            THIS.perflog('Suspense: Program Deficits In')
            THIS.timekeeper('Starting Program_deficits_in')

            *
            *  Remove records from invtmp if they have a negative netcheck
            *  Place them in suspense
            *
            * Get the unique owner and well combinations from invtmp
            SELECT  cownerid, ;
                    cprogcode ;
                FROM invtmp ;
                WHERE NOT EMPTY(cprogcode) ;
                    AND BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND cprogcode IN (SELECT  cprogcode ;
                                          FROM programs ;
                                          WHERE lprognet = .F.) ;
                INTO CURSOR tempown ;
                ORDER BY cownerid, cprogcode ;
                GROUP BY cownerid, cprogcode

            * Scan through the unique owner and well combinations so we can get the current balance for the given well
            SELE tempown
            SCAN
                SCATTER MEMVAR

                swselect('investor')
                IF SEEK(m.cownerid)
                    * Don't include owners marked to post
                    IF (lIntegGl AND (m.goapp.lAMVersion OR m.goapp.lQBVersion)) OR lDummy
                        LOOP
                    ENDIF
                ENDIF

                IF m.goapp.lCanceled
                    llReturn          = .F.
                    MESSAGEBOX('Processing canceled by user...', 16, 'Processing Canceled')
                    EXIT
                ENDIF

                THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... ' + ;
                      'Owner Program Suspense In: ' + ALLTRIM(m.cownerid) + '/' + ALLTRIM(m.cprogcode))
                lnCurBalance = THIS.program_current_balance(m.cownerid, m.cprogcode)
                * If the balance for the program is negative, put all records for the well for this owner in suspense
                IF lnCurBalance < 0
                    SELECT invtmp
                    SCAN FOR cownerid == m.cownerid AND cprogcode == m.cprogcode
                        SCATTER MEMVAR

                        IF m.nrunno_in = 0
                            m.nrunno_in   = THIS.nRunNo  &&  Bracketed b/c this.nrunno <> 0 for a new run (for some reason), which makes the recs from suspense not show on statements
                            m.crunyear_in = THIS.cRunYear
                            m.cSuspType   = 'D'
                        ELSE
                            m.nRunNo   = m.nrunno_in
                            m.cRunYear = m.crunyear_in
                        ENDIF
                        m.ciddisb = THIS.get_next_key('disbhist')
                        IF m.nNetCheck # 0
                            INSERT INTO suspense FROM MEMVAR
                            IF m.nrunno_in = THIS.nRunNo AND m.crunyear_in = THIS.cRunYear
                                INSERT INTO tsuspense FROM MEMVAR
                            ENDIF
                            SELE invtmp
                            DELETE NEXT 1
                        ENDIF
                    ENDSCAN
                ENDIF
            ENDSCAN

            THIS.perflog('Suspense: Program Deficits In', .T.)
            THIS.timekeeper('Ending Program_deficits_in')
        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Program_Deficits_In', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)

        RETURN llReturn
        ENDPROC

        **********************************
    PROTECTED PROCEDURE program_deficits_out
        **********************************
        LOCAL lnCurBalance, lnSuspBalance
        LOCAL llReturn, loError

        llReturn = .T.
        m.goapp.Rushmore(.T., 'Program_Deficits_Out')

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            THIS.perflog('Suspense: Program Deficits Out')
            THIS.timekeeper('Starting Program_deficits_out')

            swselect('programs')
            SET ORDER TO cprogcode

            swselect('suspense')
            SET ORDER TO ciddisb

            * Get the unique owner and program combinations from invtmp
            SELECT  cownerid, ;
                    cprogcode ;
                FROM invtmp ;
                WHERE NOT EMPTY(cprogcode) ;
                    AND invtmp.cprogcode IN (SELECT  cprogcode ;
                                                 FROM programs ;
                                                 WHERE programs.lprognet = .F.) ;
                    AND BETWEEN(invtmp.cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                INTO CURSOR tempown ;
                ORDER BY invtmp.cownerid, invtmp.cprogcode ;
                GROUP BY invtmp.cownerid, invtmp.cprogcode

            SELECT  * ;
                FROM suspense WITH (BUFFERING = .T.) ;
                WHERE cownerid + cprogcode IN (SELECT  cownerid + cprogcode ;
                                                   FROM tempown) ;
                    AND cownerid + cwellid + cTypeInv NOT IN (SELECT  cownerid + cwellid + cTypeInv ;
                                                                  FROM wellinv ;
                                                                  WHERE lonhold) ;
                INTO CURSOR xxsusp READWRITE ;
                ORDER BY cownerid, cprogcode
            INDEX ON cprogcode TAG cprogcode
            INDEX ON cownerid TAG cownerid

            * Store the keys of the records to delete here
            CREATE CURSOR delsusp (ciddisb   c(8))

            * Scan through the unique owner and well combinations so we can get the current balance for the given well
            SELE tempown
            SCAN
                SCATTER MEMVAR
                THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... ' + ;
                      'Owner Program Suspense Out: ' + ALLTRIM(m.cownerid) + '/' + ALLTRIM(m.cprogcode))

                IF m.goapp.lCanceled
                    llReturn          = .F.
                    IF NOT m.goapp.CancelMsg()
                        THIS.lCanceled = .T.
                        EXIT
                    ENDIF
                ENDIF

                lnCurBalance = THIS.program_current_balance(m.cownerid, m.cprogcode)

                IF lnCurBalance > 0

                    lnSuspBalance = THIS.program_suspense_balance(m.cownerid, m.cprogcode)

                    IF lnSuspBalance < 0
                        IF lnCurBalance >= ABS(lnSuspBalance)
                            * Current revenue for well exceeds the deficit for the well
                            * so we can cover it. Bring it out of suspense back into
                            * invtmp.

                            SELECT xxsusp
                            SCAN FOR cownerid == tempown.cownerid AND cprogcode == tempown.cprogcode
                                m.lprognet = lprognet
                                IF NOT EMPTY(xxsusp.cprogcode)
                                    * Get the current setting of lprognet
                                    swselect('programs')
                                    IF SEEK(xxsusp.cprogcode)
                                        m.lprognet = lprognet
                                    ENDIF
                                ENDIF
                                SELECT xxsusp
                                SCATTER MEMVAR
                                * Store the original run into run_in
                                IF m.nrunno_in = 0
                                    m.nrunno_in   = m.nRunNo
                                    m.crunyear_in = m.cRunYear
                                ENDIF
                                * Swap the original run with current run
                                m.nRunNo   = THIS.nRunNo
                                m.cRunYear = THIS.cRunYear
                                m.hdate    = THIS.dAcctDate
                                m.ciddisb  = THIS.get_next_key('disbhist')
                                IF EMPTY(m.cSuspType)
                                    m.nrunno_in   = 0
                                    m.crunyear_in = ''
                                ENDIF
                                INSERT INTO invtmp FROM MEMVAR
                                m.ciddisb = xxsusp.ciddisb
                                INSERT INTO delsusp FROM MEMVAR

                                * Get the well history record corresponding to the owner history
                                THIS.getwellhist(m.cwellid, m.hyear, m.hperiod)
                            ENDSCAN
                        ELSE
                            * There wasn't enough revenue to cover deficits.
                            * Put the current run for this well into suspense.
                            SELE invtmp
                            SCAN FOR cownerid == m.cownerid AND cprogcode == m.cprogcode
                                IF EMPTY(cprogcode) OR lprognet
                                    LOOP
                                ENDIF

                                SCATTER MEMVAR
                                m.cSuspType = 'D'

                                m.nRunNo   = THIS.nRunNo
                                m.cRunYear = THIS.cRunYear
                                IF m.nrunno_in = 0
                                    m.nrunno_in   = THIS.nRunNo
                                    m.crunyear_in = THIS.cRunYear
                                ENDIF
                                m.hdate       = THIS.dAcctDate

                                * Get the next valid primary key for suspense
                                m.ciddisb = THIS.get_next_key('disbhist')
                                IF m.nNetCheck # 0
                                    INSERT INTO suspense FROM MEMVAR
                                    IF m.nrunno_in = THIS.nRunNo AND m.crunyear_in = THIS.cRunYear
                                        INSERT INTO tsuspense FROM MEMVAR
                                    ENDIF
                                    SELE invtmp
                                    DELETE NEXT 1
                                ENDIF
                            ENDSCAN
                        ENDIF
                    ELSE

                        SELECT xxsusp
                        SCAN FOR cownerid == tempown.cownerid AND cprogcode == tempown.cprogcode
                            m.lprognet = lprognet
                            IF NOT EMPTY(xxsusp.cprogcode)
                                * Get the current setting of lprognet
                                swselect('programs')
                                IF SEEK(xxsusp.cprogcode)
                                    m.lprognet = lprognet
                                ENDIF
                            ENDIF
                            swselect('xxsusp')
                            SCATTER MEMVAR
                            * Store the original run into run_in
                            IF m.nrunno_in = 0
                                m.nrunno_in   = m.nRunNo
                                m.crunyear_in = m.cRunYear
                            ENDIF
                            * Swap the original run with current run
                            m.nRunNo   = THIS.nRunNo
                            m.cRunYear = THIS.cRunYear
                            m.hdate    = THIS.dAcctDate
                            m.ciddisb  = THIS.get_next_key('disbhist')
                            IF EMPTY(m.cSuspType)
                                m.nrunno_in   = 0
                                m.crunyear_in = ''
                            ENDIF
                            INSERT INTO invtmp FROM MEMVAR
                            m.ciddisb = xxsusp.ciddisb
                            INSERT INTO delsusp FROM MEMVAR
                            * Get the well history record corresponding to the owner history
                            THIS.getwellhist(m.cwellid, m.hyear, m.hperiod)
                        ENDSCAN
                    ENDIF
                ENDIF
            ENDSCAN

            THIS.perflog('Suspense: Program Deficits Out', .T.)
            THIS.timekeeper('Ending Program_deficits_out')

            IF RECCOUNT('delsusp') > 0
                DELETE FROM suspense WHERE ciddisb IN (SELECT ciddisb FROM delsusp)
            ENDIF

        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Program_Deficits_Out', loError.LINENO, 'FormName', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)

        RETURN llReturn
        ENDPROC
        **************************************
    PROTECTED PROCEDURE program_suspense_balance
        **************************************
        LPARAMETERS tcOwnerid, tcProgCode
        LOCAL lcAlias, lcRunYear, lnbalance
        LOCAL lnReturn, loError

        lnReturn = 0
        m.goapp.Rushmore(.T., 'Program_Suspense_Balance')

        TRY

            IF m.goapp.lCanceled
                lnReturn = 0
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            lcRunYear = THIS.cRunYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

            lcAlias = ALIAS()

            IF NOT USED('prog_susp_bal')
                * Calculate the suspense balance
                SELECT  cownerid, ;
                        cprogcode, ;
                        SUM(nNetCheck) AS nBalance ;
                    FROM suspense WITH (BUFFERING = .T.) ;
                    WHERE (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                        AND cGroup = THIS.cGroup ;
                    INTO CURSOR prog_susp_bal READWRITE ;
                    ORDER BY cownerid, cprogcode ;
                    GROUP BY cownerid, cprogcode
                INDEX ON cownerid + cprogcode TAG ownerprog
            ENDIF

            SELECT prog_susp_bal
            IF SEEK(tcOwnerid + tcProgCode)
                lnbalance = nBalance
            ELSE
                lnbalance = 0
            ENDIF

            lnReturn = lnbalance

            SELECT(lcAlias)

        CATCH TO loError
            lnReturn = 0
            DO errorlog WITH 'Program_Suspense_Balance', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)

        RETURN lnReturn
        ENDPROC


        ***************************************
    PROCEDURE Owner_Suspense_WellBalance
    ***************************************
    LPARAMETERS tcOwnerid, tcGroup, tlAfterRun, tlIgnoreHoldStatus
    LOCAL lcAlias, lnbalance, lcRunYear
    LOCAL lnReturn, loError

    lnReturn = 0
    m.goapp.Rushmore(.T., 'Owner_Suspense_Wellbalance')

    TRY

        IF m.goapp.lCanceled
            lnReturn = 0
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        THIS.perflog('Suspense: Owner Suspense Balance')
        THIS.timekeeper('Owner Suspense Balance Start')
        lcRunYear = THIS.cRunYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

        THIS.open_files()

        lcAlias = ALIAS()

        lnbalance = 0

        IF NOT tlAfterRun
            * Calculates owner's suspense balance overall before this run
            SELECT  suspense.cownerid, ;
                    suspense.cwellid, ;
                    suspense.cTypeInv, ;
                    SUM(suspense.nNetCheck) AS nBalance ;
                FROM suspense WITH (BUFFERING = .T.) ;
                WHERE suspense.cGroup   == tcGroup ;
                    AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear) ;
                    AND (EMPTY(suspense.cprogcode) ;
                      OR suspense.cprogcode IN (SELECT  cprogcode ;
                                                    FROM programs ;
                                                    WHERE lprognet = .T.)) ;
                    AND IIF(NOT tlIgnoreHoldStatus, suspense.lhold = .F., .T.) ;
                    AND IIF(NOT tlIgnoreHoldStatus, suspense.lonhold = .F., .T.) ;
                INTO CURSOR ownsuspbal1 NOFILTER READWRITE ;
                ORDER BY suspense.cownerid, suspense.cwellid, suspense.cTypeInv ;
                GROUP BY suspense.cownerid, suspense.cwellid, suspense.cTypeInv
            *         INDEX ON cownerid TAG cownerid

            IF tlIgnoreHoldStatus
                SELECT ownsuspbal1
                SCAN
                    m.cownerid = cownerid
                    m.cwellid  = cwellid
                    m.cTypeInv = cTypeInv
                    IF THIS.isonhold(m.cownerid, .T., m.cwellid, m.cTypeInv)
                        SELECT ownsuspbal1
                        DELETE NEXT 1
                    ENDIF
                ENDSCAN
                SELECT  cownerid, ;
                        SUM(nBalance) AS nBalance ;
                    FROM ownsuspbal1 ;
                    INTO CURSOR ownsuspbal READWRITE ;
                    ORDER BY cownerid ;
                    GROUP BY cownerid
                INDEX ON cownerid TAG cownerid
            ENDIF
        ELSE
            * Calculates owner's suspense balance overall after this run
            SELECT  suspense.cownerid, ;
                    suspense.cwellid, ;
                    suspense.cTypeInv, ;
                    SUM(suspense.nNetCheck) AS nBalance ;
                FROM suspense WITH (BUFFERING = .T.) ;
                WHERE suspense.cGroup   == tcGroup ;
                    AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                    AND (EMPTY(suspense.cprogcode) ;
                      OR suspense.cprogcode IN (SELECT  cprogcode ;
                                                    FROM programs ;
                                                    WHERE lprognet = .T.)) ;
                    AND IIF(NOT tlIgnoreHoldStatus, suspense.lhold = .F., .T.) ;
                    AND IIF(NOT tlIgnoreHoldStatus, suspense.lonhold = .F., .T.) ;
                INTO CURSOR ownsuspbal1 READWRITE ;
                ORDER BY suspense.cownerid, suspense.cwellid, suspense.cTypeInv ;
                GROUP BY suspense.cownerid, suspense.cwellid, suspense.cTypeInv
            *         INDEX ON cownerid TAG cownerid

            IF tlIgnoreHoldStatus
                SELECT ownsuspbal1
                SCAN
                    m.cownerid = cownerid
                    m.cwellid  = cwellid
                    m.cTypeInv = cTypeInv
                    IF THIS.isonhold(m.cownerid, .T., m.cwellid, m.cTypeInv)
                        SELECT ownsuspbal1
                        DELETE NEXT 1
                    ENDIF
                ENDSCAN
                SELECT  cownerid, ;
                        SUM(nBalance) AS nBalance ;
                    FROM ownsuspbal1 ;
                    INTO CURSOR ownsuspbal READWRITE ;
                    ORDER BY cownerid ;
                    GROUP BY cownerid
                INDEX ON cownerid TAG cownerid
            ENDIF

        ENDIF

        IF VARTYPE(tcOwnerid) = 'C'
            IF THIS.at_pay_freq(tcOwnerid)
                IF USED('ownsuspbal')
                    SELECT ownsuspbal
                    SET ORDER TO cownerid
                    IF SEEK(tcOwnerid)
                        lnbalance = nBalance
                    ELSE
                        lnbalance = 0
                    ENDIF
                ELSE
                    lnbalance = 0
                ENDIF
            ENDIF
        ELSE
            lnbalance = 0
        ENDIF

        SELECT (lcAlias)
        THIS.perflog('Suspense: Owner Suspense Balance', .T.)
        THIS.timekeeper('Owner Suspense Balance End')
        lnReturn = lnbalance

    CATCH TO loError
        lnReturn = 0
        DO errorlog WITH 'Owner_Suspense_WellBalance', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        *         MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
        'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()
    m.goapp.Rushmore(.F.)

    RETURN lnReturn
    ENDPROC

    ***************************************
    PROCEDURE owner_suspense_balance
    ***************************************
    LPARAMETERS tlByOwner, tcOwnerid, tcGroup, tlAfterRun, tlIgnoreHoldStatus
    LOCAL lcAlias, lnbalance, lcRunYear
    LOCAL lnReturn, loError

    lnReturn = 0
    m.goapp.Rushmore(.T., 'Owner_Suspense_Balance')

    TRY

        IF m.goapp.lCanceled
            lnReturn = 0
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        IF tlByOwner
            lcOrderBy = 'suspense.cownerid'
        ELSE
            lcOrderBy = 'suspense.cownerid, suspense.cwellid, suspense.ctypeinv'
        ENDIF

        THIS.perflog('Suspense: Owner Suspense Balance')
        THIS.timekeeper('Owner Suspense Balance Start')
        lcRunYear = THIS.cRunYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

        THIS.open_files()

        lcAlias = ALIAS()

        lnbalance = 0

        IF NOT tlAfterRun
            * Calculates owner's suspense balance overall before this run
            IF tlIgnoreHoldStatus
                SELECT  suspense.cownerid, ;
                        suspense.cwellid, ;
                        suspense.cTypeInv, ;
                        SUM(suspense.nNetCheck) AS nBalance ;
                    FROM suspense WITH (BUFFERING = .T.) ;
                    WHERE suspense.cGroup   == tcGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear) ;
                        AND (EMPTY(suspense.cprogcode) ;
                          OR suspense.cprogcode IN (SELECT  cprogcode ;
                                                        FROM programs ;
                                                        WHERE lprognet = .T.)) ;
                    INTO CURSOR ownsuspbal NOFILTER READWRITE ;
                    ORDER BY &lcOrderBy ;
                    GROUP BY &lcOrderBy
            ELSE
                SELECT  suspense.cownerid, ;
                        suspense.cwellid, ;
                        suspense.cTypeInv, ;
                        SUM(suspense.nNetCheck) AS nBalance ;
                    FROM suspense WITH (BUFFERING = .T.) ;
                    WHERE suspense.cGroup   == tcGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear) ;
                        AND (EMPTY(suspense.cprogcode) ;
                          OR suspense.cprogcode IN (SELECT  cprogcode ;
                                                        FROM programs ;
                                                        WHERE lprognet = .T.)) ;
                        AND cownerid + cwellid + cTypeInv NOT IN (SELECT  cownerid + cwellid + cTypeInv ;
                                                                      FROM wellinv ;
                                                                      WHERE lonhold) ;
                    INTO CURSOR ownsuspbal NOFILTER READWRITE ;
                    ORDER BY &lcOrderBy ;
                    GROUP BY &lcOrderBy
            ENDIF
        ELSE
            * Calculates owner's suspense balance overall after this run
            IF tlIgnoreHoldStatus
                SELECT  suspense.cownerid, ;
                        suspense.cwellid, ;
                        suspense.cTypeInv, ;
                        SUM(suspense.nNetCheck) AS nBalance ;
                    FROM suspense WITH (BUFFERING = .T.) ;
                    WHERE suspense.cGroup   == tcGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                        AND (EMPTY(suspense.cprogcode) ;
                          OR suspense.cprogcode IN (SELECT  cprogcode ;
                                                        FROM programs ;
                                                        WHERE lprognet = .T.)) ;
                        AND IIF(NOT tlIgnoreHoldStatus, suspense.lhold = .F., .T.) ;
                        AND IIF(NOT tlIgnoreHoldStatus, suspense.lonhold = .F., .T.) ;
                    INTO CURSOR ownsuspbal READWRITE ;
                    ORDER BY &lcOrderBy ;
                    GROUP BY &lcOrderBy
            ELSE
                SELECT  suspense.cownerid, ;
                        suspense.cwellid, ;
                        suspense.cTypeInv, ;
                        SUM(suspense.nNetCheck) AS nBalance ;
                    FROM suspense WITH (BUFFERING = .T.) ;
                    WHERE suspense.cGroup   == tcGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                        AND (EMPTY(suspense.cprogcode) ;
                          OR suspense.cprogcode IN (SELECT  cprogcode ;
                                                        FROM programs ;
                                                        WHERE lprognet = .T.)) ;
                        AND cownerid + cwellid + cTypeInv NOT IN (SELECT  cownerid + cwellid + cTypeInv ;
                                                                      FROM wellinv ;
                                                                      WHERE lonhold) ;
                    INTO CURSOR ownsuspbal READWRITE ;
                    ORDER BY &lcOrderBy ;
                    GROUP BY &lcOrderBy
            ENDIF
        ENDIF

        SELECT ownsuspbal
        INDEX ON cownerid TAG cownerid

        IF VARTYPE(tcOwnerid) = 'C'
            IF THIS.at_pay_freq(tcOwnerid)
                IF USED('ownsuspbal')
                    SELECT ownsuspbal
                    IF SEEK(tcOwnerid)
                        lnbalance = nBalance
                    ELSE
                        lnbalance = 0
                    ENDIF
                ELSE
                    lnbalance = 0
                ENDIF
            ENDIF
        ELSE
            lnbalance = 0
        ENDIF

        SELECT (lcAlias)
        THIS.perflog('Suspense: Owner Suspense Balance', .T.)
        THIS.timekeeper('Owner Suspense Balance End')
        lnReturn = lnbalance

    CATCH TO loError
        lnReturn = 0
        DO errorlog WITH 'Owner_Suspense_Balance', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        *         MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
        'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()
    m.goapp.Rushmore(.F.)

    RETURN lnReturn
    ENDPROC

    ***************************************
    PROCEDURE Owner_Balances
    ***************************************
    LPARAMETERS tcOwnerid, tcGroup, tlAfterRun, tlIncludeHolds, tlIgnoreProgs, tlIgnoreFreq, tlIncludePayments
    LOCAL lcAlias, lnbalance, lnTally, lcRunYear
    LOCAL lnReturn, loError

    lnReturn = 0
    m.goapp.Rushmore(.T., 'Owner_Balances')
    TRY

        IF m.goapp.lCanceled
            lnReturn = .F.
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        lcRunYear = THIS.cRunYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')
        STORE 0 TO lnbalance, lnTally

        THIS.open_files()

        lcAlias = ALIAS()

        IF tlIgnoreFreq
            SELECT  cwellid, ;
                    .F. AS junk ;
                FROM wells ;
                INTO CURSOR tempwells ;
                ORDER BY wells.cwellid
        ELSE
            IF THIS.at_pay_freq(tcOwnerid)
                SELECT  cwellid ;
                    FROM wellinv ;
                    WHERE wellinv.cownerid == tcOwnerid ;
                    INTO CURSOR tempwells ;
                    ORDER BY wellinv.cwellid ;
                    GROUP BY wellinv.cwellid
            ENDIF
        ENDIF

        IF NOT tlAfterRun
            IF tlIncludeHolds
                IF NOT tlIgnoreProgs
                    * Calculates owner's suspense balance overall before this run
                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM suspense WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear) ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND (cprogcode = SPACE(10) ;
                              OR cprogcode IN (SELECT  cprogcode ;
                                                   FROM programs ;
                                                   WHERE lprognet = .T.)) ;
                            AND suspense.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance1

                    lnTally = _TALLY

                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM disbhist WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') >= lcRunYear) ;
                            AND disbhist.nRunNo # 9999 ;
                            AND ((disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') < lcRunYear) ;
                              AND disbhist.nrunno_in # 0 ) ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND (cprogcode = SPACE(10) ;
                              OR cprogcode IN (SELECT  cprogcode ;
                                                   FROM programs ;
                                                   WHERE lprognet = .T.)) ;
                            AND disbhist.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance2
                    lnTally = lnTally + _TALLY



                    IF THIS.lNewRun
                        SELECT  SUM(nNetCheck) AS nBalance ;
                            FROM invtmp WITH (BUFFERING = .T.) ;
                            WHERE cownerid == tcOwnerid ;
                                AND cGroup   == tcGroup ;
                                AND (invtmp.cRunYear + PADL(TRANSFORM(invtmp.nRunNo), 3, '0') >= lcRunYear) ;
                                AND ((invtmp.crunyear_in + PADL(TRANSFORM(invtmp.nrunno_in), 3, '0') < lcRunYear) ;
                                  AND invtmp.nrunno_in # 0 ) ;
                                AND (cprogcode = SPACE(10) ;
                                  OR cprogcode IN (SELECT  cprogcode ;
                                                       FROM programs ;
                                                       WHERE lprognet = .T.)) ;
                                AND invtmp.cwellid IN (SELECT  cwellid ;
                                                           FROM tempwells) ;
                                AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            INTO CURSOR tempbalance3
                        lnTally = lnTally + _TALLY
                    ENDIF
                ELSE
                    * Calculates owner's suspense balance overall before this run
                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM suspense WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND   cGroup   == tcGroup ;
                            AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear) ;
                            AND suspense.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                        INTO CURSOR tempbalance1

                    lnTally = _TALLY

                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM disbhist WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND ((disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') < lcRunYear) ;
                              AND  disbhist.nrunno_in # 0 ) ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') >= lcRunYear) ;
                            AND disbhist.nRunNo # 9999 ;
                            AND disbhist.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance2
                    lnTally = lnTally + _TALLY

                    IF THIS.lNewRun
                        SELECT  SUM(nNetCheck) AS nBalance ;
                            FROM invtmp WITH (BUFFERING = .T.) ;
                            WHERE cownerid == tcOwnerid ;
                                AND cGroup   == tcGroup ;
                                AND (invtmp.cRunYear + PADL(TRANSFORM(invtmp.nRunNo), 3, '0') >= lcRunYear) ;
                                AND ((invtmp.crunyear_in + PADL(TRANSFORM(invtmp.nrunno_in), 3, '0') < lcRunYear) ;
                                  AND invtmp.nrunno_in # 0 ) ;
                                AND invtmp.cwellid IN (SELECT  cwellid ;
                                                           FROM tempwells) ;
                                AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            INTO CURSOR tempbalance3
                        lnTally = lnTally + _TALLY
                    ENDIF

                ENDIF

                lnTally = lnTally + _TALLY
            ELSE
                IF NOT tlIgnoreProgs
                    * Calculates owner's suspense balance overall before this run
                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM suspense WITH (BUFFERING = .T.) ;
                        WHERE (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear) ;
                            AND cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND suspense.lonhold = .F. ;
                            AND suspense.lhold = .F. ;
                            AND (cprogcode = SPACE(10) ;
                              OR cprogcode IN (SELECT  cprogcode ;
                                                   FROM programs ;
                                                   WHERE lprognet = .T.)) ;
                            AND suspense.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance1

                    lnTally = _TALLY

                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM disbhist WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND ((disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') <= lcRunYear) ;
                              AND (disbhist.nrunno_in # 0 ;
                                AND disbhist.crunyear_in # SPACE(4))) ;
                            AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') >= lcRunYear) ;
                            AND disbhist.nRunNo # 9999 ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND disbhist.lonhold = .F. ;
                            AND disbhist.lhold = .F. ;
                            AND (cprogcode = SPACE(10) ;
                              OR cprogcode IN (SELECT  cprogcode ;
                                                   FROM programs ;
                                                   WHERE lprognet = .T.)) ;
                            AND disbhist.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance2
                    lnTally = lnTally + _TALLY

                    IF THIS.lNewRun
                        SELECT  SUM(nNetCheck) AS nBalance ;
                            FROM invtmp WITH (BUFFERING = .T.) ;
                            WHERE cownerid == tcOwnerid ;
                                AND cGroup   == tcGroup ;
                                AND (invtmp.cRunYear + PADL(TRANSFORM(invtmp.nRunNo), 3, '0') >= lcRunYear) ;
                                AND ((invtmp.crunyear_in + PADL(TRANSFORM(invtmp.nrunno_in), 3, '0') <= lcRunYear) ;
                                  AND invtmp.nrunno_in # 0 ) ;
                                AND (cprogcode = SPACE(10) ;
                                  OR cprogcode IN (SELECT  cprogcode ;
                                                       FROM programs ;
                                                       WHERE lprognet = .T.)) ;
                                AND invtmp.cwellid IN (SELECT  cwellid ;
                                                           FROM tempwells) ;
                                AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            INTO CURSOR tempbalance3
                        lnTally = lnTally + _TALLY
                    ENDIF

                ELSE
                    * Calculates owner's suspense balance overall before this run
                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM suspense WITH (BUFFERING = .T.) ;
                        WHERE (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear) ;
                            AND cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND suspense.lonhold = .F. ;
                            AND suspense.lhold = .F. ;
                            AND suspense.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                        INTO CURSOR tempbalance1

                    lnTally = _TALLY

                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM disbhist WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND ((disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') <= lcRunYear) ;
                              AND (disbhist.nrunno_in # 0 ;
                                AND disbhist.crunyear_in # SPACE(4))) ;
                            AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') >= lcRunYear) ;
                            AND disbhist.nRunNo # 9999 ;
                            AND disbhist.lonhold = .F. ;
                            AND disbhist.lhold = .F. ;
                            AND disbhist.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                        INTO CURSOR tempbalance2

                    lnTally = lnTally + _TALLY
                    IF THIS.lNewRun
                        SELECT  SUM(nNetCheck) AS nBalance ;
                            FROM invtmp WITH (BUFFERING = .T.) ;
                            WHERE cownerid == tcOwnerid ;
                                AND cGroup   == tcGroup ;
                                AND (invtmp.cRunYear + PADL(TRANSFORM(invtmp.nRunNo), 3, '0') >= lcRunYear) ;
                                AND ((invtmp.crunyear_in + PADL(TRANSFORM(invtmp.nrunno_in), 3, '0') <= lcRunYear) ;
                                  AND invtmp.nrunno_in # 0 ) ;
                                AND invtmp.cwellid IN (SELECT  cwellid ;
                                                           FROM tempwells) ;
                                AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            INTO CURSOR tempbalance3
                        lnTally = lnTally + _TALLY
                    ENDIF

                ENDIF

                lnTally = lnTally + _TALLY
            ENDIF

            SELECT tempbalance1
            lnbalance = tempbalance1.nBalance
            swclose('tempbalance1')

            SELECT tempbalance2
            lnbalance = lnbalance + tempbalance2.nBalance
            swclose('tempbalance2')

            IF THIS.lNewRun
                lnbalance = lnbalance + tempbalance3.nBalance
                swclose('tempbalance3')
            ENDIF

        ELSE
            IF tlIncludeHolds
                IF NOT tlIgnoreProgs
                    * Calculates owner's suspense balance overall after this run
                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM suspense WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND (cprogcode = SPACE(10) ;
                              OR cprogcode IN (SELECT  cprogcode ;
                                                   FROM programs ;
                                                   WHERE lprognet = .T.)) ;
                            AND suspense.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance1

                    lnTally = _TALLY

                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM disbhist WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND ((crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                              AND disbhist.nrunno_in # 0 ) ;
                            AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') > lcRunYear) ;
                            AND disbhist.nRunNo # 9999 ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND (cprogcode = SPACE(10) ;
                              OR cprogcode IN (SELECT  cprogcode ;
                                                   FROM programs ;
                                                   WHERE lprognet = .T.)) ;
                            AND disbhist.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance2
                    lnTally = lnTally + _TALLY

                    IF THIS.lNewRun
                        SELECT  SUM(nNetCheck) AS nBalance ;
                            FROM invtmp WITH (BUFFERING = .T.) ;
                            WHERE cownerid == tcOwnerid ;
                                AND cGroup   == tcGroup ;
                                AND ((crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                                  AND invtmp.nrunno_in # 0 ) ;
                                AND (invtmp.cRunYear + PADL(TRANSFORM(invtmp.nRunNo), 3, '0') > lcRunYear) ;
                                AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                                AND (cprogcode = SPACE(10) ;
                                  OR cprogcode IN (SELECT  cprogcode ;
                                                       FROM programs ;
                                                       WHERE lprognet = .T.)) ;
                                AND invtmp.cwellid IN (SELECT  cwellid ;
                                                           FROM tempwells) ;
                            INTO CURSOR tempbalance3
                        lnTally = lnTally + _TALLY
                    ENDIF
                ELSE
                    * Calculates owner's suspense balance overall after this run
                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM suspense WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND suspense.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance1

                    lnTally = _TALLY

                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM disbhist WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND ((crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                              AND disbhist.nrunno_in # 0 ) ;
                            AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') > lcRunYear) ;
                            AND disbhist.nRunNo # 9999 ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND disbhist.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance2

                    lnTally = lnTally + _TALLY

                    IF THIS.lNewRun
                        SELECT  SUM(nNetCheck) AS nBalance ;
                            FROM invtmp WITH (BUFFERING = .T.) ;
                            WHERE cownerid == tcOwnerid ;
                                AND cGroup   == tcGroup ;
                                AND ((crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                                  AND invtmp.nrunno_in # 0 ) ;
                                AND (invtmp.cRunYear + PADL(TRANSFORM(invtmp.nRunNo), 3, '0') > lcRunYear) ;
                                AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                                AND invtmp.cwellid IN (SELECT  cwellid ;
                                                           FROM tempwells) ;
                            INTO CURSOR tempbalance3
                        lnTally = lnTally + _TALLY
                    ENDIF

                ENDIF

            ELSE
                IF NOT tlIgnoreProgs
                    * Calculates owner's suspense balance overall after this run
                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM suspense WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                            AND suspense.lonhold = .F. ;
                            AND suspense.lhold = .F. ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND (cprogcode = SPACE(10) ;
                              OR cprogcode IN (SELECT  cprogcode ;
                                                   FROM programs ;
                                                   WHERE lprognet = .T.)) ;
                            AND suspense.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                        INTO CURSOR tempbalance1

                    lnTally = _TALLY

                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM disbhist WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND ((crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                              AND  disbhist.nrunno_in # 0 ) ;
                            AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') > lcRunYear) ;
                            AND disbhist.nRunNo # 9999 ;
                            AND disbhist.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                            AND disbhist.lonhold = .F. ;
                            AND disbhist.lhold = .F. ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND (cprogcode = SPACE(10) ;
                              OR cprogcode IN (SELECT  cprogcode ;
                                                   FROM programs ;
                                                   WHERE lprognet = .T.)) ;
                        INTO CURSOR tempbalance2
                    lnTally = lnTally + _TALLY

                    IF THIS.lNewRun
                        SELECT  SUM(nNetCheck) AS nBalance ;
                            FROM invtmp WITH (BUFFERING = .T.) ;
                            WHERE cownerid == tcOwnerid ;
                                AND cGroup   == tcGroup ;
                                AND ((crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                                  AND invtmp.nrunno_in # 0 ) ;
                                AND (invtmp.cRunYear + PADL(TRANSFORM(invtmp.nRunNo), 3, '0') > lcRunYear) ;
                                AND (cprogcode = SPACE(10) ;
                                  OR cprogcode IN (SELECT  cprogcode ;
                                                       FROM programs ;
                                                       WHERE lprognet = .T.)) ;
                                AND invtmp.lonhold = .F. ;
                                AND invtmp.lhold = .F. ;
                                AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                                AND invtmp.cwellid IN (SELECT  cwellid ;
                                                           FROM tempwells) ;
                            INTO CURSOR tempbalance3
                        lnTally = lnTally + _TALLY
                    ENDIF

                ELSE
                    * Calculates owner's suspense balance overall after this run
                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM suspense WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND suspense.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                            AND suspense.lonhold = .F. ;
                            AND suspense.lhold = .F. ;
                        INTO CURSOR tempbalance1

                    lnTally = _TALLY

                    SELECT  SUM(nNetCheck) AS nBalance ;
                        FROM disbhist WITH (BUFFERING = .T.) ;
                        WHERE cownerid == tcOwnerid ;
                            AND cGroup   == tcGroup ;
                            AND ((crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                              AND  disbhist.nrunno_in # 0 ) ;
                            AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') > lcRunYear) ;
                            AND disbhist.nRunNo # 9999 ;
                            AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                            AND disbhist.cwellid IN (SELECT  cwellid ;
                                                         FROM tempwells) ;
                            AND disbhist.lonhold = .F. ;
                            AND disbhist.lhold = .F. ;
                        INTO CURSOR tempbalance2

                    lnTally = lnTally + _TALLY

                    IF THIS.lNewRun
                        SELECT  SUM(nNetCheck) AS nBalance ;
                            FROM invtmp WITH (BUFFERING = .T.) ;
                            WHERE cownerid == tcOwnerid ;
                                AND cGroup   == tcGroup ;
                                AND ((crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                                  AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                                  AND invtmp.nrunno_in # 0 ) ;
                                AND (invtmp.cRunYear + PADL(TRANSFORM(invtmp.nRunNo), 3, '0') > lcRunYear) ;
                                AND invtmp.lonhold = .F. ;
                                AND invtmp.lhold = .F. ;
                                AND invtmp.cwellid IN (SELECT  cwellid ;
                                                           FROM tempwells) ;
                            INTO CURSOR tempbalance3
                        lnTally = lnTally + _TALLY
                    ENDIF
                ENDIF
            ENDIF

            SELECT tempbalance1
            lnbalance = tempbalance1.nBalance
            swclose('tempbalance1')

            SELECT tempbalance2
            lnbalance = lnbalance + tempbalance2.nBalance
            swclose('tempbalance2')
            IF THIS.lNewRun
                lnbalance = lnbalance + tempbalance3.nBalance
                swclose('tempbalance3')
            ENDIF
        ENDIF

        SELECT (lcAlias)

        IF lnTally = 0
            lnbalance = 0
        ENDIF

        lnReturn = lnbalance

    CATCH TO loError
        lnReturn = 0
        DO errorlog WITH 'Owner_Balances', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        *         MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
        'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()
    m.goapp.Rushmore(.F.)

    RETURN lnReturn

    ENDPROC
    **************************************
    PROCEDURE owner_current_balance
        **************************************
        LPARAMETERS tcOwnerid, tlIncludeProgs
        LOCAL lcAlias, lnbalance, lnReturn, loError

        lnReturn = 0
        m.goapp.Rushmore(.T., 'Owner_Current_Balance')

        TRY

            IF m.goapp.lCanceled
                lnReturn = 0
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            lnbalance = 0
            lcAlias   = ALIAS()

            IF NOT tlIncludeProgs
                SELECT  invtmp.cownerid, ;
                        SUM(invtmp.nNetCheck) AS nBalance ;
                    FROM invtmp WITH (BUFFERING = .T.) ;
                    WHERE (cprogcode = SPACE(10) ;
                          OR cprogcode IN (SELECT  cprogcode ;
                                               FROM programs ;
                                               WHERE lprognet = .T.)) ;
                        AND invtmp.cownerid NOT IN (SELECT  cownerid ;
                                                        FROM investor ;
                                                        WHERE IIF(NOT m.goapp.lAMVersion ;
                                                              AND NOT m.goapp.lQBVersion, .F., investor.lIntegGl = .T.) ;
                                                            OR investor.lDummy = .T.) ;
                    INTO CURSOR owncurbal READWRITE ;
                    ORDER BY cownerid ;
                    GROUP BY cownerid
            ELSE
                SELECT  cownerid, ;
                        SUM(nNetCheck) AS nBalance ;
                    FROM invtmp WITH (BUFFERING = .T.) ;
                    INTO CURSOR owncurbal READWRITE ;
                    WHERE invtmp.cownerid NOT IN (SELECT  cownerid ;
                                                      FROM investor ;
                                                      WHERE IIF(NOT m.goapp.lAMVersion ;
                                                            AND NOT m.goapp.lQBVersion, .F., investor.lIntegGl = .T.) ;
                                                          OR investor.lDummy = .T.) ;
                    ORDER BY cownerid ;
                    GROUP BY cownerid
            ENDIF
            INDEX ON cownerid TAG cownerid

            IF VARTYPE(tcOwnerid) = 'C'
                SELECT owncurbal
                SET ORDER TO cownerid
                IF SEEK(tcOwnerid)
                    lnbalance = nBalance
                ELSE
                    lnbalance = 0
                ENDIF
            ENDIF

            SELECT (lcAlias)

            lnReturn = lnbalance

        CATCH TO loError
            lnReturn = 0
            DO errorlog WITH 'Owner_Current_Balance', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            *         MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)

        RETURN lnReturn

        ENDPROC
        *************************************
    PROTECTED PROCEDURE program_current_balance
        *************************************
        LPARAMETERS tcOwnerid, tcProgCode
        LOCAL lcAlias, lnbalance, lnReturn, loError

        lnReturn = 0
        m.goapp.Rushmore(.T., 'Program_Current_Balance')

        TRY

            IF m.goapp.lCanceled
                lnReturn = 0
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            lcAlias = ALIAS()

            IF NOT USED('prog_current_bal')
                SELECT  cownerid, ;
                        cprogcode, ;
                        SUM(nNetCheck) AS nBalance ;
                    FROM invtmp ;
                    INTO CURSOR prog_current_bal READWRITE ;
                    ORDER BY cownerid, cprogcode ;
                    GROUP BY cownerid, cprogcode
                INDEX ON cownerid + cprogcode TAG ownerprog
            ENDIF

            SELECT prog_current_bal
            IF SEEK(tcOwnerid + tcProgCode)
                lnbalance = nBalance
            ELSE
                lnbalance = 0
            ENDIF

            lnReturn = lnbalance

            SELECT (lcAlias)

        CATCH TO loError
            lnReturn = 0
            DO errorlog WITH 'Program_Current_Balance', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        ENDTRY

        THIS.CheckCancel()
        m.goapp.Rushmore(.F.)

        RETURN lnReturn

        ENDPROC

        ***************************
    PROTECTED FUNCTION at_pay_freq
        ***************************
        LPARAMETERS tcOwnerid, tnDisbFreq
        LOCAL llReturn, loError

        llReturn = .T.

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            IF THIS.lNoPayFreqs
                * Already checked and there are no pay frequencies other than monthly
                llReturn = .T.
                EXIT
            ENDIF

            * Temporary measure till we decide if passing the freq is ok
            tnDisbFreq = .F.

            IF VARTYPE(tnDisbFreq) # 'N'
                * Disbfreq was not passed as a param so look it up in the owner file
                swselect('investor')
                SET ORDER TO cownerid
                IF SEEK(tcOwnerid)
                    tnDisbFreq = ndisbfreq
                ELSE
                    llReturn = .F.
                    EXIT
                ENDIF
            ENDIF

            DO CASE
                CASE tnDisbFreq = 1 OR tnDisbFreq = 0
                    llReturn = .T.
                    EXIT
                CASE tnDisbFreq = 2
                    IF INLIST(MONTH(THIS.dAcctDate), 3, 6, 9, 12)
                        llReturn = .T.
                        EXIT
                    ELSE
                        llReturn = .F.
                        EXIT
                    ENDIF

                CASE tnDisbFreq = 3
                    IF INLIST(MONTH(THIS.dAcctDate), 6, 12)
                        llReturn = .T.
                        EXIT
                    ELSE
                        llReturn = .F.
                        EXIT
                    ENDIF

                CASE tnDisbFreq = 4
                    IF INLIST(MONTH(THIS.dAcctDate), 12)
                        llReturn = .T.
                        EXIT
                    ELSE
                        llReturn = .F.
                        EXIT
                    ENDIF

                OTHERWISE
                    llReturn = .F.

            ENDCASE

        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'At_Pay_Freq', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            *         MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()

        RETURN llReturn

        ENDFUNC

        ****************************
    PROCEDURE getlasttype
    ****************************
    LPARAMETERS tlAfterRun, tlIncHolds, tcGroup, tlForce, tlNoBlankPrograms, tlIncludePayments
    LOCAL llGroup, lcRunYear, lcTable, llReturn, loError, m.cSuspType, m.cownerid, m.cwellid

    llReturn = .F.
    m.goapp.Rushmore(.T., 'GetLastType')

    TRY

        IF m.goapp.lCanceled
            llReturn          = .F.
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        IF EMPTY(THIS.cBegOwner)
            swselect('investor')
            SET ORDER TO cownerid
            GO TOP
            THIS.cBegOwner = cownerid
            GO BOTT
            THIS.cEndOwner = cownerid
        ENDIF

        IF THIS.nRunNo = 0
            THIS.lNewRun = .T.
            THIS.nRunNo  = getrunno(THIS.cRunYear, .T., 'R')
        ENDIF

        DO CASE
            CASE tlAfterRun AND tlIncHolds
                lcTable = 'lastsusp1'
            CASE tlAfterRun AND NOT tlIncHolds
                lcTable = 'lastsusp2'
            CASE NOT tlAfterRun AND tlIncHolds
                lcTable = 'lastsusp3'
            CASE NOT tlAfterRun AND NOT tlIncHolds
                lcTable = 'lastsusp4'
        ENDCASE

        swclose('curlastsusptype')
        swselect('suspense')
        swselect('disbhist')

        * Check to see if we're getting the last type for a particular group
        llGroup = VARTYPE(tcGroup) = 'C'

        * Don't create the curlastsusptype cursor again if we don't need to.
        IF USED(lcTable) AND (llGroup AND NOT tlForce)
            USE DBF(lcTable) AGAIN IN 0 ALIAS CurLastSuspType
            llReturn = .T.
            EXIT
        ENDIF

        *!*          THIS.perflog('Suspense: GetLastType')
        *!*          THIS.timekeeper('Starting getlasttype')

        lcRunYear = THIS.cRunYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

        * Set the where parameters for before run or after run
        IF tlAfterRun
            lcWhereS = 'suspense.crunyear_in+PADL(TRANSFORM(suspense.nrunno_in),3,"0") <= lcRunYear'
            lcWhereD = 'disbhist.crunyear_in+PADL(TRANSFORM(disbhist.nrunno_in),3,"0") <= lcRunYear'
        ELSE
            lcWhereS = 'suspense.crunyear_in+PADL(TRANSFORM(suspense.nrunno_in),3,"0") < lcRunYear'
            lcWhereD = 'disbhist.crunyear_in+PADL(TRANSFORM(disbhist.nrunno_in),3,"0") < lcRunYear'
        ENDIF

        * Set the where expression for holds
        IF NOT tlIncHolds
            lcWhereHS = 'lHold=.F. AND lOnHold=.F.'
            lcWhereHD = 'lHold=.F. AND lOnHold=.F.'
        ELSE
            lcWhereHS = '.T.'
            lcWhereHD = '.T.'
        ENDIF

        *****************************************************
        *  SHOULD NET PROGRAMS HAVE THE PROGCODE IN SUSPENSE????
        *****************************************************

        IF NOT tlAfterRun

            * Get the last suspense entry for each well
            SELECT  suspense.cwellid, ;
                    suspense.cownerid, ;
                    suspense.cTypeInv, ;
                    suspense.cprogcode, ;
                    crunyear_in, ;
                    nrunno_in, ;
                    MAX(crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0')) AS cRunYear ;
                FROM suspense ;
                WHERE &lcWhereHS ;
                    AND &lcWhereS ;
                    AND BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND IIF(llGroup, cGroup == tcGroup, .T.) ;
                    AND IIF(NOT tlIncludePayments, suspense.crectype # 'P', .T.) ;
                GROUP BY suspense.cownerid, suspense.cwellid, suspense.cTypeInv, suspense.cprogcode ;
                ORDER BY suspense.cownerid, suspense.cwellid, suspense.cTypeInv, suspense.cprogcode ;
                INTO CURSOR temp0 READWRITE

            SELECT  suspense.cwellid, ;
                    suspense.cownerid, ;
                    suspense.cTypeInv, ;
                    suspense.cSuspType, ;
                    suspense.cprogcode, ;
                    temp0.cRunYear ;
                FROM suspense ;
                JOIN temp0 ;
                    ON suspense.cwellid = temp0.cwellid ;
                    AND suspense.cownerid = temp0.cownerid ;
                    AND suspense.cTypeInv = temp0.cTypeInv ;
                    AND suspense.crunyear_in + PADL(TRANSFORM(suspense.nrunno_in), 3, '0') == temp0.cRunYear ;
                    AND IIF(NOT tlIncludePayments, suspense.crectype # 'P', .T.) ;
                INTO CURSOR temp1 READWRITE ;
                GROUP BY suspense.cwellid, suspense.cownerid, suspense.cTypeInv, suspense.cprogcode, temp0.cRunYear

*                     AND NOT EMPTY(suspense.cSuspType) ;

            SELECT  disbhist.cwellid, ;
                    disbhist.cownerid, ;
                    disbhist.cTypeInv, ;
                    disbhist.cprogcode, ;
                    crunyear_in, ;
                    nrunno_in, ;
                    MAX(crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0')) AS cRunYear ;
                FROM disbhist ;
                WHERE &lcWhereHD ;
                    AND IIF(llGroup, cGroup == tcGroup, .T.) ;
                    AND &lcWhereD ;
                    AND BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND ((disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') >= lcRunYear) ;
                      AND disbhist.nRunNo # 9999) ;
                    AND disbhist.nrunno_in # 0 ;
                    AND disbhist.crunyear_in # ' ' ;
                    AND IIF(NOT tlIncludePayments, suspense.crectype # 'P', .T.) ;
                GROUP BY disbhist.cownerid, disbhist.cwellid, disbhist.cTypeInv, cprogcode ;
                ORDER BY disbhist.cownerid, disbhist.cwellid, disbhist.cTypeInv, cprogcode ;
                INTO CURSOR temp0 READWRITE

            SELECT  disbhist.cwellid, ;
                    disbhist.cownerid, ;
                    disbhist.cTypeInv, ;
                    disbhist.cSuspType, ;
                    disbhist.cprogcode, ;
                    temp0.cRunYear ;
                FROM disbhist ;
                JOIN temp0 ;
                    ON disbhist.cwellid = temp0.cwellid ;
                    AND disbhist.cownerid = temp0.cownerid ;
                    AND disbhist.cTypeInv = temp0.cTypeInv ;
                    AND disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') == temp0.cRunYear ;
                    AND IIF(NOT tlIncludePayments, suspense.crectype # 'P', .T.) ;
                    AND disbhist.cSuspType # ' ' ;
                INTO CURSOR temp2 READWRITE ;
                GROUP BY disbhist.cwellid, disbhist.cownerid, disbhist.cTypeInv, disbhist.cprogcode, temp0.cRunYear

        ELSE

            CREATE CURSOR tempsusp1 ;
                (cownerid     c(10), ;
                  cwellid      c(10), ;
                  cprogcode    c(10), ;
                  cGroup       c(2), ;
                  cTypeInv     c(1), ;
                  cSuspType    c(1), ;
                  cRunYear     c(7), ;
                  crunyear_in  c(4), ;
                  nrunno_in    i)

            * Get a temp cursor of suspense from this run and earlier
            swselect('suspense')
            SELECT  * ;
                FROM suspense WITH (BUFFERING = .T.) ;
                WHERE &lcWhereHS ;
                    AND BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND suspense.crunyear_in + PADL(TRANSFORM(suspense.nrunno_in), 3, "0") <= lcRunYear ;
                    AND IIF(NOT tlIncludePayments, crectype # 'P', .T.) ;
                INTO CURSOR xxsusp

            IF USED('xxsusp')
                SELECT tempsusp1
                APPEND FROM DBF('xxsusp')
            ENDIF

            SELECT tempsusp1
            INDEX ON cownerid TAG cownerid
            INDEX ON cwellid TAG cwellid
            INDEX ON cTypeInv TAG cTypeInv
            INDEX ON crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') TAG cRunYear

            * Get the last suspense entry for each well
            SELECT  tempsusp1.cwellid, ;
                    tempsusp1.cownerid, ;
                    tempsusp1.cTypeInv, ;
                    tempsusp1.cprogcode, ;
                    tempsusp1.crunyear_in, ;
                    tempsusp1.nrunno_in, ;
                    MAX(crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0')) AS cRunYear ;
                FROM tempsusp1 ;
                WHERE BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND IIF(llGroup, cGroup == tcGroup, .T.) ;
                GROUP BY tempsusp1.cownerid, tempsusp1.cwellid, tempsusp1.cTypeInv, cprogcode ;
                ORDER BY tempsusp1.cownerid, tempsusp1.cwellid, tempsusp1.cTypeInv, cprogcode ;
                INTO CURSOR temp0 READWRITE

            * Make sure each owner and well combination had the same last type on them
            SELECT  tempsusp1.cwellid, ;
                    tempsusp1.cownerid, ;
                    tempsusp1.cTypeInv, ;
                    tempsusp1.cSuspType, ;
                    tempsusp1.cprogcode, ;
                    temp0.cRunYear ;
                FROM tempsusp1 ;
                JOIN temp0 ;
                    ON tempsusp1.cwellid = temp0.cwellid ;
                    AND tempsusp1.cownerid = temp0.cownerid ;
                    AND tempsusp1.cTypeInv = temp0.cTypeInv ;
                    AND tempsusp1.crunyear_in + PADL(TRANSFORM(tempsusp1.nrunno_in), 3, '0') == temp0.cRunYear ;
                INTO CURSOR temp1 READWRITE

            CREATE CURSOR tempdisb1 ;
                (cownerid     c(10), ;
                  cwellid      c(10), ;
                  cprogcode    c(10), ;
                  cTypeInv     c(1), ;
                  cSuspType    c(1), ;
                  cGroup       c(2), ;
                  cRunYear     c(7), ;
                  nRunNo       i, ;
                  crunyear_in  c(4), ;
                  nrunno_in    i)

            IF NOT THIS.lNewRun
                swselect('disbhist')
                SELECT  * ;
                    FROM disbhist WITH (BUFFERING = .T.) ;
                    WHERE BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                        AND crunyear_in + PADL(TRANSFORM(nrunno_in), 3, "0") <= lcRunYear ;
                        AND nrunno_in # 0 ;
                        AND crunyear_in # ' ' ;
                        AND (cRunYear + PADL(TRANSFORM(nRunNo), 3, '0') > lcRunYear ;
                          AND nRunNo # 9999 ) ;
                    INTO CURSOR xxsusp2
                SELECT tempdisb1
                APPEND FROM DBF('xxsusp2')
                swclose('xxsusp2')
            ELSE
                IF USED('invtmp')
                    SELECT invtmp
                    SELECT  * ;
                        FROM invtmp ;
                        WHERE BETWEEN(cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                            AND crunyear_in + PADL(TRANSFORM(nrunno_in), 3, "0") = lcRunYear ;
                            AND nrunno_in # 0 ;
                            AND crunyear_in # ' ' ;
                        INTO CURSOR xxsusp3
                    SELECT tempdisb1
                    APPEND FROM DBF('xxsusp3')
                    swclose('xxsusp3')
                ENDIF
            ENDIF

            SELECT tempdisb1
            INDEX ON cownerid TAG cownerid
            INDEX ON cwellid TAG cwellid
            INDEX ON cTypeInv TAG cTypeInv
            INDEX ON crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') TAG cRunYear

            SELECT  tempdisb1.cwellid, ;
                    tempdisb1.cownerid, ;
                    tempdisb1.cTypeInv, ;
                    tempdisb1.cprogcode, ;
                    crunyear_in, ;
                    nrunno_in, ;
                    MAX(crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0')) AS cRunYear ;
                FROM tempdisb1 ;
                WHERE &lcWhereHD ;
                    AND IIF(llGroup, cGroup == tcGroup, .T.) ;
                GROUP BY cownerid, cwellid, cTypeInv, cprogcode ;
                ORDER BY cownerid, cwellid, cTypeInv, cprogcode ;
                INTO CURSOR temp0 READWRITE

            SELECT  tempdisb1.cwellid, ;
                    tempdisb1.cownerid, ;
                    tempdisb1.cTypeInv, ;
                    tempdisb1.cSuspType, ;
                    tempdisb1.cprogcode, ;
                    temp0.cRunYear ;
                FROM tempdisb1 ;
                JOIN temp0 ;
                    ON tempdisb1.cwellid = temp0.cwellid ;
                    AND tempdisb1.cownerid = temp0.cownerid ;
                    AND tempdisb1.cTypeInv = temp0.cTypeInv ;
                    AND tempdisb1.crunyear_in + PADL(TRANSFORM(tempdisb1.nrunno_in), 3, '0') == temp0.cRunYear ;
                INTO CURSOR temp2 READWRITE

        ENDIF

        SELECT temp1
        APPEND FROM DBF('temp2')
        SELECT  temp1.cwellid, ;
                temp1.cownerid, ;
                temp1.cTypeInv, ;
                cprogcode, ;
                temp1.cSuspType, ;
                MAX(cRunYear) AS cRunYear ;
            FROM temp1 ;
            GROUP BY cownerid, cwellid, cTypeInv, cprogcode ;
            ORDER BY cownerid, cwellid, cTypeInv, cprogcode ;
            INTO CURSOR curLastSuspType1 READWRITE


        * Blank out any programs that net
        IF NOT tlNoBlankPrograms
            SELECT curLastSuspType1
            SCAN FOR NOT EMPTY(cprogcode)
                m.cprogcode = cprogcode
                swselect("programs")
                SET ORDER TO cprogcode
                IF SEEK(m.cprogcode)
                    IF lprognet
                        SELECT curLastSuspType1
                        REPLACE cprogcode WITH ''
                    ENDIF
                ENDIF
            ENDSCAN
        ENDIF

        SELECT  cwellid, ;
                cownerid, ;
                cTypeInv, ;
                cprogcode, ;
                cSuspType, ;
                cRunYear ;
            FROM curLastSuspType1 ;
            GROUP BY cownerid, cwellid, cTypeInv, cprogcode ;
            ORDER BY cownerid, cwellid, cTypeInv, cprogcode ;
            INTO CURSOR (lcTable) READWRITE
        
        

        swclose('temp0')
        swclose('temp1')
        swclose('temp2')
        swclose('tempdisb1')

        USE DBF(lcTable) AGAIN IN 0 ALIAS CurLastSuspType
        SELECT CurLastSuspType
        INDEX ON cownerid + cwellid + cRunYear DESC TAG ownerwell
        INDEX on cwellid TAG cwellid
        INDEX on cownerid TAG cownerid
        INDEX on ctypeinv TAG ctypeinv
        INDEX on csusptype TAG csusptype
        INDEX on crunyear TAG crunyear
        INDEX on cprogcode TAG cprogcode
        INDEX on cownerid+cwellid+ctypeinv+cprogcode TAG pk

    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'GetLastType', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()
    m.goapp.Rushmore(.F.)

    RETURN llReturn

    ENDPROC

    ****************************
    PROCEDURE GetBalTransfer
    ****************************
    LPARAMETERS tcType, tlByOwner, tlUseOld
    LOCAL lnTotal, lnReturn, loError

    lnReturn = 0
    m.goapp.Rushmore(.T., 'GetBalTransfer')

    TRY

        IF m.goapp.lCanceled
            llReturn          = .F.
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        lnseconds1 = SECONDS()
        THIS.perflog('Suspense: GetBalTransfer')
        * Gets the amount of balance transfer during a run closing
        * Transfers between minimum and deficits are tallied

        * Get the suspense types before this run
        THIS.perflog('GetBalTransfer 1: GetLastType')
        THIS.getlasttype(.F., .T., THIS.cGroup, .T.)
        THIS.perflog('GetBalTransfer 1: GetLastType', .T.)

        * Get the suspense types before the run was closed into a cursor beforerun
        SELECT * FROM CurLastSuspType WHERE NOT EMPTY(cwellid) INTO CURSOR beforerun READWRITE
        SELECT beforerun
        INDEX ON cwellid TAG cwellid
        INDEX ON cownerid TAG cownerid
        INDEX ON cSuspType TAG cSuspType
        INDEX ON cTypeInv  TAG cTypeInv
        INDEX ON cownerid + cwellid TAG ownerwell


        * Get the suspense types after this run
        THIS.perflog('GetBalTransfer 2: GetLastType')
        THIS.getlasttype(.T., .T., THIS.cGroup, .T.)
        THIS.perflog('GetBalTransfer 2: GetLastType', .T.)


        IF tcType = 'M'
            lcInlist  = [csusptype = 'D']
            lcInlist1 = [INLIST(csusptype,'M','H','Q','S','A','I')]
        ELSE
            lcInlist  = [INLIST(csusptype,'M','H','Q','S','A','I')]
            lcInlist1 = [csusptype = 'D']
        ENDIF

        lcRunYear = THIS.cRunYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

        lnTotal = 0

        IF NOT tlByOwner
            * Select all the records from beforerun that switched types when the run was closed            
            SELECT  * ;
                FROM beforerun ;
                WHERE &lcInlist1 ;
                    AND cownerid + cwellid + cTypeInv IN (SELECT  cownerid + cwellid + cTypeInv ;
                                                              FROM CurLastSuspType ;
                                                              WHERE &lcInlist) ;
                INTO CURSOR tempswitch

            * Sum the total of the suspense that changed types  
            SELECT  SUM(nNetCheck) AS nTotal ;
                FROM suspense WITH (BUFFERING = .T.) ;
                WHERE cownerid + cwellid + cTypeInv IN (SELECT  cownerid + cwellid + cTypeInv ;
                                                            FROM tempswitch) ;
                    AND crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear ;
                INTO CURSOR mytotal
            SELECT mytotal
            lnTotal    = nTotal
            lnseconds2 = SECONDS()
            lnseconds  = lnseconds2 - lnseconds1
            THIS.perflog('Suspense: GetBalTransfer', .T.)
            swclose('beforerun')
            lnReturn = lnTotal
        ELSE
            IF NOT USED('baltransfer')
                CREATE CURSOR baltransfer ;
                    (cownerid       c(10), ;
                      cwellid        c(10), ;
                      ctype          c(1), ;
                      namount        N(12, 2))
            ENDIF
            * Get the suspense that changed types when the run was closed            
            SELECT  * ;
                FROM beforerun ;
                WHERE &lcInlist1 ;
                    AND cownerid + cwellid + cTypeInv IN (SELECT  cownerid + cwellid + cTypeInv ;
                                                              FROM CurLastSuspType ;
                                                              WHERE &lcInlist) ;
                INTO CURSOR tempswitch
            * Sum the total for each owner and well             
            SELECT  cownerid, ;
                    cwellid, ;
                    SUM(nNetCheck) AS namount ;
                FROM suspense ;
                WHERE cownerid + cwellid + cTypeInv IN (SELECT  cownerid + cwellid + cTypeInv ;
                                                            FROM tempswitch) ;
                    AND crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear ;
                INTO CURSOR transsusp ;
                ORDER BY cownerid, cwellid ;
                GROUP BY cownerid, cwellid
            SELECT transsusp
            SCAN
                SCATTER MEMVAR
                m.ctype   = tcType
                INSERT INTO baltransfer FROM MEMVAR
            ENDSCAN
            THIS.perflog('Suspense: GetBalTransfer', .T.)
            swclose('beforerun')
            lnReturn = 0
        ENDIF
    CATCH TO loError
        lnReturn = 0
        DO errorlog WITH 'GetBalTransfer', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
    ENDTRY

    THIS.CheckCancel()
    m.goapp.Rushmore(.F.)

    RETURN lnReturn

    ENDPROC

    ****************************
    PROCEDURE GetWellHist
    ****************************
    LPARA tcWellID, tcyear, tcperiod, tcRunYear, tnRunno
    LOCAL llReturn, loError, m.cwellid, m.cGroup, llRunPassed

    llReturn = .T.
    m.goapp.Rushmore(.T., 'GetWellHist')

    TRY
        IF VARTYPE(tcRunYear) # 'C'
            llRunPassed = .F.
        ELSE
            llRunPassed = .T.
        ENDIF

        IF m.goapp.lCanceled
            llReturn          = .F.
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        IF NOT THIS.lClosing

            THIS.perflog('Suspense: Get Well Hist')
            THIS.timekeeper('GetWellHist: ' + tcWellID + ' ' + tcyear + '/' + tcperiod)
            * Look to see if the well history already exists in wellwork
            SELE wellwork
            IF llRunPassed
                SET ORDER TO wellprdrun
                SEEK(tcWellID + tcyear + tcperiod + 'R' + tcRunYear + PADL(TRANSFORM(tnRunno), 3, '0'))
            ELSE
                SET ORDER TO wellprd
                SEEK(tcWellID + tcyear + tcperiod + 'R')
            ENDIF
            IF FOUND()
                llReturn = .T.
                EXIT
            ENDIF
            IF llRunPassed
                SELE wellhist
                SET ORDER TO wellprd
                SCAN FOR cwellid == tcWellID ;
                     AND hyear == tcyear ;
                     AND hperiod == tcperiod ;
                     AND cRunYear == tcRunYear ;
                     AND nRunNo = tnRunno ;
                     AND crectype = 'R'
                    SCATTER MEMVAR
                    INSERT INTO wellwork FROM MEMVAR
                ENDSCAN
            ELSE
                SELE wellhist
                SET ORDER TO wellprd
                SCAN FOR cwellid == tcWellID ;
                     AND hyear == tcyear ;
                     AND hperiod == tcperiod ;
                     AND crectype = 'R'
                    SCATTER MEMVAR
                    INSERT INTO wellwork FROM MEMVAR
                ENDSCAN
            ENDIF
            THIS.perflog('Suspense: Get Well Hist', .T.)
            THIS.timekeeper('GetWellHist: End')
        ENDIF
    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'GetWellHist', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()
    m.goapp.Rushmore(.F.)

    RETURN llReturn

    ENDPROC

    *************************
    PROCEDURE isonhold
    *************************
    LPARA tcOwnerid, tlIntHold, tcWellID, tcTypeInv
    LOCAL llReturn, loError
    *
    * Checks to see if an owner or interest on hold
    *
    llReturn = .F.

    TRY

        IF m.goapp.lCanceled
            llReturn          = .F.
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        IF NOT tlIntHold
            SELE investor
            SET ORDER TO cownerid
            IF SEEK(tcOwnerid)
                IF lhold
                    llReturn = .T.
                ENDIF
            ENDIF
        ELSE
            SELE wellinv
            SET ORDER TO wellinvid
            IF SEEK(tcWellID + tcOwnerid + tcTypeInv)
                IF lonhold
                    llReturn = .T.
                ENDIF
            ELSE
                * Owner doesn't have an interest now so don't release them - pws 2/23/14
                llReturn = .T.
            ENDIF
        ENDIF
    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'IsOnHold', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()

    RETURN llReturn

    ENDPROC

    **************************
    PROCEDURE susptemp
    **************************
    LPARAMETERS tnRunno, tcRunYear, tcGroup, tlWellHist, tcType
    LOCAL lcRunYear, llReturn, loError

    llReturn = .T.

    TRY

        IF m.goapp.lCanceled
            llReturn          = .F.
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        * Builds a susptmp cursor that looks like invtmp
        * from the suspense and disbhist files

        IF VARTYPE(tcType) # 'C'
            tcType = 'R'
        ELSE
            IF NOT INLIST(tcType, 'J', 'R')
                tcType = 'R'
            ENDIF
        ENDIF

        IF EMPTY(THIS.cBegOwner)
            swselect('investor')
            SET ORDER TO cownerid
            GO TOP
            THIS.cBegOwner = cownerid
            GO BOTT
            THIS.cEndOwner = cownerid
        ENDIF

        IF EMPTY(THIS.cBegWell)
            swselect('wells')
            SET ORDER TO cwellid
            GO TOP
            THIS.cBegWell = cwellid
            GO BOTT
            THIS.cEndWell = cwellid
        ENDIF

        lcRunYear = tcRunYear + PADL(TRANSFORM(tnRunno), 3, '0')

        * Check to see if susptemp already exists so we don't create it again.
        IF USED('susptemp')
            SELECT susptemp
            LOCATE FOR cRunYear + PADL(TRANSFORM(nRunNo), 3, '0') = lcRunYear
            IF FOUND()
                llReturn = .T.
                EXIT
            ENDIF
        ENDIF

        swselect('disbhist')
        lnx = AFIELDS(latempx)
        swselect('ownpcts')
        lny = AFIELDS(latempy)
        DIMENSION laTemp[lnx + lny - 1, 18]
        FOR x = 1 TO lnx
            FOR Y = 1 TO 18
                laTemp[x, y] = latempx[x, y]
            ENDFOR
        ENDFOR
        FOR x = 1 TO lny - 1
            FOR Y = 1 TO 18
                laTemp[x + lnx, y] = latempy[x + 1, y]
            ENDFOR
        ENDFOR
        FOR x = 1 TO lnx + lny - 1
            laTemp[X, 7]  = ''
            laTemp[X, 8]  = ''
            laTemp[X, 9]  = ''
            laTemp[X, 10] = ''
            laTemp[X, 11] = ''
            laTemp[X, 12] = ''
            laTemp[X, 13] = ''
            laTemp[X, 14] = ''
            laTemp[X, 15] = ''
            laTemp[X, 18] = ''
        ENDFOR
        CREATE CURSOR susptemp FROM ARRAY laTemp

        * This is checked after table creation so tables exist on return
        IF tnRunno = 0
            llReturn = .T.
            EXIT
        ENDIF

        swselect('disbhist')
        SET ORDER TO RUN_IN   && CRUNYEAR_IN+PADL(TRANSFORM(NRUNNO_IN),3,"0")
        IF SEEK(lcRunYear)
            * Pull in records that were created in the given run but
            * processed later.
            SELECT  disbhist.*, ;
                    ownpcts.* ;
                FROM disbhist, ownpcts WITH (BUFFERING = .T.) ;
                WHERE disbhist.crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') = lcRunYear ;
                    AND disbhist.lmanual = .F. ;
                    AND crectype == tcType ;
                    AND disbhist.cGroup = tcGroup ;
                    AND BETWEEN(disbhist.cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND disbhist.ciddisb == ownpcts.ciddisb ;
                INTO CURSOR temp


            SELECT susptemp
            APPEND FROM DBF('temp')

        ENDIF

        swselect('disbhist')
        SET ORDER TO RUN   && CRUNYEAR+PADL(TRANSFORM(NRUNNO),3,"0")
        IF SEEK(lcRunYear)
            * Pull in records that were created and processed in the
            * given run.
            SELECT  disbhist.*, ;
                    ownpcts.* ;
                FROM disbhist, ownpcts WITH (BUFFERING = .T.) ;
                WHERE disbhist.cRunYear + PADL(TRANSFORM(nRunNo), 3, '0') = lcRunYear ;
                    AND disbhist.lmanual = .F. ;
                    AND crectype == tcType ;
                    AND disbhist.cSuspType == ' ' ;
                    AND disbhist.cGroup = tcGroup ;
                    AND BETWEEN(disbhist.cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                    AND disbhist.ciddisb == ownpcts.ciddisb ;
                INTO CURSOR temp

            SELECT susptemp
            APPEND FROM DBF('temp')
        ENDIF

        swselect('suspense')
        SET ORDER TO RUN_IN   && CRUNYEAR_IN+PADL(TRANSFORM(NRUNNO_IN),3,"0")
        IF SEEK(lcRunYear)
            * Pull in records that were created in the given run but
            * are still sitting in suspense.
            SELECT  * ;
                FROM suspense WITH (BUFFERING = .T.) ;
                WHERE crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') = lcRunYear ;
                    AND lmanual = .F. ;
                    AND crectype == tcType ;
                    AND suspense.cGroup = tcGroup ;
                    AND BETWEEN(suspense.cownerid, THIS.cBegOwner, THIS.cEndOwner) ;
                INTO CURSOR temp

            SELECT susptemp
            APPEND FROM DBF('temp')
        ENDIF

        * If we're building a wellwork cursor, scan through all
        * the runs needed to pull the correct data.
        * Request to create a wellwork file and populate it
        * with well history records from the given run.
        IF tlWellHist
            Make_Copy('wellhist', 'WellWork')
            SELECT wellwork
            INDEX ON cwellid + hyear + hperiod + crectype TAG wellprd

            SELECT  IIF(EMPTY(nrunno_in), nRunNo, nrunno_in) AS nRunNo, ;
                    IIF(EMPTY(crunyear_in), cRunYear, crunyear_in) AS cRunYear, ;
                    cGroup ;
                FROM susptemp ;
                INTO CURSOR temphist ;
                ORDER BY nRunNo, cRunYear, cGroup ;
                GROUP BY nRunNo, cRunYear, cGroup

            SELECT temphist
            SCAN
                SCATTER MEMVAR
                SELECT  * ;
                    FROM wellhist WITH (BUFFERING = .T.) ;
                    WHERE nRunNo == m.nRunNo ;
                        AND cRunYear == m.cRunYear ;
                        AND crectype == tcType ;
                        AND wellhist.cGroup = tcGroup ;
                        AND BETWEEN(wellhist.cwellid, THIS.cBegWell, THIS.cEndWell) ;
                    INTO CURSOR temp
                SELECT temp
                SCAN
                    SCATTER MEMVAR
                    SELECT wellwork
                    SET ORDER TO wellprd
                    IF NOT SEEK(m.cwellid + m.hyear + m.hperiod + m.crectype)
                        INSERT INTO wellwork FROM MEMVAR
                    ENDIF
                ENDSCAN
            ENDSCAN

            SELECT wellwork
            INDEX ON cwellid TAG cwellid
            INDEX ON hyear + hperiod TAG yearprd
            INDEX ON nRunNo TAG nRunNo
            INDEX ON cRunYear TAG cRunYear
            INDEX ON DELETED() TAG _deleted BINARY

        ENDIF

        SELECT susptemp
        SCAN FOR nrunno_in # 0
            REPLACE nRunNo WITH nrunno_in
        ENDSCAN

        * We assume that if wellwork is requested, then we should
        * also be creating an invtmp cursor as well.
        IF tlWellHist
            swclose('invtmp')
            USE DBF('susptemp') AGAIN IN 0 ALIAS invtmp

            SELECT invtmp
            INDEX ON cownerid + cprogcode + cwellid + cTypeInv TAG ownertype
            INDEX ON cownerid + cwellid TAG invwell
        ENDIF

    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'SuspTemp', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()

    RETURN llReturn

    ENDPROC
    *************************
    PROTECTED PROCEDURE get_next_key
        *************************
        LPARA tcTable
        LOCAL lcKey, lcReturn, loError

        lcReturn = '*'

        TRY

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            THIS.timekeeper('Get_Next_Key - Start')
            lcKey = THIS.oRegistry.IncrementCounter('%Shared.Counters.Owner History')
            SET DELETED OFF

            SELECT disbhist1
            SET ORDER TO ciddisb
            DO WHILE SEEK(lcKey)
                * Get the next primary key for suspense (matches owner history)
                lcKey = THIS.oRegistry.IncrementCounter('%Shared.Counters.Owner History')
            ENDDO

            SELECT suspense1
            SET ORDER TO ciddisb
            DO WHILE SEEK(lcKey)
                * Get the next primary key for suspense (matches owner history)
                lcKey = THIS.oRegistry.IncrementCounter('%Shared.Counters.Owner History')
            ENDDO

            THIS.timekeeper('Get_Next_Key - End')

            SET DELETED ON

            lcReturn = lcKey

        CATCH TO loError
            llReturn = .F.
            DO errorlog WITH 'Get_Next_Key', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
            MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
        ENDTRY

        THIS.CheckCancel()

        RETURN lcReturn

        *****************************
    PROTECTED PROCEDURE timekeeper
        ******************************
        LPARA tcDescription

        IF THIS.lDebug
            IF USED('debugtime')
                m.cdesc = tcDescription
                m.ntime = SECONDS()
                INSERT INTO debugtime FROM MEMVAR
                FLUSH IN debugtime FORCE
            ENDIF
        ENDIF

        ENDPROC

        ***************************************
    PROCEDURE owner_payments
    ***************************************
    LPARAMETERS tcOwnerid, tcGroup
    * Get any payments made since last run.
    LOCAL lnbalance, lnTally, lcRunYear
    LOCAL lnReturn, loError

    lnReturn = 0
    m.goapp.Rushmore(.T., 'Owner_Payments')

    TRY

        IF m.goapp.lCanceled
            lnReturn = 0
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        THIS.open_files()

        THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Owner Payments')

        *   lcRunYear = THIS.cRunYear+PADL(TRANSFORM(THIS.nRunNo),3,'0')
        lcRunYear = getrunno(THIS.cRunYear, .F., 'R', .F., tcGroup, .T., THIS.nRunNo)
        lcAlias   = ALIAS()

        IF THIS.at_pay_freq(tcOwnerid)
            SELECT  cwellid ;
                FROM wellinv ;
                JOIN investor ;
                    ON wellinv.cownerid == investor.cownerid ;
                WHERE wellinv.cownerid == tcOwnerid ;
                    AND wellinv.lonhold = .F. ;
                    AND investor.lhold  = .F. ;
                INTO CURSOR tempwells ;
                ORDER BY wellinv.cwellid ;
                GROUP BY wellinv.cwellid

            IF NOT THIS.lNewRun
                * Get the suspense payments before this run still in suspense
                SELECT  SUM(nNetCheck) AS nBalance ;
                    FROM tsuspense ;
                    WHERE cownerid == tcOwnerid ;
                        AND crectype = 'P' ;
                        AND cGroup   == tcGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') = lcRunYear) ;
                        AND (cprogcode = SPACE(10) ;
                          OR cprogcode IN (SELECT  cprogcode ;
                                               FROM programs ;
                                               WHERE lprognet = .T.)) ;
                    INTO CURSOR tempbalance1

                lnTally = _TALLY


                SELECT  SUM(nNetCheck) AS nBalance ;
                    FROM disbhist WITH (BUFFERING = .T.) ;
                    WHERE cownerid == tcOwnerid ;
                        AND crectype = 'P' ;
                        AND cGroup   == tcGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') = lcRunYear) ;
                        AND (cprogcode = SPACE(10) ;
                          OR cprogcode IN (SELECT  cprogcode ;
                                               FROM programs ;
                                               WHERE lprognet = .T.)) ;
                        AND disbhist.cwellid IN (SELECT  cwellid ;
                                                     FROM tempwells) ;
                    INTO CURSOR tempbalance2
                lnTally = lnTally + _TALLY

            ELSE
                SELECT  SUM(nNetCheck) AS nBalance ;
                    FROM suspense ;
                    WHERE cownerid == tcOwnerid ;
                        AND crectype = 'P' ;
                        AND cGroup   == tcGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') = lcRunYear) ;
                        AND (cprogcode = SPACE(10) ;
                          OR cprogcode IN (SELECT  cprogcode ;
                                               FROM programs ;
                                               WHERE lprognet = .T.)) ;
                    INTO CURSOR tempbalance1
                lnTally = _TALLY

                SELECT  SUM(nNetCheck) AS nBalance ;
                    FROM invtmp WITH (BUFFERING = .T.) ;
                    WHERE cownerid == tcOwnerid ;
                        AND crectype = 'P' ;
                        AND cGroup   == tcGroup ;
                        AND (cprogcode = SPACE(10) ;
                          OR cprogcode IN (SELECT  cprogcode ;
                                               FROM programs ;
                                               WHERE lprognet = .T.)) ;
                    INTO CURSOR tempbalance2
                lnTally = lnTally + _TALLY

            ENDIF

            IF lnTally > 0
                SELECT tempbalance1
                GO TOP
                lnbalance = nBalance
                SELECT tempbalance2
                GO TOP
                lnbalance = lnbalance + nBalance
                swclose('tempbalance1')
                swclose('tempbalance2')
            ELSE
                lnbalance = 0
            ENDIF
        ELSE
            lnbalance = 0
        ENDIF

        lnReturn = lnbalance

        SELECT (lcAlias)

    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'Owner_Payments', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        *         MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
        'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()
    m.goapp.Rushmore(.F.)

    RETURN lnReturn

    ENDPROC
    ***************************************
    FUNCTION suspense_balance
    ***************************************
    LPARAMETERS tcType, tlAfterRun, tlIgnorePrograms, tlForceGet, tlIncPayments
    LOCAL lnbalance, lntally1, lntally2, lcAlias, lcRunYear
    LOCAL lnReturn, loError

    lnReturn = 0
    m.goapp.Rushmore(.T., 'Suspense_Balance')

    TRY

        IF m.goapp.lCanceled
            lnReturn = 0
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        DO CASE
            CASE tcType = 'D'
                lcWhere = [csusptype = 'D']
            CASE tcType = 'M'
                lcWhere = [csusptype # 'D']
            OTHERWISE
                lcWhere = [csusptype = tcType]
        ENDCASE

        THIS.perflog('Suspense: Suspense Balance')
        lcRunYear = THIS.cRunYear + PADL(TRANSFORM(THIS.nRunNo), 3, '0')

        CREATE CURSOR tempbal (cownerid c (10), nBalance N (12, 2))
        CREATE CURSOR temp (cownerid c (10), nBalance N (12, 2))

        STORE 0 TO lnbalance, lnTally

        THIS.open_files(.T.)

        lcAlias = ALIAS()

        THIS.perflog('Suspense Balance: GetLastType')
        THIS.getlasttype(tlAfterRun, .T., THIS.cGroup, tlForceGet, .F., tlIncPayments)
        THIS.perflog('Suspense Balance: GetLastType', .T.)

        IF tlAfterRun
            IF NOT tlIgnorePrograms
                SELECT  ;
                    FROM suspense WITH (BUFFERING = .T.) cownerid, SUM(nNetCheck) AS nBalance ;
                    WHERE cGroup == THIS.cGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                        AND (cprogcode = SPACE(10) ;
                          OR cprogcode IN(SELECT  cprogcode ;
                                              FROM programs ;
                                              WHERE lprognet = .T.)) ;
                        AND suspense.cownerid + suspense.cwellid IN(SELECT  cownerid + cwellid ;
                                                                        FROM CurLastSuspType ;
                                                                        WHERE &lcWhere) ;
                        AND suspense.cownerid NOT IN (SELECT  cownerid ;
                                                          FROM investor ;
                                                          WHERE investor.lDummy) ;
                    GROUP BY cownerid ;
                    ORDER BY cownerid ;
                    INTO CURSOR tempbalance1
                lntally1 = _TALLY

                SELECT  ;
                    FROM disbhist WITH (BUFFERING = .T.) cownerid, SUM(nNetCheck) AS nBalance ;
                    WHERE cGroup == THIS.cGroup ;
                        AND ((disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') <= lcRunYear) ;
                          AND ( NOT EMPTY(disbhist.nrunno_in);
                            AND  NOT EMPTY(disbhist.crunyear_in))) ;
                        AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') > lcRunYear) ;
                        AND (cprogcode = SPACE(10) ;
                          OR cprogcode IN(SELECT  cprogcode ;
                                              FROM programs ;
                                              WHERE lprognet = .T.)) ;
                        AND disbhist.cownerid + disbhist.cwellid IN(SELECT  cownerid + cwellid ;
                                                                        FROM CurLastSuspType ;
                                                                        WHERE &lcWhere) ;
                        AND disbhist.cownerid NOT IN (SELECT  cownerid ;
                                                          FROM investor ;
                                                          WHERE investor.lDummy) ;
                    GROUP BY cownerid ;
                    ORDER BY cownerid ;
                    INTO CURSOR tempbalance2
                lntally2 = _TALLY
            ELSE
                SELECT  ;
                    FROM suspense WITH (BUFFERING = .T.) cownerid, SUM(nNetCheck) AS nBalance ;
                    WHERE cGroup == THIS.cGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') <= lcRunYear) ;
                        AND suspense.cownerid + suspense.cwellid IN(SELECT  cownerid + cwellid ;
                                                                        FROM CurLastSuspType ;
                                                                        WHERE &lcWhere) ;
                        AND suspense.cownerid NOT IN (SELECT  cownerid ;
                                                          FROM investor ;
                                                          WHERE investor.lDummy) ;
                    GROUP BY cownerid ;
                    ORDER BY cownerid ;
                    INTO CURSOR tempbalance1
                lntally1 = _TALLY

                SELECT  ;
                    FROM disbhist WITH (BUFFERING = .T.) cownerid, SUM(nNetCheck) AS nBalance ;
                    WHERE cGroup == THIS.cGroup ;
                        AND ((disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') <= lcRunYear) ;
                          AND ( NOT EMPTY(disbhist.nrunno_in);
                            AND  NOT EMPTY(disbhist.crunyear_in))) ;
                        AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') > lcRunYear) ;
                        AND disbhist.cownerid + disbhist.cwellid IN(SELECT  cownerid + cwellid ;
                                                                        FROM CurLastSuspType ;
                                                                        WHERE &lcWhere) ;
                        AND disbhist.cownerid NOT IN (SELECT  cownerid ;
                                                          FROM investor ;
                                                          WHERE investor.lDummy) ;
                    GROUP BY cownerid ;
                    ORDER BY cownerid ;
                    INTO CURSOR tempbalance2
                lntally2 = _TALLY

            ENDIF
        ELSE
            IF NOT tlIgnorePrograms
                SELECT  ;
                    FROM suspense WITH (BUFFERING = .T.) cownerid, SUM(nNetCheck) nBalance ;
                    WHERE cGroup == THIS.cGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear) ;
                        AND (cprogcode = SPACE(10) ;
                          OR cprogcode IN (SELECT  cprogcode ;
                                               FROM programs ;
                                               WHERE lprognet = .T.)) ;
                        AND suspense.cownerid + suspense.cwellid IN(SELECT  cownerid + cwellid ;
                                                                        FROM CurLastSuspType ;
                                                                        WHERE &lcWhere) ;
                        AND suspense.cownerid NOT IN (SELECT  cownerid ;
                                                          FROM investor ;
                                                          WHERE investor.lDummy) ;
                    GROUP BY cownerid ;
                    ORDER BY cownerid ;
                    INTO CURSOR tempbalance1
                lntally1 = _TALLY

                SELECT  ;
                    FROM disbhist WITH (BUFFERING = .T.) cownerid, SUM(nNetCheck) nBalance ;
                    WHERE cGroup == THIS.cGroup ;
                        AND ((disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') < lcRunYear ) ;
                          AND (NOT EMPTY(disbhist.nrunno_in) ;
                            AND  NOT EMPTY(disbhist.crunyear_in))) ;
                        AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') > lcRunYear ;
                          AND nRunNo # 9999) ;
                        AND (cprogcode = SPACE(10) ;
                          OR cprogcode IN (SELECT  cprogcode ;
                                               FROM programs ;
                                               WHERE lprognet = .T.)) ;
                        AND disbhist.cownerid + disbhist.cwellid IN(SELECT  cownerid + cwellid ;
                                                                        FROM CurLastSuspType ;
                                                                        WHERE &lcWhere) ;
                        AND disbhist.cownerid NOT IN (SELECT  cownerid ;
                                                          FROM investor ;
                                                          WHERE investor.lDummy) ;
                    GROUP BY cownerid ;
                    ORDER BY cownerid ;
                    INTO CURSOR tempbalance2
                lntally2 = _TALLY
            ELSE
                SELECT  ;
                    FROM suspense WITH (BUFFERING = .T.) cownerid, SUM(nNetCheck) nBalance ;
                    WHERE cGroup == THIS.cGroup ;
                        AND (crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') < lcRunYear) ;
                        AND suspense.cownerid + suspense.cwellid IN(SELECT  cownerid + cwellid ;
                                                                        FROM CurLastSuspType ;
                                                                        WHERE &lcWhere) ;
                        AND suspense.cownerid NOT IN (SELECT  cownerid ;
                                                          FROM investor ;
                                                          WHERE investor.lDummy) ;
                    GROUP BY cownerid ;
                    ORDER BY cownerid ;
                    INTO CURSOR tempbalance1
                lntally1 = _TALLY

                SELECT  ;
                    FROM disbhist WITH (BUFFERING = .T.) cownerid, SUM(nNetCheck) nBalance ;
                    WHERE cGroup == THIS.cGroup ;
                        AND ((disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') < lcRunYear) ;
                          AND ( NOT EMPTY(disbhist.nrunno_in) ;
                            AND  NOT EMPTY(disbhist.crunyear_in))) ;
                        AND (disbhist.cRunYear + PADL(TRANSFORM(disbhist.nRunNo), 3, '0') >= lcRunYear ;
                          AND nRunNo # 9999) ;
                        AND disbhist.cownerid + disbhist.cwellid IN(SELECT  cownerid + cwellid ;
                                                                        FROM CurLastSuspType ;
                                                                        WHERE &lcWhere) ;
                        AND disbhist.cownerid NOT IN (SELECT  cownerid ;
                                                          FROM investor ;
                                                          WHERE investor.lDummy) ;
                    GROUP BY cownerid ;
                    ORDER BY cownerid ;
                    INTO CURSOR tempbalance2
                lntally2 = _TALLY
            ENDIF
        ENDIF

        IF lntally1 > 0
            SELECT temp
            APPEND FROM DBF('tempbalance1')
            swclose('tempbalance1')
        ENDIF

        IF lntally2 > 0
            SELECT temp
            APPEND FROM DBF('tempbalance2')
            swclose('tempbalance2')
        ENDIF

        SELECT cownerid, SUM(nBalance) AS nBalance FROM temp GROUP BY cownerid ORDER BY cownerid INTO CURSOR temp1
        SELECT temp1
        SCAN
            IF nBalance # 0
                SCATTER MEMVAR
                INSERT INTO tempbal FROM MEMVAR
            ENDIF
        ENDSCAN

        SELECT SUM(nBalance) AS nBalance FROM tempbal INTO CURSOR temp2
        swclose('tempbal')
        THIS.perflog('Suspense: Suspense Balance', .T.)
        SELECT temp2
        lnbalance = temp2.nBalance
        swclose('temp2')

        lnReturn = lnbalance

    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'Suspense_Balance', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        *        MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
        'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()
    m.goapp.Rushmore(.F.)

    RETURN lnReturn

    ENDFUNC

    ***************************************
    FUNCTION check_for_payments
    ***************************************
    LOCAL lnGlobalMin, lnOwnerMin
    LOCAL lcSuspKey, llReturn, loError, lprognet
    LOCAL cRunYear, ciddisb, crunyear_in, cSuspType, nRunNo, ndisbfreq, nrunno_in

    #DEFINE BY_OWNER .T.
    #DEFINE AFTER_RUN .T.
    #DEFINE DONT_IGNORE_HOLD .F.

    llReturn = .T.
    m.goapp.Rushmore(.T., 'Check_For_Payments')

    TRY

        IF m.goapp.lCanceled
            llReturn          = .F.
            IF NOT m.goapp.CancelMsg()
                THIS.lCanceled = .T.
                EXIT
            ENDIF
        ENDIF

        STORE 0 TO lnGlobalMin, lnOwnerMin

        THIS.perflog('Suspense: Check For Pmts')
        THIS.timekeeper('Suspense: Check for Payments')

        * Look to see if there are any payment records
        swselect('suspense', .T.)
        SET ORDER TO crectype
        IF NOT SEEK('P')
            * No pmt processing needed
            THIS.perflog('Suspense: Check For Pmts', .T.)
            THIS.timekeeper('Suspense: Check for Payments End')
            llReturn = .T.
            EXIT
        ENDIF

        * Get the global minimum check amount
        swselect('options')
        GO TOP
        lnGlobalMin = nMinCheck

        THIS.owner_suspense_balance(BY_OWNER, .F., THIS.cGroup, AFTER_RUN, DONT_IGNORE_HOLD )
        THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Checking for payments...')

        * Scan through the unique owner combinations so we can get the current balance for the given owner
        SELE ownsuspbal
        SCAN FOR nBalance >= 0
            SCATTER MEMVAR
            THIS.oProgress.SetProgressMessage('Processing Suspense by Owner... Check for payments - ' + m.cownerid)

            IF m.goapp.lCanceled
                llReturn          = .F.
                IF NOT m.goapp.CancelMsg()
                    THIS.lCanceled = .T.
                    EXIT
                ENDIF
            ENDIF

            swselect('suspense')
            SET ORDER TO owner_type
            IF SEEK(m.cownerid + "P")
                * The payment zeroed the balance so release all suspense entries
                SELECT  * ;
                    FROM suspense WITH (BUFFERING = .T.) ;
                    WHERE cownerid == ownsuspbal.cownerid ;
                        AND cGroup == THIS.cGroup ;
                    INTO CURSOR tempsusp
                * Look for owner minimum check amt
                swselect('investor')
                SET ORDER TO cownerid
                IF SEEK(ownsuspbal.cownerid)
                    * Don't release this if the owner is on hold
                    IF investor.lhold = .T.
                        LOOP
                    ENDIF
                    m.ndisbfreq = ndisbfreq
                    IF investor.nInvMin # 0
                        lnOwnerMin = investor.nInvMin
                    ELSE
                        lnOwnerMin = lnGlobalMin
                    ENDIF
                ELSE
                    LOOP
                ENDIF
                SELECT tempsusp
                SCAN
                    m.lprognet = lprognet
                    swselect('programs')
                    LOCATE FOR cprogcode == tempsusp.cprogcode
                    IF FOUND()
                        m.lprognet = lprognet
                    ENDIF
                    SELECT tempsusp
                    IF NOT EMPTY(cprogcode) AND NOT m.lprognet
                        LOOP
                    ENDIF
                    IF INLIST(cSuspType, 'I', 'H')
                        LOOP
                    ENDIF
                    SCATTER MEMVAR

                    * Don't release if the owner is not at their pay frequency
                    IF NOT THIS.at_pay_freq(m.cownerid, m.ndisbfreq)
                        LOOP
                    ENDIF

                    * Check for the interest being on hold. Don't release it if it is
                    IF THIS.isonhold(m.cownerid, .T., m.cwellid, m.cTypeInv)
                        LOOP
                    ENDIF

                    * Look to see if amount is below minimum check amount
                    IF ownsuspbal.nBalance < lnOwnerMin
                        LOOP
                    ENDIF

                    IF nrunno_in = THIS.nRunNo AND crunyear_in = THIS.cRunYear
                        m.nrunno_in   = 0
                        m.crunyear_in = ''
                        m.cSuspType   = ''
                    ENDIF

                    lcSuspKey = m.ciddisb
                    * Store the original run into run_in
                    m.nrunno_in   = m.nRunNo
                    m.crunyear_in = m.cRunYear
                    * Swap the original run with current run
                    m.nRunNo   = THIS.nRunNo
                    m.cRunYear = THIS.cRunYear
                    m.ciddisb  = THIS.get_next_key('disbhist')
                    IF EMPTY(m.cSuspType)
                        m.nrunno_in   = 0
                        m.crunyear_in = ''
                    ENDIF
                    INSERT INTO invtmp FROM MEMVAR
                    SELE suspense
                    SET ORDER TO ciddisb
                    IF SEEK(lcSuspKey)
                        DELETE NEXT 1
                    ENDIF
                    SELECT tsuspense
                    LOCATE FOR ciddisb == lcSuspKey
                    IF FOUND()
                        DELETE NEXT 1
                    ENDIF
                    * Get the well history record corresponding to the owner history
                    THIS.getwellhist(m.cwellid, m.hyear, m.hperiod)
                ENDSCAN
                swclose('tempsusp')
            ENDIF
        ENDSCAN
        swclose('ownsuspbal')
        WAIT CLEAR
        THIS.perflog('Suspense: Check For Pmts', .T.)
        THIS.timekeeper('Suspense: Check for Payments End')
    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'Check_For_Payments', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
        MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
    ENDTRY

    THIS.CheckCancel()
    m.goapp.Rushmore(.F.)

    RETURN llReturn

    ***************************************
    FUNCTION Owner_Pay_Freq
    ***************************************
    * This has already been set so we don't need to look again
    IF THIS.lNoPayFreqs OR THIS.lCheckedFreqs
        RETURN
    ENDIF

    swselect('investor')
    LOCATE FOR ndisbfreq # 0 AND ndisbfreq # 1
    IF NOT FOUND()
        THIS.lNoPayFreqs = .T.
    ENDIF

    THIS.lCheckedFreqs = .T.

    ENDFUNC

    *****************************************
    FUNCTION CheckCancel
    *****************************************

    IF THIS.lCanceled
        IF VARTYPE(THIS.oProgress) = 'O'
            THIS.oProgress.CloseProgress
            THIS.oProgress = .NULL.
        ENDIF
        THIS.lCanceled = .F.
    ENDIF

    ENDFUNC
    
    *********************************************
    FUNCTION Clear_Suspense (tcOwnerid, tcGroup)
    *********************************************
    LOCAL lcScan
    
    IF VARTYPE(tcGroup) = 'C'
       lcScan = "cOwnerID = tcOwnerID and cGroup = tcGroup"
    ELSE
       lcSCan = "cOwnerID = tcOwnerID"
    ENDIF 
    
   SELECT suspense
   SCAN FOR &lcScan
      SCATTER MEMVAR

      IF NOT THISFORM.IsOnHold(m.cownerid, .T., m.cwellid, m.ctypeinv)
         m.hDate = ldDate

         m.cBatch = lcBatch

         m.ciddisb = oRegistry.IncrementCounter('%Shared.Counters.Owner History')  &&  Make sure new primary key in disbhist is unique

         SWSELECT('disbhist', .T.)
         SET ORDER TO ciddisb
         SET DELE OFF
         DO WHILE SEEK(m.ciddisb)
            m.ciddisb = oRegistry.IncrementCounter('%Shared.Counters.Owner History')
         ENDDO

         SWSELECT('ownpcts', .T.)  &&  Check ownpcts, too, since we're updating that, too
         SET ORDER TO ciddisb
         DO WHILE SEEK(m.ciddisb)
            m.ciddisb = oRegistry.IncrementCounter('%Shared.Counters.Owner History')
         ENDDO
         SET DELE ON

         m.nRunNo	= 9999
         m.cRunYear	= lcRunYear

         INSERT INTO disbhist FROM MEMVAR
         INSERT INTO ownpcts FROM MEMVAR

         lnTotal = lnTotal + m.nNetCheck  &&  Running total for the entries being transferred
      ENDIF
   ENDSCAN

ENDDEFINE
*
*-- EndDefine: suspense
**************************************************



















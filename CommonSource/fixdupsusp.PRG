*  Looks for duplicate suspense entries and removes them

LOCAL lnCountD, lncountS
*:Global crectype
PRIV lcTitle1, lcTitle2, lcSortOrder, lcSelect, glGrpName, m.cGrpName, llPrinted

llReturn = .T.
TRY

    glGrpName    = .F.
    m.cGrpName   = ''
    llPrinted    = .F.
    lcSelect     = ''
    m.cprocessor = ''
    m.cproducer  = m.goapp.ccompanyname
    lncountS     = 0
    IF NOT USED('suspense')
        USE suspense IN 0
    ENDIF
    IF NOT USED('tmpsusp')
        USE suspense AGAIN IN 0 ALIAS tmpsusp
    ENDIF

    IF NOT USED('disbhist')
        USE disbhist IN 0
    ENDIF
    IF NOT USED('tmpdisb')
        USE disbhist AGAIN IN 0 ALIAS tmpdisb
    ENDIF

    IF NOT USED('sysctl')
        USE sysctl IN 0
    ENDIF

    IF USED('delrecs')
        USE IN delrecs
    ENDIF
    make_copy('disbhist', 'delrecs')
    SELECT delrecs
    INDEX ON crectype + crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') + cownerid + cwellid TAG delkey
    CREATE CURSOR keeprecs (ciddisb c(8))
    
	SELECT  * ;
		FROM suspense ;
		WHERE nnetcheck # 0 ;
			AND LEFT(ciddisb, 1) # '#' ;
		INTO CURSOR susptemp ;
		ORDER BY cownerid, cwellid, crunyear_in, nrunno_in, hyear, hperiod, nnetcheck, ctypeinv, csusptype ;
		GROUP BY cownerid, cwellid, crunyear_in, nrunno_in, hyear, hperiod, nnetcheck, ctypeinv, csusptype
    lnmax = _TALLY
	SELECT  * ;
		FROM disbhist ;
		WHERE nnetcheck # 0 ;
			AND LEFT(ciddisb, 1) # '#' ;
			AND crunyear > '2019' ;
		INTO CURSOR histtemp ;
		ORDER BY cownerid, cwellid, crunyear_in, nrunno_in, hyear, hperiod, nnetcheck, ctypeinv, csusptype ;
		GROUP BY cownerid, cwellid, crunyear_in, nrunno_in, hyear, hperiod, nnetcheck, ctypeinv, csusptype
    lnmax     = lnmax + _TALLY
    lnCount   = 1
    oprogress = m.goapp.omessage.progressbarex('Looking for duplicates: ', '')
    oprogress.setprogressrange(0, lnmax)
    oprogress.setprogressmessage('Processing suspense...')
    SELECT susptemp
    SCAN
        SCATTER MEMVAR
        oprogress.updateprogress(lnCount)
        lnCount  = lnCount + 1
        lciddisb = m.ciddisb
        SELECT tmpsusp
        SCAN FOR cownerid = m.cownerid AND cwellid = m.cwellid AND nrunno_in = m.nrunno_in   ;
                AND crunyear_in = m.crunyear_in AND nnetcheck = m.nnetcheck AND nnetcheck # 0 ;
                AND hyear = m.hyear AND hperiod = m.hperiod AND ctypeinv = m.ctypeinv AND ciddisb <> lciddisb AND LEFT(ciddisb, 1) # '#'
            SELECT keeprecs
            LOCATE FOR ciddisb = tmpsusp.ciddisb
            IF FOUND()
               LOOP
            ENDIF     
            m.crectype = 'S'
            SELECT delrecs
            LOCATE FOR ciddisb == tmpsusp.ciddisb
            IF NOT FOUND()
                m.ciddisb = tmpsusp.ciddisb
                INSERT INTO delrecs FROM MEMVAR
                lncountS  = lncountS + 1
                m.ciddisb = lciddisb
                INSERT INTO keeprecs FROM MEMVAR 
            ENDIF
        ENDSCAN
    ENDSCAN
    WAIT CLEAR

    lnCountD = 0
    oprogress.setprogressmessage('Processing owner history...')
    SELECT histtemp
    SCAN
        SCATTER MEMVAR
        oprogress.updateprogress(lnCount)
        lnCount  = lnCount + 1
        lciddisb = m.ciddisb
        SELECT tmpdisb
        SCAN  FOR cownerid = m.cownerid AND cwellid = m.cwellid AND nrunno_in = m.nrunno_in  ;
                AND crunyear_in = m.crunyear_in  AND nnetcheck = m.nnetcheck AND nnetcheck # 0  ;
                AND hyear = m.hyear AND hperiod = m.hperiod AND ctypeinv = m.ctypeinv AND ciddisb <> lciddisb ;
                AND LEFT(ciddisb, 1) # '#'
            m.crectype = 'H'
            SELECT delrecs
            LOCATE FOR ciddisb == tmpdisb.ciddisb
            IF NOT FOUND()
                SELECT suspense
                LOCATE FOR ciddisb = '#' + SUBSTR(tmpdisb.ciddisb, 2)
                IF NOT FOUND()
                    m.ciddisb = tmpdisb.ciddisb
                    INSERT INTO delrecs FROM MEMVAR
                    lnCountD  = lnCountD + 1
                    m.ciddisb = lciddisb
                ENDIF
            ENDIF
        ENDSCAN
    ENDSCAN
    WAIT CLEAR
    oprogress.closeprogress()
    IF lnCountD # 0 OR lncountS # 0

        MESSAGEBOX('Found: ' + TRANSFORM(lncountS) + ' duplicate suspense entries' + CHR(10) + ;
              'Found: ' + TRANSFORM(lnCountD) + ' duplicate owner history entries' + CHR(10) + CHR(10) + ;
              'A report showing the duplicates will open when this dialog is closed.', 0, 'Duplicate records')
		SELECT  delrecs.*, investor.cownname, wells.cwellname, 0 AS ntotbbl, 0 AS ntotmcf ;
			FROM delrecs ;
			JOIN investor ;
				ON investor.cownerid = delrecs.cownerid ;
			JOIN wells ;
				ON wells.cwellid = delrecs.cwellid ;
			INTO CURSOR delrpt ;
			ORDER BY crectype, cownname, cwellname, crunyear, nRunNo
        lcTitle1         = 'Duplicate Suspense/History Records Found'
        lcTitle2         = ''
        lcSelectCriteria = ''
        lcSortOrder      = ''
        REPORT FORM dmrodups TO PRINTER PROMPT PREVIEW

        IF MESSAGEBOX('Do you want to remove the duplicates now?', 36, 'Duplicate RECORDS') = 6
            IF lncountS > 0
                WAIT WINDOW NOWAIT 'Removing duplicate suspense...'
                DELETE FROM suspense WHERE ciddisb + 'S' IN (SELECT ciddisb + crectype FROM delrecs)
                WAIT CLEAR
            ENDIF
            IF lnCountD > 0
                SELECT delrecs
                SET DELETED OFF
                SCAN FOR crectype = 'H'
                    SCATTER MEMVAR
                    SELECT suspense
                    LOCATE FOR ciddisb = '#' + SUBSTR(m.ciddisb, 2)
                    IF NOT FOUND()
                        m.nincome   = m.nincome * -1
                        m.nexpense  = m.nexpense * -1
                        m.nSevtaxes = m.nSevtaxes * -1
                        m.nnetcheck = m.nnetcheck * -1
                        m.ntotale1  = m.ntotale1 * -1
                        m.ntotale2  = m.ntotale2 * -1
                        m.ntotale3  = m.ntotale3 * -1
                        m.ntotale4  = m.ntotale4 * -1
                        m.ntotale5  = m.ntotale5 * -1
                        m.ntotalea  = m.ntotalea * -1
                        m.ntotaleb  = m.ntotaleb * -1
                        m.ngasrev   = m.ngasrev * -1
                        m.noilrev   = m.noilrev * -1
                        m.noiltax1  = m.noiltax1 * -1
                        m.noiltax2  = m.noiltax2 * -1
                        m.noiltax3  = m.noiltax3 * -1
                        m.noiltax4  = m.noiltax4 * -1
                        m.ngastax1  = m.ngastax1 * -1
                        m.ngastax2  = m.ngastax2 * -1
                        m.ngastax3  = m.ngastax3 * -1
                        m.ngastax4  = m.ngastax4 * -1
                        m.nothtax1  = m.nothtax1 * -1
                        m.nothtax2  = m.nothtax2 * -1
                        m.nothtax3  = m.nothtax3 * -1
                        m.nothtax4  = m.nothtax4 * -1
                        m.ntaxwith  = m.ntaxwith * -1
                        m.nbackwith = m.nbackwith * -1
                        m.nothrev   = m.nothrev * -1
                        m.ngather   = m.ngather * -1
                        m.ncompress = m.ncompress * -1
                        m.nmiscrev1 = m.nmiscrev1 * -1
                        m.nmiscrev2 = m.nmiscrev2 * -1
                        m.nflatrate = m.nflatrate * -1
                        m.ciddisb   = '#' + SUBSTR(m.ciddisb, 2)
                        m.crectype  = 'R'
                        INSERT INTO suspense FROM MEMVAR
                    ENDIF
                ENDSCAN
                SET DELETED ON
            ENDIF
            MESSAGEBOX('Duplicate entries have been removed/adjusted.', 64, 'Duplicate Entries')
        ENDIF
    ELSE
        MESSAGEBOX('No duplicate entries were found in suspense or owner history!', 48, 'Duplicate Entries')
    ENDIF
CATCH TO loError
    llReturn = .F.
    DO errorlog WITH 'Duplicates', loError.LINENO, 'Find Duplicates', loError.ERRORNO, loError.MESSAGE, '', loError
    MESSAGEBOX('Unable to process the duplicate utility at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
          'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn









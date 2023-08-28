LPARA tlDirect, tnRunNo, tcRunyear
*
*  Calculates the royalty and working interest payments and plugs them into wellhist
*

*
* Changed to process by runno 7/23/08 - pws
*

IF TYPE('m.goApp') = 'O'
   lcPath = ALLTRIM(m.goApp.cDataFilePath)
ELSE
   lcPath = 'Data\'
ENDIF

IF NOT USED('wellhist')
   USE (lcPath+'wellhist') IN 0
ENDIF

IF NOT USED('disbhist')
   USE (lcPath+'disbhist') IN 0
ENDIF

IF NOT USED('suspense')
   USE (lcPath+'suspense') IN 0
ENDIF

IF RECC('disbhist') + RECCOUNT('suspense') = 0
   RETURN
ENDIF

IF VARTYPE(tnRunNo) = 'N'
         SELECT cownerid, cWellID, hYear, hPeriod, cRecType, ;
            SUM(IIF(cTypeInv='W',noilrev+ngasrev+nothrev+ntrprev+nmiscrev1+nmiscrev2-nsevtaxes-nexpense-ntotale1-ntotale2-ntotale3-ntotale4-ntotale5-ntotalea-ntotaleb,0000000.00)) AS nworking, ;
            SUM(IIF(INLIST(cTypeInv,'L','O'),noilrev+ngasrev+nothrev+ntrprev+nmiscrev1+nmiscrev2+nflatrate-nsevtaxes-nexpense-ntotale1-ntotale2+ntotale3-ntotale4-ntotale5-ntotalea-ntotaleb,0000000.00)) AS nroyalty ;
            FROM disbhist WITH (buffering=.t.);
            WHERE cRunYear = m.cRunYear  ;
            AND nrunno = m.nrunno  ;
            AND lProgram = .F. ;
            INTO CURSOR temphist readwrite ;
            ORDER BY cWellID, crunYear, nrunno, hYear, hPeriod, cRecType ;
            GROUP BY cWellID, cRunYear, nrunno, hYear, hPeriod, cRecType
          SELECT temphist
          INDEX on cwellid+hyear+hperiod TAG wellprd
   SELECT wellhist
   IF tlDirect
      SELE wellhist
      SCAN FOR nrunno = tnRunNo AND cRunYear = tcRunyear
         m.cWellID  = cWellID
         m.hYear    = hYear
         m.hPeriod  = hPeriod
         m.hdate    = hdate
         m.cRecType = cRecType
         m.cRunYear = cRunYear
         m.nrunno   = nrunno

         SELECT temphist
         SET ORDER to wellprd
         IF SEEK(m.cwellid+m.hyear+m.hperiod)
            SCATTER MEMVAR
            WAIT WIND NOWAIT 'Processing Well: ' + TRIM(m.cWellID) + ' Period: ' + m.hYear+'/'+m.hPeriod
            SELECT wellhist
            REPLACE nroyint WITH m.nroyalty, ;
                    nwrkint WITH m.nworking
         ENDIF    
      ENDSCAN
   ELSE
      SCAN FOR nrunno = tnRunNo AND cRunYear = tcRunyear
         m.cWellID  = cWellID
         m.hYear    = hYear
         m.hPeriod  = hPeriod
         m.hdate    = hdate
         m.cRecType = cRecType
         m.cRunYear = cRunYear
         m.nrunno   = nrunno

         SELECT cWellID, hYear, hPeriod, cRecType, ;
            SUM(IIF(cTypeInv='W',nnetcheck,0000000.00)) AS nworking, ;
            SUM(IIF(INLIST(cTypeInv,'L','O'),nnetcheck,0000000.00)) AS nroyalty ;
            FROM disbhist WITH (buffering=.t.);
            WHERE cWellID = m.cWellID ;
            AND hYear+hPeriod = m.hYear+m.hPeriod ;
            AND cRunYear = m.cRunYear  ;
            AND nrunno = m.nrunno  ;
            AND lProgram = .F. ;
            AND cRecType = m.cRecType ;
            INTO CURSOR temphist ;
            ORDER BY cWellID, hYear, hPeriod, cRecType ;
            GROUP BY cWellID, hYear, hPeriod, cRecType

         IF _TALLY = 0
            LOOP
         ENDIF
         SELECT temphist
         SCAN
            SCATTER MEMVAR
            WAIT WIND NOWAIT 'Processing Well: ' + TRIM(m.cWellID) + ' Period: ' + m.hYear+'/'+m.hPeriod
            SELECT wellhist
            LOCATE FOR cWellID+hYear+hPeriod = m.cWellID+m.hYear+m.hPeriod AND cRecType = m.cRecType AND cRunYear = m.cRunYear AND nrunno = m.nrunno
            IF FOUND()
               REPLACE nroyint WITH m.nroyalty
               REPLACE nwrkint WITH m.nworking
            ENDIF
            SELECT temphist
         ENDSCAN
      ENDSCAN
   ENDIF
ELSE
   SELECT wellhist
   IF tlDirect
      SELE wellhist
      SCAN
         m.cWellID  = cWellID
         m.hYear    = hYear
         m.hPeriod  = hPeriod
         m.hdate    = hdate
         m.cRecType = cRecType
         m.cRunYear = cRunYear
         m.nrunno   = nrunno

         SELECT cWellID, hYear, hPeriod, cRecType, ;
            SUM(IIF(cTypeInv='W',noilrev+ngasrev+nothrev+ntrprev+nmiscrev1+nmiscrev2-nsevtaxes-nexpense-ntotale1-ntotale2-ntotale3-ntotale4-ntotale5-ntotalea-ntotaleb,0000000.00)) AS nworking, ;
            SUM(IIF(INLIST(cTypeInv,'L','O'),noilrev+ngasrev+nothrev+ntrprev+nmiscrev1+nmiscrev2+nflatrate-nsevtaxes-nexpense-ntotale1-ntotale2-ntotale3-ntotale4-ntotale5-ntotalea-ntotaleb,0000000.00)) AS nroyalty ;
            FROM disbhist WITH (buffering=.t.);
            WHERE cWellID = m.cWellID ;
            AND hYear+hPeriod = m.hYear+m.hPeriod ;
            AND IIF(not EMPTY(cRunYear_In),cRunYear_In = m.cRunYear,cRunYear = m.cRunYear)  ;
            AND IIF(not EMPTY(cRunYear_In),nRunNo_In = m.nRunNo,nrunno = m.nrunno)  ;
            AND lProgram = .F. ;
            AND cRecType = m.cRecType ;
            INTO CURSOR temphist ;
            ORDER BY cWellID, hYear, hPeriod, cRecType ;
            GROUP BY cWellID, cRunYear, nrunno, hYear, hPeriod, cRecType

         SELECT temphist
         SCAN
            SCATTER MEMVAR
            WAIT WIND NOWAIT 'Processing Well: ' + TRIM(m.cWellID) + ' Period: ' + m.hYear+'/'+m.hPeriod
            SELECT wellhist
            LOCATE FOR cWellID+hYear+hPeriod = m.cWellID+m.hYear+m.hPeriod AND cRecType = m.cRecType AND cRunYear = m.cRunYear AND nrunno = m.nrunno
            IF FOUND()
               REPLACE nroyint WITH m.nroyalty, ;
                  nwrkint WITH m.nworking
            ENDIF
            SELECT temphist
         ENDSCAN
         
         SELECT cWellID, hYear, hPeriod, cRecType, nRunNo_In, cRunYear_In, ;
            SUM(IIF(cTypeInv='W',noilrev+ngasrev+nothrev+ntrprev+nmiscrev1+nmiscrev2-nsevtaxes-nexpense-ntotale1-ntotale2-ntotale3-ntotale4-ntotale5-ntotalea-ntotaleb,0000000.00)) AS nworking, ;
            SUM(IIF(INLIST(cTypeInv,'L','O'),noilrev+ngasrev+nothrev+ntrprev+nmiscrev1+nmiscrev2+nflatrate-nsevtaxes-nexpense-ntotale1-ntotale2-ntotale3-ntotale4-ntotale5-ntotalea-ntotaleb,0000000.00)) AS nroyalty ;
            FROM suspense WITH (buffering=.t.);
            WHERE cWellID = m.cWellID ;
            AND hYear+hPeriod = m.hYear+m.hPeriod ;
            AND cRunYear_In = m.cRunYear AND nRunNo_In = m.nRunNo  ;
            AND lProgram = .F. ;
            AND cRecType = m.cRecType ;
            INTO CURSOR temphist ;
            ORDER BY cWellID, hYear, hPeriod, cRecType ;
            GROUP BY cWellID, cRunYear, nrunno, hYear, hPeriod, cRecType

         SELECT temphist
         SCAN
            SCATTER MEMVAR
            WAIT WIND NOWAIT 'Processing Well: ' + TRIM(m.cWellID) + ' Period: ' + m.hYear+'/'+m.hPeriod
            SELECT wellhist
            LOCATE FOR cWellID+hYear+hPeriod = m.cWellID+m.hYear+m.hPeriod AND cRecType = m.cRecType AND cRunYear = m.cRunYear_In AND nrunno = m.nrunno_In
            IF FOUND()
               REPLACE nroyint WITH m.nroyalty, ;
                  nwrkint WITH m.nworking
            ENDIF
            SELECT temphist
         ENDSCAN
      ENDSCAN
   ELSE
      SCAN
         m.cWellID  = cWellID
         m.hYear    = hYear
         m.hPeriod  = hPeriod
         m.hdate    = hdate
         m.cRecType = cRecType
         m.cRunYear = cRunYear
         m.nrunno   = nrunno

         SELECT cWellID, hYear, hPeriod, cRecType, ;
            SUM(IIF(cTypeInv='W',nnetcheck,0000000.00)) AS nworking, ;
            SUM(IIF(INLIST(cTypeInv,'L','O'),nnetcheck,0000000.00)) AS nroyalty ;
            FROM disbhist WITH (buffering=.t.);
            WHERE cWellID = m.cWellID ;
            AND hYear+hPeriod = m.hYear+m.hPeriod ;
            AND IIF(not EMPTY(cRunYear_In),cRunYear_In = m.cRunYear,cRunYear = m.cRunYear)  ;
            AND IIF(not EMPTY(cRunYear_In),nRunNo_In = m.nRunNo,nrunno = m.nrunno)  ;
            AND lProgram = .F. ;
            AND cRecType = m.cRecType ;
            INTO CURSOR temphist ;
            ORDER BY cWellID, hYear, hPeriod, cRecType ;
            GROUP BY cWellID, hYear, hPeriod, cRecType
         
         SELECT temphist
         SCAN
            SCATTER MEMVAR
            WAIT WIND NOWAIT 'Processing Well: ' + TRIM(m.cWellID) + ' Period: ' + m.hYear+'/'+m.hPeriod
            SELECT wellhist
            LOCATE FOR cWellID+hYear+hPeriod = m.cWellID+m.hYear+m.hPeriod AND cRecType = m.cRecType AND cRunYear = m.cRunYear AND nrunno = m.nrunno
            IF FOUND()
               REPLACE nroyint WITH m.nroyalty
               REPLACE nwrkint WITH m.nworking
            ENDIF
            SELECT temphist
         ENDSCAN
         
         SELECT cWellID, hYear, hPeriod, cRecType, nRunNo_In, cRunYear_In,;
            SUM(IIF(cTypeInv='W',nnetcheck,0000000.00)) AS nworking, ;
            SUM(IIF(INLIST(cTypeInv,'L','O'),nnetcheck,0000000.00)) AS nroyalty ;
            FROM suspense WITH (buffering=.t.);
            WHERE cWellID = m.cWellID ;
            AND hYear+hPeriod = m.hYear+m.hPeriod ;
            AND ((cRunYear = m.cRunYear  ;
            AND nrunno = m.nrunno) OR (cRunYear_In = m.cRunYear AND nRunNo_In = m.nRunNo))  ;
            AND lProgram = .F. ;
            AND cRecType = m.cRecType ;
            INTO CURSOR temphist ;
            ORDER BY cWellID, hYear, hPeriod, cRecType ;
            GROUP BY cWellID, hYear, hPeriod, cRecType
         
         SELECT temphist
         SCAN
            SCATTER MEMVAR
            WAIT WIND NOWAIT 'Processing Well: ' + TRIM(m.cWellID) + ' Period: ' + m.hYear+'/'+m.hPeriod
            SELECT wellhist
            LOCATE FOR cWellID+hYear+hPeriod = m.cWellID+m.hYear+m.hPeriod AND cRecType = m.cRecType AND cRunYear = m.cRunYear_In AND nrunno = m.nrunno_In
            IF FOUND()
               REPLACE nroyint WITH m.nroyalty
               REPLACE nwrkint WITH m.nworking
            ENDIF
            SELECT temphist
         ENDSCAN
      ENDSCAN
   ENDIF
ENDIF

WAIT CLEAR

IF USED('temphist')
   USE IN temphist
ENDIF


*
* SherWare Utility Functions and Procedures
*
******************
PROCEDURE setstep
******************

   TRY
* Sets debugging on if the debug.txt file exists
      IF FILE('datafiles\setstep.txt')
         SET
         SET STEP ON
      ENDIF
   CATCH
   ENDTRY
   RETURN
ENDPROC

******************
FUNCTION swRound
******************
   LPARA tnAmount, tnDec
   LOCAL lnx, lnAmount

   IF EMPTY(tnDec)
      tnDec = 2
   ENDIF
   lnAmount = tnAmount

   TRY

* Commenting this out because I can't justify to why we did this - pws - 8/21/22
*!*      FOR lnx = 30 TO tnDec STEP - 1
*!*         lnAmount = ROUND(lnAmount, lnx)
*!*      ENDFOR
      lnAmount = ROUND(lnAmount, tnDec)

   CATCH TO loError
      DO errorlog WITH 'SWRound', loError.ERRORNO, SYS(16), loError.ERRORNO, loError.MESSAGE
   ENDTRY

   RETURN (lnAmount)

ENDFUNC

*********************
PROCEDURE swOldDOI
*********************
   LPARAMETERS tnRunNo, tcRunYear, tcGroup
   LOCAL lcrunyear, llFound, x, Y, lnx, lny

   DIMENSION laTemp[1, 1], laTempx[1, 1]

   lcrunyear = tcRunYear + PADL(TRANSFORM(tnRunNo), 3, '0')

   IF USED('wellinv_tmp')
      SELECT wellinv_tmp
* Wrap this in a TRY/CATCH in case wellinv_tmp doesn't
* have a field nrunno
      TRY
         LOCATE FOR nrunno = tnRunNo AND crunyear = tcRunYear
         llFound = FOUND()
      CATCH
         llFound = .F.
      ENDTRY

      IF llFound
         RETURN
      ENDIF
   ENDIF

   SWSELECT('disbhist')
   lnx = AFIELDS(laTempx)
   SWSELECT('ownpcts')
   lny = AFIELDS(latempy)
   DIMENSION laTemp[lnx + lny - 1, 18]
   FOR x = 1 TO lnx
      FOR Y = 1 TO 18
         laTemp[x, y] = laTempx[x, y]
      ENDFOR
   ENDFOR
   FOR x = 1 TO lny - 1
      FOR Y = 1 TO 18
         laTemp[x + lnx, y] = latempy[x + 1, y]
      ENDFOR
   ENDFOR
   FOR x = 1 TO lnx + lny - 1
      laTemp[X, 7]   = ''
      laTemp[X, 8]   = ''
      laTemp[X, 9]   = ''
      laTemp[X, 10]   = ''
      laTemp[X, 11]   = ''
      laTemp[X, 12]   = ''
      laTemp[X, 13]   = ''
      laTemp[X, 14]   = ''
      laTemp[X, 15]   = ''
      laTemp[X, 18]   = ''
   ENDFOR
   CREATE CURSOR wellinv_tmp FROM ARRAY laTemp

   SELECT  ownpcts.*, ;
      disbhist.cownerid, ;
      disbhist.cwellid, ;
      disbhist.nrunno, ;
      disbhist.crunyear, ;
      disbhist.cDirect, ;
      disbhist.ctypeinv, ;
      disbhist.cTypeInt, ;
      disbhist.crectype ;
      FROM ownpcts, disbhist ;
      WHERE crectype = 'R' ;
      AND ((disbhist.crunyear + PADL(TRANSFORM(disbhist.nrunno), 3, '0') = lcrunyear ;
      AND EMPTY(csusptype)) ;
      OR (disbhist.crunyear_in + PADL(TRANSFORM(disbhist.nrunno_in), 3, '0') = lcrunyear)) ;
      AND ownpcts.ciddisb = disbhist.ciddisb ;
      INTO CURSOR temp READWRITE ;
      ORDER BY cownerid, cwellid, ctypeinv, cDirect, nrevgas ;
      GROUP BY cownerid, cwellid, ctypeinv, cDirect, nrevgas

   SELECT  * ;
      FROM suspense ;
      WHERE suspense.crunyear_in + PADL(TRANSFORM(suspense.nrunno_in), 3, '0') = lcrunyear ;
      INTO CURSOR temp1 ;
      ORDER BY cownerid, cwellid, ctypeinv, cDirect ;
      GROUP BY cownerid, cwellid, ctypeinv, cDirect

   SELECT temp
   APPEND FROM DBF('temp1')
   SELECT  * ;
      FROM temp ;
      INTO CURSOR temp2 ;
      ORDER BY cownerid, cwellid, ctypeinv, cDirect, nrevgas ;
      GROUP BY cownerid, cwellid, ctypeinv, cDirect, nrevgas
   SELECT wellinv_tmp
   APPEND FROM DBF('temp2')
   INDEX ON cwellid TAG cwellid
   USE IN temp
   USE IN temp1

*********************
FUNCTION isfilelocked
*********************
   LPARAMETERS tcFileName
   LOCAL llLocked, liHandle, lnDataSession, lnSavedSession

* Get the current datasession so it can be restored later
   lnSavedSession = SET('DataSession')

* Tests if file with a given name is already in use
* Parameter should contain full path to the file

   IF TYPE('tcFileName') # 'C'
      lcFileName = 'Wells'
   ELSE
      lcFileName = tcFileName
   ENDIF

   lnSessions = ASESSIONS(laSessions)

   IF lnSessions > 0
      FOR lnDataSession = 1 TO lnSessions
         lnSession = laSessions[lnDataSession]
         SET DATASESSION TO lnSession
         IF USED(lcFileName)
            USE IN (lcFileName)
         ENDIF
      ENDFOR
      IF EMPTY(JUSTEXT(lcFileName))
         lcFileName = ALLT(m.goapp.cdatafilepath) + TRIM(lcFileName) + '.dbf'
      ELSE
         lcFileName = ALLTRIM(m.goapp.cdatafilepath) + lcFileName
      ENDIF
   ENDIF

   llLocked = .F.
   IF FILE(lcFileName)
* File exists, to try to open it
      liHandle = FOPEN(lcFileName, 2)
      IF liHandle = -1
* File could not be opened
         llLocked = .T.
      ELSE
* File can be opened exclusive
         FCLOSE(liHandle)
      ENDIF
   ENDIF

   SET DATASESSION TO (lnSavedSession)
   RETURN (llLocked)
ENDFUNC

*********************
FUNCTION GetRunNo
*********************
   LPARA tcyear, tlnew, tcType, tlYear, tcGroup, tlLastRun, tnRunNo
   LOCAL lnrunno, lcyear, lcAlias, lcrunyear

* tcYear = run year
* tlNew  = get next run no for year
* tcType = 'R' - revenue runs  'J' - Jib runs
* tlYear = only return run year
* tcGroup = get the last run for this group
* tlLastRun = get the last closed run for this group

   lcAlias = ALIAS()

   IF TYPE('tcType') # 'C'
      tcType = 'R'
   ENDIF
   IF TYPE('tcGroup') # 'C'
      tcGroup = '**'
   ENDIF

   SWSELECT('sysctl')
*
*  Gets the next run no for the given year if tlNew = .t.
*  or gets the last run no for the given year if tlNew = .f.
*
   IF NOT tlLastRun
      SELE cyear, nrunno FROM sysctl WITH (BUFFERING = .T.) ;
         WHERE cTypeClose = tcType ;
         AND nrunno # 9999 ;
         AND crunyear = tcyear ;
         AND IIF(tcGroup = '**', .T., cGroup = tcGroup) ;
         AND NOT DELETED() ;
         INTO CURSOR temp ORDER BY crunyear, nrunno
   ELSE
      lcrunyear = tcyear + PADL(TRANSFORM(tnRunNo), 3, '0')
      SELE cyear, nrunno FROM sysctl WITH (BUFFERING = .T.) ;
         WHERE cTypeClose = tcType ;
         AND nrunno # 9999 ;
         AND crunyear + PADL(TRANSFORM(nrunno), 3, '0') < lcrunyear ;
         AND IIF(tcGroup = '**', .T., cGroup = tcGroup) ;
         AND NOT DELETED() ;
         INTO CURSOR temp ORDER BY cyear, nrunno

   ENDIF
   SELE temp
   IF RECC() > 0
      GO BOTT
      IF tlnew
         lnrunno = nrunno + 1
         lcyear    = cyear
      ELSE
         IF tlLastRun AND RECCOUNT() > 1
            lnrunno   = nrunno
            lcyear   = cyear
         ELSE
            lnrunno   = nrunno
            lcyear   = cyear
         ENDIF
      ENDIF
   ELSE
      lcyear = tcyear
      IF tlnew
         lnrunno = 1
      ELSE
         lnrunno = 0
      ENDIF
   ENDIF

   IF USED('temprun')
      USE IN temprun
   ENDIF

   IF NOT EMPTY(lcAlias)  &&  Only select if not empty - BH 05/03/07
      SELECT (lcAlias)
   ENDIF

   DO CASE
      CASE tlLastRun
         lcrunyear = lcyear + PADL(TRANSFORM(lnrunno), 3, '0')
         RETURN (lcrunyear)
      CASE NOT tlYear
         RETURN (lnrunno)
      OTHERWISE
         RETURN (lcyear)
   ENDCASE

ENDFUNC

**********************
FUNCTION UpdateDBC(lcDataFilePath)
*********************
   LOCAL lnHandle, llReturn

   llReturn = .T.
   CLOSE DATABASES ALL

   TRY
      IF NOT USED('newdbc')
         USE newdbc\newdbc.DBC IN 0
      ENDIF
      SELECT newdbc
      COPY TO (lcDataFilePath + 'appdata.dbc') PRODUCTION
      USE IN newdbc
      lnHandle = FOPEN(lcDataFilePath + 'appdata.dbc', 2)
      = FSEEK(lnHandle, 28)
      = FWRITE(lnHandle, CHR(7))
      = FCLOSE(lnHandle)
      USE (lcDataFilePath + 'appdata.dbc') IN 0 EXCL
      SELECT appdata
      REINDEX
      USE IN appdata
   CATCH TO loErr
      IF FILE(m.goapp.cCommonfolder + 'debugdata.txt')
         MESSAGEBOX('Error updating DBC: ' + loErr.MESSAGE,16,'UpdateDBC')
      ENDIF
      llReturn = .F.
   ENDTRY

   RETURN llReturn

**********************
PROCEDURE swclose
**********************
   LPARAMETERS lcAlias

   IF USED(lcAlias)
      USE IN (lcAlias)
   ENDIF

**********************
PROCEDURE swstrtran
**********************
   LPARAMETERS lcString

* Remove invalid chars from string

   lcString   = STRTRAN(lcString, ',', '')
   lcString   = STRTRAN(lcString, '#', '')
   lcString   = STRTRAN(lcString, '\', '')
   lcString   = STRTRAN(lcString, '/', '')
   lcString   = STRTRAN(lcString, '@', '')
   lcString = STRTRAN(lcString, '&', '')
   lcString = STRTRAN(lcString, '*', '')
   lcString = STRTRAN(lcString, '%', '')
   lcString = STRTRAN(lcString, '$', '')
   lcString = STRTRAN(lcString, '?', '')
   lcString = STRTRAN(lcString, '!', '')
   lcString = STRTRAN(lcString, '^', '')

   RETURN lcString

**********************
PROCEDURE SWSELECT
**********************
   LPARAMETERS lcAlias, lBuffered, lcNewAlias
   LOCAL lnBufferLevel, lcFile, loError, llReturn

   llReturn = .T.

* SherWare version of select statement that will open
* the table if it is not open
   TRY
      IF NOT EMPTY(lcNewAlias)
         IF NOT USED(lcNewAlias)
            IF 'compmast' $ LOWER(lcAlias) OR ;
                  'partnerpost' $ LOWER(lcAlias) OR ;
                  'partnerinterest' $ LOWER(lcAlias) OR ;
                  'logins' $ LOWER(lcAlias)
               USE (ALLTRIM(m.goapp.cCommonfolder) + lcAlias) IN 0 AGAIN ALIAS (lcNewAlias)
            ELSE
               USE (ALLTRIM(m.goapp.cdatafilepath) + lcAlias) IN 0 AGAIN ALIAS (lcNewAlias)
            ENDIF
            SELECT (lcNewAlias)
* Only set buffering if we're asked to and
* we're not in a transaction
            IF lBuffered AND TXNLEVEL() = 0
               llReturn = CURSORSETPROP("Buffering", 5)
            ENDIF
         ELSE
            SELECT (lcNewAlias)
* Check to see if the bufferlevel is correct and set it correctly if not
            lnBufferLevel = CURSORGETPROP("Buffering")
            IF lBuffered AND TXNLEVEL() = 0 AND lnBufferLevel # 5
               llReturn = CURSORSETPROP("Buffering", 5)
            ENDIF
         ENDIF
      ELSE
         IF NOT USED(lcAlias)
            IF 'compmast' $ LOWER(lcAlias) OR ;
                  'partnerpost' $ LOWER(lcAlias) OR ;
                  'partnerinterest' $ LOWER(lcAlias) OR ;
                  'logins' $ LOWER(lcAlias)
               USE (ALLTRIM(m.goapp.cCommonfolder) + lcAlias) IN 0 AGAIN
            ELSE
               USE (ALLTRIM(m.goapp.cdatafilepath) + lcAlias) IN 0 AGAIN
            ENDIF
            SELECT (lcAlias)
* Only set buffering if we're asked to and
* we're not in a transaction
            IF lBuffered AND TXNLEVEL() = 0
               = CURSORSETPROP("Buffering", 5)
            ENDIF
         ELSE
            SELECT (lcAlias)
* Check to see if the bufferlevel is correct and set it correctly if not
            lnBufferLevel = CURSORGETPROP("Buffering")
            IF lBuffered AND TXNLEVEL() = 0 AND lnBufferLevel # 5
               = CURSORSETPROP("Buffering", 5)
            ENDIF
         ENDIF
      ENDIF
   CATCH TO loError
      DO errorlog WITH 'SWSelect', loError.ERRORNO, SYS(16), loError.ERRORNO, loError.MESSAGE, '', loError, .F., .F.
*MESSAGEBOX('Unable to select the table ' + ALLTRIM(lcAlias) + '. Check the System Log found under Other Reports for more information.', 16, 'Problem Encountered')
      llReturn = .F.
   ENDTRY

   RETURN llReturn

**********************
PROCEDURE swActivity
**********************
   LPARAMETERS lcWellID, lcGroup, llJIB, lcType
   LOCAL llAllWells, llGroup

* Checks to see if there is any unprocessed revenue or expenses
* for the given well (if one is passed), group (if one is passed)
* otherwise checks for activity in all wells.

   SWSELECT('income')
   SWSELECT('expense')
   SWSELECT('wells')
   SWSELECT('incsusp')
   SWSELECT('expsusp')

   IF VARTYPE(lcWellID) # 'C'
      llAllWells = .T.
   ELSE
      llAllWells = .F.
   ENDIF

   IF VARTYPE(lcGroup) # 'C'
      llGroup = .F.
   ELSE
      llGroup = .T.
   ENDIF

   IF VARTYPE(lcType) # 'C'
      lcType = 'B'
   ENDIF

   llReturn = .F.

   IF llAllWells
      IF llGroup
         SELECT cwellid FROM wells WHERE cGroup == lcGroup INTO CURSOR wellgroup
         IF _TALLY > 0
            IF INLIST(lcType, 'B', 'R')
               SELECT cwellid FROM income WHERE nrunno = 0 AND cwellid IN (SELECT cwellid FROM wellgroup) AND lCSTran INTO CURSOR tempinc
               llReturn = _TALLY > 0
               IF NOT llReturn
                  SELECT cwellid FROM incsusp WHERE cwellid IN (SELECT cwellid FROM wellgroup) AND lCSTran INTO CURSOR tempinc
                  llReturn = _TALLY > 0
               ENDIF
            ENDIF
            IF INLIST(lcType, 'B', 'E')
               IF llJIB
                  SELECT cwellid FROM expense WHERE nrunnojib = 0 AND cyear # 'FIXD' AND cwellid IN (SELECT cwellid FROM wellgroup) AND lAPTRan INTO CURSOR tempexp
                  llReturn = _TALLY > 0
               ELSE
                  SELECT cwellid FROM expense WHERE nrunnorev = 0 AND cyear # 'FIXD' AND cwellid IN (SELECT cwellid FROM wellgroup) AND lAPTRan INTO CURSOR tempexp
                  llReturn = _TALLY > 0
                  IF NOT llReturn
                     SELECT cwellid FROM expsusp WHERE  cwellid IN (SELECT cwellid FROM wellgroup) AND lAPTRan INTO CURSOR tempexp
                     llReturn = _TALLY > 0
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
      ELSE
         IF INLIST(lcType, 'B', 'R')
            SELECT cwellid FROM income WHERE nrunno = 0 AND lCSTran INTO CURSOR tempinc
            llReturn = _TALLY > 0
            IF NOT llReturn
               SELECT cwellid FROM incsusp WHERE lCSTran INTO CURSOR tempinc
               llReturn = _TALLY > 0
            ENDIF
         ENDIF
         IF INLIST(lcType, 'B', 'E')
            IF llJIB
               SELECT cwellid FROM expense WHERE nrunnojib = 0 AND cyear # 'FIXD' AND lAPTRan INTO CURSOR tempexp
               llReturn = _TALLY > 0
            ELSE
               SELECT cwellid FROM expense WHERE nrunnorev = 0 AND cyear # 'FIXD' AND lAPTRan INTO CURSOR tempexp
               llReturn = _TALLY > 0
               IF NOT llReturn
                  SELECT cwellid FROM expsusp WHERE lAPTRan INTO CURSOR tempexp
                  llReturn = _TALLY > 0
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   ELSE
      IF INLIST(lcType, 'B', 'E')
         IF llJIB
            SELECT cwellid FROM expense WHERE cwellid == lcWellID AND nrunnojib = 0 AND cyear # 'FIXD' AND lAPTRan INTO CURSOR tempexp
            llReturn = _TALLY > 0
         ELSE
            SELECT cwellid FROM expense WHERE cwellid == lcWellID AND nrunnorev = 0 AND cyear # 'FIXD' AND lAPTRan INTO CURSOR tempexp
            llReturn = _TALLY > 0
         ENDIF
         IF NOT llReturn
            SELECT cwellid FROM expsusp WHERE cwellid == lcWellID AND lAPTRan INTO CURSOR tempexp
            llReturn = _TALLY > 0
         ENDIF
      ENDIF
      IF INLIST(lcType, 'B', 'R')
         SELECT cwellid FROM incsusp WHERE cwellid == lcWellID AND lCSTran INTO CURSOR tempinc
         llReturn = _TALLY > 0
         IF NOT llReturn
            SELECT cwellid FROM income WHERE cwellid == lcWellID AND nrunno = 0 AND lCSTran INTO CURSOR tempinc
            llReturn = _TALLY > 0
         ENDIF
      ENDIF
   ENDIF

   RETURN (llReturn)

*-- Calculates the days on based on the beginning and ending ranges passed.
*****************************************************
PROCEDURE CalcDaysOn
*****************************************************
   LPARA lcrange1, lcrange2
   LOCAL ldDate1, ldDate2, lnDays, lcyear, lcrange1, lcrange2
   lcAlias = ALIAS()
*
*  Get the current year to use to build the date.
*
   lcyear   = STR(YEAR(DATE()), 4)
*
*  Check to see if we're supposed to calculate the dayson
*
   SELECT options
   GO TOP
   glCalcDays = .T.
   SELECT (lcAlias)
*
*  Calculate the number of days between the ranges
*
   IF glCalcDays
      IF LEFT(lcrange1, 2) > LEFT(lcrange2, 2)
         lcYear1 = STR(VAL(lcyear) + 1, 4)
      ELSE
         IF LEFT(lcrange1, 2) = LEFT(lcrange2, 2)
            IF RIGHT(lcrange1, 2) > RIGHT(lcrange2, 2)
               lcYear1 = STR(VAL(lcyear) + 1, 4)
            ELSE
               lcYear1 = lcyear
            ENDIF
         ELSE
            lcYear1 = lcyear
         ENDIF
      ENDIF
      ldDate1 = CTOD(lcrange1 + '/' + lcyear)
      ldDate2 = CTOD(lcrange2 + '/' + lcYear1)
      lnDays  = ldDate2 - ldDate1
      RETURN (lnDays)
   ELSE
      RETURN (0)
   ENDIF
ENDPROC

**********************
PROCEDURE swopenforms
**********************
   LPARAMETERS tcFormName
   LOCAL ix, lnOKForms, lnFormCount, fh, lcName, lnTotalForms, lcFormName, llReturn

   lnTotalForms   = _SCREEN.FORMCOUNT
   lnOKForms   = 0
   llReturn      = .F.
   lnFormCount   = 0
** Put a Try/Catch around this because if it craps out we'll just return .F.
** rather than throw up all over the user.
   TRY
      tcFormName   = LOWER(TRANSFORM(tcFormName))

      IF lnTotalForms > 0
         lcName = SYS(3) + '.txt'
         FOR ix = 1 TO lnTotalForms
            m.oForm = _SCREEN.FORMS[m.ix]
            IF VARTYPE(m.oForm) # 'O'
               LOOP
            ENDIF
            TRY
               lcFormName = LOWER(m.oForm.NAME)
            CATCH
               lcFormName = 'dbcxmgr'
            ENDTRY
            m.oForm.NAME = lcFormName
            DO CASE
               CASE m.oForm.NAME = 'dbcxmgr'
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME = ' '
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME = 'tbrmaintoolbar'
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME = 'tbrdevelopmenttoolbarcustom'
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME = 'frmsetlogonpassword'
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME == tcFormName
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME == 'tbrprojecttools'
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME == 'tbrlaunchpad'
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME == 'frmprojectbuilder'
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME == 'backgroundform'
                  lnOKForms = lnOKForms + 1
               CASE m.oForm.NAME == 'backgroundformtlf'
                  lnOKForms = lnOKForms + 1
               CASE 'formcompsetup' $ m.oForm.NAME
                  lnOKForms = lnOKForms + 1
               CASE 'progress' $ m.oForm.NAME
                  lnOKForms = lnOKForms + 1
               CASE 'convert' $ LOWER(m.oForm.NAME)  && File convert form
                  lnOKForms = lnOKForms + 1
               CASE 'home' $ LOWER(m.oForm.NAME)  && home
                  lnOKForms = lnOKForms + 1
               CASE 'news' $ LOWER(m.oForm.NAME)  && News
                  lnOKForms = lnOKForms + 1
               CASE 'frmlogon' $ LOWER(m.oForm.NAME)  && Login
                  lnOKForms = lnOKForms + 1
            ENDCASE
         ENDFOR
         IF lnTotalForms - lnOKForms > lnFormCount
            IF FILE('datafiles\formname.cfg')
               WAIT WINDOW 'Open Form = ' + lcFormName
            ENDIF
            llReturn = .T.
         ELSE
            llReturn = .F.
         ENDIF
      ELSE
         llReturn = .F.
      ENDIF
   CATCH
   ENDTRY

   RETURN (llReturn)

**********************
PROCEDURE swdoicheck
**********************
   LPARAMETERS tcGroup, tdRevDate, tdExpDate, cDeck
   LOCAL llReturn

   oMessage = findglobalobject('cmMessage')

   IF NOT USED('wells')
      USE wells IN 0
   ENDIF
   IF NOT USED('income')
      USE income IN 0
   ENDIF
   IF NOT USED('expense')
      USE expense IN 0
   ENDIF

   CREATE CURSOR tempdoi ;
      (cwellid  c(10), ;
      cDeck   c(10), ;
      loil     l, ;
      lgas     l, ;
      loth     l, ;
      ltrans   l, ;
      lmisc1   l, ;
      lmisc2   l, ;
      lclass0  l, ;
      lclass1  l, ;
      lclass2  l, ;
      lclass3  l, ;
      lclass4  l, ;
      lclass5  l, ;
      lclassa  l, ;
      lclassb  l, ;
      lotax1   l, ;
      lotax2   l, ;
      lotax3   l, ;
      lotax4   l, ;
      lgtax1   l, ;
      lgtax2   l, ;
      lgtax3   l, ;
      lgtax4   l, ;
      lPlug    l)

   SELECT wells.cwellid, wellinv.cDeck FROM wells JOIN wellinv ON wellinv.cwellid = wells.cwellid ;
      WHERE wells.cGroup == tcGroup ;
      AND NOT INLIST(cWellStat, 'I', 'S', 'P') ;
      ORDER BY wells.cwellid, wellinv.cDeck ;
      GROUP BY wells.cwellid, wellinv.cDeck ;
      INTO CURSOR tempwell  &&  Exclude the statuses that won't be processed anyway - BH 08/13/2008

   SELECT tempdoi
   APPEND FROM DBF('tempwell')

   SELECT tempwell
   SCAN
      SCATTER MEMVAR

      SELECT tempdoi
      LOCATE FOR cwellid == m.cwellid AND cDeck == m.cDeck
      IF FOUND()

         IF VARTYPE(tdRevDate) = 'D'
* Only process revenue if a revenue date was passed
            SELECT income
            SCAN FOR cwellid == m.cwellid AND nrunno = 0 AND dRevDate <= tdRevDate AND cDeck = m.cDeck
               m.csource = csource
               IF m.csource = 'BBL'
                  SELECT tempdoi
                  REPLACE loil WITH .T., ;
                     lotax1 WITH .T.
               ENDIF
               IF m.csource = 'MCF'
                  SELECT tempdoi
                  REPLACE lgas WITH .T., ;
                     lgtax1 WITH .T.
               ENDIF
               IF m.csource = 'OTH'
                  SELECT tempdoi
                  REPLACE loth WITH .T.
               ENDIF
               IF m.csource = 'TRANS'
                  SELECT tempdoi
                  REPLACE ltrans WITH .T.
               ENDIF
               IF m.csource = 'MISC1'
                  SELECT tempdoi
                  REPLACE lmisc1 WITH .T.
               ENDIF
               IF m.csource = 'MISC2'
                  SELECT tempdoi
                  REPLACE lmisc2 WITH .T.
               ENDIF
            ENDSCAN
         ENDIF

         IF VARTYPE(tdExpDate) = 'D'
* Only process expenses when an expense date is passed.
            SELECT expense
            SCAN FOR cwellid == m.cwellid AND (nrunnorev = 0 OR nrunnojib = 0) ;
                  AND cDeck = m.cDeck ;
                  AND dExpDate <= tdExpDate AND cyear # 'FIXD'  &&  Exclude FIXD entries - BH 08/13/2008
               m.cexpclass = cexpclass
               IF m.cexpclass = '0'
                  SELECT tempdoi
                  REPLACE lclass0 WITH .T.
               ENDIF
               IF m.cexpclass = '1'
                  SELECT tempdoi
                  REPLACE lclass1 WITH .T.
               ENDIF
               IF m.cexpclass = '2'
                  SELECT tempdoi
                  REPLACE lclass2 WITH .T.
               ENDIF
               IF m.cexpclass = '3'
                  SELECT tempdoi
                  REPLACE lclass3 WITH .T.
               ENDIF
               IF m.cexpclass = '4'
                  SELECT tempdoi
                  REPLACE lclass4 WITH .T.
               ENDIF
               IF m.cexpclass = '5'
                  SELECT tempdoi
                  REPLACE lclass5 WITH .T.
               ENDIF
               IF m.cexpclass = 'A'
                  SELECT tempdoi
                  REPLACE lclassa WITH .T.
               ENDIF
               IF m.cexpclass = 'B'
                  SELECT tempdoi
                  REPLACE lclassb WITH .T.
               ENDIF
               IF m.cexpclass = 'P'
                  SELECT tempdoi
                  REPLACE lPlug WITH .T.
               ENDIF
            ENDSCAN
         ENDIF
      ENDIF
   ENDSCAN

   llReturn = .T.

   IF NOT USED('wellinv')
      USE wellinv IN 0
   ENDIF

   SELECT tempdoi
   SCAN
      SCATTER MEMVAR

      IF m.loil
         SELECT SUM(nrevoil) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There is oil revenue to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lgas
         SELECT SUM(nrevgas) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There is gas revenue to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.loth
         SELECT SUM(nrevoth) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There is OTH revenue to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lmisc1
         SELECT SUM(nrevMisc1) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There is MISC1 revenue to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lmisc2
         SELECT SUM(nrevMisc2) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There is MISC2 revenue to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.ltrans
         SELECT SUM(nrevTrp) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There is TRP revenue to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lclass0
         SELECT SUM(nworkint) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There are working interest expenses to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lclass1
         SELECT SUM(nIntClass1) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There are Class 1 expenses to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lclass2
         SELECT SUM(nIntClass2) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There are Class 2 expenses to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lclass3
         SELECT SUM(nIntClass3) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There are Class 3 expenses to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lclass4
         SELECT SUM(nIntClass4) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There are Class 4 expenses to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lclass5
         SELECT SUM(nIntClass5) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There are Class 5 expenses to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lclassa
         SELECT SUM(nACPInt) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There are ACP expenses to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lclassb
         SELECT SUM(nBCPInt) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There are BCP expenses to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
      IF m.lPlug
         SELECT SUM(nPlugPct) AS npct FROM wellinv WHERE cwellid == m.cwellid AND cDeck = m.cDeck  INTO CURSOR temp
         SELECT temp
         IF npct # 100
            oMessage.warning('There are Plugging expenses to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
            RETURN .F.
         ENDIF
      ENDIF
*!*       IF m.lotax1
*!*           SELECT SUM(nrevtax1) AS npct FROM wellinv WHERE cwellid == m.cwellid INTO CURSOR temp
*!*           SELECT temp
*!*           IF npct <> 100
*!*               oMessage.warning('There are oil taxes to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
*!*               RETURN .F.
*!*           ENDIF
*!*       ENDIF
*!*       IF m.lgtax1
*!*           SELECT SUM(nrevtax2) AS npct FROM wellinv WHERE cwellid == m.cwellid INTO CURSOR temp
*!*           SELECT temp
*!*           IF npct <> 100
*!*               oMessage.warning('There are gas taxes to be processed for well: ' + ALLTRIM(m.cwellid) + ' but the Division of Interests does not total 100%.  Please correct before proceeding.')
*!*               RETURN .F.
*!*           ENDIF
*!*       ENDIF
      IF NOT llReturn
         IF NOT swActivity(m.cwellid)
            llReturn = .T.
         ENDIF
      ENDIF
   ENDSCAN

   RETURN (llReturn)


*************************************
PROCEDURE swUnAllRpt
*************************************
LPARAMETERS tcWell1, tcWellName1, tcWell2, tcWellName2, tnSort, tnReport, tdDate1, tdDate2, tlNewRun, tcGroup, tlSelected
LOCAL lWhere, lBetween, lOrderBy, llReturn, loError

   llReturn = .T.
   SET SAFETY OFF

TRY
    IF tcGroup # '**'  &&  If a group is specified
        lWhere = 'AND wells.cgroup = tcGroup'
    ELSE  && No group specified
        lWhere = ''
    ENDIF

    IF NOT tlSelected
        SELECT  cwellid AS cid ;
            FROM wells ;
            WHERE BETWEEN(cwellid, tcWell1, tcWell2) ;
            INTO CURSOR SELECTED ;
            ORDER BY cid
    ENDIF

    oDist = CREATEOBJECT('distproc', tcWell1, tcWell2, ;
          '01', '1980', ;
          tcGroup, 'W', DATE(), .F.)


    lBetween = 'wells.cwellid in (select cid from selected)'
    DO CASE
    CASE tnSort = 1  &&  If sorting by well ID
        lOrderBy     = 'wells.cwellid'
        m.cSortOrder = 'Well ID'
    CASE tnSort = 2 && Sorting by well name
        lOrderBy     = 'wells.cwellname'
        m.cSortOrder = 'Well Name'
    CASE tnSort = 3  &&  If sorting by well ID
        lOrderBy     = 'wells.cwellid'
        m.cSortOrder = 'Well ID'
    CASE tnSort = 4 && Sorting by well name
        lOrderBy     = 'wells.cwellname'
        m.cSortOrder = 'Well Name'
    ENDCASE

      CREATE CURSOR unalltmp ;
         (crptgroup    c(2), ;
           cprocess     c(1), ;
           cwellid      c(10), ;
           cwellname    c(30), ;
           cvendorid    c(10), ;
           cownerid     c(10), ;
           cpayee       c(30), ;
           ctaxcode     c(2), ;
           ctaxdesc     c(40), ;
           ccateg       c(20), ;
           cCatCode     c(4), ;
           cexpclass    c(1), ;
           crefid       c(15), ;
           nnetamt      N(12, 2), ;
           ngrossamt    N(12, 2), ;
           dDATE        D, ;
           crevkey      c(10), ;
           csource      c(5), ;
           cbatch       c(8), ;
           nunits       N(12, 5), ;
           nprice       N(9, 5), ;
           cGroup       c(2))

      IF tnReport = 1 OR tnReport = 3    && Report on Expenses
         SWSELECT('expsusp')
         SWSELECT('wells')
         WAIT WINDOW NOWAIT 'Processing Expenses...'
         SELECT  expsusp.cwellid, ;
                 'B' AS crptgroup, ;
                 wells.cwellname, ;
                 wells.cGroup, ;
                 expsusp.cvendorid, ;
                 expsusp.cpayee, ;
                 expsusp.ccateg, ;
                 expsusp.cCatCode, ;
                 expsusp.cownerid, ;
                 expsusp.crefid, ;
                 expsusp.cbatch, ;
                 expsusp.namount AS ngrossamt, ;
                 expsusp.dExpDate AS dDATE ;
             FROM expsusp, wells ;
             WHERE NOT lAllocated ;
                 AND &lBetween ;
                 AND expsusp.cwellid = wells.cwellid ;
                 &lWhere ;
             INTO CURSOR unalltmp1 ;
             ORDER BY &lOrderBy, expsusp.cvendorid

        IF _TALLY > 0
            IF m.goapp.lAMVersion
                SWSELECT('glmaster')
                SELECT unalltmp1
                SCAN
                    SCATTER MEMVAR
                    m.cprocess = 'A'
                    SWSELECT('glmaster')
                    SET ORDER TO glbatch
                    IF SEEK(m.cbatch)
                        m.dDATE = dDATE
                    ENDIF
                    IF BETWEEN(m.dDATE, tdDate1, tdDate2)
                        INSERT INTO unalltmp FROM MEMVAR
                    ENDIF
                ENDSCAN
            ELSE
                SELECT unalltmp1
                SCAN FOR BETWEEN(dDATE, tdDate1, tdDate2)
                    SCATTER MEMVAR
                    m.cprocess = 'A'
                    INSERT INTO unalltmp FROM MEMVAR
                ENDSCAN
            ENDIF
        ENDIF

        IF tlNewRun
            SELECT  expense.cwellid, ;
                'B' AS crptgroup, ;
                wells.cwellname, ;
                wells.cgroup + ' - ' + groups.cdesc as cgroup, ;
                expense.cvendorid, ;
                expense.cpayee, ;
                expense.ccateg, ;
                expense.cCatCode, ;
                expense.cownerid, ;
                expense.crefid, ;
                expense.cbatch, ;
                expense.cexpclass, ;
                expense.namount AS ngrossamt, ;
                expense.dExpDate AS dDATE ;
                FROM expense, wells, groups ;
                WHERE &lBetween ;
                AND (nrunnorev = 0 ;
                  AND nrunnojib = 0) ;
                AND cyear # 'FIXD' ;
                AND expense.cwellid = wells.cwellid ;
                AND wells.cgroup = groups.cgroup ;
                &lWhere ;
                INTO CURSOR unalltmp1 ;
                ORDER BY &lOrderBy, expense.cvendorid

            IF _TALLY > 0
                IF m.goapp.lAMVersion
                    SWSELECT('glmaster')
                    SELECT unalltmp1
                    SCAN
                        SCATTER MEMVAR
                        m.cprocess = 'B'
                        SWSELECT('glmaster')
                        SET ORDER TO glbatch
                        IF SEEK(m.cbatch)
                            m.dDATE = dDATE
                        ENDIF
* m.ngrossamt = swNetExp(m.ngrossamt, m.cwellid, .T., m.cexpclass, 'N')
                        IF BETWEEN(m.dDATE, tdDate1, tdDate2)
                            INSERT INTO unalltmp FROM MEMVAR
                        ENDIF
                    ENDSCAN
                ELSE
                    SELECT unalltmp1
                    SCAN FOR BETWEEN(dDATE, tdDate1, tdDate2)
                        SCATTER MEMVAR
                        m.cprocess = 'B'
* m.ngrossamt = swNetExp(m.ngrossamt, m.cwellid, .T., m.cexpclass, 'N')
                        INSERT INTO unalltmp FROM MEMVAR
                    ENDSCAN
                ENDIF
            ENDIF
        ENDIF
    ENDIF

    IF tnReport = 2 OR tnReport = 3    && Report on Income
        SWSELECT('revsrc')
        SWSELECT('incsusp')
        SWSELECT('wells')
        WAIT WINDOW NOWAIT 'Processing Revenue...'
        SELECT  incsusp.cwellid, ;
            'A' AS crptgroup, ;
            wells.cwellname, ;
            wells.cgroup + ' - ' + groups.cdesc as cgroup, ;
            incsusp.crevkey, ;
            revsrc.crevname AS cpayee, ;
            incsusp.csource, ;
            incsusp.nunits, ;
            incsusp.nprice, ;
            incsusp.cownerid, ;
            incsusp.crefid, ;
            incsusp.cbatch, ;
            incsusp.ntotalinc AS ngrossamt, ;
            incsusp.dRevDate AS dDATE ;
            FROM incsusp, wells, revsrc, groups ;
            WHERE NOT lAllocated ;
            AND &lBetween ;
            AND incsusp.cwellid = wells.cwellid ;
            AND wells.cgroup = groups.cgroup ;
            AND incsusp.crevkey = revsrc.crevkey ;
            &lWhere ;
            INTO CURSOR unalltmp1 ;
            ORDER BY &lOrderBy, incsusp.crevkey

        IF _TALLY > 0
            IF m.goapp.lAMVersion
                SWSELECT('glmaster')
                SELECT unalltmp1
                SCAN
                    SCATTER MEMVAR
                    m.cprocess = 'A'
                    SWSELECT('glmaster')
                    SET ORDER TO glbatch
                    IF SEEK(m.cbatch)
                        m.dDATE = dDATE
                    ENDIF
                    IF BETWEEN(m.dDATE, tdDate1, tdDate2)
                        INSERT INTO unalltmp FROM MEMVAR
                    ENDIF
                ENDSCAN
            ELSE
                SELECT unalltmp1
                SCAN FOR BETWEEN(dDATE, tdDate1, tdDate2)
                    SCATTER MEMVAR
                    m.cprocess = 'A'
                    INSERT INTO unalltmp FROM MEMVAR
                ENDSCAN
            ENDIF
        ENDIF

        IF tlNewRun
            SELECT  income.cwellid, ;
                'A' AS crptgroup, ;
                wells.cwellname, ;
                wells.cgroup + ' - ' + groups.cdesc as cgroup, ;
                income.crevkey, ;
                revsrc.crevname AS cpayee, ;
                income.csource, ;
                income.nunits, ;
                income.nprice, ;
                income.cownerid, ;
                income.crefid, ;
                income.ntotalinc AS ngrossamt, ;
                income.dRevDate AS dDATE, ;
                income.cbatch ;
                FROM income, wells, revsrc, groups ;
                WHERE &lBetween ;
                AND nrunno = 0 ;
                AND income.cwellid = wells.cwellid ;
                AND wells.cgroup = groups.cgroup ;
                AND income.crevkey = revsrc.crevkey ;
                &lWhere ;
                INTO CURSOR unalltmp1 ;
                ORDER BY &lOrderBy, income.crevkey

            IF _TALLY > 0
                IF m.goapp.lAMVersion
                    SWSELECT('glmaster')
                    SELECT unalltmp1
                    SCAN
                        SCATTER MEMVAR
                        m.cprocess = 'B'
                        SWSELECT('glmaster')
                        SET ORDER TO glbatch
                        IF SEEK(m.cbatch)
                            m.dDATE = dDATE
                        ENDIF
                        IF BETWEEN(m.dDATE, tdDate1, tdDate2)
                            INSERT INTO unalltmp FROM MEMVAR
                        ENDIF
                    ENDSCAN
                ELSE
                    SELECT unalltmp1
                    SCAN FOR BETWEEN(dDATE, tdDate1, tdDate2)
                        SCATTER MEMVAR
                        m.cprocess = 'B'
                        INSERT INTO unalltmp FROM MEMVAR
                    ENDSCAN
                ENDIF
            ENDIF
        ENDIF
    ENDIF

* Open the tax codes table
      SWSELECT('taxcodes')
* Open the expcat table
      SWSELECT('expcat')
      SET ORDER TO cCatCode

      SELECT unalltmp
      SET ORDER TO 0
      SCAN
         m.ngrossamt = ngrossamt
         m.crptgroup = crptgroup
         m.cwellid   = cwellid
         m.cexpclass = cexpclass
         m.csource   = csource
         m.nnetamt   = ngrossamt
         m.cCatCode  = cCatCode
         IF EMPTY(cownerid)  &&  Don't net out one man item entries - BH 8/26/04
            IF m.crptgroup = 'B'
                IF m.cCatCode = 'MKTG'
                    m.nnetamt = oDist.netrev(m.cwellid, m.ngrossamt, 'G', .F., .T., .F., ' ')
                ELSE
                    m.nnetamt = swNetExp(m.ngrossamt, m.cwellid, .T., m.cexpclass, 'B')
                ENDIF
            ELSE
                DO CASE
                CASE INLIST(m.csource, 'BBL', 'OTAX1', 'OTAX2', 'OTAX3', 'OTAX4')
                    IF m.csource = 'BBL'
                        m.nnetamt = oDist.netrev(m.cwellid, m.ngrossamt, 'O', .F., .T.)
                    ELSE  &&  Pass appropriate tax type, instead of just passing 'O' - BH 5-19-06
                        m.nnetamt = oDist.netrev(m.cwellid, m.ngrossamt, 'O' + RIGHT(TRIM(m.csource), 1), .F., .T.)
                    ENDIF
                CASE INLIST(m.csource, 'MCF', 'GTAX1', 'GTAX2', 'GTAX3', 'GTAX4')
                    IF m.csource = 'MCF'
                        m.nnetamt = oDist.netrev(m.cwellid, m.ngrossamt, 'G', .F., .T.)
                    ELSE  &&  Pass appropriate tax type, instead of just passing 'G' - BH 5-19-06
                        m.nnetamt = oDist.netrev(m.cwellid, m.ngrossamt, 'G' + RIGHT(TRIM(m.csource), 1), .F., .T.)
                    ENDIF
                CASE INLIST(m.csource, 'OTH', 'PTAX1', 'PTAX2', 'PTAX3', 'PTAX4')
                    m.nnetamt = oDist.netrev(m.cwellid, m.ngrossamt, 'P', .F., .T.)
                ENDCASE
            ENDIF
         ENDIF

         SELECT expcat
         IF SEEK(m.cCatCode)
            m.ctaxcode = ctaxcode
         ELSE
            STORE ' ' TO m.ctaxcode, ;
               m.ctaxdesc
         ENDIF
         SELECT taxcodes
         LOCATE FOR ctaxcode = m.ctaxcode
         IF FOUND()
            m.ctaxdesc = cdesc
         ELSE
            m.ctcaxdesc = ' '
         ENDIF
         SELE unalltmp
         REPL nnetamt   WITH m.nnetamt, ;
            ngrossamt WITH m.ngrossamt, ;
            ctaxcode WITH m.ctaxcode, ;
            ctaxdesc WITH m.ctaxdesc
      ENDSCAN

      SELECT unalltmp
      DO CASE
         CASE tnSort = 1
            INDEX ON cGroup + cwellid + crptgroup + cprocess + ctaxcode TAG cwellid
         CASE tnSort = 2
            INDEX ON cGroup + cwellname + crptgroup + cprocess + ctaxcode TAG cwellname
         CASE tnSort = 3
            INDEX ON cGroup + crptgroup + cprocess + cwellid + ctaxcode TAG cwellid
         CASE tnSort = 4
            INDEX ON cGroup + crptgroup + cprocess + cwellname + ctaxcode TAG cwellname
      ENDCASE

    SELECT unalltmp
    IF RECCOUNT() > 0
        llReturn = .T.
    ELSE
        llReturn = .F.
    ENDIF
CATCH TO loError
    llReturn = .F.
    DO errorlog WITH 'swUnallRpt', loError.LINENO, 'swUtils', loError.ERRORNO, loError.MESSAGE, '', loError
    MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
          'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn

ENDPROC

************************************************
DEFINE CLASS GroupListener AS REPORTLISTENER
************************************************
   Groups = NULL

*************************************
   FUNCTION BEFOREREPORT()
      LOCAL loData AS OBJECT
      LOCAL lnCnt
** Stuff all of our group bands into a collection
      THIS.Groups = CREATEOBJECT("Collection")
      SET DATASESSION TO (THIS.FRXDATASESSION)
      SELECT frx
      lnCnt = 0
      SCAN FOR INLIST(objcode, 3, 5)  && GroupHeader, GroupFooter
         DO CASE
            CASE objcode = 3   && GroupHeader
               lnCnt  = lnCnt + 1
               loData = CREATEOBJECT("Empty")
               ADDPROPERTY(loData, "expr", frx.EXPR)
               ADDPROPERTY(loData, "currentvalue", "")
               ADDPROPERTY(loData, "applyfix", .F.)
               ADDPROPERTY(loData, "groupheaderid", RECNO())
               ADDPROPERTY(loData, "groupno", lnCnt)
               THIS.Groups.ADD(loData, ALLTRIM(STR(RECNO())))

            CASE objcode = 5   && GroupFooter
** For our footer band, just use the header band but add
** it to the collection again so we can reference it by its key
               FOR EACH loData IN THIS.Groups
                  IF loData.groupno = lnCnt
                     ADDPROPERTY(loData, "groupfooterid", RECNO())
                     THIS.Groups.ADD(loData, ALLTRIM(STR(RECNO())))
                     lnCnt = lnCnt - 1
                     EXIT
                  ENDIF
               ENDFOR
         ENDCASE
      ENDSCAN
      SET DATASESSION TO (THIS.CURRENTDATASESSION)

   ENDFUNC


   FUNCTION BEFOREBAND(nBandObjCode, nFRXRecNo)
      IF INLIST(nBandObjCode, 3, 5)
         WITH THIS.Groups(ALLTRIM(STR(nFRXRecNo)))
            DO CASE
               CASE nBandObjCode = 3   && GroupHeader
** First time through this grouping?
** Just add our expression value to the groups object
                  IF EMPTY(.CurrentValue)
                     .CurrentValue = EVALUATE(.EXPR)
                  ENDIF
** Is the group expr value different?
** If so, our BUG had occured:
** Skip back 1 record and set a flag
                  IF .CurrentValue # EVALUATE(.EXPR)
                     SKIP - 1
                     .ApplyFix = .T.
                  ENDIF
               CASE nBandObjCode = 5   && GroupFooter
** Reset the group expr value if our page footer occurs
                  .CurrentValue = ""
            ENDCASE
         ENDWITH
      ENDIF
   ENDFUNC

*************************************
   FUNCTION AFTERBAND(nBandObjCode, nFRXRecNo)
      IF INLIST(nBandObjCode, 3)   && GroupHeader
         WITH THIS.Groups(ALLTRIM(STR(nFRXRecNo)))
** Our BUG occured, set the record pointer back
            IF .ApplyFix
               SKIP 1
               .ApplyFix = .F.
            ENDIF
         ENDWITH
      ENDIF
   ENDFUNC

ENDDEFINE

************************************************
DEFINE CLASS CheckExtensionHandler AS Custom
************************************************

 * Prevent checks from being printed from the preview window
   PROCEDURE PRINT
      LPARAMETERS m.toXFF
      MESSAGEBOX('Checks cannot be printed from the preview. Please choose Print instead of Preview to send the checks to the printer',16,'Print Checks')
      RETURN .F.
    ENDPROC
ENDDEFINE

*!* Function declarations to avoid compiler errors
*!* because the compiler isn't aware of the functions
*!* that are contained in the FLL.
FUNCTION EMCreateMessage
FUNCTION EMAddRecipient
FUNCTION EMSend

******************************************
PROCEDURE swEmailReport
******************************************
   LPARAMETERS tcRecipient, ;
      tcSubject, ;
      tcFileAttachment, ;
      tlOne, ;
      tcBody, ;
      tcSender, ;
      tcMailServer, ;
      tcEmailUser, ;
      tcEmailPass, ;
      tnSMTPPort, ;
      tlTLS, ;
      tlAsync, ;
      tlUseOutlook

   LOCAL lcSender, lcMailServer, lcSenderName, llResult

   IF EMPTY(tcRecipient)
      RETURN .F.
   ENDIF

   IF VARTYPE(tcFileAttachment) # 'C'
      tcFileAttachment = ''
   ENDIF
   IF VARTYPE(tcBody) # 'C'
      tcBody = ''
   ENDIF

   IF EMPTY(tcFileAttachment)
      RETURN .F.
   ENDIF

   llResult = .F.

   oSendMail = CREATEOBJECT('swSendMail')

   oMessage = findglobalobject('cmmessage')

   IF VARTYPE(tcMailServer) = 'C' AND NOT EMPTY(tcMailServer) AND NOT tlUseOutlook
      SWSELECT('options')
      oSendMail.lOutlook     = .F.
      oSendMail.cEmailServer  = tcMailServer
      oSendMail.cEmailAddress = tcSender
      oSendMail.cSender        = m.goapp.cCompanyName
      oSendMail.cEmailUser     = ALLTRIM(tcEmailUser)
      oSendMail.cEmailPass     = cmEncrypt(ALLTRIM(tcEmailPass), m.goapp.cEncryptionKey)

      oSendMail.cTo        = tcRecipient
      oSendMail.cCC        = ""
      oSendMail.cBCC     = ""
      oSendMail.cSubject  = tcSubject
      oSendMail.nSMTPPort = tnSMTPPort
      oSendMail.lUseSSL     = tlTLS

      IF tcFileAttachment # 'None'
         oSendMail.cAttachment = FULLPATH(tcFileAttachment)
      ELSE
         oSendMail.cAttachment = ''
      ENDIF
      IF EMPTY(tcBody) AND tcFileAttachment # 'None'
         oSendMail.cBody      = tcSubject + ' Report Attached...'
      ELSE
         oSendMail.cBody      = tcBody
      ENDIF

      llResult = oSendMail.SendMail(tlAsync)       && Send again - wait for completion

      IF !llResult
         IF tlOne
            MESSAGEBOX('Unable to send email...Check your settings and try again.', 16, 'E-Mail Setup Problem')
         ENDIF
      ELSE
         IF tlOne
            MESSAGEBOX("Report(s) sent......", 0, 'E-Mail Report')
         ENDIF
      ENDIF
   ELSE

      IF swIsEmailSetup()
         SWSELECT('options')
         oSendMail.lOutlook       = options.lUseOutlook
         oSendMail.cEmailServer    = options.cEmailServer
         oSendMail.cEmailAddress = options.cEmailAddress
         oSendMail.cSender       = m.goapp.cCompanyName
         oSendMail.cEmailUser    = ALLT(options.cEmailUser)
         oSendMail.cEmailPass    = cmEncrypt(ALLT(options.cEmailPass), m.goapp.cEncryptionKey)
         oSendMail.cTo          = tcRecipient
         oSendMail.cCC          = ""
         oSendMail.cBCC          = ""
         oSendMail.cSubject       = tcSubject
         oSendMail.nSMTPPort    = options.nSMTPPort
         oSendMail.lUseSSL       = options.lUseSSL

         IF tcFileAttachment # 'None'
            oSendMail.cAttachment = FULLPATH(tcFileAttachment)
         ELSE
            oSendMail.cAttachment = ''
         ENDIF
         IF EMPTY(tcBody) AND tcFileAttachment # 'None'
            oSendMail.cBody      = tcSubject + ' Report Attached...'
         ELSE
            oSendMail.cBody      = tcBody
         ENDIF

         llResult = oSendMail.SendMail(tlAsync)       && Send again - wait for completion

         IF !llResult
            IF tlOne
               MESSAGEBOX('Unable to send email...Check your settings and try again.', 16, 'E-Mail Setup Problem')
            ENDIF
         ELSE
            IF tlOne
               MESSAGEBOX("Report(s) sent......", 0, 'E-Mail Report')
            ENDIF
         ENDIF
      ENDIF
   ENDIF

*ELEASE oSendMail

   RETURN oSendMail

*********************
PROCEDURE swLeapyear
*********************
   LPARAMETERS tcyear
   LOCAL llLeapYr

*
* Determines if the year passed as a parameter
* is a leap year
*
* Returns .T. if the year is a leap year
*

   IF VARTYPE(tcyear) # 'C'
      MESSAGEBOX('Invalid year passed to swLeapYear...Contact Support', 16, 'Leap Year Routine')
      RETURN .F.
   ENDIF

   llLeapYr   = .F.
   llLeapYr   = MOD(VAL(tcyear), 4) = 0
   IF llLeapYr AND MOD(VAL(tcyear), 100) = 0 AND MOD(VAL(tcyear), 400) # 0
      llLeapYr = .F.
   ENDIF

   RETURN llLeapYr

************************
PROCEDURE swIsEmailSetup
************************
   LOCAL llIsSetup

   llIsSetup = .F.

   TRY
      SWSELECT('options')
      GO TOP

** If the option to use outlook is selected, that's good enough
      IF options.lUseOutlook
         llIsSetup = .T.
      ELSE
** If the email server info is setup then we're good
         IF NOT EMPTY(options.cEmailServer) AND ;
               NOT EMPTY(options.cEmailUser)   AND ;
               NOT EMPTY(options.cEmailAddress) AND ;
               NOT EMPTY(options.cEmailPass)
            llIsSetup = .T.
         ENDIF
      ENDIF
   CATCH
      llIsSetup = .F.
   ENDTRY

   RETURN (llIsSetup)

***********************
PROCEDURE swCleanDOI
***********************

** Removes blank well and owner records
   TRY
      SWSELECT('wellinv')
      SCAN FOR EMPTY(cownerid) OR EMPTY(cwellid)
         DELETE NEXT 1
      ENDSCAN
   CATCH
   ENDTRY

***************************
PROCEDURE swUpdate
***************************

   IF NOT USED('compmast')
      USE (m.goapp.cCommonfolder+'compmast') IN 0
   ENDIF

   lcProducer = m.goapp.cCompanyName

   SELE compmast
   LOCATE FOR cproducer = lcProducer
   IF FOUND()
      lcDataPath = m.goapp.cdatafilepath
      IF NOT USED('version')
         USE (lcDataPath + 'version') IN 0
      ENDIF
      SELECT VERSION
      GO TOP
      REPL cversion WITH '**', ;
         LUPDATE  WITH .T.
      USE IN VERSION
      m.goapp.opencompany1(.T.)
      m.goapp.opencompany2(.F.,.F.,.T.)
   ENDIF

**********************************
PROCEDURE make_copy
**********************************
   LPARAMETERS tcAlias, tcNewCursor
   LOCAL llReturn

   llReturn = .T.

   TRY

      SWSELECT(tcAlias)
      lnx = AFIELDS(laTemp)
      FOR x = 1 TO lnx
         IF laTemp[X, 1] = 'PK'
            laTemp[X, 1] = 'TEMPPK'
         ENDIF
         laTemp[X, 7]  = ''
         laTemp[X, 8]  = ''
         laTemp[X, 9]  = ''
         laTemp[X, 10] = ''
         laTemp[X, 11] = ''
         laTemp[X, 12] = ''
         laTemp[X, 13] = ''
         laTemp[X, 14] = ''
         laTemp[X, 15] = ''
         laTemp[X, 16] = ''
         laTemp[X, 17] = 0
         laTemp[X, 18] = 0
      ENDFOR
      CREATE CURSOR (tcNewCursor) FROM ARRAY laTemp
   CATCH
      llReturn = .F.
   ENDTRY

   RETURN llReturn

*************************
PROCEDURE CheckSupportExp
*************************
   LPARAMETERS tlYearEnd
   LOCAL lcCode, lcClient, lnCode, lnClient, oRegCode
   SET PROCEDURE TO swregcode ADDITIVE
* Start the regcode object
   oRegCode = CREATEOBJECT('swregcode', SYS(5) + CURDIR() + 'datafiles\')

* If demo mode bail out
   IF NOT oRegCode.GetOpt(5)
      RETURN .T.
   ENDIF

   lnClient   = oRegCode.GetCode(1)
   lcCode   = oRegCode.GetCode(2)

* Get the support expiration date
   ldExpDate = oRegCode.Checksum(lnClient, lcCode, .F., .T.)

* Check to see if support expired at year end of previous year
* If so and tlYearEnd is .T., let the expiration pass
   IF tlYearEnd
      lcExpDate   = DTOC(ldExpDate)
      lcyear   = TRANSFORM(YEAR(DATE()) - 1)
      IF lcExpDate = '12/31/' + lcyear
         RETURN .T.
      ENDIF
   ENDIF

   IF ldExpDate >= DATE()
* swconfig.daa is created the 1st time the regcode is detected as expired
* It saves the current date there so they can't reset their system date
      RETURN .T.
   ELSE
      MESSAGEBOX('Your SherWare Support Subscription Has Expired. ' + CHR(10) + ;
         'Expiration Date: ' + DTOC(ldExpDate) + CHR(10) + ;
         'Please contact SherWare Inc. to renew your support subscription. ' + CHR(10) + ;
         'Phone: (330) 262-0200  Fax: (866) 338-1254  Email: sales@sherware.com', 48, 'Expired Support Subscription')

      RETURN .F.
   ENDIF

**************************
FUNCTION GetFiscalPeriod
**************************
   LPARAMETERS tdDate
   LOCAL laPeriods[13, 2]
   LOCAL lcyear, lcPeriod, lnx, lcSelect


   ASSERT TYPE('tdDate') = 'D' ;
      MESSAGE 'A blank date was passed to the getfiscalperiod method.  Fix it!!!!'

   IF VARTYPE(tdDate) # 'D'
      MESSAGEBOX('An Invalid date was passed to getfiscalperiod', 0, 'Invalid Date')
      RETURN (PADL(TRANSFORM(MONTH(DATE())), 2, '0'))
   ENDIF

   lcSelect = SELECT()

   IF NOT m.goapp.lAMVersion
      IF tdDate = {}  &&  Should never get here, but it blows up if it somehow gets passed a blank date - BH 06/25/2008
         tdDate = DATE()
      ENDIF
      RETURN(PADL(ALLT(STR(MONTH(tdDate), 2)), 2, '0'))
   ENDIF

   SWSELECT('glopt')
   GO TOP
*  If the glopt record is deleted, recall it
   IF DELETED()
      LOCATE FOR NOT DELETED()
      IF NOT FOUND()
         GO TOP
         RECALL
      ENDIF
   ENDIF
   SCATTER MEMVAR

* If the begining month of the fiscal year is not valid, make it January.
   IF NOT INLIST(m.cFYBegin, '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12')
      m.cFYBegin = '01'
   ENDIF

   SELECT (lcSelect)

   m.cFYEnd = PADL(TRANSFORM(VAL(m.cFYBegin) - 1), 2, '0')
   IF m.cFYEnd = '00'
      m.cFYEnd = '12'
   ENDIF

   SELECT (lcSelect)
   lcFYBegYr = TRANSFORM(YEAR(tdDate))

*
*  Get the beginning date of the fiscal year.
*
   ldBegDate = CTOD(m.cFYBegin + '/' + '01' + '/' + STR(VAL(lcFYBegYr), 4))

   IF tdDate < ldBegDate
      ldBegDate = GOMONTH(ldBegDate, -12)
   ENDIF
   lcFYBegYr = TRANSFORM(YEAR(ldBegDate))
   ldEndDate = GOMONTH(ldBegDate, 11)
   ldEndDate = GoEndMonth(ldEndDate, 0, .T.)


* Force the fiscal period count to be 12 per year --pws 3/24/97
   m.nfyprds = 12

   DO CASE
      CASE m.nfyprds = 13
*
* If there are 13 periods in a FY, each period is 28 days long.
* Put the month and ending day of each period in the laPeriods
* array.
*
         ldWrkDate = ldBegDate + 28
         FOR lnx = 1 TO m.nfyprds
            laPeriods[lnX, 1] = PADL(ALLTRIM(STR(MONTH(ldWrkDate), 2)), 2, '0')
            laPeriods[lnX, 2] = PADL(ALLTRIM(STR(DAY(ldWrkDate), 2)), 2, '0')
            ldWrkDate        = ldWrkDate + 28
         ENDFOR
      CASE m.nfyprds = 12
*
* If there are 12 periods in a FY, each period coincides with a given
* month. Put the month and ending day of each period in the laPeriods
* array.
*
         ldWrkDate       = GoEndMonth(ldBegDate, 0, .T.)
         laPeriods[1, 1] = PADL(ALLTRIM(STR(MONTH(ldWrkDate), 2)), 2, '0')
         laPeriods[1, 2] = PADL(ALLTRIM(STR(DAY(ldWrkDate), 2)), 2, '0')
         ldWrkDate       = GoEndMonth(ldBegDate, 1)
         FOR lnx = 2 TO m.nfyprds
            laPeriods[lnX, 1] = PADL(ALLTRIM(STR(MONTH(ldWrkDate), 2)), 2, '0')
            laPeriods[lnX, 2] = PADL(ALLTRIM(STR(DAY(ldWrkDate), 2)), 2, '0')
            ldWrkDate        = GoEndMonth(ldBegDate, lnx)
         ENDFOR
   ENDCASE

*
* Set the period as 'XX'. If the period is still 'XX' after we've
* looked it up in the laPeriods array, the date is invalid.
*
   lcPeriod = 'XX'

*
* Look for the period in the laPeriods array.  Return the period
* by formatting the index of the given element as the period the
* given date falls into.
*
   FOR lnx = 1 TO m.nfyprds
      lcMonth = PADL(ALLTRIM(STR(MONTH(tdDate))), 2, '0')
      lcDay     = PADL(ALLTRIM(STR(DAY(tdDate))), 2, '0')
      IF lcMonth = laPeriods[lnX, 1] AND lcDay <= laPeriods[lnX, 2]
         lcPeriod = (PADL(ALLTRIM(STR(lnx)), 2, '0'))
         EXIT
      ENDIF
   ENDFOR

   SELECT (lcSelect)

   RETURN (lcPeriod)

**************************
FUNCTION GetFiscalYear
**************************
   LPARAMETERS tdDate

   LOCAL laPeriods[13, 2]
   LOCAL lcyear, lcPeriod, lnx, lcSelect


   ASSERT TYPE('tdDate') = 'D' ;
      MESSAGE 'A blank date was passed to the getfiscalyear method.  Fix it!!!!'

   IF VARTYPE(tdDate) # 'D'
      MESSAGEBOX('An Invalid date was passed to getfiscalyear', 0, 'Invalid Date')
      RETURN (TRANSFORM(YEAR(DATE())))
   ENDIF

   lcSelect = SELECT()

   IF NOT m.goapp.lAMVersion
      IF tdDate = {}  &&  Should never get here, but it blows up if it somehow gets passed a blank date - BH 06/25/2008
         tdDate = DATE()
      ENDIF
      RETURN(ALLT(STR(YEAR(tdDate), 4)))
   ENDIF

   SWSELECT('glopt')
   GO TOP
*  If the glopt record is deleted, recall it
   IF DELETED()
      LOCATE FOR NOT DELETED()
      IF NOT FOUND()
         GO TOP
         RECALL
      ENDIF
   ENDIF
   SCATTER MEMVAR

* If the begining month of the fiscal year is not valid, make it January.
   IF NOT INLIST(m.cFYBegin, '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12')
      m.cFYBegin = '01'
   ENDIF

   m.cFYEnd = PADL(TRANSFORM(VAL(m.cFYBegin) - 1), 2, '0')
   IF m.cFYEnd = '00'
      m.cFYEnd = '12'
   ENDIF

   lcFYBegYr = TRANSFORM(YEAR(tdDate))

*
*  Get the beginning date of the fiscal year.
*
   ldBegDate = CTOD(m.cFYBegin + '/' + '01' + '/' + STR(VAL(lcFYBegYr), 4))

   IF tdDate < ldBegDate
      ldBegDate = GOMONTH(ldBegDate, -12)
   ENDIF
   lcFYBegYr = TRANSFORM(YEAR(ldBegDate))
   ldEndDate = GOMONTH(ldBegDate, 11)
   ldEndDate = GoEndMonth(ldEndDate, 0, .T.)

   SELECT (lcSelect)


*
*  Just asking for fiscal year
*

   IF tdDate >= ldBegDate
*
* The date is after the beginning FY date.
* Calculate what FY the date is in by calculating the number
* of years the given date is past the beginning date.
*
      lnDays = tdDate - ldBegDate
      IF MOD(YEAR(DATE()), 4) = 0
         lnDays = lnDays - 1
      ENDIF
      lnYrs  = INT(lnDays / 365.4)
      IF m.lFYEnd
         lcyear = STR(VAL(lcFYBegYr) + lnYrs + 1, 4)
      ELSE
         lcyear = STR(VAL(lcFYBegYr) + lnYrs, 4)
      ENDIF
      RETURN(lcyear)
   ELSE
*
* The date is before the beginning date.
* Calculate what FY the date is in by calculating the number
* of years the given date is before the beginning date.
*
      lnDays = ldBegDate - tdDate
      IF m.lFYEnd
         lnYrs  = INT(lnDays / 365)
      ELSE
         lnYrs  = INT(lnDays / 365) + 1
      ENDIF
      lcyear = STR(VAL(lcFYBegYr) - lnYrs, 4)
      RETURN(lcyear)
   ENDIF

**************************
FUNCTION GetFP_Sysctl
**************************
   LPARAMETERS tcRunYear, tnRunNo
   LOCAL lcyear, lcPeriod, lnx, lcSelect


   IF VARTYPE(tcRunYear) # 'C'
      MESSAGEBOX('Bad run year passed to GetFP_Suspense', 16, 'Bad Data')
      RETURN '01'
   ENDIF

   lcSelect = SELECT()

   SWSELECT('sysctl')
   LOCATE FOR crunyear = tcRunYear AND nrunno = tnRunNo
   IF FOUND()
      lcPeriod = PADL(TRANSFORM(MONTH(dacctdate)), 2, '0')
      tdDate   = dacctdate
   ELSE
      lcPeriod = '99'
      tdDate   = {12/31/99}
   ENDIF

   IF m.goapp.lAMVersion

      SWSELECT('glopt')
      GO TOP
*  If the glopt record is deleted, recall it
      IF DELETED()
         LOCATE FOR NOT DELETED()
         IF NOT FOUND()
            GO TOP
            RECALL
         ENDIF
      ENDIF
      SCATTER MEMVAR

* If the begining month of the fiscal year is not valid, make it January.
      IF NOT INLIST(m.cFYBegin, '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12')
         m.cFYBegin = '01'
      ENDIF

      SELECT (lcSelect)

      m.cFYEnd = PADL(TRANSFORM(VAL(m.cFYBegin) - 1), 2, '0')
      IF m.cFYEnd = '00'
         m.cFYEnd = '12'
      ENDIF

      SELECT (lcSelect)
      lcFYBegYr = TRANSFORM(YEAR(tdDate))

*
*  Get the beginning date of the fiscal year.
*
      ldBegDate = CTOD(m.cFYBegin + '/' + '01' + '/' + STR(VAL(lcFYBegYr), 4))

      IF tdDate < ldBegDate
         ldBegDate = GOMONTH(ldBegDate, -12)
      ENDIF
      lcFYBegYr   = TRANSFORM(YEAR(ldBegDate))
      ldEndDate   = GOMONTH(ldBegDate, 11)
      ldEndDate   = GoEndMonth(ldEndDate, 0, .T.)


* Force the fiscal period count to be 12 per year --pws 3/24/97
      m.nfyprds = 12

      DO CASE
         CASE m.nfyprds = 13
*
* If there are 13 periods in a FY, each period is 28 days long.
* Put the month and ending day of each period in the laPeriods
* array.
*
            ldWrkDate = ldBegDate + 28
            FOR lnx = 1 TO m.nfyprds
               laPeriods[lnX, 1] = PADL(ALLTRIM(STR(MONTH(ldWrkDate), 2)), 2, '0')
               laPeriods[lnX, 2] = PADL(ALLTRIM(STR(DAY(ldWrkDate), 2)), 2, '0')
               ldWrkDate       = ldWrkDate + 28
            ENDFOR
         CASE m.nfyprds = 12
*
* If there are 12 periods in a FY, each period coincides with a given
* month. Put the month and ending day of each period in the laPeriods
* array.
*
            ldWrkDate      = GoEndMonth(ldBegDate, 0, .T.)
            laPeriods[1, 1]   = PADL(ALLTRIM(STR(MONTH(ldWrkDate), 2)), 2, '0')
            laPeriods[1, 2]   = PADL(ALLTRIM(STR(DAY(ldWrkDate), 2)), 2, '0')
            ldWrkDate      = GoEndMonth(ldBegDate, 1)
            FOR lnx = 2 TO m.nfyprds
               laPeriods[lnX, 1] = PADL(ALLTRIM(STR(MONTH(ldWrkDate), 2)), 2, '0')
               laPeriods[lnX, 2] = PADL(ALLTRIM(STR(DAY(ldWrkDate), 2)), 2, '0')
               ldWrkDate       = GoEndMonth(ldBegDate, lnx)
            ENDFOR
      ENDCASE

*
* Set the period as 'XX'. If the period is still 'XX' after we've
* looked it up in the laPeriods array, the date is invalid.
*
      lcPeriod = 'XX'

*
* Look for the period in the laPeriods array.  Return the period
* by formatting the index of the given element as the period the
* given date falls into.
*
      FOR lnx = 1 TO m.nfyprds
         lcMonth = PADL(ALLTRIM(STR(MONTH(tdDate))), 2, '0')
         lcDay    = PADL(ALLTRIM(STR(DAY(tdDate))), 2, '0')
         IF lcMonth = laPeriods[lnX, 1] AND lcDay <= laPeriods[lnX, 2]
            lcPeriod = (PADL(ALLTRIM(STR(lnx)), 2, '0'))
            EXIT
         ENDIF
      ENDFOR

      SELECT (lcSelect)
   ENDIF

   RETURN (lcPeriod)

**************************
FUNCTION GetFY_Sysctl
**************************
   LPARAMETERS tcRunYear, tnRunNo

   LOCAL lcyear, lcPeriod, lnx, lcSelect


   IF VARTYPE(tcRunYear) # 'C'
      MESSAGEBOX('Bad run year passed to GetFP_Suspense', 16, 'Bad Data')
      RETURN '01'
   ENDIF

   lcSelect = SELECT()

   SWSELECT('sysctl')
   LOCATE FOR crunyear = tcRunYear AND nrunno = tnRunNo
   IF FOUND()
      lcyear = TRANSFORM(YEAR(dacctdate))
      tdDate = dacctdate
   ELSE
      lcyear = '2099'
      tdDate = {12/31/99}
   ENDIF

   IF m.goapp.lAMVersion

      SWSELECT('glopt')
      GO TOP
*  If the glopt record is deleted, recall it
      IF DELETED()
         LOCATE FOR NOT DELETED()
         IF NOT FOUND()
            GO TOP
            RECALL
         ENDIF
      ENDIF
      SCATTER MEMVAR

* If the begining month of the fiscal year is not valid, make it January.
      IF NOT INLIST(m.cFYBegin, '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12')
         m.cFYBegin = '01'
      ENDIF

      m.cFYEnd = PADL(TRANSFORM(VAL(m.cFYBegin) - 1), 2, '0')
      IF m.cFYEnd = '00'
         m.cFYEnd = '12'
      ENDIF

      lcFYBegYr = TRANSFORM(YEAR(tdDate))

*
*  Get the beginning date of the fiscal year.
*
      ldBegDate = CTOD(m.cFYBegin + '/' + '01' + '/' + STR(VAL(lcFYBegYr), 4))

      IF tdDate < ldBegDate
         ldBegDate = GOMONTH(ldBegDate, -12)
      ENDIF
      lcFYBegYr   = TRANSFORM(YEAR(ldBegDate))
      ldEndDate   = GOMONTH(ldBegDate, 11)
      ldEndDate   = GoEndMonth(ldEndDate, 0, .T.)

      SELECT (lcSelect)


*
*  Just asking for fiscal year
*

      IF tdDate >= ldBegDate
*
* The date is after the beginning FY date.
* Calculate what FY the date is in by calculating the number
* of years the given date is past the beginning date.
*
         lnDays = tdDate - ldBegDate
         IF MOD(YEAR(DATE()), 4) = 0
            lnDays = lnDays - 1
         ENDIF
         lnYrs  = INT(lnDays / 365.4)
         IF m.lFYEnd
            lcyear = STR(VAL(lcFYBegYr) + lnYrs + 1, 4)
         ELSE
            lcyear = STR(VAL(lcFYBegYr) + lnYrs, 4)
         ENDIF
         RETURN(lcyear)
      ELSE
*
* The date is before the beginning date.
* Calculate what FY the date is in by calculating the number
* of years the given date is before the beginning date.
*
         lnDays = ldBegDate - tdDate
         IF m.lFYEnd
            lnYrs  = INT(lnDays / 365)
         ELSE
            lnYrs  = INT(lnDays / 365) + 1
         ENDIF
         lcyear = STR(VAL(lcFYBegYr) - lnYrs, 4)

      ENDIF
   ENDIF

   RETURN(lcyear)
**************************************
FUNCTION GoEndMonth
**************************************
*=================================================================================
*  Program....: GOENDMON.PRG
*  Version....: 1.0
*  Author.....: Phil W. Sherwood
*  Modified By: Vertex Software - Jon Ziegler
*  Date.......: January 10, 1995
*  Modified On: December 09, 1996
*  Notice.....: Copyright (c) 1994-1996 SherWare, Inc., All Rights Reserved.
*  Compiler...: FoxPro 2.6a
*) Description: Returns the end day of the month that is n months ahead.
*  Parameters.: tdDate    - The current date.
*               tnMonths  - The number of months to jump ahead.
*               tlCurrent - Dont add tnMonths to the month.
*  Changes....:
*      9/4/96   pws - Added check for leap year.
*     11/14/96  jmz - Added "ELSE...ldDate = tdDate" line.
*     12/09/96  jmz - Added SET CENTURY saving/restoration.
*                   - Added ldretval to avert 02/29/00 problem (see comments below)
*     04/23/99  pws - Moved to Visual FoxPro
*=================================================================================
   LPARA tdDate, tnMonths, tlCurrent

   LOCAL lddate, lcMonth, lcyear, lcDay, lcprvcent, ldretval

* save century setting  12/09/96 jmz
   lcprvcent = SET("CENTURY")
   SET CENTURY ON

   IF NOT tlCurrent
      lddate = GOMONTH(tdDate, tnMonths)
   ELSE      && 11/14/96 jmz
      lddate = tdDate
   ENDIF

   lcDay   = PADL(ALLTRIM(STR(DAY(lddate), 2)), 2, '0')
   lcMonth = PADL(ALLTRIM(STR(MONTH(lddate), 2)), 2, '0')
   lcyear  = STR(YEAR(lddate), 4)   && removed SUBSTR( ..., 3, 2) to preserve century
&& 12/09/96 jmz

*
*  Get Last Day of Month
*
   DO CASE
      CASE lcMonth = '01' OR lcMonth = '03' OR lcMonth = '05' OR lcMonth = '07' OR ;
            lcMonth = '08' OR lcMonth = '10' OR lcMonth = '12'
         lcEnd = '31'
      CASE lcMonth = '02'
*
*  Check for leap year
*
         IF MOD(VAL(lcyear), 4) = 0
            lcEnd = '29'
         ELSE
            lcEnd = '28'
         ENDIF
      CASE lcMonth = '04' OR lcMonth = '06' OR lcMonth = '09' OR lcMonth = '11'
         lcEnd = '30'
      OTHERWISE
         lcEnd = '31'
   ENDCASE

* CTOD(lcMonth+'/'+lcEnd+'/'+lcYear) will return {  /  /  } if
* SET CENTURY OFF and lcMonth = "02", lcEnd = "29", lcYear = "00"
* since 1900 did not have a Feb. 29th.  "ldretval" and SET CENTURY are
* the work-around to this  12/09/96 JMZ
   ldretval = CTOD(lcMonth + '/' + lcEnd + '/' + lcyear)

* restore previous century setting  12/09/96 JMZ
   IF NOT EMPTY(lcprvcent)
      SET CENTURY &lcprvcent
   ENDIF

   RETURN ldretval

***************************************
PROCEDURE Remove_NonExistant_Companies
***************************************
   LOCAL lcDataPath, llReturn, loError

   llReturn = .T.
   IF NOT FILE(m.goapp.cCommonfolder + 'removecomps.txt')
      RETURN
   ENDIF

   TRY
      IF NOT USED('compmast')
         USE (m.goapp.cCommonfolder + 'compmast') IN 0
      ENDIF
      SELECT compmast
      SCAN
         SCATTER MEMVAR
         lcDataPath = ALLTRIM(cdatapath)
         IF NOT DIRECTORY(lcDataPath)
            DELETE NEXT 1
         ENDIF
      ENDSCAN
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'Remove_Nonexistant_Companies', loError.LINENO, 'swUtils', loError.ERRORNO, loError.MESSAGE, '', loError
   ENDTRY

   RETURN llReturn

***************************************
FUNCTION IsInternetAvailable(tcUrlToCheck)
***************************************
   LOCAL llReturn, loError
   llReturn = .T.

   TRY
      IF VARTYPE(tcUrlToCheck) # 'C'
         tcUrlToCheck = 'http://www.irs.gov'
      ENDIF
      DECLARE INTEGER InternetCheckConnection IN wininet ;
         STRING lpszUrl, ;
         INTEGER dwFlags, ;
         INTEGER dwReserved
      IF InternetCheckConnection(tcUrlToCheck, 1, 0) # 1
         llReturn = .F.
      ENDIF
   CATCH TO loError
   ENDTRY
   RETURN llReturn
ENDFUNC


***************************************
FUNCTION GetNextPK(tcTable)
***************************************
   LOCAL loError, lcPK, lcAlias

   lcPK       = '**'
   lcAlias    = ALIAS()
   lcDeleted = SET('deleted')

   TRY
      IF VARTYPE(tcTable) # 'C'
         DO errorlog WITH 'GetNextPK', 1, 'Utility', 999, 'Bad TABLE Passed TO GetNextPK'
         lcPK = '**'
         EXIT
      ENDIF

      tcTable = UPPER(tcTable)

      DO CASE
         CASE tcTable = 'DISBHIST' OR tcTable = 'OWNPCTS'
            SWSELECT('disbhist', .F., 'keytable')
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Owner History')
            SET DELETED OFF
            SELECT keytable
            SET ORDER TO ciddisb
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Owner History')
            ENDDO
            swclose('keytable')
            SWSELECT('ownpcts', .F., 'keytable')
            SET ORDER TO ciddisb
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Owner History')
            ENDDO
            swclose('keytable')
            SWSELECT('suspense', .F., 'keytable')
            SET ORDER TO ciddisb
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Owner History')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'SUSPENSE'
            SWSELECT('suspense', .F., 'keytable')
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Suspense')
            SET DELETED OFF
            SELECT keytable
            SET ORDER TO ciddisb
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Suspense')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'WELLHIST'
            SWSELECT('wellhist', .F., 'keytable')
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Well History')
            SET DELETED OFF
            SELECT keytable
            SET ORDER TO cidwhst
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Well History')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'APPURCHD'
            SWSELECT('appurchd', .F., 'keytable')
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Purchase Detail')
            SET DELETED OFF
            SELECT keytable
            SET ORDER TO cidPurd
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Purchase Detail')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'BATCH'
            SWSELECT('glmaster', .F., 'keytable')
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            SET DELETED OFF
            SELECT keytable
            SET ORDER TO glbatch
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'CHECKS'
            SWSELECT('checks', .F., 'keytable')
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Checks')
            SET DELETED OFF
            SELECT keytable
            SET ORDER TO cidchec
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Checks')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'CSRCTDET'
            SWSELECT('csrctdet', .F., 'keytable')
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Cash Receipt Detail')
            SET DELETED OFF
            SELECT keytable
            SET ORDER TO cidPurd
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Cash Receipt Detail')
            ENDDO
            SET DELETED ON
         CASE tcTable = 'DOI'
            SWSELECT('wellinv', .F., 'keytable')
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.DOIKey')
            SET DELETED OFF
            SELECT keytable
            SET ORDER TO cidwinv
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.DOIKey')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'EXPENSE'
            SET DELETED OFF
            SWSELECT('expense', .F., 'keytable')
            SET ORDER TO cidexpe
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Expense')
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Expense')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'INCOME'
            SET DELETED OFF
            SWSELECT('income', .F., 'keytable')
            SET ORDER TO cidinco
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Income')
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Income')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'EXPCAT'
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Expense Category')
            SET DELE OFF
            SWSELECT('expcat', .F., 'keytable')
            SET ORDER TO cidexpc
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Expense Category')
            ENDDO
            SET DELE ON

         CASE tcTable = 'GLJNDET'
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Gljndet')
            SET DELE OFF
            SWSELECT('gljndet', .F., 'keytable')
            SET ORDER TO cidgljn
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Gljndet')
            ENDDO
            SET DELE ON

         CASE tcTable = 'CSRCTDET'
            lcPK  = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Cash Receipt Detail')
            SET DELETED OFF
            SWSELECT('csrctdet', .F.,'keytable')
            SET ORDER TO cidPurd
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Cash Receipt Detail')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'PROGREL'
            lcPK  = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Program Rels')
            SET DELETED OFF
            SWSELECT('progrel', .F.,'keytable')
            SET ORDER TO cidPrel
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Program Rels')
            ENDDO
            SET DELETED ON

         CASE tcTable = 'SYSCTL'
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Sysctl')
            SET DELE OFF
            SWSELECT('sysctl', .F., 'keytable')
            SET ORDER TO cidsysctl
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Sysctl')
            ENDDO
            SET DELE ON

         CASE tcTable = 'FORM6S'
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.form6s')
            SET DELE OFF
            SWSELECT('form6s', .F., 'keytable')
            SET ORDER TO cidstown
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.form6s')
            ENDDO
            SET DELE ON

         CASE tcTable = 'PROGREL'
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Program Rels')
            SET DELE OFF
            SWSELECT('progrel', .F., 'keytable')
            SET ORDER TO cidPrel
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Program Rels')
            ENDDO
            SET DELE ON
         CASE tcTable = 'ARPMTHDR'
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            SET DELE OFF
            SWSELECT('arpmthdr', .F., 'keytable')
            SET ORDER TO cbatch
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            ENDDO
            SET DELE ON
         CASE tcTable = 'ARPMTDET'
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.AR Payment Detail')
            SET DELE OFF
            SWSELECT('arpmtdet', .F., 'keytable')
            SET ORDER TO cidarpmd
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.AR Payment Detail')
            ENDDO
            SET DELE ON
         CASE tcTable = 'PUMPERS'
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            SET DELE OFF
            SWSELECT('pumpers', .F., 'keytable')
            SET ORDER TO cidpumper
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            ENDDO
            SET DELE ON
         CASE tcTable = 'METERSUB'
            lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Meter Sub')
            SET DELE OFF
            SWSELECT('metersub', .F., 'keytable')
            SET ORDER TO cidmets
            DO WHILE SEEK(lcPK)
               lcPK = m.goapp.oregistry.IncrementCounter('%Shared.Counters.Meter Sub')
            ENDDO
            SET DELE ON
         CASE tcTable = 'FORM1065'
            lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            SET DELE OFF
            SWSELECT('FORM1065', .F., 'keytable')
            SET ORDER TO cid1065
            DO WHILE SEEK(lcPK)
               lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            ENDDO
            SET DELE ON
         CASE tcTable = 'APPMTDET'
            lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.AP Payment Detail')
            SET DELE OFF
            SWSELECT('APPMTDET', .F., 'keytable')
            SET ORDER TO cidarpmd
            DO WHILE SEEK(lcPK)
               lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.AP Payment Detail')
            ENDDO
            SET DELE ON
         CASE tcTable = 'INVHDR'
            lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
            SET DELE OFF
            SWSELECT('INVHDR', .F., 'keytable')
            SET ORDER TO cbatch
            DO WHILE SEEK(lcPK)
               lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
            ENDDO
            SET DELE ON
         CASE tcTable = 'INVDET'
            lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
            SET DELE OFF
            SWSELECT('INVDET', .F., 'keytable')
            SET ORDER TO cidinvd
            DO WHILE SEEK(lcPK)
               lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.Invoice Detail')
            ENDDO
            SET DELE ON
         CASE tcTable = 'BRINELOG'
            lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            SET DELE OFF
            SWSELECT('brinelog', .F., 'keytable')
            SET ORDER TO bkey
            DO WHILE SEEK(lcPK)
               lcPK = M.goapp.oregistry.IncrementCounter('%Shared.Counters.Batch')
            ENDDO
            SET DELE ON
         CASE tcTABLE = 'INVNO'
            lcPK = TRANSFORM(VAL(m.goApp.oRegistry.IncrementCounter('%Shared.Counters.Invoice Number')))
      ENDCASE

      swclose('keytable')

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'GetNextPK', loError.LINENO, 'Utility', loError.ERRORNO, loError.MESSAGE, '', loError
      MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY

   SET DELETED &lcDeleted
   SELECT (lcAlias)
   RETURN lcPK

*************************************
FUNCTION  ConvertAmount(tcAmount)
*************************************

   IF '(' $ tcAmount
      tcAmount = STRTRAN(tcAmount, '(', '')
      tcAmount = STRTRAN(tcAmount, ')', '')
      tnAmount = VAL(tcAmount) * -1
   ELSE
      tnAmount = VAL(tcAmount)
   ENDIF

   RETURN tnAmount

*************************************
PROCEDURE ViewDocument
*************************************

   LPARAMETERS lcOutputFile

   LOCAL llReturn, lnReturn, loError, llDebug

   llDebug = .F.

   llDebug = FILE('datafiles\viewdebug.txt')

   llReturn = .T.

   TRY
      IF llReturn
         DECLARE INTEGER ShellExecute IN "Shell32.dll" ;
            INTEGER HWND, ;
            STRING lpVerb, ;
            STRING lpFile, ;
            STRING lpParameters, ;
            STRING lpDirectory, ;
            LONG nShowCmd

         lnReturn = ShellExecute(0, "Open", lcOutputFile, "", "", 1)

      ENDIF

      IF lnReturn > 32
         llReturn = .T.
      ELSE
         llReturn = .F.
         DO CASE
            CASE lnReturn = 2
               MESSAGEBOX('The file: ' + lcOutputFile + CHR(10) + 'was not found.', 48, 'File Not Found')
            CASE lnReturn = 3
               MESSAGEBOX('The path: ' + lcOutputFile + CHR(10) + 'was not found.', 48, 'Path Not Found')
            CASE lnReturn = 5
               MESSAGEBOX('Access denied for file: ' + lcOutputFile, 48, 'Access Denied')
            OTHERWISE
               MESSAGEBOX('View Document Failed with return code: ' + TRANSFORM(lnReturn), 48, 'View Failed')
         ENDCASE
      ENDIF
   CATCH TO loError
      MESSAGEBOX('Error Occured: ' + CHR(10) + ;
         loError.MESSAGE, 64, 'View Document')
   ENDTRY

   RETURN (llReturn)

*******************
PROCEDURE GetDLLS
*******************

   LOCAL lcLibrary
   LOCAL lcSourceFile, lcTargetFile, llReturn, llSupport, lnResult, loError

   RETURN .T.

   llReturn = .T.

   TRY
      IF NOT 'swftp' $ LOWER(SET('procedure'))
         SET PROCEDURE TO CUSTOM\swftp.prg ADDITIVE
      ENDIF
      IF IsInternetAvailable("http://support.sherware.com")
         lcLibrary = SET('library')

         IF NOT DIRECTORY(m.goapp.cCommonfolder + 'Bin')
            MD (m.goapp.cCommonfolder + 'Bin')
         ENDIF


         lcSourceFile = 'wwdotnetbridge.dll'
         lcTargetFile = (m.goapp.cCommonfolder + 'Bin\wwdotnetbridge.dll')

         loUpdate            = m.goapp.oUpdate
         loUpdate.cSourceFile  = lcSourceFile
         loUpdate.cTargetFile  = lcTargetFile
         loUpdate.cDescription = 'wwdotnetbridge'
         loUpdate.cUnzipTo      = m.goapp.cCommonfolder
         llReturn            = loUpdate.GetUpdate(.T.)

         lcSourceFile = 'wwipstuff.dll'
         lcTargetFile = (m.goapp.cCommonfolder + 'Bin\wwipstuff.dll')

         loUpdate.cSourceFile  = lcSourceFile
         loUpdate.cTargetFile  = lcTargetFile
         loUpdate.cDescription = 'wwipstuff'
         loUpdate.cUnzipTo      = m.goapp.cCommonfolder
         llReturn            = loUpdate.GetUpdate(.T.)

         llReturn = lnResult = 0
      ENDIF
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'GetProxy', loError.LINENO, 'Submit 1099s', loError.ERRORNO, loError.MESSAGE
      MESSAGEBOX('Unable to get the required submit dll at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY

   RETURN llReturn

*******************************
FUNCTION GetOwnerStmts()
*******************************
   LOCAL lcLibrary, llCopyError
   LOCAL loIP AS 'wwftp'
   LOCAL lcSourceFile, lcTargetFile, llReturn, llSupport, lnResult, loError

   lcLibrary = SET('library')

   llSupport = CheckSupportExp()

   IF NOT llSupport
      RETURN
   ENDIF

   IF MESSAGEBOX('This utility will download new report formats for the Owner Distribution statements.' + CHR(10) + ;
         'The current formats will be copied to a backup folder under your Rpts folder.' + CHR(10) + CHR(10) + ;
         'Do you want to continue?', 36, 'Download Owner Stmt Formats') = 7
      RETURN
   ENDIF

   TRY
      llCopyError = .F.
* Copy current formats to backup folder
      IF NOT DIRECTORY(m.goapp.crptsfolder + 'backup')
         MD (m.goapp.crptsfolder + 'backup')
      ENDIF

      COPY FILE m.goapp.crptsfolder + 'dmrostmt*.*' TO m.goapp.crptsfolder + 'backup\dmrostmt*.*'
   CATCH TO loError
      IF loError.ERRORNO # 1
         llCopyError = .T.
      ENDIF
   ENDTRY

   IF llCopyError
      IF MESSAGEBOX('A backup copy of the current owner statement formats could not be made at this time.' + CHR(10) + ;
            'The error encountered: ' + CHR(10) + ;
            'Line No: ' + TRANSFORM(loError.LINENO) + CHR(10) + ;
            'Error No: ' + TRANSFORM(loError.ERRORNO) + CHR(10) + ;
            loError.MESSAGE + CHR(10) + CHR(10) + ;
            'Do you want to continue?', 36, 'Backup Stmts Problem') = 7
         RETURN
      ENDIF
   ENDIF

   lcSourceFile    = 'ownstmt.zip'
   lcTargetFile    = m.goapp.cCommonfolder + 'ownstmt.zip'
   lcDescription = "new Owner Statements "

   loUpdate             = m.goapp.oUpdate
   loUpdate.cSourceFile    = lcSourceFile
   loUpdate.cTargetFile    = lcTargetFile
   loUpdate.cDescription = lcDescription
   loUpdate.cUnzipTo    = m.goapp.crptsfolder
   llReturn             = loUpdate.GetUpdate()

   IF NOT EMPTY(loUpdate.cErrorMessage)
      MESSAGEBOX(loUpdate.cErrorMessage, 0, 'Update Files')
   ENDIF

   RETURN llReturn

*******************************
FUNCTION GetStubStmts()
*******************************
   LOCAL lcLibrary, llCopyError
   LOCAL loIP AS 'wwftp'
   LOCAL lcSourceFile, lcTargetFile, llReturn, llSupport, lnResult, loError

   lcLibrary = SET('library')

   llSupport = CheckSupportExp()

   IF NOT llSupport
      RETURN
   ENDIF

   IF MESSAGEBOX('This utility will download new report formats ' + CHR(10) + 'for the Owner Stub statements.' + CHR(10) + ;
         'The current formats will be copied to a backup ' + CHR(10) + 'folder under your Rpts folder.' + CHR(10) + CHR(10) + ;
         'Do you want to continue?', 36, 'Download Owner Stmt Formats') = 7
      RETURN
   ENDIF

   TRY
      llCopyError = .F.
* Copy current formats to backup folder
      IF NOT DIRECTORY(m.goapp.crptsfolder + 'backup')
         MD (m.goapp.crptsfolder + 'backup')
      ENDIF

      COPY FILE m.goapp.crptsfolder + 'dmrostub*.*' TO m.goapp.crptsfolder + 'backup\dmrostub*.*'
   CATCH TO loError
      IF loError.ERRORNO # 1
         llCopyError = .T.
      ENDIF
   ENDTRY

   IF llCopyError
      IF MESSAGEBOX('A backup copy of the current owner stub formats could not be made at this time.' + CHR(10) + ;
            'The error encountered: ' + CHR(10) + ;
            'Line No: ' + TRANSFORM(loError.LINENO) + CHR(10) + ;
            'Error No: ' + TRANSFORM(loError.ERRORNO) + CHR(10) + ;
            loError.MESSAGE + CHR(10) + CHR(10) + ;
            'Do you want to continue?', 36, 'Backup Stmts Problem') = 7
         RETURN
      ENDIF
   ENDIF

   lcSourceFile    = 'ownstub.zip'
   lcTargetFile    = m.goapp.cCommonfolder + 'ownstub.zip'
   lcDescription = "New Owner Stub Statements "

   loUpdate             = m.goapp.oUpdate
   loUpdate.cSourceFile    = lcSourceFile
   loUpdate.cTargetFile    = lcTargetFile
   loUpdate.cDescription = lcDescription
   loUpdate.cUnzipTo    = m.goapp.crptsfolder
   llReturn             = loUpdate.GetUpdate()

   IF NOT EMPTY(loUpdate.cErrorMessage)
      MESSAGEBOX(loUpdate.cErrorMessage, 0, 'Update Files')
   ENDIF

   RETURN llReturn

**************************
PROCEDURE Revcat_Report
**************************

   SWSELECT('revcat')

   m.goapp.oReport.cAlias       = 'revcat'
   m.goapp.oReport.DATASESSIONID = 1
   m.goapp.oReport.cReportName    = 'Revenue Categories'

   m.goapp.oReport.cTitle1           = 'Revenue Categories'
   m.goapp.oReport.cTitle2           = ''
   m.goapp.oReport.cProcessor        = ''
   m.goapp.oReport.cSortOrder        = ''
   m.goapp.oReport.cSelectionCriteria = ''
   m.goapp.oReport.cReportName        = 'dmrxrevcat.frx'
   m.goapp.oReport.CSVFilename        = 'revenue category listing.csv'

   m.goapp.oReport.cFriendlyName = 'Revenue Category Listing'

   llReturn = m.goapp.oReport.SendReport('S', .F., .F.)



**************************
PROCEDURE Prefs_Report
**************************
   LPARAMETERS tcApp

**  Scans the various options tables and scatters the memvars to create a preferences report  **
   SWSELECT('glopt')
   SWSELECT('apopt')
   SWSELECT('aropt')
   SWSELECT('options')
   IF m.goapp.lAMVersion
      SWSELECT('propt')
      SWSELECT('coa')
   ENDIF
   SWSELECT('landopt')
   SWSELECT('afeopt')
   SWSELECT('gasopt')
   SWSELECT('vendor')
   SWSELECT('terms')

   IF USED('preftemp')
      USE IN preftemp
   ENDIF

   CREATE CURSOR preftemp  ;  &&  Cursor to hold all the preferences settings
   (cFYBegin      c(9),  ;
      lBunch         l,  ;
      lCheckNames    l,  ;
      cRetEarn       c(60),  ;
      cCurEarn       c(60),  ;
      cRevClear      c(60),  ;
      cExpClear      c(60),  ;
      cInventory     c(60),  ;
      cUndepFund     c(60),  ;
      cSuspense      c(60),  ;
      cAPCash        c(60),  ;
      cAPAcct        c(60),  ;
      cDiscAcct      c(60),  ;
      cCashAcct      c(60),  ;
      cARAcct        c(60),  ;
      cARDisc        c(60),  ;
      cTaxAcct       c(60),  ;
      cIntAcct       c(60),  ;
      cCOGSAcct      c(60),  ;
      cInvNum        c(15),  ;
      nInvType       N(1, 0),  ;
      mInvMsg        m,  ;
      cAPCheckType   c(60),  ;
      nStubLine      N(3, 0),  ;
      nAPStubLine    N(3, 0),  ;
      lAPSkipPerf    l,  ;
      lSkipPerf      l,  ;
      lAPDupStub     l,  ;
      lDupStub       l,  ;
      cDMCheckType   c(60),  ;
      lVoidNext      l,  ;
      nCheckMin      N(6, 2),  ;
      cPRCheckType   c(60),  ;
      cLMCheckType   c(60),  ;
      lDirInv        l,  ;
      lShowRoy       l,  ;
      lRefID         l,  ;
      lBillDesc      l,  ;
      lHideComp      l,  ;
      lNoJIBBal      l,  ;
      lNoFirstName   l,  ;
      lStmComp       l,  ;
      lStmInv        l,  ;
      lGrpName       l,  ;
      lExpDate       l,  ;
      lExpSum        l,  ;
      lChgPrice      l,  ;
      lJIBNotes      l,  ;
      lShowVendor    l,  ;
      lAcctDesc      l,  ;
      nMaxRound      N(6, 2),  ;
      cVendComp      c(40),  ;
      lroundHigh     l,  ;
      lGross1099     l,  ;
      nMin1099Roy    N(7, 2),  ;
      nMin1099Non    N(7, 2),  ;
      cRevAcctNo     c(10),  ;
      cCompRptNo     c(10),  ;
      nSect29Rate    N(7, 2),  ;
      nCompress      N(7, 2),  ;
      nGather        N(7, 2),  ;
      lCalcDays      l,  ;
      lShowInact     l,  ;
      lSendToAllocate l,  ;
      cdisbacct      c(60),  ;
      cdefacct       c(60),  ;
      cminacct       c(60),  ;
      cjibacct       c(60),  ;
      ctaxacct1      c(60),  ;
      ctaxacct2      c(60),  ;
      ctaxacct3      c(60),  ;
      ctaxacct4      c(60),  ;
      cbackacct      c(60),  ;
      cgathacct      c(60),  ;
      cfixedacct     c(60),  ;
      lSummaryPost   l,  ;
      cpracct        c(60),  ;
      cprexpacct     c(60),  ;
      cbonexpacct    c(60),  ;
      lcalcsuta      l,  ;
      lcalcfuta      l,  ;
      nfutarate      N(9, 2),  ;
      nfutalimit     N(9, 2),  ;
      cfutaliab      c(60),  ;
      cfutaexp       c(60),  ;
      ncostplus      N(8, 4),  ;
      nlocationfee   N(9, 2),  ;
      lallocexp      l,  ;
      cLMCashAcct    c(60),  ;
      crentacct      c(60),  ;
      lchkduestart   l,  ;
      nleaddays      N(3, 0),  ;
      lexpense       l,  ;
      cHGARAcct      c(60),  ;
      cHGSalesAcct   c(60),  ;
      nHGPrice       N(9, 2),  ;
      cHGidterm      c(20),  ;
      cHGMonth       c(12),  ;
      nHGCharge      N(9, 2),  ;
      cHGCharge      c(60),   ;
      cHGTerms       c(60), ;
      lVoidNextAP    l, ;
      lshowpsi       l,  ;
      lTwoLines      l,  ;
      mHGInvNotes    m)


   SELECT coa
   SET ORDER TO acctno

   SELECT glopt  &&  GL Options
   SCATTER MEMVAR
   DO CASE
      CASE m.cFYBegin = '01'
         m.cFYBegin = 'January'
      CASE m.cFYBegin = '02'
         m.cFYBegin = 'February'
      CASE m.cFYBegin = '03'
         m.cFYBegin = 'March'
      CASE m.cFYBegin = '04'
         m.cFYBegin = 'April'
      CASE m.cFYBegin = '05'
         m.cFYBegin = 'May'
      CASE m.cFYBegin = '06'
         m.cFYBegin = 'June'
      CASE m.cFYBegin = '07'
         m.cFYBegin = 'July'
      CASE m.cFYBegin = '08'
         m.cFYBegin = 'August'
      CASE m.cFYBegin = '09'
         m.cFYBegin = 'September'
      CASE m.cFYBegin = '10'
         m.cFYBegin = 'October'
      CASE m.cFYBegin = '11'
         m.cFYBegin = 'November'
      CASE m.cFYBegin = '12'
         m.cFYBegin = 'December'
   ENDCASE

   IF m.goapp.lAMVersion
      SWSELECT('coa')
      SET ORDER TO acctno
      IF SEEK(m.cRetEarn)
         m.cRetEarn = m.cRetEarn + ' - ' + coa.cAcctDesc
      ENDIF
      IF SEEK(m.cCurEarn)
         m.cCurEarn = m.cCurEarn + ' - ' + coa.cAcctDesc
      ENDIF
   ENDIF
   IF m.goapp.lAMVersion OR m.goapp.lQBVersion
      SWSELECT('coa')
      SET ORDER TO acctno
      IF SEEK(m.cRevClear)
         m.cRevClear = m.cRevClear + ' - ' + coa.cAcctDesc
      ENDIF
      IF SEEK(m.cExpClear)
         m.cExpClear = m.cExpClear + ' - ' + coa.cAcctDesc
      ENDIF
   ENDIF
   IF m.goapp.lAMVersion
      SWSELECT('coa')
      SET ORDER TO acctno
      IF SEEK(m.cInventory)
         m.cInventory = m.cInventory + ' - ' + coa.cAcctDesc
      ENDIF
   ENDIF
   IF m.goapp.lAMVersion OR m.goapp.lQBVersion
      SWSELECT('coa')
      SET ORDER TO acctno
      IF SEEK(m.cUndepFund)
         m.cUndepFund = m.cUndepFund + ' - ' + coa.cAcctDesc
      ENDIF
      IF SEEK(m.cSuspense)
         m.cSuspense = m.cSuspense + ' - ' + coa.cAcctDesc
      ENDIF
   ENDIF


   SELECT apopt  &&  AP Options - Not scattering, so we don't start overwriting existing memvars
   m.cAPCash     = cAPCash
   m.cAPAcct     = cAPAcct
   m.cDiscAcct     = cDiscAcct
   m.cAPCheckType = cCheckType
   m.lAPDupStub     = lDupStub
   SELECT coa
   IF SEEK(m.cAPCash)
      m.cAPCash = m.cAPCash + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cAPAcct)
      m.cAPAcct = m.cAPAcct + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cDiscAcct)
      m.cDiscAcct = m.cDiscAcct + ' - ' + coa.cAcctDesc
   ENDIF
   DO CASE
      CASE m.cAPCheckType = 'DN'
         m.cAPCheckType   = 'Dot-Matrix (No Stub)'
      CASE m.cAPCheckType = 'DA'
         m.cAPCheckType   = 'Dot-Matrix (Stub Above)'
      CASE m.cAPCheckType = 'DB'
         m.cAPCheckType   = 'Dot-Matrix (Stub Below)'
      CASE m.cAPCheckType = 'LN'
         m.cAPCheckType   = 'Laser (No Stub)'
      CASE m.cAPCheckType = 'LA'
         m.cAPCheckType   = 'Laser (Stub Above)'
      CASE m.cAPCheckType = 'LV'
         m.cAPCheckType   = 'Laser (Stub Below)'
      CASE m.cAPCheckType = 'LC'
         m.cAPCheckType   = 'Laser (Middle Check)'
   ENDCASE


   SELECT aropt  &&  AR Options
   SCATTER MEMVAR MEMO
   m.cARDisc = m.cDiscAcct
   SELECT coa
   IF SEEK(m.cCashAcct)
      m.cCashAcct = m.cCashAcct + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cARAcct)
      m.cARAcct = m.cARAcct + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cARDisc)
      m.cARDisc = m.cARDisc + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cTaxAcct)
      m.cTaxAcct = m.cTaxAcct + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cIntAcct)
      m.cIntAcct = m.cIntAcct + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cCOGSAcct)
      m.cCOGSAcct = m.cCOGSAcct + ' - ' + coa.cAcctDesc
   ENDIF


   SELECT options  &&  Disb and JIB Options
   m.nStubLine       = nStubLine
   m.nAPStubLine    = nStubLine
   m.lSkipPerf       = lSkipPerf
   m.lAPSkipPerf    = lSkipPerf
   m.lVoidNext       = lVoidNext
   m.nCheckMin       = nmincheck
   m.lDirInv       = lDirInv
   m.lShowRoy       = lShowRoy
   m.lRefID          = lRefID
   m.lBillDesc       = lBillDesc
   m.lHideComp       = lHideComp
   m.lNoJIBBal       = lNoJIBBal
   m.lNoFirstName    = lNoFirstName
   m.lStmComp       = lStmComp
   m.lStmInv       = lStmInv
   m.lGrpName       = lGrpName
   m.lExpDate       = lExpDate
   m.lExpSum       = lExpSum
   m.lChgPrice       = lChgPrice
   m.lJIBNotes       = lJIBNotes
   m.lShowVendor    = lShowVendor
   m.lAcctDesc       = lAcctDesc
   m.nMaxRound       = nMaxRound
   m.cVendComp       = cVendComp
   m.lroundHigh       = lroundHigh
   m.lGross1099       = lGross1099
   m.nMin1099Roy    = nMin1099Roy
   m.nMin1099Non    = nMin1099Non
   m.cRevAcctNo       = cRevAcctNo
   m.cCompRptNo       = cCompRptNo
   m.nSect29Rate    = nSect29Rate
   m.nCompress       = nCompress
   m.nGather       = nGather
   m.lCalcDays       = lCalcDays
   m.lShowInact       = lShowInact
   m.lSendToAllocate = lSendToAllocate
   m.cdisbacct       = cdisbacct
   m.cdefacct       = cdefacct
   m.cminacct       = cminacct
   m.cjibacct       = cjibacct
   m.ctaxacct1       = ctaxacct1
   m.ctaxacct2       = ctaxacct2
   m.ctaxacct3       = ctaxacct3
   m.ctaxacct4       = ctaxacct4
   m.cbackacct       = cbackacct
   m.cgathacct       = cgathacct
   m.cfixedacct       = cfixedacct
   IF m.goapp.lAMVersion
      m.lSummaryPost    = lSummaryPost
   ELSE
      m.lSummaryPost = .F.
   ENDIF
   m.cDMCheckType = cCheckType
   m.lTwoLines     = lTwoLines
   DO CASE
      CASE m.cDMCheckType = 'DN'
         m.cDMCheckType = 'Dot-Matrix (No Stub)'
      CASE m.cDMCheckType = 'DA'
         m.cDMCheckType = 'Dot-Matrix (Stub Above)'
      CASE m.cDMCheckType = 'DB'
         m.cDMCheckType = 'Dot-Matrix (Stub Below)'
      CASE m.cDMCheckType = 'LN'
         m.cDMCheckType = 'Laser (No Stub)'
      CASE m.cDMCheckType = 'LA'
         m.cDMCheckType = 'Laser (Stub Above)'
      CASE m.cDMCheckType = 'LV'
         m.cDMCheckType = 'Laser (Stub Below)'
      CASE m.cDMCheckType = 'LC'
         m.cDMCheckType = 'Laser (Middle Check)'
   ENDCASE
   IF NOT EMPTY(m.cVendComp)  &&  Get vendor name
      SELECT vendor
      LOCATE FOR ALLTRIM(cvendorid) = ALLTRIM(m.cVendComp)
      IF FOUND()
         m.cVendComp = ALLTRIM(m.cVendComp) + ' - ' + vendor.cVendName
      ENDIF
   ENDIF
   SELECT coa  &&  Fill in account descriptions
   IF SEEK(m.cdisbacct)
      m.cdisbacct = ALLTRIM(m.cdisbacct) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cdefacct)
      m.cdefacct = ALLTRIM(m.cdefacct) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cminacct)
      m.cminacct = ALLTRIM(m.cminacct) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cjibacct)
      m.cjibacct = ALLTRIM(m.cjibacct) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.ctaxacct1)
      m.ctaxacct1 = ALLTRIM(m.ctaxacct1) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.ctaxacct2)
      m.ctaxacct2 = ALLTRIM(m.ctaxacct2) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.ctaxacct3)
      m.ctaxacct3 = ALLTRIM(m.ctaxacct3) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.ctaxacct4)
      m.ctaxacct4 = ALLTRIM(m.ctaxacct4) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cbackacct)
      m.cbackacct = ALLTRIM(m.cbackacct) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cgathacct)
      m.cgathacct = ALLTRIM(m.cgathacct) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cfixedacct)
      m.cfixedacct = ALLTRIM(m.cfixedacct) + ' - ' + coa.cAcctDesc
   ENDIF


   IF m.goapp.lAMVersion
      SELECT propt  &&  Payroll Options
      m.cpracct       = cpracct
      m.cprexpacct    = cprexpacct
      m.cbonexpacct    = cbonexpacct
      m.lcalcsuta    = lcalcsuta
      m.lcalcfuta    = lcalcfuta
      m.nfutarate    = nfutarate
      m.nfutalimit    = nfutalimit
      m.cfutaliab    = cfutaliab
      m.cfutaexp    = cfutaexp
      m.cPRCheckType = cCheckType
      DO CASE
         CASE m.cPRCheckType = 'DN'
            m.cPRCheckType   = 'Dot-Matrix (No Stub)'
         CASE m.cPRCheckType = 'DA'
            m.cPRCheckType   = 'Dot-Matrix (Stub Above)'
         CASE m.cPRCheckType = 'DB'
            m.cPRCheckType   = 'Dot-Matrix (Stub Below)'
         CASE m.cPRCheckType = 'LN'
            m.cPRCheckType   = 'Laser (No Stub)'
         CASE m.cPRCheckType = 'LA'
            m.cPRCheckType   = 'Laser (Stub Above)'
         CASE m.cPRCheckType = 'LV'
            m.cPRCheckType   = 'Laser (Stub Below)'
         CASE m.cPRCheckType = 'LC'
            m.cPRCheckType   = 'Laser (Middle Check)'
      ENDCASE
      SELECT coa  &&  Account descriptions
      IF SEEK(m.cpracct)
         m.cpracct = ALLTRIM(m.cpracct) + ' - ' + coa.cAcctDesc
      ENDIF
      IF SEEK(m.cprexpacct)
         m.cprexpacct = ALLTRIM(m.cprexpacct) + ' - ' + coa.cAcctDesc
      ENDIF
      IF SEEK(m.cbonexpacct)
         m.cbonexpacct = ALLTRIM(m.cbonexpacct) + ' - ' + coa.cAcctDesc
      ENDIF
      IF SEEK(m.cfutaliab)
         m.cfutaliab = ALLTRIM(m.cfutaliab) + ' - ' + coa.cAcctDesc
      ENDIF
      IF SEEK(m.cfutaexp)
         m.cfutaexp = ALLTRIM(m.cfutaexp) + ' - ' + coa.cAcctDesc
      ENDIF
   ENDIF

   SELECT landopt  &&  Land Options
   m.cLMCashAcct  = cCashAcct
   m.crentacct     = crentacct
   m.lchkduestart = lchkduestart
   m.nleaddays     = nleaddays
   m.lexpense     = lexpense
   m.cLMCheckType = cCheckType
   DO CASE
      CASE m.cLMCheckType = 'DN'
         m.cLMCheckType   = 'Dot-Matrix (No Stub)'
      CASE m.cLMCheckType = 'DA'
         m.cLMCheckType   = 'Dot-Matrix (Stub Above)'
      CASE m.cLMCheckType = 'DB'
         m.cLMCheckType   = 'Dot-Matrix (Stub Below)'
      CASE m.cLMCheckType = 'LN'
         m.cLMCheckType   = 'Laser (No Stub)'
      CASE m.cLMCheckType = 'LA'
         m.cLMCheckType   = 'Laser (Stub Above)'
      CASE m.cLMCheckType = 'LV'
         m.cLMCheckType   = 'Laser (Stub Below)'
      CASE m.cLMCheckType = 'LC'
         m.cLMCheckType   = 'Laser (Middle Check)'
   ENDCASE
   SELECT coa  &&  Account descriptions
   IF SEEK(m.cLMCashAcct)
      m.cLMCashAcct = ALLTRIM(m.cLMCashAcct) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.crentacct)
      m.crentacct = ALLTRIM(m.crentacct) + ' - ' + coa.cAcctDesc
   ENDIF

   SELECT afeopt  &&  AFE Options
   SCATTER MEMVAR


   SELECT gasopt  &&  House Gas Options
   m.cHGARAcct     = cARAcct
   m.cHGSalesAcct = csalesacct
   m.nHGPrice     = nprice
   m.cHGidterm     = cidterm
   m.cHGMonth     = CMONTH
   m.nHGCharge     = ncharge
   m.cHGCharge     = ccharge
   m.lshowpsi     = lshowpsi
   m.mHGInvNotes  = minvnotes
   SELECT coa  &&  Account descriptions
   IF SEEK(m.cHGARAcct)
      m.cHGARAcct = ALLTRIM(m.cHGARAcct) + ' - ' + coa.cAcctDesc
   ENDIF
   IF SEEK(m.cHGSalesAcct)
      m.cHGSalesAcct = ALLTRIM(m.cHGSalesAcct) + ' - ' + coa.cAcctDesc
   ENDIF
   SELECT terms
   LOCATE FOR cidterm = m.cHGidterm
   IF FOUND()
      m.cidterm = terms.cTermDesc
   ENDIF
   DO CASE
      CASE m.cHGMonth = '01'
         m.cHGMonth = 'January'
      CASE m.cHGMonth = '02'
         m.cHGMonth = 'February'
      CASE m.cHGMonth = '03'
         m.cHGMonth = 'March'
      CASE m.cHGMonth = '04'
         m.cHGMonth = 'April'
      CASE m.cHGMonth = '05'
         m.cHGMonth = 'May'
      CASE m.cHGMonth = '06'
         m.cHGMonth = 'June'
      CASE m.cHGMonth = '07'
         m.cHGMonth = 'July'
      CASE m.cHGMonth = '08'
         m.cHGMonth = 'August'
      CASE m.cHGMonth = '09'
         m.cHGMonth = 'September'
      CASE m.cHGMonth = '10'
         m.cHGMonth = 'October'
      CASE m.cHGMonth = '11'
         m.cHGMonth = 'November'
      CASE m.cHGMonth = '12'
         m.cHGMonth = 'December'
   ENDCASE

   INSERT INTO preftemp FROM MEMVAR
   SELECT preftemp

   m.goapp.oReport.cAlias           = 'preftemp'
   m.goapp.oReport.DATASESSIONID     = 1
   m.goapp.oReport.cTitle1           = 'Preference Settings'
   m.goapp.oReport.cTitle2           = ''
   m.goapp.oReport.cProcessor        = ''
   m.goapp.oReport.cSortOrder        = ''
   m.goapp.oReport.cSelectionCriteria = ''
   m.goapp.oReport.cReportName        = 'dmrxopt.frx'
   m.goapp.oReport.CSVFilename        = 'preferences.csv'

   m.goapp.oReport.cFriendlyName = 'Preference Settings'

   llReturn = m.goapp.oReport.SendReport('S', .F., .F.)

**************************
PROCEDURE Pumpers_Report
**************************

   SWSELECT('pumpers')
   COUNT FOR NOT DELETED() TO lnCount
   IF lnCount = 0
      MESSAGEBOX('There are no pumpers defined. No report is available.', 0, 'Pumper Listing')
      RETURN
   ENDIF

   m.goapp.oReport.cAlias           = 'pumpers'
   m.goapp.oReport.DATASESSIONID     = 1
   m.goapp.oReport.cTitle1           = 'Pumper Listing'
   m.goapp.oReport.cTitle2           = ''
   m.goapp.oReport.cProcessor        = ''
   m.goapp.oReport.cSortOrder        = ''
   m.goapp.oReport.cSelectionCriteria = ''
   m.goapp.oReport.cReportName        = 'dmrxpumper.frx'
   m.goapp.oReport.CSVFilename        = 'pumpers.csv'

   m.goapp.oReport.cFriendlyName = 'Pumper Listing'

   llReturn = m.goapp.oReport.SendReport('S', .F., .F.)

**************************
PROCEDURE ClosedRun_Report
**************************
   LOCAL lnCount

*  Prints the closed period listing
   SET SAFETY OFF

   IF TYPE('m.goApp') # 'O'
      m.cproducer = 'Development Company'
   ELSE
      m.cproducer = m.goapp.cCompanyName
   ENDIF

   IF USED('tempsys')
      USE IN tempsys
   ENDIF

   lcTitle1   = ''
   lcTitle2   = ''
   SET DELETED ON
   SWSELECT('sysctl')
   SCAN FOR lYearClose AND EMPTY(crunyear)  &&  Fill in the run year for fiscal year closings, so it reports properly - BH 02/09/2007
      REPLACE crunyear WITH cyear
   ENDSCAN

   CREATE CURSOR tempsys  ;
      (crunyear       c(4),  ;
      nrunno          I,  ;
      cyear           c(4),  ;
      cperiod         c(2),  ;
      cRunYearNo      c(7),  ;
      cGroup          c(2),  ;
      ddateclose      D,  ;
      cTimeClose      c(8),  ;
      dacctdate       D,  ;
      dPostDate       D,  ;
      dAdvPosting     D, ;
      dRevDate        D,  ;
      dExpDate        D,  ;
      lCompanyPost    l,  ;
      lRelMin         l,  ;
      cversion        c(5), ;
      cTypeClose      c(1),  ;
      lYearClose      l)
   INDEX ON cTypeClose + cRunYearNo + DTOC(ddateclose) DESCENDING TAG cRunYearNo

   SELECT tempsys
   SET ORDER TO cRunYearNo
   APPEND FROM DBF('sysctl') FOR NOT 'BEG' $ cversion AND NOT nrunno = 9999

   SELECT tempsys  &&  Fill in the runyear on the accounting and fiscal year close records - BH 10/09/2006
   SCAN FOR EMPTY(crunyear)
      REPLACE crunyear WITH cyear, cGroup WITH ''
   ENDSCAN

   REPLACE nrunno WITH VAL(cperiod) FOR nrunno = 0 AND NOT EMPTY(cperiod)
   REPLACE cRunYearNo WITH crunyear + PADL(ALLTRIM(STR(nrunno)), 3, '0') ALL  &&  Fill in sortfield, formatted properly

   IF _TALLY > 0
      m.goapp.oReport.cAlias          = 'tempsys'
      m.goapp.oReport.DATASESSIONID       = 1
      m.goapp.oReport.cTitle1          = 'Closed Run Listing'
      m.goapp.oReport.cTitle2          = ''
      m.goapp.oReport.cProcessor       = ''
      m.goapp.oReport.cSortOrder       = ''
      m.goapp.oReport.cSelectionCriteria = ''
      m.goapp.oReport.cReportName       = 'dmrxprdcls.frx'
      m.goapp.oReport.CSVFilename       = 'Closed Runs.csv'
      m.goapp.oReport.cFriendlyName       = 'Closed Run Listing'
      llReturn                      = m.goapp.oReport.SendReport('S', .F., .F.)
   ELSE
      MESSAGEBOX('No closings have been done, so no report can be generated.', 64, 'Closed Run Listing')
   ENDIF

   USE IN sysctl

*********************************
PROCEDURE IsForeignAddress
*********************************
   LPARAMETERS tcState

   lcStates = 'AL MO AK MT AZ NE AR NV CA NH CO NJ CT NM DE NY DC NC FL ND GA OH HI OK ID OR IL PA IN RI IA SC KS SD KY TN LA TX ME UT MD VT MA VA MI WA MN WV MS WI WY,VI'
   IF NOT tcState $ lcStates
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF

************************************************************
FUNCTION IsOnHold(tcOwnerid, tlIntHold, tcwellid, tcTypeInv)
************************************************************
   LOCAL llReturn, loError
*
* Checks to see if an owner or interest on hold
*
   llReturn = .F.

   TRY

      IF NOT tlIntHold
         SWSELECT('investor')
         SET ORDER TO cownerid
         IF SEEK(tcOwnerid)
            IF lhold
               llReturn = .T.
            ENDIF
         ENDIF
      ELSE
         SWSELECT('wellinv')
         SET ORDER TO wellinvid
         IF SEEK(tcwellid + tcOwnerid + tcTypeInv)
            IF lonhold
               llReturn = .T.
            ENDIF
         ELSE
            llReturn = .F.
         ENDIF
      ENDIF
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'IsOnHold', loError.LINENO, 'Suspense', loError.ERRORNO, loError.MESSAGE, ' ', loError
      MESSAGEBOX('Unable to process the suspense at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY

   RETURN llReturn

*************************
FUNCTION ExitApp()
************************

   DECLARE INTEGER ExitProcess IN WIN32API
   ExitProcess()

******************************************
FUNCTION KillProcess(tnProcess, tnhWnd)
******************************************
   LOCAL lnhWnd, ;
      llReturn, ;
      lnProcessID, ;
      lnHandle
* Declare the Win32API functions we need.
   #DEFINE WM_DESTROY 0x0002
   DECLARE INTEGER FindWindow IN Win32API ;
      STRING @cClassName, STRING @cWindowName
   DECLARE INTEGER SendMessage IN Win32API ;
      INTEGER HWND, INTEGER uMsg, INTEGER wParam, INTEGER LPARAM
   DECLARE Sleep IN Win32API ;
      INTEGER nMilliseconds
   DECLARE INTEGER GetWindowThreadProcessId IN Win32API ;
      INTEGER HWND, INTEGER @lpdwProcessId
   DECLARE INTEGER OpenProcess IN Win32API ;
      INTEGER dwDesiredAccess, INTEGER bInheritHandle, ;
      INTEGER dwProcessID
   DECLARE INTEGER TerminateProcess IN Win32API ;
      INTEGER hProcess, INTEGER uExitCode

   IF tnhWnd # 0
      SendMessage(tnhWnd, WM_DESTROY, 0, 0)
   ENDIF
   llReturn = WaitForAppTermination(tnProcess)
   IF NOT llReturn
      lnProcessID = 0
*!*            GetWindowThreadProcessId(tnhWnd, @lnProcessID)
      lnHandle = OpenProcess(1, 1, tnProcess)
      llReturn = TerminateProcess(lnHandle, 0) > 0
   ENDIF

   RETURN llReturn

******************************
FUNCTION WaitForAppTermination
******************************
   LPARAMETERS tnProcess
   LOCAL lnCounter, ;
      llReturn
   lnCounter   = 0
   llReturn      = .F.
   lnProcesses = AProcesses('laProcess')
   lnRow      = ASCAN(laProcess, tnProcess, 1, -1, 2, 8)
   DO WHILE lnRow > 0 AND lnCounter < 5
      Sleep(1000)
      lnCounter     = lnCounter + 1
      lnProcesses = AProcesses('laProcess')
      lnRow        = ASCAN(laProcess, tnProcess, 1, -1, 2, 8)
   ENDDO WHILE
   IF lnRow = 0
      llReturn = .T.
   ENDIF
   RETURN llReturn


******************************
FUNCTION  GetMonth(tcMonth)
******************************
   LOCAL lcMonth

   lcMonth = 'January'

   IF NOT BETWEEN(tcMonth,'01','12')
      tcMonth = PADL(TRANSFORM(MONTH(DATE())),2,'0')
   ENDIF

   DO CASE
      CASE tcMonth = '01'
         lcMonth = 'January'
      CASE tcMonth = '02'
         lcMonth = 'February'
      CASE tcMonth = '03'
         lcMonth = 'March'
      CASE tcMonth = '04'
         lcMonth = 'April'
      CASE tcMonth = '05'
         lcMonth = 'May'
      CASE tcMonth = '06'
         lcMonth = 'June'
      CASE tcMonth = '07'
         lcMonth = 'July'
      CASE tcMonth = '08'
         lcMonth = 'August'
      CASE tcMonth = '09'
         lcMonth = 'September'
      CASE tcMonth = '10'
         lcMonth = 'October'
      CASE tcMonth = '11'
         lcMonth = 'November'
      CASE tcMonth = '12'
         lcMonth = 'December'
   ENDCASE

   RETURN lcMonth

ENDFUNC

***************************
FUNCTION at_pay_freq
***************************
   LPARAMETERS tcOwnerid, tdAcctDate
   LOCAL llReturn, loError, tnDisbFreq

   tnDisbFreq = 1

   llReturn = .T.

   TRY
      SWSELECT('investor')
      SET ORDER TO cownerid
      IF SEEK(tcOwnerid)
         tnDisbFreq = ndisbfreq
      ELSE
         llReturn = .F.
         EXIT
      ENDIF

      DO CASE
         CASE tnDisbFreq = 1 OR tnDisbFreq = 0
            llReturn = .T.
            EXIT
         CASE tnDisbFreq = 2
            IF INLIST(MONTH(tdAcctDate), 3, 6, 9, 12)
               llReturn = .T.
               EXIT
            ELSE
               llReturn = .F.
               EXIT
            ENDIF

         CASE tnDisbFreq = 3
            IF INLIST(MONTH(tdAcctDate), 6, 12)
               llReturn = .T.
               EXIT
            ELSE
               llReturn = .F.
               EXIT
            ENDIF

         CASE tnDisbFreq = 4
            IF INLIST(MONTH(tdAcctDate), 12)
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
      DO errorlog WITH 'At_Pay_Freq', loError.LINENO, 'SwUtils', loError.ERRORNO, loError.MESSAGE, ' ', loError
   ENDTRY

   RETURN llReturn

ENDFUNC


***************************************
FUNCTION splitnames(tcName)
***************************************
   LOCAL llSuffix, llCompany, oName
   STORE .F. TO llSuffix, llCompany, llSuffixLast, llAmpersand, llOr
   STORE ''  TO lcFirstName, lcMidName, lcLastName

   tcName = ALLT(tcName)
   lnAmpPos = 0

   oName = CREATEOBJECT('empty')
   ADDPROPERTY(oName,'cLastName','')
   ADDPROPERTY(oName,'cMidName','')
   ADDPROPERTY(oName,'cFirstName','')

   llAmpersand = '&' $ tcName
   llOr = ' OR ' $ UPPER(tcName)
   IF llAmpersand OR llOr
      FOR x = 1 TO GETWORDCOUNT(tcName)
         lcWord = UPPER(GETWORDNUM(tcName,x))
         IF lcWord = '&' OR lcWord = 'OR'
            lnAmpPos = x
         ENDIF
      ENDFOR
   ENDIF
   lnWordCount = GETWORDCOUNT(tcName)

   DO CASE

&&  Things that would cause it to go back 2 spaces from the end before reversing
      CASE RIGHT(UPPER(tcName), 3) = 'JR.' OR RIGHT(UPPER(tcName), 2) = 'JR' OR RIGHT(UPPER(tcName), 3) = 'III' OR RIGHT(UPPER(tcName), 6) = 'ESTATE' OR RIGHT(UPPER(tcName), 2) = 'IV' ;
            OR RIGHT(UPPER(tcName), 2) = ' V' OR RIGHT(UPPER(tcName), 3) = 'L P' OR RIGHT(UPPER(tcName), 2) = 'SR' OR RIGHT(UPPER(tcName), 3) = 'SR.'  OR RIGHT(UPPER(tcName), 3) = ' II' ;
            OR RIGHT(UPPER(tcName), 6) = 'AND/OR' OR RIGHT(UPPER(tcName), 1) = '&' OR RIGHT(UPPER(tcName), 5) = 'EXEC.' OR RIGHT(UPPER(tcName), 4) = ', MD' OR RIGHT (UPPER(tcName), 5) = ', MD.' ;
            OR RIGHT(UPPER(tcName), 3) = ' MD' OR RIGHT(UPPER(tcName), 4) = ' MD.' OR RIGHT(UPPER(tcName), 4) = ' TUW' OR RIGHT(UPPER(tcName), 5) = ' TRST' OR RIGHT(UPPER(tcName), 4) = 'M.D.'
         llSuffix = .T.

         lastword = GETWORDNUM(tcName,lnWordCount)
         IF UPPER(lastword) = 'JR.' OR UPPER(lastword) = 'JR' OR UPPER(lastword) = 'III' OR UPPER(lastword) = 'ESTATE' OR UPPER(lastword) = 'IV' ;
               OR UPPER(lastword) = ' V' OR UPPER(lastword) = 'L P' OR UPPER(lastword) = 'SR' OR UPPER(lastword) = 'SR.'  OR UPPER(lastword) = ' II' ;
               OR UPPER(lastword) = 'AND/OR' OR UPPER(lastword) = '&' OR UPPER(lastword) = 'EXEC.' OR UPPER(lastword) = ', MD' OR UPPER(lastword) = ', MD.' ;
               OR UPPER(lastword) = ' MD' OR UPPER(lastword) = ' MD.' OR UPPER(lastword) = ' TUW' OR UPPER(lastword) = ' TRST' OR UPPER(lastword) = 'M.D.'
            llSuffixLast = .T.
         ENDIF
         llSuffix = .T.


&&  Things that would cause it NOT to be reversed
      CASE 'COMPANY' $ UPPER(tcName) OR 'BANK' $ UPPER(tcName) OR 'INC.' $ UPPER(tcName) OR 'CO.' $ UPPER(tcName) OR 'OPERATING' $ UPPER(tcName) OR 'COMPANY' $ UPPER(tcName) ;
            OR 'PROPERTIES' $ UPPER(tcName) OR 'LIVING' $ UPPER(tcName) OR 'TRUST' $ UPPER(tcName) OR 'LTD' $ UPPER(tcName) OR ' LAND' $ UPPER(tcName) OR 'PARTNER' $ UPPER(tcName) ;
            OR 'CORP.' $ UPPER(tcName) OR 'CORPORATION' $ UPPER(tcName) OR 'PETROLEUM' $ UPPER(tcName) OR 'PROPERTY' $ UPPER(tcName) OR 'LIMITED' $ UPPER(tcName) OR 'PRODUCTION' $ UPPER(tcName) ;
            OR 'LLC' $ UPPER(tcName) OR 'CORP' $ UPPER(tcName) OR 'LLP' $ UPPER(tcName) OR 'FOUNDATION' $ UPPER(tcName) OR 'CONSERVATION' $ UPPER(tcName) OR 'DEVELOPMENT' $ UPPER(tcName) ;
            OR 'ASSOCIATION' $ UPPER(tcName) OR 'METHODIST' $ UPPER(tcName) OR 'SCHOOL' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 4) = ' AND' OR RIGHT(UPPER(tcName), 1) = ')' ;
            OR RIGHT(UPPER(tcName), 3) = 'INC' OR 'CONSOLIDATED' $ UPPER(tcName) OR 'INVESTMENT' $ UPPER(tcName) OR 'CONSULTANT' $ UPPER(tcName) OR 'COLLECTION' $ UPPER(tcName) ;
            OR 'CREEK' $ UPPER(tcName) OR 'GROUP' $ UPPER(tcName) OR '#' $ UPPER(tcName) OR 'MANUFACTURING' $ UPPER(tcName) OR 'GAS ' $ UPPER(tcName) OR 'RESOURCES' $ UPPER(tcName) ;
            OR 'SUMMIT' $ UPPER(tcName) OR 'CHURCH' $ UPPER(tcName) OR 'SERVICE' $ UPPER(tcName) OR 'MINERALS' $ UPPER(tcName) OR 'BAPTIST' $ UPPER(tcName) OR 'STATE' $ UPPER(tcName) ;
            OR 'RENTAL' $ UPPER(tcName) OR 'DRILLING' $ UPPER(tcName) OR 'OWNER' $ UPPER(tcName) OR 'REFINING' $ UPPER(tcName) OR 'INTEREST' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 4) = ' TRT' ;
            OR 'ROYALTIES' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 3) = ' CO' OR 'TENANT' $ UPPER(tcName) OR 'ASSOCIATES' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 4) = ' TTE' ;
            OR RIGHT(UPPER(tcName), 4) = ' DBA' OR RIGHT(UPPER(tcName), 6) = ' D/B/A' OR RIGHT(UPPER(tcName), 4) = ' TR.' OR 'ELECTRIC' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 3) = ' LP' ;
            OR 'NATURAL' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 4) = ' EST' OR 'ENERGY' $ UPPER(tcName) OR 'REVOC' $ UPPER(tcName) OR 'EXPLORATION' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 5) = ' TTEE' ;
            OR 'COMP.' $ UPPER(tcName) OR ' OIL' $ UPPER(tcName) OR 'TRST.' $ UPPER(tcName) OR 'FIREPROOFING' $ UPPER(tcName) OR 'LAKE ERIE' $ UPPER(tcName) OR 'FARMS' $ UPPER(tcName) ;
            OR 'RANCH' $ UPPER(tcName) OR 'COMMISSIONER' $ UPPER(tcName) OR 'MOBILE HOMES' $ UPPER(tcName) OR 'KILLBUCK' $ UPPER(tcName) OR 'APARTMENT' $ UPPER(tcName) OR 'WORKERS' $ UPPER(tcName) ;
            OR 'BRONCO' $ UPPER(tcName) OR 'AGENT' $ UPPER(tcName) OR 'HEIRS' $ UPPER(tcName) OR 'CHARLESTON' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 6) = 'L.L.C.' OR 'AIRSTRIP' $ UPPER(tcName) ;
            OR ' TR ' $ UPPER(tcName) OR ' REV ' $ UPPER(tcName) OR 'TELEPHONE' $ UPPER(tcName) OR 'DOZEN' $ UPPER(tcName) OR 'COMMUNITY' $ UPPER(tcName) OR 'SEP -' $ UPPER(tcName) ;
            OR 'DEPARTMENT' $ UPPER(tcName) OR 'BOYS HOME' $ UPPER(tcName) OR 'DEPOSIT' $ UPPER(tcName) OR 'ENGINEER' $ UPPER(tcName) OR '2001' $ UPPER(tcName) OR '2002' $ UPPER(tcName) ;
            OR '2003' $ UPPER(tcName) OR 'COLLEGE' $ UPPER(tcName) OR 'PRESBYTERIAN' $ UPPER(tcName) OR 'TOWN OF' $ UPPER(tcName) OR 'INVEST' $ UPPER(tcName) OR 'HOME FOR' $ UPPER(tcName) ;
            OR 'CONGREGATION' $ UPPER(tcName) OR ' BANK ' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 5) = ' BANK' OR 'HOSPITAL' $ UPPER(tcName) OR 'BIBLE ' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 5) = ' L.C.' ;
            OR 'CEMETERY' $ UPPER(tcName) OR 'LUTHERAN' $ UPPER(tcName) OR 'LODGE' $ UPPER(tcName) OR 'PAID' $ UPPER(tcName) OR RIGHT(UPPER(tcName), 4) = 'L.P.' OR RIGHT(UPPER(tcName), 3) = ' TR' ;
            OR 'SOCIETY' $ UPPER(tcName) OR 'TRST' $ UPPER(tcName) OR 'EXEC' $ UPPER(tcName) OR 'FARM' $ UPPER(tcName)
         llCompany = .T.
   ENDCASE

   IF llCompany
      lcFirstName = ''
      lcMidName   = ''
      lcLastName = UPPER(tcName)
   ELSE
      lnCount = GETWORDCOUNT(UPPER(tcName))
      llComma = ',' $ UPPER(tcName)

      IF NOT llSuffix
         DO CASE
            CASE lnCount = 1
               lcFirstName = ''
               lcMidName   = ''
               lcLastName  = UPPER(tcName)
            CASE lnCount = 2
               IF llComma
                  lcFirstName = GETWORDNUM(UPPER(tcName),2)
                  lcMidName   = ''
                  lcLastName  = GETWORDNUM(UPPER(tcName),1)
               ELSE
                  lcFirstName = GETWORDNUM(UPPER(tcName),1)
                  lcMidName   = ''
                  lcLastName  = GETWORDNUM(UPPER(tcName),2)
               ENDIF
            CASE lnCount = 3
               IF llComma
                  lcFirstName = GETWORDNUM(UPPER(tcName),2)
                  lcMidName   = GETWORDNUM(UPPER(tcName),3)
                  lcLastName  = GETWORDNUM(UPPER(tcName),1)
               ELSE
                  lcFirstName = GETWORDNUM(UPPER(tcName),1)
                  lcMidName   = GETWORDNUM(UPPER(tcName),2)
                  lcLastName  = GETWORDNUM(UPPER(tcName),3)
               ENDIF
            CASE lnCount = 4
               IF llComma
                  lcFirstName = GETWORDNUM(UPPER(tcName),4)
                  lcMidName   = GETWORDNUM(UPPER(tcName),2) + ' ' + GETWORDNUM(UPPER(tcName),3)
                  lcLastName  = GETWORDNUM(UPPER(tcName),1)
               ELSE
                  IF llAmpersand OR llOr
                     IF lnAmpPos = 2
                        lcFirstName = GETWORDNUM(UPPER(tcName),1) + ' ' + GETWORDNUM(tcName,2) + ' ' + GETWORDNUM(UPPER(tcName),3)
                        lcMidName   = ''
                        lcLastName  = GETWORDNUM(UPPER(tcName),4)
                     ELSE
                        lcFirstName = GETWORDNUM(UPPER(tcName),1)
                        lcMidName   = GETWORDNUM(UPPER(tcName),2) + ' ' + GETWORDNUM(UPPER(tcName),3)
                        lcLastName  = GETWORDNUM(UPPER(tcName),4)
                     ENDIF
                  ELSE
                     lcFirstName = GETWORDNUM(UPPER(tcName),1)
                     lcMidName   = GETWORDNUM(UPPER(tcName),2) + ' ' + GETWORDNUM(UPPER(tcName),3)
                     lcLastName  = GETWORDNUM(UPPER(tcName),4)
                  ENDIF
               ENDIF
            CASE lnCount = 5
               IF llComma
                  lcFirstName = GETWORDNUM(UPPER(tcName),5)
                  lcMidName   = GETWORDNUM(UPPER(tcName),2) + ' ' + GETWORDNUM(UPPER(tcName),3)
                  lcLastName  = GETWORDNUM(UPPER(tcName),1)
               ELSE
                  IF llAmpersand OR llOr
                     DO CASE
                        CASE  lnAmpPos = 2
                           lcFirstName = GETWORDNUM(UPPER(tcName),1) + ' '+GETWORDNUM(UPPER(tcName),2)+' '+GETWORDNUM(UPPER(tcName),3)
                           lcMidName   = GETWORDNUM(UPPER(tcName),4)
                           lcLastName  = GETWORDNUM(UPPER(tcName),5)
                        CASE  lnAmpPos = 3
                           lcFirstName = GETWORDNUM(UPPER(tcName),1) + ' '+GETWORDNUM(UPPER(tcName),2)+' '+GETWORDNUM(UPPER(tcName),3) + ' '+GETWORDNUM(UPPER(tcName),4)
                           lcMidName   = ''
                           lcLastName  = GETWORDNUM(UPPER(tcName),5)
                        OTHERWISE
                           lcFirstName = GETWORDNUM(UPPER(tcName),1) + ' ' + GETWORDNUM(UPPER(tcName),2)
                           lcMidName   = ''
                           lcLastName  = GETWORDNUM(UPPER(tcName),3)
                     ENDCASE
                  ELSE
                     lcFirstName = GETWORDNUM(UPPER(tcName),1)
                     lcMidName   = GETWORDNUM(UPPER(tcName),2) + ' '+GETWORDNUM(UPPER(tcName),3)+' '+GETWORDNUM(UPPER(tcName),4)
                     lcLastName  = GETWORDNUM(UPPER(tcName),5)
                  ENDIF
               ENDIF
            OTHERWISE
               lcFirstName = ''
               lcMidName   = ''
               lcLastName  = UPPER(tcName)
         ENDCASE
      ELSE
         DO CASE
            CASE lnCount = 3
               IF llComma
                  IF llSuffixLast
                     lcFirstName = GETWORDNUM(UPPER(tcName),1)
                     lcMidName   = ''
                     lcLastName  = GETWORDNUM(UPPER(tcName),2) + ' ' + GETWORDNUM(UPPER(tcName),3)
                  ELSE
                     lcFirstName = GETWORDNUM(UPPER(tcName),3)
                     lcMidName   = ''
                     lcLastName  = GETWORDNUM(UPPER(tcName),1) + ' ' + GETWORDNUM(UPPER(tcName),2)
                  ENDIF
               ELSE
                  lcFirstName = GETWORDNUM(UPPER(tcName),1)
                  lcMidName   = ''
                  lcLastName  = GETWORDNUM(UPPER(tcName),3) + ' ' + GETWORDNUM(UPPER(tcName),2)
               ENDIF
            CASE lnCount = 4
               IF llComma
                  IF llSuffixLast
                     lcFirstName = GETWORDNUM(UPPER(tcName),1)
                     lcMidName   = GETWORDNUM(UPPER(tcName),2)
                     lcLastName  = GETWORDNUM(UPPER(tcName),3)+ ' ' + GETWORDNUM(UPPER(tcName),4)
                  ELSE
                     lcFirstName = GETWORDNUM(UPPER(tcName),3)
                     lcMidName   = GETWORDNUM(UPPER(tcName),4)
                     lcLastName  = GETWORDNUM(UPPER(tcName),1)+ ' ' + GETWORDNUM(UPPER(tcName),2)
                  ENDIF
               ELSE
                  lcFirstName = GETWORDNUM(UPPER(tcName),1)
                  lcMidName   = GETWORDNUM(UPPER(tcName),2)
                  lcLastName  = GETWORDNUM(UPPER(tcName),3)+ ' ' + GETWORDNUM(UPPER(tcName),4)
               ENDIF
            OTHERWISE
               lcFirstName = ''
               lcMidName   = ''
               lcLastName  = UPPER(tcName)
         ENDCASE
      ENDIF
   ENDIF

   m.cfirstname = UPPER(STRTRAN(lcFirstName,',',''))
   m.cfirstname = STRTRAN(m.cfirstname,'.','')
   m.cmidname   = UPPER(STRTRAN(lcMidName,',',''))
   m.cmidname   = STRTRAN(m.cmidname,'.','')
   m.clastname  = UPPER(STRTRAN(lcLastName,',',''))
   m.clastname  = STRTRAN(m.clastname,'.','')

   oName.cfirstname = m.cfirstname
   oName.cmidname   = m.cmidname
   oName.clastname  = m.clastname

   RETURN oName
ENDFUNC

************************************
PROCEDURE CreateLoginsTable
************************************

   IF NOT FILE(m.goapp.cCommonfolder+'logins.dbf')
      CREATE TABLE (m.goapp.cCommonfolder+'logins') FREE ;
         (cuser     c(20), ;
         logged_in  T, ;
         logged_out T, ;
         DEVICE     c(40), ;
         company    c(60), ;
         forced_out l)
   ELSE
      TRY
         SWSELECT('logins')
         IF LEN(logins.DEVICE) < 40
            USE IN logins
            ERASE (m.goapp.cCommonfolder+'logins.dbf')
* Create the table with the right size device field
            CreateLoginsTable()
         ENDIF
      CATCH
      ENDTRY
   ENDIF
ENDPROC

**************************************
PROCEDURE LogOutUser
**************************************

   CreateLoginsTable()
   SWSELECT('logins')
   SCAN FOR LOWER(DEVICE) = ALLTRIM(LOWER(SYS(0))) AND EMPTY(logged_out)
      REPLACE logged_out WITH DATETIME(), ;
         forced_out WITH .F.
   ENDSCAN

***************************************
PROCEDURE AutoConnectComp
***************************************

   SWSELECT('compmast')

   lnFolders = ADIR(lafolders,m.goapp.cCommonfolder+'*','D')
   SET enginebehavior 70
   lnChanged = 0
   IF lnFolders > 0

      FOR x = 1 TO lnFolders

         lcDir = lafolders[x,1]

         IF NOT EMPTY(JUSTEXT(lcDir))
            LOOP
         ENDIF

         IF EMPTY(lcDir)
            LOOP
         ENDIF

         IF lcDir='.'
            LOOP
         ENDIF

         SELECT compmast
         LOCATE FOR ALLTRIM(LOWER(lcDir)) $ cdatapath
         IF FOUND()
            LOOP
         ENDIF


         llFoundComp = .T.
         IF NOT USED('version')
            USE (ALLTRIM(m.cdatapath) + 'version.dbf') IN 0
         ENDIF
         SELECT VERSION
         GO TOP
         SCATTER MEMVAR
         m.cdatapath = lcDataPath
         IF NOT USED('compmast1')
            USE compmast AGAIN IN 0 ALIAS compmast1
         ENDIF
         SELECT compmast1
         SET DELETED OFF
         SET ORDER TO cidcomp
         lcidcomp = THISFORM.oregistry.IncrementCounter('%Local.Counters.Company Master')
         DO WHILE SEEK(lcidcomp)
            lcidcomp = THISFORM.oregistry.IncrementCounter('%Local.Counters.Company Master')
         ENDDO
         SET DELETED ON
         m.cidcomp = lcidcomp
         IF NOT USED('compmast')
            USE compmast IN 0
         ENDIF
         INSERT INTO compmast FROM MEMVAR
      ENDFOR
   ENDIF
ENDPROC

*********************************************
FUNCTION SetVFPMemory
*//*****************************************************************************************
*//  FUNCTION NAME: lpSetMemory
*//
*//  AUTHOR: White Light Computing, Inc. 05/16/2014
*//
*//  COPYRIGHT © 2010-2014   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION:
*//      Sets the foreground or background buffer memory size for VFP
*//      Discussion in FoxWiki http://fox.wikis.com/wc.dll?Wiki~sys3050~Wiki*//
*//
*//      Uses a file: VfpBufferMemory.txt. If it doesn't exist, creates it.
*//
*//  PARAMETERS:
*//    INPUT PARAMETERS:
*//       None
*//
*//    OUTPUT PARAMETERS:
*//       If the VfpBufferMemory.txt file doesn't exist, creates it.
*//******************************************************************************************
   LOCAL ;
      lcVfpBufferMemoryFile AS CHARACTER ;
      ,llReturn AS Boolean ;
      ,lnLines AS INTEGER ;
      ,lnx AS INTEGER ;
      ,lcCmd AS CHARACTER ;
      ,lnMemoWidth AS INTEGER

   m.llReturn    = .T.
   m.lnMemoWidth = SET('MemoWidth')

   IF m.lnMemoWidth < 8192
      SET MEMOWIDTH TO 8192
   ENDIF

   IF FILE('datafiles\VfpBufferMemory.txt')
      m.lcVfpBufferMemoryFile = FILETOSTR('datafiles\VfpBufferMemory.txt')
      m.lnLines = MEMLINES(ALLTRIM(m.lcVfpBufferMemoryFile))
      FOR m.lnx = 1 TO m.lnLines
         m.lcCmd = ALLTRIM(MLINE(m.lcVfpBufferMemoryFile, m.lnx))
         IF EMPTY(m.lcCmd) ;
               OR m.lcCmd = '*'
            LOOP
         ELSE
            &lcCmd  && Run the code
         ENDIF
      ENDFOR
   ELSE
*-- Set the the foreground and background memory size for VFP
      SYS(3050, 1, MIN(536870912, VAL(SYS(3050, 1, 0))))
      SYS(3050, 2, MIN(536870912, VAL(SYS(3050, 1, 0))))

*-- Create the VfpBufferMemory.txt file
      TEXT TO m.lcVfpBufferMemoryFile TEXTMERGE NOSHOW FLAGS 3 PRETEXT 3
         * ------------------------------------------------------------------------
         * Name: VfpBufferMemory.txt
         * Sets the foreground or background buffer memory size for VFP
         * Discussion in FoxWiki http://fox.wikis.com/wc.dll?Wiki~sys3050~Wiki*//'
         * ------------------------------------------------------------------------
         SYS(3050, 1, MIN(536870912, VAL(SYS(3050, 1, 0))))
         SYS(3050, 2, MIN(536870912, VAL(SYS(3050, 1, 0))))
         * eof
      ENDTEXT

      m.llReturn = STRTOFILE(m.lcVfpBufferMemoryFile,'datafiles\VfpBufferMemory.txt',0)
   ENDIF

   IF m.lnMemoWidth <> 8192
      SET MEMOWIDTH TO lnMemoWidth
   ENDIF

   RETURN m.llReturn

ENDFUNC
FUNCTION IsExeRunning(tcName, tlTerminate)
   LOCAL loLocator, loWMI, loProcesses, loProcess, llIsRunning
   loLocator    = CREATEOBJECT('WBEMScripting.SWBEMLocator')
   loWMI      = loLocator.ConnectServer()
   loWMI.Security_.ImpersonationLevel = 3        && Impersonate
   loProcesses   = loWMI.ExecQuery([SELECT * FROM Win32_Process WHERE Name = '] + tcName + ['])
   llIsRunning = .F.
   IF loProcesses.COUNT > 0
      FOR EACH loProcess IN loProcesses
         llIsRunning = .T.
         IF tlTerminate
            loProcess.TERMINATE(0)
         ENDIF
      ENDFOR
   ENDIF
   RETURN llIsRunning
ENDFUNC
************************************
FUNCTION ConvertExcelDate(tnDate)
***********************************
   LOCAL lddate
   IF VARTYPE(tnDate) = 'N'
      lddate = CTOD('12/30/1899') + INT(tnDate)
   ELSE
      lddate = CTOD('12/30/1899') + INT(VAL(tnDate))
   ENDIF
   RETURN lddate
ENDFUNC
*****************************************
FUNCTION swLogUsage(tcProcess)
*****************************************
   TRY
      IF NOT FILE(m.goapp.cCommonfolder + '_lxx.dbf')
         CREATE TABLE (m.goapp.cCommonfolder + '_lxx.dbf') FREE ;
            (tdatetime   T, ;
            cprocess    c(40))
      ELSE
         IF NOT USED('_lxx')
            USE (m.goapp.cCommonfolder + '_lxx') IN 0
         ENDIF
      ENDIF
      IF NOT EMPTY(tcProcess)
         m.tdatetime = DATETIME()
         m.cprocess  = tcProcess
         INSERT INTO _lxx FROM MEMVAR
      ENDIF
   CATCH TO loError
   ENDTRY
ENDFUNC
*******************************************
FUNCTION GetDDEffDate(lcrunyear, lnrunno)
*******************************************
   LOCAL laFiles[1], lcDate, lcFile, lcLine, lcPath, lcString, lddate, llFound, lnFiles, lnWidth
*:Global nseq
   lnWidth = SET('memowidth')
   SET MEMOWIDTH TO 94
   lcPath = m.goapp.cdatafilepath
   lddate = {}
   llFound = .F.
   FOR nseq = 10 TO 1 STEP - 1
      lcFile = 'DP' + lcrunyear + PADL(TRANSFORM(lnrunno), 3, '0') + '_' + TRANSFORM(nseq) + '.txt'
      lnFiles = ADIR(laFiles, ADDBS(lcPath) + 'ACH\' + lcFile)
      IF lnFiles > 0
         lcString = FILETOSTR(ADDBS(lcPath) + 'ACH\' + lcFile)
         lcLine   = MLINE(lcString, 2)
         lcDate   = SUBSTR(lcLine, 70, 6)
         lddate   = CTOD(SUBSTR(lcDate, 3, 2) + '/' + SUBSTR(lcDate, 5, 2) + '/' + '20' + LEFT(lcDate, 2))
         llFound  = .T.
         EXIT
      ENDIF
   ENDFOR
   IF NOT llFound
      lcFile = 'DP' + lcrunyear + PADL(TRANSFORM(lnrunno), 3, '0') + '.txt'
      lnFiles = ADIR(laFiles, ADDBS(lcPath) + 'ACH\' + lcFile)
      IF lnFiles > 0
         lcString = FILETOSTR(ADDBS(lcPath) + 'ACH\' + lcFile)
         lcLine   = MLINE(lcString, 2)
         lcDate   = SUBSTR(lcLine, 70, 6)
         lddate   = CTOD(SUBSTR(lcDate, 3, 2) + '/' + SUBSTR(lcDate, 5, 2) + '/' + '20' + LEFT(lcDate, 2))
      ENDIF
   ENDIF
   SET MEMOWIDTH TO (lnWidth)
   RETURN lddate

***********************************
FUNCTION FlatDate(tdDate)
***********************************
   LOCAL tcDate
**Utility to transform the date from mm\dd\yyyy to yyyy\mm\dd

   IF NOT EMPTY(tdDate)
      tcDate = DTOS(tdDate)
   ENDIF

   RETURN tcDate

***********************************
FUNCTION FlatAmount(tnAmount)
***********************************
   LOCAL lcAmount
**Utility to transform the amount from $$$.$$ to $$$$$

   lcAmount = PADL(ALLTRIM(STRTRAN(TRANSFORM(tnAmount, '99999999.99'), '.', '')), 13, '0')

   RETURN lcAmount

***********************************
FUNCTION FlatTime(tnTime)
***********************************
   LOCAL lcTime
**Utility to transform the time from hh:mm to hhmm

   lcTime = PADL(LTRIM(STR(HOUR(DATETIME()))), 2, '0') + PADL(LTRIM(STR(MINUTE(DATETIME()))), 2, '0')

   RETURN lcTime

***********************************
FUNCTION FlatZip(tnzip)
***********************************
   LOCAL lcZip
**Utility to transform the Zip Code from 12345-6789 to 123456789

   lcZip = STRTRAN(tnzip, '-', '')

   RETURN lcZip
   
**********************************
FUNCTION FieldExists(tcTable, tcFieldName, tcPath)
**********************************
* Looks for the given field in the table and returns .T. if it exists
    LOCAL lnI, laFields[1], lcFieldName, llReturn

    llReturn = .F.

    lcFieldName = tcFieldName  && Change this to the name of the field you're looking for

    IF USED('curFieldExists')
       USE IN curFieldExists
    ENDIF
    IF USED(tcTable)
       USE IN (tcTable)
    ENDIF 
    
    USE (tcPath+tcTable) IN 0 ALIAS curFieldExists
    SELECT curFieldExists
    lnI = AFIELDS(laFields)  && Creates an array of field names

    FOR lnI = 1 TO ALEN(laFields, 1)  && Loops through the array
        IF UPPER(laFields[lnI, 1]) = UPPER(lcFieldName)  && Compares field names
            llReturn = .T.
            EXIT
        ENDIF
    ENDFOR

    swclose('curFieldExists')

    RETURN llReturn
   
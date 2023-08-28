LPARAMETERS tlRemove

LOCAL lnCountD, lncountS, llReturn
*:Global crectype
PRIV lcTitle1, lcTitle2, lcSortOrder, lcSelect, glGrpName, m.cGrpName, llPrinted

* Check to see if the dupechk1.txt file exists
* If it doesn't that means that the utility is being
* run from the special utilities menu probably because
* there are a lot of records and they chose not to run
* it when they opened the company.
tlDupeChk = FILE(m.goapp.cdatafilepath+'dupechk1.txt')
llSkipHist = FILE(m.goapp.cdatafilepath+'skipdupehist.txt')
m.details = ''

llReturn = .T.
TRY
   WAIT WINDOW NOWAIT 'Performing File Integrity Check Setup...'
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
   INDEX ON crectype TAG crectype
   CREATE CURSOR keeprecs (ciddisb c(8))

   IF (tlRemove AND !tlDupeChk) OR NOT tlRemove
      SELECT  * ;
         FROM suspense ;
         WHERE nnetcheck # 0 ;
         AND ciddisb <> '#' ;
         INTO CURSOR susptemp READWRITE ;
         ORDER BY ciddisb, cownerid, cwellid, crunyear_in, nrunno_in, hyear, hperiod, nnetcheck, ctypeinv, csusptype ;
         GROUP BY ciddisb, cownerid, cwellid, crunyear_in, nrunno_in, hyear, hperiod, nnetcheck, ctypeinv, csusptype
      INDEX ON cownerid TAG cownerid
      INDEX ON cwellid TAG cwellid
      INDEX ON hyear TAG hyear
      INDEX ON ctypeinv TAG ctypeinv
      INDEX ON hperiod TAG hperiod
      INDEX ON nnetcheck TAG nnetcheck
      INDEX ON nrunno_in TAG nrunno_in
      INDEX ON crunyear_in TAG crunyear
      INDEX ON ciddisb TAG ciddisb
      
      IF NOT llSkipHist
         lnmax = _TALLY * 2
      ELSE
         lnMax = _tally
      ENDIF    

            * Check to see if they have a lot of data to run through. If so, give them the opportunity to run the utility later
      IF lnmax > 1000000
         IF MESSAGEBOX("This company has over a million records to check. This will probably take an hour to several hours to process. " + ;
               "Do you want to continue?  If you don't continue you can run the utility later from the Special " + ;
               "Utilities menu.",36,'Integrity Check') = 7
            llReturn = .F.
            EXIT
         ENDIF
      ENDIF
   ENDIF
   
  
   * The utility has already been run and taken
   * care of suspense.
   IF tlRemove AND tlDupeChk
      lnmax = RECCOUNT('suspense')
   ENDIF
   lnCount   = 1
   oprogress = m.goapp.omessage.progressbarex('Performing One-Time File Integrity Check: ', '')
   oprogress.setprogressrange(0, lnmax)
   oprogress.setprogressmessage('Processing suspense...')

   IF (tlRemove AND !tlDupeChk) OR NOT tlRemove
      * Remove all duplicate suspense entries
      SELECT susptemp
      SCAN
         SCATTER MEMVAR
         oprogress.updateprogress(lnCount)

         lnCount  = lnCount + 1
         IF m.nnetcheck = 0
            LOOP
         ENDIF
         lciddisb = m.ciddisb
         SELECT tmpsusp
         SCAN FOR cownerid = m.cownerid AND cwellid = m.cwellid AND nrunno_in = m.nrunno_in   ;
               AND crunyear_in = m.crunyear_in AND nnetcheck = m.nnetcheck AND nnetcheck # 0 ;
               AND hyear = m.hyear AND hperiod = m.hperiod AND ctypeinv = m.ctypeinv AND ciddisb <> lciddisb AND ciddisb <> '#'
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

      * Pare down the suspense table and only get the non-duplicate suspense
      * so we can process disbhist faster
      SELECT * FROM suspense INTO CURSOR fixedsusp READWRITE ;
         WHERE ciddisb NOT IN (SELECT ciddisb FROM delrecs WHERE crectype = 'S')
   ELSE
      * We didn't process suspense this time so we need to
      * get a cursor to use to process disbhist
      SELECT * FROM suspense INTO CURSOR fixedsusp
   ENDIF

   lnCountD = 0

   IF NOT llSkipHist
   oprogress.setprogressmessage('Processing Owner History...')

   * Scan through suspense looking to see if the entries were released
   * to disbhst but still remain in suspense. Grab the primary key of
   * any entries that are in disbhist so we can reverse them later.
   SELECT fixedsusp
   SCAN
      SCATTER MEMVAR

      oprogress.updateprogress(lnCount)
      lnCount  = lnCount + 1
      lciddisb = m.ciddisb

      * Scan through disbhist and only look at run year 2020 and beyond.
      * The suspense duplicate bug started near the end of 2020 so there
      * shouldn't be any runs before 2020 that have the problem.
      SELECT tmpdisb
      SCAN  FOR tmpdisb.crunyear > "2019" AND csusptype <> ' ' ;
            AND cownerid = m.cownerid AND cwellid = m.cwellid AND nrunno_in = m.nrunno_in  ;
            AND crunyear_in = m.crunyear_in  AND nnetcheck = m.nnetcheck AND nnetcheck # 0  ;
            AND hyear = m.hyear AND hperiod = m.hperiod AND ctypeinv = m.ctypeinv AND ciddisb <> lciddisb ;
            AND ciddisb <> '#'
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
   ENDIF 
   oprogress.closeprogress()

   IF lnCountD # 0 OR lncountS # 0

      IF (tlRemove AND !tlDupeChk) OR NOT tlRemove
         * We're either running this automatically or from the utilities menu
         * If it's from the utilities menu make sure we haven't run this part
         * before. The existence of the dupechk1.txt file tells us it has been
         * run before.
         SELECT  delrecs.crectype, delrecs.ctypeinv, delrecs.cownerid, delrecs.cwellid, ;
            investor.cownname, wells.cwellname, SUM(delrecs.nnetcheck) AS nTotal;
            FROM delrecs ;
            JOIN investor ;
            ON investor.cownerid = delrecs.cownerid ;
            JOIN wells ;
            ON wells.cwellid = delrecs.cwellid ;
            INTO TABLE (m.goapp.cdatafilepath+'delrpt')  ;
            ORDER BY crectype, delrecs.cownerid, delrecs.cwellid, delrecs.ctypeinv ;
            GROUP BY crectype, delrecs.cownerid, delrecs.cwellid, delrecs.ctypeinv


         * Create the body of the support case that will be sent to support@sherware.com
         m.cMethod = 'DupSuspFix'
         m.nLineNo = 0
         tcCaller  = 'Support'
         m.nENumber = 999
         m.cMessage = ''
         m.details = ''
         llQBSDKLog = .F.
         lcLogLocation = ''
         STORE 0 TO lnTotS, lnTotH

         m.details = 'Duplicates found in company: ' + m.goapp.ccompanyname + CHR(13)+CHR(13)

         SELECT delrpt
         SCAN
            SCATTER MEMVAR
            m.details = m.details + 'Type: ' + m.crectype + '  ' + ;
               'Owner: ' + PADR(ALLTRIM(m.cownerid),10,'_') + ' ' + ;
               PADR(ALLTRIM(m.cownname),20,'_') + ;
               'Well: ' + PADR(ALLTRIM(m.cwellid),10,'_') + ;
               PADR(ALLTRIM(m.cwellname),20,'_') + ;
               TRANSFORM(m.nTotal) + CHR(13)
            IF m.crectype = 'S'
               lnTotS = lnTotS + m.nTotal
            ELSE
               lnTotH = lnTotH + m.nTotal
            ENDIF
         ENDSCAN
         m.details = m.details + CHR(13) + 'Total Suspense: ' + TRANSFORM(lnTotS) + CHR(13) + ;
            'Total History:  ' + TRANSFORM(lnTotH)

         DO senderror WITH m.cMethod, m.nLineNo, tcCaller, m.nENumber, m.cMessage, m.details, llQBSDKLog, lcLogLocation, .T.

         * Remove the duplicate suspense entries found
         IF lncountS > 0
            SELECT suspense
            COPY TO (m.goapp.cdatafilepath+'suspbkup' + ALLT(STR(YEAR(DATE()))) + '_' + ;
               PADL(ALLT(STR(MONTH(DATE()))), 2, '0') + '_' ;
               + PADL(ALLT(STR(DAY(DATE()))), 2, '0')+ '_'+STRTRAN(TIME(),':','_'))
            DELETE FROM suspense WHERE ciddisb + 'S' IN (SELECT ciddisb + crectype FROM delrecs)
            WAIT CLEAR
         ENDIF

         MESSAGEBOX('There were some issues found in the integrity check. Support has been notified and will be ' + ;
            'contacting you if further action is necessary.',64,'File Integrity Check')
      ENDIF

      IF tlRemove
         IF lncountS > 0 AND !tlDupeChk  && Don't remove suspense a 2nd time if we did it up above
            SELECT suspense
            COPY TO (m.goapp.cdatafilepath+'suspbkup' + ALLT(STR(YEAR(DATE()))) + '_' + ;
               PADL(ALLT(STR(MONTH(DATE()))), 2, '0') + '_' ;
               + PADL(ALLT(STR(DAY(DATE()))), 2, '0')+ '_'+STRTRAN(TIME(),':','_'))
            DELETE FROM suspense WHERE ciddisb + 'S' IN (SELECT ciddisb + crectype FROM delrecs)
            WAIT CLEAR
         ENDIF

         IF lnCountD > 0
            * Do a backup before we change anything
            llReturn = MakeBackup()

            * If the backup was successful then create offsetting
            * suspense entries for the extra suspense that was
            * released to disbhist. This will recoup the overpayment
            * the next few runs by reducing the amount in suspense
            * for the owner or putting them into deficit
            IF llReturn
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
                     m.csusptype = 'D'
                     IF EMPTY(m.crunyear_in)
                        m.crunyear_in = m.crunyear
                        m.nrunno_in   = m.nrunno
                     ENDIF 
                     INSERT INTO suspense FROM MEMVAR
                  ENDIF
               ENDSCAN
               MESSAGEBOX('The File Integrity Check has completed. Duplicate owner history has been corrected.',64,'File Integrity Check')
            ENDIF
            SET DELETED ON
         ELSE
            MESSAGEBOX('The File Integrity Check has completed. No issues were found.',64,'File Integrity Check')
         ENDIF
      ENDIF
   ELSE
      * Create the body of the support case that will be sent to support@sherware.com
      * telling us that no problems were found in this company
      m.cMethod = 'DupSuspFix'
      m.nLineNo = 0
      tcCaller  = 'Support'
      m.nENumber = 999
      m.cMessage = ''
      m.details = ''
      llQBSDKLog = .F.
      lcLogLocation = ''
      m.details = 'No problems found for company: ' + m.goapp.ccompanyname + CHR(13)+CHR(13)
      DO senderror WITH m.cMethod, m.nLineNo, tcCaller, m.nENumber, m.cMessage, m.details, llQBSDKLog, lcLogLocation, .T., .T.
      MESSAGEBOX('The File Integrity Check has completed. No issues were found.',64,'File Integrity Check')
   ENDIF
CATCH TO loError
   llReturn = .F.
   DO errorlog WITH 'File Integrity', loError.LINENO, 'File Integrity', loError.ERRORNO, loError.MESSAGE, '', loError
ENDTRY

IF llReturn AND NOT tlDupeChk
   STRTOFILE('Completed: ' + TTOC(DATETIME())+CHR(13)+CHR(13)+m.details,m.goapp.cDataFilePath+'dupechk1.txt')
ENDIF    

RETURN llReturn

************************
PROCEDURE MakeBackup
   ************************

   LOCAL lcDataPath, lcFileName, lcFolderName, lcYear, oRegistry, oprogress
   LOCAL lcBackupPath, lcFolder, lcSavePath, llReturn, lnError, loError

   llReturn = .T.

   TRY

      IF TYPE('m.goApp') = 'O'
         lcDataPath = ALLT(m.goapp.cdatafilepath)
         IF NOT ':' $ lcDataPath AND NOT '\\' $ lcDataPath AND LEFT(lcDataPath, 1) <> '\'
            lcSavePath = ALLT(CURDIR())
            lcDataPath = SYS(5) + CURDIR() + lcDataPath
         ENDIF
         lcBackupPath = lcDataPath
         lcFolderName = lcDataPath
         lcDataPath   = '"' + lcDataPath + '*.*' + '"'
      ENDIF

      IF NOT '\' $ lcDataPath
         lcDataPath = 'Data\*.*'
      ENDIF

      * Create the backup folders if needed
      IF NOT DIRECTORY(lcBackupPath + 'Backups')
         MD (lcBackupPath + 'Backups')
      ENDIF
      lcBackupPath = lcBackupPath + 'Backups\'

      lcFileName   = 'FileIntegrity' + '-' + STRTRAN(m.goapp.ccompanyname, ' ', '') + '-' + STRTRAN(STRTRAN(TTOC(DATETIME()),':',''),'/','-')
      lcFileName   = ALLTRIM(SUBSTR(lcFileName, RAT('\', lcFileName) + 1)) + '.zip'
      lcBackupPath = ADDBS(lcBackupPath)

      * Create the backup
      lnError = swbackup('B', lcFolderName, ALLTRIM(lcFileName), lcBackupPath)

      DO CASE
         CASE lnError = 0
            *            WAIT WIND NOWAIT 'Backup Completed'
            SET DATASESSION TO &lnSession
            llReturn = .T.
         CASE lnError = 4
            MESSAGEBOX('Backup Encountered Errors. Unable to create backup file.',64,'File Integrity Check')
            llReturn = .F.
         CASE lnError = 6
            MESSAGEBOX('Backup Encountered Errors. Unable to compress file.',64,'File Integrity Check')
            llReturn = .F.
      ENDCASE

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'Backup', loError.LINENO, 'Archive Data', loError.ERRORNO, loError.MESSAGE, '', loError
      MESSAGEBOX('Unable to process the archive at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY

   RETURN llReturn










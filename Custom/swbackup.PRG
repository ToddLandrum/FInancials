LPARAMETERS tcType, tcFolder, tcBackupName, tcBackupFolder, tlSend, tlArchive, tlChecks, tlReports, tlIgnoreError, tlProcessMsg
LOCAL lcLibrary, lnFiles1, lnFiles2, lcTable, laFiles_dbf, lFiles_fpt
LOCAL lcTempFolder, oProgress, oMessage, lnProgress, lnDataSession
PRIVATE llcancel 
*
* tlType         = (B)ackup or (R)estore
* tcFolder       = Folder to backup
* tcBackupName   = Name of Backup
* tcBackupFolder = Folder where backup is stored
* tlSend         = .t. - send the backup to SherWare
* tlArchive      = .t. - this is an archive backup so save it in the archive folder
* tlChecks       = .t. - include the checks folder
* tlReports      = .t. - include the reports folder
* tlIgnoreError  = .t. - don't complain if you can't backup something
* tlProcessMsg   = .t. - don't show progress messages about backup. Show process message about setting up process
*
lcLibrary = SET('library')
lcPath    = m.goApp.cCommonFolder + 'bin\'
SET LIBRARY TO (lcPath + 'vfpcompression.fll') ADDITIVE

* Set deleted off so that deleted records get sent when backing up to SherWare
IF tlSend
   SET DELETED OFF
ENDIF

tlSend = .F.  && Don't scrub the tax ids anymore since they are encrypted

oMessage = findglobalobject('cmmessage')

llCancel = .F.

ON KEY LABEL CTRL+C llCancel = .T.

* Save the current datasession
lnDataSession = SET('Datasession')

* Check tcFolder for a drive letter. If there's not one prepend one
IF LEFT(tcFolder, 2) # '\\'
   IF LEFT(tcFolder, 1) = '\'
      tcFolder = JUSTDRIVE(FULLPATH(tcFolder)) + tcFolder
   ENDIF
ENDIF

** Backup Files
IF tcType = 'B'
   oProgress = oMessage.ProgressBarEx('Backing up data in folder: ' + tcFolder)
* Set off so we're not asked if it's ok to delete the temp folder
   SET SAFETY OFF

   lnProgress = 0

* Open the database for the files we're backing up
   OPEN DATABASE (tcFolder + 'appdata')

* Get the list of tables in the database
   lnFiles1 = ADBOBJECTS(laFiles1, 'TABLE')
* Get the list of dat and txt files in the data folder
   lnFiles2 = ADIR(laFiles2, tcFolder + '*.dat')
   lnfiles3 = ADIR(laFiles3, tcFolder + '*.txt')

*  Include the transferlog file, if it exists
   IF FILE(tcFolder + 'transferlog.dbf') AND NOT llCancel 
      lnFiles1 = lnFiles1 + 1
      DIMENSION laFiles1(lnFiles1)
      laFiles1(lnFiles1) = ADDBS(tcFolder) + 'TRANSFERLOG'
      IF USED('transferlog')
         USE IN transferlog
      ENDIF
   ENDIF

*  Include the offsite backup file, if it exists
   IF FILE(tcFolder + 'offb1.dbf')
      lnFiles1 = lnFiles1 + 1
      DIMENSION laFiles1(lnFiles1)
      laFiles1(lnFiles1) = ADDBS(tcFolder) + 'OFFB1'
      IF USED('offb1')
         USE IN offb1
      ENDIF
   ENDIF
*  Include the online reporting file, if it exists
   IF FILE(tcFolder + 'offr1.dbf') AND NOT llCancel 
      lnFiles1 = lnFiles1 + 1
      DIMENSION laFiles1(lnFiles1)
      laFiles1(lnFiles1) = ADDBS(tcFolder) + 'OFFR1'
      IF USED('offr1')
         USE IN offr1
      ENDIF
   ENDIF

*  Include the errorlog file, if it exists
   IF FILE(m.goApp.cCommonFolder + 'errorlog.dbf') AND NOT llCancel
      lnFiles1 = lnFiles1 + 1
      DIMENSION laFiles1(lnFiles1)
      laFiles1(lnFiles1) = m.goApp.cCommonFolder + 'errorlog'
      IF USED('errorlog')
         USE IN errorlog
      ENDIF
   ENDIF
   
*  Include the version.dbf file, if it exists
   IF FILE(tcFolder + 'version.dbf') AND NOT llCancel
      lnFiles1 = lnFiles1 + 1
      DIMENSION laFiles1(lnFiles1)
      laFiles1(lnFiles1) = ADDBS(tcFolder) + 'VERSION'
      IF USED('version')
         USE IN VERSION
      ENDIF
   ENDIF

   IF tlArchive AND NOT llCancel 
      lnFiles4 = 0
      IF DIRECTORY(tcFolder + 'Archive')
         lnFiles4 = ADIR(laFiles4, tcFolder + 'Archive\*.*')
      ELSE
*  No point in pursuing any other archiving activities if the folder doesn't exist
         tlArchive = .F.
      ENDIF
   ENDIF

   oProgress.SetProgressRange(0, (lnFiles1 + lnFiles2 + lnfiles3) * 2)

* Create the temp backup folders if needed
   lcTempFolder = tcFolder + 'Temp\'
   IF NOT DIRECTORY(lcTempFolder)
      MD (lcTempFolder)
   ENDIF

* Erase any existing files in the temp folder
   ERASE (lcTempFolder + '*.*')
   
*  Include the records in the partnerpost   
   IF m.goapp.lPartnershipMod
      IF FILE(m.goapp.cCommonfolder+'partnerpost.dbf')
         lcidComp = m.goapp.cidcomp
         IF NOT USED('partnerpost')
            USE (m.goapp.cCommonFolder+'partnerpost') IN 0
         ENDIF 
         SELECT partnerpost
         lcTable = lcTempFolder+'partnerbkup.dbf'
         SELECT * FROM partnerpost INTO CURSOR tmpprtner ;
            WHERE cidcomp = m.goapp.cidcomp 
         COPY TO (lcTable)
         USE IN partnerpost
      ENDIF 
   ENDIF 

   llReturn = .T.
* Copy the files to the temp folder
   FOR lnx = 1 TO lnFiles1
      IF llCancel
         EXIT
      ENDIF
      TRY
         IF USED('tmpbkup')
            USE IN tmpbkup
         ENDIF
         IF 'cmdsave' $ LOWER(laFiles1[lnx])
* Don't backup this file
         ELSE
            USE (laFiles1[lnx]) IN 0 SHARED AGAIN ALIAS tmpbkup
            SELECT tmpbkup

            oProgress.SetProgressMessage('Creating temp files: ' + ALLTRIM(laFiles1[lnx]))
            oProgress.UpdateProgress(lnProgress)
            lnProgress = lnProgress + 1

            lcTable = lcTempFolder + JUSTFNAME(laFiles1[lnx])

            IF 'APPREG01' $ UPPER(laFiles1[lnx]) OR 'MENUPADS' $ UPPER(laFiles1[lnx])
               COPY TO (lcTable) WITH PRODUCTION
            ELSE
               COPY TO (lcTable)

* If sending to SherWare, mask out the tax ids
               IF tlSend
                  llScrubError = .F.
                  TRY
                     DO CASE
                        CASE 'INVESTOR' $ UPPER(laFiles1[lnx])
                           WAIT WINDOW NOWAIT 'Scrubbing federal tax ids and SSNs from the backup before sending...'
                           USE (lcTable) IN 0 ALIAS myowner
                           SELECT myowner
                           SCAN
                              REPLACE ctaxid WITH '***-**-****'
                           ENDSCAN
                           USE
                        CASE 'VENDOR' $ UPPER(laFiles1[lnx])
                           WAIT WINDOW NOWAIT 'Scrubbing federal tax ids and SSNs from the backup before sending...'
                           USE (lcTable) IN 0 ALIAS myvendor
                           SELECT myvendor
                           SCAN
                              REPLACE ctaxid WITH '**-*******'
                           ENDSCAN
                           USE
                        CASE 'EMPS' $ UPPER(laFiles1[lnx])
                           WAIT WINDOW NOWAIT 'Scrubbing federal tax ids and SSNs from the backup before sending...'
                           USE (lcTable) IN 0 ALIAS myemps
                           SELECT myemps
                           SCAN
                              REPLACE cssn WITH '***-**-****'
                           ENDSCAN
                           USE
                        CASE 'TAX1099' $ UPPER(laFiles1[lnx])
                           WAIT WINDOW NOWAIT 'Scrubbing federal tax ids and SSNs from the backup before sending...'
                           USE (lcTable) IN 0 ALIAS my1099
                           SELECT my1099
                           SCAN
                              REPLACE ctaxid WITH '***-**-****'
                           ENDSCAN
                           USE
                        CASE 'TAX1099DET' $ UPPER(laFiles1[lnx])
                           WAIT WINDOW NOWAIT 'Scrubbing federal tax ids and SSNs from the backup before sending...'
                           USE (lcTable) IN 0 ALIAS my1099det
                           SELECT my1099det
                           SCAN
                              REPLACE ctaxid WITH '***-**-****'
                           ENDSCAN
                           USE
                     ENDCASE
                  CATCH TO loError
                     llScrubError = .T.
                  ENDTRY
                  IF llScrubError
                     TRY
                        USE IN myowner
                     CATCH
                     ENDTRY
                     TRY
                        USE IN myvendor
                     CATCH
                     ENDTRY
                     TRY
                        USE IN myemps
                     CATCH
                     ENDTRY
                     TRY
                        USE IN my1099
                     CATCH
                     ENDTRY
                     TRY
                        USE IN my1099det
                     CATCH
                     ENDTRY
                  ENDIF
                  WAIT CLEAR
               ENDIF
            ENDIF
            USE IN tmpbkup
         ENDIF
      CATCH TO loError
         IF NOT INLIST(loError.ERRORNO, 3, 41, 1561, 1567, 1705, 1707, 1976, 1984, 2091)
* 3    - File in use
* 41   - Memo file missing or invalid
* 1561 - Database is invalid
* 1567 - Primary key property is invalid
* 1705 - File access is denied
* 1707 - Structural CDX not found
* 1976 - Cannot resolve backlink
* 1984 - Fields don't match
* 2091 - Table is corrupt
            IF NOT INLIST(UPPER(laFiles1[lnx]), 'NICKNAME', 'PRHIST') AND NOT RIGHT(ALLTRIM(laFiles1[lnx]), 1) = '1'
               MESSAGEBOX('Unable to backup file: ' + laFiles1[lnx] + CHR(10) + ;
                    'Error: ' + TRANSFORM(loError.ERRORNO) + CHR(10) + ;
                    'Msg: ' + ALLTRIM(loError.MESSAGE), 16, 'Backup Error')
               llReturn = .F.
* Set the counter variable so the loop exits
               lnx = lnFiles1 + 1
            ENDIF
         ELSE
            IF USED('tmpbkup')
               USE IN tmpbkup
            ENDIF
         ENDIF
      ENDTRY
   ENDFOR

   IF llReturn
      FOR lnx = 1 TO lnFiles2
         IF llCancel
            EXIT 
         ENDIF
         TRY
            lcTable = lcTempFolder + laFiles2[lnx, 1]
            oProgress.SetProgressMessage('Creating temp files: ' + ALLTRIM(laFiles2[lnx, 1]))
            oProgress.UpdateProgress(lnProgress)
            lnProgress = lnProgress + 1
            COPY FILE (tcFolder + laFiles2[lnx, 1]) TO (lcTable)
         CATCH TO loError
            MESSAGEBOX('Unable to backup file: ' + laFiles2[lnx, 1] + CHR(10) + ;
                 'Error: ' + TRANSFORM(loError.ERRORNO) + CHR(10) + ;
                 'Msg: ' + ALLTRIM(loError.MESSAGE), 16, 'Backup Error')
            llReturn = .F.
            lnx      = lnFiles2 + 1
         ENDTRY
      ENDFOR
   ENDIF

   IF llReturn
      FOR lnx = 1 TO lnfiles3
         IF llCancel
            EXIT
         ENDIF
         TRY
            lcTable = lcTempFolder + laFiles3[lnx, 1]
            oProgress.SetProgressMessage('Creating temp files: ' + ALLTRIM(laFiles3[lnx, 1]))
            oProgress.UpdateProgress(lnProgress)
            lnProgress = lnProgress + 1
            COPY FILE (tcFolder + laFiles3[lnx, 1]) TO (lcTable)
         CATCH TO loError
            MESSAGEBOX('Unable to backup file: ' + laFiles3[lnx, 1] + CHR(10) + ;
                 'Error: ' + TRANSFORM(loError.ERRORNO) + CHR(10) + ;
                 'Msg: ' + ALLTRIM(loError.MESSAGE), 16, 'Backup Error')
            llReturn = .F.
            lnx      = lnfiles3 + 1
         ENDTRY
      ENDFOR
   ENDIF

   IF tlArchive
      IF llReturn
         FOR lnx = 1 TO lnFiles4
            IF llCancel
               EXIT
            ENDIF
            TRY
               lcTable = lcTempFolder + laFiles4[lnx, 1]
               oProgress.SetProgressMessage('Creating temp files: ' + ALLTRIM(laFiles4[lnx, 1]))
               oProgress.UpdateProgress(lnProgress)
               lnProgress = lnProgress + 1
               COPY FILE (tcFolder + 'Archive\' + laFiles4[lnx, 1]) TO (lcTable)
            CATCH TO loError
               MESSAGEBOX('Unable to backup file: ' + laFiles4[lnx, 1] + CHR(10) + ;
                    'Error: ' + TRANSFORM(loError.ERRORNO) + CHR(10) + ;
                    'Msg: ' + ALLTRIM(loError.MESSAGE), 16, 'Backup Error')
               llReturn = .F.
               lnx      = lnFiles4 + 1
            ENDTRY
         ENDFOR
      ENDIF
   ENDIF

   IF NOT llReturn
      IF VARTYPE(oProgress) = 'O'
         oProgress.CloseProgress()
      ENDIF
      RETURN 4
   ENDIF

   TRY
      FLUSH FORCE
   CATCH
   ENDTRY

   IF llCancel
      MESSAGEBOX('The backup has been canceled by the user.', 16, 'Backup Canceled')
      RETURN 9
   ENDIF

* Set the folder to backup as the temp folder
   lcChkFolder = FULLPATH(ALLTRIM(m.goApp.cChecksFolder))
   lcRptFolder = FULLPATH(ALLTRIM(m.goApp.cRptsFolder))
   tcFolder    = lcTempFolder

   lnFiles1 = ADIR(laFiles1, tcFolder + '*.dbf')
   lnFiles2 = ADIR(laFiles2, tcFolder + '*.fpt')
   lnfiles3 = ADIR(laFiles3, tcFolder + '*.dat')
   lnFiles4 = ADIR(laFiles4, tcFolder + '*.txt')
   lnChecks = ADIR(laChecks, lcChkFolder + '*.*')
   lnRpts   = ADIR(laRpts, lcRptFolder + '*.*')
   lntotal  = lnFiles1 + lnFiles2 + lnfiles3 + lnFiles4

   IF tlChecks
      IF NOT DIRECTORY(lcTempFolder + 'Checks')
         MD (lcTempFolder + 'Checks')
      ENDIF
      FOR lnx = 1 TO lnChecks
         TRY
            lcTable = lcTempFolder + 'Checks\' + laChecks[lnx, 1]
            COPY FILE (lcChkFolder + laChecks[lnx, 1]) TO (lcTable)
         CATCH TO loError
*!*                 WAIT WINDOW 'Unable to backup file: ' + laChecks[lnx,1] + ;
*!*                      '  Error: ' + TRANSFORM(loError.ERRORNO) + ;
*!*                      '  Msg: ' + ALLTRIM(loError.MESSAGE)
         ENDTRY
      ENDFOR
   ENDIF

   IF tlReports
      SELECT 0
      IF NOT DIRECTORY(lcTempFolder + 'Rpts')
         MD (lcTempFolder + 'Rpts')
      ENDIF
      FOR lnx = 1 TO lnRpts
         TRY
            lcTable = lcTempFolder + 'Rpts\' + laRpts[lnx, 1]
            COPY FILE (lcRptFolder + laRpts[lnx, 1]) TO (lcTable)
         CATCH TO loError
*!*               WAIT WINDOW NOWAIT 'Unable to backup file: ' + laRpts[lnx,1] +   + ;
*!*                   '  Error: ' + TRANSFORM(loError.ERRORNO) + ;
*!*                   '  Msg: ' + ALLTRIM(loError.MESSAGE)
         ENDTRY
      ENDFOR
   ENDIF

   zipcallback("MyCallback('B')") && Start Event Handling - Any Function/Procedure/Method (in scope of course)
   llReturn = zipopen(tcBackupName, tcBackupFolder, .F.) && create zip file
   IF NOT llReturn
      IF VARTYPE(oProgress) = 'O'
         oProgress.CloseProgress()
         RELEASE oProgress
      ENDIF
      RETURN 4  && Unable to create zip file
   ENDIF

* DBF Files
   FOR lnx = 1 TO lnFiles1
      IF llCancel
         EXIT 
      ENDIF
      oProgress.SetProgressMessage('Compressing file: ' + ALLTRIM(laFiles1[lnx, 1]))
      oProgress.UpdateProgress(lnProgress)
      lnProgress = lnProgress + 1
      llReturn   = zipfile(tcFolder + laFiles1[lnx, 1], .T.) && compress file into zip
      IF NOT llReturn AND NOT tlIgnoreError
         IF MESSAGEBOX('Unable to compress ' + ALLTRIM(laFiles1[lnx, 1]) + ' Do you want to continue with the backup?', 36, 'Backup Problem') = 7
            IF VARTYPE(oProgress) = 'O'
               oProgress.CloseProgress()
               RELEASE oProgress
            ENDIF
            RETURN 6  && Unable to zip file
         ENDIF
      ENDIF
   ENDFOR
* FPT Files
   FOR lnx = 1 TO lnFiles2
      IF llCancel
         EXIT 
      ENDIF
      oProgress.SetProgressMessage('Compressing file: ' + ALLTRIM(laFiles2[lnx, 1]))
      oProgress.UpdateProgress(lnProgress)
      lnProgress = lnProgress + 1
      llReturn   = zipfile(tcFolder + laFiles2[lnx, 1], .T.) && compress file into zip
      IF NOT llReturn AND NOT tlIgnoreError
         IF MESSAGEBOX('Unable to compress ' + ALLTRIM(laFiles2[lnx, 1]) + ' Do you want to continue with the backup?', 36, 'Backup Problem') = 7
            IF VARTYPE(oProgress) = 'O'
               oProgress.CloseProgress()
               RELEASE oProgress
            ENDIF
            RETURN 6  && Unable to zip file
         ENDIF
      ENDIF
   ENDFOR
* Dat Files
   FOR lnx = 1 TO lnfiles3
      IF llCancel
         EXIT 
      ENDIF
      oProgress.SetProgressMessage('Compressing file: ' + ALLTRIM(laFiles3[lnx, 1]))
      oProgress.UpdateProgress(lnProgress)
      lnProgress = lnProgress + 1
      llReturn   = zipfile(tcFolder + laFiles3[lnx, 1], .T.) && compress file into zip
      IF NOT llReturn AND NOT tlIgnoreError
         IF MESSAGEBOX('Unable to compress ' + ALLTRIM(laFiles3[lnx, 1]) + ' Do you want to continue with the backup?', 36, 'Backup Problem') = 7
            IF VARTYPE(oProgress) = 'O'
               oProgress.CloseProgress()
               RELEASE oProgress
            ENDIF
            RETURN 6  && Unable to zip file
         ENDIF
      ENDIF
   ENDFOR
* TXT Files
   FOR lnx = 1 TO lnFiles4
      IF llCancel
         EXIT 
      ENDIF
      oProgress.SetProgressMessage('Compressing file: ' + ALLTRIM(laFiles4[lnx, 1]))
      oProgress.UpdateProgress(lnProgress)
      lnProgress = lnProgress + 1
      llReturn   = zipfile(tcFolder + laFiles4[lnx, 1], .T.) && compress file into zip
      IF NOT llReturn AND NOT tlIgnoreError
         IF MESSAGEBOX('Unable to compress ' + ALLTRIM(laFiles4[lnx, 1]) + ' Do you want to continue with the backup?', 36, 'Backup Problem') = 7
            IF VARTYPE(oProgress) = 'O'
               oProgress.CloseProgress()
               RELEASE oProgress
            ENDIF
            RETURN 6  && Unable to zip file
         ENDIF
      ENDIF
   ENDFOR

   llReturn = zipfile(tcFolder + 'appreg01.cdx', .T.)
   IF NOT llReturn AND NOT tlIgnoreError AND NOT llCancel
      IF MESSAGEBOX('Unable to compress appreg01.cdx. Do you want to continue with the backup?', 36, 'Backup Problem') = 7
         IF VARTYPE(oProgress) = 'O'
            oProgress.CloseProgress()
            RELEASE oProgress
         ENDIF
         RETURN 6  && Unable to zip file
      ENDIF
   ENDIF

   oProgress.CloseProgress()
   RELEASE oProgress

   IF llCancel
      MESSAGEBOX('The backup has been canceled by the user.', 16, 'Backup Canceled')
      zipclose()
      RETURN 9
   ENDIF

* Backup the check formats if requested   
   IF tlChecks
      WAIT WINDOW NOWAIT 'Backing up check formats...'
      TRY
         IF DIRECTORY(lcChkFolder)
            FOR lnx = 1 TO lnChecks
               llReturn = zipfilerelative(lcTempFolder + 'Checks\' + laChecks[lnx, 1], 'Checks\')
            ENDFOR
         ELSE
            MESSAGEBOX('Folder: ' + lcTempFolder + 'Checks\' + ' does not exist', 48, 'Missing Folder')
         ENDIF
      CATCH TO loError
      ENDTRY
      WAIT CLEAR
   ENDIF

* Backup the report formats if requested.   
   IF tlReports
      WAIT WINDOW NOWAIT 'Backing up report formats...'
      TRY
         IF DIRECTORY(lcRptFolder)
            FOR lnx = 1 TO lnRpts
               llReturn = zipfilerelative(lcTempFolder + 'Rpts\' + laRpts[lnx, 1], 'Rpts\')
            ENDFOR
         ELSE
            MESSAGEBOX('Folder: ' + lcTempFolder + 'Rpts\' + ' does not exist', 48, 'Missing Folder')
         ENDIF
      CATCH TO loError
      ENDTRY
      WAIT CLEAR
   ENDIF

   llReturn = zipclose() && done zipping
   IF NOT llReturn
      RETURN 8  && Unable to close zip file
   ENDIF

* Erase the temp files
   TRY
      ERASE (tcFolder + '*.*')
   CATCH
   ENDTRY

   SET SAFETY ON
   SET DELETED ON
   
   ON KEY LABEL ESC 

ELSE
* Close tables in all data sessions
   m.goApp.closealldata()

** Restore Files
   zipcallback("MyCallback('R')") && Start Event Handling - Any Function/Procedure/Method (in scope of course)
   llReturn = unzipopen(tcBackupName) && Open zip file
   IF NOT llReturn
      IF VARTYPE(oProgress) = 'O'
         oProgress.CloseProgress()
         RELEASE oProgress
      ENDIF
      RETURN 4  && Unable to open zip file
   ENDIF

   llReturn = unzipto(tcFolder) && extract files into folder

   IF NOT llReturn
      MESSAGEBOX('Unable to extract compressed files from ' + ALLTRIM(tcFolder), 16, 'Restore Problem')
      IF VARTYPE(oProgress) = 'O'
         oProgress.CloseProgress()
         RELEASE oProgress
      ENDIF
      RETURN 6  && Unable to zip file
   ENDIF
   llReturn = unzipclose() && done zipping
   IF NOT llReturn
      IF VARTYPE(oProgress) = 'O'
         oProgress.CloseProgress()
         RELEASE oProgress
      ENDIF
      RETURN 8  && Unable to close zip file
   ENDIF
ENDIF

llReturn = zipclose() && done zipping
IF NOT llReturn
   IF VARTYPE(oProgress) = 'O'
      oProgress.CloseProgress()
      RELEASE oProgress
   ENDIF
   RETURN 8  && Unable to close zip file
ENDIF
zipcallback("") && Stop Event Handling
SET LIBRARY TO &lcLibrary

IF VARTYPE(oProgress) = 'O'
   oProgress.CloseProgress()
   RELEASE oProgress
   oProgress = .NULL.
ENDIF

* Reset the datasession to what it was when this proc was called
SET DATASESSION TO (lnDataSession)

* Restore records in partnerpost
IF m.goapp.lPartnershipMod
   IF FILE(tcFolder+'partnerbkup.dbf')
      IF NOT USED('partnerbkup')
         USE (tcFolder+'partnerbkup')
      ENDIF 
      IF NOT USED(m.goApp.cCommonFolder+'partnerpost')
         USE (m.goapp.cCommonFolder+'partnerpost') IN 0
      ENDIF 
      SELECT partnerbkup
      SCAN 
         SCATTER MEMVAR 
         SELECT partnerpost
         LOCATE FOR cidcomp = m.cidcomp ;
                AND nrunno  = m.nrunno ;
                AND crunyear = m.crunyear ;
                AND cdmbatch = m.cdmbatch ;
                AND cownerid = m.cownerid ;
                AND dacctdate = m.dacctdate ;
                AND cprodyear = m.cprodyear ;
                AND cprodprd  = m.cprodprd ;
                AND cwellid = m.cwellid ;
                AND ctype = m.ctype ;
                AND nownunits = m.nownunits ;
                AND nownerval = m.nownerval ;
                AND ctaxcode = m.ctaxcode ;
                AND ccatcode = m.ccatcode ;
                AND cint_type = m.cint_type ;
                AND nnetamount = m.nnetamount
        IF FOUND()
           REPLACE lposted WITH m.lposted ;
                   tposted WITH m.tposted
        ELSE
           INSERT INTO partnerpost FROM MEMVAR 
        ENDIF 
      ENDSCAN 
   ENDIF 
ENDIF 

RETURN 0  && Success

*****************************
FUNCTION MyCallback()
*****************************
LPARAMETERS tcType
*!* Variables below are created on the fly
*!* by the FLL when the ZipCallback feature is used

*!* Depends on the value of nZipEvent
DO CASE
   CASE nzipevent = 1
      IF tcType = 'B'
*         WAIT WINDOW NOWAIT 'Backing Up File: ' + cZipObjectName && Name of Zip, File, or Folder being processed
      ELSE
         WAIT WINDOW NOWAIT 'Restoring File: ' + cZipObjectName && Name of Zip, File, or Folder being processed
      ENDIF
   CASE nzipevent = 5
*      WAIT CLEAR
ENDCASE

*!* Events that fire MyCallback
*!* 0 = Open Zip
*!* 1 = Start Zip/Unzip of File
*!* 2 = Read/Write File (nZipBytes will contain value of bytes read for event)
*!* 3 - End Zip/Unzip of File
*!* 4 - Folder Opened
*!* 5 - Close Zip
*    ?nZipEvent

*!* Number of Bytes read (Event 3)
*    ?nZipBytes

ENDFUNC

PROCEDURE zipcallback
ENDPROC

PROCEDURE zipopen
ENDPROC

PROCEDURE zipfile
ENDPROC

PROCEDURE unzipopen
ENDPROC

PROCEDURE unzipto
ENDPROC

PROCEDURE zipclose
ENDPROC

PROCEDURE zipfolder
ENDPROC

PROCEDURE unzipclose
ENDPROC

PROCEDURE zipfilerelative
ENDPROC


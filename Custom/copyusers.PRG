IF MESSAGEBOX('Are you sure you want to copy the users set up in 00GCW to the JV companies?',36,'Copy Users') = 7
   RETURN
ENDIF 

TRY
   lnFolders = ADIR(lafolders,'datafiles\*','D')

   USE datafiles\00gcw\appreg01 AGAIN IN 0 ALIAS gcwusers
   SELECT * FROM gcwusers WHERE LOWER(LEFT(keyname,9)) = 'security.' ;
      INTO CURSOR tempusers
      
   USE IN gcwusers

   IF lnFolders > 0
      IF NOT USED('compmast')
         USE ('datafiles\compmast') IN 0
      ENDIF

      FOR x = 1 TO lnFolders

         lcDir = lafolders[x,1]
         
         IF NOT EMPTY(JUSTEXT(lcDir))
            LOOP
         ENDIF

         IF 'empty' $ LOWER(lcDir) OR ;
               '00gcw' $ LOWER(lcDir) OR ;
               'zip'   $ LOWER(lcDir) OR ;
               'dbf'   $ LOWER(lcDir) OR ;
               'cdx'   $ LOWER(lcDir) OR ;
               'fpt'   $ LOWER(lcDir)
            LOOP
         ENDIF

         WAIT WINDOW NOWAIT 'Copying users to ' + lcDir

         llError = .F.

         TRY
            USE ('datafiles\'+lcDir+'\appreg01') AGAIN  IN 0 ALIAS xuser
            SELECT xuser
            DELETE FOR LOWER(LEFT(keyname,9)) = 'security.'
            APPEND FROM DBF('tempusers')
            USE IN xuser

         CATCH
            llError = .T.
         ENDTRY


      ENDFOR
      WAIT CLEAR 
   ENDIF

CATCH TO loErr
   MESSAGEBOX('Error: ' + loErr.MESSAGE + CHR(13) + ;
      'Line:  ' + TRANSFORM(loErr.LINENO),0,'CopyUsers')
ENDTRY

MESSAGEBOX('Finished copying users from 00GCW to the JV companies.',64,'Copy Users')



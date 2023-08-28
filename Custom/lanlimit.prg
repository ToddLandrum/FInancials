*++
* SherWare class for limiting the number of concurrent users on a LAN application.
*
* Uses text files to count users, so it will never get out of sync as the result
* of improper application shutdown or system crashes.
*
* This will work well for limits up to about 20 or so.
* For limits set much over 20, it can become slow on startup.
*
* Usage: Add code like the following to the application object BeforeMenu() event.
*
*   LOCAL oLimit
*   m.oLimit = CREATE('cmNetworkUserLimit')
*   m.oLimit.nMaxUsers = 5   && The maximum # of users allowed to run at the same time.
*   IF NOT m.oLimit.IsLicensed()
*     THIS.oMessage.Warning('User limit exceeded!')
*     RETURN .F.
*   ENDIF
*   RETURN .T.
*--
DEFINE CLASS cmNetworkUserLimit AS CUSTOM
   cLockFileName = 'UserMgr.dbf'
   oApp = .NULL.
   nMaxUsers = 0

   FUNCTION INIT()
   IF SET('DataSession') != 1
      ERROR THIS.NAME + ' must be created in default datasession'
      RETURN .F.
   ENDIF
   THIS.oApp = FindGlobalObject('appApplication')
   ENDFUNC

   FUNCTION DESTROY()
   LOCAL llError
   * Close the user lock table if open, releasing any locks.
   
   m.cFile = FULLPATH(THIS.cLockFileName, THIS.oApp.appdata_folder)
   IF NOT USED('swUserLockManager')
      USE (m.cFile) SHARED ALIAS swuserlockmanager IN 0
   ENDIF
   
   llError = .F.
   TRY 
   SELECT swuserlockmanager
   SCAN FOR !EMPTY(cTextFile)
      lcFileName = THIS.oApp.appdata_folder + cTextFile
      lnHandle = FOPEN(lcFileName)
      m.fh = fh
      IF lnHandle > 0
         FCLOSE(lnHandle)
         * Person is no longer using the application and did not log out properly
         ERASE (lcFileName)
         REPLACE cTextFile WITH ""
      ELSE
         FCLOSE(m.fh)
         ERASE (lcFileName)
         REPLACE cTextFile WITH ""
      ENDIF
   ENDSCAN    
   USE IN swUserLockManager
   CATCH
      llError = .t.
   ENDTRY 
   
   
   ENDFUNC

   FUNCTION IsLicensed()
   *++
   *>>Don't allow the number of network users to exceed licenced maximum specified in nMaxUsers property.
   *--
   LOCAL lcTextFile, lnUserCount, m.cFile, llError
   lnusercount = 0
   llError = .f.
   
   m.cFile = FULLPATH(THIS.cLockFileName, THIS.oApp.appdata_folder)

   IF THIS.nMaxUsers > 0
      TRY
      IF USED('swUserLockManager')
         SELECT swUserLockManager
      ELSE
         IF NOT FILE(m.cFile)
            CREATE TABLE (m.cFile) FREE (cTextFile c(30), fh I)
            USE
         ENDIF
         SELECT 0
         USE (m.cFile) SHARED ALIAS swUserLockManager
      ENDIF
      CATCH 
         llError = .T.
      ENDTRY 
      
      IF NOT llError 
      SCAN FOR !EMPTY(cTextFile)
         lcFileName = THIS.oApp.appdata_folder + cTextFile
         lnHandle = FOPEN(lcFileName)
         IF lnHandle > 0
            FCLOSE(lnHandle)
            * Person is no longer using the application and did not log out properly
            ERASE (lcFileName)
            REPLACE cTextFile WITH ""
         ELSE
            * Can't open the text file, so the user is still logged in
            lnUserCount = lnUserCount + 1
         ENDIF
      ENDSCAN

      IF lnUserCount <= THIS.nMaxUsers
         * Create a name for the text file
         lcTextFile = LEFT(SYS(2015), 8) + ".TXT"
         * Create the text file where everyone can access it on the network
         fh = FCREATE(THIS.oApp.appdata_folder + lcTextFile)
         m.cTextFile = lcTextFile
         INSERT INTO swUserLockManager FROM MEMVAR
      ELSE
         RETURN .f.
      ENDIF
      ELSE
         MESSAGEBOX("There's a problem with the user lock table. Try deleting datafiles\usermgr.dbf and logging in again.",16,'User Lock Table Problem')
         RETURN .f.
      ENDIF 

   ENDIF
   RETURN .T.
ENDDEFINE

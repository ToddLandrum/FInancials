LPARAMETERS tcType
LOCAL lcLibrary
LOCAL loIP AS 'wwftp'
LOCAL lcSourceFile, lcTargetFile, llReturn, llSupport, lnResult, loerror
LOCAL lcType, lnCount, lnMax

STORE .T. TO llReturn
STORE .F. TO llUpdate

IF VARTYPE(tcType) # 'C'
    tcType = '*'
ENDIF

TRY

    DO CASE
        CASE tcType = 'REV'
            lnMax  = 40
            swselect('importdefs')
            COUNT FOR NOT DELETED() AND cType = tcType TO lnCount
            IF lnCount # lnMax
                llUpdate = .T.
            ENDIF
        CASE tcType = 'EXP'
            lnMax  = 34
            swselect('importdefs')
            COUNT FOR NOT DELETED() AND cType = tcType TO lnCount
            IF lnCount # lnMax
                llUpdate = .T.
            ENDIF
        CASE tcType = '*'
            swselect('importdefs')
            COUNT FOR NOT DELETED() TO lnCount
            IF lnCount # 74
                llUpdate = .T.
            ENDIF
    ENDCASE

    IF llUpdate
        lcLibrary = SET('library')

        llSupport = checksupportexp()

        IF NOT llSupport
            llReturn = .F.
            EXIT
        ENDIF


        loIP             = CREATEOBJECT('wwftp')
        loIP.lPassiveFTP = .T.
        loIP.FTPConnect(TRIM('support.sherware.com'), ;
              TRIM('updates'), ;
              TRIM('45ts2310') )

        lcSourceFile = 'impdefs.dbf'

        lcTargetFile = 'datafiles\newdefs.dbf'

        lnResult = loIP.FTPGetFileEx(lcSourceFile, lcTargetFile)

        llReturn = lnResult = 0

        IF NOT llReturn
*                MESSAGEBOX(loIP.cerrormsg, 16, 'Update Download Problem')
        ENDIF

        WAIT CLEAR

        IF m.llReturn AND FILE(lcTargetFile)
            IF NOT USED('newdefs')
                USE datafiles\newdefs IN 0
            ENDIF
            swselect('importdefs')
            DELETE ALL
            APPEND FROM DBF('newdefs')
            USE IN newdefs
            TRY 
            ERASE (lcTargetFile)
            CATCH
            ENDTRY 
        ENDIF

        SET LIBRARY TO &lcLibrary
    ENDIF
CATCH TO loerror
    llReturn = .F.
    DO errorlog WITH 'GetUpdatedTable', loerror.LINENO, 'Revenue Import Map', loerror.ERRORNO, loerror.MESSAGE
ENDTRY

RETURN llReturn



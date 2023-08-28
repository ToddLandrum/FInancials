LPARAMETERS tcType
LOCAL lcLibrary
LOCAL loIP AS 'wwftp'
LOCAL lcSourceFile, lcTargetFile, llReturn, llSupport, lnResult, loerror
LOCAL lcType, lnCount, lnMax, llNoExtract

STORE .T. TO llReturn
STORE .F. TO llUpdate
STORE .T. TO llNoExtract

IF VARTYPE(tcType) # 'C'
    tcType = '*'
ENDIF
TRY

    llSupport = checksupportexp()

    IF NOT llSupport
        llReturn = .F.
        EXIT
    ENDIF

    swclose('newdefs')

    DO CASE
        CASE tcType == 'AM'
            lcSourceFile = 'amimpdefs.dbf'
        CASE tcType == 'DM'
            lcSourceFile = 'dmimpdefs.dbf'
        CASE tcType == 'DMIE'
            lcSourceFile = 'dmieimpdefs.dbf'
        OTHERWISE
            llReturn = .F.
            EXIT
    ENDCASE

    lcTargetFile = 'datafiles\newdefs.dbf'

    loUpdate             = m.goApp.oUpdate
    loUpdate.cSourceFile = lcSourceFile
    loUpdate.cTargetFile = lcTargetFile
    llReturn             = loUpdate.GetUpdate(llNoExtract)

    IF NOT llReturn
        EXIT
    ENDIF

    WAIT CLEAR

    IF m.llReturn AND FILE(lcTargetFile)
        USE datafiles\newdefs IN 0
        SELECT newdefs
        SCAN
            SCATTER MEMVAR
            swselect('importdefs')
            LOCATE FOR ctype == m.ctype AND cname == m.cname
            IF NOT FOUND()
                RELEASE iimportdefs
                INSERT INTO importdefs FROM MEMVAR
            ENDIF
        ENDSCAN
        swclose('newdefs')
        ERASE (lcTargetFile)
    ENDIF

CATCH TO loerror
    llReturn = .F.
    DO errorlog WITH 'GetImportDefs', loerror.LINENO, 'Revenue Import Map', loerror.ERRORNO, loerror.MESSAGE
ENDTRY

RETURN llReturn





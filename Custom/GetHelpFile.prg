LPARAMETERS tcHelpFile

LOCAL lcLibrary, lcSourceFile, lcTargetFile, llReturn, lnResult, loUpdate, loerror
#DEFINE CRLF CHR(13) + CHR(10)

TRY
    lcLibrary = SET('library')

    WAIT WINDOW NOWAIT 'Installing the most current help file into ' + ALLTRIM(m.goApp.cCommonDocuments)

    DO CASE
        CASE 'AM' $ tcHelpFile
            lcSourceFile = 'amhelp.zip'
        CASE 'DMIE' $ tcHelpFile
            lcSourceFile = 'dmiehelp.zip'
        CASE 'DM' $ tcHelpFile
            lcSourceFile = 'dmhelp.zip'
        OTHERWISE
            llReturn = .F.
            EXIT
    ENDCASE

    lcTargetFile = 'datafiles\helpfile.zip'

    loUpdate              = m.goApp.oUpdate
    loUpdate.cSourceFile  = lcSourceFile
    loUpdate.cTargetFile  = lcTargetFile
    loUpdate.cDescription = 'Help File'
    loUpdate.cUnzipTo     = m.goApp.cCommonDocuments
    llReturn              = loUpdate.GetUpdate()

    IF NOT EMPTY(loUpdate.cErrorMessage)
        MESSAGEBOX(loUpdate.cErrorMessage, 0, 'Update Files')
    ENDIF

CATCH TO loerror
    DO errorlog WITH 'GetHelpFile', loerror.LINENO, 'CheckHelpFile', loerror.ERRORNO, loerror.MESSAGE
    llReturn = .F.
ENDTRY

WAIT CLEAR
RETURN llReturn




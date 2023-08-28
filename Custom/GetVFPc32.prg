LOCAL loIP AS 'wwftp'
LOCAL lcLibrary, lcSourceFile, lcTargetFile, llReturn, lnResult, loUpdate, loerror
#DEFINE CRLF CHR(13) + CHR(10)

TRY
    lcLibrary = SET('library')

    WAIT WINDOW NOWAIT 'Installing the updated file browser module...'

    lcSourceFile = 'vfpc32.zip'
    lcTargetFile = 'datafiles\vfpc32.zip'

    loUpdate              = m.goapp.oUpdate
    loUpdate.cSourceFile  = lcSourceFile
    loUpdate.cTargetFile  = lcTargetFile
    loUpdate.cDescription = 'File Explorer Dialog'
    loUpdate.cUnzipTo     = m.goapp.cCommonFolder+'bin'
    llReturn              = loUpdate.GetUpdate()

CATCH TO loerror
    DO errorlog WITH 'GetVFPC32', loerror.LINENO, 'Connect Company', loerror.ERRORNO, loerror.MESSAGE
    llReturn = .F.
ENDTRY

WAIT CLEAR

RETURN llReturn




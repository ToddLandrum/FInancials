LOCAL loIP AS 'wwftp'
LOCAL lcLibrary, lcSourceFile, lcTargetFile, llReturn, lnResult, loUpdate, loerror
#DEFINE CRLF CHR(13) + CHR(10)

TRY
    lcLibrary = SET('library')

    WAIT WINDOW NOWAIT 'Installing the file export module...'

    lcSourceFile = 'xfrx_'+m.goApp.XFRXVersion + '.zip'
    lcTargetFile = m.goApp.cCommonFolder+'xfrx_' + m.goApp.XFRXVersion + '.zip'

    loUpdate              = m.goapp.oUpdate
    loUpdate.cSourceFile  = lcSourceFile
    loUpdate.cTargetFile  = lcTargetFile
    loUpdate.cDescription = 'XFRX Files'
    loUpdate.cUnzipTo     = m.goapp.cCommonFolder+'\bin\'
    llReturn              = loUpdate.GetUpdate()

CATCH TO loerror
    DO errorlog WITH 'GetXFRX', loerror.LINENO, 'XFRX', loerror.ERRORNO, loerror.MESSAGE
    llReturn = .F.
ENDTRY

WAIT CLEAR

RETURN llReturn




LOCAL loIP AS 'wwftp'
LOCAL lcLibrary, lcSourceFile, lcTargetFile, llReturn, lnResult, loUpdate, loerror
#DEFINE CRLF CHR(13) + CHR(10)

TRY
    lcLibrary = SET('library')


    WAIT WINDOW NOWAIT 'Installing the report preview modules...'

    lcSourceFile = 'reportapps.zip'
    lcTargetFile = m.goapp.cCommonFolder+'reportapps.zip'
    lcDescription = 'Reporting helper apps'

    loUpdate              = m.goapp.oUpdate
    loUpdate.cSourceFile  = lcSourceFile
    loUpdate.cTargetFile  = lcTargetFile
    loUpdate.cDescription = lcDescription
    loUpdate.cUnzipTo     = m.goapp.cCommonFolder
    llReturn              = loUpdate.GetUpdate()
    
    IF NOT EMPTY(loUpdate.cErrorMessage)
       MESSAGEBOX(loUpdate.cErrorMessage,0,'Update Files')
    ENDIF 

CATCH TO loerror
    DO errorlog WITH 'GetRptApps', loerror.LINENO, 'Get Report Apps', loerror.ERRORNO, loerror.MESSAGE
    llReturn = .F.
ENDTRY

WAIT CLEAR
RETURN llReturn




LOCAL loIP AS 'wwftp'
LOCAL lcLibrary, lcSourceFile, lcTargetFile, llReturn, lnResult, loUpdate, loerror
#DEFINE CRLF CHR(13) + CHR(10)

TRY
    lcLibrary = SET('library')


    WAIT WINDOW NOWAIT 'Installing the report preview modules...'

    lcSourceFile = 'envelope.zip'
    lcTargetFile = m.goapp.cRptsFolder+'envelope.zip'
    lcDescription = 'Envelope Format'

    loUpdate              = m.goapp.oUpdate
    loUpdate.cSourceFile  = lcSourceFile
    loUpdate.cTargetFile  = lcTargetFile
    loUpdate.cDescription = lcDescription
    loUpdate.cUnzipTo     = m.goapp.cRptsFolder
    llReturn              = loUpdate.GetUpdate()
    
    IF NOT EMPTY(loUpdate.cErrorMessage)
       MESSAGEBOX(loUpdate.cErrorMessage,0,'Update Files')
    ENDIF 

CATCH TO loerror
    DO errorlog WITH 'GetEnvelope', loerror.LINENO, 'Get Envelope Format', loerror.ERRORNO, loerror.MESSAGE
    llReturn = .F.
ENDTRY

WAIT CLEAR
RETURN llReturn




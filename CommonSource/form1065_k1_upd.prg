LPARAMETERS tcYear
LOCAL lcDescription, lcLibrary, lcSourceFile, lcTargetFile, lcYear, llReturn, llSupport, loUpdate
#DEFINE CRLF CHR(13) + CHR(10)

llSupport = checksupportexp(.T.)

IF NOT llSupport
    RETURN .f. 
ENDIF

lcYear = tcYear

IF MESSAGEBOX('This utility will download new report formats for Form 1065 and K1 for year: ' + lcYear + CRLF + CRLF + ;
          'Do you want to continue?', 36, 'Download Form 1065/K1') = 7
    RETURN
ENDIF

lcSourceFile  = 'form1065_' + tcYear + '.zip'
lcTargetFile  = m.goapp.cCommonFolder + 'form1065_' + tcYear + '.zip'
lcDescription = "Form 1065 and K1 report formats"

loUpdate              = m.goapp.oUpdate
loUpdate.cSourceFile  = lcSourceFile
loUpdate.cTargetFile  = lcTargetFile
loUpdate.cDescription = lcDescription
loUpdate.cUnzipTo     = m.goapp.cRptsFolder+'1065-k1\'+tcYear+'\'
llReturn              = loUpdate.GetUpdate()

IF NOT EMPTY(loUpdate.cErrorMessage)
    MESSAGEBOX(loUpdate.cErrorMessage, 0, 'Update Files')
    llReturn = .f.
ENDIF

RETURN llReturn
 
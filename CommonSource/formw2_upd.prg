LPARAMETERS tcYear

LOCAL lcDescription, lcLibrary, lcSourceFile, lcTargetFile, lcYear, llReturn, llSupport, loUpdate
#DEFINE CRLF CHR(13) + CHR(10)

llSupport = checksupportexp(.T.)

IF NOT llSupport
    RETURN .F.
ENDIF

llReturn = .T.

lcYear = tcYear

IF MESSAGEBOX('This utility will download new report formats for W2 for year: ' + lcYear + CRLF + CRLF + ;
          'Do you want to continue?', 36, 'Download Form W2') = 7
    RETURN
ENDIF

lcSourceFile  = 'formw2_' + lcYear + '.zip'
lcTargetFile  = m.goapp.cCommonFolder + 'formw2.zip'
lcDescription = "W2 report formats"

loUpdate              = m.goapp.oUpdate
loUpdate.cSourceFile  = lcSourceFile
loUpdate.cTargetFile  = lcTargetFile
loUpdate.cDescription = lcDescription
loUpdate.cUnzipTo     = m.goapp.cRptsFolder
llReturn              = loUpdate.GetUpdate()

IF NOT EMPTY(loUpdate.cErrorMessage) AND NOT llReturn
   IF 'not found' $ LOWER(loUPdate.cErrorMessage)
       MESSAGEBOX('The W2 formats for ' + lcYear + ' have not been released yet. Check with Support to find out when they will be available', 0, 'Update Files')
   ELSE
      MESSAGEBOX(loUpdate.cErrorMessage, 0, 'Update Files')
   ENDIF        
    llReturn = .F.
ENDIF

RETURN llReturn


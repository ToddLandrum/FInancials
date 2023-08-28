LPARAMETERS tcYear, tlIgnoreSupport
LOCAL lcDescription, lcLibrary, lcSourceFile, lcTargetFile, lcYear, llReturn, llSupport, loUpdate

#DEFINE CRLF CHR(13) + CHR(10)

lcLibrary = SET('library')

IF NOT tlIgnoreSupport
   llSupport = checksupportexp(.T.)
ELSE
   llSupport = .T.
ENDIF    

IF NOT llSupport
    RETURN .F.
ENDIF

lcYear = tcYear

IF MESSAGEBOX('This utility will download new report formats for 1099 Misc for year: ' + lcYear + CRLF + CRLF + ;
          'Do you want to continue?', 36, 'Download Form 1099') = 7
    RETURN
ENDIF

lcSourceFile  = 'form1099_' + lcYear + '.zip'
lcTargetFile  = m.goapp.cCommonFolder + 'form1099.zip'
lcDescription = "1099 report formats"

loUpdate              = m.goapp.oUpdate
loUpdate.cSourceFile  = lcSourceFile
loUpdate.cTargetFile  = lcTargetFile
loUpdate.cDescription = lcDescription
loUpdate.cUnzipTo     = m.goapp.cRptsFolder
llReturn              = loUpdate.GetUpdate()

IF NOT EMPTY(loUpdate.cErrorMessage)
   IF 'not found' $ LOWER(loUPdate.cErrorMessage)
      MESSAGEBOX('The 1099 formats for year ' + lcYear + ' are not available yet. The 1099s for ' + lcYear + ' cannot be printed.',16,'1099 Formats Not Available')
   ELSE
      MESSAGEBOX(loUpdate.cErrorMessage, 0, 'Update Files')
   ENDIF 
ENDIF

RETURN llReturn

 
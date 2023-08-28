LOCAL loIP AS 'wwftp'
LOCAL lcLibrary, lcSourceFile, lcTargetFile, llReturn, llSupport, lnResult, loUpdate, loerror

llReturn = .T.

IF FILE(m.goapp.ccommonfolder + "bin\newtonsoft.json.dll")
    IF NOT FILE('newtonsoft.json.dll')
        MESSAGEBOX("Copy the " + m.goapp.ccommonfolder + "bin\newtonsoft.json.dll file to the folder containing " + ;
              m.goapp.cproductname + ' and try again.', 16, 'Missing DLL')
        RETURN .F.
    ENDIF
    RETURN .T.
ENDIF

TRY

    lcLibrary = SET('library')

    IF NOT DIRECTORY(m.goapp.ccommonfolder + 'Bin')
        MD (m.goapp.ccommonfolder + 'Bin')
    ENDIF

    lcSourceFile = 'newtonsoft.json.dll'
    lcTargetFile = (m.goapp.ccommonfolder + "bin\newtonsoft.json.dll")

    loUpdate              = m.goapp.oUpdate
    loUpdate.cSourceFile  = lcSourceFile
    loUpdate.cTargetFile  = lcTargetFile
    loUpdate.cDescription = 'newtonsoft.json.dll'
    loUpdate.cUnzipTo     = m.goapp.cRptsFolder
    llReturn              = loUpdate.GetUpdate(.T.)

    IF FILE(m.goapp.ccommonfolder + "bin\newtonsoft.json.dll")
        IF NOT FILE('newtonsoft.json.dll')
            MESSAGEBOX("Copy the " + m.goapp.ccommonfolder + "bin\newtonsoft.json.dll file to the folder containing " + ;
                  m.goapp.cproductname + ' and try again.', 16, 'Missing DLL')
            llReturn = .F.
            EXIT
        ENDIF
    ENDIF
CATCH TO loerror
    llReturn = .F.
    DO errorlog WITH 'GetJson', loerror.LINENO, 'Submit 1099s', loerror.ERRORNO, loerror.MESSAGE
    MESSAGEBOX('Unable to get the required offsite backup dll at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
          'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn






LPARAMETERS tlMessage
LOCAL loIP AS 'wwftp'
LOCAL laRpts[1], lcLibrary, lcSourceFile, lcTargetFile, llGetFormats, llReturn, llSupport, lnFiles
LOCAL lnResult, loUpdate, loerror

llReturn = .T.

TRY
    lcLibrary = SET('library')

    * Check to see if we need new report formats
    lnFiles = ADIR(laRpts, m.goapp.crptsfolder + 'wvannret.frx')

    llGetFormats = .F.

    IF lnFiles > 0
        IF laRpts[1, 3] < {10/24/2019}
            llGetFormats = .T.
        ENDIF
    ENDIF

    IF NOT llGetFormats
        llReturn = .T.
        EXIT
    ENDIF

    llSupport = checksupportexp()

    IF NOT llSupport
        llReturn = .F.
        EXIT
    ENDIF

IF tlMessage
    IF MESSAGEBOX('This utility will download new WV Producer/Operator Return formats.' + ;
              'The new formats will need to be installed before viewing the return.' + CHR(10) + CHR(10) + ;
              'Do you want to continue?', 36, 'Download WV Return Formats') = 7
        llReturn = .F.
        EXIT
    ENDIF
ENDIF 

    lcSourceFile          = 'wvrpts.zip'
    lcTargetFile          = m.goapp.cCommonFolder+'wvrpts.zip'
    lcDescription         = 'WV Producer/Operator return formats'
    loUpdate              = m.goapp.oUpdate
    loUpdate.cSourceFile  = lcSourceFile
    loUpdate.cTargetFile  = lcTargetFile
    loUpdate.cDescription = lcDescription
    loUpdate.cUnzipTo     = m.goapp.crptsfolder
    llReturn              = loUpdate.GetUpdate()

CATCH TO loerror
    llReturn = .F.
    DO errorlog WITH 'GetWVFormats', loerror.LINENO, 'WV Producer/Operator Return', loerror.ERRORNO, loerror.MESSAGE
    MESSAGEBOX('Unable to get the new WV return formats at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
          'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn

 
*** Custom class to override the OnFtpBufferUpdate method
DEFINE CLASS swFTP AS wwFTP

    lConnected    = .F.
    nFTPPort      = 21
    cSourceFile   = ' '
    cTargetFile   = ' '
    cFTPServer    = ' '
    cUser         = ' '
    cPwd          = ' '
    oFTP          = ' '
    cErrorMessage = ' '
    lPassiveFTP   = .T.
    oProgress     = .NULL.
    oMessage      = .NULL.
    nProgress     = 0
    lDownload     = .F.
    #include custom\wconnect.h 
    ************************
    FUNCTION INIT
    ************************

    THIS.oMessage = findglobalobject('cmmessage')

    ************************   
    FUNCTION OnFTPBufferUpdate
    ************************
    LPARAMETER lnBytesDownloaded, lnBufferReads, lcCurrentChunk, lnTotalBytes
    LOCAL oProgress, lcType

    IF THIS.lDownload
        lcType1 = 'Downloading '
        lcType2 = 'Downloaded: '
    ELSE
        lcType1 = 'Sending '
        lcType2 = 'Sent: '
    ENDIF

    IF VARTYPE(THIS.oProgress) = 'O'
        THIS.oProgress.setprogressmessage(lcType2 + TRANSFORM(lnBytesDownloaded, '999,999,999') + ' of ' + TRANSFORM(lnTotalBytes, '999,999,999') + ' Total Bytes')
        THIS.oProgress.UpdateProgress(lnBytesDownloaded)
        THIS.nProgress = THIS.nProgress + 1
    ELSE
        IF VARTYPE(m.goapp.oMessage) = 'O'
           THIS.oProgress = m.goapp.oMessage.Progressbarex(lcType1 + 'File....', ' ')
           THIS.oProgress.setProgressRange(0, lnTotalBytes)
        ELSE
           this.oProgress = .NULL.
        ENDIF    
    ENDIF

    RETURN

    ************************
    PROCEDURE CONNECT
    ************************
    LOCAL lnError, lcError
    LOCAL lcReturn

    lcReturn = '0'

    TRY
        lnError = THIS.FTPConnect(THIS.cserver, ;
              TRIM(THIS.cUser), ;
              TRIM(THIS.cPwd) )

        IF lnError = 0
            THIS.lConnected = .T.
            lcReturn        = '0'
        ELSE
            THIS.lConnected = .F.
            lcError         = 'Error: ' + TRANSFORM(lnError) + ' - ' + THIS.cErrorMsg
            lcReturn        = lcError
        ENDIF
    CATCH TO loError
        lcReturn = loError.MESSAGE
        DO errorlog WITH 'FTPConnect', loError.LINENO, 'swFTP', loError.ERRORNO, loError.MESSAGE, '', loError
    ENDTRY

    RETURN lcReturn


    ************************
    PROCEDURE CLOSE
    ************************

    THIS.FTPClose()
    THIS.lConnected = .F.

    ***********************
    PROCEDURE SendFile
    ***********************
    LOCAL llReturn, loError

    llReturn = .T.

    TRY

        IF NOT THIS.lConnected
            lcReturn = THIS.FTPConnect(THIS.cUser, THIS.cPwd, THIS.cserver)
        ENDIF

        IF THIS.lConnected
            lcSourceFile = THIS.cSourceFile
            lcTargetFile = THIS.cTargetFile

            lnCount  = 0
            lnResult = 1

            lnResult = THIS.FTPSendFileEx(lcSourceFile, lcTargetFile)

            IF lnResult # 0
                THIS.cErrorMessage = THIS.cErrorMsg
                llReturn           = .F.
            ENDIF
            IF VARTYPE(THIS.oProgress) = 'O'
                THIS.oProgress.closeprogress()
                THIS.oProgress = .NULL.
            ENDIF
            THIS.FTPClose()
            THIS.lConnected = .F.
        ENDIF
    CATCH TO loError
        llReturn = .F.
        DO errorlog WITH 'SendFile', loError.LINENO, 'swFTP', loError.ERRORNO, loError.MESSAGE, '', loError
    ENDTRY

    RETURN llReturn


ENDDEFINE

******************************
DEFINE CLASS swupdates AS RELATION
    ******************************

    cSourceFile   = ""
    cTargetFile   = ""
    cErrorMessage = ""
    cDescription  = ""
    cUnZipTo      = ""
    nResult       = 0

    ***********************
    PROCEDURE GetUpdate
    ***********************
    LPARAMETERS llNoExtract
    *
    * Retrieves the given update from the update server
    *
    LOCAL llReturn, loIP, lcSourceFile, lcTargetFile

    llReturn = .T.

    TRY
        IF EMPTY(THIS.cSourceFile) 
            THIS.cErrorMessage = "Invalid source file given. It was either empty or didn't exist."
            llReturn           = .F.
            EXIT
        ENDIF

        IF VARTYPE(THIS.cUnZipTo) # 'C' OR EMPTY(this.cUnZipTo)
            THIS.cUnZipTo = m.goapp.crptsfolder
        ENDIF

        IF IsInternetAvailable("https://updates.sherware.com")

            loIP             = CREATEOBJECT('wwftp')
            loIP.lPassiveFTP = .T.
            loIP.nFTPPort    = 441
            loIP.FTPConnect(TRIM('updates.sherware.com'), ;
                  TRIM('sw-updates'), ;
                  TRIM('jE4t!TbC=9x[') )

            lcSourceFile = THIS.cSourceFile
            lcTargetFile = THIS.cTargetFile

            THIS.nResult       = loIP.FTPGetFileEx(lcSourceFile, lcTargetFile)
            THIS.cErrorMessage = loIP.cErrorMsg

            llReturn = THIS.nResult = 0

            IF !llNoExtract
                IF llReturn AND FILE(lcTargetFile)
                    lcLibraries = LOWER(SET('library'))
                    IF NOT 'vfpcompression' $ lcLibraries
                        SET LIBRARY TO vfpcompression.fll ADDITIVE
                    ENDIF

                    TRY
                        IF UnzipQuick(lcTargetFile, THIS.cUnZipTo) && attempt to extract the update
                            THIS.cErrorMessage = "The " + THIS.cDescription + " have been downloaded and installed."
                            llReturn           = .T.
                        ELSE
                            THIS.cErrorMessage = "Unable to extract the " + THIS.cDescription + ". "
                            llReturn           = .F.
                        ENDIF
                    CATCH TO loError
                        THIS.cErrorMessage = "Unable to extract the " + THIS.cDescription + ". "
                        llReturn           = .F.
                    ENDTRY
                    ERASE (lcTargetFile)
                ELSE
                    THIS.cErrorMessage = "The " + THIS.cDescription + " are not available on SherWare's server yet."
                    llReturn = .F.
                ENDIF
            ELSE
                llReturn = .T.
            ENDIF
        ELSE
            THIS.cErrorMessage = "No internet connection is available."
            llReturn           = .F.
        ENDIF

    CATCH TO loError
        THIS.cErrorMessage = loError.MESSAGE
        llReturn           = .F.
    ENDTRY

    RETURN llReturn

ENDDEFINE








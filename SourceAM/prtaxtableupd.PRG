LPARAMETERS tlQuiet, tlForce
LOCAL lcCurrentYear, lcDescription, lcLibrary, lcSourceFile, lcTargetFile, lcWebYear
LOCAL llNeedNewTables, llReturn, llSupport, loUpdate, loerror
#DEFINE CRLF CHR(13) + CHR(10)

TRY
    lcLibrary = SET('library')

    llSupport = checksupportexp()

    IF NOT llSupport
        llReturn = .F.
        EXIT
    ENDIF

    * Get the year of the tax tables on the web
    lcWebYear = getupdateyear()

    * Get the current year of the tax tables
    lcCurrentYear = GetCurrentYear()

    * Compare to see if we need new tables
    IF lcCurrentYear < lcWebYear OR tlForce
        llNeedNewTables = .T.
    ELSE
        llNeedNewTables = .F.
    ENDIF

    IF llNeedNewTables
        IF NOT tlQuiet AND MESSAGEBOX('This utility will download payroll tax tables for year: ' + lcWebYear + CRLF + CRLF + ;
                  'Do you want to continue?', 36, 'Download Tax Tables') = 7
            llReturn = .F.
            EXIT
        ENDIF
    ELSE
        IF NOT tlQuiet
            MESSAGEBOX('Your already have the latest version of the tax tables. No download needed.', 64, 'Tax Table Update')
            llReturn = .F.
            EXIT
        ENDIF
    ENDIF

    IF llNeedNewTables
        lcSourceFile  = 'prtaxupd.zip'
        lcTargetFile  = m.goapp.cCommonFolder + 'prtaxupd.zip'
        lcDescription = 'Payroll Tax tables'

        loUpdate              = m.goapp.oUpdate
        loUpdate.cSourceFile  = lcSourceFile
        loUpdate.cTargetFile  = lcTargetFile
        loUpdate.cDescription = lcDescription
        loUpdate.cUnzipTo     = m.goapp.cCommonFolder
        llReturn              = loUpdate.GetUpdate()
        IF NOT tlQuiet
            IF llReturn
                MESSAGEBOX('The payroll tax tables for ' + lcWebYear + ' have been downloaded and installed successfully.', 64, 'Payroll Tax Table Update')
            ELSE
                MESSAGEBOX('The payroll tax tables for ' + lcWebYear + ' were not downloaded successfully. Please try again.', 64, 'Payroll Tax Table Update')
            ENDIF
        ENDIF
    ENDIF



CATCH TO loerror
    DO errorlog WITH 'PRTaxTableUpd', loerror.LINENO, 'Update PR Tax Tables', loerror.ERRORNO, loerror.MESSAGE
    MESSAGEBOX('Unable to update the payroll tax tables. Check the System Log found under Other Reports for more information.', 16, 'Problem Encountered')
    llReturn = .F.
ENDTRY

RETURN llReturn

*************************************
PROCEDURE getupdateyear
*************************************
LOCAL lnReturn
*:Global tcUpdateVersionFile
m.lnReturn = '0.00'
DECLARE INTEGER URLDownloadToFile IN urlmon.DLL;
    INTEGER pCaller, ;
    STRING  szURL, ;
    STRING  szFileName, ;
    INTEGER dwReserved, ;
    INTEGER lpfnCB

m.tcUpdateVersionFile = ADDBS(SYS(2023)) + SYS(2015) + ".txt" && temporary file created locally so server version can be read
*!* Attempt to get the Version file from the server
URLDownloadToFile(0, "http://support.sherware.com/download/prtaxtable.txt?fakevariable=" + SYS(2015), m.tcUpdateVersionFile, 0, 0)
IF FILE(m.tcUpdateVersionFile)
    m.lnReturn = TRANSFORM(FILETOSTR(m.tcUpdateVersionFile)) && version number of the latest update on server
ENDIF

RETURN m.lnReturn

ENDPROC


*********************
FUNCTION checksupportexp
*********************
LOCAL lcClient, lcCode, ldCurrentDate, ldExpDate, lnBytes, lnClient, lnCode
LOCAL oRegCode
*:Global fh
SET PROCEDURE TO swregcode ADDITIVE
* Start the regcode object
oRegCode = CREATEOBJECT('swregcode', SYS(5) + CURDIR() + 'datafiles\')

* If demo mode bail out
IF NOT oRegCode.GetOpt(5)
    RETURN .T.
ENDIF

lnClient = oRegCode.GetCode(1)
lcCode   = oRegCode.GetCode(2)

* Get the support expiration date
ldExpDate = oRegCode.Checksum(lnClient, lcCode, .F., .T.)

IF ldExpDate >= DATE()
    RETURN .T.
ELSE
    RETURN .F.
ENDIF

ENDFUNC

*************************
FUNCTION GetCurrentYear
*************************
LOCAL lcYear, loerror

TRY
    IF FILE(m.goapp.cCommonFolder + 'PRFedWH.dbf')
        IF NOT USED('PRFedWH')
            USE (m.goapp.cCommonFolder + 'PRFedWH') IN 0
        ENDIF
    ELSE
        IF NOT USED('PRFedWH')
            USE (m.goapp.cCommonFolder + 'prtax3') ALIAS PRFedWH IN 0
        ENDIF
    ENDIF

    SELECT PRFedWH
    SELECT cyear AS cyear FROM PRFedWH INTO CURSOR temp ORDER BY cyear GROUP BY cyear
    GO BOTTOM
    lcYear = temp.cyear

    USE IN temp
    USE IN PRFedWH

CATCH TO loerror
    lcYear = '****'
ENDTRY

RETURN lcYear

ENDFUNC


PROCEDURE UnzipQuick
ENDPROC
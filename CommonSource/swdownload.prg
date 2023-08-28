LPARAMETERS tlQuiet
LOCAL lcLibrary, lcSourceFile, lcTargetFile, llReturn, llSupport, loUpdate
#DEFINE CRLF CHR(13) + CHR(10)

lcLibrary = SET('library')

llSupport = checksupportexp()

IF NOT llSupport
    RETURN
ENDIF

IF NOT tlQuiet
    IF MESSAGEBOX('This utility will download updated SherWare system modules.' + CRLF + CRLF + ;
              'This should be done ONLY if instructed by SherWare support or a software message.' + CRLF + CRLF + ;
              'Do you want to continue?', 36, 'Download System Modules') = 7
        RETURN
    ENDIF
ENDIF

lcSourceFile = 'swdownload.zip'
lcTargetFile = m.goapp.cCommonFolder+'swdownload.zip'
lcDescription = 'SherWare system modules'

loUpdate              = m.goapp.oUpdate
loUpdate.cSourceFile  = lcSourceFile
loUpdate.cTargetFile  = lcTargetFile
loUpdate.cDescription = lcDescription
loUpdate.cUnzipTo     = m.goapp.cCommonFolder + 'update'
llReturn              = loUpdate.GetUpdate()


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
    IF FILE('datafiles\swconfig.daa', 1)
        fh            = FOPEN('datafiles\swconfig.daa')
        ldCurrentDate = FGETS(fh)
        FCLOSE(fh)
        ldCurrentDate = GOMONTH(CTOD(ldCurrentDate), -14)
        IF ldExpDate < ldCurrentDate
            MESSAGEBOX('Your SherWare Support Subscription Has Expired. ' + CHR(10) + ;
                  'Expiration Date: ' + DTOC(ldExpDate) + CHR(10) + ;
                  'Please contact SherWare Inc. to renew your support subscription. ' + CHR(10) + ;
                  'Phone: (888) 262-3115  Fax: (866) 338-1254  Email: sales@sherware.com', 48, 'Expired Support Subscription')
            RETURN .F.
        ENDIF
    ENDIF
    RETURN .T.
ELSE
    MESSAGEBOX('Your SherWare Support Subscription Has Expired. ' + CHR(10) + ;
          'Expiration Date: ' + DTOC(ldExpDate) + CHR(10) + ;
          'Please contact SherWare Inc. to renew your support subscription. ' + CHR(10) + ;
          'Phone: (888) 262-3115  Fax: (866) 338-1254  Email: sales@sherware.com', 48, 'Expired Support Subscription')
    IF NOT FILE('datafiles\swconfig.daa', 1)
        fh        = FCREATE('datafiles\swconfig.daa')
        ldExpDate = DTOC(GOMONTH(DATE(), 14))
        lnBytes   = FWRITE(fh, ldExpDate)
        FCLOSE(fh)
    ENDIF
    RETURN .F.
ENDIF

ENDFUNC


PROCEDURE UnzipQuick
ENDPROC

 
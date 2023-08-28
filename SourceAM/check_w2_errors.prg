LPARAMETERS tcYear, tlSubmit, tlIgnoreState
*
* Check for any errors with the W2s like missing states, taxids, etc
*
PRIVATE m.cProducer, m.cProcessor
LOCAL lcTIN, llError, loError, llReturn
LOCAL lcMessage, lcNameCtl, lcPhone, lcState, lcaddr1, lcaddr2, lccity, lcemail, lcproducer, lczip
*:Global cGrpName

llReturn = .T.

IF FILE('datafiles\w2ignorestate.txt')
   tlIgnoreState = .T.
ENDIF 

TRY
    IF tlSubmit
        lcMessage = ''
        IF NOT USED('compmast')
            USE (m.goapp.cCommonFolder + 'compmast') IN 0
        ENDIF
        SELECT compmast
        SET ORDER TO cidcomp
        SEEK(m.goapp.cidcomp)

        lcproducer = ALLTRIM(STRTRAN(compmast.cProducer, '&', '&amp;'))
        lcaddr1    = ALLTRIM(STRTRAN(compmast.caddress1, '&', '&amp;'))
        lcaddr2    = ALLTRIM(STRTRAN(compmast.caddress2, '&', '&amp;'))
        lccity     = ALLTRIM(STRTRAN(compmast.ccity, '&', '&amp;'))
        lcState    = ALLTRIM(compmast.cstate)
        lczip      = ALLTRIM(compmast.czipcode)
        lcTIN      = ALLTRIM(STRTRAN(cmEncrypt(ALLTRIM(compmast.ctaxid),m.goapp.cEncryptionKey), '-', ''))
        lcPhone    = ALLTRIM(STRTRAN(compmast.cphoneno, '-', ''))
        lcPhone    = ALLTRIM(STRTRAN(lcPhone, '(', ''))
        lcPhone    = ALLTRIM(STRTRAN(lcPhone, ')', ''))
        lcPhone    = ALLTRIM(STRTRAN(lcPhone, ' ', ''))
        lcemail    = ALLTRIM(compmast.cemail)
        lcNameCtl  = ALLTRIM(UPPER(LEFT(lcproducer, 4)))

        IF EMPTY(lcemail) AND NOT FILE('datafiles/pats.txt')
            lcMessage = lcMessage + "You must specify a valid email address for " + lcproducer + ;
                " in Maintain Company Information before submitting the W2s." + CHR(10)
            llReturn = .F.
        ENDIF
        IF EMPTY(lcaddr1)
            lcMessage = lcMessage + "You must specify a valid address for " + lcproducer + ;
                " in Maintain Company Information before submitting the W2s." + CHR(10)
            llReturn = .F.
        ENDIF
        IF EMPTY(lccity)
            lcMessage = lcMessage + "You must specify a valid city for " + lcproducer + ;
                " in Maintain Company Information before submitting the W2s." + CHR(10)
            llReturn = .F.
        ENDIF
        IF EMPTY(lcState)
            lcMessage = lcMessage + "You must specify a valid state for " + lcproducer + ;
                " in Maintain Company Information before submitting the W2s." + CHR(10)
            llReturn = .F.
        ENDIF
        IF EMPTY(lczip)
            lcMessage = lcMessage + "You must specify a valid zip code for " + lcproducer + ;
                " in Maintain Company Information before submitting the W2s." + CHR(10)
            llReturn = .F.
        ENDIF
        IF EMPTY(lcTIN)
            lcMessage = lcMessage + "You must specify a tax id for " + lcproducer + ;
                " in Maintain Company Information before submitting the W2s." + CHR(10)
            llReturn = .F.
        ENDIF
        lcFirstDigit = LEFT(ALLTRIM(lcTIN), 1)
        llSame       = .T.
        FOR x = 2 TO LEN(lcTIN)
            IF SUBSTR(lcTIN, x, 1) # lcFirstDigit
                llSame = .F.
            ENDIF
        ENDFOR
        IF llSame
            lcMessage = lcMessage + "The tax id for " + lcproducer + ' cannot be all the same digit. Please fix' + ;
                " in Maintain Company Information before submitting the W2s." + CHR(10)
            llReturn = .F.
        ENDIF

        IF LEN(lcTIN) <> 9 AND LEN(lcTIN) # 0
            lcMessage = lcMessage + "The tax id specified in Maintain Company Information must be 9 digits." + CHR(10)
            llReturn  = .F.
        ENDIF
        IF NOT EMPTY(lcMessage)
            MESSAGEBOX(lcMessage, 16, 'Invalid Company Info')
            EXIT
        ENDIF
    ENDIF
*
*  Make the cProducer variable a default value for development purposes
*
    IF TYPE('m.goApp') = 'O'
        m.cProducer = m.goapp.ccompanyname
        IF m.goapp.lDemo
            m.cProducer = 'Demo Version of Software'
            m.cGrpName  = m.cProducer
        ENDIF
    ELSE
        m.cProducer = 'Sample Development Company'
    ENDIF

    IF TYPE('m.cProcessor') <> 'C'
        m.cProcessor = ''
    ENDIF

    IF EMPTY(m.cProducer) OR m.cProducer = "''"
        m.cProducer = 'Sample Development Company'
    ENDIF

*:Global cmsg, cprocessor, cproducer
    CREATE CURSOR w2errors ;
        (cID      c(10), ;
          cname    c(60), ;
          ctaxid   c(15), ;
          cmsg     M)
    m.cmsg = ''

    swselect('prw2file')
    SCAN FOR cYear == tcYear
        SCATTER MEMVAR
        llError  = .F.
        m.cname  = m.cempname
        m.cemptaxid = cmEncrypt(ALLTRIM(m.cemptaxid),m.goapp.cEncryptionKey)
        m.cID    = m.cempid
        m.czip   = m.czipcode

        lcTIN = ALLTRIM(STRTRAN(STRTRAN(m.cemptaxid, '-', ''), ' ', ''))

* Look for missing TIN
        IF EMPTY(lcTIN)
            m.cmsg  = 'Missing TIN'
            llError = .T.
        ENDIF

* Check for TIN being all the same digit        
        lcFirstDigit = LEFT(ALLTRIM(lcTIN), 1)
        llSame       = .T.
        FOR x = 2 TO LEN(lcTIN)
            IF SUBSTR(lcTIN, x, 1) # lcFirstDigit
                llSame = .F.
            ENDIF
        ENDFOR
        IF llSame
            IF NOT EMPTY(m.cmsg)
                m.cmsg = m.cmsg + CHR(10) + "Invalid tax id. The tax id cannot be all the same digit."
            ELSE
                m.cmsg = "Invalid tax id. The tax id cannot be all the same digit."
            ENDIF
            llError = .T.
        ENDIF


* Look for an invalid TIN (not long enough)
        IF LEN(lcTIN) # 9 AND LEN(lcTIN) > 0
            IF NOT EMPTY(m.cmsg)
                m.cmsg = m.cmsg + CHR(10) + 'Invalid TIN. Must be 9 digits.'
            ELSE
                m.cmsg = 'Invalid TIN. Must be 9 digits.'
            ENDIF
            llError = .T.
        ENDIF

* Look for an invalid TIN (asterisks)
        IF '*' $ lcTIN
            IF NOT EMPTY(m.cmsg)
                m.cmsg = m.cmsg + CHR(10) + 'Invalid TIN. Must not include "*".'
            ELSE
                m.cmsg = 'Invalid TIN. Must not include "*".'
            ENDIF
            llError = .T.
        ENDIF

* Check for bad state taxes
        IF NOT tlIgnoreState
            IF NOT EMPTY(m.cstate1) AND NOT INLIST(m.cstate1, 'TX', 'FL', 'WY', 'NV', 'SD', 'TN', 'WA')
                IF EMPTY(m.cstateid1)
                    IF NOT EMPTY(m.cmsg)
                        m.cmsg = m.cmsg + CHR(10) + 'Missing the state payer number for ' + m.cstate1 + ' state taxes.'
                    ELSE
                        m.cmsg = 'Missing the state payer number for ' + m.cstate1 + ' state taxes.'
                    ENDIF
                    llError = .T.
                ENDIF
            ENDIF
            IF NOT EMPTY(m.cstate2) AND NOT INLIST(m.cstate2, 'TX', 'FL', 'WY', 'NV', 'SD', 'TN', 'WA')
                IF EMPTY(m.cstateid2)
                    IF NOT EMPTY(m.cmsg)
                        m.cmsg = m.cmsg + CHR(10) + 'Missing the state payer number for ' + m.cstate2 + ' state taxes.'
                    ELSE
                        m.cmsg = 'Missing the state payer number for ' + m.cstate2 + ' state taxes.'
                    ENDIF
                    llError = .T.
                ENDIF
            ENDIF
        ENDIF

        IF EMPTY(m.caddress1)
            IF EMPTY(m.cmsg)
                m.cmsg = 'Missing address.'
            ELSE
                m.cmsg = m.cmsg + CHR(10) + 'Missing address.'
            ENDIF
            llError = .T.
        ENDIF

        IF EMPTY(m.ccity)
            IF EMPTY(m.cmsg)
                m.cmsg = 'Missing city in address.'
            ELSE
                m.cmsg = m.cmsg + CHR(10) + 'Missing city in address.'
            ENDIF
            llError = .T.
        ENDIF

        IF EMPTY(m.cstate)
            IF EMPTY(m.cmsg)
                m.cmsg = 'Missing state in address.'
            ELSE
                m.cmsg = m.cmsg + CHR(10) + 'Missing state in address.'
            ENDIF
            llError = .T.
        ENDIF

        IF EMPTY(m.czip)
            IF EMPTY(m.cmsg)
                m.cmsg = 'Missing zip code form address.'
            ELSE
                m.cmsg = m.cmsg + CHR(10) + 'Missing zip code from address.'
            ENDIF
            llError = .T.
        ENDIF

        IF llError
            INSERT INTO w2errors FROM MEMVAR
            m.cmsg   = ''
            llReturn = .F.
        ENDIF
    ENDSCAN

    SELECT w2errors
    IF RECCOUNT() > 0
        MESSAGEBOX('There are problems with your W2 file. Please correct them before submitting W2s to the IRS. An error report follows.', 48, 'W2 Problems')
        REPORT FORM commonsource\w2errors TO PRINTER PROMPT PREVIEW NOCONSOLE
        llReturn = .F.
        EXIT
    ENDIF
CATCH TO loError
    llReturn = .F.
    DO errorlog WITH 'checkw2s', loError.LINENO, 'W2submit', loError.ERRORNO, loError.MESSAGE, '', loError
    MESSAGEBOX('Unable to process the W2s at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
          'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn







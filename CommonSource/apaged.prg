LPARA tcBegVendor, tcEndVendor, tdThroughDate, tnDate, tcFileType, tlDetail, tcDept, tlSelected
*  tcBegVendor   = Beginning vendor id in the range to include
*  tcEndVendor   = Ending vendor id in the range to include
*  tdThroughDate = Date to calculate balances through
*  tlDueDate     = .T. if the due date is to be used instead of the invoice date
*  tcFileType    = 'D' - Detail, 'S' - Summary  Type of file to build.
*  tlDetail      = .T. - provide extra detail for outstanding bills report
*  tcDept        = department report is for or 'All' for all depts
LOCAL lcAPAcct, ldThroughDate, lcBegVendor, lcEndVendor, lnCount
LOCAL loError, llReturn
LOCAL lcFileType, llDetail, lnDate
LOCAL cBatch, cInvNum, cVendName, cVendorID, dInvDate, ddate, jdays30, jdays60, jdays90, nBal30
LOCAL nBal60, nBal90, nBalance, nDiscIn, nDiscPct, nDiscount, nInvAge, nInvBal, nNetDue, ncurrent

llReturn = .T.

IF NOT tlSelected
   SELECT cvendorid as cid ;
      FROM vendor ;
      WHERE BETWEEN(cvendorid,tcBegVendor,tcEndVendor) ;
      INTO CURSOR selected ;
      ORDER BY cid
ENDIF 

TRY
    IF TYPE('tnDate') = 'L'
        IF tnDate
            tnDate = 1
        ELSE
            tnDate = 2
        ENDIF
    ENDIF

    IF TYPE('tcDept') <> 'C'
        tcDept = 'All'
    ENDIF

    ldThroughDate = tdThroughDate
    lcBegVendor   = tcBegVendor
    lcEndVendor   = tcEndVendor
    lnDate        = tnDate
    lcFileType    = tcFileType
    llDetail      = tlDetail

    swselect('apopt')
    lcAPAcct = capacct

    jdays30 = ldThroughDate - 31
    jdays60 = ldThroughDate - 61
    jdays90 = ldThroughDate - 91

*  Clean up any bogus appmtdet entries
	SELECT  cidappmd, cBatch ;
		FROM appmtdet ;
		WHERE cBatch NOT IN(SELECT  cBatch ;
								FROM appmthdr)  ;
		INTO CURSOR temp

    IF _TALLY > 0
        SELECT temp
        SCAN
            swselect('appmtdet')
            SCAN FOR cidappmd = temp.cidappmd
                DELETE NEXT 1
            ENDSCAN
        ENDSCAN
    ENDIF

*
*  Set the report name based upon the report type chosen
*
    DO CASE
        CASE lcFileType = 'S'           && Summary Report Requested
* Get a cursor of payments through the given date
            SELECT * FROM appmtdet INTO CURSOR temppmt WHERE appmtdet.cBatch IN (SELECT cBatch FROM appmthdr WHERE dpmtdate <= ldThroughDate)

            CREATE CURSOR tempinv ;
                (cBatch     C(8), ;
                  cVendorID  C(10), ;
                  cVendName  C(40), ;
                  cidterm    C(8), ;
                  dDueDate   D, ;
                  dInvDate   D, ;
                  dDiscDate  D, ;
                  nDiscount  N(12, 2), ;
                  cInvNum    C(20), ;
                  nInvTot    N(12, 2), ;
                  nInvBal    N(12, 2), ;
                  nNetDue    N(12, 2), ;
                  nBalance   N(12, 2),  ;
                  namtpaid   N(12, 2),  ;
                  ndisctaken N(12, 2))

            CREATE CURSOR vendbal ;
                (cVendorID  C(10), ;
                  cVendName  C(40), ;
                  ncurrent   N(12, 2), ;
                  ndays01    N(12, 2), ;
                  ndays31    N(12, 2), ;
                  ndays61    N(12, 2), ;
                  ndays91    N(12, 2), ;
                  ninvage    I)
              INDEX on ninvage TAG age 

			SELECT  appurchh.cVendorID AS cVendorID, ;
					vendor.cVendName, ;
					appurchh.cBatch, ;
					appurchh.dDueDate, ;
					appurchh.dDiscDate, ;
					appurchh.dInvDate, ;
					appurchh.cInvNum, ;
					appurchh.cidterm, ;
					appurchh.nInvTot, ;
					appurchh.nInvTot AS nBalance, ;
					appurchh.nInvBal, ;
					SUM(temppmt.namtpaid) AS namtpaid,  ;
					SUM(temppmt.ndisctaken) AS ndisctaken  ;
				FROM appurchh ;
				LEFT OUTER JOIN temppmt  ;
					ON appurchh.cBatch = temppmt.cBillToken  ;
				JOIN vendor  ;
					ON appurchh.cVendorID == vendor.cVendorID  ;
				WHERE appurchh.cvendorid in (select cid from selected) ;
					AND IIF(lnDate = 1, appurchh.dDueDate, IIF(lnDate = 2, appurchh.dInvDate, appurchh.dPostDate)) <= ldThroughDate ;
					AND NOT DELETED() ;
				INTO CURSOR temp READWRITE ;
				ORDER BY appurchh.cBatch ;
				GROUP BY appurchh.cBatch

            SELECT temp
            SCAN FOR ISNULL(namtpaid)
                REPLACE namtpaid WITH 0, ndisctaken WITH 0
            ENDSCAN

            SELECT tempinv
            APPEND FROM DBF('temp')

            SELECT tempinv
            SCAN
                SCATTER MEMVAR
                REPLACE nBalance WITH nBalance - (namtpaid + ndisctaken), nNetDue WITH nBalance - (namtpaid + ndisctaken)
                IF nInvTot < 0 AND nBalance = 0
                    REPL nBalance WITH 0, ;
                        nNetDue  WITH 0
                ELSE
                    swselect('terms')
                    SET ORDER TO cidterm
                    SEEK m.cidterm
                    IF FOUND()
                        m.nDiscIn  = nDiscIn
                        m.nDiscPct = nDiscPct
                    ELSE
                        m.nDiscIn  = 0
                        m.nDiscPct = 0
                    ENDIF
                    IF m.dDiscDate >= ldThroughDate
                        m.nDiscount = m.nBalance * (m.nDiscPct / 100)
                        m.nNetDue   = m.nBalance - m.nDiscount
                    ELSE
                        m.nDiscount = 0
                        m.nNetDue   = m.nBalance
                    ENDIF
                    SELE tempinv
                    REPL nNetDue WITH m.nNetDue
                ENDIF
            ENDSCAN
*****
			SELECT  appurchh.cVendorID AS cVendorID, ;
					vendor.cVendName, ;
					00000.00 AS ncurrent, ;
					00000.00 AS ndays30, ;
					00000.00 AS ndays60, ;
					00000.00 AS ndays90 ;
				FROM appurchh, vendor ;
				WHERE appurchh.cvendorid in (select cid from selected) ;
					AND appurchh.cVendorID == vendor.cVendorID ;
					AND IIF(lnDate = 1, appurchh.dDueDate, IIF(lnDate = 2, appurchh.dInvDate, appurchh.dPostDate)) <= ldThroughDate ;
					AND NOT DELETED() ;
				INTO CURSOR vendbalx ;
				ORDER BY appurchh.cVendorID ;
				GROUP BY appurchh.cVendorID
            SELECT vendbal
            APPEND FROM DBF('vendbalx')
            INDEX ON cVendorID TAG cVendorID
            m.ncurrent = 0
            m.nBal01   = 0
            m.nBal31   = 0
            m.nBal61   = 0
            m.nBal91   = 0
            SELECT vendbal
            SCAN
                m.cVendorID = cVendorID
                SELECT tempinv
                SCAN FOR cVendorID = m.cVendorID
                    m.ddate    = dDueDate
                    m.nBalance = nBalance
                    DO CASE
                        CASE m.ddate >= ldThroughDate
                           m.ncurrent = m.ncurrent + m.nBalance
                        CASE BETWEEN(m.ddate, jdays30, ldThroughDate)
                            m.nBal01 = m.nBal01 + m.nBalance
                        CASE BETWEEN(m.ddate, jdays60, jdays30)
                            m.nBal31 = m.nBal31 + m.nBalance
                        CASE BETWEEN(m.ddate, jdays90, jdays60)
                            m.nBal61 = m.nBal61 + m.nBalance
                        CASE m.ddate < jdays90
                            m.nBal91 = m.nBal91 + m.nBalance
                        OTHERWISE
                            m.ncurrent = m.ncurrent + m.nBalance
                    ENDCASE
                    m.nBalance = 0
                ENDSCAN
                SELECT vendbal
                REPLACE ncurrent WITH m.ncurrent, ;
                    ndays01  WITH m.nBal01, ;
                    ndays31  WITH m.nBal31, ;
                    ndays61  WITH m.nBal61, ;
                    ndays91  WITH m.nBal91
                STORE 0 TO m.ncurrent, m.nBal01, m.nBal31, m.nBal61, m.nBal91
            ENDSCAN
*****
            SELECT vendbal
            DELETE FOR (ncurrent + ndays01 + ndays31 + ndays61 + ndays91) = 0
            SET ORDER TO cVendorID
            COUNT FOR NOT DELETED() TO lnCount
            IF lnCount = 0
                llReturn = .F.
            ELSE
                llReturn = .T.
            ENDIF

        CASE lcFileType = 'D'     && Detail Report Requested

            CREATE CURSOR tempinv ;
                (cBatch     C(8), ;
                  cVendorID  C(10), ;
                  cVendName  C(40), ;
                  cWellID    C(10), ;
                  cWellName  C(40),  ;
                  cProdYear      C(4),  ;
                  cProdPeriod    C(2),  ;
                  cCatCode   C(4), ;
                  cCatDesc   C(30), ;
                  cItemDesc  C(40), ;
                  cAcctNo    C(6), ;
                  cAcctDesc  C(30), ;
                  cDeptNo    C(8), ;
                  nAmount    N(12, 2), ;
                  dDueDate   D, ;
                  dInvDate   D, ;
                  dPostDate  D, ;
                  dDiscDate  D, ;
                  cidterm    C(8), ;
                  cInvNum    C(20), ;
                  nInvTot    N(12, 2), ;
                  nDiscount  N(12, 2), ;
                  nInvBal    N(12, 2), ;
                  nNetDue    N(12, 2), ;
                  nBalance   N(12, 2),  ;
                  namtpaid   N(12, 2),  ;
                  ndisctaken N(12, 2))
            CREATE CURSOR vendbal ;
                (cVendorID  C(10), ;
                  cVendName   C(40), ;
                  cInvNum     C(20), ;
                  dInvDate    D, ;
                  dDueDate    D, ;
                  nInvBal     N(12, 2), ;
                  nInvAge     I)
            INDEX ON cVendorID TAG cVendorID
            INDEX on ninvage TAG age 
            INDEX ON cVendorID + DTOS(dInvDate) TAG venddate

            IF llDetail
* Get a cursor of payments through the given date
                SELECT * FROM appmtdet INTO CURSOR temppmt WHERE appmtdet.cBatch IN (SELECT cBatch FROM appmthdr WHERE dpmtdate <= ldThroughDate)
                IF 'All ' $ tcDept
					SELECT  appurchh.cVendorID AS cVendorID, ;
							vendor.cVendName, ;
							appurchh.cBatch, ;
							appurchh.dDueDate, ;
							appurchh.dInvDate, ;
							appurchh.dPostDate, ;
							appurchh.cInvNum, ;
							appurchh.nInvTot, ;
							appurchh.nInvTot AS nBalance, ;
							appurchh.nInvBal, ;
							appurchd.cunitno AS cWellID, ;
							appurchd.cDeptNo, ;
							appurchd.cCatCode, ;
							appurchd.cAcctNo, ;
							appurchd.cProdYear,  ;
							appurchd.cProdPeriod,  ;
							appurchd.cItemDesc, ;
							appurchd.nextension AS nAmount, ;
							SUM(temppmt.namtpaid) AS namtpaid,  ;
							SUM(temppmt.ndisctaken) AS ndisctaken,  ;
							SPACE(30) AS cAcctDesc ;
						FROM appurchh  ;
						LEFT OUTER JOIN temppmt  ;
							ON appurchh.cBatch = temppmt.cBillToken  ;
						JOIN appurchd  ;
							ON appurchh.cBatch = appurchd.cBatch  ;
						JOIN vendor  ;
							ON appurchh.cVendorID == vendor.cVendorID  ;
						WHERE appurchh.cvendorid in (select cid from selected) ;
							AND IIF(lnDate = 1, appurchh.dDueDate, IIF(lnDate = 2, appurchh.dInvDate, appurchh.dPostDate)) <= ldThroughDate ;
							AND NOT DELETED() ;
						INTO CURSOR temp READWRITE ;
						ORDER BY appurchh.cBatch  ;
						GROUP BY appurchh.cBatch, appurchd.cidpurd, temppmt.cBillToken

                ELSE
					SELECT  appurchh.cVendorID AS cVendorID, ;
							vendor.cVendName, ;
							appurchh.cBatch, ;
							appurchh.dDueDate, ;
							appurchh.dInvDate, ;
							appurchh.dPostDate, ;
							appurchh.cInvNum, ;
							appurchh.nInvTot, ;
							appurchh.nInvTot AS nBalance, ;
							appurchh.nInvBal, ;
							appurchd.cunitno AS cWellID, ;
							appurchd.cDeptNo, ;
							appurchd.cCatCode, ;
							appurchd.cAcctNo, ;
							appurchd.cProdYear,  ;
							appurchd.cProdPeriod,  ;
							appurchd.cItemDesc, ;
							appurchd.nextension AS nAmount, ;
							SUM(temppmt.namtpaid) AS namtpaid,  ;
							SUM(temppmt.ndisctaken) AS ndisctaken,  ;
							SPACE(30) AS cAcctDesc ;
						FROM appurchh  ;
						LEFT OUTER JOIN temppmt  ;
							ON appurchh.cBatch = temppmt.cBillToken  ;
						JOIN appurchd  ;
							ON appurchh.cBatch = appurchd.cBatch  ;
						JOIN vendor  ;
							ON appurchh.cVendorID == vendor.cVendorID  ;
						WHERE appurchh.cvendorid in (select cid from selected) ;
							AND IIF(lnDate = 1, appurchh.dDueDate, IIF(lnDate = 2, appurchh.dInvDate, appurchh.dPostDate)) <= ldThroughDate ;
							AND appurchd.cDeptNo = tcDept ;
							AND NOT DELETED() ;
						INTO CURSOR temp READWRITE ;
						ORDER BY appurchh.cBatch  ;
						GROUP BY appurchh.cBatch, appurchd.cidpurd, temppmt.cBillToken
                ENDIF

                SELECT temp
                SCAN FOR ISNULL(namtpaid)
                    REPLACE namtpaid WITH 0, ndisctaken WITH 0
                ENDSCAN

                SELECT tempinv
                APPEND FROM DBF('temp')

                swselect('expcat')
                SET ORDER TO cCatCode

                swselect('coa')
                SET ORDER TO acctno

                SELECT tempinv
                SCAN
                    m.cBatch = cBatch
                    IF m.goApp.lAMVersion
                        swselect('coa')
                        IF SEEK(tempinv.cAcctNo)
                            REPLACE tempinv.cAcctDesc WITH coa.cAcctDesc
                        ELSE
                            REPLACE tempinv.cAcctDesc WITH 'Accounts Payable'
                        ENDIF
                    ELSE
                        REPLACE tempinv.cAcctDesc WITH 'Accounts Payable'
                    ENDIF
                    swselect('expcat')
                    IF SEEK(tempinv.cCatCode)
                        SELE tempinv
                        REPL tempinv.cCatDesc WITH expcat.ccateg
                    ENDIF
                ENDSCAN
                SELECT tempinv
                SCAN
                    SCATTER MEMVAR
                    REPLACE nBalance WITH nBalance - (namtpaid + ndisctaken), nNetDue WITH nBalance - (namtpaid + ndisctaken)
                    IF nInvTot < 0 AND nBalance = 0
                        REPL nNetDue  WITH 0
                    ELSE
                        swselect('terms')
                        SET ORDER TO cidterm
                        SEEK m.cidterm
                        IF FOUND()
                            m.nDiscIn  = nDiscIn
                            m.nDiscPct = nDiscPct
                        ELSE
                            m.nDiscIn  = 0
                            m.nDiscPct = 0
                        ENDIF
                        IF m.dDiscDate >= ldThroughDate
                            m.nDiscount = m.nBalance * (m.nDiscPct / 100)
                            m.nNetDue   = m.nBalance - m.nDiscount
                        ELSE
                            m.nDiscount = 0
                            m.nNetDue   = m.nBalance
                        ENDIF
                        SELE tempinv
                        REPL nNetDue WITH m.nNetDue
                        swselect('wells')
                        SET ORDER TO cWellID
                        IF SEEK(tempinv.cWellID)
                            REPLACE tempinv.cWellName WITH wells.cWellName
                        ENDIF
                    ENDIF
                ENDSCAN
*****
                swselect('vendor')
                SCAN 
                    m.cVendorID = cVendorID
                    m.cVendName = cVendName
                    
                    SELECT selected
                    LOCATE FOR cid = m.cVendorid
                    IF NOT FOUND()
                       LOOP
                    ENDIF 
                    
                    SELECT tempinv
                    SCAN FOR cVendorID = m.cVendorID
                        IF lnDate = 1
                            IF dDueDate > ldThroughDate
                                LOOP
                            ENDIF
                        ENDIF
                        IF lnDate = 2
                            IF dInvDate > ldThroughDate
                                LOOP
                            ENDIF
                        ENDIF
                        IF lnDate = 3
                            IF dPostDate > ldThroughDate
                                LOOP
                            ENDIF
                        ENDIF
                        m.nInvAge  = dDueDate - ldThroughDate
                        m.dInvDate = dDueDate
                        m.cInvNum  = cInvNum
                        m.nInvBal  = nBalance
                        INSERT INTO vendbal FROM MEMVAR
                    ENDSCAN
                    swselect('vendor')
                ENDSCAN
                SELECT vendbal
                SET ORDER TO venddate
                DELE FOR nInvBal = 0
                COUNT FOR NOT DELETED() TO lnCount
                IF lnCount = 0
                    llReturn = .F.
                ELSE
                    llReturn = .T.
                ENDIF
            ELSE

                SELECT * FROM appmtdet INTO CURSOR temppmt WHERE appmtdet.cBatch IN (SELECT cBatch FROM appmthdr WHERE dpmtdate <= ldThroughDate)
				SELECT  appurchh.cVendorID AS cVendorID, ;
						vendor.cVendName, ;
						appurchh.cBatch, ;
						appurchh.dDueDate, ;
						appurchh.dInvDate, ;
						appurchh.dPostDate, ;
						appurchh.cInvNum, ;
						appurchh.nInvTot, ;
						appurchh.nInvTot AS nBalance, ;
						appurchh.nInvBal, ;
						SUM(temppmt.namtpaid) AS namtpaid,  ;
						SUM(temppmt.ndisctaken) AS ndisctaken  ;
					FROM appurchh  ;
					LEFT OUTER JOIN temppmt  ;
						ON appurchh.cBatch = temppmt.cBillToken  ;
					JOIN vendor  ;
						ON appurchh.cVendorID == vendor.cVendorID  ;
					WHERE appurchh.cvendorid in (select cid from selected) ;
						AND IIF(lnDate = 1, appurchh.dDueDate, IIF(lnDate = 2, appurchh.dInvDate, appurchh.dPostDate)) <= ldThroughDate ;
						AND NOT DELETED() ;
					INTO CURSOR temp READWRITE ;
					ORDER BY appurchh.cBatch  ;
					GROUP BY appurchh.cBatch

                SELECT temp
                SCAN FOR ISNULL(namtpaid)
                    REPLACE namtpaid WITH 0, ndisctaken WITH 0
                ENDSCAN

                SELECT tempinv
                APPEND FROM DBF('temp')

                SELECT tempinv
                SCAN
                    SCATTER MEMVAR
                    REPLACE nBalance WITH nBalance - (namtpaid + ndisctaken), nNetDue WITH nBalance - (namtpaid + ndisctaken)
                    IF nInvTot < 0 AND nBalance = 0
                        REPL nBalance WITH 0, ;
                            nNetDue  WITH 0
                    ELSE
                        swselect('terms')
                        SET ORDER TO cidterm
                        SEEK m.cidterm
                        IF FOUND()
                            m.nDiscIn  = nDiscIn
                            m.nDiscPct = nDiscPct
                        ELSE
                            m.nDiscIn  = 0
                            m.nDiscPct = 0
                        ENDIF
                        IF m.dDiscDate >= ldThroughDate
                            m.nDiscount = m.nBalance * (m.nDiscPct / 100)
                            m.nNetDue   = m.nBalance - m.nDiscount
                        ELSE
                            m.nDiscount = 0
                            m.nNetDue   = m.nBalance
                        ENDIF
                        SELE tempinv
                        REPL nNetDue WITH m.nNetDue
                    ENDIF
                ENDSCAN
*****
                swselect('vendor')
                SCAN FOR BETWEEN(cVendorID, lcBegVendor, lcEndVendor)
                    m.cVendorID = cVendorID
                    m.cVendName = cVendName
                    SELECT tempinv
                    SCAN FOR cVendorID = m.cVendorID
                        IF lnDate = 1
                            IF dDueDate > ldThroughDate
                                LOOP
                            ENDIF
                        ENDIF
                        IF lnDate = 2
                            IF dInvDate > ldThroughDate
                                LOOP
                            ENDIF
                        ENDIF
                        IF lnDate = 3
                            IF dPostDate > ldThroughDate
                                LOOP
                            ENDIF
                        ENDIF
                        m.nInvAge  = dDueDate - ldThroughDate
                        m.dInvDate = dDueDate
                        m.cInvNum  = cInvNum
                        m.nInvBal  = nBalance
                        INSERT INTO vendbal FROM MEMVAR
                    ENDSCAN
                    swselect('vendor')
                ENDSCAN
                SELECT vendbal
                SET ORDER TO venddate
                DELE FOR nInvBal = 0
                COUNT FOR NOT DELETED() TO lnCount
                IF lnCount = 0
                    llReturn = .F.
                ELSE
                    llReturn = .T.
                ENDIF
            ENDIF
    ENDCASE
CATCH TO loError
    llReturn = .F.
    DO errorlog WITH 'APAged', loError.LINENO, 'None', loError.ERRORNO, loError.MESSAGE, '', loError
    MESSAGEBOX('Unable to process the report at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
          'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn

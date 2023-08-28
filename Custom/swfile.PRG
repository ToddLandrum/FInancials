****************************************
*  Class library: swfile
****************************************

DEFINE CLASS swfile AS CUSTOM

   cSoftware   = 'A'
   oImportFile = .NULL.
   cType       = 'REV'
   cMapName    = ''
   lXLSX       = .F.

   **************************
   PROCEDURE ImportCSV
      **************************
      LPARAMETERS lcFileName, lcType, lnDataSession
      LOCAL llXLSX

      llXLSX = .F.

      IF EMPTY(lcFileName)
         MESSAGEBOX('Invalid or blank file name sent to IMPORTCSV', 0, 'Invalid File')
         RETURN .F.
      ENDIF

      IF 'XLS' $ UPPER(JUSTEXT(lcFileName))
         llXLSX = .T.
      ENDIF

      llReturn = .T.

      TRY

         IF VARTYPE(lnDataSession) = 'N'
            SET DATASESSION TO lnDataSession
         ENDIF

         IF lcType = 'R'
            CREATE CURSOR importtemp ;
               (cLine          C(10), ;
               cCheckno       C(10), ;
               cCheckDate     C(10), ;
               cPropertyNo    C(20), ;
               cPropName      C(60), ;
               cProdDate      C(10), ;
               cProdType      C(5), ;
               cIntType       C(2), ;
               cPrice         C(10), ;
               cownervol      C(15), ;
               cowngross      C(15), ;
               cowntax        C(15), ;
               cowndeducts    C(15), ;
               cownnet        C(15), ;
               csender        C(60))

            CREATE CURSOR importfile ;
               (crectype        C(10), ;
               csender         C(20), ;
               cCheckno        C(10), ;
               dCheckDate      D, ;
               dProdDate       D, ;
               cPropertyNo     C(20), ;
               cDOINo          C(10), ;
               cPropName       C(60), ;
               cPropState      C(2), ;
               cPropCounty     C(25), ;
               cProdDate       C(10), ;
               cProdType       C(5), ;
               cIntType        C(5), ;
               nprice          N(12, 2), ;
               nGrossVol       N(12, 2), ;
               nGrossVal       N(12, 2), ;
               nGrossTax       N(12, 2), ;
               nGrossDeducts   N(12, 2), ;
               nGrossNet       N(12, 2), ;
               nInterest       N(11, 7), ;
               nIntPaid        N(11, 7), ;
               nOwnerVol       N(12, 2), ;
               nowngross       N(12, 2), ;
               nowntax         N(12, 2), ;
               nwithhold       N(12, 2), ;
               nowndeducts     N(12, 2), ;
               nownroychg      N(12, 2), ;
               nownnet         N(12, 2), ;
               nBTUFact        N(12, 4), ;
               cAdjCode        C(5), ;
               nCheckAmt       N(12, 2))

            IF llXLSX
               lnReturn =  THIS.getworksheet(lcFileName)
               IF lnReturn > 0
                  SELECT worksheettemp
                  SCAN
                     SCATTER MEMVAR
                     INSERT INTO importtemp FROM MEMVAR
                  ENDSCAN
               ELSE
                  EXIT
               ENDIF
            ELSE
               SELECT importtemp
               APPEND FROM (lcFileName) TYPE CSV
            ENDIF

            SELECT importtemp
            SCAN

               IF NOT ISDIGIT(SUBSTR(ALLTRIM(cLine), 1, 1))
                  LOOP
               ENDIF

               SCATTER MEMVAR

               m.cownervol   = STRTRAN(m.cownervol, '$', '')
               m.cownervol   = STRTRAN(m.cownervol, ',', '')
               m.cowngross   = STRTRAN(m.cowngross, '$', '')
               m.cowngross   = STRTRAN(m.cowngross, ',', '')
               m.cowntax     = STRTRAN(m.cowntax, '$', '')
               m.cowntax     = STRTRAN(m.cowntax, ',', '')
               m.cowndeducts = STRTRAN(m.cowndeducts, '$', '')
               m.cowndeducts = STRTRAN(m.cowndeducts, ',', '')
               m.cownnet     = STRTRAN(m.cownnet, '$', '')
               m.cownnet     = STRTRAN(m.cownnet, ',', '')
               m.iLine       = INT(VAL(m.cLine))
               m.dCheckDate  = CTOD(m.cCheckDate)
               m.dProdDate   = CTOD(m.cProdDate)

               IF '(' $ m.cownnet
                  m.cownnet = STRTRAN(m.cownnet, '(', '')
                  m.cownnet = STRTRAN(m.cownnet, ')', '')
                  m.nownnet = VAL(m.cownnet) * -1
               ELSE
                  m.nownnet = VAL(m.cownnet)
               ENDIF
               IF '(' $ m.cownervol
                  m.cownervol = STRTRAN(m.cownervol, '(', '')
                  m.cownervol = STRTRAN(m.cownervol, ')', '')
                  m.nOwnerVol = VAL(m.cownervol) * -1
               ELSE
                  m.nOwnerVol   = VAL(m.cownervol)
               ENDIF

               IF '(' $ m.cowngross
                  m.cowngross = STRTRAN(m.cowngross, '(', '')
                  m.cowngross = STRTRAN(m.cowngross, ')', '')
                  m.nowngross = VAL(m.cowngross) * -1
               ELSE
                  m.nowngross   = VAL(m.cowngross)
               ENDIF

               IF '(' $ m.cowntax
                  m.cowntax = STRTRAN(m.cowntax, '(', '')
                  m.cowntax = STRTRAN(m.cowntax, ')', '')
                  m.nowntax = VAL(m.cowntax) * -1
               ELSE
                  m.nowntax     = VAL(m.cowntax)
               ENDIF

               IF '(' $ m.cowndeducts
                  m.cowndeducts = STRTRAN(m.cowndeducts, '(', '')
                  m.cowndeducts = STRTRAN(m.cowndeducts, ')', '')
                  m.nowndeducts = VAL(m.cowndeducts) * -1
               ELSE
                  m.nowndeducts = VAL(m.cowndeducts)
               ENDIF

               INSERT INTO importfile FROM MEMVAR
            ENDSCAN
         ELSE

            CREATE CURSOR importtemp ;
               (cinvnum            C(20), ;
               cinvdate           C(10), ;
               cduedate           C(10), ;
               cProdDate          C(10), ;
               cPropertyNo        C(20), ;
               cPropName          C(60), ;
               cPropState         C(2), ;
               cPropCounty        C(25), ;
               cExpCode           C(5), ;
               cExpDesc           C(40), ;
               cIntType           C(5), ;
               cGrossVal          C(15), ;
               cInterest          C(15), ;
               cowngross          C(15))

            CREATE CURSOR importfile ;
               (cinvnum          C(20), ;
               dinvdate        D, ;
               dduedate        D, ;
               dProdDate       D, ;
               cPropertyNo     C(20), ;
               cPropName       C(60), ;
               cPropState      C(2), ;
               cPropCounty     C(25), ;
               cProdDate       C(10), ;
               cExpCode        C(5), ;
               cExpDesc        C(40), ;
               cIntType        C(5), ;
               nGrossVal       N(12, 2), ;
               nInterest       N(11, 7), ;
               nowngross       N(12, 2))
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'ImportCSV', loError.LINENO, 'swFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to import the CSV file at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn

      **************************
   PROCEDURE ImportOildex
      **************************
      LPARAMETERS lcFileName, lcType, lnDataSession
      LOCAL llXLSX

      llXLSX = .F.

      IF EMPTY(lcFileName)
         MESSAGEBOX('Invalid or blank file name sent to ImportOildex', 0, 'Invalid File')
         RETURN .F.
      ENDIF


      IF 'XLS' $ UPPER(JUSTEXT(lcFileName))
         llXLSX = .T.
      ENDIF

      llReturn = .T.

      TRY

         IF VARTYPE(lnDataSession) = 'N'
            SET DATASESSION TO lnDataSession
         ENDIF

         CREATE CURSOR importtemp ;
            (cLine          C(10), ;
            cCheckno       C(10), ;
            cCheckDate     C(10), ;
            cPropertyNo    C(20), ;
            cPropName      C(60), ;
            cProdDate      C(10), ;
            cProdType      C(5), ;
            cIntType       C(2), ;
            cownervol      C(15), ;
            cowngross      C(15), ;
            cowntax        C(15), ;
            cowndeducts    C(15), ;
            cownnet        C(15), ;
            csender        C(60))

         CREATE CURSOR importfile ;
            ( cCheckno        C(10), ;
            dCheckDate      D, ;
            dPostDate       D, ;
            dProdDate       D, ;
            cWellID         C(20), ;
            cDesc           C(30), ;
            cDeptNo         C(10), ;
            cOwnerID        C(10), ;
            cBegRange       C(5), ;
            cEndRange       C(5), ;
            nDaysOn         I, ;
            lWellRcpt       L, ;
            cProdYear       C(4), ;
            cProdPeriod     C(2), ;
            nSaltBBL        I, ;
            cAcctNo         C(6), ;
            cWellname       C(60), ;
            cProdType       C(5), ;
            nprice          N(12, 6), ;
            nUnits          N(12, 2), ;
            lGrossUnits     L, ;
            nGrossUnits     N(12,2), ;
            nTotalInc       N(12, 2), ;
            cTaxType        C(5), ;
            nTax            N(12, 2), ;
            cDedCode        C(4), ;
            nDeducts        N(12, 2), ;
            nNet            N(12, 2))

         IF llXLSX
            llReturn =  THIS.getworksheet(lcFileName)
            IF llReturn
               SELECT worksheettemp
               SCAN
                  SCATTER MEMVAR
                  m.cLine       = m.cf1
                  m.cCheckno    = m.cf2
                  m.cCheckDate  = m.cf3
                  m.cPropertyNo = m.cf4
                  m.cPropName   = m.cf5
                  m.cProdDate   = m.cf6
                  m.cProdType   = m.cf7
                  m.cIntType    = m.cf8
                  m.cownervol   = m.cf9
                  m.cowngross   = m.cf10
                  m.cowntax     = m.cf11
                  m.cowndeducts = m.cf12
                  m.cownnet     = m.cf13
                  m.csender     = m.cf14
                  INSERT INTO importtemp FROM MEMVAR
               ENDSCAN
            ELSE
               EXIT
            ENDIF
         ELSE
            SELECT importtemp
            APPEND FROM (lcFileName) TYPE CSV
         ENDIF

         SELECT importfile
         SCATTER MEMVAR BLANK

         SELECT importtemp
         SCAN

            IF NOT ISDIGIT(SUBSTR(ALLTRIM(cLine), 1, 1))
               LOOP
            ENDIF

            SCATTER MEMVAR

            m.cWellID     = m.cPropertyNo
            m.cWellname   = m.cPropName

            m.cownervol   = STRTRAN(m.cownervol, '$', '')
            m.cownervol   = STRTRAN(m.cownervol, ',', '')
            m.cowngross   = STRTRAN(m.cowngross, '$', '')
            m.cowngross   = STRTRAN(m.cowngross, ',', '')
            m.cowntax     = STRTRAN(m.cowntax, '$', '')
            m.cowntax     = STRTRAN(m.cowntax, ',', '')
            m.cowndeducts = STRTRAN(m.cowndeducts, '$', '')
            m.cowndeducts = STRTRAN(m.cowndeducts, ',', '')
            m.cownnet     = STRTRAN(m.cownnet, '$', '')
            m.cownnet     = STRTRAN(m.cownnet, ',', '')
            m.iLine       = INT(VAL(m.cLine))
            m.dCheckDate  = CTOD(m.cCheckDate)
            m.dProdDate   = CTOD(m.cProdDate)
            m.dPostDate   = m.dCheckDate
            m.cDedCode    = 'LO'

            IF '(' $ m.cownnet
               m.cownnet = STRTRAN(m.cownnet, '(', '')
               m.cownnet = STRTRAN(m.cownnet, ')', '')
               m.nNet = VAL(m.cownnet) * -1
            ELSE
               m.nNet = VAL(m.cownnet)
            ENDIF
            IF '(' $ m.cownervol
               m.cownervol = STRTRAN(m.cownervol, '(', '')
               m.cownervol = STRTRAN(m.cownervol, ')', '')
               m.nUnits = VAL(m.cownervol) * -1
            ELSE
               m.nUnits   = VAL(m.cownervol)
            ENDIF

            IF '(' $ m.cowngross
               m.cowngross = STRTRAN(m.cowngross, '(', '')
               m.cowngross = STRTRAN(m.cowngross, ')', '')
               m.nTotalInc = VAL(m.cowngross) * -1
            ELSE
               m.nTotalInc   = VAL(m.cowngross)
            ENDIF

            IF '(' $ m.cowntax
               m.cowntax = STRTRAN(m.cowntax, '(', '')
               m.cowntax = STRTRAN(m.cowntax, ')', '')
               m.nTax = VAL(m.cowntax) * -1
            ELSE
               m.nTax     = VAL(m.cowntax)
            ENDIF

            IF '(' $ m.cowndeducts
               m.cowndeducts = STRTRAN(m.cowndeducts, '(', '')
               m.cowndeducts = STRTRAN(m.cowndeducts, ')', '')
               m.nDeducts = VAL(m.cowndeducts) * -1
            ELSE
               m.nDeducts = VAL(m.cowndeducts)
            ENDIF

            INSERT INTO importfile FROM MEMVAR
         ENDSCAN

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'ImportCSV', loError.LINENO, 'swFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to import the CSV file at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn


      ************************
   PROCEDURE ImportMap
      ************************
      LPARAMETERS lcFileName, lcMapName, lcType, lnDataSession
      LOCAL lnDefMax, llXLSX

      llXLSX        = .F.
      THIS.cType    = lcType
      THIS.cMapName = lcMapName

      IF EMPTY(lcFileName)
         MESSAGEBOX('Invalid or blank file name sent to IMPORTCSV', 0, 'Invalid File')
         RETURN .F.
      ENDIF

      IF 'XLS' $ UPPER(JUSTEXT(lcFileName))
         llXLSX = .T.
      ENDIF

      THIS.lXLSX = llXLSX

      llReturn = .T.

      TRY

         IF VARTYPE(lnDataSession) = 'N'
            SET DATASESSION TO lnDataSession
         ENDIF

         CREATE CURSOR importtemp ;
            (cf1              V(254), ;
            cf2              V(254), ;
            cf3              V(254), ;
            cf4              V(254), ;
            cf5              V(254), ;
            cf6              V(254), ;
            cf7              V(254), ;
            cf8              V(254), ;
            cf9              V(254), ;
            cf10             V(254), ;
            cf11             V(254), ;
            cf12             V(254), ;
            cf13             V(254), ;
            cf14             V(254), ;
            cf15             V(254), ;
            cf16             V(254), ;
            cf17             V(254), ;
            cf18             V(254), ;
            cf19             V(254), ;
            cf20             V(254), ;
            cf21             V(254), ;
            cf22             V(254), ;
            cf23             V(254), ;
            cf24             V(254), ;
            cf25             V(254), ;
            cf26             V(254), ;
            cf27             V(254), ;
            cf28             V(254), ;
            cf29             V(254), ;
            cf30             V(254), ;
            cf31             V(254), ;
            cf32             V(254), ;
            cf33             V(254), ;
            cf34             V(254), ;
            cf35             V(254), ;
            cf36             V(254), ;
            cf37             V(254), ;
            cf38             V(254), ;
            cf39             V(254), ;
            cf40             V(254), ;
            cf41             V(254), ;
            cf42             V(254), ;
            cf43             V(254), ;
            cf44             V(254), ;
            cf45             V(254), ;
            cf46             V(254), ;
            cf47             V(254), ;
            cf48             V(254), ;
            cf49             V(254), ;
            cf50             V(254), ;
            cf51             V(254), ;
            cf52             V(254), ;
            cf53             V(254), ;
            cf54             V(254), ;
            cf55             V(254), ;
            cf56             V(254), ;
            cf57             V(254), ;
            cf58             V(254), ;
            cf59             V(254), ;
            cf60             V(254), ;
            iRow             I)

         CREATE CURSOR my_map ;
            (cm1                 C(20), ;
            cm2              C(20), ;
            cm3              C(20), ;
            cm4              C(20), ;
            cm5              C(20), ;
            cm6              C(20), ;
            cm7              C(20), ;
            cm8              C(20), ;
            cm9              C(20), ;
            cm10             C(20), ;
            cm11             C(20), ;
            cm12             C(20), ;
            cm13             C(20), ;
            cm14             C(20), ;
            cm15             C(20), ;
            cm16             C(20), ;
            cm17             C(20), ;
            cm18             C(20), ;
            cm19             C(20), ;
            cm20             C(20), ;
            cm21             C(20), ;
            cm22             C(20), ;
            cm23             C(20), ;
            cm24             C(20), ;
            cm25             C(20), ;
            cm26             C(20), ;
            cm27             C(20), ;
            cm28             C(20), ;
            cm29             C(20), ;
            cm30             C(20), ;
            cm31             C(20), ;
            cm32             C(20), ;
            cm33             C(20), ;
            cm34             C(20), ;
            cm35             C(20), ;
            cm36             C(20), ;
            cm37             C(20), ;
            cm38             C(20), ;
            cm39             C(20), ;
            cm40             C(20), ;
            cm41             C(20), ;
            cm42             C(20), ;
            cm43             C(20), ;
            cm44             C(20), ;
            cm45             C(20), ;
            cm46             C(20), ;
            cm47             C(20), ;
            cm48             C(20), ;
            cm49             C(20), ;
            cm50             C(20), ;
            cm51             C(20), ;
            cm52             C(20), ;
            cm53             C(20), ;
            cm54             C(20), ;
            cm55             C(20), ;
            cm56             C(20), ;
            cm57             C(20), ;
            cm58             C(20), ;
            cm59             C(20), ;
            cm60             C(20))

         DO CASE
            CASE lcType = 'REV'
               THIS.CreateRevFile()

            CASE lcType = 'EXP'
               THIS.CreateExpFile()

            CASE lcType = 'COA'  && COA
               THIS.CreateCOAFile()

            CASE lcType = 'GL'  && G/L Entries
               THIS.CreateGLFile()

            CASE lcType = 'WELL'  && Wells
               THIS.CreateWellFile()

            CASE lcType = 'OWN'  && Owners
               THIS.CreateOwnerFile()

            CASE lcType = 'DOI'  && DOI
               THIS.CreateDOIFile()

            CASE lcType = 'VEND'  && Vendors
               THIS.CreateVendFile()

            CASE lcType = 'CUST'  && Customers
               THIS.CreateCustFile()

            CASE lcType = 'ECAT'  && Expense Codes
               THIS.CreateECatFile()

            CASE lcType = 'PURCH'  && Purchasers
               THIS.CreatePurchFile()

            CASE lcType = 'LSE'  && Land Records
               THIS.CreateLandFile()

            CASE lcType = 'LO'  && Lease Obligations
               THIS.CreateLandOwnerFile()

            CASE lcType = 'METER'  && Master Meters
               THIS.CreateMeterFile()

         CASE lcType = 'PRG'  && Program Units
            THIS.CreateUnitsFile()
	    
          CASE lcType = 'PUMP'  && Pumpers
               THIS.CreatePumperFile()   
         ENDCASE

         TRY
         IF llXLSX
            llReturn =  THIS.getworksheet(lcFileName)
            IF llReturn
               SELECT worksheettemp
               SCAN
                  SCATTER MEMVAR
                  INSERT INTO importtemp FROM MEMVAR
               ENDSCAN
            ELSE
               EXIT
            ENDIF
         ELSE
            SELECT importtemp
            APPEND FROM (lcFileName) TYPE CSV
         ENDIF
         CATCH TO loError
            IF loError.ERRORNO = 1190
               MESSAGEBOX('The file being imported is too large. Files larger than 2 GB cannot ' + ;
                    'be imported at one time. Split the file and do two separater imports.', 64, 'Import File Too Large')
            ELSE
               MESSAGEBOX('There was a problem importing this file. Check to make sure it is ' + ;
                    'either an XLSX or CSV file and try again.', 64, 'Import File Problem')
            ENDIF
         ENDTRY

         STORE '' TO m.cm1, m.cm2, m.cm3, m.cm4, m.cm5, m.cm6
         STORE '' TO m.cm7, m.cm8, m.cm9, m.cm10, m.cm11, m.cm12
         STORE '' TO m.cm13, m.cm14, m.cm15, m.cm16, m.cm17, m.cm18
         STORE '' TO m.cm19, m.cm20, m.cm21, m.cm22, m.cm23, m.cm24
         STORE '' TO m.cm25, m.cm26, m.cm27, m.cm28, m.cm29, m.cm30
         STORE '' TO m.cm31, m.cm32, m.cm33, m.cm34, m.cm35, m.cm36, m.cm37
         STORE '' TO m.cm38, m.cm39, m.cm40, m.cm41, m.cm42, m.cm42, m.cm43
         STORE '' TO m.cm44, m.cm45, m.cm46, m.cm47, m.cm48, m.cm49, m.cm49
         STORE '' TO m.cm50, m.cm51, m.cm52, m.cm53, m.cm54, m.cm55, m.cm56, m.cm57
         STORE {} TO m.dduedate, m.dinvdate, m.dProdDate
         STORE '' TO m.crectype, m.cCheckno, m.cCheckDate, m.cPropNo
         STORE '' TO m.cPropName, m.cPropState, m.cPropCounty, m.cProdDate, m.cProdType
         STORE '' TO m.cIntType, m.cPrice, m.cgrossvol, m.cGrossVal, m.cgrosstax1, m.cgrosstax2, m.cgrosstax3, m.cgrosstax4, m.cownroychg
         STORE '' TO m.cgrossnet, m.cInterest, m.cintpaid, m.cowngross, m.cowntax1, m.cowntax2, m.cowntax3, m.cowntax4, m.cownnet, m.cbtufact
         STORE '' TO m.cowndeducts1, m.cAdjCode, m.cUnused, m.cWithhold1, m.cWithhold2, m.cWithhold3, m.cWithhold4, m.cCheckAmt
         STORE '' TO m.cowndeducts1, m.cowndeducts2, m.cowndeducts3, m.cowndeducts4, m.cgrossdeducts1, m.cgrossdeducts2, m.cgrossdeducts3
         STORE '' TO m.cgrossdeducts4, m.cnetvol, m.cPrice, m.cinvdate, m.cduedate, m.cinvnum, m.cInterest
         STORE '' TO m.cExpCode1, m.cExpCode2, m.cExpCode3, m.cExpCode4, m.cExpCode5, m.cExpCode6
         STORE '' TO m.cExpDesc1, m.cExpDesc2, m.cExpDesc3, m.cExpDesc4, m.cExpDesc5, m.cExpDesc6
         STORE '' TO m.cgrossval1, m.cgrossval2, m.cgrossval3, m.cgrossval4, m.cgrossval5, m.cgrossval6
         STORE '' TO m.cownernet1, m.cownernet2, m.cownernet3, m.cownernet4, m.cownernet5, m.cownernet6

         SELECT importfile
         SCATTER MEMVAR BLANK

         DO CASE
            CASE lcType = 'REV'
               THIS.BuildImportFileRev()

            CASE lcType = 'EXP'
               THIS.BuildImportFileExp()

            CASE lcType = 'WELL'
               THIS.BuildWells()

            CASE lcType = 'OWN'
               THIS.BuildOwners()

            CASE lcType = 'DOI'
               THIS.BuildDOI()

            CASE lcType = 'COA'
               THIS.BuildCOA()

            CASE lcType = 'GL'
               THIS.BuildJournal()

            CASE lcType = 'CUST'
               THIS.BuildCusts()

            CASE lcType = 'VEND'
               THIS.BuildVendors()

            CASE lcType = 'ECAT'
               THIS.BuildExpCodes()

            CASE lcType = 'PURCH'
               THIS.BuildPurchasers()

            CASE lcType = 'LSE'
               THIS.BuildLand()

            CASE lcType = 'LO'
               THIS.BuildLandOwner()

            CASE lcType = 'METER'
               THIS.BuildMeters()
         CASE lcType = 'PRG'
            THIS.BuildUnits()   
	    
	 CASE lcType = 'PUMP'  
               THIS.BuildPumpers()   
   

         ENDCASE

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'ImportMap', loError.LINENO, 'swFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to import the mapped file at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      SELECT importfile
      COUNT FOR NOT DELETED() TO lnCount

      IF lnCount = 0
         MESSAGEBOX('Nothing imported. Check the import map to make sure it is correct for the CSV file being imported.', 48, 'Import Failure')
         RETURN .F.
      ENDIF

      RETURN llReturn


      ************************
   PROCEDURE ProcessMap
      ************************
      LPARAMETERS lcMapName, ;
         lcID, ;
         lcCashAcct, ;
         ldDateToUse, ;
         llNoQBPost
      LOCAL llReturn, loError
      LOCAL lPostToQB, lcMessage, lcMessage2, lnBadRecs, lnTotal, lnTotalcks, lnDeducts
      LOCAL cBatch, cOwnType, cProdYear, cType, ccashacct, cDesc, cleasename, cname, copername
      LOCAL cProdPeriod, ddate, dentdate, ileasespk, ioperatorpk, nNetUnits, nprice
      LOCAL lcRevClear, lcExpClear

      lnBadRecs = 0
      llReturn  = .T.
      STORE '' TO m.cProdPeriod, m.cProdYear

      TRY

         swselect('glopt')
         GO TOP
         lcRevClear = cRevClear
         lcExpClear = cExpClear
         m.lnoqbpost = llNoQBPost
         STORE '' TO lcMessage2, m.ccashacct, m.cType
         llUseDate = VARTYPE(ldDateToUse) = 'D'

         * Check to see if the operator assumes that deducts are negative
         * If the operator does assume we need to multiply by -1 otherwise
         * just by 1.
         swselect('ImportMap')
         LOCATE FOR cType = 'REV' AND cImportName = ALLTRIM(lcMapName)
         IF FOUND()
            IF ImportMap.ldeducts
               lnDeducts = 1
            ELSE
               lnDeducts = -1
            ENDIF
         ELSE
            lnDeducts = -1
         ENDIF

         * Create cursor for bad detail lines
         CREATE CURSOR baddetail ;
            (cWellID    C(20), ;
            cWellname  C(40), ;
            cprodcode  C(7), ;
            cCheckno   C(14), ;
            cDesc      C(40))

         * Create cursors for all the revenue and adjustment codes
         llReturn = THIS.BuildCodes()

         m.cUser		   = m.goapp.cUser
         m.dlastmodified = DATETIME()

         * Fill in check date if missing
         IF llUseDate = .T.
            SELECT importfile
            REPLACE dCheckDate WITH ldDateToUse, ;
               dPostDate  WITH ldDateToUse  ALL
         ELSE
            SELECT importfile
            LOCATE FOR NOT EMPTY(dCheckDate)
            IF NOT FOUND()
               MESSAGEBOX('There was not a check date column in the import and the option to use the ' + ;
                  'shown date instead of the check date was not chosen. Please correct.', 64, 'Missing Checkdate')
               llReturn = .F.
               EXIT
            ENDIF
         ENDIF

         SELECT importfile
         REPLACE dPostDate WITH dCheckDate FOR EMPTY(dPostDate)
         REPLACE cCheckno WITH DTOC(dCheckDate) FOR EMPTY(cCheckno)

         * Get a total for each check in the import
         SELECT  cCheckno,;
            dCheckDate,;
            dPostDate,;
            SPACE(8) AS cBatch,;
            SUM(nTotalInc - nTax - nDeducts) AS nCashAmt ;
            FROM importfile ;
            WHERE NOT EMPTY(dCheckDate) ;
            AND NOT EMPTY(cWellID) ;
            INTO CURSOR curNewChecks READWRITE ;
            ORDER BY cCheckno, dCheckDate, dPostDate ;
            GROUP BY cCheckno, dCheckDate, dPostDate

         IF _TALLY = 0
            llReturn = .F.
            MESSAGEBOX('No valid records found in the import.', 16, 'No Records')
            EXIT
         ENDIF

         SELECT curNewChecks
         SCAN
            SCATTER MEMVAR

            m.ccashacct = lcCashAcct
            m.cBatch    = m.goapp.oRegistry.IncrementCounter('%Shared.Counters.Batch')
            lcBatch     = m.cBatch

            SELECT curNewChecks
            REPLACE cBatch WITH lcBatch

            IF llUseDate
               m.ddate    = ldDateToUse
            ELSE
               m.ddate    = m.dCheckDate
            ENDIF

            IF EMPTY(m.dPostDate)
               m.dPostDate = m.ddate
            ENDIF

            m.dentdate = DATE()

            IF VARTYPE(m.ddate) # 'D'
               MESSAGEBOX('An invalid date was found in the import. Using todays date instead. Correct in Production Receipts after this import.', 16, 'Bad Date')
               m.ddate = DATE()
            ENDIF
            IF NOT BETWEEN(m.ddate, {01/01/1980}, {12/31/2030})
               MESSAGEBOX('An invalid date was found in the import. Using todays date instead. Correct in Production Receipts after this import.', 16, 'Bad Date')
               m.ddate = DATE()
            ENDIF

            m.cid = lcID
            swselect('revsrc')
            SET ORDER TO crevkey
            IF SEEK(lcID)
               m.cname = crevname
            ELSE
               m.cname = 'Unknown'
            ENDIF
            m.cBatch = lcBatch
            INSERT INTO csrcthdr FROM MEMVAR

            lcLastProdType = ''
            m.lWellRcpt	 = .F.
            SELECT importfile
            SCAN FOR cCheckno = m.cCheckno AND dPostDate = m.dPostDate
               SCATTER MEMVAR
               m.cProdType   = UPPER(ALLTRIM(m.cProdType))
               m.cWellID	   = PADR(ALLTRIM(UPPER(m.cWellID)), 20, ' ')
               IF NOT EMPTY(m.cProdPeriod)
                  m.cProdPeriod = PADL(ALLTRIM(m.cProdPeriod), 2, '0')
               ENDIF
               m.namount	   = m.nTotalInc

               IF NOT EMPTY(m.cWellID)
                  swselect('wells')
                  LOCATE FOR (cPropNo == m.cWellID) OR ;
                     (coilpurchno == m.cWellID) OR ;
                     (cgaspurchno == m.cWellID) OR ;
                     (cothpurchno == m.cWellID) OR ;
                     (cWellID == LEFT(m.cWellID, 10))
                  IF FOUND()
                     m.cWellname = cWellname
                     m.cDesc	   = m.cWellname
                     m.cAcctNo   = lcRevClear
                     m.cWellID   = cWellID
                     m.lWellRcpt = .T.
                     IF wells.cWellID # ALLTRIM(m.cWellID)
                        m.cWellID = wells.cWellID
                     ENDIF

                     swselect('revcat')
                     LOCATE FOR crevtype = PADR(ALLTRIM(m.cProdType), 5, ' ')
                     IF NOT FOUND()
                        swselect('expcat')
                        LOCATE FOR UPPER(ccatcode) = PADR(ALLTRIM(m.cProdType), 4, ' ')
                        IF FOUND()
                           m.cType   = ccatcode
                           m.cAcctNo = lcExpClear
                        ELSE
                           SELECT gastypes
                           LOCATE FOR UPPER(ccode) = m.cProdType
                           IF FOUND()
                              m.cType		= 'MCF'
                              m.cProdType	= m.cType
                              m.cAcctNo	= lcRevClear
                           ELSE
                              SELECT oiltypes
                              LOCATE FOR UPPER(ccode) = m.cProdType
                              IF FOUND()
                                 m.cType	   = 'BBL'
                                 m.cProdType = m.cType
                                 m.cAcctNo   = lcRevClear
                              ELSE
                                 SELECT othtypes
                                 LOCATE FOR UPPER(ccode) = m.cProdType
                                 IF FOUND()
                                    m.cType	  = 'OTH'
                                    m.cProdType = m.cType
                                    m.cAcctNo	  = lcRevClear
                                 ELSE
                                    SELECT gtaxtypes
                                    LOCATE FOR UPPER(ccode) = m.cProdType
                                    IF FOUND()
                                       m.cType	 = 'GTAX1'
                                       m.cProdType = m.cType
                                       m.cAcctNo	 = lcRevClear
                                    ELSE
                                       SELECT otaxtypes
                                       LOCATE FOR UPPER(ccode) = m.cProdType
                                       IF FOUND()
                                          m.cType		= 'OTAX1'
                                          m.cProdType	= m.cType
                                          m.cAcctNo	= lcRevClear
                                       ELSE
                                          SELECT ptaxtypes
                                          LOCATE FOR UPPER(ccode) = m.cProdType
                                          IF FOUND()
                                             m.cType	   = 'PTAX1'
                                             m.cProdType = m.cType
                                             m.cAcctNo   = lcRevClear
                                          ELSE
                                             IF m.nTotalInc # 0
                                                MESSAGEBOX('An invalid revenue code was found in the import. The code found is: ' + CHR(10) + CHR(10) + ;
                                                   m.cProdType + CHR(10) + CHR(10) + ;
                                                   'Please add this code to the appropriate revenue type in the import ' + ;
                                                   'code mapping and then try the import again.', 16, 'Invalid Revenue Code')
                                                llReturn = .F.
                                                EXIT
                                             ENDIF
                                          ENDIF
                                       ENDIF
                                    ENDIF
                                 ENDIF
                              ENDIF
                           ENDIF
                        ENDIF
                     ELSE
                        m.cAcctNo	  = lcRevClear
                        m.cType	  = ALLTRIM(m.cProdType)
                        m.lWellRcpt = .F.
                     ENDIF
                  ELSE
                     m.cprodcode = m.cType
                     m.cDesc	   = 'Property No: ' + ALLTRIM(m.cWellID) + ' was not found.'
                     INSERT INTO baddetail FROM MEMVAR
                     lnBadRecs = lnBadRecs + 1
                  ENDIF

                  IF NOT llReturn
                     EXIT
                  ENDIF

                  IF EMPTY(m.cProdYear) AND NOT EMPTY(m.dProdDate)
                     m.cProdYear	 = TRANSFORM(YEAR(m.dProdDate))
                     m.cProdPeriod = PADL(TRANSFORM(MONTH(m.dProdDate)), 2, '0')
                  ENDIF

                  IF 'TAX' $ m.cType
                     m.nprice	= 0
                     m.nUnits	= 0
                  ELSE
                     IF m.nprice = 0
                        IF m.nUnits <> 0
                           m.nprice    = m.nTotalInc / m.nUnits
                        ELSE
                           m.nprice = 0
                        ENDIF
                     ENDIF
                  ENDIF

                  IF NOT EMPTY(m.cDesc) AND m.namount # 0
                     m.cidRctD   = GetNextPK('CSRCTDET')
                     m.lWellRcpt = .T.
                     m.cBatch = lcBatch
                     INSERT INTO csrctdet FROM MEMVAR
                  ENDIF

                  IF m.nTax # 0
                     m.namount = m.nTax * -1
                     m.cType	 = '**'
                     IF NOT EMPTY(m.cTaxType)
                        SELECT otaxtypes
                        LOCATE FOR UPPER(ccode) = m.cProdType
                        IF FOUND()
                           m.cType   = 'OTAX1'
                           m.cAcctNo = lcRevClear
                        ELSE
                           SELECT gtaxtypes
                           LOCATE FOR UPPER(ccode) = m.cProdType
                           IF FOUND()
                              m.cType	  = 'GTAX1'
                              m.cAcctNo = lcRevClear
                           ELSE
                              SELECT ptaxtypes
                              LOCATE FOR UPPER(ccode) = m.cProdType
                              IF FOUND()
                                 m.cType	 = 'PTAX1'
                                 m.cAcctNo = lcRevClear
                              ELSE
                                 SELECT revcat
                                 LOCATE FOR UPPER(crevtype) = ALLTRIM(m.cTaxType)
                                 IF FOUND()
                                    m.cType	= crevtype
                                    m.cAcctNo	= lcRevClear
                                 ELSE
                                    m.cprodcode = m.cTaxType
                                    m.cDesc	  = 'Tax Type: ' + ALLTRIM(m.cTaxType) + ' not valid.'
                                    INSERT INTO baddetail FROM MEMVAR
                                    lnBadRecs = lnBadRecs + 1
                                 ENDIF
                              ENDIF
                           ENDIF
                        ENDIF
                     ELSE
                        DO CASE
                           CASE m.cProdType = 'BBL'
                              m.cType = 'OTAX1'
                           CASE m.cProdType = 'MCF'
                              m.cType = 'GTAX1'
                           CASE m.cProdType = 'OTH'
                              m.cType = 'PTAX1'
                           OTHERWISE
                              m.cType = 'GTAX4'
                        ENDCASE
                     ENDIF
                     IF m.cType # '**'
                        m.cidRctD	  = GetNextPK('CSRCTDET')
                        m.lWellRcpt = .T.
                        STORE 0 TO m.nprice, m.nUnits
                        m.cBatch = lcBatch
                        INSERT INTO csrctdet FROM MEMVAR
                     ENDIF
                  ENDIF

                  IF m.nDeducts # 0
                     m.namount   = m.nDeducts * -1
                     m.cidRctD   = GetNextPK('CSRCTDET')
                     m.lWellRcpt = .T.
                     IF NOT EMPTY(m.cDedCode)
                        swselect('expcat')
                        LOCATE FOR ccatcode = ALLTRIM(m.cDedCode)
                        IF FOUND()
                           m.cAcctNo = lcExpClear
                           m.cType   = ALLTRIM(m.cDedCode)
                           STORE 0 TO m.nprice, m.nUnits
                           m.cBatch = lcBatch
                           INSERT INTO csrctdet FROM MEMVAR
                        ELSE
                           swselect('importtypes')
                           LOCATE FOR ALLTRIM(UPPER(m.cDedCode)) $ mtypes
                           IF FOUND()
                              m.cType	  = cType
                              m.cAcctNo = lcExpClear
                              STORE 0 TO m.nprice, m.nUnits
                              swselect('expcat')
                              LOCATE FOR ccatcode = ALLTRIM(m.cType)
                              IF FOUND()
                                 m.cAcctNo = lcExpClear
                                 STORE 0 TO m.nprice, m.nUnits
                                 m.cBatch = lcBatch
                                 INSERT INTO csrctdet FROM MEMVAR
                              ELSE
                                 SELECT revcat
                                 LOCATE FOR crevtype = ALLTRIM(m.cType)
                                 IF FOUND()
                                    m.cAcctNo = lcRevClear
                                    STORE 0 TO m.nprice, m.nUnits
                                    m.cBatch = lcBatch
                                    INSERT INTO csrctdet FROM MEMVAR
                                 ELSE
                                    m.cprodcode = m.cType
                                    m.cDesc	   = 'Deduction Code: ' + ALLTRIM(m.cType) + ' not valid.'
                                    INSERT INTO baddetail FROM MEMVAR
                                    lnBadRecs = lnBadRecs + 1
                                 ENDIF
                              ENDIF
                           ELSE
                              m.cprodcode	= m.cDedCode
                              m.cDesc		= 'Deduction Code: ' + ALLTRIM(m.cDedCode) + ' not valid.'
                              INSERT INTO baddetail FROM MEMVAR
                              lnBadRecs = lnBadRecs + 1
                           ENDIF
                        ENDIF
                     ELSE
                        swselect('importtypes')
                        LOCATE FOR 'OD' $ mtypes
                        IF FOUND()
                           m.cType   = cType
                           m.cAcctNo = lcExpClear
                           STORE 0 TO m.nprice, m.nUnits
                           swselect('expcat')
                           LOCATE FOR ccatcode = ALLTRIM(m.cType)
                           IF FOUND()
                              m.cAcctNo = lcExpClear
                              STORE 0 TO m.nprice, m.nUnits
                              m.cBatch = lcBatch
                              INSERT INTO csrctdet FROM MEMVAR
                           ELSE
                              m.cprodcode	= m.cType
                              m.cDesc		= 'Deduction Code: ' + ALLTRIM(m.cType) + ' not valid.'
                              INSERT INTO baddetail FROM MEMVAR
                              lnBadRecs = lnBadRecs + 1
                           ENDIF
                        ELSE
                           m.cprodcode = m.cDedCode
                           m.cDesc	 = 'Deduction Code: ' + ALLTRIM(m.cDedCode) + ' not valid.'
                           INSERT INTO baddetail FROM MEMVAR
                           lnBadRecs = lnBadRecs + 1
                        ENDIF
                     ENDIF
                  ENDIF
               ELSE
                  IF NOT EMPTY(m.cDesc) AND m.namount # 0
                     m.cidRctD   = GetNextPK('CSRCTDET')
                     m.lWellRcpt = .F.
                     m.cBatch = lcBatch
                     INSERT INTO csrctdet FROM MEMVAR
                  ENDIF
               ENDIF
            ENDSCAN && importfile
         ENDSCAN &&cshdr

         * Inform about any recs that couldn't be imported
         IF lnBadRecs > 0
            lcMessage = "There were " + TRANSFORM(lnBadRecs) + " detail lines that could not be imported." + CHR(10) + ;
               "The wells that couldn't be imported: " + CHR(10)

            SELECT cCheckno, cWellID FROM baddetail INTO CURSOR temp ORDER BY cWellID, cCheckno GROUP BY cWellID, cCheckno
            SELECT temp
            SCAN
               SCATTER MEMVAR
               lcMessage2 = lcMessage2 + 'Property: ' + m.cWellID + ' Check No: ' + m.cCheckno + CHR(10)
            ENDSCAN
            MESSAGEBOX(lcMessage + lcMessage2, 48, 'Import Problems')
            IF MESSAGEBOX('Do you want to print this list of import problems?', 36, 'Import Problems') = 6
               SELECT cCheckno, cWellname, cprodcode, cWellID, cDesc FROM baddetail INTO CURSOR temp ORDER BY cWellID, cCheckno GROUP BY cWellID, cprodcode, cCheckno, cDesc
               REPORT FORM baddetail TO PRINTER PROMPT PREVIEW
            ENDIF
            IF MESSAGEBOX('Do you want to continue the import?', 36, 'Continue Import') = 7
               llReturn = .F.
            ENDIF
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'ProcessCSV', loError.LINENO, 'Import Revenue', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn

      ************************
   PROCEDURE ImportCDEX
      ************************
      PARAMETERS lcFileName, lcType, lnDataSessionID

      IF EMPTY(lcFileName)
         MESSAGEBOX('Invalid or blank file name sent to IMPORTCDEX', 0, 'Invalid File')
         RETURN .F.
      ENDIF

      IF VARTYPE(lnDataSessionID) = 'N'
         SET DATASESSION TO lnDataSessionID
      ENDIF

      IF USED('CDEXData')
         USE IN CDEXData
      ENDIF

      TRY

         *  Create temp cursor to hold imported data
         CREATE CURSOR importfile ;
            (cCompCode       C(2), ;
            cCheckno       C(12), ;
            cPropName      C(30), ;
            cWellID        C(14), ;
            cProdDate1     C(4), ;
            cProdDate2     C(4), ;
            cprodcode      C(5), ;
            cTranCode1     C(2), ;
            nLeaseGrossVol N(12, 2), ;
            nLeaseGrossTax N(12, 2), ;
            nLeaseNet      N(12, 2), ;
            nownnet        N(12, 2), ;
            cTranCode2     C(2), ;
            nLeaseGross    N(12, 2), ;
            nownnet2       N(12, 2), ;
            cTypeInv       C(1), ;
            nInterest      N(13, 7))

         CREATE CURSOR newwells ;
            (cCompCode      C(2), ;
            cPropNo       C(14), ;
            cPropName     C(40), ;
            copername     C(20), ;
            cstate        C(2), ;
            ccounty       C(3), ;
            nInterest     N(11, 7), ;
            cTypeInv      C(1), ;
            cdescription  C(37))

         fh = FOPEN(lcFileName)

         IF fh > 0
            = FSEEK(fh, 0, 0)

            DO WHILE (NOT FEOF(fh))

               lcdata = FGETS(fh)
               lnlen  = LEN(lcdata)

               IF lnlen < 5
                  LOOP
               ENDIF

               DO CASE
                  CASE LEFT(lcdata, 1) = '1'
                     *  Type 1 records are check detail records
                     * 1 - Record Type
                     * 2-3 - Company Code
                     * 4-15 - Check Number
                     * 16-29 - Unit/Property/Lease Code
                     * 30-33 - From Production Year/Prd - MMYY
                     * 34-37 - Production Date Year/Prd - MMYY
                     * 38-39 - Product Code - Here's the ones we care about...
                     *    05 - Combination of Products
                     *    10-13, 42 = BBL
                     *    20-23, 43-44 = MCF
                     *    30-36, 41 = OTH
                     * 40-41 - Transaction Code - 00 is always used in this field
                     * 42-53 - Lease Gross Volume - Implied decimal +/-XXXXXXXXX.XX
                     * 54-62 - Lease Gross Severance Tax - Implied decimal +/-XXXXXX.XX
                     * 63-74 - Lease Net Value - Implied decimal +/-XXXXXXXXX.XX
                     * 75-86 - Owner Share Net - Implied decimal +/-XXXXXXXXX.XX
                     * 87-88 - Transaction Code #2 - Anything but 00
                     *    01 = MMBTU Volume
                     *    02 = Royalty % & Value
                     *    03 = Conservation Tax
                     *    04 = School Tax
                     *    05 = State Withholding Tax
                     *    06 = State Non-Resident Tax
                     *    07 = Federal Non-Resident Tax
                     *    08 = Backup Withholding
                     *    10 = Unspecified Deduction/Reimbursement
                     *    11 = Federal Income Tax
                     *    12 = State Income Tax
                     *    13 = Mining Rights Tax
                     *    14 = Ad Valorem Tax
                     *    15 = Co-Owner Tax
                     *    16 = Tax Reimbursement
                     *    17 = Tax Credit for Gas
                     *    18 = Petroleum & Gas Fund
                     *    19 = Subsidence Abatement Fund
                     *    20 = Royalty Paid for Co-Owners
                     *    21 = Manual Accounting Entry
                     *    23 = Transportation
                     *    24 = Dehydration
                     *    25 = Gas Compression/Sweetening/Dehydration/Transportation
                     *    26 = WI Royalty Reimbursement
                     *    27 = WI Dehydration Reimbursement
                     *    28 = Purchased Gas Resold
                     *    29 = Deficiency and Pre-Paid Gas
                     *    30 = Interest Payment
                     *    31 = Joint-Venture Charges
                     *    43 = Transportation - Gas
                     *    44 = Dehydration - Gas
                     *    45 = Marketing
                     *    46 = Compression
                     *    47 = Gathering
                     *    48 = Processing/Sweetening
                     *    50 = Override
                     *    51 = Supplemental
                     *    52 = Overriding Royalty
                     *    53 = Royalty
                     *    54 = Net Proceeds
                     *    60 = OK SB 1048
                     *    61 = NM SB 0621
                     *    62 = Utah Withholding
                     *    63 = Montana State WH
                     *    64 = North Dakota WH
                     * 89-100 - Lease Gross Value of Charge/Reimbursement - Implied decimal +/-XXXXXXXXX.XX
                     * 101-112 - Owner Share of Charge/Reimbursement - Implied decimal +/-XXXXXXXXX.XX
                     * 113-115 - Transmission Date - Julian format
                     * 116 - Type of Interest
                     *    B = Blanchard
                     *    M = Miscellaneous
                     *    N = Net Profit Payment
                     *    O = Overriding
                     *    P = Production Payments
                     *    R = Royalty
                     *    S = Special Override
                     *    T = Tax
                     *    W = Working
                     *    X = Buy/Purchase
                     * 117 - Decimal Flag
                     * 118-126 - Decimal Interest X.XXXXXXXX - Implied decimal
                     * 127-130 - BTU Factor X.XXX - Implied decimal
                     * 131-132 - Blank - Future use

                     m.cCompCode      = SUBSTR(lcdata, 2, 2)
                     m.cCheckno       = SUBSTR(lcdata, 4, 12)
                     m.cWellID        = SUBSTR(lcdata, 16, 14)
                     m.cProdDate1     = SUBSTR(lcdata, 30, 4)
                     m.cProdDate2     = SUBSTR(lcdata, 34, 4)
                     m.cprodcode      = SUBSTR(lcdata, 38, 2)
                     m.cTranCode1     = SUBSTR(lcdata, 40, 2)
                     m.nLeaseGrossVol = SUBSTR(lcdata, 42, 12)
                     m.nLeaseGrossTax = SUBSTR(lcdata, 54, 9)
                     m.nLeaseNet      = SUBSTR(lcdata, 63, 12)
                     m.nownnet        = SUBSTR(lcdata, 75, 12)
                     m.cTranCode2     = SUBSTR(lcdata, 87, 2)
                     m.nLeaseGross    = SUBSTR(lcdata, 89, 12)
                     m.nownnet2       = SUBSTR(lcdata, 101, 12)
                     m.cTypeInv       = SUBSTR(lcdata, 116, 1)
                     m.nInterest      = SUBSTR(lcdata, 118, 9)

                     *  Now that all fields have been assigned, it's time to clean then up.

                     *  Strip leading zeroes from the check # field
                     DO WHILE LEFT(m.cCheckno, 1) = '0'
                        m.cCheckno = SUBSTR(m.cCheckno, 2)
                     ENDDO

                     *  Assign a valid revenue type
                     DO CASE
                        CASE INLIST(m.cprodcode, '10', '11', '12', '13', '42')
                           m.cprodcode = 'BBL'
                        CASE INLIST(m.cprodcode, '20', '21', '22', '23', '43', '44')
                           m.cprodcode = 'MCF'
                        CASE INLIST(m.cprodcode, '30', '31', '32', '33', '34', '35', '36', '41')
                           m.cprodcode = 'OTH'
                        OTHERWISE
                           *  Will hopefully never get here, but import it as MISC1
                           m.cprodcode = 'MISC1'
                     ENDCASE

                     IF m.cTranCode2 = '46'
                        m.cprodcode = 'COMP'
                     ENDIF
                     IF m.cTranCode2 = '47'
                        m.cprodcode = 'GATH'
                     ENDIF

                     *  Clean up interest types
                     DO CASE
                        CASE INLIST(m.cTypeInv, 'O', 'S')
                           m.cTypeInv = 'O'
                        CASE m.cTypeInv = 'R'
                           m.cTypeInv = 'R'
                        OTHERWISE
                           m.cTypeInv = 'W'
                     ENDCASE

                     *  Pass all numeric fields to convert them from character to num and format correctly
                     m.nLeaseGrossVol = THIS.ConvertToNum(m.nLeaseGrossVol, 2)
                     m.nLeaseGrossTax = THIS.ConvertToNum(m.nLeaseGrossTax, 2)
                     m.nLeaseNet      = THIS.ConvertToNum(m.nLeaseNet, 2)
                     m.nownnet        = THIS.ConvertToNum(m.nownnet, 2)
                     m.nLeaseGross    = THIS.ConvertToNum(m.nLeaseGross, 2)
                     m.nownnet2       = THIS.ConvertToNum(m.nownnet2, 2)
                     m.nInterest      = 100 * THIS.ConvertToNum(m.nInterest, 8)

                     IF m.nownnet # 0 OR m.nownnet2 # 0
                        INSERT INTO importfile FROM MEMVAR
                     ENDIF

                  CASE LEFT(lcdata, 1) = '7'
                     * Record type 7 is new wells
                     m.cCompCode = SUBSTR(lcdata, 2, 2)
                     m.cPropNo   = SUBSTR(lcdata, 4, 14)
                     m.cPropName = SUBSTR(lcdata, 18, 40)
                     m.copername = SUBSTR(lcdata, 58, 20)
                     m.cstate    = SUBSTR(lcdata, 78, 2)
                     m.ccounty   = SUBSTR(lcdata, 80, 3)
                     m.nInterest = 100 * THIS.ConvertToNum(SUBSTR(lcdata, 83, 9))
                     m.cTypeInv  = SUBSTR(lcdata, 92, 1)

                     INSERT INTO newwells FROM MEMVAR

               ENDCASE
            ENDDO
         ENDIF

         = FCLOSE(fh)
         llReturn = .T.

      CATCH
         = FCLOSE(fh)
         llReturn = .F.
      ENDTRY

      RETURN llReturn
      ***********************
   PROCEDURE exportcdex
      ***********************
      PARAMETERS lcRunYear, lnRunNo

      *  Uses an existing stub cursor to scan through, creating separate
      *  CDEX records for each owner, placing them into a CDEX folder.
      *  Has to have the run number passed, so it can create CDEX files with a unique
      *  name.  The stub cursor doesn't contain the run number and year, oddly enough.

      LOCAL lcFilePath, lcFile, lnTotal, lcOldOwnerID, lnLeaseGrossVolTot, lnLeaseGrossTaxTot
      LOCAL lnLeaseNetTot, lnOwnNetTot, lnLeaseGrossTot, lnOwnNet2Tot


      IF NOT USED('stub')
         MESSAGEBOX('Source file for CDEX export does not exist. Cannot continue.', 0, 'Invalid File')
         RETURN .F.
      ENDIF

      lcOldOwnerID = ''

      TRY

         STORE 0 TO lnTotal, lnCount

         SELECT stub
         SCAN
            SCATTER MEMVAR

            *  Owner ID has changed, so start a new file
            IF lcOldOwnerID # m.cid

               *  We've switched owners, so check to see if we've got
               *  a valid file handle (it won't be valid the first time through),
               *  and then create the type 2 and 3 summary records
               *  and close it before creating a new one
               IF TYPE('fh') = 'N'

                  R2RecType       = '2'
                  R2CompCode      = 'SW'
                  R2CheckNumber   = PADL(ALLTRIM(m.cCheckno), 12, '0')
                  R2RecCount      = THIS.ConvertToChar(lnCountO, 4, 0, .T.)
                  R2CheckTotal    = THIS.ConvertToChar(lnTotalO, 12, 2)
                  R2NetOut        = 'Y'  &&  We don't use this for anything
                  R2PaymentFlag   = 'C'
                  R2EffDate       = PADL(ALLTRIM(STR(MONTH(m.dCheckDate))), 2, '0') + PADL(ALLTRIM(STR(DAY(m.dCheckDate))), 2, '0')
                  R2LeaseGrossVol = THIS.ConvertToChar(lnLeaseGrossVolTot, 13, 2)
                  R2LeaseGrossTax = THIS.ConvertToChar(lnLeaseGrossTaxTot, 10, 2)
                  R2LeaseNet      = THIS.ConvertToChar(lnLeaseNetTot, 13, 2)
                  R2OwnNetTot     = THIS.ConvertToChar(lnOwnNetTot, 13, 2)
                  R2LeaseGross    = THIS.ConvertToChar(lnLeaseGrossTot, 13, 2)
                  R2OwnNet2       = THIS.ConvertToChar(lnOwnNet2Tot, 13, 2)
                  R2Date          = LEFT(ALLTRIM(SYS(1)), 3)
                  R2OwnerID       = PADL(ALLTRIM(m.cid), 12, '0')
                  R2Blank         = SPACE(5)
                  R2CRLF          = m.CRLF

                  THIS.FileIO(fh, R2RecType + R2CompCode + R2CheckNumber + R2RecCount + R2CheckTotal + R2NetOut)
                  THIS.FileIO(fh, R2PaymentFlag + R2EffDate + R2LeaseGrossVol + R2LeaseGrossTax + R2LeaseNet)
                  THIS.FileIO(fh, R2OwnNetTot + R2LeaseGross + R2OwnNet2 + R2Date + R2OwnerID + R2Blank + R2CRLF)


                  *  Now create the final 3 record, and we're done!
                  R3RecType    = '3'
                  R3CheckCount = '00001'  &&  In theory, this could be more than 1 from other places, but we'll only have 1
                  R3CheckTotal = THIS.ConvertToChar(lnTotalO, 14, 2)
                  R3Space      = SPACE(112)

                  THIS.FileIO(fh, R3RecType + R3CheckCount + R3CheckTotal + R3Space)

                  = FCLOSE(fh)
               ENDIF

               *  Reset all the running totals that get reset for each owner
               STORE 0 TO lnLeaseGrossVolTot, lnLeaseGrossTaxTot, lnLeaseNetTot
               STORE 0 TO lnOwnNetTot, lnLeaseGrossTot, lnOwnNet2Tot, lnCountO, lnTotalO

               *  Check to see if there is an existing CDEX file for this owner/run.
               *  If there is, delete it.

               IF NOT DIRECTORY(m.goapp.cDataFilePath + 'CDEX\')
                  MKDIR m.goapp.cDataFilePath + 'CDEX\'
               ENDIF

               lcFilePath = m.goapp.cDataFilePath + 'CDEX\'
               lcFile     = lcFilePath + ALLTRIM(lcRunYear) + PADL(ALLTRIM(STR(lnRunNo)), 3, '0') + ALLTRIM(m.cid) + '.DAT'


               IF FILE(lcFile)
                  ERASE lcFile
               ENDIF

               fh = FCREATE(lcFile)

               lcOldOwnerID = m.cid
            ENDIF

            m.CRLF = CHR(13) + CHR(10)

            R1RecType     = '1'
            R1CompCode    = 'SW'
            R1CheckNumber = PADL(ALLTRIM(m.cCheckno), 12, '0')
            R1WellID      = PADL(ALLTRIM(m.cWellID), 14, '0')
            R1FromDate    = CHRTRAN(m.cProdPrd, '/', '')
            R1ProdDate    = CHRTRAN(m.cProdPrd, '/', '')

            *  Now determine what types of revenue there may be
            DO CASE
               CASE m.cIncType = 'O'  &&  Oil Revenue Line
                  R1ProdCode      = '11'
                  R1TranCode1     = '00'
                  R1LeaseGrossVol = THIS.ConvertToChar(m.nUnits, 12, 2)
                  R1LeaseGrossTax = THIS.ConvertToChar(m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4, 9, 2)
                  R1LeaseNet      = THIS.ConvertToChar(m.nNetVal, 12, 2)

                  *  Official documentation says that the owner net is the owner's share after taxes,
                  *  but that doesn't makes sense for importing with a separate tax amount in the second
                  *  part of the record.  The total of both owner net amounts for the file should total
                  *  the check amount, which doesn't work for us if we're making this owner net be after taxes
                  R1OwnNet = THIS.ConvertToChar(m.nowngross, 12, 2)

                  *  There's no specific code for severance tax, so we're using "Conservation Tax" instead
                  R1TranCode2  = '03'
                  R1LeaseGross = THIS.ConvertToChar(m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4, 12, 2)
                  R1OwnNet2    = THIS.ConvertToChar(m.nowntax, 12, 2)
                  R1Date       = LEFT(ALLTRIM(SYS(1)), 3)
                  R1TypeInv    = IIF(LEFT(m.cIntType, 1) = 'L', 'R', LEFT(m.cIntType, 1))
                  R1Decimal    = '0'
                  R1Interest   = THIS.ConvertToChar(m.nInterest / 100, 9, 8, .T.)
                  R1BTUFactor  = '0000'  &&  Not used
                  R1Blank      = SPACE(2)
                  R1CRLF       = m.CRLF

                  *  Only write to the file if there's actually data for this type
                  IF m.nowngross # 0 OR m.nowntax # 0
                     THIS.FileIO(fh, R1RecType + R1CompCode + R1CheckNumber + R1WellID + R1FromDate + R1ProdDate)
                     THIS.FileIO(fh, R1ProdCode + R1TranCode1 + R1LeaseGrossVol + R1LeaseGrossTax + R1LeaseNet)
                     THIS.FileIO(fh, R1OwnNet + R1TranCode2 + R1LeaseGross + R1OwnNet2 + R1Date)
                     THIS.FileIO(fh, R1TypeInv + R1Decimal + R1Interest + R1BTUFactor + R1Blank + R1CRLF)

                     *  Update all the running totals that will be needed for the summary records
                     lnTotalO           = lnTotalO + m.nowngross - m.nowntax
                     lnLeaseGrossVolTot = lnLeaseGrossVolTot + m.nUnits
                     lnLeaseGrossTaxTot = lnLeaseGrossTaxTot + m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4
                     lnLeaseNetTot      = lnLeaseNetTot + m.nNetVal
                     lnOwnNetTot        = lnOwnNetTot + m.nowngross
                     lnLeaseGrossTot    = lnLeaseGrossTot - (m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4)
                     lnOwnNet2Tot       = lnOwnNet2Tot + m.nowntax

                     lnTotal  = lnTotal + m.nowngross - m.nowntax
                     lnCountO = lnCountO + 1
                     lnCount  = lnCount + 1
                  ENDIF


               CASE m.cIncType = 'G'  &&  Gas Revenue Line
                  R1ProdCode      = '22'
                  R1TranCode1     = '00'
                  R1LeaseGrossVol = THIS.ConvertToChar(m.nUnits, 12, 2)
                  R1LeaseGrossTax = THIS.ConvertToChar(m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4, 9, 2)
                  R1LeaseNet      = THIS.ConvertToChar(m.nNetVal, 12, 2)

                  *  Official documentation says that the owner net is the owner's share after taxes,
                  *  but that doesn't makes sense for importing with a separate tax amount in the second
                  *  part of the record.  The total of both owner net amounts for the file should total
                  *  the check amount, which doesn't work for us if we're making this owner net be after taxes
                  R1OwnNet = THIS.ConvertToChar(m.nowngross, 12, 2)

                  *  There's no specific code for severance tax, so we're using "Conservation Tax" instead
                  R1TranCode2  = '03'
                  R1LeaseGross = THIS.ConvertToChar(m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4, 12, 2)
                  R1OwnNet2    = THIS.ConvertToChar(m.nowntax, 12, 2)
                  R1Date       = LEFT(ALLTRIM(SYS(1)), 3)
                  R1TypeInv    = IIF(LEFT(m.cIntType, 1) = 'L', 'R', LEFT(m.cIntType, 1))
                  R1Decimal    = '0'
                  R1Interest   = THIS.ConvertToChar(m.nInterest / 100, 9, 8, .T.)
                  R1BTUFactor  = '0000'  &&  Not used
                  R1Blank      = SPACE(2)
                  R1CRLF       = m.CRLF

                  *  Only write to the file if there's actually data for this type
                  IF m.nowngross # 0 OR m.nowntax # 0
                     THIS.FileIO(fh, R1RecType + R1CompCode + R1CheckNumber + R1WellID + R1FromDate + R1ProdDate)
                     THIS.FileIO(fh, R1ProdCode + R1TranCode1 + R1LeaseGrossVol + R1LeaseGrossTax + R1LeaseNet)
                     THIS.FileIO(fh, R1OwnNet + R1TranCode2 + R1LeaseGross + R1OwnNet2 + R1Date)
                     THIS.FileIO(fh, R1TypeInv + R1Decimal + R1Interest + R1BTUFactor + R1Blank + R1CRLF)

                     *  Update all the running totals that will be needed for the summary records
                     lnTotalO           = lnTotalO + m.nowngross - m.nowntax
                     lnLeaseGrossVolTot = lnLeaseGrossVolTot + m.nUnits
                     lnLeaseGrossTaxTot = lnLeaseGrossTaxTot + m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4
                     lnLeaseNetTot      = lnLeaseNetTot + m.nNetVal
                     lnOwnNetTot        = lnOwnNetTot + m.nowngross
                     lnLeaseGrossTot    = lnLeaseGrossTot - (m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4)
                     lnOwnNet2Tot       = lnOwnNet2Tot + m.nowntax

                     lnTotal  = lnTotal + m.nowngross - m.nowntax
                     lnCountO = lnCountO + 1
                     lnCount  = lnCount + 1
                  ENDIF


               CASE INLIST(m.cIncType, '1', '2')  &&  Misc1/Misc2 Revenue
                  R1ProdCode      = '90'
                  R1TranCode1     = '00'
                  R1LeaseGrossVol = THIS.ConvertToChar(m.nUnits, 12, 2)
                  R1LeaseGrossTax = THIS.ConvertToChar(0, 9, 2)
                  R1LeaseNet      = THIS.ConvertToChar(m.nNetVal, 12, 2)

                  *  Official documentation says that the owner net is the owner's share after taxes,
                  *  but that doesn't makes sense for importing with a separate tax amount in the second
                  *  part of the record.  The total of both owner net amounts for the file should total
                  *  the check amount, which doesn't work for us if we're making this owner net be after taxes
                  R1OwnNet = THIS.ConvertToChar(m.nowngross, 12, 2)

                  R1TranCode2  = '10'
                  R1LeaseGross = THIS.ConvertToChar(0, 12, 2)
                  R1OwnNet2    = THIS.ConvertToChar(0, 12, 2)
                  R1Date       = LEFT(ALLTRIM(SYS(1)), 3)
                  R1TypeInv    = IIF(LEFT(m.cIntType, 1) = 'L', 'R', LEFT(m.cIntType, 1))
                  R1Decimal    = '0'
                  R1Interest   = THIS.ConvertToChar(m.nInterest / 100, 9, 8, .T.)
                  R1BTUFactor  = '0000'  &&  Not used
                  R1Blank      = SPACE(2)
                  R1CRLF       = m.CRLF

                  *  Only write to the file if there's actually data for this type
                  IF m.nowngross # 0 OR m.nowntax # 0
                     THIS.FileIO(fh, R1RecType + R1CompCode + R1CheckNumber + R1WellID + R1FromDate + R1ProdDate)
                     THIS.FileIO(fh, R1ProdCode + R1TranCode1 + R1LeaseGrossVol + R1LeaseGrossTax + R1LeaseNet)
                     THIS.FileIO(fh, R1OwnNet + R1TranCode2 + R1LeaseGross + R1OwnNet2 + R1Date)
                     THIS.FileIO(fh, R1TypeInv + R1Decimal + R1Interest + R1BTUFactor + R1Blank + R1CRLF)

                     *  Update all the running totals that will be needed for the summary records
                     lnTotalO           = lnTotalO + m.nowngross - m.nowntax
                     lnLeaseGrossVolTot = lnLeaseGrossVolTot + m.nUnits
                     lnLeaseGrossTaxTot = lnLeaseGrossTaxTot + m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4
                     lnLeaseNetTot      = lnLeaseNetTot + m.nNetVal
                     lnOwnNetTot        = lnOwnNetTot + m.nowngross
                     lnLeaseGrossTot    = lnLeaseGrossTot - (m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4)
                     lnOwnNet2Tot       = lnOwnNet2Tot + m.nowntax

                     lnTotal  = lnTotal + m.nowngross - m.nowntax
                     lnCountO = lnCountO + 1
                     lnCount  = lnCount + 1
                  ENDIF


               CASE m.cIncType = 'P'  &&  OTH Revenue
                  R1ProdCode      = '90'
                  R1TranCode1     = '00'
                  R1LeaseGrossVol = THIS.ConvertToChar(m.nUnits, 12, 2)
                  R1LeaseGrossTax = THIS.ConvertToChar(m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4, 9, 2)
                  R1LeaseNet      = THIS.ConvertToChar(m.nNetVal, 12, 2)

                  *  Official documentation says that the owner net is the owner's share after taxes,
                  *  but that doesn't makes sense for importing with a separate tax amount in the second
                  *  part of the record.  The total of both owner net amounts for the file should total
                  *  the check amount, which doesn't work for us if we're making this owner net be after taxes
                  R1OwnNet = THIS.ConvertToChar(m.nowngross, 12, 2)

                  *  There's no specific code for severance tax, so we're using "Conservation Tax" instead
                  R1TranCode2  = '03'
                  R1LeaseGross = THIS.ConvertToChar(m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4, 12, 2)
                  R1OwnNet2    = THIS.ConvertToChar(m.nowntax, 12, 2)
                  R1Date       = LEFT(ALLTRIM(SYS(1)), 3)
                  R1TypeInv    = IIF(LEFT(m.cIntType, 1) = 'L', 'R', LEFT(m.cIntType, 1))
                  R1Decimal    = '0'
                  R1Interest   = THIS.ConvertToChar(m.nInterest / 100, 9, 8, .T.)
                  R1BTUFactor  = '0000'  &&  Not used
                  R1Blank      = SPACE(2)
                  R1CRLF       = m.CRLF

                  *  Only write to the file if there's actually data for this type
                  IF m.nowngross # 0 OR m.nowntax # 0
                     THIS.FileIO(fh, R1RecType + R1CompCode + R1CheckNumber + R1WellID + R1FromDate + R1ProdDate)
                     THIS.FileIO(fh, R1ProdCode + R1TranCode1 + R1LeaseGrossVol + R1LeaseGrossTax + R1LeaseNet)
                     THIS.FileIO(fh, R1OwnNet + R1TranCode2 + R1LeaseGross + R1OwnNet2 + R1Date)
                     THIS.FileIO(fh, R1TypeInv + R1Decimal + R1Interest + R1BTUFactor + R1Blank + R1CRLF)

                     *  Update all the running totals that will be needed for the summary records
                     lnTotalO           = lnTotalO + m.nowngross - m.nowntax
                     lnLeaseGrossVolTot = lnLeaseGrossVolTot + m.nUnits
                     lnLeaseGrossTaxTot = lnLeaseGrossTaxTot + m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4
                     lnLeaseNetTot      = lnLeaseNetTot + m.nNetVal
                     lnOwnNetTot        = lnOwnNetTot + m.nowngross
                     lnLeaseGrossTot    = lnLeaseGrossTot - (m.nTax1 + m.nTax2 + m.nTax3 + m.nTax4)
                     lnOwnNet2Tot       = lnOwnNet2Tot + m.nowntax

                     lnTotal  = lnTotal + m.nowngross - m.nowntax
                     lnCountO = lnCountO + 1
                     lnCount  = lnCount + 1
                  ENDIF
            ENDCASE

            *  There could be expenses on this same line of revenue, so do some reformatting
            *  and insert that line into the file, too
            *  The first part of the record will be zeroes

            IF m.nExpense # 0
               R1ProdCode      = '00'
               R1TranCode1     = '00'
               R1LeaseGrossVol = THIS.ConvertToChar(0, 12, 2)
               R1LeaseGrossTax = THIS.ConvertToChar(0, 9, 2)
               R1LeaseNet      = THIS.ConvertToChar(0, 12, 2)

               R1OwnNet = THIS.ConvertToChar(0, 12, 2)

               R1TranCode2  = '10'
               R1LeaseGross = THIS.ConvertToChar(0, 12, 2)
               R1OwnNet2    = THIS.ConvertToChar(m.nExpense * -1, 12, 2)
               R1Date       = LEFT(ALLTRIM(SYS(1)), 3)
               R1TypeInv    = IIF(LEFT(m.cIntType, 1) = 'L', 'R', LEFT(m.cIntType, 1))
               R1Decimal    = '0'
               R1Interest   = THIS.ConvertToChar(m.nInterest / 100, 9, 8, .T.)
               R1BTUFactor  = '0000'  &&  Not used
               R1Blank      = SPACE(2)
               R1CRLF       = m.CRLF

               THIS.FileIO(fh, R1RecType + R1CompCode + R1CheckNumber + R1WellID + R1FromDate + R1ProdDate)
               THIS.FileIO(fh, R1ProdCode + R1TranCode1 + R1LeaseGrossVol + R1LeaseGrossTax + R1LeaseNet)
               THIS.FileIO(fh, R1OwnNet + R1TranCode2 + R1LeaseGross + R1OwnNet2 + R1Date)
               THIS.FileIO(fh, R1TypeInv + R1Decimal + R1Interest + R1BTUFactor + R1Blank + R1CRLF)

               *  Update all the running totals that will be needed for the summary records
               lnTotalO     = lnTotalO - m.nExpense
               lnOwnNet2Tot = lnOwnNet2Tot - m.nExpense

               lnTotal  = lnTotal - m.nExpense
               lnCountO = lnCountO + 1
               lnCount  = lnCount + 1
            ENDIF
         ENDSCAN

         *  Create the 2/3 records for the last owner in the stub cursor
         IF TYPE('fh') = 'N'

            R2RecType       = '2'
            R2CompCode      = 'SW'
            R2CheckNumber   = PADL(ALLTRIM(m.cCheckno), 12, '0')
            R2RecCount      = THIS.ConvertToChar(lnCountO, 4, 0, .T.)
            R2CheckTotal    = THIS.ConvertToChar(lnTotalO, 12, 2)
            R2NetOut        = 'Y'  &&  We don't use this for anything
            R2PaymentFlag   = 'C'
            R2EffDate       = PADL(ALLTRIM(STR(MONTH(m.dCheckDate))), 2, '0') + PADL(ALLTRIM(STR(DAY(m.dCheckDate))), 2, '0')
            R2LeaseGrossVol = THIS.ConvertToChar(lnLeaseGrossVolTot, 13, 2)
            R2LeaseGrossTax = THIS.ConvertToChar(lnLeaseGrossTaxTot, 10, 2)
            R2LeaseNet      = THIS.ConvertToChar(lnLeaseNetTot, 13, 2)
            R2OwnNetTot     = THIS.ConvertToChar(lnOwnNetTot, 13, 2)
            R2LeaseGross    = THIS.ConvertToChar(lnLeaseGrossTot, 13, 2)
            R2OwnNet2       = THIS.ConvertToChar(lnOwnNet2Tot, 13, 2)
            R2Date          = LEFT(ALLTRIM(SYS(1)), 3)
            R2OwnerID       = PADL(ALLTRIM(m.cid), 12, '0')
            R2Blank         = SPACE(5)
            R2CRLF          = m.CRLF

            THIS.FileIO(fh, R2RecType + R2CompCode + R2CheckNumber + R2RecCount + R2CheckTotal + R2NetOut)
            THIS.FileIO(fh, R2PaymentFlag + R2EffDate + R2LeaseGrossVol + R2LeaseGrossTax + R2LeaseNet)
            THIS.FileIO(fh, R2OwnNetTot + R2LeaseGross + R2OwnNet2 + R2Date + R2OwnerID + R2Blank + R2CRLF)


            *  Now create the final 3 record, and we're done!
            R3RecType    = '3'
            R3CheckCount = '00001'  &&  In theory, this could be more than 1 from other places, but we'll only have 1
            R3CheckTotal = THIS.ConvertToChar(lnTotalO, 14, 2)
            R3Space      = SPACE(112)

            THIS.FileIO(fh, R3RecType + R3CheckCount + R3CheckTotal + R3Space)

            = FCLOSE(fh)
         ENDIF

      CATCH
         = FCLOSE(fh)
      ENDTRY


      ***********************
   PROCEDURE convertochar
      ***********************
      PARAMETERS lcNumberString, lnLength, lnDecimal, lNoLeadingSign

      *  Takes number and converts it to a text string with lnDecimal # of decimal places
      *  and pads with leading zeroes and inserts +/- (if lNoLeadingSign = .f.)

      LOCAL lcNumber

      *  First convert it to the right length number
      lcNumber = STR(lcNumberString, lnLength, lnDecimal)

      *  Now strip out the decimal point
      lcNumber = CHRTRAN(lcNumber, '.', '')

      *  Assign +/- and pad with zeroes
      IF LEFT(ALLTRIM(lcNumber), 1) = '-'
         *  Get rid of the leading sign, since it will format wrong if we leave it
         lcNumber = SUBSTR(ALLTRIM(lcNumber), 2)
         lcNumber = '-' + PADL(ALLTRIM(lcNumber), lnLength - 1, '0')
      ELSE
         lcNumber = '+' + PADL(ALLTRIM(lcNumber), lnLength - 1, '0')
      ENDIF

      *  S/B no +/- at the beginning of the string, so replace it with a zero instead
      IF lNoLeadingSign
         lcNumber = '0' + SUBSTR(lcNumber, 2)
      ELSE
         *  If there's a leading sign, and it's all zeroes, get rid of the leading sign
         IF VAL(lcNumber) = 0
            lcNumber = '0' + SUBSTR(lcNumber, 2)
         ENDIF
      ENDIF

      RETURN lcNumber

      **********************
   PROCEDURE ConvertToNum
      **********************
      PARAMETERS lcNumberString, lnDecimal

      *  Removes leading zeroes and +/- sign and decimal point from a string
      *  and converts it to a number

      LOCAL lnNumber

      lnNumber = VAL(lcNumberString) / 10^lnDecimal

      RETURN lnNumber

      ***********************
   PROCEDURE FileIO
      ***********************
      PARA handle, bytes

      = FWRITE(handle, bytes)
      lnError = FERROR()
      IF FERROR() > 0
         DO CASE
            CASE FERROR() = 4
               m.msg = 'TOO MANY FILE OPEN (OUT OF HANDLES)'
            CASE FERROR() = 5
               m.msg = 'FILE ACCESS DENIED'
            CASE FERROR() = 8
               m.msg = 'OUT OF MEMORY'
            CASE FERROR() = 29
               m.msg = 'DISK FULL (OUT OF SPACE)'
            CASE FERROR() = 31
               m.msg = 'GENERAL FAILURE'
            OTHERWISE
               m.msg = 'UNKNOWN DISK FAILURE' + STR(FERROR(), 3)
         ENDCASE
         WAIT WIND 'FILE WRITE ERROR: ' + m.msg
      ENDIF

      RETURN


      ***************************
   PROCEDURE CreateExpFile
      ***************************

      IF m.goapp.lQBVersion
         CREATE CURSOR importfile ;
            (iRow            I, ;
            cinvnum          C(20), ;
            dinvdate        D, ;
            dduedate        D, ;
            dPostDate       D, ;
            dProdDate       D, ;
            cWellID         C(20), ;
            cWellname       C(60), ;
         cDeck           C(10), ;
            ccatcode        C(5), ;
            cDesc           C(40), ;
            namount         N(12, 2), ;
            cProdYear       C(4), ;
            cProdPeriod     C(2), ;
            cDeptNo         C(10), ;
            cAcctNo         C(31), ;
            nSaltBBL        I, ;
            cafeno          C(10), ;
            cOwnerID        C(10), ;
            cvendorid       C(10), ;
            dpaydate        D, ;
            cPayMethod      C(20), ;
            cCheckno        C(10), ;
            nPayAmount      N(12,2))
      ELSE
         CREATE CURSOR importfile ;
            (iRow            I, ;
            cinvnum          C(20), ;
            dinvdate        D, ;
            dduedate        D, ;
            dPostDate       D, ;
            dProdDate       D, ;
            cWellID         C(20), ;
            cWellname       C(60), ;
            ccatcode        C(5), ;
            cDesc           C(40), ;
            namount         N(12, 2), ;
            cProdYear       C(4), ;
            cProdPeriod     C(2), ;
            cDeptNo         C(10), ;
            cAcctNo         C(6), ;
            nSaltBBL        I, ;
            cafeno          C(10), ;
            cOwnerID        C(10), ;
            cvendorid       C(10), ;
            dpaydate        D, ;
            cPayMethod      C(20), ;
            cCheckno        C(10), ;
            nPayAmount      N(12,2))
      ENDIF

      ***************************
   PROCEDURE CreateRevFile
      ***************************


      CREATE CURSOR importfile ;
         ( iRow            I, ;
         cCheckno        C(10), ;
         dCheckDate      D, ;
         dPostDate       D, ;
         dProdDate       D, ;
         cWellID         C(20), ;
      cDeck           C(10), ;
         cDesc           C(30), ;
         cDeptNo         C(10), ;
         cOwnerID        C(10), ;
         cBegRange       C(5), ;
         cEndRange       C(5), ;
         nDaysOn         I, ;
         lWellRcpt       L, ;
         cProdYear       C(4), ;
         cProdPeriod     C(2), ;
         nSaltBBL        I, ;
         cAcctNo         C(6), ;
         cWellname       C(60), ;
         cProdType       C(5), ;
         nprice          N(12, 6), ;
         nUnits          N(12, 2), ;
         lGrossUnits     L, ;
         nGrossUnits     N(12,2), ;
         nTotalInc       N(12, 2), ;
         cTaxType        C(5), ;
         nTax            N(12, 2), ;
         cDedCode        C(4), ;
         nDeducts        N(12, 2), ;
           cDedCode2        C(4), ;
           nDeducts2        N(12, 2), ;
           cDedCode3        C(4), ;
           nDeducts3        N(12, 2), ;
           cDedCode4        C(4), ;
           nDeducts4        N(12, 2), ;
           cDedCode5        C(4), ;
           nDeducts5        N(12, 2), ;
         nNet            N(12, 2))

      ***************************
   PROCEDURE CreateWellFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         cWellID        C(10), ;
         cWellname        C(30), ;
         ccounty      C(25), ;
         cTownship    C(25), ;
         cstate      C(2), ;
         cGroup       C(2), ;
         cMeterID     C(15), ;
         cMeterID2    C(15), ;
         cMeterID3    C(15), ;
         cMeterID4    C(15), ;
         cMeterID5    C(15), ;
         cMeterID6    C(15), ;
         cWellstat    C(1), ;
         cpermit1     C(20), ;
         cpermit2     C(20), ;
         cpermit3     C(20), ;
         cpermit4     C(20), ;
         cpermit5     C(20), ;
         cpermit6     C(20), ;
         cUser1       C(20), ;
         cUser2       C(20), ;
         cUser3       C(20), ;
         cUser4       C(20), ;
         cUser5       C(20), ;
         cUser6       C(20), ;
         csection     C(10), ;
         cTNR         C(30), ;
         crange       C(20), ;
         cPropNo      C(20), ;
         coilpurchno  C(20), ;
         cgaspurchno  C(20), ;
         cothpurchno  C(20), ;
         clatitude    C(15), ;
         clongitude   C(15), ;
         cPumper      C(40), ;
         cidPumper    C(8), ;
         dProdDate    D, ;
         dcompdate    D, ;
         ncompress    N(11, 7), ;
         lCompress    L, ;
         ngather      N(11, 7), ;
         lGather      L, ;
         cparcel      C(30), ;
         ctable       C(2), ;
         nacres       N(12, 2), ;
         clot         C(20), ;
         dsold        D, ;
         nsellprice   N(12,2), ;
         dpurchased   D, ;
         cpurchfrom   C(40), ;
         lstripper    L, ;
         dplugged     D, ;
         lThird_Prty  L, ;
         lsev1o       L, ;
         lsev2o       L, ;
         lsev3o       L, ;
         lsev4o       L, ;
         lsev1g       L, ;
         lsev2g       L, ;
         lsev3g       L, ;
         lsev4g       L, ;
         lsev1p       L, ;
         lsev2p       L, ;
         lsev3p       L, ;
         lsev4p       L, ;
         mwellnote    C(254), ;
         lroysevtx    L, ;
         lNGLEthane   L, ;
         lNGLPropane  L, ;
         lNGLButane   L, ;
         lNGLISOButane L, ;
         lNGLPentane   L, ;
         cformation    C(30), ;
         cWVDistrict   C(25), ;
         cnra1         C(15), ;
         cnra2        C(15), ;
         cnra3        C(15), ;
         cnra4        C(15), ;
         cnra5        C(15), ;
         cnra6        C(15))

      ***************************
   PROCEDURE CreateLandFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         cleaseid       C(10), ;
         cleasename     C(40), ;
         cProspect      C(40), ;
         mLegaldesc     m, ;
         ccounty        C(20), ;
         cstate         C(2), ;
         cGroup         C(2), ;
         nGrossacre     N(12, 4), ;
         nNetacres      N(12, 4), ;
         nNetdeep       N(12, 4), ;
         dLeasedate     D, ;
         nLeaseyears    I, ;
         nLeasemonths   I, ;
         dNextpmt       D, ;
         mPmtsched      m, ;
         cLeasestatus   C(10), ;
         mComments      m, ;
         dRecDate       D, ;
         cRecbook       C(10), ;
         cRecpage       C(10), ;
         cLeasegroup    C(5), ;
         cAfenumber     C(10), ;
         cPaymentfreq   C(1), ;
         dPmtstart      D, ;
         cInstrument    C(20), ;
         cComingle      C(20), ;
         cRrcleaseno    C(20), ;
         cRrcdistno     C(4), ;
         cFieldid       C(10), ;
         mFormation     m, ;
         cTownship      C(12), ;
         cAgent         C(12), ;
         cConsolref     C(8), ;
         lAmended       L, ;
         dExpires       D, ;
         dConsoldate    D, ;
         mDescription   m, ;
         mParcel        m, ;
         cUnique        C(10), ;
         cPrimadd       m, ;
         cMailadd       m, ;
         lRenewal       L, ;
         mRenewal       m, ;
         lPooling       L, ;
         mPoolnotes     m, ;
         lDepthrestrict L, ;
         mDepthnotes    m, ;
         lShutin        L, ;
         mShutnotes     m, ;
         lOrri          L, ;
         mOrrinotes     m, ;
         lFreegas       L, ;
         mFreegas       m, ;
         lContinuous    L, ;
         mContinuous    m, ;
         lUnitization   L, ;
         mUnitization   m, ;
         lLoapprove     L, ;
         mLoapprove     m, ;
         lAssignment    L, ;
         mAssignment    m, ;
         lDigitized     L, ;
         cAcquired      C(40), ;
         dAcquired      D, ;
         clatitude      C(20), ;
         clongitude     C(20), ;
         cSystem        C(20), ;
         lLegaldisp     L, ;
         cPartner       C(20), ;
         nPartpct       N(6, 2), ;
         mAmi           m, ;
         cAudlink       C(120), ;
         lNotice        L, ;
         cFormation     C(20), ;
         lLegal         L, ;
         cOriglessor    C(30), ;
         cSurfowner     C(10), ;
         cAcctNo        C(6), ;
         cDeptNo        C(8))

      ***************************
   PROCEDURE CreateLandOwnerFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         cIdlando       C(8), ;
         cOwnerID       C(10), ;
         cleaseid       C(10), ;
         nacres         N(12, 4), ;
         nRental        N(9, 2), ;
         nPmtfreq       N(3), ;
         nTotalpmt      N(9, 2), ;
         cStatus        C(2), ;
         dStartpmt      D, ;
         dContstart     D, ;
         dContend       D, ;
         nPmttodate     N(9, 2), ;
         dNextpmt       D, ;
         nYearpmt       N(12, 2), ;
         cPmtdesc       C(60), ;
         nPct           N(11, 7), ;
         cMstatus       C(12), ;
         cRecbook       C(10), ;
         cRecpage       C(10), ;
         cInstrument    C(30), ;
         dRecDate       D, ;
         iLeaseyrs      I, ;
         dExpiredate    D, ;
         lRenewal       L, ;
         mRenewal       m, ;
         lPooling       L, ;
         mPoolnotes     m, ;
         lDepthrestrict L, ;
         mDepthnotes    m, ;
         lShutin        L, ;
         mShutnotes     m, ;
         lOrri          L, ;
         mOrrinotes     m, ;
         lFreegas       L, ;
         mFreegas       m, ;
         mnotes         m, ;
         dFirstpmt      D)

      ***************************
   PROCEDURE CreateOwnerFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         cOwnerID      C(10), ;
         cownname      C(60), ;
         cownname1     C(60), ;
         caddress1a    C(60), ;
         caddress1b    C(60), ;
         ccity1        C(40), ;
         cstate1       C(2), ;
         czip1         C(10), ;
         ctaxid        C(15), ;
         cownname2     C(60), ;
         caddress2a    C(60), ;
         caddress2b    C(60), ;
         ccity2        C(40), ;
         cstate2       C(2), ;
         czip2         C(10), ;
         cphoneh       C(15), ;
         cphonew       C(15), ;
         cphonecell    C(15), ;
         cemail        C(80), ;
         csortfield    C(60), ;
         ninvmin       N(12, 2), ;
         linv1099      L, ;
         lprtdef       L, ;
         lhold         L, ;
         lDummy        L, ;
         lchktosec     L, ;
         lwellpage     L, ;
         lexempt       L, ;
         lOnlinerpts   L, ;
         ldirectdep    L, ;
         cbankacct     C(20), ;
         cbanktransit  C(15), ;
         cbankname     C(40), ;
         nbackpct      N(5, 2), ;
         lbackwith     L, ;
         itaxidtype    I, ;
         ndisbfreq     I, ;
      ccountry1     C(2), ;
      ccountry2     C(2), ;
      linteggl      L, ;
      lfedwire      L, ;
      cpayor        C(5), ;
      cfedindian    C(1), ;
      cfundcode     C(3), ;
      cpad          C(12), ;
      caccount      C(10), ;
      ctaxname      C(10), ;
      caddenda      C(60), ;
         mnotes        C(254))

      ***************************
   PROCEDURE CreateDOIFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
      cDeck     C(10), ;
         cWellID   C(20), ;
         cOwnerID  C(10), ;
         cTypeInv  C(1), ;
         ctypeint  C(1), ;
         cdirect   C(1), ;
         cprogcode C(10), ;
         ceffStartYr c(4), ;
         ceffstartPrd c(2), ;
         ljib      L, ;
         lonhold   L, ;
         nrevoil   N(13, 9), ;
         nrevgas   N(13, 9), ;
         nrevoth   N(13, 9), ;
         nrevtrp   N(13, 9), ;
         nworkint  N(13, 9), ;
         nrevtax1  N(13, 9), ;
         nrevtax2  N(13, 9), ;
         nrevtax3  N(13, 9), ;
         nrevtax4  N(13, 9), ;
         nrevtax5  N(13, 9), ;
         nrevtax6  N(13, 9), ;
         nrevtax7  N(13, 9), ;
         nrevtax8  N(13, 9), ;
         nrevtax9  N(13, 9), ;
         nrevtax10  N(13, 9), ;
         nrevtax11  N(13, 9), ;
         nrevtax12  N(13, 9), ;
         nintclass1 N(13, 9), ;
         nintclass2 N(13, 9), ;
         nintclass3 N(13, 9), ;
         nintclass4 N(13, 9), ;
         nintclass5 N(13, 9), ;
         nbcpint    N(13, 9), ;
         nacpint    N(13, 9), ;
         napoint    N(13, 9), ;
         nrevmisc1  N(13, 9), ;
         nrevmisc2  N(13, 9), ;
      ntaxpct   N(13, 9),  ;
      ceffstartyr  C(4), ;
      ceffstartprd C(2))

      ***************************
   PROCEDURE CreateGLFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         cBatch    C(8), ;
         dgldate   D, ;
         cAcctNo   C(6), ;
         cDesc     C(40), ;
         cref      C(25), ;
         cunitno   C(10), ;
         ccatcode  C(4), ;
         cDeptNo   C(8), ;
           cafeno    C(10), ;
         ndebits   N(12, 2), ;
         ncredits  N(12, 2))
***************************
   PROCEDURE CreateUnitsFile
***************************
   CREATE CURSOR importfile ;
      (iRow            I, ;
      cprogcode        C(10), ;
      cownerid         C(10), ;
      ddepositdate     D, ;
      deffdate         D, ;
      npercentage      N(11,7), ;
      namount          N(12, 2))

      ***************************
   PROCEDURE CreateCOAFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         cAcctNo   C(6), ;
         naccttype I, ;
         cacctdesc C(30), ;
         cparent   C(6), ;
         lbankacct L, ;
         lacctunit L, ;
         lacctdept L, ;
         lrent1099 L)

      ***************************
   PROCEDURE CreateCustFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         ccustid   C(10), ;
         ccustname C(60), ;
         caddress1 C(60), ;
         caddress2 C(60), ;
         ccity     C(30), ;
         cstate    C(2), ;
         czip      C(10), ;
         cphone    C(15), ;
         cfaxphone C(15), ;
         ccontact  C(30), ;
         cbaddr1   C(60), ;
         cbaddr2   C(60), ;
         cbcity    C(30), ;
         cbstate   C(2), ;
         cbzip     C(10), ;
         cbphone   C(15), ;
         cbfaxphone C(15), ;
         cbcontact  C(30), ;
         mcustnote  C(254), ;
         ctaxid     C(15))

      ***************************
   PROCEDURE CreateVendFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         cvendorid   C(10), ;
         cvendname C(60), ;
         caddress1 C(60), ;
         caddress2 C(60), ;
         ccity     C(30), ;
         cstate    C(2), ;
         czip      C(10), ;
         cphone    C(15), ;
         cfaxphone C(15), ;
         ccontact  C(30), ;
         cbaddr1   C(60), ;
         cbaddr2   C(60), ;
         cbcity    C(30), ;
         cbstate   C(2), ;
         cbzip     C(10), ;
         cbphone   C(15), ;
         cbfaxphone C(15), ;
         cbcontact  C(30), ;
         lsend1099  L, ;
         csortfield C(60), ;
         ctaxid     C(15), ;
         mvendnote  C(254), ;
         itaxidtype I)

      ***************************
   PROCEDURE CreateECatFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         ccatcode   C(4), ;
         ccateg    C(25), ;
         cdescrip  C(40), ;
         ctaxcode  C(2), ;
         cExpClass C(1))

      ***************************
   PROCEDURE CreatePurchFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         crevkey    C(10), ;
         crevname  C(30), ;
         caddress1 C(40), ;
         caddress2 C(40), ;
         caddress3 C(40), ;
         cphone    C(14), ;
         cfaxphone C(14))

      ***************************
   PROCEDURE CreateMeterFile
      ***************************

      CREATE CURSOR importfile ;
         (iRow            I, ;
         cMeterID   C(15), ;
         cmeterdesc C(30), ;
         cmeterserialno c(25), ;
         cmeterloc      c(25), ;
         cmetercity     c(40), ;
         cmeterstate    c(2), ;
         cmeterzip      c(10))
        ***************************
   PROCEDURE CreatePumperFile
      ***************************
      CREATE CURSOR importfile ;
         (iRow            I, ;
         cidpumper   C(8), ;
         cpumperName C(40), ;
         caddress1   C(40), ;
         ccity       c(25), ;
         cstate      c(2), ;
         czip        c(10), ;
         cphone      c(15), ;
         cemail      c(128))


      ****************************
   PROCEDURE BuildImportFileRev
      ****************************
      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Receipts...')
         oprogress.SetProgressRange(0, lnMax)

         SELECT importtemp
         SCAN

            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            STORE 0 TO m.nTotalInc, m.nprice, m.nTax, m.nUnits, m.nSaltBBL, m.nDaysOn, m.ndeducts, ;
                       m.nDeducts2, m.nDeducts3, m.nDeducts4, m.nDeducts5
            STORE '' TO m.cPostDate, m.cCheckDate, m.cTotalInc, m.cUnits, m.cPrice, m.cWellname, ;
               m.cWellID, m.ctcax, m.cProdYear, m.cProdPeriod, m.cBegRange, m.cEndRange, ;
               m.cDaysOn, m.cSaltBBL, m.cOwnerID, m.cAcctNo, m.cTax, m.cDeducts, m.cDeducts2, m.cDeducts3, ;
               m.cDeducts4, m.cDeducts5

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               IF NOT EMPTY(m.cCheckDate)
                  m.dCheckDate = CTOD(m.cCheckDate)
                  IF EMPTY(m.dCheckDate) AND THIS.lXLSX
                     * Convert an Excel Number to a date format
                     m.dCheckDate = CTOD('12/30/1899') + INT(VAL(m.cCheckDate))
                  ENDIF
               ELSE
                  m.dCheckDate = DATE()
               ENDIF

               IF NOT EMPTY(m.cPostDate)
                  m.dPostDate  = CTOD(m.cPostDate)
                  IF EMPTY(m.dPostDate) AND THIS.lXLSX
                     * Convert an Excel Number to a date format
                     m.dPostDate = CTOD('12/30/1899') + INT(VAL(m.cPostDate))
                  ENDIF
               ELSE
                  m.dPostDate = m.dCheckDate
               ENDIF

               IF NOT EMPTY(m.cProdDate)
                  m.dProdDate = CTOD(m.cProdDate)
                  IF EMPTY(m.dProdDate) AND THIS.lXLSX
                     * Convert an Excel Number to a date format
                     m.dProdDate = CTOD('12/30/1899') + INT(VAL(m.cProdDate))
                  ENDIF
               ELSE
                  m.dProdDate = m.dCheckDate
               ENDIF

               m.cBegPrd   = SUBSTR(m.cBegRange, 1, AT('/', m.cBegRange) - 1)
               m.cBegPrd   = PADL(ALLTRIM(m.cBegPrd), 2, '0')
               m.cBegYr    = SUBSTR(m.cBegRange, AT('/', m.cBegRange) + 1, 2)
               m.cBegRange = m.cBegPrd + '/' + m.cBegYr
               m.cEndPrd   = SUBSTR(m.cEndRange, 1, AT('/', m.cEndRange) - 1)
               m.cEndPrd   = PADL(ALLTRIM(m.cEndPrd), 2, '0')
               m.cEndYr    = SUBSTR(m.cEndRange, AT('/', m.cEndRange) + 1, 2)
               m.cEndRange = m.cEndPrd + '/' + m.cEndYr
               IF m.cBegPrd = '00'
                  m.cBegRange = ''
               ENDIF
               IF m.cEndPrd = '00'
                  m.cEndRange = ''
               ENDIF


               m.nUnits    = ConvertAmount(m.cUnits)

               IF VARTYPE(m.cGrossUnits) = 'C'
                  IF NOT EMPTY(m.cGrossUnits)
                     m.lGrossUnits = .T.
                     m.nGrossUnits = m.nUnits
                  ELSE
                     m.lGrossUnits = .F.
                     m.nGrossUnits = 0
                  ENDIF
               ENDIF

               m.nprice    = ConvertAmount(m.cPrice)
               m.nTotalInc = ConvertAmount(m.cTotalInc)
               m.nTax      = ConvertAmount(m.cTax)
               m.nDeducts  = ConvertAmount(m.cDeducts)
               m.nDeducts2  = ConvertAmount(m.cDeducts2)
               m.nDeducts3  = ConvertAmount(m.cDeducts3)
               m.nDeducts4  = ConvertAmount(m.cDeducts4)
               m.nDeducts5  = ConvertAmount(m.cDeducts5)
               m.nDaysOn   = INT(VAL(m.cDaysOn))
               * Calc days on from ranges if it wasn't imported
               IF m.nDaysOn = 0
                  m.nDaysOn = THIS.CalcDaysOn(m.cBegRange,m.cEndRange)
               ENDIF
               m.nSaltBBL  = INT(VAL(m.cSaltBBL))
               m.cWellID   = ALLTRIM(UPPER(m.cWellID))

               IF m.nTotalInc # 0 OR m.nDeducts # 0 OR m.nTax # 0 OR (m.nDeducts2+m.nDeducts3+m.nDeducts4+m.nDeducts5) # 0
                  INSERT INTO importfile FROM MEMVAR
               ENDIF

            CATCH TO loError
               llReturn = .F.
               DO errorlog WITH 'BuildImportFileRev', loError.LINENO, 'swFile', loError.ERRORNO, loError.MESSAGE, '', loError
               MESSAGEBOX('Unable to import the file at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
                  'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
            ENDTRY

         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildImportFileRev', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn

      ****************************
   PROCEDURE CalcDaysOn
      ****************************
      LPARAMETERS tcBegRange, tcEndRange
      LOCAL ldDate1, ldDate2, lnDays, lcYear, lcRange1, lcRange2

      *
      *  Get the current year to use to build the date.
      *
      lcYear   = STR(YEAR(DATE()),4)

      *
      *  Put the period ranges in variables to make them easier
      *  to work with.
      *
      lcRange1 = tcBegRange
      lcRange2 = tcEndRange

      *
      *  Check to see if we're supposed to calculate the dayson
      *
      swselect('options')
      GO TOP
      glCalcDays = lCalcDays

      *
      *  Calculate the number of days between the ranges
      *
      IF glCalcDays AND lcRange1 <> '  /  ' AND lcRange2 <> '  /  '
         IF LEFT(lcRange1,2) > LEFT(lcRange2,2)
            lcYear1 = STR(VAL(lcYear)+1,4)
         ELSE
            IF LEFT(lcRange1,2) = LEFT(lcRange2,2)
               IF RIGHT(lcRange1,2) > RIGHT(lcRange2,2)
                  lcYear1 = STR(VAL(lcYear)+1,4)
               ELSE
                  lcYear1 = lcYear
               ENDIF
            ELSE
               lcYear1 = lcYear
            ENDIF
         ENDIF
         ldDate1 = CTOD(lcRange1+'/'+lcYear)
         ldDate2 = CTOD(lcRange2+'/'+lcYear1)
         lnDays  = (ldDate2 - ldDate1) + 1
         RETURN (lnDays)
      ELSE
         RETURN (0)
      ENDIF

      ****************************
   PROCEDURE BuildImportFileExp
      ****************************
      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR


         STORE '' TO m.cinvdate, m.cduedate, m.cPostDate, m.cinvnum, m.cWellID, m.cWellname, m.cAcctNo, ;
            m.cDeptNo, m.cOwnerID, m.cDesc, m.ccatcode, m.cProdYear, m.cProdPeriod, m.camount

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Bills...')
         oprogress.SetProgressRange(0, lnMax)
         m.iRow = 0
         SELECT importtemp
         SCAN

            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)

               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               IF VARTYPE(m.cinvdate) = 'C' AND NOT EMPTY(m.cinvdate)
                  m.dinvdate = CTOD(m.cinvdate)
                  IF EMPTY(m.dinvdate) AND THIS.lXLSX
                     * Convert an Excel Number to a date format
                     m.dinvdate = CTOD('12/30/1899') + INT(VAL(m.cinvdate))
                  ENDIF
               ELSE
                  m.dinvdate = DATE()
               ENDIF
               IF EMPTY(m.dinvdate)
                  m.dinvdate = DATE()
               ENDIF
               IF VARTYPE(m.cduedate) = 'C' AND NOT EMPTY(m.cduedate)
                  m.dduedate = CTOD(m.cduedate)
                  IF EMPTY(m.dduedate) AND THIS.lXLSX
                     * Convert an Excel Number to a date format
                     m.dduedate = CTOD('12/30/1899') + INT(VAL(m.cduedate))
                  ENDIF
               ELSE
                  m.dduedate = m.dinvdate + 30
               ENDIF
               IF VARTYPE(m.cPostDate) = 'C' AND NOT EMPTY(m.cPostDate)
                  m.dPostDate = CTOD(m.cPostDate)
                  IF EMPTY(m.dPostDate) AND THIS.lXLSX
                     * Convert an Excel Number to a date format
                     m.dPostDate = CTOD('12/30/1899') + INT(VAL(m.cPostDate))
                  ENDIF
               ELSE
                  m.dPostDate = DATE()
               ENDIF
               IF EMPTY(m.dPostDate)
                  m.dPostDate = m.dinvdate
               ENDIF

               IF NOT EMPTY(m.cProdDate)
                  m.dProdDate = CTOD(m.cProdDate)
                  IF EMPTY(m.dProdDate) AND THIS.lXLSX
                     * Convert an Excel Number to a date format
                     m.dProdDate = CTOD('12/30/1899') + INT(VAL(m.cProdDate))
                  ENDIF
               ELSE
                  m.dProdDate = m.dinvdate
               ENDIF

               IF VARTYPE(m.cPayDate) = 'C'
                  m.dpaydate = CTOD(m.cPayDate)
                  IF EMPTY(m.dpaydate) AND THIS.lXLSX
                     * Convert an Excel Number to a date format
                     m.dpaydate = CTOD('12/30/1899') + INT(VAL(m.cPayDate))
                  ENDIF
               ELSE
                  m.dpaydate = {}
               ENDIF

               TRY
                  m.namount = ConvertAmount(m.camount)
               CATCH
                  m.namount = 0
               ENDTRY

               TRY
                  m.nPayAmount = ConvertAmount(m.cPayAmount)
               CATCH
                  m.nPayAmount = 0
               ENDTRY

               TRY
                  m.nSaltBBL = ConvertAmount(m.cSaltBBL)
               CATCH
                  m.nSaltBBL = 0
               ENDTRY

               m.cWellID = ALLTRIM(UPPER(m.cWellID))

               DO CASE
                  CASE NOT EMPTY(m.cWellID) AND m.namount # 0
                     INSERT INTO importfile FROM MEMVAR
                  CASE NOT EMPTY(m.cAcctNo) AND m.namount # 0
                     INSERT INTO importfile FROM MEMVAR
                  CASE NOT EMPTY(m.cDesc) AND m.namount # 0
                     INSERT INTO importfile FROM MEMVAR
               ENDCASE
            CATCH TO loError
               MESSAGEBOX('Error importing data...' + CHR(10) + ;
                  'Error No: ' + TRANSFORM(loError.ERRORNO) + CHR(10) + ;
                  'Line No: ' + TRANSFORM(loError.LINENO) + CHR(10) + ;
                  'Message: ' + loError.MESSAGE, 16, 'Error Importing')
               llError = .T.
            ENDTRY

            IF llError
               llReturn = .F.
               EXIT
            ENDIF
         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildImportFileExp', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      TRY
         IF FILE('datafiles\showimp.txt')
            SET SAFETY OFF
            SELECT importfile
            COPY TO importtemp
         ENDIF
      CATCH
      ENDTRY

      RETURN llReturn

      *************************
   PROCEDURE BuildWells
      *************************
      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Wells...')
         oprogress.SetProgressRange(0, lnMax)

         SELECT importtemp
         SCAN

            SCATTER MEMVAR
            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1
            STORE 0 TO m.nowndeducts, m.nGrossDeducts, m.nGrossTax, m.nowntax, m.nwithhold, m.nInterest

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               m.cWellID   = ALLTRIM(UPPER(m.cWellID))
               m.cWellname = ALLTRIM(m.cWellname)
            CATCH
            ENDTRY

            TRY
               m.dProdDate = CTOD(m.cProdDate)
               IF EMPTY(m.dProdDate) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dProdDate = CTOD('12/30/1899') + INT(VAL(m.cProdDate))
               ENDIF
            CATCH
               m.dProdDate = {}
            ENDTRY

            TRY
               m.dcompdate = CTOD(m.cCompDate)
               IF EMPTY(m.dcompdate) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dcompdate = CTOD('12/30/1899') + INT(VAL(m.cCompDate))
               ENDIF
            CATCH
               m.dcompdate = {}
            ENDTRY
            TRY
               m.dpurchased = CTOD(m.cpurchased)
               IF EMPTY(m.dpurchased) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dpurchased = CTOD('12/30/1899') + INT(VAL(m.cPurchased))
               ENDIF
            CATCH
               m.dPurchased = {}
            ENDTRY
            TRY
               m.dsold = CTOD(m.csold)
               IF EMPTY(m.dsold) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dsold = CTOD('12/30/1899') + INT(VAL(m.cSold))
               ENDIF
            CATCH
               m.dSold = {}
            ENDTRY
            TRY
               m.dplugged = CTOD(m.cPlugged)
               IF EMPTY(m.dPlugged) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dPlugged = CTOD('12/30/1899') + INT(VAL(m.cPlugged))
               ENDIF
            CATCH
               m.dPlugged = {}
            ENDTRY

            TRY
               m.nsellprice = ConvertAmount(m.csellprice )
            CATCH
               m.nsellprice = 0
            ENDTRY
            TRY
               m.ngather = ConvertAmount(m.cgather )
            CATCH
               m.ngather = 0
            ENDTRY

            IF m.ngather # 0
               m.lGather = .T.
            ELSE
               m.lGather = .F.
            ENDIF

            TRY
               m.ncompress = ConvertAmount(m.cCompress)
            CATCH
               m.ncompress = 0
            ENDTRY

            IF m.ncompress # 0
               m.lCompress = .T.
            ELSE
               m.lCompress = .F.
            ENDIF

            TRY
               m.nacres = VAL(m.cAcres)
            CATCH
               m.nacres = 0
            ENDTRY

            TRY
               m.nDepth = INT(VAL(m.cDepth))
            CATCH
               m.nDepth = 0
            ENDTRY
            TRY
               IF NOT EMPTY(m.cstripper) AND NOT 'N' $ UPPER(m.cstripper) AND NOT 'F' $ UPPER(m.cstripper)
                  STORE .T. TO m.lStripper
               ELSE
                  STORE .F. TO m.lStripper
               ENDIF
            CATCH
               STORE .F. TO m.lStripper
            ENDTRY

            TRY
               IF NOT EMPTY(m.coiltax1) AND NOT 'N' $ UPPER(m.coiltax1) AND NOT 'F' $ UPPER(m.coiltax1)
                  STORE .T. TO m.lsev1o, m.lsev2o, m.lsev3o, m.lsev4o
               ELSE
                  STORE .F. TO m.lsev1o
               ENDIF
            CATCH
               STORE .F. TO m.lsev1o
            ENDTRY

            TRY
               IF NOT EMPTY(m.cgastax1) AND NOT 'N' $ UPPER(m.cgastax1) AND NOT 'F' $ UPPER(m.cgastax1)
                  STORE .T. TO m.lsev1g, m.lsev2g, m.lsev3g, m.lsev4g
               ELSE
                  STORE .F. TO m.lsev1g
               ENDIF
            CATCH
               STORE .F. TO m.lsev1g
            ENDTRY

            TRY
               IF NOT EMPTY(m.cothtax1) AND NOT 'N' $ UPPER(m.cothtax1) AND NOT 'F' $ UPPER(m.cothtax1)
                  STORE .T. TO m.lsev1p, m.lsev2p, m.lsev3p, m.lsev4p
               ELSE
                  STORE .F. TO m.lsev1p
               ENDIF
            CATCH
               STORE .F. TO m.lsev1p
            ENDTRY

            TRY
               IF NOT EMPTY(m.coiltax2) AND NOT 'N' $ UPPER(m.coiltax2) AND NOT 'F' $ UPPER(m.coiltax2)
                  STORE .T. TO m.lsev2o
               ELSE
                  STORE .F. TO m.lsev2o
               ENDIF
            CATCH
               STORE .F. TO m.lsev2o
            ENDTRY

            TRY
               IF NOT EMPTY(m.cgastax2) AND NOT 'N' $ UPPER(m.cgastax2) AND NOT 'F' $ UPPER(m.cgastax2)
                  STORE .T. TO m.lsev2g
               ELSE
                  STORE .F. TO m.lsev2g
               ENDIF
            CATCH
               STORE .F. TO m.lsev2g
            ENDTRY

            TRY
               IF NOT EMPTY(m.cothtax2) AND NOT 'N' $ UPPER(m.cothtax2) AND NOT 'F' $ UPPER(m.cothtax2)
                  STORE .T. TO m.lsev2p
               ELSE
                  STORE .F. TO m.lsev2p
               ENDIF
            CATCH
               STORE .F. TO m.lsev2p
            ENDTRY

            TRY
               IF NOT EMPTY(m.coiltax3) AND NOT 'N' $ UPPER(m.coiltax3) AND NOT 'F' $ UPPER(m.coiltax3)
                  STORE .T. TO m.lsev3o
               ELSE
                  STORE .F. TO m.lsev3o
               ENDIF
            CATCH
               STORE .F. TO  m.lsev3o
            ENDTRY

            TRY
               IF NOT EMPTY(m.cgastax3) AND NOT 'N' $ UPPER(m.cgastax3) AND NOT 'F' $ UPPER(m.cgastax3)
                  STORE .T. TO m.lsev3g
               ELSE
                  STORE .F. TO m.lsev3g
               ENDIF
            CATCH
               STORE .F. TO m.lsev3g
            ENDTRY

            TRY
               IF NOT EMPTY(m.cothtax3) AND NOT 'N' $ UPPER(m.cothtax3) AND NOT 'F' $ UPPER(m.cothtax3)
                  STORE .T. TO m.lsev3p
               ELSE
                  STORE .F. TO m.lsev3p
               ENDIF
            CATCH
               STORE .F. TO m.lsev3p
            ENDTRY

            TRY
               IF NOT EMPTY(m.coiltax4) AND NOT 'N' $ UPPER(m.coiltax4) AND NOT 'F' $ UPPER(m.coiltax4)
                  STORE .T. TO m.lsev4o
               ELSE
                  STORE .F. TO m.lsev4o
               ENDIF
            CATCH
               STORE .F. TO  m.lsev4o
            ENDTRY

            TRY
               IF NOT EMPTY(m.cgastax4) AND NOT 'N' $ UPPER(m.cgastax4) AND NOT 'F' $ UPPER(m.cgastax4)
                  STORE .T. TO m.lsev4g
               ELSE
                  STORE .F. TO m.lsev4g
               ENDIF
            CATCH
               STORE .F. TO m.lsev4g
            ENDTRY

            TRY
               IF NOT EMPTY(m.cothtax4) AND NOT 'N' $ UPPER(m.cothtax4) AND NOT 'F' $ UPPER(m.cothtax4)
                  STORE .T. TO m.lsev4p
               ELSE
                  STORE .F. TO m.lsev4p
               ENDIF
            CATCH
               STORE .F. TO m.lsev4p
            ENDTRY


            TRY
               IF NOT EMPTY(m.cRoyExempt) AND NOT 'N' $ UPPER(m.cRoyExempt) AND NOT 'F' $ UPPER(m.cRoyExempt)
                  m.lroysevtx = .T.
               ELSE
                  m.lroysevtx = .F.
               ENDIF
            CATCH
               m.lroysevtx = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.cThird_Prty) AND NOT 'N' $ UPPER(m.cThird_Prty) AND NOT 'F' $ UPPER(m.cThird_Prty)
                  m.lThird_Prty = .T.
               ELSE
                  m.lThird_Prty = .F.
               ENDIF
            CATCH
               m.lThird_Prty = .F.
            ENDTRY
            TRY
               IF NOT EMPTY(m.cNGLPropane) AND NOT 'N' $ UPPER(m.cNGLPropane) AND NOT 'F' $ UPPER(m.cNGLPropane)
                  m.lNGLPropane = .T.
               ELSE
                  m.lNGLPropane = .F.
               ENDIF
            CATCH
               m.lNGLPropane = .F.
            ENDTRY
            TRY
               IF NOT EMPTY(m.cNGLEthane) AND NOT 'N' $ UPPER(m.cNGLEthane) AND NOT 'F' $ UPPER(m.cNGLEthane)
                  m.lNGLEthane = .T.
               ELSE
                  m.lNGLEthane = .F.
               ENDIF
            CATCH
               m.lNGLEthane = .F.
            ENDTRY
            TRY
               IF NOT EMPTY(m.cNGLButane) AND NOT 'N' $ UPPER(m.cNGLButane) AND NOT 'F' $ UPPER(m.cNGLButane)
                  m.lNGLButane = .T.
               ELSE
                  m.lNGLButane = .F.
               ENDIF
            CATCH
               m.lNGLButane = .F.
            ENDTRY
            TRY
               IF NOT EMPTY(m.cNGLISOButane) AND NOT 'N' $ UPPER(m.cNGLISOButane) AND NOT 'F' $ UPPER(m.cNGLISOButane)
                  m.lNGLISOButane = .T.
               ELSE
                  m.lNGLISOButane = .F.
               ENDIF
            CATCH
               m.lNGLISOButane = .F.
            ENDTRY
            TRY
               IF NOT EMPTY(m.cNGLPentane) AND NOT 'N' $ UPPER(m.cNGLPentane) AND NOT 'F' $ UPPER(m.cNGLPentane)
                  m.lNGLPentane = .T.
               ELSE
                  m.lNGLPentane = .F.
               ENDIF
            CATCH
               m.lNGLPentane = .F.
            ENDTRY

            TRY
               IF EMPTY(m.cGroup)
                  m.cGroup = '00'
               ENDIF
            CATCH
               m.cGroup = '00'
            ENDTRY

            TRY
               m.mwellnote = m.cNotes
            CATCH
               m.mwellnote = ''
            ENDTRY

            IF NOT EMPTY(m.cWellID)
               m.cWellID = ALLTRIM(UPPER(m.cWellID))
               INSERT INTO importfile FROM MEMVAR
            ENDIF

         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildWells', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn
      *************************
   PROCEDURE BuildOwners
      *************************
      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Owners...')
         oprogress.SetProgressRange(0, lnMax)

         SELECT importtemp
         SCAN

            SCATTER MEMVAR
            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1
            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               m.ninvmin = VAL(m.cInvMin)
            CATCH
               m.ninvmin = 0
            ENDTRY

            TRY
               m.nbackpct  = VAL(m.cbackpct)
               m.lbackwith = m.nbackpct # 0
            CATCH
               m.nbackpct  = 0
               m.lbackwith = .F.
            ENDTRY

            TRY
               m.ndisbfreq = VAL(m.cdisbfreq)
               IF NOT INLIST(m.ndisbfreq, 1, 2, 3, 4)
                  m.ndisbfreq = 1
               ENDIF
            CATCH
               m.ndisbfreq = 0
            ENDTRY

            TRY
               IF NOT EMPTY(m.cinv1099) AND NOT 'N' $ UPPER(m.cinv1099) AND NOT 'F' $ UPPER(m.cinv1099)
                  m.linv1099 = .T.
               ELSE
                  m.linv1099 = .F.
               ENDIF
            CATCH
               m.linv1099 = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.cprtdef) AND NOT 'N' $ UPPER(m.cprtdef) AND NOT 'F' $ UPPER(m.cprtdef)
                  m.lprtdef = .T.
               ELSE
                  m.lprtdef = .F.
               ENDIF
            CATCH
               m.lprtdef = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.cdummy) AND NOT 'N' $ UPPER(m.cdummy) AND NOT 'F' $ UPPER(m.cdummy)
                  m.lDummy = .T.
               ELSE
                  m.lDummy = .F.
               ENDIF
            CATCH
               m.lDummy = .F.
            ENDTRY


            TRY
               IF NOT EMPTY(m.chold) AND NOT 'N' $ UPPER(m.chold) AND NOT 'F' $ UPPER(m.chold)
                  m.lhold = .T.
               ELSE
                  m.lhold = .F.
               ENDIF
            CATCH
               m.lhold = .F.
         ENDTRY
         TRY
            IF NOT EMPTY(m.cinteggl) AND NOT 'N' $ UPPER(m.cinteggl) AND NOT 'F' $ UPPER(m.cinteggl)
               m.linteggl = .T.
            ELSE
               m.linteggl = .F.
            ENDIF
         CATCH
            m.linteggl = .F.
         ENDTRY
         TRY
            IF NOT EMPTY(m.cfedwire) AND NOT 'N' $ UPPER(m.cfedwire) AND NOT 'F' $ UPPER(m.cfedwire)
               m.lfedwire = .T.
            ELSE
               m.lfedwire = .F.
            ENDIF
         CATCH
            m.lfedwire = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.cchktosec) AND NOT 'N' $ UPPER(m.cchktosec) AND NOT 'F' $ UPPER(m.cchktosec)
                  m.lchktosec = .T.
               ELSE
                  m.lchktosec = .F.
               ENDIF
            CATCH
               m.lchecktosec = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.cwellpage) AND NOT 'N' $ UPPER(m.cwellpage) AND NOT 'F' $ UPPER(m.cwellpage)
                  m.lwellpage = .T.
               ELSE
                  m.lwellpage = .F.
               ENDIF
            CATCH
               m.lwellpage = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.cexempt) AND NOT 'N' $ UPPER(m.cexempt) AND NOT 'F' $ UPPER(m.cexempt)
                  m.lexempt = .T.
               ELSE
                  m.lexempt = .F.
               ENDIF
            CATCH
               m.lexempt = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.conlinerpts) AND NOT 'N' $ UPPER(m.conlinerpts) AND NOT 'F' $ UPPER(m.conlinerpts)
                  m.lOnlinerpts = .T.
               ELSE
                  m.lOnlinerpts = .F.
               ENDIF
            CATCH
               m.lOnlinerpts = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.cdirectdep) AND NOT 'N' $ UPPER(m.cdirectdep) AND NOT 'F' $ UPPER(m.cdirectdep)
                  m.ldirectdep = .T.
               ELSE
                  m.ldirectdep = .F.
               ENDIF
            CATCH
               m.ldirectdep = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.ctaxidtype)
                  IF m.ctaxidtype = '1'
                     m.itaxidtype = 1
                  ELSE
                     m.itaxidtype = 2
                  ENDIF
               ELSE
                  m.itaxidtype = 2
               ENDIF
            CATCH
            ENDTRY

            TRY
               m.mnotes = ALLTRIM(m.cNotes)
            CATCH
               m.mnotes = ''
            ENDTRY

            IF NOT EMPTY(m.cOwnerID)
               m.cOwnerID = ALLTRIM(UPPER(m.cOwnerID))
               INSERT INTO importfile FROM MEMVAR
            ENDIF

         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildOwners', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn
      *************************
   PROCEDURE BuildDOI
      *************************

      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing DOI...')
         oprogress.SetProgressRange(0, lnMax)

         SELECT importtemp
         SCAN

            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               IF NOT EMPTY(m.cJIB) AND NOT 'N' $ UPPER(m.cJIB) AND NOT 'F' $ UPPER(m.cJIB)
                  m.ljib = .T.
               ELSE
                  m.ljib = .F.
               ENDIF
            CATCH
               m.ljib = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.cOnHold) AND NOT 'N' $ UPPER(m.cOnHold) AND NOT 'F' $ UPPER(m.cOnHold)
                  m.lonhold = .T.
               ELSE
                  m.lonhold = .F.
               ENDIF
            CATCH
               m.lonhold = .F.
            ENDTRY

            TRY
               m.nrevoil = VAL(m.crevoil)
            CATCH
               m.nrevoil = 0
            ENDTRY

            TRY
               m.nrevgas = VAL(m.crevgas)
            CATCH
               m.nrevgas = 0
            ENDTRY

            TRY
               m.nrevoth = VAL(m.cRevOth)
            CATCH
               m.nrevoth = 0
            ENDTRY

            TRY
               m.nrevtrp = VAL(m.crevtrp)
            CATCH
               m.nrevtrp = 0
            ENDTRY

            TRY
               m.nworkint = VAL(m.cWorkInt)
            CATCH
               m.nworkint = 0
            ENDTRY

            TRY
               m.nrevtax1 = VAL(m.cRevTax1)
            CATCH
               m.nrevtax1 = 0
            ENDTRY

            TRY
               m.nrevtax2 = VAL(m.cRevTax2)
            CATCH
               m.nrevtax2 = 0
            ENDTRY

            TRY
               m.nrevtax3 = VAL(m.cRevTax3)
            CATCH
               m.nrevtax3 = 0
            ENDTRY

            TRY
               m.nintclass1 = VAL(m.cIntClass1)
            CATCH
               m.nintclass1 = 0
            ENDTRY

            TRY
               m.nintclass2 = VAL(m.cIntClass2)
            CATCH
               m.nintclass2 = 0
            ENDTRY

            TRY
               m.nintclass3 = VAL(m.cIntClass3)
            CATCH
               m.nintclass3 = 0
            ENDTRY

            TRY
               m.nintclass4 = VAL(m.cIntClass4)
            CATCH
               m.nintclass4 = 0
            ENDTRY

            TRY
               m.nintclass5 = VAL(m.cIntClass5)
            CATCH
               m.nintclass5 = 0
            ENDTRY

            TRY
               m.nbcpint = VAL(m.cBCPInt)
            CATCH
               m.nbcpint = 0
            ENDTRY

            TRY
               m.nacpint = VAL(m.cACPInt)
            CATCH
               m.nacpint = 0
            ENDTRY

            TRY
               m.napoint = VAL(m.cAPOInt)
            CATCH
               m.napoint = 0
            ENDTRY

            TRY
               m.ntaxpct = VAL(m.cTaxPct)
            CATCH
               m.ntaxpct = 0
            ENDTRY

            TRY
               m.nrevmisc1 = VAL(m.cRevMisc1)
            CATCH
               m.nrevmisc1 = 0
            ENDTRY

            TRY
               m.nrevmisc2 = VAL(m.cRevMisc2)
            CATCH
               m.nrevmisc2 = 0
            ENDTRY

         m.ceffstartprd = PADL(ALLTRIM(m.ceffstartprd),2,'0')
         IF m.ceffstartprd = '00'
            m.ceffstartprd = '01'
            m.ceffstartyr  = '1980'
         ENDIF
            STORE m.nrevtax1 TO m.nrevtax4, m.nrevtax7, m.nrevtax10
            STORE m.nrevtax2 TO m.nrevtax5, m.nrevtax8, m.nrevtax11
            STORE m.nrevtax3 TO m.nrevtax6, m.nrevtax9, m.nrevtax12

            IF NOT EMPTY(m.cOwnerID) AND NOT EMPTY(m.cWellID)
               m.cOwnerID = UPPER(ALLTRIM(m.cOwnerID))
               m.cWellID  = UPPER(ALLTRIM(m.cWellID))
               INSERT INTO importfile FROM MEMVAR
            ENDIF
         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildDOI', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the iport at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn
      *************************
   PROCEDURE BuildJournal
      *************************

      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Journal Entries...')
         oprogress.SetProgressRange(0, lnMax)

         SELECT importtemp
         SCAN

            SCATTER MEMVAR
            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               m.dgldate = CTOD(m.cgldate)
               IF EMPTY(m.dgldate) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dgldate = CTOD('12/30/1899') + INT(VAL(m.cgldate))
               ENDIF
               IF EMPTY(m.dgldate)
                  m.dgldate = DATE()
               ENDIF
            CATCH
               m.dgldate = DATE()
            ENDTRY

            TRY
               m.ndebits = VAL(m.cDebits)
            CATCH
               m.ndebits = 0
            ENDTRY

            TRY
               m.ncredits = VAL(m.cCredits)
            CATCH
               m.ncredits = 0
            ENDTRY

            IF NOT EMPTY(m.cAcctNo) AND (m.ndebits # 0 OR m.ncredits # 0)
               INSERT INTO importfile FROM MEMVAR
            ENDIF
         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildJournal', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn
*************************
   PROCEDURE BuildUnits
*************************
   LOCAL lnDefMax, llReturn, loError

   llReturn = .T.
   TRY
      IF EMPTY(THIS.cMapName)
         MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
         llReturn = .F.
         EXIT
      ENDIF
      SELECT ImportMap
      LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
      IF NOT FOUND()
         MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
         llReturn = .F.
         EXIT
      ENDIF
      lnDefMax = ALINES(laFields, mfields)
      FOR lnx = 1 TO lnDefMax
         lcFieldName  = "m.cm" + TRANSFORM(lnx)
         &lcFieldName = laFields[lnx]
      ENDFOR
      SELECT importfile
      SCATTER MEMVAR BLANK
      lnMax     = RECCOUNT('importtemp')
      lnCount   = 1
      oprogress = m.goapp.omessage.progressbar('Importing Program Units...')
      oprogress.SetProgressRange(0, lnMax)
      SELECT importtemp
      SCAN
         SCATTER MEMVAR
         oprogress.updateprogress(lnCount)
         lnCount = lnCount + 1
         swselect('importdefs')
         llError  = .F.
         llReturn = .T.
* Build the variables and store the correct column in them.
         FOR lnI = 1 TO lnDefMax
            lcVarName = "m.cm" + TRANSFORM(lnI)
            LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
            IF FOUND()
               SCATTER MEMVAR
               lcFieldName = "m.cf" + TRANSFORM(lnI)
               IF UPPER(LEFT(m.cname, 1)) = 'N'
                  STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                  STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
               ELSE
                  TRY
                     STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                  CATCH TO myError
                     IF FILE('datafiles\debugimport.txt')
                        IF myError.ERRORNO = 10
                           MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                              'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                              'm.cname: ' + m.cname + CHR(10) + ;
                              'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                        ENDIF
                        llReturn = .F.
                     ENDIF
                  ENDTRY
                  IF llReturn = .F.
                     EXIT
                  ENDIF
               ENDIF
            ENDIF
         ENDFOR
         TRY
            m.ddepositdate = CTOD(m.cdepositdate)
            IF EMPTY(m.ddepositdate) AND THIS.lXLSX
* Convert an Excel Number to a date format
               m.ddepositdate = CTOD('12/30/1899') + INT(VAL(m.cdepositdate))
            ENDIF
            IF EMPTY(m.ddepositdate)
               m.ddepositdate = DATE()
            ENDIF
         CATCH
            m.ddepositdate = DATE()
         ENDTRY
         TRY
            m.deffdate = CTOD(m.ceffdate)
            IF EMPTY(m.deffdate) AND THIS.lXLSX
* Convert an Excel Number to a date format
               m.deffdate = CTOD('12/30/1899') + INT(VAL(m.ceffdate))
            ENDIF
            IF EMPTY(m.deffdate)
               m.deffdate = DATE()
            ENDIF
         CATCH
            m.deffdate = DATE()
         ENDTRY
         TRY
            m.namount = VAL(m.camount)
         CATCH
            m.namount = 0
         ENDTRY
         TRY
            m.npercentage = VAL(m.cPercentage)
         CATCH
            m.npercentage = 0
         ENDTRY
         IF NOT EMPTY(m.cprogcode) AND NOT EMPTY(m.cownerid) AND m.npercentage # 0
            INSERT INTO importfile FROM MEMVAR
         ENDIF
      ENDSCAN
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'BuildJournal', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
      MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY
   TRY
      oprogress.closeprogress()
      oprogress = .NULL.
   CATCH
   ENDTRY
   RETURN llReturn
      *************************
   PROCEDURE BuildCusts
      *************************

      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         SELECT importtemp
         SCATTER MEMVAR BLANK

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Customers...')
         oprogress.SetProgressRange(0, lnMax)

         SELECT importtemp
         SCAN

            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               m.mcustnote = ALLTRIM(m.cCustNote)
            CATCH
               m.mcustnote = ''
            ENDTRY

            IF NOT EMPTY(m.ccustid)
               m.ccustid   = UPPER(ALLTRIM(m.ccustid))
               INSERT INTO importfile FROM MEMVAR
            ENDIF

         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildCusts', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn
      *************************
   PROCEDURE BuildVendors
      *************************

      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Vendors...')
         oprogress.SetProgressRange(0, lnMax)

         SELECT importtemp
         SCAN

            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               IF NOT EMPTY(m.csend1099) AND UPPER(m.csend1099) # 'N' AND NOT 'F' $ UPPER(m.csend1099)
                  m.lsend1099 = .T.
               ELSE
                  m.lsend1099 = .F.
               ENDIF
            CATCH
               m.lsend1099 = .F.
            ENDTRY

            TRY
               IF NOT EMPTY(m.ctaxidtype)
                  IF m.ctaxidtype = '1'
                     m.itaxidtype = 1
                  ELSE
                     m.itaxidtype = 2
                  ENDIF
               ELSE
                  m.itaxidtype = 2
               ENDIF
            CATCH
            ENDTRY

            TRY
               m.mvendnote = ALLTRIM(m.cvendnote)
            CATCH
               m.mvendnote = ''
            ENDTRY

            IF NOT EMPTY(m.cvendorid)
               m.cvendorid = UPPER(ALLTRIM(m.cvendorid))
               INSERT INTO importfile FROM MEMVAR
            ENDIF
         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildVendors', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn

      *************************
   PROCEDURE BuildCOA
      *************************

      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Accounts...')
         oprogress.SetProgressRange(0, lnMax)

         STORE '' TO m.cbankacct, m.cacctunit, m.cacctdept, m.crent1099

         SELECT importtemp
         SCAN

            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               m.naccttype = INT(VAL(m.caccttype))
            CATCH
               m.naccttype = 1
            ENDTRY

            IF NOT EMPTY(m.cbankacct) AND NOT 'N' $ UPPER(m.cbankacct) AND NOT 'F' $ UPPER(m.cbankacct)
               m.lbankacct = .T.
            ELSE
               m.lbankacct = .F.
            ENDIF

            IF NOT EMPTY(m.cacctunit) AND NOT 'N' $ UPPER(m.cacctunit) AND NOT 'F' $ UPPER(m.cacctunit)
               m.lacctunit = .T.
            ELSE
               m.lacctunit = .F.
            ENDIF

            IF NOT EMPTY(m.cacctdept) AND NOT 'N' $ UPPER(m.cacctdept) AND NOT 'F' $ UPPER(m.cacctdept)
               m.lacctdept = .T.
            ELSE
               m.lacctdept = .F.
            ENDIF

            IF NOT EMPTY(m.crent1099) AND NOT 'N' $ UPPER(m.crent1099) AND NOT 'F' $ UPPER(m.crent1099)
               m.lrent1099 = .T.
            ELSE
               m.lrent1099 = .F.
            ENDIF

            IF NOT EMPTY(m.cAcctNo) AND NOT EMPTY(m.cacctdesc)
               INSERT INTO importfile FROM MEMVAR
            ENDIF
         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildCOA', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn

      *************************
   PROCEDURE BuildExpCodes
      *************************

      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Expense Codes...')
         oprogress.SetProgressRange(0, lnMax)

         STORE '' TO m.ccatcode, m.ccateg, m.cdescrip, m.cExpClass

         SELECT importtemp
         SCAN

            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR


            IF NOT EMPTY(m.ccatcode)
               IF EMPTY(m.cdescrip)
                  m.cdescrip = m.ccateg
               ENDIF
               IF EMPTY(m.ctaxcode)
                  m.ctaxcode = 'OE'
               ENDIF
               m.ccatcode = UPPER(m.ccatcode)
               INSERT INTO importfile FROM MEMVAR
            ENDIF
         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildExpCodes', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn
      *************************
   PROCEDURE BuildPurchasers
      *************************

      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Purchasers...')
         oprogress.SetProgressRange(0, lnMax)

         STORE '' TO m.crevkey, m.crevname, m.caddress1, m.caddress2, m.caddress3, m.cphone, m.cfaxphone

         SELECT importtemp
         SCAN

            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            IF NOT EMPTY(m.crevkey) AND NOT EMPTY(m.crevname)
               m.crevkey = UPPER(ALLTRIM(m.crevkey))
               INSERT INTO importfile FROM MEMVAR
            ENDIF
         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildPurchasers', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn


      *************************
   PROCEDURE BuildMeters
      *************************

      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Meters...')
         oprogress.SetProgressRange(0, lnMax)

         STORE '' TO m.cMeterID, m.cmeterdesc

         SELECT importtemp
         SCAN

            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            IF NOT EMPTY(m.cMeterID) AND NOT EMPTY(m.cmeterdesc)
               m.cMeterID = UPPER(ALLTRIM(m.cMeterID))
               INSERT INTO importfile FROM MEMVAR
            ENDIF
         ENDSCAN

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildMeters', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn

      *************************
   PROCEDURE BuildPumpers
      *************************
      LOCAL lnDefMax, llReturn, loError
      llReturn = .T.
      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF
         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR
         SELECT importfile
         SCATTER MEMVAR BLANK
         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Meters...')
         oprogress.SetProgressRange(0, lnMax)
         STORE '' TO m.cName, m.caddress1, m.ccity, m.cstate, m.czip
         lnkey = 1
         SELECT importtemp
         SCAN
            SCATTER MEMVAR

            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1
            swselect('importdefs')
            llError  = .F.
            llReturn = .T.
            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR
            IF NOT EMPTY(m.cName) 
               m.cidpumper = GetNextPK('PUMPERS')
               INSERT INTO importfile FROM MEMVAR
            ENDIF
         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildMeters', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY
      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY
      RETURN llReturn
      *************************
   PROCEDURE BuildLand
      *************************
      LOCAL lnDefMax, llReturn, loError

      llReturn = .T.

      TRY
         IF EMPTY(THIS.cMapName)
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         SELECT ImportMap
         LOCATE FOR cType = THIS.cType AND cImportName = ALLTRIM(THIS.cMapName)
         IF NOT FOUND()
            MESSAGEBOX('A valid mapping file must be selected before choosing a file to import.', 16, 'Missing Map File')
            llReturn = .F.
            EXIT
         ENDIF

         lnDefMax = ALINES(laFields, mfields)
         FOR lnx = 1 TO lnDefMax
            lcFieldName  = "m.cm" + TRANSFORM(lnx)
            &lcFieldName = laFields[lnx]
         ENDFOR

         SELECT importfile
         SCATTER MEMVAR BLANK

         lnMax     = RECCOUNT('importtemp')
         lnCount   = 1
         oprogress = m.goapp.omessage.progressbar('Importing Leases...')
         oprogress.SetProgressRange(0, lnMax)

         SELECT importtemp
         SCAN

            SCATTER MEMVAR
            oprogress.updateprogress(lnCount)
            lnCount = lnCount + 1

            swselect('importdefs')

            llError  = .F.
            llReturn = .T.

            * Build the variables and store the correct column in them.
            FOR lnI = 1 TO lnDefMax
               lcVarName = "m.cm" + TRANSFORM(lnI)
               LOCATE FOR ALLTRIM(cDescript) == ALLTRIM(&lcVarName) AND cType = THIS.cType
               IF FOUND()
                  SCATTER MEMVAR
                  lcFieldName = "m.cf" + TRANSFORM(lnI)
                  IF UPPER(LEFT(m.cname, 1)) = 'N'
                     STORE STRTRAN(EVALUATE(lcFieldName), '$', '') TO (lcFieldName)
                     STORE STRTRAN(EVALUATE(lcFieldName), ',', '') TO (m.cname)
                  ELSE
                     TRY
                        STORE STRTRAN(EVALUATE(lcFieldName), '&amp;','&') TO (m.cname)
                     CATCH TO myError
                        IF FILE('datafiles\debugimport.txt')
                           IF myError.ERRORNO = 10
                              MESSAGEBOX('lcFieldname: ' + lcFieldName + CHR(10) + ;
                                 'EVAL(lcFieldName): ' + TRANSFORM(EVALUATE(lcFieldName)) + CHR(10) + ;
                                 'm.cname: ' + m.cname + CHR(10) + ;
                                 'EVAL(m.cname): ' + TRANSFORM(EVALUATE(m.cname)), 0, 'Debug')
                           ENDIF
                           llReturn = .F.
                        ENDIF
                     ENDTRY
                     IF llReturn = .F.
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDFOR

            TRY
               m.cleaseid   = ALLTRIM(UPPER(m.cleaseid))
               m.cleasename = ALLTRIM(m.cleasename)
            CATCH
            ENDTRY

            TRY
               m.cLeasestatus = ALLTRIM(m.cLeasestatus)
               IF NOT EMPTY(m.cLeasestatus)
                  IF NOT INLIST(UPPER(m.cLeasestatus),'ACTIVE',;
                        'PENDING', ;
                        'PD', ;
                        'EXPIRED',;
                        'HBP', ;
                        'PAID-UP', ;
                        'SOLD', ;
                        'MP', ;
                        'ROW', ;
                        'LA', ;
                        'PL', ;
                        'TB', ;
                        'IN', ;
                        'TA', ;
                        'TBE', ;
                        'MS')
                     m.cLeasestatus = 'Active'
                  ENDIF
               ELSE
                  m.cLeasestatus = 'Active'
               ENDIF
            CATCH
               m.cLeasestatus = 'Active'
            ENDTRY

            TRY
               m.mLegaldesc = m.cLegalDesc
            CATCH
               m.mLegaldesc = ''
            ENDTRY

            TRY
               m.dPmtstart = CTOD(m.cPmtStart)
               IF EMPTY(m.dPmtstart) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dPmtstart = CTOD('12/30/1899') + INT(VAL(m.cPmtStart))
               ENDIF
            CATCH
               m.dPmtstart = {}
            ENDTRY

            TRY
               m.dNextpmt = CTOD(m.cNextPmt)
               IF EMPTY(m.dNextpmt) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dNextpmt = CTOD('12/30/1899') + INT(VAL(m.cNextPmt))
               ENDIF
            CATCH
               m.dNextpmt = {}
            ENDTRY

            TRY
               m.dLeasedate = CTOD(m.cleasedate)
               IF EMPTY(m.dLeasedate) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dLeasedate = CTOD('12/30/1899') + INT(VAL(m.cleasedate))
               ENDIF
            CATCH
               m.dLeasedate = {}
            ENDTRY

            TRY
               m.dExpires = CTOD(m.cExpires)
               IF EMPTY(m.dExpires) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dExpires = CTOD('12/30/1899') + INT(VAL(m.dExpires))
               ENDIF
            CATCH
               m.dExpires = {}
            ENDTRY

            TRY
               m.dRecDate = CTOD(m.crecdate)
               IF EMPTY(m.dRecDate) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dRecDate = CTOD('12/30/1899') + INT(VAL(m.crecdate))
               ENDIF
            CATCH
               m.dRecDate = {}
            ENDTRY

            TRY
               m.dConsoldate = CTOD(m.cconsoldate)
               IF EMPTY(m.dConsoldate) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dConsoldate = CTOD('12/30/1899') + INT(VAL(m.cconsoldate))
               ENDIF
            CATCH
               m.dConsoldate = {}
            ENDTRY

            TRY
               m.dAcquired = CTOD(m.cacquiredd)
               IF EMPTY(m.dAcquired) AND THIS.lXLSX
                  * Convert an Excel Number to a date format
                  m.dAcquired = CTOD('12/30/1899') + INT(VAL(m.cacquiredd))
               ENDIF
            CATCH
               m.dAcquired = {}
            ENDTRY

            TRY
               m.nGrossacre = ConvertAmount(m.cGrossAcre )
            CATCH
               m.nGrossacre = 0
            ENDTRY

            TRY
               m.nNetacres = ConvertAmount(m.cNetAcres )
            CATCH
               m.nNetacres = 0
            ENDTRY

            TRY
               m.nNetdeep = ConvertAmount(m.cNetDeep )
            CATCH
               m.nNetdeep = 0
            ENDTRY

            TRY
               m.nLeaseyears = ConvertAmount(m.cLeaseYears )
            CATCH
               m.nLeaseyears = 0
            ENDTRY

            TRY
               m.nLeasemonths = ConvertAmount(m.cLeaseMonths)
            CATCH
               m.nLeasemonths = 0
            ENDTRY

            TRY
               m.nPartpct = ConvertAmount(m.cpartpct)
            CATCH
               m.nPartpct = 0
            ENDTRY

            TRY
               m.mComments = m.ccomments
            CATCH
               m.mComments = ''
            ENDTRY

            TRY
               m.mDescription = m.cdescription
            CATCH
               m.mDescription = ''
            ENDTRY

            TRY
               m.mRenewal = m.cRenewal
            CATCH
               m.mRenewal = ''
            ENDTRY

            IF NOT EMPTY(m.mRenewal)
               m.lRenewal = .T.
            ELSE
               m.lRenewal = .F.
            ENDIF

            TRY
               m.mPoolnotes = m.cPoolNotes
            CATCH
               m.mPoolnotes = ''
            ENDTRY

            IF NOT EMPTY(m.mPoolnotes)
               m.lPooling = .T.
            ELSE
               m.lPooling = .F.
            ENDIF

            TRY
               m.mDepthnotes = m.cDepthNotes
            CATCH
               m.mDepthnotes = ''
            ENDTRY

            IF NOT EMPTY(m.mDepthnotes)
               m.lDepthrestrict= .T.
            ELSE
               m.lDepthrestrict= .F.
            ENDIF

            TRY
               m.mShutnotes = m.cShutNotes
            CATCH
               m.mShutnotes = ''
            ENDTRY

            IF NOT EMPTY(m.mShutnotes)
               m.lShutin = .T.
            ELSE
               m.lShutin = .F.
            ENDIF

            TRY
               m.mOrrinotes = m.cORRINotes
            CATCH
               m.mOrrinotes = ''
            ENDTRY

            IF NOT EMPTY(m.mOrrinotes)
               m.lOrri = .T.
            ELSE
               m.lOrri = .F.
            ENDIF

            TRY
               m.mFreegas = m.cFreeGas
            CATCH
               m.mFreegas = ''
            ENDTRY

            IF NOT EMPTY(m.mFreegas)
               m.lFreegas = .T.
            ELSE
               m.lFreegas = .F.
            ENDIF

            TRY
               m.mContinuous = m.cContinuous
            CATCH
               m.mContinuous = ''
            ENDTRY

            IF NOT EMPTY(m.mContinuous)
               m.lContinuous = .T.
            ELSE
               m.lContinuious = .F.
            ENDIF

            TRY
               m.mUnitization = m.cUnitization
            CATCH
               m.mUnitization = ''
            ENDTRY

            IF NOT EMPTY(m.mUnitization)
               m.lUnitization = .T.
            ELSE
               m.lUnitization = .F.
            ENDIF

            TRY
               m.mLoapprove = m.cLOApprove
            CATCH
               m.mLoapprove = ''
            ENDTRY

            IF NOT EMPTY(m.mLoapprove)
               m.lLoapprove = .T.
            ELSE
               m.lLoapprove = .F.
            ENDIF

            TRY
               m.mAssignment = m.cAssignment
            CATCH
               m.mAssignment = ''
            ENDTRY

            IF NOT EMPTY(m.mAssignment)
               m.lAssignment = .T.
            ELSE
               m.lAssignment = .F.
            ENDIF

            TRY
               m.mParcel = m.cparcel
            CATCH
               m.mParcel = ''
            ENDTRY

            TRY
               IF NOT EMPTY(m.cDigitized) AND NOT 'N' $ UPPER(m.cDigitized) AND NOT 'F' $ UPPER(m.cDigitized)
                  STORE .T. TO m.lDigitized
               ELSE
                  STORE .F. TO m.lDigitized
               ENDIF
            CATCH
               STORE .F. TO m.lDigitized
            ENDTRY

            TRY
               IF NOT EMPTY(m.cLegalDisp) AND NOT 'N' $ UPPER(m.cLegalDisp) AND NOT 'F' $ UPPER(m.cLegalDisp)
                  STORE .T. TO m.lLegaldisp
               ELSE
                  STORE .F. TO m.lLegaldisp
               ENDIF
            CATCH
               STORE .F. TO m.lLegaldisp
            ENDTRY

            IF NOT EMPTY(m.cleaseid)
               INSERT INTO importfile FROM MEMVAR
            ENDIF

         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildLeases', loError.LINENO, 'SWFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      TRY
         oprogress.closeprogress()
         oprogress = .NULL.
      CATCH
      ENDTRY

      RETURN llReturn

      *************************
   PROCEDURE BuildCodes
      *************************
      LOCAL llReturn, lnCount, loError
      LOCAL ccode, x

      llReturn = .T.

      TRY
         * Build revenue import codes
         CREATE CURSOR oiltypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'OIL' OR cType = 'BBL'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO oiltypes FROM MEMVAR
            ENDFOR
         ENDIF

         CREATE CURSOR gastypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'GAS' OR cType = 'MCF'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO gastypes FROM MEMVAR
            ENDFOR
         ENDIF

         CREATE CURSOR othtypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'OTH' OR cType = 'NGL'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO othtypes FROM MEMVAR
            ENDFOR
         ENDIF

         * Build the adjustment codes
         CREATE CURSOR adjtypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'ADJ'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO adjtypes FROM MEMVAR
            ENDFOR
         ENDIF

         * Build the royalty codes
         CREATE CURSOR roytypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'ROY'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO roytypes FROM MEMVAR
            ENDFOR
         ENDIF

         * Build the workint int codes
         CREATE CURSOR wrktypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'WRK'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO wrktypes FROM MEMVAR
            ENDFOR
         ENDIF

         * Build the override int codes
         CREATE CURSOR ovrtypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'OVR'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO ovrtypes FROM MEMVAR
            ENDFOR
         ENDIF

         * Build the STAX codes
         CREATE CURSOR staxtypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'STAX'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO staxtypes FROM MEMVAR
            ENDFOR
         ENDIF

         * Build the PTAX codes
         CREATE CURSOR ptaxtypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'PTAX'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO ptaxtypes FROM MEMVAR
            ENDFOR
         ENDIF

         * Build the GTAX codes
         CREATE CURSOR gtaxtypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'GTAX'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO gtaxtypes FROM MEMVAR
            ENDFOR
         ENDIF

         * Build the OTAX codes
         CREATE CURSOR otaxtypes (ccode C(10))
         swselect('importtypes')
         LOCATE FOR cType = 'OTAX'
         IF FOUND()
            SELECT importtypes
            lnCount = GETWORDCOUNT(mtypes, ',')
            FOR x = 1 TO lnCount
               m.ccode = ALLTRIM(GETWORDNUM(ALLTRIM(mtypes), x, ','))
               INSERT INTO otaxtypes FROM MEMVAR
            ENDFOR
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildCodes', loError.LINENO, 'Import Revenue', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn

      **************************
   PROCEDURE CreateImportTemp
      **************************

      CREATE CURSOR importtemp ;
         (cf1              V(254), ;
         cf2              V(254), ;
         cf3              V(254), ;
         cf4              V(254), ;
         cf5              V(254), ;
         cf6              V(254), ;
         cf7              V(254), ;
         cf8              V(254), ;
         cf9              V(254), ;
         cf10             V(254), ;
         cf11             V(254), ;
         cf12             V(254), ;
         cf13             V(254), ;
         cf14             V(254), ;
         cf15             V(254), ;
         cf16             V(254), ;
         cf17             V(254), ;
         cf18             V(254), ;
         cf19             V(254), ;
         cf20             V(254), ;
         cf21             V(254), ;
         cf22             V(254), ;
         cf23             V(254), ;
         cf24             V(254), ;
         cf25             V(254), ;
         cf26             V(254), ;
         cf27             V(254), ;
         cf28             V(254), ;
         cf29             V(254), ;
         cf30             V(254), ;
         cf31             V(254), ;
         cf32             V(254), ;
         cf33             V(254), ;
         cf34             V(254), ;
         cf35             V(254), ;
         cf36             V(254), ;
         cf37             V(254), ;
         cf38             V(254), ;
         cf39             V(254), ;
         cf40             V(254), ;
         cf41             V(254), ;
         cf42             V(254), ;
         cf43             V(254), ;
         cf44             V(254), ;
         cf45             V(254), ;
         cf46             V(254), ;
         cf47             V(254), ;
         cf48             V(254), ;
         cf49             V(254), ;
         cf50             V(254), ;
         cf51             V(254), ;
         cf52             V(254), ;
         cf53             V(254), ;
         cf54             V(254), ;
         cf55             V(254), ;
         cf56             V(254), ;
         cf57             V(254), ;
         cf58             V(254), ;
         cf59             V(254), ;
         cf60             V(254), ;
         cf61             V(254), ;
         cf62             V(254), ;
         cf63             V(254), ;
         cf64             V(254), ;
         cf65             V(254), ;
         cf66             V(254), ;
         cf67             V(254), ;
         cf68             V(254), ;
         cf69             V(254), ;
         cf70             V(254), ;
         cf71             V(254), ;
         cf72             V(254), ;
         cf73             V(254), ;
         cf74             V(254), ;
         cf75             V(254), ;
         cf76             V(254), ;
         cf77             V(254), ;
         cf78             V(254), ;
         cf79             V(254), ;
         cf80             V(254), ;
         cf81             V(254), ;
         cf82             V(254), ;
         cf83             V(254), ;
         cf84             V(254), ;
         cf85             V(254), ;
         cf86             V(254), ;
         cf87             V(254), ;
         cf88             V(254), ;
         cf89             V(254), ;
         cf90             V(254), ;
         cf91             V(254), ;
         cf92             V(254), ;
         cf93             V(254), ;
         cf94             V(254), ;
         cf95             V(254), ;
         cf96             V(254), ;
         cf97             V(254), ;
         cf98             V(254), ;
         cf99             V(254), ;
         cf100            V(254), ;
         iRow             I)
      *************************
   PROCEDURE getworksheet
      *************************
      LPARAMETERS tcFileName, tlHeaderRow
      LOCAL lcFile, loText, loExcel AS 'vfpxworkbookxlsx'
      LOCAL loError, llReturn

      llReturn = .T.

      TRY

         lcFile = tcFileName
         lcExt  = UPPER(JUSTEXT(lcFile))

         IF UPPER(RIGHT(lcFile,3)) = 'XLS' OR ;
               UPPER(RIGHT(lcFile,4)) = 'XLSX'
            llXLSX = .T.
         ENDIF

         IF !EMPTY(lcFile)
            loExcel = NEWOBJECT("VFPxWorkbookXLSX", "custom\VFPxWorkbookXLSX.vcx")
            WAIT WINDOW NOWAIT 'Opening and reading workbook...Please wait...'
            lnWB = loExcel.OpenXlsxWorkbook(lcFile,.T.)
            WAIT CLEAR
            SELECT xl_workbooks
            GO TOP
            lnSheets = sheetcnt

            IF lnSheets > 1
               lnSheets = 1
               *!*	               MESSAGEBOX('Unable to import from a workbook with more than one worksheet at this time.' + CHR(10) + ;
               *!*	                    'Please save the sheet you want to import to a new workbook with that being ' + CHR(10) + ;
               *!*	                    'only sheet and try the import again.', 16, 'Too Many Sheets')
               *!*	               llReturn = .F.
               *!*	               EXIT
            ENDIF
            lnWorkBook    = workbook

            llHeaderRow = tlHeaderRow

            CREATE CURSOR worksheettemp ;
               (cf1              V(254), ;
               cf2              V(254), ;
               cf3              V(254), ;
               cf4              V(254), ;
               cf5              V(254), ;
               cf6              V(254), ;
               cf7              V(254), ;
               cf8              V(254), ;
               cf9              V(254), ;
               cf10             V(254), ;
               cf11             V(254), ;
               cf12             V(254), ;
               cf13             V(254), ;
               cf14             V(254), ;
               cf15             V(254), ;
               cf16             V(254), ;
               cf17             V(254), ;
               cf18             V(254), ;
               cf19             V(254), ;
               cf20             V(254), ;
               cf21             V(254), ;
               cf22             V(254), ;
               cf23             V(254), ;
               cf24             V(254), ;
               cf25             V(254), ;
               cf26             V(254), ;
               cf27             V(254), ;
               cf28             V(254), ;
               cf29             V(254), ;
               cf30             V(254), ;
               cf31             V(254), ;
               cf32             V(254), ;
               cf33             V(254), ;
               cf34             V(254), ;
               cf35             V(254), ;
               cf36             V(254), ;
               cf37             V(254), ;
               cf38             V(254), ;
               cf39             V(254), ;
               cf40             V(254), ;
               cf41             V(254), ;
               cf42             V(254), ;
               cf43             V(254), ;
               cf44             V(254), ;
               cf45             V(254), ;
               cf46             V(254), ;
               cf47             V(254), ;
               cf48             V(254), ;
               cf49             V(254), ;
               cf50             V(254), ;
               cf51             V(254), ;
               cf52             V(254), ;
               cf53             V(254), ;
               cf54             V(254), ;
               cf55             V(254), ;
               cf56             V(254), ;
               cf57             V(254), ;
               cf58             V(254), ;
               cf59             V(254), ;
               cf60             V(254), ;
               cf61             V(254), ;
               cf62             V(254), ;
               cf63             V(254), ;
               cf64             V(254), ;
               cf65             V(254), ;
               cf66             V(254), ;
               cf67             V(254), ;
               cf68             V(254), ;
               cf69             V(254), ;
               cf70             V(254), ;
               cf71             V(254), ;
               cf72             V(254), ;
               cf73             V(254), ;
               cf74             V(254), ;
               cf75             V(254), ;
               cf76             V(254), ;
               cf77             V(254), ;
               cf78             V(254), ;
               cf79             V(254), ;
               cf80             V(254), ;
               cf81             V(254), ;
               cf82             V(254), ;
               cf83             V(254), ;
               cf84             V(254), ;
               cf85             V(254), ;
               cf86             V(254), ;
               cf87             V(254), ;
               cf88             V(254), ;
               cf89             V(254), ;
               cf90             V(254), ;
               cf91             V(254), ;
               cf92             V(254), ;
               cf93             V(254), ;
               cf94             V(254), ;
               cf95             V(254), ;
               cf96             V(254), ;
               cf97             V(254), ;
               cf98             V(254), ;
               cf99             V(254), ;
               cf100            V(254), ;
               iRow             I)

            oprogress = m.goapp.omessage.progressbarex('Importing Worksheet')

            FOR lnx = 1 TO lnSheets
               SELECT MAX(cellrow) AS nRows FROM xl_cells WHERE SHEET = lnx INTO CURSOR temp
               lnRows = nRows
               oprogress.SetProgressRange(0,lnRows)
               IF llHeaderRow
                  lnStart = 2
               ELSE
                  lnStart = 1
               ENDIF
               FOR lnRow = lnStart TO lnRows
                  loRow = loExcel.GetSheetRowValues(lnWorkBook, lnx, lnRow)
                  oprogress.setprogressmessage('Row ' + TRANSFORM(lnRow))
                  oprogress.updateprogress(lnRow)
                  m.iRow = lnRow
                  FOR lnCol = 1 TO loRow.COUNT
                     lcVar = 'm.cf' + TRANSFORM(lnCol)
                     DO CASE
                        CASE ISNULL(loRow.VALUES[lnCol, 1])
                           &lcVar = ''
                        CASE loRow.VALUES[lnCol, 2] = 'D'
                           &lcVar = DTOC(loRow.VALUES[lnCol, 1])
                        CASE loRow.VALUES[lnCol, 2] = 'N'
                           &lcVar = TRANSFORM(loRow.VALUES[lnCol, 1], '999999999.9999')
                        OTHERWISE
                           &lcVar = TRANSFORM(loRow.VALUES[lnCol, 1])
                     ENDCASE
                  ENDFOR

                  INSERT INTO worksheettemp FROM MEMVAR
               ENDFOR
            ENDFOR
         ENDIF

         IF VARTYPE(oprogress) = 'O'
            oprogress.closeprogress()
            RELEASE oprogress
         ENDIF

         * Delete empty rows. We'll assume that if the first 10 columns are empty then the row is empty
         SELECT worksheettemp
         DELETE  FOR EMPTY(cf1) ;
            AND EMPTY(cf2) ;
            AND EMPTY(cf3) ;
            AND EMPTY(cf4) ;
            AND EMPTY(cf5) ;
            AND EMPTY(cf6) ;
            AND EMPTY(cf7) ;
            AND EMPTY(cf8) ;
            AND EMPTY(cf9) ;
            AND EMPTY(cf10)
      CATCH TO loError
         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(13) + 'Line: ' + TRANSFORM(loError.LINENO),16,'Excel Error')
      ENDTRY


      *!*	      IF llReturn
      *!*	         RETURN lnSheets
      *!*	      ELSE
      *!*	         RETURN -1
      *!*	      ENDIF

      RETURN llReturn

      ************************
   PROCEDURE createsheetcursors
      ************************
      LPARAMETERS tnSheets

      FOR lnx = 1 TO tnSheets
         lcCursorName = 'worksheet' + TRANSFORM(lnx)

         CREATE CURSOR (lcCursorName) ;
            (csheetname       C(20), ;
            cf1              V(254), ;
            cf2              V(254), ;
            cf3              V(254), ;
            cf4              V(254), ;
            cf5              V(254), ;
            cf6              V(254), ;
            cf7              V(254), ;
            cf8              V(254), ;
            cf9              V(254), ;
            cf10             V(254), ;
            cf11             V(254), ;
            cf12             V(254), ;
            cf13             V(254), ;
            cf14             V(254), ;
            cf15             V(254), ;
            cf16             V(254), ;
            cf17             V(254), ;
            cf18             V(254), ;
            cf19             V(254), ;
            cf20             V(254), ;
            cf21             V(254), ;
            cf22             V(254), ;
            cf23             V(254), ;
            cf24             V(254), ;
            cf25             V(254), ;
            cf26             V(254), ;
            cf27             V(254), ;
            cf28             V(254), ;
            cf29             V(254), ;
            cf30             V(254), ;
            cf31             V(254), ;
            cf32             V(254), ;
            cf33             V(254), ;
            cf34             V(254), ;
            cf35             V(254), ;
            cf36             V(254), ;
            cf37             V(254), ;
            cf38             V(254), ;
            cf39             V(254), ;
            cf40             V(254), ;
            cf41             V(254), ;
            cf42             V(254), ;
            cf43             V(254), ;
            cf44             V(254), ;
            cf45             V(254), ;
            cf46             V(254), ;
            cf47             V(254), ;
            cf48             V(254), ;
            cf49             V(254), ;
            cf50             V(254), ;
            cf51             V(254), ;
            cf52             V(254), ;
            cf53             V(254), ;
            cf54             V(254), ;
            cf55             V(254), ;
            cf56             V(254), ;
            cf57             V(254), ;
            cf58             V(254), ;
            cf59             V(254), ;
            cf60             V(254), ;
            cf61             V(254), ;
            cf62             V(254), ;
            cf63             V(254), ;
            cf64             V(254), ;
            cf65             V(254), ;
            cf66             V(254), ;
            cf67             V(254), ;
            cf68             V(254), ;
            cf69             V(254), ;
            cf70             V(254), ;
            cf71             V(254), ;
            cf72             V(254), ;
            cf73             V(254), ;
            cf74             V(254), ;
            cf75             V(254), ;
            cf76             V(254), ;
            cf77             V(254), ;
            cf78             V(254), ;
            cf79             V(254), ;
            cf80             V(254), ;
            cf81             V(254), ;
            cf82             V(254), ;
            cf83             V(254), ;
            cf84             V(254), ;
            cf85             V(254), ;
            cf86             V(254), ;
            cf87             V(254), ;
            cf88             V(254), ;
            cf89             V(254), ;
            cf90             V(254), ;
            cf91             V(254), ;
            cf92             V(254), ;
            cf93             V(254), ;
            cf94             V(254), ;
            cf95             V(254), ;
            cf96             V(254), ;
            cf97             V(254), ;
            cf98             V(254), ;
            cf99             V(254), ;
            cf100            V(254))

      ENDFOR

      ********************
   PROCEDURE CDEXValidation
      ********************
      LPARAMETERS tcFileName

      LOCAL lnResult, lcAlias, llError
      PRIV lcTitle1, lcTitle2, lcSortOrder, lcSelect, glGrpName, m.cGrpName, llPrinted

      m.cButton = 'S'

      lcAlias = ALIAS()

      STORE '' TO m.cGrpName

      IF NOT USED('compmast')
         USE (m.goapp.cCommonFolder+'compmast') IN 0
      ENDIF
      SELECT compmast
      LOCATE FOR cidcomp = m.goapp.cidcomp
      IF FOUND()
         m.cProcessor = cProcessor
      ELSE
         m.cProcessor = ""
      ENDIF

      m.goapp.oReport.cAlias = lcAlias
      m.goapp.oReport.cReportName = THISFORM.cReportName
      m.goapp.oReport.cTitle1 = THISFORM.cTitle1
      m.goapp.oReport.cTitle2 = THISFORM.cTitle2
      m.goapp.oReport.cProcessor = m.cProcessor
      m.goapp.oReport.cSortOrder = THISFORM.cSortOrder
      m.goapp.oReport.cSelectionCriteria = THISFORM.cselectcriteria
      m.goapp.oReport.CSVFilename = THIS.CSVFilename

      IF NOT EMPTY(THISFORM.cFriendlyName)
         m.goapp.oReport.cFriendlyName = THISFORM.cFriendlyName
      ELSE
         m.goapp.oReport.cFriendlyName = THISFORM.CAPTION
      ENDIF

      llReturn = m.goapp.oReport.SendReport(m.cButton, llFile, IIF(NOT EMPTY(m.cGrpName),m.cGrpName,.F.))

   ENDPROC

   ****************************
   PROCEDURE BuildReceipt
      ****************************
      LPARAMETERS tcCashAcct, tcPurchID, tdCheckDate

      LOCAL llReturn, loError
      LOCAL lPostToQB, lcMessage, lcMessage2, lnBadRecs, lnTotal, lnTotalcks, lnDeducts
      LOCAL cBatch, cOwnType, cProdYear, cType, ccashacct, cDesc, cleasename, cname, copername
      LOCAL cProdPeriod, ddate, dentdate, ileasespk, ioperatorpk, nNetUnits, nprice
      LOCAL lcRevClear, lcExpClear

      lnBadRecs = 0
      llReturn  = .T.
      STORE '' TO m.cProdPeriod, m.cProdYear

      TRY

         swselect('glopt')
         GO TOP
         lcRevClear = cRevClear
         lcExpClear = cExpClear
         STORE '' TO lcMessage2, m.ccashacct, m.cType
         lcMapName = tcImportMapName


         * Create cursor for bad detail lines
         CREATE CURSOR baddetail ;
            (cWellID    C(20), ;
            cWellname  C(40), ;
            cprodcode  C(7), ;
            cCheckno   C(14), ;
            cDesc      C(40))

         * Create cursors for all the revenue and adjustment codes
         llReturn = THIS.BuildCodes()

         m.cUser		   = m.goapp.cUser
         m.dlastmodified = DATETIME()

         * Fill in check date if missing
         IF VARTYPE(tdCheckDate) = 'D'
            SELECT importfile
            REPLACE dCheckDate WITH tdCheckDate, ;
               dPostDate  WITH tdCheckDate  ALL
         ELSE
            SELECT importfile
            LOCATE FOR NOT EMPTY(dCheckDate)
            IF NOT FOUND()
               MESSAGEBOX('There was not a check date column in the import and the option to use the ' + ;
                  'shown date instead of the check date was not chosen. Please correct.', 64, 'Missing Checkdate')
               llReturn = .F.
               EXIT
            ENDIF
         ENDIF

         SELECT importfile
         REPLACE dPostDate WITH dCheckDate FOR EMPTY(dPostDate)
         REPLACE cCheckno WITH DTOC(dCheckDate) FOR EMPTY(cCheckno)

         * Get a total for each check in the import
         SELECT  cCheckno,;
            dCheckDate,;
            dPostDate,;
            SPACE(8) AS cBatch,;
                 SUM(nTotalInc - nTax - nDeducts-ndeducts2-ndeducts3-ndeducts4-ndeducts5) AS nCashAmt ;
            FROM importfile ;
            WHERE NOT EMPTY(dCheckDate) ;
            AND NOT EMPTY(cWellID) ;
            INTO CURSOR curNewChecks READWRITE ;
            ORDER BY cCheckno, dCheckDate, dPostDate ;
            GROUP BY cCheckno, dCheckDate, dPostDate

         IF _TALLY = 0
            llReturn = .F.
            MESSAGEBOX('No valid records found in the import.', 16, 'No Records')
            EXIT
         ENDIF

         SELECT curNewChecks
         SCAN
            SCATTER MEMVAR

            DO CASE
               CASE m.goapp.lAMVersion
                  m.ccashacct = tcCashAcct
               CASE m.goapp.lQBVersion
                  m.ccashacct = tcCashAcct
               OTHERWISE
                  m.ccashacct = ''
            ENDCASE

            m.cBatch    = m.goapp.oRegistry.IncrementCounter('%Shared.Counters.Batch')
            lcBatch     = m.cBatch

            SELECT curNewChecks
            REPLACE cBatch WITH lcBatch

            IF VARTYPE(tdCheckDate) = 'D'
               m.ddate    = tdCheckDate
            ELSE
               m.ddate    = m.dCheckDate
            ENDIF

            IF EMPTY(m.dPostDate)
               m.dPostDate = m.ddate
            ENDIF

            m.dentdate = DATE()

            IF VARTYPE(m.ddate) # 'D'
               MESSAGEBOX('An invalid date was found in the import for check no: ' + ALLTRIM(m.cCheckno) + ;
                  '. Using todays date instead. Correct in Production Receipts after this import.', 16, 'Bad Date')
               m.ddate = DATE()
            ENDIF
            IF NOT BETWEEN(m.ddate, {01/01/1980}, {12/31/2020})
               MESSAGEBOX('An invalid date was found in the import for check no: ' + ALLTRIM(m.cCheckno) + ;
                  '. Using todays date instead. Correct in Production Receipts after this import.', 16, 'Bad Date')
               m.ddate = DATE()
            ENDIF

            m.cid = tcPurchID

            swselect('revsrc')
            LOCATE FOR crevkey = ALLTRIM(tcPurchID)
            IF FOUND()
               m.cname = revsrc.crevname
               m.cid   = revsrc.crevkey
            ELSE
               MESSAGEBOX('An invalid purchaser ID code was passed to BuildReceipt. Unable to continue.',16,'Building Receipt from Import File')
               llReturn = .F.
               EXIT
            ENDIF

            m.cBatch = lcBatch
            INSERT INTO csrcthdr FROM MEMVAR

            lcLastProdType = ''
            m.lWellRcpt	 = .F.
            SELECT importfile
            SCAN FOR cCheckno = m.cCheckno AND dPostDate = m.dPostDate
               SCATTER MEMVAR
               m.cProdType   = UPPER(ALLTRIM(m.cProdType))
               m.cWellID	   = PADR(ALLTRIM(UPPER(m.cWellID)), 20, ' ')
               IF NOT EMPTY(m.cProdPeriod)
                  m.cProdPeriod = PADL(ALLTRIM(m.cProdPeriod), 2, '0')
               ENDIF
               m.namount	   = m.nTotalInc

               IF NOT EMPTY(m.cWellID)
                  swselect('wells')
                  LOCATE FOR (cPropNo == m.cWellID) OR ;
                     (coilpurchno == m.cWellID) OR ;
                     (cgaspurchno == m.cWellID) OR ;
                     (cothpurchno == m.cWellID) OR ;
                     (cWellID == LEFT(m.cWellID, 10))
                  IF FOUND()
                     m.cWellname = cWellname
                     m.cDesc	   = m.cWellname
                     m.cAcctNo   = lcRevClear
                     m.cWellID   = cWellID
                     m.lWellRcpt = .T.
                     IF wells.cWellID # ALLTRIM(m.cWellID)
                        m.cWellID = wells.cWellID
                     ENDIF

                     swselect('revcat')
                     LOCATE FOR crevtype = PADR(ALLTRIM(m.cProdType), 5, ' ')
                     IF NOT FOUND()
                        swselect('expcat')
                        LOCATE FOR UPPER(ccatcode) = PADR(ALLTRIM(m.cProdType), 4, ' ')
                        IF FOUND()
                           m.cType   = ccatcode
                           m.cAcctNo = lcExpClear
                        ELSE
                           lcCode = THIS.FindCode(m.cProdType)
                           IF INLIST(lcCode,'BBL','MCF','OTH','MISC1','MISC2','TRP')
                              m.cType = lcCode
                              m.cAcctNo = lcRevClear
                           ELSE
                              SELECT gastypes
                              LOCATE FOR UPPER(ccode) = m.cProdType
                              IF FOUND()
                                 m.cType		= 'MCF'
                                 m.cProdType	= m.cType
                                 m.cAcctNo	= lcRevClear
                              ELSE
                                 SELECT oiltypes
                                 LOCATE FOR UPPER(ccode) = m.cProdType
                                 IF FOUND()
                                    m.cType	   = 'BBL'
                                    m.cProdType = m.cType
                                    m.cAcctNo   = lcRevClear
                                 ELSE
                                    SELECT othtypes
                                    LOCATE FOR UPPER(ccode) = m.cProdType
                                    IF FOUND()
                                       m.cType	  = 'OTH'
                                       m.cProdType = m.cType
                                       m.cAcctNo	  = lcRevClear
                                    ELSE
                                       SELECT gtaxtypes
                                       LOCATE FOR UPPER(ccode) = m.cProdType
                                       IF FOUND()
                                          m.cType	 = 'GTAX1'
                                          m.cProdType = m.cType
                                          m.cAcctNo	 = lcRevClear
                                       ELSE
                                          SELECT otaxtypes
                                          LOCATE FOR UPPER(ccode) = m.cProdType
                                          IF FOUND()
                                             m.cType		= 'OTAX1'
                                             m.cProdType	= m.cType
                                             m.cAcctNo	= lcRevClear
                                          ELSE
                                             SELECT ptaxtypes
                                             LOCATE FOR UPPER(ccode) = m.cProdType
                                             IF FOUND()
                                                m.cType	   = 'PTAX1'
                                                m.cProdType = m.cType
                                                m.cAcctNo   = lcRevClear
                                             ELSE
                                                IF m.nTotalInc # 0
                                                   MESSAGEBOX('An invalid revenue code was found in the import for check no: ' + ALLTRIM(m.cCheckno) + ;
                                                      '. The code found is: ' + CHR(10) + CHR(10) + ;
                                                      m.cProdType + CHR(10) + CHR(10) + ;
                                                      'Please add this code to the appropriate revenue type in the import ' + ;
                                                      'code mapping and then try the import again.', 16, 'Invalid Revenue Code')
                                                   llReturn = .F.
                                                   EXIT
                                                ENDIF
                                             ENDIF
                                          ENDIF
                                       ENDIF
                                    ENDIF
                                 ENDIF
                              ENDIF
                           ENDIF
                        ENDIF
                     ELSE
                        m.cAcctNo	  = lcRevClear
                        m.cType	  = ALLTRIM(m.cProdType)
                        m.lWellRcpt = .F.
                     ENDIF
                  ELSE
                     m.cprodcode = m.cType
                     m.cDesc	   = 'Property No: ' + ALLTRIM(m.cWellID) + ' was not found.'
                     INSERT INTO baddetail FROM MEMVAR
                     lnBadRecs = lnBadRecs + 1
                  ENDIF

                  IF NOT llReturn
                     EXIT
                  ENDIF

                  IF EMPTY(m.cProdYear) AND NOT EMPTY(m.dProdDate)
                     m.cProdYear	 = TRANSFORM(YEAR(m.dProdDate))
                     m.cProdPeriod = PADL(TRANSFORM(MONTH(m.dProdDate)), 2, '0')
                  ENDIF

                  IF 'TAX' $ m.cType
                     m.nprice	= 0
                     m.nUnits	= 0
                  ELSE
                     IF m.nprice = 0
                        IF m.nUnits <> 0
                           m.nprice    = m.nTotalInc / m.nUnits
                        ELSE
                           m.nprice = 0
                        ENDIF
                     ENDIF
                  ENDIF

                  IF NOT EMPTY(m.cDesc) AND m.namount # 0
                     m.cidRctD   = GetNextPK('CSRCTDET')
                     m.lWellRcpt = .T.
                     m.cBatch = lcBatch
                     INSERT INTO csrctdet FROM MEMVAR
                  ENDIF

                  IF m.nTax # 0
                     m.namount = m.nTax * -1
                     m.cType	 = '**'
                     IF NOT EMPTY(m.cTaxType)
                        SELECT otaxtypes
                        LOCATE FOR UPPER(ccode) = m.cProdType
                        IF FOUND()
                           m.cType   = 'OTAX1'
                           m.cAcctNo = lcRevClear
                        ELSE
                           SELECT gtaxtypes
                           LOCATE FOR UPPER(ccode) = m.cProdType
                           IF FOUND()
                              m.cType	  = 'GTAX1'
                              m.cAcctNo = lcRevClear
                           ELSE
                              SELECT ptaxtypes
                              LOCATE FOR UPPER(ccode) = m.cProdType
                              IF FOUND()
                                 m.cType	 = 'PTAX1'
                                 m.cAcctNo = lcRevClear
                              ELSE
                                 SELECT revcat
                                 LOCATE FOR UPPER(crevtype) = ALLTRIM(m.cTaxType)
                                 IF FOUND()
                                    m.cType	= crevtype
                                    m.cAcctNo	= lcRevClear
                                 ELSE
                                    m.cprodcode = m.cTaxType
                                    m.cDesc	  = 'Tax Type: ' + ALLTRIM(m.cTaxType) + ' not valid.'
                                    INSERT INTO baddetail FROM MEMVAR
                                    lnBadRecs = lnBadRecs + 1
                                 ENDIF
                              ENDIF
                           ENDIF
                        ENDIF
                     ELSE
                        DO CASE
                           CASE m.cProdType = 'BBL'
                              m.cType = 'OTAX1'
                           CASE m.cProdType = 'MCF'
                              m.cType = 'GTAX1'
                           CASE m.cProdType = 'OTH'
                              m.cType = 'PTAX1'
                           OTHERWISE
                              m.cType = 'GTAX4'
                        ENDCASE
                     ENDIF
                     IF m.cType # '**'
                        m.cidRctD	  = GetNextPK('CSRCTDET')
                        m.lWellRcpt = .T.
                        STORE 0 TO m.nprice, m.nUnits
                        m.cBatch = lcBatch
                        INSERT INTO csrctdet FROM MEMVAR
                     ENDIF
                  ENDIF

                  IF m.nDeducts # 0
                     m.namount   = m.nDeducts * -1
                     m.cidRctD   = GetNextPK('CSRCTDET')
                     m.lWellRcpt = .T.
                     IF NOT EMPTY(m.cDedCode)
                        swselect('expcat')
                        LOCATE FOR ccatcode = ALLTRIM(m.cDedCode)
                        IF FOUND()
                           m.cAcctNo = lcExpClear
                           m.cType   = ALLTRIM(m.cDedCode)
                           STORE 0 TO m.nprice, m.nUnits
                           m.cBatch = lcBatch
                           INSERT INTO csrctdet FROM MEMVAR
                        ELSE
                           swselect('importtypes')
                           LOCATE FOR ALLTRIM(UPPER(m.cDedCode)) $ mtypes
                           IF FOUND()
                              m.cType	  = cType
                              m.cAcctNo = lcExpClear
                              STORE 0 TO m.nprice, m.nUnits
                              swselect('expcat')
                              LOCATE FOR ccatcode = ALLTRIM(m.cType)
                              IF FOUND()
                                 m.cAcctNo = lcExpClear
                                 STORE 0 TO m.nprice, m.nUnits
                                 m.cBatch = lcBatch
                                 INSERT INTO csrctdet FROM MEMVAR
                              ELSE
                                 SELECT revcat
                                 LOCATE FOR crevtype = ALLTRIM(m.cType)
                                 IF FOUND()
                                    m.cAcctNo = lcRevClear
                                    STORE 0 TO m.nprice, m.nUnits
                                    m.cBatch = lcBatch
                                    INSERT INTO csrctdet FROM MEMVAR
                                 ELSE
                                    m.cprodcode = m.cType
                                    m.cDesc	   = 'Deduction Code: ' + ALLTRIM(m.cType) + ' not valid.'
                                    INSERT INTO baddetail FROM MEMVAR
                                    lnBadRecs = lnBadRecs + 1
                                 ENDIF
                              ENDIF
                           ELSE
                              m.cprodcode	= m.cDedCode
                              m.cDesc		= 'Deduction Code: ' + ALLTRIM(m.cDedCode) + ' not valid.'
                              INSERT INTO baddetail FROM MEMVAR
                              lnBadRecs = lnBadRecs + 1
                           ENDIF
                        ENDIF
                     ELSE
                        swselect('importtypes')
                        LOCATE FOR 'OD' $ mtypes
                        IF FOUND()
                           m.cType   = cType
                           m.cAcctNo = lcExpClear
                           STORE 0 TO m.nprice, m.nUnits
                           swselect('expcat')
                           LOCATE FOR ccatcode = ALLTRIM(m.cType)
                           IF FOUND()
                              m.cAcctNo = lcExpClear
                              STORE 0 TO m.nprice, m.nUnits
                              m.cBatch = lcBatch
                              INSERT INTO csrctdet FROM MEMVAR
                           ELSE
                              m.cprodcode	= m.cType
                              m.cDesc		= 'Deduction Code: ' + ALLTRIM(m.cType) + ' not valid.'
                              INSERT INTO baddetail FROM MEMVAR
                              lnBadRecs = lnBadRecs + 1
                           ENDIF
                        ELSE
                           m.cprodcode = m.cDedCode
                           m.cDesc	 = 'Deduction Code: ' + ALLTRIM(m.cDedCode) + ' not valid.'
                           INSERT INTO baddetail FROM MEMVAR
                           lnBadRecs = lnBadRecs + 1
                        ENDIF
                     ENDIF
                  ENDIF
               ELSE
                  IF NOT EMPTY(m.cDesc) AND m.namount # 0
                     m.cidRctD   = GetNextPK('CSRCTDET')
                     m.lWellRcpt = .F.
                     m.cBatch = lcBatch
                     INSERT INTO csrctdet FROM MEMVAR
                  ENDIF
               ENDIF
            ENDSCAN && importfile
         ENDSCAN &&cshdr

         * Inform about any recs that couldn't be imported
         IF lnBadRecs > 0
            lcMessage = "There were " + TRANSFORM(lnBadRecs) + " detail lines that could not be imported." + CHR(10) + ;
               "The rows that couldn't be imported: " + CHR(10)

            SELECT cCheckno, cWellID FROM baddetail INTO CURSOR temp ORDER BY cWellID, cCheckno GROUP BY cWellID, cCheckno
            SELECT temp
            SCAN
               SCATTER MEMVAR
               lcMessage2 = lcMessage2 + 'Property: ' + m.cWellID + ' Check No: ' + m.cCheckno + CHR(10)
            ENDSCAN
            MESSAGEBOX(lcMessage + lcMessage2, 48, 'Import Problems')
            IF MESSAGEBOX('Do you want to print this list of import problems?', 36, 'Import Problems') = 6
               SELECT  cCheckno, ;
                       cWellname, ;
                       cprodcode, ;
                       cWellID, ;
                       cDesc ;
                   FROM baddetail ;
                   INTO CURSOR temp ;
                  ORDER BY cWellID, cCheckno ;
                  GROUP BY cWellID, cprodcode, cCheckno, cDesc
               REPORT FORM baddetail TO PRINTER PROMPT PREVIEW
            ENDIF
            IF MESSAGEBOX('Do you want to continue the import?', 36, 'Continue Import') = 7
               llReturn = .F.
            ENDIF

         ENDIF

         IF llReturn
            llReturn = PostIncome(m.cBatch)
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildReceipt', loError.LINENO, 'Import Revenue', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn

     *****************************
   PROCEDURE ImportEnergyLink
      *****************************
      LPARAMETERS lcFileName, lcType, lcCashAcct, lnDataSession, llDontPost
      LOCAL lnDefMax, llXLSX

      llXLSX        = .F.
      THIS.cType    = lcType

      IF EMPTY(lcFileName)
         MESSAGEBOX('Invalid or blank file name sent to IMPORTCSV', 0, 'Invalid File')
         RETURN .F.
      ENDIF
      IF NOT FILE(lcFileName)
         MESSAGEBOX('Invalid file chosen to import. Please select another file.',16,'Import Data')
         RETURN .F.
      ENDIF

      IF 'XLS' $ UPPER(JUSTEXT(lcFileName))
         llXLSX = .T.
      ENDIF

      THIS.lXLSX = llXLSX

      llReturn = .T.

      TRY

         IF VARTYPE(lnDataSession) = 'N'
            SET DATASESSION TO lnDataSession
         ENDIF

         THIS.CreateImportTemp()

         DO CASE
            CASE lcType = 'REV'
               THIS.CreateEnergyLinkRevFile()

            CASE lcType = 'EXP'
               THIS.CreateEnergyLinkExpFile()

            OTHERWISE
               THIS.CreateEnergyLinkRevFile()

         ENDCASE

         IF llXLSX
            SET EXACT OFF
         IF lcType = 'REV'
            llReturn =  THIS.getworksheet(lcFileName, .T.)
         ELSE
            llReturn =  THIS.getworksheet(lcFileName, .F.)
         ENDIF    
            IF llReturn
               SELECT worksheettemp
               SCAN
                  SCATTER MEMVAR
                  INSERT INTO importtemp FROM MEMVAR
               ENDSCAN
            ELSE
               EXIT
            ENDIF
         ELSE
            SELECT importtemp
            APPEND FROM (lcFileName) TYPE CSV
         ENDIF

         STORE '' TO m.cm1, m.cm2, m.cm3, m.cm4, m.cm5, m.cm6
         STORE '' TO m.cm7, m.cm8, m.cm9, m.cm10, m.cm11, m.cm12
         STORE '' TO m.cm13, m.cm14, m.cm15, m.cm16, m.cm17, m.cm18
         STORE '' TO m.cm19, m.cm20, m.cm21, m.cm22, m.cm23, m.cm24
         STORE '' TO m.cm25, m.cm26, m.cm27, m.cm28, m.cm29, m.cm30
         STORE '' TO m.cm31, m.cm32, m.cm33, m.cm34, m.cm35, m.cm36, m.cm37
         STORE '' TO m.cm38, m.cm39, m.cm40, m.cm41, m.cm42, m.cm42, m.cm43
         STORE '' TO m.cm44, m.cm45, m.cm46, m.cm47, m.cm48, m.cm49, m.cm49
         STORE '' TO m.cm50, m.cm51, m.cm52, m.cm53, m.cm54, m.cm55, m.cm56, m.cm57
         STORE {} TO m.dduedate, m.dinvdate, m.dProdDate
         STORE '' TO m.crectype, m.cCheckno, m.cCheckDate, m.cPropNo
         STORE '' TO m.cPropName, m.cPropState, m.cPropCounty, m.cProdDate, m.cProdType
         STORE '' TO m.cIntType, m.cPrice, m.cgrossvol, m.cGrossVal, m.cgrosstax1, m.cgrosstax2, m.cgrosstax3, m.cgrosstax4, m.cownroychg
         STORE '' TO m.cgrossnet, m.cInterest, m.cintpaid, m.cowngross, m.cowntax1, m.cowntax2, m.cowntax3, m.cowntax4, m.cownnet, m.cbtufact
         STORE '' TO m.cowndeducts1, m.cAdjCode, m.cUnused, m.cWithhold1, m.cWithhold2, m.cWithhold3, m.cWithhold4, m.cCheckAmt
         STORE '' TO m.cowndeducts1, m.cowndeducts2, m.cowndeducts3, m.cowndeducts4, m.cgrossdeducts1, m.cgrossdeducts2, m.cgrossdeducts3
         STORE '' TO m.cgrossdeducts4, m.cnetvol, m.cPrice, m.cinvdate, m.cduedate, m.cinvnum, m.cInterest
         STORE '' TO m.cExpCode1, m.cExpCode2, m.cExpCode3, m.cExpCode4, m.cExpCode5, m.cExpCode6
         STORE '' TO m.cExpDesc1, m.cExpDesc2, m.cExpDesc3, m.cExpDesc4, m.cExpDesc5, m.cExpDesc6
         STORE '' TO m.cgrossval1, m.cgrossval2, m.cgrossval3, m.cgrossval4, m.cgrossval5, m.cgrossval6
         STORE '' TO m.cownernet1, m.cownernet2, m.cownernet3, m.cownernet4, m.cownernet5, m.cownernet6

         lcBatch = '********'

         SELECT importfile
         SCATTER MEMVAR BLANK

         DO CASE
            CASE lcType = 'REV'
               llReturn = THIS.Load_EL_ImportFile_Rev()
               lcBatch  = THIS.ProcessEnergyLinkRev(lcCashAcct, llDontPost)

            CASE lcType = 'EXP'
               llReturn = THIS.Load_EL_ImportFile_Exp()
               lcBatch  = THIS.ProcessEnergyLinkExp(.F., llDontPost)

            OTHERWISE
               MESSAGEBOX('Invalid Type passed to ImportEnergyLink method.',16,'ImportEnergyLink')
               llReturn = .F.
               EXIT
         ENDCASE

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'ImportMap', loError.LINENO, 'swFile', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to import the mapped file at this time. Check the System Log found under Help for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      IF USED('importfile')
      SELECT importfile
      COUNT FOR NOT DELETED() TO lnCount
      ELSE
         lnCount = 0
      ENDIF    

      IF lnCount = 0
         MESSAGEBOX('Nothing imported from file: ' + ALLTRIM(lcFileName) + '. Check the file to make sure it is a valid SherWare Energy Link Voucher.', 48, 'Import Failure')
         RETURN .F.
      ENDIF

      RETURN lcBatch

      ***************************
   PROCEDURE CreateEnergyLinkRevFile
      ***************************


      CREATE CURSOR importfile ;
         ( iRow            I, ;
         cCheckno        C(10), ;
         dCheckDate      D, ;
         nCheckAmt       N(12,2), ;
         cpartnercc      C(20), ;
         cPropName       C(40), ;
         dPostDate       D, ;
         dProdDate       D, ;
         cProdYear       C(4), ;
         cProdPeriod     C(2), ;
         cProdType       C(5), ;
         cProdDesc       C(20), ;
         cIntType        C(4), ;
         nownpct         N(13,8), ;
         npaidpct        N(13,8), ;
         nGrossVol       N(12,2), ;
         nGrossVal       N(12,2), ;
         nGrossTax       N(12,2), ;
         nGrossDeducts   N(12,2), ;
         nPropNet        N(12,2), ;
         nprice          N(12, 6), ;
         nOwnVol         N(12, 2), ;
         nOwnVal         N(12, 2), ;
         nowntax         N(12, 2), ;
         nowndeducts     N(12, 2), ;
         nownnet         N(12, 2), ;
         ctaxcode1       C(5), ;
         ngrosstax1      N(12,2), ;
         nowntax1        N(12,2), ;
         ctaxcode2       C(5), ;
         ngrosstax2      N(12,2), ;
         nowntax2        N(12,2), ;
         ctaxcode3       C(5), ;
         ngrosstax3      N(12,2), ;
         nowntax3        N(12,2), ;
         ctaxcode4       C(5), ;
         ngrosstax4      N(12,2), ;
         nowntax4        N(12,2), ;
         ctaxcode5       C(5), ;
         ngrosstax5      N(12,2), ;
         nowntax5        N(12,2), ;
         ctaxcode6       C(5), ;
         ngrosstax6      N(12,2), ;
         nowntax6        N(12,2), ;
         ctaxcode7       C(5), ;
         ngrosstax7      N(12,2), ;
         nowntax7        N(12,2), ;
         ctaxcode8       C(5), ;
         ngrosstax8      N(12,2), ;
         nowntax8        N(12,2), ;
         ctaxcode9       C(5), ;
         ngrosstax9      N(12,2), ;
         nowntax9        N(12,2), ;
         ctaxcode10      C(5), ;
         ngrosstax10     N(12,2), ;
         nowntax10       N(12,2), ;
         cDeductcode1       C(5), ;
         ngrossDeduct1      N(12,2), ;
         nownDeduct1        N(12,2), ;
         cDeductcode2       C(5), ;
         ngrossDeduct2      N(12,2), ;
         nownDeduct2        N(12,2), ;
         cDeductcode3       C(5), ;
         ngrossDeduct3      N(12,2), ;
         nownDeduct3        N(12,2), ;
         cDeductcode4       C(5), ;
         ngrossDeduct4      N(12,2), ;
         nownDeduct4        N(12,2), ;
         cDeductcode5       C(5), ;
         ngrossDeduct5      N(12,2), ;
         nownDeduct5        N(12,2), ;
         cDeductcode6       C(5), ;
         ngrossDeduct6      N(12,2), ;
         nownDeduct6        N(12,2), ;
         cDeductcode7       C(5), ;
         ngrossDeduct7      N(12,2), ;
         nownDeduct7        N(12,2), ;
         cDeductcode8       C(5), ;
         ngrossDeduct8      N(12,2), ;
         nownDeduct8        N(12,2), ;
         cDeductcode9       C(5), ;
         ngrossDeduct9      N(12,2), ;
         nownDeduct9        N(12,2), ;
         cDeductcode10      C(5), ;
         ngrossDeduct10     N(12,2), ;
         nownDeduct10       N(12,2), ;
         cOperCode          C(10))

     ***************************
   PROCEDURE CreateEnergyLinkExpFile
      ***************************

      CREATE CURSOR importfile ;
         ( iRow            I, ;
         cOperName       C(60), ;
         cOperCode       C(10), ;
         cOperNo         C(20), ;
      cWellID         C(20), ;
         cPropName       C(40), ;
         dinvdate        D, ;
         cinvnum         C(20), ;
         dproddate       D, ;
         ninterest       n(13,8), ;
         cmajordesc      C(30), ;
         cMinorDesc      C(30), ;
      ccatcode        C(20), ;
         ngrossval       N(12,2), ;
         nownval         N(12,2))
         
 
      *******************************
   PROCEDURE ProcessEnergyLinkExp
      *******************************
      LPARAMETERS llOneInvoice, llDontPost
      LOCAL llReturn, loError
      LOCAL lcMessage, lcMessage2, lnBadRecs, lnTotal, lnTotalcks
      LOCAL lcTaxType, llFoundLease, lnBillAmt, lnCount
      LOCAL ccatcode, ccode, cExpCode, cExpDesc1, cExpDesc2, cExpDesc3, cExpDesc6, cidterm
      LOCAL cinvtype, citemdesc, cponumber, cprodcode, creference, cWellID, ddiscdate, dinvdate
      LOCAL dPostDate, iappurchhpk, mnotes, nExtension, nSubTotal, ninvbal, npayments, x
      LOCAL cBatch, cOwnType, cProdYear, cType, ccashacct, cDesc, cleasename, cname, copername
      LOCAL cProdPeriod, ddate, dentdate, ileasespk, ioperatorpk, nNetUnits, nprice
      LOCAL oprogress, lcScan, llOneInvoice
      lnBadRecs = 0
      llReturn  = .T.

      STORE '' TO m.citemid, m.citemdec, m.ctaxable, m.cleaseid, m.cDeptNo, m.cBatch, m.ccatcode, ;
         m.cProdYear, m.cProdPeriod, m.cOwnerID, m.cleasename, m.cvendorid
      STORE 0  TO m.nprice, m.nquantity, m.nExtension, m.nSaltBBL

      oprogress = .NULL.

      TRY

         swselect('glopt')
         lcRevClear = cRevClear
         lcExpClear = cExpClear
         lcCatchAll = cSuspense
      m.cAcctNo  = lcExpClear

         swselect('apopt')
         m.capacct = capacct

         IF NOT FILE(m.goapp.cDataFilePath+'importbatch.dbf')
            CREATE TABLE (m.goapp.cDataFilePath+'importbatch') FREE ;
               (cImptype       C(4), ;
               timported      T, ;
               mkeys          m)
         ENDIF

         STORE '' TO lcMessage2
         * Create cursor for bad detail lines
         CREATE CURSOR baddetail ;
            ( iRow      I, ;
            cvendorid  C(10), ;
            cWellID     C(20), ;
            cWellname  C(40), ;
            ccatcode   C(7), ;
            cinvnum    C(14), ;
            cAcctNo    C(6), ;
            namount    N(12, 2))

         IF llOneInvoice
            SELECT  cinvnum, ;
               dinvdate, ;
            dinvdate AS dPostDate, ;
            dinvdate AS dduedate, ;
               SPACE(8) AS cBatch, ;
            SUM(nOwnVal) AS nInvTot ;
               FROM importfile ;
            WHERE nOwnVal # 0 ;
               INTO CURSOR curNewBills READWRITE ;
               ORDER BY dPostDate ;
               GROUP BY dPostDate
            REPLACE cinvnum WITH ldCheckDate
         ELSE
         SELECT  cOperCode AS cvendorid, ;
               cinvnum, ;
               dinvdate, ;
            dinvdate AS dPostDate, ;
            dinvdate AS dduedate, ;
               SPACE(8) AS cBatch, ;
            SUM(nOwnVal) AS nInvTot ;
               FROM importfile ;
            WHERE nOwnVal # 0 ;
               INTO CURSOR curNewBills READWRITE ;
               ORDER BY cvendorid, cinvnum, dPostDate ;
               GROUP BY cvendorid, cinvnum, dPostDate
         ENDIF

         m.cImptype   = 'EXP'
         m.timported = DATETIME()
         m.mkeys     = ''

         SELECT importfile
         lnMax      = RECCOUNT()
         lnProgress = 1
         oprogress  = m.goapp.omessage.progressbar('Processing imported records...')
         oprogress.SetProgressRange(1, lnMax)
         SELECT curNewBills
         SCAN
            SCATTER MEMVAR

            m.cBatch = GetNextPK('BATCH')
         lcBatch  = m.cBatch
            SELECT curNewBills
            REPLACE cBatch WITH m.cBatch
            m.mkeys = m.mkeys + m.cBatch + CHR(13)

            * Match up vendor
            swselect('vendor')
            LOCATE FOR cvendorid = ALLTRIM(m.cVendorID)
            IF FOUND()
               m.cName = cvendname 
            ELSE
               LOCATE FOR cEnergyLinkID = ALLTRIM(m.cVendorID)
               IF FOUND()
                  m.cVendorid = cVendorID
                  m.cName     = cVendName
               ELSE
                  MESSAGEBOX('Vendor: ' + m.cVendorID + ' was not found in the vendor file. ' + ;
                             'Make sure the vendor is mapped to this EnergyLink vendor code. Cannot continue the import.',64,'Import EnergyLink')
                  llreturn = .f.
                  EXIT
               ENDIF 
            ENDIF 
            lnBillAmt = 0
            m.cname   = ''

            IF THISFORM.chkUseDate.VALUE
               m.dinvdate    = THISFORM.dCheckDate.VALUE
            ENDIF

            m.dentdate   = DATE()
            m.nSubTotal  = m.nInvTot
            m.npayments  = 0
            m.ninvbal    = m.nInvTot
            m.ddiscdate  = {}
            m.creference = 'Imported: ' + DTOC(DATE())
            m.cinvtype   = ''
            m.cponumber  = ''
            m.cidterm    = ''
            m.mnotes     = ''

            IF EMPTY(m.cvendorid)
               m.cvendorid = THISFORM.txtcvendorID.VALUE
            ENDIF
            m.lnoqbpost = THISFORM.chkpostQB.VALUE

            INSERT INTO appurchh FROM MEMVAR
            lndetail = 0

            IF llOneInvoice
               lcScan = '.T.'
            ELSE
               SELECT importfile
               LOCATE FOR NOT EMPTY(cvendorid)
               IF FOUND()
                  lcScan = 'cinvnum = m.cinvnum and cvendorid = m.cvendorid'
               ELSE
                  lcScan = 'cinvnum = m.cinvnum'
               ENDIF
            ENDIF

            SELECT importfile
            SCAN FOR &lcScan
               SCATTER MEMVAR
               m.cWellID = PADR(ALLTRIM(UPPER(m.cWellID)), 20, ' ')
               oprogress.updateprogress(lnProgress)
               lnProgress   = lnProgress + 1
               llFoundLease = .F.
               IF NOT EMPTY(m.cWellID)
                  swselect('wells')
                  LOCATE FOR (cPropNo == m.cWellID) OR ;
                     (coilpurchno == m.cWellID) OR ;
                     (cgaspurchno == m.cWellID) OR ;
                     (cothpurchno == m.cWellID) OR ;
                     (cWellID == LEFT(m.cWellID, 10))
                  IF FOUND()
                     m.cunitno   = cWellID
                     m.cWellname = cWellname
                     m.cWellID   = cWellID
                     IF EMPTY(m.cDesc)
                        m.cDesc  = m.cWellname
                     ENDIF
                     lndetail = lndetail + 1
                     lcTaxType     = ''

                     IF NOT EMPTY(m.ccatcode)
                        IF m.ccatcode = 'PLUG'
                           MESSAGEBOX('The "PLUG" expense code is designated for the Plugging module ' + ;
                              'and cannot be processed on an import. Use the Fixed Expenses ' + ;
                              'or Well Expenses by Well (8/8th) window for any plugging fund ' + ;
                              'adjustments that need made.', 16, 'Plugging Expense')
                           llReturn = .F.
                           EXIT
                        ENDIF
                        * Pad with zeros to make sure the code is valid
                        IF LEN(ALLTRIM(m.ccatcode)) < 4
                           m.ccatcode = PADL(ALLTRIM(m.ccatcode),4,'0')
                        ENDIF
                        swselect('expcat')
                        LOCATE FOR ccatcode = ALLTRIM(m.ccatcode)
                        IF NOT FOUND()
                           SELECT importtypes
                           LOCATE FOR ALLTRIM(m.ccatcode) $ importtypes.mtypes
                           IF FOUND()
                              m.ccatcode   = ALLTRIM(cType)
                           ELSE
                           IF m.nOwnVal # 0
                                 MESSAGEBOX('An invalid expense code was found in the import. The code found is: ' + CHR(10) + CHR(10) + ;
                                    m.ccatcode + CHR(10) + CHR(10) + ;
                                    'Please add this code to the appropriate expense code type in the import ' + ;
                                    'code mapping and then try the import again.', 16, 'Invalid Expense Code')
                                 INSERT INTO baddetail FROM MEMVAR
                                 lnBadRecs = lnBadRecs + 1
                                 llReturn = .F.
                                 EXIT
                              ENDIF
                           ENDIF
                        ELSE
                           m.cAcctNo     = lcExpClear
                           m.cAcctListID = lcExpClear
                           m.cDesc = ccateg
                           m.cExpClass = cExpClass
                        ENDIF

                        IF NOT EMPTY(m.cOwnerID)
                           m.cExpClass = '0' && Force expense class to 0 for one-man items
                        ENDIF

                        IF EMPTY(m.cProdYear) AND NOT EMPTY(m.dProdDate)
                           m.cProdYear   = TRANSFORM(YEAR(m.dProdDate))
                           m.cProdPeriod = PADL(TRANSFORM(MONTH(m.dProdDate)), 2, '0')
                        ENDIF

                     m.nExtension = m.nOwnVal
                        m.citemdesc  = m.cDesc
                        IF NOT EMPTY(m.cProdPeriod)
                           m.cProdPeriod = PADL(ALLTRIM(m.cProdPeriod), 2, '0')
                        ENDIF

                        IF NOT EMPTY(m.ccatcode) AND m.nExtension # 0
                           lnBillAmt = lnBillAmt + m.nExtension
                           m.cidpurd = GetNextPK('APPURCHD')
                        m.cBatch  = lcBatch
                           INSERT INTO appurchd FROM MEMVAR
                        ENDIF
                     ELSE
                        m.ccatcode = ''
                        IF EMPTY(m.cAcctNo)
                           m.cAcctNo     = lcExpClear
                           m.cAcctListID = lcExpClear
                        ENDIF
                        IF m.goapp.lAMVersion OR m.goapp.lQBVersion
                           IF m.goapp.lAMVersion
                           IF NOT EMPTY(m.cAcctNo) AND m.nExtension # 0
                                 swselect('coa')
                                 LOCATE FOR cAcctNo = ALLTRIM(m.cAcctNo)
                                 IF FOUND()
                                    IF EMPTY(m.cDesc)
                                       m.citemdesc  = cacctdesc
                                    ELSE
                                       m.citemdesc  = m.cDesc
                                    ENDIF
                                    m.cidpurd = GetNextPK('APPURCHD')
                                    INSERT INTO appurchd FROM MEMVAR
                                    lnBillAmt = lnBillAmt + m.nExtension
                                 ELSE
                                    INSERT INTO baddetail FROM MEMVAR
                                 ENDIF
                              ENDIF
                           ELSE
                           IF NOT EMPTY(m.cAcctNo) AND m.nExtension # 0
                                 swselect('accounts')
                                 LOCATE FOR UPPER(cacctdesc) = UPPER(ALLTRIM(m.cAcctNo))
                                 IF FOUND()
                                    IF EMPTY(m.cDesc)
                                       m.citemdesc  = cacctdesc
                                    ELSE
                                       m.citemdesc  = m.cDesc
                                    ENDIF
                                    m.cAcctListID = clistid
                                    m.cidpurd = GetNextPK('APPURCHD')
                                    INSERT INTO appurchd FROM MEMVAR
                                    lnBillAmt = lnBillAmt + m.nExtension
                                 ELSE
                                    INSERT INTO baddetail FROM MEMVAR
                                    lnBadRecs = lnBadRecs + 1
                                 ENDIF
                              ENDIF
                           ENDIF
                        ELSE
                        IF NOT EMPTY(m.cDesc) AND m.nExtension # 0
                              IF EMPTY(m.cDesc)
                                 m.citemdesc  = cacctdesc
                              ELSE
                                 m.citemdesc  = m.cDesc
                              ENDIF
                              m.cidpurd = GetNextPK('APPURCHD')
                              INSERT INTO appurchd FROM MEMVAR
                              lnBillAmt = lnBillAmt + m.nExtension
                           ELSE
                              INSERT INTO baddetail FROM MEMVAR
                              lnBadRecs = lnBadRecs + 1
                           ENDIF
                        ENDIF
                     ENDIF
                  ELSE
                     SELECT baddetail
                     LOCATE FOR cWellID = m.cWellID
                     IF NOT FOUND()
                        INSERT INTO baddetail FROM MEMVAR
                     ENDIF
                     lnBadRecs = lnBadRecs + 1
                  ENDIF
               ELSE
                  m.cunitno  = ''
                  m.ccatcode = ''
                  lndetail = lndetail + 1
                  IF m.goapp.lAMVersion
                  IF NOT EMPTY(m.cAcctNo) AND m.nExtension # 0
                        swselect('coa')
                        LOCATE FOR cAcctNo = ALLTRIM(m.cAcctNo)
                        IF FOUND()
                           m.nExtension = m.namount
                           IF EMPTY(m.cDesc)
                              m.citemdesc  = cacctdesc
                           ELSE
                              m.citemdesc  = m.cDesc
                           ENDIF
                           m.cidpurd = GetNextPK('APPURCHD')
                           INSERT INTO appurchd FROM MEMVAR
                           lnBillAmt = lnBillAmt + m.nExtension
                        ELSE
                           INSERT INTO baddetail FROM MEMVAR
                           lnBadRecs = lnBadRecs + 1
                        ENDIF
                     ENDIF
                  ELSE
                  IF NOT EMPTY(m.cAcctNo) AND m.nExtension # 0
                        swselect('accounts')
                        LOCATE FOR UPPER(cacctdesc) = UPPER(ALLTRIM(m.cAcctNo))
                        IF FOUND()
                           IF EMPTY(m.cDesc)
                              m.citemdesc  = cacctdesc
                           ELSE
                              m.citemdesc  = m.cDesc
                           ENDIF
                           m.cAcctListID = clistid
                           m.cidpurd = GetNextPK('APPURCHD')
                           INSERT INTO appurchd FROM MEMVAR
                           lnBillAmt = lnBillAmt + m.nExtension
                        ELSE
                           IF EMPTY(m.cDesc)
                              m.citemdesc  = cacctdesc
                           ELSE
                              m.citemdesc  = m.cDesc
                           ENDIF
                           m.cAcctListID = lcCatchAll
                           m.cidpurd = GetNextPK('APPURCHD')
                           INSERT INTO appurchd FROM MEMVAR
                           lnBillAmt = lnBillAmt + m.nExtension
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
            ENDSCAN && importfile

            SELECT appurchh
            LOCATE FOR cBatch = m.cBatch
            IF FOUND()
               IF lndetail = 0
                  DELETE NEXT 1
                  LOOP
               ENDIF
               IF nInvTot # lnBillAmt
                  REPLACE nInvTot WITH lnBillAmt, ;
                     nSubTotal WITH lnBillAmt, ;
                     ninvbal  WITH lnBillAmt
               ENDIF
            ENDIF
         ENDSCAN &&curnewbills

         oprogress.closeprogress()
         * Inform about any recs that couldn't be imported
         IF lnBadRecs > 0
            SELECT cWellID FROM baddetail INTO CURSOR temp ORDER BY cWellID GROUP BY cWellID
            lnBadRecs = _TALLY
            lcMessage = "There were " + TRANSFORM(lnBadRecs) + " detail lines that could not be imported." + CHR(10) + ;
               "The property numbers that couldn't be found in the well records are: " + CHR(10)

            SELECT cinvnum, cWellname, cWellID, cAcctNo FROM baddetail INTO CURSOR temp ORDER BY cWellID, cinvnum GROUP BY cWellID, cinvnum
            SELECT temp
            SCAN
               SCATTER MEMVAR
               lcMessage2 = lcMessage2 + 'Well: ' + m.cWellID + ' ' + m.cWellname + ' Account: ' + m.cAcctNo + CHR(10)
            ENDSCAN
            MESSAGEBOX(lcMessage + lcMessage2, 48, 'Missing Wells/Account')
            IF MESSAGEBOX('Do you want to print this list of invalid wells?', 36, 'Missing Wells/Accounts') = 6
               SELECT  iRow, cinvnum, ;
                  cWellname, ;
                  ccatcode, ;
                  cWellID, ;
                  cAcctNo, ;
                  namount ;
                  FROM baddetail ;
                  INTO CURSOR temp ;
                  ORDER BY cWellID, ccatcode, cinvnum ;
                  GROUP BY cWellID, ccatcode, cinvnum
               REPORT FORM baddetaile TO PRINTER PROMPT PREVIEW
            ENDIF
            IF MESSAGEBOX('Do you want to continue the import?', 36, 'Continue Import') = 7
               llReturn = .F.
            ENDIF
         ENDIF

         INSERT INTO importbatch FROM MEMVAR

      CATCH TO loError
         llReturn = .F.
         IF VARTYPE(oprogress) = 'O'
            oprogress.closeprogress()
            RELEASE oprogress
         ENDIF
      DO errorlog WITH 'ProcessEnergyLinkExp', loError.LINENO, 'Import Expenses', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

   IF llReturn
      lcBatch = m.cbatch
   ELSE
      lcBatch = '********'
   ENDIF 
   RETURN lcBatch

      ****************************
   PROCEDURE ProcessEnergyLinkRev
      ****************************
      LPARAMETERS tcCashAcct, llDontPost

      LOCAL llReturn, loError
      LOCAL lPostToQB, lcMessage, lcMessage2, lnBadRecs, lnTotal, lnTotalcks, lnDeducts
      LOCAL cBatch, cOwnType, cType, ccashacct, cleasename, cname, copername
      LOCAL ddate, dentdate, ileasespk, ioperatorpk, nNetUnits, nprice
      LOCAL lcRevClear, lcExpClear

      lnBadRecs = 0
      llReturn  = .T.
      lnTotalCheck = 0
      STORE '' TO m.cProdPeriod, m.cProdYear

      TRY

         swselect('glopt')
         GO TOP
         lcRevClear = cRevClear
         lcExpClear = cExpClear
         STORE '' TO lcMessage2, m.ccashacct, m.cType

         * Create cursor for bad detail lines
         CREATE CURSOR baddetail ;
            (cWellID    C(20), ;
            cWellname  C(40), ;
            cprodcode  C(7), ;
            cCheckno   C(14), ;
            cDesc      C(40))

         * Create cursors for all the revenue and adjustment codes
         llReturn = THIS.BuildCodes()

         m.cUser		 = m.goapp.cUser
         m.dlastmodified = DATETIME()


         SELECT importfile
         REPLACE dPostDate WITH dCheckDate FOR EMPTY(dPostDate)
         REPLACE cCheckno WITH DTOC(dCheckDate) FOR EMPTY(cCheckno)
         SET SAFETY OFF
        
         * Get a total for each check in the import
         SELECT  cOperCode, cCheckno,;
            dCheckDate,;
            dPostDate,;
            SPACE(8) AS cBatch,;
                 SUM(nownnet) AS nCashAmt ;
            FROM importfile ;
            WHERE NOT EMPTY(dCheckDate) ;
            AND NOT EMPTY(cpartnercc) ;
         AND LOWER(cCheckno) # 'checknumbe' ;
            INTO CURSOR curNewChecks READWRITE ;
            ORDER BY cCheckno, dCheckDate, dPostDate ;
            GROUP BY cCheckno, dCheckDate, dPostDate

         IF _TALLY = 0
            llReturn = .F.
            MESSAGEBOX('No valid records found in the import.', 16, 'No Records')
            EXIT
         ENDIF
         lnOriginalAmount = 0

         SELECT curNewChecks
         SCAN
            SCATTER MEMVAR

            DO CASE
               CASE m.goapp.lAMVersion
                  m.ccashacct = tcCashAcct
               CASE m.goapp.lQBVersion
                  m.ccashacct = tcCashAcct
               OTHERWISE
                  m.ccashacct = ''
            ENDCASE

            m.cBatch    = m.goapp.oRegistry.IncrementCounter('%Shared.Counters.Batch')
            lcBatch     = m.cBatch
            lnOriginalAmount = m.nCashAmt

            SELECT curNewChecks
            REPLACE cBatch WITH lcBatch

            IF EMPTY(m.dPostDate)
               m.dPostDate = m.ddate
            ENDIF

            m.dentdate = DATE()

            IF VARTYPE(m.dCheckDate) # 'D'
               MESSAGEBOX('An invalid date was found in the import for check no: ' + ALLTRIM(m.cCheckno) + ;
                  '. Using todays date instead. Correct in Production Receipts after this import.', 16, 'Bad Date')
               m.dCheckDate = DATE()
            ENDIF
            IF NOT BETWEEN(m.dCheckDate, {01/01/1980}, {12/31/2025})
               MESSAGEBOX('An invalid date was found in the import for check no: ' + ALLTRIM(m.cCheckno) + ;
                  '. Using todays date instead. Correct in Production Receipts after this import.', 16, 'Bad Date')
               m.dCheckDate = DATE()
            ENDIF

            m.ddate = m.dCheckDate

            swselect('revsrc')
            LOCATE FOR cEnergyLinkID = ALLTRIM(m.cOperCode)
            IF FOUND()
               m.cname = revsrc.crevname
               m.cid   = revsrc.crevkey
            ELSE
               MESSAGEBOX('The operator code: ' + ALLTRIM(m.cOperCode) + ' has not been attached to a purchaser record. Unable to continue.', 16, 'Building Receipt from Import File')
               llReturn = .F.
               EXIT
            ENDIF

            m.cBatch = lcBatch
            m.lnoqbpost = llDontPost
            INSERT INTO csrcthdr FROM MEMVAR

            lnTotalCheck   = 0
            lcLastProdType = ''
            m.lWellRcpt	 = .F.
            SELECT importfile
            SCAN FOR cCheckno = m.cCheckno AND dPostDate = m.dPostDate
               SCATTER MEMVAR
               m.cProdType   = UPPER(ALLTRIM(m.cProdType))
               m.cWellID	   = PADR(ALLTRIM(UPPER(m.cpartnercc)), 20, ' ')
               m.namount	   = m.nownval
            m.nTotalInc     = m.namount
            m.nUnits        = m.nOwnVol
            IF m.cProdType = 'NETJ'
               LOOP
            ENDIF

               IF NOT EMPTY(m.cWellID)
                  swselect('wells')
                  LOCATE FOR (cPropNo == m.cWellID) OR ;
                     (coilpurchno == m.cWellID) OR ;
                     (cgaspurchno == m.cWellID) OR ;
                     (cothpurchno == m.cWellID) OR ;
                     (cWellID == LEFT(m.cWellID, 10))
                  IF FOUND()
                     m.cWellname = cWellname
                     m.cDesc	   = cWellname
                     m.cAcctNo   = lcRevClear
                     m.cWellID   = cWellID
                     m.nUnits    = m.nOwnVol
                     m.lWellRcpt = .T.
                     IF wells.cWellID # ALLTRIM(m.cWellID)
                        m.cWellID = wells.cWellID
                     ENDIF

                     swselect('revcat')
                     LOCATE FOR crevtype = PADR(ALLTRIM(m.cProdType), 5, ' ')
                     IF NOT FOUND()
                        swselect('expcat')
                        LOCATE FOR UPPER(ccatcode) = PADR(ALLTRIM(m.cProdType), 4, ' ')
                        IF FOUND()
                           m.cType   = ccatcode
                           m.cAcctNo = lcExpClear
                        ELSE
                           lcCode = THIS.FindCode(m.cProdType)
                           IF INLIST(lcCode,'BBL','MCF','OTH','MISC1','MISC2','TRANS')
                              m.cType = lcCode
                              m.cAcctNo = lcRevClear
                              m.cProdType = lcCode
                           ELSE
                              SELECT gastypes
                              LOCATE FOR UPPER(ccode) = m.cProdType
                              IF FOUND()
                                 m.cType		= 'MCF'
                                 m.cProdType	= m.cType
                                 m.cAcctNo	= lcRevClear
                              ELSE
                                 SELECT oiltypes
                                 LOCATE FOR UPPER(ccode) = m.cProdType
                                 IF FOUND()
                                    m.cType	   = 'BBL'
                                    m.cProdType = m.cType
                                    m.cAcctNo   = lcRevClear
                                 ELSE
                                    SELECT othtypes
                                    LOCATE FOR UPPER(ccode) = m.cProdType
                                    IF FOUND()
                                       m.cType	  = 'OTH'
                                       m.cProdType = m.cType
                                       m.cAcctNo	  = lcRevClear
                                    ELSE
                                       SELECT gtaxtypes
                                       LOCATE FOR UPPER(ccode) = m.cProdType
                                       IF FOUND()
                                          m.cType	 = 'GTAX1'
                                          m.cProdType = m.cType
                                          m.cAcctNo	 = lcRevClear
                                       ELSE
                                          SELECT otaxtypes
                                          LOCATE FOR UPPER(ccode) = m.cProdType
                                          IF FOUND()
                                             m.cType		= 'OTAX1'
                                             m.cProdType	= m.cType
                                             m.cAcctNo	= lcRevClear
                                          ELSE
                                             SELECT ptaxtypes
                                             LOCATE FOR UPPER(ccode) = m.cProdType
                                             IF FOUND()
                                                m.cType	   = 'PTAX1'
                                                m.cProdType = m.cType
                                                m.cAcctNo   = lcRevClear
                                             ELSE
                                             IF m.cProdType = "NET"
                                                m.cType   = "NET"
                                                m.cprodcode = m.cType
                                                m.cDesc     = ALLTRIM(m.cWellID) + " - NET JIB"
                                                m.cAcctNo   = lcRevClear
                                                m.cWellID = ""
                                             ELSE
                                                IF m.nOwnVal # 0
                                                   MESSAGEBOX('An invalid revenue code was found in the import for check no: ' + ALLTRIM(m.cCheckno) + ;
                                                      '. The code found is: ' + CHR(10) + CHR(10) + ;
                                                      m.cProdType + CHR(10) + CHR(10) + ;
                                                      'Please add this code to the appropriate revenue type in the import ' + ;
                                                      'code mapping and then try the import again.', 16, 'Invalid Revenue Code')
                                                   llReturn = .F.
                                                   EXIT
                                                ENDIF
                                             ENDIF
                                          ENDIF
                                       ENDIF
                                    ENDIF
                                 ENDIF
                              ENDIF
                           ENDIF
                        ENDIF
                     ENDIF
                     ELSE
                        m.cAcctNo	  = lcRevClear
                        m.cType	  = ALLTRIM(m.cProdType)
                        m.lWellRcpt = .F.
                     ENDIF
               ELSE
                  IF m.cWellID = "CHECK_ADJ"
                     m.cWellID = ""
                     m.cType   = "PDEF"
                     m.cprodcode = m.cType
                     m.cAcctNo	 = lcRevClear
                     m.cDesc     = "NET JIB"
                  ELSE
                     m.cprodcode = m.cType
                     m.cDesc	   = 'Property No: ' + ALLTRIM(m.cWellID) + ' was not found.'
                     INSERT INTO baddetail FROM MEMVAR
                     lnBadRecs = lnBadRecs + 1
                  ENDIF
                  ENDIF

                  IF NOT llReturn
                     EXIT
                  ENDIF


                  IF 'TAX' $ m.cType
                     m.nprice	= 0
                     m.nUnits	= 0
                  ELSE
                     IF m.nprice = 0
                        IF m.nUnits <> 0
                           m.nprice    = m.nTotalInc / m.nUnits
                        ELSE
                           m.nprice = 0
                        ENDIF
                     ENDIF
                  ENDIF

                  IF NOT EMPTY(m.cDesc) AND m.namount # 0 AND (m.nAmount # m.nOwnTax) AND (m.nAmount # m.nOwnDeducts)
                     m.cidRctD   = GetNextPK('CSRCTDET')
                     m.lWellRcpt = .T.
                     m.cBatch = lcBatch
                     lnTotalCheck = lnTotalCheck + m.namount
                     INSERT INTO csrctdet FROM MEMVAR
                  ENDIF

                  ***********************************************
                  * Process the deductions
                  ***********************************************

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct1, ;
                     m.cDeductcode1, ;
                     m.cProdType, ;
                     m.ngrossDeduct1)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct2, ;
                     m.cDeductcode2, ;
                     m.cProdType, ;
                     m.ngrossDeduct2)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct3, ;
                     m.cDeductcode3, ;
                     m.cProdType, ;
                     m.ngrossDeduct3)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct4, ;
                     m.cDeductcode4, ;
                     m.cProdType, ;
                     m.ngrossDeduct4)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct5, ;
                     m.cDeductcode5, ;
                     m.cProdType, ;
                     m.ngrossDeduct5)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct6, ;
                     m.cDeductcode6, ;
                     m.cProdType, ;
                     m.ngrossDeduct6)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct7, ;
                     m.cDeductcode7, ;
                     m.cProdType, ;
                     m.ngrossDeduct7)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct8, ;
                     m.cDeductcode8, ;
                     m.cProdType, ;
                     m.ngrossDeduct8)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct9, ;
                     m.cDeductcode9, ;
                     m.cProdType, ;
                     m.ngrossDeduct9)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessDeducts(lcBatch, m.nownDeduct10, ;
                     m.cDeductcode10, ;
                     m.cProdType, ;
                     m.ngrossDeduct10)
                  IF NOT llReturn
                     EXIT
                  ENDIF

                  ***********************************************
                  * Process the taxes
                  ***********************************************
                 
                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax1, ;
                     m.ctaxcode1, ;
                     m.ngrosstax1, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax2, ;
                     m.ctaxcode2, ;
                     m.ngrosstax2, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF

                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax3, ;
                     m.ctaxcode3, ;
                     m.ngrosstax3, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF
                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax4, ;
                     m.ctaxcode4, ;
                     m.ngrosstax4, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF
                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax5, ;
                     m.ctaxcode5, ;
                     m.ngrosstax5, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF
                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax6, ;
                     m.ctaxcode6, ;
                     m.ngrosstax6, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF
                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax7, ;
                     m.ctaxcode7, ;
                     m.ngrosstax7, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF
                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax8, ;
                     m.ctaxcode8, ;
                     m.ngrosstax8, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF
                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax9, ;
                     m.ctaxcode9, ;
                     m.ngrosstax9, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF
                  llReturn = THIS.ProcessTaxes(lcBatch, m.nowntax10, ;
                     m.ctaxcode10, ;
                     m.ngrosstax10, ;
                     m.cProdType)

                  IF NOT llReturn
                     EXIT
                  ENDIF

               ENDIF
            ENDSCAN && importfile
         ENDSCAN &&cshdr

         IF llReturn
            lnRounding = lnOriginalAmount - lnTotalCheck
            IF lnRounding # 0
               TRY
                  swselect('expcat')
                  LOCATE FOR ccatcode = 'RND '
                  IF NOT FOUND()
                     m.ccatcode  = 'RND'
                     m.ccateg    = 'Rounding'
                     m.cdescrip  = 'Rounding'
                     m.cExpClass = '0'
                     m.cidexpc   = GetNextPK('EXPCAT')
                     INSERT INTO expcat FROM MEMVAR
                  ENDIF
               CATCH
               ENDTRY
               m.cType   = 'RND'
               m.cBatch  = lcBatch
               m.nprice  = 0
               m.nUnits  = 0
               m.namount = lnRounding
               m.cidRctD = GetNextPK('CSRCTDET')
               INSERT INTO csrctdet FROM MEMVAR
            ENDIF
         ENDIF
         * Inform about any recs that couldn't be imported
         IF lnBadRecs > 0
            lcMessage = "There were " + TRANSFORM(lnBadRecs) + " detail lines that could not be imported." + CHR(10) + ;
               "The rows that couldn't be imported: " + CHR(10)

            SELECT cCheckno, cWellID FROM baddetail INTO CURSOR temp ORDER BY cWellID, cCheckno GROUP BY cWellID, cCheckno
            SELECT temp
            SCAN
               SCATTER MEMVAR
               lcMessage2 = lcMessage2 + 'Property: ' + m.cWellID + ' Check No: ' + m.cCheckno + CHR(10)
            ENDSCAN
            MESSAGEBOX(lcMessage + lcMessage2, 48, 'Import Problems')
            IF MESSAGEBOX('Do you want to print this list of import problems?', 36, 'Import Problems') = 6
               SELECT  cCheckno, ;
                       cWellname, ;
                       cprodcode, ;
                       cWellID, ;
                       cDesc ;
                   FROM baddetail ;
                   INTO CURSOR temp ;
                  ORDER BY cWellID, cCheckno ;
                  GROUP BY cWellID, cprodcode, cCheckno, cDesc
               REPORT FORM baddetail TO PRINTER PROMPT PREVIEW
            ENDIF
            IF MESSAGEBOX('Do you want to continue the import?', 36, 'Continue Import') = 7
               llReturn = .F.
            ENDIF

         ENDIF

         IF llReturn
            llReturn = PostIncome(m.cBatch)
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BuildReceipt', loError.LINENO, 'Import Revenue', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the import at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      * Return the batch no of the receipt if it was successful
      IF NOT llReturn
         RETURN '********'
      ELSE
         RETURN lcBatch
      ENDIF

      ********************
   PROCEDURE FindCode
      ********************
      LPARAMETERS tcCode

      swselect('importtypes')

      LOCATE FOR ALLTRIM(tcCode) $ mtypes
      IF FOUND()
         lcCode = cType
      ELSE
         lcCode = tcCode
      ENDIF

      RETURN lcCode


      ********************
   PROCEDURE Load_EL_ImportFile_Rev
      ********************

      SELECT importtemp
      SCAN
         SCATTER MEMVAR

         m.cCheckno = m.cf1
         m.dCheckDate = CTOD(m.cf2)
         IF EMPTY(m.dCheckDate)
            * Convert an Excel Number to a date format
            m.dCheckDate = CTOD('12/30/1899') + INT(VAL(m.cf2))
         ENDIF
         m.dPostDate  = m.dCheckDate
         m.nCheckAmt  = VAL(m.cf3)
         m.cpartnercc = m.cf4
         m.cPropName   = m.cf5
         m.cProdType   = m.cf6
         m.cProdDesc   = m.cf7
         m.cIntType    = m.cf8
         m.nownpct     = VAL(m.cf9)
         m.npaidpct    = VAL(m.cf10)
         m.dProdDate   = CTOD(m.cf11)
         IF EMPTY(m.dProdDate)
            * Convert an Excel Number to a date format
            m.dProdDate = CTOD('12/30/1899') + INT(VAL(m.cf11))
         ENDIF
         m.cProdYear   = TRANSFORM(YEAR(m.dProdDate))
         m.cProdPeriod = PADL(TRANSFORM(MONTH(m.dProdDate)),2,'0')
         m.nprice      = VAL(m.cf12)
         m.nGrossVol   = VAL(m.cf13)
         m.nGrossVal   = VAL(m.cf14)
         m.nGrossTax   = VAL(m.cf15)
         m.nGrossDeducts = VAL(m.cf16)
         m.nPropNet    = VAL(m.cf17)
         m.nOwnVol     = VAL(m.cf18)
         m.nOwnVal     = VAL(m.cf19)
         m.nowntax     = VAL(m.cf20)
         m.nowndeducts = VAL(m.cf21)
         m.nownnet     = VAL(m.cf22)
         m.ctaxcode1  = m.cf23
         m.ngrosstax1  = VAL(m.cf24)
         m.nowntax1    = VAL(m.cf25)
         m.ctaxcode2  = m.cf26
         m.ngrosstax2  = VAL(m.cf27)
         m.nowntax2    = VAL(m.cf28)
         m.ctaxcode3  = m.cf29
         m.ngrosstax3  = VAL(m.cf30)
         m.nowntax3    = VAL(m.cf31)
         m.ctaxcode4  = m.cf32
         m.ngrosstax4  = VAL(m.cf33)
         m.nowntax4    = VAL(m.cf34)
         m.ctaxcode5  = m.cf35
         m.ngrosstax5  = VAL(m.cf36)
         m.nowntax5    = VAL(m.cf37)
         m.ctaxcode6  = m.cf38
         m.ngrosstax6  = VAL(m.cf39)
         m.nowntax6    = VAL(m.cf40)
         m.ctaxcode7  = m.cf41
         m.ngrosstax7  = VAL(m.cf42)
         m.nowntax7    = VAL(m.cf43)
         m.ctaxcode8  = m.cf44
         m.ngrosstax8  = VAL(m.cf45)
         m.nowntax8    = VAL(m.cf46)
         m.ctaxcode9  = m.cf47
         m.ngrosstax9  = VAL(m.cf48)
         m.nowntax9    = VAL(m.cf49)
         m.ctaxcode10  = m.cf50
         m.ngrosstax10  = VAL(m.cf51)
         m.nowntax10    = VAL(m.cf52)
         m.cDeductcode1  = m.cf53
         m.ngrossDeduct1  = VAL(m.cf54)
         m.nownDeduct1    = VAL(m.cf55)
         m.cDeductcode2  = m.cf56
         m.ngrossDeduct2  = VAL(m.cf57)
         m.nownDeduct2    = VAL(m.cf58)
         m.cDeductcode3  = m.cf59
         m.ngrossDeduct3  = VAL(m.cf60)
         m.nownDeduct3    = VAL(m.cf61)
         m.cDeductcode4  = m.cf62
         m.ngrossDeduct4  = VAL(m.cf63)
         m.nownDeduct4    = VAL(m.cf64)
         m.cDeductcode5  = m.cf65
         m.ngrossDeduct5  = VAL(m.cf66)
         m.nownDeduct5    = VAL(m.cf67)
         m.cDeductcode6  = m.cf68
         m.ngrossDeduct6  = VAL(m.cf69)
         m.nownDeduct6    = VAL(m.cf70)
         m.cDeductcode7  = m.cf71
         m.ngrossDeduct7  = VAL(m.cf72)
         m.nownDeduct7    = VAL(m.cf73)
         m.cDeductcode8  = m.cf74
         m.ngrossDeduct8  = VAL(m.cf75)
         m.nownDeduct8    = VAL(m.cf76)
         m.cDeductcode9  = m.cf77
         m.ngrossDeduct9  = VAL(m.cf78)
         m.nownDeduct9    = VAL(m.cf79)
         m.cDeductcode10  = m.cf80
         m.ngrossDeduct10  = VAL(m.cf81)
         m.nownDeduct10    = VAL(m.cf82)
         m.cOperCode       = m.cf83

         INSERT INTO importfile FROM MEMVAR
      ENDSCAN


   ********************
   PROCEDURE Load_EL_ImportFile_Exp
      ********************

      SELECT importtemp
      SCAN
         SCATTER MEMVAR

         m.cOperName = m.cf1
         m.cOperCode = m.cf2
         m.cOperNo   = m.cf3
      m.cwellid   = m.cf4
         m.cPropName   = m.cf5
         m.dInvDate    = CTOD(m.cf6)
         IF EMPTY(m.dInvdate)
            * Convert an Excel Number to a date format
            m.dInvDate = CTOD('12/30/1899') + INT(VAL(m.cf6))
         ENDIF
         m.cInvNum     = m.cf7
         m.dProdDate   = CTOD(m.cf8)
         IF EMPTY(m.dProdDate)
            * Convert an Excel Number to a date format
            m.dProdDate = CTOD('12/30/1899') + INT(VAL(m.cf8))
         ENDIF
         m.cProdYear   = TRANSFORM(YEAR(m.dProdDate))
         m.cProdPeriod = PADL(TRANSFORM(MONTH(m.dProdDate)),2,'0')
         m.nownpct     = VAL(m.cf9)
         m.cmajordesc  = m.cf10
         m.cminordesc  = m.cf11
      m.cCatCode    = SUBSTR(ALLTRIM(m.cf12),AT('.',m.cf12)+1)
         m.ngrossval   = VAL(m.cf13)
         m.nownval     = VAL(m.cf14)

         INSERT INTO importfile FROM MEMVAR
      ENDSCAN


      **********************
   PROCEDURE ProcessTaxes
      **********************
      LPARAMETERS tcBatch, tnOwnTax, tcTaxCode, tnGrossTax, tcProdType
      llReturn = .T.

      TRY
         IF tnOwnTax <> 0
            m.cBatch = tcBatch
            m.nprice = 0
            m.nUnits = 0
            m.namount = tnOwnTax *-1

            IF  .NOT. EMPTY(tcTaxCode)
            swselect('revcat')
            LOCATE FOR crevtype == UPPER(PADR(ALLTRIM(tcTaxCode), 5, ' '))
            IF NOT FOUND()
               swselect('expcat')
               LOCATE FOR ccatcode==UPPER(PADR(ALLTRIM(tcTaxCode), 4, ' '))
               IF  .NOT. FOUND()
                  lcCode = THIS.FindCode(UPPER(ALLTRIM(tcTaxCode)))
                  IF lcCode # tcTaxCode
                     DO CASE
                        CASE lcCode = 'TAX1'
                           DO CASE
                              CASE tcProdType = 'BBL'
                                 m.cType = 'OTAX1'
                              CASE tcProdType = 'MCF'
                                 m.cType = 'GTAX1'
                              CASE tcProdType = 'OTH'
                                 m.cType = 'PTAX1'
                              OTHERWISE
                                 m.cType = 'GTAX1'
                           ENDCASE
                        CASE lcCode = 'TAX2'
                           DO CASE
                              CASE tcProdType = 'BBL'
                                 m.cType = 'OTAX2'
                              CASE tcProdType = 'MCF'
                                 m.cType = 'GTAX2'
                              CASE tcProdType = 'OTH'
                                 m.cType = 'PTAX2'
                              OTHERWISE
                                 m.cType = 'GTAX2'
                           ENDCASE
                        CASE lcCode = 'TAX3'
                           DO CASE
                              CASE tcProdType = 'BBL'
                                 m.cType = 'OTAX3'
                              CASE tcProdType = 'MCF'
                                 m.cType = 'GTAX3'
                              CASE tcProdType = 'OTH'
                                 m.cType = 'PTAX3'
                              OTHERWISE
                                 m.cType = 'GTAX3'
                           ENDCASE
                        CASE lcCode = 'TAX4'
                           DO CASE
                              CASE tcProdType = 'BBL'
                                 m.cType = 'OTAX4'
                              CASE tcProdType = 'MCF'
                                 m.cType = 'GTAX4'
                              CASE tcProdType = 'OTH'
                                 m.cType = 'PTAX4'
                              OTHERWISE
                                 m.cType = 'GTAX4'
                           ENDCASE
                        OTHERWISE
                           m.cType = 'GTAX1'
                     ENDCASE
                  ELSE
                     MESSAGEBOX('An invalid tax code was found in the import on row: ' + TRANSFORM(lnRow) + ;
                        '. The code found is: ' + CHR(10)+CHR(10) + tcTaxCode + CHR(10)+CHR(10) + ;
                        'Please add this code to the appropriate deduction type in the import ' + ;
                        'code mapping and then try the import again.', 36, 'Invalid Tax Code')
                     llReturn = .F.
                     EXIT
                  ENDIF
               ENDIF
               ELSE
               m.cType = tcTaxCode
               ENDIF
            ELSE
            MESSAGEBOX('A blank tax code was found in the import on row: ' + TRANSFORM(lnRow) + ;
                  '. The code found is: ' + CHR(10)+CHR(10) + tcTaxCode + CHR(10)+CHR(10) + ;
                  'Please add this code to the appropriate deduction type in the import ' + ;
                  'code mapping and then try the import again.', 36, 'Invalid Tax Code')
               llReturn = .F.
               EXIT
            ENDIF
            m.cidRctD   = GetNextPK('CSRCTDET')
            lnTotalCheck = lnTotalCheck + m.namount
            INSERT INTO csrctdet FROM MEMVAR
         ENDIF
      CATCH TO loError
      ENDTRY

      RETURN llReturn

      ************************
   PROCEDURE ProcessDeducts
      ************************
      LPARAMETERS tcBatch, tnDeducts, tcDedCode, tcProdType, tnGrossDeducts

      llReturn = .T.

      TRY
         IF m.tnDeducts <> 0
            m.cBatch = tcBatch
            m.nprice = 0
            m.nUnits = 0
            m.namount = tnDeducts *-1

            STORE '' TO m.cDeductCode

            IF  .NOT. EMPTY(tcDedCode)
               m.cDeductCode = tcDedCode
            ELSE
               MESSAGEBOX('An invalid deduction code was found in the import. The code found is: ' + ;
                  CHR(10)+CHR(10) + m.cDeductCode + CHR(10) + CHR(10) + ;
                  'Please add this code to the appropriate deduction type in the import ' + ;
                  'code mapping and then try the import again.',36, 'Invalid Deduct Code')
               llReturn = .F.
               EXIT
            ENDIF
            IF  .NOT. EMPTY(m.cDeductCode)
               swselect('expcat')
               LOCATE FOR ccatcode==UPPER(PADR(ALLTRIM(m.cDeductCode), 4, ' '))
               IF  .NOT. FOUND()
                  lcCode = THIS.FindCode(m.cDeductCode)
                  IF lcCode # m.cDeductCode
                     m.cType = lcCode
                  ELSE
                     MESSAGEBOX('An invalid deduction code was found in the import. The code found is: ' + ;
                        CHR(10)+CHR(10) + m.cDeductCode + CHR(10) + CHR(10) + ;
                        'Please add this code to the appropriate deduction type in the import ' + ;
                        'code mapping and then try the import again.',36, 'Invalid Deduct Code')
                     llReturn = .F.
                     EXIT
                  ENDIF
            ELSE
               m.cType = ccatcode
            ENDIF
            ENDIF
         m.cidRctD   = GetNextPK('CSRCTDET')
         INSERT INTO csrctdet FROM MEMVAR
      ENDIF

   CATCH TO loError
   ENDTRY

   RETURN llReturn

ENDDEFINE




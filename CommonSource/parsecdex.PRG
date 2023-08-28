LPARAMETERS lcFileName, llExcelFile, tnDatasession
LOCAL lcCommon, llReturn

llReturn = .T.

IF VARTYPE(tnDataSession) # 'N'
   tnDataSession = 1
ENDIF 

IF VARTYPE(m.goapp) # 'O'
   lcCommon = 'Datafiles\'
ELSE
   lcCommon = m.goapp.cCommonFolder
ENDIF

IF EMPTY(lcFileName)
   lcFileName = GETFILE('TXT,DAT','CDEX File Location','Open',1,'Where is the CDEX File')
ENDIF
IF VARTYPE(lndatasessionid) = 'N'
   SET DATASESSION TO lndatasessionid
ENDIF
IF USED('CDEXData')
   USE IN cdexdata
ENDIF
TRY
   CREATE CURSOR CDEXFile1 ( ;
      TYPE      C(1), ;
      Company   C(2), ;
      CheckNo   C(12), ;
      Property  C(20), ;
      ProdStrt  C(4), ;
      ProdEnd   C(4), ;
      ProdCode  C(10), ;
      TranCode1 C(2), ;
      LeaseVol  N(12,2), ;
      LeaseTax  N(12,2), ;
      LeaseNet  N(12,2), ;
      OwnerNet  N(12,2), ;
      TranCode2 C(10), ;
      LeaseDed  N(12,2), ;
      OwnerDed  N(12,2), ;
      TranDate  C(3), ;
      IntType   C(1), ;
      DecFlag   C(1), ;
      OwnInt    N(13,8), ;
      BTUFactor C(4))
   INDEX ON CheckNo+Property TAG PK

   CREATE CURSOR CDEXFile2 ( ;
      TYPE       C(1), ;
      Company    C(2), ;
      CheckNo    C(12), ;
      RECCOUNT   I, ;
      CheckAmt   N(12,2), ;
      NetFlag    C(1), ;
      PmtFlag    C(1), ;
      EffDate    D, ;
      LeaseGross N(12,2), ;
      LeaseTax   N(12,2), ;
      LeaseNet   N(12,2), ;
      OwnerNet   N(12,2), ;
      LeaseDed   N(12,2), ;
      OwnerDed   N(12,2), ;
      TranDate   C(3), ;
      OwnerNo    C(12))


   fh = FOPEN(lcFileName)
   IF fh > 0
      = FSEEK(fh, 0, 0)
      DO WHILE ( .NOT. FEOF(fh))
         lcdata = FGETS(fh)
         lnlen  = LEN(lcdata)
         IF lnlen < 5
            LOOP
         ENDIF

         IF LEFT(lcdata, 1) = '1'
            m.Type          = '1'
            m.Company       = SUBSTR(lcdata, 2, 2)
            m.CheckNo       = SUBSTR(lcdata, 4, 12)
            m.Property      = SUBSTR(lcdata, 16, 14)
            m.ProdStrt      = SUBSTR(lcdata, 30, 4)
            m.ProdEnd       = SUBSTR(lcdata, 34, 4)
            m.ProdCode      = SUBSTR(lcdata, 38, 2)
            m.TranCode1     = SUBSTR(lcdata, 40, 2)
            m.LeaseVol      = ConvertToNum(SUBSTR(lcdata, 42, 12),2)
            m.LeaseTax      = ConvertToNum(SUBSTR(lcdata, 54, 9),2)
            m.LeaseNet      = ConvertToNum(SUBSTR(lcdata, 63, 12),2)
            m.OwnerNet      = ConvertToNum(SUBSTR(lcdata, 75, 12),2)
            m.TranCode2     = SUBSTR(lcdata, 87, 2)
            m.LeaseDed      = ConvertToNum(SUBSTR(lcdata, 89, 12),2)
            m.OwnerDed      = ConvertToNum(SUBSTR(lcdata, 101, 12),2)
            m.TranDate      = SUBSTR(lcdata,113,3)
            m.IntType       = SUBSTR(lcdata, 116, 1)
            m.DecFlag       = SUBSTR(lcdata,117,1)
            m.OwnInt        = ConvertToNum(SUBSTR(lcdata, 118, 9),8)
            m.BTUFactor     = SUBSTR(lcdata, 127,4)

            DO CASE
               CASE m.ProdCode = '05'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-COMBO'
               CASE m.ProdCode = '10'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-OIL'
               CASE m.ProdCode = '11'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-OIL'
               CASE m.ProdCode = '12'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-COND'
               CASE m.ProdCode = '13'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-COND'
               CASE m.ProdCode = '20'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-GAS'
               CASE m.ProdCode = '21'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-GAS'
               CASE m.ProdCode = '22'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-GAS'
               CASE m.ProdCode = '23'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-GAS'
               CASE m.ProdCode = '30'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-NGL'
               CASE m.ProdCode = '31'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-METH'
               CASE m.ProdCode = '32'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-ETH'
               CASE m.ProdCode = '33'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-PROP'
               CASE m.ProdCode = '34'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-BUT'
               CASE m.ProdCode = '35'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-ISOB'
               CASE m.ProdCode = '36'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-GASO'
               CASE m.ProdCode = '42'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-WATER'
               CASE m.ProdCode = '43'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-CO2'
               CASE m.ProdCode = '44'
                  m.ProdCode = ALLTRIM(m.ProdCode) + '-HEL'
            ENDCASE

            DO CASE
               CASE m.TranCode2 = 'M'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-MISC.'
               CASE m.TranCode2 = '10'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-DED'
               CASE m.TranCode2 = '03'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-CONTAX'
               CASE m.TranCode2 = '04'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-SCHTX'
               CASE m.TranCode2 = '05'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-STWH'
               CASE m.TranCode2 = '06'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-STNRA'
               CASE m.TranCode2 = '07'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-FEDWH'
               CASE m.TranCode2 = '14'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-ADVAL'
               CASE m.TranCode2 = '23'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-TRAN'
               CASE m.TranCode2 = '22'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-GAS'
               CASE m.TranCode2 = '24'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-DEHY'
               CASE m.TranCode2 = '25'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-COMP'
               CASE m.TranCode2 = '43'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-TRAN'
               CASE m.TranCode2 = '44'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-DEHY'
               CASE m.TranCode2 = '45'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-MKT'
               CASE m.TranCode2 = '46'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-COMP'
               CASE m.TranCode2 = '47'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-GATH'
               CASE m.TranCode2 = '48'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-PROC'
               CASE m.TranCode2 = '60'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-OK'
               CASE m.TranCode2 = '61'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-NM'
               CASE m.TranCode2 = '62'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-UT'
               CASE m.TranCode2 = '63'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-MT'
               CASE m.TranCode2 = '64'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-ND'
               CASE m.TranCode2 = '65'
                  m.TranCode2 = ALLTRIM(m.TranCode2) + '-CO'
            ENDCASE

            INSERT INTO CDEXFile1 FROM MEMVAR

         ENDIF
      ENDDO

      =FCLOSE(fh)


      IF llExcelFile
         IF NOT DIRECTORY(lcCommon+'temp')
            MKDIR (lcCommon+'temp')
         ENDIF
         lcFile = JUSTFNAME(lcFileName) + '.csv'
         SELECT CDEXFile1
         lcOutputFile = lcCommon+'Temp'+lcFile
         COPY TO (lcOutputFile) TYPE CSV

         llReturn = .T.
         IF  .NOT. FILE(lcOutputFile)
            llReturn = .F.
         ENDIF
         TRY
            IF llReturn
               DECLARE INTEGER ShellExecute IN "Shell32.dll" INTEGER, STRING, STRING, STRING, STRING, LONG
               lnreturn = ShellExecute(0, "Open", lcOutputFile, "", "", 1)
            ENDIF
            IF lnreturn>32
               llReturn = .T.
            ELSE
               llReturn = .F.
            ENDIF
         CATCH TO loerror
         ENDTRY
      ELSE
         SELECT CDEXFile1
         m.cButton = 'S'

         lcAlias = ALIAS()

         STORE '' TO m.cGrpName

         m.goapp.oReport.cAlias = lcAlias
         m.goapp.oReport.DATASESSIONID = tnDataSession
         m.goapp.oReport.cReportName = 'CDEXReport.frx'
         m.goapp.oReport.cTitle1 = ''
         m.goapp.oReport.cTitle2 = ''
         m.goapp.oReport.cProcessor = ''
         m.goapp.oReport.cSortOrder = ''
         m.goapp.oReport.cSelectionCriteria = ''
         m.goapp.oReport.CSVFilename = ''
         m.goapp.oReport.cFriendlyName = "CDEX Validation Report"

         llReturn = m.goapp.oReport.SendReport(m.cButton, .F.,.F.)
      ENDIF
   ENDIF

CATCH TO loerror
   = FCLOSE(fh)
   MESSAGEBOX('Error: ' + loerror.MESSAGE + CHR(10) + 'Line No: ' + TRANSFORM(loerror.LINENO), 16, 'Error Importing CDEX')
   llReturn = .F.
ENDTRY
RETURN llReturn


**********************
FUNCTION ConvertToNum
   **********************
   PARAMETER lcnumberstring, lndecimal
   LOCAL lnnumber
   TRY
      lnnumber = VAL(lcnumberstring) / 10 ** lndecimal
   CATCH TO loerror
      lnnumber = 0
   ENDTRY
   RETURN lnnumber
ENDFUNC


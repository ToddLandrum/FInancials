LOCAL loError
LOCAL cCompData, cCompName, nDOI, nGL, nOwnHist, nOwners, nSuspense, nWellHist, nWells
LOCAL llReturn
*:Global nBills, nChecks, nInvoices

llReturn = .T.

TRY

   CREATE CURSOR compstats ;
      (cCompName    c(60), ;
        nWells       I, ;
        nWellsD      I, ;
        nOwners      I, ;
        nOwnersD     I, ;
        nDOI         I, ;
        nDOID        I, ;
        nOwnHist     I, ;
        nOwnHistD    I, ;
        nWellHist    I, ;
        nWellHistD   I, ;
        nSuspense    I, ;
        nSuspenseD   I, ;
        nGL          I, ;
        nGLD         I, ;
        nChecks      I, ;
        nChecksD     I, ;
        nBills       I, ;
        nBillsD      I, ;
        nInvoices    I, ;
        nInvoicesD   I, ;
        nReceipts    I, ;
        nReceiptsD   I, ;
        nOwnPcts     I, ;
        nOwnPctsD    I)

* Get each company's path
   IF NOT USED('compmast')
      USE datafiles\compmast IN 0
   ENDIF
   cCompName = ALLTRIM(cProducer)
   cCompData = ALLTRIM(m.goApp.cDataFilePath)

   STORE 0 TO m.nWells, m.nOwners, m.nDOI, m.nOwnHist, ;
      m.nWellHist, m.nSuspense, m.nGL, ;
      m.nBills, m.nInvoices, m.nChecks

   m.nWells     = CountRecs('Wells', cCompData)
   m.nOwners    = CountRecs('Investor', cCompData)
   m.nDOI       = CountRecs('Wellinv', cCompData)
   m.nOwnHist   = CountRecs('Disbhist', cCompData)
   m.nOwnPcts   = CountRecs('ownpcts', cCompData)
   m.nWellHist  = CountRecs('WellHist', cCompData)
   m.nSuspense  = CountRecs('Suspense', cCompData)
   m.nGL        = CountRecs('Glmaster', cCompData)
   m.nBills     = CountRecs('Appurchh', cCompData)
   m.nReceipts  = CountRecs('csrcthdr', cCompData)
   m.nInvoices  = CountRecs('Invhdr', cCompData)
   m.nChecks    = CountRecs('Checks', cCompData)
   m.nWellsD    = CountRecs('Wells', cCompData, .T.)
   m.nOwnersD   = CountRecs('Investor', cCompData, .T.)
   m.nDOID      = CountRecs('Wellinv', cCompData, .T.)
   m.nOwnHistD  = CountRecs('Disbhist', cCompData, .T.)
   m.nOwnPctsD  = CountRecs('ownpcts', cCompData, .T.)
   m.nWellHistD = CountRecs('WellHist', cCompData, .T.)
   m.nSuspenseD = CountRecs('Suspense', cCompData, .T.)
   IF m.goapp.lAMVersion
      m.nGLD       = CountRecs('Glmaster', cCompData, .T.)
   ELSE
      m.nGLD = 0
   ENDIF    
   m.nBillsD    = CountRecs('Appurchh', cCompData, .T.)
   m.nReceiptsD = CountRecs('csrcthdr', cCompData, .T.)
   m.nInvoicesD = CountRecs('Invhdr', cCompData, .T.)
   m.nChecksD   = CountRecs('Checks', cCompData, .T.)

   INSERT INTO compstats FROM MEMVAR

CATCH TO loError
   llReturn = .F.
   DO errorlog WITH 'CompanyStats', loError.LINENO, 'Stats', loError.ERRORNO, loError.MESSAGE
   MESSAGEBOX('Error:    ' + loError.MESSAGE + CHR(10) + ;
        'Line:     ' + TRANSFORM(loError.LINENO) + CHR(10) + ;
        'Error No: ' + TRANSFORM(loError.ERRORNO), 16, 'Erro')
ENDTRY

RETURN llReturn

FUNCTION CountRecs
   LPARAMETERS tcAlias, tcPath, tlDeleted
   LOCAL lnCount

   USE (tcPath + tcAlias) AGAIN ALIAS myFile IN 0
   SELECT myFile
   IF NOT tlDeleted
      COUNT FOR NOT DELETED() TO lnCount
   ELSE
      SET DELETED OFF 
      COUNT FOR DELETED() TO lnCount
      SET DELETED ON 
   ENDIF
   USE IN myFile

   RETURN lnCount




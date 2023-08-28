LPARAMETERS tcBatch, tcPrintType, tnDataSession
LOCAL lcBatch, llPrintError, llReturn

llReturn = .t.
llFile = .f.
m.cGrpName = ''
swselect('options')
swSELECT('meterall')
SET ORDER TO CBATCH   && CBATCH
IF SEEK(tcBatch)
   lcBatch = CBATCH
   SCATTER MEMVAR
   m.ctaxtype   = m.ctax
   m.cprodrange = m.cbegrange + ' - ' + m.cendrange

   CREATE CURSOR allprint ;
      (cmeterid    C(10), ;
        cmeterdesc   C(30), ;
        cyear        C(4), ;
        cprodrange   C(15), ;
        cperiod      C(2), ;
        dincdate    d, ;
        crefid       C(20), ;
        cdepositid   C(10), ;
        cpurchaser   C(40), ;
        ngasprice    N(12, 4), ;
        nmaster      N(12, 2), ;
        ntotalsub    N(12, 2), ;
        nvariance    N(12, 2), ;
        nallocation  N(12, 2), ;
        ntaxamt      N(12, 2), ;
        ntotaltax    N(12, 2), ;
        ctaxtype     C(5), ;
        cwellid      C(10), ;
        cwellname    C(30), ;
        cbegrange    C(5), ;
        cendrange    C(5), ;
        nsubmeter    N(12, 2))


   swSELECT('meters')
   SET ORDER TO meterid
   IF SEEK(m.cmeterid)
      m.cmeterdesc = cmeterdesc
   ELSE
      m.cmeterdesc = ''
   ENDIF

   swSELECT('metersub')
   SCAN FOR CBATCH == lcBatch
      SCATTER MEMVAR
      swSELECT('wells')
      SET ORDER TO cwellid
      SEEK m.cwellid
      m.cwellname = cwellname
      m.ngasprice = meterall.ngasprice
      swSELECT('revsrc')
      LOCATE FOR crevkey = meterall.crevkey
      IF FOUND()
         m.cpurchaser = revsrc.crevname
      ELSE
         m.cpurchaser = 'Unknown'
      ENDIF
      INSERT INTO allprint FROM MEMVAR
   ENDSCAN

   SELECT allprint
   GO TOP

   IF TYPE('m.cprocessor') <> 'C'
      m.cProcessor = ''
   ENDIF
   IF TYPE('m.cproducer') <> 'C'
      m.cProducer = 'Sherwood Energy'
   ENDIF

   llPrintError = .F.
   lcMessage    = ''


   m.cButton = tcPrintType

   m.goApp.oReport.cAlias             = 'allprint'
   m.goApp.oReport.DATASESSIONID      = tnDataSession
   m.goApp.oReport.cReportName        = 'dmrmetall.frx'
   m.goApp.oReport.cTitle1            = 'Gas Meter Reconciliation Report'
   m.goApp.oReport.cTitle2            = ''
   m.goApp.oReport.cProcessor         = m.cProcessor
   m.goApp.oReport.cSortOrder         = ''
   m.goApp.oReport.cSelectionCriteria = ''
   m.goApp.oReport.CSVFilename        = 'datafiles\meterrecon.csv'
   m.goApp.oReport.cFriendlyName      = 'Gas Meter Reconciliation Report'

   llReturn = m.goApp.oReport.SendReport(m.cButton, llFile, IIF(NOT EMPTY(m.cGrpName), m.cGrpName, .F.))

ELSE
   MESSAGEBOX('Problem printing this reconciliation. The recon data can not be found. Please try again and it the problem persists, contact SherWare support.',48,'Meter Reconciliation')
   llreturn = .f.
ENDIF 

RETURN llReturn
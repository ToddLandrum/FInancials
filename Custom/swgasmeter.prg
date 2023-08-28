**************************************************
*-- Class Library:  c:\develop\codeminenew\ampro_rv\custom\swgasmeter.vcx
**************************************************


**************************************************
*-- Class:        meterrecon (c:\develop\codeminenew\ampro_rv\custom\swgasmeter.vcx)
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   08/05/22 07:55:12 AM
*
DEFINE CLASS meterrecon AS CUSTOM


   HEIGHT = 101
   WIDTH  = 177
   *-- Saves the import time so that all meters get the same import time when imported from one sheet.
   timportdate    = {}
   ntotalmcf      = 0
   cerrormsg      = ''
   nDataSessionID = 1
   oDist          = .NULL.
   NAME           = 'meterrecon'

   ***************************
   PROCEDURE Init
   ***************************
   IF DODEFAULT()
      *  Call distproc to create the (invtmp) and (wellwork) cursors
         THIS.odist = CREATEOBJECT('distproc', 'A', 'Z', ;
            '01', ;
            '2022', ;
            '00', 'O', DATE(), .F., 0, .F., .t.)
   ENDIF 

   *-- Allocates the pay meter to the wells based on the well charts.
   *****************************************************
   PROCEDURE AllocateSub
      *****************************************************
      LPARA tcbatch

      LOCAL lnVariance, lnSubsTot, lcBatch, lnPrice, lnAllocation, lnTotalInc, lnRecNo
      LOCAL lnTotal, lnTotSub, lcSaveRec, lcidmets, lnTotalMCF
      LOCAL lcAlias, lnDeduct1, lnDeduct2, lnDeduct3, lnDeduct4, lnDeduct5, lnDiff, lnMasterInc
      LOCAL lnMasterMCF, lnSubInc, lnSubMCF, lnTax1, lnTax2, lnTax3, lnTax4, lnTotalDed2, lnTotalDed3
      LOCAL lnTotalDed4, lnTotalDed5, lnTotalTax1, lnTotalTax2, lnTotalTax3, lnTotalTax4, lnWellPct
      LOCAL lntotalDed1
      *
      *  Calculates the allocation to each well
      *

      lcAlias  = ALIAS()
      llReturn = .T.

      TRY
         lcBatch = tcbatch

         lnPrice = meterall.nGasPrice

         STORE 0 TO lnVariance, lnSubsTot, lnAllocation, lnTotalInc

         * Total the well meters
         SELECT metersub
         LOCATE FOR cbatch == lcBatch
         lcidmets  = metersub.cidmets
         lcSaveRec = lcidmets

         SCAN FOR cbatch == lcBatch
            lnSubsTot = lnSubsTot + metersub.nSubMeter
         ENDSCAN

         *  Don't try to divide by zero
         IF lnSubsTot = 0
            LOCATE FOR cidmets == lcidmets
            llReturn = .F.
            EXIT
         ENDIF

         * Save the substotal
         IF meterall.nsubstotal # lnSubsTot
            SELECT meterall
            REPLACE meterall.nsubstotal WITH lnSubsTot
         ENDIF

         * Calculate the variance
         lnVariance = meterall.nMaster / lnSubsTot
         IF meterall.nvariance # lnVariance
            REPLACE meterall.nvariance WITH lnVariance
         ENDIF

         lnMasterInc = meterall.ntotalinc
         lnMasterMCF = meterall.nMaster

         STORE 0 TO lnTotalMCF, lnSubMCF, lnSubInc, ;
            lnTotalTax1, lnTotalTax2, lnTotalTax3, lnTotalTax4, ;
            lntotalDed1, lnTotalDed2, lnTotalDed3, lnTotalDed4, ;
            lnTotalDed5

         SELECT metersub
         SCAN FOR cbatch == lcBatch
            lnAllocation = ROUND(nSubMeter * lnVariance, 2)
            lnTotalInc   = ROUND(lnAllocation * lnPrice, 2)

            * Calculate well's share of overall MCF so we can
            * calculate the share of taxes and deductions
            IF nSubMeter # 0
               lnWellPct     = lnAllocation / meterall.nMaster
            ELSE
               lnWellPct = 0
            ENDIF

            lnTax1 = ROUND(meterall.ntotaltax * lnWellPct, 2)
            lnTax2 = ROUND(meterall.ntotaltax2 * lnWellPct, 2)
            lnTax3 = ROUND(meterall.ntotaltax3 * lnWellPct, 2)
            lnTax4 = ROUND(meterall.ntotaltax4 * lnWellPct, 2)

            lnDeduct1 = ROUND(meterall.nDeduct1 * lnWellPct, 2)
            lnDeduct2 = ROUND(meterall.nDeduct2 * lnWellPct, 2)
            lnDeduct3 = ROUND(meterall.nDeduct3 * lnWellPct, 2)
            lnDeduct4 = ROUND(meterall.nDeduct4 * lnWellPct, 2)
            lnDeduct5 = ROUND(meterall.nDeduct5 * lnWellPct, 2)

            lnSubInc    = lnSubInc + lnTotalInc
            lnSubMCF    = lnSubMCF + lnAllocation
            lnTotalTax1 = lnTotalTax1 + lnTax1
            lnTotalTax2 = lnTotalTax2 + lnTax2
            lnTotalTax3 = lnTotalTax3 + lnTax3
            lnTotalTax4 = lnTotalTax4 + lnTax4
            lntotalDed1 = lntotalDed1 + lnDeduct1
            lnTotalDed2 = lnTotalDed2 + lnDeduct2
            lnTotalDed3 = lnTotalDed3 + lnDeduct3
            lnTotalDed4 = lnTotalDed4 + lnDeduct4
            lnTotalDed5 = lnTotalDed5 + lnDeduct5

            IF metersub.nAllocation # lnAllocation
               REPL nAllocation WITH lnAllocation
            ENDIF
            IF metersub.nTotalSub # lnTotalInc
               REPL nTotalSub   WITH lnTotalInc
            ENDIF
            IF metersub.nTaxAmt # lnTax1
               REPLACE nTaxAmt WITH lnTax1
            ENDIF
            IF metersub.nTaxAmt2 # lnTax2
               REPLACE nTaxAmt2 WITH lnTax2
            ENDIF
            IF metersub.nTaxAmt3 # lnTax3
               REPLACE nTaxAmt3 WITH lnTax3
            ENDIF
            IF metersub.nTaxAmt4 # lnTax4
               REPLACE nTaxAmt4 WITH lnTax4
            ENDIF
            IF metersub.nDeduct1 # lnDeduct1
               REPLACE nDeduct1 WITH lnDeduct1
            ENDIF
            IF metersub.nDeduct2 # lnDeduct2
               REPLACE nDeduct2 WITH lnDeduct2
            ENDIF
            IF metersub.nDeduct3 # lnDeduct3
               REPLACE nDeduct3 WITH lnDeduct3
            ENDIF
            IF metersub.nDeduct4 # lnDeduct4
               REPLACE nDeduct4 WITH lnDeduct4
            ENDIF
            IF metersub.nDeduct5 # lnDeduct5
               REPLACE nDeduct5 WITH lnDeduct5
            ENDIF

            * Create the subpaymeter record if this is a submeter
            IF metersub.lsubmeter
               THIS.CreateSubPayMeter()
               m.cmeterid     = metersub.cwellid
               m.cyear        = meterall.cyear
               m.cperiod      = meterall.cperiod
               m.crevkey      = meterall.crevkey
               m.nMaster      = lnAllocation
               m.nGasPrice    = meterall.nGasPrice
               m.ntotalinc    = lnTotalInc
               m.cbegrange    = meterall.cbegrange
               m.cendrange    = meterall.cendrange
               m.ndayson      = meterall.ndayson
               m.cidchec      = meterall.cidchec
               m.crefid       = meterall.crefid
               m.ntotaltax    = lnTax1
               m.ntotaltax2   = lnTax2
               m.ntotaltax3   = lnTax3
               m.ntotaltax4   = lnTax4
               m.cdedcode1    = meterall.cdedcode1
               m.cdedcode2    = meterall.cdedcode2
               m.cdedcode3    = meterall.cdedcode3
               m.cdedcode4    = meterall.cdedcode4
               m.cdedcode5    = meterall.cdedcode5
               m.nDeduct1     = lnDeduct1
               m.nDeduct2     = lnDeduct2
               m.nDeduct3     = lnDeduct3
               m.nDeduct4     = lnDeduct4
               m.nDeduct5     = lnDeduct5
               m.cimportbatch = meterall.cimportbatch
               SELECT subpaymeter
               lnRecNo = RECNO()
               INSERT INTO subpaymeter FROM MEMVAR
               TRY
                  * Reset the record location after the insert
                  GOTO lnRecNo
               CATCH
               ENDTRY
            ENDIF
         ENDSCAN

         * If the sub totals don't match the total dollars
         * adjust the 1st entry
         IF lnMasterInc # lnSubInc
            lnDiff = lnMasterInc - lnSubInc
            SELECT metersub
            LOCATE FOR cidmets == lcidmets AND nAllocation # 0
            IF FOUND()
               REPL nTotalSub WITH nTotalSub + lnDiff
            ENDIF
         ENDIF

         IF lnMasterMCF # lnSubMCF
            lnDiff = lnMasterMCF - lnSubMCF
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nAllocation WITH nAllocation + lnDiff
            ENDIF
         ENDIF

         IF meterall.ntotaltax # lnTotalTax1
            lnDiff = meterall.ntotaltax - lnTotalTax1
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nTaxAmt WITH nTaxAmt + lnDiff
            ENDIF
         ENDIF
         IF meterall.ntotaltax2 # lnTotalTax2
            lnDiff = meterall.ntotaltax2 - lnTotalTax2
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nTaxAmt2 WITH nTaxAmt2 + lnDiff
            ENDIF
         ENDIF
         IF meterall.ntotaltax3 # lnTotalTax3
            lnDiff = meterall.ntotaltax3 - lnTotalTax3
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nTaxAmt3 WITH nTaxAmt3 + lnDiff
            ENDIF
         ENDIF
         IF meterall.ntotaltax4 # lnTotalTax4
            lnDiff = meterall.ntotaltax4 - lnTotalTax4
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nTaxAmt4 WITH nTaxAmt4 + lnDiff
            ENDIF
         ENDIF

         IF meterall.nDeduct1 # lntotalDed1
            lnDiff = meterall.nDeduct1 - lntotalDed1
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nDeduct1 WITH nDeduct1 + lnDiff
            ENDIF
         ENDIF
         IF meterall.nDeduct2 # lnTotalDed2
            lnDiff = meterall.nDeduct2 - lnTotalDed2
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nDeduct2 WITH nDeduct2 + lnDiff
            ENDIF
         ENDIF
         IF meterall.nDeduct3 # lnTotalDed3
            lnDiff = meterall.nDeduct3 - lnTotalDed3
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nDeduct3 WITH nDeduct3 + lnDiff
            ENDIF
         ENDIF
         IF meterall.nDeduct4 # lnTotalDed4
            lnDiff = meterall.nDeduct4 - lnTotalDed4
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nDeduct4 WITH nDeduct4 + lnDiff
            ENDIF
         ENDIF
         IF meterall.nDeduct5 # lnTotalDed5
            lnDiff = meterall.nDeduct5 - lnTotalDed5
            SELECT metersub
            LOCATE FOR cidmets == lcidmets  AND nAllocation # 0
            IF FOUND()
               REPL nDeduct5 WITH nDeduct5 + lnDiff
            ENDIF
         ENDIF

         SELECT metersub
         LOCATE FOR cidmets == lcidmets

      CATCH TO loError
         THIS.cerrormsg = ALLTRIM(loError.MESSAGE) + ' Line: ' + TRANSFORM(loError.LINENO)
         llReturn       = .F.
      ENDTRY

      SELECT (lcAlias)

      RETURN llReturn
   ENDPROC

   ***************************************************** 
   PROCEDURE CalcAllocation
      *****************************************************
      LPARA tcbatch

      LOCAL llUnalloc, lcBatch, ldIncDate, lcRevKey, lnDaysOn, lcBegRange, lcEndRange, lnPrice
      LOCAL lcYear, lcPeriod, lcGroup, lcRefid, lnDaysOn, lcBatchNo, llReturn

      lcAlias   = ALIAS()
      llReturn  = .T.
      lcBatchNo = csrcthdr.cbatch

      TRY
         SELE glopt
         GO TOP
         lcRevClear = cRevClear

         *
         *  Create distproc so we can use netrev
         *
         SELECT wells
         SET ORDER TO cwellid
         GO TOP
         lcWellID1 = cwellid
         GO BOTT
         lcWellID2 = cwellid

         *
         *  Allocates the calculated MCF and $ to the income or incsusp table
         *
         SELE meterall
         LOCATE FOR cbatch == tcbatch
         lcBatch    = meterall.cbatch
         lcRevKey   = meterall.crevkey
         ldIncDate  = meterall.dIncDate
         lnPrice    = meterall.nGasPrice
         lcYear     = meterall.cyear
         lcPeriod   = meterall.cperiod
         lcRefid    = meterall.crefid
         lcBegRange = meterall.cbegrange
         lcEndRange = meterall.cendrange
         lnDaysOn   = CalcDaysOn(m.cbegrange, m.cendrange)

         SELE meterall
         REPLACE ndayson WITH lnDaysOn
         lcMeterID = cmeterid
         llUnalloc = .F.

         IF EMPTY(lcYear)
            llUnalloc = .T.
         ELSE
            llUnalloc = .F.
         ENDIF
         *
         *  Check to see if this revenue has already been closed
         *
         SELE income
         LOCATE FOR cbatch = lcBatch AND nRunNo # 0
         IF FOUND()
            THIS.cerrormsg = 'These revenue entries have been allocated and closed. No changes are possible.'
            llReturn       = .F.
         ENDIF

         *
         *  Remove the entries from previous allocations
         *
         SELECT incsusp
         SCAN FOR cbatch == lcBatch
            DELETE NEXT 1
         ENDSCAN

         SELECT income
         SCAN FOR cbatch == lcBatch
            DELETE NEXT 1
         ENDSCAN
         
         * Get the purchaser name for expenses
         swselect('revsrc')
         LOCATE FOR crevkey = meterall.crevkey
         IF FOUND()
            m.cPayee = crevname
         ELSE
            m.cPayee = 'Unknown'
         ENDIF 

         *
         *  Scan through the sub-meters and allocate the mcf and revenue
         *
         SELECT metersub
         SCAN FOR cbatch == lcBatch AND nSubMeter # 0
            SCATTER MEMVAR
            m.lAllocated = .F.
            m.dRevDate   = ldIncDate
            m.dPostDate  = ldIncDate
            m.crevkey    = lcRevKey
            m.nUnits     = m.nAllocation
            m.nPrice     = lnPrice
            m.ntotalinc  = m.nTotalSub
            m.cSource    = 'MCF'
            m.ndayson    = lnDaysOn
            m.cyear      = lcYear
            m.cperiod    = lcPeriod
            m.cbatch     = lcBatch
            m.crefid     = lcRefid
            m.lCSTran    = .F.
            m.cOwnerID   = ''
            m.lClosed    = .F.
            m.cbegrange  = lcBegRange
            m.cendrange  = lcEndRange
            REPL metersub.cbegrange WITH lcBegRange, ;
               metersub.cendrange WITH lcEndRange, ;
               metersub.ndayson   WITH lnDaysOn

            *!*               SELECT wells
            *!*               IF SEEK(m.cwellid)
            *!*                  m.cwellname = cwellname
            *!*               ELSE
            *!*                  m.cwellname = 'Unknown'
            *!*               ENDIF

            swselect('Csrctdet', .T.)
            m.cidrctd = GetNextPK('CSRCTDET')
            m.cbatch  = lcBatchNo
            IF metersub.lsubmeter
               m.ntotalinc = 0
            ENDIF
            m.namount     = m.ntotalinc
            m.cprodperiod = lcPeriod
            m.cprodyear   = lcYear
            m.cacctno     = lcRevClear
            m.ndayson     = lnDaysOn
            m.cdesc       = m.cwellname
            m.ctype       = 'MCF'
            m.lwellrcpt   = .T.
            m.cOwnerID    = ''
            m.ndayson     = lnDaysOn
            INSERT INTO csrctdet FROM MEMVAR

            * Insert into the income table
            m.cidinco   = GetNextPK('Income')
            m.cyear     = lcYear
            m.cperiod   = lcPeriod
            m.dAcctDate = ldIncDate

            SELE meterdata
            SCAN FOR cwellid  = m.cwellid ;
                  AND cyear   = m.cyear ;
                  AND cperiod = m.cperiod
               IF cMasterID1 # meterall.cmeterid AND ;
                     cMasterID2 # meterall.cmeterid AND ;
                     cMasterID3 # meterall.cmeterid AND ;
                     cMasterID4 # meterall.cmeterid AND ;
                     cMasterID5 # meterall.cmeterid

                  REPL cbatch  WITH lcBatch

                  DO CASE
                     CASE EMPTY(cMasterID1)
                        REPLACE cMasterID1 WITH meterall.cmeterid

                     CASE EMPTY(cMasterID2)
                        REPLACE cMasterID2 WITH meterall.cmeterid

                     CASE  EMPTY(cMasterID3)
                        REPLACE cMasterID3 WITH meterall.cmeterid

                     CASE EMPTY(cMasterID4)
                        REPLACE cMasterID4 WITH meterall.cmeterid

                     CASE EMPTY(cMasterID5)
                        REPLACE cMasterID5 WITH meterall.cmeterid
                  ENDCASE
               ENDIF
            ENDSCAN
            m.crefid    = meterall.crefid
            m.lCSTran   = .T.
            m.cacctno   = lcRevClear
            m.cbatch    = lcBatchNo
            m.ntotalinc = this.oDist.netrev(m.cwellid, m.ntotalinc, 'G', .T.)
            m.nUnits    = this.oDist.netrev(m.cwellid, m.nUnits, 'G', .T.)

            IF NOT metersub.lsubmeter
               INSERT INTO income FROM MEMVAR
            ENDIF

            IF metersub.nTaxAmt # 0
               m.cidrctd     = GetNextPK('CSRCTDET')
               IF metersub.lsubmeter
                  m.namount  = 0
               ELSE
                  m.namount     = metersub.nTaxAmt * -1
               ENDIF
               m.cwellid     = m.cwellid
               m.nUnits      = 0
               m.nPrice      = 0
               m.cprodperiod = lcPeriod
               m.cprodyear   = lcYear
               m.cacctno     = lcRevClear
               m.cbegrange   = m.cbegrange
               m.cendrange   = m.cendrange
               m.ndayson     = lnDaysOn
               m.cdesc       = m.cwellname
               m.ctype       = 'GTAX1'
               m.lwellrcpt   = .T.
               m.cOwnerID    = ''
               m.ndayson     = lnDaysOn
               m.cbatch      = lcBatchNo
               INSERT INTO csrctdet FROM MEMVAR

               * Insert into the income table
               m.cidinco   = GetNextPK('Income')
               m.cyear     = lcYear
               m.cperiod   = lcPeriod
               m.dAcctDate = ldIncDate
               m.cSource   = 'GTAX1'
               m.crefid    = meterall.crefid
               m.lCSTran   = .T.
               m.cacctno   = lcRevClear
               m.cbatch    = lcBatchNo
               m.ntotalinc = this.odist.netrev(m.cwellid, metersub.nTaxAmt * -1, 'G', .T.)
               m.nUnits    = 0
               IF NOT metersub.lsubmeter
                  INSERT INTO income FROM MEMVAR
               ENDIF
            ENDIF

            IF metersub.nTaxAmt2 # 0
               m.cidrctd     = GetNextPK('CSRCTDET')
               IF metersub.lsubmeter
                  m.namount  = 0
               ELSE
                  m.namount     = metersub.nTaxAmt2 * -1
               ENDIF
               m.cwellid     = m.cwellid
               m.nUnits      = 0
               m.nPrice      = 0
               m.cprodperiod = lcPeriod
               m.cprodyear   = lcYear
               m.cacctno     = lcRevClear
               m.cbegrange   = m.cbegrange
               m.cendrange   = m.cendrange
               m.ndayson     = lnDaysOn
               m.cdesc       = m.cwellname
               m.ctype       = 'GTAX2'
               m.lwellrcpt   = .T.
               m.cOwnerID    = ''
               m.ndayson     = lnDaysOn
               m.cbatch      = lcBatchNo
               INSERT INTO csrctdet FROM MEMVAR

               * Insert into the income table
               m.cidinco   = GetNextPK('Income')
               m.cyear     = lcYear
               m.cperiod   = lcPeriod
               m.dAcctDate = ldIncDate
               m.cSource   = 'GTAX2'
               m.crefid    = meterall.crefid
               m.lCSTran   = .T.
               m.cacctno   = lcRevClear
               m.cbatch    = lcBatchNo
               m.ntotalinc = this.oDist.netrev(m.cwellid, metersub.nTaxAmt2 * -1, 'G', .T.)
               m.nUnits    = 0
               IF NOT metersub.lsubmeter
                  INSERT INTO income FROM MEMVAR
               ENDIF
            ENDIF

            IF metersub.nTaxAmt3 # 0
               m.cidrctd     = GetNextPK('CSRCTDET')
               IF metersub.lsubmeter
                  m.namount  = 0
               ELSE
                  m.namount     = metersub.nTaxAmt3 * -1
               ENDIF
               m.cwellid     = m.cwellid
               m.nUnits      = 0
               m.nPrice      = 0
               m.cprodperiod = lcPeriod
               m.cprodyear   = lcYear
               m.cacctno     = lcRevClear
               m.cbegrange   = m.cbegrange
               m.cendrange   = m.cendrange
               m.ndayson     = lnDaysOn
               m.cdesc       = m.cwellname
               m.ctype       = 'GTAX3'
               m.lwellrcpt   = .T.
               m.cOwnerID    = ''
               m.ndayson     = lnDaysOn
               m.cbatch      = lcBatchNo
               INSERT INTO csrctdet FROM MEMVAR

               * Insert into the income table
               m.cidinco   = GetNextPK('Income')
               m.cyear     = lcYear
               m.cperiod   = lcPeriod
               m.dAcctDate = ldIncDate
               m.cSource   = 'GTAX3'
               m.crefid    = meterall.crefid
               m.lCSTran   = .T.
               m.cacctno   = lcRevClear
               m.cbatch    = lcBatchNo
               m.ntotalinc = this.oDist.netrev(m.cwellid, metersub.nTaxAmt3 * -1, 'G', .T.)
               m.nUnits    = 0
               IF NOT metersub.lsubmeter
                  INSERT INTO income FROM MEMVAR
               ENDIF
            ENDIF

            IF metersub.nTaxAmt4 # 0
               m.cidrctd     = GetNextPK('CSRCTDET')
               IF metersub.lsubmeter
                  m.namount  = 0
               ELSE
                  m.namount     = metersub.nTaxAmt4 * -1
               ENDIF
               m.cwellid     = m.cwellid
               m.nUnits      = 0
               m.nPrice      = 0
               m.cprodperiod = lcPeriod
               m.cprodyear   = lcYear
               m.cacctno     = lcRevClear
               m.cbegrange   = m.cbegrange
               m.cendrange   = m.cendrange
               m.ndayson     = lnDaysOn
               m.cdesc       = m.cwellname
               m.ctype       = 'GTAX4'
               m.lwellrcpt   = .T.
               m.cOwnerID    = ''
               m.ndayson     = lnDaysOn
               m.cbatch      = lcBatchNo
               INSERT INTO csrctdet FROM MEMVAR

               * Insert into the income table
               m.cidinco   = GetNextPK('INCOME')
               m.cyear     = lcYear
               m.cperiod   = lcPeriod
               m.dAcctDate = ldIncDate
               m.cSource   = 'GTAX4'
               m.crefid    = meterall.crefid
               m.lCSTran   = .T.
               m.cacctno   = lcRevClear
               m.cbatch    = lcBatchNo
               m.ntotalinc = this.oDist.netrev(m.cwellid, metersub.nTaxAmt4 * -1, 'G', .T.)
               m.nUnits    = 0
               IF NOT metersub.lsubmeter
                  INSERT INTO income FROM MEMVAR
               ENDIF
            ENDIF

            IF metersub.nDeduct1 # 0
               m.cidrctd     = GetNextPK('CSRCTDET')
               IF metersub.lsubmeter
                  m.namount  = 0
               ELSE
                  m.namount     = metersub.nDeduct1 *-1
               ENDIF
               m.cwellid     = m.cwellid
               m.nUnits      = 0
               m.nPrice      = 0
               m.cprodperiod = lcPeriod
               m.cprodyear   = lcYear
               m.cacctno     = lcRevClear
               m.cbegrange   = m.cbegrange
               m.cendrange   = m.cendrange
               m.ndayson     = lnDaysOn
               m.cdesc       = m.cwellname
               m.ctype       = meterall.cdedcode1
               m.lwellrcpt   = .T.
               m.cOwnerID    = ''
               m.ndayson     = lnDaysOn
               m.cbatch      = lcBatchNo
               INSERT INTO csrctdet FROM MEMVAR

               * Insert into the Expense table
               m.cidexpe   = GetNextPK('Expense')
               m.cyear     = lcYear
               m.cperiod   = lcPeriod
               m.dAcctDate = ldIncDate
               m.cCatCode  = meterall.cdedcode1
               m.crefid    = meterall.crefid
               m.lCSTran   = .T.
               m.cacctno   = lcRevClear
               m.cbatch    = lcBatchNo
               m.dexpdate  = ldIncDate
               m.cvendorid = m.crevkey
               swselect('expcat')
               LOCATE FOR cCatCode = meterall.cdedcode1
               IF FOUND()
                  m.cExpClass = cExpClass
                  m.cCateg    = cCateg
                  m.namount   = swNetExp(metersub.nDeduct1, m.cwellid, .F., m.cExpClass, 'B' )
                  m.nUnits    = 0
                  IF NOT metersub.lsubmeter
                     INSERT INTO expense FROM MEMVAR
                  ENDIF
               ENDIF
            ENDIF

            IF metersub.nDeduct2 # 0
               m.cidrctd     = GetNextPK('CSRCTDET')
               IF metersub.lsubmeter
                  m.namount  = 0
               ELSE
                  m.namount     = metersub.nDeduct2 *-1
               ENDIF
               m.cwellid     = m.cwellid
               m.nUnits      = 0
               m.nPrice      = 0
               m.cprodperiod = lcPeriod
               m.cprodyear   = lcYear
               m.cacctno     = lcRevClear
               m.cbegrange   = m.cbegrange
               m.cendrange   = m.cendrange
               m.ndayson     = lnDaysOn
               m.cdesc       = m.cwellname
               m.ctype       = meterall.cdedcode2
               m.lwellrcpt   = .T.
               m.cOwnerID    = ''
               m.ndayson     = lnDaysOn
               m.cbatch      = lcBatchNo
               INSERT INTO csrctdet FROM MEMVAR

               * Insert into the Expense table
               m.cidexpe   = GetNextPK('Expense')
               m.cyear     = lcYear
               m.cperiod   = lcPeriod
               m.dAcctDate = ldIncDate
               m.cCatCode  = meterall.cdedcode2
               m.crefid    = meterall.crefid
               m.lCSTran   = .T.
               m.cacctno   = lcRevClear
               m.cbatch    = lcBatchNo
               m.dexpdate  = ldIncDate
               m.cvendorid = m.crevkey
               swselect('expcat')
               LOCATE FOR cCatCode = meterall.cdedcode2
               IF FOUND()
                  m.cExpClass = cExpClass
                  m.cCateg    = cCateg
                  m.namount   = swNetExp(metersub.nDeduct2, m.cwellid, .F., m.cExpClass, 'B' )
                  m.nUnits    = 0
                  IF NOT metersub.lsubmeter
                     INSERT INTO expense FROM MEMVAR
                  ENDIF
               ENDIF
            ENDIF

            IF metersub.nDeduct3 # 0
               m.cidrctd     = GetNextPK('CSRCTDET')
               IF metersub.lsubmeter
                  m.namount  = 0
               ELSE
                  m.namount     = metersub.nDeduct3 *-1
               ENDIF
               m.cwellid     = m.cwellid
               m.nUnits      = 0
               m.nPrice      = 0
               m.cprodperiod = lcPeriod
               m.cprodyear   = lcYear
               m.cacctno     = lcRevClear
               m.cbegrange   = m.cbegrange
               m.cendrange   = m.cendrange
               m.ndayson     = lnDaysOn
               m.cdesc       = m.cwellname
               m.ctype       = meterall.cdedcode3
               m.lwellrcpt   = .T.
               m.cOwnerID    = ''
               m.ndayson     = lnDaysOn
               m.cbatch      = lcBatchNo
               INSERT INTO csrctdet FROM MEMVAR

               * Insert into the Expense table
               m.cidexpe   = GetNextPK('Expense')
               m.cyear     = lcYear
               m.cperiod   = lcPeriod
               m.dAcctDate = ldIncDate
               m.cCatCode  = meterall.cdedcode3
               m.crefid    = meterall.crefid
               m.lCSTran   = .T.
               m.cacctno   = lcRevClear
               m.cbatch    = lcBatchNo
               m.dexpdate  = ldIncDate
               m.cvendorid = m.crevkey
               swselect('expcat')
               LOCATE FOR cCatCode = meterall.cdedcode3
               IF FOUND()
                  m.cExpClass = cExpClass
                  m.cCateg    = cCateg
                  m.namount   = swNetExp(metersub.nDeduct3, m.cwellid, .F., m.cExpClass, 'B' )
                  m.nUnits    = 0
                  IF NOT metersub.lsubmeter
                     INSERT INTO expense FROM MEMVAR
                  ENDIF
               ENDIF
            ENDIF

            IF metersub.nDeduct4 # 0
               m.cidrctd     = GetNextPK('CSRCTDET')
               IF metersub.lsubmeter
                  m.namount  = 0
               ELSE
                  m.namount     = metersub.nDeduct4 *-1
               ENDIF
               m.cwellid     = m.cwellid
               m.nUnits      = 0
               m.nPrice      = 0
               m.cprodperiod = lcPeriod
               m.cprodyear   = lcYear
               m.cacctno     = lcRevClear
               m.cbegrange   = m.cbegrange
               m.cendrange   = m.cendrange
               m.ndayson     = lnDaysOn
               m.cdesc       = m.cwellname
               m.ctype       = meterall.cdedcode4
               m.lwellrcpt   = .T.
               m.cOwnerID    = ''
               m.ndayson     = lnDaysOn
               m.cbatch      = lcBatchNo
               INSERT INTO csrctdet FROM MEMVAR

               * Insert into the Expense table
               m.cidexpe   = GetNextPK('Expense')
               m.cyear     = lcYear
               m.cperiod   = lcPeriod
               m.dAcctDate = ldIncDate
               m.cCatCode  = meterall.cdedcode4
               m.crefid    = meterall.crefid
               m.lCSTran   = .T.
               m.cacctno   = lcRevClear
               m.cbatch    = lcBatchNo
               m.dexpdate  = ldIncDate
               m.cvendorid = m.crevkey
               swselect('expcat')
               LOCATE FOR cCatCode = meterall.cdedcode4
               IF FOUND()
                  m.cExpClass = cExpClass
                  m.cCateg    = cCateg
                  m.namount   = swNetExp(metersub.nDeduct4, m.cwellid, .F., m.cExpClass, 'B' )
                  m.nUnits    = 0
                  IF NOT metersub.lsubmeter
                     INSERT INTO expense FROM MEMVAR
                  ENDIF
               ENDIF
            ENDIF

            IF metersub.nDeduct5 # 0
               m.cidrctd     = GetNextPK('CSRCTDET')
               IF metersub.lsubmeter
                  m.namount  = 0
               ELSE
                  m.namount     = metersub.nDeduct5 *-1
               ENDIF
               m.cwellid     = m.cwellid
               m.nUnits      = 0
               m.nPrice      = 0
               m.cprodperiod = lcPeriod
               m.cprodyear   = lcYear
               m.cacctno     = lcRevClear
               m.cbegrange   = m.cbegrange
               m.cendrange   = m.cendrange
               m.ndayson     = lnDaysOn
               m.cdesc       = m.cwellname
               m.ctype       = meterall.cdedcode5
               m.lwellrcpt   = .T.
               m.cOwnerID    = ''
               m.ndayson     = lnDaysOn
               m.cbatch      = lcBatchNo
               INSERT INTO csrctdet FROM MEMVAR

               * Insert into the Expense table
               m.cidexpe   = GetNextPK('Expense')
               m.cyear     = lcYear
               m.cperiod   = lcPeriod
               m.dAcctDate = ldIncDate
               m.cCatCode  = meterall.cdedcode5
               m.crefid    = meterall.crefid
               m.lCSTran   = .T.
               m.cacctno   = lcRevClear
               m.cbatch    = lcBatchNo
               m.dexpdate  = ldIncDate
               m.cvendorid = m.crevkey
               swselect('expcat')
               LOCATE FOR cCatCode = meterall.cdedcode5
               IF FOUND()
                  m.cExpClass = cExpClass
                  m.cCateg    = cCateg
                  m.namount   = swNetExp(metersub.nDeduct5, m.cwellid, .F., m.cExpClass, 'B' )
                  m.nUnits    = 0
                  IF NOT metersub.lsubmeter
                     INSERT INTO expense FROM MEMVAR
                  ENDIF
               ENDIF
            ENDIF

         ENDSCAN

         SELECT meterall

         IF llUnalloc AND llReturn  &&  If not allocated, warn them
            THIS.cerrormsg = 'Since a year and period were not entered, this revenue has been sent to the allocation file.'
         ENDIF


      CATCH TO loError
         THIS.cerrormsg = ALLTRIM(loError.MESSAGE) + ' Line: ' + TRANSFORM(loError.LINENO)
         llReturn       = .F.
      ENDTRY

      SELECT (lcAlias)
      RETURN llReturn
   ENDPROC


   *-- Checks to see if an expense code is valid
   *****************************************************
   PROCEDURE VerifyExpCode
      *****************************************************
      LPARAMETERS tcExpCode, tcMeterID, tiRow

      * Check to see if the expense code is valid. If not log it as a bad import row
      lcAlias = ALIAS()

      IF EMPTY(tcExpCode)
         RETURN 0
      ENDIF

      swselect('expcat')
      SET ORDER TO cCatCode
      IF NOT SEEK(tcExpCode)
         m.cmeterid = tcMeterID
         m.cExpCode = tcExpCode
         m.iRow     = tiRow
         INSERT INTO baddata FROM MEMVAR
         lnReturn = 1
      ELSE
         lnReturn = 0
      ENDIF

      SELECT (lcAlias)

      RETURN lnReturn
   ENDPROC


   *-- Allocates the paid meter reading evenly among wells with no line loss calculated.
   *****************************************************
   PROCEDURE AllocateEvenly
      *****************************************************
      LPARA tcbatch
      LOCAL lnMaster, lnTotalInc, lnPrice, lcBatch, lnCount

      lcAlias = ALIAS()

      SELECT meterall
      LOCATE FOR cbatch == tcbatch
      IF NOT FOUND()
         RETURN
      ENDIF
      lnMaster   = meterall.nMaster
      lnTotalInc = meterall.ntotalinc
      lcBatch    = meterall.cbatch
      lnPrice    = meterall.nGasPrice

      SELECT metersub
      COUNT FOR cbatch == lcBatch TO lnCount

      lnAlloc   = ROUND(lnMaster / lnCount, 2)
      lnDollars = ROUND(lnTotalInc / lnCount, 2)

      lnTotal = lnTotalInc - (lnDollars * lnCount)
      lnSubs  = lnMaster   - (lnAlloc * lnCount)

      SELECT metersub
      SCAN FOR cbatch == lcBatch
         REPL nAllocation WITH lnAlloc, ;
            nSubMeter   WITH lnAlloc, ;
            nTotalSub   WITH lnDollars
      ENDSCAN

      IF lnSubs # 0
         SELECT metersub
         SCAN
            REPL nAllocation WITH nAllocation + lnSubs, ;
               nSubMeter   WITH nSubMeter + lnSubs
            EXIT
         ENDSCAN
      ENDIF

      IF lnTotal # 0
         SELECT metersub
         SCAN
            REPL nTotalSub WITH nTotalSub + lnTotal
            EXIT
         ENDSCAN
      ENDIF

      SELECT (lcAlias)
   ENDPROC


   *-- Builds the metersub records for the given pay meter.
   *****************************************************
   PROCEDURE BuildMeter
      *****************************************************

      ***********************************************************************************
      *  Builds the metersub table for the given master meter and production period
      ***********************************************************************************
      LPARA tcMeterID, tcyear, tcperiod, tcCheckNo, tcPurchKey
      LOCAL lnCount, lnDaysOn, lcBegRange, lcEndRange, llReturn

      lcAlias  = ALIAS()
      llReturn = .T.

      TRY
         ldImpDate = THIS.timportdate

         IF VARTYPE(tcCheckNo) # 'C'
            tcCheckNo = ''
         ENDIF

         SELECT meterall
         APPEND BLANK
         m.cbatch = GetNextPK('BATCH')
         REPL cmeterid WITH tcMeterID, ;
            crefid WITH tcCheckNo, ;
            cbatch WITH m.cbatch

         * Store the Meterall cbatch in importbatch so it can be
         * removed by the delete utility later if needed
         SELECT importbatch
         REPLACE mBatches WITH mBatches + meterall.cbatch + CHR(13)
         lcRcptBatch = csrcthdr.cbatch

         *
         *  Get the variables for the current recon
         *
         SELECT meterall
         m.cbatch   = cbatch
         m.cmeterid = cmeterid
         lcBegRange = cbegrange
         lcEndRange = cendrange
         lnDaysOn   = ndayson
         m.crevkey  = tcPurchKey
         m.dimpdate = THIS.timportdate

         * Delete all submeter readings for this recon
         SELECT metersub
         DELE FOR cbatch == m.cbatch

         * Get the list of wells tied to this master meter and then add them to metersub
         SELECT  cwellid, ;
                 cwellname ;
             FROM wells ;
             WHERE cmeterid  == m.cmeterid ;
                 OR cMeterID2 == m.cmeterid ;
                 OR cMeterID3 == m.cmeterid ;
                 OR cMeterID4 == m.cmeterid ;
                 OR cMeterID5 == m.cmeterid ;
             INTO CURSOR Tempwell ;
             ORDER BY cwellid

         IF _TALLY > 0
            IF _tally = 1
               m.nsubmeter = 1
            ENDIF 
            SELECT Tempwell
            SCAN
               SCATTER MEMVAR
               m.cidmets = GetNextPK('METERSUB')
               INSERT INTO metersub FROM MEMVAR
            ENDSCAN
         ENDIF

         * Look for submeters attached to this master
         swselect('meters')
         SELECT  cmeterid AS cwellid, ;
                 cmeterdesc AS cwellname ;
             FROM meters ;
             WHERE lsubmeter ;
                 AND (cChart1 == m.cmeterid OR ;
                   cChart2 == m.cmeterid OR ;
                   cChart3 == m.cmeterid OR ;
                   cChart4 == m.cmeterid OR ;
                   cChart5 == m.cmeterid) ;
             INTO CURSOR Tempwell ;
             ORDER BY cmeterid

         IF _TALLY > 0
            IF _tally = 1
               m.nsubmeter = 1
            ENDIF 
            SELECT Tempwell
            SCAN
               SCATTER MEMVAR
               m.cidmets = GetNextPK('METERSUB')
               * Mark as a sub pay meter so we can reconcile it to its wells
               m.lsubmeter = .T.
               INSERT INTO metersub FROM MEMVAR
            ENDSCAN
         ENDIF

         lnsubmeter = 0

         * Look for chart readings for this master meter and production period
         * Fill in the chart readings in the metersub records for each well
         SELECT metersub
         SCAN FOR cbatch == m.cbatch
            lcwellid = cwellid
            SELECT wells
            LOCATE FOR cwellid = lcwellid
            IF FOUND()

               SELE meterdata
               SCAN FOR cwellid == lcwellid ;
                     AND cyear = tcyear ;
                     AND cperiod = tcperiod
                  * Loop out if the pay meter has already used this chart record
                  IF cMasterID1 = m.cmeterid
                     LOOP
                  ENDIF
                  IF cMasterID2 = m.cmeterid
                     LOOP
                  ENDIF
                  IF cMasterID3 = m.cmeterid
                     LOOP
                  ENDIF
                  IF cMasterID4 = m.cmeterid
                     LOOP
                  ENDIF
                  IF cMasterID5 = m.cmeterid
                     LOOP
                  ENDIF
                  lnsubmeter = lnsubmeter + namount
               ENDSCAN
               
               IF lnSubmeter = 0 AND metersub.nsubmeter = 1
                     lnSubmeter = 1
                  ENDIF 
               THIS.ntotalmcf = THIS.ntotalmcf + lnsubmeter
               SELE metersub
               REPL nSubMeter WITH lnsubmeter, ;
                  ndayson   WITH lnDaysOn, ;
                  cbegrange WITH lcBegRange, ;
                  cendrange WITH lcEndRange
               lnsubmeter = 0
            ELSE
               * Process sub pay meters
               SELECT meters
               LOCATE FOR cmeterid = lcwellid
               IF FOUND()
                  SELE meterdata
                  SCAN FOR cwellid == lcwellid ;
                        AND cyear = tcyear ;
                        AND cperiod = tcperiod
                     * Loop out if the pay meter has already used this chart record
                     IF cMasterID1 = m.cmeterid
                        LOOP
                     ENDIF
                     IF cMasterID2 = m.cmeterid
                        LOOP
                     ENDIF
                     IF cMasterID3 = m.cmeterid
                        LOOP
                     ENDIF
                     IF cMasterID4 = m.cmeterid
                        LOOP
                     ENDIF
                     IF cMasterID5 = m.cmeterid
                        LOOP
                     ENDIF
                     lnsubmeter = lnsubmeter + namount
                  ENDSCAN

                  IF lnSubmeter = 0 AND metersub.nsubmeter = 1
                     lnSubmeter = 1
                  ENDIF 
                  THIS.ntotalmcf = THIS.ntotalmcf + lnsubmeter
                  SELE metersub
                  REPL nSubMeter WITH lnsubmeter, ;
                     ndayson   WITH lnDaysOn, ;
                     cbegrange WITH lcBegRange, ;
                     cendrange WITH lcEndRange
                  lnsubmeter = 0
               ENDIF
            ENDIF
         ENDSCAN

      CATCH TO loError
         THIS.cerrormsg = ALLTRIM(loError.MESSAGE) + ' Line: ' + TRANSFORM(loError.LINENO)
         llReturn       = .F.
      ENDTRY

      SELECT (lcAlias)

      RETURN llReturn
   ENDPROC

   *-- Looks to see if there are any chart readings for the wells tied to this pay meter.
   *****************************************************
   PROCEDURE CheckforCharts
      *****************************************************

      ************************************************************
      * Looks for submeter readings for the current reconciliation
      * Returns .T. if there are readings
      *         .F. if there are no readings
      ************************************************************
      LPARA tcbatch
      LOCAL lnsubmeter

      lcAlias = ALIAS()

      lnsubmeter = 0

      *  Check for submeter readings with this master
      SELE metersub
      SCAN FOR cbatch == tcbatch
         lnsubmeter = lnsubmeter + nSubMeter
      ENDSCAN

      SELECT (lcAlias)

      * if no submeter readings found, allocate the master evenly
      IF lnsubmeter = 0
         RETURN .F.
      ELSE
         RETURN .T.
      ENDIF
   ENDPROC


   *-- Imports pay meter readings from an Excel worksheet
   *****************************************************
   PROCEDURE ImportPayMeters
      *****************************************************
      LPARAMETERS tcFileName, tdAcctDate, tdPostDate, tcAcctNo, tcPurchKey, tlHeaderRow, tcCheckNo, tnDataSessionID
      LOCAL m.nUnits, m.nPrice, m.drecdate, m.ntotalinc
      LOCAL ldImpDate, lcacctno, lcRcptBatch, lnx, oExcel
      PRIVATE m.iRow

      lcAlias = ALIAS()

      llReturn = .T.

      TRY

         IF VARTYPE(tnDataSessionID) # 'N'
            tnDataSessionID = 1
         ENDIF

         THIS.nDataSessionID = tnDataSessionID

         swselect('wells')
         SET ORDER TO cwellid

         swselect('csrcthdr')
         lcRcptBatch = cbatch
         REPLACE dPostDate WITH tdPostDate

         ldImpDate = tdAcctDate
         lcacctno  = tcAcctNo
         lcRevKey  = tcPurchKey
         llHeader  = tlHeaderRow

         * Insert the record into importbatch
         * There will be one record per import
         m.timpdate = DATETIME()
         m.mBatches = ''
         m.cUser    = m.goapp.cUser
         m.cbatch   = csrcthdr.cbatch
         m.crevkey  = lcRevKey
         INSERT INTO importbatch FROM MEMVAR

         CREATE CURSOR baddata (iRow i, cmeterid c(10), cExpCode c(4), creason c(60))

         swselect('purchasermap')
         LOCATE FOR crevkey = lcRevKey
         IF FOUND()
            SCATTER MEMVAR
         ELSE
            * Use Default
            m.cMeterCol    = 'A'
            m.cMeterVolCol = 'E'
            m.cMeterPayCol = 'F'
            m.cProdPrdCol  = 'B'
            m.cDateOnCol   = 'C'
            m.cDateOffCol  = 'D'
            m.cTax1Col     = 'G'
            m.cTax2Col     = 'H'
            m.cTax3Col     = ''
            m.cTax4Col     = ''
            m.cDed1Col     = 'I'
            m.cDed1CodeCol = 'J'
            m.cDed2Col     = 'K'
            m.cDed2CodeCol = 'L'
            m.cDed3Col     = 'M'
            m.cDed3CodeCol = 'N'
            m.cDed4Col     = 'O'
            m.cDed4CodeCol = 'P'
            m.cDed5Col     = 'Q'
            m.cDed5CodeCol = 'R'
         ENDIF

         lcFile  = tcFileName

         IF EMPTY(lcFile)
            llReturn = .F.
            EXIT
         ENDIF

         oExcel = CREATEOBJECT('excel.application')
         oExcel.APPLICATION.workbooks.OPEN(lcFile)
         oExcel.APPLICATION.VISIBLE = .F.

         m.drecdate       = tdAcctDate
         THIS.timportdate = m.timpdate

         IF llHeader
            lnStart = 2
         ELSE
            lnStart = 1
         ENDIF

         * Read through the Excel sheet to get the rows to import
         lnBad = 0
         FOR lnx = lnStart TO 5500
            m.iRow = lnx

            * Build the cells to retrieve the data from
            lcMeterCol    = ALLTRIM(m.cMeterCol) + ALLTRIM(STR(lnx))
            lcDateOnCol   = ALLTRIM(m.cDateOnCol) + ALLTRIM(STR(lnx))
            lcDateOffCol  = ALLTRIM(m.cDateOffCol) + ALLTRIM(STR(lnx))
            lcMeterVolCol = ALLTRIM(m.cMeterVolCol) + ALLTRIM(STR(lnx))
            lcMeterPayCol = ALLTRIM(m.cMeterPayCol) + ALLTRIM(STR(lnx))
            lcProdPrdCol  = ALLTRIM(m.cProdPrdCol) + ALLTRIM(STR(lnx))

            IF NOT EMPTY(m.cTax1Col)
               lcTax1Col  = ALLTRIM(m.cTax1Col) + ALLTRIM(STR(lnx))
            ENDIF
            IF NOT EMPTY(m.cTax2Col)
               lcTax2Col  = ALLTRIM(m.cTax2Col) + ALLTRIM(STR(lnx))
            ENDIF
            IF NOT EMPTY(m.cTax3Col)
               lcTax3Col  = ALLTRIM(m.cTax3Col) + ALLTRIM(STR(lnx))
            ENDIF
            IF NOT EMPTY(m.cTax4Col)
               lcTax4Col  = ALLTRIM(m.cTax4Col) + ALLTRIM(STR(lnx))
            ENDIF
            IF NOT EMPTY(m.cDed1Col)
               lcDed1Col = ALLTRIM(m.cDed1Col) + TRANSFORM(lnx)
            ENDIF
            IF NOT EMPTY(m.cDed1CodeCol)
               lcDed1CodeCol = ALLTRIM(m.cDed1CodeCol) + TRANSFORM(lnx)
            ENDIF
            IF NOT EMPTY(m.cDed2Col)
               lcDed2Col = ALLTRIM(m.cDed2Col) + TRANSFORM(lnx)
            ENDIF
            IF NOT EMPTY(m.cDed2CodeCol)
               lcDed2CodeCol = ALLTRIM(m.cDed2CodeCol) + TRANSFORM(lnx)
            ENDIF
            IF NOT EMPTY(m.cDed3Col)
               lcDed3Col = ALLTRIM(m.cDed3Col) + TRANSFORM(lnx)
            ENDIF
            IF NOT EMPTY(m.cDed3CodeCol)
               lcDed3CodeCol = ALLTRIM(m.cDed3CodeCol) + TRANSFORM(lnx)
            ENDIF
            IF NOT EMPTY(m.cDed4Col)
               lcDed4Col = ALLTRIM(m.cDed4Col) + TRANSFORM(lnx)
            ENDIF
            IF NOT EMPTY(m.cDed4CodeCol)
               lcDed4CodeCol = ALLTRIM(m.cDed4CodeCol) + TRANSFORM(lnx)
            ENDIF
            IF NOT EMPTY(m.cDed5Col)
               lcDed5Col = ALLTRIM(m.cDed5Col) + TRANSFORM(lnx)
            ENDIF
            IF NOT EMPTY(m.cDed5CodeCol)
               lcDed5CodeCol = ALLTRIM( m.cDed5CodeCol) + TRANSFORM(lnx)
            ENDIF

            m.cmeterid   = oExcel.RANGE(lcMeterCol).VALUE
            IF TYPE('m.cMeterID') = 'N'
               m.cmeterid = TRANSFORM(m.cmeterid)
            ENDIF
            m.cmeterid = PADR(m.cmeterid, 15, ' ')
            IF TYPE('m.cMeterID') = 'C' AND NOT EMPTY(m.cmeterid) AND NOT ISNULL(m.cmeterid)
               SELECT wells
               LOCATE FOR cmeterid == m.cmeterid OR cMeterID2 == m.cmeterid OR cMeterID3 == m.cmeterid
               IF FOUND()
                  WAIT WIND NOWAIT 'Importing ...Meter: ' + m.cmeterid

                  IF TYPE('m.drecdate') # 'D'
                     m.drecdate = CTOD(m.drecdate)
                  ENDIF
                  m.nUnits   = oExcel.RANGE(lcMeterVolCol).VALUE
                  IF NOT TYPE('m.nUnits') = 'N'
                     m.nUnits = 0
                  ENDIF
                  IF TYPE('oExcel.RANGE(lcMeterPayCol).Value') # 'Y'
                     IF TYPE('oExcel.RANGE(lcMeterPayCol).Value') # 'N'
                        m.ntotalinc = 0
                     ELSE
                        m.ntotalinc = oExcel.RANGE(lcMeterPayCol).VALUE
                     ENDIF
                  ELSE
                     m.ntotalinc = oExcel.RANGE(lcMeterPayCol).VALUE
                  ENDIF
                  IF TYPE('m.nTotalInc') = 'N' OR TYPE('m.nTotalInc') = 'Y'
                     m.ntotalinc = ROUND(m.ntotalinc, 2)
                  ELSE
                     m.ntotalinc = 0
                  ENDIF
                  IF TYPE('m.nTotalInc') = 'Y'
                     m.ntotalinc = MTON(m.ntotalinc)
                  ENDIF
                  m.ntotalinc = ROUND(m.ntotalinc, 2)
                  IF m.nUnits # 0
                     m.nPrice = m.ntotalinc / m.nUnits
                  ELSE
                     m.nPrice = 0.00
                  ENDIF

                  ldprodprd = CAST(oExcel.RANGE(lcProdPrdCol).VALUE AS D)
                  lcProdPrd = PADL(ALLT(STR(MONTH(ldprodprd))), 2, '0')
                  lcprodyr  = ALLT(STR(YEAR(ldprodprd)))

                  IF NOT EMPTY(m.cDateOnCol)
                     ldDate1     = oExcel.RANGE(lcDateOnCol).VALUE
                     DO CASE
                        CASE VARTYPE(ldDate1) = 'T'
                           lcDate1 = TTOC(ldDate1)

                        CASE VARTYPE(ldDate1) = 'N'
                           lcDate1     = DTOC(ConvertExcelDate(ldDate1))

                        OTHERWISE
                           lcDate1     = ldDate1
                     ENDCASE
                     m.cbegrange = SUBSTR(lcDate1, 1, 5)
                  ELSE
                     ldDate1     = DATE()
                     m.cbegrange = ''
                  ENDIF
                  IF NOT EMPTY(m.cDateOffCol)
                     ldDate2     = oExcel.RANGE(lcDateOffCol).VALUE
                     DO CASE
                        CASE VARTYPE(ldDate2) = 'T'
                           lcDate2 = TTOC(ldDate2)

                        CASE VARTYPE(ldDate2) = 'N'
                           lcDate2     = DTOC(ConvertExcelDate(ldDate2))

                        OTHERWISE
                           lcDate2     = ldDate2
                     ENDCASE
                     m.cendrange = SUBSTR(lcDate2, 1, 5)
                  ELSE
                     ldDate2     = DATE()
                     m.cendrange = ''
                  ENDIF

                  lcBegRange = m.cbegrange
                  lcEndRange = m.cendrange
                  m.crevkey  = lcRevKey
                  m.ctype    = 'G'

                  TRY
                     IF NOT EMPTY(m.cTax1Col)
                        lnTax1 = NVL(oExcel.RANGE(lcTax1Col).VALUE, 0)
                     ELSE
                        lnTax1 = 0
                     ENDIF
                  CATCH
                     lnTax1 = 0
                  ENDTRY

                  TRY
                     IF NOT EMPTY(m.cTax2Col)
                        lnTax2 = NVL(oExcel.RANGE(lcTax2Col).VALUE, 0)
                     ELSE
                        lnTax2 = 0
                     ENDIF
                  CATCH
                     lnTax2 = 0
                  ENDTRY

                  TRY
                     IF NOT EMPTY(m.cTax3Col)
                        lnTax3 = NVL(oExcel.RANGE(lcTax3Col).VALUE, 0)
                     ELSE
                        lnTax3 = 0
                     ENDIF
                  CATCH
                     lnTax3 = 0
                  ENDTRY

                  TRY
                     IF NOT EMPTY(m.cTax4Col)
                        lnTax4 = NVL(oExcel.RANGE(lcTax4Col).VALUE, 0)
                     ELSE
                        lnTax4 = 0
                     ENDIF
                  CATCH
                     lnTax4 = 0
                  ENDTRY

                  TRY
                     IF NOT EMPTY(m.cTax5Col)
                        lnTax5 = NVL(oExcel.RANGE(lcTax5Col).VALUE, 0)
                     ELSE
                        lnTax5 = 0
                     ENDIF
                  CATCH
                     lnTax5 = 0
                  ENDTRY

                  TRY
                     IF NOT EMPTY(m.cDed1Col)
                        lnDeduct1  = NVL(oExcel.RANGE(lcDed1Col).VALUE, 0)
                        lcDedCode1 = TRANSFORM(NVL(oExcel.RANGE(lcDed1CodeCol).VALUE, ''))
                        lnReturn   = THIS.VerifyExpCode(lcDedCode1, m.cmeterid, m.iRow)
                        lnBad      = lnBad + lnReturn
                     ELSE
                        lnDeduct1  = 0
                        lcDedCode1 = ''
                     ENDIF
                  CATCH
                     lnDeduct1  = 0
                     lcDedCode1 = ''
                  ENDTRY

                  TRY
                     IF NOT EMPTY(m.cDed2Col)
                        lnDeduct2  = NVL(oExcel.RANGE(lcDed2Col).VALUE, 0)
                        lcDedCode2 = TRANSFORM(NVL(oExcel.RANGE(lcDed2CodeCol).VALUE, ''))
                        lnReturn   = THIS.VerifyExpCode(lcDedCode2, m.cmeterid, m.iRow)
                        lnBad      = lnBad + lnReturn
                     ELSE
                        lnDeduct2  = 0
                        lcDedCode2 = ''
                     ENDIF
                  CATCH
                     lnDeduct2  = 0
                     lcDedCode2 = ''
                  ENDTRY

                  TRY
                     IF NOT EMPTY(m.cDed3Col)
                        lnDeduct3  = NVL(oExcel.RANGE(lcDed3Col).VALUE, 0)
                        lcDedCode3 = TRANSFORM(NVL(oExcel.RANGE(lcDed3CodeCol).VALUE, ''))
                        lnReturn   = THIS.VerifyExpCode(lcDedCode3, m.cmeterid, m.iRow)
                        lnBad      = lnBad + lnReturn
                     ELSE
                        lnDeduct3  = 0
                        lcDedCode3 = ''
                     ENDIF
                  CATCH
                     lnDeduct3  = 0
                     lcDedCode3 = ''
                  ENDTRY

                  TRY
                     IF NOT EMPTY(m.cDed4Col)
                        lnDeduct4  = NVL(oExcel.RANGE(lcDed4Col).VALUE, 0)
                        lcDedCode4 = TRANSFORM(NVL(oExcel.RANGE(lcDed4CodeCol).VALUE, ''))
                        lnReturn   = THIS.VerifyExpCode(lcDedCode4, m.cmeterid, m.iRow)
                        lnBad      = lnBad + lnReturn
                     ELSE
                        lnDeduct4  = 0
                        lcDedCode4 = ''
                     ENDIF
                  CATCH
                     lnDeduct4  = 0
                     lcDedCode4 = ''
                  ENDTRY

                  TRY
                     IF NOT EMPTY(m.cDed5Col)
                        lnDeduct5  = NVL(oExcel.RANGE(lcDed5Col).VALUE, 0)
                        lcDedCode5 = TRANSFORM(NVL(oExcel.RANGE(lcDed5CodeCol).VALUE, ''))
                        lnReturn   = THIS.VerifyExpCode(lcDedCode5, m.cmeterid, m.iRow)
                        lnBad      = lnBad + lnReturn
                     ELSE
                        lnDeduct5  = 0
                        lcDedCode5 = ''
                     ENDIF
                  CATCH
                     lnDeduct5  = 0
                     lcDedCode5 = ''
                  ENDTRY

                  IF NOT EMPTY(m.crevkey) AND m.ntotalinc # 0
                     llReturn = THIS.BuildMeter(m.cmeterid, lcprodyr, lcProdPrd, tcCheckNo, lcRevKey)
                     IF llReturn
                        SELE meterall
                        REPL cacctno WITH lcacctno, ;
                           crevkey   WITH m.crevkey, ;
                           cyear     WITH lcprodyr, ;
                           cperiod   WITH lcProdPrd, ;
                           nMaster   WITH m.nUnits, ;
                           nGasPrice WITH m.nPrice, ;
                           cbegrange WITH m.cbegrange, ;
                           cendrange WITH m.cendrange, ;
                           dIncDate  WITH m.drecdate, ;
                           ntotalinc WITH m.ntotalinc, ;
                           ntotaltax WITH lnTax1, ;
                           ntotaltax2 WITH lnTax2, ;
                           ntotaltax3 WITH lnTax3, ;
                           ntotaltax4 WITH lnTax4, ;
                           nDeduct1   WITH lnDeduct1, ;
                           cdedcode1  WITH lcDedCode1, ;
                           nDeduct2   WITH lnDeduct2, ;
                           cdedcode2  WITH lcDedCode2, ;
                           nDeduct3   WITH lnDeduct3, ;
                           cdedcode3  WITH lcDedCode3, ;
                           nDeduct4   WITH lnDeduct4, ;
                           cdedcode4  WITH lcDedCode4, ;
                           nDeduct5   WITH lnDeduct5, ;
                           cdedcode5  WITH lcDedCode5
                        IF THIS.CheckforCharts(meterall.cbatch)
                           llReturn = THIS.AllocateSub(meterall.cbatch)
                        ENDIF
                        IF llReturn
                           llReturn = THIS.CalcAllocation(meterall.cbatch)
                        ENDIF
                     ENDIF
                  ENDIF
               ELSE
                  lnBad      = lnBad + 1
                  m.cExpCode = ''
                  m.creason  = 'Master Meter Not Attached to Any Wells.'
                  INSERT INTO baddata FROM MEMVAR
               ENDIF
            ELSE
               lnBad = lnBad + 1
               WAIT CLEAR
            ENDIF
            IF lnBad = 10
               lnx = 5501
            ENDIF
         ENDFOR && Read through the Excel sheet

         oExcel.QUIT()
         oExcel = .NULL.

         * Loop through the Sub Pay Meters and reconcile them
         IF USED('subpaymeter')
            SELECT subpaymeter
            SCAN
               SCATTER MEMVAR
               SELECT wells
               LOCATE FOR cmeterid == m.cmeterid OR cMeterID2 == m.cmeterid OR cMeterID3 == m.cmeterid
               IF FOUND()
                  WAIT WIND NOWAIT 'Importing ...Meter: ' + m.cmeterid
                  IF NOT EMPTY(m.crevkey) AND m.ntotalinc # 0
                     llReturn = THIS.BuildMeter(m.cmeterid, m.cyear, m.cperiod, m.crefid, m.crevkey)
                     IF llReturn
                        SELE meterall
                        REPL cacctno WITH '', ;
                           crevkey   WITH m.crevkey, ;
                           cyear     WITH m.cyear, ;
                           cperiod   WITH m.cperiod, ;
                           nMaster   WITH m.nMaster, ;
                           nGasPrice WITH m.nGasPrice, ;
                           cbegrange WITH m.cbegrange, ;
                           cendrange WITH m.cendrange, ;
                           dIncDate  WITH m.drecdate, ;
                           ntotalinc WITH m.ntotalinc, ;
                           ntotaltax WITH m.ntotaltax, ;
                           ntotaltax2 WITH m.ntotaltax2, ;
                           ntotaltax3 WITH m.ntotaltax3, ;
                           ntotaltax4 WITH m.ntotaltax4, ;
                           nDeduct1   WITH m.nDeduct1, ;
                           cdedcode1  WITH m.cdedcode1, ;
                           nDeduct2   WITH m.nDeduct2, ;
                           cdedcode2  WITH m.cdedcode2, ;
                           nDeduct3   WITH m.nDeduct3, ;
                           cdedcode3  WITH m.cdedcode3, ;
                           nDeduct4   WITH m.nDeduct4, ;
                           cdedcode4  WITH m.cdedcode4, ;
                           nDeduct5   WITH m.nDeduct5, ;
                           cdedcode5  WITH m.cdedcode5
                        IF THIS.CheckforCharts(meterall.cbatch)
                           llReturn = THIS.AllocateSub(meterall.cbatch)
                        ENDIF
                        IF llReturn
                           llReturn = THIS.CalcAllocation(meterall.cbatch)
                        ENDIF
                     ENDIF
                  ENDIF
               ELSE
                  lnBad      = lnBad + 1
                  m.cExpCode = ''
                  m.creason  = 'Master Meter Not Attached to Any Wells.'
                  INSERT INTO baddata FROM MEMVAR
               ENDIF
            ENDSCAN
         ENDIF

         IF RECCOUNT('baddata') = 0
            llReturn = .T.
         ELSE
            IF MESSAGEBOX("There were some items that couldn't be imported. Do you want to see the problem log?", 36, 'Import Pay Meters') = 6
               SELECT baddata
               * Try/Catch to avoid "Alias is already in use" error
               TRY
                  SET CLASSLIB TO CUSTOM\swreports.vcx ADDITIVE
               CATCH
               ENDTRY
               oReport                    = CREATEOBJECT('swreport')
               oReport.cAlias             = 'baddata'
               oReport.DATASESSIONID      = THIS.nDataSessionID
               oReport.cReportName        = 'customcode\badmeterimport.frx'
               oReport.cTitle1            = 'Gas Meter Import Problems'
               oReport.cTitle2            = ''
               oReport.cProcessor         = ''
               oReport.cSortOrder         = ''
               oReport.cSelectionCriteria = ''
               oReport.CSVFilename        = ''

               llReturn = oReport.SendReport('S', .F., .F.)

               RELEASE oReport
               llReturn = .F.
            ENDIF
         ENDIF

         m.crevkey = tcPurchKey
         IF THIS.ntotalmcf > 0
            THIS.meter_report(lcRcptBatch)
         ELSE
            MESSAGEBOX("There weren't any chart readings found for the wells attached to these pay meters or the pay meters have already been imported." + CHR(13) + this.cErrormsg, 64, 'Gas Meter Reconciliation')
         ENDIF

      CATCH TO loError
         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(13) + 'Line: ' + TRANSFORM(loError.LINENO), 16, 'Import Pay Meters')
      ENDTRY

      SELECT (lcAlias)

      RETURN llReturn
   ENDPROC


   *-- Opens an Excel worksheet and uploads it into a cursor.
   *****************************************************
   PROCEDURE GetWorksheet
      *****************************************************
      LPARAMETERS tcFileName, tlHeaderRow
      LOCAL lcFile, loText, loExcel AS 'vfpxworkbookxlsx'
      LOCAL loError, llReturn

      llReturn = .T.

      TRY

         lcFile = tcFileName
         lcExt  = UPPER(JUSTEXT(lcFile))

         IF UPPER(RIGHT(lcFile, 3)) = 'XLS' OR ;
               UPPER(RIGHT(lcFile, 4)) = 'XLSX'
            llXLSX = .T.
         ENDIF

         IF NOT EMPTY(lcFile)
            loExcel = NEWOBJECT('VFPxWorkbookXLSX', 'VFPxWorkbookXLSX.vcx')
            WAIT WINDOW NOWAIT 'Opening and reading workbook...Please wait...'
            lnWB = loExcel.OpenXlsxWorkbook(lcFile, .T.)
            WAIT CLEAR
            SELECT xl_workbooks
            GO TOP
            lnSheets = sheetcnt

            IF lnSheets > 1 && Only import the 1st sheet
               lnSheets = 1
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
                 cf101            V(254), ;
                 cf102            V(254), ;
                 cf103            V(254), ;
                 cf104            V(254), ;
                 cf105            V(254), ;
                 cf106            V(254), ;
                 cf107            V(254), ;
                 cf108            V(254), ;
                 cf109            V(254), ;
                 cf110            V(254), ;
                 cf111            V(254), ;
                 cf112            V(254), ;
                 cf113            V(254), ;
                 cf114            V(254), ;
                 cf115            V(254), ;
                 cf116            V(254), ;
                 cf117            V(254), ;
                 cf118            V(254), ;
                 cf119            V(254), ;
                 cf120            V(254), ;
                 cf121            V(254), ;
                 cf122            V(254), ;
                 cf123            V(254), ;
                 cf124            V(254), ;
                 cf125            V(254), ;
                 cf126            V(254), ;
                 cf127            V(254), ;
                 cf128            V(254), ;
                 cf129            V(254), ;
                 cf130            V(254), ;
                 cf131            V(254), ;
                 cf132            V(254), ;
                 cf133            V(254), ;
                 cf134            V(254), ;
                 cf135            V(254), ;
                 cf136            V(254), ;
                 cf137            V(254), ;
                 cf138            V(254), ;
                 cf139            V(254), ;
                 cf140            V(254), ;
                 cf141            V(254), ;
                 cf142            V(254), ;
                 cf143            V(254), ;
                 cf144            V(254), ;
                 cf145            V(254), ;
                 cf146            V(254), ;
                 cf147            V(254), ;
                 cf148            V(254), ;
                 cf149            V(254), ;
                 cf150            V(254), ;
                 cf151            V(254), ;
                 cf152            V(254), ;
                 cf153            V(254), ;
                 cf154            V(254), ;
                 cf155            V(254), ;
                 cf156            V(254), ;
                 cf157            V(254), ;
                 cf158            V(254), ;
                 cf159            V(254), ;
                 cf160            V(254), ;
                 cf161            V(254), ;
                 cf162            V(254), ;
                 cf163            V(254), ;
                 cf164            V(254), ;
                 cf165            V(254), ;
                 cf166            V(254), ;
                 cf167            V(254), ;
                 cf168            V(254), ;
                 cf169            V(254), ;
                 cf170            V(254), ;
                 iRow             i)

            WAIT WINDOW NOWAIT 'Importing Worksheet Row - '

            FOR lnx = 1 TO lnSheets
               SELECT MAX(cellrow) AS nRows FROM xl_cells WHERE SHEET = lnx INTO CURSOR temp
               lnRows = nRows
               IF llHeaderRow
                  lnStart = 2
               ELSE
                  lnStart = 1
               ENDIF
               FOR lnRow = lnStart TO lnRows
                  loRow = loExcel.GetSheetRowValues(lnWorkBook, lnx, lnRow)
                  WAIT WINDOW NOWAIT 'Importing Worksheet Row - ' + TRANSFORM(lnRow)
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

         WAIT CLEAR

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
         THIS.cerrormsg = 'Error: ' + loError.MESSAGE + CHR(13) + 'Line: ' + TRANSFORM(loError.LINENO)
         llReturn       = .F.
      ENDTRY

      RELEASE loExcel

      RETURN llReturn
   ENDPROC


   *-- Prints the reconciliation report for the given batch.
   *****************************************************
   PROCEDURE Meter_Report
      *****************************************************
      LPARA tcbatch, tnDataSessionID
      LOCAL lcAlias, llReturn, lcBatch

      llReturn = .T.
      lcAlias  = ALIAS()

      TRY
         lcdatapath = ALLT(m.goapp.cdatafilepath)

         IF NOT USED('importbatch')
            USE (lcdatapath + 'importbatch') IN 0
         ENDIF

         ldImpDate = THIS.timportdate

         CREATE CURSOR allprint ;
            (cbatch       c(8), ;
              ctype        c(1), ;
              drecdate     D, ;
              cmeterid     c(10), ;
              cmeterdesc   c(30), ;
              cyear        c(4), ;
              cperiod      c(2), ;
              cdepositid   c(10), ;
              cpurchaser   c(40), ;
              nPrice       N(12, 4), ;
              nMaster      N(12, 2), ;
              nsubstotal   N(12, 2), ;
              nvariance    N(12, 2), ;
              nAllocation  N(7, 2), ;
              cwellid      c(10), ;
              cwellname    c(30), ;
              cbegrange    c(5), ;
              cendrange    c(5), ;
              namtallocated N(12, 2), ;
              nSubMeter    N(7, 2), ;
              nTaxAmt      N(12, 2), ;
              nTaxAmt2     N(12, 2), ;
              nTaxAmt3     N(12, 2), ;
              nTaxAmt4     N(12, 2), ;
              cdedcode1    c(4), ;
              nDeduct1     N(12, 2), ;
              cdedcode2    c(4), ;
              nDeduct2     N(12, 2), ;
              cdedcode3    c(4), ;
              nDeduct3     N(12, 2), ;
              cdedcode4    c(4), ;
              nDeduct4     N(12, 2), ;
              cdedcode5    c(4), ;
              nDeduct5     N(12, 2))
         INDEX ON ctype + cmeterid + cbatch TAG primkey


         SELE importbatch
         LOCATE FOR cbatch == tcbatch
         IF FOUND()
            m.ctype = ctype

            lcBatches = mBatches
            lnCount   = ALINES(laBatches, lcBatches)

            FOR x = 1 TO lnCount
               lcBatch = laBatches[x]
               SELECT meterall
               SCAN FOR cbatch == lcBatch
                  SCATTER MEMVAR
                  m.drecdate = dIncDate

                  SELECT meters
                  SET ORDER TO meterid
                  IF SEEK(m.cmeterid)
                     m.cmeterdesc = cmeterdesc
                  ELSE
                     m.cmeterdesc = ''
                  ENDIF

                  SELE revsrc
                  LOCATE FOR crevkey = meterall.crevkey
                  IF FOUND()
                     m.cpurchaser = crevname
                  ELSE
                     m.cpurchaser = 'Purchaser Not On File'
                  ENDIF

                  m.nPrice = m.nGasPrice

                  SELECT metersub
                  SCAN FOR cbatch == lcBatch
                     SCATTER MEMVAR
                     SELECT wells
                     SET ORDER TO cwellid
                     SEEK m.cwellid
                     m.cwellname     = cwellname
                     m.namtallocated = m.nTotalSub
                     m.ctype         = 'G'
                     INSERT INTO allprint FROM MEMVAR
                  ENDSCAN

               ENDSCAN
            ENDFOR
         ENDIF

         IF TYPE('m.cprocessor') # 'C'
            m.cProcessor = ''
         ENDIF
         IF TYPE('m.cproducer') # 'C'
            m.cProducer = 'Sherwood Energy'
         ENDIF

         SET CLASSLIB TO CUSTOM\swreports.vcx ADDITIVE
         oReport                    = CREATEOBJECT('swreport')
         oReport.cAlias             = 'allprint'
         oReport.DATASESSIONID      = THIS.nDataSessionID
         oReport.cReportName        = 'customcode\meterpayimport.frx'
         oReport.cTitle1            = 'Meter Reconciliation Report'
         oReport.cTitle2            = ''
         oReport.cProcessor         = ''
         oReport.cSortOrder         = ''
         oReport.cSelectionCriteria = ''
         oReport.CSVFilename        = ''

         llReturn = oReport.SendReport('S', .F., .F.)

         RELEASE oReport

      CATCH TO loError
         MESSAGEBOX('Unable to create the meter reconciliation report.' + CHR(13) + loerror.message + CHR(13) + 'Line: ' + TRANSFORM(loerror.lineno),64,'Gas Meter Reconcilation')
         llReturn = .F.
      ENDTRY

      SELECT (lcAlias)

      RETURN llReturn
   ENDPROC

   *******************************
   PROCEDURE CreateSubPayMeter
      *******************************

      IF NOT USED('subpaymeter')
         CREATE CURSOR subpaymeter ( ;
              cmeterid      c(15), ;
              nGasPrice     N(12, 6), ;
              cyear         c(4), ;
              cperiod       c(2), ;
              crevkey       c(10), ;
              nMaster       N(15, 2), ;
              ntotalinc     N(12, 2), ;
              cbegrange     c(5), ;
              cendrange     c(5), ;
              ndayson       i, ;
              cidchec       c(8), ;
              crefid        c(15), ;
              ctax          c(5), ;
              ntotaltax     N(12, 2), ;
              ntotaltax2    N(12, 2), ;
              ntotaltax3    N(12, 2), ;
              ntotaltax4    N(12, 2), ;
              cdedcode1     c(4), ;
              nDeduct1      N(12, 2), ;
              cdedcode2     c(4), ;
              nDeduct2      N(12, 2), ;
              cdedcode3     c(4), ;
              nDeduct3      N(12, 2), ;
              cdedcode4     c(4), ;
              nDeduct4      N(12, 2), ;
              cdedcode5     c(4), ;
              nDeduct5      N(12, 2), ;
              cimportbatch  c(8))
      ENDIF

ENDDEFINE
*
*-- EndDefine: meterrecon
**************************************************







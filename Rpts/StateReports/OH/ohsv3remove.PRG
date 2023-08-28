LOCAL oMessage

oMessage = findglobalobject('cmMessage')

IF m.goapp.lAMVersion OR m.goapp.lQBVersion
   IF NOT oMessage.CONFIRM('This will remove all cost recovery fee adjustments in the New Run and remove the posting that created them. Continue?')
      RETURN .F.
   ENDIF
ELSE
   IF NOT oMessage.CONFIRM('This will remove all cost recovery fee adjustments in the New Run. Continue?')
      RETURN .F.
   ENDIF
ENDIF

IF m.goapp.lAMVersion
   swselect('glmaster',.T.)
ENDIF
IF m.goapp.lQBVersion
   swselect('inctxnid',.T.)
ENDIF

swselect('income',.T.)
swselect('incsusp',.T.)


DO CASE
   CASE m.goapp.lAMVersion
      SELECT cbatch FROM income WHERE nRunno = 0 AND cRevKey = 'COST' AND cRefID = 'Cost Rec' AND cSource = 'OTAX4' INTO CURSOR tempcost READWRITE ORDER BY cbatch GROUP BY cbatch
      SELECT cbatch FROM incsusp WHERE cRevKey = 'COST' AND cRefID = 'Cost Rec' AND cSource = 'OTAX4' INTO CURSOR tempcost1 ORDER BY cbatch GROUP BY cbatch
      IF _TALLY > 0
         SELECT tempcost
         APPEND FROM DBF('tempcost1')
      ENDIF
      SELECT tempcost
      WAIT WINDOW NOWAIT 'Removing G/L Entries...'
      SCAN
         SCATTER MEMVAR
         SELECT glmaster
         SCAN FOR cbatch = m.cbatch
            DELETE NEXT 1
         ENDSCAN
      ENDSCAN
      WAIT clear
      SELECT income
      SCAN FOR nRunno = 0 AND cRevKey = 'COST' AND cRefID = 'Cost Rec' AND cSource = 'OTAX4'
         WAIT WINDOW NOWAIT 'Removing entries for well: ' + ALLTRIM(income.cwellid)
         SELECT income
         DELETE NEXT 1
      ENDSCAN

      SELECT incsusp
      SCAN FOR cRevKey = 'COST' AND cRefID = 'Cost Rec' AND cSource = 'OTAX4'
         WAIT WINDOW NOWAIT 'Removing entries for well: ' + ALLTRIM(incsusp.cwellid)
         SELECT incsusp
         DELETE NEXT 1
      ENDSCAN

      SELECT glmaster
      =TABLEUPDATE(.T.)

   CASE m.goapp.lQBVersion
      IF NOT m.goapp.lQBActive
         oMessage.Warning('The connection to QuickBooks is not currently active. The Cost Recovery Fee adjustments cannot be removed at this time.')
         RETURN .F.
      ENDIF

      * Clear any prior errors
      m.goapp.oQB.oQBSM.ClearErrorRecovery()

      * get a message set request object (version 1.1 xml)
      loRequest = m.goapp.oQB.oQBRequest

      * set the on error attribute for the request
      loRequest.ATTRIBUTES.OnError = 1
      loRequest.ClearRequests()

      SELECT income
      SCAN FOR nRunno = 0 AND cRevKey = 'COST' AND cRefID = 'Cost Rec' AND cSource = 'OTAX4'
         SCATTER MEMVAR
         SELE inctxnid
         LOCATE FOR cidinco = m.cidinco
         IF FOUND()
            m.ctxnid = ctxnid
            * add a request to delete the receipt
            loRcptDel = loRequest.AppendTxnDelRq()
            IF m.goapp.oQB.QBFCVersion > ' 4.0'
               loRcptDel.TxnDelType.SetValue(15)
            ELSE
               loRcptDel.TxnDelType.SetValue(14)
            ENDIF
            loRcptDel.TxnID.SetValue(m.ctxnid)

            loResponse = m.goapp.oQB.oQBSM.DoRequests(loRequest)
            loDelResp  = loResponse.responselist.getat(0)
            loRequest.ClearRequests()
            m.goapp.oQB.oQBSM.ClearErrorRecovery()
         ENDIF
         WAIT WINDOW NOWAIT 'Removing entries for well: ' + ALLTRIM(income.cwellid)
         SELE income
         DELE NEXT 1
      ENDSCAN
      SELECT incsusp
      SCAN FOR cRevKey = 'COST' AND cRefID = 'Cost Rec' AND cSource = 'OTAX4'
         SCATTER MEMVAR
         SELE inctxnid
         LOCATE FOR cidinco = m.cidinco
         IF FOUND()
            m.ctxnid = ctxnid
            * add a request to delete the receipt
            loRcptDel = loRequest.AppendTxnDelRq()
            IF m.goapp.oQB.QBFCVersion > ' 4.0'
               loRcptDel.TxnDelType.SetValue(15)
            ELSE
               loRcptDel.TxnDelType.SetValue(14)
            ENDIF
            loRcptDel.TxnID.SetValue(m.ctxnid)

            loResponse = m.goapp.oQB.oQBSM.DoRequests(loRequest)
            loDelResp  = loResponse.responselist.getat(0)
            loRequest.ClearRequests()
            m.goapp.oQB.oQBSM.ClearErrorRecovery()
         ENDIF
         WAIT WINDOW NOWAIT 'Removing entries for well: ' + ALLTRIM(incsusp.cwellid)
         SELE incsusp
         DELE NEXT 1
      ENDSCAN

      SELECT inctxnid
      =TABLEUPDATE(.T.)

      *  Stand-alone Disbursement Manager
   CASE NOT m.goapp.lAMVersion AND NOT m.goapp.lQBVersion
      SELECT income
      SCAN FOR nRunno = 0 AND cRevKey = 'COST' AND cRefID = 'Cost Rec' AND cSource = 'OTAX4'
         WAIT WINDOW NOWAIT 'Removing entries for well: ' + ALLTRIM(income.cwellid)
         DELE NEXT 1
      ENDSCAN
      SELECT incsusp
      SCAN FOR cRevKey = 'COST' AND cRefID = 'Cost Rec' AND cSource = 'OTAX4'
         WAIT WINDOW NOWAIT 'Removing entries for well: ' + ALLTRIM(incsusp.cwellid)
         DELE NEXT 1
      ENDSCAN

ENDCASE

SELECT income
=TABLEUPDATE(.T.)
SELECT incsusp
=TABLEUPDATE(.T.)

oMessage.DISPLAY('Finished removing the Cost Recovery Fee adjustments.')




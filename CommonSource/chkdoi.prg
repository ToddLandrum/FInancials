LPARA tcWellID, tcClass
LOCAL lcMessage, lcType

IF EMPTY(tcWellID)
   RETURN .T.
ENDIF

SWSELECT('wellinv')   

** Remove any blank wells and owners
swCleanDOI()

SWSELECT('wells')
SET ORDER TO cwellid
IF SEEK(tcWellID)
   IF cWellStat = 'V' OR cWellStat = 'I'
      RETURN .T.
   ENDIF
ENDIF      

DO CASE
   CASE tcClass = 'BBL'
      SELECT SUM(nrevoil) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Oil Revenue'
   CASE INLIST(tcClass,'MCF','COMP','GATH')
      SELECT SUM(nrevgas) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Gas Revenue'
   CASE tcClass = 'TRANS'
      SELECT SUM(nrevtrp) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Trans Revenue'
   CASE tcClass = 'MISC1'
      SELECT SUM(nrevmisc1) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Misc Revenue 1'
   CASE tcClass = 'MISC2'
      SELECT SUM(nrevmisc2) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Misc Revenue 2'
   CASE tcClass = 'OTH'
      SELECT SUM(nrevoth) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Other Revenue'   
   CASE tcClass = 'OTAX1'
      SELECT SUM(nrevtax1) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Oil Tax 1'
   CASE tcClass = 'OTAX2'
      SELECT SUM(nrevtax4) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Oil Tax 2'
   CASE tcClass = 'OTAX3'
      SELECT SUM(nrevtax7) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Oil Tax 3'
   CASE tcClass = 'OTAX4'
      SELECT SUM(nrevtax10) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Oil Tax 4'
   CASE tcClass = 'GTAX1'
      SELECT SUM(nrevtax2) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Gas Tax 1'
   CASE tcClass = 'GTAX2'
      SELECT SUM(nrevtax5) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Gas Tax 2'
   CASE tcClass = 'GTAX3'
      SELECT SUM(nrevtax8) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Gas Tax 3'
   CASE tcClass = 'GTAX4'
      SELECT SUM(nrevtax11) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Gas Tax 4'
   CASE tcClass = 'PTAX1'
      SELECT SUM(nrevtax3) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Other Tax 1'
   CASE tcClass = 'PTAX2'
      SELECT SUM(nrevtax6) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Other Tax 2'
   CASE tcClass = 'PTAX3'
      SELECT SUM(nrevtax9) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Other Tax 3'
   CASE tcClass = 'PTAX4'
      SELECT SUM(nrevtax12) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Other Tax 4'
   CASE tcClass = '0'
      SELECT SUM(nworkint) AS nInterest FROM wellinv WHERE cwellid = tcWellID AND cTypeInv='W' INTO CURSOR tempdoi
      lcType = 'Working Interest'
   CASE tcClass = '1'
      SELECT SUM(nintclass1) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Expense Class 1'
   CASE tcClass = '2'
      SELECT SUM(nintclass2) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Expense Class 2'
   CASE tcClass = '3'
      SELECT SUM(nintclass3) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Expense Class 3'
   CASE tcClass = '4'
      SELECT SUM(nintclass4) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Expense Class 4'
   CASE tcClass = '5'
      SELECT SUM(nintclass5) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Expense Class 5'
   CASE tcClass = 'A'
      SELECT SUM(nACPint) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Expense Class A'   
   CASE tcClass = 'B'
      SELECT SUM(nBCPint) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Expense Class B'   
   CASE tcClass = 'P'
      SELECT SUM(nplugpct) AS nInterest FROM wellinv WHERE cwellid = tcWellID INTO CURSOR tempdoi
      lcType = 'Plugging'      
   OTHERWISE
      lcType = ''
      wait wind 'Invalid Class Passed To CHKDOI: ' + tcClass
      RETURN .f. 
ENDCASE

oMessage = FindGlobalObject('cmMessage')

IF USED('tempdoi')
   SELECT tempdoi
   IF RECC() > 0
      m.nInterest = nInterest
   ELSE
      m.nInterest = 0
   ENDIF

   IF m.nInterest <> 100
      lcMessage = 'The division of interest does not total 100% for ' + lcType + ' in this well.' + ;
                  ' The ' + lcType + ' interest total is ' + STR(m.nInterest,11,7)
      oMessage.Warning(lcMessage)
      RETURN .F.
   ELSE
      RETURN .T.
   ENDIF
ELSE
   lcMessage = 'The division of interest does not total 100% in this well.'
   oMessage.Warning(lcMessage)
   RETURN .F.
ENDIF

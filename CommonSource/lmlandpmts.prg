LOCAL oLand, llReturn, oMeta, oMessage, lcDataBase, lcPath, llCheck, lnFiles

oMessage = FindGlobalObject('cmMessage')

lcPath = ALLT(m.goapp.cDataFilePath)

IF TYPE('m.goApp') <> 'O'
   m.cProducer = 'Development Company'
ELSE
   m.cProducer = m.goapp.cCompanyName
ENDIF

swSELECT('landopt')
llChkDueStart = lChkDueStart
lnLeadDays    = nLeadDays

lnfiles = ADIR(lafiles,'datafiles\*.drp')

IF lnfiles > 0
   IF FILE('datafiles\'+ALLTRIM(m.goapp.cuser)+'.drp')
      llCheck = .t.
   ELSE
      llCheck = .f.
   ENDIF
ELSE
   llCheck = .t.
ENDIF

IF llCheck AND llChkDueStart AND oMessage.CONFIRM('Do you want to check for delay rental payments/expiring leases?')
   swSELECT('landopt')
   WAIT WIND NOWAIT 'Checking for Delay Rental Payments....'
   oLand = CREATEOBJECT('Land')
   llReturn = oLand.BuildPmts(1,DATE()+lnLeadDays,DATE()+lnLeadDays)
   WAIT CLEAR
   IF llReturn
      lcTitle1 = 'Coming Delay Rental Payments'
      lcTitle2 = ''
      lcSelect = 'All Leases'
      lcSortOrder = 'Lease ID'
      SELECT landpmts
      REPORT FORM lmrlandpmts PREVIEW
   ELSE
      MESSAGEBOX('There are no delay rental payments due within the next ' + TRANSFORM(lnLeadDays) + ' days.',64,'Check For Delay Rentals')
   ENDIF
ENDIF



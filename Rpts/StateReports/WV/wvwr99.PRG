LOCAL lnCount

*
*  Prints the closed period listing
*

IF TYPE('m.goApp') <> 'O'
   m.cProducer = 'Development Company'
ELSE
   m.cProducer = m.goApp.cCompanyName
ENDIF

oMessage = findglobalobject('cmMessage')

lcTitle1 = ''
lcTitle2 = ''
CREATE cursor temp ;
  (temp  c(1))
m.temp = 'x'
insert into temp from memvar  
REPORT FORM (m.goapp.cRptsFolder+'StateReports\WV\WVwr99.frx') TO PRINTER PROMPT PREVIEW
IF oMessage.Confirm('Should the report be sent to the printer now?')
   report form (m.goapp.cRptsFolder+'StateReports\WV\WVwr99.frx') TO PRINTER PROMPT NOCONSOLE NOEJECT
ENDIF   
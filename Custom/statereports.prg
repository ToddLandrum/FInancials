LPARAMETERS toApp, tcFormName, tcstate
LOCAL lcMessage, lcFormName 
PUBLIC m.goApp

m.goApp = toApp
lcMessage = ''

IF VARTYPE(toApp) # 'O'
   lcMessage = 'The global application object must be passed to state reporting.' + CHR(13)
ENDIF

IF VARTYPE(tcFormName) # 'C'
   lcMessage = lcMessage + 'The form name must be passed to state reporting.' + CHR(13)
ENDIF
IF VARTYPE(tcFormName) # 'C'
   lcMessage = lcMessage + 'The state must be passed to the state reports.' + CHR(13)
ENDIF 
IF NOT EMPTY(lcMessage)
   MESSAGEBOX(lcMessage,16,'Missing Parameters')
   RETURN .f.
ENDIF 

ADDPROPERTY(m.goapp,'cState',tcState)

DO loadclasses
DO loadprocedures
lcFormname = tcFormName

IF 'SCX' $ UPPER(lcFormName)
   DO FORM (lcFormName)
ELSE
   DO (lcFormName)
ENDIF    

RETURN .t. 
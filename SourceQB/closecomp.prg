*
*   Program:     CloseComp
*   Description: Closes the currently open company
*
LOCAL oRegistry

#include source\appdefs.h

lcVersion = m.goApp.cFileVersion
oRegistry = FindGlobalObject('cmRegistry')
oRegistry.SetUserKeyValue('%Local.Application.Last Open Company', .NULL.)
RELE oRegistry
CLOSE DATA ALL
SET DATASESSION TO 1
CLOSE DATA ALL
m.goApp.cDataFilePath = ''
m.goApp.lOpenCompany  = .F.

IF m.goApp.lQBActive
   m.goApp.oQB.QBClose()
ENDIF
   

_SCREEN.CAPTION = 'Disbursement and JIB Manager QB Edition V' + lcVersion + VERSION_SUB + ' - NO COMPANY OPEN'

      
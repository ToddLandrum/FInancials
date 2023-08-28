*
*   Program:     DeleteComp
*   Description: Presents a picklist so the user can choose a company to delete
*
LOCAL lcPath, oRegistry, lcidComp, lcList
PRIV llOK

*#include source\appdefs.h

llOK = .T.
lcPath = .NULL.
lcList = 'cProducer\Company,cdatapath\Data File Path'

IF NOT USED('compmast')
   USE datafiles\compmast IN 0
ENDIF

*
*  Get the pointer to the registry object
*
oRegistry = FindGlobalObject('cmRegistry')
oMessage = FindGlobalObject('cmMessage')

SET DELETED ON

IF NOT USED('compmast')
   USE datafiles\compmast IN 0
ENDIF

DO FORM ..\CUSTOM\picklist WITH 'Compmast', lcList, 'cidcomp', 2, .T.,.T.,'Delete Company', 556

IF llOK
   IF NOT 'SAMPLE' $ UPPER(compmast.cProducer)
      IF compmast.cidcomp = m.goapp.cidcomp
         omessage.warning('The currently open company cannot be deleted. Switch to another company before deleting this company.')
         RETURN
      endif
      IF messagebox('Do you want to delete the company record for ' + ALLTRIM(compmast.cProducer) + '? This will not delete the data for this company.',17,'Delete Confirmation') = 1
         SELECT compmast
         DELETE NEXT 1
      ENDIF
   ELSE
      oMessage.Warning("The Sample Company cannot be deleted.  Please select a different company to be deleted.")
   ENDIF
ENDIF

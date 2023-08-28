LPARA tcBatch
LOCAL m.cYear, m.cPeriod, m.cWellID, m.cGroup, lcPath, llOpExp, oMessage

STORE .F. TO llOpExp

oMessage = FindGlobalObject('cmmessage')

IF TYPE('m.goApp') = 'O'
   lcPath = ALLTRIM(m.goApp.cDataFilePath)
ELSE
   lcPath = 'Data\'
ENDIF

IF NOT USED('expense')
   USE (lcPath+'expense') IN 0
   llOpExp = .T.
ENDIF

*  Check to see if expenses entered for wells were allocated
*  If so, and the period is closed, let the user know he can't 
*  modify this entry.

SELECT expense
SCAN FOR cBatch = tcBatch
   IF lClosed
      oMessage.Warning('These expenses have already been allocated to the well and processed. They cannot be modified.')
      RETURN .F.
   ENDIF   
ENDSCAN 

*
*  If files were opened, make sure we close them
*
IF llOpExp
   USE IN expense
ENDIF

RETURN .T.
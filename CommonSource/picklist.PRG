LPARAMETERS tnDataSession, tcTable, tcList, tcKey, tnFields, tlCursor, tlCaptions
LOCAL lnNewRecNo
PRIVATE llOK

TRY
   IF VARTYPE(tnDatasession) = 'N'
      SET DATASESSION TO tnDataSession
   ENDIF
CATCH
ENDTRY

llOK = .f.

DO FORM picklist WITH tcTable, tcList, tcKey, tnFields, tlCursor, tlCaptions

IF llOK
   SELECT (tcTable)
   lnNewRecNo = RECNO()
ELSE
   lnNewRecNo = -1
ENDIF

RETURN lnNewRecNo
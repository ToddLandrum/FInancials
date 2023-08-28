* swExternal - call external forms and reset the environment when we get back
LPARAMETERS tcForm, tcParm

lcClasslib = SET('classlib')

TRY 
   IF PARAMETERS() = 1
      DO FORM (tcForm)
   ELSE
      DO FORM (tcForm) with tcParm
   ENDIF    
CATCH TO loError
    IF loError.errorno = 1
       MESSAGEBOX('The form setup in menupads does not exist: ' + ALLTRIM(tcform),16,'Invalid custom form')
    ENDIF 
FINALLY
   SET CLASSLIB TO &lcClassLib
ENDTRY    


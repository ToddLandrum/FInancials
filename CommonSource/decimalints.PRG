****************************************************************************************
*  Created: 3/14/21
*  Author:   Phil Sherwood
*
* Purpose: Changes the interest fields in the cursor that is passed to be decimal 
*          interests instead of whole pcts
* 
*
*
* Parameters:  tcCursor - The cursor the interests are to be changed in
*
* Changes:
*
****************************************************************************************
LPARAMETERS tcCursor
LOCAL llReturn, x, lcField, m.cfieldname, lnFields

llReturn = .t.


TRY

   IF PEMSTATUS(m.goapp.oOptions,'lDecimalInts',5) = .T.
      IF NOT m.goapp.oOptions.lDecimalInts
         llReturn = .T.
         EXIT
      ENDIF
   ELSE
      llReturn = .T.
      EXIT 
   ENDIF

   * Get a copy of the cursor into a readwrite cursor so we can update it
   SELECT * FROM (tcCursor) INTO CURSOR temp READWRITE 
   
   * Get a list of tags so we can recreate them
   lnTags = ATAGINFO(laTags,tcCursor)

   CREATE CURSOR interestfields (cfieldname C(15))
   
   * Get the fields into an array
   lnFields = AFIELDS(laFields,tcCursor)
   
   FOR x = 1 TO lnFields
      IF laFields[x, 2] = 'N'
         IF laFields[x, 3] = 11 AND laFields[x, 4] = 7
            m.cFieldname = laFields[x, 1]
            INSERT INTO interestfields FROM MEMVAR  
         ENDIF 
      ENDIF 
   ENDFOR 
   
   lnCount = RECCOUNT('interestfields')
   
   IF lnCount > 0
      SELECT temp
      SCAN
         SELECT interestfields
         SCAN
            lcField = cFieldName
            SELECT temp
            REPLACE &lcField WITH &lcField / 100
         ENDSCAN 
      ENDSCAN 
   ENDIF 
   
   * Put the changed data back into the original cursor
   SELECT * FROM temp INTO CURSOR (tcCursor) READWRITE 

   IF lnTags > 0
      FOR x = 1 TO lnTags
         lcTag  = laTags[x, 1]
         lcExpr = laTags[x, 3]
         INDEX on &lcExpr TAG &lcTag 
      ENDFOR 
   ENDIF 
   
   USE IN temp 
   
CATCH TO loErr
    MESSAGEBOX('Error: ' + loErr.message,0,'DecimalInts')
    llreturn = .f.
ENDTRY 

RETURN llReturn   

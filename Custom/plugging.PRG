DEFINE CLASS plugging AS CUSTOM

   NAME = "plugging"

   oRegistry = .NULL.
   oMessage  = .NULL.


*************************
   PROCEDURE INIT
*************************

   THIS.oRegistry = findglobalobject('cmRegistry')
   THIS.oMessage  = findglobalobject('cmMessage')

   ENDPROC


*************************************************************
   FUNCTION GetBalOwner( tcOwner, tcWell, tcRunYear, tnRunno, tlBefore)
*************************************************************
   LOCAL lcWhere1, lcWhere2, llByWell, llByOwner, llReturn, loError, lnBalance

   STORE .T. TO llReturn
   lnBalance = 0

   TRY

      IF tlBefore
         lcWhere1 = "cRunYear + PADL(TRANSFORM(nrunno), 3, '0') < tnRun"
      ELSE
         lcWhere1 = "cRunYear + PADL(TRANSFORM(nrunno), 3, '0') <= tnRun"
      ENDIF 
           
      IF VARTYPE(tcOwner) # 'C'
         llReturn = .F.
         EXIT
      ELSE
         IF tcOwner = '*'  && an * means all owners
            IF VARTYPE(tcWell) # 'C' OR tcWell = '*'
               lcWhere2 = 'cOwnerid = tcOwner'
            ELSE
               lcWhere2  = 'cOwnerid = tcOwner AND cWellID = tcWell'
            ENDIF
         ELSE
            IF VARTYPE(tcWell) # 'C' OR tcWell = '*'
               lcWhere2 = 'cOwnerID = tcOwner'
            ELSE  
               lcWhere2  = 'cOwnerid = tcOwner AND cWellID = tcWell'
            ENDIF    
         ENDIF 
      ENDIF

      swselect('plugbalwell')
      tnRun = tcRunYear + PADL(TRANSFORM(tnRunno), 3, '0')

      SELECT  cownerid, ;
              cwellid, ;
              SUM(nPlugging) AS nBalance ;
          FROM plugbalwell ;
          WHERE &lcWhere1 ;
              AND &lcWhere2 ;
          INTO CURSOR tempplugbal ;
          ORDER BY cownerid, cwellid ;
          GROUP BY cownerid, cwellid
      
      GO top
      lnBalance = nBalance

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'GetBalOwner', loError.LINENO, 'Plugging', loError.ERRORNO, loError.MESSAGE, ' ', loError
      MESSAGEBOX('Unable to process the plugging fund at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
           'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY
   
   IF tcOwner = '*'
      RETURN lnBalance
   ENDIF 

   ENDFUNC

*************************************************************
   FUNCTION GetBalWell(tcWell, tcRunYear, tnRunno, tlBefore)
*************************************************************
   LOCAL lcWhere1, lcWhere2, llByWell, llReturn, loError, lnBalance

   STORE .T. TO llReturn
   lnBalance = 0

   TRY

      IF tlBefore
         lcWhere1 = "cRunYear + PADL(TRANSFORM(nrunno), 3, '0') < tnRun"
      ELSE
         lcWhere1 = "cRunYear + PADL(TRANSFORM(nrunno), 3, '0') <= tnRun"
      ENDIF 
         
      IF VARTYPE(tcWell) # 'C'
         llReturn = .F.
         EXIT
      ELSE
         IF tcWell = '*'   && an * means balances for all wells
            lcWhere2 = '.t.'
         ELSE    
            lcWhere2  = 'cWellID = tcWell'
         ENDIF    
      ENDIF

      swselect('plugbalwell')
      tnRun = tcRunYear + PADL(TRANSFORM(tnRunno), 3, '0')

      SELECT  cwellid, ;
              SUM(nPlugging) AS nBalance ;
          FROM plugbalwell ;
          WHERE &lcWhere1 ;
              AND &lcWhere2 ;
          INTO CURSOR tempplugbal ;
          ORDER BY cwellid ;
          GROUP BY cwellid
          
      GO TOP 
      lnBalance = nbalance

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'GetBalWell', loError.LINENO, 'Plugging', loError.ERRORNO, loError.MESSAGE, ' ', loError
      MESSAGEBOX('Unable to process the plugging fund at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
           'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY
   
   IF tcWell = '*'
      RETURN lnBalance
   ENDIF 

   ENDFUNC
   
   
****************************************************
   FUNCTION CurrentBalance(tcWell)
****************************************************
**********************************************************
* Returns the plugging amount collected for the given well
* 
* 8/11/18 - pws
**********************************************************
LOCAL lnBalance

swselect('plugwellbal')

SELECT SUM(nPlugging) as nBalance ;
   FROM plugwellbal ;
   WHERE cWellID = tcWell ;
   INTO CURSOR temp 
   
 IF _tally > 0
    lnBalance = nBalance
 ELSE
    lnBalance = 0
 ENDIF
 
 RETURN lnBalance   
      
****************************************************
   FUNCTION UseBalance(tcOwner, tcRunYear, tnRunno)
****************************************************



   ENDFUNC

****************************************************
   FUNCTION RptBalance(tcOwner, tcRunYear, tnRunno)
****************************************************


   ENDFUNC

****************************************************
   FUNCTION AddPluggingFundRecs(tcCursor)
****************************************************
* Add the records in the passed cursor to the plugwellbal table
* Assumes: The records in the cursor have all the fields
*          needed to add records to plugwellbal 
*
* 8/25/18 - pws
****************************************************
LOCAL loError, llReturn

llReturn = .T.

TRY
   IF NOT USED(tcCursor)
      llReturn = .F.
   ENDIF

   SELECT (tcCursor)
   SCAN
      SCATTER MEMVAR
      INSERT INTO plugwellbal FROM MEMVAR
   ENDSCAN
CATCH TO loError
   llReturn = .F.
ENDTRY

RETURN llReturn

ENDFUNC 

ENDDEFINE
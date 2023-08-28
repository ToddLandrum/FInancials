**  Scans through the chart of accounts, and uses the title/total account settings  **
**  to add parent accounts instead.  Will check up to 5 levels deep.                **
**  This should be an X-flags procedure, since it only needs to be done once.       **
LOCAL lcParent1, lcParent2, lcParent3, lcParent4, lcParent5, lcParent6, oMessage

STORE '' TO lcParent1, lcParent2, lcParent3, lcParent4, lcParent5, lcParent6

* Check to see if we need to run this utility.
* If there are any parent fields that have data already in them, we
* skip out.


IF NOT USED('coa')
   USE coa IN 0
ENDIF
IF NOT USED('glmaster')
   USE glmaster IN 0
ENDIF

SELECT cparent FROM coa WHERE NOT EMPTY(cparent) INTO CURSOR temp
IF _tally > 0
   USE IN temp
   RETURN
ENDIF

* No need to process if there are not title or totaling accounts
SELECT coa
LOCATE FOR ltitle OR ltotalacct
IF NOT FOUND()
   RETURN
ENDIF 

WAIT WINDOW NOWAIT 'Processing Parent/Sub Accounts...Please Wait' 

IF USED('totaltemp')
   USE IN TotalTemp
ENDIF 

CREATE CURSOR TotalTemp  ;
   (cAcctNo      c(8),  ;
   cAcctDesc     c(30))
INDEX on cAcctNo TAG cAcctNo

oMessage = findglobalobject('cmMessage')

SELECT coa
SET ORDER TO acctno
SCAN
   SCATTER memvar
   IF lTitle = .T.  &&  An account that will have subaccounts
      DO CASE
         CASE EMPTY(lcParent2)  &&  No second level parent defined yet, so store this value in it
            lcParent2 = coa.cAcctNo
         CASE EMPTY(lcParent3)  &&  No third level parent defined yet, so store this value in it
            lcParent3 = coa.cAcctNo
         CASE EMPTY(lcParent4)  &&  No fourth level parent defined yet, so store this value in it
            lcParent4 = coa.cAcctNo
         CASE EMPTY(lcParent5)  &&  No fifth level parent defined yet, so store this value in it
            lcParent5 = coa.cAcctNo
         CASE EMPTY(lcParent6)  &&  No sixth level parent defined yet, so store this value in it
            lcParent6 = coa.cAcctNo
      ENDCASE
      REPLACE lTitle WITH .F.  &&  No need to keep the flag set once the processing is done
      LOOP  &&  For a title account, no need to proceed any further in this loop
   ENDIF

   IF NOT lTitle AND NOT lTotalAcct  &&  Not a title or totaling account, so fill in the parent
      DO CASE
         CASE NOT EMPTY(lcParent6)  &&  Start at the deepest level, checking to see what level it's at
            REPLACE cParent WITH lcParent6
         CASE NOT EMPTY(lcParent5)
            REPLACE cParent WITH lcParent5
         CASE NOT EMPTY(lcParent4)
            REPLACE cParent WITH lcParent4
         CASE NOT EMPTY(lcParent3)
            REPLACE cParent WITH lcParent3
         CASE NOT EMPTY(lcParent2)
            REPLACE cParent WITH lcParent2
         OTHERWISE
            REPLACE cParent WITH lcParent1
      ENDCASE
   ENDIF

   IF lTotalAcct = .T.  &&  Total account, so reset the parent account to be the next level up
      DO CASE
         CASE NOT EMPTY(lcParent6)  &&  Start at the deepest level, checking to see what level it's at
            lcParent6 = ''
         CASE NOT EMPTY(lcParent5)
            lcParent5 = ''
         CASE NOT EMPTY(lcParent4)
            lcParent4 = ''
         CASE NOT EMPTY(lcParent3)
            lcParent3 = ''
         CASE NOT EMPTY(lcParent2)
            lcParent2 = ''
      ENDCASE
      REPLACE lTotalAcct WITH .F.  &&  No need to keep the flag set once the processing is done
      
      SELECT glmaster  &&  Check to see if there's any activity for this Totaling account, and if there's not, delete it
      LOCATE FOR cAcctNo = coa.cAcctNo
      IF NOT FOUND()
         SELECT coa
         DELETE NEXT 1
      ELSE
         INSERT INTO TotalTemp FROM MEMVAR  &&  Only include items that have not been deleted, so they can be reported on 
      endif
   ENDIF
ENDSCAN

SELECT TotalTemp
SET ORDER to cAcctNo
IF RECCOUNT() > 0  &&  Former totaling accounts that couldn't be deleted, so show a report of them to the user
   REPORT FORM gltotalrpt PREVIEW
   IF oMessage.CONFIRM('Should the report be sent to the printer now?')
      REPORT FORM gltotalrpt TO PRINTER PROMPT NOCONSOLE NOEJECT
   ENDIF
ENDIF

IF USED('coa')
   USE IN coa
ENDIF

IF USED('temp')
   USE IN temp
ENDIF 

IF USED('totaltemp')
   USE IN TotalTemp
ENDIF 

WAIT clear
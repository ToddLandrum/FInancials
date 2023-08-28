**  Scans DOI and combines interests for the same owner, well, program, and interest type  **

LOCAL lcidwinv, llReturn, loError
llReturn = .T.

TRY

   swselect('wellinv')

   SELECT  cownerid, cwellid, ctypeinv, cprogcode, COUNT(*) AS ncount ;
	   FROM wellinv ;
	   INTO CURSOR temp ;
	   ORDER BY cownerid, cwellid, ctypeinv, cprogcode, cdeck ;
	   GROUP BY cownerid, cwellid, ctypeinv, cprogcode, cdeck

   IF _TALLY > 0
	  SELECT  cownerid, cwellid, cDeck, 'B' AS ctypeint, ctypeinv, cprogcode, COUNT(cownerid) AS ncount,  ;
			  SUM(nworkint)   AS nworkint, SUM(nRevOil)      AS nRevOil, SUM(nRevGas)     AS nRevGas,  ;
			  SUM(nRevOth)    AS nRevOth, SUM(nRevMisc1)     AS nRevMisc1, SUM(nRevMisc2) AS nRevMisc2,  ;
			  SUM(nIntClass1) AS nIntClass1, SUM(nIntClass2) AS nIntClass2,  ;
			  SUM(nIntClass3) AS nIntClass3, SUM(nIntClass4) AS nIntClass4,  ;
			  SUM(nIntClass5) AS nIntClass5, SUM(nRevTrp)    AS nRevTrp,  ;
			  SUM(nbcpint)    AS nbcpint, SUM(nacpint)       AS nacpint,  ;
			  SUM(napoint)    AS napoint, SUM(nRevTax1)      AS nRevTax1,  ;
			  SUM(nRevTax2)   AS nRevTax2, SUM(nRevTax3)     AS nRevTax3,  ;
			  SUM(nRevTax4)   AS nRevTax4, SUM(nRevTax5)     AS nRevTax5,  ;
			  SUM(nRevTax6)   AS nRevTax6, SUM(nRevTax7)     AS nRevTax7,  ;
			  SUM(nRevTax8)   AS nRevTax8, SUM(nRevTax9)     AS nRevTax9,  ;
			  SUM(nRevTax10)  AS nRevTax10, SUM(nRevTax11)   AS nRevTax11,  ;
			  SUM(nRevTax12)  AS nRevTax12  ;
		  FROM wellinv ;
		  WHERE NOT lFlat ;
		  GROUP BY cownerid, cwellid, ctypeinv, cprogcode, cdeck ;
		  INTO CURSOR temp

      SELECT temp
      SCAN FOR ncount > 1
         SCATTER MEMVAR
         SELECT wellinv
         LOCATE FOR cownerid = m.cownerid AND cwellid = m.cwellid AND ctypeinv = m.ctypeinv AND cprogcode = m.cprogcode AND cdeck = m.cdeck
         IF FOUND()
            GATHER MEMVAR
            lcidwinv = wellinv.cidwinv
         ELSE
            LOOP  &&  Should never get here
         ENDIF
         SELE wellinv
         SCAN FOR cidwinv <> lcidwinv ;
              AND cwellid = m.cwellid ;
              AND cdeck   = m.cdeck ;
              AND cownerid = m.cownerid ;
              AND ctypeinv = m.ctypeinv ;
              AND cprogcode = m.cprogcode ;
              AND NOT lFlat
            DELETE NEXT 1
         ENDSCAN
      ENDSCAN
   ENDIF
CATCH TO loError
   llReturn = .F.
   DO errorlog WITH 'CombineDOI', loError.LINENO, 'CombineDOI', loError.ERRORNO, loError.MESSAGE
ENDTRY

RETURN llReturn
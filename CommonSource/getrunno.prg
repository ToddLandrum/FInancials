LPARA tcyear, tlnew, tcType, tlYear

IF TYPE('tcType') <> 'C'
   tcType = 'R'
ENDIF
   
*
*  Gets the next run no for the given year if tlNew = .t.
*  or gets the last run no for the given year if tlNew = .f.
*
SELE cyear, nrunno FROM sysctl WHERE cTypeClose=tctype AND cyear = tcyear AND NOT DELETED() INTO CURSOR temp ORDER BY cyear, nrunno
SELE temp
IF RECC() > 0
   GO BOTT
   IF tlnew
      lnrunno = nrunno + 1
      lcYear  = cYear
   ELSE
      lnrunno = nrunno
      lcYear  = cYear
   ENDIF
ELSE
   lcYear = tcYear
   IF tlnew
      lnrunno = 1
   ELSE
      lnrunno = 0
   ENDIF
ENDIF

if not tlyear
   RETURN lnrunno
else
   RETURN lcYear
endif      

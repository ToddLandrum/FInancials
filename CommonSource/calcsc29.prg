*=================================================================================
*  Program....: CALCSC29.PRG
*  Version....: 1.0
*  Author.....: Phil W. Sherwood
*  Date.......: June 28, 1996
*  Notice.....: Copyright (c) 1994-1996 SherWare, Inc., All Rights Reserved.
*  Compiler...: FoxPro 2.6a
*) Description: Calculates section 29 credits.
*  Parameters.: tcYear - The year the section 29 credits are for.
*               tcOwner1 - The first owner to calculate the credit for.
*               tcOwner2 - The last owner to calculate the credit for.
*  Changes....:
*     10/17/99  pws - Changed to visual foxpro version
*     11/25/03  pws - add date range processing
*=================================================================================
LPARAMETERS tcYear, tcOwner1, tcOwner2, tdDate1, tdDate2
LOCAL lnYear

lnYear = VAL(tcYear)

if vartype(tdDate1) <> 'D'
   llDate = .f.
else   
   llDate = .t.
endif
   
IF NOT USED('options')
   USE options IN 0
ENDIF
SELECT options
GO TOP
lnSect29Rate = nSect29Rate
IF EMPTY(lnSect29Rate)
   lnSect29Rate = 6.28
ENDIF   
   
CREATE CURSOR tempsc29 ;
 (cidlease    C(10),  ;
  cleasename  C(30), ;
  cownerid    C(10), ;
  cownname    C(40), ;
  nTotMcf     N(12), ;
  ngasint     N(11,7), ;
  nMcfShare   N(12), ;
  nMcfBbl     N(12), ;
  nCredit     N(12), ;
  nSect29Rate N(9,2))

if not llDate
   SELECT disbhist.cwellid AS cidlease, ;
          wells.cwellname  AS cleasename, ;
          investor.cownerid, ;
          investor.cownname, ;
          000000.00       AS nTotMcf, ;
          000000.00       AS nMcfShare, ;
          disbhist.nrevgas AS ngasint ;
     FROM disbhist, wells, investor ;
     WHERE wells.lsection29 = .T. ;
       AND disbhist.cwellid = wells.cwellid ;
       AND disbhist.cownerid = investor.cownerid ;
       AND BETWEEN(disbhist.cownerid, tcOwner1, tcOwner2) ;
       AND YEAR(disbhist.hdate) = lnYear ;
     INTO CURSOR temp ;
     ORDER BY disbhist.cownerid, cleasename ;
     GROUP BY disbhist.cownerid, cleasename
else
   SELECT disbhist.cwellid AS cidlease, ;
          wells.cwellname  AS cleasename, ;
          investor.cownerid, ;
          investor.cownname, ;
          000000.00       AS nTotMcf, ;
          000000.00       AS nMcfShare, ;
          disbhist.nrevgas AS ngasint ;
     FROM disbhist, wells, investor ;
     WHERE wells.lsection29 = .T. ;
       AND disbhist.cwellid = wells.cwellid ;
       AND disbhist.cownerid = investor.cownerid ;
       AND BETWEEN(disbhist.cownerid, tcOwner1, tcOwner2) ;
       AND BETWEEN(hdate,tdDate1,tdDate2) ;
     INTO CURSOR temp ;
     ORDER BY disbhist.cownerid, cleasename ;
     GROUP BY disbhist.cownerid, cleasename
endif     
   
*
*  If no records are found, return
*   
IF _tally = 0
   RETURN
ENDIF
*
*  Append records into tempsc29 cursor
*   
SELECT tempsc29
APPEND FROM DBF('temp')
IF USED('temp')
   SELECT temp
   USE
ENDIF       
 
*
*  Fill in the total MCF
*
if not llDate
   SELECT cwellid, SUM(ntotmcf) AS ntotmcf ;
     FROM wellhist ;
     WHERE YEAR(wellhist.hdate) = lnYear ;
       AND cwellid IN (SELECT cwellid FROM wells WHERE lSection29 = .T.) ;
     INTO CURSOR temp29 ;
     ORDER BY cwellid ;
     GROUP BY cwellid
else
   SELECT cwellid, SUM(ntotmcf) AS ntotmcf ;
     FROM wellhist ;
     WHERE BETWEEN(hdate,tdDate1,tdDate2) ;
       AND cwellid IN (SELECT cwellid FROM wells WHERE lSection29 = .T.) ;
     INTO CURSOR temp29 ;
     ORDER BY cwellid ;
     GROUP BY cwellid
endif     
  
IF _tally > 0
   SELECT temp29
   SCAN
      SCATTER MEMVAR
      SELECT tempsc29
      SCAN
         IF cidlease = m.cwellid
            REPLACE nTotMcf WITH m.ntotmcf, ;
                    nMcfShare WITH m.ntotmcf * (ngasint/100)
         ENDIF
      ENDSCAN
   ENDSCAN
ENDIF            
       
*
*  Calculate the owner's share of the total mcf and the section 29 credit
*
SELECT tempsc29
GO TOP
SCAN
   SCATTER MEMVAR
   m.nMcfBbl   = m.nMcfShare/5.8
   m.nCredit   = m.nMcfBbl * lnSect29Rate
   REPLACE nMcfShare WITH m.nMcfShare, ;
           nMcfBbl   WITH m.nMcfBbl, ;
           nCredit   WITH m.nCredit, ;
           nSect29Rate WITH lnSect29Rate
ENDSCAN

             
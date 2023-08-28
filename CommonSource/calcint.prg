*=================================================================================
*  Program....: CALCINT.PRG
*  Version....: 1.0
*  Author.....: Phil W. Sherwood
*  Date.......: September 29, 1994
*  Notice.....: Copyright (c) 1994-1996 SherWare, Inc., All Rights Reserved.
*  Compiler...: FoxPro 2.6a
*) Description: Calculates royalty gas and oil revenue interests.
*  Parameters.:
*  Changes....:
*
*=================================================================================
PRIV m.cOwnerID, m.nInterest, m.cTypeInv, m.cTypeInt

SELE wells
SCAN
   m.cwellid = cwellid
   STORE 0 TO m.ngasint, m.noilint, m.nlandpct, m.noverpct
   SELECT cwellid, ;
      cOwnerID, ;
      nrevgas, ;
      nrevoil, ;
      cTypeInv, ;
      cTypeInt ;
      FROM wellinv  ;
      WHERE cwellid = m.cwellid ;
      INTO CURSOR royints ;
      ORDER BY cwellid, cTypeInv, cOwnerID ;
      GROUP BY cwellid, cTypeInv, cOwnerID


   IF _TALLY = 0
      STORE 0 TO m.ngasint, m.noilint, m.nlandpct, m.noverpct
      IF USED('royints')
         SELECT royints
         USE
      ENDIF
   ELSE

      SELECT royints
      SCAN
         SCATTER MEMVAR
         IF m.cTypeInv = "L" OR ;
               m.cTypeInv = "O"
            DO CASE
               CASE m.cTypeInt = 'G'
                  m.ngasint = m.ngasint + m.nrevgas
                  IF m.cTypeInv = 'L'
                     m.nlandpct = m.nlandpct + m.nrevgas
                  ENDIF
                  IF m.cTypeInv = 'O'
                     m.noverpct = m.noverpct + m.nrevgas
                  ENDIF
               CASE m.cTypeInt = 'O'
                  m.noilint = m.noilint + m.nrevoil
                  IF m.cTypeInv = 'L'
                     m.nlandpct = m.nlandpct + m.nrevoil
                  ENDIF
                  IF m.cTypeInv = 'O'
                     m.noverpct = m.noverpct + m.nrevoil
                  ENDIF
               OTHERWISE
                  m.ngasint = m.ngasint + m.nrevgas
                  m.noilint = m.noilint + m.nrevoil
                  IF m.cTypeInv = 'L'
                     m.nlandpct = m.nlandpct + m.nrevgas
                  ENDIF
                  IF m.cTypeInv = 'O'
                     m.noverpct = m.noverpct + m.nrevgas
                  ENDIF
            ENDCASE
         ENDIF
      ENDSCAN
   ENDIF
   SELE wells
   REPL nlandpct WITH m.nlandpct, ;
        noverpct WITH m.noverpct
ENDSCAN

RETURN

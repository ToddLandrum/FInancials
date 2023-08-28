PARA lAdd

SET SAFETY OFF

IF lAdd  &&  Adding void graphic to check formats

   **  Vendor Check Stub Below  **

   USE voidtmp IN 0 ALIAS voidtmp

   IF FILE('checks\apcheklv.frx')  &&  Only continue if the checks file exists - BH 8/15/06
      USE checks\apcheklv.frx IN 0 ALIAS apchek EXCL

      SELECT apchek  &&  Change print when to blank out for a zero amount in the detail section, which is how the duplicate stub will pad out the spacing
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CINVNUM' OR UPPER(EXPR) = 'STUB.CINVNUM'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'DINVDATE' OR UPPER(EXPR) = 'STUB.DINVDATE'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CREFERENCE' OR UPPER(EXPR) = 'STUB.CREFERENCE'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'NINVTOT' OR UPPER(EXPR) = 'STUB.NINVTOT'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'NAMOUNT' OR UPPER(EXPR) = 'STUB.NAMOUNT'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP  &&  Extra fields for stub detail option
      LOCATE FOR UPPER(EXPR) = 'CDESC' OR UPPER(EXPR) = 'STUB.CDESC'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CACCTNO' OR UPPER(EXPR) = 'STUB.CACCTNO'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CACCTDESC' OR UPPER(EXPR) = 'STUB.CACCTDESC'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CWELLNAME' OR UPPER(EXPR) = 'STUB.CWELLNAME'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CCATCODE' OR UPPER(EXPR) = 'STUB.CCATCODE'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CCATEG' OR UPPER(EXPR) = 'STUB.CCATEG'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF

      SELECT apchek
      SELECT * FROM apchek INTO CURSOR temp1 WHERE objtype < 23 AND platform = 'WINDOWS'  &&  Header info
      SELECT * FROM apchek INTO CURSOR temp2 WHERE objtype >= 23 AND platform = 'WINDOWS' &&  Header info, part 2
      SELECT * FROM apchek INTO CURSOR tempdos WHERE platform = 'DOS'  &&  Face info

      SELECT apchek
      ZAP

      APPEND FROM DBF('temp1')
      SELECT voidtmp
      LOCATE FOR ctype = 'APCHEKLV'
      SCATTER MEMVAR MEMO
      INSERT INTO apchek FROM MEMVAR
      SELECT apchek
      APPEND FROM DBF('temp2')
      APPEND FROM DBF('tempdos')

      SELECT temp1
      USE
      SELECT tempdos
      USE
      SELECT apchek
      USE
      SELECT temp2
      USE
   ENDIF


   **  Vendor Check Stub Above  **

   IF FILE('checks\apchekla.frx')  &&  Only continue if the checks file exists - BH 8/15/06
      USE checks\apchekla.frx IN 0 ALIAS apchek EXCL

      SELECT apchek  &&  Change print when to blank out for a zero amount in the detail section, which is how the duplicate stub will pad out the spacing
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CINVNUM' OR UPPER(EXPR) = 'STUB.CINVNUM'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'DINVDATE' OR UPPER(EXPR) = 'STUB.DINVDATE'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CREFERENCE' OR UPPER(EXPR) = 'STUB.CREFERENCE'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'NINVTOT' OR UPPER(EXPR) = 'STUB.NINVTOT'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'NAMOUNT' OR UPPER(EXPR) = 'STUB.NAMOUNT'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP  &&  Extra fields for stub detail option
      LOCATE FOR UPPER(EXPR) = 'CDESC' OR UPPER(EXPR) = 'STUB.CDESC'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CACCTNO' OR UPPER(EXPR) = 'STUB.CACCTNO'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CACCTDESC' OR UPPER(EXPR) = 'STUB.CACCTDESC'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CWELLNAME' OR UPPER(EXPR) = 'STUB.CWELLNAME'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CCATCODE' OR UPPER(EXPR) = 'STUB.CCATCODE'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'CCATEG' OR UPPER(EXPR) = 'STUB.CCATEG'
      IF FOUND()
         REPL supexpr WITH 'stub.namount <> 0'
      ENDIF

      SELECT apchek
      SELECT * FROM apchek INTO CURSOR temp1 WHERE objtype < 23 AND platform = 'WINDOWS'  &&  Header info
      SELECT * FROM apchek INTO CURSOR temp2 WHERE objtype >= 23 AND platform = 'WINDOWS' &&  Header info, part 2
      SELECT * FROM apchek INTO CURSOR tempdos WHERE platform = 'DOS'  &&  Face info

      SELECT apchek
      ZAP

      APPEND FROM DBF('temp1')
      SELECT voidtmp
      LOCATE FOR ctype = 'APCHEKLA'
      SCATTER MEMVAR MEMO
      INSERT INTO apchek FROM MEMVAR
      SELECT apchek
      APPEND FROM DBF('temp2')
      APPEND FROM DBF('tempdos')

      SELECT temp1
      USE
      SELECT tempdos
      USE
      SELECT apchek
      USE
      SELECT temp2
      USE
      SELECT voidtmp
      USE
   ENDIF

ELSE  &&  Remove void graphic from format

   IF FILE('checks\apcheklv.frx')  &&  Only continue if the checks file exists - BH 8/15/06
      USE checks\apcheklv.frx IN 0 EXCL ALIAS apchek
      SELECT apchek
      LOCATE FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
      IF FOUND()
         DELETE NEXT 1
      ENDIF

      SELECT apchek
      PACK
      USE
   ENDIF


   IF FILE('checks\apchekla.frx')  &&  Only continue if the checks file exists - BH 8/15/06
      USE checks\apchekla.frx IN 0 EXCL ALIAS apchek
      SELECT apchek
      LOCATE FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
      IF FOUND()
         DELETE NEXT 1
      ENDIF

      SELECT apchek
      PACK
      USE
   ENDIF

ENDIF

IF USED('voidtmp')
   USE IN voidtmp
ENDIF
PARA lAdd

SET SAFETY OFF

IF lAdd  &&  Adding void graphic to check formats

   **  Owner Check Stub Below  **

   IF FILE('checks\dmcheklv.frx')  &&  Only continue if the checks file exists - BH 8/15/06
      USE checks\dmcheklv.frx IN 0 ALIAS dmchek EXCL

      SELECT dmchek  &&  Change print when to blank out for an empty cwellname in the detail section, which is how the duplicate stub will pad out the spacing
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NNETCHECK'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NEXPENSE'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NINTEREST'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NNETVAL'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.CPRODPRD'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NTAXES'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NTOTALINC'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NPRICE'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NUNITS'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF

      USE voidtmp IN 0 ALIAS voidtmp

      SELECT dmchek
      SELECT * FROM dmchek INTO CURSOR temp1 WHERE objtype < 23 AND platform = 'WINDOWS'  &&  Header info
      SELECT * FROM dmchek INTO CURSOR temp2 WHERE objtype >= 23 AND platform = 'WINDOWS' &&  Header info, part 2
      SELECT * FROM dmchek INTO CURSOR tempdos WHERE platform = 'DOS'  &&  Face info

      SELECT dmchek
      ZAP

      APPEND FROM DBF('temp1')
      SELECT voidtmp
      LOCATE FOR ctype = 'DMCHEKLV'
      SCATTER MEMVAR MEMO
      INSERT INTO dmchek FROM MEMVAR
      SELECT dmchek
      APPEND FROM DBF('temp2')
      APPEND FROM DBF('tempdos')

      SELECT temp1
      USE
      SELECT tempdos
      USE
      SELECT dmchek
      USE
      SELECT temp2
      USE
   ENDIF


   **  Owner Check Stub Above  **

   IF FILE('checks\dmchekla.frx')  &&  Only continue if the checks file exists - BH 8/15/06
      USE checks\dmchekla.frx IN 0 ALIAS dmchek EXCL

      SELECT dmchek  &&  Change print when to blank out for an empty cwellname in the detail section, which is how the duplicate stub will pad out the spacing
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NNETCHECK'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NEXPENSE'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NINTEREST'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NNETVAL'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.CPRODPRD'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NTAXES'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NTOTALINC'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NPRICE'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF
      GO TOP
      LOCATE FOR UPPER(EXPR) = 'STUB.NUNITS'
      IF FOUND()
         REPL supexpr WITH "left(stub.cwellname,1) <> '*' AND NOT stub.lskip AND NOT EMPTY(stub.cwellname) AND stub.cProdPrd <> '99/99'"
      ENDIF

      SELECT * FROM dmchek INTO CURSOR temp1 WHERE objtype < 23 AND platform = 'WINDOWS'  &&  Header info
      SELECT * FROM dmchek INTO CURSOR temp2 WHERE objtype >= 23 AND platform = 'WINDOWS' &&  Header info, part 2
      SELECT * FROM dmchek INTO CURSOR tempdos WHERE platform = 'DOS'  &&  Face info

      SELECT dmchek
      ZAP

      APPEND FROM DBF('temp1')
      SELECT voidtmp
      LOCATE FOR ctype = 'DMCHEKLA'
      SCATTER MEMVAR MEMO
      INSERT INTO dmchek FROM MEMVAR
      SELECT dmchek
      APPEND FROM DBF('temp2')
      APPEND FROM DBF('tempdos')

      SELECT temp1
      USE
      SELECT temp2
      USE
      SELECT tempdos
      USE
      SELECT dmchek
      USE
   ENDIF

ELSE  &&  Remove void graphic from format

   IF FILE('checks\dmcheklv.frx')  &&  Only continue if the checks file exists - BH 8/15/06
      USE checks\dmcheklv.frx IN 0 EXCL ALIAS dmchek
      SELECT dmchek
      LOCATE FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
      IF FOUND()
         DELETE NEXT 1
      ENDIF

      SELECT dmchek
      PACK
      USE
   ENDIF

   IF FILE('checks\dmchekla.frx')  &&  Only continue if the checks file exists - BH 8/15/06
      USE checks\dmchekla.frx IN 0 EXCL ALIAS dmchek
      SELECT dmchek
      LOCATE FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
      IF FOUND()
         DELETE NEXT 1
      ENDIF

      SELECT dmchek
      PACK
      USE
   ENDIF

ENDIF

IF USED('voidtmp')
   USE IN voidtmp
ENDIF
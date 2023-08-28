PARA tlAdd, tcType

LOCAL llFoundImage

IF VARTYPE(tcType) <> 'C'
   tcType = 'DM'
ENDIF

IF USED('voidtmp')
   USE IN voidtmp
ENDIF

SET SAFETY OFF

TRY
   IF tlAdd  &&  Adding void graphic to check formats
      DO CASE
         CASE tcType = 'DM'
            **  Owner Check Stub Below  **

            IF FILE(m.goapp.cChecksFolder+'dmcheklv.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'dmcheklv.frx' IN 0 ALIAS dmchek EXCL

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

               *  Check to see if the void image is already on the format
               LOCATE FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
               IF FOUND()
                  llFoundImage = .T.
               ELSE
                  llFoundImage = .F.
               ENDIF

               SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                  REPLACE uniqueid WITH PADL(ALLTRIM(STR(RECNO())),7,'0')
               ENDSCAN

               SELECT uniqueid, COUNT(uniqueid) FROM dmchek WHERE objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE) INTO CURSOR imagecount GROUP BY uniqueid
               IF _TALLY > 1
                  lnCount = 1
                  SELECT dmchek
                  SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                     IF lnCount > 1
                        DELETE NEXT 1
                     ENDIF
                     lnCount = lnCount +1
                  ENDSCAN
               ENDIF

               USE voidtmp IN 0 ALIAS voidtmp

               SELECT dmchek
               SELECT * FROM dmchek INTO CURSOR temp1 WHERE objtype < 23 AND platform = 'WINDOWS'  &&  Header info
               SELECT * FROM dmchek INTO CURSOR temp2 WHERE objtype >= 23 AND platform = 'WINDOWS' &&  Header info, part 2
               SELECT * FROM dmchek INTO CURSOR tempdos WHERE platform = 'DOS'  &&  Face info

               SELECT dmchek
               ZAP

               APPEND FROM DBF('temp1')

               *  If the void graphic isn't there already, add it
               IF NOT llFoundImage
                  SELECT voidtmp
                  LOCATE FOR ctype = 'DMCHEKLV'
                  SCATTER MEMVAR MEMO
                  INSERT INTO dmchek FROM MEMVAR
               ENDIF
               SELECT dmchek
               APPEND FROM DBF('temp2')
               APPEND FROM DBF('tempdos')

               *  Change the voidlogo picture to be invisible when viewed as PROTECTED, and to only print when _pageno > 1
               SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                  REPLACE ORDER WITH '', supexpr WITH '_pageno > 1'
               ENDSCAN

               SELECT temp1
               USE
               SELECT tempdos
               USE
               SELECT dmchek
               USE
               SELECT temp2
               USE
               USE IN voidtmp
               USE IN imagecount
            ENDIF
            
            
            *  Owner Check - Stub Above - Enhanced
            IF FILE(m.goapp.cChecksFolder+'dmcheklve.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'dmcheklve.frx' IN 0 ALIAS dmchek EXCL

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

               *  Check to see if the void image is already on the format
               LOCATE FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
               IF FOUND()
                  llFoundImage = .T.
               ELSE
                  llFoundImage = .F.
               ENDIF

               SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                  REPLACE uniqueid WITH PADL(ALLTRIM(STR(RECNO())),7,'0')
               ENDSCAN

               SELECT uniqueid, COUNT(uniqueid) FROM dmchek WHERE objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE) INTO CURSOR imagecount GROUP BY uniqueid
               IF _TALLY > 1
                  lnCount = 1
                  SELECT dmchek
                  SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                     IF lnCount > 1
                        DELETE NEXT 1
                     ENDIF
                     lnCount = lnCount +1
                  ENDSCAN
               ENDIF

               USE voidtmp IN 0 ALIAS voidtmp

               SELECT dmchek
               SELECT * FROM dmchek INTO CURSOR temp1 WHERE objtype < 23 AND platform = 'WINDOWS'  &&  Header info
               SELECT * FROM dmchek INTO CURSOR temp2 WHERE objtype >= 23 AND platform = 'WINDOWS' &&  Header info, part 2
               SELECT * FROM dmchek INTO CURSOR tempdos WHERE platform = 'DOS'  &&  Face info

               SELECT dmchek
               ZAP

               APPEND FROM DBF('temp1')

               *  If the void graphic isn't there already, add it
               IF NOT llFoundImage
                  SELECT voidtmp
                  LOCATE FOR ctype = 'DMCHEKLV'
                  SCATTER MEMVAR MEMO
                  INSERT INTO dmchek FROM MEMVAR
               ENDIF
               SELECT dmchek
               APPEND FROM DBF('temp2')
               APPEND FROM DBF('tempdos')

               *  Change the voidlogo picture to be invisible when viewed as PROTECTED, and to only print when _pageno > 1
               SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                  REPLACE ORDER WITH '', supexpr WITH '_pageno > 1'
               ENDSCAN

               SELECT temp1
               USE
               SELECT tempdos
               USE
               SELECT dmchek
               USE
               SELECT temp2
               USE
               USE IN voidtmp
               USE IN imagecount
            ENDIF


            **  Owner Check Stub Above  **

            IF FILE(m.goapp.cChecksFolder+'dmchekla.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'dmchekla.frx' IN 0 ALIAS dmchek EXCL

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

               *  Check to see if the void image is already on the format
               LOCATE FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
               IF FOUND()
                  llFoundImage = .T.
               ELSE
                  llFoundImage = .F.
               ENDIF

               SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                  REPLACE uniqueid WITH PADL(ALLTRIM(STR(RECNO())),7,'0')
               ENDSCAN

               SELECT uniqueid, COUNT(uniqueid) FROM dmchek WHERE objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE) INTO CURSOR imagecount GROUP BY uniqueid
               IF _TALLY > 1
                  lnCount = 1
                  SELECT dmchek
                  SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                     IF lnCount > 1
                        DELETE NEXT 1
                     ENDIF
                     lnCount = lnCount +1
                  ENDSCAN
               ENDIF

               USE voidtmp IN 0 ALIAS voidtmp

               SELECT * FROM dmchek INTO CURSOR temp1 WHERE objtype < 23 AND platform = 'WINDOWS'  &&  Header info
               SELECT * FROM dmchek INTO CURSOR temp2 WHERE objtype >= 23 AND platform = 'WINDOWS' &&  Header info, part 2
               SELECT * FROM dmchek INTO CURSOR tempdos WHERE platform = 'DOS'  &&  Face info

               SELECT dmchek
               ZAP

               APPEND FROM DBF('temp1')

               *  If the void graphic isn't there already, add it
               IF NOT llFoundImage
                  SELECT voidtmp
                  LOCATE FOR ctype = 'DMCHEKLV'
                  SCATTER MEMVAR MEMO
                  INSERT INTO dmchek FROM MEMVAR
               ENDIF

               SELECT dmchek
               APPEND FROM DBF('temp2')
               APPEND FROM DBF('tempdos')

               *  Change the voidlogo picture to be invisible when viewed as PROTECTED, and to only print when _pageno > 1
               SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                  REPLACE ORDER WITH '', supexpr WITH '_pageno > 1'
               ENDSCAN

               SELECT temp1
               USE
               SELECT temp2
               USE
               SELECT tempdos
               USE
               SELECT dmchek
               USE
               USE IN voidtmp
               USE IN imagecount
            ENDIF

         CASE tcType = 'AP'
            **  Vendor Check Stub Below  **

            IF FILE(m.goapp.cChecksFolder+'apcheklv.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'apcheklv.frx' IN 0 ALIAS apchek EXCL

               SELECT apchek  &&  Change print when to blank out for a zero amount in the detail section, which is how the duplicate stub will pad out the spacing
               GO TOP
               LOCATE FOR 'CINVNUM' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'DINVDATE' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CREFERENCE' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'NINVTOT' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'NAMOUNT' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP  &&  Extra fields for stub detail option
               LOCATE FOR 'CDESC' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CACCTNO' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CACCTDESC' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CWELLNAME' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CCATCODE' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CCATEG' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF

               *  Check to see if the void image is already on the format
               LOCATE FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
               IF FOUND()
                  llFoundImage = .T.
               ELSE
                  llFoundImage = .F.
               ENDIF

               SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                  REPLACE uniqueid WITH PADL(ALLTRIM(STR(RECNO())),7,'0')
               ENDSCAN

               SELECT uniqueid, COUNT(uniqueid) FROM apchek WHERE objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE) INTO CURSOR imagecount GROUP BY uniqueid
               IF _TALLY > 1
                  lnCount = 1
                  SELECT apchek
                  SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                     IF lnCount > 1
                        DELETE NEXT 1
                     ENDIF
                     lnCount = lnCount +1
                  ENDSCAN
               ENDIF

               USE voidtmp IN 0 ALIAS voidtmp

               SELECT apchek
               SELECT * FROM apchek INTO CURSOR temp1 WHERE objtype < 23 AND platform = 'WINDOWS'  &&  Header info
               SELECT * FROM apchek INTO CURSOR temp2 WHERE objtype >= 23 AND platform = 'WINDOWS' &&  Header info, part 2
               SELECT * FROM apchek INTO CURSOR tempdos WHERE platform = 'DOS'  &&  Face info

               SELECT apchek
               ZAP

               APPEND FROM DBF('temp1')
               IF NOT llFoundImage
                  SELECT voidtmp
                  LOCATE FOR ctype = 'APCHEKLV'
                  SCATTER MEMVAR MEMO
                  INSERT INTO apchek FROM MEMVAR
               ENDIF
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
               USE IN voidtmp
               USE IN imagecount
            ENDIF


            **  Vendor Check Stub Above  **

            IF FILE(m.goapp.cChecksFolder+'apchekla.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'apchekla.frx' IN 0 ALIAS apchek EXCL

               SELECT apchek  &&  Change print when to blank out for a zero amount in the detail section, which is how the duplicate stub will pad out the spacing
               GO TOP
               LOCATE FOR 'CINVNUM' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'DINVDATE' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CREFERENCE' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'NINVTOT' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'NAMOUNT' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP  &&  Extra fields for stub detail option
               LOCATE FOR 'CDESC' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CACCTNO' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CACCTDESC' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CWELLNAME' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CCATCODE' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF
               GO TOP
               LOCATE FOR 'CCATEG' $ UPPER(EXPR)
               IF FOUND()
                  REPL supexpr WITH 'stub.namount <> 0'
               ENDIF

               *  Check to see if the void image is already on the format
               LOCATE FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
               IF FOUND()
                  llFoundImage = .T.
               ELSE
                  llFoundImage = .F.
               ENDIF

               SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                  REPLACE uniqueid WITH PADL(ALLTRIM(STR(RECNO())),7,'0')
               ENDSCAN

               SELECT uniqueid, COUNT(uniqueid) FROM apchek WHERE objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE) INTO CURSOR imagecount GROUP BY uniqueid
               IF _TALLY > 1
                  lnCount = 1
                  SELECT apchek
                  SCAN FOR objtype = 17 AND 'VOIDLOGO' $ UPPER(PICTURE)
                     IF lnCount > 1
                        DELETE NEXT 1
                     ENDIF
                     lnCount = lnCount +1
                  ENDSCAN
               ENDIF

               USE voidtmp IN 0 ALIAS voidtmp

               SELECT * FROM apchek INTO CURSOR temp1 WHERE objtype < 23 AND platform = 'WINDOWS'  &&  Header info
               SELECT * FROM apchek INTO CURSOR temp2 WHERE objtype >= 23 AND platform = 'WINDOWS' &&  Header info, part 2
               SELECT * FROM apchek INTO CURSOR tempdos WHERE platform = 'DOS'  &&  Face info

               SELECT apchek
               ZAP

               APPEND FROM DBF('temp1')

               IF NOT llFoundImage
                  SELECT voidtmp
                  LOCATE FOR ctype = 'APCHEKLA'
                  SCATTER MEMVAR MEMO
                  INSERT INTO apchek FROM MEMVAR
               ENDIF
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
               USE IN voidtmp
               USE IN imagecount
            ENDIF
      ENDCASE

   ENDIF
CATCH
   * We don't care about errors in here
ENDTRY

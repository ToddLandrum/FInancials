PARA tlChange, tcType
LOCAL llChange

IF VARTYPE(tcType) <> 'C'
   tcType = 'DM'
ENDIF

llChange = tlChange

SET SAFETY OFF

TRY
   IF llChange  &&  Adding the info for the duplicate check stubs
      DO CASE
         CASE tcType = 'DM'
            **  Owner Check Stub Below  **

            IF FILE(m.goapp.cChecksFolder+'dmcheklv.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'dmcheklv.frx' IN 0 ALIAS dmchek EXCL
               USE stubtmp IN 0 ALIAS stubtmp

               SELECT dmchek
               SELECT * FROM dmchek INTO CURSOR temp1 WHERE objtype = 1 AND platform = 'WINDOWS'  &&  Header info
               SELECT * FROM dmchek INTO CURSOR tempdos WHERE INLIST(objtype,23,25) OR platform = 'DOS'  &&  Face info

               SELECT * FROM dmchek INTO CURSOR tempface WHERE (objtype = 8 AND vpos < 39000) &&  Face info settings

               SELECT dmchek
               ZAP

               APPEND FROM DBF('temp1')
               APPEND FROM DBF('tempface')
               SELECT stubtmp
               SCAN FOR NOT lOriginal
                  SCATTER MEMVAR MEMO
                  SELECT dmchek
                  INSERT INTO dmchek FROM MEMVAR
               ENDSCAN

               SELECT dmchek
               APPEND FROM DBF('tempdos')

               SELECT temp1
               USE
               SELECT stubtmp
               USE
               SELECT tempdos
               USE
               SELECT tempface
               USE
               SELECT dmchek
               USE
            ENDIF


            **  Owner Check Stub Above  **

            IF FILE(m.goapp.cChecksFolder+'dmchekla.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'dmchekla.frx' IN 0 ALIAS dmchek EXCL
               USE stubtmpa IN 0 ALIAS stubtmp

               SELECT dmchek
               SELECT * FROM dmchek INTO CURSOR temp1 WHERE objtype = 1 AND platform = 'WINDOWS'  &&  Header info
               SELECT * FROM dmchek INTO CURSOR tempdos WHERE INLIST(objtype,23,25) OR platform = 'DOS'  &&  Face info

               SELECT * FROM dmchek INTO CURSOR tempface WHERE (objtype = 8 AND vpos > 20000) &&  Face info settings

               SELECT dmchek
               ZAP

               APPEND FROM DBF('temp1')
               APPEND FROM DBF('tempface')

               SELECT stubtmp
               SCAN FOR NOT lOriginal
                  SCATTER MEMVAR MEMO
                  SELECT dmchek
                  INSERT INTO dmchek FROM MEMVAR
               ENDSCAN

               SELECT dmchek
               APPEND FROM DBF('tempdos')

               SELECT temp1
               USE
               SELECT stubtmp
               USE
               SELECT tempdos
               USE
               SELECT tempface
               USE
               SELECT dmchek
               USE
            ENDIF

         CASE tcType = 'AP'
            **  Vendor Check Stub Above  **

            IF FILE(m.goapp.cChecksFolder+'apchekla.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'apchekla.frx' IN 0 ALIAS dmchek EXCL
               USE stubtmpapa IN 0 ALIAS stubtmp

               SELECT dmchek
               SELECT * FROM dmchek INTO CURSOR temp1 WHERE objtype = 1 AND platform = 'WINDOWS'  &&  Header info
               SELECT * FROM dmchek INTO CURSOR tempdos WHERE INLIST(objtype,23,25) OR platform = 'DOS'  &&  Face info

               SELECT * FROM dmchek INTO CURSOR tempface WHERE (objtype = 8 AND vpos > 30000) &&  Face info settings

               SELECT dmchek
               ZAP

               APPEND FROM DBF('temp1')
               APPEND FROM DBF('tempface')
               SELECT stubtmp
               SCAN FOR NOT lOriginal
                  SCATTER MEMVAR MEMO
                  SELECT dmchek
                  INSERT INTO dmchek FROM MEMVAR
               ENDSCAN

               SELECT dmchek
               APPEND FROM DBF('tempdos')

               SELECT temp1
               USE
               SELECT stubtmp
               USE
               SELECT tempdos
               USE
               SELECT tempface
               USE
               SELECT dmchek
               USE
            ENDIF


            **  Vendor Check Stub Below  **
            IF FILE(m.goapp.cChecksFolder+'apcheklv.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'apcheklv.frx' IN 0 ALIAS dmchek EXCL
               USE stubtmpap IN 0 ALIAS stubtmp

               SELECT dmchek
               SELECT * FROM dmchek INTO CURSOR temp1 WHERE objtype = 1 AND platform = 'WINDOWS'  &&  Header info
               SELECT * FROM dmchek INTO CURSOR tempdos WHERE INLIST(objtype,23,25)  &&  Face info

               SELECT * FROM dmchek INTO CURSOR tempface WHERE (objtype = 8 AND vpos < 30000) &&  Check Face fields

               SELECT dmchek
               ZAP

               APPEND FROM DBF('temp1')
               APPEND FROM DBF('tempface')
               SELECT stubtmp
               SCAN FOR NOT lOriginal
                  SCATTER MEMVAR MEMO
                  SELECT dmchek
                  INSERT INTO dmchek FROM MEMVAR
               ENDSCAN

               SELECT dmchek
               APPEND FROM DBF('tempdos')

               SELECT temp1
               USE
               SELECT stubtmp
               USE
               SELECT tempdos
               USE
               SELECT tempface
               USE
               SELECT dmchek
               USE
            ENDIF
      ENDCASE
   ELSE  &&  Removing the duplicate check stub items

      DO CASE
         CASE tcType = 'DM'
            **  Owner Check Stub Below  **

            IF FILE(m.goapp.cChecksFolder+'dmcheklv.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'dmcheklv.frx' IN 0 ALIAS dmchek EXCL
               USE stubtmp IN 0 ALIAS stubtmp

               SELECT stubtmp
               SCAN FOR lOriginal  &&  Scan for and remove the stubtmp records that were appended in
                  SCATTER MEMVAR MEMO
                  SELECT dmchek
                  LOCATE FOR uniqueid == stubtmp.uniqueid AND platform = stubtmp.platform
                  IF FOUND()
                     GATHER MEMVAR MEMO
                  ENDIF
               ENDSCAN

               SELECT dmchek
               USE
               SELECT stubtmp
               USE
            ENDIF


            **  Owner Check Stub Above  **

            IF FILE(m.goapp.cChecksFolder+'dmchekla.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'dmchekla.frx' IN 0 ALIAS dmchek EXCL
               USE stubtmpa IN 0 ALIAS stubtmp

               SELECT stubtmp
               SCAN FOR lOriginal  &&  Scan for and remove the stubtmp records that were appended in
                  SCATTER MEMVAR MEMO
                  SELECT dmchek
                  LOCATE FOR uniqueid == stubtmp.uniqueid AND platform = stubtmp.platform
                  IF FOUND()
                     GATHER MEMVAR MEMO
                  ENDIF
               ENDSCAN

               SELECT dmchek
               USE
               SELECT stubtmp
               USE
            ENDIF

         CASE tcType = 'AP'

            **  Vendor Check Stub Above  **

            IF FILE(m.goapp.cChecksFolder+'apchekla.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'apchekla.frx' IN 0 ALIAS dmchek EXCL
               USE stubtmpapa IN 0 ALIAS stubtmp

               SELECT stubtmp
               SCAN FOR lOriginal  &&  Scan for and remove the stubtmp records that were appended in
                  SCATTER MEMVAR MEMO
                  SELECT dmchek
                  LOCATE FOR uniqueid == stubtmp.uniqueid AND platform = stubtmp.platform
                  IF FOUND()
                     GATHER MEMVAR MEMO
                  ENDIF
               ENDSCAN

               SELECT dmchek
               USE
               SELECT stubtmp
               USE
            ENDIF


            **  Vendor Check Stub Below  **

            IF FILE(m.goapp.cChecksFolder+'apcheklv.frx')  &&  Only make the change if the file exists - BH 10/10/2006
               USE m.goapp.cChecksFolder+'apcheklv.frx' IN 0 ALIAS dmchek EXCL
               USE stubtmpap IN 0 ALIAS stubtmp

               SELECT stubtmp
               SCAN FOR lOriginal  &&  Scan for and remove the stubtmp records that were appended in
                  SCATTER MEMVAR MEMO
                  SELECT dmchek
                  LOCATE FOR uniqueid == stubtmp.uniqueid AND platform = stubtmp.platform
                  IF FOUND()
                     GATHER MEMVAR MEMO
                  ENDIF
               ENDSCAN

               SELECT dmchek
               USE
               SELECT stubtmp
               USE
            ENDIF
      ENDCASE
   ENDIF
CATCH
   * We want to ignore errors for now
ENDTRY




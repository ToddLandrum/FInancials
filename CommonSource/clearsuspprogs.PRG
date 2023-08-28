TRY
   IF MESSAGEBOX('This will remove the program codes from suspense records where the owner interest ' + ;
           'for that suspense is no longer in a program. Continue?', 36, 'Remove Program Codes') = 6
      SELECT  cownerid, ;
              cwellid, ;
              ctypeinv, ;
              cprogcode ;
          FROM suspense ;
          WHERE NOT EMPTY(cprogcode) ;
          INTO CURSOR suspprog ;
          ORDER BY cownerid, cwellid, ctypeinv, cprogcode ;
          GROUP BY cownerid, cwellid, ctypeinv, cprogcode

      IF _TALLY > 0
         SELECT  suspprog
         SCAN
            SCATTER MEMVAR

            SELECT wellinv
            LOCATE FOR cownerid == m.cownerid AND ;
               cwellid  == m.cwellid  AND ;
               ctypeinv == m.ctypeinv AND ;
               cprogcode == m.cprogcode
            IF FOUND()
               IF EMPTY(wellinv.cprogcode)
                  SELECT suspense
                  SCAN FOR cownerid == m.cownerid AND ;
                        cwellid  == m.cwellid AND ;
                        ctypeinv == m.ctypeinv AND ;
                        NOT EMPTY(cprogcode)
                     REPLACE cprogcode WITH ''
                  ENDSCAN
               ELSE
                  SELECT suspense
                  SCAN FOR cownerid == m.cownerid AND ;
                        cwellid  == m.cwellid AND ;
                        ctypeinv == m.ctypeinv AND ;
                     NOT EMPTY(cprogcode)
                     REPLACE cprogcode WITH ''
                  ENDSCAN
               ENDIF
            ELSE
               SELECT suspense
               SCAN FOR cownerid == m.cownerid AND ;
                     cwellid  == m.cwellid AND ;
                     ctypeinv == m.ctypeinv AND ;
                     NOT EMPTY(cprogcode)
                  REPLACE cprogcode WITH ''
               ENDSCAN
            ENDIF

         ENDSCAN
      ENDIF
   ENDIF

   USE IN suspprogs
   USE IN badprogs

CATCH
ENDTRY
WAIT CLEAR








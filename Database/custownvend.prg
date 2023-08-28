OPEN DATA dbcrun\APPDATA

CREATE SQL VIEW "CUSTOWNVEND" ; 
   AS SELECT Investor.cownerid      AS cId, ;
               Investor.cSortField AS cName, ;
               'Owner    '          AS cType, ;
               Investor.cAddress1a AS cAddr1, ;
               Investor.cAddress1b AS cAddr2, ;
               padr(allt(Investor.cCity1)+' '+Investor.cState1+' '+Investor.cZip1,44,' ') AS cAddr3, ;
               SPACE(30)         AS cContact, ;
               cphoneh           AS cPhone, ;
               cidterm ;
        FROM APPDATA!Investor ;     
     UNION ;
     SELECT Vendor.cvendorid     AS cId, ;
               Vendor.cSortField AS cName, ;
               'Vendor   '         AS cType, ;
               Vendor.cbAddr1    AS cAddr1, ;
               Vendor.cbAddr2    AS cAddr2, ;
               padr(allt(Vendor.cbcity)+' '+Vendor.cbstate+' '+Vendor.cbZip,44,' ') AS cAddr3, ;
               Vendor.cbContact  AS cContact, ;
               Vendor.cbphone    AS cPhone, ;
               Vendor.cidterm ;
        FROM APPDATA!Vendor ;  
      UNION ;
     SELECT custs.ccustid     AS cId, ;
               custs.ccustname AS cName, ;
               'Customer '      AS cType, ;
               custs.cbAddr1    AS cAddr1, ;
               custs.cbAddr2    AS cAddr2, ;
               padr(allt(custs.cbcity)+' '+custs.cbstate+' '+custs.cbZip,44,' ') AS cAddr3, ;
               custs.cbContact  AS cContact, ;
               custs.cbphone    AS cPhone, ;
               custs.cidterm ;
        FROM APPDATA!custs ;    
      UNION  SELECT Emps.cempid  AS cID,  ;
             PADR((ALLT(emps.cLastName) + ' ' + ALLT(cFirstName)),60,' ') AS cName, ;
             'Employee ' AS cType, ;
             emps.caddress      AS caddr1, ;
             SPACE(60) AS caddr2, ;             
             padr(allt(emps.ccity)+' '+emps.cstate+' '+emps.czipcode,44,' ') AS cAddr3, ;
             space(30) AS ccontact, ;
             space(14) AS cPhone, ;
             space(8)  AS cidterm ;
         FROM appdata!emps ;       
      UNION SELECT revsrc.crevkey as cid, ;
            padr(allt(revsrc.crevname),60,' ') as cname, ;
            'Purchaser' as ctype, ;
            space(60) as caddr1, ;
            space(60) as caddr2, ;
            space(44) as caddr3, ;
            space(30) AS ccontact, ;
            space(14) AS cPhone, ;
            space(8)  AS cidterm ;
         FROM appdata!revsrc ;             
        ORDER BY 3, 1

DBSetProp('CUSTOWNVEND', 'View', 'UpdateType', 1)
DBSetProp('CUSTOWNVEND', 'View', 'WhereType', 3)
DBSetProp('CUSTOWNVEND', 'View', 'FetchMemo', .T.)
DBSetProp('CUSTOWNVEND', 'View', 'SendUpdates', .F.)
DBSetProp('CUSTOWNVEND', 'View', 'UseMemoSize', 255)
DBSetProp('CUSTOWNVEND', 'View', 'FetchSize', 100)
DBSetProp('CUSTOWNVEND', 'View', 'MaxRecords', -1)
DBSetProp('CUSTOWNVEND', 'View', 'Tables', 'APPDATA!Investor')
DBSetProp('CUSTOWNVEND', 'View', 'Prepared', .F.)
DBSetProp('CUSTOWNVEND', 'View', 'CompareMemo', .T.)
DBSetProp('CUSTOWNVEND', 'View', 'FetchAsNeeded', .F.)
DBSetProp('CUSTOWNVEND', 'View', 'FetchSize', 100)
DBSetProp('CUSTOWNVEND', 'View', 'Comment', "")
DBSetProp('CUSTOWNVEND', 'View', 'BatchUpdateCount', 1)
DBSetProp('CUSTOWNVEND', 'View', 'ShareConnection', .F.)

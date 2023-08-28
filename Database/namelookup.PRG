OPEN DATA amdata\APPDATA

CREATE SQL VIEW "namelookup" ; 
      AS SELECT Investor.cownerid      AS cId, ;
               Investor.cSortField AS cName, ;
               'Owner    '          AS cType ;
        FROM APPDATA!Investor ;     
     UNION ;
   SELECT Vendor.cvendorid     AS cId, ;
               Vendor.cSortField AS cName, ;
               'Vendor   '         AS cType ;
        FROM APPDATA!Vendor ;  
      UNION ;
     SELECT custs.ccustid     AS cId, ;
               custs.ccustname AS cName, ;
               'Customer '      AS cType ;
        FROM APPDATA!custs ;    
      UNION SELECT revsrc.crevkey as cid, ;
            revsrc.crevname as cname, ;
            'Purchaser' as ctype ;
         FROM appdata!revsrc ;             
        ORDER BY 3, 1

DBSetProp('namelookup', 'View', 'UpdateType', 1)
DBSetProp('namelookup', 'View', 'WhereType', 3)
DBSetProp('namelookup', 'View', 'FetchMemo', .T.)
DBSetProp('namelookup', 'View', 'SendUpdates', .F.)
DBSetProp('namelookup', 'View', 'UseMemoSize', 255)
DBSetProp('namelookup', 'View', 'FetchSize', 100)
DBSetProp('namelookup', 'View', 'MaxRecords', -1)
DBSetProp('namelookup', 'View', 'Tables', 'APPDATA!Investor')
DBSetProp('namelookup', 'View', 'Prepared', .F.)
DBSetProp('namelookup', 'View', 'CompareMemo', .T.)
DBSetProp('namelookup', 'View', 'FetchAsNeeded', .F.)
DBSetProp('namelookup', 'View', 'FetchSize', 100)
DBSetProp('namelookup', 'View', 'Comment', "")
DBSetProp('namelookup', 'View', 'BatchUpdateCount', 1)
DBSetProp('namelookup', 'View', 'ShareConnection', .F.)

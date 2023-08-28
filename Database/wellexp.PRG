OPEN DATA DBCRUN\APPDATA
DO doit

CLOSE DATA all

OPEN DATA DATA\APPDATA
DO doit

OPEN DATA QBDATA\APPDATA
DO doit


PROC doit

CREATE SQL VIEW "wellexp" ; 
   AS SELECT *;
 FROM appdata!expense;
 WHERE Expense.cwellid = ?lcWellID;
   AND Expense.crunyearrev = ?lcRunYear;
   AND Expense.nrunnorev = ?lnRunNo;
 ORDER BY Expense.cyear, Expense.cperiod, Expense.ccateg

DBSetProp('wellexp', 'View', 'WhereType', 3)
DBSetProp('wellexp', 'View', 'FetchMemo', .T.)
DBSetProp('wellexp', 'View', 'SendUpdates', .T.)
DBSetProp('wellexp', 'View', 'UseMemoSize', 255)
DBSetProp('wellexp', 'View', 'FetchSize', 100)
DBSetProp('wellexp', 'View', 'MaxRecords', -1)
DBSetProp('wellexp', 'View', 'Tables', 'APPDATA!Expense')
DBSetProp('wellexp', 'View', 'Prepared', .F.)
DBSetProp('wellexp', 'View', 'CompareMemo', .T.)
DBSetProp('wellexp', 'View', 'FetchAsNeeded', .F.)
DBSetProp('wellexp', 'View', 'FetchSize', 100)
DBSetProp('wellexp', 'View', 'Comment', "")
DBSetProp('wellexp', 'View', 'BatchUpdateCount', 1)
DBSetProp('wellexp', 'View', 'ShareConnection', .F.)
DBSetProp('wellexp', 'View', 'UpdateType', 1)

CREATE SQL VIEW "wellexpj" ; 
   AS SELECT *;
 FROM appdata!expense;
 WHERE Expense.cwellid = ?lcWellID;
   AND Expense.crunyearjib = ?lcRunYear;
   AND Expense.nrunnojib = ?lnRunNo;
 ORDER BY Expense.cyear, Expense.cperiod, Expense.ccateg

DBSetProp('wellexpj', 'View', 'WhereType', 3)
DBSetProp('wellexpj', 'View', 'FetchMemo', .T.)
DBSetProp('wellexpj', 'View', 'SendUpdates', .T.)
DBSetProp('wellexpj', 'View', 'UseMemoSize', 255)
DBSetProp('wellexpj', 'View', 'FetchSize', 100)
DBSetProp('wellexpj', 'View', 'MaxRecords', -1)
DBSetProp('wellexpj', 'View', 'Tables', 'APPDATA!Expense')
DBSetProp('wellexpj', 'View', 'Prepared', .F.)
DBSetProp('wellexpj', 'View', 'CompareMemo', .T.)
DBSetProp('wellexpj', 'View', 'FetchAsNeeded', .F.)
DBSetProp('wellexpj', 'View', 'FetchSize', 100)
DBSetProp('wellexpj', 'View', 'Comment', "")
DBSetProp('wellexpj', 'View', 'BatchUpdateCount', 1)
DBSetProp('wellexpj', 'View', 'ShareConnection', .F.)
DBSetProp('wellexpj', 'View', 'UpdateType', 1)

LPARAMETERS tcDesc, tlStart, tnStartSeconds, tnEndSeconds
*
* Logs milestones
*

IF NOT FILE(m.goapp.ccommonfolder+'swlog.txt')
   RETURN
ENDIF

IF NOT FILE(m.goapp.ccommonfolder+'swlogs.dbf')
   CREATE TABLE (m.goapp.ccommonfolder+'swlogs') FREE ;
    (cDesc  c(40), ;
     tLogTime      t, ;
     cStartEnd     c(15), ;
     nDuration     n(12,4), ;
     cuser         c(10))
 ELSE
    IF NOT USED('swlogs')
       USE (m.goapp.ccommonfolder+'swlogs') IN 0
    ENDIF
 ENDIF 
 
 
m.cDesc = tcDesc
m.cStartEnd    =  IIF(tlStart,'Starting','Ending')
m.tLogTime     = DATETIME()
m.cuser        = m.goapp.cuser
IF NOT tlStart
   m.nduration = tnEndSeconds - tnStartSeconds
ELSE
   m.nDuration = 0
ENDIF

INSERT INTO swlogs FROM MEMVAR 

USE IN swlogs
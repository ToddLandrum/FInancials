*** 
*** ReFox XI+  #US113261  Phil Sherwood  SherWare, Inc. [VFP90]
***
 SET DELETED OFF
 IF  .NOT. USED('vendor')
    USE vendor IN 0
 ENDIF
 IF  .NOT. USED('custs')
    USE custs IN 0
 ENDIF
 SELECT vendor
 SCAN
    SCATTER MEMVAR 
    SELECT custs
    LOCATE FOR ccustid=vendor.cvendorid
    IF FOUND()
       REPLACE caddress1 WITH m.caddress1, ;
               caddress2 WITH m.caddress2, ;
               ccity     WITH m.ccity, ;
               czip      WITH m.czip, ;
               cstate    WITH m.cstate, ;
               cbaddr1   WITH m.cbaddr1, ;
               cbaddr2   WITH m.cbaddr2, ;
               cbcity    WITH m.cbcity, ;
               cbstate   WITH m.cbstate, ;
               cbzip     WITH m.cbzip, ;
               cphone    WITH m.cphone, ;
               ctaxid    WITH m.ctaxid, ;
               ccontact  WITH m.ccontact
              
    ELSE
       m.ccustid = vendor.cvendorid
       m.ccustname = vendor.cvendname
       m.caddress1 = vendor.caddress1
       m.caddress2 = vendor.caddress2
       m.ccity = vendor.ccity
       m.cstate = vendor.cstate
       m.czip = vendor.czip
       m.cbaddr1 = vendor.cbaddr1
       m.cbaddr2 = vendor.cbaddr2
       m.cbcity = vendor.cbcity
       m.cbstate = vendor.cbstate
       m.cbzip = vendor.cbzip
       m.cphone = vendor.cphone
       m.ctaxid = vendor.ctaxid
       m.ccontact = vendor.ccontact
       INSERT INTO custs FROM MEMVAR
    ENDIF
 ENDSCAN
ENDPROC
**
*** 
*** ReFox - all is not lost 
***

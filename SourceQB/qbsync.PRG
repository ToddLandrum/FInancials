
LOCAL qbutils, tlNewOnly, llOwner_as_Vendor

tlNewOnly = .f.

qbutils = m.goapp.oQB

IF FILE(m.goapp.ccommonfolder+'ownerasvendor.txt')
   llOwner_as_vendor = .t.
ELSE
   llOwner_as_vendor = .f.
ENDIF 

IF m.goapp.oQB.lqbactive
   if not used('qbbadnames')
      create cursor qbbadnames ;
        (cid    c(10), ;
         cname  C(40), ;
         ctype  C(15), ;
         nqberror I) 
   endif      

   IF NOT USED('compmast')
      USE compmast IN 0
   ENDIF
   lcidcomp = m.goapp.cidcomp
   SELE compmast
   LOCATE FOR cidcomp = lcidcomp
   IF FOUND()
      qbutils.sync_vendors(tlNewOnly)     && Synchronize Vendors
      SELECT vendor
      TABLEUPDATE(.t.,.t.)
      qbutils.sync_terms()       && Synchronize Terms
      SELECT terms
      TABLEUPDATE(.t.,.t.)
      qbutils.sync_wells(tlNewOnly)       && Synchronize Wells with Classes
      SELECT wells
      TABLEUPDATE(.t.,.t.)
      IF llOwner_as_vendor
         qbutils.sync_owners_as_vendors(tlNewOnly)      && Synchronize Owners with Vendors
      ELSE
         qbutils.sync_owners(tlNewOnly)      && Synchronize Owners with Customers
      ENDIF  
      SELECT investor
      TABLEUPDATE(.t.,.t.)  
      qbutils.sync_purchaser(tlNewOnly)   && Synchronize Purchasers
      SELECT revsrc
      TABLEUPDATE(.t.,.t.)
      qbutils.sync_expcat(tlNewOnly)      && Synchronize Expense Categories and Items
      SELECT expcat
      TABLEUPDATE(.t.,.t.)
      SELE compmast
      REPL dsyncqb WITH DATE()
      sele qbbadnames
      if recc() <> 0
         LOCAL lcPreviewWindowName
         lcPreviewWindowName=SYS(2015)
         DEFINE WINDOW (lcPreviewWindowName) ;
             FROM 0,0 TO SROWS(),SCOLS() ;
             TITLE "Synchronization Report Preview" ;
             SYSTEM CLOSE FLOAT GROW MINIMIZE ZOOM
         ZOOM WINDOW (lcPreviewWindowName) MAX

         REPORT FORM qbsyncerr TO PRINTER PROMPT PREVIEW WINDOW (lcPreviewWindowName)
         RELEASE WINDOW (lcPreviewWindowName)
         REPORT FORM qbsyncerr TO PRINTER PROMPT NOCONSOLE NOEJECT
      endif   
   ENDIF
ENDIF

qbutils = .null.

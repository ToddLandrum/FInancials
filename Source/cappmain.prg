**************************************************
*-- Class Library:  c:\develop\_newversions\am\source\appmain.vcx
**************************************************


**************************************************
*-- Class:        appapplicationsettings (c:\develop\_newversions\dmie\source\appmain.vcx)
*-- ParentClass:  cmapplicationsettings (c:\develop\_newversions\ampro_rv\common\cmapp.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   01/08/19 05:54:02 PM
*
DEFINE CLASS appapplicationsettings AS cmapplicationsettings
   cdevelopertoolbarclass = 'tbrDevelopmentToolbarCustom'
   cproject               = 'dmie.pjx'
   cglobalobjectlist      = 'cmSecurity'
   lupdateproc            = .T.
   lupdateclass           = .T.
   lupdatelocalized       = .T.
   cclasslibrarylist      = ''
   cclasslibrarylist0     = ''
   cclasslibrarylist1     = ''
   cclasslibrarylist2     = ''
   cclasslibrarylist3     = ''
   cclasslibrarylist4     = ''
   cclasslibrarylist5     = ''
   cclasslibrarylist6     = ''
   clocalizedlibrarylist  = ''
   cprocedurelibrarylist  = ''
   cprocedurelibrarylist0 = ''
   cprocedurelibrarylist1 = ''
   cprocedurelibrarylist2 = ''
   cprocedurelibrarylist3 = ''
   cprocedurelibrarylist4 = ''
   cprocedurelibrarylist5 = ''
   cprocedurelibrarylist6 = ''
   cprocedurelibrarylist7 = ''
   cprocedurelibrarylist8 = ''
   NAME                   = 'cmapplicationsettings'
ENDDEFINE
*
*-- EndDefine: appapplicationsettings
**************************************************
**************************************************
*-- Class:        appapplication (c:\develop\_newversions\dmie\source\appmain.vcx)
*-- ParentClass:  cmapplicationcustom (c:\develop\_newversions\dmie\custom\cappcustom.prg)
*-- BaseClass:    custom
*-- Time Stamp:   12/30/20 11:53:12 AM
*
*#INCLUDE "c:\develop\_newversions\am\source\appdefs.h"
*
DEFINE CLASS appapplication AS swapplicationcustom


   HEIGHT = 33
   WIDTH  = 104
   *-- Address line 1 of the currently open company.
   caddress1 = '4182 Clemmons Road #285'
   *-- Address line2 of the currently open company.
   caddress2 = ''
   *-- Address line 3 of the currently open company.
   caddress3 = ''
   *-- Tax ID of the currently open company
   ctaxid = '34-1782882'
   *-- Contact name for the currently open company
   ccontact         = 'Phil Sherwood'
   ccity            = 'Clemmons'
   cstate           = 'OH'
   czip             = '44606'
   cfileversion     = '6.0.0'
   cagentname       = ''
   sdkversion       = "' '"
   qbfcversion      = "' '"
   lgraphingopt     = .F.
   lpdfopt          = .F.
   lqbinstalled     = .F.
   cregcompany      = ''
   cfaxno           = ''
   cphoneno         = "''"
   lqbversion       = .F.
   lqboversion      = .F.
   oqb              = .F.
   cdatafilepath    = ''
   ccompanyname     = 'Sample Company'
   cuser            = ''
   cidcomp          = .NULL.
   lnologon         = .F.
   cclient          = ''
   ccode            = ''
   cmenu            = 'appMenu.mpr'
   ctoolbars        = 'tbrMainToolbar'
   csplash          = 'frmAppSplashScreen'
   cfillbitmap      = ''
   cbanner          = 'c:\Develop\_SherWare\GRAPHICS\sherware.png'
   cicon            = 'c:\develop\_sherware\graphics\pivoten-icon.ico'
   lautoyield       = .T.
   nproduct         = 21
   cdemocode        = '1312-1780-8502-1122-8005'
   cproductname     = 'DMIE'
   cdatabaseversion = '3.5.3'
   helpfilename     = 'DMIE.CHM'
   helpfiledate     = {^2015/05/22}
   formicon         = 'c:\develop\_sherware\GRAPHICS\pivoten-icon.ico'
   cfullversion     = '3.4.8'
   NAME             = 'appapplication'

   *-- Flag to tell whether a company is open or not.  .T. = Company Files are open
   lopencompany = .F.

   *-- .T. = MICR Option
   lmicropt = .F.

   *-- .T. = Investment Manager option
   linvopt = .F.

   *-- .T. = K1 and 1065 Option
   lk1opt = .F.

   *-- .T. = Land Mgr option
   llandopt = .F.

   *-- .T. = AFE Option
   lafeopt = .F.

   *-- Registration Code
   cregcode = .F.

   *-- .T. if the data files should be audited using FoxAudit
   laudit       = .F.
   lsepjibclose = .F.

   *-- Brine Hauler Option
   lbrineopt  = .F.
   cagentname = .F.

   *-- .T. if keyexcel.scx exists
   lkeystone = .F.

   *-- OK Tax form is present.
   loktax = .F.

   *-- Codes from the xflag field in compmast.
   xflag = .F.

   *-- Rev Dist Privilege
   lrevdistpriv = .F.

   *-- Payroll Privilege
   lpayrollpriv = .F.

   *-- G/L Privilege
   lglpriv = .F.

   *-- A/P Privilege
   lappriv = .F.

   *-- A/R Privilege
   larpriv = .F.

   *-- Land Files Privilege
   llandpriv       = .F.
   lbrinepriv      = .F.
   lafepriv        = .F.
   linvestpriv     = .F.
   ladminpriv      = .F.
   lrevdistrptpriv = .F.
   lcashpriv       = .F.

   *-- JIB Option
   ljibopt = .F.

   *-- Revenue Option
   lrevopt = .F.

   *-- QuickBooks Company Filename
   cqbcompany = .F.
   *-- QuickBooks Session Manager Object
   oqbsm = .F.
   *-- QuickBooks Request Object
   oqbrequest = .F.
   *-- Status of QuickBooks Connection .T. = Active
   lqbactive    = .F.
   lhousegasopt = .F.

   *-- Set when an OLE error occurs
   lqberror = .F.
   *-- The major version of quickbooks.
   qbversion = .F.

   *-- Program Option
   lprogopt = .F.
   *-- What version of the SDK can be used on the open QuickBooks file.
   sdkversion    = .F.
   landpro       = .F.
   brinepro      = .F.
   lreportpriv   = .F.
   ldirdmdep     = .F.
   capplevel     = .F.
   csdkver       = .F.
   cqbfcver      = .F.
   lhousegaspriv = .F.
   lprogpriv     = .F.
   ljibpriv      = .F.
   ldoipriv      = .F.

   *-- State Codes Array
   DIMENSION lastates[1]

   *-- Months Array
   DIMENSION lamonths[1]


   *-- Handles QuickBooks Errors
   **********************************   
   PROCEDURE qberror
      **********************************   
      LPARAMETERS tnerror, tcmessage, tnlineno

      = AERROR(aErrInfo)

      swselect('expense')
      SCAN FOR cYear = 'FIXD' AND (cRunYearJIB # 'FIXD' OR cRunYearRev # 'FIXD')
         REPLACE cRunYearJIB WITH 'FIXD', cRunYearRev WITH 'FIXD'
      ENDSCAN
   ENDPROC

   **********************************
   PROCEDURE oqb_access
      **********************************   
      IF VARTYPE(THIS.oqb) # 'O'
         IF THIS.lOptQBD
            THIS.oqb = CREATEOBJECT('qbutils')
         ELSE
            THIS.oqb = CREATEOBJECT('swqbo')
         ENDIF
      ENDIF

      RETURN THIS.oqb
   ENDPROC

   ***************************
   PROCEDURE set_payment_types
      ***************************
      LOCAL lcPmtType, lcPath

      * Not used anymore - pws 12/12/13
      RETURN
      lcPmtType = 'A'

      lcPath = ALLT(THIS.cdatafilepath)

      *
      *  Sets the payment types to the correct type:  Customer, JIB, Net or House Gas
      *

      swselect('arpmthdr')
      swselect('arpmtdet')

      SELE arpmthdr
      SCAN FOR EMPTY(cpmttype)

         m.cbatch = cbatch

         SELE arpmtdet
         SCAN FOR cbatch == m.cbatch

            DO CASE
               CASE 'JIB' $ cinvnum
                  lcPmtType = 'J'
               CASE EMPTY(cinvtoken)
                  lcPmtType = 'N'
               OTHERWISE
                  lcPmtType = 'A'
            ENDCASE
         ENDSCAN

         SELE arpmthdr
         REPL cpmttype WITH lcPmtType
      ENDSCAN



   ENDPROC

   ***************************
   PROCEDURE addrevcat
      ***************************
      **  Scan the current revcat table, and add any missing categories **
      LOCAL lnCount, lnRecNo, llFound
      LOCAL llReturn, loError
      *:Global cRevDesc, cRevType

      llReturn = .T.

      TRY
         swselect('revcat')
         SET DELETED OFF
         SET ORDER TO 0
         swselect('revcat')
         COUNT FOR NOT DELETED() TO lnCount

         IF lnCount # 20  &&  Not the maximum that there should be, so check to see what's missing

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLTRIM(cRevType) = 'BBL'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'BBL'
               m.cRevDesc = 'Oil Revenue'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'MCF'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'MCF'
               m.cRevDesc = 'Gas Revenue'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'TRANS'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'TRANS'
               m.cRevDesc = 'Transp Revenue'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'OTAX1'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'OTAX1'
               m.cRevDesc = 'Oil Tax 1'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'OTAX2'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'OTAX2'
               m.cRevDesc = 'Oil Tax 2'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'OTAX3'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'OTAX3'
               m.cRevDesc = 'Oil Tax 3'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'OTAX4'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'OTAX4'
               m.cRevDesc = 'Oil Tax 4'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'GTAX1'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'GTAX1'
               m.cRevDesc = 'Gas Tax 1'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'GTAX2'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'GTAX2'
               m.cRevDesc = 'Gas Tax 2'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'GTAX3'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'GTAX3'
               m.cRevDesc = 'Gas Tax 3'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'GTAX4'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'GTAX4'
               m.cRevDesc = 'Gas Tax 4'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'PTAX1'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'PTAX1'
               m.cRevDesc = 'Other Product Tax 1'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'PTAX2'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'PTAX2'
               m.cRevDesc = 'Other Product Tax 2'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'PTAX3'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'PTAX3'
               m.cRevDesc = 'Other Product Tax 3'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'PTAX4'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'PTAX4'
               m.cRevDesc = 'Other Product Tax 4'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'MISC1'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'MISC1'
               m.cRevDesc = 'Misc Revenue 1'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'MISC2'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'MISC2'
               m.cRevDesc = 'Misc Revenue 2'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'OTH'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'OTH'
               m.cRevDesc = 'Other Revenue'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'COMP'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'COMP'
               m.cRevDesc = 'Compression Expense'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            llFound = .F.  &&  Variable for determining whether the specified category is found
            SCAN FOR ALLT(cRevType) = 'GATH'
               llFound = .T.
            ENDSCAN
            IF NOT llFound
               m.cRevType = 'GATH'
               m.cRevDesc = 'Gathering Expense'
               INSERT INTO revcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
            ENDIF

            SELECT revcat
            GO TOP
         ENDIF

         SET DELETED ON
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'AddRevcat', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
      ENDTRY

      RETURN llReturn
   ENDPROC

   ***************************
   PROCEDURE copydisposal
      ***************************
      LOCAL llReturn, loError
      llReturn = .T.
      * Not used anymore 1/4/17
      RETURN .T.
      TRY
         swselect('disposal')
         SCAN
            IF EMPTY(cpermit1)
               REPL cpermit1 WITH cdisperm
            ENDIF
         ENDSCAN
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'CopyDisposal', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
      ENDTRY

      RETURN llReturn
   ENDPROC


   *-- Populates the glbatches table if it is empty
   *************************** 
   PROCEDURE create_glbatches
      ***************************
      LPARAMETERS tlRebuild

      LOCAL lnCount
      LOCAL llReturn, loError

      llReturn = .T.

      TRY

         swselect('glbatches')
         COUNT FOR NOT DELETED() TO lnCount
         IF lnCount = 0
            WAIT WINDOW NOWAIT 'Creating GlBatches Table (One Time Only)'
            swselect('glmaster')
            SELECT  Glmaster.cbatch, ;
                    Glmaster.cref, ;
                    Glmaster.ddate ;
                FROM appdata!Glmaster ;
                INTO CURSOR temp ;
                GROUP BY Glmaster.cbatch ;
                ORDER BY Glmaster.cbatch

            IF _TALLY > 0
               SELECT glbatches
               APPEND FROM DBF('temp')
            ENDIF
            WAIT CLEAR
         ELSE
            IF tlRebuild
               WAIT WINDOW NOWAIT 'Rebuilding GlBatches Table...'
               SELECT glbatches
               DELETE ALL
               SET ORDER TO cbatch
               swselect('glmaster')
               SELECT  Glmaster.cbatch, ;
                       Glmaster.cref, ;
                       Glmaster.ddate ;
                   FROM appdata!Glmaster ;
                   INTO CURSOR temp ;
                   GROUP BY Glmaster.cbatch ;
                   ORDER BY Glmaster.cbatch
               IF _TALLY > 0
                  SELECT glbatches
                  APPEND FROM DBF('temp')
               ENDIF
               WAIT CLEAR
            ENDIF
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'Create_GLBatches', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
         MESSAGEBOX('Unable to create the GL Batches table at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
              'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn
   ENDPROC


   *-- Copies the SUTA records from PRTAX4 to PRSUTA if no records exist in PRSUTA.
   ***************************
   PROCEDURE copysuta
      ***************************
      LOCAL llReturn, loError
      llReturn = .T.
      * Not used anymore 1/4/17
      RETURN .T.
      TRY
         IF FILE(m.goApp.cCommonFolder + 'prtax4.dbf')
            IF NOT USED('prtax4')
               USE (m.goApp.cCommonFolder + 'prtax4') IN 0
            ENDIF

            IF NOT USED('prsuta')
               USE (m.goApp.cdatafilepath + 'prsuta') IN 0
            ENDIF


            * If PRSUTA is empty, copy the PRTAX4 records to it
            * We're using PRSUTA now instead of PRTAX4 - pws 10/2/13
            SELECT prsuta
            IF RECCOUNT() = 0
               SELECT prtax4
               SCAN
                  SCATTER MEMVAR
                  INSERT INTO prsuta FROM MEMVAR
               ENDSCAN
            ENDIF
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'CopySUTA', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
         *   MESSAGEBOX('Unable to process the SUTA table at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn
   ENDPROC

   ***************************
   PROCEDURE finddeposits
      ***************************
      * Not used anymore 1/4/17
      RETURN .T.
      TRY
         swselect('csrcthdr')
         swselect('checks')
         * Check to see if this utility has already been run
         LOCATE FOR '@@#' $ cidchec
         IF FOUND()
            llReturn = .T.
            EXIT
         ENDIF

         SELECT  * ;
             FROM csrcthdr ;
             WHERE ncashamt # 0 ;
                 AND NOT EMPTY(dpostdate) ;
                 AND cbatch NOT IN (SELECT  cbatch ;
                                        FROM checks) ;
             INTO CURSOR temp

         lnkey = 500

         SELECT temp
         SCAN
            SCATTER MEMVAR

            m.cSource    = 'CS'
            m.cbatch     = m.cbatch
            m.dGLDate    = m.dpostdate
            m.cReference = 'Cash: ' + ALLTRIM(m.cinvnum)
            m.cDesc      = m.cname
            m.cacctno    = m.ccashacct
            m.cId        = m.cId
            m.namount    = m.ncashamt
            m.cBunch     = ''
            m.lprinted   = .T.
            m.dCheckDate = m.dpostdate
            m.dpostdate  = m.dpostdate
            m.cpayee     = m.cname
            m.cidchec    = ''
            m.centrytype = 'D'
            m.cidtype    = 'D'
            m.cYear      = ' '
            m.cperiod    = ' '
            m.lcleared   = .F.
            m.ccheckno   = m.ccheckno
            m.cidchec    = '@@#' + PADL(TRANSFORM(lnkey), 5, '0')
            lnkey        = lnkey + 1
            INSERT INTO checks FROM MEMVAR
         ENDSCAN
      CATCH TO loError
         MESSAGEBOX(loError.MESSAGE, 0, 'Error')
      ENDTRY
   ENDPROC

   ***************************
   PROCEDURE START
      ***************************
      LPARAMETERS cParameter

      IF FILE('datafiles\_multi.txt')
         THIS.lsingleinstance = .F.
      ELSE
         THIS.lsingleinstance = .T.
      ENDIF

      DODEFAULT(cParameter)
   ENDPROC

   ***************************
   PROCEDURE fixownstmts
      ***************************
      * Not used anymore - pws 12/12/13
      RETURN
      *
      *  Fixes the "Print When" clause for program headers
      *
      IF USED('dmrownstmt1')
         USE IN dmrownstmt1
      ENDIF

      IF USED('dmrownstmt2')
         USE IN dmrownstmt2
      ENDIF

      IF USED('dmrownstmt3')
         USE IN dmrownstmt3
      ENDIF

      IF USED('dmrownstmt4')
         USE IN dmrownstmt4
      ENDIF

      SET SAFETY OFF

      *  If the ownerstatement files don't exist in the Rpts folder. Place a copy of them there.  pws  11/10/04
      IF NOT FILE(m.goApp.cRptsFolder + 'dmrownstmt1.frx')
         USE tmpownstmt1.frx IN 0
         SELE tmpownstmt1
         COPY TO (m.goApp.cRptsFolder + 'dmrownstmt1.frx')
         USE IN tmpownstmt1
         RETURN
      ENDIF

      USE (m.goApp.cRptsFolder + 'dmrownstmt1.frx') IN 0

      SELE dmrownstmt1
      SCAN
         IF supexpr = "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> 'ZZZ' AND LEFT(cwelltype,3) <> 'YZZ')"
            REPL supexpr WITH "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> '}ZZ' AND LEFT(cwelltype,3) <> '{YZ')"
         ENDIF
      ENDSCAN

      USE IN dmrownstmt1

      IF NOT FILE(m.goApp.cRptsFolder + 'dmrownstmt2.frx')
         USE tmpownstmt2.frx IN 0
         SELE tmpownstmt2
         COPY TO (m.goApp.cRptsFolder + 'dmrownstmt2.frx')
         USE IN tmpownstmt2
         RETURN
      ENDIF

      USE (m.goApp.cRptsFolder + 'dmrownstmt2.frx') IN 0

      SELE dmrownstmt2
      SCAN
         IF supexpr = "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> 'ZZZ' AND LEFT(cwelltype,3) <> 'YZZ')"
            REPL supexpr WITH "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> '}ZZ' AND LEFT(cwelltype,3) <> '{YZ')"
         ENDIF
      ENDSCAN

      USE IN dmrownstmt2

      IF NOT FILE(m.goApp.cRptsFolder + 'dmrownstmt3.frx')
         USE tmpownstmt3.frx IN 0
         SELE tmpownstmt3
         COPY TO (m.goApp.cRptsFolder + 'dmrownstmt3.frx')
         USE IN tmpownstmt3
         RETURN
      ENDIF

      USE (m.goApp.cRptsFolder + 'dmrownstmt3.frx') IN 0

      SELE dmrownstmt3
      SCAN
         IF supexpr = "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> 'ZZZ' AND LEFT(cwelltype,3) <> 'YZZ')"
            REPL supexpr WITH "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> '}ZZ' AND LEFT(cwelltype,3) <> '{YZ')"
         ENDIF
      ENDSCAN

      USE IN dmrownstmt3

      IF NOT FILE(m.goApp.cRptsFolder + 'dmrownstmt4.frx')
         USE tmpownstmt4.frx IN 0
         SELE tmpownstmt4
         COPY TO (m.goApp.cRptsFolder + 'dmrownstmt4.frx')
         USE IN tmpownstmt4
         RETURN
      ENDIF

      USE (m.goApp.cRptsFolder + 'dmrownstmt4.frx') IN 0

      SELE dmrownstmt4
      SCAN
         IF supexpr = "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> 'ZZZ' AND LEFT(cwelltype,3) <> 'YZZ')"
            REPL supexpr WITH "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> '}ZZ' AND LEFT(cwelltype,3) <> '{YZ')"
         ENDIF
      ENDSCAN

      USE IN dmrownstmt4
   ENDPROC

   ***************************
   PROCEDURE fixpurchd
      ***************************
      LOCAL lccatcode, lcexpclass

      * Not used anymore - pws - 12/12/13
      RETURN

      swselect('expcat')

      swselect('appurchd')
      SCAN FOR NOT EMPTY(ccatcode) AND EMPTY(cexpclass)
         lccatcode = ccatcode
         SELE expcat
         LOCATE FOR ccatcode == lccatcode
         IF FOUND()
            lcexpclass = cexpclass
            SELE appurchd
            REPL cexpclass WITH lcexpclass
         ENDIF
      ENDSCAN

      swselect('appurecd')
      SCAN FOR NOT EMPTY(ccatcode) AND EMPTY(cexpclass)
         lccatcode = ccatcode
         SELE expcat
         LOCATE FOR ccatcode == lccatcode
         IF FOUND()
            lcexpclass = cexpclass
            SELE appurecd
            REPL cexpclass WITH lcexpclass
         ENDIF
      ENDSCAN
   ENDPROC

   ***************************
   PROCEDURE cleandbfs
      ***************************
      LOCAL lafiles[1], lcfile, llReturn, lnFiles, lnx, loError
      llReturn = .T.
      * Not used anymore 1/4/17
      RETURN .T.
      TRY
         * Remove any database containers from the executable folder. 
         * Having one there causes mucho problems.
         ERASE appdata.DBC
         ERASE appdata.dcx
         ERASE appdata.dct

         * If there's not a data folder, get out of here.
         * This method needs a data folder to function properly.
         IF NOT DIRECTORY('data')
            llReturn = .F.
            EXIT
         ENDIF

         * Get a list of tables in the data folder.
         lnFiles = ADIR(lafiles, 'data\*.dbf')

         FOR lnx = 1 TO lnFiles
            lcfile = LOWER(ALLT(STRTRAN(LOWER(lafiles[lnx, 1]), '.dbf', '')))
            * Remove the table from the executable folder
            IF NOT INLIST(lcfile, 'appreg02', 'compmast', 'prtax', 'coremeta', 'sdtmeta', 'dbcxreg', 'sdtuser')  &&  Don't delete the prtax 1,3,5 tables - BH 02/20/2007
               ERASE (lcfile + '.*')
            ENDIF
         ENDFOR
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'CleanDBFs', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
      ENDTRY

      RETURN llReturn
   ENDPROC

   ***************************
   PROCEDURE custommethods
      ***************************
      LOCAL lnCount, lcPath
      LOCAL lPosted, ldisbman, llReturn, llFound, lnkey, lnetdef, loError
      *:Global cPeriod, cRunYear, cVersion, cdesc, cgroup, cidsysctl, ctimeclose, ctypeclose, cyear
      *:Global dExpDate, dRevDate, dacctdate, ddateclose, dpostdate, nRunNo

      DODEFAULT()

      llReturn = .T.

      TRY

         * Convert Coa to new multi-level accounts
         DO calccoaparent

         * Copy the PRTAX4 records to PRSUTA
         THIS.copysuta()

         *  Option to send all revenue and expenses to allocation files
         swselect('options')
         GO TOP
         THIS.lSendToAllocate = options.lSendToAllocate

         IF FILE('keyexcel.dat')
            THIS.lkeystone = .T.
         ELSE
            THIS.lkeystone = .F.
         ENDIF

         IF FILE('dmroktax.scx')
            THIS.loktax = .T.
         ELSE
            THIS.loktax = .F.
         ENDIF

         * Make sure the default group is defined
         swselect('groups')
         SET DELE OFF
         llFound = .F.
         LOCATE FOR cgroup == '00'
         IF FOUND()
            IF DELETED()
               RECALL
            ENDIF
         ELSE
            m.cgroup  = '00'
            m.cDesc   = 'Default Group'
            m.lnetdef = .T.
            INSERT INTO groups FROM MEMVAR
         ENDIF

         SET DELE ON

         * Delete extra glopt records
         swselect('glopt')
         COUNT FOR NOT DELETED() TO lnCount
         IF lnCount > 1
            LOCATE FOR EMPTY(crevclear)
            IF FOUND()
               DELETE NEXT 1
            ENDIF
         ENDIF

         * Add a sysctl record if there are none
         swselect('sysctl')
         COUNT FOR NOT DELETED() TO lnCount
         lnkey    = 1
         m.nRunNo = 12
         IF lnCount = 0
            swselect('groups')
            SCAN
               m.cgroup     = cgroup
               m.cidsysctl  = 'BEG' + PADL(TRANSFORM(lnkey), 3, '0')
               lnkey        = lnkey + 1
               m.cYear      = '1980'
               m.cRunYear   = '1980'
               m.cperiod    = '12'
               m.dacctdate  = {12/31/1980}
               m.dpostdate  = {12/31/1980}
               m.dRevDate   = {12/31/1980}
               m.dExpDate   = {12/31/1980}
               m.ctypeclose = 'R'
               m.ldisbman   = .T.
               m.lPosted    = .T.
               m.ddateclose = DATE()
               m.ctimeclose = TIME()
               m.cversion   = STRTRAN(m.goApp.cfileversion, '.', '')
               INSERT INTO sysctl FROM MEMVAR
               m.nRunNo = m.nRunNo + 1
            ENDSCAN
         ENDIF

         lcPath = THIS.cdatafilepath

         * Check for empty calculation methods and warn the user.
         THIS.checktaxes()

         WAIT CLEAR
         THIS.oRegistry.cDBCPath = ALLTRIM(THIS.cdatafilepath) + 'APPDATA.DBC'

         *
         *  Set the Separate JIB Close property so the menu item can be enable or disabled
         *
         swselect('options')
         THIS.lsepjibclose = lSepClose
         * Disable the change the price to account for compression and
         * hide compression on owner statements options  7/17/07 pws
         *!*   REPLACE lchgprice WITH .f., lhidecomp WITH .f.
         *!*   USE IN options

         * Insert a record in GLOPT if it's empty
         swselect('glopt')
         IF RECC() = 0
            SCATTER MEMVAR BLANK
            RELEASE M.pk
            INSERT INTO glopt FROM MEMVAR
         ENDIF
         GO TOP
         IF NOT BETWEEN(glopt.cfybegin, '01', '12')
            REPL glopt.cfybegin WITH '01'
         ENDIF

         THIS.addrevcat()  &&  Add any missing revenue categories

         *  Convert Susaudit file to Suspense File - only do if suspense table is empty
         * THIS.ConvertSuspense()

         THIS.copydisposal()

         * Mark dummy owners
         swselect('investor')
         LOCATE FOR ldummy = .T.
         IF NOT FOUND()
            WAIT WINDOW NOWAIT 'Performing "Dummy" owner check...'
            SCAN FOR 'DUMMY' $ UPPER(cownname)
               REPLACE ldummy WITH .T.
            ENDSCAN
            WAIT CLEAR
         ENDIF

         * Populate the glbatches table if it is empty
         THIS.create_glbatches()

         * Determine tax id type and fill it in
         THIS.Get_TaxID_Type()

         * Find missing deposit entries and place them in the register
         THIS.finddeposits()

         * Open the QB Connection if we're that version
         IF m.goApp.lOptQBD OR m.goApp.lOptQBO
            THIS.OpenQBConnection()
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'CustomMethods', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
      ENDTRY

      RETURN llReturn
   ENDPROC

   ***************************
   PROCEDURE Get_TaxID_Type
      ***************************
      * Look to see if the tax id type has been determined yet.
      * If so, bail out. Otherwise try to determine the tax id type
      * by looking at the number of dashes (-) in the id
      * Not used anymore 1/4/17
      RETURN .T.
      swselect('investor')
      LOCATE FOR itaxidtype = 1 OR itaxidtype = 2
      IF NOT FOUND()
         WAIT WINDOW NOWAIT 'Determining tax id types (one time only)...'
         SCAN
            m.ctaxid = ctaxid
            lnCount  = GETWORDCOUNT(m.ctaxid, '-')
            IF lnCount = 2
               REPLACE itaxidtype WITH 1
            ELSE
               REPLACE itaxidtype WITH 2
            ENDIF
         ENDSCAN

         swselect('vendor')
         SCAN
            m.ctaxid = ctaxid
            lnCount  = GETWORDCOUNT(m.ctaxid, '-')
            IF lnCount = 2
               REPLACE itaxidtype WITH 1
            ELSE
               REPLACE itaxidtype WITH 2
            ENDIF
         ENDSCAN
         WAIT CLEAR
      ENDIF

   ENDPROC

   *****************************
   PROCEDURE OpenQBConnection
      *****************************

      IF THIS.lopencompany
         swselect('glopt')
         GO TOP
         THIS.cqbcompany = ALLT(cqbfilename)

         swselect('options')
         GO TOP

         IF NOT THIS.lqbactive
            IF THIS.lOptQBD
               llQBError      = THIS.oqb.QBConnection()
            ELSE
               WAIT WINDOW NOWAIT 'Connecting to QuickBooks Online...'
               llQBError      = THIS.oqb.ConnectTOQBCompany()
               WAIT CLEAR
               IF NOT llQBError
                  MESSAGEBOX('Could not connect to QuickBooks Online. Message received: ' + CHR(13) + ;
                       THIS.oqb.cErrorMsg, 64, 'Connect to QBO')
               ENDIF
            ENDIF
            THIS.lqberror  = NOT llQBError
            THIS.lqbactive = THIS.oqb.lqbactive
            IF THIS.lqbactive
               THIS.oqb.Error_Recovery()
            ENDIF
         ENDIF
      ENDIF
   ENDPROC

   **********************************
   PROCEDURE fixswqbaddress
      **********************************   
      LOCAL lovendorquery AS 'qbfc7.ivendorquery'
      LOCAL lovendormod   AS 'qbfc7.ivendormod'
      LOCAL lActive, llError, lni, lnvendor, loError, lorequest, loresponse, lovend, lovendresp, lsend1099

      TRY

         THIS.oqb.fixswqbaddress()

      CATCH TO loError
         llError = .T.
      ENDTRY

      TRY
         lorequest.ClearRequests()
      CATCH
      ENDTRY
   ENDPROC
   ***************************
   PROCEDURE openerror
      ***************************
   ENDPROC


   *-- Emails errorlog.dbf to SherWare Sales
   ***************************
   PROCEDURE senderrorfile
      ***************************
   ENDPROC

   ***************************
   PROCEDURE fixcounters
      ***************************
   ENDPROC

   ***************************
   PROCEDURE set_patch_registry
      ***************************
   ENDPROC

   ***************************
   PROCEDURE process_xflags
      ***************************
   ENDPROC

   ***************************
   PROCEDURE copystatetaxpct
      *************************** 
   ENDPROC


ENDDEFINE
*
*-- EndDefine: appapplication
**************************************************


**************************************************
*-- Class:        appapplicationsettings (c:\develop\_newversions\am\source\appmain.vcx)
*-- ParentClass:  cmapplicationsettings (c:\develop\_newversions\am\common\cmapp.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   01/27/21 10:46:07 AM
*
DEFINE CLASS appapplicationsettings AS cmapplicationsettings


   cdevelopertoolbarclass = 'tbrDevelopmentToolbarCustom'
   cproject               = 'ampro.pjx'
   cglobalobjectlist      = 'cmSecurity'
   lupdateproc            = .T.
   lupdateclass           = .T.
   lupdatelocalized       = .T.
   cclasslibrarylist      = ''
   cclasslibrarylist0     = ''
   cclasslibrarylist1     = ''
   cclasslibrarylist2     = ''
   cclasslibrarylist3     = ''
   cclasslibrarylist4     = ''
   clocalizedlibrarylist  = ''
   cprocedurelibrarylist  = ''
   cprocedurelibrarylist0 = ''
   cprocedurelibrarylist1 = ''
   cprocedurelibrarylist2 = ''
   cprocedurelibrarylist3 = ''
   cprocedurelibrarylist4 = ''
   cprocedurelibrarylist5 = ''
   cprocedurelibrarylist6 = ''
   cprocedurelibrarylist7 = ''
   cprocedurelibrarylist8 = ''
   NAME                   = 'cmapplicationsettings'


ENDDEFINE
*
*-- EndDefine: appapplicationsettings
**************************************************



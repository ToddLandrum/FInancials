**************************************************
*-- Class Library:  c:\develop\codeminenew\ampro_rv\source\appmain.vcx
**************************************************


**************************************************
*-- Class:        appapplication (c:\develop\codeminenew\ampro_rv\source\appmain.vcx)
*-- ParentClass:  cmapplicationcustom (c:\develop\codeminenew\ampro_rv\custom\capp.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   12/30/20 11:53:12 AM
*
#INCLUDE "c:\develop\codeminenew\ampro_rv\source\appdefs.h"
*
DEFINE CLASS swappapplication AS cmapplicationcustom


	Height = 33
	Width = 104
	*-- Address line 1 of the currently open company.
	caddress1 = "4182 Clemmons Road #285"
	*-- Address line2 of the currently open company.
	caddress2 = ""
	*-- Address line 3 of the currently open company.
	caddress3 = ""
	*-- Tax ID of the currently open company
	ctaxid = 34-1782882
	*-- Contact name for the currently open company
	ccontact = "Phil Sherwood"
	ccity = "Clemmons"
	cstate = "OH"
	czip = 44606
	cfileversion = 6.0.0
	cagentname = ""
	sdkversion = "' '"
	qbfcversion = "' '"
	lgraphingopt = .F.
	lpdfopt = .F.
	cregcompany = ""
	cfaxno = (330) 437-2791
	cphoneno = "''"
	cdatafilepath = ""
	ccompanyname = "Sample Company"
	cuser = ""
	cidcomp = .NULL.
	lnologon = .F.
	cclient = ""
	ccode = ""
	cmenu = "appMenu.mpr"
	ctoolbars = "tbrMainToolbar"
	csplash = "frmAppSplashScreen"
	cfillbitmap = ""
	cbanner = "c:\develop\codeminenew\ampro_rv\graphics\sherware.png"
	lautoyield = .F.
	nproduct = 19
	cdemocode = 9315-8940-7610-4128-005
	cversion = "600"
	cproductname = "AM"
	cdatabaseversion = 6.5.3
	helpfilename = "AMPRO.CHM"
	helpfiledate = {^2015/05/22}
	_memberdata = [<VFPData><memberdata name="finddeposits" display="FindDeposits"/><memberdata name="cdatabaseversion" type="Property" favorites="True"/></VFPData>]
	cicon = "C:\Develop\Codeminenew\AMPRO_RV\GRAPHICS\am.ico"
	formicon = "d:\dropbox\develop\codeminenew\ampro_rv\graphics\am.ico"
	Name = "appapplication"

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
	laudit = .F.
	lsepjibclose = .F.

	*-- Brine Hauler Option
	lbrineopt = .F.

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
	llandpriv = .F.
	lbrinepriv = .F.
	lafepriv = .F.
	linvestpriv = .F.
	ladminpriv = .F.
	lrevdistrptpriv = .F.
	lcashpriv = .F.

	*-- JIB Option
	ljibopt = .F.

	*-- Revenue Option
	lrevopt = .F.

	*-- House Gas Module Priviledges
	lhousegasopt = .F.

	*-- .T. = send all income and expenses to allocation files.
	lsendtoallocate = .F.

	*-- Program Option
	lprogopt = .F.
	landpro = .F.
	brinepro = .F.
	lreportpriv = .F.
	ldirdmdep = .F.
	capplevel = .F.
	csdkver = .F.
	cqbfcver = .F.
	lhousegaspriv = .F.
	lprogpriv = .F.
	ljibpriv = .F.
	ldoipriv = .F.

	*-- State Codes Array
	DIMENSION lastates[1]

	*-- Months Array
	DIMENSION lamonths[1]


	*-- Corrects problems with fixed expenses
	PROCEDURE fixedexpense
		LOCAL lcPath
		* Not used anymore  pws - 12/12/13
		RETURN 
		lcPath = allt(this.cdatafilepath)

		swselect('expense')
		SCAN FOR cYear = 'FIXD' AND (cRunYearJIB <> 'FIXD' OR cRunYearRev <> 'FIXD')
		   REPLACE cRunYearJIB WITH 'FIXD', cRunYearRev WITH 'FIXD'
		ENDSCAN
	ENDPROC


	PROCEDURE set_payment_types
		LOCAL lcPmtType, lcPath

		* Not used anymore - pws 12/12/13
		RETURN 
		lcPmtType = 'A'

		lcPath = allt(this.cdatafilepath)

		*
		*  Sets the payment types to the correct type:  Customer, JIB, Net or House Gas
		*

		swselect('arpmthdr')
		swselect('arpmtdet')

		sele arpmthdr
		scan for empty(cpmttype)
		   
		   m.cbatch = cbatch
		   
		   sele arpmtdet
		   scan for cbatch == m.cbatch
		    
		      do case
		         case 'JIB' $ cinvnum
		            lcPmtType = 'J'
		         case EMPTY(cinvtoken)
		            lcPmtType = 'N'
		         otherwise 
		            lcPmtType = 'A'
		      endcase
		   endscan
		   
		   sele arpmthdr
		   repl cpmttype with lcPmtType
		endscan

		                  
		         
	ENDPROC


	PROCEDURE addrevcat
		**  Scan the current revcat table, and add any missing categories **
		LOCAL lnCount, lnRecNo, llFound
		LOCAL llReturn, loError
		*:Global cRevDesc, cRevType

		llReturn = .T.

		TRY
		   swselect('revcat')
		   SET DELETED OFF
		   SET ORDER TO 0
		   COUNT FOR NOT DELETED() TO lnCount

		   IF lnCount <> 20  &&  Not the maximum that there should be, so check to see what's missing

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


	PROCEDURE copydisposal
		LOCAL llReturn, loError
		llReturn = .T.
		* Not used anymore 1/4/17
		RETURN .t.
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
	PROCEDURE create_glbatches
		LPARAMETERS tlRebuild

		LOCAL lncount
		LOCAL llReturn, loError

		llReturn = .T.

		TRY

		   swselect('glbatches')
		   COUNT FOR NOT DELETED() TO lncount
		   IF lncount = 0
		      WAIT WINDOW NOWAIT 'Creating GlBatches Table (One Time Only)'
		      swselect('glmaster')
			  SELECT  Glmaster.cbatch, Glmaster.cref, Glmaster.ddate ;
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
				 SELECT  Glmaster.cbatch, Glmaster.cref, Glmaster.ddate ;
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
	PROCEDURE copysuta
		LOCAL llReturn, loError
		llReturn = .T.
		* Not used anymore 1/4/17
		RETURN .t.
		TRY
		   IF FILE(m.goApp.cCommonFolder + 'prtax4.dbf')
		      IF NOT USED('prtax4')
		         USE (m.goApp.cCommonFolder + 'prtax4') IN 0
		      ENDIF

		      IF NOT USED('prsuta')
		         USE (m.goApp.cDataFilePath + 'prsuta') IN 0
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


	PROCEDURE finddeposits
		* Not used anymore 1/4/17
		RETURN .t.
		TRY
		    swselect('csrcthdr')
			swselect('checks')
		* Check to see if this utility has already been run
		    LOCATE FOR '@@#' $ cidchec
		    IF FOUND()
		       llreturn = .t.
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
		        m.lprinted   = .t.
		        m.dCheckDate = m.dpostdate
		        m.dpostdate  = m.dpostdate
		        m.cpayee     = m.cname
		        m.cidchec    = ''
		        m.centrytype = 'D'
		        m.cidtype    = 'D'
		        m.cyear      = ' '
		        m.cperiod    = ' '
		        m.lcleared   = .F.
		        m.ccheckno   = m.ccheckno
		        m.cidchec    = '@@#' + PADL(TRANSFORM(lnkey), 5, '0')
		        lnkey        = lnkey + 1
		        INSERT INTO checks FROM MEMVAR
		    ENDSCAN
		CATCH TO loerror
		    MESSAGEBOX(loerror.MESSAGE, 0, 'Error')
		ENDTRY
	ENDPROC


	PROCEDURE start
		LPARAMETERS cParameter

		IF FILE('datafiles\_multi.txt')
		   this.lsingleinstance = .f.
		ELSE
		   this.lsingleinstance = .t.
		ENDIF 

		DODEFAULT(cParameter)
	ENDPROC


	PROCEDURE fixownstmts
		* Not used anymore - pws 12/12/13
		RETURN 
		*
		*  Fixes the "Print When" clause for program headers
		*
		if used('dmrownstmt1')
		   use in dmrownstmt1
		endif

		if used('dmrownstmt2')
		   use in dmrownstmt2
		endif

		if used('dmrownstmt3')
		   use in dmrownstmt3
		endif

		if used('dmrownstmt4')
		   use in dmrownstmt4
		endif

		set safety off

		*  If the ownerstatement files don't exist in the Rpts folder. Place a copy of them there.  pws  11/10/04
		if not file(m.goapp.cRptsFolder+'dmrownstmt1.frx')
		   use tmpownstmt1.frx in 0
		   sele tmpownstmt1
		   copy to (m.goapp.cRptsFolder+'dmrownstmt1.frx')
		   use in tmpownstmt1
		   return
		endif   

		use (m.goapp.cRptsFolder+'dmrownstmt1.frx') in 0

		sele dmrownstmt1
		scan
		   if supexpr = "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> 'ZZZ' AND LEFT(cwelltype,3) <> 'YZZ')"
		      repl supexpr with "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> '}ZZ' AND LEFT(cwelltype,3) <> '{YZ')"
		   endif   
		endscan

		use in dmrownstmt1

		if not file(m.goapp.cRptsFolder+'dmrownstmt2.frx')
		   use tmpownstmt2.frx in 0
		   sele tmpownstmt2
		   copy to (m.goapp.cRptsFolder+'dmrownstmt2.frx')
		   use in tmpownstmt2
		   return
		endif   

		use (m.goapp.cRptsFolder+'dmrownstmt2.frx') in 0

		sele dmrownstmt2
		scan
		   if supexpr = "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> 'ZZZ' AND LEFT(cwelltype,3) <> 'YZZ')"
		      repl supexpr with "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> '}ZZ' AND LEFT(cwelltype,3) <> '{YZ')"
		   endif   
		endscan

		use in dmrownstmt2

		if not file(m.goapp.cRptsFolder+'dmrownstmt3.frx')
		   use tmpownstmt3.frx in 0
		   sele tmpownstmt3
		   copy to (m.goapp.cRptsFolder+'dmrownstmt3.frx')
		   use in tmpownstmt3
		   return
		endif   

		use (m.goapp.cRptsFolder+'dmrownstmt3.frx') in 0

		sele dmrownstmt3
		scan
		   if supexpr = "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> 'ZZZ' AND LEFT(cwelltype,3) <> 'YZZ')"
		      repl supexpr with "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> '}ZZ' AND LEFT(cwelltype,3) <> '{YZ')"
		   endif   
		endscan

		use in dmrownstmt3

		if not file(m.goapp.cRptsFolder+'dmrownstmt4.frx')
		   use tmpownstmt4.frx in 0
		   sele tmpownstmt4
		   copy to (m.goapp.cRptsFolder+'dmrownstmt4.frx')
		   use in tmpownstmt4
		   return
		endif   

		use (m.goapp.cRptsFolder+'dmrownstmt4.frx') in 0

		sele dmrownstmt4
		scan
		   if supexpr = "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> 'ZZZ' AND LEFT(cwelltype,3) <> 'YZZ')"
		      repl supexpr with "NOT EMPTY(cprogcode) AND (LEFT(cwelltype,3) <> '}ZZ' AND LEFT(cwelltype,3) <> '{YZ')"
		   endif   
		endscan

		use in dmrownstmt4


		   
	ENDPROC


	PROCEDURE fixpurchd
		LOCAL lccatcode, lcexpclass

		* Not used anymore - pws - 12/12/13
		RETURN 

		swselect('expcat')

		swselect('appurchd')
		scan for not empty(ccatcode) and empty(cexpclass)
		   lccatcode = ccatcode
		   sele expcat
		   locate for ccatcode == lccatcode      
		   if found()
		      lcexpclass = cexpclass
		      sele appurchd
		      repl cexpclass with lcexpclass
		   endif
		endscan      

		swselect('appurecd')
		scan for not empty(ccatcode) and empty(cexpclass)
		   lccatcode = ccatcode
		   sele expcat
		   locate for ccatcode == lccatcode      
		   if found()
		      lcexpclass = cexpclass
		      sele appurecd
		      repl cexpclass with lcexpclass
		   endif
		endscan      
	ENDPROC


	PROCEDURE cleandbfs
		LOCAL lafiles[1], lcfile, llReturn, lnFiles, lnx, loError
		llReturn = .T.
		* Not used anymore 1/4/17
		RETURN .t.
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


	PROCEDURE custommethods
		LOCAL lnCount, lcPath
		LOCAL lPosted, ldisbman, llReturn, llfound, lnKey, lnetdef, loError
		*:Global cPeriod, cRunYear, cVersion, cdesc, cgroup, cidsysctl, ctimeclose, ctypeclose, cyear
		*:Global dExpDate, dRevDate, dacctdate, ddateclose, dpostdate, nRunNo

		DODEFAULT()

		llReturn = .T.

		TRY

		* Convert Coa to new multi-level accounts
		   DO calccoaparent

		* Copy the PRTAX4 records to PRSUTA
		   THIS.CopySUTA()

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
		   llfound = .F.
		   LOCATE FOR cgroup == '00'
		   IF FOUND()
		      IF DELETED()
		         RECALL
		      ENDIF
		   ELSE
		      m.cgroup  = '00'
		      m.cdesc   = 'Default Group'
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
		   lnKey    = 1
		   m.nRunNo = 12
		   IF lnCount = 0
		      swselect('groups')
		      SCAN
		         m.cgroup     = cgroup
		         m.cidsysctl  = 'BEG' + PADL(TRANSFORM(lnKey), 3, '0')
		         lnKey        = lnKey + 1
		         m.cyear      = '1980'
		         m.cRunYear   = '1980'
		         m.cPeriod    = '12'
		         m.dacctdate  = {12/31/1980}
		         m.dpostdate  = {12/31/1980}
		         m.dRevDate   = {12/31/1980}
		         m.dExpDate   = {12/31/1980}
		         m.ctypeclose = 'R'
		         m.ldisbman   = .T.
		         m.lPosted    = .T.
		         m.ddateclose = DATE()
		         m.ctimeclose = TIME()
		         m.cversion      = STRTRAN(m.goApp.cfileversion, '.', '')
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
		   THIS.lSepJIBClose = lSepClose
		* Disable the change the price to account for compression and
		* hide compression on owner statements options  7/17/07 pws
		*!*	REPLACE lchgprice WITH .f., lhidecomp WITH .f.
		*!*	USE IN options

		* Insert a record in GLOPT if it's empty
		   swselect('glopt')
		   IF RECC() = 0
		      SCATTER MEMVAR BLANK
		      INSERT INTO glopt FROM MEMVAR
		   ENDIF
		   GO TOP
		   IF NOT BETWEEN(glopt.cfybegin, '01', '12')
		      REPL glopt.cfybegin WITH '01'
		   ENDIF

		   THIS.AddRevCat()  &&  Add any missing revenue categories

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
		   this.Get_TaxID_Type()
		   
		* Find missing deposit entries and place them in the register
		   this.FindDeposits()
		   
		CATCH TO loError
		   llReturn = .F.
		   DO errorlog WITH 'CustomMethods', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
		ENDTRY

		RETURN llReturn
	ENDPROC


	PROCEDURE get_taxid_type
		* Look to see if the tax id type has been determined yet.
		* If so, bail out. Otherwise try to determine the tax id type
		* by looking at the number of dashes (-) in the id
		* Not used anymore 1/4/17
		RETURN .t.
		swselect('investor')
		LOCATE FOR itaxidtype = 1 OR itaxidtype = 2
		IF NOT FOUND()
		   WAIT WINDOW NOWAIT 'Determining tax id types (one time only)...'
		   SCAN
		      m.ctaxid = ctaxid
		      lnCount = GETWORDCOUNT(m.cTaxID,'-')
		      IF lnCount = 2
		         REPLACE itaxidtype WITH 1
		      ELSE
		         REPLACE itaxidtype WITH 2
		      ENDIF    
		   ENDSCAN
		   
		   swselect('vendor')
		   SCAN
		      m.ctaxid = ctaxid
		      lnCount = GETWORDCOUNT(m.cTaxID,'-')
		      IF lnCount = 2
		         REPLACE itaxidtype WITH 1
		      ELSE
		         REPLACE itaxidtype WITH 2
		      ENDIF    
		   ENDSCAN
		   WAIT clear 
		ENDIF
		   
		   
	ENDPROC


	PROCEDURE openerror
	ENDPROC


	*-- Emails errorlog.dbf to SherWare Sales
	PROCEDURE senderrorfile
	ENDPROC


	PROCEDURE fixcounters
	ENDPROC


	PROCEDURE set_patch_registry
	ENDPROC


	PROCEDURE process_xflags
	ENDPROC


	PROCEDURE copystatetaxpct
	ENDPROC


ENDDEFINE
*
*-- EndDefine: appapplication
**************************************************


**************************************************
*-- Class:        appapplicationsettings (c:\develop\codeminenew\ampro_rv\source\appmain.vcx)
*-- ParentClass:  cmapplicationsettings (c:\develop\codeminenew\ampro_rv\common\cmapp.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   01/27/21 10:46:07 AM
*
DEFINE CLASS appapplicationsettings AS cmapplicationsettings


	cdevelopertoolbarclass = "tbrDevelopmentToolbarCustom"
	cproject = "ampro.pjx"
	cglobalobjectlist = "cmSecurity"
	lupdateproc = .T.
	lupdateclass = .T.
	lupdatelocalized = .T.
	cclasslibrarylist = "cmactivx,cmgadget,cmregedt,cmsecure,cmtools,apptools,cmapp,cmcredit,cmname,cmlookup,custom\ccontrol.vcx,custom\cbutton.vcx,custom\cforms.vcx,custom\swcontrol.vcx,custom\cdata.vcx,custom\sw_encrypt.vcx,cmsecman,cmsetup,appmain,custom\swforms.vcx,"
	cclasslibrarylist0 = "custom\swgl.vcx,custom\swland.vcx,..\..\3rdparty\stonefield9\sdt\source\dbcxmgr.vcx,..\..\3rdparty\stonefield9\sdt\source\sdt.vcx,custom\cgadget.vcx,custom\swprefs.vcx,custom\swcde.vcx,custom\swdate.vcx,custom\swoldstuff.vcx,custom\basectrl.vcx,"
	cclasslibrarylist1 = "appdata,custom\swreports.vcx,custom\swregistry.vcx,custom\registry.vcx,custom\swemail.vcx,custom\swxfrx.vcx,custom\mwresize.vcx,..\..\3rdparty\ffc\_hyperlink.vcx,..\..\3rdparty\ffc\_reportlistener.vcx,..\..\3rdparty\ffc\_base.vcx,"
	cclasslibrarylist2 = ..\..\3rdparty\ffc\_gdiplus.vcx,custom\sfcommon.vcx,..\..\wconnect6\classes\wwxml.vcx,custom\capp.vcx,custom\sflogger.vcx,custom\vfpxworkbookxlsx.vcx,..\..\3rdparty\xfrx\xfrx_17_2\xfrx\xfrxlib\xfrxlib.vcx,
	cclasslibrarylist3 = ..\..\3rdparty\stonefield\sfcommon\sfmover.vcx,..\..\3rdparty\stonefield9\sdt\source\controls.vcx,custom\sfctrls.vcx,..\..\3rdparty\stonefield\sfcommon\sfbutton.vcx,..\..\3rdparty\ffc\_frxcursor.vcx,
	cclasslibrarylist4 = ..\..\3rdparty\stonefield\sfcommon\sfcollection.vcx,..\..\3rdparty\oopmenu-master\source\sfmenu.vcx,..\..\3rdparty\foxaudit6\foxaudit.vcx
	clocalizedlibrarylist = ""
	cprocedurelibrarylist = "cmutil.prg,commonsource\opencomp.prg,commonsource\lmlandpmts.prg,commonsource\calcdecl.prg,commonsource\calcdepl.prg,commonsource\calcsc29.prg,commonsource\calcytditd.prg,commonsource\dmrxprdcls.prg,custom\errorlog.prg,commonsource\chkdoi.prg,"
	cprocedurelibrarylist0 = ..\..\3rdparty\stonefield\sfreports\sfreports.prg,..\..\3rdparty\stonefield\sfquery\makeobject.prg,..\..\3rdparty\stonefield\sfquery\vartype.prg,commonsource\deletecomp.prg,commonsource\errorprint.prg,commonsource\checkdoi.prg,
	cprocedurelibrarylist1 = "commonsource\checkexp.prg,commonsource\calcroywrk.prg,commonsource\apaged.prg,commonsource\checkvoid.prg,commonsource\dmrwr99.prg,..\..\3rdparty\stonefield\sfcommon\fastdoevents.prg,custom\setstep.prg,commonsource\calcint.prg,commonsource\araged.prg,"
	cprocedurelibrarylist2 = "commonsource\closecomp.prg,commonsource\modirepo.prg,commonsource\fixroycomp.prg,..\..\3rdparty\stonefield\sfcommon\execscript.prg,commonsource\buildcheck.prg,commonsource\buildcheckv.prg,commonsource\arageddet.prg,commonsource\chkbal.prg,"
	cprocedurelibrarylist3 = ..\..\wconnect6\classes\wwutils.prg,..\..\wconnect6\classes\wwapi.prg,appmain.prg,commonsource\dupapstub.prg,commonsource\dupdmstub.prg,..\..\3rdparty\ffc\setobjrf.prg,custom\suspense.prg,custom\swregcode.prg,custom\swutils.prg,calccoaparent.prg,
	cprocedurelibrarylist4 = "custom\lanlimit.prg,custom\specialfolders.prg,custom\ctrlf12.prg,..\..\3rdparty\perflog\csnwperflog.prg,commonsource\meterprint.prg,custom\fixownpcts.prg,custom\swdist.prg,custom\swjib.prg,commonsource\afecalc.prg,custom\swbackup.prg,"
	cprocedurelibrarylist5 = "custom\swexternal.prg,prtaxtableupd.prg,custom\swpdf.prg,commonsource\picklist.prg,..\..\wconnect6\classes\wwsmtp.prg,..\..\wconnect6\classes\wwdotnetbridge.prg,..\..\wconnect6\classes\wwcollections.prg,"
	cprocedurelibrarylist6 = ..\..\3rdparty\cleverfox\classes\cleverfoxdevice.prg,..\..\3rdparty\cleverfox\classes\cleverfoxlog.prg,custom\swfile.prg,..\..\wconnect6\classes\wwftp.prg,..\..\3rdparty\cleverfox\classes\cleverfoxapi.prg,..\..\wconnect6\classes\wwhttp.prg,
	cprocedurelibrarylist7 = ..\..\wconnect6\classes\wwjsonserializer.prg,..\..\wconnect6\classes\wwregex.prg,custom\getvfpc32.prg,commonsource\form1099_upd.prg,check_w2_errors.prg,commonsource\formw2_upd.prg,custom\senderror.prg,commonsource\getstateformats.prg,
	cprocedurelibrarylist8 = "commonsource\form1065_k1_upd.prg,commonsource\ohsv3remove.prg,commonsource\modicheck.prg,commonsource\swdownload.prg,commonsource\getwvformats.prg,commonsource\check_1099_errors.prg,commonsource\getjson.prg,custom\gethelpfile.prg,"
	Name = "cmapplicationsettings"


ENDDEFINE
*
*-- EndDefine: appapplicationsettings
**************************************************

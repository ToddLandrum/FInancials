**************************************************
*-- Class Library:  c:\develop\_newversions\dmie\source\appmain.vcx
**************************************************


**************************************************
*-- Class:        appapplication (c:\develop\_newversions\dmie\source\appmain.vcx)
*-- ParentClass:  cmapplicationcustom (c:\develop\_newversions\dmie\custom\capp.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   10/19/21 04:29:02 PM
*
#INCLUDE "c:\develop\_newversions\dmie\source\appdefs.h"
*
DEFINE CLASS swappapplication AS swapplicationcustom


	Height = 33
	Width = 104
	*-- Address line 1 of the currently open company.
	caddress1 = "''"
	*-- Address line2 of the currently open company.
	caddress2 = "''"
	*-- Address line 3 of the currently open company.
	caddress3 = "''"
	*-- Tax ID of the currently open company
	ctaxid = "''"
	*-- Contact name for the currently open company
	ccontact = "''"
	*-- Registration Code
	cregcode = 9212-1630-9640-6011-4304
	ccity = "''"
	cstate = "''"
	czip = "''"
	cfileversion = "3.4.8"
	*-- Starter, Basic or Unlimited
	capplevel = "Unlimited"
	lsendtoallocate = .F.
	llandpriv = .F.
	lrevdistpriv = .F.
	brinepro = .F.
	lgraphingopt = .F.
	lpdfopt = .F.
	lqbinstalled = .F.
	cregcompany = ""
	cphoneno = "''"
	lqbversion = .T.
	oqb = .F.
	cdatafilepath = ""
	ccompanyname = "''"
	cuser = "''"
	ladmin = .F.
	lafedata = .F.
	lafereports = .F.
	llanddata = .F.
	llandreports = .F.
	lcheckprinting = .F.
	lrevdistdata = .F.
	lrevdistreports = .F.
	ljibdata = .F.
	ljibreports = .F.
	linvestdata = .F.
	linvestreports = .F.
	lreportmenu = .F.
	lhousegasdata = .F.
	lhousegasreports = .F.
	lpartnerdata = .F.
	lpartnerreports = .F.
	ldoidata = .F.
	lreadonly = .F.
	lnosecurity = .F.
	cmenu = "appMenu.mpr"
	ctoolbars = "tbrMainToolbar"
	csplash = "frmAppSplashScreen"
	cfillbitmap = ""
	cbanner = "D:\Dropbox\Develop\Codeminenew\DMIE_RV\GRAPHICS\sherware.png"
	cicon = "D:\Dropbox\Develop\Codeminenew\DMIE_RV\GRAPHICS\dmie.ico"
	lautoyield = .T.
	nproduct = 21
	cdemocode = 1312-1780-8502-1122-8005   
	cproductname = "DMIE"
	cdatabaseversion = "4.0.0"
	helpfilename = "DMIE.CHM"
	helpfiledate = {^2015/05/22}
	formicon = " D:\Dropbox\Develop\Codeminenew\DMIE_RV\GRAPHICS\dmie.ico"
	cfullversion = "3.4.8"
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

	*-- .T. if the data files should be audited using FoxAudit
	laudit = .F.
	lsepjibclose = .F.

	*-- Brine Hauler Option
	lbrineopt = .F.
	cagentname = .F.

	*-- .T. if keyexcel.scx exists
	lkeystone = .F.

	*-- OK Tax form is present.
	loktax = .F.

	*-- Codes from the xflag field in compmast.
	xflag = .F.

	*-- G/L Privilege
	lglpriv = .F.

	*-- A/P Privilege
	lappriv = .F.

	*-- A/R Privilege
	larpriv = .F.
	lafepriv = .F.
	ladminpriv = .F.

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
	lqbactive = .F.
	lhousegasopt = .F.

	*-- Set when an OLE error occurs
	lqberror = .F.

	*-- The major version of quickbooks.
	qbversion = .F.

	*-- Program Option
	lprogopt = .F.

	*-- What version of the SDK can be used on the open QuickBooks file.
	sdkversion = .F.

	*-- Allow direct deposit on revenue dist checks
	ldirdmdep = .F.
	lreports = .F.
	lreportpriv = .F.
	lsdk5 = .F.

	*-- Version of QBFC installed
	qbfcversion = .F.
	csdkversion = .F.
	cqbfcversion = .F.

	*-- State Codes Array
	DIMENSION lastates[1]

	*-- Months Array
	DIMENSION lamonths[1]


	*-- Handles QuickBooks Errors
	PROCEDURE qberror
		LPARAMETERS tnerror, tcmessage, tnlineno

		=AERROR(aErrInfo)

		messagebox(aErrInfo[1,3],0,'QuickBooks Error')

		this.lQBError = .T.
	ENDPROC


	PROCEDURE set_patch_registry
		*
		*  Double-check to make sure the registry keys needed for
		*  Auto-RTPatch exist
		*
		*  Also sets the registry key version to be the current version of the software, so the
		*  auto updates can work properly
		*

		RETURN
		LOCAL lcValue
		lcValue = ''

		IF NOT cmRegGetValue(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}',@lcValue)

		   *  Key doesn't exist, so create it

		   cmRegSetString(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}\Company','SherWare, Inc.')

		   cmRegSetString(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}\Description','Disbursement Manager Pro 2004')

		   cmRegSetString(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}\Last Result','')

		   cmRegSetString(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}\Name','Disbursement Manager Pro 2004')

		   cmRegSetString(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}\URL','http://www.sherware.com/patches')

		   cmRegSetString(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}\Version',ALLT(lcVersion+VERSION_SUB))

		   cmRegSetInteger(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}\Schedule',1573120)

		ELSE  &&  Key exists, but plug in the current version and next update

		   cmRegSetString(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}\Version',ALLT(lcVersion+VERSION_SUB))

		   cmRegSetInteger(HKEY_LOCAL_MACHINE,'Software\PocketSoft\RTPatch\AutoRTPatch'  ;
		      + '\Client\{AD12E7AA-1FEA-4A61-B73F-7B906BC04300}\Schedule',1573120)

		ENDIF
	ENDPROC


	PROCEDURE addrevcat
		**  Scan the current revcat table, and add any missing categories **
		LOCAL lnCount, lnRecNo, llFound
		LOCAL llReturn, loError
		*:Global cRevDesc, cRevType

		llReturn = .T.

		TRY
		   SET DELETED OFF
		   SET ORDER TO 0
		   swselect('revcat')
		   COUNT FOR NOT DELETED() TO lnCount

		   IF lnCount <> 20  &&  Not the maximum that there should be, so check to see what's missing

		      llFound = .F.  &&  Variable for determining whether the specified category is found
		      SCAN FOR ALLTRIM(cRevType) = 'BBL'
		         llFound = .T.
		      ENDSCAN
		      IF NOT llFound
		         m.cRevType = 'BBL'
		         m.cRevDesc = 'Oil Income'
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
		         m.cRevDesc = 'Gas Income'
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
		         m.cRevDesc = 'Transp Income'
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
		   DO errorlog WITH 'AddRevCat', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
		ENDTRY

		RETURN llReturn
	ENDPROC


	PROCEDURE fixswqbaddress
		LOCAL lovendorquery AS "qbfc7.ivendorquery"
		LOCAL lovendormod   AS "qbfc7.ivendormod"
		LOCAL lActive, llError, lni, lnvendor, loError, lorequest, loresponse, lovend, lovendresp, lsend1099

		TRY

		    THIS.oQB.oqbsm.EnableErrorRecovery = .F.

		* get a message set request object (version 1.1 xml)
		    lorequest = THIS.oQB.oqbrequest

		* set the on error attribute for the request
		    lorequest.ATTRIBUTES.OnError = 1

		    lorequest.ClearRequests()

		* add a vendor query request to request message set
		    lovendorquery = lorequest.appendvendorqueryrq()

		    lovendorquery.ORVendorListQuery.VendorListFilter.ORNameFilter.NameFilter.NAME.SetValue('SherWare')
		    lovendorquery.ORVendorListQuery.VendorListFilter.ORNameFilter.NameFilter.MatchCriterion.SetValue(1)
		    lovendorquery.ORVendorListQuery.VendorListFilter.ActiveStatus.SetValue(2)


		* Add vendors from QuickBooks to vendor table if they don't already exist
		    loresponse = THIS.oQB.oqbsm.dorequests(lorequest)
		    lovendresp = loresponse.responselist.getat(0)

		    IF lovendresp.statuscode = 0
		        lnvendor = 0

		* get reference to single vendor
		        lovend = lovendresp.DETAIL.getat(0)

		* get the value of each of the fields
		        m.cListID  = lovend.listid.getvalue()
		        IF VARTYPE(lovend.editsequence) = 'O'
		            m.ceditseq = lovend.editsequence.getvalue()
		        ELSE
		            m.ceditseq = ' '
		        ENDIF

		        IF VARTYPE(lovend.isactive) = 'O'
		            m.lActive = lovend.isactive.getvalue()
		        ELSE
		            m.lActive = .T.
		        ENDIF
		        IF VARTYPE(lovend.NAME) = 'O'
		            m.cvendname  = lovend.NAME.getvalue()
		            m.csortfield = m.cvendname
		        ELSE
		            m.cvendname  = 'Unknown'
		            m.csortfield = 'Unknown'
		        ENDIF
		        IF VARTYPE(lovend.contact) = 'O'
		            m.cbcontact = lovend.contact.getvalue()
		            m.ccontact  = m.cbcontact
		        ELSE
		            m.cbcontact = ''
		            m.ccontact  = ''
		        ENDIF
		        IF VARTYPE(lovend.phone) = 'O'
		            m.cbphone = lovend.phone.getvalue()
		            m.cphone  = m.cbphone
		        ELSE
		            m.cbphone = ''
		            m.cphone  = ''
		        ENDIF
		        IF VARTYPE(lovend.fax) = 'O'
		            m.cbfaxphone = lovend.fax.getvalue()
		            m.cfaxphone  = m.cbfaxphone
		        ELSE
		            m.cbfaxphone = ''
		            m.cfaxphone  = ''
		        ENDIF
		        IF VARTYPE(lovend.email) = 'O'
		            m.cemail = lovend.email.getvalue()
		        ELSE
		            m.cemail = ''
		        ENDIF
		        IF VARTYPE(lovend.vendoraddress) = 'O'
		            IF VARTYPE(lovend.vendoraddress.addr1) = 'O'
		                m.cbaddr1 = lovend.vendoraddress.addr1.getvalue()
		            ELSE
		                m.cbaddr1 = ''
		            ENDIF
		            IF VARTYPE(lovend.vendoraddress.addr2) = 'O'
		                m.cbaddr2 = lovend.vendoraddress.addr2.getvalue()
		            ELSE
		                m.cbaddr2 = ''
		            ENDIF
		            IF VARTYPE(lovend.vendoraddress.city) = 'O'
		                m.cbcity = lovend.vendoraddress.city.getvalue()
		            ELSE
		                m.cbcity = ''
		            ENDIF
		            IF VARTYPE(lovend.vendoraddress.state) = 'O'
		                m.cbstate = lovend.vendoraddress.state.getvalue()
		            ELSE
		                m.cbstate = ''
		            ENDIF
		            IF VARTYPE(lovend.vendoraddress.postalcode) = 'O'
		                m.cbzip = lovend.vendoraddress.postalcode.getvalue()
		            ELSE
		                m.cbzip = ''
		            ENDIF
		        ELSE
		            STORE '' TO m.cbaddr1, m.cbaddr2, m.cbcity, m.cbstate, m.cbzip
		        ENDIF

		        IF ('209' $ cbaddr1 OR '3540' $ cbaddr1 OR ;
		               '209' $ cbaddr2 OR '3540' $ cbaddr2 OR ;
		               '209' $ caddress1 OR '3540' $ caddress1 OR ;
		               '209' $ caddress2 OR '3540' $ caddress2 ) ;
		               AND NOT FILE('datafiles\noaskvend.txt')
		*!*	                IF MESSAGEBOX('The vendor record for SherWare currently has an old address.' + CHR(10) + ;
		*!*	                              'The new address is 4182 Clemmons Rd. #285, Clemmons, NC 27012' + CHR(10) + ;
		*!*	                'Do you want to update to the new address?', 36, 'SherWare Address') = 6
		                lorequest.ClearRequests()

		                lovendormod = lorequest.appendvendormodrq()
		                lovendormod.listid.SetValue(m.cListID)
		                lovendormod.editsequence.SetValue(m.ceditseq)
		                lovendormod.vendoraddress.addr1.SetValue('SherWare, Inc.')
		                lovendormod.vendoraddress.addr2.SetValue('4182 Clemmons Rd. #285')
		                lovendormod.vendoraddress.Addr3.SetValue(' ')
		                lovendormod.vendoraddress.addr4.SetValue(' ')
		                lovendormod.vendoraddress.Addr5.SetValue(' ')
		                lovendormod.email.SetValue('support@sherware.com')
		                lovendormod.phone.SetValue('330-262-0200')
		                lovendormod.fax.SetValue('866-338-1254')
		                lovendormod.vendoraddress.city.SetValue('Clemmons')
		                lovendormod.vendoraddress.state.SetValue('NC')
		                lovendormod.vendoraddress.postalcode.SetValue('27012')

		                loresponse = THIS.oQB.oqbsm.dorequests(lorequest)
		                lovendresp = loresponse.responselist.getat(0)

		                IF lovendresp.statuscode = 0
		* Nothing
		                ENDIF
		            ENDIF
		            lorequest.ClearRequests()
		            STRTOFILE('No', 'datafiles\noaskvend.txt', 0)
		        ENDIF
		    THIS.oQB.oqbsm.EnableErrorRecovery = .T.
		CATCH TO loError
		    llError = .T.
		ENDTRY

		TRY
		    lorequest.ClearRequests()
		CATCH
		ENDTRY
	ENDPROC


	PROCEDURE oqb_access
		*To do: Modify this routine for the Access method
		IF VARTYPE(THIS.oQB) # 'O'
		    IF NOT 'swqb' $ LOWER(SET('procedure'))
		        SET PROCEDURE TO CUSTOM\swqb.prg ADDITIVE
		    ENDIF
		    THIS.oQB = CREATEOBJECT("qbutils")
		ENDIF

		RETURN THIS.oqb
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


	PROCEDURE beforecreateglobalobjects
		LOCAL llSuccess

		llSuccess = DODEFAULT()
		* Create the QB utils object
		IF NOT 'swqb' $ LOWER(SET('procedure'))
		  SET PROCEDURE TO CUSTOM\swqb.prg ADDITIVE
		ENDIF
		this.oQB = createobject('qbutils')

		RETURN (llSuccess)
	ENDPROC


	PROCEDURE aftercreateglobalobjects
		LOCAL llreturn, loError
		DODEFAULT()

		llreturn = .T.

		TRY
		   IF NOT VERSION(2) = 0   && Running as a stand-alone exe
		      IF m.goapp.lOpenCompany
		         SWSELECT('glopt')
		         GO TOP
		         IF NOT THIS.oqb.lqbactive AND 'qbw' $ LOWER(cqbfilename) AND NOT THIS.lqberror
		            IF THIS.omessage.CONFIRM('Do you want to connect with QB now?')
		               THIS.cqbcompany = ALLTRIM(glopt.cqbfilename)
		               THIS.oqb.qbconnection()
		               THIS.lqbactive = THIS.oqb.lqbactive
		            ENDIF
		         ENDIF
		      ENDIF
		   ENDIF
		CATCH TO loError
		   llreturn = .F.
		   DO errorlog WITH 'AfterCreateGlobalObjects', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
		   MESSAGEBOX('Unable to start the application at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
		        'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
		ENDTRY

		RETURN llreturn


		 
	ENDPROC


	PROCEDURE beforeshutdown
		*  Close the QuickBooks connection
		this.oQB.QBClose()

		DODEFAULT()
	ENDPROC


	PROCEDURE removeblanks

		FOR lnX = 1 TO 10  &&  Scan through the various datasessions, closing these tables to avoid errors
		   SET DATASESSION TO lnX  &&  Error 1540 gets trapped and returns nothing
		   IF USED('wells')
		      USE IN wells
		   ENDIF
		   IF USED('investor')
		      USE IN investor
		   ENDIF
		   IF USED('vendor')
		      USE IN vendor
		   ENDIF
		   IF USED('expcat')
		      USE IN expcat
		   ENDIF
		   IF USED('revsrc')
		      USE IN revsrc
		   ENDIF
		   IF USED('emps')
		      USE IN emps
		   ENDIF
		   IF USED('coa')
		      USE IN coa
		   ENDIF
		   IF USED('custs')
		      USE IN custs
		   ENDIF
		   IF USED('appurchh')
		      USE IN appurchh
		   ENDIF
		   IF USED('csrcthdr')
		      USE IN csrcthdr
		   ENDIF
		   IF USED('csdishdr')
		      USE IN csdishdr
		   ENDIF
		ENDFOR

		DODEFAULT()
	ENDPROC


	PROCEDURE custommethods
		LOCAL lcpath, llfound
		LOCAL lcListId, llQBError, llreturn, lnetdef, lnwells, loError
		*:Global cdesc, cgroup, tlNewCompany, tlUpdateFiles

		llreturn = .T.

		DODEFAULT()

		TRY

		   lcpath = THIS.cdatafilepath

		   tlNewCompany  = THIS.lNewCompany
		   tlUpdateFiles = THIS.lupdatefiles

		*  Option to send all revenue and expenses to allocation files
		   IF NOT USED('options')
		      USE options IN 0
		   ENDIF
		   SELE options
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
		   IF NOT USED('groups')
		      USE groups IN 0
		   ENDIF
		   SELE groups
		   SET DELE OFF
		   llfound = .F.
		   SCAN FOR cgroup == '00'
		      llfound = .T.
		      EXIT
		   ENDSCAN
		   IF DELETED()
		      RECALL
		   ENDIF
		   IF NOT llfound
		      m.cgroup  = '00'
		      m.cdesc   = 'Default Group'
		      m.lnetdef = .T.
		      INSERT INTO groups FROM MEMVAR
		   ENDIF

		   THIS.AddRevCat()  &&  Add any missing revenue categories

		   SET DELE ON
		*
		*  Check to see how many wells are defined do see if we're in compliance
		*
		   IF THIS.capplevel <> 'Unlimited'
		      lnwells = 0
		      SWSELECT('wells')
		      COUNT FOR NOT DELETED() AND cwellstat <> 'U' TO lnwells
		      IF THIS.capplevel = 'Basic' AND lnwells > 20
		         MESSAGEBOX('More than 20 wells were found in the well master file. ' + CHR(10) + ;
		              'This is a basic system. 20 wells is the maximum. ' + CHR(10) + ;
		              'You will not be able to process revenue or JIBs until you upgrade to the next level.', 0, 'Compliance Problem')
		      ENDIF
		   ENDIF

		   IF THIS.lopencompany
		      SWSELECT('glopt')
		      GO TOP
		      THIS.cQBCompany = ALLT(cqbfilename)

		      IF NOT tlNewCompany AND NOT tlUpdateFiles
		         IF NOT THIS.oqb.lqbactive
		            llQBError      = THIS.oqb.QBConnection()
		            THIS.lQBError  = NOT llQBError
		            THIS.lqbactive = THIS.oqb.lqbactive
		            IF THIS.lqbactive
		               THIS.oqb.Error_Recovery()
		            ENDIF
		         ENDIF
		      ENDIF
		   ENDIF

		* Set the default A/P account in appurchh
		   SWSELECT('apopt')
		   lcListId = capacct
		   IF NOT EMPTY(lcListId)
		      SWSELECT('appurchh')
		      SCAN FOR EMPTY(capacct)
		         REPLACE capacct WITH lcListId
		      ENDSCAN
		   ENDIF

		* Set all QBPost records as having been posted initially.
		   IF NOT FILE(m.goapp.cCommonFolder + 'qbpost.cfg')
		      SWSELECT('qbpost')
		      REPLACE lposted WITH .T. ALL
		      FCREATE(m.goapp.cCommonFolder + 'qbpost.cfg')
		   ENDIF

		   IF THIS.lqbactive
		      THIS.fixSWQBAddress()
		   ENDIF
		CATCH TO loError
		   llreturn = .F.
		   DO errorlog WITH 'CustomMethods', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE
		ENDTRY

		RETURN llreturn
	ENDPROC


	PROCEDURE openerror
	ENDPROC


	*-- Set up the QuickBooks Connection
	PROCEDURE qbconnection
	ENDPROC


	*-- Close the QuickBooks Connection
	PROCEDURE qbclose
	ENDPROC


	*-- Perform the QuickBooks lookup for the chart of accounts.
	PROCEDURE coalookup
	ENDPROC


	*-- Emails the errorlog table to SherWare
	PROCEDURE senderrorfile
	ENDPROC


	*-- Query the QB list files for a given listid.
	PROCEDURE qbentityquery
	ENDPROC


	*-- Build cursor of QB items
	PROCEDURE itemlookup
	ENDPROC


	*-- Check to make sure all specifed QuickBooks accounts still exist in QuickBooks.
	PROCEDURE qbacctcheck
	ENDPROC


	PROCEDURE qbversionchk
	ENDPROC


	PROCEDURE fixcounters
	ENDPROC


	PROCEDURE process_xflags
	ENDPROC


ENDDEFINE
*
*-- EndDefine: appapplication
**************************************************


**************************************************
*-- Class:        appapplicationsettings (c:\develop\_newversions\dmie\source\appmain.vcx)
*-- ParentClass:  cmapplicationsettings (c:\develop\_newversions\ampro_rv\common\cmapp.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   01/08/19 05:54:02 PM
*
DEFINE CLASS appapplicationsettings AS cmapplicationsettings


	cdevelopertoolbarclass = "tbrDevelopmentToolbarCustom"
	cproject = "dmie.pjx"
	cglobalobjectlist = "cmSecurity"
	lupdateproc = .T.
	lupdateclass = .T.
	lupdatelocalized = .T.
	cclasslibrarylist = ""
	cclasslibrarylist0 = ""
	cclasslibrarylist1 = ""
	cclasslibrarylist2 = ""
	cclasslibrarylist3 = ""
	cclasslibrarylist4 = ""
	cclasslibrarylist5 = ""
	cclasslibrarylist6 = ""
	clocalizedlibrarylist = ""
	cprocedurelibrarylist = ""
	cprocedurelibrarylist0 = ""
	cprocedurelibrarylist1 = ""
	cprocedurelibrarylist2 = ""
	cprocedurelibrarylist3 = ""
	cprocedurelibrarylist4 = ""
	cprocedurelibrarylist5 = ""
	cprocedurelibrarylist6 = ""
	cprocedurelibrarylist7 = ""
	cprocedurelibrarylist8 = ""
	Name = "cmapplicationsettings"


ENDDEFINE
*
*-- EndDefine: appapplicationsettings
**************************************************

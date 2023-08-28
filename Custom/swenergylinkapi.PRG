************************************************************
* SWEnergyLinkAPI
* Wrapper VFP class around custom SWEnergyLinkAPI .NET DLL.
************************************************************



************************************************************
* SWEnergyLinkAPI Class
************************************************************
DEFINE CLASS SWEnergyLinkAPI AS Custom
	* Settings that should not change
	cDLL = "SWEnergyLinkAPI.dll"						&& Path and Name of the SWEnergyLinkAPI DLL.
	cDLLAPI = "SWEnergyLinkAPIDLL.SWEnergyLinkAPI"		&& Full namespace and class name of the API class that lives in the SWEnergyLinkAPI dll.
	* Variables
	cErrorMsg = ""										&& Stores latest error message.
	lSetupOK = .F.										&& Will be set to .T. if the Setup method completes successfully.
	* Object references	
	oSetup = NULL										&& Object reference to setup parameters
	oBridge = NULL										&& Object reference to wwDotNetBridge Instance.
	oAPI = NULL											&& Object reference to SWEnergyLinkAPI API class which contains all the necessary functionality we need.
	nDataSession = null 

	* Init & Destroy - simply redirect to custom methods
	**********************************
	FUNCTION Init(toSetup)
	**********************************
		* Store setup for later
		THIS.oSetup = m.toSetup
		* Flag success or failure, but always return .T. in this method so the object stays in scope, otherwise won't be able to retrieve any error information.
		THIS.lSetupOK = THIS.Setup()
	ENDFUNC
	
	**********************************
	FUNCTION Destroy()
	**********************************
		THIS.Cleanup()
	ENDFUNC

	* Returns .T. if string is empty ( handles null values as well )
	**********************************
	FUNCTION EmptyString(tcVal)
	**********************************
		IF ISNULL(m.tcVal)
			RETURN .T.
		ENDIF
		IF VARTYPE(m.tcVal) <> "C"
			RETURN .T.
		ENDIF	
		RETURN EMPTY(ALLTRIM(m.tcVal))
	ENDFUNC
	
	* Returns .T. if number is >= Min # ( handles null values and non numeric types as well )
	**********************************
	FUNCTION GrEqMinNum(tnVal, tnMin)
	**********************************
		IF ISNULL(m.tnVal)
			RETURN .F.
		ENDIF
		IF VARTYPE(m.tnVal) <> "N"
			RETURN .F.
		ENDIF
		RETURN m.tnVal >= m.tnMin
	ENDFUNC
		

	* Validate Setup
	**********************************
	FUNCTION ValidateSetup()
	**********************************
		* Setup must be an object
		IF ISNULL(THIS.oSetup)
			THIS.SetErrorMessage("Setup object is NULL!")
			RETURN .F.
		ENDIF
		****************************
		* Check required properties*
		****************************

		* UserName *
		IF THIS.EmptyString(THIS.oSetup.cUserName)
			THIS.SetErrorMessage("Setup UserName cannot be empty!")
			RETURN .F.
		ENDIF
		* Password *
		IF THIS.EmptyString(THIS.oSetup.cPassword)
			THIS.SetErrorMessage("Setup Password cannot be empty!")
			RETURN .F.
		ENDIF
	ENDFUNC

	* Setup - Called when class is instantiated
	**********************************
	FUNCTION Setup()
	**********************************
		LOCAL loSetupAPI, loEx, llFail

		* Setup must be valid
		IF !THIS.ValidateSetup()
			RETURN .F.
		ENDIF

		* Declare Sleep
		DECLARE Sleep IN WIN32API INTEGER

		* Attempt all setup steps for DLL interaction
		TRY
		   SET PROCEDURE TO m.goapp.cCommonFolder+'\bin\wwDotNetBridge' ADDITIVE
*!*	***		   
*!*			   IF !FILE("wwdotnetbridge.dll") OR !FILE("wwipstuff.dll")
*!*	  MessageBox("ERROR: wwdotnetbridge.dll or wwipstuff.dll not found.")
*!*	  RETURN
*!*	ENDIF

*!*	DO wwDotnetBridge
*!*	loBridge = GetwwDotnetBridge()
*!*	MESSAGEBOX(loBridge.GetDotnetVersion(),48,'Dot Net Version')
******
			* Load library and initialize wwDotnetBridge
			IF !m.llFail
				DO wwDotNetBridge
			ENDIF

			* Load DotNetBridge using CLR V4 **
			IF !m.llFail
				THIS.oBridge = CREATEOBJ("wwDotNetBridge","V4")
				IF VARTYPE(THIS.oBridge) <> "O"
					THIS.SetErrorMessage("Failed to load wwDotNetBridge!")
					llFail = .T.
				ENDIF
			ENDIF

			* Load DLL .NET assembly from disk
			IF !m.llFail
				IF !THIS.oBridge.LoadAssembly(THIS.cDLL)
					THIS.SetErrorMessage(THIS.oBridge.cErrorMsg)
					llFail = .T.
				ENDIF
			ENDIF

			* Create an instance of the DLL .NET class. 
			* NOTE: No COM registration is required for the .NET DLL
			IF !m.llFail
				THIS.oAPI = THIS.oBridge.CreateInstance(THIS.cDLLAPI)
				IF THIS.oBridge.lError
					THIS.SetErrorMessage("CreateInstance Failed for DLL: " + ;
					                      THIS.cDLLAPI + CHR(13)+CHR(10) + ;
					                      "Reason: " + THIS.oBridge.cErrorMsg)
					llFail = .T.
				ENDIF
			ENDIF

			* Extra check for oAPI to be valid
			IF !m.llFail			
				IF VARTYPE(THIS.oAPI) <> "O"
					THIS.SetErrorMessage("CreateInstance failed to create oAPI as an object!")
					llFail = .T.
				ENDIF
			ENDIF

			* Setup the DLL API by first creating setup api object
			IF !m.llFail			
				loSetupAPI = THIS.oAPI.GetNewSetupAPI()
				IF VARTYPE(m.loSetupAPI) <> "O"
					THIS.SetAPIErrorMessage("Failed to retrieve Setup API Object!")
					llFail = .T.
				ENDIF
			ENDIF
			
			* Populate .NET setup object with settings from VFP setup object
			IF !m.llFail
				WITH m.loSetupAPI
					.ServerType = IIF(THIS.oSetup.cServerType == "PRODUCTION", THIS.oAPI.GetServerEnvironmentProduction(), ;
								  IIF(THIS.oSetup.cServerType == "TEST", THIS.oAPI.GetServerEnvironmentTest(), ;
								  IIF(THIS.oSetup.cServerType == "DEMO", THIS.oAPI.GetServerEnvironmentDemo(), -1))) && pass -1 as the value if no valid choice set and call to setupdll will catch it.
					.UserName = THIS.oSetup.cUserName
					.Password = THIS.oSetup.cPassword
					.InvoiceVoucherDownloadFolder = THIS.oSetup.cInvoiceVoucherDownloadFolder
					.PaymentVoucherDownloadFolder = THIS.oSetup.cPaymentVoucherDownloadFolder
					.UploadFolder = THIS.oSetup.cUploadFolder
				ENDWITH

				* Create download directories if they don't exist
				IF !EMPTY(THIS.oSetup.cInvoiceVoucherDownloadFolder) AND !DIRECTORY(THIS.oSetup.cInvoiceVoucherDownloadFolder)
					MD (THIS.oSetup.cInvoiceVoucherDownloadFolder)
				ENDIF
				IF !EMPTY(THIS.oSetup.cPaymentVoucherDownloadFolder) AND !DIRECTORY(THIS.oSetup.cPaymentVoucherDownloadFolder)
					MD (THIS.oSetup.cPaymentVoucherDownloadFolder)
				ENDIF			
				IF !EMPTY(THIS.oSetup.cUploadFolder) AND !DIRECTORY(THIS.oSetup.cUploadFolder)
					MD (THIS.oSetup.cUploadFolder)
				ENDIF		

				* Setup DLL
				IF !THIS.oAPI.SetupDLL(m.loSetupAPI)
					THIS.SetAPIErrorMessage("SetupDLL call failed!")
					llFail = .T.
				ENDIF
			ENDIF
		CATCH TO loEx
			THIS.SetErrorMessage("Setup exception: " + m.loEx.Message)
			llFail = .T.
		ENDTRY
		RETURN !m.llFail
	ENDFUNC
	
	* Cleanup - Called when class destroy event occurs
	**********************************
	FUNCTION Cleanup()
	**********************************
		* Release references
		THIS.oBridge = NULL
		THIS.oAPI = NULL
		THIS.oSetup = NULL
	ENDFUNC

	* Set Error Message
	**********************************
	FUNCTION SetErrorMessage(tcMessage)
	**********************************
		THIS.cErrorMsg = m.tcMessage
	ENDFUNC

	* Set API Error Message - Wrapper to unify setting error messages from API calls.
	**********************************
	FUNCTION SetAPIErrorMessage(tcMessage)
	**********************************
		THIS.SetErrorMessage(TTOC(DATETIME()) + ": " + m.tcMessage + CHR(13) + CHR(10) + THIS.oAPI.GetErrorMsg())
	ENDFUNC

	** PRINT DLL INFO **
	**********************************
	FUNCTION PrintDLLInfo()
	**********************************
		* Retrieve DLL Info
		LOCAL loDLLInfo
		loDLLInfo = THIS.oAPI.GetDLLInfo()
		IF VARTYPE(m.loDLLInfo) <> "O"
			THIS.SetErrorMessage("Failed to retrieve DLL Info" + CHR(13) + CHR(10) + THIS.oAPI.GetErrorMsg())
			RETURN .F.
		ENDIF	
		?"DLL Info"
		?"--------"
		?"Assembly: " + m.loDLLInfo.AssemblyName
		?"Build Version (Assembly): " + m.loDLLInfo.VersionNum
		?"Build Version (File): " + m.loDLLInfo.FileVersionNum
		?"Build Version (Product): " + m.loDLLInfo.ProductVersionNum
		?"Build Date: " + m.loDLLInfo.BuildDate
		?"Build Type: " + m.loDLLInfo.BuildType
		?
	ENDFUNC	
	
	* Return Debugging message
	**********************************
	FUNCTION GetDebugMsg()
	**********************************
		LOCAL lcMsg
		lcMsg = NVL(THIS.oAPI.GetDebugMsg(),"")
		RETURN m.lcMsg
	ENDFUNC

	* Search for Invoices based on specified from date
	**********************************
	FUNCTION SearchJIB(tcAlias, ttFrom)
	**********************************
		LOCAL loSP, llFail, loEx, lnResults
		lnResults = -1
		* Validate From Date
		IF VARTYPE(m.ttFrom) <> "D"
			THIS.SetErrorMessage("Did not receive valid date in SearchJIB()")
			RETURN -1
		ENDIF
		TRY
			* Create search parms object
			IF !m.llFail			
				loSP = THIS.oAPI.GetNewSearchParmsJIB()
				IF VARTYPE(m.loSP) <> "O"
					THIS.SetAPIErrorMessage("Failed to retrieve SearchParmsJIB Object!")
					llFail = .T.
				ENDIF
			ENDIF
			* Setup search parm data
			IF !m.llFail
				loSP.From = m.ttFrom
			ENDIF
			* Perform search & store # of results
			IF !m.llFail
				lnResults = THIS.oAPI.SearchForJIBS(m.loSP)
				IF m.lnResults < 0
					THIS.SetAPIErrorMessage("SearchForJIBS returned an error!")
					llFail = .T.
				ELSE
					* If we got results retrieve results & populate the cursor
					IF m.lnResults > 0
						LOCAL loResults
						* Cannot call directly since it returns a .NET list, instead must use InvokeMethod.
						loResults = THIS.oBridge.InvokeMethod(THIS.oAPI,"GetSearchJIBSResults")
						IF VARTYPE(m.loResults) <> "O"
							THIS.SetAPIErrorMessage("Failed to retrieve Search JIB Results List")
							llFail = .T.
						ENDIF
						* Create cursor from list results
						IF !m.llFail
							THIS.SearchJIBResultsListToCursor(m.loResults, m.tcAlias)
							* Verify
							IF !(USED(m.tcAlias) AND RECCOUNT(m.tcAlias) > 0)
								THIS.SetErrorMessage("Failed to retrieve results cursor from call to SearchJIBResultsListToCursor()! " + THIS.cErrorMsg)
								llFail = .T.
							ENDIF
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		CATCH TO loEx
			THIS.SetErrorMessage("SearchJIB exception: " + m.loEx.Message)
			llFail = .T.
		ENDTRY
		* Return # of results or -1 for error
		RETURN IIF(m.llFail,-1, m.lnResults)
	ENDFUNC

	* Create cursor to hold SearchJIB results
	**********************************
	FUNCTION CreateJIBCursor(tcAlias)
	**********************************
		IF !(VARTYPE(m.tcAlias) = "C" AND LEN(ALLTRIM(m.tcAlias)) > 0)
			THIS.SetErrorMessage("No alias specified in call to CreateJIBCursor()")
			RETURN .F.
		ENDIF
		* Close if it's already opened
		USE IN SELECT(m.tcAlias)
		* Create it
		CREATE CURSOR (m.tcAlias) ;
		( ;
			tDownloaded 	T, ;
			lProcessed 		L, ;
			cInvoiceID		C(20), ;
			cOperNo 		C(20), ;
			cOperName 		C(60), ;
			cPropertyNo 	C(20), ;
			cWellID 		C(20), ;
			cPropertyDesc 	C(60), ;
			cOperAFENo 		C(20), ;
			cOwnerAFENo 	C(20), ;
			cAFEDesc 		C(60), ;
			cVenture 		C(20), ;
			cVentureDesc 	C(60), ;
			cOwnerName 		C(60), ;
			cOwnerNo 		C(20), ;
			cAcctMonth 		C(10), ;
			cDocType 		C(3), ;
			cInvNo 			C(20), ;
			cProdMonth 		C(10), ;
			nInterest 		N(13,8), ;
			cMajorDesc 		C(60), ;
			cMinorDesc 		C(60), ;
			cOperAcct 		C(20), ;
			cOwnerAcct 		C(20), ;
			nGrossInvAmt 	N(12,2), ;
			nOwnerAmt 		N(12,2), ;
			nCashCall 		N(12,2), ;
			nInvoiced 		N(12,2), ;
			nDisAmt 		N(12,2), ;
			nDisCashCall 	N(12,2), ;
			nDisInvoiced 	N(12,2), ;
			nAccAmt 		N(12,2), ;
			nAccCashCall 	N(12,2), ;
			nAccInvoiced 	N(12,2) ;
		)
		RETURN USED(m.tcAlias)
	ENDFUNC

	* Converts list of searchjib results records into cursor of specified alias
	* Assumes validations done by caller, don't call this method directly. Logs any exception error message.
	*************************************************************
	FUNCTION SearchJIBResultsListToCursor(m.toResults, m.tcAlias)
	*************************************************************
		LOCAL lnCount, lnLoop, loRecord, loArray
		* Create cursor to hold results
		IF !THIS.CreateJIBCursor(m.tcAlias)
			RETURN -1
		ENDIF		
		TRY
			* Create a ComArray instance and convert the IEnumerable to an array we can use in FoxPro
			loArray = THIS.oBridge.CreateArray()
			loArray.FromEnumerable(m.toResults)
			* Loop over records & insert into cursor
			lnCount = m.loArray.Count
			FOR lnLoop = 1 TO m.lnCount
				loRecord = m.loArray.Item[m.lnLoop-1]	&& -1 since list is 0 index based
				INSERT INTO (m.tcAlias) (;
					tDownloaded, ;
					lProcessed, ;
					cInvoiceID, ;
					cOperNo, ;
					cOperName, ;
					cPropertyNo, ;
					cWellID, ;
					cPropertyDesc, ;
					cOperAFENo, ;
					cOwnerAFENo, ;
					cAFEDesc, ;
					cVenture, ;
					cVentureDesc, ;
					cOwnerName, ;
					cOwnerNo, ;
					cAcctMonth, ;
					cDocType, ;
					cInvNo, ;
					cProdMonth, ;
					nInterest, ;
					cMajorDesc, ;
					cMinorDesc, ;
					cOperAcct, ;
					cOwnerAcct, ;
					nGrossInvAmt, ;
					nOwnerAmt, ;
					nCashCall, ;
					nInvoiced, ;
					nDisAmt, ;
					nDisCashCall, ;
					nDisInvoiced, ;
					nAccAmt, ;
					nAccCashCall, ;
					nAccInvoiced ;
				) ;
				VALUES ( ;
					NVL(m.loRecord.Downloaded,{//:}),;
					NVL(m.loRecord.Processed,.F.),;
					LEFT(NVL(m.loRecord.InvoiceID,""),254), ;
					LEFT(NVL(m.loRecord.OperNo,""),254), ;
					LEFT(NVL(m.loRecord.OperName,""),254),;
					LEFT(NVL(m.loRecord.PropertyNo,""),254),;
					LEFT(NVL(m.loRecord.WellID,""),254),;
					LEFT(NVL(m.loRecord.PropertyDesc,""),254),;
					LEFT(NVL(m.loRecord.OperAFENo,""),254),;
					LEFT(NVL(m.loRecord.OwnerAFENo,""),254),;
					LEFT(NVL(m.loRecord.AFEDesc,""),254),;
					LEFT(NVL(m.loRecord.Venture,""),254),;
					LEFT(NVL(m.loRecord.VentureDesc,""),254),;
					LEFT(NVL(m.loRecord.OwnerName,""),254),;
					LEFT(NVL(m.loRecord.OwnerNo,""),254),;
					LEFT(NVL(m.loRecord.AcctMonth,""),254),;
					LEFT(NVL(m.loRecord.DocType,""),254),;
					LEFT(NVL(m.loRecord.InvNo,""),254),;
					LEFT(NVL(m.loRecord.ProdMonth,""),254),;
					NVL(m.loRecord.Interest,0),;
					LEFT(NVL(m.loRecord.MajorDesc,""),254),;
					LEFT(NVL(m.loRecord.MinorDesc,""),254),;
					LEFT(NVL(m.loRecord.OperAcct,""),254),;
					LEFT(NVL(m.loRecord.OwnerAcct,""),254),;
					NVL(m.loRecord.GrossInvAmt,0),;
					NVL(m.loRecord.OwnerAmt,0),;
					NVL(m.loRecord.CashCall,0),;
					NVL(m.loRecord.Invoiced,0),;
					NVL(m.loRecord.DisAmt,0),;
					NVL(m.loRecord.DisCashCall,0),;
					NVL(m.loRecord.DisInvoiced,0),;
					NVL(m.loRecord.AccAmt,0),;
					NVL(m.loRecord.AccCashCall,0),;
					NVL(m.loRecord.AccInvoiced,0);
				)
			ENDFOR
		CATCH TO m.loEx
			THIS.SetErrorMessage(m.loEx.Message)
		ENDTRY
	ENDFUNC	

	* Search for Invoice Vouchers Ready for Download
	******************************************
	FUNCTION SearchForInvoiceVouchers(tcAlias)
	******************************************
		RETURN THIS.SearchForVouchers(m.tcAlias, .T.)
	ENDFUNC

	* Search for Payment Vouchers Ready for Download
	******************************************
	FUNCTION SearchForPaymentVouchers(tcAlias)
	******************************************
		RETURN THIS.SearchForVouchers(m.tcAlias, .F.)
	ENDFUNC	

	* Search for Vouchers - Common between Invoice & Payment types.
	* Returns # of results found or -1 if there was an error.
	* Creates cursor of the results data from .NET on success
	************************************************
	FUNCTION SearchForVouchers(tcAlias, tlIsInvoice)
	************************************************
		LOCAL lnResults, lcType, lcAPICall, loResults, loEx
		* Differentiate between 2 voucher types supported
		lcType    = IIF(tlIsInvoice,"Invoice", "Payment")
		lcAPICall = IIF(tlIsInvoice,"GetSearchInvoiceVoucherResults", "GetSearchPaymentVoucherResults")
		TRY
			* Call appropriate API
			IF m.tlIsInvoice
				lnResults = THIS.oAPI.SearchForInvoiceVouchers()
			ELSE
				lnResults = THIS.oAPI.SearchForPaymentVouchers()
			ENDIF
			* Retrieve results of search if we got any
			IF lnResults > 0
				* Retrieve the results data from .NET
				* NOTE: Must use InvokeMethod() to call the API function since it returns a .NET List<Voucher> that cannot be returned directly.
				loResults = THIS.oBridge.InvokeMethod(THIS.oAPI,m.lcAPICall)
				IF VARTYPE(m.loResults) <> "O"
					THIS.SetAPIErrorMessage("Failed to retrieve Voucher Results List from API call: " + m.lcAPICall)
					RETURN -1
				ENDIF
				* Convert entire result set into cursor
				IF !THIS.VoucherListToCursor(m.loResults, m.tcAlias)
					m.lnResults = -1
				ENDIF
				* Double validation for success - cursor must be open and have at least 1 record.
				IF !(USED(m.tcAlias) AND RECCOUNT(m.tcAlias) > 0)
					m.lnResults = -1
				ENDIF
			* No results - flag error
			ELSE
				THIS.SetAPIErrorMessage("Search for " + m.lcType + " Vouchers failed!")
			ENDIF
		CATCH TO loEx
			THIS.SetErrorMessage("Search for " + m.lcType + " Vouchers failed: " + loEx.Message)
			m.lnResults = -1
		ENDTRY
		RETURN m.lnResults	
	ENDFUNC

	* Download all vouchers using data from the cursor passed which must be first populated with a call to one of the SearchForVouchers() methods above.
	* Returns the # of vouchers downloaded or -1 if there was an error.
	**************************************************
	FUNCTION DownloadAllVouchers(tcAlias, tlIsInvoice)
	**************************************************
		LOCAL lnResults, lnVID_MSDW, lnVID_LSDW, lcFileName, lcErr, loEx, llOK
		IF !USED(m.tcAlias)
			THIS.SetErrorMessage("DownloadAllVouchers() - alias: " + TRANSFORM(m.tcAlias) + " was not open.")
			RETURN -1
		ENDIF
		lnResults = 0
		TRY
			SELECT(m.tcAlias)
			SCAN
				* Grab Vendor ID lower and upper 32 bits value
				lnVID_MSDW = EVAL(m.tcAlias+".VoucherId_MSDW")
				lnVID_LSDW = EVAL(m.tcAlias+".VoucherId_LSDW")
				* Grab File Name
				lcFileName = EVAL(m.tcAlias+".FileName")
				* Download Invoice or Payment Voucher
				IF m.tlIsInvoice
					* Perform download from API
					llOK = THIS.oAPI.GetInvoiceVoucher_32Bit(m.lnVID_MSDW, m.lnVID_LSDW, m.lcFileName)
				ELSE
					llOK = THIS.oAPI.GetPaymentVoucher_32Bit(m.lnVID_MSDW, m.lnVID_LSDW, m.lcFileName)
				ENDIF
				* Handle Success or Failure
				IF m.llOK
					* Update downloaded flag in cursor
					REPLACE downloaded WITH .T. IN (m.tcAlias)
					* Update downloaded count
					lnResults = m.lnResults + 1
				ELSE
					** Append error message for each file that fails
					lcErr = THIS.cErrorMsg
					lcErr = m.lcErr + "Failed to download file: " + m.lcFileName + ". Reason: " + THIS.oAPI.GetErrorMsg() + CHR(13) + CHR(10)
					THIS.SetErrorMessage(m.lcErr)
				ENDIF
			ENDSCAN
		CATCH TO loEx
			THIS.SetErrorMessage("Download All Vouchers failed: " + loEx.Message)
			m.lnResults = -1
		ENDTRY
		RETURN m.lnResults
	ENDFUNC

	* Download a single voucher file for given voucher id
	* Returns .T. on success, .F. on failure.
	*************************************************************************
	FUNCTION DownloadVoucher(tnVID_MSDW, tnVID_LSDW, tcFileName, tlIsInvoice)
	*************************************************************************
		LOCAL llOK, loEx
		TRY
			* Download Invoice or Payment Voucher
			IF m.tlIsInvoice
				* Perform download from API
				llOK = THIS.oAPI.GetInvoiceVoucher_32Bit(m.tnVID_MSDW, m.tnVID_LSDW, m.tcFileName)
			ELSE
				* Perform download from API			
				llOK =  THIS.oAPI.GetPaymentVoucher_32Bit(m.tnVID_MSDW, m.tnVID_LSDW, m.tcFileName)
			ENDIF
			* Handle failure
			IF !m.llOK
				THIS.SetAPIErrorMessage("Failed to download file: " + m.tcFileName + ". ")
			ENDIF			
		CATCH TO loEx
			THIS.SetErrorMessage("Download Voucher failed for: " + m.tcFileName + ", Reason: " + loEx.Message)
		ENDTRY
		RETURN m.llOK	
	ENDFUNC

	* Creates and populates a cursor of info about a single voucher file for given voucher id and alias
	********************************************************
	FUNCTION GetVoucherInfo(tnVID_MSDW, tnVID_LSDW, tcAlias)
	********************************************************
		LOCAL llOK, loRecord, loVoucher, loEx, lcErr
		TRY
			* Perform info retrieval from API
			loRecord = THIS.oAPI.GetVoucherInfo_32Bit(m.tnVID_MSDW, m.tnVID_LSDW)
			* Convert into VFP Object
			IF VARTYPE(loRecord) = 'O'
				loVoucher = THIS.VoucherToVFPObj(m.loRecord)
				* Convert into a new record in Results Cursor ( will create cursor if not opened already )
				lcErr = THIS.ObjToCursor(m.loVoucher, m.tcAlias)
				IF !EMPTY(m.lcErr)
					THIS.SetErrorMessage("Get Voucher Info failed: " + m.lcErr)
				ELSE
					llOK = .T.
					* Update downloaded flag
					IF !EMPTY(EVAL(m.tcAlias+".FirstDownloadedDate"))
						* Update downloaded flag in cursor
						REPLACE downloaded WITH .T. IN (m.tcAlias)				
					ENDIF
				ENDIF
			ELSE
			   EXIT
			ENDIF 	
		CATCH TO loEx
			THIS.SetErrorMessage("Get Voucher Info failed: " + loEx.Message)
		ENDTRY
		RETURN m.llOK	
	ENDFUNC

	* Upload a single JIB file of given file name for specified account month
	* Returns .T. on success, .F. on failure.
	* Creates cursor of the result data from .NET on success
	*************************************************************
	FUNCTION UploadJib(tcFileName, ttAccountMonth, tcAlias)
	*************************************************************
		RETURN THIS.UploadFile(m.tcFileName, m.ttAccountMonth, m.tcAlias, .T.)
	ENDFUNC

	* Upload a single Revenue file of given file name for specified account month
	* Returns .T. on success, .F. on failure.
	* Creates cursor of the result data from .NET on success
	*************************************************************
	FUNCTION UploadRevenue(tcFileName, ttAccountMonth, tcAlias)
	*************************************************************
		RETURN THIS.UploadFile(m.tcFileName, m.ttAccountMonth, m.tcAlias, .F.)
	ENDFUNC	

	* Upload a file of given file name and specified account month for either Jib or Revenue file.
	* Returns .T. on success, .F. on failure.
	* Creates cursor of the result data from .NET on success
	*************************************************************
	FUNCTION UploadFile(tcFileName, ttAccountMonth, tcAlias, tlIsJib)
	*************************************************************
		LOCAL loResult, loVFPRecord, llOK, loEx, lcErr
		TRY
			* Upload Jib or Revenue
			IF m.tlIsJib
				* Perform Upload from API
				loResult = THIS.oAPI.UploadJib(m.tcFileName, ttAccountMonth)
			ELSE
				* Perform Upload from API
				loResult = THIS.oAPI.UploadRevenue(m.tcFileName, ttAccountMonth)
			ENDIF
			* Handle Success
			IF VARTYPE(m.loResult) == "O"
				IF m.loResult.StatusCode == 200
					* Convert into VFP Object
					loVFPRecord = THIS.UploadToVFPObj(m.loResult)
					* Convert into a new record in Results Cursor ( will create cursor if not opened already )
					lcErr = THIS.ObjToCursor(m.loVFPRecord, m.tcAlias)
					IF !EMPTY(m.lcErr)
						THIS.SetErrorMessage("ObjToCursor() failed: " + m.lcErr)
					ENDIF
					* Double validation for success - cursor must be open and have at least 1 record.
					llOK = (USED(m.tcAlias) AND RECCOUNT(m.tcAlias) > 0)
					* Update uploaded flag
					IF m.llOK
						REPLACE uploaded with .T. IN (m.tcAlias)
					ENDIF
				ELSE
					THIS.SetErrorMessage("Failed to upload file: " + m.tcFileName + ", Reason: " + m.loResult.Message)
				ENDIF
			ENDIF
			* Handle failure
			IF !m.llOK
				IF EMPTY(THIS.cErrorMsg)
					THIS.SetAPIErrorMessage("Failed to upload file: " + m.tcFileName + ". ")
				ELSE
					THIS.SetAPIErrorMessage(THIS.cErrorMsg)
				ENDIF
			ENDIF			
		CATCH TO loEx
			THIS.SetErrorMessage("Upload File failed for: " + m.tcFileName + ", Reason: " + loEx.Message)
		ENDTRY
		RETURN m.llOK	
	ENDFUNC	

	* Converts array of changed carrier records into cursor of specified alias
	* Assumes validations done by caller, don't call this method directly. Logs any exception error message.
	* Returns .T. on success, .F. on error.
	*************************************************************
	FUNCTION VoucherListToCursor(m.toResults, m.tcAlias)
	*************************************************************
		LOCAL lnCount, lnLoop, loRecord, loVFPRecord, lcErr, llProb
		llProb = .F.
		
		TRY
			lnCount = m.toResults.Count
			FOR lnLoop = 1 TO m.lnCount
				* Grab .NET record from List of Results
				loRecord = m.toResults.Item[m.lnLoop-1]	&& -1 since list is 0 index based
				* Convert into VFP Object
				IF VARTYPE(loRecord) = 'O'
 					loVFPRecord = THIS.VoucherToVFPObj(m.loRecord)
					* Convert into a new record in Results Cursor ( will create cursor if not opened already )
					lcErr = THIS.ObjToCursor(m.loVFPRecord, m.tcAlias)
					IF !EMPTY(m.lcErr)
						llProb = .T.
						THIS.SetErrorMessage("ObjToCursor() failed: " + m.lcErr)
						EXIT
					ENDIF
				ELSE
				   EXIT
				ENDIF 	
			ENDFOR
		CATCH TO m.loEx
			llProb = .T.
			THIS.SetErrorMessage("VoucherListToCursor() failed: " + loEx.Message)
		ENDTRY
		RETURN !m.llProb
	ENDFUNC	

	* Given an object and cursor alias name, this function creates the cursor if cursor not already open and inserts a new record from all properties of the object.
	* Returns error message string on failure
	* NOTE: This function fails for object properties that are null.
	*************************************************************
	FUNCTION ObjToCursor(m.toObj, m.tcAlias)
	*************************************************************
		LOCAL laInfo[1], loEx
		LOCAL lnLoop, lcType, lcProp, lnNumFields, lcInsert, lcCreate, lcValues, lcErr
		* Clear out vars
		
		STORE "" TO m.lcInsert, m.lcValues, m.lcCreate, m.lcErr
		TRY 
			* Retrieve property names and build strings for use later
			AMEMBERS(laInfo, m.toObj)
			lnNumFields = ALEN(m.laInfo,1)
			FOR lnLoop = 1 TO m.lnNumFields
				lcProp = m.laInfo[m.lnLoop]
				* Must have valid property name
				IF VARTYPE(m.lcProp) = "C"
					lcType = VARTYPE(EVALUATE("m.toObj." + m.lcProp))
					IF m.lcType = "C"
						m.lcType = m.lcType + "(254)"	&& We'll use largest size for Char Field Type
					ENDIF
					IF m.lcType = 'N'
					   IF 'AMOUNT' $ UPPER(m.lcProp)
					      lcType = lcType + "(12,2)"
					   ENDIF 
					ENDIF 
					* Build comma delimited list of fields with their property type for create cursor
					lcCreate = m.lcCreate + m.lcProp + " " + m.lcType + ", "
					* Build comma delimited list of fields /  property names for insert
					lcInsert = lcInsert + m.lcProp + ", "
					* Build comma delimited list of values string for insert
					lcValues = m.lcValues + "m.toObj." + m.lcProp + ", "
				ELSE
					lcErr = "Invalid property retrieved from amembers. Object may be invalid or empty"
				ENDIF
			ENDFOR
		CATCH TO loEx
			lcErr = loEx.Message
		ENDTRY

		*** BUILD CREATE CURSOR STRING ***
		IF EMPTY(m.lcErr)	
			* Strip trailing space and comma
			IF !EMPTY(ALLTRIM(m.lcCreate))
				lcCreate = LEFT(m.lcCreate, LEN(m.lcCreate) - 2)
			ENDIF
			lcCreate = "CREATE CURSOR " + m.tcAlias + " (" + m.lcCreate + ")"
		ENDIF

		*** BUILD INSERT INTO STRING ***
		IF EMPTY(m.lcErr)
			* Strip trailing space and comma
			IF !EMPTY(ALLTRIM(m.lcInsert))
				lcInsert = LEFT(m.lcInsert, LEN(m.lcInsert) - 2)
			ENDIF
			IF !EMPTY(ALLTRIM(m.lcValues))
				lcValues = LEFT(m.lcValues, LEN(m.lcValues) - 2)
			ENDIF			
			lcInsert = "INSERT INTO " + m.tcAlias + " (" + m.lcInsert + ") VALUES (" + m.lcValues + ")"
			*?m.lcInsert
		ENDIF

		*** CREATE CURSOR ***
		IF EMPTY(m.lcErr)
			IF !(USED(m.tcAlias))
				TRY
					&lcCreate
				CATCH TO loEx
					lcErr = "Failed to create cursor: " + loEx.Message
				ENDTRY
			ENDIF
		ENDIF	

		*** INSERT INTO CURSOR ***
		IF EMPTY(m.lcErr)
			TRY
				&lcInsert
			CATCH TO loEx
				lcErr = "Failed to insert record: " + loEx.Message
			ENDTRY
		ENDIF
		RETURN lcErr
	ENDFUNC

	* Converts .NET Search Voucher Result object into a VFP object and returns it.
	* This is used so that the result can be explorable in the VFP Debug window as 
	* well as for use with ObjToCursor() to create a cursor of results
	*************************************************************
	FUNCTION VoucherToVFPObj(m.toVoucherInfo)
	*************************************************************
		LOCAL loV
		loV = CREATEOBJ("Empty")
		** VFP Only Properties ( added first so they appear in results cursor first )
		ADDPROPERTY(m.loV, "Searched",                    DATETIME())
		ADDPROPERTY(m.loV, "Downloaded",                  .F.)
		** .NET Properties from toVoucherInfo
		ADDPROPERTY(m.loV, "ActionTypeDescription",       NVL(toVoucherInfo.ActionTypeDescription,""))
		ADDPROPERTY(m.loV, "DocType",                     NVL(toVoucherInfo.DocType,""))
		ADDPROPERTY(m.loV, "FileExtension",               NVL(toVoucherInfo.FileExtension,""))
		ADDPROPERTY(m.loV, "FileName",                    NVL(toVoucherInfo.FileName,""))
		ADDPROPERTY(m.loV, "FileSize",                    NVL(toVoucherInfo.FileSize,0))
		ADDPROPERTY(m.loV, "FirstDownloadedDate",         NVL(toVoucherInfo.FirstDownloadedDate,{//}))
		*ADDPROPERTY(m.loV, "FirstDownloadedUserId",      toVoucherInfo.FirstDownloadedUserId)	&& 64-bit field see 32-bit version below
		ADDPROPERTY(m.loV, "FirstDownloadedUserName",     NVL(toVoucherInfo.FirstDownloadedUserName,""))
		ADDPROPERTY(m.loV, "FirstProcessedDate",          NVL(toVoucherInfo.FirstProcessedDate,{//}))
		*ADDPROPERTY(m.loV, "FirstProcessedUserId",       toVoucherInfo.FirstProcessedUserId)	&& 64-bit field see 32-bit version below
		ADDPROPERTY(m.loV, "FirstProcessedUserName",      NVL(toVoucherInfo.FirstProcessedUserName,""))
		ADDPROPERTY(m.loV, "LastDownloadedDate",          NVL(toVoucherInfo.LastDownloadedDate,{//}))
		*ADDPROPERTY(m.loV, "LastDownloadedUserId",       toVoucherInfo.LastDownloadedUserId)	&& 64-bit field see 32-bit version below
		ADDPROPERTY(m.loV, "LastDownloadedUserName",      NVL(toVoucherInfo.LastDownloadedUserName,""))
		ADDPROPERTY(m.loV, "LastProcessedDate",           NVL(toVoucherInfo.LastProcessedDate,{//}))
		*ADDPROPERTY(m.loV, "LastProcessedUserId",        toVoucherInfo.LastProcessedUserId)	&& 64-bit field see 32-bit version below
		ADDPROPERTY(m.loV, "LastProcessedUserName",       NVL(toVoucherInfo.LastProcessedUserName,""))
		ADDPROPERTY(m.loV, "VoucherAccountingMonth",      NVL(toVoucherInfo.VoucherAccountingMonth,{//}))
		ADDPROPERTY(m.loV, "VoucherAmount",               NVL(toVoucherInfo.VoucherAmount,0))
		*ADDPROPERTY(m.loV, "VoucherId",                  toVoucherInfo.VoucherId)				&& 64-bit field see 32-bit version below
		ADDPROPERTY(m.loV, "VoucherReference",            NVL(toVoucherInfo.VoucherReference,""))
		* 32-Bit properties that replace the 64-bit ones *
		ADDPROPERTY(m.loV, "FirstDownloadedUserId_MSDW",  NVL(toVoucherInfo.FirstDownloadedUserId_MSDW,0))
		ADDPROPERTY(m.loV, "FirstDownloadedUserId_LSDW",  NVL(toVoucherInfo.FirstDownloadedUserId_LSDW,0))
		ADDPROPERTY(m.loV, "FirstProcessedUserId_MSDW",   NVL(toVoucherInfo.FirstProcessedUserId_MSDW,0))
		ADDPROPERTY(m.loV, "FirstProcessedUserId_LSDW",   NVL(toVoucherInfo.FirstProcessedUserId_LSDW,0))
		ADDPROPERTY(m.loV, "LastDownloadedUserId_MSDW",   NVL(toVoucherInfo.LastDownloadedUserId_MSDW,0))
		ADDPROPERTY(m.loV, "LastDownloadedUserId_LSDW",   NVL(toVoucherInfo.LastDownloadedUserId_LSDW,0))
		ADDPROPERTY(m.loV, "LastProcessedUserId_MSDW",    NVL(toVoucherInfo.LastProcessedUserId_MSDW,0))
		ADDPROPERTY(m.loV, "LastProcessedUserId_LSDW",    NVL(toVoucherInfo.LastProcessedUserId_LSDW,0))
		ADDPROPERTY(m.loV, "VoucherId_MSDW",              NVL(toVoucherInfo.VoucherId_MSDW,0))
		ADDPROPERTY(m.loV, "VoucherId_LSDW",              NVL(toVoucherInfo.VoucherId_LSDW,0))
		RETURN m.loV
	ENDFUNC

	* Converts .NET Upload Result object into a VFP object and returns it.
	* This is used so that the result can be explorable in the VFP Debug 
	*  window as well as for use with ObjToCursor() to create a cursor of results
	*************************************************************
	FUNCTION UploadToVFPObj(m.toUpload)
	*************************************************************
		LOCAL loU
		loU = CREATEOBJ("Empty")
		** VFP Only Properties ( added first so they appear in results cursor first )
		ADDPROPERTY(m.loU, "Submitted",      DATETIME())
		ADDPROPERTY(m.loU, "Uploaded",       .F.)
		** .NET Properties from toUpload
		ADDPROPERTY(m.loU, "StatusCode",     NVL(toUpload.StatusCode,""))
		ADDPROPERTY(m.loU, "Message",        NVL(toUpload.Message,""))
		*ADDPROPERTY(m.loU, "ProcessId",     NVL(toUpload.ProcessId,""))	&& 64-bit field see 32-bit version below
		*ADDPROPERTY(m.loU, "BatchId",       NVL(toUpload.BatchId,""))		&& 64-bit field see 32-bit version below
		* 32-Bit properties that replace the 64-bit ones *
		ADDPROPERTY(m.loU, "ProcessId_MSDW", NVL(toUpload.ProcessId_MSDW,0))
		ADDPROPERTY(m.loU, "ProcessId_LSDW", NVL(toUpload.ProcessId_LSDW,0))
		ADDPROPERTY(m.loU, "BatchId_MSDW",   NVL(toUpload.BatchId_MSDW,0))
		ADDPROPERTY(m.loU, "BatchId_LSDW",   NVL(toUpload.BatchId_LSDW,0))
		RETURN m.loU
	ENDFUNC	

ENDDEFINE
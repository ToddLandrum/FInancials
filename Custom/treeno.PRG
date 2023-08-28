
******************************************************************
*  CLASS: TreenoSoftware 
*   
*  AUTHOR, DATE:
*     Paul Mrozowski, 10/24/2012  
*  DESCRIPTION:
*     Communicates with Treeno web service and website
*  DEPENDENCIES:
*     PRGS:
*        wwHTTP 
*        wwUtils 
*        wwAPI 
*        wwSOAP 
*        wwDotNetBridge
*     Classes:
*        wwXML 
*     DLLs:
*        ClrHost.DLL - wwDotNetBridge
*        wwDotNetBridge.DLL - wwDotNetBridge
*        Sherware.Treeno.DLL
******************************************************************
DEFINE CLASS TreenoSoftware AS Custom
   cServer = "http://ws.treenosoftware.com"
   cLoginUrl = "http://tr1.treenosoftware.com/Login/Login.aspx"

   oSOAP = NULL
   lError = .F.
   cErrorMsg = ""
   cDepartment = "client_files630"
   cPassKey = ""   
   oMatches = NULL

   ******************************************************************
   *  FUNCTION NAME: Init
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Set things up.
   *  INPUT PARAMETERS:
   *     None
   *  OUTPUT PARAMETERS:
   *     None
   *****************************************************************
   FUNCTION Init()
      
   ENDFUNC


   ******************************************************************
   *  FUNCTION NAME: GetPassKey
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Get a passkey needed by all other web service calls.
   *  INPUT PARAMETERS:
   *     tcUser - Username
   *     tcPassword - Password
   *  OUTPUT PARAMETERS:
   *     PassKey - pass key
   *     This.cPasskey - pass key
   *     Empty string - An error occurred, see This.cErrorMsg
   ******************************************************************
   FUNCTION Login() 
   LOCAL lcUser, lcPassword
   *****
   ** We'll eventually get the login from a file and have it encrypted
   *****

   swselect('options')
   GO top
   lcUser = ALLTRIM(cTreenoUser)
   lcPassword = ALLTRIM(cmEncrypt(options.cTreenoPwd,'5h3rWar3A1Z2'))

   * Check for valid login credentials
   IF EMPTY(ALLTRIM(lcUser)) OR EMPTY(ALLTRIM(lcPassword)) OR EMPTY(ALLTRIM(options.cTreenoDept))
      MESSAGEBOX('The Treeno user information has not been specified in the Cloud Doc preferences. Please correct and try again.',48,'Treeno Login')
      RETURN .f.
   ENDIF 

   lcPassKey = THIS.GetPassKey(lcUser,lcPassword)
   this.cDepartment = ALLTRIM(options.cTreenoDept)
   

   IF EMPTY(m.lcPassKey) OR 'incorrect' $ LOWER(m.lcPassKey)
      RETURN .f.
   ENDIF    
   
   ******************************************************************
   *  FUNCTION NAME: GetPassKey
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Get a passkey needed by all other web service calls.
   *  INPUT PARAMETERS:
   *     tcUser - Username
   *     tcPassword - Password
   *  OUTPUT PARAMETERS:
   *     PassKey - pass key
   *     This.cPasskey - pass key
   *     Empty string - An error occurred, see This.cErrorMsg
   ******************************************************************
   FUNCTION GetPassKey(tcUser, tcPassword)
      LOCAL lcResult, ;
            lcHash, ;
            lcPassKey, ;
            lcWSDL
      
      lcHash = STRCONV(THIS.HashMD5(m.tcPassword), 15)
      lcPassKey = ""

      lcWSDL = This.cServer + "/webservices2/docutronWS2.php?wsdl"
      This.oSOAP = CREATEOBJECT("wwSOAP")

      This.oSOAP.ParseServiceWSDL(m.lcWSDL)
      This.oSOAP.AddParameter("userName", m.tcUser)
      This.oSOAP.AddParameter("md5Pass", m.lcHash)
      
      loResponse = This.oSOAP.CallWSDLMethod("Login")
      
      IF This.oSOAP.lError
         This.lError = .T.
         This.cErrorMsg = This.oSOAP.cErrorMsg
         
         RETURN ""
      ENDIF
      
      lcPassKey = loResponse.Message
      This.cPassKey = m.lcPassKey
      
      RETURN m.lcPassKey
   ENDFUNC

   ******************************************************************
   *  FUNCTION NAME: GetCabinetID
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Returns a cabinet ID for the passed in cabinet name.
   *  INPUT PARAMETERS:
   *     tcCabinetName - Name of the cabinet
   *  OUTPUT PARAMETERS:
   *     Cabinet ID - The cabinet ID
   *     -1 - Error (see This.cErrorMsg)
   ******************************************************************
   FUNCTION GetCabinetID(tcCabinetName)
      LOCAL laCabinets[1], ;
            loResponse, ;
            lnCount, ;
            lnCabID
            
      lnCabID = -1
      
      This.oSOAP.nReturnMode = 2
      This.oSOAP.AddParameter("passKey", This.cPassKey)
      This.oSOAP.AddParameter("department", This.cDepartment)
      
      loResponse = This.oSOAP.CallWSDLMethod("GetCabinetList")
      
      IF This.oSOAP.lError 
         This.lError = .T.
         This.cErrorMsg = This.oSOAP.cErrorMsg
         
         RETURN m.lnCabID
      ENDIF
      
      lnCount = This.oSOAP.ParseObjectArray(@laCabinets, "CabinetList")
      
      FOR lnIndex = 1 TO m.lnCount
          IF ALLTRIM(LOWER(laCabinets[m.lnIndex].CabinetName)) == ALLTRIM(LOWER(m.tcCabinetName))
             lnCabID = VAL(laCabinets[m.lnIndex].CabinetID)
             EXIT
          ENDIF
      ENDFOR
      
      RETURN m.lnCabID
   ENDFUNC
   
   ******************************************************************
   *  FUNCTION NAME: SearchCabinet
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Checks to see if the passed in value exists within the 
   *     passed in cabinet (searching on the key field)
   *  INPUT PARAMETERS:
   *     tnCabinetID - Cabinet ID
   *     tcKey - Search key (field to search)
   *     tcValue - Value to search for.
   *  OUTPUT PARAMETERS:
   *      # of matches - If > 0, see This.oMatches
   *     -1 - Error, see This.cErrorMsg
   ******************************************************************   
   FUNCTION SearchCabinet(tnCabinetID, tcKey, tcValue)
      LOCAL lcXML, ;
            loResponse, ;
            lnStartID, ;
            lnFetch, ;
            loResult, ;
            laMatches[1], ;
            lnCount, ;
            lcResult 
      
      * Initial search
      This.oSOAP.nReturnMode = 0
      
      TEXT TO lcXML NOSHOW TEXTMERGE
         <?xml version="1.0" encoding="utf-8"?>
         <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                     xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" 
                     xmlns:tns="urn:DocutronWebServices2" 
                     xmlns:types="urn:DocutronWebServices2/encodedTypes" 
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
            <soap:Body soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
               <tns:SearchCabinet>
                  <passKey xsi:type="xsd:string"><<This.cPassKey>></passKey>
                  <department xsi:type="xsd:string"><<This.cDepartment>></department>
                  <cabinetID xsi:type="xsd:int"><<m.tnCabinetID>></cabinetID>
                  <searchTerms href="#id1" />
               </tns:SearchCabinet>
               <soapenc:Array id="id1" soapenc:arrayType="tns:CabinetItem[1]">
                  <Item href="#id2" />
               </soapenc:Array>
               <tns:CabinetItem id="id2" xsi:type="tns:CabinetItem">
                  <index xsi:type="xsd:string"><<m.tcKey>></index>
                  <value xsi:type="xsd:string"><<m.tcValue>></value>
               </tns:CabinetItem>
            </soap:Body>
         </soap:Envelope>
      ENDTEXT  
      
      loResponse = This.oSOAP.CallSoapServer(m.lcXML) 
      
      IF This.oSOAP.lError
         This.lError = .T.
         This.cErrorMsg = This.oSOAP.cErrorMsg
         
         RETURN -1
      ENDIF
      
      * Now get the results
      loResult = This.oSOAP.ParseSoapResponse(loResponse)
      
      IF VARTYPE(loResult) = 'O'
      This.oSOAP.nReturnMode = 1
      lnStartID = 0
      lnFetch = 100 && Should really only have 1 match
      
      TEXT TO lcXML NOSHOW TEXTMERGE
         <?xml version="1.0" encoding="utf-8"?>
         <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                     xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" 
                     xmlns:tns="urn:DocutronWebServices2" 
                     xmlns:types="urn:DocutronWebServices2/encodedTypes" 
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
            <soap:Body soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
               <tns:GetResultSet>
                  <passKey xsi:type="xsd:string"><<This.cPassKey>></passKey>
                  <department xsi:type="xsd:string"><<This.cDepartment>></department>
                  <cabinetID xsi:type="xsd:int"><<m.tnCabinetID>></cabinetID>
                  <resultID xsi:type="xsd:string"><<m.loResult.ResultID>></resultID>
                  <startIndex xsi:type="xsd:int"><<m.lnStartID>></startIndex>
                  <numberToFetch xsi:type="xsd:int"><<m.lnFetch>></numberToFetch>
               </tns:GetResultSet>
            </soap:Body>
         </soap:Envelope>   
      ENDTEXT
      
      loResponse = This.oSOAP.CallSoapServer(m.lcXML)
      
      ELSE
         this.oSoap.lError = .t.
      ENDIF 
      
      IF This.oSOAP.lError
         This.lError = .T.
         This.cErrorMsg = This.oSOAP.cErrorMsg
         
         RETURN -1
      ENDIF 
      
      lcResult = This.oSoap.ParseSoapResponse(loResponse) 
      
      IF "ns4:CabinetFolder[0]" $ lcResult
         This.oMatches = NULL
         lnCount = 0
      ELSE
         lnCount = This.oSoap.ParseObjectArray(@laMatches, "CabinetFolder")
      
         This.oMatches = m.laMatches
      ENDIF
      
      RETURN m.lnCount 
   ENDFUNC
   
   ******************************************************************
   *  FUNCTION NAME: CreateFolder
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Creates a folder in the passed in cabinet. The cursor
   *     should contain only the fields needed to populate the
   *     folder item (the idea is that this is probably different
   *     for Wells vs Loans vs Accounts Payable).
   *  INPUT PARAMETERS:
   *     tnCabinetID - Cabinet ID
   *     tcCursor - cursor that contains the data needed
   *  OUTPUT PARAMETERS:
   *     .T. - Successful
   *     .F. - Failed, see This.cErrorMsg
   ******************************************************************
   FUNCTION CreateFolder(tnDataSession, tnCabinetID, tcCursor)
      LOCAL lcXML, ;
            laFields[1], ;
            lnIndex
      
      SET DATASESSION TO tnDataSession
      AFIELDS(laFields, m.tcCursor)
      lnItems = ALEN(laFields, 1)
      SELECT (m.tcCursor)
      TEXT TO lcXML TEXTMERGE NOSHOW
         <?xml version="1.0" encoding="utf-8"?>
         <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
         xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" 
         xmlns:tns="urn:DocutronWebServices2" 
         xmlns:types="urn:DocutronWebServices2/encodedTypes" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
         xmlns:xsd="http://www.w3.org/2001/XMLSchema">
            <soap:Body soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
               <tns:CreateCabinetFolder>
                  <passKey xsi:type="xsd:string"><<This.cPassKey>></passKey>
                  <department xsi:type="xsd:string"><<This.cDepartment>></department>
                  <cabinetID xsi:type="xsd:int"><<m.tnCabinetID>></cabinetID>
                  <indices href="#id1" />
               </tns:CreateCabinetFolder>
               <soapenc:Array id="id1" soapenc:arrayType="tns:CabinetItem[<<m.lnItems>>]">
               <<This.BuildItemHref(m.lnItems)>>
               </soapenc:Array>
               <<This.BuildItemKeyValues(@laFields, m.lnItems)>>
            </soap:Body>
         </soap:Envelope>
      ENDTEXT
      
      loResponse = This.oSOAP.CallSoapServer(m.lcXML)
      
      IF This.oSOAP.lError
         This.lError = .T.
         This.cErrorMsg = This.oSOAP.cErrorMsg
         RETURN .F.
      ENDIF
      
      RETURN .T.
   ENDFUNC

   ******************************************************************
   *  FUNCTION NAME: BuildItemHRef
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Builds a small snippet of XML needed when creating a folder
   *  INPUT PARAMETERS:
   *     tnItems - # of items being passed
   *  OUTPUT PARAMETERS:
   *     XML snippet
   ******************************************************************
   PROTECTED FUNCTION BuildItemHRef(tnItems)
      LOCAL lcHREF, ;
            lnIndex
      
      lcHREF = ""
      FOR lnIndex = 1 TO m.tnItems
          lcHREF = m.lcHREF ;
                 + [<Item href="#id] + TRANSFORM(m.lnIndex + 1) + [" />]
      ENDFOR
      
      RETURN m.lcHREF
   ENDFUNC

   ******************************************************************
   *  FUNCTION NAME: BuildItemKeyValues
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Builds an XML string of key/value pairs needed when creating
   *     a folder.
   *  INPUT PARAMETERS:
   *     taFieldList - the fields in the cursor
   *     tnItems - the # of items in the cursor
   *  OUTPUT PARAMETERS:
   *     XML snippet
   ******************************************************************
   PROTECTED FUNCTION BuildItemKeyValues(taFieldList, tnItems)
      LOCAL lnIndex, ;
            lcKeyValue
      
      EXTERNAL ARRAY taFieldList
      
      lcKeyValue = ""
      FOR lnIndex = 1 TO m.tnItems
          lcField = taFieldList[m.lnIndex, 1]
          lcKeyValue = m.lcKeyValue ;
                     + [<tns:CabinetItem id="id] + TRANSFORM(m.lnIndex + 1) + [" xsi:type="tns:CabinetItem">] ;
                     + [     <index xsi:type="xsd:string">] + LOWER(m.taFieldList[m.lnIndex, 1]) + [</index>] ;
                     + [     <value xsi:type="xsd:string">] + ALLTRIM(TRANSFORM(EVALUATE(lcField))) + [</value>] ;
                     + [</tns:CabinetItem>]
      ENDFOR
      
      RETURN m.lcKeyValue
   ENDFUNC


   ******************************************************************
   *  FUNCTION NAME: LaunchWebsite
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Opens an instance of IE and logs into the Treeno website
   *     and navigates to the correct folder.
   *  INPUT PARAMETERS:
   *     tcUser - User name
   *     tcPass - Password
   *     tcCabinet - cabinet name, ex "Loans"
   *     tcKey - the field to search on
   *     tcValue - the value to search for
   *  OUTPUT PARAMETERS:
   *     None
   ******************************************************************
   FUNCTION LaunchWebsite(tcUser, tcPass, tcCabinet, tcKey, tcValue)
      LOCAL loIE AS InternetExplorer.Application, ;
            lcHash, ;
            lcPostData, ;
            lcHeader
      
      LOCAL loBridge, ;
            llSuccess, ;
            loHelper
      
      loBridge = CREATEOBJECT("wwDotNetBridge", "V4")
      llSuccess = loBridge.LoadAssembly("Sherware.treeno.dll")
      
      IF m.llSuccess
         loHelper = loBridge.CreateInstance("Sherware.Treeno.IEHelper")
         loHelper.SiteURL = This.cLoginUrl + "?legint=New"
         loHelper.AlwaysCreateNewInstance = .T.
         loHelper.DoSearch(m.tcUser, m.tcPass, This.cDepartment, m.tcCabinet, m.tcKey, m.tcValue)
         
         llSuccess = .T.
      ELSE
         This.cErrorMsg = loBridge.cErrorMsg
         MESSAGEBOX('LaunchWebsite Error: Can not load SherWare.Treeno.dll',0,'Treeno:LaunchWebSite')
      ENDIF
      
      RETURN m.llSuccess
      
   ENDFUNC

   ******************************************************************
   *  FUNCTION NAME: Destroy
   *   
   *  AUTHOR, DATE:
   *     Paul Mrozowski, 10/9/2012  
   *  PROCEDURE DESCRIPTION:
   *     Clean up
   *  INPUT PARAMETERS:
   *     None
   *  OUTPUT PARAMETERS:
   *     None
   ******************************************************************
   FUNCTION Destroy
      This.oSOAP = NULL
      This.oMatches = NULL
   ENDFUNC
   
   ************************************************************************
* wwAPI :: HashMD5
****************************************
***  Function: retrieved from the FoxWiki
***          http://fox.wikis.com/wc.dll?fox~vfpmd5hashfunction
***    Assume: Self standing function - not part of wwAPI class
***      Pass: Data to encrypt
***    Return: 
************************************************************************
FUNCTION HashMD5(tcData)

*** #include "c:\program files\microsoft visual foxpro 8\ffc\wincrypt.h"
#DEFINE dnPROV_RSA_FULL           1
#DEFINE dnCRYPT_VERIFYCONTEXT     0xF0000000

#DEFINE dnALG_CLASS_HASH         BITLSHIFT(4,13)
#DEFINE dnALG_TYPE_ANY        0
#DEFINE dnALG_SID_MD5           3
#DEFINE dnCALG_MD5        BITOR(BITOR(dnALG_CLASS_HASH,dnALG_TYPE_ANY),dnALG_SID_MD5)

#DEFINE dnHP_HASHVAL              0x0002  && Hash value

LOCAL lnStatus, lnErr, lhProv, lhHashObject, lnDataSize, lcHashValue, lnHashSize
lhProv = 0
lhHashObject = 0
lnDataSize = LEN(tcData)
lcHashValue = REPLICATE(CHR(0), 16)
lnHashSize = LEN(lcHashValue)


DECLARE INTEGER GetLastError ;
   IN win32api AS GetLastError

DECLARE INTEGER CryptAcquireContextA ;
   IN WIN32API AS CryptAcquireContext ;
   INTEGER @lhProvHandle, ;
   STRING cContainer, ;
   STRING cProvider, ;
   INTEGER nProvType, ;
   INTEGER nFlags

* load a crypto provider
lnStatus = CryptAcquireContext(@lhProv, 0, 0, dnPROV_RSA_FULL, dnCRYPT_VERIFYCONTEXT)
IF lnStatus = 0
   THROW GetLastError()
ENDIF

DECLARE INTEGER CryptCreateHash ;
   IN WIN32API AS CryptCreateHash ;
   INTEGER hProviderHandle, ;
   INTEGER nALG_ID, ;
   INTEGER hKeyhandle, ;
   INTEGER nFlags, ;
   INTEGER @hCryptHashHandle

* create a hash object that uses MD5 algorithm
lnStatus = CryptCreateHash(lhProv, dnCALG_MD5, 0, 0, @lhHashObject)
IF lnStatus = 0
   THROW GetLastError()
ENDIF

DECLARE INTEGER CryptHashData ;
   IN WIN32API AS CryptHashData ;
   INTEGER hHashHandle, ;
   STRING @cData, ;
   INTEGER nDataLen, ;
   INTEGER nFlags

* add the input data to the hash object
lnStatus = CryptHashData(lhHashObject, tcData, lnDataSize, 0)
IF lnStatus = 0
   THROW GetLastError()
ENDIF


DECLARE INTEGER CryptGetHashParam ;
   IN WIN32API AS CryptGetHashParam ;
   INTEGER hHashHandle, ;
   INTEGER nParam, ;
   STRING @cHashValue, ;
   INTEGER @nHashSize, ;
   INTEGER nFlags

* retrieve the hash value, if caller did not provide enough storage (16 bytes for MD5)
* this will fail with dnERROR_MORE_DATA and lnHashSize will contain needed storage size
lnStatus = CryptGetHashParam(lhHashObject, dnHP_HASHVAL, @lcHashValue, @lnHashSize, 0)
IF lnStatus = 0
   THROW GetLastError()
ENDIF


DECLARE INTEGER CryptDestroyHash ;
   IN WIN32API AS CryptDestroyHash;
   INTEGER hKeyHandle

*** free the hash object
lnStatus = CryptDestroyHash(lhHashObject)
IF lnStatus = 0
   THROW GetLastError()
ENDIF


DECLARE INTEGER CryptReleaseContext ;
   IN WIN32API AS CryptReleaseContext ;
   INTEGER hProvHandle, ;
   INTEGER nReserved

*** release the crypto provider
lnStatus = CryptReleaseContext(lhProv, 0)
IF lnStatus = 0
   THROW GetLastError()
ENDIF

RETURN lcHashValue
ENDFUNC
* HashMD5
ENDDEFINE


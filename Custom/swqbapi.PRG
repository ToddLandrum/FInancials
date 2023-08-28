***************************************************************************************************
* SWQBApi Class Library ( Sherware Quick Books API )
* Wrapper VFP class around custom SWQBApi .NET DLL, as well as support classes for it.
*
* Author: Steve Ellenoff ( sjellenoff@whitelightcomputing.com )
***************************************************************************************************
#INCLUDE "custom\SWQBApi.h"

DIMENSION taLines [1]

************************************************************
* SWQBApi Base Class ( Shared functionality across classes)
************************************************************
DEFINE CLASS SWQBApiBase AS CUSTOM
   *** Settings that should not change ***
   lInitParmRequired   = .T.      && Init parameter (tParm) is required
   lInitParmVarType    = 'C'      && String
   cInitParmMissingMsg = 'Setup error - Invalid or missing INI path passed to Init/Setup()'   && most sub classes expect INI string as the parameter

   *** Variables & Object references that will change ***
   cErrorMsg     = ''      && Stores latest error message.
   tErrorOccured = {//:}   && Stores date & time when latest error message recorded
   ******************************************************
   
   #define CRLF CHR(13)+CHR(10)

   * Init( any variable type ) - simply redirect to custom setup method
   * Initializes the object with specified parameter
   ************************************************************   
   FUNCTION INIT(tParm)
      ************************************************************   
      THIS._Setup(m.tParm)
   ENDFUNC

   * Destroy - simply redirect to custom cleanup method
   ************************************************************   
   FUNCTION DESTROY()
      ************************************************************   
      THIS._Cleanup()
   ENDFUNC

   * Setup( any variable type )
   * Called internally when class is instantiated and receives the parameter passed during construction
   * Returns .F. on failure
   ************************************************************   
   FUNCTION _Setup(tParm)
      ************************************************************   
      * Parameter is required
      IF THIS.lInitParmRequired
         * Handle types of parameters
         DO CASE
               * String
            CASE THIS.lInitParmVarType = 'C'
               IF THIS.IsEmptyString(m.tParm)
                  THIS._SetErrorInfo(THIS.cInitParmMissingMsg)
                  RETURN .F.
               ENDIF
               * Object
            CASE THIS.lInitParmVarType = 'O'
               IF NOT THIS.IsValidObject(m.tParm)
                  THIS._SetErrorInfo(THIS.cInitParmMissingMsg)
                  RETURN .F.
               ENDIF
               * ?
            OTHERWISE
               LOCAL lcErrMsg
               lcErrMsg =    'Setup error - Invalid or missing Init parameter passed to Init/Setup().' + CRLF + ;
                  'Expected vartype: ' + THIS.lInitParmVarType + CRLF + ;
                  'Received vartype: ' + m.lcVarType
               THIS._SetErrorInfo(m.lcErrMsg)
               RETURN .F.
         ENDCASE
      ENDIF
   ENDFUNC

   * Cleanup()
   * Called internally when class destroy event occurs
   ************************************************************   
   FUNCTION _Cleanup()
      ************************************************************   
   ENDFUNC

   * _GetErrorInfo()
   * Private function to return the latest error string
   ************************************************************   
   FUNCTION _GetErrorInfo()
      ************************************************************   
      RETURN THIS.cErrorMsg
   ENDFUNC

   * _GetErrorInfoOccured()
   * Private function to return datetime when latest error string was recorded
   ************************************************************   
   FUNCTION _GetErrorInfoOccured()
      ************************************************************   
      RETURN THIS.tErrorOccured
   ENDFUNC

   * _SetErrorInfo( string )
   * Private function to set the current error string value from passed string
   ************************************************************   
   FUNCTION _SetErrorInfo(tcErrorInfo)
      ************************************************************      
      THIS.cErrorMsg     = m.tcErrorInfo
      THIS.tErrorOccured = DATETIME()
   ENDFUNC

   * _GetExceptionInfo( Exception Object )
   * Private function to return string of exception info from passed exception object
   ************************************************************
   FUNCTION _GetExceptionInfo(toEx)
      ************************************************************   
      * TODO - We could add more info than just the message here
      RETURN 'Exception Info: ' + IIF(THIS.IsValidObject(m.toEx), toEx.MESSAGE, 'Unknown - Missing Exception Object')
   ENDFUNC

   * _GetString( string )
   * Private function which returns a alltrim string or empty string if null
   ************************************************************   
   FUNCTION _GetString(tcString)
      ************************************************************

      IF ISNULL(m.tcString)
         RETURN ''
      ENDIF
      IF VARTYPE(m.tcString) # 'C'
         RETURN ''
      ENDIF
      RETURN ALLTRIM(m.tcString)
   ENDFUNC

   * IsEmptyString( string )
   * Returns .T. if string is empty ( handles null values as well )
   ************************************************************   
   FUNCTION IsEmptyString(tcString)
      ************************************************************

      IF ISNULL(m.tcString)
         RETURN .T.
      ENDIF
      IF VARTYPE(m.tcString) # 'C'
         RETURN .T.
      ENDIF
      RETURN EMPTY(ALLTRIM(m.tcString))
   ENDFUNC

   * IsValidNumeric( numeric )
   * Returns .T. if variable passed is numeric ( handles null values as well )
   ************************************************************   
   FUNCTION IsValidNumeric(tnVal)
      ************************************************************   
      IF ISNULL(m.tnVal)
         RETURN .F.
      ENDIF
      RETURN VARTYPE(m.tnVal) = 'N'
   ENDFUNC

   * IsValidObject( object )
   * Returns .T. if object variable points to valid object ( handles null values as well )
   ************************************************************   
   FUNCTION IsValidObject(toObj)
      ************************************************************   
      IF ISNULL(m.toObj)
         RETURN .F.
      ENDIF
      RETURN VARTYPE(m.toObj) == 'O'
   ENDFUNC
ENDDEFINE

************************************************************
* SWQBApi Configuration Class
************************************************************
DEFINE CLASS SWQBApiConfig AS SWQBApiBase
   *** Settings that should not change ***
   cHeader = '[SWQBAPI]'   && Header string in the INI file

   *** Variables & Object references that will change ***

   * Config Settings
   cMode          = ''
   cApiUrl_Sbox   = ''
   cApiUrl_Prod   = ''
   cApiMinVer     = 0
   cAuthServerUrl = ''
   cDLL           = ''
   cDLLFQName     = ''
   * 
   ******************************************************

   * Setup( any variable type )
   * Called internally when class is instantiated and receives the parameter passed during construction
   * Attempts to parse the INI file ( string passed as tParm ) and set config properties based on the INI settings.
   * Returns .F. if any errors encountered and sets error message property accordingly.
   ************************************************************   
   FUNCTION _Setup(tParm)
      ************************************************************   
      LOCAL lcIni, llOk, loEx, lcContent, lnPos, laLines[1]

      * Call parent first
      IF NOT DODEFAULT(tParm)
         RETURN .F.
      ENDIF

      * Parameter should be INI file ( using variable for clarity )
      lcIni = m.tParm

      TRY
         * Read in content of file
         lcContent = FILETOSTR(m.lcIni)
         * Find Section Header
         lnPos = THIS._FindHeaderPosition(m.lcContent)
         * Missing header
         IF m.lnPos < 1
            ERROR 'INI file missing ' + THIS.cHeader + ' section header'
         ENDIF
         * Remove all content prior to and including the header
         lcContent = SUBSTR(m.lcContent, m.lnPos + 1)
         * Convert all tabs to spaces
         lcContent = CHRTRANC(m.lcContent, TAB, ' ')
         * Break remainder into lines
         ALINES(m.laLines, m.lcContent)
         * Convert setting names into lower case
         THIS._ConvertLinesToLowerCase(@m.laLines)
         * Process Settings
         llOk = THIS._ProcessSettings(@m.laLines)
      CATCH TO loEx
         THIS._SetErrorInfo( 'Setup exception: ' + CRLF + THIS._GetExceptionInfo(m.loEx) )
      ENDTRY
      RETURN m.llOk
   ENDFUNC

   * _FindHeaderPosition( string )
   * Private function called by _Setup() to search passed contents of INI file for the header and return its ending position if found or 0 otherwise
   ************************************************************   
   FUNCTION _FindHeaderPosition( tcContent )
      ************************************************************   
      LOCAL lnPos, lcHeader, lnLen
      lcHeader = THIS.cHeader
      lnLen    = LEN(m.lcHeader)
      lnPos    = AT(m.lcHeader, m.tcContent)
      * Missing
      IF m.lnPos < 1
         RETURN 0
      ENDIF
      * Return position where header ends
      RETURN m.lnPos + m.lnLen
   ENDFUNC

   * _ConvertLinesToLowerCase( array by ref )
   * Private function which modifies the array passed to make all setting names lower case and remove spaces between = sign
   ************************************************************   
   PROCEDURE _ConvertLinesToLowerCase(taLines)
      ************************************************************   
      LOCAL lnLen, lnLoop, lcLine, lnPos, lcSettingName
      lnLen = ALEN(m.taLines, 1)
      FOR lnLoop = 1 TO m.lnLen
         lcLine = m.taLines[m.lnLoop]
         lnPos  = AT('=', m.lcLine)
         IF lnPos > 1
            lcSettingName       = ALLTRIM(LEFT(m.lcLine, m.lnPos - 1))
            lcSettingName       = LOWER(m.lcSettingName)
            lcLine              = m.lcSettingName + '=' + ALLTRIM(SUBSTR(m.lcLine, m.lnPos + 1))
            m.taLines[m.lnLoop] = m.lcLine
         ENDIF
      ENDFOR
   ENDPROC

   * _ProcessSettings( array by ref )
   * Private function called by _Setup() to find, extract, validate and set values of all config properties
   * Returns .F. if any errors occurred
   ************************************************************   
   PROCEDURE _ProcessSettings(taLines)
      ************************************************************

      LOCAL lcVal
      * Mode
      lcVal = THIS._FindSettingValue(@m.taLines, 'Mode')
      IF NOT THIS._SetSetting('Mode', 'cMode', m.lcVal)
         RETURN .F.
      ENDIF
      * ApiUrl_Sbox
      lcVal = THIS._FindSettingValue(@m.taLines, 'ApiUrl_Sbox')
      IF NOT THIS._SetSetting('ApiUrl_Sbox', 'cApiUrl_Sbox', m.lcVal)
         RETURN .F.
      ENDIF
      * ApiUrl_Prod
      lcVal = THIS._FindSettingValue(@m.taLines, 'ApiUrl_Prod')
      IF NOT THIS._SetSetting('ApiUrl_Prod', 'cApiUrl_Prod', m.lcVal)
         RETURN .F.
      ENDIF
      * ApiMinVer
      lcVal = THIS._FindSettingValue(@m.taLines, 'ApiMinVer')
      IF NOT THIS._SetSetting('ApiMinVer', 'cApiMinVer', m.lcVal)
         RETURN .F.
      ENDIF
      * AuthServerUrl
      lcVal = THIS._FindSettingValue(@m.taLines, 'AuthServerUrl')
      IF NOT THIS._SetSetting('AuthServerUrl', 'cAuthServerUrl', m.lcVal)
         RETURN .F.
      ENDIF
      * DLL
      lcVal = THIS._FindSettingValue(@m.taLines, 'DLL')
      IF NOT THIS._SetSetting('DLL', 'cDLL', m.lcVal)
         RETURN .F.
      ENDIF
      * DLLFQName
      lcVal = THIS._FindSettingValue(@m.taLines, 'DLLFQName')
      IF NOT THIS._SetSetting('DLLFQName', 'cDLLFQName', m.lcVal)
         RETURN .F.
      ENDIF
   ENDPROC

   * _FindSettingValue( array by ref, string )
   * Private function which returns given setting name's value from passed array of lines
   * Returns null if not found
   ************************************************************   
   FUNCTION _FindSettingValue(taLines, tcSettingName)
      ************************************************************

      LOCAL lnLen, lnLoop, lcLine, lnPos, lcSettingName
      tcSettingName = LOWER(m.tcSettingName)
      lnLen         = ALEN(m.taLines, 1)
      FOR lnLoop = 1 TO m.lnLen
         lcLine = m.taLines[m.lnLoop]
         * Skip comments
         IF LEFT(m.lcLine, 1) = '#'
            LOOP
         ENDIF
         * Locate = sign & if found return everything trimmed after it
         lnPos = AT('=', m.lcLine)
         IF lnPos > 1
            lcSettingName = ALLTRIM(LEFT(m.lcLine, m.lnPos - 1))
            IF m.lcSettingName == m.tcSettingName
               RETURN ALLTRIM(SUBSTR(m.lcLine, m.lnPos + 1))
            ENDIF
         ENDIF
      ENDFOR
      RETURN NULL
   ENDFUNC

   * _SetSetting( string, string, string)
   * Private function which checks if passed setting value is valid and if so sets property name passed on this object
   * Returns .T. or .F. accodringly.
   ************************************************************   
   FUNCTION _SetSetting( tcSettingName, tcPropName, tcVal )
      ************************************************************

      LOCAL llOk
      * Is setting missing?
      IF THIS.IsEmptyString(m.tcVal)
         THIS._SetErrorInfo(m.tcSettingName + ' Setting is missing')
         RETURN m.llOk
      ENDIF
      * Is it valid?
      DO CASE
         CASE UPPER(ALLTRIM(tcSettingName)) == 'MODE'
            IF NOT THIS._ValidateMode(m.tcVal)
               THIS._SetErrorInfo('Mode Setting is invalid. Allowed values are either Production or Sandbox')
               RETURN m.llOk
            ENDIF
         CASE UPPER(ALLTRIM(tcSettingName)) == 'DLL'
            IF NOT THIS._ValidateFileName(m.tcVal)
               THIS._SetErrorInfo('DLL Setting is invalid. Could not locate the file specified: ' + m.tcVal)
               RETURN m.llOk
            ENDIF
            * No special validation for the others
      ENDCASE
      * Set it
      TRY
         THIS.&tcPropName = m.tcVal
         llOk             = .T.
      CATCH TO loEx
         THIS._SetErrorInfo( '_SetSetting exception: ' + CRLF + THIS._GetExceptionInfo(m.loEx) )
      ENDTRY
      RETURN m.llOk
   ENDFUNC

   * _ValidateMode( string )
   * Private function used to validate the mode setting, .T. if yes, .F. if no
   ************************************************************   
   FUNCTION _ValidateMode( tcVal )
      ************************************************************   
      LOCAL lcMode
      lcMode = UPPER(m.tcVal)
      RETURN ALLTRIM(m.lcMode) == 'PRODUCTION' OR ;
         ALLTRIM(m.lcMode) == 'SANDBOX'
   ENDFUNC

   * _ValidateFileName( string )
   * Private function used to validate if a file setting is valid, i.e. the file exists
   ************************************************************   
   FUNCTION _ValidateFileName( tcFile )
      ************************************************************

      RETURN FILE(m.tcFile, 1)
   ENDFUNC
ENDDEFINE

************************************************************
* SWQBApi Save Definition Class
************************************************************
DEFINE CLASS SWQBApiSaveDefinition AS SWQBApiBase
   *** Settings that should not change ***
   lInitParmRequired    = .F.   && Init parameter (tParm) is NOT required
   *** Variables & Object references that will change ***
   * NONE
   ******************************************************

   * CreateDefinitionDBF( string, string, string, string, object)
   * Common method for creating or overwriting a DBF definition file given the passed parameters, by calling method of the passed API object
   * The first column of the created dbf is the only column that is not identical across definitions so we must pass its name.
   FUNCTION CreateDefinitionDBF(tcDBFName, tcAlias, tcFirstFieldName, tcMethod, toApi)
      LOCAL llOk, lcAlias, lcCSVFile, lcHoldAlias, lcHoldSafety, loEx
      lcAlias = m.tcAlias

      * Preserve settings
      lcHoldAlias  = ALIAS()
      lcHoldSafety = SET('SAFETY')
      TRY
         * Open Existing and Zap
         IF FILE(m.tcDBFName)
            USE (m.tcDBFName) EXCLU ALIAS (m.lcAlias) IN 0
            SET SAFETY OFF
            SELECT (m.lcAlias)
            ZAP
            USE
            * Create new DBF
         ELSE
            CREATE DBF (m.tcDBFName) FREE ( &tcFirstFieldName C(30), PropName C(50), PropType C(100), PropFullTy C(254), BaseType C(50), DefinedIn C(75) )
            USE
         ENDIF
         * Open exclusively for appending
         USE (m.tcDBFName) EXCLU ALIAS (m.lcAlias) IN 0

         * Create definition csv file by calling passed method of passed API object with generated csv temp file name
         lcCSVFile = 'tmp' + SYS(2015) + '.csv'
         llOk      = EVAL('toApi.' + m.tcMethod + '(m.lcCSVFile)')
         IF m.llOk
            * Append contents into dbf
            SELECT (m.lcAlias)
            APPEND FROM (m.lcCSVFile) TYPE CSV
         ENDIF
      CATCH TO loEx
         THIS._SetErrorInfo( 'CreateDBFFromCSV failed: ' + CRLF + toApi._GetExceptionInfo(m.loEx) )
      ENDTRY

      * Erase csv file
      TRY
         IF FILE(m.lcCSVFile)
            ERASE &lcCSVFile
         ENDIF
      CATCH
      ENDTRY

      * Clean up & Restore environment
      USE IN SELECT(m.lcAlias)
      IF NOT EMPTY(m.lcHoldAlias)
         SELECT (m.lcHoldAlias)
      ENDIF
      SET SAFETY &lcHoldSafety

      * Return status
      RETURN m.llOk
   ENDFUNC
ENDDEFINE

************************************************************
* SWQBApi Class
************************************************************
DEFINE CLASS SWQBApi AS SWQBApiBase
   *** Settings that should not change ***

   * .NET Bridge Properties
   cDLL       = ''               && Full path and file name of .NET Bridge custom DLL
   cDLLFQName = ''            && Fully qualified DLL name, includes namespace and class name of the .NET Bridge custom API class

   *** Variables & Object references that will change ***
   cSessionKey = ''         && Stores session key
   oShared     = NULL            && Shared Object references between this class and entity classes

   ********************************************************************************************************

   * Setup( any variable type )
   * Called internally when class is instantiated and receives the parameter passed during construction
   * Parameter should be the INI filename and path
   * Sets up DOTNET BRIDGE handling and other various tasks
   FUNCTION _Setup(tParm)
      LOCAL llOk, lcIni, loHoldTablePrompt, loEx

      * Call parent first
      IF NOT DODEFAULT(tParm)
         RETURN .F.
      ENDIF

      * Attempt all setup steps for DLL interaction
      TRY
         * Hold Table Prompt setting
         loHoldTablePrompt = SET('TABLEPROMPT')

         * Disable this since even inside TRY/CATCH trying to open a table will pop this up if it can't open the table
         SET TABLEPROMPT OFF

         * Parameter should be INI file ( using variable for clarity )
         lcIni = m.tParm

         * Setup our shared object instances ( must happen before any config handling )
         THIS.oShared = THIS._CreateSharedObj()

         * Read Configuration data
         IF NOT THIS._ReadConfig(m.lcIni)
            ERROR 'Read Configuration Failed: ' + THIS.cErrorMsg
         ENDIF

         * Set Configuration for DLL settings
         IF NOT THIS._SetConfigurationDLL()
            ERROR 'Set Configuration DLL Failed: ' + THIS.cErrorMsg
         ENDIF

         * Load library and initialize wwDotnetBridge
         DO wwDotNetBridge

         * Load DotNetBridge using CLR V4 **
         THIS.oShared.oBridge = CREATEOBJ('wwDotNetBridge', 'V4')
         IF NOT THIS.IsValidObject(THIS.oShared.oBridge)
            ERROR 'Failed to load wwDotNetBridge!'
         ENDIF

         * Load .NET assembly from disk
         IF NOT THIS.oShared.oBridge.LoadAssembly(THIS.cDLL)
            ERROR THIS.oShared.oBridge.cErrorMsg
         ENDIF

         * Create an instance of the .NET API class. 
         * NOTE: No COM registration is required for the .NET DLL
         THIS.oShared.oQBApi = THIS.oShared.oBridge.CreateInstance(THIS.cDLLFQName)
         IF THIS.oShared.oBridge.lError
            ERROR 'CreateInstance Failed for DLL Class: ' + THIS.cDLLFQName + CHR(13) + CHR(10) + 'Reason: ' + THIS.oShared.oBridge.GetErrorMsg()
         ENDIF

         * Extra check for oQBApi to be valid
         IF NOT THIS.IsValidObject(THIS.oShared.oQBApi)
            ERROR 'CreateInstance failed to create oQBApi as an object!'
         ENDIF

         * Set Configuration for QBAPI
         IF NOT THIS._SetConfigurationQBAPI()
            ERROR 'Set Configuration QBAPI Failed: ' + THIS.cErrorMsg
         ENDIF

         * Populate oWebApiErrorsEnum collection
         THIS.oShared.oWebApiErrorsEnum = THIS._GetWebAPIErrorEnums()
         IF NOT THIS.IsValidObject(THIS.oShared.oWebApiErrorsEnum)
            ERROR 'Failed to populate WebAPIErrorsEnum: ' + THIS.cErrorMsg
         ENDIF

         * Flag success
         llOk = .T.

      CATCH TO loEx
         THIS._SetErrorInfo( 'Setup exception: ' + CRLF + THIS._GetExceptionInfo(m.loEx) )

      FINALLY
         * Restore setting we modified initially
         SET TABLEPROMPT &loHoldTablePrompt
      ENDTRY

      * Return success or failure
      RETURN m.llOk
   ENDFUNC

   * Cleanup()
   * Called internally when class destroy event occurs
   FUNCTION _Cleanup()
      * Release references, do class before bridge to be safe
      IF THIS.IsValidObject(THIS.oShared)
         THIS.oShared.oQBApi  = NULL
         THIS.oShared.oBridge = NULL
      ENDIF
      THIS.oShared = NULL
   ENDFUNC

   * _IsConfigSetup()
   * Private function to return state of oConfig property and whether it has been setup
   FUNCTION _IsConfigSetup
      RETURN THIS.IsValidObject(THIS.oShared.oConfig)
   ENDFUNC

   * _ReadConfig( string )
   * Private function called from setup which reads the passed configuration file and populates oConfig property
   FUNCTION _ReadConfig( tcIniFile )
      * Create config option and check for error message
      THIS.oShared.oConfig = CREATEOBJ('SWQBApiConfig', m.tcIniFile)
      IF NOT EMPTY(THIS.oShared.oConfig.cErrorMsg)
         THIS._SetErrorInfo('SetConfiguration failed!' + CRLF + THIS.oShared.oConfig.cErrorMsg)
         RETURN .F.
      ENDIF
   ENDFUNC

   * _SetConfigurtionDLL()
   * Private function called from setup which sets DLL related properties from already read oConfig object
   * NOTE: DLL settings must be set before DOTNET BRIDGE is initialized
   FUNCTION _SetConfigurationDLL()
      * Abort if config not setup
      IF NOT THIS._IsConfigSetup()
         THIS._SetErrorInfo('_SetConfigurationDLL failed, oConfig not setup. Make sure to call _ReadConfig() first')
         RETURN .F.
      ENDIF
      * Seutp DLL settings *
      THIS.cDLL       = THIS.oShared.oConfig.cDLL
      THIS.cDLLFQName = THIS.oShared.oConfig.cDLLFQName
   ENDFUNC

   * _SetConfigurtionQBAPI()
   * Private function called from setup which sets QBAPI related properties from already read oConfig object
   * NOTE: QBAPI settings must be set *AFTER* DOTNET BRIDGE is initialized
   FUNCTION _SetConfigurationQBAPI()
      * Abort if config not setup
      IF NOT THIS._IsConfigSetup()
         THIS._SetErrorInfo('_SetConfigurationQBAPI failed, oConfig not setup. Make sure to call _ReadConfig() first')
         RETURN .F.
      ENDIF
      * Set Authorization Server URL
      THIS.oShared.oQBApi.Config.AuthServerUrl = THIS.oShared.oConfig.cAuthServerUrl
      * Set QBO API Min Version #
      THIS.oShared.oQBApi.Config.QBOApiMinVersion = THIS.oShared.oConfig.cApiMinVer
      * Set QBO API Base URL based on Mode ( Production vs Sandbox )
      IF UPPER(ALLTRIM(THIS.oShared.oConfig.cMode)) = 'PRODUCTION'
         THIS.oShared.oQBApi.Config.QBOAPIBaseUrl =    THIS.oShared.oConfig.cApiUrl_Prod
      ELSE
         THIS.oShared.oQBApi.Config.QBOAPIBaseUrl = THIS.oShared.oConfig.cApiUrl_Sbox
      ENDIF
   ENDFUNC

   * _GetApiErrorMessage()
   * Private wrapper function to return the .NET API Error Message String
   FUNCTION _GetApiErrorMessage
      IF THIS.IsValidObject(THIS.oShared.oQBApi)
         LOCAL lcErrMsg
         lcErrMsg = THIS.oShared.oQBApi.GetErrorMsg()
         IF NOT THIS.IsEmptyString(m.lcErrMsg)
            RETURN m.lcErrMsg
            * No error in QBApi, check the Bridge
         ELSE
            IF THIS.IsValidObject(THIS.oShared.oBridge)
               lcErrMsg = THIS.oShared.oBridge.cErrorMsg
               IF NOT THIS.IsEmptyString(m.lcErrMsg)
                  RETURN 'Bridge Error: ' + m.lcErrMsg
               ENDIF
            ENDIF
            RETURN 'Unknown QBApi Error!'
         ENDIF
      ELSE
         RETURN 'Unknown Error - QBApi not defined!'
      ENDIF
   ENDFUNC

   *_SetAPIErrorInfo( string, string, Exception Object )
   * Private function to handle setting error info from failed Bridge API Calls
   FUNCTION _SetAPIErrorInfo(tcApiMethod, tcParms, toEx)
      LOCAL lcErrInfo, lcErrMsg, lcPriorErrMsg
      * If we have an exception object use it's error message
      IF THIS.IsValidObject(m.toEx)
         lcErrMsg = THIS._GetExceptionInfo(m.toEx)
         * Add prior Error Message if we have one as it may be an API error
         lcPriorErrMsg = THIS._GetErrorInfo()
         IF NOT EMPTY(m.lcPriorErrMsg)
            lcErrMsg = m.lcErrMsg + CRLF + CRLF + ;
               'Prior Error @ ' + TRANSFORM(THIS._GetErrorInfoOccured()) + CRLF + ;
               m.lcPriorErrMsg
         ENDIF
      ELSE
         * Use API Object error message since we don't have an exception object
         lcErrMsg = THIS._GetApiErrorMessage()
      ENDIF
      lcErrInfo = 'Bridge Call Failed for method: ' + m.tcApiMethod + CRLF + ;
         'Parms: ' + m.tcParms + CRLF + ;
         'Error: ' + m.lcErrMsg
      THIS._SetErrorInfo(m.lcErrInfo)
   ENDFUNC

   * _CreateSharedObj()
   * Private function which creates a wrapper object used to share objects between an instance of this calss and entity subclass instances
   FUNCTION _CreateSharedObj()
      LOCAL loS
      loS = CREATEOBJ('Empty')
      ADDPROPERTY(m.loS, 'oBridge',         NULL)   && Object reference to wwDotNetBridge Instance.
      ADDPROPERTY(m.loS, 'oQBApi',         NULL)   && Object reference to .NET class which contains all the necessary functionality we need.
      ADDPROPERTY(m.loS, 'oConfig',         NULL)   && Config object containing properties read from the INI file
      ADDPROPERTY(m.loS, 'oWebApiErrorsEnum',   NULL)   && Collection of WebAPIError Enums from .NET Bridge class
      RETURN m.loS
   ENDFUNC

   * _OpenBrowserURL()
   * Private function opens a browser window for given URL using ShellExecute. Return .F. on failure.
   FUNCTION _OpenBrowserURL ( tcURL )
      LOCAL loEx, llError
      DECLARE ShellExecute IN shell32.DLL INTEGER, STRING, STRING, STRING, STRING, INTEGER
      TRY
         ShellExecute( 0, 'open', m.tcURL, '', '', 1 )
      CATCH TO loEx
         THIS._SetErrorInfo( '_OpenBrowserURL exception: ' + CRLF + THIS._GetExceptionInfo(m.loEx) )
         llError = .T.
      ENDTRY
      RETURN NOT m.llError
   ENDFUNC

   * _GetNETObjectProperty( object, string )
   * Private function which returns the value of the passed .NET object's passed property name or NULL on failure
   FUNCTION _GetNETObjectProperty( toObj, tcPropName )
      * Abort if invalid object
      IF NOT THIS.IsValidObject(m.toObj)
         THIS._SetErrorInfo('Object passed to _GetNETObjectProperty() is not a valid object')
         RETURN NULL
      ENDIF
      * Abort if invalid property name
      IF THIS.IsEmptyString(m.tcPropName)
         THIS._SetErrorInfo(' Property name passed to _GetNETObjectProperty() is missing or invalid')
         RETURN NULL
      ENDIF
      * Get the property name
      LOCAL lVal
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'GetProperty()'
      lcParms     = 'Object = Object'
      TRY
         * Get the value of the object's property
         lVal = THIS.oShared.oBridge.GetProperty(m.toObj, m.tcPropName)
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         lVal = NULL
      ENDIF
      ** NOTE: We don't check for NULL if call succeeded since it may be NULL
      RETURN m.lVal      && May be NULL
   ENDFUNC

   * _GetWebAPIErrorEnums()
   * Private function which returns a VFP collection of WebAPIErrorEnums or NULL on failure
   FUNCTION _GetWebAPIErrorEnums()
      LOCAL loEnums
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'GetWebApiEnums()'
      lcParms     = 'Object = Object'
      TRY
         * Must use InvokeMethod()?
         loEnums = THIS.oShared.oBridge.InvokeMethod(THIS.oShared.oQBApi, 'GetWebApiEnums')
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         loEnums = NULL
         ** Call succeeded, but did we get an object
      ELSE
         IF NOT THIS.IsValidObject(m.loEnums)
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            loEnums = NULL
            * Valid object
         ELSE
            LOCAL loColl, lnLoop, lnCount, lcVal
            lnCount = loEnums.COUNT
            loColl  = CREATEOBJ('Collection')
            FOR lnLoop = 1 TO m.lnCount
               lcVal = loEnums.ITEM(m.lnLoop - 1)
               * Value is the integer of the enum ( converted to 0 based ), and the key is the enum name string
               loColl.ADD(m.lnLoop - 1, m.lcVal)
            ENDFOR
            * Assign so we can return the collection
            loEnums = loColl
         ENDIF
      ENDIF
      ** NOTE: We don't check for NULL if call succeeded since it may be NULL
      RETURN m.loEnums      && May be NULL
   ENDFUNC

   * _GetPopulatedAuthDataInfo( object )
   * Private function which returns a VFP object populated with information from the passed Auth Data object retrieved from .NET or NULL on failure
   FUNCTION _GetPopulatedAuthDataInfo( toObj )
      * Abort if invalid object
      IF NOT THIS.IsValidObject(m.toObj)
         THIS._SetErrorInfo('Object passed to _GetPopulatedAuthDataInfo() is not a valid object')
         RETURN NULL
      ENDIF
      LOCAL loInfo, loWebApiEnums, lnErrCode, llEDev, llEFail, llEAuth, ;
         lnUnknownError, ;
         lnMissingData, ;
         lnQBOAPIStateError, ;
         lnQBOAPIAccessFailure, ;
         lnDatabaseAccessFailure, ;
         lnAccessTokenFailure, ;
         lnAccessTokenNotFound, ;
         lnRefreshTokenFailure, ;
         lnRefreshTokenExpired, ;
         lnInvalidEndpoint
      * Get WebAPIEnums array and store to local copy to avoid constant repeating of Access method
      loWebApiEnums = THIS.oShared.oWebApiErrorsEnum
      IF NOT THIS.IsValidObject(m.loWebApiEnums)
         RETURN NULL
      ENDIF
      * Track all possible enum values
      lnUnknownError          = loWebApiEnums.GETKEY('UnknownError') - 1
      lnMissingData           = loWebApiEnums.GETKEY('MissingData') - 1
      lnQBOAPIStateError      = loWebApiEnums.GETKEY('QBOAPIStateError') - 1
      lnQBOAPIAccessFailure   = loWebApiEnums.GETKEY('QBOAPIAccessFailure') - 1
      lnDatabaseAccessFailure = loWebApiEnums.GETKEY('DatabaseAccessFailure') - 1
      lnAccessTokenFailure    = loWebApiEnums.GETKEY('AccessTokenFailure') - 1
      lnAccessTokenNotFound   = loWebApiEnums.GETKEY('AccessTokenNotFound') - 1
      lnRefreshTokenFailure   = loWebApiEnums.GETKEY('RefreshTokenFailure') - 1
      lnRefreshTokenExpired   = loWebApiEnums.GETKEY('RefreshTokenExpired') - 1
      lnInvalidEndpoint       = loWebApiEnums.GETKEY('InvalidEndpoint') - 1
      * Get Error Code, since we use it for all comparisions below
      lnErrCode     = THIS._GetNETObjectProperty(m.toObj, 'ErrorCode')
      * Create new object
      loInfo = CREATEOBJ('Empty')
      * Add typical auth data properties
      ADDPROPERTY(m.loInfo, 'cKey',                  THIS._GetNETObjectProperty(m.toObj, 'Key'))
      ADDPROPERTY(m.loInfo, 'cRealmID',               THIS._GetNETObjectProperty(m.toObj, 'RealmID'))
      ADDPROPERTY(m.loInfo, 'cAccessToken',            THIS._GetNETObjectProperty(m.toObj, 'AccessToken'))
      ADDPROPERTY(m.loInfo, 'cAccessTokenExpires',      THIS._GetNETObjectProperty(m.toObj, 'AccessTokenExpires'))
      ADDPROPERTY(m.loInfo, 'dAccessExpires',            THIS._GetNETObjectProperty(m.toObj, 'dAccessExpires'))
      ADDPROPERTY(m.loInfo, 'cRefreshToken',            THIS._GetNETObjectProperty(m.toObj, 'RefreshToken'))
      ADDPROPERTY(m.loInfo, 'cRefreshTokenExpires',      THIS._GetNETObjectProperty(m.toObj, 'RefreshTokenExpires'))
      ADDPROPERTY(m.loInfo, 'dRefreshExpires',         THIS._GetNETObjectProperty(m.toObj, 'dRefreshExpires'))
      * Add properties for Error message, Code, and Code Descriptions
      ADDPROPERTY(m.loInfo, 'cErrMsg',               THIS._GetNETObjectProperty(m.toObj, 'ErrorMsg'))
      ADDPROPERTY(m.loInfo, 'nErrCode',               m.lnErrCode)
      ADDPROPERTY(m.loInfo, 'cErrCodeDesc',            THIS._GetNETObjectProperty(m.toObj, 'ErrorCodeDescr'))
      * Add properties for each possible error code enum
      ADDPROPERTY(m.loInfo, 'llUnknownError',            m.lnErrCode = lnUnknownError)
      ADDPROPERTY(m.loInfo, 'llMissingData',            m.lnErrCode = lnMissingData)
      ADDPROPERTY(m.loInfo, 'llQBOAPIStateError',         m.lnErrCode = lnQBOAPIStateError)
      ADDPROPERTY(m.loInfo, 'llQBOAPIAccessFailure',      m.lnErrCode = lnQBOAPIAccessFailure)
      ADDPROPERTY(m.loInfo, 'llDatabaseAccessFailure',   m.lnErrCode = lnDatabaseAccessFailure)
      ADDPROPERTY(m.loInfo, 'llAccessTokenFailure',      m.lnErrCode = lnAccessTokenFailure)
      ADDPROPERTY(m.loInfo, 'llAccessTokenNotFound',      m.lnErrCode = lnAccessTokenNotFound)
      ADDPROPERTY(m.loInfo, 'llRefreshTokenFailure',      m.lnErrCode = lnRefreshTokenFailure)
      ADDPROPERTY(m.loInfo, 'llRefreshTokenExpired',      m.lnErrCode = lnRefreshTokenExpired)
      ADDPROPERTY(m.loInfo, 'llInvalidEndpoint',         m.lnErrCode = lnInvalidEndpoint)
      * Add Error Codes by Group
      llEDev  = m.loInfo.llMissingData OR m.loInfo.llQBOAPIStateError OR m.loInfo.llInvalidEndpoint
      llEFail = m.loInfo.llQBOAPIAccessFailure OR m.loInfo.llDatabaseAccessFailure OR m.loInfo.llAccessTokenFailure OR m.loInfo.llRefreshTokenFailure
      llEAuth = m.loInfo.llAccessTokenNotFound OR m.loInfo.llRefreshTokenExpired
      ADDPROPERTY(m.loInfo, 'llEGrp_Dev',               m.llEDev)   && Developer error
      ADDPROPERTY(m.loInfo, 'llEGrp_Fail',            m.llEFail)   && Failure ( Database, QBOAPI )
      ADDPROPERTY(m.loInfo, 'llEGrp_NeedAuth',         m.llEAuth)  && Needs Authorization
      * Force dates to null
      IF THIS.IsEmptyString(loInfo.cAccessTokenExpires)
         loInfo.dAccessExpires = NULL
      ENDIF
      IF THIS.IsEmptyString(loInfo.cRefreshTokenExpires)
         loInfo.dRefreshExpires = NULL
      ENDIF
      * Return the object
      RETURN m.loInfo
   ENDFUNC

   * _IsValidAuthData( object )
   * Private function which checks if the last auth data object is valid ( no errors )
   * Returns .T. if auth data is valid / has no errors, .F. otherwise
   * If the error is related to requiring new authentication consent, it directs the user to do so.
   FUNCTION _IsValidAuthData( toApi )
      * Abort if invalid object
      IF NOT THIS.IsValidObject(m.toApi)
         THIS._SetErrorInfo('Object passed to _IsValidAuthData() is not a valid object')
         RETURN .F.
      ENDIF
      LOCAL loAuth
      loAuth = THIS._GetLastAuthInfo(m.toApi)
      * Abort if failed to retrieve last auth
      IF NOT THIS.IsValidObject(m.loAuth)
         THIS._SetErrorInfo('_IsValidAuthData() failed. ' + THIS.cErrorMsg)
         RETURN .F.
      ENDIF
      * Let check auth do all the work
      RETURN THIS._CheckAuthorization(m.toApi, m.loAuth)
   ENDFUNC

   * _CheckAuthorization( object, object (optional) )
   * Common handler for public method of the same name
   * Difference here is we are passed a required .NET API Class instance
   FUNCTION _CheckAuthorization(toApi, toAuthData)
      LOCAL llOk, loAuthData, llHasError, llAuthGiven, llSkipFirstGetAuth
      * Require API Object
      IF NOT THIS.IsValidObject(m.toApi)
         THIS._SetErrorInfo('_CheckAuthorization Error: Must pass API object')
         RETURN .F.
      ENDIF
      * Skip getting first auth object if it was passed and is valid
      IF THIS.IsValidObject(m.toAuthData)
         loAuthData         = m.toAuthData
         llSkipFirstGetAuth = .T.
      ENDIF
      DO WHILE(NOT m.llOk)
         * Step 1 - Call GetAuthInfo() to update the latest auth data ( unless we should skip )
         IF NOT m.llSkipFirstGetAuth
            loAuthData         = THIS._GetAuthInfo(m.toApi)   && Retrieve current data using passed API .NET instance
            llSkipFirstGetAuth = .F.            && Any follow up attempts should always get current data
         ENDIF
         * Step 2 - Handle failure
         IF NOT THIS.IsValidObject(m.loAuthData)
            RETURN .F.
         ENDIF
         * Step 3 - Retrieve Has Error property of auth data
         llHasError = THIS._GetNETObjectProperty(m.loAuthData, 'HasError')
         IF ISNULL(m.llHasError)
            RETURN .F.
         ENDIF
         * Step 4 - Handle error from the API side
         IF llHasError
            LOCAL loInfo, lcErrMsg, lnErrCode, lcErrCodeDesc
            * Retrieve VFP object with info about Auth Data record we have
            loInfo = THIS._GetPopulatedAuthDataInfo(m.loAuthData)
            IF NOT THIS.IsValidObject(m.loInfo)
               RETURN .F.
            ENDIF
            * Gather error fields
            lcErrMsg      = m.loInfo.cErrMsg
            lnErrCode     = ALLTRIM(TRANSFORM(m.loInfo.nErrCode))
            lcErrCodeDesc = m.loInfo.cErrCodeDesc
            * Do we need authorization / consent?
            IF loInfo.llEGrp_NeedAuth
               LOCAL lcMsg
               lcMsg = ''
               * First time we're asking for auth consent?
               IF NOT llAuthGiven
                  * Token Info Not Found - Initial authorization required
                  IF loInfo.llAccessTokenNotFound
                     lcMsg = 'In order to access your Quickbooks Online data, you must first provide consent.' + CRLF + ;
                        'Click OK to launch our website which will connect your data to this application.'
                  ELSE
                     * Refresh Expired - Authorization required again
                     IF loInfo.llRefreshTokenExpired
                        lcMsg = 'Your Quickbooks Online authorization has expired.' + CRLF + ;
                           'You will need to provide consent again to share your data. ' + CRLF + ;
                           'Click OK to launch our website which will connect your data to this application.'
                        * Unknown issue - just abort
                     ELSE
                        lcErrMsg = 'Error Code: ' + m.lnErrCode + ' (' + lcErrCodeDesc + ')' + CRLF + lcErrMsg
                        THIS._SetErrorInfo('Authorization Error: ' + m.lcErrMsg)
                        RETURN .F.
                     ENDIF
                  ENDIF
                  * Inform user they need to visit site for consent
                  MESSAGEBOX(m.lcMsg, 64, 'Information')
                  * Auth consent provided, but some failure still occured
               ELSE
                  lcMsg = 'Failed to retrieve authorization data.' + CRLF + ;
                     'Would you like to try again?'
                  * Ask user to try again - just abort if they decline retry
                  IF MESSAGEBOX(m.lcMsg, 4 + 32, 'Please confirm') = 7
                     THIS._SetErrorInfo('Authorization Error: User declined to retry authorization process')
                     RETURN .F.
                  ENDIF
               ENDIF
               * Launch the autorization / consent / connect page
               THIS.LaunchAuthWebPage()
               * Confirm success - just abort if they say no
               lcMsg = 'Have you succesfully connected your Quickbooks Online data to this application?'
               IF MESSAGEBOX(m.lcMsg, 4 + 32, 'Please confirm') = 7
                  THIS._SetErrorInfo('Authorization Error: User did not confirm success')
                  RETURN .F.
               ENDIF
               * At this point we'll hit the DO WHILE loop again and it will verify current auth data again
               llAuthGiven = .T.
               * All other error groups - just abort
            ELSE
               lcErrMsg = 'Error Code: ' + m.lnErrCode + ' (' + lcErrCodeDesc + ')' + CRLF + lcErrMsg
               * Missing Key or Invalid
               IF loInfo.llMissingData
                  IF 'is missing' $ m.lcErrMsg
                     lcErrMsg = 'Session Key is missing.' + CRLF + m.lcErrMsg
                  ELSE
                     lcErrMsg = 'Session Key is invalid.' + CRLF + m.lcErrMsg
                  ENDIF
               ENDIF
               THIS._SetErrorInfo(CRLF + 'Authorization Error: ' + CRLF + m.lcErrMsg)
               RETURN .F.
            ENDIF
            * Success - we're done
         ELSE
            llOk = .T.
         ENDIF
      ENDDO
      RETURN llOk
   ENDFUNC

   * _GetAuthInfo( object )
   * Common handler for public method of the same name
   * Difference here is we are passed a required .NET API Class instance
   FUNCTION _GetAuthInfo(toApi)
      * Require API Object
      IF NOT THIS.IsValidObject(m.toApi)
         THIS._SetErrorInfo('_GetAuthInfo Error: Must pass API object')
         RETURN .F.
      ENDIF
      LOCAL loAuth
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'GetAuthInfo'
      lcParms     = 'None'
      TRY
         ** Call API GetAuthInfo() - Must use InvokeMethod because toApi may be an entity class which has generics **
         loAuth = THIS.oShared.oBridge.InvokeMethod(toApi, 'GetAuthInfo')
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         loAuth = NULL
         ** Call succeeded, but did we get an object
      ELSE
         IF NOT THIS.IsValidObject(m.loAuth)
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
         ENDIF
      ENDIF
      RETURN loAuth   && May be NULL
   ENDFUNC

   * _GetLastAuthInfo( object )
   * Common handler for public method of the same name
   * Difference here is we are passed a required .NET API Class instance
   FUNCTION _GetLastAuthInfo(toApi)
      * Require API Object
      IF NOT THIS.IsValidObject(m.toApi)
         THIS._SetErrorInfo('_GetLastAuthInfo Error: Must pass API object')
         RETURN .F.
      ENDIF
      LOCAL loAuth
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'GetLastAuthInfo'
      lcParms     = 'None'
      TRY
         ** Call API GetLastAuthInfo() - Must use InvokeMethod because toApi may be an entity class which has generics **      
         loAuth = THIS.oShared.oBridge.InvokeMethod(toApi, 'GetLastAuthInfo')
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         loAuth = NULL
         ** Call succeeded, but did we get an object
      ELSE
         IF NOT THIS.IsValidObject(m.loAuth)
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
         ENDIF
      ENDIF
      RETURN loAuth   && May be NULL
   ENDFUNC

   * GetDLLInfo()
   * Returns formatted string with .NET Bridge DLL info or Error String on failure
   FUNCTION GetDLLInfo()
      LOCAL lcDLLInfo, lcInfo
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'GetDLLInfo'
      lcParms     = 'None'
      ** Call API GetDLLInfo() directly, no need for InvokeMethod() **
      TRY
         lcDLLInfo = THIS.oShared.oQBApi.GetDLLInfo()
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      * If call failed, return the error string
      IF m.llError
         RETURN THIS._GetErrorInfo()
         * Call succeeded but we got no info?
      ELSE
         IF THIS.IsEmptyString(m.lcDLLInfo)
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
            RETURN THIS._GetErrorInfo()
         ENDIF
      ENDIF
      * Success, create formatted string of results and return it
      lcInfo = ''
      lcInfo = m.lcInfo + 'DLL Info' + CRLF
      lcInfo = m.lcInfo + '--------' + CRLF
      lcInfo = m.lcInfo + m.lcDLLInfo
      RETURN m.lcInfo
   ENDFUNC

   * GetSessionKey()
   * Returns the session key by calling the GetSessionKey() method of the .NET Bridge DLL SWQBApi class instance
   FUNCTION GetSessionKey()
      LOCAL lcKey
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'GetSessionKey'
      lcParms     = 'None'
      ** Get the API Session Key property **
      TRY
         lcKey = THIS.oShared.oQBApi.GetSessionKey()
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         lcKey = NULL
         ** Call succeeded, but did we get an actual valid string?
      ELSE
         IF THIS.IsEmptyString(m.lcKey)
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            lcKey = NULL
         ENDIF
      ENDIF
      RETURN m.lcKey      && May be NULL
   ENDFUNC

   * SetSessionKey( string )
   * Sets the session key passed by calling the SetSessionKey() method of the .NET Bridge DLL SWQBApi class instance
   FUNCTION SetSessionKey(tcKey)
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'SetSessionKey'
      lcParms     = 'Key = ' + m.tcKey
      ** Set the API Session Key property **
      TRY
         THIS.oShared.oQBApi.SetSessionKey(m.tcKey)
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      RETURN NOT m.llError
   ENDFUNC

   * GetAllEntityNames()
   * Returns a collection of all QBO API Entity Names as defined by current QBO API Documentation
   FUNCTION GetAllEntityNames()
      LOCAL loEntityNames
      loEntityNames = CREATEOBJ('Collection')
      WITH loEntityNames
         .ADD('Account')
         .ADD('AccountListDetail')
         .ADD('APAgingDetail')
         .ADD('APAgingSummary')
         .ADD('ARAgingDetail')
         .ADD('ARAgingSummary')
         .ADD('Attachable')
         .ADD('BalanceSheet')
         .ADD('Batch')
         .ADD('Bill')
         .ADD('BillPayment')
         .ADD('Budget')
         .ADD('CashFlow')
         .ADD('ChangeDataCapture')
         .ADD('Class')
         .ADD('CompanyCurrency')
         .ADD('CompanyInfo')
         .ADD('CreditMemo')
         .ADD('CreditCardPayment')
         .ADD('Customer')
         .ADD('CustomerBalance')
         .ADD('CustomerBalanceDetail')
         .ADD('CustomerIncome')
         .ADD('FECReport')
         .ADD('CustomerType')
         .ADD('Department')
         .ADD('Deposit')
         .ADD('Employee')
         .ADD('Entitlements')
         .ADD('Estimate')
         .ADD('Exchangerate')
         .ADD('GeneralLedger')
         .ADD('GeneralLedgerFR')
         .ADD('InventoryValuationSummary')
         .ADD('Invoice')
         .ADD('Item')
         .ADD('JournalCode')
         .ADD('JournalEntry')
         .ADD('JournalReport')
         .ADD('JournalReportFR')
         .ADD('Payment')
         .ADD('PaymentMethod')
         .ADD('Preferences')
         .ADD('ProfitAndLoss')
         .ADD('ProfitAndLossDetail')
         .ADD('Purchase')
         .ADD('PurchaseOrder')
         .ADD('RecurringTransaction')
         .ADD('RefundReceipt')
         .ADD('ReimburseCharge')
         .ADD('SalesByClassSummary')
         .ADD('SalesByCustomer')
         .ADD('SalesByDepartment')
         .ADD('SalesByProduct')
         .ADD('SalesReceipt')
         .ADD('TaxClassification')
         .ADD('TaxCode')
         .ADD('TaxPayment')
         .ADD('TaxRate')
         .ADD('TaxService')
         .ADD('TaxSummary')
         .ADD('TaxAgency')
         .ADD('Term')
         .ADD('TimeActivity')
         .ADD('TransactionList')
         .ADD('TransactionListByVendor')
         .ADD('TransactionListByCustomer')
         .ADD('TransactionListWithSplits')
         .ADD('Transfer')
         .ADD('TrialBalance')
         .ADD('Vendor')
         .ADD('VendorBalance')
         .ADD('VendorBalanceDetail')
         .ADD('VendorCredit')
         .ADD('VendorExpenses')
      ENDWITH
      RETURN m.loEntityNames
   ENDFUNC

   * GetCommonEntityNames()
   * Returns a collection of the common QBO API Entity Names as defined by current QBO API Documentation
   FUNCTION GetCommonEntityNames()
      LOCAL loEntityNames
      loEntityNames = CREATEOBJ('Collection')
      WITH loEntityNames
         .ADD('Account')
         .ADD('Bill')
         .ADD('Class')
         .ADD('CompanyInfo')
         .ADD('Customer')
         .ADD('Employee')
         .ADD('Estimate')
         .ADD('Invoice')
         .ADD('Item')
         .ADD('Payment')
         .ADD('Preferences')
         *.Add("ProfitAndLoss")
         .ADD('SalesReceipt')
         .ADD('TaxAgency')
         .ADD('Term')
         .ADD('Vendor')
      ENDWITH
      RETURN m.loEntityNames
   ENDFUNC

   * GetNewSessionKey()
   * Returns new key for authentication look up or null on failure
   FUNCTION GetNewSessionKey()
      LOCAL lcKey
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'GetNewSessionKey'
      lcParms     = 'None'
      ** Call API GetNewSessionKey() directly, no need for InvokeMethod() **
      TRY
         lcKey = THIS.oShared.oQBApi.GetNewSessionKey()
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         lcKey = NULL
         ** Call succeeded, but did we get an actual valid string?
      ELSE
         IF THIS.IsEmptyString(m.lcKey)
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            lcKey = NULL
         ENDIF
      ENDIF
      RETURN m.lcKey   && May be NULL
   ENDFUNC

   * LaunchAuthWebPage()
   * Launches the QBO Authorization Web Page from our custom QBO Server based on the configuration setting specifying its URL.
   * Returns .F. on error
   PROCEDURE LaunchAuthWebPage()
      LOCAL lcURL, lcKey
      lcKey = THIS.GetSessionKey()
      IF NOT THIS.IsEmptyString(m.lcKey)
         lcURL = THIS.oShared.oConfig.cAuthServerUrl + '?key=' + m.lcKey
         RETURN THIS._OpenBrowserURL(m.lcURL)
      ENDIF
      RETURN .F.
   ENDPROC

   * GetAuthInfo()
   * Returns the current authorization data model object stored in the SWQBAPI instance in .NET Bridge
   * IMPORTANT: Calling this method will automatically cause .NET Bridge class to attempt to refresh the authorization object if it has expired.
   FUNCTION GetAuthInfo()
      RETURN THIS._GetAuthInfo(THIS.oShared.oQBApi)
   ENDFUNC

   * GetLastAuthInfo()
   * Returns a copy of the last authorization data model object stored in the SWQBAPI instance in .NET Bridge
   * IMPORTANT: Unlike GetAuthInfo(), this simply returns the object even if expired.
   *           One of its primary purposes is to be able to access any error messages and codes generated
   *          from the most recent attempt to access / refresh the authorization data.
   FUNCTION GetLastAuthInfo()
      RETURN THIS._GetLastAuthInfo(THIS.oShared.oQBApi)
   ENDFUNC

   * CheckAuthorization( object (optional) )
   * Checks the state of the passed QB API Authorization data, or retrieves current one if not passed.
   * Returns .T. if everything looks good, .F. otherwise.
   * The function will attempt to resolve missing session key or expired refresh token by:
   * 1) Prompting user to authorize access to QBO
   * 2) Launch a new browser window to our QBO Auth Server
   * 3) Prompt user if successful
   * 4) Test again
   * 5) If failure again, ask to retry, and if yes jump to step 2
   FUNCTION CheckAuthorization(toAuthData)
      * Let private function do all the work
      RETURN THIS._CheckAuthorization(THIS.oShared.oQBApi, m.toAuthData)
   ENDFUNC

   * QueryJson( string )
   * Returns all entity records from given query string and returns json string results or .F. on failure **
   FUNCTION QueryJson(tcQueryString)
      LOCAL lcJSON
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'QueryJson'
      lcParms     = 'Query = ' + THIS._GetString(m.tcQueryString)
      * Must have valid parameters
      IF THIS.IsEmptyString(m.tcQueryString)
         THIS._SetErrorInfo('Missing Query String in QueryJson()')
         RETURN .F.
      ENDIF
      * Call API 
      TRY
         lcJSON = THIS.oShared.oQBApi.QueryJson(ALLTRIM(m.tcQueryString))
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         lcJSON = NULL
         ** Call succeeded, but did we get an actual string?
      ELSE
         IF THIS.IsEmptyString(m.lcJSON)
            * See if Auth Data is valid, if not, set our own error
            IF THIS._IsValidAuthData(THIS.oShared.oQBApi )
               THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            ENDIF
            lcJSON = .F.
         ENDIF
      ENDIF
      RETURN m.lcJSON   && will return .F. if any errors
   ENDFUNC

   * QueryAllJson( string )
   * Returns all entity records from given entity name and returns json string results or .F. on failure **
   FUNCTION QueryAllJson(tcEntityName)
      LOCAL lcJSON
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'QueryAllJson'
      lcParms     = 'Entity Name = ' + THIS._GetString(m.tcEntityName)
      IF THIS.IsEmptyString(m.tcEntityName)
         THIS._SetErrorInfo('Missing Entity Name in QueryJson()')
         RETURN .F.
      ENDIF
      * Call API
      TRY
         lcJSON = THIS.oShared.oQBApi.QueryAllJson(ALLTRIM(m.tcEntityName))
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         lcJSON = NULL
         ** Call succeeded, but did we get an actual string?
      ELSE
         IF THIS.IsEmptyString(m.lcJSON)
            * See if Auth Data is valid, if not, set our own error
            IF THIS._IsValidAuthData(THIS.oShared.oQBApi )
               THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            ENDIF
            lcJSON = .F.
         ENDIF
      ENDIF
      RETURN m.lcJSON   && will return .F. if any errors
   ENDFUNC

   * CreateEntityObj( string )
   * Creates and returns a new instance of a QuickBooks API Entity VFP Class Object of specified entity name string.
   * If an error occurred in creating it, returns NULL to inform caller of a problem
   **************************************
   FUNCTION CreateEntityObj(tcClass)
      **************************************
      LOCAL loEntity
      * Clear our error msg just to be safe
      THIS.cErrorMsg = NULL
      * Create new VFP instance of entity class, passing shared object to Init()
      loEntity = NEWOBJECT('QBO' + ALLTRIM(m.tcClass), 'qbentity.prg', NULL, THIS.oShared)
      * Check for an error on the entity class
      IF THIS.IsValidObject(m.loEntity) AND NOT THIS.IsEmptyString(loEntity.cErrorMsg)
         THIS._SetErrorInfo(loEntity.cErrorMsg)
      ENDIF
      * Check for an error on this class
      IF NOT THIS.IsEmptyString(THIS.cErrorMsg)
         loEntity = NULL
      ENDIF
      RETURN m.loEntity
   ENDFUNC

   * CreateInstance( string )
   * Retrieve an instance of the fully qualified .NET class specified or NULL on failure
   ************************************************************
   FUNCTION CreateInstance(tcFullClassName)
      * Create .NET class
      LOCAL loClass
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'CreateInstance'
      lcParms     = 'Full Class Name = ' + m.tcFullClassName
      TRY
         * Get an instance of the .NET Class
         loClass = THIS.oShared.oBridge.CreateInstance(m.tcFullClassName)
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         loClass = NULL
         ** Call succeeded, but did we get an object
      ELSE
         IF NOT THIS.IsValidObject(m.loClass)
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            loClass = NULL
         ENDIF
      ENDIF
      RETURN m.loClass      && May be NULL
   ENDFUNC

   * --------------------------------------------------------------------------------------------------
   * QBAPI Definition Files ( CSV & DBF )
   * --------------------------------------------------------------------------------------------------
   * The QBAPI Entities have many properties of differing types including nested object & array types.
   * To help simplify working with the entities, definition files can be generated from SWQBApi .NET DLL.
   * The .NET code generates the definitions by using reflection to crawl the entity properties and 
   * recursively parse object properties into a single line per property.
   *
   * There are 3 types of definition files that are available.
   * 1) Entity Definition
   * 2) Properties Definition
   * 3) Types Definition
   *
   * Entity Definition
   * -----------------
   * A list of QBAPI Entity properties ( TOP LEVEL ONLY ).
   * If an entity property is an object, those are not included.
   * Columns of the definition :
   * 1) Entity Name
   * 2) Property Name
   * 3) Property Type ( Short Name )
   * 4) Property Type ( Fully Qualified Name)
   *    The type values of the property as defined by C#
   *    These are usually built in C# types for simple variable types or Intuit defined types
   * 5) Base Type 
   *    The base type of the property ( same as the top level parent class in VFP )
   *    1) Built in C# simple types ( String, ValueType, Enum )
   *    2) Complex property types ( Array, Object )
   * 6) Defined In
   *    Describes where the property type is defined in ( not always populated / may be buggy )
   *    This is helpful to see when the properties are inherited from a parent class 
   *
   * Example:
   *      EntityName PropName    PropType      PropFull                      BaseType     Defined In
   *   1) Class      Name        String        System.String                 String       
   *   2) Class      SubClass    Boolean       System.Boolean                ValueType    
   *   3) Class      ParentRef   ReferenceType Intuit.Ipp.Data.ReferenceType Object       
   *   4) Class      Id          String        System.String                 String       IntuitEntity
   *   5) Class      CustomField CustomField[] Intuit.Ipp.Data.CustomField[] Array        IntuitEntity

   * Properties Definition
   * ---------------------
   * A list of QBAPI Entity properties ( ALL LEVELS INCLUDING NESTED OBJECT ).
   * If an entity property is an object, its properties are included, even if it also has nested object props.
   * Columns of the definition :
   * ( Same as Entity Definition )
   * The Defined-In property here will show what type the property was defined in 
   *
   * Example: ( See 4 & 5 for differences from Entity Definition Example )
   *      EntityName PropName        PropType      PropFull                      BaseType     Defined In
   *   1) Class      Name            String        System.String                 String       Class
   *   2) Class      SubClass        Boolean       System.Boolean                ValueType    Class
   *   3) Class      ParentRef       ReferenceType Intuit.Ipp.Data.ReferenceType Object       Class
   *   4) Class      ParentRef.name  String        System.String                 String       ReferenceType
   *   5) Class      ParentRef.Value String        System.String                 String       ReferenceType
   *   6) Class      Id              String        System.String                 String       IntuitEntity
   *   7) Class      CustomField     CustomField[] Intuit.Ipp.Data.CustomField[] Array        IntuitEntity

   * Types Definition
   * ----------------
   * A list of all properties of all C# Types used by all QBAPI Entity properties ( TOP LEVEL ONLY )
   * If a type's property is an object, those are not included.
   * Columns of the definition :
   * 1) Type Name
   * 2) Property Name
   * 3) Property Type ( Short Name )
   * 4) Property Type ( Fully Qualified Name)
   *    The type values of the property as defined by C#
   *    These are usually built in C# types for simple variable types or Intuit defined properties
   * 5) Base Type 
   *    The base type of the property which helps clarify if the property is
   *    1) Built in C# simple types ( String, ValueType, Enum )
   *    2) Complex property ( Array, Object )
   * 6) Defined In
   *    Describes where the property type is defined in ( not always populated / may be buggy )
   *    This is helpful to see when the properties are inherited from a parent class 
   *
   * Example: ( See 4 & 5 for differences from Entity Definition Example )
   *      TypeName         PropName        PropType      PropFull                      BaseType     Defined In
   *   1) ReferenceType    name            String        System.String                 String       
   *   2) ReferenceType    type            String        System.String                 String       
   *   3) ReferenceType    Value           String        System.String                 String       

   *      TypeName    PropName        PropType             PropFull                            BaseType     Defined In
   *   1) CustomField DefinitionId    String               System.String                       String       
   *   2) CustomField Name            String               System.String                       String       
   *   3) CustomField Type            CustomFieldTypeEnum  Intuit.Ipp.Data.CustomFieldTypeEnum Enum         
   *   3) CustomField AnyIntuitObject Object               System.String                       String       
   * --------------------------------------------------------------------------------------------------

   * CreateEntityDefinitionFile ( string )
   * Creates a csv file for given filename containing a definition of properties for all supported QuickBooks API Entities.
   * See "Entity Definition" description defined above
   * Returns .F. on failure
   FUNCTION CreateEntityDefinitionFile(tcFileName)
      * Create .NET Entity equivalent class
      LOCAL llOk
      LOCAL lcApiMethod, lcParms, loEx
      lcApiMethod = 'CreateIntuitEntitiesDefinitionFile'
      lcParms     = 'Filename = ' + m.tcFileName
      TRY
         * Create the definition file
         llOk = THIS.oShared.oQBApi.CreateIntuitEntitiesDefinitionFile(m.tcFileName)
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
      ENDTRY
      RETURN m.llOk
   ENDFUNC

   * CreateTypesDefinitionFile ( string )
   * Creates a csv file for given filename containing a definition of properties for all Type objects referenced in supported QuickBooks API Entities.
   * See "Types Definition" description defined above
   * Returns .F. on failure
   FUNCTION CreateTypesDefinitionFile(tcFileName)
      * Create .NET Entity equivalent class
      LOCAL llOk
      LOCAL lcApiMethod, lcParms, loEx
      lcApiMethod = 'CreateIntuitTypesDefinitionFile'
      lcParms     = 'Filename = ' + m.tcFileName
      TRY
         * Create the definition file
         llOk = THIS.oShared.oQBApi.CreateIntuitTypesDefinitionFile(m.tcFileName)
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
      ENDTRY
      RETURN m.llOk
   ENDFUNC

   * CreateEntityPropsDefinitionFile ( string )
   * Creates a csv file for given filename containing a definition of all properties for all Type objects referenced in supported QuickBooks API Entities.
   * The returned properties include object properties down the hiearchy for a complete list of accessible properties.
   * Array properties, however, do not include properties of the element type.
   * See "Properties Definition" description defined above
   * Returns .F. on failure
   FUNCTION CreateEntityPropsDefinitionFile(tcFileName)
      * Create .NET Entity equivalent class
      LOCAL llOk
      LOCAL lcApiMethod, lcParms, loEx
      lcApiMethod = 'CreateIntuitEntityPropsDefinitionFile'
      lcParms     = 'Filename = ' + m.tcFileName
      TRY
         * Create the definition file
         llOk = THIS.oShared.oQBApi.CreateIntuitEntityPropsDefinitionFile(m.tcFileName)
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
      ENDTRY
      RETURN m.llOk
   ENDFUNC

   * CreateEntityDefinitionDBF( string )
   * Same as CreateEntityDefinitionFile() but saves to DBF file using specified filename parameter
   FUNCTION CreateEntityDefinitionDBF(tcDBFName)
      LOCAL lcAlias, lcFirstFieldName, lcMethod, loSave
      lcAlias          = 'entitydefs'
      lcFirstFieldName = 'EntityName'
      lcMethod         = 'CreateEntityDefinitionFile'
      * Create save definition object 
      loSave = CREATEOBJ('SWQBApiSaveDefinition')
      * Create the definition DBF
      RETURN loSave.CreateDefinitionDBF(m.tcDBFName, m.lcAlias, m.lcFirstFieldName, m.lcMethod, THIS)
   ENDFUNC

   * CreateTypesDefinitionDBF( string )
   * Same as CreateTypesDefinitionFile() but saves to DBF file using specified filename parameter
   FUNCTION CreateTypesDefinitionDBF(tcDBFName)
      LOCAL lcAlias, lcFirstFieldName, lcMethod, loSave
      lcAlias          = 'typedefs'
      lcFirstFieldName = 'TypeName'
      lcMethod         = 'CreateTypesDefinitionFile'
      * Create save definition object 
      loSave = CREATEOBJ('SWQBApiSaveDefinition')
      * Create the definition DBF
      RETURN loSave.CreateDefinitionDBF(m.tcDBFName, m.lcAlias, m.lcFirstFieldName, m.lcMethod, THIS)
   ENDFUNC

   * CreateEntityPropsDefinitionDBF( string )
   * Same as CreateEntityPropsDefinitionFile() but saves to DBF file using specified filename parameter
   FUNCTION CreateEntityPropsDefinitionDBF(tcDBFName)
      LOCAL lcAlias, lcFirstFieldName, lcMethod, loSave
      lcAlias          = 'propdefs'
      lcFirstFieldName = 'EntityName'
      lcMethod         = 'CreateEntityPropsDefinitionFile'
      * Create save definition object 
      loSave = CREATEOBJ('SWQBApiSaveDefinition')
      * Create the definition DBF
      RETURN loSave.CreateDefinitionDBF(m.tcDBFName, m.lcAlias, m.lcFirstFieldName, m.lcMethod, THIS)
   ENDFUNC
ENDDEFINE
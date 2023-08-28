***************************************************************************************************
* SWQBApi Entity Class Library ( Sherware Quick Books API )
* Wrapper VFP class around custom SWQBApi .NET DLL.
*
* Author: Steve Ellenoff ( sjellenoff@whitelightcomputing.com )
***************************************************************************************************
#INCLUDE "SWQBApi.h"

************************************************************
* SWQBApi Entity Base Class
************************************************************
DEFINE CLASS QBEntity AS SWQBApi
   *** Settings that should not change ***
   lInitParmVarType       = 'O'   && Object
   cInitParmMissingMsg    = 'Missing Shared Object in QBEntity based class _Setup().'   && Shared object should be passed
   cEntityName            = ''            && Must be populated by Subclass
   oEntityFieldDefinition = NULL   && Collection of Entity Field Names and Field Types
   oEntityClass           = NULL            && Holds an instance of the .NET Class correlating to this entity
   *** Variables & Object references that will change ***
   cDefinitionType = 'ALL'         && Include "All" property definitions instead of just TOP LEVEL
   cDefBlackList   = ''            && Comma delimited list of fields to blacklist for property definition columns
   cDefWhiteList   = ''            && Comma delimited list of fields to whitelist for property definition columns
   cDefBWType      = 'WHITE'         && Use White List by default
   ********************************************************************************************************

   * oEntityClass Access
   * Lazy loads an instance of .NET Entity Class and returns the reference to it
   FUNCTION oEntityClass_Access
      IF NOT THIS.IsValidObject(THIS.oEntityClass)
         THIS.oEntityClass = THIS._GetNETEntityClass(THIS.cEntityName)
      ENDIF
      RETURN THIS.oEntityClass
   ENDFUNC

   * oEntityFieldDefinition Access
   * Lazy loads the Entity Field Definition
   FUNCTION oEntityFieldDefinition_Access
      IF NOT THIS.IsValidObject(THIS.oEntityFieldDefinition)
         * Create the collection
         THIS.oEntityFieldDefinition = CREATEOBJ('Collection')
         * Populate the collection
         THIS._DefineFields()
      ENDIF
      RETURN THIS.oEntityFieldDefinition
   ENDFUNC

   * Setup( object )
   * Called internally when class is instantiated
   * Overrides parent class
   PROCEDURE _Setup(tParm)
      LOCAL loShared

      * TODO - consider refactor to avoid this scenario
      * Call parent first
      ** don't do this, parent will try to setup DOTNET BRIDGE again
      **IF !DODEFAULT(tParm)
      ** Instead call the ultimate base class
      IF NOT SWQBApiBase::_Setup(tParm)
         RETURN .F.
      ENDIF

      * Parameter should be an object
      loShared = m.tParm

      * Store shared object
      THIS.oShared = m.loShared
   ENDPROC

   * Cleanup()
   * Called internally when class destroy event occurs
   * Overrides parent class
   PROCEDURE _Cleanup()
      * Release references
      THIS.oEntityClass           = NULL
      THIS.oEntityFieldDefinition = NULL
      * Call parent which will clean up object references at the base class level
      ** DO NOT DO THIS - IT KILLS oBridge & oQBAPi on the parent - whoops..
      ** DODEFAULT()
   ENDPROC

   * _DefineFields()
   * Populates the entity field definition collection
   PROCEDURE _DefineFields()
      LOCAL lcEntityAlias, lcType, lcName, lcBase, lcVFPType

      lcEntityAlias = 'csrEntityFields'
      USE IN SELECT('entitydefs')
      USE IN SELECT('propdefs')

      * Adjust definition source based on current type specified
      IF ALLTRIM(UPPER(THIS.cDefinitionType)) = 'TOP'
         * Open entity definition file if not open
         IF NOT USED('entitydefs')
            USE entitydefs IN 0 SHARED
         ENDIF

         * Grab this entity definition records from entity definition dbf
         SELECT  propname, ;
                 proptype, ;
                 basetype ;
             FROM entitydefs ;
             WHERE entityname = THIS.cEntityName ;
             ORDER BY propname ;
             INTO CURSOR &lcEntityAlias
         * "ALL"
      ELSE
         * Open entity definition file if not open
         IF NOT USED('propdefs')
            USE propdefs IN 0 SHARED
         ENDIF

         * Grab this entity definition records from entity definition dbf
         SELECT  propname, ;
                 proptype, ;
                 basetype ;
             FROM propdefs ;
             WHERE entityname = THIS.cEntityName ;
             ORDER BY propname ;
             INTO CURSOR &lcEntityAlias
      ENDIF

      * BROW

      * Parse definition and store into collection converting to vfp data types along the way
      SCAN
         lcName = ALLTRIM(EVAL(m.lcEntityAlias + '.propname'))
         lcType = UPPER(ALLTRIM(EVAL(m.lcEntityAlias + '.proptype')))
         lcBase = UPPER(ALLTRIM(EVAL(m.lcEntityAlias + '.basetype')))
         * Convert to VFP types from .NET Types
         DO CASE
               * String
            CASE m.lcBase == 'STRING'
               lcVFPType = 'C'   && Character
               * ValueType ( several built in .NET Types )
            CASE m.lcBase == 'VALUETYPE'
               DO CASE
                  CASE m.lcType == 'BOOLEAN'
                     lcVFPType = 'L'   && Logical
                  CASE m.lcType == 'DECIMAL'
                     lcVFPType = 'Y'   && Currency
                  CASE m.lcType == 'INT32'
                     lcVFPType = 'I'   && Integer
                  CASE m.lcType == 'DATETIME'
                     lcVFPType = 'T'   && DateTime
                  OTHERWISE
                     SET STEP ON
               ENDCASE
               * Enum ( a special kind of number in .NET )
            CASE m.lcBase == 'ENUM'
               lcVFPType = 'I'   && Integer
               * Object
            CASE m.lcBase == 'OBJECT'
               lcVFPType = 'O'   &&    Not a real VFP Type
               * Array
            CASE m.lcBase == 'ARRAY'
               lcVFPType = 'A'   &&    Not a real VFP Type
               * Empty Base
            CASE EMPTY(m.lcBase)
               * Type may be an object
               IF m.lcType == 'OBJECT'
                  lcVFPType = 'O'   &&    Not a real VFP Type
               ENDIF
               * Intuit Entity ( special QBO base type )
            CASE m.lcBase == 'INTUITENTITY'
               lcVFPType = 'O'   &&    Not a real VFP Type
            OTHERWISE
               SET STEP ON
         ENDCASE
         THIS.oEntityFieldDefinition.ADD(m.lcVFPType, m.lcName)
      ENDSCAN
      USE IN SELECT(m.lcEntityAlias)
   ENDPROC

   * _GetNETEntityClass()
   * Retrieve an instance of the .NET Entity class that corresponds to this entity or NULL on failure
   FUNCTION _GetNETEntityClass(tcEntityName)
      * Create .NET Entity equivalent class
      LOCAL loEntity
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'CreateEntityObj'
      lcParms     = 'Entity = ' + THIS.cEntityName

      TRY
         * Get an instance of the .NET Entity Class
         loEntity = THIS.oShared.oQBApi.CreateEntityObj(THIS.cEntityName)
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         loEntity = NULL
         ** Call succeeded, but did we get an object
      ELSE
         IF NOT THIS.IsValidObject(m.loEntity)
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            loEntity = NULL
         ENDIF
      ENDIF
      RETURN m.loEntity      && May be NULL
   ENDFUNC

   * _GetApiErrorMessage()
   * Private wrapper function to return the .NET API Error Message String
   * Overrides parent class
   FUNCTION _GetApiErrorMessage
      IF THIS.IsValidObject(THIS.oEntityClass)
         LOCAL lcErrMsg
         * Retrieve the error message - Must use InvokeMethod because accessing the formerly public ErrorMsg property crashed VFP, likely due to entity class using generics
         lcErrMsg = THIS.oShared.oBridge.InvokeMethod(THIS.oEntityClass, 'GetErrorMsg')
         IF NOT THIS.IsEmptyString(m.lcErrMsg)
            RETURN m.lcErrMsg
         ELSE
            RETURN 'Unknown Entity Class Error!'
         ENDIF
      ELSE
         RETURN DODEFAULT()
      ENDIF
   ENDFUNC

   * _GetFieldProp( object, string )
   * Returns the value of given object and property name
   * Recursively handles properties that are objects
   * Example for string: MetaData.CreatedByRef.Value
   FUNCTION _GetFieldProp( toObj, tcPropName )
      LOCAL lVal, lnDotAt
      * Check for null object
      IF ISNULL(m.toObj)
         RETURN '_GetFieldProp() received null object'
      ENDIF
      * Check for string ( can be returned from recursive call error )
      IF VARTYPE(m.toObj) = 'C'
         RETURN m.toObj
      ENDIF
      * Special handling if the property name is for an object ( has a dot in the name )
      lnDotAt = AT('.', m.tcPropName)
      IF m.lnDotAt > 0
         LOCAL loObj, lcPropBase, lcPropChild, llError
         * Extract base object name and the property name of that base object
         lcPropBase  = LEFT(m.tcPropName, m.lnDotAt - 1)
         lcPropChild = SUBSTR(m.tcPropName, m.lnDotAt + 1)
         * Get the base object
         TRY
            loObj = EVAL('toObj.' + m.lcPropBase)
         CATCH
            llError = .T.
            loObj   = 'Property name: ' + m.lcPropBase + ' not found!'
         ENDTRY
         * Check for error
         IF m.llError
            RETURN m.loObj
         ENDIF
         * If base object is null, we're done..
         IF ISNULL(m.loObj)
            RETURN m.lcPropBase + ' is null'
            * Base object valid, recursively retrieve the value of the property
         ELSE
            RETURN THIS._GetFieldProp( m.loObj, m.lcPropChild )
         ENDIF
      ENDIF
      * Return the value of the property of passed object
      TRY
         lVal = EVAL('toObj.' + m.tcPropName)
      CATCH
         lVal = 'Property name: ' + m.tcPropName + ' not found!'
      ENDTRY
      RETURN m.lVal
   ENDFUNC

   * _GetFieldPropNRC( object, string )
   * Returns the value of given object and property name
   * Handles properties that are objects but w/o using recursion
   * Example for string: MetaData.CreatedByRef.Value
   FUNCTION _GetFieldPropNRC(toObj, tcPropString)
      LOCAL lnPos, loObj, lnProp, lcProp, loEx
      loEx = NULL
      * Set initial object and property settings from passed object and property string
      loObj  = m.toObj
      lcProp = ALLTRIM(m.tcPropString)
      * Find first period ( if any )
      lnPos = AT('.', m.tcPropString)
      DO WHILE m.lnPos > 0
         * Get property & remove it from prop string
         lcProp         = SUBSTR(m.tcPropString, 1, m.lnPos - 1)
         m.tcPropString = SUBSTR(m.tcPropString, m.lnPos + 1)
         * Get specified property of current object
         TRY
            lVal = EVAL('m.loObj.' + m.lcProp)
         CATCH TO m.loEx
         ENDTRY
         * Check for exception or property value of null
         IF NOT ISNULL(m.loEx) OR ISNULL(m.lVal)
            RETURN NULL
         ENDIF
         * Set object to value of property 
         * NOTE: May not be an object ( which is fine )
         loObj = m.lVal
         * Find first period ( if any )
         lnPos = AT('.', m.tcPropString)
         IF m.lnPos < 1
            * Get final property
            lcProp = ALLTRIM(m.tcPropString)
         ENDIF
      ENDDO
      * Get specified property of current object
      TRY
         lVal = EVAL('m.loObj.' + m.lcProp)
      CATCH TO m.loEx
      ENDTRY
      * If we got an exception return null
      IF ISNULL(m.loEx)
         RETURN m.lVal
      ENDIF
      RETURN NULL
   ENDFUNC

   *** PUBLIC METHODS ***

   * Set Definition Type ( string )
   * Sets the Definition Type which controls which definition file is used
   * Values are TOP_ONLY, ALL
   PROCEDURE SetDefinitionType(tcType)
      * Clear object so it will repopulate with new settings when next accessed
      THIS.oEntityFieldDefinition = NULL
      IF ALLTRIM(UPPER(EVL(m.tcType, ''))) == 'TOP_ONLY'
         THIS.cDefinitionType = 'TOP'
      ELSE
         THIS.cDefinitionType = 'ALL'
      ENDIF
   ENDPROC

   * Set Definition Black/White List Type ( string )
   * Sets the Definition Black/White List Type which controls which entity definition properties are
   * included when using ObjToCursor() or PrintRecord()
   * Values are WHITE,BLACK
   PROCEDURE SetBWType(tcType)
      IF ALLTRIM(UPPER(EVL(m.tcType, ''))) == 'BLACK'
         THIS.cDefBWType = 'BLACK'
      ELSE
         THIS.cDefBWType = 'WHITE'
      ENDIF
   ENDPROC

   * Set Definition White List ( string )
   * Sets the Definition White List to passed comma delimited property names
   * Only property names passed here will be included when using ObjToCursor() or PrintRecord()
   PROCEDURE SetDefWhiteList(tcProps)
      THIS.cDefWhiteList = m.tcProps
   ENDPROC

   * Set Definition Black List ( string )
   * Sets the Definition Black List to passed comma delimited property names
   * All property names except those passed here will be included when using ObjToCursor() or PrintRecord()
   PROCEDURE SetDefBlackList(tcProps)
      THIS.cDefBlackList = m.tcProps
   ENDPROC

   * Definition Black/White Property Include Check ( string )
   * Determines if the passed property name should be included based on current black or white list 
   * type set and the property list for the current black or white list.
   * NOTE: If the current list is empty, the black or white list is disabled and will include all properties
   PROCEDURE DefBWPropInclude(tcProp)
      LOCAL lcProp, lcList, llWhite, llInclude
      * Trim and upper the property for comparison later
      lcProp = UPPER(ALLTRIM(m.tcProp))
      * If empty, we're done
      IF EMPTY(m.lcProp)
         RETURN .F.
      ENDIF
      * Are we using BLACK list?
      llBlack = THIS.cDefBWType = 'BLACK'
      * Get the current list based on current b/w type setting
      lcList = UPPER(ALLTRIM(IIF(m.llBlack, THIS.cDefBlackList, THIS.cDefWhiteList)))
      * If the list is empty property is allowed
      IF EMPTY(m.lcList)
         RETURN .T.
      ENDIF
      * Replace . with _ for property name since . is not valid as column name
      m.lcProp = STRTRAN(m.lcProp, '.', '_')
      * Add comma to beginning of property name for easier comparision
      IF LEFT(m.lcProp, 1) # ','
         lcProp = ',' + m.lcProp
      ENDIF
      * Add comma to end of property name for easier comparision
      IF RIGHT(m.lcProp, 1) # ','
         lcProp = m.lcProp + ','
      ENDIF
      * Convert comma space to comma for easier comparision
      lcList = STRTRAN(m.lcList, [, ], [,])
      * Add comma to beginning of list for easier comparision
      IF LEFT(m.lcList, 1) # ','
         lcList = ',' + m.lcList
      ENDIF
      * Add comma to end of list for easier comparision
      IF RIGHT(m.lcList, 1) # ','
         lcList = m.lcList + ','
      ENDIF
      * Black List ( property not included if found in the black list )
      IF m.llBlack
         llInclude = NOT (m.lcProp $ m.lcList)
         * White List ( property included if found in the white list )
      ELSE
         llInclude = (m.lcProp $ m.lcList)
      ENDIF
      RETURN m.llInclude
   ENDPROC

   * Print Record( object )
   * Prints out all property names and values of the passed entity object for this class based on the list of fields defined
   * NOTE: For array objects it will simply list the value as "Array"
   PROCEDURE PrintRecord(toRecord)
      LOCAL lnLoop, lnLen, lcProp, tcType, lVal, loFields
      TRY
         * Get reference to field definition ( we do this to avoid access method firing every time during loop below )
         loFields = THIS.oEntityFieldDefinition
         lnLen    = loFields.COUNT
         FOR m.lnLoop = 1 TO m.lnLen
            * Extract Field Name and Field Type from Definition
            lcProp = loFields.GETKEY(m.lnLoop)
            * Must have valid property name
            IF NOT THIS.IsEmptyString(m.lcProp)
               * Check against black/white list and skip if property should not be included
               IF NOT THIS.DefBWPropInclude(m.lcProp)
                  LOOP
               ENDIF
               lcType = LOWER(ALLTRIM(loFields.ITEM(m.lnLoop)))
               * Extract the value from the object for given field name
               lVal = THIS._GetFieldProp( m.toRecord, m.lcProp )
               * Handle null
               IF ISNULL(m.lVal)
                  lVal = 'null'
               ENDIF
               * Print the value
               ? m.lcProp + ' = ' + ALLTRIM(TRANSFORM(m.lVal))
            ELSE
               lcErr = 'Invalid property retrieved from entity field definition.'
            ENDIF
         ENDFOR
      CATCH TO loEx
         lcErr = loEx.MESSAGE
      ENDTRY
   ENDPROC

   * Print Records ( array of objects )
   PROCEDURE PrintRecords(toRecords)
      LOCAL lnLoop, lnCount, loRecord, lcErr
      lcErr   = ''
      lnCount = toRecords.COUNT
      * Loop through array ( zero based )
      FOR lnLoop = 0 TO m.lnCount - 1
         loRecord = m.toRecords.ITEM[m.lnLoop]
         IF THIS.IsValidObject(loRecord)
            THIS.PrintRecord(m.loRecord)
         ELSE
            lcErr = 'Failed to retrieve record for index: ' + ALLTRIM(TRANSFORM(m.lnLoop))
            EXIT
         ENDIF
      ENDFOR
      RETURN m.lcErr
   ENDPROC

   * Hyrdate Record( object )
   * Forces VFP to evaluate the .NET object based on the field definitions, but doesn"t do anything with them.
   * This somehow hydrates the values, allowing AMEMBERS() to access the properties of the object correctly.
   * This is really only needed ( so far ) to allow ObjToCursor()/ObjArrayToCursor() to work as written.
   * Alternatively we could rewrite those functions to not use amembers, and simply use field definitions instead as this func does.
   PROCEDURE HydrateRecord(toRecord)
      LOCAL lnLoop, lnLen, lcField, tcType, lVal, loFields
      * Get reference to field definition ( we do this to avoid access method firing every time during loop below )
      loFields = THIS.oEntityFieldDefinition
      lnLen    = loFields.COUNT
      FOR m.lnLoop = 1 TO m.lnLen
         * Extract Field Name and Field Type from Definition
         lcField = loFields.GETKEY(m.lnLoop)
         lcType  = UPPER(ALLTRIM(loFields.ITEM(m.lnLoop)))
         * Extract the value from the object for given field name, but don't do anything with it.
         lVal = EVAL('toRecord.' + m.lcField)
      ENDFOR
   ENDPROC

   * ObjToCursor( object, string, numeric )
   * Given an object and cursor alias name, this function creates the cursor if cursor not already open and inserts a new record from all properties of the object.
   * Optionally takes data session # to use for result cursor to be created in.
   * Returns error message on failure
   FUNCTION ObjToCursor(toObj, tcAlias, tnDataSession)
      LOCAL loEx, lcErr, loFields
      LOCAL lnLoop, lcType, lcProp, lnNumFields, lcCreate, lcVal
      LOCAL lnCurSession, lnNewDataSession, llChangeDataSession
      * Clear out vars
      STORE '' TO m.lcCreate, m.lcErr
      * Set to new data session # if passed and does not match current session
      lnCurSession = SET('DATASESSION')
      lnNewDataSession = IIF(VARTYPE(m.tnDataSession) = 'N' AND m.tnDataSession > 0, ;
           m.tnDataSession, m.lnCurSession)
      llChangeDataSession = m.lnCurSession # m.lnNewDataSession
      IF m.llChangeDataSession
         TRY
            SET DATASESSION TO (m.lnNewDataSession)
         CATCH TO loEx
            lcErr = 'Failed to set session # to ' + TRANSFORM(m.lnNewDataSession) + CRLF + loEx.MESSAGE
         ENDTRY
      ENDIF
      IF NOT EMPTY(m.lcErr)
         RETURN m.lcErr
      ENDIF
      TRY
         * Get reference to field definition ( we do this to avoid access method firing every time during loop below )
         loFields = THIS.oEntityFieldDefinition
         * Limit to 254 columns max since that is the most VFP allows for Create Cursor command
         lnNumFields = MIN(loFields.COUNT, 254)
         FOR lnLoop = 1 TO m.lnNumFields
            * Extract Field Name from Definition
            lcProp = loFields.GETKEY(m.lnLoop)
            * Must have valid property name
            IF NOT THIS.IsEmptyString(m.lcProp)
               * Check against black/white list and skip if property should not be included
               IF NOT THIS.DefBWPropInclude(m.lcProp)
                  LOOP
               ENDIF
               * Extract Field Type from Definition
               lcType = UPPER(ALLTRIM(loFields.ITEM(m.lnLoop)))
               * Special handling for character type
               IF m.lcType = 'C'
                  m.lcType = m.lcType + '(254)'   && We"ll use largest size for Char Field Type
               ENDIF
               * Replace . with _ for property name since . is not valid as column name
               m.lcProp = STRTRAN(m.lcProp, '.', '_')
               * Handle normal types ( anything other than object and array )
               IF m.lcType # 'O' AND m.lcType # 'A'
                  * Build comma delimited list of fields with their property type for create cursor
                  lcCreate = m.lcCreate + m.lcProp + ' ' + m.lcType + ' NULL, '   && Make it nullable
                  * Object & Array Types
               ELSE
                  * Build comma delimited list of fields with their property type for create cursor
                  lcCreate = m.lcCreate + m.lcProp + ' C(25), '
               ENDIF
            ELSE
               lcErr = 'Invalid property retrieved from entity field definition.'
            ENDIF
         ENDFOR
      CATCH TO loEx
         lcErr = loEx.MESSAGE
      ENDTRY

      **********************************   
      *** BUILD CREATE CURSOR STRING ***
      **********************************
      IF EMPTY(m.lcErr)
         * Strip trailing space and comma
         IF NOT EMPTY(ALLTRIM(m.lcCreate))
            lcCreate = LEFT(m.lcCreate, LEN(m.lcCreate) - 2)
         ENDIF
         lcCreate = 'CREATE CURSOR ' + m.tcAlias + ' (' + m.lcCreate + ')'
      ENDIF

      * Debugging
      * SET SAFETY OFF
      * STRTOFILE(m.lcCreate, "create.txt")
      * SET SAFETY ON

      *********************
      *** CREATE CURSOR ***
      *********************
      IF EMPTY(m.lcErr)
         IF NOT (USED(m.tcAlias))
            TRY
               &lcCreate
            CATCH TO loEx
               lcErr = 'Failed to create cursor: ' + loEx.MESSAGE
            ENDTRY
         ENDIF
      ENDIF
      **************************
      *** INSERT INTO CURSOR ***
      **************************   
      IF EMPTY(m.lcErr)
         * To avoid line too long errors, we insert from an object rather than INSERT INTO command string
         LOCAL loData, lcCmd
         * Create a data object from the newly created cursor
         SELECT (m.tcAlias)
         SCATTER MEMO BLANK NAME loData
         TRY
            * Loop over property definitions
            FOR lnLoop = 1 TO m.lnNumFields
               * Extract Field Name from Definition
               lcProp = loFields.GETKEY(m.lnLoop)
               * Must have valid property name
               IF NOT THIS.IsEmptyString(m.lcProp)
                  * Check against black/white list and skip if property should not be included
                  IF NOT THIS.DefBWPropInclude(m.lcProp)
                     LOOP
                  ENDIF
                  * Extract Field Type from Definition
                  lcType = UPPER(ALLTRIM(loFields.ITEM(m.lnLoop)))
                  * Handle normal types ( anything other than object and array )
                  IF m.lcType # 'O' AND m.lcType # 'A'
                     * Get value to populate data
                     lcVal = THIS._GetFieldPropNRC(m.toObj, m.lcProp)
                     * Object & Array Types
                  ELSE
                     * Get value to populate data
                     lcVal = IIF(m.lcType = 'O', 'Object', 'Array')
                  ENDIF
                  * Replace . with _ for property name since . is not valid as column name
                  * NOTE: This must come after call to THIS._GetFieldPropNRC() above
                  m.lcProp = STRTRAN(m.lcProp, '.', '_')
                  * Store property to the data object
                  lcCmd = 'loData.' + m.lcProp + ' = m.lcVal'
                  &lcCmd
               ELSE
                  lcErr = 'Invalid property retrieved from entity field definition.'
               ENDIF
            ENDFOR
            * Insert the data object into the cursor
            INSERT INTO (m.tcAlias) FROM NAME m.loData
         CATCH TO loEx
            lcErr = loEx.MESSAGE
         ENDTRY
      ENDIF
      * Restore original datasession if we changed it
      IF m.llChangeDataSession
         TRY
            SET DATASESSION TO (m.lnCurSession)
         CATCH TO loEx
            lcErr = 'Failed to set session # to ' + TRANSFORM(m.lnCurSession) + CRLF + loEx.MESSAGE
         ENDTRY
      ENDIF
      * Return error message if any
      RETURN lcErr
   ENDFUNC

   * ObjArrayToCursor( array of objects, string, numeric )
   * Given an array of .NET entity objects and cursor alias name, this function creates the cursor if cursor not already open and inserts a new record from all properties of the object.
   * Optionally takes data session # to use for result cursor to be created in.
   * Returns error message on failure
   FUNCTION ObjArrayToCursor(toObj, tcAlias, tnDataSession )
      LOCAL lnLoop, lnCount, loRecord, lcErr
      LOCAL lnCurSession, lnNewDataSession, llChangeDataSession
      lcErr = ''

      lnCount = toObj.COUNT

      * Set to new data session # if passed and does not match current session
      lnCurSession = SET('DATASESSION')
      lnNewDataSession = IIF(VARTYPE(m.tnDataSession) = 'N' AND m.tnDataSession > 0, ;
           m.tnDataSession, m.lnCurSession)
      llChangeDataSession = m.lnCurSession # m.lnNewDataSession
      IF m.llChangeDataSession
         TRY
            SET DATASESSION TO (m.lnNewDataSession)
         CATCH TO loEx
            lcErr = 'Failed to set session # to ' + TRANSFORM(m.lnNewDataSession) + CRLF + loEx.MESSAGE
         ENDTRY
      ENDIF
      IF NOT EMPTY(m.lcErr)
         RETURN m.lcErr
      ENDIF

      * Loop through array ( zero based )
      FOR lnLoop = 0 TO m.lnCount - 1
         loRecord = m.toObj.ITEM[m.lnLoop]
         IF THIS.IsValidObject(loRecord)
            lcErr = THIS.ObjToCursor(m.loRecord, m.tcAlias)
            IF NOT EMPTY(m.lcErr)
               EXIT
            ENDIF
         ELSE
            lcErr = 'Failed to retrieve record for index: ' + ALLTRIM(TRANSFORM(m.lnLoop))
            EXIT
         ENDIF
      ENDFOR

      IF USED(m.tcAlias)
         GO TOP IN m.tcAlias
      ENDIF
      * Restore original datasession if we changed it
      IF m.llChangeDataSession
         TRY
            SET DATASESSION TO (m.lnCurSession)
         CATCH TO loEx
            lcErr = 'Failed to set session # to ' + TRANSFORM(m.lnCurSession) + CRLF + loEx.MESSAGE
         ENDTRY
      ENDIF
      * Return error message if any
      RETURN m.lcErr
   ENDFUNC

   * CreateInstance( string )
   * Retrieve an instance of the fully qualified .NET class specified or NULL on failure
   FUNCTION CreateInstance(tcFullClassName)
      * No special behavior for now, just call the parent class
      RETURN DODEFAULT(m.tcFullClassName)
   ENDFUNC

   * CheckAuthorization( object (optional) )
   * See parent for description
   * Overrides parent class
   FUNCTION CheckAuthorization(toAuthData)
      * Let private function do all the work - we must pass the Entity Class Instance since it holds authdata related to entity functions
      RETURN THIS._CheckAuthorization(THIS.oEntityClass, m.toAuthData)
   ENDFUNC

   * GetAuthInfo()
   * See parent for description   
   * Overrides parent class
   FUNCTION GetAuthInfo()
      RETURN THIS._GetAuthInfo(THIS.oEntityClass)
   ENDFUNC

   * GetLastAuthInfo()
   * See parent for description
   * Overrides parent class
   FUNCTION GetLastAuthInfo()
      RETURN THIS._GetLastAuthInfo(THIS.oEntityClass)
   ENDFUNC

   * Get( string )
   * Returns an entity for specified Entity Id of this entity type, or NULL if not found or an error occurred
   FUNCTION GET(tcId)
      LOCAL loEntity
      LOCAL lcApiMethod, lcParms, llError, loEx
      loResults   = NULL
      lcApiMethod = 'Get'
      lcParms     = 'Id = ' + m.tcId
      TRY
         * Retrieve a single record - Must use InvokeMethod() because QBEntity class is derived from base class using generics
         loEntity = THIS.oShared.oBridge.InvokeMethod(THIS.oEntityClass, 'Get', m.tcId)
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         loEntity = NULL
         ** Call succeeded, but did we get an object
      ELSE
         IF NOT THIS.IsValidObject(m.loEntity)
            * See if Auth Data is valid, if not, set our own error
            IF THIS._IsValidAuthData(THIS.oEntityClass)
               THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            ENDIF
            loEntity = NULL
         ENDIF
      ENDIF
      RETURN m.loEntity      && May be NULL
   ENDFUNC

   * GetAll()
   * Returns an array of entity objects for all records of this entity type, or NULL if an error occurred
   FUNCTION GetAll()
      LOCAL loResults
      LOCAL lcApiMethod, lcParms, llError, loEx
      loResults   = NULL
      lcApiMethod = 'GetAll'
      lcParms     = 'None'
      TRY
         * Retrieve the results - Must use InvokeMethod because method call returns an array
         loResults = THIS.oShared.oBridge.InvokeMethod(THIS.oEntityClass, 'GetAll')
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         loResults = NULL
         ** Call succeeded, but did we get any results object
      ELSE
         IF NOT THIS.IsValidObject(m.loResults)
            * See if Auth Data is valid, if not, set our own error
            IF THIS._IsValidAuthData(THIS.oEntityClass)
               THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            ENDIF
            loResults = NULL
         ENDIF
      ENDIF
      RETURN m.loResults      && May be NULL
   ENDFUNC

   * New()
   * Returns a new empty entity object or NULL if an error occurred
   FUNCTION New()
      LOCAL loEntity
      LOCAL lcApiMethod, lcParms, llError, loEx
      lcApiMethod = 'New'
      lcParms     = 'None'
      TRY
         * Retrieve a blank new record - Must use InvokeMethod() because QBEntity class is derived from base class using generics
         loEntity = THIS.oShared.oBridge.InvokeMethod(THIS.oEntityClass, 'New')
      CATCH TO loEx
         THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
         llError = .T.
      ENDTRY
      ** Call failed, ensure null is returned
      IF m.llError
         loEntity = NULL
         ** Call succeeded, but did we get an object
      ELSE
         IF NOT THIS.IsValidObject(m.loEntity)
            * NOTE: We don't need to check for possible auth error since .NET code doesn"t access auth data for this method
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
            loEntity = NULL
         ENDIF
      ENDIF
      RETURN m.loEntity      && May be NULL
   ENDFUNC

   * Add( object )
   * Adds the passed entity object to QB and returns the new entity record recevied, or NULL if an error occurred
   FUNCTION ADD(toRecord)
      * Abort if invalid
      IF NOT THIS.IsValidObject(m.toRecord)
         THIS._SetErrorInfo('Record passed to Add() is not a valid object')
         RETURN NULL
         * Add the record passed
      ELSE
         LOCAL loEntity
         LOCAL lcApiMethod, lcParms, llError, loEx
         lcApiMethod = 'Add'
         lcParms     = 'Record = Object'
         TRY
            * Add record & retrieve the newly added record back - Must use InvokeMethod() because QBEntity class is derived from base class using generics
            loEntity = THIS.oShared.oBridge.InvokeMethod(THIS.oEntityClass, 'Add', m.toRecord)
         CATCH TO loEx
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
            llError = .T.
         ENDTRY
         ** Call failed, ensure null is returned
         IF m.llError
            loEntity = NULL
            ** Call succeeded, but did we get an object
         ELSE
            IF NOT THIS.IsValidObject(m.loEntity)
               * See if Auth Data is valid, if not, set our own error
               IF THIS._IsValidAuthData(THIS.oEntityClass)
                  THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
               ENDIF
               loEntity = NULL
            ENDIF
         ENDIF
      ENDIF
      RETURN m.loEntity      && May be NULL
   ENDFUNC

   * Update( object )
   * Updates the passed entity object to QB and returns the new entity record recevied, or NULL if an error occurred
   FUNCTION UPDATE(toRecord)
      * Abort if invalid
      IF NOT THIS.IsValidObject(m.toRecord)
         THIS._SetErrorInfo('Record passed to Update() is not a valid object')
         RETURN NULL
         * Update the record passed
      ELSE
         LOCAL loEntity
         LOCAL lcApiMethod, lcParms, llError, loEx
         lcApiMethod = 'Update'
         lcParms     = 'Record = Object'
         TRY
            * Update record & retrieve an updated one - Must use InvokeMethod() because QBEntity class is derived from base class using generics
            loEntity = THIS.oShared.oBridge.InvokeMethod(THIS.oEntityClass, 'Update', m.toRecord)
         CATCH TO loEx
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
            llError = .T.
         ENDTRY
         ** Call failed, ensure null is returned
         IF m.llError
            loEntity = NULL
            ** Call succeeded, but did we get an object
         ELSE
            IF NOT THIS.IsValidObject(m.loEntity)
               * See if Auth Data is valid, if not, set our own error
               IF THIS._IsValidAuthData(THIS.oEntityClass)
                  THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
               ENDIF
               loEntity = NULL
            ENDIF
         ENDIF
      ENDIF
      RETURN m.loEntity      && May be NULL
   ENDFUNC

   * Delete( object )
   * Deletes the passed entity object from QB and returns the deleted entity record, or NULL if an error occurred
   FUNCTION DELETE(toRecord)
      * Abort if invalid
      IF NOT THIS.IsValidObject(m.toRecord)
         THIS._SetErrorInfo('Record passed to Delete() is not a valid object')
         RETURN NULL
         * Update the record passed
      ELSE
         LOCAL loEntity
         LOCAL lcApiMethod, lcParms, llError, loEx
         lcApiMethod = 'Delete'
         lcParms     = 'Record = Object'
         TRY
            * Delete record & retrieve the deleted one - Must use InvokeMethod() because QBEntity class is derived from base class using generics
            loEntity = THIS.oShared.oBridge.InvokeMethod(THIS.oEntityClass, 'Delete', m.toRecord)
         CATCH TO loEx
            THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms, m.loEx)
            llError = .T.
         ENDTRY
         ** Call failed, ensure null is returned
         IF m.llError
            loEntity = NULL
            ** Call succeeded, but did we get an object
         ELSE
            IF NOT THIS.IsValidObject(m.loEntity)
               * See if Auth Data is valid, if not, set our own error
               IF THIS._IsValidAuthData(THIS.oEntityClass)
                  THIS._SetAPIErrorInfo(m.lcApiMethod, m.lcParms)
               ENDIF
               loEntity = NULL
            ENDIF
         ENDIF
      ENDIF
      RETURN m.loEntity      && May be NULL
   ENDFUNC
ENDDEFINE

** ENTITY W/O DIRECT DELETE SUPPORT **
DEFINE CLASS QBEntityNoDelete AS QBEntity
   * Delete( object )
   * Overrides parent - No delete support, generates an error message and returns NULL
   FUNCTION DELETE(toRecord)
      THIS._SetErrorInfo('Delete() is not supported by QB Api for this entity. Set Active property to False and Update() instead.')
      RETURN NULL
   ENDFUNC
ENDDEFINE

** QUICK BOOKS ENTITIES **

* Account
DEFINE CLASS QBOAccount AS QBEntity
   cEntityName = 'Account'
ENDDEFINE
* Bill
DEFINE CLASS QBOBill AS QBEntity
   cEntityName = 'Bill'
   * Manual simplified test code - here for reference only
   *FUNCTION QueryBill()
   *   LOCAL loResults, loRecord, loLine, lnCount, loLines
   *   loResults = THIS.oBridge.InvokeMethod(THIS.oQBApi,"QueryBill")
   *   IF VARTYPE(m.loResults) <> "O"
   *      ?"Failed for QueryBill: " + THIS.oQBApi.ErrorMsg
   *      RETURN -1
   *   ENDIF
   *   lnCount = loResults.Count
   *   ?"Results Count: " 
   *   ?m.lnCount      
   **   ?loResults
   *   loRecord = m.loResults.Item[0]
   *   IF VARTYPE(m.loRecord) <> "O"
   *      ?"No record found"
   *      RETURN -1
   *   ENDIF
   *   ?loRecord.DueDate
   *   ?loRecord.Balance
   *   ?loRecord.VendorRef.name
   *   ?loRecord.MetaData.CreateTime
   **   ?loRecord.Line[0].Id
   *   *lnCount = THIS.oBridge.InvokeStaticMethod(loRecord.Line,"Count")
   *   *lnCount = loRecord.Line.Count
   *   loLines = THIS.oBridge.GetProperty(loRecord,"Line") 
   *   lnCount = loLines.Count
   *   ?"Line Count: " 
   *   ?m.lnCount
   *   * Works but not necessary since we have loLines now
   *   *loLine = THIS.oBridge.GetArrayItem(loRecord,"Line",0)
   *   FOR lnLoop = 1 TO m.lnCount
   *      loLine = loLines.Item(m.lnLoop - 1)
   *      *?loLine 
   *      IF VARTYPE(m.loLine ) <> "O"
   *         ?"No line object found"
   *         RETURN -1
   *      ENDIF
   *      ?"Line Item #" + ALLTRIM(TRANSFORM(m.lnLoop))
   *      ?loLine.Id
   *      ?loLine.Description
   *      ?loLine.Amount
   *      ?loLine.AnyIntuitObject.ItemRef.name
   *      ?
   *   ENDFOR
   *ENDFUNC

   *FUNCTION BillUpdate()
   *   LOCAL loResults, loRecord, loLine, lnCount, loLines, loVA
   *   loResults = THIS.oBridge.InvokeMethod(THIS.oQBApi,"QueryBill")
   *   IF VARTYPE(m.loResults) <> "O"
   *      ?"Failed for QueryBill: " + THIS.oQBApi.ErrorMsg
   *      RETURN -1
   *   ENDIF

   *   loVA = THIS.oBridge.CreateInstance("Intuit.Ipp.Data.PhysicalAddress")
   *   loVA.Line1 = "2310 Fenhurst Pl."
   *   loVA.City = "Atlanta"
   *   loVA.CountrySubDivisionCode = "GA"
   *   loVA.PostalCode = "30338"

   *   lnCount = loResults.Count
   *   ?"Results Count: " 
   *   ?m.lnCount      
   **   ?loResults
   *   loRecord = m.loResults.Item[0]
   *   IF VARTYPE(m.loRecord) <> "O"
   *      ?"No record found"
   *      RETURN -1
   *   ENDIF
   *   ?loRecord.DueDate
   *   ?loRecord.Balance
   *   ?loRecord.VendorRef.name
   *   ?loRecord.MetaData.CreateTime
   **   ?loRecord.Line[0].Id
   *   *lnCount = THIS.oBridge.InvokeStaticMethod(loRecord.Line,"Count")
   *   *lnCount = loRecord.Line.Count

   *   loRecord.DueDate = DATETIME()
   *   loRecord.VendorRef.name = "Bonnie Ellenoff"
   *   loRecord.Balance = CAST(12.23 AS Currency)
   *   loRecord.VendorAddr = m.loVA
   *   loRecord.VendorRef.value = "56"


   *   loLines = THIS.oBridge.GetProperty(loRecord,"Line") 
   *   lnCount = loLines.Count
   *   ?"Line Count: " 
   *   ?m.lnCount
   *   * Works but not necessary since we have loLines now
   *   *loLine = THIS.oBridge.GetArrayItem(loRecord,"Line",0)
   *!*   FOR lnLoop = 1 TO m.lnCount
   *!*      loLine = loLines.Item(m.lnLoop - 1)
   *!*      *?loLine 
   *!*      IF VARTYPE(m.loLine ) <> "O"
   *!*         ?"No line object found"
   *!*         RETURN -1
   *!*      ENDIF
   *!*      ?"Line Item #" + ALLTRIM(TRANSFORM(m.lnLoop))
   *!*      ?loLine.Id
   *!*      ?loLine.Description
   *!*      ?loLine.Amount
   *!*      ?loLine.AnyIntuitObject.ItemRef.name
   *!*      ?
   *!*   ENDFOR      
   *   loLine = loLines.Item(0)
   *   loLine.Description = loLine.Description + " - SE "

   *   LOCAL loLine2
   *   loLine2 = THIS.oBridge.CreateInstance("Intuit.Ipp.Data.Line")      
   *   loLine2.Description = "Test Line 2"
   *   loLine2.Amount = CAST(44.64 AS Currency)
   *   loLine2.AmountSpecified = .T.

   *   loLines.AddItem(m.loLine2)
   *   loLines.AssignTo(loRecord,"Line")

   **   THIS.oQBApi.BillUpdate(m.loRecord)
   *ENDFUNC

   *FUNCTION BillCreate()
   *   LOCAL loRecord, loLine, loLines, loVA, loVR
   *   loRecord = THIS.oBridge.CreateInstance("Intuit.Ipp.Data.Bill")
   *   loVA = THIS.oBridge.CreateInstance("Intuit.Ipp.Data.PhysicalAddress")
   *   loLines = THIS.oBridge.CreateArray("Intuit.Ipp.Data.Line")
   *   loVR = THIS.oBridge.CreateInstance("Intuit.Ipp.Data.ReferenceType")

   *   loVR.name = "My Vendor"
   *   loVR.type = "Computers"
   *   loVR.Value = "Whatever!"
   *   loRecord.VendorRef = m.loVR

   *   loVA.Line1 = "2310 Fenhurst Pl."
   *   loVA.City = "Atlanta"
   *   loVA.CountrySubDivisionCode = "GA"
   *   loVA.PostalCode = "30338"

   *   loRecord.DueDate = DATETIME()
   *   loRecord.VendorRef.name = "Hana Ellenoff"
   *   loRecord.Balance = CAST(3.18 AS Currency)
   *   loRecord.VendorAddr = m.loVA
   *   loRecord.VendorRef.value = "17"

   **  Line Handling
   *   loLine = THIS.oBridge.CreateInstance("Intuit.Ipp.Data.Line")      
   *   loLine.Description = "Test Line 1"
   *   loLine.Amount = CAST(150.25 AS Currency)
   *   loLine.AmountSpecified = .T.
   **   loLine.DetailType = 2
   *   loLine.DetailType = THIS.oBridge.GetEnumValue("Intuit.Ipp.Data.LineDetailTypeEnum.AccountBasedExpenseLineDetail")
   *   loLine.DetailTypeSpecified = .T.

   *   loLines.AddItem(m.loLine)
   *   loLines.AssignTo(loRecord,"Line")

   **   THIS.oQBApi.BillUpdate(m.loRecord)
   *ENDFUNC
ENDDEFINE
* Class
DEFINE CLASS QBOClass AS QBEntityNoDelete
   cEntityName = 'Class'
ENDDEFINE
* CompanyInfo
DEFINE CLASS QBOCompanyInfo AS QBEntity
   cEntityName = 'CompanyInfo'
ENDDEFINE
* Customer
DEFINE CLASS QBOCustomer AS QBEntity
   cEntityName = 'Customer'
ENDDEFINE
* Employee
DEFINE CLASS QBOEmployee AS QBEntity
   cEntityName = 'Employee'
ENDDEFINE
* Estimate
DEFINE CLASS QBOEstimate AS QBEntity
   cEntityName = 'Estimate'
ENDDEFINE
* Invoice
DEFINE CLASS QBOInvoice AS QBEntity
   cEntityName = 'Invoice'
ENDDEFINE
* Item
DEFINE CLASS QBOItem AS QBEntity
   cEntityName = 'Item'
ENDDEFINE
* Payment
DEFINE CLASS QBOPayment AS QBEntity
   cEntityName = 'Payment'
ENDDEFINE
* Preferences
DEFINE CLASS QBOPreferences AS QBEntity
   cEntityName = 'Preferences'
ENDDEFINE
* ProfitAndLoss
DEFINE CLASS QBOProfitAndLoss AS QBEntity
   cEntityName = 'ProfitAndLoss'
ENDDEFINE
* SalesReceipt
DEFINE CLASS QBOSalesReceipt AS QBEntity
   cEntityName = 'SalesReceipt'
ENDDEFINE
* TaxAgency
DEFINE CLASS QBOTaxAgency AS QBEntity
   cEntityName = 'TaxAgency'
ENDDEFINE
* Term
DEFINE CLASS QBOTerm AS QBEntity
   cEntityName = 'Term'
ENDDEFINE
* Vendor
DEFINE CLASS QBOVendor AS QBEntity
   cEntityName = 'Vendor'
ENDDEFINE
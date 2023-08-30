*++
* CodeMine support and utility functions
*  Version 7.0
*
* Copyright 1996-2002 Soft Classics, Ltd. All rights reserved.
*--
#include "CodeMine.h"

FUNCTION CreateGlobalObject(cClassAlias, cVersion, uArg1, uArg2, uArg3, uArg4, uArg5)
*++
* Usage: CreateGlobalObject(cClassName, cVersion)
*        cClassAlias:  Logical name of the class
*        cVersion:     Minimum version required
*
* Purpose:
*  Given the name of a class, return an instance variable referencing
*  an object created from that class. If no instance exists, create one.
* 
* Returns: An object reference if an instance of the class is found or created.
*
* The idea is that (1) all objects should be fully encapsulated,
* and (2) object reference variable names shouldn't be hard-
* coded anywhere if it can possibly be avoided. When one object needs
* to communicate with a different object which it didn't create and
* therefore doesn't know what the instance variable is, we shouldn't
* have to rely on object reference variable naming conventions to
* locate the object, and we can't necessarily assume that the
* object's reference variable is even in scope.
*
* Adding each global object individualy to _SCREEN is another option, but
* that also relies on naming conventions to aviod possible name conflicts.
*
* These functions allow the Codemine classes to share common global objects
* without the risk of naming conflicts when used with other third-party classes
* or frameworks.
*-- 
LOCAL oInstance

  IF NOT PEMSTATUS(_SCREEN, 'cmGlobalObjectManager', 5)
    _SCREEN.AddObject('cmGlobalObjectManager', 'cmGlobalObjectManager')
  ENDIF

  * A no-op if no parameter, but provides an easy way to instantiate the object manager
  * without doing anything else.
  IF EMPTY(m.cClassAlias)
    RETURN .NULL.
  ENDIF

  m.oInstance = _SCREEN.cmGlobalObjectManager.CreateObject(m.cClassAlias, ;
                             PCOUNT(), @m.uArg1, @m.uArg2, @m.uArg3, @m.uArg4, @m.uArg5)

  IF NOT ISNULL(m.oInstance)
    IF NOT EMPTY(m.cVersion)
      * Ensure that we have the requested version or later.
      IF PEMSTATUS(m.oInstance, 'cVersion', 5)
        IF VAL(m.oInstance.cVersion) < VAL(m.cVersion)
          ERROR 'CreateGlobalObject: Class ' + m.oInstance.Class + ' version is ' + m.oInstance.cVersion + ', but required version is ' + m.cVersion
        ENDIF
      ENDIF
    ENDIF
  ENDIF
  RETURN m.oInstance
ENDFUNC


FUNCTION FindGlobalObject(cClassAlias, cVersion, lRequired)
*++
* Find a global instance, but don't create one if not found.
*--
LOCAL oInstance

  IF PEMSTATUS(_SCREEN, 'cmGlobalObjectManager', 5)
    m.oInstance = _SCREEN.cmGlobalObjectManager.FindObject(m.cClassAlias)
  ELSE
    m.oInstance = .NULL.
  ENDIF
  IF m.lRequired AND ISNULL(m.oInstance)
    ERROR 'FindGlobalObject: No instances of class ' + m.cClassAlias + ' exist.'
  ENDIF

  * Ensure that we have the requested version or later.
  IF NOT EMPTY(m.cVersion) AND VARTYPE(m.oInstance) = 'O'
    IF VARTYPE(m.oInstance.cVersion) = 'C' AND VAL(m.oInstance.cVersion) < VAL(m.cVersion)
      ERROR 'FindGlobalObject: Class ' + m.oInstance.Class + ' version is ' + m.oInstance.cVersion + ', but required version is ' + m.cVersion
    ENDIF
  ENDIF
  RETURN m.oInstance  && Found a valid instance, return object reference.
ENDFUNC


FUNCTION ReleaseGlobalObject(cClassAlias)
*++
* Release a global instance created by the CreateGlobalObject() function.
*--
LOCAL lStatus
  * Make sure global object manager is instantiated.
  IF PEMSTATUS(_SCREEN, 'cmGlobalObjectManager', 5)
    m.lStatus = _SCREEN.cmGlobalObjectManager.ReleaseObject(m.cClassAlias)

    * Remove object manager object after global release
    IF m.lStatus AND EMPTY(m.cClassAlias)
      _SCREEN.RemoveObject('cmGlobalObjectManager')
    ENDIF
  ENDIF
  RETURN m.lStatus
ENDFUNC


FUNCTION CreateLocalized(cClassAlias, uP1, uP2, uP3, uP4, uP5, uP6, uP7, uP8, uP9)
*++
* Create an object from a localized class name.
*--
LOCAL ix, cParams, cLibrary, oMessage

  * Translate class alias into actual class name, and extract class library prefix if present.
  m.cLibrary = .NULL.
  IF PEMSTATUS(_SCREEN, 'cmGlobalObjectManager', 5)
    m.cClassAlias = _SCREEN.cmGlobalObjectManager.GetClassName(m.cClassAlias, @m.cLibrary)
  ENDIF

  * Localize the (translated) class name if message manager is available.
  m.oMessage = FindGlobalObject('cmMessage')
  IF NOT ISNULL(m.oMessage)
    m.cClassAlias = m.oMessage.LocalizeClass(m.cClassAlias)
  ENDIF

  m.cParams = ''
  FOR ix = 1 TO PCOUNT() - 1
    m.cParams = m.cParams + ', @m.uP' + STR(m.ix,1)
  ENDFOR
  RETURN NEWOBJECT(m.cClassAlias, m.cLibrary, '' &cParams)
ENDFUNC


FUNCTION CreateNewObject(cClassAlias, uP1, uP2, uP3, uP4, uP5, uP6, uP7, uP8, uP9)
*++
* Create a new instance of an object from a class name.
*--
LOCAL ix, cParams, cLibrary

  * Translate class alias into actual class name, and extract class library prefix if present.
  m.cLibrary = .NULL.
  IF PEMSTATUS(_SCREEN, 'cmGlobalObjectManager', 5)
    m.cClassAlias = _SCREEN.cmGlobalObjectManager.GetClassName(m.cClassAlias, @m.cLibrary)
  ENDIF

  m.cParams = ''
  FOR ix = 1 TO PCOUNT() - 1
    m.cParams = m.cParams + ', @m.uP' + STR(m.ix,1)
  ENDFOR
  RETURN NEWOBJECT(m.cClassAlias, m.cLibrary, '' &cParams)
ENDFUNC


FUNCTION SetClassAlias(cClassAlias, cNewName)
*++
* Global function interface for Defining a new class alias name.
*--
  IF NOT PEMSTATUS(_SCREEN, 'cmGlobalObjectManager', 5)
    _SCREEN.AddObject('cmGlobalObjectManager', 'cmGlobalObjectManager')
  ENDIF

  RETURN _SCREEN.cmGlobalObjectManager.SetClassAlias(@m.cClassAlias, @m.cNewName)
ENDFUNC


FUNCTION GetClassName(cClassAlias, cLibrary)
*++
* Global function interface for retrieving the actual class name for a class alias.
*--
  IF PEMSTATUS(_SCREEN, 'cmGlobalObjectManager', 5)
    RETURN _SCREEN.cmGlobalObjectManager.GetClassName(@m.cClassAlias, @m.cLibrary)
  ENDIF
  m.cLibrary = .NULL.
  RETURN m.cClassAlias
ENDFUNC


FUNCTION PrimaryKey(cWorkarea, cField, cCounter, cPrefix)
*++
* Generate a primary key value for a field. This function may be used
* as the DBC "Default" expression for a primary key field .
* This function uses the CodeMine counter keys to generate the values.
*
* Parameters:
*  cWorkarea - Workarea to generate key for.
*  cField    - Field in cWorkarea that is the primary key. Required 
*              if there is no index for the cursor defined as "Primary".
*  cCounter  - Optional name of the CodeMine Counter to use.
*  cPrefix   - Optional fixed-length string to pre-pend to generated sequential key value.
*--
  LOCAL ix, oRegistry, oKey, nType, nSelect, uKey, cTable, nPrimary

  * Fail if codemine not loaded, or if no application registry manager object
  IF 'CODEMINE.FXP' $ SET('PROC')
    m.oRegistry = FindGlobalObject('cmRegistry', '6.1')
  ENDIF
  IF NOT VARTYPE(m.oRegistry) = 'O'
    RETURN .NULL.
  ENDIF

  * Generate defaults for parameters
  IF EMPTY(m.cWorkarea)
    m.cWorkarea = ALIAS()
  ENDIF
  IF EMPTY(m.cPrefix)
    m.cPrefix= ''
  ENDIF

  * Get default counter key name to use, if not specified.
  m.nSelect = SELECT()
  IF USED(m.cWorkarea)    && ADO cWorkarea name will not be a valid WA
    SELECT (m.cWorkarea)
    m.nType = CURSORGETPROP('SourceType')
    IF EMPTY(m.cCounter)
      LOCAL cFile, cKeyPrefix
      * Default counter prefix is based on the DBC and cursor type.
      * '%' + <dbcnameFromCursor> + '!' + (IF local view or table then 'AppReg01' else 'AppRegRemote')
      m.cKeyPrefix = PROPER(JUSTSTEM(CURSORGETPROP('Database')))
      DO CASE
        CASE m.nType = 2           && Remote View
          *SQLPT cursors will have no DBC, so cKeyPrefix will be empty at this point for SQLPT.
          IF EMPTY(m.cKeyPrefix)
            m.cCounter = '%Shared' && SQLPT defaults to %Shared, since we need to link to a DBC
          ELSE
            m.cCounter = '%' + m.cKeyPrefix + '!AppRegRemote'
          ENDIF

        CASE m.nType = 1           && Local View
          * For local views, we defualt to a counter in the source table's DBC, which
          * may be different than the view's DBC.
          m.cKeyPrefix = GetToken(CURSORGETPROP("Tables"), ',')  && Only look at first table if more than one.
          IF '!' $ m.cKeyPrefix
            m.cCounter = '%' + PROPER(LEFT(m.cKeyPrefix, AT('!', m.cKeyPrefix))) + m.oRegistry.cSharedRegName
          ELSE
            m.cCounter = '%Shared' && If based of a free table, default to %Shared
          ENDIF

        CASE EMPTY(m.cKeyPrefix)     && Free Table
          * %Shared might map to remote database server, so we don't use that.
          * Instead, free tables always use appreg01 from the main DBC for the app.
          m.cCounter = '%' + JUSTSTEM(m.oRegistry.cDBCpath) + '!' + m.oRegistry.cSharedRegName

        OTHERWISE                  && Native VFP table
          m.cCounter = '%' + m.cKeyPrefix + '!' + m.oRegistry.cSharedRegName
      ENDCASE
      m.cCounter = m.cCounter + '.Counters.Primary Key '

      * Remainder of default counter name is based on table name. If a view, use the source table name.
      DO CASE
        CASE m.nType = 1   && Local View
          m.cFile = GetToken(CURSORGETPROP('Tables'), ',')
          m.cFile = SUBSTR(m.cFile, RAT('!', m.cFile) + 1)  && Strip dbc name
          m.cCounter = m.cCounter + PROPER(m.cFile)
        CASE m.nType = 2   && Remote View
          m.cFile = GetToken(CURSORGETPROP('Tables'), ',')
          m.cFile = SUBSTR(m.cFile, RAT('.', m.cFile) + 1)  && Strip table owner name
          m.cCounter = m.cCounter + PROPER(m.cFile)
        CASE m.nType = 3   && Table
          * For free tables, we need to use JUSTSTEM() to remove path info
          m.cCounter = m.cCounter + PROPER(JUSTSTEM(CURSORGETPROP('SourceName')))
      ENDCASE
    ENDIF

    * Field name defaults to the field of the primary index tag. Needed to determine key length and datatype.
    IF EMPTY(m.cField)
      DO CASE
        CASE m.nType = 3 && Table
          FOR ix = 1 TO TAGCOUNT(STRTRAN(DBF(), '.DBF', '.CDX'))
            IF PRIMARY(m.ix)
              m.cField = NORMALIZE(KEY(m.ix))
              EXIT
            ENDIF
          ENDFOR
        OTHERWISE        && Local/Remote view
          m.cField = GetToken(CURSORGETPROP('KeyFieldList'), ',')
      ENDCASE
    ENDIF
    IF EMPTY(m.cField)
      ERROR 'PrimaryKey() - No primary key found for ' + m.cWorkarea + ', cField parameter required'
      RETURN .NULL.      && No PK found
    ENDIF

    * Determine the table to use for validating the key value, so it will Resync if necessary.
    DO CASE
      CASE m.nType = 3   && Table
        m.cTable = DBF()
      CASE m.nType = 1   && Local View
        * If a local view, test the key in the source table.
        m.cTable = GetToken(CURSORGETPROP('Tables'), ',')
      OTHERWISE          && Remote view
        m.cTable = ''    && No resync currently available
    ENDCASE
  ELSE
    * Invalid workarea name. This may be an ADO cursor, so we proceed if a counter name is specified.
    IF EMPTY(m.cCounter)
      ASSERT .F. MESSAGE 'PrimaryKey() - cCounter parameter is required for ' + m.cWorkarea
      RETURN .NULL.
    ENDIF

    * Counter must already exist in this case.
    RETURN m.oRegistry.IncrementCounter(m.cCounter)
  ENDIF

  * First time a counter is used, re-sync with source table if necessary
  IF EMPTY(m.cTable) OR m.oRegistry.CounterValidated(m.cCounter)
    * Get the next counter value, creating the counter key if it doesn't exist.
    m.uKey = m.oRegistry.IncrementCounter(m.cCounter, IIF(TYPE(m.cField) = 'C', LEN(EVALUATE(m.cField)) - LEN(m.cPrefix), 10))
    IF VARTYPE(m.uKey) = 'C'
      IF NOT EMPTY(m.cPrefix)
        m.uKey = m.cPrefix + m.uKey
      ENDIF
      IF TYPE(m.cField) != 'C'
        m.uKey = INT(VAL(m.uKey))
      ENDIF
    ENDIF
  ELSE
    * Get a reference to the counter object (create counter, and possibly appreg01 table, if necessary)
    m.oKey = m.oRegistry.LockCounter(m.cCounter, IIF(TYPE(m.cField) = 'C', LEN(EVALUATE(m.cField)) - LEN(m.cPrefix), 10))
    IF ISNULL(m.oKey)
      RETURN .NULL.   && Error Finding/creating counter.
    ENDIF

    * Get the next value of the counter
    m.uKey = m.oRegistry.GetCounter(m.oKey)
    IF VARTYPE(m.uKey) = 'C'
      IF NOT EMPTY(m.cPrefix)
        m.uKey = m.cPrefix + m.uKey
      ENDIF
      IF TYPE(m.cField) != 'C'
        m.uKey = INT(VAL(m.uKey))
      ENDIF
    ENDIF

    * Now try to find the highest used key value, and re-sync counter if necessary.
    * We can't do this if a prefix is used, since prefix might affect ordering of keys.
    IF EMPTY(m.cPrefix)
      * Need to find the primary key tag number
      SELECT 0
      USE (m.cTable) AGAIN SHARED
      FOR ix = 1 TO TAGCOUNT()
        IF PRIMARY(m.ix) OR KEY(m.ix) == UPPER(m.cField)
          m.nPrimary = m.ix
          EXIT
        ENDIF
      ENDFOR

      IF NOT EMPTY(m.nPrimary)
        LOCAL cDeleted
        m.cDeleted = SET('DELETED')
        SET DELETED OFF
        SET ORDER TO (m.nPrimary)
        GO BOTTOM
        SET DELETED &cDeleted

        IF EVALUATE(KEY(m.nPrimary)) >= m.uKey
          * Store the highest used key value to the counter, then increment it.
          m.uKey = EVALUATE(KEY(m.nPrimary))
          IF VARTYPE(m.uKey) $ 'NI' AND m.oKey.nCounterFormat != COUNTER_TYPE_INT
            m.uKey = ALLTRIM(STR(m.uKey, 12))   && Convert to char format for counter functions.
          ENDIF
          m.oRegistry.SetCounter(m.oKey, m.uKey)
          m.uKey = m.oRegistry.GetCounter(m.oKey)
          IF VARTYPE(m.uKey) = 'C' AND TYPE(m.cField) != 'C'
            m.uKey = INT(VAL(m.uKey))
          ENDIF
        ENDIF
      ENDIF
      USE
    ENDIF

    * Write back the new value & unlock
    WITH m.oRegistry
      .UpdateCounter(m.oKey)
      .UnlockCounter(m.oKey)

      * This counter has been validated, mark it so we dont need to do it again this session.
      .CounterValidated(m.cCounter, .T.)
    ENDWITH
  ENDIF

  SELECT (m.nSelect)
  RETURN m.uKey
ENDFUNC   && PrimaryKey()


FUNCTION UseAgain(cWorkarea, cNewWorkarea)
*++
* Open a second workarea with the same cursor as the secified workarea.
* Apply the same SET KEY and SET FILTER settings from the original workarea.
*
* This allows you to scan through the record set without affecting any
* buffered updates in row-buffered cursors. It also prevents moving 
* related child table record pointers.
* 
* Returns the workarea alias of the new workarea, which is also the 
* selected workarea.
*--
LOCAL cFilter, lDescending, cSetKey, cSetKeyType 

  IF EMPTY(m.cWorkarea)
    m.cWorkarea = ALIAS()
  ENDIF
  IF EMPTY(m.cNewWorkarea)
    m.cNewWorkarea = SYS(2015)
  ENDIF

  SELECT (m.cWorkarea)
  m.lDescending = DESCENDING()
  m.cSetKey = SET('KEY', 1)
  IF LEN(m.cSetKey) > 0
    m.cSetKeyType = TYPE(KEY())
  ENDIF

  * Reopen the source cursor in a temporary workarea, to avoid moving child record pointers
  SELECT 0
  USE (DBF(m.cWorkarea)) AGAIN SHARED ALIAS (m.cNewWorkarea) NOREQUERY
 
  IF NOT EMPTY(ORDER(m.cWorkarea))
    IF m.lDescending
      SET ORDER TO (ORDER(m.cWorkarea)) DESCENDING
    ELSE
      SET ORDER TO (ORDER(m.cWorkarea))
    ENDIF
  ENDIF

  * Apply SET KEY filter from original workarea
  IF LEN(m.cSetKey) > 0
    IF m.cSetKeyType = 'C'
      SET KEY TO (m.cSetKey)
    ELSE
      SET KEY TO &cSetKey
    ENDIF
  ENDIF

  * Apply SET FILTER filter from original workarea
  IF NOT EMPTY(FILTER(m.cWorkarea))
    m.cFilter = FILTER(m.cWorkarea)
    SET FILTER TO &cFilter
  ENDIF
  RETURN ALIAS()
ENDFUNC


FUNCTION GetToken(cSourceLine, cDelimiter)
*++
* Return the next delimited token from the beginning of the source string.
* Parameter 'cSourceLine' is passed by reference, and is updated past the 
* returned token.
*--
LOCAL nDelim, cToken

  m.cDelimiter = IIF(VARTYPE(m.cDelimiter) != 'C', ' ', m.cDelimiter)
  m.nDelim = AT(m.cDelimiter, m.cSourceLine)
  IF (m.nDelim == 0)
     m.cToken = ALLTRIM(m.cSourceLine)
     m.cSourceLine = ''
  ELSE
     m.cToken = TRIM(LEFT(m.cSourceLine, m.nDelim - 1))
     m.cSourceLine = LTRIM(STUFF(m.cSourceLine, 1, m.nDelim + LEN(m.cDelimiter) - 1, ''))
  ENDIF
  RETURN m.cToken
ENDFUNC


FUNCTION NormalizeString(cString)
*++
* Remove space and punctuation from a string, and convert to uppercase.
* Typically used to prepare strings for comparison.
*--
  RETURN PADR(UPPER(CHRTRAN(m.cString, CHR(34) + " ~!@#$%^&()_+|-`=\:;,./<>'", '')), LEN(m.cString))
ENDFUNC


FUNCTION SoundsLike(cInString)
*++
* Return a phonetic representation of a character string.
*
*Phonetic conversion Rules:
*  cz,ci,ce,cy,cae -> Se
*  tch -> S
*  kn -> N
*  c -> K
*  wr->R
*  ph->F
*  qu->KW
*  ge,gy,gi->Je
*  gn->N
*  v,w->F
*  m->N
*  d->T
*  z->S
*  p->B
*Leading character only translations:
*  X->Z
*  a,e,i,o,u,y->A (Leading vowels are retained, but all sound alike)
*  h->H
*Interior only translations:
*  gh->ignore
*  x->KS
*--
LOCAL ix, ch, cLastCh, nStart, lHasDigit, cTempBuffer, cResult, cWord

  * We can be called as part of a table index expression, which may execute before the form Load has
  * the change to turn off "talk" in the Load() event. We need to keep it off here.
  SET TALK OFF

  m.cTempBuffer = ''
  FOR ix = 1 TO LEN(TRIM(m.cInString)) + 1
    m.ch = IIF(m.ix > LEN(m.cInString), '.', SUBSTR(m.cInString, m.ix, 1))
    IF ISALPHA(m.ch) OR ISDIGIT(m.ch) OR m.ch $ '*?'   && allow wildcards in words
      IF EMPTY(m.nStart)   && Start of a new word
        m.nStart = m.ix
        STORE .F. TO m.lHasDigit
      ENDIF
      m.lHasDigit = m.lHasDigit OR ISDIGIT(m.ch)
    ELSE
      * Came upon a word break, process any word we have been building.
      IF NOT EMPTY(m.nStart)  && If we have a word...
        m.cWord = SUBSTR(m.cInString, m.nStart, m.ix-m.nStart)
        IF NOT m.lHasDigit
          * We have isolated a word that needs analysis
          m.cWord = LOWER(m.cWord)
          m.cWord = CHRTRAN(m.cWord, 'àáâãäåæçèéêëìíîïñòóôõöùúûüý', 'aaaaaaaceeeeiiiinooooouuuuy')
          m.cWord = STRTRAN(m.cWord, 'ci', 'Se')  && Placeholder vowel removed later
          m.cWord = STRTRAN(m.cWord, 'ce', 'Se')
          m.cWord = STRTRAN(m.cWord, 'cy', 'Se')
          m.cWord = STRTRAN(m.cWord, 'cae', 'Se')
          m.cWord = STRTRAN(m.cWord, 'cz', 'S')
          m.cWord = STRTRAN(m.cWord, 'tch', 'S')
          m.cWord = STRTRAN(m.cWord, 'wr', 'R')
          m.cWord = STRTRAN(m.cWord, 'ph', 'F')
          m.cWord = STRTRAN(m.cWord, 'qu', 'KW')
          m.cWord = STRTRAN(m.cWord, 'ge', 'Je')
          m.cWord = STRTRAN(m.cWord, 'gy', 'Je')
          m.cWord = STRTRAN(m.cWord, 'gi', 'Je')
          m.cWord = STRTRAN(m.cWord, 'gn', 'N')
          m.cWord = STRTRAN(m.cWord, 'kn', 'N')
          m.cWord = STRTRAN(m.cWord, 'dn', 'N')
          m.cWord = CHRTRAN(m.cWord, 'cvmdzp', 'KFNTSB')

          * Special translations for leading character of a word.
          DO CASE
            CASE LEFT(m.cWord, 1) = 'x'
              m.cWord = STRTRAN(m.cWord, 'x', 'S', 1, 1)
            CASE LEFT(m.cWord, 2) = 'ps'
              m.cWord = STRTRAN(m.cWord, 'ps', 'S', 1, 1)
            CASE LEFT(m.cWord, 2) = 'pt'
              m.cWord = STRTRAN(m.cWord, 'pt', 'T', 1, 1)
          ENDCASE

          * Be careful about SUBSTR() accessing characters beyond end of string - normally it is
          * allowed, but when used in index expression the rules change for some reason.
          IF EMPTY(m.cTempBuffer)  && Only first word keeps leading vowel
            m.cWord = UPPER(CHRTRAN(LEFT(m.cWord, 1), 'aeiouyhw', 'AAAAAAAA')) + IIF(LEN(m.cWord) > 1, SUBSTR(m.cWord,2), '')
          ELSE
            * If not the first word, only leading g gets capped to prevent gh removal later.
            m.cWord = CHRTRAN(LEFT(m.cWord, 1), 'g', 'G') + IIF(LEN(m.cWord) > 1, SUBSTR(m.cWord,2), '')
          ENDIF

          * Special translations that apply only in the middle of a word.
          m.cWord = STRTRAN(m.cWord, 'gh', '')
          m.cWord = STRTRAN(m.cWord, 'x', 'KS')
        ENDIF
        m.cTempBuffer = m.cTempBuffer + m.cWord
      ENDIF
      m.nStart = 0
    ENDIF
  ENDFOR

  * Final processing of result string. Replace double letters with single & remove vowels.
  STORE '' TO m.ch, m.cLastCh, m.cResult
  FOR ix = 1 TO LEN(m.cTempBuffer)
    m.ch = SUBSTR(m.cTempBuffer, m.ix, 1)
    IF NOT UPPER(m.ch) == m.cLastCh AND NOT m.ch $ 'aeiouyhw'
      m.cResult = m.cResult + UPPER(m.ch)
    ENDIF
    m.cLastch = UPPER(m.ch)
  ENDFOR

  * Preserve original length for use in index expressions.
  RETURN PADR(m.cResult, LEN(m.cInString))
ENDFUNC


FUNCTION TagField(cTagName)
LOCAL nAt, nAtc, cExpression, nTag, cField
  * Find the field that the specified index tag is based on.
  m.cField = ''
  m.nTag = TAGNO(m.cTagName)
  IF NOT EMPTY(m.nTag)
    m.cExpression = NORMALIZE(KEY(m.nTag))

    * Find the first field delimiter, a comma or close paren, whichever comes first
    m.nAt = AT(')', m.cExpression)
    m.nAtc = AT(',', m.cExpression)
    IF m.nAtc > 0 AND m.nAtc < m.nAt
      m.nAt = m.nAtc
    ENDIF
    IF m.nAt = 0
      m.cField = m.cExpression   && Simple index with no normalization.
    ELSE
      m.cField = LEFT(m.cExpression, m.nAt - 1)
      * If simple fields are pre-pended to expression, use them instead.
      m.nAt = RAT('+', m.cField)
      IF m.nAt > 0 AND m.nAt < RAT('(', m.cField)
        m.cField = LEFT(m.cField, m.nAt - 1)
      ENDIF
      m.cField = SUBSTR(m.cField, RAT('(', m.cField) + 1)
      IF ',' $ m.cField
        m.cField = LEFT(m.cField, AT(',', m.cField) - 1)
      ENDIF
    ENDIF
  ENDIF
  RETURN IIF(NOT ISALPHA(m.cField) OR '=' $ m.cField, '', m.cField)
ENDFUNC


FUNCTION IsTable(cPath, lCleanup)
*++
* Returns true if the specified table path exists.
* Supports all syntax supported by the USE command, including the "!"
* database specifier.
*
* cPath is the name of the table/view to look for.
* lCleanup flag, if true delete table def from DBC if the DBF is no longer found.
*--
LOCAL cDBC, cName, cSelect, cDatabase, lStatus

  m.cDatabase = SET('DATABASE')

  IF '!' $ m.cPath
    * DBC name is explicitly specified.
    m.cDBC = LOWER(LEFT(m.cPath, AT('!', m.cPath) - 1))
    m.cName = LOWER(SUBSTR(m.cPath, AT('!', m.cPath) + 1))

    * DBC name must be a complete path, or just name (without extension).
    IF EMPTY(JUSTPATH(m.cDBC))
      m.cDBC = STRTRAN(m.cDBC, '.dbc', '')
    ENDIF

    IF DBUSED(m.cDBC)
      SET DATABASE TO (m.cDBC)
      m.cDBC = DBC()     && Get the full path of an open database
      SET DATABASE TO &cDatabase
    ELSE
      IF NOT '.' $ m.cDBC
        m.cDBC = FULLPATH(m.cDBC) + '.dbc'
      ENDIF
      IF NOT FILE(m.cDBC)
        RETURN .F.
      ENDIF
    ENDIF
  ELSE
    IF EMPTY(DBC()) OR '.' $ m.cPath OR '\' $ m.cPath OR ':' $ m.cPath
      IF NOT '.' $ m.cPath
        m.cPath = m.cPath + '.dbf'
      ENDIF
      RETURN FILE(m.cPath)
    ELSE
      m.cDBC = DBC()
      m.cName = LOWER(TRIM(m.cPath))
    ENDIF
  ENDIF

  * If we have a DBC, see if the table/view we are looking for is in it
  IF NOT EMPTY(m.cDBC)
    SET DATABASE TO (m.cDBC)
    IF INDBC(m.cName, 'View')
      m.lStatus = .T.   && A matching view was found 
    ELSE
      * Strip off any extension on the name, as this is not part of a DBC table name.
      m.cName = JUSTSTEM(m.cName)
      IF INDBC(m.cName, 'Table')
        * A DBC entry as a table was found. Now it must exist on disk also.
        m.cPath = DBGETPROP(m.cName, 'TABLE', 'PATH')
        m.lStatus = FILE(FULLPATH(m.cPath, m.cDBC))

        * If table is in DBC, but deleted from disk, and cleanup flag is set, remove invalid entry from the DBC.
        IF NOT m.lStatus AND m.lCleanup
          LOCAL nSelect, nID

	      * DBC has a definition for a non-existant table. We need to delete this manually, since DROP TABLE 
	      * will not work in this case, because is complains that the dbf is not found.
	      m.nSelect = SELECT()
          SELECT 0
          USE (m.cDBC) AGAIN SHARED
          LOCATE FOR TRIM(ObjectName) == m.cName AND TRIM(objecttype) == 'Table' AND NOT DELETED()
          IF FOUND()  && Should always be found
            m.nID = objectId
            DELETE   && Delete the table record in the DBC
            DELETE FOR parentId == m.nId
          ENDIF
          USE
          SELECT (m.nSelect)
        ENDIF
      ENDIF
    ENDIF
    SET DATABASE TO &cDatabase
  ENDIF
  RETURN m.lStatus
ENDFUNC


FUNCTION IsInDBC(cName)
*++
* Returns True if the specified table/view name is contained in the current DBC.
*--
LOCAL nSelect
  IF NOT EMPTY(DBC())
    m.nSelect = SELECT()
    SELECT 0
    USE (DBC()) AGAIN SHARED NOUPDATE
    LOCATE FOR TRIM(ObjectName) == LOWER(m.cName) AND INLIST(objecttype, 'Table', 'View') AND NOT DELETED()
    IF NOT FOUND()
      m.cName = ''
    ENDIF
    USE
    SELECT (m.nSelect)
    RETURN NOT EMPTY(m.cName)
  ENDIF
  RETURN .F.
ENDFUNC


FUNCTION DBGetFieldProp(cField, cProperty)
*++
* Get a field property via call to DBGETPROP(), making sure the correct DBC is selected.
*--
LOCAL cDBC, cOldDBC, uValue, cWorkarea

  IF '.' $ m.cField
    m.cWorkarea = LEFT(m.cField, AT('.', m.cField) - 1)
  ELSE
    m.cWorkarea = ALIAS()
  ENDIF

  * Replace alias name (if any) with actual table name in the DBC
  m.cField = CURSORGETPROP('SourceName', m.cWorkarea) + '.' + SUBSTR(m.cField, RAT('.', m.cField) + 1)

  * Make sure correct database is current, and get the specified property
  m.cDBC = CURSORGETPROP('Database', m.cWorkarea)
  IF NOT EMPTY(m.cDBC)
    m.cOldDBC = SET('DATABASE')
    SET DATABASE TO (m.cDBC)
    m.uValue = DBGETPROP(m.cField, 'Field', m.cProperty)
    IF NOT EMPTY(m.cOldDBC)
      SET DATABASE TO (m.cOldDBC)
    ENDIF
  ENDIF
  RETURN m.uValue
ENDFUNC


FUNCTION DBGetTableProp(cWorkarea, cProperty)
*++
* Get a table property via call to DBGETPROP(), making sure the correct DBC is selected.
*--
LOCAL cTable, cDBC, cOldDBC, uValue

  * Make sure correct database is current, and get the specified property
  m.cTable = CURSORGETPROP('SourceName', m.cWorkarea)
  m.cDBC = CURSORGETPROP('Database', m.cWorkarea)
  IF NOT EMPTY(m.cDBC)
    m.cOldDBC = SET('DATABASE')
    SET DATABASE TO (m.cDBC)
    m.uValue = DBGETPROP(m.cTable, 'Table', m.cProperty)
    IF NOT EMPTY(m.cOldDBC)
      SET DATABASE TO (m.cOldDBC)
    ENDIF
  ENDIF
  RETURN m.uValue
ENDFUNC

*
* Remainder of this file is class definitions
*
DEFINE CLASS cmGlobalObjectManager AS Custom
*++
* Implement the bulk of the CodeMine global object management code in this custom class.
* Each VFP object inherits the currently active datasession when it is created. By instantiating
* this global object management class before any forms are instantiated, we can allow forms
* with a private datasession to create new global objects without having them share in the form's
* private datasession. All shared global objects should be created in the default datasession (1).
*--
  lAllowClassAlias = .T.                     && If true, allow class-name alias substitution.

  FUNCTION Init
    THIS.AddProperty('aAlias[1,2]')          && Class alias names
    THIS.AddProperty('aGlobalObjects[1,2]')  && Array of global object references (col1) and name (col2)

    * Make sure we are in default data session, unless in unattended server mode.
    ASSERT SET('DataSession') = 1 OR SYS(2335) == '0' ; 
          MESSAGE 'CodeMine Global Object Manager must be created in default datasession'

    THIS.aGlobalObjects[1,1] = .NULL.
    THIS.aGlobalObjects[1,2] = ''
  ENDFUNC

  FUNCTION Error(nError, cMethod, nLine)
  *++
  * Fatal coding error - Pass it on to CodeMine error handler if available.
  * Returns .T. if user said to ignore error, or if it is an error we handle here.
  *--
  LOCAL oMessage

    m.cMsg = MESSAGE()   && Save error message text in case other call clears it.
    m.oMessage = FindGlobalObject('cmMessage')
    IF NOT ISNULL(m.oMessage)
      RETURN m.oMessage.FatalError(@m.cMsg, @m.cMethod, m.nLine)  && Usually .T. if anything
    ENDIF

    * Not in a Codemine form, or no message handler object.
    ERROR THIS.Name + ' - Error at line ' + LTRIM(STR(m.nLine)) + ' of ' + m.cMethod + CHR(13) + m.cMsg
    RETURN .F.
  ENDFUNC

  FUNCTION GetClassName(cClassAlias, cLibrary)
  *++
  * Translate a class name (which may have been mapped as an alias) to the actual class name to use.
  * Also, strip off and separate any class library prefix from the string.
  *--
  LOCAL ix, lExact

    m.cLibrary = ''
    m.ix = AT('->', m.cClassAlias)
    IF m.ix > 0
      m.cLibrary = LEFT(m.cClassAlias, m.ix - 1)
      m.cClassAlias = SUBSTR(m.cClassAlias, m.ix + 2)
    ENDIF

    IF THIS.lAllowClassAlias
      m.lExact = SET('EXACT') == 'ON'
      SET EXACT ON
      m.ix = ASCAN(THIS.aAlias, PROPER(m.cClassAlias))
      IF NOT m.lExact
        SET EXACT OFF
      ENDIF

      * If we found a match, make sure there is a corresponding new class anme to use.
      IF m.ix > 0 AND NOT EMPTY(THIS.aAlias[m.ix + 1])
        m.cClassAlias = THIS.aAlias[m.ix + 1]

        * We have found an alias, so cannot use original class library. Use one specified in alias string, if any.
        m.cLibrary = ''
        m.ix = AT('->', m.cClassAlias)
        IF m.ix > 0
          m.cLibrary = LEFT(m.cClassAlias, m.ix - 1)
          m.cClassAlias = SUBSTR(m.cClassAlias, m.ix + 2)
        ENDIF
      ENDIF
    ENDIF
    RETURN m.cClassAlias
  ENDFUNC


  FUNCTION SetClassAlias(cClassAlias, cNewName)
  *++
  * Set a new class name alias for the spacified class.
  *--
  LOCAL ix, lExact

    * Strip off any classlib prefix on stored class name string.
    m.ix = AT('->', m.cClassAlias)
    IF m.ix > 0
      m.cClassAlias = SUBSTR(m.cClassAlias, m.ix + 2)
    ENDIF

    * Look for an existing entry for this class
    m.lExact = SET('EXACT') == 'ON'
    SET EXACT ON
    m.ix = ASCAN(THIS.aAlias, PROPER(m.cClassAlias))
    IF NOT m.lExact
      SET EXACT OFF
    ENDIF

    IF m.ix > 0
      * Found existing entry for this class. Update the class name.
      THIS.aAlias[m.ix + 1] = LOWER(IIF(EMPTY(m.cNewName), '', m.cNewName))
    ELSE
      * Add a new entry into the alias array for this class name.
      IF NOT EMPTY(m.cNewName)
        IF NOT EMPTY(THIS.aAlias[1])
          m.ix = ALEN(THIS.aAlias, 1)
        ENDIF
        m.ix = m.ix + 1
        DIMENSION THIS.aAlias[m.ix, 2]
        THIS.aAlias[m.ix, 1] = PROPER(m.cClassAlias)
        THIS.aAlias[m.ix, 2] = LOWER(m.cNewName)
      ENDIF
    ENDIF
  ENDFUNC

  FUNCTION CreateObject(cClassAlias, nPcount, uArg1, uArg2, uArg3, uArg4, uArg5)
  *++
  * Create a global instance of the specified class if one does not already exist.
  *-- 
  LOCAL nIndex, lExact, cClassName, cLibrary, oInstance

    m.lExact = SET('EXACT') == 'ON'
    SET EXACT ON

    m.oInstance = .NULL.
    m.cClassAlias = PROPER(m.cClassAlias)

    * ASCAN executes 15-20 times faster than AINSTANCE, so it's much faster
    * to scan the global object array ourselves. The other benefit is that using
    * ASCAN allows us to apply 'logical names' or aliases to class names. That way
    * code written to access a particular global object can be made to use a developer
    * written subclass simply by setting the subclass name with a SetClassAlias() call.
    DO WHILE .T.
      m.nIndex = ASCAN(THIS.aGlobalObjects, m.cClassAlias)
      IF m.nIndex > 0
        m.nIndex = ASUBSCRIPT(THIS.aGlobalObjects, m.nIndex, 1)
        m.oInstance = THIS.aGlobalObjects[m.nIndex, 1]

        * If the object was released, remove the row and try again.
        IF ISNULL(m.oInstance)
          IF ALEN(THIS.aGlobalObjects, 1) = 1
            THIS.aGlobalObjects[1,2] = ''   && Clear alias name of non-existant object.
          ELSE
            ADEL(THIS.aGlobalObjects, m.nIndex)
            DIMENSION THIS.aGlobalObjects[ALEN(THIS.aGlobalObjects,1) - 1, 2]
          ENDIF
          LOOP
        ENDIF
      ENDIF
      EXIT
    ENDDO

    IF NOT m.lExact
      SET EXACT OFF
    ENDIF

    IF ISNULL(m.oInstance)
      * Look up possible alias names for the class we are instantiating.
      m.cClassName = THIS.GetClassName(m.cClassAlias, @m.cLibrary)

      * We want to make it look to the object's Init just as if we'd
      * made a normal CREATEOBJECT() call, including the value Init
      * will get from PCOUNT() or PARAMETERS(). Hence this CASE structure.
      DO CASE
        CASE m.nPcount <= 2
          m.oInstance = NEWOBJECT(m.cClassName, m.cLibrary, .NULL.)
        CASE m.nPcount = 3
          m.oInstance = NEWOBJECT(m.cClassName, m.cLibrary, .NULL., @uArg1)
        CASE m.nPcount = 4
          m.oInstance = NEWOBJECT(m.cClassName, m.cLibrary, .NULL., @uArg1,@uArg2)
        CASE m.nPcount = 5
          m.oInstance = NEWOBJECT(m.cClassName, m.cLibrary, .NULL., @uArg1,@uArg2,@uArg3)
        CASE m.nPcount = 6
          m.oInstance = NEWOBJECT(m.cClassName, m.cLibrary, .NULL., @uArg1,@uArg2,@uArg3,@uArg4)
        CASE m.nPcount >= 7
          m.oInstance = NEWOBJECT(m.cClassName, m.cLibrary, .NULL., @uArg1,@uArg2,@uArg3,@uArg4,@uArg5)
      ENDCASE

      IF VARTYPE(m.oInstance) = 'O'
        IF ALEN(THIS.aGlobalObjects,1) > 1 OR NOT EMPTY(THIS.aGlobalObjects[1, 2])
          DIMENSION THIS.aGlobalObjects[ALEN(THIS.aGlobalObjects,1) + 1, 2]
        ENDIF
        THIS.aGlobalObjects[ALEN(THIS.aGlobalObjects,1), 1] = m.oInstance
        THIS.aGlobalObjects[ALEN(THIS.aGlobalObjects,1), 2] = m.cClassAlias
      ELSE
        m.oInstance = .NULL.
      ENDIF
    ENDIF
    RETURN m.oInstance
  ENDFUNC


  FUNCTION FindObject(cClassAlias)
  *++
  * Find a global instance, but don't create one if not found.
  *--
  LOCAL oInstance, nIndex, cExact

    m.cExact = SET('EXACT')
    SET EXACT ON

    m.nIndex = ASCAN(THIS.aGlobalObjects, PROPER(m.cClassAlias))
    m.oInstance = IIF(m.nIndex < 2, .NULL., THIS.aGlobalObjects[m.nIndex - 1])

    IF m.cExact = 'OFF'
      SET EXACT OFF
    ENDIF
    RETURN m.oInstance
  ENDFUNC


  FUNCTION ReleaseObject(cClassAlias)
  *++
  * Release a global instance created by the CreateObject() method.
  *--
  LOCAL ix, nCount, nIndex, oRef

    IF EMPTY(m.cClassAlias)
      * Release all global objects, and the PUBLIC array that holds the refs.
      m.nIndex = ALEN(THIS.aGlobalObjects, 1)
      m.nCount = m.nIndex
    ELSE
      m.nIndex = ASCAN(THIS.aGlobalObjects, PROPER(m.cClassAlias))
      IF m.nIndex > 0
        m.nIndex = ASUBSCRIPT(THIS.aGlobalObjects, m.nIndex, 1)
        m.nCount = 1
      ELSE
        m.nCount = 0
      ENDIF
    ENDIF

    DO WHILE m.nCount > 0
      * Call the object's Release method if present.
      m.oRef = THIS.aGlobalObjects[m.nIndex,1]
      IF NOT ISNULL(m.oRef) 
        IF PEMSTATUS(m.oRef, 'Release', 5) 
          m.oRef.Release()
        ENDIF
      ENDIF
      m.oRef = .NULL.

      =ADEL(THIS.aGlobalObjects, m.nIndex)
      IF ALEN(THIS.aGlobalObjects,1) > 1
        DIMENSION THIS.aGlobalObjects[ALEN(THIS.aGlobalObjects,1) - 1, 2]
      ELSE
        THIS.aGlobalObjects[1, 1] = .NULL.
        THIS.aGlobalObjects[1, 2] = ''
      ENDIF
      m.nIndex = m.nIndex - 1
      m.nCount = m.nCount - 1
    ENDDO
  ENDPROC


  FUNCTION InspectorDetails(oNodes, cRoot)
  *++
  * Display object-specific information in the Codemine object inspector.
  *--
  LOCAL ix, cName, nLink, oNode, oTemp

    m.oNodes.Add(m.cRoot, 4, 'Globals', 'CodeMine Global Service Objects')
    FOR ix = 1 TO ALEN(THIS.aGlobalObjects, 1)
      m.oTemp = THIS.aGlobalObjects[m.ix, 1]
      m.cName = THIS.aGlobalObjects[m.ix, 2]
      IF TYPE('m.oTemp.Name') = 'C'
        m.cName = PROPER(m.oTemp.Name)
        IF TYPE('m.oTemp.cVersion') = 'C'
          m.cName = m.cName + ' (V' + m.oTemp.cVersion + ')'
        ENDIF
        m.oNode = .NULL.   && Helps prevent occassional obj refcount problems
        m.oNode = m.oNodes.Add('Globals', 4,, m.cName)
  
        * Store object name in the node.tag property to re-create an object reference.
        m.oNode.Tag = THIS.aGlobalObjects[m.ix, 2]
      ENDIF
    ENDFOR
    m.oNodes = .NULL.
  ENDFUNC
ENDDEFINE


DEFINE CLASS cmCallModalForm AS custom
*++
* Create a wrapper object for passing parameters into and out of modal
* form classes. A reference to this wrapper object is passed as the sole
* parameter to the form, which can then store the reference in one of
* its own properties. This makes the parameters available to all methods
* in the called form, and also provides an easy way to return values from the
* form, since the wrapper object still exists after the form is released.
*--
  nPcount = 0
  xParameter1 = .F.
  xParameter2 = .F.
  xParameter3 = .F.
  xParameter4 = .F.
  xParameter5 = .F.
  xParameter6 = .F.
  xParameter7 = .F.
  lReturnValue = .T.

  FUNCTION Init(cModalForm, p1, p2, p3, p4, p5, p6, p7)
  *++
  * Initialize the object and store parameters for the called form.
  *--
  LOCAL oForm
    THIS.nPcount = PCOUNT() - 1
    THIS.xParameter1 = m.p1
    THIS.xParameter2 = m.p2
    THIS.xParameter3 = m.p3
    THIS.xParameter4 = m.p4
    THIS.xParameter5 = m.p5
    THIS.xParameter6 = m.p6
    THIS.xParameter7 = m.p7

    m.oForm = CREATEOBJECT(m.cModalForm, THIS)
    IF TYPE('m.oForm') = 'O'
      m.oForm.Show()
    ENDIF
  ENDPROC
ENDDEFINE


* Store this here, since there is no VCX version for a Session class.
DEFINE CLASS sesPrivateSession AS Session
  * Session class for creating a private data session outside of a form.
  DataSession = 2
ENDDEFINE

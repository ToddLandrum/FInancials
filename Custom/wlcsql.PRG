**************************************************
*-- Class:        sqlparameter (c:\develop\codeminenew\dmie_rv\custom\wlcsql.prg)
*-- ParentClass:  collection
*-- BaseClass:    collection
*-- Time Stamp:   02/13/20 05:36:12 PM
*
DEFINE CLASS sqlparameter AS collection

	Height = 23
	Width = 23
	Name = "sqlparameter"


	PROCEDURE Add
		LPARAMETERS eItem, cKey, eBefore, eAfter
		******************************************************************
		*  FUNCTION NAME: Add
		*
		*  AUTHOR, DATE:
		*	  Paul Mrozowski, 1/3/2005
		*  PROCEDURE DESCRIPTION:
		*
		*  INPUT PARAMETERS:
		*	  eItem
		*     cKey
		*     eBefore
		*     eAfter
		*  OUTPUT PARAMETERS:
		*	  None
		******************************************************************
		LOCAL luRet

		* Change the parameter order so it makes more sense
		* eg. .Add("ParameterName", "ParameterValue")

		NODEFAULT

		DO CASE
		   CASE PCOUNT() = 1
		        luRet = DODEFAULT(m.cKey)
		   CASE PCOUNT() = 2
		        luRet = DODEFAULT(m.cKey, m.eItem)
		   CASE PCOUNT() = 3
		        luRet = DODEFAULT(m.cKey, m.eItem, m.eBefore)
		   CASE PCOUNT() = 4
		        luRet = DODEFAULT(m.cKey, m.eItem, m.eBefore, m.eAfter)
		ENDCASE

		RETURN m.luRet
	ENDPROC


ENDDEFINE
*
*-- EndDefine: sqlparameter
**************************************************


**************************************************
*-- Class:        wlcsql (c:\develop\codeminenew\dmie_rv\custom\wlcsql.prg)
*-- ParentClass:  wwsql (c:\develop\wconnect5\classes\wwsql.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   02/28/20 11:22:12 PM
*
DEFINE CLASS wlcsql AS wwsql


	*-- Builds a string of parameters (used for logging)
	cparamlog = ""
	*-- Name of a method to call from the oUpdateRecordCallback object for each pass through each modified record in UpdateRecord() method. This is good for providing feedback during large updates.
	cupdaterecordcallback = ""
	*-- Number of seconds it took to execute the SQL command.
	nexectime = 0
	*-- Object reference to be used in conjuction with cUpdateRecordCallback property.
	oupdaterecordcallback = .NULL.
	llogsql = .F.
	*-- If set to .T., code will not automatically call GetNewPK() after adding a new record. This is helpful when batching new records and you don't care about the PK values being generated.
	lskippkretrieveonnew = .F.
	crolename = ("approlename")
	*-- The name of a cursor being used to send CUD commands to SQL Server
	cupdatecursor = ""
	*-- The name of a  the key field for the cursor being used to send CUD commands to SQL Server
	cupdatekeyfield = ""
	*-- The name of a  the underlying table represented by the cursor being used to send CUD commands to SQL Server
	cupdatetable = ""
	cinstrumentationdatabase = ("DatabaseName")
	cinstrumentationtable = ("dbo.SQLPerformance")
	cmaptodate = ""
	crolepassword = ("approlepassword")
	*-- Populated with the new pk after a successful INSERT
	inewpk = 0
	lhandlesqlstyleparameters = .T.
	lreleasesqlhandle = .T.
	lreplaceemptydatewithnull = .T.
	*-- Insert/Update ALL records regardless of whether they've changed or not.
	lupdateallfields = .F.
	*-- Turn on/off performance logging.
	lenableinstrumentation = .T.
	*-- Set to .T. if the PK is locally generated (and needs to be included in an INSERT)
	llocallygeneratedpk = .F.
	*-- After saving, force a TABLEUPDATE so that the records are no longer flagged as new/changed.
	lupdateaftersave = .T.
	*-- # of records returned by the result of the last Execute() call.
	nreturnedrecords = 0
	*-- Note: Only supports values of 3 and 5
	nbuffermode = 5
	*-- Minimum threshold for a SQL command before the command gets logged
	ninstrumentationthresholdseconds =          2.25

	cskipfieldsforupdates = "Timestamp"

	Name = "wlcsql"
	DIMENSION askipfields[1]


	*-- About this object, author, licensing, misc
	PROCEDURE zzabout
		******************************************************************************************
		*  METHOD NAME: zzAbout
		*
		*  AUTHOR: White Light Computing, Inc.
		*
		*  FORM/CLASS DESCRIPTION:
		*    
		*    
		*  EXPLICIT LICENSE:
		*     Customers of White Light Computing are granted a perpetual, non-transferable, 
		*     non-exclusive, royalty free, worldwide license to use and employ such materials 
		*     within their business once they have paid for the right to do so.
		*
		*     No license is granted for any use outside of our customer's business 
		*     without the express written permission from White Light Computing, Inc.
		*   
		*     No license is granted to any other developer other than for use within our
		*     customer's business. Other developers wishing to license generic portions of the 
		*     source code for their own use can inquire by calling the offices of 
		*     White Light Computing, Inc.
		*
		*     (all terms are subject to change by implementation of separate contract with
		*      White Light Computing, Inc.)
		*
		*  INPUT PARAMETERS:
		*    None
		* 
		*  OUTPUT PARAMETERS:
		*    None
		* 
		******************************************************************************************
	ENDPROC


	PROCEDURE logsql
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::LogSQL
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/19/2018
		*//
		*//  COPYRIGHT © 2010-2018   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/11/2015 - SJE - Created 
		*//******************************************************************************************  
		LOCAL ;
			 loLog AS Object ;
			,loData AS Object

		*-- Get Logger Instance
		loLog = GetSQLLogger()

		*-- Get Data Object & Populate it
		loLog.GetDataObj(@m.loData)

		loData.cSQL      = This.cSQL
		loData.cParams   = This.cParamLog
		loData.nExecTime = This.nExecTime
		loData.nRecords  = This.aResults[1,2]

		*-- Log our data
		loLog.LogSQL(m.loData)

		*-- Clear obj references
		loData = NULL
		loLog = NULL

		*-- Clear cParams or other non param sql's will be logged using it's value.
		THIS.cParamLog = SPACE(0)

		RETURN 
	ENDPROC


	PROCEDURE disconnect
		*//******************************************************************************************
		*//  FUNCTION NAME: 
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/13/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Disconnect / close sql handle 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     08/06/2012 - Paul Mrozowski - Created 
		*//******************************************************************************************  

		SQLDISCONNECT(This.nSQLHandle)
	ENDPROC


	PROCEDURE getparametersasstring
		LPARAMETERS toParameters
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::GetParametersAsString() 
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/13/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Generates a string of DECLARE statements for the passed in parameters.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       toParameters
		*//
		*//    OUTPUT PARAMETERS: 
		*//       String   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     08/28/2012 - Paul Mrozowski - Created 
		*//******************************************************************************************  
		LOCAL ;
		   lnItem ;
		   ,lcParameter ;
		   ,lcParameterKey ;
		   ,lcString

		IF VARTYPE(toParameters) <> "O"
		   RETURN SPACE(0)
		ENDIF

		lcString = SPACE(0)

		FOR lnItem = 1 TO m.toParameters.Count
		    lcParameter = toParameters.Item(m.lnItem)
		    lcParameterKey = toParameters.GetKey(m.lnItem)

		    lcString = lcString ;
		             + "SET @" + m.lcParameterKey + " = " ;
		             + TRANSFORM(NVL(lcParameter, "NULL")) ;
		             + CHR(13) + CHR(10)   
		ENDFOR

		RETURN m.lcString
	ENDPROC


	PROCEDURE shareconnection
		LPARAMETERS toPrimary, toSql1, toSql2, toSql3, toSql4, toSql5, toSql6, toSql7, toSql8, toSql9, toSql10, ;
		            toSql11, toSql12, toSql13, toSql14, toSql15, toSql16, toSql17, toSql18, toSql19, toSql20, ;
		            toSql21, toSql22, toSql23
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::ShareConnection
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/13/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Make it easy to share the same connection between multiple SQL objects
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       toPrimary - Primary connection (to be shared w/the rest)
		*//       toSql1 - toSql23 - additional SQL objects
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     06/02/2010 - Paul Mrozowski - Created 
		*//******************************************************************************************  
		LOCAL ;
		    lnParameter AS Integer ;
		   ,lcSQLObj AS Character 

		FOR lnParameter = 1 TO 23
		   lcSQLObj = "toSql" + TRANSFORM(lnParameter)

		   IF VARTYPE(&lcSQLObj) = "O"
		      IF &lcSQLObj..nSQLHandle <> toPrimary.nSQLHandle
		         SQLDISCONNECT(&lcSQLObj..nSQLHandle)
		         &lcSQLObj..nSQLHandle = toPrimary.nSQLHandle
		      ENDIF
		   ENDIF
		ENDFOR
	ENDPROC


	*-- Rearrange the passed in SQL and apply the parameters.
	PROCEDURE applyparameters
		LPARAMETERS tcSQL, toParameters, toOutputParameter
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::ApplyParameters()
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/13/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Rearrange the passed in SQL and apply the parameters. 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcSQL - SQL code
		*//       toParameters - Parameter object
		*//       toOutputParameter - Output parameter object populated with key/value on exit.
		*//
		*//    OUTPUT PARAMETERS: 
		*//       lcSQL - new SQL code.
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     10/28/2004 - Paul Mrozowski - Created 
		*//******************************************************************************************  
		LOCAL ;
		    lnItem AS Integer ;
		   ,lcParameter AS Character ;
		   ,lcParameterKey AS Character ;
		   ,lcSQL AS Character 

		lcSQL = m.tcSQL

		* If the correct parameters weren't passed in, just return
		* the SQL as-is

		IF VARTYPE(toParameters) <> "O" OR VARTYPE(toOutputParameter) <> "O"
		   RETURN m.lcSQL
		ENDIF

		FOR lnItem = 1 TO m.toParameters.Count
		    lcParameter = toParameters.Item(m.lnItem)
		    lcParameterKey = toParameters.GetKey(m.lnItem)

		    ADDPROPERTY(m.toOutputParameter, m.lcParameterKey, m.lcParameter)
		    
		    * Handle either VFP parameters ? or SQL parameters @
		    lcSQL = STRTRAN(m.lcSQL, "?" + m.lcParameterKey, "?poParamItem." + m.lcParameterKey, 1, 100, 1)   
		    IF This.lHandleSqlStyleParameters 
		       lcSQL = STRTRAN(m.lcSQL, "@" + m.lcParameterKey, "?poParamItem." + m.lcParameterKey, 1, 100, 1)
		    ENDIF 
		ENDFOR

		RETURN m.lcSQL
	ENDPROC


	PROCEDURE getnewpk
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::GetNewPK()
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/13/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/13/2020 - PCM - Created 
		*//     10/13/2016 - JLM - Get the @@Identity 
		*//******************************************************************************************  
		*This.cSQL = "SELECT @@SCOPE_IDENTITY as newPK"

		*IF This.Execute("SELECT SCOPE_IDENTITY() AS iNewPK","curNewPK") > 0

		IF This.Execute("SELECT @@IDENTITY AS iNewPK","curNewPK") > 0
		   IF USED("curNewPK") AND RECCOUNT("curNewPK") = 1
		      This.iNewPK = curNewPK.iNewPK
		   ENDIF
		ENDIF
		USE IN curNewPK
	ENDPROC


	*-- Returns a parameter object
	PROCEDURE getparameterobject
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::GetParameterObject()
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/17/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Returns a parameter object. 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       Parameter object (collection)
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     10/27/2004 - Paul Mrozowski - Created 
		*//****************************************************************************************** 
		RETURN CREATEOBJECT('sqlParameter')
	ENDPROC


	PROCEDURE cskipfieldsforupdates_assign
		LPARAMETERS tcValue AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::cSkipFieldsForUpdates_Assign
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/17/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Used to exclude fields explicitly from the INSERT and UPDATE statement generation routines 
		*//    in SQLBuildInsert/UpdateStatement methods. 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcValue - Delimited list of fields to skip on updates 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/17/2020
		*//******************************************************************************************  
		This.cSkipFieldsForUpdates = m.tcValue

		ALINES(This.aSkipFields, This.cSkipFieldsForUpdates, 1 + 4, ',')
	ENDPROC


	PROCEDURE mapdates
		LPARAMETERS tcCursor AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::MapDates()
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/17/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/17/2020
		*//******************************************************************************************  
		LOCAL ;
		   laFields[1] ;
		   ,lcSQL AS Character ;
		   ,lnIndex AS Integer ;
		   ,lnMapCount AS Integer ;
		   ,llSkip AS Boolean

		IF EMPTY(This.cMapToDate)
		   RETURN
		ENDIF

		ALINES(laMap, This.cMapToDate, 1 + 4, ',')
		AFIELDS(laFields, m.tcCursor)

		lcSQL  = SPACE(0)
		llSkip = .F.

		lnMapCount = ALEN(laMap, 1)

		FOR lnIndex = 1 TO ALEN(laFields, 1)
		    IF m.lnIndex > 1
		       lcSQL = m.lcSQL + ", "
		    ENDIF

		    FOR lnMapIndex = 1 TO m.lnMapCount
		        IF LOWER(m.laFields[m.lnIndex, 1]) == LOWER(m.laMap[m.lnMapIndex])
		           lcSQL = m.lcSQL ;
		                 + "CAST(" + m.laFields[m.lnIndex, 1] + " AS D) AS " + m.laFields[m.lnIndex, 1]

		           llSkip = .T.
		           EXIT
		        ENDIF
		    ENDFOR

		    IF !m.llSkip
		       lcSQL = m.lcSQL ;
		             + m.laFields[m.lnIndex, 1]
		   ENDIF

		   llSkip = .F.
		ENDFOR

		IF !EMPTY(m.lcSQL)
		   lcSQL = "SELECT " ;
		         + m.lcSQL ;
		         + "  FROM " + m.tcCursor ;
		         + "  INTO CURSOR " + m.tcCursor ;
		         + "       READWRITE"

		   &lcSQL
		ENDIF

		RETURN
	ENDPROC


	*-- Set the current connection to use an application role.
	PROCEDURE setapplicationrole
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::SetApplicationRole()
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/17/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Set the current connection to use an application role.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       llSuccess
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     9/23/2004 - Paul Mrozowski - Created 
		*//******************************************************************************************  
		LOCAL llSuccess AS Boolean 

		llSuccess = .T.

		IF This.nSQLHandle > 0
		   * PCM - 9/13/2007 - Test, Aaron is getting C5 errors on this for some reason (intermittently)
		   *This.Execute([sp_setapprole '] + This.cRoleName + [', {Encrypt N '] + This.cRolePassword + ['}, 'odbc'], "")
		   This.Execute([sp_setapprole '] + This.cRoleName + [', '] + This.cRolePassword + ['], "")
		ENDIF

		RETURN m.llSuccess 
	ENDPROC


	PROCEDURE updatefromcursor
		LPARAMETERS ;
		    tcCursorName AS Character ;
		   ,tcTable AS Character ;
		   ,tcPKField AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::UpdateFromCursor
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/17/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    All three arguments are required 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursorName - Cursor Name
		*//       tcTable      - Table Name
		*//       tcPKField    - Primary Key Field name
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/17/2020 
		*//******************************************************************************************  
		LOCAL ;
		   lcOldDeleted AS Character ;
		   ,lcPKField AS Character ; 
		   ,llRetVal AS Boolean ;
		   ,lnOldRecNo AS Integer;
		   ,lnRecord AS Integer

		* All three arguments are required
		ASSERT PCOUNT() = 3 MESSAGE "All three arguments to this method are required - cursor name, table name and PK field name"

		This.cUpdateCursor   = m.tcCursorName
		This.cUpdateTable    = m.tcTable
		This.cUpdateKeyField = m.tcPKField

		lcOldDeleted = SET("Deleted")
		lnOldRecNo   = RECNO(tcCursorName)
		llRetVal     = .T.

		SET DELETED OFF
		SELECT (m.tcCursorName)
		GOTO TOP IN (m.tcCursorName)

		lnRecord = 0

		DO WHILE .T.
		   lnRecord = GETNEXTMODIFIED(m.lnRecord, m.tcCursorName)
		   IF m.lnRecord = 0
		      EXIT
		   ELSE
		      GOTO lnRecord IN (m.tcCursorName)
		      *-- Begin Add by JLM of WLC 07/05/2019
		      IF DELETED(This.cUpdateCursor) ;
		      AND EMPTY(NVL(EVALUATE(ALLTRIM(This.cUpdateCursor - '.' - This.cUpdateKeyField)),SPACE(0)))
		         *-- Go to next - This shouldn't update SQL Server
		         LOOP 
		      ENDIF    
		      *-- End Add by JLM of WLC 07/05/2019      
		   ENDIF
		   IF NOT This.UpdateRecord()
		      llRetVal = .F.
		      EXIT
		   ELSE
		      IF This.iNewPK > 0
		         lcPKField = m.tcCursorName + "." + m.tcPKField
		         REPLACE &lcPKField WITH This.iNewPK IN (m.tcCursorName)
		         This.iNewPK = 0
		      ENDIF
		   ENDIF
		ENDDO

		* PCM - 12/21/2004 - Added new flag. This marks the existing so that
		* they don't look like they are new/changed.
		* PCM - 2/26/2007 - Make sure it was successful
		IF This.lUpdateAfterSave AND m.llRetVal
		   TABLEUPDATE(.T., .F., m.tcCursorName)
		ENDIF

		SET DELETED &lcOldDeleted
		SELECT (m.tcCursorName)

		* PCM - 1/7/2005 - Changed so that, if this was a new record, we
		*                  don't attempt to do a locate to RECNO() = -1
		*                  This became a problem when This.lUpdateAfterSave
		*                  was added (since the new record is no longer -1)

		DO CASE
		   CASE This.lUpdateAfterSave AND m.lnOldRecNo > 0
		        LOCATE FOR RECNO(tcCursorName) = m.lnOldRecNo

		   CASE This.lUpdateAfterSave AND m.lnOldRecNo < 0
		        IF This.iNewPK > 0
		           LOCATE FOR &lcPKField = This.iNewPK
		        ENDIF
		   OTHERWISE
		        LOCATE FOR RECNO(tcCursorName) = m.lnOldRecNo
		ENDCASE

		RETURN m.llRetVal
	ENDPROC


	PROCEDURE updaterecord
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::UPdateRecord()
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/17/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Updates the single record.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/17/2020
		*//******************************************************************************************  
		LOCAL ;
		    laCursor[1] ;
		   ,laMembers[1];
		   ,lcCursor AS Character ;
		   ,lcFieldName AS Character ;
		   ,lcPKField AS Character ;
		   ,lcTable AS Character ;
		   ,liFields AS Integer ;
		   ,liIndex AS Integer ;
		   ,llDeleted AS Boolean ;
		   ,llNew AS Boolean ;
		   ,llRetVal AS Boolean ;
		   ,loCursor AS Object ;
		   ,luPKVal AS Variant

		llRetVal = .T.

		loCursor = CREATEOBJECT('Empty')

		lcPKField = This.cUpdateKeyField
		lcTable   = This.cUpdateTable
		lcCursor  = This.cUpdateCursor

		This.iNewPK = 0

		AFIELDS(laCursor, m.lcCursor)

		liFields = ALEN(laCursor, 1)

		*-- Loop through all the fields

		FOR liIndex = 1 TO m.liFields
		   lcFieldName = laCursor[m.liIndex, 1]
		   
		   IF laCursor[m.liIndex, 2] = "G"
		      *-- General fields can't be EVAL'd, so skip.
		      LOOP
		    ENDIF
		   
		   DO CASE
		   CASE GETFLDSTATE(0, m.lcCursor) = 2 && Deleted record
		      llDeleted = .T.
		      * No sense processing any other fields,
		      * because the record is deleted
		      EXIT
		   
		   * PCM - 12/17/2004 - Changed from <> to ! and == so we don't have to worry about SET EXACT setting.
		   * acs - 04/12/2005 - changed <> to not and == so we don't have to worry about SET EXACT setting.
		   *               AND UPPER(lcFieldName) <> UPPER(lcPKField)
		   
		   CASE (!(EVALUATE(m.lcCursor + "." + m.lcFieldName) == OLDVAL(m.lcFieldName, m.lcCursor)) ;
		         OR ISNULL(EVALUATE(m.lcCursor + "." + m.lcFieldName)) AND NOT ISNULL(OLDVAL(m.lcFieldName, m.lcCursor)) ;
		         OR NOT ISNULL(EVALUATE(m.lcCursor + "." + m.lcFieldName)) AND ISNULL(OLDVAL(m.lcFieldName, m.lcCursor))) ;
		         AND NOT (UPPER(m.lcFieldName) == UPPER(m.lcPKField))
		      * This field has *really* changed
		      * Add it to the object along with its value
		      ADDPROPERTY(loCursor, m.lcFieldName, EVALUATE(m.lcCursor + "." + m.lcFieldName))
		   OTHERWISE
		      IF UPPER(m.lcFieldName) = UPPER(m.lcPKField)
		         * acs add code to allow appended records to be seen as new
		         * PCM - 02/01/2007 - Add check to see if the PK is 0 so I can include
		         * records as part of an initial query that don't exist in the table
		         * yet, but have them saved.
		            * PCM - 08/27/2009 - Need to include the PK on a new record if it's locally generated.
		            luPKVal = EVALUATE(m.lcCursor + "." + m.lcFieldName)

		         IF GETFLDSTATE(0,m.lcCursor) = 3 OR (GETFLDSTATE(0,m.lcCursor) = 4 AND EMPTY(&lcFieldName)) ;
		               OR (!This.lLocallyGeneratedPK AND IIF(VARTYPE(m.luPKVal) = "N", m.luPKVal = 0, EMPTY(m.luPKVal)))
		         
		             * new record
		            * No need to add the PK field to the object
		            * PCM - 02/01/2007 - Changed so that code below can be triggered
		            *                  Same part of above change.
		            ADDPROPERTY(loCursor, m.lcFieldName, EVALUATE(m.lcCursor + "." + m.lcFieldName))
		            llNew = .T.
		         ELSE
		            * old record
		            * Add the key field so the sqlBuildInsertStatementFromObject method
		            * can use it to construct the update method
		            ADDPROPERTY(loCursor, m.lcFieldName, EVALUATE(m.lcCursor + "." + m.lcFieldName))
		            llNew = .F.
		         ENDIF
		      ELSE
		         * It's not the PK field and hasn't been flagged as changed
		         IF This.lUpdateAllFields
		            ADDPROPERTY(m.loCursor, m.lcFieldName, EVALUATE(m.lcCursor + "." + m.lcFieldName))
		         ENDIF
		      ENDIF
		   ENDCASE
		ENDFOR

		DO CASE
		CASE AMEMBERS(laMembers,m.loCursor) > 1
		   * Fields were modified so we're going to do an update
		   * or Insert - note that loCursor always has one member, the PK field
		   * Don't include the PK field in the update list
		   * as it's auto-generated
		    * PCM 08/27/2009 - Allow you to include the PK as part of an INSERT by setting a flag.
		    * PCM 04/02/2013 - Memory leak - property value keeps growing
		    IF !This.lLocallyGeneratedPK
		       IF !EMPTY(This.cSkipFieldsForUpdates)
		          IF ASCAN(This.aSkipFields, m.lcPKField, 1, ALEN(This.aSkipFields, 0), 1, 1) = 0
		             This.cSkipFieldsForUpdates = This.cSkipFieldsForUpdates ;
		                                        + "," ;
		                                        + m.lcPKField
		          ENDIF
		       ELSE
		          This.cSkipFieldsForUpdates = m.lcPKField
		       ENDIF
		    ENDIF

		   IF m.llNew
		      This.cSql = This.sqlBuildInsertStatementFromObject(m.loCursor,m.lcTable,,.T.)
		   ELSE
		      This.cSql = This.sqlBuildUpdateStatementFromObject(m.loCursor,m.lcTable,m.lcPKField,,,.T.)
		   ENDIF
		   
		CASE llDeleted
		   * no fields were modified, but the record was deleted
		   * PCM - 10/17/2005 - If we've already embedded the owner in the name, don't
		   * prefix it with dbof.
		    * PCM - 08/27/2009 - Fix code to be able to deal with a character based PK field
		    luPKVal = EVALUATE(m.lcCursor + "." + m.lcPKField)

		   IF "." $ m.lcTable
		       This.cSQL = "DELETE FROM " ;
		         + m.lcTable + " WHERE " ;
		             + m.lcTable + "." + m.lcPKField ;
		            + " = " ;
		           + IIF(VARTYPE(m.luPKVal) = "N", ;
		                 TRANSFORM(m.luPKVal), ;
		                  ['] + TRIM(STRTRAN(TRANSFORM(m.luPKVal), "'", "''"))+ ['])
		   ELSE
		       This.cSQL = "DELETE FROM dbo." ;
		         + m.lcTable + " WHERE " ;
		             + m.lcTable + "." + m.lcPKField ;
		            + " = " ;
		           + IIF(VARTYPE(m.luPKVal) = "N", ;
		                 TRANSFORM(m.luPKVal), ;
		                  ['] + TRIM(STRTRAN(TRANSFORM(m.luPKVal), "'", "''"))+ ['])
		   ENDIF

		OTHERWISE
		   * There's nothing to do with this record
		   * The buffer may be dirty, but the values
		   * haven't changed
		   This.cSql = SPACE(0)
		   * We'll clean the buffers while we're here
		   TABLEREVERT(.f., m.lcCursor)
		ENDCASE

		IF NOT EMPTY(This.cSQL)
		   llRetVal = This.Execute() > 0
		   This.oParameters = NULL
		   IF m.llRetVal AND m.llNew AND !This.lLocallyGeneratedPK
		      This.GetNewPK()
		   ENDIF
		ELSE
		   llRetVal = .T.
		ENDIF

		RETURN m.llRetVal

		 
	ENDPROC


	PROCEDURE connect
		LPARAMETER ;
		    tcConnectString AS Character ;
		   ,tlAsynch AS Boolean ;
		   ,tlNoAutoTransactions AS Boolean 
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::Connect()
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/17/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcConnectString - Connection String
		*//       tlAsynch        - Connection Asynch
		*//       tlNoAutoTransactions 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. or .F. on successful connection   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/17/2020
		*//******************************************************************************************  
		This.cConnectString = m.tcConnectString 

		=SQLSetProp(0, 'DispLogin', 3)
		=SQLSetProp(0, 'DispWarnings', .F.)

		IF ATC(';',m.tcConnectString) < 1
		   *-- Connection Passed
		   This.nSQLHandle = SQLConnect(m.tcConnectString)
		   *!* llUseConnection = .T. - I don't see this used anywhere. Removed by JLM 02/17/2020
		ELSE
		   *-- DSN UID and PWD passed
		   *-- Format: [DSN=MyDSN;UID=MyUID;Pwd=MyPassword]
		   THIS.nSQLHandle = SQLStringConnect(m.tcConnectString, .T.)
		   *!* llUseConnection = .F. - I don't see this used anywhere. Removed by JLM 02/17/2020
		ENDIF

		IF THIS.nSQLHandle < 1
		   THIS.lError = .T.
		   THIS.FillErrors()
		   RETURN .F.

		ELSE
		   THIS.SetAsynchMode(m.tlAsynch)
		ENDIF

		IF m.tlNoAutoTransactions 
		  =SQLSETPROP(this.nSQLHandle,"Transactions" ,2 )
		ENDIF

		RETURN .T.
	ENDPROC


	PROCEDURE sqlbuildupdatestatementfromobject
		LPARAMETER ;
		    loData AS Object ;
		    ,lcFileName AS Character ;
		    ,lcPkField AS Character ;
		    ,loOrigData AS Object ;
		    ,loSQLRecord AS Object ;
		    ,llUseNamedParameters AS Boolean
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::SQLBuildUpdateStatementFromObject
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/19/2018
		*//
		*//  COPYRIGHT © 2010-2018   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/28/2014 - PCM - Created 
		*//****************************************************************************************** 
		LOCAL loData, lnFields, lnX, lcField, lcType, lvValue, lcValue, lvPkValue
		Local laFields[1], lcRawValue, lcSQL, lcSkipFields, llOrigData

		THIS.cParamLog = SPACE(0)		&& Must clear this first

		IF EMPTY(m.lcPKField)
		  lcPKField = 'PK'
		ENDIF

		IF VARTYPE(m.loOrigData) = "O"
		  llOrigData = .T.
		  #IF VERSION(5) > 700
		     IF COMPOBJ(loData, loOrigData)
		        RETURN ""
		     ENDIF
		  #ENDIF
		ELSE
		  llOrigData = .F.
		ENDIF

		lcSQL = "UPDATE [" + m.lcFileName + "] SET"

		IF EMPTY(THIS.cSkipFieldsForUpdates)
		   lcSkipFields = ",TIMESTAMP_COLUMN,"
		ELSE
		   lcSkipFields = ",TIMESTAMP_COLUMN," + UPPER(THIS.cSkipFieldsForUpdates) + ","
		ENDIF

		*** If a SQL Record was passed used its structure to look for fields
		*** otherwise use the data record
		lnFields = AMEMBERS(laFields, IIF(VARTYPE(m.loSqlRecord) = "O", m.loSqlRecord, m.loData) )

		FOR lnX = 1 TO m.lnFields
		   lcField = laFields[lnX]

		   *** We can't deal with Timestamp columns and any other fields to be skipped
		   *** so just loop out of this field
		   IF "," + UPPER(m.lcField) + ","  $ m.lcSkipFields
		      LOOP
		   ENDIF

		   lcRawValue = EVALUATE("loData." + m.lcField)

		   *** Handle case where an error occurred
		   IF (this.lInternalError)
		      this.lInternalError = .f.  && Field that doesn't exist in SQL but exists in local cursor
		      this.lerror           = .f.
		      LOOP  && Skip this field
		   ENDIF

		   lcType = VARTYPE(m.lcRawValue)

		   *** Skip the field that haven't changed if loOrigData was passed
		   IF m.llOrigData AND m.lcRawValue == EVALUATE("loOrigData." + m.lcField)
		      LOOP
		   ENDIF

		   IF !m.llUseNamedParameters
		   DO CASE
		      CASE m.lcType = "C"
		         lcValue = ['] + TRIM(STRTRAN(m.lcRawValue, ['], [''])) + [']
		      CASE m.lcType = "N"
		         m.lcValue = STRTRAN( TRANSFORM(m.lcRawValue), [,], [.])
		      CASE m.lcType = "L"
		         m.lcValue = IIF(m.lcRawValue, '1', '0')
		      CASE lcType = "D"
		         * PCM - 2/9/2007 - Added new functionality
		         IF This.lReplaceEmptyDateWithNull
		            lcValue = IIF(EMPTY(m.lcRawValue), "null", ['] + DTOC(m.lcRawValue) + ['])
		         ELSE
		            lcValue = ['] + IIF(EMPTY(m.lcRawValue), "", DTOC(m.lcRawValue)) + [']
		         ENDIF

		      CASE m.lcType = "T"
		         * PCM - 2/9/2007 - Added new functionlity
		         IF This.lReplaceEmptyDateWithNull
		            lcValue = IIF(EMPTY(m.lcRawValue), "null", ['] + TTOC(m.lcRawValue) + ['])
		         ELSE
		            lcValue = ['] + IIF(EMPTY(m.lcRawValue), "", TTOC(m.lcRawValue)) + [']
		         ENDIF

		      CASE m.lcType = "Y"
		         lcValue = TRANSFORM( m.lcRawValue, "" )
		      CASE m.lcType = "X"
		        lcValue = "null"
		      OTHERWISE
		         LOOP   && Invalid Type - skip
		   ENDCASE

		   lcSQL = m.lcSQL +  " [" + m.lcField + "]=" + m.lcValue + ","
		   ELSE
		      THIS.AddParameter(m.lcRawValue, "__" + m.lcField)
		      lcSQL =  m.lcSql +  " [" + m.lcField + "]=?__" + m.lcField + ","

		      * Log Parameter values
			  THIS.cParamLog = THIS.cParamLog + "?__" + m.lcField + " = " + TRANSFORM(m.lcRawValue) + CHR(13) + CHR(10)
		   ENDIF
		ENDFOR

		*** If no fields need updating return a blank string
		IF ALLTRIM(m.lcSQL) == "UPDATE [" + m.lcFileName + "] SET"
		   RETURN ""
		ENDIF

		lcSQL = SUBSTR(m.lcSQL, 1, LEN(m.lcSQL) - 1)  && Strip last comma

		lvPkValue = EVALUATE("loData." + m.lcPKField)

		IF VARTYPE(m.lvPkValue) = "C"
		  lcSQL = m.lcSQL + " WHERE " + m.lcPkField +  "='" + m.lvPKValue + "'"
		ELSE
		   lcSQL = m.lcSQL + " WHERE " + m.lcPkField +  "=" + TRANSFORM( m.lvPKValue )
		ENDIF

		RETURN m.lcSQL
	ENDPROC


	PROCEDURE sqlbuildinsertstatementfromobject
		LPARAMETER ;
		    loData AS Object ;
		   ,lcFilename AS Character ;
		   ,loSQLRecord AS Object ;
		   ,llUseNamedParameters AS Boolean
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::SQLBuildInsertStatementFromObject
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/19/2018
		*//
		*//  COPYRIGHT © 2010-2018   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/28/2014 - PCM - Created 
		*//****************************************************************************************** 
		LOCAL lcFieldList, lcValueList, loData, lnFields, lnX, lcField, lcType, lcValue, lcSQL
		LOCAL laFields[1], lcRawValue, lcSkipFields

		THIS.cParamLog = ""		&& Must clear this first

		lcSQL = "INSERT [" + m.lcFileName + "]"

		lcFieldList   = ""
		lcValueList   = ""

		IF EMPTY(THIS.cSkipFieldsForUpdates)
		   lcSkipFields = ",TIMESTAMP_COLUMN,"
		ELSE
		   lcSkipFields = ",TIMESTAMP_COLUMN," + UPPER(THIS.cSkipFieldsForUpdates) + ","
		ENDIF

		*** If a SQL Record was passed used its structure to look for fields
		*** otherwise use the data record
		lnFields = AMEMBERS(laFields, IIF(VARTYPE(m.loSqlRecord) = "O", m.loSqlRecord, m.loData) )

		FOR lnX = 1 TO m.lnFields
		   lcField = laFields[m.lnX]

		   *** We can't deal with Timestamp columns and any other fields to be skipped
		   *** so just loop out of this field
		   IF "," + UPPER(m.lcField) + ","  $ m.lcSkipFields
		      LOOP
		   ENDIF

		   lcRawValue = EVALUATE("loData." + m.lcField)
		   *** Handle case where an error occurred
		   IF (this.lInternalError)
		      this.lInternalError = .f.  && Field that doesn't exist in SQL but exists in local cursor
		      this.lerror           = .f.
		      LOOP  && Skip this field
		   ENDIF


		   lcType = VARTYPE(m.lcRawValue)

		   IF !m.llUseNamedParameters
		      DO CASE
		         CASE m.lcType = "C"
		            lcValue = ['] + TRIM(STRTRAN(m.lcRawValue, "'", "''")) + [']
		         CASE m.lcType = "N"
		            lcValue = STRTRAN( TRANSFORM(m.lcRawValue), ",", ".")
		         CASE m.lcType = "L"
		            lcValue = IIF(m.lcRawValue, '1', '0')
		         CASE m.lcType = "D"
		            * PCM - 2/9/2007 - Added new functionality
		            IF This.lReplaceEmptyDateWithNull
		               lcValue = IIF(EMPTY(m.lcRawValue), "null", ['] + DTOC(m.lcRawValue) + ['])
		            ELSE
		               lcValue = ['] + IIF(EMPTY(m.lcRawValue), "", DTOC(m.lcRawValue)) + [']
		            ENDIF

		         CASE m.lcType = "T"
		            * PCM - 2/9/2007 - Added new functionality
		            IF This.lReplaceEmptyDateWithNull
		               lcValue = IIF(EMPTY(m.lcRawValue), "null", ['] + TTOC(m.lcRawValue) + ['])
		            ELSE
		               lcValue = ['] + IIF(EMPTY(m.lcRawValue), "", TTOC(m.lcRawValue)) + [']
		            ENDIF

		         CASE m.lcType = "Y"
		            lcValue = TRANSFORM( m.lcRawValue, "" )
		           CASE m.lcType = "X"  && NULL
		            lcValue = "null"
		         OTHERWISE
		            LOOP   && Invalid Type - skip
		      ENDCASE
		      lcValueList = m.lcValueList + m.lcValue + ","
		   ELSE
		      LOCAL lcParmName
		      lcParmName = "__" + m.lcField
		      * PCM - 6/15/2010 - Added new functionality
		      IF INLIST(m.lcType, "D", "T")
		         IF This.lReplaceEmptyDateWithNull AND EMPTY(m.lcRawValue)
		            lcRawValue = NULL
		         ENDIF
		      ENDIF

		      this.AddParameter(m.lcRawValue, m.lcParmName)
		      lcValueList = m.lcValueList + "?" + m.lcParmName + ","
		    
		      * Log Parameter values
			  THIS.cParamLog = THIS.cParamLog + "?" + m.lcParmName + " = " + TRANSFORM(m.lcRawValue) + CHR(13) + CHR(10)
		   ENDIF

		   lcFieldList = m.lcFieldList + '[' +  m.lcField + '],'
		ENDFOR

		IF EMPTY(m.lcFieldList) OR EMPTY(m.lcValueList)
		   RETURN ""
		ELSE
		   lcFieldList   = SUBSTR(m.lcFieldList, 1, LEN(m.lcFieldList) - 1)
		   lcValueList   = SUBSTR(m.lcValueList, 1, LEN(m.lcValueList) - 1)
		ENDIF

		lcSQL = m.lcSQL + " (" + m.lcFieldList + ") VALUES (" +  m.lcValueList + ")"

		RETURN m.lcSQL
	ENDPROC


	PROCEDURE Destroy
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::Destroy
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/19/2018
		*//
		*//  COPYRIGHT © 2010-2018   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    02/16/2015 - SJE - Created 
		*//******************************************************************************************
		THIS.oUpdateRecordCallback = NULL

		IF THIS.nSQLResult = 0
		   =SQLCancel(THIS.nSQLHandle)
		ENDIF

		IF THIS.nSQLHandle > 0 AND This.lReleaseSQLHandle
		   =SQLDisconnect(THIS.nSQLHandle)
		ENDIF

		RETURN DODEFAULT()  
	ENDPROC


	PROCEDURE execute
		LPARAMETER tcSQL, tcResultCursor, toParameters
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::Execute
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/19/2018
		*//
		*//  COPYRIGHT © 2010-2018   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Executes SQL Command  
		*//  
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcSQL - SQL command
		*//       tcResultCursor (Optional) - Result cursor name
		*//       toParameters (Optional) - Parameter object
		*//
		*//    OUTPUT PARAMETERS: 
		*//       lnResult - Result of the EXEC
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/28/2014 - PCM - Created 
		*//******************************************************************************************
		PRIVATE poParamItem

		LOCAL ;
		    lnResult AS Integer ;
		   ,lcSpecifiedCursor AS Character ;
		   ,lnStart AS Integer ;
		   ,ltStart AS Datetime ;
		   ,lcProgram AS Character ;
		   ,lcSQL AS Integer 
		   
		* Note - we have to save off the result cursor name
		* here as the Execute() method resets it to the default
		* value

		DO CASE
		   CASE PCOUNT() = 3 AND VARTYPE(m.tcResultCursor) = "C"
		        lcSpecifiedCursor = m.tcResultCursor
		   CASE PCOUNT() = 2 AND VARTYPE(m.tcResultCursor) = "C"
		       lcSpecifiedCursor = m.tcResultCursor
		   CASE NOT EMPTY(This.cSQLCursor)
		          lcSpecifiedCursor = This.cSQLCursor
		   OTHERWISE
		       lcSpecifiedCursor = SPACE(0)
		ENDCASE

		poParamItem = CREATEOBJECT("Empty")

		IF PCOUNT() = 3
		   tcSQL = This.ApplyParameters(m.tcSQL, m.toParameters, m.poParamItem)
		ENDIF

		* PCM - 7/6/2005 - Add code for performance testing
		* This won't work if the query starts before midnight
		* but finishes after midnight. I'm willing to live with that.
		IF This.lEnableInstrumentation
		   ltStart   = DATETIME()
		   lnStart   = SECONDS()
		   lnResult   = wwSQL::Execute(m.tcSQL, m.lcSpecifiedCursor)
		   * PCM - 2/7/2007 - Grab the record count
		   IF VARTYPE(lcSpecifiedCursor) = "C" AND USED(m.lcSpecifiedCursor)
		      This.nReturnedRecords = RECCOUNT(m.lcSpecifiedCursor)
		   ENDIF

		   lnLength = SECONDS() - m.lnStart

		   IF m.lnLength > This.nInstrumentationThresholdSeconds
		      * Past threshold. Log it.
		      
		      *-- Begin Add by JLM 03/04/2015
		      This.LogSQL()
		      *-- End Add by JLM 03/04/2015
		      
		      *-- Begin Remove by JLM 03/04/2015
		      *!* lcProgram = TRANSFORM(PROGRAM(PROGRAM(-1) - 1)) + " : " + TRANSFORM(SYS(16, PROGRAM(-1) - 1))
		      *!* 
		      *!* lcSQL = This.GetParametersAsString(m.toParameters) ;
		      *!*       + m.tcSQL
		      *!* = SQLEXEC(This.nSQLHandle, "INSERT INTO " ;
		      *!*                            + ALLTRIM(This.cInstrumentationDatabase) + "." + ALLTRIM(This.cInstrumentationTable) ;
		      *!*                            + " (mSQL, nQueryTime, tReceived, cCalling) VALUES (?lcSQL, ?lnLength, ?ltStart, ?lcProgram)")
		      *-- End Remove by JLM 03/04/2015 
		   ENDIF
		ELSE
		   *-- Call Parent Class to do the work
		   ltStart  = DATETIME()
		   lnResult = wwSQL::Execute(m.tcSQL, m.lcSpecifiedCursor)
		   THIS.nExecTime = DATETIME() - ltStart

		   IF VARTYPE(lcSpecifiedCursor) = 'C' AND USED(m.lcSpecifiedCursor)
		      This.nReturnedRecords = RECCOUNT(m.lcSpecifiedCursor)
		   ENDIF
		ENDIF

		IF m.lnResult > 0 AND NOT EMPTY(m.lcSpecifiedCursor)
		   ASSERT INLIST(This.nBufferMode, 3, 5) MESSAGE 'Only buffering modes 3 and 5 (optimistic row and table) are supported'

		   IF USED(m.lcSpecifiedCursor)
		       This.MapDates(m.lcSpecifiedCursor)
		        CURSORSETPROP('Buffering', This.nBufferMode, m.lcSpecifiedCursor)
		     ENDIF
		ENDIF

		*-- Log it
		IF This.lLogSQL
		   THIS.LogSQL()
		ENDIF 

		RETURN m.lnResult
	ENDPROC


	PROCEDURE Init
		LPARAMETER lcConnectString, llAsynch
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::Init()
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/13/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     08/28/2012 - Paul Mrozowski - Created 
		*//******************************************************************************************  
		DODEFAULT(m.lcConnectString, m.llAsynch)

		This.cSkipFieldsForUpdates = This.cSkipFieldsForUpdates
	ENDPROC


	PROCEDURE begintransaction
		LPARAMETERS toSql1, toSql2, toSql3, toSql4, toSql5, toSql6, toSql7, toSql8, toSql9, toSql10, ;
		            toSql11, toSql12, toSql13, toSql14, toSql15, toSql16, toSql17, toSql18, toSql19, toSql20, ;
		            toSql21, toSql22, toSql23
		*//******************************************************************************************
		*//  FUNCTION NAME: wlcSQL::BeginTransaction()
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/13/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Added parameters to make it easy to share a connection 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     06/02/2010 - PCM - Created 
		*//******************************************************************************************  
		IF VARTYPE(m.toSql1) = 'O'
		   This.ShareConnection(This, ;
		                        m.toSql1, ;
		                        m.toSql2, ;
		                        m.toSql3, ;
		                        m.toSql4, ;
		                        m.toSql5, ;
		                        m.toSql6, ;
		                        m.toSql7, ;
		                        m.toSql8, ;
		                        m.toSql9, ;
		                        m.toSql10, ;
		                        m.toSql11, ;
		                        m.toSql12, ;
		                        m.toSql13, ;
		                        m.toSql14, ;
		                        m.toSql15, ;
		                        m.toSql16, ;
		                        m.toSql17, ;
		                        m.toSql18, ;
		                        m.toSql19, ;
		                        m.toSql20, ;
		                        m.toSql21, ;
		                        m.toSql22, ;
		                        m.toSql23)
		ENDIF

		RETURN DODEFAULT()
	ENDPROC


ENDDEFINE
*
*-- EndDefine: wlcsql
**************************************************


**************************************************
*-- Class:        wlcvfp (c:\develop\codeminenew\dmie_rv\custom\wlcsql.prg)
*-- ParentClass:  wlcsql (c:\develop\codeminenew\dmie_rv\custom\wlcsql.prg)
*-- BaseClass:    custom
*-- Time Stamp:   03/02/20 04:30:10 AM
*
DEFINE CLASS wlcvfp AS wlcsql


	lvfptable = .F.
	*-- The SCATTER MEMO NAME values for the current cursor.
	onewinsert = .NULL.
	*-- If this is trruue and this is a VFP table, the SAVE will basically just SCAN throug the cursor and INSERT INTO table from NAME object.
	lbulkload = .F.
	lhandlesqlstyleparameters = .F.
	llocallygeneratedpk = .T.
	ninstrumentationthresholdseconds = 2.25
	Name = "wlcvfp"


	PROCEDURE checkforreservedwords
		LPARAMETERS tcTable AS Character, tcField AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: CheckForReservedWords
		*//
		*//  AUTHOR: White Light Computing, Inc. 10/02/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    The UPDATE doesn't work well with reserved words unless the table name is associated with it.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcTable - Table name (required)
		*//       tcField - Field name (required)
		*//
		*//    OUTPUT PARAMETERS: 
		*//       lcReturn
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     10/02/2013 - JLM - Created 
		*//******************************************************************************************  
		LOCAL ;
		    lcField AS Character ;
		   ,lcReturn AS Character
		   
		lcField = UPPER(ALLTRIM(m.tcField)) 
		IF m.lcField == 'GROUP' 
		   lcReturn = ALLTRIM(m.tcTable-'.'-m.tcField)
		ELSE
		   lcReturn = m.tcField
		ENDIF

		RETURN m.lcReturn
	ENDPROC


	PROCEDURE updatebulkrecord
		*//******************************************************************************************
		*//  FUNCTION NAME: UpdateBulkRecord
		*//
		*//  AUTHOR: White Light Computing, Inc. 10/08/2013 
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     This is for a new table and just do an insert into it. Get the PK from the table.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcConnectString 
		*//       tlAsynch 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     10/08/2013 - JLM - Created 
		*//******************************************************************************************
		IF NOT This.lVFPTable 
		   *-- Nothing at this time 
		ELSE    
		   LOCAL ARRAY laCursor[1]
		   LOCAL ARRAY laMembers[1]
		   LOCAL ARRAY laFields[1]

		   LOCAL liIndex, ;
		      liFields as Integer 
		      
		   LOCAL loCursor as Object ;
		      ,loNewInsert AS Object

		   LOCAL lcFieldName, ;
		      lcPKField as String ;
		      ,lcUpdateTable AS Characer ;
		      ,lcCursor AS Character ;
		      ,lcField AS Character 
		      
		   LOCAL llNew, ;
		      llRetVal, ;
		      llDeleted as Boolean, ;
		      luPKVal ;
		      ,lnSkipFieldCount AS Integer ;
		      ,lnx AS Integer
		     
		   LOCAL ARRAY laSkipFields[1]

		   llRetVal = .T.

		   loCursor = CREATEOBJECT('Empty')

		   lcPKField = ALLTRIM(This.cUpdateKeyField)
		   *-- Comment JLM of WLC 09/23/2013
		   *-- STRTRAN for space to equal '_' is because if a table name has a space in it
		   *-- VFP alias' it with a '_'. I.E. Import EMI.dbf alias equals Import_EMI
		   
		   lcUpdateTable = ALLTRIM(This.cUpdateTable)
		   lcTable       = STRTRAN(lcUpdateTable,' ','_')  
		   lcCursor      = ALLTRIM(This.cUpdateCursor)
		   
		   *-- Right now assuming the PK is auto generated
		   This.iNewPK = 0
		   SELECT (m.lcCursor)
		   SCATTER MEMO NAME loNewInsert
		   REMOVEPROPERTY(loNewInsert,m.lcPKField)

		   *-- Removing the Skipped fields
		   lnSkipFieldCount = ALINES(laSkipFields,This.cSkipFieldsForUpdates,1+4+16,',')
		   FOR lnx = 1 TO lnSkipFieldCount 
		      REMOVEPROPERTY(loNewInsert,laSkipFields[m.lnx])
		   ENDFOR
		 
		   *-- Figure out if we will insert or update
		   IF NVL(&lcCursor..&lcPKField,0) <> 0
		      SELECT (m.lcTable)
		      LOCATE FOR &lcPKField = &lcCursor..&lcPKField 
		      IF FOUND()
		        This.cSQL = ''
		        GATHER NAME loNewInsert MEMO 
		      ELSE
		         *-- Updated the named object to insert from.
		         This.oNewInsert = loNewInsert
		         This.cSQL       = 'INSERT INTO &lcTable FROM NAME This.oNewInsert'
		      ENDIF
		   ELSE
		      *-- Updated the named object to insert from.
		      This.oNewInsert = loNewInsert
		      This.cSQL       = 'INSERT INTO &lcTable FROM NAME This.oNewInsert'   
		   ENDIF 
		   
		   IF NOT EMPTY(This.cSQL)
		      llRetVal = This.Execute() > 0
		      This.oParameters = NULL
		      IF m.llRetVal 
		         IF m.llNew
		            IF This.lLocallyGeneratedPK
		            *-- Making an assumption here that the PK has been auto-filled 
		            *-- in by VFP using Incremental Integer
		               This.iNewPk = EVALUATE(ALLTRIM(m.lcTable-'.'-m.lcPKField))
		            ELSE
		               This.GetNewPK()
		            ENDIF
		         ENDIF   
		      ENDIF
		   ELSE
		      llRetVal = .T.
		   ENDIF

		   RETURN m.llRetVal
		ENDIF 
	ENDPROC


	PROCEDURE vfpexecute
		LPARAMETER ;
		    tcSQL AS Character ;
		   ,tcResultCursor AS Character ;
		   ,toParameters AS Object
		*//******************************************************************************************
		*//  FUNCTION NAME: VFPExecute
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Execute SQL Command
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcSQL                     - SQL command
		*//       tcResultCursor (Optional) - Result cursor name
		*//       toParameters (Optional)   - Parameter object
		*//
		*//    OUTPUT PARAMETERS: 
		*//       This.nSQLResult - Result of the Execution
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************  
		PRIVATE poParamItem

		LOCAL ;
		    lcResult AS Character ;
		   ,lcSpecifiedCursor AS Character ;
		   ,lcName AS Character

		LOCAL ARRAY laResult(1)

		DO CASE
		   CASE PCOUNT() = 3 AND VARTYPE(m.tcResultCursor) = "C"
		      lcSpecifiedCursor = m.tcResultCursor
		   CASE PCOUNT() = 2 AND VARTYPE(m.tcResultCursor) = "C"
		      lcSpecifiedCursor = m.tcResultCursor
		   CASE NOT EMPTY(This.cSQLCursor)
		      lcSpecifiedCursor = This.cSQLCursor
		   OTHERWISE
		      lcSpecifiedCursor = SPACE(0)
		ENDCASE

		IF EMPTY(m.tcSQL)
		   tcSQL = This.cSQL
		ELSE 
		   This.cSQL = m.tcSQL
		ENDIF

		poParamItem = CREATEOBJECT("Empty")

		IF PCOUNT() = 3
		   m.tcSQL = This.ApplyParameters(m.tcSQL, m.toParameters, m.poParamItem)
		ENDIF

		IF This.nSQLResult = 0
		  This.SQLCancel()
		ENDIF  

		This.lError    = .F.
		This.aErrors   = .F.  && clear out the errors
		This.cErrorMsg = ''
		m.lcResult     = ''

		TRY
		   &tcSQL
		   This.nSQLResult = 1
		CATCH TO m.lcResult
		   This.nSQLResult = -1
		ENDTRY

		IF NOT EMPTY(m.lcResult)
		   laResult[1,1] = m.lcResult
		ENDIF

		This.lparameterreset = .T.

		IF This.nSQLResult < 0
		   This.lError = .T.
		   This.FillErrors()
		ELSE
		   *** Try to parse Out parameters back into the 
		   IF this.lOutparameters 
		      FOR EACH loParm IN this.oParameters
		         IF UPPER(loParm.Direction) = "OUT"
		            lcName = loParm.Name
		            IF TYPE(lcName) # "U"
		               loParm.Value = EVALUATE(lcName)
		            ENDIF
		         ENDIF
		      ENDFOR
		   ENDIF

		   *** Always reset the SQL cursor
		   This.cSQLCursor = "TSQLQuery"

		   IF VARTYPE(m.lcSpecifiedCursor) = "C" ;
		   AND USED(m.lcSpecifiedCursor)
		      This.nReturnedRecords = RECCOUNT(m.lcSpecifiedCursor)
		   ENDIF
		   
		   IF USED(m.lcSpecifiedCursor)
		      CURSORSETPROP("Buffering", This.nBufferMode, m.lcSpecifiedCursor)
		   ENDIF
		ENDIF

		RETURN This.nSQLResult  
	ENDPROC


	PROCEDURE vfprollback
		*//******************************************************************************************
		*//  FUNCTION NAME: VFPRollBack
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/29/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/29/2020 - JLM - Created 
		*//******************************************************************************************  
		RETURN THIS.VFPExecute('ROLLBACK')
	ENDPROC


	PROCEDURE sqlbuildupdatestatementfromobject
		LPARAMETER ;
		   toData AS Object ;
		   ,tcFileName AS Character ;
		   ,tcPkField AS Character ; 
		   ,toOrigData AS Object ;
		   ,toSQLRecord AS Object ;
		   ,tlUseNamedParameters AS Boolean
		*//******************************************************************************************
		*//  FUNCTION NAME: SqlBuildUpdateStatementFromObject
		*//
		*//  AUTHOR: White Light Computing, Inc. 06/05/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Builds the SQL Update statement from an object.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       toData      - Usually a SCATTER NAME object
		*//       tcFilename  - Table name
		*//       tcPkField   - Primary field name
		*//       toOrigData  - Usually a SCATTER NAME object
		*//       toSQLRecord - SQL Record Object 
		*//       tlUseNamedParameters - Create parameters 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       lcSQL
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/28/2020 - JLM - Created 
		*//******************************************************************************************  
		IF NOT This.lVFPTable 
		   RETURN DODEFAULT(m.toData, m.tcFileName, m.tcPkField, m.toOrigData, m.toSQLRecord, m.tlUseNamedParameters)
		ELSE
		   Local ;
		      laFields[1];
		      ,lcField AS Character;
		      ,lcRawValue AS Character ;
		      ,lcSQL AS Character ;
		      ,lcSetField as Character;
		      ,lcSkipFields AS Character ;
		      ,lcType AS Character ;
		      ,lcValue AS Character ;
		      ,llOrigData AS Boolean ;
		      ,lnFields AS Integer ;
		      ,lnX AS Integer ;
		      ,lvPkValue
		   
		   IF EMPTY(m.tcPkField)
		     tcPkField = "PK"
		   ENDIF

		   IF VARTYPE(m.toOrigData) = "O"
		     llOrigData = .T.
		     #IF VERSION(5) > 700
		        IF COMPOBJ(toData,toOrigData)
		           RETURN ""
		        ENDIF
		     #ENDIF
		   ELSE
		     llOrigData = .F.
		   ENDIF

		   lcSQL = "UPDATE " + STRTRAN(m.tcFileName,' ','_') + " SET"

		   IF EMPTY(THIS.cSkipFieldsForUpdates)
		      lcSkipFields = ",TIMESTAMP_COLUMN,"
		   ELSE
		      lcSkipFields = ",TIMESTAMP_COLUMN," + UPPER(THIS.cSkipFieldsForUpdates) + ","
		   ENDIF

		   *-- If a SQL Record was passed used its structure to look for fields otherwise use the data record
		   lnFields = AMEMBERS(laFields,IIF(VARTYPE(m.toSQLRecord)="O",m.toSQLRecord,m.toData) )

		   FOR lnX = 1 TO m.lnFields
		      lcField = laFields[lnX]

		      *-- We can't deal with Timestamp columns and any other fields to be skipped
		      *-- so just loop out of this field
		      IF "," + UPPER(m.lcField) + ","  $ m.lcSkipFields
		         LOOP
		      ENDIF

		      lcRawValue = EVALUATE("toData." + m.lcField)

		      *-- Handle case where an error occurred
		      IF (this.lInternalError)
		         this.lInternalError = .f.  && Field that doesn't exist in table but exists in local cursor
		         this.lerror = .f.
		         LOOP  && Skip this field
		      ENDIF

		      lcType = VARTYPE(m.lcRawValue)

		      *-- Skip the field that haven't changed if toOrigData was passed
		      IF m.llOrigData AND m.lcRawValue == EVALUATE("toOrigData." + m.lcField)
		         LOOP
		      ENDIF

		      IF NOT m.tlUseNamedParameters
		      DO CASE
		         CASE m.lcType = "C"
		            lcValue = [']+ TRIM(STRTRAN(m.lcRawValue,['],[''])) + [']
		         CASE m.lcType = "N"
		            m.lcValue = STRTRAN( TRANSFORM(m.lcRawValue),[,],[.])
		         CASE m.lcType = "L"
		            m.lcValue = IIF(m.lcRawValue,'.T.','.F.')   && IIF(m.lcRawValue,'1','0')
		         CASE lcType = "D"
		            IF This.lReplaceEmptyDateWithNull
		               lcValue = IIF(EMPTY(m.lcRawValue), "null", ['] + DTOC(m.lcRawValue) + ['])
		            ELSE
		               lcValue = [']+IIF(EMPTY(m.lcRawValue),"",DTOC(m.lcRawValue))+[']
		            ENDIF

		         CASE m.lcType = "T"
		            IF This.lReplaceEmptyDateWithNull
		               lcValue = IIF(EMPTY(m.lcRawValue), "null", ['] + TTOC(m.lcRawValue) + ['])
		            ELSE
		               lcValue = [']+IIF(EMPTY(m.lcRawValue),"",TTOC(m.lcRawValue))+[']
		            ENDIF

		         CASE m.lcType = "Y"
		            lcValue = TRANSFORM( m.lcRawValue,"" )
		         CASE m.lcType = "X"
		           lcValue = "null"
		         OTHERWISE
		            LOOP   && Invalid Type - skip
		      ENDCASE
		      
		      *-- JLM - Added because the Update will error. Example 'GROUP'
		      m.lcField = This.CheckForReservedWords(STRTRAN(m.tcFileName,' ','_'),m.lcField)

		      lcSQL = m.lcSQL +  " " + m.lcField + "=" + m.lcValue + ","
		      ELSE
		         THIS.AddParameter(m.lcRawValue, m.lcField)
		         
		         *-- JLM - Added because the Update will error. Example 'GROUP'
		         m.lcSetField = This.CheckForReservedWords(STRTRAN(m.tcFileName,' ','_'),m.lcField)
		         lcSQL =  m.lcSql +  " " + m.lcSetField + " = " + This.cUpdateCursor - '.' - m.lcField + ","
		      ENDIF
		   ENDFOR

		   *-- If no fields need updating return a blank string
		   IF ALLTRIM(m.lcSQL) == "UPDATE " + STRTRAN(m.tcFileName,' ','_') + " SET"
		      RETURN ""
		   ENDIF
		   *!*   IF LEN(lcSQL) < 1
		   *!*      RETURN ""
		   *!*   ENDIF

		   lcSQL = SUBSTR(m.lcSQL,1,LEN(m.lcSQL)-1)  && Strip last comma

		   lvPkValue = EVALUATE("toData." + m.tcPkField)

		   IF VARTYPE(m.lvPkValue) = "C"
		     lcSQL = m.lcSQL + " WHERE " + m.tcPkField +  "='" + m.lvPKValue + "'"
		   ELSE
		      lcSQL = m.lcSQL + " WHERE " + m.tcPkField +  "=" + TRANSFORM( m.lvPKValue )
		   ENDIF
		   
		   RETURN m.lcSQL
		ENDIF

		 
	ENDPROC


	PROCEDURE Destroy
		*//******************************************************************************************
		*//  FUNCTION NAME: Destroy
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013 
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Clean up
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************  
		IF This.lVFPTable
		   This.Close()
		ELSE
		   DODEFAULT()
		ENDIF  

		RETURN  
	ENDPROC


	PROCEDURE disconnect
		*//******************************************************************************************
		*//  FUNCTION NAME: Disconnect
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013 
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//****************************************************************************************** 
		IF This.lVFPTable
		   *-- Nothing at this time 
		ELSE
		   DODEFAULT()
		ENDIF  

		RETURN  
	ENDPROC


	PROCEDURE begintransaction
		LPARAMETERS toSql1, toSql2, toSql3, toSql4, toSql5, toSql6, toSql7, toSql8, toSql9, toSql10, ;
		            toSql11, toSql12, toSql13, toSql14, toSql15, toSql16, toSql17, toSql18, toSql19, toSql20, ;
		            toSql21, toSql22, toSql23
		*//******************************************************************************************
		*//  FUNCTION NAME: BeginTransaction
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Begin Transaction 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       toSqlnn = 1 thru 23 - Passed thru
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************    
		IF This.lVfpTable
		   THIS.VfpExecute("BEGIN TRANSACTION")
		ELSE   
		   DODEFAULT(m.toSql1, m.toSql2,  m.toSql3,  m.toSql4,  m.toSql5,  m.toSql6,  m.toSql7,  m.toSql8,  m.toSql9,  m.toSql10, ;
		            m.toSql11, m.toSql12, m.toSql13, m.toSql14, m.toSql15, m.toSql16, m.toSql17, m.toSql18, m.toSql19, m.toSql20, ;
		            m.toSql21, m.toSql22, m.toSql23)
		ENDIF            
	ENDPROC


	PROCEDURE Init
		LPARAMETER ;
		    tcConnectString AS Character ;
		   ,tlAsynch AS Boolean 
		*//******************************************************************************************
		*//  FUNCTION NAME: Init
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013 
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcConnectString - Passed thru
		*//       tlAsynch        - Passed thru 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************
		IF This.lVFPTable
		   *-- Nothing at this time 
		ELSE
		   DODEFAULT(m.tcConnectString, m.tlAsynch)
		ENDIF  

		RETURN  
	ENDPROC


	PROCEDURE executenonquery
		LPARAMETER ;
		    tcSQL AS Character ;
		   ,tlStoredProcedure AS Boolean
		*//******************************************************************************************
		*//  FUNCTION NAME: ExecuteNonQuery
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Execute SQL Command 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcSQL             - Passed thru 
		*//       tlStoredProcedure - Passed thru
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************  
		IF This.lVFPTable
		   *-- Nothing at this time 
		ELSE
		   DODEFAULT(m.tcSQL, m.tlStoredProcedure)
		ENDIF  

		RETURN  
	ENDPROC


	PROCEDURE execute
		LPARAMETER ;
		    tcSQL AS Character ;
		   ,tcResultCursor AS Character ;
		   ,toParameters AS Object 
		*//******************************************************************************************
		*//  FUNCTION NAME: Excute
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Execute SQL Command 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcSQL          - Passed thru 
		*//       tcResultCursor - Passed thru
		*//       toParameters   - Passed thru
		*//
		*//    OUTPUT PARAMETERS: 
		*//       lnReturn   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************  
		LOCAL ;
		   lnReturn AS Integer
		   
		IF This.lVfpTable
		   m.lnReturn = THIS.VfpExecute(m.tcSQL, m.tcResultCursor, m.toParameters)
		ELSE 
		   m.lnReturn = DODEFAULT(m.tcSQL, m.tcResultCursor, m.toParameters)
		ENDIF 

		RETURN m.lnReturn   
	ENDPROC


	PROCEDURE sqlbuildinsertstatementfromobject
		LPARAMETER ;
		    toData AS Object ;
		   ,tcFilename AS Character ;
		   ,toSQLRecord AS Object ;
		   ,tlUseNamedParameters AS Boolean 
		*//******************************************************************************************
		*//  FUNCTION NAME: SQLBuildInsertStatementFromObject
		*//
		*//  AUTHOR: White Light Computing, Inc. 06/05/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Builds the SQL Insert statement from an object.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       toData      - Usually a SCATTER NAME object
		*//       tcFilename  - table name
		*//       toSQLRecord - SQL Record Object 
		*//       tlUseNamedParameters - Create parameters 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/28/2020 - JLM - Created 
		*//******************************************************************************************  
		IF NOT This.lVFPTable 
		   RETURN DODEFAULT(m.toData, m.tcFilename, m.toSQLRecord, m.tlUseNamedParameters)
		ELSE
		   LOCAL ;
		       laFields[1];
		      ,lcField AS Character ;
		      ,lcFieldList AS Character ;
		      ,lcParmName AS Character ;
		      ,lcRawValue AS Character ;
		      ,lcSQL AS Character ;
		      ,lcSkipFields AS Character ;
		      ,lcType AS Character ;
		      ,lcValue AS Character ;
		      ,lcValueList AS Character ;
		      ,lnFields AS Integer ;
		      ,lnX AS Integer
		      
		   lcSQL = "INSERT INTO " + STRTRAN(m.tcFileName,' ','_')

		   lcFieldList = SPACE(0)
		   lcValueList = SPACE(0)

		   IF EMPTY(THIS.cSkipFieldsForUpdates)
		      lcSkipFields = ",TIMESTAMP_COLUMN,"
		   ELSE
		      lcSkipFields = ",TIMESTAMP_COLUMN," + UPPER(THIS.cSkipFieldsForUpdates) + ","
		   ENDIF

		   *-- If a SQL Record was passed used its structure to look for fields otherwise use the data record
		   lnFields = AMEMBERS(laFields,IIF(VARTYPE(m.toSqlRecord)="O",m.toSqlRecord,m.toData) )

		   FOR lnX=1 TO m.lnFields
		      lcField = laFields[m.lnX]

		      *-- We can't deal with Timestamp columns and any other fields to be skipped
		      *-- so just loop out of this field
		      IF "," + UPPER(m.lcField) + ","  $ m.lcSkipFields
		         LOOP
		      ENDIF

		      lcRawValue = EVALUATE("toData." + m.lcField)
		      *-- Handle case where an error occurred
		      IF (this.lInternalError)
		         this.lInternalError = .F.  && Field that doesn't exist in table but exists in local cursor
		         this.lerror = .f.
		         LOOP  && Skip this field
		      ENDIF

		      lcType = VARTYPE(m.lcRawValue)

		      IF NOT m.tlUseNamedParameters 
		         DO CASE
		            CASE m.lcType = "C"
		               lcValue = '[' + m.lcRawValue + ']'  && Different from Paul's orginal code.
		            CASE m.lcType = "N"
		               lcValue = STRTRAN( TRANSFORM(m.lcRawValue),",",".")
		            CASE m.lcType = "L"
		               lcValue = IIF(m.lcRawValue,'.T.','.F.')
		            CASE m.lcType = "D"
		               lcValue = [{]+IIF(EMPTY(m.lcRawValue),"",DTOC(m.lcRawValue))+[}]

		            CASE m.lcType = "T"
		               lcValue = [{]+IIF(EMPTY(m.lcRawValue),"//::",TTOC(m.lcRawValue))+[}]

		            CASE m.lcType = "Y"
		               lcValue = TRANSFORM( m.lcRawValue,"" )
		            
		            CASE m.lcType = "X"  && NULL
		               lcValue = "null"        
		            OTHERWISE
		               LOOP   && Invalid Type - skip
		         ENDCASE
		         lcValueList = m.lcValueList + m.lcValue + ","
		      ELSE
		         lcParmName = "__" + m.lcField
		         IF INLIST(m.lcType, "D", "T")
		            IF This.lReplaceEmptyDateWithNull AND EMPTY(m.lcRawValue)
		               lcRawValue = NULL
		            ENDIF
		         ENDIF

		         this.AddParameter(m.lcRawValue,m.lcParmName)
		         lcValueList = m.lcValueList + "?" + m.lcParmName + ","
		      ENDIF

		      lcFieldList = m.lcFieldList + '' +  m.lcField + ','
		   ENDFOR

		   IF EMPTY(m.lcFieldList) OR EMPTY(m.lcValueList)
		      RETURN ""
		   ELSE
		      lcFieldList = SUBSTR(m.lcFieldList,1,LEN(m.lcFieldList) - 1)
		      lcValueList = SUBSTR(m.lcValueList,1,LEN(m.lcValueList) - 1)
		   ENDIF

		   lcSQL = m.lcSQL + " (" + m.lcFieldList + ") VALUES (" +  m.lcValueList + ")"
		   RETURN m.lcSQL
		ENDIF 
	ENDPROC


	PROCEDURE connect
		LPARAMETER ;
		    tcConnectString AS Character ;
		   ,tlAsynch AS Boolean ;
		   ,tlNoAutoTransactions AS Boolean 
		*//******************************************************************************************
		*//  FUNCTION NAME: Connect
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcConnectString      - passed thru
		*//       tlAsynch             - passed thru 
		*//       tlNoAutoTransactions - passed thru
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************  
		IF This.lVFPTable
		   *-- Nothing at this time 
		ELSE
		   DODEFAULT(m.tcConnectString, m.tlAsynch, m.tlNoAutoTransactions)
		ENDIF  

		RETURN  
	ENDPROC


	PROCEDURE rollback
		*//******************************************************************************************
		*//  FUNCTION NAME: Rollback
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Rollback 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************
		IF This.lVfpTable
		   RETURN THIS.VfpRollBack()
		ELSE 
		   RETURN DODEFAULT()
		ENDIF    
	ENDPROC


	PROCEDURE commit
		*//******************************************************************************************
		*//  FUNCTION NAME: Commit
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************  
		IF This.lVfpTable
		   RETURN THIS.VfpCommit()
		ELSE 
		   RETURN DODEFAULT()
		ENDIF    
	ENDPROC


	PROCEDURE close
		*//******************************************************************************************
		*//  FUNCTION NAME: Close 
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************  
		IF This.lVFPTable
		   *-- Nothing at this time 
		ELSE
		   DODEFAULT()
		ENDIF  

		RETURN  
	ENDPROC


	PROCEDURE sqlcancel
		*//******************************************************************************************
		*//  FUNCTION NAME: sqlCancel
		*//
		*//  AUTHOR: White Light Computing, Inc. 04/28/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     04/28/2013 - JLM - Created 
		*//******************************************************************************************  
		IF This.lVfpTable
		   *-- Nothing at this time 
		ELSE 
		   RETURN DODEFAULT()
		ENDIF    
	ENDPROC


	PROCEDURE updatefromcursor
		LPARAMETERS ;
		    tcCursorName AS Character ;
		   ,tcTable AS Character ;
		   ,tcPKField AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: 10/08/2013
		*//
		*//  AUTHOR: White Light Computing, Inc. 10/08/2013 
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Updates the VFP table from a cursor in bulk. Will scan cursor and insert into from NAME oNewInsert 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursorName - Cursor name (required)
		*//       tcTable      - Table name (required)
		*//       tcPKField    - Primary Key field (required)
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/08/2013 - JLM - Created 
		*//******************************************************************************************  
		IF NOT This.lVFPTable 
		   RETURN DODEFAULT(m.tcCursorName,m.tcTable,m.tcPKField)
		ELSE 
		   LOCAL ;
		       lcOldDeleted AS Character ;
		      ,lcPKField AS Character ;
		      ,llRetVal AS Boolean ;
		      ,lnOldRecNo AS Integer ;
		      ,lnRecord AS Integer 

		   *-- All three arguments are required
		   ASSERT PCOUNT() = 3 MESSAGE "All three arguments to this method are required - cursor name, table name and PK field name"

		   This.cUpdateCursor   = m.tcCursorName
		   This.cUpdateTable    = m.tcTable
		   This.cUpdateKeyField = m.tcPKField

		   lcOldDeleted = SET("Deleted")
		   lnOldRecNo = RECNO(tcCursorName)
		   llRetVal = .T.

		   SET DELETED OFF
		   SELECT (m.tcCursorName)
		   GOTO top
		   lnRecord = 0
		   DO WHILE .T.
		      lnRecord = GETNEXTMODIFIED(m.lnRecord, m.tcCursorName)
		      IF m.lnRecord = 0
		         EXIT
		      ELSE
		         GOTO lnRecord IN (m.tcCursorName)
		      ENDIF
		      
		      DO CASE 
		         CASE This.lBulkLoad ;
		         AND NOT This.UpdateBulkRecord()
		            llRetVal = .F.
		            EXIT
		        
		         CASE NOT This.lBulkLoad ;
		         AND NOT This.UpdateRecord()
		            llRetVal = .F.
		            EXIT

		         OTHERWISE
		            IF This.iNewPK > 0
		               lcPKField = m.tcCursorName + "." + m.tcPKField
		               REPLACE &lcPKField WITH This.iNewPK IN (m.tcCursorName)
		               This.iNewPK = 0
		            ENDIF
		      ENDCASE 
		   ENDDO

		   IF This.lUpdateAfterSave AND m.llRetVal
		      TABLEUPDATE(.T., .F., m.tcCursorName)
		   ENDIF

		   SET DELETED &lcOldDeleted
		   SELECT (m.tcCursorName)

		   DO CASE
		      CASE This.lUpdateAfterSave AND m.lnOldRecNo > 0
		           LOCATE FOR RECNO(tcCursorName) = m.lnOldRecNo

		      CASE This.lUpdateAfterSave AND m.lnOldRecNo < 0
		           IF This.iNewPK > 0
		              LOCATE FOR &lcPKField = This.iNewPK
		           ENDIF
		      OTHERWISE
		           LOCATE FOR RECNO(tcCursorName) = m.lnOldRecNo
		   ENDCASE

		   RETURN m.llRetVal
		ENDIF    


		 
	ENDPROC


	PROCEDURE updaterecord
		*//******************************************************************************************
		*//  FUNCTION NAME: UpdateRecord
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/22/2018
		*//
		*//  COPYRIGHT © 2010-2018   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Updates the single record.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/22/2018 - JLM - Created 
		*//******************************************************************************************  
		IF NOT This.lVFPTable 
		   RETURN DODEFAULT()
		ELSE  
		   LOCAL ;
		      laCursor[1] ;
		      ,laMembers[1];
		      ,lcCursor AS Character ;
		      ,lcFieldName AS Character ;
		      ,lcPKField AS Character ;
		      ,lcTable AS Character ;
		      ,lcUpdateTable AS Character ;
		      ,liFields AS Integer ;
		      ,liIndex AS Integer ;
		      ,llDeleted AS Boolean ;
		      ,llNew AS Boolean ;
		      ,llRetVal AS Boolean ;
		      ,loCursor AS Object ;
		      ,luPKVal AS Variant

		   llRetVal = .T.

		   loCursor = CREATEOBJECT("Empty")

		   lcPKField = ALLTRIM(This.cUpdateKeyField)
		   *-- Comment JLM of WLC 09/23/2013
		   *-- STRTRAN for space to equal '_' is because if a table name has a space in it
		   *-- VFP alias' it with a '_'. I.E. Import EMI.dbf alias equals Import_EMI
		   m.lcUpdateTable = ALLTRIM(This.cUpdateTable)
		   m.lcTable       = STRTRAN(lcUpdateTable,' ','_')  
		   m.lcCursor      = ALLTRIM(This.cUpdateCursor)

		   This.iNewPK = 0

		   AFIELDS(laCursor, m.lcCursor)

		   liFields = ALEN(laCursor, 1)

		   * Loop through all the fields

		   FOR liIndex = 1 TO m.liFields
		      lcFieldName = laCursor[m.liIndex, 1]
		      
		      IF laCursor[m.liIndex, 2] = "G"
		         * General fields can't be EVAL'd, so skip.
		         LOOP
		       ENDIF

		      DO CASE
		      CASE GETFLDSTATE(0, m.lcCursor) = 2 && Deleted record
		         llDeleted = .T.
		         * No sense processing any other fields,
		         * because the record is deleted
		         EXIT
		      
		      CASE (!(EVALUATE(m.lcCursor + "." + m.lcFieldName) == OLDVAL(m.lcFieldName, m.lcCursor)) ;
		            OR ISNULL(EVALUATE(m.lcCursor + "." + m.lcFieldName)) AND NOT ISNULL(OLDVAL(m.lcFieldName, m.lcCursor)) ;
		            OR NOT ISNULL(EVALUATE(m.lcCursor + "." + m.lcFieldName)) AND ISNULL(OLDVAL(m.lcFieldName, m.lcCursor))) ;
		            AND NOT (UPPER(m.lcFieldName) == UPPER(m.lcPKField))
		         * This field has *really* changed
		         * Add it to the object along with
		         * its value
		         ADDPROPERTY(loCursor, m.lcFieldName, EVALUATE(m.lcCursor + "." + m.lcFieldName))


		      OTHERWISE
		         IF UPPER(m.lcFieldName) = UPPER(m.lcPKField)
		            ** acs add code to allow appended records to be seen as new
		            * PCM - 2/1/2007 - Add check to see if the PK is 0 so I can include
		            * records as part of an initial query that don't exist in the table
		            * yet, but have them saved.
		               * PCM - 8/27/2009 - Need to include the PK on a new record if it's locally generated.
		               luPKVal = EVALUATE(m.lcCursor + "." + m.lcFieldName)
		            
		            IF GETFLDSTATE(0,m.lcCursor) = 3 OR (GETFLDSTATE(0,m.lcCursor) = 4 AND EMPTY(&lcFieldName)) ;
		                  OR (!This.lLocallyGeneratedPK AND IIF(VARTYPE(m.luPKVal) = "N", m.luPKVal = 0, EMPTY(m.luPKVal)))
		            
		                * new record
		               * No need to add the PK field to the object
		               * PCM - 2/1/2007 - Changed so that code below can be triggered
		               *                  Same part of above change.
		               IF NOT This.lLocallyGeneratedPK
		                  ADDPROPERTY(loCursor, m.lcFieldName, EVALUATE(m.lcCursor + "." + m.lcFieldName))
		               ENDIF   
		               llNew = .T.
		            ELSE
		               * old record
		               * Add the key field so the sqlBuildInsertStatementFromObject method
		               * can use it to construct the update method
		               ADDPROPERTY(loCursor, m.lcFieldName, EVALUATE(m.lcCursor + "." + m.lcFieldName))
		               llNew = .F.
		            ENDIF
		         ELSE
		            * It's not the PK field and hasn't been flagged as changed
		            IF This.lUpdateAllFields
		               ADDPROPERTY(m.loCursor, m.lcFieldName, EVALUATE(m.lcCursor + "." + m.lcFieldName))
		            ENDIF
		         ENDIF
		      ENDCASE
		   ENDFOR
		   
		   DO CASE
		   CASE AMEMBERS(laMembers,m.loCursor) > 1
		      * Fields were modified so we're going to do an update
		      * or Insert - note that loCursor always has one member, the PK field
		      * Don't include the PK field in the update list
		      * as it's auto-generated
		       * PCM 8/27/2009 - Allow you to include the PK as part of an INSERT by setting a flag.
		      This.cSkipFieldsForUpdates = This.cSkipFieldsForUpdates ;
		         + IIF(not EMPTY(This.cSkipFieldsForUpdates),",","");
		           + IIF(This.lLocallyGeneratedPK, "", m.lcPKField)

		      IF m.llNew
		         This.cSql = This.sqlBuildInsertStatementFromObject(m.loCursor,m.lcTable,,.F.)  && JLM changed last parameter from .T. to .F.
		      ELSE
		         This.cSql = This.sqlBuildUpdateStatementFromObject(m.loCursor,m.lcTable,m.lcPKField,,,.T.)  && JLM should think about this one too.
		      ENDIF
		      
		   CASE llDeleted
		      * no fields were modified, but the record was deleted
		      * PCM - 10/17/2005 - If we've already embedded the owner in the name, don't
		      * prefix it with dbof.
		       * PCM - 8/27/2009 - Fix code to be able to deal with a character based PK field
		       luPKVal = EVALUATE(m.lcCursor + "." + m.lcPKField)

		      IF "." $ m.lcTable
		          This.cSQL = "DELETE FROM " ;
		            + m.lcTable + " WHERE " ;
		                + m.lcTable + "." + m.lcPKField ;
		               + " = " ;
		              + IIF(VARTYPE(m.luPKVal) = "N", ;
		                    TRANSFORM(m.luPKVal), ;
		                     ['] + TRIM(STRTRAN(TRANSFORM(m.luPKVal), "'", "''"))+ ['])
		      ELSE
		          This.cSQL = "DELETE FROM dbo." ;
		            + m.lcTable + " WHERE " ;
		                + m.lcTable + "." + m.lcPKField ;
		               + " = " ;
		              + IIF(VARTYPE(m.luPKVal) = "N", ;
		                    TRANSFORM(m.luPKVal), ;
		                     ['] + TRIM(STRTRAN(TRANSFORM(m.luPKVal), "'", "''"))+ ['])
		      ENDIF

		   OTHERWISE
		      * There's nothing to do with this record
		      * The buffer may be dirty, but the values
		      * haven't changed
		      This.cSql = SPACE(0)
		      * We'll clean the buffers while we're here
		      TABLEREVERT(.f., m.lcCursor)
		   ENDCASE

		   IF NOT EMPTY(This.cSQL)
		      llRetVal = This.Execute() > 0
		      This.oParameters = NULL
		      IF m.llRetVal 
		         IF m.llNew
		            IF This.lLocallyGeneratedPK
		            *-- Making an assumption here that the PK has been auto-filled 
		            *-- in by VFP using Incremental Integer
		               This.iNewPk = EVALUATE(ALLTRIM(m.lcTable-'.'-m.lcPKField))
		            ELSE
		               This.GetNewPK()
		            ENDIF
		         ENDIF   
		      ENDIF
		   ELSE
		      llRetVal = .T.
		   ENDIF

		   RETURN m.llRetVal
		ENDIF 
		 
	ENDPROC


	PROCEDURE zzabout
		******************************************************************************************
		*  METHOD NAME: zzAbout
		*
		*  AUTHOR: White Light Computing, Inc.
		*
		*  FORM/CLASS DESCRIPTION:
		*     This is used for VFP Tables. 
		*     If the property This.lVFPTable is not true, then goes to the SQL Server parent methods.
		*    
		*  EXPLICIT LICENSE:
		*     Customers of White Light Computing are granted a perpetual, non-transferable, 
		*     non-exclusive, royalty free, worldwide license to use and employ such materials 
		*     within their business once they have paid for the right to do so.
		*
		*     No license is granted for any use outside of our customer's business 
		*     without the express written permission from White Light Computing, Inc.
		*   
		*     No license is granted to any other developer other than for use within our
		*     customer's business. Other developers wishing to license generic portions of the 
		*     source code for their own use can inquire by calling the offices of 
		*     White Light Computing, Inc.
		*
		*     (all terms are subject to change by implementation of separate contract with
		*      White Light Computing, Inc.)
		*
		*  INPUT PARAMETERS:
		*    None
		* 
		*  OUTPUT PARAMETERS:
		*    None
		* 
		******************************************************************************************
	ENDPROC


ENDDEFINE
*
*-- EndDefine: wlcvfp
**************************************************

**************************************************
*-- Class:        basebizobj (c:\develop\codeminenew\dmie_rv\custom\wlcbizobj.prg)
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   04/20/21 02:21:08 PM
*
DEFINE CLASS basebizobj AS custom


	*-- Primary table name used by bizobj
	ctable = (SPACE(0))
	*-- Reference to SQL object
	osql = .NULL.
	*-- The name of a the key field for the cursor being used to send C/U/D commands to SQL Server
	cupdatekeyfield = ('_PK')
	cconnectionstring = (SPACE(0))
	lautoconnectsql = .T.
	*-- Add fields here to have them removed from the updated fields list.
	cskipfieldsforupdates = ""
	*-- This is the fox table to open
	ctable_fox = (SPACE(0))
	*-- The alias used by dbfopen()
	ctable_fox_alias = (SPACE(0))
	cerrormsg = (SPACE(0))
	*-- Collection filled with any validation errors
	ovalidationerrors = .NULL.
	nreturnedrecords = 0
	csqlclass = "wlcSQL"
	cdefaultsort = ""
	orules = .NULL.
	lvalidateonsave = .T.
	cuserid = ""
	lsetemptydatestonull = .T.
	lsetemptyfktonull = .T.
	loverrideservertime = .F.
	tservertime = {}
	*-- Name of the UpdatedBy field.
	cupdatedby = "UpdatedBy"
	csearchcursor = ""
	*-- Name of the AddedBy field.
	caddedby = "AddedBy"
	*-- Name of the tUpdatedOn Field.
	cupdatedon = "UpdatedOn"
	*-- Name of the tAddedOn field
	caddedon = "AddedOn"
	cmaintenancecursor = ""
	csqlschema = "dbo"
	Name = "basebizobj"

	*-- Set this property to true if you want an error sent to the errorhandeler on sql errors.
	lraiseerror = .F.


	PROCEDURE new
		LPARAMETERS tcCursor AS CHARACTER
		*//******************************************************************************************
		*//  FUNCTION NAME: New
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION:
		*//     Creates a new record for the cursor/table
		*//
		*//  PARAMETERS:
		*//    INPUT PARAMETERS:
		*//       tcCursor AS Character
		*//
		*//    OUTPUT PARAMETERS:
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/17/2014 - PCM / JLM - Created / Modified
		*//     02/28/2020 - JLM - Added [<<This.cSQLSchema>>].
		*//******************************************************************************************
		LOCAL ;
		   lcTable AS CHARACTER

		IF VARTYPE(m.tcCursor) = 'C' ;
		   AND NOT EMPTY(NVL(m.tcCursor,SPACE(0)))
		   lcTable = ALLTRIM(m.tcCursor)
		ELSE
		   lcTable = THIS.cMaintenanceCursor
		ENDIF

		lcTable = JUSTFNAME(m.lcTable)

		IF !USED(m.lcTable)
		   THIS.GetEmptyCursor(m.lcTable)
		ENDIF

		APPEND BLANK IN (m.lcTable)

		THIS.UpdateAddedOnFields(m.lcTable)
		THIS.UpdateUpdatedOnFields(m.lcTable)
		THIS.UpdateEmptyFKtoNull(m.lcTable)

		RETURN
	ENDPROC


	PROCEDURE getemptycursor
		LPARAMETERS tcCursor AS Character, tcTable AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: GetEmptyCursor
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Gets an empty buffered cursor
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//     tcCursor (Optional) - Cursor name to create. If empty, it uses This.cTable
		*//     tcTable (optional) - Table to retrieve from. If empty, it uses This.cMaintenanceCursor.
		*//                          
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     10/17/2014 - PCM - Created 
		*//     02/28/2020 - JLM - Modified and Added [<<This.cSQLSchema>>]. 
		*//******************************************************************************************  
		LOCAL ;
		    lcTable AS Character ;
		   ,lcCursor AS Character ;
		   ,lcSQL AS Character

		IF VARTYPE(m.tcTable) = 'C' ;
		AND NOT EMPTY(NVL(m.tcTable,SPACE(0)))
		   lcTable = ALLTRIM(m.tcTable)
		ELSE
		   lcTable = JUSTSTEM(JUSTFNAME(ALLTRIM(This.cTable)))
		ENDIF

		IF VARTYPE(m.tcCursor) = 'C' ;
		OR EMPTY(NVL(m.tcCursor,SPACE(0))) 
		   lcCursor = ALLTRIM(m.tcCursor)
		ELSE
		   lcCursor = This.cMaintenanceCursor
		ENDIF

		TEXT TO lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		   SELECT
		      [<<m.lcTable>>].*
		   FROM
		      [<<This.cSQLSchema>>].[<<m.lcTable>>]
		   WHERE
		      1 = 0
		ENDTEXT

		USE IN SELECT(m.lcCursor)

		This.oSQL.Execute(m.lcSQL, m.lcCursor)
	ENDPROC


	PROCEDURE save
		LPARAMETERS tcCursor AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: Save
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Save the cursor.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - (Optional) Cursor to update from. 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Failed either validation, or error updating.
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    11/20/2014 - PCM/JLM - Created/Modified 
		*//    02/28/2020 - JLM - Modified to handle a cursor record set instead a of single record
		*//               for This.Update code and validation. 
		*//****************************************************************************************** 
		LOCAL ;
		    laField[1];
		   ,lcTable AS Character ;
		   ,llReturn AS Boolean;
		   ,lnRecord AS Integer ;
		   ,lnSelect AS Integer

		llReturn = .T.
		lnSelect = SELECT()

		IF VARTYPE(m.tcCursor) = "C"
		   lcTable = m.tcCursor
		ELSE
		   lcTable = This.cMaintenanceCursor
		ENDIF

		IF USED(m.lcTable)
		   IF ATC('.',m.lcTable) > 0
		      lcTable = JUSTEXT(m.lcTable)
		   ENDIF    

		   SELECT (m.lcTable)
		   LOCATE 

		   lnRecord = 0
		   llReturn = .T.
		   DO WHILE m.llReturn 
		      lnRecord = GETNEXTMODIFIED(m.lnRecord, m.lcTable)
		      IF m.lnRecord = 0
		         EXIT
		      ELSE
		         GOTO lnRecord IN (m.lcTable)
		      ENDIF

		      This.UpdateUpdatedOnFields(m.lcTable)
		      This.UpdateEmptyFKtoNull(m.lcTable)
		      This.UpdateEmptyDatestoNull(m.lcTable)

		      IF This.lValidateOnSave
		         llReturn = This.Validation(m.lcTable)
		      ENDIF
		   ENDDO   

		   IF m.llReturn
		      llReturn = This.oSQL.UpdateFromCursor(m.lcTable, This.cTable, This.cUpdateKeyField)
		   ENDIF
		ELSE
		   llReturn = .T.
		ENDIF 

		SELECT (m.lnSelect)

		RETURN m.llReturn
		 
	ENDPROC


	PROCEDURE validation
		LPARAMETERS tcCursor AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: Validation
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Validates the data in the various fields.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - The cursor to run the validation against.
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Unsuccessful
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/28/2014 - PCM - Created 
		*//****************************************************************************************** 
	ENDPROC


	*-- Delete Event.
	PROCEDURE delete
		LPARAMETERS tuPK 
		*//******************************************************************************************
		*//  FUNCTION NAME: Delete
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Remove a record from the table
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tuPK - Primary key of the record to remove
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Unsuccessful
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/28/2014 - PCM - Created 
		*//    12/03/2018 - JLM - Added IF This.CanDelete(m.tuPK)
		*//    02/28/2020 - JLM - Added This.SQLSchema
		*//****************************************************************************************** 
		LOCAL ;
		    lcSQL AS Character ;
		   ,loSelect AS cSelect OF WlcBizObj ;
		   ,loParameter AS Object ;
		   ,llReturn AS Boolean 

		loSelect    = CreateFactory('CSelect')
		loParameter = This.oSQL.GetParameterObject()
		llReturn    = .T.

		loParameter.Add('PK', m.tuPK)

		IF This.CanDelete(m.tuPK)
		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		      DELETE FROM
		         [<<This.cSQLSchema>>].[<<This.cTable>>]
		      WHERE
		         [<<This.cTable>>].[<<This.cUpdateKeyField>>] = ?PK
		   ENDTEXT
		   llReturn = This.oSQL.Execute(lcSQL, 'curResult', loParameter) > 0
		   
		   USE IN SELECT('curResult')
		ELSE
		   *-- references found - cannot delete
		   llReturn = .F.
		ENDIF 

		RETURN m.llReturn
	ENDPROC


	*-- Retrieve a single record from the table using the PK.
	PROCEDURE getrecord
		LPARAMETERS tuPK, tcCursor AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: GetRecord
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Retrieve a single record from the table using the PK as the key
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tuPK (Required) - Primary Key
		*//       tcCursor (Optional) - Cursor name to put record into.
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Failed
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/17/2014 - PCM / JLM - Created / Modified
		*//******************************************************************************************  
		IF VARTYPE(m.tcCursor) <> 'C' ;
		OR EMPTY(NVL(m.tcCursor,SPACE(0))) 
		   tcCursor = This.cMaintenanceCursor 
		ENDIF

		RETURN This.GetCursorByKey(m.tcCursor, This.cTable, tuPK, This.cUpdateKeyField)
	ENDPROC


	*-- Retrieve all the records in a table (not advised for large tables!)
	PROCEDURE getallrecords
		LPARAMETERS tcCursor AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: GetAllRecords
		*//
		*//  AUTHOR: White Light Computing, Inc. 10/7/2004
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Retrieve all the records in a table (not advised for large tables!)
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor (Optional) - Cursor name to put records into.
		*//
		*//    OUTPUT PARAMETERS: 
		*//       Is a cursor - Either tcCursor value or This.cMaintenanceCursor 
		*//       .T. or .F.  
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     10/07/2004 - Paul Mrozowski
		*//     02/28/2020 - JLM - Added [<<This.cSQLSchema>>]. 
		*//******************************************************************************************  
		LOCAL lcSQL AS Character

		IF VARTYPE(m.tcCursor) <> 'C' ;
		OR EMPTY(NVL(m.tcCursor,SPACE(0))) 
			tcCursor = This.cMaintenanceCursor
		ENDIF

		TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
			SELECT
				[<<This.cTable>>].*
			FROM
				[<<This.cSQLSchema>>].[<<This.cTable>>]
		ENDTEXT

		IF !EMPTY(This.cDefaultSort)
			TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2
				ORDER BY
					<<This.cDefaultSort>>
			ENDTEXT
		ENDIF

		RETURN This.oSQL.Execute(m.lcSQL, m.tcCursor)
	ENDPROC


	*-- Return a cursor for the passed in table, filtered by a specific key.
	PROCEDURE getcursorbykey
		LPARAMETERS ;
		    tcCursor AS Character ;
		   ,tcSourceTable AS Character ;
		   ,tuKey ;
		   ,tcKeyField AS Character ;
		   ,tcSortBy AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: GetCursorByKey
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Return a cursor for the specified table, filtered by the key.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - Resulting cursor name
		*//       tcSourceTable - Source Table
		*//       tuKey - Key to search for
		*//       tcKeyField - (Optional) - Key fieldname. If not specified,
		*//                   assumed to be the key field.
		*//       tcSortBy - (Optional) - column(s) to sort by
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Failed. Check oSQL.cErrors for more info.
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     10/28/2014 - PCM - Created 
		*//     02/28/2020 - JLM - Added [<<This.cSQLSchema>>]. 
		*//****************************************************************************************** 
		LOCAL ;
		    lcSQL AS Character ;
		   ,loParameter AS Object ;
		   ,lcKeyField AS Character 

		loParameter = This.oSQL.GetParameterObject()
		loParameter.Add('Key', tuKey)

		lcKeyField = This.cUpdateKeyField

		IF VARTYPE(m.tcKeyField) = 'C'
		   lcKeyField = tcKeyField
		ENDIF

		TEXT TO lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		   SELECT
		      [<<m.tcSourceTable>>].*
		   FROM
		      [<<This.cSQLSchema>>].[<<m.tcSourceTable>>]
		   WHERE
		      [<<m.tcSourceTable>>].[<<m.lcKeyField>>] = ?Key
		ENDTEXT

		IF VARTYPE(m.tcSortBy) = 'C' AND NOT EMPTY(m.tcSortBy)
		   TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2
		      ORDER BY
		         <<m.tcSortBy>>
		   ENDTEXT
		ENDIF

		RETURN (This.oSQL.Execute(m.lcSQL, m.tcCursor, m.loParameter) >= 0)
	ENDPROC


	PROCEDURE checkforerror
		LPARAMETER ;
		    tcSQL AS Character ;
		   ,tcResultCursor AS Character ;
		   ,toParameters AS Object
		*//******************************************************************************************
		*//  FUNCTION NAME: CheckForError
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    This event is bound osql.execute
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcSQL - SQL command
		*//       tcResultCursor (Optional) - Result cursor name
		*//       toParameters (Optional) - Parameter object
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/28/2014 - PCM - Created 
		*//****************************************************************************************** 
		IF THIS.osql.lError
		   PUBLIC lcLastSql, lnSqlError, lnODBCErrorno, lcSQLErrorMsg

		   lcLastSql     = THIS.osql.csql
		   lnSqlError    = THIS.osql.nErrorNo
		   lnODBCErrorno = THIS.osql.nODBCErrorno
		   lcSQLErrorMsg = THIS.osql.cErrorMsg

		   ERROR lcSQLErrorMsg
		ENDIF
	ENDPROC


	PROCEDURE cskipfieldsforupdates_access
		*//******************************************************************************************
		*//  FUNCTION NAME: cSkipFieldsForUpdates_Access
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
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
		*//    10/29/2014 - PCM - Created 
		*//****************************************************************************************** 
		LOCAL ;
		   lcFieldList AS Character 

		m.lcFieldList = [] && add comma seperated list here
		IF NOT EMPTY(m.lcFieldList)
		   RETURN This.cSkipFieldsForUpdates+[,] + m.lcFieldList
		ELSE
		   RETURN This.cSkipFieldsForUpdates
		ENDIF
	ENDPROC


	PROCEDURE cskipfieldsforupdates_assign
		LPARAMETERS tcSkipFieldsForUpdates AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: cSkipFieldsForUpdates_Assign
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
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
		*//       tcSkipFieldsForUpdates 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/29/2014 - PCM - Created 
		*//****************************************************************************************** 
		THIS.cSkipFieldsForUpdates = STRTRAN(m.tcSkipFieldsForUpdates,SPACE(1),SPACE(0))

		IF NOT EMPTY(THIS.cSkipFieldsForUpdates)
		   THIS.oSQL.resettodefault([cSkipFieldsForUpdates]) && make sure all local changes are removed.
		   THIS.oSQL.cSkipFieldsForUpdates = THIS.oSQL.cSkipFieldsForUpdates+[,]+THIS.cSkipFieldsForUpdates
		ENDIF

		RETURN 
	ENDPROC


	*-- Will open a Fox table using dbfOpen()
	PROCEDURE openfoxtable
		******************************************************************
		*  FUNCTION NAME: Openfoxtable
		*
		*  AUTHOR, DATE:
		*	  Paul Mrozowski, 1/25/2007
		*  PROCEDURE DESCRIPTION:
		*
		*  INPUT PARAMETERS:
		*	  None
		*  OUTPUT PARAMETERS:
		*	  None
		******************************************************************
		LOCAL lcAlias

		IF !EMPTY(This.cTable_Fox)
		   lcAlias = IIF(!EMPTY(This.cTable_Fox_Alias), This.cTable_Fox_Alias, This.cTable_Fox)
		   USE (This.cTable_Fox) IN 0 AGAIN ALIAS (lcAlias)
		ENDIF
	ENDPROC


	*-- Add a validation error message to the collection
	PROCEDURE addvalidationerror
		LPARAMETERS ;
		    tcErrorMessage AS Character ;
		   ,tcCode AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: AddValidationError
		*//
		*//  AUTHOR: White Light Computing, Inc. 01/29/2007
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Add a validation error to the list
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcErrorMessage - Error message
		*//       tcCode         - Code identifying the messag
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     01/29/2007 - Paul Mrozowski - Created 
		*//******************************************************************************************  
		LOCAL loError AS Object 

		loError = CreateFactory("Empty")

		ADDPROPERTY(loError, "Message", tcErrorMessage)
		ADDPROPERTY(loError, "Code", tcCode)

		IF VARTYPE(This.oValidationErrors) <> "O"
		   This.oValidationErrors = CreateFactory("Collection")
		ENDIF

		This.oValidationErrors.Add(m.loError)
	ENDPROC


	PROCEDURE clearvalidationerrors
		*//******************************************************************************************
		*//  FUNCTION NAME: ClearValidationErrors
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Clear any existing validation errors
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
		This.oValidationErrors = NULL

		RETURN 
	ENDPROC


	*-- Returns a string out of the validation errors collection.
	PROCEDURE getvalidationerrorsasstring
		LPARAMETERS tcDelimiter
		*//******************************************************************************************
		*//  FUNCTION NAME: GetValidationErrosAsString
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Returns a string out of the validation errors collection 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcDelimiter (optional) - Delimiter for the string (defaults
		*           to CHR(13). Eg. "</br>"
		*//
		*//    OUTPUT PARAMETERS: 
		*//       String
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/28/2014 - PCM - Created 
		*//****************************************************************************************** 
		LOCAL ;
		    lcError AS Character ;
		   ,lcDelimiter AS Character 

		lcError     = SPACE(0)
		lcDelimiter = CHR(13)

		IF VARTYPE(m.tcDelimiter) = 'C'
		   lcDelimiter = m.tcDelimiter
		ENDIF

		IF VARTYPE(This.oValidationErrors) = 'O'
		   FOR EACH oError IN This.oValidationErrors
		       lcError = m.lcError ;
		               + oError.Message + m.lcDelimiter

		   ENDFOR
		ENDIF

		RETURN m.lcError
	ENDPROC


	*-- Do a wildcard search against a specific column
	PROCEDURE find
		LPARAMETERS ;
		    tcCursor AS Character ;
		   ,tcSourceTable AS Character ;
		   ,tuKey AS Character ;
		   ,tcKeyField AS Character ;
		   ,tlForceUpper AS Boolean
		*//******************************************************************************************
		*//  FUNCTION NAME: Find
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Similar to GetCursorByKey, but does a wildcard search instead
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//      tcCursor      - Resulting cursor name
		*//      tcSourceTable - Source Table
		*//      tuKey         - Key to search for
		*//      tcKeyField    - Key fieldname.
		*//      tlForceUpper (Optional) - Force the search to uppercase
		*//                                USE ONLY WITH CHARACTER FIELDS!
		*//
		*//    OUTPUT PARAMETERS: 
		*//       Creates the tcCusor
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/28/2014 - PCM - Created 
		*//    02/28/2020 - JLM - Added [<<This.cSQLSchema>>].
		*//****************************************************************************************** 
		LOCAL ;
		    lcSQL AS Character ;
		   ,loParameter AS Object ;
		   ,lcKeyField AS Character 

		loParameter = This.oSQL.GetParameterObject()

		IF m.tlForceUpper ;
		AND VARTYPE(m.tuKey) = 'C'
		   loParameter.Add('Key', UPPER(m.tuKey) + "%")
		ELSE
		   loParameter.Add('Key', tuKey + '%')
		ENDIF

		lcKeyField = This.cUpdateKeyField

		IF VARTYPE(tcKeyField) = 'C'
		   lcKeyField = m.tcKeyField
		ENDIF

		IF m.tlForceUpper
		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		      SELECT
		         [<<m.tcSourceTable>>].*
		      FROM
		         [<<This.cSQLSchema>>].[<<m.tcSourceTable>>]
		      WHERE
		         UPPER([<<m.tcSourceTable>>].[<<m.lcKeyField>>]) LIKE ?Key
		   ENDTEXT
		ELSE
		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		      SELECT
		         [<<m.tcSourceTable>>].*
		      FROM
		         [<<This.cSQLSchema>>].[<<m.tcSourceTable>>]
		      WHERE
		         [<<m.tcSourceTable>>].[<<m.lcKeyField>>] LIKE ?Key
		   ENDTEXT
		ENDIF

		RETURN (This.oSQL.Execute(m.lcSQL, m.tcCursor, loParameter) >= 0)
	ENDPROC


	PROCEDURE nreturnedrecords_access
		*//******************************************************************************************
		*//  FUNCTION NAME: nReturnRecords_Access
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
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
		*//    10/28/2014 - PCM - Created 
		*//****************************************************************************************** 
		IF VARTYPE(This.oSQL) = 'O'
		   RETURN This.oSQL.nReturnedRecords
		ELSE
		   RETURN 0
		ENDIF
	ENDPROC


	PROCEDURE ischanged
		LPARAMETERS tcCursor AS Character, tlSingleRecord AS Boolean 
		*//******************************************************************************************
		*//  FUNCTION NAME: 
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Checks to see if the passed in cursor has pending changes
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - Cursor to test
		*//       tlSingleRecord - Pass in .T. and it will only test the current record.
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/17/2014 - PCM - Created 
		*//******************************************************************************************  
		LOCAL ;
		    lcState AS Character ;
		   ,llChanged AS Boolean

		llChanged = .F.

		IF NOT USED(m.tcCursor)
		   RETURN llChanged
		ENDIF

		IF m.tlSingleRecord
		   lcState   = NVL(GETFLDSTATE(-1, m.tcCursor), '')
		   llChanged = "2" $ m.lcState OR "3" $ m.lcState OR "4" $ m.lcState
		ELSE
		   llChanged = GETNEXTMODIFIED(0, m.tcCursor) <> 0
		ENDIF

		RETURN m.llChanged
	ENDPROC


	*-- Save more than one bizobj wrapped inside of a transaction
	PROCEDURE transactionsave
		LPARAMETERS ;
		    tcCursor AS Character ;
		   ,toBo1 AS Object ;
		   ,tcCursor1 AS Character ;
		   ,toBo2 AS Object;
		   ,tcCursor2 AS Character ;
		   ,toBo3 AS Object;
		   ,tcCursor3 AS Character ;
		   ,toBo4 AS Object;
		   ,tcCursor4 AS Character ;
		   ,toBo5 AS Object;
		   ,tcCursor5 AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: TransationSave
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Save more than one bizobj wrapped inside of a transaction 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor  - cursor to save associated with this bizobj
		*//       toBo1     - toBo5 - Bizobj's to include in transaction
		*//       tcCursor1 - tcCursor5 - cursors associated with Bizobj
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    10/28/2014 - PCM - Created 
		*//****************************************************************************************** 
		LOCAL ;
		    lnParameter AS Integer ;
		   ,lcBoObj AS Object ;
		   ,llSuccess AS Boolean ;
		   ,lcCursor AS Character

		This.oSQL.BeginTransaction(IIF(VARTYPE(m.toBo1) = 'O', m.toBo1.oSQL, .F.), ;
		                           IIF(VARTYPE(m.toBo2) = 'O', m.toBo2.oSQL, .F.), ;
		                           IIF(VARTYPE(m.toBo3) = 'O', m.toBo3.oSQL, .F.), ;
		                           IIF(VARTYPE(m.toBo4) = 'O', m.toBo4.oSQL, .F.), ;
		                           IIF(VARTYPE(m.toBo5) = 'O', m.toBo5.oSQL, .F.))

		llSuccess = This.Save(m.tcCursor)

		IF m.llSuccess
		   FOR m.lnParameter = 1 TO 5
		      m.lcBoObj = 'toBo' + TRANSFORM(m.lnParameter)
		      m.lcCursor = 'tcCursor' + TRANSFORM(m.lnParameter)

		      IF VARTYPE(&lcBoObj) = 'O'
		         m.llSuccess = &lcBoObj..Save(&lcCursor)

		         IF !m.llSuccess
		            This.cErrorMsg = &lcBoObj..cErrormsg
		            IF EMPTY(This.cErrorMsg)
		               This.cErrorMsg = &lcBoObj..oSQL.cErrorMsg
		            ENDIF
		            EXIT
		         ENDIF
		      ENDIF
		   ENDFOR
		ELSE
		   IF EMPTY(This.cErrorMsg)
		      This.cErrorMsg = This.oSQL.cErrorMsg
		   ENDIF
		ENDIF

		IF m.llSuccess
		   This.oSQL.Commit()
		ELSE
		   This.oSQL.Rollback()
		ENDIF

		RETURN m.llSuccess
	ENDPROC


	PROCEDURE isunique
		LPARAMETERS ;
		    tuCurrentPK ;
		   ,tcField AS Character ;
		   ,tuValue
		*//******************************************************************************************
		*//  FUNCTION NAME: IsUnique
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Checks to see if the passed in field/value is unique
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tuCurrentPK - The primary key value of the current record
		*//       tcField - The field to check
		*//       tuValue - The value of the field to check
		*//
		*//    OUTPUT PARAMETERS: 
		*//       lnUnique = 0  - It's uniue
		*//       lnUnique > 0  - It's NOT unique
		*//       lnUnique = -1 - Bad PK passed?
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     12/30/2014 - PCM/JLM - Created/Modified
		*//     02/28/2020 - JLM - Added [<<This.cSQLSchema>>]. 
		*//******************************************************************************************    
		LOCAL ;
		    llUnique AS Boolean ;
		   ,lcSQL AS Character ;
		   ,loSelect AS cSelect OF WlcBizObj ;
		   ,loParamaeter AS Object 

		loSelect    = CreateFactory('CSelect')
		loParameter = This.oSQL.GetParameterObject()

		loParameter.Add('PK', m.tuCurrentPK)
		loParameter.Add('FieldValue', m.tuValue)

		llUnique = .F.

		TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		   SELECT
		      [<<This.cTable>>].[<<m.tcField>>]
		   FROM
		      [<<This.cSQLSchema>>].[<<This.cTable>>]
		   WHERE [<<This.cTable>>].[<<m.tcField>>] = ?FieldValue
		     AND [<<This.cTable>>].[<<This.cUpdateKeyField>>] <> ?PK
		ENDTEXT

		This.oSQL.Execute(lcSQL, 'curUnique', loParameter)

		IF USED('curUnique')
		   lnUnique = RECCOUNT('curUnique')
		ELSE
		   lnUnique = -1
		ENDIF 

		USE IN SELECT('curUnique')

		RETURN lnUnique
	ENDPROC


	PROCEDURE getallerrormessages
		*//******************************************************************************************
		*//  FUNCTION NAME: GetAllErrorMessages
		*//
		*//  AUTHOR: White Light Computing, Inc. 10/26/2012
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Returns the error messages regardless of where they occurred (validation, SQL, other) 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       All error messages as a string
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     10/26/2012 - Paul Mrozowski - Created 
		*//******************************************************************************************  
		LOCAL lcMsg AS Character 
		      
		lcMsg = IIF(!EMPTY(This.cErrorMsg), This.cErrorMsg + CHR(13), "") ;
		      + IIF(!EMPTY(This.oSQL.cErrorMsg), This.oSQL.cErrorMsg + CHR(13), "") ;
		      + This.GetValidationErrorsAsString()

		RETURN m.lcMsg
	ENDPROC


	*-- About this object, author, licensing, misc
	PROCEDURE zzabout
		******************************************************************************************
		*  METHOD NAME: zzAbout
		*
		*  AUTHOR: White Light Computing, Inc.
		*
		*  FORM/CLASS DESCRIPTION:
		*     This class library is assuming SQL Server. Please see BaseVFPBizObj for VFP 9. 
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


	PROCEDURE search
		LPARAMETERS t_parameter 
		*//******************************************************************************************
		*//  FUNCTION NAME: Search
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Called when the user selects the Search command button on a form.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       t_parameter - Could just be a NULL.
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     12/30/2014 - PCM / JLM - Created / Modified
		*//     02/28/2020 - JLM - Added [<<This.cSQLSchema>>]. 
		*//******************************************************************************************  
		LOCAL ;
		    lcSQL AS Character  ;
		   ,loParameter ;
		   ,loSelect

		loSelect = CreateFactory('cSelect')

		*!* Uncomment when parameters are passed --> loParameter = This.oSQL.GetParameterObject()

		TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		   SELECT
		      [<<This.cTable>>].* 
		   FROM
		      [<<This.cSQLSchema>>].[<<This.cTable>>]
		   WHERE
		      1 = 1
		ENDTEXT

		IF !EMPTY(This.cDefaultSort)
		   TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2
		      ORDER BY
		         <<This.cDefaultSort>>
		   ENDTEXT
		ENDIF

		This.oSQL.Execute(m.lcSQL, This.cSearchCursor, loParameter)

		STORE .NULL. TO loSelect, loParameter

		RETURN 
	ENDPROC


	PROCEDURE getservertime
		*//******************************************************************************************
		*//  FUNCTION NAME: GetServerTime
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Retrieve the date/time from the server if This.lOverrideServerTime and This.tServerTime
		*//     isn't empty. 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None
		*//
		*//    OUTPUT PARAMETERS: 
		*//       Validate Date Time (Can be empty)
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    11/20/2014 - PCM/JLM - Created/Modified
		*//****************************************************************************************** 
		LOCAL ;
		   loSelect AS cSelect OF WlcBizObj

		IF This.lOverrideServerTime ;
		AND NOT EMPTY(NVL(This.tServerTime,{//::}))
		   RETURN This.tServerTime
		ENDIF

		loSelect = CreateFactory('cSelect')

		This.oSQL.Execute('SELECT GETDATE() AS tCurrent', 'curTmpGetServerTime')

		IF USED('curTmpGetServerTime')
		   SELECT('curTmpGetServerTime')
		   LOCATE

		   This.tServerTime = curTmpGetServerTime.tCurrent
		ELSE
		   This.tServerTime = {//::}
		ENDIF

		USE IN SELECT('curTmpGetServerTime')

		RETURN This.tServerTime
	ENDPROC


	PROCEDURE updateaddedonfields
		LPARAMETERS tcCursor AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: UpdatedAddedOnOnFIelds
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Updates the Added On Fields if they exist.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - Cursor we are working with
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    11/20/2014 - JLM - Created 
		*//****************************************************************************************** 
		LOCAL ;
		    ltEvalAdded AS Datetime ;
		   ,lcEvalAdded AS Character ;
		   ,ltDateTime AS DateTime ;
		   ,lcAliasField AS Character 

		IF EMPTY(This.GetServerTime())
		   ltDateTime = DATETIME()
		ELSE
		   ltDateTime = This.tServerTime 
		ENDIF 

		IF NOT EMPTY(This.cAddedOn)
		   IF FSIZE(ALLTRIM(This.cAddedOn), m.tcCursor) > 0
		      lcAliasField = m.tcCursor + '.' + This.cAddedOn
		      ltEvalAdded  = EVALUATE(m.tcCursor + '.' + This.cAddedOn)
		      
		      IF EMPTY(NVL(m.ltEvalAdded,{//::}))
		         DO CASE 
		            CASE VARTYPE(EVALUATE(m.lcAliasField),.T.) = 'T'
		               REPLACE (This.cAddedOn) WITH m.ltDateTime ;
		                 IN (m.tcCursor)
		      
		            CASE VARTYPE(EVALUATE(m.lcAliasField),.T.) = 'D'
		               REPLACE (This.cAddedOn) WITH TTOD(m.ltDateTime) ;
		                 IN (m.tcCursor)
		                 
		            OTHERWISE
		               *-- Nothing at this time   
		         ENDCASE 
		      ELSE
		         *-- Nothing at this time 
		      ENDIF
		   ELSE
		      *-- Nothing at this time 
		   ENDIF
		ELSE 
		   *-- Nothing at this time 
		ENDIF 

		IF NOT EMPTY(This.cAddedBy)
		   IF FSIZE(ALLTRIM(This.cAddedBy), m.tcCursor) > 0
		      lcAliasField = m.tcCursor + '.' + This.cAddedBy
		      lcEvalAdded = EVALUATE(m.tcCursor + '.' + This.cAddedBy)
		      
		      IF EMPTY(NVL(m.lcEvalAdded,''))
		         IF VARTYPE(EVALUATE(m.lcAliasField),.T.) = 'C'
		            REPLACE (This.cAddedBy) WITH This.cUserID ;
		                 IN (m.tcCursor)
		         ELSE
		            *-- Nothing at this time 
		         ENDIF        
		      ELSE
		         *-- Nothing at this time 
		      ENDIF
		   ELSE
		      *-- Nothing at this time 
		   ENDIF
		ELSE 
		   *-- Nothing at this time 
		ENDIF 

		RETURN
	ENDPROC


	PROCEDURE updateemptyfktonull
		LPARAMETERS tcCursor AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: UpdateEmptyFKtoNull
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Make sure empty foreign key fields are set to NULL otherwise the save will fail with an 
		*//    error about being unable to convert a uniqueidentifier.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - Cursor to updated
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    11/20/2014 - PCM/JLM - Created/Modified 
		*//******************************************************************************************
		LOCAL ARRAY ;
		   laField[1]

		LOCAL ;
		    lcField AS Character ;
		   ,lnFields AS Integer ;
		   ,lnIndex AS Integer ;
		   ,luValue 
		   
		IF This.lSetEmptyFKtoNull
		   lnFields = AFIELDS(laField, m.tcCursor)
		   FOR lnIndex = 1 TO m.lnFields
		       lcField = m.laField[m.lnIndex, 1]

		       IF VARTYPE(m.lcField) = 'C'
		          IF RIGHT(m.lcField, 3) = '_FK' ;
		          AND m.laField[m.lnIndex, 5]  && Does this field allow nulls?
		             luValue = NVL(EVALUATE(m.tcCursor + '.' + m.lcField),'')
		             IF EMPTY(m.luValue)
		                REPLACE (m.lcField) WITH NULL ;
		                    IN (m.tcCursor)
		             ENDIF
		          ENDIF
		       ENDIF
		   ENDFOR
		ENDIF

		RETURN 
	ENDPROC


	PROCEDURE updateupdatedonfields
		LPARAMETERS tcCursor AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: UpdateUpdatedOnFields
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Updates the Updated On Fields if they exist. 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - Cursor we are working with
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    11/20/2014 - JLM - Created 
		*//****************************************************************************************** 
		LOCAL ;
		    ltDateTime AS DateTime ;
		   ,lcALiasField AS Character

		IF EMPTY(This.GetServerTime())
		   ltDateTime = DATETIME()
		ELSE
		   ltDateTime = This.tServerTime 
		ENDIF 
		   
		IF NOT EMPTY(This.cUpdatedOn)
		   IF FSIZE(ALLTRIM(This.cUpdatedOn), m.tcCursor) > 0
		      lcAliasField = m.tcCursor + '.' + This.cUpdatedOn
		      
		      DO CASE 
		         CASE VARTYPE(EVALUATE(m.lcAliasField),.T.) = 'T'
		            REPLACE (This.cUpdatedOn) WITH m.ltDateTime ;
		                 IN (m.tcCursor)         

		         CASE VARTYPE(EVALUATE(m.lcAliasField),.T.) = 'D'
		            REPLACE (This.cUpdatedOn) WITH TTOD(m.ltDateTime) ;
		                 IN (m.tcCursor)
		                 
		         OTHERWISE 
		            *-- Nothing at this time 
		      ENDCASE 
		   ELSE
		      *-- Nothing at this time 
		   ENDIF
		ELSE 
		   *-- Nothing at this time 
		ENDIF 

		IF NOT EMPTY(This.cUpdatedBy)
		   IF FSIZE(ALLTRIM(This.cUpdatedBy), m.tcCursor) > 0
		      lcAliasField = m.tcCursor + '.' + This.cUpdatedBy

		      IF VARTYPE(EVALUATE(m.lcAliasField),.T.) = 'C'
		         REPLACE (This.cUpdatedBy) WITH This.cUserID ;
		              IN (m.tcCursor)
		      ELSE
		         *-- Nothing at this time 
		      ENDIF         
		   ELSE
		      *-- Nothing at this time 
		   ENDIF
		ELSE 
		   *-- Nothing at this time 
		ENDIF 

		RETURN      
	ENDPROC


	PROCEDURE updateemptydatestonull
		LPARAMETERS tcCursor AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: UpdateEmptyDatestoNull
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Make sure empty date fields are set to NULL otherwise the save will fail.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - Cursor to updated
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    11/20/2014 - PCM/JLM - Created/Modified 
		*//******************************************************************************************
		LOCAL ARRAY ;
		   laField[1]

		LOCAL ;
		    lcField AS Character ;
		   ,lnIndex AS Integer ;
		   ,lnFields AS Integer ;
		   ,luValue 

		IF This.lSetEmptyDatesToNull 
		   m.lnFields = AFIELDS(laField, m.tcCursor)
		   FOR m.lnIndex = 1 TO m.lnFields
		       m.lcField = laField[m.lnIndex, 1]   
		       IF VARTYPE(m.lcField) = 'C' ;
		       AND INLIST(laField[m.lnIndex, 2], 'D', 'T') ;
		       AND laField[m.lnIndex, 5]   && Are nulls are allowed?
		          
		         m.luValue = NVL(EVALUATE(m.tcCursor + '.' + m.lcField),{})
		         IF EMPTY(m.luValue)
		            REPLACE (m.lcField) WITH NULL ;
		                 IN (m.tcCursor)
		         ENDIF
		       ENDIF
		   ENDFOR
		ENDIF 

		RETURN 
	ENDPROC


	PROCEDURE csearchcursor_access
		*//******************************************************************************************
		*//  FUNCTION NAME: cSearchCursor_Access
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     If the cSearchCursor values is empty... create it's value.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       Returns the cCursorSearch value
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    11/26/2014 - JLM - Created 
		*//****************************************************************************************** 
		DO CASE 
		   CASE EMPTY(NVL(This.cSearchCursor,''))
		      This.cSearchCursor = 'cur' + ALLTRIM(This.cTable)
		   
		   OTHERWISE 
		      This.cSearchCursor = ALLTRIM(This.cSearchCursor)
		ENDCASE 

		RETURN This.cSearchCursor
	ENDPROC


	PROCEDURE csearchcursor_assign
		LPARAMETERS tcSearchCursor  AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: cSearchCursor_Assign
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//       Changed the value of the cSearchCursor
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcSearchCursor  
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    11/26/2014 - JLM - Created 
		*//****************************************************************************************** 
		DO CASE 
		   CASE EMPTY(NVL(m.tcSearchCursor,SPACE(0)))
		      This.cSearchCursor = 'cur' + ALLTRIM(This.cTable)
		   
		   OTHERWISE 
		      This.cSearchCursor = ALLTRIM(m.tcSearchCursor)
		ENDCASE 

		RETURN       
		      
		      
	ENDPROC


	*-- Are there references to the PK in other tables?
	PROCEDURE candelete
		LPARAMETERS t_PK 
		*//******************************************************************************************
		*//  FUNCTION NAME: CanDelete 
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/03/2018
		*//
		*//  COPYRIGHT © 2010-2018   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Checks to see if there are references found in the database. 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       t_PK - Primary Key   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - No records found supporting tables - Deletion can occur
		*//       .F. - Records found - NO Deletion!!!!
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     12/03/2018 - JLM - Created 
		*//******************************************************************************************  
		*-- Example code ----------------------------------------------------------------------------

		*!* LOCAL ;
		*!*     loSelect AS cSelect OF WlcBizObj ;
		*!*    ,lnReccount AS Integer ;
		*!*    ,lnTotalReccount AS Integer ;
		*!*    ,llCanDelete AS Boolean ;
		*!*    ,lcErrorMessage AS Character ;
		*!*    ,loStateBizObj AS Object 

		*!* loSelect = CreateFactory('cSelect')
		*!* 
		*!* This.ClearValidationErrors()

		*-- Create referenced table objects
		*-- loStateBizObj = CreateFactory('StateBizObj')
		*-- loStateBizObj.GetCursorByKey('curStateAddressRef','Address',m.t_PK,'State_FK')
		 
		*!*   llCanDelete     = .F.
		*!*   lnTotalReccount = 0

		*!*   IF USED('curStateAddressRef')
		*!*      nReccount = RECCOUNT('curStateAddressRef')
		*!*      lnTotalReccount = m.lnTotalReccount + m.lnReccount
		*!*   ELSE 
		*!*      lnReccount = -1
		*!*   ENDIF    

		*!*   USE IN SELECT('curCountry')

		*!*   DO CASE 
		*!*      CASE m.lnReccount > 0
		*!*         lcErrorMessage = 'State references found.'
		*!*      
		*!*         This.AddValidationError(m.lcErrorMessage,'State')
		*!*         
		*!*      CASE m.lnReccount < 0
		*!*         lcErrorMessage = 'State references Not Determined'
		*!*         lnReccount     = 1
		*!*         This.AddValidationError(m.lcErrorMessage,'State')   
		*!*         
		*!*      OTHERWISE 
		*!*         *-- Nothing at this time 
		*!*   ENDCASE 

		*!*   m.llCanDelete = m.lnTotalReccount = 0

		*!*   STORE .NULL. TO ;
		*!*       loSelect ;
		*!*      ,loStateBizObj
		*!*      
		*!*   RETURN m.llCanDelete
		      
	ENDPROC


	PROCEDURE getallrecordsnotexcluded
		*//******************************************************************************************
		*//  FUNCTION NAME: BaseBizOjb::GetAllRecordsNotExcluded
		*//
		*//  AUTHOR: White Light Computing, Inc. 07/08/2019
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    This is used primarily when creating a combobox list.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     07/08/2019 - JLM - Created 
		*//******************************************************************************************  
	ENDPROC


	PROCEDURE cmaintenancecursor_access
		*//******************************************************************************************
		*//  FUNCTION NAME: cMaintenanceCursor_Access
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/28/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     If the property cMaintenanceCursor values is empty... create it's value.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None
		*//
		*//    OUTPUT PARAMETERS: 
		*//       Returns the cMaintenanceCursor value
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    02/28/2020 - JLM - Created 
		*//****************************************************************************************** 
		DO CASE 
		   CASE EMPTY(NVL(This.cMaintenanceCursor,SPACE(0)))
		      This.cMaintenanceCursor = 'mur' + ALLTRIM(This.cTable)
		   
		   OTHERWISE 
		      This.cMaintenanceCursor = ALLTRIM(This.cMaintenanceCursor)
		ENDCASE 

		RETURN This.cMaintenanceCursor
	ENDPROC


	PROCEDURE cmaintenancecursor_assign
		LPARAMETERS tcMaintenanceCursor AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: MaintenanceCursor_Assign
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/28/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//       Changed the value of the property cMaintenanceCursor 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcMaintenanceCursor 
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    11/26/2014 - JLM - Created 
		*//****************************************************************************************** 
		DO CASE 
		   CASE EMPTY(NVL(m.tcMaintenanceCursor,SPACE(0)))
		      This.cMaintenanceCursor = 'mur' + ALLTRIM(This.cTable)
		   
		   OTHERWISE 
		      This.cMaintenanceCursor = ALLTRIM(m.tcMaintenanceCursor)
		ENDCASE 

		RETURN       
		      
		      
	ENDPROC


	PROCEDURE csqlschema_access
		*//******************************************************************************************
		*//  FUNCTION NAME: cSQLSchema_Access
		*//
		*//  AUTHOR: White Light Computing, Inc. 02/28/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    The default Schema is SQL Server is [dbo]
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       Returns the This.cSQLSchema value
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/28/2020 - JLM - Created 
		*//******************************************************************************************  
		DO CASE 
		   CASE EMPTY(NVL(This.cSQLSchema,SPACE(0)))
		      This.cSQLSchema = 'dbo'
		   
		   OTHERWISE 
		      This.cSQLSchema = ALLTRIM(This.cSQLSchema)
		ENDCASE 

		RETURN This.cSQLSchema
	ENDPROC


	PROCEDURE getsqlbaseselect
		LPARAMETERS tcTable AS Character, tcSchema AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: GetSQLBaseSelect
		*//
		*//  AUTHOR: White Light Computing, Inc. 07/15/2020
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    This is the base SQL statement. It just helps to reduce writing code. 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcTable - Overrides This.cTable value
		*//       tcSchema - Overrides This.cSQLSchema value
		*//
		*//    OUTPUT PARAMETERS: 
		*//       lcSQL    
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     07/15/2020 - JLM - Created 
		*//******************************************************************************************  
		LOCAL ;
		   lcSQL AS Character ;
		   ,lcSchema AS Character ; 
		   ,lcTable AS Character 

		lcSQL    = SPACE(0)

		IF EMPTY(NVL(m.tcTable,SPACE(0))) ;
		OR VARTYPE(m.tcTable) <> 'C'
		   lcTable  = ALLTRIM(This.cTable)
		ELSE
		   lcTable = ALLTRIM(m.tcTable)
		ENDIF 

		IF EMPTY(NVL(m.tcSchema,SPACE(0))) ;
		OR VARTYPE(m.tcSchema) <> 'C'
		   lcSchema = ALLTRIM(This.cSQLSchema)
		ELSE
		   lcSchema = ALLTRIM(m.tcSchema)
		ENDIF 
		   
		TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		   SELECT *
		   FROM [<<m.lcSchema>>].[<<m.lcTable>>].*
		ENDTEXT 

		RETURN m.lcSQL
	ENDPROC


	PROCEDURE Destroy
		*//******************************************************************************************
		*//  FUNCTION NAME: Destroy
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Clean up.
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
		STORE .NULL. TO ;
		    This.oSQL ;
		   ,This.oValidationErrors ;
		   ,This.oRules
		   
		RETURN DODEFAULT()
		   
	ENDPROC


	PROCEDURE Init
		*//******************************************************************************************
		*//  FUNCTION NAME: Init
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Handle any basic set-up
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
		*//    03/02/2020 - JLM - Added lVFPTable from Global Variable: 
		*//****************************************************************************************** 
		LOCAL ;
		    loSQL AS Object ;
		   ,lnSQLHandle AS Integer
		   
		This.cUserId = GetUserID()

		lnSQLHandle = .NULL.
		* If this is being instantiated within a form, see if the
		* form knows of a connection handle that can be shared
		* Note that the cForm class has an access method that will
		* retrieve this from an application object if possible
		IF TYPE([THISFORM]) = "O"
		   IF TYPE([THISFORM.nSQLHandle]) = "N"
		      lnSQLHandle = THISFORM.nSQLHandle
		   ENDIF
		ELSE
		   * If this isn't being instantiated within a form,
		   * look to an application object to see if it has
		   * a connection handle for us
		   * SAS 10/14/2005
		   IF TYPE([goApp]) = [O] AND TYPE([goApp.nSQLHandle]) = [N]
		      THIS.nSQLHandle = goApp.nSQLHandle
		   ENDIF
		ENDIF

		IF THIS.lAutoConnectSQL
		   * Added this CASE structure
		   * to accomodate the situation where we
		   * are passing a connection handle to
		   * the SQL object
		   DO CASE
		      CASE NOT ISNULL(lnSQLHandle)
		         THIS.oSQL = CreateFactory(This.cSQLClass, lnSQLHandle)
		      CASE !EMPTY(THIS.cConnectionString)
		         THIS.oSQL = CreateFactory(This.cSQLClass, THIS.cConnectionString)
		      OTHERWISE
		         THIS.oSQL = CreateFactory(This.cSQLClass)
		   ENDCASE
		ELSE
		   THIS.oSQL = CreateFactory(This.cSQLClass, "")
		ENDIF

		* If this is being instantiated within a form, and the
		* form has no shared connection handle stored, pass this
		* handle back to the form
		IF TYPE([THISFORM]) = [O]
		   IF TYPE([THISFORM.nSQLHandle]) = "N"
		      IF ISNULL(THISFORM.nSQLHandle)
		         THISFORM.nSQLHandle = THIS.oSQL.nSQLHandle
		      ENDIF
		   ENDIF
		ENDIF

		*-- add code to update osql's skip list
		THIS.oSQL.cUpdateKeyField = THIS.cUpdateKeyField
		IF NOT EMPTY(THIS.cSkipFieldsForUpdates)
		   THIS.oSQL.cSkipFieldsForUpdates = THIS.oSQL.cSkipFieldsForUpdates+[,]+THIS.cSkipFieldsForUpdates
		ENDIF

		IF THIS.lRaiseError
		   BINDEVENT(THIS.oSQL,[execute],THIS,[CheckForError],1)
		ENDIF

		*-- Begin Add by JLM of WLC 03/02/2020
		IF PEMSTATUS(This.oSQL,'lVFPTable',5)
		   This.oSQL.lVFPTable = NOT m.glSQLServer && Set in the Startup program
		ENDIF 
		*-- End Add by JLM of WLC 03/02/2020

		RETURN 
	ENDPROC


ENDDEFINE
*
*-- EndDefine: basebizobj
**************************************************


**************************************************
*-- Class:        basevfpbizobj (c:\develop\codeminenew\dmie_rv\custom\wlcbizobj.vcx)
*-- ParentClass:  basebizobj (c:\develop\codeminenew\dmie_rv\custom\wlcbizobj.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   04/20/21 01:47:11 PM
*
DEFINE CLASS basevfpbizobj AS basebizobj


	*-- Teh data folder where the data is located if it's not in the path.
	cdatafolder = ""
	_memberdata = [<VFPData><memberdata name="cdatafolder" display="cDataFolder"/><memberdata name="getfilteredrecords" display="GetFilteredRecords"/><memberdata name="pack" display="Pack"/><memberdata name="zap" display="ZAP"/></VFPData>]
	csqlclass = "wlcVFP"
	Name = "basevfpbizobj"


	PROCEDURE getfilteredrecords
		LPARAMETERS ;
		    tcCursor AS Character ;
		   ,tcFilter AS Character ;
		   ,tcSortBy AS Character ;
		*//******************************************************************************************
		*//  FUNCTION NAME: GetCursorByKey 
		*//
		*//  AUTHOR: White Light Computing, Inc. 09/17/2013
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Return a cursor for the specified table, filtered by tcFilter
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - Resulting cursor name
		*//       tcFilter - Filter
		*//       tcSortBy - Sort By
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Failed. Check oSQL.cErrors for more info.
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     09/17/2013 - JLM - Created 
		*//******************************************************************************************  
		LOCAL ;
		   lcSQL AS Character ;
		   ,lcDF AS Character
		   
		IF EMPTY(This.cDataFolder) ;
		OR VARTYPE(This.cDataFolder) <> 'C'
		   m.lcDF = ''
		ELSE
		   m.lcDF = ADDBS(ALLTRIM(This.cDataFolder))
		ENDIF 

		DO CASE
		   CASE VARTYPE(m.tcFilter) = 'C' ;
		   AND EMPTY(NVL(m.tcFilter,''))
		      m.tcFilter = ''
		   
		   OTHERWISE 
		      m.tcFilter = 'WHERE ' + m.tcFilter
		ENDCASE  

		DO CASE
		   CASE VARTYPE(m.tcCursor) <> 'C' ;
		   OR EMPTY(NVL(m.tcCursor,SPACE(0))) 
		      m.tcCursor = This.cMaintenanceCursor
		   
		   CASE ALLTRIM(UPPER(m.tcCursor)) == ALLTRIM(UPPER(This.cTable)) 
		      m.tcCursor = This.cMaintenanceCursor

		   OTHERWISE 
		      m.tcCursor = ALLTRIM(m.tcCursor)
		ENDCASE   

		IF This.oSQL.lVfpTable
		   This.cTable_Fox_Alias = m.tcCursor

		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		      SELECT 
		         *
		      FROM 
		         <<m.lcDF+This.cTable>>  AS tBizObjSQLQuery
		      INTO CURSOR <<m.tcCursor>> READWRITE 
		         <<m.tcFilter>>
		   ENDTEXT

		   IF VARTYPE(m.tcSortBy) = "C" AND !EMPTY(m.tcSortBy)
		      TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		         ORDER BY <<m.tcSortBy>>
		      ENDTEXT
		   ENDIF
		ELSE
		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		      SELECT
		         [<<This.cTable>>].*
		      FROM
		         [<<This.cTable>>]
		         <<m.tcFilter>>
		   ENDTEXT

		   IF VARTYPE(m.tcSortBy) = "C" AND !EMPTY(m.tcSortBy)
		      TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2
		         ORDER BY
		            <<m.tcSortBy>>
		      ENDTEXT
		   ENDIF
		ENDIF    

		RETURN (This.oSQL.Execute(lcSQL, tcCursor) >= 0)
	ENDPROC


	PROCEDURE pack
		*//******************************************************************************************
		*//  FUNCTION NAME: Pack
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/05/2014
		*//
		*//  COPYRIGHT © 2010-2014   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Tries to get exclusive use and PACK the vfp table.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. or .F.    
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     12/05/2014 - JLM - Created 
		*//******************************************************************************************  
		LOCAL ;
		    lcSQL AS Character ;
		   ,lcTable AS Character ;
		   ,llReturn AS Boolean ;
		   ,lcDF AS Character

		m.llReturn = .T.

		IF EMPTY(This.cDataFolder) ;
		OR VARTYPE(This.cDataFolder) <> 'C'
		   m.lcDF = ''
		ELSE
		   m.lcDF = ADDBS(ALLTRIM(This.cDataFolder))
		ENDIF

		m.lcTable = m.lcDF + ALLTRIM(This.cTable)

		IF FILE(FORCEEXT(m.lcTable,'dbf'))
		   TRY
		      USE (m.lcTable) ALIAS PackAlias IN 0 EXCLUSIVE
		      PACK IN PackAlias 
		      USE IN (SELECT('PackAlias'))
		   CATCH
		      m.llReturn = .F.
		   ENDTRY
		ELSE
		   m.llReturn = .T.
		ENDIF

		RETURN m.llReturn
	ENDPROC


	PROCEDURE zap
		*//******************************************************************************************
		*//  FUNCTION NAME: Zap 
		*//
		*//  AUTHOR: White Light Computing, Inc. 06/25/2013 
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Zaps the Vfp table. 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None   
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Failed
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     06/25/2013  - JLM - Created 
		*//******************************************************************************************  
		LOCAL ;
		    lcSQL AS Character ;
		   ,lcTable AS Character ;
		   ,llReturn AS Boolean ;
		   ,lcDF AS Character
		 
		m.llReturn = .T.
		   
		IF EMPTY(This.cDataFolder) ;
		OR VARTYPE(This.cDataFolder) <> 'C'
		   m.lcDF = ''
		ELSE
		   m.lcDF = ADDBS(ALLTRIM(This.cDataFolder))
		ENDIF  

		m.lcTable = m.lcDF + ALLTRIM(This.cTable)

		IF FILE(FORCEEXT(m.lcTable,'dbf'))
		   TRY 
		      USE (m.lcTable) ALIAS ZapAlias IN 0 EXCLUSIVE
		      ZAP IN ZapAlias 
		      USE IN (SELECT('ZapAlias'))
		   CATCH
		      m.llReturn = .F.
		   ENDTRY   
		ELSE
		   m.llReturn = .F.
		ENDIF  

		RETURN m.llReturn  
	ENDPROC


	PROCEDURE search
		LPARAMETERS t_parameter 
		*//******************************************************************************************
		*//  FUNCTION NAME: Search
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Called when the user selects the Search command button on a form.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       t_parameter - Could just be a NULL
		*//
		*//    OUTPUT PARAMETERS: 
		*//       cursor   
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     12/30/2014 - JLM - Created
		*//******************************************************************************************  
		LOCAL ;
		    lcSQL AS Character ;
		   ,lcDF AS Character ;
		   ,loParameter ;
		   ,loSelect

		loSelect = CreateFactory('cSelect')

		*!* Uncomment when parameters are passed --> loParameter = This.oSQL.GetParameterObject()
		IF NOT This.oSQL.lVFPTable
		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		      SELECT
		         [<<This.cTable>>].*
		      FROM
		         [<<This.cSQLSchema>>].[<<This.cTable>>]
		   ENDTEXT
		ELSE
		   IF EMPTY(This.cDataFolder) ;
		   OR VARTYPE(This.cDataFolder) <> 'C'
		      lcDF = ''
		   ELSE
		      lcDF = ADDBS(ALLTRIM(This.cDataFolder))
		   ENDIF 

		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		      SELECT
		         <<This.cTable>>.* 
		      FROM
		         <<m.lcDF+This.cTable>>
		      INTO CURSOR <<This.cSearchCursor>> NOFILTER 
		      WHERE
		         1 = 1
		   ENDTEXT
		ENDIF 

		IF NOT EMPTY(This.cDefaultSort)
		   TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		      ORDER BY
		         <<This.cDefaultSort>>
		   ENDTEXT
		ENDIF

		This.oSQL.Execute(m.lcSQL, This.cSearchCursor, loParameter)

		STORE .NULL. TO loSelect, loParameter

		RETURN 
	ENDPROC


	PROCEDURE isunique
		LPARAMETERS ;
		    tuCurrentPK ;
		   ,tcField AS Character ;
		   ,tuValue
		*//******************************************************************************************
		*//  FUNCTION NAME: IsUnique
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//    Checks to see if the passed in field/value is unique
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tuCurrentPK - The primary key value of the current record
		*//       tcField - The field to check
		*//       tuValue - The value of the field to check
		*//
		*//    OUTPUT PARAMETERS: 
		*//       lnUnique = 0  - It's uniue
		*//       lnUnique > 0  - It's NOT unique
		*//       lnUnique = -1 - Bad PK passed?
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/28/2020 - JLM - Created 
		*//******************************************************************************************    
		IF NOT This.oSQL.lVFPTable
		   RETURN DODEFAULT(m.tuCurrentPK,m.tcField,m.tuValue)
		ELSE
		   LOCAL ;
		       llUnique AS Boolean ;
		      ,lcSQL AS Character ;
		      ,lcDF AS Character ;
		      ,loSelect AS cSelect OF WlcBizObj ;
		      ,loParamaeter AS Object 

		   loSelect    = CreateFactory('CSelect')
		   loParameter = This.oSQL.GetParameterObject()

		   loParameter.Add('PK', m.tuCurrentPK)
		   loParameter.Add('FieldValue', m.tuValue)

		   llUnique = .F.
		   
		   IF EMPTY(This.cDataFolder) ;
		   OR VARTYPE(This.cDataFolder) <> 'C'
		      lcDF = ''
		   ELSE
		      lcDF = ADDBS(ALLTRIM(This.cDataFolder))
		   ENDIF    

		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		      SELECT
		         <<This.cTable>>.<<m.tcField>>
		      FROM
		         <<m.lcDF+This.cTable>> NOFILTER 
		      INTO CURSOR curUnique
		      WHERE <<This.cTable>>.<<m.tcField>> = ?FieldValue
		        AND <<This.cTable>>.<<This.cUpdateKeyField>> <> ?PK
		   ENDTEXT

		   This.oSQL.Execute(lcSQL, 'curUnique', loParameter)

		   IF USED('curUnique')
		      lnUnique = RECCOUNT('curUnique')
		   ELSE
		      lnUnique = -1
		   ENDIF 

		   USE IN SELECT('curUnique')

		   RETURN lnUnique
		ENDIF   
	ENDPROC


	PROCEDURE Init
		*//******************************************************************************************
		*//  FUNCTION NAME: Init
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
		LOCAL ;
		   llReturn AS Boolean

		llReturn = DODEFAULT() 

		IF m.llReturn 
		   This.oSQL.lReplaceEmptydateWithNull = .T.
		ENDIF

		RETURN m.llReturn 
	ENDPROC


	PROCEDURE getservertime
		*//******************************************************************************************
		*//  FUNCTION NAME: GetServerTime
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Retrieve the date/time from the server if This.lOverrideServerTime and This.tServerTime
		*//     isn't empty. 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       None
		*//
		*//    OUTPUT PARAMETERS: 
		*//       Validate Date Time (Can be empty)
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//    02/28/2020 - JLM - Created
		*//****************************************************************************************** 
		IF NOT This.oSQL.lVFPTable
		   RETURN DODEFAULT()
		ELSE
		   IF This.lOverrideServerTime ;
		   AND NOT EMPTY(NVL(This.tServerTime,{//::}))
		      RETURN This.tServerTime
		   ENDIF

		   This.tServerTime = DATETIME()


		   RETURN This.tServerTime
		ENDIF    
	ENDPROC


	PROCEDURE getemptycursor
		LPARAMETERS tcCursor AS Character, tcTable AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: GetEmptyCursor
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Gets an empty buffered cursor
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//     tcCursor (Optional) - Cursor name to create. If empty, it uses This.cTable
		*//     tcTable (optional) - Table to retrieve from. If empty, it uses This.cMaintenanceCursor.
		*//                          
		*//
		*//    OUTPUT PARAMETERS: 
		*//       None
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/28/2020 - JLM - Created
		*//******************************************************************************************  
		IF NOT This.oSQL.lVFPTable
		   RETURN DODEFAULT(m.tcCursor,m.tcTable)
		ELSE
		   LOCAL ;
		       lcTable AS Character ;
		      ,lcCursor AS Character ;
		      ,lcSQL AS Character ;
		      ,lcDF AS Character

		   IF VARTYPE(m.tcTable) = 'C' ;
		   AND NOT EMPTY(NVL(m.tcTable,SPACE(0)))
		      lcTable = ALLTRIM(m.tcTable)
		   ELSE
		      lcTable = JUSTSTEM(JUSTFNAME(ALLTRIM(This.cTable)))
		   ENDIF

		   IF EMPTY(This.cDataFolder) ;
		   OR VARTYPE(This.cDataFolder) <> 'C'
		      lcDF = ''
		   ELSE
		      lcDF = ADDBS(ALLTRIM(This.cDataFolder))
		   ENDIF 
		   
		   DO CASE
		      CASE VARTYPE(m.tcCursor) <> 'C' ;
		      OR EMPTY(NVL(m.tcCursor,SPACE(0))) 
		         m.lcCursor = This.cMaintenanceCursor
		      
		      CASE ALLTRIM(UPPER(m.tcCursor)) == ALLTRIM(UPPER(This.cTable)) 
		         m.lcCursor = This.cMaintenanceCursor

		      OTHERWISE 
		         m.lcCursor = ALLTRIM(m.tcCursor)
		   ENDCASE   

		   TEXT TO lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		      SELECT
		         <<m.lcTable>>.*
		      FROM
		         <<m.lcDF+m.lcTable>>
		      INTO CURSOR '<<m.lcCursor>>' READWRITE 
		      WHERE
		         1 = 0
		   ENDTEXT

		   USE IN SELECT(m.lcCursor)

		   This.oSQL.Execute(m.lcSQL, m.lcCursor)
		ENDIF
	ENDPROC


	PROCEDURE getcursorbykey
		LPARAMETERS ;
		    tcCursor AS Character ;
		   ,tcSourceTable AS Character ;
		   ,tuKey ;
		   ,tcKeyField AS Character ;
		   ,tcSortBy AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: GetCursorByKey
		*//
		*//  AUTHOR: White Light Computing, Inc. 12/30/2014
		*//
		*//  COPYRIGHT © 2010-2020   All Rights Reserved.
		*//  White Light Computing, Inc.
		*//  PO Box 391
		*//  Washington Twp., MI  48094
		*//  raschummer@whitelightcomputing.com
		*//
		*//  PROCEDURE DESCRIPTION: 
		*//     Return a cursor for the specified table, filtered by the key.
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor - Resulting cursor name
		*//       tcSourceTable - Source Table
		*//       tuKey - Key to search for
		*//       tcKeyField - (Optional) - Key fieldname. If not specified,
		*//                   assumed to be the key field.
		*//       tcSortBy - (Optional) - column(s) to sort by
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Failed. Check oSQL.cErrors for more info.
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     10/28/2014 - PCM - Created 
		*//     02/28/2020 - JLM - Added [<<This.cSQLSchema>>]. 
		*//****************************************************************************************** 
		IF NOT This.oSQL.lVFPTable
		   RETURN DODEFAULT(m.tcCursor,m.tcSourceTable,m.tuKey,m.tcKeyField,m.tcSortBy)
		ELSE
		   LOCAL ;
		       lcSQL AS Character ;
		      ,lcDF AS Character ;
		      ,loParameter AS Object ;
		      ,lcKeyField AS Character 

		   loParameter = This.oSQL.GetParameterObject()
		   loParameter.Add('Key', tuKey)

		   lcKeyField = This.cUpdateKeyField

		   IF VARTYPE(m.tcKeyField) = 'C'
		      lcKeyField = tcKeyField
		   ENDIF

		   IF EMPTY(This.cDataFolder) ;
		   OR VARTYPE(This.cDataFolder) <> 'C'
		      lcDF = ''
		   ELSE
		      lcDF = ADDBS(ALLTRIM(This.cDataFolder))
		   ENDIF 
		   
		   DO CASE
		      CASE VARTYPE(m.tcCursor) <> 'C' ;
		      OR EMPTY(NVL(m.tcCursor,SPACE(0))) 
		         m.tcCursor = This.cMaintenanceCursor
		      
		      CASE ALLTRIM(UPPER(m.tcCursor)) == ALLTRIM(UPPER(This.cTable)) 
		         m.tcCursor = This.cMaintenanceCursor

		      OTHERWISE 
		         m.tcCursor = ALLTRIM(m.tcCursor)
		   ENDCASE     
		   
		   TEXT TO lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		      SELECT
		         <<m.tcSourceTable>>.*
		      FROM
		         <<m.lcDF+m.tcSourceTable>>
		      INTO CURSOR <<m.tcCursor>> READWRITE
		      WHERE
		         <<m.tcSourceTable>>.<<m.lcKeyField>> = ?Key
		   ENDTEXT

		   IF VARTYPE(m.tcSortBy) = 'C' AND NOT EMPTY(m.tcSortBy)
		      TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		         ORDER BY
		            <<m.tcSortBy>>
		      ENDTEXT
		   ENDIF

		   RETURN (This.oSQL.Execute(m.lcSQL, m.tcCursor, m.loParameter) >= 0)
		ENDIF
	ENDPROC


	PROCEDURE find
		LPARAMETERS ;
		    tcCursor AS Character ;
		   ,tcSourceTable AS Character ;
		   ,tuKey AS Character ;
		   ,tcKeyField AS Character ;
		   ,tlForceUpper AS Boolean
		*//******************************************************************************************
		*//  FUNCTION NAME: Find
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
		*//     Similar to GetCursorByKey, but does a wildcard search instead
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//      tcCursor      - Resulting cursor name
		*//      tcSourceTable - Source Table
		*//      tuKey         - Key to search for
		*//      tcKeyField    - Key fieldname.
		*//      tlForceUpper (Optional) - Force the search to uppercase
		*//                                USE ONLY WITH CHARACTER FIELDS!
		*//
		*//    OUTPUT PARAMETERS: 
		*//       Creates the tcCusor 
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     02/29/2020 - JLM - Created 
		*//****************************************************************************************** 
		IF NOT This.oSQL.lVFPTable
		   RETURN DODEFAULT(m.tcCursor,m.tcSourceTable,m.tuKey,m.tcKeyField,m.tlForceUpper)
		ELSE 

		   LOCAL ;
		       lcSQL AS Character ;
		      ,lcDF AS Character ;
		      ,loParameter AS Object ;
		      ,lcKeyField AS Character 

		   loParameter = This.oSQL.GetParameterObject()

		   IF m.tlForceUpper ;
		   AND VARTYPE(m.tuKey) = 'C'
		      loParameter.Add('Key', UPPER(m.tuKey) + "%")
		   ELSE
		      loParameter.Add('Key', tuKey + '%')
		   ENDIF

		   lcKeyField = This.cUpdateKeyField

		   IF VARTYPE(tcKeyField) = 'C'
		      lcKeyField = m.tcKeyField
		   ENDIF

		   IF EMPTY(This.cDataFolder) ;
		   OR VARTYPE(This.cDataFolder) <> 'C'
		      lcDF = ''
		   ELSE
		      lcDF = ADDBS(ALLTRIM(This.cDataFolder))
		   ENDIF 
		   
		   IF m.tlForceUpper
		      TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		         SELECT
		            <<m.tcSourceTable>>.*
		         FROM
		            <<m.lcDF+m.tcSourceTable>>
		         WHERE
		            UPPER(<<m.tcSourceTable>>.<<m.lcKeyField>>) LIKE ?Key
		      ENDTEXT
		   ELSE
		      TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		         SELECT
		            <<m.tcSourceTable>>.*
		         FROM
		            <<m.lcDF+m.tcSourceTable>>
		         WHERE
		            <<m.tcSourceTable>>.<<m.lcKeyField>> LIKE ?Key
		      ENDTEXT
		   ENDIF

		   RETURN (This.oSQL.Execute(m.lcSQL, m.tcCursor, loParameter) >= 0)
		ENDIF 
	ENDPROC


	PROCEDURE zzabout
		******************************************************************************************
		*  METHOD NAME: zzAbout
		*
		*  AUTHOR: White Light Computing, Inc.
		*
		*  FORM/CLASS DESCRIPTION:
		*    BaseVFPBizObj - You would want to use this if you have an application that supports 
		*    VFP tables and/or SQL Server. 
		*
		*    When Using VFP and/or SQL, so your forms and other classes will work, always use a 
		*    generic cursor name, ie. curZipCode (usually used for Search Screen). For maintenance 
		*    screens, this framework works with cursors. Once the user clicks SAVE the VFP table is
		*    updated. For Maintenance screens, MurZipeCode will be the default. Or whatever naming 
		*    convention you use.
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


	PROCEDURE delete
		LPARAMETERS tuPK
		*//******************************************************************************************
		*//  FUNCTION NAME: BaseVFPBizObj
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
		*//    Remove a record from the table 
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tuPK - Primary key of the record to remove
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Unsuccessful
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     06/06/2013 - JLM - Created 
		*//******************************************************************************************  
		LOCAL ;
		    lcSQL AS Character ;
		   ,lcDF AS Character

		IF NOT This.oSQL.lVFPTable
		   RETURN DODEFAULT(m.tuPK)
		ELSE
			IF EMPTY(This.cDataFolder) ;
			OR VARTYPE(This.cDataFolder) <> 'C'
			   lcDF = ''
			ELSE
			   lcDF = ADDBS(ALLTRIM(This.cDataFolder))
			ENDIF 

		   *-- Begin Remove by JLM of WLC 03/02/2020
		   *-- This was erroring when using the parameter. Not sure why. For now, will just use textmerge
		   *!* loParameter = This.oSQL.GetParameterObject()   
		   *!* loParameter.Add("PK", tuPK)
		   *-- End Remove by JLM of WLC 03/02/2020


		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
		      DELETE 
		        FROM
		           <<m.lcDF+This.cTable>>
		       WHERE
		          <<This.cTable>>.<<This.cUpdateKeyField>> = '<<m.tuPK>>'
		   ENDTEXT
		   *-- Begin Modify by JLM of WLC 03/02/2020
			*!* RETURN This.oSQL.Execute(m.lcSQL, "curResult", loParameter) > 0
		   RETURN This.oSQL.Execute(m.lcSQL, "curResult") > 0
		   *-- End Modify  by JLM of WLC 03/02/2020
		ENDIF
	ENDPROC


	PROCEDURE getallrecords
		LPARAMETERS tcCursor AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: BaseVFPBizObj::GetAllRecords
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
		*//     Retrieve all the records in a table (not advised for large tables!)
		*// 
		*//  PARAMETERS: 
		*//    INPUT PARAMETERS: 
		*//       tcCursor (Optional) - Cursor name to put records into.
		*//
		*//    OUTPUT PARAMETERS: 
		*//       .T. - Successful
		*//       .F. - Failed
		*//******************************************************************************************
		*//  MODIFICATIONS:
		*//     05/29/2013 - JLM - Created 
		*//******************************************************************************************  
		LOCAL ;
		    lcSQL AS Character ;
		   ,llReturn AS Boolean ;
		   ,lcDF AS Character

		IF NOT This.oSQL.lVFPTable
		   RETURN DODEFAULT(m.tcCursor)
		ELSE
			IF EMPTY(This.cDataFolder) ;
			OR VARTYPE(This.cDataFolder) <> 'C'
			   m.lcDF = ''
			ELSE
			   m.lcDF = ADDBS(ALLTRIM(This.cDataFolder))
			ENDIF    

		   DO CASE
		      CASE VARTYPE(m.tcCursor) <> 'C' ;
		      OR EMPTY(NVL(m.tcCursor,SPACE(0))) 
		         m.tcCursor = This.cMaintenanceCursor
		      
		      CASE ALLTRIM(UPPER(m.tcCursor)) == ALLTRIM(UPPER(This.cTable)) 
		         m.tcCursor = This.cMaintenanceCursor

		      OTHERWISE 
		         m.tcCursor = ALLTRIM(m.tcCursor)
		   ENDCASE   

			This.cTable_Fox_Alias = ALLTRIM(m.tcCursor)

			TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
			   SELECT
			      * 
			   FROM
			      '<<m.lcDF+This.cTable>>'
			   INTO CURSOR <<m.tcCursor>> READWRITE 
			ENDTEXT

			IF NOT EMPTY(This.cDefaultSort)
			   TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
			      ORDER BY
			         <<This.cDefaultSort>>
			   ENDTEXT
			ENDIF

			m.llReturn = This.oSQL.Execute(m.lcSQL, m.tcCursor)

			USE IN SELECT(This.cTable)

		   RETURN m.llReturn
		ENDIF 
	ENDPROC


ENDDEFINE
*
*-- EndDefine: basevfpbizobj
**************************************************


**************************************************
*-- Class:        cselect (c:\develop\codeminenew\dmie_rv\custom\wlcbizobj.vcx)
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   04/29/14 11:24:06 AM
*
DEFINE CLASS cselect AS custom


	*-- XML Metadata for customizable properties
	_memberdata = [<VFPData><memberdata name="zzabout" display="zzAbout"/></VFPData>]
	Name = "cselect"
	noldarea = .F.
	noldsession = .F.


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


	PROCEDURE Init
		*---------------------- Location Section ------------------------
		*   Library: CUtils.vcx
		*   Class:   CSelect
		*   Method:  Init()
		*----------------------- Usage Section --------------------------
		*)  Description:
		*)		Verify that the specified alias to be selected is USED.
		*)		Save the current work area number, then select the
		*)		specified alias.
		*)		When this object is destroyed, the original work area
		*)		is reselected.

		*   Scope:      Public
		*   Parameters:
		*		1. tcAlias - Alias to be selected
		*		2. tnDataSession - (Optional) Data session in which
		*			the alias resides.
		*$  Usage:
		*$
		*   Returns:  Logical .T. if the work area was selected,
		*				otherwise .F.
		*--------------------- Maintenance Section ----------------------
		*   Change Log:
		*       CREATED 
		*		MODIFIED	05/04/99 - KJM
		*			Removed the call to MsgSvc if the alias is not USED.
		*			This allows CSelect to be used in COM Servers.
		*		MODIFIED	07/26/99 - KJM
		*			Added a second parameter called tnDataSession. If
		*			specified, issues  SET DATASESSION on this value.
		******************************************************************
		LPARAMETERS tcAlias, tnDataSession

		IF !EMPTY(tcAlias) AND !USED(tcAlias)
			RETURN .F.
		ENDIF

		this.nOldArea = SELECT()

		IF NOT EMPTY(tnDataSession) AND ;
		  SET('DATASESSION') != tnDataSession
			This.nOldSession = SET('DATASESSION')
			SET DATASESSION TO tnDataSession
		ENDIF

		IF !EMPTY(tcAlias)
			SELECT (tcAlias)
		ENDIF
	ENDPROC


	PROCEDURE Destroy
		*---------------------- Location Section ------------------------
		*   Library: CUtils.vcx
		*   Class:   CSelect
		*   Method:  Destroy()
		*----------------------- Usage Section --------------------------
		*)  Description:
		*)		Reselects the original work area

		*   Scope:      Public
		*   Parameters: None
		*$  Usage:      Automatically executed when the object is
		*				destroyed.
		*$
		*   Returns:  Logical .T. by default
		*--------------------- Maintenance Section ----------------------
		*   Change Log:
		*       CREATED 
		*		MODIFIED	07/26/99 - KJM
		*			Changed this method to select a previous data
		*			session (if specified)
		******************************************************************
		IF NOT EMPTY(This.nOldSession) AND ;
		  SET('DATASESSION') != This.nOldSession
			SET DATASESSION TO This.nOldSession
		ENDIF
		SELECT (this.nOldArea)
	ENDPROC


ENDDEFINE
*
*-- EndDefine: cselect
**************************************************

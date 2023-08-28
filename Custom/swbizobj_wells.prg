**************************************************
*-- Class:        wellsvfpbizobj (c:\develop\3rdparty\wlc_bizobj\libs\shwbizobj.vcx)
*-- ParentClass:  basevfpbizobj (c:\develop\3rdparty\wlc_bizobj\libs\wlcbizobj.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   08/21/20 05:51:11 PM
*
DEFINE CLASS wellsvfpbizobj AS basevfpbizobj


	ctable = "wells"
	cupdatekeyfield = ('cwellid')
	caddedby = "cAddUser"
	caddedon = "dAdded"
	cupdatedby = "cChgUser"
	cupdatedon = "dChanged"
	cdefaultsort = "cWellID"
	Name = "wellsvfpbizobj"


	PROCEDURE validation
		LPARAMETERS tcCursor AS Character
		*//******************************************************************************************
		*//  FUNCTION NAME: 
		*//
		*//  AUTHOR: White Light Computing, Inc. 08/21/2020
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
		*//     08/21/2020 - JLM - Created 
		*//******************************************************************************************
		This.ClearValidationErrors()
		This.cErrorMsg = SPACE(0)

		*-- cWellID validation -  - Required and Unique
		IF EMPTY(NVL(cWellID,SPACE(0)))
		   This.AddValidationError('The Well ID is required.', 'cWellID')
		   This.cErrorMsg = 'The Well ID is required.' + CHR(13)
		ELSE
		   IF This.IsUnique(cWellID, 'cWellID',cWellID) <> 0
		      This.AddValidationError('The Well ID must be unique.', 'cWellID')
			   This.cErrorMsg = This.cErrorMsg + 'The Well ID must be unique.' + CHR(13)
		   ENDIF
		ENDIF   

		*-- cWellName validation -  - Required 
		IF EMPTY(NVL(cWellName,SPACE(0)))
		   This.AddValidationError('The Well Name is required.', 'cWellName')
			This.cErrorMsg = This.cErrorMsg + 'The Well Name is required.' + CHR(13)
		ENDIF   

		RETURN ISNULL(This.oValidationErrors) OR (This.oValidationErrors.COUNT = 0)
		  
	ENDPROC


	PROCEDURE search
		LPARAMETERS ;
			tcWellID AS Character ;
			,tcWellName AS Character 
		*//******************************************************************************************
		*//  FUNCTION NAME: WellsBizObj.Search()
		*//
		*//  AUTHOR: White Light Computing, Inc. 08/21/2020
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
		*//     08/21/2020 - JLM - Created
		*//******************************************************************************************  
		LOCAL ;
		    lcSQL AS Character ;
		   ,lcDF AS Character ;
		   ,loParameter AS Object ;
		   ,loSelect

		loSelect    = CreateFactory('cSelect')
		loParameter = This.oSQL.GetParameterObject()

		*!* Uncomment when parameters are passed --> loParameter = This.oSQL.GetParameterObject()
		IF NOT This.oSQL.lVFPTable
		   TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
		      SELECT
		         [<<This.cTable>>].*
		      FROM
		         [<<This.cSQLSchema>>].[<<This.cTable>>]
		   ENDTEXT

		   IF EMPTY(NVL(m.tcWellID,SPACE(0)))    
		      *-- Nothing at this time 
		   ELSE
		      loParameter.Add('cWellID', ALLTRIM(m.tcWellID) + '%')
		      
		      TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2
		            AND [<<This.cTable>>].[cWellID] LIKE ?cWellID
		      ENDTEXT
		   ENDIF   

		   IF EMPTY(NVL(m.tcWellName,SPACE(0)))    
		      *-- Nothing at this time 
		   ELSE
		      loParameter.Add('cWellName', '%' + ALLTRIM(m.tcWellName) + '%')
		      
		      TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2
		            AND [<<This.cTable>>].[cWellName] LIKE ?cWellName
		      ENDTEXT
		   ENDIF 
		   
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

		   IF EMPTY(NVL(m.tcWellID,SPACE(0)))    
		      *-- Nothing at this time 
		   ELSE
		      loParameter.Add('cWellID', ALLTRIM(m.tcWellID) + '%')
		      
		      TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2 PRETEXT 2+4+8
		            AND <<This.cTable>>.cWellID LIKE ?cWellID
		      ENDTEXT
		   ENDIF   

		   IF EMPTY(NVL(m.tcWellName,SPACE(0)))    
		      *-- Nothing at this time 
		   ELSE
		      loParameter.Add('cWellName', '%' + ALLTRIM(m.tcWellName) + '%')
		      
		      TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2 PRETEXT 2+4+8
		            AND <<This.cTable>>.cWellName LIKE ?cWellName
		      ENDTEXT
		   ENDIF 
		ENDIF 

		IF NOT EMPTY(This.cDefaultSort)
		   TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1 PRETEXT 2+4+8
		      ORDER BY
		         <<This.cDefaultSort>>
		   ENDTEXT
		ENDIF

		_CLIPTEXT = LCSQL
		This.oSQL.Execute(m.lcSQL, This.cSearchCursor, loParameter)

		STORE .NULL. TO loSelect, loParameter

		RETURN 
	ENDPROC


ENDDEFINE
*
*-- EndDefine: wellsvfpbizobj
**************************************************

******************************************************************************************
*  PROGRAM: Utility.prg
*
*  AUTHOR: White Light Computing, Inc.
*
*  COPYRIGHT © 2010-2018   All Rights Reserved.
*     White Light Computing, Inc.
*     PO Box 391
*     Washington Twp., MI  48094
*     raschummer@whitelightcomputing.com
*
*  PROGRAM DESCRIPTION:
*     Various functions
*     
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
*  CALLING SYNTAX:
*     Doesn't apply - This contains many different FUNCTIONS
*
*  INPUT PARAMETERS:
*     None
*
*  OUTPUT PARAMETERS:
*     None
*
*  DATABASES ACCESSED:
*     None
* 
*  GLOBAL PROCEDURES REQUIRED:
*     None
* 
*  CODING STANDARDS:
*     Version 5.2 compliant with no exceptions
*  
*  TEST INFORMATION:
*     None
*   
*  SPECIAL REQUIREMENTS/DEVICES:
*     None
*
*  FUTURE ENHANCEMENTS:
*     None
*
*  LANGUAGE/VERSION:
*     Visual FoxPro 09.00.0000.7423 or higher
* 
******************************************************************************************
*                             C H A N G E    L O G                              
*
*    Date     Developer               Version  Description
* ----------  ----------------------  -------  -------------------------------------------
*
* ----------------------------------------------------------------------------------------
*
******************************************************************************************
*//******************************************************************************************
*//  FUNCTION NAME: RunReport
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Run the passed in report 
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tcReportTitle - Report Title
*//       tcCursor      - Cursor name
*//       tcReport      - Report (FRX)
*//       tcOutput - PRINT
*//                  PREVIEW
*//                  PDF
*//       toEmailInfo  - EmailBizObj reference
*//       tcOutputName - Output path/filename for PDF report.
*//                      Required for tcOutput = "PDF", not used for others
*// 
*//    OUTPUT PARAMETERS: 
*//       None   
*//******************************************************************************************
*//  MODIFICATIONS:
*//     02/10/2011 - Paul Mrozowski - Created 
*//******************************************************************************************  
FUNCTION RunReport(tcReportTitle, tcCursor, tcReport, tcOutput, toEmailInfo, tcOutputName)
   LOCAL loListener ;
         ,loPreview AS FrmMPPreviewer OF XFRXLib ;
         ,lcReportType AS Character 
   
   IF VARTYPE(m.tcOutput) <> 'C'
      tcOutput = "PREVIEW"
   ENDIF
   
   IF !USED(m.tcCursor)
      MESSAGEBOX("No matching records found.", 64, "Report - " + ALLTRIM(m.tcReportTitle))
      CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput,'No matching records found for cursor (NOT USED()): ' + TRANSFORM(m.tcCursor))
      RETURN
   ENDIF

   SELECT (m.tcCursor)
   IF RECCOUNT(m.tcCursor) = 0
      MESSAGEBOX("No matching records found.", 64, "Report - " + ALLTRIM(m.tcReportTitle))
      CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput,'No matching records found for cursor: ' + TRANSFORM(m.tcCursor))
      RETURN
   ENDIF
   
   DO CASE 
      CASE FILE(ALLTRIM(FORCEEXT(m.tcReport, "FRX")))
         m.lcReportForm = 'REPORT'
               
      CASE FILE(ALLTRIM(FORCEEXT(m.tcReport, "LBX")))
         m.lcReportForm = 'LABEL'
      
      OTHERWISE 
         MESSAGEBOX("Unable to find the report file for: " + NVL(m.tcReport, "NULL"), 16, "Report Error")
         *-- Begin Add by JLM of WLC 11/18/2014
         CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput,'Unable to find the report file for: ' + TRANSFORM(m.tcReport))
         *-- End Add by JLM of WLC 11/18/2014  
         RETURN
   ENDCASE 
   
   *-- Begin Add by JLM 11/05/2011
   IF VARTYPE(m.tcOutput) = 'C' ;
      AND NOT INLIST(UPPER(m.tcOutput), 'PREVIEW', 'VFPPREVIEW', 'EMAIL', 'DONOTSHOW', "PDF")
      
      m.tcOutput = ALLTRIM(m.tcOutput)
      
      TRY 
         SET PRINTER TO 
         SET PRINTER TO NAME (m.tcOutput)
      CATCH TO loEx
         CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput, loEx.Message)
         SET PRINTER TO (m.tcOutput)
      ENDTRY 

      SELECT (m.tcCursor)
      IF m.lcReportForm = 'REPORT'       
         REPORT FORM (m.tcReport) TO PRINTER NOCONSOLE  
      ELSE
         LABEL FORM (m.tcReport) TO PRINTER NOCONSOLE  
      ENDIF     
      
      SET PRINTER TO DEFAULT
     
   ELSE
      DO CASE
         CASE INLIST(UPPER(m.tcOutput),'PREVIEW')
            * PCM - 2/14/2013 - Ugly way to pass report cursor name, but I can do this in 1 minute vs a few hours of 
            * poking around in the XFRX code.
            PRIVATE pcReportCursor, ;
                    pnWorkArea
                    
            pcReportCursor = m.tcCursor
            pnWorkArea = SET("Datasession")
            
            loListener = XFRX("XFRX#LISTENER")
            lnReturn = loListener.SetParams("",,,,,, "XFF")
            
            IF m.lnReturn = 0
               SELECT (m.tcCursor)
               TRY 
                  IF m.lcReportForm = 'REPORT'       
                     REPORT FORM (m.tcReport) OBJECT loListener && PREVIEW 
                  ELSE
                     LABEL FORM (m.tcReport) OBJECT loListener && PREVIEW 
                  ENDIF    
                  loPreview = CREATEOBJECT("frmMPPreviewer")
                  loPreview.WindowType = 0
                  loPreview.PreviewXFF(loListener.oxfDocument, tcReportTitle)
                  loPreview.Show(1)    
                  loPreview  = NULL
                  loListener = NULL
               CATCH 
                  SELECT (m.tcCursor)
                  loPreview  = NULL
                  loListener = NULL
                  
                  IF m.lcReportForm = 'REPORT'       
                     REPORT FORM (m.tcReport) PREVIEW NOCONSOLE
                  ELSE
                     LABEL FORM (m.tcReport) PREVIEW NOCONSOLE
                  ENDIF                  
               ENDTRY    
            ELSE
               MESSAGEBOX("Preview failed with the error #" + TRANSFORM(m.lnReturn), 16, "Preview Error")
               *-- Begin Add by JLM of WLC 11/18/2014
               CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput,'Preview failed with the error #' + TRANSFORM(m.lnReturn))
               *-- End Add by JLM of WLC 11/18/2014
            ENDIF

         CASE INLIST(UPPER(m.tcOutput),'VFPPREVIEW')
            m.tcOutput = 'PREVIEW'
            IF m.lcReportForm = 'REPORT'       
               REPORT FORM (m.tcReport) PREVIEW NOCONSOLE
            ELSE
               LABEL FORM (m.tcReport) PREVIEW NOCONSOLE
            ENDIF

         CASE INLIST(UPPER(m.tcOutput),'EMAIL')
            loListener = XFRX("XFRX#LISTENER")
            m.lnReturn = loListener.SetParams(curEmail.cAttachment,,.T.,,,, "PDF")
            
            IF m.lnReturn = 0
               IF m.lcReportForm = 'REPORT'       
                  REPORT FORM (m.tcReport) OBJECT loListener && PDF
               ELSE
                  LABEL FORM (m.tcReport) OBJECT loListener && PDF
               ENDIF    
               loListener = NULL
               IF toEmailInfo.Save("curEmail")
                  *-- Nothing at this time 
               ELSE
                  MESSAGEBOX("Email Creation Failed: " + toEmailInfo.cErrorMsg, 16, "Email Error")
                  *-- Begin Add by JLM of WLC 11/18/2014
                  CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput, 'Email Creation Failed: ' + toEmailInfo.cErrorMsg)
                  *-- End Add by JLM of WLC 11/18/2014

               ENDIF  
            ELSE
               MESSAGEBOX("Preview failed with the error #" + TRANSFORM(m.lnReturn), 16, "PDF Error")
               *-- Begin Add by JLM of WLC 11/18/2014
               CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput, 'Preview failed with the error #' + TRANSFORM(m.lnReturn))
               *-- End Add by JLM of WLC 11/18/2014
            ENDIF          

         CASE INLIST(UPPER(m.tcOutput), 'PDF')
              loListener = XFRX("XFRX#LISTENER")
              lnReturn = loListener.SetParams(m.tcOutputName,,.T.,,,, "PDF")
            
              IF m.lnReturn = 0
                 IF m.lcReportForm = 'REPORT'       
                    REPORT FORM (m.tcReport) OBJECT loListener && PDF
                 ELSE
                    LABEL FORM (m.tcReport) OBJECT loListener && PDF
                 ENDIF   
                  
                 loListener = NULL              
              ELSE
                 MESSAGEBOX("PDF file creation failed with the error #" + TRANSFORM(m.lnReturn), 16, "PDF Error")
                 *-- Begin Add by JLM of WLC 11/18/2014
                 CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput,'PDF file creation failed with the error #' + TRANSFORM(m.lnReturn))
                 *-- End Add by JLM of WLC 11/18/2014

              ENDIF              
            
         CASE INLIST(UPPER(m.tcOutput),'DONOTSHOW')
         *-- Using this to figure out the page counts for the Payment Report (laserchk.frx)
            loListener = XFRX("XFRX#LISTENER")
            m.lnReturn = loListener.SetParams("",,.T.,,,, "XFF")
            
            IF m.lnReturn = 0
               TRY 
                  IF m.lcReportForm = 'REPORT'       
                     REPORT FORM (m.tcReport) OBJECT loListener
                  ELSE
                     LABEL FORM (m.tcReport) OBJECT loListener
                  ENDIF    
                  loListener = NULL
               CATCH 
               ENDTRY    
            ELSE
               MESSAGEBOX("Do Not Show Report error #" + TRANSFORM(m.lnReturn), 16, "Reporting Error")
               *-- Begin Add by JLM of WLC 11/18/2014
               CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput,'Used to figure out the page counts only - Do Not Show Report error #' + TRANSFORM(m.lnReturn))
               *-- End Add by JLM of WLC 11/18/2014
            ENDIF
            
         OTHERWISE 
            MESSAGEBOX("Unsupported report type: " + m.tcOutput, 16, "Run Report: Unsupported type Error")
            *-- Begin Add by JLM of WLC 11/18/2014
            CreatePrintLog(TRANSFORM(m.tcReportTitle), TRANSFORM(m.tcReport), m.tcOutput,'Unsupported report type: ' + m.tcOutput)
            *-- End Add by JLM of WLC 11/18/2014
      ENDCASE 
                   
   ENDIF    
   
   *-- End Add by JLM 11/05/2011 

ENDFUNC

*//******************************************************************************************
FUNCTION GetNewID(tcType, tiIncrement, toSQL)
*//******************************************************************************************
*//  FUNCTION NAME: GetNewID
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
*//     Get a new incrementing ID
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tcType      - Name of ID 
*//       tiIncrement - Increment amount
*//       toSQL (Optional) - reference to SQL object
*//
*//    OUTPUT PARAMETERS: 
*//        Next #
*//******************************************************************************************
*//  MODIFICATIONS:
*//     06/7/2011 - Paul Mrozowski - Created 
*//******************************************************************************************  
   LOCAL lcSQL, ;
         loSQL, ;
         liID, ;
         loSelect
   
   loSelect = CreateFactory("CSelect")
      
   TEXT TO lcSQL NOSHOW TEXTMERGE
      DECLARE @nRetVal int
       
      EXEC GetNewID '<<m.tcType>>', @nRetVal output, <<m.tiIncrement>>
      SELECT @nRetVal AS id
   ENDTEXT
   
   IF VARTYPE(toSQL) = "O"
      loSQL = m.toSQL
   ELSE
      loSQL = CreateFactory("wlcSQL")
   ENDIF
      
   loSQL.Execute(m.lcSQL, "curNextID")
   
   liID = curNextID.id
   
   USE IN SELECT("curNextID")
   
   loSelect = NULL
   
   RETURN m.liID
ENDFUNC

*//******************************************************************************************
FUNCTION GetParentFolderName(tcPath)
*//******************************************************************************************
*//  FUNCTION NAME: GetParentFolderName
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
*//    Returns the parent folder name from the passed in path
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tcPath - Path (can include file)
*//
*//    OUTPUT PARAMETERS: 
*//       Parent folder name
*//******************************************************************************************
*//  MODIFICATIONS:
*//     06/1/2010   - Paul Mrozowski- Created 
*//******************************************************************************************  
   LOCAL ;
       lcFolder ;
      ,lnCount
      
   lcFolder = JUSTPATH(m.tcPath)

   IF !EMPTY(m.lcFolder)
      lnCount = OCCURS("\", m.lcFolder)
   
      IF lnCount > 0
         lcFolder = SUBSTR(m.lcFolder, AT("\", m.lcFolder, m.lnCount) + 1)
      ENDIF
   ENDIF   

   RETURN m.lcFolder
ENDFUNC

*//******************************************************************************************
FUNCTION GetLastDayOfMonth(tdDate)
*//******************************************************************************************
*//  FUNCTION NAME: GetLastDayOfMonth
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
*//    Returns the last day of the month based on the passed in date 
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tdDate - Date
*//
*//    OUTPUT PARAMETERS: 
*//       Last day of the month
*//******************************************************************************************
*//  MODIFICATIONS:
*//     12/16/2011 - Paul Mrozowski - Created 
*//******************************************************************************************  
   LOCAL ;
      ldDate AS Date ;
      ,ldNext AS Date
       
   ldNext = GOMONTH(m.tdDate, 1)
   ldNext = DATE(YEAR(m.ldNext), MONTH(m.ldNext), 1) 
   
   ldDate = m.ldNext - 1
   
   RETURN m.ldDate
ENDFUNC

*//******************************************************************************************
FUNCTION CreateFactory
*//******************************************************************************************
*//  FUNCTION NAME:  CreateFactory
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    A (very) simple object factory. Right now, it just does a CreateObject on the passed 
*//    in class name. The idea is that this will give me a central place to easily swap out some
*//    objects for others, pre-populate properties on objects, etc. It could be data-driven, 
*//    but at this point I'm not doing it.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tcClassname - Class name
*//       glTest - Global Variable. If set to .T., enable test mode.
*//
*//    OUTPUT PARAMETERS: 
*//       loObj - Instance of object (or .NULL. if there is an error)
*//******************************************************************************************
*//  MODIFICATIONS:
*//    10/29/2007 - PCM - Created 
*//    02/03/2018 - SJE - Moved connection code to it's own function so it can be shared.
*//    03/02/2020 - JLM - Added WLCVFP
*//****************************************************************************************** 
LPARAMETERS tcClassname, tuParam1, tuParam2, tuParam3, tuParam4, tuParam5

LOCAL loObj, ;
      loException AS Exception, ;
      loEx AS Exception, ;
      lnParamCount 

loObj = .NULL.

IF VARTYPE(m.tcClassname) = "C"
   TRY      

      DO CASE
          CASE UPPER(m.tcClassname) = UPPER("AsyncSQLExec") ;
            OR UPPER(m.tcClassname) = UPPER("SQLLogger")
            
            loObj = CREATEOBJECT(m.tcClassname)
            *-- Connect to SQL
            SQLObjConnect(@loObj, m.tuParam1)

             
         *-- Begin Modified by JLM of WLC 03/02/2020
         *!* CASE UPPER(m.tcClassname) = 'WLCSQL'
         CASE INLIST(UPPER(m.tcClassname),'WLCSQL','WLCVFP')
         *-- End Modified by JLM of WLC 03/02/2020
            loObj = CREATEOBJECT(m.tcClassname)

            *-- Set some default props              
            loObj.lLocallyGeneratedPk      = .F.
            loObj.lEnableInstrumentation   = .F.
            loObj.cInstrumentationDatabase = SPACE(0)
              
            *-- Connect to SQL if the PUBLIC variable, glSQLServer, is set to .T.
            IF m.glSQLServer && Added 03/02/2020
               SQLObjConnect(@loObj, m.tuParam1)
            ENDIF 
            
         OTHERWISE
            lnParamCount = PCOUNT()
              
            DO CASE
               CASE lnParamCount = 2
                  loObj = CREATEOBJECT(m.tcClassname, m.tuParam1)
               CASE lnParamCount = 3
                  loObj = CREATEOBJECT(m.tcClassname, m.tuParam1, m.tuParam2)
               CASE lnParamCount = 4
                  loObj = CREATEOBJECT(m.tcClassname, m.tuParam1, m.tuParam2, m.tuParam3)
               CASE lnParamCount = 5
                  loObj = CREATEOBJECT(m.tcClassname, m.tuParam1, m.tuParam2, m.tuParam3, m.tuParam4)
               CASE lnParamCount = 6
                  loObj = CREATEOBJECT(m.tcClassname, m.tuParam1, m.tuParam2, m.tuParam3, m.tuParam4, m.tuParam5)
               OTHERWISE
                  loObj = CREATEOBJECT(m.tcClassname)
            ENDCASE
              
      ENDCASE
      
   CATCH TO loException
      MESSAGEBOX(loException.Message)
      loObj = .NULL.
   ENDTRY
ENDIF

RETURN loObj

ENDFUNC

******************************************************************
*  FUNCTION NAME: GetFriendlyTimespan
*	
*  AUTHOR, DATE:
*	  Paul Mrozowski, 10/8/2010  
*  PROCEDURE DESCRIPTION:
*	  Turns the passed in # of seconds into days/hours/minutes/
*      seconds string.
*  INPUT PARAMETERS:
*	  tnSeconds - # of seconds
*  OUTPUT PARAMETERS:
*	  String of days/hours/minutes/seconds
******************************************************************
FUNCTION GetFriendlyTimespan(tnSeconds)
  LOCAL lnRemainingSeconds, ;
        lnMinutes, ;
        lnHours, ;
        lnDays, ;
        lcFriendly 
  
  lnDays = INT(tnSeconds / (24 * 60 * 60))
  lnRemainingSeconds = tnSeconds - (lnDays * 24 * 60 * 60)
  lnHours = INT(lnRemainingSeconds / (60 * 60))      
  lnRemainingSeconds = lnRemainingSeconds - (lnHours * 60 * 60)
  lnMinutes = INT(lnRemainingSeconds / 60)
  lnRemainingSeconds = lnRemainingSeconds - (lnMinutes * 60)
  
  lcFriendly = ""
  
  IF lnDays > 0
     lcFriendly = lcFriendly + TRANSFORM(lnDays) + " days"
  ENDIF
  
  IF lnHours > 0
     lcFriendly = lcFriendly ;
                + IIF(!EMPTY(lcFriendly), ", ", "") ;
                + TRANSFORM(lnHours) + " hours"
  ENDIF
  
  IF lnMinutes > 0
     lcFriendly = lcFriendly ;
                + IIF(!EMPTY(lcFriendly), ", ", "") ;
                + TRANSFORM(lnMinutes) + " minutes"
  ENDIF
  
  IF lnRemainingSeconds > 0
     lcFriendly = lcFriendly ;
                + IIF(!EMPTY(lcFriendly), ", and ", "") ;
                + TRANSFORM(lnRemainingSeconds) + " seconds"
  ENDIF
  
  RETURN IIF(EMPTY(lcFriendly), "less than 1 second.", lcFriendly + ".")
ENDFUNC


*//******************************************************************************************
FUNCTION GetUserID()
*//******************************************************************************************
*//  FUNCTION NAME: GetUserID
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
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
*//     02/17/2018 - JLM - Created 
*//     11/29/2018 - JLM - Modified to use the security wlcuser object information. 
*//******************************************************************************************  
   LOCAL loSM, lcUserId
   
   lcUserId = SPACE(0)
   
   IF !PEMSTATUS(_VFP,'oSecurityMgr',5) ;
   OR ISNULL(_VFP.oSecurityMgr) 
      *-- Nothing at this time 
   ELSE
      loSM = _VFP.oSecurityMgr
      IF VARTYPE(m.loSM) == "O" AND !ISNULL(m.loSM)
         lcUserId = loSM.GetWLCUserID()
      ENDIF       
   ENDIF
   
   IF EMPTY(m.lcUserId) 
      lcUserId = ALLTRIM(STREXTRACT(SYS(0), "#"))
   ENDIF 
   
   RETURN m.lcUserId  
ENDFUNC

*//******************************************************************************************
FUNCTION GetUserComputerName()
*//******************************************************************************************
*//  FUNCTION NAME:  GetUserComputerName()
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Gets the current User's Computer Name
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None
*//
*//    OUTPUT PARAMETERS: 
*//       None
*//******************************************************************************************
*//  MODIFICATIONS:
*//    02/11/2018 - SJE - Created 
*//****************************************************************************************** 
   LOCAL lcUser, lnPos, lcName
   lcName = "<Unknown>"
   lcUser = LTRIM(SYS(0))
   lnPos = AT("#",m.lcUser)
   IF m.lnPos > 0
      lcName = ALLTRIM(LEFT(m.lcUser,m.lnPos-1))
   ENDIF
   RETURN m.lcName
ENDFUNC

******************************************************************
*  FUNCTION NAME: GetValidationErrorsAsString
*   
*  AUTHOR, DATE:
*     Paul Mrozowski,2/3/2012
*  PROCEDURE DESCRIPTION:
*     Returns a string out of the validation errors collection
*  INPUT PARAMETERS:
*     toValidationErrors - validation errors collection
*     tcDelimiter (optional) - Delimiter for the string (defaults
*           to CHR(13). Eg. "</br>"
*  OUTPUT PARAMETERS:
*     String
******************************************************************
FUNCTION GetValidationErrorsAsString(toValidationErrors, tcDelimiter)  
  LOCAL lcError, ;
        lcDelimiter

  lcError = ""
  lcDelimiter = CHR(13)
   
  IF ISNULL(m.toValidationErrors) OR TYPE("toValidationErrors") <> "O"
     RETURN ""
  ENDIF
   
  IF VARTYPE(m.tcDelimiter) = "C"
     lcDelimiter = tcDelimiter
  ENDIF

  IF VARTYPE(m.toValidationErrors) = "O"
     FOR EACH oError IN m.toValidationErrors
         lcError = lcError ;
                 + oError.Message + lcDelimiter

     ENDFOR
  ENDIF

  RETURN lcError   
ENDFUNC

*//******************************************************************************************
FUNCTION GenGuid(tlClear)
*//******************************************************************************************
*//  FUNCTION NAME: GenGuid
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Generates a sequential GUID 
*//    Snagged and modified version from VFP Wiki
*//    Modified to assume that all of the DECLARES have already been done. This gets called 
*//    a LOT and a ton of time is being spent on re-declaring them.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tlClear - Unload the DLL's after use
*//
*//    OUTPUT PARAMETERS: 
*//       None   
*//******************************************************************************************
*//  MODIFICATIONS:
*//     6/2/2010  - Paul Mrozowski - Created 
*//******************************************************************************************  
   LOCAL lcBuffer ;
   	,lcReturnValue ;
   	,llClear ;
   	,lnFuncVal

   *-- Define local variables
   lcBuffer      = REPLICATE( CHR( 0 ), 256 )
   lcReturnValue = []
   lnFuncVal     = 0

   *-- Declare DLL functions
   *!*	DECLARE INTEGER CoCreateGuid ;
   *!*		IN Ole32.DLL ;
   *!*		STRING @pGuid
   *!*		
   *!*	DECLARE INTEGER UuidCreateSequential IN RPCRT4.DLL ;
   *!*	        STRING @UniqueID	

   *!*	DECLARE INTEGER StringFromGUID2 ;
   *!*		IN Ole32.DLL ;
   *!*		STRING rguid, STRING @lpsz, INTEGER cchMax

   *-- Initialize a buffer to hold the GUID value
   pGuid = REPLICATE( CHR( 0 ), 17 )

   *-- Call the CoCreateGuid function
   *lnFuncVal = CoCreateGuid( @pGuid )
   *!* lnFuncVal = UuidCreateSequential(@pGuid)

   *-- If the DLL function returned zero,
   *-- the function was successful,
   *-- so build a string of the GUID data
   IF m.lnFuncVal = 0
   	= StringFromGUID2( m.pGuid, @lcBuffer, 128 )

   	*-- Truncate the GUID string to the desired length
   	lcBuffer = SUBSTR( m.lcBuffer, ;
   				1, ;
   				AT(CHR(0) + CHR(0), m.lcBuffer))

   	*-- Convert the string
   	lcReturnValue = STRCONV( m.lcBuffer, 6 )
   	
   	* Now strip the braces
       lcReturnValue = SUBSTR(m.lcReturnValue, 2, 36)
   ENDIF && lnFuncVal = 0

   *-- Unless the calling module chose not to,
   *-- clear the instantiated DLLs from memory
   *!*	IF !m.llClear
   *!*		CLEAR DLLS "StringFromGUID2"
   *!*		CLEAR DLLS "CoCreateGuid"
   *!*	ENDIF 

   *-- Clean up and return
   RETURN ( m.lcReturnValue )
ENDFUNC 
*== End module F9GUID


*//******************************************************************************************
FUNCTION GetSpecial(tnFolder, tlCreate)
*//******************************************************************************************
*//  FUNCTION NAME: GetSpecial
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Returns the path to one of Windows' "special folders", such as My Documents, Application 
*//    Data, Program Files, etc.
*//
*//    Code taken from here: 
*//    http://www.hexcentral.com/articles/foxpro-folders.htm
*//    
*//    INPUT PARAMETERS:
*//       tnFolder - Folder CSIDL
*//       tlCreate - Create the folder if it doesn't already exist
*//    
*//    CSIDL (decimal) Description                   Typical values
*// --------------------------------------------------------------------------------------------------------------------------
*//       5            My Documents..................C:\Documents and Settings\username\My Documents
*//                                ..................C:\Users\username\Documents
*//       6            Favorites.....................C:\Documents and Settings\username\Favorites
*//                             .....................C:\Users\IserName\Favorites
*//       8            Recent Documents..............C:\Documents and Settings\username\Recent
*//       9            Send To.......................C:\Documents and Settings\username\SendTo
*//      13            My Music......................C:\Documents and Settings\User\My Documents\My Music
*//                            ......................C:\Users\UserName\Music
*//      14            My Videos.....................C:\Documents and Settings\User\My Documents\My Videos
*//                             .....................C:\Users\UserName\Videos
*//      16            Desktop.......................C:\Documents and Settings\username\Desktop
*//                           .......................C:\Users\username\Desktop
*//      19            Network Neighborhood..........C:\Documents and Settings\username\NetHood
*//      20            Fonts.........................C:\Windows\Fonts
*//      26            Application Data..............C:\Documents and Settings\username\Application Data
*//                                    ..............C:\Users\username\AppData\Roaming
*//      28            Local (non-roaming) app data..C:\Documents and Settings\username\Local Settings\Application Data
*//                                                ..C:\Users\username\AppData\Local
*//      33            Cookies.......................C:\Documents and Settings\username\Cookies
*//      35            Common Application Data.......C:\Documents and Settings\All Users\Application Data
*//                                           .......C:\ProgramData
*//      36            Windows.......................C:\Windows
*//      37            System........................C:\Windows\System32
*//      38            Program Files.................C:\Program Files
*//      39            My Pictures...................C:\Documents and Settings\User\My Documents\My Pictures
*//                               ...................C:\Users\UserName\Pictures
*//      43            Common Files..................C:\Program Files\Common
*// --------------------------------------------------------------------------------------------------------------------------
*//  
*//    OUTPUT PARAMETERS: 
*//       Returns the path to the specified folder. If the CLSID
*//       is invalid, or the folder doesn't exist (and the second
*//       parameter is .F.), returns an empty string
*//******************************************************************************************
*//  MODIFICATIONS:
*//     12/20/2012  - Paul Mrozowski - Created 
*//******************************************************************************************  
	LOCAL lcPath, lnPidl, lnPidlOK, lnFolderOK

	#DEFINE MAX_PATH 260
	#DEFINE CREATE_FLAG 32768 

	*-- Delcare the API functions
	DECLARE LONG SHGetSpecialFolderLocation IN shell32 ;
		LONG Hwnd, LONG lnFolder, LONG @pPidl
	DECLARE LONG SHGetPathFromIDList IN shell32 ;
		LONG pPidl, STRING @pszPath
	DECLARE CoTaskMemFree IN ole32 LONG pVoid

	lcPath = SPACE(MAX_PATH)
	lnPidl = 0

	*-- If .T. is passed as second param, we want to create the 
	*-- folder if it doesn't already exist.
	IF tlCreate
		tnFolder = tnFolder + CREATE_FLAG
	ENDIF 
		
	*-- Get the PIDL
	lnPidlOK = SHGetSpecialFolderLocation(0, tnFolder, @lnPidl)

	IF lnPidlOK = 0
	  *-- Pidl found OK; get the folder
	  lnFolderOK = SHGetPathFromIDList(lnPidl, @lcPath)
	  IF lnFolderOK = 1
	    *-- Folder found OK; trim the string at the null terminator
	    lcPath = LEFT(lcPath, AT(CHR(0), lcPath) - 1)
	  ENDIF 
	ENDIF 

	*-- Free the ID List
	CoTaskMemFree(lnPidl)

	RETURN ALLTRIM(lcPath)
ENDFUNC

*//******************************************************************************************
DEFINE CLASS wlcChangeWatcher AS Session
*//******************************************************************************************
*//  CLASS NAME: wlcChangeWatcher AS Session 
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
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
*//     02/17/2018 - JLM - Created 
*//******************************************************************************************  
   uOriginalValue = NULL
   oCurrentControl = NULL
   oControls = NULL
   
   *//******************************************************************************************
   FUNCTION BindChanges(toContainer)
   *//******************************************************************************************
   *//  FUNCTION NAME: 
   *//
   *//  AUTHOR: White Light Computing, Inc. 02/17/2018
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
   *//     02/17/2018 - JLM - Created 
   *//******************************************************************************************  
      LOCAL loControl
      
      IF VARTYPE(toContainer) <> "O"
         RETURN
      ENDIF
      
      FOR EACH loControl IN toContainer.Controls
          IF PEMSTATUS(loControl, "GotFocus", 5) AND PEMSTATUS(loControl, "LostFocus", 5)
             BINDEVENT(loControl, "GotFocus", This, "OnGotFocus")
             BINDEVENT(lOControl, "LostFocus", This, "OnLostFocus")
          ENDIF
          
          IF PEMSTATUS(loControl, "Controls", 5) 
             This.BindChanges(loControl)
          ENDIF          
      ENDFOR
   ENDFUNC
   
   *//******************************************************************************************
   FUNCTION OnGotFocus()
   *//******************************************************************************************
   *//  FUNCTION NAME: OnGotFocus
   *//
   *//  AUTHOR: White Light Computing, Inc. 02/17/2018
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
   *//     02/17/2018 - JLM - Created 
   *//******************************************************************************************  
      LOCAL laEvent[1], ;
            loObject
      
      AEVENTS(laEvent, 0)
      loObject = laEvent[1]
      This.uOriginalValue = NULL
      
      IF VARTYPE(loObject) = "O"
         IF PEMSTATUS(loObject, "Value", 5)
            This.cOriginalValue = loObject.Value
         ENDIF
      ENDIF
   ENDFUNC
   
   *//******************************************************************************************
   FUNCTION OnLostFocus()
   *//******************************************************************************************
   *//  FUNCTION NAME: OnLostFocus
   *//
   *//  AUTHOR: White Light Computing, Inc. 02/17/2018
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
   *//     02/17/2018 - JLM - Created 
   *//******************************************************************************************  
      LOCAL laEvent[1], ;
            loObject
            
      AEVENTS(laEvent, 0)
      loObject = laEvent[1]  
          
      IF VARTYPE(loObject) = "O"
         IF PEMSTATUS(loObject, "Value", 5)
            IF loObject.Value <> This.uOriginalValue
               This.ControlChangedEvent()  
            ENDIF
                        
            This.uOriginalValue = NULL
         ENDIF
      ENDIF
      
   ENDFUNC
   
   *//******************************************************************************************
   FUNCTION ControlChangedEvent()
   *//******************************************************************************************
   *//  FUNCTION NAME: ControlChangedEvent
   *//
   *//  AUTHOR: White Light Computing, Inc. 02/17/2018
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
   *//     02/17/2018 - JLM - Created 
   *//******************************************************************************************  
      IF TYPE("ThisForm") = "O" 
         IF PEMSTATUS(ThisForm, "lChanged", 5)
            ThisForm.lChanged = .T.
         ENDIF
      ENDIF
   ENDFUNC
   
   *//******************************************************************************************
   FUNCTION Destroy
   *//******************************************************************************************
   *//  FUNCTION NAME: Destroy
   *//
   *//  AUTHOR: White Light Computing, Inc. 02/17/2018
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
   *//     02/17/2018 - JLM - Created 
   *//******************************************************************************************  
      This.oCurrentControl = NULL
      This.oControls = NULL
   ENDFUNC
ENDDEFINE

*//******************************************************************************************
FUNCTION EscapeStopProcess()  
*//******************************************************************************************
*//  FUNCTION NAME: EscapeStopProcess
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Used with ON KEY LABEL ESCAPE DO EscapeStopProcess. Will set a property 
*//    _VFP.lBerProStopProcess to ask if the process needs to be stopped.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None   
*//
*//    OUTPUT PARAMETERS: 
*//       None   
*//******************************************************************************************
*//  MODIFICATIONS:
*//     02/17/2018 - JLM - Created 
*//******************************************************************************************  
   _VFP.lStopProcess = .T.

   IF MESSAGEBOX('The ESCAPE key has been pressed. Do you want to stop processing?',4+256,'Stop processing?') = 6
      *-- Yes... they want to stop the process.
   ELSE
      *-- Keep going 
      _VFP.lStopProcess = .F.
   ENDIF   

   RETURN _VFP.lStopProcess 

ENDFUNC 

*//******************************************************************************************
FUNCTION IsAllDigits(tcSearched, tcOptionalSearch)
*//******************************************************************************************
*//  FUNCTION NAME: IsAllDigits
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Checks is the passed string is all numeric characters.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tcSearched = the string of characters to test.
*//       tcOptionalSearch = optional, additional characters to allow.
*//
*//    OUTPUT PARAMETERS: 
*//       Boolean
*//******************************************************************************************
*//  MODIFICATIONS:
*//     12/05/2012 - Frank Perez - Created 
*//******************************************************************************************  
	LOCAL ;
       lcSearch ;
      ,lcRemaining  

	m.lcSearch    = "01234567989" + IIF(VARTYPE(m.tcOptionalSearch) = "C", m.tcOptionalSearch, "")
	m.lcRemaining = CHRTRAN(m.tcSearched, m.lcSearch, "")

	RETURN ( LEN(m.lcRemaining) = 0 )
ENDFUNC

*//******************************************************************************************
FUNCTION IsEmptyNull(t_Value)
*//******************************************************************************************
*//  FUNCTION NAME: IsEmptyNull
*//
*//  AUTHOR: White Light Computing, Inc. 03/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Checks is the value NULL/EMPTY.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       t_Value = Any value
*//
*//    OUTPUT PARAMETERS: 
*//       Boolean
*//******************************************************************************************
*//  MODIFICATIONS:
*//     03/17/2018 - Jody L Meyer - Created from Steve's code but didn't break it down to 
*//                the various VARTYPEs
*//******************************************************************************************  
   RETURN EMPTY(NVL(t_Value,''))
ENDFUNC

*//******************************************************************************************
FUNCTION CreatePrintLog (tcTitle AS Character ;
   ,tcReportForm AS Character ;
   ,tcReportOutput AS Character ;
   ,tcErrorMessage AS Character)
*//******************************************************************************************
*//  FUNCTION NAME: CreatePrintLog
*//
*//  AUTHOR: White Light Computing, Inc. 11/18/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Create a PrintError_datetime.log file which contains:
*//       - Report form Title
*//       - Report form
*//       - User Id
*//       - Report Output: PDF, passed in printer, etc.
*//       - Windows default printer
*//       - Error message
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tcTitle        - Report Title
*//       tcReportForm   - Report Name (e.i. LaserChk.frx)
*//       tcReportOutput - 'PDF', 'PREVIEW', etc.
*//       tcErrorMessage - Error Message
*//
*//    OUTPUT PARAMETERS: 
*//       NONE - Does create a PrintError_datetime.log file   
*//******************************************************************************************
*//  MODIFICATIONS:
*//     11/18/2014 - JLM - Created 
*//     12/03/2014 - JLM - Changed so that only 1 PrintError_yyyymmdd.log file is created 
*//                        per day.
*//******************************************************************************************  
   LOCAL ;
       ldDate AS Date ;
      ,ltDateTime AS Datetime ;
      ,lcOutFile AS Character ;
      ,lnFlag AS Integer ;
      ,lnSuccess AS Integer  
   
   m.ltDateTime = DATETIME()
   m.ldDate     = TTOD(m.ltDateTime)
   m.lcOutFile  = 'PrintError_' + DTOS(m.ldDate) + '.log'
   
   IF FILE(m.lcOutFile)
      *-- Append to the file
      m.lnFlag = 1  
   ELSE
      *-- Overwrite the file
      m.lnFlag = 0  
   ENDIF 
   
  *-- Create/append the file depending on the m.lnFlag  
  m.lnSuccess = STRTOFILE(REPLICATE('=',100) + CHR(13) + CHR(10) ;
            + TTOC(m.ltDateTime) + ':' + CHR(13) + CHR(10) ; 
            + 'UserId:................. ' + GetUserID() + CHR(13) + CHR(10) ;
            + 'Report Name:............ ' + m.tcReportForm + CHR(13) + CHR(10) ;
            + 'Report Title:........... ' + m.tcTitle + CHR(13) + CHR(10) ;
            + 'Output Passed:.......... ' + m.tcReportOutput + CHR(13) + CHR(10) ;
            + 'Windows Default Printer: ' + SET('Printer',2) + CHR(13) + CHR(10) ;
            + 'Error Message:.......... ' + m.tcErrorMessage + CHR(13) + CHR(10) + CHR(13) + CHR(10) ;
            ,m.lcOutFile, m.lnFlag)
 
   IF m.lnSuccess = 0  && 0 Bytes written to file. 
       *-- Attempt to Create the file depending on the m.lnFlag  
      m.lcOutFile  = 'PrintError_' + TTOC(m.ltDateTime,1) + '.log'

      STRTOFILE(REPLICATE('=',100) + CHR(13) + CHR(10) ;
            + TTOC(m.ltDateTime)  + ':' + CHR(13) + CHR(10) ; 
            + 'UserId:................. ' + GetUserID() + CHR(13) + CHR(10) ;
            + 'Report Name:............ ' + m.tcReportForm + CHR(13) + CHR(10) ;
            + 'Report Title:........... ' + m.tcTitle + CHR(13) + CHR(10) ;
            + 'Output Passed:.......... ' + m.tcReportOutput + CHR(13) + CHR(10) ;
            + 'Windows Default Printer: ' + SET('Printer',2) + CHR(13) + CHR(10) ;
            + 'Error Message:.......... ' + m.tcErrorMessage + CHR(13) + CHR(10) ;
            ,m.lcOutFile, 0)
   ELSE
      *-- Nothing at this time 
   ENDIF 
  
   RETURN          
ENDFUNC

*//******************************************************************************************
FUNCTION AddTimeStampToFileName(tcFileName)
*//******************************************************************************************
*//  FUNCTION NAME: AddTimeStampToFileName
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Returns a new filename with the datetime appended to the end of the filename ( i.e., becomes a new file extension )
*//    Ex: 'LostPolicy.xls' -> 'LostPolicy.xls.20150507152853
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tcFileName - Name of the file
*//
*//    OUTPUT PARAMETERS: 
*//       New file name with timestamp as part of the name.
*//******************************************************************************************
*//  MODIFICATIONS:
*//    05/07/2018 - SJE - Created
*//******************************************************************************************
   RETURN ALLTRIM(m.tcFileName) + '.' + TTOC(DATETIME(),1)
ENDFUNC

*//******************************************************************************************
FUNCTION AddTimeStampToFileStem(tcFileName, tcPrependString)
*//******************************************************************************************
*//  FUNCTION NAME: AddTimeStampToFileStem
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Returns a new filename with the datetime included as part of the file stem ( part prior to file extension ).
*//    Preserves any path information as part of the input file.
*//    Ex: 'LostPolicy.xls' -> 'LostPolicy_20150507152853.xls'
*//        'C\Temp\LostPolicy.xls' -> 'C:\Temp\LostPolicy_20150507152853.xls'
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//      tcFileName      - Name of the file
*//      tcPrependString - (Optional) String to prepend to the file stamp
*//
*//    OUTPUT PARAMETERS: 
*//       New file name with timestamp as part of the name.
*//******************************************************************************************
*//  MODIFICATIONS:
*//    05/07/2018 - SJE - Created
*//******************************************************************************************
   LOCAL lcPath AS Character ;
        ,lcFile AS Character ;
        ,lcPrepend AS Character
        
   lcPrepend = EVL(m.tcPrependString,"")
   lcPath    = JUSTPATH(m.tcFileName)
   lcFile    = JUSTSTEM(m.tcFileName) + '_' + m.lcPrepend + TTOC(DATETIME(),1) + '.' + JUSTEXT(m.tcFileName)
   RETURN IIF(EMPTY(ALLTRIM(m.lcPath)),'',ADDBS(m.lcPath)) + m.lcFile

ENDFUNC

*//******************************************************************************************
FUNCTION CreateDirIfMissing(tcDir)
*//******************************************************************************************
*//  FUNCTION NAME: CreateDirIfMissing
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Checks if the passed directory exists. If it does not, it attempts to create it.
*//      It can handle multiple sub directories, it will attempt to create each one in order.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//      Directory Path to check & create
*//
*//    OUTPUT PARAMETERS: 
*//     Error Msg String - Empty if Directory Exists, Error Message if unable to create.
*//******************************************************************************************
*//  MODIFICATIONS:
*//    02/17/2018 - SJE - Created 
*//******************************************************************************************  
   LOCAL lcErrMsg AS Character ;
      ,laPaths[1] ;
      ,lnPaths AS Integer ;
      ,lcPath AS Character ;
      ,lcPathTest AS Character ;
      ,lnLoop AS Integer ;
      ,loEx AS Exception
        
    lcErrMsg = ""
    *-- Error if not valid
    IF !(VARTYPE(m.tcDir) == "C" AND !EMPTY(ALLTRIM(m.tcDir)))
       lcErrMsg = "CreateDirIfMissing() - tcDir is empty / invalid"
       RETURN m.lcErrMsg
    ENDIF
    *-- Done if it exists!
    IF DIRECTORY(m.tcDir,1)
       RETURN ""
    ENDIF
    TRY
       *-- Extract all paths based on slash
       lnPaths = ALINES(m.laPaths,m.tcDir,1,"\")
         lcPathTest = ""
         *-- Loop for each path, starting with the first one.
       FOR lnLoop = 1 TO m.lnPaths
          lcPath = m.laPaths[m.lnLoop]
          *-- Build up the directory as we go..
         lcPathTest = m.lcPathTest + ADDBS(m.lcPath)
         *-- Test it, and create it if missing.
         IF !DIRECTORY(m.lcPathTest,1)
            MKDIR (m.lcPathTest)
         ENDIF
       ENDFOR
    CATCH TO loEx
       m.lcErrMsg = "Could not create directory: " + m.tcDir + "."+CHR(13)+CHR(10)+"Reason: " + loEx.Message
    ENDTRY

   RETURN m.lcErrMsg
ENDFUNC

*//******************************************************************************************
FUNCTION CopyFileWin32(tcSrcFile, tcDstFile, tlCopyIfOpen, tlOverWrite)
*//******************************************************************************************
*//  FUNCTION NAME: CopyFileWin32
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Copies source file to Destination file using Win32API Calls ( instead of VFP COPY FILE TO )
*//      Returns any error message strings on failure, or empty on success.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//      tcSrcFile     - Source file name ( full path )
*//      tcDstFileFile - Destination file name ( full path )
*//      tlCopyIfOpen  - If .T. copy will be made even if the source file is open.
*//      tlOverWrite   - If .T. desintation will overwrite the original
*//
*//    OUTPUT PARAMETERS: 
*//      Error Msg String - Empty if copy succeeds, Message if it Fails.
*//******************************************************************************************
*//  MODIFICATIONS:
*//    02/17/2018 - SJE - Created 
*//******************************************************************************************  
   LOCAL lcErrMsg AS Character ;
      ,lnOverWrite AS Integer ;
      ,lnVal AS Integer ;
      ,lnFH AS Integer ;
      ,loEx AS Exception
      
   lcErrMsg = SPACE(0)

   *-- Special check to see if the file is open, since Win32API Copy will work even if file is open.
   *-- User may not want this!
   IF NOT m.tlCopyIfOpen
      TRY
         lnFH = FOPEN(m.tcSrcFile,1)      && Open for writing ( returns -1 on failure )
         IF m.lnFH >= 0
            FCLOSE(m.lnFH)
         ELSE
            m.lcErrMsg = "Cannot copy file! Source file is in use."
         ENDIF
      CATCH TO loEx
         m.lcErrMsg = "Cannot copy file! Source file is in use. Details: " + loEx.Message
      ENDTRY
      IF !EMPTY(m.lcErrMsg)
         RETURN m.lcErrMsg
      ENDIF
   ENDIF
   *-- Now copy it.
   TRY
      DECLARE INTEGER CopyFile IN kernel32;
               STRING  lpExistingFileName,;
               STRING  lpNewFileName,;
                INTEGER bFailIfExists 
      *-- Convert from VFP logical to proper value for the function. 0 = Never Fail, 1 = Fail if Exists             
      lnOverWrite = IIF(m.tlOverWrite,0,1)     
      *-- Copy it      
      m.lnVal = CopyFile(m.tcSrcFile, m.tcDstFile, m.lnOverWrite)      
      *-- Record Failure
      IF m.lnVal == 0
         lcErrMsg = GetWindowsSystemErrorMsg()
      ENDIF
   CATCH TO loEx
      m.lcErrMsg = loEx.Message
   ENDTRY        
   RETURN m.lcErrMsg
ENDFUNC

*//******************************************************************************************
FUNCTION GetWindowsSystemErrorMsg()
*//******************************************************************************************
*//  FUNCTION NAME: GetWindowsSystemErrorMsg
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Returns a string of the last Windows System Error Message posted or empty if no error.
*//      The most recent error returned is based on using Win32API commands, so it only makes
*//      sense to call this after a Win32API command fails.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//      None
*//
*//    OUTPUT PARAMETERS: 
*//     Error Msg String
*//******************************************************************************************
*//  MODIFICATIONS:
*//    02/17/2018 - SJE - Created
*//******************************************************************************************  
   LOCAL lnErrorCode AS Integer ;
       ,lcErrMsg AS Character ;
       ,lcErrBuffer AS Character ;
       ,lnNewErr AS Integer ;
       ,lnFlag AS Integer

   *-- Use WinAPI call to get last system error #
   DECLARE INTEGER GetLastError IN kernel32 AS GetLastErrorWin32API
   
   *-- Retrieve the most recent error
   lnErrorCode= GetLastErrorWin32API()
   
   *-- Declare FormatMessage() Win32 API command
   #DEFINE FORMAT_MESSAGE_FROM_SYSTEM 0x1000
   
   DECLARE LONG FormatMessage IN kernel32 AS FormatMessageWin32 ;
               LONG dwFlags, LONG lpSource, LONG dwMessageId, ;
               LONG dwLanguageId, STRING @lpBuffer, ;
               LONG nSize, LONG Arguments
   *-- Set up our vars
   lnFlag = FORMAT_MESSAGE_FROM_SYSTEM
   lcErrBuffer = REPL(CHR(0),1000)
   *-- Use Win32 API to get the message
   lnNewErr = FormatMessageWin32(m.lnFlag, 0, m.lnErrorCode, 0, @m.lcErrBuffer,500,0)
   lcErrMsg = LEFT(m.lcErrBuffer, AT(CHR(0),m.lcErrBuffer)-1)
   RETURN m.lcErrMsg    
ENDFUNC  

*//******************************************************************************************
FUNCTION GetProgressString(tnRecord, tnTotal, tnPlaces)
*//******************************************************************************************
*//  FUNCTION NAME: GetProgressString
*//
*//  AUTHOR: White Light Computing, Inc. 10/04/2018
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
*//     10/04/2018 - JLM - Created 
*//******************************************************************************************  
   LOCAL lcRec AS Character ;
       ,lcTot AS Character ;
       ,lcRet AS Character
    lcRec = ALLTRIM(TRANSFORM(m.tnRecord,'@R 9,999,999,999'))
    lcTot = ALLTRIM(TRANSFORM(m.tnTotal,'@R 9,999,999,999'))
    lcRet = ALLTRIM(TRANSFORM(ROUND( (m.tnRecord / m.tnTotal)*100, m.tnPlaces)))
    *-- Add zero
    IF AT(".",m.lcRet) < 1
       lcRet = m.lcRet + "." + REPLICATE("0",m.tnPlaces)
    ENDIF
    *-- Add the rest
    lcRet = m.lcRec + " of " + m.lcTot + " (" + m.lcRet + "%)"
    RETURN m.lcRet
ENDFUNC  

*//******************************************************************************************
FUNCTION ErrorMsgBox(tcTitle, tcErrorMsg, tcCaption, tcAction)
*//******************************************************************************************
*//  FUNCTION NAME: ErrorMsgBox
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Common routine to display an error message box to the user.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//      tcTitle    - Title / Line 1 of the error message   
*//      tcErrorMsg - Error Message / Line 2 of the error message
*//      tcCaption  - (Optional) Caption to display - defaults to "An error occurred!"
*//      tcAction   - (Optional) Action Description - defaults to "Please contact the helpdesk with this error message."
*//
*//    OUTPUT PARAMETERS: 
*//     None
*//******************************************************************************************
*//  MODIFICATIONS:
*//    03/24/2018 - SJE - Created 
*//******************************************************************************************
   LOCAL lcAction AS Character ;
        ,lcCaption AS Character ;
        ,lcMsg AS Character
   m.lcAction = EVL(m.tcAction,"Please contact the helpdesk with this error message.")
   m.lcCaption = EVL(m.tcCaption,"An error occurred!")
   m.lcMsg = m.tcTitle + CHR(13) + CHR(13) + ;
           m.lcAction + CHR(13) + CHR(13) + ;
           m.tcErrorMsg
   MESSAGEBOX(m.lcMsg, 64, m.lcCaption)
ENDFUNC

*//******************************************************************************************
FUNCTION IsDebugMode()
*//******************************************************************************************
*//  FUNCTION NAME: IsDebugMode  
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//     Is the application running in Debug Mode
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None
*//
*//    OUTPUT PARAMETERS: 
*//       .T. - Debug Mode is active
*//******************************************************************************************
*//  MODIFICATIONS:
*//    01/07/2018 - SJE - Created 
*//******************************************************************************************  
   RETURN FILE("debug.txt")
ENDFUNC   

*//******************************************************************************************
FUNCTION QuitApp()
*//******************************************************************************************
*//  FUNCTION NAME:    
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//     Handles a request to quit the application
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None
*//
*//    OUTPUT PARAMETERS: 
*//       None
*//******************************************************************************************
*//  MODIFICATIONS:
*//    01/07/2018 - SJE - Created 
*//******************************************************************************************  
   IF MESSAGEBOX('Quit the Application?',32+4+256,'Please confirm') = 6
      QUIT
   ENDIF
ENDFUNC 

*//******************************************************************************************
FUNCTION IsWLCAdmin()
*//******************************************************************************************
*//  FUNCTION NAME: IsWLCAdmin
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//     Checks to see if the current user is an 'admin'
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None
*//
*//    OUTPUT PARAMETERS: 
*//       .T. - Admin user
*//******************************************************************************************
*//  MODIFICATIONS:
*//    10/29/2014 - JLM - Created 
*//****************************************************************************************** 
   RETURN INLIST(UPPER(GetUserID()), 'ADMIN','WLC') && OR _vfp.StartMode = 0

ENDFUNC

*//******************************************************************************************
FUNCTION GetAppDataFolderForComputer()
*//******************************************************************************************
*//  FUNCTION NAME: GetAppDataFolderForComputer
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//     Returns the path where computer specific ( not user specific ) data will be stored for 
*//     this application.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None
*//
*//    OUTPUT PARAMETERS: 
*//       None
*//******************************************************************************************
*//  MODIFICATIONS:
*//    04/24/2018 - SJE - Created 
*//******************************************************************************************     
   LOCAL lcPath
   lcPath = SpecialFolders('CommonAppData')
   RETURN ADDBS(m.lcPath) + 'WhiteLightComputing\WLCFramework\Data'
ENDFUNC   

*//******************************************************************************************
FUNCTION GetAppDataFolderForUser()
*//******************************************************************************************
*//  FUNCTION NAME: GetAppDataFolderForUser
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//     Returns the path where user specific data will be stored for this application. If it
*//     doesn't exist, the function will created the expected folders.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None
*//
*//    OUTPUT PARAMETERS: 
*//       None
*//******************************************************************************************
*//  MODIFICATIONS:
*//    04/26/2017 - SJE/JLM - Created 
*//******************************************************************************************     
   LOCAL lcPath
   lcPath = ADDBS(SpecialFolders('LocalAppData'))
   
   IF NOT DIRECTORY(m.lcPath + 'WhiteLightComputing')
      MD '&lcPath.WhiteLightComputing'
   ENDIF
   IF NOT DIRECTORY(m.lcPath + 'WhiteLightComputing\WLCFramework')
      MD '&lcPath.WhiteLightComputing\WLCFramework'
   ENDIF 
   IF NOT DIRECTORY(m.lcPath + 'WhiteLightComputing\WLCFramework\Data')
      MD '&lcPath.WhiteLightComputing\WLCFramework\Data'
   ENDIF 
      
   RETURN m.lcPath + 'WhiteLightComputing\WLCFramework\Data'
ENDFUNC  

*//******************************************************************************************
FUNCTION GetSchemaManagerScriptInSpecialFolder()
*//******************************************************************************************
*//  FUNCTION NAME: GetSchemaManagerScriptInSpecialFolder
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//     Returns the path where user specific data will be stored for this application.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None
*//
*//    OUTPUT PARAMETERS: 
*//       None
*//******************************************************************************************
*//  MODIFICATIONS:
*//    04/24/2018 - SJE - Created 
*//******************************************************************************************     
   LOCAL lcPath
   lcPath = SpecialFolders('CommonAppData')
   RETURN ADDBS(m.lcPath) + 'WhiteLightComputing\WLCFramework\SQLUpdates'
ENDFUNC 

*//******************************************************************************************
FUNCTION GetSchemaManagerScriptInApplicationFolder()
*//******************************************************************************************
*//  FUNCTION NAME: GetSchemaManagerScriptInApplicationFolder
*//
*//  AUTHOR: White Light Computing, Inc. 11/01/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//     The SQLUpdates is a subfolder of the main application folder.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None
*//
*//    OUTPUT PARAMETERS: 
*//       None
*//******************************************************************************************
*//  MODIFICATIONS:
*//    11/01/2018 - JLM - Created 
*//******************************************************************************************     
   RETURN ADDBS('SQLUpdates')
ENDFUNC 

*//******************************************************************************************
FUNCTION GetAppConfigSetting(tcConfigSettingName)
*//******************************************************************************************
*//  FUNCTION NAME: GetAppConfigSetting
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Returns the value of an application setting read from the Global Config object.
*//    Using this wrapper function requires less coding and also ensures the object reference
*//    to the global config object is always released.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tcConfigSettingName      - Name of the config setting to retrieve the value for.
*//
*//    OUTPUT PARAMETERS: 
*//       tcValue                  - Character string value of the config object.
*//******************************************************************************************
*//  MODIFICATIONS:
*//    11/20/2017 - SJE - Created
*//******************************************************************************************

   *-- Get Global Config Obj
   LOCAL loConfig AS Object;
        ,lcValue AS Character
   loConfig = GetGlobalConfigObj()
   lcValue = loConfig.GetConfigProperty(m.tcConfigSettingName)
   STORE NULL TO m.loConfig
   RETURN m.lcValue
ENDFUNC
*-- EOF - Utility.prg ------------------------------------------------------------------------
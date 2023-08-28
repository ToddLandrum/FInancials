******************************************************************************************
*  PROGRAM: SQLUtility
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
*     Collection of functions anything SQL Utility related
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
*     None
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
* 02/19/2018  Various
* ----------------------------------------------------------------------------------------
*
******************************************************************************************  
*//******************************************************************************************
FUNCTION GetSQLConnectionObj()
*//******************************************************************************************
*//  FUNCTION NAME: GetSQLConnectionObj
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
*//    Creates the global SQL Connection Manager instance if not created, and returns the reference to it.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//      None
*//
*//    OUTPUT PARAMETERS: 
*//     Object reference to SQL Connection Manager Obj global instance
*//******************************************************************************************
*//  MODIFICATIONS:
*//    02/23/2018 - SJE - Created 
*//******************************************************************************************  
   IF !PEMSTATUS(_VFP,'oSQLConnMgr',5)
      ADDPROPERTY(_VFP,'oSQLConnMgr',NULL)
   ENDIF
   IF ISNULL(_VFP.oSQLConnMgr)
      _VFP.oSQLConnMgr = CREATEOBJ('SQLConnMgr')
   ENDIF
   RETURN _VFP.oSQLConnMgr
ENDFUNC

*//******************************************************************************************
FUNCTION GetSQLLogger()
*//******************************************************************************************
*//  FUNCTION NAME: GetSQLLogger
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
*//    Creates the global SQL Logger instance if not created, and returns the reference to it.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//      None
*//
*//    OUTPUT PARAMETERS: 
*//     Object reference to SQL Logger global instance
*//******************************************************************************************
*//  MODIFICATIONS:
*//    02/11/2018 - SJE - Created 
*//******************************************************************************************  
   IF !PEMSTATUS(_VFP,'oSQLLogger',5)
      ADDPROPERTY(_VFP,'oSQLLogger',NULL)
   ENDIF
   IF ISNULL(_VFP.oSQLLogger)
      _VFP.oSQLLogger = CreateFactory('SQLLogger')
   ENDIF
   RETURN _VFP.oSQLLogger
ENDFUNC

*//******************************************************************************************
FUNCTION SQLObjConnect(toObj AS Object, tuParam1 AS Character)
*//******************************************************************************************
*//  FUNCTION NAME: SQLObjConnect    
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
*//    Takes the passed sql obj and set's an appropriate connection string & attempts to connect.
*//      An error is displayed on failure.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//      toObj       - Object reference to a biz object.
*//      tuParam1    - (Optional) Connection string to use ( overrides the default ) OR SQL Handle to use.
*//
*//    OUTPUT PARAMETERS: 
*//     None
*//******************************************************************************************
*//  MODIFICATIONS:
*//    02/03/2018 - SJE - Created 
*//******************************************************************************************  
   LOCAL loObj AS Object ;
      ,loConfig AS Object ;
      ,lcConnStr AS Character

   loObj = m.toObj

   * Object has invalid sql handle, populate connection string for it.   
   IF loObj.nSQLHandle < 1
      * Get Global Config Obj
      loConfig = GetGlobalConfigObj()
      IF TYPE('m.loConfig') == 'O'
         * Retrieve connection string & set it on the object
         lcConnStr = loConfig.GetConnectString()
         loObj.cConnectString = m.lcConnStr 
      ELSE
         ERROR 'Failed to load Global Configuration Object in SQLObjConnect()!'
         RETURN .F.
      ENDIF
      loConfig = NULL
   ENDIF                 
    
   * PCM - 10/11/2005 - Added parameter that will let us override the connection
   IF VARTYPE(tuParam1) = 'C'
      loObj.cConnectString = tuParam1
   ENDIF
     
   IF VARTYPE(tuParam1) = 'N'
      loObj.nSQLHandle = tuParam1
      loObj.lReleaseSQLHandle = .F.
   ELSE
      IF !EMPTY(loObj.cConnectString)
         loObj.Connect(loObj.cConnectString)
      ENDIF
   ENDIF
    
   * PCM - 4/15/2005 - Added check for second parameter to display dialog if there is an error connecting
   IF loObj.lError &&VARTYPE(tuParam1) = 'L' AND tuParam1 AND loObj.lError
      ErrorMsgBox('There was an error while connecting to SQL Server.', 'Error: ' + loObj.cErrorMsg, 'Error Connecting to Database')
   ENDIF

   * PCM - 10/11/2005 - Don't set the app role if a connection string was passed in.
   *IF !loObj.lError AND VARTYPE(tuParam1) <> 'C'
      *   loObj.SetApplicationRole()
   *ENDIF
   *ENDIF
   loObj = NULL
ENDFUNC

*//******************************************************************************************
FUNCTION RetrieveSQLConnectionString()
*//******************************************************************************************
*//  FUNCTION NAME: RetrieveSQLConnectionString
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
*//     Retrieves the SQL Connection string. On failure, launches the SQL Configuration Screen ( Modal )
*//     Function only returns if a valid string is entered, or the user chooses to abort via Messagebox.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None
*//
*//    OUTPUT PARAMETERS: 
*//       SQL Connection String, or '-1' on error.
*//******************************************************************************************
*//  MODIFICATIONS:
*//    04/30/2018 - SJE - Created 
*//******************************************************************************************    
   LOCAL ;
       lcSQLConnStr AS Character ;
      ,loSQLConn AS Object ;
      ,llQuit AS Logical ;
      ,llShownScreen AS Logical ;
      ,lcErrMsg AS Character

   *-- Create SQL Connection Manager
   loSQLConn = GetSQLConnectionObj()
   IF NOT (VARTYPE(m.loSQLConn) = 'O' AND NOT ISNULL(m.loSQLConn))
       ErrorMsgBox('SQL Configuration Error.', 'Failed to create SQL Connection Manager.', 'Cannot connect to the SQL Server Database.')
      RETURN '-1'
   ENDIF
   
   *-- Keep trying until success or user quits
   DO WHILE NOT m.llQuit
      *-- Grab sql connect string
      lcSQLConnStr = GetSQLConnectionString()
      
      *-- Empty is fatal
      IF EMPTY(m.lcSQLConnStr)
         ErrorMsgBox('SQL Configuration Error.', 'SQL Connection String is Empty - Fatal Error!', 'Cannot connect to the Database')
         lcSQLConnStr = '-1'
         llQuit = .T.
      ENDIF
      
      *-- A fatal error occurred for getting sql connection string, but the message was already displayed to user, so just abort now.
      IF m.lcSQLConnStr == '-1'
         llQuit = .T.
      *-- We got a non fatal error, i.e., invalid / missing configuration string.         
      ELSE
         IF m.lcSQLConnStr == '-2'
            *-- Show config screen if we haven't shown it yet!
            IF !m.llShownScreen 
               ShowSQLConfig()
               m.llShownScreen = .T.
            *-- Shown it already..
            ELSE
               *-- Still invalid, ask user!
               IF MESSAGEBOX('The SQL Configuration is still invalid!'+CHR(13)+'Would you like to try to set it up again?',4+32,'Please confirm') = 7
                  lcSQLConnStr = '-1'
                  llQuit = .T.
               ELSE
                  m.llShownScreen = .F.
               ENDIF
            ENDIF
         *-- Got a good one! NOW TEST IT!
         ELSE
            lcErrMsg = loSQLConn.TestSqlConn(m.lcSQLConnStr)
            IF EMPTY(m.lcErrMsg)
               llQuit = .T.
            ELSE
               lcErrMsg = 'Failed to connect to SQL Server!'+CHR(13)+ m.lcErrMsg + CHR(13)+CHR(13)+;
                        'Would you like to change the configuration settings?'
               IF MESSAGEBOX(m.lcErrMsg,4+32,'Please confirm') = 6
                  ShowSQLConfig()
                  llQuit = .F.
               ELSE
                  llQuit = .T.
                  lcSQLConnStr = '-1'
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   ENDDO

   *-- Cleanup 
   STORE NULL TO m.loSQLConn
   *--  Return value
   RETURN m.lcSQLConnStr
ENDFUNC

*//******************************************************************************************
FUNCTION ShowSQLConfig(tlForceAbortOnSave)
*//******************************************************************************************
*//  FUNCTION NAME: ShowSQLConfig
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
*//     Launches the SQL Configuration Screen ( Modal )
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tlForceAbortOnSave - (optional)Force an abort on Save
*//
*//    OUTPUT PARAMETERS: 
*//       None
*//******************************************************************************************
*//  MODIFICATIONS:
*//    04/30/2018 - SJE - Created 
*//******************************************************************************************     
   LOCAL loSQLConn AS Object ;
          ,llSaved AS Logical 
   * Creat SQL Connection Manager
   loSQLConn = GetSQLConnectionObj()
   IF !(VARTYPE(m.loSQLConn)='O' AND !ISNULL(m.loSQLConn))
       ErrorMsgBox('SQL Configuration Error.', 'Failed to create SQL Connection Manager', 'Cannot connect to the Database')
      RETURN '-1'
   ENDIF
   * Display the form ( Form is Modal )
   llSaved = loSQLConn.ShowSqlConn()
   * Clean up
   STORE .NULL. TO m.loSQLConn
   * Do we need to abort?
   IF m.llSaved AND m.tlForceAbortOnSave
      MESSAGEBOX('The application will now close for new settings to take effect. ' + ;
               'Please rerun the application once it closes.',48,'Notice!')
      AbortApp()
   ENDIF
ENDFUNC 

*//******************************************************************************************
FUNCTION GetSQLConnectionString()
*//******************************************************************************************
*//  FUNCTION NAME: GetSQLConnectionString
*//
*//  COPYRIGHT © 2010-2018   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//     Retrieve the SQL Connection string to use for connecting to the appropriate database.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       nONE
*//
*//    OUTPUT PARAMETERS: 
*//       Valid connection string, or "-1" on unrecoverable error, "-2" on invalid string error.
*//******************************************************************************************
*//  MODIFICATIONS:
*//    02/23/2018 - SJE - Created 
*//****************************************************************************************** 
   LOCAL lcStr AS Character ;
       ,lcKey AS Character ;
       ,loSQLConn AS Object ;
       ,loConfig AS Object ;
       ,lcErrMsg AS Character

   loConfig = NULL
   * Set the security key
   *lcKey = GetAppSecurityKey()

   * Creat SQL Connection Manager & Get Config Obj
   loSQLConn = GetSQLConnectionObj()
   IF !(VARTYPE(m.loSQLConn)="O" AND !ISNULL(m.loSQLConn))
       ErrorMsgBox("SQL Configuration Error", "Failed to create SQL Connection Manager", "Cannot connect to the Database")
      RETURN "-1"
   ENDIF
   loSQLConn.GetConfigObj(@loConfig)
   
   * Set up configuration   
   loConfig.cFileNameProd = "prod.conn"   
   loConfig.cFileNameTest = "test.conn"   
   loConfig.cSecurityKey  = m.lcKey  
   loConfig.lUseTestDB    = IsDebugMode()
   * Set it 
   loSQLConn.SetConfig(@loConfig)
   
   * Get the unencrypted sql connection string
   lcStr = loSQLConn.GetSQLConnectionString()
   
   * Uncomment to write unencrypted string to connection file
   *IF IsDebugMode()
   *   loSQLConn._WriteSQLConnectionStringToFile(m.lcStr)
   *ENDIF

   * Validate it & display validation error if necessary.
   IF !EMPTY(ALLTRIM(m.lcStr))
      lcErrMsg = loSQLConn.ValidateConnectionString(m.lcStr)
      IF !EMPTY(m.lcErrMsg)
         ErrorMsgBox("SQL Configuration Error", "Connection String is not valid: " + m.lcErrMsg)
         m.lcStr = "-2"   && Force non fatal failure to ensure user can't get into the application w/invalid conn string.
      ENDIF
   ELSE
      ** No connection string retrieved
      IF loSQLConn.lFatalError
         m.lcStr = "-1"   && Force fatal failure
      ELSE
         m.lcStr = "-2"   && Force non fatal failure
      ENDIF
   ENDIF

   * Cleanup 
   STORE NULL TO m.loSQLConn, m.loConfig
   * Return value
   RETURN m.lcStr
ENDFUNC

*-- EOF - SQLUtility.prg ------------------------------------------------------------------------


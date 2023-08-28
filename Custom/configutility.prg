******************************************************************************************
*  PROGRAM: ConfigUtility
*
*  AUTHOR: White Light Computing, Inc.
*
*  COPYRIGHT © 2010-2020   All Rights Reserved.
*     White Light Computing, Inc.
*     PO Box 391
*     Washington Twp., MI  48094
*     raschummer@whitelightcomputing.com
*
*  PROGRAM DESCRIPTION:
*     Collection of functions anything Config Utility related
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
FUNCTION GetGlobalConfigObj()
*//******************************************************************************************
*//  FUNCTION NAME: GetGlobalConfigObj
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2020   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Creates the global Configuration instance if not created, and returns the reference to it.
*//
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//      None
*//
*//    OUTPUT PARAMETERS: 
*//     Object reference to Config Obj global instance
*//******************************************************************************************
*//  MODIFICATIONS:
*//    02/23/2018 - SJE - Created 
*//******************************************************************************************  
   IF !PEMSTATUS(_VFP,'oConfig',5)
      ADDPROPERTY(_VFP,'oConfig',NULL)
   ENDIF
   IF ISNULL(_VFP.oConfig)
      _VFP.oConfig = CREATEOBJ('ConfigObj')
   ENDIF
   RETURN _VFP.oConfig
ENDFUNC

*//******************************************************************************************
FUNCTION CreateGlobalConfigObject(tlEmpty)
*//******************************************************************************************
*//  FUNCTION NAME: CreateGlobalConfigObject
*//
*//  AUTHOR: White Light Computing, Inc. 02/19/2018
*//
*//  COPYRIGHT © 2010-2020   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//    Creates the goConfig configuration object for a single record Config record set.
 
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       tlEmpty (Optional) - create an empty configuration object.
*//
*//    OUTPUT PARAMETERS: 
*//       Public variable goConfig
*//******************************************************************************************
*//  MODIFICATIONS:
*//     09/30/2010
*//******************************************************************************************  
   LOCAL loSQL
   
   IF m.tlEmpty
      PUBLIC goConfig
      goConfig = CREATEOBJECT('Empty')
      RETURN
   ENDIF

   PUBLIC goConfig
      
   loSQL = CreateFactory('wlcSQL')
   loSQL.Execute('SELECT * FROM Config', 'curConfig')
   SCATTER NAME goConfig MEMO ADDITIVE
   
   ADDPROPERTY(goConfig, 'lDebug', FILE('debug.txt'))
   
   USE IN SELECT('curConfig')         
ENDFUNC

*//******************************************************************************************
FUNCTION LoadConfigSettings(toConfig)
*//******************************************************************************************
*//  FUNCTION NAME: LoadConfigSettings
*//
*//  AUTHOR: White Light Computing, Inc. 02/17/2018
*//
*//  COPYRIGHT © 2010-2020   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//     Loads the configuration settings. On a fatal failure, launches the SQL Configuration Screen (Modal)
*//     Function only returns if successfully loaded, or the user chooses to abort via Messagebox.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       toConfig - Config object
*//
*//    OUTPUT PARAMETERS: 
*//       .T. on success, .F. on failure/abort
*//******************************************************************************************
*//  MODIFICATIONS:
*//    05/01/2018 - SJE - Created 
*//******************************************************************************************    
   LOCAL llQuit AS Logical ;
       ,llOK AS Logical ;
       ,llHadFailure AS Logical

   *-- Abort if invalid object
   IF !(VARTYPE(m.toConfig)="O" AND !ISNULL(m.toConfig))
       ErrorMsgBox("Configuration Settings Error.", "Failed to load application configuration settings - config object is blank.")   
      RETURN .F.
   ENDIF
   
   *-- Keep trying until success or user quits
   DO WHILE !m.llQuit
      *-- Try to load settings
      IF toConfig.LoadSettings()
         *-- Success
         m.llOK = .T.
         m.llQuit = .T.
         *-- If we had a prior failure, must abort, since any existing biz objs will have wrong connection info.
         IF llHadFailure 
            MESSAGEBOX("Loading application settings succeeded." + CHR(13)+ ;
                     "The application will now close for new settings to take effect. " + ;
                     "Please rerun the application once it closes.",48,"Notice!")
            m.llOK = .F.
         ENDIF
      ELSE
         llHadFailure = .T.
         * Load Failure? Have user modify connection data
         IF toConfig.lLoadFailure
            IF MESSAGEBOX("Loading application settings failed. Would you like to test and/or modify your SQL Server Configuration?",4+32,"Please confirm") = 6
               ShowSQLConfig()
            ELSE
               * Abort/Failure
               m.llOK = .F.   
               m.llQuit = .T.
            ENDIF         
         ELSE
            * Failure
            m.llOK = .F.   
            m.llQuit = .T.
         ENDIF
      ENDIF      
   ENDDO
   RETURN m.llOK
ENDFUNC



*//******************************************************************************************
FUNCTION AbortApp()
*//******************************************************************************************
*//  FUNCTION NAME: AbortApp
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
*//     Clean up and abort the application.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None   
*//
*//    OUTPUT PARAMETERS: 
*//       None   
*//******************************************************************************************
*//  MODIFICATIONS:
*//     03/23/2018 - SJE - Created 
*//******************************************************************************************     
   *-- Not doing this seemed to prevent VFP from exiting.
   IF PEMSTATUS(_VFP,'oConfig',5)
         _VFP.oConfig = NULL
      REMOVEPROPERTY(_VFP,'oConfig')
   ENDIF
   IF PEMSTATUS(_VFP,'oSQLConnMgr',5)
         _VFP.oSQLConnMgr = NULL
      REMOVEPROPERTY(_VFP,'oSQLConnMgr')
   ENDIF
   IF PEMSTATUS(_VFP,'oSQLLogger',5)
         _VFP.oSQLLogger = NULL
      REMOVEPROPERTY(_VFP,'oSQLLogger')
   ENDIF  
   IF PEMSTATUS(_VFP,'oSecurityMgr',5)
         _VFP.oSecurityMgr= NULL
      REMOVEPROPERTY(_VFP,'oSecurityMgr')
   ENDIF     
   SET SYSMENU TO DEFAULT
   
   CANCEL
ENDFUNC   

*//******************************************************************************************
FUNCTION ExitApp()
*//******************************************************************************************
*//  FUNCTION NAME: ExitApp
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
*//     Clean up and exit application.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None   
*//
*//    OUTPUT PARAMETERS: 
*//       None   
*//******************************************************************************************
*//  MODIFICATIONS:
*//     9/30/2010 - Paul Mrozowski - Created 
*//******************************************************************************************  
   LOCAL ;
       loForm ;
      ,lnIndex AS Integer ;
      ,lnTotFormCount AS Integer ;        
      ,loEx AS Exception 
         
   CLEAR EVENTS 
      
   lnTotFormCount =  _screen.FormCount  
   IF m.lnTotFormCount > 0
      FOR m.lnIndex = m.lnTotFormCount TO 1 STEP -1          
          TRY 
             loForm = _screen.Forms[lnIndex]
             loForm.Release()
          CATCH TO loEx
          ENDTRY    
      ENDFOR
   ENDIF
   
   QUIT
ENDFUNC

FUNCTION lpSetMemory
*//******************************************************************************************
*//  FUNCTION NAME: lpSetMemory
*//
*//  AUTHOR: White Light Computing, Inc. 05/16/2014
*//
*//  COPYRIGHT © 2010-2014   All Rights Reserved.
*//  White Light Computing, Inc.
*//  PO Box 391
*//  Washington Twp., MI  48094
*//  raschummer@whitelightcomputing.com
*//
*//  PROCEDURE DESCRIPTION: 
*//      Sets the foreground or background buffer memory size for VFP
*//      Discussion in FoxWiki http://fox.wikis.com/wc.dll?Wiki~sys3050~Wiki*// 
*//      
*//      Uses a file: VfpBufferMemory.txt. If it doesn't exist, creates it.
*// 
*//  PARAMETERS: 
*//    INPUT PARAMETERS: 
*//       None   
*//
*//    OUTPUT PARAMETERS: 
*//       If the VfpBufferMemory.txt file doesn't exist, creates it.
*//****************************************************************************************** 
   LOCAL ;
       lcVfpBufferMemoryFile AS Character ;
      ,llReturn AS Boolean ;
      ,lnLines AS Integer ;
      ,lnx AS Integer ;
      ,lcCmd AS Character ;
      ,lnMemoWidth AS Integer 
      
   m.llReturn    = .T.
   m.lnMemoWidth = SET('MemoWidth')
   
   IF m.lnMemoWidth < 8192
      SET MEMOWIDTH TO 8192
   ENDIF    

   IF FILE('VfpBufferMemory.txt')   
      m.lcVfpBufferMemoryFile = FILETOSTR('VfpBufferMemory.txt')
      m.lnLines = MEMLINES(ALLTRIM(m.lcVfpBufferMemoryFile))
      FOR m.lnx = 1 TO m.lnLines
         m.lcCmd = ALLTRIM(MLINE(m.lcVfpBufferMemoryFile, m.lnx))
         IF EMPTY(m.lcCmd) ;
         OR m.lcCmd = '*'
            LOOP 
         ELSE
            &lcCmd  && Run the code
         ENDIF   
      ENDFOR 
   ELSE
      *-- Set the the foreground and background memory size for VFP
      SYS(3050, 1, MIN(536870912, VAL(SYS(3050, 1, 0))))
      SYS(3050, 2, MIN(536870912, VAL(SYS(3050, 1, 0))))

      *-- Create the VfpBufferMemory.txt file
      TEXT TO m.lcVfpBufferMemoryFile TEXTMERGE NOSHOW FLAGS 3 PRETEXT 3
         * ------------------------------------------------------------------------
         * Name: VfpBufferMemory.txt
         * Sets the foreground or background buffer memory size for VFP
         * Discussion in FoxWiki http://fox.wikis.com/wc.dll?Wiki~sys3050~Wiki*//'
         * ------------------------------------------------------------------------
         SYS(3050, 1, MIN(536870912, VAL(SYS(3050, 1, 0))))
         SYS(3050, 2, MIN(536870912, VAL(SYS(3050, 1, 0))))   
         * eof       
      ENDTEXT
      
      m.llReturn = STRTOFILE(m.lcVfpBufferMemoryFile,'VfpBufferMemory.txt',0)
   ENDIF    

   IF m.lnMemoWidth <> 8192
      SET MEMOWIDTH TO lnMemoWidth
   ENDIF
         
   RETURN m.llReturn
   
ENDFUNC 

*-- EOF - Startup ---------------------------------------------------------------------
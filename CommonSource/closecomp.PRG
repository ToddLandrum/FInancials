*
*   Program:     CloseComp
*   Description: Closes the currently open company
*
LPARAMETERS tlNewComp, tlCalledFromMenu
LOCAL oRegistry
LOCAL lcVersion, llReturn, loError

*#INCLUDE ..\SOURCE\appdefs.h

TRY
   IF NOT tlNewComp
      m.gostatemanager.closeallforms()
   ENDIF

* Check for open forms. Don't allow switch of companies if a form is open.
   IF NOT tlNewComp AND swOpenForms()
      m.goapp.omessage.severe('All open forms must be closed before closing a company file.')
      llReturn = .F.
      EXIT 
   ENDIF

   lcVersion = m.goapp.cFileVersion
   oRegistry = FindGlobalObject('cmRegistry')

   IF tlCalledFromMenu
      TRY 
         ERASE (m.goapp.cCommonDocuments + '*.loc')
      CATCH
      ENDTRY    
   ENDIF    

   m.goapp.closealldata()

* Close the QB link
   IF m.goapp.lQBVersion AND m.goapp.oQB.lQBActive
      m.goapp.oQB.QBClose()
   ENDIF

   m.goapp.cDataFilePath = ''
   m.goapp.lOpenCompany  = .F.
   m.goapp.resetmenu()

   DO CASE
      CASE m.goapp.lAMVersion
         IF NOT m.goapp.lDemo
            _SCREEN.CAPTION = 'AM V' + lcVersion + ' - NO COMPANY OPEN'
         ELSE
            _SCREEN.CAPTION = 'DEMO of AM V' + lcVersion + ' - NO COMPANY OPEN'
         ENDIF
      CASE m.goapp.lQBVersion
         IF NOT m.goapp.lDemo
            _SCREEN.CAPTION = 'DMIE V' + lcVersion + ' - NO COMPANY OPEN'
         ELSE
            _SCREEN.CAPTION = 'DEMO of DMIE V' + lcVersion + ' - NO COMPANY OPEN'
         ENDIF
      OTHERWISE
         IF NOT m.goapp.lDemo
            _SCREEN.CAPTION = 'DM V' + lcVersion + ' - NO COMPANY OPEN'
         ELSE
            _SCREEN.CAPTION = 'DEMO of DM V' + lcVersion + ' - NO COMPANY OPEN'
         ENDIF
   ENDCASE
CATCH TO loError
   llReturn = .F.
   DO errorlog WITH 'CloseComp', loError.LINENO, 'Close Company', loError.ERRORNO, loError.MESSAGE
   MESSAGEBOX('Unable to process the request at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
        'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn



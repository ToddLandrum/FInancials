*
*   Program:     OpenComp
*   Description: Presents a picklist so the user can choose a company to open
*
LPARAMETERS tlOpenComp
LOCAL lcPath, oRegistry, lcList
LOCAL laFiles[1], lcidComp, llReturn, lnFile, loError
*:Global fh
PRIV llOK

llReturn = .T.

TRY
* Check for open forms. Don't allow switch of companies if a form is open.
   IF swOpenForms()
      MESSAGEBOX('All open forms must be closed before changing companies.', 16, 'Close All Forms')
      llReturn = .F.
      EXIT
   ENDIF

*  Build the parameter for the lookup list
   llOK   = .T.
   lcPath = .NULL.
   lcList = 'cProducer\Company Name,cdatapath\Data File Path'

   IF NOT USED('compmast')
      USE (m.goApp.cCommonFolder + 'compmast') IN 0
   ENDIF

   SET DELETED ON

* Bring up the picklist so the user can choose which company to open
*!*      DO FORM picklist WITH 'Compmast', lcList, 'cidcomp', 2, .T., .T., 'Open Company', 557

* Close the currently open company
*      IF m.goApp.lOpenCompany
         DO closecomp
*      ENDIF

   llOK = m.goapp.logon()

   IF llOK

*      m.goApp.opencompany1(.F.)

      IF NOT tlOpenComp AND NOT m.goApp.lNoCallOpenComp2
*         m.goApp.opencompany2()
      ENDIF
*      llReturn = m.goapp.logon()
   ELSE
      m.goApp.lNoCallOpenComp2 = .T.
      llReturn                 = .F.
   ENDIF
CATCH TO loError
   llReturn = .F.
   DO errorlog WITH 'OpenComp', loError.LINENO, 'OpenComp', loError.ERRORNO, loError.MESSAGE
   MESSAGEBOX('Unable to open the company at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
        'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
ENDTRY

RETURN llReturn


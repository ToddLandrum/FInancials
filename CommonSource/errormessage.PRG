LPARAMETERS tcMethod, tnLineNo, tcModule, tnErrorNo, tcMessage

IF m.goApp.lDebugMode AND VERSION(2) = 2
   IF MESSAGEBOX('Error Encountered!' + CHR(10) + CHR(10) + ;
           'Error No: ' + TRANSFORM(tnErrorNo) + CHR(10) + ;
           'Method: ' + tcMethod + CHR(10) + ;
           'Line No: ' + TRANSFORM(tnLineNo) + CHR(10) + ;
           'Message: ' + tcMessage + CHR(10) + CHR(10) + ;
           'Enter Debug Mode?', 36, 'Debug Error') = 6
      SET STEP ON
   ENDIF
ELSE
   IF tnErrorNo = 5
      MESSAGEBOX("Unable to complete the processing at this time." + CHR(10) + CHR(10) + ;
           "There appears to be a problem with this company's index files. " + ;
           "Try running the Re-Index File Utility found under the Utilities menu and then try again." + CHR(10) + CHR(10) + ;
           "Check the System Log found under Other Reports for more information." + ;
           "Contact SherWare Support for help at support@sherware.com.", 16, "Index Problem Encountered")
   ELSE
      MESSAGEBOX('Unable to complete the processing at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
           'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDIF
ENDIF
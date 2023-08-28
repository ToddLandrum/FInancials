LPARAMETERS tcDocument
LOCAL llReturn

llReturn = .F.

TRY
   DECLARE INTEGER ShellExecute IN "Shell32.dll" ;
      INTEGER HWND, ;
      STRING lpVerb, ;
      STRING lpFile, ;
      STRING lpParameters, ;
      STRING lpDirectory, ;
      LONG nShowCmd

   lnReturn = ShellExecute(0, "Open", tcDocument, "", "", 1)

   DO CASE
      CASE lnReturn > 32
         llReturn = .T.
      CASE lnReturn = 0
         MESSAGEBOX('The operating system is out of memory or resources.' + CHR(10) + CHR(10) + ;
              'Unable to open document:' + CHR(10) + ;
              ALLTRIM(tcDocument), 48, 'Document Viewer Problem')
         llReturn = .F.
      CASE lnReturn = 2
         MESSAGEBOX('The specified document was not found.' + CHR(10) + CHR(10) + ;
              'Unable to open document:' + CHR(10) + ;
              ALLTRIM(tcDocument), 48, 'Document Viewer Problem')
         llReturn = .F.
      CASE lnReturn = 3
         MESSAGEBOX('The specified path was not found.' + CHR(10) + CHR(10) + ;
              'Unable to open document:' + CHR(10) + ;
              ALLTRIM(tcDocument), 48, 'Document Viewer Problem')
         llReturn = .F.
      CASE lnReturn = 26
         MESSAGEBOX('A sharing violation occurred.' + CHR(10) + CHR(10) + ;
              'Unable to open document:' + CHR(10) + ;
              ALLTRIM(tcDocument), 48, 'Document Viewer Problem')
         llReturn = .F.
      CASE lnReturn = 27
         MESSAGEBOX('The filename association is incomplete or invalid.' + CHR(10) + CHR(10) + ;
              'Unable to open document:' + CHR(10) + ;
              ALLTRIM(tcDocument), 48, 'Document Viewer Problem')
         llReturn = .F.
      CASE lnReturn = 28 OR lnReturn = 29 OR lnReturn = 30
         MESSAGEBOX('Unable to start the application to view this document.' + CHR(10) + CHR(10) + ;
              'Unable to open document:' + CHR(10) + ;
              ALLTRIM(tcDocument), 48, 'Document Viewer Problem')
         llReturn = .F.
      CASE lnReturn = 31
         MESSAGEBOX("There is no application associated with the file type of the document you're trying to view." + CHR(10) + CHR(10) + ;
              'Unable to open document:' + CHR(10) + ;
              ALLTRIM(tcDocument), 48, 'Document Viewer Problem')
         llReturn = .F.
      OTHERWISE
         MESSAGEBOX('Return from ShellExecute: ' + TRANSFORM(lnReturn), 64, 'View Document')
         llReturn = .F.
   ENDCASE

CATCH TO loError
   MESSAGEBOX('An error occurred trying to view the document.' + CHR(10) + CHR(10) + ;
        'The error message is:' + CHR(10) + ;
        loError.MESSAGE, 48, 'Document Viewer Problem')
   llReturn = .F.
ENDTRY

RETURN (llReturn)
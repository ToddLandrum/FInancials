DEFINE CLASS swPDF AS CUSTOM


   NAME = "swPDF"

   licensedto     = 'SherWare, Inc.'
   activationcode = "07EFCDAB010001009A527EE5406E35317BA203A53DB56A91B1D1E1753FD5B4CD327A255177FD182603E825A1E06106900874BCC3DC95B6504CCF9D7F2433A7"
   oPDFPrinter    = .NULL.
   lPDFInit       = .T.
   cPrinter       = ""

   *************************
   PROCEDURE INIT
   *************************
   LOCAL llReturn
   
   llReturn = .t.
   
   TRY

      THIS.oPDFPrinter = CREATEOBJECT('cdintfex.cdintfex')
      THIS.oPDFPrinter.DriverInit('SWI PDF Printer')
      THIS.lPDFInit = .T.

   CATCH TO loError
      MESSAGEBOX('Unable to print to the SherWare PDF printer.',48,'PDF Printer Error')
      llReturn = .F.
   FINALLY

   ENDTRY

   RETURN (llReturn)
   
   ***********************
   PROCEDURE EnablePrinter
   ***********************
   LOCAL llReturn
   
   THIS.cPrinter = SET('printer',2)
   SET PRINTER TO NAME ('SWI PDF PRINTER')

   THIS.oPDFPrinter.FileNameOptions = 3

   TRY
      THIS.oPDFPrinter.EnablePrinter(THIS.licensedto,THIS.activationcode)
      llReturn = .T.
   CATCH TO loError 
      MESSAGEBOX('There is a problem with the SherWare PDF Printer driver. ' + CHR(10) + ;
         'Please try reinstalling the driver by running the INSTALL.EXE ' + CHR(10) + ;
         'application found in the PDF subfolder.',16,'PDF Printer Driver Problem')
      llReturn = .f.    
   ENDTRY
   
   RETURN (llReturn)

   ***************************
   PROCEDURE CleanUp
   ***************************
   LOCAL lcPrinter

   THIS.oPDFPrinter.FileNameOptions = 0

   lcPrinter = THIS.cPrinter
   SET PRINTER TO NAME (lcPrinter)

ENDDEFINE 

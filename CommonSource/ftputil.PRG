

loIP = CREATEOBJECT('wwftp')

loIP.FTPConnect(TRIM('www.sherware.com'),;
                TRIM('sherware'),;
                TRIM('ts060962') )

lcServerPath = 'public_html\backups\'
lcFile = ALLTRIM(m.goapp.cdatafilepath)+'.zip'
lnResult = loIP.FTPSendFile(TRIM(www.sherware.com),;
                           'backup\'+ALLTRIM(m.goapp.cdatafilepath)+'.zip',;
                           lcServerPath + lcFile,;
                           'sherware',;
                           'ts060962' )
IF lnResult # 0
   MessageBox(loIP.cErrorMsg,48,"FTP Upload Error")
ELSE
   THISFORM.cmdGetDirectory.Click()
   MessageBox("Upload Complete",48,"FTP Upload")   
ENDIF


  



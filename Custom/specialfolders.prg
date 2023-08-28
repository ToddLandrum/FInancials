*==============================================================================
* Program:                SpecialFolders.PRG
* Purpose:                Determine the path to the specified special folder
* Author:                Doug Hennig
* Last revision:        03/21/2007
* Parameters:            tuFolder - the folder to get the path for. Specify
*                            the CSIDL value of the desired folder (which can
*                            be obtained from:
* http://msdn.microsoft.com/library/en-us/shellcc/platform/shell/reference/enums/csidl.asp
*                            or use one of the following strings:
*                            "AppData": application-specific data
*                            "CommonAppData": application data for all users
*                            "Desktop": the user's Desktop
*                            "LocalAppData": data for local (nonroaming)
*                                applications
*                            "Personal": the My Documents folder
*                            "CommonDocuments": the documents folder for all users
*                            "ProgramFiles": Program Files
*                            "ProgramFiles86": x86 Program Files
* Returns:                The path for the specified folder or blank if the
*                            folder wasn't found
* Environment in:        None
* Environment out:        Error 11 occurs if tuFolder isn't specified
*                            properly
* Notes:                This code was adapted from:
* http://msdn.microsoft.com/library/en-us/shellcc/platform/shell/reference/objects/folderitem/path.asp
*                        Support for other CSIDLs can easily be added
*==============================================================================

LPARAMETERS tuFolder
LOCAL lnFolder, ;
   lcFolder, ;
   loShell, ;
   loFolder, ;
   loFolderItem, ;
   lcPath

* Define the CSIDLs for the different folders.

#DEFINE CSIDL_APPDATA            0x1A
*    Application-specific data:
*        XP:        C:\Documents and Settings\<username>\Application Data
*        Vista:    C:\Users\<username>\AppData\Roaming
#DEFINE CSIDL_COMMON_APPDATA    0x23
*    Application data for all users:
*        XP:        C:\Documents and Settings\All Users\Application Data
*        Vista:     C:\ProgramData
#DEFINE CSIDL_DESKTOPDIRECTORY    0x10
*    The user's Desktop:
*        XP:        C:\Documents and Settings\<username>\Desktop
*        Vista:    C:\Users\<username>\Desktop
#DEFINE CSIDL_LOCAL_APPDATA        0x1C
*    Data for local (nonroaming) applications:
*        XP:        C:\Documents and Settings\<username>\Local Settings\Application Data
*        Vista:    C:\Users\<username>\AppData\Local
#DEFINE CSIDL_PERSONAL            0x05
*    The My Documents folder:
*        XP:        C:\Documents and Settings\<username>\My Documents
*        Vista:    C:\Users\<username>\Documents
#DEFINE CSIDL_COMMON_DOCUMENTS    0x2E
*    The My Documents folder:
*        XP:        C:\Documents and Settings\All Users\Documents
*        Vista:    C:\Users\Public\Documents
#DEFINE CSIDL_PROGRAM_FILES       0x26
*    The Program Files folder:
#DEFINE CSIDL_PROGRAM_FILESX86    0x2A
*    The Program Files (X86) folder:

* Define some other constants.

#DEFINE ERR_ARGUMENT_INVALID    11

* Test the parameter.

DO CASE

      * If it's numeric, assume it's a valid CSIDL; if not, the API function will
      * return a blank string.

   CASE VARTYPE(tuFolder) = 'N'
      lnFolder = tuFolder

      * An invalid data type or empty folder name was passed.

   CASE VARTYPE(tuFolder) <> 'C' OR EMPTY(tuFolder)
      ERROR ERR_ARGUMENT_INVALID
      RETURN ''

      * If a string was passed, convert it to the appropriate CSIDL.

   OTHERWISE
      lcFolder = UPPER(tuFolder)
      DO CASE
         CASE lcFolder = 'APPDATA'
            lnFolder = CSIDL_APPDATA
         CASE lcFolder = 'COMMONAPPDATA'
            lnFolder = CSIDL_COMMON_APPDATA
         CASE lcFolder = 'DESKTOP'
            lnFolder = CSIDL_DESKTOPDIRECTORY
         CASE lcFolder = 'LOCALAPPDATA'
            lnFolder = CSIDL_LOCAL_APPDATA
         CASE lcFolder = 'PERSONAL'
            lnFolder = CSIDL_PERSONAL
         CASE lcFolder = 'COMMONDOCUMENTS'
            lnFolder = CSIDL_COMMON_DOCUMENTS
         CASE lcFolder = 'PROGRAMFILES'
            lnFolder = CSIDL_PROGRAM_FILES
         CASE lcFolder = 'PROGRAMFILES86'
            lnFolder = CSIDL_PROGRAM_FILESX86   
         OTHERWISE
            ERROR ERR_ARGUMENT_INVALID
            RETURN ''
      ENDCASE
ENDCASE

* Get the desired path using the Shell.

TRY
   loShell      = CREATEOBJECT('Shell.Application')
   loFolder     = loShell.Namespace(lnFolder)
   loFolderItem = loFolder.SELF
   lcPath       = ADDBS(loFolderItem.PATH)
CATCH
   lcPath = ''
ENDTRY
RETURN lcPath

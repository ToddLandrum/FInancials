**************************************************
*-- Class:        sfcommondialog (e:\sf\activex.vcx)
*-- ParentClass:  olecontrol
*-- BaseClass:    olecontrol
*-- Time Stamp:   01/13/97 10:45:02 PM
*-- OLEObject = C:\WINDOWS\SYSTEM\COMDLG32.OCX
*
#INCLUDE "e:\sf\commdlg.h"
*
DEFINE CLASS sfcommondialog AS olecontrol


    Height = 32
    Width = 32
    *-- .T. to display the Help button.
    lshowhelpbutton = .F.
    *-- .T. if the user cancelled the dialog.
    lcancelled = .F.
    Name = "sfcommondialog"


    *-- Sets the CommonDialog control's Flags property based on properties of this object,
    PROTECTED PROCEDURE setflags
        with This
            .CancelError = .T.
            .lCancelled  = .F.
        endwith
    ENDPROC


    PROCEDURE Error
        LPARAMETERS nError, cMethod, nLine
        local laError[1]
        aerror(laError)

        * The user chose cancel.

        if nError = cnVFP_ERR_OLE_ERROR and laError[3] = ccCOMMDLG_CANCEL_MSG
            This.lCancelled = .T.

        * Display a generic error message.

        else
            messagebox('Error #' + ltrim(str(nError)) + ' occurred in line ' + ;
                ltrim(str(nLine)) + ' of ' + cMethod, 0, _VFP.Caption)
        endif nError = cnVFP_ERR_OLE_ERROR ...
    ENDPROC


ENDDEFINE
*
*-- EndDefine: sfcommondialog
**************************************************


**************************************************
*-- Class:        sffiledialog (e:\sf\activex.vcx)
*-- ParentClass:  sfcommondialog (e:\sf\activex.vcx)
*-- BaseClass:    olecontrol
*-- Time Stamp:   01/13/97 10:41:10 PM
*-- OLEObject = C:\WINDOWS\SYSTEM\COMDLG32.OCX
*
#INCLUDE "e:\sf\commdlg.h"
*
DEFINE CLASS sffiledialog AS sfcommondialog


    Height = 32
    Width = 32
    *-- .T. to display a prompt if the specified file exists,
    loverwriteprompt = .F.
    *-- .T. to display the Read Only button in the dialog.
    lshowreadonly = .F.
    *-- .T. to allow multiple filenames to be selected.
    lallowmultiple = .F.
    *-- .T. to display an error if the specified path doesn't exist.
    lpathmustexist = .F.
    *-- .T. if an error should be displayed if the specified file doesn't exist.
    lfilemustexist = .F.
    *-- .T. to display a prompt if the specified file doesn't exist.
    lpromptnew = .F.
    *-- .T. to allow a file to be selected even if it's open in another application.
    lshareaware = .F.
    *-- The path of the selected file.
    cpath = ""
    *-- The current directory prior to invoking the File dialog.
    PROTECTED coldcurrdir
    coldcurrdir = ""
    Name = "sffiledialog"

    *-- An array of filenames [without a path] selected by the user.
    DIMENSION afiles[1]


    *-- Displays an Open File dialog.
    PROCEDURE openfile
        with This
            .SaveDirectory()
            .SetFlags()
            .ShowOpen()
            .SetProperties()
            .RestoreDirectory()
        endwith
    ENDPROC


    *-- Displays a Save File dialog.
    PROCEDURE savefile
        with This
            .SaveDirectory()
            .SetFlags()
            .ShowSave()
            .SetProperties()
            .RestoreDirectory()
        endwith
    ENDPROC


    *-- Saves the current directory to cOldCurrDir.
    PROTECTED PROCEDURE savedirectory
        * Save the current directory.

        This.cOldCurrDir = sys(5) + curdir()
    ENDPROC


    *-- Sets the current directory to the one in cOldCurrDir.
    PROTECTED PROCEDURE restoredirectory
        * Restore the current directory.

        local lcOldCurrDir
        lcOldCurrDir = This.cOldCurrDir
        set default to (lcOldCurrDir)
    ENDPROC


    *-- Sets various properties after return from the dialog.
    PROTECTED PROCEDURE setproperties
        * Populate This.aFiles with the files selected by the user (there may be
        * multiple files) and set This.cPath to the directory for the file(s). Thanks
        * to Ted Roche for figuring out the multi-file parsing stuff.

        local lcSeparator, ;
            lcNewDir, ;
            lcFileName, ;
            lnFiles, ;
            lnStart, ;
            lnI, ;
            lnPos

        * Set This.cPath to the current directory (which is set to the directory
        * selected by the user).

        with This
            .cPath = sys(5) + curdir()
            do case

        * If the user cancelled the dialog, clear the aFiles array.

                case .lCancelled
                    dimension .aFiles[1]
                    .aFiles[1] = ''

        * If multiple files were selected, .FileName consists of the path followed by a
        * separator followed by the list of files selected separated by separators. If
        * only one file was selected, .FileName is the complete path to the file. To
        * parse everything out, start by determining if filenames are separated by
        * nulls (Windows 95 and NT 4) or spaces (NT 3.51). Strip the directory off
        * .FileName and remove any leading backslash or separator.

                case .lAllowMultiple
                    lcSeparator = iif(ccNULL $ This.FileName, ccNULL, ccSPACE)
                    lcNewDir    = left(.cPath, len(.cPath) - 1)
                    lcFileName  = substr(strtran(upper(.FileName), lcNewDir), 2)

        * Parse filenames from the filename string.

                    lnFiles = occurs(lcSeparator, lcFileName) + 1
                    lnStart = 1
                    for lnI = 1 to lnFiles
                        lnPos = iif(lnI = lnFiles, len(lcFileName) + 1, ;
                            at(lcSeparator, lcFileName, lnI))
                        dimension .aFiles[lnI]
                        .aFiles[lnI] = substr(lcFileName, lnStart, lnPos - lnStart)
                        lnStart = lnPos + 1
                    next lnI

        * If we didn't allow multiple filenames to be selected, save the filename
        * (without the path) in the aFiles array.

                otherwise
                    .aFiles[1] = substr(.FileName, rat('\', .FileName) + 1)
            endcase
        endwith
    ENDPROC


    PROCEDURE Init
        This.aFiles = ''
        dodefault()
    ENDPROC


    PROCEDURE setflags
        local lnFlags
        lnFlags = 0

        * Set the flags based on the settings of our properties.

        with This
            if .lAllowMultiple
                lnFlags = lnFlags + cnFILEDLG_MULTIPLE + cnFILEDLG_EXPLORER
            endif .lAllowMultiple
            if .lPromptNew
                lnFlags = lnFlags + cnFILEDLG_PROMPTNEW
            endif .lPromptNew
            if .lShowHelpButton
                lnFlags = lnFlags + cnFILEDLG_SHOWHELP
            endif .lShowHelpButton
            if .lFileMustExist
                lnFlags = lnFlags + cnFILEDLG_FILEEXIST
            endif .lFileMustExist
            if .lOverwritePrompt
                lnFlags = lnFlags + cnFILEDLG_OVERWRITE
            endif .lOverwritePrompt
            if .lPathMustExist
                lnFlags = lnFlags + cnFILEDLG_PATHEXIST
            endif .lPathMustExist
            if not .lShowReadOnly
                lnFlags = lnFlags + cnFILEDLG_HIDERO
            endif not .lShowReadOnly
            .Flags       = lnFlags
            .DialogTitle = alltrim(.DialogTitle)
            .DefaultExt  = alltrim(.DefaultExt)
            .FileName    = alltrim(.FileName)
            .InitDir     = alltrim(.InitDir)
            .Filter      = alltrim(.Filter)
            dodefault()
        endwith
    ENDPROC


ENDDEFINE
*
*-- EndDefine: sffiledialog
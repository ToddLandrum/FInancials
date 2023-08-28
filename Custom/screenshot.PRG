* Sound constants.

#DEFINE SND_SYNC       0
#DEFINE SND_ASYNC      1
#DEFINE SND_NODEFAULT  2
#DEFINE SND_LOOP       8
#DEFINE SND_NOSTOP    16

* Other constants.

#DEFINE cnERR_ARGUMENT_INVALID        11
&& Function argument value, type, or count is invalid

* Class to do screen shots.

DEFINE CLASS ScreenShot AS CUSTOM
    oBackGround = .NULL.
&& A reference to a white background form
    oBackGroundTLF = .NULL.
&& A reference to a white background form
    nhWnd = 0
&& The hWnd for the last form we used
    cSoundFile = 'camera_click.wav'
&& The name of the WAV file to play
    lPlaySound = .T.
&& .T. to play a sound after taking a screen shot

    PROCEDURE INIT

* Create a white background form in case we're using Aero Glass.

    THIS.oBackGround    = CREATEOBJECT('BackgroundForm')
    THIS.oBackGroundTLF = CREATEOBJECT('BackgroundFormTLF')

* Ensure System is available.

    DO (m.goapp.cCommonfolder+'\bin\SYSTEM.APP')

* Define some API functions we need.

    DECLARE Sleep IN Win32API INTEGER nMilliseconds
    DECLARE INTEGER SetForegroundWindow IN user32 INTEGER HWND
    DECLARE INTEGER sndPlaySound IN WinMM.DLL STRING lpszSoundName, INTEGER uFlags
    ENDPROC

    PROCEDURE DESTROY
    THIS.oBackGround = .NULL.
    ENDPROC

* Take a screen shot from the specified form.

    PROCEDURE TakeScreenShot(toForm, tcImageFile, tlNoResize)
    LOCAL loBackground, ;
        lcExt, ;
        loFormat, ;
        loCaptureBmp

* Ensure the parameters are passed correctly.
    DO CASE
        CASE TYPE('toForm.hWnd') <> 'N'
            ERROR cnERR_ARGUMENT_INVALID
            RETURN
        CASE VARTYPE(tcImageFile) <> 'C' OR EMPTY(tcImageFile)
            ERROR cnERR_ARGUMENT_INVALID
            RETURN
        CASE NOT INLIST(UPPER(JUSTEXT(tcImageFile)), 'PNG', 'BMP', 'GIF', ;
                  'JPG', 'JPEG', 'ICO', 'TIF', 'TIFF', 'WMF')
            ERROR cnERR_ARGUMENT_INVALID
            RETURN
    ENDCASE

* If we're not on the same form as before, adjust some things. First, see if we
* need a background window and if so, which one (in screen or top-level form).

    IF toForm.HWND <> THIS.nhWnd
        DO CASE
            CASE toForm.SHOWWINDOW = 2
                loBackground = THIS.oBackGroundTLF
            CASE toForm.DESKTOP
                loBackground = THIS.oBackGround
        ENDCASE

* If we're using a background window, make it visible and bring it to the top.
* Otherwise, make both background windows invisible.

        IF VARTYPE(loBackground) = 'O'
            loBackground.VISIBLE = .T.
            SetForegroundWindow(THIS.oBackGround.HWND)
        ELSE
            THIS.oBackGround.VISIBLE    = .F.
            THIS.oBackGroundTLF.VISIBLE = .F.
        ENDIF VARTYPE(loBackground) = 'O'

* Make the form the topmost window if it's visible or make it visible if it
* isn't. Notice that we call Show with 0 to make sure the form is modeless.

        IF toForm.VISIBLE
            SetForegroundWindow(toForm.HWND)
        ELSE
            toForm.SHOW(0)
        ENDIF toForm.VISIBLE

* Adjust the form to its smallest size.

        IF NOT tlNoResize
            IF toForm.MINWIDTH <> -1
                toForm.WIDTH = toForm.MINWIDTH
            ENDIF toForm.MINWIDTH <> -1
            IF toForm.MINHEIGHT <> -1
                toForm.HEIGHT = toForm.MINHEIGHT
            ENDIF toForm.MINHEIGHT <> -1
        ENDIF NOT tlNoResize

* Adjust the background form so it's larger than the target form so we have a
* nice white background for the target form.

        IF VARTYPE(loBackground) = 'O'
            WITH loBackground
                .TOP    = toForm.TOP    - 50
                .LEFT   = toForm.LEFT   - 50
                .HEIGHT = toForm.HEIGHT + 100
                .WIDTH  = toForm.WIDTH  + 100
            ENDWITH
        ENDIF VARTYPE(loBackground) = 'O'

* Use Sleep to ensure all window drawing is complete.

        Sleep(1000)
    ENDIF toForm.HWND <> THIS.nhWnd

* Use DOEVENTS to ensure all window drawing is complete.

    DOEVENTS FORCE
    WITH _SCREEN.SYSTEM.Drawing AS xfcDrawing OF SOURCE\SYSTEM.PRG

* Determine the image type from the file extension.

        lcExt = UPPER(JUSTEXT(tcImageFile))
        DO CASE
            CASE lcExt = 'PNG'
                loFormat = .Imaging.ImageFormat.Png
            CASE lcExt = 'BMP'
                loFormat = .Imaging.ImageFormat.Bmp
            CASE lcExt = 'GIF'
                loFormat = .Imaging.ImageFormat.Gif
            CASE INLIST(lcExt, 'JPG', 'JPEG')
                loFormat = .Imaging.ImageFormat.Jpeg
            CASE lcExt = 'ICO'
                loFormat = .Imaging.ImageFormat.ICON
            CASE INLIST(lcExt, 'TIF', 'TIFF')
                loFormat = .Imaging.ImageFormat.Tiff
            CASE lcExt = 'WMF'
                loFormat = .Imaging.ImageFormat.Wmf
        ENDCASE

* Take the screen shot.

        loCaptureBmp = .BITMAP.FromScreen(toForm.HWND)

* Save the image to the specified file.

        loCaptureBmp.SAVE(tcImageFile, loFormat)

* Play a screen shot sound.

        IF THIS.lPlaySound
            sndPlaySound(THIS.cSoundFile, SND_SYNC)
        ENDIF THIS.lPlaySound
        
        this.ViewScreenShot(tcImageFile)
        
    ENDWITH
    THIS.nhWnd = toForm.HWND
    RETURN
    ENDPROC

* Shoot all pages of the specified pageframe in the form.

    PROCEDURE ShootAllPageFramePages(toForm, toPageFrame, tcRootName, ;
          tlNoResize)
    LOCAL lcRootName, ;
        lcExt, ;
        lnI
    lcRootName = ADDBS(JUSTPATH(tcRootName)) + JUSTSTEM(tcRootName)
    lcExt      = '.' + JUSTEXT(tcRootName)
    FOR lnI = 1 TO toPageFrame.PAGECOUNT
        toPageFrame.ACTIVEPAGE = lnI
        THIS.TakeScreenShot(toForm, lcRootName + ;
              TRANSFORM(lnI) + lcExt, tlNoResize)
    NEXT lnI
    ENDPROC

    PROCEDURE ViewScreenShot
    LPARAMETERS tcScreenShot

    LOCAL lnReturn, llReturn, lcOutputFile
    LOCAL liKey, lcPath, llDebug

    llDebug = FILE('datafiles\debug.txt')


    TRY
            DECLARE INTEGER ShellExecute IN "Shell32.dll" ;
                INTEGER HWND, ;
                STRING lpVerb, ;
                STRING lpFile, ;
                STRING lpParameters, ;
                STRING lpDirectory, ;
                LONG nShowCmd

            lnReturn = ShellExecute(0, "Open", tcScreenShot, "", "", 1)

        

*      THIS.nReturnValue = lnReturn

        IF lnReturn > 32
            llReturn = .T.
        ELSE
            llReturn = .F.
            IF llDebug
                MESSAGEBOX('Return from ShellExecute: ' + TRANSFORM(lnReturn), 64, 'View Document')
            ENDIF
        ENDIF
    CATCH TO loError
        IF llDebug
            MESSAGEBOX('Error Occured: ' + CHR(10) + ;
                  loError.MESSAGE, 64, 'View Document')
        ENDIF
    ENDTRY

    RETURN (llReturn)

ENDDEFINE

* Class to provide a background window.

DEFINE CLASS BackgroundForm AS FORM
    DESKTOP   = .T.
    BACKCOLOR = RGB(255, 255, 255)
    CAPTION   = 'Screen Shot Background'
    ICON      = _SCREEN.ICON
ENDDEFINE

* Class to provide a background window for top-level forms.

DEFINE CLASS BackgroundFormTLF AS BackgroundForm
    SHOWWINDOW = 2
ENDDEFINE







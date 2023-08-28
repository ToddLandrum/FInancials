**********************************************************************
* Program....: IsRunning.prg
* Compiler...: Visual FoxPro 06.00.8492.00 for Windows
* Abstract...: When passed a string (i.e., 'Microsoft Word'), return .T.
* ...........: if the application is running. When invoked with no parameters,
*............: returns a parameter object whose array lists all running
*............: applications
*************************************************************************
FUNCTION IsRunning
LPARAMETERS luApplication

LOCAL luRetVal, lnFoxHwnd, lnWindow, lnWhich, lcText, lnLen, laApps[1], lnAppCnt
 
*** Declare necessary Windows API functions 
 
DECLARE INTEGER GetActiveWindow IN Win32Api 

DECLARE INTEGER GetWindow IN Win32Api ;
		INTEGER lnWindow, ;
		INTEGER lnWhich

DECLARE INTEGER GetWindowText IN Win32Api ;
		INTEGER lnWindow, ;
		STRING 	@lcText, ;
		INTEGER lnLen
		
DECLARE INTEGER IsWindowVisible IN Win32Api ;
		INTEGER lnWindow
 
lnAppCnt = 0

*** Get the HWND (handle) to the main FoxPro window

lnFoxHwnd = GetActiveWindow()
IF lnFoxHwnd = 0
	MESSAGEBOX( 'Invalid return value from GetActiveWindow', 16, 'Fatal Error' )
	RETURN
ENDIF	 
 
***  Loop through all the running applications
 
lnWindow = GetWindow( lnFoxHwnd, 0 )
DO WHILE lnWindow # 0
	*** Make sure we do not have the Visual Foxpro window
   	IF lnWindow # lnFoxHwnd 
        IF GetWindow( lnWindow, 4 ) = 0 AND IsWindowVisible( lnWindow ) # 0
			lcText = SPACE( 254 )
			lnLen  = GetWindowText( lnWindow, @lcText, LEN( lcText ) )
 			
 			*** If the function was passed an Application Name, check for a match
 			*** Otherwise, Add this to the array
			IF lnLen > 0
			  	IF VARTYPE( luApplication ) = 'L'
					lnAppCnt = lnAppCnt + 1
			  		DIMENSION laApps[ lnAppCnt ]
		  			laApps[ lnAppCnt ] = LEFT( lcText, lnLen )
				ELSE
 					IF UPPER( ALLTRIM( luApplication ) ) $ UPPER( ALLTRIM( lcText ) )
        	           RETURN .T.
            	    ENDIF
				ENDIF            	    
			ENDIF
		ENDIF
	ENDIF

 	*** See if there is another running application
	lnWindow = GetWindow( lnWindow, 2 )
ENDDO
 
*** Either we haven't found a match for the passed application name
*** or we are returning an array of all running applications
IF VARTYPE( luApplication ) = 'L'
	SET CLASSLIB TO Ch13 ADDITIVE
	luRetVal = CREATEOBJECT( 'xParameters', @laApps )
ELSE    
	luRetVal = .F.
ENDIF
	 
RETURN luRetVal

*++
* CodeMine header file for accessing win32 system functions.
* Values derived from the Win95 SDK file winuser.h
*
* Copyright 1995 Soft Classics, Ltd. All rights reserved.
*--

* SetWindowPos Flags
#define SWP_NOSIZE          1
#define SWP_NOMOVE          2
#define SWP_NOZORDER        4
#define SWP_NOREDRAW        8
#define SWP_NOACTIVATE      16
#define SWP_FRAMECHANGED    32    && The frame changed: send WM_NCCALCSIZE
#define SWP_SHOWWINDOW      64
#define SWP_HIDEWINDOW      128
#define SWP_NOCOPYBITS      256
#define SWP_NOOWNERZORDER   512   && Don't do owner Z ordering
#define SWP_NOSENDCHANGING  1024  && Don't send WM_WINDOWPOSCHANGING

#define SWP_DRAWFRAME       SWP_FRAMECHANGED
#define SWP_NOREPOSITION    SWP_NOOWNERZORDER

#define HWND_TOP        0
#define HWND_BOTTOM     1
#define HWND_TOPMOST    -1
#define HWND_NOTOPMOST  -2

* ShowWindow() Commands
#define SW_HIDE             0
#define SW_SHOWNORMAL       1
#define SW_NORMAL           1
#define SW_SHOWMINIMIZED    2
#define SW_SHOWMAXIMIZED    3
#define SW_MAXIMIZE         3
#define SW_SHOWNOACTIVATE   4
#define SW_SHOW             5
#define SW_MINIMIZE         6
#define SW_SHOWMINNOACTIVE  7
#define SW_SHOWNA           8
#define SW_RESTORE          9
#define SW_SHOWDEFAULT      10
#define SW_FORCEMINIMIZE    11
#define SW_MAX              11

* GetWindow() Constants
#define GW_HWNDFIRST        0
#define GW_HWNDLAST         1
#define GW_HWNDNEXT         2
#define GW_HWNDPREV         3
#define GW_OWNER            4
#define GW_CHILD            5
#define GW_MAX              5

#define WM_MOUSEFIRST      512
#define WM_MOUSEMOVE       512
#define WM_LBUTTONDOWN     513
#define WM_LBUTTONUP       514
#define WM_LBUTTONDBLCLK   515
#define WM_RBUTTONDOWN     516
#define WM_RBUTTONUP       517
#define WM_RBUTTONDBLCLK   518
#define WM_MBUTTONDOWN     519
#define WM_MBUTTONUP       520
#define WM_MBUTTONDBLCLK   521
#define WM_MOUSELAST       521

* Window Style bits
#define WS_OVERLAPPED       0x00000000
#define WS_POPUP            0x80000000
#define WS_CHILD            0x40000000
#define WS_MINIMIZE         0x20000000
#define WS_VISIBLE          0x10000000
#define WS_DISABLED         0x08000000
#define WS_CLIPSIBLINGS     0x04000000
#define WS_CLIPCHILDREN     0x02000000
#define WS_MAXIMIZE         0x01000000
#define WS_CAPTION          0x00C00000    && WS_BORDER | WS_DLGFRAME
#define WS_BORDER           0x00800000
#define WS_DLGFRAME         0x00400000
#define WS_VSCROLL          0x00200000
#define WS_HSCROLL          0x00100000
#define WS_SYSMENU          0x00080000
#define WS_THICKFRAME       0x00040000
#define WS_GROUP            0x00020000
#define WS_TABSTOP          0x00010000
#define WS_MINIMIZEBOX      0x00020000
#define WS_MAXIMIZEBOX      0x00010000

* Extended window styles
#define WS_EX_DLGMODALFRAME     0x00000001
#define WS_EX_NOPARENTNOTIFY    0x00000004
#define WS_EX_TOPMOST           0x00000008
#define WS_EX_ACCEPTFILES       0x00000010
#define WS_EX_TRANSPARENT       0x00000020
#define WS_EX_MDICHILD          0x00000040
#define WS_EX_TOOLWINDOW        0x00000080
#define WS_EX_WINDOWEDGE        0x00000100
#define WS_EX_CLIENTEDGE        0x00000200
#define WS_EX_CONTEXTHELP       0x00000400
#define WS_EX_RIGHT             0x00001000
#define WS_EX_LEFT              0x00000000
#define WS_EX_RTLREADING        0x00002000
#define WS_EX_LTRREADING        0x00000000
#define WS_EX_LEFTSCROLLBAR     0x00004000
#define WS_EX_RIGHTSCROLLBAR    0x00000000
#define WS_EX_CONTROLPARENT     0x00010000
#define WS_EX_STATICEDGE        0x00020000
#define WS_EX_APPWINDOW         0x00040000

* Windows color element codes used by GetSysColor()
#define COLOR_SCROLLBAR                0
#define COLOR_BACKGROUND               1
#define COLOR_ACTIVECAPTION            2
#define COLOR_INACTIVECAPTION          3
#define COLOR_MENU                     4
#define COLOR_WINDOW                   5
#define COLOR_WINDOWFRAME              6
#define COLOR_MENUTEXT                 7
#define COLOR_WINDOWTEXT               8
#define COLOR_CAPTIONTEXT              9
#define COLOR_ACTIVEBORDER            10
#define COLOR_INACTIVEBORDER          11
#define COLOR_APPWORKSPACE            12
#define COLOR_HIGHLIGHT               13
#define COLOR_HIGHLIGHTTEXT           14
#define COLOR_BTNFACE                 15
#define COLOR_BTNSHADOW               16
#define COLOR_GRAYTEXT                17
#define COLOR_BTNTEXT                 18
#define COLOR_INACTIVECAPTIONTEXT     19
#define COLOR_BTNHIGHLIGHT            20
#define COLOR_3DDKSHADOW              21
#define COLOR_3DLIGHT                 22
#define COLOR_INFOTEXT                23
#define COLOR_INFOBK                  24
#define COLOR_GRADIENTACTIVECAPTION   27
#define COLOR_GRADIENTINACTIVECAPTION 28
#define COLOR_DESKTOP                 COLOR_BACKGROUND
#define COLOR_3DFACE                  COLOR_BTNFACE
#define COLOR_3DSHADOW                COLOR_BTNSHADOW
#define COLOR_3DHIGHLIGHT             COLOR_BTNHIGHLIGHT
#define COLOR_3DHILIGHT               COLOR_BTNHIGHLIGHT
#define COLOR_BTNHILIGHT              COLOR_BTNHIGHLIGHT

* Virtual Keys, Standard Set
#define VK_LBUTTON        1
#define VK_RBUTTON        2
#define VK_CANCEL         3
#define VK_MBUTTON        4    && NOT contiguous with L & R BUTTON 
#define VK_BACK           8
#define VK_TAB            9
#define VK_CLEAR          12
#define VK_RETURN         13

#define VK_SHIFT          16
#define VK_CONTROL        17
#define VK_MENU           18
#define VK_PAUSE          19
#define VK_CAPITAL        20

#define VK_ESCAPE         27

#define VK_SPACE          32
#define VK_PRIOR          33
#define VK_NEXT           34
#define VK_END            35
#define VK_HOME           36
#define VK_LEFT           37
#define VK_UP             38
#define VK_RIGHT          39
#define VK_DOWN           40
#define VK_SELECT         41
#define VK_PRINT          42
#define VK_EXECUTE        43
#define VK_SNAPSHOT       44
#define VK_INSERT         45
#define VK_DELETE         46
#define VK_HELP           47

* VK_0 thru VK_9 are the same as ASCII '0' thru '9' (0x30 - 0x39)
* VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' (0x41 - 0x5A)

#define VK_LWIN           91
#define VK_RWIN           92
#define VK_APPS           93

#define VK_NUMPAD0        96
#define VK_NUMPAD1        97
#define VK_NUMPAD2        98
#define VK_NUMPAD3        99
#define VK_NUMPAD4        100
#define VK_NUMPAD5        101
#define VK_NUMPAD6        102
#define VK_NUMPAD7        103
#define VK_NUMPAD8        104
#define VK_NUMPAD9        105
#define VK_MULTIPLY       106
#define VK_ADD            107
#define VK_SEPARATOR      108
#define VK_SUBTRACT       109
#define VK_DECIMAL        110
#define VK_DIVIDE         111
#define VK_F1             112
#define VK_F2             113
#define VK_F3             114
#define VK_F4             115
#define VK_F5             116
#define VK_F6             117
#define VK_F7             118
#define VK_F8             119
#define VK_F9             120
#define VK_F10            121
#define VK_F11            122
#define VK_F12            123
#define VK_F13            124
#define VK_F14            125
#define VK_F15            126
#define VK_F16            127
#define VK_F17            128
#define VK_F18            129
#define VK_F19            130
#define VK_F20            131
#define VK_F21            132
#define VK_F22            133
#define VK_F23            134
#define VK_F24            135

#define VK_NUMLOCK        144
#define VK_SCROLL         145

*
* VK_L* & VK_R* - left and right Alt, Ctrl and Shift virtual keys.
* Used only as parameters to GetAsyncKeyState() and GetKeyState().
* No other API or message will distinguish left and right keys in this way.
*
#define VK_LSHIFT         160
#define VK_RSHIFT         161
#define VK_LCONTROL       162
#define VK_RCONTROL       163
#define VK_LMENU          164
#define VK_RMENU          165

*
* Key State Masks for Mouse Messages
*
#IFNDEF MB_OK
#define MK_LBUTTON          1
#define MK_RBUTTON          2
#define MK_SHIFT            4
#define MK_CONTROL          8
#define MK_MBUTTON         16

#define MB_OK                       0
#define MB_ICONHAND                 16
#define MB_ICONQUESTION             32
#define MB_ICONEXCLAMATION          48
#define MB_ICONASTERISK             64
#ENDIF
*
* Standard Cursor IDs
*
#define IDC_ARROW           32512
#define IDC_IBEAM           32513
#define IDC_WAIT            32514
#define IDC_CROSS           32515
#define IDC_UPARROW         32516
#define IDC_SIZE            32640 && OBSOLETE: use IDC_SIZEALL
#define IDC_ICON            32641 && OBSOLETE: use IDC_ARROW
#define IDC_SIZENWSE        32642
#define IDC_SIZENESW        32643
#define IDC_SIZEWE          32644
#define IDC_SIZENS          32645
#define IDC_SIZEALL         32646
#define IDC_NO              32648 && not in win3.1
#define IDC_APPSTARTING     32650 && not in win3.1
#define IDC_HELP            32651

* Windows registry root key definitions
#define HKEY_CLASSES_ROOT           (2^31) + 0
#define HKEY_CURRENT_USER           (2^31) + 1
#define HKEY_LOCAL_MACHINE          (2^31) + 1
#define HKEY_USERS                  (2^31) + 3
#define HKEY_PERFORMANCE_DATA       (2^31) + 4

* Win 4.0 only keys
#define HKEY_CURRENT_CONFIG         (2^31) + 5
#define HKEY_DYN_DATA               (2^31) + 6

* Predefined Value Types.
#define REG_NONE                    ( 0 )   && No value type
#define REG_SZ                      ( 1 )   && null terminated string
#define REG_EXPAND_SZ               ( 2 )   && Unicode nul terminated string
                                            && (with environment variable references)
#define REG_BINARY                  ( 3 )   && Free form binary
#define REG_DWORD                   ( 4 )   && 32-bit number
#define REG_DWORD_LITTLE_ENDIAN     ( 4 )   && 32-bit number (same as REG_DWORD)
#define REG_DWORD_BIG_ENDIAN        ( 5 )   && 32-bit number
#define REG_LINK                    ( 6 )   && Symbolic Link (unicode)
#define REG_MULTI_SZ                ( 7 )   && Multiple Unicode strings
#define REG_RESOURCE_LIST           ( 8 )   && Resource list in the resource map
#define REG_FULL_RESOURCE_DESCRIPTOR ( 9 )  && Resource list in the hardware description
#define REG_RESOURCE_REQUIREMENTS_LIST ( 10 )

* InformationItem code for SQLGetInfo() API function (from Visual Studio sql.h file)
#define SQL_ACTIVE_CONNECTIONS               0	 && MAX_DRIVER_CONNECTIONS
#define SQL_ACTIVE_STATEMENTS                1	 && MAX_CONCURRENT_ACTIVITIES
#define SQL_DATA_SOURCE_NAME                 2   && DSN name (if any)
#define SQL_SERVER_NAME                     13
#define SQL_DBMS_NAME                       17   && Server type (SQL Server, Sybase, Oracle, etc)
#define SQL_DBMS_VER                        18   && Server software version
#define SQL_DATA_SOURCE_READ_ONLY           25   && Database (or ODBC driver) is read-only
#define SQL_IDENTIFIER_CASE                 28
#define SQL_IDENTIFIER_QUOTE_CHAR           29
#define SQL_USER_NAME                       47
#define SQL_DRIVER_NAME                      6   && ODBC driver file name
#define SQL_DRIVER_VER                       7   && ODBC driver version
#define SQL_PROCEDURES                      21
#define SQL_TXN_CAPABLE                     46
#define SQL_SPECIAL_CHARACTERS              94   && List of valid item name characters 

* Generic access rights flags for NT file operations
#define GENERIC_READ                     0x80000000
#define GENERIC_WRITE                    0x40000000
#define GENERIC_EXECUTE                  0x20000000
#define GENERIC_ALL                      0x10000000

* File sharing bit flags for NT file operations
#define FILE_SHARE_READ                 0x00000001  
#define FILE_SHARE_WRITE                0x00000002  
#define FILE_SHARE_DELETE               0x00000004  

* File creation flags
#define CREATE_NEW          1
#define CREATE_ALWAYS       2
#define OPEN_EXISTING       3
#define OPEN_ALWAYS         4
#define TRUNCATE_EXISTING   5

*** Post boundary used for posting multipart vars
#DEFINE MULTIPART_BOUNDARY		"-----------------------------7cf2a327f01ae"

*** General WinINET Constants
#DEFINE INTERNET_OPEN_TYPE_PRECONFIG    		0
#DEFINE INTERNET_OPEN_TYPE_DIRECT       		1
#DEFINE INTERNET_OPEN_TYPE_PROXY             	3
#DEFINE INTERNET_OPTION_CONNECT_TIMEOUT         2
#DEFINE INTERNET_OPTION_CONNECT_RETRIES         3
#DEFINE INTERNET_OPTION_SEND_TIMEOUT       		5
#DEFINE INTERNET_OPTION_RECEIVE_TIMEOUT    		6
#DEFINE INTERNET_OPTION_DATA_SEND_TIMEOUT       5
#DEFINE INTERNET_OPTION_DATA_RECEIVE_TIMEOUT    6
#DEFINE INTERNET_OPTION_LISTEN_TIMEOUT          11
#DEFINE INTERNET_SERVICE_FTP				    1
#DEFINE INTERNET_DEFAULT_FTP_PORT				21

#DEFINE ERROR_INTERNET_EXTENDED_ERROR           12003

* WinInet Service Flags
#DEFINE INTERNET_SERVICE_HTTP         			3
#DEFINE INTERNET_DEFAULT_HTTP_PORT      		80
#DEFINE INTERNET_DEFAULT_HTTPS_PORT   		  	443
#DEFINE INTERNET_FLAG_RELOAD            		2147483648
#DEFINE INTERNET_FLAG_SECURE            		8388608
#DEFINE INTERNET_FLAG_KEEP_CONNECTION           0x00400000  

#DEFINE HTTP_STATUS_PROXY_AUTH_REQ           	407 
#DEFINE HTTP_QUERY_STATUS_CODE                  19  
#DEFINE HTTP_QUERY_FLAG_NUMBER                  0x20000000
#DEFINE HTTP_QUERY_RAW_HEADERS_CRLF          	22  
#DEFINE HTTP_QUERY_STATUS_CODE                  19  
#DEFINE HTTP_QUERY_STATUS_TEXT                  20  
#DEFINE HTTP_QUERY_CONTENT_TYPE                 1
#DEFINE HTTP_QUERY_CONTENT_ID                   3
#DEFINE HTTP_QUERY_CONTENT_DESCRIPTION          4
#DEFINE HTTP_QUERY_CONTENT_LENGTH               5

#DEFINE FTP_TRANSFER_TYPE_ASCII     			1
#DEFINE FTP_TRANSFER_TYPE_BINARY    			2

#DEFINE INTERNET_FLAG_IGNORE_CERT_DATE_INVALID  0x00002000

* WinHttpOpen dwAccessType values (also for WINHTTP_PROXY_INFO::dwAccessType)
#define WINHTTP_ACCESS_TYPE_DEFAULT_PROXY               0
#define WINHTTP_ACCESS_TYPE_NO_PROXY                    1
#define WINHTTP_ACCESS_TYPE_NAMED_PROXY                 3

* WinHttpOpen prettifiers for optional parameters
#define WINHTTP_NO_PROXY_NAME     NULL
#define WINHTTP_NO_PROXY_BYPASS   NULL

* Flags for WinHttpOpenRequest()
#define WINHTTP_FLAG_SECURE                0x00800000  && use SSL if applicable (HTTPS)
#define WINHTTP_FLAG_ESCAPE_PERCENT        0x00000004  && if escaping enabled, escape percent as well
#define WINHTTP_FLAG_NULL_CODEPAGE         0x00000008  && assume all symbols are ASCII, use fast convertion
#define WINHTTP_FLAG_BYPASS_PROXY_CACHE    0x00000100  && add "pragma: no-cache" request header
#define	WINHTTP_FLAG_REFRESH               WINHTTP_FLAG_BYPASS_PROXY_CACHE
#define WINHTTP_FLAG_ESCAPE_DISABLE        0x00000040  && disable escaping
#define WINHTTP_FLAG_ESCAPE_DISABLE_QUERY  0x00000080  && if escaping enabled escape path part, but do not escape query

* WinHttp Option flags
#define WINHTTP_OPTION_RESOLVE_TIMEOUT                2
#define WINHTTP_OPTION_CONNECT_TIMEOUT                3
#define WINHTTP_OPTION_CONNECT_RETRIES                4
#define WINHTTP_OPTION_SEND_TIMEOUT                   5
#define WINHTTP_OPTION_RECEIVE_TIMEOUT                6
#define WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT       7
#define WINHTTP_OPTION_READ_BUFFER_SIZE              12
#define WINHTTP_OPTION_WRITE_BUFFER_SIZE             13
#define WINHTTP_OPTION_EXTENDED_ERROR                24
#define WINHTTP_OPTION_SECURITY_FLAGS                31
#define WINHTTP_OPTION_SECURITY_CERTIFICATE_STRUCT   32
#define WINHTTP_OPTION_URL                           34
#define WINHTTP_OPTION_PROXY                         38

#define WINHTTP_QUERY_MIME_VERSION                 0
#define WINHTTP_QUERY_CONTENT_TYPE                 1
#define WINHTTP_QUERY_CONTENT_TRANSFER_ENCODING    2
#define WINHTTP_QUERY_CONTENT_ID                   3
#define WINHTTP_QUERY_CONTENT_DESCRIPTION          4
#define WINHTTP_QUERY_CONTENT_LENGTH               5
#define WINHTTP_QUERY_CONTENT_LANGUAGE             6
#define WINHTTP_QUERY_VERSION                      18  && special: part of status line
#define WINHTTP_QUERY_STATUS_CODE                  19  && special: part of status line
#define WINHTTP_QUERY_STATUS_TEXT                  20  && special: part of status line
#define WINHTTP_QUERY_RAW_HEADERS                  21  && special: all headers as ASCIIZ
#define WINHTTP_QUERY_RAW_HEADERS_CRLF             22  && special: all headers

* Win32 API Constants
#DEFINE ERROR_SUCCESS               			0

* Access Flags
#DEFINE GENERIC_READ                     		0x80000000
#DEFINE GENERIC_WRITE                    		0x40000000
#DEFINE GENERIC_EXECUTE                  		0x20000000
#DEFINE GENERIC_ALL                      		0x10000000

* File Attribute Flags
#DEFINE FILE_ATTRIBUTE_NORMAL               	0x00000080
#DEFINE FILE_ATTRIBUTE_READONLY             	0x00000001
#DEFINE FILE_ATTRIBUTE_HIDDEN               	0x00000002
#DEFINE FILE_ATTRIBUTE_SYSTEM               	0x00000004

* Values for FormatMessage API
#DEFINE FORMAT_MESSAGE_FROM_SYSTEM				4096
#DEFINE FORMAT_MESSAGE_FROM_HMODULE				2048

* Generic File Access Rights for NT ACLs
#define FILERIGHTS_READ				1179785
#define FILERIGHTS_READEXECUTE		1179817
#define FILERIGHTS_CHANGE 			1245631
#define FILERIGHTS_FULL				2032127


* Application-specific header file
#include '..\common\codemine.h'
#include '..\custom\sfctrls.h'
#include ..\common\win32.h

#DEFINE COMPANYNAME_LOC "SherWare, Inc."

* These constants are used to build the root system registry key for the application
* SherWare Financials
#DEFINE APPNAME_LOC "SherWare Financials"
#DEFINE VERSION_LOC '6.0.0'

* Version subletters
#DEFINE VERSION_SUB ''

#DEFINE opt_graphing        0
#DEFINE opt_WPIE            0
#DEFINE opt_partnership     1
#DEFINE opt_housegas        2
#DEFINE opt_K1              3
#DEFINE opt_qbstandard      4
#DEFINE opt_LiveVersion     5
#DEFINE opt_brine           6
#DEFINE opt_afe             7
#DEFINE opt_qbbasic         8
#DEFINE opt_documents       9
#DEFINE opt_land           10
#DEFINE opt_online         11
#DEFINE opt_offsite        12
#DEFINE opt_directdep      13
#DEFINE opt_payroll        14
#DEFINE opt_micr           15
#DEFINE opt_lan5           16
#DEFINE opt_lan10          17
#DEFINE opt_lanunlimited   18
#DEFINE opt_AM             19
#DEFINE opt_DM             20
#DEFINE opt_DMIE           21
#DEFINE opt_CloudDoc       22
#DEFINE opt_LandEn         23
#DEFINE opt_WP             24
#DEFINE opt_MonthlySupport 26
#DEFINE opt_MonthlyLicense 27
#DEFINE opt_WPENT          28
#DEFINE opt_ImportModule   29
#DEFINE opt_PluggingModule 30
#DEFINE opt_JVModule 	   31
#DEFINE opt_EnergyLink 	  '60'

#DEFINE opt_OH_Reports     '17'
#DEFINE opt_WV_Reports	   '35'
#DEFINE opt_PA_Reports     '02'
#DEFINE opt_TX_Reports     '28'
#DEFINE opt_OK_Reports     '46'
#DEFINE opt_NY_Reports     '11'
#DEFINE opt_WY_Reports     '44'
#DEFINE opt_CO_Reports     '38'
#DEFINE opt_LA_Reports     '18'

#DEFINE myProduct 'AM'

* Table Buffering
#DEFINE TABLEBUFFER       .T.

* swNetExp parms
#DEFINE netJIBDUMMY       'N'
#DEFINE netDUMMY          'B'
#DEFINE netNETDUMMY       'J'
#DEFINE netJIB            'D'
#DEFINE netNET            'DN'

#DEFINE GROSSUP           .F.
#DEFINE NETDOWN           .T.
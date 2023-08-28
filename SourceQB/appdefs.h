* Application-specific header file
#include '..\common\codemine.h'

#define COMPANYNAME_LOC "SherWare, Inc."

* These constants are used to build the root system registry key for the application
* Accounting Manager Pro Version 6.0.0
#define APPNAME_LOC "Oil & Gas Accounting Manager"
#define VERSION_LOC '6.0.0' 

* Version subletters
#define VERSION_SUB ''

* SherWare Module Options
#define opt_graphing      0
#define opt_partnership   1   
#define opt_housegas      2
#define opt_K1            3
#define opt_qbstandard    4
#define opt_LiveVersion   5
#define opt_brine         6
#define opt_afe           7
#define opt_qbbasic       8
#define opt_documents     9
#define opt_land          10
#define opt_online        11
#define opt_offsite       12
#define opt_directdep     13
#define opt_payroll       14
#define opt_micr          15
#define opt_lan5          16
#define opt_lan10         17
#define opt_lanunlimited  18
#define opt_AMPRO         19
#define opt_DMPRO         20
#define opt_DMQB          21
#DEFINE opt_CloudDoc       22
#DEFINE opt_LandEn         23
#DEFINE opt_MonthlySupport 26
#DEFINE opt_MonthlyLicense 27
#DEFINE opt_WPENT          28
#DEFINE opt_ImportModule   29
#DEFINE opt_PluggingModule 30
#DEFINE opt_JVModule 		31
#DEFINE opt_EnergyLink 		'60'

#DEFINE opt_OH_Reports     '17'
#DEFINE opt_WV_Reports	   '35'
#DEFINE opt_PA_Reports     '02'
#DEFINE opt_TX_Reports     '28'
#DEFINE opt_OK_Reports     '46'
#DEFINE opt_NY_Reports     '11'
#DEFINE opt_WY_Reports     '44'
#DEFINE opt_CO_Reports     '38'
#DEFINE opt_LA_Reports     '18'

#DEFINE myProduct 'DMIE'
* Table Buffering
#define TABLEBUFFER       .T.

* swNetExp parms
#DEFINE netJIBDUMMY       'N'
#DEFINE netDUMMY          'B'
#DEFINE netNETDUMMY       'J'
#DEFINE netJIB            'D'
#DEFINE netNET            'DN'

#DEFINE GROSSUP           .F.
#DEFINE NETDOWN           .T.


* Application-specific header file
#include '..\common\codemine.h'

#DEFINE COMPANYNAME_LOC "SherWare, Inc."

* These constants are used to build the root system registry key for the application
* SherWare Financials
#DEFINE APPNAME_LOC "SherWare Financials"
#DEFINE VERSION_LOC '6.0.0'

* Version subletters
#DEFINE VERSION_SUB ''

#DEFINE _Family_APP             1
#DEFINE _Operator_APP           2
#DEFINE _OperatorPlus_APP       4 
#DEFINE _Enterprise_APP         8

#DEFINE _optJIB               512
#DEFINE _optLand             1024
#DEFINE _optDirDeposit       2048
#DEFINE _optMICR             4096
#DEFINE _optPlugging         8192
#DEFINE _optStateRpts       16384
#DEFINE _optQBO             32768
#DEFINE _optQBD             65536
#DEFINE _optHG             131072
#DEFINE _optAdvRpts        262144
#DEFINE _opt1099k1         524288
#DEFINE _optGoldSupport   1048576
#DEFINE _optPlatSupport   2097152
#DEFINE _optInvPortal     4194304
#DEFINE _optSilverSupport 8388608
#DEFINE _optBrineHauler  16777216
#DEFINE _optAFE          33554432

#DEFINE _optLiveVersion  67108864

#DEFINE _optPayroll     134217728
#DEFINE _optPartnership 268435456


#DEFINE Family_APP             0
#DEFINE Operator_APP           1
#DEFINE OperatorPlus_APP       2
#DEFINE Enterprise_APP         3

#DEFINE optJIB                 9
#DEFINE optLand               10
#DEFINE optDirDeposit         11
#DEFINE optMICR               12
#DEFINE optPlugging           13
#DEFINE optStateRpts          14
#DEFINE optQBO                15
#DEFINE optQBD                16
#DEFINE optHG                 17
#DEFINE optAdvRpts            18
#DEFINE opt1099k1             19
#DEFINE optGoldSupport        20
#DEFINE optPlatSupport        21
#DEFINE optInvPortal          22
#DEFINE optSilverSupport      23
#DEFINE optBrineHauler        24
#DEFINE optAFE                25

#DEFINE optLiveVersion        26

#DEFINE optPayroll            27
#DEFINE optPartnership        28

#DEFINE optNumWells           4
#DEFINE optNumUsers           5
#DEFINE optNumTrans           6
#DEFINE optNumCompanies       7
 
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
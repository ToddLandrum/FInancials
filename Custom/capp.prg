
**************************************************
*-- Class Library:  c:\develop\codeminenew\ampro_rv\custom\capp.vcx
**************************************************F
**************************************************
*-- Class:        frmaboutcustom (c:\develop\codeminenew\ampro_rv\custom\capp.vcx)
*-- ParentClass:  frmabout (c:\develop\codeminenew\ampro_rv\common\cmdialog.vcx)
*-- BaseClass:    form
*-- Time Stamp:   06/08/03 01:36:13 AM
*
DEFINE CLASS frmaboutcustom AS frmabout


   DOCREATE                                = .T.
   NAME                                    = 'frmaboutcustom'
   pgfpageframe.ERASEPAGE                  = .T.
   pgfpageframe.Page1.Lbllabel3.NAME       = 'Lbllabel3'
   pgfpageframe.Page1.lblOwner.NAME        = 'lblOwner'
   pgfpageframe.Page1.lblOrg.NAME          = 'lblOrg'
   pgfpageframe.Page1.lblCopyright.NAME    = 'lblCopyright'
   pgfpageframe.Page1.lblProductName.NAME  = 'lblProductName'
   pgfpageframe.Page1.Lbllabel8.NAME       = 'Lbllabel8'
   pgfpageframe.Page1.lblWinVersion.NAME   = 'lblWinVersion'
   pgfpageframe.Page1.Lbllabel9.NAME       = 'Lbllabel9'
   pgfpageframe.Page1.Lbllabel12.NAME      = 'Lbllabel12'
   pgfpageframe.Page1.Lbllabel1.NAME       = 'Lbllabel1'
   pgfpageframe.Page1.lblSerialNumber.NAME = 'lblSerialNumber'
   pgfpageframe.Page1.NAME                 = 'Page1'
   pgfpageframe.Page2.lblCompany.NAME      = 'lblCompany'
   pgfpageframe.Page2.lblAddr1.NAME        = 'lblAddr1'
   pgfpageframe.Page2.lblAddr2.NAME        = 'lblAddr2'
   pgfpageframe.Page2.lblPhone.NAME        = 'lblPhone'
   pgfpageframe.Page2.lblWeb.NAME          = 'lblWeb'
   pgfpageframe.Page2.lblEmail.NAME        = 'lblEmail'
   pgfpageframe.Page2.NAME                 = 'Page2'
   pgfpageframe.Page3.lblDiskspace.NAME    = 'lblDiskspace'
   pgfpageframe.Page3.lblFreeDisk.NAME     = 'lblFreeDisk'
   pgfpageframe.Page3.Shpshape1.NAME       = 'Shpshape1'
   pgfpageframe.Page3.Lbllabel1.NAME       = 'Lbllabel1'
   pgfpageframe.Page3.Lbllabel2.NAME       = 'Lbllabel2'
   pgfpageframe.Page3.Lbllabel4.NAME       = 'Lbllabel4'
   pgfpageframe.Page3.lblRegpath.NAME      = 'lblRegpath'
   pgfpageframe.Page3.Lbllabel3.NAME       = 'Lbllabel3'
   pgfpageframe.Page3.Lbllabel5.NAME       = 'Lbllabel5'
   pgfpageframe.Page3.Lbllabel6.NAME       = 'Lbllabel6'
   pgfpageframe.Page3.Lbllabel7.NAME       = 'Lbllabel7'
   pgfpageframe.Page3.lblMemPool.NAME      = 'lblMemPool'
   pgfpageframe.Page3.lblFreeMem.NAME      = 'lblFreeMem'
   pgfpageframe.Page3.Lbllabel10.NAME      = 'Lbllabel10'
   pgfpageframe.Page3.Lbllabel11.NAME      = 'Lbllabel11'
   pgfpageframe.Page3.NAME                 = 'Page3'
   pgfpageframe.NAME                       = 'pgfpageframe'
   Cmdcommandbutton1.NAME                  = 'Cmdcommandbutton1'
   cmdok.NAME                              = 'cmdok'


ENDDEFINE
*
*-- EndDefine: frmaboutcustom
**************************************************


**************************************************
*-- Class:        frminstallconfirmcustom (c:\develop\_SherWare\custom\capp.vcx)
*-- ParentClass:  frminstallconfirm (c:\develop\_SherWare\common\cmsetup.vcx)
*-- BaseClass:    form
*-- Time Stamp:   06/08/03 01:37:05 AM
*
DEFINE CLASS frminstallconfirmcustom AS frminstallconfirm


   DOCREATE                    = .T.
   NAME                        = 'frminstallconfirmcustom'
   Cntokcancel1.cmdok.NAME     = 'cmdok'
   Cntokcancel1.cmdCancel.NAME = 'cmdCancel'
   Cntokcancel1.NAME           = 'Cntokcancel1'
   lblPath.NAME                = 'lblPath'
   Lbltext1.NAME               = 'Lbltext1'
   Lbltext2.NAME               = 'Lbltext2'
   Imgimage1.HEIGHT            = 32
   Imgimage1.WIDTH             = 32
   Imgimage1.NAME              = 'Imgimage1'


ENDDEFINE
*
*-- EndDefine: frminstallconfirmcustom
**************************************************


**************************************************
*-- Class:        frminstalldialogcustom (c:\develop\_SherWare\custom\capp.vcx)
*-- ParentClass:  frminstalldialog (c:\develop\_SherWare\common\cmsetup.vcx)
*-- BaseClass:    form
*-- Time Stamp:   02/15/07 05:54:01 PM
*
DEFINE CLASS frminstalldialogcustom AS frminstalldialog


   DOCREATE                                      = .T.
   NAME                                          = 'frminstalldialogcustom'
   pgfSteps.ERASEPAGE                            = .T.
   pgfSteps.pagRegistration.txtName.NAME         = 'txtName'
   pgfSteps.pagRegistration.Lbltext1.NAME        = 'Lbltext1'
   pgfSteps.pagRegistration.lblName.NAME         = 'lblName'
   pgfSteps.pagRegistration.lblCompany.NAME      = 'lblCompany'
   pgfSteps.pagRegistration.lblSerialNo.NAME     = 'lblSerialNo'
   pgfSteps.pagRegistration.txtCompany.NAME      = 'txtCompany'
   pgfSteps.pagRegistration.txtSerialno.NAME     = 'txtSerialno'
   pgfSteps.pagRegistration.NAME                 = 'pagRegistration'
   pgfSteps.pagPaths.cntLocalPath.txtPath.NAME   = 'txtPath'
   pgfSteps.pagPaths.cntLocalPath.Command1.NAME  = 'Command1'
   pgfSteps.pagPaths.cntLocalPath.NAME           = 'cntLocalPath'
   pgfSteps.pagPaths.lblLocal.NAME               = 'lblLocal'
   pgfSteps.pagPaths.lblShared.NAME              = 'lblShared'
   pgfSteps.pagPaths.lblCommon.NAME              = 'lblCommon'
   pgfSteps.pagPaths.Lbltext1.NAME               = 'Lbltext1'
   pgfSteps.pagPaths.cntSharedPath.txtPath.NAME  = 'txtPath'
   pgfSteps.pagPaths.cntSharedPath.Command1.NAME = 'Command1'
   pgfSteps.pagPaths.cntSharedPath.NAME          = 'cntSharedPath'
   pgfSteps.pagPaths.cntCommonPath.txtPath.NAME  = 'txtPath'
   pgfSteps.pagPaths.cntCommonPath.Command1.NAME = 'Command1'
   pgfSteps.pagPaths.cntCommonPath.NAME          = 'cntCommonPath'
   pgfSteps.pagPaths.NAME                        = 'pagPaths'
   pgfSteps.TOP                                  = 30
   pgfSteps.HEIGHT                               = 147
   pgfSteps.NAME                                 = 'pgfSteps'
   cmdBack.NAME                                  = 'cmdBack'
   cmdNext.NAME                                  = 'cmdNext'
   Lbllabel1.NAME                                = 'Lbllabel1'
   Command1.NAME                                 = 'Command1'


ENDDEFINE
*
*-- EndDefine: frminstalldialogcustom
**************************************************


**************************************************
*-- Class:        frmsplashscreencustom (c:\develop\_sherware\custom\capp.vcx)
*-- ParentClass:  frmsplashscreen (c:\develop\_sherware\common\cmsetup.vcx)
*-- BaseClass:    form
*-- Time Stamp:   06/08/03 01:38:06 AM
*
DEFINE CLASS frmsplashscreencustom AS frmsplashscreen


   DOCREATE      = .T.
   NAME          = 'frmsplashscreencustom'
   TIMER.NAME    = 'Timer'
   cmdClick.NAME = 'cmdClick'


ENDDEFINE
*
*-- EndDefine: frmsplashscreencustom
**************************************************


**************************************************
*-- Class:        frmviewtoolbarscustom (c:\develop\_sherware\custom\capp.vcx)
*-- ParentClass:  frmviewtoolbars (c:\develop\_sherware\common\cmdialog.vcx)
*-- BaseClass:    form
*-- Time Stamp:   06/08/03 01:38:13 AM
*
DEFINE CLASS frmviewtoolbarscustom AS frmviewtoolbars


   DOCREATE                               = .T.
   NAME                                   = 'frmviewtoolbarscustom'
   lstToolbars.NAME                       = 'lstToolbars'
   Cntokcancelapplycustom1.cmdok.NAME     = 'cmdok'
   Cntokcancelapplycustom1.cmdCancel.NAME = 'cmdCancel'
   Cntokcancelapplycustom1.cmdapply.NAME  = 'cmdapply'
   Cntokcancelapplycustom1.NAME           = 'Cntokcancelapplycustom1'


ENDDEFINE
*
*-- EndDefine: frmviewtoolbarscustom
**************************************************


**************************************************
*-- Class:        cmapplicationcustom (c:\develop\_sherware\custom\capp.vcx)
*-- ParentClass:  cmapplicationmanager (c:\develop\_sherware\common\cmapp.vcx)
*-- BaseClass:    custom
*-- Time Stamp:   02/24/21 10:55:06 AM
*
#INCLUDE "c:\develop\_sherware\source\appdefs.h"
*
DEFINE CLASS swapplicationcustom AS cmapplicationmanager


   HEIGHT = 91
   WIDTH  = 196
*-- Product Option Number 19=AMPRO, 20=DMPRO, 21=DMQB
   nproduct         = 19
   lreportmenu      = .F.
   apdata           = ''
   lapreports       = .F.
   lardata          = .F.
   larreports       = .F.
   lgldata          = .F.
   lglreports       = .F.
   lglfinancials    = .F.
   llanddata        = .F.
   llandreports     = .F.
   lpayrolldata     = .F.
   lpayrollreports  = .F.
   lrevdistdata     = .F.
   lrevdistreports  = .F.
   lbrinedata       = .F.
   lbrinereports    = .F.
   lafedata         = .F.
   lafereports      = .F.
   linvestdata      = .F.
   linvestreports   = .F.
   lcashdata        = .F.
   lcashreports     = .F.
   lcheckprinting   = .F.
   lreadonly        = .F.
   lhousegasdata    = .F.
   lhousegasreports = .F.
   ljibdata         = .F.
   ljibreports      = .F.
   ldoidata         = .F.
   lpartnerdata     = .F.
   lpartnerreports  = .F.
   ladmin           = .F.
   lnosecurity      = .F.
   lSendToAllocate  = .F.
*-- Stonefield Database Toolkit object
   ometa            = .NULL.
   ldemo            = .F.
   lpayrollopt      = .F.
   cclient          = ''
   ccode            = ''
   lapdata          = .F.
   lopeningfiles    = .F.
   cexecutable      = '6.0.0'
   cdemocode        = '0116-5490-7265-0060-806'
   cfullversion     = '6.0.0'
   llan5            = .F.
   llan10           = .F.
   llanunlimited    = .F.
   lnocallopencomp2 = .F.
   lclouddocs       = .F.
   dsupportexpires  = .F.
*-- .T. if we're in the development environment
   ldevelopmentenv    = .F.
   cproductname       = 'DM'
   lnologon           = .F.
   lnewcompany        = .F.
   lupdatefiles       = .F.
   lform1065reporting = .F.
   ladhocreporting    = .F.
   lgraphs            = .F.
   lonlinereporting   = .F.
   ldmpro             = .F.
   lamversion         = .T.
   ddirectdate        = 'DATE()'
*-- Don't call opencompany2
   lnoopencomp2 = .F.
*-- Set by opencompany1 if the .loc file has a valid cidcomp which is found in compmast.
   lvalidcompany  = .F.
   appdata_folder = ''
   cidcomp        = .NULL.
   ltestversion   = .F.
   cuser          = ''
   operflog       = .F.
*-- Path for Checks folder.
   cchecksfolder = 'checks\'
*-- Location of Rpts Folder
   crptsfolder      = 'rpts\'
   cdatabaseversion = '6.5.3'
   cqueryfolder     = 'swquery\'
   ccommonfolder    = 'datafiles\'
   ccompanyname     = ''
*-- Determines whether the autologon or just login dialog is used.
   lautologon     = .T.
   coffsiteserver = 'mail.sherware.com'
   lautologin     = .F.
*-- Table being opened...save for error processing
   ctablename    = ''
   cdatafilepath = 'datafiles\data\'
   oqb           = .NULL.
   lqbversion    = .F.
   lqboversion   = .F.
   clocalappdata = .F.
*-- Documents Feature?
   ldocuments = .F.
*-- Enhanced Land Module?
   lenhancedland = .F.
*-- Treeno Object created the first time Treeno is accessed
   otreeno        = .NULL.
   loffbackup     = .F.
   loffsitebackup = .F.
   cphoneno       = ''
*-- Allows certain processes to cancel processing when the ESC key is pressed.
   lcanceled        = .F.
   ldebugmode       = .F.
   lonlinereports   = .F.
   ccommondocuments = ''
*-- The name of the help file for this application.  Ex.  AMPRO.CHM
   helpfilename = ''
*-- Date of the most current help file.
   helpfiledate = {}
*-- Company Fax Number
   cfaxno = ''
*-- Company's email address
   cemail          = ''
   lmonthlysupport = .F.
   lmonthlylicense = .F.
   lohrpts         = .F.
   lwvrpts         = .F.
   lparpts         = .F.
   ltxrpts         = .F.
   lokrpts         = .F.
   lnyrpts         = .F.
   lwyrpts         = .F.
   lcorpts         = .F.
*-- Monthly Subscription Failed
   lexpired   = .F.
   cerrortext = 'Check the System Log found under the Help menu for more information.'
*-- State Codes
   cstates       = ''
   cregcompany   = ''
   oimport       = .NULL.
   limportmodule = .F.
   rushmoreopt   = .F.
*-- Object for the sfLogger object for intrumentation
   ologger     = .NULL.
   oreport     = .NULL.
   oscreenshot = .NULL.
   oupdate     = .NULL.
   nupdport    = 441
*-- The URL to send backups to SherWare support
   cbackupurl = 'cb.sherware.com'
*-- Has the URL of the update server to get updates.
   cupdateurl      = 'updates.sherware.com'
   formicon        = 'graphics\pivoten-icon.ico '
   lencrypted      = .F.
   cencryptionkey  = 'SherWareKey_@8@2899909'
   ltaxids         = .F.
   lbankinfo       = .F.
   lpluggingmodule = .F.
   lcloudserver    = .F.
   oglmaint        = .NULL.
   ldmversion      = .F.
   opartnership    = .NULL.
*-- Flag for signifying that the install has the new partnership module
   lpartnershipmod = .F.
*-- Distproc object created on first access.
   odist    = .NULL.
   ooptions = .NULL.
*-- EnergyLink Option
   lenergylink     = .F.
   lparentcompany  = .F.
   ljvmodule       = .F.
   cicon           = 'c:\develop\_sherware\graphics\pivoten-icon.ico'
   lsingleinstance = .T.
   cversion        = '6000'
   cbanner         = 'c:\develop\_SherWare\graphics\sherware.png'

* SherWare Financials Properties
   lFamilyApp         =  .F.
   lOperatorApp       =  .F.
   lOperatorPlusApp   =  .F.
   lEnterpriseApp     =  .F.

*Options
   lOptJIB           = .F.
   lOptLand          = .F.
   lOptDirDeposit    = .F.
   lOptMICR          = .F.
   lOptPlugging      = .F.
   lOptStateRpts     = .F.
   lOptQBO           = .F.
   lOptQBD           = .F.
   lOptHG            = .F.
   lOptAdvRpts       = .F.
   lOpt1099K1        = .F.
   lOptSilverSupport = .F.
   lOptGoldSupport   = .F.
   lOptPlatSupport   = .F.
   lOptInvPortal     = .F.
   lOptBrineHauler   = .F.
   lOptAFE           = .F.
   lOptPartnership   = .F.
   lOptPayroll       = .F.
   lOptLiveVersion   = .F.

* Traditional Menus
   lTradMenu  = .F.

* License Counts
   nWells     = 0
   nUsers     = 0
   nTrans     = 0
   nCompanies = 0

   XFRXVersion = '22_2'

   NAME = 'cmapplicationcustom'

*-- Turns the FoxAudit audit trail on or off globally.
   laudittrail = .T.

*-- Investment Manager Version
   limversion = .F.

**********************************
   PROCEDURE ConfigReg
**********************************
      LPARAMETERS tlReading, tlNoRenew
      LOCAL lcOpt, oReg, lcCode, lcClient, lnClient, lnCode, lnFile, lcCompany
      LOCAL lcProduct, ldDate
      LOCAL llReturn, lnlen, loError

      THIS.LogCodePath(.T.,'CAPP:ConfigReg')

*   #include SOURCE\appdefs.h
      llReturn = .T.

      TRY
         SET PROCEDURE TO CUSTOM\swregcode.prg ADDITIVE
         oReg = CREATEOBJECT('swregcode', THIS.ccommonfolder)
******************************************
*  Check for existence of Config File
******************************************
         IF NOT FILE(THIS.ccommonfolder + 'swconfig.cfg')
            THIS.lFamilyApp         = .F.
            THIS.lOperatorApp       = .F.
            THIS.lOperatorPlusApp   = .F.
            THIS.lEnterpriseApp     = .T.

            THIS.lOptJIB           = .F.
            THIS.lOptLand          = .F.
            THIS.lOptDirDeposit    = .T.
            THIS.lOptMICR          = .F.
            THIS.lOptPlugging      = .F.
            THIS.lOptStateRpts     = .F.
            THIS.lOptQBO           = .F.
            THIS.lOptQBD           = .F.
            THIS.lOptHG            = .F.
            THIS.lOptAdvRpts       = .F.
            THIS.lOpt1099K1        = .F.
            THIS.lOptSilverSupport = .T.
            THIS.lOptGoldSupport   = .F.
            THIS.lOptPlatSupport   = .F.
            THIS.lOptInvPortal     = .F.
            THIS.lOptBrineHauler   = .F.
            THIS.lOptAFE           = .F.
            THIS.lOptPayroll       = .F.
            THIS.lOptLiveVersion   = .F.

            THIS.nWells     = 5
            THIS.nUsers     = 1
            THIS.nTrans     = 100
            THIS.nCompanies = 1

            lcCode    = THIS.cdemocode
            lcClient  = '9999'
            lcCompany = 'Sample Company'
            lcCompany = PADR(lcCompany, 40, ' ')
            lnClient  = INT(VAL(lcClient))
            oReg.writecode(lnClient, lcCode, lcCompany)
            ldDate    = oReg.SFCheckSum(lnClient, lcCode, .F., .T.)

         ELSE

            THIS.lFamilyApp         = oReg.GetSFOpt(Family_App)
            THIS.lOperatorApp       = oReg.GetSFOpt(Operator_App)
            THIS.lOperatorPlusApp   = oReg.GetSFOpt(OperatorPlus_App)
            THIS.lEnterpriseApp     = oReg.GetSFOpt(Enterprise_App)

            THIS.lOptJIB           = oReg.GetSFOpt(optJIB)
            THIS.lOptLand          = oReg.GetSFOpt(optLand)
            THIS.lOptDirDeposit    = oReg.GetSFOpt(optDirDeposit)
            THIS.lOptMICR          = oReg.GetSFOpt(optMICR)
            THIS.lOptPlugging      = oReg.GetSFOpt(optPlugging)
            THIS.lOptStateRpts     = oReg.GetSFOpt(optStateRpts)
            THIS.lOptQBO           = oReg.GetSFOpt(optQBO)
            THIS.lOptQBD           = oReg.GetSFOpt(optQBD)
            THIS.lOptHG            = oReg.GetSFOpt(optHG)
            THIS.lOptAdvRpts       = oReg.GetSFOpt(optAdvRpts)
            THIS.lOpt1099K1        = oReg.GetSFOpt(opt1099K1)
            THIS.lOptSilverSupport = oReg.GetSFOpt(optSilverSupport)
            THIS.lOptGoldSupport   = oReg.GetSFOpt(optGoldSupport)
            THIS.lOptPlatSupport   = oReg.GetSFOpt(optPlatSupport)
            THIS.lOptInvPortal     = oReg.GetSFOpt(optInvPortal)
            THIS.lOptBrineHauler   = oReg.GetSFOpt(optBrineHauler)
            THIS.lOptAFE           = oReg.GetSFOpt(optAFE)
            THIS.lOptPayroll       = oReg.GetSFOpt(optPayroll)
            THIS.lOptLiveVersion   = oReg.GetSFOpt(optLiveVersion)

            THIS.nWells     = oReg.GetSFCode(optNumWells)
            THIS.nUsers     = oReg.GetSFCode(optNumUsers)
            THIS.nTrans     = oReg.GetSFCode(optNumTrans)
            THIS.nCompanies = oReg.GetSFCode(optNumCompanies)

            lcClient  = PADL(ALLTRIM(TRANSFORM(oReg.GetSFCode(1))), 4, '0')
            lcCode    = TRANSFORM(oReg.GetSFCode(2))
            lcCompany = oReg.GetSFCode(3)

            THIS.lqboversion = THIS.lOptQBO
            THIS.lqbversion  = THIS.lOptQBD

            TRY
               IF THIS.lmonthlysupport
                  lcDate = oReg.GetSFSupportStatus(lcClient)
                  ldDate = CTOD(lcDate)
                  IF ldDate - DATE() < - 10
                     MESSAGEBOX('Your monthly support subscription expired: ' + lcDate + ' Please contact SherWare support to renew.', 48, 'Support Expired')
                  ENDIF
               ENDIF
            CATCH TO loError
               DO errorlog WITH 'ConfigReg-Monthly-Support', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
            ENDTRY

            TRY
               IF THIS.lmonthlylicense
                  lcDate = oReg.GetSFLicenseStatus(lcClient)
                  ldDate = CTOD(lcDate)
                  IF ldDate < DATE()
                     MESSAGEBOX('Your monthly subscription expired: ' + lcDate + CHR(13) + CHR(10) + ' Please contact SherWare support to renew.', 48, 'Support Expired')
                     THIS.lexpired = .T.
                     THIS.ldemo    = .T.
                  ENDIF
               ENDIF
            CATCH TO loError
               DO errorlog WITH 'ConfigReg-Monthly-License', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
            ENDTRY
         ENDIF

         IF NOT '-' $ lcCode
            lnlen = LEN(ALLTRIM(lcCode))
            DO CASE
               CASE lnlen > 16
                  lcCode = SUBSTR(lcCode, 1, 4) + '-' + ;
                     SUBSTR(lcCode, 5, 4) + '-' + ;
                     SUBSTR(lcCode, 9, 4) + '-' + ;
                     SUBSTR(lcCode, 13, 4) + '-' + ;
                     SUBSTR(lcCode, 17)
               CASE lnlen < 16
                  lcCode = SUBSTR(lcCode, 1, 4) + '-' + ;
                     SUBSTR(lcCode, 5, 4) + '-' + ;
                     SUBSTR(lcCode, 9, 4) + '-' + ;
                     SUBSTR(lcCode, 13)
            ENDCASE
         ENDIF
         THIS.cclient     = lcClient
         THIS.ccode       = lcCode
         THIS.cregcompany = lcCompany


* Set up the product name
         DO CASE
            CASE THIS.lFamilyApp
               THIS.cproductname = 'SherWare Financials Family Edition'
            CASE THIS.lOperatorApp
               THIS.cproductname = 'SherWare Financials Operator Edition'
            CASE THIS.lOperatorPlusApp AND THIS.lOptQBO
               THIS.cproductname = 'SherWare Financials Operator Plus QBO Edition'
            CASE THIS.lOperatorPlusApp AND THIS.lOptQBD
               THIS.cproductname = 'SherWare Financials Operator Plus QBD Edition'
            CASE THIS.lOperatorPlusApp
               THIS.cproductname = 'SherWare Financials Operator Plus Edition'
            CASE THIS.lEnterpriseApp AND THIS.lOptQBO
               THIS.cproductname = 'SherWare Financials Enterprise QBO Edition'
            CASE THIS.lEnterpriseApp AND THIS.lOptQBD
               THIS.cproductname = 'SherWare Financials Enterprise QBD Edition'
            CASE THIS.lEnterpriseApp
               THIS.cproductname = 'SherWare Financials Enterprise Edition'
            OTHERWISE
               THIS.cproductname = 'SherWare Financials'
         ENDCASE

         IF NOT tlReading
            IF NOT THIS.ltestversion
               IF THIS.ldemo
                  THIS.SetScreenCaption()
                  MESSAGEBOX('The application has started in demonstration mode. ' + CHR(10) + CHR(10) + ;
                     'Please contact Pivoten sales when you are ready to ' + CHR(10) + ;
                     'purchase and activate the live version.  If you have ' + CHR(10) + ;
                     'already purchased the software, enter the registration ' + CHR(10) + ;
                     'code you received under the file menu to take the software ' + CHR(10) + ;
                     'out of demonstration mode.', 64, 'Demo Mode')
               ELSE
                  THIS.SetScreenCaption()
               ENDIF
            ENDIF
         ENDIF

         IF llReturn

            lcExpires = THIS.checksupportexp()
            THIS.dsupportexpires = CTOD(lcExpires)

            TRY
               IF NOT tlNoRenew
* Check to see if the reg code needs to be updated

* Renew it if the expiration date of the current code
* is within 60 days of today's date.
                  IF CTOD(lcExpires) - 60 < DATE()
                     oReg.RenewCode(.F., lcExpires)
                  ENDIF
               ENDIF
            CATCH
            ENDTRY

            oReg = NULL
            RELEASE oReg

* Log the client info to our server
            THIS.LogClientInfo()
            THIS.LogUsage()
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'ConfigReg', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the Pivoten Registry at this time.' + CHR(10) + ;
            'Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE Set_Reg_Keys
**********************************
      LPARA tlReset
      PRIV lcValue

      LOCAL laFiles[1], lcValue, lcidcomp, llReturn, lnFile, loError
      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:Set_Reg_Keys')

*   #include common\win32.h
      TRY
         lcValue = ''

         IF tlReset
* Reset keys to data\ folder
            cmRegGetValue(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Local', @lcValue)
            lcValue = STRTRAN(lcValue, '\\', '\', 2)
            cmRegSetString(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Local', ALLT(lcValue))
            cmRegSetString(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Shared', ALLT(lcValue) + 'Datafiles\Data\')
            cmRegSetString(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Common', ALLT(lcValue) + 'Datafiles\Data\')
         ELSE
* Set keys to current company's data folder
            cmRegSetString(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Shared', ALLT(THIS.cdatafilepath))
            cmRegSetString(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Common', ALLT(THIS.cdatafilepath))
*            THIS.closealldata()
            cmRegGetValue(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Local', @lcValue)
         ENDIF

*   THIS.setsearchpath()
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'Set_Reg_Keys', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE Logon
**********************************
      LOCAL llSuccess
      LOCAL loError, lcidcomp

      llSuccess = .F.

      THIS.LogCodePath(.T.,'CAPP:Logon')

      IF VARTYPE(THIS.osecurity) # 'O'
         RETURN .F.
      ENDIF

      TRY

* Check for the existence of the security semaphore file
* If it exists, don't ask for a logon
         IF FILE(THIS.ccommonfolder + 'swi1215.cfg')
            THIS.lnosecurity = .T.
         ELSE
            THIS.lnosecurity = .F.
         ENDIF

* Set the default to not use the eventlog
         THIS.osecurity.leventlogenabled = .F.

* Require successful logon before application may continue.
* If you dont care about security issues, you can remove this line.
         IF NOT THIS.ldemo
            THIS.osecurity.cLogonDialogClass = 'swForms.frmLogon'
            IF THIS.lautologon
               llSuccess = THIS.osecurity.LogonDialog()
            ELSE
               llSuccess       = THIS.osecurity.LogonDialog()
               THIS.lautologon = .T.
            ENDIF

            IF THIS.lnosecurity
               THIS.cuser = 'ADMIN'
            ELSE
               THIS.cuser  = THIS.osecurity.GetUserProperty('User')
               IF EMPTY(THIS.cuser)
                  THIS.cuser = 'ADMIN'
               ENDIF
            ENDIF
            IF llSuccess
               THIS.SetPrivileges()
            ENDIF
         ELSE
            llSuccess  = .T.
            THIS.cuser = 'Admin'
            WITH THIS
               STORE .T. TO .lafedata, .lafereports, .lapdata, .lapreports, .lardata, .larreports
               STORE .T. TO .lgldata, .lglreports, .lglfinancials, .llanddata, .llandreports
               STORE .T. TO .lbrinedata, .lbrinereports, .lcashdata, .lcashreports, .lcheckprinting
               STORE .T. TO .lrevdistdata, .lrevdistreports, .ljibdata, .ljibreports
               STORE .T. TO .ladmin, .linvestdata, .linvestreports, .lreportmenu
               STORE .T. TO .lhousegasdata, .lhousegasreports, .lpartnerdata, .lpartnerreports
               STORE .T. TO .lpayrolldata, .lpayrollreports, .ldoidata
               STORE .T. TO .lgraphs, .ladhocreporting, .lform1065reporting
               STORE .T. TO .loffsitebackup, .lonlinereporting
               STORE .F. TO .lreadonly
            ENDWITH

            THIS.osecurity.cLogonDialogClass = 'swForms.frmLogon'
            llSuccess                        = THIS.osecurity.LogonDialog()
            THIS.lautologon                  = .T.

         ENDIF
      CATCH TO loError
         llSuccess = .F.
         DO errorlog WITH 'Logon', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to login at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
      ENDTRY

      IF llSuccess
         IF INLIST(UPPER(THIS.cuser), 'ADMIN', 'DEVELOPER')
            THIS.osecurity.SetPrivilege('Administrator', .T., .T.)
         ENDIF
* Erase the last open company file
         lnFile = ADIR(laFiles, THIS.ccommondocuments + '*.loc')
         IF lnFile > 0
            FOR x = 1 TO lnFile
               TRY
                  ERASE (THIS.ccommondocuments + laFiles[x, 1])
               CATCH
               ENDTRY
            ENDFOR
         ENDIF

         lcidcomp = THIS.cidcomp

         IF VARTYPE(lcidcomp) # 'C'
            lcidcomp = 'x    '
         ENDIF

* Create the last open company file
         IF NOT FILE(THIS.ccommondocuments + lcidcomp + '.loc')
            fh = FCREATE(THIS.ccommondocuments + lcidcomp + '.loc')
            FCLOSE(fh)
         ENDIF


      ENDIF

      RETURN llSuccess
   ENDPROC

**********************************
   PROCEDURE AddToMenu
**********************************
      LPARAMETERS loMenu
      LOCAL lnBarNo, lcAction, lcPath, lnPads
      LOCAL lcBarPrompt, lcMenu, llReturn, loError

      THIS.LogCodePath(.T.,'CAPP:AddToMenu')

      IF FILE('datafiles\menudebug.txt')
         llDebug = .T.
      ELSE
         llDebug = .F.
      ENDIF
      llReturn = .T.

      STORE .F. TO llTasks, llReports
      TRY
*
* Adds custom tasks and custom reports to the custom menupads
* of the Tasks and Reports menus. The new menu pads are defined
* in the menupads table
*
         lcPath = ALLT(THIS.cdatafilepath)

         IF NOT FILE(THIS.cdatafilepath + 'appdata.dbc')
            llReturn = .F.
            EXIT
         ENDIF

* Remove the custom menu bars if they exist
         IF VARTYPE(oMenu.Tasks.CustomTasks) = 'O'
            oMenu.Tasks.CustomTasks.HIDE()
         ENDIF
         IF VARTYPE(oMenu.Reports.CustomReports) = 'O'
            oMenu.Reports.CustomReports.HIDE()
         ENDIF

         swselect('menupads')
         SET ORDER TO cMenu
         SELECT cMenu FROM menupads INTO CURSOR tempmenu ORDER BY cMenu GROUP BY cMenu

         SELECT tempmenu
         SCAN
            m.cMenu = cMenu

            IF llDebug
               WAIT WINDOW 'Adding menu: ' + m.cMenu
            ENDIF
            DO CASE
               CASE 'TASK' $ UPPER(m.cMenu)
* Add the menu bar again
                  oMenu.Tasks.AddSeparatorbar()
                  oMenu.Tasks.AddBar('SFBar', '', 'CustomTasks')
                  oMenu.Tasks.CustomTasks.cCaption = [Custom Tasks]

               CASE 'REPO' $ UPPER(m.cMenu)
* Add the menu bar again
                  oMenu.Reports.AddSeparatorbar()
                  oMenu.Reports.AddBar('SFBar', '', 'CustomReports')
                  oMenu.Reports.CustomReports.cCaption = [Custom Reports]

            ENDCASE

            TRY
               SELECT menupads
               SCAN FOR cMenu = m.cMenu
                  SCATTER MEMVAR

                  lcAction    = ALLT(m.cMenuCmd)
                  lcMenu      = ALLT(m.cMenu)
                  lcBarPrompt = ALLT(m.cBarPrompt)
                  lcBar       = STRTRAN(lcBarPrompt, ' ', '_')
                  lcBar       = STRTRAN(lcBar, '/', '')
                  lcBar       = STRTRAN(lcBar, '.', '')
                  lcBar       = STRTRAN(lcBar, ')', '')
                  lcBar       = STRTRAN(lcBar, '(', '')

                  IF llDebug
                     WAIT WINDOW 'Adding pad: ' + lcBar + ' to the ' + m.cMenu + ' menu.'
                  ENDIF

* Wrap error handling around the actual menu processing
                  DO CASE
                     CASE 'TASK' $ UPPER(m.cMenu)
                        IF lcBar = '\-'
                           oMenu.Tasks.CustomTasks.AddSeparatorbar()
                           LOOP
                        ELSE
                           loBar = oMenu.Tasks.CustomTasks.AddBar('SFBar', '', lcBar)
                        ENDIF

                        llTasks = .T.
                     CASE 'REPO' $ UPPER(m.cMenu)
                        IF lcBar = '\-'
                           oMenu.Reports.CustomReports.AddSeparatorbar()
                           LOOP
                        ELSE
                           loBar = oMenu.Reports.CustomReports.AddBar('SFBar', '', lcBar)
                        ENDIF

                        llReports = .T.
                     OTHERWISE
                        loBar = .NULL.
                  ENDCASE

                  IF VARTYPE(loBar) = 'O'
                     loBar.cCaption        = lcBarPrompt
                     loBar.cOnClickCommand = lcAction
                  ENDIF

               ENDSCAN
            CATCH TO loError
               IF llDebug
                  WAIT WINDOW NOWAIT 'Error: ' + loError.MESSAGE + ' Line: ' + TRANSFORM(loError.LINENO)
               ENDIF
               IF loError.ERRORNO = 165
                  SELECT menupads
                  GO BOTT
               ENDIF
            FINALLY
            ENDTRY
         ENDSCAN

         WAIT CLEAR

* Now show the new custom menus
         IF llTasks
            oMenu.Tasks.CustomTasks.SHOW()
         ENDIF
         IF llReports
            oMenu.Reports.CustomReports.SHOW()
         ENDIF

         USE IN menupads
      CATCH TO loError
         IF llDebug
            WAIT WINDOW NOWAIT 'Error: ' + loError.MESSAGE + ' Line: ' + TRANSFORM(loError.LINENO)
         ENDIF
         llReturn = .F.
         DO errorlog WITH 'AddToMenu', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE UpdateTables
**********************************
      LPARA tcidcomp, tlAll, tcFile, tlMenu
*
*  Called by opencompany to see what files, if any need updated.
*
      LOCAL lnx, lny, lcFile, laFiles[1], lcProducer
      LOCAL latemp[1], lcDataVersion, lcTable, lcd, lcdataFilePath, lcdatabase, llError, llReturn
      LOCAL lnHandle, loError
*:Global cVersion, jcVersion, tlAll

      llReturn = .T.
      THIS.LogCodePath(.T.,'CAPP:UpdateTables')

      TRY
         IF NOT USED('compmast')
            USE (THIS.ccommonfolder + 'compmast') IN 0
         ENDIF

         SELE compmast
         LOCATE FOR UPPER(cidcomp) == UPPER(PADR(tcidcomp, 8, ' '))
         IF FOUND()
            lcdataFilePath = ALLT(cdatapath)
            lcProducer     = ALLT(cproducer)
         ELSE
            llReturn = .F.
            EXIT
         ENDIF

* Create the SDT object
         jcVersion = STRTRAN(THIS.cfileversion, '.', '')

         IF FILE(lcdataFilePath + 'version.dbf')
            USE (lcdataFilePath + 'version.dbf') IN 0
            SELECT VERSION
            GO TOP
            lcDataVersion = cversion
            USE IN VERSION
            IF compmast.cversion # lcDataVersion
               SELECT compmast
               REPLACE cversion WITH lcDataVersion
            ENDIF
         ELSE
            IF NOT USED('compmast')
               USE (THIS.ccommonfolder + 'compmast') IN 0
            ENDIF
            SELECT compmast
            SCATTER MEMVAR
            lnx     = AFIELDS(latemp)
            lcTable = lcdataFilePath + 'version'
            CREATE TABLE (lcTable) FREE FROM ARRAY latemp
            m.cversion = jcVersion
            INSERT INTO VERSION FROM MEMVAR
            USE IN VERSION
            lcDataVersion = compmast.cversion
         ENDIF

* Close all tables
         THIS.closealldata()

* Reformat the version with periods
         lcDataVersion = SUBSTR(lcDataVersion, 1, 1) + '.' + ;
            SUBSTR(lcDataVersion, 2, 1) + '.' + ;
            SUBSTR(lcDataVersion, 3, 1)


         tlAll = .T.

* If tlAll is true, update all tables
         IF tlAll
            IF DIRECTORY(lcdataFilePath)
* Development environment stuff - pws 2/15/09
               TRY
                  IF VERSION(2) = 2
                     lcd = LOWER(CURDIR())
                     DO CASE
                        CASE 'am' $ lcd
                           USE newdbc\newdbc.DBC IN 0
                        CASE 'dm' $ lcd
                           USE newdbc\newdbc.DBC IN 0
                        CASE 'dmie' $ lcd
                           USE newdbc\newdbc.DBC IN 0
                        CASE THIS.limversion
                           USE newdbc\newdbc.DBC IN 0
                        OTHERWISE
                           USE newdbc.DBC IN 0
                     ENDCASE
                  ELSE
                     USE newdbc.DBC IN 0
                  ENDIF
               CATCH
               ENDTRY

               IF NOT isfilelocked(lcdataFilePath + 'appdata.dbc')
                  SET SAFETY OFF
                  llError = .F.
* Attempt to copy in the new database container
                  TRY
                     UpdateDBC(lcdataFilePath)
                     swclose('newdbc')
                  CATCH TO loError
* Unable to do the copy. Tell the user about it and set the error flag
                     IF loError.ERRORNO = 1705 OR loError.ERRORNO = 108
                        IF tlMenu
                           MESSAGEBOX('Unable to update the database files to the new version. ' + CHR(10) + CHR(10) + ;
                              'Another user has this company open on their workstation ' + CHR(10) + ;
                              'Have them close out of the Accounting Manager and try again.', 48, 'Update Files')
                        ENDIF

                        llError = .T.
                     ELSE
                        DO errorlog WITH 'UpdateTables', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
                        MESSAGEBOX('Unable to update the company at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                           'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
                        llError = .T.
                     ENDIF
                  FINALLY
                  ENDTRY

* If we encountered an error during the copy bail out.
                  IF llError
                     llReturn = .F.
                     EXIT
                  ENDIF

                  TRY
                     lcdatabase = TRIM(THIS.cdatafilepath) + 'AppData'
                     THIS.opensdt()
                     OPEN DATABASE (lcdatabase)
                     ometa.lSuppressErrors = .T.
                     ometa.setdatabase(DBC())
                     ometa.oSDTMgr.lQuiet = NOT tlMenu
                     IF ometa.oSDTMgr.NeedUpdate('Appdata!')
                        WAIT WIND NOWAIT 'Updating Files For ' + ALLTRIM(THIS.ccompanyname) + '.  Please Wait...'
                        ometa.oSDTMgr.lQuiet = .F.
                        IF NOT ometa.oSDTMgr.UPDATE('ALL')
                           IF tlMenu
                              MESSAGEBOX('Unable to update the files for: ' + ALLTRIM(THIS.ccompanyname) + CHR(13) + ;
                                 TRANSFORM(ometa.aErrorInfo[1, 2]) + ': ' + CHR(13) + ;
                                 TRANSFORM(ometa.aErrorInfo[1, 3]), 16, 'Update Company Problem')
                           ENDIF
                        ENDIF
                     ENDIF
                     ometa.oSDTMgr.lQuiet = .F.
                  CATCH TO loError
                     DO errorlog WITH 'UpdateTables', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
                     MESSAGEBOX('Unable to update files at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
                        'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
                  ENDTRY
                  swselect('compmast')
                  LOCATE FOR UPPER(cidcomp) == UPPER(tcidcomp)
                  IF FOUND()
                     REPL LUPDATE WITH .F., ;
                        cversion WITH STRTRAN(TRANSFORM(THIS.cdatabaseversion), '.', '')
                  ENDIF
                  IF FILE(lcdataFilePath + 'version.dbf')
                     USE (lcdataFilePath + 'version') IN 0
                     SELECT VERSION
                     GO TOP
                     REPLACE cversion WITH STRTRAN(TRANSFORM(THIS.cdatabaseversion), '.', '')
                     USE IN VERSION
                  ELSE
                     IF NOT USED('compmast')
                        USE (THIS.ccommonfolder + 'compmast') IN 0
                     ENDIF
                     SELECT compmast
                     SCATTER MEMVAR
                     lnx     = AFIELDS(latemp)
                     lcTable = lcdataFilePath + 'version'
                     CREATE TABLE (lcTable) FREE FROM ARRAY latemp
                     m.cversion = STRTRAN(TRANSFORM(THIS.cdatabaseversion), '.', '')
                     INSERT INTO VERSION FROM MEMVAR
                     USE IN VERSION
                  ENDIF
               ELSE
                  IF tlMenu
                     MESSAGEBOX('This company appears to be open on another workstation. ' + CHR(10) + CHR(10) + ;
                        'Close the company files on all workstations and then choose ' + CHR(10) + ;
                        'Update Files from the Utilities menu.', 48, 'Unable to Update')
                  ENDIF
               ENDIF
            ENDIF
            llReturn = .T.
            EXIT
         ELSE

* Not updating all tables, so get list of tables to update
            lnx = ADIR(laFiles, ALLT(CURDIR()) + '*.SWI')

            IF lnx > 0 OR VARTYPE(tcFile) = 'C'
               IF DIRECTORY(lcdataFilePath)
                  TRY
                     USE newdbc.DBC IN 0
                     SELECT newdbc
                     COPY TO (lcdataFilePath + 'appdata.dbc')
                     USE IN newdbc
                     lnHandle = FOPEN(lcdataFilePath + 'appdata.dbc', 2)
                     = FSEEK(lnHandle, 28)
                     = FWRITE(lnHandle, CHR(7))
                     = FCLOSE(lnHandle)
                     USE (lcdataFilePath + 'appdata.dbc') IN 0 EXCL
                     SELECT appdata
                     REINDEX
                     USE
                  CATCH
                  FINALLY
                  ENDTRY
               ENDIF

               lcdatabase = TRIM(THIS.cdatafilepath) + 'AppData'

               THIS.opensdt()
               OPEN DATABASE (lcdatabase)
               ometa.setdatabase(DBC())

               IF VARTYPE(tcFile) = 'C'
                  ometa.lSuppressErrors = .T.
                  IF NOT ometa.oSDTMgr.UPDATE(tcFile)
                     MESSAGEBOX('Unable to the file: ' + tcFile + CHR(13) + ;
                        ometa.aErrorInfo[1, 2] + ': ' + CHR(13) + ;
                        ometa.aErrorInfo[1, 3], 16, 'Update Company Problem')
                  ENDIF
               ELSE
* Change all file names to uppercase
                  FOR lny = 1 TO lnx
                     laFiles[lny, 1] = UPPER(laFiles[lny, 1])
                  ENDFOR

                  lny = 0
*  Look for an update file for updating all files.
                  lny = ASCAN(laFiles, 'ALL.SWI')

                  IF lny > 0
* Update all tables
                     ometa.lSuppressErrors = .T.
                     IF NOT ometa.oSDTMgr.UPDATE('ALL')
                        MESSAGEBOX('Unable to update the files for: ' + ALLTRIM(THIS.ccompanyname) + CHR(13) + ;
                           ometa.aErrorInfo[1, 2] + ': ' + CHR(13) + ;
                           ometa.aErrorInfo[1, 3], 16, 'Update Company Problem')
                     ENDIF
                  ELSE
* Update the individual tables
                     FOR lny = 1 TO lnx
                        lcFile = JUSTSTEM(laFiles[lny, 1])
                        WAIT WIND 'Updating table: ' + lcFile
                        ometa.oSDTMgr.UPDATE(lcFile)
                        ERASE laFiles[lny, 1]
                     ENDFOR
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'UpdateTables', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE REINDEX
**********************************
      LOCAL lcidcomp
      LOCAL lcdatabase, llReturn, loError

      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:Reindex')

      TRY
         lcidcomp = THIS.cidcomp

         IF NOT USED('compmast')
            USE (THIS.ccommonfolder + 'compmast') IN 0
         ENDIF
         SELE compmast
         LOCATE FOR cidcomp = lcidcomp
         IF FOUND()
            IF EMPTY(compmast.dreindex)
               REPL compmast.dreindex WITH {01/01/1980}
            ENDIF
            IF (DATE() - compmast.dreindex) > 7
               IF THIS.omessage.CONFIRM('It has been over 7 days since the files were indexed. Index them now?')
                  lcdatabase = TRIM(THIS.cdatafilepath) + 'AppData'

                  THIS.closealldata()
                  OPEN DATABASE (lcdatabase)
                  ometa.setdatabase(DBC())
                  ometa.lSuppressErrors = .T.
                  IF NOT ometa.oSDTMgr.REINDEX('ALL')
                     MESSAGEBOX('Unable to index the files for: ' + ALLTRIM(THIS.ccompanyname) + CHR(13) + ;
                        ometa.aErrorInfo[1, 2] + ': ' + CHR(13) + ;
                        ometa.aErrorInfo[1, 3], 16, 'Index File Problem')
                  ENDIF
                  IF NOT USED('compmast')
                     USE (THIS.ccommonfolder + 'compmast') IN 0
                  ENDIF
                  SELE compmast
                  LOCATE FOR cidcomp = lcidcomp
                  REPL dreindex WITH DATE()
               ENDIF
            ENDIF
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'Reindex', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to reindex the files at this time. ' + CHR(10) + CHR(10) + ;
            'Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE CleanDBFs
**********************************
*
* Removes tables from executable directory that shouldn't be there.
* Gets list of tables in data folder because none of them should
* exist in the executable folder.
*
* Not used anymore 1/4/17
      RETURN .T.

      LOCAL laFiles[1], lcFile, llReturn, lnFiles, lnx, loError
      llReturn = .T.

      TRY

         IF NOT DIRECTORY('data')
            llReturn = .F.
         ENDIF

         lnFiles = ADIR(laFiles, THIS.ccommonfolder + 'data\*.dbf')

         FOR lnx = 1 TO lnFiles
            lcFile = LOWER(ALLT(STRTRAN(LOWER(laFiles[lnx, 1]), '.dbf', '')))
            IF lcFile # 'appreg02' AND lcFile # 'compmast'
               ERASE (lcFile + '.dbf')
               ERASE (lcFile + '.cdx')
               ERASE (lcFile + '.fpt')
            ENDIF
         ENDFOR
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'CleanDBFS', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE ResetCounters
**********************************
      LPARAMETERS tlMenu
      LOCAL oregistry, omessage, oCounter, lcPath
      LOCAL lcBatch, lcDB, lckey

      THIS.LogCodePath(.T.,'CAPP:ResetCounters')

*
* Resets the Codemine registry counters to their next available value
*
      WAIT WIND NOWAIT 'Resetting Counters....Please Wait'
      THIS.closealldata()
      SET DELETED ON

      lcPath = ALLT(THIS.cdatafilepath)
      lcDB   = ALLT(THIS.cdatafilepath) + 'appdata'
      OPEN DATABASE (lcDB)

      USE (lcPath + 'appreg01') IN 0 ALIAS cmregistry

      oregistry = THIS.oregistry
      omessage  = THIS.omessage

*********************************
* 1099key
*********************************

* Lock the counter so no other users can access it.
      oCounter = oregistry.LockCounter('%Shared.Counters.1099Key')

      TRY
* Open the table
         USE (lcPath + 'tax1099') IN 0
* Find the highest used key value in the table
         SELE tax1099
         SET ORDER TO cidtax1
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF tax1099.cidtax1 >= m.cCounterValue
            m.ccounter    = '1099key'
            m.filecounter = tax1099.cidtax1
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar
* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, tax1099.cidtax1)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN tax1099
      CATCH
      ENDTRY
*********************************
* AFEDET
*********************************
* Open the table
      TRY
         USE (lcPath + 'afedet') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.afedet')

* Find the highest used key value in the table
         SELE afedet
         SET ORDER TO cidafed
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF afedet.cidafed >= m.cCounterValue
            m.ccounter    = 'afedet'
            m.filecounter = afedet.cidafed
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar
* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, afedet.cidafed)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN afedet
      CATCH
      ENDTRY

*********************************
* AFEHDR
*********************************
* Open the table
      TRY
         USE (lcPath + 'afehdr') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.afehdr')

* Find the highest used key value in the table
         SELE afehdr
         SET ORDER TO cidafeh
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF afehdr.cidafeh >= m.cCounterValue
            m.ccounter    = 'afehdr'
            m.filecounter = afehdr.cidafeh
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar
* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, afehdr.cidafeh)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN afehdr
      CATCH
      ENDTRY

*********************************
* AnnProd
*********************************
* Open the table
      TRY
         USE (lcPath + 'annprod') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.annprod')

* Find the highest used key value in the table
         SELE annprod
         SET ORDER TO cidannp
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF annprod.cidannp >= m.cCounterValue
            m.ccounter    = 'annprod'
            m.filecounter = annprod.cidannp
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar
* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, annprod.cidannp)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN annprod
      CATCH
      ENDTRY
*********************************
* AP Payment Detail
*********************************
* Open the table
      IF NOT THIS.lqbversion  &&  Appmtdet not in DMIE database
         TRY
            USE (lcPath + 'appmtdet') IN 0
* Lock the counter so no other users can access it.
            oCounter = oregistry.LockCounter('%Shared.Counters.AP Payment Detail')

* Find the highest used key value in the table
            SELE appmtdet
            SET ORDER TO cidarpmd
            GO BOTT

* Get the next value of the counter key
            m.cCounterValue = oregistry.GetCounter(oCounter)

            IF appmtdet.cidappmd >= m.cCounterValue
               m.ccounter    = 'AP Payment Detail'
               m.filecounter = appmtdet.cidappmd
               m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar
* Table is out of sync with the counter, so update it.
               oregistry.SetCounter(oCounter, appmtdet.cidappmd)
               oregistry.UpdateCounter(oCounter)
            ENDIF

            oregistry.UnlockCounter(oCounter)
            USE IN appmtdet
         CATCH
         ENDTRY
      ENDIF
*********************************
* AR Payment Detail
*********************************
* Open the table
      TRY
         USE (lcPath + 'arpmtdet') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.AR Payment Detail')

* Find the highest used key value in the table
         SELE arpmtdet
         SET ORDER TO cidarpmd
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF arpmtdet.cidarpmd >= m.cCounterValue
            m.ccounter    = 'AR Payment Detail'
            m.filecounter = arpmtdet.cidarpmd
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, arpmtdet.cidarpmd)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN arpmtdet
      CATCH
      ENDTRY

*********************************
* Batch
*********************************
      lcBatch = ''

* Open the table
      IF THIS.lamversion
         TRY
            USE (lcPath + 'glmaster')
            SET ORDER TO glbatch
            GO BOTT
            IF LEFT(cbatch, 1) # '0'
               DO WHILE NOT BOF() AND LEFT(cbatch, 1) # '0'
                  SKIP - 1
               ENDDO
            ENDIF
            lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
         CATCH
         ENDTRY

         TRY
            USE (lcPath + 'gljourn')
            SET FILT TO LEFT(cbatch, 1) = '0'
            SET ORDER TO BATCH
            GO BOTT
            IF gljourn.cbatch > lcBatch
               lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
            ENDIF
         CATCH
         ENDTRY

         TRY
            USE (lcPath + 'csdishdr')
            SET FILT TO LEFT(cbatch, 1) = '0'
            SET ORDER TO cbatch
            GO BOTT
            IF csdishdr.cbatch > lcBatch
               lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
            ENDIF
         CATCH
         ENDTRY

         TRY
            USE (lcPath + 'glrecur')
            SET FILT TO LEFT(cbatch, 1) = '0'
            SET ORDER TO BATCH
            GO BOTT
            IF glrecur.cbatch > lcBatch
               lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
            ENDIF
         CATCH
         ENDTRY

         TRY
            USE (lcPath + 'deposits')
            SET FILT TO LEFT(cbatch, 1) = '0'
            SET ORDER TO cbatch
            GO BOTT
            IF deposits.cbatch > lcBatch
               lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
            ENDIF
         CATCH
         ENDTRY

         TRY
            USE (lcPath + 'prdata')
            SET FILT TO LEFT(cbatch, 1) = '0'
            LOCATE FOR cbatch > lcBatch
            IF FOUND()
               lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
            ENDIF
         CATCH
         ENDTRY

         TRY
            USE (lcPath + 'workord')
            SET FILT TO LEFT(cbatch, 1) = '0'
            SET ORDER TO cbatch
            GO BOTT
            IF workord.cbatch > lcBatch
               lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
            ENDIF
         CATCH
         ENDTRY

         TRY
            USE (lcPath + 'brinelog')
            SET FILT TO LEFT(cbatch, 1) = '0'
            LOCATE FOR cbatch > lcBatch
            IF FOUND()
               lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
            ENDIF
         CATCH
         ENDTRY

         TRY
            USE (lcPath + 'invrech')
            SET FILT TO LEFT(cbatch, 1) = '0'
            SET ORDER TO cbatch
            GO BOTT
            IF invrech.cbatch > lcBatch
               lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
            ENDIF
         CATCH
         ENDTRY
      ENDIF

      TRY
         USE (lcPath + 'appurchh')
         SET FILT TO LEFT(cbatch, 1) = '0'
         SET ORDER TO cbatch
         GO BOTT
         IF appurchh.cbatch > lcBatch
            lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
         ENDIF
      CATCH
      ENDTRY

      TRY
         USE (lcPath + 'invhdr')
         SET FILT TO LEFT(cbatch, 1) = '0'
         SET ORDER TO cbatch
         GO BOTT
         IF invhdr.cbatch > lcBatch
            lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
         ENDIF
      CATCH
      ENDTRY

      TRY
         USE (lcPath + 'arpmthdr')
         SET FILT TO LEFT(cbatch, 1) = '0'
         SET ORDER TO cbatch
         GO BOTT
         IF arpmthdr.cbatch > lcBatch
            lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
         ENDIF
      CATCH
      ENDTRY

      TRY
         USE (lcPath + 'csrcthdr')
         SET FILT TO LEFT(cbatch, 1) = '0'
         SET ORDER TO cbatch
         GO BOTT
         IF csrcthdr.cbatch > lcBatch
            lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
         ENDIF
      CATCH
      ENDTRY

      TRY
         USE (lcPath + 'meterall')
         SET FILT TO LEFT(cbatch, 1) = '0'
         SET ORDER TO cbatch
         GO BOTT
         IF meterall.cbatch > lcBatch
            lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
         ENDIF
      CATCH
      ENDTRY

      TRY
         USE (lcPath + 'income')
         SET FILT TO LEFT(cbatch, 1) = '0'
         LOCATE FOR cbatch > lcBatch
         IF FOUND()
            lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
         ENDIF
      CATCH
      ENDTRY

      TRY
         USE (lcPath + 'meterdata')
         SET FILT TO LEFT(cbatch, 1) = '0'
         SET ORDER TO cbatch
         GO BOTT
         IF meterdata.cbatch > lcBatch
            lcBatch = PADL(RIGHT(cbatch, 4), 8, '0')
         ENDIF
      CATCH
      ENDTRY

* Lock the counter so no other users can access it.
      oCounter = oregistry.LockCounter('%Shared.Counters.Batch')

* Get the next value of the counter key
      m.cCounterValue = oregistry.GetCounter(oCounter)

      IF lcBatch > m.cCounterValue
         m.ccounter    = 'Batch'
         m.filecounter = lcBatch
         m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
         oregistry.SetCounter(oCounter, lcBatch)
         oregistry.UpdateCounter(oCounter)
      ENDIF

      oregistry.UnlockCounter(oCounter)

*********************************
* Cash Receipt Detail
*********************************
* Open the table
      TRY
         USE (lcPath + 'csrctdet') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Cash Receipt Detail')

* Find the highest used key value in the table
         SELE csrctdet
         SET ORDER TO cidpurd
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF csrctdet.cidrctd >= m.cCounterValue
            m.ccounter    = 'Cash Receipt Detail'
            m.filecounter = csrctdet.cidrctd
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, csrctdet.cidrctd)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN csrctdet
      CATCH
      ENDTRY

*********************************
* Checks
*********************************
* Open the table
      TRY
         USE (lcPath + 'checks') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Checks')

* Find the highest used key value in the table
         SELE checks
         SET FILT TO LEFT(cidchec, 1) = '0'
         SET ORDER TO cidchec
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF checks.cidchec >= m.cCounterValue
            m.ccounter    = 'Checks'
            m.filecounter = checks.cidchec
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, checks.cidchec)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN checks
      CATCH
      ENDTRY

*********************************
* Deposit Details
*********************************
* Open the table
      IF  THIS.lamversion
         TRY
            USE (lcPath + 'depositd') IN 0
* Lock the counter so no other users can access it.
            oCounter = oregistry.LockCounter('%Shared.Counters.Deposit Details')

* Find the highest used key value in the table
            SELE depositd
            SET ORDER TO ciddepd
            GO BOTT

* Get the next value of the counter key
            m.cCounterValue = oregistry.GetCounter(oCounter)

            IF depositd.ciddepd >= m.cCounterValue
               m.ccounter    = 'Deposit Details'
               m.filecounter = depositd.ciddepd
               m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
               oregistry.SetCounter(oCounter, depositd.ciddepd)
               oregistry.UpdateCounter(oCounter)
            ENDIF

            oregistry.UnlockCounter(oCounter)
            USE IN depositd
         CATCH
         ENDTRY

*********************************
* Disbursement Detail
*********************************
* Open the table
         TRY
            USE (lcPath + 'csdisdet') IN 0
* Lock the counter so no other users can access it.
            oCounter = oregistry.LockCounter('%Shared.Counters.Disbursement Detail')

* Find the highest used key value in the table
            SELE csdisdet
            SET ORDER TO ciddisd
            GO BOTT

* Get the next value of the counter key
            m.cCounterValue = oregistry.GetCounter(oCounter)

            IF csdisdet.ciddisd >= m.cCounterValue
               m.ccounter    = 'Disbursement Detail'
               m.filecounter = csdisdet.ciddisd
               m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
               oregistry.SetCounter(oCounter, csdisdet.ciddisd)
               oregistry.UpdateCounter(oCounter)
            ENDIF

            oregistry.UnlockCounter(oCounter)
            USE IN csdisdet
         CATCH
         ENDTRY
      ENDIF
*********************************
* Doikey
*********************************
* Open the table
      TRY
         USE (lcPath + 'wellinv') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.doikey')

* Find the highest used key value in the table
         SELE wellinv
         SET ORDER TO cidwinv
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF wellinv.cidwinv >= m.cCounterValue
            m.ccounter    = 'DoiKey'
            m.filecounter = wellinv.cidwinv
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, wellinv.cidwinv)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN wellinv
      CATCH
      ENDTRY
*********************************
* Expense Category
*********************************
* Open the table
      TRY
         USE (lcPath + 'expcat') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Expense Category')

* Find the highest used key value in the table
         SELE expcat
         SET ORDER TO cidexpc
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF expcat.cidexpc >= m.cCounterValue
            m.ccounter    = 'Expense Category'
            m.filecounter = expcat.cidexpc
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, expcat.cidexpc)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN expcat
      CATCH
      ENDTRY
*********************************
* Expense
*********************************
* Open the table
      TRY
         USE (lcPath + 'expense') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.expense')

* Find the highest used key value in the table
         SELE expense
         SET ORDER TO cidexpe
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF expense.cidexpe >= m.cCounterValue
            m.ccounter    = 'Expense'
            m.filecounter = expense.cidexpe
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, expense.cidexpe)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN expense
      CATCH
      ENDTRY

*********************************
* Form6
*********************************
* Open the table
      TRY
         USE (lcPath + 'form6') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Form6')

* Find the highest used key value in the table
         SELE form6
         SET ORDER TO cidform6
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF form6.cidform6 >= m.cCounterValue
            m.ccounter    = 'Form6'
            m.filecounter = form6.cidform6
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, form6.cidform6)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN form6
      CATCH
      ENDTRY
*********************************
* Form6s
*********************************
* Open the table
      TRY
         USE (lcPath + 'form6s')  IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Cash Receipt Detail')

* Find the highest used key value in the table
         SELE form6s
         SET ORDER TO cidstown
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF form6s.cidstown >= m.cCounterValue
            m.ccounter    = 'Form6s'
            m.filecounter = form6s.cidstown
            m.regcounter  = m.cCounterValue
*  insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, form6s.cidstown)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN form6s
      CATCH
      ENDTRY
*********************************
* Gljndet
*********************************
* Open the table
      IF THIS.lamversion
         TRY
            USE (lcPath + 'gljndet') IN 0
* Lock the counter so no other users can access it.
            oCounter = oregistry.LockCounter('%Shared.Counters.gljndet')

* Find the highest used key value in the table
            SELE gljndet
            SET ORDER TO cidgljn
            GO BOTT

* Get the next value of the counter key
            m.cCounterValue = oregistry.GetCounter(oCounter)

            IF gljndet.cidgljo >= m.cCounterValue
               m.ccounter    = 'gljndet'
               m.filecounter = gljndet.cidgljo
               m.regcounter  = m.cCounterValue
*  insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
               oregistry.SetCounter(oCounter, gljndet.cidgljo)
               oregistry.UpdateCounter(oCounter)
            ENDIF

            oregistry.UnlockCounter(oCounter)
            USE IN gljndet
         CATCH
         ENDTRY

*********************************
* glmaster
*********************************
* Open the table
         TRY
            USE (lcPath + 'glmaster') IN 0
* Lock the counter so no other users can access it.
            oCounter = oregistry.LockCounter('%Shared.Counters.Glmaster')

* Find the highest used key value in the table
            SELE glmaster
            SET ORDER TO cidglma
            GO BOTT
            IF LEFT(cidglma, 1) # '0'
               DO WHILE NOT BOF() AND LEFT(cidglma, 1) # '0'
                  SKIP - 1
               ENDDO
            ENDIF

* Get the next value of the counter key
            m.cCounterValue = oregistry.GetCounter(oCounter)

            IF glmaster.cidglma >= m.cCounterValue
               m.ccounter    = 'Glmaster'
               m.filecounter = glmaster.cidglma
               m.regcounter  = m.cCounterValue
*  insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
               oregistry.SetCounter(oCounter, glmaster.cidglma)
               oregistry.UpdateCounter(oCounter)
            ENDIF

            oregistry.UnlockCounter(oCounter)
            USE IN glmaster
         CATCH
         ENDTRY
      ENDIF

*********************************
* Income
*********************************
* Open the table
      TRY
         USE (lcPath + 'income') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.income')

* Find the highest used key value in the table
         SELE income
         SET ORDER TO cidinco
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF income.cidinco >= m.cCounterValue
            m.ccounter    = 'Income'
            m.filecounter = income.cidinco
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, income.cidinco)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN income
      CATCH
      ENDTRY

*********************************
* Invoice Detail
*********************************
* Open the table
      TRY
         USE (lcPath + 'invdet') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Invoice Detail')

* Find the highest used key value in the table
         SELE invdet
         SET ORDER TO cidinvd
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF invdet.cidinvd >= m.cCounterValue
            m.ccounter    = 'Invoice Detail'
            m.filecounter = invdet.cidinvd
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, invdet.cidinvd)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN invdet
      CATCH
      ENDTRY

*********************************
* Invoice Number
*********************************
* Open the table
      TRY
         USE (lcPath + 'invhdr') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Invoice Number')

* Find the highest used key value in the table
         SELE SUBSTR(cinvnum, 4) AS invnum FROM invhdr INTO CURSOR temp ORDER BY invnum
         SELE temp
         GO BOTT

         lckey = PADL(ALLT(invnum), 10, '0')

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF lckey >= m.cCounterValue
            m.ccounter    = 'Invoice Number'
            m.filecounter = lckey
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, lckey)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN invhdr
      CATCH
      ENDTRY

*********************************
* Meter Sub
*********************************
* Open the table
      TRY
         USE (lcPath + 'metersub') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Meter Sub')

* Find the highest used key value in the table
         SELE metersub
         SET ORDER TO cidmets
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF metersub.cidmets >= m.cCounterValue
            m.ccounter    = 'Meter Sub'
            m.filecounter = metersub.cidmets
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, metersub.cidmets)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN metersub
      CATCH
      ENDTRY

*********************************
* Owner History
*********************************
* Open the table
      TRY
         USE (lcPath + 'disbhist') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Owner History')

* Find the highest used key value in the table
         SELE disbhist
         SET ORDER TO ciddisb
         GO BOTT
         IF LEFT(disbhist.ciddisb, 1) # '0'
            SELE MAX(ciddisb) AS ckey FROM disbhist WHERE LEFT(ciddisb, 1) = '0' INTO CURSOR temp
            lckey = PADL(ALLT(ckey), 8, '0')
         ELSE
            lckey = ciddisb
         ENDIF

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF lckey >= m.cCounterValue
            m.ccounter    = 'Owner History'
            m.filecounter = lckey
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, lckey)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN disbhist
      CATCH
      ENDTRY
*********************************
* OtherNames
*********************************
* Open the table
      IF THIS.lamversion
         TRY
            USE (lcPath + 'othnames') IN 0
* Lock the counter so no other users can access it.
            oCounter = oregistry.LockCounter('%Shared.Counters.OtherNames')

* Find the highest used key value in the table
            SELE othnames
            SET ORDER TO cidothn
            GO BOTT

* Get the next value of the counter key
            m.cCounterValue = oregistry.GetCounter(oCounter)

            IF othnames.cidothn >= m.cCounterValue
               m.ccounter    = 'Other Names'
               m.filecounter = othnames.cidothn
               m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
               oregistry.SetCounter(oCounter, othnames.cidothn)
               oregistry.UpdateCounter(oCounter)
            ENDIF

            oregistry.UnlockCounter(oCounter)
            USE IN othnames
         CATCH
         ENDTRY
*********************************
* Payroll W2s
*********************************
* Open the table
         TRY
            USE (lcPath + 'prw2file') IN 0

* Lock the counter so no other users can access it.
            oCounter = oregistry.LockCounter('%Shared.Counters.Payroll W2s')

* Find the highest used key value in the table
            SELE prw2file
            SET ORDER TO cidw2
            GO BOTT

* Get the next value of the counter key
            m.cCounterValue = oregistry.GetCounter(oCounter)

            IF prw2file.cidw2 >= m.cCounterValue
               m.ccounter    = 'Payroll W2s'
               m.filecounter = prw2file.cidw2
               m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
               oregistry.SetCounter(oCounter, prw2file.cidw2)
               oregistry.UpdateCounter(oCounter)
            ENDIF

            oregistry.UnlockCounter(oCounter)
            USE IN prw2file
         CATCH
         ENDTRY
*********************************
* Prdata
*********************************
* Open the table
         TRY
            USE (lcPath + 'prdata') IN 0
* Lock the counter so no other users can access it.
            oCounter = oregistry.LockCounter('%Shared.Counters.prdata')

* Find the highest used key value in the table
            SELE prdata
            SET ORDER TO cidprdata
            GO BOTT

* Get the next value of the counter key
            m.cCounterValue = oregistry.GetCounter(oCounter)

            IF prdata.cidprdata >= m.cCounterValue
               m.ccounter    = 'Prdata'
               m.filecounter = prdata.cidprdata
               m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
               oregistry.SetCounter(oCounter, prdata.cidprdata)
               oregistry.UpdateCounter(oCounter)
            ENDIF

            oregistry.UnlockCounter(oCounter)
            USE IN prdata
         CATCH
         ENDTRY
      ENDIF
*********************************
* Program Rels
*********************************
* Open the table
      TRY
         USE (lcPath + 'progrel') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Program Rels')

* Find the highest used key value in the table
         SELE progrel
         SET ORDER TO cidprel
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF progrel.cidprel >= m.cCounterValue
            m.ccounter    = 'Program Rels'
            m.filecounter = progrel.cidprel
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, progrel.cidprel)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN progrel
      CATCH
      ENDTRY

*********************************
* Purchase Detail
*********************************
* Open the table
      TRY
         USE (lcPath + 'appurchd') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Purchase Detail')

* Find the highest used key value in the table
         SELE appurchd
         SET ORDER TO cidpurd
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF appurchd.cidpurd >= m.cCounterValue
            m.ccounter    = 'Purchase Detail'
            m.filecounter = appurchd.cidpurd
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, appurchd.cidpurd)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN appurchd
      CATCH
      ENDTRY

*********************************
* Suspense
*********************************
* Open the table
      TRY
         USE (lcPath + 'susaudit') IN 0

* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Suspense')

* Find the highest used key value in the table
         SELE susaudit
         SET ORDER TO cidsusa
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF susaudit.cidsusa >= m.cCounterValue
            m.ccounter    = 'Suspense'
            m.filecounter = susaudit.cidsusa
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, susaudit.cidsusa)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN susaudit
      CATCH
      ENDTRY

*********************************
* Sysctl
*********************************
* Open the table
      TRY
         USE (lcPath + 'sysctl') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Sysctl')

* Find the highest used key value in the table
         SELE sysctl
         SET ORDER TO cidsysctl
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF sysctl.cidsysctl >= m.cCounterValue
            m.ccounter    = 'Sysctl'
            m.filecounter = sysctl.cidsysctl
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, sysctl.cidsysctl)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN sysctl
      CATCH
      ENDTRY
*********************************
* Well History
*********************************
* Open the table
      TRY
         USE (lcPath + 'wellhist') IN 0
* Lock the counter so no other users can access it.
         oCounter = oregistry.LockCounter('%Shared.Counters.Well History')

* Find the highest used key value in the table
         SELE wellhist
         SET ORDER TO cidwhst
         GO BOTT

* Get the next value of the counter key
         m.cCounterValue = oregistry.GetCounter(oCounter)

         IF wellhist.cidwhst >= m.cCounterValue
            m.ccounter    = 'Well History'
            m.filecounter = wellhist.cidwhst
            m.regcounter  = m.cCounterValue
*   insert into badkeys from memvar

* Table is out of sync with the counter, so update it.
            oregistry.SetCounter(oCounter, wellhist.cidwhst)
            oregistry.UpdateCounter(oCounter)
         ENDIF

         oregistry.UnlockCounter(oCounter)
         USE IN wellhist
      CATCH
      ENDTRY

      WAIT CLEAR

      IF tlMenu
         MESSAGEBOX('File Counters Have Been Reset.', 48, 'Reset File Counters')
      ENDIF

   ENDPROC

*-- Opens the SDT and DBCX tables
**********************************
   PROCEDURE opensdt
**********************************
      LOCAL lasessions[1], llReturn, lnDatasession, lnSessions, lnx, loError
      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:OpenSDT')

      TRY
         lnDatasession = SET('datasession')
* Try to set the datasession to where dbcxreg is currently open
         lnSessions = ASESSIONS(lasessions)

         FOR lnx = 1 TO lnSessions
            TRY
               SET DATASESSION TO lasessions[lnx]
               IF USED('dbcxreg')
* Get us out of the loop
                  lnx = lnSessions + 1
               ENDIF
            CATCH
            FINALLY
            ENDTRY
         NEXT

* Reopen dbcx files
         IF ISNULL(ometa)
* If the file 'datafiles\sdt.cfg' exists, tell DBCXMgr to turn debug mode on
            ometa = NEWOBJECT('DBCXMgr', 'DBCXMGR.VCX', '', FILE('datafiles\sdt.cfg'))
         ENDIF

         IF NOT USED('coremeta')
            USE coremeta IN 0
         ENDIF

         IF NOT USED('dbcxreg')
            USE dbcxreg IN 0
         ENDIF

         IF NOT USED('sdtmeta')
            USE sdtmeta IN 0
         ENDIF

         IF NOT USED('sdtuser')
            USE sdtuser IN 0
         ENDIF

         SET DATASESSION TO (lnDatasession)
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'OpenSDT', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC


*-- Preliminary opencompany processing
**********************************
   PROCEDURE OpenCompany1
**********************************
      LPARA tlNoLogon
      LOCAL lcdatabase, llUpdate, omessage, llNewDBC, lcPath, llReturn
      LOCAL laFiles[1], lcDemo, lcFileVersion, lcValue, lcidcomp, lnFile, loError
      PRIV lcValue, lcidcomp
      lcValue  = ' '
      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:OpenCompany1')

      TRY
         THIS.lnologon = tlNoLogon

* Close all tables
         THIS.closealldata()
*
*  Clean up any extraneous dbf's in the executable folder
*
         THIS.CleanDBFs()

         THIS.cfullversion = THIS.cfileversion

         IF NOT USED('compmast')
            USE (THIS.ccommonfolder + 'compmast') IN 0 ORDER cidcomp
         ENDIF

*  Get the id of the company to open
         lcidcomp = THIS.cidcomp

         IF VARTYPE(lcidcomp) # 'C'
            lcidcomp = .NULL.
         ENDIF

         IF ISNULL(lcidcomp)
            lnFile   = ADIR(laFiles, THIS.ccommondocuments + '*.loc')
            IF lnFile > 0
               lcidcomp     = JUSTSTEM(laFiles[1, 1])
               lcidcomp     = SUBSTR(lcidcomp, ATC('_', lcidcomp) + 1)
               THIS.cidcomp = lcidcomp
            ENDIF
         ENDIF

         IF THIS.ldemo
            lcDemo = 'DEMO of '
         ELSE
            lcDemo = ''
         ENDIF

         IF NOT USED('compmast')
            USE (THIS.ccommonfolder + 'compmast') IN 0
         ENDIF

         IF NOT ISNULL(lcidcomp)
            SELECT compmast
            LOCATE FOR UPPER(cidcomp) == UPPER(lcidcomp)
            IF FOUND()
               IF DIRECTORY(cdatapath) AND FILE(ALLTRIM(cdatapath) + 'leases.dbf')
                  THIS.cdatafilepath = ADDBS(ALLT(cdatapath))
                  IF VARTYPE(THIS.oregistry) = 'O'
                     THIS.oregistry.cDBCPath = THIS.cdatafilepath + 'appdata.dbc'
                  ENDIF
* Check to see if the company has been updated to a newer version
* Don't allow it to be opened if the compmast version is newer
                  TRY
                     IF FILE(THIS.cdatafilepath + 'version.dbf')
                        USE (THIS.cdatafilepath + 'version.dbf') IN 0
                        SELECT VERSION
                        lcFileVersion = SUBSTR(VERSION.cversion, 1, 1) + '.' + SUBSTR(VERSION.cversion, 2, 1) + '.' + PADL(ALLTRIM(SUBSTR(VERSION.cversion, 3)), 3, '0')
                        IF lcFileVersion > STRTRAN(THIS.cfileversion, '.', '')
                           IF VERSION(2) # 2
                              MESSAGEBOX('The company being opened has been updated by a newer version of the software. ' + CHR(10) + ;
                                 'It is at version ' + TRANSFORM(lcFileVersion) + ' ' + CHR(10) + ;
                                 'You need to update to the latest version before you can open this company.', 16, 'Company/Software Version Mismatch')
                              THIS.lnocallopencomp2 = .T.
                              IF THIS.ltestversion
                                 THIS.SetScreenCaption()
                              ELSE
                                 THIS.SetScreenCaption()
                              ENDIF
                              llReturn = .T.
                              EXIT
                           ENDIF
                        ENDIF
                     ENDIF
                  CATCH TO loError
                  ENDTRY

                  THIS.lnocallopencomp2 = .F.

* Set the current shared path
                  THIS.cpathshared = THIS.cdatafilepath
                  THIS.cpathcommon = THIS.cdatafilepath

* Set the current database
                  TRY
                     OPEN DATABASE THIS.cdatafilepath + 'appdata.dbc'
                     SET DATABASE TO appdata
                     lcPath            = ALLT(cdatapath)
                     THIS.lOpenCompany = .T.
                  CATCH
                     THIS.lOpenCompany = .F.
                     MESSAGEBOX('The data in folder: ' + ALLTRIM(cdatapath) + ' for the company "' + ALLTRIM(compmast.cproducer) + '" cannot be opened. ' + CHR(10) + ;
                        'Please make sure that the folder for this company exists and that there is data in it. ' + CHR(10) + ;
                        'If you cannot determine the problem you can delete this company record and create a new ' + CHR(10) + ;
                        'company linking it to the desired data.', ;
                        16, 'Data for company not found...')
                     THIS.cdatafilepath = ''
                     DO OpenComp WITH .F.
                     THIS.lnocallopencomp2 = .T.
                     lnFile                = ADIR(laFiles, THIS.ccommondocuments + '*.loc')
                     IF lnFile <= 0
                        THIS.lOpenCompany = .F.
                     ELSE
                        THIS.lOpenCompany = .T.
                     ENDIF
                  ENDTRY
               ELSE
                  THIS.lOpenCompany = .F.
                  IF MESSAGEBOX('The data path: ' + ALLTRIM(cdatapath) + ' for the company "' + ALLTRIM(compmast.cproducer) + '" is not available. ' + ;
                        'Please make sure that the folder for this company exists and that there is data in it. ' + CHR(10) + CHR(10) + ;
                        'If you cannot determine the problem you can delete this company record and create a ' + CHR(10) + ;
                        'new company linking it to the desired data.' + CHR(10) + CHR(10) + ;
                        'Delete the company record now?', ;
                        36, 'Data for company not found...') = 6
                     SELECT compmast
                     DELETE NEXT 1
                  ENDIF
                  THIS.cdatafilepath = ''
                  IF OpenComp(.F.)
                     THIS.lnocallopencomp2 = .T.
                     llReturn              = .T.
                     EXIT
                  ELSE
                     THIS.cidcomp = .NULL.
                     llReturn     = .F.
                     EXIT
                  ENDIF
               ENDIF
            ELSE
*
*  No company chosen to open
*
               THIS.cdatafilepath = ''
               THIS.lOpenCompany  = .F.

               THIS.SetScreenCaption()

               THIS.lOpenCompany  = .F.
               THIS.cdatafilepath = ''
               THIS.lOpenCompany  = .F.
               llReturn           = .F.
               EXIT
            ENDIF
         ELSE
            llReturn = .F.
            EXIT
         ENDIF
         WAIT CLEAR
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'OpenCompany1', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to open the company at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn
   ENDPROC


*-- Post opencompany processing
**********************************
   PROCEDURE OpenCompany2
**********************************
      LPARAMETERS tlNoUpdate, tlForceUpdate, tlMenu
      LOCAL lcidcomp

      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:OpenCompany2')

      TRY
         lcidcomp = THIS.cidcomp

* Temporary fix for GCW
         IF lcidcomp = '00GCW'
            THIS.lparentcompany = .T.
         ELSE
            THIS.lparentcompany = .F.
         ENDIF

         IF NOT USED('compmast')
            USE (THIS.ccommonfolder + 'compmast') IN 0
         ENDIF

         IF ISNULL(lcidcomp)
            SELECT compmast
            GO TOP
            lcidcomp = cidcomp
         ENDIF

         SELECT compmast
         LOCATE FOR UPPER(cidcomp) == UPPER(lcidcomp)
         IF FOUND()
* Replace the compmast record with the record from the version file
* since it will always be the most current.
            TRY
               IF NOT FILE(ALLTRIM(compmast.cdatapath) + 'version.dbf')
                  SELECT compmast
                  SCATTER MEMVAR
                  lnx     = AFIELDS(latemp)
                  lcTable = ALLTRIM(m.cdatapath) + 'version'
                  CREATE TABLE (lcTable) FREE FROM ARRAY latemp
                  INSERT INTO VERSION FROM MEMVAR
               ENDIF
               SELECT VERSION
               GO TOP
               SELECT compmast
               REPLACE cprocessor WITH VERSION.cprocessor
               REPLACE caddress1  WITH VERSION.caddress1
               REPLACE ccity      WITH VERSION.ccity
               REPLACE cstate     WITH VERSION.cstate
               REPLACE czipcode   WITH VERSION.czipcode
               REPLACE caddress2  WITH VERSION.caddress2
               REPLACE ccontact   WITH VERSION.ccontact
               REPLACE ctaxid     WITH VERSION.ctaxid
               REPLACE cphoneno   WITH VERSION.cphoneno
               REPLACE cfax       WITH VERSION.cfax
               IF NOT 'SAMPLE' $ UPPER(cproducer)
                  REPLACE cproducer  WITH VERSION.cproducer
               ENDIF
               REPLACE cversion   WITH VERSION.cversion
               USE IN VERSION
            CATCH
            ENDTRY
            IF THIS.ldemo
*        THIS.oMessage.DISPLAY('This software is in demonstration mode.  Report and check printing will be affected and not all features will be available.')
               lcDemo = 'DEMO of '
            ELSE
               lcDemo = ''
            ENDIF

            SELECT compmast
            THIS.lOpenCompany = .T.
            THIS.ccompanyname = cproducer
            THIS.cAgentName   = cprocessor
            m.cproducer       = cproducer
            THIS.caddress1    = caddress1
            THIS.laudittrail  = lAudit
            THIS.xFlag        = xFlag
            THIS.ccity        = ccity
            THIS.cstate       = cstate
            THIS.cZip         = czipcode
            THIS.cphoneno     = cphoneno
            THIS.cfaxno       = cfax
            THIS.cemail       = cemail
            IF NOT EMPTY(caddress2)
               THIS.caddress2 = caddress2
               THIS.cAddress3 = ALLTRIM(ccity) + ', ' + cstate + ' ' + czipcode
            ELSE
               THIS.caddress2 = ALLTRIM(ccity) + ', ' + cstate + ' ' + czipcode
               THIS.cAddress3 = ''
            ENDIF
            THIS.ccontact      = ccontact

            SELECT compmast
            THIS.ctaxid   = ctaxid
            THIS.cphoneno = cphoneno
            THIS.cfaxno   = cfax

* Check tax id to see if it has not been encrypted
            IF ISDIGIT(LEFT(THIS.ctaxid, 1)) AND THIS.osecurity.HasPrivilege('Tax Ids')
               MESSAGEBOX("The company's EIN number needs to be reentered by going to Maintain Company Information." + ;
                  'It has become corrupted.', 48, 'Bad Company EIN Detected')
            ENDIF

*!*               lcSupportExpires     = THIS.checksupportexp()
*!*               ldExpires            = CTOD(lcSupportExpires)
*!*               THIS.dsupportexpires = ldExpires

            IF THIS.dsupportexpires < DATE()
               lcExpireMessage = ' ** Support Expired on ' + lcSupportExpires + ' **'
            ELSE
               lcExpireMessage = ''
            ENDIF

            THIS.SetScreenCaption()

* Set the data path in the main window
            IF THIS.lcloudserver
               _VFP.STATUSBAR = 'Company Open: ' +  PROPER(THIS.ccompanyname) + '    - Support Subscription Expires: ' + DTOC(THIS.dsupportexpires)
            ELSE
               _VFP.STATUSBAR = 'Data Path: ' +  LOWER(THIS.cdatafilepath) + '    - Support Subscription Expires: ' + DTOC(THIS.dsupportexpires)
            ENDIF
*
*  Rebuild the search path
*
            THIS.setsearchpath()

* Set the registry keys to the new path
            THIS.Set_Reg_Keys()
*            THIS.closealldata()
            OPEN DATABASE (THIS.cdatafilepath + 'appdata.dbc')
            SET DATABASE TO (THIS.cdatafilepath + 'appdata.dbc')

* Run through the sessions to make sure appreg01 is not open
* so we can add records.
            lnSessions = ASESSIONS(laSession)
            FOR lnx = 1 TO lnSessions
               TRY
                  SET DATASESSION TO lnx
                  DO CASE
                     CASE USED('appreg01')
                        USE IN appreg01
                     CASE USED('appdata_appreg01')
                        USE IN appdata_appreg01
                     CASE USED('cmregistry')
                        USE IN cmregistry
                     OTHERWISE
                  ENDCASE
               CATCH
               ENDTRY
            ENDFOR
            SET DATASESSION TO 1
* Copy in any new security records

            IF NOT THIS.limversion
               TRY
                  IF NOT USED('appsec')
                     USE appsec IN 0
                  ENDIF
                  SELECT appsec
                  SCAN
                     SCATTER MEMVAR MEMO
                     IF USED('cmregistry')
                        SELE cmregistry
                     ELSE
                        THIS.lopeningfiles   = .T.
                        ometa.oSDTMgr.cAlias = 'appreg01'
                        IF NOT USED('appreg01')
                           USE (THIS.cdatafilepath + 'appreg01') IN 0
                        ENDIF
                        THIS.lopeningfiles = .F.
                        SELECT appreg01
                     ENDIF
                     LOCATE FOR LOWER(keyname) = LOWER(m.keyname)
                     IF NOT FOUND()
                        APPEND BLANK
                        GATHER MEMVAR
                     ENDIF
                  ENDSCAN
               CATCH
               ENDTRY
            ENDIF

* Update the tables to the new formats
            IF NOT tlNoUpdate
               THIS.UpdateTables(lcidcomp, tlForceUpdate, .F., tlMenu)
            ENDIF

            WAIT WIND NOWAIT 'Opening Files For ' + ALLTRIM(THIS.ccompanyname) + '.  Please Wait...'

* Set the current database
            TRY
               OPEN DATABASE THIS.cdatafilepath + 'appdata.dbc'
               THIS.opensdt()
               SET DATABASE TO appdata
               ometa.ResetError()
               ometa.setdatabase(DBC())
               THIS.lopeningfiles = .T.
               SET DATASESSION TO 1
               llReturn = .T.
               EXIT
            CATCH
            ENDTRY
            TRY
               ometa.lSuppressErrors = .T.
               IF NOT ometa.oSDTMgr.OpenAllTables(, .T.)
                  MESSAGEBOX('Unable to Open the files for: ' + ALLTRIM(THIS.ccompanyname) + CHR(13) + ;
                     ometa.aErrorInfo[1, 2] + ': ' + CHR(13) + ;
                     ometa.aErrorInfo[1, 3], 16, 'Open Company Problem')
                  llReturn = .F.
                  EXIT
               ENDIF
            CATCH TO loError
               MESSAGEBOX('Unable to Open the files for: ' + ALLTRIM(THIS.ccompanyname), 16, 'Open Company Problem')
               llReturn = .F.
               EXIT
            ENDTRY
            IF NOT llReturn
               llReturn = .F.
               EXIT
            ENDIF

            THIS.lopeningfiles = .F.

* Set eventlog to disabled
            THIS.oregistry.setkeyvalue('%Shared.Security.Event Log.Enabled', .F.)

* Set confirmdelete to true
            THIS.oregistry.setkeyvalue(keyname_confirm_delete, .T.)

* Check to see if the data has been encrypted for this company
            swselect('options')
            IF options.lencrypted
               swselect('compmast')
               IF ISDIGIT(LEFT(ctaxid, 1))
                  REPLACE ctaxid WITH cmEncrypt(compmast.ctaxid, THIS.cencryptionkey)
               ENDIF
            ENDIF
            THIS.lencrypted = options.lencrypted

* Process any custom methods

            THIS.custommethods()

* Extra processing for non-IM applications
            IF NOT THIS.limversion
*  Go check for delay rental payments due
               IF THIS.lLandOpt AND THIS.llanddata AND NOT THIS.lnologon
                  DO lmlandpmts
               ENDIF


            ENDIF

* Create the options object
            swselect('options')
            GO TOP
            SCATTER NAME THIS.ooptions

         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'OpenCompany2', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to open the company at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn
   ENDPROC


*-- Custom methods that need to be done during opencompany processing
**********************************
   PROCEDURE custommethods
**********************************
*
* Make sure all payments in suspense and disbhist have nrunno_in filled in
*
      LOCAL lFlat, loError
      LOCAL llReturn
*:Global cOwnerID, cTypeInv, cWellID

      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:CustomMethods')


      TRY
* Create the foxaudit object and turn on logging
         THIS.FoxAuditSetup()

         IF FILE(THIS.ccommonfolder + 'rushmore.txt')
            THIS.rushmoreopt = .T.
         ELSE
            THIS.rushmoreopt = .F.
         ENDIF

         IF NOT THIS.limversion

* Remove any blank program records
            swselect('programs')
            DELETE FOR EMPTY(cprogcode)

* Setup swquery the first time
            THIS.sfquery_setup()

* Set the documents description to the path if the desc is empty
            TRY
               swselect('documents')
               SCAN FOR EMPTY(cdesc)
                  REPLACE cdesc WITH cpath
               ENDSCAN
            CATCH TO loError
            ENDTRY

* Set the new lTaxNet flag in options
            TRY
               IF FILE('datafiles\taxnet.cfg')
                  swselect ('options')
                  GO TOP
                  REPLACE ltaxnet WITH .T.
               ENDIF
            CATCH
            ENDTRY
         ENDIF

* Fix the Pivoten Address
         THIS.AddPivotenVendor()

         THIS.SetupLogger()

         THIS.CheckXFRXFiles()

         THIS.XFRXErase()

         THIS.Appreg02_Replace()

         THIS.Setup_Screenshot()

         THIS.CheckVFPVersion()

         THIS.FixTaxSection()

         THIS.FixAFENo()

* Change how COMP and GATH are handled. Move from revcat to expcat
         THIS.FixCOMPGATH()

* Encrypt the taxids if they haven't been encrypted yet
         THIS.Encryptdata()

* Check to make sure the tax ids for owners are encrypted
         THIS.FixEncryption()

* Fill in the new cDDCompName field in options
         THIS.fixDDCompName()

* Fix employee tax ids to make sure they are encrypted
         IF m.goapp.lpayrollopt
            THIS.EncryptEmps()
         ENDIF

* Run the suspense check method to check for empty(csusptype)
         THIS.FixBlankSuspType()

* Plug in the new primary key to tables that need it
         THIS.PrimaryKeySetup()
* Build the initial DOI Decks
         THIS.BuildDOIDecks()

* Set the iSource property on bills if it isn't set.
         THIS.FillBillSource()

* Log the record counts for this company
         THIS.LogWellCounts()

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'CustomMethods', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE Appdata_Folder_Access
**********************************
*To do: Modify this routine for the Access method

      IF EMPTY(THIS.appdata_folder)

         THIS.appdata_folder = SYS(5) + CURDIR() + 'DataFiles\'
      ENDIF

      RETURN THIS.appdata_folder
   ENDPROC


*-- Get the location of the Checks and Rpts folders from the sherware.ini file
**********************************
   PROCEDURE GetFolderPaths
**********************************
*
* Gets the location of the Checks and Rpts folders from the sherware.ini file
*
      LOCAL m.lcChecksFolder, m.lcRptsFolder, oOldINIReg, m.lcQueryFolder, m.lcCommonFolder
      LOCAL lcChecksFolder, lcCommonFolder, lcINIFileFullPath, lcQueryFolder, lcRptsFolder, lcclasslib
      LOCAL llReturn, loError
*:Global cOffsite, fh

      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:GetFolderPaths')

      TRY

         STORE '' TO m.lcChecksFolder, m.lcRptsFolder, m.lcQueryFolder, m.lcCommonFolder, m.cUpdate, m.cUpdPort, m.cSend, m.cSendPort

         lcclasslib = SET('classlib')
         IF NOT 'registry.vcx' $ LOWER(lcclasslib)
            SET CLASSLIB TO registry.vcx ADDITIVE
         ENDIF
         m.lcINIFileFullPath = FULLPATH('datafiles\sherware.ini')
         oOldINIReg          = CREATEOBJECT('oldinireg')

         STORE .F. TO llChecks, llRpts, llQuery, llCommon, llUpdateURL, llPort, llBackupUrl

         IF FILE(m.lcINIFileFullPath)
* Get the location of the checks folder
            lnReturn = oOldINIReg.GetIniEntry(@m.lcChecksFolder, 'FOLDERS', 'checks', m.lcINIFileFullPath)
            IF lnReturn = 0
               llChecks = .T.
            ENDIF

* Get the location of the Rpts folder
            lnReturn = oOldINIReg.GetIniEntry(@m.lcRptsFolder, 'FOLDERS', 'rpts', m.lcINIFileFullPath)
            IF lnReturn = 0
               llRpts = .T.
            ENDIF

* Get the location of the Query folder
            lnReturn = oOldINIReg.GetIniEntry(@m.lcQueryFolder, 'FOLDERS', 'query', m.lcINIFileFullPath)
            IF lnReturn = 0
               llQuery = .T.
            ENDIF

* Get the location of the Common folder
            lnReturn = oOldINIReg.GetIniEntry(@m.lcCommonFolder, 'FOLDERS', 'common', m.lcINIFileFullPath)
            IF lnReturn = 0
               llCommon = .T.
            ENDIF

* Get the name of the update server
            lnReturn = oOldINIReg.GetIniEntry(@m.cUpdate, 'SYSTEM', 'server', m.lcINIFileFullPath)
            IF lnReturn = 0
               llUpdURL = .T.
            ENDIF
            lnReturn = oOldINIReg.GetIniEntry(@m.cUpdPort, 'SYSTEM', 'p', m.lcINIFileFullPath)
            IF lnReturn = 0
               llPort = .T.
            ENDIF

* Get the name of the update server
            lnReturn = oOldINIReg.GetIniEntry(@m.cSend, 'SYSTEM', 'send', m.lcINIFileFullPath)
            IF lnReturn = 0
               llBackupUrl = .T.
            ENDIF

         ELSE
            fh = FCREATE(m.lcINIFileFullPath)
            = FPUTS(fh, '[FOLDERS]')
            = FPUTS(fh, ' ')
            = FPUTS(fh, 'checks=checks')
            = FPUTS(fh, ' ')
            = FPUTS(fh, 'rpts=rpts')
            = FPUTS(fh, ' ')
            = FPUTS(fh, 'query=swquery')
            = FPUTS(fh, ' ')
            = FPUTS(fh, 'common=datafiles')
            = FPUTS(fh, ' ')
            = FPUTS(fh, '[SYSTEM]')
            = FPUTS(fh, ' ')
            = FPUTS(fh, 'server=updates.Pivoten.com')
            = FPUTS(fh, 'p=441')
            = FPUTS(fh, 'send=cb.Pivoten.com')
            = FPUTS(fh, ' ')
            = FFLUSH(fh)
            = FCLOSE(fh)
            m.lcChecksFolder = 'checks'
            m.lcRptsFolder   = 'rpts'
            m.lcQueryFolder  = 'swquery'
            m.cUpdate        = 'updates.Pivoten.com'
            m.cUpdPort       = '441'
            m.cSend          = 'cb.Pivoten.com'
         ENDIF

* Check for the existence of the checks folder specified. If it doesn't exist, ask for its location.
         IF NOT DIRECTORY(m.lcChecksFolder)
            MESSAGEBOX("The location specified for the checks folder in sherware.ini doesn't exist. " + CHR(10) + ;
               'Please choose the checks folder location.', 16, 'Missing Checks Folder')
            m.lcChecksFolder = GETDIR(CURDIR(), 'Choose the location of the check formats.', 'Choose Checks Folder', 64)
            IF EMPTY(m.lcChecksFolder)
               m.lcChecksFolder = 'checks'
            ENDIF
            oOldINIReg.WriteIniEntry(m.lcChecksFolder, 'FOLDERS', 'checks', m.lcINIFileFullPath)
         ENDIF

* Check for the existence of the Rpts folder specified. If it doesn't exist, ask for its location.
         IF NOT DIRECTORY(m.lcRptsFolder)
            MESSAGEBOX("The location specified for the Rpts folder in sherware.ini doesn't exist. " + CHR(10) + ;
               'Please choose the Rpts folder location.', 16, 'Missing Rpts Folder')
            m.lcRptsFolder = GETDIR(CURDIR(), 'Choose the location of the report formats.', 'Choose Rpts Folder', 64)
            IF EMPTY(m.lcRptsFolder)
               m.lcRptsFolder = 'Rpts'
            ENDIF
            oOldINIReg.WriteIniEntry(m.lcRptsFolder, 'FOLDERS', 'rpts', m.lcINIFileFullPath)
         ENDIF

* Check for the existence of the Query folder specified. If it doesn't exist, ask for its location.
         IF NOT DIRECTORY(m.lcQueryFolder)
            MESSAGEBOX("The location specified for the Query folder in sherware.ini doesn't exist. " + CHR(10) + ;
               'Please choose the Query folder location.', 16, 'Missing Query Folder')
            m.lcQueryFolder = GETDIR(CURDIR(), 'Choose the location of the Pivoten Query files.', 'Choose Query Folder', 64)
            IF EMPTY(m.lcQueryFolder)
               m.lcQueryFolder = 'swquery'
            ENDIF
            oOldINIReg.WriteIniEntry(m.lcQueryFolder, 'FOLDERS', 'query', m.lcINIFileFullPath)
         ENDIF

* Check for the existence of the Common (datafiles) folder specified. If it doesn't exist, ask for its location.
         IF NOT DIRECTORY(m.lcCommonFolder)
            MESSAGEBOX("The location specified for the Common folder in sherware.ini doesn't exist. " + CHR(10) + ;
               'Please choose the Common folder location. ' + CHR(10) + ;
               'The default location should be the datafiles subfolder found in the installation folder.', 16, 'Missing Common Folder')
            m.lcCommonFolder = GETDIR(CURDIR(), 'Choose the location of the Pivoten Common files.', 'Choose Common Folder', 64)
            IF EMPTY(m.lcCommonFolder)
               m.lcCommonFolder = 'datafiles'
            ENDIF
            oOldINIReg.WriteIniEntry(m.lcCommonFolder, 'FOLDERS', 'common', m.lcINIFileFullPath)
         ENDIF

         IF llChecks
            THIS.cchecksfolder  = ADDBS(ALLTRIM(m.lcChecksFolder))
         ELSE
            THIS.cchecksfolder  = 'checks\'
         ENDIF
         IF llRpts
            THIS.crptsfolder    = ADDBS(ALLTRIM(m.lcRptsFolder))
         ELSE
            THIS.crptsfolder    = 'rpts\'
         ENDIF
         IF llQuery
            THIS.cqueryfolder   = ADDBS(ALLTRIM(m.lcQueryFolder))
         ELSE
            THIS.cqueryfolder   = 'swquery\'
         ENDIF
         IF llCommon
            THIS.ccommonfolder  = ADDBS(ALLTRIM(m.lcCommonFolder))
         ELSE
            THIS.ccommonfolder  = 'datafiles\'
         ENDIF
         IF llUpdateURL
            THIS.cupdateurl     = m.cUpdate
         ELSE
            THIS.cupdateurl     = 'updates.Pivoten.com'
         ENDIF
         IF llPort
            THIS.nupdport       = INT(VAL(m.cUpdPort))
         ELSE
            THIS.nupdport       = 441
         ENDIF
         IF llBackupUrl
            THIS.cbackupurl     = m.cSend
         ELSE
            THIS.cbackupurl     = 'cb.Pivoten.com'
         ENDIF

* Get the LocalAppData folder
         THIS.clocalappdata = specialfolders('LocalAppData') + 'temp\'


* Build the swquery data.ini file if it doesn't exist

         IF NOT FILE('swquery\data\data.ini')
            fh = FCREATE('swquery\data\data.ini')
            = FPUTS(fh, '[Pivoten Query]')
            = FPUTS(fh, '[Options]')
            = FPUTS(fh, 'CommonFiles=.')
            = FPUTS(fh, 'TargetApp=' + JUSTPATH(FULLPATH('swlaunch.exe')))
            = FFLUSH(fh)
            = FCLOSE(fh)
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'GetFolderPaths', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE KillProcess
*==============================================================================
* Program:         KillProcess
* Purpose:         Terminate the specified application
* Author:         Doug Hennig
* Copyright:      (c) 2001 Stonefield Systems Group Inc.
* Last revision:   02/02/2001
* Parameters:      tcCaption - the caption for the application to terminate
* Returns:         .T. if it succeeded
* Environment in:   none
* Environment out:   if successful, the application has been terminated
*==============================================================================

      LPARAMETERS tcCaption
      LOCAL lnhWnd, ;
         llReturn, ;
         lnProcessID, ;
         lnHandle

* If we're in the development environment
* don't kill the process
      IF VERSION(2) = 2
         RETURN
      ENDIF

      WAIT WINDOW NOWAIT 'Exiting the application....'
* Declare the Win32API functions we need.

      #DEFINE WM_DESTROY 0x0002
      DECLARE INTEGER FindWindow IN Win32API ;
         STRING @cClassName, STRING @cWindowName
      DECLARE INTEGER SendMessage IN Win32API ;
         INTEGER HWND, INTEGER uMsg, INTEGER wParam, INTEGER LPARAM
      DECLARE Sleep IN Win32API ;
         INTEGER nMilliseconds
      DECLARE INTEGER GetWindowThreadProcessId IN Win32API ;
         INTEGER HWND, INTEGER @lpdwProcessId
      DECLARE INTEGER OpenProcess IN Win32API ;
         INTEGER dwDesiredAccess, INTEGER bInheritHandle, INTEGER dwProcessID
      DECLARE INTEGER TerminateProcess IN Win32API ;
         INTEGER hProcess, INTEGER uExitCode

* Get a handle to the window by its caption.

      lnhWnd   = FindWindow(0, tcCaption)
      llReturn = lnhWnd = 0

* If we found the window, send a "destroy" message to it, then wait for it to
* be gone. If it didn't, let's use the big hammer: we'll terminate its process.

      IF NOT llReturn
         SendMessage(lnhWnd, WM_DESTROY, 0, 0)
         llReturn = THIS.WaitForAppTermination(tcCaption)
         IF NOT llReturn
            lnProcessID = 0
            GetWindowThreadProcessId(lnhWnd, @lnProcessID)
            lnHandle = OpenProcess(1, 1, lnProcessID)
            llReturn = TerminateProcess(lnHandle, 0) > 0
         ENDIF NOT llReturn
      ENDIF NOT llReturn
      RETURN llReturn


* For up to five times, wait for a second, then see if the specified application
* is still running. Return .T. if the application has terminated.
   ENDPROC

**********************************
   PROCEDURE WaitForAppTermination
**********************************
      LPARAMETERS tcCaption
      LOCAL lnCounter, llReturn
      m.lnCounter = 0
      m.llReturn  = .F.
      DO WHILE NOT m.llReturn AND lnCounter < 5
         Sleep(1000)
         m.lnCounter = lnCounter + 1
         m.llReturn  = FindWindow(0, m.tcCaption) = 0
      ENDDO
      RETURN m.llReturn
   ENDPROC

**********************************
   PROCEDURE ResetRemind
**********************************
*
*  Resets the RemindIn INI setting so that the user is reminded of updates
*
      LOCAL lcINIFullPath
      LOCAL oOldINIReg AS 'oldinireg'
      LOCAL llReturn, loError

      THIS.LogCodePath(.T.,'CAPP:ResetRemind')

      TRY
         lcINIFullPath = FULLPATH('datafiles\swlaunch.ini')
         oOldINIReg    = CREATEOBJECT('oldinireg')

         oOldINIReg.WriteIniEntry('', 'REMINDER', 'remindin', lcINIFullPath)
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'ResetRemind', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY
   ENDPROC


*-- Close all data sessions
**********************************
   PROCEDURE closealldata
**********************************
* Close the tables in all datasessions
      LOCAL laSession[1], llReturn, lnSessions, lnx, loError
*:Global nwa
      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:CloseAllData')

      TRY

         lnSessions = ASESSIONS(laSession)
         FOR lnx = 1 TO lnSessions
            TRY
               SET DATASESSION TO laSession[lnx]
               IF USED('dbcxreg')
                  IF NOT EMPTY(DBC())
                     CLOSE DATABASES
                  ENDIF
               ELSE
                  CLOSE DATABASES
* Close all tables in the workareas
                  FOR nwa = 1 TO 255
                     SELECT (nwa)
                     USE
                  ENDFOR
               ENDIF
            CATCH
* Nothing
            FINALLY
            ENDTRY
         ENDFOR
         SET DATASESSION TO 1
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'CloseAllData', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE oTreeno_Access
**********************************
      IF VARTYPE(THIS.otreeno) # 'O'
         DO wwDotNetBridge
         THIS.otreeno = CREATEOBJECT('TreenoSoftware')
      ENDIF

      RETURN THIS.otreeno
   ENDPROC


*-- Creates the Data.ini file so the setup for query doesn't ask a lot of questions the first time you get in.
**********************************
   PROCEDURE sfquery_setup
**********************************
*
* Writes a data.ini file for sfquery if it doesn't exist
* so that query doesn't ask the user a lot of questions
* the first time they get into advanced reporting
*
      LOCAL llReturn, loError
*:Global fh
      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:SFQuery_Setup')

      TRY
         IF NOT FILE('swquery\data\data.ini')
            fh = FCREATE('swquery\data\data.ini')
            = FPUTS(fh, '[Pivoten Query]')
            = FPUTS(fh, '[Options]')
            = FPUTS(fh, 'CommonFiles=.')
            = FPUTS(fh, 'TargetApp=' + JUSTPATH(FULLPATH('swlaunch.exe')))
            = FFLUSH(fh)
            = FCLOSE(fh)
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'SFQuery_Setup', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      TRY
         IF FILE('swquery\data\sfconfig.dbf')
            IF NOT USED('sfconfig')
               USE ('swquery\data\sfconfig') IN 0
            ENDIF
            SELECT sfconfig
            LOCATE FOR UPPER(KEY) = 'DEFAULTUSEDISTINCT'
            IF FOUND()
               REPLACE VALUE WITH '.F.'
            ENDIF
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'SFQuery_Setup', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE AddPivotenVendor
**********************************
* Add a vendor record for Pivoten if it doesn't exist
      LOCAL llReturn, loError

      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:AddPivotenVendor')

      TRY
         IF NOT THIS.lqbversion  && Vendors are maintained in QB
            swselect('vendor')
            LOCATE FOR 'pivoten' $ LOWER(cvendname)
            IF NOT FOUND()
               SELECT vendor
               LOCATE FOR 'pivoten' $ LOWER(cvendorid)
               IF NOT FOUND()
                  m.cvendorid = 'PIVOTEN'
                  m.cvendname = 'Pivoten, LLC'
                  STORE '1610 Wynkoop STE 118' TO m.cbaddr1, m.caddress1
                  STORE '' TO m.cbaddr2, m.caddress2
                  STORE 'Denver' TO m.cbcity, m.ccity
                  STORE 'CO' TO m.cbstate, m.cstate
                  STORE '80202' TO m.cbzip, m.cZip
                  STORE '877-748-6836' TO m.cbphone, m.cphone
                  INSERT INTO vendor FROM MEMVAR
               ENDIF
            ENDIF
         ENDIF
      CATCH TO loError
         llReturn = .F.
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE CancelMsg
**********************************
      LOCAL llReturn, loError

      llReturn = .F.

      THIS.LogCodePath(.T.,'CAPP:CancelMsg')

      TRY
         IF MESSAGEBOX('Are you sure you want to cancel this process?', 36, 'Cancel Pressed') = 6
            llReturn = .F.
            MESSAGEBOX('Processing canceled by user...', 16, 'Processing Canceled')
         ELSE
            llReturn = .T.
         ENDIF
      CATCH TO loError
      ENDTRY

      THIS.lcanceled = .F.

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE CancelProcess
**********************************
      THIS.lcanceled = .T.
      THIS.LogCodePath(.T.,'CAPP:CancelProcess')
      MESSAGEBOX('Esc key was pressed to cancel process!', 48, 'Cancel Process')
   ENDPROC


*-- Checks to see if the help file is up to date.
**********************************
   PROCEDURE CheckHelpFile
**********************************
* Check to see if we have the most up to date help file

      LOCAL lcHelpFile, llReturn, loError
      LOCAL laFile[1], ldHelpDate, lnFound

      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:CheckHelpFile')

* Commenting this out for now. Will uncomment if we ever put out new help files.
      RETURN


      TRY

         lcHelpFile = THIS.helpfilename

         lnFound = ADIR(laFile, THIS.ccommondocuments + lcHelpFile)

         IF lnFound >= 0
            IF VARTYPE(THIS.helpfiledate) # 'D'
               THIS.helpfiledate = CTOD(THIS.helpfiledate)
            ENDIF
            IF lnFound > 0
               ldHelpDate = laFile[1, 3]
               IF ldHelpDate < THIS.helpfiledate
                  llReturn = GetHelpFile(lcHelpFile)
               ENDIF
            ELSE
               llReturn = GetHelpFile(lcHelpFile)
            ENDIF
         ELSE
            llReturn = GetHelpFile(lcHelpFile)
         ENDIF

         IF llReturn AND FILE(THIS.ccommondocuments + THIS.helpfilename)
            SET HELP TO (THIS.ccommondocuments + THIS.helpfilename)
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'CheckHelpFile', loError.LINENO, 'App Startup', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC


**********************************
   PROCEDURE ShowNews
**********************************
      LOCAL loNews

      DO FORM news

   ENDPROC

**********************************
   PROCEDURE LogUsage
**********************************
      LOCAL loIP AS 'wwftp'
      LOCAL lcSourceFile, lcTargetFile, lnResult, loError, lcRegCode, lcState, lcString, lcReports
      LOCAL lcCompanies

      #DEFINE CRLF CHR(13) + CHR(10)

      IF NOT IsInternetAvailable()
         IF THIS.ldebugmode
            MESSAGEBOX('LogUsage: Internet is not available.',16,'LogUsage')
         ENDIF
         RETURN
      ENDIF

      STORE '' TO lcString, lcState, lcReports, lcRegCode, lcCompanies, lcStates

      TRY

         llReturn = .T.

* Get the # of wells
         TRY
            IF NOT USED('_lxx')
               USE (THIS.ccommonfolder+'_lxx') IN 0
            ENDIF
            SELECT _lxx
            COUNT FOR NOT DELETED() TO lxx
         CATCH
            lxx = 0
         ENDTRY

         IF lxx > 0

            lcTemp     = SYS(2023) + '\_' + SYS(3)+'.csv'
            SELECT _lxx
            COPY TO (lcTemp) TYPE CSV

            lcDate = STRTRAN(DTOC(DATE()),'/','-') + '-'+STRTRAN(TIME(),':','-')

            lcFileName = ALLTRIM(m.goapp.cclient) + '-' + lcDate + '.csv'

            SET PROCEDURE TO CUSTOM\swftp.prg ADDITIVE
            loIP             = CREATEOBJECT('swftp')
            loIP.lPassiveFTP = .T.
            loIP.cuser       = 'client-backups'
            loIP.cPwd        = 'm]6.X$fKKh96{4&W'
            loIP.cServer     = 'cb.sherware.com'
            loIP.nFTPPort    = 441

            lcReturn = loIP.CONNECT()

* Create file to transfer in temp folder
            lcSourceFile = lcTemp
            lcTargetFile = '_Logs/' + lcFileName

            loIP.cTargetFile = lcTargetFile
            loIP.cSourceFile = lcSourceFile

            lnCount  = 0
            lnResult = 1

            INKEY(1)
            llResult = loIP.SendFile()

            IF NOT llResult
*        MESSAGEBOX(loIP.cerrormsg, 16, 'Update Log Problem')
            ENDIF

            TRY
               ERASE (lcTemp)
            CATCH
            ENDTRY
         ENDIF

*    SET LIBRARY TO &lcLibrary

      CATCH TO loError
         IF THIS.ldebugmode
            MESSAGEBOX('Error:   ' + loError.MESSAGE + CHR(10) + ;
               'Line:    ' + TRANSFORM(loError.LINENO) + CHR(10) + ;
               'Contents: ' + loError.LINECONTENTS,16,'Log Upload Error')
         ENDIF
         llReturn = .F.
      ENDTRY

      IF llReturn
         TRY
            SELECT _lxx
            DELETE ALL
         CATCH
         ENDTRY
      ENDIF

      WAIT CLEAR

      RETURN

   ENDPROC

**********************************
   PROCEDURE LogWellCounts
**********************************
      LOCAL loIP AS 'wwftp'
      LOCAL lcSourceFile, lcTargetFile, lnResult, loError, lcRegCode, lcState, lcString, lcReports
      LOCAL lcCompanies

      #DEFINE CRLF CHR(13) + CHR(10)

      IF NOT IsInternetAvailable()
         RETURN
      ENDIF

      STORE '' TO lcString, lcState, lcReports, lcRegCode, lcCompanies, lcStates

      TRY

  * Get Support expiration date
         lcSupportExpires = THIS.checksupportexp()

* Get the # of wells
         swselect('wells')
         COUNT FOR NOT DELETED() TO lnWells
* Get the # of leases
         swselect('land')
         COUNT FOR NOT DELETED() TO lnLeases
* Get the # of owners
         swselect('investor')
         COUNT FOR NOT DELETED() TO lnOwners

* Build the file
         lcString = 'Client ID,App,Company Name,# of Wells,# of Leases,# of Owners'
         lcString = lcString + CRLF + ;
            m.goapp.cclient + ',' + ;
            m.goapp.cproductname + ',' + ;
            STRTRAN(ALLTRIM(m.goapp.ccompanyname),',',' ') + ',' + ;
            TRANSFORM(lnWells)  + ',' + ;
            TRANSFORM(lnLeases)  + ',' + ;
            TRANSFORM(lnOwners)

         lcTemp     = SYS(2023) + '_' + SYS(3)
         lcFileName = ALLTRIM(m.goapp.cclient) + '-' + ALLTRIM(m.goapp.ccompanyname) + '.csv'
         STRTOFILE(lcString, lcTemp)

         SET PROCEDURE TO CUSTOM\swftp.prg ADDITIVE
         loIP = CREATEOBJECT('swftp')
         loIP.lPassiveFTP = .T.
         loIP.cuser = 'client-backups'
         loIP.cPwd  = "m]6.X$fKKh96{4&W"
         loIP.cServer = 'cb.sherware.com'
         loIP.nFTPPort = 441

         lcReturn = loIP.CONNECT()

* Create file to transfer in temp folder
         lcSourceFile = lcTemp
         lcTargetFile = '_WellCounts/' + lcFileName

         loIP.cTargetFile = lcTargetFile
         loIP.cSourceFile = lcSourceFile

         lnCount  = 0
         lnResult = 1

         INKEY(1)
         llResult = loIP.SendFile()

         IF NOT llResult AND THIS.ldebugmode
            MESSAGEBOX(loIP.cerrormsg, 16, 'Update Log Problem')
         ENDIF

         TRY
            ERASE (lcTemp)
         CATCH
         ENDTRY

*    SET LIBRARY TO &lcLibrary

      CATCH TO loError
         IF THIS.ldebugmode
            MESSAGEBOX('Error:   ' + loError.MESSAGE + CHR(10) + ;
               'Line:    ' + TRANSFORM(loError.LINENO) + CHR(10) + ;
               'Contents: ' + loError.LINECONTENTS,16,'Log Upload Error')
         ENDIF
         llReturn = .F.
      ENDTRY

      WAIT CLEAR

      RETURN

   ENDPROC
*-- Uploads a log file to our server that tells the clients id, name, version, regcode and what state reports they have.
**********************************
   PROCEDURE LogClientInfo
**********************************
      LOCAL loIP AS 'wwftp'
      LOCAL lcSourceFile, lcTargetFile, lnResult, loError, lcRegCode, lcState, lcString, lcReports
      LOCAL lcCompanies, llReturn

      #DEFINE CRLF CHR(13) + CHR(10)

      THIS.LogCodePath(.T.,'CAPP:LogClientInfo')

      IF NOT IsInternetAvailable()
         IF THIS.ldebugmode
            MESSAGEBOX('LogClientInfo: Internet Not Available',16,'Log Client Info')
         ENDIF
         RETURN
      ENDIF
      
      llReturn = .T.

      STORE '' TO lcString, lcState, lcReports, lcRegCode, lcCompanies, lcStates

      TRY

         lcVersion = THIS.cfileversion
         IF NOT VERSION(2) = 2
            lcDate = DTOC(FDATE(HOME()+'sherware.exe'))
            lcTime = FTIME(HOME()+'sherware.exe')
         ELSE
            lcDate = DTOC(FDATE('sherware.exe'))
            lcTime = FTIME('sherware.exe')
         ENDIF
         lcProduct = 'SherWare Financials'
         lcVersion = 'Version: '+ lcVersion
         lcVersionDate = lcDate
         lcVersionTime = lcTime

         lcRegCode = ALLTRIM(THIS.ccode) + '*' + THIS.cstates
         
         lnlen    = LEN(ALLTRIM(THIS.cstates)) / 2
         lnIndex  = 1
         lcStates = ''
         FOR lni = 1 TO lnlen
            IF lnIndex > 1
               lcStates = lcStates + ', '
            ENDIF
            lcState = SUBSTR(ALLTRIM(THIS.cstates), lnIndex, 2)
            lnIndex = lnIndex + 2
            DO CASE
               CASE lcState = opt_OH_Reports
                  lcStates = lcStates + 'OH'
               CASE lcState = opt_PA_Reports
                  lcStates = lcStates + 'PA'
               CASE lcState = opt_WV_Reports
                  lcStates = lcStates + 'WV'
               CASE lcState = opt_TX_Reports
                  lcStates = lcStates + 'TX'
               CASE lcState = opt_WY_Reports
                  lcStates = lcStates + 'WY'
               CASE lcState = opt_CO_Reports
                  lcStates = lcStates + 'CO'
               CASE lcState = opt_OK_Reports
                  lcStates = lcStates + 'OK'
               CASE lcState = opt_NY_Reports
                  lcStates = lcStates + 'NY'
               CASE lcState = opt_LA_Reports
                  lcStates = lcStates + 'LA'
            ENDCASE
         ENDFOR

* Get the companies in company master
         swselect('compmast')
         SET ORDER TO cproducer
         SCAN
            lcCompanies = lcCompanies + compmast.cproducer + CRLF
         ENDSCAN

* Get Support expiration date
         lcSupportExpires = DTOC(THIS.dsupportexpires)

* Build the file
         lcString = 'Client ID: ' + THIS.cclient + CRLF + ;
            'Registered Company: ' + THIS.cregcompany + CRLF + ;
            'Reg Code: ' + lcRegCode + CRLF + ;
            'Support Expires: ' + lcSupportExpires + CRLF + ;
            'State Codes: ' + THIS.cstates + CRLF + ;
            'State Reports: ' + lcStates +  CRLF + CRLF + ;
            'Application: ' + lcProduct + CRLF + ;
            'Version:     ' + lcVersion + CRLF + ;
            'Date:        ' + lcVersionDate + CRLF + ;
            'Time:        ' + lcVersionTime + CRLF + CRLF + ;
            lcCompanies + CRLF + ;
            'IP Address: ' + getipaddr()
         
         lcTemp     = SYS(2023) + '_' + SYS(3)
         lcFileName = ALLTRIM(THIS.cclient) + '-' + THIS.cproductname + '-' + ALLTRIM(THIS.cregcompany) + '.txt'
         STRTOFILE(lcString, lcTemp)

         SET PROCEDURE TO CUSTOM\swftp.prg ADDITIVE
         loIP             = CREATEOBJECT('swftp')
         loIP.lPassiveFTP = .T.
         loIP.cuser       = 'client-backups'
         loIP.cPwd        = 'm]6.X$fKKh96{4&W'
         loIP.cServer     = 'cb.sherware.com'
         loIP.nFTPPort    = 441

         lcReturn = loIP.CONNECT()
         
         IF this.lDebugMode
            ?lcReturn
         ENDIF 

* Create file to transfer in temp folder
         lcSourceFile = lcTemp
         lcTargetFile = '_ClientLogs/' + lcFileName

         loIP.cTargetFile = lcTargetFile
         loIP.cSourceFile = lcSourceFile

         lnCount  = 0
         lnResult = 1

         INKEY(1)
         llResult = loIP.SendFile()

         IF NOT llResult AND THIS.ldebugmode
            MESSAGEBOX(loIP.cerrormsg, 16, 'Update Log Problem')
         ENDIF

         TRY
            ERASE (lcTemp)
         CATCH
         ENDTRY

*    SET LIBRARY TO &lcLibrary

      CATCH TO loError
         IF THIS.ldebugmode
            MESSAGEBOX('Error:   ' + loError.MESSAGE + CHR(10) + ;
               'Line:    ' + TRANSFORM(loError.LINENO) + CHR(10) + ;
               'Contents: ' + loError.LINECONTENTS,16,'Log Upload Error')
         ENDIF
         llReturn = .F.
      ENDTRY

      WAIT CLEAR

      RETURN
   ENDPROC

**********************************
   PROCEDURE checksupportexp
**********************************
      LOCAL lcCode, lcClient, lnCode, lnClient, oRegCode

      ldExpDate = '11/02/1960'

      THIS.LogCodePath(.T.,'CAPP:CheckSupportExp')

      TRY
         SET PROCEDURE TO CUSTOM\swregcode ADDITIVE
* Start the regcode object
         oRegCode = CREATEOBJECT('swregcode', SYS(5) + CURDIR() + 'datafiles\')

* If demo mode bail out
         IF NOT oRegCode.GetOpt(5)
            ldExpDate = '12/31/2060'
            EXIT
         ENDIF

         lnClient = oRegCode.GetCode(1)
         lcCode   = oRegCode.GetCode(2)
         lcName   = oRegCode.GetCode(3)

* Get the support expiration date
         ldExpDate = DTOC(oRegCode.CheckSum(lnClient, lcCode, .F., .T.))
      CATCH TO loError
         ldExpDate = '11/02/1960'
      ENDTRY

      RETURN ldExpDate
   ENDPROC


*-- Starts and stops Rushmore optimization recording sys(3054)
**********************************
   PROCEDURE Rushmore
**********************************
      LPARAMETERS tlStart, tcDesc
      LOCAL myMemVar

      THIS.LogCodePath(.T.,'CAPP:Rushmore')

      IF THIS.rushmoreopt = .T.
         IF tlStart
            lcFolder = THIS.ccommonfolder + 'Rushmore\'
            IF NOT DIRECTORY(lcFolder)
               MKDIR (lcFolder)
            ENDIF
            lcFile = lcFolder + STRTRAN(tcDesc, ' ', '') + '.txt'
            SYS(3092, lcFile)
            SYS(3054, 12, 'myMemVar')
         ELSE
            SYS(3054, 0)
            SYS(3092, '')
         ENDIF
      ENDIF
   ENDPROC

**********************************
   PROCEDURE oLogger_Access
**********************************

      IF VARTYPE(THIS.ologger) # 'O'
         THIS.ologger          = NEWOBJECT('SFLogger', 'SFLogger.vcx')
         THIS.ologger.cLogFile = THIS.ccommonfolder + 'Diags\Diagnostic_' + STRTRAN(DTOC(DATE()), '/', '-') + '-' + STRTRAN(TIME(), ':', '-') + '.txt'
      ENDIF

      RETURN THIS.ologger

**********************************
   PROCEDURE SetupLogger
**********************************
      THIS.LogCodePath(.T.,'CAPP:SetupLogger')

* Creates the oLogger object for intrumentation
      IF NOT DIRECTORY(THIS.ccommonfolder + 'Diags')
         MKDIR (THIS.ccommonfolder + 'Diags')
      ENDIF

      IF FILE(THIS.ccommonfolder + 'Diag.cfg')
         THIS.ologger.lLoggingEnabled = .T.
         TRY
            ERASE (THIS.ologger.cLogFile)
         CATCH
         ENDTRY
      ELSE
         THIS.ologger.lLoggingEnabled = .F.
      ENDIF
   ENDPROC

**********************************
   PROCEDURE oReport_Access
**********************************

      IF VARTYPE(THIS.oreport) # 'O'
         THIS.oreport = CREATEOBJECT('swreport')
      ENDIF

      RETURN THIS.oreport
   ENDPROC

**********************************
   PROCEDURE CheckXFRXFiles
**********************************
      LPARAMETERS tlForce
* Check to see if we have the most up to date help file

      LOCAL llReturn, loError
      LOCAL laFile[1], ldFileDate, lnFound, llReplace

      llReturn  = .T.

      THIS.LogCodePath(.T.,'CAPP:CheckXFRXFiles')

      IF FILE(m.goapp.ccommonfolder + 'xfrxdebug.txt')
         llDebug = .T.
      ELSE
         llDebug = .F.
      ENDIF
      TRY

         IF NOT DIRECTORY(THIS.ccommonfolder + 'bin\')
            MKDIR (THIS.ccommonfolder + 'bin\')
         ENDIF

         IF NOT FILE(m.goapp.ccommonfolder + 'Bin\xfrx_' + THIS.XFRXVersion + '.txt')
            llReturn = GetXFRX()
            IF llReturn
               loListener = XFRX('XFRX#LISTENER')
               lnReturn   = loListener.SetParams('datafiles/test.pdf', SYS(2023), .T.,         '',       .T.,     .T.,              'PDF',     '',      .F.,        .F.,         .F.)
               RELEASE loListener
               IF lnReturn # 0
                  llReturn = .F.
               ELSE
                  STRTOFILE('Version ' + THIS.XFRXVersion, m.goapp.ccommonfolder + 'Bin\xfrx_' + THIS.XFRXVersion + '.txt')
               ENDIF
            ENDIF
         ENDIF


         IF NOT llReturn
            MESSAGEBOX('The Report Preview Files were unable to be downloaded at this time. ' + ;
               'Check with Pivoten support and give them this version number: ' + ;
               'XFRX_' + m.goapp.XFRXVersion, 16, 'Report Preview File Problem')
         ENDIF

      CATCH TO loError
         llReturn = .F.
         IF llDebug
            WAIT WINDOW loError.MESSAGE
         ENDIF
         DO errorlog WITH 'CheckXFRXFiles', loError.LINENO, 'App Startup', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE XFRXErase
**********************************
      LOCAL llDebug

      llDebug = .F.

      THIS.LogCodePath(.T.,'CAPP:XFRXErase')

* This method erases the xfrx files from the executable folder.
* ShellExecute asks to elevate so the files can be deleted
      IF FILE(THIS.ccommonfolder + 'ignorexfrx.txt')
         RETURN .T.
      ENDIF

      lcdir = SYS(5) + CURDIR()
      IF FILE('datafiles\sedebug.txt')
         llDebug = .T.
      ENDIF
      IF llDebug
         MESSAGEBOX('Current directory is: ' + lcdir, 0, 'Current Directory')
      ENDIF
      llFound = .F.
      lcText  = ''
      swselect('xfrxfiles')
      SCAN
         m.cname = cname
         IF 'vfpcompression' $ LOWER(m.cname)
            LOOP
         ENDIF
         IF FILE(ADDBS(lcdir) + ALLTRIM(m.cname))
            lcText  = lcText + 'Del ' + '"' + ADDBS(lcdir) + m.cname + '"' + CHR(13) + CHR(10)
            llFound = .T.
         ENDIF
      ENDSCAN

      lcdir = FULLPATH(THIS.ccommonfolder)

      IF llDebug
         MESSAGEBOX('Path = ' + lcdir, 0, 'Debug')
      ENDIF

      SELECT xfrxfiles
      SCAN
         m.cname = cname
         IF 'vfpcompression' $ LOWER(m.cname)
            LOOP
         ENDIF
         IF FILE(ADDBS(lcdir) + ALLTRIM(m.cname))
            lcText  = lcText + 'Del ' + '"' + ADDBS(lcdir) + m.cname + '"' + CHR(13) + CHR(10)
            llFound = .T.
         ENDIF
      ENDSCAN

      IF llDebug AND NOT llFound
         MESSAGEBOX('XFRX Files not in exe directory', 0, 'Current Directory')
      ENDIF

      IF llFound
         DECLARE INTEGER ShellExecute IN Shell32.DLL ;
            INTEGER nWinHandle, ; && handle of parent window
         STRING cOperation, ; && operation to perform
         STRING cFileName, ; && filename
         STRING cParameters, ; && parameters for the executable
         STRING cDirectory, ; && default directory
         INTEGER nShowWindow && window state

         IF llDebug
            lcText = lcText + CHR(13) + CHR(10) + ;
               'pause'
         ENDIF


         MESSAGEBOX('There are some files that need to be installed in order for report previews to work properly. ' + ;
            "After clicking OK on this message you'll be asked if it is ok for this application to make changes. " + ;
            'Reply YES for the installation to complete successfully.', 0, 'Installing Files Next')
         lcFile = THIS.ccommonfolder + 'xfrx.bat'
         STRTOFILE(lcText, lcFile)
         lcFile = FULLPATH(THIS.ccommonfolder + 'xfrx.bat')

         lnReturn = ShellExecute(0, 'RunAs', lcFile, ' ', '', 1)

         IF lnReturn < 32 AND llDebug
            DO CASE
               CASE lnReturn = 8
                  lcMessage = 'Out of memory'
               CASE lnReturn = 2
                  lcMessage = 'File not found'
               CASE lnReturn = 3
                  lcMessage = 'Path not found'
               CASE lnReturn = 11
                  lcMessage = 'Exe is invalid'
               CASE lnReturn = 5
                  lcMessage = 'Access Denied'
               CASE lnReturn = 27
                  lcMessage = 'Invalid file association'
               OTHERWISE
                  lcMessage = 'Return code: ' + TRANSFORM(lnReturn)
            ENDCASE
            MESSAGEBOX('Install: ' + lcMessage, 0, 'ShellExecute Return')
         ENDIF
      ENDIF
   ENDPROC

**********************************
   PROCEDURE Appreg02_Replace
**********************************
      LOCAL lnFound, m.dfiledate, llReplace, ldFileDate

      llReplace = .F.

      THIS.LogCodePath(.T.,'CAPP:Appreg02_Replace')

      lnFound     = ADIR(laFile, THIS.ccommonfolder + 'appreg02.dbf')
      m.dfiledate = {9/27/2017}

      IF lnFound >= 0
         IF lnFound > 0
            ldFileDate = laFile[1, 3]
            IF ldFileDate <= m.dfiledate
               llReplace = .T.
            ENDIF
         ELSE
            llReplace = .T.
         ENDIF
      ELSE
         llReplace = .T.
      ENDIF

      IF llReplace
         TRY
            IF NOT USED('appreg02')
               USE (THIS.ccommonfolder + 'appreg02') IN 0
            ENDIF
            IF NOT USED('tempreg02')
               USE tempreg02 IN 0
            ENDIF
            SELECT appreg02
            DELETE ALL
            APPEND FROM DBF('tempreg02')
         CATCH
            MESSAGEBOX('appreg02 copy failed.', 0, 'appreg02')
         ENDTRY
      ENDIF
   ENDPROC

**********************************
   PROCEDURE Setup_Screenshot
**********************************
      THIS.LogCodePath(.T.,'CAPP:Setup_Screenshot')

      RETURN
* Create the oScreenshot object
      IF NOT 'screenshot' $ LOWER(SET('procedure'))
         SET PROCEDURE TO screenshot.prg ADDITIVE
      ENDIF
      THIS.oscreenshot = CREATEOBJECT('screenshot')
   ENDPROC

**********************************
   PROCEDURE oScreenshot_Access
**********************************

      IF NOT 'screenshot' $ LOWER(SET('procedure'))
         SET PROCEDURE TO screenshot.prg ADDITIVE
      ENDIF
      THIS.oscreenshot = CREATEOBJECT('screenshot')
      RETURN THIS.oscreenshot
   ENDPROC

**********************************
   PROCEDURE oUpdate_Access
**********************************
      IF VARTYPE(THIS.oupdate) # 'O'
         IF NOT 'swftp' $ LOWER(SET('procedure'))
            SET PROCEDURE TO CUSTOM\swftp.prg ADDITIVE
         ENDIF
         THIS.oupdate = CREATEOBJECT('swUpdates')
      ENDIF
      RETURN THIS.oupdate
   ENDPROC

**********************************
   PROCEDURE OQB_Access
**********************************

      IF VARTYPE(THIS.oqb) # 'O'
         IF NOT 'swqb' $ LOWER(SET('procedure'))
            SET PROCEDURE TO CUSTOM\swqb.prg ADDITIVE
         ENDIF
         THIS.oqb = CREATEOBJECT("qbutils")
      ENDIF

      RETURN THIS.oqb

**********************************
   PROCEDURE CheckVFPVersion
**********************************

      THIS.LogCodePath(.T.,'CAPP:CheckVFPVersion')
      TRY
         IF FILE('vfp9r.dll')
            lnx    = AGETFILEVERSION(afile, 'vfp9r.dll')
            IF lnx = 15
               lcVersion = afile[4]
               IF NOT '7423' $ lcVersion
                  MESSAGEBOX('An older version of the run-time libraries is in use for this Pivoten application. ' + ;
                     'Please contact Pivoten support for an update. Send an email to support@Pivoten.com ' + ;
                     'or call (330) 262-0200.', 48, 'Outdated Run-time Libraries')
               ENDIF
            ENDIF
         ENDIF
      CATCH
      ENDTRY
   ENDPROC

**********************************
   PROCEDURE Encryptdata
**********************************

      THIS.LogCodePath(.T.,'CAPP:Encryptdata')

      IF NOT USED('Compmast')
         USE (THIS.ccommonfolder + 'Compmast') IN 0
      ENDIF
      llAdmin = THIS.osecurity.HasPrivilege('Administrator')
      SELECT compmast
      LOCATE FOR cidcomp == THIS.cidcomp
      IF FOUND()

         IF THIS.lencrypted
            IF NOT FILE(THIS.ccommonfolder + 'welltax.txt')
* Check well taxid because we didn't initally encrypt it
               SELECT cwelltaxid FROM wells WHERE NOT EMPTY(cwelltaxid) AND ISDIGIT(LEFT(cwelltaxid, 1)) INTO CURSOR temp
               IF _TALLY > 0
                  swselect('wells')
                  SCAN FOR NOT EMPTY(cwelltaxid)
                     IF ISDIGIT(LEFT(cwelltaxid, 1))
                        REPLACE cwelltaxid WITH cmEncrypt(ALLTRIM(cwelltaxid), THIS.cencryptionkey)
                     ENDIF
                  ENDSCAN
                  STRTOFILE('Done', THIS.ccommonfolder + 'welltax.txt')
               ENDIF
            ENDIF
         ELSE
            IF NOT THIS.lencrypted AND NOT compmast.xFlag = '453E' AND llAdmin
               IF MESSAGEBOX('This version of Pivoten includes encryption for all ' + CHR(13) + ;
                     'federal tax ids and banking information. Before encrypting ' + CHR(13) + ;
                     'the data a backup will be performed.' + CHR(13) + CHR(13) + ;
                     'After encryption the tax ids and banking information will ' + CHR(13) + ;
                     'still be visible on the screen and in reports but the raw ' + CHR(13) + ;
                     'data will be encrypted so that anyone looking at the data ' + CHR(13) + ;
                     'outside of Pivoten will not be able to view this information.' + CHR(13) + CHR(13) + ;
                     'Do you want to encrypt the tax id codes?', 36, 'Encrypt Data') = 6

                  IF THIS.BackupDataBeforeEncryption()
                     THIS.cencryptionkey = 'SherWareKey_@8@2899909'
                     IF NOT USED('Compmast')
                        USE (THIS.ccommonfolder + 'Compmast') IN 0
                     ENDIF
                     SELECT compmast
                     LOCATE FOR cidcomp == THIS.cidcomp
                     IF ISDIGIT(LEFT(ctaxid, 1))  && Make sure company tax id is encrypted
                        REPLACE ctaxid WITH cmEncrypt(compmast.ctaxid, THIS.cencryptionkey)
                     ENDIF
                     THIS.ctaxid = compmast.ctaxid
                     oProgress   = THIS.omessage.progressbarex('Encrypting Data...')
                     swselect('investor')
                     lnMax = RECCOUNT()
                     swselect('vendor')
                     lnMax = lnMax + RECCOUNT()
                     swselect('tax1099')
                     lnMax = lnMax + RECCOUNT()
                     swselect('programs')
                     lnMax = lnMax + RECCOUNT()
                     IF THIS.lamversion
                        swselect('emps')
                        lnMax = lnMax + RECCOUNT()
                        swselect('custs')
                        lnMax = lnMax + RECCOUNT()
                     ENDIF
                     oProgress.setprogressrange(0, lnMax)
                     lnCount = 0

                     SELECT investor
                     SCAN
                        oProgress.SetProgressMessage('Owner: ' + investor.cownerid)
                        oProgress.updateprogress(lnCount)
                        lnCount = lnCount + 1
                        REPLACE ctaxid WITH cmEncrypt(investor.ctaxid, THIS.cencryptionkey)
                        REPLACE cBankAcct WITH cmEncrypt(cBankAcct, THIS.cencryptionkey)
                        REPLACE cBankTransit WITH cmEncrypt(cBankTransit, THIS.cencryptionkey)
                     ENDSCAN
                     SELECT wells
                     SCAN
                        oProgress.SetProgressMessage('Well: ' + wells.cwellid)
                        oProgress.updateprogress(lnCount)
                        lnCount = lnCount + 1
                        REPLACE cwelltaxid WITH cmEncrypt(ALLTRIM(wells.cwelltaxid), THIS.cencryptionkey)
                     ENDSCAN
                     swselect('vendor')
                     SCAN
                        oProgress.SetProgressMessage('Vendor: ' + vendor.cvendorid)
                        oProgress.updateprogress(lnCount)
                        lnCount = lnCount + 1
                        REPLACE ctaxid WITH cmEncrypt(vendor.ctaxid, THIS.cencryptionkey)
                     ENDSCAN
                     swselect('tax1099')
                     SCAN
                        oProgress.SetProgressMessage('1099: ' + tax1099.cid)
                        oProgress.updateprogress(lnCount)
                        lnCount = lnCount + 1
                        REPLACE ctaxid WITH cmEncrypt(tax1099.ctaxid, THIS.cencryptionkey)
                     ENDSCAN

                     swselect('tax1099states')
                     SCAN
                        REPLACE cpayerno WITH cmEncrypt(cpayerno, THIS.cencryptionkey)
                     ENDSCAN

                     swselect('programs')
                     SCAN
                        oProgress.SetProgressMessage('Programs: ' + programs.cprogcode)
                        oProgress.updateprogress(lnCount)
                        lnCount = lnCount + 1
                        REPLACE cprogtaxid WITH cmEncrypt(programs.cprogtaxid, THIS.cencryptionkey)
                     ENDSCAN

                     IF THIS.lamversion
                        swselect('emps')
                        SCAN
                           oProgress.SetProgressMessage('Employee: ' + emps.cempid)
                           oProgress.updateprogress(lnCount)
                           lnCount = lnCount + 1
                           REPLACE cssn WITH cmEncrypt(emps.cssn, THIS.cencryptionkey)
                        ENDSCAN
                        swselect('custs')
                        SCAN
                           oProgress.SetProgressMessage('Customer: ' + custs.ccustid)
                           oProgress.updateprogress(lnCount)
                           lnCount = lnCount + 1
                           REPLACE ctaxid WITH cmEncrypt(custs.ctaxid, THIS.cencryptionkey)
                        ENDSCAN
                        swselect('prw2file')
                        SCAN
                           oProgress.SetProgressMessage('W2: ' + prw2file.cempid)
                           oProgress.updateprogress(lnCount)
                           lnCount = lnCount + 1
                           REPLACE cemptaxid WITH cmEncrypt(prw2file.cemptaxid, THIS.cencryptionkey)
                        ENDSCAN
                     ENDIF
                     WAIT CLEAR
                     swselect('options')
                     REPLACE lencrypted WITH .T.
                     REPLACE cBankAcct WITH cmEncrypt(cBankAcct, THIS.cencryptionkey)
                     REPLACE cBankTransit WITH cmEncrypt(cBankTransit, THIS.cencryptionkey)
                     THIS.lencrypted = .T.
                  ENDIF
               ELSE
                  MESSAGEBOX('This dialog will come up each time you open this company until the data is encrypted.', 48, 'Encrypt Data')
                  THIS.cencryptionkey = ''
               ENDIF
               IF VARTYPE(oProgress) = 'O'
                  oProgress.closeprogress()
                  RELEASE oProgress
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      IF THIS.lencrypted
         THIS.cencryptionkey = 'SherWareKey_@8@2899909'
      ELSE
         THIS.cencryptionkey = ''
      ENDIF
   ENDPROC

**********************************
   PROCEDURE BackupDataBeforeEncryption
**********************************
      LOCAL lcDataPath, lcFileName, lcFolderName, lcBackupPath

      THIS.LogCodePath(.T.,'CAPP:BackupDataBeforeEncryption')

      THIS.closealldata()

      IF NOT isfilelocked('investor')

         IF TYPE('THIS') = 'O'
            lcDataPath = ALLT(THIS.cdatafilepath)
            IF NOT ':' $ lcDataPath AND NOT '\\' $ lcDataPath AND LEFT(lcDataPath, 1) # '\'
               lcSavePath = ALLT(CURDIR())
               lcDataPath = SYS(5) + CURDIR() + lcDataPath
            ENDIF
            lcBackupPath = lcDataPath
            lcFolderName = lcDataPath
            lcDataPath   = '"' + lcDataPath + '*.*' + '"'
         ELSE
            lcBackupPath = ALLTRIM(GETDIR())
            lcDataPath   = lcBackupPath + '*.*'
         ENDIF

         IF NOT '\' $ lcDataPath
            lcDataPath = 'Data\*.*'
         ENDIF

* Create the backup folders if needed
         IF NOT DIRECTORY(lcBackupPath + 'Backups')
            MD (lcBackupPath + 'Backups')
         ENDIF

         lcBackupPath = lcBackupPath + 'Backups\'
         lcFolder     = lcBackupPath
         IF NOT DIRECTORY(lcBackupPath)
            MD (lcBackupPath)
         ENDIF

         lcFileName   = 'BeforeEncryption-' + ALLTRIM(STRTRAN(THIS.ccompanyname, ' ', '')) + '.zip'
         lcBackupPath = ADDBS(lcBackupPath)

         llReturn = .T.
* Create the backup
         lnError = swbackup('B', lcFolderName, ALLTRIM(lcFileName), lcBackupPath)

         DO CASE
            CASE lnError = 0
               WAIT WIND NOWAIT 'Backup Completed'
               SET DATASESSION TO &lnSession
               llReturn = .T.
            CASE lnError = 4
               MESSAGEBOX('Backup Encountered Errors. Unable to create backup file.', 16, 'Backup Problem')
               llReturn = .F.
            CASE lnError = 6
               MESSAGEBOX('Backup Encountered Errors. Unable to compress file.', 16, 'Backup Problem')
               llReturn = .F.
         ENDCASE

         ometa.oSDTMgr.OpenAllTables(, .T.)
      ELSE
         MESSAGEBOX('The files cannot be encrypted now because someone else has the company open. ' + ;
            'Have them close out of Pivoten and then open this company again.', 16, 'Encrypt Data')
         llReturn = .F.
      ENDIF

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE SetPrivileges
**********************************
      WITH THIS
         THIS.LogCodePath(.T.,'CAPP:SetPrivileges')

         .osecurity._grantAccess(THIS.cuser)
         IF .osecurity.HasPrivilege('Administrator') OR THIS.lnosecurity
            STORE .T. TO .lafedata, .lafereports, .lapdata, .lapreports, .lardata, .larreports
            STORE .T. TO .lgldata, .lglreports, .lglfinancials, .llanddata, .llandreports
            STORE .T. TO .lbrinedata, .lbrinereports, .lcashdata, .lcashreports, .lcheckprinting
            STORE .T. TO .lrevdistdata, .lrevdistreports, .ljibdata, .ljibreports
            STORE .T. TO .ladmin, .linvestdata, .linvestreports, .lreportmenu
            STORE .T. TO .lhousegasdata, .lhousegasreports, .lpartnerdata, .lpartnerreports
            STORE .T. TO .lpayrolldata, .lpayrollreports, .ldoidata
            STORE .T. TO .lgraphs, .ladhocreporting, .lform1065reporting
            STORE .T. TO .loffsitebackup, .lonlinereporting, .lbankinfo, .ltaxids
            STORE .F. TO .lreadonly
         ELSE
            .lreportmenu        = THIS.osecurity.HasPrivilege('Report Menu')
            .lapdata            = THIS.osecurity.HasPrivilege('AP Data Entry') OR THIS.osecurity.IsMemberOf('Accounts Payable')
            .lapreports         = THIS.osecurity.HasPrivilege('AP Reporting') OR THIS.osecurity.IsMemberOf('Accounts Payable')
            .lardata            = THIS.osecurity.HasPrivilege('AR Data Entry') OR THIS.osecurity.IsMemberOf('Accounts Receivable')
            .larreports         = THIS.osecurity.HasPrivilege('AR Reporting')OR THIS.osecurity.IsMemberOf('Accounts Receivable')
            .lgldata            = THIS.osecurity.HasPrivilege('GL Data Entry') OR THIS.osecurity.IsMemberOf('G/L')
            .lglreports         = THIS.osecurity.HasPrivilege('GL Reporting') OR THIS.osecurity.IsMemberOf('G/L')
            .lglfinancials      = THIS.osecurity.HasPrivilege('GL Financial Reporting') OR THIS.osecurity.IsMemberOf('G/L')
            .llanddata          = THIS.osecurity.HasPrivilege('Land Data Entry') OR THIS.osecurity.IsMemberOf('Land Management')
            .llandreports       = THIS.osecurity.HasPrivilege('Land Reporting') OR THIS.osecurity.IsMemberOf('Land Management')
            .lpayrolldata       = THIS.osecurity.HasPrivilege('Payroll Data Entry') OR THIS.osecurity.IsMemberOf('Payroll')
            .lpayrollreports    = THIS.osecurity.HasPrivilege('Payroll Reporting') OR THIS.osecurity.IsMemberOf('Payroll')
            .lrevdistdata       = THIS.osecurity.HasPrivilege('Rev Dist Data Entry') OR THIS.osecurity.IsMemberOf('Revenue Distribution')
            .lrevdistreports    = THIS.osecurity.HasPrivilege('Rev Dist Reporting') OR THIS.osecurity.IsMemberOf('Revenue Distribution Reports')
            .lbrinedata         = THIS.osecurity.HasPrivilege('Brine Data Entry') OR THIS.osecurity.IsMemberOf('Brine Hauler')
            .lbrinereports      = THIS.osecurity.HasPrivilege('Brine Reporting') OR THIS.osecurity.IsMemberOf('Brine Hauler')
            .lafedata           = THIS.osecurity.HasPrivilege('AFE Data Entry') OR THIS.osecurity.IsMemberOf('AFE')
            .lafereports        = THIS.osecurity.HasPrivilege('AFE Reporting') OR THIS.osecurity.IsMemberOf('AFE')
            .linvestdata        = THIS.osecurity.HasPrivilege('Investment Data Entry') OR THIS.osecurity.IsMemberOf('Investments')
            .linvestreports     = THIS.osecurity.HasPrivilege('Investment Reporting') OR THIS.osecurity.IsMemberOf('Investments')
            .lcashdata          = THIS.osecurity.HasPrivilege('Cash Data Entry') OR THIS.osecurity.IsMemberOf('Cash')
            .lcashreports       = THIS.osecurity.HasPrivilege('Cash Reporting') OR THIS.osecurity.IsMemberOf('Cash')
            .lcheckprinting     = THIS.osecurity.HasPrivilege('Check Printing') OR THIS.osecurity.IsMemberOf('Cash')
            .lreadonly          = THIS.osecurity.HasPrivilege('Read Only')
            .lhousegasdata      = THIS.osecurity.HasPrivilege('House Gas Data Entry') OR THIS.osecurity.IsMemberOf('House Gas')
            .lhousegasreports   = THIS.osecurity.HasPrivilege('House Gas Reporting') OR THIS.osecurity.IsMemberOf('House Gas')
            .ljibdata           = THIS.osecurity.HasPrivilege('JIB Data Entry') OR THIS.osecurity.IsMemberOf('JIB Processing')
            .ljibreports        = THIS.osecurity.HasPrivilege('JIB Reporting') OR THIS.osecurity.IsMemberOf('JIB Processing')
            .ldoidata           = THIS.osecurity.HasPrivilege('DOI Data Entry') OR THIS.osecurity.IsMemberOf('JIB Processing') OR  THIS.osecurity.IsMemberOf('Revenue Distribution')
            .lpartnerdata       = THIS.osecurity.HasPrivilege('Partnership Data Entry') OR THIS.osecurity.IsMemberOf('Partnerships')
            .lpartnerreports    = THIS.osecurity.HasPrivilege('Partnership Reporting') OR THIS.osecurity.IsMemberOf('Partnerships')
            .lgraphs            = THIS.osecurity.HasPrivilege('Graphing')
            .lform1065reporting = THIS.osecurity.HasPrivilege('Form 1065 Reporting')
            .ladhocreporting    = THIS.osecurity.HasPrivilege('Ad Hoc Reporting')
            .loffsitebackup     = THIS.osecurity.HasPrivilege('Offsite Backup')
            .lonlinereporting   = THIS.osecurity.HasPrivilege('Online Reporting')
            .lbankinfo          = THIS.osecurity.HasPrivilege('Bank Info')
            .ltaxids            = THIS.osecurity.HasPrivilege('Tax IDs')
            .ladmin             = .F.
            .lreportmenu = .lapreports OR .larreports OR .lglreports OR .llandreports OR ;
               .lglfinancials OR .lpayrollreports OR .lrevdistreports OR ;
               .lbrinereports OR .lafereports OR .linvestreports OR ;
               .lcashreports OR .ljibreports OR .lhousegasreports OR ;
               .lpartnerreports OR .ladhocreporting OR .lform1065reporting OR ;
               .lgraphs

         ENDIF
      ENDWITH
   ENDPROC

**********************************
   PROCEDURE FixCOMPGATH
**********************************

      THIS.LogCodePath(.T.,'CAPP:FixCompGath')

* Remove COMP and GATH from revcats
      swselect('revcat')
      DELETE FROM revcat WHERE INLIST(crevtype, 'COMP', 'GATH')
      USE IN revcat

      IF THIS.lpluggingmodule
         TRY
            swselect('expcat')
            SET ORDER TO cidexpc
            GO BOTT
            lnkey = VAL(cidexpc)
            lnkey = lnkey + 1
            SET DELETED OFF
            LOCATE FOR ccatcode = 'PLUG'
            IF NOT FOUND()
               m.ccatcode  = 'PLUG'
               m.cCateg    = 'Plugging Fund Charge'
               m.cDescrip  = 'Plugging Fund Charge'
               m.cexpclass = 'P'
               m.ctaxcode  = 'OE'
               m.cidexpc   = THIS.oregistry.incrementcounter('%Shared.Counters.Expense Category')
               INSERT INTO expcat FROM MEMVAR
            ELSE
               IF DELETED()
                  RECALL
               ENDIF
               REPLACE cexpclass WITH 'P'
            ENDIF
            SET DELETED ON
         CATCH
         ENDTRY
      ENDIF

      swselect('expcat')
      SET ORDER TO cidexpc
      GO BOTT
      lnkey = VAL(cidexpc)
      lnkey = lnkey + 1
      SET DELETED OFF
      SELECT expcat
      LOCATE FOR ccatcode = 'COMP'
      IF NOT FOUND()
         m.ccatcode  = 'COMP'
         m.cCateg    = 'Compression Charges'
         m.cDescrip  = 'Compression Charges'
         m.cexpclass = 'G'
         m.ctaxcode  = 'OE'
         m.cidexpc   = THIS.oregistry.incrementcounter('%Shared.Counters.Expense Category')
         LOCATE FOR cidexpc = m.cidexpc
         DO WHILE FOUND()
            m.cidexpc   = THIS.oregistry.incrementcounter('%Shared.Counters.Expense Category')
            SELECT expcat
            LOCATE FOR cidexpc = m.cidexpc
         ENDDO

         lnkey       = lnkey + 1
         INSERT INTO expcat FROM MEMVAR
      ELSE
         IF DELETED()
            RECALL
         ENDIF
      ENDIF
      LOCATE FOR ccatcode = 'GATH'
      IF NOT FOUND()
         m.ccatcode  = 'GATH'
         m.cCateg    = 'Gathering Charges'
         m.cDescrip  = 'Gathering Charges'
         m.cexpclass = 'G'
         m.ctaxcode  = 'OE'
         m.cidexpc   = THIS.oregistry.incrementcounter('%Shared.Counters.Expense Category')
         LOCATE FOR cidexpc = m.cidexpc
         DO WHILE FOUND()
            m.cidexpc   = THIS.oregistry.incrementcounter('%Shared.Counters.Expense Category')
            SELECT expcat
            LOCATE FOR cidexpc = m.cidexpc
         ENDDO
         INSERT INTO expcat FROM MEMVAR
      ELSE
         IF DELETED()
            RECALL
         ENDIF
      ENDIF
      SET DELETED ON
   ENDPROC

**********************************
   PROCEDURE FixEncryption
**********************************
* Encrypts any data that isn't encrypted but should be

      THIS.LogCodePath(.T.,'CAPP:FixEncryption')

      swselect('options')
      GO TOP
      IF options.lencrypted
         TRY
            swselect('investor')
            LOCATE FOR ISDIGIT(LEFT(ctaxid, 1))
            IF FOUND()
               SCAN
                  llDigits = .F.
                  lcDigits = LEFT(ctaxid, 2)
                  IF LEN(lcDigits) = 2
                     IF ISDIGIT(LEFT(lcDigits, 1)) AND ISDIGIT(RIGHT(lcDigits, 1))
                        llDigits = .T.
                     ENDIF
                  ENDIF
                  IF llDigits
                     REPLACE ctaxid WITH cmEncrypt(ctaxid, THIS.cencryptionkey)
                  ENDIF
               ENDSCAN
            ENDIF
            swselect('vendor')
            LOCATE FOR ISDIGIT(LEFT(ctaxid, 1))
            IF FOUND()
               SCAN
                  llDigits = .F.
                  lcDigits = LEFT(ctaxid, 2)
                  IF LEN(lcDigits) = 2
                     IF ISDIGIT(LEFT(lcDigits, 1)) AND ISDIGIT(RIGHT(lcDigits, 1))
                        llDigits = .T.
                     ENDIF
                  ENDIF
                  IF llDigits
                     REPLACE ctaxid WITH cmEncrypt(ctaxid, THIS.cencryptionkey)
                  ENDIF
               ENDSCAN
            ENDIF
            IF THIS.lamversion
               swselect('prw2file')
               LOCATE FOR ISDIGIT(LEFT(cemptaxid, 1))
               IF FOUND()
                  SCAN
                     llDigits = .F.
                     lcDigits = LEFT(cemptaxid, 2)
                     IF LEN(lcDigits) = 2
                        IF ISDIGIT(LEFT(lcDigits, 1)) AND ISDIGIT(RIGHT(lcDigits, 1))
                           llDigits = .T.
                        ENDIF
                     ENDIF
                     IF llDigits
                        REPLACE cemptaxid WITH cmEncrypt(prw2file.cemptaxid, THIS.cencryptionkey)
                     ENDIF
                  ENDSCAN
               ENDIF
            ENDIF
         CATCH TO loError
         ENDTRY
      ENDIF
   ENDPROC

**********************************
   PROCEDURE FixTaxSection
**********************************
      THIS.LogCodePath(.T.,'CAPP:FixTaxSection')
      TRY
         swselect('taxcodes')
         SET DELETED OFF
         LOCATE FOR ctaxcode = 'OE'
         IF NOT FOUND()
            m.ctaxcode = 'OE'
            m.cdesc    = 'Lease Operating Expenses'
            INSERT INTO taxcodes FROM MEMVAR
         ELSE
            IF DELETED()
               RECALL
            ENDIF
         ENDIF
         LOCATE FOR ctaxcode = 'LC'
         IF NOT FOUND()
            m.ctaxcode = 'LC'
            m.cdesc    = 'Leasehold Costs'
            INSERT INTO taxcodes FROM MEMVAR
         ELSE
            IF DELETED()
               RECALL
            ENDIF
         ENDIF
         LOCATE FOR ctaxcode = 'ID'
         IF NOT FOUND()
            m.ctaxcode = 'ID'
            m.cdesc    = 'Intangible Drilling'
            INSERT INTO taxcodes FROM MEMVAR
         ELSE
            IF DELETED()
               RECALL
            ENDIF
         ENDIF
         LOCATE FOR ctaxcode = 'IC'
         IF NOT FOUND()
            m.ctaxcode = 'IC'
            m.cdesc    = 'Intangible Completion'
            INSERT INTO taxcodes FROM MEMVAR
         ELSE
            IF DELETED()
               RECALL
            ENDIF
         ENDIF
         LOCATE FOR ctaxcode = 'TC'
         IF NOT FOUND()
            m.ctaxcode = 'TC'
            m.cdesc    = 'Tangible Completion'
            INSERT INTO taxcodes FROM MEMVAR
         ELSE
            IF DELETED()
               RECALL
            ENDIF
         ENDIF
         LOCATE FOR ctaxcode = 'TD'
         IF NOT FOUND()
            m.ctaxcode = 'TD'
            m.cdesc    = 'Tangible Drilling'
            INSERT INTO taxcodes FROM MEMVAR
         ELSE
            IF DELETED()
               RECALL
            ENDIF
         ENDIF
         LOCATE FOR ctaxcode = 'TE'
         IF NOT FOUND()
            m.ctaxcode = 'TE'
            m.cdesc    = 'Tangible Equipment'
            INSERT INTO taxcodes FROM MEMVAR
         ELSE
            IF DELETED()
               RECALL
            ENDIF
         ENDIF
         SET DELETED ON
      CATCH
         SET DELETED ON
      ENDTRY
   ENDPROC


*-- Adds the AFE No to past records
**********************************
   PROCEDURE FixAFENo
**********************************
      LPARAMETERS tlSilent, tlForce
      LOCAL oProgress
      THIS.LogCodePath(.T.,'CAPP:FixAFENo')
      TRY
         oProgress = THIS.omessage.progressbarex('Plugging AFE #s to new AFE field...')

         IF NOT FILE(THIS.cdatafilepath + 'afefix.txt') OR tlForce
            swselect('afedet')
            swselect('appurchh')
            swselect('appurchd')

            IF THIS.lamversion
               swselect('glmaster')
               swselect('csdishdr')
               swselect('csdisdet')
            ENDIF
            swselect('expense')
            swselect('expsusp')
            swselect('afehdr')

            COUNT FOR NOT DELETED() TO lnAFEs

            IF lnAFEs > 1
               IF NOT tlSilent
                  IF MESSAGEBOX('The way AFE expenses are tracked to actuals has changed. '  + ;
                        'The AFE codes need to be updated on all historical expenses. ' + CHR(10) + CHR(10) + ;
                        'The processing found AFEs defined. This process could '  + ;
                        'take several minutes to several hours. Do you want to do the processing now? ' + CHR(10) + CHR(10) + ;
                        'The processing can be done later by going to the Special Utilities menu '  + ;
                        'and choosing the "Update AFE Codes" utility.', 36, 'Update AFE Codes') = 7
                     llReturn = .F.
                     EXIT
                  ENDIF
               ENDIF
            ENDIF

            lnMax   = lnAFEs
            lnCount = 1
            oProgress.setprogressrange(0, lnMax)
            SELECT afehdr
            SCAN
               SCATTER MEMVAR
               oProgress.SetProgressMessage('Processing AFE: ' + m.cafeno)
               oProgress.updateprogress(lnCount)
               lnCount = lnCount + 1
               SELECT afedet
               SCAN FOR cidafeh = m.cidafeh
                  m.ccatcode = ccatcode

                  IF THIS.lamversion
                     SELECT glmaster
                     SCAN FOR cunitno = m.cwellid AND ccatcode = m.ccatcode AND ddate >= m.dafedate
                        IF NOT EMPTY(m.dcompdate) AND ddate > m.dcompdate
                           LOOP
                        ENDIF
                        REPLACE cafeno WITH m.cafeno
                     ENDSCAN

                     SELECT csdishdr
                     SCAN FOR dpostdate >= m.dafedate
                        IF NOT EMPTY(m.dcompdate) AND dpostdate > m.dcompdate
                           LOOP
                        ENDIF
                        m.cbatch = cbatch
                        SELECT csdisdet
                        SCAN FOR cbatch = m.cbatch AND ;
                              cunitno = m.cwellid AND ;
                              ccatcode = m.ccatcode
                           REPLACE cafeno WITH m.cafeno
                        ENDSCAN
                     ENDSCAN
                  ENDIF

                  SELECT appurchh
                  SCAN FOR dpostdate >= m.dafedate
                     IF NOT EMPTY(m.dcompdate) AND dpostdate > m.dcompdate
                        LOOP
                     ENDIF
                     m.cbatch = cbatch
                     SELECT appurchd
                     SCAN FOR cbatch = m.cbatch AND ;
                           cunitno = m.cwellid AND ;
                           ccatcode = m.ccatcode
                        REPLACE cafeno WITH m.cafeno
                     ENDSCAN
                  ENDSCAN

                  SELECT expense
                  SCAN FOR cwellid = m.cwellid AND ccatcode = m.ccatcode AND dexpdate >= m.dafedate
                     IF NOT EMPTY(m.dcompdate) AND dafedate > m.dcompdate
                        LOOP
                     ENDIF
                     REPLACE cafeno WITH m.cafeno
                  ENDSCAN

                  SELECT expsusp
                  SCAN FOR cwellid = m.cwellid AND ccatcode = m.ccatcode AND dexpdate >= m.dafedate
                     IF NOT EMPTY(m.dcompdate) AND dexpdate > m.dcompdate
                        LOOP
                     ENDIF
                     REPLACE cafeno WITH m.cafeno
                  ENDSCAN

               ENDSCAN
            ENDSCAN

            lcString = 'DONE'
            STRTOFILE(lcString, THIS.cdatafilepath + 'afefix.txt')

         ENDIF
      CATCH TO loError
         MESSAGEBOX('Error: ' + loError.MESSAGE, 0, 'AFE Fix')
         IF VARTYPE(oProgress) = 'O'
            oProgress.closeprogress()
         ENDIF
      ENDTRY

      IF VARTYPE(oProgress) = 'O'
         oProgress.closeprogress()
      ENDIF
   ENDPROC


*-- Checks for entries in the partnerpost table for the open company and shows the dialog that lets the entries be posted.
**********************************
   PROCEDURE PartnerPost
**********************************
****************************************************************
* Shows any items that are available to be posted from another
* company.
****************************************************************
      LPARAMETERS tlQuiet, tlShowPosted
      LOCAL llPost, llReturn
      THIS.LogCodePath(.T.,'CAPP:PartnerPost')
      TRY
         llPost = .T.

         IF tlShowPosted
            IF MESSAGEBOX('Should entries marked as posted be shown?', 36, 'Post JV Receipts') = 7
               tlShowPosted = .F.
            ENDIF
         ENDIF
         llReturn = THIS.opartnership.EntriesToPost(tlShowPosted)

         llPost = llReturn
         IF NOT llReturn AND NOT tlQuiet
            MESSAGEBOX('There are no entries to post into this JV at this time.', 64, 'JV Posting')
         ENDIF


         IF llReturn OR tlQuiet
            IF NOT tlQuiet
               IF MESSAGEBOX('There are entries from the main company that are ready to be posted. ' + ;
                     'Do you want to post them now?', 36, 'Post Entries?') = 7
                  llPost = .F.
               ENDIF
            ENDIF

            IF llPost
               m.gostatemanager.openform('partnerpostform.scx', tlShowPosted)
            ENDIF
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'PartnerPost', loError.LINENO, '', loError.ERRORNO, loError.MESSAGE
         MESSAGEBOX('Unable to post the entries at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
      ENDTRY

      WAIT CLEAR

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE oGlmaint_Access
**********************************
      IF VARTYPE(THIS.oglmaint) # 'O'
         THIS.oglmaint = CREATEOBJECT('glmaint')
      ENDIF
      RETURN THIS.oglmaint
   ENDPROC

**********************************
   PROCEDURE oImport_Access
**********************************
      IF VARTYPE(THIS.oimport) # 'O'
         IF NOT 'swfile' $ LOWER(SET('procedure'))
            SET PROCEDURE TO CUSTOM\swfile.prg ADDITIVE
         ENDIF
         THIS.oimport = CREATEOBJECT('swFile')
      ENDIF
      RETURN THIS.oimport
   ENDPROC

**********************************
   PROCEDURE oPartnership_Access
**********************************
      IF VARTYPE(THIS.opartnership) # 'O'
         IF NOT 'swpartners' $ LOWER(SET('procedure'))
            SET PROCEDURE TO CUSTOM\swpartners.prg ADDITIVE
         ENDIF
         THIS.opartnership = CREATEOBJECT('partners')
      ENDIF
      RETURN THIS.opartnership
   ENDPROC

**********************************
   PROCEDURE oDist_Access
**********************************
      IF VARTYPE(THIS.odist) # 'O'
         IF NOT 'swdist' $ LOWER(SET('procedure'))
            SET PROCEDURE TO CUSTOM\swdist.prg ADDITIVE
         ENDIF
         THIS.odist = CREATEOBJECT('distproc', ' ', ' ', '01', TRANSFORM(YEAR(DATE())), '00', 'O', DATE(), .F., 0, .F., .T.)
      ENDIF
      RETURN THIS.odist
   ENDPROC


*-- Plugs in the producer name to the cDDCompname field in options if it is empty.
**********************************
   PROCEDURE fixDDCompName
**********************************
      THIS.LogCodePath(.T.,'CAPP:FixDDCompName')
      TRY
         swselect('options')
         GO TOP
         IF EMPTY(cDDCompName)
            REPLACE cDDCompName WITH THIS.ccompanyname
         ENDIF
         IF VARTYPE(THIS.ooptions) = 'O'
            THIS.ooptions.cDDCompName = THIS.ccompanyname
         ENDIF
      CATCH
      ENDTRY
   ENDPROC

**********************************
   PROCEDURE FixBlankSuspType
**********************************
      THIS.LogCodePath(.T.,'CAPP:FixBlankSuspType')
*
* This method looks for suspense records with a blank csusptype
* It then determines what type to put on the records and fills
* in the csusptype and nrunno_in and crunyear_in fields so the
* suspense can be processed.
*
      swselect('suspense')
      SET ORDER TO CSUSPTYPE   && CSUSPTYPE
      IF SEEK(' ')
         SET ORDER TO
         WAIT WINDOW NOWAIT 'Suspense check in progress...'
         SELECT  cownerid, ;
            SUM(nnetcheck) AS nbalance ;
            FROM suspense ;
            WHERE CSUSPTYPE = ' ' ;
            INTO CURSOR tempsusp ;
            ORDER BY cownerid ;
            GROUP BY cownerid

         SELECT tempsusp
         SCAN
            SCATTER MEMVAR
            IF m.nbalance < 0
               m.CSUSPTYPE = 'D'
            ELSE
               m.CSUSPTYPE = 'M'
            ENDIF
            SELECT suspense
            SCAN FOR cownerid = m.cownerid AND CSUSPTYPE = ' '
               REPLACE CSUSPTYPE WITH m.CSUSPTYPE
               IF suspense.cRunYear_In = ' '
                  REPLACE cRunYear_In WITH cRunYear, ;
                     nRunNo_IN   WITH nrunno
               ENDIF
            ENDSCAN
         ENDSCAN
         WAIT CLEAR
      ENDIF

      swselect('investor')
      LOCATE FOR linteggl = .T.
      IF FOUND()
         IF NOT FILE(THIS.cdatafilepath + 'postingowner.txt')
            WAIT WINDOW NOWAIT 'Checking posting owners...'
            SELECT * FROM suspense INTO CURSOR temp WHERE cownerid IN (SELECT cownerid FROM investor WHERE linteggl = .T.)
            IF _TALLY > 0
               DELETE FROM suspense WHERE cownerid IN (SELECT cownerid FROM investor WHERE linteggl)
            ENDIF
            WAIT CLEAR
            lcString = 'Completed: ' + TTOC(DATETIME())
            STRTOFILE(lcString, THIS.cdatafilepath + 'postingowner.txt')
         ENDIF
      ENDIF
   ENDPROC

**********************************
   PROCEDURE ShowMenu
**********************************
      THIS.LogCodePath(.T.,'CAPP:ShowMenu')
      swselect('options')
      GO TOP
      THIS.lTradMenu = options.lTradMenu


* Add this companies custom menu bars if the menu already exists
      IF VARTYPE(oMenu) = 'O'
         RELEASE oMenu
         PUBLIC oMenu
      ENDIF

      oMenu = CREATEOBJECT('MainMenu', 'oMenu')
      IF m.goapp.lamversion
*            DO FORM homeam.scx
      ENDIF

      oMenu.SHOW()
      TRY
         THIS.AddToMenu(oMenu)
      CATCH
      ENDTRY

      THIS.ShowNews()
   ENDPROC

**********************************
   PROCEDURE INIT
**********************************
      LPARAMETERS cRootKey
      THIS.LogCodePath(.F.,'Init')
      IF VARTYPE(ometa) = 'U'
         PUBL ometa
         ometa = .NULL.
         ometa = NEWOBJECT('DBCXMgr', 'c:\develop\3rdparty\stonefield9\sdt\source\DBCXMGR.VCX', '', .F.)
         IF TYPE('oMeta') # 'O' OR ISNULL(ometa)
* Display error message and exit, because DBCX cannot be used.
*      MESSAGEBOX('The DBCX is not available',16,'Error Loading DBCX')
*      RETURN .F.
         ENDIF
      ENDIF

      IF FILE('datafiles\debug.txt')
         THIS.ldebugmode = .T.
      ENDIF

* Turn on reprocess for index and memos
      SYS(3052, 1, .T.)
      SYS(3052, 2, .T.)

      DODEFAULT(cRootKey)
   ENDPROC

**********************************
   PROCEDURE ClearBanner
**********************************

      THIS.LogCodePath(.T.,'CAPP:ClearBanner')

      IF PEMSTATUS(_SCREEN, 'helplink', 5)
         _SCREEN.REMOVEOBJECT('helplink')
      ENDIF
      DODEFAULT()


   ENDPROC

**********************************
   PROCEDURE IsRegistered
**********************************
*
*  Change 2/14/2008 by pws - changed HKEY_LOCAL_MACHINE to HKEY_CURRENT_USER
*

      THIS.LogCodePath(.T.,'CAPP:IsRegistered')
*++
*>>Called on startup to determine if the applciation has been registered with a valid serial number.
*--
      LOCAL cValue
      LOCAL llReturn, loError
*   #include common\win32.h
      TRY
         IF cmRegGetValue(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\SerialNumber', @m.cValue)
* Make sure serial number is valid, so no funny business is allowed.
            IF THIS.SerialHash(LEFT(m.cValue, 6)) == RIGHT(m.cValue, 5)
               llReturn = .T.
            ELSE
               MESSAGEBOX('Installation Serial Number is Invalid or Missing', 16, _SCREEN.CAPTION)
               llReturn = .F.
            ENDIF
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'IsRegistered', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE IsDataPathValid
**********************************
*
*  Change 2/14/2008 by pws - changed HKEY_LOCAL_MACHINE to HKEY_CURRENT_USER
*

      THIS.LogCodePath(.T.,'CAPP:IsDataPathValid')
*++
*>>Called on startup to verify stored data paths. Return .T. if the paths are valid, or .F. if one or more paths are invalid. Return .NULL. to Abort app startup.
*--
      LOCAL cValue, cPaths
      LOCAL llReturn, loError

      llReturn = .T.

      TRY

* Make sure files paths are still valid.
         m.cPaths = 'Local,Shared,Common'
         DO WHILE NOT EMPTY(m.cPaths)
            m.cValue = ''
            IF NOT cmRegGetValue(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\' + GetToken(@m.cPaths, ','), @m.cValue) ;
                  OR (NOT EMPTY(m.cValue) AND NOT DIRECTORY(m.cValue))
* The path is invalid. If user opts to cancel, return NULL. Otherwise return false.
               llReturn =  IIF(THIS.PathNotFound(m.cValue), .F., .NULL.)
               EXIT
            ENDIF
         ENDDO
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'IsDataPathValid', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

****************************
   PROCEDURE setsearchpath
****************************
      LOCAL llReturn, loError
      llReturn = .T.
      THIS.LogCodePath(.T.,'CAPP:SetSearchPath')
      TRY
* Override codemine path stuff
         THIS.cpathlocal  = SYS(5) + CURDIR()
         THIS.cpathcommon = THIS.cdatafilepath
         THIS.cpathshared = THIS.cdatafilepath

* If we're in development mode, add a couple search paths
         IF THIS.ldevelopmentenv = .T.
            SET PATH TO THIS.ccommonfolder + 'bin\' + ',' + THIS.ccommonfolder + ',' + THIS.cdatafilepath  + ',c:\develop\codeminenew\commonsource'
         ELSE
            SET PATH TO THIS.ccommonfolder + 'bin\' + ',' + THIS.ccommonfolder + ',' + THIS.cdatafilepath
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'SetSearchPath', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE GetFilePath
**********************************
      LPARAMETERS cFile
*++
*>>Given a filespec, return the full path name to use to find the file at runtime.
*--
      LOCAL ix, cExact, cpath
      LOCAL lcFile, llReturn, loError
*   #include common\win32.h
      llReturn = m.cFile

      THIS.LogCodePath(.T.,'CAPP:GetFilePath - ' + m.cFile)

      TRY

*  IF THIS.lApplicationStarted
         IF .T.  AND NOT 'pjx' $ LOWER(m.cFile)
* Strip off any path info in the original spec.
            m.cFile = UPPER(SUBSTR(m.cFile, RAT('\', m.cFile) + 1))

* Look in filespec cache first to keep it fast.
            m.cExact = SET('EXACT')
            SET EXACT ON
            m.ix = ASCAN(THIS.aPathCache, m.cFile)
            IF m.cExact = 'OFF'
               SET EXACT OFF
            ENDIF

            IF m.ix > 0
               m.ix = ASUBSCRIPT(THIS.aPathCache, m.ix, 1)
               IF LOWER(m.cFile) # 'appreg02.dbf'
                  lcFile  = THIS.aPathCache[m.ix, 2]
                  m.cFile = UPPER(SUBSTR(lcFile, RAT('\', lcFile) + 1))
                  IF 'COMPMAST' $ UPPER(m.cFile)
                     cmRegGetValue(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Local', @m.cpath)
                     m.cpath = THIS.ccommonfolder
                     m.cpath = ADDBS(m.cpath)
                  ELSE
                     cmRegGetValue(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Shared', @m.cpath)
                     m.cpath = ADDBS(m.cpath)
                  ENDIF
* Force the variables to have the correct type - pws 1/28/09
                  IF VARTYPE(m.cpath) # 'C'
                     m.cpath = ''
                  ELSE
                     m.cpath = ADDBS(m.cpath)
                  ENDIF
                  IF VARTYPE(m.cFile) # 'C'
                     m.cFile = ''
                  ENDIF
                  llReturn = (ALLTRIM(m.cpath) + m.cFile)
                  EXIT
               ENDIF
            ELSE
               IF EMPTY(THIS.aPathCache[1])
                  m.ix = 1
               ELSE
                  m.ix = ALEN(THIS.aPathCache, 1) + 1
                  DIMENSION THIS.aPathCache[m.ix, 2]
               ENDIF
               THIS.aPathCache[m.ix, 1] = m.cFile

* Look in the system registry for a path override for this file.
* The path returned here will be empty unless developer added installation code
* to assign a specific system registry key value for this file path.
               m.cpath = ''
*
* Over rode original code to use shared path instead of one specified for the
* table. pws - 5/30/06
*
               IF 'COMPMAST' $ UPPER(m.cFile) OR 'APPREG02' $ UPPER(m.cFile)
*cmRegGetValue(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Local', @m.cPath)
                  m.cpath = THIS.ccommonfolder
                  m.cpath = ADDBS(m.cpath)
               ELSE
                  cmRegGetValue(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Shared', @m.cpath)
                  m.cpath = ADDBS(m.cpath)
               ENDIF
               THIS.aPathCache[m.ix, 2] = LOWER(ALLTRIM(m.cpath) + m.cFile)
            ENDIF
            llReturn = THIS.aPathCache[m.ix, 2]
            EXIT
         ENDIF
      CATCH TO loError
         llReturn = m.cFile
         DO errorlog WITH 'GetFilePath', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

* Application object not started, so disable path name processing
      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE BeforeShutdown
**********************************
      THIS.LogCodePath(.T.,'CAPP:BeforeShutdown')
* Check for open forms. Don't allow close if forms are open.
      m.gostatemanager.closeallforms()

* Reset the registry keys to the Data\ path
      THIS.Set_Reg_Keys(.T.)

      THIS.oreport     = .NULL.
      THIS.oscreenshot = .NULL.
      THIS.oimport     = .NULL.
      THIS.ologger     = .NULL.
*THIS.ometa       = .NULL.
*THIS.oqb         = .NULL.
      THIS.otreeno  = .NULL.
      THIS.oupdate  = .NULL.
      THIS.oglmaint = .NULL.

      RETURN DODEFAULT()
   ENDPROC

**********************************
   PROCEDURE Install
**********************************
      LPARAMETERS lNeedInstall
*++
*>>Perform once-only registration and installation and find out where our data is located.
*--
      LOCAL cValue, oDialog, cBadPath
      LOCAL lcPath, lcPath2, lcSerial, llReturn, loError
      THIS.LogCodePath(.T.,'CAPP:Install')
      llReturn = .T.
*   #include common\win32.h
      TRY

***********************************************************************************
*  Modified to plug the installation paths instead of calling frmAppInstallDialog
*  pws - 5/5/2005
***********************************************************************************
         lcSerial = '12345'
         lcPath   = ADDBS(JUSTPATH(THIS.cexecutable))   && Get path of executable
         lcPath2  = ALLT(lcPath) + 'Datafiles\Data\'
         cmRegSetString(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\SerialNumber', lcSerial)
         cmRegSetString(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Local', lcPath)
         cmRegSetString(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Common', lcPath2)
         cmRegSetString(HKEY_CURRENT_USER, THIS.cSysRegRoot + '\Paths\Shared', lcPath2)
         m.lNeedInstall = .F.
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'Install', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN .T.
   ENDPROC

**********************************
   PROCEDURE ERROR
**********************************
      LPARAMETERS tnerror, tcMethod, tnlineno
      LOCAL lcProject, laError, lcStack

      THIS.LogCodePath(.T.,'CAPP:Error')

      AERROR(gaErrors)

      #DEFINE ccMSG_RETRY  'Retry'

      IF THIS.lopeningfiles
         DO CASE
* End of File Encountered - Set record pointer at last record
            CASE tnerror = 4
               GO BOTT
               RETURN ccMSG_RETRY

* If an index error occurred (5 = record out of range, 19 = index doesn't match
* DBF, 20 = record not in index, 23 = index expression too big, 26 = table
* isn't ordered, 112 = invalid key length, 114 = index file doesn't match DBF,
* 1124 = key too big, 1683 = tag not found, 1707 = structural CDX not found,
* 1567 = primary key invalid), reindex the table.
            CASE INLIST(tnerror, 5, 19, 114, 20, 23, 26, 112, 1124, 1683, 1707, 1567)
               IF VARTYPE(ometa) = 'O'
                  IF NOT EMPTY(ometa.oSDTMgr.cAlias)
                     DO errorlog WITH 'OpenCompany2', tnlineno, '', tnerror, ALLTRIM(gaErrors[2]) + ' It was automatically reindexed.', ometa.oSDTMgr.cAlias
                     OPEN DATABASE THIS.cdatafilepath + 'appdata.dbc'
                     SET DATABASE TO appdata
                     ometa.ResetError()
                     ometa.setdatabase(DBC())
                     ometa.oSDTMgr.REINDEX(ometa.oSDTMgr.cAlias)
                     ometa.oSDTMgr.OPENTABLE(ometa.oSDTMgr.cAlias)
                     RETURN ccMSG_RETRY
                  ENDIF
               ENDIF

* If the table or memo is corrupted (15 = not a table, 41 = memo missing or
* invalid), repair it.

            CASE INLIST(tnerror, 15, 41)
               IF VARTYPE(ometa) = 'O'
                  IF NOT EMPTY(ometa.oSDTMgr.cAlias)
                     DO errorlog WITH 'OpenCompany2', tnlineno, '', tnerror,  + ALLTRIM(gaErrors[2]) + ' It was automatically repaired.', ometa.oSDTMgr.cAlias
                     OPEN DATABASE THIS.cdatafilepath + 'appdata.dbc'
                     SET DATABASE TO appdata
                     ometa.ResetError()
                     ometa.setdatabase(DBC())
                     ometa.oSDTMgr.Repair(ometa.oSDTMgr.cAlias)
                     ometa.oSDTMgr.OPENTABLE(ometa.oSDTMgr.cAlias)
                     RETURN ccMSG_RETRY
                  ENDIF
               ENDIF

* 1984 = Fields do not match database
            CASE INLIST(tnerror, 1, 1542, 1561, 1976, 1984)
               IF NOT EMPTY(ometa.oSDTMgr.cAlias)
                  DO errorlog WITH 'OpenCompany2', tnlineno, '', tnerror, ALLTRIM(gaErrors[2]) + ' It was automatically recreated.', ometa.oSDTMgr.cAlias
                  THIS.UpdateTables(THIS.cidcomp, .F., ometa.oSDTMgr.cAlias)
                  OPEN DATABASE THIS.cdatafilepath + 'appdata.dbc'
                  SET DATABASE TO appdata
                  ometa.ResetError()
                  ometa.setdatabase(DBC())
                  ometa.oSDTMgr.OPENTABLE(ometa.oSDTMgr.cAlias)
                  RETURN ccMSG_RETRY
               ENDIF
            CASE tnerror = 1540 OR tnerror = 1001
* Do Nothing

         ENDCASE
      ELSE
         DO CASE
            CASE tnerror = 1540 OR tnerror = 1001
* Do Nothing
         ENDCASE
      ENDIF

      IF THIS.lqbversion AND VARTYPE(THIS.oqb) = 'O'
         THIS.oqb.QBClose()
      ELSE
         IF THIS.lqboversion AND VARTYPE(THIS.oqb) = 'O'
         ENDIF
      ENDIF

      DODEFAULT(tnerror, tcMethod, tnlineno)
   ENDPROC

**********************************
   PROCEDURE SetTitle
**********************************
      LPARAMETERS cTitle

      THIS.LogCodePath(.T.,'CAPP:SetTitle')
* Do Nothing

      RETURN .T.
   ENDPROC

**********************************
   PROCEDURE BeforeMenu
**********************************
      LOCAL oLimit, lnLimit
      LOCAL llReturn, loError

      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:BeforeMenu')

      TRY

         SET DATASESSION TO 1
         SET PROCEDURE TO CUSTOM\lanlimit.prg ADDITIVE
         m.oLimit = CREATE('cmNetworkUserLimit')

* Set default limit of 2 unless we're in development environment
         IF VERSION(2) = 2
            lnLimit = 9999999
         ELSE
            lnLimit = 2
         ENDIF

         DO CASE
            CASE THIS.llan5
               lnLimit = 5
            CASE THIS.llan10
               lnLimit = 10
            CASE THIS.llanunlimited
               lnLimit = 50
         ENDCASE

*WAIT WINDOW 'Max Users = ' + TRANSFORM(lnLimit)
         m.oLimit.nMaxUsers = lnLimit   && The maximum # of users allowed to run at the same time.

* Check to see if we can log in.
         IF NOT m.oLimit.IsLicensed()
            THIS.omessage.warning('User limit exceeded! Only ' + TRANSFORM(lnLimit) + ' users can be logged into the software at the same time.')
            llReturn = .F.
            EXIT
         ENDIF

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BeforeMenu', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to start the application at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE BeforeCreateGlobalObjects
**********************************
      LOCAL lcDemo
      LOCAL llReturn, loError

      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:BeforeCreateGlobalObjects')

      TRY

         THIS.cfullversion = THIS.cfileversion

* Get the Checks and Rpts Folder locations
         THIS.GetFolderPaths()

* Add the common folder to the path so appreg02 can be found
         SET PATH TO THIS.ccommonfolder ADDITIVE

* Get the report apps if they don't exist
         IF NOT FILE(THIS.ccommonfolder + 'reportpreview.app')
            GetRptApps()
         ENDIF

* Check to see if we're installed on the Cloud Server
         IF FILE('cloudserver.txt')
            THIS.lcloudserver = .T.
         ELSE
            THIS.lcloudserver = .F.
         ENDIF

&& Report output
         _REPORTOUTPUT  = THIS.ccommonfolder + 'REPORTOUTPUT.APP'
&& Report preview
         _REPORTPREVIEW = THIS.ccommonfolder + 'REPORTPREVIEW.APP'
&& Report Writer
         _REPORTBUILDER = THIS.ccommonfolder + 'REPORTBUILDER.APP'

* Create the performance log object
         IF FILE('perflog.txt')
            THIS.operflog = CREATEOBJECT( [csnwPerfLog] )
         ENDIF

* Go check the registration code
         THIS.ConfigReg()

         IF THIS.ldemo
*    In Demo mode
            lcDemo = 'DEMO of '
         ELSE
            lcDemo = ''
         ENDIF

* Check for test version
         IF FILE('testversion.cfg')
            THIS.ltestversion = .T.
         ELSE
            THIS.ltestversion = .F.
         ENDIF

* Ask for login and open company files
         THIS.SetScreenCaption()
         THIS.lnocallopencomp2 = .F.
         llReturn              = .T.
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'BeforeCreateGlobalObjects', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the start the application at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn



   ENDPROC

**********************************
   PROCEDURE AfterCreateGlobalObjects
**********************************
      LOCAL llReturn, loError
      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:AfterCreateGlobalObjects')

      TRY
         lcidcomp = THIS.cidcomp
         IF EMPTY(lcidcomp)
            lcidcomp = .NULL.
         ENDIF
*
* Default open company method
*
         IF NOT THIS.lnocallopencomp2
* Logoff from security
            IF VARTYPE(THIS.osecurity) = 'O'
               THIS.osecurity.logoff()
            ENDIF

* Close all registry tables
            IF VARTYPE(THIS.oregistry) = 'O'
               THIS.oregistry.closeall()
            ENDIF

* Delete compmast records for companies that have data paths that don't exist
            Remove_Nonexistant_Companies()

* Get our environment
            IF VERSION(2) = 2 AND NOT ISNULL(lcidcomp)
* We're in the development environment, so login as Admin automatically.
               WITH THIS
                  .ldevelopmentenv = .T.
                  .lnologon        = .T.
                  THIS.cuser       = 'Admin'

                  .osecurity.Logon('Admin', 'Admin')
                  STORE .T. TO .lafedata, .lafereports, .lapdata, .lapreports, .lardata, .larreports
                  STORE .T. TO .lgldata, .lglreports, .lglfinancials, .llanddata, .llandreports
                  STORE .T. TO .lbrinedata, .lbrinereports, .lcashdata, .lcashreports, .lcheckprinting
                  STORE .T. TO .lrevdistdata, .lrevdistreports, .ljibdata, .ljibreports
                  STORE .T. TO .ladmin, .linvestdata, .linvestreports, .lreportmenu
                  STORE .T. TO .lhousegasdata, .lhousegasreports, .lpartnerdata, .lpartnerreports
                  STORE .T. TO .lpayrolldata, .lpayrollreports, .ldoidata
                  STORE .T. TO .lgraphs, .ladhocreporting, .lform1065reporting
                  STORE .F. TO .lreadonly
                  THIS.cuser = 'Admin'
               ENDWITH

* Erase the last open company file
               lnFile = ADIR(laFiles, THIS.ccommondocuments + '*.loc')
               IF lnFile > 0
                  FOR x = 1 TO lnFile
                     TRY
                        ERASE (THIS.ccommondocuments + laFiles[x, 1])
                     CATCH
                     ENDTRY
                  ENDFOR
               ENDIF

               lcidcomp = THIS.cidcomp

* Create the last open company file
               IF NOT FILE(THIS.ccommondocuments + lcidcomp + '.loc')
                  fh = FCREATE(THIS.ccommondocuments + lcidcomp + '.loc')
                  FCLOSE(fh)
               ENDIF

            ELSE
               THIS.ldevelopmentenv = .F.
            ENDIF

* Bring up the logon dialog
            llReturn = THIS.Logon()
         ENDIF

         THIS.lnocallopencomp2 = .F.

      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'AfterCreateGlobalObjects', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
         MESSAGEBOX('Unable to process the start the application at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
            'Contact Pivoten Support for help at support@Pivoten.com', 16, 'Problem Encountered')
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE ShowBanner
**********************************

      THIS.LogCodePath(.T.,'CAPP:ShowBanner')

* Add the data path status message
      TRY
         _SCREEN.REMOVEOBJECT('cdatapath')
      CATCH
      ENDTRY
      _SCREEN.ADDOBJECT('cdatapath', 'label')
      _SCREEN.cdatapath.CAPTION = ''
*_screen.cDataPath.Visible = .T.
      _SCREEN.cdatapath.AUTOSIZE = .T.
      _SCREEN.cdatapath.TOP      = _SCREEN.HEIGHT - 15

      DODEFAULT()

      _SCREEN.cdatapath.ZORDER(0)
   ENDPROC

**********************************
   PROCEDURE REFRESH
**********************************
      IF PEMSTATUS(_SCREEN, 'helplink', 5)
         _SCREEN.helpLINK.LEFT = 5
         _SCREEN.helpLINK.TOP  = _SCREEN.HEIGHT - 50
      ENDIF

      THIS.LogCodePath(.T.,'CAPP:Refresh')

      DODEFAULT()
      _SCREEN.cdatapath.TOP = _SCREEN.HEIGHT - 15
   ENDPROC

**********************************
   PROCEDURE AfterInit
**********************************
      THIS.LogCodePath(.T.,'CAPP:AfterInit')
* Set the class alias for the quickFill class

      setclassalias('cmQuickFillSupport', 'swQuickFillSupport')

* Get the common documents folder for this workstation
* We store the LOC (last open company) file and the help file there

      THIS.ccommondocuments = specialfolders('CommonDocuments')
   ENDPROC

***********************
   PROCEDURE SHUTDOWN
***********************
      LPARAMETERS lForced
*++
*>>Shut down the application.
*--
      LOCAL oForm, cShutCmd

      THIS.LogCodePath(.T.,'CAPP:ShutDown')

* Ignore further shutdown requests until we finish.
      m.cShutCmd = ON('Shutdown')
      ON SHUTDOWN *
      WAIT WINDOW NOWAIT 'Shutting down...'
      INKEY(.5)
* Don't allow shutdown if any modal forms are open. Check all forms, because a "modeless" form opened
* from within a modal one is really modal, even though it appears modeless.
      FOR EACH oForm IN _SCREEN.FORMS
         IF TYPE('m.oForm.WindowType') = 'N' AND m.oForm.WINDOWTYPE = 1 AND m.oForm.VISIBLE
            IF NOT ISNULL(THIS.omessage)
               LOCAL cMsg, cname
               IF TYPE('_SCREEN.Activeform.Baseclass') = 'C'
                  m.cname = _SCREEN.ACTIVEFORM.CAPTION
               ELSE
                  m.cname = WONTOP()
               ENDIF
               m.cMsg = THIS.omessage.TranslateString('%txtNoShutdown')
               m.cMsg = THIS.omessage.FORMAT(m.cMsg, m.cname)
               THIS.omessage.FlashMessage(m.cMsg)
            ENDIF
            ON SHUTDOWN &cShutCmd
            RETURN .F.
         ENDIF
      ENDFOR
      INKEY(.5)
      IF NOT ISNULL(THIS.oStateManager)
* Exit the event loop only if all forms close successfully.
         IF NOT THIS.BeforeShutdown() OR NOT THIS.oStateManager.closeallforms() ;
               OR (NOT m.lForced AND NOT THIS.AfterShutdown())
            WAIT WINDOW 'Shutdown failed...'
            ON SHUTDOWN &cShutCmd
            RETURN .F.
         ELSE
            WAIT WINDOW NOWAIT 'Shutdown Successful...'
            INKEY(.5)
         ENDIF
      ENDIF

* Success, or State manager is gone - clear shutdown handler and end event loop.
      ON SHUTDOWN
      CLEAR EVENTS
   ENDPROC

**********************************
   PROCEDURE LoadLibraries
**********************************

      THIS.LogCodePath(.T.,'CAPP:LoadLibraries')

      THIS.NEWOBJECT('appSettings', 'appApplicationSettings', THIS.CLASSLIBRARY)

* Load class libraries
      DO loadclasses

* Load Procedures
      DO loadprocedures
   ENDPROC

**********************************
   PROCEDURE FoxAuditSetup
**********************************
* Adjust the path to point to the FoxAudit 6.0 Class Library (FoxAudit.VCX)
      LOCAL lcFoxAuditLoc, lcLogLoc

      THIS.LogCodePath(.T.,'CAPP:FoxAuditSetup')

      lcFoxAuditLoc = 'C:\Develop\_newversions\custom\'
      lcLogLoc      = THIS.cdatafilepath + 'APPDATA_LOG.DBF'
*SET CLASSLIB TO (lcFoxAuditLoc+'FOXAUDIT.VCX') ADDITIVE

      oFoxAudit_APPDATA = CREATEOBJECT('FoxAudit', lcLogLoc)

* Make sure the FoxAudit 6.0 Object was created properly
      IF TYPE('oFoxAudit_APPDATA') == 'O' AND NOT ISNULL('oFoxAudit_APPDATA')
* Assign the application's UserID value to FoxAudit's cUserID property
* In Visual FoxExpress 6.0: _SCREEN.oApplication.oSecurity.cUserID
* In Visual MaxFrame: oUser.GetUserInfo('USR_LANID')
* In Mere Mortals: goApp.cUserID
         oFoxAudit_APPDATA.cUserID     = THIS.cuser
         oFoxAudit_APPDATA.lLogUpdates = THIS.laudittrail
      ENDIF
   ENDPROC

**********************************
   PROCEDURE CheckTaxes
**********************************
      LOCAL llFound, llReturn, loError
      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:CheckTaxes')

      TRY

         llFound = .F.

         swselect('sevtax')
         LOCATE FOR EMPTY(cmethodbbl1) AND ntaxbbl1 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodmcf1) AND ntaxmcf1 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodoth1) AND ntaxoth1 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodbbl2) AND ntaxbbl2 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodmcf2) AND ntaxmcf2 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodoth2) AND ntaxoth2 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodbbl3) AND ntaxbbl3 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodmcf3) AND ntaxmcf3 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodoth3) AND ntaxoth3 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodbbl4) AND ntaxbbl4 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodmcf4) AND ntaxmcf4 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         LOCATE FOR EMPTY(cmethodoth4) AND ntaxoth4 # 0
         IF FOUND()
            llFound = .T.
         ENDIF
         IF llFound
            THIS.omessage.warning('There appears to be a problem with the Well Products Tax Table. ' + ;
               'Check to make sure the calculation method is not blank on any entries.')
         ENDIF
      CATCH TO loError
         llReturn = .F.
         DO errorlog WITH 'CheckTaxes', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError
      ENDTRY

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE PrimaryKeySetup
**********************************

      THIS.LogCodePath(.T.,'CAPP:PrimaryKeySetup')
      RETURN

   ENDPROC

**********************************
   PROCEDURE BuildDOIDecks
**********************************
*
* Builds original DOI Deck records if none exit
* and there are DOI records in wellinv
*
      LOCAL lnCount AS INTEGER ;
         , oWellInv AS OBJECT ;
         , llReturn AS Logical

      llReturn = .T.

      THIS.LogCodePath(.T.,'CAPP:BuildDoiDecks')

      oWellInv = CREATEOBJECT('swbizobj_wellinv')
      llReturn = oWellInv.BuildOriginalDecks()

      swselect('wellinv')
      REPLACE cDeck WITH 'ORIGINAL' FOR EMPTY(cDeck)

      oWellInv = .NULL.

      RETURN llReturn
   ENDPROC

**********************************
   PROCEDURE SetScreenCaption
**********************************

      LOCAL lcDemo

      THIS.LogCodePath(.T.,'CAPP:SetupScreenCaption')

      IF m.goapp.ldemo
         lcDemo = 'DEMO of '
      ELSE
         lcDemo = ''
      ENDIF

      IF THIS.lOpenCompany = .F.
         IF THIS.ltestversion
            _SCREEN.CAPTION = THIS.cproductname + ' - Test Version: No Company Open'
         ELSE
            _SCREEN.CAPTION = lcDemo + THIS.cproductname + ' V' + THIS.cfullversion + ' - No Company Open'
         ENDIF
      ELSE
         lcSupportExpires     = DTOC(THIS.dsupportexpires)
         ldExpires            = THIS.dsupportexpires

         IF ldExpires < DATE()
            lcExpireMessage = ' ** Support Expired on ' + lcSupportExpires + ' **'
         ELSE
            lcExpireMessage = ''
         ENDIF

         IF THIS.ltestversion
            _SCREEN.CAPTION = THIS.cproductname + ' - Test Version'
         ELSE
            _SCREEN.CAPTION = lcDemo + THIS.cproductname + ' V' + THIS.cfullversion + ' - ' + TRIM(THIS.ccompanyname) + lcExpireMessage
         ENDIF


* Set the data path in the main window
         IF THIS.lcloudserver
            _VFP.STATUSBAR = 'Company Open: ' +  PROPER(THIS.ccompanyname)
         ELSE
            _VFP.STATUSBAR = 'Data Path: ' +  LOWER(THIS.cdatafilepath) + '    - Support Subscription Expires: ' + DTOC(THIS.dsupportexpires)
         ENDIF
      ENDIF

   ENDPROC

**********************************
   PROCEDURE EncryptEmps
**********************************

      THIS.LogCodePath(.T.,'CAPP:EncryptEmps')

      IF m.goapp.lamversion
         TRY
            IF NOT m.goapp.lpayrollopt
               EXIT
            ENDIF

            swselect('emps')
            SCAN
               m.ctaxid = cssn

               IF LEFT(m.ctaxid, 1) $ '1234567890'
                  m.ctaxid = cmEncrypt(ALLTRIM(m.ctaxid), m.goapp.cencryptionkey)
                  REPLACE cssn WITH m.ctaxid
               ENDIF
            ENDSCAN
         CATCH TO loErr
         ENDTRY
      ENDIF

**********************************
   PROCEDURE FillBillSource
**********************************

      THIS.LogCodePath(.T.,'CAPP:FillBillSource')

      TRY
         swselect('appurchh')
         SCAN
            IF appurchh.iSource = 0
               IF 'imported' $ LOWER(appurchh.creference)
                  REPLACE iSource WITH 2
               ELSE
                  REPLACE iSource WITH 1
               ENDIF
            ENDIF
         ENDSCAN
      CATCH TO loError
         DO errorlog WITH 'FillBillSource', loError.LINENO, 'Appmain', loError.ERRORNO, loError.MESSAGE, '', loError, .F., .T.
      ENDTRY

*************************************
   FUNCTION LogCodePath(tlAppend,tcMethod)
*************************************

      IF THIS.ldebugmode
         TRY
            SET SAFETY OFF
            STRTOFILE(TIME() + ' - ' + tcMethod + CHR(13)+CHR(10),THIS.ccommonfolder+'CodePath.txt',tlAppend)
         CATCH
         ENDTRY
      ENDIF

   ENDFUNC

ENDDEFINE
*
*-- EndDefine: cmapplicationcustom
**************************************************






********************************************************************************
********************************************************************************
DEFINE CLASS MainMenu AS SFMenu OF SFMenu.vcx
********************************************************************************
********************************************************************************
   PROCEDURE DefineMenu
      WITH THIS
         .AddPad('FileMenu', '', 'msm_file')
         .AddPad('EditMenu', '', 'msm_edit')
         .AddPad('Maintain', '', 'MainTain')
         .AddPad('Tasks', '', 'Tasks')
         .AddPad('Reports', '', 'Reports')
         .AddPad('Utilities', '', 'Utilities')
         .AddPad('Windows', '', 'Windows')
         .AddPad('HelpMenu', '', 'msm_systm')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
*===============================================================================
*===============================================================================
DEFINE CLASS FileMenu AS SFPad OF SFMenu.vcx
*===============================================================================
*===============================================================================
*===============================================================================
   cCaption	 = [\<File]
   cKey		 = [ALT+F]
   cPopupName	 = [FileMenu]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('OpenCompany', '', 'OpenCompany')
         .AddBar('CloseCompany', '', 'CloseCompany')
         .AddBar('SetupCompany', '', 'SetupCompany')
         .AddBar('DeleteCompany', '', 'DeleteCompany')

         IF m.goapp.lQBVersion
            .AddSeparatorBar()
            .AddBar('ConnectToQB', '', 'ConnectToQB')
            .AddBar('DisconnectQB', '', 'DisconnectQB')
         ENDIF

         .AddSeparatorBar()
         .AddBar('BackupData', '', 'BackupData')
         .AddBar('RestoreData', '', 'RestoreData')
         .AddBar('SendFile', '', 'SendFile')
         .AddSeparatorBar()
         .AddBar('EditRegistry', '', 'EditRegistry')
         .AddBar('EditUsers', '', 'EditUsers')
         .AddBar('ChangePassword', '', 'ChangePassword')
         .AddBar('ChangeRegistrationCode', '', 'ChangeRegistrationCode')
         .AddSeparatorBar()
         .AddBar('ViewToolBars', '', 'ViewToolBars')
         .AddSeparatorBar()
         .AddBar('SwitchUser', '', 'SwitchUser')
         .AddSeparatorBar()
         .AddBar('ExitApp', '', 'ExitApp')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OpenCompany AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Open Company]
   cOnClickCommand	= [do opencomp]
ENDDEFINE

*===============================================================================
DEFINE CLASS CloseCompany AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Close Company]
   cOnClickCommand	= [do closecomp with .f., .t.]
   cSkipFor		= [not m.goapp.lopencompany]
ENDDEFINE

*===============================================================================
DEFINE CLASS SetupCompany AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Setup a \<New Company]
   cOnClickCommand	= [do form compsetup]
   cSkipFor		= [m.goapp.lReadOnly]
ENDDEFINE

*===============================================================================
DEFINE CLASS DeleteCompany AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Delete Company]
   cOnClickCommand	= [do deletecomp]
   cSkipFor		= [m.goapp.lReadOnly]
ENDDEFINE

*===============================================================================
DEFINE CLASS ConnectToQB AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Connect To QuickBooks]
   cOnClickCommand	= [m.goapp.oQB.qbconnection()]
   cSkipFor		= [m.goapp.oQB.lqbactive or not m.goapp.lopencompany or m.goApp.lExpired or m.goapp.lReadOnly]
ENDDEFINE

*===============================================================================
DEFINE CLASS DisconnectQB AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Close QuickBooks Connection]
   cOnClickCommand	= [m.goapp.oQB.qbclose()]
   cSkipFor		= [not m.goapp.oQB.lqbactive or m.goApp.lExpired or m.goapp.lReadOnly]
ENDDEFINE

*===============================================================================
DEFINE CLASS BackupData AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Backup Data Files]
   cOnClickCommand	= [m.goStateManager.OpenForm('filebackup.scx')]
   cSkipFor		= [not m.goapp.lopencompany or m.goapp.lReadOnly]
ENDDEFINE

*===============================================================================
DEFINE CLASS RestoreData AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Restore Data Files]
   cOnClickCommand	= [m.goStateManager.OpenForm('filerestore.scx')]
   cSkipFor		= [not m.goapp.lopencompany or m.goapp.lReadOnly]
ENDDEFINE

*===============================================================================
DEFINE CLASS SendFile AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Send \<File to SherWare]
   cOnClickCommand	= [m.goStateManager.openform('utftpsend.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS EditRegistry AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Edit Registry...]
   cOnClickCommand	= [m.goStateManager.OpenForm('frmRegistryEditor')]
   cSkipFor		= [not m.goapp.lopencompany or m.goApp.lExpired or m.goapp.lReadonly]
ENDDEFINE

*===============================================================================
DEFINE CLASS EditUsers AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Edit User Accounts...]
   cOnClickCommand	= [m.goStateManager.OpenForm('frmAccountEditor')]
   cSkipFor		= [not m.goapp.lopencompany or m.goApp.lExpired or m.goapp.lReadonly]
ENDDEFINE

*===============================================================================
DEFINE CLASS ChangePassword AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Change Password]
   cOnClickCommand	= [m.goStateManager.OpenModalForm('frmSetLogonPassword')]
   cSkipFor		= [m.goApp.lExpired]
ENDDEFINE

*===============================================================================
DEFINE CLASS ChangeRegistrationCode AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Change Re\<gistration Code]
   cOnClickCommand	= [m.goStateManager.OpenForm('changereg.scx')]
   cSkipFor		= [not m.goapp.lAdmin]
ENDDEFINE


*===============================================================================
DEFINE CLASS ViewToolBars AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [View Toolbars...]
   cOnClickCommand	= [m.goStateManager.OpenModalForm('frmViewToolbars')]
   cSkipFor		= "empty(m.gostatemanager.atoolbars[1, 1])"
ENDDEFINE

*===============================================================================
DEFINE CLASS SwitchUser AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [S\<witch User]
   cOnClickCommand	= [do opencomp]
ENDDEFINE

*===============================================================================
DEFINE CLASS ExitApp AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [E\<xit]
   cOnClickCommand	= [m.goApp.Shutdown(.T.)]
ENDDEFINE

*===============================================================================
*===============================================================================
*===============================================================================
DEFINE CLASS EditMenu AS SFPad OF SFMenu.vcx
*===============================================================================
*===============================================================================
*===============================================================================
   cCaption	 = [\<Edit]
   cKey		 = [ALT+E]
   cPopupName	 = [_medit]
   cSkipFor	 = [not m.goapp.lopencompany]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('med_undo', '', 'med_undo')
         .AddBar('med_redo', '', 'med_redo')
         .AddSeparatorBar()
         .AddBar('med_cut', '', 'med_cut')
         .AddBar('med_copy', '', 'med_copy')
         .AddBar('med_paste', '', 'med_paste')
         .AddSeparatorBar()
         .AddBar('med_slcta', '', 'med_slcta')
         .AddSeparatorBar()
         .AddBar('EditPreferences', '', 'EditPreferences')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS med_undo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption   = [\<Undo]
   cKey	   = [CTRL+Z]
   cKeyText   = [Ctrl+Z]
   cSystemBar = [_med_undo]
ENDDEFINE

*===============================================================================
DEFINE CLASS med_redo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption   = [Re\<do]
   cKey	   = [CTRL+R]
   cKeyText   = [Ctrl+R]
   cSystemBar = [_med_redo]
ENDDEFINE

*===============================================================================
DEFINE CLASS med_cut AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption   = [Cu\<t]
   cKey	   = [CTRL+X]
   cKeyText   = [Ctrl+X]
   cSystemBar = [_med_cut]
ENDDEFINE

*===============================================================================
DEFINE CLASS med_copy AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption   = [\<Copy]
   cKey	   = [CTRL+C]
   cKeyText   = [Ctrl+C]
   cSystemBar = [_med_copy]
ENDDEFINE

*===============================================================================
DEFINE CLASS med_paste AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption   = [\<Paste]
   cKey	   = [CTRL+V]
   cKeyText   = [Ctrl+V]
   cSystemBar = [_med_paste]
ENDDEFINE

*===============================================================================
DEFINE CLASS med_slcta AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption   = [Se\<lect All]
   cKey	   = [CTRL+A]
   cKeyText   = [Ctrl+A]
   cSystemBar = [_med_slcta]
ENDDEFINE

*===============================================================================
DEFINE CLASS EditPreferences AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Prefere\<nces]
   cOnClickCommand	= [m.gostatemanager.openform('preferences.scx')]
   cSkipFor		= [not m.goapp.lAdmin]
ENDDEFINE

*===============================================================================
*===============================================================================
*===============================================================================
DEFINE CLASS Maintain AS SFPad OF SFMenu.vcx
*===============================================================================
*===============================================================================
*===============================================================================
   cCaption	 = [\<Maintain]
   cKey		 = [ALT+M]
   cPopupName	 = [Maintain]
   cSkipFor	 = [not m.goapp.lopencompany or m.goApp.lExpired]

   PROCEDURE AddBars
      WITH THIS
         DO CASE
            CASE m.goapp.lAMVersion
               .AddBar('CompanyInfo', '', 'CompanyInfo')
               .AddSeparatorBar()
               .AddBar('ChartofAccounts', '', 'ChartofAccounts')
               .AddBar('GLAccountTypes', '', 'GLAccountTypes')
               .AddSeparatorBar()
               .AddBar('DisbursementJIBFiles', '', 'DisbursementJIBFiles')
               .AddSeparatorBar()
               .AddBar('CustomerInfo', '', 'CustomerInfo')
               .AddBar('VendorInfo', '', 'VendorInfo')
               .AddBar('EmployeeInfo', '', 'EmployeeInfo')
               .AddSeparatorBar()
               .AddBar('CustomerInfo', '', 'CustomerInfo')
               .AddBar('AFEFiles', '', 'AFEFiles')
               .AddBar('LandFiles', '', 'LandFiles')
               .AddBar('InvestmentFiles', '', 'InvestmentFiles')
               .AddBar('BrineFiles', '', 'BrineFiles')
               .AddBar('HouseGasOwners', '', 'HouseGasOwners')
               .AddBar('PluggingModule', '', 'PluggingModule')
               .AddSeparatorBar()
               .AddBar('FixedAssetInfo', '', 'FixedAssetInfo')
               .AddBar('BillingCodes', '', 'BillingCodes')
               .AddBar('GLDeptInfo', '', 'GLDeptInfo')
               .AddBar('FinanceChargeCodes', '', 'FinanceChargeCodes')
               .AddBar('TermsCodes', '', 'TermsCodes')
               .AddBar('SalesTaxCodes', '', 'SalesTaxCodes')
               .AddBar('PayrollCodes', '', 'PayrollCodes')

            CASE m.goapp.lQBVersion
               .AddBar('CompanyInfo', '', 'CompanyInfo')
               .AddSeparatorBar()
               .AddBar('LeaseInfo', '', 'LeaseInfo')
               .AddBar('WellInfo', '', 'WellInfo')
               .AddBar('OwnerInfo', '', 'OwnerInfo')
               .AddBar('DOIInfo', '', 'DOIInfo')
               .AddSeparatorBar()
               .AddBar('PumperInfo', '', 'PumperInfo')
               .AddBar('PurchaserInfo', '', 'PurchaserInfo')
               .AddBar('ProgramInfo', '', 'ProgramInfo')
               .AddBar('GroupInfo', '', 'GroupInfo')
               .AddBar('MasterMeterInfo', '', 'MasterMeterInfo')
               .AddBar('ExpenseCodeInfo', '', 'ExpenseCodeInfo')
               .AddBar('RevenueCatInfo', '', 'RevenueCatInfo')
               .AddBar('TankInfo', '', 'TankInfo')
               .AddSeparatorBar()
               .AddBar('FixedExpInfo', '', 'FixedExpInfo')
               .AddBar('RecurringBillInfo', '', 'RecurringBillInfo')
               .AddBar('TaxTableInfo', '', 'TaxTableInfo')
               .AddBar('TaxSectionInfo', '', 'TaxSectionInfo')
               .AddSeparatorBar()
               .AddBar('OwnerHistoryAdj', '', 'OwnerHistoryAdj')
               .AddBar('WellHistoryAdj', '', 'WellHistoryAdj')
               .AddBar('SuspenseHistoryAdj', '', 'SuspenseHistoryAdj')
               .AddSeparatorBar()
               .AddBar('OwnerTotals', '', 'OwnerTotals')
               .AddBar('WellTotals', '', 'WellTotals')
               .AddSeparatorBar()
               .AddBar('LandFiles', '', 'LandFiles')
               .AddBar('AFEFiles', '', 'AFEFiles')
               .AddBar('InvestmentFiles', '', 'InvestmentFiles')
               .AddBar('HouseGasOwners', '', 'HouseGasOwners')
               .AddBar('PluggingModule', '', 'PluggingModule')
            OTHERWISE
         ENDCASE
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS CompanyInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Company I\<nformation]
   cOnClickCommand	= [m.goStateManager.OpenForm('company.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ChartofAccounts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Chart of \<Accounts]
   cOnClickCommand	= [m.goStateManager.OpenFormMulti('glcoa.scx')]
   cSkipFor		= [NOT m.goApp.lGLData]
ENDDEFINE

*===============================================================================
DEFINE CLASS GLAccountTypes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [G/L Account T\<ypes]
   cOnClickCommand	= [m.goStateManager.OpenFormMulti('glacctyp.scx')]
   cSkipFor		= [NOT m.goApp.lGLData]
ENDDEFINE

*AM
*===============================================================================
*===============================================================================
DEFINE CLASS DisbursementJIBFiles AS SFBar OF SFMenu.vcx
*===============================================================================
*===============================================================================
   cCaption	 = [\<Disbursement and JIB Files]
   cPopupName	 = [DisbJIBFiles]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('LeaseInfo', '', 'LeaseInfo')
         .AddBar('WellInfo', '', 'WellInfo')
         .AddBar('OwnerInfo', '', 'OwnerInfo')
         .AddBar('DOIInfo', '', 'DOIInfo')
         .AddSeparatorBar()
         .AddBar('PumperInfo', '', 'PumperInfo')
         .AddBar('PurchaserInfo', '', 'PurchaserInfo')
         .AddBar('ProgramInfo', '', 'ProgramInfo')
         .AddBar('GroupInfo', '', 'GroupInfo')
         .AddBar('MasterMeterInfo', '', 'MasterMeterInfo')
         .AddBar('ExpenseCodeInfo', '', 'ExpenseCodeInfo')
         .AddBar('RevenueCatInfo', '', 'RevenueCatInfo')
         .AddBar('TankInfo', '', 'TankInfo')
         .AddSeparatorBar()
         .AddBar('FixedExpInfo', '', 'FixedExpInfo')
         .AddBar('RecurringBillInfo', '', 'RecurringBillInfo')
         .AddBar('TaxTableInfo', '', 'TaxTableInfo')
         .AddBar('TaxSectionInfo', '', 'TaxSectionInfo')
         .AddSeparatorBar()
         .AddBar('OwnerHistoryAdj', '', 'OwnerHistoryAdj')
         .AddBar('WellHistoryAdj', '', 'WellHistoryAdj')
         .AddBar('SuspenseHistoryAdj', '', 'SuspenseHistoryAdj')
         .AddSeparatorBar()
         .AddBar('OwnerTotals', '', 'OwnerTotals')
         .AddBar('WellTotals', '', 'WellTotals')
         .AddSeparatorBar()
         .AddBar('LandFiles', '', 'LandFiles')
         .AddBar('AFEFiles', '', 'AFEFiles')
         .AddBar('HouseGasOwners', '', 'HouseGasOwners')
         .AddBar('PluggingModule', '', 'PluggingModule')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS LeaseInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Lease Information]
   cOnClickCommand	= [m.goStateManager.OpenFormMulti('lmleaseinfo.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata and not m.goapp.llanddata and not m.goapp.ljibdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS WellInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Well Information]
   cOnClickCommand	= [m.goStateManager.OpenFormMulti('dmwellinfo.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata and not m.goapp.lpartnerdata and not m.goapp.lafedata and not m.goapp.ljibdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Owner Information]
   cSkipFor = [not m.goapp.lrevdistdata and not m.goapp.lpartnerdata and not m.goapp.lafedata and not m.goapp.lhousegasdata and not m.goapp.ljibdata]

   PROCEDURE CLICK
      IF m.goapp.lProgOpt
         m.goStateManager.OpenFormMulti('dmownerinfo.scx')
      ELSE
         m.goStateManager.OpenFormMulti('dmowners.scx')
      ENDIF
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS DOIInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Division of Interests]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmdoi.scx')]
   cSkipFor		= [not m.goapp.ldoidata]
ENDDEFINE

*===============================================================================
DEFINE CLASS PumperInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [P\<umper Information]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmpumpers.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS PurchaserInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Purchaser Information]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrevsrc.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS ProgramInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well P\<rogram/Partnerships]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmprog.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS GroupInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well \<Group Definitions]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmgroups.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata and not m.goapp.ljibdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS MasterMeterInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Master Meters]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmmeters.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS ExpenseCodeInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [E\<xpense Codes]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmexpcat.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata and not m.goapp.lafedata and not m.goapp.ljibdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS RevenueCatInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Revenue \<Categories]
   cOnClickCommand	= [m.goStateManager.openform('dmrevcat.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS TankInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Tank Information]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmtanks.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS FixedExpInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Fixed Well Expenses]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmfixedexp.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata and not m.goapp.ljibdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS RecurringBillInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [R\<ecurring A/P Bills]
   cOnClickCommand	= [m.goStateManager.Openform('aprecur.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS TaxTableInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well Product Tax \<Tables]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmtaxes.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS TaxSectionInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Expense Section Co\<des]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmtaxcodes.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata and not m.goapp.lafedata and not m.goapp.ljibdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerHistoryAdj AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner \<History Adjustments]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmownerhistory.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS WellHistoryAdj AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well History Ad\<justments]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmwellhistory.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS SuspenseHistoryAdj AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Suspense Beginning Balances/Adjustments]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmsuspbal.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerTotals AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Totals]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmowntot.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS WellTotals AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well Totals]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmwelltot.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS LandFiles AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Land Files]
   cPopupName	 = [LandManage]
   cSkipFor	 = [not m.goapp.llandopt or not m.goapp.lLandData]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('LandInfo', '', 'LandInfo')
         .AddBar('LeaseOwners', '', 'LeaseOwners')
         .AddBar('Formations', '', 'Formations')
         .AddBar('AMIInfo', '', 'AMIInfo')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS LandInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Lease Information]

   PROCEDURE CLICK
      DO CASE
         CASE m.goapp.lEnhancedLand AND m.goapp.lDocuments
            m.goStateManager.OpenFormMulti('lmleaseinfod.scx')
         CASE m.goapp.lEnhancedLand
            m.goStateManager.OpenFormMulti('lmleaseinfod.scx')
         CASE m.goapp.lDocuments
            m.goStateManager.OpenFormMulti('lmlandinfod.scx')
         OTHERWISE
            m.goStateManager.OpenFormMulti('lmlandinfod.scx')
      ENDCASE

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS LeaseOwners AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Lease \<Obligations]
   cOnClickCommand	= [m.gostatemanager.openform('lmlandowner.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Formations AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Formations]
   cOnClickCommand	= [m.goStateManager.Openform('lmformations.scx')]
   cSkipFor		= [NOT m.goApp.lEnhancedLand]
ENDDEFINE

*===============================================================================
DEFINE CLASS AMIInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<AMI Information]
   cOnClickCommand	= [m.goStateManager.Openform('lmamiinfo.scx')]
   cSkipFor		= [NOT m.goApp.lEnhancedLand]
ENDDEFINE

*===============================================================================
DEFINE CLASS InvestmentFiles AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [InvestmentFiles]
   cPopupName	 = [InvestmentFiles]
   cSkipFor	 = [not m.goapp.lInvestData]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('Fields', '', 'Fields')
         .AddBar('Investments', '', 'Investments')
         .AddBar('DeplSetup', '', 'DeplSetup')
         .AddBar('DeplPcts', '', 'DeplPcts')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS FIELDS AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Field Information]
   cOnClickCommand	= [m.gostatemanager.openform('imfields.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Investments AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Investment/Payout Information]
   cOnClickCommand	= [m.gostatemanager.openform('iminvestment.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS DeplSetup AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Depletion Setup]
   cOnClickCommand	= [m.gostatemanager.openform('imdeplset.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS DeplPcts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Depletion \<Pcts]
   cOnClickCommand	= [m.gostatemanager.openform('imdeplpct.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS AFEFiles AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<AFE Files]
   cPopupName	 = [AFEMainten]
   cSkipFor	 = [not m.goapp.lafeopt and not m.goapp.lafepriv]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('AFEMaint', '', 'AFEMaint')
         .AddBar('AFECopy', '', 'AFECopy')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS AFEMaint AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<AFE Maintenance]
   cOnClickCommand	= [m.gostatemanager.openform('afemaint.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS AFECopy AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Copy AFE]
   cOnClickCommand	= [m.gostatemanager.openform('afecopy.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS AFEFiles AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<AFE Files]
   cPopupName	 = [AFEMainten]
   cSkipFor	 = [not m.goapp.lafeopt and not m.goapp.lafepriv]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('AFEMaint', '', 'AFEMaint')
         .AddBar('AFECopy', '', 'AFECopy')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS AFEMaint AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<AFE Maintenance]
   cOnClickCommand	= [m.gostatemanager.openform('afemaint.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS AFECopy AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Copy AFE]
   cOnClickCommand	= [m.gostatemanager.openform('afecopy.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS BrineFiles AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Brine Ha\<uler Files]
   cSkipFor	 = [NOT m.goApp.lBrineOpt or NOT m.goApp.lBrinedata]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('BrineLeases', '', 'BrineLeases')
         .AddBar('DisposalSites', '', 'DisposalSites')
         .AddBar('Trucks', '', 'Trucks')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS BrineLeases AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Brine Pickup Wells]
   cOnClickCommand	= [m.goStateManager.OpenForm('bmleases.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS DisposalSites AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Disposal Sites]
   cOnClickCommand	= [m.goStateManager.OpenForm('bmdispsite.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Trucks AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Trucks]
   cOnClickCommand	= [m.goStateManager.OpenForm('bmtrucks.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS HouseGasOwners AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [House Gas \<Owners]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmgasown.scx')]
   cSkipFor		= [NOT m.goapp.lhousegasopt or not m.goapp.lhousegasdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS PluggingModule AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Pl\<ugging Module]
   cSkipFor	 = [not m.goapp.lPluggingModule]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('PluggingTargets', '', 'PluggingTargets')
         .AddBar('PluggingAdj', '', 'PluggingAdj')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS PluggingTargets AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Plugging \<Fund Well Targets]
   cOnClickCommand	= [m.gostatemanager.openform('plugwell.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PluggingAdj AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Plugging Fund Balance Adjustments]
   cOnClickCommand	= [m.gostatemanager.openform('plugwellbal.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS FixedAssetInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Fi\<xed Asset Information]
   cOnClickCommand	= [m.gostatemanager.openform('glassets.scx')]
   cSkipFor = [NOT m.goApp.lGLdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS BillingCodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Inventory/\<Billing Codes]
   cOnClickCommand	= [m.gostatemanager.openform('aritems.scx')]
   cSkipFor = [NOT m.goApp.lARdata and not m.goapp.lbrinedata]
ENDDEFINE

*===============================================================================
DEFINE CLASS GLDeptInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Depa\<rtment Information]
   cOnClickCommand	= [m.gostatemanager.openform('gldept.scx')]
   cSkipFor = [NOT m.goApp.lGLdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS FinanceChargeCodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Finance Charge Codes]
   cOnClickCommand	= [m.gostatemanager.openform('arfinchg.scx')]
   cSkipFor = [NOT m.goApp.lARdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS TermsCodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Terms Codes]
   cOnClickCommand	= [m.gostatemanager.openform('glterms.scx')]
   cSkipFor = [NOT m.goApp.lARdata and not m.goapp.lAPData]
ENDDEFINE

*===============================================================================
DEFINE CLASS SalesTaxCodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Sales Tax Codes]
   cOnClickCommand	= [m.gostatemanager.openform('arsalestx.scx')]
   cSkipFor = [NOT m.goApp.lARdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS PayrollCodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<Payroll Codes]
   cSkipFor	 = [not m.goapp.lpayrollopt or NOT m.goApp.lPayrolldata]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('PRIncomeCodes', '', 'PRIncomeCodes')
         .AddBar('PRDeductionCodes', '', 'PRDeductionCodes')
         .AddBar('PRTaxCodes', '', 'PRTaxCodes')
         .AddSeparatorBar()
         .AddBar('PRSUTACodes', '', 'PRSUTACodes')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS PRIncomeCodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Payroll \<Income Codes]
   cOnClickCommand	= [m.gostatemanager.openform('princupd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PRDeductionCodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Payroll \<Deduction Codes]
   cOnClickCommand	= [m.goStateManager.Openform('prdedupd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PRTaxCodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Payroll \<Taxes]
   cOnClickCommand	= [m.goStateManager.Openform('prtaxupd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PRSUTACodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State \<Unemployment Codes]
   cOnClickCommand	= [m.goStateManager.Openform('prsuta.scx')]
ENDDEFINE

*===============================================================================
*===============================================================================
*===============================================================================
DEFINE CLASS Tasks AS SFPad OF SFMenu.vcx
*===============================================================================
*===============================================================================
*===============================================================================
   cCaption	 = [\<Tasks]
   cKey		 = [ALT+T]
   cPopupName	 = [Tasks]
   cSkipFor	 = [not m.goapp.lopencompany or m.goApp.lExpired]

   PROCEDURE AddBars
      WITH THIS
         DO CASE
            CASE m.goapp.lAMVersion
               .AddBar('SalesInvoicing', '', 'SalesInvoicing')
               .AddBar('ReceivePayments', '', 'ReceivePayments')
               .AddBar('GenFinanceChgs', '', 'GenFinanceChgs')
               .AddSeparatorBar()
               .AddBar('CashReceipts', '', 'CashReceipts')
               .AddBar('CashDisbursements', '', 'CashDisbursements')
               .AddBar('MakeDeposits', '', 'MakeDeposits')
               .AddBar('CheckProcessing', '', 'CheckProcessing')
               .AddBar('ReconcileBankAccts', '', 'ReconcileBankAccts')
               .AddSeparatorBar()
               .AddBar('DisbJIBTasks', '', 'DisbJIBTasks')
               .AddBar('WellRevenue', '', 'WellRevenue')
               .AddBar('GasMeterRecon', '', 'GasMeterRecon')
               .AddBar('AllocateRevenue', '', 'AllocateRevenue')
               .AddBar('StatementNotes', '', 'StatementNotes')
               .AddSeparatorBar()
               .AddBar('EnterBills', '', 'EnterBills')
               .AddBar('PurchaseInventory', '', 'PurchaseInventory')
               .AddBar('PayBills', '', 'PayBills')
               .AddBar('TransferInventory', '', 'TransferInventory')
               .AddSeparatorBar()
               .AddBar('WellExpenses', '', 'WellExpenses')
               .AddBar('FixedExpRel', '', 'FixedExpRel')
               .AddBar('PluggingRel', '', 'PluggingRel')
               .AddBar('AllocateExpensesEvenly', '', 'AllocateExpensesEvenly')
               .AddBar('AllocateExpenses', '', 'AllocateExpenses')
               .AddSeparatorBar()
               .AddBar('CheckProcessing', '', 'CheckProcessing')
               .AddBar('DelayRentalChecks', '', 'DelayRentalChecks')
               .AddSeparatorBar()
               .AddBar('HouseGasTasks', '', 'HouseGasTasks')
               .AddSeparatorBar()
               .AddBar('CloseRevRun', '', 'CloseRevRun')
               .AddBar('CloseJIBRun', '', 'CloseJIBRun')
               .AddBar('CloseFiscalPeriod', '', 'CloseFiscalPeriod')
               .AddSeparatorBar()
               .AddBar('DataImports', '', 'DataImports')
               .AddSeparatorBar()
               .AddBar('CustomTasks', '', 'CustomTasks')

            CASE m.goapp.lQBVersion
               .AddBar('Receipts', '', 'Receipts')
               .AddBar('WellRevenue', '', 'WellRevenue')
               .AddBar('GasMeterRecon', '', 'GasMeterRecon')
               .AddBar('AllocateRevenue', '', 'AllocateRevenue')
               .AddBar('StatementNotes', '', 'StatementNotes')
               .AddSeparatorBar()
               .AddBar('EnterBills', '', 'EnterBills')
               .AddBar('WellExpenses', '', 'WellExpenses')
               .AddBar('FixedExpRel', '', 'FixedExpRel')
               .AddBar('PluggingRel', '', 'PluggingRel')
               .AddBar('AllocateExpensesEvenly', '', 'AllocateExpensesEvenly')
               .AddBar('AllocateExpenses', '', 'AllocateExpenses')
               .AddSeparatorBar()
               .AddBar('CheckProcessing', '', 'CheckProcessing')
               .AddBar('DelayRentalChecks', '', 'DelayRentalChecks')
               .AddBar('RecNetPayments', '', 'RecNetPayments')
               .AddBar('RecPrepayments', '', 'RecPrepayments')
               .AddSeparatorBar()
               .AddBar('HouseGasMeterEntry', '', 'HouseGasMeterEntry')
               .AddSeparatorBar()
               .AddBar('CloseRevRun', '', 'CloseRevRun')
               .AddBar('CloseJIBRun', '', 'CloseJIBRun')
               .AddSeparatorBar()
               .AddBar('PostToQB', '', 'PostToQB')
               .AddSeparatorBar()
               .AddBar('DataImports', '', 'DataImports')
               .AddSeparatorBar()
               .AddBar('CustomTasks', '', 'CustomTasks')
            OTHERWISE
         ENDCASE
      ENDWITH
   ENDPROC
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS ReceivePayments AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Receive Payments]
   cPopupName = [ReceivePayments]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('RecCustPayments', '', 'RecCustPayments')
         .AddBar('RecJIBPayments', '', 'RecJIBPayments')
         .AddBar('RecNetPayments', '', 'RecNetPayments')
         .AddBar('RecPrepayments', '', 'RecPrepayments')
      ENDWITH
   ENDPROC
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS RecCustPayments AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Customer Payments]
   cOnClickCommand	= [m.gostatemanager.openform('arrecpmt.scx','AR')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS RecNetPayments AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Receive \<Owner Net Payments]
   cOnClickCommand	= [m.gostatemanager.openform('arrecpmt.scx','NET')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS RecJIBPayments AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<JIB Payments]
   cOnClickCommand	= [m.gostatemanager.openform('arrecpmt.scx','JIB')]
   cSkipFor		= [not m.goapp.ljibdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS RecHGPayments AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<House Gas Payments]
   cOnClickCommand	= [m.gostatemanager.openform('arrecpmt.scx','HG')]
   cSkipFor		= [not m.goapp.lhousegasdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS RecPrepayments AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Receive O\<wner Prepayments]
   cSkipFor		= [not m.goapp.lrevdistdata]

   PROCEDURE CLICK
      IF m.goapp.lQBVersion
         m.goStateManager.openform('dmprepayqb.scx')
      ELSE
         m.goStateManager.openform('dmprepay.scx')
      ENDIF

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS Receipts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Production Receipts]
   cOnClickCommand	= [m.gostatemanager.openform('csreceipt.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*AM
*===============================================================================
*===============================================================================
DEFINE CLASS DisbJIBTasks AS SFBar OF SFMenu.vcx
*===============================================================================
*===============================================================================
   cCaption		= [Disbursement and JIB \<Tasks]
   cSkipFor		= [not m.goapp.lrevdistdata]
   cPopupName   = [DisbJIBTasks]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('WellRevenue', '', 'WellRevenue')
         .AddBar('GasMeterRecon', '', 'GasMeterRecon')
         .AddBar('AllocateRevenue', '', 'AllocateRevenue')
         .AddBar('StatementNotes', '', 'StatementNotes')
         .AddSeparatorBar()
         .AddBar('WellExpenses', '', 'WellExpenses')
         .AddBar('FixedExpRel', '', 'FixedExpRel')
         .AddBar('PluggingRel', '', 'PluggingRel')
         .AddBar('AllocateExpensesEvenly', '', 'AllocateExpensesEvenly')
         .AddBar('AllocateExpenses', '', 'AllocateExpenses')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS WellRevenue AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well \<Revenue by Well (8/8ths)]
   cSkipFor		= [not m.goapp.lrevdistdata]

   PROCEDURE CLICK
      IF m.goapp.lAMVersion
         m.goStateManager.openform('dmwellrev.scx')
      ELSE
         m.goStateManager.openform('dmwellinc1.scx')
      ENDIF
   ENDPROC

ENDDEFINE

*===============================================================================
DEFINE CLASS GasMeterRecon AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Gas Meter Reconciliation]
   cOnClickCommand	= [m.gostatemanager.openform('dmmeterall.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS AllocateRevenue AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Allocate Held Re\<venue]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmselrev.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS StatementNotes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Enter Statement \<Notes]
   cOnClickCommand	= [m.goStateManager.Openform('dmstmtnotes.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS EnterBills AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Enter \<Bills]
   cOnClickCommand	= [m.gostatemanager.openform('apbill.scx')]
   cSkipFor		= [NOT m.goApp.lAPdata and not m.goapp.lrevdistdata]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PurchaseInventory AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Purchase In\<ventory Items]
   cOnClickCommand	= [m.gostatemanager.openform('apbill2.scx')]
   cSkipFor		= [NOT m.goApp.lAPdata and not m.goapp.lardata]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PayBills AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Pay Bills]
   cOnClickCommand	= [m.gostatemanager.openform('apbillpay.scx')]
   cSkipFor		= [NOT m.goApp.lAPdata]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS TransferInventory AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Transfer Inventory to \<Wells]
   cOnClickCommand	= [m.gostatemanager.openform('dminvtrans.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata and not m.goapp.ljibdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS WellExpenses AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well \<Expenses by Well (8/8ths)]
   cOnClickCommand	= [m.gostatemanager.openform('dmwellexpense.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS FixedExpRel AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Release \<Fixed Expenses]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmfixrel.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS PluggingRel AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Release \<Plugging Fund Charges]
   cOnClickCommand	= [m.gostatemanager.openform('pluggingrel.scx')]
   cSkipFor		= [not m.goapp.lPluggingModule]
ENDDEFINE

*===============================================================================
DEFINE CLASS AllocateExpensesEvenly AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Allocate Operator-Charged Expe\<nses Evenly]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmexpall.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS AllocateExpenses AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Allocate Held Expenses]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmselexp.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS CheckProcessing AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Chec\<k Processing]
   cSkipFor = [not m.goapp.lrevdistdata]
   cPopupName = [CheckProcessing]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('CheckRegister', '', 'CheckRegister')
         .AddBar('PrintChecks', '', 'PrintChecks')

         IF m.goapp.lAMVersion
            .AddBar('VoidReissue', '', 'VoidReissue')
         ENDIF

      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS CheckRegister AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Check Register]
   cOnClickCommand	= [m.gostatemanager.openform('csregister.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PrintChecks AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Print Checks]
   cOnClickCommand	= [m.gostatemanager.openform('cschecks.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS VoidReissue AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Void/Reissue Checks]
   cOnClickCommand	= [m.gostatemanager.openform('csvoidreissue.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS DelayRentalChecks AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Create Dela\<y Rental Checks]
   cOnClickCommand	= [m.gostatemanager.openform('lmlandchk.scx')]
   cSkipFor		= [not m.goapp.llandopt or not m.goapp.llanddata]
ENDDEFINE

*===============================================================================
DEFINE CLASS HouseGasTasks AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [House Gas Tasks]
   cPopupName = [HGTasks]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('HouseGasMeterEntry', '', 'HouseGasMeterEntry')
         .AddBar('HouseGasUsageAdj', '', 'HouseGasUsageAdj')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS HouseGasMeterEntry AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Ho\<use Gas Meter Entry]
   cOnClickCommand	= [m.gostatemanager.openform('dmgasuse.scx')]
   cSkipFor		= [NOT m.goapp.lhousegasopt or not m.goapp.lhousegasdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS HouseGasUsageAdj AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Usage Adjustments]
   cOnClickCommand	= [m.gostatemanager.openform('dmgasbaladj.scx')]
   cSkipFor		= [NOT m.goapp.lhousegasopt or not m.goapp.lhousegasdata]
ENDDEFINE

*===============================================================================
DEFINE CLASS CloseRevRun AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Close a Revenue Run]
   cOnClickCommand	= [m.gostatemanager.openform('dmcloserev.scx')]
   cSkipFor		= [not m.goapp.lrevdistdata or m.goapp.lReadOnly]
ENDDEFINE

*===============================================================================
DEFINE CLASS CloseJIBRun AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Close a \<JIB Run]
   cOnClickCommand	= [m.gostatemanager.openform('dmclosejib.scx')]
   cSkipFor		= [not m.goapp.ljibdata or m.goapp.lReadonly]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS CloseFiscalPeriod AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Close a \<Fiscal Accounting Period]
   cOnClickCommand	= [m.gostatemanager.openform('glcloseprd.scx')]
   cSkipFor		= [not m.goapp.lgldata or m.goapp.lReadonly]
ENDDEFINE

*QB
*===============================================================================
DEFINE CLASS PostToQB AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Post a Revenue Run To QuickBooks]
   cSkipFor = [not m.goapp.oQB.lqbactive or not m.goapp.lrevdistdata]
   onClickCommand = [m.gostatemanager.openform('dmqbpostr.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS DataImports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Data Imports]
   cSkipFor = [not m.goApp.lImportModule]
   cPopupName = [DataImports]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('ImportRevExp', '', 'ImportRevExp')
         .AddBar('ImportDataFiles', '', 'ImportDataFiles')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportRevExp AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Import Receipts, Bills]
   cPopupName	 = [ImportRevExp]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('ImportReceipts', '', 'ImportReceipts')
         .AddBar('ImportBills', '', 'ImportBills')

         IF m.goapp.lAMVersion
            .AddBar('ImportGLEntries', '', 'ImportGLEntries')
         ENDIF

      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportReceipts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Receipts]
   cOnClickCommand	= [m.gostatemanager.openform('importrev.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportBills AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Bills]
   cOnClickCommand	= [m.goStateManager.openform('importexp.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportGLEntries AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import G/L Entries]
   cOnClickCommand	= [m.goStateManager.openform('importdata.scx','GL')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportDataFiles AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Import Data Files]
   cPopupName	 = [ImportData]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('ImportWells', '', 'ImportWells')
         .AddBar('ImportOwners', '', 'ImportOwners')
         .AddBar('ImportDOI', '', 'ImportDOI')
         .AddBar('ImportPurchasers', '', 'ImportPurchasers')
         .AddBar('ImportExpCodes', '', 'ImportExpCodes')
         .AddBar('ImportLeases', '', 'ImportLeases')
         .AddBar('ImportMasterMeters', '', 'ImportMasterMeters')
         IF m.goapp.lAMVersion
            .AddBar('ImportVendors', '', 'ImportVendors')
            .AddBar('ImportAccounts', '', 'ImportAccounts')
         ENDIF
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportWells AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Wells]
   cOnClickCommand	= [m.goStateManager.OpenForm('importdata.scx','WELL')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportOwners AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Owners]
   cOnClickCommand	= [m.goStateManager.OpenForm('importdata.scx','OWN')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportDOI AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import DOI]
   cOnClickCommand	= [m.goStateManager.OpenForm('importdata.scx','DOI')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportPurchasers AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Purchasers]
   cOnClickCommand	= [m.goStateManager.OpenForm('importdata.scx','PURCH')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportExpCodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Expense Codes]
   cOnClickCommand	= [m.goStateManager.OpenForm('importdata.scx','ECAT')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportLeases AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Leases]
   cOnClickCommand	= [m.goStatemanager.openform('importdata.scx','LSE')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ImportMasterMeters AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Master Meters]
   cOnClickCommand	= [m.goStatemanager.openform('importdata.scx','METER')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS ImportVendors AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Vendors]
   cOnClickCommand	= [m.goStatemanager.openform('importdata.scx','VEND')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS ImportAccounts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Import Accounts]
   cOnClickCommand	= [m.goStatemanager.openform('importdata.scx','COA')]
ENDDEFINE

*===============================================================================
DEFINE CLASS CustomTasks AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [CustomTasks]
   cPopupName	 = [CustomTasks]

ENDDEFINE

*===============================================================================
*===============================================================================
*===============================================================================
DEFINE CLASS Reports AS SFPad OF SFMenu.vcx
*===============================================================================
*===============================================================================
*===============================================================================
   cCaption	 = [\<Reports]
   cPopupName	 = [Reports]
   cSkipFor	 = [not m.goapp.lopencompany or m.goApp.lExpired or m.goApp.lReadOnly]

   PROCEDURE AddBars
      WITH THIS
         IF m.goapp.lAMVersion
            .AddBar('AR_Reports', '', 'AR_Reports')
            .AddBar('AP_Reports', '', 'AP_Reports')
            .AddBar('GL_Reports', '', 'GL_Reports')
            .AddBar('PR_Reports', '', 'PR_Reports')
            .AddSeparatorBar()
            .AddBar('CS_Reports', '', 'CS_Reports')
            .AddSeparatorBar()
         ENDIF

         .AddBar('WellReports', '', 'WellReports')
         .AddBar('OwnerReports', '', 'OwnerReports')
         .AddBar('ProgramReports', '', 'ProgramReports')
         .AddBar('SuspenseReports', '', 'SuspenseReports')
         .AddSeparatorBar()
         .AddBar('LandReports', '', 'LandReports')
         .AddBar('AFEReports', '', 'AFEReports')
         .AddBar('InvestmentReports', '', 'InvestmentReports')
         .AddBar('HouseGasReports', '', 'HouseGasReports')
         .AddBar('PluggingReports', '', 'PluggingReports')
         .AddSeparatorBar()
         .AddBar('Process1099s', '', 'Process1099s')
         .AddBar('Process1065s', '', 'Process1065')
         .AddSeparatorBar()
         .AddBar('TaxReports', '', 'TaxReports')
         .AddBar('StateComplianceReports', '', 'StateComplianceReports')
         .AddSeparatorBar()

         IF m.goapp.lAMVersion
            .AddBar('Asset_Reports', '', 'Asset_Reports')
         ENDIF
         .AddBar('Graphing', '', 'Graphing')
         .AddBar('OtherReports', '', 'OtherReports')
         .AddSeparatorBar()
         .AddBar('CustomReports', '', 'CustomReports')
         .AddBar('AdvancedReporting', '', 'AdvancedReporting')
      ENDWITH
   ENDPROC
ENDDEFINE

*AM
*===============================================================================
*===============================================================================
DEFINE CLASS AR_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
*===============================================================================
   cCaption	 = [A/\<R Reports]
   cPopupName	 = [ARReports]
   cSkipFor	 = [NOT m.goApp.lARreports]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('CustomerListing', '', 'CustomerListing')
         .AddBar('CustomerLabels', '', 'CustomerLabels')
         .AddSeparatorBar()
         .AddBar('AgedReceivableRpt', '', 'AgedReceivableRpt')
         .AddBar('InvoiceListing', '', 'InvoiceListing')
         .AddBar('InvoicesandPaymentsReports', '', 'InvoicesandPaymentsReports')
         .AddBar('PrintInvoices', '', 'PrintInvoices')
         .AddSeparatorBar()
         .AddBar('SalesJournRpt', '', 'SalesJournRpt')
         .AddBar('BillingCodeSummary', '', 'BillingCodeSummary')
         .AddBar('CustomerStatements', '', 'CustomerStatements')
      ENDWITH
   ENDPROC
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS CustomerListing AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Customer Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('arcustrpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS CustomerLabels AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Customer \<Labels]
   cOnClickCommand	= [m.goStateManager.OpenForm('arcustlab.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS AgedReceivableRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Aged Receivables Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('araged.scx','A')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS InvoiceListing AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Invoice Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('arinvlist.scx','A')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS InvoicesandPaymentsReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Invoices and Pa\<yments Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('arinvrpt.scx','A')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PrintInvoices AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Print Invoices]
   cOnClickCommand	= [m.goStateManager.OpenForm('arinvprint.scx','A')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS SalesJournRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Sales Journal Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('arsalesjrn.scx','A')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS BillingCodeSummary AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Billing Code Summary]
   cOnClickCommand	= [m.goStateManager.OpenForm('arbillcode.scx','A')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS CustomerStatements AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [C\<ustomer Statements]
   cOnClickCommand	= [m.goStateManager.OpenForm('arcuststm.scx','A')]
ENDDEFINE

*AM
*===============================================================================
*===============================================================================
DEFINE CLASS AP_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
*===============================================================================
   cCaption	 = [A/\<P Reports]
   cPopupName	 = [APReports]
   cSkipFor	 = [NOT m.goApp.lAPreports]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('VendorListing', '', 'VendorListing')
         .AddBar('VendorLabels', '', 'VendorLabels')
         .AddSeparatorBar()
         .AddBar('VendorActRpt', '', 'VendorActRpt')
         .AddBar('VendorCheckStmts', '', 'VendorCheckStmts')
         .AddSeparatorBar()
         .AddBar('AgedPayableRpt', '', 'AgedPayableRpt')
         .AddBar('CashRequirements', '', 'CashRequirements')
         .AddBar('OutstandingBills', '', 'OutstandingBills')
         .AddBar('BillPaymentRpt', '', 'BillPaymentRpt')
         .AddBar('PurchaseJournRpt', '', 'PurchaseJournRpt')
         .AddBar('SalesTaxPayable', '', 'SalesTaxPayable')
         .AddSeparatorBar()
         .AddBar('ConsolidatedPayables', '', 'ConsolidatedPayables')
      ENDWITH
   ENDPROC
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS VendorListing AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Vendor Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('apvendrpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS VendorLabels AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Vendor \<Labels]
   cOnClickCommand	= [m.goStateManager.OpenForm('apvendlab.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS VendorActRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Vendor \<Activity Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('apvendact.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS VendorCheckStmts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Vendor Check \<Statements]
   cOnClickCommand	= [m.goStateManager.OpenForm('apvendstm.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS AgedPayableRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Aged \<Payables Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('apaged.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS CashRequirements AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Cash Requirements]
   cOnClickCommand	= [m.goStateManager.OpenForm('apcashreq.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS OutstandingBills AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Outstanding \<Bills]
   cOnClickCommand	= [m.goStateManager.OpenForm('apbillout.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS BillPaymentRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Bill Payment Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('apbillpayrpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PurchaseJournRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Purchase \<Journal Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('apbilljrn.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS SalesTaxPayable AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Purchase \<Journal Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('apsalestx.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS ConsolidatedPayables AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Consolidated Payables]
   cOnClickCommand	= [m.goStateManager.OpenForm('apagedcon.scx')]
ENDDEFINE

*AM
*===============================================================================
*===============================================================================
DEFINE CLASS GL_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
*===============================================================================
   cCaption	 = [\<G/L Reports]
   cPopupName	 = [GLReports]
   cSkipFor	 = [NOT m.goApp.lGLreports]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('COAListing', '', 'COAListing')
         .AddSeparatorBar()
         .AddBar('JournalRpts', '', 'JournalRpts')
         .AddBar('TransGroupJournal', '', 'TransGroupJournal')
         .AddSeparatorBar()
         .AddBar('GLActWell', '', 'GLActWell')
         .AddBar('GLActID', '', 'GLActID')
         .AddBar('GLActDept', '', 'GLActDept')
         .AddBar('GLAct', '', 'GLAct')
         .AddSeparatorBar()
         .AddBar('TrialBalance', '', 'TrialBalance')
         .AddBar('BalanceSheet', '', 'BalanceSheet')
         .AddBar('IncomeStmt', '', 'IncomeStmt')
         .AddSeparatorBar()
         .AddBar('ConsolidatedGLRpts', '', 'ConsolidatedGLRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS COAListing AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Chart of Accounts Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('glcoalist.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS JournalRpts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Journal Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('gljournrpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS TransGroupJournal AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Tra\<nsaction Group Journal]
   cOnClickCommand	= [m.goStateManager.OpenForm('gltrangroup.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS GLActWell AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [G/L Activity by \<Well]
   cOnClickCommand	= [m.goStateManager.OpenForm('glacctactw.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS GLActID AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [G/L Activity by \<ID]
   cOnClickCommand	= [m.goStateManager.OpenForm('glactid.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS GLActDept AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [G/L Activity by \<Department]
   cOnClickCommand	= [m.goStateManager.OpenForm('glacctactd.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS GLAct AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<G/L Account Activity]
   cOnClickCommand	= [m.goStateManager.OpenForm('glactlist.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS TrialBalance AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\Trial Balance]
   cOnClickCommand	= [m.goStateManager.OpenForm('gltrialbrpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS BalanceSheet AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Balance Sheet]
   cOnClickCommand	= [m.goStateManager.OpenForm('glbalrpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS IncomeStatement AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Income Statement]
   cOnClickCommand	= [m.goStateManager.OpenForm('glincrpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS ConsolidatedGLRpts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Consolidated \<Reports]
   cPopupName	 = [GLConReports]
   cSkipFor	 = [NOT m.goApp.lGLreports]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('GLConTrial', '', 'GLConTrial')
         .AddBar('GLConBal', '', 'GLConBal')
         .AddBar('GLConInc', '', 'GLConInc')
      ENDWITH
   ENDPROC
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS GLConTrial AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Trial Balance]
   cOnClickCommand	= [m.goStateManager.OpenForm('gltrialcon.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS GLConBal AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Balance Sheet]
   cOnClickCommand	= [m.goStateManager.OpenForm('glbalcon.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS GLConInc AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Income Statement]
   cOnClickCommand	= [m.goStateManager.OpenForm('glinccon.scx')]
ENDDEFINE

*AM
*===============================================================================
*===============================================================================
DEFINE CLASS PR_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
*===============================================================================
   cCaption	 = [Pa\<yroll Reports]
   cPopupName	 = [PRReports]
   cSkipFor	 = [NOT m.goApp.lPayrollopt or not m.goapp.lpayrollreports]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('EmployeeRpts', '', 'EmployeeRpts')
         .AddSeparatorBar()
         .AddBar('PayrollRegister', '', 'PayrollRegister')
         .AddBar('PayrollDetailRpt', '', 'PayrollDetailRpt')
         .AddBar('PayrollStubRpt', '', 'PayrollStubRpt')
         .AddBar('PR941Worksheet', '', 'PR941Worksheet')
         .AddBar('FUTASUTARpts', '', 'FUTASUTARpts')
         .AddBar('IncomeTotals', '', 'IncomeTotals')
         .AddBar('DeductionTotals', '', 'DeductionTotals')
         .AddBar('PayrollDepositRpt', '', 'PayrollDepositRpt')
         .AddBar('PayrollDetailRpt', '', 'PayrollDetailRpt')
         .AddSeparatorBar()
         .AddBar('CreateW2File', '', 'CreateW2File')
         .AddBar('ModifyW2File', '', 'ModifyW2File')
         .AddBar('PrintW2Summary', '', 'PrintW2Summary')
         .AddBar('PrintW2Forms', '', 'PrintW2Forms')
         .AddBar('W2Portal', '', 'W2Portal')
         .AddBar('CheckW2Status', '', 'CheckW2Status')
      ENDWITH
   ENDPROC
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS EmployeeRpts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Employee Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('premplist.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PayrollRegister AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Payroll \<Register]
   cOnClickCommand	= [m.goStateManager.OpenForm('prreg.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PayrollDetailRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Payroll Detai\<l Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('prlabor.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PayrollStubRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Payroll Stu\<b Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('prstubrpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PR941Worksheet AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<941 Worksheet]
   cOnClickCommand	= [m.goStateManager.OpenForm('pr941.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS FUTASUTARpts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<FUTA/SUTA Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('prunemprpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS IncomeTotals AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Income Totals]
   cOnClickCommand	= [m.goStateManager.OpenForm('prtotrpt.scx','I')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS DeductionTotals AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Deduction \<Totals]
   cOnClickCommand	= [m.goStateManager.OpenForm('prtotrpt.scx','D')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PayrollDepositRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Payroll \<Deposit Liabilities]
   cOnClickCommand	= [m.goStateManager.OpenForm('prliabrpt.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS CreateW2File AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Create W2 File]
   cOnClickCommand	= [m.goStateManager.OpenForm('prw2make.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS ModifyW2File AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Modify W2 File]
   cOnClickCommand	= [m.goStateManager.OpenForm('prw2upd.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PrintW2Summary AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Print \<W2 Summary]
   cOnClickCommand	= [m.goStateManager.OpenForm('prw2list.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS PrintW2Forms AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Print W2 Forms]
   cOnClickCommand	= [m.goStateManager.OpenForm('prw2print.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS W2Portal AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [SherWare W2 Reporting/Submission]
   cOnClickCommand	= [m.goStateManager.OpenForm('prw2submission.scx')]
ENDDEFINE

*AM
*===============================================================================
DEFINE CLASS CheckW2Status AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Check W2 Filing Status]

   PROCEDURE CLICK
      oLink = CREATEOBJECT('hyperlink')
      oLink.NAVIGATETO('https://sherware.nelcoportal.com/Account/Logon')
   ENDPROC
ENDDEFINE

*===============================================================================
*===============================================================================
DEFINE CLASS WellReports AS SFBar OF SFMenu.vcx
*===============================================================================
*===============================================================================
   cCaption	 = [\<Well Reports]
   cPopupName	 = [WellReports]
   cSkipFor	 = [not m.goapp.lrevdistreports and not m.goapp.lpartnerreports and not m.goapp.lafereports and not m.goapp.ljibreports and not m.goapp.lInvestReports and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('WellListingRpt', '', 'WellListingRpt')
         .AddSeparatorBar()
         .AddBar('RevenueByPurchaserRpt', '', 'RevenueByPurchaserRpt')
         .AddBar('RevenueByWellRpt', '', 'RevenueByWellRpt')
         .AddBar('FixedWellExpensesRpt', '', '_5QP182JH5Bar5Rpt')
         .AddSeparatorBar()
         .AddBar('RevenueExpenseDetailRpt', '', 'RevenueExpenseDetailRpt')
         .AddBar('RevenueExpenseSummaryRpt', '', 'RevenueExpenseSummaryRpt')
         .AddBar('RevenueOpSummaryRpt', '', 'RevenueOpSummaryRpt')
         .AddSeparatorBar()
         .AddBar('JIBExpDetailRpt', '', 'JIBExpDetailRpt')
         .AddBar('JIBExpSummaryRpt', '', 'JIBExpSummaryRpt')
         .AddBar('JIBOpSummaryRpt', '', 'JIBOpSummaryRpt')
         .AddSeparatorBar()
         .AddBar('WellProfitLossRpt', '', 'WellProfitLossRpt')
         .AddBar('DisbByWellRpt', '', 'DisbByWellRpt')
         .AddBar('MCFBBLRpt', '', 'MCFBBLRpt')
         .AddBar('ProductionDeclineRpt', '', 'ProductionDeclineRpt')
         .AddSeparatorBar()
         .AddBar('SaltWaterRpt', '', 'SaltWaterRpt')
         .AddBar('ExpensesByCodeRpt', '', 'ExpensesByCodeRpt')
         .AddBar('ExpensesByVendorRpt', '', 'ExpensesByVendorRpt')
         .AddBar('ExpensesBySectionRpt', '', 'ExpensesBySectionRpt')
         .AddBar('UnallRevExpRpt', '', 'UnallRevExpRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS WellListingRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well/Interest \<Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwlist.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports and not m.goapp.lafereports]
ENDDEFINE

*===============================================================================
DEFINE CLASS RevenueByPurchaserRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well Revenue by Purc\<haser]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwrev.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS RevenueByWellRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well Revenue by Well]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwrevw.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS FixedWellExpensesRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Fixed Well Expenses]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwfix.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS RevenueExpenseDetailRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Revenue/Expense \<Detail]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwiedet.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS RevenueExpenseSummaryRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Revenue/Expense Su\<mmary]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwiesum.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS RevenueOpSummaryRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well Revenue \<Operating Summary]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwopsum.scx','R')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS JIBExpDetailRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well JIB Expense De\<tail Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwjibdet.scx')]
   cSkipFor		= [not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS JIBExpSummaryRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well JIB Expense Summary Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwiesumJ.scx','J')]
ENDDEFINE

*===============================================================================
DEFINE CLASS JIBOpSummaryRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well \<JIB Operating Summary]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwopsum.scx','J')]
   cSkipFor		= [not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS ProductionRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Production Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwprod.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS TotalsRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well \<Totals Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwytd.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS WellProfitLossRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well Profit and Lo\<ss]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwprofit.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS DisbByWellRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Disb\<ursements by Well]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwdisb.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS MCFBBLRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [MCF and \<BBL Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwmcf.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS ProductionDeclineRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Production Decline Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwdecline.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS SaltWaterRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Salt Wat\<er Reports]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwsalt.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS ExpensesByCodeRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well Expenses by Code]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwexp.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS ExpensesByVendorRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well Expenses by \<Vendor]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrvexp.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS ExpensesBySectionRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well Expenses by Tax \<Section]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrwclass.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS UnallRevExpRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Unallocated Revenue and Expenses]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrunall.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
*===============================================================================
DEFINE CLASS OwnerReports AS SFBar OF SFMenu.vcx
*===============================================================================
*===============================================================================
   cCaption	 = [\<Owner Reports]
   cPopupName	 = [OwnerReports]
   cSkipFor	 = [not m.goapp.lrevdistreports and not m.goapp.lpartnerreports and not m.goapp.lafereports and not m.goapp.ljibreports and not m.goapp.lInvestReports and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('OwnerListingRpt', '', 'OwnerListingRpt')
         .AddBar('OwnerLabelsRpt', '', 'OwnerLabelsRpt')
         .AddSeparatorBar()
         .AddBar('OwnerDistStmtsRpt', '', 'OwnerDistStmtsRpt')
         .AddBar('OwnerStubRpt', '', 'OwnerStubRpt')
         .AddBar('OwnerDisbSummaryRpt', '', 'OwnerDisbSummaryRpt')
         .AddBar('OwnerYearlyDisbSummaryRpt', '', 'OwnerYearlyDisbSummaryRpt')
         .AddBar('OwnerOneManRpt', '', 'OwnerOneManRpt')
         .AddSeparatorBar()
         .AddBar('OwnerJIBStmtRpt', '', 'OwnerJIBStmtRpt')
         .AddBar('OwnerJIBExpRpt', '', 'OwnerJIBExpRpt')
         .AddSeparatorBar()
         .AddBar('OwnerYTDITDRpt', '', 'OwnerYTDITDRpt')
         .AddBar('Owner1099ReconRpt', '', 'Owner1099ReconRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerListingRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner/Interest \<Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrolist.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports and not m.goapp.lhousegasreports and m.goapp.lafereports]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerLabelsRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner L\<abels]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrolab.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports and not m.goapp.lhousegasreports and m.goapp.lafereports]
ENDDEFINE


*===============================================================================
DEFINE CLASS OwnerDistStmtsRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Distribution \<Statements]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrownstmt.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerStubRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Stu\<b Statements]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrostub.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerDisbSummaryRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Disbursement Summary]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrodisb.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerYearlyDisbSummaryRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Yearly Disbursement Summary]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrodisbyr.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerOneManRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [One-\<Man Items Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmroneman.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerJIBStmtRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Joint Interest Billing Statements]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrojib.scx')]
   cSkipFor		= [not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerJIBExpRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Joint Interest Expenses by Ca\<tegory]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrojibrpt.scx','JE')]
   cSkipFor		= [not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS OwnerYTDITDRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Owner YTD and ITD Statements]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmroytd.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS Owner1099ReconRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner \<1099 Reconciliation]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99recon.scx')]
   cSkipFor		= [not m.goapp.lrevdistreports and not m.goapp.ljibreports]
ENDDEFINE

*===============================================================================
DEFINE CLASS ProgramReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<Program Reports]
   cPopupName	 = [ProgramReports]
   cSkipFor	 = [not m.goapp.lrevdistreports and not m.goapp.lpartnerreports and not m.goapp.lafereports and not m.goapp.ljibreports and not m.goapp.lInvestReports and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('ProgListingRpt', '', 'ProgListingRpt')
         .AddBar('ProgHistoryRpt', '', 'ProgHistoryRpt')
         .AddBar('ProgTotalsRpt', '', 'ProgTotalsRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ProgListingRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Program/Partnership \<Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrplist.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ProgHistoryRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Program/Partnership \<History]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrphist.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ProgTotalsRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Program/Partnership \<Totals]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrprogtot.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS SuspenseReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<Suspense Reports]
   cSkipFor	 = [not m.goapp.lrevdistreports]
   cOnClickCommand = [m.goStateManager.OpenForm('dmrsuspense.scx')]

ENDDEFINE

*===============================================================================
DEFINE CLASS LandReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<Land Reports]
   cPopupName	 = [LandReports]
   cSkipFor	 = [not m.goapp.lLandReports and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('LandRecords', '', 'LandRecords')
         .AddBar('DelayRentalRpt', '', 'DelayRentalRpt')
         .AddBar('DelayRentalDet', '', 'DelayRentalDet')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS LandRecords AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Land Records]
   cOnClickCommand	= [m.gostatemanager.openform('lmrland.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS DelayRentalRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Land Records]
   cOnClickCommand	= [m.gostatemanager.openform('lmrland.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS DelayRentalDet AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Delay \<Rental Check Detail]
   cOnClickCommand	= [m.gostatemanager.openform('lmrlandchk.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS AFEReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<AFE Reports]
   cPopupName	 = [AFEReports]
   cSkipFor	 = [not m.goapp.lAFEReports and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('AFERpt', '', 'AFERpt')
         .AddBar('AFEOwnPresRpt', '', 'AFEOwnPresRpt')
         .AddBar('AFEDetailRpt', '', 'AFEDetailRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS AFERpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<AFE Reports]
   cOnClickCommand	= [m.gostatemanager.openform('aferpt.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS AFEOwnPresRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [AFE \<Owner Presentation/Cash Call]
   cOnClickCommand	= [m.goStateManager.OpenForm('afeownrpt.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS AFEDetailRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [AFE \<Detail Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('afedetrpt.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS InvestmentReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<Investment Reports]
   cPopupName	 = [InvestmentReports]
   cSkipFor	 = [not m.goapp.lInvestReports and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('InvWellPayoutRpt', '', 'InvWellPayoutRpt')
         .AddBar('InvWellPayoutWellRpt', '', 'InvWellPayoutWellRpt')
         .AddBar('InvDepletionRpt', '', 'InvDepletionRpt')
         .AddBar('InvDiscRateReturnRpt', '', 'InvDiscRateReturnRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS InvWellPayoutRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well \<Payout by Owner Reports]
   cOnClickCommand	= [m.gostatemanager.openform('imrpayout.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS InvWellPayoutWellRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Well \<Payout by Well]
   cOnClickCommand	= [m.gostatemanager.openform('dmrpayout.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS InvDepletionRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Depletion Reports]
   cOnClickCommand	= [m.gostatemanager.openform('imrdepl.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS InvDiscRateReturnRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Discounted \<Rate of Return Report]
   cOnClickCommand	= [m.gostatemanager.openform('imrdiscrate.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS HouseGasReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<House Gas Reports]
   cPopupName	 = [HouseGasReports]
   cSkipFor	 = [NOT m.goapp.lhousegasopt or not m.goapp.lhousegasReports and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('HGOwnerUsageRpt', '', 'HGOwnerUsageRpt')
         .AddBar('HGUsageStmtRpt', '', 'HGUsageStmtRpt')
         .AddSeparatorBar()
         .AddBar('HGRouteRpt', '', 'HGRouteRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS HGOwnerUsageRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner \<Listing]
   cOnClickCommand	= [m.gostatemanager.openform('gasownlist.scx','OL')]
ENDDEFINE

*===============================================================================
DEFINE CLASS HGUsageStmtRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner \<Usage Statement]
   cOnClickCommand	= [m.gostatemanager.openform('gasusestmt.scx','OS')]
ENDDEFINE


*===============================================================================
DEFINE CLASS HGRouteRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Route Report]
   cOnClickCommand	= [m.gostatemanager.openform('gasrouterpt.scx','OR')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PluggingReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Plu\<gging Reports]
   cPopupName	 = [PluggingReports]
   cSkipFor	 = [not m.goapp.lPluggingModule]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('PlugTargetsRpt', '', 'PlugTargetsRpt')
         .AddBar('PlugFundsRpt', '', 'PlugFundsRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS PlugTargetsRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Plugging Targets]
   cOnClickCommand	= [m.goStateManager.OpenForm('plugreports.scx','TARGET')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PlugFundsRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Plugging Funds]
   cOnClickCommand	= [m.goStateManager.OpenForm('plugreports.scx','FUND')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Process1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<1099 Processing\Printing]
   cPopupName	 = [Processing1099s]
   cSkipFor	 = [(NOT m.goApp.lTaxIds or not m.goapp.lRevDistReports) and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('View1099Tutorial', '', 'View1099Tutorial')
         .AddBar('StatePayerSetup', '', 'StatePayerSetup')
         .AddBar('TaxIDList', '', 'TaxIDList')
         .AddSeparatorBar()
         .AddBar('Create1099s', '', 'Create1099s')
         .AddBar('Update1099s', '', 'Update1099s')
         .AddBar('Update1099Det', '', 'Update1099Det')
         .AddBar('Update1099State', '', 'Update1099State')
         .AddSeparatorBar()
         .AddBar('Ten99Summary', '', 'Ten99Summary')
         .AddBar('State1099Summary', '', 'State1099Summary')
         .AddSeparatorBar()
         .AddBar('Ten99Misc', '', 'Ten99Misc')
         .AddBar('State1099Misc', '', 'State1099Misc')
         .AddSeparatorBar()
         .AddBar('Owner1099Rec', '', 'Owner1099Rec')
         .AddSeparatorBar()
         .AddBar('Print1099s', '', 'Print1099s')
         .AddBar('PrintState1099s', '', 'PrintState1099s')
         .AddSeparatorBar()
         .AddBar('MagMedia1099s', '', 'MagMedia1099s')
         .AddBar('StateMagMedia1099s', '', 'StateMagMedia1099s')
         .AddSeparatorBar()
         .AddBar('Submit1099s', '', 'Submit1099s')
         .AddBar('Check1099Status', '', 'Check1099Status')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS View1099Tutorial AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<View 1099 Tutorials]

   PROCEDURE CLICK
      oLink = CREATEOBJECT('hyperlink')
      oLink.NAVIGATETO('support.sherware.com/1099Tutorials.html')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS StatePayerSetup AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State Payer No Setup]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99states.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS TaxIDList AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Ta\<x ID List]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrtaxidlist.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Create1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Create 1099 File]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99create.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Update1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Update 1099 File]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99upd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Update1099Det AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Update 1099 Detail File]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99detupd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Update1099State AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Up\<date State 1099 File]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99updst.scx')]
ENDDEFINE

*=============================================================================
DEFINE CLASS Ten99Summary AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [1099 \<Summary]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99summ.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS State1099Summary AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State 1099 Summar\<y]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99summst.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Ten99Misc AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [1099-Misc \<Replacement]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99misc.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS State1099Misc AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State \<1099-Misc Replacement]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99miscst.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Owner1099Rec AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Owner 1099 Reconciliation]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99recon.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Print1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Print 1099s]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99print.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PrintState1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Pr\<int State 1099s]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99printst.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS MagMedia1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Magnetic Media 1099s]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99Mag.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS StateMagMedia1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State Ma\<gnetic Media 1099 File]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99Magst.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Submit1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [SherWare 1099 Web Reporting/Submission]
   cOnClickCommand	= [m.goStateManager.OpenForm('ten99submission.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Check1099Status AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Check 1099 Filing Status]

   PROCEDURE CLICK
      oLink = CREATEOBJECT('hyperlink')
      oLink.NAVIGATETO('https://sherware.nelcoportal.com/Account/Logon')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS Process1065s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [1065 and \<K1 Processing]
   cPopupName	 = [Processing1065s]
   cSkipFor	 = [NOT m.goApp.lK1Opt OR not m.goapp.lform1065reporting and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('Form1065FormatDownload', '', 'Form1065FormatDownload')
         .AddSeparatorBar()
         .AddBar('Form1065Create', '', 'Form1065Create')
         .AddSeparatorBar()
         .AddBar('Form1065Modify', '', 'Form1065Modify')
         .AddBar('Form1065DedModify', '', 'Form1065DedModify')
         .AddBar('Form1065K1Modify', '', 'Form1065K1Modify')
         .AddBar('Form1065K1DedModify', '', 'Form1065K1DedModify')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS Form1065FormatDownload AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Download 1065/K1 Report Formats]

   PROCEDURE CLICK
      lcYear = TRANSFORM(YEAR(DATE()))
      lnMonth		   = MONTH(DATE())
      lcYearLast	   = TRANSFORM(VAL(lcYear) - 1)
      IF MESSAGEBOX('Download 1065/K1 formats for ' + lcYearLast + '? Answer NO to download formats for the current year.', 36, 'Download 1065 Formats') = 6
         DO form1065_k1_upd WITH lcYearLast
      ELSE
         DO form1065_k1_upd WITH lcYear
      ENDIF


   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS Form1065Create AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Create 1065 and K1 Files]
   cOnClickCommand	= [m.goStateManager.OpenForm('dm1065create.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Form1065Modify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Modify 1065 File]
   cOnClickCommand	= [m.goStateManager.OpenForm('dm1065upd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Form1065DedModify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify 1065 Deductions]
   cOnClickCommand	= [m.gostatemanager.openform('dm1065dedupd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Form1065K1Modify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify \<K1 File]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmk1upd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS Form1065K1DedModify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify K1 \<Deductions]
   cOnClickCommand	= [m.gostatemanager.openform('dmk1dedupd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS TaxReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Ta\<x Reports]
   cPopupName	 = [TaxReports]
   cSkipFor	 = [not m.goapp.lRevDistReports and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('SevTaxReports', '', 'SevTaxReports')
         .AddBar('BackupTaxReports', '', 'BackupTaxReports')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS SevTaxReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Severance / Production Tax Reports]
   cOnClickCommand	= [m.gostatemanager.openform('dmrtaxes.scx']
ENDDEFINE

*===============================================================================
DEFINE CLASS BackupTaxReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Backup/Tax \<Withholding]
   cOnClickCommand	= [m.gostatemanager.openform('dmrtaxes1.scx']
ENDDEFINE

*===============================================================================
DEFINE CLASS StateComplianceReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [State Co\<mpliance Reports]
   cPopupName	 = [StateComplianceReports]
   cSkipFor	 = [m.goapp.lDemo or not m.goapp.lRevDistReports and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('CO_Reports', '', 'CO_Reports')
         .AddBar('NY_Reports', '', 'NY_Reports')
         .AddBar('OH_Reports', '', 'OH_Reports')
         .AddBar('PA_Reports', '', 'PA_Reports')
         .AddBar('TX_Reports', '', 'TX_Reports')
         .AddBar('WV_Reports', '', 'WV_Reports')
         .AddBar('WY_Reports', '', 'WY_Reports')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS CO_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Colorado Reports]
   cSkipFor = [NOT m.goApp.lCORpts]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('COStateAcctNumber', '', 'COStateAcctNumber')
         .AddBar('CODR0461Create', '', 'CODR0461Create')
         .AddBar('CODR0461Modify', '', 'CODR0461Modify')
         .AddBar('CODR0461Print', '', 'CODR0461Print')
         .AddSeparatorBar()
         .AddBar('CODR0021WCreate', '', 'CODR0021WCreate')
         .AddBar('CODR0021WModify', '', 'CODR0021WModify')
         .AddBar('CODR0021WPrint', '', 'CODR0021WPrint')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS COStateAcctNumber AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State Account Number]
   cOnClickCommand	= [m.gostatemanager.openform('stateaccounts.scx','CO')]
ENDDEFINE

*===============================================================================
DEFINE CLASS CODR0461Create AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Create Monthly Severance Tax File (DR0461)]

   PROCEDURE CLICK
      getstateformats('CO', .T.)

      DO (m.goapp.cRptsFolder + 'StateReports\CO\costatereports') WITH m.goapp, 'codr0461.scx', 'CO'
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS CODR0461Modify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Modify Monthly Severance Tax File]

   PROCEDURE CLICK
      getstateformats('CO', .T.)
      DO (m.goapp.cRptsFolder + 'StateReports\CO\costatereports') WITH m.goapp, 'codr0461upd.scx', 'CO'

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS CODR0461Print AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Print Monthly Severance Tax Rpt (DR0461)]

   PROCEDURE CLICK
      getstateformats('CO', .T.)
      DO (m.goapp.cRptsFolder + 'StateReports\CO\costatereports') WITH m.goapp, 'codr0461rpt.scx', 'CO'

   ENDPROC
ENDDEFINE


*===============================================================================
DEFINE CLASS CODR0021WCreate AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Create \<DR0021W & DR0456 Files]

   PROCEDURE CLICK
      getstateformats('CO', .T.)
      DO (m.goapp.cRptsFolder + 'StateReports\CO\costatereports') WITH m.goapp, 'codr0021w.scx', 'CO'

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS CODR0021WModify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Modify DR0021W Records]

   PROCEDURE CLICK
      getstateformats('CO', .T.)
      DO (m.goapp.cRptsFolder + 'StateReports\CO\costatereports') WITH m.goapp, 'codr0021wupd.scx', 'CO'

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS CODR0021WPrint AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Print DR0021W Report]

   PROCEDURE CLICK
      getstateformats('CO', .T.)
      DO (m.goapp.cRptsFolder + 'StateReports\CO\costatereports') WITH m.goapp, 'codr0021wrpt.scx', 'CO'

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS _5QP182JJ3Bar10 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Modify DR0456 Records]

   PROCEDURE CLICK
      getstateformats('CO', .T.)
      DO (m.goapp.cRptsFolder + 'StateReports\CO\costatereports') WITH m.goapp, 'codr0456upd.scx', 'CO'

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS _5QP182JJ3Bar11 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Print DR0456 Report]

   PROCEDURE CLICK
      getstateformats('CO', .T.)
      DO (m.goapp.cRptsFolder + 'StateReports\CO\costatereports') WITH m.goapp, 'codr0456rpt.scx', 'CO'

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS NY_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<New York Reports]
   cSkipFor = [NOT m.goApp.lNYRpts]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('NYStateAcctNumber', '', 'NYStateAcctNumber')
         .AddSeparatorBar()
         .AddBar('NYAnnualProdCreate', '', 'NYAnnualProdCreate')
         .AddBar('NYAnnualProdModify', '', 'NYAnnualProdModify')
         .AddBar('NYAnnualProdPrint', '', 'NYAnnualProdPrint')
         .AddBar('NYAnnualProdMag', '', 'NYAnnualProdMag')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS NYStateAcctNumber AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State Account Number]
   cOnClickCommand	= [m.gostatemanager.openform('stateaccounts.scx','NY')]
ENDDEFINE

*===============================================================================
DEFINE CLASS NYAnnualProdCreate AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Create Annual File]

   PROCEDURE CLICK
      getstateformats('NY', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\NY\NYAnnualProdCreate.scx', 'NY')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS NYAnnualProdModify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Modify Annual File]

   PROCEDURE CLICK
      getstateformats('NY', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\NY\NYAnnualProdUpd.scx', 'NY')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS NYAnnualProdPrint AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Print Annual Report]

   PROCEDURE CLICK
      getstateformats('NY', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\NY\NYAnnualProdPrint.scx', 'NY')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS NYAnnualProdMag AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Magnetic \<Annual Production File]

   PROCEDURE CLICK
      getstateformats('NY', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\NY\NYAnnualProdMag.scx', 'NY')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OH_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Ohio Reports]
   cSkipFor = [NOT m.goApp.lOHRpts]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('OHStateAcctNumber', '', 'OHStateAcctNumber')
         .AddSeparatorBar()
         .AddBar('OHForm10Create', '', 'OHForm10Create')
         .AddBar('OHForm10Modify', '', 'OHForm10Modify')
         .AddBar('OHForm10Summary', '', 'OHForm10Summary')
         .AddBar('OHForm10Print', '', 'OHForm10Print')
         .AddBar('OHForm10Mag', '', 'OHForm10Mag')
         .AddSeparatorBar()
         .AddBar('OHFormSV3', '', 'OHFormSV3')
         .AddBar('OHFormSV3Remove', '', 'OHFormSV3Remove')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OHStateAcctNumber AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State Account]
   cOnClickCommand	= [m.gostatemanager.openform('stateaccounts.scx','OH')]
ENDDEFINE


*===============================================================================
DEFINE CLASS OHForm10Create AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Create Form 10 File]

   PROCEDURE CLICK
      getstateformats('OH', .T.)

      DO (m.goapp.cRptsFolder + 'StateReports\OH\OHStateReports') WITH m.goapp, 'OHForm10Create.scx', 'OH'

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OHForm10Modify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Modify Form 10 File]

   PROCEDURE CLICK
      getstateformats('OH', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\OH\OHForm10Upd.scx', 'OH')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OHForm10Summary AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Form 10 \<Summary]

   PROCEDURE CLICK
      getstateformats('OH', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\OH\OHForm10Summary.scx')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OHForm10Print AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Print Form 10 Report]

   PROCEDURE CLICK
      getstateformats('OH', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\OH\OHForm10Rpt.scx', 'OH')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OHForm10Mag AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Form 10 Ma\<gnetic File]

   PROCEDURE CLICK
      getstateformats('OH', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\OH\OHForm10Mag.scx', 'OH')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OHFormSV3 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Print Form SV3 & SV3A]

   PROCEDURE CLICK
      getstateformats('OH', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\OH\OHSV3.scx')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OHFormSV3Remove AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Remove Cost Recovery Adjustments]
   cOnClickCommand	= [do ohsv3remove]
ENDDEFINE


*===============================================================================
DEFINE CLASS PA_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<Pennsylvania  Reports]
   cPopupName	 = [PA_Reports]
   cSkipFor	 = [NOT m.goApp.lPARpts]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('PAStateAcctNumber', '', 'PAStateAcctNumber')
         .AddSeparatorBar()
         .AddBar('PAAnnualProdCreate', '', 'PAAnnualProdCreate')
         .AddBar('PAAnnualProdModify', '', 'PAAnnualProdModify')
         .AddBar('PAAnnualProdPrint', '', 'PAAnnualProdPrint')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS PAStateAcctNumber AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State Account Setup]
   cOnClickCommand	= [m.gostatemanager.openform('stateaccounts.scx','PA')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PAAnnualProdCreate AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Create Annual File]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmannprod.scx','PA')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PAAnnualProdModify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Modify Annual File]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmannprodupd.scx','PA')]
ENDDEFINE

*===============================================================================
DEFINE CLASS PAAnnualProdPrint AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Print Annual Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmannprodrpt.scx','PA')]
ENDDEFINE

*===============================================================================
DEFINE CLASS TX_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<Texas Reports]
   cPopupName	 = [TexasRepor]
   cSkipFor	 = [NOT m.goApp.lTXRpts]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('TXStateAcctNumber', '', 'TXStateAcctNumber')
         .AddSeparatorBar()
         .AddBar('TXPRFileCreate', '', 'TXPRFileCreate')
         .AddBar('TXPRFileModify', '', 'TXPRFileModify')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS TXStateAcctNumber AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State Account Setup]
   cOnClickCommand	= [m.gostatemanager.openform('stateaccounts.scx','TX')]
ENDDEFINE

*===============================================================================
DEFINE CLASS TXPRFileCreate AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Build PR File]

   PROCEDURE CLICK
      getstateformats('TX', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\TX\TXPRCreate.scx')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS TXPRFileModify AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Modify PR File]

   PROCEDURE CLICK
      getstateformats('TX', .T.)
      m.goStateManager.openform(m.goapp.cRptsFolder + 'StateReports\TX\TXPRUpd.scx')
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS WV_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<West Virginia Reports]
   cPopupName	 = [WV_Reports]
   cSkipFor	 = [NOT m.goApp.lWVRpts]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('WVStateAcctNumber', '', 'WVStateAcctNumber')
         .AddSeparatorBar()
         .AddBar('WVOperReturnCreate', '', 'WVOperReturnCreate')
         .AddBar('WVOperReturnModify1', '', 'WVOperReturnModify1')
         .AddBar('WVOperReturnModify2', '', 'WVOperReturnModify2')
         .AddBar('WVOperReturnPrint', '', 'WVOperReturnPrint')
         .AddBar('WVNotaryPrint', '', 'WVNotaryPrint')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS WVStateAcctNumber AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State Account Setup]
   cOnClickCommand	= [m.gostatemanager.openform('stateaccounts.scx','WV')]
ENDDEFINE

*===============================================================================
DEFINE CLASS WVOperReturnCreate AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Create Producer/Operator Return]
ENDDEFINE

*===============================================================================
DEFINE CLASS WVOperReturnModify1 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Modify Producer/Operator Return (Sch 2)]
ENDDEFINE

*===============================================================================
DEFINE CLASS WVOperReturnModify2 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Modify Producer/Operator Return (Sch3)]
ENDDEFINE

*===============================================================================
DEFINE CLASS WVOperReturnPrint AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Print Producer/Operator Return]

   PROCEDURE CLICK
      getstateformats('WV', .T.)
      m.goStateManager.openform('WVAnnualRetPrint.scx', 'WV')

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS WVNotaryPrint AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Print \<Notary Page]

   PROCEDURE CLICK
      LOCAL loError, llReturn

      llReturn = .T.

      TRY
         llReturn = GetWVFormats()
         CREATE CURSOR temp (junk c(1))
         junk = 'a'
         INSERT INTO temp FROM MEMVAR
         REPORT FORM (m.goapp.cRptsFolder + 'StateReports\WV\WV_Notary.frx') TO PRINTER PROMPT PREVIEW NOCONSOLE NOEJECT
      CATCH TO loError
         MESSAGEBOX('Error sending the report to the printer!' + CHR(10) + ;
            loError.MESSAGE, 64, 'Error Printing')
      ENDTRY
   ENDPROC
ENDDEFINE


*===============================================================================
DEFINE CLASS WY_Reports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [W\<yoming Reports]
   cPopupName	 = [WY_Reports]
   cSkipFor	 = [NOT m.goApp.lWYRpts]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('WYStateAcctNumber', '', 'WYStateAcctNumber')
         .AddSeparatorBar()
         .AddBar('WYConservationRpt', '', 'WYConservationRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS WYStateAcctNumber AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [State Account Setup]
   cOnClickCommand	= [m.gostatemanager.openform('stateaccounts.scx','WY')]
ENDDEFINE

*===============================================================================
DEFINE CLASS WYConservationRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Conservation Tax Report]
ENDDEFINE

*===============================================================================
DEFINE CLASS Graphing AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Graphing]
   cPopupName	 = [Graphing]
   cSkipFor	 = [not m.goapp.lRevDistReports]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('ProductionGraphs', '', 'ProductionGraphs')
         .AddBar('RevExpGraphs', '', 'RevExpGraphs')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ProductionGraphs AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Production Graphs]
   cOnClickCommand	= [m.gostatemanager.openform('dmgraphprod.scx']
ENDDEFINE

*===============================================================================
DEFINE CLASS RevExpGraphs AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Revenue/Expense Graphs]
   cOnClickCommand	= [m.gostatemanager.openform('dmgraphwell.scx']
ENDDEFINE

*===============================================================================
DEFINE CLASS OtherReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [O\<ther Reports]
   cPopupName	 = [OtherReports]
   cSkipFor	 = [not m.goapp.lRevDistReports and not m.goapp.lJIBReports  and not m.goapp.lAdmin]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('OthExpCodeRpt', '', 'OthExpCodeRpt')
         .AddBar('OthRevCodeRpt', '', 'OthRevCodeRpt')
         .AddBar('OthPreferencerpt', '', 'OthPreferencerpt')
         .AddBar('OthMeterRpt', '', 'OthMeterRpt')
         .AddBar('OthPumperRpt', '', 'OthPumperRpt')
         .AddBar('OthPurchaserRpt', '', 'OthPurchaserRpt')
         .AddSeparatorBar()
         .AddBar('OthClosedRunRpt', '', 'OthClosedRunRpt')
         .AddBar('OthRevCloseRpt', '', 'OthRevCloseRpt')
         .AddBar('OthJIBCloseRpt', '', 'OthJIBCloseRpt')
         .AddBar('OthDirDepRpt', '', 'OthDirDepRpt')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OthExpCodeRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Expense Code Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrexplist.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS OthRevCodeRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Re\<venue Category Listing]
   cOnClickCommand	= [Revcat_Report()]
ENDDEFINE

*===============================================================================
DEFINE CLASS OthPreferencerpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Preferences Listing]
   cOnClickCommand	= [Prefs_Report()]
ENDDEFINE

*===============================================================================
DEFINE CLASS OthMeterRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Meter Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrmlist.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS OthPumperRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Pumper Listing]
   cOnClickCommand	= [Pumpers_Report()]
ENDDEFINE

*===============================================================================
DEFINE CLASS OthPurchaserRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [P\<urchaser Listing]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrrevsrc.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS OthClosedRunRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Closed Run Listing]
   cOnClickCommand	= [ClosedRun_Report()]
ENDDEFINE

*===============================================================================
DEFINE CLASS OthRevCloseRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Revenue Run Closing Summary]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrrevclose.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS OthJIBCloseRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<JIB Run Closing Summary]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrjibclose.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS OthDirDepRpt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Direct Deposit Entries Report]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmrrevclose.scx',.t.)]
ENDDEFINE

*===============================================================================
DEFINE CLASS CustomReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Custom Reports]
   cPopupName	 = [CustomReports]

ENDDEFINE

*===============================================================================
DEFINE CLASS AdvancedReporting AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption	 = [Advanced Reporting]
   cPopupName	 = [AdvancedReporting]
   cSkipFor	 = [not m.goapp.lAdhocReporting and not m.goapp.lAdmin]

   PROCEDURE CLICK
      IF FILE(m.goapp.cQueryFolder+'sfquery.exe')
         lcCmd = m.goapp.cQueryFolder+[sfquery.exe ] + ["database=] + m.goapp.cIDComp + ["]
         !/n1 &lcCmd
      ENDIF
   ENDPROC
ENDDEFINE
*===============================================================================
DEFINE CLASS Utilities AS SFPad OF SFMenu.vcx
*===============================================================================
   cCaption	 = [\<Utilities]
   cPopupName	 = [Utilities]
   cSkipFor	 = [not m.goapp.lopencompany or m.goApp.lExpired or m.goApp.lReadOnly]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('UTReindex', '', 'UTReindex')
         .AddBar('UTUpdateFiles', '', 'UTUpdateFiles')
         .AddBar('UTResetRemind', '', 'UTResetRemind')

         .AddSeparatorBar()
         .AddBar('CheckSetup', '', 'CheckSetup')
         .AddSeparatorBar()

         .AddBar('ModifyReports', '', 'ModifyReports')
         .AddSeparatorBar()

         .AddBar('Ten99Setup', '', 'Ten99Setup')
         .AddBar('DownloadOwnStmts', '', 'DownloadOwnStmts')
         .AddBar('Download1065K1', '', 'Download1065K1')

         IF m.goapp.lAMVersion
            .AddSeparatorBar()
            .AddBar('OpenFiscalPeriod', '', 'OpenFiscalPeriod')
         ENDIF

         .AddSeparatorBar()
         .AddBar('OpenRevRun', '', 'OpenRevRun')
         .AddBar('OpenJIBRun', '', 'OpenJIBRun')

         .AddSeparatorBar()
         .AddBar('DOIUtilities', '', 'DOIUtilities')

         .AddSeparatorBar()
         .AddBar('BackoutFixed', '', 'BackoutFixed')
         .AddBar('BackoutPlugging', '', 'BackoutPlugging')
         .AddBar('RecalcYTDITD', '', 'RecalcYTDITD')
         .AddBar('BuildInvHist', '', 'BuildInvHist')
         .AddBar('ExportOwnStmts', '', 'ExportOwnStmts')

         .AddSeparatorBar()
         .AddBar('ClearOwnerSusp', '', 'ClearOwnerSusp')
         .AddBar('SwitchProdPeriod', '', 'SwitchProdPeriod')
         .AddBar('SwitchTaxWH', '', 'SwitchTaxWH')
         .AddBar('FileCopy', '', 'FileCopy')
         .AddBar('ResetLeasePmts', '', 'ResetLeasePmts')

         IF m.goapp.lDirDMDep
            .AddSeparatorBar()
            .AddBar('CreateACHFile', '', 'CreateACHFile')
         ENDIF

         IF NOT m.goapp.lQBVersion AND m.goapp.lCashData
            .AddSeparatorBar()
            .AddBar('ChangeReconDates', '', 'ChangeReconDates')
            .AddBar('DeleteRecon', '', 'DeleteRecon')
         ENDIF

         .AddSeparatorBar()

         IF m.goapp.lOffBackup AND m.goapp.loffsitebackup
            .AddBar('ManageOffsite', '', 'ManageOffsite')
         ENDIF

         IF m.goapp.lOnlineReports AND m.goapp.lOnlinereporting
            .AddBar('OnlineRptsUpload', '', 'OnlineRptsUpload')
         ENDIF

         .AddBar('EnergyLink', '', 'EnergyLink')

         .AddSeparatorBar()
         .AddBar('SpecialUtilities', '', 'SpecialUtilities')

      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS UTReindex AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Re-Inde\<x Files]

   PROCEDURE CLICK
      LOCAL oMeta, llUseOK

      IF swOpenForms()
         MESSAGEBOX('All forms must be closed before reindexing the files.', 16, 'Reindex Error')
         RETURN
      ENDIF

      llUseOK	   = .T.
      lcDataBase = TRIM(m.goapp.cDataFilePath) + 'AppData'

      swselect('disbhist')

      llUseOK = FLOCK('Disbhist')

      UNLOCK IN disbhist

      CLOSE DATABASES ALL

      IF llUseOK
         OPEN DATABASE (lcDataBase)
         oMeta = NEWOBJECT('DBCXMgr', 'DBCXMGR.VCX', '', .F. )
         IF TYPE('oMeta') <> 'O' OR ISNULL(oMeta)
* Display error message and exit, because DBCX cannot be used.
            MESSAGEBOX('The DBCX is not available', 16, 'Error Loading DBCX')
            RETURN .F.
         ENDIF

         oMeta.SetDatabase(DBC())

         oMeta.oSDTMgr.REINDEX()

         RELE oMeta
      ELSE
         MESSAGEBOX("This company's files are in use by another user.  Have everyone logout and try again...")
      ENDIF
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS UTUpdateFiles AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Update Files]

   PROCEDURE CLICK
      IF swOpenForms()
         MESSAGEBOX('All open forms must be closed before updating the files.', 16, 'Close All Forms')
         RETURN
      ENDIF

      DO swUpdate
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS UTResetRemind AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Reset Automatic Update Reminder]

   PROCEDURE CLICK
      m.goapp.resetremind()
      WAIT WINDOW NOWAIT "Reset of automatic update reminder complete"
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS CheckSetup AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Chec\<k Setup]

   PROCEDURE AddBars
      WITH THIS
         IF m.goapp.lAMVersion OR m.goapp.lDMVersion
            .AddBar('APCheckSetup', '', 'APCheckSetup')

            IF m.goapp.lPayrollOpt
               .AddBar('PRCheckSetup', '', 'PRCheckSetup')
            ENDIF
         ENDIF

         .AddBar('DMCheckSetup', '', 'DMCheckSetup')

         IF m.goapp.lLandOpt
            .AddBar('LMCheckSetup', '', 'LMCheckSetup')
         ENDIF
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS DMCheckSetup AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Revenue Distribution Check]
   cOnClickCommand	= [do modicheck with 'DM']
ENDDEFINE

*===============================================================================
DEFINE CLASS APCheckSetup AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Vendor Check]
   cOnClickCommand	= [do modicheck with 'AP']
ENDDEFINE

*===============================================================================
DEFINE CLASS LMCheckSetup AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Delay Rental Check]
   cOnClickCommand	= [do modicheck with 'LM']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModifyReports AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [M\<odify Reports]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('ModOwnerStmts', '', 'ModOwnerStmts')
         .AddBar('ModLabels', '', 'ModLabels')
         .AddBar('ModStubStmt', '', 'ModStubStmt')

         IF m.goapp.lAFEopt
            .AddBar('ModAFEOwner', '', 'ModAFEOwner')
         ENDIF

         IF m.goapp.lAMVersion
            .AddBar('CustomerStmts', '', 'CustomerStmts')
         ENDIF

         .AddBar('DivOrder', '', 'DivOrder')
         .AddBar('DivOrder1Page', '', 'DivOrder1Page')

         IF m.goapp.lPayrollOpt
            .AddBar('W2Setup', '', 'W2Setup')
         ENDIF
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ModOwnerStmts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Modify Owner \<Statements]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('ModStmt1', '', 'ModStmt1')
         .AddBar('ModStmt2', '', 'ModStmt2')
         .AddBar('ModStmt3', '', 'ModStmt3')
         .AddBar('ModStmt4', '', 'ModStmt4')
         .AddBar('ModStmt5', '', 'ModStmt5')
         .AddBar('ModStmt6', '', 'ModStmt6')
         .AddBar('ModStmt7', '', 'ModStmt7')
         .AddBar('ModStmt8', '', 'ModStmt8')
         .AddSeparatorBar()
         .AddBar('ModJIBStmt1', '', 'ModJIBStmt1')
         .AddBar('ModJIBStmt2', '', 'ModJIBStmt2')
         .AddBar('ModJIBStmt3', '', 'ModJIBStmt3')
         .AddBar('ModJIBStmt4', '', 'ModJIBStmt4')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ModStmt1 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Statements (Standard)]
   cOnClickCommand	= [DO modirepo WITH 'OSTMT1']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModStmt2 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Statements (Standard)(Duplex)]
   cOnClickCommand	= [DO modirepo WITH 'OSTMT2']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModStmt3 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Statements (Standard Tax Code Subtotal)]
   cOnClickCommand	= [DO modirepo WITH 'OSTMT3']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModStmt4 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Statements (Standard Tax Code Subtotal)(Duplex)]
   cOnClickCommand	= [DO modirepo WITH 'OSTMT4']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModStmt5 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Statements (Compressed Standard)]
   cOnClickCommand	= [DO modirepo WITH 'OSTMT5']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModStmt6 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Statements (Compressed Standard)(Duplex)]
   cOnClickCommand	= [DO modirepo WITH 'OSTMT6']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModStmt7 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Statements (Compressed Tax Code Subtotal)]
   cOnClickCommand	= [DO modirepo WITH 'OSTMT7']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModStmt8 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Owner Statements (Compressed Tax Code Subtotal)(Duplex)]
   cOnClickCommand	= [DO modirepo WITH 'OSTMT8']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModJIBStmt1 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify Owner \<JIB Statement]
   cOnClickCommand	= [DO MODIREPO WITH 'JIBRUN']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModJIBStmt2 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify Owner JIB Statement (2nd Sort)]
   cOnClickCommand	= [DO modirepo with 'JIBSORT']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModJIBStmt3 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify Owner JIB Summary By Well]
   cOnClickCommand	= [DO modirepo with 'JIBSUM']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModJIBStmt4 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify Owner JIB Summary By Category]
   cOnClickCommand	= [DO modirepo with 'JIBCAT']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModLabels AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Modify Owner Labels]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('ModDotMatrix', '', 'ModDotMatrix')
         .AddBar('ModLaser', '', 'ModLaser')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ModDotMatrix AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Dot-Matrix Labels]
   cOnClickCommand	= [DO modirepo WITH 'OWNLABD']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModLaser AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Laser Labels]
   cOnClickCommand	= [DO modirepo WITH 'OWNLABL']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModStubStmt AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify Owner Stu\<b Statement]
   cOnClickCommand	= [DO MODIREPO WITH 'OWNSTUB']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModAFEOwner AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify \<AFE Owner Presentation]
   cOnClickCommand	= [DO modirepo with 'AFEOWNRPT1']
ENDDEFINE

*===============================================================================
DEFINE CLASS CustomerStmts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Customer Statements]
   cOnClickCommand	= [do modirepo with 'CUSTSTMT']
ENDDEFINE

*===============================================================================
DEFINE CLASS DivOrder AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Division Order]
   cOnClickCommand	= [do modirepo with 'DIVORDM']
ENDDEFINE

*===============================================================================
DEFINE CLASS DivOrder1Page AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Division Order (1 Int per Page)]
   cOnClickCommand	= [do modirepo with 'DIVORDS']
ENDDEFINE

*===============================================================================
DEFINE CLASS W2Setup AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<W2 Setup]
   cOnClickCommand	= [do modirepo with 'W2']
ENDDEFINE

*===============================================================================
DEFINE CLASS UnPostFromQB AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Remove Revenue Run From \<QuickBooks]
   cOnClickCommand	= [m.gostatemanager.openform('dmunqbpostr.scx')]
   cSkipFor		= [not m.goapp.oQB.lqbactive]
ENDDEFINE

*===============================================================================
DEFINE CLASS BackoutPlugging AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Back Out \<Plugging Charges]
   cOnClickCommand	= [m.gostatemanager.openform('pluggingback.scx')]
   cSkipFor		= [not m.goapp.lPluggingModule]
ENDDEFINE

*===============================================================================
DEFINE CLASS DownloadOwnStmts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Download Owner Statement Formats]
   cOnClickCommand	= [GetOwnerStmts()]
ENDDEFINE

*===============================================================================
DEFINE CLASS Ten99Setup AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<1099 Setup]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('Download1099s', '', 'Download1099s')
         .AddBar('Modify1099s', '', 'Modify1099s')
         .AddSeparatorBar()
         .AddBar('ModifyMisc1099Repl', '', 'ModifyMisc1099Repl')
         .AddBar('ModifyMisc1099ReplW', '', 'ModifyMisc1099ReplW')
         .AddBar('ToggleStatePayer', '', 'ToggleStatePayer')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS Download1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Download New 1099 Formats]

   PROCEDURE CLICK
      lcYear = TRANSFORM(YEAR(DATE()))
      lnMonth		   = MONTH(DATE())

      IF lnMonth < 6
         lcYear = TRANSFORM(VAL(lcYear) - 1)
      ENDIF

      DO form1099_upd WITH lcYear, .T.
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS Modify1099s AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify \<1099 Format]
   cOnClickCommand	= [DO MODIREPO WITH 'TENLAS']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModifyMisc1099Repl AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Modify 1099-Misc Replacement]
   cOnClickCommand	= [do modirepo with '1099misc']
ENDDEFINE

*===============================================================================
DEFINE CLASS ModifyMisc1099ReplW AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Modify 1099-Misc Replacement by \<Well]
   cOnClickCommand	= [do modirepo with '1099miscw']
ENDDEFINE

*===============================================================================
DEFINE CLASS ToggleStatePayer AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Toggle State Payer Usage for 1099s]

   PROCEDURE CLICK
      IF FILE('datafiles\t9ignorestate.txt')
         ERASE ('datafiles\t9ignorestate.txt')
         MESSAGEBOX('State Payer Codes will be used now.', 0, 'State Payer Codes (1099s)')
      ELSE
         STRTOFILE('x', 'datafiles\t9ignorestate.txt')
         MESSAGEBOX('State Payer Codes will NOT be used now.', 0, 'State Payer Codes (1099s)')
      ENDIF

   ENDPROC

ENDDEFINE

*===============================================================================
DEFINE CLASS Download1065k1 AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Download 1065/K1 Formats]
   cSkipFor = [NOT m.goApp.lK1Opt OR not m.goapp.lform1065reporting and not m.goapp.lAdmin]

   PROCEDURE CLICK
      lcYear = TRANSFORM(YEAR(DATE()))
      lnMonth		   = MONTH(DATE())
      lcYearLast	   = TRANSFORM(VAL(lcYear) - 1)
      IF MESSAGEBOX('Download 1065/K1 formats for ' + lcYearLast + '? Answer NO to download formats for the current year.', 36, 'Download 1065 Formats') = 6
         DO form1065_k1_upd WITH lcYearLast
      ELSE
         DO form1065_k1_upd WITH lcYear
      ENDIF

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS OpenRevRun AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Open a Closed \<Revenue Run]
   cOnClickCommand	= [m.gostatemanager.openform('dmreopenr.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS OpenJIBRun AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Open a Closed \<JIB Run]
   cOnClickCommand	= [m.gostatemanager.openform('dmreopenj.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS BackoutFixed AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Back Out Fixed Expenses]
   cOnClickCommand	= [m.gostatemanager.openform('dmfixback.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS DOIUtilities AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Division of Interest Utilities]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('CheckDOI', '', 'CheckDOI')
         .AddBar('CopyDOI', '', 'CopyDOI')
         .AddBar('TransferDOI', '', 'TransferDOI')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS CheckDOI AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Check Division of Interest]
   cOnClickCommand	= [m.goStateManager.openform('dmcheckdoi.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS CopyDOI AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Co\<py Division of Interest]
   cOnClickCommand	= [m.goStateManager.OpenForm('dmdoicopy.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS TransferDOI AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Transfer DOI Between Owners]
   cOnClickCommand	= [m.gostatemanager.openform('dmdoitransfer.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS RecalcYTDITD AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Recalculate \<YTD and ITD Totals]

   PROCEDURE CLICK
      LOCAL ldDate

      oMessage = FindGlobalObject('cmMessage')

      IF oMessage.CONFIRM('Should last year be used for YTD totals?')
         ldDate = CTOD('01/01/' + TRANSFORM(YEAR(DATE()))) - 1
      ELSE
         ldDate = DATE()
      ENDIF

      DO calcytditd WITH ldDate, '**', .T.

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS BuildInvHist AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Build \<History for Investment Wells]
   cOnClickCommand	= [m.gostatemanager.openform('dmbldinvhist.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ExportOwnStmts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Export Owner Statements]
   cOnClickCommand	= [m.gostatemanager.openform('dmexportstmt.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ClearOwnerSusp AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Clear Owner Suspense]
   cOnClickCommand	= [m.gostatemanager.openform('dmclearsusp.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS SwitchProdPeriod AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Switch Prod Period in a Closed Run]
   cOnClickCommand	= [m.gostatemanager.openform('dmswitchprod.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS SwitchTaxWH AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Switch State Tax Withholding Rate]
   cOnClickCommand	= [m.gostatemanager.openform('dmtaxswitch.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS FileCopy AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Copy \<Files to Another Company]
   cOnClickCommand	= [m.gostatemanager.openform('filecopy.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS CreateACHFile AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Re-Create Direc\<t Deposit ACH File]
   cOnClickCommand	= [m.gostatemanager.openform('dmdirectdep.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ChangeReconDates AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Chan\<ge Reconciliation Dates]
   cOnClickCommand	= [m.gostatemanager.openform('csreconchg.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS DeleteRecon AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [De\<lete a Reconcilation]
   cOnClickCommand	= [m.gostatemanager.openform('csrecondel.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ManageOffsite AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Manage Offsite Backups]
   cOnClickCommand	= [m.gostatemanager.openform('fileoffsite.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS OnlineRptsUpload AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [U\<pload Reports to Website]
   cOnClickCommand	= [m.gostatemanager.openform('dmronline.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS EnergyLink AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Create EnergyLink File]
   cOnClickCommand	= [m.gostatemanager.openform('energylink.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ResetLeasePmts AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Reset Lease Pmt Totals]
   cSkipFor = [not m.goapp.lAdmin]

   PROCEDURE CLICK
*
* Resets the total payments to date in the landowner file
* based on the payments made in the landhist file
*
      swselect('landowner')
      swselect('landhist')

      SELECT cownerid, cleaseid, SUM(npmtamount) AS ntotal ;
         FROM landhist ;
         INTO CURSOR temphist ;
         ORDER BY cownerid, cleaseid ;
         GROUP BY cownerid, cleaseid

      SELECT temphist
      SCAN
         SCATTER MEMVAR
         WAIT WINDOW NOWAIT 'Processing owner/lease: ' + m.cownerid + '/' + m.cleaseid
         SELECT landowner
         LOCATE FOR cownerid == m.cownerid AND cleaseid == m.cleaseid
         IF FOUND()
            REPLACE npmttodate WITH m.ntotal
         ENDIF
      ENDSCAN
      WAIT CLEAR
      MESSAGEBOX('Lease Obligation Payment Totals Have Been Updated.', 64, 'Update Pmts To Date')
   ENDPROC
ENDDEFINE


*===============================================================================
DEFINE CLASS SpecialUtilities AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Special Utilities]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('Security', '', 'Security')
         .AddBar('RemoveCompRecs', '', 'RemoveCompRecs')
         .AddBar('RemoveProgs', '', 'RemoveProgs')
         .AddBar('Diagnostics', '', 'Diagnostics')
         .AddBar('InstallFilesMsg', '', 'InstallFilesMsg')

         .AddSeparatorBar()
         .AddBar('ArchiveData', '', 'ArchiveData')

         IF m.goapp.lAMVersion
            .AddSeparatorBar()
            .AddBar('CloseFiscalYr', '', 'CloseFiscalYr')
            .AddBar('OpenFiscalYr', '', 'OpenFiscalYr')
            .AddSeparatorBar()
            .AddBar('GLMasterUpd', '', 'GLMasterUpd')
            .AddBar('CheckGLProbs', '', 'CheckGLProbs')
            .AddBar('GLBatches', '', 'GLBatches')
         ENDIF

         IF m.goapp.lPayrollOpt
            .AddSeparatorBar()
            .AddBar('PRTaxTables', '', 'PRTaxTables')
         ENDIF

         .AddSeparatorBar()
         .AddBar('FileStats', '', 'FileStats')
         .AddBar('ResetCounters', '', 'ResetCounters')
         .AddBar('RepairFiles', '', 'RepairFiles')
         .AddBar('UpdateAFECodes', '', 'UpdateAFECodes')

         IF m.goapp.lAdmin
            .AddSeparatorBar()
            .AddBar('CommandUtility', '', 'CommandUtility')
         ENDIF
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS Security AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Enable/Disable Log In Form]

   PROCEDURE CLICK
      LOCAL lcpass, lnPass, lcdate, lndate, lnx, lnlen, lcPassEntered, oMessage, lnChk

      oMessage = FindGlobalObject('cmMessage')
      SET CENTURY ON
      lcdate = DTOC(DATE())
      lndate = 0

      lnlen = LEN(ALLTRIM(lcdate))

      FOR lnx = 1 TO lnlen
         lndate = lndate + VAL(SUBSTR(lcdate,lnx,1))
      ENDFOR

      lndate = lndate

      lcpass = TRANSFORM((MONTH(DATE())*DAY(DATE())) + YEAR(DATE()))

      lcPassEntered = oMessage.gettext('Enter the Supervisor Password:','Password Required')

      IF ALLTRIM(lcPassEntered) = ALLTRIM(lcpass)
         IF FILE(m.goapp.cCommonFolder+'swi1215.cfg')
            ERASE (m.goapp.cCommonFolder+'swi1215.cfg')
            oMessage.INFORM('Security has been enabled.')
         ELSE
            fh = FCREATE(m.goapp.cCommonFolder+'swi1215.cfg')
            FCLOSE(fh)
            oMessage.INFORM('Security has been disabled.')
         ENDIF
      ELSE
         oMessage.warning('Invalid password entered. Please contact technical support for the password.')
      ENDIF
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS RemoveCompRecs AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Remove Companies with Missing Data]
   cOnClicCommand = [do remove_nonexistant_companies]

ENDDEFINE

*===============================================================================
DEFINE CLASS RemoveProgs AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Remove Programs From Suspense Records]
   cOnClicCommand = [do clearsuspprogs]

ENDDEFINE

*===============================================================================
DEFINE CLASS Diagnostics AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Enable/Disable Log In Form]

   PROCEDURE CLICK
      TRY
         IF FILE(m.goapp.cCommonFolder + 'diag.cfg')
            ERASE(m.goapp.cCommonFolder + 'diag.cfg')
            m.goapp.oLogger.lLoggingEnabled = .F.
            MESSAGEBOX('Diagnostic reporting has been disabled', 64, 'Diagnostics')
         ELSE
            lcString = 'diagnostics'
            STRTOFILE(lcString, m.goapp.cCommonFolder + 'diag.cfg')
            m.goapp.oLogger.lLoggingEnabled = .T.
            MESSAGEBOX('Diagnostic reporting has been enabled', 64, 'Diagnostics')
         ENDIF
      CATCH
      ENDTRY
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS InstallFilesMsg AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Turn Off Install Files Message]

   PROCEDURE CLICK
      oMessage = FindGlobalObject('cmMessage')
      IF FILE(m.goapp.cCommonFolder + 'ignorexfrx.txt')
         ERASE (m.goapp.cCommonFolder + 'ignorexfrx.txt')
         oMessage.INFORM('The message about installing files will be reinstated.')
      ELSE
         fh = FCREATE(m.goapp.cCommonFolder + 'ignorexfrx.txt')
         FCLOSE(fh)
         oMessage.INFORM('The message bout install files will be silenced.')
      ENDIF

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ArchiveData AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Archive Data]
   cOnClickCommand	= [m.gostatemanager.openform('filearchive.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS CloseFiscalYr AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Close Fiscal Accounting Year]
   cOnClickCommand	= [m.gostatemanager.openform('glcloseyr.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS OpenFiscalYr AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Open Fiscal Accounting Year]
   cOnClickCommand	= [m.gostatemanager.openform('glopenyr.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS GLMasterUpd AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [G/L Master File Update]
   cOnClickCommand	= [m.gostatemanager.openform('glmastupd.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS CheckGLProbs AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Check G/L for Out of Balance Batches]
   cOnClickCommand	= [do chkbal]
ENDDEFINE

*===============================================================================
DEFINE CLASS GLBatches AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Recreate G/L Batches File]
   cOnClickCommand	= [m.goapp.Create_GLBatches(.T.)]
ENDDEFINE

*===============================================================================
DEFINE CLASS PRTaxTables AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Download Payroll Tax Tables]
   cOnClickCommand	= [do prtaxtableupd with .F.,.T.]
ENDDEFINE

*===============================================================================
DEFINE CLASS FileStats AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [View File Statistics]
   cOnClickCommand	= [m.gostatemanager.openform('companystats.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ResetCounters AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Reset File Counters]
   cOnClickCommand	= [m.goapp.resetcounters(.T.)]
ENDDEFINE

*===============================================================================
DEFINE CLASS RepairFiles AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Repair Files]

   PROCEDURE CLICK
      lcpass = m.goapp.oMessage.gettext('Enter the support password')

      jcPass = TRANSFORM(MONTH(DATE())*DAY(DATE())+YEAR(DATE()))

      IF ISNULL(lcpass)
         RETURN .F.
      ENDIF

      IF ALLTRIM(lcpass) # ALLTRIM(jcPass)
         MESSAGEBOX('You entered an invalid password. The Repair Utility cannot be used.',16,'Security Failure')
         RETURN .F.
      ENDIF

      IF swOpenForms()
         MESSAGEBOX('All forms must be closed before repairing the files.',16,'Repair Error')
         RETURN
      ENDIF

      llUseOK = .T.
      lcDataBase = TRIM(m.goapp.cDataFilePath) + 'AppData'

      IF NOT USED('disbhist')
         USE disbhist IN 0
      ENDIF

      llUseOK = FLOCK('Disbhist')

      m.goapp.closealldata()

      IF llUseOK
         m.goapp.opensdt()

         OPEN DATABASE (lcDataBase)

         oMeta.SetDatabase(DBC())

         oMeta.oSDTMgr.Repair()

      ELSE
         MESSAGEBOX("This company's files are in use by another user.  Have everyone logout and try again...")
      ENDIF

   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS UpdateAFECodes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Update AFE Codes]
   cOnClickCommand	= [m.goapp.fixafeno(.t.,.t.)]
ENDDEFINE

*===============================================================================
DEFINE CLASS CommandUtility AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Command Utility]
   cOnClickCommand	= [m.goStateManager.OpenModalForm('command.scx')]
ENDDEFINE

*===============================================================================
*===============================================================================
*===============================================================================
DEFINE CLASS WINDOWS AS SFPad OF SFMenu.vcx
*===============================================================================
*===============================================================================
*===============================================================================
   cCaption	 = [\<Window]
   cKey		 = [ALT+W]
   cPopupName	 = [Window]
   cSkipFor	 = [m.goApp.lExpired]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('WindowClose', '', 'WindowClose')
         .AddBar('WindowCycle', '', 'WindowCycle')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS WindowClose AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Close]
   cOnClickCommand	= [m.goStateManager.Execute('Form Close')]
   cSkipFor		= [not m.gostatemanager.getvalue('form close')]
ENDDEFINE

*===============================================================================
DEFINE CLASS WindowCycle AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption   = [C\<ycle]
   cKey	   = [CTRL+F1]
   cKeyText   = [Ctrl+F1]
   cSystemBar = [_mwi_rotat]
ENDDEFINE


*===============================================================================
*===============================================================================
*===============================================================================
DEFINE CLASS HelpMenu AS SFPad OF SFMenu.vcx
*===============================================================================
*===============================================================================
*===============================================================================
   cCaption	 = [\<Help]
   cKey		 = [ALT+H]
   cPopupName	 = [HelpMenu]

   PROCEDURE AddBars
      WITH THIS
         .AddBar('HelpTopics', '', 'HelpTopics')
         .AddBar('HelpOnline', '', 'HelpOnline')
         .AddSeparatorBar()
         .AddBar('SherWareNews', '', 'SherWareNews')
         .AddSeparatorBar()
         .AddBar('VersionInfo', '', 'VersionInfo')
         .AddBar('ReleaseNotes', '', 'ReleaseNotes')
         .AddBar('ForceUpdate', '', 'ForceUpdate')
         .AddSeparatorBar()
         .AddBar('EmailSupport', '', 'EmailSupport')
         .AddBar('ConnectWithSupport', '', 'ConnectWithSupport')
         .AddBar('WishList', '', 'WishList')
      ENDWITH
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS HelpTopics AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [Topics...]
   cKey			= [F1]
   cKeyText		= [F1]
   cOnClickCommand	= [HELP]
ENDDEFINE

*===============================================================================
DEFINE CLASS HelpOnline AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Help Online]

   PROCEDURE CLICK
      lcurl = 'https://support.sherware.com/help/dmie'

* declare API-function 'ShellExecute'
      DECLARE ShellExecute IN shell32.DLL INTEGER, STRING, STRING, STRING, STRING, INTEGER

* let windows decide, which app computes URLs
      ShellExecute( 0, [open], lcurl, [], [], 1 )

* undeclare API-function
      CLEAR DLLS [ShellExecute]
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS SherWareNews AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<SherWare News]
   cOnClickCommand	= [m.gostatemanager.openform('news.scx',.T.)]
ENDDEFINE

*===============================================================================
DEFINE CLASS VersionInfo AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption		= [\<Version Information]
   cOnClickCommand	= [m.goStateManager.OpenForm('appversion.scx')]
ENDDEFINE

*===============================================================================
DEFINE CLASS ReleaseNotes AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [View Release \<Notes]

   PROCEDURE CLICK
      lcurl = 'https://support.sherware.com/changesdmie.html'

* declare API-function 'ShellExecute'
      DECLARE ShellExecute IN shell32.DLL INTEGER, STRING, STRING, STRING, STRING, INTEGER

* let windows decide, which app computes URLs
      ShellExecute( 0, [open], lcurl, [], [], 1 )

* undeclare API-function
      CLEAR DLLS [ShellExecute]
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ForceUpdate AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Force Update Next Start]

   PROCEDURE CLICK
      TRY
         IF NOT FILE('datafiles\forceupd.cfg')
            fh = FCREATE('datafiles\forceupd.cfg')
            IF fh > 0
               MESSAGEBOX('Exit the software and then start it up again to download an update.', 64, 'Force Update')
            ELSE
               MESSAGEBOX('Could not create the temp file to force the update. Please try again later.', 64, 'Force Update')
            ENDIF
         ENDIF
      CATCH
      ENDTRY
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS EmailSupport AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Send Email To Support]

   PROCEDURE CLICK
      lcurl = 'https://support.sherware.com/supportcontact.html'

* declare API-function 'ShellExecute'
      DECLARE ShellExecute IN shell32.DLL INTEGER, STRING, STRING, STRING, STRING, INTEGER

* let windows decide, which app computes URLs
      ShellExecute( 0, [open], lcurl, [], [], 1 )

* undeclare API-function
      CLEAR DLLS [ShellExecute]
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS ConnectWithSupport AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [\<Connect with SherWare Support]

   PROCEDURE CLICK
      lcurl = 'https://fastsupport.gotoassist.com'

* declare API-function 'ShellExecute'
      DECLARE ShellExecute IN shell32.DLL INTEGER, STRING, STRING, STRING, STRING, INTEGER

* let windows decide, which app computes URLs
      ShellExecute( 0, [open], lcurl, [], [], 1 )

* undeclare API-function
      CLEAR DLLS [ShellExecute]
   ENDPROC
ENDDEFINE

*===============================================================================
DEFINE CLASS WishList AS SFBar OF SFMenu.vcx
*===============================================================================
   cCaption = [Software \<Wish List]

   PROCEDURE CLICK
      lcurl = 'https://sherware.uservoice.com'

* declare API-function 'ShellExecute'
      DECLARE ShellExecute IN shell32.DLL INTEGER, STRING, STRING, STRING, STRING, INTEGER

* let windows decide, which app computes URLs
      ShellExecute( 0, [open], lcurl, [], [], 1 )

* undeclare API-function
      CLEAR DLLS [ShellExecute]
   ENDPROC
ENDDEFINE






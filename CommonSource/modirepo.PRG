PARA tcReport
LOCAL lcData, llFound, llError

IF swOpenForms()
   MESSAGEBOX('All forms must be closed before modifying any report formats.',16,'Open Form Error')
   RETURN
ENDIF

llFound = .F.  &&  Variable for telling whether the requested file exists - BH 8/30/06
llError = .F.  &&  Set to .T. in the catch if an error is enountered trying to modi a file
oMessage = findglobalobject('cmMessage')
tcReport = UPPER(tcReport)

PUSH MENU _MSYSMENU
SET SYSMENU TO _MFILE, _MEDIT

lcData = ALLTRIM(m.goApp.cDataFilePath)

llCommonMICR = FILE(m.goApp.cCommonFolder+'commonmicr.txt')

m.goStateManager.CloseToolbar('tbrMainToolBar')

* Setup up try/catch to catch error 1 - file does not exist
TRY
   DO CASE
      CASE tcReport == 'W2'
         IF FILE(m.goapp.cRptsFolder+'prw2L.frx')
            AddProtection(m.goapp.cRptsFolder+'prw2L.frx')
            MODIFY REPORT (m.goapp.cRptsFolder+'prw2L.frx') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PRCHKLV'
         IF FILE(m.goApp.cChecksFolder+'prcheklv.frx')
            AddProtection(m.goApp.cChecksFolder+'prcheklv.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'prcheklv') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PRCHKLM'
         IF FILE(lcData+'prcheklm.frx')
            AddProtection(lcData+'prcheklm.frx')
            MODIFY REPORT (lcData+'prcheklm') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PRCHKDA'
         IF FILE(m.goApp.cChecksFolder+'prchekda.frx')
            AddProtection(m.goApp.cChecksFolder+'prchekda.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'prchekda') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'PRCHKDB'
         IF FILE(m.goApp.cChecksFolder+'prchekdb.frx')
            AddProtection(m.goApp.cChecksFolder+'prchekdb.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'prchekdb') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLV'
         IF FILE(m.goApp.cChecksFolder+'apcheklv.frx')
            AddProtection(m.goApp.cChecksFolder+'apcheklv.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'apcheklv') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLM'
         IF FILE(lcData+'apcheklm.frx')
            AddProtection(lcData+'apcheklm.frx')
            MODIFY REPORT (lcData+'apcheklm') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLN'
         IF FILE(m.goApp.cChecksFolder+'apchekln.frx')
            AddProtection(m.goApp.cChecksFolder+'apchekln.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'apchekln') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLE'
         IF llCommonMICR
            IF FILE(m.goApp.cChecksFolder+'apchekle.frx')
               AddProtection(m.goApp.cChecksFolder+'apchekle.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'apchekle') PROTECTED NOENVIRONMENT
               llFound = .T.
            ELSE
               IF FILE(lcData+'apchekle.frx')
                  AddProtection(lcData+'apchekle.frx')
                  MODIFY REPORT (lcData+'apchekle') PROTECTED NOENVIRONMENT
                  llFound = .T.
               ENDIF
            ENDIF
         ENDIF
      CASE tcReport == 'APCHKDB'
         IF FILE(m.goApp.cChecksFolder+'apchekdb.frx')
            AddProtection(m.goApp.cChecksFolder+'apchekdb.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'apchekdb') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKDA'
         IF FILE(m.goApp.cChecksFolder+'apchekda.frx')
            AddProtection(m.goApp.cChecksFolder+'apchekda.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'apchekda') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKDN'
         IF FILE(m.goApp.cChecksFolder+'apchekdn.frx')
            AddProtection(m.goApp.cChecksFolder+'apchekdn.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'apchekdn') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLA'
         IF FILE(m.goApp.cChecksFolder+'apchekla.frx')
            AddProtection(m.goApp.cChecksFolder+'apchekla.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'apchekla') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKLC'
         IF FILE(m.goApp.cChecksFolder+'apcheklc.frx')
            AddProtection(m.goApp.cChecksFolder+'apcheklc.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'apcheklc') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'APCHKCF'
         IF NOT FILE(lcData+'apchekcf.frx')
            USE customchk IN 0
            SELECT customchk
            COPY TO (lcData+'apchekcf.frx') FOR checkname='APCHEKCF'
            USE IN customchk
         ENDIF
         TRY
            MODIFY REPORT (lcData+'apchekcf') PROTECTED NOENVIRONMENT
            llFound = .T.
         CATCH
            llFound = .F.
         ENDTRY
      CASE tcReport == 'DMCHKLVE'
         IF FILE(m.goApp.cChecksFolder+'dmcheklve.frx')
            AddProtection(m.goApp.cChecksFolder+'dmcheklve.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'dmcheklve') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKLV'
         IF FILE(m.goApp.cChecksFolder+'dmcheklv.frx')
            AddProtection(m.goApp.cChecksFolder+'dmcheklv.frx')
            MODIFY REPORT (m.goApp.cChecksFolder+'dmcheklv') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKLM'
         IF FILE(lcData+'dmcheklm.frx')
            AddProtection(lcData+'dmcheklm.frx')
            MODIFY REPORT (lcData+'dmcheklm') PROTECTED NOENVIRONMENT
            llFound = .T.
         ENDIF
      CASE tcReport == 'DMCHKLE'
         IF llCommonMICR
            IF FILE(m.goApp.cChecksFolder+'dmchekle.frx')
               AddProtection(m.goApp.cChecksFolder+'dmchekle.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'dmchekle') PROTECTED NOENVIRONMENT
            ELSE
               IF FILE(lcData+'dmchekle.frx')
                  AddProtection(lcData+'dmchekle.frx')
                  MODIFY REPORT (lcData+'dmchekle') PROTECTED NOENVIRONMENT
                  llFound = .T.
               ENDIF
            ENDIF
         ENDIF 
         CASE tcReport == 'DMCHKLA'
            IF FILE(m.goApp.cChecksFolder+'dmchekla.frx')
               AddProtection(m.goApp.cChecksFolder+'dmchekla.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'dmchekla') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'DMCHKLC'
            IF FILE(m.goApp.cChecksFolder+'dmcheklc.frx')
               AddProtection(m.goApp.cChecksFolder+'dmcheklc.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'dmcheklc') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'DMCHKDB'
            IF FILE(m.goApp.cChecksFolder+'dmchekdb.frx')
               AddProtection(m.goApp.cChecksFolder+'dmchekdb.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'dmchekdb') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'DMCHKDA'
            IF FILE(m.goApp.cChecksFolder+'dmchekda.frx')
               AddProtection(m.goApp.cChecksFolder+'dmchekda.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'dmchekda') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'DMCHKDN'
            IF FILE(m.goApp.cChecksFolder+'dmchekdn.frx')
               AddProtection(m.goApp.cChecksFolder+'dmchekdn.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'dmchekdn') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'DMCHKLN'
            IF FILE(m.goApp.cChecksFolder+'dmchekln.frx')
               AddProtection(m.goApp.cChecksFolder+'dmchekln.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'dmchekln') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'DMCHKCF'
            IF NOT FILE(lcData+'dmchekcf.frx')
               USE customchk IN 0
               SELECT customchk
               COPY TO (lcData+'dmchekcf.frx') FOR checkname='DMCHEKCF'
               USE IN customchk
            ENDIF
            AddProtection(lcData+'dmchekcf.frx')
            TRY
               MODIFY REPORT (lcData+'dmchekcf') PROTECTED NOENVIRONMENT
               llFound = .T.
            CATCH
            ENDTRY
         CASE tcReport == 'CUSTSTMT'
            TRY
               AddProtection(m.goApp.cRptsFolder+'custstmt.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'custstmt') PROTECTED NOENVIRONMENT
               llFound = .T.
            CATCH
            ENDTRY
         CASE tcReport == 'ARINV'
            swselect('aropt')  &&  Get format being used, and modify that one
            GO TOP
            IF nInvType = 1
               IF FILE(m.goApp.cRptsFolder+'arinv1.frx')
                  AddProtection(m.goApp.cRptsFolder+'arinv1.frx')
                  MODIFY REPORT (m.goApp.cRptsFolder+'arinv1') PROTECTED NOENVIRONMENT
                  llFound = .T.
               ENDIF
            ELSE
               IF FILE(m.goApp.cRptsFolder+'arinv2.frx')
                  AddProtection(m.goApp.cRptsFolder+'arinv2.frx')
                  MODIFY REPORT (m.goApp.cRptsFolder+'arinv2') PROTECTED NOENVIRONMENT
                  llFound = .T.
               ENDIF
            ENDIF
         CASE tcReport == 'HGINV'
            IF FILE(m.goApp.cRptsFolder+'gasinv.frx')
               AddProtection(m.goApp.cRptsFolder+'gasinv.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'gasinv') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'BMINV'
            swselect('aropt')  &&  Get format being used, and modify that one
            GO TOP
            IF nInvType = 1
               IF FILE('modules\brine\rpts\bminv1.frx')
                  AddProtection('modules\brine\rpts\bminv1.frx')
                  MODIFY REPORT ('modules\brine\rpts\bminv1') PROTECTED NOENVIRONMENT
                  llFound = .T.
               ENDIF
            ELSE
               IF FILE('modules\brine\rpts\bminv2.frx')
                  AddProtection('modules\brine\rpts\bminv2.frx')
                  MODIFY REPORT ('modules\brine\rpts\bminv2') PROTECTED NOENVIRONMENT
                  llFound = .T.
               ENDIF
            ENDIF
         CASE tcReport == 'OWNSTUB'
            IF FILE(m.goApp.cRptsFolder+'dmrostub.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrostub.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrostub') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OSTMT1' && Standard Stmt
            IF FILE(m.goApp.cRptsFolder+'dmrostmt1a.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrostmt1a.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrostmt1a') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OSTMT2' && Standard Stmt Duplex
            IF FILE(m.goApp.cRptsFolder+'dmrostmt1ad.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrostmt1ad.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrostmt1ad') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OSTMT3' && Standard Stmt Tax Code
            IF FILE(m.goApp.cRptsFolder+'dmrostmt1b.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrostmt1b.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrostmt1b') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OSTMT4' && Standard Stmt Tax Code Duplex
            IF FILE(m.goApp.cRptsFolder+'dmrostmt1bd.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrostmt1bd.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrostmt1bd') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OSTMT5' && Compressed Stmt
            IF FILE(m.goApp.cRptsFolder+'dmrostmt2a.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrostmt2a.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrostmt2a') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OSTMT6' && Compressed Stmt Duplex
            IF FILE(m.goApp.cRptsFolder+'dmrostmt2ad.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrostmt2ad.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrostmt2ad') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OSTMT7' && Compressed Stmt Tax Code
            IF FILE(m.goApp.cRptsFolder+'dmrostmt2b.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrostmt2b.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrostmt2b') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OSTMT8' && Compressed Stmt Tax Code Duplex
            IF FILE(m.goApp.cRptsFolder+'dmrostmt2bd.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrostmt2bd.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrostmt2bd') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF

         CASE tcReport == 'TENDOT'
            IF FILE(m.goApp.cRptsFolder+'1099s\ten99rptd.frx')
               AddProtection(m.goApp.cRptsFolder+'1099s\ten99rptd.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'1099s\ten99rptd') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'TENLAS'
            IF FILE(m.goApp.cRptsFolder+'1099s\ten99rptl.frx')
               AddProtection(m.goApp.cRptsFolder+'1099s\ten99rptl.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'1099s\ten99rptl') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'TENNEC'
            IF FILE(m.goApp.cRptsFolder+'1099s\ten99nec.frx')
               AddProtection(m.goApp.cRptsFolder+'1099s\ten99nec.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'1099s\ten99nec') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OWNLABD'
            IF FILE(m.goApp.cRptsFolder+'ownlabd.lbx')
               AddProtection(m.goApp.cRptsFolder+'ownlabd.lbx')
               MODIFY LABEL (m.goApp.cRptsFolder+'ownlabd') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OWNLABL'
            IF FILE(m.goApp.cRptsFolder+'ownlabl.lbx')
               AddProtection(m.goApp.cRptsFolder+'ownlabl.lbx')
               MODIFY LABEL (m.goApp.cRptsFolder+'ownlabl') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LMCHKDB'
            IF FILE(m.goApp.cChecksFolder+'lmchekdb.frx')
               AddProtection(m.goApp.cChecksFolder+'lmchekdb.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'lmchekdb') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LMCHKDA'
            IF FILE(m.goApp.cChecksFolder+'lmchekda.frx')
               AddProtection(m.goApp.cChecksFolder+'lmchekda.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'lmchekda') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LMCHKDN'
            IF FILE(m.goApp.cChecksFolder+'lmchekdn.frx')
               AddProtection(m.goApp.cChecksFolder+'lmchekdn.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'lmchekdn') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LMCHKLV'
            IF FILE(m.goApp.cChecksFolder+'lmcheklv.frx')
               AddProtection(m.goApp.cChecksFolder+'lmcheklv.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'lmcheklv') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LMCHKLA'
            IF FILE(m.goApp.cChecksFolder+'lmchekla.frx')
               AddProtection(m.goApp.cChecksFolder+'lmchekla.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'lmchekla') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LMCHKLC'
            IF FILE(m.goApp.cChecksFolder+'lmcheklc.frx')
               AddProtection(m.goApp.cChecksFolder+'lmcheklc.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'lmcheklc') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LMCHKLN'
            IF FILE(m.goApp.cChecksFolder+'lmchekln.frx')
               AddProtection(m.goApp.cChecksFolder+'lmchekln.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'lmchekln') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LMCHKCF'
            IF NOT FILE(lcData+'lmchekcf.frx')
               USE customchk IN 0
               SELECT customchk
               COPY TO (lcData+'lmchekcf.frx') FOR checkname='LMCHEKCF'
               USE IN customchk
            ENDIF
            AddProtection(lcData+'lmchekcf.frx')
            TRY
               MODIFY REPORT (lcData+'lmchekcf') PROTECTED NOENVIRONMENT
               llFound = .T.
            CATCH
            ENDTRY
         CASE tcReport == 'JIBSUM'
            IF FILE(m.goApp.cRptsFolder+'dmrojibsummcust.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrojibsummcust.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrojibsummcust') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'JIBCAT'
            IF FILE(m.goApp.cRptsFolder+'dmrojibsumcatcust.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrojibsumcatcust.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrojibsumcatcust') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'JIBRUN'
            IF FILE(m.goApp.cRptsFolder+'dmrojibcust.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrojibcust.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrojibcust') PROTECTED NOENVIRONMENT
               llFound = .T.
            ELSE
               * If the custom format doesn't exist, use the default one - BH 05/16/2008
               IF FILE(m.goApp.cRptsFolder+'dmrojibrun.frx')
                  AddProtection(m.goApp.cRptsFolder+'dmrojibrun.frx')
                  MODIFY REPORT (m.goApp.cRptsFolder+'dmrojibrun') PROTECTED NOENVIRONMENT
                  llFound = .T.
               ENDIF
            ENDIF
         CASE tcReport == 'JIBSORT'
            IF FILE(m.goApp.cRptsFolder+'dmrojibcust1.frx')
               AddProtection(m.goApp.cRptsFolder+'dmrojibcust1.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'dmrojibcust1') PROTECTED NOENVIRONMENT
               llFound = .T.
            ELSE
               IF FILE(m.goApp.cRptsFolder+'dmrojibrun1.frx')  &&  If the custom format doesn't exist, use the default one - BH 05/16/2008
                  AddProtection(m.goApp.cRptsFolder+'dmrojibrun1.frx')
                  MODIFY REPORT (m.goApp.cRptsFolder+'dmrojibrun1') PROTECTED NOENVIRONMENT
                  llFound = .T.
               ENDIF
            ENDIF
         CASE tcReport == 'PDCHKLV'
            IF FILE(m.goApp.cChecksFolder+'pdcheklv.frx')
               AddProtection(m.goApp.cChecksFolder+'pdcheklv.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'pdcheklv') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'PDCHKLA'
            IF FILE(m.goApp.cChecksFolder+'pdchekla.frx')
               AddProtection(m.goApp.cChecksFolder+'pdchekla.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'pdchekla') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'PDCHKLB'
            IF FILE(m.goApp.cChecksFolder+'pdcheklb.frx')
               AddProtection(m.goApp.cChecksFolder+'pdcheklb.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'pdcheklb') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'PDCHKDA'
            IF FILE(m.goApp.cChecksFolder+'pdchekda.frx')
               AddProtection(m.goApp.cChecksFolder+'pdchekda.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'pdchekda') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'PDCHKDB'
            IF FILE(m.goApp.cChecksFolder+'pdchekdb.frx')
               AddProtection(m.goApp.cChecksFolder+'pdchekdb.frx')
               MODIFY REPORT (m.goApp.cChecksFolder+'pdchekdb') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == '1099MISCW'
            IF FILE(m.goApp.cRptsFolder+'1099s\ten99miscw.frx')
               AddProtection(m.goApp.cRptsFolder+'1099s\ten99miscw.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'1099s\ten99miscw') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == '1099MISC'
            IF FILE(m.goApp.cRptsFolder+'1099s\ten99misc.frx')
               AddProtection(m.goApp.cRptsFolder+'1099s\ten99misc.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'1099s\ten99misc') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == '1099NEC'
            IF FILE(m.goApp.cRptsFolder+'1099s\ten99necr.frx')
               AddProtection(m.goApp.cRptsFolder+'1099s\ten99necr.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'1099s\ten99necr') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
        CASE tcReport == '1099NECW'
            IF FILE(m.goApp.cRptsFolder+'1099s\ten99necr.frx')
               AddProtection(m.goApp.cRptsFolder+'1099s\ten99necw.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'1099s\ten99necw') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'AFEOWNRPT1'
            IF FILE(m.goApp.cRptsFolder+'afeownrpt1.frx')
               AddProtection(m.goApp.cRptsFolder+'afeownrpt1.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'afeownrpt1') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LASEVTAX2'
            IF FILE(m.goApp.cRptsFolder+'lasevtax2.frx')
               AddProtection(m.goApp.cRptsFolder+'lasevtax2.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'lasevtax2') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LASEVTAX3'
            IF FILE(m.goApp.cRptsFolder+'lasevtax3.frx')
               AddProtection(m.goApp.cRptsFolder+'lasevtax3.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'lasevtax3') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'LASEVTAX'
            IF FILE(m.goApp.cRptsFolder+'lasevtax.frx')
               AddProtection(m.goApp.cRptsFolder+'lasevtax.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'lasevtax') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'NYPROD'
            IF FILE(m.goApp.cRptsFolder+'nyprod.frx')
               AddProtection(m.goApp.cRptsFolder+'nyprod.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'nyprod') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OHFORM10'
            IF FILE(m.goApp.cRptsFolder+'ohform10.frx')
               AddProtection(m.goApp.cRptsFolder+'ohform10.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'ohform10') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OHFORM6A'
            IF FILE(m.goApp.cRptsFolder+'ohform6a.frx')
               AddProtection(m.goApp.cRptsFolder+'ohform6a.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'ohform6a') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OHFORM6S'
            IF FILE(m.goApp.cRptsFolder+'ohform6s.frx')
               AddProtection(m.goApp.cRptsFolder+'ohform6s.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'ohform6s') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OHFORM6'
            IF FILE(m.goApp.cRptsFolder+'ohform6.frx')
               AddProtection(m.goApp.cRptsFolder+'ohform6.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'ohform6') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'PAPROD'
            IF FILE(m.goApp.cRptsFolder+'paprod.frx')
               AddProtection(m.goApp.cRptsFolder+'paprod.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'paprod') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'TEXASPR'
            oMessage.Warning('The formatting for the PR report has been approved by the Texas RRC, and cannot be modified.')
            llFound = .T.
         CASE tcReport == 'WVANNRET1'
            IF FILE(m.goApp.cRptsFolder+'wvannret1.frx')
               AddProtection(m.goApp.cRptsFolder+'wvannret1.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'wvannret1') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'WVANNRET'
            IF FILE(m.goApp.cRptsFolder+'wvannret.frx')
               AddProtection(m.goApp.cRptsFolder+'wvannret.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'wvannret') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'WVRPT39'
            IF FILE(m.goApp.cRptsFolder+'wvrpt39.frx')
               AddProtection(m.goApp.cRptsFolder+'wvrpt39.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'wvrpt39') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'WVWR99'
            IF FILE(m.goApp.cRptsFolder+'wvwr99.frx')
               AddProtection(m.goApp.cRptsFolder+'wvwr99.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'wvwr99') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'WVINSPECT'
            IF FILE(m.goApp.cRptsFolder+'wvinspect.frx')
               AddProtection(m.goApp.cRptsFolder+'wvinspect.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'wvinspect') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'WYOG-001'
            IF FILE(m.goApp.cRptsFolder+'wyog-001.frx')
               AddProtection(m.goApp.cRptsFolder+'wyog-001.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'wyog-001') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'WYSEVTAX'
            IF FILE(m.goApp.cRptsFolder+'wysevtax.frx')
               AddProtection(m.goApp.cRptsFolder+'wysevtax.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'wysevtax') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OHSV3A'
            IF FILE(m.goApp.cRptsFolder+'ohformsv3a.frx')
               AddProtection(m.goApp.cRptsFolder+'ohformsv3a.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'ohformsv3a') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'OHSV3'
            IF FILE(m.goApp.cRptsFolder+'ohformsv3.frx')
               AddProtection(m.goApp.cRptsFolder+'ohformsv3.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'ohformsv3') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'DIVORDM'
            IF FILE(m.goApp.cRptsFolder+'divorder.frx')
               *            AddProtection(m.goApp.cRptsFolder+'divorder.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'divorder') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
         CASE tcReport == 'DIVORDS'
            IF FILE(m.goApp.cRptsFolder+'divorder_single.frx')
               *            AddProtection(m.goApp.cRptsFolder+'divorder_single.frx')
               MODIFY REPORT (m.goApp.cRptsFolder+'divorder_single') PROTECTED NOENVIRONMENT
               llFound = .T.
            ENDIF
      ENDCASE

   CATCH TO loError
      llError = .T.
   ENDTRY

   * Tell the user there was a problem if llError is .T.
   IF llError
      IF loError.ERRORNO = 1
         oMessage.Warning('The requested report does not exist, so it cannot be modified.')
      ELSE
         MESSAGEBOX('The chosen report cannot be modified. The error encountered: ' + CHR(10) + CHR(10) + loError.MESSAGE,48,'Modify Report Problem')
      ENDIF
   ELSE
      IF NOT llFound  &&  Requested format didn't exist, so give a warning, instead of doing nothing
         oMessage.Warning('The requested report does not exist, so it cannot be modified.')
      ENDIF
   ENDIF

   POP MENU _MSYSMENU

   m.goStateManager.OpenToolbar('tbrMainToolBar')

   *!*    IF lcCURR_MENU = 'OFF'
   *!*       SET SYSMENU OFF
   *!*    ENDIF lcCURR_MENU = 'OFF'



PROCEDURE AddProtection

   PARAMETERS tcReportFormat

   **  Try and get a lock on the file, so we know whether we'll be able to open the .frx file to check the protection stuff.
   **  If it can't open the .frx file, just open it like normal.  This should be rare.  Should only happen if they're trying
   **  to modify the report format while someone else is printing using that format, or is modifying it, too.  What are the chances...

   fh = FOPEN(tcReportFormat)

   IF fh > 0
      FCLOSE(fh)
      USE "&tcReportFormat"
      GO TOP
      IF NOT '€€' $ ORDER
         * Wrap this in a TRY/CATCH to catch any errors
         * caused by the file being read only.
         TRY
            REPLACE ORDER WITH '€€'
         CATCH
         ENDTRY
      ENDIF
      USE
   ENDIF

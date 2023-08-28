****************************************
DEFINE CLASS Partners AS CUSTOM
***************************************

   lSelected    = .F.
   nRunNo       = 0
   cRunYear     = '2020'
   cGroup       = '00'
   dAcctDate    = DATE()
   cDMBatch     = ''
   nDataSession = 1
   cErrorMsg    = ""

*****************************
   PROCEDURE INIT
*****************************

   THIS.CreatePartnerPostTable()

***************************
   PROCEDURE CreatePartnerPost
***************************
   LPARAMETERS tlReCreate  && Called from a form that lets you recreate the posting entries

   LOCAL tcOwner1, tcOwner2, tcYear, tcPeriod, tcWellID1, tcWellID2, ownstmt, lcVersion
   LOCAL llReturn, loError
   LOCAL tcDMBatch, tcGroup, tcOwnerType, tdAcctDate, tlDetail, tlFlatRate, tlIncludeChecks
   LOCAL tlNoProd, tlNoSuspDet, tlPrintDef, tlPrintMin, tlZipCode, tnRunNo

   TRY

* Create the selected cursor from all the owners who have
* a company id specified in their owner record.
      IF !tlReCreate
         SELECT cownerid AS cid, cidcomp ;
            FROM investor ;
            INTO CURSOR SELECTED ;
            WHERE NOT EMPTY(cidcomp) ;
            ORDER BY cid
      ENDIF

* The selected table is either created above or in the recreate form
* so it should always exist at this point
      SELECT SELECTED
      GO TOP
      tcOwner1        = cid
      GO BOTTOM
      tcOwner2        = cid
      tcYear          = THIS.cRunYear
      tnRunNo         = THIS.nRunNo
      tcGroup         = THIS.cGroup
      tdAcctDate      = THIS.dAcctDate
      tcDMBatch       = THIS.cDMBatch
      tlSelected      = THIS.lSelected
      tlFlatRate      = .T.
      tlIncludeChecks = .T.
      tlZipCode       = .F.
      tlDetail        = .F.
      tlNoSuspDet     = .F.
      tlIncSummary    = .F.
      lcVersion       = ' '
      tlNoProd        = .F.
      tlPrintMin      = .T.
      tlPrintDef      = .T.
      tcOwnerType     = 'ALL'
      tlReplace       = .T.

* Fix expense codes to have correct tax codes
      TRY
         swselect('taxcodes')
         swselect('expcat')
         REPLACE cdescrip WITH ccateg FOR EMPTY(cdescrip)
         SELECT ctaxcode FROM expcat WHERE ctaxcode NOT IN (SELECT ctaxcode FROM taxcodes) ;
            INTO CURSOR temp ORDER BY ctaxcode GROUP BY ctaxcode
         SCAN
            SCATTER MEMVAR
            m.cdesc = m.ctaxcode
            INSERT INTO taxcodes FROM MEMVAR
         ENDSCAN
      CATCH
      ENDTRY

      swclose('partnerpost')
      USE (m.goapp.cCommonfolder+'partnerpost') IN 0
      SELECT partnerpost
      CURSORSETPROP("Buffering", 5)

      IF tlReCreate
* Check to see if there are already entries for the chosen
* JVs for this run and warn about it.
         swselect('partnerpost')
         SELECT cidcomp, lposted FROM partnerpost ;
            WHERE cDMBatch = tcDMBatch ;
            AND cidcomp IN (SELECT cidcomp FROM SELECTED) ;
            INTO CURSOR temp ;
            ORDER BY cidcomp ;
            GROUP BY cidcomp
         IF _TALLY > 0
            LOCATE FOR lposted
            IF FOUND()
               MESSAGEBOX('There are posting entries for the chosen JVs and this run ' + ;
                  'that have already posted. They cannot be replaced',0,'Create JV Posting')
               tlReplace = .F.
               EXIT
            ELSE
               IF MESSAGEBOX('There are already posting entries for this run for the chosen JVs. ' + ;
                     'Do you want to replace them?',36,'Create JV Posting') = 7
                  tlReplace = .F.
                  EXIT
               ELSE
                  tlReplace = .T.
               ENDIF
            ENDIF
         ENDIF

         IF tlReplace
            SELECT partnerpost
            DELETE FROM partnerpost WHERE cDMBatch = tcDMBatch AND cidcomp IN (SELECT cidcomp FROM temp)
            TABLEUPDATE(.T.,.T.)
         ENDIF
      ENDIF


      SET PROCEDURE TO CUSTOM\swowner.prg ADDITIVE
      ownstmt                = CREATEOBJECT('swownerstmt')
      ownstmt.lIncludeChecks = tlIncludeChecks
      ownstmt.lEmailOnly     = .F.
      ownstmt.lDirDeposit    = .T.
      ownstmt.lNoSuspDet     = tlNoSuspDet


* Fill in properties needed by the statement process
      ownstmt.cOwner1    = tcOwner1
      ownstmt.cOwner2    = tcOwner2
      ownstmt.cGroup     = tcGroup
      ownstmt.dAcctDate  = tdAcctDate
      ownstmt.cDMBatch   = tcDMBatch
      ownstmt.cRunYear   = tcYear
      ownstmt.nRunNo     = tnRunNo
      ownstmt.cOwnerType = tcOwnerType
      ownstmt.lFlatRate  = tlFlatRate
      ownstmt.lNoProd    = tlNoProd
      ownstmt.lPrintMin  = tlPrintMin
      ownstmt.lPrintDef  = tlPrintDef
      ownstmt.lZipOrder  = tlZipCode
      ownstmt.lDetail    = tlDetail
      ownstmt.lIncSummary = tlIncSummary
      ownstmt.lNoSuspDet = .T.
      ownstmt.lClosing   = !tlReCreate
      ownstmt.lPartnerPost = .T.

      IF ownstmt.MAIN(tlSelected)
         SELECT statemnt
         SET ORDER TO invprog
         IF RECC() = 0
            llReturn = .F.
         ELSE
            llReturn = .T.
         ENDIF
      ELSE
         llReturn = .F.
      ENDIF

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'swpartners', loError.LINENO, 'Create Partner Post', loError.ERRORNO, loError.MESSAGE
      MESSAGEBOX('Unable to process the posting entries at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY

   IF NOT llReturn
      RETURN llReturn
   ENDIF

   lcTemp = SYS(2023) + '\' + SYS(3)
   swselect('investor')
   SELECT cownerid FROM investor WHERE lhold INTO TABLE (lcTemp)

* Remove the records from the statement file that we don't need
   SELECT statemnt
   REPLACE cType WITH 'PDEF', ninvamt WITH ntotnet, ntotal WITH ntotnet, lpriorsusp WITH .T. FOR crptgroup = 'N' AND cType = 'BAL' AND ntotnet < 0
   DELETE FOR crptgroup = 'N' AND cType = 'PDEF' AND 'Suspense Balance' $ cdescript
   DELETE FOR EMPTY(cType) OR INLIST(cType,'NOT','TOT','NET','PRG','PRS','PPD','RND','BAL','FLT')
   DELETE FOR ninvamt = 0
   REPLACE ninvamt WITH ninvamt *-1 FOR cType='EXP'
   REPLACE nrevint WITH nworkint FOR cType='EXP'
   REPLACE cType WITH ccatcode FOR cType = 'EXP' AND NOT EMPTY(ccatcode) && AND NOT lpriorsusp
   REPLACE cType WITH 'PDEF' FOR lpriorsusp AND cType='EXP'
   DELETE FROM statemnt WHERE cownerid IN (SELECT cownerid FROM (lcTemp))

   USE IN (lcTemp)


   CREATE CURSOR temppost ;
      (cidcomp      C(8), ;
      cMasterID    C(8), ;
      nRunNo       I, ;
      cRunYear     C(4), ;
      cownerid     C(10), ;
      cDMBatch     C(8), ;
      dAcctDate    D, ;
      cprodyear    C(4), ;
      cprodprd     C(2), ;
      cwellid      C(10), ;
      cwellname    C(40), ;
      crevkey      C(10), ;
      cType        C(5), ;
      ngrunits     N(12,2), ;
      nownunits    N(12,2), ;
      nprice       N(12,4), ;
      ngrossval    N(12,2), ;
      nownerval    N(12,2), ;
      ctaxcode     C(2), ;
      ccatcode     C(4), ;
      ccategory    C(30), ;
      cvendorid    C(10), ;
      cvendor      C(40), ;
      cdesc        C(40), ;
      crefid       C(20), ;
      cint_type    C(1), ;
      nnetamount   N(12,2), ;
      ninterest    N(11,7))

   CREATE CURSOR tempdoi ;
      (cidcomp    C(8), ;
      cMasterID  C(8), ;
      cDMBatch   C(8), ;
      cownerid   C(10), ;
      cwellid    C(10), ;
      nrevgas    N(11,7), ;
      nrevoil    N(11,7), ;
      nworkint   N(11,7))


   SELECT cownerid FROM statemnt INTO CURSOR owners ORDER BY cownerid GROUP BY cownerid
   lncount = 0
   lnowners = 0
   lcPeriod = PADL(TRANSFORM(MONTH(DATE())),2,'0')
   SELECT owners
   SCAN
      m.cownerid = cownerid
      SELECT SELECTED
      LOCATE FOR cid = m.cownerid
      IF FOUND()
         m.cidcomp = cidcomp
      ELSE
         m.cidcomp = ''
      ENDIF
      SELECT statemnt
      SCAN FOR cownerid == m.cownerid
         STORE '' TO m.cwellid, m.cwellname, m.cType, m.ctaxcode, ;
            m.cdedcode, m.ccategory, m.creference, m.cvendor, m.cint_type
         STORE 0 TO m.ngrunits, m.nownunits, m.nprice, m.ngrossval, m.nownerval, ;
            m.nnetamount, m.ninterest
         STORE {} TO m.dAcctDate
         SCATTER MEMVAR
         IF NOT EMPTY(m.cperiod) AND NOT m.cperiod = '00'
            lcPeriod = m.cperiod  && Save production period
         ELSE
            m.cperiod = lcPeriod
         ENDIF
         m.cprodyear = m.cyear
         m.cprodprd = PADL(ALLTRIM(m.cperiod),2,'0')
         IF m.nunits # 0
            m.ngrunits = m.nunits
            m.nownunits = ROUND(m.nunits * (m.nrevint/100),2)
         ELSE
            STORE 0 TO m.ngrunits, m.nownunits
         ENDIF
         m.price = m.nprice
         IF m.ntotal # 0
            m.ngrossval = m.ntotal
            m.nownerval = m.ninvamt
         ENDIF
         IF NOT EMPTY(m.ccatcode)
            STORE 0 TO m.ngrunits, ;
               m.nprice
            m.ngrossval = m.namount
            m.nownerval = m.ninvamt
            m.cvendor = m.cpayee
         ELSE
            IF INLIST(m.cType,'BBL','MCF','OTH','TRP') OR (m.crptgroup = 'B' AND 'TAX' $ m.cType)
               m.cvendor = m.csource
            ELSE
               m.cvendor = ''
            ENDIF
         ENDIF
         m.crefid    = m.cmiscmemo
         m.cint_type = m.ctypeinv
         m.nnetamount = m.ninvamt
         m.ninterest = m.nrevint
         m.nRunNo    = tnRunNo
         m.cRunYear  = tcYear
         m.cDMBatch  = tcDMBatch
         m.lposted   = .F.
         m.tPosted   = {}
         m.cMasterID = m.goapp.cidcomp
         INSERT INTO temppost FROM MEMVAR
         lncount = lncount + 1
      ENDSCAN

      lnowners = lnowners + 1

      SELECT cwellid, ;
         cownerid, ;
         nrevgas, ;
         nrevoil, ;
         nworkint, ;
         tcDMBatch AS cDMBatch, ;
         m.goapp.cidcomp AS cMasterID, ;
         m.cidcomp AS cidcomp ;
         FROM wellinv ;
         INTO CURSOR tempinterest ;
         WHERE cownerid = m.cownerid ;
         ORDER BY cownerid

      SELECT tempdoi
      APPEND FROM DBF('tempinterest')

   ENDSCAN



   swclose('partnerpost')
   USE (m.goapp.cCommonfolder+'partnerpost') IN 0
   SELECT partnerpost
   CURSORSETPROP("Buffering", 5)
   APPEND FROM DBF('temppost')
   TABLEUPDATE(.T.,.T.)

   swclose('partnerinterest')
   USE (m.goapp.cCommonfolder+'partnerinterest') IN 0
   SELECT partnerinterest
   CURSORSETPROP("Buffering", 5)
   APPEND FROM DBF('tempdoi')
   TABLEUPDATE(.T.,.T.)

   USE IN temppost
   USE IN tempdoi

   RETURN llReturn

   ENDPROC

*****************************************
   PROCEDURE EntriesToPost
*****************************************
   LPARAMETERS tlShowPosted
   LOCAL llReturn

   swclose('partnerpost')
   USE (m.goapp.cCommonfolder+'partnerpost') IN 0
   SELECT partnerpost
   CURSORSETPROP("Buffering", 5)

   IF tlShowPosted
      SELECT * FROM partnerpost ;
         WHERE cidcomp = m.goapp.cidcomp ;
         INTO CURSOR temp
   ELSE
      SELECT * FROM partnerpost ;
         WHERE cidcomp = m.goapp.cidcomp ;
         AND NOT lposted ;
         INTO CURSOR temp
   ENDIF

   IF _TALLY > 0
      llReturn = .T.
   ELSE
      llReturn = .F.
   ENDIF

   RETURN llReturn

*****************************************
   PROCEDURE PostPartnerData
*****************************************
   LPARAMETERS tcDMBatch, tcAccount
   LOCAL lcRevClear, lcExpClear

   llReturn = .T.

   TRY
      swclose('partnerpost')
      USE (m.goapp.cCommonfolder+'partnerpost') IN 0
      SELECT partnerpost
      CURSORSETPROP("Buffering", 5)
*!*				swselect('csrcthdr',.T.)
*!*				swselect('csrctdet',.T.)

      swselect('glopt')
      GO TOP
      lcRevClear = cRevClear
      lcExpClear = cExpClear
      lcSuspense = cSuspense

      SELECT dAcctDate, cMasterID, cDMBatch, SUM(nnetamount) AS nCashAmt ;
         FROM partnerpost ;
         WHERE cidcomp = m.goapp.cidcomp ;
         AND cDMBatch = tcDMBatch ;
         INTO CURSOR posttotal

      SELECT * FROM partnerpost ;
         INTO CURSOR tmpPostData ;
         WHERE cidcomp = m.goapp.cidcomp ;
         AND cDMBatch = tcDMBatch ;
         ORDER BY cwellid, cprodyear, cprodprd


      SELECT csrcthdr
      SCATTER MEMVAR BLANK
      SELECT csrctdet
      SCATTER MEMVAR BLANK

      SELECT posttotal
      SCAN
         SCATTER MEMVAR

         m.cBatch = GetNextPK('BATCH')
         lcBatch  = m.cBatch

         swselect('revsrc')
         LOCATE FOR cidcomp = m.cMasterID
         IF FOUND()
            m.cid = crevkey
            m.cName = crevname
         ELSE
            THIS.cErrorMsg = 'Before importing, you need to choose the purchaser record that matches the ' + ;
               'company these entries are being imported from. Go to Maintain, Purchasers ' + ;
               'and choose the main company in the Partnership Company on a purchaser record.'
            llReturn = .F.
            EXIT
         ENDIF

* Got to figure out where to get the cash account from
         m.cCashAcct = tcAccount

         m.dPostDate = m.dAcctDate
         m.ddate     = m.dAcctDate
         m.cCheckNo = DTOC(m.dAcctDate)
         m.dEntDate = DATETIME()
         m.cdeck    = ''

         INSERT INTO csrcthdr FROM MEMVAR

         SELECT partnerpost
         SCAN FOR cDMBatch = tcDMBatch AND cidcomp = m.goapp.cidcomp
            SCATTER MEMVAR
            m.cBatch = lcBatch

            m.cidrctd = GetNextPK('CSRCTDET')

            swselect('wells')
            LOCATE FOR cwellid = m.cwellid
            IF FOUND()
               m.cdesc = cwellname
               m.cProdPeriod = m.cprodprd
* Check to make sure the expense code exists in this company
               IF NOT INLIST(m.cType,'BBL','MCF','OTH','TRP', ;
                     'GTAX1','GTAX2','GTAX3','GTAX4', ;
                     'OTAX1','OTAX2','OTAX3','OTAX4', ;
                     'PTAX1','PTAX2','PTAX3','PTAX4','MI1','MI2','MISC1','MISC2')
                  swselect('expcat')
                  LOCATE FOR ccatcode = LEFT(m.cType,4) OR m.cType = 'PDEF'
                  IF NOT FOUND()
                     THIS.cErrorMsg = 'Expense Code: ' + m.cType + ' was not found in ' + ;
                        'the expense code file. Cannot continue the import.'
                     llReturn = .F.
                     EXIT
                  ELSE
                     m.cAcctListID = lcExpClear
                     m.nprice      = 0
                     m.nunits      = 0
                     m.nGrossUnits = 0
                     m.namount     = m.nnetamount
                  ENDIF
               ELSE
                  IF m.cType = 'TRP'
                     m.cType = 'TRANS'
                  ENDIF
                  IF m.cType = 'MI1'
                     m.cType = 'MISC1'
                  ENDIF
                  IF m.cType = 'MI2'
                     m.cType = 'MISC2'
                  ENDIF
                  m.cAcctListID = lcRevClear
                  m.nunits      = m.nownunits
                  m.nGrossUnits = m.ngrunits
                  m.namount     = m.nnetamount
               ENDIF

               m.lWellRcpt = .T.
               m.cownerid  = ''
               m.cpayee    = m.cvendor

               INSERT INTO csrctdet FROM MEMVAR

               SELECT partnerpost
               REPLACE lposted WITH .T., ;
                  tPosted WITH DATETIME()
            ENDIF
         ENDSCAN
      ENDSCAN
   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'PostPartnerData', loError.LINENO, '', loError.ERRORNO, loError.MESSAGE
      MESSAGEBOX('Unable to process the importing at this time. Check the System Log found under Other Reports for more information.' + CHR(10) + CHR(10) + ;
         'Contact SherWare Support for help at support@sherware.com', 16, 'Problem Encountered')
   ENDTRY

   WAIT CLEAR


   IF llReturn
      lcBatch  = m.cBatch
      llReturn = PostIncome(lcBatch)
      TABLEUPDATE(.T.,.T.,'Partnerpost')
      TABLEUPDATE(.T.,.T.,'Csrcthdr')
      TABLEUPDATE(.T.,.T.,'Csrctdet')
   ELSE
      TABLEREVERT(.T.,'partnerpost')
      TABLEREVERT(.T.,'csrcthdr')
      TABLEREVERT(.T.,'csrctdet')
      lcBatch  = '***'
   ENDIF

   RETURN lcBatch

   ENDPROC


*****************************************
   FUNCTION  DeleteEntries(tcDMBatch)
*****************************************
   LOCAL llReturn
   llReturn = .T.

   TRY

      swclose('partnerpost')
      USE (m.goapp.cCommonfolder+'partnerpost') IN 0
      SELECT partnerpost
      llReturn = CURSORSETPROP("Buffering", 5)
      DELETE FROM partnerpost WHERE cDMBatch == tcDMBatch AND cMasterID = m.goapp.cidcomp

      swclose('partnerinterest')
      USE (m.goapp.cCommonfolder+'partnerinterest') IN 0
      SELECT partnerinterest
      llReturn = CURSORSETPROP("Buffering", 5)
      DELETE FROM partnerinterest WHERE cDMBatch == tcDMBatch AND cMasterID = m.goapp.cidcomp

   CATCH TO loError
      llReturn = .F.
      DO errorlog WITH 'DeleteEntries', loError.LINENO, 'swPartner', loError.ERRORNO, loError.MESSAGE
   ENDTRY

   RETURN llReturn

*****************************************
   FUNCTION  CheckPosted(tcDMBatch)
*****************************************
   LOCAL llReturn

   llReturn = .F.

   swclose('partnerpost')
   USE (m.goapp.cCommonfolder+'partnerpost') IN 0
   SELECT partnerpost
   CURSORSETPROP("Buffering", 5)
   LOCATE FOR cDMBatch = tcDMBatch AND lposted AND cidcomp = m.goapp.cidcomp
   IF FOUND()
      IF USED('compmast')
         USE IN compmast
      ENDIF
      USE (m.goapp.cCommonfolder+'compmast') IN 0
      SELECT compmast
      LOCATE FOR cidcomp = partnerpost.cidcomp
      lcCompany = compmast.cproducer
      MESSAGEBOX('Entries from this run have already been imported in another partnership company. ' + CHR(13) + ;
         '    ' + lcCompany + CHR(13) + ;
         'The run cannot be opened.',16,'Partnership Import')
      llReturn = .T.
   ENDIF

   RETURN llReturn

*****************************************
   FUNCTION  GetPostAmount(tcDMBatch)
*****************************************
   LOCAL llReturn, lnPartnerPost

   STORE 0 TO lnPartnerPost
   swclose('partnerpost')
   USE (m.goapp.cCommonfolder+'partnerpost') IN 0
   SELECT partnerpost
   CURSORSETPROP("Buffering", 5)
   SCAN FOR cDMBatch = tcDMBatch AND cMasterID = m.goapp.cidcomp
      lnPartnerPost    = lnPartnerPost + nnetamount
   ENDSCAN

   RETURN lnPartnerPost

*****************************************
   PROCEDURE CreatePartnerPostTable
*****************************************

   IF NOT FILE(m.goapp.cCommonfolder+'partnerpost.dbf')
      CREATE TABLE (m.goapp.cCommonfolder+'partnerpost') FREE ;
         (cidcomp      C(8), ;
         lposted      L, ;
         tPosted      T, ;
         nRunNo       I, ;
         cRunYear     C(4), ;
         cDMBatch     C(8), ;
         cBatch       C(8), ;
         cownerid     C(10), ;
         dAcctDate    D, ;
         cprodyear    C(4), ;
         cprodprd     C(2), ;
         cwellid      C(10), ;
         cwellname    C(40), ;
         crevkey      C(10), ;
         cType        C(5), ;
         ngrunits     N(12,2), ;
         nownunits    N(12,2), ;
         nprice       N(12,4), ;
         ngrossval    N(12,2), ;
         nownerval    N(12,2), ;
         ctaxcode     C(2), ;
         ccatcode     C(4), ;
         ccategory    C(30), ;
         cvendorid    C(10), ;
         cvendor      C(60), ;
         crefid       C(20), ;
         cdesc        C(40), ;
         cint_type    C(1), ;
         nnetamount   N(12,2), ;
         ninterest    N(11,7), ;
         cMasterID    C(8))

      INDEX ON cidcomp TAG cidcomp
      USE
   ENDIF

   IF NOT FILE(m.goapp.cCommonfolder+'partnerhist.dbf')
      CREATE TABLE (m.goapp.cCommonfolder+'partnerhist') FREE ;
         (cidcomp      C(8), ;
         lposted      L, ;
         tPosted      T, ;
         nRunNo       I, ;
         cRunYear     C(4), ;
         cDMBatch     C(8), ;
         cBatch       C(8), ;
         cownerid     C(10), ;
         dAcctDate    D, ;
         cprodyear    C(4), ;
         cprodprd     C(2), ;
         cwellid      C(10), ;
         cwellname    C(40), ;
         crevkey      C(10), ;
         cType        C(5), ;
         ngrunits     N(12,2), ;
         nownunits    N(12,2), ;
         nprice       N(12,4), ;
         ngrossval    N(12,2), ;
         nownerval    N(12,2), ;
         ctaxcode     C(2), ;
         ccatcode     C(4), ;
         ccategory    C(30), ;
         cvendorid    C(10), ;
         cvendor      C(60), ;
         crefid       C(20), ;
         cdesc        C(40), ;
         cint_type    C(1), ;
         nnetamount   N(12,2), ;
         ninterest    N(11,7), ;
         cMasterID    C(8))

      INDEX ON cidcomp TAG cidcomp
      USE
   ENDIF

   IF NOT FILE(m.goapp.cCommonfolder+'partnerinterest.dbf')
      CREATE TABLE (m.goapp.cCommonfolder+'partnerinterest') FREE ;
         (cidcomp   C(8), ;
         cDMBatch  C(8), ;
         cownerid  C(10), ;
         cwellid   C(10), ;
         nrevgas   N(11,7), ;
         nrevoil   N(11,7), ;
         nworkint  N(11,7), ;
         cMasterID C(8))
   ENDIF

   swselect('partnerpost')

   ENDPROC

*************************************************
   FUNCTION MarkSettlementNotes(tcRunYear, tnRunNo)
*************************************************

   swselect('settlementnotes')
   SCAN FOR nRunNo = 0
      REPLACE cRunYear WITH tcRunYear, nRunNo WITH tnRunNo
   ENDSCAN

   ENDPROC

*************************************************
   FUNCTION UnMarkSettlementNotes(tcRunYear, tnRunNo)
*************************************************

   swselect('settlementnotes')
   SCAN FOR cRunYear = tcRunYear AND nRunNo = tnRunNo
      REPLACE cRunYear WITH '', nRunNo WITH 0
   ENDSCAN

   ENDPROC

**************************************************
   PROCEDURE CreateDecks
**************************************************
   LPARAMETERS tcProgCode, tnPctAvailable, tcOwnerID, tnDatasession
   LOCAL llReturn, lnDecks, lnDecksUpd

   STORE 0 TO lnDecks, lnDeckUpd
   
   llReturn = .T.

   SET DATASESSION TO tnDatasession

   tnOwnerPct = 100 - (tnPctAvailable*100)

* Cursor for saving the calculated waterfall units
   CREATE CURSOR waterfallunits ;
      (cownerid    C(10), ;
      nyear       I, ;
      nperiod     I, ;
      nday        I, ;
      nwaterfallunits N(17,15))

   CREATE CURSOR tempdoi ( ;
      cDeck       C(10), ;
      effstartyr  C(4), ;
      effstartprd C(2), ;
      cwellid     C(10), ;
      cownerid    C(10), ;
      nunits      N(8,4), ;
      nworkint    N(13,7), ;
      nrevgas     N(13,7), ;
      nrevoil     N(13,7), ;
      nrevoth     N(13,7), ;
      nrevmisc1   N(13,7), ;
      nrevmisc2   N(13,7), ;
      nrevtax1    N(13,7), ;
      nrevtax2    N(13,7), ;
      nrevtax3    N(13,7), ;
      nrevtax4    N(13,7), ;
      nrevtax5    N(13,7), ;
      nrevtax6    N(13,7), ;
      nrevtax7    N(13,7), ;
      nrevtax8    N(13,7), ;
      nrevtax9    N(13,7), ;
      nrevtax10   N(13,7), ;
      nrevtax11   N(13,7), ;
      nrevtax12   N(13,7))

* Build a beginning deck for each well in the JV that consists of all the partners with no deposit date
   SELECT progowners
   LOCATE FOR EMPTY(dEffDate)
   IF FOUND()
      IF MESSAGEBOX('Do you want to create Original Decks with a starting period of 2010/01? ' + ;
            'This will catch all entries before the first waterfall.',36,'Create Beginning Decks') = 6

         SELECT cownerid, SUM(nPercentage) AS nPercentage, ;
            1 AS nperiod, ;
            '2010' AS nyear ;
            FROM progowners WITH (BUFFERING = .T.) ;
            WHERE EMPTY(dEffDate) ;
            INTO CURSOR jvowners ;
            ORDER BY cownerid ;
            GROUP BY cownerid


         SELECT SUM(nPercentage) AS ntotUnits FROM jvowners WITH (BUFFERING=.T.);
            INTO CURSOR tempunits
         lnTotalUnits = tempunits.ntotUnits

         m.cDeck   = 'ORIGINAL'
         m.lWaterFall = .F.
         m.effstartyr = '2010'  && Picked 2010 because there shouldn't be any corrections entered this far back.
         m.effstartprd = '01'

* Insert an interest for each JV owner that had deposited before this period
         SELECT jvowners
         SCAN
            SCATTER MEMVAR
            m.nyear   = 2010
            m.nperiod = 1
            m.lWaterFall = .F.
            m.effstartyr = '2010'
            m.effstartprd = '01'

            lnUnits = m.nPercentage
            m.nUnits = lnUnits
            m.ninterest = ROUND(lnUnits/lnTotalUnits * tnPctAvailable * 100,7)
            STORE m.ninterest TO m.nworkint, m.nrevgas, m.nrevoil, m.nrevoth, m.nrevtax1, m.nrevtax2, m.nrevtax3, ;
               m.nrevtax4, m.nrevtax5, m.nrevtax6, m.nrevtax7, m.nrevtax8, m.nrevtax9, ;
               m.nrevtax10, m.nrevtax11, m.nrevtax12, m.nrevmisc1, m.nrevmisc2, m.nrevoth

* Create a deck record for every well and partner
            swselect('wells')
            SCAN
               m.cwellid = cwellid
               INSERT INTO tempdoi FROM MEMVAR
            ENDSCAN  && Wells
         ENDSCAN  && jvowners

* Create a deck record for every well and company pct
         swselect('wells')
         SCAN
            m.cwellid = cwellid
* Add the company pct. They don't have units just a pct of each well.
            IF NOT EMPTY(tcOwnerID) AND tnOwnerPct # 0
               m.cownerid = tcOwnerID
               m.ninterest = tnOwnerPct
               m.nunits = 0
               STORE m.ninterest TO m.nworkint, m.nrevgas, m.nrevoil, m.nrevoth, m.nrevtax1, m.nrevtax2, m.nrevtax3, ;
                  m.nrevtax4, m.nrevtax5, m.nrevtax6, m.nrevtax7, m.nrevtax8, m.nrevtax9, ;
                  m.nrevtax10, m.nrevtax11, m.nrevtax12, m.nrevmisc1, m.nrevmisc2, m.nrevoth
               INSERT INTO tempdoi FROM MEMVAR
            ENDIF
         ENDSCAN  && Wells
      ENDIF
   ENDIF && Original Deck

   SELECT progowners
* Check to see if we need to create a new DOI or update one
   LOCATE FOR NOT EMPTY(dEffDate)
   IF FOUND()  && There are waterfall entries to be created

* Get the production periods that DOI should be created for
      SELECT MONTH(dEffDate) AS nperiod, ;
         YEAR(dEffDate)  AS nyear ;
         FROM progowners ;
         WHERE NOT EMPTY(dEffDate) ;
         INTO CURSOR prodperiods ;
         ORDER BY nyear, nperiod;
         GROUP BY nyear, nperiod

* Scan through each production period to see which owners
* deposited during that period and create waterfall interests for each
      SELECT prodperiods
      SCAN
         m.cDeck   = TRANSFORM(prodperiods.nyear) +'-'+ PADL(TRANSFORM(prodperiods.nperiod),2,'0') + '-' + 'WF'
         m.nyear   = nyear
         m.nperiod = nperiod
         m.lWaterFall = .T.
         m.effstartyr = TRANSFORM(m.nyear)
         m.effstartprd = PADL(TRANSFORM(m.nperiod),2,'0')

* Get the # of units in the partnership before the deposits during this prod period
         SELECT SUM(progowners.nPercentage) AS nunits ;
            FROM progowners ;
            WHERE (TRANSFORM(YEAR(dEffDate)) +'-'+ PADL(TRANSFORM(MONTH(dEffDate)),2,'0') < LEFT(m.cDeck,7)) ;
            OR EMPTY(dEffDate) ;
            INTO CURSOR periodunits

         IF _TALLY > 0
            lnTotalUnits = periodunits.nunits
         ELSE
            lnTotalUnits = 0
         ENDIF
         swclose('periodunits')

* Get the waterfall units to add to the total units
         SELECT progowners
         SCAN FOR YEAR(dEffDate) = prodperiods.nyear ;
               AND MONTH(dEffDate) = prodperiods.nperiod
            SCATTER MEMVAR
            m.nday = DAY(dEffDate)
            lnUnits = m.nPercentage
            ldEndMonth = goendmonth(m.dEffDate,0,.T.)
            lnEndMonth = DAY(ldEndMonth)
            lnDays = ldEndMonth+1 - m.dEffDate

* Calculate the # of units this partner has for the waterfall
            m.nwaterfallunits  = (lnUnits/lnEndMonth) * lnDays

            lnTotalUnits = lnTotalUnits + m.nwaterfallunits

            INSERT INTO waterfallunits FROM MEMVAR
         ENDSCAN

* Calculate the interests for the partners in this deck
         SELECT progowners
         SCAN FOR (TRANSFORM(YEAR(dEffDate)) +'-'+ PADL(TRANSFORM(MONTH(dEffDate)),2,'0') <= LEFT(m.cDeck,7))
* This should get all partners with this production period in their deposit date and all production
* periods before. It should also include blank depositdates

            SCATTER MEMVAR
            lnYear = YEAR(m.dEffDate)
            lnPeriod = MONTH(m.dEffDate)
            lnDay    = DAY(m.dEffDate)
            m.lWaterFall = .T.
*            m.effstartyr = TRANSFORM(lnYear)
*            m.effstartprd = PADL(TRANSFORM(lnPeriod),2,'0')


* If the period matches, lookup the units from the waterfall cursor,
* otherwise just get their units from progowners
            IF lnYear = m.nyear AND lnPeriod = m.nperiod
               SELECT waterfallunits
               LOCATE FOR cownerid = m.cownerid AND ;
                  nyear    = lnYear AND ;
                  nperiod  = lnPeriod AND ;
                  nday     = lnDay
               IF FOUND()
                  lnUnits = waterfallunits.nwaterfallunits
                  m.nUnits = lnUnits
               ELSE
                  m.nUnits = 0
* What about this?
               ENDIF
            ELSE
               lnUnits = m.nPercentage
               m.nUnits = lnUnits
            ENDIF

            m.ninterest = ROUND(lnUnits/lnTotalUnits * tnPctAvailable,9) * 100
            STORE m.ninterest TO m.nworkint, m.nrevgas, m.nrevoil, m.nrevoth, m.nrevtax1, m.nrevtax2, m.nrevtax3, ;
               m.nrevtax4, m.nrevtax5, m.nrevtax6, m.nrevtax7, m.nrevtax8, m.nrevtax9, ;
               m.nrevtax10, m.nrevtax11, m.nrevtax12, m.nrevmisc1, m.nrevmisc2, m.nrevoth

* Create a deck record for every well and partner
            swselect('wells')
            SCAN
               m.cwellid = cwellid
               INSERT INTO tempdoi FROM MEMVAR
            ENDSCAN && Wells
         ENDSCAN  && Progowners

* Create a deck record for every well and company pct
         swselect('wells')
         SCAN
            m.cwellid = cwellid
* Add the company pct. They don't have units just a pct of each well.
            IF NOT EMPTY(tcOwnerID) AND tnOwnerPct # 0
               m.cownerid = tcOwnerID
               m.ninterest = tnOwnerPct
               m.nunits    = 0
               STORE m.ninterest TO m.nworkint, m.nrevgas, m.nrevoil, m.nrevoth, m.nrevtax1, m.nrevtax2, m.nrevtax3, ;
                  m.nrevtax4, m.nrevtax5, m.nrevtax6, m.nrevtax7, m.nrevtax8, m.nrevtax9, ;
                  m.nrevtax10, m.nrevtax11, m.nrevtax12, m.nrevmisc1, m.nrevmisc2, m.nrevoth
               INSERT INTO tempdoi FROM MEMVAR
            ENDIF
         ENDSCAN
      ENDSCAN  && Prodperiods
   ENDIF

   SELECT cownerid, SUM(nPercentage) AS nPercentage, ;
      MONTH(dEffDate) AS nperiod, ;
      YEAR(dEffDate)  AS nyear, ;
      cprogcode ;
      FROM progowners WITH (BUFFERING = .T.) ;
      INTO CURSOR jvowners ;
      ORDER BY cprogcode, cownerid, nyear, nperiod ;
      GROUP BY cprogcode, cownerid, nyear, nperiod

* Create a deck for each period after the waterfall period
   IF USED('prodperiods')
      SELECT prodperiods
      SCAN
         SCATTER MEMVAR

* If the period is 12 make the deck be for period 01 of the next year
         IF m.nperiod = 12
            lnPeriod = 1
            lnYear = m.nyear + 1
         ELSE
            lnYear   = m.nyear
            lnPeriod = m.nperiod + 1
         ENDIF

         SELECT SUM(nPercentage) AS ntotUnits FROM jvowners WITH (BUFFERING=.T.);
            WHERE ((nyear = 0 AND nperiod = 0) OR ;
            (TRANSFORM(nyear)+PADL(TRANSFORM(nperiod),2,'0') <= TRANSFORM(lnYear) + PADL(TRANSFORM(lnPeriod),2,'0'))) ;
            AND cprogcode = tcProgCode ;
            INTO CURSOR tempunits
         lnTotalUnits = tempunits.ntotUnits

         m.cDeck   = TRANSFORM(lnYear) +'-'+ PADL(TRANSFORM(lnPeriod),2,'0')
         m.lWaterFall = .F.
         m.effstartyr = TRANSFORM(lnYear)
         m.effstartprd = PADL(TRANSFORM(lnPeriod),2,'0')

* Insert an interest for each JV owner that had deposited before this period
         SELECT jvowners
         SCAN FOR (nyear = 0 AND nperiod = 0) OR ;
               (TRANSFORM(nyear)+PADL(TRANSFORM(nperiod),2,'0') <= TRANSFORM(m.nyear) + PADL(TRANSFORM(m.nperiod),2,'0'))
            SCATTER MEMVAR
            m.nyear   = lnYear
            m.nperiod = lnPeriod
            m.lWaterFall = .F.

            lnUnits = m.nPercentage
            m.nUnits = lnUnits
            m.ninterest = ROUND(lnUnits/lnTotalUnits * tnPctAvailable * 100,9)
            STORE m.ninterest TO m.nworkint, m.nrevgas, m.nrevoil, m.nrevoth, m.nrevtax1, m.nrevtax2, m.nrevtax3, ;
               m.nrevtax4, m.nrevtax5, m.nrevtax6, m.nrevtax7, m.nrevtax8, m.nrevtax9, ;
               m.nrevtax10, m.nrevtax11, m.nrevtax12, m.nRevMisc1, m.nRevMisc2

* Create a deck record for every well and partner
            swselect('wells')
            SCAN
               m.cwellid = cwellid
               INSERT INTO tempdoi FROM MEMVAR
            ENDSCAN  && Wells
         ENDSCAN  && jvowners

* Create a deck record for every well and company pct
         swselect('wells')
         SCAN
            m.cwellid = cwellid
* Add the company pct. They don't have units just a pct of each well.
            IF NOT EMPTY(tcOwnerID) AND tnOwnerPct # 0
               m.cownerid = tcOwnerID
               m.ninterest = tnOwnerPct
               m.nUnits = 0
               STORE m.ninterest TO m.nworkint, m.nrevgas, m.nrevoil, m.nrevoth, m.nrevtax1, m.nrevtax2, m.nrevtax3, ;
                  m.nrevtax4, m.nrevtax5, m.nrevtax6, m.nrevtax7, m.nrevtax8, m.nrevtax9, ;
                  m.nrevtax10, m.nrevtax11, m.nrevtax12, m.nrevmisc1, m.nrevmisc2, m.nrevoth
               INSERT INTO tempdoi FROM MEMVAR
            ENDIF
         ENDSCAN  && Wells
      ENDSCAN  && prodperiods
   ENDIF

* Check to see if any well decks don't add up to 100%. Adjust the difference to the passed company owner
   SELECT cDeck, cwellid FROM tempdoi INTO CURSOR mydecks ORDER BY cDeck, cwellid GROUP BY cDeck, cwellid
   SELECT mydecks
   SCAN
      SCATTER MEMVAR

      SELECT cDeck, cwellid, ;
         SUM(nrevoil) AS nrevoil, ;
         SUM(nrevgas) AS nrevgas, ;
         SUM(nrevoth) AS nrevoth, ;
         SUM(nrevmisc1) as nrevmisc1, ;
         SUM(nrevmisc2) as nrevmisc2, ;
         SUM(nworkint) AS nworkint ;
         FROM tempdoi ;
         WHERE cDeck = m.cDeck AND cwellid = m.cwellid ;
         INTO CURSOR decktmp ;
         ORDER BY cDeck, cwellid ;
         GROUP BY cDeck, cwellid

      SELECT decktmp
      IF nrevoil # 100
         lnDiffOil = 100 - nrevoil
      ELSE
         lnDiffOil = 0
      ENDIF
      IF nrevgas # 100
         lnDiffGas = 100 - nrevgas
      ELSE
         lnDiffGas = 0
      ENDIF
      IF nrevoth # 100
         lnDiffOth = 100 - nrevoth
      ELSE
         lnDiffOth = 0
      ENDIF
      IF nrevmisc1 # 100
         lnDiffMisc1 = 100 - nrevmisc1
      ELSE
         lnDiffMisc1 = 0
      ENDIF
       IF nrevmisc2 # 100
         lnDiffMisc2 = 100 - nrevmisc2
      ELSE
         lnDiffMisc2 = 0
      ENDIF
      IF nworkint # 100
         lnDiffWrk = 100 - nworkint
      ELSE
         lnDiffWrk = 0
      ENDIF

      IF lnDiffOil # 0 OR lnDiffGas # 0 OR lnDiffOth # 0 OR lnDiffMisc1 # 0 OR lnDiffMisc2 # 0
         SELECT tempdoi
         LOCATE FOR cDeck = m.cDeck AND cwellid = m.cwellid AND cownerid = tcOwnerID
         IF FOUND()

            IF lnDiffOil # 0
               lnNewInt = nrevoil + lnDiffOil
               REPLACE nrevoil WITH lnNewInt, ;
                  nrevtax1 WITH lnNewInt, ;
                  nrevtax4 WITH lnNewInt, ;
                  nrevtax7 WITH lnNewInt, ;
                  nrevtax10 WITH lnNewInt
            ENDIF

            IF lnDiffGas # 0
               lnNewInt = nrevgas + lnDiffGas
               REPLACE nrevgas WITH lnNewInt, ;
                  nrevtax2 WITH lnNewInt, ;
                  nrevtax5 WITH lnNewInt, ;
                  nrevtax8 WITH lnNewInt, ;
                  nrevtax11 WITH lnNewInt
            ENDIF

            IF lnDiffOth # 0
               lnNewInt = nrevoth + lnDiffOth
               REPLACE nrevoth WITH lnNewInt, ;
                  nrevtax3 WITH lnNewInt, ;
                  nrevtax6 WITH lnNewInt, ;
                  nrevtax9 WITH lnNewInt, ;
                  nrevtax12 WITH lnNewInt
            ENDIF
            
            IF lnDiffMisc1 # 0
               lnNewInt = nrevmisc1 + lnDiffMisc1
               REPLACE nrevmisc1 WITH lnNewInt
            ENDIF 
            
            IF lnDiffMisc2 # 0
               lnNewInt = nrevmisc2 + lnDiffMisc2
               REPLACE nrevmisc2 WITH lnNewInt
            ENDIF 

            IF lnDiffWrk # 0
               lnNewInt = nworkint + lnDiffWrk
               REPLACE nworkint WITH lnNewInt
            ENDIF
         ENDIF
      ENDIF
   ENDSCAN

   TRY
* Open the wellinv and doidecks tables if they aren't already open
      swselect('wellinv')
      swselect('doidecks')

      IF RECCOUNT('tempdoi') > 0

         SELECT cDeck FROM tempdoi ;
            INTO CURSOR tempdecks ;
            ORDER BY cDeck ;
            GROUP BY cDeck

         SELECT cDeck, cwellid, effstartyr, effstartprd FROM tempdoi ;
            INTO CURSOR tempdoidecks ;
            ORDER BY cDeck, cwellid ;
            GROUP BY cDeck, cwellid

         STORE .F. TO llReplace,	llAsked, llFound
         SELECT tempdoidecks
         SCAN
            IF cDeck # m.cDeck
               llAsked = .F.
            ENDIF
            SCATTER MEMVAR
            SELECT doidecks
            LOCATE FOR cDeck = m.cDeck AND cwellid = m.cwellid
            IF FOUND()
               llFound = .T.
               IF RIGHT(ALLTRIM(m.cDeck),3) = '-WF'
                  m.lWaterFall = .T.
               ELSE
                  m.lWaterFall = .F.
               ENDIF
               IF NOT llAsked
                  IF MESSAGEBOX('The deck ' + ALLTRIM(m.cDeck) + ;
                        ' already exists. Do you want to replace the deck for all wells?', ;
                        36,'Deck Found') = 6
                     llReplace = .T.
                     llAsked   = .T.
                     DELETE FROM wellinv WHERE cDeck = m.cDeck
                     SELECT doidecks
                  ELSE
                     llAsked = .T.
                     llReplace = .F.
                  ENDIF
               ELSE
                  llReplace = .F.
               ENDIF
               IF llReplace
                  REPLACE effstartyr  WITH m.effstartyr, ;
                     effstartprd WITH m.effstartprd, ;
                     lWaterFall  WITH m.lWaterFall
               ENDIF
            ELSE
               IF RIGHT(ALLTRIM(m.cDeck),3) = '-WF'
                  m.lWaterFall = .T.
               ELSE
                  m.lWaterFall = .F.
               ENDIF
               INSERT INTO doidecks FROM MEMVAR
            ENDIF
         ENDSCAN

* Ask if they want us to do this
* Remove any decks that we don't need because they aren't needed
         DELETE FROM wellinv WHERE cDeck NOT IN (SELECT cDeck FROM tempdecks)
         DELETE FROM doidecks WHERE cDeck NOT IN (SELECT cDeck FROM tempdecks)

* Remove any owners that were in the deck but aren't now
         DELETE FROM wellinv WHERE cownerid+cDeck NOT IN (SELECT cownerid+cDeck FROM tempdoi)

         lnDecks   = 0
         lnDecksUpd = 0
         SELECT tempdecks
         SCAN
            SCATTER MEMVAR
            SELECT wellinv
            LOCATE FOR cDeck = m.cDeck
            IF FOUND()
               IF (llFound AND llReplace) OR NOT llFound
* Reset the replace variable for the next deck
                  lnDecksUpd = lnDecksUpd + 1
                  SELECT tempdoi
                  SCAN FOR cDeck = m.cDeck
                     SCATTER MEMVAR
                     SELECT wellinv
                     LOCATE FOR cDeck = m.cDeck AND cwellid = m.cwellid AND cownerid = m.cownerid
                     IF FOUND()
                        REPLACE nUnits WITH m.nUnits, nworkint WITH m.nworkint, ;
                           nrevgas  WITH m.nrevgas, ;
                           nrevoil  WITH m.nrevoil, ;
                           nrevoth  WITH m.nrevoth, ;
                           nrevtax1 WITH m.nrevtax1, ;
                           nrevtax2 WITH m.nrevtax2, ;
                           nrevtax3 WITH m.nrevtax3, ;
                           nrevtax4 WITH m.nrevtax4, ;
                           nrevtax5 WITH m.nrevtax5, ;
                           nrevtax6 WITH m.nrevtax6, ;
                           nrevtax7 WITH m.nrevtax7, ;
                           nrevtax8 WITH m.nrevtax8, ;
                           nrevtax9 WITH m.nrevtax9, ;
                           nrevtax10 WITH m.nrevtax10, ;
                           nrevtax11 WITH m.nrevtax11, ;
                           nrevtax12 WITH m.nrevtax12, ;
                           nrevmisc1 WITH m.nrevmisc1, ;
                           nrevmisc2 WITH m.nrevmisc2
                     ELSE
                        m.cidwinv = GetNextPK('DOI')
                        m.ctypeinv = 'W'
                        m.cDirect  = 'N'
                        m.ctypeint = 'B'
                        m.ljib     = .F.
                        m.dAdded = DATETIME()
                        m.cadduser = m.goapp.cuser
                        INSERT INTO wellinv FROM MEMVAR
                     ENDIF
                  ENDSCAN
               ENDIF
            ELSE
               lnDecks = lnDecks + 1
               SELECT tempdoi
               SCAN FOR cDeck = m.cDeck
                  SCATTER MEMVAR
                  m.cidwinv = GetNextPK('DOI')
                  m.ctypeinv = 'W'
                  m.cDirect  = 'N'
                  m.ctypeint = 'B'
                  m.ljib     = .F.
                  m.dAdded = DATETIME()
                  m.cadduser = m.goapp.cuser
                  INSERT INTO wellinv FROM MEMVAR
               ENDSCAN
            ENDIF
         ENDSCAN
      ENDIF

      IF llReturn
         MESSAGEBOX('Processing has been completed by updating and adding decks for this JV.' + CHR(13) + ;
            'Added/Updated ' + TRANSFORM(lnDecks+lnDecksUpd) + ' Decks ',64,'Partnership Units')
      ENDIF
   CATCH TO loError
      DO errorlog WITH 'CreateDecks', loError.LINENO, 'swPartners', loError.ERRORNO, loError.MESSAGE, ' ', loError
   ENDTRY

   RETURN llReturn
   ENDPROC

**********************************************
   PROCEDURE waterfallunits
**********************************************
   LPARAMETERS tcYear, tcPeriod, tcOwner
   LOCAL m.cDeck, lnTotalUnits

   IF VARTYPE(tcOwner) # 'C'
      tcOwner = ''
   ENDIF

   m.cDeck = tcYear+'-'+tcPeriod
   lnYear   = INT(VAL(tcYear))
   lnPeriod = INT(VAL(tcPeriod))

   swselect('progrel')

   IF EMPTY(tcOwner)
* Get the # of units in the partnership before the deposits during this prod period
      SELECT SUM(progrel.nPercentage) AS nunits ;
         FROM progrel ;
         WHERE (TRANSFORM(YEAR(dEffDate)) +'-'+ PADL(TRANSFORM(MONTH(dEffDate)),2,'0') < LEFT(m.cDeck,7)) ;
         OR EMPTY(dEffDate) ;
         INTO CURSOR periodunits

      IF _TALLY > 0
         lnTotalUnits = periodunits.nunits
      ELSE
         lnTotalUnits = 0
      ENDIF
      swclose('periodunits')

* Get the waterfall units to add to the total units
      SELECT progrel
      SCAN FOR YEAR(dEffDate) = lnYear;
            AND MONTH(dEffDate) = lnPeriod
         SCATTER MEMVAR
         m.nday = DAY(dEffDate)
         lnUnits = m.nPercentage
         ldEndMonth = goendmonth(m.dEffDate,0,.T.)
         lnEndMonth = DAY(ldEndMonth)
         lnDays = ldEndMonth+1 - m.dEffDate

* Calculate the # of units this partner has for the waterfall
         m.nwaterfallunits  = (lnUnits/lnEndMonth) * lnDays

         lnTotalUnits = lnTotalUnits + m.nwaterfallunits

      ENDSCAN
   ELSE
* Get the # of units in the partnership before the deposits during this prod period
      SELECT SUM(progrel.nPercentage) AS nunits ;
         FROM progrel ;
         WHERE cownerid = tcOwner ;
         AND ((TRANSFORM(YEAR(dEffDate)) +'-'+ PADL(TRANSFORM(MONTH(dEffDate)),2,'0') < LEFT(m.cDeck,7)) ;
         OR EMPTY(dEffDate)) ;
         INTO CURSOR periodunits

      IF _TALLY > 0
         lnTotalUnits = periodunits.nunits
      ELSE
         lnTotalUnits = 0
      ENDIF
      swclose('periodunits')

* Get the waterfall units to add to the total units
      SELECT progrel
      SCAN FOR cownerid = tcOwner ;
            AND YEAR(dEffDate) = lnYear;
            AND MONTH(dEffDate) = lnPeriod
         SCATTER MEMVAR
         m.nday = DAY(dEffDate)
         lnUnits = m.nPercentage
         ldEndMonth = goendmonth(m.dEffDate,0,.T.)
         lnEndMonth = DAY(ldEndMonth)
         lnDays = ldEndMonth+1 - m.dEffDate

* Calculate the # of units this partner has for the waterfall
         m.nwaterfallunits  = (lnUnits/lnEndMonth) * lnDays

         lnTotalUnits = lnTotalUnits + m.nwaterfallunits

      ENDSCAN
   ENDIF

   RETURN lnTotalUnits

   ENDPROC
ENDDEFINE


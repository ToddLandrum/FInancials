SET PROCEDURE TO custom\wlcbizobj additive
SET PROCEDURE TO custom\wlcsql additive
SET PROCEDURE TO custom\swutils additive
SET PROCEDURE TO c:\develop\wconnect7\classes\wwsql ADDITIVE 
SET PROCEDURE TO custom\swbizobj_wellinv ADDITIVE 
SET PROCEDURE TO custom\wlcutility ADDITIVE 

PUBLIC glSQLServer

glSQLServer = .F.

**************************************************
*-- Class:        swbizobj_wellinv (c:\develop\3rdparty\wlc_bizobj\libs\swbizobj_wellinv.prg)
*-- ParentClass:  basevfpbizobj (c:\develop\3rdparty\wlc_bizobj\libs\wlcbizobj.prg)
*-- BaseClass:    custom
*-- Time Stamp:   08/21/20 05:51:11 PM
*
DEFINE CLASS swbizobj_wellinv AS basevfpbizobj


   ctable = "wellinv"
   cupdatekeyfield = ('cidwinv')
   caddedby = "cAddUser"
   caddedon = "dAdded"
   cupdatedby = "cChgUser"
   cupdatedon = "dChanged"
   cdefaultsort = "cWellID"
   cErrorMsg    = ''
   NAME = "swbizobj_wellinv"

   PROCEDURE AppendDecks
      LPARAMETERS tcAlias   AS CHARACTER
      *//******************************************************************************************
      *//  FUNCTION NAME: AppendRecords
      *//
      *//  AUTHOR: SherWare, Inc. 5/17/2021
      *//
      *//  PROCEDURE DESCRIPTION:
      *//    Attempts to append the records in the passed alias to the wellinv table.
      *//
      *//  PARAMETERS:
      *//    INPUT PARAMETERS:
      *//       tcAlias   = Alias of cursor to append into wellinv
      *//
      *//    OUTPUT PARAMETERS:
      *//       Returns .T. or .F. depending on the sucess of the append
      *//******************************************************************************************
      *//  MODIFICATIONS:
      *//     05/17/2021 - pws - Created
      *//******************************************************************************
      LOCAL llReturn

      llReturn = .T.

        lcAlias = ALIAS()
        
      IF NOT USED(tcAlias)
         THIS.cErrorMsg = 'Alias ' + ALLTRIM(tcAlias) + ' is not open.'
         llReturn = .F.
         RETURN llReturn
      ENDIF

      SELECT (tcAlias)

      * Get the Decks being added
      SELECT cWellid, ;
         cDeck    ;
         FROM (tcAlias) ;
         INTO CURSOR tempdecks ;
         ORDER BY cDeck ;
         GROUP BY cDeck

      IF _TALLY > 0
         * See if there is already a deck for the decks in the cursor
         SELECT tempdecks
         SCAN
            SCATTER MEMVAR
            SELECT wellinv
            LOCATE FOR cDeck = m.cDeck AND cWellid = m.cWellid
            IF FOUND()
               IF MESSAGEBOX('The deck ' + ALLTRIM(m.cDeck) + ' already exists. Do you want to replace it?',36,'Replace Deck') = 6
                  SELECT (tcAlias)
                  SCAN
                     SCATTER MEMVAR
                  ENDSCAN
               ENDIF
            ENDIF
         ENDSCAN
      ENDIF
      
      SELECT (lcAlias)

      *******************************
   PROCEDURE DOIDeckNameLookup
      *******************************
      LPARAMETERS  tcYear       AS CHARACTER ;
         ,tcPeriod      AS CHARACTER ;
         ,tcWellID      AS CHARACTER
      *//******************************************************************************************
      *//  FUNCTION NAME: DOIDeckNameLookup
      *//
      *//  AUTHOR: SherWare, Inc. 6/5/2021
      *//
      *//  PROCEDURE DESCRIPTION:
      *//    Uses the passed parameters to look up the deck that should be used for the period.
      *//    If there is a deck found for the given production period it returns that deck.
      *//    If there is a waterfall deck for that period, it returns that deck.
      *//    If there isn't a deck for the period, it returns the last valid deck or the default
      *//    deck.
      *//
      *//  PARAMETERS:
      *//    INPUT PARAMETERS:
      *//       tcYear   = Production Year
      *//       tcPeriod   = Production Period
      *//
      *//    OUTPUT PARAMETERS:
      *//       Returns a character variable with the name of the found deck
      *//******************************************************************************************
      *//  MODIFICATIONS:
      *//     06/05/2021 - pws - Created
      *//******************************************************************************************
      LOCAL lcReturnDeck, llFound

      lcReturnDeck = SPACE(10)
      llFound       = .F.

        lcAlias = ALIAS()
      swselect('doidecks')

      * First check for the given waterfall deck
      lcDeck = tcYear + '-' + tcPeriod + '-' + 'WF'
      LOCATE FOR effStartYr = tcYear AND effstartPrd = tcPeriod AND lWaterFall = .T. AND cWellid = tcWellID
      IF FOUND()
         lcReturnDeck = cDeck
      ELSE
         * Check for a non-waterfall deck for the period
         LOCATE FOR effStartYr = tcYear AND effstartPrd = tcPeriod AND cWellid = tcWellID
         IF FOUND()
            lcReturnDeck = cDeck
         ELSE
            * Check for the last non-waterfall deck
            FOR nYear = VAL(tcYear) TO 1980 STEP -1
               lcYear = TRANSFORM(nYear)
               IF NOT llFound
                  FOR nperiod = VAL(tcPeriod) TO 1 STEP -1
                     lcPeriod = PADL(TRANSFORM(nperiod),2,'0')

                     LOCATE FOR effStartYr = lcYear AND effstartPrd = lcPeriod AND cWellid = tcWellID 
                     IF FOUND()
                        lcReturnDeck = cDeck
                        llFound = .T.
                        EXIT 
                     ENDIF
                  ENDFOR
               ENDIF
               tcPeriod = '12'
            ENDFOR
            IF NOT llFound
               LOCATE FOR cWellid = tcWellID AND lDefault
               IF FOUND()
                  lcReturnDeck = cDeck
               ELSE
                  lcReturnDeck = SPACE(10)
               ENDIF
            ENDIF       
         ENDIF
      ENDIF
      
      SELECT (lcAlias)
      
      RETURN lcReturnDeck

      ***************************
   PROCEDURE DOIDeckLookup
      ***************************
      LPARAMETERS tcOwner    AS CHARACTER ;
         ,tcWell      AS CHARACTER ;
         ,tcTypeInv   AS CHARACTER ;
         ,tcProgCode   AS CHARACTER ;
         ,tcYear      AS CHARACTER ;
         ,tcPeriod   AS CHARACTER ;
         ,tcType      AS CHARACTER ;
         ,tlWaterfall AS Logical
      *//******************************************************************************************
      *//  FUNCTION NAME: DOIDeckLookup
      *//
      *//  AUTHOR: SherWare, Inc. 5/8/2021
      *//
      *//  PROCEDURE DESCRIPTION:
      *//    Uses the passed parameters to look up the owner's interests in the given well.
      *//    If there is a deck found for the given production period it returns those interests.
      *//    If there is no deck found for the production period it returns the interests for the
      *//    default or blank deck.
      *//
      *//  PARAMETERS:
      *//    INPUT PARAMETERS:
      *//       tcOwner    = Owner ID of the owner the interests should be returned for.
      *//       tcWell     = Well ID of the well the interests should be returned for.
      *//       tcTypeInv = Interest type
      *//       tcyear    = Production Year
      *//       tcPeriod  = Production Period
      *//
      *//    OUTPUT PARAMETERS:
      *//       Returns an object with the record in it.
      *//******************************************************************************************
      *//  MODIFICATIONS:
      *//     05/08/2021 - pws - Created
      *//******************************************************************************************
      LOCAL lcAlias, lcDeckLookup, lcDeck, m.nInterest

      lcAlias = ALIAS()

      IF !tlWaterfall
         lcDeckLookup = tcYear+'-'+tcPeriod+tcOwner+tcWell+tcTypeInv+tcProgCode
      ELSE
         lcDeckLookup = tcYear+'-'+tcPeriod+'-WF'+tcOwner+tcWell+tcTypeInv+tcProgCode
      ENDIF
      swselect('wellinv')
      SET ORDER TO DeckLookup
      IF SEEK(lcDeckLookup)
         SCATTER NAME oInterests

      ELSE
         lcDeck = SPACE(7)
         lcDeckLookup = lcDeck+tcOwner+tcWell+tcTypeInv+tcProgCode
         IF SEEK(lcDeckLookup)
            SCATTER NAME oInterests

         ENDIF
      ENDIF

      SELECT (lcAlias)

      RETURN oInterests

      ***********************
   PROCEDURE DOIDeckHist
      ***********************
      LPARAMETERS tcOwner    AS CHARACTER ;
         ,tcWell      AS CHARACTER ;
         ,tcTypeInv   AS CHARACTER ;
         ,tcProgCode   AS CHARACTER ;
         ,tcYear      AS CHARACTER ;
         ,tcPeriod   AS CHARACTER ;
         ,tcType      AS CHARACTER
      *//******************************************************************************************
      *//  FUNCTION NAME: DOIDeckLookup
      *//
      *//  AUTHOR: SherWare, Inc. 5/8/2021
      *//
      *//  PROCEDURE DESCRIPTION:
      *//    Uses the passed parameters to look up the owner's interests in the given well.
      *//    If there is a deck found for the given production period it returns those interests.
      *//    If there is no deck found for the production period it returns the interests for the
      *//    default or blank deck.
      *//
      *//  PARAMETERS:
      *//    INPUT PARAMETERS:
      *//       tcOwner    = Owner ID of the owner the interests should be returned for.
      *//       tcWell     = Well ID of the well the interests should be returned for.
      *//       tcTypeInv = Interest type
      *//       tcyear    = Production Year
      *//       tcPeriod  = Production Period
      *//
      *//    OUTPUT PARAMETERS:
      *//       Returns an object with the record in it.
      *//******************************************************************************************
      *//  MODIFICATIONS:
      *//     05/08/2021 - pws - Created
      *//******************************************************************************************


      ***************************
   PROCEDURE BuildOriginalDecks
      ***************************
      *//******************************************************************************************
      *//  FUNCTION NAME: BuildOriginalDecks
      *//
      *//  AUTHOR: SherWare, Inc. 6/24/2021
      *//
      *//  PROCEDURE DESCRIPTION:
      *//    Creates the "ORIGINAL" deck for the first time a company is opened and there are no
      *//    DOIDECK records.  This is only the 1st time someone opens a company that has never
      *//    had the original deck created.
      *//
      *//  PARAMETERS:
      *//    INPUT PARAMETERS:
      *//       None
      *//
      *//    OUTPUT PARAMETERS:
      *//       Returns .T. if successful
      *//******************************************************************************************
      *//  MODIFICATIONS:
      *//     06/24/2021 - pws - Created
      *//******************************************************************************************

        lcAlias = ALIAS()
      swselect('doidecks')
      COUNT FOR NOT DELETED() TO lnCount

      IF lnCount = 0
         SELECT cWellID FROM (this.ctable) INTO CURSOR tempdoi ORDER BY cwellid GROUP BY cwellid
         
         SCAN 
            m.cwellid = cwellid
            m.lDefault = .f.
            m.effstartyr = '2010'
            m.effstartprd = '01'
            m.cDeck = 'ORIGINAL'
            m.lWaterFall = .F.
            INSERT INTO doidecks FROM MEMVAR 
         ENDSCAN 
         
         SELECT wellinv
         REPLACE cdeck WITH 'ORIGINAL' FOR EMPTY(cdeck)
      
       ENDIF 
       
       SELECT (lcAlias)

   PROCEDURE Validation
      LPARAMETERS tcCursor AS CHARACTER
      *//******************************************************************************************
      *//  FUNCTION NAME:
      *//
      *//  AUTHOR: White Light Computing, Inc. 08/21/2020
      *//
      *//  COPYRIGHT © 2010-2020   All Rights Reserved.
      *//  White Light Computing, Inc.
      *//  PO Box 391
      *//  Washington Twp., MI  48094
      *//  raschummer@whitelightcomputing.com
      *//
      *//  PROCEDURE DESCRIPTION:
      *//
      *//
      *//  PARAMETERS:
      *//    INPUT PARAMETERS:
      *//       None
      *//
      *//    OUTPUT PARAMETERS:
      *//       None
      *//******************************************************************************************
      *//  MODIFICATIONS:
      *//     08/21/2020 - JLM - Created
      *//******************************************************************************************
      THIS.ClearValidationErrors()
      THIS.cErrorMsg = SPACE(0)

      *-- cWellID validation -  - Required
      IF EMPTY(NVL(cWellid,SPACE(0)))
         THIS.AddValidationError('The Well ID is required.', 'cWellID')
         THIS.cErrorMsg = 'The Well ID is required.' + CHR(13)
      ENDIF
      *-- cOwnerID validation -  - Required
      IF EMPTY(NVL(cOwnerID,SPACE(0)))
         THIS.AddValidationError('The Well ID is required.', 'cWellID')
         THIS.cErrorMsg = 'The Well ID is required.' + CHR(13)
      ENDIF

      RETURN ISNULL(THIS.oValidationErrors) OR (THIS.oValidationErrors.COUNT = 0)

   ENDPROC


   PROCEDURE Search
      LPARAMETERS ;
         tcWellID AS CHARACTER
      *//******************************************************************************************
      *//  FUNCTION NAME: swbizobj_wellinv.Search()
      *//
      *//  AUTHOR: White Light Computing, Inc. 08/21/2020
      *//
      *//  COPYRIGHT © 2010-2020   All Rights Reserved.
      *//  White Light Computing, Inc.
      *//  PO Box 391
      *//  Washington Twp., MI  48094
      *//  raschummer@whitelightcomputing.com
      *//
      *//  PROCEDURE DESCRIPTION:
      *//    Called when the user selects the Search command button on a form.
      *//
      *//  PARAMETERS:
      *//    INPUT PARAMETERS:
      *//       t_parameter - Could just be a NULL
      *//
      *//    OUTPUT PARAMETERS:
      *//       cursor
      *//******************************************************************************************
      *//  MODIFICATIONS:
      *//     08/21/2020 - JLM - Created
      *//******************************************************************************************
      LOCAL ;
         LCSQL AS CHARACTER ;
         ,lcDF AS CHARACTER ;
         ,loParameter AS OBJECT ;
         ,loSelect

      loSelect    = CreateFactory('cSelect')
      loParameter = THIS.oSQL.GetParameterObject()

      *!* Uncomment when parameters are passed --> loParameter = This.oSQL.GetParameterObject()
      IF NOT THIS.oSQL.lVFPTable
         TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1+2
            SELECT
               [<<This.cTable>>].*
            FROM
               [<<This.cSQLSchema>>].[<<This.cTable>>]
         ENDTEXT

         IF EMPTY(NVL(m.tcWellID,SPACE(0)))
            *-- Nothing at this time
         ELSE
            loParameter.ADD('cWellID', ALLTRIM(m.tcWellID) + '%')

            TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2
                  AND [<<This.cTable>>].[cWellID] LIKE ?cWellID
            ENDTEXT
         ENDIF

      ELSE
         IF EMPTY(THIS.cDataFolder) ;
               OR VARTYPE(THIS.cDataFolder) <> 'C'
            lcDF = ''
         ELSE
            lcDF = ADDBS(ALLTRIM(THIS.cDataFolder))
         ENDIF

         TEXT TO m.lcSQL TEXTMERGE NOSHOW FLAGS 1 PRETEXT 1+2+4+8
            SELECT
               <<This.cTable>>.*
            FROM
               <<m.lcDF+This.cTable>>
            INTO CURSOR <<This.cSearchCursor>> NOFILTER
            WHERE
               1 = 1
         ENDTEXT

         IF EMPTY(NVL(m.tcWellID,SPACE(0)))
            *-- Nothing at this time
         ELSE
            loParameter.ADD('cWellID', ALLTRIM(m.tcWellID) + '%')

            TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1+2 PRETEXT 2+4+8
                  AND <<This.cTable>>.cWellID LIKE ?cWellID
            ENDTEXT
         ENDIF
      ENDIF

      IF NOT EMPTY(THIS.cdefaultsort)
         TEXT TO m.lcSQL ADDITIVE TEXTMERGE NOSHOW FLAGS 1 PRETEXT 2+4+8
            ORDER BY
               <<This.cDefaultSort>>
         ENDTEXT
      ENDIF

      _CLIPTEXT = LCSQL
      THIS.oSQL.Execute(m.LCSQL, THIS.cSearchCursor, loParameter)

      STORE .NULL. TO loSelect, loParameter

      RETURN
   ENDPROC


ENDDEFINE
*
*-- EndDefine: swbizobj_wellinv
**************************************************

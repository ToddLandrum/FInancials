*
*  QBO class library
*
***************************************
DEFINE CLASS swqbo AS CUSTOM
***************************************

*** Main QBO object
   oQBO            = .NULL.

*** General properties
   cErrorMsg = ''
   lQBActive = .F.

*** Entity Properties
   oClassEntity    = .NULL.
   oCustomerEntity = .NULL.
   oVendorEntity   = .NULL.
   oAccountEntity  = .NULL.
   oBillEntity     = .NULL.
   oInvoiceEntity  = .NULL.
   oItemEntity     = .NULL.
   oTermsEntity    = .NULL.
   oCompanyEntity  = .NULL.

*** Entity Record Objects
   oClassRecord    = .NULL.
   oCustomerRecord = .NULL.
   oVendorRecord   = .NULL.
   oAccountRecord  = .NULL.
   oBillRecord     = .NULL.
   oInvoiceRecord  = .NULL.
   oItemRecord     = .NULL.
   oTermsRecord    = .NULL.
   oCompanyRecord  = .NULL.

***************************************
   PROCEDURE INIT
***************************************

      THIS.oQBO = CREATEOBJECT('SWQBApi', m.goapp.cCommonFolder + 'sherware.ini')

      IF VARTYPE(THIS.oQBO) # 'O'
         THIS.cErrorMsg = 'Failed to instantiate SWQBapi'
         RETURN .F.
      ENDIF
* Check for any setup error ( VERY IMPORTANT )
      IF NOT EMPTY(THIS.cErrorMsg)
         THIS.cErrorMsg =  'An unrecoverable error occurred during setup of SWQBApi class!' + CHR(13) + ;
            toVar.cErrorMsg
         RETURN .F.
      ENDIF


***************************************
   FUNCTION GetSessionKey
***************************************

      LOCAL lcKey

      swselect('options')
      GO TOP
      lcKey = options.cqbosessionkey

* No session key? Create one
      IF EMPTY(lcKey)
* Get new key
         WAIT WINDOW 'Getting new Quickbooks Online Authorization Key' NOWAIT NOCLEAR
         lcKey = THIS.oQBO.GetNewSessionKey()
         WAIT CLEAR
* Bail if we didn't get one
         IF THIS.oQBO.IsEmptyString(m.lcKey)
            RETURN ''
         ENDIF
* Add new record with the new key
         REPLACE options.cqbosessionkey WITH lcKey
      ENDIF

      RETURN lcKey
   ENDFUNC

***************************************
   FUNCTION ConnectToQBCompany
***************************************
      LOCAL lcKey, loQBO

      loQBO = THIS.oQBO

      lcKey = THIS.GetSessionKey()

      IF NOT EMPTY(lcKey)
         llReturn = loQBO.SetSessionKey(lcKey)

         IF NOT llReturn
            THIS.cErrorMsg = 'Failed to set session key: ' + loQBO.cErrorMsg
            RETURN .F.
         ENDIF

         IF NOT loQBO.CheckAuthorization()
            THIS.cErrorMsg = 'An error occurred during authorization check: ' + loQBO.cErrorMsg
            RETURN .F.
         ELSE
            THIS.lQBActive = .T.
         ENDIF

         IF THIS.lQBActive
            TRY

* Create a class entity object
               loCompanyEntity = loQBO.CreateEntityObj('CompanyInfo')

* Query the company info in QBO
               WAIT WINDOW NOWAIT 'Getting company info from QBO...'
               loResults = loCompanyEntity.GETALL()
               WAIT CLEAR

               IF VARTYPE(loResults) # 'O'
                  THIS.cErrorMsg = 'Unable to retrieve Company Info from QBO at this time...'
                  lnCount        = 0
                  llReturn       = .F.
                  EXIT
               ELSE
                  lnCount = 1
               ENDIF

               THIS.oCompanyEntity = loCompanyEntity

               swclose('qbocompany')
* Save the results to a cursor if any records were returned.
               lcResult = THIS.oCompanyEntity.ObjArrayToCursor(loResults, 'qbocompany')

               IF NOT EMPTY(lcResult)
                  THIS.cErrorMsg = 'Unable to retrieve company from QBO at this time...'
                  llReturn       = .F.
                  EXIT
               ENDIF

               _SCREEN.CAPTION = ALLTRIM(_SCREEN.CAPTION) + ' - QBO Company: ' + ALLTRIM(qbocompany.companyname)

            CATCH TO loError

            ENDTRY
         ENDIF

         RETURN .T.
      ELSE
         THIS.cErrorMsg = 'Unable to get a QBO session key!'
         RETURN .F.
      ENDIF

      swclose('qboCompany')

***************************************
   PROCEDURE Sync_Wells_as_Classes
***************************************
      LPARAMETERS tnDatasession, tlNewOnly
      LOCAL loResults, llReturn, loRecord, lnAdded, lnUpdated, loQBO

      llReturn = .T.

      TRY
         loQBO = THIS.oQBO

         IF TYPE('tnDataSession') = 'N'
            TRY
               SET DATASESSION TO (tnDatasession)
            CATCH TO loError
            ENDTRY
         ELSE
            tnDatasession = 1
         ENDIF

* Create a class entity object
         THIS.oClassEntity = loQBO.CreateEntityObj('class')

* Query the classes in QBO
         WAIT WINDOW NOWAIT 'Getting all classes from QBO...'
         loResults = THIS.oClassEntity.GETALL()
         WAIT CLEAR

         IF VARTYPE(loResults) # 'O'
            THIS.cErrorMsg = 'Unable to retrieve classes from QBO at this time...'
            lnCount        = 0
            llReturn       = .F.
            EXIT
         ELSE
            lnCount = loResults.COUNT
         ENDIF

         swclose('qboclasses')
* Save the results to a cursor if any records were returned.
         lcResult = THIS.oClassEntity.ObjArrayToCursor(loResults, 'qboclasses', tnDatasession)

         IF NOT EMPTY(lcResult)
            THIS.cErrorMsg = 'Unable to retrieve classes from QBO at this time...'
            llReturn       = .F.
            EXIT
         ENDIF

* Create a cursor to store the wells we've already syncd so we don't try again
         CREATE CURSOR syncdwells (cwellid c(10))
         SET EXACT OFF

* Make sure the wells table is open
         swselect('wells')
* There are classes in QBO. Now check to see if they match any of our existing wells.
         SELECT qboclasses
         SCAN

            SELECT wells
            LOCATE FOR UPPER(cwellname) = ALLTRIM(UPPER(qboclasses.NAME)) OR wells.clistid = ALLTRIM(qboclasses.ID)
            IF FOUND()
               REPLACE clistid WITH qboclasses.ID
               m.cwellid = cwellid
               INSERT INTO syncdwells FROM MEMVAR
            ENDIF

         ENDSCAN

* Now check to see what wells might need to be added to QBO
         lnAdded = 0
         SELECT wells
         SCAN
            m.cwellid   = cwellid
            m.cwellname = cwellname

            SELECT syncdwells
            LOCATE FOR cwellid = m.cwellid
            IF FOUND()
               LOOP
            ENDIF

            WAIT WINDOW NOWAIT 'Adding Well: ' + ALLTRIM(m.cwellname) + ' as a Class in QBO...'

            loRecord = THIS.oClassEntity.New()

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Failed to get a new class record.'
               llReturn       = .F.
               EXIT
            ENDIF

            loRecord.NAME     = ALLTRIM(m.cwellname)
            loRecord.ACTIVE   = .T.
            THIS.oClassRecord = loRecord


* Add the new class record
            loRecord = THIS.oClassEntity.ADD(THIS.oClassRecord)

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Unable to save the new class record.'
               llReturn       = .F.
               EXIT
            ENDIF

* Save the QBO id returned in the saved record to the clistid field in the wells table
            SELECT wells
            REPLACE wells.clistid WITH loRecord.ID
            lnAdded = lnAdded + 1
            WAIT CLEAR
         ENDSCAN

* Now check to see what wells might need to be updated in QBO

         IF NOT tlNewOnly
            lnUpdated = 0
            SELECT wells
            SCAN
               SCATTER MEMVAR

               SELECT syncdwells
               LOCATE FOR cwellid = m.cwellid
               IF NOT FOUND()
                  LOOP
               ENDIF

               WAIT WINDOW NOWAIT 'Updating Well: ' + ALLTRIM(m.cwellname) + ' as a Class in QBO...'

               loRecord = THIS.oClassEntity.GET(ALLTRIM(m.clistid))

               IF NOT THIS.ValidObject(loRecord)
                  THIS.cErrorMsg = 'Failed to get a class record.'
                  llReturn       = .F.
                  EXIT
               ENDIF

               loRecord.NAME     = ALLTRIM(m.cwellname)

               IF m.cWellstat = 'I'
                  loRecord.ACTIVE   = .F.
               ELSE
                  loRecord.ACTIVE   = .T.
               ENDIF
               THIS.oClassRecord = loRecord

* Add the new class record
               loRecord = THIS.oClassEntity.UPDATE(THIS.oClassRecord)

               IF NOT THIS.ValidObject(loRecord)
                  THIS.cErrorMsg = 'Unable to save the updated class record.'
                  lcErrorMsg     = THIS.oWellEntity.cErrorMsg
                  m.cid          = m.cwellid
                  m.cname        = m.cwellname
                  m.cmessage     = THIS.QBOParseError(lcErrorMsg)
                  m.cType        = 'Well'
                  m.nqberror     = 0
                  INSERT INTO qbbadnames FROM MEMVAR
                  LOOP
               ENDIF

               lnUpdated = lnUpdated + 1

               WAIT CLEAR
            ENDSCAN
         ENDIF


      CATCH TO loError
         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(13) + ;
              'Line:  ' + TRANSFORM(loError.LINENO), 16, 'Sync_Wells_as_Classes')

      ENDTRY

      WAIT CLEAR

      IF lnAdded + lnUpdated > 0
         MESSAGEBOX('Sync Wells:' + CHR(13) + ;
              'Added ' + TRANSFORM(lnAdded) + ' Wells to QBO' + CHR(13) + ;
              'Updated ' + TRANSFORM(lnUpdated) + ' Well / CLASS RECORDS IN QBO', 64, 'Sync wells TO QBO', 2000)
      ENDIF


      swclose('qboclasses')
      swclose('syncdwells')

      RETURN llReturn

***************************************
   PROCEDURE Sync_Owners_as_Customers
***************************************
      LPARAMETERS tnDatasession, tlNewOnly
      LOCAL loResults, llReturn, loRecord, lnAdded, lnUpdated

      llReturn = .T.
      lnAdded  = 0

      TRY
         loQBO = THIS.oQBO

         IF TYPE('tnDataSession') = 'N'
            TRY
               SET DATASESSION TO (tnDatasession)
            CATCH TO loError
            ENDTRY
         ELSE
            tnDatasession = 1
         ENDIF

* Create a class entity object
         THIS.oCustomerEntity = loQBO.CreateEntityObj('customer')

* Get all the customers currently in QBO
         WAIT WINDOW NOWAIT 'Getting all customers from QBO...'
         loResults = THIS.oCustomerEntity.GETALL()
         WAIT CLEAR

         IF THIS.ValidObject(loResults)  && It could come back as a null object if there are no customers in QBO
            lnCount = loResults.COUNT

            swclose('qbocustomers')
* Save the results to a cursor if any records were returned.
            lcResult = THIS.oCustomerEntity.ObjArrayToCursor(loResults, 'qbocustomers', tnDatasession)

            IF NOT EMPTY(lcResult)
               THIS.cErrorMsg = 'Unable to retrieve customers from QBO at this time...'
               llReturn       = .F.
               EXIT
            ENDIF

* Create a cursor to store the owners we've already syncd so we don't try again
            CREATE CURSOR syncdowners (cownerid c(10), csortfield c(60))

* Make sure the investor table is open
            swselect('investor')
* There are customers in QBO. Now check to see if they match any of our existing owners.
            SELECT qbocustomers
            SCAN

               SELECT investor
               LOCATE FOR UPPER(csortfield) = ALLTRIM(UPPER(qbocustomers.displayname))
               IF FOUND()
                  REPLACE clistid WITH qbocustomers.ID
                  m.cownerid   = cownerid
                  m.csortfield = csortfield
                  INSERT INTO syncdowners FROM MEMVAR
               ENDIF

            ENDSCAN
         ENDIF

* Now check to see what owners might need to be added to QBO
         SELECT investor
         SCAN
            SCATTER MEMVAR

* Only sync newly added owners?
            IF tlNewOnly
               IF NOT EMPTY(investor.clistid)
                  LOOP
               ENDIF
            ENDIF

            SELECT syncdowners
            LOCATE FOR UPPER(syncdowners.csortfield) = UPPER(ALLTRIM(m.csortfield))
            IF FOUND()
               LOOP
            ENDIF

            WAIT WINDOW NOWAIT 'Adding Owner: ' + ALLTRIM(m.csortfield) + ' as a Customer in QBO...'

            SELECT investor
            IF 'é' $ m.cownname
               m.csortfield   = STRTRAN(m.csortfield, 'é', 'e')
               REPLACE csortfield WITH m.csortfield
            ENDIF
            IF ':' $ m.csortfield
               m.csortfield = STRTRAN(m.csortfield, ':', '-')
               REPLACE csortfield WITH m.csortfield
            ENDIF

            loRecord = THIS.oCustomerEntity.New()

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Failed to get a new customer record.'
               llReturn       = .F.
               EXIT
            ENDIF

            loRecord.displayname    = ALLTRIM(m.csortfield)
            IF m.iTaxIDType = 1  && Company
               loRecord.companyname = ALLTRIM(m.csortfield)
            ENDIF
            loRecord.ACTIVE                        = .T.

            TRY
               loPhone                = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
               loPhone.FreeFormNumber = ALLTRIM(m.cPhonew)
               loRecord.PrimaryPhone  = loPhone
            CATCH
            ENDTRY

            TRY
               loAltPhone                = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
               loAltPhone.FreeFormNumber = ALLTRIM(m.cPhonew)
               loRecord.AlternatePhone   = loAltPhone
            CATCH
            ENDTRY

            TRY
               loBillAddr            = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
               loBillAddr.Line1      = ALLTRIM(m.caddress1a)
               loBillAddr.Line2      = ALLTRIM(m.cAddress1b)
               loBillAddr.City       = ALLTRIM(m.cCity1)
               loBillAddr.PostalCode = ALLTRIM(m.cZip1)
               loRecord.BillAddr     = loBillAddr
            CATCH
            ENDTRY

            TRY
               loShipAddr = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
* Only fill in Shipping Address if the owner's secondary address is not empty
               IF NOT EMPTY(m.caddress1a)
                  loShipAddr.Line1      = ALLTRIM(m.caddress2a)
                  loShipAddr.Line2      = ALLTRIM(m.cAddress2b)
                  loShipAddr.City       = ALLTRIM(m.cCity2)
                  loShipAddr.PostalCode = ALLTRIM(m.cZip2)
                  loRecord.ShipAddr     = loShipAddr
               ENDIF
            CATCH
            ENDTRY

            THIS.oCustomerRecord = loRecord

* Add the new class record
            loRecord = THIS.oCustomerEntity.ADD(THIS.oCustomerRecord)

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Unable to save the new customer record.'
               llReturn       = .F.
               EXIT
            ENDIF

* Save the QBO id returned in the saved record to the clistid field in the wells table
            SELECT investor
            REPLACE investor.clistid WITH loRecord.ID
            lnAdded = lnAdded + 1
            WAIT CLEAR
         ENDSCAN

         IF NOT tlNewOnly
            lnUpdated = 0
* Now check to see what owners might need to be added to QBO
            SELECT investor
            SCAN FOR EMPTY(clistid)
               SCATTER MEMVAR

* Only sync newly added owners?
               IF tlNewOnly
                  IF NOT EMPTY(investor.clistid)
                     LOOP
                  ENDIF
               ENDIF

               SELECT syncdowners
               LOCATE FOR UPPER(syncdowners.csortfield) = UPPER(ALLTRIM(m.csortfield))
               IF FOUND()
                  LOOP
               ENDIF

               WAIT WINDOW NOWAIT 'Updating Owner: ' + ALLTRIM(m.csortfield) + ' as a Customer in QBO...'

               SELECT investor
               IF 'é' $ m.cownname
                  m.csortfield   = STRTRAN(m.csortfield, 'é', 'e')
                  REPLACE csortfield WITH m.csortfield
               ENDIF
               IF ':' $ m.csortfield
                  m.csortfield = STRTRAN(m.csortfield, ':', '-')
                  REPLACE csortfield WITH m.csortfield
               ENDIF

               loRecord = THIS.oCustomerEntity.GET(ALLTRIM(m.clistid))

               IF NOT THIS.ValidObject(loRecord)
                  THIS.cErrorMsg = 'Did not find a customer record for ' + ALLTRIM(m.csortfield)
                  llReturn       = .F.
                  EXIT
               ENDIF

               loRecord.displayname    = ALLTRIM(m.csortfield)
               IF m.iTaxIDType = 1  && Company
                  loRecord.companyname = ALLTRIM(m.csortfield)
               ENDIF
               loRecord.ACTIVE                        = .T.

               TRY
                  loPhone                = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
                  loPhone.FreeFormNumber = ALLTRIM(m.cPhonew)
                  loRecord.PrimaryPhone  = loPhone
               CATCH
               ENDTRY

               TRY
                  loAltPhone                = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
                  loAltPhone.FreeFormNumber = ALLTRIM(m.cPhonew)
                  loRecord.AlternatePhone   = loAltPhone
               CATCH
               ENDTRY

               TRY
                  loBillAddr            = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
                  loBillAddr.Line1      = ALLTRIM(m.caddress1a)
                  loBillAddr.Line2      = ALLTRIM(m.cAddress1b)
                  loBillAddr.City       = ALLTRIM(m.cCity1)
                  loBillAddr.PostalCode = ALLTRIM(m.cZip1)
                  loRecord.BillAddr     = loBillAddr
               CATCH
               ENDTRY

               TRY
                  loShipAddr = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
* Only fill in Shipping Address if the owner's secondary address is not empty
                  IF NOT EMPTY(m.caddress1a)
                     loShipAddr.Line1      = ALLTRIM(m.caddress2a)
                     loShipAddr.Line2      = ALLTRIM(m.cAddress2b)
                     loShipAddr.City       = ALLTRIM(m.cCity2)
                     loShipAddr.PostalCode = ALLTRIM(m.cZip2)
                     loRecord.ShipAddr     = loShipAddr
                  ENDIF
               CATCH
               ENDTRY

               THIS.oCustomerRecord = loRecord

* Add the new class record
               loRecord = THIS.oCustomerEntity.UPDATE(THIS.oCustomerRecord)

               IF NOT THIS.ValidObject(loRecord)
                  THIS.cErrorMsg = 'Unable to update the new customer record.'
                  lcErrorMsg     = THIS.oCustomerEntity.cErrorMsg
                  m.cid          = m.cownerid
                  m.cname        = m.cownname
                  m.cmessage     = THIS.QBOParseError(lcErrorMsg)
                  m.cType        = 'Owner'
                  m.nqberror     = 0
                  INSERT INTO qbbadnames FROM MEMVAR
                  LOOP
               ENDIF

               lnUpdated = lnUpdated + 1
               WAIT CLEAR
            ENDSCAN
         ENDIF

         IF lnAdded + lnUpdated > 0
            MESSAGEBOX('Sync Owners:' + CHR(13) + ;
                 'Added ' + TRANSFORM(lnAdded) + ' Owners to QBO' + CHR(13) + ;
                 'Updated ' + TRANSFORM(lnUpdated) + ' Owner / Customer RECORDS IN QBO', 64, 'Sync Owners TO QBO', 2000)
         ENDIF

      CATCH TO loError
         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(13) + ;
              'Line:  ' + TRANSFORM(loError.LINENO), 16, 'Sync_Owners_as_Customers')

      ENDTRY

      WAIT CLEAR

      RETURN llReturn

***************************************
   PROCEDURE Sync_Purchasers_as_Customers
***************************************
      LPARAMETERS tnDatasession, tlNewOnly
      LOCAL loResults, llReturn, loRecord, lnAdded

      llReturn = .T.
      lnAdded  = 0
      lnUpd    = 0

      TRY
         loQBO = THIS.oQBO

         IF TYPE('tnDataSession') = 'N'
            TRY
               SET DATASESSION TO (tnDatasession)
            CATCH TO loError
            ENDTRY
         ELSE
            tnDatasession = 1
         ENDIF

* Create a class entity object
         THIS.oCustomerEntity = loQBO.CreateEntityObj('customer')

* Get all the customers currently in QBO
         WAIT WINDOW NOWAIT 'Getting all customers from QBO...'
         loResults = THIS.oCustomerEntity.GETALL()
         WAIT CLEAR

         IF NOT THIS.ValidObject(loResults)
            THIS.cErrorMsg = 'Unable to retrieve customers from QBO at this time...'
            lnCount        = 0
            llReturn       = .F.
            EXIT
         ELSE
            lnCount = loResults.COUNT
         ENDIF

         swclose('qbocustomers')
* Save the results to a cursor if any records were returned.
         lcResult = THIS.oCustomerEntity.ObjArrayToCursor(loResults, 'qbocustomers', tnDatasession)

         IF NOT EMPTY(lcResult)
            THIS.cErrorMsg = 'Unable to retrieve customers from QBO at this time...'
            llReturn       = .F.
            EXIT
         ENDIF

* Create a cursor to store the purchasers we've already syncd so we don't try again
         CREATE CURSOR syncdpurchasers (crevkey c(10), crevname c(60))

* Make sure the investor table is open
         swselect('revsrc')
* There are customers in QBO. Now check to see if they match any of our existing purchasers.
         SELECT qbocustomers
         SCAN

            SELECT revsrc
            LOCATE FOR UPPER(crevname) = ALLTRIM(UPPER(qbocustomers.displayname))
            IF FOUND()
               REPLACE clistid WITH qbocustomers.ID
               m.crevkey  = crevkey
               m.crevname = crevname
               INSERT INTO syncdpurchasers FROM MEMVAR
            ENDIF

         ENDSCAN

* Now check to see what owners might need to be added to QBO
         SELECT revsrc
         SCAN FOR EMPTY(clistid)
            SCATTER MEMVAR

* Only sync newly added owners?
            IF tlNewOnly
               IF NOT EMPTY(revsrc.clistid)
                  LOOP
               ENDIF
            ENDIF

            SELECT syncdpurchasers
            LOCATE FOR UPPER(crevname) = ALLTRIM(UPPER(m.crevname))
            IF FOUND()
               LOOP
            ENDIF

            WAIT WINDOW NOWAIT 'Adding Purchasers: ' + ALLTRIM(m.crevname) + ' as a Customer in QBO...'

            SELECT revsrc
            IF 'é' $ m.crevname
               m.crevname   = STRTRAN(m.crevname, 'é', 'e')
               REPLACE crevname WITH m.crevname
            ENDIF
            IF ':' $ m.crevname
               m.crevname = STRTRAN(m.crevname, ':', '-')
               REPLACE crevname WITH m.crevname
            ENDIF

            loRecord = THIS.oCustomerEntity.New()

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Failed to get a new customer record.'
               llReturn       = .F.
               EXIT
            ENDIF

            loRecord.displayname = ALLTRIM(m.crevname)
            loRecord.companyname = ALLTRIM(m.crevname)
            loRecord.ACTIVE      = .T.

            TRY
               loPhone                = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
               loPhone.FreeFormNumber = ALLTRIM(m.cphone)
               loRecord.PrimaryPhone  = loPhone
            CATCH
            ENDTRY

            TRY
               loAltPhone                = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
               loAltPhone.FreeFormNumber = ALLTRIM(m.cfaxphone)
               loRecord.AlternatePhone   = loAltPhone
            CATCH
            ENDTRY

            TRY
               loBillAddr        = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
               loBillAddr.Line1  = ALLTRIM(m.caddress1)
               loBillAddr.Line2  = ALLTRIM(m.caddress2)
               loBillAddr.Line2  = ALLTRIM(m.caddress3)
               loRecord.BillAddr = loBillAddr
            CATCH
            ENDTRY

            TRY
               loShipAddr = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
* Only fill in Shipping Address if the owner's secondary address is not empty
               IF NOT EMPTY(m.caddress1a)
                  loShipAddr.Line1  = ALLTRIM(m.caddress1)
                  loShipAddr.Line2  = ALLTRIM(m.caddress2)
                  loShipAddr.Line3  = ALLTRIM(m.caddress3)
                  loRecord.ShipAddr = loShipAddr
               ENDIF
            CATCH
            ENDTRY

            THIS.oCustomerRecord = loRecord


* Add the new class record
            loRecord = THIS.oCustomerEntity.ADD(THIS.oCustomerRecord)

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Unable to save the new customer record.'
               lcErrorMsg     = THIS.oCustomerEntity.cErrorMsg
               m.cid          = m.crevkey
               m.cname        = m.crevname
               m.cmessage     = THIS.QBOParseError(lcErrorMsg)
               m.cType        = 'Purchaser'
               m.nqberror     = 0
               INSERT INTO qbbadnames FROM MEMVAR
               LOOP
            ENDIF

* Save the QBO id returned in the saved record to the clistid field in the wells table
            SELECT revsrc
            REPLACE revsrc.clistid WITH loRecord.ID
            lnAdded = lnAdded + 1
            WAIT CLEAR
         ENDSCAN

         IF NOT tlNewOnly
* Now check to see what owners might need to be updated in QBO
            SELECT revsrc
            SCAN
               SCATTER MEMVAR

               SELECT syncdpurchasers
               LOCATE FOR UPPER(crevname) = ALLTRIM(UPPER(m.crevname))
               IF FOUND()
                  LOOP
               ENDIF

               WAIT WINDOW NOWAIT 'Updating Purchasers: ' + ALLTRIM(m.crevname) + ' as a Customer in QBO...'

               SELECT revsrc
               IF 'é' $ m.crevname
                  m.crevname   = STRTRAN(m.crevname, 'é', 'e')
                  REPLACE crevname WITH m.crevname
               ENDIF
               IF ':' $ m.crevname
                  m.crevname = STRTRAN(m.crevname, ':', '-')
                  REPLACE crevname WITH m.crevname
               ENDIF

               loRecord = THIS.oCustomerEntity.GET(ALLTRIM(m.clistid))

               IF NOT THIS.ValidObject(loRecord)
                  THIS.cErrorMsg = 'Failed to get a new customer record.'
                  llReturn       = .F.
                  EXIT
               ENDIF

               loRecord.displayname = ALLTRIM(m.crevname)
               loRecord.companyname = ALLTRIM(m.crevname)
               loRecord.ACTIVE      = .T.

               TRY
                  loPhone                = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
                  loPhone.FreeFormNumber = ALLTRIM(m.cphone)
                  loRecord.PrimaryPhone  = loPhone
               CATCH
               ENDTRY

               TRY
                  loAltPhone                = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
                  loAltPhone.FreeFormNumber = ALLTRIM(m.cfaxphone)
                  loRecord.AlternatePhone   = loAltPhone
               CATCH
               ENDTRY

               TRY
                  loBillAddr        = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
                  loBillAddr.Line1  = ALLTRIM(m.caddress1)
                  loBillAddr.Line2  = ALLTRIM(m.caddress2)
                  loBillAddr.Line2  = ALLTRIM(m.caddress3)
                  loRecord.BillAddr = loBillAddr
               CATCH
               ENDTRY

               TRY
                  loShipAddr = THIS.oCustomerEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
* Only fill in Shipping Address if the owner's secondary address is not empty
                  IF NOT EMPTY(m.caddress1a)
                     loShipAddr.Line1  = ALLTRIM(m.caddress1)
                     loShipAddr.Line2  = ALLTRIM(m.caddress2)
                     loShipAddr.Line3  = ALLTRIM(m.caddress3)
                     loRecord.ShipAddr = loShipAddr
                  ENDIF
               CATCH
               ENDTRY

               THIS.oCustomerRecord = loRecord


* Add the new class record
               loRecord = THIS.oCustomerEntity.UPDATE(THIS.oCustomerRecord)

               IF NOT THIS.ValidObject(loRecord)
                  THIS.cErrorMsg = 'Unable to save the new customer record.'
                  lcErrorMsg     = THIS.oCustomerEntity.cErrorMsg
                  m.cid          = m.crevkey
                  m.cname        = m.crevname
                  m.cmessage     = THIS.QBOParseError(lcErrorMsg)
                  m.cType        = 'Purchaser'
                  m.nqberror     = 0
                  INSERT INTO qbbadnames FROM MEMVAR
                  LOOP
               ENDIF

               lnUpd = lnUpd + 1
               WAIT CLEAR
            ENDSCAN
         ENDIF

         IF lnAdded > 0 OR lnUpd > 0
            MESSAGEBOX('Sync Purchasers: ' + CHR(13) + ;
                 'Added   ' + TRANSFORM(lnAdded) +  CHR(13) + ;
                 'Updated ' + TRANSFORM(lnUpd) + ;
                 ' Purchasers to QBO', 64, 'Sync Purchasers to QBO')
         ENDIF

      CATCH TO loError
         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(13) + ;
              'Line:  ' + TRANSFORM(loError.LINENO), 16, 'Sync_Purchasers_as_Customers')

      ENDTRY

      WAIT CLEAR

      RETURN llReturn


***************************************
   PROCEDURE Sync_Terms
***************************************
      LPARAMETERS tnDatasession, tlNewOnly
      LOCAL loResults, llReturn, loRecord, lnAdded, lnUpdated

      llReturn = .T.

      TRY
         loQBO = THIS.oQBO

         IF TYPE('tnDataSession') = 'N'
            TRY
               SET DATASESSION TO (tnDatasession)
            CATCH TO loError
            ENDTRY
         ELSE
            tnDatasession = 1
         ENDIF

* Get all the customers currently in QBO
         WAIT WINDOW NOWAIT 'Getting all terms from QBO...'
         CREATE CURSOR qboterms ;
            (NAME      c(60), ;
              ID        c(36), ;
              duedays   i, ;
              discountdays i, ;
              discountpercent   N(12, 2))

         loSer   = CREATEOBJECT('wwjsonserializer')
         lcQuery = 'select * from term'
         lcJSON  = loQBO.QueryJson(m.lcQuery)
         loTerms = loSer.DeserializeJson(lcJSON)
         loSer   = .NULL.
         FOR x = 1 TO loTerms.queryresponse.TERM.COUNT
            loterm    = loTerms.queryresponse.TERM.ITEM[x]
            m.name    = loterm.NAME
            m.duedays = loterm.duedays
            m.id      = loterm.ID
            m.cidterm = m.id
            TRY
               m.discountdays = loterm.discountdays
               IF m.discountdays # 0
                  m.discountpercent = loterm.discountpercent
               ELSE
                  m.discountpercent = 0
               ENDIF
            CATCH
               m.discountdays    = 0
               m.discountpercent = 0
            ENDTRY
            INSERT INTO qboterms FROM MEMVAR
         ENDFOR
         WAIT CLEAR

* Create a cursor to store the purchasers we've already syncd so we don't try again
         CREATE CURSOR syncdterms (cidterm c(8))

         SELECT qboterms
         SCAN
            SCATTER MEMVAR

            SELECT terms
            LOCATE FOR UPPER(ctermdesc) = ALLTRIM(UPPER(qboterms.NAME))
            IF FOUND()
               REPLACE clistid WITH qboterms.ID
               m.cidterm = cidterm
               INSERT INTO syncdterms FROM MEMVAR
            ENDIF
         ENDSCAN

         SELECT qboterms
         SCAN
            SCATTER MEMVAR

            SELECT syncdterms
            LOCATE FOR cidterm = ALLTRIM(m.id)
            IF FOUND()
               LOOP
            ENDIF

            m.cidterm   = m.id
            m.ctermdesc = m.name
            TRY
               m.nnetduein = m.duedays
               m.ndiscin   = m.discountdays
               m.ndiscpct  = m.discountpercent
            CATCH
               m.nnetduein = 0
               m.ndiscin   = 0
               m.ndiscpct  = 0
            ENDTRY
            m.clistid   = m.id
            INSERT INTO terms FROM MEMVAR
         ENDSCAN

      CATCH TO loError
         MESSAGEBOX(loError.MESSAGE + CHR(13) + 'Line: ' + TRANSFORM(loError.LINENO), 64, 'Sync Terms')
         llReturn = .F.
      ENDTRY

      RETURN llReturn

***************************************
   PROCEDURE Sync_Vendors
***************************************
      LPARAMETERS tnDatasession, tlNewOnly
      LOCAL loResults, llReturn, loRecord, lnAdded

      llReturn = .T.

      TRY
         loQBO = THIS.oQBO

         IF TYPE('tnDataSession') = 'N'
            TRY
               SET DATASESSION TO (tnDatasession)
            CATCH TO loError
            ENDTRY
         ELSE
            tnDatasession = 1
         ENDIF

* Reset the list ids if we've never synched with QBO so our vendors get added to QBO
         IF NOT FILE(m.goapp.cDataFilePath + 'qbovendsync.txt')
            swselect('vendor')
            REPLACE clistid WITH '' ALL
         ENDIF

* Create a class entity object
         THIS.oVendorEntity = loQBO.CreateEntityObj('vendor')

* Get all the customers currently in QBO
         WAIT WINDOW NOWAIT 'Getting all vendors from QBO...'
         loResults = THIS.oVendorEntity.GETALL()
         WAIT CLEAR

         IF NOT THIS.ValidObject(loResults)
            THIS.cErrorMsg = 'Unable to retrieve vendors from QBO at this time...'
            lnCount        = 0
            llReturn       = .F.
            EXIT
         ELSE
            lnCount = loResults.COUNT
         ENDIF

* Create a cursor to store the owners we've already syncd so we don't try again
         CREATE CURSOR syncdvendors (cvendname c(60))

         swclose('qbovendors')
* Save the results to a cursor if any records were returned.
         lcResult = THIS.oVendorEntity.ObjArrayToCursor(loResults, 'qboVendors', tnDatasession)

         IF NOT EMPTY(lcResult)
            THIS.cErrorMsg = 'Unable to retrieve vendors from QBO at this time...'
            llReturn       = .F.
            EXIT
         ENDIF

* Make sure the vendor table is open
         swselect('vendor')
* There are vendors in QBO. Now check to see if they match any of our existing owners.
         SELECT qbovendors
         SCAN

            SELECT vendor
            LOCATE FOR (UPPER(cvendname) = ALLTRIM(UPPER(qbovendors.companyname)) OR ;
                        UPPER(cvendname) = ALLTRIM(UPPER(qbovendors.displayname)))
            IF FOUND()
               IF clistid # ALLTRIM(qbovendors.ID)
                  REPLACE clistid WITH qbovendors.ID
               ENDIF
               m.cvendname = cvendname
               INSERT INTO syncdvendors FROM MEMVAR
            ENDIF

         ENDSCAN

         lnAdded = 0
         lnUpd   = 0

* Now check to see what vendors might need to be added to our vendor table
         SELECT qbovendors
         SCAN
            SCATTER MEMVAR

            SELECT syncdvendors
            LOCATE FOR (UPPER(cvendname) = UPPER(ALLTRIM(m.companyname)) OR ;
                 UPPER(cvendname) = UPPER(ALLTRIM(m.displayname)))
            IF FOUND()
               LOOP
            ENDIF

            IF m.companyname # '.NULL.'
               m.cvendname  = m.companyname
               m.csortfield = m.companyname
            ELSE
               IF m.displayname # '.NULL.'
                  m.cvendname  = m.displayname
                  m.csortfield = m.displayname
               ENDIF
            ENDIF

            WAIT WINDOW NOWAIT 'Adding Vendor: ' + ALLTRIM(m.cvendname) + ' to the Vendor file...'

            m.clistid   = m.id
            m.cvendorid = m.id

* Tax ID
            IF m.businessnumber # '.NULL.'
               m.ctaxid = m.businessnumber
            ELSE
               m.ctaxid = ''
            ENDIF

* Send 1099
            m.lsend1099 = m.vendor1099

* Terms
            IF m.termref_value # '.NULL.'
               m.cqbterms  = m.termref_value
            ELSE
               m.cqbterms  = ''
            ENDIF

            IF UPPER(m.termref_name) = 'POST'
               m.linteggl = .T.
            ELSE
               m.linteggl = .F.
            ENDIF

* Addresses
            IF m.billaddr_line1 # '.NULL.'
               m.cbaddr1   = m.billaddr_line1
               m.caddress1 = m.cbaddr1
            ELSE
               m.cbaddr1   = ''
               m.caddress1 = ''
            ENDIF
            IF m.billaddr_line2 # '.NULL.'
               m.cbaddr2   = m.billaddr_line2
               m.caddress2 = m.cbaddr2
            ELSE
               m.cbaddr2   = ''
               m.caddress2 = ''
            ENDIF
            IF m.billaddr_city # '.NULL.'
               m.cbcity = m.billaddr_city
               m.ccity  = m.cbcity
            ELSE
               m.cbcity = ''
               m.ccity  = ''
            ENDIF
            IF m.billaddr_countrysubdivisioncode # '.NULL.'
               m.cbstate = m.billaddr_countrysubdivisioncode
               m.cstate  = m.cbstate
            ELSE
               m.cbstate = ''
               m.cstate  = ''
            ENDIF
            IF m.billaddr_postalcode # '.NULL.'
               m.cbzip = m.billaddr_postalcode
               m.czip  = m.cbzip
            ELSE
               m.cbzip = ''
               m.czip  = ''
            ENDIF

            SELECT vendor
            LOCATE FOR cvendorid = LEFT(m.cvendorid, 10)
            IF NOT FOUND()
               INSERT INTO vendor FROM MEMVAR
               lnAdded = lnAdded + 1
            ENDIF
         ENDSCAN

* Now check to see what vendors might need to be added to QBO
         SELECT vendor
         SCAN FOR EMPTY(clistid)
            SCATTER MEMVAR

* Only sync newly added owners?
            IF tlNewOnly
               IF NOT EMPTY(vendor.clistid)
                  LOOP
               ENDIF
            ENDIF

            SELECT syncdvendors
            LOCATE FOR UPPER(ALLTRIM(cvendname)) = UPPER(ALLTRIM(m.cvendname))
            IF FOUND()
               LOOP
            ENDIF

            WAIT WINDOW NOWAIT 'Adding Vendors: ' + ALLTRIM(m.cvendname) + ' to QBO...'

            SELECT vendor
            IF 'é' $ m.cvendname
               m.cvendname   = STRTRAN(m.cvendname, 'é', 'e')
               REPLACE cvendname WITH m.cvendname
            ENDIF
            IF ':' $ m.cvendname
               m.cvendname = STRTRAN(m.cvendname, ':', '-')
               REPLACE cvendname WITH m.cvendname
            ENDIF

            loRecord = THIS.oVendorEntity.New()

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Failed to get a new vendor record.'
               llReturn       = .F.
               EXIT
            ENDIF

            loRecord.displayname = ALLTRIM(m.cvendname)
            loRecord.companyname = ALLTRIM(m.cvendname)
            loRecord.ACTIVE      = .T.

            TRY
               loPhone                = THIS.oVendorrEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
               loPhone.FreeFormNumber = ALLTRIM(m.cbphone)
               loRecord.PrimaryPhone  = loPhone
            CATCH
            ENDTRY

            TRY
               loAltPhone                = THIS.oVendorEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
               loAltPhone.FreeFormNumber = ALLTRIM(m.cbfaxphone)
               loRecord.AlternatePhone   = loAltPhone
            CATCH
            ENDTRY

            TRY
               loBillAddr        = THIS.oVendorEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
               loBillAddr.Line1  = ALLTRIM(m.cbaddr1)
               loBillAddr.Line2  = ALLTRIM(m.cbaddr2)
               loRecord.BillAddr = loBillAddr
            CATCH
            ENDTRY

            THIS.oVendorRecord = loRecord

* Add the new class record
            loRecord = THIS.oVendorEntity.ADD(THIS.oVendorRecord)

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Unable to save the new vendor record.'
               lcErrorMsg     = THIS.oVendorEntity.cErrorMsg
               m.cid          = m.cvendorid
               m.cname        = m.cvendname
               m.cmessage     = THIS.QBOParseError(lcErrorMsg)
               m.cType        = 'Vendor'
               m.nqberror     = 0
               INSERT INTO qbbadnames FROM MEMVAR
               LOOP
            ENDIF

* Save the QBO id returned in the saved record to the clistid field in the wells table
            SELECT vendor
            REPLACE vendor.clistid WITH loRecord.ID
            lnAdded = lnAdded + 1
            WAIT CLEAR
         ENDSCAN
         lcString = 'Vendors Synched to QBO ' + TTOC(DATETIME())
         SET SAFETY OFF

         lnVend = 0
         WAIT WINDOW NOWAIT 'Checking Vendors to see if any need updated in QBO: 0'
* Now check to see what vendors might need to be updated in QBO
         SELECT vendor
         SCAN FOR NOT EMPTY(clistid)
            SCATTER MEMVAR
            llDiff = .F.

            lnVend = lnVend + 1
            WAIT WINDOW NOWAIT 'Checking Vendors to see if any need updated in QBO: ' + TRANSFORM(lnVend)

            SELECT vendor
            IF 'é' $ m.cvendname
               m.cvendname   = STRTRAN(m.cvendname, 'é', 'e')
               REPLACE cvendname WITH m.cvendname
            ENDIF
            IF ':' $ m.cvendname
               m.cvendname = STRTRAN(m.cvendname, ':', '-')
               REPLACE cvendname WITH m.cvendname
            ENDIF

            loRecord = THIS.oVendorEntity.GET(ALLTRIM(m.clistid))

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Failed to get a new vendor record.'
               llReturn       = .F.
               EXIT
            ENDIF

            lcResult = THIS.oVendorEntity.ObjToCursor(loRecord, 'qboTemp', tnDatasession)

            IF NOT EMPTY(lcResult)
               THIS.cErrorMsg = 'Unable to retrieve vendors from QBO at this time...'
               llReturn       = .F.
               EXIT
            ENDIF

            IF m.cvendname # ALLTRIM(qboTemp.displayname)
               llDiff = .T.
            ENDIF

            IF m.cvendname # ALLTRIM(qboTemp.companyname)
               llDiff = .T.
            ENDIF

* Tax ID
            IF qboTemp.businessnumber # '.NULL.'
               IF m.ctaxid # ALLTRIM(qboTemp.businessnumber)
                  llDiff = .T.
               ENDIF
            ENDIF

* Send 1099
            IF m.lsend1099 # qboTemp.vendor1099
               llDiff = .T.
            ENDIF

* Terms
            IF qboTemp.termref_value # '.NULL.'
               IF m.cqbterms # ALLTRIM(qboTemp.termref_value)
                  llDiff = .T.
               ENDIF
            ENDIF

            IF qboTemp.termref_name # '.NULL.'
               IF UPPER(qboTemp.termref_name) = 'POST'
                  IF m.linteggl # .T.
                     llDiff = .T.
                  ENDIF
               ENDIF
            ENDIF

* Addresses
            IF qboTemp.billaddr_line1 # '.NULL.'
               IF m.cbaddr1   # ALLTRIM(qboTemp.billaddr_line1)
                  llDiff = .T.
               ENDIF
            ENDIF
            IF qboTemp.billaddr_line2 # '.NULL.'
               IF m.cbaddr2   # ALLTRIM(qboTemp.billaddr_line2)
                  llDiff = .T.
               ENDIF
            ENDIF
            IF qboTemp.billaddr_city # '.NULL.'
               IF m.cbcity # ALLTRIM(qboTemp.billaddr_city)
                  llDiff = .T.
               ENDIF
            ENDIF
            IF qboTemp.billaddr_countrysubdivisioncode # '.NULL.'
               IF m.cbstate # ALLTRIM(qboTemp.billaddr_countrysubdivisioncode)
                  llDiff = .T.
               ENDIF
            ENDIF
            IF qboTemp.billaddr_postalcode # '.NULL.'
               IF m.cbzip # ALLTRIM(qboTemp.billaddr_postalcode)
                  llDiff = .T.
               ENDIF
            ENDIF

            IF NOT llDiff
               swclose('qboTemp')
               LOOP
            ENDIF

            WAIT WINDOW NOWAIT 'Updating Vendor: ' + ALLTRIM(m.cvendname) + ' in QBO...'

            loRecord.displayname = ALLTRIM(m.cvendname)
            loRecord.companyname = ALLTRIM(m.cvendname)
            loRecord.ACTIVE      = .T.

            TRY
               loPhone                = THIS.oVendorrEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
               loPhone.FreeFormNumber = ALLTRIM(m.cbphone)
               loRecord.PrimaryPhone  = loPhone
            CATCH
            ENDTRY

            TRY
               loAltPhone                = THIS.oVendorEntity.CreateInstance('Intuit.Ipp.Data.TelephoneNumber')
               loAltPhone.FreeFormNumber = ALLTRIM(m.cbfaxphone)
               loRecord.AlternatePhone   = loAltPhone
            CATCH
            ENDTRY

            TRY
               loBillAddr        = THIS.oVendorEntity.CreateInstance('Intuit.Ipp.Data.PhysicalAddress')
               loBillAddr.Line1  = ALLTRIM(m.cbaddr1)
               loBillAddr.Line2  = ALLTRIM(m.cbaddr2)
               loRecord.BillAddr = loBillAddr
            CATCH
            ENDTRY

            THIS.oVendorRecord = loRecord

* Add the new class record
            loRecord = THIS.oVendorEntity.UPDATE(THIS.oVendorRecord)

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Unable to update the vendor record.'
               lcErrorMsg     = THIS.oVendorEntity.cErrorMsg
               m.cid          = m.cvendorid
               m.cname        = m.cvendname
               m.cmessage     = THIS.QBOParseError(lcErrorMsg)
               m.cType        = 'Vendor'
               m.nqberror     = 0
               INSERT INTO qbbadnames FROM MEMVAR
               LOOP
            ENDIF

            lnUpd = lnUpd + 1
            WAIT CLEAR
         ENDSCAN

      CATCH TO loError
         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(13) + ;
              'Line:  ' + TRANSFORM(loError.LINENO), 16, 'Sync_Vendors')

      ENDTRY

      IF lnAdded > 0 OR lnUpd > 0
         MESSAGEBOX('Sync Vendors: ' + CHR(13) + ;
              'Added   ' + TRANSFORM(lnAdded) + CHR(13) + ;
              'Updated ' + TRANSFORM(lnUpd) + ' Vendors in QBO', 64, 'Sync Vendors with QBO', 3000)
      ENDIF

      WAIT CLEAR

      RETURN llReturn

*********************************
   PROCEDURE Sync_ExpCodes_as_Items
*********************************
      LPARA tnDatasession, tlNewOnly
      LOCAL loitemquery, loresponse, loitemresp, loitem, lnDatasession

* Not finished **  pws - 7/5/22

      TRY
         lnDatasession = SET('Datasession')

         IF TYPE('tnDataSession') = 'N'
            TRY
               SET DATASESSION TO (tnDatasession)
            CATCH TO loError
            ENDTRY
         ELSE
            MESSAGEBOX('Bad datasession passed to qbitems.', 16, 'Sync_ExpCodes_as_Items')
            llReturn = .F.
            EXIT
         ENDIF

* create output cursors
         CREATE CURSOR qbitems (citemid c(31), clistid c(36))
         INDEX ON citemid TAG citemid

         loQBO = THIS.oQBO

* Create a class entity object
         THIS.oItemEntity = loQBO.CreateEntityObj('item')

* Get all the classes currently in QBO
         WAIT WINDOW NOWAIT 'Getting all items from QBO...'
         loResults = THIS.oItemEntity.GETALL()
         WAIT CLEAR

         IF VARTYPE(loResults) # 'O'
            THIS.cErrorMsg = 'Unable to retrieve items from QBO at this time...'
            lnCount        = 0
            llReturn       = .F.
            EXIT
         ELSE
            lnCount = loResults.COUNT
         ENDIF

* Create a cursor to store the owners we've already syncd so we don't try again
         CREATE CURSOR syncditems (ccatcode c(4))

         swclose('qboitems')
* Save the results to a cursor if any records were returned.
         lcResult = THIS.oItemEntity.ObjArrayToCursor(loResults, 'qboitems', tnDatasession)

         IF NOT EMPTY(lcResult)
            THIS.cErrorMsg = 'Unable to retrieve items from QBO at this time...'
            llReturn       = .F.
            EXIT
         ENDIF

* There are classes in QBO. Now check to see if they match any of our existing wells.
         SELECT qboitems
         SCAN

            SELECT expcat
            LOCATE FOR UPPER(ccateg) = ALLTRIM(UPPER(qboitems.NAME))
            IF FOUND()
               REPLACE clistid WITH qboitems.ID
               m.ccatcode = ccatcode
               INSERT INTO syncditems FROM MEMVAR
            ENDIF

         ENDSCAN

         swselect('glopt')
         GO TOP
         lcExpClear = cqbexpclear

         lnAdded = 0
* Now check to see what owners might need to be added to QBO
         swselect('expcat')
         SCAN
            SCATTER MEMVAR

            SELECT syncditems
            LOCATE FOR ccatcode = m.ccatcode
            IF FOUND()
               LOOP
            ENDIF

            WAIT WINDOW NOWAIT 'Adding Exp Code: ' + ALLTRIM(m.ccatcode) + ' as an Item in QBO...'

            SELECT expcat
            IF 'é' $ m.ccateg
               m.ccateg   = STRTRAN(m.ccateg, 'é', 'e')
               REPLACE ccateg WITH m.ccateg
            ENDIF
            IF ':' $ m.ccateg
               m.ccateg = STRTRAN(m.ccateg, ':', '-')
               REPLACE ccateg WITH m.ccateg
            ENDIF

            loRecord = THIS.oItemEntity.New()

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Failed to get a new Item record.'
               llReturn       = .F.
               EXIT
            ENDIF

            loRecord.NAME              = ALLTRIM(m.ccateg)
            loRecord.DESCRIPTION       = ALLTRIM(m.cdescrip)
            loAccount                  = THIS.oItemEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')
            loAccount.VALUE            = lcExpClear
            loRecord.IncomeAccountRef  = loAccount
            loRecord.ExpenseAccountRef = loAccount
            loRecord.ACTIVE            = .T.
            lnServiceEnum              = THIS.oItemEntity.oShared.oBridge.GetEnumValue('Intuit.Ipp.Data.ItemTypeEnum', 'Service')
            loRecord.TYPE              = lnServiceEnum
            loRecord.TypeSpecified     = .T.

            THIS.oItemRecord = loRecord


* Add the new class record
            loRecord = THIS.oItemEntity.ADD(THIS.oItemRecord)

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Unable to save the new Item record.'
               lcErrorMsg     = THIS.oItemEntity.cErrorMsg
               m.cid          = m.ccatcode
               m.cname        = m.ccateg
               m.cmessage     = THIS.QBOParseError(lcErrorMsg)
               m.cType        = 'Exp Code'
               m.nqberror     = 0
               INSERT INTO qbbadnames FROM MEMVAR
               LOOP
            ENDIF

* Save the QBO id returned in the saved record to the clistid field in the wells table
            SELECT expcat
            REPLACE expcat.clistid WITH loRecord.ID
            lnAdded = lnAdded + 1
            WAIT CLEAR

         ENDSCAN

      CATCH TO loError

         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(13) + ;
              'Line:  ' + TRANSFORM(loError.LINENO), 16, 'Sync_Expcodes_as_Items')

      ENDTRY

      IF lnAdded > 0
         MESSAGEBOX('Sync Exp Codes: Added ' + TRANSFORM(lnAdded) + ' Items to QBO', 64, 'Sync Exp Codes with QBO', 2000)
      ENDIF

***************************************
   PROCEDURE QBAccounts
***************************************
      LPARA tcAccount, tlDescOnly, tlCursorOnly, tnDatasession

      LOCAL loResults, llReturn, loRecord

* Returns the QBO Chart of Accounts

      llReturn = .T.

      TRY

         lnDatasession = SET('datasession')

         IF tlCursorOnly
            IF TYPE('tnDataSession') = 'N'
               TRY
                  SET DATASESSION TO (tnDatasession)
               CATCH TO loError
               ENDTRY
            ELSE
               tnDatasession = 1
            ENDIF
         ENDIF

* create output cursors
         CREATE CURSOR accounts (cAcctDesc c(60), clistid c(36), cAcctType c(25), cacctno c(7), nListOrder i)
         INDEX ON nListOrder TAG nListOrder
         INDEX ON clistid    TAG clistid
         INDEX ON cAcctDesc TAG cAcctDesc
         INDEX ON cAcctType TAG cAcctType

         loQBO = THIS.oQBO

* Create a class entity object
         THIS.oAccountEntity = loQBO.CreateEntityObj('account')

* Get all the classes currently in QBO
         WAIT WINDOW NOWAIT 'Getting all accounts from QBO...'
         loResults = THIS.oAccountEntity.GETALL()
         WAIT CLEAR

         IF VARTYPE(loResults) # 'O'
            THIS.cErrorMsg = 'Unable to retrieve accounts from QBO at this time...'
            lnCount        = 0
            llReturn       = .F.
            EXIT
         ELSE
            lnCount = loResults.COUNT
         ENDIF

         swclose('qboaccounts')
* Save the results to a cursor if any records were returned.
         lcResult = THIS.oAccountEntity.ObjArrayToCursor(loResults, 'qboaccounts', tnDatasession)

         IF NOT EMPTY(lcResult)
            THIS.cErrorMsg = 'Unable to retrieve accounts from QBO at this time...'
            llReturn       = .F.
            EXIT
         ENDIF

         SELECT qboaccounts
         SCAN
            SCATTER MEMVAR
            m.cAcctDesc = m.name
            m.clistid   = m.id

            IF m.acctnum # '.NULL.'
               m.cacctno = m.acctnum
            ELSE
               m.cacctno = ''
            ENDIF

            lnType      = m.AccountType

            DO CASE
               CASE lnType = 0
                  lcType       = 'Bank'
                  m.nListOrder = 0
               CASE lnType = 1
                  lcType       = 'Accounts Receivable'
                  m.nListOrder = 1
               CASE lnType = 2
                  lcType       = 'Other Current Asset'
                  m.nListOrder = 2
               CASE lnType = 3
                  lcType       = 'Fixed Asset'
                  m.nListOrder = 3
               CASE lnType = 4
                  lcType       = 'Other Asset'
                  m.nListOrder = 4
               CASE lnType = 5
                  lcType       = 'Accounts Payable'
                  m.nListOrder = 5
               CASE lnType = 6
                  lcType       = 'Credit Card'
                  m.nListOrder = 6
               CASE lnType = 7
                  lcType       = 'Other Current Liability'
                  m.nListOrder = 7
               CASE lnType = 8
                  lcType       = 'Long Term Liability'
                  m.nListOrder = 8
               CASE lnType = 9
                  lcType       = 'Equity'
                  m.nListOrder = 9
               CASE lnType = 10
                  lcType       = 'Income'
                  m.nListOrder = 10
               CASE lnType = 11
                  lcType       = 'Cost of Goods Sold'
                  m.nListOrder = 11
               CASE lnType = 12
                  lcType       = 'Expense'
                  m.nListOrder = 12
               CASE lnType = 13
                  lcType       = 'Other Income'
                  m.nListOrder = 13
               CASE lnType = 14
                  lcType       = 'Other Expense'
                  m.nListOrder = 14
               CASE lnType = 15
                  lcType       = 'Non-Posting'
                  m.nListOrder = 15
               OTHERWISE
                  lcType = ''
            ENDCASE

            m.cAcctType = lcType

            INSERT INTO accounts FROM MEMVAR

         ENDSCAN

      CATCH TO loError
         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(13) + ;
              'Line:  ' + TRANSFORM(loError.LINENO), 16, 'QBAccounts')

      ENDTRY

      SET DATASESSION TO lnDatasession

      RETURN llReturn

***************************
   PROCEDURE qbitems
***************************
      LPARA tnDatasession
      LOCAL llReturn, lnDatasession

*
* Returns a cursor of QBO items
*

      llReturn = .T.

      TRY
         lnDatasession = SET('Datasession')

         IF TYPE('tnDataSession') = 'N'
            TRY
               SET DATASESSION TO (tnDatasession)
            CATCH TO loError
            ENDTRY
         ELSE
            MESSAGEBOX('Bad datasession passed to qbitems.', 16, 'QBItems')
            llReturn = .F.
            EXIT
         ENDIF

* create output cursors
         CREATE CURSOR qbitems (citemid c(31), clistid c(36))
         INDEX ON citemid TAG citemid

         loQBO = THIS.oQBO

* Create a class entity object
         THIS.oItemEntity = loQBO.CreateEntityObj('item')

* Get all the classes currently in QBO
         WAIT WINDOW NOWAIT 'Getting all items from QBO...'
         loResults = THIS.oItemEntity.GETALL()
         WAIT CLEAR

         IF VARTYPE(loResults) # 'O'
            THIS.cErrorMsg = 'Unable to retrieve items from QBO at this time...'
            lnCount        = 0
            llReturn       = .F.
            EXIT
         ELSE
            lnCount = loResults.COUNT
         ENDIF

         swclose('qboitems')
* Save the results to a cursor if any records were returned.
         lcResult = THIS.oAccountEntity.ObjArrayToCursor(loResults, 'qboitems', tnDatasession)

         IF NOT EMPTY(lcResult)
            THIS.cErrorMsg = 'Unable to retrieve items from QBO at this time...'
            llReturn       = .F.
            EXIT
         ENDIF

         SELECT qboitems
         SCAN
            SCATTER MEMVAR

            m.citemid = qboitems.NAME
            m.clistid = qboitems.ID
            INSERT INTO qbitems FROM MEMVAR

         ENDSCAN

      CATCH TO loError
         MESSAGEBOX('Error: ' + loError.MESSAGE + CHR(13) + ;
              'Line:  ' + TRANSFORM(loError.LINENO), 16, 'QBItems')

      ENDTRY

      SET DATASESSION TO lnDatasession

      RETURN llReturn

***************************************
   FUNCTION ValidObject(toObj)
***************************************

      IF VARTYPE(toObj) # 'O'
         RETURN .F.
      ELSE
         RETURN .T.
      ENDIF

***************************************
   PROCEDURE Error_Recovery()
***************************************

* Not sure what is needed here yet - pws 7/4/22


***************************
   FUNCTION Create_QBBadnames
***************************
      LPARAMETERS tnDatasession

      IF VARTYPE(tnDatasession) = 'N'
         TRY
            SET DATASESSION TO (tnDatasession)
         CATCH
         ENDTRY
      ENDIF

      CREATE CURSOR qbbadnames ;
         (cid    c(10), ;
           cname  c(40), ;
           cType  c(15), ;
           cmessage m, ;
           nqberror i)


******************************
   FUNCTION QBOParseError(tcText)
******************************
      LOCAL lcText, lnTextLen, lnQBOLoc, lnNETLoc, lnLength

      lnTextLen = LEN(tcText)
      lnQBOLoc  = AT('QBO API Inner', tcText) + 25
      lnNETLoc  = AT('.NET Inner Exceptions:', tcText)

      lnLength = lnNETLoc - lnQBOLoc

      lcText = SUBSTR(tcText, lnQBOLoc, lnLength)

      RETURN lcText


ENDDEFINE


****************************************************************************
* QBOBill - Class to operate on QBO Bills
****************************************************************************
DEFINE CLASS QBOBills AS CUSTOM
*******************************

   oJSON       = .NULL.
   oQBOAPI     = .NULL.
   oBillEntity = .NULL.

   cErrorMsg   = ''

*******************************
   FUNCTION INIT(loQBOAPI)
*******************************

      THIS.oQBOAPI = loQBOAPI

*******************************
   PROCEDURE oBillEntity_Access
*******************************

      IF VARTYPE(THIS.oBillEntity) # 'O'
         THIS.oBillEntity = THIS.oQBOAPI.CreateEntityObj('bill')
      ENDIF

      RETURN THIS.oBillEntity

   ENDPROC

*******************************
   PROCEDURE oJSON_Access
*******************************

      IF VARTYPE(THIS.oJSON) # '0'
         THIS.oJSON = CREATEOBJECT('wwjsonserializer')
      ENDIF

      RETURN THIS.oJSON

   ENDPROC

*******************************
   PROCEDURE GetBillObject
*******************************
* Returns a QBO Bill object
      LPARAMETERS tcID, tcCursor
      LOCAL loResults, lcJSON, loBill

      loBill = .NULL.

      TEXT TO lcQuery NOSHOW TEXTMERGE
         SELECT * FROM bill WHERE id = '<<tcID>>'
      ENDTEXT

      lcJSON  = THIS.oQBOAPI.QueryJson(m.lcQuery)

      IF VARTYPE(lcJSON) = 'C'
         loBills  = THIS.oJSON.DeserializeJson(lcJSON)
         IF loBills.queryresponse.TotalCount > 0
            loBill = loBills.queryresponse.Bill.ITEM[1]
         ENDIF
      ELSE
         MESSAGEBOX(THIS.oQBOAPI.cErrorMsg, 64, 'QueryBill')
      ENDIF

      RETURN loBill

   ENDPROC

*******************************
   PROCEDURE GetBillCursor
*******************************
* Returns a QBO Bill object
      LPARAMETERS tcID, tcCursor, tnDatasession
      LOCAL loResults, lcJSON, loBill

      loBill   = .NULL.
      llReturn = .T.

      IF VARTYPE(tcCursor) # 'C'
         tcCursor = 'curBill'
      ENDIF

      IF VARTYPE(tnDatasession) # 'N'
         tnDatasession = 1
      ENDIF

* Create a bill entity object
      THIS.oBillEntity = THIS.oQBOAPI.CreateEntityObj('bill')

* Query the classes in QBO
      loResults = THIS.oBillEntity.GET(tcID)
      WAIT CLEAR

      IF VARTYPE(loResults) # 'O'
         THIS.cErrorMsg = 'Unable to retrieve bill from QBO at this time...'
         lnCount        = 0
         llReturn       = .F.
         EXIT
      ENDIF

      swclose(tcCursor)
* Save the results to a cursor if any records were returned.
      lcResult = THIS.oBillEntity.ObjToCursor(loResults, tcCursor, tnDatasession)

      IF NOT EMPTY(lcResult)
         THIS.cErrorMsg = 'Unable to retrieve bill from QBO at this time...'
         llReturn       = .F.
         EXIT
      ENDIF

      RETURN llReturn

   ENDPROC

***********************
   PROCEDURE AddBill
***********************
      LPARAMETERS tcBatch, tcCursorH, tcCursorD
      LOCAL llReturn
*
* tcBatch   = Batch No of the bill to add
* tcCursorH = Name of bill header cursor
* tcCursorD = Name of bill detail cursor


      llReturn = .T.

      TRY
         IF VARTYPE(tcBatch) # 'C' OR EMPTY(tcBatch)
            THIS.cErrorMsg = 'Batch No is missing from call.'
            llReturn       = .F.
            EXIT
         ENDIF

         IF VARTYPE(tcCursorH) # 'C' OR EMPTY(tcCursorH)
            tcCursorH = 'appurchh'
         ENDIF
         IF VARTYPE(tcCursorD) # 'C' OR EMPTY(tcCursorD)
            tcCursorD = 'appurchd'
         ENDIF

         IF NOT USED(tcCursorH)
            swselect(tcCursorH)
         ENDIF

         SELECT (tcCursorH)
         LOCATE FOR cBatch = tcBatch
         IF NOT FOUND()
            THIS.cErrorMsg = 'Batch No: ' + tcBatch + ' was not found.'
            llReturn       = .F.
            EXIT
         ELSE
* Check to see if this bill has already been added to QBO
            IF NOT EMPTY(cTxnID)
               THIS.cErrorMsg = 'This bill has already been added to QBO.'
               llReturn       = .F.
               EXIT
            ENDIF
         ENDIF

         SCATTER MEMVAR

* Get the Default AP Account
         swselect('apopt')
         GO TOP
         lcDefAPAcct = apopt.cQBAPAcct
         USE IN apopt
         
         loBridge = THIS.oQBOAPI.oShared.oBridge

* Create a bill entity object
*         THIS.oBillEntity = THIS.oQBOAPI.CreateEntityObj('bill')
         loBillEntity = this.oBillEntity

         IF THIS.ValidObject(THIS.oBillEntity)
            loRecord = THIS.oBillEntity.New()

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Failed to get a new bill record.'
               llReturn       = .F.
               EXIT
            ENDIF
         ELSE
            llReturn = .F.
            EXIT 
         ENDIF

* Get the Vendor ID code
         swselect('vendor')
         LOCATE FOR cvendorid = m.cvendorid
         IF FOUND()
            loVendorRef = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')

            IF NOT THIS.ValidObject(loVendorRef)
               THIS.cErrorMsg = 'Unable to create the VendorRef object.'
               llReturn       = .F.
               EXIT
            ENDIF

            loVendorRef.NAME   = ALLTRIM(vendor.cvendname)
            loVendorRef.Value  = ALLTRIM(vendor.clistid)
            loRecord.VendorRef = loVendorRef

            loAPAcctRef = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')

            IF NOT THIS.ValidObject(loAPAcctRef)
               THIS.cErrorMsg = 'Unable to create the AP AcctRef object.'
               llReturn       = .F.
               EXIT
            ENDIF

            IF NOT EMPTY(m.cQBAPAcct)
               loAPAcctRef.VALUE = ALLTRIM(m.cQBAPAcct)
            ELSE
               loAPAcctRef.VALUE = ALLTRIM(lcDefAPAcct)
            ENDIF
            loRecord.APAccountRef = loAPAcctRef

            loSalesTermRef = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')

            IF NOT THIS.ValidObject(loSalesTermRef)
               THIS.cErrorMsg = 'Unable to create the TermAcctRef object.'
               llReturn       = .F.
               EXIT
            ENDIF

            swselect('terms')
            LOCATE FOR cidterm = m.cidterm
            IF FOUND()
               loSalesTermRef.VALUE  = ALLTRIM(clistid)
               loSalesTermRef.NAME   = ALLTRIM(ctermdesc)
               loRecord.SalesTermRef = loSalesTermRef
            ENDIF

            loRecord.TxnDate   = m.dInvDate
            loRecord.DueDate   = m.dDueDate
            loRecord.DocNumber = m.cInvNum

            loLines = loBridge.CreateArray('Intuit.Ipp.Data.Line')
            IF NOT this.ValidObject(loLines)
               this.cErrorMsg = 'Unable to create the detail array of lines.'
               llReturn = .f.
               EXIT
            ENDIF 
            
            lnLine = 1
* Add line items
            SELECT(tcCursorD)
            SCAN FOR cBatch == m.cBatch
               SCATTER MEMVAR 
               loLine             = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.Line')
               loLine.DetailType  = loBridge.GetEnumValue('Intuit.Ipp.Data.LineDetailTypeEnum.AccountBasedExpenseLineDetail')
               loLine.DetailTypeSpecified = .T.
               loLine.Amount      = CAST(m.nExtension as Currency)
               loLine.AmountSpecified = .T.
               loLine.DESCRIPTION = ALLTRIM(m.cItemDesc)
               loLine.LineNum     = lnLine
               lnLine             = lnLine + 1
               
               loAcctBasedExpLineDet = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.AccountBasedExpenseLineDetail')

               loAcctRefd = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')

               IF NOT THIS.ValidObject(loAcctRefd)
                  THIS.cErrorMsg = 'Unable to create the AcctRef object.'
                  llReturn       = .F.
                  EXIT
               ENDIF

               loAcctRefd.value  = ALLTRIM(m.cAcctListID)
               loAcctBasedExpLineDet.AccountRef = loAcctRefD
               
* Get the class from the well record
               IF NOT EMPTY(m.cUnitNo)
                  swselect('wells')
                  LOCATE FOR cwellid = m.cUnitNo
                  IF FOUND()
                     loClassRef       = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')
                     loClassRef.value = ALLTRIM(wells.clistid)
                     loAcctBasedExpLineDet.ClassRef  = loClassRef
                  ENDIF
               ENDIF
               
               loLine.AnyIntuitObject = loAcctBasedExpLineDet

               loLines.ADDITEM(loLine)
               
            ENDSCAN

            loLines.AssignTo(loRecord, 'Line')
            loBillRecord = THIS.oBillEntity.Add(loRecord)

            IF NOT THIS.ValidObject(loBillRecord)
               THIS.cErrorMsg = 'Unable to add the bill at this time.'
               llReturn       = .F.
               
               LOCAL lcErrMsg
               
               IF NOT EMPTY(this.oBillEntity.cErrorMsg)
                  lcErrMsg = this.oBillEntity.cErrorMsg
               ELSE 
                  lcErrrMsg = NVL(this.oQBOAPI.cErrorMsg,"Unknown")
               ENDIF 
               MESSAGEBOX('Failed to add new bill record!' + CHR(13) + ;
                          'Error: ' + lcErrMsg,16,'Add Bill to QBO')
               EXIT
            ENDIF

         ENDIF
      CATCH TO loError 
         MESSAGEBOX('Error adding bill!' + CHR(13) + loError.Message + CHR(13) + 'Line: ' + TRANSFORM(loError.LineNo),16,'QBOBill.AddBill')
      ENDTRY
 ENDPROC
 
 ***********************
   PROCEDURE UpdateBill
***********************
      LPARAMETERS tcBatch, tcCursorH, tcCursorD
      LOCAL llReturn
*
* tcBatch   = Batch No of the bill to add
* tcCursorH = Name of bill header cursor
* tcCursorD = Name of bill detail cursor


      llReturn = .T.

      TRY
         IF VARTYPE(tcBatch) # 'C' OR EMPTY(tcBatch)
            THIS.cErrorMsg = 'Batch No is missing from call.'
            llReturn       = .F.
            EXIT
         ENDIF

         IF VARTYPE(tcCursorH) # 'C' OR EMPTY(tcCursorH)
            tcCursorH = 'appurchh'
         ENDIF
         IF VARTYPE(tcCursorD) # 'C' OR EMPTY(tcCursorD)
            tcCursorD = 'appurchd'
         ENDIF

         IF NOT USED(tcCursorH)
            swselect(tcCursorH)
         ENDIF

         SELECT (tcCursorH)
         LOCATE FOR cBatch = tcBatch
         IF NOT FOUND()
            THIS.cErrorMsg = 'Batch No: ' + tcBatch + ' was not found.'
            llReturn       = .F.
            EXIT
         ELSE
* Check to see if this bill has already been added to QBO
            IF EMPTY(cTxnID)
               THIS.cErrorMsg = 'This bill has not been added to QBO. It must be added before it can be updated'
               llReturn       = .F.
               EXIT
            ENDIF
         ENDIF

         SCATTER MEMVAR

* Get the Default AP Account
         swselect('apopt')
         GO TOP
         lcDefAPAcct = apopt.cQBAPAcct
         USE IN apopt
         
         loBridge = THIS.oQBOAPI.oShared.oBridge

* Create a bill entity object
*         THIS.oBillEntity = THIS.oQBOAPI.CreateEntityObj('bill')
         loBillEntity = this.oBillEntity

         IF THIS.ValidObject(THIS.oBillEntity)
            loRecord = THIS.oBillEntity.Get(m.cTxnID)

            IF NOT THIS.ValidObject(loRecord)
               THIS.cErrorMsg = 'Failed to get a the requested bill record.'
               llReturn       = .F.
               EXIT
            ENDIF
         ELSE
            llReturn = .F.
            EXIT 
         ENDIF

* Get the Vendor ID code
         swselect('vendor')
         LOCATE FOR cvendorid = m.cvendorid
         IF FOUND()
            loVendorRef = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')

            IF NOT THIS.ValidObject(loVendorRef)
               THIS.cErrorMsg = 'Unable to create the VendorRef object.'
               llReturn       = .F.
               EXIT
            ENDIF

            loVendorRef.NAME   = ALLTRIM(vendor.cvendname)
            loVendorRef.Value  = ALLTRIM(vendor.clistid)
            loRecord.VendorRef = loVendorRef

            loAPAcctRef = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')

            IF NOT THIS.ValidObject(loAPAcctRef)
               THIS.cErrorMsg = 'Unable to create the AP AcctRef object.'
               llReturn       = .F.
               EXIT
            ENDIF

            IF NOT EMPTY(m.cQBAPAcct)
               loAPAcctRef.VALUE = ALLTRIM(m.cQBAPAcct)
            ELSE
               loAPAcctRef.VALUE = ALLTRIM(lcDefAPAcct)
            ENDIF
            loRecord.APAccountRef = loAPAcctRef

            loSalesTermRef = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')

            IF NOT THIS.ValidObject(loSalesTermRef)
               THIS.cErrorMsg = 'Unable to create the TermAcctRef object.'
               llReturn       = .F.
               EXIT
            ENDIF

            swselect('terms')
            LOCATE FOR cidterm = m.cidterm
            IF FOUND()
               loSalesTermRef.VALUE  = ALLTRIM(clistid)
               loSalesTermRef.NAME   = ALLTRIM(ctermdesc)
               loRecord.SalesTermRef = loSalesTermRef
            ENDIF

            loRecord.TxnDate   = m.dInvDate
            loRecord.DueDate   = m.dDueDate
            loRecord.DocNumber = m.cInvNum

            loLines = loBridge.CreateArray('Intuit.Ipp.Data.Line')
            IF NOT this.ValidObject(loLines)
               this.cErrorMsg = 'Unable to create the detail array of lines.'
               llReturn = .f.
               EXIT
            ENDIF 
            
            lnLine = 1
* Add line items
            SELECT(tcCursorD)
            SCAN FOR cBatch == m.cBatch
               SCATTER MEMVAR 
               loLine             = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.Line')
               loLine.DetailType  = loBridge.GetEnumValue('Intuit.Ipp.Data.LineDetailTypeEnum.AccountBasedExpenseLineDetail')
               loLine.DetailTypeSpecified = .T.
               loLine.Amount      = CAST(m.nExtension as Currency)
               loLine.AmountSpecified = .T.
               loLine.DESCRIPTION = ALLTRIM(m.cItemDesc)
               loLine.LineNum     = lnLine
               lnLine             = lnLine + 1
               
               loAcctBasedExpLineDet = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.AccountBasedExpenseLineDetail')

               loAcctRefd = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')

               IF NOT THIS.ValidObject(loAcctRefd)
                  THIS.cErrorMsg = 'Unable to create the AcctRef object.'
                  llReturn       = .F.
                  EXIT
               ENDIF

               loAcctRefd.value  = ALLTRIM(m.cAcctListID)
               loAcctBasedExpLineDet.AccountRef = loAcctRefD
               
* Get the class from the well record
               IF NOT EMPTY(m.cUnitNo)
                  swselect('wells')
                  LOCATE FOR cwellid = m.cUnitNo
                  IF FOUND()
                     loClassRef       = THIS.oBillEntity.CreateInstance('Intuit.Ipp.Data.ReferenceType')
                     loClassRef.value = ALLTRIM(wells.clistid)
                     loAcctBasedExpLineDet.ClassRef  = loClassRef
                  ENDIF
               ENDIF
               
               loLine.AnyIntuitObject = loAcctBasedExpLineDet

               loLines.ADDITEM(loLine)
               
            ENDSCAN

            loLines.AssignTo(loRecord, 'Line')
            loBillRecord = THIS.oBillEntity.Add(loRecord)

            IF NOT THIS.ValidObject(loBillRecord)
               THIS.cErrorMsg = 'Unable to add the bill at this time.'
               llReturn       = .F.
               
               LOCAL lcErrMsg
               
               IF NOT EMPTY(this.oBillEntity.cErrorMsg)
                  lcErrMsg = this.oBillEntity.cErrorMsg
               ELSE 
                  lcErrrMsg = NVL(this.oQBOAPI.cErrorMsg,"Unknown")
               ENDIF 
               MESSAGEBOX('Failed to add new bill record!' + CHR(13) + ;
                          'Error: ' + lcErrMsg,16,'Add Bill to QBO')
               EXIT
            ENDIF

         ENDIF
      CATCH TO loError 
         MESSAGEBOX('Error adding bill!' + CHR(13) + loError.Message + CHR(13) + 'Line: ' + TRANSFORM(loError.LineNo),16,'QBOBill.AddBill')
      ENDTRY
 ENDPROC
 
 ***************************************
   FUNCTION ValidObject(toObj)
***************************************

      IF VARTYPE(toObj) # 'O'
         RETURN .F.
      ELSE
         RETURN .T.
      ENDIF
ENDDEFINE






















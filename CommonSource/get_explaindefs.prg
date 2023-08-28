LPARAMETERS tnDataSession
LOCAL loIP AS 'wwftp'
LOCAL lcLibrary, lcSourceFile, lcTargetFile, lcType, llReturn, llSupport, llUpdate, lnCount, lnMax
LOCAL lnResult, loUpdate, loerror
*:Global cexplanation, tcType


STORE .T. TO llReturn
STORE .F. TO llUpdate

IF VARTYPE(tcType) # 'C'
	tcType = '*'
ENDIF

TRY

	IF VARTYPE(tnDataSession) = 'N'
		SET DATASESSION TO (tnDataSession)
	ENDIF

	lcLibrary = SET('library')

	llSupport = checksupportexp()

	IF NOT llSupport
		llReturn = .F.
		EXIT
	ENDIF

	swclose('explaindefs')

	lcSourceFile = 'explaindefs.dbf'
	lcTargetFile = 'datafiles\explaindefs.dbf'
	loUpdate              = m.goApp.oUpdate
	loUpdate.cSourceFile  = lcSourceFile
	loUpdate.cTargetFile  = lcTargetFile
	loUpdate.cDescription = 'Import Field Explanations'
	loUpdate.cUnzipTo     = m.goApp.cRptsFolder
	llReturn              = loUpdate.GetUpdate(.T.)

	lcSourceFile          = 'explaindefs.fpt'
	lcTargetFile          = 'datafiles\explaindefs.fpt'
	loUpdate.cSourceFile  = lcSourceFile
	loUpdate.cTargetFile  = lcTargetFile
	llReturn              = loUpdate.GetUpdate(.T.)

	IF llReturn AND FILE(lcTargetFile)
		swselect('importexplain')
		DELETE ALL

		USE (m.goApp.cCommonFolder + "\explaindefs") IN 0
		SET DELETED OFF 
		SELECT explaindefs
		SCAN FOR NOT DELETED()
			SCATTER MEMVAR MEMO
			m.cexplanation = m.cexplain
			SELECT importexplain
			LOCATE FOR DELETED()
			IF FOUND()
			    recall
				GATHER MEMVAR MEMO 
			ELSE 
   				INSERT INTO importexplain FROM MEMVAR
   			ENDIF 		
		ENDSCAN
		swclose('explaindefs')
		ERASE (lcTargetFile)
		SET DELETED ON 
	ENDIF

CATCH TO loerror
	llReturn = .F.
	DO errorlog WITH 'Get_ExplainDefs', loerror.LINENO, 'Maps', loerror.ERRORNO, loerror.MESSAGE
ENDTRY

RETURN llReturn





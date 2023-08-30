*enum CursorTypeEnum
#define adOpenUnspecified	-1
#define adOpenForwardOnly	0
#define adOpenKeyset		1
#define adOpenDynamic		2
#define adOpenStatic		3

*enum CursorOptionEnum
#define adHoldRecords		0x100
#define adMovePrevious		0x200
#define adAddNew			0x1000400
#define adDelete			0x1000800
#define adUpdate			0x1008000
#define adBookmark			0x2000
#define adApproxPosition	0x4000
#define adUpdateBatch		0x10000
#define adResync			0x20000
#define adNotify			0x40000
#define adFind				0x80000

*enum LockTypeEnum
#define adLockUnspecified		-1
#define adLockReadOnly			1
#define adLockPessimistic		2
#define adLockOptimistic		3
#define adLockBatchOptimistic	4

*enum ExecuteOptionEnum
#define adOptionUnspecified		-1
#define adAsyncExecute			0x10
#define adAsyncFetch			0x20
#define adAsyncFetchNonBlocking	0x40
#define adExecuteNoRecords		0x80

*enum ConnectOptionEnum
#define adConnectUnspecified	-1
#define adAsyncConnect			0x10

*enum ObjectStateEnum
#define adStateClosed			0
#define adStateOpen				0x1
#define adStateConnecting		0x2
#define adStateExecuting		0x4
#define adStateFetching			0x8

*enum CursorLocationEnum
#define adUseNone			1
#define adUseServer			2
#define adUseClient			3

*enum DataTypeEnum
#define adEmpty				0
#define adTinyInt			16
#define adSmallInt			2
#define adInteger			3
#define adBigInt			20
#define adUnsignedTinyInt	17
#define adUnsignedSmallInt	18
#define adUnsignedInt		19
#define adUnsignedBigInt	21
#define adSingle			4
#define adDouble			5
#define adCurrency			6
#define adDecimal			14
#define adNumeric			131
#define adBoolean			11
#define adError				10
#define adUserDefined		132
#define adVariant			12
#define adIDispatch			9
#define adIUnknown			13
#define adGUID				72
#define adDate				7
#define adDBDate			133
#define adDBTime			134
#define adDBTimeStamp		135
#define adBSTR				8
#define adChar				129
#define adVarChar			200
#define adLongVarChar		201
#define adWChar				130
#define adVarWChar			202
#define adLongVarWChar		203
#define adBinary			128
#define adVarBinary			204
#define adLongVarBinary		205
#define adChapter			136
#define adFileTime			64
#define adDBFileTime		137
#define adPropVariant		138
#define adVarNumeric		139

*enum FieldAttributeEnum
#define adFldUnspecified	-1
#define adFldMayDefer		0x2
#define adFldUpdatable		0x4
#define adFldUnknownUpdatable	0x8
#define adFldFixed			0x10
#define adFldIsNullable		0x20
#define adFldMayBeNull		0x40
#define adFldLong			0x80
#define adFldRowID			0x100
#define adFldRowVersion		0x200
#define adFldCacheDeferred	0x1000
#define adFldNegativeScale	0x4000
#define adFldKeyColumn		0x8000

*enum EditModeEnum
#define adEditNone			0
#define adEditInProgress	0x1
#define adEditAdd			0x2
#define adEditDelete		0x4

*enum RecordStatusEnum
#define adRecOK					0
#define adRecNew				0x1
#define adRecModified			0x2
#define adRecDeleted			0x4
#define adRecUnmodified			0x8
#define adRecInvalid			0x10
#define adRecMultipleChanges	0x40
#define adRecPendingChanges		0x80
#define adRecCanceled			0x100
#define adRecCantRelease		0x400
#define adRecConcurrencyViolation	0x800
#define adRecIntegrityViolation	0x1000
#define adRecMaxChangesExceeded	0x2000
#define adRecObjectOpen			0x4000
#define adRecOutOfMemory		0x8000
#define adRecPermissionDenied	0x10000
#define adRecSchemaViolation	0x20000
#define adRecDBDeleted			0x40000

*enum GetRowsOptionEnum
#define adGetRowsRest			-1

*enum PositionEnum
#define adPosUnknown			-1
#define adPosBOF				-2
#define adPosEOF				-3

*enum BookmarkEnum
#define adBookmarkCurrent		0
#define adBookmarkFirst			1
#define adBookmarkLast			2

*enum MarshalOptionsEnum
#define adMarshalAll			0
#define adMarshalModifiedOnly	1

*enum AffectEnum
#define adAffectCurrent			1
#define adAffectGroup			2
#define adAffectAll				3
#define adAffectAllChapters		4

*enum ResyncEnum
#define adResyncUnderlyingValues	1
#define adResyncAllValues			2

*enum CompareEnum
#define adCompareLessThan			0
#define adCompareEqual				1
#define adCompareGreaterThan		2
#define adCompareNotEqual			3
#define adCompareNotComparable		4

*enum FilterGroupEnum
#define adFilterNone				0
#define adFilterPendingRecords		1
#define adFilterAffectedRecords		2
#define adFilterFetchedRecords		3
#define adFilterPredicate			4
#define adFilterConflictingRecords	5

*enum SearchDirectionEnum
#define adSearchForward				1
#define adSearchBackward			-1

*enum PersistFormatEnum
#define adPersistADTG				0
#define adPersistXML				1

*enum StringFormatEnum
#define adClipString				2

*enum ADCPROP_UPDATECRITERIA_ENUM
#define adCriteriaKey				0
#define adCriteriaAllCols			1
#define adCriteriaUpdCols			2
#define adCriteriaTimeStamp			3

*enum ADCPROP_ASYNCTHREADPRIORITY_ENUM
#define adPriorityLowest			1
#define adPriorityBelowNormal		2
#define adPriorityNormal			3
#define adPriorityAboveNormal		4
#define adPriorityHighest			5

*enum ConnectPromptEnum
#define adPromptAlways				1
#define adPromptComplete			2
#define adPromptCompleteRequired	3
#define adPromptNever				4

*enum ConnectModeEnum
#define adModeUnknown			0
#define adModeRead				1
#define adModeWrite				2
#define adModeReadWrite			3
#define adModeShareDenyRead		4
#define adModeShareDenyWrite	8
#define adModeShareExclusive	0xc
#define adModeShareDenyNone		0x10

*enum IsolationLevelEnum
#define adXactUnspecified		0xffffffff
#define adXactChaos				0x10
#define adXactReadUncommitted	0x100
#define adXactBrowse			0x100
#define adXactCursorStability	0x1000
#define adXactReadCommitted		0x1000
#define adXactRepeatableRead	0x10000
#define adXactSerializable		0x100000
#define adXactIsolated			0x100000

*enum XactAttributeEnum
#define adXactCommitRetaining	0x20000
#define adXactAbortRetaining	0x40000
#define adXactAsyncPhaseOne		0x80000
#define adXactSyncPhaseOne		0x100000

*enum PropertyAttributesEnum
#define adPropNotSupported		0
#define adPropRequired			0x1
#define adPropOptional			0x2
#define adPropRead				0x200
#define adPropWrite				0x400


*enum ParameterAttributesEnum
#define adParamSigned			0x10
#define adParamNullable			0x40
#define adParamLong				0x80

*enum ParameterDirectionEnum
#define adParamUnknown			0
#define adParamInput			0x1
#define adParamOutput			0x2
#define adParamInputOutput		0x3
#define adParamReturnValue		0x4

*enum CommandTypeEnum
#define adCmdUnspecified		-1
#define adCmdUnknown			0x8
#define adCmdText				0x1
#define adCmdTable				0x2
#define adCmdStoredProc			0x4
#define adCmdFile				0x100
#define adCmdTableDirect		0x200

*enum EventStatusEnum
#define adStatusOK				0x1
#define adStatusErrorsOccurred	0x2
#define adStatusCantDeny		0x3
#define adStatusCancel			0x4
#define adStatusUnwantedEvent	0x5

*enum EventReasonEnum
#define adRsnAddNew				1
#define adRsnDelete				2
#define adRsnUpdate				3
#define adRsnUndoUpdate			4
#define adRsnUndoAddNew			5
#define adRsnUndoDelete			6
#define adRsnRequery			7
#define adRsnResynch			8
#define adRsnClose				9
#define adRsnMove				10
#define adRsnFirstChange		11
#define adRsnMoveFirst			12
#define adRsnMoveNext			13
#define adRsnMovePrevious		14
#define adRsnMoveLast			15

*enum SchemaEnum
#define adSchemaProviderSpecific		-1
#define adSchemaAsserts					0
#define adSchemaCatalogs				1
#define adSchemaCharacterSets			2
#define adSchemaCollations				3
#define adSchemaColumns					4
#define adSchemaCheckConstraints		5
#define adSchemaConstraintColumnUsage	6
#define adSchemaConstraintTableUsage	7
#define adSchemaKeyColumnUsage			8
#define adSchemaReferentialContraints	9
#define adSchemaTableConstraints		10
#define adSchemaColumnsDomainUsage		11
#define adSchemaIndexes					12
#define adSchemaColumnPrivileges		13
#define adSchemaTablePrivileges			14
#define adSchemaUsagePrivileges			15
#define adSchemaProcedures				16
#define adSchemaSchemata				17
#define adSchemaSQLLanguages			18
#define adSchemaStatistics				19
#define adSchemaTables					20
#define adSchemaTranslations			21
#define adSchemaProviderTypes			22
#define adSchemaViews					23
#define adSchemaViewColumnUsage			24
#define adSchemaViewTableUsage			25
#define adSchemaProcedureParameters		26
#define adSchemaForeignKeys				27
#define adSchemaPrimaryKeys				28
#define adSchemaProcedureColumns		29
#define adSchemaDBInfoKeywords			30
#define adSchemaDBInfoLiterals			31
#define adSchemaCubes					32
#define adSchemaDimensions				33
#define adSchemaHierarchies				34
#define adSchemaLevels					35
#define adSchemaMeasures				36
#define adSchemaProperties				37
#define adSchemaMembers					38

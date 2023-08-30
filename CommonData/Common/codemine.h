*++
* CodeMine VFP Application Framework common header file.
*
* Copyright 1995-2005 Soft Classics, Ltd. All rights reserved.
*--
* Version update history:
*
*  5/24/2005 (7501) - Fixed problem in cmdevprojectmanager where it still looked to 
*                     the Common50 folder for list of language subfolders. Changed to
*                     look in Common folder instead.
*--
#include win32.h
#define EVALUATION_ONLY .F.
#define CODEMINE_FOUNDATION_VERSION '7.5'
#define MIN_FLL_VERSION 2010

#define SYSREG_CODEMINE_ROOT 'SoftWare\Soft Classics\CodeMine'

* cmLookupManager lookup tag data array column offsets.
#define KEYLIST_WORKAREA           1   && Workarea tag applies to
#define KEYLIST_TAG_NAME           2   && Tag or field name
#define KEYLIST_PHONETIC_TAG       3   && Name of phonetic index tag
#define KEYLIST_DISPLAY_NAME       4   && Localized name for display purposes
#define KEYLIST_DISPLAY_EXPRESSION 5   && Expression to display in "hit" list
#define KEYLIST_LOOKUP_CLASS       6   && Class to use as lookup engine
#define KEYLIST_FLAGS              7   && Lookup Option flag bitmask
#define KEYLIST_NCOLS              7   && Number of columns to allocate

* Lookup key option flag bits
#define LOOKUPFLAG_ORDER           0   && Key can be used for navigation order
#define LOOKUPFLAG_LOOKUP          1   && Key can be used for lookups
#define LOOKUPFLAG_CHECKFLAGS      3   && Set when flag mask needs to be verified as supported.
#define LOOKUPFLAG_FINDALL         8   && Find all possible matches
#define LOOKUPFLAG_PHONETIC        9   && Use phonetic matching if a phonetic index is available
#define LOOKUPFLAG_PARTIAL        10   && Accept partial matches
#define LOOKUPFLAG_NICKNAME       11   && Match on nicknames when using proper name lookups
#define LOOKUPFLAG_RANGE          12   && Accept a range of values
* Mask equivilents for above flag bits. Use INT() so VFP doesnt default values to floating point.
#define LOOKUPMASK_ORDER           INT(2 ^ LOOKUPFLAG_ORDER)
#define LOOKUPMASK_LOOKUP          INT(2 ^ LOOKUPFLAG_LOOKUP)
#define LOOKUPMASK_TAGTYPE         INT(LOOKUPMASK_ORDER + LOOKUPMASK_LOOKUP)
#define LOOKUPMASK_CHECKFLAGS      INT(2 ^ LOOKUPFLAG_CHECKFLAGS)
#define LOOKUPMASK_FINDALL         INT(2 ^ LOOKUPFLAG_FINDALL)
#define LOOKUPMASK_PHONETIC        INT(2 ^ LOOKUPFLAG_PHONETIC)
#define LOOKUPMASK_PARTIAL         INT(2 ^ LOOKUPFLAG_PARTIAL)
#define LOOKUPMASK_NICKNAME        INT(2 ^ LOOKUPFLAG_NICKNAME)
#define LOOKUPMASK_RANGE           INT(2 ^ LOOKUPFLAG_RANGE)

* Foundation control flag bit definitions.
#define CTLFLAG_RULE_VIOLATION     1   && flag set when field rule is violated.
#define CTLFLAG_ESCAPE             2   && Internal flag set on escape press
#define CTLFLAG_VALUE_LOADED       3   && Flag set when data is loaded into control on Init method.
#define CTLFLAG_HELP_INITIALIZED   4   && Tooltip & statusbar text have been translated
#define CTLFLAG_DATA_MANAGER       5   && Form has a data manager object
#define CTLFLAG_SKIP_VALID         6   && Control's Valid() should just return .T. when set.
#define CTLFLAG_REFRESHING         7   && Datamanager Refresh()/AfterChange() callback in progress
#define CTLFLAG_BOUND_COLUMN       8   && Control is in a grid, bound to column's controlSource
#define CTLFLAG_INGRID             9   && Control is contained in a grid.
#define CTLFLAG_NULL              10   && Control's value is null, though display may not be while focused.
#define CTLFLAG_HAS_FOCUS         11   && Set for some controls while the control has focus.
#define CTLFLAG_SELECT_ALL        12   && Select all text on next mouseUp
#define CTLFLAG_RELOAD_WORKAREA   13   && Reload cWorkarea value on first refresh on delayed binding.

#define CTLFLAG_RESET_CARET       16  && Fix insertion point (txtNumeric only)
#define CTLFLAG_INITIALIZED       16  && Recordset initialized (nav controls & Grid only)
#define CTLFLAG_SEARCHING         17  && Grids Only - Incremental search in progress 
#define CTLFLAG_FIRST_CLICK       17  && Cbo Only - Used to prevent popup of combos in a grid on first click
#define CTLFLAG_POPPED            18  && Cbo Only - Set when the dropdown part of a cbo is open.

* Flag values for SetPage() method of Pageframe control.
#define PAGEMASK_NOFOCUS           2  && Don't set focus to the new page
#define PAGEMASK_SKIP_VALID        4  && Don't validate before page change

* Form state flag bits
#define FRMFLAG_ACTIVE             1  && This bit set when form is the active form
#define FRMFLAG_BATCHING_MESSAGES  2  && This bit set when form is batching error messages
#define FRMFLAG_SKIP_VALID         3  && Don't enforce field validation during cancel
#define FRMFLAG_HELP_INITIALIZED   4  && Value must match CTLFLAG_HELP_INITIALIZED
#define FRMFLAG_OPEN               5  && This bit set when form is opened for the first time
#define FRMFLAG_CODEMINE_ENV       6  && Set when form requires app object & Codemine runtime env.
#define FRMFLAG_REFRESH_CELL       7  && Current cell in a grid needs refresh when it gets focus. Used by ActivateNextControl().
#define FRMFLAG_READ_CONFIRMCLOSE  8  && Read lConfirmSave property setting from appreg when RegistryUpdate() triggered.
#define FRMFLAG_READ_CONFIRMDELETE 9  && Read lConfirmSave property setting from appreg when RegistryUpdate() triggered.
#define FRMFLAG_READ_CONFIRMSAVE  10  && Read lConfirmSave property setting from appreg when RegistryUpdate() triggered.
#define FRMFLAG_NAVIGATING        11  && Record navigation in progress (used by frmModalDataChild).
#define FRMFLAG_FORCE_RELOAD      15  && Force reload of control values during refresh cycle.

* Cursor state flag bits
#define CURSORFLAG_RESETFLAGS	   1  && Set if position flags need updating
#define CURSORFLAG_TOP             2  && If true, current record is the first one.
#define CURSORFLAG_BOTTOM          3  && If true, current record is the last one.
#define CURSORFLAG_MAPPED          4  && Set when cursor has been mapped into CDE cursor map.
#define CURSORFLAG_RECNO_CHANGED   5  && Record number of a record is changed after TABLEUPDATE()

* CDE State flag bit masks
#define CDEMASK_FORM               1  && Part of a form. Don't allow Private DataSession, or lAutoOpen.
#define CDEMASK_DESIGN_TIME        2  && Don't create runtime properties.
#define CDEMASK_NORULES            4  && Don't link rule to a cursor object created by AddCursor()
#define CDEMASK_NOEXPOSE           8  && Don't expose linked child CDE cursors to parent CDE's GetCursor()
#define CDEMASK_ENUM_NESTED       16  && Include cursors in nested CDEs in host EnumCursors() results.
#define CDEMASK_ENUM_NOIGNORED    32  && Exclude cursors with lIgnore = .T. from EnumCursors() results.
#define CDEMASK_DATAFORM          64  && Part of a Data Form, with Datra Manager.
#define CDEMASK_CHILD            128  && This is a contained child CDE (not set for linked child CDE)

* Cursor Clone() method flag bit masks
#define CLONEMASK_NOBUFFER         1  && Do not apply original cursor's buffermode
#define CLONEMASK_NOCDE            2  && Create free Cursor object outside of CDE

* Cursor Update/Revert method option flag bit masks
#define UPDATEMASK_NOSAVE          1  && Do not save/restore current record position in the cursor.
#define UPDATEMASK_NOVALID	       2  && Do not enforce validation rules for this operation
#define UPDATEMASK_NOCHILDREN      4  && Do not include child records in the current operation
#define UPDATEMASK_OBEY_SETKEY     8  && Obey any SET KEY filter in effect
#define UPDATEMASK_NOUNLOCK	      16  && Do not unlock records after operation
#define UPDATEMASK_NOEVENTS       32  && Do not trigger rule events for this operation
#define UPDATEMASK_COMMIT         64  && Commit operation even if not required by buffering mode.
#define UPDATEMASK_REQUERY       128  && Requery a view cursor after successful DeleteWhere() call.
#define UPDATEMASK_NOCLOSE       256  && Leave the current LocalTrans level active after commit/rollback.

* Cursor Update/Revert method option flag bit masks
#define TRANMASK_FORCENEW          1  && Force a new transaction level
#define TRANMASK_REMOTEONLY        2  && Start a remote transaction only, without a VFP transaction

* Cursor Local Transaction flag masks
#define LOCALTRANS_REVERT_ON_ROLLBACK 1   && Use TABLEREVERT() to rollback record state
#define LOCALTRANS_NO_RECORD          2   && No record exists - create new record on rollback

* Cursor rule execution control bit flags.
#define RULEFLAG_ANDED             1   && Results of this rule are ANDed together if set, ORed if not set.
#define RULEFLAG_NOCALLBACK        2   && This rule does not callback to DM/BO level on execution.
#define RULEFLAG_DM_ONLY           3   && Only execute the rule method for DM level rule objects.
* Mask equivilents
#define RULEMASK_ANDED             INT(2 ^ RULEFLAG_ANDED)
#define RULEMASK_ORED              0   && For explicitly passing a RULEFLAG_ANDED bit off
#define RULEMASK_NOCALLBACK        INT(2 ^ RULEFLAG_NOCALLBACK)
#define RULEMASK_DM_ONLY           INT(2 ^ RULEFLAG_DM_ONLY)

* Data Object Error mode flag masks
#define ERRMASK_SILENT_WARNING     1   && Don't display "handled" warning messages
#define ERRMASK_SILENT_FATAL       2   && Don't display fatal error messages
#define ERRMASK_SILENT_MESSAGE     4   && Don't display messages via DisplayMessage() method.
#define ERRMASK_SILENT_ALL         7   && Combination of all 3 ERRMASK_SILENT_* bits
#define ERRMASK_NOMSGMAN           8   && Do NOT use Message Manager for any error display

* Registry key types.
#define KEY_TYPE_CATEGORY          1
#define KEY_TYPE_CHAR              2
#define KEY_TYPE_MEMO              3
#define KEY_TYPE_POPUP             4
#define KEY_TYPE_NUMERIC           5
#define KEY_TYPE_LOGICAL           6
#define KEY_TYPE_PATH              7
#define KEY_TYPE_BINARY            8
#define KEY_TYPE_ENUM              9
#define KEY_TYPE_COUNTER          10

#define KEY_ACCESS_NONE            0
#define KEY_ACCESS_DEVELOPER       0
#define KEY_ACCESS_ADMIN           1
#define KEY_ACCESS_VIEW            2
#define KEY_ACCESS_USEREDIT        3

#define KEY_PATH_TABLE             1
#define KEY_PATH_ONLY              2
#define KEY_PATH_FILE              3

#define KEY_REPLICATE_NONE         0
#define KEY_REPLICATE_USER         1

* Flag option bits for app registry object SetKey() method
#define REGMASK_BROADCAST          1   && Broadcast a RegistryUpdate() event after the change.
#define REGMASK_LOG                2   && Record the key change in the event log.

* App Registry key paths for common global objects
#define KEYNAME_CASE_DELIMITERS     '%Local.Propercase Rules.Delimiters'
#define KEYNAME_CASE_EXCEPTIONS     '%Local.Propercase Rules.Exceptions'
#define KEYNAME_CASE_STOPONUPPER    '%Local.Propercase Rules.Stop On Upper'

#define KEYNAME_MALE_PREFIX_LIST    '%Local.Name Parsing Rules.Male Salutation List'
#define KEYNAME_FEMALE_PREFIX_LIST  '%Local.Name Parsing Rules.Female Salutation List'
#define KEYNAME_NEUTRAL_PREFIX_LIST '%Local.Name Parsing Rules.Neutral Salutation List'
#define KEYNAME_LAST_PREFIX_LIST    '%Local.Name Parsing Rules.Last Name Prefix List'
#define KEYNAME_SUFFIX_LIST         '%Local.Name Parsing Rules.Suffix List'
#define KEYNAME_DISPLAY_LAST_FIRST  '%Local.Name Parsing Rules.Display Last Name First'
#define KEYNAME_STORE_LAST_FIRST    '%Local.Name Parsing Rules.Store Last Name First'
#define KEYNAME_UPPER_NAME          '%Local.Name Parsing Rules.Force Uppercase'
#define KEYNAME_PERIOD_INITIAL      '%Local.Name Parsing Rules.Period After Initials'
#define KEYNAME_DOUBLE_PREFIX       '%Local.Name Parsing Rules.Allow Double Prefix'
#define KEYNAME_NAME_COMPONENTS     '%Local.Name Parsing Rules.Name Components'

#define KEYNAME_LOOKUP_PHONETIC     '%Local.Search Rules.Phonetic Function'
#define KEYNAME_LOOKUP_MAXHITS      '%Local.Search Rules.Maximum Hits'
#define KEYNAME_LOOKUP_SORT         '%Local.Search Rules.Sort Results'

#define KEYNAME_AUTO_TAB            '%Local.Data Entry.Auto Tab When Full'
#define KEYNAME_CONFIRM_DELETE      '%Local.Data Entry.Confirm Delete'
#define KEYNAME_CONFIRM_CLOSE       '%Local.Data Entry.Confirm Save on Close'
#define KEYNAME_CONFIRM_SAVE        '%Local.Data Entry.Confirm Save on Navigate'
#define KEYNAME_CENTURY             '%Local.Data Entry.Current Century'
#define KEYNAME_ROLLOVER            '%Local.Data Entry.Rollover Year'

* Character representations of common binary values.
#define BIN_ZERO                 CHR(0)
#define BIN_SHORT_ZERO           REPLICATE(CHR(0), 2)
#define BIN_LONG_ZERO            REPLICATE(CHR(0), 4)

* Counter value return types and reset periods.
#define COUNTER_TYPE_INT         0    && Binary Integer
#define COUNTER_TYPE_NUMERIC     10   && Base 10
#define COUNTER_TYPE_HEX         16   && Base 16
#define COUNTER_TYPE_CHAR        36   && Base 36 (letters & digits)
#define COUNTER_TYPE_BASE62      62   && Base 62 (mixed case letters & digits)
#define COUNTER_TYPE_ASCII       95   && Base 95 (Printable characters)
#define COUNTER_TYPE_BIN         256  && Base 256 (Character format integer)

#define COUNTER_RESET_WRAP      0
#define COUNTER_RESET_YEAR      1
#define COUNTER_RESET_MONTH     2
#define COUNTER_RESET_WEEK      3
#define COUNTER_RESET_DAY       4

#define MSG_TYPE_DIALOG         1
#define MSG_TYPE_TEXT           2
#define MSG_TYPE_PROMPT         3

#define MSG_DIALOG_CONFIRM_OK   1
#define MSG_DIALOG_CONFIRM_OKC  2
#define MSG_DIALOG_CONFIRM_YN   3
#define MSG_DIALOG_CONFIRM_YNC  4
#define MSG_DIALOG_CONFIRM_RC   5
#define MSG_DIALOG_INFORM       6
#define MSG_DIALOG_TEXT         7
#define MSG_DIALOG_STATUS		8

* cmMessage class severity codes.
#define MSG_SEVERITY_INFORM      1
#define MSG_SEVERITY_WARNING     2
#define MSG_SEVERITY_QUESTION    3
#define MSG_SEVERITY_ERROR       4

* cmMessage aLanguage array column offsets
#define LANGUAGE_ID              1
#define LANGUAGE_PARENT          2

* cmMessageValue message key translation array column values
#define MSGVAL_LANG_ID           1
#define MSGVAL_FIELD_SHORT       2
#define MSGVAL_FIELD_LONG        3
#define MSGVAL_FIELD_TIP         3
#define MSGVAL_FIELD_PROMPT      4
#define MSGVAL_FIELD_RICH        4

* Event log codes (used by security module)
#define EVENT_TYPE_SECURITY     'Security'
#define EVENT_TYPE_REGISTRY     'Registry'
#define EVENT_TYPE_ERROR        'Error'
#define EVENT_TYPE_APP          'Application'

#define EVENT_SEC_LOGON         'Logon'
#define EVENT_SEC_LOGOFF        'Logoff'	
#define EVENT_SEC_LOGONFAIL     'LogonFail'
#define EVENT_SEC_ADDUSER       'AddUser'
#define EVENT_SEC_GRPMEMBER     'GroupMembership'
#define EVENT_SEC_PRIV          'PrivChange'
#define EVENT_SEC_GRPDEFINE     'GroupDefine'
#define EVENT_SEC_PASSCHANGE    'ChangePassword'
#define EVENT_SEC_DEVMODE       'DeveloperMode'
#define EVENT_SEC_DEBUGMODE     'DebugMode'
#define EVENT_SEC_LOGENABLE     'EventLogEnable'
#define EVENT_SEC_LOGDISABLE    'EventLogDisable'

#define EVENT_REG_EDIT          'KeyEdit'
#define EVENT_REG_DELETE        'KeyDelete'
#define EVENT_REG_CREATE        'KeyCreate'
#define EVENT_REG_WRITE_ERROR   'WriteError'

* Context menu bar number definitions for forms and controls.
* Bars 1-15 are reserved for form-only bars. It is not necessary to use unique
* bar numbers across different context menus, but doing so makes the bar 
* translation cache more efficient, since translations are indexed by bar number.
#define CTX_BAR_FRM_HELP      1
#define CTX_BAR_FRM_SEP1      2
#define CTX_BAR_FRM_CENTER    3
#define CTX_BAR_FRM_RESTORE   4
#define CTX_BAR_FRM_SEP2      5
#define CTX_BAR_FRM_EDITMODE  6
#define CTX_BAR_FRM_SEP3      7
#define CTX_BAR_FRM_SAVE      8
#define CTX_BAR_FRM_CANCEL    9
#define CTX_BAR_FRM_SEP4     10
#define CTX_BAR_FRM_NEW      11
#define CTX_BAR_FRM_DELETE   12
#define CTX_BAR_FRM_SEP5     13
#define CTX_BAR_FRM_DEBUG    14
#define CTX_BAR_FRM_SUSPEND  15
#define CTX_BAR_FRM_REFRESH  16

#define CTX_BAR_TBR_HELP       1
#define CTX_BAR_TBR_SEP1       2
#define CTX_BAR_TBR_CLOSE      3
#define CTX_BAR_TBR_SEP2       4
#define CTX_BAR_TBR_DOCKTOP    5
#define CTX_BAR_TBR_DOCKLEFT   6
#define CTX_BAR_TBR_DOCKRIGHT  7
#define CTX_BAR_TBR_DOCKBOTTOM 8
#define CTX_BAR_TBR_SEP3       9
#define CTX_BAR_TBR_VIEW       10

#define CTX_BAR_CTL_HELP      20
#define CTX_BAR_CTL_SEP1      21
#define CTX_BAR_CTL_UNDO      22
#define CTX_BAR_CTL_REVERT    23
#define CTX_BAR_CTL_SEP2      24
#define CTX_BAR_CTL_ZOOM      25
#define CTX_BAR_CTL_SEP3      26
#define CTX_BAR_CTL_SETMEM    27
#define CTX_BAR_CTL_INSMEM    28
#define CTX_BAR_CTL_CLRMEM    29
#define CTX_BAR_CTL_SEP4      30
#define CTX_BAR_CTL_AUTOMEM   31
#define CTX_BAR_CTL_COLUMNS   32
#define CTX_BAR_CTL_SEP5      33
#define CTX_BAR_CTL_NEW       34
#define CTX_BAR_CTL_EDIT      35
#define CTX_BAR_CTL_DELETE    36
#define CTX_BAR_CTL_NULL      37
#define CTX_BAR_CTL_QUICKPOP  38
#define CTX_BAR_CTL_QUICK_SEP 39
#define CTX_BAR_CUSTOM        40   && Custom bar numbers for individual forms or controls


* Define offsets into our form color element array.
#define WINCOLOR_FOREGROUND       1
#define WINCOLOR_BACKGROUND       2
#define WINCOLOR_EDIT_FOREGROUND  3
#define WINCOLOR_EDIT_BACKGROUND  4
#define WINCOLOR_HIGHLIGHT        5
#define WINCOLOR_SHADOW           6
#define WINCOLOR_DARK_SHADOW      7
#define WINCOLOR_TITLE_BAR        8

* Misc constants
#define CR_LF CHR(13) + CHR(10)

* ReleaseType values passed to BeforeClose() CodeMine form method.
* Developer-specific value codes start at -100.
#define CLOSE_BY_RELEASE   0    && Form object var released
#define CLOSE_BY_CONTROL   1    && Forms close box clicked
#define CLOSE_BY_QUIT      2    && Quiting FoxPro
#define CLOSE_BY_OK       -1    && OK/Yes/Retry Button pushed
#define CLOSE_BY_APPLY    -2    && Apply (Save but dont close) Button pushed
#define CLOSE_BY_CANCEL   -3    && Cancel button pushed
#define CLOSE_BY_NO       -4    && NO Button pushed
* Obsolete names for backward compatibility
#define SAVE_BY_RELEASE   0    && Form object var released
#define SAVE_BY_CONTROL   1    && Forms close box clicked
#define SAVE_BY_QUIT      2    && Quiting FoxPro
#define SAVE_BY_OK       -1    && OK/Yes/Retry Button pushed
#define SAVE_BY_SAVE     -2    && Apply (Save but dont close) Button pushed
#define SAVE_BY_CANCEL   -3    && Cancel button pushed

* State manager callback reason bitmask definations
#define CBR_STATE_CHANGE   1     && Enabled state of file/edit menu items changed
#define CBR_TOGGLE         2     && Capslock/Numlock changed
#define CBR_MAIN_RESIZE    4     && Main window resized.
#define CBR_WINDOW_CHANGE  8     && Active window changed.
#define CBR_LEFT_MOUSE     16    && A trapped left mouse click occured.
#define CBR_RIGHT_MOUSE    32    && A trapped right mouse click occured.
#define CBR_IDLE           64    && Idle loop entered

* State Manager Mouse button trap mask values
#define MOUSE_CTL_RIGHT    1
#define MOUSE_SHIFT_RIGHT  2
#define MOUSE_CTL_LEFT     4
#define MOUSE_SHIFT_LEFT   8

* Application object toolbar list array column offsets
#define TOOL_NAME         1
#define TOOL_REFCOUNT     2
#define TOOL_MEMORY       3
#define TOOL_NCOLS        3

* FontMetric() function codes
#DEFINE TM_HEIGHT           1
#DEFINE TM_ASCENT           2
#DEFINE TM_DESCENT          3
#DEFINE TM_INTERNALLEADING  4
#DEFINE TM_EXTERNALLEADING  5
#DEFINE TM_AVECHARWIDTH     6
#DEFINE TM_MAXCHARWIDTH     7
#DEFINE TM_WEIGHT           8
#DEFINE TM_ITALIC           9
#DEFINE TM_UNDERLINED      10
#DEFINE TM_STRUCKOUT       11
#DEFINE TM_FIRSTCHAR       12
#DEFINE TM_LASTCHAR        13
#DEFINE TM_DEFAULTCHAR     14
#DEFINE TM_BREAKCHAR       15
#DEFINE TM_PITCHANDFAMILY  16
#DEFINE TM_CHARSET         17
#DEFINE TM_OVERHANG        18
#DEFINE TM_ASPECTX         19
#DEFINE TM_ASPECTY         20

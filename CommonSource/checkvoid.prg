*
*   Called by the dmcheklf.frx form to void the next check if the stub goes
*   to the next page.
*
LPARA tnPageNo, tcCheckNo, tcidchec
LOCAL lcSelect

lcSelect = SELECT()

SELE options
llVoidNext = lVoidNext

IF NOT llVoidNext
   RETURN ''
ENDIF
   
*
*  Create work cursor so we know what check numbers to add to
*  the register as voids
*
IF NOT USED('chkvoid')
    CREATE CURSOR chkvoid ;
        (ccheckno   C(10), ;
         cPeriod    C(2), ;
         cYear      C(4), ;
         dCheckDate D, ;
         dPostDate  D, ;
         cdmbatch   C(8), ;
         cGroup     C(2), ;
         cidchec    C(8), ;
         cacctno    C(6), ;
         cid        C(10), ;
         cidtype    C(1), ;
         cdesc      C(10))
ENDIF

*
*  Work cursor to keep track of what page we're on
*  This proc is called from the detail area of the check,
*  so we don't want to create a void record on each call,
*  just when we go to a new page.
*
IF NOT USED('chkpage')
    CREATE CURSOR chkpage ;
        (pageno   N(2), ;
         cidchec  C(8))
ENDIF

*
*  Get a handle on the checktmp file so we can
*  shift the check numbers if we need to void
*  one.
IF NOT USED('chktmp1')
    USE DBF('checktmp') IN 0 AGAIN ALIAS chktmp1
ENDIF

*  If the page no is 1, we don't need to
*  do anything
IF tnPageNo = 1
    m.ccheckno = tcCheckNo
    m.cidchec  = tcidchec
    m.cdesc    = 'Check'
    SELECT (lcSelect)
    RETURN ''
ELSE
    * The page no is greater than 1 so we need
    * to check to see if we've processed this
    * page before.  If not, we'll add a void
    * record to our work cursor and increment
    * the check numbers in the checktmp cursor.
    SELE checktmp
    SCATTER MEMVAR
    SELE chkpage
    LOCATE FOR pageno = tnPageNo AND cidchec = tcidchec
    IF NOT FOUND()
        SELE chktmp1
        SCAN FOR ccheckno > tcCheckNo
            lcCheckNo = PADL(ALLT(STR(VAL(ccheckno)+1)),10,' ')
            REPL ccheckno WITH lcCheckNo
        ENDSCAN
        tcCheckNo = PADL(ALLT(STR(VAL(tcCheckNo)+tnPageNo-1)),10,' ')
        m.ccheckno = tcCheckNo

        SELE chkvoid
        LOCATE FOR ccheckno = m.ccheckno
        IF NOT FOUND()
            m.cdesc    = 'VOID'
            INSERT INTO chkvoid FROM MEMVAR
        ENDIF
        m.pageno = tnPageNo
        m.cidchec = tcidchec
        INSERT INTO chkpage FROM MEMVAR
    ENDIF
    SELECT (lcSelect)
    RETURN ''
ENDIF


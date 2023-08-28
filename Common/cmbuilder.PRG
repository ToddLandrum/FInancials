LPARAMETERS oTarget, cSource, cOther, cSpecial
*++
* This program replaces the default VFP builder.app in order to dispatch
* to the correct CodeMine class builder when necessary. The Builder.dbf appoach
* is not flexible enough for our needs here.
*
* The default VFP builder is called if we do not dispatch to our own handler here.
*--
LOCAL ix, aDataEnvironment[1], aDataObjs[1], aObjects[1] 
LOCAL nObjects, lNewObject, cFormClass

  IF PCOUNT() > 0  && If no parameters, we don't do anything
    IF VARTYPE(m.oTarget) = 'O' AND EMPTY(m.cSpecial)
      * Get a list of all selected objects
      m.nObjects = ASELOBJ(aObjects)
      m.lNewObject = (m.cSource == 'TOOLBOX')

      * Get a reference to the form, if contained in one
      m.oThisForm = m.oTarget
      DO WHILE NOT m.oThisForm.BaseClass == 'Form' ;
      AND NOT m.oThisForm.BaseClass == 'Toolbar' ;
      AND NOT m.oThisForm.BaseClass == 'Dataenvironment'
        IF m.oThisForm.Parent.Class == 'Form'
          EXIT   && The only base Form class we should find is the class designer itself.
        ENDIF
        m.oThisForm = m.oThisForm.Parent
      ENDDO

      IF PEMSTATUS(m.oThisForm, 'cClass', 5)
        m.cFormClass = PROPER(m.oThisForm.cClass)
      ELSE
        m.cFormClass = PROPER(m.oThisForm.Class)
      ENDIF

      DO CASE
        CASE m.cFormClass == 'Cmcursor'
          IF PEMSTATUS(m.oTarget, 'cClass', 5)  && Allow nested cursors for crosstabs.
            IF m.nObjects = 1 AND PROPER(m.oTarget.cClass) == 'Cmcursor'
              RETURN DoBuilder('frmCursorBuilder', m.oTarget)
            ENDIF
          ENDIF
          RETURN DoBuilder('frmCursorBuilder', m.oThisForm)
        CASE m.cFormClass == 'Cmdataenvironment'
          IF PEMSTATUS(m.oTarget, 'cClass', 5)
            IF m.nObjects = 1 AND PROPER(m.oTarget.cClass) == 'Cmcursor'
              RETURN DoBuilder('frmCursorBuilder', m.oTarget)
            ENDIF
          ENDIF
          RETURN DoBuilder('frmCDEBuilder', m.oThisForm)
*        CASE PROPER(m.oTarget.Baseclass) == 'Form'
*          RETURN DoBuilder('frmFormBuilder', m.oThisForm)
      ENDCASE
    ENDIF

    * Dispatch to the default VFP builder if we don't handle this class ourself.
    IF EMPTY(_SCREEN.cVFPBuilder)
      _SCREEN.cVFPBuilder = HOME() + 'builder.app'
    ENDIF
    IF NOT EMPTY (_SCREEN.cVFPBuilder) AND FILE(_SCREEN.cVFPBuilder)
      DO (_SCREEN.cVFPBuilder) WITH m.oTarget, m.cSource, m.cOther, m.cSpecial
    ENDIF
  ENDIF
  RETURN .T.

FUNCTION DoBuilder(cBuilder, oTarget)
LOCAL oBuilder

  DO (_SCREEN.cCodemineCommonPath + 'cmStart') WITH 'LoadAPILibrary'
  SET CLASSLIB TO (_SCREEN.cCodemineCommonPath + 'cmBuilder') ADDITIVE 
  SET CLASSLIB TO (_SCREEN.cCodemineCommonPath + 'cmDialog') ADDITIVE 

  m.oBuilder = CREATEOBJECT(m.cBuilder, m.oTarget)
  IF VARTYPE(m.oBuilder) = 'O'
    m.oBuilder.Show()
    IF VARTYPE(m.oBuilder) = 'O'  && Test again in case it was released
      RETURN m.oBuilder.ReturnValue()
    ENDIF
  ENDIF
  RETURN .F.
ENDFUNC

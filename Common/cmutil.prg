*++
* CodeMine utility and string formatting functions.
*
* These utility functions are used primarily by reports. Reports have no object
* context, so it is generally easier to access traditional style procedures and
* functions from within report expressions.
*
* Copyright 1996,1997 Soft Classics, Ltd. All rights reserved.
*--

#include "CodeMine.h"

FUNCTION NumToWords(nNumber)
*++
*>>Function to convert numeric to words, eg: 120.12 -> "One Hunred Twenty and 12/100"
* Currently, only English is supported.
*--
#define WORD_LENGTH 9
LOCAL ix, cDecimals, cResult, cBuffer
LOCAL cDigits, cTens, cScale
LOCAL nScale, nInteger, nHundreds, nTens, nDigit

  m.cDigits = 'Zero     One      Two      Three    Four     Five     Six      Seven    Eight    Nine     Ten      Eleven   Twelve   Thirteen Fourteen Fifteen  Sixteen  SeventeenEighteen Nineteen '
  m.cTens = 'Ten      Twenty   Thirty   Forty    Fifty    Sixty    Seventy  Eighty   Ninety   '
  m.cScale = '         Thousand Million  Billion  Trillion *********'

  m.nInteger = INT(m.nNumber)
  m.cDecimals = ' and ' + PADL(LTRIM(STR(ROUND(m.nNumber % 1, 2) * 100)), 2, '0') + '/100'
  m.cResult = ''
  m.ix = 0
  DO WHILE m.nInteger > 0
    m.nScale = m.nInteger % 1000
    m.nInteger = INT(m.nInteger / 1000)

    m.nHundreds = INT(m.nScale / 100)
    m.nTens = m.nScale % 100
    m.cBuffer = ''
    IF m.nHundreds > 0
      m.cBuffer = TRIM(SUBSTR(m.cDigits, m.nHundreds * WORD_LENGTH + 1, WORD_LENGTH)) + ' Hundred '
    ENDIF
    DO CASE
      CASE m.nTens = 0
        * do nothing
      CASE m.nTens < 20
        m.cBuffer = m.cBuffer + TRIM(SUBSTR(m.cDigits, m.nTens * WORD_LENGTH + 1, WORD_LENGTH))
      OTHERWISE
        m.nDigit = m.nTens % 10
        m.nTens = INT(m.nTens / 10) - 1
        m.cBuffer = m.cBuffer + TRIM(SUBSTR(m.cTens, m.nTens * WORD_LENGTH + 1, WORD_LENGTH))
        IF m.nDigit > 0
          m.cBuffer = m.cBuffer + ' ' + TRIM(SUBSTR(m.cDigits, m.nDigit * WORD_LENGTH + 1, WORD_LENGTH))
        ENDIF
    ENDCASE
    IF m.ix > 0
      m.cResult = TRIM(TRIM(m.cBuffer) + ' ' + TRIM(SUBSTR(m.cScale, m.ix  * WORD_LENGTH + 1, WORD_LENGTH)) + ' ' + m.cResult)
    ELSE
      m.cResult = TRIM(m.cBuffer)
    ENDIF
    m.ix = m.ix + 1
  ENDDO
  IF EMPTY(m.cResult)
    m.cResult = TRIM(LEFT(m.cDigits, WORD_LENGTH))    && Zero
  ENDIF
  RETURN m.cResult + m.cDecimals
ENDFUNC


FUNCTION DisplayName(cSalute, cFirst, cMiddle, cLast, cSuffix)
*++
*>>Return a formated personal name string from standard component fields.
*--
LOCAL cFullName
  m.cFullName = IIF(EMPTY(NVL(m.cSalute, '')), '', TRIM(m.cSalute) + ' ')
  m.cFullName = m.cFullName + IIF(EMPTY(NVL(m.cFirst,'')), '', TRIM(m.cFirst) ;
                            + IIF(LEN(TRIM(m.cFirst)) = 1, '. ',' '))
  m.cFullName = m.cFullName + IIF(EMPTY(NVL(m.cMiddle,'')), '', TRIM(m.cMiddle) ;
                            + IIF(LEN(TRIM(m.cMiddle)) = 1, '. ',' '))
  m.cFullName = m.cFullName + IIF(EMPTY(NVL(m.cLast,'')), '', TRIM(m.cLast) + ' ')

  * Replace any underscores with space before returning
  RETURN CHRTRAN(TRIM(m.cFullName + IIF(EMPTY(NVL(m.cSuffix,'')), '', TRIM(m.cSuffix))), '_', ' ')
ENDFUNC


FUNCTION DisplayNameLastFirst(cSalute, cFirst, cMiddle, cLast, cSuffix)
*++
*>>Return a formated personal name string, in "Lastname, Firstname" format.
*--
LOCAL cFullName
  m.cFullName = IIF(EMPTY(NVL(m.cLast,'')), '', TRIM(m.cLast) + ', ')

  m.cFullName = m.cFullName + IIF(EMPTY(NVL(m.cSalute,'')), '', TRIM(m.cSalute) + ' ')
  m.cFullName = m.cFullName + IIF(EMPTY(NVL(m.cFirst,'')), '', TRIM(m.cFirst) ;
                            + IIF(LEN(TRIM(m.cFirst)) = 1, '. ',' '))
  m.cFullName = m.cFullName + IIF(EMPTY(NVL(m.cMiddle,'')), '', TRIM(m.cMiddle) ;
                            + IIF(LEN(TRIM(m.cMiddle)) = 1, '. ',' '))

  * Replace any underscores with space before returning
  RETURN CHRTRAN(TRIM(m.cFullName + IIF(EMPTY(NVL(m.cSuffix,'')), '', TRIM(m.cSuffix))), '_', ' ')
ENDFUNC

FUNCTION SqlQuote(cString)
*++
* Return a string enclosed in single quotes ('), with embedded quote
* characters replaced with two quotes, according to the SQL Server quoting syntax.
*--
  RETURN "'" + STRTRAN(TRIM(m.cString), "'", "''") + "'"
  
**********************************************************************
* Program....: NumToStr
* Compiler...: Visual FoxPro 06.00.8492.00 for Windows
* Abstract...: Convert number into a text string
* Notes......: Handles Numbers up to 99,999,999 and will accommodate
* ...........: negative numbers.  Decimals are rounded to Two Places
* ...........: And returned as 'and xxxx hundredths'
************************************************************************
FUNCTION NumToStr
LPARAMETERS tnvalue
LOCAL lnHund, lnThou, lnHTho, lnMill, lnInt, lnDec
LOCAL llDecFlag, llHFlag, llTFlag, llMFlag, llNegFlag
LOCAL lcRetVal

*** Evaluate Parameters
DO CASE
    CASE TYPE('tnValue') # 'N'
        RETURN('')
    CASE tnvalue = 0
        RETURN 'Zero'
    CASE tnvalue < 0
        llNegFlag = .T.
        tnvalue = ABS(tnvalue)
    OTHERWISE
        llNegFlag = .F.
ENDCASE

*** Initialise Variables
STORE .F. TO llHFlag,llTFlag,llMFlag
STORE 0 TO lnHund, lnThou, lnMill
STORE "" TO lcRetVal
lnInt = INT(tnvalue)                    && Integer Portion

*** Check for Decimals
IF MOD( tnValue, 1) # 0                    && We Have Decimals
    lnDec = ROUND(MOD(tnvalue,1),2)        && Decimals Portion
    llDecFlag = .T.
ELSE
    llDecFlag = .F.
ENDIF

*** Do the Integer Portion
DO WHILE .T.
    DO CASE
        CASE lnInt < 100            && TENS
            IF EMPTY(lcRetVal)
                lcRetVal = lcRetVal + ALLTRIM(con_tens(lnInt))
            ELSE
*!*                    IF RIGHT(lcRetVal,5)#" and "
*!*                        lcRetVal = lcRetVal+' and '
*!*                    ENDIF    
                lcRetVal = lcRetVal + ALLTRIM(con_tens(lnInt))
            ENDIF
        CASE lnInt < 1000            && HUNDREDS
            lnHund = INT(lnInt/100)
            lnInt = lnInt - (lnHund*100)
            lcRetVal = lcRetVal + ALLTRIM(con_tens(lnHund)) + " Hundred"
            IF lnInt # 0
                lcRetVal = lcRetVal+" "
                LOOP
            ENDIF
        CASE lnInt < 100000            && THOUSANDS
            lnThou = INT(lnInt/1000)
            lnInt = lnInt - (lnThou*1000)
            lcRetVal = lcRetVal + ALLTRIM(con_tens(lnThou)) + " Thousand"
            IF lnInt # 0
                lcRetVal = lcRetVal + " "
                LOOP
            ENDIF
        CASE lnInt < 1000000        && Hundred Thousands
            lnHTho = INT(lnInt/100000)
            lnInt = lnInt - (lnHTho * 100000)
            lcRetVal = lcRetVal + ALLTRIM(con_tens(lnHTho)) + " Hundred"
            IF lnInt # 0
                lcRetVal = lcRetVal + " "
                LOOP
            ELSE
                lcRetVal = lcRetVal + " Thousand"
            ENDIF
        CASE lnInt < 100000000        && Millions
            lnMill = INT(lnInt/1000000)
            lnInt = lnInt - (lnMill * 1000000)
            lcRetVal = lcRetVal + ALLTRIM(con_tens(lnMill)) + " Million"
            IF lnInt # 0
                lcRetVal = lcRetVal + ", "
                LOOP
            ENDIF
    ENDCASE
    EXIT
ENDDO

*** Handle Decimals
IF llDecFlag
    lnDec = lnDec * 100
    lcRetVal = lcRetVal + " and " + PADL(transform(INT(lnDec)),2,'0') + '/100'
ELSE
   lcRetVal = lcRetVal + " and 00/100"
ENDIF

*** Handle Negative Numbers
IF llNegFlag
    lcRetVal = "[MINUS " + ALLTRIM(lcRetVal) + "]"
ENDIF
RETURN lcRetVal

***********************************************
*** Sub Function for NumToStr: Handle the TENS
***********************************************
FUNCTION Con_Tens
LPARAMETERS tndvalue
LOCAL lcStrVal, lcStrTeen
STORE '' TO lcStrVal,lcStrTeen
DO CASE
    CASE tnDValue < 20
        RETURN(con_teens(tnDValue))
    CASE tnDValue < 30
        lcStrVal = 'Twenty'
        tnDValue = tnDValue - 20
    CASE tnDValue < 40
        lcStrVal = 'Thirty'
        tnDValue = tnDValue - 30
    CASE tnDValue < 50
        lcStrVal = 'Forty'
        tnDValue = tnDValue - 40
    CASE tnDValue < 60
        lcStrVal = 'Fifty'
        tnDValue = tnDValue - 50
    CASE tnDValue < 70
        lcStrVal = 'Sixty'
        tnDValue = tnDValue - 60
    CASE tnDValue < 80
        lcStrVal = 'Seventy'
        tnDValue = tnDValue - 70
    CASE tnDValue < 90
        lcStrVal = 'Eighty'
        tnDValue = tnDValue - 80
    CASE tnDValue < 100
        lcStrVal = 'Ninety'
        tnDValue = tnDValue - 90
ENDCASE
lcStrTeen = con_teens(tnDValue)
IF LEN(lcStrTeen) # 0           && there was something there
    lcStrVal = lcStrVal + '-' + lcStrTeen
ENDIF
RETURN TRIM(lcStrVal)

***********************************************
*** Sub Function for NumToStr: Handle the Units/Teens
***********************************************
FUNCTION Con_Teens
LPARAMETERS tntvalue
DO CASE
    CASE tntvalue = 0
        RETURN('')
    CASE tntvalue = 1
        RETURN('One ')
    CASE tntvalue = 2
        RETURN('Two ')
    CASE tntvalue = 3
        RETURN('Three ')
    CASE tntvalue = 4
        RETURN('Four ')
    CASE tntvalue = 5
        RETURN('Five ')
    CASE tntvalue = 6
        RETURN('Six ')
    CASE tntvalue = 7
        RETURN('Seven ')
    CASE tntvalue = 8
        RETURN('Eight ')
    CASE tntvalue = 9
        RETURN('Nine ')
    CASE tntvalue = 10
        RETURN('Ten ')
    CASE tntvalue = 11
        RETURN('Eleven ')
    CASE tntvalue = 12
        RETURN('Twelve ')
    CASE tntvalue = 13
        RETURN('Thirteen ')
    CASE tntvalue = 14
        RETURN('Fourteen ')
    CASE tntvalue = 15
        RETURN('Fifteen ')
    CASE tntvalue = 16
        RETURN('Sixteen ')
    CASE tntvalue = 17
        RETURN('Seventeen ')
    CASE tntvalue = 18
        RETURN('Eighteen ')
    CASE tntvalue = 19
        RETURN('Nineteen ')
ENDCASE
  

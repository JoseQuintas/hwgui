/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Misc functions
 *
 * This is a container for several useful functions.
 * Don't forget to add the desription in the function docu, if
 * a new function is added.
 * Try to make versions for WinAPI and GTK equal.
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2020-2023 Wilfried Brunken, DF7BE
*/

#include "hwgui.ch"
#include "hbclass.ch"

FUNCTION hwg_IsLeapYear ( nyear )

   * nyear : a year to check for leap year
   * returns:
   * .T. a leap year
   * ================================= *
   RETURN ( ( (nyear % 4)  == 0 );
       .AND. ( ( nyear % 100 ) != 0 ) ;
       .OR.  ( ( nyear % 400 ) == 0 ) )

FUNCTION hwg_isWindows()

#ifndef __PLATFORM__WINDOWS
   RETURN .F.
#else
   RETURN .T.
#endif

FUNCTION hwg_CompleteFullPath( cPath )

   LOCAL  cDirSep := hwg_GetDirSep()

   IF RIGHT(cPath , 1 ) != cDirSep
      cPath := cPath + cDirSep
   ENDIF

   RETURN cPath

FUNCTION hwg_CreateTempfileName( cPrefix , cSuffix )

   LOCAL cPre , cSuff

   cPre  := IIF( cPrefix == NIL , "e" , cPrefix )
   cSuff := IIF( cSuffix == NIL , ".tmp" , cSuffix )

   RETURN hwg_CompleteFullPath( hwg_GetTempDir() ) + cPre + Ltrim(Str(Int(Seconds()*100))) + cSuff

FUNCTION hwg_CurDrive()

#ifdef __PLATFORM__WINDOWS
   RETURN hb_CurDrive() + ":\"
#else
   RETURN ""
#endif

FUNCTION hwg_CurDir()

#ifdef __PLATFORM__WINDOWS
   RETURN hwg_CurDrive() + CurDir()
#else
   RETURN "/" + CurDir()
#endif

FUNCTION hwg_GetUTCDateANSI

   * Format: YYYYMMDD, based on UTC

   RETURN SUBSTR(hwg_GetUTCTimeDate(), 3 , 8 )

FUNCTION hwg_GetUTCTime

   * Format: HH:MM:SS
   RETURN SUBSTR(hwg_GetUTCTimeDate(), 12 , 8 )

FUNCTION hwg_cHex2Bin (chexstr,cdebug)

   * Converts a hex string to binary
   * Returns empty string, if error
   * or number of hex characters is
   * odd.
   * chexstr:
   * Valid characters:
   * 0 ... 9 , A ... F , a ... f
   * Other characters are ignored.
   * cdebug : Set a string for debug.
   * The string appears at the beginning
   * of the logfile.
   * ================================= *

   LOCAL cbin, ncount, chs, lpos, nvalu, nvalue , nodd
   * lpos : F = MSB , T = LSB
   LOCAL ldebug

   IF cdebug == NIL
      ldebug := .F.
   ELSE
      ldebug := .T.
      hwg_xvalLog(cdebug)
   ENDIF
   cbin := ""
   lpos := .T.
   nvalue := 0
   nodd := 0
   IF (chexstr == NIL)
      RETURN ""
   ENDIF
   chexstr := UPPER(chexstr)
   IF ldebug
      hwg_xvalLog(chexstr)
   ENDIF
   FOR ncount := 1 TO LEN(chexstr)
      chs := SUBSTR(chexstr, ncount, 1 )
      IF chs $ "0123456789ABCDEF"
         nodd := nodd + 1  && Count valid chars for odd/even check
         DO CASE
         CASE chs == "0" ; nvalu := 0
         CASE chs == "1" ; nvalu := 1
         CASE chs == "2" ; nvalu := 2
         CASE chs == "3" ; nvalu := 3
         CASE chs == "4" ; nvalu := 4
         CASE chs == "5" ; nvalu := 5
         CASE chs == "6" ; nvalu := 6
         CASE chs == "7" ; nvalu := 7
         CASE chs == "8" ; nvalu := 8
         CASE chs == "9" ; nvalu := 9
         CASE chs == "A" ; nvalu := 10
         CASE chs == "B" ; nvalu := 11
         CASE chs == "C" ; nvalu := 12
         CASE chs == "D" ; nvalu := 13
         CASE chs == "E" ; nvalu := 14
         CASE chs == "F" ; nvalu := 15
         ENDCASE
         IF lpos
            * MSB
            nvalue := nvalu * 16
            lpos := .F.  && Toggle MSB/LSB
         ELSE
            * LSB
            nvalue := nvalue + nvalu
            lpos := .T.
            cbin := cbin + CHR(nvalue)
            * nvalue := 0
         ENDIF
      ENDIF  && IF 0..9,A..F
   NEXT
   * if odd, return error
   IF ( nodd % 2 ) != 0
      RETURN ""
   ENDIF
   IF ldebug
      hwg_xvalLog(cbin)
   ENDIF

   RETURN cbin

FUNCTION hwg_HEX_DUMP( cinfield, npmode, cpVarName )

* Hex dump from a C field (binary)
* into C field (Character type).
* In general,
* every byte value (2 hex digits)
* separated by a blank.
*
* npmode:
* Selects the output format.
* 0 : All hex values in one line,
*     without quotes and trailing EOL.
* 1 : 16 bytes per line,
*     with display of printable
*     characters,
*     not inserted in quotes,
*     but columns with printable
*     characters are separated with
*     ">> " in every line.
* 2 : As variable definition
*     for copy and paste into prg source
*     code file, 16 bytes per line,
*     concatenated by "+ ;"
*     (Default)
* 3 : 16 bytes per line, only hex output,
*     no quotes or other characters.
* 4 : Like 0, but without blank
*     between the hex values.
*     Used by Binary Large Objects (BLOBs)
*     stored in memo fields of a DBF.
*     See program utils\bincnt\bindbf.prg
* 5:  As C notation array,
*     16 bytes per line, 0x..
*     written in {}
*     Add before generated block (for example):
*     const unsigned char sample[] =
*
* cpVarName:
* Only used, if npmode = 2.
* Preset for variable name,
* Default is "cVar".
* For other modes, this parameter
* is ignored.
*
* Sample writing hex dump to text file
* MEMOWRIT("hexdump.txt",HEX_DUMP(varbuf))
* ================================= *

   LOCAL nlength, coutfield,  nindexcnt , cccchar, nccchar, ccchex, nlinepos, cccprint, ;
      cccprline, ccchexline, nmode , cVarName , ncomma

   IF npmode == NIL
      nmode := 2
   ELSE
      nmode := npmode
   ENDIF
   IF cpVarName == NIL
      cVarName := "cVar"
   ELSE
      cVarName := cpVarName
   ENDIF
   * Check for valid mode
   IF (nmode < 1 ) .OR. (nmode > 6 )
      RETURN ""
   ENDIF
   * get length of field to be dumped
   nlength := LEN(cinfield)
   * if empty, nothing to dump
   IF nlength == 0
      RETURN ""
   ENDIF
   nlinepos := 0
   IF nmode == 2
      coutfield := cVarName + " := " + CHR(34)  && collects out line, start with variable name
   ELSE
      IF nmode == 5
         coutfield := "{"
      ELSE
         coutfield := ""  && collects out line
      ENDIF
   ENDIF
   // cccprint := ""   && collects printable char
   cccprline := ""  && collects printable chars
   ccchexline := "" && collects hex chars
   * loop over every byte in field
   FOR nindexcnt := 1 TO nlength
      nlinepos := nlinepos + 1
      * extract single character to convert
      cccchar := SUBSTR(cinfield,nindexcnt,1)
      * convert single character to number
      nccchar := ASC(cccchar)
      * is printable character below 0x80 (pure ASCII)
      IF (nccchar > 31) .AND. (nccchar < 128)
         IF nccchar == 32
            * space represented by underline
            cccprint := "_"
         ELSE
            cccprint := cccchar
         ENDIF
      ELSE
         * other characters represented by "."
         cccprint := "."
      ENDIF
      * convert single character to hex
      ccchex  := hwg_NUMB2HEX(nccchar)
      * collect hex and printable chars in outline
      IF nmode == 4
         cccprline := cccprline + cccprint
         ccchexline := ccchexline + ccchex
      ELSE
         IF nmode == 5
            cccprline := cccprline + cccprint + " "
            ccchexline := ccchexline + "0x" + ccchex + ","
         ELSE
            * Add a blank between a hex value pair
            cccprline := cccprline + cccprint + " "
            ccchexline := ccchexline + ccchex + " "
         ENDIF
      ENDIF
      * end of line with 16 bytes reached
      IF nlinepos > 15
         * create new line
         *
         DO CASE
         CASE nmode == 0
            coutfield := coutfield + ccchexline
         CASE nmode == 1
            coutfield := coutfield + ccchexline + ">> " +  cccprline + hwg_EOLStyle()
         CASE nmode == 2
            coutfield := coutfield + ccchexline + CHR(34) + " + ;" + hwg_EOLStyle()
         CASE nmode == 3
            coutfield := coutfield + ccchexline + hwg_EOLStyle()
         CASE nmode == 4
            coutfield := coutfield + ccchexline
         CASE nmode == 5
            coutfield := coutfield + ccchexline + hwg_EOLStyle()
         ENDCASE

         * ready for new line
         nlinepos := 0
         cccprline := ""
         IF nmode == 2
            ccchexline := CHR(34) && start new line with double quote
         ELSE
            ccchexline := ""
         ENDIF
      ENDIF
   NEXT
   * complete as last line, if rest of recent line existing
   * HEX line 16 * 3 = 48
   * line with printable chars: 16 * 2 = 32
   IF  .NOT. EMPTY(ccchexline)  && nlinepos < 16
      DO CASE
      CASE nmode == 0
         coutfield := coutfield + ccchexline
      CASE nmode == 1
         coutfield := coutfield + PADR(ccchexline,48) + ">> " +  PADR(cccprline,32) + hwg_EOLStyle()
      CASE nmode == 2
         coutfield := coutfield + ccchexline + CHR(34) +  hwg_EOLStyle()
      CASE nmode == 3
         coutfield := coutfield + ccchexline + hwg_EOLStyle()
      CASE nmode == 4
         coutfield := coutfield + ccchexline
      CASE nmode == 5
         * Remove "," at end of last line
         ncomma := RAT(",",ccchexline)
         ccchexline := IIF(ncomma > 0 , SUBSTR(ccchexline, 1, ncomma - 1) , ccchexline )
         coutfield := coutfield + ccchexline + "}" + hwg_EOLStyle()
      ENDCASE
   ENDIF

   RETURN coutfield

FUNCTION hwg_NUMB2HEX (nascchar)

   * Converts
   * 0 ... 255 TO HEX 00 ... FF
   * (2 Bytes String)

   LOCAL chexchars := ;
      {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
   LOCAL n1, n2

   * Range 0 ... 255
   IF nascchar > 255
      RETURN "  "
   ENDIF
   IF nascchar < 0
      RETURN "  "
   ENDIF
   * split bytes
   * MSB: n1, LSB: n2
   n1 := nascchar / 16
   n2 := nascchar % 16
   * combine return value

   RETURN chexchars[ n1 + 1 ] + chexchars[ n2 + 1 ]

FUNCTION hwg_EOLStyle()

   * Returns the "End Of Line" (EOL) character(s)
   * OS dependent.
   * Windows: OD0A (CRLF)
   * LINUX:   0A (LF)
   * This function works also on
   * GTK cross development environment.
   * MacOS not supported yet.
   * Must then return 0D (CR).
   * ================================= *

#ifdef __PLATFORM__WINDOWS
   RETURN CHR(13) + CHR(10)
#else
   RETURN CHR(10)
#endif

FUNCTION hwg_BaseName ( pFullpath )

   LOCAL nPosifilna , cFilename , cseparator

   * avoid crash
   IF PCOUNT() == 0
      RETURN ""
   ENDIF
   IF EMPTY(pFullpath)
      RETURN ""
   ENDIF

   cseparator := hwg_GetDirSep()
   * Search separator backwards
   nPosifilna = RAT(cseparator,pFullpath)

   IF nPosifilna == 0
      * Only filename
      cFilename := pFullpath
   ELSE
      cFilename := SUBSTR(pFullpath , nPosifilna + 1)
   ENDIF

   RETURN ALLTRIM(cFilename)

FUNCTION hwg_Dirname ( pFullpath )

   LOCAL nPosidirna , sFilePath , cseparator , sFullpath

   * avoid crash
   IF PCOUNT() == 0
      RETURN ""
   ENDIF
   IF EMPTY(pFullpath)
      RETURN ""
   ENDIF

   cseparator := hwg_GetDirSep()
   *  Reduce \\ to \  or // to /
   sFullpath := ALLTRIM(hwg_CleanPathname(pFullpath))

   * Search separator backwards
   nPosidirna := RAT(cseparator,sFullpath)

   IF nPosidirna == 1
      * Special case:  /name  or  \name
      *   is "root" ==> directory separator
      sFilePath := cseparator
   ELSE
      IF nPosidirna != 0
         sFilePath := SUBSTR(sFullpath,1,nPosidirna - 1)
      ELSE
         * Special case:
         * recent directory (only filename)
         * or only drive letter
         * for example C:name
         * ==> set directory with "cd".
         IF SUBSTR(sFullpath,2,1) == ":"
            * Only drive letter with ":" (for example C: )
            sFilePath := SUBSTR(sFullpath,1,2)
         ELSE
            sFilePath = "."
         ENDIF
      ENDIF
   ENDIF

   RETURN sFilePath

FUNCTION hwg_CleanPathname ( pSwithdbl )

   LOCAL sSwithdbl , bready , cseparator

   * avoid crash
   IF PCOUNT() == 0
      RETURN ""
   ENDIF
   IF EMPTY(pSwithdbl)
      RETURN ""
   ENDIF
   cseparator = hwg_GetDirSep()
   bready := .F.
   sSwithdbl = ALLTRIM(pSwithdbl)
   DO WHILE .NOT. bready
      * Loop until
      * multi separators (for example "///") are reduced to "/"
      sSwithdbl := STRTRAN(sSwithdbl , cseparator + cseparator , cseparator)
      * Done, if // does not apear any more
      IF AT(cseparator + cseparator, sSwithdbl) == 0
         bready := .T.
      ENDIF
   ENDDO

   RETURN sSwithdbl

FUNCTION hwg_Array_Len(ato_check)

   IF ato_check == NIL
      RETURN 0
   ENDIF

   RETURN IIF(EMPTY(ato_check), 0 , LEN(ato_check)  )

FUNCTION hwg_MemoCmp(mmemo1,mmemo2)

   LOCAL nnum , nlen1 , nlen2 , lende

   nnum := 1
   lende := .T.
   nlen1 := LEN(mmemo1)
   nlen2 := LEN(mmemo2)
   IF nlen1 != nlen2
      RETURN .F.
   ENDIF
   DO WHILE ( nnum <= nlen1 ) .AND. lende
      IF SUBSTR(mmemo1,nnum,1) != SUBSTR(mmemo2,nnum,1)
         lende := .F.
      ENDIF
      nnum := nnum + 1
   ENDDO

   RETURN lende

FUNCTION hwg_MemoEdit(mpmemo , cTextTitME , cTextSave ,  cTextClose , ;
   cTTSave , cTTClose , oHCfont )

   LOCAL mvarbuff , varbuf , oModDlg , oEdit , owb1 , owb2 , bMemoMod

   IF cTextTitME == NIL
      cTextTitME := "Memo Edit"
   ENDIF

   IF cTextSave == NIL
      cTextSave := "Save"
   ENDIF

   IF cTextClose == NIL
      cTextClose := "Close"
   ENDIF

   IF cTTSave == NIL
      cTTSave := "Save modifications and close"
   ENDIF

   IF cTTClose == NIL
      cTTClose := "Close without saving modifications"
   ENDIF

   mvarbuff := mpmemo
   varbuf   := mpmemo

   INIT DIALOG oModDlg title cTextTitME AT 0, 0 SIZE 400, 300 ON INIT { |o|o:center() }

   IF oHCfont == NIL
      @ 10, 10 HCEDIT oEdit SIZE oModDlg:nWidth - 20, 240
   ELSE
      @ 10, 10 HCEDIT oEdit SIZE oModDlg:nWidth - 20, 240 ;
         FONT  oHCfont
   ENDIF

   @ 10, 252  ownerbutton owb2 TEXT cTextSave size 80, 24 ;
      ON Click { || mvarbuff := oEdit , omoddlg:Close(), oModDlg:lResult := .T. } ;
      TOOLTIP cTTSave
   @ 100, 252 ownerbutton owb1 TEXT cTextClose size 80, 24 ON CLICK { ||oModDlg:close() } ;
      TOOLTIP cTTClose

   oEdit:SetText(mvarbuff)

   ACTIVATE DIALOG oModDlg

   * is modified ? (.T.)
   bMemoMod := oEdit:lUpdated
   IF bMemoMod
   * write out edited memo field
     varbuf := oEdit:GetText()
   ENDIF

   RETURN varbuf

* === Unit conversions ===

* ===== Temperature conversions ==============

FUNCTION hwg_TEMP_C2F( T )

   RETURN (T * 1.8) + 32.0

FUNCTION hwg_TEMP_C2K( T )

   RETURN T + 273.15

FUNCTION hwg_TEMP_C2RA( T )

   RETURN (T * 1.8) + 32.0 + 459.67

FUNCTION hwg_TEMP_C2R( T )

   RETURN T * 0.8

FUNCTION hwg_TEMP_K2C( T )

   RETURN T - 273.15

FUNCTION hwg_TEMP_K2F( T )

   RETURN (T * 1.8) - 459.67

FUNCTION hwg_TEMP_K2RA( T )

   RETURN T * 1.8

FUNCTION hwg_TEMP_K2R( T )

   RETURN ( T - 273.15 ) * 0.8

FUNCTION hwg_TEMP_F2C( T )

   RETURN ( T - 32.0) / 1.8

FUNCTION hwg_TEMP_F2K( T )

   RETURN ( T + 459.67) / 1.8

FUNCTION hwg_TEMP_F2RA( T )

   RETURN T + 459.67

FUNCTION hwg_TEMP_F2R( T )

   RETURN ( T - 32.0 ) / 2.25

FUNCTION hwg_TEMP_RA2C( T )

   RETURN ( T - 32.0 - 459.67) / 1.8

FUNCTION hwg_TEMP_RA2F( T )

   RETURN  T - 459.67

FUNCTION hwg_TEMP_RA2K( T )

   RETURN T / 1.8

FUNCTION hwg_TEMP_RA2R( T )

   RETURN ( T - 32.0 -459.67 ) / 2.25

FUNCTION hwg_TEMP_R2C( T )

   RETURN T * 1.25

FUNCTION hwg_TEMP_R2F( T )

   RETURN ( T * 2.25 ) + 32.0

FUNCTION hwg_TEMP_R2K( T )

   RETURN ( T * 1.25 ) + 273.15

FUNCTION hwg_TEMP_R2RA( T )

   RETURN ( T * 2.25 ) + 32.0 + 459.67

* ===== End of temperature conversions ==============

* ===== Other unit conversions =====================

* in / cm

FUNCTION hwg_INCH2CM( I )

   RETURN I * 2.54

FUNCTION hwg_CM2INCH( cm )

   RETURN cm * 0.3937

* feet / m

FUNCTION  hwg_FT2METER( ft )

   RETURN ft * 0.3048

FUNCTION hwg_METER2FT( m )

   RETURN m * 3.2808

* mile / km

FUNCTION hwg_MILES2KM( mi )

   RETURN mi * 1.6093

FUNCTION hwg_KM2MILES( km )

   RETURN  km * 0.6214

* sqin / sq cm

FUNCTION hwg_SQIN2SQCM( sqin )

   RETURN sqin * 6.4516

FUNCTION hwg_SQCM2SQIN( sqcm )

   RETURN sqcm * 0.155

* sqft / sq m

FUNCTION hwg_SQFT2SQM( sqft )

   RETURN sqft * 0.0929

FUNCTION hwg_SQM2SQFT( sqm )

   RETURN sqm * 10.7642

* usoz / c.c. (Cubic cm)

FUNCTION hwg_USOZ2CC( usoz )

   RETURN usoz * 29.574

FUNCTION hwg_CC2USOZ( cc )

   RETURN cc * 0.0338

* usgal / liter

FUNCTION hwg_USGAL2L( usgal )

   RETURN usgal * 3.7854

FUNCTION hwg_L2USGAL( l )

   RETURN l * 0.2642

* lb / kg

FUNCTION  hwg_LB2KG( lb )

   RETURN lb * 0.4536

FUNCTION hwg_KG2LB( kg )

   RETURN kg * 2.2046

* oz / g

FUNCTION hwg_OZ2GR( oz )

   RETURN oz * 28.35

FUNCTION hwg_GR2OZ( gr )

   RETURN gr * 0.0353

* Nautical mile / km

FUNCTION hwg_NML2KM(nml)

   RETURN nml * 1.852

FUNCTION hwg_KM2NML(km)

   RETURN km * 0.5399568034557235

* ===== End of unit conversions ==============

FUNCTION hwg_KEYESCCLDLG (odlg)

    odlg:Close()

   RETURN NIL

FUNCTION hwg_ShowHelp(cHelptxt,cTitle,cClose,opFont,blmodus)

   * Shows a help window
   * ================================= *

   LOCAL oDlg , oheget

   * T: not modal (default is .F.)
   IF blmodus == NIL
      blmodus := .F.
   ENDIF

   IF cTitle == NIL
      cTitle := "No title for help window"
   ENDIF

   IF cHelptxt == NIL
      cHelptxt := "No help available"
   ENDIF

   IF cClose == NIL
      cClose := "Close"
   ENDIF

   IF opFont == NIL
#ifdef __PLATFORM__WINDOWS
      PREPARE FONT opFont NAME "Courier" WIDTH 0 HEIGHT -16
#else
      PREPARE FONT opFont NAME "Sans" WIDTH 0 HEIGHT 12
#endif
   ENDIF

   INIT DIALOG oDlg TITLE cTitle ;
        AT 204,25 SIZE 777, 440 FONT opFont

   SET KEY 0,VK_ESCAPE TO hwg_KEYESCCLDLG(oDlg)
   @ 1,3 GET oheget VAR cHelptxt SIZE 772,384 NOBORDER ;
      STYLE WS_VSCROLL + ES_AUTOHSCROLL + ES_MULTILINE + ES_READONLY + WS_BORDER + ES_NOHIDESEL

   @ 322,402 BUTTON cClose SIZE 100,32 ;
      ON CLICK {||oDlg:Close() }

   IF blmodus
      ACTIVATE DIALOG oDlg NOMODAL
   ELSE
      ACTIVATE DIALOG oDlg
   ENDIF

   SET KEY 0,VK_ESCAPE TO

   RETURN NIL

FUNCTION hwg_PI()

   * high accuracy

   RETURN 3.141592653589793285

FUNCTION hwg_StrDebNIL(xParchk)

   LOCAL cres

   IF xParchk == NIL
      cres := "NIL"
   ELSE
      cres := "not NIL"
   ENDIF

   RETURN cres

FUNCTION hwg_StrDebLog(ltoCheck)

   LOCAL cres

   IF ltoCheck
      cres := ".T."
   ELSE
      cres := ".F."
   ENDIF

   RETURN cres

FUNCTION hwg_IsNIL(xpara)

   IF xpara == NIL
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_MsgIsNIL(xpara,ctitle)

   * Sample call:
   * hwg_MsgIsNIL(hwg_Getactivewindow() )
   * Only for debugging
   * =======================================================

   LOCAL lrvalue

   lrvalue := hwg_Isnil( xpara )

   IF ctitle == NIL
      IF lrvalue
         hwg_MsgInfo("NIL")
      ELSE
         hwg_MsgInfo("NOT NIL")
      ENDIF
   ELSE
      IF lrvalue
         hwg_MsgInfo("NIL",ctitle)
      ELSE
         hwg_MsgInfo("NOT NIL",ctitle)
      ENDIF
   ENDIF

   RETURN lrvalue

FUNCTION hwg_DefaultFont()

   * Returns an object with a suitable default font
   * for Windows and LINUX
   * =======================================================

   LOCAL oFont

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12
#endif

   RETURN oFont

FUNCTION hwg_deb_is_object(oObj)

   LOCAL lret

   IF Valtype(oObj) == "O" && Debug
      hwg_MsgInfo("Is object")
      lret := .T.
   ELSE
      hwg_MsgInfo("Is not an object")
      lret := .F.
   ENDIF

   RETURN lret

FUNCTION hwg_leading0(ce)

   * ce : string
   * Returns : String
   * Replace all leading blanks with
   * "0".
   * =================================

   LOCAL vni , e1 , crvalue, lstop

   lstop := .F.

   e1 := ce
   IF LEN(e1) == 0
      RETURN ""
   ENDIF
   FOR vni := 1 TO LEN(ce)
      IF .NOT. lstop
         IF SUBSTR(e1,vni,1) == " "
            e1 := STUFF(e1,vni,1,"0")  && modify character at position vni to "0"
         ELSE
            lstop := .T.               && Stop search, if no blank appeared
         ENDIF
      ENDIF
   NEXT
   crvalue := e1

   RETURN crvalue

FUNCTION hwg_Bin2D(chex,nlen,ndec)

   // hwg_msginfo(chex)

   RETURN hwg_Bin2DC(SUBSTR(STRTRAN(SUBSTR(chex,1,23) ," ","") ,1,16) ,nlen,ndec)

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Date and time functions
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FUNCTION hwg_checkANSIDate(cANSIDate)

   * Check, if an ANSI Date is valid.
   * cANSIDate: ANSI date as string
   * of Format YYYYMMDD
   *
   * =================================

   LOCAL ddate, cdate

   IF cANSIDate == NIL
      RETURN .F.
   ENDIF
   cANSIDate := ALLTRIM(cANSIDate)
   IF EMPTY(cANSIDate)
      RETURN .F.
   ENDIF
   IF LEN(cANSIDate) <> 8
      RETURN .F.
   ENDIF
   ddate := hwg_STOD(cANSIDate)
   cdate := DTOC(ddate)
   * Invalid date is "  .  .  " , so ...
   cdate := STRTRAN(cdate," ","")
   cdate := STRTRAN(cdate,".","")
   IF EMPTY(cdate)
      RETURN .F.
   ENDIF

   RETURN .T.

FUNCTION hwg_Date2JulianDay(dDate,nhour,nminutes,nseconds)

   LOCAL nyear, nmonth, nday , ngreg

   IF nhour == NIL
      nhour     := 0
   ENDIF
   IF nminutes == NIL
      nminutes  := 0
   ENDIF
   IF nseconds == NIL
      nseconds  := 0
   ENDIF

   nyear  := YEAR(dDate)
   nmonth := MONTH(dDate)
   nday   := DAY(dDate)

   IF nmonth <= 2
      nmonth := nmonth + 12
      nyear :=  nyear - 1
   ENDIF

   ngreg :=  ( nyear / 400 ) - ( nyear / 100 ) + ( nyear / 4 )  && Gregorian calendar

   RETURN 2400000.5 + 365 * nyear - 679004 + ngreg ;
           + INT(30.6001 * ( nmonth + 1 )) + nday + ( nhour / 24 ) ;
           + ( nminutes / 1440 ) + ( nseconds / 86400 )


FUNCTION hwg_JulianDay2Date(z)

   * Converts julian date of mem files into
   * String , Format YYYYMMDD (ANSI)
   * z: double (of type N)
   * Returns string
   * Valid for dates from 1901 to 2099
   * The julian is stored in Clipper
   * and Harbour MEM files as
   * double value.
   * =================================

   LOCAL njoff , nRound_4 , nFour , nYear , d , d1 , i , jz  , sz ,  k ,  cYear ,  cMonth , cday

   njoff := 4712                  && const year offset
   nFour := ( z + 13 ) / 1461     && 1461 = 3*365+366  period of 4 years  (valid 1901 ... 2099)
   nRound_4 := INT(nFour)
   nYear := nRound_4 * 4
   nRound_4 := (nRound_4 * 1461) - 13
   d  := z - nRound_4
   i  := 1
   d1 := 0
   DO WHILE (d1 >= 0) .AND. (i < 5)
      IF i == 1
         jz := 366
      ELSE
         jz := 365
      ENDIF
      d1 := d - jz
      IF d1 >= 0
         d := d1
         nYear := nYear + 1
      ENDIF
      i := i + 1
   ENDDO
   nYear := nYear - njoff
   cYear := STR( nYear , 4 , 0 )

   cYear := hwg_leading0(cYear)
   * Check for valid year range
   IF (nYear < 1901 ) .OR. (nYear > 2099)
      RETURN ""
   ENDIF

   d := d + 1;     && 0 .. 364 => 1 .. 365

   IF ( nYear % 4 ) == 0   && Leap year 1901 ... 2099
      sz := -1
   ELSE
      sz := 0
   ENDIF
   IF (sz = -1) .AND. (d = 60)
      * 29th February
      cMonth := "02"
      cday := "29"
    ELSE
      * All other days
      IF (d > 60) .AND. (sz == -1)
           d := d - 1
      ENDIF  && Correction Leap Year
      cMonth := "  "
      IF  d > 0
         cMonth := "01"
         k := 0
      ENDIF
      IF  d > 31
         cMonth := "02"
         k := 31
      ENDIF
      IF  d > 59
         cMonth := "03"
         k := 59
      ENDIF
      IF  d > 90
         cMonth := "04"
         k := 90
      ENDIF
      IF  d > 120
         cMonth := "05"
         k := 120
      ENDIF
      IF  d > 151
         cMonth := "06"
         k := 151
      ENDIF
      IF  d > 181
         cMonth := "07"
         k := 181
      ENDIF
      IF  d > 212
         cMonth := "08"
         k := 212
      ENDIF
      IF  d > 243
         cMonth := "09"
         k := 243
      ENDIF
      IF  d > 273
         cMonth := "10"
         k := 273
      ENDIF
      IF  d > 304
         cMonth := "11"
         k := 304
      ENDIF
      IF  d > 334
         cMonth := "12"
         k := 334
      ENDIF
      d := d - k
      cday := STR( d , 2 ,0 )
   ENDIF
   cday := hwg_leading0(cday)

   * Check for Errors
   * Could be for example "20991232".
   IF .NOT. hwg_checkANSIDate(cYear + cMonth + cday)
      RETURN ""
   ENDIF

   RETURN cYear + cMonth + cday


FUNCTION HWG_GET_TIME_SHIFT()

   LOCAL nhUTC , nhLocal

   nhUTC := VAL(SUBSTR(HWG_GETUTCTIMEDATE(),12,2  ))
   * Format: W,YYYYMMDD-HH:MM:SS
   nhLocal := VAL(SUBSTR(TIME(),1,2))

   RETURN nhLocal - nhUTC

FUNCTION hwg_addextens(cfilename,cext,lcs)

   LOCAL nposi , fna , ce

   IF cfilename == NIL
      cfilename := ""
   ENDIF
   IF cext == NIL
      RETURN cfilename
   ENDIF
   IF EMPTY(cext)
      RETURN cfilename
   ENDIF
   IF lcs == NIL
      lcs := .F.
   ENDIF
   fna := cfilename
   IF lcs
      cfilename := UPPER(cfilename)
      ce := "." + UPPER(cext)
   ELSE
      ce := "." + cext
   ENDIF
   nposi := RAT(ce,cfilename)
   IF nposi == 0
      fna := fna + "." + cext
   ENDIF

   RETURN fna

FUNCTION hwg_EuroUTF8()

   * 0xE2 + 0x82 + 0xAC

   RETURN CHR(226) + CHR(130) + CHR(172)

FUNCTION hwg_ValType(xxxx)

   * Returns the type of a variable or expression:
   * "A", "L", "N", "C" , "D", "O" , "U"

   LOCAL crtype

   IF xxxx == NIL
      crtype := "U"
   ELSE
      crtype := VALTYPE(xxxx)
   ENDIF

   RETURN crtype

FUNCTION hwg_xVal2C(xxx)

   * Convert the value of xxx to string, dependant
   * of type.
   * Helpful for debugging.

   LOCAL ctyp , cval

   ctyp := hwg_ValType(xxx)

   DO CASE
   CASE ctyp == "U"
      cval := "NIL"
   CASE ctyp == "A"
      cval := "<ARRAY>"
   CASE ctyp == "L"
      cval := IIF(xxx, ".T.",".F.")
   CASE ctyp == "N"
      cval := ALLTRIM(STR(xxx))
   CASE ctyp == "C"
      cval := xxx
   CASE ctyp == "D"
      cval := DTOS(xxx)
   CASE ctyp == "O"
      cval := "<OBJECT>"
   OTHERWISE
      cval := "<UNKNOWN>"
   ENDCASE

   RETURN cval

FUNCTION hwg_xvalMsg(xxx,cttype,cttval,cttitle)

   * Starts a messagebox to display a value of xxx

   IF cttype == NIL
      cttype := "Type : "
   ENDIF
   IF cttval == NIL
      cttval := "Value : "
   ENDIF
   IF cttitle == NIL
      cttitle := "Debug"
   ENDIF
   hwg_MsgInfo(cttype + hwg_ValType(xxx) + CHR(10) +  cttval + hwg_xVal2C(xxx) )

   RETURN NIL

FUNCTION hwg_xvalLog(xxx,cttype,cttval,cttitle,cfilename)

   * Writes a value of xxx into a log file
   IF cttype == NIL
      cttype := "Type : "
   ENDIF
   IF cttval == NIL
      cttval := "Value : "
   ENDIF
   IF cttitle == NIL
      cttitle := "Debug"
   ENDIF
   IF cfilename == NIL
      cfilename := "a.log"
   ENDIF
   hwg_WriteLog(cttype + hwg_ValType(xxx) + " " +  cttval + hwg_xVal2C(xxx), cfilename )

   RETURN NIL

FUNCTION hwg_ChangeCharInString(cinp,nposi,cval)

   LOCAL cout, i

   IF cinp == NIL
      RETURN ""
   ENDIF
   IF cval == NIL
      RETURN cinp
   ENDIF
   IF LEN(cval) <> 1
      RETURN cinp
   ENDIF
   IF nposi == NIL
      RETURN cinp
   ENDIF
   IF nposi > LEN(cinp)
      RETURN cinp
   ENDIF
   cout := ""
   FOR i := 1 TO LEN(cinp)
      IF i == nposi
         cout := cout + cval
      ELSE
         cout := cout + SUBSTR(cinp,i,1)
      ENDIF
   NEXT

   RETURN cout

FUNCTION hwg_hex2binchar(cchar)

   LOCAL cret , ipos , csingle, lpair, lignore

   cret := ""
   lpair := .F.
   cchar := UPPER(cchar)
   FOR ipos := 1 to LEN(cchar)
      lignore := .F.
      csingle := SUBSTR(cchar,ipos,1)
      DO CASE
      CASE csingle == "0"; cret := cret + "0000 "
      CASE csingle == "1"; cret := cret + "0001 "
      CASE csingle == "2"; cret := cret + "0010 "
      CASE csingle == "3"; cret := cret + "0011 "
      CASE csingle == "4"; cret := cret + "0100 "
      CASE csingle == "5"; cret := cret + "0101 "
      CASE csingle == "6"; cret := cret + "0110 "
      CASE csingle == "7"; cret := cret + "0111 "
      CASE csingle == "8"; cret := cret + "1000 "
      CASE csingle == "9"; cret := cret + "1001 "
      CASE csingle == "A"; cret := cret + "1010 "
      CASE csingle == "B"; cret := cret + "1011 "
      CASE csingle == "C"; cret := cret + "1100 "
      CASE csingle == "D"; cret := cret + "1101 "
      CASE csingle == "E"; cret := cret + "1110 "
      CASE csingle == "F"; cret := cret + "1111 "
      OTHERWISE
         lignore := .T.
      ENDCASE
      * Ignore invalid character
      IF .NOT. lignore
         IF lpair
            cret := cret + " "
         ENDIF
         * toggle for hex pair to add a space
         lpair := .NOT. lpair
      ENDIF
   NEXT

   RETURN cret

FUNCTION hwg_Toggle_HalfByte( cchar )

   LOCAL ci

   ci := ASC(SUBSTR(cchar,1,1))

   RETURN SUBSTR(CHR(hwg_Toggle_HalfByte_C(ci) ),1,1)

FUNCTION hwg_COUNT_CHAR(stri,such)

   * Counts the appearance of string "such"
   * in "stri".
   * This function has a subset
   * of parameters of the function
   * AFTERATNUM() for better handling.

   LOCAL l,i,c,t

   l := LEN (stri)
   IF l == 0
      RETURN 0
   ENDIF
   IF LEN(such) == 0
      RETURN 0
   ENDIF
   c := 0
   t := stri
   DO WHILE .T.
      i := AT(such,t)
      IF i != 0
         c := c + 1
         t := SUBSTR(t,i+LEN(such))
      ELSE
         RETURN c
      ENDIF
   ENDDO

   RETURN 0


FUNCTION hwg_nothing(xpara)

   RETURN xpara

FUNCTION hwg_ProcFileExt(pFiname,pFiext,lupper)

   * Process file name extension:
   * Add file extension, if not available
   * or replace an existing extension.
   * pFiname : The filename to be processed
   * pFiext  : The new file extension
   * lupper  : Windows only (parameter ignored on UNIX/LINUX):
   *           Set to .T. , if extension is set to upper case
   *           .F. : preserve case (default)
   *
   * Sample call: hwg_ProcFileExt("TEST.TXT","PRG")
   * returns the value "TEST.PRG"
   * pFiname may contain a full path.
   * DOS, Windows and UNIX/LINUX filenames
   * are supported.

   LOCAL sfifullnam , sFiname , sFiext , nSlash , nPunkt

#ifndef __PLATFORM__WINDOWS
   HB_SYMBOL_UNUSED(lupper)
#endif

   IF lupper == NIL
      lupper := .F.
   ENDIF
   * Trim strings
   sFiext := ALLTRIM(pFiext)

   sFiname := ALLTRIM(hwg_CleanPathname( pFiname ))

#ifdef __PLATFORM__WINDOWS
   IF lupper
      sFiext := UPPER(sFiext)
   ENDIF
#endif
   * UNIX/LINUX : preserve case as passed
   * Attention !
   * Also path names may contain dots!
   nSlash := RAT(hwg_GetDirSep(),sFiname)
   nPunkt := RAT(".", sFiname )
   IF nPunkt == 0
      * Without extension: add extension
      sfifullnam := sFiname + "." + sFiext
   ELSE
      IF nSlash > nPunkt
         * Special case:
         * Without extension, but dot in path name
         sfifullnam := sFiname + "." + sFiext
      ELSE
         IF nPunkt == 1
            * Special : hidden file in UNIX, for example .profile
            * so add extension
            sfifullnam := sFiname + "." + sFiext
         ELSE
            * The rest:
            * Cut existing extension
            sFiname := SUBSTR(sFiname,1,nPunkt - 1)
            * Add new extension
            sfifullnam := sFiname + "." + sFiext
         ENDIF
      ENDIF
   ENDIF

   RETURN sfifullnam

#pragma BEGINDUMP

#include "hbapi.h"

HB_FUNC( HWG_HAS_WIN_EURO_SUPPORT )
{
#ifdef __XHARBOUR__
   hb_retl( 0 );
#else
#if ( HB_VER_REVID - 0 ) >= 2002101634
   hb_retl( 1 );
#else
   hb_retl( 0 );
#endif
#endif
}

#pragma ENDDUMP

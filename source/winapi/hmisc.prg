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
 * Copyright 2020 Wilfried Brunken, DF7BE
*/
#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

* ================================= *
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
  
FUNCTION hwg_CurDrive
#ifdef __PLATFORM__WINDOWS
RETURN hb_CurDrive() + ":\"
#else
RETURN ""
#endif

FUNCTION hwg_CurDir
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

* ================================= * 
FUNCTION hwg_cHex2Bin (chexstr)
* Converts a hex string to binary
* Returns empty string, if error
* or number of hex characters is
* odd. 
* chexstr:
* Valid characters:
* 0 ... 9 , A ... F , a ... f
* Other characters are ignored.
* ================================= *
LOCAL cbin, ncount, chs, lpos, nvalu, nvalue , nodd
* lpos : F = MSB , T = LSB
cbin := ""
lpos := .T.
nvalue := 0
nodd := 0
IF (chexstr == NIL)
 RETURN ""
ENDIF 
chexstr := UPPER(chexstr)
FOR ncount := 1 TO LEN(chexstr)
 chs := SUBSTR(chexstr, ncount, 1 )
 IF chs $ "0123456789ABCDEF"
  nodd := nodd + 1  && Count valid chars for odd/even check
  DO CASE
   CASE chs == "0"
    nvalu := 0 
   CASE chs == "1"
    nvalu := 1   
   CASE chs == "2"
    nvalu := 2
   CASE chs == "3"
    nvalu := 3
   CASE chs == "4"
    nvalu := 4
   CASE chs == "5"
    nvalu := 5
   CASE chs == "6"
    nvalu := 6
   CASE chs == "7"
    nvalu := 7
   CASE chs == "8"
    nvalu := 8
   CASE chs == "9"
    nvalu := 9
   CASE chs == "A"
    nvalu := 10
   CASE chs == "B"
    nvalu := 11
   CASE chs == "C"
    nvalu := 12
   CASE chs == "D"
    nvalu := 13
   CASE chs == "E"
    nvalu := 14
   CASE chs == "F"
    nvalu := 15    
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
RETURN cbin


* ================================= * 
FUNCTION hwg_HEX_DUMP (cinfield, npmode, cpVarName)
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
   cccprline, ccchexline, nmode , cVarName
 IIF(npmode == NIL , nmode := 2 , nmode := npmode )
 IIF(cpVarName == NIL , cVarName := "cVar" , cVarName := cpVarName )
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
   coutfield := ""  && collects out line
  ENDIF 
  cccprint := ""   && collects printable char
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
    cccprline := cccprline + cccprint + " "
    ccchexline := ccchexline + ccchex + " "  
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
    ENDCASE

  ENDIF
RETURN coutfield 
 
* ================================= *
FUNCTION hwg_NUMB2HEX (nascchar)
* Converts 
* 0 ... 255 TO HEX 00 ... FF
* (2 Bytes String)
* ================================= *
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

* ================================= *
FUNCTION hwg_EOLStyle
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

* ================================= *
FUNCTION hwg_BaseName ( pFullpath )
* ================================= *
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
 
* ================================= *
FUNCTION hwg_Dirname ( pFullpath )
* ================================= *
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

* ================================= *
FUNCTION hwg_CleanPathname ( pSwithdbl )
* ================================= *
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

* ================================= * 
FUNCTION hwg_Array_Len(ato_check)
* ================================= *
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


* ~~~~~~~~~~~~~~~~~~~~~~~~
* === Unit conversions ===
* ~~~~~~~~~~~~~~~~~~~~~~~~

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



* ============== EOF of hmisc.prg =================


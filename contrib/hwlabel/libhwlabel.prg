*
* libhwlabel.prg
*
*   $Id$
*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
* Label library for HWGUI
* "HWLABEL"
*
* Copyright 2022 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License
* with special exceptions of HWGUI.
* See file "license.txt" for details of
* HWGUI project at
*  https://sourceforge.net/projects/hwgui/
*
* This is the port of a label feature of Clipper/Harbour to HWGUI.
* This is the function library need to add to your HWGUI
* application.
*
* Codepages stored in label:
* Recent setting of codepage is IBM DE858.
* (OK for most european countries with Euro currency sign)
*

    
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  Supported languages:
*  - English
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* =========================================================================================
* Function list
* ~~~~~~~~~~~~~
*
* FUNCTION hwlabel_translcp2        && Translates codepages for label file
* FUNCTION hwlabel_setO             && Copies the object var into static var (for better handling)
* FUNCTION hwlabel_getO             && Returns the HWinprn object from STATIC variable
* FUNCTION hwlabel_transfi          && Convert codepage from input to output file.
* FUNCTION hwlabel_filerln          && Read line from a text file.
* FUNCTION hwlabel_REM_CR           && Remove MacOS line ending (CR)
* FUNCTION hwlabel_Writeln          && Write one line into text file.
* FUNCTION hwlabel_WRI_TXTDOS       && Write the line with Windows/DOS line ending
* FUNCTION hwlabel_REM_FILEEXT      && Remove file extension, for Windows and LINUX both.
* FUNCTION hwlabel_MAX(a,b)         && Returns the max value of a or b
* FUNCTION hwlabel_OPENR            && Opens a text file for reading 
*
* ~~~~~~ Shortend functions for label contents ~~~~~~
* FUNCTION NOSKIP           && For empty lines in labels
* FUNCTION   S(n)           && (C)  SPACE(n)
* FUNCTION   P(s,n)         && (C)  PADR(s,n)
* FUNCTION   C(n)           && (C)  CHR(n)
* FUNCTION   R(s,n)         && (C)  REPLICATE(s,n)
* FUNCTION   T(s,p)         && (C)  TRANSFORM(s,p)
* FUNCTION   A(s)           && (C)  ALLTRIM(s)
*
* ============================================================================================

#include "hwgui.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif
#include "hbclass.ch"
#include "hwgextern.ch"

STATIC oWinPrn

* ==============================================
FUNCTION hwlabel_setO(o)
* Copies the object var into static var
* (for better handling)
* ==============================================
oWinPrn := o
RETURN NIL

* ==============================================
FUNCTION hwlabel_getO()
* Returns the HWinprn object from STATIC variable
* ==============================================
RETURN oWinPrn

* ==============================================
FUNCTION hwlabel_OPENR(ctxtfilename,cErrorMsg,cErrorTitle )
* Opens a text file for reading 
* Returns it's handle.
* If open error, an error Message
* is displayed.
* ctxtfilename : Filename for file to open
* cErrorMsg    : Error message, default in englisch 
* cErrorTitle  : Title, default in englisch
* ==============================================
LOCAL handle

IF ctxtfilename == NIL
  ctxtfilename := ""
ENDIF  
IF cErrorMsg == NIL
  cErrorMsg := "Open error " + ctxtfilename
ENDIF
IF cErrorTitle == NIL
  cErrorTitle := "HWLABEL Error"
ENDIF
  
 handle := FOPEN(ctxtfilename,0)
 IF handle < 0
   * ... handle open error
   hwg_MsgStop(cErrorMsg,cErrorTitle)
  ENDIF
 RETURN handle

* ==============================================
FUNCTION hwlabel_transfi(cfnam1,cfnam2,cCpLocWin,cCpLocLINUX,cCpLabel)
* Convert codepage from input to output file.
* cfnam1  : Input filename created by LABEL FORM ... command
* cfnam2  : Output filename with translated contents
* Returns .T., if success.
* ==============================================
* The empty sign CHR(255) is on Windows printable (&yuml;),
* so convert it to empty string here.
* (y with double points)
LOCAL lsucc , handle , handler , cbuffer , lEOF
lsucc := .T.

* Open for read
 handler := FOPEN(cfnam1,0)
 IF handler < 0
   * ... handle open error
   RETURN .F.
 ENDIF
 
* Open for overwrite
IF .NOT. FILE(cfnam2)
   handle = FCREATE(cfnam2,0)  && FC_NORMAL
 ELSE
   Erase &cfnam2
   handle = FCREATE(cfnam2,0)
 ENDIF
 IF handle != -1
  FSEEK (handle,0,2)
 ENDIF
 
 lEOF := .F.
 
DO WHILE .NOT. lEOF 
 
  cbuffer := hwlabel_filerln(handler)
  IF cbuffer == ""
    lEOF := .T.
  ELSE
  * Remove CR line ending
   cbuffer := hwlabel_REM_CR(cbuffer)
  * Translation
  * First suppress the NOSKIP character
  cbuffer := STRTRAN(cbuffer , CHR(255) , "")
  * Supress line with 0x1a = CHR(26) "SUB" at EOF
  IF SUBSTR(cbuffer,1,1) != CHR(26)
  * And now translate to local codepage
  cbuffer := hwlabel_translcp2(cbuffer,0,cCpLocWin,cCpLocLINUX,cCpLabel)
  * Write line to output 
  lsucc := hwlabel_Writeln(handle,cbuffer,cfnam2)
    IF .NOT. lsucc
    * Stop processiing in case of write error
       lEOF := .T.
    ENDIF && ! lsucc
   ENDIF && SUB
  ENDIF && cbuffer == ""
  
ENDDO 

* Close files
FCLOSE(handler) 
FCLOSE(handle) 

RETURN lsucc


* ================================= * 
FUNCTION hwlabel_filerln(handle)
* Read line from a text file.
* It is not important, if line ending
* is CRLF or LF or CR.
*
* returns:
* The line read
* Empty line      : " "
* EOF or error    : "" (empty string)
*
* CRLF : 0x0D + 0x0A =  CHR(13) + CHR(10) (Windows/DOS)  
* CR   = 0x0D = CHR(13) (only CR for MacOS) 
* LF   = 0x0A = CHR(10) (only LF for UNIX/LINUX)
* The returned line ended with MacOS line ending
* CR , so you need to handle this
* for example with
*  hwlabel_REM_CR()
* ================================= *
 LOCAL anzbytes , anzbytes2 , puffer , puffer2 , bEOL , cZeile , bMacOS 
 anzbytes := 1
 bEOL := .F.
 cZeile := ""
 bMacOS := .F.
 * Buffer may not be empty, otherwise FREAD() reads nothing !
 puffer := " "
 puffer2 := " "
 
    DO WHILE ( anzbytes != 0 ) .AND. ( .NOT. bEOL )
       anzbytes := FREAD(handle,@puffer,1)  && Read 1 Byte
       IF anzbytes != 1
        * Last line may be without line ending
         IF .NOT. EMPTY(cZeile)
         RETURN cZeile
        ELSE
         RETURN ""
        ENDIF
       ENDIF
       * Detect MacOS: First appearance of CR alone
       * Erkennen von MacOS: erstes Auftreten von CR alleine
       IF ( .NOT. bMacOS ) .AND. ( puffer == CHR(13) )
       * Bereits Zeilenende erreicht
         bEOL := .T.
         && get actual file pointer
         * position := FSEEK (adifhand , 0 , 1 )
         * Pre read (2nd read sequence)
          anzbytes2 := FREAD(handle,@puffer2,1)  && Read 1 byte / 
         IF anzbytes2 != 1
          * Optional last line with line ending
          IF .NOT. EMPTY(cZeile)
           RETURN cZeile
          ELSE
           RETURN ""
          ENDIF
         ENDIF
         * Line ending for Windows: must be LF (continue reading)
         IF .NOT. ( puffer2 == CHR(10) )
           * Windows : ignore read character
           bMacOS := .T.
           * puffer := puffer2
           * Set file pointer one byte backwards (is first character of following line)
           FSEEK (handle, -1 , 1 )
         ENDIF
       ELSE
         * UNIX / LINUX (only LF)
          IF puffer == CHR(10) 
           bEOL := .T.
           * Ignore EOL character
           puffer := ""
          ENDIF
       ENDIF 
        * Otherwise complete the line   
        cZeile := cZeile + puffer
       * Prefill buffer for next read
       puffer := " "
     ENDDO
    IF EMPTY(cZeile)
     RETURN " "
    ENDIF
RETURN cZeile

* ================================= * 
FUNCTION hwlabel_REM_CR(czeile)
* Remove MacOS line ending (CR)
* ================================= *
LOCAL nlaenge , czl
IF czeile == NIL
 czeile := ""
ENDIF
czl := czeile
nlaenge := LEN(czeile)
IF nlaenge > 0
 IF SUBSTR( czeile , nlaenge , 1) == CHR(13)
    czl := SUBSTR(czeile , 1 , nlaenge - 1 )
 ENDIF
ENDIF
RETURN czl

* ------------------------
FUNCTION hwlabel_Writeln(ha,s,dateiname)
* Write one line into text file.
* ha  : Handle of open file
* s   : Text buffer for 1 line
* dateiname : File name inserted in
*             error message 
* ------------------------
 LOCAL zs_s_rc
 
 IF dateiname == NIL
    dateiname := "<unknown>"
  ENDIF 
 
 
  zs_s_rc := hwlabel_WRI_TXTDOS(ha,s)   && Windows/DOS line ending fixed
   IF .NOT. zs_s_rc
     hwg_MsgStop( "FATAL: File access error " + dateiname )
     RETURN .F.
   ENDIF
RETURN .T.


* ================================= *
FUNCTION hwlabel_WRI_TXTDOS(dat_handle,dat_text)
* Write the line with Windows/DOS
* line ending
* ================================= *
 LOCAL Puffer,Laenge
 Puffer = dat_text + CHR(13) + CHR(10)
 Laenge = LEN(Puffer)
 IF FWRITE(dat_handle,Puffer, Laenge) == Laenge
  RETURN .T.
 ENDIF
RETURN .F.


* ==============================================
FUNCTION hwlabel_translcp2(cInput,nmode,cCpLocWin,cCpLocLINUX,cCpLabel)
* Translates codepages for label file
* 
* This is the same function as "hwlabel_translcp()"
* of "hwlbledt.prg", but was renamed to avoid symbol
* conflicts linking your programm containing code of
* this library and "hwlbledt.prg".
*
* Parameters:
* Default values in ()
*
* cInput      : The Input String to translate ("")
* nmode       : Direction of translation (0):
*               0 = Label to local (Windows,LINUX)
*               1 = Local (Windows,LINUX) to label
* cCpLocWin   : Name of local codepage for display and printing
*               on Windows OS ("DEWIN")
* cCpLocLINUX : Name of local codepage for display and printing
*               on LINUX OS ("UTF8EX")
* cCpLabel    : Name of codepage for label file
*               ("DE858")
* 
* The used operating system is automatically
* detected by compiler switch. 
* ==============================================
LOCAL cOutput, cloccp

cOutput := ""

IF nmode == NIL
  nmode := 0
ENDIF 

IF cInput == NIL
 cInput := ""
ENDIF 

IF cCpLocWin == NIL
   cCpLocWin := "DEWIN"
ENDIF   
IF cCpLocLINUX == NIL
   cCpLocLINUX := "UTF8EX"
ENDIF   
IF cCpLabel == NIL
   cCpLabel := "DE858"
ENDIF   

#ifdef __PLATFORM__WINDOWS
 cloccp := cCpLocWin
#else
 cloccp := cCpLocLINUX
#endif 

IF nmode == 0
  cOutput := hb_Translate( cInput, cCpLabel , cloccp   )
ELSE
  cOutput := hb_Translate( cInput, cloccp   , cCpLabel )
ENDIF 

RETURN cOutput

* =======================================================
FUNCTION hwlabel_REM_FILEEXT(dateiname)
* Remove file extension, for
* Windows and LINUX both.
* dateiname : filename with extension
* =======================================================
LOCAL cf , npos, nvz1 , nvz2 , nvz
cf := dateiname
* PATH : Search for / or \  beginning at end of String.
* (for Windows and LINUX)
* Path could contain "." !
nvz1 := RAT("/",cf)
nvz2 := RAT("\",cf)
nvz := hwlabel_MAX(nvz1,nvz2)
* Search for "." beginning at end of String.
npos := RAT(".", cf)
IF npos != 0
* If . not found, return original file name, has no extension
 IF .NOT. ( nvz > npos)
  * The . is not in directory name below
  * Strip extension
  cf := SUBSTR(cf,1,npos - 1)   
 ENDIF 
ENDIF
RETURN cf

* =======================================================
FUNCTION hwlabel_MAX(a,b)
* Returns the max value of a or b 
* ======================================================= 
IF a >= b
 RETURN a
ENDIF
RETURN b


* =======================================================
FUNCTION hwlabel_HexDump(cinfield,ldisp)
* Returns hex value for debugging,
* all values in one line
* and display it, if ldisp set to .T. (Default)
* =======================================================
LOCAL chexstr
IF ldisp == NIL
 ldisp := .T.
ENDIF 
chexstr := hwg_HEX_DUMP (cinfield, 0)
IF ldisp
 hwg_MsgInfo(chexstr,"Debug Hex String")
ENDIF
RETURN chexstr

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Functions for use in label file
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* ==========
* Set modes
* ==========



*   METHOD SetMode( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset )

FUNCTION SET_NCH(nChars)
* Set Charset
 oWinPrn:SetMode( , , , , , , , nChars )
RETURN "" 

// "Some character sizes: "
// SET_SMA() + "Small" + SET_DEF() + "Default" 
// SET_SML() + "Smaller" + SET_DEF() + "Default"
// SET_VSM() + "Very small" + SET_DEF() + "Default"

FUNCTION SET_DEF()
*  Default
* See hwinprn.prg, METHOD SetDefaultMode() CLASS HWinPrn, about line 252
oWinPrn:SetMode( .F., .F. , 6, .F. , .F. , .F. , 0 , 0 )
* oWinPrn:SetMode( .F.,.F. )
RETURN "" 

FUNCTION SET_SMA()
*   Small
oWinPrn:SetMode( .T. )
RETURN ""

FUNCTION SET_SML()
* Smaller
oWinPrn:SetMode( .F.,.T. )
RETURN ""

FUNCTION SET_VSM()
* Very small
oWinPrn:SetMode( .T.,.T. )
RETURN "" 


* ================================= *
FUNCTION NOSKIP(e)
* For  label printing:
* Returns CHR(255), not printable,
* if e (a string) is empty.
* * Otherwise the value of e is returned
* is passed.
*
* Reason:
* Lines defined in label file, but
* left empty are not printed.
* It seems, that this line is not
* existing. This causes an
* misfunction in the design,
* the following lines are moved to top.  
*
*  Gibt das Zeichen 255 (nicht abdruckbar)
*  zurueck, wenn e leer ist (String),
*  sonst wird der Inhalt von e so
*  wie uebergeben, zurueckgegeben.
*  Hintergrund: Zeilen die zwar
*  in der LBL-Datei definiert sind,
*  aber leer sind, werden nicht ausgegeben,
*  ( d.h. beim Drucken unterdrueckt )
*  so dass die nachfolgenden Zeilen nachruecken
*  und somit das Layout nicht mehr stimmt.
* ================================= *
RETURN IF( ! EMPTY(e) , e , CHR(255) )

* Short function call's

FUNCTION   S(n)        && (C)  SPACE(n)
RETURN SPACE(n)

FUNCTION   P(s,n)      && (C)  PADR(s,n)
RETURN PADR(s,n)

FUNCTION   C(n)        && (C)  CHR(n)
RETURN CHR(n)

FUNCTION   R(s,n)      && (C)  REPLICATE(s,n)
RETURN REPLICATE(s,n)

FUNCTION   T(s,p)      && (C)  TRANSFORM(s,p)
RETURN TRANSFORM(s,p)

FUNCTION   A(s)        && (C)  ALLTRIM(s)
RETURN ALLTRIM(s)

* ~~~~~~~~ End of label functions ~~~~~~~~~~

* ================================= *
FUNCTION hwlbl_IconHex()
* Hex value for icon "hwlabel.ico"
* Size 48x48
* ================================= *
RETURN ;
"00 00 01 00 01 00 30 30 00 00 01 00 08 00 A8 0E " + ;
"00 00 16 00 00 00 28 00 00 00 30 00 00 00 60 00 " + ;
"00 00 01 00 08 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 FF FF FF 00 14 FF FF 00 00 FF FF 00 5B FF " + ;
"FF 00 B4 B4 B4 00 00 35 35 00 00 CD CD 00 00 0B " + ;
"0B 00 00 F3 F3 00 00 09 09 00 00 CE CE 00 00 C5 " + ;
"C5 00 00 1C 1C 00 00 E9 E9 00 00 0D 0D 00 00 EC " + ;
"EC 00 00 18 18 00 00 E3 E3 00 00 C2 C2 00 00 41 " + ;
"41 00 00 D2 D2 00 00 DD DD 00 00 0E 0E 00 00 5E " + ;
"5E 00 00 9E 9E 00 00 2E 2E 00 00 3C 3C 00 00 10 " + ;
"10 00 00 2B 2B 00 00 37 37 00 00 02 02 00 00 7B " + ;
"7B 00 00 69 69 00 00 8A 8A 00 00 9C 9C 00 00 51 " + ;
"51 00 00 A2 A2 00 00 59 59 00 00 05 05 00 00 C1 " + ;
"C1 00 00 DB DB 00 00 C9 C9 00 00 EE EE 00 00 E8 " + ;
"E8 00 00 25 25 00 00 A3 A3 00 00 DE DE 00 00 CB " + ;
"CB 00 00 D4 D4 00 00 3B 3B 00 00 B7 B7 00 00 54 " + ;
"54 00 00 99 99 00 00 E2 E2 00 00 1A 1A 00 00 95 " + ;
"95 00 00 90 90 00 00 6C 6C 00 00 FA FA 00 00 23 " + ;
"23 00 00 72 72 00 00 42 42 00 00 B9 B9 00 00 78 " + ;
"78 00 00 7C 7C 00 00 0F 0F 00 00 E5 E5 00 00 DC " + ;
"DC 00 00 26 26 00 00 C7 C7 00 00 D8 D8 00 00 CA " + ;
"CA 00 00 AA AA 00 00 76 76 00 00 A7 A7 00 00 82 " + ;
"82 00 00 3F 3F 00 00 D9 D9 00 00 5C 5C 00 00 92 " + ;
"92 00 00 6E 6E 00 00 44 44 00 00 62 62 00 00 15 " + ;
"15 00 00 71 71 00 00 E7 E7 00 00 34 34 00 00 F1 " + ;
"F1 00 00 3E 3E 00 00 F2 F2 00 00 77 77 00 00 F8 " + ;
"F8 00 00 8D 8D 00 00 47 47 00 00 D0 D0 00 00 17 " + ;
"17 00 00 6B 6B 00 00 4B 4B 00 00 CC CC 00 00 28 " + ;
"28 00 00 9A 9A 00 00 BF BF 00 00 32 32 00 00 B6 " + ;
"B6 00 00 87 87 00 00 97 97 00 00 63 63 00 00 74 " + ;
"74 00 00 12 12 00 00 BD BD 00 00 36 36 00 00 AC " + ;
"AC 00 00 70 70 00 00 B1 B1 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"64 65 00 00 00 64 65 00 00 1D 66 1C 00 00 67 68 " + ;
"00 00 0A 66 66 66 66 25 1F 69 66 6A 6B 6C 6D 25 " + ;
"3D 6E 3A 00 00 6F 70 6E 71 00 0A 72 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 00 55 56 26 00 00 4C 56 " + ;
"57 00 0F 58 59 59 59 06 34 0B 3E 21 5A 5B 11 5C " + ;
"5D 5E 5F 53 60 2B 61 62 63 61 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 00 33 4A 4B 00 00 46 4C " + ;
"20 00 0F 10 00 00 00 00 4D 4E 4F 1E 50 51 11 0E " + ;
"00 00 52 3F 53 25 00 00 54 08 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 27 12 42 43 1F 1C 44 45 " + ;
"46 00 0F 10 00 00 00 00 00 34 25 46 3B 3A 11 47 " + ;
"00 00 1A 48 3A 03 03 03 03 49 0F 10 00 00 00 00 " + ;
"06 03 03 03 03 03 07 00 32 33 00 33 32 34 35 00 " + ;
"36 1C 0F 10 00 00 00 00 37 38 00 00 39 3A 11 3B " + ;
"3C 00 3D 19 3E 3F 1F 00 40 41 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 20 20 00 21 22 23 24 00 " + ;
"25 26 0F 10 00 00 00 00 27 28 29 2A 09 1D 11 2B " + ;
"15 0C 2C 2D 00 2E 2F 30 31 1C 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 13 14 00 0D 15 16 17 00 " + ;
"18 19 0F 10 00 00 00 00 00 00 1A 1B 1C 00 11 12 " + ;
"17 1B 08 00 00 00 1D 1E 1F 00 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 08 09 0A 00 00 0B 0C 00 00 " + ;
"0D 0E 0F 10 00 00 00 00 00 00 00 00 00 00 11 12 " + ;
"00 00 00 00 00 00 00 00 00 00 0F 10 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 00 00 00 00 " + ;
"00 00 05 00 00 00 00 00 00 00 00 00 00 00 00 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 00 00 00 00 " + ;
"05 00 00 00 00 00 00 00 00 00 00 00 00 00 05 00 " + ;
"00 00 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 00 00 00 00 " + ;
"00 00 05 00 00 00 00 00 00 00 00 00 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 00 00 00 00 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 04 04 04 04 04 " + ;
"04 04 04 04 04 04 04 04 04 04 04 04 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 00 00 00 00 00 01 00 00 00 00 00 00 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 00 00 00 00 00 00 00 00 01 00 00 00 01 00 00 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 00 00 00 00 00 00 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 02 02 02 02 02 " + ;
"02 02 02 02 02 02 02 02 02 02 02 02 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 "

* ==================================== EOF of libhwlabel.prg ================================

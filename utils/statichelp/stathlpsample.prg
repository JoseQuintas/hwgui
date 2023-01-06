/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 * stathlpsample.prg - Sample program using static
 * help text.
 *
 * Copyright 2023 
 * Wilfried Brunken, DF7BE
 * 
 * https://sourceforge.net/projects/hwgui/
 */
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes

#include "hwgui.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif


* Forever needed
REQUEST HB_CODEPAGE_UTF8
* Windows: 
* Add codepage request concerning your used language(s)
REQUEST HB_CODEPAGE_DEWIN

MEMVAR cHelptext1, cHelptext2

FUNCTION Main()

   LOCAL oWndMain, oButton1, oButton2, oButton3
   
   PUBLIC cHelptext1, cHelptext2
   
   INIT_HELPTXT()
   
  INIT WINDOW oWndMain MAIN TITLE "Static help sample" ;
     AT 309,167 SIZE 560,199 
 
   @ 38,45 BUTTON oButton1 CAPTION "Quit"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { | | oWndMain:Close() }
   * Pure ASCII, no conversion needed
   @ 154,45 BUTTON oButton2 CAPTION "Help Text EN"   SIZE 146,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { | | hwg_ShowHelp(cHelptext1,"Static help sample") } ;
        TOOLTIP "Display English help window"
   @ 326,45 BUTTON oButton3 CAPTION "Help Text DE"   SIZE 164,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { | | ShowHelp_DE(cHelptext2, "Statischer Hilfe-Text", ;
         "Schließen") } ;
        TOOLTIP "Display German help window" 
 
  ACTIVATE WINDOW oWndMain 
  
RETURN NIL

FUNCTION ShowHelp_DE(cHelptxt, cTitle, cButton)

* Conversion from UTF-8 needed for Windows
cHelptxt := xTranslateWin_DE(cHelptxt)
cTitle   := xTranslateWin_DE(cTitle)
cButton  := xTranslateWin_DE(cButton)

hwg_ShowHelp(cHelptxt,cTitle,cButton)

RETURN NIL

FUNCTION xTranslateWin_DE(clang)
#ifdef __PLATFORM__WINDOWS
clang := HB_TRANSLATE( clang, "UTF8", "DEWIN" )
#endif
RETURN clang

FUNCTION INIT_HELPTXT()

MEMVAR cHelptext1, cHelptext2
* The static help texts

cHelptext1 := ;
"This is help text 1" +  CHR(13) + CHR(10)  + ;
"(pure ASCII)" +  CHR(13) + CHR(10)  + ;
"OK for text in English lan" +  ; 
"guage" +  CHR(13) + CHR(10)  + ;
"[]{}\@|<>$" + CHR(34)  +  CHR(39) + "test the quick" +  ; 
" brown fox" +  CHR(13) + CHR(10)  + ;
"jumps over the lazy dog" + CHR(39)  +  CHR(34)  +   CHR(13) + CHR(10)  + ;
"%&/()=!#*?"

cHelptext2 := ;
"This is help text 2 (Germa" +  ; 
"n)" + CHR(13) + CHR(10) + ;
"(UTF-8)" + CHR(13) + CHR(10) + ;
"Deutsche Umlaute und Euro-" +  ; 
"Währungszeichen." + CHR(13) + CHR(10) + ;
"ÄÖÜäöüß€@" + CHR(13) + CHR(10) + ;
""

RETURN NIL

* ===================== EOF of stathlpsample.prg ======================

*
* juldate.prg
*
* $Id$ 
*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
* Test program for Julian date converting functions
*
* Copyright 2022 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
 
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes 


#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif
FUNCTION MAIN()

LOCAL oWinMain

SET CENTURY ON
SET DATE GERMAN


INIT WINDOW oWinMain MAIN  ;
     TITLE "Test program Julian Date" AT 0, 0 SIZE 600,400;
     STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "Test it"     ACTION TestAll()
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN NIL

FUNCTION TestAll()

TESTIT( DATE(), "Today")
TESTIT( CTOD("01.01.1901"), "OK" )
TESTIT( CTOD("31.12.2000"), "OK" )
TESTIT( CTOD("31.12.2099"), "OK" )
TESTIT( CTOD("01.01.1900"), "Error" )
TESTIT( CTOD("01.01.2100"), "Error" )
TESTIT( CTOD("01.07.2100"), "Error" )


RETURN NIL


FUNCTION TESTIT(dinput, cTitle)
LOCAL njulian, cdateo , ddateo , cErro

cErro := " "
njulian := hwg_Date2JulianDay( dinput )
cdateo :=  hwg_JulianDay2Date(njulian)
IF EMPTY(cdateo)
    cErro := "Error !"
ENDIF
ddateo := hwg_STOD(cdateo)

hwg_msgInfo( "Input: " + DTOC(dinput) + CHR(10) + ;
"Julian Date : " + ALLTRIM(STR(njulian)) + CHR(10) + ;
"Returned date : " + cdateo  + CHR(10) + ;
"After hwg_STOD() : " +  DTOC(ddateo) + CHR(10) + cErro ;
  ,cTitle)

RETURN NIL


* ==================================== EOF of juldate.prg ========================================



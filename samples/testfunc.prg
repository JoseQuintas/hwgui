/*
 *
 * testfunc.prg
 *
 * Test program sample for HWGUI (hwg_*) standalone functions
 * 
 * $Id$
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2020 Wilfried Brunken, DF7BE 
*/

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes
/* 
  Add extensions to your own needs
*/


#include "hwgui.ch"
#include "common.ch"
#include "windows.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif



FUNCTION MAIN
LOCAL Testfunc, oFont

LOCAL oButton1, oButton2, oButton3, oButton4, oButton5, oButton6, oButton7, oButton8, oButton9
LOCAL oButton10, oButton11, oButton12
PUBLIC bgtk

* Detect GTK build
bgtk := .F.
#ifdef __GTK__
bgtk := .T.
#endif

SET DATE ANSI  && YY(YY).MM.TT

#ifdef __PLATFORM__WINDOWS
 PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -10 && vorher -13
#else
 PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif 

  INIT WINDOW Testfunc MAIN TITLE "Test Of Standalone HWGUI Functions" ;
    AT 1,1 SIZE 770,548 ; 
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 25,25 BUTTON oButton1 CAPTION "Exit" SIZE 75,18 FONT oFont ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { | | Testfunc:Close() }
   @ 127,25 BUTTON oButton2 CAPTION "CENTURY ON"   SIZE 120,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK  { | | CENT_ON() }
   @ 277,25 BUTTON oButton3 CAPTION "CENTURY OFF"   SIZE 120,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK  { | | CENT_OFF() }
   @ 407,25 BUTTON oButton4 CAPTION "DATE()"   SIZE 120,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | |Funkt(DATE(),"D","DATE()") }
   @ 537,25 BUTTON oButton5 CAPTION "Summary"   SIZE 120,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | |  fSUMM() }
   @ 25,50 BUTTON oButton6 CAPTION "hwg_GetUTCTimeDate()" SIZE 218,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | |Funkt(hwg_GetUTCTimeDate(),"C","hwg_GetUTCTimeDate()") }
   @ 250,50 BUTTON oButton7 CAPTION "hwg_getCentury()" SIZE 218,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Funkt(hwg_getCentury(),"O","hwg_getCentury()") }

   /* Sample for a Windows only function,
      use a intermediate function with compiler switch for platform windows   */
   @ 505,50 BUTTON oButton8 CAPTION "hwg_GetWindowsDir()" SIZE 218,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Funkt(GET_WINDIR(),"C","hwg_GetWindowsDir()") }

   @ 25,75 BUTTON oButton9 CAPTION "hwg_GetTempDir()" SIZE 218,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | |Funkt(hwg_GetTempDir(),"C","hwg_GetTempDir()") }

   @ 25,100 BUTTON oButton10 CAPTION "Test Button" SIZE 140,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Hwg_MsgInfo("This is a test without any function") }

   @ 180,100 BUTTON oButton11 CAPTION "Deactivate Test Button" SIZE 140,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | TstButt_Deact(oButton10) }

   @ 340,100 BUTTON oButton11 CAPTION "Activate Test Button" SIZE 140,18 FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | TstButt_Act(oButton10) }
   

/* Disable buttons for Windows only functions */
#ifndef __PLATFORM__WINDOWS
     oButton8:Disable()
#endif

   ACTIVATE WINDOW Testfunc
RETURN NIL

* ====================================
FUNCTION Funkt ( rval, cType , cfunkt)
* Executes a function and displays the
* result in a info messagebox.
* rval: Return value of the called function
* cfunkt: Name of the function for display in title.
* cType: Type of rval
* "C" "N" "L" "D"
* "O" ==> "L", but display ON/OFF
* ====================================
 DO CASE
     CASE cType == "C"
      hwg_MsgInfo("Return Value: >" + rval + "<", "Function: " + cfunkt )
     CASE cType == "N"
      hwg_MsgInfo("Return Value: >" + ALLTRIM(STR(rval)) + "<", "Function: " + cfunkt )
     CASE cType == "L"
      hwg_MsgInfo("Return Value: >" + IIF(rval,"True","False") + "<", "Function: " + cfunkt )
     CASE cType == "D"
      hwg_MsgInfo("Return Value: >" + DTOC(rval) + "<", "Function: " + cfunkt )
     CASE cType == "O"
      hwg_MsgInfo("Return Value: >" + IIF(rval,"ON","OFF") + "<", "Function: " + cfunkt )
 ENDCASE
 
RETURN NIL 

FUNCTION CENT_ON
 SET CENTURY ON
RETURN NIL  

FUNCTION CENT_OFF
 SET CENTURY OFF 
RETURN NIL

FUNCTION N2STR(numb)
RETURN ALLTRIM(STR(numb) ) 

FUNCTION TotF(btf)
RETURN IIF(btf,"True","False")

FUNCTION TstButt_Deact(obo)
      obo:Disable()
RETURN NIL

FUNCTION TstButt_Act(obo)
      obo:Enable()
RETURN NIL

FUNCTION fSUMM
  hwg_Msginfo( ;
       "OS(): " + OS() + CHR(10) + ;
       "Hwgui Version  : " + hwg_Version() + CHR(10) + ;   
       "Windows : " + TotF(hwg_isWindows() )  + CHR(10) + ; 
       "Windows 7: " + TotF(hwg_isWin7() ) + CHR(10) + ; 
       "Windows 10: " + TotF(hwg_isWin10() ) + CHR(10) + ;
       "Windows Maj.Vers.: " + N2STR(hwg_GetWinMajorVers() ) + CHR(10) + ;
       "Windows Min.Vers.: " + N2STR(hwg_GetWinMinorVers() ) + CHR(10) + ; 
       "Unicode : " + TotF(hwg__isUnicode() ) + CHR(10) + ;
       "Default user lang. :" + HWG_DEFUSERLANG() + CHR(10) +  ;
       "Locale :" + hwg_GetLocaleInfo() + CHR(10) +  ;
       "Locale (N) :" + N2STR(hwg_GetLocaleInfoN()) + CHR(10) +  ;
       "UTC :" + HWG_GETUTCTIMEDATE() + CHR(10) +  ;
       "GTK : " + TotF(bgtk) ;
   )
RETURN NIL

FUNCTION GET_WINDIR
LOCAL verz
#ifndef __PLATFORM__WINDOWS
 verz := "<none>: Windows only"
#else
 verz := hwg_GetWindowsDir()
#endif
RETURN verz

* ============================== EOF of testfunc.prg ==============================
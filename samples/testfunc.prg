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

/*
 List of used HWGUI standalone functions:
 
 hwg_GetUTCTimeDate()
 hwg_GetDateANSI()
 hwg_GetUTCDateANSI()
 hwg_GetUTCTime()
 hwg_getCentury()
 hwg_GetWindowsDir()
 hwg_GetTempDir()
 hwg_CreateTempfileName
 Activate / Deactivate  Button
 hwg_CompleteFullPath()
 hwg_ShowCursor()
 hwg_GetCursorType() && GTK only
 hwg_IsLeapYear ( nyear )

 Harbour functions:
 CurDir() 
 
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
LOCAL Testfunc, oFont , nheight

LOCAL oButton1, oButton2, oButton3, oButton4, oButton5, oButton6, oButton7, oButton8, oButton9
LOCAL oButton10, oButton11 , oButton12 , oButton13 , oButton14 , oButton15 , oButton16 , oButton17
LOCAL oButton18, oButton19 , oButton20 , oButton21 , oButton22  
PUBLIC cDirSep := hwg_GetDirSep()
PUBLIC bgtk , ndefaultcsrtype

* Detect GTK build
bgtk := .F.
#ifdef __GTK__
bgtk := .T.
#endif

SET DATE ANSI  && YY(YY).MM.TT

#ifdef __PLATFORM__WINDOWS
 nheight := 18
 PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -10 && vorher -13
#else
 nheight := 25
 PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif 
  
* save default cursor style in a numeric variable for
* later recovery after cursor hide action.  
#ifdef __GTK__  
 ndefaultcsrtype := hwg_GetCursorType() && GTK only
#else
 ndefaultcsrtype := 0  && not needed on WinAPI
#endif 
 
 // hwg_msginfo(Str(ndefaultcsrtype))

  INIT WINDOW Testfunc MAIN TITLE "Test Of Standalone HWGUI Functions" ;
    AT 1,1 SIZE 770,548 ; 
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 25,25 BUTTON oButton1 CAPTION "Exit" SIZE 75,nheight FONT oFont ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { | | Testfunc:Close() }
   @ 127,25 BUTTON oButton2 CAPTION "CENTURY ON"   SIZE 120,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK  { | | CENT_ON() }
   @ 277,25 BUTTON oButton3 CAPTION "CENTURY OFF"   SIZE 120,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK  { | | CENT_OFF() }
   @ 407,25 BUTTON oButton4 CAPTION "DATE()"   SIZE 120,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | |Funkt(DATE(),"D","DATE()") }
   @ 537,25 BUTTON oButton5 CAPTION "Summary"   SIZE 120,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | |  fSUMM() }
   @ 25,50 BUTTON oButton6 CAPTION "hwg_GetUTCTimeDate()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | |Funkt(hwg_GetUTCTimeDate(),"C","hwg_GetUTCTimeDate()") }
   @ 250,50 BUTTON oButton7 CAPTION "hwg_getCentury()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Funkt(hwg_getCentury(),"O","hwg_getCentury()") }

   /* Sample for a Windows only function,
      use a intermediate function with compiler switch for platform windows   */
   @ 505,50 BUTTON oButton8 CAPTION "hwg_GetWindowsDir()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Funkt(GET_WINDIR(),"C","hwg_GetWindowsDir()") }

   @ 25,75 BUTTON oButton9 CAPTION "hwg_GetTempDir()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | |Funkt(hwg_GetTempDir(),"C","hwg_GetTempDir()") }

   @ 250,75 BUTTON oButton9 CAPTION "hwg_CreateTempfileName()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | |Funkt(hwg_CreateTempfileName(),"C","hwg_CreateTempfileName()") }

   @ 505,75 BUTTON oButton12 CAPTION "GetWindowsDir Full" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Funkt(GET_WINDIR_FULL(),"C","GET_WINDIR_FULL()") }

   @ 25,100 BUTTON oButton10 CAPTION "Test Button" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Hwg_MsgInfo("This is a test without any function") }

   @ 180,100 BUTTON oButton11 CAPTION "Deactivate Test Button" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | TstButt_Deact(oButton10) }

   @ 340,100 BUTTON oButton13 CAPTION "Activate Test Button" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | TstButt_Act(oButton10) }

   @ 25 ,125 BUTTON oButton15 CAPTION "CurDir()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(CurDir(),"C","CurDir()") }

   @ 180 ,125 BUTTON oButton16 CAPTION "hwg_CurDir()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(hwg_CurDir(),"C","hwg_CurDir()") }

   @ 25 ,150 BUTTON oButton17 CAPTION "hwg_GetDateANSI()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(hwg_GetDateANSI(),"C","hwg_GetDateANSI()") }

   @ 180 ,150 BUTTON oButton18 CAPTION "hwg_GetUTCDateANSI()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(hwg_GetUTCDateANSI(),"C","hwg_GetUTCDateANSI()") }

   @ 340 ,150 BUTTON oButton19 CAPTION "hwg_GetUTCTime()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(hwg_GetUTCTime(),"C","hwg_GetUTCTime()") }

   * Hide / recovery of mouse cursor in extra dialog
   @ 25 ,175 BUTTON oButton20 CAPTION "Cursor functions" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | HIDE_CURSOR ( oFont , nheight , Testfunc) }
 
   @ 25 ,200 BUTTON oButton22 CAPTION "hwg_IsLeapYear()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
                { | | TestLeapYear() } 

/* Disable buttons for Windows only functions */
#ifndef __PLATFORM__WINDOWS
     oButton8:Disable()
#endif



   ACTIVATE WINDOW Testfunc
RETURN NIL

FUNCTION HIDE_CURSOR ( oFont , nheight , Testfunc )
* Testfunc: object variable of main window only for GTK

  LOCAL odlg , oButton1 , oButton2 , oButton3 , ncursor , hmain
  
  * Init, otherwise crashes, if dialog closed without any action.
  ncursor := 0 

* For hiding mouse cursor on main window
//     hmain := Testfunc:handle

      INIT DIALOG odlg TITLE "Hide / show cursor"  AT 0,0   SIZE 400 , 100 ;
      FONT oFont CLIPPER

* Hide cursor only in dialog window.
  hmain := odlg:handle  


   @ 25 , 25 BUTTON oButton1 CAPTION "hwg_ShowCursor(.F.)" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt( ncursor := hwg_ShowCursor(.F.,hmain,ndefaultcsrtype),"N","hwg_ShowCursor(.F.)") , ;
            hwg_Setfocus(oButton2:handle) }

   @ 180 , 25 BUTTON oButton2 CAPTION "hwg_ShowCursor(.T.)" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt( ncursor := hwg_ShowCursor(.T.,hmain,ndefaultcsrtype),"N","hwg_ShowCursor(.T.)") }

   @ 25 , 50 BUTTON oButton3 CAPTION "Return" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | odlg:Close }

  ACTIVATE DIALOG odlg
 
#ifndef __GTK__ 
   * Activate cursor before return to main window
   * crash on GTK, because handle is lost after leaving dialog.
   DO WHILE ncursor < 0
      ncursor := hwg_ShowCursor(.T.)   && ,hmain,ndefaultcsrtype)  : crash 
   ENDDO
#endif   
   
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
       "GTK : " + TotF(bgtk)  + CHR(10) + ;
       "Dir Separator: " + cDirSep ;
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

FUNCTION GET_WINDIR_FULL
LOCAL verz
#ifndef __PLATFORM__WINDOWS
 verz := "<none>: Windows only"
#else
 verz := hwg_CompleteFullPath(hwg_GetWindowsDir() )
#endif
RETURN verz


FUNCTION TestLeapYear()
LOCAL nyeart
Local oTestLeapYear
LOCAL oLabel1, oEditbox1, oButton1 , oButton2

nyeart := YEAR( DATE() )  && Preset recent year

 INIT DIALOG oTestLeapYear TITLE "hwg_IsLeapYear()" ;
    AT 738,134 SIZE 516,336 NOEXIT ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 54,44 SAY oLabel1 CAPTION "Enter a year 1583 and higher"  SIZE 380,22   
   @ 61,102 GET oEditbox1 VAR nyeart  SIZE 325,24 ;
        STYLE WS_BORDER   PICTURE "9999"   
   @ 63,181 BUTTON oButton1 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT   ;
        ON CLICK { | | Res_LeapYear(nyeart) }
   @ 200,181 BUTTON oButton2 CAPTION "Cancel"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT   ;
        ON CLICK { | | oTestLeapYear:Close() }

   ACTIVATE DIALOG oTestLeapYear



RETURN NIL


FUNCTION Res_LeapYear(nyeart)
LOCAL cRet  
 cRet := IIF(hwg_IsLeapYear(nyeart), "TRUE","FALSE") 
 hwg_MsgInfo("Result of Res_LeapYear(" + ALLTRIM(STR(nyeart)) + ")=" + cRet , "hwg_IsLeapYear()" )
RETURN NIL


* ============================== EOF of testfunc.prg ==============================

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
 * Copyright 2020-2022 Wilfried Brunken, DF7BE
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
 hwg_MsgYesNoCancel(...)
 hwg_GUIType()
 hwg_RunApp()
 hwg_Has_Win_Euro_Support()
 hwg_FileModTimeU()
 hwg_FileModTime()
 hwg_Get_Time_Shift()


 Harbour functions:
 CurDir()

*/


#include "hwgui.ch"
#include "common.ch"
// #include "windows.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

MEMVAR cDirSep , bgtk , ndefaultcsrtype

FUNCTION MAIN()

   LOCAL Testfunc, oFont , nheight
   LOCAL oButton1, oButton2, oButton3, oButton4, oButton5, oButton6, oButton7, oButton8, oButton9
   LOCAL oButton10, oButton11 , oButton12 , oButton13 , oButton14 , oButton15 , oButton16 , oButton17
   LOCAL oButton18, oButton19 , oButton20 , oButton21 , oButton22 , oButton23 , oButton24 , oButton25
   LOCAL oButton26, oButton27, oButton28, oButton29
   
   LOCAL nspcbutton
  
   PUBLIC cDirSep := hwg_GetDirSep()
   PUBLIC bgtk , ndefaultcsrtype

* Trouble with GTK3:
* Buttons are greater than nheigth, so
* space between them must be increased

  nspcbutton := 25   && Windows and GTK2
#ifdef ___GTK3___
  nspcbutton := 35
#endif  
 
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

   @ 25,nspcbutton BUTTON oButton1 CAPTION "Exit" SIZE 75,nheight FONT oFont ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { | | Testfunc:Close() } ;
        TOOLTIP "Terminate Program"
   @ 127,nspcbutton BUTTON oButton2 CAPTION "CENTURY ON"   SIZE 120,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK  { | | CENT_ON() }
   @ 277,nspcbutton BUTTON oButton3 CAPTION "CENTURY OFF"   SIZE 120,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK  { | | CENT_OFF() }
   @ 407,nspcbutton BUTTON oButton4 CAPTION "DATE()"   SIZE 120,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | |Funkt(DATE(),"D","DATE()") }
   @ 537,nspcbutton BUTTON oButton5 CAPTION "Summary"   SIZE 120,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | |  fSUMM() }
   @ 25,nspcbutton * 2 BUTTON oButton6 CAPTION "hwg_GetUTCTimeDate()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | |Funkt(hwg_GetUTCTimeDate(),"C","hwg_GetUTCTimeDate()") }
   @ 250,nspcbutton * 2 BUTTON oButton7 CAPTION "hwg_getCentury()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Funkt(hwg_getCentury(),"O","hwg_getCentury()") }

   /* Sample for a Windows only function,
      use a intermediate function with compiler switch for platform windows   */
   @ 505,nspcbutton * 2 BUTTON oButton8 CAPTION "hwg_GetWindowsDir()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Funkt(GET_WINDIR(),"C","hwg_GetWindowsDir()") }

   @ 25,nspcbutton * 3 BUTTON oButton9 CAPTION "hwg_GetTempDir()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | |Funkt(hwg_GetTempDir(),"C","hwg_GetTempDir()") }

   @ 250,nspcbutton * 3 BUTTON oButton9 CAPTION "hwg_CreateTempfileName()" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | |Funkt(hwg_CreateTempfileName(),"C","hwg_CreateTempfileName()") }

   @ 505,nspcbutton * 3 BUTTON oButton12 CAPTION "GetWindowsDir Full" SIZE 218,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Funkt(GET_WINDIR_FULL(),"C","GET_WINDIR_FULL()") }

   @ 25,nspcbutton * 4 BUTTON oButton10 CAPTION "Test Button" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Hwg_MsgInfo("This is a test without any function") }

   @ 180,nspcbutton * 4 BUTTON oButton11 CAPTION "Deactivate Test Button" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | TstButt_Deact(oButton10) }

   @ 340,nspcbutton * 4 BUTTON oButton13 CAPTION "Activate Test Button" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | TstButt_Act(oButton10) }

   @ 25 ,nspcbutton * 5 BUTTON oButton15 CAPTION "CurDir()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(CurDir(),"C","CurDir()") }

   @ 180 ,nspcbutton * 5 BUTTON oButton16 CAPTION "hwg_CurDir()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(hwg_CurDir(),"C","hwg_CurDir()") }

   @ 25 ,nspcbutton * 6  BUTTON oButton17 CAPTION "hwg_GetDateANSI()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(hwg_GetDateANSI(),"C","hwg_GetDateANSI()") }

   @ 180 ,nspcbutton * 6 BUTTON oButton18 CAPTION "hwg_GetUTCDateANSI()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(hwg_GetUTCDateANSI(),"C","hwg_GetUTCDateANSI()") }

   @ 340 ,nspcbutton * 6 BUTTON oButton19 CAPTION "hwg_GetUTCTime()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(hwg_GetUTCTime(),"C","hwg_GetUTCTime()") }

   * Hide / recovery of mouse cursor in extra dialog
   @ 25 ,nspcbutton * 7 BUTTON oButton20 CAPTION "Cursor functions" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | HIDE_CURSOR ( oFont , nheight , Testfunc) }

   @ 25 ,nspcbutton * 8 BUTTON oButton22 CAPTION "hwg_IsLeapYear()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
                { | | TestLeapYear() }

   @ 180,nspcbutton * 7 BUTTON oButton23 CAPTION "hwg_Has_Win_Euro_Support()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
                { | |  Funkt(hwg_Has_Win_Euro_Support(),"L","hwg_Has_Win_Euro_Support()" ) }

   @ 340,nspcbutton * 7 BUTTON oButton24 CAPTION "hwg_FileModTimeU()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
                { | |  Test_FileModTimeU() }

   @ 505,nspcbutton * 7 BUTTON oButton25 CAPTION "hwg_FileModTime()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
                { | |  Test_FileModTime() }

   @ 505 ,nspcbutton * 6 BUTTON oButton26 CAPTION "hwg_Get_Time_Shift()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt(hwg_Get_Time_Shift(),"N","hwg_Get_Time_Shift()") }

   @ 505 ,nspcbutton * 4 BUTTON oButton27 CAPTION "New caption Test Button" SIZE 160,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | oButton10:SetText("New Caption") }

   @ 25 ,nspcbutton * 9 BUTTON oButton22 CAPTION "hwg_MsgYesNoCancel()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
                { | | Test_MsgYesNoCancel() }

   @ 25 ,nspcbutton * 10 BUTTON oButton28 CAPTION "hwg_GUIType()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | Funkt(hwg_GUIType(),"C","hwg_GUIType()") }

   @ 180 ,nspcbutton * 10 BUTTON oButton29 CAPTION "hwg_RunApp()" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
       { | | do_the_RunApp() }


   /* Disable buttons for Windows only functions */
#ifndef __PLATFORM__WINDOWS
   oButton8:Disable()
#endif

   ACTIVATE WINDOW Testfunc

RETURN Nil

FUNCTION HIDE_CURSOR ( oFont , nheight , Testfunc )

   * Testfunc: object variable of main window only for GTK

   LOCAL odlg , oButton1 , oButton2 , oButton3 , ncursor , hmain

   * Init, otherwise crashes, if dialog closed without any action.
   ncursor := 0

   * For hiding mouse cursor on main window
   //     hmain := Testfunc:handle

   INIT DIALOG odlg TITLE "Hide / show cursor"  AT 0,0   SIZE 400 , 200 ;
      FONT oFont CLIPPER

   * Hide cursor only in dialog window.
   hmain := odlg:handle

   @ 25 , 35 BUTTON oButton1 CAPTION "hwg_ShowCursor(.F.)" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt( ncursor := hwg_ShowCursor(.F.,hmain,ndefaultcsrtype),"N","hwg_ShowCursor(.F.)") , ;
            hwg_Setfocus(oButton2:handle) }

   @ 180 , 35 BUTTON oButton2 CAPTION "hwg_ShowCursor(.T.)" SIZE 140,nheight FONT oFont  ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
        { | | Funkt( ncursor := hwg_ShowCursor(.T.,hmain,ndefaultcsrtype),"N","hwg_ShowCursor(.T.)") }

   @ 25 , 70 BUTTON oButton3 CAPTION "Return" SIZE 140,nheight FONT oFont  ;
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

RETURN Nil

FUNCTION Funkt( rval, cType , cfunkt)

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

RETURN Nil

FUNCTION CENT_ON()

   SET CENTURY ON

RETURN Nil

FUNCTION CENT_OFF()

   SET CENTURY OFF

RETURN Nil

FUNCTION N2STR( numb )

   RETURN ALLTRIM( STR( numb ) )

FUNCTION TotF( btf )

RETURN IIF( btf, "True", "False" )

FUNCTION ToLogical( btf )

RETURN IIF( btf, ".T.", ".F." )

FUNCTION TstButt_Deact( obo )

   obo:Disable()

RETURN Nil

FUNCTION TstButt_Act( obo )

   obo:Enable()

RETURN Nil

FUNCTION fSUMM()

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

RETURN Nil

FUNCTION GET_WINDIR()

   LOCAL verz

#ifndef __PLATFORM__WINDOWS
   verz := "<none>: Windows only"
#else
   verz := hwg_GetWindowsDir()
#endif

RETURN verz

FUNCTION GET_WINDIR_FULL()

   LOCAL verz

#ifndef __PLATFORM__WINDOWS
   verz := "<none>: Windows only"
#else
   verz := hwg_CompleteFullPath(hwg_GetWindowsDir() )
#endif

RETURN verz

FUNCTION TestLeapYear()

   LOCAL nyeart
   LOCAL oTestLeapYear
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

RETURN Nil

FUNCTION Res_LeapYear( nyeart )

   LOCAL cRet

   cRet := IIF(hwg_IsLeapYear(nyeart), "TRUE","FALSE")
   hwg_MsgInfo("Result of Res_LeapYear(" + ALLTRIM(STR(nyeart)) + ")=" + cRet , "hwg_IsLeapYear()" )

RETURN Nil

FUNCTION FILE_SEL()

   LOCAL cstartvz,fname

   * Get current directory as start directory
   cstartvz := Curdir()
   fname := hwg_Selectfile("Select a file" , "*.*", cstartvz )

RETURN fname

FUNCTION Test_FileModTimeU()

   LOCAL fn, ctim

   fn := FILE_SEL()
   IF EMPTY(fn)
      RETURN NIL
   ENDIF
   ctim := hwg_FileModTimeU(fn)
   hwg_MsgInfo("Modification date and time (UTC) of file" + ;
      CHR(10) + fn + " is :" + CHR(10) +  ctim, "Result of hwg_FileModTimeU()")

RETURN Nil

FUNCTION Test_FileModTime()

   LOCAL fn, ctim

   fn := FILE_SEL()
   IF EMPTY( fn )
      RETURN Nil
   ENDIF
   ctim := hwg_FileModTime(fn)
   hwg_MsgInfo("Modification date and time (local) of file" + ;
      CHR(10) + fn + " is :" + CHR(10) +  ctim, "Result of hwg_FileModTime()")

RETURN Nil

FUNCTION Test_MsgYesNoCancel()

   LOCAL nretu

   nretu := hwg_MsgYesNoCancel("Press a button")
   * yes    = 1
   * no     = 2
   * cancel = 0

   hwg_MsgInfo( STR( nretu ) , "Return value of hwg_MsgYesNoCancel()" )

RETURN Nil


FUNCTION do_the_RunApp()
LOCAL cCmd , rc , cgt

cCmd := _hwg_RunApp()
IF EMPTY(cCmd)
 RETURN NIL
ENDIF

rc := hwg_RunApp(cCmd)

cgt := hwg_GUIType()

DO CASE   
 CASE cgt == "WinAPI"
  hwg_MsgInfo("Return Code: " + ALLTRIM(STR(rc)),"Result of hwg_RunApp()")
 CASE cgt == "GTK2"
  hwg_MsgInfo("Return Code: " + ALLTRIM(STR(rc)),"Result of hwg_RunApp()")
//  hwg_MsgInfo("Return Code: " + ToLogical(),"Result of hwg_RunApp()")
 CASE cgt == "GTK3"
  hwg_MsgInfo("Return Code: " + ALLTRIM(STR(rc)),"Result of hwg_RunApp()")
//  hwg_MsgInfo("Return Code: " + ToLogical(),"Result of hwg_RunApp()")
 ENDCASE
 
RETURN NIL

FUNCTION _hwg_RunApp()

LOCAL _hwg_RunApp_test
LOCAL oLabel1, oEditbox1, oButton1, oButton2
LOCAL cCmd


  cCmd := SPACE(80)
  cCmd := hwg_GET_Helper(cCmd, 80)

  INIT DIALOG _hwg_RunApp_test TITLE "hwg_RunApp()" ;
    AT 315,231 SIZE 940,239 ;
    STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 80,32 SAY oLabel1 CAPTION "Enter command line for run an external program"  SIZE 587,22
   @ 80,71 GET oEditbox1 VAR cCmd  SIZE 772,24 ;
        STYLE WS_BORDER
   @ 115,120 BUTTON oButton1 CAPTION "Run" SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| _hwg_RunApp_test:Close() } 
   @ 809,120 BUTTON oButton2 CAPTION "Cancel" SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| cCmd := "" , _hwg_RunApp_test:Close() }

   ACTIVATE DIALOG _hwg_RunApp_test
* RETURN _hwg_RunApp_test:lresult
RETURN cCmd

* ============================== EOF of testfunc.prg ==============================

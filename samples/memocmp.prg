/*
 *
 * memocmp.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Sample for Edit and Compare memo and get length of a memo 
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2024 Wilfried Brunken, DF7BE
*/

/*
 Some instructions:
 - SET EXACT ON
   before comparing memos with " == "
 - If one memo or both memo's are NIL,
   it is no problem to compare it with " == "
 - The only trouble is to use LEN() to get
   the size of a memo, LEN() crashes, if memo is NIL
   (in this case the return value must be 0)
   so use the FUNCTION nMemolen(mmemo)
   above to get the size of a memo !

 Reference:
 Commit  [r3463] by josequintas 2024-07-17
 Browse code at this revision
 Parent: [r3462]
 Child: [r3464]
 title:
 removed hwg_memocmp() and hwg_lenmem() 
 
*/


   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes
    *  GTK/MacOS:  No

#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

FUNCTION Main()

   LOCAL oWinMain
   LOCAL mmemo1, mmemo2

   SET EXACT ON   
   * Init empty
   mmemo1 := ""
   mmemo2 := ""

   INIT WINDOW oWinMain MAIN  ;
      TITLE "Sample program Memo edit and compare" AT 100, 100 SIZE 600,400;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "Memo &1"  ACTION {|| mmemo1 := hwg_MemoEdit(mmemo1 , "Edit memo 1") }
         MENUITEM "Memo &2"  ACTION {|| mmemo2 := hwg_MemoEdit(mmemo2 , "Edit memo 2") }
         MENUITEM "Init memos with NIL"  ACTION {|| mmemo1 := NIL , mmemo2 := NIL }
      ENDMENU
      MENU TITLE "&Compare"
         MENUITEM " direct =="     ACTION Compare1(mmemo1, mmemo2)
         //
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN Nil

FUNCTION Compare1(mmemo1, mmemo2)
LOCAL nleng1, nleng2

 IF mmemo1 == NIL
   hwg_Msginfo("Memo1 is NIL")
//   mmemo1 := ""
 ENDIF

 IF mmemo2 == NIL
   hwg_Msginfo("Memo2 is NIL")
//   mmemo2 := ""
 ENDIF

/* 
 * Display length
 nleng1 := LEN(mmemo1)
 nleng2 := LEN(mmemo2) 
   hwg_Msginfo("LEN() of memo1 = " + ALLTRIM(STR(nleng1))  + CHR(10) + ;
   "LEN() of memo2 = " + ALLTRIM(STR(nleng2)) )

 The symptom, if memo is NIL
Error BASE/1111  Argument error: LEN
Called from (b)HWG_ERRSYS(20)
Called from LEN(0)
Called from COMPARE1(80)
Called from (b)MAIN(56)
Called from ONCOMMAND(643)
Called from (b)HMAINWINDOW(300)
Called from HMAINWINDOW:ONEVENT(406)
Called from HWG_ACTIVATEMAINWINDOW(0)
Called from HMAINWINDOW:ACTIVATE(395)
Called from MAIN(61)

HWGUI 2.23 dev Build 8
Date:08/05/24
Time:19:07:34
*/

* Use Function nMemolen() above to get the length of memo,
* returns 0, if memo is NIL !

 nleng1 := nMemolen(mmemo1)
 nleng2 := nMemolen(mmemo2) 
   hwg_Msginfo("LEN() of memo1 = " + ALLTRIM(STR(nleng1))  + CHR(10) + ;
   "LEN() of memo2 = " + ALLTRIM(STR(nleng2)) ) 

 IF mmemo1 == mmemo2
   hwg_MsgInfo("Memos are equal")
 ELSE
   hwg_MsgInfo("Memos are not equal")
 ENDIF 
RETURN NIL 


FUNCTION nMemolen(mmemo)

IF mmemo == NIL
* NIL same as LEN=0
 RETURN 0
ENDIF
RETURN MLCount(mmemo, 254 )  && nLineLength ==> max 254  

 
* ==================== EOF of memocmp.prg ========================0
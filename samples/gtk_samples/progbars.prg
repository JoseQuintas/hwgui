/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library
 * Sample of using HProgressBar class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
*/

    * Status:
    *  WinAPI   :  Yes ==> other sample
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

#include "hwgui.ch"

Static oMain, oForm, oFont, oBar := Nil
Static n :=0
Function Main()

        INIT WINDOW oMain MAIN TITLE "Progress Bar Sample" ;
        SIZE 200, 100

        MENU OF oMain
         MENU TITLE "&Exit"
             MENUITEM "&Quit" ACTION oMain:Close()
         ENDMENU
         MENU TITLE "&Demo"
             MENUITEM "&Test" ACTION Test()
         ENDMENU
        ENDMENU

        ACTIVATE WINDOW oMain && MAXIMIZED && DF7BE: Progbar is otherwise hidden.
Return Nil

Function Test()

Local cMsgErr := "Bar doesn't exist"

        PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

        INIT DIALOG oForm CLIPPER NOEXIT TITLE "Progress Bar Demo";
             FONT oFont ;
             AT 0, 0 SIZE 700, 425 ;
             STYLE DS_CENTER + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU ;
             ON EXIT {||Iif(oBar==Nil,.T.,(oBar:Close(),.T.))}

             @ 300, 395 BUTTON 'Reset Bar'   SIZE 75,25 ;
                ON CLICK {|| IIF(oBar == NIL , .T. , RES_PROGBAR ( obar ) ) }

             @ 380, 395 BUTTON 'Step Bar'   SIZE 75,25 ;
                ON CLICK {|| n+=100,Iif(oBar==Nil,hwg_Msgstop(cMsgErr),oBar:Set(,n/100)) }

             @ 460, 395 BUTTON 'Create Bar' SIZE 75,25 ;
                ON CLICK {|| oBar := HProgressBar():NewBox( "Testing ...",500,700,,, 10, 100 ) }
             * Attention !
             * Do not Create a second progress bar. Close recent Progbar before creating a new one.
             * Please set parameters nTop and nLeft forever, it could be possible,
             * that the box with the progress bar is hidden by the calling window.
             * Calling window is in foreground, the box with the progress bar
             * becomes visible if moved. 
             @ 540, 395 BUTTON 'Close Bar'  SIZE 75,25 ;
                ON CLICK {|| Iif(oBar==Nil,hwg_Msgstop(cMsgErr),(oBar:Close(),oBar:=Nil)) }

             @ 620, 395 BUTTON 'Close'      SIZE 75,25 ON CLICK {|| oForm:Close() }

        ACTIVATE DIALOG oForm

Return Nil

FUNCTION RES_PROGBAR ( opbar )
 n := 0
 opBar:Reset()
 * opBar:Set(,0 )
RETURN .F. 


* ====================== EOF of progbars.prg ========================

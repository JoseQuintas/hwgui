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

#include "hwgui.ch"

Static oMain, oForm, oFont, oBar := Nil
Static n :=0
Function Main()

        INIT WINDOW oMain MAIN TITLE "Progress Bar Sample"
* DF7BE: Trouble: If main menu points have no subtite, only "Aktivieren" apprears
*        Bug:
*         Some work needed, Progress bar could be created, but no steps appeared


        MENU OF oMain
*             MENUITEM "&Exit" ACTION oMain:Close()
*             MENUITEM "&Demo" ACTION Test()

              MENU TITLE "&Exit" 
               MENUITEM "&Exit" ACTION oMain:Close()
              ENDMENU
              MENU TITLE "&Demo" 
               MENUITEM "&Demo" ACTION Test()
              ENDMENU
        ENDMENU

        ACTIVATE WINDOW oMain MAXIMIZED
Return Nil

Function Test()
Local cMsgErr := "Bar doesn't exist"

        PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

        INIT DIALOG oForm CLIPPER NOEXIT TITLE "Progress Bar Demo";
             FONT oFont ;
             AT 0, 0 SIZE 700, 425 ;
             STYLE DS_CENTER + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU ;
             ON EXIT {||Iif(oBar==Nil,.T.,(oBar:Close(),.T.))}

             @ 380, 395 BUTTON 'Step Bar'   SIZE 75,25 ON CLICK {|| n+=10,Iif(oBar==Nil,hwg_Msgstop(cMsgErr),oBar:Set(,n/100)) }
             @ 460, 395 BUTTON 'Create Bar' SIZE 75,25 ON CLICK {|| oBar := HProgressBar():NewBox( "Testing ...",,,,, 10, 100 ) }
             @ 540, 395 BUTTON 'Close Bar'  SIZE 75,25 ON CLICK {|| Iif(oBar==Nil,hwg_Msgstop(cMsgErr),(oBar:Close(),oBar:=Nil)) }
             @ 620, 395 BUTTON 'Close'      SIZE 75,25 ON CLICK {|| oForm:Close() }

        ACTIVATE DIALOG oForm

Return Nil


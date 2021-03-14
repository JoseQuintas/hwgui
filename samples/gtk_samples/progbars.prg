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
 * With extensions by Alain Aupeix 
 * (TNX)
 *
*/

    * Status:
    *  WinAPI   :  Yes ==> other sample
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

/*
  No more parameter when launching, the choice is made in Demo menu
  Four choices:
  - External manual progbar
  - External automatic progbar
  - Internal manual progbar
  - Internal automatic progbar
*/


#include "hwgui.ch"

memvar n, cMsgErr, isdemo
Static oMain, oForm, oFont, oBar := Nil

// ============================================================================
Function Main()
// ============================================================================

public isdemo:=.f.

        INIT WINDOW oMain MAIN TITLE "Progress Bar Sample" ;
        SIZE 300, 100 AT 0,0

/*
  iif(!isdemo,(isdemo=.t.,Test("AutoInt")),"")
  causes 
  Warning W0027  Meaningless use of expression 'Logical'
*/
        MENU OF oMain
         MENU TITLE "&Exit"
             MENUITEM "&Quit" ACTION oMain:Close()
         ENDMENU
         MENU TITLE "&Demo"
            MENUITEM "Manual &External progbar" ACTION _ISDEMO("ManExt")
            MENUITEM "&Automatic External progbar" ACTION _ISDEMO("AutoExt")
            SEPARATOR
            MENUITEM "Manual &Internal progbar" ACTION _ISDEMO("ManInt")
            MENUITEM "Aut&omatic Internal progbar" ACTION _ISDEMO("AutoInt")
         ENDMENU
        ENDMENU

        ACTIVATE WINDOW oMain && MAXIMIZED && DF7BE: Progbar is otherwise hidden.

Return Nil


FUNCTION _ISDEMO(ctext)
 IF ! isdemo
  isdemo = .T.
 ELSE
  Test(ctext)
 ENDIF
RETURN ""

// ============================================================================
Function Test(included)
// ============================================================================
local oTimer, oCreate
Public cMsgErr := "Bar doesn't exist"
public n :=0

/*
progbars.prg(102) Warning W0027  Meaningless use of expression 'String'
progbars.prg(123) Warning W0027  Meaningless use of expression 'Logical'
progbars.prg(127) Warning W0027  Meaningless use of expression 'String'
progbars.prg(130) Warning W0027  Meaningless use of expression 'String'

 use iif(<condition>,<action if true>, )
                                      ^ let empty
*/

        PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

        INIT DIALOG oForm CLIPPER NOEXIT TITLE "Progress Bar Demo";
             FONT oFont ;
             AT 200, 200 SIZE 200, 200 ;
             STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU ;
             ON EXIT {||Iif(oBar==Nil,.T.,(oBar:Close(),.T.))}

             do case
                case included == NIL .or. included == "ManExt" .or.included == "AutoExt"
                     @ 290, 395 BUTTON oCreate CAPTION 'Create Bar' SIZE 85,25 ;
                        ON CLICK {|| oBar := HProgressBar():NewBox( "Testing ...",,,,, 20, 100 ),iif(included == "AutoExt",SetTimer(oForm,@oTimer),),oCreate:hide()}
                     * Attention !
                     * To bypass the hidden toolbar, use wmctrl to place the toolbar on top ...
                     * sudo apt install wmctrl
                     * Next advise no more possible, because after creating progbar, oCreate is hidden 
                     * Do not Create a second progress bar. Close recent Progbar before creating a new one.
                case included == "ManInt" .or. included == "AutoInt" 
                     @ 150,110 say "Testing ..." SIZE 200,32
                     @ 150,150 PROGRESSBAR oBar SIZE 100, 20 BARWIDTH 10 QUANTITY 100
                     @ 290, 395 BUTTON oCreate CAPTION 'Create Bar' SIZE 85,25 ;
                       ON CLICK {||oBar:show(),oCreate:hide(),iif(included == "AutoInt",SetTimer(oForm,@oTimer),"")}
                     oCreate:hide()
                     if included == "AutoInt"
                        SetTimer(oForm,@oTimer)
                     endif
             endcase

             @ 380, 395 BUTTON 'Step Bar'   SIZE 75,25 ;
                ON CLICK {|| n+=100,Iif(oBar==Nil,hwg_Msgstop(cMsgErr),oBar:Set(,n/100)),hb_run("wmctrl -a 'Testing ...'"),iif(n/100 == 100,RES_PROGBAR ( obar ), ) }

             @ 460, 395 BUTTON 'Reset Bar'   SIZE 75,25 ;
                ON CLICK {|| IIF(oBar == NIL , , RES_PROGBAR(oBar) ) , n:=0 }
             // IIF(oBar == NIL , .T. , RES_PROGBAR(oBar) )

             if right(included,3) == "Ext"
                @ 540, 395 BUTTON 'Close Bar'  SIZE 75,25 ;
                   ON CLICK {|| Iif(oBar==Nil,hwg_Msgstop(cMsgErr),(iif(left(included,4)== "Auto",oTimer:End(), ),oBar:close(),oBar:=Nil,n:=0,oCreate:show())) }
             else
                @ 540, 395 BUTTON 'Close Bar'  SIZE 75,25 ;
                   ON CLICK {|| Iif(oBar==Nil,hwg_Msgstop(cMsgErr),(iif(left(included,4)== "Auto",oTimer:End(), ),RES_PROGBAR(oBar),oBar:hide(),n:=0,oCreate:show())) }
             endif
             @ 620, 395 BUTTON 'Close'      SIZE 75,25 ON CLICK {|| isdemo:=.f.,oForm:Close() }

        ACTIVATE DIALOG oForm
        if left(included,4)== "Auto"
           oTimer:End()
        endif

Return Nil


// ============================================================================
FUNCTION RES_PROGBAR ( opbar )
// ============================================================================

 n := 0
 opBar:Reset()
 * opBar:Set(,0 )

 hb_run("wmctrl -a 'Testing ...'")

RETURN .F. 

// ============================================================================
Static Function SetTimer( oDlg,oTimer )
// ============================================================================

SET TIMER oTimer OF oDlg VALUE 1000 ACTION {||TimerFunc()}

Return Nil

// ============================================================================
Static Function TimerFunc()
// ============================================================================

n+=100
if oBar==Nil
   hwg_Msgstop(cMsgErr)
else
   oBar:Set(,n/100)
   hb_run("wmctrl -a 'Testing ...'")
   if n/100 == 100
      RES_PROGBAR ( obar )
   endif
endif   

Return Nil

* ====================== EOF of progbars.prg ========================

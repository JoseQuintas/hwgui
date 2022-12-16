/*
 * $Id$
 * 
 * Copyright 2022 Alain Aupeix <alain.aupeix@wanadoo.fr>
 * www - http://jujuland.pagesperso-orange.fr/
 *
 * Support ticket #54 Tooltip for tabs ?
 *
*/

#include "hwgui.ch"

memvar oMainWindow
// ============================================================================
function Main()
// ============================================================================
local oTab, oToolbar, cTooltip1:="This is the first tab"

#ifdef __GTK__
local cTooltip2:="This is the second tab"  + CHR(10) + "Second line"
#else
* Multiline tooltip not allowed on WinAPI, CR or CR+LF ignored
local cTooltip2:="This is the second tab"
#endif

local oButton, oButton1, oButton2 ,oget1 , cget1, oget2 , cget2

#ifndef __GTK__
 local bquitter
#endif 

public oMainWindow

INIT WINDOW oMainWindow MAIN TITLE "Test tabs with tooltip" AT 168,50 SIZE 400,240 BACKCOLOR hwg_ColorC2N("#DCDAFF")

  // Toolbar
  @ 0,0 PANEL oToolbar SIZE 0,32

#ifdef __GTK__
  @ 2,3 BUTTON oButton  CAPTION "Quit";
        ON CLICK {|| Quitter()} ;
        SIZE 40,24 ;
        COLOR hwg_ColorC2N("#FF0000") Tooltip "Quit ?"

#else
  * "OF oToolbar" needed, because the toolbar blocks the button actions  
  @ 2,3 BUTTON oButton  CAPTION "Quit";
        OF oToolbar ;
        ON CLICK {|| bquitter := Quitter() , IIF (bquitter , oMainWindow:Close() , .F. ) } ;
        SIZE 40,24 ;
        COLOR hwg_ColorC2N("#FF0000") Tooltip "Quit ?"

#endif

  @ 10, 35 TAB oTab ITEMS {} SIZE 380, 190

  BEGIN PAGE "Tab 1" of oTab  Tooltip cTooltip1
        @ 20,50 SAY "This is the tab 1" SIZE 100,22
        @ 20,70 GET oget1 VAR cget1 SIZE 100,22 TOOLTIP "Tooltip of GET1"
        @ 200,30 BUTTON oButton1 CAPTION "Button 1" TOOLTIP "Tooltip of BUTTON1"        
  END PAGE of oTab


  BEGIN PAGE "Tab 2" of oTab Tooltip cTooltip2 
        @ 20,50 SAY "This is the tab 2" SIZE 100,22
        @ 20,70 GET oget2 VAR cget2 SIZE 100,22 TOOLTIP "Tooltip of GET2"
        @ 200,30 BUTTON oButton2 CAPTION "Button 2" TOOLTIP "Tooltip of BUTTON2"
  END PAGE of oTab

#ifndef __GTK__
* On WinAPI, the correct tooltip must be synchronized with the shown first tab
* at program start.  
  oTab:ChangePage(1)
#endif  

ACTIVATE WINDOW oMainWindow

return nil

// ============================================================================
function Quitter()
// ============================================================================
local oDlg, oFont := HFont():Add( "Serif",0,-13 )
local bquit

bquit := .F.

INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Quit" AT oMainWindow:nLeft+250,oMainWindow:nTop+130  SIZE 210,90 ;
        FONT oFont

@ 40,10 SAY "Do you want to quit ?" SIZE 150, 22 COLOR hwg_ColorC2N("0000FF")

#ifdef __GTK__
* This has no effect on WinAPI, the program does not quit !
@ 30,40 BUTTON hb_i18n_gettext("Quit") OF oDlg ID IDOK  ;
    SIZE 60, 32 COLOR hwg_ColorC2N("FF0000")

@ 110,40 BUTTON hb_i18n_gettext("Cancel") OF oDlg ID IDCANCEL  ;
    SIZE 60, 32 COLOR hwg_ColorC2N("FF0000")
#else
@ 30,40 BUTTON hb_i18n_gettext("Quit") ;
    SIZE 60, 32 COLOR hwg_ColorC2N("FF0000") ;
    ON CLICK {|| bquit := .T. , oDlg:Close()}

@ 110,40 BUTTON hb_i18n_gettext("Cancel") ;
    SIZE 60, 32 COLOR hwg_ColorC2N("FF0000");
    ON CLICK {|| oDlg:Close() }
#endif




ACTIVATE DIALOG oDlg
oFont:Release()
#ifdef __GTK__
if oDlg:lresult
   hwg_EndWindow()
endif
#endif

return bquit

// ============================================================================

* ================================== EOF of Test_tab.prg =========================================



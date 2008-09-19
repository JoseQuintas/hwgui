/*
 *$Id: flashocx.prg,v 1.1 2008-09-19 19:55:48 sandrorrfreire Exp $
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 * flashocx.prg - sample of ActiveX container for the Acrobat Reader ocx
 *
 *
 * Copyright 2006 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Sample code derived from a sample code found on Internet.... oohg ?
 *
 */

#include "hwgui.ch"
#include "rmchart.ch"
#include "hbclass.ch"

Function Main
Local oMainWnd, oPanel
Local mypath := curdrive()+":\" + CURDIR() + IIF( EMPTY( CURDIR() ), "", "\" )
Private oFlash

   INIT WINDOW oMainWnd TITLE "FlashPlayer example" AT 200,0 SIZE 500,400

   MENU OF oMainWnd
      MENU TITLE "File"
         MENUITEM "E&xit" ACTION oMainWnd:Close()
      ENDMENU
   ENDMENU

   @ 0,0 PANEL oPanel SIZE 500,366 ON SIZE {|o,x, y| o:Move(,,x,y)}

   oFlash := FlashPlayer( oPanel, mypath+"mma.swf", 0, 0, 500, 366 )

   ACTIVATE WINDOW oMainWnd

Return

CLASS ShockwaveFlash FROM HActiveX
CLASS VAR winclass INIT "ShockwaveFlash"
  METHOD New()
ENDCLASS


METHOD New(p1,p2,p3,p4,p5,p6) CLASS ShockwaveFlash
  Super:New(p1,p2,p3,p4,p5,p6)
RETURN

function FlashPlayer(oWindow, cFlashFile, col, row, nHeight, nWidth)
    local oFlash

    oFlash := ShockwaveFlash():New( oWindow, "ShockwaveFlash.ShockwaveFlash.1", 0, 0, nHeight, nWidth )
    oFlash:LoadMovie(0,cFlashFile)

    return oFlash


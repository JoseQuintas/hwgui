/*
 * $Id$
 *
 * GTHWG, Video subsystem, based on HwGUI
 *
 * test1.prg - simple test program
 *
 * Copyright 2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hbgtinfo.ch"

FUNCTION Main

   LOCAL nKey, nh, nw
   LOCAL cLogin := Space( 16 )

   ANNOUNCE HB_GTSYS
   REQUEST HB_GT_HWGUI
   REQUEST HB_GT_HWGUI_DEFAULT

   REQUEST HB_CODEPAGE_RU866
   REQUEST HB_CODEPAGE_UTF8

   SET SCORE OFF
   hb_cdpSelect( "RU866" )

   CreateWindow()

   //SetMode( 30,90 )
   nw := hb_gtinfo( HB_GTI_DESKTOPWIDTH ) - 20
   nh := hb_gtinfo( HB_GTI_DESKTOPHEIGHT ) - 84
   hb_gtinfo( HB_GTI_FONTWIDTH, Int( nw / 80 ) )
   hb_gtinfo( HB_GTI_FONTSIZE, Int( nh / 25 ) )
   //hwg_writelog( "gt: " + hb_gtVersion() + " " + hwg_version() )

   SetColor( "W+/B" )
   clear screen
   @ 0, 0, 24, 79 BOX "******** "
   @ 4,5 SAY "Test"
   @ 23,1 SAY "---- " + Str( hb_gtinfo( HB_GTI_DESKTOPROWS ) )
   @ 23,70 SAY "----"
   @ 24,1 SAY "===="
   @ 24,70 SAY "===="
   @ 3,5 SAY "‚Ά¥¤¨β¥ β¥ªαβ:" GET cLogin
   READ

   hwg_writelog( "Login: " + cLogin )

   nKey := Inkey( 5 )
   hwg_writelog( "Key " + Str( nKey ) )
   gthwg_CloseWindow()

   RETURN Nil

#include "hwgui.ch"

STATIC FUNCTION CreateWindow()

   LOCAL oWnd := gthwg_CreateMainWindow( "GT HwGUI Test" )

   MENU OF oWnd
      MENU TITLE "&File"
         MENUITEM "&New" ACTION hwg_MsgInfo( "New!" )
         SEPARATOR
         MENUITEM "&Exit" ACTION oWnd:Close()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION hwg_MsgInfo( hwg_version()+Chr(13)+Chr(10)+"gt: " + hb_gtVersion(),"About" )
      ENDMENU
   ENDMENU

   RETURN oWnd

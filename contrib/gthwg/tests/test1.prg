/*
 * $Id$
 *
 * GTHWG, Video subsystem, based on HwGUI
 *
 * test1.prg - simple test program
 *
 * Copyright 2021 - 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

REQUEST HB_GT_HWGUI
REQUEST HB_GT_HWGUI_DEFAULT

REQUEST HB_CODEPAGE_RU866
REQUEST HB_CODEPAGE_UTF8

#include "hbgtinfo.ch"

STATIC shadow1

FUNCTION Main( _par1 )

   LOCAL choice, frame, nw, nh

   ( _par1 )
   SET DATE BRITISH
   SET WRAP ON
   SET SCORE OFF
   hb_cdpSelect( "RU866" )

   CreateWindow()

   SetMode( 30,100 )
   nw := Min( 1920, hb_gtinfo( HB_GTI_DESKTOPWIDTH ) ) - 20
   nh := Min( 1080, hb_gtinfo( HB_GTI_DESKTOPHEIGHT ) ) - 84
   hb_gtinfo( HB_GTI_FONTWIDTH, Int( nw / ( MaxCol() + 1 ) ) )
   hb_gtinfo( HB_GTI_FONTSIZE, Int( nh / ( MaxRow() + 1 ) ) )

   frame   := Replicate( Chr( 219 ), 9 )
   shadow1 := Replicate( Chr( 220 ), 9 )

   choice := 1
   DO WHILE choice != 3 .AND. choice != 0
      SET COLOR TO N+/N
      @  0,  0, 29, 99 BOX frame
      @  2,  7, 2, 30 BOX shadow1
      @  1, 30 SAY Chr( 223 )
      @  4,  7, 4, 30 BOX shadow1
      @  3, 30 SAY Chr( 223 )
      @  6,  7, 6, 30 BOX shadow1
      @  5, 30 SAY Chr( 223 )
      DO ZAGOL
      SET COLOR TO B/W,+GR/B
      @ 01, 06 PROMPT "   GET SYSTEM DIALOG    "
      @ 03, 06 PROMPT "    SHOW SCREEN INFO    "
      @ 05, 06 PROMPT "        E X I T         "
      MENU TO choice

      DO CASE
      CASE choice = 1
         DO PGM1
      CASE choice = 2
         DO PGM2
      ENDCASE
   ENDDO

   SET COLOR TO W/N
   @  0,  0 CLEAR TO 29, 99

   gthwg_CloseWindow()

   RETURN Nil

STATIC PROCEDURE ZAGOL

   DO SHADOW WITH 04, 63, 13, 94
   SET COLOR TO +GR/B
   @  4, 63 CLEAR TO 13, 94
   @  4, 63 TO 13, 94
   @  5, 70 SAY "GTHWGUI DEMO PROGRAM"
   @  6, 75 SAY "Version 1.1"
   @ 09, 64 TO 09, 93
   SET COLOR TO +RB/B

   RETURN

STATIC PROCEDURE SHADOW( y1, x1, y2, x2 )

   SET COLOR TO N+/N
   @ y2 + 1, x1 + 1, y2 + 1, x2 + 1 BOX shadow1
   @ y1 + 1, x2 + 1 CLEAR TO y2, x2 + 1
   @ y1, x2 + 1 SAY Chr( 223 )

   RETURN

STATIC PROCEDURE PGM1

   LOCAL bufsc := SaveScreen( 6, 10, 14, 74 )
   LOCAL x1, x2, x3, GetList := {}

   @ 6, 10 CLEAR TO 14, 74
   @ 6, 10 TO 14,74

   gthwg_PaintCB( , "../../../image/hwgui.bmp" )

   x1 := x2 := x3 := Space( 32 )
   @  8, 12  SAY "1:" GET x1
   @  10, 12 SAY "2:" GET x2
   @  12, 12 SAY "3:" GET x3
   READ

   gthwg_PaintCB()
   RestScreen( 6, 10, 14, 74, bufsc )

   RETURN

STATIC PROCEDURE PGM2

   LOCAL bufsc := SaveScreen( 6, 20, 15, 44 )

   @ 6, 20 CLEAR TO 15, 44
   @ 6, 20 TO 15, 44

   @  08, 22 SAY "Rows: " + Ltrim( Str( MaxRow() ) )
   @  09, 22 SAY "Cols: " + Ltrim( Str( MaxCol() ) )
   @  10, 22 SAY "Height: " + Ltrim( Str( hb_gtinfo( HB_GTI_SCREENHEIGHT ) ) )
   @  11, 22 SAY "Width: " + Ltrim( Str( hb_gtinfo( HB_GTI_SCREENWIDTH ) ) )
   @  13, 22 SAY "Press any key"
   Inkey(0)

   RestScreen( 6, 20, 15, 44, bufsc )

   RETURN

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

FUNCTION gthwg_PaintCB( hDC, cFileName )

   LOCAL aBmpSize
   STATIC hImage, img_x1, img_y1, img_width, img_height

   IF Empty( hDC )
      IF Empty( cFileName )
         gthwg_paint_SetCallback()
         IF !Empty( hImage )
            hwg_Deleteobject( hImage )
            hImage := Nil
         ENDIF
      ELSE
         hImage := hwg_OpenImage( cFileName )
         IF !Empty( hImage )
            img_x1 := Int( hb_gtinfo( HB_GTI_SCREENWIDTH ) / MaxCol() ) * 50
            img_y1 := Int( hb_gtinfo( HB_GTI_SCREENHEIGHT ) / MaxRow() ) * 8
            aBmpSize  := hwg_Getbitmapsize( hImage )
            img_width := aBmpSize[ 1 ]
            img_height := aBmpSize[ 2 ]
            gthwg_paint_SetCallback( "GTHWG_PAINTCB" )
            hwg_Invalidaterect( hb_gtinfo(HB_GTI_WINHANDLE), 0 )
         ENDIF
      ENDIF
   ELSEIF !Empty( hImage )
      hwg_Drawbitmap( hDC, hImage,, img_x1, img_y1, img_width, img_height )
   ENDIF

   RETURN Nil

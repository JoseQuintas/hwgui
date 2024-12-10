/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  stretch.prg
 *
 * Sample for resizing bitmaps (background)
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 *
 * TNX to Itamar M. Lins Jr.
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

* Tiled: In German "gekachelt"

#include "hwgui.ch"
// #ifdef __GTK__
// #include "gtk.ch"
// #endif

FUNCTION Main( lStretch )

   LOCAL oFormMain
   LOCAL nPosX
   LOCAL nPosY
   LOCAL oQuitButton
   LOCAL oBitmap
   LOCAL oBmp

   LOCAL cDirSep := hb_PS() //PATH SEPARATOR
   LOCAL cImagePath := ".." + cDirSep + "image" + cDirSep
   LOCAL cImageMain := cImagePath + "hwgui.bmp"

   CHECK_FILE( cImageMain )


   // oBmp := HBitmap():AddFile(cImageMain,,.F.,hwg_Getdesktopwidth(),hwg_Getdesktopheight()-21)
   oBmp := HBitmap():AddFile( cImageMain,, .F., 301, 160 )
   * 301 x 160 is the original size of the bitmap image.

   // hwg_deb_is_object(oBmp) && Debug

   // Here default is resized image
   // But works only with WinAPI, not GTK.

   nPosX := hwg_Getdesktopwidth()
   nPosY := hwg_Getdesktopheight()

   lStretch := IIF( lStretch == NIL, lStretch := .T.,lStretch := .F.)

   * Display size of recent desktop, it is equal to the size of screen.
   hwg_msginfo("X=" + STR(nPosX) + CHR(10) + "Y=" + STR(nPosY) + CHR(10) + ;
      "lStretch=" + IIF(lStretch,"True","False") )

   IF lStretch
      INIT WINDOW oFormMain MAIN AT 0,0 SIZE nPosX , nPosY

      @ 110,0 BITMAP oBitmap  SHOW oBmp OF oFormMain ;
         SIZE nPosX - 10, nPosY - 100 // Here resize of background image (stretch)
         // 301, 160

      // Attention !
      // The button may not positioned into the image, otherwise
      // the ON CLICK block does not work.
      // Say "0,0 BITMAP oBitmap" and you can realize the symptom.

      @ 25,25 BUTTON oQuitButton CAPTION "Exit" SIZE 75,32 ;
         ON CLICK { | | oFormMain:Close() }

      oFormMain:Activate()

   ELSE
      INIT WINDOW oFormMain APPNAME "Agenda Hwgui" MAIN AT 0,0 SIZE nPosX,nPosY BACKGROUND BITMAP oBmp
      // Tiled: Side by side, not stretch
      // If the Button is here inside the background image, the
      // ON CLICK block works fine.

      @ 25,25 BUTTON oQuitButton CAPTION "Exit" SIZE 75,32 ;
      ON CLICK { | | oFormMain:Close() }

      oFormMain:Activate()
   ENDIF

RETURN Nil


FUNCTION CHECK_FILE ( cfi )

   * Check, if file exist, otherwise terminate program
   IF .NOT. FILE( cfi )
      Hwg_MsgStop("File >" + cfi + "< not found, program terminated","File ERROR !")
      QUIT
   ENDIF

RETURN Nil

* ==================== EOF of stretch.prg ============

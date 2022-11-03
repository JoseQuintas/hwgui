 *
 * qrencode.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *
 * Sample program for QR encoding and
 * converts its output to 
 * monochrome bitmaps for multi platform usage.
 *
 * Copyright 2022 Wilfried Brunken, DF7BE 
 * https://sourceforge.net/projects/cllog/

 
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

* <under construction>

#include "hwgui.ch"

FUNCTION Main()

LOCAL oMainWindow, oButton1, oButton2

INIT WINDOW oMainWindow MAIN TITLE "Creating QR code" AT 168,50 SIZE 250,150

  @ 20,50 BUTTON oButton1 CAPTION "Test";
        ON CLICK {|| Testen()} ;
        SIZE 80,32

  @ 120,50 BUTTON oButton2 CAPTION "Quit";
        ON CLICK {|| oMainWindow:Close } ;
        SIZE 80,32

ACTIVATE WINDOW oMainWindow

RETURN NIL



* Ask for string to convert, zoom factor and 
* store to bitmap file
* Convert to bitmap and show the qrcode,
* Store the QR code to bitmap file "test.bmp 
FUNCTION Testen()

LOCAL cqrc, cbitmap

// cqrc := hwg_QRCodeTxtGen("https://www.darc.de",1)

cqrc := hwg_QRCodeTxtGen("https://sourceforge.net/projects/hwgui",1)


cqrc := hwg_QRCodeZoom(cqrc,3)

// cqrc := hwg_QRCodeZoom_C(cqrc,LEN(cqrc),3)

hwg_WriteLog(cqrc)

cbitmap := hwg_QRCodetxt2BPM(cqrc)

* Store to bitmap file
MEMOWRIT("test.bmp",cbitmap)

* And show the new bitmap image
hwg_ShowBitmap(cbitmap,"test",0,hwg_ColorC2N("080808") ) // Color = 526344

RETURN NIL


*  ================== EOF of qrencode.prg ======================
 

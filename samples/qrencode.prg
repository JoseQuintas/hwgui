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
 * The created bitmap with the QR code is displayed in
 * a extra windows and also written in file 
 * "test.bmp"
 * and under construction:
 * "qr-code.bmp"
 *
 * Copyright 2025 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/


    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No
    *  MacOS:Yes    


#include "hwgui.ch"
#include "hbextcdp.ch"

FUNCTION Main()

   LOCAL oMainWindow, oButton1, oButton2

   INIT WINDOW oMainWindow MAIN TITLE "Creating QR code" AT 168,50 SIZE 250,150

   @ 20,50 BUTTON oButton1 CAPTION "Test" ;
      ON CLICK { || Testen() } ;
      SIZE 80,32

   @ 120,50 BUTTON oButton2 CAPTION "Quit";
      ON CLICK { || oMainWindow:Close } ;
      SIZE 80,32

   ACTIVATE WINDOW oMainWindow

RETURN Nil

* Ask for string to convert, zoom factor and
* store to bitmap file
* Convert to bitmap and show the qrcode,
* Store the QR code to bitmap file "test.bmp

FUNCTION Testen()

*
* All steps of generating a QR code from string
* are collected in one function:
*   HB_QRENDCODE(ctext,cbitmapfile,nzoomf)
* 
* Copy it from
*  contrib\qrencode\libqrcode_hb.prg
* and insert into your HWGUI program.
* In the comment lines the parameters are there described, too.
*  

   LOCAL cqrc, cbitmap , narrsize

   // cqrc := hwg_QRCodeTxtGen("https://www.darc.de",1)

   cqrc := hwg_QRCodeTxtGen( "https://sourceforge.net/projects/hwgui", 1 )


   cqrc := hwg_QRCodeZoom( cqrc, 3 )

   // cqrc := hwg_QRCodeZoom_C(cqrc,LEN(cqrc),3)
  
  
   * Add border 10 pixels
   cqrc := hwg_QRCodeAddBorder(cqrc,10)
   
   * Get size of QR code and display it
   narrsize := hwg_QRCodeGetSize(cqrc)

   hwg_MsgInfo("x=" + ALLTRIM(STR(narrsize[1])) + " y=" +  ;
   ALLTRIM(STR(narrsize[2])),"Size of QR code")

   hwg_WriteLog( cqrc )

   cbitmap := hwg_QRCodetxt2BPM( cqrc )

   * Store to bitmap file
   MEMOWRIT( "test.bmp", cbitmap )
   
   * <under construction>
   // TO-DO: extend with conversion to bitmap object.
   // hwg_oBitmap2file(cbitmap,"qr-code.bmp")

   * And show the new bitmap image
   hwg_ShowBitmap( cbitmap, "test", 0, hwg_ColorC2N( "080808" ) ) // Color = 526344

RETURN Nil

 

*  ================== EOF of qrencode.prg ======================

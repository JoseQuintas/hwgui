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
    *  MacOS    :  Yes    


#include "hwgui.ch"
#include "hbextcdp.ch"

FUNCTION Main()

   LOCAL oMainWindow, oButton1, oButton2

   INIT WINDOW oMainWindow MAIN TITLE "Creating QR code" AT 168,50 SIZE 250,150


  * First run
  * Testen()
  * Second run (optional)

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
* First run
FIRST_RUN()
SECOND_RUN()
RETURN NIL



FUNCTION FIRST_RUN()

*
* All steps of generating a QR code from string
* are collected in one function:
*   HWG_QRENCODE(ctext,nzoomf)
   LOCAL  cbitmap, narrsize 

    
   cbitmap  := HWG_QRENCODE("https://sourceforge.net/projects/hwgui/")
   
   // QR_Size_Disp(cbitmap)  && here 0,0
   
   // hwg_WriteLog( cbitmap )
   // cqrc := hwg_QRCodeZoom_C(cqrc,LEN(cqrc),3)
   
  * Store to bitmap file
   // MEMOWRIT( "test.bmp", cbitmap )
   hwg_CBmp2file(cbitmap,"test.bmp")
   
   * <under construction>
   // TO-DO: extend with conversion to bitmap object.
   // hwg_oBitmap2file(cbitmap,"qr-code.bmp")

   * And show the new bitmap image
   hwg_ShowBitmap( cbitmap, "test", 0, hwg_ColorC2N( "080808" ) ) // Color = 526344

RETURN Nil

 FUNCTION QR_Size_Disp(cbitmap)
   * Get size of QR code and display it
 
   LOCAL narrsize
 
   narrsize := hwg_QRCodeGetSize(cbitmap)

   hwg_MsgInfo("x=" + ALLTRIM(STR(narrsize[1])) + " y=" +  ;
   ALLTRIM(STR(narrsize[2])),"Size of QR code")
RETURN NIL 


FUNCTION SECOND_RUN()

   LOCAL cqrc, cbitmap 

   // cqrc := hwg_QRCodeTxtGen("https://www.darc.de",1)

   cqrc := hwg_QRCodeTxtGen( "https://sourceforge.net/projects/hwgui", 1 )


   cqrc := hwg_QRCodeZoom( cqrc, 3 )

   // cqrc := hwg_QRCodeZoom_C(cqrc,LEN(cqrc),3)
  
  
   * Add border
   cqrc := hwg_QRCodeAddBorder(cqrc,10)
   
   * Get size of QR code and display it
   // narrsize := hwg_QRCodeGetSize(cqrc)
   // Now in this function
    QR_Size_Disp(cqrc)
    
   // Size should be x=126 y=125 

   // hwg_WriteLog( cqrc )

   * Finally convert QR code text image to bitmap binary image as type C
   cbitmap := hwg_QRCodetxt2BPM( cqrc )

   * Store to bitmap file
   MEMOWRIT( "test.bmp", cbitmap )
   * Attention !
   * The MEMOWRIT() function add an EOF marker at end of file
   * 0x1a = CHR(26)
   
   * <under construction>
   // TO-DO: extend with conversion to bitmap object.
   // hwg_oBitmap2file(cbitmap,"qr-code.bmp")

   * And show the new bitmap image
   hwg_ShowBitmap( cbitmap, "test", 0, hwg_ColorC2N( "080808" ) ) // Color = 526344


RETURN NIL

* DF7BE:
* Here DO:
* After calling hwg_QRCodetxt2BPM() the 
* size getting with hwg_QRCodeGetSize() returns 0,0
* (is now binary format of bitmap)

*  ================== EOF of qrencode.prg ======================

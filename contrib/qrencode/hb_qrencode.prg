*
* hb_qrencode.prg
*
*
* $Id$
*
* Sample program creating QR codes by Harbour console program
* (for example to create QR codes by bat or sh calls)
* using functions of HWGUI.
* 
*
* Compile with:
* hbmk2 hb_qrencode.hbp

#include "hbextcdp.ch"

FUNCTION MAIN(ctext,cbitmapfile,czoomf)

LOCAL nzoomf

* Set "_DE858" to your language setting on Windows
// REQUEST HB_CODEPAGE_DEWIN
// REQUEST HB_CODEPAGE_CP1251
REQUEST HB_CODEPAGE_DE858
REQUEST HB_CODEPAGE_UTF8
#ifndef __PLATFORM__WINDOWS
REQUEST HB_CODEPAGE_UTF8EX
#endif 

  IF ( ctext == NIL ) .OR.  (cbitmapfile == NIL)
    ? "Usage: hb_qrencode <text convert to QR code> , "  + ;
     "<bitmap file name with QRcode, add extension " + CHR(34) + ".bmp" + CHR(34) + "> " + ;
     "[,<zoom factor>]"
    ? "Default value for zoom factor is 3"
    RETURN 1
  ENDIF 
  
  IF czoomf == NIL
   nzoomf := 3
  ELSE
   nzoomf := VAL(czoomf)
  ENDIF 
 
  HB_QRENDCODE(ctext,cbitmapfile,nzoomf)

 QUIT

RETURN 0 



* =============== EOF of hb_qrencode.prg =========================
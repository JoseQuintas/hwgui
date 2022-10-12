*
* testbmpcr.prg
*

#include "hwgui.ch"

FUNCTION Main()

LOCAL oMainWindow, oButton1, oButton2

INIT WINDOW oMainWindow MAIN TITLE "Test creating bitmap file" AT 168,50 SIZE 250,150

  @ 20,50 BUTTON oButton1 CAPTION "Test";
        ON CLICK {|| Testen()} ;
        SIZE 80,32

  @ 120,50 BUTTON oButton2 CAPTION "Quit";
        ON CLICK {|| oMainWindow:Close } ;
        SIZE 80,32

ACTIVATE WINDOW oMainWindow

RETURN NIL

FUNCTION Testen()

LOCAL CBMP , nfilesiz ,rc , lrc , cmsg , noffset , npoffset
LOCAL CBMP2 , cdirsep
LOCAL ctest

cdirsep := hwg_GetDirSep()

nfilesiz := HWG_BMPFILESIZE(48, 48, 1, 2)

// hwg_msgInfo("sizeof(BMPImage3x) is " + ALLTRIM(STR(HWG_BMPSZ3X() )) )

// hwg_msgInfo("Filesize is " + ALLTRIM(STR(nfilesiz)) )

* Create the bitmap template string.
* This is the default for QR encoding:
*
*                        (x) width
*                        !  (y) height
*                        !  !   bits per pixel
*                        !  !   !
*                        !  !   !  colors (2 = monochrome bitmap)
*                        !  !   !  !  x pixel per meter 
*                        !  !   !  !  !
*                        !  !   !  !  !     y pixel per meter
*                        !  !   !  !  !     ! 
*                        v  v   v  v  v     v
CBMP := HWG_BMPNEWIMAGE(48, 48, 1, 2, 2835, 2835 )
* The x and y size can be modified by size of QR code.
*
* After creating the bitmap template string,
* free not used memory:
HWG_BMPDESTROY()



noffset := hwg_BMPCalcOffsPixArr(2);

// hwg_msgInfo("Offset to pixel data is " + ALLTRIM(STR(noffset)), "Expected value: 62" )


* Set monochrome palette for QR encoding,
* The background is white.
* (2 colors, black and white)
* Set 55, 56, 57 to 0xFF
* Define color 0 as white (the color 1 now is black by default)
npoffset := HWG_BMPCALCOFFSPAL()
* Start with 55 : Add 1 to palette offset
CBMP := hwg_ChangeCharInString(CBMP,npoffset + 1 , CHR(255) )
CBMP := hwg_ChangeCharInString(CBMP,npoffset + 2 , CHR(255) )
CBMP := hwg_ChangeCharInString(CBMP,npoffset + 3 , CHR(255) )


// hwg_msgInfo("Offset to palette data is " + ALLTRIM(STR(npoffset)), "Expected value: 54" )

* Setting example pixels:

* Pixel data of image, index
* y , x
*
* y = 0 bottom, x = 0 left


* Some tests
* 0x101 = 257 + 1,  0x80 = 128
CBMP := hwg_ChangeCharInString(CBMP,258,CHR(128) )  // center point

* Add 1 to pixel data offset
CBMP := hwg_ChangeCharInString(CBMP,noffset+1,CHR(170) )
CBMP := hwg_ChangeCharInString(CBMP,noffset+1+48,CHR(170) )



* MEMOWRIT("hexdump.txt",hwg_HEX_DUMP (CBMP, 1) )
MEMOWRIT("test.bmp",CBMP)
* EOF mark 0x1A = CHR(26) is added by MEMOWRIT,
* it seems, that this has no negative effect.

hwg_ShowBitmap(CBMP,"test",0,hwg_ColorC2N("080808") ) // Color = 526344

CBMP2 := MEMOREAD(".." + cdirsep + "image" + cdirsep + "astro.bmp")
 hwg_ShowBitmap(CBMP2,"astro")

* Test for setting bits in a byte
 hwg_msgInfo(hwg_hex2binchar(hwg_HEX_DUMP(CHR(HWG_SETBITBYTE(0,8,1)), 4 ) ) )  && OK 0 to 1
 hwg_msgInfo(hwg_hex2binchar(hwg_HEX_DUMP(CHR(HWG_SETBITBYTE(255,8,0)), 4 ) ) ) && OK 1 to 0

RETURN NIL

/*
FUNCTION hwg_QR_SetPixel(x,y,xw,xh)
LOCAL nposi

nposi := 

RETURN NIL
*/

/*
FUNCTION hwg_QR_PixelPos(x,y,xw,xh)
* Calculates the the pixel position in the
* pixel data jagged array at position x,y.
* xw: width
* xh: heigth
* Pass these values same as HWG_BMPNEWIMAGE(x,y, ...)
LOCAL nret, noffset
noffset := hwg_BMPCalcOffsPixArr(2);  && For 2 colors
* y = 0 bottom, x = 0 left, so turn to
* y = 1 top,    x = 1 left
*
x := x + 1
y := xh - ( y - 1 )

RETURN nret
*/





* ===================== EOF of testbmpcr.prg ====================



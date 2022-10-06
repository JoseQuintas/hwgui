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

cdirsep := hwg_GetDirSep()

nfilesiz := HWG_BMPFILESIZE(48, 48, 1, 2)

// hwg_msgInfo("sizeof(BMPImage3x) is " + ALLTRIM(STR(HWG_BMPSZ3X() )) )

// hwg_msgInfo("Filesize is " + ALLTRIM(STR(nfilesiz)) )

CBMP := HWG_BMPNEWIMAGE(48, 48, 1, 2, 2835, 2835 )
HWG_BMPDESTROY()

* Set 55, 56, 57 to 0xFF
* Define color 0 as white (the color 1 is black, default)

noffset := hwg_BMPCalcOffsPixArr(2);

* Expected value: 62
hwg_msgInfo("Offset to pixel data is " + ALLTRIM(STR(noffset)) )

npoffset := HWG_BMPCALCOFFSPAL()
* Start with 55 : Add 1 to palette offset
CBMP := hwg_ChangeCharInString(CBMP,npoffset + 1 , CHR(255) )
CBMP := hwg_ChangeCharInString(CBMP,npoffset + 2 , CHR(255) )
CBMP := hwg_ChangeCharInString(CBMP,npoffset + 3 , CHR(255) )


hwg_msgInfo("Offset to palette data is " + ALLTRIM(STR(npoffset)) )
* Expected value: 54


* 0x101 = 257 + 1,  0x80 = 128
CBMP := hwg_ChangeCharInString(CBMP,258,CHR(128) )  // center point

CBMP := hwg_ChangeCharInString(CBMP,noffset,CHR(170) )

* Pixel data of image, index
* y , x
*
* y = 0 bottom, x = 0 left

* MEMOWRIT("hexdump.txt",hwg_HEX_DUMP (CBMP, 1) )
MEMOWRIT("test.bmp",CBMP)
* EOF mark 0x1A = CHR(26) is added by MEMOWRIT,
* it seems, that this has no negative effect.

hwg_ShowBitmap(CBMP,"test",0,hwg_ColorC2N("080808") ) // 526344

CBMP2 := MEMOREAD(".." + cdirsep + "image" + cdirsep + "astro.bmp")
hwg_ShowBitmap(CBMP2,"astro")

RETURN NIL



* ===================== EOF of testbmpcr.prg ====================



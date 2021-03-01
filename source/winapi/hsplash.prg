/*
 * $Id$
 *
 * HwGUI Harbour Win32 Gui Copyright (c) Alexander Kresin
 *
 * HwGUI HSplash Class
 *
 * Copyright (c) Sandro R. R. Freire <sandrorrfreire@yahoo.com.br>
 *
 */

#include "guilib.ch"
#include "windows.ch"
#include "hbclass.ch"

/* ---- Bugfixing MinGW64 by DF7BE:
With call
gcc -Wall -O3 -DHWG_USE_POINTER_ITEM -c -Iinclude -IC:\harbour64\core-master/include -o obj/hsplash.o obj/hsplash.c
the gcc ended immediately without any error messages nor creating object output file:
The make systems say:
mingw32-make.exe: Interrupt/Exception caught (code = 0xc0000005, addr = 0x00007FFDD11C0BC4)
Need to add #include "hwingui.h" at the BEGINNING of the generated c file.
That not possible.
Build HWGUI only with command:
  hbmk2 hwgui.hbp procmisc.hbp hbxml.hbp hwgdebug.hbp
*/

/*
#pragma BEGINDUMP


#include "hwingui.h"

#pragma ENDDUMP
*/



CLASS HSplash

   DATA oTimer

   METHOD Create( cFile, oTime, oResource ) CONSTRUCTOR
   METHOD CountSeconds( oTime, oDlg )

ENDCLASS

METHOD Create( cFile, oTime, oResource ) CLASS HSplash
   LOCAL aWidth, aHeigth
   LOCAL bitmap, oDlg

   IIf( Empty( oTime ) .or. oTime == Nil, oTime := 2000, oTime := oTime )

   IF oResource == Nil .or. ! oResource
      bitmap  := HBitmap():AddFile( cFile )
   ELSE
      bitmap  := HBitmap():AddResource( cFile )
   ENDIF

   aWidth := bitmap:nWidth
   aHeigth := bitmap:nHeight

   INIT DIALOG oDlg TITLE "" ;
        At 0, 0 SIZE aWidth, aHeigth  STYLE WS_POPUP + DS_CENTER + WS_VISIBLE + WS_DLGFRAME ;
        BACKGROUND bitmap bitmap ON INIT { || ::CountSeconds( oTime, oDlg ) }

   oDlg:Activate()
   ::oTimer:END()

   RETURN Self

METHOD CountSeconds( oTime, oDlg )

   SET TIMER ::oTimer OF oDlg VALUE oTime  ACTION { || hwg_EndDialog( hwg_GetModalHandle() ) }

   RETURN Nil



* ====================== EOF of hsplash.prg =======================

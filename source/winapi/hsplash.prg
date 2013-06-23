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





/*
 * $Id: hsplash.prg,v 1.2 2007-11-26 10:50:17 andijahja Exp $
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

   METHOD Create(cFile,oTime,oResource) CONSTRUCTOR

ENDCLASS
 
METHOD Create(cFile, oTime, oResource ) CLASS HSplash
   local aWidth,aHeigth
   local bitmap, oDlg

   Iif(Empty(oTime) .or. oTime==Nil, oTime:=2000,oTime:=oTime)

   If oResource==Nil .or. !oResource
      bitmap  := HBitmap():AddFile(cFile)
   Else
      bitmap  := HBitmap():AddResource(cFile)
   Endif

   aWidth := bitmap:nWidth
   aHeigth:= bitmap:nHeight
 
   INIT DIALOG oDlg TITLE "" ;
     AT 0,0 SIZE aWidth, aHeigth  STYLE WS_POPUP+DS_CENTER+WS_VISIBLE+WS_DLGFRAME;
     BACKGROUND BITMAP bitmap ON INIT {||CountSeconds(oTime,oDlg)}

    oDlg:Activate()

RETURN Self

Static Function CountSeconds(oTime,oDlg) 
local oTimer

SET TIMER oTimer OF oDlg VALUE oTime  ACTION {||EndDialog(GetModalHandle())}

Return Nil



 

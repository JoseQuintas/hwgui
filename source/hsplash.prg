/*
 * $Id: hsplash.prg,v 1.6 2010-02-18 01:25:18 lfbasso Exp $
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
   DATA oDlg

   METHOD Create( cFile, oTime, oResource, nWidth, nHeight, nStyle ) CONSTRUCTOR
   METHOD CountSeconds( oTime, oDlg )
   METHOD Release() INLINE ::oDlg:Close()   

ENDCLASS

METHOD Create( cFile, oTime, oResource, nWidth, nHeight, nStyle ) CLASS HSplash
   LOCAL aWidth, aHeigth
   LOCAL bitmap

   IIf( Empty( oTime ) .or. oTime == Nil, oTime := 2000, oTime := oTime )

   IF oResource == Nil .or. ! oResource
      bitmap  := HBitmap():AddFile( cFile,,, nWidth, nHeight )
   ELSE
      bitmap  := HBitmap():AddResource( cFile,,, nWidth, nHeight )
   ENDIF

   aWidth := IIF( nWidth = Nil, bitmap:nWidth, nWidth )
   aHeigth := IIF( nHeight = Nil, bitmap:nHeight, nHeight )

   IF nWidth = Nil .OR. nHeight = Nil
      INIT DIALOG ::oDlg TITLE "" ;
        At 0, 0 SIZE aWidth, aHeigth  STYLE WS_POPUP + DS_CENTER + WS_VISIBLE + WS_DLGFRAME ;
        BACKGROUND bitmap bitmap ON INIT { || ::CountSeconds( oTime, ::oDlg ) }
      //oDlg:lBmpCenter := .T.        
   ELSE
      INIT DIALOG ::oDlg TITLE "" ;
        At 0, 0 SIZE aWidth, aHeigth  STYLE WS_POPUP + DS_CENTER + WS_VISIBLE + WS_DLGFRAME ;
        ON INIT { || ::CountSeconds( oTime, ::oDlg ) }        
      @ 0,0 BITMAP Bitmap SHOW cFile STRETCH 0 SIZE nWidth, nHeight STYLE nStyle 
   ENDIF     
   
   ::oDlg:Activate( otime < 0 )
   ::oTimer:END()

   RETURN Self

METHOD CountSeconds( oTime, oDlg )

   SET TIMER ::oTimer OF oDlg VALUE oTime  ACTION { || EndDialog( GetModalHandle() ) }

   RETURN Nil





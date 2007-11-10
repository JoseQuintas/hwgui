/*
 * $Id: hshbtn.prg,v 1.2 2007-11-10 17:44:48 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HShadeButton class, inherited from HOwnButton
 * It implements some kind of owner drawn buttons
 *
 * Copyright 2006 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "hbclass.ch"
#include "hwgui.ch"

#define STATE_DEFAULT    1
#define STATE_SELECTED   2
#define STATE_FOCUS      4
#define STATE_OVER       8
#define STATE_DISABLED  16

CLASS HShadeButton INHERIT HOwnButton

   DATA hShade

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,bClick,lflat,              ;
                  cText,color,font,xt,yt,                       ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,trColor, ;
                  cTooltip, lEnabled, shadeID, palette,         ;
                  granularity, highlight, coloring, shcolor )
   METHOD Paint()
   METHOD End()

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
               bInit,bSize,bPaint,bClick,lFlat,              ;
               cText,color,font,xt,yt,                       ;
               bmp,lResour,xb,yb,widthb,heightb,lTr,trColor, ;
               cTooltip, lEnabled, shadeID, palette,         ;
               granularity, highlight, coloring, shcolor ) CLASS HShadeButton

   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,    ;
                     bInit,bSize,bPaint,bClick,lFlat,             ;
                     cText,color,font,xt,yt,,,                    ;
                     bmp,lResour,xb,yb,widthb,heightb,lTr,trColor,;
                     cTooltip, lEnabled )

   ::hShade := shade_New( 0, 0, nWidth, nHeight, lFlat )
   shade_Set( ::hShade, shadeID, palette, granularity, highlight, coloring, shcolor )
Return Self

METHOD Paint() CLASS HShadeButton
Local pps, hDC
Local nState

   pps := DefinePaintStru()
   hDC := BeginPaint( ::handle, pps )

   IF ::state == OBTN_INIT
      ::state := OBTN_NORMAL
   ENDIF

   IF ::lEnabled
      nState := Iif( ::state == OBTN_PRESSED, STATE_SELECTED, STATE_DEFAULT + ;
                  Iif( ::state == OBTN_MOUSOVER, STATE_OVER, 0 ) ) + ;
                    Iif( GetFocus() == ::handle, STATE_FOCUS, 0 )
   ELSE
      nState := STATE_DISABLED
   ENDIF

   shade_Draw( ::hShade, hDC, nState )

   ::DrawItems( hDC )

   EndPaint( ::handle, pps )
Return Nil

METHOD End() CLASS HShadeButton

   Super:End()
   shade_Release( ::hShade )
Return Nil

/*
 * $Id: hownbtn.prg,v 1.22 2005-10-19 10:04:27 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HOwnButton class, which implements owner drawn buttons
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HOwnButton INHERIT HControl

   DATA winclass   INIT "OWNBTN"
   DATA lFlat
   DATA state
   DATA bClick
   DATA lPress  INIT .F.
   DATA text,ofont,xt,yt,widtht,heightt
   DATA bitmap,xb,yb,widthb,heightb,lTransp,trColor, oBitmap
   DATA lEnabled INIT .T.
   DATA nOrder

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,bClick,lflat,              ;
                  cText,color,font,xt,yt,widtht,heightt,        ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,trColor, ;
                  cTooltip, lEnabled )

   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Redefine( oWndParent,nId,bInit,bSize,bPaint,bClick,lflat, ;
                  cText,color,font,xt,yt,widtht,heightt,     ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,      ;
                  cTooltip, lEnabled ) 
   METHOD Paint()
   METHOD MouseMove( wParam, lParam )
   METHOD MDown()
   METHOD MUp()
   METHOD Press()   INLINE ( ::lPress := .T., ::MDown() )
   METHOD Release()
   METHOD End()
   METHOD Enable()
   METHOD Disable()

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,   ;
                  bInit,bSize,bPaint,bClick,lflat,             ;
                  cText,color,font,xt,yt,widtht,heightt,       ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,trColor,;
                  cTooltip, lEnabled  ) CLASS HOwnButton

   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,font,bInit, ;
                  bSize,bPaint,ctooltip )

   ::lFlat   := Iif( lFlat==Nil,.F.,lFlat )
   ::bClick  := bClick
   ::state   := OBTN_INIT
   ::nOrder  := iif( oWndParent==nil, 0, len( oWndParent:aControls ) )
   
   ::text    := cText
   ::tcolor  := Iif( color==Nil, GetSysColor( COLOR_BTNTEXT ), color )
   ::xt      := xt
   ::yt      := yt
   ::widtht  := widtht
   ::heightt := heightt

   if lEnabled!=Nil
      ::lEnabled:=lEnabled
   endif
   IF bmp != Nil
      ::bitmap  := Iif( (lResour!=Nil.AND.lResour).OR.Valtype(bmp)=="N", HBitmap():AddResource( bmp ), HBitmap():AddFile( bmp ) )
   ENDIF
   ::xb      := xb
   ::yb      := yb
   ::widthb  := widthb
   ::heightb := heightb
   ::lTransp := Iif( ltr!=Nil,lTr,.F. )
   ::trColor := trColor

   hwg_RegOwnBtn()
   ::Activate()

Return Self

METHOD Activate CLASS HOwnButton
   IF ::oParent:handle != 0    
      ::handle := CreateOwnBtn( ::oParent:handle, ::id, ;
                  ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   if !::lEnabled
      EnableWindow( ::handle, .f. )
      ::Disable()
   EndIf

   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HOwnButton

   IF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_LBUTTONDOWN
      ::MDown()
   ELSEIF msg == WM_LBUTTONUP
      ::MUp()
   ELSEIF msg == WM_MOUSEMOVE
      ::MouseMove( wParam, lParam )
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

Return -1

METHOD Init CLASS HOwnButton

   IF !::lInit
      ::nHolder := 1
      SetWindowObject( ::handle,Self )
      // Hwg_InitOwnbtnProc( ::handle )
      Super:Init()
   ENDIF

Return Nil

METHOD Redefine( oWndParent,nId,bInit,bSize,bPaint,bClick,lflat, ;
                  cText,color,font,xt,yt,widtht,heightt,     ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,      ;
                  cTooltip, lEnabled ) CLASS HOwnButton

   Super:New( oWndParent,nId,0,0,0,0,0,,bInit, ;
                  bSize,bPaint,ctooltip )

   ::lFlat   := Iif( lFlat==Nil,.F.,lFlat )
   ::bClick  := bClick
   ::state   := OBTN_INIT

   ::text    := cText
   ::tcolor  := Iif( color==Nil, GetSysColor( COLOR_BTNTEXT ), color )
   ::ofont   := font
   ::xt      := xt
   ::yt      := yt
   ::widtht  := widtht
   ::heightt := heightt

   if lEnabled!=Nil
      ::lEnabled:=lEnabled
   endif

   IF bmp != Nil
      ::bitmap  := Iif( lResour,HBitmap():AddResource( bmp ), HBitmap():AddFile( bmp ) )
   ENDIF
   ::xb      := xb
   ::yb      := yb
   ::widthb  := widthb
   ::heightb := heightb
   ::lTransp := Iif( ltr!=Nil,lTr,.F. )
   hwg_RegOwnBtn()

Return Self

METHOD Paint() CLASS HOwnButton
Local pps, hDC
Local aCoors, aMetr, oPen, oldBkColor, x1, y1, x2, y2

   pps := DefinePaintStru()
   hDC := BeginPaint( ::handle, pps )
   aCoors := GetClientRect( ::handle )

   oldBkColor := SetBkColor( hDC,GetSysColor(COLOR_3DFACE) )
   IF ::state == OBTN_INIT
      ::state := OBTN_NORMAL
   ENDIF

   IF ::lFlat
      IF ::state == OBTN_NORMAL
         DrawButton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],0 )
      ELSEIF ::state == OBTN_MOUSOVER
         DrawButton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],1 )
      ELSEIF ::state == OBTN_PRESSED
         DrawButton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],2 )
      ENDIF
   ELSE
      IF ::state == OBTN_NORMAL
         DrawButton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],5 )
      ELSEIF ::state == OBTN_PRESSED
         DrawButton( hDC, aCoors[1],aCoors[2],aCoors[3],aCoors[4],6 )
      ENDIF
   ENDIF

   IF ::bitmap != Nil
      IF ::widthb == Nil .OR. ::widthb == 0
         ::widthb := ::bitmap:nWidth
         ::heightb := ::bitmap:nHeight
      ENDIF
      x1 := Iif( ::xb!=Nil .AND. ::xb!=0, ::xb, ;
                 Round( (aCoors[3]-aCoors[1]-::widthb) / 2, 0 ) )
      y1 := Iif( ::yb!=Nil .AND. ::yb!=0, ::yb, ;
                 Round( (aCoors[4]-aCoors[2]-::heightb) / 2, 0 ) )
      if ::lEnabled //if button is enabled
         if ::oBitmap!=Nil
            ::bitmap:handle:=::oBitmap
            ::oBitmap:=Nil
         EndIf
         IF ::lTransp
            DrawTransparentBitmap( hDC, ::bitmap:handle, x1, y1, ::trColor )
         ELSE
            DrawBitmap( hDC, ::bitmap:handle,, x1, y1, ::widthb, ::heightb )
         ENDIF
      Else
         ::oBitmap:=::bitmap:handle
         DrawGrayBitmap( hDC, ::bitmap:handle, x1, y1 )
      EndIf
   ENDIF

   IF ::text != Nil
      IF ::ofont != Nil
         SelectObject( hDC, ::ofont:handle )
      ELSEIF ::oParent:oFont != Nil
         SelectObject( hDC, ::oParent:ofont:handle )
      ENDIF
      aMetr := GetTextMetric( hDC )
      if ::lEnabled //if button is enabled
         SetTextColor( hDC,::tcolor )
      Else
         SetTextColor( hDC, RGB(255,255,255) )
      EndIf
      x1 := Iif( ::xt!=Nil .AND. ::xt!=0, ::xt, aCoors[1]+2 )
      y1 := Iif( ::yt!=Nil .AND. ::yt!=0, ::yt, ;
                              Round( ( aCoors[4]-aCoors[2]-aMetr[1] ) / 2, 0 ) )
      x2 := Iif( ::widtht!=Nil .AND. ::widtht!=0, ;
                          ::xt+::widtht-1, aCoors[3]-2 )
      y2 := Iif( ::heightt!=Nil .AND. ::heightt!=0, ;
                 ::yt+::heightt-1, y1+aMetr[1] )
      SetTransparentMode( hDC,.T. )
      DrawText( hDC, ::text, x1, y1, x2, y2, DT_CENTER )
      SetTransparentMode( hDC,.F. )
   ENDIF
   SetBkColor( hDC,oldBkColor )
   EndPaint( ::handle, pps )
Return Nil

METHOD MouseMove( wParam, lParam )  CLASS HOwnButton
Local xPos, yPos, otmp
Local res := .F.

   IF ::state != OBTN_INIT
      xPos := LoWord( lParam )
      yPos := HiWord( lParam )
      IF xPos > ::nWidth .OR. yPos > ::nHeight
         ReleaseCapture()
         res := .T.
      ENDIF

      IF res .AND. !::lPress
         ::state := OBTN_NORMAL
         InvalidateRect( ::handle, 0 )
         PostMessage( ::handle, WM_PAINT, 0, 0 )
      ENDIF
      IF ::state == OBTN_NORMAL .AND. !res
         ::state := OBTN_MOUSOVER
         InvalidateRect( ::handle, 0 )
         PostMessage( ::handle, WM_PAINT, 0, 0 )
         SetCapture( ::handle )
      ENDIF
   ENDIF
Return Nil

METHOD MDown()  CLASS HOwnButton
   IF ::state != OBTN_PRESSED
      ::state := OBTN_PRESSED
      InvalidateRect( ::handle, 0 )
      SetFocus( ::handle )
      PostMessage( ::handle, WM_PAINT, 0, 0 )
   ENDIF
Return Nil

METHOD MUp() CLASS HOwnButton
   IF ::state == OBTN_PRESSED
      IF !::lPress
         ::state := OBTN_NORMAL  // IIF( ::lFlat,OBTN_MOUSOVER,OBTN_NORMAL )
         InvalidateRect( ::handle, 0 )
         PostMessage( ::handle, WM_PAINT, 0, 0 )
      ENDIF
      IF ::bClick != Nil
         ReleaseCapture()
         Eval( ::bClick, ::oParent, ::id )
      ENDIF
   ENDIF

Return Nil

METHOD Release()  CLASS HOwnButton
   ::lPress := .F.
   ::state := OBTN_NORMAL
   InvalidateRect( ::handle, 0 )
   PostMessage( ::handle, WM_PAINT, 0, 0 )
Return Nil

METHOD End()  CLASS HOwnButton

   Super:End()
   IF ::ofont != Nil
       ::ofont:Release()
       ::ofont := Nil
   ENDIF
   IF ::bitmap != Nil
      ::bitmap:Release()
      ::bitmap := Nil
   ENDIF

Return Nil

METHOD Enable() CLASS HOwnButton

   EnableWindow( ::handle, .T. )
   ::lEnabled:=.T.
   InvalidateRect( ::handle, 0 )
   SendMessage( ::handle, WM_PAINT, 0, 0 )
   ::Init()

Return Nil

METHOD Disable() CLASS HOwnButton

   ::state   := OBTN_INIT
   ::lEnabled:=.F.
   InvalidateRect( ::handle, 0 )
   SendMessage( ::handle, WM_PAINT, 0, 0 )
   EnableWindow( ::handle, .F. )

Return Nil


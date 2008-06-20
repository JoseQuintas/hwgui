/*
 * $Id: hownbtn.prg,v 1.32 2008-06-20 23:43:00 mlacecilia Exp $
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
#include "common.ch"

CLASS HOwnButton INHERIT HControl

   CLASS VAR cPath SHARED
   DATA winclass   INIT "OWNBTN"
   DATA lFlat
   DATA state
   DATA bClick
   DATA lPress  INIT .F.
   DATA lCheck  INIT .f.
   DATA xt,yt,widtht,heightt
   DATA oBitmap,xb,yb,widthb,heightb,lTransp,trColor
   DATA lEnabled INIT .T.
   DATA nOrder

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,bClick,lflat,              ;
                  cText,color,font,xt,yt,widtht,heightt,        ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,trColor, ;
                  cTooltip, lEnabled, lCheck )

   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Redefine( oWndParent,nId,bInit,bSize,bPaint,bClick,lflat, ;
                  cText,color,font,xt,yt,widtht,heightt,     ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,      ;
                  cTooltip, lEnabled, lCheck )
   METHOD Paint()
   METHOD DrawItems( hDC )
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
                  cText,color,oFont,xt,yt,widtht,heightt,       ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,trColor,;
                  cTooltip, lEnabled, lCheck  ) CLASS HOwnButton

   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip )

   IF oFont == Nil
      ::oFont := ::oParent:oFont
   ENDIF
   ::lFlat   := Iif( lFlat==Nil, .F., lFlat )
   ::bClick  := bClick
   ::state   := OBTN_INIT
   ::nOrder  := iif( oWndParent==nil, 0, len( oWndParent:aControls ) )

   ::title   := cText
   ::tcolor  := Iif( color==Nil, GetSysColor( COLOR_BTNTEXT ), color )
   ::xt      := Iif( xt==Nil, 0, xt )
   ::yt      := Iif( yt==Nil, 0, yt )
   ::widtht  := Iif( widtht==Nil, 0, widtht )
   ::heightt := Iif( heightt==Nil, 0, heightt )

   IF lEnabled != Nil
      ::lEnabled := lEnabled
   ENDIF
   IF lCheck != Nil
     ::lCheck := lCheck
   ENDIF
   IF bmp != Nil
      IF Valtype( bmp ) == "O"
         ::oBitmap := bmp
      ELSE
         ::oBitmap := Iif( (lResour!=Nil.AND.lResour).OR.Valtype(bmp)=="N", ;
                    HBitmap():AddResource( bmp ), ;
                    HBitmap():AddFile( Iif( ::cPath!=Nil,::cPath+bmp,bmp ) ) )
      ENDIF
   ENDIF
   ::xb      := xb
   ::yb      := yb
   ::widthb  := Iif( widthb==Nil, 0, widthb )
   ::heightb := Iif( heightb==Nil, 0, heightb )
   ::lTransp := Iif( ltr!=Nil, lTr, .F. )
   ::trColor := trColor

   hwg_RegOwnBtn()
   ::Activate()

Return Self

METHOD Activate CLASS HOwnButton
   IF !empty( ::oParent:handle ) 
      ::handle := CreateOwnBtn( ::oParent:handle, ::id, ;
                  ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      IF !::lEnabled
         EnableWindow( ::handle, .f. )
         ::Disable()
      ENDIF
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HOwnButton

   IF msg == WM_PAINT
      IF ::bPaint != Nil
         Eval( ::bPaint, Self )
      ELSE
         ::Paint()
      ENDIF
   ELSEIF msg == WM_ERASEBKGND
      Return 1
   ELSEIF msg == WM_MOUSEMOVE
      ::MouseMove( wParam, lParam )
   ELSEIF msg == WM_LBUTTONDOWN
      ::MDown()
   ELSEIF msg == WM_LBUTTONUP
      ::MUp()
   ELSEIF msg == WM_DESTROY
      ::End()
   ELSEIF msg == WM_SETFOCUS
      IF !empty(::bGetfocus)
         Eval(::bGetfocus, self, msg, wParam, lParam)
      ENDIF
   ELSEIF msg == WM_KILLFOCUS
      IF !Empty(::bLostfocus)
         Eval(::bLostfocus, self, msg, wParam, lParam)
      ENDIF
   ELSE
      IF !Empty(::bOther)
         Eval(::bOther, self, msg, wParam, lParam)
      ENDIF
   ENDIF

Return -1

METHOD Init CLASS HOwnButton

   IF !::lInit
      ::nHolder := 1
      SetWindowObject( ::handle,Self )
      Super:Init()
   ENDIF

Return Nil

METHOD Redefine( oWndParent,nId,bInit,bSize,bPaint,bClick,lflat, ;
                  cText,color,font,xt,yt,widtht,heightt,     ;
                  bmp,lResour,xb,yb,widthb,heightb,lTr,      ;
                  cTooltip, lEnabled, lCheck ) CLASS HOwnButton

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0,, bInit, bSize, bPaint, ctooltip )

   ::lFlat   := Iif( lFlat==Nil, .F., lFlat )
   ::bClick  := bClick
   ::state   := OBTN_INIT

   ::title   := cText
   ::tcolor  := Iif( color==Nil, GetSysColor( COLOR_BTNTEXT ), color )
   ::ofont   := font
   ::xt      := Iif( xt==Nil, 0, xt )
   ::yt      := Iif( yt==Nil, 0, yt )
   ::widtht  := Iif( widtht==Nil, 0, widtht )
   ::heightt := Iif( heightt==Nil, 0, heightt )

   IF lEnabled != Nil
      ::lEnabled := lEnabled
   ENDIF
      IF lEnabled != Nil
      ::lEnabled := lEnabled
   ENDIF
   IF lCheck != Nil
     ::lCheck := lCheck
   ENDIF

   IF bmp != Nil
      IF Valtype( bmp ) == "O"
         ::oBitmap := bmp
      ELSE
         ::oBitmap := Iif( lResour,HBitmap():AddResource( bmp ), ;
                 HBitmap():AddFile( bmp ) )
      ENDIF
   ENDIF
   ::xb      := xb
   ::yb      := yb
   ::widthb  := Iif( widthb==Nil, 0, widthb )
   ::heightb := Iif( heightb==Nil, 0, heightb )
   ::lTransp := Iif( ltr!=Nil,lTr,.F. )
   hwg_RegOwnBtn()

Return Self

METHOD Paint() CLASS HOwnButton
Local pps, hDC
Local aCoors

   pps := DefinePaintStru()

   hDC := BeginPaint( ::handle, pps )

   aCoors := GetClientRect( ::handle )

   IF ::state == OBTN_INIT
      ::state := OBTN_NORMAL
   ENDIF
   IF ::nWidth != aCoors[3] .OR. ::nHeight != aCoors[4]
      ::nWidth  := aCoors[3]
      ::nHeight := aCoors[4]
   ENDIF

   IF ::lFlat
      IF ::state == OBTN_NORMAL
         DrawButton( hDC,0,0,aCoors[3],aCoors[4],0 )
      ELSEIF ::state == OBTN_MOUSOVER
         DrawButton( hDC,0,0,aCoors[3],aCoors[4],1 )
      ELSEIF ::state == OBTN_PRESSED
         DrawButton( hDC,0,0,aCoors[3],aCoors[4],2 )
      ENDIF
   ELSE
      IF ::state == OBTN_NORMAL
         DrawButton( hDC,0,0,aCoors[3],aCoors[4],5 )
      ELSEIF ::state == OBTN_PRESSED
         DrawButton( hDC,0,0,aCoors[3],aCoors[4],6 )
      ENDIF
   ENDIF

   ::DrawItems( hDC )

   EndPaint( ::handle, pps )
Return Nil

METHOD DrawItems( hDC )
Local x1, y1, x2, y2

   IF ::oBitmap != Nil
      IF ::widthb == 0
         ::widthb := ::oBitmap:nWidth
         ::heightb := ::oBitmap:nHeight
      ENDIF
      x1 := Iif( ::xb!=Nil .AND. ::xb!=0, ::xb, ;
                 Round( (::nWidth-::widthb) / 2, 0 ) )
      y1 := Iif( ::yb!=Nil .AND. ::yb!=0, ::yb, ;
                 Round( (::nHeight-::heightb) / 2, 0 ) )
      IF ::lEnabled
         IF ::oBitmap:ClassName()=="HICON"
            DrawIcon( hDC, ::oBitmap:handle, x1, y1 )
         ELSE
            IF ::lTransp
               DrawTransparentBitmap( hDC, ::oBitmap:handle, x1, y1, ::trColor )
            ELSE
               DrawBitmap( hDC, ::oBitmap:handle,, x1, y1, ::widthb, ::heightb )
            ENDIF
         ENDIF
      ELSE
         DrawGrayBitmap( hDC, ::oBitmap:handle, x1, y1 )
      ENDIF
   ENDIF

   IF ::oBitmap != Nil
      IF ::widthb == 0
         ::widthb := ::oBitmap:nWidth
         ::heightb := ::oBitmap:nHeight
      ENDIF
      x1 := Iif( ::xb!=Nil .AND. ::xb!=0, ::xb, ;
                 Round( (::nWidth-::widthb) / 2, 0 ) )
      y1 := Iif( ::yb!=Nil .AND. ::yb!=0, ::yb, ;
                 Round( (::nHeight-::heightb) / 2, 0 ) )
      IF ::lEnabled
         IF ::oBitmap:ClassName()=="HICON"
            DrawIcon( hDC, ::oBitmap:handle, x1, y1 )
         ELSE
            IF ::lTransp
               DrawTransparentBitmap( hDC, ::oBitmap:handle, x1, y1, ::trColor )
            ELSE
               DrawBitmap( hDC, ::oBitmap:handle,, x1, y1, ::widthb, ::heightb )
            ENDIF
         ENDIF
      ELSE
         DrawGrayBitmap( hDC, ::oBitmap:handle, x1, y1 )
      ENDIF
   ENDIF

   IF ::title != Nil
      IF ::oFont != Nil
         SelectObject( hDC, ::oFont:handle )
      ENDIF
      IF ::lEnabled
         SetTextColor( hDC,::tcolor )
      ELSE
         SetTextColor( hDC, RGB(255,255,255) )
      ENDIF
      x1 := Iif( ::xt!=0, ::xt, 4 )
      y1 := Iif( ::yt!=0, ::yt, 4 )
      x2 := ::nWidth - 4
      y2 := ::nHeight - 4
      SetTransparentMode( hDC,.T. )
      DrawText( hDC, ::title, x1, y1, x2, y2, ;
         Iif( ::xt!=0,DT_LEFT,DT_CENTER ) + Iif( ::yt!=0,DT_TOP,DT_VCENTER+DT_SINGLELINE ) )
      SetTransparentMode( hDC,.F. )
   ENDIF

Return Nil

METHOD MouseMove( wParam, lParam )  CLASS HOwnButton
Local xPos, yPos
Local res := .F.

HB_SYMBOL_UNUSED(wParam)

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
      ENDIF
     IF ::lCheck
      IF ::lPress
         ::Release()
      else
           ::Press()
      ENDIF
     ENDIF
      IF ::bClick != Nil
         ReleaseCapture()
         Eval( ::bClick, ::oParent, ::id )
      ENDIF
      InvalidateRect( ::handle, 0 )
//    SendMessage( ::handle, WM_PAINT, 0, 0 )
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
   ::oFont := Nil
   IF ::oBitmap != Nil
      ::oBitmap:Release()
      ::oBitmap := Nil
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


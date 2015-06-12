/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HOwnButton class, which implements owner drawn buttons
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "inkey.ch"
#include "hbclass.ch"
#include "hwgui.ch"

CLASS HOwnButton INHERIT HControl

   CLASS VAR cPath SHARED
   DATA winclass   INIT "OWNBTN"
   DATA lFlat
   DATA aStyle
   DATA state
   DATA bClick
   DATA lPress   INIT .F.
   DATA lCheck  INIT .F.
   DATA oFont, xt, yt, widtht, heightt
   DATA oBitmap, xb, yb, widthb, heightb
   DATA lTransp  INIT .F.
   DATA trColor
   DATA lEnabled INIT .T.
   DATA nOrder

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bClick, lflat,              ;
      cText, color, font, xt, yt, widtht, heightt,        ;
      bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, ;
      cTooltip, lEnabled, lCheck )

   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD MouseMove( wParam, lParam )
   METHOD MDown()
   METHOD MUp()
   METHOD Press()   INLINE ( ::lPress := .T. , ::MDown() )
   METHOD RELEASE()
   METHOD End()
   METHOD Enable()
   METHOD Disable()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight,   ;
      bInit, bSize, bPaint, bClick, lflat,             ;
      cText, color, font, xt, yt, widtht, heightt,       ;
      bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, ;
      cTooltip, lEnabled, lCheck  ) CLASS HOwnButton

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, font, bInit, ;
      bSize, bPaint, ctooltip )

   ::lFlat   := Iif( lFlat == Nil, .F. , lFlat )
   ::bClick  := bClick
   ::state   := OBTN_INIT
   ::nOrder  := Iif( oWndParent == nil, 0, Len( oWndParent:aControls ) )

   ::title    := cText
   ::tcolor  := Iif( color == Nil, 0, color )
   ::xt      := xt
   ::yt      := yt
   ::widtht  := widtht
   ::heightt := heightt

   IF lEnabled != Nil
      ::lEnabled := lEnabled
   ENDIF
   IF lCheck != Nil
      ::lCheck := lCheck
   ENDIF
   IF bmp != Nil
      IF ValType( bmp ) == "O"
         ::oBitmap := bmp
      ELSE
         ::oBitmap := Iif( ( lResour != Nil .AND. lResour ) .OR. ValType( bmp ) == "N", ;
            HBitmap():AddResource( bmp ), ;
            HBitmap():AddFile( Iif( ::cPath != Nil,::cPath + bmp,bmp ) ) )
      ENDIF
      IF ::oBitmap != Nil .AND. lTr != Nil .AND. lTr
         ::trColor := Iif( trColor != Nil, trColor, 16777215 )
         ::lTransp := .T.
         hwg_alpha2pixbuf( ::oBitmap:handle, ::trColor )
      ENDIF
   ENDIF
   ::xb      := xb
   ::yb      := yb
   ::widthb  := widthb
   ::heightb := heightb
   ::trColor := trColor

   ::Activate()

   RETURN Self

METHOD Activate CLASS HOwnButton

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createownbtn( ::oParent:handle, ::id, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      IF !::lEnabled
         hwg_Enablewindow( ::handle, .F. )
         ::Disable()
      ENDIF

   ENDIF

   RETURN Nil

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

   RETURN 0

METHOD Init CLASS HOwnButton

   IF !::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HOwnButton
   LOCAL hDC := hwg_Getdc( ::handle )
   LOCAL aCoors, aMetr, x1, y1, x2, y2, n

   aCoors := hwg_Getclientrect( ::handle )

   IF ::state == OBTN_INIT
      ::state := OBTN_NORMAL
   ENDIF

   IF !Empty( ::aStyle )
      n := Len( ::aStyle )
      n := Iif( ::state == OBTN_MOUSOVER, Iif( n > 2, 3, 1 ), ;
            Iif( ::state == OBTN_PRESSED, Iif( n > 1, 2, 1 ), 1 ) )
      hwg_drawGradient( hDC, aCoors[1], aCoors[2], aCoors[ 3 ], aCoors[ 4 ], ;
            ::aStyle[n]:nOrient, ::aStyle[n]:aColors )
      IF !Empty( ::aStyle[n]:oPen )
         hwg_Selectobject( hDC, ::aStyle[n]:oPen:handle )
         hwg_Rectangle( hDC, 0, 0, aCoors[3]-1, aCoors[4]-1 )
      ENDIF
   ELSEIF ::lFlat
      IF ::state == OBTN_NORMAL
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 0 )
      ELSEIF ::state == OBTN_MOUSOVER
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 1 )
      ELSEIF ::state == OBTN_PRESSED
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 2 )
      ENDIF
   ELSE
      IF ::state == OBTN_NORMAL
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 5 )
      ELSEIF ::state == OBTN_PRESSED
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 6 )
      ENDIF
   ENDIF

   IF ::oBitmap != Nil
      IF ::widthb == Nil .OR. ::widthb == 0
         ::widthb := ::oBitmap:nWidth
         ::heightb := ::oBitmap:nHeight
      ENDIF
      x1 := Iif( ::xb != Nil .AND. ::xb != 0, ::xb, ;
         Round( ( aCoors[3] - aCoors[1] - ::widthb ) / 2, 0 ) )
      y1 := Iif( ::yb != Nil .AND. ::yb != 0, ::yb, ;
         Round( ( aCoors[4] - aCoors[2] - ::heightb ) / 2, 0 ) )
      IF ::lEnabled
         hwg_Drawbitmap( hDC, ::oBitmap:handle, , x1, y1, ::widthb, ::heightb )
      ELSE
         hwg_Drawgraybitmap( hDC, ::oBitmap:handle, x1, y1 )
      ENDIF
   ENDIF

   IF ::title != Nil
      IF ::oFont != Nil
         hwg_Selectobject( hDC, ::oFont:handle )
      ELSEIF ::oParent:oFont != Nil
         hwg_Selectobject( hDC, ::oParent:oFont:handle )
      ENDIF
      aMetr := hwg_Gettextmetric( hDC )
      IF ::lEnabled
         hwg_Settextcolor( hDC, ::tcolor )
      ELSE
         hwg_Settextcolor( hDC, 0 )
      ENDIF
      x1 := Iif( ::xt != Nil .AND. ::xt != 0, ::xt, aCoors[1] + 2 )
      y1 := Iif( ::yt != Nil .AND. ::yt != 0, ::yt, ;
         Round( ( aCoors[4] - aCoors[2] - aMetr[1] ) / 2, 0 ) )
      x2 := Iif( ::widtht != Nil .AND. ::widtht != 0, ;
         ::xt + ::widtht - 1, aCoors[3] - 2 )
      y2 := Iif( ::heightt != Nil .AND. ::heightt != 0, ;
         ::yt + ::heightt - 1, y1 + aMetr[1] )
      // hwg_Settransparentmode( hDC,.T. )
      hwg_Drawtext( hDC, ::title, x1, y1, x2, y2, Iif( ::xt != Nil .AND. ::xt != 0,DT_LEFT,DT_CENTER ) )
      // hwg_Settransparentmode( hDC,.F. )
   ENDIF
   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD MouseMove( wParam, lParam )  CLASS HOwnButton
   LOCAL lEnter := ( hwg_BitAnd( wParam,16 ) > 0 )
   LOCAL res := .F.

   IF ::state != OBTN_INIT
      IF !lEnter .AND. !::lPress
         ::state := OBTN_NORMAL
         hwg_Redrawwindow( ::handle )
      ENDIF
      IF lEnter .AND. ::state == OBTN_NORMAL
         ::state := OBTN_MOUSOVER
         hwg_Redrawwindow( ::handle )
      ENDIF
   ENDIF

   RETURN Nil

METHOD MDown()  CLASS HOwnButton

   IF ::state != OBTN_PRESSED
      ::state := OBTN_PRESSED
      hwg_Redrawwindow( ::handle )
      //hwg_Setfocus( ::handle )
   ENDIF

   RETURN Nil

METHOD MUp() CLASS HOwnButton

   IF ::state == OBTN_PRESSED
      IF !::lPress
         ::state := OBTN_NORMAL
      ENDIF
      IF ::lCheck
         IF ::lPress
            ::Release()
         ELSE
            ::Press()
         ENDIF
      ENDIF
      IF ::bClick != Nil
         Eval( ::bClick, ::oParent, ::id )
      ENDIF
      hwg_Redrawwindow( ::handle )
   ENDIF

   RETURN Nil

METHOD RELEASE()  CLASS HOwnButton

   ::lPress := .F.
   ::state := OBTN_NORMAL
   hwg_Redrawwindow( ::handle )

   RETURN Nil

METHOD End()  CLASS HOwnButton

   ::Super:End()
   IF ::oFont != Nil
      ::oFont:Release()
      ::oFont := Nil
   ENDIF
   IF ::oBitmap != Nil
      ::oBitmap:Release()
      ::oBitmap := Nil
   ENDIF

   RETURN Nil

METHOD Enable() CLASS HOwnButton

   hwg_Enablewindow( ::handle, .T. )
   ::lEnabled := .T.
   hwg_Redrawwindow( ::handle )

   RETURN Nil

METHOD Disable() CLASS HOwnButton

   ::state   := OBTN_INIT
   ::lEnabled := .F.
   hwg_Redrawwindow( ::handle )
   hwg_Enablewindow( ::handle, .F. )

   RETURN Nil

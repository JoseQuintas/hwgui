/*
 * $Id: hpanel.prg,v 1.24 2009-05-15 11:38:57 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPanel class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HPanel INHERIT HControl

   DATA winclass Init "PANEL"
   DATA oEmbedded
   DATA bScroll
   DATA lResizeX, lResizeY HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               bInit, bSize, bPaint, bcolor )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor )
   METHOD Paint()
   METHOD BackColor( bcolor ) INLINE ::SetColor(, bcolor, .T. )
   METHOD Hide()
   METHOD Show()
   METHOD Release()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               bInit, bSize, bPaint, bcolor ) CLASS HPanel
LOCAL oParent := Iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, Iif( nWidth == Nil, 0, nWidth ), ;
              Iif( nHeight == Nil, 0, nHeight ), oParent:oFont, bInit, ;
              bSize, bPaint )

   IF bcolor != NIL
      ::brush  := HBrush():Add( bcolor )
      ::bcolor := bcolor
   ENDIF
   ::bPaint   := bPaint
   ::lResizeX := ( ::nWidth == 0 )
   ::lResizeY := ( ::nHeight == 0 )
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:Type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] := ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] := ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] := ::nWidth
         ENDIF
      ENDIF
   ENDIF

   hwg_RegPanel()
   ::Activate()

RETURN Self

METHOD Activate CLASS HPanel
LOCAL handle := ::oParent:handle

   IF !Empty( handle )
      ::handle := CreatePanel( handle, ::id, ;
                               ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HPanel

   IF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_ERASEBKGND
      IF ::brush != Nil
         IF Valtype( ::brush ) != "N"
            FillRect( wParam, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
         ENDIF
         RETURN 1
      ENDIF
   ELSEIF msg == WM_SIZE
      IF ::oEmbedded != Nil
         ::oEmbedded:Resize( Loword( lParam ), Hiword( lParam ) )
      ENDIF
      ::Super:onEvent( WM_SIZE, wParam, lParam )
   ELSEIF msg == WM_DESTROY
      IF ::oEmbedded != Nil
         ::oEmbedded:END()
      ENDIF
      ::Super:onEvent( WM_DESTROY )
      RETURN 0
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
         onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

RETURN - 1

METHOD Init CLASS HPanel

   IF !::lInit
      IF ::bSize == Nil
         ::bSize := { | o, x, y | o:Move( Iif( ::nLeft > 0, x - ::nLeft, 0 ), ;
                      Iif( ::nTop > 0, y - ::nHeight, 0 ), ;
                      Iif( ::nWidth == 0 .OR. ::lResizeX, x, ::nWidth ), ;
                      Iif( ::nHeight == 0 .OR. ::lResizeY, y, ::nHeight ) ) }
      ENDIF

      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitWinCtrl( ::handle )
   ENDIF

RETURN Nil

METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor ) CLASS HPanel
LOCAL oParent := Iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   Super:New( oWndParent, nId, 0, 0, 0, Iif( nWidth == Nil, 0, nWidth ), ;
              Iif( nHeight != Nil, nHeight, 0 ), oParent:oFont, bInit, ;
              bSize, bPaint )

   IF bcolor != NIL
      ::brush  := HBrush():Add( bcolor )
      ::bcolor := bcolor
   ENDIF

   ::bPaint   := bPaint
   ::lResizeX := ( ::nWidth == 0 )
   ::lResizeY := ( ::nHeight == 0 )
   hwg_RegPanel()

RETURN Self

METHOD Paint() CLASS HPanel
LOCAL pps, hDC, aCoors, oPenLight, oPenGray

   IF ::bPaint != Nil
      Eval( ::bPaint, Self )
   ELSE
      pps    := DefinePaintStru()
      hDC    := BeginPaint( ::handle, pps )
      aCoors := GetClientRect( ::handle )

      oPenLight := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
      SelectObject( hDC, oPenLight:handle )
      DrawLine( hDC, 5, 1, aCoors[ 3 ] - 5, 1 )
      oPenGray := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DSHADOW ) )
      SelectObject( hDC, oPenGray:handle )
      DrawLine( hDC, 5, 0, aCoors[ 3 ] - 5, 0 )

      oPenGray:Release()
      oPenLight:Release()
      EndPaint( ::handle, pps )
   ENDIF

RETURN Nil

METHOD Release CLASS HPanel

   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] -= ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] -= ::nWidth
         ENDIF
      ENDIF
      InvalidateRect( ::oParent:handle, 0, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   SendMessage( ::oParent:handle, WM_SIZE, 0, 0 )
   ::oParent:DelControl( Self )
RETURN Nil

METHOD Hide CLASS HPanel
LOCAL i

   IF ::lHide
      RETURN Nil
   ENDIF
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] -= ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] -= ::nWidth
         ENDIF
      ENDIF
      InvalidateRect( ::oParent:handle, 0, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   ::nSize := ::nWidth
   FOR i := 1 TO Len( ::acontrols )
      ::acontrols[ i ]:hide()
   NEXT
   super:hide()
   SendMessage( ::oParent:Handle, WM_SIZE, 0, 0 )
RETURN Nil

METHOD Show CLASS HPanel
LOCAL i

   IF !::lHide
      RETURN Nil
   ENDIF
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] += ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] += ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] += ::nWidth
         ENDIF
      ENDIF
      InvalidateRect( ::oParent:handle, 1, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   ::nWidth := ::nsize
   SendMessage( ::oParent:Handle, WM_SIZE, 0, 0 )
   super:Show()
   FOR i := 1 TO Len( ::acontrols )
      ::acontrols[ i ]:Show()
   NEXT
   MoveWindow( ::Handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )
RETURN Nil

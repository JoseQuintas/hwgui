/*
 * $Id: hpanel.prg,v 1.21 2008-11-24 10:02:13 mlacecilia Exp $
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

   DATA winclass   INIT "PANEL"
   DATA oEmbedded
   DATA lResizeX, lResizeY   HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               bInit, bSize, bPaint, bcolor )  //lDocked )
METHOD Activate()
METHOD onEvent( msg, wParam, lParam )
METHOD Init()
METHOD Redefine( oWndParent, nId, nHeight, bInit, bSize, bPaint, lDocked )
METHOD Paint()
METHOD BackColor( bcolor ) INLINE ::SetColor(, bcolor, .T. )

ENDCLASS


METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            bInit, bSize, bPaint, bcolor ) CLASS HPanel
   LOCAL oParent := IIf( oWndParent == Nil, ::oDefaultParent, oWndParent )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, IIf( nWidth == Nil, 0, nWidth ), ;
              IIf( nHeight == Nil, 0, nHeight ), oParent:oFont, bInit, ;
              bSize, bPaint )

   IF bcolor != NIL
      ::brush := HBrush():Add( bcolor )
      ::bcolor := bcolor
   ENDIF
   ::bPaint  := bPaint
   ::lResizeX := ::nWidth == 0
   ::lResizeY := ::nHeight == 0
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

   IF ! Empty( handle )
      ::handle := CreatePanel( handle, ::id, ;
                               ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HPanel

   IF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_ERASEBKGND
      IF ::brush != Nil
         IF ValType( ::brush ) != "N"
            FillRect( wParam, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
         ENDIF
         RETURN 1
      ENDIF
   ELSEIF msg == WM_SIZE
      IF ::oEmbedded != Nil
         ::oEmbedded:Resize( LOWORD( lParam ), HIWORD( lParam ) )
      ENDIF
      ::Super:onEvent( WM_SIZE, wParam, lParam )
   ELSEIF msg == WM_DESTROY
      IF ::oEmbedded != Nil
         ::oEmbedded:END()
      ENDIF
      ::Super:onEvent( WM_DESTROY )
      RETURN 0
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1

METHOD Init CLASS HPanel

   IF ! ::lInit
      IF ::bSize == Nil
/*         IF ::nHeight!=0 .AND. ( ::nWidth>::nHeight .OR. ::nWidth==0 )
            ::bSize := {|o,x,y|o:Move( ,Iif(::nTop>0,y-::nHeight,0),x,::nHeight )}
         ELSEIF ::nWidth!=0 .AND. ( ::nHeight>::nWidth .OR. ::nHeight==0 )
            ::bSize := {|o,x,y|o:Move( Iif(::nLeft>0,x-::nLeft,0),,::nWidth,y )}
      ENDIF     */
      ::bSize := { | o, x, y | o:Move( IIf( ::nLeft > 0, x - ::nLeft,   0 ), ;
                                       IIf( ::nTop  > 0, y - ::nHeight, 0 ), ;
                                       IIf( ::nWidth == 0 .or. ::lResizeX, x, ::nWidth ) , ;
                                       IIf( ::nHeight == 0.or. ::lResizeY, y, ::nHeight ) ) }
   ENDIF

   Super:Init()
   ::nHolder := 1
   SetWindowObject( ::handle, Self )
   Hwg_InitWinCtrl( ::handle )
ENDIF

RETURN Nil


METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor ) CLASS HPanel
   LOCAL oParent := IIf( oWndParent == Nil, ::oDefaultParent, oWndParent )

   Super:New( oWndParent, nId, 0, 0, 0, IIf( nWidth == Nil, 0, nWidth ), ;
              IIf( nHeight != Nil, nHeight, 0 ), oParent:oFont, bInit, ;
              bSize, bPaint )

   IF bcolor != NIL
      ::brush := HBrush():Add( bcolor )
      ::bcolor := bcolor
   ENDIF

   ::bPaint  := bPaint
   ::lResizeX := ::nWidth == 0
   ::lResizeY := ::nHeight == 0
   hwg_RegPanel()

   RETURN Self

METHOD Paint() CLASS HPanel
   LOCAL pps, hDC, aCoors, oPenLight, oPenGray

   IF ::bPaint != Nil
      Eval( ::bPaint, Self )
   ELSE
      pps := DefinePaintStru()
      hDC := BeginPaint( ::handle, pps )
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


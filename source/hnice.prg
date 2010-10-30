/*
 * $Id: hnice.prg,v 1.10 2010-10-30 16:43:31 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 *
 *
 * Copyright 2004 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/

#include "windows.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define TRANSPARENT 1

CLASS HNiceButton INHERIT HControl

   DATA winclass INIT "NICEBUTT"
   DATA TEXT, id, nTop, nLeft, nwidth, nheight
   CLASSDATA oSelected INIT Nil
   DATA State INIT 0
   DATA ExStyle
   DATA bClick, cTooltip

   DATA lPress INIT .F.
   DATA r INIT 30
   DATA g INIT 90
   DATA b INIT 90
   DATA lFlat
   DATA nOrder

   METHOD New( oWndParent, nId, nStyle, nStyleEx, nLeft, nTop, nWidth, nHeight, ;
               bInit, bClick, ;
               cText, cTooltip, r, g, b )

   METHOD Redefine( oWndParent, nId, nStyleEx, ;
                    bInit, bClick, ;
                    cText, cTooltip, r, g, b )

   METHOD Activate()
   METHOD INIT()
   METHOD Create( )
   METHOD Size( )
   METHOD Moving( )
   METHOD Paint()
   METHOD MouseMove( wParam, lParam )
   METHOD MDown()
   METHOD MUp()
   METHOD Press() INLINE( ::lPress := .T., ::MDown() )
   METHOD RELEASE()
   METHOD END ()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nStyleEx, nLeft, nTop, nWidth, nHeight, ;
            bInit, bClick, ;
            cText, cTooltip, r, g, b ) CLASS HNiceButton
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight,, bInit, ;
              ,, cTooltip )
   DEFAULT g := ::g
   DEFAULT b := ::b

   DEFAULT r := ::r
   ::lFlat  := .t.
   ::bClick := bClick
   ::nOrder  := IIf( oWndParent == nil, 0, Len( oWndParent:aControls ) )

   ::ExStyle := nStyleEx
   ::text    := cText
   ::r       := r
   ::g       := g
   ::b       := b
   ::nTop    := nTop
   ::nLeft   := nLeft
   ::nWidth  := nWidth
   ::nHeight := nHeight

   hwg_Regnice()
   ::Activate()

   RETURN Self


METHOD Redefine( oWndParent, nId, nStyleEx, ;
                 bInit, bClick, ;
                 cText, cTooltip, r, g, b ) CLASS HNiceButton

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0,, bInit,,, cTooltip )

   DEFAULT g := ::g
   DEFAULT b := ::b
   DEFAULT r := ::r

   ::lFlat  := .t.

   ::bClick := bClick

   ::ExStyle := nStyleEx
   ::text    := cText
   ::r       := r
   ::g       := g
   ::b       := b

   hwg_Regnice()

   RETURN Self

METHOD Activate() CLASS HNiceButton

   IF ! Empty( ::oParent:handle )
      ::handle := CreateNiceBtn( ::oParent:handle, ::id, ;
                                 ::Style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::ExStyle, ::Text )
      ::Init()
   ENDIF
   RETURN Nil

METHOD INIT() CLASS HNiceButton

   IF ! ::lInit
      Super:Init()
      ::Create()
   ENDIF
   RETURN Nil

FUNCTION NICEBUTTPROC( hBtn, msg, wParam, lParam )

   LOCAL oBtn
   IF msg != WM_CREATE
      IF AScan( { WM_MOUSEMOVE, WM_PAINT, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK, WM_DESTROY, WM_MOVING, WM_SIZE }, msg ) > 0
         IF ( oBtn := FindSelf( hBtn ) ) == Nil
            RETURN .F.
         ENDIF

         IF msg == WM_PAINT
            oBtn:Paint()
         ELSEIF msg == WM_LBUTTONUP
            oBtn:MUp()
         ELSEIF msg == WM_LBUTTONDOWN
            oBtn:MDown()
         ELSEIF msg == WM_MOUSEMOVE
            oBtn:MouseMove( wParam, lParam )
         ELSEIF msg == WM_SIZE
            oBtn:Size( )

         ELSEIF msg == WM_DESTROY
            oBtn:END()
            RETURN .T.
         ENDIF
      ENDIF

   ENDIF
   RETURN .F.

METHOD Create( ) CLASS HNICEButton

   LOCAL Region
   LOCAL Rct
   LOCAL w
   LOCAL h

   Rct    := GetClientRect( ::handle )
   w      := Rct[ 3 ] - Rct[ 1 ]
   h      := Rct[ 4 ] - Rct[ 2 ]
   Region := CreateRoundRectRgn( 0, 0, w, h, h * 0.90, h * 0.90 )
   SetWindowRgn( ::Handle, Region, .T. )
   InvalidateRect( ::Handle, 0, 0 )

   RETURN Self

METHOD Size( ) CLASS HNICEButton

   ::State := OBTN_NORMAL
   InvalidateRect( ::Handle, 0, 0 )

   RETURN Self

METHOD Moving( ) CLASS HNICEButton

   ::State := .f.
   InvalidateRect( ::Handle, 0, 0 )

   RETURN Self

METHOD MouseMove( wParam, lParam ) CLASS HNICEButton

   LOCAL otmp

   HB_SYMBOL_UNUSED( wParam )
   HB_SYMBOL_UNUSED( lParam )

   IF ::lFlat .AND. ::state != OBTN_INIT
      otmp := SetNiceBtnSelected()

      IF otmp != Nil .AND. otmp:id != ::id .AND. ! otmp:lPress
         otmp:state := OBTN_NORMAL
         InvalidateRect( otmp:handle, 0 )
         PostMessage( otmp:handle, WM_PAINT, 0, 0 )
         SetNiceBtnSelected( Nil )
      ENDIF

      IF ::state == OBTN_NORMAL
         ::state := OBTN_MOUSOVER

         // aBtn[ CTRL_HANDLE ] := hBtn
         InvalidateRect( ::handle, 0 )
         PostMessage( ::handle, WM_PAINT, 0, 0 )
         SetNiceBtnSelected( Self )
      ENDIF
   ENDIF

   RETURN Self

METHOD MUp( ) CLASS HNICEButton

   IF ::state == OBTN_PRESSED
      IF ! ::lPress
         ::state := IIf( ::lFlat, OBTN_MOUSOVER, OBTN_NORMAL )
         InvalidateRect( ::handle, 0 )
         PostMessage( ::handle, WM_PAINT, 0, 0 )
      ENDIF
      IF ! ::lFlat
         SetNiceBtnSelected( Nil )
      ENDIF
      IF ::bClick != Nil
         Eval( ::bClick, ::oParent, ::id )
      ENDIF
   ENDIF

   RETURN Self

METHOD MDown() CLASS HNICEButton

   IF ::state != OBTN_PRESSED
      ::state := OBTN_PRESSED

      InvalidateRect( ::Handle, 0, 0 )
      PostMessage( ::handle, WM_PAINT, 0, 0 )
      SetNiceBtnSelected( Self )
   ENDIF

   RETURN Self

METHOD PAINT() CLASS HNICEButton

   LOCAL ps        := DefinePaintStru()
   LOCAL hDC       := BeginPaint( ::Handle, ps )
   LOCAL Rct
   LOCAL Size
   LOCAL T
   LOCAL XCtr
   LOCAL YCtr
   LOCAL x
   LOCAL y
   LOCAL w
   LOCAL h
   //  *******************

   Rct  := GetClientRect( ::Handle )
   x    := Rct[ 1 ]
   y    := Rct[ 2 ]
   w    := Rct[ 3 ] - Rct[ 1 ]
   h    := Rct[ 4 ] - Rct[ 2 ]
   XCtr := ( Rct[ 1 ] + Rct[ 3 ] ) / 2
   YCtr := ( Rct[ 2 ] + Rct[ 4 ] ) / 2
   T    := GetWindowText( ::Handle )
   // **********************************
   //         Draw our control
   // **********************************

   IF ::state == OBTN_INIT
      ::state := OBTN_NORMAL
   ENDIF

   Size := GetTextSize( hDC, T )

   Draw_Gradient( hDC, x, y, w, h, ::r, ::g, ::b )
   SetBkMode( hDC, TRANSPARENT )

   IF ( ::State == OBTN_MOUSOVER )
      SetTextColor( hDC, VCOLOR( "FF0000" ) )
      TextOut( hDC, XCtr - ( Size[ 1 ] / 2 ) + 1, YCtr - ( Size[ 2 ] / 2 ) + 1, T )
   ELSE
      SetTextColor( hDC, VCOLOR( "0000FF" ) )
      TextOut( hDC, XCtr - Size[ 1 ] / 2, YCtr - Size[ 2 ] / 2, T )
   ENDIF

   EndPaint( ::Handle, ps )

   RETURN Self

METHOD END () CLASS HNiceButton

   RETURN Nil

METHOD RELEASE() CLASS HNiceButton

   ::lPress := .F.
   ::state  := OBTN_NORMAL
   InvalidateRect( ::handle, 0 )
   PostMessage( ::handle, WM_PAINT, 0, 0 )

   RETURN Nil

FUNCTION SetNiceBtnSelected( oBtn )

   LOCAL otmp := HNiceButton() :oSelected

   IF PCount() > 0
      HNiceButton() :oSelected := oBtn
   ENDIF

   RETURN otmp


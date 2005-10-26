/*
 * $Id: hnice.prg,v 1.5 2005-10-26 07:43:26 omm Exp $
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
   Data TEXT, id, nTop, nLeft, nwidth, nheight
   CLASSDATA oSelected INIT Nil
   DATA State INIT 0
   Data ExStyle
   Data bClick, cTooltip

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
              ,, ctooltip )
   DEFAULT g := ::g
   DEFAULT b := ::b

   DEFAULT r := ::r
   ::lFlat  := .t.
   ::bClick := bClick
   ::nOrder  := iif( oWndParent==nil, 0, len( oWndParent:aControls ) )

   ::ExStyle := nStyleEx
   ::text    := cText
   ::r       := r
   ::g       := g
   ::b       := b
   ::nTop    := nTop
   ::nLeft   := nLeft
   ::nwidth  := nwidth
   ::nheight := nheight

   hwg_Regnice()
   ::Activate()

RETURN Self


METHOD Redefine( oWndParent, nId, nStyleEx, ;
                    bInit, bClick, ;
                    cText, cTooltip, r, g, b ) CLASS HNiceButton

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0,, bInit,,, ctooltip )

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

METHOD Activate CLASS HNiceButton

   IF ::oParent:handle != 0
      ::handle := CreateNiceBtn( ::oParent:handle, ::id, ;
                                 ::Style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::ExStyle, ::Text )
      ::Init()
   ENDIF
RETURN Nil

METHOD INIT CLASS HNiceButton

   IF !::lInit
      Super:Init()
      ::Create()
   ENDIF
RETURN Nil

FUNCTION NICEBUTTPROC( hBtn, msg, wParam, lParam )

LOCAL oBtn
   IF msg != WM_CREATE
      IF Ascan( { WM_MOUSEMOVE, WM_PAINT, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK, WM_DESTROY, WM_MOVING, WM_SIZE }, msg ) > 0
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
            oBtn:End()
            RETURN .T.
         ENDIF
      ENDIF

   ENDIF
RETURN .F.

METHOD Create( ) CLASS HNICEButton

   LOCAL Region
   LOCAL Rct
   LOCAL x
   LOCAL y
   LOCAL w
   LOCAL h

   Rct    := GetClientRect( ::handle )
   x      := Rct[ 1 ]
   y      := Rct[ 2 ]
   w      := Rct[ 3 ] - Rct[ 1 ]
   h      := Rct[ 4 ] - Rct[ 2 ]
   Region := CreateRoundRectRgn( 0, 0, w, h, h * 0.90, h * 0.90 )
   SetWindowRgn( ::Handle, Region, .T. )
   InvalidateRect( ::Handle, 0, 0 )

RETURN self

METHOD Size( ) CLASS HNICEButton

   ::State := OBTN_NORMAL
   InvalidateRect( ::Handle, 0, 0 )

RETURN Self

METHOD Moving( ) CLASS HNICEButton

   ::State := .f.
   InvalidateRect( ::Handle, 0, 0 )

RETURN Self

METHOD MouseMove( wParam, lParam ) CLASS HNICEButton

   LOCAL aCoors
   LOCAL xPos
   LOCAL yPos
   LOCAL otmp
   LOCAL res    := .F.

   IF ::lFlat .AND. ::state != OBTN_INIT
      otmp := SetNiceBtnSelected()

      IF otmp != Nil .AND. otmp:id != ::id .AND. !oTmp:lPress
         otmp:state := OBTN_NORMAL
         InvalidateRect( otmp:handle, 0 )
         PostMessage( otmp:handle, WM_PAINT, 0, 0 )
         SetNiceBtnSelected( Nil )
      ENDIF

      aCoors := GetClientRect( ::handle )
      xPos   := LoWord( lParam )
      yPos   := HiWord( lParam )

      IF ::state == OBTN_NORMAL
         ::state := OBTN_MOUSOVER

         // aBtn[ CTRL_HANDLE ] := hBtn
         InvalidateRect( ::handle, 0 )
         PostMessage( ::handle, WM_PAINT, 0, 0 )
         SetNiceBtnSelected( Self )
      ENDIF
   ENDIF

RETURN self

METHOD MUp( ) CLASS HNICEButton

   IF ::state == OBTN_PRESSED
      IF !::lPress
         ::state := Iif( ::lFlat, OBTN_MOUSOVER, OBTN_NORMAL )
         InvalidateRect( ::handle, 0 )
         PostMessage( ::handle, WM_PAINT, 0, 0 )
      ENDIF
      IF !::lFlat
         SetNiceBtnSelected( Nil )
      ENDIF
      IF ::bClick != Nil
         Eval( ::bClick, ::oParent, ::id )
      ENDIF
   ENDIF

RETURN SELF

METHOD MDown() CLASS HNICEButton

   IF ::state != OBTN_PRESSED
      ::state := OBTN_PRESSED

      InvalidateRect( ::Handle, 0, 0 )
      PostMessage( ::handle, WM_PAINT, 0, 0 )
      SetNiceBtnSelected( Self )
   ENDIF

RETURN SELF

METHOD PAINT() CLASS HNICEButton

   LOCAL ps        := DefinePaintStru()
   LOCAL hDC       := BeginPaint( ::Handle, ps )
   LOCAL Rct
   LOCAL Size
   LOCAL T         := Space( 2048 )
   LOCAL i
   LOCAL XCtr
   LOCAL YCtr
   LOCAL x
   LOCAL y
   LOCAL w
   LOCAL h
   LOCAL p
   //  *******************

   Rct  := GetClientRect( ::Handle )
   x    := Rct[ 1 ]
   y    := Rct[ 2 ]
   w    := Rct[ 3 ] - Rct[ 1 ]
   h    := Rct[ 4 ] - Rct[ 2 ]
   XCtr := ( Rct[ 1 ] + Rct[ 3 ] ) / 2
   YCtr := ( Rct[ 2 ] + Rct[ 4 ] ) / 2
   t    := GetWindowText( ::Handle )
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
      p := SetTextColor( hDC, VCOLOR( "FF0000" ) )
      TextOut( hDC, XCtr - ( Size[ 1 ] / 2 ) + 1, YCtr - ( Size[ 2 ] / 2 ) + 1, T )
   ELSE
      p := SetTextColor( hDC, VCOLOR( "0000FF" ) )
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

   IF Pcount() > 0
      HNiceButton() :oSelected := oBtn
   ENDIF

RETURN otmp


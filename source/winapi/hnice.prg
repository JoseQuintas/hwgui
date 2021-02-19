/*
 * $Id$
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
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight,, bInit, ;
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

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0,, bInit,,, cTooltip )

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
      ::handle := hwg_Createnicebtn( ::oParent:handle, ::id, ;
                                 ::Style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::ExStyle, ::Text )
      ::Init()
   ENDIF
   RETURN Nil

METHOD INIT() CLASS HNiceButton

   IF ! ::lInit
      ::Super:Init()
      ::Create()
   ENDIF
   RETURN Nil

FUNCTION hwg_NICEBUTTPROC( hBtn, msg, wParam, lParam )


   LOCAL oBtn
   IF msg != WM_CREATE
      IF AScan( { WM_MOUSEMOVE, WM_PAINT, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK, WM_DESTROY, WM_MOVING, WM_SIZE }, msg ) > 0
         IF ( oBtn := hwg_FindSelf( hBtn ) ) == Nil
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
   
* Not used variables
*   LOCAL x
*   LOCAL y
   
   Rct    := hwg_Getclientrect( ::handle )
*   x      := Rct[ 1 ]
*   y      := Rct[ 2 ]
   w      := Rct[ 3 ] - Rct[ 1 ]
   h      := Rct[ 4 ] - Rct[ 2 ]
   Region := hwg_Createroundrectrgn( 0, 0, w, h, h * 0.90, h * 0.90 )
   hwg_Setwindowrgn( ::Handle, Region, .T. )
   hwg_Invalidaterect( ::Handle, 0, 0 )

   RETURN Self

METHOD Size( ) CLASS HNICEButton

   ::State := OBTN_NORMAL
   hwg_Invalidaterect( ::Handle, 0, 0 )

   RETURN Self

METHOD Moving( ) CLASS HNICEButton

   ::State := .f.
   hwg_Invalidaterect( ::Handle, 0, 0 )

   RETURN Self

METHOD MouseMove( wParam, lParam ) CLASS HNICEButton


   LOCAL otmp

* Not used variables
*     LOCAL aCoors
*     LOCAL xPos
*     LOCAL yPos   

* Not used parameters   
   HB_SYMBOL_UNUSED( wParam )
   HB_SYMBOL_UNUSED( lParam )

   IF ::lFlat .AND. ::state != OBTN_INIT
      otmp := hwg_SetNiceBtnSelected()

      IF otmp != Nil .AND. otmp:id != ::id .AND. ! otmp:lPress
         otmp:state := OBTN_NORMAL
         hwg_Invalidaterect( otmp:handle, 0 )
         hwg_Postmessage( otmp:handle, WM_PAINT, 0, 0 )
         hwg_SetNiceBtnSelected( Nil )
      ENDIF

*      aCoors := hwg_Getclientrect( ::handle )
*      xPos   := hwg_Loword( lParam )
*      yPos   := hwg_Hiword( lParam )

      IF ::state == OBTN_NORMAL
         ::state := OBTN_MOUSOVER

         // aBtn[ CTRL_HANDLE ] := hBtn
         hwg_Invalidaterect( ::handle, 0 )
         hwg_Postmessage( ::handle, WM_PAINT, 0, 0 )
         hwg_SetNiceBtnSelected( Self )
      ENDIF
   ENDIF

   RETURN Self

METHOD MUp( ) CLASS HNICEButton

   IF ::state == OBTN_PRESSED
      IF ! ::lPress
         ::state := IIf( ::lFlat, OBTN_MOUSOVER, OBTN_NORMAL )
         hwg_Invalidaterect( ::handle, 0 )
         hwg_Postmessage( ::handle, WM_PAINT, 0, 0 )
      ENDIF
      IF ! ::lFlat
         hwg_SetNiceBtnSelected( Nil )
      ENDIF
      IF ::bClick != Nil
         Eval( ::bClick, ::oParent, ::id )
      ENDIF
   ENDIF

   RETURN Self

METHOD MDown() CLASS HNICEButton

   IF ::state != OBTN_PRESSED
      ::state := OBTN_PRESSED

      hwg_Invalidaterect( ::Handle, 0, 0 )
      hwg_Postmessage( ::handle, WM_PAINT, 0, 0 )
      hwg_SetNiceBtnSelected( Self )
   ENDIF

   RETURN Self

METHOD PAINT() CLASS HNICEButton

   LOCAL ps        := hwg_Definepaintstru()
   LOCAL hDC       := hwg_Beginpaint( ::Handle, ps )
   LOCAL Rct
   LOCAL Size
   LOCAL XCtr
   LOCAL YCtr
   LOCAL x
   LOCAL y
   LOCAL w
   LOCAL h
   LOCAL T       &&  := Space( 2048 )
   //  *******************

* Variables not used
*
*    LOCAL p
* Preset of variable T with SPACE( 2048 )
* produces:
* Warning W0032  Variable 'T' is assigned but not used in function 'HNICEBUTTON_PAINT(276)'
*

   Rct  := hwg_Getclientrect( ::Handle )
   x    := Rct[ 1 ]
   y    := Rct[ 2 ]
   w    := Rct[ 3 ] - Rct[ 1 ]
   h    := Rct[ 4 ] - Rct[ 2 ]
   XCtr := ( Rct[ 1 ] + Rct[ 3 ] ) / 2
   YCtr := ( Rct[ 2 ] + Rct[ 4 ] ) / 2
   T    := hwg_Getwindowtext( ::Handle )
   // **********************************
   //         Draw our control
   // **********************************

   IF ::state == OBTN_INIT
      ::state := OBTN_NORMAL
   ENDIF

   Size := hwg_Gettextsize( hDC, T )

   hwg_Draw_gradient( hDC, x, y, w, h, ::r, ::g, ::b )
   hwg_Setbkmode( hDC, TRANSPARENT )

   IF ( ::State == OBTN_MOUSOVER )
*      p := hwg_Settextcolor( hDC, hwg_ColorC2N( "FF0000" ) )
      hwg_Settextcolor( hDC, hwg_ColorC2N( "FF0000" ) )
      hwg_Textout( hDC, XCtr - ( Size[ 1 ] / 2 ) + 1, YCtr - ( Size[ 2 ] / 2 ) + 1, T )
   ELSE
*      p := hwg_Settextcolor( hDC, hwg_ColorC2N( "0000FF" ) )
      hwg_Settextcolor( hDC, hwg_ColorC2N( "0000FF" ) )
      hwg_Textout( hDC, XCtr - Size[ 1 ] / 2, YCtr - Size[ 2 ] / 2, T )
   ENDIF

   hwg_Endpaint( ::Handle, ps )

   RETURN Self

METHOD END () CLASS HNiceButton

   RETURN Nil

METHOD RELEASE() CLASS HNiceButton

   ::lPress := .F.
   ::state  := OBTN_NORMAL
   hwg_Invalidaterect( ::handle, 0 )
   hwg_Postmessage( ::handle, WM_PAINT, 0, 0 )

   RETURN Nil

FUNCTION hwg_SetNiceBtnSelected( oBtn )


   LOCAL otmp := HNiceButton() :oSelected

   IF PCount() > 0
      HNiceButton() :oSelected := oBtn
   ENDIF

   RETURN otmp

* =============================== EOF of hnice.prg ===================


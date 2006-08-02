/*
 * $Id: hcontrol.prg,v 1.25 2006-08-02 19:28:58 fsgiudice Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HControl, HStatus, HStatic, HButton, HGroup, HLine classes
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define  CONTROL_FIRST_ID   34000


//- HControl

CLASS HControl INHERIT HCustomWindow

   DATA id
   DATA tooltip
   DATA lInit      INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   METHOD Init()
   METHOD SetColor( tcolor, bColor, lRepaint )
   METHOD NewId()

   METHOD Disable()     INLINE EnableWindow( ::handle, .F. )
   METHOD Enable()      INLINE EnableWindow( ::handle, .T. )
   METHOD IsEnabled()   INLINE IsWindowEnabled( ::Handle )
   METHOD SetFocus()    INLINE ( SendMessage( ::oParent:handle, WM_NEXTDLGCTL, ;
                                              ::handle, 1 ), ;
                                 SetFocus( ::handle  ) )
   METHOD GetText()     INLINE GetWindowText(::handle)
   METHOD SetText( c )  INLINE SetWindowText( ::Handle, c )
   METHOD Refresh()     VIRTUAL
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
            bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HControl

   ::oParent := IIF( oWndParent==NIL, ::oDefaultParent, oWndParent )
   ::id      := IIF( nId == NIL, ::NewId(), nId )
   ::style   := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), ;
                           WS_VISIBLE + WS_CHILD )
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := cTooltip
   ::SetColor( tcolor, bColor )

   ::oParent:AddControl( Self )

RETURN Self

METHOD NewId() CLASS HControl
LOCAL nId := CONTROL_FIRST_ID + Len( ::oParent:aControls )

   IF Ascan( ::oParent:aControls, {|o| o:id == nId } ) != 0
      nId --
      DO WHILE nId >= CONTROL_FIRST_ID .AND. ;
               Ascan( ::oParent:aControls, {|o| o:id == nId } ) != 0
         nId --
      ENDDO
   ENDIF
RETURN nId

METHOD INIT CLASS HControl

   IF !::lInit
      AddToolTip( ::oParent:handle, ::handle, ::tooltip )
      IF ::oFont != NIL
         SetCtrlFont( ::oParent:handle, ::id, ::oFont:handle )
      ELSEIF ::oParent:oFont != NIL
         SetCtrlFont( ::oParent:handle, ::id, ::oParent:oFont:handle )
      ENDIF
      IF ISBLOCK( ::bInit )
         Eval( ::bInit, Self )
      ENDIF
      ::lInit := .T.
   ENDIF
RETURN NIL

METHOD SetColor( tcolor, bColor, lRepaint ) CLASS HControl

   IF tcolor != NIL
      ::tcolor := tcolor
      IF bColor == NIL .AND. ::bColor == NIL
         bColor := GetSysColor( COLOR_3DFACE )
      ENDIF
   ENDIF

   IF bColor != NIL
      ::bColor := bColor
      IF ::brush != NIL
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add( bColor )
   ENDIF

   IF lRepaint != NIL .AND. lRepaint
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

RETURN NIL

METHOD End() CLASS HControl

   Super:End()

   IF ::tooltip != NIL
      DelToolTip( ::oParent:handle, ::handle )
      ::tooltip := NIL
   ENDIF
RETURN NIL


//- HStatus

CLASS HStatus INHERIT HControl

   CLASS VAR winclass   INIT "msctls_statusbar32"

   DATA aParts

   METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint )
   METHOD Activate()
   METHOD Init()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint ) CLASS HStatus

   bSize  := IIF( bSize != NIL, bSize, {|o,x,y| o:Move( 0, y - 20, x, 20 ) } )
   nStyle := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), ;
                        WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + ;
                        WS_CLIPSIBLINGS )
   Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint )

   ::aParts  := aParts

   ::Activate()

RETURN Self

METHOD Activate CLASS HStatus
LOCAL aCoors

   IF ::oParent:handle != 0
      ::handle := CreateStatusWindow( ::oParent:handle, ::id )
      ::Init()
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         aCoors := GetWindowRect( ::handle )
         ::oParent:aOffset[ 4 ] := aCoors[ 4 ] - aCoors[ 2 ]
      ENDIF
   ENDIF
RETURN NIL

METHOD Init CLASS HStatus
   IF !::lInit
      Super:Init()
      hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
   ENDIF
RETURN  NIL

//- HStatic

CLASS HStatic INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
               bColor, lTransp )
   METHOD Redefine( oWndParent, nId, oFont, bInit, ;
                    bSize, bPaint, cTooltip, tcolor, bColor, lTransp )
   METHOD Activate()
   METHOD SetValue( value ) INLINE SetDlgItemText( ::oParent:handle, ::id, ;
                                                   value )
   METHOD Init()
ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
            bColor, lTransp ) CLASS HStatic

   // Enabling style for tooltips
   IF ValType( cTooltip ) == "C"
      IF nStyle == NIL
         nStyle := SS_NOTIFY
      ELSE
         nStyle := Hwg_BitOr( nStyle, SS_NOTIFY )
      ENDIF
   ENDIF

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont,;
              bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption

   IF lTransp != NIL .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF

   ::Activate()

RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, cTooltip, tcolor, bColor, lTransp ) CLASS HStatic

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   // Enabling style for tooltips
   IF ValType( cTooltip ) == "C"
      ::Style := SS_NOTIFY
   ENDIF

   IF lTransp != NIL .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF

RETURN Self

METHOD Activate CLASS HStatic
   IF ::oParent:handle != 0
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::extStyle )
      ::Init()
   ENDIF
RETURN NIL

METHOD Init CLASS HStatic
   IF !::lInit
      Super:init()
      IF ::Title != NIL
         SETWINDOWTEXT( ::handle, ::title )
      ENDIF
   ENDIF
RETURN  NIL

//- HButton

CLASS HButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"

   DATA bClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
               tcolor, bColor )
   METHOD Activate()
   METHOD Redefine( oWnd, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                    tcolor, bColor )
   METHOD Init()
ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
            tcolor, bColor ) CLASS HButton

   nStyle := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), BS_PUSHBUTTON )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
              IIF( nWidth  == NIL, 90, nWidth  ), ;
              IIF( nHeight == NIL, 30, nHeight ), ;
              oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   ::bClick  := bClick
   ::title   := cCaption
   ::Activate()

   IF bClick != NIL
      IF ::oParent:className == "HSTATUS"
         ::oParent:oParent:AddEvent( 0, ::id, bClick )
      ELSE
         ::oParent:AddEvent( 0, ::id, bClick )
      ENDIF
   ENDIF

RETURN Self

METHOD Activate CLASS HButton
   IF ::oParent:handle != 0
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::title )
      ::Init()
   ENDIF
RETURN NIL

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                 cTooltip, tcolor, bColor, cCaption ) CLASS HButton

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip, tcolor, bColor )

   ::title   := cCaption

   IF bClick != NIL
      ::oParent:AddEvent( 0, ::id, bClick )
   ENDIF
RETURN Self

METHOD Init CLASS HButton

   ::super:init()
   IF ::Title != NIL
      SETWINDOWTEXT( ::handle, ::title )
   ENDIF
RETURN  NIL

//- HGroup

CLASS HGroup INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor )
   METHOD Activate()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
            oFont, bInit, bSize, bPaint, tcolor, bColor ) CLASS HGroup

   nStyle := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), BS_GROUPBOX )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
              oFont, bInit, bSize, bPaint,, tcolor, bColor )

   ::title   := cCaption
   ::Activate()

RETURN Self

METHOD Activate CLASS HGroup
   IF ::oParent:handle != 0
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::title )
      ::Init()
   ENDIF
RETURN NIL

// HLine

CLASS HLine INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"

   DATA lVert
   DATA oPenLight, oPenGray

   METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize )
   METHOD Activate()
   METHOD Paint()

ENDCLASS


METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize ) CLASS HLine

   Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop,,,,, ;
              bSize, {|o,lp| o:Paint( lp ) } )

   ::title := ""
   ::lVert := IIF( lVert==NIL, .F., lVert )
   IF ::lVert
      ::nWidth  := 10
      ::nHeight := IIF( nLength == NIL, 20, nLength )
   ELSE
      ::nWidth  := IIF( nLength == NIL, 20, nLength )
      ::nHeight := 10
   ENDIF

   ::oPenLight := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
   ::oPenGray  := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DSHADOW  ) )

   ::Activate()

RETURN Self

METHOD Activate CLASS HLine
   IF ::oParent:handle != 0
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth,::nHeight )
      ::Init()
   ENDIF
RETURN NIL

METHOD Paint( lpdis ) CLASS HLine
LOCAL drawInfo := GetDrawItemInfo( lpdis )
LOCAL hDC := drawInfo[3]
LOCAL x1  := drawInfo[4], y1 := drawInfo[5]
LOCAL x2  := drawInfo[6], y2 := drawInfo[7]

   SelectObject( hDC, ::oPenLight:handle )
   IF ::lVert
      // DrawEdge( hDC,x1,y1,x1+2,y2,EDGE_SUNKEN,BF_RIGHT )
      DrawLine( hDC, x1 + 1, y1, x1 + 1, y2 )
   ELSE
      // DrawEdge( hDC,x1,y1,x2,y1+2,EDGE_SUNKEN,BF_RIGHT )
      DrawLine( hDC, x1 , y1 + 1, x2, y1 + 1 )
   ENDIF

   SelectObject( hDC, ::oPenGray:handle )
   IF ::lVert
      DrawLine( hDC, x1, y1, x1, y2 )
   ELSE
      DrawLine( hDC, x1, y1, x2, y1 )
   ENDIF

RETURN NIL


/*
 * $Id: hcontrol.prg,v 1.22 2005-10-26 07:43:26 omm Exp $
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
   DATA lInit    INIT .F.

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )
   METHOD Init()
   METHOD SetColor( tcolor,bcolor,lRepaint )
   METHOD NewId()

   METHOD Disable() INLINE EnableWindow( ::handle, .F. )
   METHOD Enable()  INLINE EnableWindow( ::handle, .T. )
   METHOD IsEnabled()   INLINE IsWindowEnabled( ::Handle )
   METHOD SetFocus()    INLINE ( SendMessage( ::oParent:handle,WM_NEXTDLGCTL,::handle,1),SetFocus( ::handle  ) )
   METHOD GetText()     INLINE GetWindowText(::handle)
   METHOD SetText( c )  INLINE SetWindowText( ::Handle, c )
   METHOD End()

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor ) CLASS HControl

   ::oParent := Iif( oWndParent==Nil, ::oDefaultParent, oWndParent )
   ::id      := Iif( nId==Nil,::NewId(), nId )
   ::style   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ),WS_VISIBLE+WS_CHILD )
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := ctooltip
   ::SetColor( tcolor,bcolor )

   ::oParent:AddControl( Self )

Return Self

METHOD NewId() CLASS HControl
Local nId := CONTROL_FIRST_ID + Len( ::oParent:aControls )

   IF Ascan( ::oParent:aControls, {|o|o:id==nId} ) != 0
      nId --
      DO WHILE nId >= CONTROL_FIRST_ID .AND. Ascan( ::oParent:aControls, {|o|o:id==nId} ) != 0
         nId --
      ENDDO
   ENDIF
Return nId

METHOD INIT CLASS HControl

   IF !::lInit
      AddToolTip( ::oParent:handle, ::handle, ::tooltip )
      IF ::oFont != Nil
         SetCtrlFont( ::oParent:handle, ::id, ::oFont:handle )
      ELSEIF ::oParent:oFont != Nil
         SetCtrlFont( ::oParent:handle, ::id, ::oParent:oFont:handle )
      ENDIF
      IF ISBLOCK(::bInit)
         Eval( ::bInit, Self )
      ENDIF
      ::lInit := .T.
   ENDIF
RETURN Nil

METHOD SetColor( tcolor,bcolor,lRepaint ) CLASS HControl

   IF tcolor != Nil
      ::tcolor  := tcolor
      IF bColor == Nil .AND. ::bColor == Nil
         bColor := GetSysColor( COLOR_3DFACE )
      ENDIF
   ENDIF

   IF bcolor != Nil
      ::bcolor  := bcolor
      IF ::brush != Nil
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add( bcolor )
   ENDIF

   IF lRepaint != Nil .AND. lRepaint
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

Return Nil

METHOD End() CLASS HControl

   Super:End()
   IF ::tooltip != Nil
      DelToolTip( ::oParent:handle,::handle )
      ::tooltip := Nil
   ENDIF
Return Nil


//- HStatus

CLASS HStatus INHERIT HControl

   CLASS VAR winclass   INIT "msctls_statusbar32"
   DATA aParts
   METHOD New( oWndParent,nId,nStyle,oFont,aParts,bInit,bSize,bPaint )
   METHOD Activate()
   METHOD Init()

ENDCLASS

METHOD New( oWndParent,nId,nStyle,oFont,aParts,bInit,bSize,bPaint ) CLASS HStatus

   bSize := Iif( bSize!=Nil, bSize, {|o,x,y|o:Move(0,y-20,x,20)} )
   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_CHILD+WS_VISIBLE+WS_OVERLAPPED+WS_CLIPSIBLINGS )
   Super:New( oWndParent,nId,nStyle,0,0,0,0,oFont,bInit,bSize,bPaint )

   ::aParts  := aParts

   ::Activate()

Return Self

METHOD Activate CLASS HStatus
Local aCoors

   IF ::oParent:handle != 0
      ::handle := CreateStatusWindow( ::oParent:handle, ::id )
      ::Init()
      IF __ObjHasMsg( ::oParent,"AOFFSET" )
         aCoors := GetWindowRect( ::handle )
         ::oParent:aOffset[4] := aCoors[4] - aCoors[2]
      ENDIF
   ENDIF
Return Nil

METHOD Init CLASS HStatus
   IF !::lInit
      Super:Init()
      hwg_InitStatus( ::oParent:handle, ::handle, Len(::aParts), ::aParts )
   ENDIF
Return  NIL

//- HStatic

CLASS HStatic INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp )
   METHOD Redefine( oWndParent,nId,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp )
   METHOD Activate()
   METHOD SetValue(value) INLINE SetDlgItemText( ::oParent:handle,::id,value )
   METHOD Init()
ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp ) CLASS HStatic

   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::title   := cCaption
   IF lTransp != Nil .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF

   ::Activate()

Return Self

METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp )  CLASS HStatic

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::title   := cCaption
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   IF lTransp != Nil .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF

Return Self

METHOD Activate CLASS HStatic
   IF ::oParent:handle != 0
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle )
      ::Init()
   ENDIF
Return Nil

METHOD Init CLASS HStatic
   IF !::lInit
      Super:init()
      IF ::Title != NIL
         SETWINDOWTEXT( ::handle, ::title )
      ENDIF
   ENDIF
Return  NIL

//- HButton

CLASS HButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,oFont,bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor )
   METHOD Init()
ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor ) CLASS HButton

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), BS_PUSHBUTTON )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,Iif( nWidth==Nil,90,nWidth ),;
              Iif( nHeight==Nil,30,nHeight ),oFont,bInit, ;
              bSize,bPaint,ctooltip,tcolor,bcolor )

   ::title   := cCaption
   ::Activate()

   IF bClick != Nil
      ::oParent:AddEvent( 0,::id,bClick )
   ENDIF

Return Self

METHOD Activate CLASS HButton
   IF ::oParent:handle != 0
      ::handle := CreateButton( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,oFont,bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor,cCaption ) CLASS HButton

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
              bSize,bPaint,ctooltip,tcolor,bcolor )

   ::title   := cCaption

   IF bClick != Nil
      ::oParent:AddEvent( 0,::id,bClick )
   ENDIF
Return Self

METHOD Init CLASS HButton
::super:init()
   IF ::Title != NIL
      SETWINDOWTEXT( ::handle, ::title )
   ENDIF
Return  NIL

//- HGroup

CLASS HGroup INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption, ;
                  oFont,bInit,bSize,bPaint,tcolor,bcolor )
   METHOD Activate()

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption, ;
                  oFont,bInit,bSize,bPaint,tcolor,bcolor ) CLASS HGroup

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), BS_GROUPBOX )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,,tcolor,bcolor )

   ::title   := cCaption
   ::Activate()

Return Self

METHOD Activate CLASS HGroup
   IF ::oParent:handle != 0
      ::handle := CreateButton( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
Return Nil

// hline

CLASS HLine INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA lVert
   DATA oPenLight, oPenGray

   METHOD New( oWndParent,nId,lVert,nLeft,nTop,nLength,bSize )
   METHOD Activate()
   METHOD Paint()

ENDCLASS


METHOD New( oWndParent,nId,lVert,nLeft,nTop,nLength,bSize ) CLASS hline

   Super:New( oWndParent,nId,SS_OWNERDRAW,nLeft,nTop,,,,,bSize,{|o,lp|o:Paint(lp)} )

   ::title := ""
   ::lVert := Iif( lVert==Nil, .F., lVert )
   IF ::lVert
      ::nWidth  := 10
      ::nHeight := Iif( nLength==Nil,20,nLength )
   ELSE
      ::nWidth  := Iif( nLength==Nil,20,nLength )
      ::nHeight := 10
   ENDIF

   ::oPenLight := HPen():Add( BS_SOLID,1,GetSysColor(COLOR_3DHILIGHT) )
   ::oPenGray  := HPen():Add( BS_SOLID,1,GetSysColor(COLOR_3DSHADOW) )

   ::Activate()

Return Self

METHOD Activate CLASS hline
   IF ::oParent:handle != 0
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth,::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Paint( lpdis ) CLASS hline
Local drawInfo := GetDrawItemInfo( lpdis )
Local hDC := drawInfo[3], x1 := drawInfo[4], y1 := drawInfo[5], x2 := drawInfo[6], y2 := drawInfo[7]

   SelectObject( hDC, ::oPenLight:handle )
   IF ::lVert
      // DrawEdge( hDC,x1,y1,x1+2,y2,EDGE_SUNKEN,BF_RIGHT )
      DrawLine( hDC, x1+1,y1,x1+1,y2 )
   ELSE
      // DrawEdge( hDC,x1,y1,x2,y1+2,EDGE_SUNKEN,BF_RIGHT )
      DrawLine( hDC, x1,y1+1,x2,y1+1 )
   ENDIF

   SelectObject( hDC, ::oPenGray:handle )
   IF ::lVert
      DrawLine( hDC, x1,y1,x1,y2 )
   ELSE
      DrawLine( hDC, x1,y1,x2,y1 )
   ENDIF

Return Nil


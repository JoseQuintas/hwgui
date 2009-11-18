/*
 * $Id: hrect.prg,v 1.14 2009-11-18 02:24:34 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level class HRect (Panel)
 *
 * Copyright 2004 Ricardo de Moura Marques <ricardo.m.marques@caixa.gov.br>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"




//-----------------------------------------------------------------
CLASS HRect INHERIT HControl

   DATA oLine1
   DATA oLine2
   DATA oLine3
   DATA oLine4

   METHOD New( oWndParent, nLeft, nTop, nRight, nBottom, lPress, nStyle )


ENDCLASS

//----------------------------------------------------------------
METHOD New( oWndParent, nLeft, nTop, nRight, nBottom, lPress, nStyle ) CLASS HRect
   LOCAL nCor1, nCor2

   IF nStyle = NIL
      nStyle := 3
   ENDIF
   nCor1 := COLOR_3DHILIGHT
   IF lPress
      nCor2 := COLOR_3DHILIGHT
      nCor1 := COLOR_3DSHADOW
   ELSE
      nCor1 := COLOR_3DHILIGHT
      nCor2 := COLOR_3DSHADOW
   ENDIF

   DO CASE
   CASE nStyle = 1
      ::oLine1 = HRect_Line():New( oWndParent, , .f., nLeft,  nTop,    nRight - nLeft, , nCor1 )
      ::oLine3 = HRect_Line():New( oWndParent, , .f., nLeft,  nBottom, nRight - nLeft, , nCor2 )

   CASE nStyle = 2
      ::oLine2 = HRect_Line():New( oWndParent, , .t., nLeft,  nTop,    nBottom - nTop, , nCor1 )
      ::oLine4 = HRect_Line():New( oWndParent, , .t., nRight, nTop,    nBottom - nTop, , nCor2 )

   OTHERWISE
      ::oLine1 = HRect_Line():New( oWndParent, , .f., nLeft,  nTop,    nRight - nLeft, , nCor1 )
      ::oLine2 = HRect_Line():New( oWndParent, , .t., nLeft,  nTop,    nBottom - nTop, , nCor1 )
      ::oLine3 = HRect_Line():New( oWndParent, , .f., nLeft,  nBottom, nRight - nLeft, , nCor2 )
      ::oLine4 = HRect_Line():New( oWndParent, , .t., nRight, nTop,    nBottom - nTop, , nCor2 )
   ENDCASE

   RETURN Self

//---------------------------------------------------------------------------
CLASS HRect_Line INHERIT HControl

CLASS VAR winclass   INIT "STATIC"
   DATA lVert
   DATA oPen

   METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize, nColor )
   METHOD Activate()
   METHOD Paint()

ENDCLASS


//---------------------------------------------------------------------------
METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize, nColor ) CLASS HRect_Line

   Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop,,,,, bSize, { | o, lp | o:Paint( lp ) } )


   ::title := ""
   ::lVert := IIf( lVert == Nil, .F., lVert )
   IF ::lVert
      ::nWidth  := 10
      ::nHeight := IIf( nLength == Nil, 20, nLength )
   ELSE
      ::nWidth  := IIf( nLength == Nil, 20, nLength )
      ::nHeight := 10
   ENDIF
   ::oPen := HPen():Add( BS_SOLID, 1, GetSysColor( nColor ) )

   ::Activate()

   RETURN Self

//---------------------------------------------------------------------------
METHOD Activate CLASS HRect_Line
   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

//---------------------------------------------------------------------------
METHOD Paint( lpdis ) CLASS HRect_Line
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ], x1 := drawInfo[ 4 ], y1 := drawInfo[ 5 ], x2 := drawInfo[ 6 ], y2 := drawInfo[ 7 ]


   SelectObject( hDC, ::oPen:handle )

   IF ::lVert
      DrawLine( hDC, x1, y1, x1, y2 )
   ELSE
      DrawLine( hDC, x1, y1, x2, y1 )
   ENDIF


   RETURN Nil


//Contribution   Luis Fernando Basso

CLASS HShape INHERIT HControl

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, nBorder, nCurvature, ;
               nbStyle, nfStyle, tcolor, bcolor, bSize, bInit, nBackStyle )  //, bClick, bDblClick)

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, nBorder, nCurvature, ;
            nbStyle, nfStyle, tcolor, bcolor, bSize, bInit, nBackStyle ) CLASS HShape

   nBorder := IIf( nBorder = Nil, 1, nBorder )
   nbStyle := IIf( nbStyle = Nil, PS_SOLID, nbStyle )
   nfStyle := IIf( nfStyle = Nil, BS_TRANSPARENT , nfStyle )
   nCurvature := nCurvature

   Self := HDrawShape():New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, bSize, tcolor, bcolor,,, ;
                             nBorder, nCurvature, nbStyle, nfStyle, bInit, nBackStyle )

   RETURN Self

//---------------------------------------------------------------------------

CLASS HLContainer INHERIT HControl

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, nStyle, bSize, lnoBorder, bInit )  //, bClick, bDblClick)

ENDCLASS


METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, nStyle, bSize, lnoBorder, bInit ) CLASS HLContainer

   nStyle := IIf( nStyle = NIL, 3, nStyle )  // FLAT
   lnoBorder := IIf( lnoBorder = NIL, .F., lnoBorder )  // FLAT

   Self := HDrawShape():New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, bSize,,, nStyle, lnoBorder,,,,, bInit ) //,bClick, bDblClick)

   RETURN Self


//---------------------------------------------------------------------------

CLASS HDrawShape INHERIT HControl

CLASS VAR winclass   INIT "STATIC"
   DATA oPen, oBrush
   DATA ncStyle, nbStyle, nfStyle
   DATA nCurvature
   DATA nBorder, lnoBorder
   DATA brushFill
   DATA bClick, bDblClick

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, bSize, tcolor, bColor, nStyle, ;
               lnoBorder, nBorder, nCurvature, nbStyle, nfStyle, bInit, bClick, bDblClick, nBackStyle )

   METHOD Activate()
   METHOD Paint( lDsip )
   METHOD SetColor( tcolor, bcolor )
   METHOD Curvature( nCurvature )
   //METHOD Refresh() INLINE SENDMESSAGE( ::handle, WM_PAINT, 0, 0 ), RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )

ENDCLASS


METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, bSize, tcolor, bColor, ncStyle, ;
            lnoBorder, nBorder, nCurvature, nbStyle, nfStyle, bInit, nBackStyle )  CLASS HDrawShape

   HB_SYMBOL_UNUSED( ncStyle )

   ::bPaint   := { | o, p | o:paint( p ) }
   Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, ,;
              bInit, bSize, ::bPaint, , tcolor, bColor ) //= Nil

   ::title := ""
   ::backStyle := IIF( nbackStyle = Nil, 1, nbackStyle ) // OPAQUE DEFAULT

   ::lnoBorder := lnoBorder
   ::nBorder := nBorder
   ::nbStyle := nbStyle
   ::nfStyle := nfStyle
   ::nCurvature := nCurvature
   ::SetColor( ::tcolor , ::bColor )

   ::Activate()

   IF ::ncStyle == Nil
      ::oPen := HPen():Add( ::nbStyle, ::nBorder, ::tColor )
   //ELSE  // CONTAINER
   //    ::oPen := HPen():Add( PS_SOLID, 5, GetSysColor( COLOR_3DHILIGHT ) )
   ENDIF

  RETURN Self

//---------------------------------------------------------------------------

METHOD Activate CLASS HDrawShape
   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil


METHOD SetColor( tcolor, bColor ) CLASS HDrawShape

   Super:SetColor( tColor, bColor )
   IF ::nfStyle = HS_SOLID .OR. ( ::nfStyle != BS_TRANSPARENT .OR. ::backStyle = 1 )
       IF !EMPTY( ::tColor ) .AND. ::nfStyle != HS_SOLID
         ::brushFill := HBrush():Add( ::tColor, ::nfstyle )
      ELSE
         ::brushFill := HBrush():Add( , ::nfstyle )
      ENDIF
   ENDIF
   //SENDMESSAGE( ::handle, WM_PAINT, 0, 0 )
   RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   RETURN Nil


METHOD Curvature( nCurvature ) CLASS HDrawShape

   IF nCurvature != NIL
      ::nCurvature := nCurvature
      SENDMESSAGE( ::handle, WM_PAINT, 0, 0 )
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF
   RETURN Nil

//---------------------------------------------------------------------------
METHOD Paint( lpdis ) CLASS HDrawShape
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ], oBrush
   LOCAL  x1 := drawInfo[ 4 ], y1 := drawInfo[ 5 ]
   LOCAL  x2 := drawInfo[ 6 ], y2 := drawInfo[ 7 ]

   SelectObject( hDC, ::oPen:handle )
   IF ::ncStyle != Nil
      /*
      IF ::lnoBorder = .F.
         IF ::ncStyle == 0      // RAISED
            DrawEdge( hDC, x1, y1, x2, y2, BDR_RAISED, BF_LEFT + BF_TOP + BF_RIGHT + BF_BOTTOM )  // raised  forte      8
         ELSEIF ::ncStyle == 1  // sunken
            DrawEdge( hDC, x1, y1, x2, y2, BDR_SUNKEN, BF_LEFT + BF_TOP + BF_RIGHT + BF_BOTTOM ) // sunken mais forte
         ELSEIF ::ncStyle == 2  // FRAME
            DrawEdge( hDC, x1, y1, x2, y2, BDR_RAISED + BDR_RAISEDOUTER, BF_LEFT + BF_TOP + BF_RIGHT + BF_BOTTOM ) // FRAME
         ELSE                   // FLAT
            DrawEdge( hDC, x1, y1, x2, y2, BDR_SUNKENINNER, BF_TOP )
            DrawEdge( hDC, x1, y1, x2, y2, BDR_RAISEDOUTER, BF_BOTTOM )
            DrawEdge( hDC, x1, y2, x2, y1, BDR_SUNKENINNER, BF_LEFT )
            DrawEdge( hDC, x1, y2, x2, y1, BDR_RAISEDOUTER, BF_RIGHT )
         ENDIF
      ELSE
         DrawEdge( hDC, x1, y1, x2, y2, 0, 0 )
      ENDIF
      */
   ELSE
      SetBkMode( hDC, ::backStyle )
      IF ::backStyle != 0
         SelectObject( hDC, ::Brush:Handle )
         RoundRect( hDC, x1 + 1, y1 + 1, x2, y2 , ::nCurvature, ::nCurvature)
      ELSE
        oBrush :=  HBrush():Add( GetBackColorParent( Self ) )
        SelectObject( hDC, oBrush:Handle )
        DeleteObject( oBrush )
      ENDIF
      IF ::nfStyle = HS_SOLID .OR. ( ::nfStyle != BS_TRANSPARENT  .OR. ::backStyle = 1 )
         SelectObject( hDC, ::BrushFill:Handle )
         RoundRect( hDC, x1 + 1, y1 + 1, x2 , y2, ::nCurvature, ::nCurvature )
      ELSE
         RoundRect( hDC, x1 + 1, y1 + 1, x2, y2 , ::nCurvature, ::nCurvature)
      ENDIF
   ENDIF
   RETURN 0

// END NEW CLASSE


//-----------------------------------------------------------------
FUNCTION Rect( oWndParent, nLeft, nTop, nRight, nBottom, lPress, nST )

   IF lPress = NIL
      lPress := .f.
   ENDIF

   RETURN  HRect():New( oWndParent, nLeft, nTop, nRight, nBottom, lPress, nST )


//---------------------------------------------------------------------------


CLASS HContainer INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA oPen, oBrush
   DATA ncStyle   INIT 3
   DATA nBorder
   DATA lnoBorder INIT .T.
   DATA bLoad
   DATA bClick, bDblClick

   DATA lCreate   INIT .F.
   DATA xVisible  INIT .T. HIDDEN

   METHOD New( oWndParent, nId, nstyle, nLeft, nTop, nWidth, nHeight, ncStyle, bSize,;
               lnoBorder, bInit, nBackStyle, tcolor, bcolor, bLoad, bRefresh, bOther)  //, bClick, bDblClick)

   METHOD Activate()
   METHOD Init()
   METHOD Create( ) INLINE ::lCreate := .T.
   METHOD onEvent( msg, wParam, lParam )
   METHOD Paint( lpDisp )
   METHOD Visible( lvisible ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ncStyle, bSize,;
            lnoBorder, bInit, nBackStyle, tcolor, bcolor, bLoad, bRefresh, bOther) CLASS HContainer  //, bClick, bDblClick)

    ::bPaint   := { | o, p | o:paint( p ) }
    nStyle := SS_OWNERDRAW + IIF( nStyle = WS_TABSTOP, WS_TABSTOP , 0 ) + Hwg_Bitand( nStyle, SS_NOTIFY )
    Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, , ;
              bInit, bSize, ::bPaint,, tcolor, bColor )

   ::title := ""
   ::ncStyle := IIF( ncStyle = NIL .AND. nStyle < WS_TABSTOP, 3, ncStyle )
   ::lnoBorder := IIF( lnoBorder = NIL, .F., lnoBorder )

   ::backStyle := IIF( nbackStyle = Nil, 1, nbackStyle ) // OPAQUE DEFAULT
   ::bLoad := bLoad
   ::bRefresh := bRefresh
   ::bOther := bOther

   ::SetColor( ::tColor, ::bColor )
   ::Activate()
   IF ::bLoad != Nil
     // SET ENVIRONMENT
       Eval( ::bLoad,Self )
   ENDIF
   ::oPen := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )

  Return Self

//---------------------------------------------------------------------------
METHOD Activate CLASS HContainer

   IF !Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight )
      IF ! ::lInit
         AddToolTip( ::handle, ::handle, "" )
         ::nHolder := 1
         SetWindowObject( ::handle, Self )
         Hwg_InitStaticProc( ::handle )
         ::linit := .T.
         IF Empty( ::oParent:oParent ) .AND. ::oParent:Type >= WND_DLG_RESOURCE
            ::Create()
            ::lCreate := .T.
         ENDIF
      ENDIF
      ::Init()
   ENDIF
   IF ! ::lCreate
      ::Create()
      ::lCreate := .T.
   ENDIF
   RETURN Nil

METHOD Init CLASS HContainer

   IF ! ::lInit
      Super:init()
      AddToolTip( ::handle, ::handle, "" )
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitStaticProc( ::handle )
      //SetWindowPos( ::Handle, HWND_BOTTOM, 0, 0, 0, 0 , SWP_NOSIZE + SWP_NOMOVE + SWP_NOZORDER)
   ENDIF
   RETURN  NIL


METHOD onEvent( msg, wParam, lParam ) CLASS HContainer
   Local nEval

   IF ::bOther != Nil
      IF ( nEval := Eval( ::bOther,Self,msg,wParam,lParam ) ) != Nil .AND. nEval != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_PAINT
      RETURN - 1
   ELSEIF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg == WM_SETFOCUS
     GetSkip( ::oparent, ::handle, , ::nGetSkip )
   ELSEIF msg == WM_KEYUP
       IF wParam = VK_DOWN
          GetSkip( ::oparent, ::handle, , 1 )
       ELSEIF  wParam = VK_UP
          GetSkip( ::oparent, ::handle, , -1 )
       ELSEIF wParam = VK_TAB
          GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
       ENDIF
       RETURN 0
   ELSEIF msg = WM_SYSKEYUP
   ENDIF
   RETURN Super:onEvent( msg, wParam, lParam )

METHOD Visible( lVisibled ) CLASS HContainer

    IF lVisibled != Nil
      IF lVisibled
        ::Show()
      ELSE
        ::Hide()
      ENDIF
      ::xVisible := lVisibled
   ENDIF
   RETURN ::xVisible


//---------------------------------------------------------------------------
METHOD Paint( lpdis ) CLASS HContainer
   Local pps, drawInfo, hDC
   Local aCoors, x1, y1, x2, y2

    drawInfo := GetDrawItemInfo( lpdis )
    hDC := drawInfo[ 3 ]
    x1  := drawInfo[ 4 ]
    y1  := drawInfo[ 5 ]
    x2  := drawInfo[ 6 ]
    y2  := drawInfo[ 7 ]

   SelectObject( hDC, ::oPen:handle )

   IF ::ncStyle != Nil
      SetBkMode( hDC, ::backStyle )
      IF ! ::lnoBorder
         IF ::ncStyle == 0      // RAISED
           DrawEdge( hDC, x1, y1, x2, y2,BDR_RAISED,BF_LEFT+BF_TOP+BF_RIGHT+BF_BOTTOM)  // raised  forte      8
         ELSEIF ::ncStyle == 1  // sunken
           DrawEdge( hDC, x1, y1, x2, y2,BDR_SUNKEN,BF_LEFT+BF_TOP+BF_RIGHT+BF_BOTTOM ) // sunken mais forte
         ELSEIF ::ncStyle == 2  // FRAME
           DrawEdge( hDC, x1, y1, x2, y2,BDR_RAISED+BDR_RAISEDOUTER,BF_LEFT+BF_TOP+BF_RIGHT+BF_BOTTOM) // FRAME
         ELSE                   // FLAT
           DrawEdge( hDC, x1, y1, x2, y2,BDR_SUNKENINNER,BF_TOP)
           DrawEdge( hDC, x1, y1, x2, y2,BDR_RAISEDOUTER,BF_BOTTOM)
           DrawEdge( hDC, x1, y2, x2, y1,BDR_SUNKENINNER,BF_LEFT)
           DrawEdge( hDC, x1, y2, x2, y1,BDR_RAISEDOUTER,BF_RIGHT)
         ENDIF
      ELSE
         DrawEdge( hDC, x1, y1, x2, y2,0,0)
      ENDIF
      IF ::backStyle != 0
         IF ::Brush != Nil
            FillRect( hDC, x1 + 2, y1 + 2, x2 - 2, y2 - 2 , ::brush:handle )
         ELSE
            FillRect( hDC, x1 + 2, y1 + 2, x2 - 2, y2 - 2 , GetStockObject( 5 ) )
         ENDIF
      ENDIF
      SetBkMode( hDC, 0 )
   ENDIF

   Return 1

// END NEW CLASSE


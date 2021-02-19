/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level class HRect (Panel)
 *
 * Copyright 2004 Ricardo de Moura Marques <ricardo.m.marques@caixa.gov.br>
*/

#include "windows.ch"
#include "hbclass.ch"

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
   METHOD Paint( lpdis )

ENDCLASS


//---------------------------------------------------------------------------
METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize, nColor ) CLASS HRect_Line

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop,,,,, bSize, { | o, lp | o:Paint( lp ) } )


   ::title := ""
   ::lVert := IIf( lVert == Nil, .F., lVert )
   IF ::lVert
      ::nWidth  := 10
      ::nHeight := IIf( nLength == Nil, 20, nLength )
   ELSE
      ::nWidth  := IIf( nLength == Nil, 20, nLength )
      ::nHeight := 10
   ENDIF
   ::oPen := HPen():Add( BS_SOLID, 1, hwg_Getsyscolor( nColor ) )

   ::Activate()

   RETURN Self

//---------------------------------------------------------------------------
METHOD Activate() CLASS HRect_Line
   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

//---------------------------------------------------------------------------
METHOD Paint( lpdis ) CLASS HRect_Line
   LOCAL drawInfo := hwg_Getdrawiteminfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ], x1 := drawInfo[ 4 ], y1 := drawInfo[ 5 ], x2 := drawInfo[ 6 ], y2 := drawInfo[ 7 ]


   hwg_Selectobject( hDC, ::oPen:handle )

   IF ::lVert
      hwg_Drawline( hDC, x1, y1, x1, y2 )
   ELSE
      hwg_Drawline( hDC, x1, y1, x2, y1 )
   ENDIF


   RETURN Nil


//Contribution   Luis Fernando Basso

CLASS HShape INHERIT HControl

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, nBorder, nCurvature, ;
               nbStyle, nfStyle, tcolor, bcolor, bSize, bInit )  //, bClick, bDblClick)

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, nBorder, nCurvature, ;
            nbStyle, nfStyle, tcolor, bcolor, bSize, bInit ) CLASS HShape

   /* Variable Self is reserved and cannot be overwritten ! */
   LOCAL oSelf

   nBorder := IIf( nBorder = Nil, 1, nBorder )
   nbStyle := IIf( nbStyle = Nil, PS_SOLID, nbStyle )
   nfStyle := IIf( nfStyle = Nil, BS_TRANSPARENT , nfStyle )
   nCurvature := nCurvature

   /* old : Self := ... */
   oSelf := HDrawShape():New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, bSize, tcolor, bcolor,,, ;
                             nBorder, nCurvature, nbStyle, nfStyle, bInit )

   RETURN oSelf

//---------------------------------------------------------------------------

CLASS HContainer INHERIT HControl

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, nStyle, bSize, lnoBorder, bInit )  //, bClick, bDblClick)

ENDCLASS


METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, nStyle, bSize, lnoBorder, bInit ) CLASS HContainer

   LOCAL oSelf

   nStyle := IIf( nStyle = NIL, 3, nStyle )  // FLAT
   lnoBorder := IIf( lnoBorder = NIL, .F., lnoBorder )  // FLAT

   oSelf := HDrawShape():New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, bSize,,, nStyle, lnoBorder,,,,, bInit ) //,bClick, bDblClick)

   RETURN oSelf


//---------------------------------------------------------------------------

CLASS HDrawShape INHERIT HControl

CLASS VAR winclass   INIT "STATIC"
   DATA oPen, oBrush
   DATA ncStyle, nbStyle, nfStyle
   DATA nCurvature
   DATA nBorder, lnoBorder
   DATA ntColor, nbColor
   DATA bClick, bDblClick

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, bSize, tcolor, bColor, ncStyle, ;
               lnoBorder, nBorder, nCurvature, nbStyle, nfStyle, bInit )

   METHOD Activate()
   METHOD Paint(lpdis)
   METHOD SetColor( tcolor, bcolor )
   METHOD Curvature( nCurvature )
   // METHOD onClick()
   // METHOD onDblClick()

ENDCLASS

/* nStyle ==> ncStyle , removed: bClick, bDblClick */
METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, bSize, tcolor, bColor, ncStyle, ;
            lnoBorder, nBorder, nCurvature, nbStyle, nfStyle, bInit ) CLASS HDrawShape

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop,,,, bInit, bSize, { | o, lp | o:Paint( lp ) } )

   ::title := ""
   ::ncStyle :=  ncStyle  //0 -raised ,1-sunken 2-flat
   ::nLeft := nLeft
   ::nTop := nTop
   ::nWidth := nWidth
   ::nHeight := nHeight
   tcolor := IIf( tcolor = Nil, 0, tcolor )
   bColor := IIf( bColor = Nil, hwg_Getsyscolor( COLOR_BTNFACE )  , bColor )
   ::lnoBorder := lnoBorder
   ::nBorder := nBorder
   ::nbStyle := nbStyle
   ::nfStyle := nfStyle
   ::nCurvature := nCurvature
   ::Activate()
   // brush somente para os SHAPE
   ::nbcolor := bColor
   ::ntColor := tcolor
   IF ncStyle == Nil
      ::oPen := HPen():Add( ::nbStyle, ::nBorder, tcolor )
   ELSE  // CONTAINER
      ::oPen := HPen():Add( PS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
   ENDIF

   RETURN Self

//---------------------------------------------------------------------------
METHOD Activate() CLASS HDrawShape
   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD SetColor( tcolor, bColor ) CLASS HDrawShape

   IF tcolor != NIL
      ::ntcolor := tcolor
   ENDIF
   IF bColor != NIL
      ::nbColor := bColor
      IF ::obrush != NIL
         ::obrush:Release()
      ENDIF
   ENDIF
   hwg_Sendmessage( ::handle, WM_PAINT, 0, 0 )
   hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE )

   RETURN Nil

METHOD Curvature( nCurvature ) CLASS HDrawShape

   IF nCurvature != NIL
      ::nCurvature := nCurvature
      hwg_Sendmessage( ::handle, WM_PAINT, 0, 0 )
      hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF
   RETURN Nil

//---------------------------------------------------------------------------
METHOD Paint( lpdis ) CLASS HDrawShape
   LOCAL drawInfo := hwg_Getdrawiteminfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ], oBrush
   LOCAL  x1 := drawInfo[ 4 ], y1 := drawInfo[ 5 ]
   LOCAL  x2 := drawInfo[ 6 ], y2 := drawInfo[ 7 ]

   hwg_Selectobject( hDC, ::oPen:handle )
   IF ::ncStyle != Nil
      IF ::lnoBorder = .F.
         IF ::ncStyle == 0      // RAISED
            hwg_Drawedge( hDC, x1, y1, x2, y2, BDR_RAISED, BF_LEFT + BF_TOP + BF_RIGHT + BF_BOTTOM )  // raised  forte      8
         ELSEIF ::ncStyle == 1  // sunken
            hwg_Drawedge( hDC, x1, y1, x2, y2, BDR_SUNKEN, BF_LEFT + BF_TOP + BF_RIGHT + BF_BOTTOM ) // sunken mais forte
         ELSEIF ::ncStyle == 2  // FRAME
            hwg_Drawedge( hDC, x1, y1, x2, y2, BDR_RAISED + BDR_RAISEDOUTER, BF_LEFT + BF_TOP + BF_RIGHT + BF_BOTTOM ) // FRAME
         ELSE                   // FLAT
            hwg_Drawedge( hDC, x1, y1, x2, y2, BDR_SUNKENINNER, BF_TOP )
            hwg_Drawedge( hDC, x1, y1, x2, y2, BDR_RAISEDOUTER, BF_BOTTOM )
            hwg_Drawedge( hDC, x1, y2, x2, y1, BDR_SUNKENINNER, BF_LEFT )
            hwg_Drawedge( hDC, x1, y2, x2, y1, BDR_RAISEDOUTER, BF_RIGHT )
         ENDIF
      ELSE
         hwg_Drawedge( hDC, x1, y1, x2, y2, 0, 0 )
      ENDIF
   ELSE
      hwg_Setbkmode( hDC, 1 )
      oBrush := HBrush():Add( ::nbColor )
      hwg_Selectobject( hDC, oBrush:handle )
      hwg_Roundrect( hDC, x1, y1, x2, y2 , ::nCurvature, ::nCurvature )
      IF ::nfStyle != BS_TRANSPARENT
         hwg_Setbkmode( hDC, 0 )
         oBrush := HBrush():Add( ::ntColor, ::nfstyle )
         hwg_Selectobject( hDC, oBrush:handle )
         hwg_Roundrect( hDC, x1, y1, x2, y2 , ::nCurvature, ::nCurvature )
      ENDIF
   ENDIF
   RETURN Nil

// END NEW CLASSE


//-----------------------------------------------------------------
FUNCTION hwg_Rect( oWndParent, nLeft, nTop, nRight, nBottom, lPress, nST )


   IF lPress = NIL
      lPress := .f.
   ENDIF

   RETURN  HRect():New( oWndParent, nLeft, nTop, nRight, nBottom, lPress, nST )

* ================================== EOF of hrect.prg =====================================


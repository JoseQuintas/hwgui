/*
 * $Id: hrect.prg,v 1.6 2008-09-01 19:00:20 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level class HRect (Panel)
 *
 * Copyright 2004 Ricardo de Moura Marques <ricardo.m.marques@caixa.gov.br>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"

//-----------------------------------------------------------------
CLASS HRect INHERIT HControl

 DATA oLine1
 DATA oLine2
 DATA oLine3
 DATA oLine4

 METHOD New(oWndParent,nLeft,nTop,nRight,nBottom, lPress, nStyle)


ENDCLASS

//----------------------------------------------------------------
METHOD New(oWndParent,nLeft,nTop,nRight,nBottom, lPress, nStyle) Class HRect
Local nCor1, nCor2

  if nStyle = NIL
     nStyle := 3
  endif
     nCor1 := COLOR_3DHILIGHT
  if lPress
     nCor2 := COLOR_3DHILIGHT
     nCor1 := COLOR_3DSHADOW
  else
     nCor1 := COLOR_3DHILIGHT
     nCor2 := COLOR_3DSHADOW
  endif

  do case
    case nStyle = 1
       ::oLine1 = HRect_Line():New( oWndParent, ,.f., nLeft,  nTop,    nRight-nLeft, , nCor1 )
       ::oLine3 = HRect_Line():New( oWndParent, ,.f., nLeft,  nBottom, nRight-nLeft, , nCor2 )

    case nStyle = 2
       ::oLine2 = HRect_Line():New( oWndParent, ,.t., nLeft,  nTop,    nBottom-nTop, , nCor1 )
       ::oLine4 = HRect_Line():New( oWndParent, ,.t., nRight, nTop,    nBottom-nTop, , nCor2 )

    OtherWise
       ::oLine1 = HRect_Line():New( oWndParent, ,.f., nLeft,  nTop,    nRight-nLeft, , nCor1 )
       ::oLine2 = HRect_Line():New( oWndParent, ,.t., nLeft,  nTop,    nBottom-nTop, , nCor1 )
       ::oLine3 = HRect_Line():New( oWndParent, ,.f., nLeft,  nBottom, nRight-nLeft, , nCor2 )
       ::oLine4 = HRect_Line():New( oWndParent, ,.t., nRight, nTop,    nBottom-nTop, , nCor2 )
  endcase

Return Self

//---------------------------------------------------------------------------
CLASS HRect_Line INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA lVert
   DATA oPen

   METHOD New( oWndParent,nId,lVert,nLeft,nTop, nLength,bSize, nColor )
   METHOD Activate()
   METHOD Paint()

ENDCLASS


//---------------------------------------------------------------------------
METHOD New( oWndParent,nId,lVert,nLeft,nTop, nLength,bSize, nColor ) CLASS HRect_Line

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
   ::oPen := HPen():Add( BS_SOLID,1,GetSysColor(nColor) )

   ::Activate()

Return Self

//---------------------------------------------------------------------------
METHOD Activate CLASS HRect_Line
   IF !empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth,::nHeight )
      ::Init()
   ENDIF
Return Nil

//---------------------------------------------------------------------------
METHOD Paint( lpdis ) CLASS HRect_Line
Local drawInfo := GetDrawItemInfo( lpdis )
Local hDC := drawInfo[3], x1 := drawInfo[4], y1 := drawInfo[5], x2 := drawInfo[6], y2 := drawInfo[7]


   SelectObject( hDC, ::oPen:handle )

   IF ::lVert
      DrawLine( hDC, x1,y1,x1,y2 )
   ELSE
      DrawLine( hDC, x1,y1,x2,y1 )
   ENDIF


Return Nil


//Contribution   Luis Fernando Basso

CLASS HShape INHERIT HControl

  METHOD New(oWndParent,nId,nLeft,nTop,nWidth,nHeight, nBorder, nCurvature,;
              nbStyle, nfStyle, tcolor, bcolor, bSize)

ENDCLASS

METHOD New(oWndParent,nId,nLeft,nTop,nWidth,nHeight, nBorder, nCurvature,;
              nbStyle, nfStyle, tcolor, bcolor, bSize) Class HShape

    nBorder := IIF(nBorder = Nil, 1, nBorder)
   nbStyle := IIF(nbStyle = Nil, PS_SOLID, nbStyle )
   nfStyle := IIF(nfStyle = Nil, BS_TRANSPARENT , nfStyle )
   nCurvature := nCurvature

   Self := HDrawShape():New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,bSize,tColor,bColor,,,;
                                nBorder, nCurvature, nbStyle, nfStyle)

Return Self

//---------------------------------------------------------------------------

CLASS HContainer INHERIT HControl

   METHOD New( oWndParent,nId, nLeft, nTop, nWidth, nHeight, nStyle, bSize, lnoBorder )

ENDCLASS

METHOD New(oWndParent,nId,nLeft,nTop,nWidth,nHeight, nStyle,bSize, lnoBorder) Class HContainer

   nStyle := IIF(nStyle = NIL, 3, nStyle)  // FLAT
   lnoBorder := IIF(lnoBorder = NIL, .F., lnoBorder)  // FLAT

   Self := HDrawShape():New( oWndParent,nId, nLeft, nTop, nWidth, nHeight, bSize,,,nStyle, lnoBorder,,,,)

Return Self


//---------------------------------------------------------------------------

CLASS HDrawShape INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA oPen, oBrush
   DATA ncStyle, nbStyle, nfStyle
   DATA nCurvature
   DATA nBorder, lnoBorder
   DATA ntColor, nbColor

   METHOD New( oWndParent,nId, nLeft, nTop, nWidth, nHeight, bSize, tcolor, bColor, nStyle, ;
                lnoBorder, nBorder, nCurvature, nbStyle, nfStyle)
   METHOD Activate()
   METHOD Paint()
   METHOD SetColor(tcolor,bcolor)
   METHOD Curvature(nCurvature)

ENDCLASS


METHOD New( oWndParent,nId, nLeft, nTop, nWidth, nHeight, bSize, tcolor, bColor, ncStyle, ;
                lnoBorder, nBorder, nCurvature, nbStyle, nfStyle) CLASS HDrawShape

   Super:New( oWndParent,nId,SS_OWNERDRAW,nLeft,nTop,,,,,bSize,{|o,lp|o:Paint(lp)} )

   ::title := ""
   ::ncStyle :=  ncStyle  //0 -raised ,1-sunken 2-flat
   ::nLeft := nLeft
   ::nTop := nTop
   ::nWidth := nWidth
   ::nHeight := nHeight
   tColor := IIF(tColor = Nil, 0, tColor)
   bColor := IIF(bColor = Nil, GetSysColor( COLOR_BTNFACE )  , bColor)
   ::lnoBorder := lnoBorder
   ::nBorder := nBorder
   ::nbStyle := nbStyle
   ::nfStyle := nfStyle
   ::nCurvature := nCurvature
   ::Activate()
   // brush somente para os SHAPE
   ::nbcolor := bcolor
   ::ntColor := tcolor
   IF ncStyle == Nil
      ::oPen := HPen():Add(::nbStyle, ::nBorder, tColor)
   ELSE  // CONTAINER
       ::oPen := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
   ENDIF


Return Self

//---------------------------------------------------------------------------
METHOD Activate CLASS HDrawShape
   IF !empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth,::nHeight )
      ::Init()
   ENDIF
Return Nil

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
   SENDMESSAGE(::handle, WM_PAINT,0,0)
   RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )

RETURN Nil

METHOD Curvature( nCurvature ) CLASS HDrawShape

   IF nCurvature != NIL
      ::nCurvature := nCurvature
      SENDMESSAGE(::handle, WM_PAINT,0,0)
      RedrawWindow(::handle,RDW_ERASE + RDW_INVALIDATE )
   ENDIF
RETURN Nil

//---------------------------------------------------------------------------
METHOD Paint( lpdis ) CLASS HDrawShape
 Local drawInfo := GetDrawItemInfo( lpdis )
 Local hDC := drawInfo[3], oBrush
 Local  x1 := drawInfo[4], y1 := drawInfo[5]
 Local  x2 := drawInfo[6], y2 := drawInfo[7]

   SelectObject( hDC, ::oPen:handle )
   IF ::ncStyle != Nil
      IF ::lnoBorder = .F.
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
   ELSE
      setbkmode(hdc,1)
      obrush := HBrush():Add(::nbColor)
        SelectObject( hDC, oBrush:handle )
         ROUNDRECT( hDC, x1,y1, x2, y2 , ::nCurvature, ::nCurvature)
         IF ::nfStyle != BS_TRANSPARENT
         setbkmode(hdc,0)
         obrush := HBrush():Add(::ntColor,::nfstyle)
         SelectObject( hDC, oBrush:handle )
         RoundRect( hDC, x1,y1, x2, y2 , ::nCurvature, ::nCurvature)
      ENDIF
   ENDIF
Return Nil

// END NEW CLASSE


//-----------------------------------------------------------------
Function Rect(oWndParent,nLeft,nTop,nRight,nBottom, lPress, nST)

if lPress = NIL
   lPress := .f.
endif

return  HRect():New(oWndParent,nLeft,nTop,nRight,nBottom, lPress, nST)
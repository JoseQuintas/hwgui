/*
 * $Id: hrect.prg,v 1.1 2004-12-13 16:27:39 sandrorrfreire Exp $
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
   IF ::oParent:handle != 0
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

//-----------------------------------------------------------------
Function Rect(oWndParent,nLeft,nTop,nRight,nBottom, lPress, nST)
Local nCor1, nCor2

if lPress = NIL
   lPress := .f.
endif

return  HRect():New(oWndParent,nLeft,nTop,nRight,nBottom, lPress, nST)

/*
 * $Id: hctrl.prg,v 1.3 2004-06-06 15:35:33 alkresin Exp $
 *
 * Designer
 * HControlGen class
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "HBClass.ch"
#include "guilib.ch"
#include "hxml.ch"

Static aBDown := { Nil,0,0,.F. }

//- HControl

CLASS HControlGen INHERIT HControl

   CLASS VAR winclass INIT "STATIC"
   DATA  cClass
   DATA lContainer    INIT .F.
   DATA oContainer
   DATA oXMLDesc
   DATA aProp         INIT {}
   DATA aMethods      INIT {}
   DATA  aPaint, oBitmap

   METHOD New( oWndParent, xClass, aProp )
   METHOD Activate()
   METHOD Paint( lpdis )
   METHOD GetProp( cName )
   METHOD SetProp( xName,cValue )

ENDCLASS

METHOD New( oWndParent, xClass, aProp ) CLASS HControlGen
Local oXMLDesc
Local oPaint, bmp, cPropertyName
Local i, j, xProperty
Private value, oCtrl := Self

   ::oParent := Iif( oWndParent==Nil,HFormGen():oDlgSelected,oWndParent )
   ::id      := ::NewId()
   ::style   := WS_VISIBLE+WS_CHILD+WS_DISABLED+SS_OWNERDRAW

   IF Valtype( xClass ) == "C"
      oXMLDesc := FindWidget( xClass )
   ELSE
      oXMLDesc := xClass
      xClass := oXMLDesc:GetAttribute( "class" )
   ENDIF
   ::cClass := xClass

   IF oXMLDesc != Nil
      IF ( cProperty := oXMLDesc:GetAttribute( "container" ) ) != Nil .AND. ;
           Upper(cProperty) == "YES"
         ::lContainer := .T.
      ENDIF
      FOR i := 1 TO Len( oXMLDesc:aItems )
         IF oXMLDesc:aItems[i]:title == "paint"
            oPaint := oXMLDesc:aItems[i]
            IF !Empty( oPaint:aItems ) .AND. oPaint:aItems[1]:type == HBXML_TYPE_CDATA
               ::aPaint := RdScript( ,oPaint:aItems[1]:aItems[1] )
            ENDIF
            IF ( bmp := oPaint:GetAttribute( "bmp" ) ) != Nil
               IF Isdigit( Left( bmp,1 ) )
                  ::oBitmap := HBitmap():AddResource( Val(bmp) )
               ELSE
                  ::oBitmap := HBitmap():AddFile( bmp )
               ENDIF
            ENDIF
         ELSEIF oXMLDesc:aItems[i]:title == "property"
            IF !Empty( oXMLDesc:aItems[i]:aItems )
               IF Valtype( oXMLDesc:aItems[i]:aItems[1]:aItems[1] ) == "C"
                  oXMLDesc:aItems[i]:aItems[1]:aItems[1] := &( "{||" + oXMLDesc:aItems[i]:aItems[1]:aItems[1] + "}" )
               ENDIF
               xProperty := Eval( oXMLDesc:aItems[i]:aItems[1]:aItems[1] )
            ELSE
               xProperty := oXMLDesc:aItems[i]:GetAttribute( "value" )
               /*
               IF oXMLDesc:aItems[i]:GetAttribute( "type" ) == "A" .AND. !Empty(xProperty)
                  xProperty := Str2Arr( xProperty )
               ENDIF
               */
            ENDIF
            Aadd( ::aProp, { oXMLDesc:aItems[i]:GetAttribute( "name" ),  ;
                             xProperty, ;
                             oXMLDesc:aItems[i]:GetAttribute( "type" ) } )
         ELSEIF oXMLDesc:aItems[i]:title == "method"
            Aadd( ::aMethods, { oXMLDesc:aItems[i]:GetAttribute( "name" ),"" } )
         ENDIF
      NEXT
   ENDIF
   IF aProp != Nil
      FOR i := 1 TO Len( aProp )
         cPropertyName := Lower( aProp[ i,1 ] )
         IF ( j := Ascan( ::aProp, {|a|Lower(a[1])==cPropertyName} ) ) != 0
            // IF !Empty( aProp[i,2] )
               ::aProp[j,2] := aProp[i,2]
            // ENDIF
         ELSE
            // Aadd( ::aProp, { aProp[i,1], aProp[i,2] } )
         ENDIF
      NEXT
   ENDIF
   FOR i := 1 TO Len( ::aProp )
      value := ::aProp[ i,2 ]
      cPropertyName := Lower( ::aProp[ i,1 ] )
      j := Ascan( aDataDef, {|a|a[1]==cPropertyName} )
      IF value != Nil // .AND. !Empty( value )
         IF j != 0 .AND. aDataDef[ j,3 ] != Nil
            EvalCode( aDataDef[ j,3 ] )
         ENDIF
      ELSEIF j != 0 .AND. value == Nil .AND. aDataDef[ j,7 ] != Nil
         ::aProp[ i,2 ] := EvalCode( aDataDef[ j,7 ] )
      ENDIF
   NEXT

   ::title   := Iif( ::title==Nil,xClass,::title )

   ::bPaint  := {|o,lp|o:Paint(lp)}
   ::SetColor( ::tcolor,::bcolor )

   ::oParent:AddControl( Self )

   ::oXMLDesc := oXMLDesc

   ::Activate()

Return Self

METHOD Activate() CLASS HControlGen

   IF ::oParent != Nil .AND. ::oParent:handle != 0
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
               ::style, ::nLeft, ::nTop, ::nWidth,::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Paint( lpdis ) CLASS HControlGen
Local drawInfo := GetDrawItemInfo( lpdis )
Private hDC := drawInfo[3], oCtrl := Self

   IF ::aPaint != Nil
      DoScript( ::aPaint )
   ENDIF

Return Nil

METHOD GetProp( cName ) CLASS HControlGen
Local i

  cName := Lower( cName )
  i := Ascan( ::aProp,{|a|Lower(a[1])==cName} )
Return Iif( i==0, Nil, ::aProp[i,2] )

METHOD SetProp( xName,cValue )

   IF Valtype( xName ) == "C"
      xName := Lower( xName )
      xName := Ascan( ::aProp,{|a|Lower(a[1])==xName} )
   ENDIF
   IF xName != 0
      ::aProp[xName,2] := cValue
   ENDIF
Return Nil

// -----------------------------------------------

Function CreateName( cPropertyName, oCtrl )
Local i, j, aControls := oCtrl:oParent:aControls, arr := {}
Local cName := "o" + Upper( Left( oCtrl:cClass,1 ) ) + Substr( oCtrl:cClass,2 )
Local nLen := Len( cName )

   FOR i := 1 TO Len( aControls )
      IF( j := Ascan( aControls[i]:aProp, {|a|a[1]==cPropertyName} ) ) > 0
         IF Left( aControls[i]:aProp[j,2],nLen ) == cName
            Aadd( arr,Substr( aControls[i]:aProp[j,2],nLen+1 ) )
         ENDIF
      ENDIF
   NEXT
   i := 1
   DO WHILE Ascan( arr,Ltrim(Str(i)) ) > 0
      i ++
   ENDDO

Return cName+Ltrim(Str(i))

Function CtrlMove( oCtrl,xPos,yPos,lMouse )
Local i, dx, dy

   IF xPos != aBDown[2] .OR. yPos != aBDown[3]
      IF lMouse .AND. Abs( xPos - aBDown[2] ) < 3 .AND. Abs( yPos - aBDown[3] ) < 3 
         Return Nil
      ENDIF
      InvalidateRect( oCtrl:oParent:handle, 1, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      dx := xPos - aBDown[2]
      dy := yPos - aBDown[3]
      IF oCtrl:nLeft + dx < 0
         dx := - oCtrl:nLeft
      ENDIF
      IF oCtrl:nTop + dy < 0
         dy := - oCtrl:nTop
      ENDIF
      oCtrl:nLeft += dx
      oCtrl:nTop  += dy
      aBDown[2] := xPos
      aBDown[3] := yPos
      InvalidateRect( oCtrl:oParent:handle, 0, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      MoveWindow( oCtrl:handle, oCtrl:nLeft, oCtrl:nTop, oCtrl:nWidth, oCtrl:nHeight )
      oCtrl:oParent:oParent:lChanged := .T.
      FOR i := 1 TO Len( oCtrl:aControls )
         oCtrl:aControls[i]:nLeft += dx
         oCtrl:aControls[i]:nTop += dy
         MoveWindow( oCtrl:aControls[i]:handle, oCtrl:aControls[i]:nLeft, oCtrl:aControls[i]:nTop, oCtrl:aControls[i]:nWidth, oCtrl:aControls[i]:nHeight )
      NEXT
      InspUpdBrowse()
   ENDIF
Return Nil

Function CtrlResize( oCtrl,xPos,yPos )
Local dx, dy

   IF xPos != aBDown[2] .OR. yPos != aBDown[3]
      InvalidateRect( oCtrl:oParent:handle, 1, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      dx := xPos - aBDown[2]
      dy := yPos - aBDown[3]
      IF aBDown[4] == 1
         IF oCtrl:nWidth - dx < 4
            dx := oCtrl:nWidth - 4
         ENDIF
         oCtrl:nLeft += dx
         oCtrl:nWidth -= dx
      ELSEIF aBDown[4] == 2
         IF oCtrl:nHeight - dy < 4
            dy := oCtrl:nHeight - 4
         ENDIF
         oCtrl:nTop  += dy
         oCtrl:nHeight  -= dy
      ELSEIF aBDown[4] == 3
         IF oCtrl:nWidth + dx < 4
            dx := 4 - oCtrl:nWidth
         ENDIF
         oCtrl:nWidth += dx
      ELSEIF aBDown[4] == 4
         IF oCtrl:nHeight + dy < 4
            dy := 4 - oCtrl:nHeight
         ENDIF
         oCtrl:nHeight  += dy
      ENDIF
      aBDown[2] := xPos
      aBDown[3] := yPos
      InvalidateRect( oCtrl:oParent:handle, 0, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      MoveWindow( oCtrl:handle, oCtrl:nLeft, oCtrl:nTop, oCtrl:nWidth, oCtrl:nHeight )
      oCtrl:oParent:oParent:lChanged := .T.
      InspUpdBrowse()
   ENDIF
Return Nil

Function SetBDown( oCtrl,xPos,yPos,nBorder )
   aBDown[1] := oCtrl
   aBDown[2]  := xPos
   aBDown[3]  := yPos
   aBDown[4] := nBorder
   IF oCtrl != Nil
      SetCtrlSelected( oCtrl:oParent,oCtrl )
   ENDIF
Return Nil

Function GetBDown
Return aBDown

Function SetCtrlSelected( oDlg,oCtrl )
Local oFrm := oDlg:oParent, handle, i

   IF ( oFrm:oCtrlSelected == Nil .AND. oCtrl != Nil ) .OR. ;
        ( oFrm:oCtrlSelected != Nil .AND. oCtrl == Nil ) .OR. ;
        ( oFrm:oCtrlSelected != Nil .AND. oCtrl != Nil .AND. ;
        oFrm:oCtrlSelected:handle != oCtrl:handle )
      handle := Iif( oCtrl!=Nil,oCtrl:oParent:handle, ;
                        oFrm:oCtrlSelected:oParent:handle )
      IF oFrm:oCtrlSelected != Nil
         InvalidateRect( oFrm:oCtrlSelected:oParent:handle, 1, ;
                  oFrm:oCtrlSelected:nLeft-4, oFrm:oCtrlSelected:nTop-4, ;
                  oFrm:oCtrlSelected:nLeft+oFrm:oCtrlSelected:nWidth+3,  ;
                  oFrm:oCtrlSelected:nTop+oFrm:oCtrlSelected:nHeight+3 )
      ENDIF
      oFrm:oCtrlSelected := oCtrl
      IF oCtrl != Nil
         InvalidateRect( oCtrl:oParent:handle, 0, ;
                  oCtrl:nLeft-4, oCtrl:nTop-4, ;
                  oCtrl:nLeft+oCtrl:nWidth+3,  ;
                  oCtrl:nTop+oCtrl:nHeight+3 )
         IF oDlgInsp != Nil
            i := Ascan( oDlg:aControls,{|o|o:handle==oCtrl:handle} )
            InspUpdCombo( i )
         ENDIF
      ELSE
         IF oDlgInsp != Nil
            InspUpdCombo( 0 )
         ENDIF
      ENDIF
      SendMessage( handle,WM_PAINT,0,0 )
   ENDIF
Return Nil

Function GetCtrlSelected( oDlg )
Return Iif( oDlg!=Nil,oDlg:oParent:oCtrlSelected,Nil )

Function CheckResize( oCtrl,xPos,yPos )
   IF xPos > oCtrl:nLeft-5 .AND. xPos < oCtrl:nLeft+3 .AND. ;
      yPos >= oCtrl:nTop .AND. yPos < oCtrl:nTop + oCtrl:nHeight
      IF oCtrl:nWidth > 3
         Return 1
      ENDIF
   ELSEIF xPos > oCtrl:nLeft+oCtrl:nWidth-5 .AND. xPos < oCtrl:nLeft+oCtrl:nWidth+3 .AND. ;
      yPos >= oCtrl:nTop .AND. yPos < oCtrl:nTop + oCtrl:nHeight
      IF oCtrl:nWidth > 3
         Return 3
      ENDIF
   ELSEIF yPos > oCtrl:nTop-5 .AND. yPos < oCtrl:nTop+3 .AND. ;
      xPos >= oCtrl:nLeft .AND. xPos < oCtrl:nLeft + oCtrl:nWidth
      IF oCtrl:nHeight > 3
         Return 2
      ENDIF
   ELSEIF yPos > oCtrl:nTop+oCtrl:nHeight-5 .AND. yPos < oCtrl:nTop+oCtrl:nHeight+3 .AND. ;
      xPos >= oCtrl:nLeft .AND. xPos < oCtrl:nLeft + oCtrl:nWidth
      IF oCtrl:nHeight > 3
         Return 4
      ENDIF
   ENDIF
Return 0

Function MoveCtrl( oCtrl )

   MoveWindow( oCtrl:handle,oCtrl:nLeft,oCtrl:nTop,oCtrl:nWidth,oCtrl:nHeight )
   IF oCtrl:ClassName() != "HDIALOG"
      RedrawWindow( oCtrl:oParent:handle,RDW_ERASE + RDW_INVALIDATE )
   ENDIF
Return Nil

Function AdjustCtrl( oCtrl, lLeft, lTop )
Local i, aControls := Iif( oCtrl:oContainer != Nil, oCtrl:oContainer:aControls, oCtrl:oParent:aControls )
Local lRes := .F., xPos, yPos, delta := 15

   IF lLeft == Nil .AND. lTop == Nil
      lLeft := lTop := .T.
   ELSE
      delta := 30
   ENDIF
   FOR i := Len( aControls ) To 1 STEP -1
      IF lLeft .AND. aControls[i]:nLeft+aControls[i]:nWidth < oCtrl:nLeft .AND. ;
         aControls[i]:nLeft+aControls[i]:nWidth + delta > oCtrl:nLeft .AND. ;
         aControls[i]:nTop <= oCtrl:nTop .AND. aControls[i]:nTop + aControls[i]:nHeight > oCtrl:nTop
         lRes := .T.
         xPos := aControls[i]:nLeft+aControls[i]:nWidth + 1
         yPos := aControls[i]:nTop
         EXIT
      ELSEIF lTop .AND. Abs( aControls[i]:nLeft-oCtrl:nLeft ) < delta .AND. ;
             aControls[i]:nTop + aControls[i]:nHeight < oCtrl:nTop .AND. ;
             aControls[i]:nTop + aControls[i]:nHeight + delta > oCtrl:nTop
         lRes := .T.
         xPos := aControls[i]:nLeft
         yPos := aControls[i]:nTop + aControls[i]:nHeight + 1
         EXIT
      ENDIF
   NEXT
   IF lRes
      InvalidateRect( oCtrl:oParent:handle, 1, ;
               oCtrl:nLeft-4, oCtrl:nTop-4,    ;
               oCtrl:nLeft+oCtrl:nWidth+3,     ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      oCtrl:Move( xPos, yPos )
      InvalidateRect( oCtrl:oParent:handle, 1, ;
               oCtrl:nLeft-4, oCtrl:nTop-4,    ;
               oCtrl:nLeft+oCtrl:nWidth+3,     ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      InspUpdBrowse()
   ENDIF
Return Nil

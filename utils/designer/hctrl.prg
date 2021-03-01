/*
 * $Id$
 *
 * Designer
 * HControlGen class
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "hxml.ch"

Static aBDown := { Nil,0,0,.F. }
Static oPenSel
Static nAlignV := -1, nAlignH := -1

Memvar oDesigner, nMaxId

//- HControl

CLASS HControlGen INHERIT HControl

   CLASS VAR winclass INIT "STATIC"
   DATA  cClass
   DATA lContainer    INIT .F.
   DATA oContainer, nPage
   DATA oXMLDesc
   DATA aProp         INIT {}
   DATA aMethods      INIT {}
   DATA aPaint, oBitmap
   DATA aInit
   DATA cCreate
   DATA Adjust        INIT 0
   DATA lEmbed        INIT .F.

   METHOD New( oWndParent, xClass, aProp )
   METHOD Activate()
   METHOD Paint( lpdis )
   METHOD GetProp( cName,i )
   METHOD SetProp( xName,xValue )
   METHOD SetCoor( xName,nValue )

ENDCLASS

METHOD New( oWndParent, xClass, aProp ) CLASS HControlGen
Local oXMLDesc
Local oPaint, bmp, cPropertyName, cProperty
Local i, j, xProperty
Memvar value, oCtrl
Private value, oCtrl := Self

   IF oPenSel == Nil
      oPenSel := HPen():Add( PS_SOLID,1,255 )
   ENDIF

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
                  //::oBitmap := HBitmap():AddResource( Val(bmp) )
                  ::oBitmap := HBitmap():AddStandard( Val(bmp) )
               ELSEIF "." $ bmp
                  ::oBitmap := HBitmap():AddFile( bmp )
               ELSE
                  ::oBitmap := HBitmap():AddResource( bmp)
               ENDIF
            ENDIF
         ELSEIF oXMLDesc:aItems[i]:title == "init"
            oPaint := oXMLDesc:aItems[i]
            IF !Empty( oPaint:aItems ) .AND. oPaint:aItems[1]:type == HBXML_TYPE_CDATA
               ::aInit := RdScript( ,oPaint:aItems[1]:aItems[1] )
            ENDIF
         ELSEIF oXMLDesc:aItems[i]:title == "create"
            oPaint := oXMLDesc:aItems[i]
            IF !Empty( oPaint:aItems ) .AND. oPaint:aItems[1]:type == HBXML_TYPE_CDATA
               ::cCreate := RdStr( ,oPaint:aItems[1]:aItems[1],1 )
               ::style   := WS_VISIBLE+WS_CHILD+WS_DISABLED
            ENDIF
         ELSEIF oXMLDesc:aItems[i]:title == "property"
            IF !Empty( oXMLDesc:aItems[i]:aItems )
               IF Valtype( oXMLDesc:aItems[i]:aItems[1]:aItems[1] ) == "C"
                  oXMLDesc:aItems[i]:aItems[1]:aItems[1] := &( "{||" + oXMLDesc:aItems[i]:aItems[1]:aItems[1] + "}" )
               ENDIF
               xProperty := Eval( oXMLDesc:aItems[i]:aItems[1]:aItems[1] )
            ELSE
               xProperty := oXMLDesc:aItems[i]:GetAttribute( "value" )
            ENDIF
            Aadd( ::aProp, { oXMLDesc:aItems[i]:GetAttribute( "name" ),  ;
                             xProperty, ;
                             oXMLDesc:aItems[i]:GetAttribute( "type" ) } )
            IF oXMLDesc:aItems[i]:GetAttribute( "hidden" ) != Nil
               Aadd( Atail( ::aProp ),.T. )
            ENDIF
         ELSEIF oXMLDesc:aItems[i]:title == "method"
            Aadd( ::aMethods, { oXMLDesc:aItems[i]:GetAttribute( "name" ),"" } )
         ENDIF
      NEXT
   ENDIF
   IF aProp != Nil
      FOR i := 1 TO Len( aProp )
         cPropertyName := Lower( aProp[ i,1 ] )
         IF ( j := Ascan( ::aProp, {|a|Lower(a[1])==cPropertyName} ) ) != 0
            ::aProp[j,2] := aProp[i,2]
         ENDIF
      NEXT
   ENDIF
   FOR i := 1 TO Len( ::aProp )
      value := ::aProp[ i,2 ]
      cPropertyName := Lower( ::aProp[ i,1 ] )
      j := Ascan( oDesigner:aDataDef, {|a|a[1]==cPropertyName} )
      IF value != Nil
         IF j != 0 .AND. oDesigner:aDataDef[ j,3 ] != Nil
            // pArray := oDesigner:aDataDef[ j,6 ]
            EvalCode( oDesigner:aDataDef[ j,3 ] )
         ENDIF
      ELSEIF j != 0 .AND. value == Nil .AND. oDesigner:aDataDef[ j,7 ] != Nil
         ::aProp[ i,2 ] := EvalCode( oDesigner:aDataDef[ j,7 ] )
      ENDIF
   NEXT

   IF xClass == "menu"
      ::nLeft := ::nTop := -1
   ELSE
      ::title   := Iif( ::title==Nil,xClass,::title )
      ::bPaint  := {|o,lp|o:Paint(lp)}
      ::bSize   := {|o,x,y|ctrlOnSize(o,x,y)}
      ::SetColor( ::tcolor,::bcolor )
   ENDIF

   ::oParent:AddControl( Self )
   ::oXMLDesc := oXMLDesc
   ::Activate()
   ctrlOnSize( Self, ::oParent:nWidth, ::oParent:nHeight )
   //hwg_writelog( ": "+::cclass+" "+valtype(::nLeft)+" "+valtype(::nTop) )

Return Self

METHOD Activate() CLASS HControlGen
Local oFont
Memvar oCtrl

   IF ::oParent != Nil .AND. !Empty( ::oParent:handle )
      Private oCtrl := Self
      IF ::aInit != Nil
         DoScript( ::aInit )
      ENDIF
      IF ::cCreate != Nil
         ::handle := &( ::cCreate )
      ELSE
         ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
               ::style, ::nLeft, ::nTop, ::nWidth,::nHeight )
      ENDIF
      oFont := ::oFont
      ::Init()
      ::oFont := oFont
   ENDIF
Return Nil

METHOD Paint( lpdis ) CLASS HControlGen
Local drawInfo := hwg_Getdrawiteminfo( lpdis )
Memvar hDC, oCtrl
Private hDC := drawInfo[3], oCtrl := Self

   IF ::aPaint != Nil
      DoScript( ::aPaint )
   ENDIF
   oCtrl := GetCtrlSelected( HFormGen():oDlgSelected )
   IF oCtrl != Nil .AND. ::handle == oCtrl:handle
      hwg_Selectobject( hDC, oPenSel:handle )
      hwg_Rectangle( hDC, 0, 0, ::nWidth-1, ::nHeight-1 )
   ENDIF

Return Nil

METHOD GetProp( cName,i ) CLASS HControlGen

  cName := Lower( cName )
  i := Ascan( ::aProp,{|a|Lower(a[1])==cName} )
Return Iif( i==0, Nil, ::aProp[i,2] )

METHOD SetProp( xName,xValue )

   IF Valtype( xName ) == "C"
      xName := Lower( xName )
      xName := Ascan( ::aProp,{|a|Lower(a[1])==xName} )
   ENDIF
   IF xName != 0
      ::aProp[xName,2] := xValue
   ENDIF
Return xValue

METHOD SetCoor( xName,nValue )

   IF oDesigner:lReport
      nValue := Round( nValue/::oParent:oParent:oParent:oParent:nKoeff,1 )
   ENDIF
   ::SetProp( xName,Ltrim(Str(nValue)) )

Return nValue

// -----------------------------------------------

Function ctrlOnSize( oCtrl, x, y )

   IF oCtrl:Adjust == 2
      oCtrl:Move( 0,y-oCtrl:nHeight,x )
      oCtrl:SetProp( "Left","0" )
      oCtrl:SetCoor( "Top",oCtrl:nTop )
      oCtrl:SetCoor( "Width",oCtrl:nWidth )
      IF oDesigner:lReport
         oCtrl:SetCoor( "Right",oCtrl:nWidth-1 )
         oCtrl:SetCoor( "Bottom",oCtrl:nTop+oCtrl:nHeight-1 )
      ENDIF
   ENDIF
Return Nil

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

Function CtrlMove( oCtrl,xPos,yPos,lMouse,lChild )
Local i, dx, dy

   IF lChild == Nil .OR. !lChild
      lChild := .F.
      dx := xPos - aBDown[2]
      dy := yPos - aBDown[3]
      IF oCtrl:lEmbed
         IF Lower( oCtrl:cClass ) == "hline"
            dx := 0
         ELSE
            dy := 0
         ENDIF
      ENDIF
   ELSE
      dx := xPos
      dy := yPos
   ENDIF

   IF dx != 0 .OR. dy != 0
      IF !lChild .AND. lMouse .AND. Abs( xPos - aBDown[2] ) < 3 .AND. Abs( yPos - aBDown[3] ) < 3
         Return .F.
      ENDIF
      hwg_Invalidaterect( oCtrl:oParent:handle, 1, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      IF oCtrl:nLeft + dx < 0
         dx := - oCtrl:nLeft
      ENDIF
      IF oCtrl:nTop + dy < 0
         dy := - oCtrl:nTop
      ENDIF
      oCtrl:nLeft := Int( oCtrl:nLeft + dx + 0.01 )
      oCtrl:nTop := Int( oCtrl:nTop + dy + 0.01 )
      /*
      IF oDesigner:nGrid > 0
         oCtrl:nLeft := Int( oCtrl:nLeft - (oCtrl:nLeft%oDesigner:nGrid) + 0.01 )
         oCtrl:nTop := Int( oCtrl:nTop - (oCtrl:nTop%oDesigner:nGrid) + 0.01 )
      ENDIF
      */
      oCtrl:SetCoor( "Left",oCtrl:nLeft )
      oCtrl:SetCoor( "Top",oCtrl:nTop )
      IF oDesigner:lReport
         oCtrl:SetCoor( "Right",oCtrl:nLeft+oCtrl:nWidth-1 )
         oCtrl:SetCoor( "Bottom",oCtrl:nTop+oCtrl:nHeight-1 )
      ENDIF
      IF !lChild
         aBDown[2] := xPos
         aBDown[3] := yPos
      ENDIF
      hwg_Invalidaterect( oCtrl:oParent:handle, 0, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      hwg_Movewindow( oCtrl:handle, oCtrl:nLeft, oCtrl:nTop, oCtrl:nWidth, oCtrl:nHeight )
      IF oDesigner:lReport
         oCtrl:oParent:oParent:oParent:oParent:lChanged := .T.
      ELSE
         oCtrl:oParent:oParent:lChanged := .T.
      ENDIF
      FOR i := 1 TO Len( oCtrl:aControls )
         CtrlMove( oCtrl:aControls[i],dx,dy,.F.,.T. )
      NEXT
      IF !lChild
         InspUpdBrowse()
      ENDIF
      Return .T.
   ENDIF
Return .F.

Function CtrlResize( oCtrl,xPos,yPos )
Local dx, dy

   IF xPos != aBDown[2] .OR. yPos != aBDown[3]
      hwg_Invalidaterect( oCtrl:oParent:handle, 1, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      dx := xPos - aBDown[2]
      dy := yPos - aBDown[3]
      IF aBDown[4] == 1
         IF oCtrl:nWidth - dx < 4
            dx := oCtrl:nWidth - 4
         ENDIF
         oCtrl:nLeft := Int( oCtrl:nLeft + dx + 0.01 )
         oCtrl:nWidth := Int( oCtrl:nWidth - dx + 0.01 )
         oCtrl:SetCoor( "Left",oCtrl:nLeft )
         oCtrl:SetCoor( "Width",oCtrl:nWidth )
         IF oDesigner:lReport
            oCtrl:SetCoor( "Right",oCtrl:nLeft+oCtrl:nWidth-1 )
         ENDIF
      ELSEIF aBDown[4] == 2
         IF oCtrl:nHeight - dy < 4
            dy := oCtrl:nHeight - 4
         ENDIF
         oCtrl:nTop := Int( oCtrl:nTop + dy + 0.01 )
         oCtrl:nHeight := Int( oCtrl:nHeight - dy + 0.01 )
         oCtrl:SetCoor( "Top",oCtrl:nTop )
         oCtrl:SetCoor( "Height",oCtrl:nHeight )
         IF oDesigner:lReport
            oCtrl:SetCoor( "Bottom",oCtrl:nTop+oCtrl:nHeight-1 )
         ENDIF
      ELSEIF aBDown[4] == 3
         IF oCtrl:nWidth + dx < 4
            dx := 4 - oCtrl:nWidth
         ENDIF
         oCtrl:nWidth := Int( oCtrl:nWidth + dx + 0.01 )
         oCtrl:SetCoor( "Width",oCtrl:nWidth )
         IF oDesigner:lReport
            oCtrl:SetCoor( "Right",oCtrl:nLeft+oCtrl:nWidth-1 )
         ENDIF
      ELSEIF aBDown[4] == 4
         IF oCtrl:nHeight + dy < 4
            dy := 4 - oCtrl:nHeight
         ENDIF
         oCtrl:nHeight := Int( oCtrl:nHeight + dy + 0.01 )
         oCtrl:SetCoor( "Height",oCtrl:nHeight )
         IF oDesigner:lReport
            oCtrl:SetCoor( "Bottom",oCtrl:nTop+oCtrl:nHeight-1 )
         ENDIF
      ENDIF
      aBDown[2] := xPos
      aBDown[3] := yPos
      hwg_Invalidaterect( oCtrl:oParent:handle, 0, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      hwg_Movewindow( oCtrl:handle, oCtrl:nLeft, oCtrl:nTop, oCtrl:nWidth, oCtrl:nHeight )
      IF oDesigner:lReport
         oCtrl:oParent:oParent:oParent:oParent:lChanged := .T.
      ELSE
         oCtrl:oParent:oParent:lChanged := .T.
      ENDIF
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

Function SetCtrlSelected( oDlg,oCtrl,n )
Local oFrm := Iif( oDlg:oParent:Classname()=="HPANEL",oDlg:oParent:oParent:oParent,oDlg:oParent ), handle, i

   IF ( oFrm:oCtrlSelected == Nil .AND. oCtrl != Nil ) .OR. ;
        ( oFrm:oCtrlSelected != Nil .AND. oCtrl == Nil ) .OR. ;
        ( oFrm:oCtrlSelected != Nil .AND. oCtrl != Nil .AND. ;
        oFrm:oCtrlSelected:handle != oCtrl:handle )
      handle := Iif( oCtrl!=Nil,oCtrl:oParent:handle, ;
                        oFrm:oCtrlSelected:oParent:handle )
      IF oFrm:oCtrlSelected != Nil
         hwg_Invalidaterect( oFrm:oCtrlSelected:oParent:handle, 1, ;
                  oFrm:oCtrlSelected:nLeft-4, oFrm:oCtrlSelected:nTop-4, ;
                  oFrm:oCtrlSelected:nLeft+oFrm:oCtrlSelected:nWidth+3,  ;
                  oFrm:oCtrlSelected:nTop+oFrm:oCtrlSelected:nHeight+3 )
      ENDIF
      oFrm:oCtrlSelected := oCtrl
      IF oCtrl != Nil
         hwg_Invalidaterect( oCtrl:oParent:handle, 0, ;
                  oCtrl:nLeft-4, oCtrl:nTop-4, ;
                  oCtrl:nLeft+oCtrl:nWidth+3,  ;
                  oCtrl:nTop+oCtrl:nHeight+3 )
         IF oDesigner:oDlgInsp != Nil
            IF n != Nil
               i := n
            ELSE
               i := Ascan( oDlg:aControls,{|o|hwg_Isptreq(o:handle,oCtrl:handle)} )
            ENDIF
            InspUpdCombo( i )
         ENDIF
      ELSE
         IF oDesigner:oDlgInsp != Nil
            InspUpdCombo( 0 )
         ENDIF
      ENDIF
      hwg_Sendmessage( handle,WM_PAINT,0,0 )
   ENDIF
Return Nil

Function GetCtrlSelected( oDlg )
Return Iif( oDlg!=Nil,Iif( oDlg:oParent:Classname()=="HPANEL",oDlg:oParent:oParent:oParent:oCtrlSelected,oDlg:oParent:oCtrlSelected),Nil )

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

   LOCAL nDiff := Iif( oCtrl:oParent:Classname() == "HFORMGEN", oCtrl:oParent:nDiff, 0 )

   hwg_Movewindow( oCtrl:handle, oCtrl:nLeft, oCtrl:nTop, oCtrl:nWidth, oCtrl:nHeight+nDiff )
   hwg_Redrawwindow( oCtrl:oParent:handle, RDW_ERASE + RDW_INVALIDATE )
Return Nil

Function AdjustCtrl( oCtrl, lLeft, lTop, lRight, lBottom )
Local i, aControls := Iif( oCtrl:oContainer != Nil, oCtrl:oContainer:aControls, oCtrl:oParent:aControls )
Local lRes := .F., xPos, yPos, delta := 15

   IF oCtrl:lEmbed
      Return Nil
   ENDIF
   IF lLeft == Nil .AND. lTop == Nil .AND. lRight == Nil .AND. lBottom == Nil
      lLeft := lTop := lRight := lBottom := .T.
   ELSE
      delta := 30
   ENDIF
   FOR i := Len( aControls ) To 1 STEP -1
      IF !aControls[i]:lHide
         IF lLeft .AND. aControls[i]:nLeft+aControls[i]:nWidth < oCtrl:nLeft .AND. ;
            aControls[i]:nLeft+aControls[i]:nWidth + delta > oCtrl:nLeft .AND. ;
            aControls[i]:nTop <= oCtrl:nTop .AND. aControls[i]:nTop + aControls[i]:nHeight > oCtrl:nTop
            lRes := .T.
            xPos := aControls[i]:nLeft+aControls[i]:nWidth
            yPos := aControls[i]:nTop
            EXIT
         ELSEIF lTop .AND. Abs( aControls[i]:nLeft-oCtrl:nLeft ) < delta .AND. ;
                aControls[i]:nTop + aControls[i]:nHeight < oCtrl:nTop .AND. ;
                aControls[i]:nTop + aControls[i]:nHeight + delta > oCtrl:nTop
            lRes := .T.
            xPos := aControls[i]:nLeft
            yPos := aControls[i]:nTop + aControls[i]:nHeight
            EXIT
         ELSEIF lRight .AND. oCtrl:nLeft+oCtrl:nWidth < aControls[i]:nLeft .AND. ;
            oCtrl:nLeft+oCtrl:nWidth >= aControls[i]:nLeft - delta .AND. ;
            oCtrl:nTop >= aControls[i]:nTop .AND. aControls[i]:nTop + aControls[i]:nHeight > oCtrl:nTop
            lRes := .T.
            xPos := aControls[i]:nLeft-oCtrl:nWidth
            yPos := aControls[i]:nTop
            EXIT
         ELSEIF lBottom .AND. Abs( aControls[i]:nLeft-oCtrl:nLeft ) <= delta .AND. ;
                aControls[i]:nTop > oCtrl:nTop + oCtrl:nHeight .AND. ;
                aControls[i]:nTop - delta <= oCtrl:nTop + oCtrl:nHeight
            lRes := .T.
            xPos := aControls[i]:nLeft
            yPos := aControls[i]:nTop - oCtrl:nHeight
            EXIT
         ENDIF
      ENDIF
   NEXT
   IF lRes
      IF oDesigner:nGrid > 0
         IF xPos % oDesigner:nGrid != 0
            xPos := Int( xPos - (xPos%oDesigner:nGrid) + 0.01 + oDesigner:nGrid )
         ENDIF
         IF yPos % oDesigner:nGrid != 0
            yPos := Int( yPos - (yPos%oDesigner:nGrid) + 0.01 + oDesigner:nGrid )
         ENDIF
      ENDIF
      CtrlMove( oCtrl,xPos-oCtrl:nLeft,yPos-oCtrl:nTop,.F.,.T. )
      Container( oCtrl:oParent,oCtrl,oCtrl:nLeft,oCtrl:nTop )
      InspUpdBrowse()
   ENDIF
Return Nil

Function AlignCtrl( oCtrl, nAlignType )

   IF nAlignType == 1 .AND. nAlignV >= 0
      CtrlMove( oCtrl, nAlignV-oCtrl:nLeft, 0, .F., .T. )
      Container( oCtrl:oParent, oCtrl, oCtrl:nLeft, oCtrl:nTop )
      InspUpdBrowse()
   ELSEIF nAlignType == 2 .AND. nAlignH >= 0
      CtrlMove( oCtrl, 0, nAlignH-oCtrl:nTop, .F., .T. )
      Container( oCtrl:oParent, oCtrl, oCtrl:nLeft, oCtrl:nTop )
      InspUpdBrowse()
   ENDIF
Return Nil

Function SetAsPattern( oCtrl, nAlignType )

   IF nAlignType == 1
      nAlignV := oCtrl:nLeft
   ELSEIF nAlignType == 2
      nAlignH := oCtrl:nTop
   ENDIF
Return Nil

Function FitLine( oCtrl )

   IF oCtrl:lEmbed
      oCtrl:lEmbed := .F.
   ELSE
      IF Lower( oCtrl:cClass ) == "hline"
         oCtrl:Move( oCtrl:oContainer:nLeft+1,,oCtrl:oContainer:nWidth-2 )
         oCtrl:SetCoor( "Left",oCtrl:nLeft )
         oCtrl:SetCoor( "Width",oCtrl:nWidth )
         oCtrl:SetCoor( "Right",oCtrl:nLeft+oCtrl:nWidth-1 )
      ELSE
         oCtrl:Move( ,oCtrl:oContainer:nTop+1,,oCtrl:oContainer:nHeight-2 )
         oCtrl:SetCoor( "Top",oCtrl:nTop )
         oCtrl:SetCoor( "Height",oCtrl:nHeight )
         oCtrl:SetCoor( "Bottom",oCtrl:nTop+oCtrl:nHeight-1 )
      ENDIF
      oCtrl:lEmbed := .T.
   ENDIF
Return Nil

Function Page_New( oTab )
Local aTabs := oTab:GetProp( "Tabs" )

   IF aTabs == Nil
      aTabs := {}
      oTab:SetProp( "Tabs",aTabs )
   ENDIF
   hwg_Addtab( oTab:handle, Len( aTabs ), "New Page" )
   Aadd( aTabs,"New Page" )
   InspUpdProp( "Tabs", aTabs )
   hwg_Redrawwindow( oTab:handle,5 )
Return Nil

Function Page_Next( oTab )
Return Nil

Function Page_Prev( oTab )
Return Nil

Function Page_Upd( oTab, arr )
Local i, nTabs := hwg_Sendmessage( oTab:handle,TCM_GETITEMCOUNT,0,0 )

   FOR i := 1 TO Len( arr )
      IF i <= nTabs
         hwg_Settabname( oTab:handle, i, arr[i] )
      ELSE
         hwg_Addtab( oTab:handle, i-1, arr[i] )
      ENDIF
   NEXT

Return Nil

Function Page_Select( oTab, nTab, lForce )
Local i, j, oCtrl

   IF ( lForce != Nil .AND. lForce ) .OR. hwg_Getcurrenttab( oTab:handle ) != nTab

      hwg_Sendmessage( oTab:handle, TCM_SETCURSEL, nTab-1, 0 )
      FOR i := 1 TO Len( oTab:aControls )
         oCtrl := oTab:aControls[i]
         IF oCtrl:nPage != nTab .AND. !oCtrl:lHide
            oCtrl:Hide()
            FOR j := 1 TO Len( oCtrl:aControls )
               oCtrl:aControls[j]:Hide()
            NEXT
         ELSEIF oCtrl:nPage == nTab .AND. oCtrl:lHide
            oCtrl:Show()
            FOR j := 1 TO Len( oCtrl:aControls )
               oCtrl:aControls[j]:Show()
            NEXT
         ENDIF
      NEXT

   ENDIF

Return Nil

Function EditMenu()
Local oDlg, oTree, i, aMenu
Private nMaxId := 0

   oDlg := HFormGen():oDlgSelected
   FOR i := 1 TO Len( oDlg:aControls )
      IF oDlg:aControls[i]:cClass == "menu"
         aMenu := oDlg:aControls[i]:GetProp( "aTree" )
         IF aMenu == Nil
            aMenu := oDlg:aControls[i]:SetProp( "aTree", { { ,"Menu",32000,Nil } } )
         ENDIF
         aMenu := aClone( aMenu )
         EXIT
      ENDIF
   NEXT

   INIT DIALOG oDlg TITLE "Edit Menu" ;
        AT 300,280 SIZE 400,350 FONT oDesigner:oMainWnd:oFont ;
        STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SIZEBOX ;
        ON INIT {||BuildTree( oTree,aMenu )}

   @ 10,20 TREE oTree OF oDlg SIZE 200,240 STYLE WS_BORDER EDITABLE
   oTree:bItemChange := {|o,s|VldItemChange(aMenu,o,s)}

   @ 240,20 BUTTON "Rename" SIZE 140,30 ON CLICK {||EditTree(aMenu,oTree,0)}
   @ 240,60 BUTTON "Add item after" SIZE 140,30 ON CLICK {||EditTree(aMenu,oTree,1)}
   @ 240,100 BUTTON "Add item before" SIZE 140,30 ON CLICK {||EditTree(aMenu,oTree,2)}
   @ 240,140 BUTTON "Add child item" SIZE 140,30 ON CLICK {||EditTree(aMenu,oTree,3)}
   @ 240,180 BUTTON "Delete" SIZE 140,30 ON CLICK {||EditTree(aMenu,oTree,4)}
   @ 240,220 BUTTON "Edit code" SIZE 140,30 ON CLICK {||EditTree(aMenu,oTree,10)}

   @ 40,290 BUTTON "Ok" SIZE 100,30 ON CLICK {||oDlg:lResult:=.T.,hwg_EndDialog()}
   @ 260,290 BUTTON "Cancel" SIZE 100,30 ON CLICK {||hwg_EndDialog()}

   oDlg:AddEvent( 0,IDOK,{||hwg_Setfocus(oDlg:aControls[2]:handle)} )
   oDlg:AddEvent( 0,IDCANCEL,{||hwg_Setfocus(oDlg:aControls[2]:handle)} )

   ACTIVATE DIALOG oDlg
   IF oDlg:lResult
      HFormGen():oDlgSelected:aControls[i]:SetProp( "aTree",aMenu )
   ENDIF

Return Nil

Static Function BuildTree( oParent, aMenu )
Local i := Len( aMenu ), oNode

   FOR i := 1 TO Len( aMenu )
      INSERT NODE oNode CAPTION aMenu[i,2] TO oParent
      oNode:cargo := aMenu[i,3]
      nMaxId := Max( nMaxId,aMenu[i,3] )
      IF Valtype( aMenu[i,1] ) == "A"
         BuildTree( oNode, aMenu[i,1] )
      ENDIF
   NEXT

Return Nil

Static Function VldItemChange( aTree,oNode,cText )
Local nPos, aSubarr

   IF ( aSubarr := FindTreeItem( aTree, oNode:cargo, @nPos ) ) != Nil
      aSubarr[nPos,2] := cText
   ENDIF
Return .T.

Static Function FindTreeItem( aTree, nId, nPos )
Local nPos1, aSubarr
   nPos := 1
   DO WHILE nPos <= Len( aTree )
      IF aTree[npos,3] == nId
         Return aTree
      ELSEIF Valtype(aTree[npos,1]) == "A"
         IF ( aSubarr := FindTreeItem( aTree[nPos,1] , nId, @nPos1 ) ) != Nil
            nPos := nPos1
            Return aSubarr
         ENDIF
      ENDIF
      nPos ++
   ENDDO
Return Nil

Static Function EditTree( aTree,oTree,nAction )
Local oNode, cMethod
Local nPos, aSubarr

   IF Empty( oTree:oSelected ) .AND. !Empty( oTree:aItems )
      oTree:Select( oTree:aItems[1] )
   ENDIF

   IF nAction == 0       // Rename
      IF !Empty( oTree:oSelected )
         oTree:EditLabel( oTree:oSelected )
      ENDIF

   ELSEIF nAction == 1   // Insert after
      IF !Empty( oTree:aItems )
         IF oTree:oSelected:oParent == Nil
            oNode := oTree:AddNode( "New" )
         ELSE
            oNode := oTree:oSelected:oParent:AddNode( "New",oTree:oSelected )
         ENDIF
         oTree:EditLabel( oNode )
         nMaxId ++
         oNode:cargo := nMaxId
         IF ( aSubarr := FindTreeItem( aTree, oTree:oSelected:cargo, @nPos ) ) != Nil
            Aadd( aSubarr,Nil )
            Ains( aSubarr,nPos+1 )
            aSubarr[nPos+1] := { Nil,"New",nMaxId,Nil }
         ENDIF
      ENDIF

   ELSEIF nAction == 2   // Insert before
      IF !Empty( oTree:aItems )
         IF oTree:oSelected:oParent == Nil
            oNode := oTree:AddNode( "New",,oTree:oSelected )
         ELSE
            oNode := oTree:oSelected:oParent:AddNode( "New",,oTree:oSelected )
         ENDIF
         oTree:EditLabel( oNode )
         nMaxId ++
         oNode:cargo := nMaxId
         IF ( aSubarr := FindTreeItem( aTree, oTree:oSelected:cargo, @nPos ) ) != Nil
            Aadd( aSubarr,Nil )
            Ains( aSubarr,nPos )
            aSubarr[nPos] := { Nil,"New",nMaxId,Nil }
         ENDIF
      ENDIF

   ELSEIF nAction == 3   // Insert child
      IF Empty( oTree:aItems )
         oNode := oTree:AddNode( "New" )
      ELSE
         oNode := oTree:oSelected:AddNode( "New" )
         oTree:Expand( oTree:oSelected )
      ENDIF
      oTree:EditLabel( oNode )
      nMaxId ++
      oNode:cargo := nMaxId
      IF ( aSubarr := FindTreeItem( aTree, oTree:oSelected:cargo, @nPos ) ) != Nil
         IF Valtype( aSubarr[nPos,1] ) != "A"
            aSubarr[nPos,1] := {}
         ENDIF
         Aadd( aSubarr[nPos,1], { Nil,"New",nMaxId,Nil } )
      ENDIF

   ELSEIF nAction == 4   // Delete
      IF !Empty( oTree:aItems ) .AND. !(oTree:oSelected == oTree:aItems[1])
         IF ( aSubarr := FindTreeItem( aTree, oTree:oSelected:cargo, @nPos ) ) != Nil
            Adel( aSubarr,nPos )
            Asize( aSubarr,Len(aSubarr)-1 )
         ENDIF
         oTree:oSelected:Delete()
      ENDIF

   ELSEIF nAction == 10  // Edit code
      IF ( aSubarr := FindTreeItem( aTree, oTree:oSelected:cargo, @nPos ) ) != Nil
         IF ( cMethod := EditMethod( oTree:oSelected:GetText(), aSubarr[nPos,4] ) ) != Nil
            aSubarr[nPos,4] := cMethod
         ENDIF
      ENDIF
   ENDIF

Return Nil

Function GetMenu()
Local oDlg, i, aMenu
Memvar nMaxID, oDesigner
Private nMaxId := 0

   oDlg := HFormGen():oDlgSelected
   FOR i := 1 TO Len( oDlg:aControls )
      IF oDlg:aControls[i]:cClass == "menu"
         aMenu := oDlg:aControls[i]:GetProp( "aTree" )
         IF aMenu == Nil
            aMenu := oDlg:aControls[i]:SetProp( "aTree", { { ,"Menu",32000,Nil } } )
         ENDIF
         aMenu := aClone( aMenu )
         EXIT
      ENDIF
   NEXT
 RETURN aMenu

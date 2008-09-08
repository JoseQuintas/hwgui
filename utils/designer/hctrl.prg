/*
 * $Id: hctrl.prg,v 1.25 2008-09-08 16:53:30 mlacecilia Exp $
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

#include "designer.ch"

#define TCM_SETCURSEL           4876
#define TCM_GETITEMCOUNT        4868

Static aBDown := { Nil,0,0,.F. }
Static vBDown := { Nil,0,0,.F. }
Static oPenSel

// :LFB
STATIC aSels := {}
// :END LFB

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
   DATA cCreate
   DATA Adjust        INIT 0
   DATA lEmbed        INIT .F.


   METHOD New( oWndParent, xClass, aProp )
   METHOD Activate()
   METHOD Paint( lpdis )
   METHOD GetProp( cName,i )
   METHOD GetPropIndex( cName,i )
   METHOD SetProp( xName,xValue )
   METHOD SetCoor( xName,nValue )

ENDCLASS

METHOD New( oWndParent, xClass, aProp ) CLASS HControlGen
Local oXMLDesc
Local oPaint, bmp, cPropertyName
Local i, j, xProperty, cProperty

Memvar  value, oCtrl, oDesigner
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
                  ::oBitmap := HBitmap():AddStandard( Val(bmp) )
               ELSEIF "." $ bmp
                  ::oBitmap := HBitmap():AddFile( bmp )
               ELSE
                  ::oBitmap := HBitmap():AddResource( bmp)
               ENDIF
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
      // :LFB pos
        statusbarmsg(,'x: '+ltrim(str(::nLeft))+'  y: '+ltrim(str(::nTop)),;
          'w: '+ltrim(str(::nWidth))+'  h: '+ltrim(str(::nHeight)))
         // :END LFB
   ENDIF

   ::oParent:AddControl( Self )
   ::oXMLDesc := oXMLDesc

   ::Activate()
   ctrlOnSize( Self, ::oParent:nWidth, ::oParent:nHeight )

Return Self

METHOD Activate() CLASS HControlGen

 Memvar oCtrl

   IF ::oParent != Nil .AND. ::oParent:handle != 0
      IF ::cCreate != Nil
         Private oCtrl := Self
         ::handle := &( ::cCreate )
      ELSE
         ::handle := CreateStatic( ::oParent:handle, ::id, ;
               ::style, ::nLeft, ::nTop, ::nWidth,::nHeight )
      ENDIF
      ::Init()
   ENDIF
Return Nil

METHOD Paint( lpdis ) CLASS HControlGen
Local drawInfo := GetDrawItemInfo( lpdis )
local i,octrl2
Memvar hDC, oCtrl
Private hDC := drawInfo[3], oCtrl := Self

  IF ::aPaint != Nil
     DoScript( ::aPaint )
  ENDIF
  // :LFB pos
  IF LEN(asels) > 1
    for i=1 to Len(asels)
      octrl2 := asels[i]
      IF oCtrl2 != Nil .AND. ::handle == oCtrl2:handle
        SelectObject( hDC, oPenSel:handle )
        Rectangle( hDC, 0, 0, ::nWidth-1, ::nHeight-1 )
      ENDIF
    next
  ELSE // :LEFB
    oCtrl := GetCtrlSelected( HFormGen():oDlgSelected )
    IF oCtrl != Nil .AND. ::handle == oCtrl:handle
      SelectObject( hDC, oPenSel:handle )
      Rectangle( hDC, 0, 0, ::nWidth-1, ::nHeight-1 )
    ENDIF
  ENDIF // :END LFB

Return Nil

METHOD GetProp( cName,i ) CLASS HControlGen
//FP get property index
  i := ::GetPropIndex( cName )
Return Iif( i==0, Nil, ::aProp[i,2] )

METHOD GetPropIndex(cName ) CLASS HControlGen
local i := 0
   cName := Lower( cName )
   i := Ascan( ::aProp,{|a|Lower(a[1])==cName} )
Return (i)

METHOD SetProp( xName,xValue )
local iIndex := 0
   IF Valtype( xName ) == "C"
      xName := Lower( xName )
      //xName := Ascan( ::aProp,{|a|Lower(a[1])==xName} )
     iIndex := ::GetPropIndex( xName )
    ENDIF
    IF Valtype( xName ) == "N"
      iIndex := xName
    ENDIF


   //IF xName != 0
   //   ::aProp[xName,2] := xValue
   //ENDIF

   IF iIndex != 0
      ::aProp[iIndex,2] := xValue
   ENDIF

Return xValue

METHOD SetCoor( xName,nValue )
memvar oDesigner

   IF oDesigner:lReport
      nValue := Round( nValue/::oParent:oParent:oParent:oParent:nKoeff,1 )
   ENDIF
   ::SetProp( xName,Ltrim(Str(nValue)) )

Return nValue

// -----------------------------------------------

Function ctrlOnSize( oCtrl, x, y )
Local aControls := oCtrl:oParent:aControls,i,oCtrls
memvar oDesigner

   IF oCtrl:Adjust == 1
      oCtrl:Move( 0,0,x )
      oCtrl:SetProp( "Left","0" )
      //oCtrl:SetCoor( "Top",oCtrl:nTop )
      oCtrl:SetCoor( "Width",oCtrl:nWidth )
    ENDIF
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
   IF oCtrl:Adjust == 6
         oCtrl:Move(oCtrl:nLeft ,2 )
         oCtrl:SetProp( "Top","2" )
      //oCtrl:SetCoor( "Top",oCtrl:nTop )
      //oCtrl:SetCoor( "Width",oCtrl:nWidth )
   ENDIF

   IF oCtrl:Adjust == 5
      *-IF oCtrl:oParent:nTop != Nil
        FOR i=1 to len(acontrols)
          oCtrls := aControls[i]
              *-msginfo(STR(oCtrl:oParent:nTop)+'-'+STR(oCtrl:nTop)) //+'-'+STR(oCtrl:oparent:oParent:nTop))
              IF oCtrls:cClass="browse" .AND. (oCtrl:nTop > oCtrls:nTop .AND. oCtrl:nTop < oCtrls:nTop+oCtrls:nHeight)
                 oCtrl:Move(oCtrl:nLeft ,oCtrls:nTop+2 )
              *oCtrl:SetProp( "Top","oCtrls:nTop+2" )
              EXIT
               ENDIF
            NEXT
         *-ELSE
      *-   oCtrl:Move( ,2 )
      *-   oCtrl:SetProp( "Top","2" )
      //oCtrl:SetCoor( "Top",oCtrl:nTop )
      //oCtrl:SetCoor( "Width",oCtrl:nWidth )
      *-ENDIF
    ENDIF

Return Nil

Function CreateName( cPropertyName, oCtrl )
Local i, j, aControls := oCtrl:oParent:aControls, arr := {}
Local cName := IIF(cPropertyName!="v","o","v") + Upper( Left( oCtrl:cClass,1 ) ) + Substr( oCtrl:cClass,2 )
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
Local i, dx, dy , vdx , vdy ,mdx , mdy
Memvar oDesigner

   IF lChild == Nil .OR. !lChild
      lChild := .F.
      dx := xPos - aBDown[BDOWN_XPOS]
      dy := yPos - aBDown[BDOWN_YPOS]
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

   // writelog( "V0=("+alltrim(str(oCtrl:nLeft))+","+alltrim(str(oCtrl:nTop))+") P1=("+alltrim(str(xPos,5))+","+alltrim(str(yPos,5)
   // )+ ") B1=("+alltrim(str(aBDown[2]))+","+alltrim(str(aBDown[3]))+")  d=("+alltrim(str(dx,3))+","+alltrim(str(dy,3))+") " )
   // writelog( "vBDown=("+alltrim(str(vBDown[2]))+","+alltrim(str(vBDown[3]))+") " )

   IF dx != 0 .OR. dy != 0
      IF !lChild .AND. lMouse .AND. Abs( xPos - aBDown[BDOWN_XPOS] ) < 3 .AND. Abs( yPos - aBDown[BDOWN_YPOS] ) < 3
         Return .F.
      ENDIF

      IF IsCheckedMenuItem( oDesigner:oMainWnd:handle,1051 )
        IF !lChild .AND. lMouse
          vdx := xPos - vBDown[BDOWN_XPOS]
          vdy := yPos - vBDown[BDOWN_YPOS]
          mdx := vdx % oDesigner:nPixelGrid
          mdy := vdy % oDesigner:nPixelGrid

          if abs( int( ( ( mdx ) / oDesigner:nPixelGrid) * 10 ) ) <= 4
            mdx := mdx
          else
            mdx := (mdx - oDesigner:nPixelGrid )
          endif

          // writelog( "coordinate normalizzate=" +"   N= " +str(dx)+"   mdx="+str(mdx) )

          dx = ( vdx - oCtrl:nLeft ) - mdx

          // writelog( "Output:   dx= " +str(dx)+"   NLeft="+str(oCtrl:nLeft+dx)+ "  aBBDown2="+ alltrim(str(mdy)) )

          if abs( int( ( ( mdy ) / oDesigner:nPixelGrid) * 10 ) ) <= 4
            mdy := mdy
          else
            mdy := (mdy - oDesigner:nPixelGrid )
          endif

          dy = ( vdy - oCtrl:nTop ) - mdy
        ENDIF
      ENDIF

      InvalidateRect( oCtrl:oParent:handle, 1, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )

      IF oCtrl:nLeft + dx < 0
         dx := - oCtrl:nLeft
      ENDIF
      IF oCtrl:nTop + dy < 0
         dy := - oCtrl:nTop
      ENDIF

      oCtrl:nLeft := oCtrl:nLeft + dx
      oCtrl:nTop := oCtrl:nTop + dy
      oCtrl:SetCoor( "Left",oCtrl:nLeft)
      oCtrl:SetCoor( "Top",oCtrl:nTop)

      IF oDesigner:lReport
         oCtrl:SetCoor( "Right",oCtrl:nLeft+oCtrl:nWidth-1 )
         oCtrl:SetCoor( "Bottom",oCtrl:nTop+oCtrl:nHeight-1 )
      ENDIF
      IF !lChild
         aBDown[BDOWN_XPOS] := xPos
         aBDown[BDOWN_YPOS] := yPos
      ENDIF

      InvalidateRect( oCtrl:oParent:handle, 0, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )

      MoveWindow( oCtrl:handle, oCtrl:nLeft, oCtrl:nTop, oCtrl:nWidth, oCtrl:nHeight )
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
Memvar oDesigner

   IF xPos != aBDown[BDOWN_XPOS] .OR. yPos != aBDown[BDOWN_YPOS]
      InvalidateRect( oCtrl:oParent:handle, 1, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      dx := xPos - aBDown[BDOWN_XPOS]
      dy := yPos - aBDown[BDOWN_YPOS]
      IF aBDown[BDOWN_NBORDER] == 1
         IF oCtrl:nWidth - dx < 4
            dx := oCtrl:nWidth - 4
         ENDIF
         oCtrl:SetCoor( "Left",oCtrl:nLeft := oCtrl:nLeft + dx )
         oCtrl:SetCoor( "Width",oCtrl:nWidth := oCtrl:nWidth - dx )
         IF oDesigner:lReport
            oCtrl:SetCoor( "Right",oCtrl:nLeft+oCtrl:nWidth-1 )
         ENDIF
      ELSEIF aBDown[BDOWN_NBORDER] == 2
         IF oCtrl:nHeight - dy < 4
            dy := oCtrl:nHeight - 4
         ENDIF
         oCtrl:SetCoor( "Top",oCtrl:nTop := oCtrl:nTop + dy )
         oCtrl:SetCoor( "Height",oCtrl:nHeight := oCtrl:nHeight - dy )
         IF oDesigner:lReport
            oCtrl:SetCoor( "Bottom",oCtrl:nTop+oCtrl:nHeight-1 )
         ENDIF
      ELSEIF aBDown[BDOWN_NBORDER] == 3
         IF oCtrl:nWidth + dx < 4
            dx := 4 - oCtrl:nWidth
         ENDIF
         oCtrl:SetCoor( "Width",oCtrl:nWidth := oCtrl:nWidth + dx )
         IF oDesigner:lReport
            oCtrl:SetCoor( "Right",oCtrl:nLeft+oCtrl:nWidth-1 )
         ENDIF
      ELSEIF aBDown[BDOWN_NBORDER] == 4
         IF oCtrl:nHeight + dy < 4
            dy := 4 - oCtrl:nHeight
         ENDIF
         oCtrl:SetCoor( "Height",oCtrl:nHeight := oCtrl:nHeight + dy )
         IF oDesigner:lReport
            oCtrl:SetCoor( "Bottom",oCtrl:nTop+oCtrl:nHeight-1 )
         ENDIF
      ENDIF
      aBDown[BDOWN_XPOS] := xPos
      aBDown[BDOWN_YPOS] := yPos
      InvalidateRect( oCtrl:oParent:handle, 0, ;
               oCtrl:nLeft-4, oCtrl:nTop-4, ;
               oCtrl:nLeft+oCtrl:nWidth+3,  ;
               oCtrl:nTop+oCtrl:nHeight+3 )
      MoveWindow( oCtrl:handle, oCtrl:nLeft, oCtrl:nTop, oCtrl:nWidth, oCtrl:nHeight )
      IF oDesigner:lReport
         oCtrl:oParent:oParent:oParent:oParent:lChanged := .T.
      ELSE
         oCtrl:oParent:oParent:lChanged := .T.
      ENDIF
      InspUpdBrowse()
   ENDIF
Return Nil

Function SetBDown( oCtrl,xPos,yPos,nBorder )
   aBDown[ BDOWN_OCTRL ] := oCtrl
   aBDown[ BDOWN_XPOS ] := xPos
   aBDown[ BDOWN_YPOS ] := yPos
   aBDown[ BDOWN_NBORDER ] := nBorder
   IF oCtrl != Nil .AND. oCtrl:ClassName() != "HDIALOG" // NANDO POS DO AND EM DIANTE
      SetCtrlSelected( oCtrl:oParent,oCtrl )
   ELSE
     // nando pos  para maniplear marcar todos objetos com mouse
      aBDown[ BDOWN_OCTRL ] := oCtrl
      //
   ENDIF
Return Nil

Function GetBDown
Return aBDown

Function SetvBDown( oCtrl,xPos,yPos,nBorder )

   HB_SYMBOL_UNUSED( oCtrl )
   HB_SYMBOL_UNUSED( nBorder )

   vBDown[ BDOWN_OCTRL ] := nil
   vBDown[ BDOWN_XPOS ]  := xPos
   vBDown[ BDOWN_YPOS ]  := yPos
   vBDown[ BDOWN_NBORDER ] := 0
Return Nil

Function GetvBDown
Return vBDown

Function SetCtrlSelected( oDlg,oCtrl,n ,nShift)   // nando pos nshift
Local oFrm := Iif( oDlg:oParent:Classname()=="HPANEL",oDlg:oParent:oParent:oParent,oDlg:oParent ), handle, i, nSh
Memvar oDesigner

   IF ( oFrm:oCtrlSelected == Nil .AND. oCtrl != Nil ) .OR. ;
        ( oFrm:oCtrlSelected != Nil .AND. oCtrl == Nil ) .OR. ;
        ( oFrm:oCtrlSelected != Nil .AND. oCtrl != Nil .AND. ;
        oFrm:oCtrlSelected:handle != oCtrl:handle )
      handle := Iif( oCtrl!=Nil,oCtrl:oParent:handle, ;
                        oFrm:oCtrlSelected:oParent:handle )
      nSh := IIF(nShift != Nil,nShift,GetKeyState(VK_SHIFT))       // nando po
      IF oFrm:oCtrlSelected != Nil
        // aqui desmarca o anterior nando colocou
            IF nsh >= 0    // nando pos
           // NANDO POS O FOR
              FOR i = 1 to IIF(len(asels) > 0,LEN(asels),1)
               oFrm:oCtrlSelected := asels[i]  // NANDO POS
           InvalidateRect( oFrm:oCtrlSelected:oParent:handle, 1, ;
                  oFrm:oCtrlSelected:nLeft-4, oFrm:oCtrlSelected:nTop-4, ;
                  oFrm:oCtrlSelected:nLeft+oFrm:oCtrlSelected:nWidth+3,  ;
                  oFrm:oCtrlSelected:nTop+oFrm:oCtrlSelected:nHeight+3 )
           NEXT
        ELSEIF oCtrl == Nil
              // CASO ELE CLICOU NO FORM
          RETURN Nil
        ELSE
            // CASO ELE QUER DESMARCAR UM
          i := Ascan( aSels, {|a| a:GetProp( "Name") == oCtrl:GetProp( "Name")} )
              IF i > 0
              InvalidateRect( oCtrl:oParent:handle, 1, ;
                  oCtrl:nLeft-4, oCtrl:nTop-4, ;
                  oCtrl:nLeft+oCtrl:nWidth+3,  ;
                  oCtrl:nTop+oCtrl:nHeight+3 )
                  ADEL(aSels,i)
                 ASIZE(Asels,LEN(aSels)-1)
            RETURN nil
          ENDIF
          //
        ENDIF
      ENDIF
      // nando pos
        aSels := iIF( nsh >= 0, {} ,asels)
        IF oCtrl != Nil
           AADD(aSels,oCtrl)
        ENDIF
      //

      oFrm:oCtrlSelected := oCtrl
      IF oCtrl != Nil
         InvalidateRect( oCtrl:oParent:handle, 0, ;
                  oCtrl:nLeft-4, oCtrl:nTop-4, ;
                  oCtrl:nLeft+oCtrl:nWidth+3,  ;
                  oCtrl:nTop+oCtrl:nHeight+3 )
         // nando pos
             IF nShift != Nil
               RETURN Nil
             ENDIF
         IF oDesigner:oDlgInsp != Nil
            IF n != Nil
               i := n
            ELSE
               i := Ascan( oDlg:aControls,{|o|o:handle==oCtrl:handle} )
            ENDIF
            InspUpdCombo( i )
         ENDIF
      ELSE
         IF oDesigner:oDlgInsp != Nil
            InspUpdCombo( 0 )
         ENDIF
      ENDIF
      SendMessage( handle,WM_PAINT,0,0 )
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

   // writelog( "MoveCtrl "+str(oCtrl:nWidth) + str(oCtrl:nHeight) )
   IF oCtrl:ClassName() == "HDIALOG"
      SendMessage( oCtrl:handle, WM_MOVE, 0, oCtrl:nLeft + oCtrl:nTop*65536 )
      SendMessage( oCtrl:handle, WM_SIZE, 0, oCtrl:nWidth + oCtrl:nHeight*65536 )
   ELSE
      MoveWindow( oCtrl:handle,oCtrl:nLeft,oCtrl:nTop,oCtrl:nWidth,oCtrl:nHeight )
      RedrawWindow( oCtrl:oParent:handle,RDW_ERASE + RDW_INVALIDATE )
   ENDIF
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
         ELSEIF lRight .AND. oCtrl:nLeft+oCtrl:nWidth < aControls[i]:nLeft .AND. ;
            oCtrl:nLeft+oCtrl:nWidth >= aControls[i]:nLeft - delta .AND. ;
            oCtrl:nTop >= aControls[i]:nTop .AND. aControls[i]:nTop + aControls[i]:nHeight > oCtrl:nTop
            lRes := .T.
            xPos := aControls[i]:nLeft-oCtrl:nWidth - 1
            yPos := aControls[i]:nTop
            EXIT
         ELSEIF lBottom .AND. Abs( aControls[i]:nLeft-oCtrl:nLeft ) <= delta .AND. ;
                aControls[i]:nTop > oCtrl:nTop + oCtrl:nHeight .AND. ;
                aControls[i]:nTop - delta <= oCtrl:nTop + oCtrl:nHeight
            lRes := .T.
            xPos := aControls[i]:nLeft
            yPos := aControls[i]:nTop - oCtrl:nHeight - 1
            EXIT
         ENDIF
      ENDIF
   NEXT
   IF lRes
      CtrlMove( oCtrl,xPos-oCtrl:nLeft,yPos-oCtrl:nTop,.F.,.T. )
      Container( oCtrl:oParent,oCtrl,oCtrl:nLeft,oCtrl:nTop )
      InspUpdBrowse()
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
   AddTab( oTab:handle, Len( aTabs ), "New Page" )
   Aadd( aTabs,"New Page" )
   InspUpdProp( "Tabs", aTabs )
   RedrawWindow( oTab:handle,5 )
Return Nil

Function Page_Next( oTab )
   HB_SYMBOL_UNUSED( oTab )
Return Nil

Function Page_Prev( oTab )
   HB_SYMBOL_UNUSED( oTab )
Return Nil

Function Page_Upd( oTab, arr )
Local i, nTabs := SendMessage( oTab:handle,TCM_GETITEMCOUNT,0,0 )

   FOR i := 1 TO Len( arr )
      IF i <= nTabs
         SetTabName( oTab:handle, i-1, arr[i] )
      ELSE
         AddTab( oTab:handle, i-1, arr[i] )
      ENDIF
   NEXT

Return Nil

Function Page_Select( oTab, nTab, lForce )
Local i, j, oCtrl

   IF ( lForce != Nil .AND. lForce ) .OR. GetCurrentTab( oTab:handle ) != nTab

      SendMessage( oTab:handle, TCM_SETCURSEL, nTab-1, 0 )
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

   INIT DIALOG oDlg TITLE "Edit Menu" ;
        AT 300,280 SIZE 400,350 FONT oDesigner:oMainWnd:oFont ;
        STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SIZEBOX ;
        ON INIT {||BuildTree( oTree,aMenu )}

   @ 10,20 TREE oTree OF oDlg SIZE 210,240 STYLE WS_BORDER EDITABLE
   oTree:bItemChange := {|o,s|VldItemChange(aMenu,o,s)}

   @ 240,20 BUTTON "Rename" SIZE 140,28 ON CLICK {||EditTree(aMenu,oTree,0)}
   @ 240,54 BUTTON "Add item after" SIZE 140,28 ON CLICK {||EditTree(aMenu,oTree,1)}
   @ 240,88 BUTTON "Add item before" SIZE 140,28 ON CLICK {||EditTree(aMenu,oTree,2)}
   @ 240,122 BUTTON "Add child item" SIZE 140,28 ON CLICK {||EditTree(aMenu,oTree,3)}
   @ 240,156 BUTTON "Insert Separador" SIZE 140,28 ON CLICK {||EditTree(aMenu,oTree,9)}
   @ 240,190 BUTTON "Delete" SIZE 140,28 ON CLICK {||EditTree(aMenu,oTree,4)}
   @ 240,224 BUTTON "Edit code" SIZE 140,28 ON CLICK {||EditTree(aMenu,oTree,10)}

   @ 40,290 BUTTON "Ok" SIZE 100,30 ON CLICK {||oDlg:lResult:=.T.,EndDialog()}
   @ 260,290 BUTTON "Cancel" SIZE 100,30 ON CLICK {||EndDialog()}

   oDlg:AddEvent( 0,IDOK,{||SetFocus(oDlg:aControls[2]:handle)} )
   oDlg:AddEvent( 0,IDCANCEL,{||SetFocus(oDlg:aControls[2]:handle)} )

   ACTIVATE DIALOG oDlg
   IF oDlg:lResult
      HFormGen():oDlgSelected:aControls[i]:SetProp( "aTree",aMenu )
   ENDIF

Return Nil

Static Function BuildTree( oParent, aMenu )
Local i := Len( aMenu ), oNode
Memvar nMaxId

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
Memvar nMaxID

   IF nAction == 0       // Rename
      oTree:EditLabel( oTree:oSelected )
   ELSEIF nAction == 1   // Insert after
      IF oTree:oSelected:oParent == Nil
         oNode := oTree:AddNode( "New",oTree:oSelected )
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
   ELSEIF nAction == 2   // Insert before
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
   ELSEIF nAction == 9   // Insert Separaodr
      IF oTree:oSelected:oParent == Nil
         oNode := oTree:AddNode( "-",oTree:oSelected )
      ELSE
         oNode := oTree:oSelected:oParent:AddNode( "-",oTree:oSelected )
      ENDIF
      //oTree:EditLabel( oNode )
      nMaxId ++
      oNode:cargo := nMaxId
      IF ( aSubarr := FindTreeItem( aTree, oTree:oSelected:cargo, @nPos ) ) != Nil
         Aadd( aSubarr,Nil )
         Ains( aSubarr,nPos+1 )
         aSubarr[nPos+1] := { Nil,"-",nMaxId,Nil }
      ENDIF
   ELSEIF nAction == 3   // Insert child
      oNode := oTree:oSelected:AddNode( "New" )
      oTree:Expand( oTree:oSelected )
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
      IF ( aSubarr := FindTreeItem( aTree, oTree:oSelected:cargo, @nPos ) ) != Nil
         Adel( aSubarr,nPos )
         Asize( aSubarr,Len(aSubarr)-1 )
      ENDIF
      oTree:oSelected:Delete()
   ELSEIF nAction == 10  &&.AND. oTree:oSelected:cargo != "SEPARATOR" // Edit code
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

 //....................................................................
 // : LFB
 //
 FUNCTION aselCtrls
 RETURN aSels


 FUNCTION asels_ajustar(najuste)
 // align left  sides
 // align right  sides
 // align top edges
 // align bottom edges
 // Same Width
 // Same Height
 // center horizontally
 // center vertically
 Local oCtrl,nminLeft , nmaxright, nminTop, nmaxbottom, nmaxwidth, nmaxheight,i
 Local nCenterTop, nCenterLeft
 Local asels := aselCtrls()

 IF LEN(aSels) <= 1 .AND. nAjuste <7
   RETURN Nil
 ENDIF
 oCtrl := asels[1]
 nminLeft   := octrl:nLeft
 nmaxright  := octrl:nLeft + octrl:nWidth
 nminTop    := octrl:nTop
 nmaxbottom := octrl:nTop + octrl:nHeight
 nmaxwidth  := octrl:nWidth
 nmaxheight := octrl:nHeight
 *-nTop, nLeft, nWidth, nHeight
 ncenterTop := INT(octrl:oparent:nHeight / 2)
 nCenterLeft := INT(octrl:oparent:nWidth / 2)
 IF LEN(aSels) = 1
   IF nAjuste = 8
        // center horizontally
       SetBDown( ,0,0,0 )
      CtrlMove(oCtrl,0,(nCenterTop-INT(oCtrl:nHeight/2))-oCtrl:nTop,.F.,.F.)
     ELSEIF nAjuste = 7
        // center vertically
      SetBDown( ,0,0,0 )
    CtrlMove(oCtrl,(nCenterLeft-INT(oCtrl:nWidth/2))-oCtrl:nLeft,0,.F.,.F.)
   ENDIF
   RETURN Nil
 ENDIF

 FOR i = 2 to len(asels)
    oCtrl := asels[i]
    IF oCtrl != Nil
       nminLeft   := IIF(octrl:nLeft < nminLeft,octrl:nLeft,nminLeft)
       nmaxright  := IIF(octrl:nLeft + octrl:nWidth > nmaxRight,octrl:nLeft + octrl:nWidth,nmaxright)
       nminTop    := IIF(octrl:nTop < nMinTop,octrl:nTop,nMinTop)
      nmaxbottom := IIF(octrl:nTop + octrl:nHeight > nmaxBottom,octrl:nTop + oCtrl:nHeight,nmaxBottom)
       nmaxwidth  := IIF(octrl:nWidth > nmaxWidth,octrl:nWidth,nmaxWidth)
       nmaxheight := IIF(octrl:nHeight > nmaxHeight,octrl:nHeight,nmaxHeight)
    ENDIF
 NEXT
 FOR i = 1 to len(asels)
   oCtrl := asels[i]
    IF nAjuste = 1
      // alinhas a esquerda
       SetBDown( ,0,0,0 )
      CtrlMove(oCtrl,nMinLeft-oCtrl:nLeft,0,.F.,.F.)
     ELSEIF nAjuste = 2
         // alinhar a direita
    SetBDown( ,0,0,0 )
    CtrlMove(oCtrl,nMaxRight-oCtrl:nWidth-oCtrl:nLeft,0,.F.,.F.)
     ELSEIF nAjuste = 3
           // alinhar ao TOP
       SetBDown( ,0,0,0 )
      CtrlMove(oCtrl,0,nMinTop-oCtrl:nTop,.F.,.F.)
     ELSEIF nAjuste = 4
           *-oCtrl:nBottom := nmaxBottom
     ELSEIF nAjuste = 5
         // same Width
       SetBDown( , oCtrl:nLeft,oCtrl:nTop,3 )
      CtrlResize( OCTRL,oCtrl:nLeft+(nMaxWidth-oCtrl:nWidth),oCtrl:nTop)
     ELSEIF nAjuste = 6
           // same Height
           SetBDown( , oCtrl:nLeft,oCtrl:nTop,4 )
           CtrlResize( OCTRL,oCtrl:nLeft,oCtrl:nTop+(nMaxHeight-oCtrl:nHeight))
     ELSEIF nAjuste = 8
        // center horizontally
      SetBDown( ,0,0,0 )
    CtrlMove(oCtrl,0,(nCenterTop-INT((nMaxBottom-nMinTop)/2))-nMinTop,.F.,.F.)
     ELSEIF nAjuste = 7
        // center vertically
      SetBDown( ,0,0,0 )
    CtrlMove(oCtrl,(nCenterLeft-INT((nMaxRight-nMinLeft)/2))-nMinLeft,0,.F.,.F.)

     ENDIF
 NEXT

 RETURN Nil

Function RegionSelect(odlg,xi,yi,xPos,yPos)
  Local pps, hDC, xf,yf

   pps := DefinePaintStru()
   hDC := GetDC( GetActiveWindow() )
   IF oPenSel == Nil
      oPenSel := HPen():Add( PS_SOLID,1,255 )
   ENDIF
  SelectObject( hDC, oPenSel:handle )
  IF xpos < xi
    xf := xi
    xi := xpos
    xpos := xf
  ENDIF
  IF ypos < yi
    yf := yi
    yi := ypos
    ypos := yf
  ENDIF
  InvalidateRect( odlg:handle, 1, xPos+1, yPos+1,  xPos+2,yPos+2 )
  Rectangle( hDC, xi, yi, xPos+1,yPos+1 )
  InvalidateRect( odlg:handle, 1,  xi+1, yi+1,  xPos,yPos )

 RETURN Nil


FUNCTION selsobjetos(odlg,xi,yi,xpos,ypos)
Local Octrl, i, xf,yf

 IF xpos < xi
   xf:=xi
   xi := xpos
   xpos := xf
 ENDIF
 IF ypos < yi
   yf:=yi
   yi := ypos
   ypos := yf
 ENDIF
 //msginfo(str(xi)+','+str(yi)+','+str(xpos)+','+str(ypos))
 FOR i = 1 to Len( oDlg:aControls )
    oCtrl := oDlg:aControls[i]
    IF ((yi <= oCtrl:nTop +  oCtrl:nHeight .AND. yPos >= oCtrl:nTop) .OR. ;
         (yPos <= oCtrl:nTop + oCtrl:nHeight .AND. yi >= oCtrl:nTop)) .AND. ;
       ((xi <= oCtrl:nLeft + oCtrl:nWidth .AND. xPos >= oCtrl:nLeft) .OR.;
          (xPos <= oCtrl:nLeft + oCtrl:nWidth .AND. xi >= oCtrl:nLeft))
         SetCtrlSelected( oCtrl:oParent,oCtrl,,-128)
    ENDIF
 NEXT
Return Nil

FUNCTION AUTOSIZE(oCtrl)
LOCAL aSize :={}

   IF oCtrl:oFont != NIL
        asize :=  GETTEXTWIDTH(oCtrl:title+" ",oCtrl:oFont,GetDC(oCtrl:handle)) //nHdc)
     ELSE
        asize :=  GETTEXTWIDTH(oCtrl:title+" ",oCtrl:oparent:oFont,GetDC(oCtrl:handle)) //nHdc)
    ENDIF
    IF octrl:nLeft = Nil
      return nil
    ENDIF
     SetBDown( , oCtrl:nWidth,oCtrl:nHeight,3 )
    CtrlResize( OCTRL,asize[1],oCtrl:nTop)
     SetBDown( , oCtrl:nLeft,oCtrl:nHeight,4 )
     CtrlResize( OCTRL,oCtrl:nLeft,asize[2])

   RETURN Nil

FUNCTION GetTextWidth( cString, oFont ,hdc)
Local arr, hFont

   IF oFont != Nil
      hFont := SelectObject( hDC,oFont:handle )
   ENDIF
   arr := GetTextSize( hDC,cString )
   IF oFont != Nil
      SelectObject( hDC,hFont )
   ENDIF

Return arr

// :END LFB
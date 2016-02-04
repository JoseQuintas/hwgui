/*
 * $Id$
 *
 * Designer
 * Object Inspector
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "fileio.ch"
#include "hwgui.ch"
#include "designer.ch"

Static oCombo, oBrw1, oBrw2
Static aProp := {}, aMethods := {}
Static oTab

Memvar oDesigner

Function InspOpen

   INIT DIALOG oDesigner:oDlgInsp TITLE "Object Inspector" ;
      AT 0,280  SIZE 220,300                     ;
      STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SIZEBOX ;
      FONT oDesigner:oMainWnd:oFont                   ;
      ON INIT {||hwg_Movewindow(oDesigner:oDlgInsp:handle,0,280,230,280)}   ;
      ON EXIT {||oDesigner:oDlgInsp:=Nil,hwg_Checkmenuitem(oDesigner:oMainWnd:handle,MENU_OINSP,.F.),.T.}

   @ 0,0 COMBOBOX oCombo ITEMS {} SIZE 220,26 ;
          STYLE WS_VSCROLL                     ;
          ON SIZE {|o,x,y|hwg_Movewindow(o:handle,0,0,x,)} ;
          ON CHANGE {||ComboOnChg()}

   @ 0,28 TAB oTab ITEMS {} SIZE 220,250 ;
      ON SIZE {|o,x,y|hwg_Movewindow(o:handle,0,28,x,y-28)}

   BEGIN PAGE "Properties" OF oTab
      @ 2,30 BROWSE oBrw1 ARRAY SIZE 214,218 STYLE WS_VSCROLL ;
         ON CLICK {||Edit1()} ON SIZE {|o,x,y|hwg_Movewindow(o:handle,2,30,x-6,y-32)}
#ifndef __GTK__
      oBrw1:tColor := hwg_Getsyscolor( COLOR_BTNTEXT )
      oBrw1:bColor := oBrw1:bColorSel := hwg_Getsyscolor( COLOR_BTNFACE )
      oBrw1:lSep3d := .T.
#endif
      oBrw1:tColorSel := 8404992
      oBrw1:freeze := 1
      oBrw1:lDispHead := .F.
      oBrw1:sepColor  := hwg_Getsyscolor( COLOR_BTNSHADOW )
      oBrw1:aArray := aProp
      oBrw1:AddColumn( HColumn():New( ,{|v,o|Iif(Empty(o:aArray[o:nCurrent,1]),"","  "+o:aArray[o:nCurrent,1])},"C",12,0,.T. ) )
      oBrw1:AddColumn( HColumn():New( ,hwg_ColumnArBlock(),"U",100,0,.T. ) )
   END PAGE OF oTab

   BEGIN PAGE "Events" OF oTab
      @ 2,30 BROWSE oBrw2 ARRAY SIZE 214,218 STYLE WS_VSCROLL ;
         ON CLICK {||Edit2()} ON SIZE {|o,x,y|hwg_Movewindow(o:handle,2,30,x-6,y-32)}
#ifndef __GTK__
      oBrw2:tColor := hwg_Getsyscolor( COLOR_BTNTEXT )
      oBrw2:bColor := oBrw2:bColorSel := hwg_Getsyscolor( COLOR_BTNFACE )
      oBrw2:lSep3d := .T.
#endif
      oBrw2:tColorSel := 8404992
      oBrw2:freeze := 1
      oBrw2:lDispHead := .F.
      oBrw2:sepColor  := hwg_Getsyscolor( COLOR_BTNSHADOW )
      oBrw2:aArray := aMethods
      oBrw2:AddColumn( HColumn():New( ,{|v,o|Iif(Empty(o:aArray[o:nCurrent,1]),"","  "+o:aArray[o:nCurrent,1])},"C",12,0,.T. ) )
      oBrw2:AddColumn( HColumn():New( ,{|v,o|Iif(Empty(o:aArray[o:nCurrent,2]),"",":"+o:aArray[o:nCurrent,1])},"C",100,0,.T. ) )
   END PAGE OF oTab

   ACTIVATE DIALOG oDesigner:oDlgInsp NOMODAL
   hwg_Checkmenuitem(oDesigner:oMainWnd:handle,MENU_OINSP,.T.)

   InspSetCombo()

   oDesigner:oDlgInsp:AddEvent( 0,IDOK,{||DlgOk()} )
   oDesigner:oDlgInsp:AddEvent( 0,IDCANCEL,{||DlgCancel()} )

Return Nil

Static Function Edit1()
Local varbuf, x1, y1, nWidth, j, cName, aCtrlProp, oGet
Local aDataDef := oDesigner:aDataDef
Local lRes := .F., oModDlg, oColumn, aCoors, nChoic, bInit, aItems
Memvar value, oCtrl
Private value, oCtrl := Iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )

   IF oBrw1:SetColumn() == 1
      Return Nil
   ENDIF
   oBrw1:cargo := Eval( oBrw1:bRecno,oBrw1 )
   IF oCombo:value == 1
      aCtrlProp := oCtrl:oParent:aProp
   ELSE
      aCtrlProp := oCtrl:aProp
   ENDIF
   oColumn := oBrw1:aColumns[2]
   cName := Lower( aProp[oBrw1:cargo,1] )
   j := Ascan( aDataDef, {|a|a[1]==cName} )
   varbuf := Eval( oColumn:block,,oBrw1,2 )

   IF ( j != 0 .AND. aDataDef[ j,5 ] != Nil ) .OR. aCtrlProp[ oBrw1:cargo,3 ] == "A"
      IF j != 0 .AND. aDataDef[ j,5 ] != Nil
         IF aDataDef[ j,5 ] == "color"
            varbuf := Hwg_ChooseColor( Val(varbuf),.F. )
            IF varbuf != Nil
               varbuf := Ltrim( Str( varbuf ) )
               lRes := .T.
            ENDIF
         ELSEIF aDataDef[ j,5 ] == "font"
            varbuf := HFont():Select( varbuf )
            IF varbuf != Nil
               lRes := .T.
            ENDIF
         ELSEIF aDataDef[ j,5 ] == "file"
            varbuf := hwg_Selectfile( "All files ( *.* )","*.*" )
            IF varbuf != Nil
               lRes := .T.
            ENDIF
         ENDIF
      ELSE
         varbuf := EditArray( varbuf )
         IF varbuf != Nil
            lRes := .T.
         ENDIF
      ENDIF

      IF lRes
         cName := Lower( aProp[ oBrw1:cargo,1 ] )
         j := Ascan( aDataDef, {|a|a[1]==cName} )
         value := aProp[ oBrw1:cargo,2 ] := varbuf
         aCtrlProp[ oBrw1:cargo,2 ] := value
         IF j != 0 .AND. aDataDef[ j,3 ] != Nil
            EvalCode( aDataDef[ j,3 ] )
            IF aDataDef[ j,4 ] != Nil
               EvalCode( aDataDef[ j,4 ] )
            ENDIF
         ENDIF
         hwg_Redrawwindow( oCtrl:handle,5 )
         HFormGen():oDlgSelected:oParent:lChanged := .T.
         oBrw1:lUpdated := .T.
         oBrw1:Refresh()
      ENDIF
   ELSE
      x1  := oBrw1:x1 + oBrw1:aColumns[1]:width - 2
      y1 := oBrw1:y1 + ( oBrw1:height+1 ) * ( oBrw1:rowPos - 1 )
      nWidth := Min( oBrw1:aColumns[2]:width, oBrw1:x2 - x1 - 1 )

      ReadExit( .T. )
      IF ( j != 0 .AND. aDataDef[ j,6 ] != Nil ) .OR. aCtrlProp[ oBrw1:cargo,3 ] == "L"

         aItems := Iif( j != 0 .AND. aDataDef[ j,6 ] != Nil, aDataDef[ j,6 ], { "True","False" } )
         varbuf := AllTrim(varbuf)
         nChoic := Ascan( aItems,varbuf )

         @ x1,y1-2 COMBOBOX oGet         ;
            ITEMS aItems                 ;
            INIT nChoic                  ;
            OF oBrw1                     ;
            SIZE nWidth, oBrw1:height*5  ;
            FONT oBrw1:oFont

         IF ( j := Ascan( oBrw1:aEvents, {|a|a[1] == CBN_KILLFOCUS .AND. ;
               a[2] == oGet:id } ) ) > 0
            oBrw1:aEvents[j,3] := {||VldBrwGet(oGet)}
         ELSE
            oBrw1:AddEvent( CBN_KILLFOCUS,oGet:id,{||VldBrwGet(oGet)} )
         ENDIF
      ELSE
         @ x1,y1-2 GET oGet VAR varbuf OF oBrw1  ;
            SIZE nWidth, oBrw1:height+6        ;
            STYLE ES_AUTOHSCROLL               ;
            FONT oBrw1:oFont                   ;
            VALID {||VldBrwGet(oGet)}
         oGet:nMaxLength := 0
      ENDIF
      hwg_Setfocus( oGet:handle )
   ENDIF
RETURN Nil

Static Function Edit2()
Local value, cargo

   IF oBrw2:SetColumn() == 1
      Return Nil
   ENDIF
   cargo := oBrw2:cargo := Eval( oBrw2:bRecno,oBrw2 )
   IF ( value := EditMethod( aMethods[cargo,1],aMethods[cargo,2] ) ) != Nil ;
       .AND. !( aMethods[cargo,2] == value )
      aMethods[cargo,2] := value
      IF oCombo:value == 1
         HFormGen():oDlgSelected:oParent:aMethods[cargo,2] := value
      ELSE
         GetCtrlSelected( HFormGen():oDlgSelected ):aMethods[cargo,2] := value
      ENDIF
      HFormGen():oDlgSelected:oParent:lChanged := .T.
      oBrw2:lUpdated := .T.
      oBrw2:Refresh()
   ENDIF
Return Nil

Static Function VldBrwGet( oGet )
Local vari, j, cName
Memvar value, oCtrl
Private value, oCtrl := Iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )

   cName := Lower( aProp[ oBrw1:cargo,1 ] )

   j := Ascan( oDesigner:aDataDef, {|a|a[1]==cName} )

   IF oGet:Classname() == "HCOMBOBOX"
      vari := hwg_Sendmessage( oGet:handle,CB_GETCURSEL,0,0 ) + 1
      value := aProp[ oBrw1:cargo,2 ] := oGet:aItems[ vari ]
   ELSE
      vari := oGet:GetText()
      value := aProp[ oBrw1:cargo,2 ] := vari
   ENDIF
   IF oCombo:value == 1
      oCtrl:oParent:aProp[ oBrw1:cargo,2 ] := value
   ELSE
      oCtrl:aProp[ oBrw1:cargo,2 ] := value
   ENDIF
   IF j != 0 .AND. oDesigner:aDataDef[ j,3 ] != Nil
      EvalCode( oDesigner:aDataDef[ j,3 ] )
      IF oDesigner:aDataDef[ j,4 ] != Nil
         EvalCode( oDesigner:aDataDef[ j,4 ] )
      ENDIF
   ENDIF
   hwg_Redrawwindow( oCtrl:handle,5 )
   HFormGen():oDlgSelected:oParent:lChanged := .T.
   oBrw1:lUpdated := .T.
   oBrw1:DelControl( oGet )

Return .T.

Static Function DlgOk()

   IF !Empty( oBrw1:aControls )
      VldBrwGet( oBrw1:aControls[1] )
   ENDIF
Return Nil

Static Function DlgCancel()
Local oDlg

   IF !Empty( oBrw1:aControls )
      IF ( oDlg := hwg_ParentGetDialog( oBrw1:aControls[1] ) ) != Nil
         oDlg:nLastKey := 0
      ENDIF

      oBrw1:DelControl( oBrw1:aControls[1] )
      oBrw1:Refresh()
   ENDIF
Return Nil

Function InspSetCombo()
Local i, aControls, oCtrl, n := -1, oDlg := HFormGen():oDlgSelected

   oCombo:aItems := {}
   IF oDlg != Nil
      n := 0
      Aadd( oCombo:aItems, "Form." + oDlg:title )
      oCtrl := GetCtrlSelected( oDlg )
      aControls := Iif( oDesigner:lReport, oDlg:aControls[1]:aControls[1]:aControls, ;
          oDlg:aControls )
      FOR i := 1 TO Len( aControls )
         Aadd( oCombo:aItems, aControls[i]:cClass + "." + Iif(aControls[i]:title!=Nil,Left(aControls[i]:title,15),Ltrim(str(aControls[i]:id)) ) )
         IF oCtrl != Nil .AND. oCtrl:handle == aControls[i]:handle
            n := i
         ENDIF
      NEXT
   ENDIF
   oCombo:Refresh( n+1 )
   //oCombo:value := n + 1
   InspSetBrowse()
Return Nil

Function InspUpdCombo( n )
Local aControls, i

   IF n > 0
      aControls := Iif( oDesigner:lReport, ;
         HFormGen():oDlgSelected:aControls[1]:aControls[1]:aControls, ;
         HFormGen():oDlgSelected:aControls )
      i := Len( aControls )
      IF i >= Len( oCombo:aItems )
         Aadd( oCombo:aItems, aControls[i]:cClass + "." + Iif(aControls[i]:title!=Nil,Left(aControls[i]:title,15),Ltrim(str(aControls[i]:id)) ) )
      ELSEIF i + 1 < Len( oCombo:aItems )
         Return InspSetCombo()
      ENDIF
   ENDIF
   oCombo:Refresh( n+1 )
   //oCombo:value := n + 1
   InspSetBrowse()
Return Nil

Static Function ComboOnChg()
Local oDlg := HFormGen():oDlgSelected, oCtrl, n
Local aControls := Iif( oDesigner:lReport,oDlg:aControls[1]:aControls[1]:aControls,oDlg:aControls )

   oCombo:GetValue()
   IF oDlg != Nil
      n := oCombo:xValue - 1
      oCtrl := GetCtrlSelected( oDlg )
      IF n == 0
         IF oCtrl != Nil
            SetCtrlSelected( oDlg )
         ENDIF
      ELSEIF n > 0
         IF oCtrl == Nil .OR. oCtrl:handle != aControls[n]:handle
            SetCtrlSelected( oDlg,aControls[n],n )
         ENDIF
      ENDIF
   ENDIF
Return .T.

Static Function InspSetBrowse()
Local i, o

   aProp := {}
   aMethods := {}

   IF oCombo:value > 0
      o := Iif( oCombo:value == 1, HFormGen():oDlgSelected:oParent, GetCtrlSelected( HFormGen():oDlgSelected ) )
      FOR i := 1 TO Len( o:aProp )
         IF Len( o:aProp[i] ) == 3
            Aadd( aProp, { o:aProp[i,1], o:aProp[i,2] } )
         ENDIF
      NEXT
      FOR i := 1 TO Len( o:aMethods )
         Aadd( aMethods, { o:aMethods[i,1], o:aMethods[i,2] } )
      NEXT
   ENDIF

   oBrw1:aArray := aProp
   oBrw2:aArray := aMethods

   Eval( oBrw1:bGoTop,oBrw1 )
   Eval( oBrw2:bGoTop,oBrw2 )
   oBrw1:rowPos := 1
   oBrw2:rowPos := 1
   oBrw1:Refresh()
   oBrw2:Refresh()

Return Nil

Function InspUpdBrowse()
Local i, j, lChg := .F.
Memvar value, oCtrl
Private value, oCtrl

   IF oCombo == Nil
      Return Nil
   ENDIF
   oCtrl := Iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )
   IF oDesigner:oDlgInsp != Nil
      FOR i := 1 TO Len( aProp )
         value := Iif( oCombo:value == 1,oCtrl:oParent:aProp[ i,2 ],oCtrl:aProp[ i,2 ] )
         IF Valtype(aProp[ i,2 ]) != "O" .AND. Valtype(aProp[ i,2 ]) != "A" ;
               .AND. ( aProp[ i,2 ] == Nil .OR. !( aProp[ i,2 ] == value ) )
            aProp[ i,2 ] := value
            lChg := .T.
         ENDIF
      NEXT
      IF lChg .AND. !oBrw1:lHide
         oBrw1:Refresh()
      ENDIF
   ENDIF
 
Return Nil

Function InspUpdProp( cName, xValue )
Local i

   cName := Lower( cName )
   IF ( i := Ascan( aProp, {|a|Lower(a[1])==Lower(cName)} ) ) > 0
      aProp[ i,2 ] := xValue
      oBrw1:Refresh()
   ENDIF

Return Nil

Static Function EditArray( arr )
Local oDlg, oBrw, nRec := Eval( oBrw1:bRecno,oBrw1 ), i

   IF arr == Nil
      arr := {}
   ENDIF
   IF Empty( arr )
      Aadd( arr,"....." )
   ENDIF
   INIT DIALOG oDlg TITLE "Edit "+aProp[nRec,1]+" array" ;
        AT 300,280 SIZE 400,300 FONT oDesigner:oMainWnd:oFont

   @ 0,0 BROWSE oBrw ARRAY SIZE 400,255  ;
       ON SIZE {|o,x,y|o:Move(,,x,y-45)}      

   oBrw:bcolor := 15132390
   oBrw:bcolorSel := hwg_ColorC2N( "008000" )
   oBrw:lAppable := .T.
   oBrw:aArray := arr
   oBrw:AddColumn( HColumn():New( ,{|v,o|Iif(v!=Nil,o:aArray[o:nCurrent]:=v,o:aArray[o:nCurrent])},"C",100,0,.T.,,,Replicate("X",100) ) )

   @ 30,265 BUTTON "Ok" SIZE 100, 32     ;
       ON SIZE {|o,x,y|o:Move(,y-35,,)}  ;
       ON CLICK {||oDlg:lResult:=.T.,hwg_EndDialog()}
   @ 170,265 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ;
       ON SIZE {|o,x,y|o:Move(,y-35,,)}

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF Len( arr ) == 1 .AND. arr[1] == "....."
         arr := {}
      ENDIF
      FOR i := 1 TO Len( arr )
         arr[i] := Trim( arr[i] )
      NEXT
      Return arr
   ENDIF

Return Nil

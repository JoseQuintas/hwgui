/*
 * $Id: inspect.prg,v 1.10 2004-12-08 08:23:17 alkresin Exp $
 *
 * Designer
 * Object Inspector
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "fileio.ch"
#include "windows.ch"
#include "HBClass.ch"
#include "guilib.ch"

#define CBN_KILLFOCUS       4

#xcommand @ <x>,<y> PBROWSE [ <oBrw> ] ;
            [ <lArr: ARRAY> ]          ;
            [ <lDb: DATABASE> ]        ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bEnter> ]      ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ STYLE <nStyle> ]         ;
            [ <lNoVScr: NO VSCROLL> ]  ;
            [ <lNoBord: NO BORDER> ]   ;
            [ FONT <oFont> ]           ;
            [ <lAppend: APPEND> ]      ;
            [ <lAutoedit: AUTOEDIT> ]  ;
            [ ON UPDATE <bUpdate> ]    ;
            [ ON KEYDOWN <bKeyDown> ]  ;
          => ;
    [<oBrw> :=] PBrowse():New( Iif(<.lDb.>,BRW_DATABASE,Iif(<.lArr.>,BRW_ARRAY,0)),;
        <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>,<height>,<oFont>,<bInit>,<bSize>, ;
        <bDraw>,<bEnter>,<bGfocus>,<bLfocus>,<.lNoVScr.>,<.lNoBord.>, <.lAppend.>,;
        <.lAutoedit.>, <bUpdate>, <bKeyDown> )

Static oCombo, oBrw1, oBrw2
Static aProp := {}, aMethods := {}
Static oTab

CLASS PBrowse INHERIT HBrowse

   METHOD New( lType,oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
                  bInit,bSize,bPaint,bEnter,bGfocus,bLfocus,lNoVScroll,     ;
                  lNoBorder,lAppend,lAutoedit,bUpdate,bKeyDown )
   METHOD Edit()
   METHOD HeaderOut( hDC )
ENDCLASS

METHOD New( lType,oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
               bInit,bSize,bPaint,bEnter,bGfocus,bLfocus,lNoVScroll,     ;
               lNoBorder,lAppend,lAutoedit,bUpdate,bKeyDown ) CLASS PBrowse

   Super:New( lType,oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
               bInit,bSize,bPaint,bEnter,bGfocus,bLfocus,lNoVScroll,       ;
               lNoBorder,lAppend,lAutoedit,bUpdate,bKeyDown )
Return Self

METHOD Edit( wParam,lParam ) CLASS PBrowse
Local varbuf, x1, y1, nWidth, j, cName, aCtrlProp
Local aDataDef := oDesigner:aDataDef
Local lRes := .F., oModDlg, oColumn, aCoors, nChoic, bInit, oGet, aItems
Private value, oCtrl := Iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )

   IF ::SetColumn() == 1 .AND. ::bEnter == Nil
      Return Nil
   ENDIF
   ::cargo := Eval( ::bRecno,Self )
   IF oTab:GetActivePage() == 2
      IF ( value := EditMethod( aMethods[::cargo,1],aMethods[::cargo,2] ) ) != Nil ;
          .AND. !( aMethods[::cargo,2] == value )
         aMethods[::cargo,2] := value
         IF oCombo:value == 1
            HFormGen():oDlgSelected:oParent:aMethods[::cargo,2] := value
         ELSE
            GetCtrlSelected( HFormGen():oDlgSelected ):aMethods[::cargo,2] := value
         ENDIF
         HFormGen():oDlgSelected:oParent:lChanged := .T.
         oBrw2:lUpdated := .T.
         oBrw2:Refresh()
      ENDIF
      Return Nil
   ENDIF
   IF oCombo:value == 1
      aCtrlProp := oCtrl:oParent:aProp
   ELSE
      aCtrlProp := oCtrl:aProp
   ENDIF
   oColumn := ::aColumns[2]
   cName := Lower( aProp[::cargo,1] )
   j := Ascan( aDataDef, {|a|a[1]==cName} )
   varbuf := Eval( oColumn:block,,Self,2 )

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
            varbuf := SelectFile( "All files ( *.* )","*.*" )
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
         RedrawWindow( oCtrl:handle,5 )
         HFormGen():oDlgSelected:oParent:lChanged := .T.
         oBrw1:lUpdated := .T.
         oBrw1:Refresh()
      ENDIF
   ELSE
      x1  := ::x1 + ::aColumns[1]:width - 2
      y1 := ::y1 + ( ::height+1 ) * ( ::rowPos - 1 )
      nWidth := Min( ::aColumns[2]:width, ::x2 - x1 - 1 )

      ReadExit( .T. )
      IF ( j != 0 .AND. aDataDef[ j,6 ] != Nil ) .OR. aCtrlProp[ oBrw1:cargo,3 ] == "L"

         aItems := Iif( j != 0 .AND. aDataDef[ j,6 ] != Nil, aDataDef[ j,6 ], { "True","False" } )
         varbuf := AllTrim(varbuf)
         nChoic := Ascan( aItems,varbuf )

         @ x1,y1-2 COMBOBOX oGet           ;
            ITEMS aItems                   ;
            INIT nChoic                    ;
            OF oBrw1                       ;
            SIZE nWidth, ::height*5        ;
            FONT ::oFont
         oBrw1:AddEvent( CBN_KILLFOCUS,oGet:id,{||VldBrwGet(oGet)} )
      ELSE
         @ x1,y1-2 GET oGet VAR varbuf OF oBrw1  ;
            SIZE nWidth, ::height+6        ;
            STYLE ES_AUTOHSCROLL           ;
            FONT ::oFont                   ;
            VALID {||VldBrwGet(oGet)}
      ENDIF
      SetFocus( oGet:handle )
   ENDIF
RETURN Nil

METHOD HeaderOut( hDC ) CLASS PBrowse
Local i, x, fif, xSize
Local nRows := Min( ::kolz,::rowCount ), oColumn
Local oPen := HPen():Add( PS_SOLID,1,::sepColor )
Local oPenLight := HPen():Add( PS_SOLID,1,GetSysColor(COLOR_3DHILIGHT) )
Local oPenGray  := HPen():Add( PS_SOLID,1,GetSysColor(COLOR_3DSHADOW) )

   x := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   while x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      if fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      endif
      if x > ::x1
         SelectObject( hDC, oPenLight:handle )
         DrawLine( hDC, x-1, ::y1+1, x-1, ::y1+(::height+1)*nRows )
         SelectObject( hDC, oPenGray:handle )
         DrawLine( hDC, x-2, ::y1+1, x-2, ::y1+(::height+1)*nRows )
      endif
      x += xSize
      fif := IIF( fif = ::freeze, ::nLeftCol, fif + 1 )
      if fif > Len( ::aColumns )
         exit
      endif
   enddo

   SelectObject( hDC, oPen:handle )
   FOR i := 1 to nRows
      DrawLine( hDC, ::x1, ::y1+(::height+1)*i, iif(::lAdjRight, ::x2, x), ::y1+(::height+1)*i )
   NEXT

   oPen:Release()

RETURN Nil


// -----------------------------

Static Function VldBrwGet( oGet )
Local vari, j, cName
Private value, oCtrl := Iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )

   cName := Lower( aProp[ oBrw1:cargo,1 ] )

   j := Ascan( oDesigner:aDataDef, {|a|a[1]==cName} )

   IF oGet:Classname() == "HCOMBOBOX"
      vari := SendMessage( oGet:handle,CB_GETCURSEL,0,0 ) + 1
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
      // pArray := oDesigner:aDataDef[ j,6 ]
      EvalCode( oDesigner:aDataDef[ j,3 ] )
      IF oDesigner:aDataDef[ j,4 ] != Nil
         EvalCode( oDesigner:aDataDef[ j,4 ] )
      ENDIF
   ENDIF
   RedrawWindow( oCtrl:handle,5 )
   HFormGen():oDlgSelected:oParent:lChanged := .T.
   oBrw1:lUpdated := .T.
   oBrw1:aEvents := {}
   oBrw1:aNotify := {}
   oBrw1:aControls := {}
   PostMessage( oGet:handle,WM_CLOSE,0,0 )
   // oBrw1:DelControl( oGet )
   // oBrw1:Refresh()
Return .T.

Function InspOpen

   INIT DIALOG oDesigner:oDlgInsp TITLE "Object Inspector" ;
      AT 0,280  SIZE 220,300                     ;
      STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SIZEBOX ;
      FONT oDesigner:oMainWnd:oFont                   ;
      ON INIT {||MoveWindow(oDesigner:oDlgInsp:handle,0,280,230,280)}   ;
      ON EXIT {||oDesigner:oDlgInsp:=Nil,CheckMenuItem(oDesigner:oMainWnd:handle,1010,.F.),.T.}

   @ 0,0 COMBOBOX oCombo ITEMS {} SIZE 220,150 ;
          STYLE WS_VSCROLL                     ;
          ON SIZE {|o,x,y|MoveWindow(o:handle,0,0,x,150)} ;
          ON CHANGE {||ComboOnChg()}

   @ 0,28 TAB oTab ITEMS {} SIZE 220,250 ;
      ON SIZE {|o,x,y|MoveWindow(o:handle,0,28,x,y-28)}

   BEGIN PAGE "Properties" OF oTab
      @ 2,30 PBROWSE oBrw1 ARRAY SIZE 214,218 STYLE WS_VSCROLL ;
         ON SIZE {|o,x,y|MoveWindow(o:handle,2,30,x-6,y-32)}
      oBrw1:tColor := GetSysColor( COLOR_BTNTEXT )
      oBrw1:tColorSel := 8404992
      oBrw1:bColor := oBrw1:bColorSel := GetSysColor( COLOR_BTNFACE )
      oBrw1:freeze := 1
      oBrw1:lDispHead := .F.
      oBrw1:lSep3d := .T.
      oBrw1:sepColor  := GetSysColor( COLOR_BTNSHADOW )
      oBrw1:msrec := aProp
      oBrw1:AddColumn( HColumn():New( ,{|v,o|Iif(Empty(o:msrec[o:tekzp,1]),"","  "+o:msrec[o:tekzp,1])},"C",12,0,.T. ) )
      oBrw1:AddColumn( HColumn():New( ,ColumnArBlock(),"U",100,0,.T. ) )
   END PAGE OF oTab

   BEGIN PAGE "Events" OF oTab
      @ 2,30 PBROWSE oBrw2 ARRAY SIZE 214,218 STYLE WS_VSCROLL ;
         ON SIZE {|o,x,y|MoveWindow(o:handle,2,30,x-6,y-32)}
      oBrw2:tColor := GetSysColor( COLOR_BTNTEXT )
      oBrw2:tColorSel := 8404992
      oBrw2:bColor := oBrw2:bColorSel := GetSysColor( COLOR_BTNFACE )
      oBrw2:freeze := 1
      oBrw2:lDispHead := .F.
      oBrw2:lSep3d := .T.
      oBrw2:sepColor  := GetSysColor( COLOR_BTNSHADOW )
      oBrw2:msrec := aMethods
      oBrw2:AddColumn( HColumn():New( ,{|v,o|Iif(Empty(o:msrec[o:tekzp,1]),"","  "+o:msrec[o:tekzp,1])},"C",12,0,.T. ) )
      oBrw2:AddColumn( HColumn():New( ,{|v,o|Iif(Empty(o:msrec[o:tekzp,2]),"",":"+o:msrec[o:tekzp,1])},"C",100,0,.T. ) )
   END PAGE OF oTab

   ACTIVATE DIALOG oDesigner:oDlgInsp NOMODAL
   CheckMenuItem(oDesigner:oMainWnd:handle,1010,.T.)

   InspSetCombo()

   oDesigner:oDlgInsp:AddEvent( 0,IDOK,{||DlgOk()} )
   oDesigner:oDlgInsp:AddEvent( 0,IDCANCEL,{||DlgCancel()} )

Return Nil

Static Function DlgOk()

   IF !Empty( oBrw1:aControls )
      VldBrwGet( oBrw1:aControls[1] )
   ENDIF
Return Nil

Static Function DlgCancel()

   IF !Empty( oBrw1:aControls )
      oBrw1:aEvents := {}
      oBrw1:aNotify := {}
      PostMessage( oBrw1:aControls[1]:handle,WM_CLOSE,0,0 )
      oBrw1:aControls := {}
      // oBrw1:DelControl( oBrw1:aControls[1] )
      // oBrw1:Refresh()
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
   oCombo:value := n + 1
   oCombo:Refresh()
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
   oCombo:value := n + 1
   oCombo:Refresh()
   InspSetBrowse()
Return Nil

Static Function ComboOnChg()
Local oDlg := HFormGen():oDlgSelected, oCtrl, n
Local aControls := Iif( oDesigner:lReport,oDlg:aControls[1]:aControls[1]:aControls,oDlg:aControls )

   oCombo:value := SendMessage( oCombo:handle,CB_GETCURSEL,0,0 ) + 1
   IF oDlg != Nil
      n := oCombo:value - 1
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

   oBrw1:msrec := aProp
   oBrw2:msrec := aMethods

   Eval( oBrw1:bGoTop,oBrw1 )
   Eval( oBrw2:bGoTop,oBrw2 )
   oBrw1:rowPos := 1
   oBrw2:rowPos := 1
   oBrw1:Refresh()
   oBrw2:Refresh()

Return Nil

Function InspUpdBrowse()
Local i, j, cPropertyName, lChg := .F.
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
Local oDlg, oBrw, nRec := Eval( oBrw1:bRecno,oBrw1 )

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
   oBrw:bcolorSel := VColor( "008000" )
   oBrw:lAppable := .T.
   oBrw:msrec := arr
   oBrw:AddColumn( HColumn():New( ,{|v,o|Iif(v!=Nil,o:msrec[o:tekzp]:=v,o:msrec[o:tekzp])},"C",100,0,.T. ) )

   @ 30,265 BUTTON "Ok" SIZE 100, 32     ;
       ON SIZE {|o,x,y|o:Move(,y-35,,)}  ;
       ON CLICK {||oDlg:lResult:=.T.,EndDialog()}
   @ 170,265 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ;
       ON SIZE {|o,x,y|o:Move(,y-35,,)}

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF Len( arr ) == 1 .AND. arr[1] == "....."
         arr := {}
      ENDIF
      Return arr
   ENDIF

Return Nil

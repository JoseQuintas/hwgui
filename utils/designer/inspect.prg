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

STATIC oCombo, oBrw1, oBrw2
STATIC aProp := {}, aMethods := {}
STATIC oTab

MEMVAR oDesigner

FUNCTION InspOpen

   INIT DIALOG oDesigner:oDlgInsp TITLE "Object Inspector" ;
      AT 0, 280  SIZE 220, 300                     ;
      STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SIZEBOX ;
      FONT oDesigner:oMainWnd:oFont                   ;
      ON INIT { ||hwg_Movewindow( oDesigner:oDlgInsp:handle, 0, 280, 230, 280 ) }   ;
      ON EXIT { ||oDesigner:oDlgInsp := Nil, hwg_Checkmenuitem( oDesigner:oMainWnd:handle, MENU_OINSP, .F. ), .T. }

   @ 0, 0 COMBOBOX oCombo ITEMS {} SIZE 220, 26 ;
      STYLE WS_VSCROLL                     ;
      ON SIZE { |o, x, y|hwg_Movewindow( o:handle, 0, 0, x, ) } ;
      ON CHANGE { ||ComboOnChg() }

   @ 0, 28 TAB oTab ITEMS {} SIZE 220, 250 ;
      ON SIZE { |o, x, y|hwg_Movewindow( o:handle, 0, 28, x, y - 28 ) }

   BEGIN PAGE "Properties" OF oTab
   @ 2, 30 BROWSE oBrw1 ARRAY SIZE 214, 218 STYLE WS_VSCROLL ;
      ON CLICK { ||Edit1() } ON SIZE { |o, x, y|hwg_Movewindow( o:handle, 2, 30, x - 6, y - 32 ) }
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
   oBrw1:AddColumn( HColumn():New( ,{ |v,o|iif(Empty(o:aArray[o:nCurrent,1] ),"","  " + o:aArray[o:nCurrent,1] ) },"C",12,0, .T. ) )
   oBrw1:AddColumn( HColumn():New( ,hwg_ColumnArBlock(),"U",100,0, .T. ) )
   ENDPAGE OF oTab

   BEGIN PAGE "Events" OF oTab
   @ 2, 30 BROWSE oBrw2 ARRAY SIZE 214, 218 STYLE WS_VSCROLL ;
      ON CLICK { ||Edit2() } ON SIZE { |o, x, y|hwg_Movewindow( o:handle, 2, 30, x - 6, y - 32 ) }
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
   oBrw2:AddColumn( HColumn():New( ,{ |v,o|iif(Empty(o:aArray[o:nCurrent,1] ),"","  " + o:aArray[o:nCurrent,1] ) },"C",12,0, .T. ) )
   oBrw2:AddColumn( HColumn():New( ,{ |v,o|iif(Empty(o:aArray[o:nCurrent,2] ),"",":" + o:aArray[o:nCurrent,1] ) },"C",100,0, .T. ) )
   ENDPAGE OF oTab

   ACTIVATE DIALOG oDesigner:oDlgInsp NOMODAL
   hwg_Checkmenuitem( oDesigner:oMainWnd:handle, MENU_OINSP, .T. )

   InspSetCombo()

   oDesigner:oDlgInsp:AddEvent( 0, IDOK, { ||DlgOk() } )
   oDesigner:oDlgInsp:AddEvent( 0, IDCANCEL, { ||DlgCancel() } )

   RETURN Nil

STATIC FUNCTION Edit1()
   LOCAL varbuf, x1, y1, nWidth, j, cName, aCtrlProp, oGet
   LOCAL aDataDef := oDesigner:aDataDef
   LOCAL lRes := .F. , oModDlg, oColumn, aCoors, nChoic, bInit, aItems
   MEMVAR value, oCtrl
   PRIVATE value, oCtrl := iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )

   IF oBrw1:SetColumn() == 1
      RETURN Nil
   ENDIF
   oBrw1:cargo := Eval( oBrw1:bRecno, oBrw1 )
   IF oCombo:value == 1
      aCtrlProp := oCtrl:oParent:aProp
   ELSE
      aCtrlProp := oCtrl:aProp
   ENDIF
   oColumn := oBrw1:aColumns[2]
   cName := Lower( aProp[oBrw1:cargo,1] )
   j := Ascan( aDataDef, { |a|a[1] == cName } )
   varbuf := Eval( oColumn:block, , oBrw1, 2 )

   IF ( j != 0 .AND. aDataDef[ j,5 ] != Nil ) .OR. aCtrlProp[ oBrw1:cargo,3 ] == "A"
      IF j != 0 .AND. aDataDef[ j,5 ] != Nil
         IF aDataDef[ j,5 ] == "color"
            varbuf := Hwg_ChooseColor( Val( varbuf ), .F. )
            IF varbuf != Nil
               varbuf := LTrim( Str( varbuf ) )
               lRes := .T.
            ENDIF
         ELSEIF aDataDef[ j,5 ] == "font"
            varbuf := HFont():Select( varbuf )
            IF varbuf != Nil
               lRes := .T.
            ENDIF
         ELSEIF aDataDef[ j,5 ] == "file"
            varbuf := hwg_Selectfile( "All files ( *.* )", "*.*" )
            IF varbuf != Nil
               lRes := .T.
            ENDIF
         ELSEIF aDataDef[ j,5 ] == "anchor"
            varbuf := SelectAnchor( Val(varbuf) )
            IF varbuf != Nil
               varbuf := LTrim( Str( varbuf ) )
               lRes := .T.
            ENDIF
         ELSEIF Left( aDataDef[j,5],6 ) == "hstyle"
            varbuf := SelectStyle( varbuf )
            IF varbuf != Nil
               lRes := .T.
            ENDIF
         ELSEIF aDataDef[ j,5 ] == "styles"
            varbuf := SeleStyles( varbuf )
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
         j := Ascan( aDataDef, { |a|a[1] == cName } )
         value := aProp[ oBrw1:cargo,2 ] := varbuf
         aCtrlProp[ oBrw1:cargo,2 ] := value
         IF j != 0 .AND. aDataDef[ j,3 ] != Nil
            EvalCode( aDataDef[ j,3 ] )
            IF aDataDef[ j,4 ] != Nil
               EvalCode( aDataDef[ j,4 ] )
            ENDIF
         ENDIF
         hwg_Redrawwindow( oCtrl:handle, 5 )
         HFormGen():oDlgSelected:oParent:lChanged := .T.
         oBrw1:lUpdated := .T.
         oBrw1:Refresh()
      ENDIF
   ELSE
      x1  := oBrw1:x1 + oBrw1:aColumns[1]:width - 2
      y1 := oBrw1:y1 + ( oBrw1:height + 1 ) * ( oBrw1:rowPos - 1 )
      nWidth := Min( oBrw1:aColumns[2]:width, oBrw1:x2 - x1 - 1 )

      ReadExit( .T. )
      IF ( j != 0 .AND. aDataDef[ j,6 ] != Nil ) .OR. aCtrlProp[ oBrw1:cargo,3 ] == "L"

         aItems := iif( j != 0 .AND. aDataDef[ j,6 ] != Nil, aDataDef[ j,6 ], { "True", "False" } )
         varbuf := AllTrim( varbuf )
         nChoic := Ascan( aItems, varbuf )

         @ x1, y1 - 2 COMBOBOX oGet         ;
            ITEMS aItems                 ;
            INIT nChoic                  ;
            OF oBrw1                     ;
            SIZE nWidth, oBrw1:height * 5  ;
            FONT oBrw1:oFont

         IF ( j := Ascan( oBrw1:aEvents, { |a|a[1] == CBN_KILLFOCUS .AND. ;
               a[2] == oGet:id } ) ) > 0
            oBrw1:aEvents[j,3] := { ||VldBrwGet( oGet ) }
         ELSE
            oBrw1:AddEvent( CBN_KILLFOCUS, oGet:id, { ||VldBrwGet( oGet ) } )
         ENDIF
      ELSE
         @ x1, y1 - 2 GET oGet VAR varbuf OF oBrw1  ;
            SIZE nWidth, oBrw1:height + 6        ;
            STYLE ES_AUTOHSCROLL               ;
            FONT oBrw1:oFont                   ;
            VALID { ||VldBrwGet( oGet ) }
         oGet:nMaxLength := 0
      ENDIF
      hwg_Setfocus( oGet:handle )
   ENDIF

   RETURN Nil

STATIC FUNCTION Edit2()
   LOCAL value, cargo

   IF oBrw2:SetColumn() == 1
      RETURN Nil
   ENDIF
   cargo := oBrw2:cargo := Eval( oBrw2:bRecno, oBrw2 )
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

   RETURN Nil

STATIC FUNCTION VldBrwGet( oGet )
   LOCAL vari, j, cName, x1, x2, y1, y2
   MEMVAR value, oCtrl
   PRIVATE value, oCtrl := iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )

   cName := Lower( aProp[ oBrw1:cargo,1 ] )

   j := Ascan( oDesigner:aDataDef, { |a|a[1] == cName } )

   IF oGet:Classname() == "HCOMBOBOX"
      vari := hwg_Sendmessage( oGet:handle, CB_GETCURSEL, 0, 0 ) + 1
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

   x1 := oCtrl:nLeft; y1 := oCtrl:nTop
   x2 := oCtrl:nLeft + oCtrl:nWidth; y2 := oCtrl:nTop + oCtrl:nHeight

   IF j != 0 .AND. oDesigner:aDataDef[ j,3 ] != Nil
      EvalCode( oDesigner:aDataDef[ j,3 ] )
      IF oDesigner:aDataDef[ j,4 ] != Nil
         EvalCode( oDesigner:aDataDef[ j,4 ] )
      ENDIF
   ENDIF

   IF x1 != oCtrl:nLeft .OR. y1 != oCtrl:nTop .OR. ;
         x2 != oCtrl:nLeft + oCtrl:nWidth .OR. y2 != oCtrl:nTop + oCtrl:nHeight
      hwg_Invalidaterect( oCtrl:oParent:handle, 1, x1-4, y1-4, x2+4, y2+4 )
      hwg_Invalidaterect( oCtrl:oParent:handle, 1, oCtrl:nLeft-4, oCtrl:nTop-4, ;
         oCtrl:nLeft + oCtrl:nWidth + 4, oCtrl:nTop + oCtrl:nHeight + 4 )
      IF x1 != oCtrl:nLeft .OR. y1 != oCtrl:nTop
         FOR j := 1 TO Len( oCtrl:aControls )
            CtrlMove( oCtrl:aControls[j], oCtrl:nLeft - x1, oCtrl:nTop - y1, .F., .T. )
         NEXT
      ENDIF
   ENDIF

   HFormGen():oDlgSelected:oParent:lChanged := .T.
   oBrw1:lUpdated := .T.
   oBrw1:DelControl( oGet )

   RETURN .T.

STATIC FUNCTION DlgOk()

   IF !Empty( oBrw1:aControls )
      VldBrwGet( oBrw1:aControls[1] )
   ENDIF

   RETURN Nil

STATIC FUNCTION DlgCancel()
   LOCAL oDlg

   IF !Empty( oBrw1:aControls )
      IF ( oDlg := hwg_ParentGetDialog( oBrw1:aControls[1] ) ) != Nil
         oDlg:nLastKey := 0
      ENDIF

      oBrw1:DelControl( oBrw1:aControls[1] )
      oBrw1:Refresh()
   ENDIF

   RETURN Nil

FUNCTION InspSetCombo()
   LOCAL i, aControls, oCtrl, n := - 1, oDlg := HFormGen():oDlgSelected

   oCombo:aItems := {}
   IF oDlg != Nil
      n := 0
      AAdd( oCombo:aItems, "Form." + oDlg:title )
      oCtrl := GetCtrlSelected( oDlg )
      aControls := iif( oDesigner:lReport, oDlg:aControls[1]:aControls[1]:aControls, ;
         oDlg:aControls )
      FOR i := 1 TO Len( aControls )
         AAdd( oCombo:aItems, aControls[i]:cClass + "." + iif( aControls[i]:title != Nil,Left(aControls[i]:title,15 ),LTrim(Str(aControls[i]:id ) ) ) )
         IF oCtrl != Nil .AND. oCtrl:handle == aControls[i]:handle
            n := i
         ENDIF
      NEXT
   ENDIF
   oCombo:Refresh( n + 1 )
   //oCombo:value := n + 1
   InspSetBrowse()

   RETURN Nil

FUNCTION InspUpdCombo( n )
   LOCAL aControls, i

   IF n > 0
      aControls := iif( oDesigner:lReport, ;
         HFormGen():oDlgSelected:aControls[1]:aControls[1]:aControls, ;
         HFormGen():oDlgSelected:aControls )
      i := Len( aControls )
      IF i >= Len( oCombo:aItems )
         AAdd( oCombo:aItems, aControls[i]:cClass + "." + iif( aControls[i]:title != Nil,Left(aControls[i]:title,15 ),LTrim(Str(aControls[i]:id ) ) ) )
      ELSEIF i + 1 < Len( oCombo:aItems )
         RETURN InspSetCombo()
      ENDIF
   ENDIF
   oCombo:Refresh( n + 1 )
   //oCombo:value := n + 1
   InspSetBrowse()

   RETURN Nil

STATIC FUNCTION ComboOnChg()
   LOCAL oDlg := HFormGen():oDlgSelected, oCtrl, n
   LOCAL aControls := iif( oDesigner:lReport, oDlg:aControls[1]:aControls[1]:aControls, oDlg:aControls )

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
            SetCtrlSelected( oDlg, aControls[n], n )
         ENDIF
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION InspSetBrowse()
   LOCAL i, o

   aProp := {}
   aMethods := {}

   IF oCombo:value > 0
      o := iif( oCombo:value == 1, HFormGen():oDlgSelected:oParent, GetCtrlSelected( HFormGen():oDlgSelected ) )
      FOR i := 1 TO Len( o:aProp )
         IF Len( o:aProp[i] ) == 3
            AAdd( aProp, { o:aProp[i,1], o:aProp[i,2] } )
         ENDIF
      NEXT
      FOR i := 1 TO Len( o:aMethods )
         AAdd( aMethods, { o:aMethods[i,1], o:aMethods[i,2] } )
      NEXT
   ENDIF

   oBrw1:aArray := aProp
   oBrw2:aArray := aMethods

   Eval( oBrw1:bGoTop, oBrw1 )
   Eval( oBrw2:bGoTop, oBrw2 )
   oBrw1:rowPos := 1
   oBrw2:rowPos := 1
   oBrw1:Refresh()
   oBrw2:Refresh()

   RETURN Nil

FUNCTION InspUpdBrowse()
   LOCAL i, j, lChg := .F.
   MEMVAR value, oCtrl
   PRIVATE value, oCtrl

   IF oCombo == Nil
      RETURN Nil
   ENDIF
   oCtrl := iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )
   IF oDesigner:oDlgInsp != Nil
      FOR i := 1 TO Len( aProp )
         value := iif( oCombo:value == 1, oCtrl:oParent:aProp[ i,2 ], oCtrl:aProp[ i,2 ] )
         IF ValType( aProp[ i,2 ] ) != "O" .AND. ValType( aProp[ i,2 ] ) != "A" ;
               .AND. ( aProp[ i,2 ] == Nil .OR. !( aProp[ i,2 ] == value ) )
            aProp[ i,2 ] := value
            lChg := .T.
         ENDIF
      NEXT
      IF lChg .AND. !oBrw1:lHide
         oBrw1:Refresh()
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION InspUpdProp( cName, xValue )
   LOCAL i

   cName := Lower( cName )
   IF ( i := Ascan( aProp, { |a|Lower(a[1] ) == Lower(cName ) } ) ) > 0
      aProp[ i,2 ] := xValue
      oBrw1:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION EditArray( arr )
   LOCAL oDlg, oBrw, nRec := Eval( oBrw1:bRecno, oBrw1 ), i

   IF arr == Nil
      arr := {}
   ENDIF
   IF Empty( arr )
      AAdd( arr, "....." )
   ENDIF
   INIT DIALOG oDlg TITLE "Edit " + aProp[nRec,1] + " array" ;
      AT 300, 280 SIZE 400, 300 FONT oDesigner:oMainWnd:oFont

   @ 0, 0 BROWSE oBrw ARRAY SIZE 400, 255  ;
      ON SIZE { |o, x, y|o:Move( , , x, y - 45 ) }

   oBrw:bcolor := 15132390
   oBrw:bcolorSel := hwg_ColorC2N( "008000" )
   oBrw:lAppable := .T.
   oBrw:aArray := arr
   oBrw:AddColumn( HColumn():New( ,{ |v,o|iif(v != Nil,o:aArray[o:nCurrent] := v,o:aArray[o:nCurrent] ) },"C",100,0, .T. ,,,Replicate("X",100 ) ) )

   @ 30, 265 BUTTON "Ok" SIZE 100, 32     ;
      ON SIZE { |o, x, y|o:Move( , y - 35, , ) }  ;
      ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 170, 265 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ;
      ON SIZE { |o, x, y|o:Move( , y - 35, , ) }

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF Len( arr ) == 1 .AND. arr[1] == "....."
         arr := {}
      ENDIF
      FOR i := 1 TO Len( arr )
         arr[i] := Trim( arr[i] )
      NEXT
      RETURN arr
   ENDIF

   RETURN Nil

FUNCTION SelectAnchor( nAnchor )
   LOCAL oDlg
   LOCAL c1 := .F., c2 := .F., c3 := .F., c4 := .F., c5 := .F., c6 := .F.
   LOCAL c7 := .F., c8 := .F., c9 := .F., c10 := .F., c11 := .F.

   IF nAnchor == 0
      c1 := .T.
   ELSEIF nAnchor > 0
      IF hwg_BitAnd( nAnchor, ANCHOR_TOPABS ) > 0; c2 := .T.; ENDIF
      IF hwg_BitAnd( nAnchor, ANCHOR_LEFTABS ) > 0; c3 := .T.; ENDIF
      IF hwg_BitAnd( nAnchor, ANCHOR_BOTTOMABS ) > 0; c4 := .T.; ENDIF
      IF hwg_BitAnd( nAnchor, ANCHOR_RIGHTABS ) > 0; c5 := .T.; ENDIF
      IF hwg_BitAnd( nAnchor, ANCHOR_TOPREL ) > 0; c6 := .T.; ENDIF
      IF hwg_BitAnd( nAnchor, ANCHOR_LEFTREL ) > 0; c7 := .T.; ENDIF
      IF hwg_BitAnd( nAnchor, ANCHOR_BOTTOMREL ) > 0; c8 := .T.; ENDIF
      IF hwg_BitAnd( nAnchor, ANCHOR_RIGHTREL ) > 0; c9 := .T.; ENDIF
      IF hwg_BitAnd( nAnchor, ANCHOR_HORFIX ) > 0; c10 := .T.; ENDIF
      IF hwg_BitAnd( nAnchor, ANCHOR_VERTFIX ) > 0; c11 := .T.; ENDIF
   ENDIF

   INIT DIALOG oDlg TITLE "Select anchor" ;
      AT 300, 280 SIZE 280, 354 FONT oDesigner:oMainWnd:oFont

   @ 20,20 GET CHECKBOX c1 CAPTION "ANCHOR_TOPLEFT" SIZE 200, 24
   @ 20,44 GET CHECKBOX c2 CAPTION "ANCHOR_TOPABS" SIZE 200, 24
   @ 20,68 GET CHECKBOX c3 CAPTION "ANCHOR_LEFTABS" SIZE 200, 24
   @ 20,92 GET CHECKBOX c4 CAPTION "ANCHOR_BOTTOMABS" SIZE 200, 24
   @ 20,116 GET CHECKBOX c5 CAPTION "ANCHOR_RIGHTABS" SIZE 200, 24
   @ 20,140 GET CHECKBOX c6 CAPTION "ANCHOR_TOPREL" SIZE 200, 24
   @ 20,164 GET CHECKBOX c7 CAPTION "ANCHOR_LEFTREL" SIZE 200, 24
   @ 20,188 GET CHECKBOX c8 CAPTION "ANCHOR_BOTTOMREL" SIZE 200, 24
   @ 20,212 GET CHECKBOX c9 CAPTION "ANCHOR_RIGHTREL" SIZE 200, 24
   @ 20,236 GET CHECKBOX c10 CAPTION "ANCHOR_HORFIX" SIZE 200, 24
   @ 20,260 GET CHECKBOX c11 CAPTION "ANCHOR_VERTFIX" SIZE 200, 24

   @ 20, 310 BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 160, 310 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      nAnchor := 0
      IF c2; nAnchor += ANCHOR_TOPABS; ENDIF
      IF c3; nAnchor += ANCHOR_LEFTABS; ENDIF
      IF c4; nAnchor += ANCHOR_BOTTOMABS; ENDIF
      IF c5; nAnchor += ANCHOR_RIGHTABS; ENDIF
      IF c6; nAnchor += ANCHOR_TOPREL; ENDIF
      IF c7; nAnchor += ANCHOR_LEFTREL; ENDIF
      IF c8; nAnchor += ANCHOR_BOTTOMREL; ENDIF
      IF c9; nAnchor += ANCHOR_RIGHTREL; ENDIF
      IF c10; nAnchor += ANCHOR_HORFIX; ENDIF
      IF c11; nAnchor += ANCHOR_VERTFIX; ENDIF
      IF nAnchor == 0 .AND. !c1
         nAnchor := -1
      ENDIF
      RETURN nAnchor
   ENDIF

   RETURN Nil

FUNCTION SelectStyle( oStyle )
   LOCAL oDlg, oDemo, oDemoStyle := Hstyle():New()
   LOCAL nOrient := 1, aColors, nBorder := 0, aCorners, nUpLeft := 0, nUpRight := 0, nDnLeft := 0, nDnRight := 0
   LOCAL oGet1, cColors := "", i
   LOCAL bAddClr := {||
      LOCAL nColor := Hwg_ChooseColor(), cVal := Trim(oGet1:Value)
      IF nColor != Nil
         oGet1:Value := cVal + Iif(!Empty(cVal).AND.Right(cVal,1)!= ',',',',"") + '#' + hwg_ColorN2C(nColor)
         oDemoStyle:aColors := hb_ATokens( AllTrim(cColors),',' )
         Cnv_aColors( oDemoStyle:aColors )
         Demo( oDemo, oDemoStyle )
      ENDIF
      RETURN .T.
   }
   LOCAL bRadio := {||
      oDemoStyle:nOrient := nOrient
      //hwg_writelog( hwg_hfrm_Arr2Str( oDemoStyle:aColors ) )
      Demo( oDemo, oDemoStyle )
      RETURN .T.
   }
   LOCAL bValid := {||
      IF Empty( cColors )
         oDemoStyle:aColors := Nil
      ELSE
         oDemoStyle:aColors := hb_ATokens( AllTrim(cColors),',' )
         Cnv_aColors( oDemoStyle:aColors )
      ENDIF
      Demo( oDemo, oDemoStyle )
      RETURN .T.
   }
   LOCAL bUpd := {||
      IF oDemoStyle:nBorder != nBorder
         oDemoStyle:nBorder := nBorder
         IF oDemoStyle:oPen != Nil
            oDemoStyle:oPen:Release()
         ENDIF
         oDemoStyle:oPen := Nil
         IF nBorder != 0
            oDemoStyle:oPen := HPen():Add( BS_SOLID, nBorder, oDemoStyle:tColor )
         ENDIF
         Demo( oDemo, oDemoStyle )
      ENDIF
      RETURN .T.
   }
   LOCAL bUpdC := {||
      IF aCorners == Nil
         aCorners := {0,0,0,0}
      ENDIF
      aCorners[1] := nUpLeft
      aCorners[2] := nUpRight
      aCorners[3] := nDnRight
      aCorners[4] := nDnLeft
      oDemoStyle:aCorners := aCorners
      Demo( oDemo, oDemoStyle )
      RETURN .T.
   }
   LOCAL bBorderClr := {||
      LOCAL nColor := Hwg_ChooseColor(oDemoStyle:tColor)
      IF nColor != Nil .AND. oDemoStyle:tColor != nColor
         oDemoStyle:tColor := nColor
         IF oDemoStyle:oPen != Nil
            oDemoStyle:oPen:Release()
         ENDIF
         oDemoStyle:oPen := Nil
         IF nBorder != 0
            oDemoStyle:oPen := HPen():Add( BS_SOLID, nBorder, oDemoStyle:tColor )
         ENDIF
         Demo( oDemo, oDemoStyle )
      ENDIF
      RETURN .T.
   }

   IF oStyle != Nil
      IF !Empty( oStyle:aColors )
         cColors := hwg_hfrm_Arr2Str( oStyle:aColors )
         cColors := Substr( cColors,2,Len(cColors)-2 )
         nOrient := oStyle:nOrient
         aCorners := oStyle:aCorners
         nBorder := oStyle:nBorder
         nUpLeft := Iif( !Empty(aCorners).AND.Len(aCorners)>0,aCorners[1],0 )
         nUpRight := Iif( !Empty(aCorners).AND.Len(aCorners)>1,aCorners[2],0 )
         nDnRight := Iif( !Empty(aCorners).AND.Len(aCorners)>2,aCorners[3],0 )
         nDnLeft := Iif( !Empty(aCorners).AND.Len(aCorners)>3,aCorners[4],0 )
      ENDIF
      oDemoStyle:aColors := oStyle:aColors
      oDemoStyle:nOrient := oStyle:nOrient
      oDemoStyle:aCorners := oStyle:aCorners
      oDemoStyle:nBorder := oStyle:nBorder
      oDemoStyle:tColor := oStyle:tColor
   ENDIF

   INIT DIALOG oDlg TITLE "Select style" ;
      AT 300, 120 SIZE 320, 400 FONT oDesigner:oMainWnd:oFont ;
      ON INIT {||Iif(oStyle!=Nil,Demo( oDemo, oDemoStyle ),.t.)}

   @ 20,16 GET oGet1 VAR cColors SIZE 200, 26 VALID bValid MAXLENGTH 36
   @ 220,16 BUTTON "Add" SIZE 40, 28 ON CLICK bAddClr

   GET RADIOGROUP nOrient
   @ 20,60 RADIOBUTTON "vertical down" SIZE 140, 24 ON CLICK bRadio
   @ 160,60 RADIOBUTTON "vertical up" SIZE 140, 24 ON CLICK bRadio
   @ 20,84 RADIOBUTTON "horizontal right" SIZE 140, 24 ON CLICK bRadio
   @ 160,84 RADIOBUTTON "horizontal left" SIZE 140, 24 ON CLICK bRadio
   @ 20,108 RADIOBUTTON "diagonal right-up" SIZE 140, 24 ON CLICK bRadio
   @ 160,108 RADIOBUTTON "diagonal left-dn" SIZE 140, 24 ON CLICK bRadio
   @ 20,132 RADIOBUTTON "diagonal right-dn" SIZE 140, 24 ON CLICK bRadio
   @ 160,132 RADIOBUTTON "diagonal left-up" SIZE 140, 24 ON CLICK bRadio
   END RADIOGROUP

   @ 20, 160 LINE LENGTH 280

   @ 20, 172 SAY "Border:" SIZE 100,24
   @ 120, 168 GET UPDOWN nBorder RANGE 0,10 SIZE 50,30 VALID bUpd
   @ 180, 168 BUTTON "Color" SIZE 80, 30 ON CLICK bBorderClr

   @ 20, 208 LINE LENGTH 280

   @ 20, 220 SAY "Corners:" SIZE 80,24
   @ 100, 216 GET UPDOWN nUpLeft RANGE 0,80 SIZE 50,30 VALID bUpdC
   @ 180, 216 GET UPDOWN nUpRight RANGE 0,80 SIZE 50,30 VALID bUpdC
   @ 100, 250 GET UPDOWN nDnLeft RANGE 0,80 SIZE 50,30 VALID bUpdC
   @ 180, 250 GET UPDOWN nDnRight RANGE 0,80 SIZE 50,30 VALID bUpdC

   @ 100, 310 PANEL oDemo SIZE 120, 36

   @ 20, 360 BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 200, 360 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF !Empty( cColors )
         aColors := hb_ATokens( AllTrim(cColors),',' )
         Cnv_aColors( aColors )
         IF aCorners != Nil .AND. aCorners[1] == 0 .AND. aCorners[2] == 0 .AND. aCorners[3] == 0 .AND. aCorners[4] == 0 
            aCorners := Nil
         ENDIF
         RETURN HStyle():New( aColors, nOrient, aCorners, nBorder, oDemoStyle:tColor )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION Cnv_aColors( aColors )
   LOCAL i
   FOR i := 1 TO Len(aColors)
      IF Left(aColors[i],1) == '#'
         aColors[i] := hwg_ColorC2N( aColors[i] )
      ELSEIF IsDigit( Left(aColors[i],1) )
         aColors[i] := Val(aColors[i])
      ELSE
         hwg_MsgStop( "Wrong colors string" )
         RETURN Nil
      ENDIF
   NEXT
   RETURN Nil

STATIC FUNCTION Demo( oDemo, oStyle )

   oDemo:oStyle := oStyle
   hwg_Invalidaterect( oDemo:handle, 1 )

   RETURN Nil

FUNCTION SeleStyles( aStyles )
   LOCAL oDlg, aDemo := Array(3)
   LOCAL bClick := {|o|
      LOCAL oStyle := Iif( aStyles != Nil, aStyles[o:cargo], Nil )
      IF !Empty( oStyle := SelectStyle( oStyle ) )
         IF aStyles == Nil
            aStyles := Array(3)
         ENDIF
         aStyles[o:cargo] := oStyle
         Demo( aDemo[o:cargo], oStyle )
      ENDIF
      RETURN .T.
   }

   INIT DIALOG oDlg TITLE "Select styles" ;
      AT 300, 120 SIZE 320, 240 FONT oDesigner:oMainWnd:oFont

   @ 30, 20 BUTTON "Normal state" SIZE 180, 30 ON CLICK bClick
   ATail(oDlg:aControls):cargo := 1

   @ 230,20 PANEL aDemo[1] SIZE 40, 40

   @ 30, 70 BUTTON "Pressed" SIZE 180, 30 ON CLICK bClick
   ATail(oDlg:aControls):cargo := 2

   @ 230,70 PANEL aDemo[2] SIZE 40, 40

   @ 30, 120 BUTTON "Mouse over" SIZE 180, 30 ON CLICK bClick
   ATail(oDlg:aControls):cargo := 3

   @ 230,120 PANEL aDemo[3] SIZE 40, 40

   @ 20, 200 BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 200, 200 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   IF aStyles != Nil
      aDemo[1]:oStyle := aStyles[1]
      aDemo[2]:oStyle := aStyles[2]
      aDemo[3]:oStyle := aStyles[3]
   ENDIF

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      RETURN aStyles
   ENDIF
   RETURN Nil

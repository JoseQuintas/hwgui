/*
 * $Id$
 *
 * Designer
 * Object Inspector
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "fileio.ch"
#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

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
      [ <lNoBord: NOBORDER> ]    ;
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

STATIC oCombo, oBrw1, oBrw2
STATIC aProp := {}, aMethods := {}
STATIC oTab , oMenuisnp

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

   ::Super:New( lType,oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
         bInit,bSize,bPaint,bEnter,bGfocus,bLfocus,lNoVScroll,       ;
         lNoBorder,lAppend,lAutoedit,bUpdate,bKeyDown )

   RETURN Self

METHOD Edit( wParam,lParam ) CLASS PBrowse
   MEMVAR oDesigner
   LOCAL varbuf, x1, y1, nWidth, j, cName, aCtrlProp
   LOCAL aDataDef := oDesigner:aDataDef
   LOCAL lRes := .F., oColumn, nChoic, oGet, oBtn,aItems
   // : LFB
   LOCAL aItemsaux, k, cAlias, i
   // : END LFB
   MEMVAR Value, oCtrl
   PRIVATE value, oCtrl := Iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )

   HB_SYMBOL_UNUSED( wParam )
   HB_SYMBOL_UNUSED( lParam )

   IF ::SetColumn() == 1 .AND. ::bEnter == NIL
      RETURN NIL
   ENDIF
   ::cargo := Eval( ::bRecno,Self )
   IF oTab:GetActivePage() == 2
      IF ( value := EditMethod( aMethods[::cargo,1],aMethods[::cargo,2] ) ) != NIL ;
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
      RETURN NIL
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

   IF ( j != 0 .AND. aDataDef[ j,5 ] != NIL ) .OR. aCtrlProp[ oBrw1:cargo,3 ] == "A"
      IF j != 0 .AND. aDataDef[ j,5 ] != NIL
         IF aDataDef[ j,5 ] == "color"
            varbuf := Hwg_ChooseColor( Val(varbuf),.F. )
            IF varbuf != NIL
               varbuf := Ltrim( Str( varbuf ) )
               lRes := .T.
            ENDIF
         ELSEIF aDataDef[ j,5 ] == "font"
            varbuf := HFont():Select( varbuf )
            IF varbuf != NIL
               lRes := .T.
            ENDIF
         ELSEIF aDataDef[ j,5 ] == "file"
            // :LFB
            x1 := ::x1 + ::aColumns[1]:width - 2
            y1 := ::y1 + ( ::height+1 ) * ( ::rowPos - 1 )
            nWidth := Min( ::aColumns[2]:width, ::x2 - x1 - 1 )
            ReadExit( .T. )
            obrw1:bPosChanged:={|| VldBrwGet(oGet,oBtn)}
            @ x1+14,y1-2 GET oGet VAR varbuf OF oBrw1  ;
                  SIZE nWidth, ::height+6        ;
                  STYLE ES_AUTOHSCROLL           ;
                  FONT ::oFont                   ;
                  WHEN {||PostMessage( oBtn:handle,WM_CLOSE,0,0 ),OgET:REFRESH()   ,.T.}

            @ x1,y1-2 BUTTON oBtn CAPTION '...' OF oBrw1;
                  SIZE 13,::height+6  ;
                  ON CLICK {|| (varbuf := IIF (aDataDef[ j,1 ] == "filename",;
                  SelectFile( "Animation Files( *.avi )", "*.avi"),IIF (aDataDef[ j,1 ] == "filedbf", ;
                  SelectFile( {"xBase Files( *.dbf)"," All Files( *.*)"},{ "*.dbf","*.*"}),;
                  SelectFile("Imagens Files( *.jpg;*.gif;*.bmp;*.ico )",;
                  "*.jpg;*.gif;*.bmp;*.ico")))), ;
                  IIF( !empty(varbuf), oGet:refresh(), NIL ) } //,;
                  *   VldBrwGet(oGet)} //,   PostMessage( oBtn:handle,WM_CLOSE,0,0 )}
            // : END LFB
            //varbuf := SelectFile( "All files ( *.* )","*.*" )
            //
            SetFocus( obtn:handle )
            IF varbuf != NIL
               lRes := .T.
            ENDIF
         ENDIF
      ELSE
         varbuf := EditArray( varbuf )
         IF varbuf != NIL
            lRes := .T.
         ENDIF
      ENDIF

      IF lRes
         cName := Lower( aProp[ oBrw1:cargo,1 ] )
         j := Ascan( aDataDef, {|a|a[1]==cName} )
         value := aProp[ oBrw1:cargo,2 ] := varbuf
         aCtrlProp[ oBrw1:cargo,2 ] := value
         IF j != 0 .AND. aDataDef[ j,3 ] != NIL
            EvalCode( aDataDef[ j,3 ] )
            IF aDataDef[ j,4 ] != NIL
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
      IF ( j != 0 .AND. aDataDef[ j,6 ] != NIL ) .OR. aCtrlProp[ oBrw1:cargo,3 ] == "L"
         // : LFB - CAMPOS PARA AS COLUNAS
         IF ( j != 0 .AND. aDataDef[ j,6 ] != NIL .AND.aDataDef[ j,6 ][1] = "@afields" ) // funcao
            //cAlias := LEFT(CutPath( value ),AT(".",CutPath( value ))-1)
            aItems := {" "}
            FOR i = 1 to 200
               cAlias := ALIAS(i)
               IF !EMPTY(ALIAS(i))
                  aItemsaux  := ARRAY(&(alias(i))->(FCOUNT()) )
                  &(alias(i))->(Afields(aItemsAux))
                  FOR k = 1 TO LEN(aItemsaux)
                     AADD(aitems,ALIAS(i) + "->" + aItemsAux[k])
                     //AADD(aitems, aItemsAux[k])
                  NEXT
               ENDIF
            NEXT
         ELSEIF ( j != 0 .AND. aDataDef[ j,6 ] != NIL .AND.aDataDef[ j,6 ][1] = "@atags" )// funcao
            i := 1
            aItems := {" "}
            IF select(alias()) > 0
               DO WHILE !EMPTY(ORDNAME(i))
                  AADD(aItems,ORDNAME(i++))
               ENDDO
            ENDIF
         ELSE
            aItems := Iif( j != 0 .AND. aDataDef[ j,6 ] != NIL, aDataDef[ j,6 ], { "True","False" } )
         ENDIF
         varbuf := AllTrim(varbuf)
         nChoic := Ascan( aItems,varbuf )

         @ x1,y1-2 COMBOBOX oGet           ;
               ITEMS aItems                   ;
               INIT nChoic                    ;
               OF oBrw1                       ;
               SIZE nWidth, ::height + 6      ;
               FONT ::oFont                   ;
               STYLE WS_VSCROLL               ;
               ON LOSTFOCUS {||VldBrwGet(oGet)}
      ELSE
         @ x1,y1-2 GET oGet VAR varbuf OF oBrw1  ;
               SIZE nWidth, ::height+6        ;
               STYLE ES_AUTOHSCROLL           ;
               FONT ::oFont                   ;
               VALID {||VldBrwGet(oGet)}
      ENDIF
      SetFocus( oGet:handle )
   ENDIF

   RETURN NIL

METHOD HeaderOut( hDC ) CLASS PBrowse
   LOCAL i, x, fif, xSize
   LOCAL nRows := Min( ::nRecords,::rowCount ), oColumn
   LOCAL oPen := HPen():Add( PS_SOLID,1,::sepColor )
   LOCAL oPenLight := HPen():Add( PS_SOLID,1,GetSysColor(COLOR_3DHILIGHT) )
   LOCAL oPenGray  := HPen():Add( PS_SOLID,1,GetSysColor(COLOR_3DSHADOW) )

   x := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   WHILE x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      IF fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      IF x > ::x1
         SelectObject( hDC, oPenLight:handle )
         DrawLine( hDC, x-1, ::y1+1, x-1, ::y1+(::height+1)*nRows )
         SelectObject( hDC, oPenGray:handle )
         DrawLine( hDC, x-2, ::y1+1, x-2, ::y1+(::height+1)*nRows )
      ENDIF
      x += xSize
      fif := IIF( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO

   SelectObject( hDC, oPen:handle )
   FOR i := 1 TO nRows
      DrawLine( hDC, ::x1, ::y1+(::height+1)*i, iif(::lAdjRight, ::x2, x), ::y1+(::height+1)*i )
   NEXT

   oPen:Release()

   RETURN NIL

STATIC FUNCTION VldBrwGet( oGet ,oBtn)
   LOCAL vari, j, cName
   MEMVAR Value, oCtrl, oDesigner
   PRIVATE value, oCtrl := Iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )

   cName := Lower( aProp[ oBrw1:cargo,1 ] )

   j := Ascan( oDesigner:aDataDef, {|a|a[1]==cName} )

   IF oGet:Classname() == "HCOMBOBOX"
      vari := SendMessage( oGet:handle,CB_GETCURSEL,0,0 ) + 1
      value := aProp[ oBrw1:cargo,2 ] := oGet:aItems[ vari ]
   ELSE
      vari := TRIM(oGet:GetText())   // :LFB -  COLOCOU TRIM
      value := aProp[ oBrw1:cargo,2 ] := vari
   ENDIF
   IF oCombo:value == 1
      oCtrl:oParent:aProp[ oBrw1:cargo,2 ] := value
   ELSE
      oCtrl:aProp[ oBrw1:cargo,2 ] := value
   ENDIF
   IF j != 0 .AND. oDesigner:aDataDef[ j,3 ] != NIL
      // pArray := oDesigner:aDataDef[ j,6 ]
      EvalCode( oDesigner:aDataDef[ j,3 ] )
      IF oDesigner:aDataDef[ j,4 ] != NIL
         EvalCode( oDesigner:aDataDef[ j,4 ] )
      ENDIF
   ENDIF
   RedrawWindow( oCtrl:handle,5 )
   HFormGen():oDlgSelected:oParent:lChanged := .T.
   oBrw1:lUpdated := .T.
   oBrw1:aEvents := {}
   oBrw1:aNotify := {}
   oBrw1:aControls := {}
   PostMessage( oGet:handle, WM_CLOSE, 0, 0 )
   // :LFB POS
   IF VALTYPE(obtn) = "O"
      PostMessage( oBtn:handle, WM_CLOSE, 0, 0 )
   ENDIF
   obrw1:bPosChanged := NIL
   // : END LFB
   // oBrw1:DelControl( oGet )
   // oBrw1:Refresh()

   RETURN .T.

FUNCTION InspOpen(lShow)
   LOCAL nStilo := 0
   MEMVAR oDesigner
   //PRIVATE oMenuDlg := 0

   *FONT oDesigner:oMainWnd:oFonti
   *STYLE WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SIZEBOX+WS_SYSMENU;
   lShow := IIF(VALTYPE(lShow) != "U",lShow, .T.)
   nStilo := WS_CAPTION+WS_SIZEBOX+MB_USERICON + WS_VISIBLE
   //  IIF(lShow,WS_VISIBLE,0) //DS_SYSMODAL
   INIT DIALOG oDesigner:oDlgInsp TITLE "Object Inspector" ;
         AT 0,280  SIZE 220,300       ;
         FONT HFont():Add( "MS Sans Serif",0,-12,400,,,)  ;
         STYLE nStilo;
         ON INIT {||IIF(!lshow,oDesigner:oDlgInsp:hide(),),MoveWindow(oDesigner:oDlgInsp:handle,0,134,280,410)}   ;
         ON GETFOCUS {|o| o:show(),.t.};
         ON EXIT {|| oDesigner:oDlgInsp := NIL, CheckMenuItem( oDesigner:oMainWnd:handle, 1010, .F. ), .T. } ;
         ON OTHER MESSAGES {|o,m,wp,lp| MessagesOthers( o, m, wp, lp ) }

   @ 0,0 COMBOBOX oCombo ITEMS {} SIZE 220,22 ;
         STYLE WS_VSCROLL                     ;
         ON SIZE {|o,x|MoveWindow(o:handle,0,0,x,250)} ;
         ON CHANGE {||ComboOnChg()}

   @ 0,28 TAB oTab ITEMS {} SIZE 220,250 ;
         ON SIZE {|o,x,y|MoveWindow(o:handle,0,28,x,y-28)}

   BEGIN PAGE "Properties" OF oTab
      @ 2,30 PBROWSE oBrw1 ARRAY SIZE 214,218 STYLE WS_VSCROLL ;
            ON SIZE {|o,x,y|MoveWindow(o:handle,2,30,x-6,y-32)}
            setdlgkey(oDesigner:oDlgInsp,0,VK_DELETE,{|| ResetToDefault(oBrw1)} )

      oBrw1:tColor := GetSysColor( COLOR_BTNTEXT )
      oBrw1:tColorSel := 8404992
      oBrw1:bColor := oBrw1:bColorSel := GetSysColor( COLOR_BTNFACE )
      oBrw1:freeze := 1
      oBrw1:lDispHead := .F.
      oBrw1:lSep3d := .T.
      oBrw1:sepColor  := GetSysColor( COLOR_BTNSHADOW )
      oBrw1:aArray := aProp
      oBrw1:AddColumn( HColumn():New( ,{|v,o| HB_SYMBOL_UNUSED( v ),Iif(Empty(o:aArray[o:nCurrent,1]),"","  "+o:aArray[o:nCurrent,1])},"C",12,0,.T. ) )
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
      oBrw2:aArray := aMethods
      oBrw2:AddColumn( HColumn():New( ,{|v,o|HB_SYMBOL_UNUSED( v ),Iif(Empty(o:aArray[o:nCurrent,1]),"","  "+o:aArray[o:nCurrent,1])},"C",12,0,.T. ) )
      oBrw2:AddColumn( HColumn():New( ,{|v,o|HB_SYMBOL_UNUSED( v ),Iif(Empty(o:aArray[o:nCurrent,2]),"",":"+o:aArray[o:nCurrent,1])},"C",100,0,.T. ) )
   END PAGE OF oTab

   // : LFB POS
   @ 190,25 BUTTON "Close" SIZE 50, 23     ;
         ON SIZE {|o,x|o:Move(x-52,,,)};
         ON CLICK {|| oDesigner:oDlgInsp:close()}
   // : LFB

   CONTEXT MENU oMenuisnp
      MENUITEM "AlwaysOnTop" ACTION ActiveTopMost( oDesigner:oDlgInsp:Handle, .t. )
      //{||oDesigner:oDlgInsp:Close(),inspOpen(.F.)}
      MENUITEM "Normal" ACTION ActiveTopMost( oDesigner:oDlgInsp:Handle, .f. )
      //{||oDesigner:oDlgInsp:Close(),inspOpen(0)}
      MENUITEM "Hide" ACTION oDesigner:oDlgInsp:close()
    ENDMENU

   ACTIVATE DIALOG oDesigner:oDlgInsp NOMODAL
   CheckMenuItem( oDesigner:oMainWnd:handle, 1010, .T. )

   InspSetCombo()

   oDesigner:oDlgInsp:AddEvent( 0,IDOK,{||DlgOk()} )
   oDesigner:oDlgInsp:AddEvent( 0,IDCANCEL,{||DlgCancel()} )

   RETURN NIL

STATIC FUNCTION DlgOk()

   IF !Empty( oBrw1:aControls )
      VldBrwGet( oBrw1:aControls[1] )
   ENDIF

   RETURN NIL

STATIC FUNCTION DlgCancel()

   IF !Empty( oBrw1:aControls )
      oBrw1:aEvents := {}
      oBrw1:aNotify := {}
      PostMessage( oBrw1:aControls[1]:handle,WM_CLOSE,0,0 )
      oBrw1:aControls := {}
      // oBrw1:DelControl( oBrw1:aControls[1] )
      // oBrw1:Refresh()
   ENDIF

   RETURN NIL

FUNCTION InspSetCombo()
LOCAL i, aControls, oCtrl, n := -1, oDlg := HFormGen():oDlgSelected
MEMVAR oDesigner

   oCombo:aItems := {}
   IF oDlg != NIL
      n := 0
      Aadd( oCombo:aItems, "Form." + oDlg:title )
      oCtrl := GetCtrlSelected( oDlg )
      aControls := Iif( oDesigner:lReport, oDlg:aControls[1]:aControls[1]:aControls, ;
            oDlg:aControls )
      FOR i := 1 TO Len( aControls )
         IF ( oDesigner:lReport )
            Aadd( oCombo:aItems, aControls[i]:cClass + "." + Iif( aControls[i]:title != NIL, Left( aControls[i]:title, 15 ), Ltrim( str( aControls[i]:id ) ) ) )
         ELSE
            Aadd( oCombo:aItems, aControls[i]:cClass + "." + aControls[i]:GetProp("Name",2) )
         ENDIF
         IF oCtrl != NIL .AND. oCtrl:handle == aControls[i]:handle
            n := i
        ENDIF
      NEXT
   ENDIF
   oCombo:Requery()
   oCombo:SetItem(n + 1)
   /*
   oCombo:value := n + 1
   oCombo:Refresh()
   */
   InspSetBrowse()

   RETURN NIL

FUNCTION InspUpdCombo( n )
   LOCAL aControls, i
   MEMVAR oDesigner

   IF n > 0
      aControls := Iif( oDesigner:lReport, ;
            HFormGen():oDlgSelected:aControls[1]:aControls[1]:aControls, ;
            HFormGen():oDlgSelected:aControls )
      i := Len( aControls )
      IF i >= Len( oCombo:aItems )
         IF ( oDesigner:lReport )
            Aadd( oCombo:aItems, aControls[i]:cClass + "." + Iif( aControls[i]:title != NIL, Left( aControls[i]:title, 15 ), Ltrim( str( aControls[i]:id ) ) ) )
         ELSE
            Aadd( oCombo:aItems, aControls[i]:cClass + "." + aControls[i]:GetProp("Name",2) )
         ENDIF
      ELSEIF i + 1 < Len( oCombo:aItems )
         RETURN InspSetCombo()
      ENDIF
   ENDIF
   oCombo:Requery()
   oCombo:SetItem(n + 1)
   /*
   oCombo:value := n + 1
   oCombo:Refresh()
   */
   InspSetBrowse()

   RETURN NIL

STATIC FUNCTION ComboOnChg()
   MEMVAR oDesigner
   LOCAL oDlg := HFormGen():oDlgSelected, oCtrl, n
   LOCAL aControls := Iif( oDesigner:lReport,oDlg:aControls[1]:aControls[1]:aControls,oDlg:aControls )

   oCombo:value := SendMessage( oCombo:handle,CB_GETCURSEL,0,0 ) + 1
   IF oDlg != NIL
      n := oCombo:value - 1
      oCtrl := GetCtrlSelected( oDlg )
      IF n == 0
         IF oCtrl != NIL
            SetCtrlSelected( oDlg )
         ENDIF
      ELSEIF n > 0
         IF oCtrl == NIL .OR. oCtrl:handle != aControls[n]:handle
            SetCtrlSelected( oDlg,aControls[n],n )
         ENDIF
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION InspSetBrowse()
   LOCAL i, o, nRow:=1

   IF oBrw1 != NIL
      nRow:=oBrw1:rowPos
   ENDIF
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
   oBrw1:rowPos := 1 //IIF(nrow > LEN(APROP),1,NROW-1) //1
   oBrw2:rowPos := 1
   oBrw1:Refresh()
   oBrw2:Refresh()

   RETURN NIL

FUNCTION InspUpdBrowse()
   LOCAL i, lChg := .F.
   MEMVAR value, oCtrl, oDesigner
   PRIVATE value, oCtrl

   IF oCombo == NIL
      RETURN NIL
   ENDIF

   oCtrl := Iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )
   IF oDesigner:oDlgInsp != NIL
      FOR i := 1 TO Len( aProp )
         value := Iif( oCombo:value == 1,oCtrl:oParent:aProp[ i,2 ],oCtrl:aProp[ i,2 ] )
         IF Valtype(aProp[ i,2 ]) != "O" .AND. Valtype(aProp[ i,2 ]) != "A" ;
               .AND. ( aProp[ i,2 ] == NIL .OR. !( aProp[ i,2 ] == value ) )
            aProp[ i,2 ] := value
            lChg := .T.
         ENDIF
      NEXT
      IF lChg .AND. !oBrw1:lHide
         oBrw1:Refresh()
         // : LFB pos
         statusbarmsg(,'x: '+ltrim(str(oCtrl:nLeft))+'  y: '+ltrim(str(oCtrl:nTop)),;
               'w: '+ltrim(str(oCtrl:nWidth))+' h: '+ltrim(str(oCtrl:nHeight)))
         // : LFB
      ENDIF
   ENDIF

   RETURN NIL

FUNCTION InspUpdProp( cName, xValue )
   LOCAL i

   cName := Lower( cName )
   IF ( i := Ascan( aProp, {|a|Lower(a[1])==Lower(cName)} ) ) > 0
      aProp[ i,2 ] := xValue
      oBrw1:Refresh()
   ENDIF

   RETURN NIL

STATIC FUNCTION EditArray( arr )
   LOCAL oDlg, oBrw, nRec := Eval( oBrw1:bRecno,oBrw1 ),arrold:={}
   MEMVAR oDesigner

   IF arr == NIL
      arr := {}
   ENDIF
   IF Empty( arr )
      Aadd( arr, "....." )
   ENDIF
   arrold := arr
   INIT DIALOG oDlg TITLE "Edit "+aProp[nRec,1]+" array" ;
         AT 300,280 SIZE 400,300 FONT oDesigner:oMainWnd:oFont

   @ 0,0 BROWSE oBrw ARRAY SIZE 400,255  ;
         ON SIZE {|o,x,y|o:Move(,,x,y-45)}
   oBrw:acolumns:={}
   oBrw:bcolor := 15132390
   oBrw:bcolorSel := VColor( "008000" )
   oBrw:lAppable := .T.
   oBrw:aArray := arr
   oBrw:AddColumn( HColumn():New( ,{|v,o| Iif( v!=NIL, o:aArray[o:nCurrent] := v, o:aArray[o:nCurrent] ) }, "C", 100, 0, .T. ) )
   // 30 - 35
   @ 21,265 BUTTON "Delete Item"  SIZE 110, 26 ;
         ON SIZE {|o,x,y|HB_SYMBOL_UNUSED( x ),o:Move(,y-30,,)};
         ON CLICK {|| onclick_deleteItem(oBrw)}
   @ 151,265 BUTTON "Ok" SIZE 110, 26     ;
         ON SIZE {|o,x,y|HB_SYMBOL_UNUSED( x ),o:Move(,y-30,,)}  ;
         ON CLICK {||oDlg:lResult:=.T.,EndDialog()}
   @ 276,265 BUTTON "Cancel" ID IDCANCEL SIZE 110, 26 ;
         ON SIZE {|o,x,y|HB_SYMBOL_UNUSED( x ),o:Move(,y-30,,)}

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF Len( arr ) == 1 .AND. arr[1] == "....."
         arr := NIL //{} NANDO POS
      ENDIF
      RETURN arr
   ENDIF

   RETURN NIL

// : LFB
STATIC FUNCTION onclick_deleteitem(oBrw)
   IF oBrw:nCurrent = 1 .AND. oBrw:aArray[oBrw:nCurrent] = ".."
      RETURN NIL
   ENDIF
   IF len(obrw:aArray) > 0 .AND. msgyesno("Confirm item deleted : [ "+oBrw:aArray[oBrw:nCurrent]+" ] ?","Items")
      oBrw:aArray := ADEL(obrw:aArray,oBrw:nCurrent)
      obrw:aArray := ASIZE(obrw:aArray,len(obrw:aArray)-1)
      obrw:refresh()
   ENDIF

   RETURN NIL

FUNCTION ObjInspector(oObject )
   LOCAL opForm, oBrw, oBrw2
   LOCAL nLeft:=0, nTop, nLin, oPage1,i
   LOCAL oBtn1, cType
   LOCAL aClassMsgMtdo, aClassMsgProp

   IF oObject = NIL
      oObject := HFormGen():oDlgSelected
   ENDIF
   //lData := .t.
   aClassMsgMtdo := __objGetMethodList(oObject)
#ifndef __XHARBOUR__
   aClassMsgProp := __objGetProperties( oObject, .t. )
#else
   aClassMsgProp := __ObjGetValueDiff( oObject)
#endif
   FOR i = 1 TO len(aClassMsgProp)
      ctype := VALTYPE(aClassMsgProp[i,2])
      DO CASE
      CASE ctype="C"
      CASE ctype="N"
         aClassMsgProp[i,2] := str(aClassMsgProp[i,2])
      CASE ctype="L"
         aClassMsgProp[i,2] := iif(aClassMsgProp[i,2],"True","False")
      OTHERWISE
         aClassMsgProp[i,2] := ctype
      ENDCASE
   NEXT

   INIT DIALOG opForm ;
         noexit ;
         TITLE "Methods and Properties" ;
         FONT HFont():Add( "Arial", 0, -11 ) ;
         AT 0, 0 SIZE 600, 400 ;
         STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   nTop = 4
   nLeft += 15
   @ nLeft, nTop button oBtn1 ;
         CAPTION "&Exit" ;
         SIZE 80, 25 ;
         ON CLICK { || EndDialog() }

   @ nLeft + 150, ntop+2 SAY "Object: " + 'oObject'  SIZE 200,24
   nLin = nTop + 30

   @ 6,nlin-5 TAB oPage1 ITEMS {} SIZE 580,360
   BEGIN PAGE ' Properties ' OF oPage1
      @ 010, nLin browse oBrw array size 570, 300 style WS_VSCROLL + WS_HSCROLL

      CreateArList( oBrw, aClassMsgProp )

      oBrw:aColumns[ 1 ]:length = 30
      oBrw:aColumns[ 1 ]:heading = " Property "
      oBrw:aColumns[ 2 ]:length = 10
      oBrw:aColumns[ 2 ]:heading = " Value "

   END PAGE OF oPage1

   BEGIN PAGE ' Methods ' OF oPage1
      @ 010, nLin browse oBrw2 array size 570, 300 style WS_VSCROLL + WS_HSCROLL

      CreateArList( oBrw2, aClassMsgMtdo )

      oBrw2:aColumns[ 1 ]:length = 10
      oBrw2:aColumns[ 1 ]:heading = "Methods"

   END PAGE OF oPage1

   opForm:Activate()

   RETURN NIL

STATIC FUNCTION MessagesOthers( oDlg, msg, wParam, lParam )
   MEMVAR oDesigner

   HB_SYMBOL_UNUSED( lParam )

   // writelog( str(msg)+str(wParam)+str(lParam) )
   IF msg == WM_MOUSEMOVE
      * MouseMove( oDlg, wParam, LoWord( lParam ), HiWord( lParam ) )
      RETURN 1
   ELSEIF msg == WM_LBUTTONDOWN
      * LButtonDown( oDlg, LoWord( lParam ), HiWord( lParam ) )
      RETURN 1
   ELSEIF msg == WM_LBUTTONUP
      * LButtonUp( oDlg, LoWord( lParam ), HiWord( lParam ) )
      RETURN 1
   ELSEIF msg == WM_RBUTTONUP
      *RButtonUp( oDlg, LoWord( lParam ), HiWord( lParam ) )
      oMenuisnp:Show( oDlg,oDlg:nTop+5,oDlg:nLeft+15,.T. )
      RETURN 1
   ELSEIF msg == WM_LBUTTONDBLCLK
      oDlg:hide()
      *MSGINFO('Futura a‡Æo dos Eventos')
      RETURN 1
   ELSEIF msg == WM_MOVE
   ELSEIF msg == WM_KEYDOWN
      IF wParam == 46    // Del
         DeleteCtrl()
      ENDIF
   ELSEIF msg == WM_KEYUP
   ENDIF

   RETURN -1

FUNCTION ActiveTopMost( nHandle, lActive )
   LOCAL lSucess   // ,nHandle

   nHandle:=GetActiveWindow()

   IF lActive
      lSucess := SetTopMost(nHandle)    // Set TopMost
   ELSE
      lSucess := RemoveTopMost(nHandle) // Remove TopMost
   ENDIF

   RETURN lSucess

STATIC FUNCTION resettodefault(oBrw1)
   LOCAL j, cName
   MEMVAR oDesigner, value, oCtrl
   PRIVATE value,oCtrl := Iif( oCombo:value == 1, HFormGen():oDlgSelected, GetCtrlSelected( HFormGen():oDlgSelected ) )

   cName := Lower(aProp[ oBrw1:nCurrent,1 ] )
   j := Ascan( oDesigner:aDataDef, {|a|a[1]==cName} )
   IF j = 0 .OR. aProp[ oBrw1:nCurrent,2 ] = NIL
      RETURN NIL
   ENDIF
   IF ltrim(oBrw1:aArray[oBrw1:nCurrent,1]) = "Font"
      value := aProp[ oBrw1:nCurrent,2 ]
      value:name := ""
   ELSE
      value := aProp[ oBrw1:nCurrent,2 ]
      //aProp[ oBrw1:nCurrent,2 ] := NIL //value
   ENDIF
   IF j != 0 .AND. oDesigner:aDataDef[ j,3 ] != NIL
      EvalCode( oDesigner:aDataDef[ j,3 ] )
      IF oDesigner:aDataDef[ j,4 ] != NIL
         EvalCode( oDesigner:aDataDef[ j,4 ] )
      ENDIF
   ENDIF
   RedrawWindow( oCtrl:handle,5 )
   HFormGen():oDlgSelected:oParent:lChanged := .T.
   oBrw1:lUpdated := .T.
   oBrw1:Refresh()

   RETURN NIL

  // :END LFB
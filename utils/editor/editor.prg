/*
 * $Id$
 *
 * Simple editor
 *
 * Copyright 2014 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hwgui.ch"
#include "hcedit.ch"

#define APP_VERSION  "0.8"

#ifdef __PLATFORM__UNIX
#include "gtk.ch"
#define CURS_HAND GDK_HAND1
#else
#define CURS_HAND IDC_HAND
#endif

#if defined (__HARBOUR__) // ( __HARBOUR__ - 0 >= 0x030000 )
REQUEST HB_CODEPAGE_UTF8
#endif

REQUEST HB_CODEPAGE_RU1251
REQUEST HB_CODEPAGE_RU866

#define MENU_RULER       1901
#define MENU_INSROW      1902
#define MENU_TABLE       1903
#define MENU_CELL        1904

#define BOUNDL           12

#define P_X             1
#define P_Y             2

#define SETC_XY         4
#define SETC_XFIRST     5

#define OB_TYPE         1
#define OB_OB           2
#define OB_CLS          3
#define OB_ID           4
#define OB_HREF         4

#define  CLR_BLACK          0
#define  CLR_GRAY1    5592405  // #555555
#define  CLR_GRAY2   11184810  // #AAAAAA

#define  CLR_VDBLUE  10485760
#define  CLR_LBLUE   16759929  // #79BCFF
#define  CLR_LBLUE0  12164479  // #7F9DB9
#define  CLR_LBLUE1  16773866  // #EAF2FF
#define  CLR_LBLUE2  16770002  // #D2E3FF
#define  CLR_LBLUE3  16772062  // #DEEBFF


STATIC cNewLine := e"\r\n"
STATIC cWebBrow
STATIC oFontP, oBrush1
STATIC oToolbar, oRuler, oEdit, aButtons[4]
STATIC oComboSiz, cComboSizDef := "100%", lComboSet := .F.

MEMVAR handcursor, cIniPath

FUNCTION Main ( fName )
   LOCAL oMainWindow, oFont
   LOCAL oStyle1, oStyle2, oStyle3
   LOCAL aComboSiz := { "40%", "60%", "80%", cComboSizDef, "120%", "140%", "160%" }

   PRIVATE oMenuC1, handcursor, cIniPath := FilePath( hb_ArgV( 0 ) )

   IF hwg__isUnicode()
      hb_cdpSelect( "UTF8" )
   ENDIF

   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT - 18 CHARSET 204
   PREPARE FONT oFontP NAME "Courier New" WIDTH 0 HEIGHT - 15
   oBrush1 := HBrush():Add( 16777215 )

   oStyle1 := HStyle():New( {CLR_LBLUE,CLR_LBLUE3}, 1 )
   oStyle2 := HStyle():New( {CLR_LBLUE}, 1,, 3, CLR_BLACK )
   oStyle3 := HStyle():New( {CLR_LBLUE1}, 1,, 2, CLR_LBLUE0 )

   INIT WINDOW oMainWindow MAIN TITLE "Editor" ;
      AT 200, 0 SIZE 600, 300 FONT oFont

   @ 0, 0 PANEL oToolBar SIZE oMainWindow:nWidth, 30 STYLE SS_OWNERDRAW ;
         ON SIZE {|o,x|o:Move(,,x) } ON PAINT {|o| PaintTB( o ) }
   oToolBar:brush := 0

   @ 0,2 COMBOBOX oComboSiz ITEMS aComboSiz OF oToolBar INIT Ascan( aComboSiz,cComboSizDef ) ;
         SIZE 80, 26 DISPLAYCOUNT 6 ON CHANGE {||onBtnSize()} TOOLTIP "Font size in %"

   @ 82,0 OWNERBUTTON aButtons[1] OF oToolBar ON CLICK {|| onBtnStyle(1) } ;
       SIZE 30,30 TEXT "B" FONT oMainWindow:oFont:SetFontStyle( .T. ) CHECK
   aButtons[1]:aStyle := { oStyle1,oStyle2,oStyle3 }
   aButtons[1]:cargo := "fb"
   @ 112,0 OWNERBUTTON aButtons[2] OF oToolBar ON CLICK {|| onBtnStyle(2) } ;
       SIZE 30,30 TEXT "I" FONT oMainWindow:oFont:SetFontStyle( .F.,,.T. ) CHECK
   aButtons[2]:aStyle := { oStyle1,oStyle2,oStyle3 }
   aButtons[2]:cargo := "fi"
   @ 142,0 OWNERBUTTON aButtons[3] OF oToolBar ON CLICK {|| onBtnStyle(3) } ;
       SIZE 30,30 TEXT "U" FONT oMainWindow:oFont:SetFontStyle( .F.,,.F.,.T. ) CHECK
   aButtons[3]:aStyle := { oStyle1,oStyle2,oStyle3 }
   aButtons[3]:cargo := "fu"
   @ 172,0 OWNERBUTTON aButtons[4] OF oToolBar ON CLICK {|| onBtnStyle(4) } ;
       SIZE 30,30 TEXT "S" FONT oMainWindow:oFont:SetFontStyle( .F.,,.F.,.F.,.T. ) CHECK
   aButtons[4]:aStyle := { oStyle1,oStyle2,oStyle3 }
   aButtons[4]:cargo := "fs"

   @ 0, 30 PANEL oRuler SIZE oMainWindow:nWidth, 0 STYLE SS_OWNERDRAW  ON SIZE {|o,x|o:Move(,,x) }

   @ 0, 30 HCEDITEXT oEdit SIZE 600, 270 ON SIZE { |o, x, y|o:Move( , oRuler:nHeight+oToolBar:nHeight, x, y-oRuler:nHeight-oToolBar:nHeight ) }
   oEdit:nIndent := 20
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF

   oEdit:bColorCur := oEdit:bColor
   oEdit:SetHili( "url", -1, hwg_colorC2N( "#000080") )
   oEdit:bOther := { |o, m, wp, lp|EditMessProc( o, m, wp, lp ) }
   oEdit:bChangePos := { || onChangePos() }

   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&New" ACTION NewFile()
         MENUITEM "&Open" ACTION OpenFile()
         SEPARATOR
         MENUITEM "&Save" ACTION SaveFile( .F. )
         MENUITEM "Save &as" ACTION SaveFile( .T. , .F. )
         MENUITEM "Save as &html" ACTION SaveFile( .T. , .T. )
         SEPARATOR
         MENUITEM "&Print" ACTION PrintFile()
         SEPARATOR
         MENUITEM "E&xit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "Undo" ACTION oEdit:Undo()
         SEPARATOR
         MENUITEM "Edit &URL" ACTION EditUrl( .F. )
      ENDMENU
      MENU TITLE "&View"
         MENUITEMCHECK "&Ruler" ID MENU_RULER ACTION SetRuler()
      ENDMENU
      MENU TITLE "&Insert"
         MENUITEM "&URL" ACTION EditUrl( .T. )
         MENUITEM "&Image" ACTION InsImage()
         MENUITEM "&Table" ACTION InsTable( .T. )
         MENUITEM "&Rows" ID MENU_INSROW ACTION InsRows()
      ENDMENU
      MENU TITLE "&Format"
         MENU TITLE "&Style"
            MENUITEM "Set Bold" ACTION oEdit:ChgStyle( ,, "fb" )
            MENUITEM "Set Italic" ACTION oEdit:ChgStyle( ,, "fi" )
            MENUITEM "Set Underline" ACTION oEdit:ChgStyle( ,, "fu" )
            MENUITEM "Set StrikeOut" ACTION oEdit:ChgStyle( ,, "fs" )
            SEPARATOR
            MENUITEM "ReSet Bold" ACTION oEdit:ChgStyle( ,, "fb-" )
            MENUITEM "ReSet Italic" ACTION oEdit:ChgStyle( ,, "fi-" )
            MENUITEM "ReSet Underline" ACTION oEdit:ChgStyle( ,, "fu-" )
            MENUITEM "ReSet StrikeOut" ACTION oEdit:ChgStyle( ,, "fs-" )
         ENDMENU
         MENUITEM "&Font" ACTION ChgFont( .F. )
         MENUITEM "Colo&r" ACTION ChangeColor( .F. )
         SEPARATOR
         MENUITEM "&Document" ACTION ChangeDoc()
         MENU TITLE "&Paragraph"
            MENUITEM "Properties" ACTION ChangePara()
            MENUITEM "Font" ACTION ChgFont( .T. )
            MENUITEM "Color" ACTION ChangeColor( .T. )
         ENDMENU
         SEPARATOR
         MENUITEM "&Table" ID MENU_TABLE ACTION (.T.)
         MENUITEM "&Cell" ID MENU_CELL ACTION ChangeColor( .T., .T. )
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION About()
      ENDMENU
   ENDMENU

   handCursor := hwg_Loadcursor( CURS_HAND )

   IF fname != Nil
      OpenFile( fname )
   ENDIF

   ACTIVATE WINDOW oMainWindow
   CloseFile()

   RETURN Nil

STATIC FUNCTION NewFile()

   CloseFile()
   oEdit:SetText()

   RETURN Nil

STATIC FUNCTION OpenFile( fname )

   CloseFile()
   IF Empty( fname )
      fname := hwg_Selectfile( { "All files" }, { "*.*" }, "" )
   ENDIF
   IF !Empty( fname )
      IF !( Lower( hb_FNameExt( fname ) ) $ ".html;.hwge;" )
         oEdit:bImport := { |o, cText| SetText( o, cText ) }
      ENDIF
      oEdit:Open( fname )
      oEdit:bImport := Nil
      oEdit:nBoundL := iif( oEdit:nDocFormat > 0, BOUNDL, 0 )
      IF oEdit:lError
         hwg_MsgStop( "Wrong file format!" )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION SaveFile( lAs, lHtml )
   LOCAL fname

   IF lAs .OR. Empty( oEdit:cFileName )
#ifdef __PLATFORM__UNIX
      fname := hwg_Selectfile( "( *.* )", "*.*", CurDir() )
#else
      fname := hwg_Savefile( "*.*", "( *.* )", "*.*", CurDir() )
#endif
      IF !Empty( fname )
         IF Empty( hb_FnameExt( fname ) )
            fname += iif( Empty( lHtml ), ".hwge", ".html" )
         ENDIF
         oEdit:Save( fname, , lHtml )
      ENDIF
   ELSE
      oEdit:Save( oEdit:cFileName )
   ENDIF

   RETURN Nil

STATIC FUNCTION CloseFile()

   IF oEdit:lUpdated .AND. hwg_MsgYesNo( "Save changes ?" )
      SaveFile( .F. )
   ENDIF

   RETURN Nil

STATIC FUNCTION PrintFile()

   IF Empty( oEdit:nDocFormat )
      ChangeDoc()
   ENDIF
   IF !Empty( oEdit:nDocFormat )
      oEdit:Print()
   ENDIF

   RETURN Nil

STATIC FUNCTION SetRuler()

   IF Empty( oRuler:bPaint )
      oRuler:bPaint := { |o| PaintRuler(o) }
      oRuler:nHeight := 32
      oEdit:Move( , oRuler:nHeight+oToolBar:nHeight,, oEdit:nHeight - 28 )
      hwg_Checkmenuitem( ,MENU_RULER, .T. )
   ELSE
      oRuler:bPaint := Nil
      oRuler:nHeight := 0
      oEdit:Move( , oRuler:nHeight+oToolBar:nHeight,, oEdit:nHeight + 28 )
      hwg_Checkmenuitem( ,MENU_RULER, .F. )
   ENDIF
   oRuler:Move( ,,, oRuler:nHeight )

   RETURN Nil

STATIC FUNCTION PaintRuler( o )
   LOCAL pps, hDC, aCoors, n1cm, x := oEdit:nBoundL - oEdit:nShiftL, i := 0, nBoundR

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( o:handle, pps )

   n1cm := Round( oEdit:nKoeffScr * 10, 0 )
   aCoors := hwg_Getclientrect( o:handle )

   nBoundR := iif( !Empty( oEdit:nDocWidth ), Min( aCoors[3], oEdit:nDocWidth + oEdit:nMarginR - oEdit:nShiftL ), aCoors[3] - 10 )
   hwg_Fillrect( hDC, If( x < 0,0,x ), 4, nBoundR, 28, oBrush1:handle )
   DO WHILE x <= ( nBoundR - n1cm )
      i ++
      x += n1cm
      IF x > 0
         hwg_Drawline( hDC, x, 8, x, iif( i % 10 == 0, 26, 16 ) )
         IF i % 2 == 0
            hwg_Selectobject( hDC, oFontP:handle )
            hwg_Settransparentmode( hDC, .T. )
            hwg_Drawtext( hDC, LTrim( Str(i,2 ) ), x - 12, 12, x + 12, 30, DT_CENTER )
            hwg_Settransparentmode( hDC, .F. )
         ENDIF
      ENDIF
   ENDDO

   hwg_Endpaint( o:handle, pps )

   RETURN Nil

STATIC FUNCTION PaintTB( o )
   LOCAL pps, hDC, aCoors

   pps    := hwg_Definepaintstru()
   hDC    := hwg_Beginpaint( o:handle, pps )
   aCoors := hwg_Getclientrect( o:handle )
   hwg_drawGradient( hDC, 0, 0, aCoors[3], aCoors[4], 1, { CLR_GRAY1, CLR_GRAY2 } )
   hwg_Endpaint( o:handle, pps )

   RETURN Nil

STATIC FUNCTION onBtnSize()

   LOCAL cAttr

   IF !lComboSet
      IF !Empty( oEdit:aPointM2[2] ) .OR. !Empty( oEdit:aTdSel[2] )

         cAttr := "fh" + oComboSiz:aItems[oComboSiz:Value]
         oEdit:ChgStyle( ,, cAttr )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION onBtnStyle( nBtn )

   LOCAL cAttr

   IF !Empty( oEdit:aPointM2[2] ) .OR. !Empty( oEdit:aTdSel[2] )

      cAttr := aButtons[nBtn]:cargo
      oEdit:ChgStyle( ,, cAttr )
   ELSE
   ENDIF

   RETURN Nil

STATIC FUNCTION onChangePos()

   LOCAL aAttr, i, l, cTmp
   STATIC lInTable := .F.

   lComboSet := .T.
   IF !Empty( arr := oEdit:GetPosInfo() ) .AND. !Empty( arr[3] ) .AND. ;
         !Empty( arr[3][OB_CLS] )
      aAttr := oEdit:getClassAttr( arr[3][OB_CLS] )
      FOR i := 1 TO 4
         IF Ascan( aAttr, aButtons[i]:cargo ) > 0
            aButtons[i]:Press()
         ELSEIF aButtons[i]:lPress
            aButtons[i]:Release()
         ENDIF
      NEXT
      cTmp := Iif( ( i := Ascan(aAttr,"fh") ) == 0, cComboSizDef, Substr(aAttr[i],3) )
      IF ( i := Ascan( oComboSiz:aItems,cTmp ) ) != 0 .AND. oComboSiz:Value != i
         oComboSiz:Value := i
      ENDIF
   ELSE
      FOR i := 1 TO 4
         IF aButtons[i]:lPress
            aButtons[i]:Release()
         ENDIF
      NEXT
      IF oComboSiz:aItems[oComboSiz:Value] != cComboSizDef        
         oComboSiz:Value := Ascan( oComboSiz:aItems,cComboSizDef )
      ENDIF
   ENDIF
   IF ( l := ( oEdit:getEnv() > 0 ) ) != lInTable
      lInTable := l
      hwg_Enablemenuitem( , MENU_INSROW, lInTable, .T. )
      hwg_Enablemenuitem( , MENU_TABLE, lInTable, .T. )
      hwg_Enablemenuitem( , MENU_CELL, lInTable, .T. )
   ENDIF
   lComboSet := .F.

   RETURN Nil

STATIC FUNCTION ChgFont( lDiv )
   LOCAL oFont := HFont():Select( oEdit:oFont ), nFont

   IF oFont != Nil
      nFont := oEdit:AddFont( , oFont:name, oFont:width, oFont:height, oFont:weight, ;
         oFont:charset, oFont:italic, oFont:underline, oFont:strikeout )
      IF lDiv
         oEdit:StyleDiv( , "ff" + LTrim( Str(nFont ) ) )
      ELSE
         oEdit:ChgStyle( ,, "ff" + LTrim( Str(nFont ) ) )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ChangeColor( lDiv, lCell )
   LOCAL oDlg, oSay
   LOCAL aHili, tColor, bColor, nColor, tc, tb, arr := {}, arr1

   IF Len( arr1 := oEdit:GetPosInfo() ) >= 7
      IF Empty( lCell )
         oEdit:LoadEnv( arr1[1], arr1[2] )
         aHili := oEdit:StyleDiv()
         oEdit:RestoreEnv( arr1[1], arr1[2] )
      ELSE
         aHili := oEdit:StyleDiv()
      ENDIF
   ELSEIF !Empty( lCell )
      RETURN Nil
   ELSE
      aHili := oEdit:StyleDiv()
   ENDIF

   IF aHili == Nil
      tColor := oEdit:tColor
      bColor := oEdit:bColor
   ELSE
      tColor := iif( aHili[2] == Nil, oEdit:tColor, aHili[2] )
      bColor := iif( aHili[3] == Nil, oEdit:bColor, aHili[3] )
   ENDIF
   tc := tColor
   tb := bColor

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Set " + Iif( Empty(lCell),"","cell " ) + "color"  ;
      AT 210, 10  SIZE 300, 190 FONT HWindow():GetMain():oFont

   @ 20, 20 SAY "Text:" SIZE 120, 22
   @ 160, 20 BUTTON "Select" SIZE 100, 32 ON CLICK {||Iif((nColor:=Hwg_ChooseColor(tColor))==Nil,.T.,(tColor:=nColor,oSay:Setcolor(tColor,,.T.))) }

   @ 20, 60 SAY "Background:" SIZE 120, 22
   @ 160, 60 BUTTON "Select" SIZE 100, 32 ON CLICK {||Iif((nColor:=Hwg_ChooseColor(bColor))==Nil,.T.,(bColor:=nColor,oSay:Setcolor(,bColor,.T.))) }

   @ 20, 100 SAY oSay CAPTION "This is a sample" SIZE 260, 26 ;
      STYLE WS_BORDER + SS_CENTER COLOR tColor BACKCOLOR bcolor

   @  20, 140  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 180, 140 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult .AND. ( tColor != tc .OR. bColor != tb )
      IF tColor != tc
         AAdd( arr, "ct" + LTrim( Str(tColor ) ) )
      ENDIF
      IF bColor != tb
         AAdd( arr, "cb" + LTrim( Str(bColor ) ) )
      ENDIF

      IF lDiv
         IF Len( arr1 ) >= 7 .AND. Empty( lCell )
            oEdit:LoadEnv( arr1[1], arr1[2] )
            oEdit:StyleDiv( arr1[4], arr )
            oEdit:RestoreEnv( arr1[1], arr1[2] )
         ELSE
            oEdit:StyleDiv( , arr )
         ENDIF
      ELSE
         oEdit:ChgStyle( ,, arr )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ChangePara()
   LOCAL oDlg, nMarginL := oEdit:nMarginL, nMarginR := oEdit:nMarginR, nIndent := oEdit:nIndent
   LOCAL nBWidth := 0, nBColor := 0, cId := "", oGetId
   LOCAL lml := .F. , lmr := .F. , lti := .F. , nAlign := 1, aCombo := { "Left", "Center", "Right" }
   LOCAL nL := oEdit:aPointC[2], arr1, cClsName, aAttr, i, arr[6]
   LOCAL bColor := { ||
     LOCAL nColor
     IF ( nColor := Hwg_ChooseColor( nBColor ) ) != Nil
        nBColor := nColor
     ENDIF
     RETURN .T.
   }

   IF Len( arr1 := oEdit:GetPosInfo() ) >= 7
      cClsName := arr1[7,1,3]
   ELSE
      cClsName := oEdit:aStru[nl,1,3]
      IF Len( oEdit:aStru[nl,1] ) >= OB_ID
         cId := oEdit:aStru[nl,1,OB_ID]
      ENDIF
   ENDIF

   IF !Empty( cClsName )
      aAttr := oEdit:getClassAttr( cClsName )
      IF ( i := Ascan( aAttr, "ml" ) ) != 0
         nMarginL := Val( SubStr( aAttr[i],3 ) )
         lml := ( Right( aAttr[i],1 ) == '%' )
      ENDIF
      IF ( i := Ascan( aAttr, "mr" ) ) != 0
         nMarginR := Val( SubStr( aAttr[i],3 ) )
         lmr := ( Right( aAttr[i],1 ) == '%' )
      ENDIF
      IF ( i := Ascan( aAttr, "ti" ) ) != 0
         nIndent := Val( SubStr( aAttr[i],3 ) )
         lti := ( Right( aAttr[i],1 ) == '%' )
      ENDIF
      IF ( i := Ascan( aAttr, "ta" ) ) != 0
         nAlign := Val( SubStr( aAttr[i],3 ) ) + 1
      ENDIF
      IF ( i := Ascan( aAttr, "bw" ) ) != 0
         nBWidth := Val( SubStr( aAttr[i],3 ) )
      ENDIF
      IF ( i := Ascan( aAttr, "bc" ) ) != 0
         nBColor := Val( SubStr( aAttr[i],3 ) )
      ENDIF
   ENDIF

   arr[1] := nMarginL; arr[2] := nMarginR; arr[3] := nIndent; arr[4] := nAlign; arr[5] := nBWidth; arr[6] := nBColor

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Set paragraph properties"  ;
      AT 210, 10  SIZE 340, 400 FONT HWindow():GetMain():oFont ON INIT {||Iif(Len(arr1)>=7,oGetId:Disable(),.T.)}

   @ 10, 10 GROUPBOX "Margins" SIZE 320, 130
   @ 20, 40 SAY "Left:" SIZE 120, 24
   @ 140, 40 GET nMarginL SIZE 80, 24
   @ 232, 40 GET CHECKBOX lml CAPTION "in %" SIZE 80, 22

   @ 20, 68 SAY "Right:" SIZE 120, 24
   @ 140, 68 GET nMarginR SIZE 80, 24
   @ 232, 68 GET CHECKBOX lmr CAPTION "in %" SIZE 80, 22

   @ 20, 96 SAY "First line:" SIZE 120, 24
   @ 140, 96 GET nIndent SIZE 80, 24
   @ 232, 96 GET CHECKBOX lti CAPTION "in %" SIZE 80, 22

   @ 20, 160 SAY "Alignment:" SIZE 140, 24
   @ 160, 160 GET COMBOBOX nAlign ITEMS aCombo SIZE 120, 150

   @ 10, 210 GROUPBOX "Border" SIZE 320, 80
   @ 20, 246 SAY "Width:" SIZE 100, 24
   @ 140, 240 GET UPDOWN nBWidth RANGE 0, 8 SIZE 60, 30
   @ 220, 240  BUTTON "Color" SIZE 80, 30 ON CLICK bColor

   @ 10, 300 SAY "Anchor:" SIZE 100, 24
   @ 110,300 GET oGetId VAR cId SIZE 100, 24
   oGetId:nMaxLength := 0

   @  20, 350  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 220, 350 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult 
      IF ( arr[1] != nMarginL .OR. arr[2] != nMarginR .OR. ;
         arr[3] != nIndent .OR. arr[4] != nAlign .OR. arr[5] != nBWidth .OR. arr[6] != nBColor )
         aAttr := { }
         IF arr[1] != nMarginL
            AAdd( aAttr, "ml" + LTrim( Str( nMarginL ) ) + iif( lml, '%', '' ) )
         ENDIF
         IF arr[2] != nMarginR
            AAdd( aAttr, "mr" + LTrim( Str( nMarginR ) ) + iif( lmr, '%', '' ) )
         ENDIF
         IF arr[3] != nIndent
            AAdd( aAttr, "ti" + LTrim( Str( nIndent ) ) + iif( lti, '%', '' ) )
         ENDIF
         IF arr[4] != nAlign
            AAdd( aAttr, "ta" + LTrim( Str( nAlign - 1 ) ) )
         ENDIF
         IF arr[5] != nBWidth
            AAdd( aAttr, "bw" + LTrim( Str( nBWidth ) ) )
         ENDIF
         IF arr[6] != nBColor
            AAdd( aAttr, "bc" + LTrim( Str( nBColor ) ) )
         ENDIF
         IF Len( arr1 ) >= 7
            oEdit:LoadEnv( arr1[1], arr1[2] )
            oEdit:StyleDiv( arr1[4], aAttr )
            oEdit:RestoreEnv( arr1[1], arr1[2] )
         ELSE
            oEdit:StyleDiv( nL, aAttr )
         ENDIF
      ENDIF
      IF !Empty( cId )
         IF Len( oEdit:aStru[nl,1] ) >= OB_ID
            oEdit:aStru[nl,1,OB_ID] := cId
         ELSE
            Aadd( oEdit:aStru[nl,1], cId )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ChangeDoc()
   LOCAL oDlg, arr[6]
   LOCAL nFormat := oEdit:nDocFormat + 1, aCombo := { "Free", "A3", "A4", "A5", "A6" }
   LOCAL nOrient := oEdit:nDocOrient+1, nMargL, nMargR, nMargT, nMargB

   IF !Empty( oEdit:nKoeffScr )
      nMargL := oEdit:aDocMargins[1]
      nMargR := oEdit:aDocMargins[2]
      nMargT := oEdit:aDocMargins[3]
      nMargB := oEdit:aDocMargins[4]
   ELSE
      nMargL := nMargR := nMargT := nMargB := 0
   ENDIF
   arr[1] := nFormat; arr[2] := nOrient; arr[3] := nMargL; arr[4] := nMargR; arr[5] := nMargT; arr[6] := nMargB

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Document properties"  ;
      AT 210, 10  SIZE 440, 370 FONT HWindow():GetMain():oFont

   @ 20, 20 SAY "Size:" SIZE 100, 24
   @ 120, 16 GET COMBOBOX nFormat ITEMS aCombo SIZE 120, 150

   @ 20,60 GROUPBOX "Orientation" SIZE 200, 90

   GET RADIOGROUP nOrient
   @ 40,90 RADIOBUTTON "Portrait" SIZE 160, 22
   @ 40,114 RADIOBUTTON "Landscape" SIZE 160, 22
   END RADIOGROUP

   @ 20,170 GROUPBOX "Margins" SIZE 400, 120

   @ 40, 200 SAY "Left" SIZE 100, 24
   @ 140,200 GET UPDOWN nMargL RANGE 0,80 SIZE 60,30

   @ 240,200 SAY "Top" SIZE 100, 24
   @ 340,200 GET UPDOWN nMargT RANGE 0,80 SIZE 60,30

   @ 40, 240 SAY "Right" SIZE 100, 24
   @ 140,240 GET UPDOWN nMargR RANGE 0,80 SIZE 60,30

   @ 240,240 SAY "Bottom" SIZE 100, 24
   @ 340,240 GET UPDOWN nMargB RANGE 0,80 SIZE 60,30

   @  20, 320  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 220, 320 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult .AND. ( arr[1] != nFormat .OR. arr[2] != nOrient .OR. ;
         arr[3] != nMargL .OR. arr[4] != nMargR .OR.arr[5] != nMargT .OR.arr[6] != nMargB )
      IF ( oEdit:nDocFormat := nFormat - 1 ) > 0
         oEdit:nBoundL := BOUNDL
         oEdit:nDocOrient := nOrient - 1
         oEdit:aDocMargins[1] := nMargL
         oEdit:aDocMargins[2] := nMargR
         oEdit:aDocMargins[3] := nMargT
         oEdit:aDocMargins[4] := nMargB
         oEdit:nMarginL := Round( nMargL*oEdit:nKoeffScr,0 )
         oEdit:nMarginR := Round( nMargR*oEdit:nKoeffScr,0 )
         oEdit:nMarginT := Round( nMargT*oEdit:nKoeffScr,0 )
         oEdit:nMarginB := Round( nMargB*oEdit:nKoeffScr,0 )
      ELSE
         oEdit:nBoundL := oEdit:nDocOrient := oEdit:nMarginL := oEdit:nMarginR := oEdit:nMarginT := oEdit:nMarginB := 0
      ENDIF

      oEdit:Scan()
      oEdit:nWCharF := oEdit:nWSublF := 1
      oEdit:Paint( .F. )
      oEdit:SetCaretPos()
      hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )
      RETURN .T.
   ENDIF

   RETURN .F.

STATIC FUNCTION SetText( oEd, cText )
   LOCAL aText, i, nLen
   LOCAL nPos1, nPos2

   IF ( nPos1 := At( Chr(10 ), cText ) ) == 0
      aText := hb_aTokens( cText, Chr( 13 ) )
   ELSEIF SubStr( cText, nPos1 - 1, 1 ) == Chr( 13 )
      aText := hb_aTokens( cText, cNewLine )
   ELSE
      aText := hb_aTokens( cText, Chr( 10 ) )
   ENDIF
   oEd:aStru := Array( Len( aText ) )

   FOR i := 1 TO Len( aText )
      oEd:aStru[i] := { { 0,0,Nil } }
      nLen := Len( aText[i] )
      nPos2 := 1
      DO WHILE ( nPos1 := hb_At( "://", aText[i], nPos2 ) ) != 0
         DO WHILE -- nPos1 > 0 .AND. IsAlpha( SubStr( aText[i], nPos1, 1 ) ); ENDDO
         nPos1 ++
         nPos2 := nPos1
         DO WHILE ++ nPos2 <= nLen .AND. !( SubStr( aText[i], nPos2, 1 ) == " " ); ENDDO
         nPos2 --
         IF SubStr( aText[i], nPos2 - 1, 1 ) $ ",.;"
            nPos2 --
         ENDIF
         AAdd( oEd:aStru[i], { nPos1, nPos2, "url", SubStr( aText[i],nPos1,nPos2 - nPos1 + 1 ) } )
      ENDDO
   NEXT

   RETURN aText

STATIC FUNCTION EditUrl( lNew )
   LOCAL oDlg, cHref := "", cName := "", cTemp, aPos, xAttr

   aPos := oEdit:GetPosInfo()
   IF aPos != Nil .AND. aPos[3] != Nil .AND. Len( aPos[3] ) >= OB_HREF
      IF lNew
         hwg_msgStop( "Can't insert URL into existing one" )
         RETURN Nil
      ENDIF
      cHref := aPos[3,OB_HREF]
      cName := SubStr( oEdit:aText[aPos[1]], aPos[3,1], aPos[3,2] - aPos[3,1] + 1 )
   ELSEIF !lNew
      hwg_msgStop( "Set cursor to existing URL" )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE iif( lNew, "Insert URL", "Edit URL" )  ;
      AT 210, 10  SIZE 360, 190 FONT HWindow():GetMain():oFont

   @ 20, 10 SAY "Href:" SIZE 120, 22
   @ 20, 32 GET cHref SIZE 320, 26 STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   IF lNew
      @ 20, 70 SAY "Name:" SIZE 120, 22
      @ 20, 92 GET cName SIZE 320, 26 STYLE ES_AUTOHSCROLL
      Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
   ENDIF
   @  20, 140 BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 240, 140 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF !Empty( cHref ) .OR. !Empty( cName )
         IF lNew
            xAttr := oEdit:getClassAttr( "url" )
            oEdit:InsSpan( cName, xAttr, cHref )
         ELSE
            aPos[3,OB_HREF] := cHref
            oEdit:lUpdated := .T.
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION InsImage()

   LOCAL fname, lEmbed := .T., nBorder := 0
   LOCAL arr := { "Left", "Center", "Right" }, nAlign := 1

   fname := hwg_Selectfile( "Graphic files( *.jpg;*.png;*.gif;*.bmp )", "*.jpg;*.png;*.gif;*.bmp", "" )

   IF Empty( fname )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE "Insert Image - " + hb_FnameNameExt( fname )  ;
      AT 20, 30 SIZE 440, 220 FONT HWindow():GetMain():oFont

   @ 20, 10 GET CHECKBOX lEmbed CAPTION "Keep the image inside the document ?" SIZE 400, 24

   @ 20, 50 SAY "Align:" SIZE 96, 22
   @ 116, 50 GET COMBOBOX nAlign ITEMS arr SIZE 100, 26 DISPLAYCOUNT 3

   @ 20, 90 SAY "Border:" SIZE 96, 22
   @ 116, 90 GET UPDOWN nBorder RANGE 0, 4 SIZE 50, 30 STYLE WS_BORDER

   @ 80, 162 BUTTON "Ok" ID IDOK  SIZE 100, 32
   @ 260, 162 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF lEmbed
         oEdit:InsImage( , nAlign-1,, MemoRead( fname ) )
      ELSE
         oEdit:InsImage( fname, nAlign-1 )
      ENDIF
   ENDIF
   hced_Setfocus( oEdit:hEdit )

   RETURN Nil

STATIC FUNCTION InsTable( lNew )
   LOCAL oDlg, nRows := 3, nCols := 2, nBorder := 0, nBColor := 0, nWidth := 100
   LOCAL arr := { "Left", "Center", "Right" }, nAlign := 1, aAttr
   LOCAL bColor := { ||
     LOCAL nColor
     IF ( nColor := Hwg_ChooseColor( nBColor ) ) != Nil
        nBColor := nColor
     ENDIF
     RETURN .T.
   }

   /*
   IF !lNew
      nRows := Len( oNodeTblC:aItems )
      nCols := Len( oNodeTblC:cargo[CG_TABLE,TBL_COLS] )
      nBorder := oNodeTblC:cargo[CG_TABLE,TBL_BORDER]
      nWidth := - oNodeTblC:cargo[CG_TABLE,TBL_WIDTH]
      nAlign := oNodeTblC:cargo[CG_TABLE,TBL_ALIGN] + 1
   ENDIF
   */

   INIT DIALOG oDlg TITLE "Insert Table"  ;
      AT 20, 30 SIZE 440, 250 FONT HWindow():GetMain():oFont

   @ 10, 10 SAY "Rows:" SIZE 96, 22
   @ 106, 10 GET UPDOWN nRows RANGE 1, 100 SIZE 50, 30 STYLE WS_BORDER

   @ 210, 10 SAY "Columns:" SIZE 96, 22
   @ 306, 10 GET UPDOWN nCols RANGE 1, 24 SIZE 50, 30 STYLE WS_BORDER

   @ 10, 50 SAY "Width,%" SIZE 96, 22
   @ 106, 50 GET UPDOWN nWidth RANGE 10, 100 SIZE 80, 30 STYLE WS_BORDER

   @ 210, 50 SAY "Align:" SIZE 96, 22
   @ 306, 50 GET COMBOBOX nAlign ITEMS arr SIZE 100, 26 DISPLAYCOUNT 3

   @ 10, 90 GROUPBOX "Border" SIZE 320, 80
   @ 20, 116 SAY "Width:" SIZE 100, 24
   @ 140,110 GET UPDOWN nBorder RANGE 0, 8 SIZE 60, 30
   @ 220,110  BUTTON "Color" SIZE 80, 30 ON CLICK bColor

   @ 80, 200 BUTTON "Ok" ID IDOK  SIZE 100, 32
   @ 260,200 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      oEdit:lSetFocus := .T.
      IF lNew
         IF nBorder > 0 .OR. nBColor > 0
            aAttr := {}
            IF nBorder > 0
               AAdd( aAttr, "bw" + LTrim( Str( nBorder ) ) )
            ENDIF
            IF nBColor > 0
               AAdd( aAttr, "bc" + LTrim( Str( nBColor ) ) )
            ENDIF
         ENDIF
         oEdit:InsTable( nCols, nRows, iif( nWidth == 100, Nil, - nWidth ), ;
            nAlign-1, aAttr )
      ELSE
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION InsRows()
   LOCAL nL := oEdit:aPointC[P_Y], oDlg, nRows := 1

   IF Valtype(oEdit:aStru[nL,1,1]) != "C" .OR. oEdit:aStru[nL,1,1] != "tr"
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE "Insert rows"  ;
      AT 20, 30 SIZE 200, 150 FONT HWindow():GetMain():oFont

   @ 20, 20 SAY "Rows:" SIZE 100, 22
   @ 120, 20 GET UPDOWN nRows RANGE 1, 100 SIZE 50, 30 STYLE WS_BORDER

   @ 10, 100 BUTTON "Ok" ID IDOK  SIZE 80, 32
   @ 110, 100 BUTTON "Cancel" ID IDCANCEL  SIZE 80, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      oEdit:InsRows( nL, nRows )
      hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )
   ENDIF

   RETURN Nil

STATIC FUNCTION EditMessProc( o, msg, wParam, lParam )
   LOCAL i, cLine, oNode, arr
   STATIC nShiftL := 0

   IF msg == WM_LBUTTONDBLCLK
      IF !Empty( arr := o:GetPosInfo( hwg_LoWord(lParam ), hwg_HiWord(lParam ) ) ) .AND. ;
            !Empty( arr[3] ) .AND. Len( arr[3] ) > 3
         UrlLaunch( arr[3,OB_HREF] )
      ENDIF
      RETURN 0

   ELSEIF msg == WM_MOUSEMOVE
      IF !Empty( arr := o:GetPosInfo( hwg_LoWord(lParam ), hwg_HiWord(lParam ) ) ) .AND. ;
            !Empty( arr[3] ) .AND. Len( arr[3] ) > 3
         hwg_SetCursor( handCursor )
      ENDIF

   ELSEIF msg == WM_RBUTTONDOWN

   ENDIF

   IF nShiftL != o:nShiftL
      nShiftL := o:nShiftL
      hwg_Redrawwindow( oRuler:handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN - 1

STATIC FUNCTION UrlLaunch( cAddr )

   LOCAL n
   IF Lower( Left( cAddr, 4 ) ) == "http"
      IF !Empty( cWebBrow )
#ifdef __PLATFORM__UNIX
         hwg_RunApp( cWebBrow, cAddr )
#else
         hwg_RunApp( cWebBrow + " " + cAddr )
#endif
      ELSE
#ifndef __PLATFORM__UNIX
         hwg_Shellexecute( cAddr )
#endif
      ENDIF
   ELSEIF Lower( Left( cAddr, 8 ) ) == "goto://#"
      IF !Empty( n := oEdit:Find( ,Substr( cAddr,9 ) ) )
         oEdit:Goto( n )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION About()

   LOCAL oDlg, oStyle1, oStyle2

   oStyle1 := HStyle():New( { 0xFFFFFF, CLR_GRAY1 }, 1,, 2 )
   oStyle2 := HStyle():New( { 0xFFFFFF, CLR_GRAY1 }, 2,, 2 )

   INIT DIALOG oDlg TITLE "About" ;
      AT 0, 0 SIZE 400, 330 FONT HWindow():GetMain():oFont COLOR hwg_colorC2N("CCCCCC")

   @ 20, 40 SAY "Editor" SIZE 360,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 20, 64 SAY "Version "+APP_VERSION SIZE 360,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 10, 100 SAY "Copyright 2015 Alexander S.Kresin" SIZE 380,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 20, 124 SAY "http://www.kresin.ru" LINK "http://www.kresin.ru" SIZE 360,26 STYLE SS_CENTER
   @ 20, 160 LINE LENGTH 360
   @ 20, 180 SAY hwg_version() SIZE 360,26 STYLE SS_CENTER COLOR CLR_LBLUE0 TRANSPARENT

   @ 120, 246 OWNERBUTTON ON CLICK {|| hwg_EndDialog()} SIZE 160,36 ;
          TEXT "Close" COLOR hwg_colorC2N("0000FF")

   Atail(oDlg:aControls):aStyle := { oStyle1, oStyle2 }

   ACTIVATE DIALOG oDlg CENTER

   hced_Setfocus( oEdit:hEdit )

   RETURN Nil

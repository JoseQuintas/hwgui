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


#ifdef __PLATFORM__UNIX
#include "gtk.ch"
#define DIR_SEP  '/'
#define CURS_HAND GDK_HAND1
#else
#define DIR_SEP  '\'
#define CURS_HAND IDC_HAND
#endif

#if defined (__HARBOUR__) // ( __HARBOUR__ - 0 >= 0x030000 )
REQUEST HB_CODEPAGE_UTF8
#endif

REQUEST HB_CODEPAGE_RU1251
REQUEST HB_CODEPAGE_RU866

#define MENU_RULER       1901
#define BOUNDL           12

#define P_X             1
#define P_Y             2

#define SETC_XY         4
#define OB_TYPE         1
#define OB_HREF         4

   STATIC cNewLine := e"\r\n"
   STATIC cWebBrow
   STATIC lRuler := .F.
   STATIC oFontP, oBrush1
   STATIC oPanel, oEdit

   MEMVAR handcursor, cIniPath

FUNCTION Main ( fName )
   LOCAL oMainWindow, oFont
   PRIVATE oMenuC1, handcursor, cIniPath := FilePath( hb_ArgV( 0 ) )

   IF hwg__isUnicode()
      hb_cdpSelect( "UTF8" )
   ENDIF

   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT - 20 CHARSET 204
   PREPARE FONT oFontP NAME "Courier New" WIDTH 0 HEIGHT - 15
   oBrush1 := HBrush():Add( 16777215 )

   INIT WINDOW oMainWindow MAIN TITLE "Editor"  ;
      AT 200, 0 SIZE 600, 300                                ;
      ON GETFOCUS { || iif( oEdit != Nil, hwg_Setfocus( oEdit:handle ), .T. ) } ;
      FONT oFont SYSCOLOR - 1

   @ 0, 0 PANEL oPanel SIZE 0, 4

   @ 0, 4 HCEDITEXT oEdit SIZE 600, 270 ON SIZE { |o, x, y|o:Move( , oPanel:nHeight, x, y - oPanel:nHeight ) }
   oEdit:nIndent := 20
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF

   oEdit:bColorCur := oEdit:bColor
   oEdit:SetHili( "url", - 1, 255 )
   oEdit:bOther := { |o, m, wp, lp|EditMessProc( o, m, wp, lp ) }

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
         MENUITEMCHECK "&Ruler" ACTION SetRuler()
      ENDMENU
      MENU TITLE "&Document"
         MENUITEM "Properties" ACTION ChangeDoc()
         MENUITEM "Font" ACTION ChangeFont()
         SEPARATOR
         MENUITEM "RU866 -> RU1251" ACTION oEdit:Convert( "RU866", "RU1251" )
      ENDMENU
      MENU TITLE "&Paragraph"
         MENUITEM "Properties" ACTION ChangePara()
         MENUITEM "Font" ACTION ChgFont( .T. )
         MENUITEM "Color" ACTION ChangeColor( .T. )
      ENDMENU
      MENU TITLE "&Selected"
         MENU TITLE "Style"
            MENUITEM "Set Bold" ACTION oEdit:ChgStyle( , , "fb" )
            MENUITEM "Set Italic" ACTION oEdit:ChgStyle( , , "fi" )
            MENUITEM "Set Underline" ACTION oEdit:ChgStyle( , , "fu" )
            MENUITEM "Set StrikeOut" ACTION oEdit:ChgStyle( , , "fs" )
            SEPARATOR
            MENUITEM "ReSet Bold" ACTION oEdit:ChgStyle( , , "fb-" )
            MENUITEM "ReSet Italic" ACTION oEdit:ChgStyle( , , "fi-" )
            MENUITEM "ReSet Underline" ACTION oEdit:ChgStyle( , , "fu-" )
            MENUITEM "ReSet StrikeOut" ACTION oEdit:ChgStyle( , , "fs-" )
         ENDMENU
         MENUITEM "Font" ACTION ChgFont( .F. )
         MENUITEM "Color" ACTION ChangeColor( .F. )
      ENDMENU
      MENU TITLE "&Insert"
         MENUITEM "&URL" ACTION EditUrl( .T. )
         MENUITEM "&Image" ACTION InsImage()
         MENUITEM "&Table" ACTION InsTable( .T. )
         MENUITEM "&Rows" ACTION InsRows()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION hwg_MsgInfo( oMainWindow:Title, "About" )
      ENDMENU
   ENDMENU

   handCursor := hwg_Loadcursor( CURS_HAND )

   IF fname != Nil
      OpenFile( fname )
   ENDIF

   ACTIVATE WINDOW oMainWindow

   RETURN Nil

STATIC FUNCTION NewFile()

   oEdit:SetText()

   RETURN Nil

STATIC FUNCTION OpenFile( fname )

   IF Empty( fname )
      fname := hwg_Selectfile( { "All files" }, { "*.*" }, "" )
   ENDIF
   IF !Empty( fname )
      IF !( Lower( FilExten( fname ) ) $ "html;xml;hwge;" )
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
#ifdef __GTK__
      fname := hwg_Selectfile( "( *.* )", "*.*", CurDir() )
#else
      fname := hwg_Savefile( "*.*", "( *.* )", "*.*", CurDir() )
#endif
      IF !Empty( fname )
         IF Empty( FilExten( fname ) )
            fname += iif( Empty( lHtml ), ".hwge", ".html" )
         ENDIF
         oEdit:Save( fname, , lHtml )
      ENDIF
   ELSE
      oEdit:Save( oEdit:cFileName )
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

   IF ( lRuler := !lRuler )
      oPanel:bPaint := { || PaintPanel() }
      oPanel:nHeight := 32
      oEdit:Move( , 32, , oEdit:nHeight - 28 )
      oPanel:Move( , , , 32 )
   ELSE
      oPanel:bPaint := Nil
      oPanel:nHeight := 4
      oEdit:Move( , 4, , oEdit:nHeight + 28 )
      oPanel:Move( , , , 4 )
   ENDIF

   RETURN Nil

STATIC FUNCTION ChangeFont()
   LOCAL oFont

   IF !Empty( oFont := HFont():Select( oEdit:oFont ) )
      oEdit:SetFont( oFont )
   ENDIF

   RETURN Nil

STATIC FUNCTION ChgFont( lDiv )
   LOCAL oFont := HFont():Select( oEdit:oFont ), nFont

   IF oFont != Nil
      nFont := oEdit:AddFont( , oFont:name, oFont:width, oFont:height, oFont:weight, ;
         oFont:charset, oFont:italic, oFont:underline, oFont:strikeout )
      IF lDiv
         oEdit:StyleDiv( , "ff" + LTrim( Str(nFont ) ) )
      ELSE
         oEdit:ChgStyle( , , "ff" + LTrim( Str(nFont ) ) )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ChangeColor( lDiv )
   LOCAL oDlg, oSay
   LOCAL aHili, tColor, bColor, nColor, tc, tb, arr := {}

   aHili := oEdit:StyleDiv()
   IF aHili == Nil
      tColor := oEdit:tColor
      bColor := oEdit:bColor
   ELSE
      tColor := iif( aHili[2] == Nil, oEdit:tColor, aHili[2] )
      bColor := iif( aHili[3] == Nil, oEdit:bColor, aHili[3] )
   ENDIF
   tc := tColor
   tb := bColor

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Set Colors"  ;
      AT 210, 10  SIZE 300, 190 FONT HWindow():GetMain():oFont

   @ 20, 20 SAY "Text:" SIZE 120, 22
   @ 160, 20 BUTTON "Select" SIZE 100, 32 ON CLICK { ||iif( ( nColor := Hwg_ChooseColor(tColor ) ) == Nil, .T. , ( tColor := nColor,oSay:Setcolor(tColor,, .T. ) ) ) }

   @ 20, 60 SAY "Background:" SIZE 120, 22
   @ 160, 60 BUTTON "Select" SIZE 100, 32 ON CLICK { ||iif( ( nColor := Hwg_ChooseColor(bColor ) ) == Nil, .T. , ( bColor := nColor,oSay:Setcolor(,bColor, .T. ) ) ) }

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
         oEdit:StyleDiv( , arr )
      ELSE
         oEdit:ChgStyle( , , arr )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ChangePara()
   LOCAL oDlg, nMarginL := oEdit:nMarginL, nMarginR := oEdit:nMarginR, nIndent := oEdit:nIndent
   LOCAL nBWidth := 0, nBColor := 0
   LOCAL lml := .F. , lmr := .F. , lti := .F. , nAlign := 1, aCombo := { "Left", "Center", "Right" }
   LOCAL nL := oEdit:aPointC[2], cClsName := oEdit:aStru[nl,1,3], aAttr, i, arr[6]
   LOCAL bColor := { ||

   RETURN .T.

   }

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
      AT 210, 10  SIZE 340, 370 FONT HWindow():GetMain():oFont

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


   @  20, 320  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 220, 320 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult .AND. ( arr[1] != nMarginL .OR. arr[2] != nMarginR .OR. ;
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
      oEdit:StyleDiv( nL, aAttr )
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

STATIC FUNCTION SetText( cText, cPageIn, cPageOut )
   LOCAL aText, i, nLen
   LOCAL nPos1, nPos2

   IF ( nPos1 := At( Chr(10 ), cText ) ) == 0
      aText := hb_aTokens( cText, Chr( 13 ) )
   ELSEIF SubStr( cText, nPos1 - 1, 1 ) == Chr( 13 )
      aText := hb_aTokens( cText, cNewLine )
   ELSE
      aText := hb_aTokens( cText, Chr( 10 ) )
   ENDIF
   oEdit:aStru := Array( Len( aText ) )

   FOR i := 1 TO Len( aText )
      oEdit:aStru[i] := { { 0,0,Nil } }
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
         AAdd( oEdit:aStru[i], { nPos1, nPos2, "url", SubStr( aText[i],nPos1,nPos2 - nPos1 + 1 ) } )
      ENDDO
   NEXT

   RETURN aText

STATIC FUNCTION EditUrl( lNew )
   LOCAL oDlg, cHref := "", cName := "", cTemp, aPos, xAttr

   aPos := oEdit:SetCaretPos( SETC_XY + 200 )
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
   LOCAL fname

   fname := hwg_Selectfile( "Graphic files( *.jpg;*.gif;*.bmp )", "*.jpg;*.gif;*.bmp", "" )
   IF !Empty( fname )
      IF hwg_MsgYesNo( "Keep the image inside the document ?" )
         oEdit:InsImage( , , MemoRead( fname ) )
      ELSE
         oEdit:InsImage( fname )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION InsTable( lNew )
   LOCAL oDlg, nRows := 3, nCols := 2, nBorder := 0, nWidth := 100
   LOCAL arr := { "Left", "Center", "Right" }, nAlign := 1
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
      AT 20, 30 SIZE 440, 220 FONT HWindow():GetMain():oFont

   @ 10, 10 SAY "Rows:" SIZE 96, 22
   @ 106, 10 GET UPDOWN nRows RANGE 1, 100 SIZE 50, 30 STYLE WS_BORDER

   @ 210, 10 SAY "Columns:" SIZE 96, 22
   @ 306, 10 GET UPDOWN nCols RANGE 1, 24 SIZE 50, 30 STYLE WS_BORDER

   @ 10, 50 SAY "Width,%" SIZE 96, 22
   @ 106, 50 GET UPDOWN nWidth RANGE 10, 100 SIZE 80, 30 STYLE WS_BORDER

   @ 210, 50 SAY "Align:" SIZE 96, 22
   @ 306, 50 GET COMBOBOX nAlign ITEMS arr SIZE 100, 150

   @ 10, 90 SAY "Border:" SIZE 96, 22
   @ 106, 90 GET UPDOWN nBorder RANGE 0, 4 SIZE 50, 30 STYLE WS_BORDER

   @ 80, 152 BUTTON "Ok" ID IDOK  SIZE 100, 32
   @ 260, 152 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF lNew
         oEdit:InsTable( nCols, nRows, iif( nWidth == 100, Nil, - nWidth ), ;
            nAlign-1, Iif( nBorder > 0, "bw" + LTrim( Str(nBorder ) ), Nil ) )
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
      IF !Empty( arr := o:GetPosInfo( hwg_LoWord(lParam ), hwg_HiWord(lParam ) ) )
         IF !Empty( arr[3] ) .AND. Len( arr[3] ) > 3
            WebLaunch( arr[3,OB_HREF] )
         ENDIF
      ENDIF
      RETURN 0

   ELSEIF msg == WM_MOUSEMOVE
      IF !Empty( arr := o:GetPosInfo( hwg_LoWord(lParam ), hwg_HiWord(lParam ) ) )
         IF !Empty( arr[3] ) .AND. Len( arr[3] ) > 3
            hwg_SetCursor( handCursor )
         ENDIF
      ENDIF

   ELSEIF msg == WM_RBUTTONDOWN

   ENDIF

   IF nShiftL != o:nShiftL
      nShiftL := o:nShiftL
      hwg_Redrawwindow( oPanel:handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN - 1

STATIC FUNCTION PaintPanel()
   LOCAL pps, hDC, aCoors, n1cm, x := oEdit:nBoundL - oEdit:nShiftL, i := 0, nBoundR

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( oPanel:handle, pps )

   n1cm := Round( oEdit:nKoeffScr * 10, 0 )
   aCoors := hwg_Getclientrect( oPanel:handle )

   nBoundR := iif( !Empty( oEdit:nDocWidth ), Min( aCoors[3], oEdit:nDocWidth + oEdit:nMarginR - oEdit:nShiftL ), aCoors[3] - 10 )
   hwg_Fillrect( hDC, If( x < 0,0,x ), 4, nBoundR, 28, oBrush1 )
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

   hwg_Endpaint( oPanel:handle, pps )

   RETURN Nil

FUNCTION WebLaunch( cAddr )

   IF !Empty( cWebBrow )
#ifdef __GTK__
      hwg_RunApp( cWebBrow, cAddr )
#else
      hwg_RunApp( cWebBrow + " " + cAddr )
#endif
   ELSE
#ifndef __GTK__
      hwg_Shellexecute( cAddr )
#endif
   ENDIF

   RETURN Nil

   // Временно - из procmisc.lib

FUNCTION CutExten( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '.', fname ) ) = 0, fname, SubStr( fname, 1, i - 1 ) )

FUNCTION FilExten( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '.', fname ) ) = 0, "", SubStr( fname, i + 1 ) )

FUNCTION FilePath( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '\', fname ) ) = 0, ;
      iif( ( i := RAt( '/', fname ) ) = 0, "", Left( fname, i ) ), ;
      Left( fname, i ) )

FUNCTION CutPath( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '\', fname ) ) = 0, ;
      iif( ( i := RAt( '/', fname ) ) = 0, fname, SubStr( fname, i + 1 ) ), ;
      SubStr( fname, i + 1 ) )

FUNCTION AddPath( fname, cPath )

   IF Empty( FilePath( fname ) ) .AND. !Empty( cPath )
      IF !( Right( cPath,1 ) $ "\/" )
#ifdef __PLATFORM__UNIX
         cPath += "/"
#else
         cPath += "\"
#endif
      ENDIF
      fname := cPath + fname
   ENDIF

   RETURN fname

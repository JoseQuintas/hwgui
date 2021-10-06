/*
 * Repbuild - Visual Report Builder
 * Edit properties of items
 *
 * Copyright 2001-2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "guilib.ch"
#include "repbuild.h"
#include "repmain.h"

#ifndef UDS_SETBUDDYINT
#define UDS_SETBUDDYINT     2
#endif

#ifndef UDS_ALIGNRIGHT
#define UDS_ALIGNRIGHT      4
#endif

STATIC aPenStyles := { "SOLID", "DASH", "DOT", "DASHDOT", "DASHDOTDOT" }
STATIC aVariables := { "Static", "Variable" }
MEMVAR apaintrep, mypath
MEMVAR cDirSep, oFontDlg

FUNCTION LButtonDbl( xPos, yPos )
   LOCAL i, aItem

   FOR i := Len( aPaintRep[FORM_ITEMS] ) TO 1 STEP - 1
      aItem := aPaintRep[FORM_ITEMS,i]
      IF xPos >= LEFT_INDENT + aItem[ITEM_X1] ;
            .AND. xPos < LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] ;
            .AND. yPos > TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] ;
            .AND. yPos < TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] + aItem[ITEM_HEIGHT]
         aPaintRep[FORM_ITEMS,i,ITEM_STATE] := STATE_SELECTED
         IF aItem[ITEM_TYPE] == TYPE_TEXT
            StaticDlg( aItem )
         ELSEIF aItem[ITEM_TYPE] == TYPE_HLINE .OR. aItem[ITEM_TYPE] == TYPE_VLINE .OR. aItem[ITEM_TYPE] == TYPE_BOX
            LineDlg( aItem )
         ELSEIF aItem[ITEM_TYPE] == TYPE_BITMAP
            BitmapDlg( aItem )
         ELSEIF aItem[ITEM_TYPE] == TYPE_MARKER
            IF aItem[ITEM_CAPTION] == "SL" .OR. aItem[ITEM_CAPTION] == "EL"
               MarkLDlg( aItem )
            ELSEIF aItem[ITEM_CAPTION] == "DF"
               MarkFDlg( aItem )
            ENDIF
         ENDIF
         EXIT
      ENDIF
   NEXT

   RETURN Nil

STATIC FUNCTION StaticDlg( aItem )

   LOCAL oModDlg
   LOCAL oLabel2, oEdit1, oEdit2, oRb1, oRb2, oRb3, oCombo

   // FROM RESOURCE  "DLG_STATIC"
   INIT DIALOG oModDlg  TITLE "Text" ;
      AT 680, 150 SIZE 516, 460 FONT oFontDlg ;
      ON INIT { || InitStatic( oModDlg, aItem ) }

   @ 14, 6 SAY "Caption:"  SIZE 80, 22
   @ 20, 33 EDITBOX oEdit1 CAPTION "" SIZE 425, 24 STYLE WS_BORDER

   @ 20, 70 GROUPBOX "Alignment" SIZE 100, 108
   RADIOGROUP
   @ 28, 93 RADIOBUTTON oRb1 CAPTION "Left"    SIZE 80, 22
   @ 28, 118 RADIOBUTTON oRb2 CAPTION "Right"  SIZE 76, 22
   @ 28, 145 RADIOBUTTON oRb3 CAPTION "Center" SIZE 83, 22
   END RADIOGROUP SELECTED Iif( aItem[ITEM_ALIGN] == 0, 1, Iif( aItem[ITEM_ALIGN] == 1, 2, 3 ) )

   @ 173, 92 SAY oLabel2 CAPTION "" SIZE 147, 22

   @ 208, 142 BUTTON "Change" SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT ON CLICK {|| SetItemFont( oModDlg,aItem ) }

   @ 167, 70 GROUPBOX "Font" SIZE 161, 108

   @ 354, 78 SAY "Type:"  SIZE 80, 22

   @ 350, 113 COMBOBOX oCombo ITEMS aVariables SIZE 92, 96  ;
      STYLE CBS_DROPDOWNLIST + WS_TABSTOP ;
      ON INIT { || aItem[ITEM_VAR] := aItem[ITEM_VAR] + 1 }

   @ 22, 185 SAY "Script:"  SIZE 80, 22

   @ 23, 211 EDITBOX oEdit2 CAPTION "" SIZE 457, 139 ;
      STYLE WS_BORDER + ES_AUTOHSCROLL + WS_TABSTOP + ES_MULTILINE + ES_AUTOVSCROLL + ES_WANTRETURN + WS_DLGFRAME

   @ 25, 370 BUTTON "OK" SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT ON CLICK {|| EndStatic( oModDlg, aItem ) }

   @ 390, 372 BUTTON "Cancel" ID IDCANCEL  SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT

   oModDlg:Activate()

   RETURN Nil

STATIC FUNCTION InitStatic( oDlg, aItem )

   LOCAL oFont := aItem[ITEM_FONT]
/*
   oDlg:oRb1:Value := .F.
   IF aItem[ITEM_ALIGN] == 0
      oDlg:oRb1:Value := .T.
   ELSEIF aItem[ITEM_ALIGN] == 1
      oDlg:oRb2:Value := .T.
   ELSE
      oDlg:oRb3:Value := .T.
   ENDIF
*/
   oDlg:oEdit1:Value := aItem[ITEM_CAPTION]
   IF aItem[ITEM_SCRIPT] != Nil
      oDlg:oEdit2:Value := aItem[ITEM_SCRIPT]
   ENDIF
   oDlg:oCombo:Value := aItem[ITEM_VAR]
   oDlg:oLabel2:SetText( oFont:name + "," + LTrim( Str(oFont:width ) ) + "," + LTrim( Str(oFont:height ) ) )
   hwg_Setfocus( oDlg:oEdit1:handle )

   RETURN .T.

STATIC FUNCTION EndStatic( oDlg, aItem )

   aItem[ITEM_CAPTION] := oDlg:oEdit1:Value
   aItem[ITEM_ALIGN] := iif( oDlg:oRb1:Value, 0, iif( oDlg:oRb2:Value, 1, 2 ) )
   aItem[ITEM_VAR] := oDlg:oCombo:Value - 1
   aItem[ITEM_SCRIPT] := oDlg:oEdit2:Value
   aPaintRep[FORM_CHANGED] := .T.
   oDlg:Close()

   RETURN .T.

STATIC FUNCTION SetItemFont( oDlg, aItem )
   LOCAL oFont := HFont():Select()

   IF oFont != Nil
      aItem[ITEM_FONT] := oFont
      oDlg:oLabel2:SetText( oFont:name + "," + LTrim( Str(oFont:width ) ) + "," + LTrim( Str(oFont:height ) ) )
   ENDIF

   RETURN .T.

STATIC FUNCTION LineDlg( aItem )
   LOCAL oModDlg
   LOCAL oPen := aItem[ITEM_PEN]
   LOCAL oEdit1, oCombo1, oCombo2

   // FROM RESOURCE "DLG_LINE"
   INIT DIALOG oModDlg TITLE "Line" ;
      AT 430, 255 SIZE 292, 200 FONT oFontDlg ;
      ON INIT { || InitLine( oModDlg, aItem ) }

   @ 15, 5   SAY "Type:"        SIZE 49, 22
   @ 19, 90  SAY "Line width:"  SIZE 80, 22
   @ 150, 62 SAY "Fill:"        SIZE 80, 22

   @ 24, 33 COMBOBOX oCombo1  ITEMS aPenStyles SIZE 78, 96 ;
      STYLE CBS_DROPDOWNLIST + WS_TABSTOP ;
      ON INIT { || oPen:style + 1 }

   @ 109, 90 EDITBOX oEdit1 CAPTION "" SIZE 16, 24 STYLE WS_BORDER

   @ 154, 90 COMBOBOX oCombo2  ITEMS {} SIZE 87, 96 STYLE CBS_DROPDOWNLIST + WS_TABSTOP

   @ 27, 135 BUTTON "OK" SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT ON CLICK { || EndLine( oModDlg, aItem ) }

   @ 152, 134 BUTTON "Cancel" ID IDCANCEL SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT

   oModDlg:Activate()

   RETURN Nil

STATIC FUNCTION InitLine( oDlg, aItem )
   LOCAL oPen := aItem[ITEM_PEN]

   IF aItem[ITEM_TYPE] != TYPE_BOX
      oDlg:oCombo2:Disable()
   ENDIF
   oDlg:oEdit1:Value := Str( oPen:width,1 )

   RETURN .T.

STATIC FUNCTION EndLine( oDlg, aItem )
   LOCAL nWidth := Val( oDlg:oEdit1:Value )
   LOCAL cType := aPenStyles[oDlg:oCombo1:Value]
   LOCAL oPen := aItem[ITEM_PEN]
   LOCAL i := Ascan( aPenStyles, cType )

   IF oPen:style != i - 1 .OR. oPen:width != nWidth
      oPen:Release()
      aItem[ITEM_PEN] := HPen():Add( i - 1, nWidth, 0 )
      aPaintRep[FORM_CHANGED] := .T.
   ENDIF
   oDlg:Close()

   RETURN .T.

FUNCTION BitmapDlg( aItem )
   LOCAL oModDlg, res := .T.
   LOCAL oLabel6, oLabel7, oEdit1, oUpdown1

   // FROM RESOURCE "DLG_BITMAP"
   INIT DIALOG oModDlg  TITLE "Bitmap" ;
      AT 500, 130 SIZE 350, 320 FONT oFontDlg ;
      ON INIT { || InitBitmap( oModDlg, aItem ) }

   DIALOG ACTIONS OF oModDlg ;
      ON EN_CHANGE, IDC_EDIT3 ACTION { ||UpdateProcent( oModDlg, aItem ) }

   @ 49, 10 SAY "Bitmap file:"  SIZE 80, 22

   @ 9, 39 EDITBOX oEdit1 CAPTION "" SIZE 238, 24 ;
      STYLE WS_BORDER

   @ 265, 39 BUTTON "Browse" SIZE 56, 24 ;
      STYLE WS_TABSTOP + BS_FLAT ON CLICK { ||OpenBmp( oModDlg, aItem, hwg_SelectFile( "Bitmap files( *.bmp )", "*.bmp",mypath ) ) }

   @ 12, 86 GROUPBOX "Bitmap size" SIZE 283, 137

   @ 20, 115 SAY "Original size:" SIZE 102, 22
   @ 214, 117 SAY "pixels" SIZE 52, 22

   @ 214, 147 SAY "pixels" SIZE 52, 22
   @ 20, 148 SAY "New size:" SIZE 80, 22

   @ 131, 118 SAY oLabel6 CAPTION "0x0" SIZE 63, 22
   @ 131, 149 SAY oLabel7 CAPTION "0x0" SIZE 63, 22

   // Range 1 ... 500 % Start 100
   @ 207, 183 UPDOWN oUpdown1 INIT 100 RANGE 1, 500 SIZE 60, 24

   @ 20, 186 SAY "Percentage of original %" SIZE 161, 22

   @ 15, 240 BUTTON "OK" SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT ON CLICK { || EndBitmap( oModDlg, aItem ) }
   @ 197, 240 BUTTON "Cancel" ID IDCANCEL  SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT ON CLICK { || res := .F., oModDlg:Close() }

   oModDlg:Activate()

   RETURN res

STATIC FUNCTION OpenBmp( oDlg, aItem, fname )
   LOCAL aBmpSize

   oDlg:oEdit1:Value := fname
   IF !Empty( fname )
      IF aItem[ITEM_BITMAP] != Nil
         hwg_Deleteobject( aItem[ITEM_BITMAP]:handle )
      ENDIF
      aItem[ITEM_CAPTION] := fname
      aItem[ITEM_BITMAP] := HBitmap():AddFile( fname )
      aBmpSize := hwg_Getbitmapsize( aItem[ITEM_BITMAP]:handle )
      aItem[ITEM_WIDTH] :=  aItem[ITEM_BITMAP]:nWidth
      aItem[ITEM_HEIGHT] := aItem[ITEM_BITMAP]:nHeight
      oDlg:oLabel6:SetText( LTrim( Str(aBmpSize[1] ) ) + "x" + LTrim( Str(aBmpSize[2] ) ) )
      oDlg:oLabel7:SetText( LTrim( Str(aItem[ITEM_WIDTH] ) ) + "x" + LTrim( Str(aItem[ITEM_HEIGHT] ) ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION UpdateProcent( oDlg, aItem )
   LOCAL nValue := oDlg:oUpdown1:Value
   LOCAL aBmpSize

   IF aItem[ITEM_BITMAP] != Nil
      aBmpSize := hwg_Getbitmapsize( aItem[ITEM_BITMAP]:handle )
      oDlg:oLabel7:SetText( LTrim( Str(Round(aBmpSize[1] * nValue/100,0 ) ) ) + "x" + LTrim( Str(Round(aBmpSize[2] * nValue/100,0 ) ) ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION InitBitmap( oDlg, aItem )
   LOCAL aBmpSize

   IF aItem[ITEM_BITMAP] != Nil
      aBmpSize := hwg_Getbitmapsize( aItem[ITEM_BITMAP]:handle )
      oDlg:oEdit1:Value := aItem[ITEM_CAPTION]
      oDlg:oLabel6:SetText( LTrim( Str(aBmpSize[1] ) ) + "x" + LTrim( Str(aBmpSize[2] ) ) )
      oDlg:oLabel7:SetText( LTrim( Str(aItem[ITEM_WIDTH] ) ) + "x" + LTrim( Str(aItem[ITEM_HEIGHT] ) ) )
      oDlg:oUpdown1:Value := Round( aItem[ITEM_WIDTH] * 100/aBmpSize[1],0 )
   ENDIF

   RETURN .T.

STATIC FUNCTION EndBitmap( oDlg, aItem )
   LOCAL nValue := oDlg:oUpdown1:Value
   LOCAL aBmpSize := hwg_Getbitmapsize( aItem[ITEM_BITMAP]:handle )

   aItem[ITEM_WIDTH] := Round( aBmpSize[1] * nValue/100, 0 )
   aItem[ITEM_HEIGHT] := Round( aBmpSize[2] * nValue/100, 0 )
   aPaintRep[FORM_CHANGED] := .T.
   oDlg:Close()

   RETURN .T.

FUNCTION MarkLDlg( aItem )
   LOCAL oModDlg
   LOCAL oLabel1, oEdit1

   // FROM RESOURCE "DLG_MARKL"
   INIT DIALOG oModDlg TITLE "Start line" ;
      AT 399, 212 SIZE 382, 275 FONT oFontDlg ;
      ON INIT { || InitMarkL( oModDlg, aItem ) }

   @ 20, 13 SAY oLabel1 CAPTION "" SIZE 80, 22  // Scrpit

   @ 26, 41 EDITBOX oEdit1 CAPTION "" SIZE 316, 113 ;
      STYLE WS_BORDER + ES_MULTILINE + ES_AUTOVSCROLL + ES_AUTOHSCROLL + ES_WANTRETURN + WS_TABSTOP + WS_DLGFRAME

   @ 26, 168 BUTTON "OK" SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT ON CLICK { || EndMarkL( oModDlg, aItem ) }
   @ 249, 168 BUTTON "Cancel" ID IDCANCEL SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT

   oModDlg:Activate()

   RETURN Nil

STATIC FUNCTION InitMarkL( oDlg, aItem )

   oDlg:oLabel1:SetText( "Script:" )
   IF ValType( aItem[ITEM_SCRIPT] ) == "C"
      oDlg:oEdit1:Value := aItem[ITEM_SCRIPT]
   ENDIF

   RETURN .T.

STATIC FUNCTION EndMarkL( oDlg, aItem )

   aItem[ITEM_SCRIPT] := oDlg:oEdit1:Value
   aPaintRep[FORM_CHANGED] := .T.
   oDlg:Close()

   RETURN .T.

FUNCTION MarkFDlg( aItem )
   LOCAL oModDlg
   LOCAL oRb1, oRb2

   // FROM RESOURCE "DLG_MARKF"
   INIT DIALOG oModDlg  TITLE "Marker" ;
      AT 44, 80 SIZE 268, 220 FONT oFontDlg

   @ 26, 18 GROUPBOX "Type of a footer position" SIZE 207, 80
   RADIOGROUP
   @ 35, 39 RADIOBUTTON oRb1 CAPTION "Fixed"             SIZE 185, 22
   @ 35, 66 RADIOBUTTON oRb2 CAPTION "Dependent on list" SIZE 182, 22
   END RADIOGROUP SELECTED iif( aItem[ITEM_ALIGN] == 0, 1, 2 )

   @ 24, 115 BUTTON "OK" SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT ON CLICK { || EndMarkF( oModDlg, aItem ) }
   @ 144, 115 BUTTON "Cancel" ID IDCANCEL SIZE 80, 24 STYLE WS_TABSTOP + BS_FLAT

   oModDlg:Activate()

   RETURN Nil

STATIC FUNCTION EndMarkF( oDlg, aItem )

   aItem[ITEM_ALIGN] := iif( oDlg:oRb1:Value, 0, 1 )
   aPaintRep[FORM_CHANGED] := .T.
   oDlg:Close()

   RETURN .T.

FUNCTION FormOptions()
   LOCAL oModDlg
   LOCAL oLabel1, oEdit1

   // FROM RESOURCE "DLG_MARKL"
   INIT DIALOG oModDlg  TITLE "" ;
      AT 400, 212 SIZE 382, 275  FONT oFontDlg ;
      ON INIT { || InitFOpt(oModDlg) }

   @ 20, 13 SAY "Script:" SIZE 80, 22
   @ 120, 13 SAY oLabel1 CAPTION "" SIZE 80, 22

   @ 26, 41 EDITBOX oEdit1 CAPTION "" SIZE 316, 113 ;
      STYLE WS_BORDER + ES_MULTILINE + ES_AUTOVSCROLL + ES_AUTOHSCROLL + ES_WANTRETURN + WS_TABSTOP + WS_DLGFRAME

   @ 26, 168 BUTTON "OK" SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT ON CLICK { || EndFOpt(oModDlg) }
   @ 249, 168 BUTTON "Cancel" ID IDCANCEL SIZE 80, 24 ;
      STYLE WS_TABSTOP + BS_FLAT

   oModDlg:Activate()

   RETURN Nil

STATIC FUNCTION InitFOpt( oDlg )

   oDlg:oLabel1:SetText( "Variables:" )
   IF ValType( aPaintRep[FORM_VARS] ) == "C"
      oDlg:oEdit1:Value := aPaintRep[FORM_VARS]
   ENDIF

   RETURN .T.

STATIC FUNCTION EndFOpt( oDlg )

   aPaintRep[FORM_VARS] := oDlg:oEdit1:Value
   aPaintRep[FORM_CHANGED] := .T.
   oDlg:Close()

   RETURN .T.

   // ============================= EOF of propert.prg ==============================

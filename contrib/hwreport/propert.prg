/*
 * Repbuild - Visual Report Builder
 * Edit properties of items
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "guilib.ch"
#include "repbuild.h"
#include "repmain.h"

#define UDS_SETBUDDYINT     2
#define UDS_ALIGNRIGHT      4

Static aPenStyles := { "SOLID","DASH","DOT","DASHDOT","DASHDOTDOT" }
Static aVariables := { "Static", "Variable" }
memvar apaintrep, mypath
Function LButtonDbl( xPos, yPos )
Local i, aItem

   FOR i := Len( aPaintRep[FORM_ITEMS] ) TO 1 STEP -1
      aItem := aPaintRep[FORM_ITEMS,i]
      IF xPos >= LEFT_INDENT+aItem[ITEM_X1] ;
           .AND. xPos < LEFT_INDENT+aItem[ITEM_X1]+aItem[ITEM_WIDTH] ;
           .AND. yPos > TOP_INDENT+aItem[ITEM_Y1]-aPaintRep[FORM_Y] ;
           .AND. yPos < TOP_INDENT+aItem[ITEM_Y1]-aPaintRep[FORM_Y]+aItem[ITEM_HEIGHT]
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
Return Nil

Static Function StaticDlg( aItem )
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE  "DLG_STATIC" ON INIT {|| InitStatic(aItem) }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndStatic(aItem)}  ;
        ON BN_CLICKED,IDC_PUSHBUTTON1 ACTION {||SetItemFont(aItem)}
   REDEFINE COMBOBOX aVariables OF aModDlg ID IDC_COMBOBOX3 INIT aItem[ITEM_VAR]+1
   aModDlg:Activate()

Return Nil

Static Function InitStatic( aItem )
Local hDlg := hwg_GetModalHandle()
Local oFont := aItem[ITEM_FONT]
   hwg_Checkradiobutton( hDlg,IDC_RADIOBUTTON1,IDC_RADIOBUTTON3, ;
     Iif(aItem[ITEM_ALIGN]==0,IDC_RADIOBUTTON1,Iif(aItem[ITEM_ALIGN]==1,IDC_RADIOBUTTON2,IDC_RADIOBUTTON3)) )
   hwg_Setdlgitemtext( hDlg, IDC_EDIT1, aItem[ITEM_CAPTION] )
   IF aItem[ITEM_SCRIPT] != Nil
      hwg_Setdlgitemtext( hDlg, IDC_EDIT3, aItem[ITEM_SCRIPT] )
   ENDIF
   // SetComboBox( hDlg, IDC_COMBOBOX3, aVariables, aItem[ITEM_VAR]+1 )
   hwg_Setdlgitemtext( hDlg, IDC_TEXT1, oFont:name+","+Ltrim(Str(oFont:width))+","+Ltrim(Str(oFont:height)) )
   hwg_Setfocus( hwg_Getdlgitem( hDlg, IDC_EDIT1 ) )
Return .T.

Static Function EndStatic( aItem )
Local hDlg := hwg_GetModalHandle()

   aItem[ITEM_CAPTION] := hwg_Getedittext( hDlg, IDC_EDIT1 )
   aItem[ITEM_ALIGN] := Iif( hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON1 ),0, ;
                          Iif( hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON2 ),1,2 ))
   aItem[ITEM_VAR] := Ascan( aVariables,hwg_Getdlgitemtext( hDlg, IDC_COMBOBOX3, 12 ) ) - 1
   aItem[ITEM_SCRIPT] := hwg_Getedittext( hDlg, IDC_EDIT3 )
   aPaintRep[FORM_CHANGED] := .T.
   hwg_EndDialog( hDlg )
Return .T.

Static Function SetItemFont( aItem )
Local hDlg := hwg_GetModalHandle()
Local oFont := HFont():Select()
   IF oFont != Nil
      aItem[ITEM_FONT] := oFont
      hwg_Setdlgitemtext( hDlg, IDC_TEXT1, oFont:name+","+Ltrim(Str(oFont:width))+","+Ltrim(Str(oFont:height)) )
   ENDIF
Return .T.

Static Function LineDlg( aItem )
Local aModDlg
Local oPen := aItem[ITEM_PEN]

   INIT DIALOG aModDlg FROM RESOURCE "DLG_LINE" ON INIT {|| InitLine(aItem) }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndLine(aItem)}
   REDEFINE COMBOBOX aPenStyles OF aModDlg ID IDC_COMBOBOX1 INIT oPen:style+1
   aModDlg:Activate()

Return Nil

Static Function InitLine( aItem )
Local hDlg := hwg_GetModalHandle()
Local oPen := aItem[ITEM_PEN]
   // SetComboBox( hDlg, IDC_COMBOBOX1, aPenStyles, aPen[1]+1 )
   IF aItem[ITEM_TYPE] == TYPE_BOX
   ELSE
      hwg_Sendmessage( hwg_Getdlgitem( hDlg,IDC_COMBOBOX2 ), WM_ENABLE, 0, 0 )
   ENDIF
   hwg_Setdlgitemtext( hDlg, IDC_EDIT1, Str(oPen:width,1) )
Return .T.

Static Function EndLine( aItem )
Local hDlg := hwg_GetModalHandle()
Local nWidth := Val( hwg_Getedittext( hDlg, IDC_EDIT1 ) )
Local cType := hwg_Getdlgitemtext( hDlg, IDC_COMBOBOX1, 12 ), i
Local oPen := aItem[ITEM_PEN]
   i := Ascan( aPenStyles,cType )
   IF oPen:style != i-1 .OR. oPen:width != nWidth
      oPen:Release()
      aItem[ITEM_PEN] := HPen():Add( i-1,nWidth,0 )
      aPaintRep[FORM_CHANGED] := .T.
   ENDIF
   hwg_EndDialog( hDlg )
Return .T.

Function BitmapDlg( aItem )
Local aModDlg, res := .T.

   INIT DIALOG aModDlg FROM RESOURCE "DLG_BITMAP" ON INIT {|| InitBitmap(aItem) }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndBitmap(aItem)}  ;
        ON 0,IDCANCEL     ACTION {|| res := .F.,hwg_EndDialog( hwg_GetModalHandle() )} ;
        ON BN_CLICKED,IDC_BUTTONBRW ACTION {||OpenBmp(aItem,hwg_SelectFile("Bitmap files( *.bmp )", "*.bmp",mypath))} ;
        ON EN_CHANGE,IDC_EDIT3 ACTION {||UpdateProcent(aItem)}
   aModDlg:Activate()

Return res

Static Function OpenBmp( aItem,fname )
Local hDlg := hwg_GetModalHandle()
   Local aBmpSize
   hwg_Setdlgitemtext( hDlg, IDC_EDIT1, fname )
   IF !Empty( fname )
      IF aItem[ITEM_BITMAP] != Nil
         hwg_Deleteobject( aItem[ITEM_BITMAP]:handle )
      ENDIF
      aItem[ITEM_CAPTION] := fname
      aItem[ITEM_BITMAP] := HBitmap():AddFile( fname )
      aBmpSize := hwg_Getbitmapsize( aItem[ITEM_BITMAP]:handle )
      aItem[ITEM_WIDTH] :=  aItem[ITEM_BITMAP]:nWidth
      aItem[ITEM_HEIGHT] := aItem[ITEM_BITMAP]:nHeight
      hwg_Setdlgitemtext( hDlg, IDC_TEXT1, Ltrim(Str(aBmpSize[1]))+"x"+Ltrim(Str(aBmpSize[2])) )
      hwg_Setdlgitemtext( hDlg, IDC_TEXT2, Ltrim(Str(aItem[ITEM_WIDTH]))+"x"+Ltrim(Str(aItem[ITEM_HEIGHT])) )
   ENDIF
Return Nil

Static Function UpdateProcent( aItem )
Local hDlg := hwg_GetModalHandle()
Local nValue := Val( hwg_Getedittext( hDlg,IDC_EDIT3 ) )
Local aBmpSize
   IF aItem[ITEM_BITMAP] != Nil
      aBmpSize := hwg_Getbitmapsize( aItem[ITEM_BITMAP]:handle )
      hwg_Setdlgitemtext( hDlg, IDC_TEXT2, Ltrim(Str(Round(aBmpSize[1]*nValue/100,0)))+"x"+Ltrim(Str(Round(aBmpSize[2]*nValue/100,0))) )
   ENDIF
Return Nil

Static Function InitBitmap( aItem )
Local hDlg := hwg_GetModalHandle()
Local aBmpSize, hUp
   hUp := hwg_Createupdowncontrol( hDlg,120,UDS_ALIGNRIGHT+UDS_SETBUDDYINT,0,0,12,0,hwg_Getdlgitem(hDlg,IDC_EDIT3),500,1,100 )
   IF aItem[ITEM_BITMAP] != Nil
      aBmpSize := hwg_Getbitmapsize( aItem[ITEM_BITMAP]:handle )
      hwg_Setdlgitemtext( hDlg, IDC_EDIT1, aItem[ITEM_CAPTION] )
      hwg_Setdlgitemtext( hDlg, IDC_TEXT1, Ltrim(Str(aBmpSize[1]))+"x"+Ltrim(Str(aBmpSize[2])) )
      hwg_Setdlgitemtext( hDlg, IDC_TEXT2, Ltrim(Str(aItem[ITEM_WIDTH]))+"x"+Ltrim(Str(aItem[ITEM_HEIGHT])) )
      hwg_Setupdown( hUp, Round(aItem[ITEM_WIDTH]*100/aBmpSize[1],0) )
   ENDIF
Return .T.

Static Function EndBitmap( aItem )
Local hDlg := hwg_GetModalHandle()
Local nValue := Val( hwg_Getedittext( hDlg,IDC_EDIT3 ) )
Local aBmpSize := hwg_Getbitmapsize( aItem[ITEM_BITMAP]:handle )

   aItem[ITEM_WIDTH] := Round(aBmpSize[1]*nValue/100,0)
   aItem[ITEM_HEIGHT] := Round(aBmpSize[2]*nValue/100,0)
   aPaintRep[FORM_CHANGED] := .T.
   hwg_EndDialog( hDlg )
Return .T.

Function MarkLDlg( aItem )
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DLG_MARKL" ON INIT {|| InitMarkL(aItem) }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndMarkL(aItem)}  ;
        ON 0,IDCANCEL     ACTION {|| hwg_EndDialog( hwg_GetModalHandle() )}
   aModDlg:Activate()

Return Nil

Static Function InitMarkL( aItem )
Local hDlg := hwg_GetModalHandle()
   hwg_Setdlgitemtext( hDlg, IDC_TEXT1, "Script:" )
   IF Valtype(aItem[ITEM_SCRIPT]) == "C"
      hwg_Setdlgitemtext( hDlg, IDC_EDIT1, aItem[ITEM_SCRIPT] )
   ENDIF
Return .T.

Static Function EndMarkL( aItem )
Local hDlg := hwg_GetModalHandle()
   aItem[ITEM_SCRIPT] := hwg_Getedittext( hDlg, IDC_EDIT1 )
   aPaintRep[FORM_CHANGED] := .T.
   hwg_EndDialog( hDlg )
Return .T.

Function MarkFDlg( aItem )
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DLG_MARKF" ON INIT {|| InitMarkF(aItem) }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndMarkF(aItem)}  ;
        ON 0,IDCANCEL     ACTION {|| hwg_EndDialog( hwg_GetModalHandle() )}
   aModDlg:Activate()

Return Nil

Static Function InitMarkF( aItem )
Local hDlg := hwg_GetModalHandle()
   hwg_Checkradiobutton( hDlg,IDC_RADIOBUTTON1,IDC_RADIOBUTTON2, ;
      Iif(aItem[ITEM_ALIGN]==0,IDC_RADIOBUTTON1,IDC_RADIOBUTTON2 ) )
Return .T.

Static Function EndMarkF( aItem )
Local hDlg := hwg_GetModalHandle()
   aItem[ITEM_ALIGN] := Iif( hwg_Isdlgbuttonchecked( hDlg,IDC_RADIOBUTTON1 ),0,1 )
   aPaintRep[FORM_CHANGED] := .T.
   hwg_EndDialog( hDlg )
Return .T.

Function FormOptions()
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DLG_MARKL" ON INIT {|| InitFOpt() }
   DIALOG ACTIONS OF aModDlg ;
        ON 0,IDOK         ACTION {|| EndFOpt()}  ;
        ON 0,IDCANCEL     ACTION {|| hwg_EndDialog( hwg_GetModalHandle() )}
   aModDlg:Activate()

Return Nil

Static Function InitFOpt()
Local hDlg := hwg_GetModalHandle()
   hwg_Setdlgitemtext( hDlg, IDC_TEXT1, "Variables:" )
   IF Valtype(aPaintRep[FORM_VARS]) == "C"
      hwg_Setdlgitemtext( hDlg, IDC_EDIT1, aPaintRep[FORM_VARS] )
   ENDIF
Return .T.

Static Function EndFOpt( aItem )
Local hDlg := hwg_GetModalHandle()
   aPaintRep[FORM_VARS] := hwg_Getedittext( hDlg, IDC_EDIT1 )
   aPaintRep[FORM_CHANGED] := .T.
   hwg_EndDialog( hDlg )
Return .T.


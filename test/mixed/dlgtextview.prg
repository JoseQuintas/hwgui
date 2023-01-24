#include "hwgui.ch"
#include "directry.ch"

FUNCTION DlgTextView()

   LOCAL aFileList, nIndex, cFileSpec := hb_cwd() + "*.prg"
   LOCAL oDlg, oEdit, oFont := HFont():Add( "MS Sans Serif", 0, -13 )
   LOCAL aButtonList := { "First", "Previous", "Next", "Last", "Exit" }
   LOCAL cCaption

   aFileList := Directory( cFileSpec )
   nIndex := 1

   INIT DIALOG oDlg CLIPPER TITLE "Text view"  ;
      AT 0,0  SIZE 800, 600 ;
      FONT oFont ON INIT { || Dlg_SetText( oEdit, aFileList, nIndex ) }

   FOR EACH cCaption IN aButtonList
      CreateButton( cCaption, { || Button_Click( cCaption, aFileList, @nIndex, oDlg, oEdit ) } )
   NEXT
   @ 10, 60 EDITBOX oEdit CAPTION "" SIZE oDlg:nWidth - 40, oDlg:nHeight - 100 FONT oFont ;
       STYLE ES_MULTILINE + ES_AUTOVSCROLL + WS_VSCROLL + WS_HSCROLL

   ACTIVATE DIALOG oDlg

RETURN Nil

STATIC FUNCTION Dlg_SetText( oEdit, aFileList, nIndex )

   LOCAL cTxt

   IF Len( aFileList ) == 0
      cTxt := ""
   ELSE
      cTxt := MemoRead( aFileList[ nIndex, F_NAME ] )
   ENDIF
   oEdit:Value := cTxt
   oEdit:Refresh()

RETURN Nil

STATIC FUNCTION CreateButton( cCaption, bCode )

   STATIC nCol

   IF cCaption == "First"
      nCol := 20
   ELSE
      nCol += 100
   ENDIF
   @  nCol, 20 BUTTON cCaption SIZE 90, 32 ON CLICK bCode

RETURN Nil

STATIC FUNCTION Button_Click( cCaption, aFileList, nIndex, oDlg, oEdit )

   DO CASE
   CASE cCaption == "First"
      nIndex := 1
      Dlg_SetText( oEdit, aFileList, nIndex )
   CASE cCaption == "Previous"
      IF nIndex > 1
         nIndex -= 1
      ENDIF
      Dlg_SetText( oEdit, aFileList, nIndex )
   CASE cCaption == "Next"
      IF nIndex < Len( aFileList )
         nIndex += 1
      ENDIF
      Dlg_SetText( oEdit, aFileList, nIndex )
   CASE cCaption == "Last"
      nIndex := Len( aFileList )
      Dlg_SetText( oEdit, aFileList, nIndex )
   CASE cCaption == "Exit"
      oDlg:Close()
   ENDCASE

RETURN Nil

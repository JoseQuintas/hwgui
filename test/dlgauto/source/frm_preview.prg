/*
frm_preview - preview of report
*/

#include "directry.ch"
#include "frm_class.ch"

FUNCTION frm_Preview( cFileMask )

   LOCAL aFileList, nIndex
   LOCAL oFrm, oEdit := "EditPreview"
   LOCAL cCaption

   aFileList := Directory( cFileMask )
   nIndex := 1

   oFrm := frm_Class():New()
   oFrm:cOptions := ""
   oFrm:aOptionList := { ;
      { "First",    { || Button_Click( cCaption, aFileList, @nIndex, oFrm:oDlg, oEdit ) } }, ;
      { "Previous", { || Button_Click( cCaption, aFileList, @nIndex, oFrm:oDlg, oEdit ) } }, ;
      { "Next",     { || Button_Click( cCaption, aFileList, @nIndex, oFrm:oDlg, oEdit ) } }, ;
      { "Last",     { || Button_Click( cCaption, aFileList, @nIndex, oFrm:oDlg, oEdit ) } } }

   gui_DialogCreate( @oFrm:oDlg, 0, 0, oFrm:nDlgWidth, oFrm:nDlgHeight, "Preview", { || frm_SetText( oEdit, aFileList, nIndex, oFrm:oDlg ) } )
   frm_Buttons( oFrm, .F. )
   gui_MLTextCreate( oFrm:oDlg, @oEdit, 65, 10, oFrm:nDlgWidth - 40, oFrm:nDlgHeight - 120, "" )
   gui_DialogActivate( oFrm:oDlg )

   RETURN Nil

STATIC FUNCTION frm_SetText( oEdit, aFileList, nIndex, xDlg )

   LOCAL cTxt

   IF Len( aFileList ) == 0
      cTxt := ""
   ELSE
      cTxt := MemoRead( aFileList[ nIndex, F_NAME ] )
   ENDIF
   gui_TextSetValue( xDlg, oEdit, cTxt )

   RETURN Nil

STATIC FUNCTION Button_Click( cCaption, aFileList, nIndex, xDlg, oEdit )

   DO CASE
   CASE cCaption == "First"
      nIndex := 1
      frm_SetText( oEdit, aFileList, nIndex, xDlg )
   CASE cCaption == "Previous"
      IF nIndex > 1
         nIndex -= 1
      ENDIF
      frm_SetText( oEdit, aFileList, nIndex, xDlg )
   CASE cCaption == "Next"
      IF nIndex < Len( aFileList )
         nIndex += 1
      ENDIF
      frm_SetText( oEdit, aFileList, nIndex, xDlg )
   CASE cCaption == "Last"
      nIndex := Len( aFileList )
      frm_SetText( oEdit, aFileList, nIndex, xDlg )
   CASE cCaption == "Exit"
      gui_DialogClose( xDlg )
   ENDCASE

   RETURN Nil

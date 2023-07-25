#include "dbstruct.ch"
#include "directry.ch"
#include "hbclass.ch"

CREATE CLASS DlgAutoPrint

   METHOD Print()

   ENDCLASS

METHOD Print() CLASS DlgAutoPrint

   LOCAL aItem, nPag, nLin, nCol, nLen

   SET PRINTER TO ( "rel.lst" )
   SET DEVICE TO PRINT
   nPag := 0
   nLin := 99
   GOTO TOP
   DO WHILE ! Eof()
      IF nLin > 64
         nPag += 1
         @ 0, 0   SAY ::cFileDBF
         @ 0, 71 SAY "Page " + StrZero( nPag, 3 )
         @ 1, 0   SAY Replicate( "-", 80 )
         nLin := 2
         nCol := 0
         FOR EACH aItem IN ::aEditList // need additional adjust
            nLen = Max( Len( aItem[ DBS_NAME ] ), Len( Transform( FieldGet( FieldNum( aItem[ DBS_NAME ] ) ), "" ) ) )
            IF nCol != 0 .AND. nCol + nLen > 79
               nLin += 1
               nCol := 0
            ENDIF
            @ nLin, nCol SAY aItem[ DBS_NAME ]
            nCol += nLen + 2
         NEXT
         nLin += 1
      ENDIF
      nCol := 0
      FOR EACH aItem IN ::aEditList // need additional adjust
         nLen = Max( Len( aItem[ DBS_NAME ] ), Len( Transform( FieldGet( FieldNum( aItem[ DBS_NAME ] ) ), "" ) ) )
         IF nCol != 0 .AND. nCol + nLen > 79
            nLin += 1
            nCol := 0
         ENDIF
         @ nLin, nCol SAY Transform( FieldGet( FieldNum( aItem[ DBS_NAME ] ) ), "" )
         nCol += nLen + 2
      NEXT
      nLin += 1
      SKIP
   ENDDO

   SET DEVICE TO SCREEN
   SET PRINTER TO

   DlgPreview( "rel.lst" )

   RETURN Nil

#include "hwgui.ch"

STATIC FUNCTION DlgPreview( cFileMask )

   LOCAL aFileList, nIndex
   LOCAL oDlg, oEdit, oFont := HFont():Add( "Courier New", 0, -13 )
   LOCAL aButtonList := { "First", "Previous", "Next", "Last", "Exit" }
   LOCAL cCaption

   aFileList := Directory( cFileMask )
   nIndex := 1

   INIT DIALOG oDlg CLIPPER TITLE "Text view"  ;
      AT 0,0  SIZE 800, 600 ;
      ON INIT { || Dlg_SetText( oEdit, aFileList, nIndex ) }

   FOR EACH cCaption IN aButtonList
      CreateButton( cCaption, { || Button_Click( cCaption, aFileList, @nIndex, oDlg, oEdit ) } )
   NEXT
   @ 10, 65 EDITBOX oEdit CAPTION "" SIZE oDlg:nWidth - 40, oDlg:nHeight - 100 FONT oFont ;
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
   LOCAL oBtn

   IF cCaption == "First"
      nCol := 20
   ELSE
      nCol += 50
   ENDIF
   @  nCol, 10 BUTTON oBtn CAPTION Nil ;
      SIZE 50, 50 ;
      STYLE BS_TOP ;
      ON CLICK bCode ;
      ON INIT { || BtnSetImageText( oBtn, cCaption ) }

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

STATIC FUNCTION BtnSetImageText( oBtn, cCaption )

   LOCAL oIcon

   oIcon := HIcon():AddResource( "AppIcon", 30, 30 )
   hwg_SendMessage( oBtn:Handle, BM_SETIMAGE, IMAGE_ICON, oIcon:Handle )
   hwg_SendMessage( oBtn:Handle, WM_SETTEXT, 0, cCaption )

   RETURN Nil

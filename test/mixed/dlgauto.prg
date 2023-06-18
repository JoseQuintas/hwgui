#include "hbclass.ch"
#include "directry.ch"

PROCEDURE DlgAuto( cModule, cTitle, ... )

   LOCAL aFileList, aFile, nCont

   (cModule)
   (cTitle)
   SET EXCLUSIVE OFF

   IF Len( Directory( "*.dbf" ) ) == 0
      dbCreate( "test", { ;
         { "IDSTOCK", "N", 6, 0 }, ;
         { "NAME", "C", 50, 0 }, ;
         { "VALUE", "N", 10, 2 }, ;
         { "QTD", "N", 6, 0 }, ;
         { "BARCODE", "N", 10, 0 }, ;
         { "OTHER", "C", 50, 0 } } )
      USE test
      FOR nCont = 1 TO 9
         APPEND BLANK
         REPLACE ;
            field->IDSTOCK WITH nCont, ;
            field->NAME WITH Replicate( Str( nCont, 1 ), 50 ), ;
            field->Value WITH nCont, ;
            field->Qtd WITH nCont, ;
            field->BarCode WITH nCont, ;
            field->Other WITH Replicate( Str( nCont, 1 ), 50 )
      NEXT
      USE
   ENDIF
   aFileList := Directory( "*.dbf" )
   IF Len( aFileList ) == 0
      hwg_MsgInfo( "No files for test" )
   ELSE
      FOR EACH aFile IN aFileList
         Execute( hb_FNameName( aFile[ F_NAME ] ) )
         IF aFile:__EnumIndex > 10
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN

FUNCTION Execute( cFile )

   LOCAL oDlg

   oDlg := ThisDlgClass():New()
   oDlg:cFileDBF := cFile
   oDlg:cTitle   := "test of " + cFile
   oDlg:cOptions := "IEDP"
   AAdd( oDlg:aOptionList, { "Mail", { || Nil } } )
   AAdd( oDlg:aOptionList, { "CtlList",  { || oDlg:ShowCtl() } } )
   oDlg:Execute()

   RETURN Nil

CREATE CLASS ThisDlgClass INHERIT DlgAutoMainClass

   METHOD ShowCtlList()

   ENDCLASS

METHOD ShowCtlList() CLASS ThisDlgClass

   LOCAL oControl, cTxt := "", cTxtTmp := ""

   FOR EACH oControl IN ::oDlg:aControlList
      IF Len( cTxtTmp ) > 500
         cTxt += cTxtTmp + hb_Eol()
         cTxtTmp := ""
      ENDIF
      cTxtTmp += oControl[2]:winClass + Ltrim( Str( oControl[2]:id ) ) + " "
   NEXT
   cTxt += cTxtTmp
   hwg_MsgInfo( cTxt )

   RETURN Nil

#include "hbclass.ch"
#include "directry.ch"
#include "dlgauto.ch"

PROCEDURE DlgAutoMain( cDBF, aAllSetup )

   Execute( cDBF, aAllSetup )

   RETURN

FUNCTION Execute( cDBF, aAllSetup )

   LOCAL oDlg, aItem

   oDlg := ThisDlg():New()
   oDlg:cFileDBF   := cDBF
   oDlg:cTitle     := "test of " + cDBF
   oDlg:cOptions   := "IEDP"
   oDlg:lWithTab   := .F.
   oDlg:nEditStyle := 3 // from 1 to 3
   AAdd( oDlg:aOptionList, { "Mail", { || Nil } } )
   AAdd( oDlg:aOptionList, { "CtlList",  { || oDlg:ShowCtlList() } } )
   oDlg:aEditList := {}
   FOR EACH aItem IN aAllSetup
      IF cDBF == aItem[1]
         AAdd( oDlg:aEditList, { aItem[2], aItem[3], aItem[4], aItem[5], aItem[6], aItem[7], aItem[8], aItem[9], aItem[10], aItem[11] } )
      ENDIF
   NEXT
   oDlg:Execute()

   RETURN Nil

CREATE CLASS ThisDlg INHERIT DlgAutoData

   METHOD ShowCtlList()

   ENDCLASS

METHOD ShowCtlList() CLASS ThisDlg

   LOCAL oControl, cTxt := "", cTxtTmp := ""

   FOR EACH oControl IN ::oDlg:aControlList
      IF Len( cTxtTmp ) > 500
         cTxt += cTxtTmp + hb_Eol()
         cTxtTmp := ""
      ENDIF
      cTxtTmp += oControl[ CFG_OBJ ]:winClass + " " // static não tem id // Ltrim( Str( oControl[2]:id ) ) + " "
   NEXT
   cTxt += cTxtTmp
   hwg_MsgInfo( cTxt )

   RETURN Nil

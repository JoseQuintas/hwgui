/*
frm_Dialog - create the dialog for data
*/

#include "frm_class.ch"
#include "inkey.ch"

FUNCTION frm_Dialog( Self )

   LOCAL aItem, aFile

   SELECT 0
   USE ( ::cFileDBF )
   IF hb_ASCan( ::aEditList, { | e | e[ CFG_ISKEY ] } ) != 0
      SET INDEX TO ( ::cFileDBF )
   ENDIF
   // dbfs for code validation
   FOR EACH aItem IN ::aEditList
      IF ! Empty( aItem[ CFG_VTABLE ] ) .AND. Select( aItem[ CFG_VTABLE ] ) == 0
         SELECT 0
         USE ( aItem[ CFG_VTABLE ] )
         SET INDEX TO ( aItem[ CFG_VTABLE ] )
         SET ORDER TO 1
      ENDIF
   NEXT
   // dbfs for code in use validation
   FOR EACH aFile IN ::aAllSetup
      FOR EACH aItem IN aFile[ 2 ]
         IF aItem[ CFG_VTABLE ] == ::cFileDBF .AND. Select( aFile[ 1 ] ) == 0
            SELECT 0
            USE ( aFile[ 1 ] )
            SET INDEX TO ( aFile[ 1 ] )
            SET ORDER TO 1
         ENDIF
      NEXT
   NEXT

   SELECT ( Select( ::cFileDbf ) )

   gui_DialogCreate( @::oDlg, 0, 0, ::nDlgWidth, ::nDlgHeight, ::cTitle )
   ::CreateControls()
   gui_DialogActivate( ::oDlg, { || ::EditOff(), ::UpdateEdit() } )

#ifdef HBMK_HAS_GTWVG
   DO WHILE Inkey(1) != K_ESC
   ENDDO
#endif
   CLOSE DATABASES

   RETURN Nil

/*
frm_Validate - Validate each field
*/

#include "frm_class.ch"

FUNCTION frm_Validate( aItem, Self )

   LOCAL nSelect, lFound := .T., xValue, nPos

   // if btn cancel abort validate (current on hwgui only)
   nPos := hb_AScan( ::aControlList, { | e | e[ CFG_CTLTYPE ] == TYPE_BUTTON .AND. ;
      e[ CFG_CAPTION ] == "Cancel" } )
   IF nPos != 0
      IF gui_IsCurrentFocus( ::oDlg, ::aControlList[ nPos, CFG_FCONTROL ] )
         RETURN .T.
      ENDIF
   ENDIF

   xValue := gui_TextGetValue( ::oDlg, aItem[ CFG_FCONTROL ] )
   IF aItem[ CFG_ISKEY ]
      SEEK xValue
      IF ::cSelected == "INSERT"
         IF ! Eof()
            gui_Msgbox( "Code already exists" )
            gui_SetFocus( ::oDlg, aItem[ CFG_FCONTROL ] ) // minigui need this
            RETURN .F.
         ENDIF
      ELSE
         IF Eof()
            gui_Msgbox( "Code not found" )
            gui_SetFocus( ::oDlg, aItem[ CFG_FCONTROL ] ) // minigui need this
            RETURN .F.
         ENDIF
      ENDIF
      ::UpdateEdit()
      gui_TextSetValue( ::oDlg, aItem[ CFG_FCONTROL ], xValue )
   ENDIF
   // if setup to find on another dbf
   IF ! Empty( aItem[ CFG_VTABLE ] )
      nSelect := Select()
      SELECT ( Select( aItem[ CFG_VTABLE ] ) )
      SEEK xValue
      lFound := ! Eof()
      xValue := FieldGet( FieldNum( aItem[ CFG_VSHOW ] ) )
      SELECT ( nSelect )
      IF ! lFound
         frm_Browse( Self, ::oDlg, @aItem[ CFG_FCONTROL ], aItem[ CFG_VTABLE ] )
         gui_SetFocus( ::oDlg, aItem[ CFG_FCONTROL ] ) // minigui need this
      ENDIF
      gui_LabelSetValue( ::oDlg, aItem[ CFG_VCONTROL ], xValue )
   ENDIF

   RETURN lFound

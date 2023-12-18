/*
frm_Class - Class for data and bypass for functions
*/

#include "hbclass.ch"
#include "frm_class.ch"

CREATE CLASS frm_Class

   VAR cTitle
   VAR cFileDBF
   VAR aEditList       INIT {}
   VAR cOptions        INIT "IED"
   VAR aOptionList     INIT {}
   VAR cSelected       INIT "NONE"

   VAR nEditStyle      INIT 1
   VAR lWithTab        INIT .F.

   VAR nDlgWidth       INIT 1024
   VAR nDlgHeight      INIT 768
   VAR nLineSpacing    INIT 21
   VAR nLineHeight     INIT 20
   VAR nButtonSize     INIT 50
   VAR nButtonSpace    INIT 3
   VAR nTextSize       INIT 15

   VAR oDlg
   VAR aControlList   INIT {}
   VAR aAllSetup      INIT {}

   METHOD First()
   METHOD Last()
   METHOD Next()
   METHOD Previous()
   METHOD CreateControls()     INLINE frm_Buttons( Self ), frm_Edit( Self )
   METHOD ButtonSaveOn()
   METHOD ButtonSaveOff()
   METHOD UpdateEdit()
   METHOD EditKeyOn()
   METHOD EditOn()
   METHOD EditOff()
   METHOD Print()              INLINE frm_Print( Self )
   METHOD Execute()            INLINE frm_Dialog( Self )
   METHOD View()               INLINE frm_Browse( Self, "", "", ::cFileDbf, Nil ), ::UpdateEdit()
   METHOD Edit()               INLINE ::cSelected := "EDIT", ::EditKeyOn()
   METHOD Delete()
   METHOD Insert()             INLINE ::cSelected := "INSERT", ::EditKeyOn()
   METHOD Exit()               INLINE gui_DialogClose( ::oDlg )
   METHOD Save()
   METHOD Cancel()             INLINE ::cSelected := "NONE", ::EditOff(), ::UpdateEdit()
   METHOD Validate( aItem )    INLINE frm_Validate( aItem, Self )
   METHOD Browse( ... )        INLINE frm_Browse( Self, ... )

   ENDCLASS

METHOD First() Class frm_Class

   GOTO TOP
   ::UpdateEdit()

   RETURN Nil

METHOD Last() CLASS frm_Class

   GOTO BOTTOM
   ::UpdateEdit()

   RETURN Nil

METHOD Next() CLASS frm_Class

   SKIP
   IF Eof()
      GOTO BOTTOM
   ENDIF
   ::UpdateEdit()

   RETURN Nil

METHOD Previous() CLASS frm_Class

   SKIP -1
   IF Bof()
      GOTO TOP
   ENDIF
   ::UpdateEdit()

   RETURN Nil

METHOD ButtonSaveOn() CLASS frm_Class

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_BUTTON
         IF aItem[ CFG_CAPTION ] $ "Save,Cancel"
            gui_ButtonEnable( ::oDlg, aItem[ CFG_FCONTROL ], .T. )
         ELSE
            gui_ButtonEnable( ::oDlg, aItem[ CFG_FCONTROL ], .F. )
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

METHOD ButtonSaveOff() CLASS frm_Class

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_BUTTON
         IF aItem[ CFG_CAPTION ] $ "Save,Cancel"
            gui_ButtonEnable( ::oDlg, aItem[ CFG_FCONTROL ], .F. )
         ELSE
            gui_ButtonEnable( ::oDlg, aItem[ CFG_FCONTROL ], .T. )
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

METHOD EditKeyOn() CLASS frm_Class

   LOCAL aItem, oKeyEdit, lFound := .F.

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT .AND. ( aItem[ CFG_ISKEY ] .OR. Empty( aItem[ CFG_FNAME ] ) )
         gui_TextEnable( ::oDlg, aItem[ CFG_FCONTROL ], .T. )
         IF ! lFound
            lFound := .T.
            oKeyEdit := aItem[ CFG_FCONTROL ]
         ENDIF
      ENDIF
   NEXT
   ::ButtonSaveOn()
   gui_SetFocus( ::oDlg, oKeyEdit )

   RETURN Nil

METHOD EditOn() CLASS frm_Class

   LOCAL aItem, oFirstEdit, lFound := .F.

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT
         IF aItem[ CFG_ISKEY ]
            gui_TextEnable( ::oDlg, aItem[ CFG_FCONTROL ], .F. )
         ELSE
            gui_TextEnable( ::oDlg, aItem[ CFG_FCONTROL ], .T. )
            IF ! lFound
               lFound := .T.
               oFirstEdit := aItem[ CFG_FCONTROL ]
            ENDIF
         ENDIF
      ENDIF
   NEXT
   ::ButtonSaveOn()
   gui_SetFocus( ::oDlg, oFirstEdit )

   RETURN Nil

METHOD EditOff() CLASS frm_Class

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT
         gui_TextEnable( ::oDlg, aItem[ CFG_FCONTROL ], .F. )
      ENDIF
   NEXT
   ::ButtonSaveOff()

   RETURN Nil

METHOD Delete() CLASS frm_Class

   LOCAL aFile, cSearch, nSelect, aItem

   nSelect := Select()
   // check if code is in use, from validate setup
   // do not use hb_Scan(), because can exists more than one field to same dbf
   FOR EACH aFile IN ::aAllSetup
      FOR EACH aItem IN aFile[ 2 ]
         IF aItem[ CFG_VTABLE ] == ::cFileDbf
            SELECT Select( aFile[ 1 ] )
            cSearch := aItem[ CFG_FNAME ] + [=("] + ::cFileDbf + [")->] + aItem[ CFG_VFIELD ]
            LOCATE FOR &cSearch
            IF ! Eof()
               gui_MsgBox( "Code in use on " + aFile[ 1 ] )
               SELECT ( nSelect )
               RETURN Nil
            ENDIF
         ENDIF
      NEXT
   NEXT
   SELECT ( nSelect )

   IF gui_MsgYesNo( "Delete" )
      IF rLock()
         DELETE
         SKIP 0
         UNLOCK
      ENDIF
   ENDIF

   RETURN Nil

METHOD UpdateEdit() CLASS frm_Class

   LOCAL aItem, nSelect, xValue, cText

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT .AND. ! Empty( aItem[ CFG_FNAME ] )
         xValue := FieldGet( FieldNum( aItem[ CFG_FNAME ] ) )
         gui_TextSetValue( ::oDlg, aItem[ CFG_FCONTROL ], xValue )
         IF ! Empty( aItem[ CFG_VTABLE ] )
            nSelect := Select()
            SELECT ( Select( aItem[ CFG_VTABLE ] ) )
            SEEK xValue
            cText := &( aItem[ CFG_VTABLE ] )->( FieldGet( FieldNum( aItem[ CFG_VSHOW ] ) ) )
            SELECT ( nSelect )
            gui_LabelSetValue( ::oDlg, aItem[ CFG_VCONTROL ], cText )
         ENDIF
      ENDIF
   NEXT
   (cText)

   RETURN Nil

METHOD Save() CLASS frm_Class

   LOCAL aItem

   ::EditOff()
   IF RLock()
      FOR EACH aItem IN ::aControlList
         DO CASE
         CASE aItem[ CFG_CTLTYPE ] != TYPE_EDIT // not editable
         CASE Empty( aItem[ CFG_FNAME ] )       // do not have name
         CASE aItem[ CFG_ISKEY ]
         OTHERWISE
            FieldPut( FieldNum( aItem[ CFG_FNAME ] ), gui_TextGetValue( ::oDlg, aItem[ CFG_FCONTROL ] ) )
         ENDCASE
      NEXT
      SKIP 0
      UNLOCK
   ENDIF
   ::cSelected := "NONE"

   RETURN Nil

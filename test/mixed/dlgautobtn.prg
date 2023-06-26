#include "hbclass.ch"
#include "hwgui.ch"
#include "dlgauto.ch"

CREATE CLASS DlgAutoBtn

   VAR cOptions     INIT "IED"
   VAR aOptionList  INIT {}
   VAR aControlList INIT {}
   VAR nButtonSize  INIT 50
   VAR nButtonSpace INIT 3
   VAR nTextSize    INIT 20
   METHOD ButtonCreate()
   METHOD ButtonSaveOn()
   METHOD ButtonSaveOff()

   ENDCLASS

METHOD ButtonCreate() CLASS DlgAutoBtn

   LOCAL nRow, nCol, nRowLine := 1, aItem, aList := {}

   IF "I" $ ::cOptions
      AAdd( aList, { "Insert",   { || ::Insert() } } )
   ENDIF
   IF "E" $ ::cOptions
      AAdd( aList, { "Edit", { || ::Edit() } } )
   ENDIF
   IF "D" $ ::cOptions
      AAdd( aList, { "Delete",   { || ::Delete() } } )
   ENDIF
   AAdd( aList, { "View",     { || ::View() } } )
   AAdd( aList, { "First",    { || ::First() } } )
   AAdd( aList, { "Previous", { || ::Previous() } } )
   AAdd( aList, { "Next",     { || ::Next() } } )
   AAdd( aList, { "Last",     { || ::Last() } } )
   IF "E" $ ::cOptions
      AAdd( aList, { "Save",     { || ::Save() } } )
      AAdd( aList, { "Cancel",   { || ::Cancel() } } )
   ENDIF
   IF "P" $ ::cOptions
      AAdd( aList, { "Print",    { || Nil } } )
   ENDIF
   FOR EACH aItem IN ::aOptionList
      AAdd( aList, { aItem[1], aItem[2] } )
   NEXT
   AAdd( aList, { "Exit",     { || ::Exit() } } )

   nCol := 10
   nRow := 10
   FOR EACH aItem IN aList
      AAdd( ::aControlList, { TYPE_BUTTON, Nil, aItem[ 1 ], aItem[ 2 ] } )
   NEXT
   FOR EACH aItem IN ::aControlList
      @ nCol, nRow BUTTON aItem[ CFG_OBJ ] ;
         CAPTION Nil ;
         OF ::oDlg SIZE ::nButtonSize, ::nButtonSize ;
         STYLE BS_TOP ;
         ON CLICK aItem[ CFG_ACTION ] ;
         ON INIT { || ;
            BtnSetImageText( aItem[ CFG_OBJ ]:Handle, aItem[ CFG_NAME ], Self ) } ;
            TOOLTIP aItem[ CFG_NAME ]
      IF nCol > ::nDlgWidth - ( ::nButtonSize - ::nButtonSpace ) * 2
         nRowLine += 1
         nRow += ::nButtonSize + ::nButtonSpace
         nCol := ::nDlgWidth - ::nButtonSize - ::nButtonSpace
      ENDIF
      nCol += iif( nRowLine == 1, 1, -1 ) * ( ::nButtonSize + ::nButtonSpace )
   NEXT

   RETURN Nil

METHOD ButtonSaveOn() CLASS DlgAutoBtn

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_BUTTON
         IF aItem[ CFG_NAME ] $ "Save,Cancel"
            aItem[ CFG_OBJ ]:Enable()
         ELSE
            aItem[ CFG_OBJ ]:Disable()
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

METHOD ButtonSaveOff() CLASS DlgAutoBtn

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_BUTTON
         IF aItem[ CFG_NAME ] $ "Save,Cancel"
            aItem[ CFG_OBJ ]:Disable()
         ELSE
            aItem[ CFG_OBJ ]:Enable()
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

STATIC FUNCTION BtnSetImageText( hHandle, cCaption, oAuto )

   LOCAL oIcon, nPos, cResName, hIcon
   LOCAL aList := { ;
      { "Insert",   "AppIcon" }, ;
      { "Edit",     "AppIcon" }, ;
      { "View",     "AppIcon" }, ;
      { "Delete",   "AppIcon" }, ;
      { "First",    "AppIcon" }, ;
      { "Previous", "AppIcon" }, ;
      { "Next",     "AppIcon" }, ;
      { "Last",     "AppIcon" }, ;
      { "Save",     "AppIcon" }, ;
      { "Cancel",   "AppIcon" }, ;
      { "Mail",     "AppIcon" }, ;
      { "Print",    "AppIcon" }, ;
      { "CtlList",  "AppIcon" }, ;
      { "Exit",     "AppIcon" } }

   IF ( nPos := hb_AScan( aList, { | e | e[1] == cCaption } ) ) != 0
      cResName := aList[ nPos, 2 ]
      oIcon := HICON():AddResource( cResName, oAuto:nButtonSize - oAuto:nTextSize, oAuto:nButtonSize - oAuto:nTextSize )
      IF ValType( oIcon ) == "O"
         hIcon := oIcon:Handle
      ENDIF
   ENDIF
   hwg_SendMessage( hHandle, BM_SETIMAGE, IMAGE_ICON, hIcon )
   hwg_SendMessage( hHandle, WM_SETTEXT, 0, cCaption )

   RETURN Nil

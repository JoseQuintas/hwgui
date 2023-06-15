#include "hbclass.ch"
#include "hwgui.ch"

#define BUTTON_SIZE  50
#define TEXT_SIZE    20
#define BUTTON_SPACE 3
#define TYPE_BUTTON      1
#define TYPE_EDIT        2

CREATE CLASS DlgAutoButtonClass

   VAR cOptions     INIT "IED"
   VAR aOptionList  INIT {}
   VAR aControlList INIT {}
   VAR nDlgWidth    INIT 1024
   VAR nDlgHeight   INIT 768
   METHOD CreateButtons()

   ENDCLASS

METHOD CreateButtons() CLASS DlgAutoButtonClass

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
      @ nCol, nRow BUTTON aItem[2] ;
         CAPTION Nil ;
         OF ::oDlg SIZE BUTTON_SIZE, BUTTON_SIZE ;
         STYLE BS_TOP ;
         ON CLICK aItem[4] ;
         ON INIT { || ;
            BtnSetImageText( aItem[2]:Handle, aItem[3] ) } ;
         TOOLTIP aItem[1]
      IF nCol > ::nDlgWidth - ( BUTTON_SIZE - BUTTON_SPACE ) * 2
         nRowLine += 1
         nRow += BUTTON_SIZE + BUTTON_SPACE
         nCol := ::nDlgWidth - BUTTON_SIZE - BUTTON_SPACE
      ENDIF
      nCol += iif( nRowLine == 1, 1, -1 ) * ( BUTTON_SIZE + BUTTON_SPACE )
   NEXT

   RETURN Nil

STATIC FUNCTION BtnSetImageText( hHandle, cCaption )

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
      oIcon := HICON():AddResource( cResName, BUTTON_SIZE - TEXT_SIZE, BUTTON_SIZE - TEXT_SIZE )
      IF ValType( oIcon ) == "O"
         hIcon := oIcon:Handle
      ENDIF
   ENDIF
   hwg_SendMessage( hHandle, BM_SETIMAGE, IMAGE_ICON, hIcon )
   hwg_SendMessage( hHandle, WM_SETTEXT, 0, cCaption )

   RETURN Nil

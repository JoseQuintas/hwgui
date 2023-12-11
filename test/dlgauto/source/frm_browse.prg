/*
frm_browse - browse
*/

#include "frm_class.ch"

FUNCTION frm_Browse( Self, xDlg, xControl, cTable )

   LOCAL oTBrowse := {}, aItem, xValue, cField, nSelect, nPos

   nSelect := Select()
   SELECT ( cTable )

   nPos := hb_Ascan( ::aAllSetup, { | e | e[1] == cTable } )
   FOR EACH aItem IN ::aAllSetup[ nPos, 2 ]
      AAdd( oTBrowse, { aItem[ CFG_CAPTION ], aItem[ CFG_FNAME ], aItem[ CFG_FPICTURE ] } )
      IF aItem[ CFG_ISKEY ]
         cField := aItem[ CFG_FNAME ]
      ENDIF
   NEXT

   DialogBrowse( oTBrowse, cTable, cField, @xValue )

   IF ! Empty( xValue ) .AND. ! Empty( xControl )
      gui_TextSetValue( xDlg, xControl, xValue )
   ENDIF

   SELECT ( nSelect )
   (xDlg)

   RETURN Nil

FUNCTION DialogBrowse( oTBrowse, cTable, cField, xValue )

   LOCAL oThisForm, aItem

   oThisForm := frm_Class():New()
   oThisForm:cOptions := ""
   gui_DialogCreate( @oThisForm:oDlg, 0, 0, oThisForm:nDlgWidth, oThisForm:nDlgHeight, cTable, { || Nil } )
   frm_Buttons( oThisForm, .F. )
   AAdd( oThisForm:aControlList, CFG_EMPTY )
   aItem := Atail( oThisForm:aControlList )
   aItem[ CFG_CTLTYPE ] := TYPE_BROWSE

   gui_Browse( oThisForm:oDlg, @aItem[ CFG_FCONTROL ], 70, 5, ;
      oThisForm:nDlgWidth - 10, oThisForm:nDlgHeight - 80, ;
      oTbrowse, cField, @xValue, cTable )

   gui_DialogActivate( oThisForm:oDlg ) // , { || gui_SetFocus( aItem[ CFG_FCONTROL ] ) } )

   RETURN Nil

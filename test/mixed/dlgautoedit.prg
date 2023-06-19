#include "hbclass.ch"
#include "hwgui.ch"
#include "dbstruct.ch"
#include "dlgauto.ch"

CREATE CLASS DlgAutoEditClass INHERIT DlgAutoBtnClass

   VAR cTitle
   VAR cFileDBF
   VAR aEditList INIT {}
   METHOD EditSetup()
   METHOD EditUpdate()
   METHOD EditCreate()
   METHOD EditOn()
   METHOD EditOff()
   VAR oDlg

   ENDCLASS

METHOD EditOn() CLASS DlgAutoEditClass

   LOCAL aItem, oFirstEdit, lFound := .F.

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT
         aItem[ CFG_OBJ ]:Enable()
         IF ! lFound
            lFound := .T.
            oFirstEdit := aItem[ CFG_OBJ ]
         ENDIF
      ENDIF
   NEXT
   ::ButtonSaveOn()
   oFirstEdit:SetFocus()

   RETURN Nil

METHOD EditOff() CLASS DlgAutoEditClass

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT
         aItem[ CFG_OBJ ]:Disable()
      ENDIF
   NEXT
   ::ButtonSaveOff()

   RETURN Nil

METHOD EditCreate() CLASS DlgAutoEditClass

   LOCAL nRow, nCol, aItem

   FOR EACH aItem IN ::aEditList
      AAdd( ::aControlList, { TYPE_EDIT, Nil, aItem[ DBS_NAME ], aItem[ DBS_TYPE ], aItem[ DBS_LEN ], aItem[ DBS_DEC ], Nil } )
      Atail( ::aControlList)[ CFG_VALUE ] := &( ::cFileDbf )->( FieldGet( FieldNum( aItem[ DBS_NAME ] ) ) )
   NEXT
   nRow := 110
   nCol := 5
   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT
      IF nCol + 50 + aItem[ CFG_LEN ] * 12 + 50 > 1024 - 20
         nCol := 5
         nRow += 25
      ENDIF
      @ nCol, nRow SAY aItem[ CFG_NAME ] SIZE 100, 20 COLOR STYLE_FORE TRANSPARENT
      @ nCol + 110, nRow GET aItem[ CFG_OBJ ] ;
         VAR aItem[ CFG_VALUE ] ;
         SIZE ( aItem[ CFG_LEN ] + 1 ) * 12, 20 ;
         STYLE WS_DISABLED + iif( aItem[ CFG_VALTYPE ] == "N", ES_RIGHT, ES_LEFT ) ;
         MAXLENGTH aItem[ CFG_LEN ] ;
         PICTURE PictureFromValue( aItem )
      IF aItem:__EnumIndex < 5
         nCol += 5000
      ELSE
         nCol += 100 + ( ( aItem[ CFG_LEN ] + 1 ) * 12 ) + 50
      ENDIF
      ENDIF
   NEXT
   AAdd( ::aControlList, { TYPE_EDIT, Nil, "", "C", 1, 0, "" } )
   @ nCol, nRow GET Atail( ::aControlList )[ CFG_OBJ ] VAR Atail( ::aControlList )[ CFG_VALUE ] SIZE 0, 0

   RETURN Nil

METHOD EditUpdate() CLASS DlgAutoEditClass

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT
         IF ! Empty( aItem[ CFG_NAME ] )
            aItem[ CFG_OBJ ]:Value := FieldGet( FieldNum( aItem[ CFG_NAME ] ) )
            aItem[ CFG_OBJ ]:Refresh()
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

METHOD EditSetup() CLASS DlgAutoEditClass

   IF Empty( ::aEditList )
      ::aEditList := dbStruct()
   ENDIF

   RETURN Nil

STATIC FUNCTION PictureFromValue( oValue )

   LOCAL cPicture, cType, nLen, nDec

   cType := oValue[ CFG_VALTYPE ]
   nLen  := oValue[ CFG_LEN ]
   nDec  := oValue[ CFG_DEC ]
   DO CASE
   CASE cType == "D"
      cPicture := "@D"
   CASE cType == "N"
      cPicture := Replicate( "9", nLen - nDec )
      IF nDec != 0
         cPicture += "." + Replicate( "9", nDec )
      ENDIF
   CASE cType == "M"
      cPicture := "@S100"
   CASE cType == "C"
      cPicture := iif( nLen > 100, "@S100", "@X" )
   ENDCASE

   RETURN cPicture

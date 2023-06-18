#include "hbclass.ch"
#include "hwgui.ch"
#include "dbstruct.ch"
#define EDIT_NAME  3
#define EDIT_TYPE  4
#define EDIT_LEN   5
#define EDIT_DEC   6
#define EDIT_VALUE 7
#define STYLE_BACK       WIN_RGB( 13, 16, 51 )
#define STYLE_FORE       WIN_RGB( 255, 255, 255 )
#define TYPE_BUTTON      1
#define TYPE_EDIT        2
#define BUTTON_SIZE  50
#define TEXT_SIZE    20
#define BUTTON_SPACE 3

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

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[1] == TYPE_EDIT
         aItem[2]:Enable()
      ENDIF
   NEXT
   ::ButtonSaveOn()

   RETURN Nil

METHOD EditOff() CLASS DlgAutoEditClass

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[1] == TYPE_EDIT
         aItem[2]:Disable()
      ENDIF
   NEXT
   ::ButtonSaveOff()

   RETURN Nil

METHOD EditCreate() CLASS DlgAutoEditClass

   LOCAL nRow, nCol, aItem

   FOR EACH aItem IN ::aEditList
      AAdd( ::aControlList, { TYPE_EDIT, Nil, aItem[ DBS_NAME ], aItem[ DBS_TYPE ], aItem[ DBS_LEN ], aItem[ DBS_DEC ], Nil } )
      ATail( ::aControlList )[ EDIT_VALUE ] := &( ::cFileDbf )->( FieldGet( aItem[ DBS_NAME ] ) )
   NEXT
   nRow := 110
   nCol := 5
   FOR EACH aItem IN ::aControlList
      IF aItem[1] == TYPE_EDIT
      IF nCol + 50 + aItem[ EDIT_LEN ] * 12 + 50 > 1024 - 20
         nCol := 5
         nRow += 25
      ENDIF
      @ nCol, nRow SAY aItem[ EDIT_NAME ] SIZE 100, 20 COLOR STYLE_FORE TRANSPARENT
      @ nCol + 110, nRow GET aItem[2] ;
         VAR aItem[ EDIT_VALUE ] ;
         SIZE ( aItem[ EDIT_LEN ] + 1 ) * 12, 20 ;
         STYLE WS_DISABLED + iif( aItem[ EDIT_TYPE ] == "N", ES_RIGHT, ES_LEFT ) ;
         MAXLENGTH aItem[ EDIT_LEN ] ;
         PICTURE PictureFromValue( aItem )
      IF aItem:__EnumIndex < 5
         nCol += 5000
      ELSE
         nCol += 100 + ( ( aItem[ EDIT_LEN ] + 1 ) * 12 ) + 50
      ENDIF
      ENDIF
   NEXT
   AAdd( ::aControlList, { TYPE_EDIT, Nil, "", "C", 1, 0, "" } )
   @ nCol, nRow GET Atail( ::aControlList )[2] VAR Atail( ::aControlList )[ EDIT_VALUE ] SIZE 0, 0

   RETURN Nil

METHOD EditUpdate() CLASS DlgAutoEditClass

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[1] == TYPE_EDIT
         IF ! Empty( aItem[ EDIT_NAME ] )
            aItem[2]:Value := FieldGet( FieldNum( aItem[ EDIT_NAME ] ) )
            aItem[2]:Refresh()
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

   cType := oValue[ EDIT_TYPE ]
   nLen  := oValue[ EDIT_LEN ]
   nDec  := oValue[ EDIT_DEC ]
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

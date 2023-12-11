/*
test - main program
*/
REQUEST DBFCDX

#include "directry.ch"
#include "dbstruct.ch"
#include "frm_class.ch"

PROCEDURE Main()

   LOCAL aAllSetup, aList, aFile, aField, aStru, cFile, aItem, aDBF, nKeyPos, nSeekPos
   LOCAL aKeyList, aSeekList

   SET CONFIRM OFF
   SET DATE    BRITISH
   SET DELETED ON
   SET EPOCH TO Year( Date() ) - 90
   SET EXCLUSIVE OFF
   gui_Init()
   RddSetDefault( "DBFCDX" )
   frm_DBF()
   /* table, key */
   aKeyList := { ;
      { "DBCLIENT",  "IDCLIENT" }, ;
      { "DBPRODUCT", "IDPRODUCT" }, ;
      { "DBUNIT",    "IDUNIT" }, ;
      { "DBSELLER",  "IDSELLER" }, ;
      { "DBBANK",    "IDBANK" }, ;
      { "DBGROUP",   "IDGROUP" }, ;
      { "DBSTOCK",   "IDSTOCK" }, ;
      { "DBFINANC",  "IDFINANC" }, ;
      { "DBSTATE",   "IDSTATE" } }
   /* table, field, table to search, key field, field to show */
   aSeekList := { ;
      { "DBCLIENT",  "CLSELLER",  "DBSELLER",  "IDSELLER",  "SENAME" }, ;
      { "DBCLIENT",  "CLBANK",    "DBBANK",    "IDBANK",    "BANAME" }, ;
      { "DBCLIENT",  "CLSTATE",   "DBSTATE",   "IDSTATE",   "STNAME" }, ;
      { "DBPRODUCT", "IEUNIT",    "DBUNIT",    "IDUNIT",    "UNNAME" }, ;
      { "DBSTOCK",   "STCLIENT",  "DBCLIENT",  "IDCLIENT",  "CLNAME" }, ;
      { "DBSTOCK",   "STPRODUCT", "DBPRODUCT", "IDPRODUCT", "PRNAME" }, ;
      { "DBSTOCK",   "STGROUP",   "DBGROUP",   "IDGROUP",   "GRNAME" }, ;
      { "DBFINANC",  "FICLIENT",  "DBCLIENT",  "IDCLIENT",  "CLNAME" }, ;
      { "DBFINANC",  "FIBANK",    "DBBANK",    "IDBANK",    "BANAME" } }

   aAllSetup := {}
   aList := Directory( "*.dbf" )
   FOR EACH aFile IN aList
      aFile[ F_NAME ] := Upper( hb_FNameName( aFile[ F_NAME ] ) )
      cFile := aFile[ F_NAME ]
      AAdd( aAllSetup, { cFile, {} } )
      USE ( cFile )
      aStru := dbStruct()
      FOR EACH aField IN aStru
         aItem := CFG_EMPTY
         aItem[ CFG_FNAME ]    := aField[ DBS_NAME ]
         aItem[ CFG_FTYPE ]    := aField[ DBS_TYPE ]
         aItem[ CFG_FLEN ]     := aField[ DBS_LEN ]
         aItem[ CFG_FDEC ]     := aField[ DBS_DEC ]
         aItem[ CFG_VALUE ]    := aField[ DBS_NAME ]
         aItem[ CFG_CAPTION ]  := aField[ DBS_NAME ]
         aItem[ CFG_FPICTURE ] := PictureFromValue( aItem )
         /* is key */
         IF hb_ASCan( aKeyList, { | e | e[1] == cFile .AND. e[2] == aItem[ CFG_FNAME ] } ) != 0
            aItem[ CFG_ISKEY ] := .T.
         ENDIF
         /* to search */
         IF ( nSeekPos := hb_ASCan( aSeekList, { | e | e[1] == cFile .AND. e[2] == aItem[ CFG_FNAME ] } ) ) != 0
            aItem[ CFG_VTABLE ] := aSeekList[ nSeekPos, 3 ]
            aItem[ CFG_VFIELD ] := aSeekList[ nSeekPos, 4 ]
            aItem[ CFG_VSHOW ]  := aSeekList[ nSeekPos, 5 ]
         ENDIF
         AAdd( Atail( aAllSetup )[ 2 ], aItem )
      NEXT
      USE
   NEXT
   /* retrieve size of VSHOW */
   FOR EACH aDBF IN aAllSetup
      FOR EACH aItem IN aDBF[ 2 ]
         IF ! Empty( aItem[ CFG_VTABLE ] )
            IF ( nKeyPos := hb_AScan( aAllSetup, { | e | e[ 1 ] == aItem[ CFG_VTABLE ] } ) ) != 0
               IF ( nSeekPos := hb_AScan( aAllSetup[ nKeyPos, 2 ], { | e | e[ CFG_FNAME ] == aItem[ CFG_VSHOW ] } ) ) != 0
                  aItem[ CFG_VLEN ] := aAllSetup[ nKeyPos, 2, nSeekPos, CFG_FLEN ]
               ENDIF
            ENDIF
         ENDIF
      NEXT
   NEXT
   frm_MainMenu( @aAllSetup )

   RETURN

STATIC FUNCTION PictureFromValue( oValue )

   LOCAL cPicture, cType, nLen, nDec

   cType := oValue[ CFG_FTYPE ]
   nLen  := oValue[ CFG_FLEN ]
   nDec  := oValue[ CFG_FDEC ]
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

FUNCTION AppVersaoExe(); RETURN ""
FUNCTION AppUserName(); RETURN ""

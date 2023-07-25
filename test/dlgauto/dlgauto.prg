REQUEST DBFCDX

#include "directry.ch"
#include "dbstruct.ch"
#include "dlgauto.ch"

PROCEDURE Main()

   LOCAL aAllSetup, aList, aFile, aField, aStru, cFile, aItem

   SET EXCLUSIVE OFF
   RddSetDefault( "DBFCDX" )
   DlgAutoDBF( @aAllSetup )

   aAllSetup := {}
   aList := Directory( "*.dbf" )
   FOR EACH aFile IN aList
      aFile[ F_NAME ] := Upper( hb_FNameName( aFile[ F_NAME ] ) )
      cFile := aFile[ F_NAME ]
      USE ( cFile )
      aStru := dbStruct()
      FOR EACH aField IN aStru
         AAdd( aAllSetup, { cFile, aField[ DBS_NAME ], aField[ DBS_TYPE ], ;
            aField[ DBS_LEN ], aField[ DBS_DEC ], aField[ DBS_NAME ], ;
            "", "", "", "", "" } )
         DO CASE
         CASE ! cFile == "ACCOUNT"
         CASE aField[ DBS_NAME ] == "IDPRODUCT"
            ATail( aAllSetup )[ 8 ] := "PRODUCT"
            ATail( aAllSetup )[ 9 ] := "IDPRODUCT"
            ATail( aAllSetup )[ 10 ]  := "NAME"
         CASE aField[ DBS_NAME ] == "IDPEOPLE"
            ATail( aAllSetup )[ 8 ] := "PEOPLE"
            ATail( aAllSetup )[ 9 ] := "IDPEOPLE"
            ATail( aAllSetup )[ 10 ]  := "NAME"
         ENDCASE
      NEXT
      USE
   NEXT
   FOR EACH aItem IN aAllSetup
      IF ! Empty( aItem[ 8 ] )
         USE ( aItem[ 8 ] )
         aItem[ 11 ] := Space( FieldLen( aItem[10] ) )
         USE
      ENDIF
   NEXT

   DlgAutoMenu( @aAllSetup )

   RETURN

FUNCTION AppVersaoExe(); RETURN ""
FUNCTION AppUserName(); RETURN ""

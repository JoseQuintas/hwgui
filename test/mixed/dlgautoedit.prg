#include "hbclass.ch"
#include "hwgui.ch"
#include "dbstruct.ch"
#include "dlgauto.ch"

CREATE CLASS DlgAutoEdit

   VAR cTitle
   VAR cFileDBF
   VAR aEditList   INIT {}
   VAR lWithTab    INIT .F.
   VAR nLineHeight INIT 25
   VAR nEditStyle  INIT 1
   VAR nPageLimit  INIT 300
   METHOD EditSetup()
   METHOD EditUpdate()
   METHOD EditCreate()
   METHOD EditOn()
   METHOD EditOff()
   VAR oDlg

   ENDCLASS

METHOD EditOn() CLASS DlgAutoEdit

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

METHOD EditOff() CLASS DlgAutoEdit

   LOCAL aItem

   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT
         aItem[ CFG_OBJ ]:Disable()
      ENDIF
   NEXT
   ::ButtonSaveOff()

   RETURN Nil

METHOD EditCreate() CLASS DlgAutoEdit

   LOCAL nRow, nCol, aItem, oTab := Nil, nPageCount := 0, oPanel, nLen, aList := {}
   LOCAL nRow2, nCol2, nTab, nPageNext, nLenList

   hwg_SetColorInFocus(.T., ,WIN_RGB(255,255,0) )
   FOR EACH aItem IN ::aEditList
      AAdd( ::aControlList, { TYPE_EDIT, Nil, aItem[ DBS_NAME ], aItem[ DBS_TYPE ], aItem[ DBS_LEN ], aItem[ DBS_DEC ], aItem[ 5 ], Nil } )
      Atail( ::aControlList)[ CFG_VALUE ] := &( ::cFileDbf )->( FieldGet( FieldNum( aItem[ DBS_NAME ] ) ) )
   NEXT
   IF ::lWithTab
      @ 5, 70 TAB oTab ITEMS {} OF ::oDlg ID 101 SIZE ::nDlgWidth - 10, ::nDlgHeight - 140 STYLE WS_CHILD + WS_VISIBLE
      AAdd( ::aControlList, { TYPE_TAB, oTab, Nil, Nil, Nil, Nil, Nil, Nil  } )
      @ 1, 23 PANEL oPanel OF oTab SIZE ::nDlgWidth - 12, ::nDlgHeight - 165 BACKCOLOR STYLE_BACK
      AAdd( ::aControlList, { TYPE_PANEL, oPanel, Nil, Nil, Nil, Nil, Nil, Nil } )
      nRow := 999
   ELSE
      nRow := 80
   ENDIF
   nCol := 10
   nLenList := Len( ::aControlList )
   FOR EACH aItem IN ::aControlList
      IF aItem:__EnumIndex > nLenList
         EXIT
      ENDIF
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT
         IF ::nEditStyle == 1 .OR. ::nEditStyle == 2
            nLen := Len( aItem[ CFG_CAPTION ] ) + aItem[ CFG_LEN ] + 3
         ELSE
            nLen := Max( aItem[ CFG_LEN ], Len( aItem[ CFG_CAPTION ] ) )
         ENDIF
         IF ::nEditStyle == 1 .OR. nCol + 30 + ( nLen * 12 ) > ::nDlgWidth - 40 .OR. nRow > ::nPageLimit
            IF ::lWithTab .AND. nRow > ::nPageLimit
               IF nPageCount > 0
                  AAdd( ::aControlList, { TYPE_EDIT, Nil, "", "C", 1, 0, "", "" } )
                  @ nCol, nRow GET Atail( ::aControlList )[ CFG_OBJ ] VAR Atail( ::aControlList )[ CFG_VALUE ] ;
                     OF oTab SIZE 0, 0 STYLE WS_DISABLED
                  AAdd( Atail( aList ), Atail( ::aControlList )[ CFG_OBJ ] )
                  END PAGE OF oTab
               ENDIF
               nPageCount += 1
               BEGIN PAGE "Pag." + Str( nPageCount, 2 ) OF oTab
               nRow := 40
               AAdd( aList, {} )
            ENDIF
            nCol := 10
            nRow += ( ::nLineHeight * 2 )
         ENDIF
         IF ::nEditStyle == 1 .OR. ::nEditStyle == 2
            nRow2 := nRow
            nCol2 := nCol + ( Len( aItem[ CFG_CAPTION ] ) * 12 )
         ELSE
            nRow2 := nRow + ::nLineHeight
            nCol2 := nCol
         ENDIF
         @ nCol, nRow SAY aItem[ CFG_CAPTION ] OF iif( ::lWithTab, oTab, ::oDlg ) SIZE nLen * 12, 20 COLOR STYLE_FORE TRANSPARENT
         @ nCol2, nRow2 GET aItem[ CFG_OBJ ] ;
            VAR aItem[ CFG_VALUE ] OF iif( ::lWithTab, oTab, ::oDlg ) ;
            SIZE aItem[ CFG_LEN ] * 12, 20 ;
            STYLE WS_DISABLED + iif( aItem[ CFG_VALTYPE ] == "N", ES_RIGHT, ES_LEFT ) ;
            MAXLENGTH aItem[ CFG_LEN ] ;
            PICTURE PictureFromValue( aItem )
            nCol += ( nLen * 12 ) + 30
         IF ::lWithTab
            AAdd( Atail( aList ), aItem[ CFG_OBJ ] )
         ENDIF
      ENDIF
   NEXT
   AAdd( ::aControlList, { TYPE_EDIT, Nil, "", "C", 1, 0, "", "" } )
   @ nCol, nRow GET Atail( ::aControlList )[ CFG_OBJ ] VAR Atail( ::aControlList )[ CFG_VALUE ] ;
      OF iif( ::lWithTab, oTab, ::oDlg ) SIZE 0, 0 STYLE WS_DISABLED
   IF ::lWithTab
      AAdd( ATail( aList ), Atail( ::aControlList )[ CFG_OBJ ] )
      END PAGE OF oTab
      FOR nTab = 1 TO Len( aList )
         nPageNext  := iif( nTab == Len( aList ), 1, nTab + 1 )
         SetLostFocus( aList[ nTab, Len( aList[ nTab ] ) - 1 ], oTab, nPageNext, aList[ nPageNext, 1 ] )
      NEXT
   ENDIF

   RETURN Nil

STATIC FUNCTION SetLostFocus( oEdit, oTab, nPageNext, oEditNext )

   oEdit:bLostFocus := { || oTab:ChangePage( nPageNext ), oTab:SetTab( nPageNext ), oEditNext:SetFocus(), .T. }

   RETURN Nil

METHOD EditUpdate() CLASS DlgAutoEdit

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

METHOD EditSetup() CLASS DlgAutoEdit

   LOCAL aItem

   IF Empty( ::aEditList )
      ::aEditList := dbStruct()
      FOR EACH aItem IN ::aEditList
         aSize( aItem, 5 )
         aItem[ 5 ] := Upper( Left( aItem[ DBS_NAME ], 1 ) ) + Lower( Substr( aItem[ DBS_NAME ], 2 ) )
      NEXT
   ENDIF
   IF Len( ::aEditList ) > 30
      ::lWithTab := .T.
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
